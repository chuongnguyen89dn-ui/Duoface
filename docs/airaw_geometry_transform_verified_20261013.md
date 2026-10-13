# Airaw: verified host-view geometry transformation path

Evidence: arm64 disassembly of the user-uploaded `Airaw.dylib` at `/mnt/data/airaw_full_disasm.txt`. Addresses below are VM offsets within that slice.

**New result beyond notification analysis:** `0x43b04` is a layout wrapper which calls its saved original, checks a condition via `0x4b2c0`, and branches at `0x43b38` to **`0x45254`**. Another path at `0x44b2c` calls `0x45254` after setting several values and a boolean. Thus `0x45254` is not an orphan helper.

`0x45254` reads a rectangle (`0x45290`), validates positive width/height (`0x45294`, `0x452a0`), reads horizontal and vertical offsets (`0x452b8`, `0x452c4`), reads scaling conditions, and constructs a CoreGraphics transform. It calls `CGAffineTransformMakeTranslation` at `0x45390` and `0x4542c`, and `CGAffineTransformScale` at `0x45450`. The transformed geometry is applied through the selector stub **`0x50fe0`** at `0x45320` and `0x45488`; a rectangle is sent through `0x4e680` at `0x45360` and `0x453f8`.

This is **confirmed transform/geometry logic**, unlike the previously traced notification receiver. However, the exact class, Objective-C selectors for the stubs, and whether this branch corresponds to *whole-host fullscreen* rather than split/layout scaling are not yet resolved. It must not be copied into v12 without verifying those bindings and runtime geometry.

No code change to original v12, no fullscreen build, no CarPlay device test. Next resolve selectors at `0x50fe0`, `0x4e680`, `0x4b2c0`, then trace the controlling state to the host fullscreen toggle.
