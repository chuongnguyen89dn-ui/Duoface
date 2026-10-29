# Original Native12: layout and preset ARM64 IMP evidence

- Verified original DEB SHA256: \`2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad\`
- Verified Dashboard SHA256: \`9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea\`
- Original method index blob: \`efa45df59bc3c16887cc979bf3aedc0c93c92111\`
- Exact extracted IMPs: **6**, ARM64 instructions: **27975**
- IMPORTANT: machine disassembly is NOT a runtime preset-frame test.
- A selector in an Objective-C call site does NOT prove a receiver.
- Preset 0..7 formulas in independent DFLayoutEngine remain UNVERIFIED until
  original function control flow and numerical CGRect outputs are derived.
- This artifact contains read-only evidence; no vendor code linked to app.

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

## CBBridgedSplitApp.initWithBundleIdentifier:frame:showSplash: @ 0x1025e4
Original ABI: \`@60@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24B56\`
Function boundary: \`0x1025e4..0x1038ac\`
Instruction count: **1202**; branches **280**;
Potential numerical operations (not yet semantic proof):

    10260c:	add	x29, sp, #0x90
    102610:	sub	sp, sp, #0x370
    10265c:	sub	x0, x29, #0xd0
    1026d0:	cmp	x0, #0x8
    1026f8:	cmp	x0, #0x0
    102744:	fmov	d1, #0.50000000
    102758:	mov	x9, #-0x1
    1028ac:	mov	w2, #0x12
    1028c4:	mov	w2, #0x1
    1028f4:	fmov	d3, #1.00000000
    10294c:	sub	x0, x29, #0xd8
    10296c:	fcmp	d9, #0.0
    102974:	fcmp	d8, #0.0
    10299c:	mov	w24, #0x0
    1029c4:	mov	w24, #0x1
    102a10:	mov	w24, #0x0
    102a38:	mov	w24, #0x1
    102af0:	sub	x2, x29, #0xc0
    102af4:	mov	w3, #0x4
    102b50:	fmov	d4, #2.00000000
    102b70:	mov	x19, #0x0
    102bb8:	add	x8, sp, #0x2f8
    102bc4:	add	x22, x8, #0x20
    102bd0:	add	x9, sp, #0x2d0
    102bd4:	add	x26, x9, #0x20
    102c9c:	mov	w2, #0x1
    102d08:	add	x8, x8, #0x98
    102d10:	sub	x1, x29, #0xd8
    102d20:	add	x2, sp, #0x2f8
    102d48:	add	x8, x8, #0xf98
    102d50:	sub	x1, x29, #0xd8
    102d5c:	add	x2, sp, #0x2d0
    102d88:	add	x19, x19, #0x1
    102db4:	cmp	x0, #0x2
    102dc0:	mov	w13, #0x1
    102dc4:	mov	x24, #0x0
    102ea4:	add	x17, sp, #0x250
    102ea8:	add	x17, x17, #0x20
    102ef0:	add	x17, sp, #0x228
    102ef4:	add	x17, x17, #0x20

Branch samples:
    102640:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    102674:	bl	0x2ecd18 ; Objc message: -[[x0 super] initWithBundleIdentifier:frame:]
    10267c:	cbz	x0, 0x103788
    102690:	bl	0x2ecd00 ; Objc message: +[CBDashboardSettings sharedInstance]
    102698:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    1026a8:	bl	0x2ecd00 ; Objc message: -[x0 reload]
    1026bc:	bl	0x2ecd00 ; Objc message: -[x0 splitPreset]
    1026c0:	tbnz	x0, #0x3f, 0x1026e8
    1026cc:	bl	0x2ecd00 ; Objc message: -[x0 splitPreset]
    1026d4:	b.gt	0x1026e8
    1026e0:	bl	0x2ecd00 ; Objc message: -[x0 splitPreset]
    1026e4:	b	0x102700
    1026f4:	bl	0x2ecd00 ; Objc message: -[x0 splitMode]
    102720:	bl	0x2ecd00 ; Objc message: -[x0 splitRatio]
    102774:	bl	0x2ecd00 ; Objc message: +[NSMutableArray array]
    10277c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    102798:	bl	0x2ecd30 ; symbol stub for: _objc_release
    1027a4:	bl	0x2ecd00 ; Objc message: -[x0 array]
    1027ac:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    1027c8:	bl	0x2ecd30 ; symbol stub for: _objc_release
    1027d4:	bl	0x2ecd00 ; Objc message: -[x0 array]
    1027dc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    1027f8:	bl	0x2ecd30 ; symbol stub for: _objc_release
    102804:	bl	0x2ecd00 ; Objc message: -[x0 array]
    10280c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    102828:	bl	0x2ecd30 ; symbol stub for: _objc_release
    102834:	bl	0x2ecd00 ; Objc message: -[x0 array]
    10283c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    102858:	bl	0x2ecd30 ; symbol stub for: _objc_release
    102864:	bl	0x2ecc34 ; symbol stub for: _objc_alloc
    102884:	bl	0x2ecd00 ; Objc message: +[CBSplitContainerView initWithFrame:]
    102898:	bl	0x2ecd00 ; Objc message: -[x0 setSplitApp:]
    1028b0:	bl	0x2ecd00 ; Objc message: -[x0 setAutoresizingMask:]
    1028c8:	bl	0x2ecd00 ; Objc message: -[x0 setClipsToBounds:]
    102904:	bl	0x2ecd00 ; Objc message: +[UIColor colorWithRed:green:blue:alpha:]
    10290c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    102928:	bl	0x2ecd00 ; Objc message: -[x0 setBackgroundColor:]
    102930:	bl	0x2ecd30 ; symbol stub for: _objc_release
    102948:	bl	0x2ecd00 ; Objc message: -[x0 setView:]
    102954:	bl	0x2ecce8 ; symbol stub for: _objc_initWeak

## CBBridgedSplitApp.startInParentViewController: @ 0x10bb1c
Original ABI: \`v24@0:8@16\`
Function boundary: \`0x10bb1c..0x10beec\`
Instruction count: **244**; branches **67**;
Potential numerical operations (not yet semantic proof):

    10bb1c:	sub	sp, sp, #0x160
    10bb3c:	add	x29, sp, #0x150
    10bc08:	add	x2, sp, #0x20
    10bc0c:	add	x3, sp, #0x60
    10bc14:	mov	w4, #0x10
    10bc2c:	mov	x27, #0x0
    10bcc0:	fcmp	d2, #0.0
    10bce8:	fcmp	d8, #0.0
    10bd10:	add	x27, x27, #0x1
    10bd1c:	add	x2, sp, #0x20
    10bd20:	add	x3, sp, #0x60
    10bd2c:	mov	w4, #0x10
    10be4c:	mov	w2, #0x1
    10bee0:	add	sp, sp, #0x160

Branch samples:
    10bb58:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    10bb74:	bl	0x2ecd00 ; Objc message: -[x0 count]
    10bb78:	cbz	x0, 0x10be24
    10bb7c:	cbnz	x23, 0x10bbe0
    10bb90:	bl	0x2ecd00 ; Objc message: +[CBBridgeManager sharedInstanceIfExists]
    10bb98:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    10bba8:	bl	0x2ecd00 ; Objc message: -[x0 window]
    10bbb0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    10bbc0:	bl	0x2ecd00 ; Objc message: -[x0 rootViewController]
    10bbc8:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    10bbd4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    10bbdc:	bl	0x2ecd30 ; symbol stub for: _objc_release
    10bbf8:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    10bc18:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    10bc1c:	cbz	x0, 0x10bd3c
    10bc60:	b.eq	0x10bc6c
    10bc68:	bl	0x2eccb8 ; symbol stub for: _objc_enumerationMutation
    10bc7c:	bl	0x2ecd00 ; Objc message: -[x0 frame]
    10bc84:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    10bc8c:	cbz	x0, 0x10bd08
    10bc98:	bl	0x2ecd00 ; Objc message: -[x0 frame]
    10bca0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    10bcac:	bl	0x2ecd00 ; Objc message: -[x0 frame]
    10bcb0:	cbz	x0, 0x10bd00
    10bcbc:	bl	0x2ecd00 ; Objc message: -[x0 frame]
    10bcc4:	b.le	0x10bd00
    10bcd0:	bl	0x2ecd00 ; Objc message: -[x0 frame]
    10bcdc:	bl	0x2ecd30 ; symbol stub for: _objc_release
    10bce4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    10bcec:	b.le	0x10bd10
    10bcf8:	bl	0x2ecd00 ; Objc message: -[x0 frame]
    10bcfc:	b	0x10bd10
    10bd04:	bl	0x2ecd30 ; symbol stub for: _objc_release
    10bd0c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    10bd18:	b.lo	0x10bc54
    10bd30:	bl	0x2ecd00 ; Objc message: -[x0 frame]
    10bd38:	cbnz	x0, 0x10bc2c
    10bd40:	bl	0x2ecd30 ; symbol stub for: _objc_release
    10bd54:	bl	0x2ecd00 ; Objc message: -[x0 layoutSplitViews]
    10bd64:	cbz	x8, 0x10be90

## CBBridgedUIAppView.startInParentViewController: @ 0xadf30
Original ABI: \`v24@0:8@16\`
Function boundary: \`0xadf30..0xaefb0\`
Instruction count: **1056**; branches **299**;
Potential numerical operations (not yet semantic proof):

    adf4c:	add	x29, sp, #0x60
    adf50:	sub	sp, sp, #0x1d0
    adfa8:	mov	w2, #0x1
    ae018:	add	x0, x0, #0xfbf ; literal pool for: "SBApplicationController"
    ae028:	add	x0, x0, #0xfd7 ; literal pool for: "SBDeviceApplicationSceneEntity"
    ae038:	add	x0, x0, #0xff6 ; literal pool for: "SBAppViewController"
    ae0fc:	add	x0, x0, #0xa ; literal pool for: "initWithApplication:generatingNewSceneIfRequired:"
    ae128:	add	x0, x0, #0xa ; literal pool for: "initWithApplication:generatingNewSceneIfRequired:"
    ae13c:	mov	w3, #0x1
    ae150:	add	x0, x0, #0x3c ; literal pool for: "initWithApplication:"
    ae17c:	add	x0, x0, #0x3c ; literal pool for: "initWithApplication:"
    ae228:	add	x0, x0, #0x51 ; literal pool for: "initWithApplicationSceneEntity:"
    ae254:	add	x0, x0, #0x51 ; literal pool for: "initWithApplicationSceneEntity:"
    ae2d0:	mov	w2, #0x1
    ae2e8:	add	x1, x1, #0xe8b ; literal pool for: "CBDuoFaceHosted"
    ae2f4:	mov	w3, #0x1
    ae310:	mov	w2, #0x1
    ae328:	add	x1, x1, #0xe9b ; literal pool for: "CBCarBridgeHosted"
    ae334:	mov	w3, #0x1
    ae384:	add	x1, x1, #0xead ; literal pool for: "CBDuoFaceBundleID"
    ae390:	mov	w3, #0x3
    ae3c0:	add	x1, x1, #0xebf ; literal pool for: "CBCarBridgeBundleID"
    ae3cc:	mov	w3, #0x3
    ae44c:	mov	w2, #0x1
    ae478:	mov	w2, #0x0
    ae4a4:	fcmp	d0, #0.0
    ae4b0:	fcmp	d1, #0.0
    ae534:	mov	w2, #0x2
    ae544:	mov	x0, #0x0
    ae548:	mov	w1, #0x0
    ae554:	add	x1, x1, #0x8f5 ; literal pool for: "BKSDisplayServicesSetScreenBlanked"
    ae564:	mov	w0, #0x0
    ae5f4:	mov	w2, #0x0
    ae628:	add	x2, sp, #0xc0
    ae65c:	mov	w2, #0x12
    ae6a8:	add	x1, x1, #0xd57 ; literal pool for: "_deviceAppViewController"
    ae6e8:	mov	w2, #0x1
    ae700:	add	x1, x1, #0xe8b ; literal pool for: "CBDuoFaceHosted"
    ae70c:	mov	w3, #0x1
    ae724:	mov	w2, #0x1

Branch samples:
    adf6c:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    adf80:	bl	0x2ecd00 ; Objc message: -[x0 invalidated]
    adf84:	tbnz	w0, #0x0, 0xaeef4
    adf94:	bl	0x2ecd00 ; Objc message: -[x0 hosting]
    adf98:	tbnz	w0, #0x0, 0xaeef4
    adfac:	bl	0x2ecd00 ; Objc message: -[x0 setHosting:]
    adfb0:	cbnz	x19, 0xae014
    adfc4:	bl	0x2ecd00 ; Objc message: +[CBBridgeManager sharedInstanceIfExists]
    adfcc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    adfdc:	bl	0x2ecd00 ; Objc message: -[x0 window]
    adfe4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    adff4:	bl	0x2ecd00 ; Objc message: -[x0 rootViewController]
    adffc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ae008:	bl	0x2ecd30 ; symbol stub for: _objc_release
    ae010:	bl	0x2ecd30 ; symbol stub for: _objc_release
    ae01c:	bl	0x2eccd0 ; symbol stub for: _objc_getClass
    ae02c:	bl	0x2eccd0 ; symbol stub for: _objc_getClass
    ae03c:	bl	0x2eccd0 ; symbol stub for: _objc_getClass
    ae040:	cbz	x21, 0xaeef4
    ae044:	cbz	x26, 0xaeef4
    ae04c:	cbz	x0, 0xaeef4
    ae05c:	bl	0x2ecd00 ; Objc message: -[x0 sharedInstance]
    ae064:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ae07c:	bl	0x2ecd00 ; Objc message: -[x0 bundleIdentifier]
    ae084:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ae09c:	bl	0x2ecd00 ; Objc message: -[x0 applicationWithBundleIdentifier:]
    ae0a4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ae0b0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    ae0b4:	cbz	x28, 0xaeee4
    ae0d4:	bl	0x2ecd00 ; Objc message: -[x0 initWithApplicationForMainDisplay:]
    ae0d8:	cbz	w0, 0xae0f8
    ae0e0:	bl	0x2ecc34 ; symbol stub for: _objc_alloc
    ae0ec:	bl	0x2ecd00 ; Objc message: -[x0 initWithApplicationForMainDisplay:]
    ae0f4:	b	0xae1a8
    ae100:	bl	0x2ecdfc ; symbol stub for: _sel_registerName
    ae110:	bl	0x2ecd00 ; Objc message: -[x0 initWithApplicationForMainDisplay:]
    ae114:	cbz	w0, 0xae14c
    ae11c:	bl	0x2ecc34 ; symbol stub for: _objc_alloc
    ae12c:	bl	0x2ecdfc ; symbol stub for: _sel_registerName
    ae140:	bl	0x2ecd00 ; Objc message: -[x0 initWithApplicationForMainDisplay:]

## CBBridgeManager.loadNewAppFromCurrentRequest: @ 0x153544
Original ABI: \`v24@0:8@16\`
Function boundary: \`0x153544..0x16b9a0\`
Instruction count: **24855**; branches **1906**;
Potential numerical operations (not yet semantic proof):

    15355c:	add	x29, sp, #0x50
    153560:	sub	sp, sp, #0x1, lsl #12
    153564:	sub	sp, sp, #0x810
    1535dc:	add	x22, sp, #0x9e0
    1535e0:	add	x23, sp, #0x160
    1535e8:	mov	x19, #0x1
    1535ec:	movk	x19, #0x15, lsl #32
    1535f0:	mov	x0, #0x0
    1535fc:	mov	w8, #0x10
    153608:	add	x0, sp, #0x158
    15360c:	add	x2, sp, #0x970
    153610:	add	x3, sp, #0x130
    153614:	mov	w1, #0x2
    153618:	mov	x4, #0x0
    15361c:	mov	x5, #0x0
    153628:	cmp	x8, #0x0
    153638:	add	x12, x12, #0xcb0
    15365c:	add	x21, x21, #0x6c0
    153678:	mov	w9, #0x5a
    15367c:	add	x10, sp, #0x160
    153684:	add	x11, x11, #0xff0
    153688:	lsl	w12, w8, #3
    153690:	add	w12, w12, #0x33
    1536a0:	lsl	w14, w14, #1
    1536ac:	add	w13, w8, w8, lsl #1
    1536b0:	add	w13, w13, #0x17
    1536bc:	add	x8, x8, #0x1
    1536c0:	cmp	x8, #0x35
    1536d0:	add	x1, x1, #0x7d9 ; literal pool for: "rb"
    1536d4:	add	x0, sp, #0x160
    1536f4:	add	x0, sp, #0x8e0
    1536f8:	mov	w1, #0x28
    1536fc:	mov	w2, #0x1
    153708:	cmp	x0, #0x1
    153710:	mov	w26, #0xae85
    153714:	movk	w26, #0xbb67, lsl #16
    153718:	mov	w19, #0xf53a
    15371c:	movk	w19, #0xa54f, lsl #16
    153720:	mov	w6, #0x688c
    153724:	movk	w6, #0x9b05, lsl #16

Branch samples:
    153580:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    153590:	bl	0x2ecd00 ; Objc message: -[x0 bundleIdentifier]
    153598:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    1535a8:	bl	0x2ecd00 ; Objc message: -[x0 copy]
    1535b4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    1535b8:	cbz	x26, 0x159450
    1535cc:	bl	0x2ecd00 ; Objc message: -[x0 length]
    1535d0:	cbz	x0, 0x159450
    1535f4:	bl	0x2ece98 ; symbol stub for: _time
    153620:	bl	0x2ece80 ; symbol stub for: _sysctl
    153644:	blr	x13
    153654:	cbnz	x8, 0x153dc4
    153664:	cbz	x8, 0x153678
    15366c:	blr	x13
    153674:	b	0x153dc4
    1536c4:	b.ne	0x153688
    1536d8:	bl	0x2ecb80 ; symbol stub for: _fopen
    1536ec:	cbz	x0, 0x153ab4
    153704:	bl	0x2ecb8c ; symbol stub for: _fread
    15370c:	b.ne	0x153ac0
    15376c:	cbz	w8, 0x162028
    153830:	b.ne	0x15381c
    15388c:	b.ne	0x153848
    15396c:	b.ne	0x1538e4
    153a48:	b.ne	0x153a34
    153a80:	b.ne	0x153a68
    153ab0:	b	0x153ac8
    153abc:	b	0x153ad0
    153acc:	bl	0x2ecb74 ; symbol stub for: _fclose
    153b20:	b.ne	0x153ae4
    153b7c:	b.ne	0x153b40
    153b9c:	bl	0x2ecd00 ; Objc message: +[NSString stringWithUTF8String:]
    153ba4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    153bbc:	bl	0x2ecd00 ; Objc message: -[x0 stringWithUTF8String:]
    153bc4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    153c64:	bl	0x2ecd00 ; Objc message: +[NSNumber numberWithBool:]
    153c6c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    153cb4:	bl	0x2ecd00 ; Objc message: +[NSDictionary dictionaryWithObjects:forKeys:count:]
    153cbc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    153cc8:	bl	0x2ecd30 ; symbol stub for: _objc_release

