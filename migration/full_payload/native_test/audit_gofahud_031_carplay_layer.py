#!/usr/bin/env python3
"""Read-only inspection of the exact published GOFAHUD v0.3.1 rootless DEB.

No installation or modification of package bytes. Produces durable JSON evidence.
"""
import argparse
import hashlib
import json
import pathlib
import plistlib
import re
import subprocess
import tempfile

EXPECTED_SHA256 = "62d6d818384844591217d74ab446404637127752e1b23bc1f9754ef1da297ad5"
INTERESTING = (
    "GOFACarGlobalWindow", "GOFACarHUD", "CARNotificationWindow",
    "CARStatusBarHostWindow", "CPSWindow", "CarPlayApp",
    "CarPlayTemplateUIHost", "windowLevel", "initWithWindowScene:",
    "setScreen:", "bringSubviewToFront:", "addSubview:",
    "rootViewController", "hitTest:withEvent:", "pointInside:",
    "local.gofahud.carplay.global", "local.gofahud.carplay.trace",
    "UIScreen", "windowScene", "CarPlay", "SpringBoard",
    "setHidden:", "setWindowLevel:", "GofaCarplayGlobal",
)


def run(*argv):
    return subprocess.run(argv, check=True, capture_output=True, text=True).stdout.strip()


def extract_filter(path):
    data = path.read_bytes()
    if data.startswith(b"bplist00") or data.lstrip().startswith(b"<?xml"):
        try:
            obj = plistlib.loads(data)
            return {"format": "binary_or_xml", "object": obj}
        except Exception as error:
            return {"format": "binary_or_xml_parse_error", "error": str(error)}
    text = data.decode("utf-8", errors="replace")
    return {"format": "openstep_text", "text": text,
            "bundle_ids": sorted(set(re.findall(r"com\\.[a-zA-Z0-9.]+", text)))}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--deb", type=pathlib.Path, required=True)
    ap.add_argument("--out", type=pathlib.Path, required=True)
    a = ap.parse_args()
    data = a.deb.read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    assert digest == EXPECTED_SHA256, f"wrong exact GOFA DEB: {digest}"
    with tempfile.TemporaryDirectory(prefix="duoface-gofa-forensic-") as dirname:
        home = pathlib.Path(dirname)
        payload = home / "payload"
        control = home / "control"
        payload.mkdir()
        control.mkdir()
        run("dpkg-deb", "-x", str(a.deb), str(payload))
        run("dpkg-deb", "-e", str(a.deb), str(control))
        pkg = run("dpkg-deb", "-f", str(a.deb), "Package")
        ver = run("dpkg-deb", "-f", str(a.deb), "Version")
        arch = run("dpkg-deb", "-f", str(a.deb), "Architecture")
        assert pkg == "local.gofahud", pkg
        assert ver == "0.3.1", ver
        report = {
            "status": "GOFAHUD_031_ACTUAL_ROOTLESS_DEB_LAYER_AUDIT_PASS_STATIC_ONLY",
            "origin": "manhtien9x/gofahud-repo releases v0.3.1-1",
            "filename": a.deb.name,
            "sha256": digest,
            "package": pkg, "version": ver, "architecture": arch,
            "device_tested": False, "carplay_order_proven": False,
            "control": {f.name: f.read_text(errors="replace")[:8000]
                        for f in control.iterdir() if f.is_file()},
            "filters": {},
            "dylibs": {},
            "file_count": 0,
        }
        for path in sorted(payload.rglob("*")):
            if not path.is_file():
                continue
            report["file_count"] += 1
            rel = path.relative_to(payload).as_posix()
            if "/MobileSubstrate/DynamicLibraries/" not in rel:
                continue
            if path.suffix == ".plist":
                report["filters"][path.name] = extract_filter(path)
            if path.suffix == ".dylib":
                symbols = run("strings", "-a", str(path)).splitlines()
                report["dylibs"][path.name] = {
                    "path": rel,
                    "size": path.stat().st_size,
                    "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                    "file": run("file", "-b", str(path)),
                    "interesting_strings": sorted({s for s in symbols
                        if any(needle in s for needle in INTERESTING)})[:140],
                }
        assert "GofaCarplayGlobal.dylib" in report["dylibs"], "global module missing"
        assert "GofaCarplayGlobal.plist" in report["filters"], "global filter missing"
        gf = report["filters"]["GofaCarplayGlobal.plist"]
        ftext = json.dumps(gf, ensure_ascii=False)
        for expected in ("com.apple.CarPlayApp", "com.apple.CarPlayTemplateUIHost"):
            assert expected in ftext, f"global filter missing {expected}"
        global_symbols = " ".join(report["dylibs"]["GofaCarplayGlobal.dylib"]["interesting_strings"])
        for expected in ("GOFACarGlobalWindow", "CARNotificationWindow", "windowLevel"):
            assert expected in global_symbols, f"global binary marker missing {expected}"
        a.out.parent.mkdir(parents=True, exist_ok=True)
        a.out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\\n")
        print("GOFAHUD031_EXACT_ROOTLESS_SHA256_AND_DEB_METADATA_PASS")
        print("GOFAHUD031_CARPLAY_GLOBAL_DYLIB_AND_TWO_BUNDLE_FILTERS_PASS")
        print(json.dumps({
            "status": report["status"], "sha256": report["sha256"],
            "package": pkg, "version": ver, "architecture": arch,
            "file_count": report["file_count"],
            "filters": report["filters"],
            "dylib_str": {name: x["interesting_strings"]
                          for name, x in report["dylibs"].items()},
            "dylib_sha256": {name: x["sha256"]
                             for name, x in report["dylibs"].items()},
        }, ensure_ascii=False, indent=2))
        print("GOFAHUD031_REAL_DEB_FORENSIC_COMPLETE_STATIC_NOT_DEVICE_TESTED")


if __name__ == "__main__":
    main()
