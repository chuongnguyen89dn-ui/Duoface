# SHA verified Native12 original Dock and usable bounds IMP evidence

- Original read-only Mach-O; not an independent DuoFace patch.
- Original SHA256: `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`.
- Native Mach-O SHA256: `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`.
- Full ARM64 disassembly in original-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json.

## CBWindow.carPlayContentInsets 0xb0c98..0xb0ef4
Original instructions=151
    b0c98:	stp	d13, d12, [sp, #-0x80]!
    b0c9c:	stp	d11, d10, [sp, #0x10]
    b0ca0:	stp	d9, d8, [sp, #0x20]
    b0ca4:	stp	x26, x25, [sp, #0x30]
    b0ca8:	stp	x24, x23, [sp, #0x40]
    b0cac:	stp	x22, x21, [sp, #0x50]
    b0cb0:	stp	x20, x19, [sp, #0x60]
    b0cb4:	stp	x29, x30, [sp, #0x70]
    b0cb8:	add	x29, sp, #0x70
    b0cbc:	adrp	x26, 721 ; 0x381000
    b0cc0:	add	x26, x26, #0x590
    b0cc4:	ldp	d10, d11, [x26, #0x10]
    b0cc8:	ldp	d8, d9, [x26]
    b0ccc:	fcmp	d9, #0.0
    b0cd0:	b.gt	0xb0e8c
    b0cd4:	fcmp	d11, #0.0
    b0cd8:	b.gt	0xb0e8c
    b0cdc:	fcmp	d10, #0.0
    b0ce0:	b.gt	0xb0e8c
    b0ce4:	fcmp	d8, #0.0
    b0ce8:	b.gt	0xb0e8c
    b0cec:	adrp	x8, 719 ; 0x37f000
    b0cf0:	ldr	x19, [x8, #0x708] ; Objc class ref: _OBJC_CLASS_$_NSString
    b0cf4:	adrp	x8, 721 ; 0x381000
    b0cf8:	ldr	x8, [x8, #0x5b8]
    b0cfc:	cmn	x8, #0x1
    b0d00:	b.ne	0xb0edc
    b0d04:	adrp	x8, 721 ; 0x381000
    b0d08:	ldr	x2, [x8, #0x5b0]
    b0d0c:	adrp	x8, 717 ; 0x37d000
    b0d10:	ldr	x1, [x8, #0xcd0] ; Objc selector ref: stringWithContentsOfFile:encoding:error:
    b0d14:	mov	x0, x19
    b0d18:	mov	w3, #0x4
    b0d1c:	mov	x4, #0x0
    b0d20:	bl	0x2ecd00 ; Objc message: +[NSString stringWithContentsOfFile:encoding:error:]
    b0d24:	mov	x29, x29
    b0d28:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b0d2c:	mov	x19, x0
    b0d30:	cbz	x0, 0xb0d80
    b0d34:	adrp	x8, 717 ; 0x37d000
    b0d38:	ldr	x1, [x8, #0x568] ; Objc selector ref: length
    b0d3c:	mov	x0, x19
    b0d40:	bl	0x2ecd00 ; Objc message: -[x0 length]
    b0d44:	cbz	x0, 0xb0d80
    b0d48:	mov	x0, x19
    b0d4c:	bl	0x2eca24 ; symbol stub for: _UIEdgeInsetsFromString
    b0d50:	mov.16b	v8, v0
    b0d54:	mov.16b	v9, v1
    b0d58:	mov.16b	v10, v2
    b0d5c:	mov.16b	v11, v3
    b0d60:	fcmp	d0, #0.0
    b0d64:	b.gt	0xb0ec0
    b0d68:	fcmp	d10, #0.0
    b0d6c:	b.gt	0xb0ec0
    b0d70:	fcmp	d9, #0.0
    b0d74:	b.gt	0xb0ec0
    b0d78:	fcmp	d11, #0.0
    b0d7c:	b.gt	0xb0ec0
    b0d80:	adrp	x8, 719 ; 0x37f000
    b0d84:	ldr	x0, [x8, #0x910] ; Objc class ref: CBWindow
    b0d88:	adrp	x8, 718 ; 0x37e000
    b0d8c:	ldr	x1, [x8, #0x4c8] ; Objc selector ref: activeCarPlayWindow
    b0d90:	bl	0x2ecd00 ; Objc message: +[CBWindow activeCarPlayWindow]
    b0d94:	mov	x29, x29
    b0d98:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b0d9c:	mov	x20, x0
    b0da0:	fmov	d8, xzr
    b0da4:	cbz	x0, 0xb0e6c
    b0da8:	adrp	x8, 718 ; 0x37e000
    b0dac:	ldr	x21, [x8, #0x4d0] ; Objc selector ref: rootWindow
    b0db0:	mov	x0, x20
    b0db4:	mov	x1, x21
    b0db8:	bl	0x2ecd00 ; Objc message: -[x0 rootWindow]
    b0dbc:	mov	x29, x29
    b0dc0:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b0dc4:	cbz	x0, 0xb0e6c
    b0dc8:	mov	x23, x0
    b0dcc:	mov	x0, x20
    b0dd0:	mov	x1, x21
    b0dd4:	bl	0x2ecd00 ; Objc message: -[x0 rootWindow]
    b0dd8:	mov	x29, x29
    b0ddc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b0de0:	mov	x24, x0
    b0de4:	adrp	x8, 718 ; 0x37e000
    b0de8:	ldr	x22, [x8, #0x4d8] ; Objc selector ref: safeAreaInsets
    b0dec:	adrp	x8, 717 ; 0x37d000
    b0df0:	ldr	x1, [x8, #0x5d8] ; Objc selector ref: respondsToSelector:
    b0df4:	mov	x2, x22
    b0df8:	bl	0x2ecd00 ; Objc message: -[x0 respondsToSelector:]
    b0dfc:	mov	x25, x0
    b0e00:	mov	x0, x24
    b0e04:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b0e08:	mov	x0, x23
    b0e0c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b0e10:	cbz	w25, 0xb0e6c
    b0e14:	mov	x0, x20
    b0e18:	mov	x1, x21
    b0e1c:	bl	0x2ecd00 ; Objc message: -[x0 respondsToSelector:]
    b0e20:	mov	x29, x29
    b0e24:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b0e28:	mov	x21, x0
    b0e2c:	mov	x1, x22
    b0e30:	bl	0x2ecd00 ; Objc message: -[x0 respondsToSelector:]
    b0e34:	mov.16b	v12, v0
    b0e38:	mov.16b	v9, v1
    b0e3c:	mov.16b	v10, v2
    b0e40:	mov.16b	v11, v3
    b0e44:	mov	x0, x21
    b0e48:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b0e4c:	fcmp	d12, #0.0
    b0e50:	b.gt	0xb0ecc
    b0e54:	fcmp	d10, #0.0
    b0e58:	b.gt	0xb0ecc
    b0e5c:	fcmp	d9, #0.0
    b0e60:	b.gt	0xb0ecc
    b0e64:	fcmp	d11, #0.0
    b0e68:	b.gt	0xb0ecc
    b0e6c:	mov	x8, #0x4050000000000000
    b0e70:	fmov	d9, x8
    b0e74:	fmov	d10, xzr
    b0e78:	fmov	d11, xzr
    b0e7c:	mov	x0, x20
    b0e80:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b0e84:	mov	x0, x19
    b0e88:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b0e8c:	mov.16b	v0, v8
    b0e90:	mov.16b	v1, v9
    b0e94:	mov.16b	v2, v10
    b0e98:	mov.16b	v3, v11
    b0e9c:	ldp	x29, x30, [sp, #0x70]
    b0ea0:	ldp	x20, x19, [sp, #0x60]
    b0ea4:	ldp	x22, x21, [sp, #0x50]
    b0ea8:	ldp	x24, x23, [sp, #0x40]
    b0eac:	ldp	x26, x25, [sp, #0x30]
    b0eb0:	ldp	d9, d8, [sp, #0x20]
    b0eb4:	ldp	d11, d10, [sp, #0x10]
    b0eb8:	ldp	d13, d12, [sp], #0x80
    b0ebc:	ret
    b0ec0:	stp	d8, d9, [x26]
    b0ec4:	stp	d10, d11, [x26, #0x10]
    b0ec8:	b	0xb0e84
    b0ecc:	stp	d12, d9, [x26]
    b0ed0:	mov.16b	v8, v12
    b0ed4:	stp	d10, d11, [x26, #0x10]
    b0ed8:	b	0xb0e7c
    b0edc:	adrp	x0, 721 ; 0x381000
    b0ee0:	add	x0, x0, #0x5b8
    b0ee4:	adrp	x1, 660 ; 0x344000
    b0ee8:	add	x1, x1, #0xf08
    b0eec:	bl	0x2ecb38 ; symbol stub for: _dispatch_once
    b0ef0:	b	0xb0d04

## CBWindow.carPlayUsableBounds 0xb0ef4..0xb0ff0
Original instructions=63
    b0ef4:	stp	d11, d10, [sp, #-0x40]!
    b0ef8:	stp	d9, d8, [sp, #0x10]
    b0efc:	stp	x20, x19, [sp, #0x20]
    b0f00:	stp	x29, x30, [sp, #0x30]
    b0f04:	add	x29, sp, #0x30
    b0f08:	mov	x19, x0
    b0f0c:	adrp	x8, 718 ; 0x37e000
    b0f10:	ldr	x1, [x8, #0x4e0] ; Objc selector ref: carPlayScreenBounds
    b0f14:	bl	0x2ecd00 ; Objc message: -[x0 carPlayScreenBounds]
    b0f18:	mov.16b	v10, v0
    b0f1c:	mov.16b	v11, v1
    b0f20:	mov.16b	v9, v2
    b0f24:	mov.16b	v8, v3
    b0f28:	adrp	x8, 718 ; 0x37e000
    b0f2c:	ldr	x1, [x8, #0x4e8] ; Objc selector ref: carPlayContentInsets
    b0f30:	mov	x0, x19
    b0f34:	bl	0x2ecd00 ; Objc message: -[x0 carPlayContentInsets]
    b0f38:	mov.16b	v5, v2
    b0f3c:	fadd	d2, d1, d3
    b0f40:	fsub	d2, d9, d2
    b0f44:	fadd	d4, d0, d5
    b0f48:	fsub	d4, d8, d4
    b0f4c:	mov	x8, #0x4059000000000000
    b0f50:	fmov	d6, x8
    b0f54:	fcmp	d2, d6
    b0f58:	mov	x8, #0x4059000000000000
    b0f5c:	fmov	d6, x8
    b0f60:	fccmp	d4, d6, #0x8, ge
    b0f64:	b.ge	0xb0fcc
    b0f68:	fcmp	d0, #0.0
    b0f6c:	mov	x8, #-0x3fb0000000000000
    b0f70:	fmov	d1, x8
    b0f74:	fadd	d1, d9, d1
    b0f78:	fmov	d2, xzr
    b0f7c:	mov	x8, #0x4050000000000000
    b0f80:	fmov	d4, x8
    b0f84:	fsub	d6, d8, d0
    b0f88:	fcsel	d4, d4, d2, le
    b0f8c:	fcsel	d0, d2, d0, le
    b0f90:	fcsel	d1, d1, d9, le
    b0f94:	fcsel	d6, d8, d6, le
    b0f98:	fsub	d7, d8, d5
    b0f9c:	fcmp	d5, #0.0
    b0fa0:	fcsel	d4, d4, d2, le
    b0fa4:	fcsel	d0, d0, d2, le
    b0fa8:	fcsel	d5, d1, d9, le
    b0fac:	fcsel	d6, d6, d7, le
    b0fb0:	fsub	d7, d9, d3
    b0fb4:	fcmp	d3, #0.0
    b0fb8:	fcsel	d3, d4, d2, le
    b0fbc:	fcsel	d1, d0, d2, le
    b0fc0:	fcsel	d2, d5, d7, le
    b0fc4:	fcsel	d4, d6, d8, le
    b0fc8:	b	0xb0fd4
    b0fcc:	fadd	d3, d10, d1
    b0fd0:	fadd	d1, d11, d0
    b0fd4:	mov.16b	v0, v3
    b0fd8:	mov.16b	v3, v4
    b0fdc:	ldp	x29, x30, [sp, #0x30]
    b0fe0:	ldp	x20, x19, [sp, #0x20]
    b0fe4:	ldp	d9, d8, [sp, #0x10]
    b0fe8:	ldp	d11, d10, [sp], #0x40
    b0fec:	ret

## CBWindow.carPlayScreenBounds 0xb0704..0xb0c98
Original instructions=357
    b0704:	sub	sp, sp, #0x60
    b0708:	stp	d11, d10, [sp, #0x10]
    b070c:	stp	d9, d8, [sp, #0x20]
    b0710:	stp	x22, x21, [sp, #0x30]
    b0714:	stp	x20, x19, [sp, #0x40]
    b0718:	stp	x29, x30, [sp, #0x50]
    b071c:	add	x29, sp, #0x50
    b0720:	adrp	x8, 721 ; 0x381000
    b0724:	add	x8, x8, #0x580
    b0728:	ldp	d8, d9, [x8]
    b072c:	mov	x8, #0x4059000000000000
    b0730:	fmov	d0, x8
    b0734:	fcmp	d8, d0
    b0738:	mov	x8, #0x4059000000000000
    b073c:	fmov	d0, x8
    b0740:	fccmp	d9, d0, #0x4, gt
    b0744:	b.gt	0xb08a8
    b0748:	mov	x19, x0
    b074c:	adrp	x8, 719 ; 0x37f000
    b0750:	ldr	x20, [x8, #0x708] ; Objc class ref: _OBJC_CLASS_$_NSString
    b0754:	adrp	x8, 721 ; 0x381000
    b0758:	ldr	x8, [x8, #0x5c8]
    b075c:	cmn	x8, #0x1
    b0760:	b.ne	0xb0b4c
    b0764:	adrp	x8, 721 ; 0x381000
    b0768:	ldr	x0, [x8, #0x5c0]
    b076c:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    b0770:	mov	x21, x0
    b0774:	adrp	x8, 717 ; 0x37d000
    b0778:	ldr	x1, [x8, #0xcd0] ; Objc selector ref: stringWithContentsOfFile:encoding:error:
    b077c:	mov	x0, x20
    b0780:	mov	x2, x21
    b0784:	mov	w3, #0x4
    b0788:	mov	x4, #0x0
    b078c:	bl	0x2ecd00 ; Objc message: +[NSString stringWithContentsOfFile:encoding:error:]
    b0790:	mov	x29, x29
    b0794:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b0798:	mov	x20, x0
    b079c:	mov	x0, x21
    b07a0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b07a4:	cbz	x20, 0xb07e8
    b07a8:	adrp	x8, 717 ; 0x37d000
    b07ac:	ldr	x1, [x8, #0x568] ; Objc selector ref: length
    b07b0:	mov	x0, x20
    b07b4:	bl	0x2ecd00 ; Objc message: -[x0 length]
    b07b8:	cbz	x0, 0xb07e8
    b07bc:	mov	x0, x20
    b07c0:	bl	0x2ec910 ; symbol stub for: _CGSizeFromString
    b07c4:	mov.16b	v8, v0
    b07c8:	mov.16b	v9, v1
    b07cc:	mov	x8, #0x4059000000000000
    b07d0:	fmov	d0, x8
    b07d4:	fcmp	d8, d0
    b07d8:	mov	x8, #0x4059000000000000
    b07dc:	fmov	d0, x8
    b07e0:	fccmp	d1, d0, #0x4, gt
    b07e4:	b.gt	0xb0924
    b07e8:	mov	x0, x20
    b07ec:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b07f0:	adrp	x8, 718 ; 0x37e000
    b07f4:	ldr	x1, [x8, #0x4b8] ; Objc selector ref: carPlayWindowScene
    b07f8:	mov	x0, x19
    b07fc:	bl	0x2ecd00 ; Objc message: -[x0 carPlayWindowScene]
    b0800:	mov	x29, x29
    b0804:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b0808:	mov	x20, x0
    b080c:	cbz	x0, 0xb08b8
    b0810:	adrp	x8, 718 ; 0x37e000
    b0814:	ldr	x21, [x8, #0x4c0] ; Objc selector ref: coordinateSpace
    b0818:	adrp	x8, 717 ; 0x37d000
    b081c:	ldr	x1, [x8, #0x5d8] ; Objc selector ref: respondsToSelector:
    b0820:	mov	x0, x20
    b0824:	mov	x2, x21
    b0828:	bl	0x2ecd00 ; Objc message: -[x0 respondsToSelector:]
    b082c:	cbz	w0, 0xb08b8
    b0830:	mov	x0, x20
    b0834:	mov	x1, x21
    b0838:	bl	0x2ecd00 ; Objc message: -[x0 respondsToSelector:]
    b083c:	mov	x29, x29
    b0840:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b0844:	mov	x21, x0
    b0848:	adrp	x8, 717 ; 0x37d000
    b084c:	ldr	x1, [x8, #0x9b0] ; Objc selector ref: bounds
    b0850:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    b0854:	mov.16b	v10, v0
    b0858:	mov.16b	v11, v1
    b085c:	mov.16b	v8, v2
    b0860:	mov.16b	v9, v3
    b0864:	mov	x0, x21
    b0868:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b086c:	mov	x8, #0x4059000000000000
    b0870:	fmov	d0, x8
    b0874:	fcmp	d8, d0
    b0878:	b.le	0xb08b8
    b087c:	mov	x8, #0x4059000000000000
    b0880:	fmov	d0, x8
    b0884:	fcmp	d9, d0
    b0888:	b.le	0xb08b8
    b088c:	adrp	x8, 721 ; 0x381000
    b0890:	add	x8, x8, #0x570
    b0894:	stp	d10, d11, [x8]
    b0898:	stp	d8, d9, [x8, #0x10]
    b089c:	mov	x0, x20
    b08a0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b08a4:	b	0xb0b20
    b08a8:	adrp	x8, 721 ; 0x381000
    b08ac:	add	x8, x8, #0x570
    b08b0:	ldp	d10, d11, [x8]
    b08b4:	b	0xb0b20
    b08b8:	mov	x0, x20
    b08bc:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b08c0:	adrp	x8, 718 ; 0x37e000
    b08c4:	ldr	x1, [x8, #0x450] ; Objc selector ref: carPlayUIScreen
    b08c8:	mov	x0, x19
    b08cc:	bl	0x2ecd00 ; Objc message: -[x0 carPlayUIScreen]
    b08d0:	mov	x29, x29
    b08d4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b08d8:	mov	x20, x0
    b08dc:	cbz	x0, 0xb0940
    b08e0:	adrp	x8, 717 ; 0x37d000
    b08e4:	ldr	x21, [x8, #0x9b0] ; Objc selector ref: bounds
    b08e8:	mov	x0, x20
    b08ec:	mov	x1, x21
    b08f0:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    b08f4:	mov	x8, #0x4059000000000000
    b08f8:	fmov	d0, x8
    b08fc:	fcmp	d2, d0
    b0900:	b.le	0xb0940
    b0904:	mov	x0, x20
    b0908:	mov	x1, x21
    b090c:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    b0910:	mov.16b	v8, v2
    b0914:	mov	x0, x20
    b0918:	mov	x1, x21
    b091c:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    b0920:	mov.16b	v9, v3
    b0924:	adrp	x8, 721 ; 0x381000
    b0928:	add	x8, x8, #0x570
    b092c:	stp	xzr, xzr, [x8]
    b0930:	stp	d8, d9, [x8, #0x10]
    b0934:	mov	x0, x20
    b0938:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b093c:	b	0xb0b18
    b0940:	mov	x0, x20
    b0944:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b0948:	adrp	x8, 718 ; 0x37e000
    b094c:	ldr	x1, [x8, #0x4a8] ; Objc selector ref: carPlayCADisplay
    b0950:	mov	x0, x19
    b0954:	bl	0x2ecd00 ; Objc message: -[x0 carPlayCADisplay]
    b0958:	mov	x29, x29
    b095c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b0960:	mov	x19, x0
    b0964:	cbz	x0, 0xb0a3c
    b0968:	adrp	x8, 717 ; 0x37d000
    b096c:	ldr	x2, [x8, #0x9b0] ; Objc selector ref: bounds
    b0970:	nop
    b0974:	ldr	x20, [x8, #0x5d8]
    b0978:	mov	x0, x19
    b097c:	mov	x1, x20
    b0980:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    b0984:	cbz	w0, 0xb0a3c
    b0988:	adrp	x0, 601 ; 0x309000
    b098c:	add	x0, x0, #0x24a ; literal pool for: "bounds"
    b0990:	bl	0x2ecdfc ; symbol stub for: _sel_registerName
    b0994:	mov	x1, x0
    b0998:	mov	x0, x19
    b099c:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    b09a0:	mov.16b	v8, v2
    b09a4:	mov	x8, #0x4059000000000000
    b09a8:	fmov	d0, x8
    b09ac:	fcmp	d2, d0
    b09b0:	b.le	0xb0a3c
    b09b4:	mov.16b	v9, v3
    b09b8:	mov	x8, #0x4059000000000000
    b09bc:	fmov	d0, x8
    b09c0:	fcmp	d3, d0
    b09c4:	b.le	0xb0a3c
    b09c8:	adrp	x8, 718 ; 0x37e000
    b09cc:	ldr	x2, [x8, #0x4b0] ; Objc selector ref: pointScale
    b09d0:	mov	x0, x19
    b09d4:	mov	x1, x20
    b09d8:	bl	0x2ecd00 ; Objc message: -[x0 pointScale]
    b09dc:	cbz	w0, 0xb0a24
    b09e0:	adrp	x0, 601 ; 0x309000
    b09e4:	add	x0, x0, #0x139 ; literal pool for: "pointScale"
    b09e8:	bl	0x2ecdfc ; symbol stub for: _sel_registerName
    b09ec:	mov	x1, x0
    b09f0:	mov	x0, x19
    b09f4:	bl	0x2ecd00 ; Objc message: -[x0 pointScale]
    b09f8:	fmov	d1, #1.00000000
    b09fc:	fcmp	d0, d1
    b0a00:	b.le	0xb0a24
    b0a04:	fdiv	d1, d8, d0
    b0a08:	fcvt	s1, d1
    b0a0c:	frinta	s1, s1
    b0a10:	fcvt	d8, s1
    b0a14:	fdiv	d0, d9, d0
    b0a18:	fcvt	s0, d0
    b0a1c:	frinta	s0, s0
    b0a20:	fcvt	d9, s0
    b0a24:	adrp	x8, 721 ; 0x381000
    b0a28:	add	x8, x8, #0x570
    b0a2c:	stp	xzr, xzr, [x8]
    b0a30:	stp	d8, d9, [x8, #0x10]
    b0a34:	mov	x0, x19
    b0a38:	b	0xb0938
    b0a3c:	mov	x0, x19
    b0a40:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b0a44:	adrp	x22, 719 ; 0x37f000
    b0a48:	ldr	x0, [x22, #0x800] ; Objc class ref: _OBJC_CLASS_$_UIScreen
    b0a4c:	adrp	x8, 717 ; 0x37d000
    b0a50:	ldr	x19, [x8, #0x998] ; Objc selector ref: mainScreen
    b0a54:	mov	x1, x19
    b0a58:	bl	0x2ecd00 ; Objc message: +[UIScreen mainScreen]
    b0a5c:	mov	x29, x29
    b0a60:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b0a64:	mov	x21, x0
    b0a68:	adrp	x8, 717 ; 0x37d000
    b0a6c:	ldr	x20, [x8, #0x9b0] ; Objc selector ref: bounds
    b0a70:	mov	x1, x20
    b0a74:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    b0a78:	mov.16b	v8, v2
    b0a7c:	mov	x0, x21
    b0a80:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b0a84:	ldr	x0, [x22, #0x800]
    b0a88:	mov	x1, x19
    b0a8c:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    b0a90:	mov	x29, x29
    b0a94:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b0a98:	mov	x21, x0
    b0a9c:	mov	x1, x20
    b0aa0:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    b0aa4:	mov.16b	v9, v3
    b0aa8:	mov	x0, x21
    b0aac:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b0ab0:	fcmp	d8, d9
    b0ab4:	fcsel	d8, d9, d8, mi
    b0ab8:	ldr	x0, [x22, #0x800]
    b0abc:	mov	x1, x19
    b0ac0:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    b0ac4:	mov	x29, x29
    b0ac8:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b0acc:	mov	x21, x0
    b0ad0:	mov	x1, x20
    b0ad4:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    b0ad8:	mov.16b	v9, v2
    b0adc:	mov	x0, x21
    b0ae0:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b0ae4:	ldr	x0, [x22, #0x800]
    b0ae8:	mov	x1, x19
    b0aec:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    b0af0:	mov	x29, x29
    b0af4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b0af8:	mov	x19, x0
    b0afc:	mov	x1, x20
    b0b00:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    b0b04:	mov.16b	v10, v3
    b0b08:	mov	x0, x19
    b0b0c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b0b10:	fcmp	d9, d10
    b0b14:	fcsel	d9, d9, d10, mi
    b0b18:	fmov	d10, xzr
    b0b1c:	fmov	d11, xzr
    b0b20:	mov.16b	v0, v10
    b0b24:	mov.16b	v1, v11
    b0b28:	mov.16b	v2, v8
    b0b2c:	mov.16b	v3, v9
    b0b30:	ldp	x29, x30, [sp, #0x50]
    b0b34:	ldp	x20, x19, [sp, #0x40]
    b0b38:	ldp	x22, x21, [sp, #0x30]
    b0b3c:	ldp	d9, d8, [sp, #0x20]
    b0b40:	ldp	d11, d10, [sp, #0x10]
    b0b44:	add	sp, sp, #0x60
    b0b48:	ret
    b0b4c:	adrp	x0, 721 ; 0x381000
    b0b50:	add	x0, x0, #0x5c8
    b0b54:	adrp	x1, 660 ; 0x344000
    b0b58:	add	x1, x1, #0xf28
    b0b5c:	bl	0x2ecb38 ; symbol stub for: _dispatch_once
    b0b60:	b	0xb0764
- Truncated; see full JSON

## CBWindow.carPlayUIScreen 0xafe60..0xafffc
Original instructions=103
    afe60:	sub	sp, sp, #0x140
    afe64:	stp	x28, x27, [sp, #0xe0]
    afe68:	stp	x26, x25, [sp, #0xf0]
    afe6c:	stp	x24, x23, [sp, #0x100]
    afe70:	stp	x22, x21, [sp, #0x110]
    afe74:	stp	x20, x19, [sp, #0x120]
    afe78:	stp	x29, x30, [sp, #0x130]
    afe7c:	add	x29, sp, #0x130
    afe80:	adrp	x8, 661 ; 0x344000
    afe84:	ldr	x8, [x8, #0x140] ; literal pool symbol address: ___stack_chk_guard
    afe88:	ldr	x8, [x8]
    afe8c:	stur	x8, [x29, #-0x60]
    afe90:	movi.16b	v0, #0x0
    afe94:	stp	q0, q0, [sp, #0x10]
    afe98:	stp	q0, q0, [sp, #0x30]
    afe9c:	adrp	x26, 720 ; 0x37f000
    afea0:	ldr	x0, [x26, #0x800] ; Objc class ref: _OBJC_CLASS_$_UIScreen
    afea4:	adrp	x8, 718 ; 0x37d000
    afea8:	ldr	x1, [x8, #0x9a0] ; Objc selector ref: screens
    afeac:	bl	0x2ecd00 ; Objc message: +[UIScreen screens]
    afeb0:	mov	x29, x29
    afeb4:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    afeb8:	mov	x19, x0
    afebc:	adrp	x8, 718 ; 0x37d000
    afec0:	ldr	x1, [x8, #0x898] ; Objc selector ref: countByEnumeratingWithState:objects:count:
    afec4:	add	x2, sp, #0x10
    afec8:	add	x3, sp, #0x50
    afecc:	str	x1, [sp, #0x8]
    afed0:	mov	w4, #0x10
    afed4:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    afed8:	cbz	x0, 0xaffa0
    afedc:	ldr	x8, [sp, #0x20]
    afee0:	ldr	x27, [x8]
    afee4:	adrp	x8, 718 ; 0x37d000
    afee8:	adrp	x9, 718 ; 0x37d000
    afeec:	mov	x20, #0x0
    afef0:	ldr	x21, [x8, #0x998]
    afef4:	ldr	x22, [x9, #0xc60]
    afef8:	cmp	x0, #0x1
    afefc:	csinc	x28, x0, xzr, hi
    aff00:	ldr	x8, [sp, #0x20]
    aff04:	ldr	x8, [x8]
    aff08:	cmp	x8, x27
    aff0c:	b.eq	0xaff18
    aff10:	mov	x0, x19
    aff14:	bl	0x2eccb8 ; symbol stub for: _objc_enumerationMutation
    aff18:	ldr	x8, [sp, #0x18]
    aff1c:	ldr	x23, [x8, x20, lsl #3]
    aff20:	ldr	x0, [x26, #0x800]
    aff24:	mov	x1, x21
    aff28:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    aff2c:	mov	x29, x29
    aff30:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    aff34:	mov	x24, x0
    aff38:	cmp	x0, x23
    aff3c:	b.eq	0xaff68
    aff40:	adrp	x8, 720 ; 0x37f000
    aff44:	ldr	x0, [x8, #0x898] ; Objc class ref: CBLicenseSyncManager
    aff48:	mov	x1, x22
    aff4c:	mov	x2, x23
    aff50:	bl	0x2ecd00 ; Objc message: +[CBLicenseSyncManager countByEnumeratingWithState:objects:count:]
    aff54:	mov	x25, x0
    aff58:	mov	x0, x24
    aff5c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    aff60:	tbz	w25, #0x0, 0xaff70
    aff64:	b	0xaffa8
    aff68:	mov	x0, x24
    aff6c:	bl	0x2ecd30 ; symbol stub for: _objc_release
    aff70:	add	x20, x20, #0x1
    aff74:	cmp	x28, x20
    aff78:	b.ne	0xaff00
    aff7c:	add	x2, sp, #0x10
    aff80:	add	x3, sp, #0x50
    aff84:	mov	x0, x19
    aff88:	ldr	x1, [sp, #0x8]
    aff8c:	mov	w4, #0x10
    aff90:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    aff94:	adrp	x8, 718 ; 0x37d000
    aff98:	adrp	x9, 718 ; 0x37d000
    aff9c:	cbnz	x0, 0xafeec
    affa0:	mov	x20, #0x0
    affa4:	b	0xaffb4
    affa8:	mov	x0, x23
    affac:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    affb0:	mov	x20, x0
    affb4:	mov	x0, x19
    affb8:	bl	0x2ecd30 ; symbol stub for: _objc_release
    affbc:	ldur	x8, [x29, #-0x60]
    affc0:	adrp	x9, 661 ; 0x344000
    affc4:	ldr	x9, [x9, #0x140] ; literal pool symbol address: ___stack_chk_guard
    affc8:	ldr	x9, [x9]
    affcc:	cmp	x9, x8
    affd0:	b.ne	0xafff8
    affd4:	mov	x0, x20
    affd8:	ldp	x29, x30, [sp, #0x130]
    affdc:	ldp	x20, x19, [sp, #0x120]
    affe0:	ldp	x22, x21, [sp, #0x110]
    affe4:	ldp	x24, x23, [sp, #0x100]
    affe8:	ldp	x26, x25, [sp, #0xf0]
    affec:	ldp	x28, x27, [sp, #0xe0]
    afff0:	add	sp, sp, #0x140
    afff4:	b	0x2ecc7c ; symbol stub for: _objc_autoreleaseReturnValue
    afff8:	bl	0x2eca9c ; symbol stub for: ___stack_chk_fail

## CBWindow.carPlayCADisplay 0xafffc..0xb059c
Original instructions=360
    b0030:	ldr	x1, [x8, #0x450] ; Objc selector ref: carPlayUIScreen
    b0034:	bl	0x2ecd00 ; Objc message: -[x0 carPlayUIScreen]
    b0050:	ldr	x20, [x8, #0xc48] ; Objc selector ref: displayConfiguration
    b0064:	bl	0x2ecd00 ; Objc message: -[x0 displayConfiguration]
    b0074:	bl	0x2ecd00 ; Objc message: -[x0 displayConfiguration]
    b008c:	ldr	x22, [x8, #0xc50] ; Objc selector ref: CADisplay
    b009c:	bl	0x2ecd00 ; Objc message: -[x0 CADisplay]
    b00ac:	bl	0x2ecd00 ; Objc message: -[x0 CADisplay]
    b00f4:	ldr	x22, [x8, #0x478] ; Objc selector ref: currentCarPlayExternalDevice
    b0108:	bl	0x2ecd00 ; Objc message: -[x0 currentCarPlayExternalDevice]
    b0118:	bl	0x2ecd00 ; Objc message: -[x0 currentCarPlayExternalDevice]
    b0130:	ldr	x22, [x8, #0x480] ; Objc selector ref: screenIDs
    b0140:	bl	0x2ecd00 ; Objc message: -[x0 screenIDs]
    b0150:	bl	0x2ecd00 ; Objc message: -[x0 screenIDs]
    b0170:	ldr	x1, [x8, #0x610] ; Objc selector ref: class
    b0174:	bl	0x2ecd00 ; Objc message: +[NSArray class]
    b0180:	ldr	x1, [x8, #0x618] ; Objc selector ref: isKindOfClass:
    b0188:	bl	0x2ecd00 ; Objc message: -[x0 isKindOfClass:]
    b0194:	ldr	x1, [x8, #0x620] ; Objc selector ref: count
    b019c:	bl	0x2ecd00 ; Objc message: -[x0 count]
    b01a8:	ldr	x1, [x8, #0x8b8] ; Objc selector ref: objectAtIndexedSubscript:
    b01b4:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    b01dc:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    b0200:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    b0278:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    b0288:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    b02a8:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    b02b8:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    b02cc:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    b02e8:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    b0334:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    b0390:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    b03b4:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    b0418:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    b0430:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
    b045c:	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]

## CBWindow.getCarPlayDisplay 0xb0ff0..0xb1064
Original instructions=29
    b0ff0:	stp	x20, x19, [sp, #-0x20]!
    b0ff4:	stp	x29, x30, [sp, #0x10]
    b0ff8:	add	x29, sp, #0x10
    b0ffc:	adrp	x8, 719 ; 0x37f000
    b1000:	ldr	x0, [x8, #0x910] ; Objc class ref: CBWindow
    b1004:	adrp	x8, 717 ; 0x37e000
    b1008:	ldr	x1, [x8, #0x4a8] ; Objc selector ref: carPlayCADisplay
    b100c:	bl	0x2ecd00 ; Objc message: +[CBWindow carPlayCADisplay]
    b1010:	mov	x29, x29
    b1014:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b1018:	mov	x19, x0
    b101c:	cbz	x0, 0xb102c
    b1020:	mov	x0, x19
    b1024:	bl	0x2ecd3c ; symbol stub for: _objc_retain
    b1028:	b	0xb1048
    b102c:	adrp	x8, 718 ; 0x37f000
    b1030:	ldr	x0, [x8, #0x928] ; Objc class ref: _OBJC_CLASS_$_CADisplay
    b1034:	adrp	x8, 717 ; 0x37e000
    b1038:	ldr	x1, [x8, #0x4f0] ; Objc selector ref: mainDisplay
    b103c:	bl	0x2ecd00 ; Objc message: +[CADisplay mainDisplay]
    b1040:	mov	x29, x29
    b1044:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    b1048:	mov	x20, x0
    b104c:	mov	x0, x19
    b1050:	bl	0x2ecd30 ; symbol stub for: _objc_release
    b1054:	mov	x0, x20
    b1058:	ldp	x29, x30, [sp, #0x10]
    b105c:	ldp	x20, x19, [sp], #0x20
    b1060:	b	0x2ecc7c ; symbol stub for: _objc_autoreleaseReturnValue

## CBWindow.resetCachedBounds 0xaf570..0xaf690
Original instructions=72
    af570:	stp	x22, x21, [sp, #-0x30]!
    af574:	stp	x20, x19, [sp, #0x10]
    af578:	stp	x29, x30, [sp, #0x20]
    af57c:	add	x29, sp, #0x20
    af580:	adrp	x8, 661 ; 0x344000
    af584:	ldr	x8, [x8, #0x20] ; literal pool symbol address: _CGRectZero
    af588:	adrp	x9, 722 ; 0x381000
    af58c:	add	x9, x9, #0x570
    af590:	ldp	q0, q1, [x8]
    af594:	stp	q0, q1, [x9]
    af598:	adrp	x8, 661 ; 0x344000
    af59c:	ldr	x8, [x8, #0xb0] ; literal pool symbol address: _UIEdgeInsetsZero
    af5a0:	adrp	x9, 722 ; 0x381000
    af5a4:	add	x9, x9, #0x590
    af5a8:	ldp	q0, q1, [x8]
    af5ac:	stp	q0, q1, [x9]
    af5b0:	adrp	x22, 720 ; 0x37f000
    af5b4:	ldr	x0, [x22, #0x718] ; Objc class ref: _OBJC_CLASS_$_NSFileManager
    af5b8:	adrp	x8, 718 ; 0x37d000
    af5bc:	ldr	x19, [x8, #0x4a0] ; Objc selector ref: defaultManager
    af5c0:	mov	x1, x19
    af5c4:	bl	0x2ecd00 ; Objc message: +[NSFileManager defaultManager]
    af5c8:	mov	x29, x29
    af5cc:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    af5d0:	mov	x21, x0
    af5d4:	adrp	x8, 722 ; 0x381000
    af5d8:	ldr	x8, [x8, #0x5b8]
    af5dc:	cmn	x8, #0x1
    af5e0:	b.ne	0xaf660
    af5e4:	adrp	x8, 722 ; 0x381000
    af5e8:	ldr	x2, [x8, #0x5b0]
    af5ec:	adrp	x8, 718 ; 0x37d000
    af5f0:	ldr	x20, [x8, #0xd28] ; Objc selector ref: removeItemAtPath:error:
    af5f4:	mov	x0, x21
    af5f8:	mov	x1, x20
    af5fc:	mov	x3, #0x0
    af600:	bl	0x2ecd00 ; Objc message: -[x0 removeItemAtPath:error:]
    af604:	mov	x0, x21
    af608:	bl	0x2ecd30 ; symbol stub for: _objc_release
    af60c:	ldr	x0, [x22, #0x718]
    af610:	mov	x1, x19
    af614:	bl	0x2ecd00 ; Objc message: -[x0 removeItemAtPath:error:]
    af618:	mov	x29, x29
    af61c:	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
    af620:	mov	x19, x0
    af624:	adrp	x8, 722 ; 0x381000
    af628:	ldr	x8, [x8, #0x5c8]
    af62c:	cmn	x8, #0x1
    af630:	b.ne	0xaf678
    af634:	adrp	x8, 722 ; 0x381000
    af638:	ldr	x2, [x8, #0x5c0]
    af63c:	mov	x0, x19
    af640:	mov	x1, x20
    af644:	mov	x3, #0x0
    af648:	bl	0x2ecd00 ; Objc message: -[x0 removeItemAtPath:error:]
    af64c:	mov	x0, x19
    af650:	ldp	x29, x30, [sp, #0x20]
    af654:	ldp	x20, x19, [sp, #0x10]
    af658:	ldp	x22, x21, [sp], #0x30
    af65c:	b	0x2ecd30 ; symbol stub for: _objc_release
    af660:	adrp	x0, 722 ; 0x381000
    af664:	add	x0, x0, #0x5b8
    af668:	adrp	x1, 661 ; 0x344000
    af66c:	add	x1, x1, #0xf08
    af670:	bl	0x2ecb38 ; symbol stub for: _dispatch_once
    af674:	b	0xaf5e4
    af678:	adrp	x0, 722 ; 0x381000
    af67c:	add	x0, x0, #0x5c8
    af680:	adrp	x1, 661 ; 0x344000
    af684:	add	x1, x1, #0xf28
    af688:	bl	0x2ecb38 ; symbol stub for: _dispatch_once
    af68c:	b	0xaf634

## CBWindow.initWithAppFrame: 0xaf4bc..0xaf554
Original instructions=38
    af4f4:	ldr	x1, [x8, #0x530] ; Objc selector ref: init
    af4fc:	bl	0x2ecd18 ; Objc message: -[[x0 super] init]
    af51c:	ldr	x1, [x8, #0x440] ; Objc selector ref: createWindows
    af524:	bl	0x2ecd00 ; Objc message: -[x0 createWindows]
    af52c:	ldr	x1, [x8, #0x448] ; Objc selector ref: resizeWindows
    af534:	bl	0x2ecd00 ; Objc message: -[x0 resizeWindows]

## CBWindow.createWindows 0xb1064..0xb1974
Original instructions=580
    b10a4:	ldr	x1, [x8, #0x4b8] ; Objc selector ref: carPlayWindowScene
    b10a8:	bl	0x2ecd00 ; Objc message: +[CBWindow carPlayWindowScene]
    b10c0:	ldr	x1, [x8, #0x450] ; Objc selector ref: carPlayUIScreen
    b10c4:	bl	0x2ecd00 ; Objc message: -[x0 carPlayUIScreen]
    b10e8:	ldr	x22, [x8, #0x460] ; Objc selector ref: screen
    b10f8:	bl	0x2ecd00 ; Objc message: -[x0 screen]
    b1108:	bl	0x2ecd00 ; Objc message: -[x0 screen]
    b1134:	ldr	x1, [x8, #0x4a8] ; Objc selector ref: carPlayCADisplay
    b1138:	bl	0x2ecd00 ; Objc message: -[x0 carPlayCADisplay]
    b1160:	ldr	x23, [x8, #0xc48] ; Objc selector ref: displayConfiguration
    b1170:	bl	0x2ecd00 ; Objc message: -[x0 displayConfiguration]
    b1180:	bl	0x2ecd00 ; Objc message: -[x0 displayConfiguration]
    b11a8:	ldr	x24, [x8, #0x4f8] ; Objc selector ref: _FBSScene
    b11bc:	bl	0x2ecd00 ; Objc message: -[x0 _FBSScene]
    b11c8:	ldr	x23, [x8, #0xfc8] ; Objc selector ref: performSelector:
    b11d8:	bl	0x2ecd00 ; Objc message: -[x0 performSelector:]
    b11f0:	ldr	x26, [x8, #0x500] ; Objc selector ref: settings
    b1200:	bl	0x2ecd00 ; Objc message: -[x0 settings]
    b1214:	bl	0x2ecd00 ; Objc message: -[x0 settings]
    b122c:	ldr	x22, [x8, #0xc48] ; Objc selector ref: displayConfiguration
    b123c:	bl	0x2ecd00 ; Objc message: -[x0 displayConfiguration]
    b1250:	bl	0x2ecd00 ; Objc message: -[x0 displayConfiguration]
    b12ac:	ldr	x1, [x8, #0x508] ; Objc selector ref: initWithCADisplay:isMainDisplay:
    b12b8:	bl	0x2ecd00 ; Objc message: -[x0 initWithCADisplay:isMainDisplay:]
    b1340:	ldr	x26, [x8, #0x2c8] ; Objc selector ref: hitTest:withEvent:
    b1388:	ldr	x26, [x8, #0x5a8] ; Objc selector ref: pointInside:withEvent:
    b13c8:	ldr	x26, [x8, #0x5b0] ; Objc selector ref: sendEvent:
    b1428:	ldr	x25, [x8, #0x510] ; Objc selector ref: initWithDisplayConfiguration:
    b1438:	bl	0x2ecd00 ; Objc message: -[x0 initWithDisplayConfiguration:]
    b145c:	ldr	x25, [x8, #0x518] ; Objc selector ref: initWithWindowScene:
    b146c:	bl	0x2ecd00 ; Objc message: -[x0 initWithWindowScene:]
    b1484:	bl	0x2ecd00 ; Objc message: -[x0 initWithWindowScene:]
    b14a4:	ldr	x25, [x8, #0x520] ; Objc selector ref: initWithScreen:
    b14b4:	bl	0x2ecd00 ; Objc message: -[x0 initWithScreen:]
    b14cc:	bl	0x2ecd00 ; Objc message: -[x0 initWithScreen:]
    b14ec:	bl	0x2ecd00 ; Objc message: -[x0 initWithScreen:]
    b14f4:	ldr	x1, [x8, #0x9b8] ; Objc selector ref: initWithFrame:
    b14fc:	bl	0x2ecd00 ; Objc message: -[x0 initWithFrame:]
    b151c:	ldr	x24, [x8, #0x528] ; Objc selector ref: setWindowScene:
    b1528:	bl	0x2ecd00 ; Objc message: -[x0 setWindowScene:]
    b153c:	bl	0x2ecd00 ; Objc message: -[x0 setWindowScene:]
    b154c:	ldr	x25, [x8, #0x530] ; Objc selector ref: setScreen:
    b155c:	bl	0x2ecd00 ; Objc message: -[x0 setScreen:]
    b1570:	bl	0x2ecd00 ; Objc message: -[x0 setScreen:]
    b1584:	ldr	x25, [x8, #0x9c8] ; Objc selector ref: setWindowLevel:
    b1590:	bl	0x2ecd00 ; Objc message: -[x0 setWindowLevel:]
    b15a8:	bl	0x2ecd00 ; Objc message: -[x0 setWindowLevel:]
    b15b4:	bl	0x2ecd00 ; Objc message: -[x0 setWindowLevel:]
    b15d0:	ldr	x1, [x8, #0x320] ; Objc selector ref: carPlayUsableBounds
    b15d4:	bl	0x2ecd00 ; Objc message: -[x0 carPlayUsableBounds]
    b1600:	ldr	x24, [x8, #0xa10] ; Objc selector ref: setFrame:
    b1618:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    b1624:	ldr	x1, [x8, #0x980] ; Objc selector ref: setHidden:
    b162c:	bl	0x2ecd00 ; Objc message: -[x0 setHidden:]
    b163c:	ldr	x26, [x8, #0x9d0] ; Objc selector ref: clearColor
    b1644:	bl	0x2ecd00 ; Objc message: +[UIColor clearColor]
    b165c:	ldr	x27, [x8, #0x9d8] ; Objc selector ref: setBackgroundColor:
    b1668:	bl	0x2ecd00 ; Objc message: -[x0 setBackgroundColor:]
    b1698:	bl	0x2ecd00 ; Objc message: +[UIViewController setBackgroundColor:]
    b16b0:	ldr	x25, [x8, #0x2f0] ; Objc selector ref: view
    b16b8:	bl	0x2ecd00 ; Objc message: -[x0 view]
    b16d0:	bl	0x2ecd00 ; Objc message: -[x0 view]
    b16ec:	bl	0x2ecd00 ; Objc message: -[x0 view]
    b1710:	bl	0x2ecd00 ; Objc message: -[x0 view]
    b1724:	bl	0x2ecd00 ; Objc message: -[x0 view]
    b1738:	ldr	x28, [x8, #0xdc0] ; Objc selector ref: setAutoresizingMask:
    b1744:	bl	0x2ecd00 ; Objc message: -[x0 setAutoresizingMask:]
    b1758:	ldr	x1, [x8, #0x9c0] ; Objc selector ref: setRootViewController:
    b175c:	bl	0x2ecd00 ; Objc message: -[x0 setRootViewController:]
    b1770:	ldr	x1, [x8, #0xa08] ; Objc selector ref: initWithEffect:
    b1778:	bl	0x2ecd00 ; Objc message: +[UIVisualEffectView initWithEffect:]
    b1794:	bl	0x2ecd00 ; Objc message: -[x0 initWithEffect:]
    b17b0:	bl	0x2ecd00 ; Objc message: -[x0 initWithEffect:]
    b17d4:	bl	0x2ecd00 ; Objc message: -[x0 initWithEffect:]
    b17e4:	bl	0x2ecd00 ; Objc message: -[x0 initWithEffect:]
    b17f0:	ldr	x1, [x8, #0xdf8] ; Objc selector ref: setClipsToBounds:
    b17f8:	bl	0x2ecd00 ; Objc message: -[x0 setClipsToBounds:]
    b1804:	ldr	x1, [x8, #0xa18] ; Objc selector ref: layer
    b1808:	bl	0x2ecd00 ; Objc message: -[x0 layer]
    b181c:	ldr	x1, [x8, #0xa28] ; Objc selector ref: setMasksToBounds:
    b1824:	bl	0x2ecd00 ; Objc message: -[x0 setMasksToBounds:]
    b1838:	bl	0x2ecd00 ; Objc message: -[x0 setMasksToBounds:]
    b1850:	ldr	x1, [x8, #0xa80] ; Objc selector ref: addSubview:
    b1854:	bl	0x2ecd00 ; Objc message: -[x0 addSubview:]

## CBWindow.resizeWindows 0xb1aac..0xb1d98
Original instructions=187
    b1ae8:	ldr	x1, [x8, #0x4e0] ; Objc selector ref: carPlayScreenBounds
    b1aec:	bl	0x2ecd00 ; Objc message: +[CBWindow carPlayScreenBounds]
    b1b08:	ldr	x1, [x8, #0x320] ; Objc selector ref: carPlayUsableBounds
    b1b0c:	bl	0x2ecd00 ; Objc message: -[x0 carPlayUsableBounds]
    b1b4c:	bl	0x2ecd00 ; Objc message: -[x0 carPlayUsableBounds]
    b1b58:	bl	0x2ecd00 ; Objc message: -[x0 carPlayUsableBounds]
    b1b74:	bl	0x2ecd00 ; Objc message: -[x0 carPlayUsableBounds]
    b1b8c:	ldr	x20, [x8, #0x2f0] ; Objc selector ref: view
    b1b94:	bl	0x2ecd00 ; Objc message: -[x0 view]
    b1bb4:	bl	0x2ecd00 ; Objc message: -[x0 view]
    b1bd8:	bl	0x2ecd00 ; Objc message: -[x0 view]
    b1c00:	bl	0x2ecd00 ; Objc message: -[x0 view]
    b1c0c:	bl	0x2ecd00 ; Objc message: -[x0 view]
    b1c28:	bl	0x2ecd00 ; Objc message: -[x0 view]
    b1c3c:	ldr	x1, [x8, #0x548] ; Objc selector ref: setEffect:
    b1c44:	bl	0x2ecd00 ; Objc message: -[x0 setEffect:]
    b1c50:	ldr	x1, [x8, #0xdf8] ; Objc selector ref: setClipsToBounds:
    b1c58:	bl	0x2ecd00 ; Objc message: -[x0 setClipsToBounds:]
    b1c64:	ldr	x1, [x8, #0xa18] ; Objc selector ref: layer
    b1c68:	bl	0x2ecd00 ; Objc message: -[x0 layer]
    b1c7c:	ldr	x1, [x8, #0xa28] ; Objc selector ref: setMasksToBounds:
    b1c84:	bl	0x2ecd00 ; Objc message: -[x0 setMasksToBounds:]
    b1c9c:	ldr	x20, [x8, #0xe40] ; Objc selector ref: superview
    b1ca4:	bl	0x2ecd00 ; Objc message: -[x0 superview]
    b1cc4:	bl	0x2ecd00 ; Objc message: -[x0 superview]
    b1cd8:	ldr	x1, [x8, #0x9b0] ; Objc selector ref: bounds
    b1cdc:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    b1ce8:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    b1d0c:	bl	0x2ecd00 ; Objc message: -[x0 bounds]

## CBBridgedSplitApp.layoutSplitViews 0x1044f8..0x105890
Original instructions=1254
    104548:	ldr	x1, [x8, #0x320] ; Objc selector ref: carPlayUsableBounds
    10454c:	bl	0x2ecd00 ; Objc message: +[CBWindow carPlayUsableBounds]
    10455c:	ldr	x22, [x8, #0x2f0] ; Objc selector ref: view
    104568:	bl	0x2ecd00 ; Objc message: -[x0 view]
    10457c:	ldr	x23, [x8, #0x9b0] ; Objc selector ref: bounds
    104584:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    104598:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    1045ac:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    1045cc:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    1045e0:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    1045f4:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    104608:	bl	0x2ecd00 ; Objc message: -[x0 bounds]
    104638:	ldr	x1, [x8, #0x9e0] ; Objc selector ref: isDismissing
    10463c:	bl	0x2ecd00 ; Objc message: -[x0 isDismissing]
    104680:	bl	0x2ecd00 ; Objc message: -[x0 isDismissing]
    104694:	bl	0x2ecd00 ; Objc message: -[x0 isDismissing]
    1046a4:	ldr	x20, [x8, #0x8b8] ; Objc selector ref: objectAtIndexedSubscript:
    1046c0:	ldr	x8, [x8, #0x9e0] ; Objc selector ref: setUserInteractionEnabled:
    1046cc:	ldr	x9, [x8, #0x9e8] ; Objc selector ref: setAudioOnlyBackgroundMode:
    1046d4:	ldr	x8, [x8, #0xa10] ; Objc selector ref: setFrame:
    1046e0:	ldr	x10, [x8, #0xef8] ; Objc selector ref: setBounds:
    1046fc:	ldr	x8, [x8, #0xe88] ; Objc selector ref: setCornerCurve:
    104708:	ldr	x8, [x8, #0x5d8] ; Objc selector ref: respondsToSelector:
    104724:	ldr	x9, [x8, #0xa30] ; Objc selector ref: setBorderWidth:
    104738:	ldr	x9, [x8, #0xa40] ; Objc selector ref: CGColor
    10474c:	ldr	x9, [x8, #0xa28] ; Objc selector ref: setMasksToBounds:
    104754:	ldr	x8, [x8, #0x120] ; Objc selector ref: bringSubviewToFront:
    104760:	ldr	x8, [x8, #0x420] ; Objc selector ref: bundleIdentifier
    10476c:	ldr	x9, [x8, #0x568] ; Objc selector ref: length
    104774:	ldr	x8, [x8, #0x2c0] ; Objc selector ref: refreshSceneLayout
    104780:	ldr	x9, [x8, #0xf00] ; Objc selector ref: setNeedsLayout
    104794:	ldr	x9, [x8, #0x9f0] ; Objc selector ref: setFocusedMode:
    1047f4:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    10480c:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104824:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104844:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    10485c:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    10488c:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    10489c:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    1048ac:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    1048c8:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    1048e4:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    1048f0:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104908:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    10491c:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104934:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104950:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104968:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    10497c:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104994:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    1049bc:	bl	0x2ecd00 ; Objc message: +[UIColor setFocusedMode:]
    1049d4:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    1049e4:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    1049fc:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104a18:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104a30:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104a44:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104a5c:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104a78:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104a84:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104a90:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104aa0:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104abc:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104ad0:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104af8:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104b04:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104b14:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104b24:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104b34:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104b48:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104b5c:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104b6c:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104b88:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104b9c:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104bb8:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104bd0:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104bdc:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104be8:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104bf4:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104c08:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104c28:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104c38:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104c44:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104c54:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104c80:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104cb8:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104cc8:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104cd8:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104d00:	bl	0x2ecd00 ; Objc message: -[x0 setFocusedMode:]
    104d3c:	ldr	x21, [x8, #0x898] ; Objc selector ref: countByEnumeratingWithState:objects:count:
    104d50:	bl	0x2ecd00 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
    104d70:	ldr	x23, [x8, #0x980] ; Objc selector ref: setHidden:
    104da4:	bl	0x2ecd00 ; Objc message: -[x0 setHidden:]
    104db4:	bl	0x2ecd00 ; Objc message: -[x0 setHidden:]
    104dd8:	bl	0x2ecd00 ; Objc message: -[x0 setHidden:]
    104e0c:	bl	0x2ecd00 ; Objc message: -[x0 setHidden:]
    104e34:	ldr	x20, [x8, #0xbb8] ; Objc selector ref: array
    104e3c:	bl	0x2ecd00 ; Objc message: +[NSMutableArray array]
    104e54:	bl	0x2ecd00 ; Objc message: -[x0 array]
    104ea0:	bl	0x2ecd00 ; Objc message: -[x0 array]
    104ee4:	ldr	x8, [x8, #0x9e0] ; Objc selector ref: setUserInteractionEnabled:
    104ef0:	ldr	x10, [x8, #0xef8] ; Objc selector ref: setBounds:
    104f0c:	ldr	x8, [x8, #0xe88] ; Objc selector ref: setCornerCurve:
    104f18:	ldr	x8, [x8, #0x5d8] ; Objc selector ref: respondsToSelector:
    104f34:	ldr	x10, [x8, #0xa30] ; Objc selector ref: setBorderWidth:
    104f48:	ldr	x10, [x8, #0xa40] ; Objc selector ref: CGColor
    104f5c:	ldr	x8, [x8, #0xa28] ; Objc selector ref: setMasksToBounds:
    104f68:	ldr	x10, [x8, #0x9e8] ; Objc selector ref: setAudioOnlyBackgroundMode:
    104f70:	ldr	x8, [x8, #0x420] ; Objc selector ref: bundleIdentifier
    104f7c:	ldr	x10, [x8, #0x568] ; Objc selector ref: length
    104f84:	ldr	x8, [x8, #0x2b8] ; Objc selector ref: updateLayout
    104f90:	ldr	x10, [x8, #0xf00] ; Objc selector ref: setNeedsLayout
    104fa4:	ldr	x10, [x8, #0x810] ; Objc selector ref: setShowsExpandButton:
    104fb8:	ldr	x8, [x8, #0x960] ; Objc selector ref: setCompactMode:
    10500c:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105028:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    10503c:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105064:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105088:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    1050ac:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    1050c8:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    1050d8:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    1050e8:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105104:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105120:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    10512c:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105144:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105158:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105170:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    10518c:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    1051a4:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    1051b8:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    1051d0:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    1051f8:	bl	0x2ecd00 ; Objc message: +[UIColor setCompactMode:]
    105210:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105220:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105238:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105254:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    10526c:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105288:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105294:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    1052a0:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    1052b0:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    1052cc:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    1052e0:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105308:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105314:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105330:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105344:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    10535c:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105374:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105380:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    10538c:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105398:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    1053ac:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    1053f8:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105408:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105418:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105428:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105438:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105464:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    10549c:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    1054ac:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    1054bc:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    1054ec:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105510:	bl	0x2ecd00 ; Objc message: -[x0 setCompactMode:]
    105520:	ldr	x21, [x8, #0x8b8] ; Objc selector ref: objectAtIndexedSubscript:
    105534:	ldr	x23, [x8, #0xa10] ; Objc selector ref: setFrame:
    105558:	ldr	x26, [x8, #0x988] ; Objc selector ref: setAlpha:
    105560:	ldr	x8, [x8, #0x120] ; Objc selector ref: bringSubviewToFront:
    105570:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    105588:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    10559c:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    1055bc:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    1055e0:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    105600:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    10561c:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    105634:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    10564c:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    105664:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    105680:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    10569c:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    1056bc:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]
    1056f0:	ldr	x1, [x8, #0xe40] ; Objc selector ref: superview
    1056f4:	bl	0x2ecd00 ; Objc message: -[x0 superview]
    10570c:	bl	0x2ecd00 ; Objc message: -[x0 superview]
    105738:	ldr	x1, [x8, #0x560] ; Objc selector ref: frame
    10573c:	bl	0x2ecd00 ; Objc message: -[x0 frame]
    105758:	bl	0x2ecd00 ; Objc message: -[x0 frame]
    10576c:	bl	0x2ecd00 ; Objc message: -[x0 frame]
    1057ac:	bl	0x2ecd00 ; Objc message: -[x0 frame]
    1057c0:	bl	0x2ecd00 ; Objc message: -[x0 frame]
    1057cc:	ldr	x1, [x8, #0xa10] ; Objc selector ref: setFrame:
    1057d0:	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
    1057e4:	ldr	x1, [x8, #0xa18] ; Objc selector ref: layer
    1057e8:	bl	0x2ecd00 ; Objc message: -[x0 layer]
    1057fc:	ldr	x1, [x8, #0x990] ; Objc selector ref: setZPosition:
    105808:	bl	0x2ecd00 ; Objc message: -[x0 setZPosition:]
    10581c:	bl	0x2ecd00 ; Objc message: -[x0 setZPosition:]
    105834:	ldr	x1, [x8, #0x120] ; Objc selector ref: bringSubviewToFront:
    105838:	bl	0x2ecd00 ; Objc message: -[x0 bringSubviewToFront:]

