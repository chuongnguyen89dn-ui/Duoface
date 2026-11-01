# So sánh cấu trúc hàm: DuoNavi 1.0.4 gốc ↔ DuoFace nativebridge4 (2026-11-01)

## Bằng chứng và giới hạn

- DuoNavi nguyên bản: log thiết bị `main:sideplay/log/DuoNaviObserver-16990B2B-71E6-4CC1-9AAB-8CBECBD97599.txt`, blob `ae3f8ec858acd225b1df7ea5a991ed3e24d7bd0a`, 4.426 JSON records; 9 cặp Home enter/return. Đọc `REAL_DEVICE_LOG_16990_ANALYSIS_20261101.md`.
- DuoFace hiện hành: `main:sideplay/log/DuoFaceAudit 26.txt`, blob `d376f820d6b4dc88f80b1c269e40257e5c5e4009`, 5 request Facebook/Safari/YouTube và phản hồi người dùng **Home sai đích**. Đọc `../qa156-log26-home-rejected-20261101/FINDINGS.md`.
- Source đối chiếu tại nhánh `feature/duoface-qa146-native-home-exit-20261031`. Sơ đồ gốc là thứ tự callback quan sát từ binary/log, **không phải** mã nguồn DuoNavi hoặc chứng minh quan hệ gọi trực tiếp tại từng cạnh.

## Luồng mở ứng dụng không hỗ trợ CarPlay

**DuoNavi (quan sát thật):**
```text
CarPlay: CBBridgeManagerDashboard.startBridging:withCompletion:
    -> prepareHomeScreenForBridge:
    -> requestActivation:
    -> bridgeDidActivate:
    -> setAppDockActiveBundleID: / setHomeButtonInApp:
[bridged app được quản lý bởi manager, native dashboard vẫn có thể showingApp=false]
```

**DuoFace (đã kiểm tra source + Log26):**
```text
CarPlay: DBDashboardHomeViewController.iconManager:launchIconForIconView:
    -> DF144Launch -> DF144BeginSelectedBridge
    -> DF152PrepareThenContinue -> ghi request.plist -> Darwin notify
SpringBoard: DF144Consume -> DF144Solo.begin
    -> UIRootSceneWindow + DFSceneHost.hostViewForBundleID
    -> sceneReady -> result.plist + Darwin notify
CarPlay: DF147ConsumeResult -> DF147ActivateDock
    -> DBAppDockViewController.setActiveBundleIdentifier:animated:
    -> DBStatusBarHomeButton.setDisplayState:0
```
Bằng chứng source: `DFHomeStandalone144.m:170-235,485-568,725-749`; `DFNativeDockSync147.h:50-70,71-115`. Kết quả source chỉ xác nhận scene/window/manager và Dock; ACK không khẳng định điều hướng hay hiển thị trang chọn ứng dụng.

## Luồng nhấn Home sau khi đang ở ứng dụng bridge

**DuoNavi (9 callback gốc):**
```text
DBRootStatusBarViewController.homeButtonUp: [enter]
    -> CBBridgeManagerDashboard.stopBridging
    -> CBBridgeManagerDashboard.requestDismiss
    -> bridgeDidDeactivate / handleStateDict (có thể lặp/reentrant)
    -> setAppDockActiveBundleID:nil
    -> setHomeButtonInApp:NO -> DBStatusBarHomeButton.setDisplayState:1
DBRootStatusBarViewController.homeButtonUp: [return]
```
`stopBridging` và `requestDismiss` được đo **trước Home return trong cùng đợt gọi** (8/9 lần). Trường hợp Music/Calendar là CarPlay native thật: khi cần, `DBMutableWorkspaceStateChangeRequest.deactivateApplication:` -> `DBWorkspace.requestStateChange:`, không thay bằng giải pháp bridge.

**DuoFace:**
```text
DFOwnerDBHome (hook homeButtonUp:)
    -> DFOwnerHomeReceived
         -> notify_post(standalone144.stop) [chỉ gửi, KHÔNG chờ stop]
         -> ghi revoke session/restore Dock cho owner khác
    -> DFOwnerDBHomeOriginal [Apple Home được gọi ngay]
                   ... CarPlay Home quyết định điều hướng ...
SpringBoard (async): notification stop -> DF144Owner.stop
                   -> hide UIWindow/release DFSceneHost -> result.plist
CarPlay (async): notify stop/result -> DF147Reset/DF147RestoreDock
```
Source `DFCarPlayOwnerObserver.h:127-164`, `DFHomeStandalone144.m:460-470,765-775`, `DFNativeDockSync147.h:50-70,163-169`. Log26 đo từ Home tới stop **29,365–52,047 ms**, khác với DuoNavi có stop/dismiss trước Home return. Đây là **khác biệt thứ tự, ranh giới tiến trình và quyền sở hữu** đã chứng minh; chưa đủ chứng minh một mình gây lỗi trang đích.

## Điểm cấu trúc quan trọng về trang chọn ứng dụng

- **DuoFace có app picker riêng**: `DFNative12Chrome.m:1037-1047` tạo `DFAppPickerVC` và `appPickerWindow`; `:1718-1764` chỉ hiển thị picker trong chrome `openAppPickerForSlot:`.
- **Đường Home độc lập khác hoàn toàn**: `DFHomeStandalone144.m:485-568` tạo cửa sổ `DF144Solo` trong SpringBoard rồi gọi `DFSceneHost`; **không gọi chrome hoặc app picker** (source ghi rõ tại dòng 558-560).
- `DFHomeSceneBridge143.m:20-31` là cầu đi **từ picker có sẵn tới mở một bundle**, không phải luồng **từ Home bridge quay lại picker**. `DFNativeHomeExitPolicy.h` chỉ quyết định Dock=nil, displayState=1; không điều khiển đích điều hướng.
- Vì vậy, trong source hiện hành **chưa tìm thấy cạnh Home-exit -> hiện/khôi phục app-picker đã sở hữu**. Đây là thiếu hụt cấu trúc có thể chỉ ra từ code. Tuy nhiên bản log DuoNavi chưa có `RESULT_APP_CHOOSER` và chưa chứng minh màn đích gốc của vendor là màn chọn app; không được khẳng định Apple Home tự có khả năng quay vào picker.

## Kết luận / bước kỹ thuật

1. **Giống**: hook nút Home thật, native Dock và trạng thái Home button, host app ngoài, chuyển scene, luồng native workspace quan sát được.
2. **Khác cốt lõi**: DuoNavi quản lý bridge start/stop/dismiss qua một manager theo callback Home; DuoFace ghép owner CarPlay/SpringBoard bằng plist + Darwin notify, xử lý stop trễ và tách picker khỏi standalone owner.
3. **Chưa có**: cơ chế đã kiểm chứng để chuyển Home của một app standalone về picker, kèm phép đo rõ owner/scene trước-sau Apple callback.
4. **Không làm theo phỏng đoán**: trước khi sửa, log CarPlay Home entry/return + thời điểm cleanup xong + owner chính xác; xác định trang đích qua marker nhìn thật. Sau đó mới viết state machine độc lập chuyển về picker, giữ nguyên Apple Home cho native Music/Calendar. Không lấy mã/licensing của DuoNavi, không fake showingApp, không đổi Dock đơn lẻ thêm lần nữa.

**Trạng thái:** chỉ so sánh mã nguồn và log đã có. Chưa sửa runtime, chưa build DEB, chưa phát hành Sileo, chưa có test thiết bị mới.
