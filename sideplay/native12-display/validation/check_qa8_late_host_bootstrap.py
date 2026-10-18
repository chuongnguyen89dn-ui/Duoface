#!/usr/bin/env python3
"""QA8 targeted checks, not an on-device CarPlay pass."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[3]
source=(ROOT/"sideplay/sileo-qa/Tweak.xm").read_text()
control=(ROOT/"sideplay/sileo-qa/control").read_text()
filter_plist=(ROOT/"sideplay/sileo-qa/DuoFaceSidePlayDisplayQA.plist").read_text()
methods=json.loads((ROOT/"sideplay/native12-display/audit/SIDEPLAY_SPLIT_OWNER_SELECTORS.json").read_text())
owner=next(x for x in methods["matches"] if x["class"]=="SPDash")
selectors={x["selector"] for x in owner["selectors"]}
def ok(condition,why):
    assert condition,why
    print("PASS:",why)
ok("-carWindow" in selectors and "-layout:" in selectors and
   "-layoutRootView" in selectors and "-setCarWindow:" in selectors,
   "SPDash getter and both host layout callbacks exist in audited original binary")
ok("- (UIWindow *)carWindow;" in source and
   "UIWindow *window=[owner carWindow]" in source,
   "QA8 can discover already-created original CarPlay window")
ok('DFSPBootstrapFromLiveOwner(self,@"SPDash.layout")' in source and
   'DFSPBootstrapFromLiveOwner(self,@"SPDash.layoutRootView")' in source,
   "late window bootstrap called from BOTH original host layout events")
ok("if (DFSPManager==owner && DFSPWindow==window && DFSPUI)return;" in source and
   "DFSPBootstrapQueued=YES;" in source and
   "if (!actual || !live || [actual carWindow]!=live)" in source,
   "single-flight queued hook preserves active window owner and rejects stale windows")
ok("if (DFSPHookInstalled)return;" in source and
   "dispatch_after(dispatch_time(DISPATCH_TIME_NOW,5LL*NSEC_PER_SEC)" in source and
   "attempt<30" not in source,
   "no 30-second expiry before SidePlay lazy class load")
ok("QA8 CONSTRUCTOR:" in source and "QA8 HOOKS_READY:" in source and
   "QA8 BOOTSTRAP_ATTACH" in source and
   "QA8 BOOTSTRAP_REJECT" in source and "QA7 owner-check attached=" in source,
   "logs distinguish dylib loaded, hooks ready, window accepted/rejected and host geometry")
ok("%hook SPDash" in source and "%orig(animated)" in source and
   "DFSPHideReplacedView([pane chipView]);" in source and
   "DFSPHideReplacedView([pane layoutButton]);" in source,
   "preserves SidePlay actual app host while hiding old visual controls")
ok("window.frame=desired;" not in source and
   "DFSPHost=[[DFSPNative12Host alloc]" in source and
   "DFSPApply(NO,@\"startup\")" in source,
   "no regression to QA5 window crop or forced fullscreen")
ok('Bundle' not in filter_plist and
   '"com.apple.springboard"' in filter_plist and
   "com.sideplay" in control,
   "rootless filter remains limited to SpringBoard and package depends on SidePlay")
ok("0.1.6~native12bootstrap8" in control,
   "new isolated QA8 package version")
print("QA8 SOURCE INTEGRATION PASS; DEVICE STATE STILL UNKNOWN")
