# QA142 fresh two-DEB Home launch static verification — 2026-10-31

## Verified work

- **Actual GitHub Actions run**: https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41174290359 ; job 124458513033 **completed SUCCESS**. This is a newly executed audit, unlike the earlier report which only reused prior archived results.
- Source branch: `feature/duoface-qa141-declaration-map-layout-20261031`; workflow `.github/workflows/duoface-qa142-two-deb-home-readonly.yml` committed at `fa2a404fab66baea4e5272a75d2acfbaca087dce`, source `sideplay/audit/qa142-log20-home-launch-20261031/verify_two_debs_readonly.py` committed at `961fffe44a010da9cea8a9639ce0e0c41033f3f7`.
- Runner **actually downloaded/verified/unzipped/read** central skill archives `01-github-continuity.zip`, `02-ios-deb-ipa-carplay.zip`, `05-research-debug-testing.zip`; used checksum-pinned existing project scripts; only scanned extracted binaries, never executed vendor code.
- Actual package inputs: ORIGINAL DuoNavi104 SHA256 `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd` and **REPACK** DuoDash113 Fullscreen427 SHA256 `ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465`; both extracted dylibs SHA-verified against `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15` and `b41dd7f892bfd3722e95a40f764a989886078b4a30943c1f0b50d47b6e248a47`.
- Machine-readable result `TWO_DEB_HOME_XREFS_VERIFIED.json` + `TWO_DEB_HOME_XREFS_RUN.txt`, archived GitHub commit `44eaac5768e72eec85aff86d8e27875649040275`; successful re-read from GitHub.

## Actual newly computed outputs

| Input | Tracked original-string literals | Matched functions | Candidate functions with tap/bridge references |
|---|---:|---:|---:|
| Original DuoNavi 1.0.4 | 15 | **22** | **8** |
| DuoDash 1.1.3 Fullscreen427 **REPACK** | 15 | **4** | **0** under this bounded same-function criterion |

DuoNavi candidate function `0xa35cc` references `iconManager:launchIconForIconView:`; additional candidate references to `startBridging:` occur at `0xed334`, `0x173e04`, `0x1a68ac`, `0x1c08e4`, `0x1f39fc`, `0x21fb2c`, `0x2fa444`. **This is marker-to-bounded-function co-location, NOT proof a specific call invokes another**. The earlier independent exact original method scan `ORIGINAL_DUONAVI_TAP_SELECTORS.json` identifies the distinct `0x3110f4/0x311144` selector sites; this fresh broad xref scanner cannot replace full call graph and may map unrelated symbol refs.

**A zero DuoDash tap candidate is explicitly inconclusive**: its repack has symbol strings but can dispatch through other functions/relocations/obfuscation/IPC; do not infer it lacks a functional icon launch bridge. Separate earlier selected IMP proof `ORIGINAL_DUONAVI_VS_DUODASH_REPACK_IMP.json` still verifies `CNABSpringBoardObserver.onHostRequest:` @0xf968, `onHostRequestSplit:` @0xfd90, `DDz2.cnabBuildSceneHostForBid:displaySize:` @0x1b7a0, `CNABUIApp.setBridgeState:width:height:orientation:` @0x1f514, `DDz1.showLayoutPanes:natives:bids:` @0x1543c (static, not on-device execution).

## What remains unverified

Actual user's QA141 Log20 proves six selected CarPlay Home icons visible, all six declaration getter readbacks and eight policy callbacks; user tap does NOT open app. No Home-tap hook/launch-outcome trace, host scene activation or native Dashboard 16.7.16 callback ABI proof. The original `_CARDashboardHomeViewController` was absent on the current device in prior ABI samples, so it must **not** be patched by original name/address. `launch=0` is an ABI-checked setter invocation result, not a system launch verdict. GOFA nine size ACKs match; visual status not newly tested.

## Next gate

Validate the **real current CarPlay Dashboard Home icon manager class/selector/ABI on the user's device**, not just the original dylib static names; design and test selected-only original-first launch handler to existing independent scene owner. Verify application scene active and accepted, native passthrough and failure/back teardown; preserve QA141 Home admission, original CarPlay apps and Dock, GOFA, screen-dim, YouTube input. Then signed CI -> immutable DEB -> Sileo live SHA -> physical CarPlay tap. No runtime change/build/Sileo claim for this audit.
