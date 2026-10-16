# DuoDash Optimize CPU And Thermal — hiệu quả thực tế, đối chiếu mã nguồn mở (16/10/2026)

## 0. Phạm vi, mức độ chứng cứ và giới hạn

**Yêu cầu mới:** Đánh giá phương pháp tối ưu CPU/nhiệt của DuoDash thực sự hiệu quả đến đâu, tìm các dự án có cơ chế tương tự/khả thi để có thể nghiên cứu áp dụng cho **DuoFace**, không build hay phát hành. Chỉ được dùng **DuoFace Native12** làm nền cho bất kỳ build tương lai; native13–21 lỗi theo phản hồi thiết bị người dùng.

**Nguồn nhị phân đã kiểm chứng trước đây** (đừng nhầm với phiên bản 1.1.3 gốc người dùng từng cung cấp): `chuongnguyen89dn-ui/DauDat-CarPlay` commit `5f683ad16a2c4f2b37e333e891cfb8f7ba3e0d6b`, `DuoDash_1.1.3_Fullscreen427_iphoneos-arm64.deb` version `1.1.3+fullscreen1`, SHA256 `ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465`. Different from previous 1.1.3 uploaded repack SHA256 `16ffab22b4246dea9978cae92df7ec635d833ec067b4d9f425a231b26edec601`; **do not assert identical**.

- Bộ mã ARM64 thuộc `DuoDash.dylib` đã được audit read-only bằng `feature:migration/full_payload/native_test/audit_duodash_perf_thermal_113.py` và `feature:migration/full_payload/native_test/trace_duodash_carplay_fps_113.py`; báo cáo `feature:audit/duodash-1.1.3/DUODASH_PERF_CPU_THERMAL_RAW_TRACE.json`, `feature:audit/duodash-1.1.3/DUODASH_FPS_ENCODER_SYMBOL_TRACE.json`. Runs [38879870747](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/38879870747) và [38880502956](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/38880502956) SUCCESS **static analysis only**, not an iPhone device test.
- Báo cáo trước: `docs/duodash-113-optimize-cpu-thermal-arm64-analysis-20261016.md` (main). Rootless DuoFace Native12 immutable SHA256 `85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7`.
- Không có bằng chứng livestream FPS thực, công suất mW, tải CPU/GPU %, nhiệt độ cảm biến hoặc so sánh A/B 30 phút trên một chiếc iPhone/xe cụ thể. Không diễn đạt kết quả mã tĩnh thành QA thiết bị.

## 1. DuoDash thực sự điều chỉnh gì? Có hiệu quả không?

**Đã xác thực qua disassembly:** `perf_tweak_enabled` true ghi `maxFPS=15` và `encoderFPSFixed=15` vào domain `com.apple.airplay` qua `CFPreferencesSetValue`, rồi synchronize/readback. False ghi NULL xóa hai giá trị override; backup/restore arbitrary existing values **chưa chứng minh**. Đây là yêu cầu **giới hạn FPS luồng AirPlay/CarPlay**, **không phải** lệnh hạ CPU frequency, không dựa trên cảm biến nhiệt và không giảm render FPS từng app bằng API công khai. iOS có thể bỏ qua private keys trên một phiên bản nhất định; cần quan sát encoder/receiver thực mới kết luận.

**Hiệu quả về mặt cơ chế:** Nếu đường encode thực được giới hạn và nội dung có chuyển động, 60→15 có thể yêu cầu xử lý ít hơn tối đa 75% số khung hình/giây; khối lượng công việc **không giảm tuyến tính** tương đương 75% CPU, nhiệt hay pin vì phần cơ sở luôn hoạt động (GPS, kết nối radio, sạc, điều hướng, giải mã video, hệ điều hành, GPU và encoder tăng tốc phần cứng). Nội dung tĩnh thường đã không tạo ra đủ 60 khung hình mới. Nếu iOS không đọc override thì tác dụng có thể =0; nếu hệ thống khác dùng AirPlay settings thì tác dụng/rủi ro có thể lan tới luồng khác.

**Đánh đổi hiển thị:** 15 FPS = 66,7ms/khung; 30=33,3ms; 60=16,7ms. Hình ảnh CarPlay có thể kém mượt đặc biệt khi Waze, Google Maps cuộn liên tục, bấm nút, chia đôi, video. Không tuyên bố touch delay sẽ tăng đúng 50 ms hoặc giảm hiệu năng định lượng nếu chưa đo. Developer ghi rõ tính năng beta có thể gây vấn đề nghiêm trọng và sau bật/tắt phải ngắt kết nối CarPlay rồi nối lại. **Đánh giá:** phương pháp hợp lý để thử như phương án cứu nóng có chủ ý, quá thô và nhiều rủi ro để mặc định trong DuoFace.

**Nguồn Apple chính thức:** Apple `ProcessInfo.ThermalState.serious` khuyến nghị *giảm target FPS 60→30* khi quá nóng; app có thể quan sát `thermalState` và `thermalStateDidChangeNotification`. `CADisplayLink.preferredFrameRateRange` chỉ áp dụng cho callback liên quan app, hệ thống lựa chọn giá trị cuối, không phải API khống chế toàn bộ CarPlay/AirPlay. Tài liệu: 
- https://developer.apple.com/documentation/foundation/processinfo/thermalstate-swift.enum/serious
- https://developer.apple.com/documentation/foundation/processinfo
- https://developer.apple.com/documentation/quartzcore/cadisplaylink/preferredframeraterange

## 2. Các dự án mã nguồn mở ĐÃ KIỂM CHỨNG thực sự liên quan

### A. PlayPort — CarPlay receiver thực, điều khiển FPS ở bước thỏa thuận (rất đáng tham khảo)
- https://github.com/youcci/playport
- Code `server/src/main/kotlin/com/playport/server/CarPlayServer.kt` tạo `AirPlayDisplayConfig(widthPixels, heightPixels, fps=display.fps)`, tức bên nhận **yêu cầu** FPS trong phiên kết nối; `DisplayState.kt` kiểm hợp lệ 24–60 fps; UI cho lựa chọn **30 FPS hiệu quả / 60 FPS mượt**, đổi rồi CarPlay restart để thương lượng lại.
- Có stats HUD hiển thị fps thực, bitrate, dropped frames, decode queue, latency; tốt cho thiết kế tiêu chí đo **requested ≠ actual**.
- Phù hợp tham khảo thuật toán, đo và tư duy negotiation; **không thể chép thẳng vào DuoFace** (DuoFace chạy trên iPhone, không kiểm soát phần mềm receiver của màn hình xe). PlayPort GPL-3.0, không copy nguyên code vào tweak chưa kiểm license và kiến trúc. Nguồn https://github.com/youcci/playport/blob/main/README.md và file server ở repo.

### B. carlinkit-cxx — pipeline CarPlay receiver + đo thực FPS/CPU/nhiệt/hardware decode
- https://github.com/jwinarske/carlinkit-cxx
- Code `src/main_kms.cpp`: `CARLINKIT_FPS_LOG` đếm riêng `video=` khung decode và `display=` page flips, tránh đánh đồng phone output và màn scanout; cấu hình `CARLINKIT_FPS` có thể yêu cầu 60. Có fallback decoder VAAPI/V4L2/CPU và so sánh thực trên Raspberry Pi; README tuyên bố Pi4 hardware decode ~6–10% CPU, Pi5 CPU/software cao hơn với ảnh/video lớn. **Đây là hiệu quả nhận và giải mã trên head unit, không phải chứng minh giảm nhiệt iPhone khi hạ encoder FPS.**
- Áp dụng chủ yếu **phương pháp đo** độc lập `video FPS` vs `display FPS` + CPU/hardware decode và điều chỉnh resolution trong điều kiện test. Không thể can thiệp backend decoder xe chỉ với DuoFace iPhone.

### C. Telegram-iOS — tối ưu FPS *mỗi animation*, không đè cấu hình hệ thống
- https://github.com/TelegramMessenger/Telegram-iOS/blob/master/submodules/Display/Source/DisplayLinkAnimator.swift
- `SharedDisplayLinkDriver` dùng `CADisplayLink` + `preferredFrameRateRange`, link-level FPS target, `isPaused`, bỏ qua callback frames khi animation không cần tốc độ tối đa.
- Áp dụng **cách quản lý công việc render bổ trợ** của chính DuoFace (menu, logo animation, indicator, overlay) khi không chuyển động; nhưng không tự động đặt FPS luồng CarPlay, không làm video Waze/Youtube chậm lại, và DuoFace Native12 host compiled có thể không sở hữu callback của app bên thứ ba. Tránh copy code không kiểm giấy phép.

### D. FPSIndicator / Unity60FPS — iOS jailbreak nhưng không phải CarPlay
- https://github.com/brendonjkding/FPSIndicator — `Tweak.x` đếm `presentRenderbuffer`/frameTicks trong game; minh họa FPS phải đo trên luồng render thực, có giới hạn với video CarPlay encoder.
- https://github.com/brendonjkding/Unity60FPS — `Tweak.x` hook `UnityEngine.Application::set_targetFrameRate` để ép FPS game; khác hoàn toàn với AirPlay FPS. Tham khảo phương thức injection/kiểm phản ứng FPS **không khuyến nghị chèn hook toàn hệ thống** vào DuoFace.
- https://github.com/lich4/ChargeLimiter — tùy chọn power/thermal simulation can thiệp sâu hệ thống, bản thân tác giả cảnh báo dễ xung đột với tweak và làm máy lag. Không dùng mô phỏng nhiệt / can thiệp thermal governor để tối ưu CarPlay. Đừng nhầm dùng governor là giải pháp an toàn.

**Không tìm thấy một dự án được kiểm chứng trên thiết bị, cùng cấu hình iPhone/iOS/xe, chứng minh `maxFPS=15/encoderFPSFixed=15` qua `com.apple.airplay` giúp DuoDash giảm chính xác bao nhiêu °C hoặc %CPU.** Bằng chứng cộng đồng `reddit.com/r/CarPlay` cho thấy nhiệt phụ thuộc đồng thời phương thức sạc (đặc biệt Qi), GPS/maps, nắng, radio, iOS; chỉ là phản hồi giai thoại, không phải thử nghiệm độc lập.
- https://www.reddit.com/r/CarPlay/comments/1vgmjxf/why_is_my_phone_getting_skin_melting_hot_in_my/
- https://www.reddit.com/r/CarPlay/comments/1lkqgo0/anyone_elses_iphone_overheating_with_wireless/

## 3. Hướng nghiên cứu CHO DUOFACE Native12 — chưa triển khai

**Ưu tiên 1 — giảm chi phí nội bộ trước, tránh thay đổi phạm vi toàn hệ thống**: rà soát refresh không cần thiết khi Dock không hiện (Native12 có `CBDockSystemMonitorView` timer 5s/12s), animation logo/menu khi ẩn, render overlay/layer không thay đổi, tránh timer/recomposition khi ô chia không có thay đổi. Không được dừng bản đồ/GPS/âm thanh hoặc ứng dụng thực.

**Ưu tiên 2 — cân nhắc thử giới hạn 30 FPS khi cần và được user chấp thuận**: Thiết kế công tắc mặc định OFF; dùng `NSProcessInfo.thermalState` `nominal/fair/serious/critical` để quyết định *giảm khối lượng công việc tự quản lý*, không dựa vào chỉ số nhiệt `Dock` có thể giả định. Không áp đặt 15 FPS toàn phiên; chỉ nghiên cứu khi có đo FPS thực ở receiver. Phân biệt: `CADisplayLink` hợp pháp và phạm vi app, không thể dùng như API sửa framerate stream CarPlay. Chưa chứng minh iOS cho phép cấu hình FPS tùy ý ở head unit người dùng.

**Ưu tiên 3 — nếu thực nghiệm cơ chế private AirPlay từ DuoDash**: tuyệt đối không copy dylib, không ghi cấu hình toàn hệ thống theo mặc định; phải backup tồn tại/absence + kiểu/giá trị trước, khôi phục nguyên vẹn ngay cả crash/uninstall/reboot/reconnect, rollback khi FPS không thay đổi hoặc stream đứt, watchdog timeout, không sửa khi đang lái xe. Đánh giá riêng ảnh hưởng AirPlay khác. Apple không hỗ trợ `maxFPS`/`encoderFPSFixed` công khai.

**Thiết kế thử nghiệm trên thiết bị/xe (chỉ khi được yêu cầu)**: So sánh A/B/A hoặc ngẫu nhiên điều kiện tương đương **stock native12, thử 30 nếu kỹ thuật thật có tác dụng, thử 15 khẩn cấp** ở cùng xe, cùng iOS, cùng quãng chạy thử đứng yên/mô phỏng Waze map động + YouTube, cùng độ sáng, sạc, thời tiết, kết nối wired/wireless. Mỗi tình huống 20–30 phút ổn định rồi ghi:
- Target/actual FPS, frame drops/encoding backlog, responsiveness chạm và giật hình ở receiver hoặc camera ghi màn hình (không chỉ log fake `60` Darwin notify).
- CPU overall và riêng DuoFace (lệnh process), GPU/energy nếu có dụng cụ, battery/power/thermalState `serious` và thiết bị ngoài đo nhiệt nếu có; đừng dùng 33.5/38/43.5/48°C fallback Dock của Native12 như nhiệt cảm biến thật.
- Audio chỉ đường/cuộc gọi/video, không bị drop hay mất sync; reconnect nhanh, không đổi cấu hình Apple sau DISABLE; không ảnh hưởng ứng dụng khác.
- Nhiều lần/đảo thứ tự để kiểm nhiệt tích lũy; không tuyên bố % tiết kiệm từ giảm frame count.

**KẾT LUẬN:** Có khả năng giúp giảm tải encoder dưới một số điều kiện, nhưng **chưa thể khẳng định hiệu quả thiết bị**, nhất là khi chạy nội dung ít chuyển động và trên iOS private keys có thể đã thay đổi. Với DuoFace đề xuất cách tiếp cận **đo thực → tối ưu phần riêng → điều chỉnh thích nghi khi nóng → chỉ mới xét private 15fps như fallback có bật tay**, thay vì sao chép DuoDash.

## 4. Trạng thái bàn giao

- Đã hoàn tất: nghiên cứu mã DuoDash có kiểm chứng, tìm/đọc mã các dự án nêu trên và tài liệu Apple; viết báo cáo.
- Chưa hoàn tất/ngoài phạm vi: rebuild, sửa Native12, test thực trên iPhone/xe, đo FPS/CPU/°C, build .deb, publish Sileo.
- GitHub duy nhất chứa hồ sơ DuoFace: `chuongnguyen89dn-ui/Duoface`. Các repo khác dùng làm nguồn tham khảo, **không sửa**.
- Khi được yêu cầu làm thử, bắt buộc tái tải **Native12 exact DEB** từ `f08b6f4a7be0bc3a38cce1b0c9b52f8179841064`, kiểm SHA256 `85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7`, và giữ Native13–21 chỉ để điều tra.
