# QA143 design decision — Make *selected* CarPlay Home icons launch a verified DuoFace-hosted iPhone app (2026-10-31)

## Decision, grounded in real Log21, NOT an implemented fix

Target **only** `chuongnguyen89dn-ui/Duoface`, current branch `feature/duoface-qa142-home-abi-20261031`; public signed rollback QA142 `0.0.142~homeabi1`. User confirmed six selected app icons visible on genuine CarPlay Home but tap does not open an app. Do not introduce a second fake CarPlay app or override Apple native app launches. Work only when parked/test controlled.

### Why just calling UIApplication/openURL/uiopen does not solve it

An ordinary iPhone app without the requisite CarPlay scene cannot be assumed to launch a full-interactive CarPlay scene merely because its icon is admitted to Home. The OS native Home launch targets the CarPlay workspace; `uiopen` targets the phone. Comparable independent research: `https://github.com/pavunato/carsurf/blob/main/sbtweak/CSCarLaunch.m`. However, that reference expects `DBApplicationController.sharedInstance/applicationWithBundleIdentifier:` which were both **absent** in the actual user QA142 ABI. Do not transplant its methods or claim compatibility.

DuoFace already has the **real remote iPhone UI host** inside SpringBoard: `DFSceneHost hostViewForBundleID:error:`, `DFNative12Chrome appPicker:didSelectBundleID:displayName:`, `sceneReady:` / `sceneFailed:` and `DFTouchOwnerProbe` external windows. These are the target renderer/scene, NOT the Dashboard icon itself. But the owner is `sChrome` in SpringBoard and exists only after a verified active DuoFace CarPlay template scene. `DFNativeHostAppDelegate.m` **explicitly refuses to start the host while Home is foreground**: `startTouchOwnerForScene:` checks `scene.activationState==UISceneActivationStateForegroundActive`, then creates a fresh lease and emits `com.duoface.nativehost.touchowner.start.v1`. This is an essential bootstrapping gap for clicks **outside** DuoFace.

### Two-stage, original/native-preserving bridge

```text
Actual CarPlay Home tap (CarPlay process, iOS 16.7.16)
  DBDashboardHomeViewController
     iconManager:launchIconForIconView:  [v32@0:8@16@24, REAL ABI LOG21]
       |-- Apple/native/unselected/consent-off/unknown icon -> ORIGINAL once
       '-- allowlisted ordinary iPhone app:
              | get exact app bundle id from live iconView/application object
              | bind fresh request ID, session, max 2-second age; deny stale/replay
              | save request to DuoFace-owned atomic preference; Darwin notify
              | obtain the REAL system Dashboard owner's live DBWorkspace
              | activate the genuine D u o F a c e host CarPlay app object
              |   (not ordinary third-party app; NO fake DBApplication)
              '-- do not report success until next steps
                           |
DuoFaceNativeHost (CarPlay scene delegate, system-issued CPWindow)
  sceneDidBecomeActive -> real owner/session heartbeat, not Home/foreground spoof
                           |
DFTouchOwnerProbe (SpringBoard)
  verify session + fresh UUID and same request/consent/selected bundle
  -> DFNative12Chrome's real scene choice (extract UI-independent method)
  -> DFSceneHost hostViewForBundleID:error:
  -> actual remote sceneReady: / sceneFailed:
  -> ACK = live scene/verified bundle and process, not merely notify delivered
                           |
CarPlay Home/Back or disconnect
  invalidate UUID; cancel outstanding; tear down/restore Dock exactly as QA142.
```

A native application on Home must be forwarded to the original handler exactly once with no other method or global entitlement changes. For a selected third-party icon, do not intercept until both real app identity and a verified native DuoFace host activation route are available; otherwise fail **open to the original**, not to a black screen. If the selected app is already hosted and live, use its existing physical slot/reentry rather than create another scene.

### Specific ABI, discovery and implementation gates (do NOT skip)

1. **Home selector confirmed**, no further blind old-class guesses: `-[DBDashboardHomeViewController iconManager:launchIconForIconView:]` exact `v32@0:8@16@24` in Log21. The other overload `iconManager:launchIcon:` is absent. Add only ABI-exact method hook inside **CarPlay process**; inspect typed `iconView`/application identity, do not guess ivar names or call KVC. Native original must be called once. User opt-in `DFHome140Enabled()` + `DFPickerAllowsApp` on both IPC ends. Use kill switch and bounded per-request logging. Do not touch `DFHomeAdmission141.m` entitlements — old QA138 entitlement-hook recursion killed CarPlay in three historical crash IPS.
2. **Live dashboard workspace**, not just a class: `-[DBWorkspace initWithOwner:]` type `@24@0:8@16`; only capture a weak workspace when the owner is **`DBDashboardWorkspaceOwner`**, not an instrument-cluster workspace. `-[DBWorkspace requestStateChange:]` type `v24@0:8@16`; `-[DBMutableWorkspaceStateChangeRequest activateApplication:]` type `v24@0:8@16`. Still missing: genuine existing **DuoFace host app object**, actual current method to get it in iOS16 Dashboard, and observable Home/request outcome. Do not construct bogus DBApplication and do not send requests until these are proven. A real Home click on DuoFace itself can be used to capture the app object, but only if safe readback and lifetime are verified.
3. **Real first-party host startup**: preserve `DFNativeHostAppDelegate.m` active-scene check, `DFCarPlayOwnerLease`, `DFTouchOwnerProbe.m` session generation/expiration. Never manufacture Active=YES to bypass the foreground gate.
4. **Once host actually active**, wire the already-existing `DFNative12Chrome.m` selection implementation into an independent `requestHomeBundleID:` method. Do not call picker UI delegate with a fabricated picker. Reuse its exact `hostViewForBundleID:error:` and `sceneReady:` / `sceneFailed:`, preserving old scene until verified replacement. Selected app should be shown as solo/full pane according to user choice without stealing global Dock. Validate click/touch/video only from physical test.
5. **Tests:** source ABI positive/negative; enabled/disabled app; native Apple app pass-through *once*; unknown icon fallback; duplicate icon taps/idempotent; consent off/killed; stale UUID/disconnect; host never became foreground; native DBWorkspace missing; user app scene failure leaves Home intact; multi-window/cluster workspace not hijacked; rollback to public QA142; GOFA resizing, YouTube QA90, native Dock/BKS/lock baseline. Build macOS signed arm64 rootless DEB only after tests. Publish to Sileo only if signed CI and regressions pass. Physical proof requires selected Home tap -> DuoFace scene became active -> SpringBoard app sceneReady + same bundle + touch works, and Home/Back restores native Dock.

### Evidence and state

- User Log21 SHA256 `45408726bce40fcf7193c615968891dddad1f86ea5a2146324d81617bf876ac1`; reproducible parser in `sideplay/audit/qa142-log21-home-click-20261031`; run `41176289183` PASS.
- Source to change `sideplay/duoface-native-scene-host/{DFHomeLaunchABI142.m,DFTouchOwnerProbe.m,DFNative12Chrome.m,DFNative12Chrome.h,DFNativeHostAppDelegate.m,build.sh}`; add a separate scoped Home tap receiver and IPC contract as necessary. Existing actual rootless modules in nativehost`/build.sh`.
- No code hook, no activation, no QA143 DEB, no Sileo update, no new iPhone run was performed by **this decision document**. The real first-party host app activation method still requires evidence; don't fake it.

