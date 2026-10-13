# Airaw dock notification receiver — verified instruction trace

Input: user-supplied Airaw 1.7.1k arm64 Mach-O. Command: `llvm-objdump --macho --arch=arm64 --disassemble --no-show-raw-insn Airaw.dylib`. Inspected offsets below in the arm64 disassembly.

**New verified receiver link:**

1. At `0x43a30` the replacement `DBDockWindow.layoutSubviews` first invokes its saved original implementation (`0x43a50: blr x8`), then checks `isChk` (`0x43a58`). If not checked, it obtains `NSDistributedNotificationCenter`, builds a block with invoke pointer **`0x451f0`** (`0x43ab4–0x43ac8`), registers the block via `0x43ae0: bl 0x47a20`, and sets `isChk` true (`0x43aec`). This is an observer registration path, not direct frame manipulation.
2. At `0x451f0` the registered block receives a notification, invokes a selector on that notification (`0x45208: bl 0x523e0`), compares the returned value with a static string (`0x45218: bl 0x4c9e0`), and on match calls `0x48580`, then dispatches `0x4f040` with `x0=[block+0x20]` and `x2` set to the value from `0x48580` (`0x45228–0x45230`). It logs the result (`0x45240`).
3. The two earlier identified `toggleFullscreen` posts (`0x25514`, `0x2b0d4`) are therefore linked to an actual dock-window notification observer *candidate*. The notification string and selector implementation `0x4f040` still need resolution before claiming this is the complete fullscreen action.
4. A distinct geometry-heavy function starts at `0x45254`, checks preconditions, reads a rectangle through `0x4c700`, and compares its width and height against zero (`0x45294`, `0x452a0`). It reads further scalar values and branches. Its caller and connection to host fullscreen remain unverified; do not assume it is the target.

**Status:** This establishes a concrete receiver path beyond mere selector-string matches. No DuoFace patch, compiled DEB, or device test yet. Preserve v12 unchanged.
