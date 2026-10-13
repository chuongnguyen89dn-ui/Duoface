# Targeted fullscreen toggle callback lookup (2026-10-13)

Evidence: user-supplied Airaw 1.7.1k arm64 dylib at /mnt/data/airaw_audit/root/var/jb/Library/MobileSubstrate/DynamicLibraries/Airaw.dylib, arm64 slice file offset 0x4000; /mnt/data/airaw_full_disasm.txt.

Targets: fullscreen entry-registration 0x44580; fullscreen exit-registration 0x4438C. These feed callback block invokes 0x45D20 and 0x45B50, respectively.

Actual checks:
- Search entire disassembly for references to each address, excluding their own function labels: 0 occurrences for both.
- Read arm64 Mach-O section table with llvm-objdump: __objc_methlist VM 0x52848 size 0x3ec8; __objc_const VM 0x74000 size 0x98b0.
- Scan aligned 32-bit signed relative words in each section; test both (word address + offset == target) and (word address + 8 + offset == target). Zero matches for both targets in both sections.
- This is a negative result for those specific encodings/sections, NOT proof that the methods have no dynamic/indirect callers. Do not conflate with split-view selector callbacks.

Next: analyze ADRP/ADD and ADR address construction for 0x44580 and 0x4438C, and inspect runtime registration/class methods or chained fixups; determine actual UI event origin before modifying DuoFace v12. No binary patch, DEB build, or device test.
