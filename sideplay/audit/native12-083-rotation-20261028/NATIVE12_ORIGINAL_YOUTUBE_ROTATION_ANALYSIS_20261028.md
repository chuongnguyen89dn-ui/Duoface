# Native12 original HUD8 — YouTube scene orientation, ARM64 facts

Original DEB SHA256: 2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad
Original Dashboard SHA256: 9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea
Evidence run: https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40647306779 (SUCCESS).
Input original immutable Git blob: b894fb893c3da3a38ad035c7115fc981e10fcc00
Scope: original Native12 only, not SidePlay. Original DEB is read-only.

## Original app/process injection filters
- var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.plist: {"Bundles": ["com.apple.CarPlayApp", "com.apple.CarPlay", "com.apple.dashboard", "com.apple.springboard", "com.apple.SpringBoard", "com.google.ios.youtube", "com.google.ios.youtubemusic", "com.netflix.Netflix", "org.videolan.vlc-ios", "com.apple.mobilesafari", "tv.twitch", "com.zhiliaoapp.musically", "com.google.Maps", "com.waze.iphone", "com.spotify.client", "com.apple.Preferences", "com.apple.mobilenotes", "com.apple.mobilephone", "com.apple.Music", "com.google.chrome.ios", "com.apple.BarcodeScanner", "com.apple.PrintKit.Print-Center", "com.duoface.duofaceui"]}
- var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.plist: {"Bundles": ["com.apple.CarPlayApp", "com.apple.CarPlay", "com.apple.dashboard", "com.apple.springboard"], "Executables": ["CarPlay", "CarPlayApp", "Dashboard", "SpringBoard"]}
- var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceLogoGripOnly.plist: {"Bundles": ["com.apple.CarPlayApp", "com.apple.CarPlay", "com.apple.dashboard", "com.apple.springboard", "com.apple.SpringBoard", "com.duoface.duofaceui"]}
- var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.plist: {"Bundles": ["com.apple.CarPlayApp", "com.apple.CarPlay", "com.apple.dashboard", "com.apple.springboard", "com.apple.SpringBoard", "com.duoface.duofaceui"]}

## Real original ARM64 counts and callsite PCs

### DuoFaceDashboard.dylib
- SHA256: 9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea; methods: 757; ARM64 instructions: 760136
- main_scene_hook: 1 references; PC 0x2c7d9c
- interface_rotation: 20 references; PC 0xacf9c, 0xacfb0, 0xacfcc, 0xad66c, 0x2aa5b0, 0x2aa5c0, 0x2aa5d4, 0x2aad04
- orientation_write: 0 references; PC 
- app_orientation_feedback: 0 references; PC 
- ui_geometry: 1 references; PC 0x2acbb0
- ui_scene: 7 references; PC 0xaf738, 0xaf73c, 0x2a8918, 0x2a8920, 0x2a8940, 0x2aaed4, 0x2aaee0
- fullscreen: 23 references; PC 0x901c, 0xad3c, 0xca64, 0xca78, 0xd2c0, 0xd3b0, 0xe784, 0x104ac
- video: 4 references; PC 0x2a914c, 0x2a9a88, 0x2b28b4, 0x2b29d0
- scene_handle: 11 references; PC 0xad714, 0xad720, 0xadc48, 0xae8c4, 0xae8d0, 0x2c7d8c, 0x2c7dc8, 0x2c7de4
- update_settings: 8 references; PC 0xad970, 0xad980, 0xad990, 0xad9b4, 0xad9f0, 0xada28, 0xada60, 0xadacc
- scene_reference: 19 references; PC 0xacf9c, 0xacfb0, 0xacfcc, 0xacfd4, 0xacfe4, 0xad004, 0xad66c, 0xad6ac
- scene_owner: 40 references; PC 0xaa28c, 0xaa290, 0x185044, 0x185048, 0x185080, 0x185084, 0x1850d0, 0x1850d4
- notification: 24 references; PC 0x33714, 0x33908, 0x1d0834, 0x1d0844, 0x1d8dec, 0x1d8df8, 0x249b48, 0x249b54
- orientation_notification: 62 references; PC 0xacf9c, 0xacfb0, 0xacfcc, 0xacfd4, 0xacfe4, 0xad004, 0xad66c, 0xad6ac
- youtube: 2 references; PC 0x33460, 0xa214c
- CBBridgeManager.renderSizeForBundleID: IMP 0x24c920; instructions 510; BL 0x24c950=>0x2ecd3c, 0x24c968=>0x2ecd00, 0x24c97c=>0x2ecd00, 0x24c998=>0x2ecd00, 0x24c9a0=>0x2ecd60
- CBBridgeManager.sendStateToApp:shouldBridge: IMP 0x1d1624; instructions 1280; BL 0x1d166c=>0x2ecd3c, 0x1d1688=>0x2ecd00, 0x1d16a8=>0x2ecd00, 0x1d16b8=>0x2ece98, 0x1d16e4=>0x2ece80
- CBBridgeManager.shouldBridge: IMP 0x2491b0; instructions 279; BL 0x2491e8=>0x2ecd3c, 0x249200=>0x2ecd00, 0x249218=>0x2ecd00, 0x249220=>0x2ecd60, 0x249238=>0x2ecd00
- CBBridgeManager.supportsInterfaceOrientation:forBundleID: IMP 0x24d118; instructions 2; BL 
- CBBridgedUIAppView.layoutSubviews IMP 0xac8f0; instructions 20; BL 0xac91c=>0x2ecd18, 0xac92c=>0x2ecd00
- CBBridgedUIAppView.refreshSceneLayout IMP 0xade58; instructions 54; BL 0xade74=>0x2ecd00, 0xade84=>0x2ecd00, 0xadea4=>0x2ecd00, 0xadeac=>0x2ecd60, 0xadeb4=>0x2ecd30
- CBBridgedUIAppView.updateLayout IMP 0xacc6c; instructions 596; BL 0xacccc=>0x2ecd00, 0xacd00=>0x2ecd00, 0xacd50=>0x2ecd00, 0xacd74=>0x2ecd00, 0xacd84=>0x2ecd00
- CBBridgedUIAppView.updateSceneFrame IMP 0xade4c; instructions 3; BL 
- CBBridgedUIAppView.updateSceneSettingsFrame IMP 0xad5bc; instructions 548; BL 0xad5fc=>0x2ecd00, 0xad620=>0x2ecd00, 0xad638=>0x2ecd00, 0xad658=>0x2ecd00, 0xad660=>0x2ecd60

### DuoFaceFullscreenBridge.dylib
- SHA256: 0bcd172dedbbffe7ad5d549770c1c1769323e21b0127528a661bbe144c10f3fe; methods: 61; ARM64 instructions: 8750
- main_scene_hook: 0 references; PC 
- interface_rotation: 0 references; PC 
- orientation_write: 0 references; PC 
- app_orientation_feedback: 0 references; PC 
- ui_geometry: 0 references; PC 
- ui_scene: 0 references; PC 
- fullscreen: 4 references; PC 0x72b0, 0x745c, 0x76a4, 0xc4f0
- video: 0 references; PC 
- scene_handle: 0 references; PC 
- update_settings: 0 references; PC 
- scene_reference: 0 references; PC 
- scene_owner: 0 references; PC 
- notification: 0 references; PC 
- orientation_notification: 0 references; PC 
- youtube: 0 references; PC 

### DuoFaceUI
- SHA256: cb40346d8ca504cb399abe31367847b4f980a01ba93810986ce1acf1fbe9eef9; methods: 522; ARM64 instructions: 159015
- main_scene_hook: 0 references; PC 
- interface_rotation: 0 references; PC 
- orientation_write: 0 references; PC 
- app_orientation_feedback: 0 references; PC 
- ui_geometry: 0 references; PC 
- ui_scene: 0 references; PC 
- fullscreen: 23 references; PC 0x100031a00, 0x100033720, 0x100035448, 0x10003545c, 0x100035ca4, 0x100035d94, 0x100037168, 0x100038e90
- video: 0 references; PC 
- scene_handle: 0 references; PC 
- update_settings: 0 references; PC 
- scene_reference: 0 references; PC 
- scene_owner: 0 references; PC 
- notification: 0 references; PC 
- orientation_notification: 0 references; PC 
- youtube: 1 references; PC 0x10000b4a0

### DuoFaceVisualHook.dylib
- SHA256: 4ebf68b630c102dee1bbaac87dcadddd3e13f618331cacd9c47ae1a27437959d; methods: 0; ARM64 instructions: 2486
- main_scene_hook: 0 references; PC 
- interface_rotation: 0 references; PC 
- orientation_write: 0 references; PC 
- app_orientation_feedback: 0 references; PC 
- ui_geometry: 0 references; PC 
- ui_scene: 0 references; PC 
- fullscreen: 0 references; PC 
- video: 0 references; PC 
- scene_handle: 0 references; PC 
- update_settings: 0 references; PC 
- scene_reference: 0 references; PC 
- scene_owner: 0 references; PC 
- notification: 0 references; PC 
- orientation_notification: 0 references; PC 
- youtube: 0 references; PC 

## Original Dashboard orientation hook instructions

### main_scene_orientation_policy (0x2c8b4c..0x2c8ca4)

Instructions 86
~~~text
0x2c8b4c stp	x26, x25, [sp, #-0x50]!
0x2c8b50 stp	x24, x23, [sp, #0x10]
0x2c8b54 stp	x22, x21, [sp, #0x20]
0x2c8b58 stp	x20, x19, [sp, #0x30]
0x2c8b5c stp	x29, x30, [sp, #0x40]
0x2c8b60 add	x29, sp, #0x40
0x2c8b64 mov	x19, x2
0x2c8b68 mov	x21, x1
0x2c8b6c mov	x22, x0
0x2c8b70 nop
0x2c8b74 ldr	x0, #0xb6d64 ; Objc class ref: CBBridgeManager
0x2c8b78 nop
0x2c8b7c ldr	x1, #0xb581c ; Objc selector ref: sharedInstanceIfExists
0x2c8b80 bl	0x2ecd00 ; Objc message: +[CBBridgeManager sharedInstanceIfExists]
0x2c8b84 mov	x29, x29
0x2c8b88 bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
0x2c8b8c mov	x20, x0
0x2c8b90 cbz	x0, 0x2c8c68
0x2c8b94 nop
0x2c8b98 ldr	x1, #0xb5680 ; Objc selector ref: isUIAppBridging
0x2c8b9c mov	x0, x20
0x2c8ba0 bl	0x2ecd00 ; Objc message: -[x0 isUIAppBridging]
0x2c8ba4 cbz	w0, 0x2c8c68
0x2c8ba8 nop
0x2c8bac ldr	x23, #0xb674c ; Objc selector ref: application
0x2c8bb0 nop
0x2c8bb4 ldr	x24, #0xb4a24 ; Objc selector ref: respondsToSelector:
0x2c8bb8 mov	x0, x22
0x2c8bbc mov	x1, x24
0x2c8bc0 mov	x2, x23
0x2c8bc4 bl	0x2ecd00 ; Objc message: -[x0 respondsToSelector:]
0x2c8bc8 cbz	w0, 0x2c8c68
0x2c8bcc mov	x0, x22
0x2c8bd0 mov	x1, x23
0x2c8bd4 bl	0x2ecd00 ; Objc message: -[x0 respondsToSelector:]
0x2c8bd8 mov	x29, x29
0x2c8bdc bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
0x2c8be0 mov	x23, x0
0x2c8be4 cbz	x0, 0x2c8c60
0x2c8be8 nop
0x2c8bec ldr	x25, #0xb4834 ; Objc selector ref: bundleIdentifier
0x2c8bf0 mov	x0, x23
0x2c8bf4 mov	x1, x24
0x2c8bf8 mov	x2, x25
0x2c8bfc bl	0x2ecd00 ; Objc message: -[x0 bundleIdentifier]
0x2c8c00 cbz	w0, 0x2c8c60
0x2c8c04 mov	x0, x23
0x2c8c08 mov	x1, x25
0x2c8c0c bl	0x2ecd00 ; Objc message: -[x0 bundleIdentifier]
0x2c8c10 mov	x29, x29
0x2c8c14 bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
0x2c8c18 mov	x24, x0
0x2c8c1c cbz	x0, 0x2c8c58
0x2c8c20 nop
0x2c8c24 ldr	x1, #0xb60f4 ; Objc selector ref: shouldBridge:
0x2c8c28 mov	x0, x20
0x2c8c2c mov	x2, x24
0x2c8c30 bl	0x2ecd00 ; Objc message: -[x0 shouldBridge:]
0x2c8c34 mov	x25, x0
0x2c8c38 mov	x0, x24
0x2c8c3c bl	0x2ecd30 ; symbol stub for: _objc_release
0x2c8c40 tbz	w25, #0x0, 0x2c8c60
0x2c8c44 cmp	x19, #0x1
0x2c8c48 cset	w19, eq
0x2c8c4c mov	x0, x23
0x2c8c50 bl	0x2ecd30 ; symbol stub for: _objc_release
0x2c8c54 b	0x2c8c84
0x2c8c58 mov	x0, x24
0x2c8c5c bl	0x2ecd30 ; symbol stub for: _objc_release
0x2c8c60 mov	x0, x23
0x2c8c64 bl	0x2ecd30 ; symbol stub for: _objc_release
0x2c8c68 nop
0x2c8c6c ldr	x8, #0xb94dc
0x2c8c70 mov	x0, x22
0x2c8c74 mov	x1, x21
0x2c8c78 mov	x2, x19
0x2c8c7c blr	x8
0x2c8c80 mov	x19, x0
0x2c8c84 mov	x0, x20
0x2c8c88 bl	0x2ecd30 ; symbol stub for: _objc_release
0x2c8c8c mov	x0, x19
0x2c8c90 ldp	x29, x30, [sp, #0x40]
0x2c8c94 ldp	x20, x19, [sp, #0x30]
0x2c8c98 ldp	x22, x21, [sp, #0x20]
0x2c8c9c ldp	x24, x23, [sp, #0x10]
0x2c8ca0 ldp	x26, x25, [sp], #0x50
~~~

### two_arg_reference_policy (0x2c895c..0x2c8a50)

Instructions 61
~~~text
0x2c895c stp	d9, d8, [sp, #-0x50]!
0x2c8960 stp	x24, x23, [sp, #0x10]
0x2c8964 stp	x22, x21, [sp, #0x20]
0x2c8968 stp	x20, x19, [sp, #0x30]
0x2c896c stp	x29, x30, [sp, #0x40]
0x2c8970 add	x29, sp, #0x40
0x2c8974 mov	x19, x2
0x2c8978 mov.16b	v8, v1
0x2c897c mov.16b	v9, v0
0x2c8980 mov	x20, x1
0x2c8984 mov	x21, x0
0x2c8988 nop
0x2c898c ldr	x0, #0xb6f4c ; Objc class ref: CBBridgeManager
0x2c8990 nop
0x2c8994 ldr	x1, #0xb5a04 ; Objc selector ref: sharedInstanceIfExists
0x2c8998 bl	0x2ecd00 ; Objc message: +[CBBridgeManager sharedInstanceIfExists]
0x2c899c mov	x29, x29
0x2c89a0 bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
0x2c89a4 mov	x22, x0
0x2c89a8 cbz	x0, 0x2c8a14
0x2c89ac nop
0x2c89b0 ldr	x1, #0xb5868 ; Objc selector ref: isUIAppBridging
0x2c89b4 mov	x0, x22
0x2c89b8 bl	0x2ecd00 ; Objc message: -[x0 isUIAppBridging]
0x2c89bc cbz	w0, 0x2c8a14
0x2c89c0 mov	x0, x21
0x2c89c4 bl	0x2c93c4
0x2c89c8 mov	x29, x29
0x2c89cc bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
0x2c89d0 mov	x23, x0
0x2c89d4 cbz	x0, 0x2c8a0c
0x2c89d8 nop
0x2c89dc ldr	x1, #0xb633c ; Objc selector ref: shouldBridge:
0x2c89e0 mov	x0, x22
0x2c89e4 mov	x2, x23
0x2c89e8 bl	0x2ecd00 ; Objc message: -[x0 shouldBridge:]
0x2c89ec cbz	w0, 0x2c8a0c
0x2c89f0 nop
0x2c89f4 ldr	x1, #0xb62fc ; Objc selector ref: renderSizeForBundleID:
0x2c89f8 mov	x0, x22
0x2c89fc mov	x2, x23
0x2c8a00 bl	0x2ecd00 ; Objc message: -[x0 renderSizeForBundleID:]
0x2c8a04 mov.16b	v9, v0
0x2c8a08 mov.16b	v8, v1
0x2c8a0c mov	x0, x23
0x2c8a10 bl	0x2ecd30 ; symbol stub for: _objc_release
0x2c8a14 nop
0x2c8a18 ldr	x8, #0xb9720
0x2c8a1c mov	x0, x21
0x2c8a20 mov	x1, x20
0x2c8a24 mov.16b	v0, v9
0x2c8a28 mov.16b	v1, v8
0x2c8a2c mov	x2, x19
0x2c8a30 blr	x8
0x2c8a34 mov	x0, x22
0x2c8a38 ldp	x29, x30, [sp, #0x40]
0x2c8a3c ldp	x20, x19, [sp, #0x30]
0x2c8a40 ldp	x22, x21, [sp, #0x20]
0x2c8a44 ldp	x24, x23, [sp, #0x10]
0x2c8a48 ldp	d9, d8, [sp], #0x50
0x2c8a4c b	0x2ecd30 ; symbol stub for: _objc_release
~~~

### three_arg_reference_policy (0x2c8a50..0x2c8b4c)

Instructions 63
~~~text
0x2c8a50 stp	d9, d8, [sp, #-0x50]!
0x2c8a54 stp	x24, x23, [sp, #0x10]
0x2c8a58 stp	x22, x21, [sp, #0x20]
0x2c8a5c stp	x20, x19, [sp, #0x30]
0x2c8a60 stp	x29, x30, [sp, #0x40]
0x2c8a64 add	x29, sp, #0x40
0x2c8a68 mov	x19, x3
0x2c8a6c mov	x20, x2
0x2c8a70 mov.16b	v8, v1
0x2c8a74 mov.16b	v9, v0
0x2c8a78 mov	x21, x1
0x2c8a7c mov	x22, x0
0x2c8a80 nop
0x2c8a84 ldr	x0, #0xb6e54 ; Objc class ref: CBBridgeManager
0x2c8a88 nop
0x2c8a8c ldr	x1, #0xb590c ; Objc selector ref: sharedInstanceIfExists
0x2c8a90 bl	0x2ecd00 ; Objc message: +[CBBridgeManager sharedInstanceIfExists]
0x2c8a94 mov	x29, x29
0x2c8a98 bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
0x2c8a9c mov	x23, x0
0x2c8aa0 cbz	x0, 0x2c8b0c
0x2c8aa4 nop
0x2c8aa8 ldr	x1, #0xb5770 ; Objc selector ref: isUIAppBridging
0x2c8aac mov	x0, x23
0x2c8ab0 bl	0x2ecd00 ; Objc message: -[x0 isUIAppBridging]
0x2c8ab4 cbz	w0, 0x2c8b0c
0x2c8ab8 mov	x0, x22
0x2c8abc bl	0x2c93c4
0x2c8ac0 mov	x29, x29
0x2c8ac4 bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
0x2c8ac8 mov	x24, x0
0x2c8acc cbz	x0, 0x2c8b04
0x2c8ad0 nop
0x2c8ad4 ldr	x1, #0xb6244 ; Objc selector ref: shouldBridge:
0x2c8ad8 mov	x0, x23
0x2c8adc mov	x2, x24
0x2c8ae0 bl	0x2ecd00 ; Objc message: -[x0 shouldBridge:]
0x2c8ae4 cbz	w0, 0x2c8b04
0x2c8ae8 nop
0x2c8aec ldr	x1, #0xb6204 ; Objc selector ref: renderSizeForBundleID:
0x2c8af0 mov	x0, x23
0x2c8af4 mov	x2, x24
0x2c8af8 bl	0x2ecd00 ; Objc message: -[x0 renderSizeForBundleID:]
0x2c8afc mov.16b	v9, v0
0x2c8b00 mov.16b	v8, v1
0x2c8b04 mov	x0, x24
0x2c8b08 bl	0x2ecd30 ; symbol stub for: _objc_release
0x2c8b0c nop
0x2c8b10 ldr	x8, #0xb9630
0x2c8b14 mov	x0, x22
0x2c8b18 mov	x1, x21
0x2c8b1c mov.16b	v0, v9
0x2c8b20 mov.16b	v1, v8
0x2c8b24 mov	x2, x20
0x2c8b28 mov	x3, x19
0x2c8b2c blr	x8
0x2c8b30 mov	x0, x23
0x2c8b34 ldp	x29, x30, [sp, #0x40]
0x2c8b38 ldp	x20, x19, [sp, #0x30]
0x2c8b3c ldp	x22, x21, [sp, #0x20]
0x2c8b40 ldp	x24, x23, [sp, #0x10]
0x2c8b44 ldp	d9, d8, [sp], #0x50
0x2c8b48 b	0x2ecd30 ; symbol stub for: _objc_release
~~~

### host_hook_registration (0x2c7c40..0x2c7f00)

Instructions 176
~~~text
0x2c7c40 ldp	x29, x30, [sp, #0x30]
0x2c7c44 ldp	x20, x19, [sp, #0x20]
0x2c7c48 ldp	x22, x21, [sp, #0x10]
0x2c7c4c ldp	d9, d8, [sp], #0x40
0x2c7c50 b	0x2ecd30 ; symbol stub for: _objc_release
0x2c7c54 stp	x20, x19, [sp, #-0x20]!
0x2c7c58 stp	x29, x30, [sp, #0x10]
0x2c7c5c add	x29, sp, #0x10
0x2c7c60 adr	x0, #286861 ; literal pool for: "FBScene"
0x2c7c64 nop
0x2c7c68 bl	0x2eccd0 ; symbol stub for: _objc_getClass
0x2c7c6c mov	x19, x0
0x2c7c70 nop
0x2c7c74 ldr	x1, #0xb76ac ; Objc selector ref: updateSettings:withTransitionContext:completion:
0x2c7c78 adr	x2, #400
0x2c7c7c nop
0x2c7c80 adr	x3, #763016
0x2c7c84 nop
0x2c7c88 bl	0x2ec9a0 ; symbol stub for: _MSHookMessageEx
0x2c7c8c nop
0x2c7c90 ldr	x1, #0xb7698 ; Objc selector ref: _applyUpdateWithContext:completion:
0x2c7c94 adr	x2, #1916
0x2c7c98 nop
0x2c7c9c adr	x3, #762996
0x2c7ca0 nop
0x2c7ca4 mov	x0, x19
0x2c7ca8 bl	0x2ec9a0 ; symbol stub for: _MSHookMessageEx
0x2c7cac adr	x0, #286793 ; literal pool for: "_UIScenePresentationView"
0x2c7cb0 nop
0x2c7cb4 bl	0x2eccd0 ; symbol stub for: _objc_getClass
0x2c7cb8 nop
0x2c7cbc ldr	x1, #0xb7674 ; Objc selector ref: scene:didPrepareUpdateWithContext:
0x2c7cc0 adr	x2, #2320
0x2c7cc4 nop
0x2c7cc8 adr	x3, #762960
0x2c7ccc nop
0x2c7cd0 bl	0x2ec9a0 ; symbol stub for: _MSHookMessageEx
0x2c7cd4 adr	x0, #286778 ; literal pool for: "SBSuspendedUnderLockManager"
0x2c7cd8 nop
0x2c7cdc bl	0x2eccd0 ; symbol stub for: _objc_getClass
0x2c7ce0 mov	x19, x0
0x2c7ce4 nop
0x2c7ce8 ldr	x1, #0xb7650 ; Objc selector ref: interceptUpdateForScene:withNewSettings:
0x2c7cec adr	x2, #2428
0x2c7cf0 nop
0x2c7cf4 adr	x3, #762924
0x2c7cf8 nop
0x2c7cfc bl	0x2ec9a0 ; symbol stub for: _MSHookMessageEx
0x2c7d00 nop
0x2c7d04 ldr	x1, #0xb763c ; Objc selector ref: _shouldBeBackgroundUnderLockForScene:withSettings:
0x2c7d08 adr	x2, #2656
0x2c7d0c nop
0x2c7d10 adr	x3, #762904
0x2c7d14 nop
0x2c7d18 mov	x0, x19
0x2c7d1c bl	0x2ec9a0 ; symbol stub for: _MSHookMessageEx
0x2c7d20 nop
0x2c7d24 ldr	x1, #0xb7624 ; Objc selector ref: shouldBeUnderLockForScene:
0x2c7d28 adr	x2, #2888
0x2c7d2c nop
0x2c7d30 adr	x3, #762880
0x2c7d34 nop
0x2c7d38 mov	x0, x19
0x2c7d3c bl	0x2ec9a0 ; symbol stub for: _MSHookMessageEx
0x2c7d40 adr	x0, #286698 ; literal pool for: "SBDeviceApplicationSceneViewController"
0x2c7d44 nop
0x2c7d48 bl	0x2eccd0 ; symbol stub for: _objc_getClass
0x2c7d4c mov	x19, x0
0x2c7d50 nop
0x2c7d54 ldr	x1, #0xb65b4 ; Objc selector ref: setContentReferenceSize:withInterfaceOrientation:
0x2c7d58 adr	x2, #3076
0x2c7d5c nop
0x2c7d60 adr	x3, #762840
0x2c7d64 nop
0x2c7d68 bl	0x2ec9a0 ; symbol stub for: _MSHookMessageEx
0x2c7d6c nop
0x2c7d70 ldr	x1, #0xb65a0 ; Objc selector ref: setContentReferenceSize:withContentOrientation:andContainerOrientation:
0x2c7d74 adr	x2, #3292
0x2c7d78 nop
0x2c7d7c adr	x3, #762820
0x2c7d80 nop
0x2c7d84 mov	x0, x19
0x2c7d88 bl	0x2ec9a0 ; symbol stub for: _MSHookMessageEx
0x2c7d8c adr	x0, #286661 ; literal pool for: "SBDeviceApplicationSceneHandle"
0x2c7d90 nop
0x2c7d94 bl	0x2eccd0 ; symbol stub for: _objc_getClass
0x2c7d98 nop
0x2c7d9c ldr	x1, #0xb75b4 ; Objc selector ref: _mainSceneSupportsInterfaceOrientation:
0x2c7da0 adr	x2, #3500
0x2c7da4 nop
~~~

### scene_update_handler (0x2c7e08..0x2c8410)

Instructions 386
~~~text
0x2c7e08 sub	sp, sp, #0x80
0x2c7e0c stp	d9, d8, [sp, #0x10]
0x2c7e10 stp	x28, x27, [sp, #0x20]
0x2c7e14 stp	x26, x25, [sp, #0x30]
0x2c7e18 stp	x24, x23, [sp, #0x40]
0x2c7e1c stp	x22, x21, [sp, #0x50]
0x2c7e20 stp	x20, x19, [sp, #0x60]
0x2c7e24 stp	x29, x30, [sp, #0x70]
0x2c7e28 add	x29, sp, #0x70
0x2c7e2c mov	x23, x4
0x2c7e30 mov	x20, x3
0x2c7e34 mov	x21, x1
0x2c7e38 mov	x22, x0
0x2c7e3c mov	x0, x2
0x2c7e40 bl	0x2ecd3c ; symbol stub for: _objc_retain
0x2c7e44 mov	x19, x0
0x2c7e48 mov	x0, x20
0x2c7e4c bl	0x2ecd3c ; symbol stub for: _objc_retain
0x2c7e50 mov	x20, x0
0x2c7e54 mov	x0, x23
0x2c7e58 bl	0x2ecd3c ; symbol stub for: _objc_retain
0x2c7e5c mov	x23, x0
0x2c7e60 nop
0x2c7e64 ldr	x0, #0xb7a74 ; Objc class ref: CBBridgeManager
0x2c7e68 nop
0x2c7e6c ldr	x1, #0xb652c ; Objc selector ref: sharedInstanceIfExists
0x2c7e70 bl	0x2ecd00 ; Objc message: +[CBBridgeManager sharedInstanceIfExists]
0x2c7e74 mov	x29, x29
0x2c7e78 bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
0x2c7e7c mov	x24, x0
0x2c7e80 cbz	x0, 0x2c8358
0x2c7e84 nop
0x2c7e88 ldr	x1, #0xb6390 ; Objc selector ref: isUIAppBridging
0x2c7e8c mov	x0, x24
0x2c7e90 bl	0x2ecd00 ; Objc message: -[x0 isUIAppBridging]
0x2c7e94 cbz	w0, 0x2c8358
0x2c7e98 mov	x0, x22
0x2c7e9c bl	0x2c6958
0x2c7ea0 mov	x29, x29
0x2c7ea4 bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
0x2c7ea8 mov	x25, x0
0x2c7eac cbz	x0, 0x2c8350
0x2c7eb0 nop
0x2c7eb4 ldr	x1, #0xb6e64 ; Objc selector ref: shouldBridge:
0x2c7eb8 mov	x0, x24
0x2c7ebc mov	x2, x25
0x2c7ec0 bl	0x2ecd00 ; Objc message: -[x0 shouldBridge:]
0x2c7ec4 cbz	w0, 0x2c8350
0x2c7ec8 nop
0x2c7ecc ldr	x1, #0xb6e24 ; Objc selector ref: renderSizeForBundleID:
0x2c7ed0 mov	x0, x24
0x2c7ed4 mov	x2, x25
0x2c7ed8 bl	0x2ecd00 ; Objc message: -[x0 renderSizeForBundleID:]
0x2c7edc mov.16b	v8, v0
0x2c7ee0 mov.16b	v9, v1
0x2c7ee4 mov	x0, x19
0x2c7ee8 bl	0x2ecd3c ; symbol stub for: _objc_retain
0x2c7eec mov	x26, x0
0x2c7ef0 cbz	x0, 0x2c8348
0x2c7ef4 fcmp	d8, #0.0
0x2c7ef8 b.le	0x2c7fb8
0x2c7efc fcmp	d9, #0.0
0x2c7f00 b.le	0x2c7fb8
0x2c7f04 nop
0x2c7f08 ldr	x2, #0xb6658 ; Objc selector ref: frame
0x2c7f0c nop
0x2c7f10 ldr	x27, #0xb56c8 ; Objc selector ref: respondsToSelector:
0x2c7f14 mov	x0, x26
0x2c7f18 mov	x1, x27
0x2c7f1c bl	0x2ecd00 ; Objc message: -[x0 respondsToSelector:]
0x2c7f20 cbz	w0, 0x2c7f4c
0x2c7f24 adr	x0, #286284 ; literal pool for: "frame"
0x2c7f28 nop
0x2c7f2c bl	0x2ecdfc ; symbol stub for: _sel_registerName
0x2c7f30 mov	x1, x0
0x2c7f34 mov	x0, x26
0x2c7f38 bl	0x2ecd00 ; Objc message: -[x0 respondsToSelector:]
0x2c7f3c fcmp	d2, d8
0x2c7f40 b.ne	0x2c7f4c
0x2c7f44 fcmp	d3, d9
0x2c7f48 b.eq	0x2c7fc0
0x2c7f4c nop
0x2c7f50 ldr	x28, #0xb5ac0 ; Objc selector ref: setFrame:
0x2c7f54 mov	x0, x26
0x2c7f58 mov	x1, x27
0x2c7f5c mov	x2, x28
0x2c7f60 bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
0x2c7f64 cbz	w0, 0x2c7f84
0x2c7f68 fmov	d0, xzr
0x2c7f6c fmov	d1, xzr
~~~

## Evidence boundaries
- Native12 Dashboard filter explicitly contains com.google.ios.youtube; static filter is not proof of injection running on user's iPhone.
- Distinguish main scene orientation policy, content-reference-size hooks and scene-settings host transaction; none alone proves renderer/player UIKit rotation accepted.
- Original Native12 fullscreen support and app-side role must be evaluated separately. Do not copy licensing, global private hooks, or arbitrary rotation/zoom.
- No runtime source patch or new DEB/Sileo/device pass in this scan.
