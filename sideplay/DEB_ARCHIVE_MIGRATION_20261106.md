# DuoFace DEB repository migration — 2026-11-06

The original Git history is unchanged. This commit only removes tracked DEBs from the current tree after byte-for-byte archival. Old raw.githubusercontent.com URLs pinned to earlier DuoFace commits continue to resolve.

- Archived historical `spec-main` source: `efdd4ebeb166864e676dcc059b12145111b3174f`.
- Source history: **1,079 tracked DEB files, 440,062,162 bytes**. The archive contains every file under `historical/<original-relative-path>`, preserving its filename and relative path to prevent collisions.
- Archive repository: https://github.com/chuongnguyen89dn-ui/duoface-debs-
- Archive manifest: `MANIFEST.tsv` (path, size, SHA-256 for every file), archive `main` commit `3d791cd4ef8d43ab8a04e26890697b9554c7e49e`.
- An additional **2 DEBs / 4,109,458 bytes** from the old DuoFace `main` branch (not present in spec-main) are preserved under `historical-main/<original-relative-path>` and `MAIN_ONLY_MANIFEST.tsv`.
- Selected QA178 signed DEB: `debs/com.duoface.jb.embedded_0.0.178~h1wake1_iphoneos-arm64.deb`, SHA-256 `9ef27c0155aedf9eaef1a489bbe7f1191de8b987189cd4c554c3c79067a002c0`.
- The raw audit JSON dumps >= 100,000 bytes were removed from the working tree; all historical Git commits remain intact and Markdown/text audit summaries are retained.

Do not use Git LFS or rewrite Git history. New QA artifacts must be archived directly in the DEB repository and referenced by commit-pinned raw URL. `.gitignore` prevents accidental re-adding of `.deb` files.
