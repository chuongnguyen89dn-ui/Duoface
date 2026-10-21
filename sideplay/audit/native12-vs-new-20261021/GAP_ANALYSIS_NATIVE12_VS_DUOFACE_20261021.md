# Native12 gốc vs DuoFace mới — KẾT LUẬN TỪNG PHẦN CHƯA TƯƠNG ĐỒNG (NO-GO)

**Ngày kiểm:** 2026-10-21 ICT. **CHỈ 2 DEB, tuyệt đối không đưa DuoNavi vào phép so sánh.**

- Gốc: `dist/payload-migration/native12-speed8compact/com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb`, commit gốc `1286a3ef868cf7e29804bcddf7e20b2eae707ce1`, SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`.
- Mới: `sideplay/jb-embedded-appbridge/evidence/runs/39592301388/com.duoface.jb.embedded_0.0.12~pinnednative13_iphoneos-arm64.deb`, SHA256 `6476498212ede843640a7be305a275981cf639ac963c7d7760631fd7fd4718a7`, bên trong Native Host `0.1.13~native12bundle3` SHA256 `46bf9136178278d1762dd5fe46c3a9e4ddf8d49a02424391c7d7fdd73b2b330f`.
- Bằng chứng quét 2026-10-21: [Actions 39595001786](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39595001786) **SUCCESS**. `SUMMARY.json`, `FILE_INVENTORY.json`, `ALL_NATIVE12_1385_METHODS.json`, `CLASSES_AND_NEW_MACHO.json`, `FEATURE_GATES.json` và `REPORT.md` trong THƯ MỤC NÀY. Script `compare_native12_new_full.py` SHA-pins hai DEB và method-index gốc (Git blob `efa45df59bc3c16887cc979bf3aedc0c93c92111`).

## I. Kiểm kê 100% file/ObjC method, không đánh tráo khái niệm

| Chỉ tiêu | Native12 | DuoFace mới |
|---|---|---|
| File payload thực trong DEB | **43** | **34** |
| Mach-O compiled thật trong DEB | **8** | **6** |
| Objective-C class của Native12 được lập chỉ mục | **66** | Cần đọc lớp mới từ từng binary; không có equivalence 1-1 theo class |
| ObjC methods trong Native12 index | **1.385** | **297 mục** tìm thấy selector string chung; **1.088 mục** không thấy. Đây là chữ selector, **không phải** 297 method có đúng implementation |
| Trường hợp file cùng basename và SHA256 byte giống nhau | **13 trường hợp** | Chỉ **6 loại ảnh** (logo ngang, logo dọc, picker logo, fullscreen, picker, swap) được lưu ở nhiều vị trí |
| Package app trên iPhone | `DuoFaceUI.app` với root app/settings | **Hai app**: `DuoFaceNativeHost.app` và `DuoFaceQA.app` ⇒ chưa giống sản phẩm độc lập một app |
| Injection/loaders | `DuoFaceDashboard`, `FullscreenBridge`, `LogoGripOnly`, `SpeedHUD`, `SpeedOwner`, `VisualHook` | `DFV1APreflight`, `DFNativeDashboardBridgeQA`, `DFFirstPartyAdmission`, `DFTouchOwnerProbe` ⇒ khác kiến trúc/process loading |

**Gốc có 2.509 LC_FUNCTION_STARTS**: cao hơn 1.385 method ObjC do còn C, blocks, hook và helper. Báo cáo cũ đếm 1.087 lời gọi optimized objc stub chưa suy ra selector đủ; vì vậy **không** phát biểu đã hiểu tương ứng byte-to-byte tất cả mã máy. Với tiêu chí user, những phần không có chứng cứ hàm/scene tương đồng đều **KHÔNG ĐẠT**.

## II. Đối chiếu chính xác chuỗi hàm/chủ sở hữu → module mới → điểm gãy

| Chức năng | Native12, hàm thật và đường gọi | DuoFace mới và khác biệt thực tế | Kết luận |
|---|---|---|---|
| Khởi động | `CBSplitSplashScreenView.startLoadingAnimation`, `dismissAnimated:completion:`, `onWillDismiss/onDismissed`; hai binary app/Dashboard cùng có lớp splash | `DFNative12Chrome.start` có logo ngang và `CABasicAnimation` 1.25s, kết thúc sau khoảng 1.3s bằng timer; không nối đúng Native12 splash state/scene handoff và callbacks; bản đã chạy trước hiển thị UI sai thứ tự | **KHÔNG ĐẠT** |
| UI picker CarPlay | `CBBridgeManager.showAppPickerForSlot:` → `CBWindow.showAppPickerForSlot:` → `CBMultitaskingOverlayView.showAppPickerForSlot:parentView:`; class overlay **66 method**, có `setupAppPickerCardsInCardW:cardH:contentY:`, `setupRecentAppsCardsInCardW:cardH:contentY:`, `pageControlChanged:` | `DFNative12Chrome.menuAction/openAppPickerForSlot:` → `DFAppPickerVC`, đã có UICollectionView cards/Recent (source) nhưng layout dạng lưới/cuộn, **chưa có pageControl/paging/đúng Native12 visual và timer**; bản mới chưa chụp UI trên xe | **KHÔNG ĐẠT** |
| App iPhone UI / settings | `DuoFaceUI` **522 ObjC methods**, `CBAppManager` 21, `CBSplitViewController` 42, nhiều settings | `DuoFaceNativeHost` là app host/status; thêm `DuoFaceQA` riêng; chưa có duy nhất một màn điều khiển/cài đặt đầy đủ như Native12 | **KHÔNG ĐẠT** |
| App normal host | `CBBridgeManager.requestStateChange:` → `loadNewAppFromCurrentRequest:` → `CBBridgedUIAppView.start` / `startInParentViewController:` | `DFSceneHost.hostViewForBundleID:error:` → `SBDeviceApplicationSceneEntity` / `SBAppViewController` → `sceneHandle`; người dùng xác nhận app thường chạy ở **bản 0.1.10**, nhưng chính 0.0.12 aggregate chưa test | **KHÔNG ĐẠT phiên bản mới** |
| Video/Safe Mode | `CBBridgedUIAppView.refreshSceneLayout/updateSceneFrame/updateSceneSettingsFrame`, `audioOnlyBackgroundMode`, player lifecycle | `DFSceneHost.layoutScene` đã bỏ private FrontBoard `updateSettings:...nil transition`, nhưng không chứng minh gọi đúng media scene/host/orientation; YouTube bản cũ vừa mở bị Safe Mode, chưa có .ips | **KHÔNG ĐẠT nghiêm trọng** |
| Split thật | `CBBridgedSplitApp.layoutSplitViews` IMP `0x1044f8`, `handleDividerPan:isVertical:state:` IMP `0x103ee0`, `setSplitRatio:`, `saveBridgeStateToDisk` | `DFNative12Chrome.layoutControls/dividerPan:` có 2 scene windows, kéo ratio và lưu; người dùng xác nhận bản 0.1.10 có kéo/swap/chạm. Nhưng chưa runtime parity bộ 4 slot và lifecycle version mới | **KHÔNG ĐẠT tổng thể** |
| 8 layout / 4 app | `CBDashboardSettings.splitPreset/gridCols/gridRows/splitApp1..4`, `CBBridgedSplitApp.setSplitPreset/rotateAllSlotsClockwise/moveSlot`, `CBMultitaskingOverlayView.setupPresetCards...:` | `DFNative12Chrome` khởi tạo `hostedScenes` đúng **2 slot** và `menuAction case 2` mới đảo dọc/ngang, ratio reset 0.5; không có 8 preset/4 app real | **KHÔNG ĐẠT, THIẾU THẬT** |
| Swap / logo divider | `CBDividerView.handleMoveButtonLongPress:`, `handlePan:`, `CBBridgedSplitApp.swapSlot:withSlot:/persistSlotOrder`, `CBSlotPillView` | `DFNative12Chrome.swapPressed/dividerPan/logoHold` có logic 2 slot, icon `duoface-swap.png` từ asset thật, nhưng chỉ bo tròn bằng layer; chưa đo đủ kích cỡ và trạng thái gốc | **KHÔNG ĐẠT parity** |
| Phóng 1 ô / Restore | `CBBridgedSplitApp.focusSlot:animated:`, `DFFullscreenTransport` **36 method**, `DFHostSnapshot` **23 method** | `DFNative12Chrome.zoomPressed` chỉ đổi `focus` và mở pane trên `contentRect`; không có state/snapshot/fullscreen transport gốc | **KHÔNG ĐẠT** |
| Zoom ẩn Dock | `CBBridgeManagerDashboard.getDockDimension/updateCarPlayMetrics/appDockVC` liên quan `CBWindow.carPlayUsableBounds` và fullscreen chrome policy | Mới cố tình giới hạn `contentRect` tránh Dock, chưa có lệnh native Dock hide/restore. Người dùng đã nói Zoom phóng ô **chưa ẩn Dock** | **KHÔNG ĐẠT, THIẾU THẬT** |
| Viền đỏ và hiệu ứng | `CBBridgedSplitApp.noteUserActivity/startBlinkingSession/stopBlinkingSession`, `CBDividerView.startBlinking/stopBlinking` | `DFNative12Chrome.noteUserActivity` tự tạo timer **2.1s** và border 1pt `#E3020F` trong 2 frame, focus ẩn border; không cùng Native12 session/timing/hitbox/animation callback | **KHÔNG ĐẠT** |
| Home/khởi động overlay | `CBWindow.createWindows/resizeWindows/destroyWindows` + `CBBridgeManagerDashboard.handleScreenDidDisconnect:` + native scene owner | Mới tạo `UIRootSceneWindow` độc lập trong SpringBoard qua `DFTouchOwnerProbe`, foreground check + heartbeat/watchdog; người dùng thấy thanh/menu hiện **trước** scene và còn **sau** CarPlay Home trong bản trước | **KHÔNG ĐẠT** |
| HUD8 speed | `DFSpeedNativeHUD` **43 method**: `pan:`, `savePosition/restoreSavedPosition`, `loadSettings/saveSettings`, `selectedSource`, `tick:`; `DFOwnerPollingDriver` | Gói 0.0.12 không chứa `DuoFaceSpeedHUD.dylib` hay một implementation đầy đủ `DFSpeedNativeHUD`; chưa có nguồn tốc độ thực | **KHÔNG ĐẠT, THIẾU THẬT** |
| Assistant / mic | `CBAssistantManager` **69 method** (AudioEngine, SpeechRecognizer, recognition request, mic HUD, voice commands) | Chưa nối service micro/speech/AI tương ứng vào app mới; không thay bằng nút giả | **KHÔNG ĐẠT, THIẾU THẬT** |
| Audio / navigation control | `CBBridgedUIAppView.audioOnlyBackgroundMode` và assistant/audio flow trên CarPlay | New `DFSceneHost` chỉ có luồng scene UIKit; chưa chứng minh audio focus/video control | **KHÔNG ĐẠT** |
| Giấy phép gốc | `CBBridgeManager.init` và `requestStateChange:` gọi `checkAndSyncLicenseIfNeeded` trong chính luồng host, PC `0x13b1fc/0x13b21c`; `CBLicenseSyncManager` 60 method bị lặp qua hai Mach-O | **Không được ghép nguyên CBBridgeManager hay license DLL**; `DFSceneHost` độc lập phải thay các phần host operational không giấy phép; chưa tương đương hành vi media/focus/teardown nên vẫn FAIL | **KHÔNG ĐẠT chức năng, khác biệt giấy phép là chủ đích** |
| Dọn scene / lỗi playback | `CBBridgedUIAppView.dismiss/dealloc/invalidated`, `CBBridgeManager.deactivateCurrentApp/terminateAllBridgedApplications`, `CBWindow.destroyWindows` | `DFSceneHost.releaseHostedView/stopAllHosts`, `DFTouchOwnerProbe.stop/watchdog`; source có callback nhưng thiếu device+video crash log xác nhận exitmode không còn | **KHÔNG ĐẠT** |

## III. Phân biệt 3 loại khác nhau, đều NO-GO

1. **Trùng byte hình:** 6 loại hình/logo có hash đúng, tổng 13 cặp do đóng trùng vào app/assets. Đây chỉ là bằng chứng đóng gói asset, **không phải visual/method parity**.
2. **Có chức năng độc lập từng phần:** app normal mở, cảm ứng, chia 2, kéo tỷ lệ, swap, per-slot focus do người dùng đã thử trên 0.1.10; bản **0.0.12 chưa được thử**, còn khác biệt hành vi Native12 rõ ràng, nên NO-GO.
3. **Thiếu hoặc chưa chạy:** 8 layout, 4 slots, full Dock Zoom, HUD8, assistant, iPhone settings, original picker paging, bootstrap/Home gating, YouTube/player Safe Mode ⇒ NO-GO.
4. **Các hàm giấy phép:** exclusion có chủ đích là hợp lệ đối với dự án độc lập; **không được dùng khác biệt cấp phép làm lý do bỏ hành vi CarPlay thực tế**. Phần host/IPC/lifecycle có giấy phép đan xen phải được viết lại, test chức năng, tuyệt đối không copy/hook/bypass vendor license.

## IV. Tiêu chí duy nhất để xác nhận giống Native12

**NO-GO bất kể GitHub Actions PASS** nếu bất kỳ hàng nào trong phần II chưa được chứng minh bằng (1) code path + caller/receiver, type encoding, process/scene ownership, (2) hàm thực hành động, không nút demo, (3) hình ảnh/hitbox đúng, (4) một lượt kiểm nghiệm thật trên iPhone X + CarPlay: app normal và YouTube video không Safe Mode; split, drag, swap, 8 layout, zoom/hide/restore system Dock, Home/reconnect sạch, HUD, AI/settings như bản gốc.

**Phạm vi đã phân tích toàn diện về file và Objective-C:** 43 vs 34 file, mọi Mach-O và 1.385 method Native12. **Chưa** có đối chiếu tương đương từng lệnh ARM64/ABI/C orphan function giữa hai máy (Native12 có 2.509 function starts và các optimized stub), hoặc runtime trace cho từng phương thức. Do đó không khai đã tái tạo 100% và không phát hành Sileo.

**NEXT:** trên chính `0.0.12` aggregate, xử lý P0 media scene (dựa SpringBoard ips), phát triển 4-slot/8-layout và fullscreen native Dock, port độc lập HUD8/settings/voice, nối native picker paging/startup/Home lifecycle, kiểm thống nhất các callback, rồi mới build phiên bản bất biến khác + một lượt kiểm nghiệm. Không sửa/gộp lại DEB hiện tại đang lưu.
