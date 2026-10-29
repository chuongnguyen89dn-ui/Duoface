# Original Native12: layout and preset ARM64 IMP evidence

- Verified original DEB SHA256: \`2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad\`
- Verified Dashboard SHA256: \`9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea\`
- Original method index blob: \`efa45df59bc3c16887cc979bf3aedc0c93c92111\`
- Exact extracted IMPs: **11**, ARM64 instructions: **3194**
- IMPORTANT: machine disassembly is NOT a runtime preset-frame test.
- A selector in an Objective-C call site does NOT prove a receiver.
- Preset 0..7 formulas in independent DFLayoutEngine remain UNVERIFIED until
  original function control flow and numerical CGRect outputs are derived.
- This artifact contains read-only evidence; no vendor code linked to app.

## CBWindow.carPlayContentInsets @ 0xb0c98
Original ABI: \`{UIEdgeInsets=dddd}16@0:8\`
Function boundary: \`0xb0c98..0xb0ef4\`
Instruction count: **151**; branches **41**;
Potential numerical operations (not yet semantic proof):

    b0cb8:	add	x29, sp, #0x70
    b0cc0:	add	x26, x26, #0x590
    b0ccc:	fcmp	d9, #0.0
    b0cd4:	fcmp	d11, #0.0
    b0cdc:	fcmp	d10, #0.0
    b0ce4:	fcmp	d8, #0.0
    b0cfc:	cmn	x8, #0x1
    b0d18:	mov	w3, #0x4
    b0d1c:	mov	x4, #0x0
    b0d60:	fcmp	d0, #0.0
    b0d68:	fcmp	d10, #0.0
    b0d70:	fcmp	d9, #0.0
    b0d78:	fcmp	d11, #0.0
    b0e4c:	fcmp	d12, #0.0
    b0e54:	fcmp	d10, #0.0
    b0e5c:	fcmp	d9, #0.0
    b0e64:	fcmp	d11, #0.0
    b0e6c:	mov	x8, #0x4050000000000000
    b0ee0:	add	x0, x0, #0x5b8
    b0ee8:	add	x1, x1, #0xf08

Branch samples:
    b0cd0:	b.gt	0xb0e8c
    b0cd8:	b.gt	0xb0e8c
    b0ce0:	b.gt	0xb0e8c
    b0ce8:	b.gt	0xb0e8c
    b0d00:	b.ne	0xb0edc
    b0d20:	bl	0x2ecd00 ; Objc message: +[NSString stringWithContentsOfFile:encoding:error:]
    b0d28:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b0d30:	cbz	x0, 0xb0d80
    b0d40:	bl	0x2ecd00 ; Objc message: -[x0 length]
    b0d44:	cbz	x0, 0xb0d80
    b0d4c:	bl	0x2eca24 ; symbol stub for: _UIEdgeInsetsFromString
    b0d64:	b.gt	0xb0ec0
    b0d6c:	b.gt	0xb0ec0
    b0d74:	b.gt	0xb0ec0
    b0d7c:	b.gt	0xb0ec0
    b0d90:	bl	0x2ecd00 ; Objc message: +[CBWindow activeCarPlayWindow]
    b0d98:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b0da4:	cbz	x0, 0xb0e6c
    b0db8:	bl	0x2ecd00 ; Objc message: -[x0 rootWindow]
    b0dc0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b0dc4:	cbz	x0, 0xb0e6c
    b0dd4:	bl	0x2ecd00 ; Objc message: -[x0 rootWindow]
    b0ddc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b0df8:	bl	0x2ecd00 ; Objc message: -[x0 respondsToSelector:]
    b0e04:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b0e0c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b0e10:	cbz	w25, 0xb0e6c
    b0e1c:	bl	0x2ecd00 ; Objc message: -[x0 respondsToSelector:]
    b0e24:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b0e30:	bl	0x2ecd00 ; Objc message: -[x0 respondsToSelector:]
    b0e48:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b0e50:	b.gt	0xb0ecc
    b0e58:	b.gt	0xb0ecc
    b0e60:	b.gt	0xb0ecc
    b0e68:	b.gt	0xb0ecc
    b0e80:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b0e88:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b0ec8:	b	0xb0e84
    b0ed8:	b	0xb0e7c
    b0eec:	bl	0x2ecb38 ; symbol stub for: _dispatch_once

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

## CBWindow.carPlayScreenBounds @ 0xb0704
Original ABI: \`{CGRect={CGPoint=dd}{CGSize=dd}}16@0:8\`
Function boundary: \`0xb0704..0xb0c98\`
Instruction count: **357**; branches **109**;
Potential numerical operations (not yet semantic proof):

    b0704:	sub	sp, sp, #0x60
    b071c:	add	x29, sp, #0x50
    b0724:	add	x8, x8, #0x580
    b072c:	mov	x8, #0x4059000000000000
    b0738:	mov	x8, #0x4059000000000000
    b075c:	cmn	x8, #0x1
    b0784:	mov	w3, #0x4
    b0788:	mov	x4, #0x0
    b07cc:	mov	x8, #0x4059000000000000
    b07d8:	mov	x8, #0x4059000000000000
    b086c:	mov	x8, #0x4059000000000000
    b087c:	mov	x8, #0x4059000000000000
    b0890:	add	x8, x8, #0x570
    b08ac:	add	x8, x8, #0x570
    b08f4:	mov	x8, #0x4059000000000000
    b0928:	add	x8, x8, #0x570
    b098c:	add	x0, x0, #0x24a ; literal pool for: "bounds"
    b09a4:	mov	x8, #0x4059000000000000
    b09b8:	mov	x8, #0x4059000000000000
    b09e4:	add	x0, x0, #0x139 ; literal pool for: "pointScale"
    b09f8:	fmov	d1, #1.00000000
    b0a28:	add	x8, x8, #0x570
    b0b44:	add	sp, sp, #0x60
    b0b50:	add	x0, x0, #0x5c8
    b0b58:	add	x1, x1, #0xf28
    b0b7c:	cmp	w1, #0x1
    b0ba0:	add	x0, x0, #0xe08 ; Objc cfstring ref: @"[CBWindow] Warning: Exception querying carPlayCADisplay bounds: %@"
    b0bc0:	cmp	w1, #0x1
    b0be4:	add	x0, x0, #0xde8 ; Objc cfstring ref: @"[CBWindow] Warning: Exception querying carPlayUIScreen bounds: %@"
    b0c04:	cmp	w1, #0x1
    b0c28:	add	x0, x0, #0xdc8 ; Objc cfstring ref: @"[CBWindow] Warning: Exception querying carPlayWindowScene bounds: %@"
    b0c48:	cmp	w1, #0x1
    b0c6c:	add	x0, x0, #0xda8 ; Objc cfstring ref: @"[CBWindow] Warning: Exception reading live screen bounds file: %@"

Branch samples:
    b0744:	b.gt	0xb08a8
    b0760:	b.ne	0xb0b4c
    b076c:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    b078c:	bl	0x2ecd00 ; Objc message: +[NSString stringWithContentsOfFile:encoding:error:]
    b0794:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b07a0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b07a4:	cbz	x20, 0xb07e8
    b07b4:	bl	0x2ecd00 ; Objc message: -[x0 length]
    b07b8:	cbz	x0, 0xb07e8
    b07c0:	bl	0x2ec910 ; symbol stub for: _CGSizeFromString
    b07e4:	b.gt	0xb0924
    b07ec:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b07fc:	bl	0x2ecd00 ; Objc message: -[x0 carPlayWindowScene]
    b0804:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b080c:	cbz	x0, 0xb08b8
    b0828:	bl	0x2ecd00 ; Objc message: -[x0 respondsToSelector:]
    b082c:	cbz	w0, 0xb08b8
    b0838:	bl	0x2ecd00 ; Objc message: -[x0 respondsToSelector:]
    b0840:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b0850:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    b0868:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b0878:	b.le	0xb08b8
    b0888:	b.le	0xb08b8
    b08a0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b08a4:	b	0xb0b20
    b08b4:	b	0xb0b20
    b08bc:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b08cc:	bl	0x2ecd00 ; Objc message: -[x0 carPlayUIScreen]
    b08d4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b08dc:	cbz	x0, 0xb0940
    b08f0:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    b0900:	b.le	0xb0940
    b090c:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    b091c:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    b0938:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b093c:	b	0xb0b18
    b0944:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b0954:	bl	0x2ecd00 ; Objc message: -[x0 carPlayCADisplay]
    b095c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b0964:	cbz	x0, 0xb0a3c

## CBWindow.carPlayUIScreen @ 0xafe60
Original ABI: \`@16@0:8\`
Function boundary: \`0xafe60..0xafffc\`
Instruction count: **103**; branches **23**;
Potential numerical operations (not yet semantic proof):

    afe60:	sub	sp, sp, #0x140
    afe7c:	add	x29, sp, #0x130
    afec4:	add	x2, sp, #0x10
    afec8:	add	x3, sp, #0x50
    afed0:	mov	w4, #0x10
    afeec:	mov	x20, #0x0
    afef8:	cmp	x0, #0x1
    aff70:	add	x20, x20, #0x1
    aff7c:	add	x2, sp, #0x10
    aff80:	add	x3, sp, #0x50
    aff8c:	mov	w4, #0x10
    affa0:	mov	x20, #0x0
    afff0:	add	sp, sp, #0x140

Branch samples:
    afeac:	bl	0x2ecd00 ; Objc message: +[UIScreen screens]
    afeb4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    afed4:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    afed8:	cbz	x0, 0xaffa0
    aff0c:	b.eq	0xaff18
    aff14:	bl	0x2eccb8 ; symbol stub for: _objc_enumerationMutation
    aff28:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    aff30:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aff3c:	b.eq	0xaff68
    aff50:	bl	0x2ecd00 ; Objc message: +[CBLicenseSyncManager countByEnumeratingWithState:objects:count:]
    aff5c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    aff60:	tbz	w25, #0x0, 0xaff70
    aff64:	b	0xaffa8
    aff6c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    aff78:	b.ne	0xaff00
    aff90:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    aff9c:	cbnz	x0, 0xafeec
    affa4:	b	0xaffb4
    affac:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    affb8:	bl	0x2ecd30 ; symbol stub for: _objc_release
    affd0:	b.ne	0xafff8
    afff4:	b	0x2ecc7c ; symbol stub for: _objc_autoreleaseReturnValue
    afff8:	bl	0x2eca9c ; symbol stub for: ___stack_chk_fail

## CBWindow.carPlayCADisplay @ 0xafffc
Original ABI: \`@16@0:8\`
Function boundary: \`0xafffc..0xb059c\`
Instruction count: **360**; branches **115**;
Potential numerical operations (not yet semantic proof):

    b0014:	add	x29, sp, #0x50
    b0018:	sub	sp, sp, #0x1f0
    b00d4:	add	x0, x0, #0xff ; literal pool for: "AVExternalDevice"
    b01b0:	mov	x2, #0x0
    b01ec:	add	x2, sp, #0xa0
    b01f0:	sub	x3, x29, #0xe0
    b01fc:	mov	w4, #0x10
    b0224:	mov	x28, #0x0
    b0240:	cmp	x0, #0x1
    b0308:	mov	x25, #0x0
    b0314:	add	x28, x28, #0x1
    b0320:	add	x2, sp, #0xa0
    b0324:	sub	x3, x29, #0xe0
    b0330:	mov	w4, #0x10
    b03a4:	add	x2, sp, #0x60
    b03a8:	add	x3, sp, #0xe0
    b03b0:	mov	w4, #0x10
    b03cc:	add	x22, x22, #0xf9b ; literal pool for: "screenType"
    b03d0:	mov	x28, #0x0
    b03e4:	cmp	x0, #0x1
    b0434:	cmp	w0, #0x2
    b043c:	add	x28, x28, #0x1
    b0448:	add	x2, sp, #0x60
    b044c:	add	x3, sp, #0xe0
    b0458:	mov	w4, #0x10
    b047c:	mov	x21, #0x0
    b04bc:	add	sp, sp, #0x1f0
    b054c:	cmp	w1, #0x1
    b0570:	add	x0, x0, #0xd68 ; Objc cfstring ref: @"[DuoFace] carPlayCADisplay exception: %@"

Branch samples:
    b0034:	bl	0x2ecd00 ; Objc message: -[x0 carPlayUIScreen]
    b003c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b0048:	cbz	x0, 0xb00d0
    b0064:	bl	0x2ecd00 ; Objc message: -[x0 displayConfiguration]
    b0068:	cbz	w0, 0xb00d0
    b0074:	bl	0x2ecd00 ; Objc message: -[x0 displayConfiguration]
    b007c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b0084:	cbz	x0, 0xb00c8
    b009c:	bl	0x2ecd00 ; Objc message: -[x0 CADisplay]
    b00a0:	cbz	w0, 0xb00c8
    b00ac:	bl	0x2ecd00 ; Objc message: -[x0 CADisplay]
    b00b4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b00bc:	cbnz	x0, 0xb0490
    b00c4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b00cc:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b00d8:	bl	0x2eccd0 ; symbol stub for: _objc_getClass
    b00ec:	cbz	x0, 0xb037c
    b0108:	bl	0x2ecd00 ; Objc message: -[x0 currentCarPlayExternalDevice]
    b010c:	cbz	w0, 0xb037c
    b0118:	bl	0x2ecd00 ; Objc message: -[x0 currentCarPlayExternalDevice]
    b0120:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b0128:	cbz	x0, 0xb0374
    b0140:	bl	0x2ecd00 ; Objc message: -[x0 screenIDs]
    b0144:	cbz	w0, 0xb0374
    b0150:	bl	0x2ecd00 ; Objc message: -[x0 screenIDs]
    b0158:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b0160:	cbz	x0, 0xb036c
    b0174:	bl	0x2ecd00 ; Objc message: +[NSArray class]
    b0188:	bl	0x2ecd00 ; Objc message: -[x0 isKindOfClass:]
    b018c:	cbz	w0, 0xb036c
    b019c:	bl	0x2ecd00 ; Objc message: -[x0 count]
    b01a0:	cbz	x0, 0xb036c
    b01b4:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    b01c0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b01dc:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    b01e4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b0200:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    b0204:	cbz	x0, 0xb034c
    b0258:	b.eq	0xb0264
    b0260:	bl	0x2eccb8 ; symbol stub for: _objc_enumerationMutation

## CBWindow.getCarPlayDisplay @ 0xb0ff0
Original ABI: \`@16@0:8\`
Function boundary: \`0xb0ff0..0xb1064\`
Instruction count: **29**; branches **9**;
Potential numerical operations (not yet semantic proof):

    b0ff8:	add	x29, sp, #0x10

Branch samples:
    b100c:	bl	0x2ecd00 ; Objc message: +[CBWindow carPlayCADisplay]
    b1014:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b101c:	cbz	x0, 0xb102c
    b1024:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    b1028:	b	0xb1048
    b103c:	bl	0x2ecd00 ; Objc message: +[CADisplay mainDisplay]
    b1044:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b1050:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b1060:	b	0x2ecc7c ; symbol stub for: _objc_autoreleaseReturnValue

## CBWindow.resetCachedBounds @ 0xaf570
Original ABI: \`v16@0:8\`
Function boundary: \`0xaf570..0xaf690\`
Instruction count: **72**; branches **14**;
Potential numerical operations (not yet semantic proof):

    af57c:	add	x29, sp, #0x20
    af58c:	add	x9, x9, #0x570
    af5a4:	add	x9, x9, #0x590
    af5dc:	cmn	x8, #0x1
    af5fc:	mov	x3, #0x0
    af62c:	cmn	x8, #0x1
    af644:	mov	x3, #0x0
    af664:	add	x0, x0, #0x5b8
    af66c:	add	x1, x1, #0xf08
    af67c:	add	x0, x0, #0x5c8
    af684:	add	x1, x1, #0xf28

Branch samples:
    af5c4:	bl	0x2ecd00 ; Objc message: +[NSFileManager defaultManager]
    af5cc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    af5e0:	b.ne	0xaf660
    af600:	bl	0x2ecd00 ; Objc message: -[x0 removeItemAtPath:error:]
    af608:	bl	0x2ecd30 ; symbol stub for: _objc_release
    af614:	bl	0x2ecd00 ; Objc message: -[x0 removeItemAtPath:error:]
    af61c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    af630:	b.ne	0xaf678
    af648:	bl	0x2ecd00 ; Objc message: -[x0 removeItemAtPath:error:]
    af65c:	b	0x2ecd30 ; symbol stub for: _objc_release
    af670:	bl	0x2ecb38 ; symbol stub for: _dispatch_once
    af674:	b	0xaf5e4
    af688:	bl	0x2ecb38 ; symbol stub for: _dispatch_once
    af68c:	b	0xaf634

## CBWindow.initWithAppFrame: @ 0xaf4bc
Original ABI: \`@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16\`
Function boundary: \`0xaf4bc..0xaf554\`
Instruction count: **38**; branches **4**;
Potential numerical operations (not yet semantic proof):

    af4bc:	sub	sp, sp, #0x50
    af4d0:	add	x29, sp, #0x40
    af54c:	add	sp, sp, #0x50

Branch samples:
    af4fc:	bl	0x2ecd18 ; Objc message: -[[x0 super] init]
    af504:	cbz	x0, 0xaf538
    af524:	bl	0x2ecd00 ; Objc message: -[x0 createWindows]
    af534:	bl	0x2ecd00 ; Objc message: -[x0 resizeWindows]

## CBWindow.createWindows @ 0xb1064
Original ABI: \`v16@0:8\`
Function boundary: \`0xb1064..0xb1974\`
Instruction count: **580**; branches **175**;
Potential numerical operations (not yet semantic proof):

    b1064:	sub	sp, sp, #0xe0
    b1090:	add	x29, sp, #0xd0
    b10d4:	cmp	x26, #0x0
    b1128:	mov	x20, #0x0
    b114c:	add	x0, x21, #0x8
    b1194:	mov	x23, #0x0
    b1264:	mov	x23, #0x0
    b126c:	mov	x23, #0x0
    b128c:	add	x0, x0, #0x2de ; literal pool for: "FBSDisplayConfiguration"
    b1294:	mov	x23, #0x0
    b12b4:	mov	w3, #0x0
    b12c0:	add	x0, x21, #0x10
    b12d0:	add	x0, x0, #0x2f6 ; literal pool for: "UIRootSceneWindow"
    b12e8:	add	x0, x0, #0x308 ; literal pool for: "SBFTouchPassThroughWindow"
    b12fc:	add	x0, x0, #0x322 ; literal pool for: "UIWindow"
    b1310:	add	x0, x0, #0x443 ; literal pool for: "CBTouchPassThroughRootSceneWindow"
    b1324:	add	x1, x1, #0x443 ; literal pool for: "CBTouchPassThroughRootSceneWindow"
    b132c:	mov	x2, #0x0
    b136c:	add	x3, x3, #0x465 ; literal pool for: "@@:{CGPoint=dd}@"
    b13ac:	add	x3, x3, #0x476 ; literal pool for: "B@:{CGPoint=dd}@"
    b13ec:	add	x3, x3, #0x487 ; literal pool for: "v@:@"
    b14d4:	mov	x24, #0x0
    b15ec:	add	x0, x0, #0x568
    b1628:	mov	w2, #0x1
    b1740:	mov	w2, #0x12
    b1774:	mov	x2, #0x0
    b17e0:	mov	w2, #0x12
    b17f4:	mov	w2, #0x1
    b1820:	mov	w2, #0x0
    b18b4:	add	x0, x0, #0xe48 ; Objc cfstring ref: @"[DuoFaceWindow] createWindows completed: _rootWindow=%@, rootVC=%@, screenBounds=%@, usableBounds=%@, config=%@"
    b1910:	add	sp, sp, #0xe0
    b1920:	cmp	w1, #0x1
    b1944:	add	x0, x0, #0xe28 ; Objc cfstring ref: @"[CBWindow] Warning: Exception resolving FBSScene displayConfiguration: %@"

Branch samples:
    b10a8:	bl	0x2ecd00 ; Objc message: +[CBWindow carPlayWindowScene]
    b10b0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b10c4:	bl	0x2ecd00 ; Objc message: -[x0 carPlayUIScreen]
    b10cc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b10e0:	b.ne	0xb112c
    b10f8:	bl	0x2ecd00 ; Objc message: -[x0 screen]
    b10fc:	cbz	w0, 0xb1128
    b1108:	bl	0x2ecd00 ; Objc message: -[x0 screen]
    b1110:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b111c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b1124:	b	0xb112c
    b1138:	bl	0x2ecd00 ; Objc message: -[x0 carPlayCADisplay]
    b1144:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b1154:	bl	0x2ecd90 ; symbol stub for: _objc_storeStrong
    b1158:	cbz	x20, 0xb1194
    b1170:	bl	0x2ecd00 ; Objc message: -[x0 displayConfiguration]
    b1174:	cbz	w0, 0xb1194
    b1180:	bl	0x2ecd00 ; Objc message: -[x0 displayConfiguration]
    b1188:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b1190:	b	0xb1198
    b119c:	cbz	x26, 0xb1284
    b11a0:	cbnz	x23, 0xb1284
    b11bc:	bl	0x2ecd00 ; Objc message: -[x0 _FBSScene]
    b11c0:	cbz	w0, 0xb1288
    b11d8:	bl	0x2ecd00 ; Objc message: -[x0 performSelector:]
    b11e0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b11e8:	cbz	x0, 0xb1264
    b1200:	bl	0x2ecd00 ; Objc message: -[x0 settings]
    b1204:	cbz	w0, 0xb1264
    b1214:	bl	0x2ecd00 ; Objc message: -[x0 settings]
    b121c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b1224:	cbz	x0, 0xb126c
    b123c:	bl	0x2ecd00 ; Objc message: -[x0 displayConfiguration]
    b1240:	cbz	w0, 0xb126c
    b1250:	bl	0x2ecd00 ; Objc message: -[x0 displayConfiguration]
    b1258:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b1260:	b	0xb1270
    b1268:	b	0xb1278
    b1274:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b127c:	bl	0x2ecd30 ; symbol stub for: _objc_release

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

