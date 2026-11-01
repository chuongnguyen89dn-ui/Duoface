# CarPlayPro Speed original hook-import xrefs (ARM64, static only)

These are actual original import stub references. A found call to
`MSHookFunction` is evidence of a hooking mechanism, **not** proof of
which GOFA method was hooked or which traffic data fields are available.

## Exact otool indirect import lines
- `0x000000000004361c   138 _MSHookFunction`
- `0x0000000000043628   139 _MSHookMessageEx`
- `0x0000000000043898   304 _dlsym`
- `0x0000000000043a3c   356 _objc_msgSend`
- `0x0000000000043a48   357 _objc_msgSendSuper2`
- `0x0000000000043d24   418 _swift_dynamicCast`
- `0x000000000005c3a0   138 _MSHookFunction`
- `0x000000000005c3a8   139 _MSHookMessageEx`
- `0x000000000005c620   304 _dlsym`
- `0x000000000005c7c0   356 _objc_msgSend`
- `0x000000000005c7c8   356 _objc_msgSend`
- `0x000000000005c7d0   357 _objc_msgSendSuper2`
- `0x000000000005c9b8   418 _swift_dynamicCast`

## Direct B/BL call sites to these stubs
- `0xab58` in `0xa988`: `_MSHookMessageEx` -> 0x43628
- `0xda80` in `0xa988`: `_objc_msgSend` -> 0x43a3c
- `0xe7a0` in `0xa988`: `_objc_msgSend` -> 0x43a3c
- `0xe7e0` in `0xa988`: `_objc_msgSend` -> 0x43a3c
- `0xe8d8` in `0xa988`: `_objc_msgSend` -> 0x43a3c
- `0xe8f4` in `0xa988`: `_objc_msgSend` -> 0x43a3c
- `0x17c98` in `0x17ac4`: `_MSHookMessageEx` -> 0x43628
- `0x1a988` in `0x1a8e8`: `_objc_msgSend` -> 0x43a3c
- `0x278a8` in `0x27840`: `_dlsym` -> 0x43898
- `0x2f83c` in `0x2f798`: `_MSHookMessageEx` -> 0x43628
- `0x2f85c` in `0x2f798`: `_MSHookMessageEx` -> 0x43628
- `0x2f9ec` in `0x2f798`: `_MSHookMessageEx` -> 0x43628
- `0x2fa14` in `0x2f798`: `_MSHookMessageEx` -> 0x43628
- `0x2fa3c` in `0x2f798`: `_MSHookMessageEx` -> 0x43628
- `0x2fae4` in `0x2f798`: `_MSHookMessageEx` -> 0x43628
- `0x2fb00` in `0x2f798`: `_MSHookMessageEx` -> 0x43628
- `0x2fb20` in `0x2f798`: `_MSHookMessageEx` -> 0x43628
- `0x2fb40` in `0x2f798`: `_MSHookMessageEx` -> 0x43628
- `0x2fb60` in `0x2f798`: `_MSHookMessageEx` -> 0x43628
- `0x30178` in `0x2f798`: `_MSHookMessageEx` -> 0x43628
- `0x30210` in `0x2f798`: `_MSHookMessageEx` -> 0x43628
- `0x3022c` in `0x2f798`: `_MSHookMessageEx` -> 0x43628
- `0x3028c` in `0x2f798`: `_MSHookFunction` -> 0x4361c
- `0x303d8` in `0x2f798`: `_MSHookFunction` -> 0x4361c
- `0x30710` in `0x2f798`: `_MSHookFunction` -> 0x4361c
- `0x30840` in `0x2f798`: `_MSHookFunction` -> 0x4361c
- `0x3086c` in `0x2f798`: `_MSHookFunction` -> 0x4361c
- `0x308e4` in `0x2f798`: `_MSHookFunction` -> 0x4361c
- `0x311f4` in `0x30f40`: `_MSHookMessageEx` -> 0x43628
- `0x31d30` in `0x31cbc`: `_objc_msgSend` -> 0x43a3c
- `0x32428` in `0x32288`: `_objc_msgSend` -> 0x43a3c
- `0x34b60` in `0x34ab0`: `_objc_msgSend` -> 0x43a3c
- `0x34b7c` in `0x34ab0`: `_objc_msgSend` -> 0x43a3c
- `0x369e8` in `0x368f4`: `_objc_msgSend` -> 0x43a3c
- `0x3716c` in `0x36f64`: `_MSHookMessageEx` -> 0x43628
- `0x371b0` in `0x36f64`: `_MSHookMessageEx` -> 0x43628
- `0x37354` in `0x3728c`: `_MSHookMessageEx` -> 0x43628
- `0x373cc` in `0x3728c`: `_MSHookMessageEx` -> 0x43628
- `0x37488` in `0x3728c`: `_MSHookMessageEx` -> 0x43628
- `0x37a8c` in `0x37a20`: `_objc_msgSend` -> 0x43a3c
- `0x37bd0` in `0x37b64`: `_objc_msgSend` -> 0x43a3c
- `0x37d48` in `0x37ca8`: `_objc_msgSend` -> 0x43a3c
- `0x390a4` in `0x38f60`: `_MSHookMessageEx` -> 0x43628
- `0x39188` in `0x38f60`: `_MSHookMessageEx` -> 0x43628
- `0x393a0` in `0x38f60`: `_dlsym` -> 0x43898
- `0x393b4` in `0x38f60`: `_dlsym` -> 0x43898
- `0x393c8` in `0x38f60`: `_dlsym` -> 0x43898
- `0x393f0` in `0x38f60`: `_MSHookFunction` -> 0x4361c
- `0x39408` in `0x38f60`: `_MSHookFunction` -> 0x4361c
- `0x39420` in `0x38f60`: `_MSHookFunction` -> 0x4361c
- `0x3c2e0` in `0x3c188`: `_objc_msgSend` -> 0x43a3c
- `0x3c308` in `0x3c188`: `_objc_msgSend` -> 0x43a3c
- `0x3c334` in `0x3c188`: `_objc_msgSend` -> 0x43a3c
- `0x3cc9c` in `0x3cb98`: `_objc_msgSend` -> 0x43a3c
- `0x3ccc8` in `0x3cb98`: `_objc_msgSend` -> 0x43a3c
- `0x3ccec` in `0x3cb98`: `_objc_msgSend` -> 0x43a3c
- `0x3e2b4` in `0x3e234`: `_swift_dynamicCast` -> 0x43d24
- `0x3e2e4` in `0x3e234`: `_objc_msgSend` -> 0x43a3c
- `0x3e340` in `0x3e234`: `_objc_msgSend` -> 0x43a3c
- `0x3e3c0` in `0x3e390`: `_objc_msgSend` -> 0x43a3c
- `0x3e448` in `0x3e390`: `_objc_msgSend` -> 0x43a3c
- `0x3e62c` in `0x3e390`: `_objc_msgSend` -> 0x43a3c
- `0x3ea18` in `0x3e940`: `_objc_msgSend` -> 0x43a3c
- `0x3eb24` in `0x3e940`: `_objc_msgSend` -> 0x43a3c
- `0x3f0bc` in `0x3e940`: `_swift_dynamicCast` -> 0x43d24
- `0x3f128` in `0x3e940`: `_objc_msgSend` -> 0x43a3c
- `0x3f18c` in `0x3e940`: `_swift_dynamicCast` -> 0x43d24
- `0x3f340` in `0x3e940`: `_swift_dynamicCast` -> 0x43d24
- `0x3f394` in `0x3e940`: `_swift_dynamicCast` -> 0x43d24
- `0x3f3f0` in `0x3e940`: `_swift_dynamicCast` -> 0x43d24
- `0x3f410` in `0x3e940`: `_objc_msgSend` -> 0x43a3c
- `0x3f420` in `0x3e940`: `_objc_msgSend` -> 0x43a3c
- `0x3f434` in `0x3e940`: `_objc_msgSend` -> 0x43a3c
- `0x3f448` in `0x3e940`: `_objc_msgSend` -> 0x43a3c
- `0x3f51c` in `0x3e940`: `_objc_msgSend` -> 0x43a3c
- `0x40cd4` in `0x40c70`: `_swift_dynamicCast` -> 0x43d24
- `0x4257c` in `0x42560`: `_dlsym` -> 0x43898
- `0x42908` in `0x428ec`: `_dlsym` -> 0x43898
- `0x42a00` in `0x429e4`: `_dlsym` -> 0x43898
- `0x42a30` in `0x42a14`: `_dlsym` -> 0x43898
- `0x43248` in `0x4322c`: `_dlsym` -> 0x43898
- `0x43278` in `0x4325c`: `_dlsym` -> 0x43898

## Evidence limitations
ObjC dispatch/Swift function pointers may use BLR,
and imported stubs can be wrapped by local trampoline functions. This is
not runtime source-model field evidence and does not authorize made-up
GOFA camera, speed-limit or next-turn values.
