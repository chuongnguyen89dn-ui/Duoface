# 2026-11-07 — Gate0 real-device trace + audit2 corrective diagnostic (QA182 preserved)

## User request / immutable scope
- User: “Tiếp tục công việc duoface hiện tại”. Continue the existing DuoFace native Maps/CarPlay Home investigation, **not** a new QA chain or broad unrelated changes.
- Work from `chuongnguyen89dn-ui/Duoface`, canonical SidePlay handoff `sideplay/tiep tuc du an.md` on `spec-main`; diagnostic source branch `feature/duoface-gate0-onoff-readonly-20261107`. QA182 signed source, QA180/H1/keyboard, SpringBoard watchdog and public Sileo must remain untouched. Keep native CarPlay Google Maps, same-car **Customize OFF hard release gate**, two-pane touch/Home restoration. Do not substitute phone Maps or force CarPlay Home icon ON.
- This is independently authored DuoFace source using original OmniCar/DuoNavi research as **behavioral reference**, without copying vendor source, binary or license logic.

## New REAL inputs discovered on log branch main
Read the directory metadata using live GitHub connector, **main head `10dbf43a266b01cff6a70f763785487eefb79793`** at inspection. User uploads include:
| File, `sideplay/log/` | Blob SHA-1 | Event time; interpretation |
|---|---|---|
| `DuoFaceMapsGate0-CarPlay.jsonl` | `c484d98cb085823a60d43297185977716e74dcd4` | 200 valid JSON objects, **2026-11-07 02:11:33–02:18:55 UTC**, CarPlay process PID 6259 |
| `DuoFaceMapsGate0-Preferences.jsonl` | `6c7cd51555f2f942c5823657c16e08af320fe4aa` | 4 valid JSON objects, **2026-11-07 02:11:25–02:11:26 UTC**, Preferences process |
| `DuoFaceAudit 13.txt` | `e8c3a579a27c61209e0de556f166e57fa5fa2c06` | Actual header **2026-10-30 08:43:52 UTC**, exporter 0.0.90~nativegetters1, not a Nov7 Gate0 audit |
| `DuoFaceAudit 14.txt` | `3a4203db0f013ab45a6cc129a07a6eb045b6ca6e` | Actual header **2026-10-30 14:14:02 UTC**, exporter 0.0.90~nativegetters1, not a Nov7 Gate0 audit |

Audit13/Audit14 were retrieved from Git blobs because `fetch_file` produced empty content on their 4–6MB sizes. Both show **zero** `area=gate0`; this is explained by their older timestamps and **must not** be used to assert the Nov7 probe failed to inject.

### Measured output from real Gate0 JSONL, not predictions
- CarPlay 200 total = `start.readonly` 1, `stock.candidate.discovery` 15, `abi.metadata` 15, `settings.runtime.classes` 15, `presentBase.hook-readonly` 1, `native.scene.snapshot` **148**, `presentBase.original-returned` **5**. Preferences 4 total: start/discovery/ABI/class record each 1.
- This **verifies read-only injection** into the CarPlay and Preferences processes on the hardware and that the native method hook was entered; it does not by itself verify the separate DeepTrace mirror.
- All 204 rows: `stockSettings=UNKNOWN`, `stockSourceStatus=UNVERIFIED`, `stockSource=UNVALIDATED_CARPLAY_ICONSTATE_CANDIDATES`, `stockProfileMatch=false`. **No authenticated Apple per-car ON/OFF reader or independently calibrated OFF window.** Gate0 ON/OFF verdict **MEASUREMENT_BLOCKED**. Do not treat `mapsPresent` in the 28/29 candidate files as ON.
- ABI in actual CarPlay log: `DBDashboardRootViewController presentBaseViewController:animated:launchSource:completion:` = **`v44@0:8@16B24Q28@?36`**; `dismissBase=v28@0:8B16@?20`; `layout=v16@0:8`; `nativeFrame={CGRect={CGPoint=dd}{CGSize=dd}}32@0:8@16@24`; `nativeInsets={UIEdgeInsets=dddd}32@0:8@16@24`; `homeEvent=v24@0:8@16`; `destroyScene=v32@0:8@16@24`. These are runtime ABI observations, **not** proof of pane ownership.
- All five `presentBase.original-returned` records say `controller=DBApplicationSceneViewController`, target `com.google.Maps`, scene IDs:
  - 02:11:48 UTC: `Car[2-3]:com.apple.CarPlayTemplateUIHost:com.google.Maps`, launchSource=3, no assignment;
  - 02:12:29: same scene, assignment prefix `54F33FA2`, physical slot 0;
  - 02:13:20: `Car[2-5]`, assignment prefix `DD3DC82B`, slot 0;
  - 02:14:57: `Car[2-7]`, assignment `558EE72F`, slot 0;
  - 02:15:08: `Car[2-7]`, assignment `90D9417A`, slot 0.
  Original call synchronous durations: ~28, 18, 10, 5, 6ms. **148 tree snapshots** all have `sceneCount=0` and empty `scenes`. This is a **probe traversal/ownership discrepancy**, not proof that Maps scenes were impossible, displayed, or touchable. Exact source had `if(ws.screen==UIScreen.mainScreen)continue;` which can erroneously skip windows in the CarPlay-process main display; the presenter may also not own the view in any traversed root tree.
- Candidate reader discovered **29 candidate plists** on both processes; 28 contained some reference to Maps. `fileId=b83570fc7004961b` (DISPLAY) changed hashed Maps path `ed212f8560abcf47`→`cfbc713c215cf74e` between initial and 02:12:03 snapshot, back to `ed212f8560abcf47` by 02:13:34. Multiple OTHER candidates changed mtime/size around the run. No vehicle ID/selector/semantics/calibration was available: **no inference about ON or OFF** from those hashes.
- Current `DFGate0CarPlayProbe.m` source (prior branch head `8668f85080385ea2b4f9d1445a6f9a4597005ebd`) also had an audit mirror `\\n` Objective-C string escape; that generates literal backslash-n rather than LF. It separately repeated the full candidate scan and roughly 29 candidate entries on every event, inflating trace volume and risking exporter tail loss.

## Actual source change — audit2 (one atomic branch commit)
**Branch:** `feature/duoface-gate0-onoff-readonly-20261107`; before `8668f85080385ea2b4f9d1445a6f9a4597005ebd`; committed and verified new head **`a4be9544e528e5374e1ed0665d1a4a44b233a853`**.
- `sideplay/gate0-carplay-maps-probe/DFGate0CarPlayProbe.m`: replace doubled slash-n with real Objective-C escaped LF; write receipt `auditMirrorWrite=complete|failed` to independent process JSONL; on each event use **cached** candidate count/age instead of rescanning plist & duplicating the whole candidate list. Discover/rehash on the existing 30-second tick only; unknown source has `stockSampleWall=0` (no counterfeit ON/OFF readout).
- Add **weak, non-owning** readback of last Google Maps presentation target and its loaded UIKit view/window, role, screen relation, parent, frame, scene ID; sample relevant scenes even when `ws.screen == UIScreen.mainScreen`; stamp window count and CarPlay role count. This only observes, never forwards differently or re-parents views.
- `sideplay/gate0-carplay-maps-probe/tests/test_gate0.py`: added explicit audit newline, record receipt, cached readback and screen role tests while retaining fail-closed ON/OFF tests.
- `sideplay/gate0-carplay-maps-probe/build_private_probe.sh`, `.github/workflows/duoface-gate0-onoff-readonly-signed.yml`, `README_ONE_RUN.md`: atomic package version bump **`0.0.2~gate0audit2`**, private signed CI only; no public publish or device deployment.

**CI:** GitHub Actions [run 42330321209](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/42330321209) triggered from exact new commit. Source-contract job `128275124639` **completed SUCCESS** (negative/regression source tests + unmodified QA182/H1 diff). Mac signed-private build job `128275199744` was IN_PROGRESS at first check; check its final result/artifact before claiming package is available. CI, even when passing, cannot validate installed device, OS Settings source, pane/Maps pixels/touch or OFF gate.

## Next reproducible action / success criteria
1. Confirm CI signed-private build success and exact artifact SHA/DEB metadata/ldid signature; if compiler/test fails, fix only Gate0 source and rerun. **Do not install old 0.0.1 again** expecting audit2 readback.
2. In parked test car only, install newer *separate* `com.duoface.carplay.gate0probe` DEB, reconnect affected CarPlay processes; export usual DuoFaceAudit and independent `DuoFaceMapsGate0-CarPlay.jsonl`, `DuoFaceMapsGate0-Preferences.jsonl`. Verify audit2 version, `auditMirrorWrite`, one event per physical line, window/lastPresent readback and 5-type ABI trace under real Maps launch. If audit mirror failed, record filesystem permission cause; if succeeded but missing from audit, check exporter tail/coverage (no false success).
3. Independently validate actual Apple per-vehicle Customize ON→OFF→ON reader with fresh source/profile stamps per event; only then run `analyze_gate0.py` for ON/OFF scene verdict. If no source, keep `MEASUREMENT_BLOCKED`. A known live scene ID without actual CarPlay window, hit testing, map pixels and two panes is **not** product success.
4. After a **verified OFF-native-scene path** exists, design first-party unified Dashboard presentation-owner plus fresh SpringBoard ownership attestation; preserve strict watchdog/Home rollback. No QA182/QA183 changes from this diagnostic.

## Execution truth and provenance
Tools used: live GitHub connector `get_repo`, `fetch` (directories/branches/runs), `fetch_file` (JSONL/source), `fetch_blob` for large older audits, `create_blob`+ `create_tree`+`create_commit`+`update_ref` to fast-forward only Gate0 source branch. Logs decoded and group-counted from real GitHub text, not generated synthetic test events. No local iPhone, CarPlay hardware or signing keys accessible in this chat; no installation, car test, or Sileo promotion claimed. No secrets recorded.
