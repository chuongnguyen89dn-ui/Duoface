# DuoFace VisualTest12 — launchfix1 / Sileo checkpoint 2026-10-17

## User goal
User's immediate priority: the existing `com.duonavi.app` VisualTest12 must open on the iPhone after the trial expired. Do not confuse with independent Native12/Speed8 Hub. Verify on the actual expired iPhone before declaring fixed.

## Verified deliverable
- Package: `com.duonavi.app`; version `1.0.3-12~visualtest12launch1`, architecture `iphoneos-arm64`.
- Signed DEB: `dist/visualtest12-launchfix1/com.duonavi.app_1.0.3-12~visualtest12launch1_iphoneos-arm64.deb` in project branch `feature/duoface-exact-payload-migration`.
- GitHub file blob SHA: `d43dec36ec77a74d3a7a0b62167e63407dcc6777`; SHA256 `e30148affc767ce039040f0e0cccd9a0ecbd40e523ee66409ca96e6ef2085f02`; size 1,555,368 bytes.
- Built by `migration/full_payload/native_test/build_visualtest12_launchfix1.py`, using immutable VisualTest12 input SHA256 `8b7dedf77b9ec05465b83fdb6e2d7127800eac232a34ecf12f2c08b3983a481a`. The existing method-body compatibility strategy affected 291 methods across two arm64 hosts plus 2 expired UI state methods; 35 other package files unchanged; original VisualHook unchanged. Signed ARM64 and dpkg-deb checked in macos-15. **This is a device-untested launch recovery candidate, not proof of full removal or runtime success.**
- Successful CI build: DuoFace run `39021792773`, job `117364909028`; Actions artifact ID `12096469859`. Initial run `39021729748` failed because source lacked DEBIAN/md5sums; builder fixed in commit `0725ed2400d1a0bf1c817bdba11f3ca3207a7cd0`.
- Build workflow: `.github/workflows/duoface-visualtest12-launch-recovery-deb.yml`.
- Published via Sileo repo `chuongnguyen89dn-ui/carplaydsp`, workflow `.github/workflows/build.yml`, commits `15f70f0cb6d76ad2e66027db7d17c442d89d05f1` and filename-verification fix `b60952bc030a9df222250219be72ba9ace670431`. Pages run `39022124541`: both build `117365855193` and deploy `117366205398` **SUCCESS**. Initial deployment `39021929432` failed from a stale filename in checksum validation (not a DEB build failure).
- **Real public download independently verified in GitHub Actions**: `39022327036`, job `117366437442` **SUCCESS**. Downloaded public `Packages` and original DEB; package ID, version, filename and SHA256 match. Report `audit/payload-migration/VISUALTEST12_LAUNCHFIX1_PUBLIC_SILEO.json` at feature commit `953c4be4cbbb2628f3e0a4b8f4ebe54141ffeb05`, report blob `018cb354c4a9d652772c3cff985cf6999af1aa30`. URL:
  `https://chuongnguyen89dn-ui.github.io/carplaydsp/debs/com.duonavi.app_1.0.3-12~visualtest12launch1_iphoneos-arm64.deb`
- Sileo APT source: `https://chuongnguyen89dn-ui.github.io/carplaydsp/`. Refresh Sources and upgrade `com.duonavi.app` on the expired device.
- Hub remains exact `com.duoface.independent` version `0.1.0~native12+speed8compact`, public SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`, confirmed in the same public APT verification.

## Pending acceptance and next action
1. User updates the existing VisualTest12 from Sileo, opens the app on the specific iPhone whose trial has expired and confirms whether the dashboard opens without crash or expiry block. Do not say launch fixed before that test.
2. If it still cannot open, obtain current device logs and check springboard, launch, runtime symbol resolution; compare original VisualTest12 and current build. No guessed patch or incompatible Hub swap.
3. If successful, test CarPlay side-by-side, picker, full-screen, launch behavior, and only then mark resolved. Do not alter independent Hub or unrelated Sileo packages.
4. Maintain user-visible report of what was actually built/published vs verified on-device.
