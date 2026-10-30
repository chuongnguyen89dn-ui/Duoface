#!/usr/bin/env python3
"""Reproducible, read-only DuoFace CarPlay Home vs in-app picker source contract audit."""
import argparse
import json
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[3])
p.add_argument("--out", type=Path, required=True)
args = p.parse_args()
repo = args.root
src = repo / "sideplay/duoface-native-scene-host"
def source(name):
    return (src / name).read_text(encoding="utf-8")
phone = source("DFNativeHostRootController.m")
picker = source("DFAppPickerVC.m")
policy = source("DFEnabledAppsPolicy.h")
build = source("build.sh")
info = source("Info.plist")
omni_file = repo / "sideplay/audit/omnicar-iphone-picker-20261029/runs/40789537861/ORIGINAL_OMNICAR_APP_FILTER_ARM64.json"
omni = json.loads(omni_file.read_text(encoding="utf-8"))
methods = omni["methods"]
def original_strings(selector):
    return "\n".join(methods[selector]["instructions"])
original_load = original_strings("OMCAppBridgeAppsController.loadState")
original_save = original_strings("OMCAppBridgeAppsController.storeChoices")
original_publisher = original_strings("SCPCarSplit.publishCarPlayApps")
assert 'DFWriteEnabledAppIDs(updated.array)' in phone, "Missing iPhone enable action"
assert 'DFPickerAllowsApp(app.bundleID,enabled)' in picker, "Missing in-app catalog filter"
assert 'EnabledBundleIDs' in policy and 'DFEnabledAppsChangedNotification' in policy
assert 'com.duoface.native.scenehost' in info and 'CPTemplateApplicationScene' in info
assert 'DFTouchOwnerProbe.m' in build and 'DFAppPickerVC.m' in build
assert 'homeScreenShownApps' in original_load and 'homeScreenHiddenApps' in original_load
assert 'homeScreenShownApps' in original_save and 'homeScreenHiddenApps' in original_save
assert 'appBridgeApps' in original_save
assert 'CarSplit: %lu app CarPlay' in original_publisher
# Current integrated runtime and bridge preference are separate from dormant
# first-party *DuoFace-only* admission experiments. No foreign-app Home API
# publisher is compiled as part of this signed package.
foreign_home_publisher = any(x in build for x in (
    'DFHomeScreenBridge.m', 'DFCarPlayHomeCatalog.m', 'DFHomeIconPublisher.m'))
result = {
    "kind": "read-only-home-icon-architecture-gap",
    "source": "fix/duoface-postlock-settings-20261030",
    "iphone_enabled_bundle_ids_are_used_by_in_car_picker": True,
    "external_carplay_home_icon_publication_in_signed_build": foreign_home_publisher,
    "original_omnicar_prefs": {
        "bridge_key": "appBridgeApps",
        "home_shown": "homeScreenShownApps",
        "home_hidden": "homeScreenHiddenApps",
        "home_config_is_separate_from_split_picker": True,
        "original_arms": {
            "load": methods["OMCAppBridgeAppsController.loadState"]["imp"],
            "save": methods["OMCAppBridgeAppsController.storeChoices"]["imp"],
            "carplay_split": methods["SCPCarSplit.publishCarPlayApps"]["imp"],
        },
    },
    "caveats": [
        "Missing current publisher proves a source integration gap, not a device execution trace.",
        "Original CFString/method evidence does not prove exact iOS16 Dashboard launch filter.",
        "No QA129 touch or Home device PASS is asserted.",
        "Do not rewrite third-party entitlements or claim Apple CarPlay approval.",
    ],
}
assert not foreign_home_publisher, "Home publisher was added: update audit to verify real registered-Home semantics"
args.out.parent.mkdir(parents=True, exist_ok=True)
args.out.write_text(json.dumps(result, indent=2, ensure_ascii=False)+"\n", encoding="utf-8")
print("DUOFACE_HOME_SELECTED_APP_PICKER_ONLY_GAP_VERIFIED_ORIGINAL_OMNICAR_HOME_STATE_SEPARATE")
