# First-party request-scoped Darwin mailbox (private candidate)

Baseline: DuoFace feature/duoface-qa146-native-home-exit-20261031, f80253438a9db9cc5e82ca8ea7e2969e467e6941. Continued from user checkpoint 5d1e109. Existing public QA156 nativebridge1 remains immutable.

Read central ZIP skills 01,02,05 by git clone /tmp/duoface-training then Python zipfile; exact central tree 0180bd5b4244a93a08283806be7173dea3999675. Read original-app-state-route-20261031/APP_STATE_ROUTE_FINDINGS.md: vendor listener request/recovery/active/inactive lifecycle, no vendor tokens/license copied. Original binary imports NSDistributedNotificationCenter, so platform documentation alone does not prove that private class is missing at runtime. This change removes our unverified private center/registration dependency; it does not establish the sole cause of Log24 failure.

## Actual implementation
DF156DarwinMailbox.h transports up to 2048 complete JSON bytes using fixed per-bundle/direction Darwin notify state slots, explicit invalid-before-write, random publish generation, length/CRC32 and double generation snapshot. Notifications only wake readers; full requestID/owner/scene/bundle/timestamp/dimensions remain unchanged. CRC detects torn/corrupt snapshots, NOT malicious forgery. Channel names never contain request IDs; token storage is bounded by 14 exact app IDs x2 directions x258 words/header/commit, slots registered lazily. Tokens intentionally retained for process lifetime to keep state names alive. All wrapper calls serialized on main queue. One writer per bundle/direction is required; this is a latest-value mailbox, not an event queue. ACK phases may coalesce; scene-matched/window-adjusted or restored retain exact request evidence.

DF154AppStateProtocol.h sends/reads full dictionaries and reports write failures; DF154GeneralAppStateRelay.m registers its exact bundle, reads initial committed lease and keeps prior expiry, scene/owner/request validation and frame restore. DFHomeStandalone144.m listens only for same 14 supported ACK bundles and retains current/terminal identity checks. Existing consent, native Dock/Home, scene attach and GOFA/YouTube code otherwise preserved. No all-app injection.

Version 0.0.156~nativebridge2 (native 0.1.156~nativebridge2) reserved only for new private signed candidate; no same-version public overwrite. No carplaydsp changes or publication in this work.

## Verification
Local C actual mailbox algorithm with mocked notify backend: all lengths 1..2048, empty/oversize/zero generation, corruption, racing snapshot, partial failed publish, get failure and separate-bundle isolation PASS. One initial test compile failed signed/unsigned comparison under -Werror; cast corrected and re-run passed. Full existing scoped Linux workflow step ran locally with EXIT=0 (source guards + C lifecycle tests). Full log: IPC_LOCAL_TESTS.log.

Added real macOS cross-process test app_state_ipc_156_runtime.m to private workflow: complete state -> exact-identity ACK -> revoke -> restored, plus stale lease/invalid scene/dimension validation. Requires macOS Foundation/notify, not runnable on Linux here. Existing private workflow also compiles actual iOS16 source, signs and inspects integrated package. These results MUST be checked after new source commit; currently pending.

## Limits / exact continuation
Darwin names are not sender authenticated: any process allowed to write the names can forge a packet. Neither CRC nor owner UUID is a cryptographic signature. Do not treat this as authorization for sensitive commands or weaken native scene/allowlist validation. Sandbox permission on real iPhone, runtime notify state visibility, resource/latency cost, actual UIKit scene IDs and app ACKs remain UNVERIFIED. Reject failures; expiry restores owned windows. No claim that attach bogus reference size, native Dock/Home, touch/orientation/reconnect is fixed. Hardware acceptance requires actual same-request selected app trace after one deliberate immutable release through original source.

Next: inspect new private CI runtime test + iOS compile/sign/package run; fix concrete failures; verify archived DEB SHA/provenance. Do not publish nativebridge2 until those checks pass and device rollout is deliberate.

Primary API reference read: https://github.com/apple-oss-distributions/Libnotify/blob/main/notify.h (64-bit state; notifications coalesce), https://github.com/apple-oss-distributions/Libnotify/blob/main/libnotify.c (state access checks), https://developer.apple.com/documentation/darwinnotify/notify_set_state(_:_:).

## Completed verification — 2026-11-01 08:20 ICT

Source commit 08512742276c6540590d7fb76ba25b69486c8b51. Scoped CI 41260407157 SUCCESS; macOS integrated private CI 41260407074, job 124712305538 SUCCESS (completed 01:20:35Z). Actual log markers confirm mailbox negative tests and real two-process Darwin STATE/ACK/REVOKE PASS, not a proposed test. Actual iOS16 compile-check, complete build, ldid readback, merged exact-filter checks and archive upload passed.

Archive commit cc3738643c3bff697db206210e25dfdae0f1f871. DEB at sideplay/jb-embedded-appbridge/evidence/runs/41260407074/com.duoface.jb.embedded_0.0.156~nativebridge2_iphoneos-arm64.deb, 1,192,308 bytes; SHA256 b64d78e9678cd36f05ab9a5a4512559254b044de61d2bd5f5e22e2da8225eb17. CI_RESULT.txt explicitly SIGNED=true, SILEO_PUBLISHED=false, DEVICE_DIRECT_HOME_TESTED=false. SHA256SUMS.txt and PACKAGING_PROVENANCE.json read back and agree. Three changed core source files re-fetched at source commit and exact content matched local.

Independently fetched actual archived binary via git show cc3738643c3bff697db206210e25dfdae0f1f871:<above path> > /tmp/df156-package/candidate.deb. Ran:
```
python3 sideplay/audit/qa155-vehicle-gate-20261101/verify_ipc_candidate.py /tmp/df156-package/candidate.deb --expected-sha256 b64d78e9678cd36f05ab9a5a4512559254b044de61d2bd5f5e22e2da8225eb17
```
from DuoFace repo root. PASS exact hash/version/architecture, full dpkg listing/extraction, exact14 bundle filter, actual new Darwin IPC marker in SpringBoard host and app relay, embedded Mach-O signature blobs. JSON report IPC_PACKAGE_VERIFIED.json. Embedded signature structure is verified here; actual ldid entitlement readback was performed by macOS CI. CI log has a dpkg/tar Broken pipe caused by existing dpkg-deb -c | head -1 metadata check, which closes output early. Independent complete dpkg listing/extraction finished successfully; no package corruption observed. Preserved the log excerpt as IPC_CI_MARKERS.log.

Scope clarification: NSDistributedNotificationCenter is absent from NEW general app relay binary; SpringBoard host still contains it via pre-existing dedicated DFYouTubeHostState.h, intentionally untouched. Do not report that all project uses were removed or that YouTube's path was validated by this change.

NEXT / physical blocker: signed source+binary transport replacement ready for deliberate rollout, not installed or published. Existing main Sileo remains nativebridge1. Actual iPhone sandbox delivery and app-scene match must be established before functional acceptance. Carry same request/bundle/owner/scene through host publish, app scene-matched/window-adjusted and restored on Home/disconnect; measure orientation/touch/Dock and bogus reference size independently. No remote iPhone or car access exists in this session.
