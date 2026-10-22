# Original Native12: layout and preset ARM64 IMP evidence

- Verified original DEB SHA256: \`2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad\`
- Verified Dashboard SHA256: \`9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea\`
- Original method index blob: \`efa45df59bc3c16887cc979bf3aedc0c93c92111\`
- Exact extracted IMPs: **7**, ARM64 instructions: **1027**
- IMPORTANT: machine disassembly is NOT a runtime preset-frame test.
- A selector in an Objective-C call site does NOT prove a receiver.
- Preset 0..7 formulas in independent DFLayoutEngine remain UNVERIFIED until
  original function control flow and numerical CGRect outputs are derived.
- This artifact contains read-only evidence; no vendor code linked to app.

## CBMultitaskingOverlayView.showLayoutChooserInParentView: @ 0xaacf0
Original ABI: \`v24@0:8@16\`
Function boundary: \`0xaacf0..0xab164\`
Instruction count: **285**; branches **62**;
Potential numerical operations (not yet semantic proof):

    aacf0:	sub	sp, sp, #0x140
    aad0c:	add	x29, sp, #0x130
    aad7c:	mov	w9, #0x1
    aadd0:	cmp	x0, #0x8
    aadf8:	cmp	x0, #0x0
    aae54:	add	x24, x24, #0x288 ; Objc cfstring ref: @""
    aae80:	cmp	x0, #0x0
    aae8c:	mov	w9, #0x1
    aaeb8:	mov	w25, #0x0
    aaee0:	cmp	x0, #0x0
    aaee8:	mov	w25, #0x1
    aaf0c:	cmp	x0, #0x0
    aaf34:	cmp	x0, #0x0
    aaf50:	sub	x2, x29, #0x80
    aaf54:	mov	w3, #0x4
    ab060:	mov	w2, #0x0
    ab070:	add	x8, sp, #0x80
    ab0a0:	add	x2, sp, #0x50
    ab0e0:	add	x9, x9, #0x658
    ab108:	fmov	d0, #0.25000000
    ab110:	add	x3, sp, #0x28
    ab114:	mov	w2, #0x20000
    ab118:	mov	x4, #0x0
    ab158:	add	sp, sp, #0x140

Branch samples:
    aad20:	cbz	x2, 0xab128
    aad40:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    aad50:	bl	0x2ecd00 ; Objc message: +[CBLocalization sharedInstance]
    aad58:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aad68:	bl	0x2ecd00 ; Objc message: -[x0 reloadLanguage]
    aad70:	bl	0x2ecd30 ; symbol stub for: _objc_release
    aad90:	bl	0x2ecd00 ; Objc message: +[CBDashboardSettings reloadLanguage]
    aad98:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aada8:	bl	0x2ecd00 ; Objc message: -[x0 reload]
    aadbc:	bl	0x2ecd00 ; Objc message: -[x0 splitPreset]
    aadc0:	tbnz	x0, #0x3f, 0xaade8
    aadcc:	bl	0x2ecd00 ; Objc message: -[x0 splitPreset]
    aadd4:	b.gt	0xaade8
    aade0:	bl	0x2ecd00 ; Objc message: -[x0 splitPreset]
    aade4:	b	0xaae00
    aadf4:	bl	0x2ecd00 ; Objc message: -[x0 splitMode]
    aae18:	bl	0x2ecd00 ; Objc message: -[x0 splitRatio]
    aae40:	bl	0x2ecd00 ; Objc message: +[NSMutableArray splitApp1]
    aae48:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aae58:	cbz	x0, 0xaae68
    aae64:	b	0xaae94
    aae74:	bl	0x2ecd00 ; Objc message: -[x0 splitLeftBundleID]
    aae7c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aaea4:	bl	0x2ecd00 ; Objc message: -[x0 splitApp2]
    aaeac:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aaeb4:	cbz	x0, 0xaaec4
    aaec0:	b	0xaaeec
    aaed0:	bl	0x2ecd00 ; Objc message: -[x0 splitRightBundleID]
    aaed8:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aaefc:	bl	0x2ecd00 ; Objc message: -[x0 splitApp3]
    aaf04:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aaf24:	bl	0x2ecd00 ; Objc message: -[x0 splitApp4]
    aaf2c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aaf58:	bl	0x2ecd00 ; Objc message: +[NSArray arrayWithObjects:count:]
    aaf60:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aaf78:	bl	0x2ecd00 ; Objc message: -[x0 arrayWithArray:]
    aaf80:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aaf98:	bl	0x2ecd30 ; symbol stub for: _objc_release
    aafa0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    aafa8:	bl	0x2ecd30 ; symbol stub for: _objc_release

## CBMultitaskingOverlayView.layoutSubviews @ 0xa28e8
Original ABI: \`v16@0:8\`
Function boundary: \`0xa28e8..0xa2a58\`
Instruction count: **92**; branches **11**;
Potential numerical operations (not yet semantic proof):

    a28e8:	sub	sp, sp, #0x50
    a28fc:	add	x29, sp, #0x40
    a296c:	fcmp	d8, #0.0
    a2974:	fcmp	d3, #0.0
    a2988:	fmov	d0, #24.00000000
    a298c:	fmov	d1, #10.00000000
    a29a0:	fmov	d1, #18.00000000
    a29a4:	fmov	d2, #8.00000000
    a29d0:	fmov	d1, #0.50000000
    a2a50:	add	sp, sp, #0x50

Branch samples:
    a291c:	bl	0x2ecd18 ; Objc message: -[[x0 super] layoutSubviews]
    a2930:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    a294c:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    a2958:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    a2968:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    a2970:	b.ls	0xa2a40
    a2978:	b.ls	0xa2a40
    a2a0c:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    a2a18:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    a2a2c:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    a2a3c:	bl	0x2ecd00 ; Objc message: -[x0 setupCardContent]

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

## CBBridgedUIAppView.setAudioOnlyBackgroundMode: @ 0xac858
Original ABI: \`v20@0:8B16\`
Function boundary: \`0xac858..0xac8f0\`
Instruction count: **38**; branches **7**;
Potential numerical operations (not yet semantic proof):

    ac860:	add	x29, sp, #0x10
    ac898:	mov	w2, #0x0
    ac8a8:	fmov	d0, #1.00000000
    ac8c0:	mov	w2, #0x1

Branch samples:
    ac87c:	cbz	w2, 0xac8a8
    ac888:	bl	0x2ecd00 ; Objc message: -[x0 setAlpha:]
    ac8a4:	b	0x2ecd00 ; Objc message: -[x0 setUserInteractionEnabled:]
    ac8b0:	bl	0x2ecd00 ; Objc message: -[x0 setUserInteractionEnabled:]
    ac8c4:	bl	0x2ecd00 ; Objc message: -[x0 setUserInteractionEnabled:]
    ac8d4:	bl	0x2ecd00 ; Objc message: -[x0 updateLayout]
    ac8ec:	b	0x2ecd00 ; Objc message: -[x0 refreshSceneLayout]

## CBBridgedUIAppView.dismiss @ 0xaf01c
Original ABI: \`v16@0:8\`
Function boundary: \`0xaf01c..0xaf1d8\`
Instruction count: **111**; branches **27**;
Potential numerical operations (not yet semantic proof):

    af02c:	add	x29, sp, #0x30
    af03c:	mov	w2, #0x1
    af050:	mov	w2, #0x0
    af094:	mov	w2, #0x0
    af098:	mov	w3, #0x0
    af0d4:	mov	x2, #0x0
    af12c:	mov	x2, #0x0

Branch samples:
    af040:	bl	0x2ecd00 ; Objc message: -[x0 setInvalidated:]
    af054:	bl	0x2ecd00 ; Objc message: -[x0 setHosting:]
    af068:	cbz	x0, 0xaf190
    af084:	bl	0x2ecd00 ; Objc message: -[x0 respondsToSelector:]
    af088:	cbz	w0, 0xaf0b0
    af09c:	bl	0x2ecd00 ; Objc message: -[x0 respondsToSelector:]
    af0ac:	bl	0x2ecd00 ; Objc message: -[x0 endAppearanceTransition]
    af0c4:	bl	0x2ecd00 ; Objc message: -[x0 setRequestedMode:]
    af0c8:	cbz	w0, 0xaf0dc
    af0d8:	bl	0x2ecd00 ; Objc message: -[x0 setRequestedMode:]
    af0e8:	bl	0x2ecd00 ; Objc message: -[x0 view]
    af0f0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    af0fc:	bl	0x2ecd00 ; Objc message: -[x0 view]
    af104:	bl	0x2ecd30 ; symbol stub for: _objc_release
    af11c:	bl	0x2ecd00 ; Objc message: -[x0 willMoveToParentViewController:]
    af120:	cbz	w0, 0xaf134
    af130:	bl	0x2ecd00 ; Objc message: -[x0 willMoveToParentViewController:]
    af148:	bl	0x2ecd00 ; Objc message: -[x0 removeFromParentViewController]
    af14c:	cbz	w0, 0xaf15c
    af158:	bl	0x2ecd00 ; Objc message: -[x0 removeFromParentViewController]
    af170:	bl	0x2ecd00 ; Objc message: -[x0 invalidate]
    af174:	cbz	w0, 0xaf184
    af180:	bl	0x2ecd00 ; Objc message: -[x0 invalidate]
    af18c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    af19c:	cbz	x0, 0xaf1c4
    af1a4:	bl	0x2ecd00 ; Objc message: -[x0 invalidate]
    af1c0:	b	0x2ecd30 ; symbol stub for: _objc_release

