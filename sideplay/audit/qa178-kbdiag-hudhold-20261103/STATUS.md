# QA178 STATUS — kbdiag round 3 + HUD exit hold

- Branch: `feature/duoface-qa178-kbdiag-hudhold-20261103` (from QA177 tip `062c708e`).
- Integrated: `0.0.178~kbhud1`; host: `0.1.178~kbhud1`.
- Implementation commit: `93d93f8d91a5bf036b161fed8721a363fccb9c21`.
- Fixes after first CI attempts: workflow branch filter `cb61c8475cb90f7739df9be14d41ce5bcef9be5b`; relay DF154Object C-string getters `6befad7d457da2bdef3a71b98ae64a937fd7aa62`; QA178 test assertion `07fb0c973ae353990bbc88de0710f2d2f0c0d729`.
- Private build run: `41557631891` — SUCCESS (verified directly through the Actions API).
- Archive commit: `75d496c790a1f05f44efc7dbf12e4f7b24f9b880`.
- DEB: `com.duoface.jb.embedded_0.0.178~kbhud1_iphoneos-arm64.deb`, 1,273,420 bytes, SHA256 `5f4ecb0d10eb5205909f2e5aaa9a764390a1f5f6e14da839a7e7871fe4126c7a`.
- SILEO_PUBLISHED=true (2026-11-03, Nguyen approved). Publisher commit `5534b504b3ae79ff6b4a929ac795512f1cb816a2`, publisher run `41558568255` SUCCESS (all 5 jobs); public index independently verified: exactly 1 stanza `0.0.178~kbhud1`, SHA256 `5f4ecb0d10eb5205909f2e5aaa9a764390a1f5f6e14da839a7e7871fe4126c7a`, Size 1273420. DEVICE_TESTED=true (2026-11-03, see verdicts below).

## H1 — keyboard diagnostics round 3: DONE, behaviour unchanged
- `DF154GeneralAppStateRelay.m`: window enumeration now merges the two public lists with the guarded private `+[UIWindow allWindowsIncludingInternalWindows:onlyVisibleWindows:]` (`respondsToSelector` + @try/@catch).
- Keyboard search prefers a non-hidden Keyboard-class window and falls back to any Keyboard-class window.
- Accepted `UIKeyboardDidShowNotification` captures immediately and once more after `kDF178KBDelayedCaptureSeconds = 0.3`.
- Keyplane lookup no longer depends on finding the window: fallback through `UIKeyboardImpl.activeInstance` and its layout-star getters, read-only and guarded.
- Record/log fields added: `late`, keyboard screen-space frame, keyboard transform, app-perceived sizes (`main`, key-window, scene), and a capped compact all-window dump (max 10 windows, dump truncated at 880 chars to stay within the DF156 2048-byte mailbox budget).
- Chrome logs the added fields on `qa178-kbdiag2` and gains a fallback host-transform lookup through Chrome's own hosted surfaces when `hostViewForBundleID:` returns nil.
- No keyboard behaviour hooks: no keyplane/input-mode/width/hardware-keyboard changes.

## H2 — HUD exit hold: DONE, branches 2 + 3 used
- Step-0 point found in our own code: `DFTouchOwnerProbe`'s `DFStopProbe` calls `[sChrome hideAllExternalWindowsImmediately]` before `[old stop]`.
- Added unconditional one-line `qa178-hud-gate` logging at `deactivate` (in `DFStopProbe`) and at the head of Chrome `-stop`, with all four old gate values, snapshot age, Chrome-lease freshness and overlay-record freshness.
- Branch 2: `hideAllExternalWindowsImmediately` excludes the speed HUD window while the pre-hide snapshot says the HUD is up.
- Branch 3: the lease heartbeat stamps `hudWasVisibleAt176` whenever the Chrome HUD is visible; `-stop` decides handover from `hudLease176Published` OR a snapshot no older than `kDF178HUDSnapshotFreshSeconds = 2.0`, without trusting the current hidden flag.
- On handover, Chrome re-shows the stashed HUD window, removes it from the mass-hide list, publishes the Retiring lease immediately before hiding the other windows, and retains the QA177 tick/finish logic with the existing ~4s maximum.
- Limit ring + red X unchanged.

## Scope kept / untouched
- `DFSceneHost.m` untouched (frozen digest preserved).
- `DFHostedMapRenderSize.h` untouched.
- GOFA decoder remains shadow; HUD speed remains GPS; QA175 T1/T2, QA176 lease and QA177 mechanisms retained.
- Conflicts/Replaces verified complete from the built DEB control.
- postinst md5 `5d016787d5af05ce8a353942f1dfa091`, postrm md5 `eddecdc6cbe35384fd72bf23a831d801` — byte-identical to QA177.
- Binary markers verified in the built package: `build=0.0.178~kbhud1`, `qa178-hud-gate`, `qa178-kbdiag2`, the private all-windows selector in the DF155 relay, and the retained `qa177-hud-handover` / `qa177-app-touch` markers.

## Device tests owed after Sileo publish approval
1. Waze full-screen -> search -> keyboard photo -> export log immediately.
2. Google Maps in a pane -> same.
3. Exit DuoFace while the speed HUD is visible -> check whether the HUD still blinks -> export log.


## Device verdicts (2026-11-03, export 08:25 VN, DuoFaceAudit 4.txt on main bb6e32b7; 471 lines build=0.0.178~kbhud1)

DEVICE_TESTED=true.

### H2 — PASS (designed path), user-confirmed improvement
- 3 exits captured with `qa178-hud-gate` at BOTH points. Exit with the Chrome HUD up: deactivate `pub=1 hidden=0 wasAge=0.64`, stop `pub=1 hidden=0` (branch-2 exclusion held: the probe's mass hide did NOT hide the HUD window), then `qa177-hud-handover start max=4.0s pub=1 snapshotAge=0.65` -> `done=overlay-visible waited=0.25s`. First log proof the QA177 handover engages and completes.
- Other exits had no Chrome HUD up (pub=0) and correctly took no handover; overlay attached 12x / detached 11x, all `reason=native-fallback`.
- Nguyen: HUD flicker "relatively fixed". Residual blink, if any, is on the overlay fallback path, not the handover path.

### H1 — PASS (diagnostics delivered), keyboard behaviour unchanged by design (user confirms)
- kbdiag round 3 sees the keyboard: 10 records `kbClass=UIRemoteKeyboardWindow`, incl. DidShow captures and `late=1` delayed blocks.
- Keyplane measured for the first time: `1510_PortraitTruffle_iPhone-Alphabetic-Keyboard_Capital-Letters` — NORMAL letters keyplane, not nil/wrong.
- Window dump (Google Maps process): `UIRemoteKeyboardWindow` frame/bounds {414,736}, level 10000001, transform IDENTITY; app key window (AZWindow) {397,685} or {595,685}; `UITextEffectsWindow` {414,736}.
- App self-perception: `UIScreen.mainScreen.bounds` = {414,736} while the app window is {397,685}. Host facts via the Chrome fallback worked (`src=fallback`, hostT scale 0.500/0.500).
- MEASURED mechanism: the app IS resized to the pane-derived window size, but the keyboard window is sized from `UIScreen.mainScreen` (the phone's 414x736), so the keyboard is wider/taller than the app window it must fit; presented through the 0.5 scene scale it overflows and its bottom rows (anchored at y=736 in a 685-tall presented space) clip. This matches the original's `keyboardScreenReferenceSize`/`fixedKeyboardWidth` target exactly.
- Only Google Maps produced kbdiag records this session; Waze keyboard still unmeasured. Some DidShow records still show kbClass=none (mailbox latest-value overwrite between WillShow/immediate/late captures is the likely cause; the found records carry the full field set).
- QA179 input: the proven fault is the keyboard reference size only — keyplane, input mode and hardware-keyboard signal are all normal here, so a future keyboard layer can be minimal (reference-size/width correction in the app process) rather than the original's full 5 groups.
