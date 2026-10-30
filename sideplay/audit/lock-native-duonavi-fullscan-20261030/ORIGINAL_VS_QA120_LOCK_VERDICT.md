# Native12 + DuoNavi original DEB full lock / screen / scene lifecycle forensic crosswalk

Original binaries SHA-pinned; all Mach-O payload files scanned for 5 relevant feature groups.
ObjC class selectors and selected ARM64 methods inventoried. No binary, proprietary code
or license is copied. Selector existence/directed calls do NOT prove runtime activation.

## Original reference identities

### DuoNavi104
- Original DEB SHA256: `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`
- Main dylib SHA256: `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`
- Mach-O binaries examined: 4
- ObjC classes decoded: 47; methods: 873;
- Relevant method names: 326; ARM64 functions extracted: 27

- `var/jb/Applications/DuoNaviUI.app/DuoNaviUI` categories: {'sleep-backlight': 1, 'under-lock': 0, 'scene-lifecycle': 0, 'display-external': 0, 'video-activity': 0}
- `var/jb/usr/libexec/cboptimize_helper` categories: {'sleep-backlight': 0, 'under-lock': 0, 'scene-lifecycle': 0, 'display-external': 0, 'video-activity': 0}
- `var/jb/usr/lib/ellekit/OldABI.dylib` categories: {'sleep-backlight': 0, 'under-lock': 0, 'scene-lifecycle': 0, 'display-external': 0, 'video-activity': 0}
- `var/jb/Library/MobileSubstrate/DynamicLibraries/DuoNaviDashboard.dylib` categories: {'sleep-backlight': 11, 'under-lock': 7, 'scene-lifecycle': 7, 'display-external': 24, 'video-activity': 29}

### Exact original lifecycle/lock methods (method existence proven)

- `CBLicenseSyncManager.-isCarPlayScreenConnected` at `0x5d99c`
- `CBLicenseSyncManager.+isCarPlayScreen:` at `0x5d378`
- `CBLicenseSyncManager.+isCarPlayScreenConnectedExcludingScreen:` at `0x5d5cc`
- `CBLicenseSyncManager.+isCarPlayScreenConnected` at `0x5d98c`
- `CBMultitaskingOverlayView.-dimBackground` at `0xab524`
- `CBMultitaskingOverlayView.-setDimBackground:` at `0xab534`
- `CBBridgedUIAppView.-setAudioOnlyBackgroundMode:` at `0xac334`
- `CBBridgedUIAppView.-audioOnlyBackgroundMode` at `0xaf604`
- `CBWindow.-getCarPlayDisplay` at `0xb16c8`
- `CBWindow.+activeCarPlayWindow` at `0xafa24`
- `CBWindow.+carPlayWindowScene` at `0xafb60`
- `CBWindow.+carPlayUIScreen` at `0xb0538`
- `CBWindow.+carPlayCADisplay` at `0xb06d4`
- `CBWindow.+carPlayScreenScale` at `0xb0c74`
- `CBWindow.+carPlayScreenBounds` at `0xb0ddc`
- `CBWindow.+carPlayContentInsets` at `0xb1370`
- `CBWindow.+carPlayUsableBounds` at `0xb15cc`
- `CBVoiceTransport.+syncCarPlayContextOnce:` at `0x138ec0`
- `CBBridgeManager.-acquireCarPlaySleepAssertion` at `0x1c05b8`
- `CBBridgeManager.-releaseCarPlaySleepAssertion` at `0x1c0650`
- `CBBridgeManager.-scheduleAutoResumeFallback` at `0x1c0858`
- `CBBridgeManager.-performAutoResume` at `0x1c08e4`
- `CBBridgeManager.-handleGenericScreenOrCarPlayNotification:` at `0x1d9e68`
- `CBBridgeManager.-handleCarPlayConnectionChanged:` at `0x1da7c0`
- `CBBridgeManager.-autoResumeBundleID` at `0x1bf408`
- `CBBridgeManager.-setAutoResumeBundleID:` at `0x1bf414`
- `CBBridgeManagerDashboard.-updateCarPlayMetrics` at `0x2c75b8`

### Selected actual ARM64 proof and direct machine-code callsites
- `acquireCarPlaySleepAssertion` IMP `0x1c05b8`: 0 direct BL callers
- `releaseCarPlaySleepAssertion` IMP `0x1c0650`: 0 direct BL callers
- `carPlayUsableBounds` IMP `0xb15cc`: 0 direct BL callers
- `refreshSceneLayout` IMP `0xadc30`: 0 direct BL callers
- `performAutoResume` IMP `0x1c08e4`: 0 direct BL callers
#### `CBBridgeManager.-acquireCarPlaySleepAssertion` @ `0x1c05b8`
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
#### `CBBridgeManager.-releaseCarPlaySleepAssertion` @ `0x1c0650`
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
#### `CBBridgedUIAppView.-audioOnlyBackgroundMode` @ `0xaf604`
    0xaf604: adrp x8, #0x3aa000
    0xaf608: ldrsw x8, [x8, #0xfc8]
    0xaf60c: ldrb w0, [x0, x8]
    0xaf610: ret 
#### `CBBridgedUIAppView.-setAudioOnlyBackgroundMode:` @ `0xac334`
    0xac334: stp x20, x19, [sp, #-0x20]!
    0xac338: stp x29, x30, [sp, #0x10]
    0xac33c: add x29, sp, #0x10
    0xac340: mov x19, x0
    0xac344: adrp x8, #0x3aa000
    0xac348: ldrsw x8, [x8, #0xfc8]
    0xac34c: strb w2, [x0, x8]
    0xac350: adrp x8, #0x3a8000
    0xac354: ldr x1, [x8, #0xa38]  ; SEL_OR_LITERAL 'setAlpha:'
    0xac358: cbz w2, #0xac384
    0xac35c: fmov d0, xzr
    0xac360: mov x0, x19
    0xac364: bl #0x313780
    0xac368: adrp x8, #0x3a8000
    0xac36c: ldr x1, [x8, #0x828]  ; SEL_OR_LITERAL 'setUserInteractionEnabled:'
    0xac370: mov x0, x19
    0xac374: mov w2, #0
    0xac378: ldp x29, x30, [sp, #0x10]
    0xac37c: ldp x20, x19, [sp], #0x20
    0xac380: b #0x313780
    0xac384: fmov d0, #1.00000000
    0xac388: mov x0, x19
    0xac38c: bl #0x313780
    0xac390: adrp x8, #0x3a8000
    0xac394: ldr x1, [x8, #0x828]  ; SEL_OR_LITERAL 'setUserInteractionEnabled:'
    0xac398: mov x0, x19
    0xac39c: mov w2, #1
    0xac3a0: bl #0x313780
    0xac3a4: adrp x8, #0x3a8000
    0xac3a8: ldr x1, [x8, #0xd88]  ; SEL_OR_LITERAL 'updateLayout'
    0xac3ac: mov x0, x19
    0xac3b0: bl #0x313780
    0xac3b4: adrp x8, #0x3a8000
    0xac3b8: ldr x1, [x8, #0xd90]  ; SEL_OR_LITERAL 'refreshSceneLayout'
    0xac3bc: mov x0, x19
    0xac3c0: ldp x29, x30, [sp, #0x10]
    0xac3c4: ldp x20, x19, [sp], #0x20
    0xac3c8: b #0x313780
#### `CBMultitaskingOverlayView.-dimBackground` @ `0xab524`
    0xab524: adrp x8, #0x3aa000
    0xab528: ldrsw x8, [x8, #0xf80]
    0xab52c: ldr x0, [x0, x8]
    0xab530: ret 
#### `CBMultitaskingOverlayView.-setDimBackground:` @ `0xab534`
    0xab534: mov x1, x2
    0xab538: adrp x8, #0x3aa000
    0xab53c: ldrsw x8, [x8, #0xf80]
    0xab540: add x0, x0, x8
    0xab544: b #0x313810

### Native12
- Original DEB SHA256: `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`
- Main dylib SHA256: `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`
- Mach-O binaries examined: 8
- ObjC classes decoded: 36; methods: 757;
- Relevant method names: 327; ARM64 functions extracted: 26

- `var/jb/Applications/DuoFaceUI.app/DuoFaceUI` categories: {'sleep-backlight': 1, 'under-lock': 0, 'scene-lifecycle': 0, 'display-external': 0, 'video-activity': 0}
- `var/jb/usr/libexec/duoface_cboptimize_helper` categories: {'sleep-backlight': 0, 'under-lock': 0, 'scene-lifecycle': 0, 'display-external': 0, 'video-activity': 0}
- `var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceSpeedOwner.dylib` categories: {'sleep-backlight': 0, 'under-lock': 0, 'scene-lifecycle': 0, 'display-external': 0, 'video-activity': 0}
- `var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceSpeedHUD.dylib` categories: {'sleep-backlight': 0, 'under-lock': 0, 'scene-lifecycle': 0, 'display-external': 0, 'video-activity': 0}
- `var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib` categories: {'sleep-backlight': 0, 'under-lock': 0, 'scene-lifecycle': 0, 'display-external': 2, 'video-activity': 0}
- `var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.dylib` categories: {'sleep-backlight': 0, 'under-lock': 0, 'scene-lifecycle': 0, 'display-external': 0, 'video-activity': 0}
- `var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib` categories: {'sleep-backlight': 11, 'under-lock': 7, 'scene-lifecycle': 7, 'display-external': 24, 'video-activity': 18}
- `var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceLogoGripOnly.dylib` categories: {'sleep-backlight': 0, 'under-lock': 0, 'scene-lifecycle': 0, 'display-external': 0, 'video-activity': 0}

### Exact original lifecycle/lock methods (method existence proven)

- `CBLicenseSyncManager.-isCarPlayScreenConnected` at `0x5fb88`
- `CBLicenseSyncManager.+isCarPlayScreen:` at `0x5f564`
- `CBLicenseSyncManager.+isCarPlayScreenConnectedExcludingScreen:` at `0x5f7b8`
- `CBLicenseSyncManager.+isCarPlayScreenConnected` at `0x5fb78`
- `CBMultitaskingOverlayView.-dimBackground` at `0xab8f8`
- `CBMultitaskingOverlayView.-setDimBackground:` at `0xab908`
- `CBBridgedUIAppView.-setAudioOnlyBackgroundMode:` at `0xac858`
- `CBBridgedUIAppView.-audioOnlyBackgroundMode` at `0xaf2d8`
- `CBWindow.-getCarPlayDisplay` at `0xb0ff0`
- `CBWindow.+activeCarPlayWindow` at `0xaf554`
- `CBWindow.+carPlayWindowScene` at `0xaf690`
- `CBWindow.+carPlayUIScreen` at `0xafe60`
- `CBWindow.+carPlayCADisplay` at `0xafffc`
- `CBWindow.+carPlayScreenScale` at `0xb059c`
- `CBWindow.+carPlayScreenBounds` at `0xb0704`
- `CBWindow.+carPlayContentInsets` at `0xb0c98`
- `CBWindow.+carPlayUsableBounds` at `0xb0ef4`
- `CBBridgeManager.-acquireCarPlaySleepAssertion` at `0x19eaf8`
- `CBBridgeManager.-releaseCarPlaySleepAssertion` at `0x19eb90`
- `CBBridgeManager.-scheduleAutoResumeFallback` at `0x19ed98`
- `CBBridgeManager.-performAutoResume` at `0x19ee24`
- `CBBridgeManager.-handleGenericScreenOrCarPlayNotification:` at `0x1b816c`
- `CBBridgeManager.-handleCarPlayConnectionChanged:` at `0x1b8a1c`
- `CBBridgeManager.-autoResumeBundleID` at `0x19db7c`
- `CBBridgeManager.-setAutoResumeBundleID:` at `0x19db88`
- `CBBridgeManagerDashboard.-updateCarPlayMetrics` at `0x2a4c24`

### Selected actual ARM64 proof and direct machine-code callsites
- `acquireCarPlaySleepAssertion` IMP `0x19eaf8`: 0 direct BL callers
- `releaseCarPlaySleepAssertion` IMP `0x19eb90`: 0 direct BL callers
- `carPlayUsableBounds` IMP `0xb0ef4`: 0 direct BL callers
- `refreshSceneLayout` IMP `0xade58`: 0 direct BL callers
- `performAutoResume` IMP `0x19ee24`: 0 direct BL callers
#### `CBBridgeManager.-acquireCarPlaySleepAssertion` @ `0x19eaf8`
    0x19eaf8: sub sp, sp, #0x30
    0x19eafc: stp x20, x19, [sp, #0x10]
    0x19eb00: stp x29, x30, [sp, #0x20]
    0x19eb04: add x29, sp, #0x20
    0x19eb08: adrp x8, #0x381000
    0x19eb0c: ldr w8, [x8, #0x728]
    0x19eb10: cbnz w8, #0x19eb80
    0x19eb14: adrp x0, #0x30a000
    0x19eb18: add x0, x0, #0xcb  ; DIRECT_STRING '/System/Library/Frameworks/IOKit.framework/IOKit'
    0x19eb1c: mov w1, #1
    0x19eb20: bl #0x2ecb5c
    0x19eb24: cbnz x0, #0x19eb34
    0x19eb28: mov w1, #1
    0x19eb2c: bl #0x2ecb5c
    0x19eb30: cbz x0, #0x19eb80
    0x19eb34: adrp x1, #0x30a000
    0x19eb38: add x1, x1, #0xfc  ; DIRECT_STRING 'IOPMAssertionCreateWithName'
    0x19eb3c: bl #0x2ecb68
    0x19eb40: cbz x0, #0x19eb80
    0x19eb44: mov x8, x0
    0x19eb48: adrp x0, #0x371000
    0x19eb4c: add x0, x0, #0x708
    0x19eb50: adrp x2, #0x371000
    0x19eb54: add x2, x2, #0x6e8
    0x19eb58: adrp x19, #0x381000
    0x19eb5c: add x19, x19, #0x728
    0x19eb60: mov w1, #0xff
    0x19eb64: mov x3, x19
    0x19eb68: blr x8
    0x19eb6c: ldr w8, [x19]
    0x19eb70: stp x0, x8, [sp]
    0x19eb74: adrp x0, #0x371000
    0x19eb78: add x0, x0, #0x728
    0x19eb7c: bl #0x2ec9ac
    0x19eb80: ldp x29, x30, [sp, #0x20]
    0x19eb84: ldp x20, x19, [sp, #0x10]
    0x19eb88: add sp, sp, #0x30
    0x19eb8c: ret 
#### `CBBridgeManager.-releaseCarPlaySleepAssertion` @ `0x19eb90`
    0x19eb90: sub sp, sp, #0x30
    0x19eb94: stp x20, x19, [sp, #0x10]
    0x19eb98: stp x29, x30, [sp, #0x20]
    0x19eb9c: add x29, sp, #0x20
    0x19eba0: adrp x19, #0x381000
    0x19eba4: ldr w8, [x19, #0x728]
    0x19eba8: cbz w8, #0x19ec00
    0x19ebac: adrp x0, #0x30a000
    0x19ebb0: add x0, x0, #0xcb  ; DIRECT_STRING '/System/Library/Frameworks/IOKit.framework/IOKit'
    0x19ebb4: mov w1, #1
    0x19ebb8: bl #0x2ecb5c
    0x19ebbc: cbnz x0, #0x19ebcc
    0x19ebc0: mov w1, #1
    0x19ebc4: bl #0x2ecb5c
    0x19ebc8: cbz x0, #0x19ebfc
    0x19ebcc: adrp x1, #0x30a000
    0x19ebd0: add x1, x1, #0x19d  ; DIRECT_STRING 'IOPMAssertionRelease'
    0x19ebd4: bl #0x2ecb68
    0x19ebd8: cbz x0, #0x19ebfc
    0x19ebdc: mov x8, x0
    0x19ebe0: ldr w0, [x19, #0x728]
    0x19ebe4: blr x8
    0x19ebe8: ldr w8, [x19, #0x728]
    0x19ebec: str x8, [sp]
    0x19ebf0: adrp x0, #0x371000
    0x19ebf4: add x0, x0, #0x748
    0x19ebf8: bl #0x2ec9ac
    0x19ebfc: str wzr, [x19, #0x728]
    0x19ec00: ldp x29, x30, [sp, #0x20]
    0x19ec04: ldp x20, x19, [sp, #0x10]
    0x19ec08: add sp, sp, #0x30
    0x19ec0c: ret 
#### `CBBridgedUIAppView.-audioOnlyBackgroundMode` @ `0xaf2d8`
    0xaf2d8: adrp x8, #0x37f000
    0xaf2dc: ldrsw x8, [x8, #0xce4]
    0xaf2e0: ldrb w0, [x0, x8]
    0xaf2e4: ret 
#### `CBBridgedUIAppView.-setAudioOnlyBackgroundMode:` @ `0xac858`
    0xac858: stp x20, x19, [sp, #-0x20]!
    0xac85c: stp x29, x30, [sp, #0x10]
    0xac860: add x29, sp, #0x10
    0xac864: mov x19, x0
    0xac868: adrp x8, #0x37f000
    0xac86c: ldrsw x8, [x8, #0xce4]
    0xac870: strb w2, [x0, x8]
    0xac874: adrp x8, #0x37d000
    0xac878: ldr x1, [x8, #0x988]  ; SEL_OR_LITERAL 'setAlpha:'
    0xac87c: cbz w2, #0xac8a8
    0xac880: fmov d0, xzr
    0xac884: mov x0, x19
    0xac888: bl #0x2ecd00
    0xac88c: adrp x8, #0x37d000
    0xac890: ldr x1, [x8, #0x9e0]  ; SEL_OR_LITERAL 'setUserInteractionEnabled:'
    0xac894: mov x0, x19
    0xac898: mov w2, #0
    0xac89c: ldp x29, x30, [sp, #0x10]
    0xac8a0: ldp x20, x19, [sp], #0x20
    0xac8a4: b #0x2ecd00
    0xac8a8: fmov d0, #1.00000000
    0xac8ac: mov x0, x19
    0xac8b0: bl #0x2ecd00
    0xac8b4: adrp x8, #0x37d000
    0xac8b8: ldr x1, [x8, #0x9e0]  ; SEL_OR_LITERAL 'setUserInteractionEnabled:'
    0xac8bc: mov x0, x19
    0xac8c0: mov w2, #1
    0xac8c4: bl #0x2ecd00
    0xac8c8: adrp x8, #0x37e000
    0xac8cc: ldr x1, [x8, #0x2b8]  ; SEL_OR_LITERAL 'updateLayout'
    0xac8d0: mov x0, x19
    0xac8d4: bl #0x2ecd00
    0xac8d8: adrp x8, #0x37e000
    0xac8dc: ldr x1, [x8, #0x2c0]  ; SEL_OR_LITERAL 'refreshSceneLayout'
    0xac8e0: mov x0, x19
    0xac8e4: ldp x29, x30, [sp, #0x10]
    0xac8e8: ldp x20, x19, [sp], #0x20
    0xac8ec: b #0x2ecd00
#### `CBMultitaskingOverlayView.-dimBackground` @ `0xab8f8`
    0xab8f8: adrp x8, #0x37f000
    0xab8fc: ldrsw x8, [x8, #0xc9c]
    0xab900: ldr x0, [x0, x8]
    0xab904: ret 
#### `CBMultitaskingOverlayView.-setDimBackground:` @ `0xab908`
    0xab908: mov x1, x2
    0xab90c: adrp x8, #0x37f000
    0xab910: ldrsw x8, [x8, #0xc9c]
    0xab914: add x0, x0, x8
    0xab918: b #0x2ecd90

## Current first-party source gap (verified source lines)
### `DFNativeHostAppDelegate.m` (sha256 `1b8f0494bad8c6e9f66cb98b4d51fe389c2722a18d01746d61b27640992c1459`)
- `sceneWillResignActive:`: L142 `- (void)sceneWillResignActive:(UIScene *)scene {`; L248 `- (void)sceneWillResignActive:(UIScene *)scene {`
- `sceneDidEnterBackground:`: L252 `- (void)sceneDidEnterBackground:(UIScene *)scene {`
- `renewTouchOwnerHeartbeat`: L53 `- (void)renewTouchOwnerHeartbeat:(NSTimer *)timer;`; L186 `- (void)renewTouchOwnerHeartbeat:(NSTimer *)timer {`; L238 `selector:@selector(renewTouchOwnerHeartbeat:) userInfo:nil repeats:YES];`; L242 `[self renewTouchOwnerHeartbeat:timer];`
- `stopTouchOwnerWithReason`: L52 `- (void)stopTouchOwnerWithReason:(NSString *)reason;`; L159 `- (void)stopTouchOwnerWithReason:(NSString *)reason {`; L190 `[self stopTouchOwnerWithReason:@"not-active-or-home"];`; L210 `[self stopTouchOwnerWithReason:@"heartbeat-write-failed"];`; L250 `[self stopTouchOwnerWithReason:@"scene-resigned-carplay-home"];`; L254 `[self stopTouchOwnerWithReason:@"scene-background"];`; L258 `[self stopTouchOwnerWithReason:@"scene-disconnected"];`; L407 `[self stopTouchOwnerWithReason:@"template-disconnected"];`
### `DFTouchOwnerProbe.m` (sha256 `3b00cb5b0b649e52b6806ba66df5ee6d612c67bd10a8881698f08f5ebea07076`)
- `DFStopProbe`: L364 `static void DFStopProbe(NSString *reason) {`; L420 `DFStopProbe(@"inactive-or-stale-heartbeat");`; L491 `DFStopProbe(@"preflight-failed");return;`; L501 `DFStopProbe(@"external-display-unavailable");return;`; L559 `DFStopProbe(@"content-invalid");return;`; L569 `DFStopProbe(@"session-revoked-before-window-start");return;`; L581 `DFStopProbe(@"chrome-window-create-failed");return;`; L585 `DFStopProbe(@"session-revoked-during-window-start");return;`
- `hideAllExternalWindowsImmediately`: L374 `[sChrome hideAllExternalWindowsImmediately];`
- `DFWatchdog`: L408 `static void DFWatchdog(NSUInteger generation) {`; L473 `dispatch_get_main_queue(),^{DFWatchdog(generation);});`; L606 `DFWatchdog(generation);`
- `DFCarPlayPreventIdleSystemSleep121`: L327 `static void DFCarPlayPreventIdleSystemSleep121(void) {`; L597 `DFCarPlayPreventIdleSystemSleep121();`
### `DFSceneLifecycle.m` (sha256 `e5bb53c89b5a46e9e1bec31bec87acd5ec977394c349544449f308362647ce32`)
- `incoming-background-owned-live`: L64 `@"incoming-background-owned-live scene=%p corrected-copy=1 caller=%@",`
- `setForeground:`: L53 `SEL fg=NSSelectorFromString(@"setForeground:");`
- `owned-manual-observer-consumed`: L114 `@"owned-manual-observer-consumed controller=%p handle=%p scene=%p",`
### `DFSceneHost.m` (sha256 `19a88ae81f97edcae031d308cd4e0d09317ad4bf3a5e7cbf4b1d91ba4e3adffa`)
- `scene-foreground-observed-only`: L667 `DFSceneLog(@"scene-foreground-observed-only",self.bundleID,`
- `setIgnoresOcclusions`: L320 `DFHostBool(self.appController, @"setIgnoresOcclusions:", YES);`
- `setAutomatesLifecycle`: L321 `DFHostBool(self.appController, @"setAutomatesLifecycle:", NO);`
### `DFNative12Chrome.m` (sha256 `aa651d13b08e2de2ddfbc67454fcc1f8bd7660196b4a4909f98c8b97a471f3e6`)
- `qa120-pane-tap`: L152 `@"qa120-pane-tap point=%@ fractionY=%.3f window=%@ root=%@ owner=%@",`
- `userInteractionEnabled`: L452 `surface.userInteractionEnabled=NO;`; L748 `secondLine.userInteractionEnabled=NO;`; L774 `nativeMaterial.userInteractionEnabled=NO;`; L780 `brandImage.userInteractionEnabled=NO;`; L868 `styleMaterial.userInteractionEnabled=NO;`; L882 `styleLogo.userInteractionEnabled=NO;`; L983 `thumb.userInteractionEnabled=NO;`; L996 `badge.userInteractionEnabled=NO;`

## Causal classification (do not overclaim)
- User device says Apple CarPlay native Dock remains visible while DuoFace panes go black. External display itself is still rendered. Last observed screenshot-size issue was fixed on QA120.
- DuoFace current template delegate indiscriminately stops owned window chrome during scene resign/background; immediate stop hides **only DuoFace-owned windows** and watchdog detaches after heartbeat expires.
- Source and prior QA119 device log establish a real hide/restart chain, but there is NO timestamped physical iPhone lock-button event tied to that chain. Distinguish CarPlay Home from iPhone lock before preserving lease.
- YouTube can scroll/other menu clicks with phone dark but Play depends on phone screen lit. This may involve its own app/AV media foreground underlock state, not merely pane visibility or actual screen brightness.
- Original proofs are exact machine-code methods + selector/group presence, NOT evidence that any original app is guaranteed never to blank under lock.
- Do not copy vendor hooks, fake foreground for nonowned scenes, bypass lock, or keep system Dock covered.

## Acceptance and continuation
- Before any patch: validate per-app host owner, lock state vs CarPlay Home, scene presence, active external screen and callback sequence together.
- Patch only verified first-party owner/generation; preserve immediate teardown on CarPlay Home/disconnect and legitimate scene background, and no user data.
- Run signed iOS build + source regressions before publishing, then on-device QA locked/unlocked Play and full Dock/geometry. No build/DEB/Sileo done by this read-only audit.
