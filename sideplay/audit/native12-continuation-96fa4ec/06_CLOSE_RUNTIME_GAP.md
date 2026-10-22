# Native12 Close/Restart/Close All — original ABI comparison and remaining runtime proof

Source: original SHA256 DEB `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`, original DuoFaceDashboard.dylib SHA256 `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`, persisted static disassembly `sideplay/audit/native12-continuation-4888299/original-picker-close-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json`.

Verified original:
- `CBMultitaskingOverlayView.closeSingleAppTapped:` IMP0xa9484, @a9578 obtains `CBBridgeManager sharedInstance`, @a9598/@a95a0 calls `terminateApplicationWithBundleID:` with real selected BundleID.
- `restartSingleAppTapped:` IMP0xa91ec, @a92e0 gets shared manager; @a9300/@a9308 invokes `restartApplicationWithBundleID:`.
- `closeAllBridgedAppsTapped:` IMP0xa9838, @a98e8 original logging string explicitly `Killing background apps & restarting active on-screen apps`. @a98f4 gets manager; @a9914/@a9918 calls `terminateAllBridgedApplications`.
- `dismissOverlay` IMP0xab70c is entirely separate from above. Thus X does NOT mean Close. Native12 inner modal has three tabs Apps/Layout/Recent, and RECENT uses live `runningBridgedApplications` rather than recent-list guess.

Verified *current independent implementation*:
- `DFNative12Chrome.m` opens running manager with real `DFSceneHost`-owned ready BundleIDs; `DFAppPickerVC.m` renders real Close/Restart/CloseAll controls. `closeHostedSlot` calls `DFSceneHost releaseHostedView:`; `DFSceneHost.m` stops/invalidate its own `SBAppViewController` / removes the view. This is a **scene release, not necessarily process termination**.
- Current CloseAll enumerates owned visible panes only; there is **no verified equivalent of terminating background iPhone processes and restarting active on-screen apps**.
- Current Restart releases scene and starts a new host asynchronously; it does not call original vendor `CBBridgeManager` (must remain independent).
- A vendor manager selector is not evidence any independent SpringBoard ABI can safely terminate arbitrary OS processes. No `killall`, hardcoded launch agent, private method guessed, or third-party license binary will be added. Need a separate source/test/device-grounded process lifecycle owner and rollback before claiming equality.

Next implementation gate: inspect prior working independent code/handoff for confirmed process termination API and exact SpringBoard ownership, write fail-closed live capability probe/test. Only after a verified compatible selector and real device safe-mode regression can Close/Restart/Close All be marked original-parity-complete. As of this audit the OS-termination gate remains OPEN; never present closeHostedSlot as equivalent to terminateApplicationWithBundleID. No change to installed/public DEB, no deployment.
