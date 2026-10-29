# DuoNavi 1.0.4 vs independently signed DuoFace .118 — actual Dock seam geometry difference

**2026-10-29, original and current DEBs SHA-pinned and scanned. No on-device width was measured. No patch/build/release from this audit.**

## Hardware outcome

User physically confirms after .118 emergency rollback the **native CarPlay Dock is visible again**, but the black vertical gap between its right edge and DuoFace's left-hand pane is **still present**. The user explicitly rejects any invented 42pt/percentage or guessed scale and requires original DuoNavi binary comparison before another patch. This outcome is expected: .118 deliberately restored *exactly* .116's original `MAX(42, 8.2%)` extra-left-guard for safety after .117's fullscreen/Dock-hidden device failure. It was not designed or claimed to remove the black gap.

Separate GOFA robot voice hypothesis remains untested. No evidence identifies GOFA as responsible for the black seam or YouTube input loss; do not conflate the two.

## Exact two real package identities

| Identity | DuoNavi original | DuoFace current |
|---|---|---|
| Filename | `dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb` | `sideplay/jb-embedded-appbridge/evidence/runs/40901000640/com.duoface.jb.embedded_0.0.118~dock-rollback1_iphoneos-arm64.deb` |
| SHA256 | `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd` | `4b566ea40727df0acfd7baab8268dac2bfc8ada2779ad5ec6964b43f7b6793fb` |
| Actual installed-layout logic | `DuoNaviDashboard.dylib` SHA256 `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15` | `DFTouchOwnerProbe.dylib` from signed archive; exact source verified identical to build source commit `e9501ec1e5b441095a22b78b255c8c8b932bb383` |
| Status | Original vendor binary read-only | First-party independently implemented package, rootless |

**Proof:** GitHub Actions [run 40904918475](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40904918475), job `123556931745` **COMPLETED SUCCESS**: central skill ZIP checksum and SKILL.md, original/current DEB identities, original dylib hash, exact compiled-source commit, original 18 ARM64 methods, downloadable workflow artifact and archived reports. `ORIGINAL_DUONAVI104_DOCK_IMP.json` Git blob `d72422d899119444a2045466de2ed9a20c4a9cea`; `DUONAVI104_VS_SIGNED_DUOFACE118_DOCK_VERDICT.md` blob `b1957858aaa8527b8083f16f8200484c6de05b5b`. Original 1.0.4 is **not** assumed identical to Native12 HUD8; this scan inspected its own binary.

## Confirmed differences — exact functions and code locations

1. **Display bounds owner is different**:
   - Original `CBWindow.carPlayScreenBounds` IMP `0xb0ddc` (357 ARM64 instructions): queries *current CarPlay window scene* `carPlayWindowScene.coordinateSpace.bounds` (refs `0xb0ecc`, `0xb0eec`, `0xb0f24`), then `carPlayUIScreen.bounds` (refs `0xb0f9c`, `0xb0fbc`) or `carPlayCADisplay.bounds` with `pointScale` (refs `0xb1024`, `0xb1044`, `0xb10a4`). This is a real conditional native display/frame acquisition path, not one fixed 507.3pt rectangle.
   - Current `DFNativeHostAppDelegate.m:189-196` uses `CPWindow.frame` + `CPWindow.safeAreaLayoutGuide.layoutFrame` in the iPhone application process and transfers a serialized `ContentRect` by session plist to SpringBoard. `DFTouchOwnerProbe.m:378` separately obtains external `UIScreen.bounds` from `UIRootSceneWindow`. These represent **two potentially different coordinate spaces and owners**, not proved numerically equal.
2. **Native Dock inset is obtained from a different window**:
   - Original `CBWindow.carPlayContentInsets` IMP `0xb1370` (151 ARM64 instructions) reads cached or configured insets, otherwise the **actual native `activeCarPlayWindow.rootWindow.safeAreaInsets`** (refs `0xb1464`, `0xb1484`, `0xb14c0`); it has conditional fallback `0x4050000000000000 = 64.0pt` at `0xb1544` only when no positive inset was available. This is a fallback, NOT an unconditional original left margin of 64pt.
   - Current `DFNativeHostAppDelegate.m:190-191` uses an app `CPWindow.safeAreaLayoutGuide.layoutFrame` and **if it is empty, substitutes the entire `CPWindow.bounds`**. That can report zero left inset even when native CarPlay Dock still occupies the rail.
   - Current `DFTouchOwnerProbe.m:391-403` then imposes `safeLeft=screen.minX+MAX(42,screen.width*.082)` **unconditionally** on a valid `ContentRect`, or invents an outer content rectangle using that floor if not valid. This is **not** original's native `rootWindow.safeAreaInsets` readout or fallback. On user device it can move all panes farther from the Dock than the actual native usable edge, but the magnitude remains unmeasured.
3. **Single native geometry contract vs independent multi-stage geometry**:
   - Original `CBWindow.carPlayUsableBounds` IMP `0xb15cc` computes usable area from `carPlayScreenBounds` @`0xb15e8` and `carPlayContentInsets` @`0xb1604` with explicit floating-point additions/subtractions @`0xb1614..b1620`. `CBWindow.createWindows` @`0xb173c` consults screen/usable bounds @`0xb1bc0/b1ca8`; `CBWindow.resizeWindows` @`0xb24ac` consults both @`0xb24e8/b2508`; `CBBridgedSplitApp.layoutSplitViews` @`0x10bad8` references usable bounds @`0x10bb28`, then updates split children. Source-level geometry owner is internally consistent by reference.
   - Independent DuoFace `DFNative12Chrome.m:990-1001,1493-1499` creates **four** real external physical scene UIWindows at `contentRect.origin` from the **SpringBoard-clamped app-provided rect**, and separate host scene reference/YouTube layout phases run later. The physical pane x origin is whatever value survives the second hardcoded clamp.
4. **Render layout/frame agreement**:
   - Original `CBBridgedUIAppView.updateLayout` @`0xac7cc` has explicit `setFrame:` @`0xac8cc` etc and `setContentReferenceSize:...:` @`0xacb24/b5c`; `refreshSceneLayout` @`0xadc30` triggers UIKit layout. Current DuoFace synchronizes physical frame, remote scene reference and YouTube in separate owner/event phases, which can also be relevant to delayed touch but **not proven caused by the Dock gap**.

## What the binary comparison DOES and DOES NOT prove

**PROVEN:** DuoNavi 1.0.4 and DuoFace .118 have materially **different ways to choose screen geometry, source window, safe-area insets, fallback and pane origin**. We did NOT find identical sizing logic; the previous assumption that `CPWindow.safeAreaLayoutFrame` equals the original native Dock content inset is **false as a source identity claim**. The .118 extra floor is confirmed and real.

**NOT PROVEN from DEBs alone:** On the user's particular CarPlay display, the original `rootWindow.safeAreaInsets.left` numerical value, current iPhone CPWindow left inset, actual Dock rightmost pixel, and therefore the number of unwanted black points/pixels. Static ARM64 is **not a measurement**. One must not equate the original 64pt fallback to the car's actual Dock dimension, nor arbitrarily decrease the current 42pt to zero (the .117 Dock-hidden regression demonstrates why).

## Strict next concrete step, without a speculative visual patch

- **Only diagnostic / read-only first**: on the connected CarPlay display, record *in the same session and coordinate space*: native `activeCarPlayWindow.rootWindow.safeAreaInsets` (if accessible), `carPlayWindowScene.coordinateSpace.bounds`, Apple Dock's native view frame/right edge (if accessible), app `CPWindow.frame`, `CPWindow.safeAreaLayoutGuide.layoutFrame`, SpringBoard `UIScreen.bounds`, pre-clamp `ContentRect`, post-clamp `region`, and actual `appSceneWindows[0].frame`. Record owner/scene/session timestamp; never include personal data.
- **Do not change UI until these readings exist.** Remove the independent second margin only once a verified native root safe-area/owned Dock rail origin is available. If safe-area and Dock frame disagree, keep the Dock-visible fallback and document mismatch rather than covering it.
- Distinct device acceptance: Dock present immediately and never cropped; zero unintended black seam under same original-display setup; YouTube top/middle/bottom touch after idle; .90 orientation and .92 divider retained. GOFA voice A/B is a separate hypothesis requiring separate time-stamped evidence.

**No runtime code changed here, no new Sileo package or hardware PASS claimed.**
