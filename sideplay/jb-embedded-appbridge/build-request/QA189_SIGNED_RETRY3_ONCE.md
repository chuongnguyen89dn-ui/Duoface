# QA189 corrected private signer retry3

- User authorized private QA189 integrated signed DEB; no Sileo or iPhone deployment.
- Trigger only after source+H1/map regressions pass and QA179/QA180/QA182 package version assertions updated.
- Run42382525341 was pinned to an older workflow asserting 188 after signing CFBundleVersion 189; current workflow changes both signed-host and integrated DEB postbuild gates to 189. Corrected request runs with frozen functional source e88a73d24335802e9540032b23cf18ec8f10bf83; no vendor copy or DuoNavi removal.
- Target 0.0.189~mapsh1fix1 signed iphoneos-arm64; SHA256 and all 11 Mach-O signatures checked independently after artifact. No vehicle-pass claim.
