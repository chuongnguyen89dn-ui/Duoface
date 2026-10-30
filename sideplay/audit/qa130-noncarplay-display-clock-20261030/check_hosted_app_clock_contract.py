#!/usr/bin/env python3
"""Read-only proof of which display/scene contracts QA130 implements.

No code injection, app entitlement change, brightness hook or vendor source.
This script does NOT prove that a particular lost YouTube Play tap is caused
by display clock starvation; physical QA130 app process logs are required.
"""
import argparse
import hashlib
import json
import pathlib
import subprocess

p=argparse.ArgumentParser()
p.add_argument("--repo", type=pathlib.Path, default=pathlib.Path(__file__).resolve().parents[3])
p.add_argument("--out", type=pathlib.Path, required=True)
a=p.parse_args()
rel="sideplay/duoface-native-scene-host/"
sources=["DFTouchOwnerProbe.m","DFSceneHost.m","DFSceneLifecycle.m",
         "DFNativeHostAppDelegate.m","DFYouTubeOrientationRelay.m",
         "DFYouTubeOrientationRelay.plist","DFNativeHostSurfaceView.m"]
read={}
for name in sources:
    b=(a.repo/rel/name).read_bytes()
    read[name]={"sha256":hashlib.sha256(b).hexdigest(),"bytes":len(b)}
    read[name]["text"]=b.decode("utf8")
owner=read["DFTouchOwnerProbe.m"]["text"]
scene=read["DFSceneHost.m"]["text"]
lifecycle=read["DFSceneLifecycle.m"]["text"]
relay=read["DFYouTubeOrientationRelay.m"]["text"]
delegate=read["DFNativeHostAppDelegate.m"]["text"]
assert 'CFSTR("PreventUserIdleSystemSleep")' in owner
assert "DFCarPlayPreventIdleSystemSleep121" in owner
assert "SBAppViewController" in scene
assert "sceneHandle" in scene and "isHostingAnApp" in scene
assert "DFIsOwnedHostedLockScene123(scene)" in lifecycle
assert "sceneHandle:didDestroyScene:" in lifecycle
assert "UIWindowScene" in relay
assert "UIWindowSceneSessionRoleCarPlay" in delegate
assert "CPTemplateApplicationSceneSessionRoleApplication" in delegate
# Check the complete signed app receiver / scene host runtime is NOT
# implementing a dedicated car-display CADisplayLink (the independent CarSurf
# app-process architecture uses one). This is a source difference only, not
# proof that all YouTube/GOFA app processes use display links.
clock_owners=[name for name in sources if "CADisplayLink" in read[name]["text"] or
              "displayLinkWithTarget:" in read[name]["text"]]
assert not clock_owners, "Runtime clock code detected. Update the audit."
display_controls=["BKSDisplayServicesSetScreenBlanked","setScreenBlankEnabled:",
                  "setIdleTimerDisabled:","PreventUserIdleDisplaySleep"]
found_controls={x:[f for f in sources if x in read[f]["text"]]
                for x in display_controls}
assert not any(found_controls.values()), "Display-power code detected; audit is stale."
result={
    "scope":"source-only signed QA130 runtime contract; not physical touch validation",
    "repo_head":subprocess.check_output(["git","rev-parse","HEAD"],cwd=a.repo,text=True).strip(),
    "source_files":{k:{"sha256":v["sha256"],"bytes":v["bytes"]}
                    for k,v in read.items()},
    "has_manual_SBAppViewController_host":True,
    "has_native_session_lease_and_destroy_scene_hook":True,
    "has_system_idle_sleep_assertion":True,
    "has_phone_display_keep_awake_or_dim_policy":False,
    "has_app_process_car_display_CADisplayLink_bridge_in_signed_runtime":False,
    "has_carplay_role_for_own_duoface_app":True,
    "found_display_controls":found_controls,
    "no_new_QA131_or_Sileo_update":True,
    "causation_of_QA130_failed_play":"NOT established; CarPlay headunit and phone clock, remote event ACK and scene active must be measured in same loaded build",
    "external_2026_analogue":"pavunato/carsurf: recorded main display 0Hz while car display 60Hz on iPhone car scene; independent model evidence, not proof of DuoFace's actual frame rate",
}
a.out.parent.mkdir(parents=True,exist_ok=True)
a.out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n")
print("QA130_HOSTED_PHONE_APP_NO_CAR_DISPLAY_CLOCK_OR_PHONE_DIM_POLICY_SOURCE_GAP_VERIFIED_NOT_DEVICE_CAUSE")
