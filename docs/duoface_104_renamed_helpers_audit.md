# 2026-10-13 — Compare renamed helper counterparts (v12-first delta vs upstream 1.0.4)

Extracted paths under `/var/jb` from existing delta and upstream DEBs; compared SHA256 and full bytes.

| Component | v12-first | upstream 1.0.4 | Finding |
|---|---|---|---|
| CLI `usr/bin/duoface-cboptimize` vs `usr/bin/cboptimize` | 3364 B, SHA256 `73b19cdafe1624f0…` | 3364 B, `dc51c0de747e0c1f…` | Not byte-identical; retain v12 |
| Helper `usr/libexec/duoface_cboptimize_helper` vs `usr/libexec/cboptimize_helper` | 150528 B, `bd77f7594b649b72…` | 150720 B, `421656d74a08174c…` | Different binary; retain v12 until behavior is validated |
| `etc/sudoers.d/duoface` vs `etc/sudoers.d/duonavi` | 28 B | 28 B | Identical content: `ALL ALL=(ALL) NOPASSWD: ALL`; do not duplicate |
| `DuoFaceDashboard.plist` vs `DuoNaviDashboard.plist` | 23 filter bundles | 23 filter bundles | Lists identical except final bundle ID `com.duoface.duofaceui` vs `com.duonavi.duonaviui`; preserve v12 filter |

These checks are on the **57-file v12-first delta**, not the original 35-file v12. This audit does not justify claiming the 1.0.4 voice implementation has been transplanted. No DEB released.
