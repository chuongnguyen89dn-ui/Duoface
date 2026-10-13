# Airaw fullscreen: verified pre-dispatch input gates

Scope: only the previously found block-registration methods feeding fullscreen callbacks 0x45B50 (exit) and 0x45D20 (entry). Arm64 disassembly of user-provided Airaw 1.7.1k.

**Exit path**: `0x4438c` is the function constructing the block invoking `0x45B50`; its entry calls condition helper `0x4b2c0` at `0x443a0`, optionally performs a preliminary action (`0x443b8`), sets scalar property via `0x50140` and inset-like property via `0x50160`, then creates two stack blocks and passes them to `0x45728` at `0x44430`.

**Entry path**: `0x44580` is the function constructing the block invoking `0x45D20`. At `0x445b0–0x44674`, it performs two configuration lookups and tests through `0x49c00`; if either gate fails it exits at `0x446f8`. At `0x44678–0x44698`, it checks `0x4b2c0` and `0x4b0c0`, possibly takes an alternative branch `0x481c0`; otherwise constructs the entry and paired blocks and calls `0x45728` at `0x446f4`.

**New constraint**: the entry callback is NOT called unconditionally on a fullscreen button press. Two settings checks and a state check gate the call. The event receiver for `0x44580` remains unverified; do not wire a v12 button directly to `0x45D20` without these semantics. Exact direct branch/call references to `0x4438c` or `0x44580` were not found in the disassembly, consistent with indirect Objective-C dispatch.

No v12 binary edits, build or device test.
