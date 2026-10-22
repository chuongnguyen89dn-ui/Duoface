# DuoFace Zoom: đối chiếu trực tiếp lịch sử người dùng ↔ mã có sẵn ↔ host độc lập hiện tại

Ngày kiểm tra: 2026-10-22. Repo `chuongnguyen89dn-ui/Duoface`; feature `feature/duoface-jb-embedded-appbridge-20261020`.

## Bằng chứng người dùng, phân biệt thành công có giới hạn

- Đầu mối lịch sử `tiep tuc du an.md`, phần "**2026-10-14 — Yêu cầu mới: chuyển nút fullscreen thành toggle...**" ghi rõ ảnh thật và người dùng xác nhận **phóng to CẢ HAI pane hoạt động trên CarPlay**. Đây là **device-observed ENTER fullscreen** đối với bản đang cài lúc đó, **không biết chính xác bản DEB/commit**. Không được suy ra Zoom Out/ẩn Apple Dock đã kiểm tra thành công.
- Ngay phần "**2026-10-14 — Đính chính sau ảnh fullscreen...**" xác nhận menu ứng dụng biến mất lúc fullscreen, thanh trắng/mục Thu nhỏ bị chặn, nên full toggle/restore **chưa PASS** ở checkpoint đó.
- Cùng `tiep tuc du an.md` phần "**2026-10-14 — User correction: old fullscreen button already removed**" xác nhận người dùng đã chuyển Zoom vào menu. Giữ lựa chọn UI này; không tái tạo nút ngoài, không đụng focus/expand từng pane.
- Bộ lịch sử `ban giao du an duoface moi.md`, `sideplay/tiep tuc du an.md` ghi các nhánh/payload đời sau, không làm thay đổi sự thật về giới hạn xác nhận thiết bị trên.

## Cơ chế CŨ thực sự có source trong repo

| Tầng/owner | Mã gốc sẵn có | Công việc thực |
|---|---|---|
| UI lệnh | `runtime/fullscreen/DFPickerZoomMenu.xm` | Điều khiển menu gọi event `com.duoface.fullscreen.picker.v1` |
| Điều phối Dashboard | `runtime/fullscreen/DFFullscreenCoordinator.mm` | `DFEnterFullscreen` → `DFRequestHostFullscreen(YES)`; ACK geometry rồi `DFDashboardSetChromeHidden(YES)`; Zoom Out `DFRequestHostFullscreen(NO)`, `DFDashboardRestoreChrome` |
| Giao tiếp quá trình | `runtime/fullscreen/DFFullscreenTransport.mm` | requestID, sequence, pending 3s, lease 6s, state/owner/rollback trên `NSDistributedNotificationCenter` |
| Geometry SpringBoard (native12 cũ) | `runtime/fullscreen/DFHostGeometry.xm` | `CBBridgeManager.sharedInstanceIfExists` + `CBWindow.carPlayUsableBounds`, `CBBridgedSplitApp.layoutSplitViews`; snapshot app/window/manager; `DFHostSetExpanded` và `DFHostRestore` |
| Chrome CarPlay | `runtime/fullscreen/DFDashboardChrome.xm` | Chỉ thao tác `DBStatusBarWindow` hoặc `CARStatusBarWindow`, lưu/khôi phục `hidden`. **Không mặc nhiên chứng minh Apple AppDock biến mất**. |
| Đóng gói cũ | `Makefile.fullscreen` | Biên dịch đủ `DFRuntimeEntry`, `DFHostGeometry`, `DFFullscreenTransport`, `DFDashboardChrome`, `DFPickerZoomMenu`, `DFFullscreenCoordinator` |
| Cách native độc lập V1BC khác | `sideplay/mytweak-native-bridgeqa/DFCPNativeBridgeQA.m` | Có `toggleWholeHostFullscreen`/ `MTCPBridgeWriteHostFullscreen` và receiver native applyHostFullscreen; README cảnh báo thử nghiệm chưa có device PASS |

Nền tảng cũ sử dụng `CBBridgeManager`/`CBWindow` của cấu trúc **Native12/v12** trên SpringBoard. Không cấy nguyên `DFHostGeometry.xm` vào app V1BC nếu class/owner khác: sẽ không có owner, gặp fail-closed; và không đồng nhất system Apple Dock với status bar.

## Đường lệnh phiên bản đang build .36: điểm đứt CỤ THỂ

1. `sideplay/duoface-native-scene-host/DFNative12Chrome.m`, `menuAction:` **tag 1**: hiện chỉ `[self emit:@"Zoom" ratio:nil]`, log `native12-global-zoom-owner-ack-pending`; **không gọi** geometry hay hidden-state.
2. `sideplay/duoface-native-scene-host/DFTouchOwnerProbe.m`, `DFSendCommand`: chụp **post-action** `stateSnapshot`, viết plist/notify; source ghi rõ không execute Zoom ở receiver.
3. `sideplay/duoface-native-scene-host/DFNativeHostAppDelegate.m`, `consumeTouchCommand`: whitelist `Zoom`, trả `Accepted:@YES` sau validation state nhưng **không thực hiện** `DFHostSetExpanded`, `DFDashboardSetChromeHidden`, Dock/usableBounds hay restore. ACK này không là Zoom runtime thành công.
4. `sideplay/duoface-native-scene-host/build.sh` chỉ biên dịch `DFTouchOwnerProbe.m`, `DFNative12Chrome.m`/scene host; không biên dịch sáu file ở `runtime/fullscreen/`. `PACKAGING_PROVENANCE.json` bản .36 chỉ 28 payload files và không có `DuoFaceFullscreenBridge.dylib`. Do đó pipeline cũ **KHÔNG được nối trong bản độc lập**, không phải vì tính năng chưa từng được tìm ra.

## Bước triển khai KHÔNG ĐOÁN

- Giữ nguyên menu App/Zoom/Style/Close, chín presets, focus per-pane, split divider và DEB đã build. Không lấy ACK hiện tại làm success.
- Dựa vào **coordinator + rollback + chrome snapshot** vốn có và `DFCPNativeBridgeQA` first-party; xác định owner thật theo independent CarPlay session/touchowner (SpringBoard source content + CarPlay-issued CPWindow), không giả lập `CBBridgeManager` cũ.
- Thêm tín hiệu **request/ACK của hành động Zoom riêng** có trạng thái `expanded`, định danh session, timeout và thực kiểm chứng geometry/actual bar owner. Khi thiếu actor thì fail-closed, không trả Accepted:YES. Bảo đảm Zoom Out luôn có đường bấm khi host đã full, có rollback lúc Home/disconnect/close; không đụng/tái tạo tính năng per-pane zoom.
- Chỉ sửa runtime sau khi so source hiện có `DFCPNativeBridgeQA.m`, `MTCPBridgeContract.m` và bên CarPlay owner; kiểm ABI và process thực. Kiểm thử độc lập với log build và trên iPhone/CarPlay; CI xanh ≠ fullscreen video/Dock trên xe.

Trạng thái: **đã tìm thấy lịch sử thành công ENTER trên máy, nguồn code đầy đủ cũ và lỗ hổng nối hàm chính xác ở source mới**. Đây là audit và checkpoint, **chưa sửa runtime hiện hành/chưa build Zoom mới/chưa Sileo**.
