# DuoFace v12 → DuoNavi 1.0.4 native compatibility audit

Read-only script: `scripts/duoface_104_compatibility_audit.py`. No package is published by this audit.

Inputs:
- DuoFace v12: `dist/visual-1.0.3-12/com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb`
- Original 1.0.4: `dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb`

Local invocation:
```bash
python3 scripts/duoface_104_compatibility_audit.py \
  --v12 dist/visual-1.0.3-12/com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb \
  --upstream dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb \
  --output /tmp/duoface_104_compatibility_audit.json
```

Verified on 2026-10-13: 35 v12 payload files; 50 upstream 1.0.4 payload files. 1.0.4 native Dashboard contains `CBVoiceSessionManager`; v12 Dashboard does not. Both native binaries contain `1.0.3` strings, and upstream 1.0.4 contains DuoNavi UI literals. Existing v12 hook references `_dotsButton`, `_expandButton`, `_restoreButton`, `_moveButtons`, `_logoImageView`; all these names exist in upstream Dashboard strings, but this is not proof of runtime hook compatibility.

**Do not publish v12+audio as a true 1.0.4 update.** Functional native merge and iPhone/CarPlay test remain unverified. Keep working v12 Sileo release.
