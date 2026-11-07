# 2026-11-07 — QA182 physical Audit12 + two user-uploaded Maps/CarPlayOwner logs: verified causal verdict

**Source repository:** `chuongnguyen89dn-ui/Duoface`, **log branch `main`**, snapshot branch head observed `34229434ebd93e83335883d899d3b357db658a65`. User uploaded files to `sideplay/log`. Read via live GitHub connector `contents` (file names/blob SHAs) and `git/blobs/<SHA>` (full 6.2MB audit) / `fetch_file` (two JSONL) and programmatically parsed source with no assumption that all three come from the same date. No attached/user device direct access in this chat.

## Inputs and provenance (do not conflate the logs)

| File in `sideplay/log` on `main` | Git blob SHA-1 | Size / records | Actual event time |
|---|---|---|---|
| `DuoFaceAudit 12.txt` | `ef159663c1627af1cdbdd974acd4ae0e6a4f51ac` | 6,197,216 bytes, 29,411 LF-delimited lines | Export: **2026-11-07 02:15:32 UTC**, iOS 16.7.16 |
| `DuoFaceCarPlayOwner-4C5C8ADB-EE69-458A-B664-1753AB90C797.jsonl` | `ffe9c6e6f0a0382426cf3dd78fd3da45d5a3fecc` | 141,845 bytes, **46 JSON records**, schema1=40, schema2=6 | **2026-10-28 04:39:58–05:04:37 UTC** |
| `DuoFaceCarPlayOwner-D48F4C0E-A72B-4621-ABA3-36DF83CFF037.jsonl` | `f38eb00da1c74f741c4a416c83720c8299d742b5` | 34,008 bytes, **3 JSON records**, schema1=3 | **2026-10-28 04:39:58–04:40:57 UTC** |

**Exact dedup check:** the 3 short-file records are **identical** to the first 3 long-file records; **46 unique** records total, not 49 independent observations. UTC timestamps are from `utc` JSON keys, not file upload date. The October 28 owner samples are nearly **10 days older** than Audit12 and cannot prove Gate0 injection or the ON/OFF mode for November 7.

## Audit12 — computed events and outcomes

The full `DuoFaceDeepTrace.log.previous` and `DuoFaceDeepTrace.log` sections contain **162** matching `area=qa182-b1` events belonging to **12 unique AssignmentID values**, 12 unique native Maps attempts. The exact event counts:
- `b1-assignment-created` **12**; `b1-catalog-reconciled` **12**; `b1-launch-issued` **12**; `b1-scene-seen` **12**; `b1-frame-placed` **12**; `b1-scene-frame-request` **36**; `b1-lifecycle-swallowed` **12**; `b1-assignment-revoked` **12**; `b1-lifecycle-restored` **12**; `b1-summary` **24**; `b1-hook-ABI` **6**.
- All **12** assignment lifetimes ended in revoke **839–1,636 ms after native frame placement**, meaning **0/12 sustained**. **11/12** had `touch-owner event=watchdog-detach` between placement and revoke and `CarPlay native-owner-state active=0 visible-candidates=0 unique-duoface=0 hooks=1`; **1/12** was revoked specifically as `app-replaced-in-native-slot`. All 12 had DuoFace host background boundary in the corresponding window.
- Original scene frame request `{{0,0},{640,360}}` -> requested `{{0,0},{297.5,360}}`; native `b1-frame-placed` coordinates `{{342.5,0},{297.5,360}}`, `native-parent=DBDashboardRootViewController`, `native-window-level=-1.0`, `target-SpringBoard-window=hidden`, `touch=UNVERIFIED`. This demonstrates an initial **placement into Dashboard's tree**, NOT user-visible DuoFace-owned composition/verified native pixels.
- All QA182 `stock-settings` tags remain exactly `unknown` (**162 matching QA182 lines**). The overall audit has **0** `gate0` markers, **0** `DuoFaceMapsGate0` records, **0** runtime `presentBaseViewController` probe records and no `0.0.1~gate0readonly1` runtime build marker. It **does not prove** Gate0 package was not installed: injection, writes, process restart and exporter coverage were not established. It **does prove** no successful Gate0 instrumentation is present in exported Audit12.
- Audit header `Audit schema: 4; exporter build 0.0.171~gofadiag1` represents **exporter**, while runtime trace says `build=0.0.182~b1nativemaps1`. Do not assume exporter version means old runtime.
- End-of-audit `Native Map ACK: applied=NO attached=NO reason=native-maps-scene-host-identity-unverified owner=CarPlay age=13333.41s` is **stale** (about 3h42m) and is NOT the current native Maps place/revoke verdict. `Native Maps physical frame readback: count=2 age=22.82s` confirms two physical frame records, not actual native Maps imagery/touch.

**12 correlations (UTC, full day 2026-11-07):**
| Assignment prefix | Created UTC | Frame line | Revoke line | Frame→revoke (ms) | Cause |
|---|---|---|---|---:|---|
| EB8EF4B0 | 00:43:28 | 23801 | 23812 | 839 | watchdog |
| 441A67B0 | 00:44:01 | 23944 | 23961 | 924 | watchdog |
| AA2D6DD9 | 00:44:27 | 24088 | 24099 | 1435 | watchdog |
| 1931799B | 00:44:46 | 24214 | 24224 | 957 | watchdog |
| 3DCF68D0 | 00:44:58 | 24327 | 24341 | 1611 | watchdog |
| 7547244C | 00:46:07 | 24500 | 24512 | 1357 | watchdog |
| 5DC1E3AF | 00:46:47 | 24652 | 24665 | 953 | app replacement |
| DE11F3D8 | 00:47:11 | 25408 | 25420 | 1217 | watchdog |
| 54F33FA2 | 02:12:28 | 28849 | 28866 | 1316 | watchdog |
| DD3DC82B | 02:13:19 | 29007 | 29018 | 894 | watchdog |
| 558EE72F | 02:14:56 | 29187 | 29205 | 1636 | watchdog |
| 90D9417A | 02:15:07 | 29306 | 29324 | 1457 | watchdog |

**Causal example (Audit12 exact lines 23801–23823):** native initial `b1-frame-placed` at 23801; local `catalog/launch/scene/frame=PASS` but `lifecycle/native-pixels/touch=UNVERIFIED` at 23802; `DuoFaceNativeHost qa125-background-boundary` and `native-owner-background-retention-requested` 23805–23806; CarPlay `native-owner-state active=0 visible-candidates=0 unique-duoface=0` at 23807; SpringBoard `watchdog-detach age=0.13 active=1 session-match=1` at 23809; SpringBoard hides own windows then `b1-assignment-revoked` 23811–23812; Waze counterpart `deactivate-request` at 23816; Chrome stop at 23820; native Maps frame restored 23822; final `lifecycle=PASS reason=assignment-released` at 23823. Final PASS is **correct cleanup**, not sustained Maps/pane product success.

## The 2 October owner snapshots: exact evidence vs unsupported inference
All **46** unique records contain `mapsNativeOwnerProven=false` and `kind=carplay-live-owner-readonly`. Schema1 (40 records): 7 of 40 show 2 actual external CarPlay window scenes (statusbar + Dashboard), including `DBDashboardRootViewController` and **a full-screen `DBApplicationSceneViewController` at 427×240 inside Dashboard**; later 33/40 have `scenes=[]` due to no reachable observation, not proof scene destruction. Schema2 records after CarPlay process PID changed also show dashboard tree and app scene during first 4 records, none during last 2. These show CarPlay process/window/widget/controller topology but **no verified bundle identity of the DBApplicationSceneViewController as Google Maps** and no verified current Maps ownership, touch/continued nav or pane membership. `DBMapsNavigationWidgetViewController` and `DBMapsWidgetViewController` are Dashboard **widgets**, not by themselves the `com.google.Maps` native application scene. `sceneHostViewStatus=present-UIView` proves only an observed UIView; `mapsNativeOwnerProven=false` is explicit provenance limitation. All records from October 28 predate Gate0 by ~10 days and have no ON/OFF source tag.

## Product verdict, diagnosis and safe next action
**Audit12 = QA182 native launch + initial UIKit placement reproduced 12/12, split fails 12/12**. Observed dominant failure = old single-host CarPlay native-owner lease becoming false when Maps takes foreground, SB watchdog stops all Chrome panes, with presentation also still routed through original Dashboard rather than an independently owned split pane. Neither Audit12 nor the October owner logs proves OFF mode. Do NOT disable Home watchdog, force CarPlay Settings ON, reuse phone Maps, or declare success from `frame PASS`.

**Important current branch distinction:** separate Gate0 diagnostic built from `feature/duoface-gate0-onoff-readonly-20261107`; the original package `0.0.1~gate0readonly1` writes stand-alone JSONL only. Later commit `8668f85080385ea2b4f9d1445a6f9a4597005ebd` attempts to mirror Gate0 records into `/var/mobile/Library/Logs/DuoFaceDeepTrace.log`, which the existing iPhone **DuoFaceAudit.txt** exporter *already includes*. GitHub Actions run `42328683349` is CI SUCCESS at that commit but **no device injection/effect check**, so this new logger is **not verified installed or included in Audit12**. Review ObjC newline escaping in `DFG0MirrorToAudit` (`\\n` currently seems to emit literal slash-n, not newline) and log visibility/permissions before distributing; no server GitHub hook can read device files by itself.

**Next reproducible action:** first install a separately signed, corrected private Gate0 Audit-mirror build on parked device *if desired*, verify `area=gate0` and `abi.metadata` records actually appear in next normal `DuoFaceAudit.txt`; if not, fail closed with injection/file-permission diagnosis. Separately locate and calibrate authentic Apple per-car CarPlay Customize ON/OFF reader; current probe candidates remain `UNKNOWN/UNVERIFIED` even if loaded. Only after same paired-car ON→OFF→ON and OFF native-scene proof should a first-party unified **presentation-owner + watchdog lease** patch be evaluated with sustained map pixels/hit-testing/second app and genuine CarPlay Home grid.

## This turn's execution
Read GitHub `main` log directory metadata and blob SHAs, fetched full Audit12 by exact Git blob `ef159...` (fetch_file content was empty because 6.2MB) and both full JSONL via GitHub connector, parsed structured events / 12 per-assignment windows / 46 unique JSONL records and confirmed old timeline, examined source `DFNativeDiagnostics.m` and probe `DFGate0CarPlayProbe.m`. **No source/runtime patch, new CI build, Sileo publish or physical device test in this user request.** This report/hand-off should be re-read after GitHub write to confirm persistence. No secrets stored.
