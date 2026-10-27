# Original Native12: layout and preset ARM64 IMP evidence

- Verified original DEB SHA256: \`2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad\`
- Verified Dashboard SHA256: \`9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea\`
- Original method index blob: \`efa45df59bc3c16887cc979bf3aedc0c93c92111\`
- Exact extracted IMPs: **9**, ARM64 instructions: **1318**
- IMPORTANT: machine disassembly is NOT a runtime preset-frame test.
- A selector in an Objective-C call site does NOT prove a receiver.
- Preset 0..7 formulas in independent DFLayoutEngine remain UNVERIFIED until
  original function control flow and numerical CGRect outputs are derived.
- This artifact contains read-only evidence; no vendor code linked to app.

## CBBridgedUIAppView.initWithBundleIdentifier: @ 0xac6f4
Original ABI: \`@24@0:8@16\`
Function boundary: \`0xac6f4..0xac704\`
Instruction count: **4**; branches **1**;
Potential numerical operations (not yet semantic proof):

    ac6fc:	fmov	d0, #0.50000000

Branch samples:
    ac700:	b	0x2ecd00 ; Objc message: -[x0 initWithBundleIdentifier:scale:]

## CBBridgedUIAppView.initWithBundleIdentifier:scale: @ 0xac704
Original ABI: \`@32@0:8@16d24\`
Function boundary: \`0xac704..0xac83c\`
Instruction count: **78**; branches **12**;
Potential numerical operations (not yet semantic proof):

    ac704:	sub	sp, sp, #0x40
    ac714:	add	x29, sp, #0x30
    ac78c:	mov	x9, #0x3fe0000000000000
    ac800:	mov	w2, #0x1
    ac814:	mov	w2, #0x12
    ac834:	add	sp, sp, #0x40

Branch samples:
    ac720:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    ac750:	bl	0x2ecd18 ; Objc message: -[[x0 super] initWithFrame:]
    ac758:	cbz	x0, 0xac81c
    ac768:	bl	0x2ecd00 ; Objc message: -[x0 copy]
    ac780:	bl	0x2ecd30 ; symbol stub for: _objc_release
    ac7c8:	bl	0x2ecd00 ; Objc message: +[UIColor blackColor]
    ac7d0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ac7e8:	bl	0x2ecd00 ; Objc message: -[x0 setBackgroundColor:]
    ac7f0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    ac804:	bl	0x2ecd00 ; Objc message: -[x0 setClipsToBounds:]
    ac818:	bl	0x2ecd00 ; Objc message: -[x0 setAutoresizingMask:]
    ac820:	bl	0x2ecd30 ; symbol stub for: _objc_release

## CBBridgedUIAppView.start @ 0xaf00c
Original ABI: \`v16@0:8\`
Function boundary: \`0xaf00c..0xaf01c\`
Instruction count: **4**; branches **1**;
Potential numerical operations (not yet semantic proof):

    af014:	mov	x2, #0x0

Branch samples:
    af018:	b	0x2ecd00 ; Objc message: -[x0 startInParentViewController:]

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

## CBBridgedUIAppView.setHosting: @ 0xaf2a8
Original ABI: \`v20@0:8B16\`
Function boundary: \`0xaf2a8..0xaf2b8\`
Instruction count: **4**; branches **0**;
Potential numerical operations (not yet semantic proof):


Branch samples:

## CBBridgedUIAppView.setInvalidated: @ 0xaf2c8
Original ABI: \`v20@0:8B16\`
Function boundary: \`0xaf2c8..0xaf2d8\`
Instruction count: **4**; branches **0**;
Potential numerical operations (not yet semantic proof):


Branch samples:

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

## CBBridgedUIAppView.dealloc @ 0xaf1d8
Original ABI: \`v16@0:8\`
Function boundary: \`0xaf1d8..0xaf224\`
Instruction count: **19**; branches **2**;
Potential numerical operations (not yet semantic proof):

    af1d8:	sub	sp, sp, #0x30
    af1e4:	add	x29, sp, #0x20
    af21c:	add	sp, sp, #0x30

Branch samples:
    af1f4:	bl	0x2ecd00 ; Objc message: -[x0 dismiss]
    af210:	bl	0x2ecd18 ; Objc message: -[[x0 super] dealloc]

