# Log25 — native Calendar/Music vs bridged-app Home exit

## Scope and pinned inputs
User specifically asks to inspect Calendar/Music exit and compare non-CarPlay apps. Read central Gpt-training- SKILL_INDEX/AGENTS/DEB_IPA and ZIP01/02/05 instructions/references in this turn. Main input `sideplay/log/DuoFaceAudit 25.txt`, main commit `7f69f521a69005e0b9bdcd4531a297f2151e6fb6`, blob `8e452cc8c1abc60cc85edccf557de2e1f86dca95`, 5,394,970 bytes, SHA256 `46270f9867ca55c51f26ad8bbcf1a731b2c16fd6fe276442e0c4bb65f7aad9eb`. Export timestamp 2026-11-01 02:51:19Z /09:51:19 ICT. Latest standalone receiver session starts09:47:28.270 ICT. Older retained sections are NOT current-session evidence.

Feature branch checkpoint read: `9f738e6475f4de07127b6065a3d0cae6cd930459`. Fresh source readbacks:
- DFCarPlayOwnerObserver.h blob `7fe060ca5229a1f723b1145215cbf21a9ff052f6`.
- DFNativeDockSync147.h blob `68b2a04b552878ab4e8b7a2a1f69830790189fb4`.
- DFHomeStandalone144.m blob `c64dad56a1ca6fa16d3d742be5a6caa65110f7da`.
Original-static reference re-read `sideplay/audit/original-execution-route-20261031/ROUTE_FINDINGS.md`, especially genuine Home hook and teardown. No original binary execution or new device observation.

## Confirmed current-session bridge evidence
Eight request transactions: Safari3, Facebook2, YouTube2, Wyn1. All8 receive manager live-scene/PID/hosted observations, native Dock active, stop `native-Home-exit`, native Dock restored. No latest-session attach failure/timeout stage. This supersedes earlier *zero app-side ACK* evidence for this session ONLY.

62 host-received general app-side ACKs: Safari40, Facebook22. Five `restored` receipts: Safari3 and Facebook2. Safari third request has `window-adjusted count=1` followed by `restored count=1`. Other restored count0 means no owned window overrides needed restoration; it is NOT a failed restore indicator. YouTube uses its dedicated relay, so no general ACK is expected. Wyn is outside the exact14 generic injected bundle filter, so its missing generic ACK cannot be presented as a transport failure.

| App / request prefix | Home->stopped ms | Home->Dock restored ms | General ACK count | Restored count |
|---|---:|---:|---:|---:|
| Safari 94937D30 | 101.000 | 85.000 | 18 | 0 |
| Facebook B0B1C87C | 36.914 | 112.914 | 15 | 0 |
| Safari 110774BC | 33.314 | 105.314 | 5 | 0 |
| YouTube 0BEA6665 | 47.429 | 154.429 | 0 | dedicated relay |
| Safari 1E20D6CA | 48.272 | 129.272 | 17 | 1 |
| YouTube 3E91303F | 94.996 | 159.996 | 0 | dedicated relay |
| Facebook C3CEA069 | 11.508 | 48.508 | 7 | 0 |
| Wyn 4336DC07 | 43.143 | 136.143 | 0 | outside generic filter |

Timing derives from source-section timestamps, precision milliseconds. Dock can reset before final SpringBoard stop log because they are independent asynchronous subscribers. Every stop correlates to a physical Home pulse within0.5s. Total17 timestamped Home pulses in latest DeepTrace;8 correlate to bridge stops,9 remain unattributed. Do not label those9 as Calendar/Music or second-press corrections without app identity.

Example Safari request1E20D6CA at09:49:55: scene ownership/manager and Dock active;09:49:57 window-adjusted count1. At09:50:05.227728 Home stop posted; .229 host sends lease revoke; .265 scene invalidated; .276 stopped; .291 app-side restored count1; .357 Dock restored. Exact line references in EXIT_EXCERPTS.txt (original Log25 line numbers). ACK does not prove pixels/touch/Home destination or icon animation.

## Comparison: proven source behavior vs unavailable native-app trace

| Boundary | Native Calendar/Music | Bridged Safari/Facebook/etc |
|---|---|---|
| App-specific log identity | NO Calendar/Music bundle or class event in Log25. Cannot trace a named native app exit. | Exact request/bundle/scene identities recorded. |
| Common Home hook | Source forwards saved Apple `homeButtonUp:` exactly once. The hook posts standalone stop even when no standalone request is active; in that case there is no bridge terminal response. | Same immediate Apple callback, plus asynchronous standalone stop and Dock reset subscribers. |
| App scene cleanup | Native workspace lifecycle is Apple's; its actual per-app transition is NOT captured here. | SpringBoard: app lease revoke -> hide external window -> release hosted scene -> stopped result. App restores its changed windows. |
| Dock/Home state | Apple owns native state. No current native app-labelled before/after values available. | `DF147RestoreDock` writes saved previous active bundle and captured `DF147HomeBefore`, refreshes Dock; Log25 shows it48.5–160ms after pulse. |

Whole-text scans find ZERO `com.apple.mobilecal`, `com.apple.mobileipod`, `com.apple.Music`, Calendar/Music/DBCalendar identifiers. `DBNowPlayingWidgetViewController` occurs only in21 retained older owner snapshots (around Oct29), not a current Music-app Home exit. This log therefore cannot prove exactly how Calendar and Music returned to a Home page or Dashboard, nor equate unidentified Home gaps to those apps.

## Concrete ordering gap / bounded hypothesis
`DFOwnerDBHome` calls `DFOwnerHomeReceived`, then immediately calls the saved Apple original. `DFOwnerHomeReceived` only `notify_post`s standalone stop. Separate main-queue Darwin listeners later call SpringBoard `stop:` and CarPlay `DF147Reset`. The latter restores **a pre-bridge saved** active app and Home display state. Thus local Dock/Home restore does not happen inline before Apple's callback; it can write state after Apple processed Home. Log25 corroborates a later asynchronous restore, but does NOT measure Apple's original callback entry/return, Home displayState values, folder/page or native foreground scene.

This creates a specific stale-state/ordering hypothesis for the user-visible different Home exit: restoring a captured in-app state after native Home may override current state. It is NOT proven root cause and NOT evidence to suppress Apple's Home callback. Original DuoNavi static audit also forwards the Apple original unconditionally after a manager-stop call; whether its remote teardown completes before original is not established. Do not invent synchronous original behavior.

## Reproduction and exact next evidence
Actual commands used from workspace: `git -C Duoface fetch --depth=1 origin main`; `git -C Duoface show 'FETCH_HEAD:sideplay/log/DuoFaceAudit 25.txt' > /tmp/duoface-log25.txt`; hash and parse full file. Reproduce pinned input:
```
git show '7f69f521a69005e0b9bdcd4531a297f2151e6fb6:sideplay/log/DuoFaceAudit 25.txt' > /tmp/duoface-log25.txt
python3 sideplay/audit/qa156-log25-exit-comparison-20261101/analyze_log25.py /tmp/duoface-log25.txt --expected-blob 8e452cc8c1abc60cc85edccf557de2e1f86dca95 > /tmp/exit-analysis.json
```
Parser output EXIT_ANALYSIS.json and relevant raw source lines EXIT_EXCERPTS.txt. Independently asserted8requests/62ACKs/17pulses/9unattributed and all3 native bundle counts0. Exporter's diagnostic build string0.0.90 is historically fixed; do NOT infer package downgrade from it. Exact currently installed package revision still not directly read by exporter.

Next comparison must identify active native bundle (Calendar/Music), native scene/workspace owner and Home button displayState **before/after the same Home callback**, plus saved DF147HomeBefore and restoration timestamp. Existing native Dock owner ABI checks should be reused, no guessed methods/global hook. Correlate bridged request or explicit absence with native app identity. Verify whether cached restoration overwrites Apple's result before changing it; do not block original Home based only on destination symptoms.

This turn changes analysis/handoff only. No runtime patch, new DEB, build or Sileo release; existing nativebridge3 remains public. User asked to compare evidence, and current evidence does not justify a speculative behavior patch or claim exact Calendar/Music parity.
