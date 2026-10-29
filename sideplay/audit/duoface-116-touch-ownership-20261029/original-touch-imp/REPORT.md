# Original Native12: layout and preset ARM64 IMP evidence

- Verified original DEB SHA256: \`2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad\`
- Verified Dashboard SHA256: \`9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea\`
- Original method index blob: \`efa45df59bc3c16887cc979bf3aedc0c93c92111\`
- Exact extracted IMPs: **14**, ARM64 instructions: **1191**
- IMPORTANT: machine disassembly is NOT a runtime preset-frame test.
- A selector in an Objective-C call site does NOT prove a receiver.
- Preset 0..7 formulas in independent DFLayoutEngine remain UNVERIFIED until
  original function control flow and numerical CGRect outputs are derived.
- This artifact contains read-only evidence; no vendor code linked to app.

## CBTouchCloneView.sendTouchEventAtPoint:isDown: @ 0x82d4c
Original ABI: \`v36@0:8{CGPoint=dd}16B32\`
Function boundary: \`0x82d4c..0x82ff8\`
Instruction count: **171**; branches **19**;
Potential numerical operations (not yet semantic proof):

    82d4c:	sub	sp, sp, #0x80
    82d68:	add	x29, sp, #0x70
    82e00:	cmp	x8, #0x0
    82e24:	cmp	x8, #0x0
    82e30:	mov	w22, #0x3
    82e34:	mov	x9, #-0x4
    82e40:	add	x10, x10, #0xc48
    82e50:	add	x3, sp, #0x1c
    82e54:	add	x4, sp, #0x10
    82e58:	mov	w2, #0x4
    82e64:	cmp	x8, #0x3
    82e7c:	mov	w11, #0x10
    82e80:	movk	w11, #0x5800, lsl #16
    82e8c:	mov	w11, #0x14000000
    82e9c:	mov	w11, #0x200
    82ea0:	movk	w11, #0xd61f, lsl #16
    82ee4:	cmp	w20, #0x0
    82f0c:	mov	w2, #0x2
    82f10:	mov	w3, #0x0
    82f14:	mov	w4, #0x1
    82f1c:	mov	w6, #0x0
    82f4c:	mov	w2, #0x0
    82f50:	mov	w3, #0x1
    82f68:	mov	w7, #0x0
    82f7c:	mov	w2, #0x0
    82f88:	mov	x1, #0xbeef
    82f8c:	movk	x1, #0xdead, lsl #16
    82f90:	movk	x1, #0xc8ed, lsl #32
    82f94:	movk	x1, #0xdefa, lsl #48
    82ff0:	add	sp, sp, #0x80

Branch samples:
    82d8c:	bl	0x2ecd00 ; Objc message: +[UIScreen mainScreen]
    82d94:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    82dac:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    82dbc:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    82dcc:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    82ddc:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    82e5c:	bl	0x2ecea4 ; symbol stub for: _vm_read_overwrite
    82ed0:	bl	0x2ecbec ; symbol stub for: _mach_absolute_time
    82f2c:	bl	0x2ec928 ; symbol stub for: _IOHIDEventCreateDigitizerEvent
    82f6c:	bl	0x2ec934 ; symbol stub for: _IOHIDEventCreateDigitizerFingerEvent
    82f80:	bl	0x2ec91c ; symbol stub for: _IOHIDEventAppendEvent
    82f98:	bl	0x2ec940 ; symbol stub for: _IOHIDEventSetSenderID
    82fa4:	cbnz	x0, 0x82fb8
    82fac:	bl	0x2ec94c ; symbol stub for: _IOHIDEventSystemClientCreate
    82fb4:	cbz	x0, 0x82fc0
    82fbc:	bl	0x2ec958 ; symbol stub for: _IOHIDEventSystemClientDispatchEvent
    82fc4:	bl	0x2ec7fc ; symbol stub for: _CFRelease
    82fcc:	bl	0x2ec7fc ; symbol stub for: _CFRelease
    82fd4:	bl	0x2ecd30 ; symbol stub for: _objc_release

## CBTouchCloneView.touchesBegan:withEvent: @ 0x82ff8
Original ABI: \`v32@0:8@16@24\`
Function boundary: \`0x82ff8..0x83058\`
Instruction count: **24**; branches **5**;
Potential numerical operations (not yet semantic proof):

    83000:	add	x29, sp, #0x10
    83040:	mov	w2, #0x1

Branch samples:
    83014:	bl	0x2ecd00 ; Objc message: -[x0 anyObject]
    8301c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    83030:	bl	0x2ecd00 ; Objc message: -[x0 locationInView:]
    83044:	bl	0x2ecd00 ; Objc message: -[x0 sendTouchEventAtPoint:isDown:]
    83054:	b	0x2ecd30 ; symbol stub for: _objc_release

## CBTouchCloneView.touchesMoved:withEvent: @ 0x83058
Original ABI: \`v32@0:8@16@24\`
Function boundary: \`0x83058..0x830b8\`
Instruction count: **24**; branches **5**;
Potential numerical operations (not yet semantic proof):

    83060:	add	x29, sp, #0x10
    830a0:	mov	w2, #0x1

Branch samples:
    83074:	bl	0x2ecd00 ; Objc message: -[x0 anyObject]
    8307c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    83090:	bl	0x2ecd00 ; Objc message: -[x0 locationInView:]
    830a4:	bl	0x2ecd00 ; Objc message: -[x0 sendTouchEventAtPoint:isDown:]
    830b4:	b	0x2ecd30 ; symbol stub for: _objc_release

## CBTouchCloneView.touchesEnded:withEvent: @ 0x830b8
Original ABI: \`v32@0:8@16@24\`
Function boundary: \`0x830b8..0x83118\`
Instruction count: **24**; branches **5**;
Potential numerical operations (not yet semantic proof):

    830c0:	add	x29, sp, #0x10
    83100:	mov	w2, #0x0

Branch samples:
    830d4:	bl	0x2ecd00 ; Objc message: -[x0 anyObject]
    830dc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    830f0:	bl	0x2ecd00 ; Objc message: -[x0 locationInView:]
    83104:	bl	0x2ecd00 ; Objc message: -[x0 sendTouchEventAtPoint:isDown:]
    83114:	b	0x2ecd30 ; symbol stub for: _objc_release

## CBTouchCloneView.touchesCancelled:withEvent: @ 0x83118
Original ABI: \`v32@0:8@16@24\`
Function boundary: \`0x83118..0x83178\`
Instruction count: **24**; branches **5**;
Potential numerical operations (not yet semantic proof):

    83120:	add	x29, sp, #0x10
    83160:	mov	w2, #0x0

Branch samples:
    83134:	bl	0x2ecd00 ; Objc message: -[x0 anyObject]
    8313c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    83150:	bl	0x2ecd00 ; Objc message: -[x0 locationInView:]
    83164:	bl	0x2ecd00 ; Objc message: -[x0 sendTouchEventAtPoint:isDown:]
    83174:	b	0x2ecd30 ; symbol stub for: _objc_release

## CBBridgedUIAppView.hitTest:withEvent: @ 0xac940
Original ABI: \`@40@0:8{CGPoint=dd}16@32\`
Function boundary: \`0xac940..0xaca6c\`
Instruction count: **75**; branches **17**;
Potential numerical operations (not yet semantic proof):

    ac940:	sub	sp, sp, #0x70
    ac95c:	add	x29, sp, #0x60
    aca64:	add	sp, sp, #0x70

Branch samples:
    ac970:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    ac988:	bl	0x2ecd00 ; Objc message: +[CBBridgeManager sharedInstance]
    ac990:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ac9a4:	bl	0x2ecd00 ; Objc message: -[x0 currentApp]
    ac9ac:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ac9c8:	bl	0x2ecd00 ; Objc message: -[x0 noteUserActivity]
    ac9d4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    ac9d8:	cbz	w25, 0xaca04
    ac9e4:	bl	0x2ecd00 ; Objc message: -[x0 noteUserActivity]
    ac9ec:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ac9f8:	bl	0x2ecd00 ; Objc message: -[x0 noteUserActivity]
    aca00:	bl	0x2ecd30 ; symbol stub for: _objc_release
    aca28:	bl	0x2ecd18 ; Objc message: -[[x0 super] hitTest:withEvent:]
    aca30:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aca3c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    aca44:	bl	0x2ecd30 ; symbol stub for: _objc_release
    aca68:	b	0x2ecc7c ; symbol stub for: _objc_autoreleaseReturnValue

## CBBridgedUIAppView.touchesBegan:withEvent: @ 0xaca6c
Original ABI: \`v32@0:8@16@24\`
Function boundary: \`0xaca6c..0xacc28\`
Instruction count: **111**; branches **33**;
Potential numerical operations (not yet semantic proof):

    aca6c:	sub	sp, sp, #0x60
    aca84:	add	x29, sp, #0x50
    acc20:	add	sp, sp, #0x60

Branch samples:
    acaa4:	bl	0x2ecd18 ; Objc message: -[[x0 super] touchesBegan:withEvent:]
    acab8:	bl	0x2ecd00 ; Objc message: +[CBBridgeManager sharedInstance]
    acac0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    acad4:	bl	0x2ecd00 ; Objc message: -[x0 currentApp]
    acadc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    acafc:	bl	0x2ecd00 ; Objc message: -[x0 noteUserActivity]
    acb08:	bl	0x2ecd30 ; symbol stub for: _objc_release
    acb0c:	cbz	w25, 0xacb38
    acb18:	bl	0x2ecd00 ; Objc message: -[x0 noteUserActivity]
    acb20:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    acb2c:	bl	0x2ecd00 ; Objc message: -[x0 noteUserActivity]
    acb34:	bl	0x2ecd30 ; symbol stub for: _objc_release
    acb48:	bl	0x2ecd00 ; Objc message: -[x0 window]
    acb50:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    acb58:	cbz	x0, 0xacbfc
    acb64:	bl	0x2ecd00 ; Objc message: -[x0 window]
    acb6c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    acb7c:	bl	0x2ecd00 ; Objc message: -[x0 isKeyWindow]
    acb80:	cbz	w0, 0xacb90
    acb88:	bl	0x2ecd30 ; symbol stub for: _objc_release
    acb8c:	b	0xacbfc
    acb98:	bl	0x2ecd00 ; Objc message: -[x0 isKeyWindow]
    acba0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    acbb8:	bl	0x2ecd00 ; Objc message: -[x0 makeKeyWindow]
    acbc4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    acbcc:	bl	0x2ecd30 ; symbol stub for: _objc_release
    acbd4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    acbd8:	cbz	w21, 0xacc04
    acbe4:	bl	0x2ecd00 ; Objc message: -[x0 makeKeyWindow]
    acbec:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    acbf8:	bl	0x2ecd00 ; Objc message: -[x0 makeKeyWindow]
    acc00:	bl	0x2ecd30 ; symbol stub for: _objc_release
    acc08:	bl	0x2ecd30 ; symbol stub for: _objc_release

## CBBridgedUIAppView.setAppScale: @ 0xac83c
Original ABI: \`v24@0:8d16\`
Function boundary: \`0xac83c..0xac858\`
Instruction count: **7**; branches **1**;
Potential numerical operations (not yet semantic proof):

    ac844:	mov	x9, #0x3fe0000000000000

Branch samples:
    ac854:	b	0x2ecd00 ; Objc message: -[x0 updateLayout]

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

## CBUIAppContainerView.hitTest:withEvent: @ 0xb97cc
Original ABI: \`@40@0:8{CGPoint=dd}16@32\`
Function boundary: \`0xb97cc..0xb9888\`
Instruction count: **47**; branches **9**;
Potential numerical operations (not yet semantic proof):

    b97cc:	sub	sp, sp, #0x50
    b97e0:	add	x29, sp, #0x40
    b9880:	add	sp, sp, #0x50

Branch samples:
    b97fc:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    b980c:	bl	0x2ecd00 ; Objc message: -[x0 uiApp]
    b9814:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b9824:	bl	0x2ecd00 ; Objc message: -[x0 noteUserActivity]
    b982c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b9854:	bl	0x2ecd18 ; Objc message: -[[x0 super] hitTest:withEvent:]
    b985c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b9868:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b9884:	b	0x2ecc7c ; symbol stub for: _objc_autoreleaseReturnValue

## CBUIAppContainerView.touchesBegan:withEvent: @ 0xb9888
Original ABI: \`v32@0:8@16@24\`
Function boundary: \`0xb9888..0xb98f8\`
Instruction count: **28**; branches **5**;
Potential numerical operations (not yet semantic proof):

    b9888:	sub	sp, sp, #0x30
    b9894:	add	x29, sp, #0x20
    b98f0:	add	sp, sp, #0x30

Branch samples:
    b98b4:	bl	0x2ecd18 ; Objc message: -[[x0 super] touchesBegan:withEvent:]
    b98c4:	bl	0x2ecd00 ; Objc message: -[x0 uiApp]
    b98cc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b98dc:	bl	0x2ecd00 ; Objc message: -[x0 noteUserActivity]
    b98e4:	bl	0x2ecd30 ; symbol stub for: _objc_release

## CBUIAppContainerView.layoutSubviews @ 0xb9730
Original ABI: \`v16@0:8\`
Function boundary: \`0xb9730..0xb97cc\`
Instruction count: **39**; branches **9**;
Potential numerical operations (not yet semantic proof):

    b9730:	sub	sp, sp, #0x40
    b9740:	add	x29, sp, #0x30
    b97c4:	add	sp, sp, #0x40

Branch samples:
    b9764:	bl	0x2ecd18 ; Objc message: -[[x0 super] layoutSubviews]
    b9778:	bl	0x2ecd00 ; Objc message: -[x0 uiApp]
    b9780:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b9788:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b978c:	cbz	x22, 0xb97b8
    b9798:	bl	0x2ecd00 ; Objc message: -[x0 uiApp]
    b97a0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b97ac:	bl	0x2ecd00 ; Objc message: -[x0 uiApp]
    b97b4:	bl	0x2ecd30 ; symbol stub for: _objc_release

## CBWindow.resizeWindows @ 0xb1aac
Original ABI: \`v16@0:8\`
Function boundary: \`0xb1aac..0xb1d98\`
Instruction count: **187**; branches **48**;
Potential numerical operations (not yet semantic proof):

    b1aac:	sub	sp, sp, #0xa0
    b1ad4:	add	x29, sp, #0x90
    b1c40:	mov	x2, #0x0
    b1c54:	mov	w2, #0x1
    b1c80:	mov	w2, #0x0
    b1d58:	add	x0, x0, #0xe68 ; Objc cfstring ref: @"[DuoFaceWindow] resizeWindows completed: screenBounds=%@, usableBounds=%@"
    b1d90:	add	sp, sp, #0xa0

Branch samples:
    b1aec:	bl	0x2ecd00 ; Objc message: +[CBWindow carPlayScreenBounds]
    b1b0c:	bl	0x2ecd00 ; Objc message: -[x0 carPlayUsableBounds]
    b1b34:	cbz	x0, 0xb1b80
    b1b4c:	bl	0x2ecd00 ; Objc message: -[x0 carPlayUsableBounds]
    b1b58:	bl	0x2ecd00 ; Objc message: -[x0 carPlayUsableBounds]
    b1b60:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b1b74:	bl	0x2ecd00 ; Objc message: -[x0 carPlayUsableBounds]
    b1b7c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b1b84:	cbz	x0, 0xb1be4
    b1b94:	bl	0x2ecd00 ; Objc message: -[x0 view]
    b1b9c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b1ba4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b1ba8:	cbz	x21, 0xb1be4
    b1bb4:	bl	0x2ecd00 ; Objc message: -[x0 view]
    b1bbc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b1bd8:	bl	0x2ecd00 ; Objc message: -[x0 view]
    b1be0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b1be8:	cbz	x0, 0xb1c90
    b1c00:	bl	0x2ecd00 ; Objc message: -[x0 view]
    b1c0c:	bl	0x2ecd00 ; Objc message: -[x0 view]
    b1c14:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b1c28:	bl	0x2ecd00 ; Objc message: -[x0 view]
    b1c30:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b1c44:	bl	0x2ecd00 ; Objc message: -[x0 setEffect:]
    b1c58:	bl	0x2ecd00 ; Objc message: -[x0 setClipsToBounds:]
    b1c68:	bl	0x2ecd00 ; Objc message: -[x0 layer]
    b1c70:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b1c84:	bl	0x2ecd00 ; Objc message: -[x0 setMasksToBounds:]
    b1c8c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b1c94:	cbz	x0, 0xb1d10
    b1ca4:	bl	0x2ecd00 ; Objc message: -[x0 superview]
    b1cac:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b1cb4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b1cbc:	cbz	x21, 0xb1cf8
    b1cc4:	bl	0x2ecd00 ; Objc message: -[x0 superview]
    b1ccc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b1cdc:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    b1ce8:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    b1cf0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b1cf4:	b	0xb1d10

