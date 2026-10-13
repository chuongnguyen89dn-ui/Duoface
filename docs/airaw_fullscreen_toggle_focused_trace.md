# Focused toggle-function verification — 2026-10-13

Source: locally available user-uploaded Airaw 1.7.1k dylib and `/mnt/data/airaw_full_disasm.txt`. Inspected actual arm64 disassembly of both registration routines, not just keyword matches.

- **Exit path `0x4438C`:** state check `bl 0x4B2C0` at `0x443A0`; property updates `bl 0x50140` at `0x443C8` and `bl 0x50160` at `0x443D4`; creates block invoke `0x45B00` at `0x443F0–0x44400` and restore block invoke `0x45B50` at `0x4440C–0x44420`; both passed to scene dispatcher `0x45728` at `0x44430`.
- **Entry path `0x44580`:** IMPORTANT correction: checks **three** configuration keys, at `0x6F2B8`, `0x6F2D8`, `0x6F2F8`, via `0x49C00` at `0x445E8`, `0x4462C`, `0x44670`. Any enabled key proceeds to state checks `0x4B2C0` / `0x4B0C0`; if no key enabled, returns without invoking entry block. If already in alternate state, `0x481C0` path is used. Otherwise builds callback block `0x45D20` and dispatches via `0x45728`.
- Exhaustive exact direct branch/call search of `/mnt/data/airaw_full_disasm.txt` for `bl/b 0x4438c` or `bl/b 0x44580`: zero. This supports indirect method invocation, not proof of button selector ownership.
- ObjC metadata textual search for direct textual target addresses: no match. Further task: inspect class method lists/registration and the UI target-action selector, specifically for these two entrypoints. Do not confuse split pane callbacks with fullscreen.
- No DuoFace v12 code edits, no DEB build, no device test.
