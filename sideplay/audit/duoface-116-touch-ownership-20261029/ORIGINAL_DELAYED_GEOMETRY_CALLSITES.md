# Native12 original delayed touch: layout, window and scene callsites

- 2026-10-29, read-only original binary ARM64 extraction, **not a real-car touch test**.
- Original DEB SHA256: `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`.
- Mach-O SHA256: `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`.
- Selected 13 original method IMPs; exact disassembly in `original-delayed-geometry-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json`.
- PC callsites establish selector invocation but not Objective-C receiver or temporal execution order across threads.

## CBWindow.resetCachedBounds @ 0xaf570
- Source boundary: `0xaf570..0xaf690`; 72 instructions, 0 matching callsites.

- No matching named marker in this IMP (not evidence of no indirect call).

## CBWindow.resizeWindows @ 0xb1aac
- Source boundary: `0xb1aac..0xb1d98`; 187 instructions, 7 matching callsites.

    b1b08:	ldr	x1, [x8, #0x320] ; Objc selector ref: carPlayUsableBounds
    b1b0c:	bl	0x2ecd00 ; Objc message: -[x0 carPlayUsableBounds]
    b1b4c:	bl	0x2ecd00 ; Objc message: -[x0 carPlayUsableBounds]
    b1b58:	bl	0x2ecd00 ; Objc message: -[x0 carPlayUsableBounds]
    b1b74:	bl	0x2ecd00 ; Objc message: -[x0 carPlayUsableBounds]
    b1c50:	ldr	x1, [x8, #0xdf8] ; Objc selector ref: setClipsToBounds:
    b1c58:	bl	0x2ecd00 ; Objc message: -[x0 setClipsToBounds:]

## CBWindow.show @ 0xb1d98
- Source boundary: `0xb1d98..0xb1ec0`; 74 instructions, 4 matching callsites.

    b1db4:	ldr	x1, [x8, #0x448] ; Objc selector ref: resizeWindows
    b1db8:	bl	0x2ecd00 ; Objc message: -[x0 resizeWindows]
    b1e08:	ldr	x1, [x8, #0x980] ; Objc selector ref: setHidden:
    b1e10:	bl	0x2ecd00 ; Objc message: -[x0 setHidden:]

## CBBridgedUIAppView.layoutSubviews @ 0xac8f0
- Source boundary: `0xac8f0..0xac940`; 20 instructions, 4 matching callsites.

    ac914:	ldr	x1, [x8, #0xef0] ; Objc selector ref: layoutSubviews
    ac91c:	bl	0x2ecd18 ; Objc message: -[[x0 super] layoutSubviews]
    ac924:	ldr	x1, [x8, #0x2b8] ; Objc selector ref: updateLayout
    ac92c:	bl	0x2ecd00 ; Objc message: -[x0 updateLayout]

## CBBridgedUIAppView.calculateNativeSizeForSlotRect: @ 0xacc28
- Source boundary: `0xacc28..0xacc6c`; 17 instructions, 0 matching callsites.

- No matching named marker in this IMP (not evidence of no indirect call).

## CBBridgedUIAppView.updateLayout @ 0xacc6c
- Source boundary: `0xacc6c..0xad24c`; 376 instructions, 20 matching callsites.

    accf4:	ldr	x1, [x8, #0x2f8] ; Objc selector ref: calculateNativeSizeForSlotRect:
    acd00:	bl	0x2ecd00 ; Objc message: -[x0 calculateNativeSizeForSlotRect:]
    acd44:	ldr	x21, [x8, #0xe30] ; Objc selector ref: setTransform:
    acd50:	bl	0x2ecd00 ; Objc message: -[x0 setTransform:]
    acd5c:	ldr	x23, [x8, #0xa10] ; Objc selector ref: setFrame:
    acd74:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    ace44:	ldr	x20, [x8, #0xa10] ; Objc selector ref: setFrame:
    ace5c:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    aceb4:	ldr	x20, [x8, #0xa10] ; Objc selector ref: setFrame:
    acecc:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    acf9c:	ldr	x24, [x8, #0x308] ; Objc selector ref: setContentReferenceSize:withInterfaceOrientation:
    acfb0:	bl	0x2ecd00 ; Objc message: -[x0 setContentReferenceSize:withInterfaceOrientation:]
    acfcc:	bl	0x2ecd00 ; Objc message: -[x0 setContentReferenceSize:withInterfaceOrientation:]
    acfd4:	ldr	x24, [x8, #0x310] ; Objc selector ref: setContentReferenceSize:withContentOrientation:andContainerOrientation:
    acfe4:	bl	0x2ecd00 ; Objc message: -[x0 setContentReferenceSize:withContentOrientation:andContainerOrientation:]
    ad004:	bl	0x2ecd00 ; Objc message: -[x0 setContentReferenceSize:withContentOrientation:andContainerOrientation:]
    ad0c4:	ldr	x1, [x8, #0xe60] ; Objc selector ref: setCenter:
    ad0cc:	bl	0x2ecd00 ; Objc message: -[x0 setCenter:]
    ad1ac:	ldr	x1, [x8, #0xdf8] ; Objc selector ref: setClipsToBounds:
    ad1b4:	bl	0x2ecd00 ; Objc message: -[x0 setClipsToBounds:]

## CBBridgedUIAppView.refreshSceneLayout @ 0xade58
- Source boundary: `0xade58..0xadf30`; 54 instructions, 9 matching callsites.

    ade70:	ldr	x1, [x8, #0x2b8] ; Objc selector ref: updateLayout
    ade74:	bl	0x2ecd00 ; Objc message: -[x0 updateLayout]
    ade7c:	ldr	x1, [x8, #0x378] ; Objc selector ref: updateSceneSettingsFrame
    ade84:	bl	0x2ecd00 ; Objc message: -[x0 updateSceneSettingsFrame]
    aded8:	ldr	x1, [x8, #0xf00] ; Objc selector ref: setNeedsLayout
    adedc:	bl	0x2ecd00 ; Objc message: -[x0 setNeedsLayout]
    adef0:	bl	0x2ecd00 ; Objc message: -[x0 setNeedsLayout]
    adf04:	ldr	x1, [x8, #0xf08] ; Objc selector ref: layoutIfNeeded
    adf08:	bl	0x2ecd00 ; Objc message: -[x0 layoutIfNeeded]

## CBBridgedUIAppView.updateSceneSettingsFrame @ 0xad5bc
- Source boundary: `0xad5bc..0xadc74`; 430 instructions, 18 matching callsites.

    ad61c:	ldr	x1, [x8, #0x320] ; Objc selector ref: carPlayUsableBounds
    ad620:	bl	0x2ecd00 ; Objc message: +[CBWindow carPlayUsableBounds]
    ad630:	ldr	x1, [x8, #0x2f8] ; Objc selector ref: calculateNativeSizeForSlotRect:
    ad638:	bl	0x2ecd00 ; Objc message: -[x0 calculateNativeSizeForSlotRect:]
    ad66c:	ldr	x21, [x8, #0x308] ; Objc selector ref: setContentReferenceSize:withInterfaceOrientation:
    ad6ac:	ldr	x23, [x8, #0x310] ; Objc selector ref: setContentReferenceSize:withContentOrientation:andContainerOrientation:
    ad6bc:	bl	0x2ecd00 ; Objc message: -[x0 setContentReferenceSize:withContentOrientation:andContainerOrientation:]
    ad6dc:	bl	0x2ecd00 ; Objc message: -[x0 setContentReferenceSize:withContentOrientation:andContainerOrientation:]
    ad6ec:	bl	0x2ecd00 ; Objc message: -[x0 setContentReferenceSize:withContentOrientation:andContainerOrientation:]
    ad708:	bl	0x2ecd00 ; Objc message: -[x0 setContentReferenceSize:withContentOrientation:andContainerOrientation:]
    ad970:	ldr	x26, [x8, #0x340] ; Objc selector ref: updateSettingsWithBlock:
    ad980:	bl	0x2ecd00 ; Objc message: -[x0 updateSettingsWithBlock:]
    ad990:	bl	0x2ecd00 ; Objc message: -[x0 updateSettingsWithBlock:]
    ad9b4:	bl	0x2ecd00 ; Objc message: -[x0 updateSettingsWithBlock:]
    ad9f0:	bl	0x2ecd00 ; Objc message: -[x0 updateSettingsWithBlock:]
    ada28:	bl	0x2ecd00 ; Objc message: -[x0 updateSettingsWithBlock:]
    ada60:	bl	0x2ecd00 ; Objc message: -[x0 updateSettingsWithBlock:]
    adacc:	bl	0x2ecd00 ; Objc message: -[x0 updateSettingsWithBlock:]

## CBUIAppContainerView.layoutSubviews @ 0xb9730
- Source boundary: `0xb9730..0xb97cc`; 39 instructions, 2 matching callsites.

    b9758:	ldr	x19, [x8, #0xef0] ; Objc selector ref: layoutSubviews
    b9764:	bl	0x2ecd18 ; Objc message: -[[x0 super] layoutSubviews]

## CBBridgedSplitApp.layoutSplitViews @ 0x1044f8
- Source boundary: `0x1044f8..0x105890`; 1254 instructions, 19 matching callsites.

    104548:	ldr	x1, [x8, #0x320] ; Objc selector ref: carPlayUsableBounds
    10454c:	bl	0x2ecd00 ; Objc message: +[CBWindow carPlayUsableBounds]
    1046c0:	ldr	x8, [x8, #0x9e0] ; Objc selector ref: setUserInteractionEnabled:
    1046d4:	ldr	x8, [x8, #0xa10] ; Objc selector ref: setFrame:
    1046e0:	ldr	x10, [x8, #0xef8] ; Objc selector ref: setBounds:
    104774:	ldr	x8, [x8, #0x2c0] ; Objc selector ref: refreshSceneLayout
    104780:	ldr	x9, [x8, #0xf00] ; Objc selector ref: setNeedsLayout
    104d70:	ldr	x23, [x8, #0x980] ; Objc selector ref: setHidden:
    104da4:	bl	0x2ecd00 ; Objc message: -[x0 setHidden:]
    104db4:	bl	0x2ecd00 ; Objc message: -[x0 setHidden:]
    104dd8:	bl	0x2ecd00 ; Objc message: -[x0 setHidden:]
    104e0c:	bl	0x2ecd00 ; Objc message: -[x0 setHidden:]
    104ee4:	ldr	x8, [x8, #0x9e0] ; Objc selector ref: setUserInteractionEnabled:
    104ef0:	ldr	x10, [x8, #0xef8] ; Objc selector ref: setBounds:
    104f84:	ldr	x8, [x8, #0x2b8] ; Objc selector ref: updateLayout
    104f90:	ldr	x10, [x8, #0xf00] ; Objc selector ref: setNeedsLayout
    105534:	ldr	x23, [x8, #0xa10] ; Objc selector ref: setFrame:
    1057cc:	ldr	x1, [x8, #0xa10] ; Objc selector ref: setFrame:
    1057d0:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]

## CBBridgedSplitApp.updateScale:forSlot: @ 0x108dd8
- Source boundary: `0x108dd8..0x108f28`; 84 instructions, 2 matching callsites.

    108e3c:	ldr	x1, [x8, #0x2c0] ; Objc selector ref: refreshSceneLayout
    108e40:	bl	0x2ecd00 ; Objc message: -[x0 refreshSceneLayout]

## CBBridgeManager.receivedMetricsUpdatedNotification: @ 0x1d1400
- Source boundary: `0x1d1400..0x1d1498`; 38 instructions, 1 matching callsites.

    1d1484:	bl	0x2ecb2c ; symbol stub for: _dispatch_async

## CBBridgeManager.updateScale:forSlot: @ 0x280130
- Source boundary: `0x280130..0x280208`; 54 instructions, 2 matching callsites.

    2801c4:	ldr	x1, #0xfebdc ; Objc selector ref: updateScale:forSlot:
    2801d0:	bl	0x2ecd00 ; Objc message: -[x0 updateScale:forSlot:]

