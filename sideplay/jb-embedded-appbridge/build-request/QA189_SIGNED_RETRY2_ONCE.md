# QA189 private signer retry2 — source freeze preserved

- User requested private signed QA189 DEB; no Sileo or device installation.
- Previous run `42382187096` failed before compiling because QA182 version assertion still expected CFBundleVersion 188; corrected.
- Retry1 `42382351197` failed before compiling because old QA180 H1 tests still expected QA188 package versions; both QA179/QA180 tests corrected as version assertions only. Maps/H1 functional sources and keyboard remain frozen to e88a73d24335802e9540032b23cf18ec8f10bf83.
- Run only single signer producing `com.duoface.jb.embedded_0.0.189~mapsh1fix1_iphoneos-arm64.deb` with signed binary checks, source identity, SHA256 and GitHub artifact, no Sileo.
