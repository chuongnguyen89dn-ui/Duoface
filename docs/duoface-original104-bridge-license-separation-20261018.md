# DuoFace independent — DuoNavi 1.0.4 / Native12 bridge–license boundary

## 2026-10-18: user decision and verified evidence

**USER_DECISION:** Continue reconstructing the already independently running CarPlay QA from original DuoNavi 1.0.4 and Native12 HUD8. Trace *how* UI and scene management connect, not merely styling. If licensing/checking is mixed with CarPlay, characterize each call boundary, then implement a **clean replacement** for the needed CarPlay behavior instead of copying vendor license or relying on the original binary.

Repository `chuongnguyen89dn-ui/Duoface`, QA branch `feature/visual12-duodash-recovery`. Original `dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb` SHA256 `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`, Dashboard SHA256 `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`, assembly `audit/duonavi-original104-scene/REPORT.md`, prior macOS Actions `39082350491` / `39082485471`. The source for full upstream GUI renderer is **not** present.

Native12 pinned unmixed artifact `85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7`; for real current Native12 HUD8 use `dist/payload-migration/native12-speed8compact/BAO_CAO.json`, source script `migration/full_payload/native_test/build_native12_speed8compact_candidate.py` (only SpeedHUD changes from Speed7). Do not confuse binary versions or reuse original 1.0.4 ARM64 IMP addresses for Native12.

## Identified historical coupling; what is—and is not—proven

| Historical binary class / method family | Feature side (needed for a working app) | Licensing / policy side | What static audit establishes |
|---|---|---|---|
| Original `CBWindow` | `createWindows`, `showAppPickerForSlot:`, `resizeWindows`, `showLayoutChooser` and `destroyWindows` | Other component can constrain whether window shown | Own actual window/slot UI methods in original 1.0.4 class metadata. No evidence this class alone checks subscription. |
| Original `CBBridgedSplitApp` | `handleDividerPan:isVertical:state:`, `focusSlot:animated:`, `restoreSplitAnimated:`, `toggleFocusForSlot:` | `restoreSplitAnimated:` static disassembly invokes `CBBridgeManager sharedInstance`, `saveBridgeStateToDisk`, `sendStateToApp:shouldBridge:` | Original functional layout is coupled to global bridge state. Exact dynamic requirements and effect of removing manager not proven. |
| Native `CBBridgeManager` | `showAppPickerForSlot:`, `switchToSplitWithLeft:right:ratio:`, `sendStateToApp:shouldBridge:`, app request notifications, per-app state / auto-resume | ALSO has `startLicenseWatchdogTimer`, `stopLicenseWatchdogTimer`, `licenseWatchdogTimerFired:`, `presentLicenseWarningModalWithType:`; its companion `CBBridgeManagerDashboard +isDashboardPolicySignalActive` may guard policy | Same compiled library/class owns functional bridge and license methods; **not** safe to remove the entire class from vendor binary while expecting CarPlay to work. Association is real; exact watchdog->scene side-effect not proven. Sources `audit/payload-migration/NATIVE12_CONNECTION_FULL_OWNERS_READONLY.json`, `NATIVE12_LICENSE_ACTIVATION_GATE_READONLY.json`. |
| Native iPhone `XXRootViewController` | App Settings / tabs / selection | `-checkAndPresentLicenseModalIfNeeded` directly references `CBSubscriptionViewController` and `CBLicenseExpiredModalViewController` | `audit/payload-migration/NATIVE12_LICENSE_XREF_CALLSITE_OWNERS.json` confirms three direct class references in UI method; **none should be copied** into independent QA Preferences. |
| Native `CBLicenseSyncManager` | Not part of our independent scene-owner API | Validation, remaining seconds, license sync | Existing Native12 methods are present; some return constants in that particular binary. This does **not** prove all license/policy behavior eliminated or license was the root cause of observed device failure. |
| Native mandatory disconnect/watchdog | Cleanup/resume and termination after disconnect | Has terms like `scheduleMandatoryDisconnectWatchdog` | **Unclear** whether license-linked; names do not suffice. Separate functional disconnect watchdog from actual trial/subscription watchdog by reading callers and state. |

Never disable diagnostics or clone vendor `postinst` (original 1.0.4 changes TCC, helper permissions and system daemons); retain CrashReporter to debug `exit mode`. No vendor license binary patch, service impersonation, license bypass, token/device-code recreation, or vendor network coupling.

## Exact replacement boundary already implemented in QA

**Own API and owner, not an expired-license patch:**

1. `replacement/visual12/engine/runtime/DFIRuntime.m:DFIStart` creates external `UIRootSceneWindow` on `CADisplay` and one `DFV12SplitController`; fail-closed when a vendor `CBBridgeManager` class is loaded to prevent two competing scene owners. It does **not** ask license endpoint for permission.
2. `DFV12SceneHost` uses Apple SpringBoard private `SBAppViewController`/scene APIs to attach apps, `setRequestedMode:2` when opening; its idempotent `close` requests `setRequestedMode:0` and invokes `invalidate` (standalone6invalidate fix). Device previously confirmed two different apps launch. Private APIs carry iOS 16/respring risks.
3. `replacement/cb-compat/DFCBCompat.m` defines own **`DFCBBridgeManager`**, `DFCBWindow`, `DFCBBridgedSplitApp` facades binding to the already existing QA root, not vendor `CBBridgeManager` or a second window; `DFCBBindHost`/ `DFCBUnbindHost` are the ownership boundary. No license classes/functions appear in this facade.
4. `DFV12SplitController` keeps independent `hosts[]` slot ownership; `choose:` calls `openBundle:pane:` per pane; source `DFIInterface.inc` after commit `5aabd9bc531edd218e6a7b8c650564e5c6e8d1ed` adds per-slot App and focus/restore buttons from original control contracts, plus divider-wide pan hit strips. This is a *first independent equivalent*, NOT the original UIKit classes or proven exact UI parity.
5. Non-license `replacement/visual12/engine/shared/DFISettings.m` still needs accurate Native12-equivalent Settings reconstruction; no subscription, time, vendor servers. HUD visual available; speed data not connected.

## Known open failure gates and reason to proceed incrementally

- **User device test of UI8NATIVE2:** two live apps and HUD PASS, original visual/controls FAIL, first-respring `exit mode` FAIL, live-app drag FAIL. Exact hit-test and first-respring stack unverified because contemporaneous `.ips`/runtime log missing.
- **CI of new independent control trial:** `native104ui3` build Actions [39092392033](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39092392033) completed/success, `com.duoface.visual12 1.0.3-12~native104ui3` artifact SHA256 `3068526673e6d38187b53945365cc7ea0d29fb2ede1b3372f1efd59a24ac37e1`, 1,066,788 bytes; `dist/visual12-native104ui3-qa/`. Verifier asserts no vendor `CBLicenseSyncManager` and no `licenseWatchdogTimerFired` strings in QA tweak, native per-slot controls present. Compiler/package tests **do not** prove the binary is free of every possible license/policy string at runtime or that CarPlay UI/touch works.
- **Next device acceptance:** original per-pane picker/zoom/restore with two active apps; drag ratio along divider *outside* center grip; zoom/unzoom restores prior ratio; no first-respring `exit mode`; screenshot compare Native12. Collect event-matched logs. Do NOT close old UI parity issues until user test.
- **Defer until next isolated run:** fuller original method-to-callback reverse-engineering for `calculateNativeSizeForSlotRect:`, `updateSceneSettingsFrame`, native view/pill hit-test; improvement to non-license iPhone settings; split-scene media/cleanup behavior.

Source and build changes in this task remain on the QA branch only. Stable `com.duoface.independent` Native12 HUD8 payload and Sileo record must remain unmodified.

## 2026-10-18 release and original UI audit addendum (SUPERSEDES INTERIM PACKAGE LABEL)

The historical `1.0.3-12~native104ui3` package above was a *successful intermediate build*, but its Debian version sorts below previously published `ui8native2`; **do not tell a tester to install that version**. The final tested-by-CI QA artifact is **`1.0.3-12~ui8native3`**, under `dist/visual12-native104ui3b-qa/` with SHA256 `3bb83550ead8cdc13fd7881e652aee2384d3ea1aba7bd5d5a235775809e73872`. GitHub Actions DuoFace run `39092553442` completed/success. Independent publisher `chuongnguyen89dn-ui/carplaydsp` run `39092623743` build and Pages deployment completed/success; stable Native12 HUD8 APT entry remained unchanged. This is still **QA device test pending**, not an approved native-equivalent UI.

New original104 read-only report: `audit/duonavi-original104-ui/ORIGINAL104_UI_CALLCHAINS.json` and `REPORT.md` from macOS Actions run `39092806387` (success), latest persisted audit commit `260ac992270c333931577031d0f453c53bbac863`. It samples 25 original UI/scene methods and confirms important **static** selector routes:

- `CBWindow.showAppPickerForSlot:` references `multitaskingOverlay.showAppPickerForSlot:parentView:`; the real native picker is connected via overlay, not a root QA list alone.
- `CBBridgedSplitApp.handleDividerPan:isVertical:state:` references `CBWindow.carPlayUsableBounds`, `layoutSplitViews`, `CBDashboardSettings.setSplitRatio:`, saving bridge state and communicating per-app state.
- `CBBridgedSplitApp.focusSlot:animated:` and `restoreSplitAnimated:` reference animation, `layoutSplitViews`, `refreshSceneLayout`, plus `CBBridgeManager.saveBridgeStateToDisk` and `sendStateToApp:shouldBridge:`. The functional state path must be reimplemented independently rather than copying manager or license.
- `CBBridgedUIAppView.updateLayout` references `calculateNativeSizeForSlotRect:`, transforms and contentReferenceSize; `updateSceneSettingsFrame` checks `carPlayUsableBounds` and scene settings updates. These should guide the future cramped-app geometry fix; current QA 2x render/0.5x transform has **not** been changed.
- `CBBridgedUIAppView.hitTest:withEvent:` references manager `noteUserActivity`. Native active gesture/visibility behavior may be coupled to scene activity and divider blink; not proven as the user's touch failure root cause without device trace.

For the next session: inspect original 17-instruction arithmetic implementation of `calculateNativeSizeForSlotRect:` and actual two-app divider hit tests before modifying scene transform/geometry. Never port vendor license/lease, subscription modal, original postinst, or system-daemon disabling. Preserve QA independent scene owner, previous lifecycle teardown, and Native12 stable payload.
