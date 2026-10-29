# Original CBTouchPassThroughRootSceneWindow: dynamically installed C IMPs

- Original Native12 DEB SHA256: `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`
- Dashboard SHA256: `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`
- Addresses derived from original CBWindow.createWindows ADR + class_addMethod.
- This is original ARM64 evidence, not a DuoFace implementation or a physical touch test.

## hitTest:withEvent: at 0xb2d50
Instructions: 108

    b2d50:	sub	sp, sp, #0x70
    b2d54:	stp	d9, d8, [sp, #0x10]
    b2d58:	stp	x26, x25, [sp, #0x20]
    b2d5c:	stp	x24, x23, [sp, #0x30]
    b2d60:	stp	x22, x21, [sp, #0x40]
    b2d64:	stp	x20, x19, [sp, #0x50]
    b2d68:	stp	x29, x30, [sp, #0x60]
    b2d6c:	add	x29, sp, #0x60
    b2d70:	mov	x20, x2
    b2d74:	mov.16b	v8, v1
    b2d78:	mov.16b	v9, v0
    b2d7c:	mov	x21, x1
    b2d80:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    b2d84:	mov	x19, x0
    b2d88:	mov	x0, x20
    b2d8c:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    b2d90:	mov	x20, x0
    b2d94:	adrp	x8, 715 ; 0x37d000
    b2d98:	ldr	x1, [x8, #0x9b0] ; Objc selector ref: bounds
    b2d9c:	mov	x0, x19
    b2da0:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    b2da4:	mov.16b	v4, v9
    b2da8:	mov.16b	v5, v8
    b2dac:	bl	0x2ec898 ; symbol stub for: _CGRectContainsPoint
    b2db0:	cbz	w0, 0xb2eb8
    b2db4:	adrp	x8, 717 ; 0x37f000
    b2db8:	ldr	x0, [x8, #0x910] ; Objc class ref: CBWindow
    b2dbc:	adrp	x8, 716 ; 0x37e000
    b2dc0:	ldr	x1, [x8, #0x320] ; Objc selector ref: carPlayUsableBounds
    b2dc4:	bl	0x2ecd00 ; Objc message: +[CBWindow carPlayUsableBounds]
    b2dc8:	mov.16b	v4, v9
    b2dcc:	mov.16b	v5, v8
    b2dd0:	bl	0x2ec898 ; symbol stub for: _CGRectContainsPoint
    b2dd4:	cbz	w0, 0xb2e6c
    b2dd8:	adrp	x8, 717 ; 0x37f000
    b2ddc:	ldr	x0, [x8, #0x8d8] ; Objc class ref: CBBridgeManager
    b2de0:	adrp	x8, 715 ; 0x37d000
    b2de4:	ldr	x1, [x8, #0x518] ; Objc selector ref: sharedInstance
    b2de8:	bl	0x2ecd00 ; Objc message: +[CBBridgeManager sharedInstance]
    b2dec:	mov	x29, x29
    b2df0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b2df4:	mov	x22, x0
    b2df8:	adrp	x8, 715 ; 0x37d000
    b2dfc:	ldr	x23, [x8, #0xf20] ; Objc selector ref: currentApp
    b2e00:	mov	x1, x23
    b2e04:	bl	0x2ecd00 ; Objc message: -[x0 currentApp]
    b2e08:	mov	x29, x29
    b2e0c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b2e10:	mov	x25, x0
    b2e14:	adrp	x8, 715 ; 0x37d000
    b2e18:	ldr	x24, [x8, #0xf28] ; Objc selector ref: noteUserActivity
    b2e1c:	nop
    b2e20:	ldr	x1, [x8, #0x5d8]
    b2e24:	mov	x2, x24
    b2e28:	bl	0x2ecd00 ; Objc message: -[x0 noteUserActivity]
    b2e2c:	mov	x26, x0
    b2e30:	mov	x0, x25
    b2e34:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b2e38:	cbz	w26, 0xb2e64
    b2e3c:	mov	x0, x22
    b2e40:	mov	x1, x23
    b2e44:	bl	0x2ecd00 ; Objc message: -[x0 noteUserActivity]
    b2e48:	mov	x29, x29
    b2e4c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b2e50:	mov	x23, x0
    b2e54:	mov	x1, x24
    b2e58:	bl	0x2ecd00 ; Objc message: -[x0 noteUserActivity]
    b2e5c:	mov	x0, x23
    b2e60:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b2e64:	mov	x0, x22
    b2e68:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b2e6c:	mov	x0, x19
    b2e70:	bl	0x2ecdcc ; symbol stub for: _object_getClass
    b2e74:	bl	0x2ecb14 ; symbol stub for: _class_getSuperclass
    b2e78:	stp	x19, x0, [sp]
    b2e7c:	mov	x0, sp
    b2e80:	mov	x1, x21
    b2e84:	mov.16b	v0, v9
    b2e88:	mov.16b	v1, v8
    b2e8c:	mov	x2, x20
    b2e90:	bl	0x2ecd0c ; symbol stub for: _objc_msgSendSuper
    b2e94:	mov	x29, x29
    b2e98:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b2e9c:	mov	x22, x0
    b2ea0:	cmp	x0, x19
    b2ea4:	b.eq	0xb2ec0
    b2ea8:	mov	x0, x22
    b2eac:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    b2eb0:	mov	x21, x0
    b2eb4:	b	0xb2ec4
    b2eb8:	mov	x21, #0x0
    b2ebc:	b	0xb2ecc
    b2ec0:	mov	x21, #0x0
    b2ec4:	mov	x0, x22
    b2ec8:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b2ecc:	mov	x0, x20
    b2ed0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b2ed4:	mov	x0, x19
    b2ed8:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b2edc:	mov	x0, x21
    b2ee0:	ldp	x29, x30, [sp, #0x60]
    b2ee4:	ldp	x20, x19, [sp, #0x50]
    b2ee8:	ldp	x22, x21, [sp, #0x40]
    b2eec:	ldp	x24, x23, [sp, #0x30]
    b2ef0:	ldp	x26, x25, [sp, #0x20]
    b2ef4:	ldp	d9, d8, [sp, #0x10]
    b2ef8:	add	sp, sp, #0x70
    b2efc:	b	0x2ecc7c ; symbol stub for: _objc_autoreleaseReturnValue

## pointInside:withEvent: at 0xb2f00
Instructions: 145

    b2f00:	sub	sp, sp, #0x170
    b2f04:	stp	d11, d10, [sp, #0xf0]
    b2f08:	stp	d9, d8, [sp, #0x100]
    b2f0c:	stp	x28, x27, [sp, #0x110]
    b2f10:	stp	x26, x25, [sp, #0x120]
    b2f14:	stp	x24, x23, [sp, #0x130]
    b2f18:	stp	x22, x21, [sp, #0x140]
    b2f1c:	stp	x20, x19, [sp, #0x150]
    b2f20:	stp	x29, x30, [sp, #0x160]
    b2f24:	add	x29, sp, #0x160
    b2f28:	mov	x20, x2
    b2f2c:	mov.16b	v8, v1
    b2f30:	mov.16b	v9, v0
    b2f34:	adrp	x8, 658 ; 0x344000
    b2f38:	ldr	x8, [x8, #0x140] ; literal pool symbol address: ___stack_chk_guard
    b2f3c:	ldr	x8, [x8]
    b2f40:	stur	x8, [x29, #-0x80]
    b2f44:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    b2f48:	mov	x19, x0
    b2f4c:	mov	x0, x20
    b2f50:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    b2f54:	stp	x0, x19, [sp, #0x10]
    b2f58:	adrp	x8, 715 ; 0x37d000
    b2f5c:	ldr	x1, [x8, #0x9b0] ; Objc selector ref: bounds
    b2f60:	mov	x0, x19
    b2f64:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    b2f68:	mov.16b	v4, v9
    b2f6c:	mov.16b	v5, v8
    b2f70:	bl	0x2ec898 ; symbol stub for: _CGRectContainsPoint
    b2f74:	cbz	w0, 0xb30d8
    b2f78:	adrp	x8, 717 ; 0x37f000
    b2f7c:	ldr	x0, [x8, #0x910] ; Objc class ref: CBWindow
    b2f80:	adrp	x8, 716 ; 0x37e000
    b2f84:	ldr	x1, [x8, #0x320] ; Objc selector ref: carPlayUsableBounds
    b2f88:	bl	0x2ecd00 ; Objc message: +[CBWindow carPlayUsableBounds]
    b2f8c:	mov.16b	v4, v9
    b2f90:	mov.16b	v5, v8
    b2f94:	bl	0x2ec898 ; symbol stub for: _CGRectContainsPoint
    b2f98:	tbnz	w0, #0x0, 0xb30e8
    b2f9c:	movi.16b	v0, #0x0
    b2fa0:	stp	q0, q0, [sp, #0x40]
    b2fa4:	stp	q0, q0, [sp, #0x20]
    b2fa8:	adrp	x8, 715 ; 0x37d000
    b2fac:	ldr	x1, [x8, #0xfd0] ; Objc selector ref: subviews
    b2fb0:	ldr	x0, [sp, #0x18]
    b2fb4:	bl	0x2ecd00 ; Objc message: -[x0 subviews]
    b2fb8:	mov	x29, x29
    b2fbc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b2fc0:	mov	x21, x0
    b2fc4:	adrp	x8, 715 ; 0x37d000
    b2fc8:	ldr	x1, [x8, #0x898] ; Objc selector ref: countByEnumeratingWithState:objects:count:
    b2fcc:	add	x2, sp, #0x20
    b2fd0:	add	x3, sp, #0x60
    b2fd4:	str	x1, [sp, #0x8]
    b2fd8:	mov	w4, #0x10
    b2fdc:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    b2fe0:	cbz	x0, 0xb30d0
    b2fe4:	ldr	x8, [sp, #0x30]
    b2fe8:	ldr	x22, [x8]
    b2fec:	adrp	x8, 607 ; 0x311000
    b2ff0:	ldr	d10, [x8, #0x948]
    b2ff4:	mov	x20, #0x0
    b2ff8:	adrp	x8, 715 ; 0x37d000
    b2ffc:	ldr	x23, [x8, #0xe70] ; Objc selector ref: isHidden
    b3000:	nop
    b3004:	ldr	x24, [x8, #0xe78]
    b3008:	adrp	x8, 715 ; 0x37e000
    b300c:	ldr	x25, [x8, #0x5b8] ; Objc selector ref: isUserInteractionEnabled
    b3010:	nop
    b3014:	ldr	x26, [x8, #0x5c0]
    b3018:	cmp	x0, #0x1
    b301c:	csinc	x19, x0, xzr, hi
    b3020:	nop
    b3024:	ldr	x27, [x8, #0x5a8]
    b3028:	ldr	x8, [sp, #0x30]
    b302c:	ldr	x8, [x8]
    b3030:	cmp	x8, x22
    b3034:	b.eq	0xb3040
    b3038:	mov	x0, x21
    b303c:	bl	0x2eccb8 ; symbol stub for: _objc_enumerationMutation
    b3040:	ldr	x8, [sp, #0x28]
    b3044:	ldr	x28, [x8, x20, lsl #3]
    b3048:	mov	x0, x28
    b304c:	mov	x1, x23
    b3050:	bl	0x2ecd00 ; Objc message: -[x0 isUserInteractionEnabled]
    b3054:	tbnz	w0, #0x0, 0xb30a8
    b3058:	mov	x0, x28
    b305c:	mov	x1, x24
    b3060:	bl	0x2ecd00 ; Objc message: -[x0 isUserInteractionEnabled]
    b3064:	fcmp	d0, d10
    b3068:	b.le	0xb30a8
    b306c:	mov	x0, x28
    b3070:	mov	x1, x25
    b3074:	bl	0x2ecd00 ; Objc message: -[x0 isUserInteractionEnabled]
    b3078:	cbz	w0, 0xb30a8
    b307c:	mov	x0, x28
    b3080:	mov	x1, x26
    b3084:	mov.16b	v0, v9
    b3088:	mov.16b	v1, v8
    b308c:	ldr	x2, [sp, #0x18]
    b3090:	bl	0x2ecd00 ; Objc message: -[x0 isUserInteractionEnabled]
    b3094:	mov	x0, x28
    b3098:	mov	x1, x27
    b309c:	ldr	x2, [sp, #0x10]
    b30a0:	bl	0x2ecd00 ; Objc message: -[x0 isUserInteractionEnabled]
    b30a4:	tbnz	w0, #0x0, 0xb30e0
    b30a8:	add	x20, x20, #0x1
    b30ac:	cmp	x19, x20
    b30b0:	b.ne	0xb3028
    b30b4:	add	x2, sp, #0x20
    b30b8:	add	x3, sp, #0x60
    b30bc:	mov	x0, x21
    b30c0:	ldr	x1, [sp, #0x8]
    b30c4:	mov	w4, #0x10
    b30c8:	bl	0x2ecd00 ; Objc message: -[x0 isUserInteractionEnabled]
    b30cc:	cbnz	x0, 0xb2ff4
    b30d0:	mov	x0, x21
    b30d4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b30d8:	mov	w21, #0x0
    b30dc:	b	0xb30ec
    b30e0:	mov	x0, x21
    b30e4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b30e8:	mov	w21, #0x1
    b30ec:	ldr	x0, [sp, #0x10]
    b30f0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b30f4:	ldr	x0, [sp, #0x18]
    b30f8:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b30fc:	ldur	x8, [x29, #-0x80]
    b3100:	adrp	x9, 657 ; 0x344000
    b3104:	ldr	x9, [x9, #0x140] ; literal pool symbol address: ___stack_chk_guard
    b3108:	ldr	x9, [x9]
    b310c:	cmp	x9, x8
    b3110:	b.ne	0xb3140
    b3114:	mov	x0, x21
    b3118:	ldp	x29, x30, [sp, #0x160]
    b311c:	ldp	x20, x19, [sp, #0x150]
    b3120:	ldp	x22, x21, [sp, #0x140]
    b3124:	ldp	x24, x23, [sp, #0x130]
    b3128:	ldp	x26, x25, [sp, #0x120]
    b312c:	ldp	x28, x27, [sp, #0x110]
    b3130:	ldp	d9, d8, [sp, #0x100]
    b3134:	ldp	d11, d10, [sp, #0xf0]
    b3138:	add	sp, sp, #0x170
    b313c:	ret
    b3140:	bl	0x2eca9c ; symbol stub for: ___stack_chk_fail

## sendEvent: at 0xb3144
Instructions: 136

    b3144:	sub	sp, sp, #0x140
    b3148:	stp	x28, x27, [sp, #0xe0]
    b314c:	stp	x26, x25, [sp, #0xf0]
    b3150:	stp	x24, x23, [sp, #0x100]
    b3154:	stp	x22, x21, [sp, #0x110]
    b3158:	stp	x20, x19, [sp, #0x120]
    b315c:	stp	x29, x30, [sp, #0x130]
    b3160:	add	x29, sp, #0x130
    b3164:	mov	x21, x2
    b3168:	mov	x20, x1
    b316c:	adrp	x8, 657 ; 0x344000
    b3170:	ldr	x8, [x8, #0x140] ; literal pool symbol address: ___stack_chk_guard
    b3174:	ldr	x8, [x8]
    b3178:	stur	x8, [x29, #-0x60]
    b317c:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    b3180:	mov	x19, x0
    b3184:	mov	x0, x21
    b3188:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    b318c:	mov	x21, x0
    b3190:	adrp	x8, 715 ; 0x37e000
    b3194:	ldr	x1, [x8, #0x5c8] ; Objc selector ref: type
    b3198:	bl	0x2ecd00 ; Objc message: -[x0 type]
    b319c:	cbnz	x0, 0xb32f8
    b31a0:	movi.16b	v0, #0x0
    b31a4:	stp	q0, q0, [sp, #0x30]
    b31a8:	stp	q0, q0, [sp, #0x10]
    b31ac:	adrp	x8, 715 ; 0x37e000
    b31b0:	ldr	x1, [x8, #0x5d0] ; Objc selector ref: allTouches
    b31b4:	mov	x0, x21
    b31b8:	bl	0x2ecd00 ; Objc message: -[x0 allTouches]
    b31bc:	mov	x29, x29
    b31c0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b31c4:	mov	x22, x0
    b31c8:	adrp	x8, 714 ; 0x37d000
    b31cc:	ldr	x23, [x8, #0x898] ; Objc selector ref: countByEnumeratingWithState:objects:count:
    b31d0:	add	x2, sp, #0x10
    b31d4:	add	x3, sp, #0x50
    b31d8:	mov	x1, x23
    b31dc:	mov	w4, #0x10
    b31e0:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    b31e4:	cbz	x0, 0xb32f0
    b31e8:	ldr	x8, [sp, #0x20]
    b31ec:	ldr	x25, [x8]
    b31f0:	adrp	x26, 715 ; 0x37e000
    b31f4:	mov	x27, #0x0
    b31f8:	ldr	x24, [x26, #0x5d8]
    b31fc:	cmp	x0, #0x1
    b3200:	csinc	x28, x0, xzr, hi
    b3204:	ldr	x8, [sp, #0x20]
    b3208:	ldr	x8, [x8]
    b320c:	cmp	x8, x25
    b3210:	b.eq	0xb321c
    b3214:	mov	x0, x22
    b3218:	bl	0x2eccb8 ; symbol stub for: _objc_enumerationMutation
    b321c:	ldr	x8, [sp, #0x18]
    b3220:	ldr	x0, [x8, x27, lsl #3]
    b3224:	mov	x1, x24
    b3228:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    b322c:	cbz	x0, 0xb325c
    b3230:	add	x27, x27, #0x1
    b3234:	cmp	x28, x27
    b3238:	b.ne	0xb3204
    b323c:	add	x2, sp, #0x10
    b3240:	add	x3, sp, #0x50
    b3244:	mov	x0, x22
    b3248:	mov	x1, x23
    b324c:	mov	w4, #0x10
    b3250:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    b3254:	cbnz	x0, 0xb31f4
    b3258:	b	0xb32f0
    b325c:	adrp	x8, 716 ; 0x37f000
    b3260:	ldr	x0, [x8, #0x8d8] ; Objc class ref: CBBridgeManager
    b3264:	adrp	x8, 714 ; 0x37d000
    b3268:	ldr	x1, [x8, #0x518] ; Objc selector ref: sharedInstance
    b326c:	bl	0x2ecd00 ; Objc message: +[CBBridgeManager sharedInstance]
    b3270:	mov	x29, x29
    b3274:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b3278:	mov	x23, x0
    b327c:	adrp	x8, 714 ; 0x37d000
    b3280:	ldr	x24, [x8, #0xf20] ; Objc selector ref: currentApp
    b3284:	mov	x1, x24
    b3288:	bl	0x2ecd00 ; Objc message: -[x0 currentApp]
    b328c:	mov	x29, x29
    b3290:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b3294:	mov	x26, x0
    b3298:	adrp	x8, 714 ; 0x37d000
    b329c:	ldr	x25, [x8, #0xf28] ; Objc selector ref: noteUserActivity
    b32a0:	nop
    b32a4:	ldr	x1, [x8, #0x5d8]
    b32a8:	mov	x2, x25
    b32ac:	bl	0x2ecd00 ; Objc message: -[x0 noteUserActivity]
    b32b0:	mov	x27, x0
    b32b4:	mov	x0, x26
    b32b8:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b32bc:	cbz	w27, 0xb32e8
    b32c0:	mov	x0, x23
    b32c4:	mov	x1, x24
    b32c8:	bl	0x2ecd00 ; Objc message: -[x0 noteUserActivity]
    b32cc:	mov	x29, x29
    b32d0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b32d4:	mov	x24, x0
    b32d8:	mov	x1, x25
    b32dc:	bl	0x2ecd00 ; Objc message: -[x0 noteUserActivity]
    b32e0:	mov	x0, x24
    b32e4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b32e8:	mov	x0, x23
    b32ec:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b32f0:	mov	x0, x22
    b32f4:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b32f8:	mov	x0, x19
    b32fc:	bl	0x2ecdcc ; symbol stub for: _object_getClass
    b3300:	bl	0x2ecb14 ; symbol stub for: _class_getSuperclass
    b3304:	stp	x19, x0, [sp]
    b3308:	mov	x0, sp
    b330c:	mov	x1, x20
    b3310:	mov	x2, x21
    b3314:	bl	0x2ecd0c ; symbol stub for: _objc_msgSendSuper
    b3318:	mov	x0, x21
    b331c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b3320:	mov	x0, x19
    b3324:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b3328:	ldur	x8, [x29, #-0x60]
    b332c:	adrp	x9, 657 ; 0x344000
    b3330:	ldr	x9, [x9, #0x140] ; literal pool symbol address: ___stack_chk_guard
    b3334:	ldr	x9, [x9]
    b3338:	cmp	x9, x8
    b333c:	b.ne	0xb3360
    b3340:	ldp	x29, x30, [sp, #0x130]
    b3344:	ldp	x20, x19, [sp, #0x120]
    b3348:	ldp	x22, x21, [sp, #0x110]
    b334c:	ldp	x24, x23, [sp, #0x100]
    b3350:	ldp	x26, x25, [sp, #0xf0]
    b3354:	ldp	x28, x27, [sp, #0xe0]
    b3358:	add	sp, sp, #0x140
    b335c:	ret
    b3360:	bl	0x2eca9c ; symbol stub for: ___stack_chk_fail

