# Native12 gốc ↔ DuoFace mới 0.0.17: kiểm toán 43/28 FILE theo CHỨC NĂNG

**2026-10-21 — bằng chứng kiểm kê tĩnh, KHÔNG phải nghiệm thu CarPlay.** Duy nhất Native12 gốc và DuoFace mới. Tuyệt đối không dùng DuoNavi làm nguồn đối chiếu.

## A. Định danh bất biến
- Original Native12: `dist/payload-migration/native12-speed8compact/com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb`, source commit `1286a3ef868cf7e29804bcddf7e20b2eae707ce1`, SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`.
- Candidate DuoFace merged: `sideplay/jb-embedded-appbridge/evidence/runs/39615150459/com.duoface.jb.embedded_0.0.17~native12layout1_iphoneos-arm64.deb`, SHA256 `d1f063091449d24f2b61f85263159ac4aef1e984e44a22566e9fcecbc72c211c`, [successful package run](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39615150459).
- [Original vs candidate inventory run 39617487337](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39617487337) completed success, with actual results in `sideplay/audit/native12-vs-new-20261021/results-0.0.17/{FILE_INVENTORY.json,SUMMARY.json,ALL_NATIVE12_1385_METHODS.json,FEATURE_GATES.json}`.
- Audit script `sideplay/audit/native12-vs-new-20261021/compare_native12_new_full.py` independently verifies exact input SHA, extracts all files, compares per-file SHA, catalogs Mach-O and original 1,385 ObjC methods. **It does not execute or dynamically compare the apps.** The 25 `full_functional_parity_proven` fields are *hardcoded false* by design; they do NOT represent 25 performed on-device tests.

## B. Where the 15-file net difference ACTUALLY comes from

| Payload class | Original | New | Delta new − old | Interpretation |
|---|---:|---:|---:|---|
| App icon PNG sizes | 18 | 2 | −16 | Different icon packaging sizes; not 16 independent features |
| Main iPhone app executable and Info.plist | 2 | 2 | 0 | **Function content not equivalent**: old 1,220,256-byte DuoFaceUI vs new 153,840-byte DuoFaceNativeHost; size itself not proof |
| Supporting art/visual files (excluding app icons) | 8 | 13 | +5 | New includes two copies of six visual names + a separate logo; original includes 3 VisualAssets, manifest, four loose images |
| Launch storyboard files | 0 | 3 | +3 | New packaging details, not more functional parity |
| Tweak libraries and their injection plists | 12 (6+6) | 8 (4+4) | −4 | Different modules; functional gaps need explicit mapping |
| Original helper + command script + sudoers configuration | 3 | 0 | −3 | Must determine if functionality is needed; **do not copy elevated-privilege paths just to equalize count** |
| **TOTAL** | **43** | **28** | **−15** | Raw count is NOT a functional pass/fail test |

**13 byte-identical basename/path matches in the script are just six types of approved visual PNG used in multiple new locations; they do not prove 13 features.** New app launch storyboard was additionally installed; original had many legacy icon sizes. Deduplication can produce a smaller DEB without loss of behavior; this project has not proven all behavior was preserved.

## C. 8 old compiled Mach-O → 5 newly compiled Mach-O: real functional risk

| Original native Mach-O, exact extracted path basename | New first-party possible implementation | Evidence classification | What is STILL missing / test needed |
|---|---|---|---|
| `DuoFaceUI` (1,220,256 bytes; 522 ObjC methods) | `DuoFaceNativeHost` (153,840 bytes), `DFNativeHostRootController.m` | **PARTIAL**, not ABI equivalent | Native12 phone preferences, app-manager, assistant/voice features vs new small status/app/layout tab |
| `DuoFaceDashboard.dylib` (3,760,032 bytes; 757 ObjC methods) | `DFTouchOwnerProbe.dylib` (200,064 bytes), `DFNativeDashboardBridgeQA.dylib` (275,520 bytes), `DFFirstPartyAdmission.dylib` (187,024 bytes), `DFV1APreflight.dylib` (292,160 bytes) | **PARTIAL/NOT VERIFIED** | CBWindow CarPlay geometry, native system AppDock owner, multi-app scene lifetime, and split/receiver ABI not shown equivalent; new binaries named QA/Preflight still present |
| `DuoFaceFullscreenBridge.dylib` (124,976 bytes; 61 ObjC methods) | `DFNative12Chrome.zoomPressed`, but no proven active `DFFullscreenTransport` equivalent | **FUNCTIONAL ABSENCE** | System-owned Dock hide/restore + focus lease/snapshot/ACK/rollback. Resizing only inside contentRect does not reproduce it |
| `DuoFaceLogoGripOnly.dylib` (72,320 bytes; no exported ObjC method list) | UI and gestures in `DFNative12Chrome` | **PARTIAL** | Native12 grip position/hold/drag, touch hitboxes/animation and shutdown equivalence must be measured |
| `DuoFaceSpeedHUD.dylib` (106,928 bytes; 44 methods) | No equivalent running 4-source speed HUD service in merged binary | **FUNCTIONAL ABSENCE** | Real data source adapters, one HUD view, app lifecycle and persist settings |
| `DuoFaceSpeedOwner.dylib` (70,736 bytes; one method plus C/closure code) | No proven HUD-specific independent owner | **FUNCTIONAL ABSENCE** | SpringBoard process ownership, data/speed update, teardown and privacy checks |
| `DuoFaceVisualHook.dylib` (75,536 bytes; no ObjC method list) | Approved artwork, Chrome and Picker rendering | **PARTIAL** | Actual Native12 window levels, red-border timer, pill shape/position and startup transitions |
| `duoface_cboptimize_helper` (150,528 bytes) | No direct bundled executable | **UNRESOLVED DEPENDENCY, NOT automatically a required feature** | Trace old helper callers and task before deciding whether to implement a least-privilege independent equivalent |

Old injection filters: `DuoFaceDashboard.plist`, `DuoFaceFullscreenBridge.plist`, `DuoFaceLogoGripOnly.plist`, `DuoFaceSpeedHUD.plist`, `DuoFaceSpeedOwner.plist`, `DuoFaceVisualHook.plist`. New filters: `DFFirstPartyAdmission.plist`, `DFNativeDashboardBridgeQA.plist`, `DFTouchOwnerProbe.plist`, `DFV1APreflight.plist`. Need compare injection targets/process role, not just existence.

Old `duoface-cboptimize`, `sudoers.d/duoface`: absent. Neither copy nor run old helper without knowing behavior, security and license implications.

## D. Method-level verification required; missing from present audit

Original method-index already records class, selector, IMP address and Objective-C type encoding. It can map **where** to investigate; identical strings in the new binaries (294 of 1,385 method entries) are NOT an operational edge.

| Functional path | Original reference and known code | New source candidate | Verification still missing |
|---|---|---|---|
| Split ratio, persistent state | `CBBridgedSplitApp.handleDividerPan:isVertical:state:` IMP `0x103ee0` → `setSplitRatio:` `0x104100` → `layoutSplitViews` `0x1044f8` → saved state `0x104330` | `DFNative12Chrome.dividerPan/layoutControls/saveSplitState`; `DFLayoutEngine` | Exact input ABI, ratio math, preset rules, live scene frames and restore after disconnect; unit geometry + real head unit required |
| Eight presets and four slots | `CBBridgedSplitApp.setSplitPreset:`, `CBDashboardSettings.gridRows/gridCols/setSplitApp1..4:`, `CBMultitaskingOverlayView.presetSelected:` `0xaa4f0` | `DFLayoutEngine.m` case 0..7, `DFNative12Chrome` 4 UIWindow, iPhone `Bố cục` tab | **The eight new frame formulas were independently invented; ORIGINAL eight frame values are NOT decoded or compared.** No proven Native12 pixel/layout parity. Inspect original disassembly/graphics fixtures before claiming match |
| Open/replace app scene | `CBBridgedSplitApp.replaceAppInSlot:withBundleIdentifier:` `0x1098c0`, `CBBridgedUIAppView` ownership | `DFSceneHost` real SBAppViewController lease, `DFNative12Chrome.appPicker:didSelect/sceneReady` | Same bundle identity, real attachment/visible state, touch and repeat open/close, AV lifecycle; run on device |
| Focus and system Dock | `CBBridgedSplitApp.focusSlot:animated:` `0x105890`, `CBWindow.carPlayUsableBounds` `0xb0ef4`, `CBDashboardShared.appDockVC` | `DFNative12Chrome.zoomPressed/layoutControls` | Real CarPlay Dashboard AppDock hide/restore and scene snapshot/rollback not implemented/verified; no fake overlay |
| Video | Old `CBBridgedUIAppView` media app host | `DFSceneHost.start/layoutScene/pollScene/stop` | On-device SpringBoard .ips/crash stack/AV session and video seek/playback; compile PASS is insufficient |
| HUD | `DFSpeedNativeHUD`, `DFSpeedSplit7Driver`, `DFOwnerPollingDriver` | No equivalent first-party speed owner/data adapters | Need independently written speed service and verified source updates; historical HUD assets do not implement data flow |

**No evidence that 294 selector entries are 294 correct functions.** Static compare does not resolve all 1,087 original optimized stubs or 2,509 function starts (C, block trampolines etc). Current strict `25/25 KHONG_DAT` gates are **unproven** state, because script hardcodes the gate status; not a 25-test runtime failure report.

## E. Required next evidence to finish, not guess
1. For each user-visible Native12 feature: trace original **caller → selector → IMP/type encoding → receiver/process → state/data → UI/scene → cleanup**. Mark static confidence B/I/C/P separately; never promote to runtime R without a vehicle test.
2. Build a same-input geometry replay for all eight Native12 presets using disassembled constants/branches and current `DFLayoutEngine`; compare normalized rectangles, scene slot order and clamp/snap; test all 8.
3. For Dock/Fullscreen, identify actual iOS 16 CP Dashboard AppDock view owner and frame/visibility commands with an on-device safe logger before integrating reversible first-party control. Without this, Zoom cannot be declared equivalent.
4. For YouTube/Safe Mode, collect SpringBoard .ips/backtrace; verify scene and AV teardown. No assumption about the faulting private function without stack evidence.
5. Implement missing **independent** HUD data/owner, voice/settings, and any genuinely needed helper role; keep vendor license runtime deliberately unported.
6. Release one version to public Sileo only when signed/combined DEB, true feature checks and physical CarPlay/iPhone tests pass. Current public Sileo unchanged.

**Machine-verified scope:** exact SHA of both input DEBs, per-file bytes/sha, presence of eight vs five Mach-O, complete original 1,385 ObjC method index, 294 mere selector text overlaps. **Not verified:** behavior/geometry/Dock/video/HUD/voice/CarPlay physical equivalence. No new build/publish performed in this inventory report.
