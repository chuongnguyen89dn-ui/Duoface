# QA172 — Clean-room GOFA payload decoder: design and gated plan

Date: 2026-11-02. Branch: `feature/duoface-qa172-gofa-payload-decoder-20261102`
(based on QA171 tip `cad8d7d1`). Evidence base: `FIELD_MAP.md` in this
folder. Status flags for this whole QA: `DEVICE_TESTED=false`,
`SILEO_PUBLISHED=false`, nothing in this document is a device result.

## Decision (user-authorised 2026-11-02)

Method 2 only: DuoFace learns to read GOFA data itself, following the
*mechanism* the original product proves works (in-process NSNotification
observation + reflection-based payload extraction + normalised transport +
existing DuoFace HUD). The original binary is **not** incorporated,
loaded, linked or redistributed; no vendor code/assets/strings are copied.
Only interface facts (names, keys, shapes) from `FIELD_MAP.md` are used —
they are recorded there with instruction-level evidence.

Explicitly rejected (recorded 2026-11-02, do not revisit): bundling or
side-loading the original `SpeedAlerts.dylib` — it would keep the data
locked inside the vendor collector anyway (no export path exists), would
double-render overlays, and would redistribute a commercial binary with
its own activation system.

## Why the success probability is now high (and where it is not)

Already in place, verified in current source (QA171 tip):

- The GOFA-process seat exists: `DFGofaSpeedSource162.dylib` filter is
  exactly `com.lumi.GOFA`, and the build already compiles
  `DFGofaTrafficNavProbe166.m` into it (`build.sh` line 61). The probe
  already receives the real `NSNotification` objects for the three proven
  names — only value extraction is missing.
- The speed protocol already carries a limit: `DFSpeed::Sample` has
  `speedKmh/limitKmh` + validity bits, `Encode/Decode` validate ranges
  (speed <= 400, 0 < limit <= 200, freshness 5 s), and
  `ChooseUnifiedSample` prefers a complete sample from one source and
  never mixes one provider's speed with another's limit. The HUD view
  already renders a limit ring when `limitValid` is set.
- The only reason no limit flows today is a deliberate guard in
  `DFSpeedTransport.mm`: `DFSpeedHUDPublish` rejects `hasLimit == YES`
  ("GOFA GPS does not provide a verified road limit"). A board-sourced
  publish entry point removes exactly that guard for board data only.
- A Darwin-mailbox pattern for cross-process payloads already exists in
  the project (`DF156DarwinMailbox.h`, `DF167GOFAEventProtocol.h`).

Not yet proven (the honest residual risk):

- Whether the notifications fire, with the `push*` `userInfo` keys, in
  the GOFA build on the user's iPhone X (QA171's whole purpose).
- Whether the payload values are Swift model objects (needing Mirror) or
  plain dictionaries on that build. The probe's `userInfo` schema log
  (keys + value classes) answers this before any decoder ships.
- `userSpeed` vs `speed` display semantics/units (see FIELD_MAP §5).

## Architecture (all new code is first-party)

```
GOFA process (DFGofaSpeedSource162.dylib, filter com.lumi.GOFA only)
  DFGofaTrafficNavProbe166 (existing observer, 3 notifications)
        |  NSNotification (object + userInfo)
        v
  DFGofaPayloadDecoder172.swift  (NEW, Swift, no dependencies)
    - structural, name-agnostic: Mirror-based object -> [String: Any]
      conversion written from scratch (bounded: depth <= 3,
      children <= 64, points <= 32), plus direct NSDictionary path
    - speed: userInfo["pushSpeedBoard"] -> fields
      {userSpeed, speed, currentAllowSpeed, limit} (all optional,
      numerically validated, finite, range-checked)
    - alerts: userInfo["pushNextBoard"] /
      userInfo["pushOtherBoardToCarplay"] -> array of points
      {identity, sign, latitude, longitude} (lat/lon range-checked)
    - type names are LOGGED as evidence, never hard-required:
      structural validation decides acceptance (survives GOFA renames)
        |
        +--> shadow log (sanitised: classes, keys, value ranges,
        |    distance buckets; NEVER raw coordinates/route data)
        +--> DFSpeed board publish (speed + limit)   [gate G3]
        +--> alert mailbox plist + Darwin ping        [gate G3]
CarPlay/SpringBoard processes (existing owners)
  DFSpeedTransport read + ChooseUnifiedSample (existing)
  DFNative8SpeedHUDView (existing; limit ring already implemented)
  alert reader (NEW, small): freshness <= 10 s, max 8 points,
  nearest-first, distance computed/validated host-side
```

Swift is required for exactly one reason: the payload models are Swift
classes, and labelled-property reflection (`Mirror`) is a Swift stdlib
facility — the same public technique the original uses, re-implemented.
The Swift file is compiled by the existing macOS CI (Xcode toolchain)
into the GOFA dylib; the on-device GOFA process already hosts Swift
runtime code. If CI Swift integration fails, the fallback is the
NSDictionary-only path (works iff the runtime log shows dictionary
values) — the gate order below makes that decision with evidence, not
hope.

## Safety rules (non-negotiable, from project history)

- Decoder runs **only inside the GOFA process**. Worst-case crash blast
  radius is the GOFA app, never SpringBoard/CarPlay owners (the 2026-10-26
  +440 crash history is why nothing new goes near scene settings).
- No new method swizzling. Observation only, like the existing probe.
- Every reflection/cast step is checked; malformed payload = drop sample,
  increment a reject counter, never crash, never fabricate a value
  (project rule: no synthetic fallback — a missing limit stays "—").
- Throttle: decode at most 2 samples/sec/channel; stale data expires
  (speed 5 s per existing protocol; alerts 10 s).
- Privacy: logs never contain coordinates, route or address data —
  the QA166/167 sanitisation rules carry over unchanged.
- HUD publishing stays behind a default-off flag until gate G3 passes.

## Gates (each gate must pass before the next starts)

- **G0 — static field map.** DONE 2026-11-02: `FIELD_MAP.md` in this
  folder, instruction-level evidence for names, keys, shapes, outputs.
- **G1 — runtime shape evidence.** From the QA171 device log (user runs
  GOFA, exports log): confirm (a) notifications fire, (b) `userInfo`
  contains the `push*` keys, (c) value classes (Swift model vs
  dictionary), (d) GOFA build identity. *No decoder code ships before
  G1.* If the keys are absent on this GOFA build, stop and re-plan —
  do not guess alternative keys.
- **G2 — decoder core + host tests.** Implement
  `DFGofaPayloadDecoder172.swift` with synthetic stand-in models on the
  macOS host (same Mirror mechanics), unit tests for: all four speed
  keys, missing keys, wrong types, out-of-range values, alert arrays,
  oversized inputs, malformed identities. CI green required.
- **G3 — shadow integration (private build only).** Wire the decoder
  into the GOFA dylib in shadow mode: decode + sanitised log, HUD
  publishing flag OFF. Device check: log shows decoded boards/points
  whose ranges match what GOFA's own UI shows at the same moment
  (parked + a short driven segment). This is also where `userSpeed` vs
  `speed` semantics get settled by observation.
- **G4 — transport + HUD.** Add the board publish entry point (limit
  allowed for board source only), alert mailbox + reader, flip the flag
  in a private build. Device acceptance: HUD speed/limit/alert vs GOFA
  UI on a road with a known limit and a known camera; no synthetic data
  at any point.
- **G5 — release decision.** Separate explicit user authorisation for
  any Sileo publication, after the installed-package conflict inventory
  (standing rule from QA170/171). Keep QA170 as rollback.

Maneuvers/turns are **out of scope** for QA172 v1 (the Flutter-channel
lead in FIELD_MAP §4 is a separate investigation). Speed + limit +
road-alert points are the v1 target — that is the data the original's
notification route demonstrably carries.

## Files planned (no code written yet — gates G1/G2 first)

- `sideplay/duoface-native-scene-host/DFGofaPayloadDecoder172.swift` (new)
- `sideplay/duoface-native-scene-host/DFGofaPayloadDecoder172.h` (ObjC bridge)
- `sideplay/duoface-native-scene-host/DFGofaBoardSource172.m` (observer glue,
  supersedes the type-only summariser path of the QA166 probe)
- `sideplay/duoface-native-scene-host/speed8/DFSpeedTransport.mm` (board
  publish entry point; GPS path untouched)
- `sideplay/duoface-native-scene-host/speed8/DFGofaAlertMailbox.hpp` (new)
- tests under `sideplay/duoface-native-scene-host/tests/` (host, synthetic)
- version bump: native host `0.1.172~gofadecoder1`, integrated
  `0.0.172~gofadecoder1`, new private workflow copied from the QA171 one.
