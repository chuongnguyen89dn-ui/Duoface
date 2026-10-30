# DuoNavi / OmniCar original sleep assertion, blanking and lock policy — ARM64

SHA verified original binaries, bounded ARM64 method inspection. Selector presence is NOT proof of invocation.

## DuoNavi
- SHA256: 44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15
- Matches: 2
- Class metadata: decoded

### CBBridgeManager.-acquireCarPlaySleepAssertion @ 0x1c05b8
ARM64 instructions: 38
    0x1c05b8: sub sp, sp, #0x30
    0x1c05bc: stp x20, x19, [sp, #0x10]
    0x1c05c0: stp x29, x30, [sp, #0x20]
    0x1c05c4: add x29, sp, #0x20
    0x1c05c8: adrp x8, #0x3ad000
    0x1c05cc: ldr w8, [x8, #0x560]
    0x1c05d0: cbnz w8, #0x1c0640
    0x1c05d4: adrp x0, #0x336000
    0x1c05d8: add x0, x0, #0x8d7  ; DIRECT_STRING '/System/Library/Frameworks/IOKit.framework/IOKit'
    0x1c05dc: mov w1, #1
    0x1c05e0: bl #0x3135d0
    0x1c05e4: cbnz x0, #0x1c05f4
    0x1c05e8: mov w1, #1
    0x1c05ec: bl #0x3135d0
    0x1c05f0: cbz x0, #0x1c0640
    0x1c05f4: adrp x1, #0x336000
    0x1c05f8: add x1, x1, #0x908  ; DIRECT_STRING 'IOPMAssertionCreateWithName'
    0x1c05fc: bl #0x3135dc
    0x1c0600: cbz x0, #0x1c0640
    0x1c0604: mov x8, x0
    0x1c0608: adrp x0, #0x39c000
    0x1c060c: add x0, x0, #0x600
    0x1c0610: adrp x2, #0x39c000
    0x1c0614: add x2, x2, #0x5e0
    0x1c0618: adrp x19, #0x3ad000
    0x1c061c: add x19, x19, #0x560
    0x1c0620: mov w1, #0xff
    0x1c0624: mov x3, x19
    0x1c0628: blr x8
    0x1c062c: ldr w8, [x19]
    0x1c0630: stp x0, x8, [sp]
    0x1c0634: adrp x0, #0x39c000
    0x1c0638: add x0, x0, #0x620
    0x1c063c: bl #0x3133c0
    0x1c0640: ldp x29, x30, [sp, #0x20]
    0x1c0644: ldp x20, x19, [sp, #0x10]
    0x1c0648: add sp, sp, #0x30
    0x1c064c: ret 

### CBBridgeManager.-releaseCarPlaySleepAssertion @ 0x1c0650
ARM64 instructions: 32
    0x1c0650: sub sp, sp, #0x30
    0x1c0654: stp x20, x19, [sp, #0x10]
    0x1c0658: stp x29, x30, [sp, #0x20]
    0x1c065c: add x29, sp, #0x20
    0x1c0660: adrp x19, #0x3ad000
    0x1c0664: ldr w8, [x19, #0x560]
    0x1c0668: cbz w8, #0x1c06c0
    0x1c066c: adrp x0, #0x336000
    0x1c0670: add x0, x0, #0x8d7  ; DIRECT_STRING '/System/Library/Frameworks/IOKit.framework/IOKit'
    0x1c0674: mov w1, #1
    0x1c0678: bl #0x3135d0
    0x1c067c: cbnz x0, #0x1c068c
    0x1c0680: mov w1, #1
    0x1c0684: bl #0x3135d0
    0x1c0688: cbz x0, #0x1c06bc
    0x1c068c: adrp x1, #0x336000
    0x1c0690: add x1, x1, #0x9a9  ; DIRECT_STRING 'IOPMAssertionRelease'
    0x1c0694: bl #0x3135dc
    0x1c0698: cbz x0, #0x1c06bc
    0x1c069c: mov x8, x0
    0x1c06a0: ldr w0, [x19, #0x560]
    0x1c06a4: blr x8
    0x1c06a8: ldr w8, [x19, #0x560]
    0x1c06ac: str x8, [sp]
    0x1c06b0: adrp x0, #0x39c000
    0x1c06b4: add x0, x0, #0x640
    0x1c06b8: bl #0x3133c0
    0x1c06bc: str wzr, [x19, #0x560]
    0x1c06c0: ldp x29, x30, [sp, #0x20]
    0x1c06c4: ldp x20, x19, [sp, #0x10]
    0x1c06c8: add sp, sp, #0x30
    0x1c06cc: ret 

## OmniBridge
- SHA256: d99b8d00dc60f69db7b54fc1addaec6b8cb866b8dcdde6f1d85e06ce5b7d6e79
- Matches: 0
- Class metadata: ValueError: cannot map Mach-O address 0x1000000003e570

## OmniSplit
- SHA256: f696b518579266cf99cfd46f85cb54931d18e679c793a563ee2fcc9bf8115754
- Matches: 0
- Class metadata: ValueError: cannot map Mach-O address 0x10000000087ad0

## Limits
Methods without Objective-C class metadata and indirect C calls may not appear. Do not claim screenshot brightness or hardware Play fixed by this read-only scan.
