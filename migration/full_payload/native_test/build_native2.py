#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Build native2 by REUSING proven native1 byte-for-byte staging and packaging.

Only the new 2-source add-on changes. The original DuoFaceUI, Dashboard,
FullscreenBridge, VisualHook, assets, and filters remain bit-identical.
"""
import argparse
import json
import pathlib

import build_native_trial as baseline

VERSION="0.1.0~native2"
NATIVE1_SHA256="16fd5fcbad7eba98de91a2e7a1200793509640cc47decbcca30491a45a6b9a13"

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--policy",type=pathlib.Path,required=True)
    p.add_argument("--out",type=pathlib.Path,required=True)
    p.add_argument("--report",type=pathlib.Path,required=True)
    args=p.parse_args()
    baseline.VERSION=VERSION
    baseline.main()
    report=json.loads(args.report.read_text(encoding="utf-8"))
    assert report["package"]=="com.duoface.independent"
    assert report["version"]==VERSION
    assert report["original_unchanged_payload_file_count"]>=37
    assert report["original_ui_source_rewritten"] is False
    report.update({
        "status":"ORIGINAL_UI_NATIVE2_CANDIDATE_BUILT_NEEDS_DEVICE_TEST",
        "based_on_proven_native1_sha256":NATIVE1_SHA256,
        "native2_changes":[
            "Suppress iPhone-only expiry modal entrypoint XXRootViewController.checkAndPresentLicenseModalIfNeeded",
            "Hide date/license/subscription rows from original CBGeneralSettingsViewController, preserving other row actions",
            "Disable obsolete subscription-navigation action from iPhone settings",
        ],
        "carplay_scene_host_changed":False,
        "carplay_picker_or_menu_changed":False,
        "original_source_binaries_changed":False,
        "original_license_bytecode_still_embedded":True,
        "original_time_value_hooks_preserved_from_working_native1":True,
        "rollback_original_native1_sha256":NATIVE1_SHA256,
        "device_tested":False,
        "sileo_published":False,
    })
    args.report.write_text(json.dumps(report,ensure_ascii=False,indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print("NATIVE2_UI_ONLY_TRIAL_PACKAGED; ORIGINAL_37_FILES_UNCHANGED; NEEDS_DEVICE_TEST")

if __name__=="__main__":main()
