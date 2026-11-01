# QA166 — Evidence gate for actual GOFA traffic warnings and turn-by-turn navigation
Date: 2026-11-01. One independent DuoFace project; no CarPlayPro license, binary patch or activation bypass.

## Latest user decision
**Priority is real traffic warnings and upcoming navigation turns/distance**, not a cosmetic GPS-speed HUD. User requested behavior comparable to CarPlayPro Speed. Do not fabricate speed limits, camera alerts, signs, directions, or route distance; do not call source/live functionality implemented until sample provenance is measured.

## Original DEB evidence (static, independently preserved)
- Original archive: `Duoface/main:sideplay/audit/com.carplaypro.speed_0.9.97_iphoneos-arm64.deb` SHA256 `e5b0918b3bc1948420f37a8a9e21365756da46fba44d582a3f2893aee9b4102f`.
- Full static audit CI `41292790813` SUCCESS; 94 payload files, 10 ARM64/ARM64e slices, binary plist and disassembly archived on `main` under `sideplay/audit/carplaypro-0.9.97/`.
- Source of specific evidence: `main:sideplay/audit/carplaypro-0.9.97/macho/007-SpeedAlerts.dylib-arm64.section-strings.json` exact **Git blob `b8db68f5314b386dad24835f32f74cdf4086e35e`** and original disassembly `disassembly/007-SpeedAlerts.dylib-arm64.arm64.txt.gz`. Decoded original artifacts from repo directly, NOT decompiled original ObjC/Swift source.
- SpeedAlerts filter explicitly includes `com.apple.CarPlayApp` and source apps `com.lumi.GOFA`, `vn.vietmap.live`, `vn.vietmap.live.v2`, `com.wynauto.wyn`, `su.navitel`.
- Relevant observed original strings: `GOFA.SpeedBoardModel`, `GOFA.DatapointModel`, `Swift.Array<GOFA.DatapointModel>`, `currentAllowSpeed`, `notificationSpeedBoard`, `notificationNextBoard`, `notificationOtherBoard`, `pushOtherBoardToCarplay`, `flutterDirection`, `gofaAlertAccepted`, `gofaAlertRejected`, `gofaAlertGroups`, `cameraUpcoming`, `navigationSample`, `upcomingManeuvers`, `distanceRemaining`.
- Exact symbol records include `_SAGofaSpeedPayload` (value `254860`) and `_SAGofaAlertPayload` (value `256316`) in original arm64; matching Swift helper symbols are present. These support a GOFA-specific source path and alert-processing code, but not a safe inference about object layout, Swift ABI, notification type, or which class publishes an event at runtime.
- `CPSpeedPrefs` decoded plist contains user settings `showRoadAlerts`, `showNavigation`, warning mode/overspeed tolerance, and 5 source choices. This documents intended feature surface, not guaranteed device behavior.

## Compared to live DuoFace QA165 source
- `DFGofaNativeLocationTap165.m`: only intercepts GOFA CoreLocation delegate and publishes km/h; actual callback not observed on user's device. Old autonomous `DFGofaSpeedSource162.m` disabled via `-DDF165_PASSIVE_GOFA_ONLY=1`.
- `speed8/DFSpeedTransport.mm`: only GOFA speed, explicitly disallows speed limit `hasLimit`, provides no alert/turn IPC payload.
- `speed8/DFNative8SpeedHUDView.mm`: draws a speed pill and unknown limit ring; no real signs, camera, turn arrow, road-alert distance. Code may render `—`, not a real alert.
- QA165 CI `41306934372`, Sileo release `41307657432`: signed and public bytes verified. **No physical road alert, GPS callback, CarPlay z-order, navigation event, or source lifecycle proven**.

## Safe QA166 source work (NOT a functioning traffic alert)
- New `sideplay/duoface-native-scene-host/DFGofaTrafficNavProbe166.m` reads class names and available method type encodings for `GOFA.*Board*`, `GOFA.*Datapoint*`, `GOFA.*Navigation*`; observes **candidate** NSNotification names above only if actually posted, and logs **only type/payload-key COUNT**, no coordinates, route text, identifiers, objects or values. It neither swizzles/patches GOFA methods nor creates a location manager. It deliberately does **not** guess Swift method invocation or traffic-field map.
- Exporter `DFNativeDiagnostics.m` now lists `/var/mobile/Library/Logs/DuoFaceTrafficNav166.log` (read-only). The probe currently remains **source-staged on QA166 branch and is not wired into QA165 public build**. Therefore user cannot yet generate this log from the installed QA165 Sileo package.
- Targeted source test `tests/test_qa166_traffic_nav_evidence.py`, workflow `.github/workflows/duoface-166-traffic-nav-evidence-private.yml` check original **main** audit symbols by pinned Git blob, iOS16/arm64 Objective-C syntax, and no guessed payload producer. Initial CI `41311774157` failed only because original audit path was assumed present on feature branch; fix was to fetch pinned symbol blob from main in CI. Do not invent test pass before new run finishes.
- No binary built or installed from QA166. No change to public Sileo, QA165 fallback remains.

## Runtime evidence and implementation conditions
1. Prove GOFA actually exposes relevant class/selector or notification delivery on iPhone X iOS 16.7.16 **without violating original app workflow**. No device log yet.
2. Capture minimal type/shape and event sequence without private route text, coordinates, identifiers or licensing. Map **actual** GOFA event fields for speed limit, traffic sign/camera (kind and ahead distance), turn direction and maneuver remaining distance; cross-check against original CarPlayPro static callgraph. If Swift is not ObjC visible, do not invoke guessed selectors.
3. Only after sample schema validated: implement source-independent `DuoFaceRoadAlertSample` and `DuoFaceManeuverSample` with explicit validity/freshness and source identity, expiration, no cross-source merging, no synthetic values, sanitization, and reset on process suspension/disconnect.
4. Render one verified alert/icon/distance and one upcoming turn/distance in current DuoFace Speed8 overlay, with background-safe updates and no blocking Dock/touch; require physical CarPlay tests and rollback. Do not borrow vendor licensed binaries/activation.
5. Build a **new properly versioned integrated rootless DEB**, verify signing, source SHA, package contents, private CI, physical QA, then promote on the **existing** Sileo source (not a new repo) when approved for functional testing. Do not silently publish a misleading alert release.

## Precise verification commands
- Github Actions source evidence workflow: `git fetch --depth=1 origin main` then `git show FETCH_HEAD:sideplay/audit/carplaypro-0.9.97/macho/007-SpeedAlerts.dylib-arm64.section-strings.json > "$RUNNER_TEMP/carplaypro-speed-alerts-symbols.json"`, verify `git hash-object` == `b8db68f5314b386dad24835f32f74cdf4086e35e`.
- Run `DF166_ORIGINAL_SYMBOL_FILE="$RUNNER_TEMP/carplaypro-speed-alerts-symbols.json" python3 -m unittest discover -s sideplay/duoface-native-scene-host/tests -p 'test_qa166_traffic_nav_evidence.py' -v`.
- iOS syntax from root: `SDK="$(xcrun --sdk iphoneos --show-sdk-path)"`; `xcrun --sdk iphoneos clang -target arm64-apple-ios16.0 -isysroot "$SDK" -fobjc-arc -fblocks -O2 -Wall -Wextra -Werror -Wno-deprecated-declarations -framework Foundation -framework UIKit -fsyntax-only sideplay/duoface-native-scene-host/DFGofaTrafficNavProbe166.m`.
