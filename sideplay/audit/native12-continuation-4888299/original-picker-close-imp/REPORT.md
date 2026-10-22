# Original Native12: layout and preset ARM64 IMP evidence

- Verified original DEB SHA256: \`2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad\`
- Verified Dashboard SHA256: \`9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea\`
- Original method index blob: \`efa45df59bc3c16887cc979bf3aedc0c93c92111\`
- Exact extracted IMPs: **14**, ARM64 instructions: **6289**
- IMPORTANT: machine disassembly is NOT a runtime preset-frame test.
- A selector in an Objective-C call site does NOT prove a receiver.
- Preset 0..7 formulas in independent DFLayoutEngine remain UNVERIFIED until
  original function control flow and numerical CGRect outputs are derived.
- This artifact contains read-only evidence; no vendor code linked to app.

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

## CBMultitaskingOverlayView.setupRecentAppsCardsInCardW:cardH:contentY: @ 0xa678c
Original ABI: \`v40@0:8d16d24d32\`
Function boundary: \`0xa678c..0xa7f20\`
Instruction count: **1509**; branches **330**;
Potential numerical operations (not yet semantic proof):

    a67b4:	add	x29, sp, #0x90
    a67b8:	sub	sp, sp, #0x270
    a6844:	fmov	d0, #6.00000000
    a684c:	fmov	d0, #3.00000000
    a6854:	fmov	d0, #-16.00000000
    a685c:	mov	x8, #-0x3fa2000000000000
    a6874:	fmov	d0, #-24.00000000
    a6884:	mov	x8, #0x4041000000000000
    a688c:	fmov	d0, #16.00000000
    a68bc:	fmov	d0, #12.00000000
    a6908:	fmov	d0, #0.75000000
    a690c:	fmov	d1, #1.00000000
    a6990:	add	x2, x2, #0xa8 ; Objc cfstring ref: @"OVERLAY_ACTIVE_COUNT"
    a6a04:	add	x2, x2, #0xe8 ; Objc cfstring ref: @"OVERLAY_NO_ACTIVE"
    a6a68:	mov	x2, #0x0
    a6a84:	mov	x8, #0x405e000000000000
    a6a8c:	fmov	d3, #28.00000000
    a6b30:	fmov	d0, #14.00000000
    a6bd4:	fmov	d10, #1.00000000
    a6c64:	mov	w2, #0x1
    a6c74:	add	x2, x2, #0x128 ; Objc cfstring ref: @"OVERLAY_CLOSE_ALL"
    a6ca4:	mov	x3, #0x0
    a6ce8:	mov	x3, #0x0
    a6d0c:	fmov	d0, #11.50000000
    a6d84:	mov	w4, #0x40
    a6db0:	mov	x8, #0x4041000000000000
    a6dbc:	fmov	d0, #2.00000000
    a6dc4:	mov	x8, #-0x3fc0000000000000
    a6dd0:	fmov	d0, #16.00000000
    a6dd4:	fmov	d11, #0.50000000
    a6e48:	fmov	d0, #5.00000000
    a6e54:	fmov	d12, #-10.00000000
    a6ec8:	mov	w8, #0x2
    a6ed0:	sub	x23, x19, #0x1
    a6eec:	mov	x25, #0x0
    a6f48:	fmov	d0, #10.00000000
    a6f68:	mov	x8, #-0x3fb5000000000000
    a6f74:	mov	x8, #-0x3fb0000000000000
    a6f80:	fmov	d2, #-8.00000000
    a6f8c:	mov	x9, #0x404b000000000000

Branch samples:
    a67e0:	bl	0x2ecd00 ; Objc message: -[x0 contentView]
    a67e8:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a6800:	bl	0x2ecd00 ; Objc message: +[CBBridgeManager sharedInstance]
    a6808:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a6818:	bl	0x2ecd00 ; Objc message: -[x0 runningBridgedApplications]
    a6820:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a6838:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a6840:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a6870:	bl	0x2ecc34 ; symbol stub for: _objc_alloc
    a6898:	bl	0x2ecd00 ; Objc message: +[UILabel initWithFrame:]
    a68c8:	bl	0x2ecd00 ; Objc message: +[UIFont systemFontOfSize:weight:]
    a68d0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a68ec:	bl	0x2ecd00 ; Objc message: -[x0 setFont:]
    a68f4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a6914:	bl	0x2ecd00 ; Objc message: +[UIColor colorWithWhite:alpha:]
    a691c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a6938:	bl	0x2ecd00 ; Objc message: -[x0 setTextColor:]
    a6940:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a6954:	bl	0x2ecd00 ; Objc message: -[x0 count]
    a6978:	cbz	x0, 0xa69f4
    a699c:	bl	0x2ecd00 ; Objc message: -[x0 localizedStringForKey:]
    a69a4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a69b4:	bl	0x2ecd00 ; Objc message: -[x0 localizedStringForKey:]
    a69c8:	bl	0x2ecd00 ; Objc message: -[x0 localizedStringForKey:]
    a69d0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a69e4:	bl	0x2ecd00 ; Objc message: -[x0 localizedStringForKey:]
    a69ec:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a69f0:	b	0xa6a2c
    a6a0c:	bl	0x2ecd00 ; Objc message: -[x0 localizedStringForKey:]
    a6a14:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a6a28:	bl	0x2ecd00 ; Objc message: -[x0 localizedStringForKey:]
    a6a30:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a6a50:	bl	0x2ecd00 ; Objc message: -[x0 addSubview:]
    a6a6c:	bl	0x2ecd00 ; Objc message: +[UIButton buttonWithType:]
    a6a74:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a6a9c:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    a6ad8:	bl	0x2ecd00 ; Objc message: +[UIColor colorWithRed:green:blue:alpha:]
    a6ae0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a6afc:	bl	0x2ecd00 ; Objc message: -[x0 setBackgroundColor:]
    a6b04:	bl	0x2ecd30 ; symbol stub for: _objc_release

## CBMultitaskingOverlayView.setupCardContent @ 0xa2a58
Original ABI: \`v16@0:8\`
Function boundary: \`0xa2a58..0xa3e5c\`
Instruction count: **1281**; branches **281**;
Potential numerical operations (not yet semantic proof):

    a2a80:	add	x29, sp, #0x90
    a2a84:	sub	sp, sp, #0x1b0
    a2aec:	add	x2, sp, #0xe0
    a2af0:	add	x3, sp, #0x120
    a2af8:	mov	w4, #0x10
    a2b14:	mov	x27, #0x0
    a2b44:	add	x27, x27, #0x1
    a2b50:	add	x2, sp, #0xe0
    a2b54:	add	x3, sp, #0x120
    a2b60:	mov	w4, #0x10
    a2bb4:	fcmp	d2, #0.0
    a2be4:	fcmp	d3, #0.0
    a2c14:	mov	x8, #0x4043000000000000
    a2c1c:	mov	x8, #0x4040000000000000
    a2c34:	fmov	d0, #-18.00000000
    a2c3c:	fmov	d1, #0.50000000
    a2c4c:	fmov	d0, #14.00000000
    a2c50:	fmov	d2, #18.00000000
    a2c84:	mov	w2, #0x1
    a2cb0:	fmov	d2, #1.00000000
    a2d1c:	cmp	x8, #0x1
    a2d2c:	add	x2, x2, #0xd28 ; Objc cfstring ref: @"rectangle.split.2x1.fill"
    a2d44:	add	x2, x2, #0xe48 ; Objc cfstring ref: @"square.grid.2x2.fill"
    a2d54:	add	x2, x2, #0xe68 ; Objc cfstring ref: @"app.badge.fill"
    a2da0:	fmov	d0, #28.00000000
    a2da4:	fmov	d10, #24.00000000
    a2dcc:	add	x9, x9, #0x830
    a2dd4:	mov	x8, #-0x3fbe000000000000
    a2de4:	mov	x8, #-0x3fbd000000000000
    a2df0:	mov	x8, #0x4054000000000000
    a2dfc:	fmov	d0, #-20.00000000
    a2e08:	fmov	d1, #0.50000000
    a2e10:	fmov	d0, #13.00000000
    a2e14:	fmov	d3, #11.50000000
    a2e1c:	mov	x8, #0x4042000000000000
    a2e24:	fmov	d3, #20.00000000
    a2ee8:	mov	w2, #0x1
    a2f14:	mov	w2, #0x2
    a2f38:	cmp	x8, #0x1
    a2f44:	add	x2, x2, #0xf48 ; Objc cfstring ref: @"OVERLAY_LAYOUT"

Branch samples:
    a2ab0:	bl	0x2ecd00 ; Objc message: -[x0 contentView]
    a2ab8:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a2ad4:	bl	0x2ecd00 ; Objc message: -[x0 subviews]
    a2adc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a2afc:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    a2b00:	cbz	x0, 0xa2b70
    a2b28:	b.eq	0xa2b34
    a2b30:	bl	0x2eccb8 ; symbol stub for: _objc_enumerationMutation
    a2b40:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    a2b4c:	b.lo	0xa2b1c
    a2b64:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    a2b6c:	cbnz	x0, 0xa2b14
    a2b74:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a2b88:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a2b9c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a2bb0:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    a2bb8:	b.le	0xa2bd0
    a2bc4:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    a2bcc:	b	0xa2bd8
    a2be0:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    a2be8:	b.le	0xa2c00
    a2bf4:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    a2bfc:	b	0xa2c08
    a2c30:	bl	0x2ecc34 ; symbol stub for: _objc_alloc
    a2c5c:	bl	0x2ecd00 ; Objc message: +[UIImageView initWithFrame:]
    a2c74:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a2c88:	bl	0x2ecd00 ; Objc message: -[x0 setContentMode:]
    a2cc4:	bl	0x2ecd00 ; Objc message: -[x0 colorWithRed:green:blue:alpha:]
    a2ccc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a2ce8:	bl	0x2ecd00 ; Objc message: -[x0 setTintColor:]
    a2cf0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a2d0c:	cbz	x8, 0xa2d34
    a2d24:	b.ne	0xa2d50
    a2d30:	b	0xa2d58
    a2d4c:	b	0xa2d58
    a2d58:	bl	0x2ecd00 ; Objc message: -[x0 systemImageNamed:]
    a2d5c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a2d74:	bl	0x2ecd00 ; Objc message: -[x0 setImage:]
    a2d7c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a2d94:	bl	0x2ecd00 ; Objc message: -[x0 addSubview:]

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

## CBMultitaskingOverlayView.closeSingleAppTapped: @ 0xa9484
Original ABI: \`v24@0:8@16\`
Function boundary: \`0xa9484..0xa9620\`
Instruction count: **103**; branches **20**;
Potential numerical operations (not yet semantic proof):

    a9484:	sub	sp, sp, #0xd0
    a949c:	add	x29, sp, #0xc0
    a950c:	add	x24, x24, #0x658
    a9534:	add	x9, x9, #0x818
    a9554:	add	x2, sp, #0x58
    a9558:	add	x3, sp, #0x30
    a956c:	add	x0, x0, #0x8 ; Objc cfstring ref: @"[DuoFaceSB] UI closeSingleAppTapped: %@"
    a95ac:	mov	x0, #0x0
    a95b0:	mov	w1, #0xd180
    a95b4:	movk	w1, #0x8f0, lsl #16
    a95dc:	add	x2, sp, #0x8
    a9618:	add	sp, sp, #0xd0

Branch samples:
    a94a8:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    a94b8:	bl	0x2ecd00 ; Objc message: -[x0 accessibilityIdentifier]
    a94c0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a94c8:	cbz	x0, 0xa95f4
    a94d8:	bl	0x2ecd00 ; Objc message: -[x0 length]
    a94dc:	cbz	x0, 0xa95f4
    a9518:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    a953c:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    a9560:	bl	0x2ecd00 ; Objc message: +[UIView animateWithDuration:animations:completion:]
    a9570:	bl	0x2ec9ac ; symbol stub for: _NSLog
    a9584:	bl	0x2ecd00 ; Objc message: +[CBBridgeManager sharedInstance]
    a958c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a95a0:	bl	0x2ecd00 ; Objc message: -[x0 terminateApplicationWithBundleID:]
    a95a8:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a95b8:	bl	0x2ecb50 ; symbol stub for: _dispatch_time
    a95e0:	bl	0x2ecb20 ; symbol stub for: _dispatch_after
    a95e8:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a95f0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a95f8:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a9600:	bl	0x2ecd30 ; symbol stub for: _objc_release

## CBMultitaskingOverlayView.closeAllBridgedAppsTapped: @ 0xa9838
Original ABI: \`v24@0:8@16\`
Function boundary: \`0xa9838..0xa9964\`
Instruction count: **75**; branches **13**;
Potential numerical operations (not yet semantic proof):

    a9838:	sub	sp, sp, #0x90
    a984c:	add	x29, sp, #0x80
    a9888:	add	x9, x9, #0x658
    a98a8:	add	x9, x9, #0x818
    a98d0:	add	x2, sp, #0x28
    a98e8:	add	x0, x0, #0x28 ; Objc cfstring ref: @"[DuoFaceSB] UI closeAllBridgedAppsTapped: Killing background apps & restarting active on-screen apps"
    a995c:	add	sp, sp, #0x90

Branch samples:
    a9858:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    a9890:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    a98c0:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    a98e0:	bl	0x2ecd00 ; Objc message: +[UIView animateWithDuration:animations:completion:]
    a98ec:	bl	0x2ec9ac ; symbol stub for: _NSLog
    a9900:	bl	0x2ecd00 ; Objc message: +[CBBridgeManager sharedInstance]
    a9908:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a9918:	bl	0x2ecd00 ; Objc message: -[x0 terminateAllBridgedApplications]
    a9920:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a9930:	bl	0x2ecd00 ; Objc message: -[x0 dismissOverlay]
    a9938:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a9940:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a9948:	bl	0x2ecd30 ; symbol stub for: _objc_release

## CBMultitaskingOverlayView.restartSingleAppTapped: @ 0xa91ec
Original ABI: \`v24@0:8@16\`
Function boundary: \`0xa91ec..0xa9360\`
Instruction count: **93**; branches **19**;
Potential numerical operations (not yet semantic proof):

    a91ec:	sub	sp, sp, #0xb0
    a9204:	add	x29, sp, #0xa0
    a9274:	add	x9, x9, #0x658
    a929c:	add	x9, x9, #0x818
    a92bc:	add	x2, sp, #0x38
    a92c0:	add	x3, sp, #0x10
    a92d4:	add	x0, x0, #0xfe8 ; Objc cfstring ref: @"[DuoFaceSB] UI restartSingleAppTapped: %@"
    a9358:	add	sp, sp, #0xb0

Branch samples:
    a9210:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    a9220:	bl	0x2ecd00 ; Objc message: -[x0 accessibilityIdentifier]
    a9228:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a9230:	cbz	x0, 0xa9334
    a9240:	bl	0x2ecd00 ; Objc message: -[x0 length]
    a9244:	cbz	x0, 0xa9334
    a9280:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    a92a4:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    a92c8:	bl	0x2ecd00 ; Objc message: +[UIView animateWithDuration:animations:completion:]
    a92d8:	bl	0x2ec9ac ; symbol stub for: _NSLog
    a92ec:	bl	0x2ecd00 ; Objc message: +[CBBridgeManager sharedInstance]
    a92f4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a9308:	bl	0x2ecd00 ; Objc message: -[x0 restartApplicationWithBundleID:]
    a9310:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a9320:	bl	0x2ecd00 ; Objc message: -[x0 dismissOverlay]
    a9328:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a9330:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a9338:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a9340:	bl	0x2ecd30 ; symbol stub for: _objc_release

## CBMultitaskingOverlayView.showAppPickerForSlot:parentView: @ 0xaa800
Original ABI: \`v32@0:8q16@24\`
Function boundary: \`0xaa800..0xaac80\`
Instruction count: **288**; branches **62**;
Potential numerical operations (not yet semantic proof):

    aa800:	sub	sp, sp, #0x140
    aa81c:	add	x29, sp, #0x130
    aa8ec:	cmp	x0, #0x8
    aa914:	cmp	x0, #0x0
    aa970:	add	x24, x24, #0x288 ; Objc cfstring ref: @""
    aa99c:	cmp	x0, #0x0
    aa9a8:	mov	w9, #0x1
    aa9d4:	mov	w25, #0x0
    aa9fc:	cmp	x0, #0x0
    aaa04:	mov	w25, #0x1
    aaa28:	cmp	x0, #0x0
    aaa50:	cmp	x0, #0x0
    aaa6c:	sub	x2, x29, #0x80
    aaa70:	mov	w3, #0x4
    aab7c:	mov	w2, #0x0
    aab8c:	add	x8, sp, #0x80
    aabbc:	add	x2, sp, #0x50
    aabfc:	add	x9, x9, #0x658
    aac24:	fmov	d0, #0.25000000
    aac2c:	add	x3, sp, #0x28
    aac30:	mov	w2, #0x20000
    aac34:	mov	x4, #0x0
    aac74:	add	sp, sp, #0x140

Branch samples:
    aa830:	cbz	x3, 0xaac44
    aa854:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    aa864:	bl	0x2ecd00 ; Objc message: +[CBLocalization sharedInstance]
    aa86c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aa87c:	bl	0x2ecd00 ; Objc message: -[x0 reloadLanguage]
    aa884:	bl	0x2ecd30 ; symbol stub for: _objc_release
    aa8ac:	bl	0x2ecd00 ; Objc message: +[CBDashboardSettings reloadLanguage]
    aa8b4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aa8c4:	bl	0x2ecd00 ; Objc message: -[x0 reload]
    aa8d8:	bl	0x2ecd00 ; Objc message: -[x0 splitPreset]
    aa8dc:	tbnz	x0, #0x3f, 0xaa904
    aa8e8:	bl	0x2ecd00 ; Objc message: -[x0 splitPreset]
    aa8f0:	b.gt	0xaa904
    aa8fc:	bl	0x2ecd00 ; Objc message: -[x0 splitPreset]
    aa900:	b	0xaa91c
    aa910:	bl	0x2ecd00 ; Objc message: -[x0 splitMode]
    aa934:	bl	0x2ecd00 ; Objc message: -[x0 splitRatio]
    aa95c:	bl	0x2ecd00 ; Objc message: +[NSMutableArray splitApp1]
    aa964:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aa974:	cbz	x0, 0xaa984
    aa980:	b	0xaa9b0
    aa990:	bl	0x2ecd00 ; Objc message: -[x0 splitLeftBundleID]
    aa998:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aa9c0:	bl	0x2ecd00 ; Objc message: -[x0 splitApp2]
    aa9c8:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aa9d0:	cbz	x0, 0xaa9e0
    aa9dc:	b	0xaaa08
    aa9ec:	bl	0x2ecd00 ; Objc message: -[x0 splitRightBundleID]
    aa9f4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aaa18:	bl	0x2ecd00 ; Objc message: -[x0 splitApp3]
    aaa20:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aaa40:	bl	0x2ecd00 ; Objc message: -[x0 splitApp4]
    aaa48:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aaa74:	bl	0x2ecd00 ; Objc message: +[NSArray arrayWithObjects:count:]
    aaa7c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aaa94:	bl	0x2ecd00 ; Objc message: -[x0 arrayWithArray:]
    aaa9c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aaab4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    aaabc:	bl	0x2ecd30 ; symbol stub for: _objc_release
    aaac4:	bl	0x2ecd30 ; symbol stub for: _objc_release

## CBMultitaskingOverlayView.showRecentAppsInParentView: @ 0xab1d4
Original ABI: \`v24@0:8@16\`
Function boundary: \`0xab1d4..0xab69c\`
Instruction count: **306**; branches **68**;
Potential numerical operations (not yet semantic proof):

    ab1d4:	sub	sp, sp, #0x140
    ab1f0:	add	x29, sp, #0x130
    ab260:	mov	w9, #0x2
    ab2b8:	cmp	x0, #0x8
    ab2e0:	cmp	x0, #0x0
    ab33c:	add	x26, x26, #0x288 ; Objc cfstring ref: @""
    ab368:	cmp	x0, #0x0
    ab374:	mov	w9, #0x1
    ab3a0:	mov	w23, #0x0
    ab3c8:	cmp	x0, #0x0
    ab3d0:	mov	w23, #0x1
    ab3f4:	cmp	x0, #0x0
    ab41c:	cmp	x0, #0x0
    ab438:	sub	x2, x29, #0x80
    ab43c:	mov	w3, #0x4
    ab598:	mov	w2, #0x0
    ab5a8:	add	x8, sp, #0x80
    ab5d8:	add	x2, sp, #0x50
    ab618:	add	x9, x9, #0x658
    ab640:	fmov	d0, #0.25000000
    ab648:	add	x3, sp, #0x28
    ab64c:	mov	w2, #0x20000
    ab650:	mov	x4, #0x0
    ab690:	add	sp, sp, #0x140

Branch samples:
    ab204:	cbz	x2, 0xab660
    ab224:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    ab234:	bl	0x2ecd00 ; Objc message: +[CBLocalization sharedInstance]
    ab23c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ab24c:	bl	0x2ecd00 ; Objc message: -[x0 reloadLanguage]
    ab254:	bl	0x2ecd30 ; symbol stub for: _objc_release
    ab278:	bl	0x2ecd00 ; Objc message: +[CBDashboardSettings reloadLanguage]
    ab280:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ab290:	bl	0x2ecd00 ; Objc message: -[x0 reload]
    ab2a4:	bl	0x2ecd00 ; Objc message: -[x0 splitPreset]
    ab2a8:	tbnz	x0, #0x3f, 0xab2d0
    ab2b4:	bl	0x2ecd00 ; Objc message: -[x0 splitPreset]
    ab2bc:	b.gt	0xab2d0
    ab2c8:	bl	0x2ecd00 ; Objc message: -[x0 splitPreset]
    ab2cc:	b	0xab2e8
    ab2dc:	bl	0x2ecd00 ; Objc message: -[x0 splitMode]
    ab300:	bl	0x2ecd00 ; Objc message: -[x0 splitRatio]
    ab328:	bl	0x2ecd00 ; Objc message: +[NSMutableArray splitApp1]
    ab330:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ab340:	cbz	x0, 0xab350
    ab34c:	b	0xab37c
    ab35c:	bl	0x2ecd00 ; Objc message: -[x0 splitLeftBundleID]
    ab364:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ab38c:	bl	0x2ecd00 ; Objc message: -[x0 splitApp2]
    ab394:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ab39c:	cbz	x0, 0xab3ac
    ab3a8:	b	0xab3d4
    ab3b8:	bl	0x2ecd00 ; Objc message: -[x0 splitRightBundleID]
    ab3c0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ab3e4:	bl	0x2ecd00 ; Objc message: -[x0 splitApp3]
    ab3ec:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ab40c:	bl	0x2ecd00 ; Objc message: -[x0 splitApp4]
    ab414:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ab440:	bl	0x2ecd00 ; Objc message: +[NSArray arrayWithObjects:count:]
    ab448:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ab460:	bl	0x2ecd00 ; Objc message: -[x0 arrayWithArray:]
    ab468:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ab480:	bl	0x2ecd30 ; symbol stub for: _objc_release
    ab488:	bl	0x2ecd30 ; symbol stub for: _objc_release
    ab490:	bl	0x2ecd30 ; symbol stub for: _objc_release

## CBMultitaskingOverlayView.switchToAppPickerMode @ 0xa9a88
Original ABI: \`v16@0:8\`
Function boundary: \`0xa9a88..0xa9b1c\`
Instruction count: **37**; branches **2**;
Potential numerical operations (not yet semantic proof):

    a9a88:	sub	sp, sp, #0x40
    a9a90:	add	x29, sp, #0x30
    a9adc:	add	x10, x10, #0x658
    a9afc:	add	x4, sp, #0x8
    a9b04:	mov	w3, #0x500000
    a9b08:	mov	x5, #0x0
    a9b14:	add	sp, sp, #0x40

Branch samples:
    a9aa0:	cbz	x9, 0xa9b10
    a9b0c:	bl	0x2ecd00 ; Objc message: +[UIView transitionWithView:duration:options:animations:completion:]

## CBMultitaskingOverlayView.switchToRecentMode @ 0xa9bd8
Original ABI: \`v16@0:8\`
Function boundary: \`0xa9bd8..0xa9cd0\`
Instruction count: **62**; branches **8**;
Potential numerical operations (not yet semantic proof):

    a9bd8:	sub	sp, sp, #0x50
    a9be4:	add	x29, sp, #0x40
    a9bf4:	cmp	x9, #0x2
    a9c00:	mov	w9, #0x2
    a9c90:	add	x9, x9, #0x658
    a9cb0:	add	x4, sp, #0x8
    a9cb4:	mov	w3, #0x500000
    a9cb8:	mov	x5, #0x0
    a9cc8:	add	sp, sp, #0x50

Branch samples:
    a9bf8:	b.eq	0xa9cc0
    a9c18:	bl	0x2ecd00 ; Objc message: +[CBBridgeManager sharedInstance]
    a9c20:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a9c30:	bl	0x2ecd00 ; Objc message: -[x0 runningBridgedApplications]
    a9c38:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    a9c50:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a9c58:	bl	0x2ecd30 ; symbol stub for: _objc_release
    a9cbc:	bl	0x2ecd00 ; Objc message: +[UIView transitionWithView:duration:options:animations:completion:]

## CBMultitaskingOverlayView.dismissOverlay @ 0xab70c
Original ABI: \`v16@0:8\`
Function boundary: \`0xab70c..0xab7a0\`
Instruction count: **37**; branches **1**;
Potential numerical operations (not yet semantic proof):

    ab70c:	sub	sp, sp, #0x60
    ab714:	add	x29, sp, #0x50
    ab744:	add	x11, x11, #0x658
    ab760:	add	x10, x10, #0x818
    ab780:	add	x3, sp, #0x28
    ab78c:	mov	w2, #0x10000
    ab798:	add	sp, sp, #0x60

Branch samples:
    ab790:	bl	0x2ecd00 ; Objc message: +[UIView animateWithDuration:delay:options:animations:completion:]

