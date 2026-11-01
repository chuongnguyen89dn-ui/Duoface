# QA160 WIP — ứng dụng mở chậm + Home về Dashboard thay vì lưới ứng dụng (2026-11-01)

## Yêu cầu mới — trạng thái phần cứng
Người dùng xác nhận QA159 không còn menu chọn app của DuoFace, nhưng Home từ app mở độc lập quay về **CarPlay Dashboard (bản đồ + Đang phát)**, thay vì **CarPlay Home native icon grid**; đồng thời mở app phản hồi chậm. Cả hai cần sửa; không lấy việc Dashboard hiện được làm PASS. Chưa có log thiết bị hậu QA159 tại đúng path theo lần kiểm tra này.

## Bằng chứng gốc đã đọc
- DuoFace real Log26: `sideplay/audit/qa156-log26-home-rejected-20261101/LOG26_EXCERPTS.txt` và `FINDINGS.md`: 5 request Facebook/Safari/YouTube, `native-dashboard-context-verified` và `qa152-native-prep-resume cause=native-chooser-ready`; `scene-hosted-render-and-touch-unverified` và native Dock ACK. **Tap -> manager hosted receipt** 130–536 ms; **không phải** thời gian tới frame đầu hoặc cảm ứng thực sử dụng.
- DuoNavi real Observer3: `sideplay/audit/duonavi-homeflow-observer-20261101/DEEP_ORIGINAL_LIVE_ORDER_REAUDIT_20261101.md`: 3 unsupported-app launches: manager state +90–195 ms; not first app frame. Trong các lần Home tương ứng, manager CarPlay thực hiện `stopBridging/requestDismiss/bridgeDidDeactivate` tại local Home callback, SB remote state đến sau. Chưa có marker trang GRID hay Dashboard sau Home.
- DuoNavi Observer4: `sideplay/audit/duonavi-homeflow-observer-20261101/OBSERVER4_LIVE_APP_OWNER_PICKER_TRACE_20261101.md`: factory runtime có `CBBridgedUIApp` và `CBBridgedSplitApp`, manager-owned window/picker; không chứng minh bộ chọn Home grid như mong muốn.
- Apple hướng dẫn phân biệt CarPlay Home app-icon grid và Dashboard map+Now Playing: https://support.apple.com/en-hk/guide/iphone/iph5f6b2beb5/ios
- Source baseline `2b6fef143c19dfd4d4b8557ca03b322aba711ae2`: `DFSceneHost.m` polls readiness bằng NSTimer 0.35s; `DF153PhoneEviction.h` có bounded 120ms fallback **chỉ khi app đang foreground iPhone thực sự**. Không được kết luận 120ms luôn phát sinh hoặc 350ms là tổng độ trễ thực tế.
- Native Home `DF144Launch` chặn selected Home icon và gửi riêng solo SpringBoard host; `DFCarPlayOwnerObserver.h` chuyển notification dừng và vẫn forward original Apple callback; `DFNativeDockSync147.h` chỉ chỉnh Dock/Home-button displayState; chưa có chứng cứ native app-grid page owner được khôi phục. Không fake private Home, không gọi lần thứ hai.

## Công việc đã ghi lên nhánh tính tới source commit 38f2910
- `DFSceneHost.h/.m`: thêm `setFastInitialPolling` áp dụng **riêng** SOLO, probe 0.10s thay vì 0.35s **chỉ tới first genuine ready**, sau đó trả về 0.35s. Preserve existing owned-scene gate, không coi scene/touch đã READY khi chưa xác nhận.
- `DFHomeStandalone144.m`: opt in first-scene probe trước `addSubview`; thêm `qa160-native-grid-icon-pressed`, bridge-accepted/forwarded và `qa160-native-home-page-snapshot-not-pixel`, log read-only native controller/visible window & Home-button state.
- `DFCarPlayOwnerObserver.h`: snapshot Home native before and after original Apple callback, +200ms, không chặn original.
- `DFNativeDockSync147.h`: `qa160-request-to-dock-ms`, ghi rõ touchReady unknown.
- `tests/test_qa160_homegrid_latency.py`: source assertions (new, no CI run passed).
- Bump **source-only** metadata `Info.plist`, `control`, `build.sh`, `package_integrated.py` sang `0.0.160~homegridprobe1` (host `0.1.160~homegridprobe1`). KHÔNG đồng nghĩa DEB đã build hoặc được đưa lên Sileo.
- No native grid routing fix asserted; diagnostic only. No vendor binary/licensing copied.

## CI thực tế — FAIL, không phát hành
- `Duoface` Actions run [41286992937](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41286992937), head `38f2910`, completed FAILURE at early test step; exact job log: `test_qa144_no_split_home_redirect.py:59` still asserted old host version `0.1.159~nativehome1` whereas source now 0.1.160. Build and signing steps SKIPPED.
- Earlier scoped run [41286934845](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41286934845) failed **intentional frozen SHA guard** `test_qa148_real_pid_and_stop_identity.py:47`: historical DFSceneHost blob SHA `aeb6178654eebe3a052e358febcc0b2519c3ac54` differs from edited `d1a71c03041d0d71f4a4ac6364ee14f84bf7f3de`. The guard needs an explicit reviewed migration; do NOT bypass a freeze assertion or claim regression safe.
- Attempts to update old `test_integrated_package_144.py` version assertions through authorized GitHub update_file were **rejected by tool-level safety validation**; no successful test migration. No workaround, no skipping safety checks. `test_qa144_no_split_home_redirect.py`, `test_qa145_controlled_home.py` and `test_integrated_package_144.py` still pin 159; QA159 private workflow also pins 159.
- No signed QA160, artifact, Pages, Sileo or device measurement. **Current public Sileo remains QA159** at existing `carplaydsp` feed, not modified.

## Exact resumption and success gates
1. Resolve safety/permission blocker for applying legitimate reviewed test migrations. Inspect frozen `DFSceneHost` diff against golden SHA and explicitly review lifecycle/rollback compatibility; if unable to prove stable, revert fast-probe change rather than falsifying hash assertion.
2. Update **existing** old version-specific static tests and signed workflow to validate 160 (retain legacy regression tests), add new QA160 tests; run all checks on exact branch. Do not publish when any guard fails.
3. Compile/pack/sign integrated QA160 in *existing* DuoFace workflow, capture run ID, source SHA, artifact SHA and archive under `sideplay/jb-embedded-appbridge/evidence/runs/<run>/`.
4. Only after green CI release through existing `chuongnguyen89dn-ui/carplaydsp` Pages publisher preserving QA159 rollback. In a parked CarPlay test, gather newer log with precise icon-tap -> request -> SB received -> scene live -> actual usable touch and Home page before/after. Compare to genuine original *same device* control and verify Home returns to **native icon grid**, not Dashboard, and touch-ready is faster. No fabricated timings.
5. Update `sideplay/tiep tuc du an.md` with actual new verification. Public Sileo QA159 remains the known physical Home-Dashboard FAIL.
