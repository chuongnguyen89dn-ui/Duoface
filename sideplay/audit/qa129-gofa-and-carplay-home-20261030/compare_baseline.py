#!/usr/bin/env python3
"""Read-only QA128 physically-successful GOFA baseline versus QA129 signed source.

This program compares exact pinned Git source objects; it never edits runtime
code, never infers a device regression from text differences, and never changes
Apple CarPlay capabilities.
"""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path

QA128 = "f84e27a9a97d58e0fb0509bdc6d3de13444c4a75"
QA129 = "39270d65182ef61d06393d6a8904d8b8b095bdc3"
ROOT = "sideplay/duoface-native-scene-host/"
GEOMETRY = ["DFSceneHost.m", "DFHostedMapRenderSize.h",
            "DFNative12Chrome.m", "DFAppPickerVC.m", "DFEnabledAppsPolicy.h"]
OWNERS = ["DFNativeHostAppDelegate.m", "DFSceneLifecycle.m",
          "DFTouchOwnerProbe.m", "DFCarPlayDockOwner.m", "DFCarPlayOwnerLease.h",
          "DFCarPlayOwnerObserver.h"]
def show(ref, path):
    cmd = ["git", "show", ref + ":" + ROOT + path]
    result = subprocess.run(cmd, capture_output=True, check=False)
    if result.returncode != 0:
        if b"does not exist" in result.stderr or b"exists on disk" in result.stderr:
            return None
        raise RuntimeError("Unable to read immutable git source for " + path + ": " +
                           result.stderr.decode(errors="replace")[:320])
    return result.stdout

def digest(value):
    return hashlib.sha256(value).hexdigest() if value is not None else None

def inspect():
    files = {}
    for name in GEOMETRY + OWNERS:
        before, after = show(QA128, name), show(QA129, name)
        files[name] = {"qa128_sha256": digest(before), "qa129_sha256": digest(after),
                       "byte_identical": before == after,
                       "qa128_present": before is not None,
                       "qa129_present": after is not None}
    # The last device-confirmed GOFA render + crash improvements came on QA128.
    # Geometry is not the changed producer, whereas the native owner/session
    # reader and post-lock foreground policy changed in QA129.
    assert all(files[n]["byte_identical"] for n in GEOMETRY),         "Unexpected visual/catalog change: inspect source before conclusions."
    assert all(not files[n]["byte_identical"] for n in OWNERS),         "Owner delta differs from approved pinned QA128->129 reference."
    native = show(QA129, "DFNativeHostAppDelegate.m").decode()
    scene = show(QA129, "DFSceneLifecycle.m").decode()
    lease = show(QA129, "DFCarPlayOwnerLease.h").decode()
    dock = show(QA129, "DFCarPlayOwnerObserver.h").decode()
    assert "DFOwnerNativeEvidence(self.touchSession" in native
    assert 'stopTouchOwnerWithReason:@"scene-background"' in native
    assert "DFOwnerAcceptPulse(pulse)" in scene
    assert "DFPostLockIntercept" in scene
    assert "DFOwnerHomeHooksReady" in dock
    assert "DFOwnerEvidenceMatches" in lease
    assert 'homeScreenShownApps' not in show(QA129, "DFEnabledAppsPolicy.h").decode()
    return {
        "qa128_source": QA128, "qa129_signed_source": QA129,
        "files": files,
        "geometry_and_in_app_picker_unchanged": True,
        "qa129_new_native_owner_lease_and_home_hook": True,
        "qa129_new_postlock_scene_writer": True,
        "qa129_lacks_foreign_app_system_carplay_home_publisher": True,
        "qa128_device": "User directly reported GOFA layout and crash improved on QA128; lock touch still failed",
        "qa129_device": "User reports GOFA regression and missing CarPlay application entry; latest uploaded Audit13 is QA90, not QA129",
        "conclusion": "Source change boundary is owner/activation path, not static GOFA viewport formulas. Exact runtime cause NOT verified. No Home publishing contract exists.",
        "next": "Verify installed QA129 Mach-O UUID, scene ownership, stop/launch sequence and post-commit GOFA viewport on parked CarPlay before any runtime patch or release.",
        "no_device_success_claim": True,
        "no_runtime_patch": True,
    }

p = argparse.ArgumentParser()
p.add_argument("--out", required=True, type=Path)
args = p.parse_args()
result = inspect()
args.out.parent.mkdir(parents=True, exist_ok=True)
args.out.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
print("QA128_QA129_GEOMETRY_UNCHANGED_NATIVE_OWNER_CHANGED_GOFA_ROOT_CAUSE_NOT_YET_VERIFIED")
