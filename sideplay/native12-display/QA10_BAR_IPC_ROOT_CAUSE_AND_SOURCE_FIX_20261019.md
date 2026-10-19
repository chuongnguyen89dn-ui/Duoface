# QA10 — Thanh bar CarPlay chưa xuất hiện: nguyên nhân trong mã và bản sửa source-only

**Nguồn thông tin:** Ảnh thiết bị mới trong chat cho thấy picker **“Chọn app cho ô 1”** của SidePlay vẫn phủ toàn màn hình, thanh chia cũ/viền đen logo còn chồng; user nhắc **thanh bar CarPlay vẫn không hiện**. Không có log CarPlay process mới; không tuyên bố thanh Apple/CarPlay dock đã phục hồi.

## Phân loại bằng chứng

**Đã xác minh bằng mã:** QA9 `sideplay/sileo-qa/DFSPChromeBridge.xm` dùng `NSClassFromString(@"NSDistributedNotificationCenter")`, trả về `nil` và bỏ lệnh mà không có kênh dự phòng; trên iOS đây không phải API IPC được bảo đảm sẵn có. Vì vậy QA9 không thể được xem là đã giao lệnh bar thành công. QA9 `DuoFaceSidePlayDisplayQA.plist` chỉ có `Bundles=(...)`, thiếu bộ lọc `Executables` theo tiến trình thực; không xác minh được receiver được nạp CarPlayApp/CarPlay/Dashboard. `Tweak.xm` QA9 dùng `windowLevel=UIWindowLevelStatusBar-1` ở Normal, có thể che bar dù `statusbarWindow.hidden=NO`; QA10 đã trả lại `DFSPOriginalLevel`. `DFSPSystemUsableRect` vẫn dùng fallback trái 64pt khi safeArea thiếu; **đây không phải xác nhận dock hiện**, SidePlay `carDockMode/carDockArea` vẫn chỉ log.

**Đã xác minh với tài liệu:** Cydia Substrate <https://www.cydiasubstrate.com/inject/darwin/> yêu cầu `Filter.Mode = Any` khi dùng nhiều loại filter (`Bundles`, `Executables`), nếu không có thể áp dụng phép AND. Apple <https://developer.apple.com/documentation/corefoundation/cfnotificationcentergetdarwinnotifycenter()> mô tả Darwin Notification dùng system-wide, phù hợp gửi tín hiệu liên tiến trình trên iOS; **không truyền userInfo**, nên command show/hide/reset/ACK được phân biệt bằng tên thông báo riêng, không cố nhét NSDictionary.

**Chưa xác minh trên iPhone/CarPlay:** tiến trình nào thật sự sở hữu thanh Apple dock/sidebar trong cấu hình SidePlay; subclass `DBStatusBarWindow`/`CARStatusBarWindow` có tồn tại trong hệ iOS16.7.x của user; window có được nạp, trạng thái z-order, viewport/hierarchy, còn app nào đang hook cùng cửa sổ; nguyên nhân cuối cùng của **dock vẫn không hiện** có thể khác với statusBarWindow. Không diễn giải ACK “SHOWN_WINDOW” là Apple dock đang hiển thị.

## Sửa mã đã commit, chưa build

Branch `feature/duoface-qa10-picker-divider-source-only`, giữ QA9 DEB trên Sileo nguyên trạng.
1. `sideplay/sileo-qa/DFSPChromeBridge.xm`: **loại bỏ gọi `NSDistributedNotificationCenter` trong đường thực thi**. Thay bằng `CFNotificationCenterGetDarwinNotifyCenter`, 3 command riêng `show/hide/reset`, ACK `shown/hidden/missing/reset` qua Darwin (name-only). Tự động retry tối đa 4 lần nếu chưa có ACK để xử lý CarPlay process khởi động muộn; gửi timeout. Receiver chỉ hook hai subclass statusWindow sau khi thấy class, snapshot/restore `hidden`; không global UIWindow hook, không tác động vendor dylib. SpringBoard lưu ACK/timeout vào `/var/mobile/Library/Logs/DuoFaceSidePlayDisplayQA.log` với prefix `QA10_CHROME`.
2. `sideplay/sileo-qa/DuoFaceSidePlayDisplayQA.plist`: thêm `Filter.Mode = Any`, `Executables=(SpringBoard,CarPlayApp,CarPlay,Dashboard)` song song các bundle identifier, đúng cơ chế Cydia Substrate. Không inject bừa vào các app khác.
3. `sideplay/native12-display/validation/check_qa9_chrome_divider.py`: đổi gate IPC của QA9 từ distributed sang Darwin/ACK/retry/filter, giữ gate hình học và thay đổi cửa sổ nguyên trạng. QA10 bản trước sửa `Tweak.xm` trả về `DFSPOriginalLevel` thay vì nâng cửa sổ đè bar; picker SidePlay tạm ẩn shell; thanh chia/viền logo QA thừa đã loại.
4. Kiểm thử trong lượt này: **15/15 source assertions PASS** (kiểm dữ liệu trực tiếp từ GitHub sau cập nhật): hiện diện thông báo Darwin, ACK/timeout/retry, whitelist window, rollback, filter Cydia Substrate Mode Any, gọi Normal/Zoom, không nâng z-level, không tạo vạch chia QA thứ hai. **Chưa compile Theos, chưa chạy Python validation script tại iOS, chưa chạy test thiết bị.** Source assertions không xác nhận transport/runtime.

## Tiêu chí xác minh tiếp theo sau khi user cho phép build

- Build candidate từ đúng branch QA10 bằng workflow iOS16 arm64, kiểm `plutil`/dpkg, **không** ghi đè stable Native12/HUD8; chỉ phát hành nếu pipeline và package kiểm qua.
- CarPlay khi xe đỗ: xác minh phiên bản, nhận log `QA10_CHROME Darwin request...` và một trong `ACK=SHOWN_WINDOW`, `ACK=WINDOW_NOT_FOUND_OR_MISMATCH`, `ACK TIMEOUT`. Nếu `ACK TIMEOUT` → kiểm process injection/IPC. Nếu `ACK=WINDOW_NOT_FOUND_OR_MISMATCH` → kiểm chính lớp cửa sổ / active UIScene. Nếu `ACK=SHOWN_WINDOW` **nhưng bar/dock vẫn không nhìn thấy**, cần trace riêng dock owner/scene/occlusion thay vì tiếp tục gọi setHidden hoặc đổi 64pt.
- Đồng thời thử khôi phục theo Normal/Zoom/reconnect, hai pane sống, picker không chồng logo, kéo tỷ lệ không trôi. Chưa thực hiện.

**Không được tuyên bố:** “thanh bar đã có”, “build PASS”, “Sileo đã lên QA10”. Ở checkpoint này là **sửa mã nguồn, kiểm tra tĩnh và lưu GitHub**, còn hệ thống thực người dùng vẫn là DEB QA9.
