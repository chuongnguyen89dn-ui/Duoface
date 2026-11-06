# QA177 A2 — CarPlay physical acceptance (NOT TESTED YET)

Source baseline: DuoFace repo `chuongnguyen89dn-ui/Duoface`, branch `fix/qa180-owned-wake-map-replace-20261106`. Pre-sign verified CI `42193156605` PASS on A1 source `ec5c2ad40e439405f6d314b4269d30d39bba1eea`. Isolated candidate workflow `42193994412`, prepare SHA `e8449cbb9e457f97bc4fe4ac64445a3669b205f2`, integrated version `0.0.177~a1wake1`. Candidate build SHA256, Sileo status and actual device verdict PENDING at time of document creation.

## Safety / prerequisites

- Use only a **verified signed candidate with recorded source SHA, DEB SHA256 and package version**, not a source/test-only CI artifact. Do not install until package audit PASS and DEB bytes match checksum. Keep immutable QA174/175/176 rollbacks. Do not assume uploading an Actions artifact made it available on Sileo.
- Test stationary/parked. Use same iOS16.7.16 + exact CarPlay head unit conditions as LOG5 when possible. Record connection/session UUID, display resolution, current installed version `dpkg -s com.duoface.jb.embedded` and actual DEB hash. One candidate per capture; avoid mixing QA176 and QA177 lines.
- The agent has no physical vehicle access. **DEVICE_TESTED=false** until actual car/phone evidence arrives. These are instructions and acceptance gates, not claimed observations.

## A2 procedure — test 3 full hide/wake cycles PER source

1. Open DuoFace and two hosted apps (YouTube + GOFA where supported); wait at least 4–5 seconds for logo artwork to fade. Record `qa179-logo-idle-red-border-hidden-visual-only`, phone session owner and A1 wake state.
2. **Direct logo target:** with logo visually hidden, touch its remembered position (including a finger move). It must ONLY reveal logo. No `action=SWAP`, `swap-button`, `divider-axis-locked-ratio`, `divider-pan-begin`, `divider-axis-locked-logo-vertical-no-hold` for that gesture. Expect `qa176-a1-direct-logo-hidden-contact-reserved` then `qa176-a1-direct-logo-wake-ended-no-swap`; independent second contact may SWAP or drag deliberately.
3. **Bare primary/secondary divider:** hide artwork, start actual pan from the divider strip; the entire FIRST contact may only wake, not change ratio or logo coordinate; markers `qa176-a1-divider-hidden-gesture-reserved` / `qa176-a1-secondary-hidden-gesture-reserved` and corresponding `gesture-ended-no-resize`. SECOND gesture when visible moves split normally. Include cancellation/disconnect and re-entry to avoid stuck pan owner.
4. **Hosted app pane:** with YouTube/GOFA scene live, hide logo and tap inside *app content*, not the logo/divider, 3 times independently: first contact wakes chrome but **must not** start YouTube controls, play/seek, GOFA button or scroll; second independent contact must reach actual app. Expect `qa176-a1-host-wake-received`, `qa176-a1-host-wake-visual-state alpha≈1` and `qa176-a1-relay-scene-diagnostic match=1`. Check `wakeStateReadable=1` if exported. Do not count `DF156Write` or `notify_post` as visible success without host and car observation.
5. **Negative controls:** touch same app on iPhone while CarPlay hosted (must not be swallowed); open keyboard in YouTube/GOFA/hosted app and type normally while chrome hides; keyboard show/unknown must fail-open; test two simultaneous fingers, touch cancellation, Home→return, focused/fullscreen state and relayout. If any capture blocks typing or another scene, A2 FAIL.
6. Repeat 3 hide/first/second cycles **per path** after reconnection; no stale scene/PID/session, no Chrome stuck visible and no unexpected SWAP. Preserve original 4-second hiding behavior.

## Required evidence and verdicts

- **A2_DIRECT_LOGO**: PASS only if raw contact IDs and visible screen state show first hidden contact wake-only, with `SWAP` absent for same ID, and next visible gesture functions.
- **A2_DIVIDER**: PASS only if first hidden gesture leaves ratio/logo position unchanged and the second moves as intended.
- **A2_HOSTED_APP**: PASS only if first hidden content touch wakes logo without app action, next app action succeeds, and scene identity/receiver/visual markers are correlated for the same session.
- **A2_PHONE_KEYBOARD**: PASS only if negative controls all preserve typing/touch.
- **A2_OVERALL** requires ALL four plus 3 cycles; any unsupported/absent markers and no visual observation -> `UNVERIFIED`, NOT PASS.
- **B1_NATIVE_MAP_LOGO** is a distinct **future** hard gate after native Maps is integrated into one pane: cannot inherit A2 hosted-app PASS. First touch on Maps native wakes only, second pan/zoom works, DuoFace foreground remains visible. Roster/picker Home icon and tiles/touch remain separately required.

## Recording / next steps

Capture next raw DuoFaceAudit export with version, UTC timestamps, logical window/FBScene ID, PID, input target (logo/track/app), per-contact IDs and visual observations. Do not accidentally use `DuoFaceAudit 4.txt` when `DuoFaceAudit 5.txt` is the current prior baseline. Add `RESULTS.md` after a real run with IDs, metrics, pass/fail/unknown, exact head & archive checksum. A failure must point to exact gesture markers and no-go rule before any new release.

Status at creation: `A1_SOURCE_CI=PASS`; `QA177_SIGNED_DEB=PENDING`; `A2_DEVICE_TESTED=NO`; `B1_NATIVE_MAP_DEVICE_TESTED=NO`.
