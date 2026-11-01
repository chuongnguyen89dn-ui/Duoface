# Current Home app launch compared with genuine DuoNavi route — 2026-11-01

## Evidence basis
Original side: bounded static callgraph in original-execution-route-20261031/ROUTE_FINDINGS.md and original-manager-window-route-20261031/MANAGER_WINDOW_FINDINGS.md, genuine dylib SHA44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15. This is NOT a new side-by-side original-device test.
Current side: exact Log25 blob8e452cc8c1abc60cc85edccf557de2e1f86dca95 (main7f69f521a69005e0b9bdcd4531a297f2151e6fb6), latest standalone receiver session09:47:28.270ICT, existing pinned analysis qa156-log25-exit-comparison-20261101. Current public nativebridge3; runtime exact package revision not directly exported.
Fresh source DF152NativeWorkspacePrepare.h blobd17cde230c805040977bfd7d18c4244e2b7d4ef6, DF151WorkspaceOwnerCapture.h blobb5b0e52faaee786798563056f06435934e03afd3. New finding is an existing real-runtime bypass, not a new patch or build.

## Stage comparison
| Stage | Original verified static route | Current evidence / limit |
|---|---|---|
| Tap native Home icon | Native Home hook -> bridge manager start |8 current selected requests enter bridge (Safari3/Facebook2/YouTube2/Wyn1). Safari selection path now reaches host; this does not certify every installed app or visual icon rendering. |
| Prepare native foreground workspace | prepareHomeScreenForBridge; if showingApp, closeOfficialTopApp via verified native workspace deactivation/completion | **8/8 resume with dashboard-workspace-unverified**. Preparation guard bypassed; not established equivalent to original. |
| Manager/host lifecycle | request, phone eviction continuation, owned host start/show, manager state notification |8 manager live-owned scene, process PID and host outcomes observed. Source independently has manager/scene separation; full original branch/lifecycle parity not proven. |
| Root/content boundary | Full external root + separate usable content, pass-through input | Current source implements separate root/content and scoped Dock pass-through. Static/source and prior signed proof; physical touch/window behavior not certified by ACK. |
| App-side state | Selected app listener, layout and restore |62 real general app ACKs from Safari/Facebook,5 restored receipts, one actual window-adjusted1/restored1. YouTube separate receiver; Wyn outside14 generic filter. Transport boundary is now device-observed. |
| Native Dock | Manager activated response -> native active/history/Home state |8 native-dock-active and8 restore observations; exact visual/current app UI still needs user evidence. |
| Press Home | Original hook requests manager stop, then forwards Apple original | User confirms wrong destination: bridged app goes Home CarPlay instead of app chooser. Current code posts async stop then original, later cached Dock/Home restore. Original also forwards; suppressing Apple Home is not justified. |

## Newly verified native workspace bypass (not just exit delay)
All8 DF151 snapshots contain:
captured=1 dashboardOwner=1 workspaceClass=DBWorkspace homeGetter=0 workspaceSame=0 showingAppGetter=0 showingApp=missing stateGetter=1 activeGetter=1 activeBundle=com.apple.CarPlay.dashboard.
Each immediately followed by qa152-native-prep-resume cause=dashboard-workspace-unverified. Exact Log25 snapshot/resume line pairs:
15440/15441,15504/15505,15565/15566,15616/15617,15661/15662,15724/15725,15768/15769,15821/15822.

DF152PrepareThenContinue explicitly calculates workspaceMatched from actual Dashboard owner/captured workspace AND DF151SafeObjectGetter(home,"workspace") AND identity equality. On false, it resumes old standalone continuation without native state mutation and returns BEFORE showingApp query or deactivation request. Thus the request/scene successes later do not prove the native preparation stage actually ran.

homeGetter=0 means no ABI-verified object getter; it is not proof the method is absent. Snapshot's showingAppGetter also uses object getter check, whereas DF152 has a BOOL-aware helper; do not conclude a native BOOL selector is absent from this snapshot. Here DF152 never reaches that helper because workspaceMatched already false. activeBundle dashboard cannot identify Calendar or Music or establish displayed native page.

## Current verdict and next boundary
Opening now has actual app-process/scene/Dock evidence, but native workspace integration and return-to-chooser behavior are not equivalent to the original. No numerical percent-complete claim. Native-app preparation is **source implemented but runtime bypassed in8/8 latest requests**; do not list it as completed parity.
Next inspect exact actual Home receiver and supported native workspace access/ownership relationship against genuine original and measured ABI. Recover chooser/navigation context and validate native exit destination. Do not remove ownership guards, manufacture a workspace, block Apple Home or blame async latency alone. Source gap is confirmed; its causal contribution to the wrong destination remains a hypothesis requiring matching native navigation state. No new runtime code/build/release in this comparison turn.
