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

## 2026-10-23 — Truy lại thành công trên xe 14/10 trước khi đòi thêm log (đối chiếu source thực)

Đây là kiểm tra trực tiếp lại **root** `tiep tuc du an.md` các mục ngày 14/10 (khoảng dòng 2232–2293), không phải giả thiết rằng Zoom chưa từng làm được. Người dùng xác nhận bằng **hai ảnh trên xe** rằng **ENTER fullscreen đồng thời cả 2 pane đã chạy**, trước khi thay đổi giao diện. Cũng trong hồ sơ ghi picker biến mất khi full và white restore grabber chặn thao tác, nên xác nhận cũ **chưa** chứng minh `Zoom Out`, hide Apple AppDock và bản DEB SHA đang cài. Bản candidate1 xác minh CI 38526499519, nhưng không chứng minh đó là bản đã hiện trong ảnh; candidate2 đã compile/đóng DEB 38531876025 nhưng chưa device PASS.

**Đường mã đã viết hoàn chỉnh trước đây (không cần lặp lại reverse engineering):** `runtime/fullscreen/DFFullscreenCoordinator.mm` gọi `DFRequestHostFullscreen(YES)` và **chờ ACK host trước rồi mới** `DFDashboardSetChromeHidden(YES)`; khi thoát `DFRequestHostFullscreen(NO)` rồi restore chrome, rollback khi lỗi. `runtime/fullscreen/DFFullscreenTransport.mm` dùng `3*NSEC_PER_SEC` cho timeout ACK, `DFLeaseSeconds=6.0`, ID request/sequence và tự khôi phục. `runtime/fullscreen/DFHostGeometry.xm` chụp owner CBBridgeManager/CBWindow/CBBridgedSplitApp, managerFrame/renderSize/window/content/appView/transform, override `CBWindow.carPlayUsableBounds` khi session full, gọi `resizeWindows`, `layoutSplitViews`, có `DFHostRestore`. `runtime/fullscreen/DFDashboardChrome.xm` chỉ quan sát `DBStatusBarWindow`/`CARStatusBarWindow` (KHÔNG mặc nhiên là Apple AppDock). `runtime/fullscreen/DFRuntimeEntry.mm` khởi tạo từ bundle **com.apple.springboard, com.apple.carplay, com.apple.carplayapp, com.apple.dashboard**.

**Đã tìm điểm lệch CỤ THỂ trong v0.0.43 độc lập**: `DFCarPlayDockOwner.plist` chỉ inject `CarPlay/CarPlayApp` và `DFZCarPlayProcess()` từ chối `dashboard`, dù cặp owner Dashboard là đường gốc đã được phân tích. `DFDockZoomCoordinator.m` timeout Dock ACK chỉ **1.5s**, còn `DFCarPlayDockOwner.m` command age/ACK chỉ **2s**, khác timeout host 3s thành công trước đây. Điều này khiến đường được hỗ trợ trong bản cũ bị bỏ sót và thời gian IPC khắt khe hơn; **chưa chứng minh chính hai sai khác gây lỗi trên máy**. Bản hiện tại cũng đảo thứ tự Enter: Dock trước rồi geometry sau, khác old host trước chrome; không tự đảo thứ tự khi chưa có chứng cứ điều khiển đúng cùng owner. Nhìn vào kiến trúc independent hiện tại, không copy/call CBBridgeManager, CBWindow của nhà cung cấp vì thiếu runtime độc lập/license boundary.

**Sửa có căn cứ đã lưu source (chưa phát hành):** commit `49dec312a615afad4fa5b46cf1a41f715853ead7` mở listener cho `com.apple.dashboard` khi **đúng bundle+process** và thay giới hạn command age 2→3s; `9de06220786e249e8ec3c1545ef1feb0a07d3fd7` bổ sung `com.apple.dashboard` + `dashboard/Dashboard` filter vào first-party receiver; `beb30fc17da44efd4783063bf9ebb6078ae9a901` nới cross-process ACK 1.5→3.0s và ACK timestamp age 2→3s; `bcd17ed60e24c6006470e8236487c3c30ea9562e` thêm regression rồi `19e7d15752e1a74624df421602c846a4825d874a` sửa một ASSERT TEST sai (nó cấm chữ trong **comment**, không phải gọi vendor). **Fail-closed không đổi**: chỉ 1 measured Apple AppDock, fresh DuoFace heartbeat, UUID request+session, receiver ACK `DockHidden`, geometry host thực, restore khi thất bại; không gửi lệnh ẩn thanh trạng thái giả hoặc chế tác Dock. GitHub source-only CI `39906276963` SUCCESS trước test, `39906329246` FAILED test-only comment assertion, mới nhất `39906373214` đang chạy tại checkpoint; kiểm kết quả thực sau. Không package, publish hay tuyên bố device-success; Sileo 0.0.43~zoomtrace1 giữ nguyên.

**Quyết định trả lời người dùng:** lần đọc log thiết bị sau chỉ để phân biệt những biến thể runtime còn lại sau khi đã dùng lịch sử; không được biến việc xin log thành điều kiện để bắt đầu sửa hay lặp lại chẩn đoán đã có. **Bước tiếp:** xác minh source CI, đối chiếu test/callgraph runtime và chỉ khi có bản signed mới mới cập nhật Sileo theo yêu cầu đang được áp dụng; hardware `Zoom In→Zoom Out` thật vẫn là acceptance gate cuối.
