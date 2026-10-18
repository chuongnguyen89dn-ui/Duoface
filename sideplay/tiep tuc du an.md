# SIDEPLAY — HỒ SƠ THEO DÕI VÀ BÀN GIAO (DuoFace)

> **ĐẦU MỐI HOẠT ĐỘNG TỪ 2026-10-18 15:52 ICT.**
> Đây là luồng phát triển **SidePlay → DuoFace độc lập** nằm trong repo `chuongnguyen89dn-ui/Duoface`, KHÔNG phải nhánh QA/MyTweak cũ, KHÔNG phải bản Native12/Visual12 đang được phân phối. Hồ sơ này là nơi ghi checkpoint mới cho hướng SidePlay; giữ các hồ sơ cũ làm lịch sử.

## 1. QUYẾT ĐỊNH MỚI NHẤT — USER_DECISION (2026-10-18)

- Hướng CarPlay DuoFace hiện tại được chủ dự án tuyên bố **thất bại vì chưa tách được phụ thuộc giấy phép**. Không tiếp tục vá giấy phép hoặc trộn lõi DuoNavi/QA vào DuoFace để cứu phương án cũ.
- **Chuyển hướng:** xây dựng **nền tương thích chức năng SidePlay từ đầu, độc lập**, rồi đưa **toàn bộ giao diện và tương tác DuoFace** sang nền mới; không làm UI QA thay thế.
- SidePlay là **tài liệu tham chiếu về hành vi, cơ chế kết nối và luồng scene**, không tự động đồng nghĩa có mã nguồn SidePlay được cấp phép sử dụng. Chỉ triển khai mã do dự án tự viết / thành phần được phép dùng; **không bê cơ chế giấy phép, trial, nhị phân độc quyền hoặc cách vô hiệu hóa bảo vệ** vào sản phẩm.
- **Bảo toàn** mọi bản hiện có Native12, Visual12, Hub8 và nhánh QA/MyTweak; không tự ghi đè package/bundle ID, phát hành Sileo hay tự chạy workflow đóng gói. Kiểm thử độc lập rồi mới cân nhắc thay thế theo yêu cầu mới.

## 2. EXECUTION LOCK / CHECKPOINT

| Trường | Trạng thái tại lúc tạo hồ sơ |
|---|---|
| Repository lưu mã và bàn giao | `chuongnguyen89dn-ui/Duoface` |
| Nhánh viết hồ sơ | `main` |
| Base commit main đã đối chiếu | `56321974682442693f9bdca3ba7d386b99e0f457` (2026-10-18 06:01:20 UTC) |
| QA để tham khảo, không chỉnh | `feature/visual12-duodash-recovery` tại `c11ff1181eeda01dfc5e81f5166c99ba0287cfed` (2026-10-18 08:50:24 UTC): ghi dừng đường MyTweak QA trùng lặp |
| Thư mục làm việc SidePlay | `sideplay/` (tạo hồ sơ trước; **chưa có source SidePlay mới** trong lần ghi này) |
| Đầu mối bàn giao SidePlay | `sideplay/tiep tuc du an.md` (file này) |
| Bàn giao DuoFace cũ | `ban giao du an duoface moi.md` (lịch sử độc lập cũ); `tiep tuc du an.md` (lịch sử thế hệ trước); không thay/xóa |
| Nguồn hình ảnh/giao diện tham chiếu | `dist/visual-1.0.3-12/assets/`, `dist/visual-1.0.3-12/CONTENTS.txt`, `dist/visual-1.0.3-12/verification.json`; xác minh chi tiết trước khi sử dụng |
| Loại sản phẩm đích | DEB rootless `iphoneos-arm64` cho iOS 16 / CarPlay; **chưa build gói SidePlay-DuoFace** |
| Thiết bị nghiệm thu dự kiến | iPhone X rootless iOS 16.7.x, iPhone 8 Plus iOS 16, màn CarPlay DiPlay/Mazda CX-5; nghiệm thu thực tế **chưa diễn ra** |
| Phát hành đích | GitHub Actions artifact → Sileo **chỉ sau khi có yêu cầu đóng gói/phát hành** |
| Tình trạng Actions tại lần kiểm tra | Truy vấn `status=in_progress` và `status=queued` cho repo đều có 0 run; chỉ phản ánh thời điểm kiểm tra, không phải giám sát liên tục |
| Việc đã làm | Xác minh repo/nhánh, các hướng cũ, đọc ZIP kỹ năng 01/02/06, tạo hồ sơ theo dõi SidePlay; **không sửa code, không build, không test thiết bị** |
| Phần bị chặn | Chưa kiểm kê/đọc bản SidePlay gốc trong repo và chưa xác nhận giấy phép sử dụng/source của thành phần nào; chưa có baseline SidePlay hoạt động trên máy thật |

## 3. PHẠM VI TRIỂN KHAI VÀ TIÊU CHÍ NGHIỆM THU

**G0 — Chốt baseline.** Xác minh gói SidePlay được tham chiếu trong trao đổi trước đây (`com.sideplay_1.0.4-1_iphoneos-arm64.deb`, chỉ là tên được nhắc tới, **không khẳng định đang có trong repo hoặc đã giải nén**). Đối chiếu control, payload, lớp nạp, app/tweak, entitlements, lifecycle, API và điều kiện độc lập; lưu inventory + checksum chính xác nếu có file. Không nhầm `dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb` với SidePlay.

**G1 — Nền CarPlay độc lập.** Thiết kế/thực hiện từ đầu bootstrap, danh sách app, tạo/quản lý scene/window, host app iPhone không hỗ trợ CarPlay, lifecycle/teardown an toàn trên iOS 16 rootless. Không gọi `CB*`/watchdog giấy phép của DuoNavi; không chép nhị phân/proprietary code của SidePlay. Phải test mở–đóng–mở lại và SpringBoard restart trên thiết bị thật.

**G2 — Mang giao diện DuoFace sang ĐẦY ĐỦ.** Đối chiếu inventory file/assets, kích thước/màu sắc, lớp UI, các khung chia, biểu tượng, logo, nút và logic của bản Native12/Visual12/HUD8 trước khi cấy ghép. Bảo toàn trải nghiệm DuoFace, không mang khung UI hoặc thanh che khởi động từ QA. Ghi mapping từng thành phần, file nguồn, file đích và bằng chứng kiểm thử.

**G3 — Tương tác giao diện.** Split ratio kéo được; nhấn giữ đường chia để hoán đổi; menu App/Zoom/Style/Close với đúng hành vi đã chốt; fullscreen chỉ ở Zoom; viền đỏ lúc chạm và tự ẩn, không giữ viền trong fullscreen. HUD tốc độ đã có trong bản tham chiếu cần kiểm kê để ghép sau khi host và UI nền ổn định; không ưu tiên phát triển tính năng HUD mới trước khi chuyển UI xong.

**G4 — Ổn định.** Không mất kết nối CarPlay, không treo/exitmode khi đóng scene hoặc respring; app launcher hoạt động thật trên iPhone X và 8 Plus. Dùng log SpringBoard/scene và test thiết bị, không ghi PASS chỉ vì compile hoặc tạo DEB.

**G5 — Phân phối độc lập.** Package/bundle ID và đường dẫn riêng không phụ thuộc DuoNavi/SidePlay; không xung đột các bản Native/Hub/Sileo cũ. Xuất DEB, checksum, build artifact, bản thử Sileo **theo yêu cầu phát hành cụ thể** sau G1–G4.

## 4. QUY TẮC KHÔNG ĐƯỢC THAY ĐỔI ÂM THẦM

- Không tiếp tục ghép nhân lõi QA/MyTweak hoặc DuoNavi rồi gọi đó là SidePlay mới.
- Không sửa/xóa/ghi đè bản Native12/Hub8/Visual12 đã có hoặc tự chuyển nhánh đang được người khác sử dụng.
- Không bỏ bớt các thành phần giao diện để lấy bản build có vẻ chạy được; chuyển nguyên vẹn có kiểm kê.
- Không suy luận DEB tham chiếu chứa mã nguồn, không khẳng định SidePlay không có giấy phép nếu chưa xác minh.
- Không sửa cơ chế giấy phép của bên thứ ba; dự án mới phải độc lập về mã nguồn, package, identifiers và hạ tầng phân phối.

## 5. BƯỚC TIẾP THEO CÓ THỂ THỰC HIỆN NGAY

1. Kiểm tra README này và checkout trạng thái mới nhất của `main`, QA branch; rà lại jobs chạy tránh chạy trùng.
2. Xác định file tham chiếu SidePlay thật trong GitHub/đầu vào đã có, có checksum và khả năng đọc; nếu chỉ có DEB, đánh dấu `binary reference, no source`.
3. Tạo `sideplay/INVENTORY.md` ghi so sánh từng tầng SidePlay với G1–G5 và DuoFace Native12/Visual12; *chưa viết appbridge bằng suy đoán*.
4. Chỉ sau khi inventory & quyền sử dụng rõ ràng: tạo branch/source SidePlay độc lập và compile-only test, lưu commit và logs, không build DEB ngoài phạm vi cho phép.
5. Tiếp tục bổ sung **file này** mỗi khi có thay đổi yêu cầu, code, kết quả test, lỗi, checkpoint; sau khi ghi phải đọc lại chính file trên GitHub.

## 6. EVENT LOG — CẬP NHẬT THEO SỰ KIỆN

- **2026-10-18 15:52 ICT — USER_DECISION:** Dừng hướng CarPlay DuoFace hiện tại do phụ thuộc giấy phép không thể giải quyết; mở hướng SidePlay từ đầu + chuyển nguyên vẹn giao diện DuoFace. Không coi MyTweak QA là nền được chọn.
- **2026-10-18 15:52 ICT — CONFIRMED:** Đã truy cập `Gpt-training-` và đọc thực tế `skills/01-github-continuity.zip`, `skills/02-ios-deb-ipa-carplay.zip`, `skills/06-artifact-zip-handoff.zip` (các `SKILL.md` bên trong); kiểm tra repo DuoFace `main`, nhánh QA, workflows và cấu trúc assets. Không có đường dẫn `sideplay/` trong cây `main` trước khi tạo.
- **2026-10-18 15:52 ICT — NOT_YET:** Chưa sửa mã nguồn, chưa tạo baseline chạy CarPlay/DEB SidePlay, chưa kiểm thử thực tế hoặc xuất bản.
