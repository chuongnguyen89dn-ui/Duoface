# CarPlayPro Speed 0.9.97 — confirmed static ARM64 GOFA call-site trace

This is **original binary evidence**, not GOFA device execution and not original source code.
Original dylib: `main:sideplay/audit/carplaypro-0.9.97/unpacked/rootfs/var/jb/Library/MobileSubstrate/DynamicLibraries/SpeedAlerts.dylib`.
Symbols/ARM64 disassembly: original audited `007-SpeedAlerts.dylib-arm64.*`.
No vendor license or binary is incorporated into DuoFace.

## Exact analysis counts
- ARM64 function starts: 541
- decoded instructions inspected: 60552
- disassembly instruction address span: 0x8000 .. 0x43288
- direct B/BL edges: 5520

## Proven GOFA-specific symbols and branch callers

### GOFA_speed_callback @ 0x3d468
- Parent function start: `0x3d468`
- Symbol: `None`
- Direct call branches to exact address: **0**
- Direct callers: none found
- Reverse callers up to four hops: none from direct B/BL

First instructions at exported address:
```text
0x3d468 sub sp, sp, #0x190
0x3d46c stp d9, d8, [sp, #0x120]
0x3d470 stp x28, x27, [sp, #0x130]
0x3d474 stp x26, x25, [sp, #0x140]
0x3d478 stp x24, x23, [sp, #0x150]
0x3d47c stp x22, x21, [sp, #0x160]
0x3d480 stp x20, x19, [sp, #0x170]
0x3d484 stp x29, x30, [sp, #0x180]
0x3d488 add x29, sp, #0x180
0x3d48c mov x0, x1
0x3d490 adrp x8, #0x5c000
0x3d494 ldr x8, [x8, #0x520]
0x3d498 ldr x8, [x8]
0x3d49c stur x8, [x29, #-0x70]
0x3d4a0 bl #0x43aa8
0x3d4a4 str x0, [sp, #8]
0x3d4a8 adrp x8, #0x6b000
0x3d4ac ldr x0, [x8, #0x40]
0x3d4b0 bl #0x45e40
0x3d4b4 mov x29, x29
0x3d4b8 bl #0x43acc
0x3d4bc mov x19, x0
0x3d4c0 bl #0x47e20
0x3d4c4 fmov d8, d0
0x3d4c8 mov x0, x19
0x3d4cc bl #0x43a9c
0x3d4d0 ldr x0, [sp, #8]
0x3d4d4 bl #0x3e38c
```

### GOFA_alert_callback @ 0x3cfb4
- Parent function start: `0x3cfb4`
- Symbol: `None`
- Direct call branches to exact address: **0**
- Direct callers: none found
- Reverse callers up to four hops: none from direct B/BL

First instructions at exported address:
```text
0x3cfb4 sub sp, sp, #0x60
0x3cfb8 stp d9, d8, [sp, #0x30]
0x3cfbc stp x20, x19, [sp, #0x40]
0x3cfc0 stp x29, x30, [sp, #0x50]
0x3cfc4 add x29, sp, #0x50
0x3cfc8 mov x0, x1
0x3cfcc bl #0x43aa8
0x3cfd0 mov x19, x0
0x3cfd4 adrp x8, #0x71000
0x3cfd8 add x8, x8, #0x620
0x3cfdc ldaxr w9, [x8]
0x3cfe0 add w10, w9, #1
0x3cfe4 stlxr w11, w10, [x8]
0x3cfe8 cbnz w11, #0x3cfdc
0x3cfec cmp w9, #8
0x3cff0 b.lo #0x3d008
0x3cff4 ldaxr w9, [x8]
0x3cff8 sub w9, w9, #1
0x3cffc stlxr w10, w9, [x8]
0x3d000 cbnz w10, #0x3cff4
0x3d004 b #0x3d094
0x3d008 adrp x8, #0x6b000
0x3d00c ldr x0, [x8, #0x40]
0x3d010 bl #0x45e40
0x3d014 mov x29, x29
0x3d018 bl #0x43acc
0x3d01c mov x20, x0
0x3d020 bl #0x47e20
```

### GOFA_speed_export @ 0x3e38c
- Parent function start: `0x3e38c`
- Symbol: `_SAGofaSpeedPayload`
- Direct call branches to exact address: **1**
- Direct callers: `0x3d468`
- Reverse callers up to four hops: `0x3d468`

First instructions at exported address:
```text
0x3e38c b #0x3e390
0x3e390 sub sp, sp, #0xd0
0x3e394 stp x24, x23, [sp, #0x90]
0x3e398 stp x22, x21, [sp, #0xa0]
0x3e39c stp x20, x19, [sp, #0xb0]
0x3e3a0 stp x29, x30, [sp, #0xc0]
0x3e3a4 add x29, sp, #0xc0
0x3e3a8 mov x24, #0x14
0x3e3ac movk x24, #0xd000, lsl #48
0x3e3b0 bl #0x43aa8
0x3e3b4 mov x19, x0
0x3e3b8 adrp x8, #0x6b000
0x3e3bc ldr x1, [x8, #0x30]
0x3e3c0 bl #0x43a3c
0x3e3c4 mov x29, x29
0x3e3c8 bl #0x43acc
0x3e3cc mov x22, x0
0x3e3d0 bl #0x43328
0x3e3d4 mov x21, x0
0x3e3d8 mov x20, x1
0x3e3dc mov x0, x22
0x3e3e0 bl #0x43a9c
0x3e3e4 orr x9, x24, #2
0x3e3e8 adrp x8, #0x55000
0x3e3ec add x8, x8, #0x3f0
0x3e3f0 cmp x21, x9
0x3e3f4 b.ne #0x3e410
0x3e3f8 sub x9, x8, #0x20
```

### GOFA_speed_Swift_wrapper @ 0x3e390
- Parent function start: `0x3e390`
- Symbol: `_$s11SpeedAlerts04gofaA7PayloadySvSgSVF`
- Direct call branches to exact address: **1**
- Direct callers: `0x3e38c`
- Reverse callers up to four hops: `0x3e38c`, `0x3d468`

First instructions at exported address:
```text
0x3e390 sub sp, sp, #0xd0
0x3e394 stp x24, x23, [sp, #0x90]
0x3e398 stp x22, x21, [sp, #0xa0]
0x3e39c stp x20, x19, [sp, #0xb0]
0x3e3a0 stp x29, x30, [sp, #0xc0]
0x3e3a4 add x29, sp, #0xc0
0x3e3a8 mov x24, #0x14
0x3e3ac movk x24, #0xd000, lsl #48
0x3e3b0 bl #0x43aa8
0x3e3b4 mov x19, x0
0x3e3b8 adrp x8, #0x6b000
0x3e3bc ldr x1, [x8, #0x30]
0x3e3c0 bl #0x43a3c
0x3e3c4 mov x29, x29
0x3e3c8 bl #0x43acc
0x3e3cc mov x22, x0
0x3e3d0 bl #0x43328
0x3e3d4 mov x21, x0
0x3e3d8 mov x20, x1
0x3e3dc mov x0, x22
0x3e3e0 bl #0x43a9c
0x3e3e4 orr x9, x24, #2
0x3e3e8 adrp x8, #0x55000
0x3e3ec add x8, x8, #0x3f0
0x3e3f0 cmp x21, x9
0x3e3f4 b.ne #0x3e410
0x3e3f8 sub x9, x8, #0x20
0x3e3fc orr x0, x9, #0x8000000000000000
```

### GOFA_alert_export @ 0x3e93c
- Parent function start: `0x3e93c`
- Symbol: `_SAGofaAlertPayload`
- Direct call branches to exact address: **1**
- Direct callers: `0x3cfb4`
- Reverse callers up to four hops: `0x3cfb4`

First instructions at exported address:
```text
0x3e93c b #0x3e940
0x3e940 stp d11, d10, [sp, #-0x80]!
0x3e944 stp d9, d8, [sp, #0x10]
0x3e948 stp x28, x27, [sp, #0x20]
0x3e94c stp x26, x25, [sp, #0x30]
0x3e950 stp x24, x23, [sp, #0x40]
0x3e954 stp x22, x21, [sp, #0x50]
0x3e958 stp x20, x19, [sp, #0x60]
0x3e95c stp x29, x30, [sp, #0x70]
0x3e960 add x29, sp, #0x70
0x3e964 sub sp, sp, #0x270
0x3e968 mov x19, sp
0x3e96c mov x22, x0
0x3e970 mov x20, #0x6f42
0x3e974 movk x20, #0x7261, lsl #16
0x3e978 movk x20, #0x64, lsl #32
0x3e97c movk x20, #0xed00, lsl #48
0x3e980 mov x27, #0x7570
0x3e984 movk x27, #0x6873, lsl #16
0x3e988 movk x27, #0x654e, lsl #32
0x3e98c movk x27, #0x7478, lsl #48
0x3e990 mov x0, #0
0x3e994 bl #0x434a8
0x3e998 str x0, [x19, #0xb8]
0x3e99c ldur x25, [x0, #-8]
0x3e9a0 ldr x8, [x25, #0x40]
0x3e9a4 mov x9, x8
0x3e9a8 adrp x16, #0x5c000
```

### GOFA_alert_Swift_wrapper @ 0x3e940
- Parent function start: `0x3e940`
- Symbol: `_$s11SpeedAlerts16gofaAlertPayloadySvSgSVF`
- Direct call branches to exact address: **1**
- Direct callers: `0x3e93c`
- Reverse callers up to four hops: `0x3e93c`, `0x3cfb4`

First instructions at exported address:
```text
0x3e940 stp d11, d10, [sp, #-0x80]!
0x3e944 stp d9, d8, [sp, #0x10]
0x3e948 stp x28, x27, [sp, #0x20]
0x3e94c stp x26, x25, [sp, #0x30]
0x3e950 stp x24, x23, [sp, #0x40]
0x3e954 stp x22, x21, [sp, #0x50]
0x3e958 stp x20, x19, [sp, #0x60]
0x3e95c stp x29, x30, [sp, #0x70]
0x3e960 add x29, sp, #0x70
0x3e964 sub sp, sp, #0x270
0x3e968 mov x19, sp
0x3e96c mov x22, x0
0x3e970 mov x20, #0x6f42
0x3e974 movk x20, #0x7261, lsl #16
0x3e978 movk x20, #0x64, lsl #32
0x3e97c movk x20, #0xed00, lsl #48
0x3e980 mov x27, #0x7570
0x3e984 movk x27, #0x6873, lsl #16
0x3e988 movk x27, #0x654e, lsl #32
0x3e98c movk x27, #0x7478, lsl #48
0x3e990 mov x0, #0
0x3e994 bl #0x434a8
0x3e998 str x0, [x19, #0xb8]
0x3e99c ldur x25, [x0, #-8]
0x3e9a0 ldr x8, [x25, #0x40]
0x3e9a4 mov x9, x8
0x3e9a8 adrp x16, #0x5c000
0x3e9ac ldr x16, [x16, #0x4d8]
```

### Original_Swift_hook_table_wrapper_0 @ 0x405b8
- Parent function start: `0x405b8`
- Symbol: `None`
- Direct call branches to exact address: **0**
- Direct callers: none found
- Reverse callers up to four hops: none from direct B/BL

First instructions at exported address:
```text
0x405b8 sub sp, sp, #0xe0
0x405bc stp x0, x1, [sp]
0x405c0 stp x2, x3, [sp, #0x10]
0x405c4 stp x4, x5, [sp, #0x20]
0x405c8 stp x6, x7, [sp, #0x30]
0x405cc stp x8, x30, [sp, #0x40]
0x405d0 stp q0, q1, [sp, #0x50]
0x405d4 stp q2, q3, [sp, #0x70]
0x405d8 stp q4, q5, [sp, #0x90]
0x405dc stp q6, q7, [sp, #0xb0]
0x405e0 mov w0, #0
0x405e4 bl #0x8000
0x405e8 mov x16, x0
0x405ec ldp q6, q7, [sp, #0xb0]
0x405f0 ldp q4, q5, [sp, #0x90]
0x405f4 ldp q2, q3, [sp, #0x70]
0x405f8 ldp q0, q1, [sp, #0x50]
0x405fc ldp x8, x30, [sp, #0x40]
0x40600 ldp x6, x7, [sp, #0x30]
0x40604 ldp x4, x5, [sp, #0x20]
0x40608 ldp x2, x3, [sp, #0x10]
0x4060c ldp x0, x1, [sp]
0x40610 add sp, sp, #0xe0
0x40614 br x16
0x40618 sub sp, sp, #0xe0
0x4061c stp x0, x1, [sp]
0x40620 stp x2, x3, [sp, #0x10]
0x40624 stp x4, x5, [sp, #0x20]
```

### Original_Swift_hook_table_wrapper_1 @ 0x40618
- Parent function start: `0x40618`
- Symbol: `None`
- Direct call branches to exact address: **0**
- Direct callers: none found
- Reverse callers up to four hops: none from direct B/BL

First instructions at exported address:
```text
0x40618 sub sp, sp, #0xe0
0x4061c stp x0, x1, [sp]
0x40620 stp x2, x3, [sp, #0x10]
0x40624 stp x4, x5, [sp, #0x20]
0x40628 stp x6, x7, [sp, #0x30]
0x4062c stp x8, x30, [sp, #0x40]
0x40630 stp q0, q1, [sp, #0x50]
0x40634 stp q2, q3, [sp, #0x70]
0x40638 stp q4, q5, [sp, #0x90]
0x4063c stp q6, q7, [sp, #0xb0]
0x40640 mov w0, #1
0x40644 bl #0x8000
0x40648 mov x16, x0
0x4064c ldp q6, q7, [sp, #0xb0]
0x40650 ldp q4, q5, [sp, #0x90]
0x40654 ldp q2, q3, [sp, #0x70]
0x40658 ldp q0, q1, [sp, #0x50]
0x4065c ldp x8, x30, [sp, #0x40]
0x40660 ldp x6, x7, [sp, #0x30]
0x40664 ldp x4, x5, [sp, #0x20]
0x40668 ldp x2, x3, [sp, #0x10]
0x4066c ldp x0, x1, [sp]
0x40670 add sp, sp, #0xe0
0x40674 br x16
0x40678 sub sp, sp, #0xe0
0x4067c stp x0, x1, [sp]
0x40680 stp x2, x3, [sp, #0x10]
0x40684 stp x4, x5, [sp, #0x20]
```

### Original_Swift_hook_table_wrapper_2 @ 0x40678
- Parent function start: `0x40678`
- Symbol: `None`
- Direct call branches to exact address: **0**
- Direct callers: none found
- Reverse callers up to four hops: none from direct B/BL

First instructions at exported address:
```text
0x40678 sub sp, sp, #0xe0
0x4067c stp x0, x1, [sp]
0x40680 stp x2, x3, [sp, #0x10]
0x40684 stp x4, x5, [sp, #0x20]
0x40688 stp x6, x7, [sp, #0x30]
0x4068c stp x8, x30, [sp, #0x40]
0x40690 stp q0, q1, [sp, #0x50]
0x40694 stp q2, q3, [sp, #0x70]
0x40698 stp q4, q5, [sp, #0x90]
0x4069c stp q6, q7, [sp, #0xb0]
0x406a0 mov w0, #2
0x406a4 bl #0x8000
0x406a8 mov x16, x0
0x406ac ldp q6, q7, [sp, #0xb0]
0x406b0 ldp q4, q5, [sp, #0x90]
0x406b4 ldp q2, q3, [sp, #0x70]
0x406b8 ldp q0, q1, [sp, #0x50]
0x406bc ldp x8, x30, [sp, #0x40]
0x406c0 ldp x6, x7, [sp, #0x30]
0x406c4 ldp x4, x5, [sp, #0x20]
0x406c8 ldp x2, x3, [sp, #0x10]
0x406cc ldp x0, x1, [sp]
0x406d0 add sp, sp, #0xe0
0x406d4 br x16
0x406d8 sub sp, sp, #0xe0
0x406dc stp x0, x1, [sp]
0x406e0 stp x2, x3, [sp, #0x10]
0x406e4 stp x4, x5, [sp, #0x20]
```

### Original_Swift_hook_table_wrapper_3 @ 0x406d8
- Parent function start: `0x406d8`
- Symbol: `None`
- Direct call branches to exact address: **0**
- Direct callers: none found
- Reverse callers up to four hops: none from direct B/BL

First instructions at exported address:
```text
0x406d8 sub sp, sp, #0xe0
0x406dc stp x0, x1, [sp]
0x406e0 stp x2, x3, [sp, #0x10]
0x406e4 stp x4, x5, [sp, #0x20]
0x406e8 stp x6, x7, [sp, #0x30]
0x406ec stp x8, x30, [sp, #0x40]
0x406f0 stp q0, q1, [sp, #0x50]
0x406f4 stp q2, q3, [sp, #0x70]
0x406f8 stp q4, q5, [sp, #0x90]
0x406fc stp q6, q7, [sp, #0xb0]
0x40700 mov w0, #3
0x40704 bl #0x8000
0x40708 mov x16, x0
0x4070c ldp q6, q7, [sp, #0xb0]
0x40710 ldp q4, q5, [sp, #0x90]
0x40714 ldp q2, q3, [sp, #0x70]
0x40718 ldp q0, q1, [sp, #0x50]
0x4071c ldp x8, x30, [sp, #0x40]
0x40720 ldp x6, x7, [sp, #0x30]
0x40724 ldp x4, x5, [sp, #0x20]
0x40728 ldp x2, x3, [sp, #0x10]
0x4072c ldp x0, x1, [sp]
0x40730 add sp, sp, #0xe0
0x40734 br x16
0x40738 sub sp, sp, #0xe0
0x4073c stp x0, x1, [sp]
0x40740 stp x2, x3, [sp, #0x10]
0x40744 stp x4, x5, [sp, #0x20]
```

## Relevant strings are present, but their runtime meaning requires validation

The following tokens were checked in the original Mach-O's ObjC selector and C-string sections:
- `GOFA.SpeedBoardModel`: PRESENT
- `GOFA.DatapointModel`: PRESENT
- `notificationSpeedBoard`: PRESENT
- `notificationNextBoard`: PRESENT
- `notificationOtherBoard`: PRESENT
- `pushOtherBoardToCarplay`: PRESENT
- `currentAllowSpeed`: PRESENT
- `flutterDirection`: PRESENT
- `cameraUpcoming`: PRESENT
- `gofaAlertGroups`: PRESENT
- `navigationSample`: PRESENT
- `distanceRemaining`: PRESENT
- `upcomingManeuvers`: PRESENT

## What these findings do *not* prove
- Whether `notificationNextBoard` is a literal NSNotification name (could be a Swift/ObjC property).
- Which GOFA object property holds a camera, speed limit, turn or distance at runtime.
- That a direct branch means a successful GOFA event: wrappers can short-circuit or call indirectly.
- A zero direct-caller count does NOT imply an exported hook has no caller (IMP dispatch, function pointers and BLR are invisible).
- Successful parsing is NOT a CarPlay hardware test.

## Required next test
Use exact call sites/ObjC selector tables and runtime symbol type evidence to validate a GOFA-specific *read-only* adapter. Do not synthesize signs/cameras/turns, or claim the current QA166 speed HUD displays them.
