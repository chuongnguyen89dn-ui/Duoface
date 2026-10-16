# DuoFace Native12 — phương án tối ưu CPU và nhiệt độ ĐÃ CHỐT (2026-10-16)

**Trạng thái: PHƯƠNG ÁN ĐƯỢC NGƯỜI DÙNG CHỌN, CHƯA TRIỂN KHAI.**

## 1. Quyết định mới nhất

Trong trao đổi ngày 16/10/2026, sau khi phân tích `Optimize CPU And Thermal` của DuoDash và các giải pháp mở, người dùng yêu cầu chốt phương án rồi chỉ thị **"Cập nhật phương án lên dự án đi"**.

**Phương án đã chốt:** tối ưu theo tải và trạng thái nhiệt, **ưu tiên bảo vệ độ mượt và các chức năng Native12**. Không sao chép trực tiếp phương pháp `15 FPS` cố định của DuoDash. Thứ tự thực thi là:

1. **Đo hiệu năng trước khi thay đổi:** xác định nút thắt thực ở render UI DuoFace, hai ứng dụng chạy cùng lúc, encoder CarPlay, kết nối hoặc sạc; không suy diễn từ phần trăm tải CPU trên Dock.
2. **Giảm chi phí riêng của DuoFace:** chỉ cập nhật timer, hiệu ứng, lớp vẽ hoặc overlay khi còn hiển thị và thực sự thay đổi. Tận dụng cơ chế pause/resume theo trạng thái, tránh redraw nền và trùng timer; không đóng/đóng băng các app đang hiển thị.
3. **Điều chỉnh thích nghi theo nhiệt:** quan sát `NSProcessInfo.thermalState` và `NSProcessInfoThermalStateDidChangeNotification`; khi serious/critical, ưu tiên hạ nhịp công việc UI phụ của chính DuoFace, có hysteresis/cooldown tránh thay đổi bật/tắt liên tục; khi nominal/fair và đủ ổn định thì phục hồi. Cài đặt ban đầu phải an toàn; không dùng bảng giá trị Dock 33.5/38/43.5/48°C như nhiệt độ cảm biến thực.
4. **Nhánh thử nghiệm tùy chọn về FPS luồng CarPlay:** chỉ sau khi có dữ liệu đo cho thấy ba bước trên chưa đủ và được giao thực hiện cụ thể, nghiên cứu 30 FPS (mặc định OFF, có rollback) với kiểm tra thực sự được iOS/head unit chấp nhận. **Không tự áp dụng 15 FPS**, không dùng `CADisplayLink` per-app để giả vờ thay FPS encoder; không chỉnh `com.apple.airplay` mà chưa chứng minh sao lưu/khôi phục nguyên trạng an toàn.

**Đây là lựa chọn kiến trúc/định hướng, không phải cam kết đã giảm nhiệt/CPU trên máy thật.** Việc bổ sung giao diện switch hay đóng DEB mới chỉ thực hiện trong lượt người dùng giao triển khai.

## 2. Nền bắt buộc, phạm vi cấm sửa

- Repo thực thi: `chuongnguyen89dn-ui/Duoface`.
- Nhánh chứa dữ liệu/DEB gốc: `feature/duoface-exact-payload-migration`.
- Baseline **duy nhất**: `dist/payload-migration/native12/com.duoface.independent_0.1.0~native12_iphoneos-arm64.deb`.
- Commit chứa gói đúng: `f08b6f4a7be0bc3a38cce1b0c9b52f8179841064`.
- `Package: com.duoface.independent`, `Version: 0.1.0~native12`, `Architecture: iphoneos-arm64`; SHA256 `85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7`.
- **TUYỆT ĐỐI KHÔNG** lấy DEB/binary của Native13–21 làm nền build. Có thể đọc mã các bản này để so sánh nhưng không được kế thừa thay đổi lỗi. Không ghi đè artifact Native12 gốc.
- **Giữ nguyên** split-screen, divider kéo, zoom, menu App/Style/Close, chọn app iPhone, ghi nhớ ứng dụng bên trong DuoFace theo hành vi Native12, logo, thanh Dock, điều khiển cảm ứng, GPS, âm thanh/video, trạng thái ứng dụng và cách ghép CarPlay.
- Chưa chạm vào những việc khác đang tồn: dòng kích hoạt giấy phép ở Native12, hai ô App `Lite`/`Zingalo`, các mục khởi động/tự đóng đã thử ở Native13+ nhưng gây hồi quy.
- Kho Sileo hiện là repo **khác** `chuongnguyen89dn-ui/carplaydsp`, nguồn `https://chuongnguyen89dn-ui.github.io/carplaydsp/`; phát hành trên đó chỉ sau khi có lệnh, build/test và QA; hiện giữ Native12 nguyên bản.

## 3. Các giai đoạn thực thi khi nhận lệnh phát triển sau này

### Giai đoạn A — baseline/đo, chưa patch

- Đọc handoff mới nhất `main:ban giao du an duoface moi.md`, tài liệu này và các báo cáo liên quan; tra ZIP kỹ năng iOS/debug từ `Gpt-training-`.
- Tải đúng gói Native12 theo commit đã ghim và **đối chiếu SHA256 trước khi chỉnh**. Kiểm tra có job tương tự đang chạy trước khi khởi động cái mới.
- Trace các chủ sở hữu UI Native12: `CBDockSystemMonitorView.startMonitoring/stopMonitoring/updateMetrics` (hiện có timer khoảng 12s thu gọn/5s mở rộng), lớp menu/overlay/đồng hồ/logo; tách việc tính dữ liệu và render.
- Thiết kế đo CPU **của DuoFace** vs **tổng máy**, actual FPS từ pipeline hoặc thiết bị nhận, dropped frames, thermal state thực `nominal/fair/serious/critical`, đồ họa/sạc/độ sáng/kết nối; dựng kịch bản chạy hai app (Maps hoặc Waze + YouTube) và split/zoom/drag.
- Nếu không có đường lấy **actual CarPlay FPS**, nói rõ chưa đo được và không suy ra từ giá trị 15/30/60 trong cấu hình.

### Giai đoạn B — tối ưu cục bộ, giữ nguyên core

- Chọn một nhóm việc dư thừa đã được **trace và chứng minh**; thực hiện patch nhỏ trên **binary/payload Native12 gốc**, không tạo hàng loạt hook phủ quá rộng. Bật/tắt được cho thử nghiệm nếu cần, mặc định an toàn.
- Đảm bảo xử lý trạng thái `view hidden`, `connected/disconnected`, pause/resume và invalidation timer đúng vòng đời; không tắt giám sát Dock khi đang hiển thị và người dùng muốn xem.
- Có báo cáo trước/sau: số timer active, số event redraw mỗi giây, CPU của tweak/host, độ phản hồi kéo divider, trạng thái đồng bộ app, log crash và xung đột.
- Nếu không giảm tải thực hoặc làm mất chức năng, rollback candidate về Native12.

### Giai đoạn C — phản ứng theo nhiệt, không can thiệp governor

- Lắng nghe trạng thái nhiệt iOS thật. Để iOS quyết định thermal severity; không dùng số °C fallback Dock làm ngưỡng.
- Chỉ giảm nhịp những thành phần DuoFace **tự quản lý**, giữ app dẫn đường/video đang hoạt động, sự kiện touch, GPS, gọi điện, Siri, nhạc và hình ảnh đang xem.
- Có ngưỡng phục hồi, thời gian chờ (hysteresis), reset khi thay đổi kết nối; nếu không đọc được thermal state thì quay lại Native12 bình thường.
- Không thay hệ thống quản lý xung CPU/GPU, không giả lập nhiệt, không ép toàn bộ màn hình CarPlay xuống 15 FPS.

### Giai đoạn D — nhánh FPS tùy chọn, KHÔNG mặc định

- Chỉ khi người dùng muốn thử và baseline A/B chỉ ra cần giảm encoder workload. DuoDash `perf_tweak_enabled` đặt `maxFPS=15` + `encoderFPSFixed=15` trong `com.apple.airplay`, nhưng đây là **private/undocumented**, không có xác nhận iPhone/xe thực chấp nhận.
- Khảo sát khả năng cấu hình giới hạn **30 FPS** và so với stock theo iOS/xe. Không hứa tương thích. Thiết kế lưu cả key có tồn tại hay không, kiểu và giá trị cũ trước khi thay đổi; khôi phục qua OFF, lỗi, reboot/uninstall, CarPlay disconnect. Chưa giải quyết được restore tuyệt đối thì **không tích hợp**.
- Nếu actual FPS không đổi, audio/video mất sync, app giật/đen, crash hoặc preference phục hồi sai, tắt candidate và quay Native12.

## 4. Phép thử và tiêu chí chấp nhận

**Thiết kế A/B/A, thử khi xe đỗ an toàn** trên cùng iPhone/iOS, cùng màn hình xe và bộ kết nối, hai ứng dụng đang chạy, độ sáng, sạc, nguồn điện và độ ấm môi trường tương đương. Ít nhất vài lượt **20–30 phút** mỗi chế độ để giảm thiên lệch tích nhiệt.

Theo dõi:
- Tổng CPU và CPU của các tiến trình liên quan đến DuoFace (tránh dùng phần trăm CPU tổng máy như bằng chứng CPU tweak giảm), trạng thái nhiệt iOS, pin/dòng sạc, GPU/energy nếu truy xuất được.
- FPS thực nhận và FPS panel, dropped frames, tương tác split/drag/zoom; bảo đảm không giật bất thường khi Waze/Maps/YouTube chuyển động; âm thanh, video, Siri/gọi điện và dẫn đường không bị lỗi.
- Timer/redraw chỉ giảm ở phần phụ, phản ứng nhiệt đúng chiều, phục hồi khi máy nguội, không lưu trạng thái sai khi reconnect hoặc sau uninstall.
- Kiểm thử hồi quy Native12 trước khi đánh dấu PASS: khởi động app iPhone, chọn app, mở lại **app đã chọn trong DuoFace** (không mở app ngoài), icon, split, menu, close, zoom, sự kiện kéo, Dock, CarPlay connect/disconnect.

**Điều kiện tiến tới bản candidate**: đo được ít nhất một cải thiện có bằng chứng, không có hồi quy các tính năng quan trọng. Không gắn nhãn "đã tối ưu" chỉ bằng CI xanh. **CI/build/published/device-tested là bốn trạng thái riêng.** Khi có lỗi, giữ phương án rollback về DEB gốc.

## 5. Nghiên cứu và tài liệu nguồn

- `main:docs/duodash-113-optimize-cpu-thermal-arm64-analysis-20261016.md` — mã ARM64 của DuoDash, cài 15 FPS.
- `main:docs/duodash-fps-thermal-effectiveness-open-source-20261016.md` — đánh giá hiệu quả, hạn chế, đối chiếu dự án mở và lập kế hoạch đo.
- `main:docs/native12-iphone-screenblank-dock-deep-audit-20261016.md` — cơ chế Dock sample CPU/temp, Screen Blank (không đồng nghĩa giảm CPU).
- `feature:audit/payload-migration/NATIVE12_CPU_THERMAL_READONLY.json`, `NATIVE12_SCREENBLANK_DOCK_DEEP_READONLY.json`; GitHub Actions run `38877337186`, `38878439739` — static audit, không phải đo trên thiết bị.
- Dự án tham khảo: `https://github.com/youcci/playport` (FPS negotiation 30/60 và đo phía receiver), `https://github.com/jwinarske/carlinkit-cxx` (video FPS khác display FPS, hardware decode), `https://github.com/TelegramMessenger/Telegram-iOS` (CADisplayLink per-view), tài liệu `https://developer.apple.com/documentation/foundation/processinfo` và `https://developer.apple.com/documentation/quartzcore/cadisplaylink/preferredframeraterange`.
- Không được coi source receiver head unit là mã có thể copy vào CarPlay phone host; không copy license/code nguyên khối khi chưa thẩm tra.

## 6. Mốc lưu và điểm tiếp nối

- **Đã chốt:** phương án đo thực → tối ưu cục bộ → điều chỉnh theo thermalState → chỉ cân nhắc giới hạn 30 FPS riêng, không cố định 15 FPS.
- **Đang thực thi:** ghi phương án và checkpoint này lên đúng GitHub; không có job build/deploy được yêu cầu.
- **Bị chặn:** kết quả A/B thiết bị iPhone/xe, chưa có benchmark nhiệt/CPU/FPS thực.
- **Việc chưa bắt đầu:** triển khai patch, tạo DEB candidate, QA CarPlay thật, phát hành Sileo.
- **Bước tiếp theo khi được giao triển khai:** đọc checkpoint, kiểm Native12 SHA, chọn phép đo có thể làm với thiết bị/harness hiện có, lấy baseline; sau đó đề xuất đúng một patch nhỏ có phép thử hồi quy và rollback cụ thể. Không mặc nhiên thay đổi Sileo.

