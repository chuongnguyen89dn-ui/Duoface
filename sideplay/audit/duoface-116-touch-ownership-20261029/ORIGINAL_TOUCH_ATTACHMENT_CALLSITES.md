# ORIGINAL Native12 touch owner: attachment and override callsites

- Evidence: original immutable DEB SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`
- Original Dashboard Mach-O SHA256 `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`
- Original 6 verified IMPs from CI run 40863967219; this is read-only disassembly, not runtime UI testing.
- Context below is native Mach-O disassembly. A name or class reference alone is not a proven execution branch.

## CBWindow.createWindows @ 0xb1064
- Original instructions: 580; selected callsite markers: 21

    ...
    b12bc:	mov	x23, x0
    b12c0:	add	x0, x21, #0x10
    b12c4:	mov	x1, x23
    b12c8:	bl	0x2ecd90 ; symbol stub for: _objc_storeStrong
    b12cc:	adrp	x0, 600 ; 0x309000
    b12d0:	add	x0, x0, #0x2f6 ; literal pool for: "UIRootSceneWindow"
    b12d4:	bl	0x2eccd0 ; symbol stub for: _objc_getClass
    b12d8:	mov	x25, x0
    b12dc:	adrp	x22, 717 ; 0x37e000
    b12e0:	cbnz	x0, 0xb130c
    b12e4:	adrp	x0, 600 ; 0x309000
    b12e8:	add	x0, x0, #0x308 ; literal pool for: "SBFTouchPassThroughWindow"
    b12ec:	bl	0x2eccd0 ; symbol stub for: _objc_getClass
    b12f0:	mov	x25, x0
    b12f4:	cbnz	x0, 0xb130c
    b12f8:	adrp	x0, 600 ; 0x309000
    b12fc:	add	x0, x0, #0x322 ; literal pool for: "UIWindow"
    b1300:	bl	0x2eccd0 ; symbol stub for: _objc_getClass
    b1304:	mov	x25, x0
    b1308:	cbz	x0, 0xb14d4
    b130c:	adrp	x0, 600 ; 0x309000
    b1310:	add	x0, x0, #0x443 ; literal pool for: "CBTouchPassThroughRootSceneWindow"
    b1314:	bl	0x2eccd0 ; symbol stub for: _objc_getClass
    b1318:	mov	x24, x0
    b131c:	cbnz	x0, 0xb1410
    b1320:	adrp	x1, 600 ; 0x309000
    b1324:	add	x1, x1, #0x443 ; literal pool for: "CBTouchPassThroughRootSceneWindow"
    b1328:	mov	x0, x25
    b132c:	mov	x2, #0x0
    b1330:	bl	0x2ecc4c ; symbol stub for: _objc_allocateClassPair
    b1334:	cbz	x0, 0xb1360
    b1338:	mov	x24, x0
    b133c:	adrp	x8, 717 ; 0x37e000
    b1340:	ldr	x26, [x8, #0x2c8] ; Objc selector ref: hitTest:withEvent:
    b1344:	mov	x0, x25
    b1348:	mov	x1, x26
    b134c:	bl	0x2ecaf0 ; symbol stub for: _class_getInstanceMethod
    b1350:	cbz	x0, 0xb1368
    b1354:	bl	0x2ecc10 ; symbol stub for: _method_getTypeEncoding
    b1358:	mov	x3, x0
    b135c:	b	0xb1370
    b1360:	mov	x24, x25
    ...
    b136c:	add	x3, x3, #0x465 ; literal pool for: "@@:{CGPoint=dd}@"
    b1370:	adr	x2, #6624
    b1374:	nop
    b1378:	mov	x0, x24
    b137c:	mov	x1, x26
    b1380:	bl	0x2ecae4 ; symbol stub for: _class_addMethod
    b1384:	adrp	x8, 717 ; 0x37e000
    b1388:	ldr	x26, [x8, #0x5a8] ; Objc selector ref: pointInside:withEvent:
    b138c:	mov	x0, x25
    b1390:	mov	x1, x26
    b1394:	bl	0x2ecaf0 ; symbol stub for: _class_getInstanceMethod
    b1398:	cbz	x0, 0xb13a8
    b139c:	bl	0x2ecc10 ; symbol stub for: _method_getTypeEncoding
    b13a0:	mov	x3, x0
    b13a4:	b	0xb13b0
    b13a8:	adrp	x3, 600 ; 0x309000
    b13ac:	add	x3, x3, #0x476 ; literal pool for: "B@:{CGPoint=dd}@"
    b13b0:	adr	x2, #6992
    b13b4:	nop
    b13b8:	mov	x0, x24
    b13bc:	mov	x1, x26
    b13c0:	bl	0x2ecae4 ; symbol stub for: _class_addMethod
    b13c4:	adrp	x8, 717 ; 0x37e000
    b13c8:	ldr	x26, [x8, #0x5b0] ; Objc selector ref: sendEvent:
    b13cc:	mov	x0, x25
    b13d0:	mov	x1, x26
    b13d4:	bl	0x2ecaf0 ; symbol stub for: _class_getInstanceMethod
    b13d8:	cbz	x0, 0xb13e8
    b13dc:	bl	0x2ecc10 ; symbol stub for: _method_getTypeEncoding
    b13e0:	mov	x3, x0
    ...
    b13ec:	add	x3, x3, #0x487 ; literal pool for: "v@:@"
    b13f0:	adr	x2, #7508
    b13f4:	nop
    b13f8:	mov	x0, x24
    b13fc:	mov	x1, x26
    b1400:	bl	0x2ecae4 ; symbol stub for: _class_addMethod
    b1404:	mov	x0, x24
    b1408:	bl	0x2ecd24 ; symbol stub for: _objc_registerClassPair
    b140c:	ldr	x26, [sp, #0x30]
    b1410:	mov	x0, x24
    b1414:	bl	0x2ecd48 ; symbol stub for: _objc_retainAutorelease
    b1418:	mov	x24, x0
    b141c:	adrp	x19, 717 ; 0x37e000
    b1420:	cbz	x23, 0xb1454
    b1424:	adrp	x8, 717 ; 0x37e000
    b1428:	ldr	x25, [x8, #0x510] ; Objc selector ref: initWithDisplayConfiguration:
    ...
    b1570:	bl	0x2ecd00 ; Objc message: -[x0 setScreen:]
    b1574:	b	0xb157c
    b1578:	ldr	x24, [x27, #0x5d8]
    b157c:	ldr	x0, [x21, #0x20]
    b1580:	adrp	x8, 716 ; 0x37d000
    b1584:	ldr	x25, [x8, #0x9c8] ; Objc selector ref: setWindowLevel:
    b1588:	mov	x1, x24
    b158c:	mov	x2, x25
    b1590:	bl	0x2ecd00 ; Objc message: -[x0 setWindowLevel:]
    b1594:	cbz	w0, 0xb15ac
    b1598:	ldr	x0, [x21, #0x20]
    b159c:	adrp	x8, 608 ; 0x311000
    b15a0:	ldr	d0, [x8, #0x940]
    b15a4:	mov	x1, x25
    b15a8:	bl	0x2ecd00 ; Objc message: -[x0 setWindowLevel:]
    b15ac:	ldr	x0, [x28, #0x910]
    b15b0:	ldr	x1, [x22, #0x4e0]
    b15b4:	bl	0x2ecd00 ; Objc message: -[x0 setWindowLevel:]
    b15b8:	mov.16b	v12, v0
    b15bc:	mov.16b	v13, v1
    b15c0:	mov.16b	v14, v2
    b15c4:	mov.16b	v15, v3
    b15c8:	ldr	x0, [x28, #0x910]
    b15cc:	adrp	x8, 717 ; 0x37e000
    b15d0:	ldr	x1, [x8, #0x320] ; Objc selector ref: carPlayUsableBounds
    b15d4:	bl	0x2ecd00 ; Objc message: -[x0 carPlayUsableBounds]
    ...
    b15ec:	add	x0, x0, #0x568
    b15f0:	mov	x1, x21
    b15f4:	bl	0x2ecd9c ; symbol stub for: _objc_storeWeak
    b15f8:	ldr	x0, [x21, #0x20]
    b15fc:	adrp	x8, 716 ; 0x37d000
    b1600:	ldr	x24, [x8, #0xa10] ; Objc selector ref: setFrame:
    b1604:	mov	x1, x24
    b1608:	mov.16b	v0, v12
    b160c:	mov.16b	v1, v13
    b1610:	mov.16b	v2, v14
    b1614:	mov.16b	v3, v15
    b1618:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    b161c:	ldr	x0, [x21, #0x20]
    b1620:	adrp	x8, 716 ; 0x37d000
    b1624:	ldr	x1, [x8, #0x980] ; Objc selector ref: setHidden:
    b1628:	mov	w2, #0x1
    b162c:	bl	0x2ecd00 ; Objc message: -[x0 setHidden:]
    b1630:	adrp	x19, 718 ; 0x37f000
    b1634:	ldr	x0, [x19, #0x818] ; Objc class ref: _OBJC_CLASS_$_UIColor
    b1638:	adrp	x8, 716 ; 0x37d000
    ...
    b17dc:	mov	x1, x28
    b17e0:	mov	w2, #0x12
    b17e4:	bl	0x2ecd00 ; Objc message: -[x0 initWithEffect:]
    b17e8:	ldr	x0, [x21, #0x30]
    b17ec:	adrp	x8, 716 ; 0x37d000
    b17f0:	ldr	x1, [x8, #0xdf8] ; Objc selector ref: setClipsToBounds:
    b17f4:	mov	w2, #0x1
    b17f8:	bl	0x2ecd00 ; Objc message: -[x0 setClipsToBounds:]
    b17fc:	ldr	x0, [x21, #0x30]
    b1800:	adrp	x8, 716 ; 0x37d000
    b1804:	ldr	x1, [x8, #0xa18] ; Objc selector ref: layer
    b1808:	bl	0x2ecd00 ; Objc message: -[x0 layer]
    b180c:	mov	x29, x29
    b1810:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b1814:	mov	x22, x0
    b1818:	adrp	x8, 716 ; 0x37d000
    ...
    b183c:	mov	x29, x29
    b1840:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b1844:	mov	x22, x0
    b1848:	ldr	x2, [x21, #0x30]
    b184c:	adrp	x8, 716 ; 0x37d000
    b1850:	ldr	x1, [x8, #0xa80] ; Objc selector ref: addSubview:
    b1854:	bl	0x2ecd00 ; Objc message: -[x0 addSubview:]
    b1858:	mov	x0, x22
    b185c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b1860:	ldp	x19, x24, [x21, #0x20]
    b1864:	mov.16b	v0, v12
    b1868:	mov.16b	v1, v13
    b186c:	mov.16b	v2, v14
    b1870:	mov.16b	v3, v15
    b1874:	bl	0x2ec9d0 ; symbol stub for: _NSStringFromCGRect

## CBWindow.initWithAppFrame: @ 0xaf4bc
- Original instructions: 38; selected callsite markers: 0

- No matching input-attachment selector/class marker observed in this IMP.

## CBBridgedSplitApp.initWithBundleIdentifier:frame:showSplash: @ 0x1025e4
- Original instructions: 1202; selected callsite markers: 3

    ...
    1028a4:	mov	x0, x24
    1028a8:	str	x1, [sp, #0x1a0]
    1028ac:	mov	w2, #0x12
    1028b0:	bl	0x2ecd00 ; Objc message: -[x0 setAutoresizingMask:]
    1028b4:	adrp	x8, 635 ; 0x37d000
    1028b8:	ldr	x1, [x8, #0xdf8] ; Objc selector ref: setClipsToBounds:
    1028bc:	mov	x0, x24
    1028c0:	str	x1, [sp, #0x148]
    1028c4:	mov	w2, #0x1
    1028c8:	bl	0x2ecd00 ; Objc message: -[x0 setClipsToBounds:]
    1028cc:	adrp	x8, 637 ; 0x37f000
    1028d0:	ldr	x0, [x8, #0x818] ; Objc class ref: _OBJC_CLASS_$_UIColor
    1028d4:	adrp	x8, 635 ; 0x37d000
    1028d8:	ldr	x1, [x8, #0xb68] ; Objc selector ref: colorWithRed:green:blue:alpha:
    1028dc:	adrp	x8, 525 ; 0x30f000
    1028e0:	ldr	d0, [x8, #0xad8]
    1028e4:	nop
    1028e8:	ldr	d1, [x8, #0xae0]
    ...
    102e64:	ldr	x10, [x10, #0x2f0] ; Objc selector ref: view
    102e68:	str	x10, [sp, #0xb8]
    102e6c:	adrp	x10, 635 ; 0x37d000
    102e70:	adrp	x11, 636 ; 0x37e000
    102e74:	adrp	x12, 635 ; 0x37d000
    102e78:	ldr	x12, [x12, #0xa80] ; Objc selector ref: addSubview:
    102e7c:	str	x12, [sp, #0x1c8]
    102e80:	adrp	x12, 636 ; 0x37e000
    102e84:	eor	w13, w13, #0x1
    102e88:	str	w13, [sp, #0x94]
    102e8c:	adrp	x13, 635 ; 0x37d000
    102e90:	ldr	x23, [x13, #0xbe8] ; Objc selector ref: addObject:
    102e94:	adrp	x13, 636 ; 0x37e000
    102e98:	adrp	x14, 636 ; 0x37e000

## CBBridgedSplitApp.startInParentViewController: @ 0x10bb1c
- Original instructions: 244; selected callsite markers: 2

    ...
    10bd88:	adrp	x8, 626 ; 0x37d000
    10bd8c:	ldr	x1, [x8, #0x9b0] ; Objc selector ref: bounds
    10bd90:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    10bd94:	ldr	x0, [x22, x20]
    10bd98:	adrp	x8, 626 ; 0x37d000
    10bd9c:	ldr	x1, [x8, #0xa10] ; Objc selector ref: setFrame:
    10bda0:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    10bda4:	mov	x0, x19
    10bda8:	bl	0x2ecd30 ; symbol stub for: _objc_release
    10bdac:	ldr	x0, [x22, x20]
    10bdb0:	adrp	x8, 626 ; 0x37d000
    10bdb4:	ldr	x1, [x8, #0xa18] ; Objc selector ref: layer
    10bdb8:	bl	0x2ecd00 ; Objc message: -[x0 layer]
    10bdbc:	mov	x29, x29
    10bdc0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue

## CBBridgedUIAppView.startInParentViewController: @ 0xadf30
- Original instructions: 1056; selected callsite markers: 7

    ...
    ae400:	mov	x0, x19
    ae404:	bl	0x2ecd00 ; Objc message: -[x0 numberWithBool:]
    ae408:	cbz	w0, 0xae420
    ae40c:	ldr	x2, [x20, x22]
    ae410:	adrp	x8, 720 ; 0x37e000
    ae414:	ldr	x1, [x8, #0x3d8] ; Objc selector ref: addChildViewController:
    ae418:	mov	x0, x19
    ae41c:	bl	0x2ecd00 ; Objc message: -[x0 addChildViewController:]
    ae420:	ldr	x0, [x20, x22]
    ae424:	adrp	x8, 720 ; 0x37e000
    ae428:	ldr	x21, [x8, #0x3e0] ; Objc selector ref: setIgnoresOcclusions:
    ae42c:	adrp	x8, 719 ; 0x37d000
    ae430:	ldr	x24, [x8, #0x5d8] ; Objc selector ref: respondsToSelector:
    ae434:	mov	x1, x24
    ae438:	mov	x2, x21
    ae43c:	bl	0x2ecd00 ; Objc message: -[x0 respondsToSelector:]
    ...
    ae504:	mov	x29, x29
    ae508:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ae50c:	str	x0, [sp, #0x38]
    ae510:	ldr	x0, [x20, x22]
    ae514:	adrp	x8, 720 ; 0x37e000
    ae518:	ldr	x21, [x8, #0x3f0] ; Objc selector ref: setRequestedMode:
    ae51c:	mov	x1, x24
    ae520:	mov	x2, x21
    ae524:	bl	0x2ecd00 ; Objc message: -[x0 setRequestedMode:]
    ae528:	cbz	w0, 0xae53c
    ae52c:	ldr	x0, [x20, x22]
    ae530:	mov	x1, x21
    ae534:	mov	w2, #0x2
    ae538:	bl	0x2ecd00 ; Objc message: -[x0 setRequestedMode:]
    ae53c:	str	x26, [sp, #0x20]
    ae540:	str	x19, [sp, #0x48]
    ae544:	mov	x0, #0x0
    ae548:	mov	w1, #0x0
    ae54c:	bl	0x2ecb5c ; symbol stub for: _dlopen
    ae550:	adrp	x1, 601 ; 0x307000
    ae554:	add	x1, x1, #0x8f5 ; literal pool for: "BKSDisplayServicesSetScreenBlanked"
    ae558:	bl	0x2ecb68 ; symbol stub for: _dlsym
    ...
    ae630:	bl	0x2ecd00 ; Objc message: -[x0 setTransform:]
    ae634:	ldr	x0, [x20, x26]
    ae638:	mov	x1, x23
    ae63c:	bl	0x2ecd00 ; Objc message: -[x0 setTransform:]
    ae640:	adrp	x8, 719 ; 0x37d000
    ae644:	ldr	x1, [x8, #0xa10] ; Objc selector ref: setFrame:
    ae648:	mov	x0, x28
    ae64c:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    ae650:	adrp	x8, 719 ; 0x37d000
    ae654:	ldr	x1, [x8, #0xdc0] ; Objc selector ref: setAutoresizingMask:
    ae658:	mov	x0, x28
    ae65c:	mov	w2, #0x12
    ae660:	bl	0x2ecd00 ; Objc message: -[x0 setAutoresizingMask:]
    ae664:	ldr	x0, [x20, x26]
    ae668:	ldr	x21, [x19, #0xa80]
    ae66c:	mov	x1, x21

## CBBridgeManager.loadNewAppFromCurrentRequest: @ 0x153544
- Original instructions: 24855; selected callsite markers: 0

- No matching input-attachment selector/class marker observed in this IMP.

