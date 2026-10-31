# QA154 scoped app-state and restore continuation

2026-10-31, actual repository `chuongnguyen89dn-ui/Duoface`, branch `feature/duoface-qa146-native-home-exit-20261031`.

## Source progress

- New `sideplay/duoface-native-scene-host/DF154AppStateProtocol.h` (commit `8c7717042a60d8f5c3998df56e722e65fabfe066`): independent 3-second per-request owner + sceneIdentifier + bundle state and distributed notification contract. No original commercial channel, token or licensing copied.
- New `sideplay/duoface-native-scene-host/DF154GeneralAppStateRelay.m` (commit `3d19e28f1d3760f89a76721263c5e41b6219e7e2`): source-only UIKit consumer validating exact owned `UIWindowScene` ID; saves original window frame and bounds; explicitly restores on same-owner stop, owner replacement or expiry. Never changes device-wide orientation or Apple native Dock.
- Updated `sideplay/duoface-native-scene-host/DFHomeStandalone144.m` (commit `24e5126a38c7f9f23bb161d9971cebec73453b0c`): generic state publication only from SpringBoard real live hosted scene and matching bundle; refreshes during owner heartbeat and revokes when stopping. Excludes existing dedicated YouTube and GOFA channels. Frozen `DFSceneHost.m` untouched.

## Boundary and packaging

**The new generic app consumer is source-only and NOT packaged or injected into other applications.** No new substrate filter, no general-app release, no device acceptance. Integrating it into other apps would require explicit, secure and reviewable bundle scopes; that integration was not completed in this turn. GitHub Actions presently compiles the SpringBoard publication half but not the standalone generic app receiver. Do not claim successful app-side restoration or generic multi-app support. The two original dedicated YT/GOFA receivers remain unchanged.

## Exact review/verification status

- Baseline QA153 signed DEB `sideplay/jb-embedded-appbridge/evidence/runs/41214955481/com.duoface.jb.embedded_0.0.147~native-dock-sync1_iphoneos-arm64.deb` SHA256 `7f609a78159a506e58c82c5813b436f2b82daec9f55a8c3a3cb912ae8c88d44e`, prior tested code only; not reclassified as QA154.
- New source push `24e5126` triggers private macOS build run `41216200946` and source guard run `41216201038`. The fast guard run completed SUCCESS. The macOS signed run must be checked again before reporting any QA154 build success; whether it completes or fails, record the exact result. No public Sileo release or phone test.
- Expected original route remains native Dashboard workspace prepare, SpringBoard phone foreground transition, real scene host, manager state, native Dock/Home, per-app scene layout and symmetric exit. Original genuine DuoNaviDashboard binary pin SHA256 `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`, device Log23 pin `c327274898d8d7285259d4bdbfc04b623a81e3cb6263ccda7ccf948d9cca267d`.

## Next

Do not publish or install a speculative general-app receiver. Review exact eligible-app process scope and packaging permissions; add isolated app-process compile/restore tests without affecting the working YouTube/GOFA modules; require same-request iPhone X iOS16.7.16 trace for real app scene ID and stop restore before declaring native execution parity. The source-only relay must not be treated as an installed component.

## Source-only validation and CI revision

- Additional test `sideplay/duoface-native-scene-host/tests/test_qa154_staged_app_state.py` committed `0cc66369297e2d20c8c718f391d25569ff870c62`, verifies sender requires a live owned scene, three-second app lease, window restore and that generic app-process receiver is **not included** in `build.sh`.
- Scoped workflow commit `9706752b159f8398fd2d0b6c6a19f5a585ba3d1c`; [run 41216470683](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41216470683) **SUCCESS**.
- Private macOS workflow commit `ecba74effb7848cfe7deae86a57b87d12f2588fe` adds iOS16 syntax-only compile of staged receiver (does **not** build it into package). Initial [run 41216478996](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41216478996) **FAILED** only due to unused linker-only `-framework` flags under `clang -fsyntax-only -Werror`. Corrected workflow at `c7844358ca28845877f39525825a01ca190a92e8`. [run 41216554297](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41216554297) passed source and iOS syntax validation; signed build was still running when observed. Inspect final result before claiming success.
- Pinned historic/source verifier expanded 29→31 static checks, commit `2b9d5454f7638e3371c0bd3ea0b096eb864d02ab`, CI marker `d1b950790695d48f03a22a3cb646003572435bd9`; [run 41216635707](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41216635707) **SUCCESS**. This is code/string/archive consistency, not physical app or UI parity.
- No generic receiver plist/filter or third-party app injection was shipped. Source-only generic receiver is deliberately excluded from the integrated DEB and cannot yet fix arbitrary-app orientation on a CarPlay device.
