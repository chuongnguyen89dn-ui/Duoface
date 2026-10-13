# Full original-v12 vs original-1.0.4 audit — 2026-10-13

**Source of truth:** recovered the ORIGINAL working v12 DEB from `/mnt/data/github-actions-artifact-11786004593.zip`, member `com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb`. Original upstream: `com.duonavi.app_1.0.4_iphoneos-arm64.deb`. Extracted with `dpkg-deb -x` to `/mnt/data/duoface_fullaudit/v12` and `up`. This supersedes previous comparison using the 57-file delta.

## File counts

- Original v12 **35** payload files.
- Original 1.0.4 **50** payload files.
- **0 exact shared relative paths** because v12 renamed its application, Dashboard, helpers and asset tree, and original 1.0.4 has 22 audio/OldABI files absent in original v12.
- Matched equivalent roles via renaming rules for AppIcon/Info.plist, logos, Dashboard dylib/plist, sudoers and helper binaries. Among 50 upstream files: **1 byte-identical** (sudoers), **26 same-role but byte-different**, **23 unmatched** (21 audio files + OldABI dylib + native app executable with different name). The native app executable is a *same-role* binary despite unmatched filename: `DuoNaviUI` vs `DuoFaceUI`.

## Directory decisions

| Upstream 1.0.4 directory | Count | Decision relative to original v12 |
|---|---:|---|
| `var/jb/Applications/DuoNaviUI.app` | 20 | 18 AppIcon and Info.plist are same-role, changed branding; native executable is renamed. Preserve 20 v12 app files; do not add second app. |
| `var/jb/Library/Application Support/DuoNavi/Audio` | 21 | Missing from v12: safe file-level addition pending integration; this was already added in 57-file delta. |
| `var/jb/Library/Application Support/DuoNavi` branding root | 3 | Preserve v12 DuoFace branding assets; do not copy DuoNavi logos. |
| `var/jb/Library/MobileSubstrate/DynamicLibraries` | 2 | Dashboard binary differs and contains new voice Objective-C classes absent from v12. Preserve v12 Dashboard; cannot transplant code by merely copying missing files without creating duplicate. Filter plist same role but different app bundle ID. |
| `var/jb/etc/sudoers.d` | 1 | Identical bytes, no need duplicate. |
| `var/jb/usr/bin` | 1 | Different helper binary; keep v12 helper. |
| `var/jb/usr/lib/ellekit` | 1 | OldABI dylib absent v12; included in delta. |
| `var/jb/usr/libexec` | 1 | Different helper binary; keep v12 helper. |

**Important:** Original 1.0.4's native voice subsystem is compiled into `DuoNaviDashboard.dylib`, not present as standalone files. A union of missing paths alone will NOT give working voice functionality. The v12-first delta already contains all 22 independently new audio/OldABI files. Further work requires binary-compatible native feature implementation, not copying duplicate app/Dashboard. License/1800 days cannot be verified statically. No Sileo change or finished DEB issued.
