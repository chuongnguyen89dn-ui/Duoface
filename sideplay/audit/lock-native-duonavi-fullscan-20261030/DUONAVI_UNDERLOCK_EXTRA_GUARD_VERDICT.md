# DuoNavi additional under-lock scene eligibility guard — exact bounded ARM64

Original DuoNavi SHA256: `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`.
Native12 under-lock owner gate has isUIAppBridging+shouldBridge:, but
DuoNavi 1.0.4 **also calls helper 0x2eeb24 and checks the return value**
before overriding Apple's under-lock decision. This is verified by
two separate direct ARM64 caller PC sites. Semantic meaning of helper
is NOT assigned from its address; inspect body below.

## Original bounded helper disassembly 0x2eeb24..0x2eec64
- Original literals: ['CBCarBridgeHosted', 'CBDuoNaviHosted', 'displayIdentity', 'isRootIdentity', 'performSelector:', 'respondsToSelector:']

Note: window may include adjacent function bytes; no forced function-end claim.

    0x2eeb24: sub sp, sp, #0x50
    0x2eeb28: stp x24, x23, [sp, #0x10]
    0x2eeb2c: stp x22, x21, [sp, #0x20]
    0x2eeb30: stp x20, x19, [sp, #0x30]
    0x2eeb34: stp x29, x30, [sp, #0x40]
    0x2eeb38: add x29, sp, #0x40
    0x2eeb3c: mov x20, x1
    0x2eeb40: bl #0x3137bc
    0x2eeb44: mov x19, x0
    0x2eeb48: mov x0, x20
    0x2eeb4c: bl #0x3137bc
    0x2eeb50: mov x20, x0
    0x2eeb54: cbz x19, #0x2eeb7c
    0x2eeb58: adr x1, #0x33264f ; original literal='CBDuoNaviHosted'
    0x2eeb5c: nop 
    0x2eeb60: mov x0, x19
    0x2eeb64: bl #0x313744
    0x2eeb68: mov x29, x29
    0x2eeb6c: bl #0x3137e0
    0x2eeb70: cbz x0, #0x2eeb84
    0x2eeb74: bl #0x3137b0
    0x2eeb78: b #0x2eeba8
    0x2eeb7c: mov w22, #0
    0x2eeb80: b #0x2eebac
    0x2eeb84: adr x1, #0x33265f ; original literal='CBCarBridgeHosted'
    0x2eeb88: nop 
    0x2eeb8c: mov x0, x19
    0x2eeb90: bl #0x313744
    0x2eeb94: mov x29, x29
    0x2eeb98: bl #0x3137e0
    0x2eeb9c: mov x21, x0
    0x2eeba0: bl #0x3137b0
    0x2eeba4: cbz x21, #0x2eebd8
    0x2eeba8: mov w22, #1
    0x2eebac: mov x0, x20
    0x2eebb0: bl #0x3137b0
    0x2eebb4: mov x0, x19
    0x2eebb8: bl #0x3137b0
    0x2eebbc: mov x0, x22
    0x2eebc0: ldp x29, x30, [sp, #0x40]
    0x2eebc4: ldp x20, x19, [sp, #0x30]
    0x2eebc8: ldp x22, x21, [sp, #0x20]
    0x2eebcc: ldp x24, x23, [sp, #0x10]
    0x2eebd0: add sp, sp, #0x50
    0x2eebd4: ret 
    0x2eebd8: mov x0, x20
    0x2eebdc: bl #0x3137bc
    0x2eebe0: cbz x0, #0x2eecec
    0x2eebe4: mov x21, x0
    0x2eebe8: nop 
    0x2eebec: ldr x22, #0x3a8358 ; original literal='respondsToSelector:'
    0x2eebf0: nop 
    0x2eebf4: ldr x23, #0x3aa5f0 ; original literal='displayIdentity'
    0x2eebf8: mov x0, x21
    0x2eebfc: mov x1, x22
    0x2eec00: mov x2, x23
    0x2eec04: bl #0x313780
    0x2eec08: cbz w0, #0x2eec6c
    0x2eec0c: nop 
    0x2eec10: ldr x1, #0x3a8a48 ; original literal='performSelector:'
    0x2eec14: mov x0, x21
    0x2eec18: mov x2, x23
    0x2eec1c: bl #0x313780
    0x2eec20: mov x29, x29
    0x2eec24: bl #0x3137e0
    0x2eec28: mov x23, x0
    0x2eec2c: cbz x0, #0x2eec64
    0x2eec30: nop 
    0x2eec34: ldr x2, #0x3aa5f8 ; original literal='isRootIdentity'
    0x2eec38: mov x0, x23
    0x2eec3c: mov x1, x22
    0x2eec40: bl #0x313780
    0x2eec44: cbz w0, #0x2eec64
    0x2eec48: adr x0, #0x33abb2 ; original literal='isRootIdentity'
    0x2eec4c: nop 
    0x2eec50: bl #0x313894
    0x2eec54: mov x1, x0
    0x2eec58: mov x0, x23
    0x2eec5c: bl #0x313780
    0x2eec60: tbz w0, #0, #0x2eed38

## Independent DuoFace implication
- Even an owned YouTube scene must meet its actual hosted scene eligibility criteria.
- Do not return false for all scenes, bypass SBMainWorkspace passcode or disable iPhone lock; nonowned scenes use Apple's original decision.
- Preserve QA120 Dock sizing, Home scene frontmost behavior, .90 orientation and .92 divider. This report is research, not a runtime build/test.
