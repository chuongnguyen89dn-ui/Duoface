# CarPlayPro Speed 0.9.97 — confirmed static ARM64 GOFA call-site trace

This is **original binary evidence**, not GOFA device execution and not original source code.
Original dylib: `main:sideplay/audit/carplaypro-0.9.97/unpacked/rootfs/var/jb/Library/MobileSubstrate/DynamicLibraries/SpeedAlerts.dylib`.
Symbols/ARM64 disassembly: original audited `007-SpeedAlerts.dylib-arm64.*`.
No vendor license or binary is incorporated into DuoFace.

## Exact analysis counts
- ARM64 function starts: 541
- decoded instructions inspected: 16007
- disassembly instruction address span: 0x8000 .. 0x17a18
- direct B/BL edges: 1087

## Proven GOFA-specific symbols and branch callers

### GOFA_speed_export @ 0x3e38c
- Parent function start: `0x3e38c`
- Symbol: `_SAGofaSpeedPayload`
- Direct call branches to exact address: **0**
- Direct callers: none found
- Reverse callers up to four hops: none from direct B/BL

First instructions at exported address:
```text
```

### GOFA_speed_Swift_wrapper @ 0x3e390
- Parent function start: `0x3e390`
- Symbol: `_$s11SpeedAlerts04gofaA7PayloadySvSgSVF`
- Direct call branches to exact address: **0**
- Direct callers: none found
- Reverse callers up to four hops: none from direct B/BL

First instructions at exported address:
```text
```

### GOFA_alert_export @ 0x3e93c
- Parent function start: `0x3e93c`
- Symbol: `_SAGofaAlertPayload`
- Direct call branches to exact address: **0**
- Direct callers: none found
- Reverse callers up to four hops: none from direct B/BL

First instructions at exported address:
```text
```

### GOFA_alert_Swift_wrapper @ 0x3e940
- Parent function start: `0x3e940`
- Symbol: `_$s11SpeedAlerts16gofaAlertPayloadySvSgSVF`
- Direct call branches to exact address: **0**
- Direct callers: none found
- Reverse callers up to four hops: none from direct B/BL

First instructions at exported address:
```text
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
