#!/usr/bin/env python3
"""Repackage native16 as native17 with exactly one DuoFaceUI-only presentation module.

DuoFaceUI and Dashboard are EXACT native12 byte sequences. Do not change
license method bodies/ObjC metadata, old NoLease hook, CarPlay, SmartConnection,
or 10-second disconnect logic. Source DEB is pinned and never overwritten.
"""
import argparse
import hashlib
import json
import pathlib
import plistlib
import re
import shutil
import subprocess
import tempfile

BASE = pathlib.Path("dist/payload-migration/native16/com.duoface.independent_0.1.0~native16_iphoneos-arm64.deb")
BASE_SHA = "5d5cbd368c24d0c074b081d16aaf7d006467c3e9cfef01ee12378ce79d716fae"
VERSION = "0.1.0~native17"
PREFIX = "var/jb/Library/MobileSubstrate/DynamicLibraries/"
MOD = PREFIX + "DuoFaceSettingsUIRestore"
UI = "var/jb/Applications/DuoFaceUI.app/DuoFaceUI"
DASH = PREFIX + "DuoFaceDashboard.dylib"
EXPECTED_HOSTS = {
    UI: "cb40346d8ca504cb399abe31367847b4f980a01ba93810986ce1acf1fbe9eef9",
    DASH: "9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea",
}
EXPECTED_SMART = "0986cf70b4c613ad011520204337e1e2b403d24111f39f14f70628fb57e61d50"
EXPECTED_CARPLAY = "d0246415f4020f353e5ec7373d8d375cbbda868471fd1a467f8e57654c4d01ad"

def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def cmd(*args: str) -> str:
    return subprocess.check_output(args, stderr=subprocess.STDOUT, text=True).strip()

def inventory(root: pathlib.Path) -> dict[str, str]:
    return {p.relative_to(root).as_posix(): sha(p.read_bytes())
            for p in root.rglob("*")
            if p.is_file() and not p.is_symlink() and p.relative_to(root).parts[0] != "DEBIAN"}

def check_source_only_ui(source: str) -> None:
    required = ("CBGeneralSettingsViewController", "DFIsObsoleteLicenseRow",
                "DFVisibleCount", "DFVisibleCell", "DFVisibleSelect",
                "com.duoface.duofaceui")
    assert all(word in source for word in required), "Expected native2 UI row filtering missing"
    forbidden = ("CBLicenseSyncManager", "checkAndSyncLicenseIfNeeded",
                 "isLicenseCurrentlyValid", "licenseWatchdogTimerFired",
                 "A_DuoFaceNativeNoLease", "terminateApplicationWithBundleID:")
    assert all(word not in source for word in forbidden), "License/CarPlay runtime must NOT be restored"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dylib", required=True, type=pathlib.Path)
    ap.add_argument("--out", required=True, type=pathlib.Path)
    ap.add_argument("--report", required=True, type=pathlib.Path)
    args = ap.parse_args()
    assert BASE.is_file() and sha(BASE.read_bytes()) == BASE_SHA, "Native16 published artifact mismatch"
    assert cmd("dpkg-deb", "-f", str(BASE), "Package") == "com.duoface.independent"
    assert cmd("dpkg-deb", "-f", str(BASE), "Version") == "0.1.0~native16"
    assert not args.out.exists() and not args.report.exists(), "Refuse overwrite of an existing build"
    assert args.dylib.is_file() and len(args.dylib.read_bytes()) > 2000, "Missing compiled UI module"
    source = pathlib.Path("runtime/settings/DFSettingsUIRestore.mm").read_text()
    check_source_only_ui(source)
    with tempfile.TemporaryDirectory(prefix="duoface-native17-restore-ui-") as td:
        stage = pathlib.Path(td) / "stage"
        subprocess.run(["dpkg-deb", "-R", str(BASE), str(stage)], check=True)
        before = inventory(stage)
        assert len(before) >= 43
        assert all(before.get(path) == checksum for path, checksum in EXPECTED_HOSTS.items())
        assert before.get(PREFIX + "DuoFaceSmartConnection.dylib") == EXPECTED_SMART
        assert before.get(PREFIX + "DuoFaceInCarAddApps.dylib") == EXPECTED_CARPLAY
        assert not any("A_DuoFaceNativeNoLease" in p for p in before)
        assert MOD + ".dylib" not in before and MOD + ".plist" not in before
        shutil.copy2(args.dylib, stage / (MOD + ".dylib"))
        shutil.copy2(pathlib.Path("runtime/settings/DuoFaceSettingsUIRestore.plist"), stage / (MOD + ".plist"))
        subprocess.run(["ldid", "-S", str(stage / (MOD + ".dylib"))], check=True)
        subprocess.run(["lipo", str(stage / (MOD + ".dylib")), "-verify_arch", "arm64"], check=True)
        filt = plistlib.loads((stage / (MOD + ".plist")).read_bytes())["Filter"]
        assert filt == {"Executables": ["DuoFaceUI"], "Bundles": ["com.duoface.duofaceui"]}, filt
        after = inventory(stage)
        assert set(after) - set(before) == {MOD + ".dylib", MOD + ".plist"}
        assert not set(before) - set(after)
        assert all(after[k] == before[k] for k in before), "Existing native16 payload modified"
        control = stage / "DEBIAN/control"
        raw = control.read_text()
        assert re.search(r"(?m)^Version: 0\.1\.0~native16$", raw)
        control.write_text(re.sub(r"(?m)^Version: 0\.1\.0~native16$", "Version: " + VERSION, raw, count=1))
        checks = [hashlib.md5((stage / p).read_bytes()).hexdigest() + "  " + p
                  for p in sorted(after)]
        (stage / "DEBIAN/md5sums").write_text("\n".join(checks) + "\n")
        args.out.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["dpkg-deb", "--build", "--root-owner-group", str(stage), str(args.out)], check=True)
        assert cmd("dpkg-deb", "-f", str(args.out), "Package") == "com.duoface.independent"
        assert cmd("dpkg-deb", "-f", str(args.out), "Version") == VERSION
        assert cmd("dpkg-deb", "-f", str(args.out), "Architecture") == "iphoneos-arm64"
        report = {
            "status": "NATIVE17_IOS_SETTINGS_UI_ONLY_NATIVE12_CORE_EXACT_NOT_DEVICE_TESTED",
            "package": "com.duoface.independent",
            "version": VERSION,
            "base_published_native16_sha256": BASE_SHA,
            "deb_sha256": sha(args.out.read_bytes()),
            "deb_bytes": args.out.stat().st_size,
            "preserved_native16_payload_entries": len(before),
            "new_payload_paths": [MOD + ".dylib", MOD + ".plist"],
            "all_native16_original_payload_byte_identical": True,
            "native12_exact_original_host_sha256": EXPECTED_HOSTS,
            "smartconnection_10s_unchanged_sha256": EXPECTED_SMART,
            "carplay_addapps_unchanged_sha256": EXPECTED_CARPLAY,
            "ui_module_sha256": after[MOD + ".dylib"],
            "ui_plist_sha256": after[MOD + ".plist"],
            "restored_license_methods_or_registration": False,
            "original_nolease_library_reintroduced": False,
            "dopamine_touched": False,
            "device_tested": False,
            "published_to_sileo": False,
            "limitations": "This restores native2-era SETTINGS ROW PRESENTATION only. It does NOT change the native12 license core, prove its runtime behavior, or verify row filtering on an iPhone.",
        }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(report, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()
