#!/usr/bin/env python3
"""Read-only ORIGINAL-DEB ARM64 method dataflow for DuoFace YouTube orientation.
SHA-pinned inputs, no vendor image redistribution and no modifications to runtime.
The first-party parser was previously verified in DuoFace DuoNavi/DuoDash audits.
A selector used by an objc_msgSend does not prove the dynamic receiver's class.
"""
from __future__ import annotations
import argparse, bisect, hashlib, json, os, re, subprocess, sys, tempfile
from pathlib import Path

PINS = {
    "native12": "2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad",
    "sideplay104": "7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c",
    "duonavi104": "f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd",
    "omnicar103": "d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd",
    "duodash113_repack": "ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465",
}
IMAGES = {
    "native12": ("DuoFaceDashboard.dylib",),
    "sideplay104": ("SidePlay.dylib",),
    "duonavi104": ("DuoNaviDashboard.dylib",),
    "omnicar103": ("OmniCarAppBridge.dylib", "OmniCarSplitScreen.dylib"),
    "duodash113_repack": ("DuoDash.dylib",),
}
# Only decode orientation-relevant app/scene method bodies, NOT licensing.
TARGET = re.compile(
    r"orientation|scene.?frame|scene.?settings|scene.?layout|reference.?size|"
    r"bridge.?state|watch.?orientation|layout.?pane|refresh.?scene|"
    r"geometry|fullscreen|rotate|present.?player|scene.?host",
    re.I
)
EVIDENCE = re.compile(
    r"orientation|sceneHandle|sceneIfExists|updateSettings|setFrame|"
    r"foreground|background|contentReference|layout|bridgeState|"
    r"windowScene|watchToken|geometry|player|fullscreen|"
    r"setNeeds|setRequestedMode|renderSize|frame",
    re.I
)
CRITICAL = {
    "sideplay104": (
        "applySceneFrame:", "restoreSceneFrame", "setSceneFrame:orientation:",
        "orientationForBundleID:idiom:", "watchOrientationFor:token:",
        "sceneViewOrientation", "scheduleGeometryChecksFor:"
    ),
    "native12": (
        "refreshSceneLayout", "updateSceneSettingsFrame",
        "updateLayout", "renderSizeForBundleID:",
        "supportsInterfaceOrientation:forBundleID:"
    ),
    "duonavi104": (
        "refreshSceneLayout", "updateSceneSettingsFrame",
        "updateLayout", "renderSizeForBundleID:"
    ),
    "omnicar103": ("layoutPane:", "effectiveOrientation:",
                   "setInterfaceOrientation:", "requestedOrientation",
                   "setSceneFrame:orientation:"),
    "duodash113_repack": ("setBridgeState:width:height:orientation:",
                          "onHostRequest:", "onHostRequestSplit:")
}
MAX_METHODS = 65
MAX_FULL_INS = 320
MAX_NEAR = 16

def sha(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()

def extract(deb: Path, root: Path) -> None:
    subprocess.run(("dpkg-deb", "-x", str(deb), str(root)), check=True)

def main() -> None:
    arg = argparse.ArgumentParser()
    for name in PINS:
        arg.add_argument("--" + name, required=True, type=Path)
    arg.add_argument("--out", required=True, type=Path)
    opt = arg.parse_args()
    parser_dir = os.environ.get("NATIVE_PARSER_DIR")
    if not parser_dir:
        raise RuntimeError("NATIVE_PARSER_DIR (first-party historical parser) missing")
    sys.path.insert(0, parser_dir)
    from audit_native12_license_class_xrefs import MachO, select_arm64
    from audit_native12_carplay_add_app_chain import methods, disassemble

    class TaggedMachO(MachO):
        def map(self, vm):
            try:
                return super().map(vm)
            except ValueError:
                clean = vm & 0x0000FFFFFFFFFFFF
                if clean == vm:
                    raise
                return super().map(clean)

    result = {
        "status": "SHA_PINNED_ORIGINAL_DEB_STATIC_ARM64_ORIENTATION_DATAFLOW_ONLY",
        "device_video_rotation_fixed": False,
        "scope": "YouTube app-scene/player rotation; Google Maps left untouched",
        "notices": [
            "No original DEB, dylib or proprietary licensing source redistributed",
            "A selector dispatch is not proof of target class at runtime",
            "Next IMP can bound disassembly but does not prove all C/block function extents",
            "DuoDash is a repack, not verified stock original",
            "This is original binary analysis, not a new DuoFace DEB or real device test"
        ],
        "packages": {}
    }
    with tempfile.TemporaryDirectory(prefix="duoface-static-orientation-") as temp:
        for name in PINS:
            deb = getattr(opt, name)
            package_raw = deb.read_bytes()
            observed = sha(package_raw)
            if observed != PINS[name]:
                raise RuntimeError("Incorrect original " + name + " DEB SHA256: " + observed)
            unpack = Path(temp) / name
            unpack.mkdir()
            extract(deb, unpack)
            pkg = {"deb_sha256": observed, "images": {}, "missing_targets": []}
            for binary_name in IMAGES[name]:
                choices = list(unpack.rglob(binary_name))
                if len(choices) != 1:
                    raise RuntimeError(name + " expected one " + binary_name +
                                       ", found " + str(len(choices)))
                raw = choices[0].read_bytes()
                thin = select_arm64(raw)
                obj = TaggedMachO(thin) if name == "duodash113_repack" else MachO(thin)
                classes = obj.classes()
                byclass = {}
                starts = set()
                errors = 0
                for cls in classes:
                    try:
                        entries = methods(obj, cls)
                        if not entries:
                            continue
                        byclass[cls] = entries
                        for item in entries.values():
                            if item.get("vm"):
                                start = item["vm"] & 0x0000FFFFFFFFFFFF
                                starts.add(start)
                    except (ValueError, KeyError, IndexError, AssertionError):
                        errors += 1
                starts = sorted(starts)
                chosen = []
                critical_seen = set()
                for cls, entries in byclass.items():
                    for method, info in entries.items():
                        selector = method.lstrip("+-")
                        critical = selector in CRITICAL[name]
                        if not critical and not TARGET.search(selector):
                            continue
                        vm = info["vm"] & 0x0000FFFFFFFFFFFF
                        limit_pos = bisect.bisect_right(starts, vm)
                        next_imp = starts[limit_pos] if limit_pos < len(starts) else vm + 0x2000
                        end = min(next_imp, vm + 0x1800)
                        if end <= vm:
                            continue
                        try:
                            instructions = disassemble(obj, vm, end)
                        except (ValueError, IndexError, AssertionError):
                            continue
                        if not instructions:
                            continue
                        focused = [i for i, line in enumerate(instructions)
                                   if EVIDENCE.search(line) and
                                   ("SEL_OR_LITERAL" in line or "Objc" in line or
                                    "objc" in line or "literal" in line)]
                        # Include local incoming argument register setup around exact selector call.
                        windows = []
                        for i in focused[:20]:
                            lo, hi = max(0, i - MAX_NEAR), min(len(instructions), i + 4)
                            windows.append({
                                "instruction_index": i,
                                "arm64": instructions[lo:hi]
                            })
                        selected = {
                            "class": cls, "selector": selector, "imp": hex(vm),
                            "objc_type": info.get("type"), "bounded_next_objc_imp": hex(next_imp),
                            "method_range_truncated": next_imp > end,
                            "arm64_instruction_count": len(instructions),
                            "semantic_windows": windows,
                            "leading_arm64": instructions[:18],
                            "full_bounded_arm64": instructions[:MAX_FULL_INS] if critical else None,
                        }
                        chosen.append((0 if critical else 1, len(windows) == 0, selected))
                        if critical:
                            critical_seen.add(selector)
                chosen.sort(key=lambda v: (v[0], v[1], v[2]["class"], v[2]["selector"]))
                retained = [x[2] for x in chosen[:MAX_METHODS]]
                pkg["images"][binary_name] = {
                    "original_image_sha256": sha(raw),
                    "thin_arm64_sha256": sha(thin),
                    "objc_class_count": len(classes),
                    "objc_parsed_classes": len(byclass),
                    "objc_class_parse_failures": errors,
                    "retained_orientation_methods": retained,
                    "orientation_method_candidates_total": len(chosen),
                    "critical_method_presence": {
                        key: key in critical_seen for key in CRITICAL[name]
                    }
                }
                for key in CRITICAL[name]:
                    if key not in critical_seen:
                        pkg["missing_targets"].append(binary_name + ":" + key)
                print("ORIGINAL_SHA_PASS", name, binary_name,
                      "classes", len(classes), "selected", len(retained),
                      "critical", sorted(critical_seen), flush=True)
            result["packages"][name] = pkg
    opt.out.parent.mkdir(parents=True, exist_ok=True)
    opt.out.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n",
                       encoding="utf-8")
    print("ORIGINAL_YOUTUBE_ORIENTATION_SOURCE_DEB_COUNT", len(result["packages"]))
    print("ORIGINAL_YOUTUBE_ORIENTATION_DATAFLOW_OUTPUT", opt.out)

if __name__ == "__main__":
    main()
