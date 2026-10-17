# Speed6 17/10/2026 — phân tích log iPhone CarPlay thật: gate activated / host sai

**Nguồn người dùng trực tiếp upload:** `DuoFaceSpeed6-CarPlayApp.jsonl`, đúng 23 dòng UTF-8 JSONL, 3.677 bytes (ảnh trước đó chụp thực tế DuoFace split không có bong bóng). Không tự đẩy log gốc chứa số PID lên GitHub nếu không cần; lưu chuỗi trạng thái khôi phục được ở đây.

## Quan sát thực tế xác nhận qua file

- **23/23 records valid JSON**, `pid=53824`, `process=CarPlay`, tất cả `mounted:false`, `owner:nil`, `host:nil`. `time` UNIX float trong phạm vi `1792202685.8790231` đến `1792202907.382849` (~221.5s).
- Event start: `LOADED: Speed6 CarPlayApp Native12 split-host module` tại 1792202685.8790231; `HOOKED: CBWindow + CBBridgeManagerDashboard activation only` tại 1792202685.8862. **THỰC TẾ module đã nạp, ObjC method hooks đã được cài vào CarPlay**; giả thuyết thiếu GOFAHUD hay dylib/plist mismatch không giải thích trạng thái này.
- **12 lần** `WAIT: CBBridgeManagerDashboard.activated=NO`, từ 1792202685.886642 tới 1792202907.382849. `UNMOUNTED: Dashboard bridgeDidDeactivate` xuất hiện **8 lần** xen kẽ. Đây là chứng cứ trực tiếp dashboard activation singleton đang FALSE phần lớn thời gian trên tiến trình đã hook.
- **4 lần** `WAIT: no visible activeCarPlayWindow/content/controller host`, tại 1792202713.0933661, 1792202734.7448931, 1792202747.0673409, 1792202838.6217241. Code chỉ tới bước này khi đã qua `S6DashboardActive` (tức có thời điểm `activated=YES`); nhưng **không tìm ra UIView/CBWindow hợp lệ**.
- **0 lần** `MOUNTED`, **0 lần** `WAIT: turn OFF GOFA HUD...`, **0 lần** `WAIT: GOFA foreground`, **0 lần** `WAIT: Native12 dashboard/CBWindow classes unavailable`.
- Vì event `WAIT` được debounce theo **stage string** và cứ 0.5 giây reconcile, các số lần không đại diện số tick thật. Đặc biệt trạng thái activated `YES` chỉ suy ra được lúc log tới bước `no visible ...host`; không khẳng định đúng lúc người dùng ở split.
- **Kết luận được xác minh:** Speed6 có loader + hooks, nhưng bộ dò split state/window hoạt động sai/mismatch với thực tế CarPlay device, hoàn toàn chưa gắn HUD. **Chưa tách được nguyên nhân cụ thể của host mismatch** do log gộp 9 điều kiện thành một câu và không lưu class root/current UIWindow.

## Giải thích kỹ thuật từ source pin

`feature:runtime/speedbubble/DFSpeedNativeSplitHost.mm` blob `7f6e3c44fa1d735622a385bd8f1ff9d0a3b80f01`.
1. `S6Reconcile`: class gate → GOFAHUD duplicate gate → GOFA foreground → `S6DashboardActive()` → `S6CurrentOwner()` + `S6VerifiedHost()` → mount. Device **đã vượt qua** 3 gate đầu tối thiểu nhiều lần, không phải GOFAHUD actively blocking in this log.
2. `S6DashboardActive` dựa `[CBBridgeManagerDashboard sharedInstance] activated` trong `CarPlay` process. Log cho thấy FALSE nhiều lần ngay cả khi DuoFace split UI được chụp, nhưng không có timestamp ảnh đồng bộ đến giây nên **không khẳng định luôn FALSE trong split**.
3. `S6CurrentOwner` buộc class return của `+[CBWindow activeCarPlayWindow]` là `CBWindow`, trong khi ABI `@16@0:8` chỉ là generic ObjC object. Nếu native method thực tế trả `UIWindow` thì check thất bại; chỉ fallback khi `s6EventOwner` nhận show/resize. Đây **là nghi vấn mạnh**, chưa kết luận cho đến khi dump `NSStringFromClass([window class])`.
4. `S6VerifiedHost` có các chặn độc lập owner nil/isVisible, root hidden/scene, content.window != root, controller.window != root, descendant relationship, bounds, nhưng chỉ ghi một mã WAIT. Cần mỗi gate kèm tên lớp, role, screen, alpha, bounds, manager.active và owner source (class-return/event), process. Chỉ log metadata, không ghi URL/người dùng/vị trí.
5. Không thay đổi về dữ liệu tốc độ hoặc GOFA source; HUD placeholder `—/—` vẫn phải hiện khi mount thành công, độc lập GOFAHUD.

## Bước sửa chính xác, tránh Speed2/Home bleed

**Tiếp theo** viết patch chẩn đoán/tách gate dựa trên event trong **CarPlay process**: ghi một bản snapshot tối thiểu cho `activeCarPlayWindow` actual returned class và `CBWindow` event owner + root/controller/content view, `CBBridgeManagerDashboard.activated`, *có đúng native split visible không*, một entry mỗi thay đổi trạng thái (không spam) và đường log tồn tại. Tiếp đó quyết định host thật; **không bypass dashboard/host verification hoặc inject/quét mọi CarPlay UIWindow**, vì Speed2 đã hiện nhiều bóng trên Home. Chỉ khi thấy split-window ownership thực tế mới sửa mount và build QA. Không publish Sileo cho bản chỉ suy đoán.

**Ngưỡng chấp nhận:** CarPlay Home=0, DuoFace split=1 placeholder visible, rời=0, Waze stable. Người dùng không cần cài GOFAHUD thêm.

## Trạng thái thực thi

`LOADED` và `HOOKED`: xác minh máy thật. `mounted:false`: xác minh trong toàn bộ 23 sự kiện. Source vẫn bản Speed6 đã publish, không sửa file runtime/build, không thêm DEB và không cập nhật Sileo trong checkpoint đọc log này.
