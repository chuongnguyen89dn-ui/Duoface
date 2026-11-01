# QA164 — GPS `—` and split-pane-limited Speed8: source-proven diagnosis + device gate
Date: 2026-11-01. Project: independent DuoFace. Original CarPlayPro Speed DEB remains untouched.

## User observation (actual QA163 iPhone/CarPlay feedback)
1. HUD contains no speed data.
2. HUD in DuoFace only moves inside one split pane, not over the full DuoFace content.
3. Universal CarPlay Dashboard support is still requested, NOT confirmed.

## Root cause: why drag is pane-local (source-confirmed)
- QA163: `DFNative12Chrome.m:-refreshGlobalSpeedHUD163` picks an item from `appSceneWindows`, then `[ownerWindow.rootViewController.view addSubview:self.gofaSpeedHUD]`.
- Speed8 `DFNative8SpeedHUDView.mm:DFAllowedArea` used `self.superview.bounds` as the allowed drag rectangle, and `pan:` clamped `self.center` to it. That parent is one split pane's UIKit UIWindow, not the full CarPlay content.
- **Fix QA164**: DuoFace creates one extra **compact bubble-sized external UIWindow** with its original `makeWindow:` construction (the existing external-display contract), level 2.5 above app windows and below pickers. Its 104×46 HUD view moves the *window frame* across full `contentRect`, saved normalized position; no fullscreen transparent touch-intercepting layer, and no changes to the split-app windows or Apple CarPlay Dock. Settings panel temporarily expands only the same bubble window while menu is open; restores compact footprint at close. Actual on-device touch success still UNVERIFIED.
- Native CarPlayApp/dashboard path `DFSpeedNativeOverlay163.mm` remains unchanged, and requires real vehicle window/scene evidence to prove visible.

## Missing speed data: what source actually does (not yet runtime-diagnosed)
- QA162/163/164 **does not read GOFA internal speed/limit/camera data**, nor a CarPlayPro data adapter. `DFGofaSpeedSource162.m` creates an independent `CLLocationManager` *inside the GOFA app process* (Substrate plist only `com.lumi.GOFA`).
- Source starts only when location services enabled AND authorization always/when-in-use. It accepts nonnegative finite GPS speed, horizontalAccuracy 0–100m, timestamp age -2..+8s, converts m/s × 3.6, sends to `DFSpeedTransport.mm` Darwin notify.
- `DFSpeedProtocol.hpp` TTL: **5 seconds**. No periodic valid sample when GOFA is stopped/suspended, GPS returns speed<0, permission denied, location blocked or transport fails -> HUD `—`. Which actual reason on the user's iPhone is **unknown until live logs**. Road-limit `limitValid=false`; a traffic-sign limit is never inferred from speed.
- Added throttled source logs without user coordinates:
  - `[DuoFaceSpeed8] GOFA GPS source status auth=<status> services=<0/1> active=<0/1>`
  - `[DuoFaceSpeed8] GOFA GPS sample REJECTED fresh=... speedValid=... accuracyValid=...`
  - `[DuoFaceSpeed8] GOFA GPS IPC publication FAILED`
  - `[DuoFaceSpeed8] GOFA valid GPS speed publish, limit unavailable`
  - `[DuoFaceSpeed8] viewer NO_FRESH_SAMPLE source=GOFA ttl=5s process=...`
- Even after source becomes valid, the GPS readout alone is NOT proof that GOFA proprietary navigation speed-limit/camera/turn data is integrated. Don't claim feature parity or invent a value.

## Build and release evidence
- Source branch: `feature/duoface-qa164-speed8-fullscreen-drag-20261101`.
- Actual signed integrated package (one unchanged ID): `com.duoface.jb.embedded 0.0.164~globaldragtest1`.
- Signed source CI: [41304528724](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41304528724), source SHA `bbdf83e3593d44e2dd70a6ae175dbc6dde413855`, artifact commit `a4f4bf2e3c428e46d59988919cc658bbddf5f7d1`.
- SHA256: `ce8d49302619301188cf9862a73dcc90c7688ed28851278a4bab001f4d8694ca`.
- Receipt: `sideplay/jb-embedded-appbridge/evidence/runs/41304528724/{CI_RESULT.txt,SHA256SUMS.txt,PACKAGING_PROVENANCE.json}`.
- Sileo main publish commit `faa259d0f0cf04ce8b9aabab6619a4abd39e7ab0`, workflow [41304885379](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/41304885379), still running at this checkpoint; public availability must be checked again.
- No real device testing; prior QA163 remains rollback.

## Parked-car regression acceptance plan (to be filled with actual logs/screenshots)
1. Refresh **existing Sileo** source only AFTER public QA164 SHA verified; confirm installed exact version in Sileo.
2. DuoFace split 2 panes: HUD should be movable across dividing line **without dragging the divider or resizing apps**; other pane taps and YouTube controls remain responsive. Try 4 panes, SOLO, change positions, restart.
3. Native CarPlay Dashboard, Home, Maps, third-party CarPlay app: confirm one HUD visually, not zero/two, no Dock/Home interception. If missing, capture actual process external UIWindow / FBScene / z-order; not a static-source success.
4. GOFA with authorized location: observe GOFA GPS auth log, accepted/rejected samples, IPC, viewer TTL. No source = `—` is correct fail-closed; if a number appears, compare stationary and real movement safely.
5. Switch GOFA→YouTube→native Dashboard, lock/dim/reconnect: HUD stays displayed but GPS source may timeout to `—`. Never drive solely to test, collect diagnostics when parked / passenger.
6. Attach exact screenshots/logs and device/CarPlay iOS/software versions in this repo. Stop/rollback on crash, misrouted touch, CarPlay black screen or Dock regression.

**Status:** CAUSAL SOURCE AUDIT + SIGNED BUILD PASS. Public delivery gate pending; hardware test pending; GPS data adapter itself not fixed.

## Public Sileo release verified — 2026-11-01

- Signed QA164 project package SHA: `ce8d49302619301188cf9862a73dcc90c7688ed28851278a4bab001f4d8694ca` (see exact source+archive above).
- Existing `chuongnguyen89dn-ui/carplaydsp/main` release workflow commit `a7ace08bf40e15ae955fa2d7d91aad09838f095c`, YAML validation run `41305261246` SUCCESS, [Sileo publish+Pages run 41305261209](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/41305261209) **COMPLETED SUCCESS**. Build job `124844243086`, deploy `124844785844`, public DuoFace SHA verification `124844830442`, additional independent checks `124844830445` / `124844830501` all SUCCESS.
- Real public verifier emitted `DUOFACE_ONE_PACKAGE_PUBLIC_SILEO_INDEX_VERIFIED` and `/home/runner/work/_temp/duoface-public.deb: OK`, `DUOFACE_PUBLIC_SILEO_DEB_DOWNLOAD_AND_CHECKSUM_VERIFIED` (2026-11-01 12:13:48 UTC). APT has exactly ONE selected `com.duoface.jb.embedded` QA164 record with matching version/filename/hash, QA163 binary retained unchanged for rollback.
- First publish run `41304885379` failed due to **CI-only incorrect expected string** `[DuoFaceSpeed8] QA164 native owner attached` in publisher for the unchanged QA163 native-owner module; fixed publisher compare to actual `QA163` at commit `a7ace08bf40e15ae955fa2d7d91aad09838f095c`. No DuoFace binary rebuild or code change was needed for that failure.
- **No physical iPhone/car test, no verified drag or real GOFA data.** Success is publication and byte-identical package checksum, not a result of hardware validation. Continue the acceptance plan above.
