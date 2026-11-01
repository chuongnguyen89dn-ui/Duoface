# CarPlayPro Speed 0.9.97 — complete static DEB inventory

**Tra cứu nhanh / hồ sơ độc lập:** [CARPLAYPRO_SPEED_0.9.97.md](../CARPLAYPRO_SPEED_0.9.97.md). Đây là đầu mối đọc đầu tiên ở các phiên sau; không cần đọc lịch sử DuoFace để lấy thông tin gói.


Original: \`sideplay/audit/com.carplaypro.speed_0.9.97_iphoneos-arm64.deb\` on \`Duoface/main\`. SHA256: \`e5b0918b3bc1948420f37a8a9e21365756da46fba44d582a3f2893aee9b4102f\`.

Extracted 94 regular payload files and 3 control files; 5 Mach-O binaries / 10 arm64(+arm64e) architecture slices; 16 decoded plists; 69 identified images.

The \`unpacked/\` tree preserves all package payload and Debian control file bytes. \`inventory.json\` and \`SHA256SUMS.txt\` record every file, mode, symlink and digest. \`macho/\` holds every recognized binary's load commands, imported dylibs, RPATHs, segments, sections, UUID, symbol table, function starts, section strings (including ObjC methods/classes), and full offset-tagged ASCII/UTF16 strings in gzip. \`disassembly/\` contains full static arm64 \`__text\` instruction listings when Capstone available. \`plists-decoded.json\`, \`images.json\`, \`archive-members.txt\`, \`control-fields.txt\` and \`package-info.txt\` preserve other machine-readable evidence.

**Important:** read-only static audit. No installer scripts run; no iPhone/CarPlay device proof; no proprietary source recovered; no license/copy-protection alterations. Runtime-only behavior, encrypted code and stripped symbols cannot be guaranteed exhaustively.

Regenerate from root: \`python3 -m pip install capstone==5.0.6 && python3 sideplay/tools/audit_carplaypro_0997.py --replace\`.
