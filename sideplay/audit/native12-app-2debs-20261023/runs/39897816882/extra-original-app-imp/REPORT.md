# Original Native12: layout and preset ARM64 IMP evidence

- Verified original DEB SHA256: \`2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad\`
- Verified Dashboard SHA256: \`9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea\`
- Original method index blob: \`efa45df59bc3c16887cc979bf3aedc0c93c92111\`
- Exact extracted IMPs: **6**, ARM64 instructions: **4427**
- IMPORTANT: machine disassembly is NOT a runtime preset-frame test.
- A selector in an Objective-C call site does NOT prove a receiver.
- Preset 0..7 formulas in independent DFLayoutEngine remain UNVERIFIED until
  original function control flow and numerical CGRect outputs are derived.
- This artifact contains read-only evidence; no vendor code linked to app.

## CBMultitaskingOverlayView.initWithFrame: @ 0xa0420
Original ABI: \`@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16\`
Function boundary: \`0xa0420..0xa0aec\`
Instruction count: **435**; branches **105**;
Potential numerical operations (not yet semantic proof):

    a0420:	sub	sp, sp, #0xc0
    a0440:	add	x29, sp, #0xb0
    a0468:	add	x0, sp, #0x18
    a04d4:	mov	w2, #0x12
    a04e8:	add	x8, x8, #0x288 ; Objc cfstring ref: @""
    a0504:	add	x2, sp, #0x28
    a0508:	mov	w3, #0x4
    a0578:	mov	w9, #0x1
    a0588:	mov	x9, #0x3fe0000000000000
    a0624:	mov	w2, #0x12
    a079c:	fmov	d0, #26.00000000
    a07cc:	fmov	d1, #10.00000000
    a0804:	mov	w2, #0x0
    a0834:	mov	w2, #0x12
    a089c:	fmov	d0, #20.00000000
    a0904:	mov	w2, #0x1
    a0934:	fmov	d8, #1.00000000
    a0a88:	mov	x5, #0x0
    a0ae0:	add	sp, sp, #0xc0

Branch samples:
    a0470:	bl	0x2ecd18 ; Objc message: -[[x0 super] initWithFrame:]
    a0478:	cbz	x0, 0xa0aa8
    a0494:	bl	0x2ecd00 ; Objc message: +[UIColor clearColor]
    a049c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a04b8:	bl	0x2ecd00 ; Objc message: -[x0 setBackgroundColor:]
    a04c0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a04d8:	bl	0x2ecd00 ; Objc message: -[x0 setAutoresizingMask:]
    a050c:	bl	0x2ecd00 ; Objc message: +[NSArray arrayWithObjects:count:]
    a0514:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a052c:	bl	0x2ecd00 ; Objc message: -[x0 arrayWithArray:]
    a0534:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a054c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a0554:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a0598:	bl	0x2ecc34 ; symbol stub for: _objc_alloc
    a05ac:	bl	0x2ecd00 ; Objc message: +[UIView bounds]
    a05b8:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    a05d0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a05f0:	bl	0x2ecd00 ; Objc message: -[x0 colorWithWhite:alpha:]
    a05f8:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a0610:	bl	0x2ecd00 ; Objc message: -[x0 colorWithWhite:alpha:]
    a0618:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a0628:	bl	0x2ecd00 ; Objc message: -[x0 colorWithWhite:alpha:]
    a0634:	bl	0x2ecc34 ; symbol stub for: _objc_alloc
    a064c:	bl	0x2ecd00 ; Objc message: +[UITapGestureRecognizer dismissOverlay]
    a0664:	bl	0x2ecd00 ; Objc message: -[x0 addGestureRecognizer:]
    a0680:	bl	0x2ecd00 ; Objc message: -[x0 addSubview:]
    a0688:	bl	0x2ecc40 ; symbol stub for: _objc_alloc_init
    a06a0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a06ac:	bl	0x2ecd00 ; Objc message: -[x0 addSubview:]
    a06b4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a06c8:	bl	0x2ecd00 ; Objc message: -[x0 addSubview:]
    a06d0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a06e0:	bl	0x2ecd00 ; Objc message: -[x0 blackColor]
    a06e8:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a06ec:	bl	0x2ecd48 ; symbol stub for: _objc_retainAutorelease
    a0700:	bl	0x2ecd00 ; Objc message: -[x0 CGColor]
    a0718:	bl	0x2ecd00 ; Objc message: -[x0 layer]
    a0720:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a0734:	bl	0x2ecd00 ; Objc message: -[x0 setShadowColor:]
    a073c:	bl	0x2ecd30 ; symbol stub for: _objc_release

## CBMultitaskingOverlayView.loadInstalledApps @ 0xa0c48
Original ABI: \`v16@0:8\`
Function boundary: \`0xa0c48..0xa1594\`
Instruction count: **595**; branches **143**;
Potential numerical operations (not yet semantic proof):

    a0c64:	add	x29, sp, #0x60
    a0c68:	sub	sp, sp, #0x2d0
    a0d10:	add	x0, x0, #0x50e ; literal pool for: "LSApplicationWorkspace"
    a0df8:	add	x2, sp, #0x100
    a0dfc:	sub	x3, x29, #0xf0
    a0e08:	mov	w4, #0x10
    a0e20:	fmov	d8, #2.00000000
    a0e28:	mov	x28, #0x0
    a0f28:	mov	x1, #0x0
    a0fa8:	mov	x19, #0x0
    a0fb0:	mov	x25, #0x0
    a100c:	mov	w3, #0x0
    a1028:	mov	x25, #0x0
    a1048:	add	x8, x8, #0xd28 ; Objc cfstring ref: @"bundleIdentifier"
    a1054:	add	x8, x8, #0xda8 ; Objc cfstring ref: @"displayName"
    a1068:	add	x8, x8, #0xdc8 ; Objc cfstring ref: @"icon"
    a1078:	mov	w24, #0x0
    a1090:	add	x2, x2, #0xde8 ; Objc cfstring ref: @"app.fill"
    a10a4:	mov	w24, #0x1
    a10b4:	add	x8, x8, #0xe08 ; Objc cfstring ref: @"categoryRank"
    a10e8:	add	x2, sp, #0x220
    a10ec:	add	x3, sp, #0x200
    a10f4:	mov	w4, #0x4
    a1164:	add	x28, x28, #0x1
    a1170:	add	x2, sp, #0x100
    a1174:	sub	x3, x29, #0xf0
    a1180:	mov	w4, #0x10
    a11c8:	add	x2, sp, #0xc0
    a11cc:	add	x3, sp, #0x180
    a11d4:	mov	w4, #0x10
    a11f0:	fmov	d8, #2.00000000
    a11f8:	mov	x21, #0x0
    a129c:	mov	x1, #0x0
    a12c8:	mov	w3, #0x0
    a12e4:	mov	x28, #0x0
    a12fc:	add	x2, x2, #0xe28 ; Objc cfstring ref: @"."
    a1378:	mov	x2, #0x0
    a1388:	add	x9, x8, #0xd28 ; Objc cfstring ref: @"bundleIdentifier"
    a1390:	add	x8, x8, #0xda8 ; Objc cfstring ref: @"displayName"
    a13a0:	add	x8, x8, #0xdc8 ; Objc cfstring ref: @"icon"

Branch samples:
    a0c90:	bl	0x2ecd00 ; Objc message: +[NSMutableArray array]
    a0c98:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a0cb0:	bl	0x2ecd00 ; Objc message: +[CBDashboardSettings sharedInstance]
    a0cb8:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a0cc8:	bl	0x2ecd00 ; Objc message: -[x0 reload]
    a0cd8:	bl	0x2ecd00 ; Objc message: -[x0 bridgedApps]
    a0ce0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a0ce8:	cbz	x0, 0xa1520
    a0cfc:	bl	0x2ecd00 ; Objc message: -[x0 count]
    a0d00:	cbz	x0, 0xa1520
    a0d14:	bl	0x2eccd0 ; symbol stub for: _objc_getClass
    a0d2c:	bl	0x2ecd00 ; Objc message: +[UIImage class]
    a0d44:	bl	0x2ecd00 ; Objc message: +[NSMutableSet set]
    a0d4c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a0d64:	cbz	x19, 0xa11ac
    a0d84:	bl	0x2ecd00 ; Objc message: -[x0 defaultWorkspace]
    a0d88:	cbz	w0, 0xa11ac
    a0d94:	bl	0x2ecd00 ; Objc message: -[x0 defaultWorkspace]
    a0d9c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a0da4:	cbz	x0, 0xa11a4
    a0dbc:	bl	0x2ecd00 ; Objc message: -[x0 allInstalledApplications]
    a0dc0:	cbz	w0, 0xa11a4
    a0ddc:	bl	0x2ecd00 ; Objc message: -[x0 performSelector:]
    a0de4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a0e0c:	bl	0x2ecd00 ; Objc message: -[x0 performSelector:]
    a0e10:	cbz	x0, 0xa1190
    a0eac:	b.eq	0xa0eb8
    a0eb4:	bl	0x2eccb8 ; symbol stub for: _objc_enumerationMutation
    a0ec0:	cbz	x23, 0xa1164
    a0ed0:	bl	0x2ecd00 ; Objc message: -[x0 addObject:]
    a0ed8:	tbnz	w0, #0x0, 0xa0ef4
    a0ee8:	bl	0x2ecd00 ; Objc message: -[x0 addObject:]
    a0ef0:	cbz	w0, 0xa0fa8
    a0efc:	bl	0x2ecd00 ; Objc message: -[x0 addObject:]
    a0f04:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a0f0c:	cbz	x0, 0xa115c
    a0f1c:	bl	0x2ecd00 ; Objc message: -[x0 addObject:]
    a0f20:	cbz	w0, 0xa115c
    a0f2c:	bl	0xa1594
    a0f30:	tbnz	w0, #0x0, 0xa115c

## CBMultitaskingOverlayView.addMoreAppsTapped: @ 0xa7f20
Original ABI: \`v24@0:8@16\`
Function boundary: \`0xa7f20..0xa8e9c\`
Instruction count: **991**; branches **219**;
Potential numerical operations (not yet semantic proof):

    a7f48:	add	x29, sp, #0x90
    a7f4c:	sub	sp, sp, #0x1e0
    a7f98:	add	x9, x9, #0x658
    a7fbc:	add	x9, x9, #0x818
    a7fe0:	sub	x2, x29, #0xd8
    a7fe4:	sub	x3, x29, #0x100
    a7ff8:	add	x0, x0, #0xfa8 ; Objc cfstring ref: @"[DuoFaceSB] UI addMoreAppsTapped -> presenting custom frosted alert modal"
    a800c:	mov	w2, #0x81cd
    a8010:	movk	w2, #0x1, lsl #16
    a8050:	fcmp	d11, #0.0
    a805c:	fcmp	d3, #0.0
    a80a8:	mov	w2, #0x81cd
    a80ac:	movk	w2, #0x1, lsl #16
    a810c:	mov	w2, #0x12
    a8194:	mov	w2, #0x12
    a81f4:	mov	x8, #-0x3fbc000000000000
    a8210:	fmov	d1, #0.50000000
    a8224:	mov	x8, #-0x3fa1000000000000
    a8250:	mov	x8, #0x405f000000000000
    a826c:	mov	w8, #0x81cd
    a8270:	movk	w8, #0x1, lsl #16
    a8274:	add	x2, x8, #0x1
    a831c:	fmov	s0, #0.50000000
    a834c:	fmov	d12, #18.00000000
    a8380:	fmov	d1, #6.00000000
    a83bc:	mov	w2, #0x0
    a83dc:	mov	w2, #0x12
    a845c:	fmov	d0, #16.00000000
    a84cc:	mov	w2, #0x1
    a8500:	fmov	d10, #1.00000000
    a864c:	add	x2, x2, #0x228 ; Objc cfstring ref: @"ADD_MORE_APPS_ALERT_TITLE"
    a8684:	fmov	d0, #13.50000000
    a86b8:	sub	x2, x29, #0xa8
    a86bc:	sub	x3, x29, #0xb0
    a86c0:	mov	w4, #0x1
    a8704:	fmov	d1, #24.00000000
    a870c:	fmov	d1, #-24.00000000
    a8740:	fmov	d1, #15.00000000
    a8780:	fmov	d13, #14.00000000
    a87ac:	add	x2, x2, #0xfc8 ; Objc cfstring ref: @"iphone.and.arrow.forward"

Branch samples:
    a7f68:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    a7fa0:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    a7fc4:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    a7ff0:	bl	0x2ecd00 ; Objc message: +[UIView animateWithDuration:animations:completion:]
    a7ffc:	bl	0x2ec9ac ; symbol stub for: _NSLog
    a8014:	bl	0x2ecd00 ; Objc message: -[x0 viewWithTag:]
    a801c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a8024:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a8028:	cbnz	x21, 0xa8e38
    a803c:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    a804c:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    a8054:	b.ls	0xa8e38
    a8060:	b.ls	0xa8e38
    a8068:	bl	0x2ecc34 ; symbol stub for: _objc_alloc
    a807c:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    a8094:	bl	0x2ecd00 ; Objc message: -[x0 initWithFrame:]
    a80b0:	bl	0x2ecd00 ; Objc message: -[x0 setTag:]
    a80c4:	bl	0x2ecd00 ; Objc message: +[UIColor clearColor]
    a80cc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a80f0:	bl	0x2ecd00 ; Objc message: -[x0 setBackgroundColor:]
    a80f8:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a8110:	bl	0x2ecd00 ; Objc message: -[x0 setAutoresizingMask:]
    a8118:	bl	0x2ecc34 ; symbol stub for: _objc_alloc
    a812c:	bl	0x2ecd00 ; Objc message: -[x0 setAutoresizingMask:]
    a813c:	bl	0x2ecd00 ; Objc message: -[x0 setAutoresizingMask:]
    a8160:	bl	0x2ecd00 ; Objc message: -[x0 colorWithWhite:alpha:]
    a8168:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a817c:	bl	0x2ecd00 ; Objc message: -[x0 colorWithWhite:alpha:]
    a8184:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a8198:	bl	0x2ecd00 ; Objc message: -[x0 colorWithWhite:alpha:]
    a81a4:	bl	0x2ecc34 ; symbol stub for: _objc_alloc
    a81c0:	bl	0x2ecd00 ; Objc message: +[UITapGestureRecognizer initWithTarget:action:]
    a81d8:	bl	0x2ecd00 ; Objc message: -[x0 addGestureRecognizer:]
    a81f0:	bl	0x2ecd00 ; Objc message: -[x0 addSubview:]
    a824c:	bl	0x2ecc34 ; symbol stub for: _objc_alloc
    a8268:	bl	0x2ecd00 ; Objc message: +[UIView addSubview:]
    a8280:	bl	0x2ecd00 ; Objc message: -[x0 addSubview:]
    a8294:	bl	0x2ecd00 ; Objc message: -[x0 blackColor]
    a829c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a82a0:	bl	0x2ecd48 ; symbol stub for: _objc_retainAutorelease

## CBMultitaskingOverlayView.setupAppPickerCardsInCardW:cardH:contentY: @ 0xa3e5c
Original ABI: \`v40@0:8d16d24d32\`
Function boundary: \`0xa3e5c..0xa5d18\`
Instruction count: **1967**; branches **389**;
Potential numerical operations (not yet semantic proof):

    a3e84:	add	x29, sp, #0x90
    a3e88:	sub	sp, sp, #0x330
    a3f38:	mov	x8, #0x4089000000000000
    a3f40:	mov	x8, #0x407e000000000000
    a3f4c:	fmov	d4, #2.00000000
    a3f5c:	mov	x2, #0x0
    a3fa0:	cmp	x19, #0x1
    a3fac:	mov	x21, #0x0
    a4078:	add	x21, x21, #0x1
    a40c0:	sub	x8, x0, #0x4
    a40c4:	cmp	x8, #0x2
    a40c8:	mov	w8, #0x4
    a40e4:	cmp	x8, #0x2
    a40e8:	mov	w8, #0x2
    a4138:	fmov	d0, #18.00000000
    a413c:	fmov	d12, #14.00000000
    a4144:	cmp	x23, #0x1
    a415c:	fmov	d1, #-2.00000000
    a41c8:	mov	w2, #0x1
    a41dc:	mov	w2, #0x0
    a41f0:	mov	w2, #0x0
    a4218:	mov	w2, #0x0
    a4260:	cmp	x23, #0x1
    a427c:	fmov	d1, #-2.00000000
    a42d0:	mov	x2, #0x0
    a42e4:	mov	w2, #0x1
    a42fc:	fmov	d0, #1.00000000
    a4300:	fmov	d1, #0.25000000
    a4378:	sub	x8, x29, #0xf0
    a43a0:	add	x2, sp, #0x2a0
    a43c0:	mov	w4, #0x1000
    a43dc:	cmp	x9, #0x6
    a43e0:	fmov	d0, #10.00000000
    a43e4:	fmov	d1, #8.00000000
    a43fc:	fmov	d2, #6.00000000
    a4408:	fmov	d0, #4.00000000
    a4420:	sub	x8, x9, #0x1
    a444c:	sub	x8, x22, #0x1
    a4470:	mov	w8, #0x42200000
    a4480:	fmov	d0, #-6.00000000

Branch samples:
    a3ec0:	bl	0x2ecd00 ; Objc message: -[x0 contentView]
    a3ec8:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a3eec:	bl	0x2ecd00 ; Objc message: -[x0 count]
    a3f08:	cbz	x0, 0xa44dc
    a3f1c:	bl	0x2ecd00 ; Objc message: +[NSMutableArray array]
    a3f24:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a3f60:	bl	0x9eee0
    a3f74:	bl	0x2ecd00 ; Objc message: -[x0 array]
    a3f8c:	bl	0x2ecd00 ; Objc message: +[NSMutableDictionary dictionary]
    a3f94:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a3fa8:	b.lt	0xa4084
    a3fe4:	bl	0x2ecd00 ; Objc message: -[x0 numberWithInteger:]
    a3fec:	b.hs	0xa4084
    a3ffc:	b.eq	0xa4078
    a400c:	bl	0x2ecd00 ; Objc message: -[x0 numberWithInteger:]
    a4014:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a401c:	cbz	x0, 0xa406c
    a4028:	bl	0x2ecd00 ; Objc message: -[x0 numberWithInteger:]
    a402c:	cbz	x0, 0xa406c
    a403c:	bl	0x2ecd00 ; Objc message: -[x0 numberWithInteger:]
    a4044:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a405c:	bl	0x2ecd00 ; Objc message: -[x0 numberWithInteger:]
    a4068:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a4070:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a4080:	b.ne	0xa3fdc
    a4094:	bl	0x2ecd00 ; Objc message: +[CBDashboardSettings sharedInstance]
    a409c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a40ac:	bl	0x2ecd00 ; Objc message: -[x0 reload]
    a40bc:	bl	0x2ecd00 ; Objc message: -[x0 gridCols]
    a40dc:	bl	0x2ecd00 ; Objc message: -[x0 gridRows]
    a40fc:	bl	0x2ecd00 ; Objc message: -[x0 hideIconLabels]
    a411c:	bl	0x2ecd00 ; Objc message: -[x0 hideIconLabels]
    a416c:	bl	0x2ecc34 ; symbol stub for: _objc_alloc
    a418c:	bl	0x2ecd00 ; Objc message: +[CBOverlayScrollView initWithFrame:]
    a41a4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a41b8:	bl	0x2ecd00 ; Objc message: -[x0 setDelegate:]
    a41cc:	bl	0x2ecd00 ; Objc message: -[x0 setPagingEnabled:]
    a41e0:	bl	0x2ecd00 ; Objc message: -[x0 setShowsHorizontalScrollIndicator:]
    a41f4:	bl	0x2ecd00 ; Objc message: -[x0 setShowsVerticalScrollIndicator:]
    a4208:	bl	0x2ecd00 ; Objc message: -[x0 setAlwaysBounceHorizontal:]

## CBMultitaskingOverlayView.appSelected: @ 0xa9ea8
Original ABI: \`v24@0:8@16\`
Function boundary: \`0xa9ea8..0xaa4f0\`
Instruction count: **402**; branches **106**;
Potential numerical operations (not yet semantic proof):

    a9ea8:	sub	sp, sp, #0x90
    a9ec4:	add	x29, sp, #0x80
    a9f38:	add	x2, x2, #0xd28 ; Objc cfstring ref: @"bundleIdentifier"
    a9fb8:	mov	x8, #0x4089000000000000
    a9fc0:	mov	x8, #0x407e000000000000
    a9fc8:	fmov	d4, #2.00000000
    a9fd8:	mov	x2, #0x0
    a9ff0:	cmp	x0, #0x1
    a9ffc:	mov	x23, #0x0
    aa060:	add	x23, x23, #0x1
    aa06c:	mov	x23, #-0x1
    aa0a4:	cmn	x8, #0x1
    aa1f8:	cmn	x8, #0x1
    aa218:	mov	w3, #0x1
    aa23c:	cmn	x8, #0x1
    aa25c:	mov	x2, #0x0
    aa260:	mov	x3, #0x0
    aa264:	mov	w4, #0x1
    aa42c:	add	sp, sp, #0x90
    aa4a0:	add	sp, sp, #0x90
    aa4ac:	add	x0, x0, #0x528
    aa4b4:	add	x1, x1, #0xe18
    aa4c4:	add	x0, x0, #0x528
    aa4cc:	add	x1, x1, #0xe18
    aa4dc:	add	x0, x0, #0x540
    aa4e4:	add	x1, x1, #0xe38

Branch samples:
    a9ed8:	bl	0x2ecd00 ; Objc message: -[x0 tag]
    a9edc:	tbnz	x0, #0x3f, 0xaa408
    a9efc:	bl	0x2ecd00 ; Objc message: -[x0 count]
    a9f04:	b.hs	0xaa408
    a9f1c:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    a9f24:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a9f3c:	bl	0x2ecd00 ; Objc message: -[x0 objectForKeyedSubscript:]
    a9f44:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a9f50:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a9f54:	cbz	x24, 0xaa400
    a9f64:	tbnz	x23, #0x3f, 0xaa400
    a9f78:	bl	0x2ecd00 ; Objc message: -[x0 objectForKeyedSubscript:]
    a9f80:	b.hs	0xaa400
    a9f98:	bl	0x2ecd00 ; Objc message: +[NSMutableArray array]
    a9fa0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a9fdc:	bl	0x9eee0
    a9fec:	bl	0x2ecd00 ; Objc message: -[x0 array]
    a9ff4:	b.lt	0xaa06c
    aa010:	bl	0x2ecd00 ; Objc message: -[x0 isEqualToString:]
    aa018:	b.hs	0xaa06c
    aa024:	b.eq	0xaa060
    aa034:	bl	0x2ecd00 ; Objc message: -[x0 isEqualToString:]
    aa03c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aa04c:	bl	0x2ecd00 ; Objc message: -[x0 isEqualToString:]
    aa058:	bl	0x2ecd30 ; symbol stub for: _objc_release
    aa05c:	tbnz	w28, #0x0, 0xaa070
    aa068:	b.ne	0xaa008
    aa084:	bl	0x2ecd00 ; Objc message: +[CBDashboardSettings sharedInstance]
    aa08c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aa0a8:	b.ne	0xaa4a8
    aa0b4:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    aa0cc:	bl	0x2ecd00 ; Objc message: +[NSMutableDictionary dictionaryWithContentsOfFile:]
    aa0d4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aa0dc:	cbz	x0, 0xaa0ec
    aa0e4:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    aa0e8:	b	0xaa104
    aa0f8:	bl	0x2ecd00 ; Objc message: -[x0 dictionary]
    aa100:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aa10c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    aa114:	bl	0x2ecd30 ; symbol stub for: _objc_release

## CBMultitaskingOverlayView.pageControlChanged: @ 0xa5de4
Original ABI: \`v24@0:8@16\`
Function boundary: \`0xa5de4..0xa5e78\`
Instruction count: **37**; branches **7**;
Potential numerical operations (not yet semantic proof):

    a5df4:	add	x29, sp, #0x30
    a5e24:	fcmp	d2, #0.0
    a5e58:	mov	w2, #0x1

Branch samples:
    a5e00:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    a5e14:	cbz	x0, 0xa5e60
    a5e20:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    a5e28:	b.le	0xa5e60
    a5e3c:	bl	0x2ecd00 ; Objc message: -[x0 currentPage]
    a5e5c:	bl	0x2ecd00 ; Objc message: -[x0 setContentOffset:animated:]
    a5e74:	b	0x2ecd30 ; symbol stub for: _objc_release

