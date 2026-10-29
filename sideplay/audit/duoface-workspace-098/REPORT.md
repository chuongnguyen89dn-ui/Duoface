# DuoFace #5-#7: Remember apps / rotate 3-4 positions / owned-running status

2026-10-29; repository chuongnguyen89dn-ui/Duoface; branch feature/duoface-jb-embedded-appbridge-20261020.

## Evidence and source ownership

- Existing DFNative12Chrome has four real physical UIWindow owners and four corresponding appSceneContainers, while DFSceneHost holds SpringBoard-owned SBAppViewController remote app lifecycle. Original split prefs only persisted ratio, 9-preset, logo position and 2-slot swapped; no verified per-app restore and no trustworthy PID.
- DFSceneSurface.start binds an app controller to its current parent, and scene readiness requires actual window + hosting owner. Reparenting it between different UIWindows is dangerous. Therefore 3/4 rotation repositions whole physical app UIWindow frames using an independently persisted bijective visual order; no hosted view or app-controller reparenting.
- The original .92 three-second logo source was preserved **byte-for-byte** in tests/fixtures/logo92_contact_and_swap_baseline.txt, sourced from DFNative12Chrome Git blob 367689325f6ff84d8d258ff9891ec85338a7d647. An exact original method regression test still runs even though the Chrome file grows.

## Implemented (source only)

- DFSlotWorkspacePolicy.h: versioned, atomically saved and re-read four physical bundle IDs and separate three/four visual permutations; duplicate/invalid IDs fail; no scene handles, PIDs, private process info or third-party license stored.
- DFNative12Chrome.m: records each app only after sceneReady, clears saved slot on explicit Close, retains on CarPlay Home; after new session splash, sequential restore of still-installed + explicitly iPhone-enabled app IDs, one outstanding app at a time, 7s timeout and generation guard. Never invents a ready callback.
- DFNative12Chrome.m: position rotation only if 3 or 4 actual hosted live slots are ready and no pending; same UIWindow remains owning each app, only the bounded visual positions change. Old two-position swap remains through existing Swapped preference.
- DFNativeHostRootController.m: iPhone apps settings now include enable/disable restoration and clear stored app choices; not fixed left/right/slot assignment UI.
- DFSceneHost.m/.h: actual owned-host checks and read-only guarded SBApplication PID probe, omitting PID if cannot verify bundle ID, pid>1, not SpringBoard and live via kill(pid,0). No process terminate is performed.
- DFAppPickerVC.m/.h: running cards show scene visible/hidden and optional authentic PID, controls for clockwise and counterclockwise 3/4-window rotation when all scenes ready. Existing Close/Restart target **only owned scene host**; do not misrepresent this as app-process kill/restart.
- No changes to original Native12 vendor binary or license. No signed DEB or Sileo publish.

## Source commits and QA

- Source checkpoint: aafbf6c8 (workspace policy); beb60541/4f09d1ae (Chrome memory/restore/window rotation, safety correction); ac3d0717/c280694c (live PID probe); 2c1b1555/1e1b1919 (picker interface/UI); 8eb4771c (Chrome delegate integration); 0b0ff6e0/f2a056b (golden logo fixture/check); 9884e812 (iPhone restore menu); 0b892512/3b72f461 (Foundation/Python tests); 2103dfe3 (098 macOS and iOS16 source-only CI). Branch HEAD can move due to CI handoff commits.
- Test working dir: sideplay/duoface-native-scene-host; Foundation runtime xcrun clang -fobjc-arc -fblocks -Wall -Wextra -Werror -framework Foundation -I . tests/workspace_runtime.m -o <runner temp>/workspace, then execute; Python: python3 -m unittest discover -s sideplay/duoface-native-scene-host/tests -p test_workspace_098.py -v; iOS syntax as workflow .github/workflows/duoface-098-workspace-smoke.yml.
- Initial 098 CI run 40799166970 failed at source-only test asserting wrong variable self.restoreGeneration instead of actual owner.restoreGeneration. Fixed exact test at a3165afd. Do NOT claim restored or media rotation works on physical hardware based on source tests.
- CI results automatically persist to sideplay/audit/duoface-workspace-098/ci/runs/<run>.txt and append the existing sideplay/tiep tuc du an.md. Check the latest result and logs to verify PASS/FAIL.

## Next acceptance and risks

1. Fix any compiler/runtime/source assertions discovered by the 098 workflow. Treat rejected/unknown private PID as PID unavailable; do not synthesize a number.
2. Verify 3/4-app CarPlay iPhone X rootless runtime and actual scene content after visual rotation (YouTube rotation .90, Maps, orientation refresh, dock and logo hold .92); ensure swap/reconnect doesn't lose logical mapping.
3. Compare recorded PID with an actual process list on-device, and test explicit Close/Restart of owned scenes. True operating-system process termination/force-quit is NOT implemented and must be investigated separately before claiming that requirement complete.
4. Only package a fresh signed one-DEB QA and stage/publish to Sileo after user authorization; no current Sileo upload.

## Verified #7 original Native12 binary audit comparison

- Source: docs/duoface-picker-running-state-audit-20261015.md (read-only original binary analysis). It identifies native CBBridgeManager.runningBridgedApplications at IMP 0x280D48. Native binary distinguishes three data predicates: inActiveSlot == YES; off-slot with pid>0; off-slot with pid<=0. It uses FBProcessManager.allApplicationProcesses/allProcesses plus SBApplicationController fallback. Original table fields: bundleIdentifier, displayName, icon, isRunning, inActiveSlot, slotIndex and pid.
- Native App actions use restartSingleAppTapped:, closeSingleAppTapped: and closeAllBridgedAppsTapped: and do not prove the underlying process-termination contract from the static audit. Current independent source intentionally restricts Close/Restart to DFSceneHost-owned scene views; it does NOT yet reproduce the external background-process inventory or safe OS-level process exit. This portion of #7 is **PARTIAL**, not complete.
- Next source research to complete #7: verify original FBProcessManager PID-to-bundle ownership lookup and original Close/Restart call chain and exact signatures from original DEB. Add only read-only, self-consistent results first. Never issue speculative terminate/kill against SpringBoard or unrelated process. Then test on a jailbroken iPhone with PID cross-check.

## CI and checkpoints confirmed

- First run 40799166970 FAILED a wrong source-test assertion using self.restoreGeneration instead of owner.restoreGeneration; corrected at a3165afd. Next run 40799287192 FAILED an outdated legacy source assertion requiring no negative visual slot, fixed by widening the actual inactive UIWindow guard and test at 101a632f/ecd0ad3e. These errors remain preserved in per-run CI evidence.
- Final source safety change ea3f5a72 adds real physical UIWindow frame readback after 3/4 clockwise/counterclockwise position rotation, with a rollback if remote geometry refuses. This does not alter an app's SBAppViewController parent.
- Latest successful source-only macOS/iOS16 CI: https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40799616425; source SHA ea3f5a7206f5a132b1d42394dfb6fa8d1df94260; job 123204299188; 97 Python source/legacy regression cases PASS (7+3+74+5+4+4), 4 actual Foundation executables PASS (DF_WORKSPACE_RUNTIME_PASS, DF_PICKER_DISPLAY_RUNTIME_PASS, ENABLED_APPS_POLICY_RUNTIME_PASS, APP_HABITS_RUNTIME_PASS), all changed Objective-C owners pass iOS16 SDK syntax check.
- GitHub Actions appended the existing sideplay/tiep tuc du an.md and archived the immutable result in sideplay/audit/duoface-workspace-098/ci/runs/40799616425.txt and ci/LATEST_RESULT.txt. The exact run and checkpoint commit should be read back before claiming persistence.
- Explicit release gate: source code only, NO newly signed integrated DEB, NO Sileo publication, NO device/video/navigation/PID process termination physical QA. The next output to user must distinguish these states precisely.
