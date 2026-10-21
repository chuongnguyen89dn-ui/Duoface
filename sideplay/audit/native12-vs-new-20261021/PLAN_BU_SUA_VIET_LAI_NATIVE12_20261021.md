# Native12 gốc ↔ DuoFace mới — MA TRẬN SAI / THIẾU / BÙ / VIẾT LẠI

**Ngày phân tích: 2026-10-21. Duy nhất hai DEB. KHÔNG đối chiếu DuoNavi.**

- Native12: `com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb`, SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`.
- DuoFace hiện tại: `com.duoface.jb.embedded_0.0.13~native12parity1_iphoneos-arm64.deb`, SHA256 `f33496cfc6221afe64bbc3fbcc3599ca079b76cbede80319c7e72e7b4b2fc02b`.
- CI đối chiếu [39598478579](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39598478579), bất biến; nguồn đầy đủ `results-0.0.13/{SUMMARY.json,FILE_INVENTORY.json,ALL_NATIVE12_1385_METHODS.json,FEATURE_GATES.json}`.
- Native12 **43 file/8 Mach-O/66 ObjC classes/1385 ObjC methods**; mới **28 file/5 Mach-O**. 292 mục có selector text chung: **không có nghĩa 292 hàm đã nối đúng**.
- Cùng một phần logic độc lập có thể gom nhiều file; không yêu cầu số file bằng nhau. **Chức năng/hành vi/scene tương đương mới là chuẩn.**
- 25/25 chức năng vẫn **CHƯA ĐẠT** tiêu chuẩn tương đồng đầy đủ (không nói 25 chức năng đều không chạy).

## Kết quả phân loại

| Đánh giá | Số nhóm | Ý nghĩa |
|---|---:|---|
| **SAI** | 9 | Đã code nhưng đường xử lý/giao diện/vòng đời khác Native12 |
| **THIẾU** | 6 | Gói mới thiếu implementation chức năng |
| **CÓ MỘT PHẦN** | 9 | Lõi hoặc UI đã có, chưa đủ chức năng |
| **CHƯA KIỂM CHỨNG** | 1 | Có mã nhưng thiếu stack/log và runtime CarPlay |
| **BÙ ĐƯỢC** | **9** | Giữ lõi tốt, bổ sung/hợp nhất code/asset/handlers |
| **CẦN VIẾT LẠI MODULE ĐỘC LẬP** | **16** | Thay phần sai hoặc tạo hệ thống còn thiếu; không đồng nghĩa xóa toàn bộ ứng dụng |

### Ma trận 25 nhóm

| ID | Chức năng | Đã thấy trong DEB/mã mới | Hướng xử lý | Ưu tiên |
|---|---|---|---|---|
| 01 | CarPlay native scene/admission | Sai/khác Native12 | **Viết lại** | P0 |
| 02 | Khởi động splash logo ngang và thanh tiến trình | Sai/khác Native12 | **Bù được** | P1 |
| 03 | Bộ chọn app cards/icon/Recent/paging | Có một phần | **Bù được** | P1 |
| 04 | Host app iPhone bình thường | Có một phần | **Viết lại** | P0 |
| 05 | YouTube/video/audio phát không Safe Mode | Sai/khác Native12 | **Viết lại** | P0 |
| 06 | Hiển thị hai app thật độc lập | Có một phần | **Bù được** | P1 |
| 07 | Cảm ứng hai app, scroll, player control | Có một phần | **Viết lại** | P0 |
| 08 | Chia màn và kéo tỷ lệ, nhớ tỷ lệ | Có một phần | **Bù được** | P1 |
| 09 | Hoán đổi trái-phải, giữ logo | Có một phần | **Bù được** | P1 |
| 10 | Phóng to một ô, hoàn tác | Sai/khác Native12 | **Viết lại** | P0 |
| 11 | Phóng to thật sự ẩn Dock, hoàn tác | Thiếu module | **Viết lại** | P0 |
| 12 | Tám layout, chế độ đa khung Native12 | Thiếu module | **Viết lại** | P1 |
| 13 | Thay app slot/close/restore/atomic state | Có một phần | **Bù được** | P1 |
| 14 | Đúng vị trí/timer/hitbox của các pill | Sai/khác Native12 | **Bù được** | P2 |
| 15 | Viền đỏ khi chạm và tự ẩn | Sai/khác Native12 | **Bù được** | P2 |
| 16 | Logo, icon, màu sắc, bo góc và hiệu ứng | Có một phần | **Bù được** | P2 |
| 17 | Về CarPlay Home ẩn thanh/menu tức thì | Sai/khác Native12 | **Viết lại** | P0 |
| 18 | Reconnect, exitmode, SpringBoard stability | Chưa đủ kiểm chứng | **Viết lại** | P0 |
| 19 | Dock và geometry nhiều màn CarPlay | Sai/khác Native12 | **Viết lại** | P0 |
| 20 | Audio focus và playback video | Thiếu module | **Viết lại** | P0 |
| 21 | Bong bóng HUD8 4 nguồn/tự ẩn | Thiếu module | **Viết lại** | P1 |
| 22 | Trợ lý nói chuyện/voice mic | Thiếu module | **Viết lại** | P2 |
| 23 | Cài đặt app iPhone/preferences | Thiếu module | **Viết lại** | P1 |
| 24 | Đồng bộ SpringBoard/CarPlay/app process | Sai/khác Native12 | **Viết lại** | P0 |
| 25 | Injection filters/entitlement lifecycle | Có một phần | **Viết lại** | P0 |

## Đường nối cụ thể theo từng ID

**01 — CarPlay native scene/admission (P0; Sai/khác Native12; VIẾT LẠI).** Native12: `CBWindow`, `CBBridgeManagerDashboard` (76 ObjC method entries liên quan, không nhất thiết là phương thức cần copy). Mới: `DFNativeHostAppDelegate.m; DFTouchOwnerProbe.m; DFFirstPartyAdmission.m`. **Chênh lệch:** Hai owner CarPlay/SpringBoard; template CPMapTemplate + SpringBoard UIWindow rời, chưa có state-machine admission/receiver như Native12. **Cách làm:** Tạo một bộ native scene ownership/ack + định tuyến receiver khi ForegroundActive, không chuyển app thành UI demo. **Đạt khi:** CarPlay app scene nhận trạng thái thực, các cửa sổ được tạo/đóng đúng scene; Home không bị overlay trễ.

**02 — Khởi động splash logo ngang và thanh tiến trình (P1; Sai/khác Native12; BÙ).** Native12: `CBSplitSplashScreenView` (32 ObjC method entries liên quan, không nhất thiết là phương thức cần copy). Mới: `DFNative12BasicController.m; DFNative12Chrome.m`. **Chênh lệch:** Hai splash độc lập: BasicController CPWindow logo fade ~1.5s và Chrome SpringBoard logo+line ~1.3s; không cùng điểm ready/dismiss. **Cách làm:** Dùng một launch session với onWillDismiss/onDismissed; logo+line chỉ do một owner render và bàn giao theo readiness. **Đạt khi:** Khi launch/reconnect không hiện pill trước splash hoặc splash chồng nhau; đạt kích thước/timing Native12.

**03 — Bộ chọn app cards/icon/Recent/paging (P1; Có một phần; BÙ).** Native12: `CBMultitaskingOverlayView`, `CBAppPickerViewController` (82 ObjC method entries liên quan, không nhất thiết là phương thức cần copy). Mới: `DFAppPickerVC.m; DFNative12Chrome.menuAction; DFAppLibrary`. **Chênh lệch:** UICollectionView card/Recent+pageControl đã có; chưa có preset/mode cards, restart/close running apps, shadow card/layout 1:1. **Cách làm:** Bù mode Style/preset, running/recent actions, shadows/hitboxes, state sync; không thay callback chọn app thật. **Đạt khi:** App/Recent/Style/Close/Restart hoạt động; card/page indicator đúng ảnh Native12 trên xe.

**04 — Host app iPhone bình thường (P0; Có một phần; VIẾT LẠI).** Native12: `CBBridgedUIAppView`, `CBBridgedUIApp` (45 ObjC method entries liên quan, không nhất thiết là phương thức cần copy). Mới: `DFSceneHost.m DFSceneSurface.start/pollScene/layoutScene/stop`. **Chênh lệch:** SBAppViewController/SBDeviceApplicationSceneEntity mở app thường; mode=2, handle ready chỉ kiểm scene tồn tại; lifecycle chưa so Native12. **Cách làm:** Giữ lõi host thật; viết lớp scene-transaction controller độc lập với ready/visible/attached/failed/closing và ABI typing. **Đạt khi:** App thường mở và đóng/lặp ổn, render thật không chỉ sceneHandle; không phá giao diện khi thay slot.

**05 — YouTube/video/audio phát không Safe Mode (P0; Sai/khác Native12; VIẾT LẠI).** Native12: `CBBridgedUIAppView`, `CBBridgedUIApp` (45 ObjC method entries liên quan, không nhất thiết là phương thức cần copy). Mới: `DFSceneHost.m layoutScene, pollScene, stop`. **Chênh lệch:** YouTube/video user báo SpringBoard Safe Mode; private media/orientation/audio lifecycle chưa có, bỏ nil FrontBoard transition chỉ giảm rủi ro. **Cách làm:** Thu SpringBoard .ips và event trace; thay media/orientation/teardown sai ABI, phân biệt app audio/video scene; tránh gọi private chưa chứng minh. **Đạt khi:** Mở YouTube/VLC, phát/seek/pause/tắt 10 lần không Safe Mode, stack không còn lỗi.

**06 — Hiển thị hai app thật độc lập (P1; Có một phần; BÙ).** Native12: `CBBridgedSplitApp`, `CBBridgedUIAppView` (78 ObjC method entries liên quan, không nhất thiết là phương thức cần copy). Mới: `DFNative12Chrome.m init/layoutControls; DFSceneHost.m`. **Chênh lệch:** Chỉ 2 UIWindow appSceneWindows, hostedScenes/pendingScenes/ready arrays size 2; hai app báo mở trên bản cũ, 0.0.13 chưa test. **Cách làm:** Mở rộng state động 1..4 slot, giữ atomic host và scene real; mô hình tách slots/layout, không nhân bản cửa sổ giả. **Đạt khi:** Hai app chạy đồng thời, chạm vào mỗi ô; bố cục 3/4 ô không làm mất scene.

**07 — Cảm ứng hai app, scroll, player control (P0; Có một phần; VIẾT LẠI).** Native12: `CBBridgedUIAppView` (29 ObjC method entries liên quan, không nhất thiết là phương thức cần copy). Mới: `DFSceneHost.m; DFNative12Chrome.m; DFTouchOwnerProbe.m`. **Chênh lệch:** App thường có touch; chưa chứng minh hitTest/touches forwarding trên video/scroll/cử chỉ khi đổi orientation/zoom. **Cách làm:** Giữ UIKit hit-test đang hoạt động; xử lý event ownership đúng app window/scene, tránh overlay intercept và các synthetic UITouch. **Đạt khi:** Tap/scroll/player controls trong hai ô và fullscreen thực, không crash.

**08 — Chia màn và kéo tỷ lệ, nhớ tỷ lệ (P1; Có một phần; BÙ).** Native12: `CBBridgedSplitApp`, `CBDividerView` (76 ObjC method entries liên quan, không nhất thiết là phương thức cần copy). Mới: `DFNative12Chrome.m DFCClamp/DFCSnap/layoutControls/dividerPan/DFCSaveLayout`. **Chênh lệch:** dividerPan ratio clamp 1/3..2/3 snap 4%; mới tính hai pane theo verticalDivider, thiếu mẫu multi-slot Native12. **Cách làm:** Giữ pan, persistence, thêm layout engine cho tám preset/4 slot và phân phối scene geometry thực. **Đạt khi:** Drag frame của mọi app đồng bộ, state restore và không stripe lệch.

**09 — Hoán đổi trái-phải, giữ logo (P1; Có một phần; BÙ).** Native12: `CBDividerView`, `CBSlotPillView` (63 ObjC method entries liên quan, không nhất thiết là phương thức cần copy). Mới: `DFNative12Chrome.m swapPressed/dividerPan/logoHold`. **Chênh lệch:** swapped boolean và logoTap; long hold thay vị trí logo chứ không phải mọi thao tác rotate/move/slot order Native12. **Cách làm:** Giữ tap swap, logo pan và hold 0.30s; thêm moveSlot, rotateAllSlotsClockwise/persistSlotOrder theo preset thật. **Đạt khi:** Tap, hold, đổi trái-phải và đổi ô trong 4-slot không lẫn app.

**10 — Phóng to một ô, hoàn tác (P0; Sai/khác Native12; VIẾT LẠI).** Native12: `CBBridgedSplitApp`, `DFFullscreenTransport` (85 ObjC method entries liên quan, không nhất thiết là phương thức cần copy). Mới: `DFNative12Chrome.m zoomPressed/menuAction/layoutControls; runtime/fullscreen/DFFullscreenTransport.mm (source tham khảo)`. **Chênh lệch:** focus chỉ đặt pane selected=contentRect; không có native fullscreen lease/state ACK/snapshot restore. **Cách làm:** Bổ sung độc lập focus transaction/lease/ack/rollback; tái dùng ý tưởng IPC có kiểm chứng từ code dự án nhưng không kéo host gốc. **Đạt khi:** Zoom/Restore trả về đúng frame, focus, ratio, scene/gesture qua 10 chu kỳ.

**11 — Phóng to thật sự ẩn Dock, hoàn tác (P0; Thiếu module; VIẾT LẠI).** Native12: `CBBridgeManagerDashboard`, `CBWindow` (76 ObjC method entries liên quan, không nhất thiết là phương thức cần copy). Mới: `DFNative12Chrome.m; DFNativeHostAppDelegate.m; runtime/fullscreen/DFHostGeometry.xm (tham khảo)`. **Chênh lệch:** Không có điều khiển AppDockVC system-owned; contentRect luôn trừ Dock, fullscreen không được ẩn Dock. **Cách làm:** Viết service Dock của CarPlay/Dashboard thật kiểm đúng process/ABI/window + trạng thái trước/sau; rollback nếu không có class. **Đạt khi:** Zoom In thực sự ẩn Dock và mở rộng đúng app; Zoom Out khôi phục Dock nguyên trạng, không che giả.

**12 — Tám layout, chế độ đa khung Native12 (P1; Thiếu module; VIẾT LẠI).** Native12: `CBDashboardSettings`, `CBMultitaskingOverlayView` (127 ObjC method entries liên quan, không nhất thiết là phương thức cần copy). Mới: `DFNative12Chrome.m init/layoutControls/menuAction case2; CBDashboardSettings original indices`. **Chênh lệch:** Style chỉ đảo verticalDivider và ratio=.5; 2 slot hardcoded, không có splitPreset, gridRows/gridCols 8 layout và 4-slot. **Cách làm:** Viết DFLayoutEngine với 8 preset canonical + frame cho 1-4 app, chọn preset cards; port thuật toán độc lập, không copy binary. **Đạt khi:** Cả 8 preset tác động app thật, kéo ratio/swap/focus vẫn đúng, lưu/khôi phục.

**13 — Thay app slot/close/restore/atomic state (P1; Có một phần; BÙ).** Native12: `CBBridgedSplitApp`, `CBBridgeManager` (124 ObjC method entries liên quan, không nhất thiết là phương thức cần copy). Mới: `DFNative12Chrome.m appPicker:didSelect/sceneReady/sceneFailed/closeHostedSlot; DFSceneHost.m`. **Chênh lệch:** Có pending host + old host retained đến sceneReady; scene ready chỉ sceneHandle+isHostingAnApp, render chưa chứng minh; no restart slot/all. **Cách làm:** Giữ atomic replace, bù restart, close all, recovery timeout/verified visible, persist slot order. **Đạt khi:** App cũ vẫn chạy nếu app mới fail, không lost focus hoặc tắt app khác.

**14 — Đúng vị trí/timer/hitbox của các pill (P2; Sai/khác Native12; BÙ).** Native12: `CBSlotPillView` (36 ObjC method entries liên quan, không nhất thiết là phương thức cần copy). Mới: `DFNative12Chrome.m layoutControls; sideplay/native12-display/DFSPNativeSlotPill.m (UI source)`. **Chênh lệch:** Pill size 38/44/64/76, focus 72/80; menu/zoom có state, nhưng original six modes/hitbox/autohide chưa xác thực. **Cách làm:** Bù native state machine empty/loaded/focused+compact, hide/reveal/activity timers, hitbox quan sát. **Đạt khi:** Pill đúng 76x22/bo 11 và trạng thái Native12, không chặn app.

**15 — Viền đỏ khi chạm và tự ẩn (P2; Sai/khác Native12; BÙ).** Native12: `CBBridgedSplitApp`, `CBDividerView` (76 ObjC method entries liên quan, không nhất thiết là phương thức cần copy). Mới: `DFNative12Chrome.m noteUserActivity/layoutControls; native12-display/DFSPNativeFrame.m`. **Chênh lệch:** Viền 1pt #E3020F ẩn sau 2.1s chỉ khi thao tác UI; không đúng session/border animation Native12; không viền khi focused. **Cách làm:** Bù event-based blinking/reveal/hide theo activity thực trên app window, không chạy permanent runner và không thêm touch layer. **Đạt khi:** Viền đúng hiệu ứng trên 2/4 slot, tự ẩn và không xuất hiện khi zoom.

**16 — Logo, icon, màu sắc, bo góc và hiệu ứng (P2; Có một phần; BÙ).** Native12: `CBMultitaskingOverlayView`, `CBSplitSplashScreenView` (98 ObjC method entries liên quan, không nhất thiết là phương thức cần copy). Mới: `DFNative12Chrome.m DFCArtwork; DFAppPickerVC.m; VisualAssets; app Info.plist`. **Chênh lệch:** 6 PNG được đóng giống byte theo basename nhưng 13 cặp trùng do nhiều path; icon gốc nhiều size, asset nhỏ/trạng thái menu chưa dùng đầy đủ. **Cách làm:** Tái dùng artwork đã được phê duyệt, bù các kích thước/icon/opacity/shadow/gradient và asset manifest; không chép Mach-O. **Đạt khi:** Đúng logo ngang/dọc/grip/picker/splash, màu và ảnh so Native12, không fallback SF Symbol khi có asset.

**17 — Về CarPlay Home ẩn thanh/menu tức thì (P0; Sai/khác Native12; VIẾT LẠI).** Native12: `CBWindow`, `CBBridgeManagerDashboard` (76 ObjC method entries liên quan, không nhất thiết là phương thức cần copy). Mới: `DFNativeHostAppDelegate.m stopTouchOwner; DFTouchOwnerProbe.m DFWatchdog/DFStopProbe; DFNative12Chrome.stop`. **Chênh lệch:** Đã đổi stop() ẩn windows trước scene invalidate; nhưng Darwin stop từ CPTemplate có thể tới muộn; watchdog 1s / stale 2.5s. **Cách làm:** Thay bằng Home activation owner + synchronous hide signal/visible generation ACK, session keyed teardown; watchdog chỉ fallback. **Đạt khi:** Ngay thời điểm Home không còn thanh, menu, black splash; 10 lần back/reopen không overlay treo.

**18 — Reconnect, exitmode, SpringBoard stability (P0; Chưa đủ kiểm chứng; VIẾT LẠI).** Native12: `CBBridgeManager`, `CBWindow` (112 ObjC method entries liên quan, không nhất thiết là phương thức cần copy). Mới: `DFSceneHost.m start/stop/pollScene; DFNativeHostAppDelegate; DFTouchOwnerProbe`. **Chênh lệch:** Nguồn có timer scene poll .35s, heartbeat .75s, watchdog, cleanup; chưa chứng minh interleaving/restart/multiple scene race. **Cách làm:** Viết deterministic state machine destroy/attach/disconnect, cancel timers generation, idempotent cleanup & receiver ack. **Đạt khi:** Không exitmode khi respring/reconnect/launch/close 10-20 chu kỳ; logs và .ips.

**19 — Dock và geometry nhiều màn CarPlay (P0; Sai/khác Native12; VIẾT LẠI).** Native12: `CBWindow`, `CBBridgeManagerDashboard` (76 ObjC method entries liên quan, không nhất thiết là phương thức cần copy). Mới: `DFNative12Chrome.m makeWindow/layoutControls; DFTouchOwnerProbe.m DFStartProbe`. **Chênh lệch:** App scene bounds phụ thuộc static contentRect và springboard UIRootSceneWindow; Native12 có carPlayContentInsets/usableBounds/updateCarPlayMetrics/dock owner. **Cách làm:** Viết geometry provider đo current CarPlay screen/Dock metrics và orientation/resize, relay thay đổi sang app scenes. **Đạt khi:** Dock normal đúng diện tích mọi xe, ẩn Dock đúng focus, tự scale 507x240/và màn khác.

**20 — Audio focus và playback video (P0; Thiếu module; VIẾT LẠI).** Native12: `CBBridgedUIAppView` (29 ObjC method entries liên quan, không nhất thiết là phương thức cần copy). Mới: `DFSceneHost.m; DFNativeHostAppDelegate.m`. **Chênh lệch:** Mới có SBAppViewController view transform 2x + requestedMode; không có media AVAudioSession/scene interruptions/route/focus. **Cách làm:** Tạo audio/media session lifecycle riêng có request/teardown, xử lý interruptions/rotation đúng process; cần device crash log. **Đạt khi:** Youtube/VLC âm thanh video ổn và không làm CarPlay audio focus hỏng.

**21 — Bong bóng HUD8 4 nguồn/tự ẩn (P1; Thiếu module; VIẾT LẠI).** Native12: `DFSpeedNativeHUD`, `DFSpeedSplit7Driver`, `DFOwnerPollingDriver` (45 ObjC method entries liên quan, không nhất thiết là phương thức cần copy). Mới: `New DFHUDOwner/DFHUDView/DFSpeedSource adapters chưa có; original method-index DFSpeedNativeHUD`. **Chênh lệch:** Không có DFSpeedNativeHUD/Owner implementation hay speed four-source service trong 5 Mach-O; original SpeedHUD/SpeedOwner chỉ có binary tham chiếu. **Cách làm:** Viết HUD8 độc lập (4 nguồn hợp pháp có dữ liệu), position/pan/close/opacity/settings+persist, host cùng lifecycle DuoFace. **Đạt khi:** 1 bong bóng tốc độ thực, chọn nguồn Waze/GMaps/VMaps/GOFA nếu dữ liệu có, sống/ẩn đúng vòng đời.

**22 — Trợ lý nói chuyện/voice mic (P2; Thiếu module; VIẾT LẠI).** Native12: `CBAssistantManager`, `CBBridgedAssistantView` (84 ObjC method entries liên quan, không nhất thiết là phương thức cần copy). Mới: `DFNativeHostRootController.m; new VoiceService to create`. **Chênh lệch:** Không có CBAssistantManager tương đương; new phone root chỉ status/apps, thiếu STT/AVAudioEngine/mic HUD. **Cách làm:** Viết voice service mới với Speech/AVAudioEngine + command router thật, server AI nếu cần; không gọi vendor backend/giấy phép. **Đạt khi:** Nhận mic, nói tiếng Việt, voice commands thật và báo lỗi server rõ.

**23 — Cài đặt app iPhone/preferences (P1; Thiếu module; VIẾT LẠI).** Native12: `CBGeneralSettingsViewController`, `CBSplitViewController`, `CBAppManager` (93 ObjC method entries liên quan, không nhất thiết là phương thức cần copy). Mới: `DFNativeHostRootController.m`. **Chênh lệch:** RootController có 2 tab Trạng thái/Ứng dụng chỉ đọc; CBGeneralSettingsViewController, CBSplitViewController, CBAppManager không có bản tương ứng. **Cách làm:** Tạo UI preferences/allow-list/layout/HUD/audio nguồn thật và store versioned, đồng bộ CarPlay qua một owner. **Đạt khi:** Thao tác cài đặt trên iPhone lưu và cập nhật CarPlay thật, không dùng danh sách chỉ đọc.

**24 — Đồng bộ SpringBoard/CarPlay/app process (P0; Sai/khác Native12; VIẾT LẠI).** Native12: `CBBridgeManager`, `CBBridgeManagerDashboard` (114 ObjC method entries liên quan, không nhất thiết là phương thức cần copy). Mới: `DFNativeHostAppDelegate.m consumeTouchCommand; DFNative12BasicController.m; DFNativeDashboardBridgeQA.m`. **Chênh lệch:** consumeTouchCommand chuyển setPresetRatio/performCarPlayControl sang DFNative12BasicController, nhưng phương thức này chỉ NSLog; main chrome sửa trong SpringBoard -> hai owner không đồng bộ ACK. **Cách làm:** Xây typed IPC command/state/ack, một owner duy nhất thay đổi layout/app/Zoom và receiver báo trạng thái thực; xóa receipt-only lệnh giả. **Đạt khi:** Touch input -> đúng owner -> state applied -> ack, hai tiến trình nhất quán với sự kiện Home/Zoom/video.

**25 — Injection filters/entitlement lifecycle (P0; Có một phần; VIẾT LẠI).** Native12: `CBWindow`, `CBBridgeManager` (112 ObjC method entries liên quan, không nhất thiết là phương thức cần copy). Mới: `DFTouchOwnerProbe.plist; DFNativeDashboardBridgeQA.plist; DFFirstPartyAdmission.plist; package_integrated.py`. **Chênh lệch:** Bản mới 4 tweak dylib vẫn có tên QA/preflight; source injection filters đang dùng SpringBoard/CarPlay và probe; original chia filter theo app/media/fullscreen/HUD. **Cách làm:** Kiểm entitlement/filter ABI mỗi process, loại module QA tạm sau khi thay đường thực, không ép entitlement vô tội vạ. **Đạt khi:** Sileo 1 app/DEB, chỉ inject đúng process, không treo SpringBoard; app và Dock hoạt động đúng.



## Những lỗi mã thực làm thay đổi hẳn kiến trúc (ưu tiên P0)

**1) Receiver CarPlay hiện nhận lệnh rồi chỉ ghi log.** `DFNativeHostAppDelegate.consumeTouchCommand` gọi `DFNative12BasicController.setPresetRatio:/performCarPlayControl:`, nhưng các phương thức đó chỉ `NSLog`; trong khi `DFNative12Chrome` tại SpringBoard tự đổi state chia/zoom/chọn app. Đây là **đường command/state/ACK chưa hoàn thiện**; bắt buộc viết receiver + định tuyến owner độc lập, không nhân đôi hai state manager.

**2) Hai splash ở hai tiến trình không cùng vòng đời.** `DFNative12BasicController` logo CPWindow fade sau ~1.5s, `DFNative12Chrome` logo và line chạy riêng ~1.3s. Native12 gốc có `CBSplitSplashScreenView.startLoadingAnimation`, `dismissAnimated:completion:`, `onWillDismiss/onDismissed`. Cần một launch-state owner, callback readiness và thứ tự đóng/mở; **bù được UI**, sửa synchronization, không dựng màn demo.

**3) Video/media:** user quan sát YouTube/VLC vào Safe Mode trên bản Sileo cũ. `DFSceneHost.layoutScene` dùng scale 2x / 0.5x, `pollScene` ready theo sceneHandle + isHostingAnApp; không có đường AV route/audio/orientation tương ứng Native12. Bỏ lệnh `updateSettings:...nil transition` chỉ giảm nguy cơ, **không chứng minh đã sửa**. Phải thu SpringBoard `.ips` để xác định fault ABI/process trước khi thực thi thay thế đúng.

**4) Zoom khác gốc:** `DFNative12Chrome.zoomPressed` chỉ focus pane vào `contentRect`, Dock Apple không được quản lý/ẩn. Native12 có `DFFullscreenTransport`, Dashboard `appDockVC` + chrome policy. `runtime/fullscreen/DFFullscreenTransport.mm` của dự án có mẫu request/ACK/lease/rollback có thể nghiên cứu, nhưng không thể ghép thẳng module có phụ thuộc `CBWindow`; phải viết owner fullscreen độc lập. **Không dùng cửa sổ đè giả Dock**.

**5) Tám bố cục/bốn app thực sự thiếu:** `DFNative12Chrome` có đúng hai UIWindow và các mảng state hai phần tử; menu Style chỉ đổi `verticalDivider` và ratio=.5. Native12 có `CBDashboardSettings.splitPreset/gridCols/gridRows/splitApp1..4` và `CBBridgedSplitApp.setSplitPreset/rotateAllSlotsClockwise/moveSlot`. Phải tạo layout/preset engine + scene host cho 4 app thật, giữ drag/swap/atomic replace đang hoạt động.

**6) Về Home chưa đồng bộ hoàn toàn:** sửa ở NativeHost `0.1.14` ẩn hết windows trước scene invalidate đã build PASS, nhưng `notify_post` CarPlay→SpringBoard có thể tới muộn; watchdog 1s/2.5s chỉ là fallback. Cần foreground-loss state/ACK/cleanup generation để tránh thanh/menu nổi lại trên Home; thử trên iPhone.

**7) HUD8 và voice/settings:** Original chứa `DuoFaceSpeedHUD.dylib`, `DuoFaceSpeedOwner.dylib` và classes `DFSpeedNativeHUD`/`CBAssistantManager`. Gói mới **không có** implementation speed source, HUD owner, speech/audio engine hoặc full settings. Chỉ có UI phone hai tab read-only. Viết module nguồn hợp lệ + thực, không ghép nhị phân giấy phép. Không hứa Waze/GMaps/VMaps/GOFA cung cấp API khi chưa xác minh.

## Những thứ tận dụng được ngay (mã nguồn độc lập của dự án)

- **Giữ và BÙ:** `DFNative12Chrome.m` (split ratio, logoHold 0.30s, swap, red border, pill); `DFAppPickerVC.m` (real bundle icon, Recent, pageControl); `DFSceneHost.m` (khung mở app thường, phần vận hành cần sửa); `sideplay/native12-display/DFSPNativeFrame.m`, `DFSPNativeSlotPill.m` (tham khảo hành vi/kích thước Native12).
- **Tái dùng ý tưởng, phải viết receiver/owner mới:** `runtime/fullscreen/DFFullscreenTransport.mm`, `runtime/fullscreen/DFHostGeometry.xm`, `sideplay/mytweak-native-bridgeqa/DFCPNativeBridgeQA.m`. Code QA lịch sử không đương nhiên đủ chuẩn iOS16/Native12.
- **Chưa có trong gói, phải viết mới:** Native media/audio scene lifecycle, system Dock owner, 8-preset/4-slot engine, HUD8 speed owner + adapters, voice service, phone settings, typed IPC state/ACK.
- **License khác là chủ đích, không phải lỗi cần sửa:** Native12 `CBBridgeManager.requestStateChange:` gọi license checks; tuyệt đối không copy/patch/hook bỏ qua bản quyền vendor. Thay **chức năng host độc lập**, không thay đổi quy tắc cấp phép của người khác.
- **Không lấy số file hoặc binary làm checklist sao chép:** `DuoFaceUI` nhiều AppIcon và `duoface_cboptimize_helper`/sudoers bản gốc không phải lúc nào cũng bắt buộc với kiến trúc độc lập. Phải xác minh vai trò trước, không bê nguyên DEB gốc.

## Thứ tự đủ để sửa A→Z mà không tạo demo mới

1. **P0: một owner CarPlay/SpringBoard + ACK → media video không Safe Mode → fullscreen thật/Dock → Home/reconnect + geometry.** Trước mỗi sửa tra `WIRING_REPORT.md` và method-index gốc, đối chiếu đúng caller/receiver/ABI, kiểm tra timeout/lifecycle.
2. **P1: 8 layout/4 slot thật + Style/close/restart/persist → HUD8 4 nguồn có dữ liệu → cài đặt trên iPhone.**
3. **P2: logo/splash/pill/border/hitbox, mic/assistant real → nghiệm thu đầy đủ hình, thao tác, audio.**
4. **Mỗi commit** build/safety tests + 43 file/1.385 method comparison của đúng DEB mới; **chỉ một Sileo release hoàn chỉnh** khi các hạng mục bắt buộc vượt kiểm tra thiết bị iPhone X CarPlay, kể cả video YouTube/VLC, normal app, Dock hide/restore, 8 layout, 4 app, Home/reconnect, HUD/voice/settings.

**Lưu ý độ chắc chắn:** 25 nhóm được đánh giá theo mã nguồn/DEB; CI build pass không chứng minh CarPlay runtime. Chưa có stack SpringBoard `.ips` bản 0.0.13; chưa giải hoàn toàn 2.509 Native12 function starts và 1.087 optimized selector call stubs. Vì vậy phần không chứng minh tương đương vẫn là **KHÔNG ĐẠT**. Báo cáo máy chi tiết kèm từng ID và tiêu chí tại `sideplay/audit/native12-vs-new-20261021/GAP_CLASSIFICATION_NATIVE12_VS_0.0.13.json`.
