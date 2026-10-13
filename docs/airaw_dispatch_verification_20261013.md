# Verified Airaw arm64 dispatch sites (static)

Input: user-provided Airaw 1.7.1k, arm64 disassembly generated using llvm-objdump. Local assertion-based verification passed for five addresses:

| Address | Instruction | Meaning |
|---|---|---|
| 0x42f30 | bl 0x46b9c | `MSHookMessageEx` dock hook installer |
| 0x43a58 | bl 0x4af40 | `isChk` Objective-C stub; **not geometry** |
| 0x43aec | bl 0x4f320 | `setIsChk:` Objective-C stub; **not geometry** |
| 0x25514 | bl 0x47a00 | first notification dispatch after loading `toggleFullscreen` selector ref |
| 0x2b0d4 | bl 0x47a00 | second notification dispatch after loading same ref |

These observations establish an event dispatch and a dock layout hook, **not** a proven fullscreen geometry mutation or correct restoration of the dock. The callback receiver and host frame mutation are still unresolved. No v12 binary modifications, compilation, or device tests have occurred. Preserve original working v12.
