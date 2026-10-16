# DuoFace Settings Pro — hợp nhất Cài đặt DuoDash và DuoFace native12

**Ngày:** 16/10/2026 · **Trạng thái:** ĐỀ XUẤT THIẾT KẾ/CONTRACT, CHƯA TÍCH HỢP VÀO DEB.  
**Mục tiêu:** DuoFace giữ nguyên giao diện, app picker, Zoom/Style/Close, cử chỉ CarPlay đang dùng; bổ sung *những tác dụng hữu ích* của phần Cài đặt DuoDash 1.1.3 bằng **thiết kế và mã riêng của DuoFace**, phát triển thông minh hơn với cấu hình an toàn và quan sát được.  
**Không trong phạm vi:** bê giao diện, logo, ảnh, binary, API nội bộ hoặc mã nguồn của DuoDash; sao chép chức năng chia ô/CarPlay của DuoDash; tái khởi động công việc xóa giấy phép đang TẠM HOÃN; tự build DEB hoặc cập nhật Sileo.

## 1. Số liệu và nguồn thực tế

- Nguồn phân tích DuoDash: `audit/duodash-1.1.3/settings_license_static_audit.md`: 18 hàng settings trong PreferenceLoader (8 trong Root.plist); Navigation Bubble, Voice Command và Crash Reporter có nhãn trong dylib; **không có test runtime DuoDash**.
- Nguồn đối chiếu DuoFace: `audit/duodash-1.1.3/doi-chieu-cai-dat-duodash-vs-duoface-native12-20261016.md`, `main:tiep tuc du an.md`, `main:ban giao du an duoface moi.md`, `feature/duoface-exact-payload-migration:audit/payload-migration/ORIGINAL_SETTINGS_OBJC_METHODS.json`.
- Native12 `com.duoface.independent` SHA256 `85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7` đã được người dùng thử tốt nói chung. Không được suy ra tất cả switch Cài đặt đều được QA trên máy.
- Nguồn cài đặt DuoFace tồn tại: `CBGeneralSettingsViewController` trong **DuoFaceUI** (30 ObjC methods, 1 `openSubscriptionScreen` đã vô hiệu hóa) và `CBDashboardSettings` trong **DuoFaceDashboard** (61 methods). Chưa có source đầy đủ của hai host Mach-O để thêm row bằng build lại app trực tiếp.
- Dữ liệu cấu trúc cho triển khai: `audit/duodash-1.1.3/duoface-settings-pro-feature-manifest.json` định nghĩa **30 mục, 8 nhóm, 5 pha**, mặc định an toàn, dependency và tiêu chí nghiệm thu mỗi mục. **Manifest không phải tính năng đã cài trên iPhone.**

## 2. Giao diện Cài đặt đề xuất — nằm trong ứng dụng DuoFace trên iPhone

Chỉ sắp xếp/phát triển màn Cài đặt trong ứng dụng DuoFace; **không thay menu chọn app đang dùng trên CarPlay**.

| Nhóm mới | Giữ từ DuoFace | Học tính năng DuoDash | DuoFace Pro mạnh hơn như thế nào |
|---|---|---|---|
| **Kết nối & tự phục hồi** | Tự mở khi kết nối | Auto Start, Close Apps on Disconnect | Nhớ phiên app trước, chống tự mở trùng, cấu hình theo màn hình/xe, hẹn đóng app 12 giây **có thể hủy khi kết nối lại**, OFF mặc định |
| **Ứng dụng** | App picker, trạng thái Live/X; giữ callback Close App hiện tại | Choose Apps, Close Unloaded Pane Apps | Chỉ đóng nền theo bundle-id đã xác minh và opt-in; bảo vệ bản đồ/nhạc/app đang hoạt động; lịch sử ứng dụng bị dọn |
| **Hiệu năng & pin** | Screen Blank (không phải Deep Sleep) | Optimize CPU & Thermal, Deep Sleep | Đọc trạng thái nhiệt `ProcessInfo.thermalState`, tự giảm *hiệu ứng/timer của DuoFace* khi nóng; tuyệt đối không tự bật airplane/tắt Bluetooth/Wi-Fi |
| **Màn hình & cá nhân hóa** | Ngôn ngữ, ẩn nhãn app, Dock Monitor, splash/logo | Headunit Info, Recommended Video Quality, Go To CarPlay, Splash | Thông số độ phân giải/scale chỉ đọc, gợi ý video minh bạch không ép trình phát, chọn splash do DuoFace sở hữu; không phá asset/logo đang dùng |
| **Bong bóng tốc độ** | Chưa có tính năng tương đương được chứng minh | Navigation Bubble / Provider / cảnh báo | GPS current speed kèm độ chính xác và độ mới; giới hạn tốc độ chỉ hiện khi có provider đáng tin; thử provider, cảnh báo có ngưỡng chống nhấp nháy liên tục |
| **Giọng nói** | Có metadata assistant/voice feedback, chưa chứng minh voice handler | Handler, Steering-Wheel Button, Test Press | Module lệnh opt-in, provider riêng, báo trạng thái/khả năng; **không chiếm nút Siri theo mặc định**, fallback Siri |
| **Ổn định & khôi phục** | Reset defaults, Respring thủ công | Crash Reporter, crash latch, Re-enable Tweaks | Nhật ký vòng đệm tại máy, xuất log chỉ khi tự yêu cầu, redaction ID/toạ độ, safe-mode từng mô-đun, không tạo respring loop |
| **HUD Bluetooth (tùy chọn)** | Không có chức năng HUD được chứng minh | Pair/Status/Firmware | Chỉ hiện khi phần cứng HUD tương thích được người dùng sử dụng và có tài liệu giao thức; không bắt cài tất cả máy |

## 3. Những mục nên tích hợp ngay khi bắt đầu phát triển

**P0 — Chỉ rà soát và bảo toàn (8 mục):** Auto Start; Choose Apps; Screen Blank; Language; Hide Labels; Dock Monitor; Reset Defaults; Respring. Kiểm tra luồng getter/setter, app iPhone, trạng thái trên CarPlay; **không tạo ra các công tắc trùng chức năng gốc**, không chỉnh hành vi Close App, không đụng license.

**P1 — Bổ sung hữu ích và ít rủi ro (7 mục):** Session Restore; App Status; Thermal Adaptive; Runtime Metrics; Headunit Info; Go To CarPlay Settings; Diagnostics. Mọi mục mới phải có nhãn rõ, state sync, reset được, logs và nút xem trạng thái; không được hiển thị `Enabled` giả khi chưa có implementation.

**P2 — Chính sách có tác dụng phụ (7 mục):** Profile theo màn hình/xe; Auto Close on Disconnect; Close Unloaded Apps; Light Sleep; Recommended Video Quality (chỉ tư vấn); Splash Selection; Crash Safe Mode. Các hành vi đóng app / sleep **OFF mặc định**, có allowlist/denylist, điều kiện kết nối lại, bản sao cấu hình để rollback và thông báo tác động.

**P3 — Phụ thuộc nguồn dữ liệu/permission (7 mục):** Speed Provider; Speed Limit; Speed Alert; Provider Test; Voice Handler; Steering-Wheel Button; Voice Test. Bắt buộc kiểm tra quyền và khả năng thực tế trước khi bật; không tạo nguồn tốc độ tối đa giả, không khẳng định hỗ trợ rộng tại Việt Nam khi chưa có dữ liệu đo.

**P4 — Tùy chọn phần cứng (1 mục):** HUD Bluetooth. Không cho vào màn Cài đặt mặc định khi không có phần cứng và giao thức phù hợp.

## 4. Các nguyên tắc bắt buộc (mạnh hơn, nhưng không phá cái đang chạy)

1. **Tách khối điều khiển và khối thực thi:** view trên iPhone chỉ ghi option, runtime backend đăng ký rõ `supported`/`unsupported`/`waitingForPermission`/`active`/`error`. Không tạo màn có switch nhưng không nối hàm.
2. **Bảo toàn toàn bộ cài đặt cũ:** chưa xác minh tên khóa Preferences thực tế nên thiết kế cần adapter đọc current keys từ host Mach-O; không tự thay tên `CFPreferences` keys/callback hoặc ghi đè lựa chọn user khi nâng cấp.
3. **Cấu hình nâng cấp không phá dữ liệu:** versioned schema, backup trạng thái trước thay đổi, rollback cấu hình theo mô-đun, validation với giá trị ngoài phạm vi.
4. **Default an toàn:** auto-close, low-power, speed/voice overlay, gửi log đều OFF hoặc chỉ đọc; profile mặc định duy nhất; không thay radio/OS, không upload log bí mật.
5. **Độ tin cậy thông tin:** GPS có `CLLocation.speed` (m/s), `speedAccuracy`, `timestamp` nhưng KHÔNG cung cấp tốc độ giới hạn hợp pháp. Speed limit cần provider riêng (và kiểm phạm vi VN). Khi thiếu dữ liệu phải hiện `Không có dữ liệu`, không phỏng đoán.
6. **Tối ưu tài nguyên đúng mức:** `ProcessInfo.thermalState` cung cấp nominal/fair/serious/critical, không phải số độ C và không bảo đảm throttle toàn hệ thống. Chỉ giảm effect/timer do DuoFace sở hữu. Không tự ý điều khiển FPS video của app khác.
7. **Không thay ràng buộc đã chốt:** giữ CarPlay UI, split/ratio, logo 0,30s tap/drag, Zoom, Style, Close, Live/X, mức màu nền, âm thanh và app picker hiện tại. Mọi thay đổi phải diff review, compile-only trước; chỉ build DEB khi được yêu cầu rõ.
8. **Không bê dependency DuoDash:** không thêm BLE HUD, Voice Handlers hay các module độc quyền bằng cách copy nhị phân; chỉ viết implementation của DuoFace với giao thức được phép/đã xác minh.

## 5. Trình tự nối mã khi được giao triển khai

**Bước A:** Đọc binary native12 đúng SHA trong GitHub Actions (không sửa) để xác định *keys/notifications/controller render path* của `CBGeneralSettingsViewController` và `CBDashboardSettings`. Với mỗi row, lưu chứng cứ selector, callsite, quyền hiện tại; xác định khả năng gắn module settings mới bằng hook cô lập, không thay host.

**Bước B:** Tạo module cấu hình DuoFace-owned với version, schema, validator, backup/rollback và telemetry read-only. App Settings controller hoặc Preferences pane mới chỉ lựa chọn sau khi xác minh đường xuất hiện trên iPhone; không giả rằng chỉ thả plist vào DEB là hiện/hoạt động.

**Bước C:** Wire P0 và P1 riêng; compile-only/test on CI; thử trên iPhone; QA màn hình xe cho mỗi tính năng thật sự tác động CarPlay. Mục nào chưa xong ghi `not_implemented` thay vì bật switch mẫu.

**Bước D:** Thực thi P2 và P3 theo dependency; quyền vị trí/Bluetooth/giọng nói theo lựa chọn user; test data cũ, reconnection, background music/maps, Safe Mode, lỗi provider và thiếu quyền.

**Bước E:** Khi được người dùng yêu cầu đóng DEB, tạo artifact version thử riêng so với native12, kiểm package/rootless/signature/endianness/selector hash; test device trước khi publish Sileo, giữ native12 và native10 rollback.

## 6. Tiêu chí thành công tổng thể

- Native12 nguồn hiện hành **không bị thay đổi ngoài scope được duyệt**; không mất menu/cử chỉ chức năng tốt.
- Mỗi mục P1/P2/P3 khi đưa vào bản dựng có UI, persist, apply, reset, observed feedback, điều kiện lỗi và test riêng; danh sách các mục có mã nhưng **chưa thử trên máy** phải để nhãn tương ứng.
- Auto-close không đóng nhầm nav/music; reconnect ngắn không gây kết thúc nhầm app; thermal adaptation không phá media/điều hướng.
- Bong bóng tốc độ không tự tạo speed limit nếu nguồn vắng hoặc stale, cảnh báo không giật/nháy liên tục.
- Nhật ký crash không tự gửi đi, không lưu bí mật; không có vòng lặp Respring.
- Mục license cleanup 14 classes/249 methods vẫn **PAUSED** theo lệnh mới nhất, không gộp vào settings khi chưa được yêu cầu.

## Tham chiếu

- Apple Developer: `https://developer.apple.com/documentation/foundation/processinfo/thermalstate-swift.enum`
- Apple Developer: `https://developer.apple.com/documentation/corelocation/cllocation?language=objc`
- `main:audit/duodash-1.1.3/settings_license_static_audit.md`
- `main:audit/duodash-1.1.3/doi-chieu-cai-dat-duodash-vs-duoface-native12-20261016.md`
- `main:audit/duodash-1.1.3/duoface-settings-pro-feature-manifest.json`
- `main:ban giao du an duoface moi.md`
- `main:tiep tuc du an.md`
- `feature/duoface-exact-payload-migration:audit/payload-migration/ORIGINAL_SETTINGS_OBJC_METHODS.json`
