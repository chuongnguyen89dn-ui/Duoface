# Airaw fullscreen callback registration: actual indirect caller located

Input: uploaded Airaw 1.7.1k arm64 dylib, `llvm-objdump --macho --arch=arm64 --disassemble`. Verified against `/mnt/data/airaw_full_disasm.txt`.

**Breakthrough:** Both targets are registered as **stack block invoke functions** using `adrp/add`, not stored as direct pointers or Objective-C method IMPs. This explains why direct `bl`, 64-bit pointer and relative Objective-C method scans all failed.

### Exit callback `0x45B50`
At `0x4440c–0x44420`, `adrp x8, 0x45000; add x8,x8,#0xb50` constructs callback `0x45B50` and stores it at `[sp+0x10]` with a block descriptor at `[sp+0x18]`. Another stack block is constructed at `0x443d8–0x44404` with invoke function `0x45B00`. At `0x44424–0x44430`, both blocks are passed to **`0x45728`** (`x0=x19`, `x1=sp+0x28`, `x2=sp`).

### Entry callback `0x45D20`
At `0x446b4–0x446c8`, `adrp x9,0x45000; add x9,x9,#0xd20` constructs callback `0x45D20`, stores it at `[sp+0x40]` with descriptor `[sp+0x48]`. The paired callback `0x45D90` is stored at `[sp+0x18]` at `0x446d0–0x446e4`. At `0x446e8–0x446f4`, both blocks are passed to the **same `0x45728`** (`x0=x19`, `x1=sp+0x30`, `x2=sp+0x8`).

### Common dispatcher `0x45728`
Checks target responds to selectors (`objc_opt_respondsToSelector` at `0x45760` and `0x45780`). One branch obtains a view and calls an Objective-C stub `0x4ce00` with a stack block in `x3` (`0x457b8–0x457c4`). Another branch calls stub `0x52300` at `0x4583c`. Callback cleanup starts `0x45840`. Resolve selector names of these two stubs to identify animation/transition behavior and the host receiver.

**Scope:** This establishes the missing indirect callback registration for both entry and exit. It does not yet establish the button event that reaches the registration methods or runtime fullscreen correctness. No changes to DuoFace v12 or DEB build.
