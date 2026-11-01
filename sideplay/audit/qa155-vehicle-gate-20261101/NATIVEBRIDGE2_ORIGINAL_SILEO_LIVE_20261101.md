# QA156 nativebridge2 — original Sileo live verified, 2026-11-01

## Confirmed distribution
Original APT source https://chuongnguyen89dn-ui.github.io/carplaydsp/ .
Package com.duoface.jb.embedded, version 0.0.156~nativebridge2, architecture iphoneos-arm64.
Public DEB https://chuongnguyen89dn-ui.github.io/carplaydsp/debs/com.duoface.jb.embedded_0.0.156~nativebridge2_iphoneos-arm64.deb .
SHA256 b64d78e9678cd36f05ab9a5a4512559254b044de61d2bd5f5e22e2da8225eb17, 1,192,308 bytes.

Source 08512742276c6540590d7fb76ba25b69486c8b51; signed build 41260407074, archive cc3738643c3bff697db206210e25dfdae0f1f871 under sideplay/jb-embedded-appbridge/evidence/runs/41260407074/. Existing signed binary reused; no rebuild/new QA number.
Publisher carplaydsp/main .github/workflows/build.yml commit 3a1539847cd585adf28fe3c28cba030e78b91a08, exact read-back blob 93dc009692aa29cccab2d96cc0ab09b43427e84f.
Local publisher validation passed YAML parse, bash -n all30 run steps, Debian revision ordering, 101 archived integrated package versions and actual new DEB filter/compiled IPC markers.
GitHub YAML/actionlint validator 41261185836 SUCCESS.
Publication run https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/41261185823 COMPLETED SUCCESS, completed 2026-11-01T01:31:46Z (08:31:46 ICT).
All jobs SUCCESS: build 124714610588, deploy 124715210966, verify-duoface-integrated-pages 124715334910, verify-qa11-pages 124715334870, verify-duonavi-observer-pages 124715334842.
Actual public verifier downloaded Packages/Release and DEB, checked exactly one live integrated APT stanza/version/filename/hash. Public downloaded nativebridge2 SHA agrees with signed archive. Prior nativebridge1 SHA 9af1868794948317f1c9f1ebd15bb33b091c9132d99c815614287656b806e193, QA155 24143b1893f464a1d56b57bf60956bc4503bcafe57f8d8e4675bd64bbda3ff74, QA147 4d330ae909dc6f1e12ead482aef5b0754bf93ea8678e3ed41f97bd6d8ea1b7a6 all re-downloaded and unchanged. Public marker excerpt: NATIVEBRIDGE2_PUBLIC_MARKERS.log.
No new source/repository; no same-version replacement; all earlier immutable DEBs retained.

## Device next step (not performed)
In existing Sileo source refresh/upgrade DuoFace to exact 0.0.156~nativebridge2, respring to load new host. Fully close previously running selected test app to avoid retaining old injected module. In DuoFace My Apps enable Safari (and another supported chosen app). Existing settings must have “Hiện app trên CarPlay Home” and “Mở trực tiếp App từ CarPlay Home” enabled; keep existing enabled settings, no reset. On parked car tap Safari directly on native CarPlay Home, test touch/scroll including lower area after30s, native Home and Dock switch to second selected app, lock and disconnect/restore if possible in same session. Use “Xuất log / lỗi CarPlay” after test. Track one request/owner/scene through host state publish, app scene-matched/window-adjusted ACK and restored on stop. No VLC-only acceptance.
Physical iPhone sandbox notify delivery/permissions, UIKit scene IDs, attachment bogus reference size, real Home/Dock/touch/orientation/reconnect remain UNVERIFIED. Public distribution is not a device pass. Do not make another speculative build until actual trace locates next failed boundary.
