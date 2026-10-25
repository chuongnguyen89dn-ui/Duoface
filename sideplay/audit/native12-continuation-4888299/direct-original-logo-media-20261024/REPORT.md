# Original Native12: layout and preset ARM64 IMP evidence

- Verified original DEB SHA256: \`2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad\`
- Verified Dashboard SHA256: \`9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea\`
- Original method index blob: \`efa45df59bc3c16887cc979bf3aedc0c93c92111\`
- Exact extracted IMPs: **25**, ARM64 instructions: **26762**
- IMPORTANT: machine disassembly is NOT a runtime preset-frame test.
- A selector in an Objective-C call site does NOT prove a receiver.
- Preset 0..7 formulas in independent DFLayoutEngine remain UNVERIFIED until
  original function control flow and numerical CGRect outputs are derived.
- This artifact contains read-only evidence; no vendor code linked to app.

## CBDividerView.pointInside:withEvent: @ 0xff728
Original ABI: \`B40@0:8{CGPoint=dd}16@32\`
Function boundary: \`0xff728..0xff974\`
Instruction count: **147**; branches **32**;
Potential numerical operations (not yet semantic proof):

    ff728:	sub	sp, sp, #0x160
    ff74c:	add	x29, sp, #0x150
    ff7c4:	mov	w20, #0x0
    ff80c:	add	sp, sp, #0x160
    ff83c:	add	x2, sp, #0x10
    ff840:	add	x3, sp, #0x50
    ff848:	mov	w4, #0x10
    ff864:	fmov	d10, #-12.00000000
    ff868:	mov	x28, #0x0
    ff874:	cmp	x0, #0x1
    ff8e8:	add	x28, x28, #0x1
    ff8f4:	add	x2, sp, #0x10
    ff8f8:	add	x3, sp, #0x50
    ff904:	mov	w4, #0x10
    ff934:	cmp	w8, #0x0
    ff938:	fmov	d5, #-8.00000000
    ff968:	mov	w20, #0x1

Branch samples:
    ff770:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    ff784:	cbz	w8, 0xff7c4
    ff798:	bl	0x2ecd00 ; Objc message: -[x0 isHidden]
    ff79c:	tbnz	w0, #0x0, 0xff7c4
    ff7b0:	bl	0x2ecd00 ; Objc message: -[x0 alpha]
    ff7c0:	b.pl	0xff814
    ff7cc:	bl	0x2ecd30 ; symbol stub for: _objc_release
    ff7e4:	b.ne	0xff970
    ff82c:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    ff84c:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    ff850:	cbz	x0, 0xff910
    ff888:	b.eq	0xff894
    ff890:	bl	0x2eccb8 ; symbol stub for: _objc_enumerationMutation
    ff8a4:	bl	0x2ecd00 ; Objc message: -[x0 frame]
    ff8a8:	tbnz	w0, #0x0, 0xff8e8
    ff8b4:	bl	0x2ecd00 ; Objc message: -[x0 frame]
    ff8bc:	b.le	0xff8e8
    ff8c8:	bl	0x2ecd00 ; Objc message: -[x0 frame]
    ff8d4:	bl	0x2ec8f8 ; symbol stub for: _CGRectInset
    ff8e0:	bl	0x2ec898 ; symbol stub for: _CGRectContainsPoint
    ff8e4:	tbnz	w0, #0x0, 0xff960
    ff8f0:	b.ne	0xff87c
    ff908:	bl	0x2ecd00 ; Objc message: -[x0 frame]
    ff90c:	cbnz	x0, 0xff868
    ff914:	bl	0x2ecd30 ; symbol stub for: _objc_release
    ff924:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    ff948:	bl	0x2ec8f8 ; symbol stub for: _CGRectInset
    ff954:	bl	0x2ec898 ; symbol stub for: _CGRectContainsPoint
    ff95c:	b	0xff7c8
    ff964:	bl	0x2ecd30 ; symbol stub for: _objc_release
    ff96c:	b	0xff7c8
    ff970:	bl	0x2eca9c ; symbol stub for: ___stack_chk_fail

## CBDividerView.hitTest:withEvent: @ 0xff974
Original ABI: \`@40@0:8{CGPoint=dd}16@32\`
Function boundary: \`0xff974..0xffbf8\`
Instruction count: **161**; branches **37**;
Potential numerical operations (not yet semantic proof):

    ff974:	sub	sp, sp, #0x170
    ff99c:	add	x29, sp, #0x160
    ffa54:	add	x2, sp, #0x10
    ffa58:	add	x3, sp, #0x50
    ffa60:	mov	w4, #0x10
    ffa74:	fmov	d10, #-12.00000000
    ffa78:	mov	x24, #0x0
    ffa8c:	cmp	x0, #0x1
    ffb20:	add	x24, x24, #0x1
    ffb2c:	add	x2, sp, #0x10
    ffb30:	add	x3, sp, #0x50
    ffb3c:	mov	w4, #0x10
    ffb84:	mov	x20, #0x0
    ffbd0:	add	sp, sp, #0x170

Branch samples:
    ff9c0:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    ff9d4:	bl	0x2ecd00 ; Objc message: -[x0 isUserInteractionEnabled]
    ff9d8:	cbz	w0, 0xffb84
    ff9ec:	bl	0x2ecd00 ; Objc message: -[x0 isHidden]
    ff9f0:	tbnz	w0, #0x0, 0xffb84
    ffa04:	bl	0x2ecd00 ; Objc message: -[x0 alpha]
    ffa14:	b.mi	0xffb84
    ffa24:	cbz	w8, 0xffb84
    ffa44:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    ffa64:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    ffa68:	cbz	x0, 0xffb48
    ffaa0:	b.eq	0xffaac
    ffaa8:	bl	0x2eccb8 ; symbol stub for: _objc_enumerationMutation
    ffabc:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    ffac0:	tbnz	w0, #0x0, 0xffb20
    ffacc:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    ffad4:	b.le	0xffb20
    ffaec:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    ffb00:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    ffb0c:	bl	0x2ec8f8 ; symbol stub for: _CGRectInset
    ffb18:	bl	0x2ec898 ; symbol stub for: _CGRectContainsPoint
    ffb1c:	tbnz	w0, #0x0, 0xffbd8
    ffb28:	b.ne	0xffa94
    ffb40:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    ffb44:	cbnz	x0, 0xffa78
    ffb4c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    ffb6c:	bl	0x2ecd00 ; Objc message: -[x0 pointInside:withEvent:]
    ffb70:	cbz	w0, 0xffb84
    ffb78:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    ffb80:	b	0xffb88
    ffb8c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    ffba4:	b.ne	0xffbf4
    ffbd4:	b	0x2ecc7c ; symbol stub for: _objc_autoreleaseReturnValue
    ffbdc:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    ffbe8:	bl	0x2ecd30 ; symbol stub for: _objc_release
    ffbf0:	b	0xffb88
    ffbf4:	bl	0x2eca9c ; symbol stub for: ___stack_chk_fail

## CBDividerView.configureWithButtonConfigs: @ 0xfea50
Original ABI: \`v24@0:8@16\`
Function boundary: \`0xfea50..0xff410\`
Instruction count: **624**; branches **131**;
Potential numerical operations (not yet semantic proof):

    fea78:	add	x29, sp, #0x90
    fea7c:	sub	sp, sp, #0x300
    feacc:	add	x2, sp, #0x1b0
    fead0:	add	x3, sp, #0x270
    fead8:	mov	w4, #0x10
    feaf4:	mov	x21, #0x0
    feb60:	add	x21, x21, #0x1
    feb6c:	add	x2, sp, #0x1b0
    feb70:	add	x3, sp, #0x270
    feb7c:	mov	w4, #0x10
    fec14:	cmp	w19, #0x0
    fec30:	fmov	d0, #12.50000000
    fec34:	fmov	d1, #11.50000000
    fec44:	mov	w2, #0x7
    fec68:	mov	x24, #0x0
    feca4:	fmov	d0, #15.00000000
    feca8:	fmov	d1, #14.00000000
    fee84:	mov	x2, #0x0
    fefa4:	fmov	d0, #1.00000000
    ff080:	fmov	d1, #1.50000000
    ff0d8:	fmov	d0, #3.00000000
    ff0f0:	mov	w2, #0x0
    ff100:	mov	w2, #0x0
    ff130:	cmp	w8, #0x0
    ff138:	add	x8, x8, #0x1c8 ; Objc cfstring ref: @"arrow.left.arrow.right"
    ff140:	add	x9, x9, #0x1e8 ; Objc cfstring ref: @"arrow.up.arrow.down"
    ff190:	mov	x3, #0x0
    ff1e4:	mov	w4, #0x1
    ff1fc:	mov	w4, #0x40
    ff214:	mov	w4, #0x180
    ff298:	add	x24, x24, #0x1
    ff304:	add	x2, sp, #0x170
    ff308:	add	x3, sp, #0x1f0
    ff310:	mov	w4, #0x10
    ff330:	mov	x27, #0x0
    ff374:	mov	w2, #0x1
    ff37c:	add	x27, x27, #0x1
    ff388:	add	x2, sp, #0x170
    ff38c:	add	x3, sp, #0x1f0
    ff398:	mov	w4, #0x10

Branch samples:
    fea98:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    feabc:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    feadc:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    feae0:	cbz	x0, 0xfeb8c
    feb18:	b.eq	0xfeb24
    feb20:	bl	0x2eccb8 ; symbol stub for: _objc_enumerationMutation
    feb34:	bl	0x2ecd00 ; Objc message: -[x0 removeAllAnimations]
    feb3c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    feb48:	bl	0x2ecd00 ; Objc message: -[x0 removeAllAnimations]
    feb50:	bl	0x2ecd30 ; symbol stub for: _objc_release
    feb5c:	bl	0x2ecd00 ; Objc message: -[x0 removeAllAnimations]
    feb68:	b.lo	0xfeb0c
    feb80:	bl	0x2ecd00 ; Objc message: -[x0 removeAllAnimations]
    feb88:	cbnz	x0, 0xfeaf4
    feb90:	bl	0x2ecd30 ; symbol stub for: _objc_release
    feba8:	bl	0x2ecd00 ; Objc message: -[x0 removeAllObjects]
    febbc:	bl	0x2ecd00 ; Objc message: -[x0 removeAllObjects]
    febc4:	cbz	x26, 0xff3bc
    febd8:	bl	0x2ecd00 ; Objc message: -[x0 count]
    febdc:	cbz	x0, 0xff3bc
    febf0:	bl	0x2ecd00 ; Objc message: -[x0 addObjectsFromArray:]
    fec10:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    fec48:	bl	0x2ecd00 ; Objc message: +[UIImageSymbolConfiguration configurationWithPointSize:weight:]
    fec50:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    fec60:	bl	0x2ecd00 ; Objc message: -[x0 configurationWithPointSize:weight:]
    fec64:	cbz	x0, 0xff2b4
    fee68:	bl	0x2ecd00 ; Objc message: -[x0 addSubview:]
    fee70:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    fee88:	bl	0x2ecd00 ; Objc message: +[UIButton addSubview:]
    fee90:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    feeac:	bl	0x2ecd00 ; Objc message: -[x0 addSubview:]
    feeb4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    feec8:	bl	0x2ecd00 ; Objc message: -[x0 addSubview:]
    feed0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    feee0:	bl	0x2ecd00 ; Objc message: -[x0 addSubview:]
    feeec:	bl	0x2ecd00 ; Objc message: -[x0 addSubview:]
    feef4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    fef04:	bl	0x2ecd00 ; Objc message: -[x0 addSubview:]
    fef0c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    fef18:	bl	0x2ecd00 ; Objc message: -[x0 addSubview:]

## CBDividerView.moveButtonTouchDown: @ 0xffbf8
Original ABI: \`v24@0:8@16\`
Function boundary: \`0xffbf8..0xffcf4\`
Instruction count: **63**; branches **13**;
Potential numerical operations (not yet semantic proof):

    ffbf8:	sub	sp, sp, #0x60
    ffc08:	add	x29, sp, #0x50
    ffc94:	add	x9, x9, #0x658
    ffcc0:	add	x2, sp, #0x8
    ffcec:	add	sp, sp, #0x60

Branch samples:
    ffc14:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    ffc2c:	bl	0x2ecd00 ; Objc message: -[x0 onActivity]
    ffc34:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ffc3c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    ffc40:	cbz	x22, 0xffc6c
    ffc4c:	bl	0x2ecd00 ; Objc message: -[x0 onActivity]
    ffc54:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ffc60:	blr	x8
    ffc68:	bl	0x2ecd30 ; symbol stub for: _objc_release
    ffcb0:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    ffccc:	bl	0x2ecd00 ; Objc message: +[UIView animateWithDuration:animations:]
    ffcd4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    ffcdc:	bl	0x2ecd30 ; symbol stub for: _objc_release

## CBDividerView.moveButtonTouchUp: @ 0xffeb4
Original ABI: \`v24@0:8@16\`
Function boundary: \`0xffeb4..0x1000c4\`
Instruction count: **132**; branches **30**;
Potential numerical operations (not yet semantic proof):

    ffeb4:	sub	sp, sp, #0xa0
    ffec8:	add	x29, sp, #0x90
    fff58:	add	x9, x9, #0x7b8
    fff84:	add	x9, x9, #0x68
    fffc0:	add	x3, sp, #0x30
    fffcc:	mov	w2, #0x20000
    ffff0:	mov	x8, #0x7fffffffffffffff
    1000bc:	add	sp, sp, #0xa0

Branch samples:
    ffed4:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    ffeec:	bl	0x2ecd00 ; Objc message: -[x0 onActivity]
    ffef4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ffefc:	bl	0x2ecd30 ; symbol stub for: _objc_release
    fff00:	cbz	x22, 0xfff2c
    fff0c:	bl	0x2ecd00 ; Objc message: -[x0 onActivity]
    fff14:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    fff20:	blr	x8
    fff28:	bl	0x2ecd30 ; symbol stub for: _objc_release
    fff68:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    fff90:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    fffd0:	bl	0x2ecd00 ; Objc message: -[x0 animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:]
    fffec:	bl	0x2ecd00 ; Objc message: -[x0 indexOfObject:]
    ffff8:	b.eq	0x100094
    100014:	bl	0x2ecd00 ; Objc message: -[x0 count]
    10001c:	b.hs	0x100094
    100030:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    100038:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    10004c:	bl	0x2ecd00 ; Objc message: -[x0 onSwap]
    100054:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    10005c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    100060:	cbz	x22, 0x10008c
    10006c:	bl	0x2ecd00 ; Objc message: -[x0 onSwap]
    100074:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    100080:	blr	x8
    100088:	bl	0x2ecd30 ; symbol stub for: _objc_release
    100090:	bl	0x2ecd30 ; symbol stub for: _objc_release
    100098:	bl	0x2ecd30 ; symbol stub for: _objc_release
    1000a0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    1000a8:	bl	0x2ecd30 ; symbol stub for: _objc_release

## CBDividerView.moveButtonTouchCancelled: @ 0x1002e0
Original ABI: \`v24@0:8@16\`
Function boundary: \`0x1002e0..0x1003d8\`
Instruction count: **62**; branches **7**;
Potential numerical operations (not yet semantic proof):

    1002e0:	sub	sp, sp, #0xa0
    1002f4:	add	x29, sp, #0x90
    100330:	add	x9, x9, #0x7b8
    100358:	add	x9, x9, #0x68
    100390:	add	x3, sp, #0x30
    1003a0:	mov	w2, #0x20000
    1003d0:	add	sp, sp, #0xa0

Branch samples:
    100300:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    10033c:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    10036c:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    1003a4:	bl	0x2ecd00 ; Objc message: -[x0 animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:]
    1003ac:	bl	0x2ecd30 ; symbol stub for: _objc_release
    1003b4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    1003bc:	bl	0x2ecd30 ; symbol stub for: _objc_release

## CBDividerView.handleMoveButtonLongPress: @ 0x1005f4
Original ABI: \`v24@0:8@16\`
Function boundary: \`0x1005f4..0x100860\`
Instruction count: **155**; branches **41**;
Potential numerical operations (not yet semantic proof):

    1005f4:	sub	sp, sp, #0xa0
    10060c:	add	x29, sp, #0x90
    10062c:	cmp	x0, #0x1
    1006bc:	mov	x8, #0x7fffffffffffffff
    100738:	add	x9, x9, #0x658
    100760:	add	x9, x9, #0x818
    100780:	add	x2, sp, #0x28
    100858:	add	sp, sp, #0xa0

Branch samples:
    100618:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    100628:	bl	0x2ecd00 ; Objc message: -[x0 state]
    100630:	b.ne	0x10083c
    100644:	bl	0x2ecd00 ; Objc message: -[x0 onActivity]
    10064c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    100654:	bl	0x2ecd30 ; symbol stub for: _objc_release
    100658:	cbz	x22, 0x100684
    100664:	bl	0x2ecd00 ; Objc message: -[x0 onActivity]
    10066c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    100678:	blr	x8
    100680:	bl	0x2ecd30 ; symbol stub for: _objc_release
    100690:	bl	0x2ecd00 ; Objc message: -[x0 view]
    100698:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    1006b8:	bl	0x2ecd00 ; Objc message: -[x0 indexOfObject:]
    1006c4:	b.eq	0x100834
    1006e0:	bl	0x2ecd00 ; Objc message: -[x0 count]
    1006e8:	b.hs	0x100834
    1006fc:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    100704:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    100744:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    100768:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    10078c:	bl	0x2ecd00 ; Objc message: +[UIView animateWithDuration:animations:completion:]
    1007a0:	bl	0x2ecd00 ; Objc message: -[x0 onRotate]
    1007a8:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    1007b0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    1007b4:	cbz	x23, 0x1007cc
    1007c0:	bl	0x2ecd00 ; Objc message: -[x0 onRotate]
    1007c8:	b	0x100804
    1007dc:	bl	0x2ecd00 ; Objc message: -[x0 onSwap]
    1007e4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    1007ec:	bl	0x2ecd30 ; symbol stub for: _objc_release
    1007f0:	cbz	x23, 0x10081c
    1007fc:	bl	0x2ecd00 ; Objc message: -[x0 onSwap]
    100804:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    100810:	blr	x8
    100818:	bl	0x2ecd30 ; symbol stub for: _objc_release
    100820:	bl	0x2ecd30 ; symbol stub for: _objc_release
    100828:	bl	0x2ecd30 ; symbol stub for: _objc_release
    100830:	bl	0x2ecd30 ; symbol stub for: _objc_release
    100838:	bl	0x2ecd30 ; symbol stub for: _objc_release

## CBDividerView.handlePan: @ 0x10152c
Original ABI: \`v24@0:8@16\`
Function boundary: \`0x10152c..0x101668\`
Instruction count: **79**; branches **23**;
Potential numerical operations (not yet semantic proof):

    10153c:	add	x29, sp, #0x30

Branch samples:
    101548:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    101560:	bl	0x2ecd00 ; Objc message: -[x0 onActivity]
    101568:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    101570:	bl	0x2ecd30 ; symbol stub for: _objc_release
    101574:	cbz	x22, 0x1015a0
    101580:	bl	0x2ecd00 ; Objc message: -[x0 onActivity]
    101588:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    101594:	blr	x8
    10159c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    1015ac:	bl	0x2ecd00 ; Objc message: -[x0 superview]
    1015b4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    1015cc:	bl	0x2ecd00 ; Objc message: -[x0 translationInView:]
    1015dc:	bl	0x2ecd30 ; symbol stub for: _objc_release
    1015f0:	bl	0x2ecd00 ; Objc message: -[x0 onPanChanged]
    1015f8:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    101600:	bl	0x2ecd30 ; symbol stub for: _objc_release
    101604:	cbz	x22, 0x101650
    101610:	bl	0x2ecd00 ; Objc message: -[x0 onPanChanged]
    101618:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    10162c:	bl	0x2ecd00 ; Objc message: -[x0 state]
    101644:	blr	x8
    10164c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    101664:	b	0x2ecd30 ; symbol stub for: _objc_release

## CBDividerView.updateGripLayout @ 0xff460
Original ABI: \`v16@0:8\`
Function boundary: \`0xff460..0xff728\`
Instruction count: **178**; branches **30**;
Potential numerical operations (not yet semantic proof):

    ff460:	sub	sp, sp, #0xc0
    ff48c:	add	x29, sp, #0xb0
    ff4b4:	cmp	w21, #0x0
    ff4c8:	fmov	d0, #30.00000000
    ff4cc:	fmov	d1, #28.00000000
    ff4f4:	mov	x21, #0x0
    ff510:	fmov	d11, #0.50000000
    ff528:	fmov	d13, #4.00000000
    ff52c:	fmov	d14, #-4.00000000
    ff530:	fmov	d15, #1.00000000
    ff598:	fcmp	d0, #0.0
    ff6d4:	add	x21, x21, #0x1
    ff720:	add	sp, sp, #0xc0

Branch samples:
    ff4b0:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    ff4ec:	bl	0x2ecd00 ; Objc message: -[x0 count]
    ff4f0:	cbz	x0, 0xff6f8
    ff53c:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    ff544:	b.hs	0xff6f8
    ff55c:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    ff564:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ff57c:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    ff584:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    ff594:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    ff5a0:	b.lt	0xff5cc
    ff5ac:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    ff5b8:	b.hi	0xff5cc
    ff5c4:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    ff5e0:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    ff5e4:	cbz	w23, 0xff648
    ff600:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    ff60c:	b.le	0xff624
    ff618:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    ff62c:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    ff644:	b	0xff6a4
    ff660:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    ff66c:	b.le	0xff684
    ff678:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    ff68c:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    ff6c0:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    ff6c8:	bl	0x2ecd30 ; symbol stub for: _objc_release
    ff6d0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    ff6e4:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    ff6f4:	b.lo	0xff534

## CBDividerView.moveButtons @ 0x1016a8
Original ABI: \`@16@0:8\`
Function boundary: \`0x1016a8..0x1016b8\`
Instruction count: **4**; branches **0**;
Potential numerical operations (not yet semantic proof):


Branch samples:

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

## CBDividerView.startBlinking @ 0x1009d4
Original ABI: \`v16@0:8\`
Function boundary: \`0x1009d4..0x100e30\`
Instruction count: **279**; branches **48**;
Potential numerical operations (not yet semantic proof):

    1009fc:	add	x29, sp, #0x90
    100a00:	sub	sp, sp, #0x1d0
    100a1c:	mov	w9, #0x1
    100a4c:	add	x2, sp, #0x100
    100a50:	add	x3, sp, #0x140
    100a58:	mov	w4, #0x10
    100a7c:	fmov	d8, #1.00000000
    100ad0:	mov	x24, #0x0
    100ba4:	mov	w2, #0x0
    100bd0:	add	x2, sp, #0xd0
    100ca8:	fmov	d0, #1.50000000
    100d40:	fmov	d0, #2.50000000
    100d50:	add	x24, x24, #0x1
    100d60:	add	x2, sp, #0x100
    100d64:	add	x3, sp, #0x140
    100d6c:	mov	w4, #0x10
    100dac:	add	x9, x9, #0x658
    100dd4:	add	x3, sp, #0xa8
    100dd8:	mov	w2, #0x1e
    100ddc:	mov	x4, #0x0
    100dfc:	add	sp, sp, #0x1d0

Branch samples:
    100a40:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    100a5c:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    100a64:	cbz	x0, 0x100d7c
    100b60:	b.eq	0x100b6c
    100b68:	bl	0x2eccb8 ; symbol stub for: _objc_enumerationMutation
    100b7c:	bl	0x2ecd00 ; Objc message: -[x0 setShadowOpacity:]
    100b84:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    100b90:	bl	0x2ecd00 ; Objc message: -[x0 setShadowOpacity:]
    100b98:	bl	0x2ecd30 ; symbol stub for: _objc_release
    100ba8:	bl	0x2ecd00 ; Objc message: -[x0 setShadowOpacity:]
    100bb8:	bl	0x2ecd00 ; Objc message: -[x0 setShadowOpacity:]
    100bdc:	bl	0x2ecd00 ; Objc message: -[x0 setShadowOpacity:]
    100bf8:	bl	0x2ecd00 ; Objc message: -[x0 setShadowOpacity:]
    100c00:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    100c14:	bl	0x2ecd00 ; Objc message: -[x0 setShadowOpacity:]
    100c1c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    100c38:	bl	0x2ecd00 ; Objc message: -[x0 setShadowOpacity:]
    100c40:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    100c44:	bl	0x2ecd48 ; symbol stub for: _objc_retainAutorelease
    100c50:	bl	0x2ecd00 ; Objc message: -[x0 setShadowOpacity:]
    100c60:	bl	0x2ecd00 ; Objc message: -[x0 setShadowOpacity:]
    100c68:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    100c78:	bl	0x2ecd00 ; Objc message: -[x0 setShadowOpacity:]
    100c80:	bl	0x2ecd30 ; symbol stub for: _objc_release
    100c88:	bl	0x2ecd30 ; symbol stub for: _objc_release
    100c94:	bl	0x2ecd00 ; Objc message: -[x0 setShadowOpacity:]
    100c9c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    100cac:	bl	0x2ecd00 ; Objc message: -[x0 setShadowOpacity:]
    100cb4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    100cd0:	bl	0x2ecd00 ; Objc message: -[x0 setShadowOpacity:]
    100cd8:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    100cec:	bl	0x2ecd00 ; Objc message: -[x0 setShadowOpacity:]
    100cf4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    100d00:	bl	0x2ecd00 ; Objc message: -[x0 setShadowOpacity:]
    100d08:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    100d18:	bl	0x2ecd00 ; Objc message: -[x0 setShadowOpacity:]
    100d20:	bl	0x2ecd30 ; symbol stub for: _objc_release
    100d2c:	bl	0x2ecd00 ; Objc message: -[x0 setShadowOpacity:]
    100d34:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    100d44:	bl	0x2ecd00 ; Objc message: -[x0 setShadowOpacity:]

## CBDividerView.stopBlinking @ 0x1010bc
Original ABI: \`v16@0:8\`
Function boundary: \`0x1010bc..0x101288\`
Instruction count: **115**; branches **16**;
Potential numerical operations (not yet semantic proof):

    1010bc:	sub	sp, sp, #0x190
    1010d8:	add	x29, sp, #0x180
    101124:	add	x2, sp, #0x60
    101128:	add	x3, sp, #0xa0
    101130:	mov	w4, #0x10
    101150:	mov	x19, #0x0
    1011a0:	add	x19, x19, #0x1
    1011ac:	add	x2, sp, #0x60
    1011b0:	add	x3, sp, #0xa0
    1011bc:	mov	w4, #0x10
    101200:	add	x10, x10, #0x658
    101220:	add	x9, x9, #0x818
    101240:	add	x2, sp, #0x38
    101244:	add	x3, sp, #0x10
    10127c:	add	sp, sp, #0x190

Branch samples:
    101114:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    101134:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    101138:	cbz	x0, 0x1011cc
    101168:	b.eq	0x101174
    101170:	bl	0x2eccb8 ; symbol stub for: _objc_enumerationMutation
    101180:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    101188:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    101194:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    10119c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    1011a8:	b.lo	0x10115c
    1011c0:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    1011c8:	cbnz	x0, 0x101150
    1011d0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    101248:	bl	0x2ecd00 ; Objc message: +[UIView animateWithDuration:animations:completion:]
    101260:	b.ne	0x101284
    101284:	bl	0x2eca9c ; symbol stub for: ___stack_chk_fail

## CBBridgedSplitApp.noteUserActivity @ 0x10c378
Original ABI: \`v16@0:8\`
Function boundary: \`0x10c378..0x10c454\`
Instruction count: **55**; branches **9**;
Potential numerical operations (not yet semantic proof):

    10c378:	sub	sp, sp, #0x50
    10c384:	add	x29, sp, #0x40
    10c3d8:	fmov	d2, #0.25000000
    10c3fc:	add	sp, sp, #0x50
    10c428:	add	x9, x9, #0x658
    10c43c:	add	x1, sp, #0x8
    10c44c:	add	sp, sp, #0x50

Branch samples:
    10c39c:	bl	0x2ecd00 ; Objc message: +[NSThread isMainThread]
    10c3a0:	tbz	w0, #0x0, 0x10c404
    10c3b0:	cbz	x0, 0x10c3c4
    10c3bc:	bl	0x2ecd00 ; Objc message: -[x0 isDismissing]
    10c3c0:	cbz	w0, 0x10c444
    10c3c4:	bl	0x2ec778 ; symbol stub for: _CACurrentMediaTime
    10c3e0:	b.mi	0x10c444
    10c400:	b	0x2ecd00 ; Objc message: -[x0 startBlinkingSession]
    10c440:	bl	0x2ecb2c ; symbol stub for: _dispatch_async

## CBBridgedSplitApp.startBlinkingSession @ 0x10c464
Original ABI: \`v16@0:8\`
Function boundary: \`0x10c464..0x11f3e8\`
Instruction count: **19425**; branches **1338**;
Potential numerical operations (not yet semantic proof):

    10c480:	add	x29, sp, #0x60
    10c484:	sub	sp, sp, #0x1, lsl #12
    10c488:	sub	sp, sp, #0xa70
    10c4d8:	add	x28, sp, #0x120
    10c508:	mov	w9, #0x1
    10c538:	add	x2, sp, #0x1a0
    10c53c:	add	x3, sp, #0x340
    10c544:	mov	w4, #0x10
    10c560:	mov	x25, #0x0
    10c590:	add	x25, x25, #0x1
    10c59c:	add	x2, sp, #0x1a0
    10c5a0:	add	x3, sp, #0x340
    10c5ac:	mov	w4, #0x10
    10c5e4:	add	x2, sp, #0x160
    10c5e8:	add	x3, sp, #0x2c0
    10c5f0:	mov	w4, #0x10
    10c60c:	mov	x25, #0x0
    10c640:	add	x25, x25, #0x1
    10c64c:	add	x2, sp, #0x160
    10c650:	add	x3, sp, #0x2c0
    10c65c:	mov	w4, #0x10
    10c6a0:	add	x2, sp, #0x120
    10c6a4:	add	x3, sp, #0x240
    10c6ac:	mov	w4, #0x10
    10c6c4:	mov	x19, #0x0
    10c730:	mov	w2, #0x0
    10c738:	add	x19, x19, #0x1
    10c744:	add	x2, sp, #0x120
    10c748:	add	x3, sp, #0x240
    10c754:	mov	w4, #0x10
    10c794:	add	x9, x9, #0x658
    10c7b0:	fmov	d0, #0.25000000
    10c7b4:	add	x2, sp, #0xf8
    10c7bc:	add	x0, sp, #0xf0
    10c7d4:	cmp	w8, #0x1
    10c7e0:	mov	x0, #0x0
    10c7f8:	mov	w9, #0x1
    10c7fc:	movk	w9, #0xcbdb, lsl #16
    10c804:	cmp	w8, #0x0
    10c808:	mov	w9, #0x1337

Branch samples:
    10c4b0:	bl	0x2ecd00 ; Objc message: +[NSThread isMainThread]
    10c4b4:	tbz	w0, #0x0, 0x10c920
    10c4c4:	cbz	x0, 0x10c4d8
    10c4d0:	bl	0x2ecd00 ; Objc message: -[x0 isDismissing]
    10c4d4:	cbz	w0, 0x10c960
    10c4f0:	bl	0x2ecd00 ; Objc message: -[x0 invalidate]
    10c4fc:	bl	0x2ecd30 ; symbol stub for: _objc_release
    10c528:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    10c548:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    10c54c:	cbz	x0, 0x10c5bc
    10c574:	b.eq	0x10c580
    10c57c:	bl	0x2eccb8 ; symbol stub for: _objc_enumerationMutation
    10c58c:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    10c598:	b.lo	0x10c568
    10c5b0:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    10c5b8:	cbnz	x0, 0x10c560
    10c5c0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    10c5dc:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    10c5f4:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    10c5f8:	cbz	x0, 0x10c66c
    10c620:	b.eq	0x10c62c
    10c628:	bl	0x2eccb8 ; symbol stub for: _objc_enumerationMutation
    10c63c:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    10c648:	b.lo	0x10c614
    10c660:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    10c668:	cbnz	x0, 0x10c60c
    10c674:	bl	0x2ecd30 ; symbol stub for: _objc_release
    10c698:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    10c6b0:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    10c6b4:	cbz	x0, 0x10c764
    10c6ec:	b.eq	0x10c6f8
    10c6f4:	bl	0x2eccb8 ; symbol stub for: _objc_enumerationMutation
    10c708:	bl	0x2ecd00 ; Objc message: -[x0 setHidden:]
    10c710:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    10c71c:	bl	0x2ecd00 ; Objc message: -[x0 setHidden:]
    10c724:	bl	0x2ecd30 ; symbol stub for: _objc_release
    10c734:	bl	0x2ecd00 ; Objc message: -[x0 setHidden:]
    10c740:	b.lo	0x10c6e0
    10c758:	bl	0x2ecd00 ; Objc message: -[x0 setHidden:]
    10c760:	cbnz	x0, 0x10c6c4

## CBBridgedSplitApp.stopBlinkingSession @ 0x11f558
Original ABI: \`v16@0:8\`
Function boundary: \`0x11f558..0x11f828\`
Instruction count: **180**; branches **29**;
Potential numerical operations (not yet semantic proof):

    11f570:	add	x29, sp, #0x50
    11f574:	sub	sp, sp, #0x200
    11f5fc:	add	x2, sp, #0x90
    11f600:	sub	x3, x29, #0xd8
    11f608:	mov	w4, #0x10
    11f624:	mov	x26, #0x0
    11f654:	add	x26, x26, #0x1
    11f660:	add	x2, sp, #0x90
    11f664:	sub	x3, x29, #0xd8
    11f670:	mov	w4, #0x10
    11f6a8:	add	x2, sp, #0x50
    11f6ac:	add	x3, sp, #0xf8
    11f6b4:	mov	w4, #0x10
    11f6d0:	mov	x26, #0x0
    11f704:	add	x26, x26, #0x1
    11f710:	add	x2, sp, #0x50
    11f714:	add	x3, sp, #0xf8
    11f720:	mov	w4, #0x10
    11f764:	add	x10, x10, #0x658
    11f780:	add	x9, x9, #0x818
    11f79c:	add	x2, sp, #0x28
    11f7d0:	add	x9, x9, #0x658
    11f7e4:	add	x1, sp, #0xd0
    11f804:	add	sp, sp, #0x200

Branch samples:
    11f59c:	bl	0x2ecd00 ; Objc message: +[NSThread isMainThread]
    11f5a0:	tbz	w0, #0x0, 0x11f7ac
    11f5b8:	bl	0x2ecd00 ; Objc message: -[x0 invalidate]
    11f5c4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    11f5ec:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    11f60c:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    11f610:	cbz	x0, 0x11f680
    11f638:	b.eq	0x11f644
    11f640:	bl	0x2eccb8 ; symbol stub for: _objc_enumerationMutation
    11f650:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    11f65c:	b.lo	0x11f62c
    11f674:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    11f67c:	cbnz	x0, 0x11f624
    11f684:	bl	0x2ecd30 ; symbol stub for: _objc_release
    11f6a0:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    11f6b8:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    11f6bc:	cbz	x0, 0x11f730
    11f6e4:	b.eq	0x11f6f0
    11f6ec:	bl	0x2eccb8 ; symbol stub for: _objc_enumerationMutation
    11f700:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    11f70c:	b.lo	0x11f6d8
    11f724:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    11f72c:	cbnz	x0, 0x11f6d0
    11f734:	bl	0x2ecd30 ; symbol stub for: _objc_release
    11f7a4:	bl	0x2ecd00 ; Objc message: +[UIView animateWithDuration:animations:completion:]
    11f7a8:	b	0x11f7ec
    11f7e8:	bl	0x2ecb2c ; symbol stub for: _dispatch_async
    11f800:	b.ne	0x11f824
    11f824:	bl	0x2eca9c ; symbol stub for: ___stack_chk_fail

## CBBridgedSplitApp.startContainerBorderBlinking: @ 0x11fa88
Original ABI: \`v24@0:8@16\`
Function boundary: \`0x11fa88..0x11fcd4\`
Instruction count: **147**; branches **32**;
Potential numerical operations (not yet semantic proof):

    11faa4:	add	x29, sp, #0x60
    11fae4:	add	x22, x22, #0x268 ; Objc cfstring ref: @"borderPulse"
    11fb0c:	add	x2, x2, #0x288 ; Objc cfstring ref: @"borderColor"
    11fba0:	fmov	d2, #1.00000000
    11fbf0:	fmov	d0, #0.50000000
    11fc08:	mov	w2, #0x1
    11fc18:	mov	w8, #0x7f800000

Branch samples:
    11fab8:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    11fac8:	bl	0x2ecd00 ; Objc message: -[x0 layer]
    11fad0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    11faec:	bl	0x2ecd00 ; Objc message: -[x0 removeAnimationForKey:]
    11faf4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    11fb10:	bl	0x2ecd00 ; Objc message: +[CABasicAnimation animationWithKeyPath:]
    11fb18:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    11fb54:	bl	0x2ecd00 ; Objc message: +[UIColor colorWithRed:green:blue:alpha:]
    11fb5c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    11fb60:	bl	0x2ecd48 ; symbol stub for: _objc_retainAutorelease
    11fb74:	bl	0x2ecd00 ; Objc message: -[x0 CGColor]
    11fb88:	bl	0x2ecd00 ; Objc message: -[x0 setFromValue:]
    11fb90:	bl	0x2ecd30 ; symbol stub for: _objc_release
    11fbb0:	bl	0x2ecd00 ; Objc message: -[x0 setFromValue:]
    11fbb8:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    11fbbc:	bl	0x2ecd48 ; symbol stub for: _objc_retainAutorelease
    11fbc8:	bl	0x2ecd00 ; Objc message: -[x0 setFromValue:]
    11fbdc:	bl	0x2ecd00 ; Objc message: -[x0 setToValue:]
    11fbe4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    11fbf8:	bl	0x2ecd00 ; Objc message: -[x0 setDuration:]
    11fc0c:	bl	0x2ecd00 ; Objc message: -[x0 setAutoreverses:]
    11fc24:	bl	0x2ecd00 ; Objc message: -[x0 setRepeatCount:]
    11fc44:	bl	0x2ecd00 ; Objc message: +[CAMediaTimingFunction functionWithName:]
    11fc4c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    11fc64:	bl	0x2ecd00 ; Objc message: -[x0 setTimingFunction:]
    11fc6c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    11fc78:	bl	0x2ecd00 ; Objc message: -[x0 setTimingFunction:]
    11fc80:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    11fc8c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    11fca4:	bl	0x2ecd00 ; Objc message: -[x0 addAnimation:forKey:]
    11fcac:	bl	0x2ecd30 ; symbol stub for: _objc_release
    11fcd0:	b	0x2ecd30 ; symbol stub for: _objc_release

## CBBridgedSplitApp.stopContainerBorderBlinking: @ 0x11fcd4
Original ABI: \`v24@0:8@16\`
Function boundary: \`0x11fcd4..0x11fddc\`
Instruction count: **66**; branches **15**;
Potential numerical operations (not yet semantic proof):

    11fce4:	add	x29, sp, #0x30
    11fd24:	add	x2, x2, #0x268 ; Objc cfstring ref: @"borderPulse"

Branch samples:
    11fcf8:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    11fd08:	bl	0x2ecd00 ; Objc message: -[x0 layer]
    11fd10:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    11fd28:	bl	0x2ecd00 ; Objc message: -[x0 removeAnimationForKey:]
    11fd30:	bl	0x2ecd30 ; symbol stub for: _objc_release
    11fd64:	bl	0x2ecd00 ; Objc message: +[UIColor colorWithRed:green:blue:alpha:]
    11fd6c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    11fd70:	bl	0x2ecd48 ; symbol stub for: _objc_retainAutorelease
    11fd80:	bl	0x2ecd00 ; Objc message: -[x0 CGColor]
    11fd90:	bl	0x2ecd00 ; Objc message: -[x0 CGColor]
    11fd98:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    11fda4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    11fdb8:	bl	0x2ecd00 ; Objc message: -[x0 setBorderColor:]
    11fdc0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    11fdd8:	b	0x2ecd30 ; symbol stub for: _objc_release

## CBBridgedSplitApp.configureDividerButtons @ 0x1067a4
Original ABI: \`v16@0:8\`
Function boundary: \`0x1067a4..0x1088b8\`
Instruction count: **2117**; branches **506**;
Potential numerical operations (not yet semantic proof):

    1067cc:	add	x29, sp, #0x90
    1067d0:	sub	sp, sp, #0x550
    106858:	fcmp	d2, #0.0
    1068b4:	fcmp	d3, #0.0
    1068fc:	add	x0, sp, #0x410
    10692c:	add	x9, x9, #0xf98
    106938:	add	x8, sp, #0x3e8
    10693c:	add	x24, x8, #0x20
    106940:	add	x1, sp, #0x410
    106958:	sub	x8, x8, #0x1
    10695c:	cmp	x8, #0x7
    106964:	fmov	d0, #-2.00000000
    10699c:	add	x9, x9, #0x4d8
    1069a8:	add	x10, x10, x11, lsl #2
    1069d0:	mov	x2, #0x0
    106a40:	add	x2, x2, #0x1c8 ; Objc cfstring ref: @"arrow.left.arrow.right"
    106a50:	fmov	d0, #0.50000000
    106a7c:	add	x8, x8, #0xf98
    106a84:	add	x8, sp, #0x3c0
    106a88:	add	x21, x8, #0x20
    106a8c:	add	x1, sp, #0x410
    106aa0:	add	x2, sp, #0x3c0
    106ab4:	add	x2, sp, #0x3e8
    106ac8:	mov	x2, #0x0
    106af0:	sub	x2, x29, #0xa8
    106af4:	mov	w3, #0x1
    106b40:	mov	x2, #0x0
    106bb0:	add	x2, x2, #0x1e8 ; Objc cfstring ref: @"arrow.up.arrow.down"
    106bf0:	add	x8, x8, #0xf98
    106bf8:	add	x8, sp, #0x398
    106bfc:	add	x21, x8, #0x20
    106c00:	add	x1, sp, #0x410
    106c14:	add	x2, sp, #0x398
    106c28:	add	x2, sp, #0x3e8
    106c3c:	mov	x2, #0x0
    106c64:	sub	x2, x29, #0xb0
    106c68:	mov	w3, #0x1
    106cb4:	mov	x2, #0x0
    106d24:	add	x2, x2, #0x1c8 ; Objc cfstring ref: @"arrow.left.arrow.right"
    106d34:	fmov	d0, #0.50000000

Branch samples:
    106804:	bl	0x2ecd00 ; Objc message: -[x0 count]
    106808:	cbz	x0, 0x1086fc
    10681c:	bl	0x2ecd00 ; Objc message: +[CBWindow carPlayUsableBounds]
    106838:	bl	0x2ecd00 ; Objc message: -[x0 view]
    106840:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    106854:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    10685c:	b.le	0x10688c
    106868:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    106870:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    10687c:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    106888:	bl	0x2ecd30 ; symbol stub for: _objc_release
    106890:	bl	0x2ecd30 ; symbol stub for: _objc_release
    10689c:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    1068a4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    1068b0:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    1068b8:	b.le	0x1068e8
    1068c4:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    1068cc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    1068d8:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    1068e4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    1068ec:	bl	0x2ecd30 ; symbol stub for: _objc_release
    106904:	bl	0x2ecce8 ; symbol stub for: _objc_initWeak
    106948:	bl	0x2ecc94 ; symbol stub for: _objc_copyWeak
    106960:	b.hi	0x1071c8
    1069b8:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    1069bc:	cbz	x0, 0x1086e4
    1069d4:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    1069dc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    1069f4:	bl	0x2ecd00 ; Objc message: +[CBDividerView class]
    106a08:	bl	0x2ecd00 ; Objc message: -[x0 isKindOfClass:]
    106a14:	bl	0x2ecd30 ; symbol stub for: _objc_release
    106a18:	cbz	w21, 0x1086e4
    106a2c:	bl	0x2ecd00 ; Objc message: +[CBDividerButtonInfo new]
    106a44:	bl	0x2ecd00 ; Objc message: -[x0 setIconName:]
    106a58:	bl	0x2ecd00 ; Objc message: -[x0 setRelativePos:]
    106a94:	bl	0x2ecc94 ; symbol stub for: _objc_copyWeak
    106aa8:	bl	0x2ecd00 ; Objc message: -[x0 setOnSwap:]
    106abc:	bl	0x2ecd00 ; Objc message: -[x0 setOnRotate:]
    106acc:	bl	0x2ecd00 ; Objc message: -[x0 setOnRotate:]
    106ad4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue

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


## Original binary's verified blink duration/scale literals

Each double is mapped from the exact original Dashboard SHA; selector execution or final idle duration still requires CFG/runtime interpretation.

- `blink_start_animation_duration_100d9c` VM `0x30f968`, file off `0x30f968`: raw double `1.60807493534e-314`, bytes `000000c200000000`; interpretation **AMBIGUOUS_NOT_A_PLAUSIBLE_DURATION**
- `blink_stop_animation_duration_1011ec` VM `0x30f968`, file off `0x30f968`: raw double `1.60807493534e-314`, bytes `000000c200000000`; interpretation **AMBIGUOUS_NOT_A_PLAUSIBLE_DURATION**
- `blink_session_NSTimer_interval_10c848` VM `0x311b20`, file off `0x311b20`: raw double `1000`, bytes `0000000000408f40`; interpretation **RAW_TIMER_LITERAL_NOT_VERIFIED_VISIBLE_IDLE_TIME**
- `blink_grip_scale_100eb8` VM `0x312498`, file off `0x312498`: raw double `1.18`, bytes `e17a14ae47e1f23f`; interpretation **BUTTON_TRANSFORM_SCALE_LITERAL**
