# QA153 — SpringBoard phone-foreground eviction before opening selected CarPlay app

2026-10-31. Repo `chuongnguyen89dn-ui/Duoface`, branch `feature/duoface-qa146-native-home-exit-20261031`, predecessor checkpoint `94a7c178d638b0d0504a8b1a1d8f714e368e3649`. **Signed CI build is not proof of car-screen/Home/Dock behavior.**

## Real original-route basis, independent implementation

Pinned genuine DuoNavi `DuoNaviDashboard.dylib` SHA256 `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15` original machine-code audit `sideplay/audit/original-execution-route-20261031/ROUTE_FINDINGS.md` demonstrates `loadNewAppFromCurrentRequest:` -> `evictAppFromPhoneScreen:completion:` -> hosted view continuation. Some branches call native `SBUIController clickedMenuButton` when the **same app** occupies phone foreground; other branches build `SBMainWorkspace` / `SBHomeScreenEntity` transition requests. A 120ms once-only fallback exists in the bounded original suffix. **This does not establish that a global Home press is always appropriate** and does not grant permission to fire unverified private selectors.

Independently cross-checked iOS SpringBoard interface declarations in [battsafepro SpringBoard-Private.h](https://github.com/udevsharold/battsafepro/blob/master/SpringBoard-Private.h) (`SpringBoard _accessibilityFrontMostApplication`, `SBApplicationProcessState.isForeground`, `SBApplication.bundleIdentifier`, `SBMainWorkspace` request selectors). [DVirtualHome Tweak.xm](https://github.com/DGh0st/DVirtualHome/blob/master/Tweak.xm) shows a separate `SBMainWorkspace` activation example but is not target iOS16.7.16 evidence. The first-party code below uses only the bounded **conditional exact-foreground native phone Home** branch; deliberately does not invent the bigger `SBMainWorkspace` request ABI.

## Changes actually made

- `sideplay/duoface-native-scene-host/DF153PhoneEviction.h`, source commit `a2a06d786481cc97281283a65480c71bddabb347`, Git blob `c468102f9efef875bf349b2cd181d3530792480f`: SpringBoard-only native phone action, **only if exact selected app is actually phone-frontmost and isForeground**. Gets app from SpringBoard `UIApplication.sharedApplication._accessibilityFrontMostApplication` via existing ABI-checked `DF144Get`; requires exact `bundleIdentifier` equality with selected bundle, live `processState.isForeground` BOOL/signed-char ABI, `SBUIController.sharedInstance` ABI `@16@0:8`, `clickedMenuButton` ABI `v16@0:8`. Only then invokes the real native phone Home once. If any owner/app/selector/ABI fails, it **does not press Home**; logs a reason and continues. It **never** evicts an unrelated phone app or calls guessed `SBMainWorkspace` transition requests. A generation-scoped 120ms continuation and exception fallback use the existing first-party once-only state.
- `DFHomeStandalone144.m`, source commit `80a27e62cc80b1b79d2c98905306ba38740f3322`, blob `908b11a99f667ca04edec9360b7767ceb9d778ab`: SpringBoard now consumes validated, enabled, fresh native Home selection, then conditionally evicts only the selected phone app **before** `DF144Solo begin:` creates the CarPlay host. The deferred continuation rechecks same `RequestID`, freshness and opt-in. Physical CarPlay Home, native switch, pending watchdog and owner revoke each invalidate the phone-stage generation first. The previous QA152 Dashboard-native workspace preparation is kept before IPC to SpringBoard, so the partial order is now: Dashboard native preparation -> remote request -> conditional phone eviction -> host/window live receipt -> native Dock/Home.
- New test `tests/test_qa153_phone_foreground_eviction.py`, commit `0a050345e041f45ea9982e14cb4d35c086e78231`: exact on-phone selected bundle matching, real foreground, getter/selector ABIs, single native phone Home, 120ms cancellation, revalidation before host, frozen `DFSceneHost.m` geometry baseline `ec2924c145be4edaaa27b7320bb869b18de12c6b`, native Dock manager preserved. **Textual/static tests**, not actual iPhone touch or Home function acceptance.
- Fast CI `.github/workflows/duoface-qa147-mount-ready-guards.yml` commit `f534492cfb1ea81ec99ac7034bf4290400942f7e`, signed macOS iOS16 PRIVATE `.github/workflows/duoface-146-native-home-exit-private.yml` commit `ba6c8b786f36266ef45b84894750525c711125f8`, both add QA153 test and source path trigger.
- Pinned historical original/source 29-check verifier `sideplay/audit/qa147-full-route-evidence-20261031/verify_full_route_evidence.py` updated commit `196eaa2c3feeb295cd92a1503b8a733d33bfa204`; CI marker `29_STATIC_ASSERTIONS_PASS_NOT_RUNTIME_PARITY` updated `515704451d21a0f5a6a65c72ecdd21043bceeef8`. This reuses previous original binary and Log23 pins (no re-run of original vendor DEB).

## Tests/build and real gate

- [Scoped source safety regression CI `41214947768`](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41214947768) completed **SUCCESS**.
- [Historic/static 29-check route CI `41215018619`](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41215018619) completed **SUCCESS**; previous `41214998384` failed old 27-check workflow marker before it was changed.
- [macOS iOS16 full PRIVATE signed build `41214955481`](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41214955481) started at source SHA `ba6c8b786f36266ef45b84894750525c711125f8`. **Check final result, `CI_RESULT.txt`, `SHA256SUMS.txt`, `PACKAGING_PROVENANCE.json`, DEB path and GitHub archive before claiming build SUCCESS.** It is not published via Sileo.
- Reproduce from repository root:
  ```bash
  python3 -m unittest discover -s sideplay/duoface-native-scene-host/tests -p 'test_qa153_phone_foreground_eviction.py' -v
  python3 -m unittest discover -s sideplay/duoface-native-scene-host/tests -p 'test_qa152_workspace_prepare.py' -v
  python3 sideplay/audit/qa147-full-route-evidence-20261031/verify_full_route_evidence.py --repo .
  ```

## Still missing and not claimed

- No QA153 physical device test on user's iPhone X iOS16.7.16; exact runtime method encoding and native phone Home response have NOT been observed. **May fail closed**, leaving the phone foreground app untouched; this is intentional until the exact receiver is verified.
- `SBMainWorkspace` alternate native phone eviction route and completion handler have not been implemented because live receiver/ABI is unknown. General app-side state contract, native Home previous-page semantics, full-root CarPlay window pass-through and touch/orientation bugs not proven fixed. Avoid inventing Home/Dock success, replacing Apple’s native app route or copying vendor license behavior.
- Next work: physical trace same RequestID across QA150/151/152/153, real scene receipt and native Dock/Home, then implement and test missing `SBMainWorkspace` variant, app-side state and symmetric restoration. Only publish once vehicle acceptance confirms launch, input, orientation, Home, Dock, reconnect and old split regression.
