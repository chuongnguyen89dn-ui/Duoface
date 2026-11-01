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
