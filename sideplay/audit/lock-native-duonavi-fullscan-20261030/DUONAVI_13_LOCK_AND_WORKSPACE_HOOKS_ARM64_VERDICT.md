# DuoNavi 1.0.4: 13 exact C hook implementations for scene, lock and workspace

Original signed dashboard SHA256: `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`.
C registration proven by previous `EXACT_DUONAVI_REGISTERED_UNDERLOCK_HOOKS.json`
and independent validation against 11 known Native12 originals.
This is read-only ARM64 function evidence, not proof of invocation on a
physical iOS 16 device and not an independent-runtime patch.

## FBScene updateSettings:withTransitionContext:completion: @ 0x2ed0d8
- Registration call PC: 0x2ecf0c
- Original IMP storage: 0x3adfb8
- Original callback may be reached through *indirect* dynamic dispatch.
- Literal strings resolved: ['canShowWhileLocked', 'class', 'deactivationReasons', 'frame', 'idleModeEnabled', 'isForeground', 'isOccluded', 'isUIAppBridging', 'isUnderLock', 'renderSizeForBundleID:', 'setCanShowWhileLocked:', 'setDeactivationReasons:', 'setForeground:', 'setFrame:', 'setIdleModeEnabled:', 'setOccluded:', 'setUnderLock:', 'sharedInstanceIfExists', 'shouldBridge:']
- Conditional zero-return candidate sites: ['0x2ed390: mov w2, #0', '0x2ed440: mov w2, #0', '0x2ed564: mov x2, #0', '0x2ed5f4: mov w2, #0']
- Indirect calls: ['0x2ed650: blr x8']

### Bounded original ARM64
    0x2ed0d8: sub sp, sp, #0x80
    0x2ed0dc: stp d9, d8, [sp, #0x10]
    0x2ed0e0: stp x28, x27, [sp, #0x20]
    0x2ed0e4: stp x26, x25, [sp, #0x30]
    0x2ed0e8: stp x24, x23, [sp, #0x40]
    0x2ed0ec: stp x22, x21, [sp, #0x50]
    0x2ed0f0: stp x20, x19, [sp, #0x60]
    0x2ed0f4: stp x29, x30, [sp, #0x70]
    0x2ed0f8: add x29, sp, #0x70
    0x2ed0fc: mov x23, x4
    0x2ed100: mov x20, x3
    0x2ed104: mov x21, x1
    0x2ed108: mov x22, x0
    0x2ed10c: mov x0, x2
    0x2ed110: bl #0x3137bc
    0x2ed114: mov x19, x0
    0x2ed118: mov x0, x20
    0x2ed11c: bl #0x3137bc
    0x2ed120: mov x20, x0
    0x2ed124: mov x0, x23
    0x2ed128: bl #0x3137bc
    0x2ed12c: mov x23, x0
    0x2ed130: nop 
    0x2ed134: ldr x0, #0x3aab00
    0x2ed138: nop 
    0x2ed13c: ldr x1, #0x3a8e68 ; original literal='sharedInstanceIfExists'
    0x2ed140: bl #0x313780
    0x2ed144: mov x29, x29
    0x2ed148: bl #0x3137e0
    0x2ed14c: mov x24, x0
    0x2ed150: cbz x0, #0x2ed634
    0x2ed154: nop 
    0x2ed158: ldr x1, #0x3a8cf0 ; original literal='isUIAppBridging'
    0x2ed15c: mov x0, x24
    0x2ed160: bl #0x313780
    0x2ed164: cbz w0, #0x2ed634
    0x2ed168: mov x0, x22
    0x2ed16c: bl #0x2eb9d4
    0x2ed170: mov x29, x29
    0x2ed174: bl #0x3137e0
    0x2ed178: mov x25, x0
    0x2ed17c: cbz x0, #0x2ed62c
    0x2ed180: nop 
    0x2ed184: ldr x1, #0x3a9f18 ; original literal='shouldBridge:'
    0x2ed188: mov x0, x24
    0x2ed18c: mov x2, x25
    0x2ed190: bl #0x313780
    0x2ed194: cbz w0, #0x2ed62c
    0x2ed198: mov x0, x22
    0x2ed19c: mov x1, x19
    0x2ed1a0: bl #0x2eeb24
    0x2ed1a4: cbz w0, #0x2ed62c
    0x2ed1a8: nop 
    0x2ed1ac: ldr x1, #0x3a9ef0 ; original literal='renderSizeForBundleID:'
    0x2ed1b0: mov x0, x24
    0x2ed1b4: mov x2, x25
    0x2ed1b8: bl #0x313780
    0x2ed1bc: mov v8.16b, v0.16b
    0x2ed1c0: mov v9.16b, v1.16b
    0x2ed1c4: mov x0, x19
    0x2ed1c8: bl #0x3137bc
    0x2ed1cc: mov x26, x0
    0x2ed1d0: cbz x0, #0x2ed624
    0x2ed1d4: fcmp d8, #0.0
    0x2ed1d8: adrp x8, #0x3a8000
    0x2ed1dc: b.le #0x2ed298
    0x2ed1e0: fcmp d9, #0.0
    0x2ed1e4: b.le #0x2ed298
    0x2ed1e8: nop 
    0x2ed1ec: ldr x2, #0x3a90b0 ; original literal='frame'
    0x2ed1f0: ldr x27, [x8, #0x358]
    0x2ed1f4: mov x0, x26
    0x2ed1f8: mov x1, x27
    0x2ed1fc: bl #0x313780
    0x2ed200: cbz w0, #0x2ed22c
    0x2ed204: adr x0, #0x33aa67
    0x2ed208: nop 
    0x2ed20c: bl #0x313894
    0x2ed210: mov x1, x0
    0x2ed214: mov x0, x26
    0x2ed218: bl #0x313780
    0x2ed21c: fcmp d2, d8
    0x2ed220: b.ne #0x2ed22c
    0x2ed224: fcmp d3, d9
    0x2ed228: b.eq #0x2ed29c
    0x2ed22c: nop 
    0x2ed230: ldr x28, #0x3a87f8 ; original literal='setFrame:'
    0x2ed234: mov x0, x26
    0x2ed238: mov x1, x27
    0x2ed23c: mov x2, x28
    0x2ed240: bl #0x313780
    0x2ed244: cbz w0, #0x2ed264
    0x2ed248: fmov d0, xzr
    0x2ed24c: fmov d1, xzr
    0x2ed250: mov x0, x26
    0x2ed254: mov x1, x28
    0x2ed258: mov v2.16b, v8.16b
    0x2ed25c: mov v3.16b, v9.16b
    0x2ed260: bl #0x313780
    0x2ed264: nop 
    0x2ed268: ldr x1, #0x3a8390 ; original literal='class'
    0x2ed26c: mov x0, x26
    0x2ed270: bl #0x313780
    0x2ed274: adr x1, #0x3326da
    0x2ed278: nop 
    0x2ed27c: bl #0x313528
    0x2ed280: cbz x0, #0x2ed29c
    0x2ed284: bl #0x313648
    0x2ed288: add x8, x0, x26
    0x2ed28c: stp xzr, xzr, [x8]
    0x2ed290: stp d8, d9, [x8, #0x10]
    0x2ed294: b #0x2ed29c
    0x2ed298: ldr x27, [x8, #0x358]
    0x2ed29c: nop 
    0x2ed2a0: ldr x2, #0x3aa5e0 ; original literal='isForeground'
    0x2ed2a4: mov x0, x26
    0x2ed2a8: mov x1, x27
    0x2ed2ac: bl #0x313780
    0x2ed2b0: cbz w0, #0x2ed2d0
    0x2ed2b4: adr x0, #0x33aa6d
    0x2ed2b8: nop 
    0x2ed2bc: bl #0x313894
    0x2ed2c0: mov x1, x0
    0x2ed2c4: mov x0, x26
    0x2ed2c8: bl #0x313780
    0x2ed2cc: tbnz w0, #0, #0x2ed330
    0x2ed2d0: nop 
    0x2ed2d4: ldr x2, #0x3a8e18 ; original literal='setForeground:'
    0x2ed2d8: mov x0, x26
    0x2ed2dc: mov x1, x27
    0x2ed2e0: bl #0x313780
    0x2ed2e4: cbz w0, #0x2ed304
    0x2ed2e8: adr x0, #0x3326e1
    0x2ed2ec: nop 
    0x2ed2f0: bl #0x313894
    0x2ed2f4: mov x1, x0
    0x2ed2f8: mov x0, x26
    0x2ed2fc: mov w2, #1
    0x2ed300: bl #0x313780
    0x2ed304: nop 
    0x2ed308: ldr x1, #0x3a8390 ; original literal='class'
    0x2ed30c: mov x0, x26
    0x2ed310: bl #0x313780
    0x2ed314: adr x1, #0x33aa7a
    0x2ed318: nop 
    0x2ed31c: bl #0x313528
    0x2ed320: cbz x0, #0x2ed330
    0x2ed324: bl #0x313648
    0x2ed328: mov w8, #1
    0x2ed32c: strb w8, [x0, x26]
    0x2ed330: nop 
    0x2ed334: ldr x2, #0x3aa2d0 ; original literal='isOccluded'
    0x2ed338: mov x0, x26
    0x2ed33c: mov x1, x27
    0x2ed340: bl #0x313780
    0x2ed344: cbz w0, #0x2ed364
    0x2ed348: adr x0, #0x33aa86
    0x2ed34c: nop 
    0x2ed350: bl #0x313894
    0x2ed354: mov x1, x0
    0x2ed358: mov x0, x26
    0x2ed35c: bl #0x313780
    0x2ed360: cbz w0, #0x2ed3e0
    0x2ed364: nop 
    0x2ed368: ldr x2, #0x3a8e20 ; original literal='setOccluded:'
    0x2ed36c: mov x0, x26
    0x2ed370: mov x1, x27
    0x2ed374: bl #0x313780
    0x2ed378: cbz w0, #0x2ed398
    0x2ed37c: adr x0, #0x3326f0
    0x2ed380: nop 
    0x2ed384: bl #0x313894
    0x2ed388: mov x1, x0
    0x2ed38c: mov x0, x26
    0x2ed390: mov w2, #0
    0x2ed394: bl #0x313780
    0x2ed398: nop 
    0x2ed39c: ldr x28, #0x3a8390 ; original literal='class'
    0x2ed3a0: mov x0, x26
    0x2ed3a4: mov x1, x28
    0x2ed3a8: bl #0x313780
    0x2ed3ac: adr x1, #0x33aa91
    0x2ed3b0: nop 
    0x2ed3b4: bl #0x313528
    0x2ed3b8: cbnz x0, #0x2ed3d8
    0x2ed3bc: mov x0, x26
    0x2ed3c0: mov x1, x28
    0x2ed3c4: bl #0x313780
    0x2ed3c8: adr x1, #0x33aa9b
    0x2ed3cc: nop 
    0x2ed3d0: bl #0x313528
    0x2ed3d4: cbz x0, #0x2ed3e0
    0x2ed3d8: bl #0x313648
    0x2ed3dc: strb wzr, [x0, x26]
    0x2ed3e0: nop 
    0x2ed3e4: ldr x2, #0x3aa2e0 ; original literal='isUnderLock'
    0x2ed3e8: mov x0, x26
    0x2ed3ec: mov x1, x27
    0x2ed3f0: bl #0x313780
    0x2ed3f4: cbz w0, #0x2ed414
    0x2ed3f8: adr x0, #0x33aaa7
    0x2ed3fc: nop 
    0x2ed400: bl #0x313894
    0x2ed404: mov x1, x0
    0x2ed408: mov x0, x26
    0x2ed40c: bl #0x313780
    0x2ed410: cbz w0, #0x2ed470
    0x2ed414: nop 
    0x2ed418: ldr x2, #0x3a8e28 ; original literal='setUnderLock:'
    0x2ed41c: mov x0, x26
    0x2ed420: mov x1, x27
    0x2ed424: bl #0x313780
    0x2ed428: cbz w0, #0x2ed448
    0x2ed42c: adr x0, #0x3326fd
    0x2ed430: nop 
    0x2ed434: bl #0x313894
    0x2ed438: mov x1, x0
    0x2ed43c: mov x0, x26
    0x2ed440: mov w2, #0
    0x2ed444: bl #0x313780
    0x2ed448: nop 
    0x2ed44c: ldr x1, #0x3a8390 ; original literal='class'
    0x2ed450: mov x0, x26
    0x2ed454: bl #0x313780
    0x2ed458: adr x1, #0x33aab3
    0x2ed45c: nop 
    0x2ed460: bl #0x313528
    0x2ed464: cbz x0, #0x2ed470
    0x2ed468: bl #0x313648
    0x2ed46c: strb wzr, [x0, x26]
    0x2ed470: nop 
    0x2ed474: ldr x2, #0x3aa2e8 ; original literal='canShowWhileLocked'
    0x2ed478: mov x0, x26
    0x2ed47c: mov x1, x27
    0x2ed480: bl #0x313780
    0x2ed484: cbz w0, #0x2ed4a4
    0x2ed488: adr x0, #0x33aabe
    0x2ed48c: nop 
    0x2ed490: bl #0x313894
    0x2ed494: mov x1, x0
    0x2ed498: mov x0, x26
    0x2ed49c: bl #0x313780
    0x2ed4a0: tbnz w0, #0, #0x2ed504
    0x2ed4a4: nop 
    0x2ed4a8: ldr x2, #0x3a8e30 ; original literal='setCanShowWhileLocked:'
    0x2ed4ac: mov x0, x26
    0x2ed4b0: mov x1, x27
    0x2ed4b4: bl #0x313780
    0x2ed4b8: cbz w0, #0x2ed4d8
    0x2ed4bc: adr x0, #0x33270b
    0x2ed4c0: nop 
    0x2ed4c4: bl #0x313894
    0x2ed4c8: mov x1, x0
    0x2ed4cc: mov x0, x26
    0x2ed4d0: mov w2, #1
    0x2ed4d4: bl #0x313780
    0x2ed4d8: nop 
    0x2ed4dc: ldr x1, #0x3a8390 ; original literal='class'
    0x2ed4e0: mov x0, x26
    0x2ed4e4: bl #0x313780
    0x2ed4e8: adr x1, #0x33aad1
    0x2ed4ec: nop 
    0x2ed4f0: bl #0x313528
    0x2ed4f4: cbz x0, #0x2ed504
    0x2ed4f8: bl #0x313648
    0x2ed4fc: mov w8, #1
    0x2ed500: strb w8, [x0, x26]
    0x2ed504: nop 
    0x2ed508: ldr x2, #0x3aa2d8 ; original literal='deactivationReasons'
    0x2ed50c: mov x0, x26
    0x2ed510: mov x1, x27
    0x2ed514: bl #0x313780
    0x2ed518: cbz w0, #0x2ed594
    0x2ed51c: adr x0, #0x33aae5
    0x2ed520: nop 
    0x2ed524: bl #0x313894
    0x2ed528: mov x1, x0
    0x2ed52c: mov x0, x26
    0x2ed530: bl #0x313780
    0x2ed534: cbz x0, #0x2ed594
    0x2ed538: nop 
    0x2ed53c: ldr x2, #0x3a8e38 ; original literal='setDeactivationReasons:'
    0x2ed540: mov x0, x26
    0x2ed544: mov x1, x27
    0x2ed548: bl #0x313780
    0x2ed54c: cbz w0, #0x2ed56c
    0x2ed550: adr x0, #0x332722
    0x2ed554: nop 
    0x2ed558: bl #0x313894
    0x2ed55c: mov x1, x0
    0x2ed560: mov x0, x26
    0x2ed564: mov x2, #0
    0x2ed568: bl #0x313780
    0x2ed56c: nop 
    0x2ed570: ldr x1, #0x3a8390 ; original literal='class'
    0x2ed574: mov x0, x26
    0x2ed578: bl #0x313780
    0x2ed57c: adr x1, #0x33aaf9
    0x2ed580: nop 
    0x2ed584: bl #0x313528
    0x2ed588: cbz x0, #0x2ed594
    0x2ed58c: bl #0x313648
    0x2ed590: str xzr, [x0, x26]
    0x2ed594: nop 
    0x2ed598: ldr x2, #0x3aa5e8 ; original literal='idleModeEnabled'
    0x2ed59c: mov x0, x26
    0x2ed5a0: mov x1, x27
    0x2ed5a4: bl #0x313780
    0x2ed5a8: cbz w0, #0x2ed5c8
    0x2ed5ac: adr x0, #0x33ab0e
    0x2ed5b0: nop 
    0x2ed5b4: bl #0x313894
    0x2ed5b8: mov x1, x0
    0x2ed5bc: mov x0, x26
    0x2ed5c0: bl #0x313780
    0x2ed5c4: cbz w0, #0x2ed624
    0x2ed5c8: nop 
    0x2ed5cc: ldr x2, #0x3a8e40 ; original literal='setIdleModeEnabled:'
    0x2ed5d0: mov x0, x26
    0x2ed5d4: mov x1, x27
    0x2ed5d8: bl #0x313780
    0x2ed5dc: cbz w0, #0x2ed5fc
    0x2ed5e0: adr x0, #0x33273a
    0x2ed5e4: nop 
    0x2ed5e8: bl #0x313894
    0x2ed5ec: mov x1, x0
    0x2ed5f0: mov x0, x26
    0x2ed5f4: mov w2, #0
    0x2ed5f8: bl #0x313780
    0x2ed5fc: nop 
    0x2ed600: ldr x1, #0x3a8390 ; original literal='class'
    0x2ed604: mov x0, x26
    0x2ed608: bl #0x313780
    0x2ed60c: adr x1, #0x33ab1e
    0x2ed610: nop 
    0x2ed614: bl #0x313528
    0x2ed618: cbz x0, #0x2ed624
    0x2ed61c: bl #0x313648
    0x2ed620: strb wzr, [x0, x26]
    0x2ed624: mov x0, x26
    0x2ed628: bl #0x3137b0
    0x2ed62c: mov x0, x25
    0x2ed630: bl #0x3137b0
    0x2ed634: nop 
    0x2ed638: ldr x8, #0x3adfb8
    0x2ed63c: mov x0, x22
    0x2ed640: mov x1, x21
    0x2ed644: mov x2, x19
    0x2ed648: mov x3, x20
    0x2ed64c: mov x4, x23
    0x2ed650: blr x8
    0x2ed654: mov x0, x24
    0x2ed658: bl #0x3137b0
    0x2ed65c: mov x0, x23
    0x2ed660: bl #0x3137b0
    0x2ed664: mov x0, x20
    0x2ed668: bl #0x3137b0
    0x2ed66c: mov x0, x19
    0x2ed670: ldp x29, x30, [sp, #0x70]
    0x2ed674: ldp x20, x19, [sp, #0x60]
    0x2ed678: ldp x22, x21, [sp, #0x50]
    0x2ed67c: ldp x24, x23, [sp, #0x40]
    0x2ed680: ldp x26, x25, [sp, #0x30]
    0x2ed684: ldp x28, x27, [sp, #0x20]
    0x2ed688: ldp d9, d8, [sp, #0x10]
    0x2ed68c: add sp, sp, #0x80
    0x2ed690: b #0x3137b0
    0x2ed694: b #0x2ed698
    0x2ed698: mov x25, x0
    0x2ed69c: cmp w1, #1
    0x2ed6a0: b.ne #0x2ed6e0
    0x2ed6a4: mov x0, x25
    0x2ed6a8: bl #0x3136fc
    0x2ed6ac: mov x29, x29
    0x2ed6b0: bl #0x3137e0
    0x2ed6b4: mov x25, x0
    0x2ed6b8: str x0, [sp]
    0x2ed6bc: adr x0, #0x39e680
    0x2ed6c0: nop 
    0x2ed6c4: bl #0x2ec4d8
    0x2ed6c8: mov x0, x25
    0x2ed6cc: bl #0x3137b0
    0x2ed6d0: bl #0x313720
    0x2ed6d4: b #0x2ed634
    0x2ed6d8: mov x25, x0
    0x2ed6dc: bl #0x313720
    0x2ed6e0: mov x0, x25
    0x2ed6e4: bl #0x313498
    0x2ed6e8: brk #1

## FBScene _applyUpdateWithContext:completion: @ 0x2ed6ec
- Registration call PC: 0x2ecf2c
- Original IMP storage: 0x3adfc0
- Original callback may be reached through *indirect* dynamic dispatch.
- Literal strings resolved: ['isUIAppBridging', 'performSelector:', 'renderSizeForBundleID:', 'respondsToSelector:', 'settings', 'sharedInstanceIfExists', 'shouldBridge:']
- Conditional zero-return candidate sites: []
- Indirect calls: ['0x2ed82c: blr x8']

### Bounded original ARM64
    0x2ed6ec: sub sp, sp, #0x60
    0x2ed6f0: stp x26, x25, [sp, #0x10]
    0x2ed6f4: stp x24, x23, [sp, #0x20]
    0x2ed6f8: stp x22, x21, [sp, #0x30]
    0x2ed6fc: stp x20, x19, [sp, #0x40]
    0x2ed700: stp x29, x30, [sp, #0x50]
    0x2ed704: add x29, sp, #0x50
    0x2ed708: mov x22, x3
    0x2ed70c: mov x20, x1
    0x2ed710: mov x21, x0
    0x2ed714: mov x0, x2
    0x2ed718: bl #0x3137bc
    0x2ed71c: mov x19, x0
    0x2ed720: mov x0, x22
    0x2ed724: bl #0x3137bc
    0x2ed728: mov x22, x0
    0x2ed72c: nop 
    0x2ed730: ldr x0, #0x3aab00
    0x2ed734: nop 
    0x2ed738: ldr x1, #0x3a8e68 ; original literal='sharedInstanceIfExists'
    0x2ed73c: bl #0x313780
    0x2ed740: mov x29, x29
    0x2ed744: bl #0x3137e0
    0x2ed748: mov x23, x0
    0x2ed74c: cbz x0, #0x2ed814
    0x2ed750: nop 
    0x2ed754: ldr x1, #0x3a8cf0 ; original literal='isUIAppBridging'
    0x2ed758: mov x0, x23
    0x2ed75c: bl #0x313780
    0x2ed760: cbz x19, #0x2ed814
    0x2ed764: cbz w0, #0x2ed814
    0x2ed768: mov x0, x21
    0x2ed76c: bl #0x2eb9d4
    0x2ed770: mov x29, x29
    0x2ed774: bl #0x3137e0
    0x2ed778: mov x24, x0
    0x2ed77c: cbz x0, #0x2ed80c
    0x2ed780: nop 
    0x2ed784: ldr x1, #0x3a9f18 ; original literal='shouldBridge:'
    0x2ed788: mov x0, x23
    0x2ed78c: mov x2, x24
    0x2ed790: bl #0x313780
    0x2ed794: cbz w0, #0x2ed80c
    0x2ed798: nop 
    0x2ed79c: ldr x25, #0x3a8ff0 ; original literal='settings'
    0x2ed7a0: nop 
    0x2ed7a4: ldr x1, #0x3a8358 ; original literal='respondsToSelector:'
    0x2ed7a8: mov x0, x19
    0x2ed7ac: mov x2, x25
    0x2ed7b0: bl #0x313780
    0x2ed7b4: cbz w0, #0x2ed80c
    0x2ed7b8: nop 
    0x2ed7bc: ldr x1, #0x3a8a48 ; original literal='performSelector:'
    0x2ed7c0: mov x0, x19
    0x2ed7c4: mov x2, x25
    0x2ed7c8: bl #0x313780
    0x2ed7cc: mov x29, x29
    0x2ed7d0: bl #0x3137e0
    0x2ed7d4: mov x25, x0
    0x2ed7d8: mov x0, x21
    0x2ed7dc: mov x1, x25
    0x2ed7e0: bl #0x2eeb24
    0x2ed7e4: cbz w0, #0x2ed804
    0x2ed7e8: nop 
    0x2ed7ec: ldr x1, #0x3a9ef0 ; original literal='renderSizeForBundleID:'
    0x2ed7f0: mov x0, x23
    0x2ed7f4: mov x2, x24
    0x2ed7f8: bl #0x313780
    0x2ed7fc: mov x0, x25
    0x2ed800: bl #0x2eca50
    0x2ed804: mov x0, x25
    0x2ed808: bl #0x3137b0
    0x2ed80c: mov x0, x24
    0x2ed810: bl #0x3137b0
    0x2ed814: nop 
    0x2ed818: ldr x8, #0x3adfc0
    0x2ed81c: mov x0, x21
    0x2ed820: mov x1, x20
    0x2ed824: mov x2, x19
    0x2ed828: mov x3, x22
    0x2ed82c: blr x8
    0x2ed830: mov x0, x23
    0x2ed834: bl #0x3137b0
    0x2ed838: mov x0, x22
    0x2ed83c: bl #0x3137b0
    0x2ed840: mov x0, x19
    0x2ed844: ldp x29, x30, [sp, #0x50]
    0x2ed848: ldp x20, x19, [sp, #0x40]
    0x2ed84c: ldp x22, x21, [sp, #0x30]
    0x2ed850: ldp x24, x23, [sp, #0x20]
    0x2ed854: ldp x26, x25, [sp, #0x10]
    0x2ed858: add sp, sp, #0x60
    0x2ed85c: b #0x3137b0
    0x2ed860: b #0x2ed868
    0x2ed864: b #0x2ed868
    0x2ed868: mov x24, x0
    0x2ed86c: cmp w1, #1
    0x2ed870: b.ne #0x2ed8b0
    0x2ed874: mov x0, x24
    0x2ed878: bl #0x3136fc
    0x2ed87c: mov x29, x29
    0x2ed880: bl #0x3137e0
    0x2ed884: mov x24, x0
    0x2ed888: str x0, [sp]
    0x2ed88c: adr x0, #0x39e6c0
    0x2ed890: nop 
    0x2ed894: bl #0x2ec4d8
    0x2ed898: mov x0, x24
    0x2ed89c: bl #0x3137b0
    0x2ed8a0: bl #0x313720
    0x2ed8a4: b #0x2ed814
    0x2ed8a8: mov x24, x0
    0x2ed8ac: bl #0x313720
    0x2ed8b0: mov x0, x24
    0x2ed8b4: bl #0x313498
    0x2ed8b8: brk #1

## _UIScenePresentationView scene:didPrepareUpdateWithContext: @ 0x2ed8bc
- Registration call PC: 0x2ecf54
- Original IMP storage: 0x3adfc8
- Original callback may be reached through *indirect* dynamic dispatch.
- Literal strings resolved: ['_updateFrameAndTransform', 'isUIAppBridging', 'respondsToSelector:', 'sharedInstanceIfExists']
- Conditional zero-return candidate sites: []
- Indirect calls: ['0x2ed8d8: blr x8']

### Bounded original ARM64
    0x2ed8bc: stp x22, x21, [sp, #-0x30]!
    0x2ed8c0: stp x20, x19, [sp, #0x10]
    0x2ed8c4: stp x29, x30, [sp, #0x20]
    0x2ed8c8: add x29, sp, #0x20
    0x2ed8cc: mov x19, x0
    0x2ed8d0: nop 
    0x2ed8d4: ldr x8, #0x3adfc8
    0x2ed8d8: blr x8
    0x2ed8dc: nop 
    0x2ed8e0: ldr x0, #0x3aab00
    0x2ed8e4: nop 
    0x2ed8e8: ldr x1, #0x3a8e68 ; original literal='sharedInstanceIfExists'
    0x2ed8ec: bl #0x313780
    0x2ed8f0: mov x29, x29
    0x2ed8f4: bl #0x3137e0
    0x2ed8f8: mov x20, x0
    0x2ed8fc: cbz x0, #0x2ed940
    0x2ed900: nop 
    0x2ed904: ldr x1, #0x3a8cf0 ; original literal='isUIAppBridging'
    0x2ed908: mov x0, x20
    0x2ed90c: bl #0x313780
    0x2ed910: cbz w0, #0x2ed940
    0x2ed914: nop 
    0x2ed918: ldr x21, #0x3aa600 ; original literal='_updateFrameAndTransform'
    0x2ed91c: nop 
    0x2ed920: ldr x1, #0x3a8358 ; original literal='respondsToSelector:'
    0x2ed924: mov x0, x19
    0x2ed928: mov x2, x21
    0x2ed92c: bl #0x313780
    0x2ed930: cbz w0, #0x2ed940
    0x2ed934: mov x0, x19
    0x2ed938: mov x1, x21
    0x2ed93c: bl #0x313780
    0x2ed940: mov x0, x20
    0x2ed944: ldp x29, x30, [sp, #0x20]
    0x2ed948: ldp x20, x19, [sp, #0x10]
    0x2ed94c: ldp x22, x21, [sp], #0x30
    0x2ed950: b #0x3137b0

## SBSuspendedUnderLockManager interceptUpdateForScene:withNewSettings: @ 0x2ed954
- Registration call PC: 0x2ecf80
- Original IMP storage: 0x3adfd0
- Original callback may be reached through *indirect* dynamic dispatch.
- Literal strings resolved: ['isUIAppBridging', 'renderSizeForBundleID:', 'sharedInstanceIfExists', 'shouldBridge:']
- Conditional zero-return candidate sites: []
- Indirect calls: ['0x2ed9a0: blr x8']

### Bounded original ARM64
    0x2ed954: stp x22, x21, [sp, #-0x30]!
    0x2ed958: stp x20, x19, [sp, #0x10]
    0x2ed95c: stp x29, x30, [sp, #0x20]
    0x2ed960: add x29, sp, #0x20
    0x2ed964: mov x20, x3
    0x2ed968: mov x21, x1
    0x2ed96c: mov x22, x0
    0x2ed970: mov x0, x2
    0x2ed974: bl #0x3137bc
    0x2ed978: mov x19, x0
    0x2ed97c: mov x0, x20
    0x2ed980: bl #0x3137bc
    0x2ed984: mov x20, x0
    0x2ed988: nop 
    0x2ed98c: ldr x8, #0x3adfd0
    0x2ed990: mov x0, x22
    0x2ed994: mov x1, x21
    0x2ed998: mov x2, x19
    0x2ed99c: mov x3, x20
    0x2ed9a0: blr x8
    0x2ed9a4: nop 
    0x2ed9a8: ldr x0, #0x3aab00
    0x2ed9ac: nop 
    0x2ed9b0: ldr x1, #0x3a8e68 ; original literal='sharedInstanceIfExists'
    0x2ed9b4: bl #0x313780
    0x2ed9b8: mov x29, x29
    0x2ed9bc: bl #0x3137e0
    0x2ed9c0: mov x21, x0
    0x2ed9c4: cbz x0, #0x2eda40
    0x2ed9c8: nop 
    0x2ed9cc: ldr x1, #0x3a8cf0 ; original literal='isUIAppBridging'
    0x2ed9d0: mov x0, x21
    0x2ed9d4: bl #0x313780
    0x2ed9d8: cbz w0, #0x2eda40
    0x2ed9dc: mov x0, x19
    0x2ed9e0: bl #0x2eb9d4
    0x2ed9e4: mov x29, x29
    0x2ed9e8: bl #0x3137e0
    0x2ed9ec: mov x22, x0
    0x2ed9f0: cbz x0, #0x2eda38
    0x2ed9f4: nop 
    0x2ed9f8: ldr x1, #0x3a9f18 ; original literal='shouldBridge:'
    0x2ed9fc: mov x0, x21
    0x2eda00: mov x2, x22
    0x2eda04: bl #0x313780
    0x2eda08: cbz w0, #0x2eda38
    0x2eda0c: mov x0, x19
    0x2eda10: mov x1, x20
    0x2eda14: bl #0x2eeb24
    0x2eda18: cbz w0, #0x2eda38
    0x2eda1c: nop 
    0x2eda20: ldr x1, #0x3a9ef0 ; original literal='renderSizeForBundleID:'
    0x2eda24: mov x0, x21
    0x2eda28: mov x2, x22
    0x2eda2c: bl #0x313780
    0x2eda30: mov x0, x20
    0x2eda34: bl #0x2eca50
    0x2eda38: mov x0, x22
    0x2eda3c: bl #0x3137b0
    0x2eda40: mov x0, x21
    0x2eda44: bl #0x3137b0
    0x2eda48: mov x0, x20
    0x2eda4c: bl #0x3137b0
    0x2eda50: mov x0, x19
    0x2eda54: ldp x29, x30, [sp, #0x20]
    0x2eda58: ldp x20, x19, [sp, #0x10]
    0x2eda5c: ldp x22, x21, [sp], #0x30
    0x2eda60: b #0x3137b0

## SBSuspendedUnderLockManager _shouldBeBackgroundUnderLockForScene:withSettings: @ 0x2eda64
- Registration call PC: 0x2ecfa0
- Original IMP storage: 0x3adfd8
- Original callback may be reached through *indirect* dynamic dispatch.
- Literal strings resolved: ['isUIAppBridging', 'sharedInstanceIfExists', 'shouldBridge:']
- Conditional zero-return candidate sites: ['0x2edb1c: mov w21, #0']
- Indirect calls: ['0x2edb44: blr x8']

### Bounded original ARM64
    0x2eda64: stp x24, x23, [sp, #-0x40]!
    0x2eda68: stp x22, x21, [sp, #0x10]
    0x2eda6c: stp x20, x19, [sp, #0x20]
    0x2eda70: stp x29, x30, [sp, #0x30]
    0x2eda74: add x29, sp, #0x30
    0x2eda78: mov x20, x3
    0x2eda7c: mov x21, x1
    0x2eda80: mov x22, x0
    0x2eda84: mov x0, x2
    0x2eda88: bl #0x3137bc
    0x2eda8c: mov x19, x0
    0x2eda90: mov x0, x20
    0x2eda94: bl #0x3137bc
    0x2eda98: mov x20, x0
    0x2eda9c: nop 
    0x2edaa0: ldr x0, #0x3aab00
    0x2edaa4: nop 
    0x2edaa8: ldr x1, #0x3a8e68 ; original literal='sharedInstanceIfExists'
    0x2edaac: bl #0x313780
    0x2edab0: mov x29, x29
    0x2edab4: bl #0x3137e0
    0x2edab8: mov x23, x0
    0x2edabc: cbz x0, #0x2edb2c
    0x2edac0: nop 
    0x2edac4: ldr x1, #0x3a8cf0 ; original literal='isUIAppBridging'
    0x2edac8: mov x0, x23
    0x2edacc: bl #0x313780
    0x2edad0: cbz w0, #0x2edb2c
    0x2edad4: mov x0, x19
    0x2edad8: bl #0x2eb9d4
    0x2edadc: mov x29, x29
    0x2edae0: bl #0x3137e0
    0x2edae4: mov x24, x0
    0x2edae8: cbz x0, #0x2edb24
    0x2edaec: nop 
    0x2edaf0: ldr x1, #0x3a9f18 ; original literal='shouldBridge:'
    0x2edaf4: mov x0, x23
    0x2edaf8: mov x2, x24
    0x2edafc: bl #0x313780
    0x2edb00: cbz w0, #0x2edb24
    0x2edb04: mov x0, x19
    0x2edb08: mov x1, x20
    0x2edb0c: bl #0x2eeb24
    0x2edb10: cbz w0, #0x2edb24
    0x2edb14: mov x0, x24
    0x2edb18: bl #0x3137b0
    0x2edb1c: mov w21, #0
    0x2edb20: b #0x2edb4c
    0x2edb24: mov x0, x24
    0x2edb28: bl #0x3137b0
    0x2edb2c: nop 
    0x2edb30: ldr x8, #0x3adfd8
    0x2edb34: mov x0, x22
    0x2edb38: mov x1, x21
    0x2edb3c: mov x2, x19
    0x2edb40: mov x3, x20
    0x2edb44: blr x8
    0x2edb48: mov x21, x0
    0x2edb4c: mov x0, x23
    0x2edb50: bl #0x3137b0
    0x2edb54: mov x0, x20
    0x2edb58: bl #0x3137b0
    0x2edb5c: mov x0, x19
    0x2edb60: bl #0x3137b0
    0x2edb64: mov x0, x21
    0x2edb68: ldp x29, x30, [sp, #0x30]
    0x2edb6c: ldp x20, x19, [sp, #0x20]
    0x2edb70: ldp x22, x21, [sp, #0x10]
    0x2edb74: ldp x24, x23, [sp], #0x40
    0x2edb78: ret 

## SBSuspendedUnderLockManager shouldBeUnderLockForScene: @ 0x2edb7c
- Registration call PC: 0x2ecfc0
- Original IMP storage: 0x3adfe0
- Original callback may be reached through *indirect* dynamic dispatch.
- Literal strings resolved: ['isUIAppBridging', 'sharedInstanceIfExists', 'shouldBridge:']
- Conditional zero-return candidate sites: ['0x2edc10: mov x1, #0', '0x2edc24: mov w20, #0']
- Indirect calls: ['0x2edc48: blr x8']

### Bounded original ARM64
    0x2edb7c: stp x24, x23, [sp, #-0x40]!
    0x2edb80: stp x22, x21, [sp, #0x10]
    0x2edb84: stp x20, x19, [sp, #0x20]
    0x2edb88: stp x29, x30, [sp, #0x30]
    0x2edb8c: add x29, sp, #0x30
    0x2edb90: mov x20, x1
    0x2edb94: mov x21, x0
    0x2edb98: mov x0, x2
    0x2edb9c: bl #0x3137bc
    0x2edba0: mov x19, x0
    0x2edba4: nop 
    0x2edba8: ldr x0, #0x3aab00
    0x2edbac: nop 
    0x2edbb0: ldr x1, #0x3a8e68 ; original literal='sharedInstanceIfExists'
    0x2edbb4: bl #0x313780
    0x2edbb8: mov x29, x29
    0x2edbbc: bl #0x3137e0
    0x2edbc0: mov x22, x0
    0x2edbc4: cbz x0, #0x2edc34
    0x2edbc8: nop 
    0x2edbcc: ldr x1, #0x3a8cf0 ; original literal='isUIAppBridging'
    0x2edbd0: mov x0, x22
    0x2edbd4: bl #0x313780
    0x2edbd8: cbz w0, #0x2edc34
    0x2edbdc: mov x0, x19
    0x2edbe0: bl #0x2eb9d4
    0x2edbe4: mov x29, x29
    0x2edbe8: bl #0x3137e0
    0x2edbec: mov x23, x0
    0x2edbf0: cbz x0, #0x2edc2c
    0x2edbf4: nop 
    0x2edbf8: ldr x1, #0x3a9f18 ; original literal='shouldBridge:'
    0x2edbfc: mov x0, x22
    0x2edc00: mov x2, x23
    0x2edc04: bl #0x313780
    0x2edc08: cbz w0, #0x2edc2c
    0x2edc0c: mov x0, x19
    0x2edc10: mov x1, #0
    0x2edc14: bl #0x2eeb24
    0x2edc18: cbz w0, #0x2edc2c
    0x2edc1c: mov x0, x23
    0x2edc20: bl #0x3137b0
    0x2edc24: mov w20, #0
    0x2edc28: b #0x2edc50
    0x2edc2c: mov x0, x23
    0x2edc30: bl #0x3137b0
    0x2edc34: nop 
    0x2edc38: ldr x8, #0x3adfe0
    0x2edc3c: mov x0, x21
    0x2edc40: mov x1, x20
    0x2edc44: mov x2, x19
    0x2edc48: blr x8
    0x2edc4c: mov x20, x0
    0x2edc50: mov x0, x22
    0x2edc54: bl #0x3137b0
    0x2edc58: mov x0, x19
    0x2edc5c: bl #0x3137b0
    0x2edc60: mov x0, x20
    0x2edc64: ldp x29, x30, [sp, #0x30]
    0x2edc68: ldp x20, x19, [sp, #0x20]
    0x2edc6c: ldp x22, x21, [sp, #0x10]
    0x2edc70: ldp x24, x23, [sp], #0x40
    0x2edc74: ret 

## SBDeviceApplicationSceneViewController setContentReferenceSize:withInterfaceOrientation: @ 0x2edc78
- Registration call PC: 0x2ecfec
- Original IMP storage: 0x3adfe8
- Original callback may be reached through *indirect* dynamic dispatch.
- Literal strings resolved: ['isUIAppBridging', 'renderSizeForBundleID:', 'sharedInstanceIfExists', 'shouldBridge:']
- Conditional zero-return candidate sites: []
- Indirect calls: ['0x2edd58: blr x8']

### Bounded original ARM64
    0x2edc78: stp d9, d8, [sp, #-0x50]!
    0x2edc7c: stp x24, x23, [sp, #0x10]
    0x2edc80: stp x22, x21, [sp, #0x20]
    0x2edc84: stp x20, x19, [sp, #0x30]
    0x2edc88: stp x29, x30, [sp, #0x40]
    0x2edc8c: add x29, sp, #0x40
    0x2edc90: mov x19, x2
    0x2edc94: mov v8.16b, v1.16b
    0x2edc98: mov v9.16b, v0.16b
    0x2edc9c: mov x20, x1
    0x2edca0: mov x21, x0
    0x2edca4: nop 
    0x2edca8: ldr x0, #0x3aab00
    0x2edcac: nop 
    0x2edcb0: ldr x1, #0x3a8e68 ; original literal='sharedInstanceIfExists'
    0x2edcb4: bl #0x313780
    0x2edcb8: mov x29, x29
    0x2edcbc: bl #0x3137e0
    0x2edcc0: mov x22, x0
    0x2edcc4: cbz x0, #0x2edd3c
    0x2edcc8: nop 
    0x2edccc: ldr x1, #0x3a8cf0 ; original literal='isUIAppBridging'
    0x2edcd0: mov x0, x22
    0x2edcd4: bl #0x313780
    0x2edcd8: cbz w0, #0x2edd3c
    0x2edcdc: mov x0, x21
    0x2edce0: bl #0x2eedac
    0x2edce4: cbz w0, #0x2edd3c
    0x2edce8: mov x0, x21
    0x2edcec: bl #0x2eefdc
    0x2edcf0: mov x29, x29
    0x2edcf4: bl #0x3137e0
    0x2edcf8: mov x23, x0
    0x2edcfc: cbz x0, #0x2edd34
    0x2edd00: nop 
    0x2edd04: ldr x1, #0x3a9f18 ; original literal='shouldBridge:'
    0x2edd08: mov x0, x22
    0x2edd0c: mov x2, x23
    0x2edd10: bl #0x313780
    0x2edd14: cbz w0, #0x2edd34
    0x2edd18: nop 
    0x2edd1c: ldr x1, #0x3a9ef0 ; original literal='renderSizeForBundleID:'
    0x2edd20: mov x0, x22
    0x2edd24: mov x2, x23
    0x2edd28: bl #0x313780
    0x2edd2c: mov v9.16b, v0.16b
    0x2edd30: mov v8.16b, v1.16b
    0x2edd34: mov x0, x23
    0x2edd38: bl #0x3137b0
    0x2edd3c: nop 
    0x2edd40: ldr x8, #0x3adfe8
    0x2edd44: mov x0, x21
    0x2edd48: mov x1, x20
    0x2edd4c: mov v0.16b, v9.16b
    0x2edd50: mov v1.16b, v8.16b
    0x2edd54: mov x2, x19
    0x2edd58: blr x8
    0x2edd5c: mov x0, x22
    0x2edd60: ldp x29, x30, [sp, #0x40]
    0x2edd64: ldp x20, x19, [sp, #0x30]
    0x2edd68: ldp x22, x21, [sp, #0x20]
    0x2edd6c: ldp x24, x23, [sp, #0x10]
    0x2edd70: ldp d9, d8, [sp], #0x50
    0x2edd74: b #0x3137b0

## SBDeviceApplicationSceneViewController setContentReferenceSize:withContentOrientation:andContainerOrientation: @ 0x2edd78
- Registration call PC: 0x2ed00c
- Original IMP storage: 0x3adff0
- Original callback may be reached through *indirect* dynamic dispatch.
- Literal strings resolved: ['isUIAppBridging', 'renderSizeForBundleID:', 'sharedInstanceIfExists', 'shouldBridge:']
- Conditional zero-return candidate sites: []
- Indirect calls: ['0x2ede60: blr x8']

### Bounded original ARM64
    0x2edd78: stp d9, d8, [sp, #-0x50]!
    0x2edd7c: stp x24, x23, [sp, #0x10]
    0x2edd80: stp x22, x21, [sp, #0x20]
    0x2edd84: stp x20, x19, [sp, #0x30]
    0x2edd88: stp x29, x30, [sp, #0x40]
    0x2edd8c: add x29, sp, #0x40
    0x2edd90: mov x19, x3
    0x2edd94: mov x20, x2
    0x2edd98: mov v8.16b, v1.16b
    0x2edd9c: mov v9.16b, v0.16b
    0x2edda0: mov x21, x1
    0x2edda4: mov x22, x0
    0x2edda8: nop 
    0x2eddac: ldr x0, #0x3aab00
    0x2eddb0: nop 
    0x2eddb4: ldr x1, #0x3a8e68 ; original literal='sharedInstanceIfExists'
    0x2eddb8: bl #0x313780
    0x2eddbc: mov x29, x29
    0x2eddc0: bl #0x3137e0
    0x2eddc4: mov x23, x0
    0x2eddc8: cbz x0, #0x2ede40
    0x2eddcc: nop 
    0x2eddd0: ldr x1, #0x3a8cf0 ; original literal='isUIAppBridging'
    0x2eddd4: mov x0, x23
    0x2eddd8: bl #0x313780
    0x2edddc: cbz w0, #0x2ede40
    0x2edde0: mov x0, x22
    0x2edde4: bl #0x2eedac
    0x2edde8: cbz w0, #0x2ede40
    0x2eddec: mov x0, x22
    0x2eddf0: bl #0x2eefdc
    0x2eddf4: mov x29, x29
    0x2eddf8: bl #0x3137e0
    0x2eddfc: mov x24, x0
    0x2ede00: cbz x0, #0x2ede38
    0x2ede04: nop 
    0x2ede08: ldr x1, #0x3a9f18 ; original literal='shouldBridge:'
    0x2ede0c: mov x0, x23
    0x2ede10: mov x2, x24
    0x2ede14: bl #0x313780
    0x2ede18: cbz w0, #0x2ede38
    0x2ede1c: nop 
    0x2ede20: ldr x1, #0x3a9ef0 ; original literal='renderSizeForBundleID:'
    0x2ede24: mov x0, x23
    0x2ede28: mov x2, x24
    0x2ede2c: bl #0x313780
    0x2ede30: mov v9.16b, v0.16b
    0x2ede34: mov v8.16b, v1.16b
    0x2ede38: mov x0, x24
    0x2ede3c: bl #0x3137b0
    0x2ede40: nop 
    0x2ede44: ldr x8, #0x3adff0
    0x2ede48: mov x0, x22
    0x2ede4c: mov x1, x21
    0x2ede50: mov v0.16b, v9.16b
    0x2ede54: mov v1.16b, v8.16b
    0x2ede58: mov x2, x20
    0x2ede5c: mov x3, x19
    0x2ede60: blr x8
    0x2ede64: mov x0, x23
    0x2ede68: ldp x29, x30, [sp, #0x40]
    0x2ede6c: ldp x20, x19, [sp, #0x30]
    0x2ede70: ldp x22, x21, [sp, #0x20]
    0x2ede74: ldp x24, x23, [sp, #0x10]
    0x2ede78: ldp d9, d8, [sp], #0x50
    0x2ede7c: b #0x3137b0

## SBDeviceApplicationSceneHandle _mainSceneSupportsInterfaceOrientation: @ 0x2ede80
- Registration call PC: 0x2ed034
- Original IMP storage: 0x3adff8
- Original callback may be reached through *indirect* dynamic dispatch.
- Literal strings resolved: ['application', 'bundleIdentifier', 'isUIAppBridging', 'respondsToSelector:', 'sharedInstanceIfExists', 'shouldBridge:']
- Conditional zero-return candidate sites: []
- Indirect calls: ['0x2edfb0: blr x8']

### Bounded original ARM64
    0x2ede80: stp x26, x25, [sp, #-0x50]!
    0x2ede84: stp x24, x23, [sp, #0x10]
    0x2ede88: stp x22, x21, [sp, #0x20]
    0x2ede8c: stp x20, x19, [sp, #0x30]
    0x2ede90: stp x29, x30, [sp, #0x40]
    0x2ede94: add x29, sp, #0x40
    0x2ede98: mov x19, x2
    0x2ede9c: mov x21, x1
    0x2edea0: mov x22, x0
    0x2edea4: nop 
    0x2edea8: ldr x0, #0x3aab00
    0x2edeac: nop 
    0x2edeb0: ldr x1, #0x3a8e68 ; original literal='sharedInstanceIfExists'
    0x2edeb4: bl #0x313780
    0x2edeb8: mov x29, x29
    0x2edebc: bl #0x3137e0
    0x2edec0: mov x20, x0
    0x2edec4: cbz x0, #0x2edf9c
    0x2edec8: nop 
    0x2edecc: ldr x1, #0x3a8cf0 ; original literal='isUIAppBridging'
    0x2eded0: mov x0, x20
    0x2eded4: bl #0x313780
    0x2eded8: cbz w0, #0x2edf9c
    0x2ededc: nop 
    0x2edee0: ldr x23, #0x3aa560 ; original literal='application'
    0x2edee4: nop 
    0x2edee8: ldr x24, #0x3a8358 ; original literal='respondsToSelector:'
    0x2edeec: mov x0, x22
    0x2edef0: mov x1, x24
    0x2edef4: mov x2, x23
    0x2edef8: bl #0x313780
    0x2edefc: cbz w0, #0x2edf9c
    0x2edf00: mov x0, x22
    0x2edf04: mov x1, x23
    0x2edf08: bl #0x313780
    0x2edf0c: mov x29, x29
    0x2edf10: bl #0x3137e0
    0x2edf14: mov x23, x0
    0x2edf18: cbz x0, #0x2edf94
    0x2edf1c: nop 
    0x2edf20: ldr x25, #0x3a8198 ; original literal='bundleIdentifier'
    0x2edf24: mov x0, x23
    0x2edf28: mov x1, x24
    0x2edf2c: mov x2, x25
    0x2edf30: bl #0x313780
    0x2edf34: cbz w0, #0x2edf94
    0x2edf38: mov x0, x23
    0x2edf3c: mov x1, x25
    0x2edf40: bl #0x313780
    0x2edf44: mov x29, x29
    0x2edf48: bl #0x3137e0
    0x2edf4c: mov x24, x0
    0x2edf50: cbz x0, #0x2edf8c
    0x2edf54: nop 
    0x2edf58: ldr x1, #0x3a9f18 ; original literal='shouldBridge:'
    0x2edf5c: mov x0, x20
    0x2edf60: mov x2, x24
    0x2edf64: bl #0x313780
    0x2edf68: mov x25, x0
    0x2edf6c: mov x0, x24
    0x2edf70: bl #0x3137b0
    0x2edf74: tbz w25, #0, #0x2edf94
    0x2edf78: cmp x19, #1
    0x2edf7c: cset w19, eq
    0x2edf80: mov x0, x23
    0x2edf84: bl #0x3137b0
    0x2edf88: b #0x2edfb8
    0x2edf8c: mov x0, x24
    0x2edf90: bl #0x3137b0
    0x2edf94: mov x0, x23
    0x2edf98: bl #0x3137b0
    0x2edf9c: nop 
    0x2edfa0: ldr x8, #0x3adff8
    0x2edfa4: mov x0, x22
    0x2edfa8: mov x1, x21
    0x2edfac: mov x2, x19
    0x2edfb0: blr x8
    0x2edfb4: mov x19, x0
    0x2edfb8: mov x0, x20
    0x2edfbc: bl #0x3137b0
    0x2edfc0: mov x0, x19
    0x2edfc4: ldp x29, x30, [sp, #0x40]
    0x2edfc8: ldp x20, x19, [sp, #0x30]
    0x2edfcc: ldp x22, x21, [sp, #0x20]
    0x2edfd0: ldp x24, x23, [sp, #0x10]
    0x2edfd4: ldp x26, x25, [sp], #0x50
    0x2edfd8: ret 

## SBAppViewController sceneHandle:didUpdateSettingsWithDiff:previousSettings: @ 0x2edfdc
- Registration call PC: 0x2ed060
- Original IMP storage: 0x3ae000
- Original callback may be reached through *indirect* dynamic dispatch.
- Literal strings resolved: ['automatesLifecycle', 'performSelector:', 'respondsToSelector:', 'sceneHandle']
- Conditional zero-return candidate sites: []
- Indirect calls: ['0x2ee1d0: blr x8']

### Bounded original ARM64
    0x2edfdc: sub sp, sp, #0x60
    0x2edfe0: stp x26, x25, [sp, #0x10]
    0x2edfe4: stp x24, x23, [sp, #0x20]
    0x2edfe8: stp x22, x21, [sp, #0x30]
    0x2edfec: stp x20, x19, [sp, #0x40]
    0x2edff0: stp x29, x30, [sp, #0x50]
    0x2edff4: add x29, sp, #0x50
    0x2edff8: mov x21, x4
    0x2edffc: mov x20, x3
    0x2ee000: mov x22, x1
    0x2ee004: mov x23, x0
    0x2ee008: mov x0, x2
    0x2ee00c: bl #0x3137bc
    0x2ee010: mov x19, x0
    0x2ee014: mov x0, x20
    0x2ee018: bl #0x3137bc
    0x2ee01c: mov x20, x0
    0x2ee020: mov x0, x21
    0x2ee024: bl #0x3137bc
    0x2ee028: mov x21, x0
    0x2ee02c: adr x1, #0x33264f
    0x2ee030: nop 
    0x2ee034: mov x0, x23
    0x2ee038: bl #0x313744
    0x2ee03c: mov x29, x29
    0x2ee040: bl #0x3137e0
    0x2ee044: cbz x0, #0x2ee050
    0x2ee048: bl #0x3137b0
    0x2ee04c: b #0x2ee074
    0x2ee050: adr x1, #0x33265f
    0x2ee054: nop 
    0x2ee058: mov x0, x23
    0x2ee05c: bl #0x313744
    0x2ee060: mov x29, x29
    0x2ee064: bl #0x3137e0
    0x2ee068: mov x24, x0
    0x2ee06c: bl #0x3137b0
    0x2ee070: cbz x24, #0x2ee0a4
    0x2ee074: mov x0, x21
    0x2ee078: bl #0x3137b0
    0x2ee07c: mov x0, x20
    0x2ee080: bl #0x3137b0
    0x2ee084: mov x0, x19
    0x2ee088: ldp x29, x30, [sp, #0x50]
    0x2ee08c: ldp x20, x19, [sp, #0x40]
    0x2ee090: ldp x22, x21, [sp, #0x30]
    0x2ee094: ldp x24, x23, [sp, #0x20]
    0x2ee098: ldp x26, x25, [sp, #0x10]
    0x2ee09c: add sp, sp, #0x60
    0x2ee0a0: b #0x3137b0
    0x2ee0a4: cbz x19, #0x2ee0e8
    0x2ee0a8: adr x1, #0x33264f
    0x2ee0ac: nop 
    0x2ee0b0: mov x0, x19
    0x2ee0b4: bl #0x313744
    0x2ee0b8: mov x29, x29
    0x2ee0bc: bl #0x3137e0
    0x2ee0c0: cbnz x0, #0x2ee048
    0x2ee0c4: adr x1, #0x33265f
    0x2ee0c8: nop 
    0x2ee0cc: mov x0, x19
    0x2ee0d0: bl #0x313744
    0x2ee0d4: mov x29, x29
    0x2ee0d8: bl #0x3137e0
    0x2ee0dc: mov x24, x0
    0x2ee0e0: bl #0x3137b0
    0x2ee0e4: cbnz x24, #0x2ee074
    0x2ee0e8: nop 
    0x2ee0ec: ldr x25, #0x3a8df8 ; original literal='sceneHandle'
    0x2ee0f0: nop 
    0x2ee0f4: ldr x24, #0x3a8358 ; original literal='respondsToSelector:'
    0x2ee0f8: mov x0, x23
    0x2ee0fc: mov x1, x24
    0x2ee100: mov x2, x25
    0x2ee104: bl #0x313780
    0x2ee108: cbz w0, #0x2ee180
    0x2ee10c: nop 
    0x2ee110: ldr x1, #0x3a8a48 ; original literal='performSelector:'
    0x2ee114: mov x0, x23
    0x2ee118: mov x2, x25
    0x2ee11c: bl #0x313780
    0x2ee120: mov x29, x29
    0x2ee124: bl #0x3137e0
    0x2ee128: cbz x0, #0x2ee180
    0x2ee12c: mov x25, x0
    0x2ee130: adr x1, #0x33264f
    0x2ee134: nop 
    0x2ee138: bl #0x313744
    0x2ee13c: mov x29, x29
    0x2ee140: bl #0x3137e0
    0x2ee144: cbz x0, #0x2ee154
    0x2ee148: bl #0x3137b0
    0x2ee14c: mov x0, x25
    0x2ee150: b #0x2ee048
    0x2ee154: adr x1, #0x33265f
    0x2ee158: nop 
    0x2ee15c: mov x0, x25
    0x2ee160: bl #0x313744
    0x2ee164: mov x29, x29
    0x2ee168: bl #0x3137e0
    0x2ee16c: mov x26, x0
    0x2ee170: bl #0x3137b0
    0x2ee174: mov x0, x25
    0x2ee178: bl #0x3137b0
    0x2ee17c: cbnz x26, #0x2ee074
    0x2ee180: nop 
    0x2ee184: ldr x2, #0x3aa608 ; original literal='automatesLifecycle'
    0x2ee188: mov x0, x23
    0x2ee18c: mov x1, x24
    0x2ee190: bl #0x313780
    0x2ee194: cbz w0, #0x2ee1b4
    0x2ee198: adr x0, #0x33ac23
    0x2ee19c: nop 
    0x2ee1a0: bl #0x313894
    0x2ee1a4: mov x1, x0
    0x2ee1a8: mov x0, x23
    0x2ee1ac: bl #0x313780
    0x2ee1b0: cbz w0, #0x2ee074
    0x2ee1b4: nop 
    0x2ee1b8: ldr x8, #0x3ae000
    0x2ee1bc: mov x0, x23
    0x2ee1c0: mov x1, x22
    0x2ee1c4: mov x2, x19
    0x2ee1c8: mov x3, x20
    0x2ee1cc: mov x4, x21
    0x2ee1d0: blr x8
    0x2ee1d4: b #0x2ee074
    0x2ee1d8: mov x22, x0
    0x2ee1dc: cmp w1, #1
    0x2ee1e0: b.ne #0x2ee220
    0x2ee1e4: mov x0, x22
    0x2ee1e8: bl #0x3136fc
    0x2ee1ec: mov x29, x29
    0x2ee1f0: bl #0x3137e0
    0x2ee1f4: mov x22, x0
    0x2ee1f8: str x0, [sp]
    0x2ee1fc: adr x0, #0x39e700
    0x2ee200: nop 
    0x2ee204: bl #0x3133c0
    0x2ee208: mov x0, x22
    0x2ee20c: bl #0x3137b0
    0x2ee210: bl #0x313720
    0x2ee214: b #0x2ee074
    0x2ee218: mov x22, x0
    0x2ee21c: bl #0x313720
    0x2ee220: mov x0, x22
    0x2ee224: bl #0x313498
    0x2ee228: brk #1

## SBAppViewController sceneHandle:didDestroyScene: @ 0x2ee22c
- Registration call PC: 0x2ed080
- Original IMP storage: 0x3ae008
- Original callback may be reached through *indirect* dynamic dispatch.
- Literal strings resolved: ['bundleIdentifier', 'isEqualToString:', 'isUIAppBridging', 'sharedInstanceIfExists', 'terminate']
- Conditional zero-return candidate sites: []
- Indirect calls: ['0x2ee3b4: blr x8']

### Bounded original ARM64
    0x2ee22c: stp x28, x27, [sp, #-0x60]!
    0x2ee230: stp x26, x25, [sp, #0x10]
    0x2ee234: stp x24, x23, [sp, #0x20]
    0x2ee238: stp x22, x21, [sp, #0x30]
    0x2ee23c: stp x20, x19, [sp, #0x40]
    0x2ee240: stp x29, x30, [sp, #0x50]
    0x2ee244: add x29, sp, #0x50
    0x2ee248: mov x20, x3
    0x2ee24c: mov x21, x1
    0x2ee250: mov x22, x0
    0x2ee254: mov x0, x2
    0x2ee258: bl #0x3137bc
    0x2ee25c: mov x19, x0
    0x2ee260: mov x0, x20
    0x2ee264: bl #0x3137bc
    0x2ee268: mov x20, x0
    0x2ee26c: nop 
    0x2ee270: ldr x0, #0x3aab00
    0x2ee274: nop 
    0x2ee278: ldr x1, #0x3a8e68 ; original literal='sharedInstanceIfExists'
    0x2ee27c: bl #0x313780
    0x2ee280: mov x29, x29
    0x2ee284: bl #0x3137e0
    0x2ee288: mov x23, x0
    0x2ee28c: cbz x0, #0x2ee39c
    0x2ee290: nop 
    0x2ee294: ldr x1, #0x3a8cf0 ; original literal='isUIAppBridging'
    0x2ee298: mov x0, x23
    0x2ee29c: bl #0x313780
    0x2ee2a0: cbz x20, #0x2ee39c
    0x2ee2a4: cbz w0, #0x2ee39c
    0x2ee2a8: mov x0, x20
    0x2ee2ac: bl #0x2eb9d4
    0x2ee2b0: mov x29, x29
    0x2ee2b4: bl #0x3137e0
    0x2ee2b8: mov x24, x0
    0x2ee2bc: cbz x0, #0x2ee394
    0x2ee2c0: nop 
    0x2ee2c4: ldr x26, #0x3a8198 ; original literal='bundleIdentifier'
    0x2ee2c8: mov x0, x23
    0x2ee2cc: mov x1, x26
    0x2ee2d0: bl #0x313780
    0x2ee2d4: mov x29, x29
    0x2ee2d8: bl #0x3137e0
    0x2ee2dc: mov x25, x0
    0x2ee2e0: nop 
    0x2ee2e4: ldr x8, #0x3ae028
    0x2ee2e8: cmn x8, #1
    0x2ee2ec: b.ne #0x2ee3e8
    0x2ee2f0: nop 
    0x2ee2f4: ldr x0, #0x3ae020
    0x2ee2f8: bl #0x3137bc
    0x2ee2fc: mov x27, x0
    0x2ee300: nop 
    0x2ee304: ldr x28, #0x3a81c0 ; original literal='isEqualToString:'
    0x2ee308: mov x0, x25
    0x2ee30c: mov x1, x28
    0x2ee310: mov x2, x27
    0x2ee314: bl #0x313780
    0x2ee318: cbz w0, #0x2ee330
    0x2ee31c: mov x0, x27
    0x2ee320: bl #0x3137b0
    0x2ee324: mov x0, x25
    0x2ee328: bl #0x3137b0
    0x2ee32c: b #0x2ee394
    0x2ee330: mov x0, x23
    0x2ee334: mov x1, x26
    0x2ee338: bl #0x313780
    0x2ee33c: mov x29, x29
    0x2ee340: bl #0x3137e0
    0x2ee344: mov x26, x0
    0x2ee348: mov x0, x24
    0x2ee34c: mov x1, x28
    0x2ee350: mov x2, x26
    0x2ee354: bl #0x313780
    0x2ee358: mov x28, x0
    0x2ee35c: mov x0, x26
    0x2ee360: bl #0x3137b0
    0x2ee364: mov x0, x27
    0x2ee368: bl #0x3137b0
    0x2ee36c: mov x0, x25
    0x2ee370: bl #0x3137b0
    0x2ee374: cbz w28, #0x2ee394
    0x2ee378: nop 
    0x2ee37c: ldr x1, #0x3aa610 ; original literal='terminate'
    0x2ee380: mov x0, x23
    0x2ee384: bl #0x313780
    0x2ee388: mov x0, x24
    0x2ee38c: bl #0x3137b0
    0x2ee390: b #0x2ee3b8
    0x2ee394: mov x0, x24
    0x2ee398: bl #0x3137b0
    0x2ee39c: nop 
    0x2ee3a0: ldr x8, #0x3ae008
    0x2ee3a4: mov x0, x22
    0x2ee3a8: mov x1, x21
    0x2ee3ac: mov x2, x19
    0x2ee3b0: mov x3, x20
    0x2ee3b4: blr x8
    0x2ee3b8: mov x0, x23
    0x2ee3bc: bl #0x3137b0
    0x2ee3c0: mov x0, x20
    0x2ee3c4: bl #0x3137b0
    0x2ee3c8: mov x0, x19
    0x2ee3cc: ldp x29, x30, [sp, #0x50]
    0x2ee3d0: ldp x20, x19, [sp, #0x40]
    0x2ee3d4: ldp x22, x21, [sp, #0x30]
    0x2ee3d8: ldp x24, x23, [sp, #0x20]
    0x2ee3dc: ldp x26, x25, [sp, #0x10]
    0x2ee3e0: ldp x28, x27, [sp], #0x60
    0x2ee3e4: b #0x3137b0
    0x2ee3e8: adr x0, #0x3ae028
    0x2ee3ec: nop 
    0x2ee3f0: adr x1, #0x372510
    0x2ee3f4: nop 
    0x2ee3f8: bl #0x313570
    0x2ee3fc: b #0x2ee2f0

## SBMainWorkspace systemService:isPasscodeLockedOrBlockedWithResult: @ 0x2ee400
- Registration call PC: 0x2ed0ac
- Original IMP storage: 0x3ae010
- Original callback may be reached through *indirect* dynamic dispatch.
- Literal strings resolved: ['isUIAppBridging', 'sharedInstanceIfExists']
- Conditional zero-return candidate sites: ['0x2ee490: mov w1, #0', '0x2ee494: mov x2, #0']
- Indirect calls: ['0x2ee498: blr x8', '0x2ee4c0: blr x8']

### Bounded original ARM64
    0x2ee400: stp x24, x23, [sp, #-0x40]!
    0x2ee404: stp x22, x21, [sp, #0x10]
    0x2ee408: stp x20, x19, [sp, #0x20]
    0x2ee40c: stp x29, x30, [sp, #0x30]
    0x2ee410: add x29, sp, #0x30
    0x2ee414: mov x20, x3
    0x2ee418: mov x21, x1
    0x2ee41c: mov x23, x0
    0x2ee420: mov x0, x2
    0x2ee424: bl #0x3137bc
    0x2ee428: mov x19, x0
    0x2ee42c: mov x0, x20
    0x2ee430: bl #0x3137bc
    0x2ee434: mov x20, x0
    0x2ee438: nop 
    0x2ee43c: ldr x0, #0x3aab00
    0x2ee440: nop 
    0x2ee444: ldr x1, #0x3a8e68 ; original literal='sharedInstanceIfExists'
    0x2ee448: bl #0x313780
    0x2ee44c: mov x29, x29
    0x2ee450: bl #0x3137e0
    0x2ee454: mov x22, x0
    0x2ee458: cbz x0, #0x2ee4a8
    0x2ee45c: nop 
    0x2ee460: ldr x1, #0x3a8cf0 ; original literal='isUIAppBridging'
    0x2ee464: mov x0, x22
    0x2ee468: bl #0x313780
    0x2ee46c: cbz w0, #0x2ee4a8
    0x2ee470: adr x0, #0x39e720
    0x2ee474: nop 
    0x2ee478: bl #0x2ec4d8
    0x2ee47c: cbz x20, #0x2ee4a8
    0x2ee480: mov x0, x20
    0x2ee484: bl #0x3137ec
    0x2ee488: mov x21, x0
    0x2ee48c: ldr x8, [x0, #0x10]
    0x2ee490: mov w1, #0
    0x2ee494: mov x2, #0
    0x2ee498: blr x8
    0x2ee49c: mov x0, x21
    0x2ee4a0: bl #0x3137b0
    0x2ee4a4: b #0x2ee4c4
    0x2ee4a8: nop 
    0x2ee4ac: ldr x8, #0x3ae010
    0x2ee4b0: mov x0, x23
    0x2ee4b4: mov x1, x21
    0x2ee4b8: mov x2, x19
    0x2ee4bc: mov x3, x20
    0x2ee4c0: blr x8
    0x2ee4c4: mov x0, x22
    0x2ee4c8: bl #0x3137b0
    0x2ee4cc: mov x0, x20
    0x2ee4d0: bl #0x3137b0
    0x2ee4d4: mov x0, x19
    0x2ee4d8: ldp x29, x30, [sp, #0x30]
    0x2ee4dc: ldp x20, x19, [sp, #0x20]
    0x2ee4e0: ldp x22, x21, [sp, #0x10]
    0x2ee4e4: ldp x24, x23, [sp], #0x40
    0x2ee4e8: b #0x3137b0

## SBMainWorkspace systemService:canActivateApplication:withResult: @ 0x2ee4ec
- Registration call PC: 0x2ed0d4
- Original IMP storage: 0x3ae018
- Original callback may be reached through *indirect* dynamic dispatch.
- Literal strings resolved: ['bundleIdentifier', 'class', 'isKindOfClass:', 'isUIAppBridging', 'performSelector:', 'respondsToSelector:', 'sharedInstanceIfExists', 'shouldBridge:']
- Conditional zero-return candidate sites: []
- Indirect calls: []

### Bounded original ARM64
    0x2ee4ec: sub sp, sp, #0x60
    0x2ee4f0: stp x26, x25, [sp, #0x10]
    0x2ee4f4: stp x24, x23, [sp, #0x20]
    0x2ee4f8: stp x22, x21, [sp, #0x30]
    0x2ee4fc: stp x20, x19, [sp, #0x40]
    0x2ee500: stp x29, x30, [sp, #0x50]
    0x2ee504: add x29, sp, #0x50
    0x2ee508: mov x21, x4
    0x2ee50c: mov x20, x3
    0x2ee510: mov x22, x1
    0x2ee514: mov x23, x0
    0x2ee518: mov x0, x2
    0x2ee51c: bl #0x3137bc
    0x2ee520: mov x19, x0
    0x2ee524: mov x0, x20
    0x2ee528: bl #0x3137bc
    0x2ee52c: mov x20, x0
    0x2ee530: mov x0, x21
    0x2ee534: bl #0x3137bc
    0x2ee538: mov x21, x0
    0x2ee53c: nop 
    0x2ee540: ldr x0, #0x3aab00
    0x2ee544: nop 
    0x2ee548: ldr x1, #0x3a8e68 ; original literal='sharedInstanceIfExists'
    0x2ee54c: bl #0x313780
    0x2ee550: mov x29, x29
    0x2ee554: bl #0x3137e0
    0x2ee558: mov x24, x0
    0x2ee55c: cbz x0, #0x2ee658
    0x2ee560: nop 
    0x2ee564: ldr x1, #0x3a8cf0 ; original literal='isUIAppBridging'
    0x2ee568: mov x0, x24
    0x2ee56c: bl #0x313780
    0x2ee570: cbz w0, #0x2ee658
    0x2ee574: nop 
    0x2ee578: ldr x0, #0x3aa998
    0x2ee57c: nop 
    0x2ee580: ldr x1, #0x3a8390 ; original literal='class'
    0x2ee584: bl #0x313780
    0x2ee588: mov x2, x0
    0x2ee58c: nop 
    0x2ee590: ldr x1, #0x3a8398 ; original literal='isKindOfClass:'
    0x2ee594: mov x0, x20
    0x2ee598: bl #0x313780
    0x2ee59c: cbz w0, #0x2ee5ac
    0x2ee5a0: mov x0, x20
    0x2ee5a4: bl #0x3137bc
    0x2ee5a8: b #0x2ee5e8
    0x2ee5ac: nop 
    0x2ee5b0: ldr x25, #0x3a8198 ; original literal='bundleIdentifier'
    0x2ee5b4: nop 
    0x2ee5b8: ldr x1, #0x3a8358 ; original literal='respondsToSelector:'
    0x2ee5bc: mov x0, x20
    0x2ee5c0: mov x2, x25
    0x2ee5c4: bl #0x313780
    0x2ee5c8: cbz w0, #0x2ee64c
    0x2ee5cc: nop 
    0x2ee5d0: ldr x1, #0x3a8a48 ; original literal='performSelector:'
    0x2ee5d4: mov x0, x20
    0x2ee5d8: mov x2, x25
    0x2ee5dc: bl #0x313780
    0x2ee5e0: mov x29, x29
    0x2ee5e4: bl #0x3137e0
    0x2ee5e8: mov x25, x0
    0x2ee5ec: cbz x0, #0x2ee650
    0x2ee5f0: nop 
    0x2ee5f4: ldr x1, #0x3a9f18 ; original literal='shouldBridge:'
    0x2ee5f8: mov x0, x24
    0x2ee5fc: mov x2, x25
    0x2ee600: bl #0x313780
    0x2ee604: cbz w0, #0x2ee650
    0x2ee608: str x25, [sp]

## Comparison target for independent DuoFace
- Original Native12 and DuoNavi both register the same 3 SBSuspendedUnderLockManager hooks; DuoNavi additionally registers SBMainWorkspace passcode/activation callbacks.
- A low-level no-background/no-underlock decision applies only for an owned, actively bridged scene; do not blanket bypass iPhone locks or non-owned apps.
- Current DuoFace FBScene foreground correction alone is not the same as returning before Apple's under-lock background decision.
- Current CPTemplate sceneWillResignActive hides DuoFace windows while Apple Dock remains; verify iPhone-lock-vs-CarPlay-Home ownership separately.
- No changes to QA120 native Dock sizing, .90 YouTube rotation, .92 divider; no build/DEB/Sileo or hardware Play result in this audit.
