# Original Native12: layout and preset ARM64 IMP evidence

- Verified original DEB SHA256: \`2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad\`
- Verified Dashboard SHA256: \`9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea\`
- Original method index blob: \`efa45df59bc3c16887cc979bf3aedc0c93c92111\`
- Exact extracted IMPs: **16**, ARM64 instructions: **30686**
- IMPORTANT: machine disassembly is NOT a runtime preset-frame test.
- A selector in an Objective-C call site does NOT prove a receiver.
- Preset 0..7 formulas in independent DFLayoutEngine remain UNVERIFIED until
  original function control flow and numerical CGRect outputs are derived.
- This artifact contains read-only evidence; no vendor code linked to app.

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

## CBBridgedSplitApp.setSplitPreset: @ 0x11fec4
Original ABI: \`v24@0:8q16\`
Function boundary: \`0x11fec4..0x11fed4\`
Instruction count: **4**; branches **0**;
Potential numerical operations (not yet semantic proof):


Branch samples:

## CBBridgedSplitApp.handleDividerPan:isVertical:state: @ 0x103ee0
Original ABI: \`v44@0:8{CGPoint=dd}16B32q36\`
Function boundary: \`0x103ee0..0x1044f8\`
Instruction count: **390**; branches **86**;
Potential numerical operations (not yet semantic proof):

    103f04:	add	x29, sp, #0x80
    103f08:	sub	sp, sp, #0x1b0
    103f20:	cmp	x3, #0x2
    103f28:	cmp	x3, #0x1
    103fac:	cmp	w19, #0x0
    103fbc:	fcmp	d0, #0.0
    104020:	add	sp, sp, #0x1b0
    10404c:	sub	x8, x3, #0x3
    104050:	cmp	x8, #0x1
    104090:	fmov	d2, #-0.50000000
    1040a4:	fmov	d0, #0.50000000
    104114:	cmn	x8, #0x1
    1041bc:	add	x3, x3, #0x2c8 ; Objc cfstring ref: @"splitRatio"
    1041d8:	cmn	x8, #0x1
    1041f0:	mov	w3, #0x1
    104214:	cmn	x8, #0x1
    104238:	mov	x2, #0x0
    10423c:	mov	x3, #0x0
    104240:	mov	w4, #0x1
    104280:	add	x2, sp, #0x60
    104284:	add	x3, sp, #0x120
    10428c:	mov	w4, #0x10
    1042a8:	mov	x23, #0x0
    1042d8:	add	x23, x23, #0x1
    1042e4:	add	x2, sp, #0x60
    1042e8:	add	x3, sp, #0x120
    1042f4:	mov	w4, #0x10
    104354:	add	x2, sp, #0x20
    104358:	add	x3, sp, #0xa0
    104360:	mov	w4, #0x10
    10437c:	mov	x23, #0x0
    10440c:	mov	w3, #0x1
    104424:	add	x23, x23, #0x1
    104430:	add	x2, sp, #0x20
    104434:	add	x3, sp, #0xa0
    104440:	mov	w4, #0x10
    104480:	add	sp, sp, #0x1b0
    1044b0:	add	x0, x0, #0x630
    1044b8:	add	x1, x1, #0x178
    1044c8:	add	x0, x0, #0x630

Branch samples:
    103f24:	b.eq	0x103f4c
    103f2c:	b.ne	0x10404c
    103f48:	b	0x104468
    103f68:	bl	0x2ecd00 ; Objc message: +[CBWindow carPlayUsableBounds]
    103f80:	bl	0x2ecd00 ; Objc message: -[x0 view]
    103f88:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    103f98:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    103fa8:	bl	0x2ecd30 ; symbol stub for: _objc_release
    104010:	b.ne	0x1044f4
    104048:	b	0x2ecd00 ; Objc message: -[x0 layoutSplitViews]
    104054:	b.hi	0x104468
    104080:	b.pl	0x104090
    10408c:	b	0x1040cc
    1040a0:	b.pl	0x1040ac
    1040a8:	b	0x1040cc
    1040c0:	b.pl	0x1040d0
    1040e4:	bl	0x2ecd00 ; Objc message: +[CBDashboardSettings sharedInstance]
    1040ec:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    104100:	bl	0x2ecd00 ; Objc message: -[x0 setSplitRatio:]
    10411c:	b.ne	0x1044ac
    104128:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    104140:	bl	0x2ecd00 ; Objc message: +[NSMutableDictionary dictionaryWithContentsOfFile:]
    104148:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    104150:	cbz	x0, 0x104160
    104158:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    10415c:	b	0x104178
    10416c:	bl	0x2ecd00 ; Objc message: -[x0 dictionary]
    104174:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    104180:	bl	0x2ecd30 ; symbol stub for: _objc_release
    104188:	bl	0x2ecd30 ; symbol stub for: _objc_release
    1041a0:	bl	0x2ecd00 ; Objc message: +[NSNumber numberWithDouble:]
    1041a8:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    1041c8:	bl	0x2ecd00 ; Objc message: -[x0 setObject:forKeyedSubscript:]
    1041d0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    1041dc:	b.ne	0x1044c4
    1041f4:	bl	0x2ecd00 ; Objc message: -[x0 writeToFile:atomically:]
    1041f8:	bl	0x2ec7cc ; symbol stub for: _CFNotificationCenterGetDarwinNotifyCenter
    104208:	cbnz	x1, 0x104230
    104218:	b.ne	0x1044dc
    104224:	bl	0x2ecd3c ; symbol stub for: _objc_retain

## CBBridgedSplitApp.focusSlot:animated: @ 0x105890
Original ABI: \`v28@0:8q16B24\`
Function boundary: \`0x105890..0x105bc4\`
Instruction count: **205**; branches **42**;
Potential numerical operations (not yet semantic proof):

    105890:	sub	sp, sp, #0x1b0
    1058ac:	add	x29, sp, #0x1a0
    105908:	mov	w9, #0x1
    10597c:	add	x2, sp, #0x80
    105980:	add	x3, sp, #0xc0
    10598c:	mov	w4, #0x10
    1059a4:	mov	x22, #0x0
    105a74:	mov	w3, #0x1
    105a8c:	add	x22, x22, #0x1
    105a98:	add	x2, sp, #0x80
    105a9c:	add	x3, sp, #0xc0
    105aa8:	mov	w4, #0x10
    105ae4:	add	x10, x10, #0x818
    105b14:	add	x9, x9, #0x658
    105b3c:	fmov	d3, #0.50000000
    105b40:	add	x19, sp, #0x58
    105b48:	add	x3, sp, #0x30
    105b4c:	add	x4, sp, #0x58
    105b50:	mov	w2, #0x4
    105b6c:	add	x19, sp, #0x58
    105b74:	add	x0, sp, #0x58
    105b78:	mov	w1, #0x1
    105bb8:	add	sp, sp, #0x1b0

Branch samples:
    1058c0:	tbnz	x2, #0x3f, 0x105b88
    1058e4:	bl	0x2ecd00 ; Objc message: -[x0 count]
    1058ec:	b.ls	0x105b88
    1058fc:	cbnz	w9, 0x105b88
    105904:	cbz	w21, 0x105910
    105930:	bl	0x2ecd00 ; Objc message: +[CBBridgeManager sharedInstance]
    105938:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    105948:	bl	0x2ecd00 ; Objc message: -[x0 saveBridgeStateToDisk]
    105950:	bl	0x2ecd30 ; symbol stub for: _objc_release
    105970:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    105990:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    105994:	cbz	x0, 0x105ab8
    1059cc:	b.eq	0x1059d8
    1059d4:	bl	0x2eccb8 ; symbol stub for: _objc_enumerationMutation
    1059e8:	bl	0x2ecd00 ; Objc message: -[x0 sendStateToApp:shouldBridge:]
    1059f0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    1059f8:	cbz	x0, 0x105a84
    105a04:	bl	0x2ecd00 ; Objc message: -[x0 sendStateToApp:shouldBridge:]
    105a0c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    105a18:	bl	0x2ecd00 ; Objc message: -[x0 sendStateToApp:shouldBridge:]
    105a24:	bl	0x2ecd30 ; symbol stub for: _objc_release
    105a2c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    105a30:	cbz	x23, 0x105a8c
    105a40:	bl	0x2ecd00 ; Objc message: +[CBBridgeManager sendStateToApp:shouldBridge:]
    105a48:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    105a58:	bl	0x2ecd00 ; Objc message: -[x0 sendStateToApp:shouldBridge:]
    105a60:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    105a78:	bl	0x2ecd00 ; Objc message: -[x0 sendStateToApp:shouldBridge:]
    105a80:	bl	0x2ecd30 ; symbol stub for: _objc_release
    105a88:	bl	0x2ecd30 ; symbol stub for: _objc_release
    105a94:	b.lo	0x1059c0
    105aac:	bl	0x2ecd00 ; Objc message: -[x0 sendStateToApp:shouldBridge:]
    105ab4:	cbnz	x0, 0x1059a4
    105abc:	bl	0x2ecd30 ; symbol stub for: _objc_release
    105af8:	cbz	w9, 0x105b5c
    105b54:	bl	0x2ecd00 ; Objc message: +[UIView animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:]
    105b58:	b	0x105b80
    105b68:	bl	0x2ecd00 ; Objc message: -[x0 layoutSplitViews]
    105b7c:	blr	x8
    105b84:	bl	0x2ecd30 ; symbol stub for: _objc_release

## CBBridgedSplitApp.restoreSplitAnimated: @ 0x105e2c
Original ABI: \`v20@0:8B16\`
Function boundary: \`0x105e2c..0x1062b0\`
Instruction count: **289**; branches **60**;
Potential numerical operations (not yet semantic proof):

    105e44:	add	x29, sp, #0x50
    105e48:	sub	sp, sp, #0x2d0
    105e78:	mov	w9, #0x1
    105e88:	mov	x9, #-0x1
    105eb8:	add	x2, sp, #0x100
    105ebc:	sub	x3, x29, #0xe0
    105ec4:	mov	w4, #0x10
    105ee4:	mov	x27, #0x0
    105f18:	mov	w2, #0x0
    105f28:	mov	w2, #0x1
    105f30:	add	x27, x27, #0x1
    105f3c:	add	x2, sp, #0x100
    105f40:	sub	x3, x29, #0xe0
    105f4c:	mov	w4, #0x10
    105f84:	add	x2, sp, #0xc0
    105f88:	add	x3, sp, #0x1c0
    105f90:	mov	w4, #0x10
    105fa8:	mov	x24, #0x0
    105fd4:	mov	w2, #0x0
    105fdc:	add	x24, x24, #0x1
    105fe8:	add	x2, sp, #0xc0
    105fec:	add	x3, sp, #0x1c0
    105ff8:	mov	w4, #0x10
    106068:	add	x2, sp, #0x80
    10606c:	add	x3, sp, #0x140
    106078:	mov	w4, #0x10
    106090:	mov	x23, #0x0
    106160:	mov	w3, #0x1
    106178:	add	x23, x23, #0x1
    106184:	add	x2, sp, #0x80
    106188:	add	x3, sp, #0x140
    106194:	mov	w4, #0x10
    1061d0:	add	x10, x10, #0x818
    106200:	add	x9, x9, #0x658
    106228:	fmov	d3, #0.50000000
    10622c:	add	x19, sp, #0x58
    106234:	add	x3, sp, #0x30
    106238:	add	x4, sp, #0x58
    10623c:	mov	w2, #0x4
    106258:	add	x19, sp, #0x58

Branch samples:
    105e68:	cbnz	w9, 0x106274
    105e74:	cbz	w2, 0x105e80
    105ea8:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    105ec8:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    105ed0:	cbz	x0, 0x105f5c
    105efc:	b.eq	0x105f08
    105f04:	bl	0x2eccb8 ; symbol stub for: _objc_enumerationMutation
    105f1c:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    105f2c:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    105f38:	b.lo	0x105ef0
    105f50:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    105f58:	cbnz	x0, 0x105ee4
    105f60:	bl	0x2ecd30 ; symbol stub for: _objc_release
    105f7c:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    105f94:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    105f98:	cbz	x0, 0x106008
    105fbc:	b.eq	0x105fc8
    105fc4:	bl	0x2eccb8 ; symbol stub for: _objc_enumerationMutation
    105fd8:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    105fe4:	b.lo	0x105fb0
    105ffc:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    106004:	cbnz	x0, 0x105fa8
    10600c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    106024:	bl	0x2ecd00 ; Objc message: +[CBBridgeManager sharedInstance]
    10602c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    10603c:	bl	0x2ecd00 ; Objc message: -[x0 saveBridgeStateToDisk]
    106044:	bl	0x2ecd30 ; symbol stub for: _objc_release
    106064:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    10607c:	bl	0x2ecd00 ; Objc message: -[x0 saveBridgeStateToDisk]
    106080:	cbz	x0, 0x1061a4
    1060b8:	b.eq	0x1060c4
    1060c0:	bl	0x2eccb8 ; symbol stub for: _objc_enumerationMutation
    1060d4:	bl	0x2ecd00 ; Objc message: -[x0 sendStateToApp:shouldBridge:]
    1060dc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    1060e4:	cbz	x0, 0x106170
    1060f0:	bl	0x2ecd00 ; Objc message: -[x0 sendStateToApp:shouldBridge:]
    1060f8:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    106104:	bl	0x2ecd00 ; Objc message: -[x0 sendStateToApp:shouldBridge:]
    106110:	bl	0x2ecd30 ; symbol stub for: _objc_release
    106118:	bl	0x2ecd30 ; symbol stub for: _objc_release

## CBBridgedSplitApp.rotateAllSlotsClockwise @ 0x106560
Original ABI: \`v16@0:8\`
Function boundary: \`0x106560..0x1066e4\`
Instruction count: **97**; branches **15**;
Potential numerical operations (not yet semantic proof):

    106560:	sub	sp, sp, #0x80
    106570:	add	x29, sp, #0x70
    106594:	cmp	x0, #0x2
    1065a8:	cmp	x0, #0x2
    1065bc:	mov	x2, #0x0
    1065c0:	mov	w3, #0x1
    1065d0:	add	sp, sp, #0x80
    1065e4:	cmp	x0, #0x3
    1065f8:	mov	x2, #0x0
    1065fc:	mov	w3, #0x1
    106604:	mov	x0, #0x0
    106608:	mov	w1, #0x7600
    10660c:	movk	w1, #0x10b0, lsl #16
    106638:	add	x9, x9, #0x658
    10664c:	add	x2, sp, #0x28
    106660:	cmp	x0, #0x4
    106674:	mov	x2, #0x0
    106678:	mov	w3, #0x1
    106680:	mov	x0, #0x0
    106684:	mov	w1, #0x7600
    106688:	movk	w1, #0x10b0, lsl #16
    1066b4:	add	x9, x9, #0x658
    1066dc:	add	sp, sp, #0x80

Branch samples:
    106590:	bl	0x2ecd00 ; Objc message: -[x0 count]
    106598:	b.lo	0x1066d0
    1065a4:	bl	0x2ecd00 ; Objc message: -[x0 count]
    1065ac:	b.ne	0x1065d8
    1065d4:	b	0x2ecd00 ; Objc message: -[x0 swapSlot:withSlot:]
    1065e0:	bl	0x2ecd00 ; Objc message: -[x0 swapSlot:withSlot:]
    1065e8:	b.ne	0x106654
    106600:	bl	0x2ecd00 ; Objc message: -[x0 swapSlot:withSlot:]
    106610:	bl	0x2ecb50 ; symbol stub for: _dispatch_time
    106650:	b	0x1066cc
    10665c:	bl	0x2ecd00 ; Objc message: -[x0 swapSlot:withSlot:]
    106664:	b.lo	0x1066d0
    10667c:	bl	0x2ecd00 ; Objc message: -[x0 swapSlot:withSlot:]
    10668c:	bl	0x2ecb50 ; symbol stub for: _dispatch_time
    1066cc:	bl	0x2ecb20 ; symbol stub for: _dispatch_after

## CBBridgedSplitApp.moveSlot:direction: @ 0x108f28
Original ABI: \`v32@0:8q16q24\`
Function boundary: \`0x108f28..0x108fc8\`
Instruction count: **40**; branches **4**;
Potential numerical operations (not yet semantic proof):

    108f38:	add	x29, sp, #0x30
    108f64:	cmp	x0, #0x2
    108f90:	sub	x9, x0, #0x1
    108f94:	cmp	x8, #0x0

Branch samples:
    108f60:	bl	0x2ecd00 ; Objc message: -[x0 count]
    108f68:	b.hs	0x108f80
    108f88:	bl	0x2ecd00 ; Objc message: -[x0 count]
    108fc4:	b	0x2ecd00 ; Objc message: -[x0 swapSlot:withSlot:]

## CBBridgedSplitApp.swapSlot:withSlot: @ 0x10915c
Original ABI: \`v32@0:8q16q24\`
Function boundary: \`0x10915c..0x10949c\`
Instruction count: **208**; branches **55**;
Potential numerical operations (not yet semantic proof):

    10915c:	sub	sp, sp, #0x130
    10917c:	add	x29, sp, #0x120
    1092b8:	mov	x27, #0x0
    1092f0:	mov	x25, #0x0
    109340:	add	x9, x9, #0x118
    109384:	add	x9, x9, #0x148
    1093e0:	fmov	d0, #0.25000000
    1093e4:	add	x4, sp, #0x50
    1093e8:	add	x5, sp, #0x18
    1093f8:	mov	w3, #0x500000
    109494:	add	sp, sp, #0x130

Branch samples:
    109180:	tbnz	x2, #0x3f, 0x109478
    109190:	b.eq	0x109478
    1091b0:	bl	0x2ecd00 ; Objc message: -[x0 count]
    1091b4:	tbnz	x20, #0x3f, 0x109478
    1091bc:	b.ls	0x109478
    1091c8:	bl	0x2ecd00 ; Objc message: -[x0 count]
    1091d0:	b.ls	0x109478
    1091e4:	bl	0x2ecd00 ; Objc message: -[x0 count]
    1091ec:	b.ls	0x109478
    1091f8:	bl	0x2ecd00 ; Objc message: -[x0 count]
    109200:	b.ls	0x109478
    109218:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    109220:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    109234:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    10923c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    109250:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    109258:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    10926c:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    109274:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    10928c:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    109294:	b.ls	0x1092b8
    1092a4:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    1092ac:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    1092b4:	b	0x1092bc
    1092c4:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    1092cc:	b.ls	0x1092f0
    1092dc:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    1092e4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    1092ec:	b	0x1092f4
    10930c:	bl	0x2ecd00 ; Objc message: +[UIView view]
    109314:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    10934c:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    10935c:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    10939c:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    1093a8:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    1093b4:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    1093c0:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    1093cc:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    1093d8:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    1093fc:	bl	0x2ecd00 ; Objc message: -[x0 transitionWithView:duration:options:animations:completion:]

## CBBridgedSplitApp.replaceAppInSlot:withBundleIdentifier: @ 0x1098c0
Original ABI: \`v32@0:8q16@24\`
Function boundary: \`0x1098c0..0x109ee8\`
Instruction count: **394**; branches **91**;
Potential numerical operations (not yet semantic proof):

    1098dc:	add	x29, sp, #0x60
    1098e0:	sub	sp, sp, #0x210
    109988:	add	x9, sp, #0xb0
    10998c:	mov	x10, #-0x1
    1099c0:	add	x2, sp, #0xb0
    1099c4:	sub	x3, x29, #0xf8
    1099cc:	mov	w4, #0x10
    1099e8:	fmov	d8, #1.00000000
    1099ec:	mov	x21, #0x0
    109a30:	mov	w2, #0x0
    109a50:	mov	w2, #0x1
    109a58:	add	x21, x21, #0x1
    109a64:	add	x2, sp, #0xb0
    109a68:	sub	x3, x29, #0xf8
    109a74:	mov	w4, #0x10
    109ab4:	add	x2, sp, #0x70
    109ab8:	add	x3, sp, #0xf8
    109ac0:	mov	w4, #0x10
    109adc:	fmov	d8, #1.00000000
    109ae0:	mov	x21, #0x0
    109b14:	mov	w2, #0x0
    109b2c:	add	x21, x21, #0x1
    109b38:	add	x2, sp, #0x70
    109b3c:	add	x3, sp, #0xf8
    109b48:	mov	w4, #0x10
    109c64:	mov	w3, #0x0
    109ce4:	mov	w2, #0x12
    109cfc:	mov	x3, #0x0
    109d5c:	mov	w2, #0x1
    109e38:	add	x9, x9, #0x7e8
    109e68:	add	x1, sp, #0x38
    109ec0:	add	sp, sp, #0x210

Branch samples:
    109900:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    109908:	tbnz	x20, #0x3f, 0x109ea0
    109924:	bl	0x2ecd00 ; Objc message: -[x0 count]
    10992c:	b.ls	0x109ea0
    109940:	bl	0x2ecd00 ; Objc message: -[x0 count]
    109944:	cbz	x19, 0x109ea0
    10994c:	b.ls	0x109ea0
    109960:	bl	0x2ecd00 ; Objc message: -[x0 length]
    109964:	cbz	x0, 0x109ea0
    109980:	tbnz	x9, #0x3f, 0x109b6c
    1099b0:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    1099d0:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    1099d8:	cbz	x0, 0x109a88
    109a14:	b.eq	0x109a20
    109a1c:	bl	0x2eccb8 ; symbol stub for: _objc_enumerationMutation
    109a34:	bl	0x2ecd00 ; Objc message: -[x0 setHidden:]
    109a44:	bl	0x2ecd00 ; Objc message: -[x0 setHidden:]
    109a54:	bl	0x2ecd00 ; Objc message: -[x0 setHidden:]
    109a60:	b.lo	0x109a08
    109a78:	bl	0x2ecd00 ; Objc message: -[x0 setHidden:]
    109a84:	cbnz	x0, 0x1099ec
    109a8c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    109aac:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    109ac4:	bl	0x2ecd00 ; Objc message: -[x0 setHidden:]
    109ac8:	cbz	x0, 0x109b58
    109af8:	b.eq	0x109b04
    109b00:	bl	0x2eccb8 ; symbol stub for: _objc_enumerationMutation
    109b18:	bl	0x2ecd00 ; Objc message: -[x0 setHidden:]
    109b28:	bl	0x2ecd00 ; Objc message: -[x0 setHidden:]
    109b34:	b.lo	0x109aec
    109b4c:	bl	0x2ecd00 ; Objc message: -[x0 setHidden:]
    109b54:	cbnz	x0, 0x109ae0
    109b5c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    109b84:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    109b8c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    109ba0:	bl	0x2ecd00 ; Objc message: -[x0 bundleIdentifier]
    109ba8:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    109bbc:	bl	0x2ecd00 ; Objc message: -[x0 isEqualToString:]
    109bc8:	bl	0x2ecd30 ; symbol stub for: _objc_release
    109bcc:	tbnz	w25, #0x0, 0x109e98

## CBDashboardSettings.setSplitPreset: @ 0x37f40
Original ABI: \`v24@0:8q16\`
Function boundary: \`0x37f40..0x37f48\`
Instruction count: **2**; branches **0**;
Potential numerical operations (not yet semantic proof):


Branch samples:

## CBDashboardSettings.setGridRows: @ 0x37fd0
Original ABI: \`v24@0:8q16\`
Function boundary: \`0x37fd0..0x37fd8\`
Instruction count: **2**; branches **0**;
Potential numerical operations (not yet semantic proof):


Branch samples:

## CBDashboardSettings.setGridCols: @ 0x37fc0
Original ABI: \`v24@0:8q16\`
Function boundary: \`0x37fc0..0x37fc8\`
Instruction count: **2**; branches **0**;
Potential numerical operations (not yet semantic proof):


Branch samples:

## CBMultitaskingOverlayView.presetSelected: @ 0xaa4f0
Original ABI: \`v24@0:8@16\`
Function boundary: \`0xaa4f0..0xaa800\`
Instruction count: **196**; branches **50**;
Potential numerical operations (not yet semantic proof):

    aa508:	add	x29, sp, #0x50
    aa584:	cmn	x8, #0x1
    aa62c:	add	x3, x3, #0x208 ; Objc cfstring ref: @"splitPreset"
    aa668:	add	x3, x3, #0x228 ; Objc cfstring ref: @"splitMode"
    aa688:	cmn	x8, #0x1
    aa6a0:	mov	w3, #0x1
    aa6c4:	cmn	x8, #0x1
    aa6e4:	mov	x2, #0x0
    aa6e8:	mov	x3, #0x0
    aa6ec:	mov	w4, #0x1
    aa7bc:	add	x0, x0, #0x528
    aa7c4:	add	x1, x1, #0xe18
    aa7d4:	add	x0, x0, #0x528
    aa7dc:	add	x1, x1, #0xe18
    aa7ec:	add	x0, x0, #0x540
    aa7f4:	add	x1, x1, #0xe38

Branch samples:
    aa51c:	bl	0x2ecd00 ; Objc message: -[x0 tag]
    aa540:	bl	0x2ecd00 ; Objc message: +[CBDashboardSettings sharedInstance]
    aa548:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aa55c:	bl	0x2ecd00 ; Objc message: -[x0 setSplitPreset:]
    aa570:	bl	0x2ecd00 ; Objc message: -[x0 setSplitMode:]
    aa588:	b.ne	0xaa7b8
    aa594:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    aa5ac:	bl	0x2ecd00 ; Objc message: +[NSMutableDictionary dictionaryWithContentsOfFile:]
    aa5b4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aa5bc:	cbz	x0, 0xaa5cc
    aa5c4:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    aa5c8:	b	0xaa5e4
    aa5d8:	bl	0x2ecd00 ; Objc message: -[x0 dictionary]
    aa5e0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aa5ec:	bl	0x2ecd30 ; symbol stub for: _objc_release
    aa5f4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    aa610:	bl	0x2ecd00 ; Objc message: +[NSNumber numberWithInteger:]
    aa618:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aa63c:	bl	0x2ecd00 ; Objc message: -[x0 setObject:forKeyedSubscript:]
    aa644:	bl	0x2ecd30 ; symbol stub for: _objc_release
    aa654:	bl	0x2ecd00 ; Objc message: -[x0 setObject:forKeyedSubscript:]
    aa65c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aa678:	bl	0x2ecd00 ; Objc message: -[x0 setObject:forKeyedSubscript:]
    aa680:	bl	0x2ecd30 ; symbol stub for: _objc_release
    aa68c:	b.ne	0xaa7d0
    aa6a4:	bl	0x2ecd00 ; Objc message: -[x0 writeToFile:atomically:]
    aa6a8:	bl	0x2ec7cc ; symbol stub for: _CFNotificationCenterGetDarwinNotifyCenter
    aa6b8:	cbnz	x1, 0xaa6e0
    aa6c8:	b.ne	0xaa7e8
    aa6d4:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    aa6f0:	bl	0x2ec7d8 ; symbol stub for: _CFNotificationCenterPostNotification
    aa704:	bl	0x2ecd00 ; Objc message: -[x0 onMultiSplitSelected]
    aa70c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aa714:	bl	0x2ecd30 ; symbol stub for: _objc_release
    aa718:	cbz	x24, 0xaa780
    aa724:	bl	0x2ecd00 ; Objc message: -[x0 onMultiSplitSelected]
    aa72c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aa748:	bl	0x2ecd00 ; Objc message: -[x0 copy]
    aa76c:	blr	x8
    aa774:	bl	0x2ecd30 ; symbol stub for: _objc_release

## CBMultitaskingOverlayView.setupPresetCardsInCardW:cardH:contentY: @ 0xa5e78
Original ABI: \`v40@0:8d16d24d32\`
Function boundary: \`0xa5e78..0xa678c\`
Instruction count: **581**; branches **112**;
Potential numerical operations (not yet semantic proof):

    a5ea0:	add	x29, sp, #0x90
    a5ea4:	sub	sp, sp, #0x190
    a5efc:	fmov	d11, #-4.00000000
    a5f4c:	mov	w8, #0x5
    a5f50:	mov	w9, #0x6
    a5f58:	fmov	d0, #-28.00000000
    a5f64:	sub	x8, x9, #0x1
    a5f6c:	fmov	d8, #10.00000000
    a5f84:	fmov	d0, #-14.00000000
    a5fb8:	fmov	d2, #1.00000000
    a5fd4:	mov	x26, #0x0
    a6084:	fmov	d1, #0.50000000
    a609c:	mov	x8, #0x404b000000000000
    a60c8:	fmov	d0, #-17.00000000
    a61c4:	fmov	d1, #14.00000000
    a61d4:	fmov	d1, #22.00000000
    a61e8:	mov	x2, #0x0
    a6230:	fmov	d0, #12.00000000
    a6270:	mov	w2, #0x1
    a6298:	mov	w4, #0x40
    a630c:	fmov	d0, #2.00000000
    a6328:	fmov	d2, #1.00000000
    a63c8:	fmov	d8, #1.00000000
    a6460:	fmov	d1, #6.00000000
    a64b4:	mov	w2, #0x1
    a64c4:	mov	w2, #0x0
    a64f8:	fmov	d1, #4.00000000
    a64fc:	fmov	d2, #17.00000000
    a6540:	sub	x2, x29, #0xb0
    a6548:	mov	w3, #0x2
    a6598:	add	x2, x2, #0xec8 ; Objc cfstring ref: @"checkmark.circle.fill"
    a6698:	fmov	d0, #3.00000000
    a66b0:	mov	w2, #0x0
    a6700:	add	x26, x26, #0x1
    a6704:	cmp	x26, #0x9
    a6758:	add	sp, sp, #0x190

Branch samples:
    a5edc:	bl	0x2ecd00 ; Objc message: -[x0 contentView]
    a5ee4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a5ef4:	bl	0x2ecc34 ; symbol stub for: _objc_alloc
    a5f1c:	bl	0x2ecd00 ; Objc message: +[CBOverlayScrollView initWithFrame:]
    a5f3c:	bl	0x2ecd00 ; Objc message: -[x0 addSubview:]
    a5fc4:	bl	0x2ecd00 ; Objc message: +[UIColor colorWithRed:green:blue:alpha:]
    a5fcc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a61ec:	bl	0x2ecd00 ; Objc message: +[UIButton bringSubviewToFront:]
    a61f4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a6210:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    a621c:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    a6224:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a6234:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    a623c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a6248:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    a6250:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a625c:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    a6264:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a6274:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    a6284:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    a629c:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    a62b0:	b.ne	0xa6364
    a62c8:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    a62d0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a62e4:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    a62ec:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a62f8:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    a6300:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a6310:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    a6318:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a6330:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    a6338:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a633c:	bl	0x2ecd48 ; symbol stub for: _objc_retainAutorelease
    a6348:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    a6358:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    a6360:	b	0xa6420
    a6384:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    a638c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a63a0:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    a63a8:	bl	0x2ecd30 ; symbol stub for: _objc_release

## CBBridgeManager.switchToMultiSplitMode:apps:ratio: @ 0x24d228
Original ABI: \`v40@0:8q16@24d32\`
Function boundary: \`0x24d228..0x267764\`
Instruction count: **26959**; branches **2214**;
Potential numerical operations (not yet semantic proof):

    24d248:	add	x29, sp, #0x70
    24d24c:	sub	sp, sp, #0x1, lsl #12
    24d250:	sub	sp, sp, #0x8e0
    24d290:	mov	w8, #0x1
    24d308:	mov	x2, #0x0
    24d340:	mov	x2, #0x0
    24d37c:	cmp	x0, #0x2
    24d390:	mov	w2, #0x1
    24d3c8:	mov	w2, #0x1
    24d404:	cmp	x0, #0x3
    24d414:	mov	w2, #0x2
    24d450:	cmp	x0, #0x4
    24d460:	mov	w2, #0x3
    24d4b8:	cmn	x8, #0x1
    24d54c:	mov	w2, #0x1
    24d56c:	add	x3, x3, #0x188 ; Objc cfstring ref: @"splitScreenEnabled"
    24d5b0:	add	x3, x3, #0x208 ; Objc cfstring ref: @"splitPreset"
    24d5ec:	add	x3, x3, #0x228 ; Objc cfstring ref: @"splitMode"
    24d624:	mov	x2, #0x0
    24d63c:	add	x3, x3, #0x248 ; Objc cfstring ref: @"splitApp1"
    24d660:	mov	x2, #0x0
    24d678:	add	x3, x3, #0x1c8 ; Objc cfstring ref: @"splitLeftBundleID"
    24d6a0:	cmp	x0, #0x2
    24d6b8:	mov	w2, #0x1
    24d6d0:	add	x3, x3, #0x268 ; Objc cfstring ref: @"splitApp2"
    24d6f4:	mov	w2, #0x1
    24d70c:	add	x3, x3, #0x1e8 ; Objc cfstring ref: @"splitRightBundleID"
    24d734:	cmp	x0, #0x3
    24d744:	mov	w2, #0x2
    24d75c:	add	x3, x3, #0x288 ; Objc cfstring ref: @"splitApp3"
    24d784:	cmp	x0, #0x4
    24d794:	mov	w2, #0x3
    24d7ac:	add	x3, x3, #0x2a8 ; Objc cfstring ref: @"splitApp4"
    24d7fc:	mov	w2, #0x0
    24d80c:	mov	w2, #0x2
    24d81c:	mov	w2, #0x1
    24d834:	add	x3, x3, #0x2e8 ; Objc cfstring ref: @"splitRatioIndex"
    24d854:	cmn	x8, #0x1
    24d878:	mov	w3, #0x1
    24d8a4:	cmn	x8, #0x1

Branch samples:
    24d274:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    24d2ac:	bl	0x2ecd00 ; Objc message: +[CBDashboardSettings sharedInstance]
    24d2b4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    24d2c8:	bl	0x2ecd00 ; Objc message: -[x0 setSplitPreset:]
    24d2dc:	bl	0x2ecd00 ; Objc message: -[x0 setSplitMode:]
    24d2f0:	bl	0x2ecd00 ; Objc message: -[x0 count]
    24d2f8:	cbz	x0, 0x24d370
    24d30c:	bl	0x2ecd00 ; Objc message: -[x0 count]
    24d314:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    24d32c:	bl	0x2ecd00 ; Objc message: -[x0 setSplitApp1:]
    24d334:	bl	0x2ecd30 ; symbol stub for: _objc_release
    24d344:	bl	0x2ecd00 ; Objc message: -[x0 setSplitApp1:]
    24d34c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    24d364:	bl	0x2ecd00 ; Objc message: -[x0 setSplitLeftBundleID:]
    24d36c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    24d378:	bl	0x2ecd00 ; Objc message: -[x0 setSplitLeftBundleID:]
    24d380:	b.lo	0x24d3f8
    24d394:	bl	0x2ecd00 ; Objc message: -[x0 setSplitLeftBundleID:]
    24d39c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    24d3b4:	bl	0x2ecd00 ; Objc message: -[x0 setSplitApp2:]
    24d3bc:	bl	0x2ecd30 ; symbol stub for: _objc_release
    24d3cc:	bl	0x2ecd00 ; Objc message: -[x0 setSplitApp2:]
    24d3d4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    24d3ec:	bl	0x2ecd00 ; Objc message: -[x0 setSplitRightBundleID:]
    24d3f4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    24d400:	bl	0x2ecd00 ; Objc message: -[x0 setSplitRightBundleID:]
    24d408:	b.lo	0x24d444
    24d418:	bl	0x2ecd00 ; Objc message: -[x0 setSplitRightBundleID:]
    24d420:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    24d438:	bl	0x2ecd00 ; Objc message: -[x0 setSplitApp3:]
    24d440:	bl	0x2ecd30 ; symbol stub for: _objc_release
    24d44c:	bl	0x2ecd00 ; Objc message: -[x0 setSplitApp3:]
    24d454:	b.lo	0x24d490
    24d464:	bl	0x2ecd00 ; Objc message: -[x0 setSplitApp3:]
    24d46c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    24d484:	bl	0x2ecd00 ; Objc message: -[x0 setSplitApp4:]
    24d48c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    24d4a4:	bl	0x2ecd00 ; Objc message: -[x0 setSplitRatio:]
    24d4bc:	b.ne	0x25d40c
    24d4c8:	bl	0x2ecd3c ; symbol stub for: _objc_retain

## CBWindow.carPlayUsableBounds @ 0xb0ef4
Original ABI: \`{CGRect={CGPoint=dd}{CGSize=dd}}16@0:8\`
Function boundary: \`0xb0ef4..0xb0ff0\`
Instruction count: **63**; branches **4**;
Potential numerical operations (not yet semantic proof):

    b0f04:	add	x29, sp, #0x30
    b0f4c:	mov	x8, #0x4059000000000000
    b0f58:	mov	x8, #0x4059000000000000
    b0f68:	fcmp	d0, #0.0
    b0f6c:	mov	x8, #-0x3fb0000000000000
    b0f7c:	mov	x8, #0x4050000000000000
    b0f9c:	fcmp	d5, #0.0
    b0fb4:	fcmp	d3, #0.0

Branch samples:
    b0f14:	bl	0x2ecd00 ; Objc message: -[x0 carPlayScreenBounds]
    b0f34:	bl	0x2ecd00 ; Objc message: -[x0 carPlayContentInsets]
    b0f64:	b.ge	0xb0fcc
    b0fc8:	b	0xb0fd4

