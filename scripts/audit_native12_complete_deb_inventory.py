#!/usr/bin/env python3
"""Exhaustive, READ-ONLY signed DEB payload/image/ObjC class inventory.

No original vendor binaries are copied into the QA package; color swatches from
PNG pixels are *not* claims about runtime UIKit colors or compiled UI parity.
"""
from __future__ import annotations

import argparse
from collections import Counter
from io import BytesIO
import hashlib
import json
from pathlib import Path
import plistlib
import re
import subprocess
import tarfile
import tempfile

NATIVE_SHA = "2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
QA7_SHA = "57ae2b34487b3c24fc584ab2d1bf6b44abe6797c8c7d14628004e2bb78c62137"
ORIG_SHA = "f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd"
UI_FAMILIES = {
    "window": ["CBWindow"],
    "split": ["CBBridgedSplitApp"],
    "scene": ["CBBridgedUIAppView"],
    "overlay_picker": ["CBMultitaskingOverlayView"],
    "per_slot_pill": ["CBSlotPillView"],
    "divider": ["CBDividerView"],
}
QA_OWNERS = {
    "window": "DFINativeWindowSurface + DFIStart",
    "split": "DFV12SplitController + DFIFramesMake",
    "scene": "DFV12SceneHost",
    "overlay_picker": "DFINativePickerCard/MenuBar/PickerCardsController",
    "per_slot_pill": "DFINativeSlotPillView",
    "divider": "DFINativeDividerTrack/Logo",
}
NAME = re.compile(r"^\s*name\s+0x[0-9a-fA-F]+\s+([A-Za-z_][A-Za-z0-9_]*)\s*$")
METHOD = re.compile(r"^\s*name\s+0x[0-9a-fA-F]+\s+\(0x[0-9a-fA-F]+\)\s+(.+?)\s*$")


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def objc_metadata(binary: Path):
    # Supported by the existing Native12 macOS read-only disassembly workflow.
    arch = subprocess.run(["xcrun", "lipo", "-archs", str(binary)],
                          text=True, capture_output=True, check=False)
    target = binary
    if (arch.returncode == 0 and "arm64" in arch.stdout.split() and
        int.from_bytes(binary.read_bytes()[:4], "big") in
        (0xCAFEBABE, 0xBEBAFECA, 0xCAFEBABF, 0xBFBAFECA)):
        # Some signed originals are FAT; objc-objdump requires the ARM64 slice.
        sliced = binary.with_name(binary.name + ".arm64")
        subprocess.run(["xcrun", "lipo", "-thin", "arm64", str(binary),
                        "-output", str(sliced)], check=True, capture_output=True)
        target = sliced
    meta = subprocess.run(["xcrun", "llvm-objdump", "--macho",
                           "--objc-meta-data", str(target)],
                          text=True, capture_output=True)
    if meta.returncode != 0:
        return {"error": meta.stderr[-1200:], "class_count": 0, "classes": {}}
    classes = {}
    current = None
    active = False
    for line in meta.stdout.splitlines():
        m = NAME.match(line)
        if m:
            proposed = m.group(1)
            # ObjC -objc-meta-data also prints instance-variable and property
            # names as 'name 0x...' (e.g. _app, _currentRatio). These are NOT
            # class declarations. Count only class/protocol-style identifiers.
            # Still a static candidate count, not a formal linker class total.
            if proposed[:1].isupper() or proposed.startswith("_Tt"):
                current = proposed
                classes.setdefault(current, [])
            else:
                current = None
            active = False
            continue
        if current is None:
            continue
        if re.match(r"^\s*baseMethods\s+0x", line):
            active = not bool(re.match(r"^\s*baseMethods\s+0x0\s*$", line))
            continue
        if active and re.match(r"^\s*baseProtocols\b", line):
            active = False
        m = METHOD.match(line) if active else None
        if m:
            v = m.group(1)
            if v not in classes[current]:
                classes[current].append(v)
    # Never call an incomplete metadata scrape a complete class inventory.
    return {
        "class_count": len(classes),
        "method_count": sum(map(len, classes.values())),
        "classes": {k: classes[k] for k in sorted(classes)},
        "metadata_note": "Candidate class/protocol-style identifiers from static metadata (uppercase names only), not a certified count of every Objective-C runtime class; stripped or Swift symbols may not appear",
    }


def png_record(raw):
    from PIL import Image
    with Image.open(BytesIO(raw)) as im:
        rgba = im.convert("RGBA")
        bbox = rgba.getchannel("A").getbbox()
        small = rgba.copy()
        small.thumbnail((96, 96))
        palette = Counter()
        for r, g, b, alpha in small.getdata():
            if alpha < 32:
                continue
            # Reduce PNG colors into robust bins, including visible alpha.
            palette[(r // 32 * 32, g // 32 * 32, b // 32 * 32)] += 1
        common = [{"rgb_bin": list(c), "samples": n}
                  for c, n in palette.most_common(8)]
        return {
            "width_px": im.width,
            "height_px": im.height,
            "mode": im.mode,
            "visible_bbox_px": list(bbox) if bbox else None,
            "dominant_png_rgb_bins_only": common,
        }


def read_deb(path, label):
    raw = path.read_bytes()
    sha = digest(raw)
    expected = {"native12": NATIVE_SHA, "qa7": QA7_SHA,
                "original104": ORIG_SHA}[label]
    if sha != expected:
        raise ValueError(f"{label} immutable DEB SHA mismatch {sha} != {expected}")
    contents = subprocess.check_output(["dpkg-deb", "--fsys-tarfile", str(path)])
    result = {
        "deb_sha256": sha, "deb_size_bytes": len(raw), "all_files": [],
        "all_directories": [], "images": [], "machos": {},
    }
    with tempfile.TemporaryDirectory(prefix="duoface-payload-") as temp:
        with tarfile.open(fileobj=BytesIO(contents), mode="r:") as tar:
            for member in tar:
                name = member.name.lstrip("./")
                if member.isdir():
                    result["all_directories"].append(name)
                    continue
                if not member.isfile():
                    result.setdefault("other_archive_entries", []).append(
                        {"name": name, "type": str(member.type)})
                    continue
                payload = tar.extractfile(member).read()
                item = {"path": name, "bytes": len(payload), "sha256": digest(payload)}
                result["all_files"].append(item)
                if name.lower().endswith(".png"):
                    image = dict(item)
                    image.update(png_record(payload))
                    image["role"] = ("app_icon" if "appicon" in name.lower() or
                                     "/Icon" in name else "ui_asset")
                    result["images"].append(image)
                if name.lower().endswith((".dylib", "/DuoFaceUI", "/DuoFaceVisual12",
                                          "/DuoNaviUI", "/DuoNavi")):
                    binary = Path(temp) / Path(name).name
                    binary.write_bytes(payload)
                    result["machos"][name] = objc_metadata(binary)
                if name.lower().endswith("info.plist"):
                    try:
                        d = plistlib.loads(payload)
                        result.setdefault("info_plists", {})[name] = {
                            k: d[k] for k in ("CFBundleIdentifier", "CFBundleExecutable",
                                              "NSPrincipalClass", "CFBundleName")
                            if k in d and isinstance(d[k], (str, int, bool))}
                    except Exception as exc:
                        result.setdefault("plist_read_errors", {})[name] = str(exc)
    result["counts"] = {
        "files": len(result["all_files"]),
        "directories": len(result["all_directories"]),
        "png": len(result["images"]),
        "app_icon_png": sum(x["role"] == "app_icon" for x in result["images"]),
        "ui_asset_png": sum(x["role"] == "ui_asset" for x in result["images"]),
        "dylib": sum(x["path"].endswith(".dylib") for x in result["all_files"]),
        "plist": sum(x["path"].endswith(".plist") for x in result["all_files"]),
        "objc_class_candidates_listed": sum(x["class_count"] for x in result["machos"].values()),
        "objc_methods_listed": sum(x.get("method_count", 0) for x in result["machos"].values()),
    }
    return result


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--native-deb", type=Path, required=True)
    ap.add_argument("--qa-deb", type=Path, required=True)
    ap.add_argument("--original-deb", type=Path, required=True)
    ap.add_argument("--out-json", type=Path, required=True)
    ap.add_argument("--out-md", type=Path, required=True)
    a = ap.parse_args()
    all_data = {name: read_deb(file, name)
                for name, file in (("native12", a.native_deb),
                                   ("qa7", a.qa_deb),
                                   ("original104", a.original_deb))}
    native, qa = all_data["native12"], all_data["qa7"]
    if native["counts"]["files"] != 43 or native["counts"]["png"] != 25:
        raise AssertionError("Native12 immutable full payload 43 files / 25 PNG changed")
    if qa["counts"]["files"] != 23:
        raise AssertionError("QA7 immutable full payload differs from pinned 23 files")
    # The requested total scan is the *entire* signed archive, not just six
    # selected UI classes. Class coverage is separately bounded by objdump.
    native_cls = {}
    for dylib, entry in native["machos"].items():
        for name, methods in entry["classes"].items():
            native_cls.setdefault(name, []).append({"binary": dylib, "methods": methods})
    qa_cls = {}
    for dylib, entry in qa["machos"].items():
        for name, methods in entry["classes"].items():
            qa_cls.setdefault(name, []).append({"binary": dylib, "methods": methods})
    native_png = {Path(x["path"]).name: x for x in native["images"]}
    qa_png = {Path(x["path"]).name: x for x in qa["images"]}
    families = {}
    for role, names in UI_FAMILIES.items():
        families[role] = {
            "native_class_names": names, "qa_owned_reimplementation": QA_OWNERS[role],
            "native_classes_in_objc_metadata": [n for n in names if n in native_cls],
            "native_method_counts": {n: sum(len(z["methods"]) for z in native_cls.get(n, []))
                                     for n in names},
            "qa_owner_not_the_original_native_class": True,
            "native_runtime_parity_device_verified": False,
        }
    missing_assets = sorted(n for n in native_png if n not in qa_png)
    only_qa = sorted(n for n in qa_png if n not in native_png)
    differing = sorted(n for n in native_png.keys() & qa_png.keys()
                       if native_png[n]["sha256"] != qa_png[n]["sha256"])
    obj = {
        "status": "EXHAUSTIVE_SIGNED_DEB_FILE_SCAN_STATIC_UI_OWNERS_ONLY",
        "read_only": True, "native_runtime_executed": False,
        "device_ui_verified": False,
        "scope_note": "All archive entries, image dimensions and sampled color bins; "
                      "ObjC class enumeration is metadata-only, not executable coverage",
        "packages": all_data,
        "ui_families": families,
        "asset_diff": {
            "native_png_names_absent_qa7": missing_assets,
            "qa7_png_names_absent_native": only_qa,
            "common_png_names_with_different_sha": differing,
        },
        "native_objc_class_names": sorted(native_cls),
        "qa_objc_class_names": sorted(qa_cls),
        "ui_rgb_color_caveat": "Colors from PNG pixels, not UIKit dynamic runtime colors",
    }
    a.out_json.parent.mkdir(parents=True, exist_ok=True)
    a.out_md.parent.mkdir(parents=True, exist_ok=True)
    a.out_json.write_text(json.dumps(obj, ensure_ascii=False, indent=2) + "\n")
    lines = [
        "# DuoFace full immutable DEB scan — Native12 vs QA7 and DuoNavi 1.0.4",
        "", "Read-only archive and ObjC static metadata, not device parity or vendor code reuse.",
        "",
        "| Package | Files | Directories | PNG | App icon PNG | UI PNG | Dylib | Plist | ObjC class/protocol candidates listed |",
        "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]
    for name, pack in all_data.items():
        c = pack["counts"]
        lines.append(f'| {name} | {c["files"]} | {c["directories"]} | '
                     f'{c["png"]} | {c["app_icon_png"]} | {c["ui_asset_png"]} | '
                     f'{c["dylib"]} | {c["plist"]} | {c["objc_class_candidates_listed"]} |')
    lines += ["", "## Six core UI families from actual binary, not six total UI files"]
    for k, v in families.items():
        lines.append(f'- **{k}**: {", ".join(v["native_class_names"])} '
                     f'({v["native_method_counts"]} ObjC methods); QA owner '
                     f'{v["qa_owned_reimplementation"]}; full parity **NO**')
    lines += [
        "", "## Native12 images present in DEB (pixel sizes, asset color swatches)",
        "", "| Asset name | PNG pixels | Kind | dominant PNG RGB bin |",
        "| --- | --- | --- | --- |",
    ]
    for img in native["images"]:
        palette = img["dominant_png_rgb_bins_only"]
        main_rgb = palette[0]["rgb_bin"] if palette else None
        lines.append(f'| {Path(img["path"]).name} | {img["width_px"]}×'
                     f'{img["height_px"]} | {img["role"]} | {main_rgb} |')
    lines += [
        "", "## Differences vs QA7",
        f'- Native image names absent QA7: {missing_assets}',
        f'- QA7-only image names: {only_qa}',
        f'- Common names with different image SHA: {differing}',
        "", "## Why current QA7 is NOT restored DuoFace Native12",
        "- QA relies on its custom DFV12SplitController/native analogs; merely including PNG "
        "or matching 38/44/64/72/76/80pt pills cannot reproduce Native12 input behavior.",
        "- The image color bins above cannot establish compiled UIColor, gradient, blur, "
        "window/safe-area, dynamic states, or true physical screen geometry.",
        "- QA-only alpha floating controls must be deleted, not hidden; bridge/scene "
        "playback may be kept if device verified; no original/vendor/licensed runtime linked.",
        "- Continue by mapping every Native12 UI class/method into an independent "
        "owner, testing layout/interaction at real head-unit resolution.",
        "", "## Full inventories",
        "- Complete file names, byte sizes and SHA256, all PNG dimensions/bboxes/colors, "
        "all ObjC class names and per-class selectors (as objdump can expose) are "
        "in `audit/native12-complete-deb-inventory/INVENTORY.json`.",
        "",
    ]
    a.out_md.write_text("\n".join(lines))
    print("NATIVE12_FULL_ARCHIVE_AND_STATIC_OBJC_INVENTORY_PASS")
    for k, d in all_data.items():
        print(k, d["counts"])
    print("DO_NOT_INFER_NATIVE_UI_PARITY_OR_LICENSE_RUNTIME_FROM_STATIC_SCAN")


if __name__ == "__main__":
    main()
