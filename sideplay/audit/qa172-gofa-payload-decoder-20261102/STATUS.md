# QA172 — status

- 2026-11-02 (session, Muse as implementer under explicit user
  authorisation to proceed with Method 2 and to keep the sideplay
  project history updated as in previous sessions):
  - Gate G0 completed: full instruction-level trace of the original
    payload helpers against the real Mach-O bytes (selrefs, cstrings,
    CFStrings, Swift small strings resolved). Results in `FIELD_MAP.md`.
  - Design + gated plan written: `DESIGN.md`. No source code changed,
    no build run, no publication, no device claim.
  - Key new facts vs the QA171 checkpoint: the speed board lives in
    `userInfo["pushSpeedBoard"]` (not `note.object`); the alert payload
    key differs by board (`pushNextBoard` vs
    `pushOtherBoardToCarplay`); normalised alert point keys are
    `identity/sign/latitude/longitude`; the existing DuoFace speed
    protocol and HUD already support a limit — only the transport
    publish guard blocks it.
- Next action: Gate G1 — user device session with QA171 (open GOFA,
  export the log via the DuoFace app's "Xuất log / lỗi CarPlay"), or
  explicit user instruction to proceed to G2 on static evidence alone.
- Flags: `DEVICE_TESTED=false`, `SILEO_PUBLISHED=false`,
  `GOFA_REAL_ROAD_ALERTS_CONNECTED=false`,
  `GOFA_REAL_NAVIGATION_TURNS_CONNECTED=false`.

## Update — 2026-11-02 evening: Gate G1 partially passed

- QA171 published to Sileo (carplaydsp commit `ca428c4d79b5`,
  publisher run `41420918323` SUCCESS, public index verified) and
  installed by the user; device export analysed in `G1_EVIDENCE.md`.
- Proven on device: GOFA posts the original board notifications —
  34 events in one GOFA session; latest was `notificationSpeedBoard`
  with exactly one `userInfo` key and a nil object, matching the G0
  field map (`userInfo["pushSpeedBoard"]`).
- Not captured: the probe's detail log file — the GOFA sandbox
  blocked its writes to `/var/mobile/Library/Logs` (anticipated in
  the probe source). Key name + value class remain runtime-unverified.
- Decision recorded in `G1_EVIDENCE.md`: fold that question into the
  decoder's shadow-mode diagnostics (Darwin channel), proceed to G2.

## Update — 2026-11-02 night: Gate G2 completed (host side)

- Implemented the decoder core exactly per DESIGN.md:
  `DFGofaPayloadDecoder172.swift` (pure Swift + Foundation, Mirror
  based, bounded children 64 / points 32, structural validation only,
  type names reported never required, both `userSpeed` and `speed`
  carried), the ObjC bridge header `DFGofaPayloadDecoder172.h`, and
  `DF172GOFAEvidenceProtocol.h` — the v2 Darwin diagnostics channel
  that replaces the sandbox-blocked detail log (present/rejected
  field masks + value kind + bucketed point counts; no values, no
  coordinates, no key names).
- Host tests: synthetic stand-in models only. Swift 5.10.1 host
  build ran **39/39 checks green** (full/missing/wrong-typed/
  out-of-range/NaN fields, boundary 200/400 vs 201/401, superclass
  properties, dictionary payload path, alert arrays, per-point
  rejection, 32-point cap, per-board key selection). The C evidence
  protocol encode/decode + staleness test also passes (clang-18).
- Honest residue: the `@objc` bridge section compiles only under
  macOS/iOS (`#if canImport(ObjectiveC)`); it is type-checked by
  design review, not yet by a compiler. That verification belongs to
  the G3 private build (macOS CI), together with wiring
  `DFGofaBoardSource172` and the version bump to
  `0.1.172~gofadecoder1` / `0.0.172~gofadecoder1`.
- Next action: Gate G3 — create the QA172 private build workflow
  (copy of the QA171 one), wire shadow mode, private build, device
  session to settle `userSpeed` vs `speed` and capture the value
  class via the v2 evidence channel.

## Update — 2026-11-02 night: Gate G3 wiring completed (pre-build)

- New glue `DFGofaBoardSource172.m`: GOFA-process-only constructor,
  observes the 3 board notifications alongside the untouched QA166/167
  probe, throttled to 2 decodes/sec/channel, decodes via the Swift
  bridge, reports via NSLog `[DuoFaceDecoder172]` and the DF172 v2
  Darwin evidence state. Shadow mode: NO HUD publish call exists in
  the file (G4 owns transport).
- Host app export extended in `DFNativeDiagnostics.m`: a
  `QA172 decoder shadow: ...` summary line sits next to the QA167 one,
  decoded from the v2 channel (diagnostics only, no values).
- `build.sh` compiles `DFGofaPayloadDecoder172.swift` with
  `xcrun swiftc -emit-object` (module DFGofaDecoder172) and links the
  object + glue into `DFGofaSpeedSource162.dylib` with the SDK swift
  library path added. First CI run must confirm the Swift autolink
  (LC_LINKER_OPTION) resolution; documented fallback is linking that
  one dylib with the swiftc driver.
- Versions bumped: native host `0.1.172~gofadecoder1`
  (control, build.sh OUT, Info.plist 172 / 0.1.172), integrated
  `0.0.172~gofadecoder1` (package_integrated.py).
- Local verification actually run: both ObjC files pass
  `clang-18 -fsyntax-only -Wall -Wextra` against iPhoneOS16.5.sdk
  (zero errors/warnings). The Swift @objc bridge and the final link
  remain CI-only verifications.
- Prepared workflow staged at
  `sideplay/audit/qa172-gofa-payload-decoder-20261102/duoface-172-workflow-prepared.yml`
  (mechanical QA171→QA172 transform + decoder marker checks, YAML
  validated). It is NOT live: placing it under `.github/workflows/`
  needs an account with Workflows permission (the Muse app lacks
  it; the user's one-shot PAT was deleted after the QA171 publish).
- Remaining for G3: place workflow → private build → user installs
  the private DEB (single-file install, conflicts inventory first)
  → one driven GOFA session → export settles (a) value class via the
  v2 evidence kind, (b) `userSpeed` vs `speed` via the shadow NSLog
  values compared with GOFA's own UI.


## Update — 2026-11-02 night: Gate G3 private build SUCCESS

- Workflow placed on this branch with the user's PAT (commit
  `cade0361`); after sweeping the repo's current-version contract
  pins 171 -> 172 across all tests/ directories, adding the QA172
  regression test, bumping the packager's host pin and moving the
  Swift object outside the DEB staging root, run `41442985902`
  completed **SUCCESS** (job stage-only): contract battery green,
  Swift decoder compiled and linked into `DFGofaSpeedSource162.dylib`
  (autolink resolved), integrated DEB assembled, signed and verified
  (decoder markers asserted in the GOFA dylib).
- Archive commit `7374df0593a3`:
  `sideplay/jb-embedded-appbridge/evidence/runs/41442985902/` holds
  the private DEB `com.duoface.jb.embedded_0.0.172~gofadecoder1_
  iphoneos-arm64.deb` (1,256,084 bytes) + CI_RESULT + SHA256SUMS.
  Flags: SIGNED=true, SILEO_PUBLISHED=false, DEVICE_TESTED=false,
  alerts/turns still NOT CONNECTED (shadow build: decoder observes
  and reports, publishes nothing to the HUD).
- Remaining for G3: user installs the private DEB (upgrade over
  QA171, same package id), one driven GOFA navigation session, then
  exports the audit log — the new `QA172 decoder shadow:` line
  settles the payload value kind and which speed fields exist;
  `userSpeed` vs `speed` value comparison uses the shadow NSLog.


## Update — 2026-11-02 night: QA172 PUBLISHED to Sileo

- At the user's explicit direction (all builds go through Sileo;
  no raw-DEB installs), the carplaydsp publisher was switched from
  QA171 to QA172: publisher commits `40413873` + fix `8acde03f`
  (first run caught a transform error that dropped QA171 from the
  retained-version set; fixed and re-ran). Publisher run
  `41444947933` SUCCESS (all 5 jobs).
- Independently verified on the public index
  `chuongnguyen89dn-ui.github.io/carplaydsp/Packages`: exactly one
  `com.duoface.jb.embedded` stanza, Version `0.0.172~gofadecoder1`,
  SHA256 `69aa22b09eda...`, Size 1256084.
- State: SILEO_PUBLISHED=true, DEVICE_TESTED=false. QA171/QA170
  retained as rollbacks. Next: user updates via Sileo, one driven
  GOFA navigation session, export for the decoder shadow verdict.
