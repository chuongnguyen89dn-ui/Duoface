# Targeted call-origin audit for Airaw 0x45D20 and 0x45B50

Scope limited to these two function entrypoints and their invocation/registration, not package-wide keyword scans.

Evidence: uploaded Airaw 1.7.1k arm64 dylib, `/mnt/data/airaw_full_disasm.txt`, Mach-O `__TEXT,__objc_methlist` section.

1. `0x45D20` takes a nullable second argument, sets `isFull=YES`, saves the view's current frame in `savedRect`, zeroes target edge insets, then calls `setDefaultAppChromeHidden:YES`. Its final call is a **tail branch** (`b 0x4eac0` at `0x45d88`), not a conventional `bl`. This distinction matters for tracing.
2. `0x45B50` restores `CGAffineTransformIdentity`, restores `savedRect` through `setFrame:`, and calls `setDefaultAppChromeHidden:NO`.
3. Exact direct `bl` and `b` caller search returned no references to either entrypoint in the disassembled text.
4. **New targeted metadata test:** scanned every aligned 4-byte word in the actual arm64 `__TEXT,__objc_methlist` section, VM `0x52848–0x56710`, for signed relative IMP offsets satisfying `entry_address + offset == 0x45D20` or `0x45B50`. **Zero matches for both**. This rules out direct relative IMP references in this specific section, but not chained fixups, method lists elsewhere, block callback descriptors or dynamic registrations.
5. The adjacent methods at `0x45D98`, `0x45DE8`, `0x45DF0` use the same state-object pattern; `0x45DE8` branches into previously excluded native-split geometry. Do not conflate this adjacent method with fullscreen.

Next focused step: decode method/block callback registration and chained fixups for these two IMPs; identify their caller/owner before altering DuoFace v12. No DEB built or device tested.
