# BÁO CÁO TẬN RĂNG — ĐỐI CHIẾU CUỐI: DEB GỐC vs DEB HIỆN TẠI (QA185)

Ngày 2026-11-03. Khép vòng bóc tách A–Z cả hai deb theo lệnh của chủ dự án.
Các hồ sơ thành phần (spec-knowledge): HO_SO_TAN_RANG_HINH_HOC / PORTAL /
VONG_DOI / BANG_HOOK_486 / PHU_BINARIES_PHU (bản gốc) và HO_SO_DEB_HIEN_TAI
(bản ta, bóc từ binary đã đóng gói).

## Bảng đối chiếu theo hàm/chuỗi

| Chuỗi | Gốc (hàm/cơ chế đã đọc) | Ta (hàm/cơ chế đã kiểm chứng từ binary) | Khoảng cách |
|---|---|---|---|
| Hình học | +[CBWindow carPlayScreenBounds/carPlayUsableBounds]: cache 3 nguồn + file override + sàn 100pt/kẹp 64pt; renderSizeForBundleID: theo usable × slot, split ×2 trên slot, ngưỡng 10pt | DFHostedLogicalSizeForBundle (header): QA185 = pane ×1 cho mọi trường hợp; không cache, không insets riêng, không override | Thiếu: usable-tách-insets có sàn, supersample split, cache+reset theo sự kiện |
| Ghi settings scene | updateSceneSettingsFrame: đủ 7 cờ qua setter/ivar + hook interceptUpdate trên SBSuspendedUnderLockManager | DFSceneHost commitSceneGeometry: frame-only (chủ đích, bài học .77/QA127); binary xác nhận không có setDeactivationReasons | Thiếu tầng giữ scene (điểm đặt đúng là lúc kích hoạt, không phải giao dịch frame) |
| Đọc trạng thái scene | Hook cả getter: isOccluded/deactivationReasons/isUnderLock/_isSuspended/_isDeactivated | Không có | Thiếu hẳn |
| Bàn phím | ~110 hook tĩnh trong-process (UIKeyboardImpl 40, Traits 22, LayoutStar 18) + 2 function hook hwKB trả NO | Relay cài hook qua dlsym: fit cửa sổ (QA179) + suite QA183 (mặc định tắt từ QA184) + refSize getter hook | Cùng bệnh, khác cấp độ: gốc sửa tại nơi sinh phím, ta vá tại cửa sổ |
| Chạm trong app | host trực tiếp + portal HID (IOHIDEventCreateDigitizerEvent) | host trực tiếp; recall qua sendEvent hook đọc-only (QA177 H1 đạt) | Chạm đầy đủ trong app host chưa từng đạt kiểm chứng |
| Portal | CBBridgedPortalApp: app ở màn phone + __UICreateScreenUIImage + touch-clone HID | Không có (đã có thiết kế Bước 0 riêng) | Thiếu hẳn một chế độ |
| Vòng đời | chống flap, lưu bundle khôi phục ra file bền, hủy khôi phục chờ khi ngắt, sleep assertion, reset cache theo sự kiện | disconnect-close coordinator (grace 10s, đóng app theo PID), stop/ack theo phiên | Thiếu: flap guard, khôi phục bền, sleep assertion |
| Settings | 1 file com.duoface.plist ~40 khóa + handleSettingsChanged (đọc lại file) | Nhiều plist theo vòng/tính năng (qa176 là chính) + file command/ack riêng lẻ | Gốc hợp nhất; ta phân mảnh theo lịch sử vòng |
| IPC | DistributedNotification + file state 0666 + tự sửa filter plist lúc chạy | DF156 mailbox Darwin một ô (mất record đã biết) + file command/ack | Mailbox một ô là điểm yếu đã trả giá QA180–183 |
| Fullscreen/zoom | FullscreenBridge: kênh lệnh có lease + sequence + deadline, hook usable-bounds, snapshot khôi phục | Dock-zoom coordinator: command/ack file, không lease/snapshot | Thiếu lease + khôi phục nguyên trạng |
| Dock/icon | ~150 hook (SBIcon*, CARIcon*, grid layout, dock VC, status bar) | Tự vẽ Chrome + picker riêng (DFAppPickerVC 109 method) | Hai triết lý: gốc bám hạ tầng Apple, ta tự dựng |
| Media | ~30 hook AVPlayer/PiP/route/volume | Không có lớp tương đương (chỉ relay orientation cho YouTube) | Thiếu hẳn |
| Trợ lý | CBAssistantManager: nghe 2 đường + định tuyến lệnh (app/nhạc/nav) + HUD riêng + TCC-grant | DFVoiceAssistant trong app (26 method), nghe–đáp | Thiếu định tuyến lệnh + HUD trợ lý |
| GOFA/HUD tốc độ | Không có (0 selector speed trong bản 1.0.3-12 này) | Toàn bộ stack GOFA + HUD lease 3 presenter | Ta có, gốc không — phần này là của dòng CarPlayPro |
| Tối ưu hệ thống | cboptimize setuid: tắt 12 daemon (chỉ ghi nhận) | Không có | Ngoài phạm vi |
| Giấy phép | CBLicenseSyncManager 2 bản + modal + watchdog (chỉ ghi nhận) | Không có | Ngoài phạm vi |

## Độ bao phủ cuối — nói thẳng
- Gốc: đã đọc thân hàm mọi chuỗi chịu lực (hình học, settings 2 tầng,
  portal, vòng đời, trợ lý cấu trúc, transport fullscreen) + trích trọn
  486 + 10 đăng ký hook + bản đồ app 27 class. Chưa đọc thân: đuôi UI
  thuần trang trí của Dashboard (pill/overlay/dock view bodies), thân
  từng lệnh thoại của trợ lý, ghép cặp selector↔class của VisualHook
  (đăng ký dạng bảng — đã rõ cơ chế/class/nhóm selector). Internals giấy
  phép/optimizer/thương mại: cố ý không đọc.
- Ta: đã disassembly cả 10 dylib + app; trích cơ chế hook từ binary
  (import tĩnh/dlsym/setImplementation), đối chiếu các hợp đồng chịu lực
  với source từ byte thô (DestSize185, frame-only, selector lớp phím).
  Chưa làm: liệt kê từng điểm cài hook qua dlsym theo (class, selector)
  từ binary — với phía ta, danh sách đó lấy đúng nhất từ source (binary
  xác nhận cơ chế + tên, không có bảng tĩnh để trích như gốc).

## Kết luận một dòng
Hai sản phẩm giải cùng bài toán bằng hai kiến trúc khác hẳn nhau: gốc là
một dylib nguyên khối bám sâu vào hạ tầng hệ thống (486 hook, settings
hợp nhất, portal dự phòng, vòng đời có kỷ luật file bền); ta là một bộ
dylib chuyên biệt, hook thưa và động, mạnh ở phần gốc không có (GOFA/HUD)
và yếu đúng ở các tầng gốc dày nhất (phím, giữ scene, media, dock).
