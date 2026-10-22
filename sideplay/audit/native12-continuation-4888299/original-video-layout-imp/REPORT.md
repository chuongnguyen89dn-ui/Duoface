# Original Native12: layout and preset ARM64 IMP evidence

- Verified original DEB SHA256: \`2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad\`
- Verified Dashboard SHA256: \`9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea\`
- Original method index blob: \`efa45df59bc3c16887cc979bf3aedc0c93c92111\`
- Exact extracted IMPs: **9**, ARM64 instructions: **2653**
- IMPORTANT: machine disassembly is NOT a runtime preset-frame test.
- A selector in an Objective-C call site does NOT prove a receiver.
- Preset 0..7 formulas in independent DFLayoutEngine remain UNVERIFIED until
  original function control flow and numerical CGRect outputs are derived.
- This artifact contains read-only evidence; no vendor code linked to app.

## CBBridgedUIAppView.updateLayout @ 0xacc6c
Original ABI: \`v16@0:8\`
Function boundary: \`0xacc6c..0xad24c\`
Instruction count: **376**; branches **85**;
Potential numerical operations (not yet semantic proof):

    acc6c:	sub	sp, sp, #0x190
    acc94:	add	x29, sp, #0x180
    accd0:	fcmp	d2, #0.0
    accdc:	fcmp	d3, #0.0
    acd04:	fcmp	d0, #0.0
    acd10:	fcmp	d1, #0.0
    acd48:	sub	x2, x29, #0xb0
    acdac:	add	x2, sp, #0xa0
    acde0:	mov	w2, #0x12
    ace0c:	add	x1, x1, #0xd57 ; literal pool for: "_deviceAppViewController"
    ace20:	mov	w8, #0x1
    acf50:	add	sp, sp, #0x190
    acf80:	add	x2, x2, #0xc28 ; Objc cfstring ref: @"_deviceAppViewController"
    acfc8:	mov	w2, #0x1
    acffc:	mov	w2, #0x1
    ad000:	mov	w3, #0x1
    ad024:	add	x0, x0, #0xdb6 ; literal pool for: "setHomeGrabberDisplayMode:"
    ad034:	mov	w2, #0x1
    ad054:	fmov	d1, #0.50000000
    ad05c:	add	x8, sp, #0x70
    ad080:	add	x2, sp, #0x40
    ad0d4:	fcmp	d12, #0.0
    ad0e8:	fmov	d0, #10.00000000
    ad1b0:	mov	w2, #0x1
    ad1ec:	add	sp, sp, #0x190
    ad1f8:	cmp	w1, #0x1
    ad21c:	add	x0, x0, #0xc48 ; Objc cfstring ref: @"[CBBridgedUIAppView] Warning: _deviceAppViewController KVC failed: %@"
    ad230:	mov	x22, #0x0

Branch samples:
    acca4:	cbz	x8, 0xad1c8
    accb8:	cbz	x8, 0xad1c8
    acccc:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    accd4:	b.ls	0xace2c
    acce0:	b.ls	0xace2c
    acd00:	bl	0x2ecd00 ; Objc message: -[x0 calculateNativeSizeForSlotRect:]
    acd08:	b.ls	0xace9c
    acd14:	b.ls	0xace9c
    acd50:	bl	0x2ecd00 ; Objc message: -[x0 setTransform:]
    acd74:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    acd84:	bl	0x2ecd00 ; Objc message: -[x0 view]
    acd8c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    acd94:	cbz	x0, 0xacde8
    acdb8:	bl	0x2ecd00 ; Objc message: -[x0 view]
    acdc4:	bl	0x2ecd00 ; Objc message: -[x0 view]
    acdd0:	bl	0x2ecd00 ; Objc message: -[x0 view]
    acde4:	bl	0x2ecd00 ; Objc message: -[x0 setAutoresizingMask:]
    acdf0:	tbnz	w8, #0x0, 0xacf58
    acdf8:	cbz	x0, 0xacf58
    ace04:	bl	0x2ecd00 ; Objc message: -[x0 class]
    ace10:	bl	0x2ecafc ; symbol stub for: _class_getInstanceVariable
    ace28:	b	0xacf60
    ace5c:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    ace70:	bl	0x2ecd00 ; Objc message: -[x0 view]
    ace78:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ace80:	bl	0x2ecd30 ; symbol stub for: _objc_release
    ace84:	cbz	x22, 0xad1c8
    ace90:	bl	0x2ecd00 ; Objc message: -[x0 view]
    ace98:	b	0xacf08
    acecc:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    acee0:	bl	0x2ecd00 ; Objc message: -[x0 view]
    acee8:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    acef0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    acef4:	cbz	x22, 0xad1c8
    acf00:	bl	0x2ecd00 ; Objc message: -[x0 view]
    acf08:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    acf24:	bl	0x2ecd00 ; Objc message: -[x0 view]
    acf54:	b	0x2ecd30 ; symbol stub for: _objc_release
    acf68:	cbz	x1, 0xacf74
    acf6c:	bl	0x2ecdd8 ; symbol stub for: _object_getIvar

## CBBridgedUIAppView.updateSceneFrame @ 0xade4c
Original ABI: \`v16@0:8\`
Function boundary: \`0xade4c..0xade58\`
Instruction count: **3**; branches **1**;
Potential numerical operations (not yet semantic proof):


Branch samples:
    ade54:	b	0x2ecd00 ; Objc message: -[x0 refreshSceneLayout]

## CBBridgedUIAppView.calculateNativeSizeForSlotRect: @ 0xacc28
Original ABI: \`{CGSize=dd}48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16\`
Function boundary: \`0xacc28..0xacc6c\`
Instruction count: **17**; branches **2**;
Potential numerical operations (not yet semantic proof):

    acc28:	fcmp	d2, #0.0
    acc30:	fcmp	d3, #0.0

Branch samples:
    acc2c:	b.ls	0xacc5c
    acc34:	b.ls	0xacc5c

## CBBridgedUIAppView.refreshSceneLayout @ 0xade58
Original ABI: \`v16@0:8\`
Function boundary: \`0xade58..0xadf30\`
Instruction count: **54**; branches **15**;
Potential numerical operations (not yet semantic proof):

    ade64:	add	x29, sp, #0x20

Branch samples:
    ade74:	bl	0x2ecd00 ; Objc message: -[x0 updateLayout]
    ade84:	bl	0x2ecd00 ; Objc message: -[x0 updateSceneSettingsFrame]
    ade94:	cbz	x0, 0xadf20
    adea4:	bl	0x2ecd00 ; Objc message: -[x0 view]
    adeac:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    adeb4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    adeb8:	cbz	x21, 0xadf20
    adec4:	bl	0x2ecd00 ; Objc message: -[x0 view]
    adecc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    adedc:	bl	0x2ecd00 ; Objc message: -[x0 setNeedsLayout]
    adee4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    adef0:	bl	0x2ecd00 ; Objc message: -[x0 setNeedsLayout]
    adef8:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    adf08:	bl	0x2ecd00 ; Objc message: -[x0 layoutIfNeeded]
    adf1c:	b	0x2ecd30 ; symbol stub for: _objc_release

## CBBridgedUIAppView.updateSceneSettingsFrame @ 0xad5bc
Original ABI: \`v16@0:8\`
Function boundary: \`0xad5bc..0xadc74\`
Instruction count: **430**; branches **131**;
Potential numerical operations (not yet semantic proof):

    ad5bc:	sub	sp, sp, #0xb0
    ad5dc:	add	x29, sp, #0xa0
    ad600:	fcmp	d2, #0.0
    ad608:	fcmp	d3, #0.0
    ad654:	add	x2, x2, #0xc28 ; Objc cfstring ref: @"_deviceAppViewController"
    ad6a0:	mov	w2, #0x1
    ad6d4:	mov	w2, #0x1
    ad6d8:	mov	w3, #0x1
    ad704:	mov	w2, #0x1
    ad74c:	mov	x21, #0x0
    ad750:	cmp	x19, #0x0
    ad7a8:	mov	w2, #0x1
    ad7c0:	add	x1, x1, #0xe8b ; literal pool for: "CBDuoFaceHosted"
    ad7cc:	mov	w3, #0x1
    ad7e4:	mov	w2, #0x1
    ad7fc:	add	x1, x1, #0xe9b ; literal pool for: "CBCarBridgeHosted"
    ad808:	mov	w3, #0x1
    ad85c:	add	x1, x1, #0xead ; literal pool for: "CBDuoFaceBundleID"
    ad868:	mov	w3, #0x3
    ad894:	add	x1, x1, #0xebf ; literal pool for: "CBCarBridgeBundleID"
    ad8a0:	mov	w3, #0x3
    ad8c4:	add	x1, x1, #0xed3 ; literal pool for: "_scene"
    ad9b0:	mov	w2, #0x1
    ad9c8:	add	x1, x1, #0xe8b ; literal pool for: "CBDuoFaceHosted"
    ad9d4:	mov	w3, #0x1
    ad9ec:	mov	w2, #0x1
    ada04:	add	x1, x1, #0xe9b ; literal pool for: "CBCarBridgeHosted"
    ada10:	mov	w3, #0x1
    ada3c:	add	x1, x1, #0xead ; literal pool for: "CBDuoFaceBundleID"
    ada48:	mov	w3, #0x3
    ada74:	add	x1, x1, #0xebf ; literal pool for: "CBCarBridgeBundleID"
    ada80:	mov	w3, #0x3
    adab4:	add	x9, x9, #0xe58
    adac0:	add	x2, sp, #0x10
    adad8:	cmp	w1, #0x1
    adafc:	add	x0, x0, #0xcc8 ; Objc cfstring ref: @"[DuoFace] updateSettingsWithBlock error: %@"
    adb1c:	cmp	w1, #0x1
    adb40:	add	x0, x0, #0xc68 ; Objc cfstring ref: @"[CBBridgedUIAppView] Warning: _deviceAppViewController KVC failed in updateSceneSettingsFrame, falling back to ivar: %@"
    adb5c:	add	x1, x1, #0xd57 ; literal pool for: "_deviceAppViewController"
    adb84:	mov	x19, #0x0

Branch samples:
    ad5ec:	cbz	x8, 0xadbf8
    ad5fc:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    ad604:	b.ls	0xad610
    ad60c:	b.hi	0xad62c
    ad620:	bl	0x2ecd00 ; Objc message: +[CBWindow carPlayUsableBounds]
    ad638:	bl	0x2ecd00 ; Objc message: -[x0 calculateNativeSizeForSlotRect:]
    ad658:	bl	0x2ecd00 ; Objc message: -[x0 valueForKey:]
    ad660:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ad678:	cbz	x19, 0xad6e0
    ad688:	bl	0x2ecd00 ; Objc message: -[x0 respondsToSelector:]
    ad68c:	cbz	w0, 0xad6a8
    ad6a4:	bl	0x2ecd00 ; Objc message: -[x0 respondsToSelector:]
    ad6bc:	bl	0x2ecd00 ; Objc message: -[x0 setContentReferenceSize:withContentOrientation:andContainerOrientation:]
    ad6c0:	cbz	w0, 0xad6e0
    ad6dc:	bl	0x2ecd00 ; Objc message: -[x0 setContentReferenceSize:withContentOrientation:andContainerOrientation:]
    ad6ec:	bl	0x2ecd00 ; Objc message: -[x0 setContentReferenceSize:withContentOrientation:andContainerOrientation:]
    ad6f0:	cbz	w0, 0xad70c
    ad708:	bl	0x2ecd00 ; Objc message: -[x0 setContentReferenceSize:withContentOrientation:andContainerOrientation:]
    ad720:	bl	0x2ecd00 ; Objc message: -[x0 sceneHandle]
    ad724:	cbz	w0, 0xad74c
    ad738:	bl	0x2ecd00 ; Objc message: -[x0 performSelector:]
    ad740:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ad748:	b	0xad750
    ad758:	b.ne	0xad790
    ad768:	bl	0x2ecd00 ; Objc message: -[x0 performSelector:]
    ad76c:	cbz	w0, 0xadbf0
    ad780:	bl	0x2ecd00 ; Objc message: -[x0 performSelector:]
    ad788:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ad790:	cbz	x21, 0xadbf0
    ad7ac:	bl	0x2ecd00 ; Objc message: +[NSNumber numberWithBool:]
    ad7b4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ad7d0:	bl	0x2ecd78 ; symbol stub for: _objc_setAssociatedObject
    ad7d8:	bl	0x2ecd30 ; symbol stub for: _objc_release
    ad7e8:	bl	0x2ecd00 ; Objc message: -[x0 numberWithBool:]
    ad7f0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ad80c:	bl	0x2ecd78 ; symbol stub for: _objc_setAssociatedObject
    ad814:	bl	0x2ecd30 ; symbol stub for: _objc_release
    ad828:	bl	0x2ecd00 ; Objc message: -[x0 bundleIdentifier]
    ad830:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ad838:	bl	0x2ecd30 ; symbol stub for: _objc_release

## CBBridgedUIAppView.setAppScale: @ 0xac83c
Original ABI: \`v24@0:8d16\`
Function boundary: \`0xac83c..0xac858\`
Instruction count: **7**; branches **1**;
Potential numerical operations (not yet semantic proof):

    ac844:	mov	x9, #0x3fe0000000000000

Branch samples:
    ac854:	b	0x2ecd00 ; Objc message: -[x0 updateLayout]

## CBBridgeManager.supportsInterfaceOrientation:forBundleID: @ 0x24d118
Original ABI: \`B32@0:8q16@24\`
Function boundary: \`0x24d118..0x24d120\`
Instruction count: **2**; branches **0**;
Potential numerical operations (not yet semantic proof):

    24d118:	mov	w0, #0x1

Branch samples:

## CBBridgeManager.renderSizeForBundleID: @ 0x24c920
Original ABI: \`{CGSize=dd}24@0:8@16\`
Function boundary: \`0x24c920..0x24d118\`
Instruction count: **510**; branches **136**;
Potential numerical operations (not yet semantic proof):

    24c920:	sub	sp, sp, #0xc0
    24c944:	add	x29, sp, #0xb0
    24c9b0:	cmn	x8, #0x1
    24cb58:	fcmp	d2, #0.0
    24cba0:	fcmp	d2, #0.0
    24cbe0:	fcmp	d3, #0.0
    24cc74:	fmov	d4, #2.00000000
    24ccd0:	mov	x25, #0x0
    24cdb8:	add	x25, x25, #0x1
    24ce28:	fcmp	d2, #0.0
    24ce60:	fcmp	d3, #0.0
    24ced8:	add	sp, sp, #0xc0
    24cf30:	fmov	d0, #10.00000000
    24cfb8:	fcmp	d2, #0.0
    24cfdc:	fcmp	d3, #0.0
    24cff0:	fcmp	d8, #0.0
    24d010:	fcmp	d9, #0.0
    24d0a4:	fcmp	d3, #0.0
    24d104:	add	x0, x0, #0x9e8

Branch samples:
    24c950:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    24c958:	cbz	x0, 0x24cb6c
    24c968:	bl	0x2ecd00 ; Objc message: -[x0 length]
    24c96c:	cbz	x0, 0x24cb6c
    24c97c:	bl	0x2ecd00 ; Objc message: -[x0 activated]
    24c984:	cbz	w0, 0x24ce18
    24c998:	bl	0x2ecd00 ; Objc message: -[x0 bundleIdentifier]
    24c9a0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    24c9b4:	b.ne	0x24d100
    24c9d0:	bl	0x2ecd00 ; Objc message: -[x0 isEqualToString:]
    24c9dc:	bl	0x2ecd30 ; symbol stub for: _objc_release
    24c9e0:	cbz	w24, 0x24ce18
    24c9f4:	bl	0x2ecd00 ; Objc message: -[x0 currentApp]
    24c9fc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    24ca14:	bl	0x2ecd00 ; Objc message: +[CBBridgedSplitApp class]
    24ca28:	bl	0x2ecd00 ; Objc message: -[x0 isKindOfClass:]
    24ca34:	bl	0x2ecd30 ; symbol stub for: _objc_release
    24ca38:	cbz	w25, 0x24ce18
    24ca44:	bl	0x2ecd00 ; Objc message: -[x0 isKindOfClass:]
    24ca4c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    24ca60:	bl	0x2ecd00 ; Objc message: -[x0 focusedSlotIndex]
    24ca68:	tbnz	x0, #0x3f, 0x24cb90
    24ca74:	bl	0x2ecd00 ; Objc message: -[x0 focusedSlotIndex]
    24ca8c:	bl	0x2ecd00 ; Objc message: -[x0 appViews]
    24ca94:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    24caa4:	bl	0x2ecd00 ; Objc message: -[x0 count]
    24cab4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    24cac0:	b.hs	0x24cb90
    24cacc:	bl	0x2ecd00 ; Objc message: -[x0 count]
    24cad4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    24cae4:	bl	0x2ecd00 ; Objc message: -[x0 count]
    24caf8:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    24cb00:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    24cb0c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    24cb18:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    24cb20:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    24cb34:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    24cb40:	bl	0x2ecd30 ; symbol stub for: _objc_release
    24cb44:	tbz	w22, #0x0, 0x24cb88
    24cb54:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]

## CBBridgedSplitApp.layoutSplitViews @ 0x1044f8
Original ABI: \`v16@0:8\`
Function boundary: \`0x1044f8..0x105890\`
Instruction count: **1254**; branches **311**;
Potential numerical operations (not yet semantic proof):

    104520:	add	x29, sp, #0x90
    104524:	sub	sp, sp, #0x1f0
    104588:	fcmp	d2, #0.0
    1045e4:	fcmp	d3, #0.0
    10469c:	mov	x24, #0x0
    1047ac:	fmov	d11, #1.00000000
    104838:	mov	x22, #0x0
    104870:	mov	x20, #0x0
    104888:	mov	w2, #0x0
    1048a8:	mov	w2, #0x1
    104904:	fmov	d0, #10.00000000
    104a2c:	mov	w2, #0x1
    104a74:	mov	w2, #0x0
    104af4:	mov	w2, #0x0
    104b10:	mov	w2, #0x1
    104b30:	mov	w2, #0x0
    104b44:	mov	w2, #0x1
    104b58:	mov	w2, #0x1
    104b84:	mov	w2, #0x1
    104c24:	mov	w2, #0x1
    104c34:	mov	w2, #0x0
    104c5c:	fmov	d1, #0.50000000
    104c78:	fmov	d1, #3.00000000
    104c9c:	mov	w2, #0x0
    104cac:	mov	w2, #0x1
    104cf4:	add	x24, x24, #0x1
    104d40:	add	x2, sp, #0x120
    104d44:	add	x3, sp, #0x160
    104d4c:	mov	w4, #0x10
    104d68:	mov	x27, #0x0
    104da0:	mov	w2, #0x1
    104db8:	add	x27, x27, #0x1
    104dc4:	add	x2, sp, #0x120
    104dc8:	add	x3, sp, #0x160
    104dd4:	mov	w4, #0x10
    104e10:	cmp	x0, #0x1
    104e74:	fmov	d4, #2.00000000
    104ec4:	mov	x20, #0x0
    1050c4:	mov	w2, #0x0
    1050d4:	fmov	d0, #1.00000000

Branch samples:
    10454c:	bl	0x2ecd00 ; Objc message: +[CBWindow carPlayUsableBounds]
    104568:	bl	0x2ecd00 ; Objc message: -[x0 view]
    104570:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    104584:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    10458c:	b.le	0x1045bc
    104598:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    1045a0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    1045ac:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    1045b8:	bl	0x2ecd30 ; symbol stub for: _objc_release
    1045c0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    1045cc:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    1045d4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    1045e0:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    1045e8:	b.le	0x104618
    1045f4:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    1045fc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    104608:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    104614:	bl	0x2ecd30 ; symbol stub for: _objc_release
    10461c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    104630:	cbz	x0, 0x10464c
    10463c:	bl	0x2ecd00 ; Objc message: -[x0 isDismissing]
    104648:	b	0x104650
    10466c:	tbnz	x20, #0x3f, 0x104dec
    104680:	bl	0x2ecd00 ; Objc message: -[x0 isDismissing]
    104688:	b.hs	0x104dec
    104694:	bl	0x2ecd00 ; Objc message: -[x0 isDismissing]
    104698:	cbz	x0, 0x104d18
    1047f4:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    1047fc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    10480c:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104814:	b.hs	0x104838
    104824:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    10482c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    104834:	b	0x10483c
    104844:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    10484c:	b.hs	0x104870
    10485c:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104864:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    10486c:	b	0x104874
    104880:	b.ne	0x104b0c

