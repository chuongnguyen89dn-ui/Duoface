# QA160 real-device new uploaded log cfd887 — app sequence & perceived later-launch slowness (2026-11-01)

## Source, scope, validation
- New manual export is **ACTUALLY PRESENT**: `Duoface/main:sideplay/log/DuoFaceAudit.txt`, upload commit `cfd88719c61ad793892de13f8bcfeb071d2c2f4d` (2026-11-01 08:38:21 UTC), Git blob `49a57e4f1be42eec903a1f9aaf1d77e1e54411d5`, 5,904,458 UTF-8 characters, 36,576 lines. Header says export 2026-11-01 08:37:33 +0000; device iOS 16.7.16.
- Existing GitHub connector fetch_file on this large blob returned empty body; validated and parsed **real raw UTF-8 body** via authorized GitHub API `contents/sideplay/log/DuoFaceAudit.txt?ref=main` using `mcp__GitHub__fetch` directly in tool JS, not fabricated extraction. Sections: `DuoFaceStandalone144.log` lines 15041–16182, `DuoFaceSceneHost.log` 393–3768, `DuoFaceDeepTrace.log` 31927–36576. Raw evidence stays in main user log; only forensic results saved here.
- QA160 `qa160-native-grid-icon-pressed` 10 events; 9 supported bridge requests and 1 normal app `com.duoface.native.scenehost` forwarded to original. All nine bridge requests correspond to live scenes and native Dock ACK. No physical first pixel/touch timestamp present; `scene-hosted-render-and-touch-unverified` is expressly not proof that it rendered and accepted touch.

## Nine QA160 launch chains from **actual raw logs**
Timings are computed from native icon pressed to actual logged events (rounded milliseconds). These are **technical receipt measurements**, NOT user-visible app load or usable-touch latency.

| Sequence / selected app | Icon tap epoch UTC | Before SOLO mount | Scene-hosted receipt | Native Dock ACK | Source `qa160-request-to-dock-ms` |
|---|---:|---:|---:|---:|---:|
| 1 Facebook | 1793521595.790 | 76 ms | 150 ms | 158 ms | 155.0 ms |
| 2 Gemini | 1793521601.114 | 41 ms | 236 ms | 241 ms | 239.9 ms |
| 3 YouTube | 1793521610.780 | 54 ms | 267 ms | 276 ms | 275.8 ms |
| 4 Facebook again | 1793521628.250 | 90 ms | 192 ms | 210 ms | 204.9 ms |
| 5 DuoFace NativeHost (normal original forward) | 1793521632.353 | n/a | n/a | n/a | n/a |
| 6 Safari | 1793521636.525 | 78 ms | 207 ms | 214 ms | 209.6 ms |
| 7 com.wynauto.wyn | 1793521647.538 | 80 ms | 272 ms | 286 ms | 280.0 ms |
| 8 Facebook again | 1793521676.282 | 76 ms | 263 ms | 279 ms | 275.4 ms |
| 9 YouTube again | 1793521694.777 | 107 ms | 228 ms | 246 ms | 240.1 ms |
| 10 YouTube again | 1793521709.893 | 90 ms | 132 ms | 134 ms | 128.6 ms |

- Facebook first 155ms Dock-ACK versus later Facebook 205ms and 275ms **confirms later controller/scene receipts were 50–120ms slower** in this sample. There is also variation in the opposite direction (YouTube 276→240→129ms); therefore no evidence of monotonic slowdown per switch and no basis to claim every subsequent launch necessarily slower.
- QA160 SOLO poll first scene 0.10sec confirmed by `qa160-fast-initial-probe-complete` for real recorded apps, then it returns to heartbeat 0.35sec. Source `DFSceneHost.m` retains `[NSTimer scheduledTimerWithTimeInterval:0.30]` **between owned scene readiness and remote geometry reference write**, visible in DeepTrace as `scene-handle-observed-render-unverified` followed ~0.30s by `geometry-before-reference-setters` and `media-reference-committed-after-stable-viewport`. Delaying reference means initial scene may show wrong phone-sized frame until commit; **causal effect on perceived slowness is plausible but not yet visually proved**. The 0.30s debounce intentionally protects split/zoom/YT/GOFA and must NOT globally decrease.
- Source `DF144Solo.begin` creates new external `UIRootSceneWindow`, controller, `SBAppViewController`, and start for each request, and `stop` releases old host. Hence each independent app switch recreates an owned remote scene; no cached instant native scene handoff.

## Actual native Home observations
- For QA160 Facebook after user pressed Home, `qa160-native-home-page-snapshot-not-pixel` at 1793521598.864 (before) shows buttonState=0; immediately after native handler 1793521598.889 state=1; +200ms 1793521599.094 state=0. Similar sequences for Gemini, Safari, YouTube. `solo-native-home-own-bridge` and `qa147-native-dock-restored native-home-stop` occur within native callback, then SpringBoard `qa159-native-home-stop-no-chooser` asynchronously.
- Snapshot's `visible` names simultaneously include `DBDashboardHomeViewController`, `DBFolderController`, `DBTodayViewController`, `DBMapsWidgetViewController`, `DBNowPlayingWidgetViewController` (controllers loaded/attached, **not pixel visibility**). Their coexistence cannot prove icon grid is displayed. User physically confirms final result is Dashboard map+Now Playing; this is real physical FAIL.
- `qa151-native-workspace-live-owner` for these requests: `showingApp=NO activeBundle=com.apple.CarPlay.dashboard` and `qa152-native-prep-resume cause=native-chooser-ready`. DuoFace's independent SB scene is never recorded as an activated Apple dashboard workspace app. No guessed dashboard/grid switch should be shipped.

## Engineering priorities grounded by this log
1. Do **not** confuse 128–280ms scene/Dock ACK with first touch or initial pixels; user complaints may occur after scene exists, app UI startup/loading or remote orientation/geometry.
2. For a bounded latency improvement in the existing independently hosted SOLO route, consider shortening **ONLY the first owned-SOLO geometry commit debounce** from 0.30s to a measured lower bound (e.g. 0.12s), only on a visible/live attached scene and only for non-YouTube/non-GOFA apps, preserving 0.30s for split/divider/zoom and all YT/GOFA; compare actual scene frame and touch for regression. Need to inspect exact source invariants, frozen baseline tests and sign/CI; not a confirmed speed fix.
3. For native-like parity, the structural issue remains: Apple native launch is intercepted and replaced by SpringBoard separate overlay. Investigate verified CarPlay-native DBWorkspace-owned app scene activation with typed ABI and app scene-role compatibility, not guessed Home grid button toggles. Original vendor manager evidence + public independent CarSurf source referenced in prior detailed audit. Never double-launch both routes.
4. User expects Sileo integration for each real patch, preserve public QA160 rollback; no build/deploy claim without success run and verified public SHA.
