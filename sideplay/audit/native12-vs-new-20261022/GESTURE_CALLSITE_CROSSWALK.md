# Native12 original ↔ independent DuoFace: divider gesture callsite crosswalk (2026-10-22)

## Immutable evidence (not a runtime claim)

- Original: `dist/payload-migration/native12-speed8compact/com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb`, SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`.
- Extracted 1,385-method original index: `sideplay/audit/qa7-vs-native12-methods-20261018/method-index.json`, Git blob `efa45df59bc3c16887cc979bf3aedc0c93c92111`, commit `a57815b2430092a9c27811a88b53f9bbbb70312d`.
- Original source-approved independent grip: `feature/visual12-duodash-recovery:src/DFDividerLogoGrip.inc`, Git blob `0b14c99ab8ed9283fbb8c98839eb5d0ebc70ad52`.
- Original approved UI reference: `feature/visual12-duodash-recovery:replacement/visual12/engine/runtime/DFINativeShell.inc`, Git blob `836eb52a51a309cf2d9740cfbcb22c407733f33d`.
- **Only Native12 versus new DuoFace. No third-party license runtime linked or copied.**
- New independent code `sideplay/duoface-native-scene-host/DFNative12Chrome.m`, gesture isolation source commit `f8bddb16863abc02a61615495ec5b24fa6856fb3`, source test commit `eaadcfaaa3b6bf8a4561c9b9e35d6cee798622d1`.
- Immutable signed independent host `0.1.25~gestureowner1` SHA256 `fef92578d407debc2dc05e5234e286d238e44e9245cceb6d314ed695188c2a4d`, CI run [39641652056](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39641652056) success for build/sign/static source tests + original 1385-method audit. **Not device tested or Sileo released.**

## Original-to-independent method and interaction mapping

| Original Native12 class/method (original IMP) | Independent DuoFace source | Evidence and limitation |
|---|---|---|
| `CBDividerView.pointInside:withEvent:` `0xff728`, `hitTest:withEvent:` `0xff974` | `DFNativeDividerGripButton.pointInside:withEvent:` and parent track gesture delegate `gestureRecognizer:shouldReceiveTouch:` | Original approved source expands logo touch zone by 12pt. New touch accepts +12pt within bounded external window and prevents parent pan stealing same logo touch. **Original exact runtime window hit forwarding on every CarPlay size is not proven.** |
| `CBDividerView.handleMoveButtonLongPress:` `0x1005f4` | `logoHold:` | Approved >=0.30 seconds and then drag ALONG bar repositions `logoFraction`; never swaps or sets split ratio. User said "3 giây" later; threshold unchanged pending reconciliation with explicit earlier approved value. |
| `CBDividerView.moveButtonTouchUp:` `0xffeb4` | UIButton `UIControlEventTouchUpInside` to `swapPressed:` | Short TAP swaps physical slots; long hold/pan recognizer cancels late touch-up. Pixel/device call-path unverified. |
| `CBDividerView.handlePan:` `0x10152c` and `CBBridgedSplitApp.handleDividerPan:isVertical:state:` `0x103ee0` | `dividerPan:` + `DFPrimaryDividerCoordinate` + `DFComputePresetFrames` | Divider pan changes split ratio clamped [1/3, 2/3], snaps within 0.04 of 1/3, 1/2, 2/3. Exact 8 original preset frame arithmetic remains unverified. |
| `CBDividerView.gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:` `0xfea48` | `UIGestureRecognizerDelegate.shouldReceiveTouch:`, `logoPan requireGestureRecognizerToFail:hold` | New approach isolates tap/hold/pan input without importing vendor handlers. ABI/callback ordering in CarPlay UIKit still needs device evidence. |
| `CBDividerView.updateGripLayout` `0xff460` | `layoutControls` | New logo visual size 28/30pt and stored relative fraction 0.1..0.9, original 28/30 reference supported by disassembly. Insets/window boundaries and final pixel geometry not proven. |

## Exact current behavior to preserve

1. Short logo tap: swap left/right real app slots.
2. Hold logo for historical approved >=0.30s then move ALONG the divider: only logo position; no swap, no split ratio.
3. Drag divider CROSS-axis: live ratio resize with snap; live app hosts remain attached.
4. Persist logo position and ratio separately across focus/Style/reconnect. Preserve external CarPlay system Dock and avoid receiving touches outside bounded chrome windows.

## Next actual gates / nonclaims

- Verify touch hitbox+recognizer lifecycle on a stopped-car CarPlay display, including logo edge touch, quick logo tap, held dragging, ratio pan off logo, cancellation, reconnect and two live app scenes. **Successful static assertions and clang build are not proof of this.**
- Exact Native12 original 43-file/1,385 method full mapping versus ONE integrated 0.0.21 DEB after GitHub runner succeeds; keep unknown original static C helpers distinct from Objective-C inventory.
- Original full parity still requires scene registration/touch, video/SpringBoard crash trace, proper system Dock fullscreen/rollback, all eight real layouts, HUD8 four sources, voice/settings, exitmode/reconnect stability and on-device test.
- Final Sileo release is **NO-GO** until those gates verified, despite user's delivery requirement. Do not copy original vendor/license implementation or claim complete because a candidate compiles.
