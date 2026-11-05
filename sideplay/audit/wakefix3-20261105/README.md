# QA172 wakefix3 — whole-DEB audit and source repairs

## Verified result — 2026-11-05

**Build/sign/package/static audit: PASS. Device acceptance: not tested.**

- [Successful Actions run 42047069344](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/42047069344), completed at 14:42:15 UTC.
- Source commit: `d6ab38887a85bb3683add68e74dac6e0c106918e`; package archive commit: `f74cb0f4af45508b4bdecb77ddb1d0d9f90f5c6a`.
- DEB: `com.duoface.jb.embedded_0.0.172~wakefix3_iphoneos-arm64.deb`, 1,252,836 bytes.
- SHA256: `64e6e06f94bb5734e74ce936ba9999cc94934109c597b48821cea5414ab26e42`.
- Local gates: 159 Python tests and eight portable C/C++ harnesses passed. CI additionally executed all seven Foundation harnesses, including 79 keyboard assertions, then passed both iOS syntax checks and the complete build.
- A fresh scan of the downloaded artifact verified 1,250/1,250 code-page hashes in all 11 images / 14 slices. Private original-versus-candidate comparison passed 39 checks, with no unexpected changes. Paths/types/modes/owners, filters, architecture roster, iOS minima, dependency names, rpaths, entitlements and nonbinary resources/scripts remain unchanged. Seven dylib install IDs changed as intended.
- [CI receipt](ci-validation.json), [comparison summary](candidate-comparison-summary.json) and the Actions archive preserve the result. Full extracted binary strings/symbols remain in the separately delivered private audit ZIP.
- No Sileo publication or installation occurred. Automatic native app launch/navigation keepalive and actual CarPlay keyboard/touch/reconnect behavior remain device/implementation gates as described below.

## Status at source submission

- Target repository: `chuongnguyen89dn-ui/Duoface`.
- Isolated repair branch: `feature/sideplay-repair-audit-20261105`.
- Buildable baseline: `97edf281e9e2d757a5b19d895b18888b3f821af2`, the source of successful [wakefix2 run 41943698677](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41943698677).
- Baseline DEB: `com.duoface.jb.embedded_0.0.172~wakefix2_iphoneos-arm64.deb`, SHA256 `673590b0f9027bcdecc842b38d19cf198388dc0a494138b4229b64bd168a6e39`, 1,243,424 bytes.
- Candidate package versions: integrated `0.0.172~wakefix3`, native host `0.1.172~wakefix3`.
- Source repairs and local validation are complete when recorded in `local-validation.json`. macOS compilation, signing, the candidate audit and archive are separate CI gates; their actual result belongs to the Actions run and its `CI_RESULT.txt` receipt.
- No Sileo publication, installation or physical-device acceptance is implied by this source checkpoint.

The default `spec-main` branch contains later-numbered experimental source, whereas the latest successful package was built from the pinned wakefix2 source. This repair deliberately starts from that exact successful package's source. It does not replace the unrelated default-branch experiments.

## Whole original package

[Baseline summary](baseline-summary.json) records aggregate coverage and the exact input checksum. The detailed per-file and per-slice extraction is retained separately for the user and is not uploaded to this public branch. Automatic approval review rejected publishing the full strings/symbols/metadata extraction because it could disclose sensitive information. This smaller public report contains source-repair explanations and aggregate results only.

All 40 payload files and 3 control files were scanned. All 11 Mach-O images / 14 slices were parsed; all 1,230 declared code-page hashes matched across 28 CodeDirectories. All 12 plists and 15 PNGs were checked, and both compiled NIBs were inventoried. The scripts and binaries were not executed. No implemented static integrity check failed. This result does not contradict the source-level runtime bugs below.

## Repairs and executable evidence

| Problem | Production change | Verification |
|---|---|---|
| A keyboard learned through a window notification could disappear from an incomplete application-window scan | Retain weak identities of observed keyboard windows; remove only the exact hidden/deallocated window; merge positive scene/window observations | Foundation harness exercises visible → empty scan, replacement, unrelated hide, real hide and deallocation using the shipping header |
| One app's hidden keyboard record could overwrite another app's visible state | Distinct retained mailbox per bundle; receiver validates schema, exact hosted bundle and verified PID; common notification only requests a reread | Harness exercises production mailbox read/write with a deterministic notify backend and two distinct production channel names |
| Failed keyboard publication followed by a visibility bounce could skip the corrective update | Invalidate cached publication success before a new attempt; coalesce only a completely successful write and common wake | Production publication-decision helper tested with false → failed true → false and repeated failures |
| A delayed control layout could run with unknown keyboard state, or miss the transition back to known/closed | Refresh immediately before delayed layout; require known/closed state; schedule deferred layout on a changed fully known/closed snapshot | Source contract checks the actual method body, with a negative control injecting the previously missed immediate layout |
| Old disconnect timer could cancel a newer session | Classify stale callbacks separately and return without touching current candidates, generation or ACK | Production C policy/harness reproduces A disconnect → reconnect → B disconnect → old A callback |
| Exit-verification tick could overwrite a new session's ACK | Revalidate generation, physical disconnection and enabled policy on every 0.4-second verification tick | Executable C policy checks valid ticks and stale/reconnected/disabled cases |
| Native-map slot-only selection could adopt a different app after reconnect | Persist exact supported bundle plus physical slot; require one matching live owner; legacy slot-only preferences require explicit reselection | Foundation lease/catalogue harnesses and source contracts; no assumed launch ABI |
| Changed native owner or failed geometry could renew a misleading lease | Verify exact native scene identity, bundle, UIKit owner and physical pane; revoke same-session lease on invalid geometry; discard references only after the owned pane is empty and the native view has left | Freshness C harness, Foundation lease harness and exact owner/geometry contracts |
| Native map ownership could be confused with a saved preference | Phone-scene exclusion requires a fresh matching active-session heartbeat and native-owner lease; preference alone is insufficient | Foundation tests cover stale/future/NaN/cross-session/unsupported bundle and preference-only cases |
| Compiled dylib identities contained temporary runner paths | Set stable `@rpath/<module>.dylib` identities during linking, before signing | Candidate CI checks source-defined package contracts; a separate private full comparison verifies the original paths, scopes and all binary metadata |

The broad native-app rewrite from failed commit `c47b80e45aff01823379d2b3348f145f2f5f95f6` was not copied wholesale. Its wrong application-library assumptions are addressed by reading the real existing `FBSApplicationLibrary` and matching declarations. Adoption remains limited to Apple Maps, Google Maps and Waze, which are the existing adapter's supported identities.

## Regression gates retain their purpose

The historical frozen-host tests still compare the exact known scene-host blob after removing only the precisely reviewed import and fresh-native-lease guard. They do not accept an arbitrary new fingerprint. A negative control proves that an unrelated geometry edit, a moved/duplicated/missing guard or an always-true guard still fails. Current package-version assertions advance together to wakefix3. Legacy experimental test suites are not presented as current build gates.

The scanner has nine negative tests covering corrupted page hashes, corruption in the second FAT slice, bounds violations, archive traversal/duplicate paths, PNG CRC damage, checksum mismatch and non-execution of maintainer scripts. `local-validation.json` records actual local commands and counts. The macOS workflow also executes the Foundation harnesses and recompiles the iOS16 sources with the existing warning-as-error build.

## Material limits and device checks

1. An unknown keyboard snapshot is treated conservatively. If any hosted app lacks a valid report, the wake gate does not consume its touch and the keyboard-sensitive four-second relayout is deferred. Controls can therefore remain visible longer for unsupported relay apps or failed channels. This is deliberate; known/closed state resumes deferred layout.
2. The mailbox tests use deterministic notify stubs. They verify the shipping transport algorithm and channel separation, not iOS sandbox permission, notification delivery or IPC sender authentication.
3. Native maps must already be open on CarPlay. This candidate does not claim to launch every native CarPlay app, keep an arbitrary app alive in the background, or render/navigation-test a map on a car. Only the three existing map identities can be adopted.
4. If UIKit has replaced the native scene but still keeps that view inside the assigned pane, restoration remains deferred and no lease is renewed. The repair only removes an empty first-party pane after the system moves its native view away; it does not reparent a different live owner.
5. Internal CodeDirectory hashes are checked, not Apple/CMS identity or device AMFI acceptance. Keep the final whole-DEB SHA256 because resource sealing is incomplete in the existing jailbreak signature format.
6. `postinst` still reports successful package configuration even if `uicache` only emits a warning; icon registration must be observed on the device. Existing package conflict declarations remain present.

After CI succeeds, the focused physical checks are: repeated hidden-controls first taps; keyboard open/type/close while switching between two apps; fast unplug/reconnect spanning both the ten-second grace and the exit-verification ticks; explicit native-map app/slot choice and reconnect without changing owners; orientation/ratio/Dock/YouTube/GOFA regressions. Record actual logs and installed package identity before attributing a result to this candidate. No device test result is fabricated here.

## Reproduce the private build

Workflow: `.github/workflows/duoface-172-wakefix3-signed-private.yml`. A source push to the isolated repair branch triggers the existing macOS15 build/sign/package flow, executes the new harnesses, scans the complete new DEB in temporary storage, checks source-defined package contracts, then uploads and archives the existing requested candidate DEB with source SHA, run ID and a small aggregate audit summary. Full binary strings, symbols and detailed audit folders are not uploaded or archived. The original-versus-candidate full comparison runs separately and stays private. Audit/report-only follow-up commits do not trigger another build. There is no APT/Sileo publication step.
