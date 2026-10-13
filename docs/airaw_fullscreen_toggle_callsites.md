# Airaw fullscreen toggle callsite scan

Executed static ARM64 scan on the user-provided Airaw 1.7.1k Mach-O using `python /mnt/data/airaw_audit/fullscreen_selector_refs_scan.py` and checked disassembly.

- `toggleFullscreen` selector reference at `0x80498` is loaded at `0x254fc` and `0x2b0bc`; both call through the notification dispatch path (`0x25514`, `0x2b0d4`) after obtaining `NSDistributedNotificationCenter`. This is a concrete event/notification trigger for fullscreen.
- `setSavedRect:` selector reference at `0x7fef8` is loaded only at accessor registration sites `0xb004`, `0xbb4c`, `0x432c0` in the current disassembly listing.
- `setSavedEdgeInsets:` at `0x7fef0`: registration sites `0xaf74`, `0xbabc`, `0x43230`.
- `setIsFull:` at `0x7f9c8`: registration sites `0xadd4`, `0xb91c`, `0x43090`.
- `requestFullscreenToggle` at `0x7f2e0` has no direct `x3` selector load in the current listing.

**Result:** The fullscreen toggle notification sites have been located. The geometry mutation path is not resolved by these selector references; do not claim before/after dimensions or a working v12 fullscreen implementation. No DEB built or device-tested.
