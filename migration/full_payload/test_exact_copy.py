#!/usr/bin/env python3
"""Hồi quy việc chuyển nguyên byte payload, không chuyển dữ liệu giấy phép cá nhân."""
import hashlib
import json
import pathlib
import subprocess
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "migration/full_payload/prepare_exact_copy.py"

class CopyBaselineTests(unittest.TestCase):
    def test_copies_payload_exactly_except_license_only_state(self):
        with tempfile.TemporaryDirectory(prefix="duoface-fake-deb-") as temp:
            base=pathlib.Path(temp)
            root=base/"debroot"
            paths={
                "var/jb/Applications/DuoFaceUI.app/Info.plist": (
                    b"<?xml version=\"1.0\"?><plist version=\"1.0\"><dict>"
                    b"<key>CFBundleIdentifier</key><string>com.test.original</string>"
                    b"</dict></plist>"
                ),
                "var/jb/Applications/DuoFaceUI.app/DuoFaceUI": b"app\0isLicenseCurrentlyValid\0DuoFace UI\0",
                "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib": b"dash\0licenseWatchdogTimerFired:\0window",
                "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib": b"fullscreen\xff",
                "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.dylib": b"visual\x00",
                "var/mobile/Library/Preferences/com.duonavi.sync.plist": b"SENSITIVE_LICENSE_STATE_NOT_FOR_STAGE",
                "var/jb/Library/Application Support/DuoFace/duoface-logo.png": b"APPROVED_ORIGINAL_IMAGE",
                "var/jb/usr/bin/duoface-cboptimize": b"#!/bin/sh\nexit 0\n",
            }
            for relative,data in paths.items():
                file=root/relative
                file.parent.mkdir(parents=True,exist_ok=True)
                file.write_bytes(data)
            control=root/"DEBIAN/control"
            control.parent.mkdir(parents=True,exist_ok=True)
            control.write_text("Package: com.test.fixture\nVersion: 1.0\nArchitecture: all\n"
                               "Maintainer: test\nDescription: regression fixture\n",encoding="utf-8")
            package=base/"input.deb"
            subprocess.run(["dpkg-deb","--build","--root-owner-group",str(root),str(package)],
                           check=True,capture_output=True,text=True)
            before=hashlib.sha256(package.read_bytes()).hexdigest()
            stage=base/"staging"
            report=base/"audit.json"
            subprocess.run([sys.executable,str(SCRIPT),"--deb",str(package),"--stage",str(stage),
                            "--report",str(report),"--allow-fixture"],
                           check=True,capture_output=True,text=True)
            data=json.loads(report.read_text(encoding="utf-8"))
            self.assertFalse((stage/"var/mobile/Library/Preferences/com.duonavi.sync.plist").exists())
            self.assertEqual(data["excluded_only"],["var/mobile/Library/Preferences/com.duonavi.sync.plist"])
            self.assertEqual(data["copied_file_count"],len(paths))
            self.assertEqual(data["source_file_count"],len(paths)+1)
            self.assertTrue(data["license_check_code_still_present"])
            self.assertFalse(data["staging_is_installable"])
            self.assertFalse(data["new_package_id_applied"])
            self.assertTrue(data["byte_identical_files"])
            for relative,blob in paths.items():
                if "sync.plist" in relative: continue
                self.assertEqual((stage/relative).read_bytes(),blob,relative)
            self.assertEqual(before,hashlib.sha256(package.read_bytes()).hexdigest())
            self.assertFalse(report.read_text(encoding="utf-8").find("SENSITIVE_LICENSE_STATE_NOT_FOR_STAGE")>=0)
            # Không xóa nhầm file khi script chạy lần 2: staging phải trống.
            result=subprocess.run([sys.executable,str(SCRIPT),"--deb",str(package),
                                   "--stage",str(stage),"--report",str(report),"--allow-fixture"],
                                  capture_output=True,text=True)
            self.assertNotEqual(result.returncode,0)

if __name__=="__main__":
    unittest.main(verbosity=2)
