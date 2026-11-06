# Four latest SidePlay logs: evidence-based QA174 findings

## Follow-up opinion assessment - 2026-11-06

User asks whether the logs confirm ONLY (a) a passive wake gate not receiving/handling the wake contact and (b) native-map requests lost between picker and coordinator, while scene-retention hooks and attach are innocent.

Verdict: reasonable repair priority, but not a proven exhaustive root-cause statement. Keep the following distinctions for implementation:

- The passive-only implementation contradicts the hidden-first-contact-consumed user contract regardless of log coverage. Nine expiry markers, zero pane-wake markers and the user's failure establish a failing wake feature and focus investigation on actual touch receipt/ownership. They do not isolate whether the touch misses the surface, is rejected by state guards, or reaches an unlogged path. Merely changing return nil to interception at an unreachable view is not demonstrated to repair it.
- No native picker request/Attach/ACK was recorded. This is NOT proof a successfully sent message was lost in transport. The source has an occupied-pane early return before command creation/write/notify/request logging, and the five recorded picker openings are on loaded panes. Correct the per-pane replacement transaction and observe card-entry plus dispatch; do not label the exact rejection of every Waze tap established when callback-entry evidence is absent.
- Existing under-lock and BKS hook installation is positively logged. Do not add duplicate hooks or change lifecycle as a speculative fix for a pre-dispatch block. Installation alone does not prove every ownership predicate/retention callback is correct.
- Native coordinator attach is not demonstrated to have run for the captured in-pane requests. It is not the first evidenced failing boundary there, but an unexercised stage has not passed. Do not remove its identity/session guards or certify it fault-free.
- The separate Google Maps Home/standalone route DID receive requests and create hosts; the app-side report at original audit L17388 is scene-unmatched count=0. That observed identity-reconciliation failure remains open even after the picker/wake work. Later restored count=1 limits the inference: it is not proof of permanent nonmatching. Do not conflate this path with native in-pane Attach, or erase it from scope.
- Home icon publication is another unresolved acceptance condition. Prioritize the two upstream source defects without claiming they explain all failures or complete Home publication.

This clarification preserves the ordered work below; it does not authorize a new runtime change or claim a fix. Live GitHub review baseline dc119d51049a5f0db20d5d159cb0a4a2c14993fc; read canonical sideplay/tiep tuc du an.md, this report and DFNative12Chrome.m lines2405-2470. In-progress Actions query returned zero. No older log file was opened, no analysis rerun, no app test/build/DEB/Sileo change. This file is already referenced from both canonical handoffs. Next work remains behavioral wake regression and owned in-path gate, explicit picker replace/launch transaction, then actual request-correlated scene/retention/render/input and Home verification. User device acceptance remains FAILED.

Review date: 2026-11-06. Scope: read/analyze the four files from the latest user upload, compare necessary current-source callsites, preserve findings. NO runtime patch, DEB build, Sileo deployment or new device test.

## 1. Exact input and freshness

Repository `chuongnguyen89dn-ui/Duoface`, upload on `main` commit `3dc27f7d833709be04fc3406aa3bb7077b023f83`, timestamp `2026-11-06T04:15:23Z` / 11:15:23 ICT. Compare against its parent confirms exactly these four changed paths. No content from other/older repository log files was opened for this review.

| File under sideplay/log/ | Bytes | Lines | Git blob |
|---|---:|---:|---|
| DuoFaceAudit 3.txt | 4830277 | 41447 | 0db33be9fe28ecfa9dcc1bdc14749aadfda21bc3 |
| Crash-0-SpringBoard.diskwrites_resource-2026-11-04-210058 3.ips | 30679 | 421 | fd7f66c3969dc0eab91d7c6c934f6da7cc9705eb |
| Crash-1-CarPlay.diskwrites_resource-2026-11-02-140101 3.ips | 235005 | 2410 | 45ac1ec2cf378ecf75675d98702d1ff6789c3a58 |
| Crash-2-SpringBoard.diskwrites_resource-2026-11-02-104439 3.ips | 251827 | 2496 | 904a9aa2bbd8e69761c3fff3eb8b46065c7710c2 |

`DuoFaceAudit 3.txt` L2: `Date: 2026-11-06 04:13:25 +0000` = 11:13:25 ICT. L6's exporter banner `0.0.171~gofadiag1` is a static exporter string, NOT the running package identity. The timestamped trace contains **863 current records with build=0.0.174~mapwake1** (SpringBoard PID2015, CarPlay PID2045, app PID2050); current-stamp UTC range 03:40:29.002999 to 04:13:22.032635. Current device version is therefore evidenced, not merely inferred from Sileo. Previous build173 records exist inside this same cumulative export and are separated, not used as QA174 proof.

Current relevant split/standalone interaction occurs about 10:41:26-10:43:56 ICT. L41409/L41413 record physical disconnect/template-disconnected near 10:43:56; export is about 29m29s later. Thus the final `Session active: NO` and old physical-pane snapshot do not prove the user was disconnected during the failed interactions. Do not tell the user to reconnect as an unsupported root-cause diagnosis.

## 2. Logo: the expiry path runs, but no current pane-wake observation is recorded

Counts over the 863 explicitly stamped QA174 records:

- `qa179-logo-idle-red-border-hidden-visual-only`: **9**.
- `qa177-recall`: **0**; `qa179-recall`: **0**.
- `qa120-pane-tap`: **0**; `qa120-hosted-touch-hit`: **0** (also absent from the entire new export).
- Direct divider logo contacts: two Began/Ended pairs, L40759/L40762 and L40951/L40954.

Exact examples from the new export:

- L37113, utc1793936495.134937: `area=chrome qa179-logo-idle-red-border-hidden-visual-only`.
- L40759, utc1793936608.020514: `area=logo-control raw-began id=1 at={452, 127}`.
- L40762, utc1793936608.239023: `area=logo-control raw-ended id=1 elapsed=0.218502 inside=1`.
- L40951, utc1793936615.417038: `area=logo-control raw-began id=2 at={446, 119}`.

Interpretation: recorded 4s expiry and direct-logo input exist, while the requested anywhere-in-pane recall has no corresponding current marker. Together with the user's failure report this localizes the investigation to receipt/ownership of pane touch and the already-confirmed wrong passive-only contract, not merely the countdown value. Absence of a marker alone is NOT proof of the precise rejecting condition or of every hardware event's delivery.

Preserve latest user contract: hidden -> first entire contact is consumed solely to wake controls; visible -> untouched app routing; consume through Ended/Cancelled, no replay, no independent red wake, no scene/keyboard re-layout and no global shield. Do not return to the superseded 'never consume first tap' test.

## 3. Maps INSIDE DuoFace: no native attach transaction is recorded; an occupied-slot guard is concrete

The new export has **zero** `qa178-native-map-picker-request`, `qa178-native-map-picker-rejected`, `qa178-native-map-picker-ack`, or `command=Attach` records. The native-map log section L19361-19396 consists of listener startup/catalog messages, not command execution. L41434 reports:

`Native Map ACK: applied=NO attached=NO reason=none owner=unknown age=infs`

L41443 reports no chosen native slot and no owner lease. This is missing ACK evidence, NOT an explicit native rejection with reason `none`.

There are five explicitly QA174-stamped `real-app-picker-open` entries. The immediately preceding per-pane records show loaded apps: L36919 slot0 YouTube; L37119 slot1 GOFA; L40392 slot1 GOFA; L41127 slot1 GOFA; L41340 slot1 Wyn. No native request follows these captured picker openings.

Current released source, `sideplay/duoface-native-scene-host/DFNative12Chrome.m`, compiled commit `d8144d3c58833764fbc6a53e25044682adf852e2`, `appPicker:didSelectNativeMapBundleID:displayName:` (roughly L2405-2460), refuses a pane that has a hosted or pending UIView and returns after showing `Hãy chọn ô còn trống để ghép bản đồ`. This branch is BEFORE the command write and BEFORE `qa178-native-map-picker-request`, and the early rejection is not logged.

Conclusion: selecting a map to replace an already occupied pane is concretely blocked by this implementation. This fits the captured occupied picker openings and absent dispatch. However the log has no callback-entry record for the tapped native card, so do not assert that every attempted Waze click reached this exact guard. Instrument the missing card-entry/early-rejection boundary and implement the intended per-pane replacement transaction instead of blindly loosening downstream native ownership checks.

Waze is seen as selected/installed by current CarPlay PID2045: L15924 `selected-LS-inclusion bundle=com.waze.iphone key=SBStarkCapable`. No QA174-stamped Waze host creation or current standalone Waze request is recorded. The code's whitelist contains the correct `com.waze.iphone`. Thus this is not evidence of Waze being absent or having the wrong bundle ID; its actual launch boundary remains unobserved here.

## 4. Google Maps OUTSIDE DuoFace: actual independent-bridge requests occur, with a scene-match failure

This is distinct from the native map coordinator. The current-period `DuoFaceStandalone144.log` contains seven `qa160-native-grid-icon-pressed bid=com.google.Maps` entries between epoch1793936583.493 and 1793936586.029 (10:43:03.493-10:43:06.029 ICT). The first request follows:

- L17035: `stage=qa160-native-grid-icon-pressed bid=com.google.Maps`.
- L17049: `stage=native-dashboard-context-verified ... workspaceSame=1 externalSame=1 rootRelated=1`.
- L17052: `stage=standalone-requested-not-yet-ready bid=com.google.Maps ... content={{45, 0}, {595, 360}}`.
- L17053: `stage=qa160-native-icon-bridge-accepted com.google.Maps`.
- L17075: `stage=qa149-manager-live-scene-owned ... generation=3 window={{0, 0}, {640, 360}}`.
- L17080: `stage=scene-hosted-render-and-touch-unverified bid=com.google.Maps ... verifiedPID=2067`.
- L17082: `stage=qa160-request-to-dock-ms ... ms=256.8 touchReady=unknown`.

Timestamped QA174 source logs independently confirm seven Google Maps host creations and FBScene attachment/foreground=1/hosting=1. Repeated icon inputs lead to six `stopped ... next-home-selection` transitions and rebuilds, then one `native-Home-exit`. Do NOT call this an automatic crash/restart loop: each replacement is preceded by another logged icon input.

Most concrete app-side failure, L17388 at 10:43:06.560 ICT:

`stage=qa155-app-side-ack ... bid=com.google.Maps scene=sceneID:com.google.Maps-default phase=scene-unmatched count=0`

In released `DF154GeneralAppStateRelay.m`, `reconcile` posts this phase when no `UIApplication.connectedScenes` UIWindowScene matches the requested identifier (using `_sceneIdentifier` / `identifier`); it returns before the matching scene's window geometry is applied. The IPC reaches the app-side receiver, but at this instant the requested scene cannot be matched to a UIKit scene. This is an observed transaction defect, not speculation that the app never received any request. L17399 later reports `phase=restored count=1` for the last request; therefore the single mismatch must NOT be generalized into 'never matched any scene' or 'no window was ever changed'. The same request/scene lifecycle needs tracing and a correct identity join, without treating PID/FBScene attachment as rendered map or removing identity checks.

Also recorded seven times in the Google Maps attempts: `scene-frame-readback actual={{0, 0}, {414, 736}} target={{0, 0}, {1190, 720}} same=0` (e.g. L39985, L40117). `DFSceneHost.m` L530-610 reads this frame BEFORE sending its frame update. Thus this alone is NOT proof of a failed final resize or of two writers racing. Require post-apply readback and stable scene identity.

This native Home Google Maps input is not proof that DuoFace successfully published newly selected phone-app icons. It does not invalidate the user's report that selected apps fail to appear/render outside DuoFace.

## 5. Home publication: source roster/declarations exist; visible icon publication is not proved

At current PID2045 and current-period timestamps:

- L15917: `ABI-checked hooks ... DashBoardFactory=1; scope=CarPlay; switch=1`.
- L15919 and L15924 include selected Google Maps and Waze.
- L15925-15928: declaration-attached/getterReadback=1 for Facebook, TikTok, Wyn and YouTube.
- L15929: `original-DashBoard-factory returned=FBSApplicationLibrary newRecords=4; not-icon-proof`.
- L12885-12891: actual FBS library found, reconciliation repeatedly returns 0 new records.
- L15930-15937: `CRCarPlayAppPolicy launch=0 capable=1 display=1 phone=1; icon-and-tap-unverified` for those bridged apps.

The failure cannot honestly be summarized as 'phone choices were never read'. They were read and declarations built. Need finish/validate the actual native Home roster, notifications/refresh and displayed app entries. No visible-icon evidence is in these logs; respect the user's device failure.

Important non-error: L12884 `notify home=0 enabled=0` logs the two `notify_register_dispatch` RETURN CODES in `DFHomePublisher136Entry.m`, not the Home enable preferences. Do not misdiagnose both switches as OFF. Existing library lookup succeeds here, so the prior possible library-selector mismatch must not be asserted as proven failure of this current session.

## 6. Under-lock and the three IPS reports

Current QA174 L36859/L36860 explicitly record `runtime-presence background=1 obsolete=0 bg-argc=4` and `scoped-existing-background-hook-installed`. L36848 records `qa132-bks-interceptor-installed original-first owned-pane protected-data-locked 0.8s unblank`. The log contains 153 current post-lock setting records. Therefore the claim 'no under-lock/screen-blank hook exists' is contradicted for this runtime. This does not prove every callback's ownership/retention works; do not add duplicate global hooks.

All three newly uploaded IPS files are `Event: disk writes`, `Action taken: none`, bug_type145, with event dates Nov4/Nov2 as named. Each reports about1073.75MB dirtied, rates27.88,49.51,27.77KB/s versus12.43KB/s limit respectively. They are not three new QA174 crash/termination reports. The heaviest stacks reach Foundation/filesystem writes but several responsible images are unresolved UUIDs; do not invent symbol attribution or claim they prove a QA174 touch/map crash. The exporter automatically included these earlier diagnostic events in today's upload.

## 7. Ordered next implementation targets (NOT implemented in this review)

1. Correct hidden-contact in-path wake ownership and its behavioral test, then verify actual host touch receipt; retain 4s expiry and working GOFA/keyboard/divider.
2. Give map selection a real per-pane replace/launch transaction; fix or explicitly handle the occupied-pane early exit, with observable entry/result. Do not wait for a native ACK when the command was never sent.
3. Repair actual Google Maps host-to-UIKit scene identity/lifecycle handling; keep same-app repeated taps from destroying a still-valid request unnecessarily. Preserve strict identity and obtain after-apply geometry/input evidence.
4. Complete Home publication as a separate path after the already-read selection/declaration stage; distinguish existing native icons from newly bridged app entries.
5. Validate on parked CarPlay. This review does not claim a fix or ask the user to resend the same logs.

## Execution / handoff

Canonical source/code work branch: `fix/qa173-logo-map-touch-recall-20261106`; initial handoff HEAD55bf217a6a01d8ef273f186d53ad5b955dcfba05. Input logs are pinned to MAIN upload3dc27f7, not read from the older work branch. Runtime code comparison pinned to compiled source d8144d3c58833764fbc6a53e25044682adf852e2.

Because the large log exceeded connector raw-file reading and local direct GitHub DNS failed, the existing GitHub connection ran a bounded analysis-only job:42161788698, workflow `.github/workflows/duoface-174-four-latest-logs-review.yml`, script `analyze_latest_four.py` in this directory. Exact command from repo root: `python3 sideplay/audit/qa174-four-latest-logs-20261106/analyze_latest_four.py --fetch --input-dir "$RUNNER_TEMP/latest-four" --out "$RUNNER_TEMP/four-log-evidence"`. All four Git blob hashes verified. Results in `evidence/` and artifact13477227165 were read back; raw logs are not modified. Local focused analysis is preserved as `focus_current.py`, run as `python focus_current.py '/mnt/data/duoface-log-review-20261106/latest-four/DuoFaceAudit 3.txt' --out /mnt/data/duoface-log-review-20261106/FOCUSED.json`. Both scripts treat file content as data, never execute it.

No app/source fix, DEB signing/build, installation or Sileo publication in this turn. User-reported functional acceptance remains FAILED. Analysis CI success means the four selected files were read/hash-checked, not that any product defect was fixed.
