#!/usr/bin/env python3
"""Read-only pinned-source+existing-Log23 evidence gate; NOT runtime/device parity."""
import argparse
import hashlib
import json
from pathlib import Path

PINS = {
 "orig":("sideplay/audit/original-execution-route-20261031/ROUTE_FINDINGS.md","756303274555a6135e4811aafbe8026d9b327dc1"),
 "mgr":("sideplay/audit/original-manager-window-route-20261031/MANAGER_WINDOW_FINDINGS.md","83bf569a7ef5a3a45a33d0cd5dadb6399e1233f3"),
 "app":("sideplay/audit/original-app-state-route-20261031/APP_STATE_ROUTE_FINDINGS.md","34db633d2a0ba28ace0ddfa1da3ceb518c91f697"),
 "host":("sideplay/duoface-native-scene-host/DFSceneHost.m","ec2924c145be4edaaa27b7320bb869b18de12c6b"),
 "solo":("sideplay/duoface-native-scene-host/DFHomeStandalone144.m","878ebfe6f3d106a42a6a11d2b572b7680c01b9d8"),
 "dock":("sideplay/duoface-native-scene-host/DFNativeDockSync147.h","54844255af5fae93c515d994661f7a7daca8ae37"),
 "home":("sideplay/duoface-native-scene-host/DFCarPlayOwnerObserver.h","7fe060ca5229a1f723b1145215cbf21a9ff052f6"),
 "build":("sideplay/duoface-native-scene-host/build.sh","172f9d2b9740367c66582d1e976889e828059410"),
 "pack":("sideplay/jb-embedded-appbridge/package_integrated.py","00ddd337c8b4e25d947df53fbff7f2182bf62743"),
 "signed":("sideplay/audit/qa147-native-dock-sync-20261031/artifact-readback/FULL_FILE_LIST.txt","dfb2a1592d3becdc61323aec90d73b03f645a827"),
 "log":("sideplay/audit/qa147-user-log23-failure-20261031/LOG23_FAILURE_FINDINGS.json","a8bb80b89931421bd3785afbb88ae35f2e7134bf"),
 "focus":("sideplay/audit/qa147-focused-startup-boundary-20261031/FOCUSED_LOG23_EVIDENCE.json","42df81f19f93ef865c4c46e8f6966e4114c4f32c"),
 "viewport":("sideplay/duoface-native-scene-host/DFAppViewportRelay.m","06be1e13b73f3342a469e4342a53887d7cc08d4f"),
}

def blob_sha(raw):
 return hashlib.sha1(b"blob "+str(len(raw)).encode()+b"\0"+raw).hexdigest()

def segment(text, first, after):
 start=text.find(first);end=text.find(after,start+len(first))
 assert start>=0 and end>=0,(first,after)
 return text[start:end]

def run(repo):
 source={}
 for key,(path,want) in PINS.items():
  raw=(repo/path).read_bytes()
  assert blob_sha(raw)==want, f"input changed: {key} {path}"
  source[key]=raw.decode("utf-8")
 original,manager,app=(source[k] for k in ("orig","mgr","app"))
 host,solo,dock=(source[k] for k in ("host","solo","dock"))
 log=json.loads(source["log"]);focused=json.loads(source["focus"])
 begin=segment(solo,"- (BOOL)begin:(NSDictionary *)p {","- (void)attemptOwnedReadyForView:")
 ready=segment(solo,"- (void)attemptOwnedReadyForView:","- (void)sceneFailed:(NSNotification *)notice {")
 start=segment(host,"- (void)start {","- (void)layoutSubviews {")
 checks={
  "original_home_and_dock_entry":"Home app entry" in original and "Dock entry" in original,
  "original_native_workspace_preparation":"DBMutableWorkspaceStateChangeRequest" in original and "closeOfficialTopApp:" in original,
  "original_evict_then_host":"evictAppFromPhoneScreen:completion:" in original and "window show" in original,
  "original_manager_state_after_show":"notifyStateUpdated" in manager and "handleStateDict:" in original,
  "original_app_state_and_restore":"NSDistributedNotificationCenter" in app and "150ms and 500ms" in app and "inactive" in app,
  "current_start_flags_order_diff":0<=start.find("[self addSubview:appView]")<start.find("setIgnoresOcclusions:")<start.find("setRequestedMode:"),
  "current_pending_pre_mount_and_terminal_guard":0<=begin.find('[self reply:@"pending-scene"')<begin.find("[root.view addSubview:v]") and "if(self.generation!=generation || self.surface!=v || self.window!=w" in begin,
  "current_owned_pid_bounded_retry":'verifiedPIDForHostedView:v' in ready and "if(attempt>=14)return;" in ready and "dispatch_after" in ready and "self.generation!=generation" in ready,
  "current_dock_requires_custom_ack_pid":"scene-hosted-render-and-touch-unverified" in dock and "DF147ResultAction" in dock and "VerifiedPID" in dock,
  "log23_26_requests_16_scene_observed_no_native_dock":len(log["requests"])==26 and log["scene_event_counts"]["scene-handle-observed-render-unverified"]==16 and not log["stage_counts"].get("qa147-native-dock-active") and not log["stage_counts"].get("scene-hosted-render-and-touch-unverified"),
  "log23_eight_attach_failures_and_null_pending":log["stage_counts"]["failed"]==8 and log["null_identity_pending_count"]==8 and len(focused["failed_attach_requests"])==8,
  "log23_two_swapped_bounds":focused["requests"]==26 and len(focused["swapped_first_host_geometry"])==2,
  "log23_no_pixel_first_touch_or_pid_predicate":not log["real_pixel_or_first_touch_latency_measured"] and not log["exact_failed_ready_predicate_measured"] and focused["measured_verified_pid"] is None,
  "generic_app_viewport_source_not_in_shipped_build":"DFAppViewportRelay.m" not in source["build"] and "DFAppViewportRelay.dylib" not in source["signed"],
  "shipped_app_side_youtube_gofa_filters":"YouTube relay filter broadened" in source["pack"] and "GOFA map resize receiver filter broadened" in source["pack"],
  "standalone_home_stop_and_native_home_callback":"com.duoface.nativehost.standalone144.stop" in source["home"] and "homeButtonUp:" in source["home"],
  "current_standalone_window_content_sized":"w.frame=content;" in solo and "UIWindowLevelNormal+1" in solo and "root.view=[[UIView alloc]initWithFrame:(CGRect){CGPointZero,content.size}]" in solo,
 }
 failed=[k for k,v in checks.items() if not v]
 assert not failed, "static checks failed: "+",".join(failed)
 return {
  "result":"17_STATIC_ASSERTIONS_PASS_NOT_RUNTIME_PARITY",
  "source_baseline_commit":"02893d86e827e1f281d8a6496be9ad9789609730",
  "original_duonavi_dylib_sha256_from_prior_verified_audit":"44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15",
  "log23_sha256_from_prior_analysis":focused["log_sha256"],
  "checks":checks,
  "counts":{"passed":len(checks),"home_requests":26,"host_observed":16,"standalone_hosted_ack":0,"native_dock_active":0,"attach_failures":8,"null_identity_pending":8,"first_host_dimensions_swapped":2},
  "source_git_blobs":{key:{"path":path,"sha":sha} for key,(path,sha) in PINS.items()},
  "limitations":["Previous original-DEB static audits and prior Log23 parser are inputs, not rerun vendor binary/disassembly or device runtime.","New Solo readiness guard telemetry added, but no actual device log yet identifies which guard rejected Log23. Exact native throw operation, Home navigation branch, pixel/first-tap/latency proof are absent.","DuoDash reference package is repacked; not a pristine original."]
 }

if __name__=="__main__":
 p=argparse.ArgumentParser()
 p.add_argument("--repo",type=Path,default=Path(__file__).resolve().parents[3])
 a=p.parse_args()
 print(json.dumps(run(a.repo),ensure_ascii=False,indent=2))
