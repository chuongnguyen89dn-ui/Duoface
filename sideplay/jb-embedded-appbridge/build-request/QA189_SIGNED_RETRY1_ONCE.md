# QA189 private signer retry1 — isolated version-test repair

- Previous run: 42382187096 / 128431952346 FAILED before build, `test_qa182_b1nativemaps1.test_versions` expected stale CFBundleVersion 188 despite Info.plist version 189.
- Exact fix: only `test_qa182_b1nativemaps1.py` assert CFBundleVersion 189 and one isolated workflow retry path; package/functional Maps/H1 implementation unchanged.
- User authorized a private QA189 signed package, no Sileo or install. Immutable source base e88a73d24335802e9540032b23cf18ec8f10bf83. Artifact requested com.duoface.jb.embedded_0.0.189~mapsh1fix1_iphoneos-arm64.deb.
