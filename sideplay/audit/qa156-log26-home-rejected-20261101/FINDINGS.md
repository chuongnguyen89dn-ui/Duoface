# Log26 — nativebridge4 Home navigation REJECTED by physical user

User reports unchanged incorrect navigation: unsupported-app Home goes directly to “Home CarPlay”, not “trang chọn app”. This is a failed physical acceptance result and supersedes the previous physical-pending status, not the verified publication state. No package installation/reselection/respring repetition is justified by this finding.

## Input and new execution proof

Read actual main c82247fac5fbe1029a150ec68a4dbef0a17a93f9, `sideplay/log/DuoFaceAudit 26.txt`, blobd376f820d6b4dc88f80b1c269e40257e5c5e4009,5465407bytes, SHA256412a4996507cfc008a740d5902d4b9bd6e3770cfd0a302602313988f55a23645. Export10:27:42ICT, latest standalone receiver10:24:20.893ICT. Existing files contain older sessions; parser isolates the most recent registered receiver, not historical matches.

Five requests: Facebook2, Safari2, YouTube1. All5 actual runtime native-dashboard-context-verified: getter_currentDashboard, anchorDBDashboardHomeViewController, dashboardDBDashboard, workspaceSame1/externalSame1/rootRelated1. All5 qa151 workspace getter+identity and BOOL showingApp getter are1. This positively proves the new receiver repair executed on device; exact installed dpkg version/hash is absent. Hardcoded exporter/build0.0.90 is not downgrade evidence.

All5 snapshots show showingApp=NO and workspace.activeBundle=com.apple.CarPlay.dashboard BEFORE launch; all5 resume cause=native-chooser-ready. This is not dashboard-workspace-unverified anymore. Crucially there is NO equivalent snapshot WHILE hosted or at the Home callback, so do not claim the native state stayedNO or diagnose that as established causality.

All5 manager/live scene/PID/hosted/native Dock-active events present, with homeCaptured1. All5 stop native-Home-exit and native-home-stop Dock restore.66 actual app ACKs total. Nine timestamped native Home pulses;5 correlate with bridge exits,4 unattributed. Home->stop29.365..52.047ms; Home->Dock24.365..130.047ms. These show cleanup happened; they do not identify Apple's navigation branch or returned page. Launch->hosted130..536ms measures manager receipt only, not first visible frame/input latency.

## Changed hypothesis after failed physical result

The old wrong receiver is now ruled out for these5 attempts. A missing stop/undismissed bridge window is also not supported by these receipts. Dock/Home setter alignment alone did not solve page navigation. Current source DF147ActivateDock mutates history/active app/Home button; DF147RestoreDock resets own state. Neither supplies an explicit saved chooser/page transition. This is a source observation, NOT a justified instruction to fabricate a workspace or force a page, because genuine original also delegates to Apple Home.

Read-only bounded recheck of genuine DuoNaviDashboard SHA44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15 this turn confirms original prepareHomeScreenForBridge: showingApp false branches0x2c6074->0x2c6090 invoking continuation0x2c6098. Thus native-chooser-ready/no deactivation for a known chooser follows that branch; do not “fix” it by deactivating dashboard. Original bridgeDidActivate:0x2c70cc..0x2c7140 setsactivated, Dock active ID, Home in-app; handleStateDict:0x2c6f88..0x2c70cc dispatches activate/deactivate and pending completion. These bounded methods contain no newly discovered forced chooser navigation. Original Home forwards saved receiver/selector/event at0x30f5b4/5b8/5bc, call0x30f5c0. No vendor implementation copied.

Still missing in actual Log26: native Calendar/Music identifiers all0; Apple's Home handler entry/return, live showingApp/foreground scene/workspace at Home, home-button displayState before/after, active/visible native Home/Dashboard controller and page destination. Four anonymous Home events cannot be assigned to Calendar/Music. Current geometry/traces do not establish page navigation. Old NowPlaying widget snapshots cannot fill this gap.

Next bounded investigation is the native Home handler's decision and actual native state at activation/Home, compared with genuine original receiver/argument/notification chain. Preserve Apple callback; no suppressing it, guessed delays, repeated Dock-only reset or no-evidence new Sileo package. No runtime edit/build/release this log-check turn; public4 remains available but navigation requirement is REJECTED. Reproducer analyze_log26.py verifies exact input and all5 context/cleanup chains, writes per-request times/lines and bounded excerpts.

Additional bounded check: only identified showingApp selref0x3aa0a8 code read is at0x2c604c in the pinned original scan. This does not establish the absence of dynamically registered alternate hooks, and supplies no basis to add a fabricated showingApp=YES override. Original selected Home library registration selectors were re-resolved; no new native navigation target was verified from that family. No causal fix is claimed from these negative/bounded checks.
