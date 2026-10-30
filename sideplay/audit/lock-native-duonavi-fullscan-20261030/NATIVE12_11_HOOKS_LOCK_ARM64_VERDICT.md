# Original Native12 — all 11 installed hooks (3 specific under-lock hooks)

Original SHA256: `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`
Evidence: exact 11 MSHookMessageEx replacements are already verified in
`sideplay/audit/native12-foreground-hooks-20261027/HOOKS_AND_ARM64.json`.
This extends their 3 previously decoded windows to all 11, including the
**real SBSuspendedUnderLockManager selectors**. Disassembly is binary evidence
NOT proof the hook fires when the user locks iPhone or video plays.

## fbscene_update_settings 0x2c7e08..0x2c8410
- ARM64 instructions: 386
- Decoded literals: ['_canShowWhileLocked', '_deactivationReasons', '_foreground', '_frame', '_idleModeEnabled', '_isOccluded', '_occluded', '_underLock', 'canShowWhileLocked', 'class', 'deactivationReasons', 'frame', 'idleModeEnabled', 'isForeground', 'isOccluded', 'isUIAppBridging', 'isUnderLock', 'renderSizeForBundleID:', 'respondsToSelector:', 'setCanShowWhileLocked:', 'setDeactivationReasons:', 'setForeground:', 'setFrame:', 'setIdleModeEnabled:', 'setOccluded:', 'setUnderLock:', 'sharedInstanceIfExists', 'shouldBridge:']
- Call count: 88; branch count: 37

    0x2c7e08: sub sp, sp, #0x80
    0x2c7e0c: stp d9, d8, [sp, #0x10]
    0x2c7e10: stp x28, x27, [sp, #0x20]
    0x2c7e14: stp x26, x25, [sp, #0x30]
    0x2c7e18: stp x24, x23, [sp, #0x40]
    0x2c7e1c: stp x22, x21, [sp, #0x50]
    0x2c7e20: stp x20, x19, [sp, #0x60]
    0x2c7e24: stp x29, x30, [sp, #0x70]
    0x2c7e28: add x29, sp, #0x70
    0x2c7e2c: mov x23, x4
    0x2c7e30: mov x20, x3
    0x2c7e34: mov x21, x1
    0x2c7e38: mov x22, x0
    0x2c7e3c: mov x0, x2
    0x2c7e40: bl #0x2ecd3c
    0x2c7e44: mov x19, x0
    0x2c7e48: mov x0, x20
    0x2c7e4c: bl #0x2ecd3c
    0x2c7e50: mov x20, x0
    0x2c7e54: mov x0, x23
    0x2c7e58: bl #0x2ecd3c
    0x2c7e5c: mov x23, x0
    0x2c7e60: nop 
    0x2c7e64: ldr x0, #0x37f8d8
    0x2c7e68: nop 
    0x2c7e6c: ldr x1, #0x37e398 ; original_literal='sharedInstanceIfExists'
    0x2c7e70: bl #0x2ecd00
    0x2c7e74: mov x29, x29
    0x2c7e78: bl #0x2ecd60
    0x2c7e7c: mov x24, x0
    0x2c7e80: cbz x0, #0x2c8358
    0x2c7e84: nop 
    0x2c7e88: ldr x1, #0x37e218 ; original_literal='isUIAppBridging'
    0x2c7e8c: mov x0, x24
    0x2c7e90: bl #0x2ecd00
    0x2c7e94: cbz w0, #0x2c8358
    0x2c7e98: mov x0, x22
    0x2c7e9c: bl #0x2c6958
    0x2c7ea0: mov x29, x29
    0x2c7ea4: bl #0x2ecd60
    0x2c7ea8: mov x25, x0
    0x2c7eac: cbz x0, #0x2c8350
    0x2c7eb0: nop 
    0x2c7eb4: ldr x1, #0x37ed18 ; original_literal='shouldBridge:'
    0x2c7eb8: mov x0, x24
    0x2c7ebc: mov x2, x25
    0x2c7ec0: bl #0x2ecd00
    0x2c7ec4: cbz w0, #0x2c8350
    0x2c7ec8: nop 
    0x2c7ecc: ldr x1, #0x37ecf0 ; original_literal='renderSizeForBundleID:'
    0x2c7ed0: mov x0, x24
    0x2c7ed4: mov x2, x25
    0x2c7ed8: bl #0x2ecd00
    0x2c7edc: mov v8.16b, v0.16b
    0x2c7ee0: mov v9.16b, v1.16b
    0x2c7ee4: mov x0, x19
    0x2c7ee8: bl #0x2ecd3c
    0x2c7eec: mov x26, x0
    0x2c7ef0: cbz x0, #0x2c8348
    0x2c7ef4: fcmp d8, #0.0
    0x2c7ef8: b.le #0x2c7fb8
    0x2c7efc: fcmp d9, #0.0
    0x2c7f00: b.le #0x2c7fb8
    0x2c7f04: nop 
    0x2c7f08: ldr x2, #0x37e560 ; original_literal='frame'
    0x2c7f0c: nop 
    0x2c7f10: ldr x27, #0x37d5d8 ; original_literal='respondsToSelector:'
    0x2c7f14: mov x0, x26
    0x2c7f18: mov x1, x27
    0x2c7f1c: bl #0x2ecd00
    0x2c7f20: cbz w0, #0x2c7f4c
    0x2c7f24: adr x0, #0x30dd70 ; original_literal='frame'
    0x2c7f28: nop 
    0x2c7f2c: bl #0x2ecdfc
    0x2c7f30: mov x1, x0
    0x2c7f34: mov x0, x26
    0x2c7f38: bl #0x2ecd00
    0x2c7f3c: fcmp d2, d8
    0x2c7f40: b.ne #0x2c7f4c
    0x2c7f44: fcmp d3, d9
    0x2c7f48: b.eq #0x2c7fc0
    0x2c7f4c: nop 
    0x2c7f50: ldr x28, #0x37da10 ; original_literal='setFrame:'
    0x2c7f54: mov x0, x26
    0x2c7f58: mov x1, x27
    0x2c7f5c: mov x2, x28
    0x2c7f60: bl #0x2ecd00
    0x2c7f64: cbz w0, #0x2c7f84
    0x2c7f68: fmov d0, xzr
    0x2c7f6c: fmov d1, xzr
    0x2c7f70: mov x0, x26
    0x2c7f74: mov x1, x28
    0x2c7f78: mov v2.16b, v8.16b
    0x2c7f7c: mov v3.16b, v9.16b
    0x2c7f80: bl #0x2ecd00
    0x2c7f84: nop 
    0x2c7f88: ldr x1, #0x37d610 ; original_literal='class'
    0x2c7f8c: mov x0, x26
    0x2c7f90: bl #0x2ecd00
    0x2c7f94: adr x1, #0x308f16 ; original_literal='_frame'
    0x2c7f98: nop 
    0x2c7f9c: bl #0x2ecafc
    0x2c7fa0: cbz x0, #0x2c7fc0
    0x2c7fa4: bl #0x2ecbd4
    0x2c7fa8: add x8, x0, x26
    0x2c7fac: stp xzr, xzr, [x8]
    0x2c7fb0: stp d8, d9, [x8, #0x10]
    0x2c7fb4: b #0x2c7fc0
    0x2c7fb8: nop 
    0x2c7fbc: ldr x27, #0x37d5d8 ; original_literal='respondsToSelector:'
    0x2c7fc0: nop 
    0x2c7fc4: ldr x2, #0x37f368 ; original_literal='isForeground'
    0x2c7fc8: mov x0, x26
    0x2c7fcc: mov x1, x27
    0x2c7fd0: bl #0x2ecd00
    0x2c7fd4: cbz w0, #0x2c7ff4
    0x2c7fd8: adr x0, #0x30dd76 ; original_literal='isForeground'
    0x2c7fdc: nop 
    0x2c7fe0: bl #0x2ecdfc
    0x2c7fe4: mov x1, x0
    0x2c7fe8: mov x0, x26
    0x2c7fec: bl #0x2ecd00
    0x2c7ff0: tbnz w0, #0, #0x2c8054
    0x2c7ff4: nop 
    0x2c7ff8: ldr x2, #0x37e348 ; original_literal='setForeground:'
    0x2c7ffc: mov x0, x26
    0x2c8000: mov x1, x27
    0x2c8004: bl #0x2ecd00
    0x2c8008: cbz w0, #0x2c8028
    0x2c800c: adr x0, #0x308f1d ; original_literal='setForeground:'
    0x2c8010: nop 
    0x2c8014: bl #0x2ecdfc
    0x2c8018: mov x1, x0
    0x2c801c: mov x0, x26
    0x2c8020: mov w2, #1
    0x2c8024: bl #0x2ecd00
    0x2c8028: nop 
    0x2c802c: ldr x1, #0x37d610 ; original_literal='class'
    0x2c8030: mov x0, x26
    0x2c8034: bl #0x2ecd00
    0x2c8038: adr x1, #0x30dd83 ; original_literal='_foreground'
    0x2c803c: nop 
    0x2c8040: bl #0x2ecafc
    0x2c8044: cbz x0, #0x2c8054
    0x2c8048: bl #0x2ecbd4
    0x2c804c: mov w8, #1
    0x2c8050: strb w8, [x0, x26]
    0x2c8054: nop 
    0x2c8058: ldr x2, #0x37f090 ; original_literal='isOccluded'
    0x2c805c: mov x0, x26
    0x2c8060: mov x1, x27
    0x2c8064: bl #0x2ecd00
    0x2c8068: cbz w0, #0x2c8088
    0x2c806c: adr x0, #0x30dd8f ; original_literal='isOccluded'
    0x2c8070: nop 
    0x2c8074: bl #0x2ecdfc
    0x2c8078: mov x1, x0
    0x2c807c: mov x0, x26
    0x2c8080: bl #0x2ecd00
    0x2c8084: cbz w0, #0x2c8104
    0x2c8088: nop 
    0x2c808c: ldr x2, #0x37e350 ; original_literal='setOccluded:'
    0x2c8090: mov x0, x26
    0x2c8094: mov x1, x27
    0x2c8098: bl #0x2ecd00
    0x2c809c: cbz w0, #0x2c80bc
    0x2c80a0: adr x0, #0x308f2c ; original_literal='setOccluded:'
    0x2c80a4: nop 
    0x2c80a8: bl #0x2ecdfc
    0x2c80ac: mov x1, x0
    0x2c80b0: mov x0, x26
    0x2c80b4: mov w2, #0
    0x2c80b8: bl #0x2ecd00
    0x2c80bc: nop 
    0x2c80c0: ldr x28, #0x37d610 ; original_literal='class'
    0x2c80c4: mov x0, x26
    0x2c80c8: mov x1, x28
    0x2c80cc: bl #0x2ecd00
    0x2c80d0: adr x1, #0x30dd9a ; original_literal='_occluded'
    0x2c80d4: nop 
    0x2c80d8: bl #0x2ecafc
    0x2c80dc: cbnz x0, #0x2c80fc
    0x2c80e0: mov x0, x26
    0x2c80e4: mov x1, x28
    0x2c80e8: bl #0x2ecd00
    0x2c80ec: adr x1, #0x30dda4 ; original_literal='_isOccluded'
    0x2c80f0: nop 
    0x2c80f4: bl #0x2ecafc
    0x2c80f8: cbz x0, #0x2c8104
    0x2c80fc: bl #0x2ecbd4
    0x2c8100: strb wzr, [x0, x26]
    0x2c8104: nop 
    0x2c8108: ldr x2, #0x37f0a0 ; original_literal='isUnderLock'
    0x2c810c: mov x0, x26
    0x2c8110: mov x1, x27
    0x2c8114: bl #0x2ecd00
    0x2c8118: cbz w0, #0x2c8138
    0x2c811c: adr x0, #0x30ddb0 ; original_literal='isUnderLock'
    0x2c8120: nop 
    0x2c8124: bl #0x2ecdfc
    0x2c8128: mov x1, x0
    0x2c812c: mov x0, x26
    0x2c8130: bl #0x2ecd00
    0x2c8134: cbz w0, #0x2c8194
    0x2c8138: nop 
    0x2c813c: ldr x2, #0x37e358 ; original_literal='setUnderLock:'
    0x2c8140: mov x0, x26
    0x2c8144: mov x1, x27
    0x2c8148: bl #0x2ecd00
    0x2c814c: cbz w0, #0x2c816c
    0x2c8150: adr x0, #0x308f39 ; original_literal='setUnderLock:'
    0x2c8154: nop 
    0x2c8158: bl #0x2ecdfc
    0x2c815c: mov x1, x0
    0x2c8160: mov x0, x26
    0x2c8164: mov w2, #0
    0x2c8168: bl #0x2ecd00
    0x2c816c: nop 
    0x2c8170: ldr x1, #0x37d610 ; original_literal='class'
    0x2c8174: mov x0, x26
    0x2c8178: bl #0x2ecd00
    0x2c817c: adr x1, #0x30ddbc ; original_literal='_underLock'
    0x2c8180: nop 
    0x2c8184: bl #0x2ecafc
    0x2c8188: cbz x0, #0x2c8194
    0x2c818c: bl #0x2ecbd4
    0x2c8190: strb wzr, [x0, x26]
    0x2c8194: nop 
    0x2c8198: ldr x2, #0x37f0a8 ; original_literal='canShowWhileLocked'
    0x2c819c: mov x0, x26
    0x2c81a0: mov x1, x27
    0x2c81a4: bl #0x2ecd00
    0x2c81a8: cbz w0, #0x2c81c8
    0x2c81ac: adr x0, #0x30ddc7 ; original_literal='canShowWhileLocked'
    0x2c81b0: nop 
    0x2c81b4: bl #0x2ecdfc
    0x2c81b8: mov x1, x0
    0x2c81bc: mov x0, x26
    0x2c81c0: bl #0x2ecd00
    0x2c81c4: tbnz w0, #0, #0x2c8228
    0x2c81c8: nop 
    0x2c81cc: ldr x2, #0x37e360 ; original_literal='setCanShowWhileLocked:'
    0x2c81d0: mov x0, x26
    0x2c81d4: mov x1, x27
    0x2c81d8: bl #0x2ecd00
    0x2c81dc: cbz w0, #0x2c81fc
    0x2c81e0: adr x0, #0x308f47 ; original_literal='setCanShowWhileLocked:'
    0x2c81e4: nop 
    0x2c81e8: bl #0x2ecdfc
    0x2c81ec: mov x1, x0
    0x2c81f0: mov x0, x26
    0x2c81f4: mov w2, #1
    0x2c81f8: bl #0x2ecd00
    0x2c81fc: nop 
    0x2c8200: ldr x1, #0x37d610 ; original_literal='class'
    0x2c8204: mov x0, x26
    0x2c8208: bl #0x2ecd00
    0x2c820c: adr x1, #0x30ddda ; original_literal='_canShowWhileLocked'
    0x2c8210: nop 
    0x2c8214: bl #0x2ecafc
    0x2c8218: cbz x0, #0x2c8228
    0x2c821c: bl #0x2ecbd4
    0x2c8220: mov w8, #1
    0x2c8224: strb w8, [x0, x26]
    0x2c8228: nop 
    0x2c822c: ldr x2, #0x37f098 ; original_literal='deactivationReasons'
    0x2c8230: mov x0, x26
    0x2c8234: mov x1, x27
    0x2c8238: bl #0x2ecd00
    0x2c823c: cbz w0, #0x2c82b8
    0x2c8240: adr x0, #0x30ddee ; original_literal='deactivationReasons'
    0x2c8244: nop 
    0x2c8248: bl #0x2ecdfc
    0x2c824c: mov x1, x0
    0x2c8250: mov x0, x26
    0x2c8254: bl #0x2ecd00
    0x2c8258: cbz x0, #0x2c82b8
    0x2c825c: nop 
    0x2c8260: ldr x2, #0x37e368 ; original_literal='setDeactivationReasons:'
    0x2c8264: mov x0, x26
    0x2c8268: mov x1, x27
    0x2c826c: bl #0x2ecd00
    0x2c8270: cbz w0, #0x2c8290
    0x2c8274: adr x0, #0x308f5e ; original_literal='setDeactivationReasons:'
    0x2c8278: nop 
    0x2c827c: bl #0x2ecdfc
    0x2c8280: mov x1, x0
    0x2c8284: mov x0, x26
    0x2c8288: mov x2, #0
    0x2c828c: bl #0x2ecd00
    0x2c8290: nop 
    0x2c8294: ldr x1, #0x37d610 ; original_literal='class'
    0x2c8298: mov x0, x26
    0x2c829c: bl #0x2ecd00
    0x2c82a0: adr x1, #0x30de02 ; original_literal='_deactivationReasons'
    0x2c82a4: nop 
    0x2c82a8: bl #0x2ecafc
    0x2c82ac: cbz x0, #0x2c82b8
    0x2c82b0: bl #0x2ecbd4
    0x2c82b4: str xzr, [x0, x26]
    0x2c82b8: nop 
    0x2c82bc: ldr x2, #0x37f370 ; original_literal='idleModeEnabled'
    0x2c82c0: mov x0, x26
    0x2c82c4: mov x1, x27
    0x2c82c8: bl #0x2ecd00
    0x2c82cc: cbz w0, #0x2c82ec
    0x2c82d0: adr x0, #0x30de17 ; original_literal='idleModeEnabled'
    0x2c82d4: nop 
    0x2c82d8: bl #0x2ecdfc
    0x2c82dc: mov x1, x0
    0x2c82e0: mov x0, x26
    0x2c82e4: bl #0x2ecd00
    0x2c82e8: cbz w0, #0x2c8348
    0x2c82ec: nop 
    0x2c82f0: ldr x2, #0x37e370 ; original_literal='setIdleModeEnabled:'
    0x2c82f4: mov x0, x26
    0x2c82f8: mov x1, x27
    0x2c82fc: bl #0x2ecd00
    0x2c8300: cbz w0, #0x2c8320
    0x2c8304: adr x0, #0x308f76 ; original_literal='setIdleModeEnabled:'
    0x2c8308: nop 
    0x2c830c: bl #0x2ecdfc
    0x2c8310: mov x1, x0
    0x2c8314: mov x0, x26
    0x2c8318: mov w2, #0
    0x2c831c: bl #0x2ecd00
    0x2c8320: nop 
    0x2c8324: ldr x1, #0x37d610 ; original_literal='class'
    0x2c8328: mov x0, x26
    0x2c832c: bl #0x2ecd00
    0x2c8330: adr x1, #0x30de27 ; original_literal='_idleModeEnabled'
    0x2c8334: nop 
    0x2c8338: bl #0x2ecafc
    0x2c833c: cbz x0, #0x2c8348
    0x2c8340: bl #0x2ecbd4
    0x2c8344: strb wzr, [x0, x26]
    0x2c8348: mov x0, x26
    0x2c834c: bl #0x2ecd30
    0x2c8350: mov x0, x25
    0x2c8354: bl #0x2ecd30
    0x2c8358: nop 
    0x2c835c: ldr x8, #0x382108
    0x2c8360: mov x0, x22
    0x2c8364: mov x1, x21
    0x2c8368: mov x2, x19
    0x2c836c: mov x3, x20
    0x2c8370: mov x4, x23
    0x2c8374: blr x8
    0x2c8378: mov x0, x24
    0x2c837c: bl #0x2ecd30
    0x2c8380: mov x0, x23
    0x2c8384: bl #0x2ecd30
    0x2c8388: mov x0, x20
    0x2c838c: bl #0x2ecd30
    0x2c8390: mov x0, x19
    0x2c8394: ldp x29, x30, [sp, #0x70]
    0x2c8398: ldp x20, x19, [sp, #0x60]
    0x2c839c: ldp x22, x21, [sp, #0x50]
    0x2c83a0: ldp x24, x23, [sp, #0x40]
    0x2c83a4: ldp x26, x25, [sp, #0x30]
    0x2c83a8: ldp x28, x27, [sp, #0x20]
    0x2c83ac: ldp d9, d8, [sp, #0x10]
    0x2c83b0: add sp, sp, #0x80
    0x2c83b4: b #0x2ecd30
    0x2c83b8: b #0x2c83bc
    0x2c83bc: mov x25, x0
    0x2c83c0: cmp w1, #1
    0x2c83c4: b.ne #0x2c8404
    0x2c83c8: mov x0, x25
    0x2c83cc: bl #0x2ecc88
    0x2c83d0: mov x29, x29
    0x2c83d4: bl #0x2ecd60
    0x2c83d8: mov x25, x0
    0x2c83dc: str x0, [sp]
    0x2c83e0: adr x0, #0x3735c8
    0x2c83e4: nop 
    0x2c83e8: bl #0x2c745c
    0x2c83ec: mov x0, x25
    0x2c83f0: bl #0x2ecd30
    0x2c83f4: bl #0x2eccac
    0x2c83f8: b #0x2c8358
    0x2c83fc: mov x25, x0
    0x2c8400: bl #0x2eccac
    0x2c8404: mov x0, x25
    0x2c8408: bl #0x2eca84
    0x2c840c: brk #1

## fbscene_apply_update 0x2c8410..0x2c85d0
- ARM64 instructions: 112
- Decoded literals: ['isUIAppBridging', 'performSelector:', 'renderSizeForBundleID:', 'respondsToSelector:', 'settings', 'sharedInstanceIfExists', 'shouldBridge:']
- Call count: 25; branch count: 10

    0x2c8410: sub sp, sp, #0x60
    0x2c8414: stp x26, x25, [sp, #0x10]
    0x2c8418: stp x24, x23, [sp, #0x20]
    0x2c841c: stp x22, x21, [sp, #0x30]
    0x2c8420: stp x20, x19, [sp, #0x40]
    0x2c8424: stp x29, x30, [sp, #0x50]
    0x2c8428: add x29, sp, #0x50
    0x2c842c: mov x22, x3
    0x2c8430: mov x20, x1
    0x2c8434: mov x21, x0
    0x2c8438: mov x0, x2
    0x2c843c: bl #0x2ecd3c
    0x2c8440: mov x19, x0
    0x2c8444: mov x0, x22
    0x2c8448: bl #0x2ecd3c
    0x2c844c: mov x22, x0
    0x2c8450: nop 
    0x2c8454: ldr x0, #0x37f8d8
    0x2c8458: nop 
    0x2c845c: ldr x1, #0x37e398 ; original_literal='sharedInstanceIfExists'
    0x2c8460: bl #0x2ecd00
    0x2c8464: mov x29, x29
    0x2c8468: bl #0x2ecd60
    0x2c846c: mov x23, x0
    0x2c8470: cbz x0, #0x2c8528
    0x2c8474: nop 
    0x2c8478: ldr x1, #0x37e218 ; original_literal='isUIAppBridging'
    0x2c847c: mov x0, x23
    0x2c8480: bl #0x2ecd00
    0x2c8484: cbz x19, #0x2c8528
    0x2c8488: cbz w0, #0x2c8528
    0x2c848c: mov x0, x21
    0x2c8490: bl #0x2c6958
    0x2c8494: mov x29, x29
    0x2c8498: bl #0x2ecd60
    0x2c849c: mov x24, x0
    0x2c84a0: cbz x0, #0x2c8520
    0x2c84a4: nop 
    0x2c84a8: ldr x1, #0x37ed18 ; original_literal='shouldBridge:'
    0x2c84ac: mov x0, x23
    0x2c84b0: mov x2, x24
    0x2c84b4: bl #0x2ecd00
    0x2c84b8: cbz w0, #0x2c8520
    0x2c84bc: nop 
    0x2c84c0: ldr x25, #0x37e500 ; original_literal='settings'
    0x2c84c4: nop 
    0x2c84c8: ldr x1, #0x37d5d8 ; original_literal='respondsToSelector:'
    0x2c84cc: mov x0, x19
    0x2c84d0: mov x2, x25
    0x2c84d4: bl #0x2ecd00
    0x2c84d8: cbz w0, #0x2c8520
    0x2c84dc: nop 
    0x2c84e0: ldr x1, #0x37dfc8 ; original_literal='performSelector:'
    0x2c84e4: mov x0, x19
    0x2c84e8: mov x2, x25
    0x2c84ec: bl #0x2ecd00
    0x2c84f0: mov x29, x29
    0x2c84f4: bl #0x2ecd60
    0x2c84f8: mov x25, x0
    0x2c84fc: nop 
    0x2c8500: ldr x1, #0x37ecf0 ; original_literal='renderSizeForBundleID:'
    0x2c8504: mov x0, x23
    0x2c8508: mov x2, x24
    0x2c850c: bl #0x2ecd00
    0x2c8510: mov x0, x25
    0x2c8514: bl #0x2c77cc
    0x2c8518: mov x0, x25
    0x2c851c: bl #0x2ecd30
    0x2c8520: mov x0, x24
    0x2c8524: bl #0x2ecd30
    0x2c8528: nop 
    0x2c852c: ldr x8, #0x382110
    0x2c8530: mov x0, x21
    0x2c8534: mov x1, x20
    0x2c8538: mov x2, x19
    0x2c853c: mov x3, x22
    0x2c8540: blr x8
    0x2c8544: mov x0, x23
    0x2c8548: bl #0x2ecd30
    0x2c854c: mov x0, x22
    0x2c8550: bl #0x2ecd30
    0x2c8554: mov x0, x19
    0x2c8558: ldp x29, x30, [sp, #0x50]
    0x2c855c: ldp x20, x19, [sp, #0x40]
    0x2c8560: ldp x22, x21, [sp, #0x30]
    0x2c8564: ldp x24, x23, [sp, #0x20]
    0x2c8568: ldp x26, x25, [sp, #0x10]
    0x2c856c: add sp, sp, #0x60
    0x2c8570: b #0x2ecd30
    0x2c8574: b #0x2c857c
    0x2c8578: b #0x2c857c
    0x2c857c: mov x24, x0
    0x2c8580: cmp w1, #1
    0x2c8584: b.ne #0x2c85c4
    0x2c8588: mov x0, x24
    0x2c858c: bl #0x2ecc88
    0x2c8590: mov x29, x29
    0x2c8594: bl #0x2ecd60
    0x2c8598: mov x24, x0
    0x2c859c: str x0, [sp]
    0x2c85a0: adr x0, #0x3735e8
    0x2c85a4: nop 
    0x2c85a8: bl #0x2ec9ac
    0x2c85ac: mov x0, x24
    0x2c85b0: bl #0x2ecd30
    0x2c85b4: bl #0x2eccac
    0x2c85b8: b #0x2c8528
    0x2c85bc: mov x24, x0
    0x2c85c0: bl #0x2eccac
    0x2c85c4: mov x0, x24
    0x2c85c8: bl #0x2eca84
    0x2c85cc: brk #1

## scene_prepare_update 0x2c85d0..0x2c8668
- ARM64 instructions: 38
- Decoded literals: ['_updateFrameAndTransform', 'isUIAppBridging', 'respondsToSelector:', 'sharedInstanceIfExists']
- Call count: 6; branch count: 4

    0x2c85d0: stp x22, x21, [sp, #-0x30]!
    0x2c85d4: stp x20, x19, [sp, #0x10]
    0x2c85d8: stp x29, x30, [sp, #0x20]
    0x2c85dc: add x29, sp, #0x20
    0x2c85e0: mov x19, x0
    0x2c85e4: nop 
    0x2c85e8: ldr x8, #0x382118
    0x2c85ec: blr x8
    0x2c85f0: nop 
    0x2c85f4: ldr x0, #0x37f8d8
    0x2c85f8: nop 
    0x2c85fc: ldr x1, #0x37e398 ; original_literal='sharedInstanceIfExists'
    0x2c8600: bl #0x2ecd00
    0x2c8604: mov x29, x29
    0x2c8608: bl #0x2ecd60
    0x2c860c: mov x20, x0
    0x2c8610: cbz x0, #0x2c8654
    0x2c8614: nop 
    0x2c8618: ldr x1, #0x37e218 ; original_literal='isUIAppBridging'
    0x2c861c: mov x0, x20
    0x2c8620: bl #0x2ecd00
    0x2c8624: cbz w0, #0x2c8654
    0x2c8628: nop 
    0x2c862c: ldr x21, #0x37f378 ; original_literal='_updateFrameAndTransform'
    0x2c8630: nop 
    0x2c8634: ldr x1, #0x37d5d8 ; original_literal='respondsToSelector:'
    0x2c8638: mov x0, x19
    0x2c863c: mov x2, x21
    0x2c8640: bl #0x2ecd00
    0x2c8644: cbz w0, #0x2c8654
    0x2c8648: mov x0, x19
    0x2c864c: mov x1, x21
    0x2c8650: bl #0x2ecd00
    0x2c8654: mov x0, x20
    0x2c8658: ldp x29, x30, [sp, #0x20]
    0x2c865c: ldp x20, x19, [sp, #0x10]
    0x2c8660: ldp x22, x21, [sp], #0x30
    0x2c8664: b #0x2ecd30

## underlock_intercept_update 0x2c8668..0x2c8768
- ARM64 instructions: 64
- Decoded literals: ['isUIAppBridging', 'renderSizeForBundleID:', 'sharedInstanceIfExists', 'shouldBridge:']
- Call count: 14; branch count: 5

    0x2c8668: stp x22, x21, [sp, #-0x30]!
    0x2c866c: stp x20, x19, [sp, #0x10]
    0x2c8670: stp x29, x30, [sp, #0x20]
    0x2c8674: add x29, sp, #0x20
    0x2c8678: mov x20, x3
    0x2c867c: mov x21, x1
    0x2c8680: mov x22, x0
    0x2c8684: mov x0, x2
    0x2c8688: bl #0x2ecd3c
    0x2c868c: mov x19, x0
    0x2c8690: mov x0, x20
    0x2c8694: bl #0x2ecd3c
    0x2c8698: mov x20, x0
    0x2c869c: nop 
    0x2c86a0: ldr x8, #0x382120
    0x2c86a4: mov x0, x22
    0x2c86a8: mov x1, x21
    0x2c86ac: mov x2, x19
    0x2c86b0: mov x3, x20
    0x2c86b4: blr x8
    0x2c86b8: nop 
    0x2c86bc: ldr x0, #0x37f8d8
    0x2c86c0: nop 
    0x2c86c4: ldr x1, #0x37e398 ; original_literal='sharedInstanceIfExists'
    0x2c86c8: bl #0x2ecd00
    0x2c86cc: mov x29, x29
    0x2c86d0: bl #0x2ecd60
    0x2c86d4: mov x21, x0
    0x2c86d8: cbz x0, #0x2c8744
    0x2c86dc: nop 
    0x2c86e0: ldr x1, #0x37e218 ; original_literal='isUIAppBridging'
    0x2c86e4: mov x0, x21
    0x2c86e8: bl #0x2ecd00
    0x2c86ec: cbz w0, #0x2c8744
    0x2c86f0: mov x0, x19
    0x2c86f4: bl #0x2c6958
    0x2c86f8: mov x29, x29
    0x2c86fc: bl #0x2ecd60
    0x2c8700: mov x22, x0
    0x2c8704: cbz x0, #0x2c873c
    0x2c8708: nop 
    0x2c870c: ldr x1, #0x37ed18 ; original_literal='shouldBridge:'
    0x2c8710: mov x0, x21
    0x2c8714: mov x2, x22
    0x2c8718: bl #0x2ecd00
    0x2c871c: cbz w0, #0x2c873c
    0x2c8720: nop 
    0x2c8724: ldr x1, #0x37ecf0 ; original_literal='renderSizeForBundleID:'
    0x2c8728: mov x0, x21
    0x2c872c: mov x2, x22
    0x2c8730: bl #0x2ecd00
    0x2c8734: mov x0, x20
    0x2c8738: bl #0x2c77cc
    0x2c873c: mov x0, x22
    0x2c8740: bl #0x2ecd30
    0x2c8744: mov x0, x21
    0x2c8748: bl #0x2ecd30
    0x2c874c: mov x0, x20
    0x2c8750: bl #0x2ecd30
    0x2c8754: mov x0, x19
    0x2c8758: ldp x29, x30, [sp, #0x20]
    0x2c875c: ldp x20, x19, [sp, #0x10]
    0x2c8760: ldp x22, x21, [sp], #0x30
    0x2c8764: b #0x2ecd30

## underlock_should_background 0x2c8768..0x2c8870
- ARM64 instructions: 66
- Decoded literals: ['isUIAppBridging', 'sharedInstanceIfExists', 'shouldBridge:']
- Call count: 14; branch count: 5

    0x2c8768: stp x24, x23, [sp, #-0x40]!
    0x2c876c: stp x22, x21, [sp, #0x10]
    0x2c8770: stp x20, x19, [sp, #0x20]
    0x2c8774: stp x29, x30, [sp, #0x30]
    0x2c8778: add x29, sp, #0x30
    0x2c877c: mov x20, x3
    0x2c8780: mov x21, x1
    0x2c8784: mov x22, x0
    0x2c8788: mov x0, x2
    0x2c878c: bl #0x2ecd3c
    0x2c8790: mov x19, x0
    0x2c8794: mov x0, x20
    0x2c8798: bl #0x2ecd3c
    0x2c879c: mov x20, x0
    0x2c87a0: nop 
    0x2c87a4: ldr x0, #0x37f8d8
    0x2c87a8: nop 
    0x2c87ac: ldr x1, #0x37e398 ; original_literal='sharedInstanceIfExists'
    0x2c87b0: bl #0x2ecd00
    0x2c87b4: mov x29, x29
    0x2c87b8: bl #0x2ecd60
    0x2c87bc: mov x23, x0
    0x2c87c0: cbz x0, #0x2c8820
    0x2c87c4: nop 
    0x2c87c8: ldr x1, #0x37e218 ; original_literal='isUIAppBridging'
    0x2c87cc: mov x0, x23
    0x2c87d0: bl #0x2ecd00
    0x2c87d4: cbz w0, #0x2c8820
    0x2c87d8: mov x0, x19
    0x2c87dc: bl #0x2c6958
    0x2c87e0: mov x29, x29
    0x2c87e4: bl #0x2ecd60
    0x2c87e8: mov x24, x0
    0x2c87ec: cbz x0, #0x2c8818
    0x2c87f0: nop 
    0x2c87f4: ldr x1, #0x37ed18 ; original_literal='shouldBridge:'
    0x2c87f8: mov x0, x23
    0x2c87fc: mov x2, x24
    0x2c8800: bl #0x2ecd00
    0x2c8804: cbz w0, #0x2c8818
    0x2c8808: mov x0, x24
    0x2c880c: bl #0x2ecd30
    0x2c8810: mov w21, #0
    0x2c8814: b #0x2c8840
    0x2c8818: mov x0, x24
    0x2c881c: bl #0x2ecd30
    0x2c8820: nop 
    0x2c8824: ldr x8, #0x382128
    0x2c8828: mov x0, x22
    0x2c882c: mov x1, x21
    0x2c8830: mov x2, x19
    0x2c8834: mov x3, x20
    0x2c8838: blr x8
    0x2c883c: mov x21, x0
    0x2c8840: mov x0, x23
    0x2c8844: bl #0x2ecd30
    0x2c8848: mov x0, x20
    0x2c884c: bl #0x2ecd30
    0x2c8850: mov x0, x19
    0x2c8854: bl #0x2ecd30
    0x2c8858: mov x0, x21
    0x2c885c: ldp x29, x30, [sp, #0x30]
    0x2c8860: ldp x20, x19, [sp, #0x20]
    0x2c8864: ldp x22, x21, [sp, #0x10]
    0x2c8868: ldp x24, x23, [sp], #0x40
    0x2c886c: ret 

## underlock_should_underlock 0x2c8870..0x2c895c
- ARM64 instructions: 59
- Decoded literals: ['isUIAppBridging', 'sharedInstanceIfExists', 'shouldBridge:']
- Call count: 12; branch count: 5

    0x2c8870: stp x24, x23, [sp, #-0x40]!
    0x2c8874: stp x22, x21, [sp, #0x10]
    0x2c8878: stp x20, x19, [sp, #0x20]
    0x2c887c: stp x29, x30, [sp, #0x30]
    0x2c8880: add x29, sp, #0x30
    0x2c8884: mov x20, x1
    0x2c8888: mov x21, x0
    0x2c888c: mov x0, x2
    0x2c8890: bl #0x2ecd3c
    0x2c8894: mov x19, x0
    0x2c8898: nop 
    0x2c889c: ldr x0, #0x37f8d8
    0x2c88a0: nop 
    0x2c88a4: ldr x1, #0x37e398 ; original_literal='sharedInstanceIfExists'
    0x2c88a8: bl #0x2ecd00
    0x2c88ac: mov x29, x29
    0x2c88b0: bl #0x2ecd60
    0x2c88b4: mov x22, x0
    0x2c88b8: cbz x0, #0x2c8918
    0x2c88bc: nop 
    0x2c88c0: ldr x1, #0x37e218 ; original_literal='isUIAppBridging'
    0x2c88c4: mov x0, x22
    0x2c88c8: bl #0x2ecd00
    0x2c88cc: cbz w0, #0x2c8918
    0x2c88d0: mov x0, x19
    0x2c88d4: bl #0x2c6958
    0x2c88d8: mov x29, x29
    0x2c88dc: bl #0x2ecd60
    0x2c88e0: mov x23, x0
    0x2c88e4: cbz x0, #0x2c8910
    0x2c88e8: nop 
    0x2c88ec: ldr x1, #0x37ed18 ; original_literal='shouldBridge:'
    0x2c88f0: mov x0, x22
    0x2c88f4: mov x2, x23
    0x2c88f8: bl #0x2ecd00
    0x2c88fc: cbz w0, #0x2c8910
    0x2c8900: mov x0, x23
    0x2c8904: bl #0x2ecd30
    0x2c8908: mov w20, #0
    0x2c890c: b #0x2c8934
    0x2c8910: mov x0, x23
    0x2c8914: bl #0x2ecd30
    0x2c8918: nop 
    0x2c891c: ldr x8, #0x382130
    0x2c8920: mov x0, x21
    0x2c8924: mov x1, x20
    0x2c8928: mov x2, x19
    0x2c892c: blr x8
    0x2c8930: mov x20, x0
    0x2c8934: mov x0, x22
    0x2c8938: bl #0x2ecd30
    0x2c893c: mov x0, x19
    0x2c8940: bl #0x2ecd30
    0x2c8944: mov x0, x20
    0x2c8948: ldp x29, x30, [sp, #0x30]
    0x2c894c: ldp x20, x19, [sp, #0x20]
    0x2c8950: ldp x22, x21, [sp, #0x10]
    0x2c8954: ldp x24, x23, [sp], #0x40
    0x2c8958: ret 

## scene_reference_size 0x2c895c..0x2c8a50
- ARM64 instructions: 61
- Decoded literals: ['isUIAppBridging', 'renderSizeForBundleID:', 'sharedInstanceIfExists', 'shouldBridge:']
- Call count: 9; branch count: 5

    0x2c895c: stp d9, d8, [sp, #-0x50]!
    0x2c8960: stp x24, x23, [sp, #0x10]
    0x2c8964: stp x22, x21, [sp, #0x20]
    0x2c8968: stp x20, x19, [sp, #0x30]
    0x2c896c: stp x29, x30, [sp, #0x40]
    0x2c8970: add x29, sp, #0x40
    0x2c8974: mov x19, x2
    0x2c8978: mov v8.16b, v1.16b
    0x2c897c: mov v9.16b, v0.16b
    0x2c8980: mov x20, x1
    0x2c8984: mov x21, x0
    0x2c8988: nop 
    0x2c898c: ldr x0, #0x37f8d8
    0x2c8990: nop 
    0x2c8994: ldr x1, #0x37e398 ; original_literal='sharedInstanceIfExists'
    0x2c8998: bl #0x2ecd00
    0x2c899c: mov x29, x29
    0x2c89a0: bl #0x2ecd60
    0x2c89a4: mov x22, x0
    0x2c89a8: cbz x0, #0x2c8a14
    0x2c89ac: nop 
    0x2c89b0: ldr x1, #0x37e218 ; original_literal='isUIAppBridging'
    0x2c89b4: mov x0, x22
    0x2c89b8: bl #0x2ecd00
    0x2c89bc: cbz w0, #0x2c8a14
    0x2c89c0: mov x0, x21
    0x2c89c4: bl #0x2c93c4
    0x2c89c8: mov x29, x29
    0x2c89cc: bl #0x2ecd60
    0x2c89d0: mov x23, x0
    0x2c89d4: cbz x0, #0x2c8a0c
    0x2c89d8: nop 
    0x2c89dc: ldr x1, #0x37ed18 ; original_literal='shouldBridge:'
    0x2c89e0: mov x0, x22
    0x2c89e4: mov x2, x23
    0x2c89e8: bl #0x2ecd00
    0x2c89ec: cbz w0, #0x2c8a0c
    0x2c89f0: nop 
    0x2c89f4: ldr x1, #0x37ecf0 ; original_literal='renderSizeForBundleID:'
    0x2c89f8: mov x0, x22
    0x2c89fc: mov x2, x23
    0x2c8a00: bl #0x2ecd00
    0x2c8a04: mov v9.16b, v0.16b
    0x2c8a08: mov v8.16b, v1.16b
    0x2c8a0c: mov x0, x23
    0x2c8a10: bl #0x2ecd30
    0x2c8a14: nop 
    0x2c8a18: ldr x8, #0x382138
    0x2c8a1c: mov x0, x21
    0x2c8a20: mov x1, x20
    0x2c8a24: mov v0.16b, v9.16b
    0x2c8a28: mov v1.16b, v8.16b
    0x2c8a2c: mov x2, x19
    0x2c8a30: blr x8
    0x2c8a34: mov x0, x22
    0x2c8a38: ldp x29, x30, [sp, #0x40]
    0x2c8a3c: ldp x20, x19, [sp, #0x30]
    0x2c8a40: ldp x22, x21, [sp, #0x20]
    0x2c8a44: ldp x24, x23, [sp, #0x10]
    0x2c8a48: ldp d9, d8, [sp], #0x50
    0x2c8a4c: b #0x2ecd30

## scene_reference_orientation 0x2c8a50..0x2c8b4c
- ARM64 instructions: 63
- Decoded literals: ['isUIAppBridging', 'renderSizeForBundleID:', 'sharedInstanceIfExists', 'shouldBridge:']
- Call count: 9; branch count: 5

    0x2c8a50: stp d9, d8, [sp, #-0x50]!
    0x2c8a54: stp x24, x23, [sp, #0x10]
    0x2c8a58: stp x22, x21, [sp, #0x20]
    0x2c8a5c: stp x20, x19, [sp, #0x30]
    0x2c8a60: stp x29, x30, [sp, #0x40]
    0x2c8a64: add x29, sp, #0x40
    0x2c8a68: mov x19, x3
    0x2c8a6c: mov x20, x2
    0x2c8a70: mov v8.16b, v1.16b
    0x2c8a74: mov v9.16b, v0.16b
    0x2c8a78: mov x21, x1
    0x2c8a7c: mov x22, x0
    0x2c8a80: nop 
    0x2c8a84: ldr x0, #0x37f8d8
    0x2c8a88: nop 
    0x2c8a8c: ldr x1, #0x37e398 ; original_literal='sharedInstanceIfExists'
    0x2c8a90: bl #0x2ecd00
    0x2c8a94: mov x29, x29
    0x2c8a98: bl #0x2ecd60
    0x2c8a9c: mov x23, x0
    0x2c8aa0: cbz x0, #0x2c8b0c
    0x2c8aa4: nop 
    0x2c8aa8: ldr x1, #0x37e218 ; original_literal='isUIAppBridging'
    0x2c8aac: mov x0, x23
    0x2c8ab0: bl #0x2ecd00
    0x2c8ab4: cbz w0, #0x2c8b0c
    0x2c8ab8: mov x0, x22
    0x2c8abc: bl #0x2c93c4
    0x2c8ac0: mov x29, x29
    0x2c8ac4: bl #0x2ecd60
    0x2c8ac8: mov x24, x0
    0x2c8acc: cbz x0, #0x2c8b04
    0x2c8ad0: nop 
    0x2c8ad4: ldr x1, #0x37ed18 ; original_literal='shouldBridge:'
    0x2c8ad8: mov x0, x23
    0x2c8adc: mov x2, x24
    0x2c8ae0: bl #0x2ecd00
    0x2c8ae4: cbz w0, #0x2c8b04
    0x2c8ae8: nop 
    0x2c8aec: ldr x1, #0x37ecf0 ; original_literal='renderSizeForBundleID:'
    0x2c8af0: mov x0, x23
    0x2c8af4: mov x2, x24
    0x2c8af8: bl #0x2ecd00
    0x2c8afc: mov v9.16b, v0.16b
    0x2c8b00: mov v8.16b, v1.16b
    0x2c8b04: mov x0, x24
    0x2c8b08: bl #0x2ecd30
    0x2c8b0c: nop 
    0x2c8b10: ldr x8, #0x382140
    0x2c8b14: mov x0, x22
    0x2c8b18: mov x1, x21
    0x2c8b1c: mov v0.16b, v9.16b
    0x2c8b20: mov v1.16b, v8.16b
    0x2c8b24: mov x2, x20
    0x2c8b28: mov x3, x19
    0x2c8b2c: blr x8
    0x2c8b30: mov x0, x23
    0x2c8b34: ldp x29, x30, [sp, #0x40]
    0x2c8b38: ldp x20, x19, [sp, #0x30]
    0x2c8b3c: ldp x22, x21, [sp, #0x20]
    0x2c8b40: ldp x24, x23, [sp, #0x10]
    0x2c8b44: ldp d9, d8, [sp], #0x50
    0x2c8b48: b #0x2ecd30

## scene_supports_orientation 0x2c8b4c..0x2c8ca8
- ARM64 instructions: 87
- Decoded literals: ['application', 'bundleIdentifier', 'isUIAppBridging', 'respondsToSelector:', 'sharedInstanceIfExists', 'shouldBridge:']
- Call count: 16; branch count: 8

    0x2c8b4c: stp x26, x25, [sp, #-0x50]!
    0x2c8b50: stp x24, x23, [sp, #0x10]
    0x2c8b54: stp x22, x21, [sp, #0x20]
    0x2c8b58: stp x20, x19, [sp, #0x30]
    0x2c8b5c: stp x29, x30, [sp, #0x40]
    0x2c8b60: add x29, sp, #0x40
    0x2c8b64: mov x19, x2
    0x2c8b68: mov x21, x1
    0x2c8b6c: mov x22, x0
    0x2c8b70: nop 
    0x2c8b74: ldr x0, #0x37f8d8
    0x2c8b78: nop 
    0x2c8b7c: ldr x1, #0x37e398 ; original_literal='sharedInstanceIfExists'
    0x2c8b80: bl #0x2ecd00
    0x2c8b84: mov x29, x29
    0x2c8b88: bl #0x2ecd60
    0x2c8b8c: mov x20, x0
    0x2c8b90: cbz x0, #0x2c8c68
    0x2c8b94: nop 
    0x2c8b98: ldr x1, #0x37e218 ; original_literal='isUIAppBridging'
    0x2c8b9c: mov x0, x20
    0x2c8ba0: bl #0x2ecd00
    0x2c8ba4: cbz w0, #0x2c8c68
    0x2c8ba8: nop 
    0x2c8bac: ldr x23, #0x37f2f8 ; original_literal='application'
    0x2c8bb0: nop 
    0x2c8bb4: ldr x24, #0x37d5d8 ; original_literal='respondsToSelector:'
    0x2c8bb8: mov x0, x22
    0x2c8bbc: mov x1, x24
    0x2c8bc0: mov x2, x23
    0x2c8bc4: bl #0x2ecd00
    0x2c8bc8: cbz w0, #0x2c8c68
    0x2c8bcc: mov x0, x22
    0x2c8bd0: mov x1, x23
    0x2c8bd4: bl #0x2ecd00
    0x2c8bd8: mov x29, x29
    0x2c8bdc: bl #0x2ecd60
    0x2c8be0: mov x23, x0
    0x2c8be4: cbz x0, #0x2c8c60
    0x2c8be8: nop 
    0x2c8bec: ldr x25, #0x37d420 ; original_literal='bundleIdentifier'
    0x2c8bf0: mov x0, x23
    0x2c8bf4: mov x1, x24
    0x2c8bf8: mov x2, x25
    0x2c8bfc: bl #0x2ecd00
    0x2c8c00: cbz w0, #0x2c8c60
    0x2c8c04: mov x0, x23
    0x2c8c08: mov x1, x25
    0x2c8c0c: bl #0x2ecd00
    0x2c8c10: mov x29, x29
    0x2c8c14: bl #0x2ecd60
    0x2c8c18: mov x24, x0
    0x2c8c1c: cbz x0, #0x2c8c58
    0x2c8c20: nop 
    0x2c8c24: ldr x1, #0x37ed18 ; original_literal='shouldBridge:'
    0x2c8c28: mov x0, x20
    0x2c8c2c: mov x2, x24
    0x2c8c30: bl #0x2ecd00
    0x2c8c34: mov x25, x0
    0x2c8c38: mov x0, x24
    0x2c8c3c: bl #0x2ecd30
    0x2c8c40: tbz w25, #0, #0x2c8c60
    0x2c8c44: cmp x19, #1
    0x2c8c48: cset w19, eq
    0x2c8c4c: mov x0, x23
    0x2c8c50: bl #0x2ecd30
    0x2c8c54: b #0x2c8c84
    0x2c8c58: mov x0, x24
    0x2c8c5c: bl #0x2ecd30
    0x2c8c60: mov x0, x23
    0x2c8c64: bl #0x2ecd30
    0x2c8c68: nop 
    0x2c8c6c: ldr x8, #0x382148
    0x2c8c70: mov x0, x22
    0x2c8c74: mov x1, x21
    0x2c8c78: mov x2, x19
    0x2c8c7c: blr x8
    0x2c8c80: mov x19, x0
    0x2c8c84: mov x0, x20
    0x2c8c88: bl #0x2ecd30
    0x2c8c8c: mov x0, x19
    0x2c8c90: ldp x29, x30, [sp, #0x40]
    0x2c8c94: ldp x20, x19, [sp, #0x30]
    0x2c8c98: ldp x22, x21, [sp, #0x20]
    0x2c8c9c: ldp x24, x23, [sp, #0x10]
    0x2c8ca0: ldp x26, x25, [sp], #0x50
    0x2c8ca4: ret 

## manual_scene_observer 0x2c8ca8..0x2c8ef8
- ARM64 instructions: 148
- Decoded literals: ['CBCarBridgeHosted', 'CBDuoFaceHosted', 'automatesLifecycle', 'performSelector:', 'respondsToSelector:', 'sceneHandle']
- Call count: 37; branch count: 16

    0x2c8ca8: sub sp, sp, #0x60
    0x2c8cac: stp x26, x25, [sp, #0x10]
    0x2c8cb0: stp x24, x23, [sp, #0x20]
    0x2c8cb4: stp x22, x21, [sp, #0x30]
    0x2c8cb8: stp x20, x19, [sp, #0x40]
    0x2c8cbc: stp x29, x30, [sp, #0x50]
    0x2c8cc0: add x29, sp, #0x50
    0x2c8cc4: mov x21, x4
    0x2c8cc8: mov x20, x3
    0x2c8ccc: mov x22, x1
    0x2c8cd0: mov x23, x0
    0x2c8cd4: mov x0, x2
    0x2c8cd8: bl #0x2ecd3c
    0x2c8cdc: mov x19, x0
    0x2c8ce0: mov x0, x20
    0x2c8ce4: bl #0x2ecd3c
    0x2c8ce8: mov x20, x0
    0x2c8cec: mov x0, x21
    0x2c8cf0: bl #0x2ecd3c
    0x2c8cf4: mov x21, x0
    0x2c8cf8: adr x1, #0x308e8b ; original_literal='CBDuoFaceHosted'
    0x2c8cfc: nop 
    0x2c8d00: mov x0, x23
    0x2c8d04: bl #0x2eccc4
    0x2c8d08: mov x29, x29
    0x2c8d0c: bl #0x2ecd60
    0x2c8d10: cbz x0, #0x2c8d1c
    0x2c8d14: bl #0x2ecd30
    0x2c8d18: b #0x2c8d40
    0x2c8d1c: adr x1, #0x308e9b ; original_literal='CBCarBridgeHosted'
    0x2c8d20: nop 
    0x2c8d24: mov x0, x23
    0x2c8d28: bl #0x2eccc4
    0x2c8d2c: mov x29, x29
    0x2c8d30: bl #0x2ecd60
    0x2c8d34: mov x24, x0
    0x2c8d38: bl #0x2ecd30
    0x2c8d3c: cbz x24, #0x2c8d70
    0x2c8d40: mov x0, x21
    0x2c8d44: bl #0x2ecd30
    0x2c8d48: mov x0, x20
    0x2c8d4c: bl #0x2ecd30
    0x2c8d50: mov x0, x19
    0x2c8d54: ldp x29, x30, [sp, #0x50]
    0x2c8d58: ldp x20, x19, [sp, #0x40]
    0x2c8d5c: ldp x22, x21, [sp, #0x30]
    0x2c8d60: ldp x24, x23, [sp, #0x20]
    0x2c8d64: ldp x26, x25, [sp, #0x10]
    0x2c8d68: add sp, sp, #0x60
    0x2c8d6c: b #0x2ecd30
    0x2c8d70: cbz x19, #0x2c8db4
    0x2c8d74: adr x1, #0x308e8b ; original_literal='CBDuoFaceHosted'
    0x2c8d78: nop 
    0x2c8d7c: mov x0, x19
    0x2c8d80: bl #0x2eccc4
    0x2c8d84: mov x29, x29
    0x2c8d88: bl #0x2ecd60
    0x2c8d8c: cbnz x0, #0x2c8d14
    0x2c8d90: adr x1, #0x308e9b ; original_literal='CBCarBridgeHosted'
    0x2c8d94: nop 
    0x2c8d98: mov x0, x19
    0x2c8d9c: bl #0x2eccc4
    0x2c8da0: mov x29, x29
    0x2c8da4: bl #0x2ecd60
    0x2c8da8: mov x24, x0
    0x2c8dac: bl #0x2ecd30
    0x2c8db0: cbnz x24, #0x2c8d40
    0x2c8db4: nop 
    0x2c8db8: ldr x25, #0x37e328 ; original_literal='sceneHandle'
    0x2c8dbc: nop 
    0x2c8dc0: ldr x24, #0x37d5d8 ; original_literal='respondsToSelector:'
    0x2c8dc4: mov x0, x23
    0x2c8dc8: mov x1, x24
    0x2c8dcc: mov x2, x25
    0x2c8dd0: bl #0x2ecd00
    0x2c8dd4: cbz w0, #0x2c8e4c
    0x2c8dd8: nop 
    0x2c8ddc: ldr x1, #0x37dfc8 ; original_literal='performSelector:'
    0x2c8de0: mov x0, x23
    0x2c8de4: mov x2, x25
    0x2c8de8: bl #0x2ecd00
    0x2c8dec: mov x29, x29
    0x2c8df0: bl #0x2ecd60
    0x2c8df4: cbz x0, #0x2c8e4c
    0x2c8df8: mov x25, x0
    0x2c8dfc: adr x1, #0x308e8b ; original_literal='CBDuoFaceHosted'
    0x2c8e00: nop 
    0x2c8e04: bl #0x2eccc4
    0x2c8e08: mov x29, x29
    0x2c8e0c: bl #0x2ecd60
    0x2c8e10: cbz x0, #0x2c8e20
    0x2c8e14: bl #0x2ecd30
    0x2c8e18: mov x0, x25
    0x2c8e1c: b #0x2c8d14
    0x2c8e20: adr x1, #0x308e9b ; original_literal='CBCarBridgeHosted'
    0x2c8e24: nop 
    0x2c8e28: mov x0, x25
    0x2c8e2c: bl #0x2eccc4
    0x2c8e30: mov x29, x29
    0x2c8e34: bl #0x2ecd60
    0x2c8e38: mov x26, x0
    0x2c8e3c: bl #0x2ecd30
    0x2c8e40: mov x0, x25
    0x2c8e44: bl #0x2ecd30
    0x2c8e48: cbnz x26, #0x2c8d40
    0x2c8e4c: nop 
    0x2c8e50: ldr x2, #0x37f380 ; original_literal='automatesLifecycle'
    0x2c8e54: mov x0, x23
    0x2c8e58: mov x1, x24
    0x2c8e5c: bl #0x2ecd00
    0x2c8e60: cbz w0, #0x2c8e80
    0x2c8e64: adr x0, #0x30dea4 ; original_literal='automatesLifecycle'
    0x2c8e68: nop 
    0x2c8e6c: bl #0x2ecdfc
    0x2c8e70: mov x1, x0
    0x2c8e74: mov x0, x23
    0x2c8e78: bl #0x2ecd00
    0x2c8e7c: cbz w0, #0x2c8d40
    0x2c8e80: nop 
    0x2c8e84: ldr x8, #0x382150
    0x2c8e88: mov x0, x23
    0x2c8e8c: mov x1, x22
    0x2c8e90: mov x2, x19
    0x2c8e94: mov x3, x20
    0x2c8e98: mov x4, x21
    0x2c8e9c: blr x8
    0x2c8ea0: b #0x2c8d40
    0x2c8ea4: mov x22, x0
    0x2c8ea8: cmp w1, #1
    0x2c8eac: b.ne #0x2c8eec
    0x2c8eb0: mov x0, x22
    0x2c8eb4: bl #0x2ecc88
    0x2c8eb8: mov x29, x29
    0x2c8ebc: bl #0x2ecd60
    0x2c8ec0: mov x22, x0
    0x2c8ec4: str x0, [sp]
    0x2c8ec8: adr x0, #0x373608
    0x2c8ecc: nop 
    0x2c8ed0: bl #0x2ec9ac
    0x2c8ed4: mov x0, x22
    0x2c8ed8: bl #0x2ecd30
    0x2c8edc: bl #0x2eccac
    0x2c8ee0: b #0x2c8d40
    0x2c8ee4: mov x22, x0
    0x2c8ee8: bl #0x2eccac
    0x2c8eec: mov x0, x22
    0x2c8ef0: bl #0x2eca84
    0x2c8ef4: brk #1

## manual_scene_destroy 0x2c8ef8..0x2c9060
- ARM64 instructions: 90
- Decoded literals: ['bundleIdentifier', 'isEqualToString:', 'isUIAppBridging', 'sharedInstanceIfExists', 'terminate']
- Call count: 21; branch count: 8

    0x2c8ef8: stp x28, x27, [sp, #-0x60]!
    0x2c8efc: stp x26, x25, [sp, #0x10]
    0x2c8f00: stp x24, x23, [sp, #0x20]
    0x2c8f04: stp x22, x21, [sp, #0x30]
    0x2c8f08: stp x20, x19, [sp, #0x40]
    0x2c8f0c: stp x29, x30, [sp, #0x50]
    0x2c8f10: add x29, sp, #0x50
    0x2c8f14: mov x20, x3
    0x2c8f18: mov x21, x1
    0x2c8f1c: mov x22, x0
    0x2c8f20: mov x0, x2
    0x2c8f24: bl #0x2ecd3c
    0x2c8f28: mov x19, x0
    0x2c8f2c: mov x0, x20
    0x2c8f30: bl #0x2ecd3c
    0x2c8f34: mov x20, x0
    0x2c8f38: nop 
    0x2c8f3c: ldr x0, #0x37f8d8
    0x2c8f40: nop 
    0x2c8f44: ldr x1, #0x37e398 ; original_literal='sharedInstanceIfExists'
    0x2c8f48: bl #0x2ecd00
    0x2c8f4c: mov x29, x29
    0x2c8f50: bl #0x2ecd60
    0x2c8f54: mov x23, x0
    0x2c8f58: cbz x0, #0x2c9068
    0x2c8f5c: nop 
    0x2c8f60: ldr x1, #0x37e218 ; original_literal='isUIAppBridging'
    0x2c8f64: mov x0, x23
    0x2c8f68: bl #0x2ecd00
    0x2c8f6c: cbz x20, #0x2c9068
    0x2c8f70: cbz w0, #0x2c9068
    0x2c8f74: mov x0, x20
    0x2c8f78: bl #0x2c6958
    0x2c8f7c: mov x29, x29
    0x2c8f80: bl #0x2ecd60
    0x2c8f84: mov x24, x0
    0x2c8f88: cbz x0, #0x2c9060
    0x2c8f8c: nop 
    0x2c8f90: ldr x26, #0x37d420 ; original_literal='bundleIdentifier'
    0x2c8f94: mov x0, x23
    0x2c8f98: mov x1, x26
    0x2c8f9c: bl #0x2ecd00
    0x2c8fa0: mov x29, x29
    0x2c8fa4: bl #0x2ecd60
    0x2c8fa8: mov x25, x0
    0x2c8fac: nop 
    0x2c8fb0: ldr x8, #0x382168
    0x2c8fb4: cmn x8, #1
    0x2c8fb8: b.ne #0x2c90b4
    0x2c8fbc: nop 
    0x2c8fc0: ldr x0, #0x382160
    0x2c8fc4: bl #0x2ecd3c
    0x2c8fc8: mov x27, x0
    0x2c8fcc: nop 
    0x2c8fd0: ldr x28, #0x37d448 ; original_literal='isEqualToString:'
    0x2c8fd4: mov x0, x25
    0x2c8fd8: mov x1, x28
    0x2c8fdc: mov x2, x27
    0x2c8fe0: bl #0x2ecd00
    0x2c8fe4: cbz w0, #0x2c8ffc
    0x2c8fe8: mov x0, x27
    0x2c8fec: bl #0x2ecd30
    0x2c8ff0: mov x0, x25
    0x2c8ff4: bl #0x2ecd30
    0x2c8ff8: b #0x2c9060
    0x2c8ffc: mov x0, x23
    0x2c9000: mov x1, x26
    0x2c9004: bl #0x2ecd00
    0x2c9008: mov x29, x29
    0x2c900c: bl #0x2ecd60
    0x2c9010: mov x26, x0
    0x2c9014: mov x0, x24
    0x2c9018: mov x1, x28
    0x2c901c: mov x2, x26
    0x2c9020: bl #0x2ecd00
    0x2c9024: mov x28, x0
    0x2c9028: mov x0, x26
    0x2c902c: bl #0x2ecd30
    0x2c9030: mov x0, x27
    0x2c9034: bl #0x2ecd30
    0x2c9038: mov x0, x25
    0x2c903c: bl #0x2ecd30
    0x2c9040: cbz w28, #0x2c9060
    0x2c9044: nop 
    0x2c9048: ldr x1, #0x37f388 ; original_literal='terminate'
    0x2c904c: mov x0, x23
    0x2c9050: bl #0x2ecd00
    0x2c9054: mov x0, x24
    0x2c9058: bl #0x2ecd30
    0x2c905c: b #0x2c9084

## Exact distinction from current DuoFace
- Original Native12 installed THREE under-lock callbacks: interceptUpdateForScene:withNewSettings:, _shouldBeBackgroundUnderLockForScene:withSettings:, shouldBeUnderLockForScene:.
- Current first-party `DFSceneLifecycle.m` does NOT register those three; it corrects FBScene foreground and consumes owned manual observer updates only.
- Original also hooks _UIScenePresentationView, FBScene apply-update, scene-destroy. A blanket foreground YES or skipping all callbacks would be unsafe.
- Original DuoNavi independently has a real IOPM sleep assertion pair, and its Dashboard shares many CBBridgeManager/CBBridgedUIAppView owners with Native12. These source similarities alone do not establish runtime lock behavior.
- To match the user's Dock-still-visible black panes without harming CarPlay Home, gate an independent per-scene owner and generation, distinguish phone lock vs native CarPlay Home and preserve teardown on Home.
- Any proposed patch must be built/tested and device-tested; this report makes no fix claim.
