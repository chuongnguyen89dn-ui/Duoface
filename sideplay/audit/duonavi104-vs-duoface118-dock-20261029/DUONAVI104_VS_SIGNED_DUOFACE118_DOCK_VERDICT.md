# Original DuoNavi 1.0.4 vs signed DuoFace .118: CarPlay Dock and pane geometry

**Read-only binary verification. This is not a device measurement or a proved no-gap correction.**

- Original signed source: `dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb`
- Original DEB SHA256: `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`
- Original `DuoNaviDashboard.dylib` SHA256: `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`
- Current immutable signed DuoFace `0.0.118~dock-rollback1` SHA256: `4b566ea40727df0acfd7baab8268dac2bfc8ada2779ad5ec6964b43f7b6793fb`
- Current real signed binary includes `DFTouchOwnerProbe.dylib` and `DuoFaceNativeHost`.
- Original extracted IMPs and disassembly in `ORIGINAL_DUONAVI104_DOCK_IMP.json`.

## Original binary: geometry owner and callsites

### `CBWindow.carPlayContentInsets` @0xb1370
ARM64 instructions: 151. Exact relevant callsites:
- `0xb1464: ldr x1, [x8, #0xfb8]  ; SEL_OR_LITERAL 'activeCarPlayWindow'`
- `0xb1484: ldr x21, [x8, #0xfc0]  ; SEL_OR_LITERAL 'rootWindow'`
- `0xb14c0: ldr x22, [x8, #0xfc8]  ; SEL_OR_LITERAL 'safeAreaInsets'`

### `CBWindow.carPlayUsableBounds` @0xb15cc
ARM64 instructions: 63. Exact relevant callsites:
- `0xb15e8: ldr x1, [x8, #0xfd0]  ; SEL_OR_LITERAL 'carPlayScreenBounds'`
- `0xb1604: ldr x1, [x8, #0xfd8]  ; SEL_OR_LITERAL 'carPlayContentInsets'`

### `CBWindow.carPlayScreenBounds` @0xb0ddc
ARM64 instructions: 357. Exact relevant callsites:
- No labeled matching callsite in bounded function; inspect full instructions.

### `CBWindow.carPlayUIScreen` @0xb0538
ARM64 instructions: 103. Exact relevant callsites:
- No labeled matching callsite in bounded function; inspect full instructions.

### `CBWindow.carPlayScreenScale` @0xb0c74
ARM64 instructions: 90. Exact relevant callsites:
- No labeled matching callsite in bounded function; inspect full instructions.

### `CBWindow.getCarPlayDisplay` @0xb16c8
ARM64 instructions: 29. Exact relevant callsites:
- No labeled matching callsite in bounded function; inspect full instructions.

### `CBWindow.resetCachedBounds` @0xafa40
ARM64 instructions: 72. Exact relevant callsites:
- No labeled matching callsite in bounded function; inspect full instructions.

### `CBWindow.createWindows` @0xb173c
ARM64 instructions: 586. Exact relevant callsites:
- `0xb1bc0: ldr x1, [x22, #0xfd0]  ; SEL_OR_LITERAL 'carPlayScreenBounds'`
- `0xb1c5c: ldr x25, [x8, #0x28]  ; SEL_OR_LITERAL 'setWindowLevel:'`
- `0xb1c88: ldr x1, [x22, #0xfd0]  ; SEL_OR_LITERAL 'carPlayScreenBounds'`
- `0xb1ca8: ldr x1, [x8, #0xdf0]  ; SEL_OR_LITERAL 'carPlayUsableBounds'`
- `0xb1cd8: ldr x24, [x8, #0x7f8]  ; SEL_OR_LITERAL 'setFrame:'`
- `0xb1cfc: ldr x1, [x8, #0x950]  ; SEL_OR_LITERAL 'setHidden:'`
- `0xb1ec8: ldr x1, [x8, #0x7b0]  ; SEL_OR_LITERAL 'setClipsToBounds:'`

### `CBWindow.resizeWindows` @0xb24ac
ARM64 instructions: 218. Exact relevant callsites:
- `0xb24e8: ldr x1, [x8, #0xfd0]  ; SEL_OR_LITERAL 'carPlayScreenBounds'`
- `0xb2508: ldr x1, [x8, #0xdf0]  ; SEL_OR_LITERAL 'carPlayUsableBounds'`
- `0xb2538: ldr x1, [x23, #0x7f8]  ; SEL_OR_LITERAL 'setFrame:'`
- `0xb25c4: ldr x1, [x23, #0x7f8]  ; SEL_OR_LITERAL 'setFrame:'`
- `0xb25ec: ldr x1, [x23, #0x7f8]  ; SEL_OR_LITERAL 'setFrame:'`
- `0xb2650: ldr x1, [x8, #0x7b0]  ; SEL_OR_LITERAL 'setClipsToBounds:'`
- `0xb26e4: ldr x1, [x23, #0x7f8]  ; SEL_OR_LITERAL 'setFrame:'`
- `0xb26f8: ldr x1, [x23, #0x7f8]  ; SEL_OR_LITERAL 'setFrame:'`

### `CBWindow.initWithAppFrame:` @0xaf960
ARM64 instructions: 49. Exact relevant callsites:
- `0xaf9e0: ldr x1, [x8, #0xf38]  ; SEL_OR_LITERAL 'resizeWindows'`

### `CBBridgedSplitApp.layoutSplitViews` @0x10bad8
ARM64 instructions: 1254. Exact relevant callsites:
- `0x10bb28: ldr x1, [x8, #0xdf0]  ; SEL_OR_LITERAL 'carPlayUsableBounds'`
- `0x10bc8c: ldr x9, [x8, #0x950]  ; SEL_OR_LITERAL 'setHidden:'`
- `0x10bca0: ldr x8, [x8, #0x828]  ; SEL_OR_LITERAL 'setUserInteractionEnabled:'`
- `0x10bcb4: ldr x8, [x8, #0x7f8]  ; SEL_OR_LITERAL 'setFrame:'`
- `0x10bcc0: ldr x10, [x8, #0x970]  ; SEL_OR_LITERAL 'setBounds:'`
- `0x10bd54: ldr x8, [x8, #0xd90]  ; SEL_OR_LITERAL 'refreshSceneLayout'`
- `0x10bd60: ldr x9, [x8, #0x978]  ; SEL_OR_LITERAL 'setNeedsLayout'`
- `0x10c350: ldr x23, [x8, #0x950]  ; SEL_OR_LITERAL 'setHidden:'`
- `0x10c4b0: ldr x10, [x10, #0x950]  ; SEL_OR_LITERAL 'setHidden:'`
- `0x10c4c4: ldr x8, [x8, #0x828]  ; SEL_OR_LITERAL 'setUserInteractionEnabled:'`
- `0x10c4d0: ldr x10, [x8, #0x970]  ; SEL_OR_LITERAL 'setBounds:'`
- `0x10c570: ldr x10, [x8, #0x978]  ; SEL_OR_LITERAL 'setNeedsLayout'`
- `0x10c5d0: ldr x8, [x11, #0x7f8]  ; SEL_OR_LITERAL 'setFrame:'`
- `0x10cb14: ldr x23, [x8, #0x7f8]  ; SEL_OR_LITERAL 'setFrame:'`
- `0x10cb1c: ldr x24, [x8, #0x950]  ; SEL_OR_LITERAL 'setHidden:'`
- `0x10cdac: ldr x1, [x8, #0x7f8]  ; SEL_OR_LITERAL 'setFrame:'`

- NOT FOUND in ObjC metadata: `CBBridgedSplitApp.updateBoundsSize`
### `CBBridgedSplitApp.setSplitRatio:` @0x12807c
ARM64 instructions: 4. Exact relevant callsites:
- No labeled matching callsite in bounded function; inspect full instructions.

### `CBBridgeManager.receivedMetricsUpdatedNotification:` @0x1f37ac
ARM64 instructions: 148. Exact relevant callsites:
- `0x1f3898: ldr x1, [x8, #0xdf0]  ; SEL_OR_LITERAL 'carPlayUsableBounds'`
- `0x1f392c: ldr x1, [x8, #0xf38]  ; SEL_OR_LITERAL 'resizeWindows'`

### `CBBridgeManager.renderSizeForBundleID:` @0x26fad0
ARM64 instructions: 510. Exact relevant callsites:
- `0x26fd70: ldr x1, [x8, #0xdf0]  ; SEL_OR_LITERAL 'carPlayUsableBounds'`
- `0x26fdb0: ldr x1, [x8, #0xdf0]  ; SEL_OR_LITERAL 'carPlayUsableBounds'`
- `0x26fff8: ldr x1, [x8, #0xdf0]  ; SEL_OR_LITERAL 'carPlayUsableBounds'`
- `0x270030: ldr x1, [x8, #0xdf0]  ; SEL_OR_LITERAL 'carPlayUsableBounds'`
- `0x2701b4: ldr x1, [x8, #0xdf0]  ; SEL_OR_LITERAL 'carPlayUsableBounds'`
- `0x2701d8: ldr x1, [x8, #0xdf0]  ; SEL_OR_LITERAL 'carPlayUsableBounds'`
- `0x270238: ldr x1, [x8, #0xdf0]  ; SEL_OR_LITERAL 'carPlayUsableBounds'`
- `0x270274: ldr x1, [x8, #0xdf0]  ; SEL_OR_LITERAL 'carPlayUsableBounds'`

### `CBBridgedUIAppView.layoutSubviews` @0xac3cc
ARM64 instructions: 31. Exact relevant callsites:
- No labeled matching callsite in bounded function; inspect full instructions.

### `CBBridgedUIAppView.updateLayout` @0xac7cc
ARM64 instructions: 743. Exact relevant callsites:
- `0xac8b4: ldr x21, [x8, #0x888]  ; SEL_OR_LITERAL 'setTransform:'`
- `0xac8cc: ldr x23, [x8, #0x7f8]  ; SEL_OR_LITERAL 'setFrame:'`
- `0xac9b4: ldr x20, [x8, #0x7f8]  ; SEL_OR_LITERAL 'setFrame:'`
- `0xaca24: ldr x20, [x8, #0x7f8]  ; SEL_OR_LITERAL 'setFrame:'`
- `0xacb24: ldr x24, [x8, #0xdd8]  ; SEL_OR_LITERAL 'setContentReferenceSize:withInterfaceOrientation:'`
- `0xacb5c: ldr x24, [x8, #0xde0]  ; SEL_OR_LITERAL 'setContentReferenceSize:withContentOrientation:andContainerOrientation:'`
- `0xacd34: ldr x1, [x8, #0x7b0]  ; SEL_OR_LITERAL 'setClipsToBounds:'`

### `CBBridgedUIAppView.refreshSceneLayout` @0xadc30
ARM64 instructions: 54. Exact relevant callsites:
- `0xadcb0: ldr x1, [x8, #0x978]  ; SEL_OR_LITERAL 'setNeedsLayout'`
- `0xadcdc: ldr x1, [x8, #0x980]  ; SEL_OR_LITERAL 'layoutIfNeeded'`

### `CBBridgedUIAppView.updateSceneSettingsFrame` @0xad368
ARM64 instructions: 559. Exact relevant callsites:
- `0xad3d8: ldr x1, [x8, #0xdf0]  ; SEL_OR_LITERAL 'carPlayUsableBounds'`
- `0xad428: ldr x21, [x8, #0xdd8]  ; SEL_OR_LITERAL 'setContentReferenceSize:withInterfaceOrientation:'`
- `0xad468: ldr x23, [x8, #0xde0]  ; SEL_OR_LITERAL 'setContentReferenceSize:withContentOrientation:andContainerOrientation:'`
- `0xada70: ldr x22, [x8, #0x7f8]  ; SEL_OR_LITERAL 'setFrame:'`

## Current DuoFace .118 — exact signed source geometry chain

- CPWindow_delegate_uses_safeAreaLayoutGuide.layoutFrame: YES
- delegate_uses_entire_CPWindow_bounds_if_safe_empty: YES
- host_sends_ContentRect: YES
- SpringBoard_second_left_floor_MAX_42_or_8_2_percent: YES
- SpringBoard_clamps_valid_ContentRect_again: YES
- SpringBoard_fabricates_rail_if_ContentRect_invalid: YES
- Chrome_positions_panels_from_contentRect_origin: YES

The current iPhone CPWindow computes `ContentRect` from `frame + safeAreaLayoutGuide.layoutFrame`, with an **unconditional fallback to the entire CPWindow bounds when layoutFrame is empty**. The SpringBoard owner then applies a **second independent left boundary floor** `MAX(42pt, 8.2% screen width)` to that content rectangle, or invents a region with the same floor when content is invalid. The independent Chrome places all app panes in the resulting rectangle.

**Not equivalent to proving a literal physical gap.** We have not captured the current screen's measured rootWindow.safeAreaInsets, actual Apple Dock frame, or `ContentRect` before and after the clamp. Neither binary's static geometry can supply those device-dependent values. A derived example is not a measurement.

**Do not copy** proprietary vendor methods/gestures/license, invent another 42pt/64pt constant, crop native Dock, or publish a new DEB solely from this static diff. First isolate `native-root-window safeAreaInsets` vs `CPWindow safeAreaLayoutFrame` and resulting `pane origin` at runtime. Protect .118 Dock, .90 player orientation and .92 divider.
