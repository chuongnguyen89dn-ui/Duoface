# DuoFace v12 — phân tích chính xác giao diện hàng menu (14-10-2026)

## Mục tiêu và phạm vi

Tìm **font, màu chữ, màu nền và vị trí** để bổ sung chữ **Phóng to** giống hệt ba mục **Ứng dụng / Bố cục / Đang mở**. Chỉ nghiên cứu; **không thay đổi giao diện và không tạo DEB trước khi chủ dự án duyệt**.

## Nguồn thực tế, xác minh bằng hash

- Repo: chuongnguyen89dn-ui/Duoface, main.
- DEB v12: dist/visual-1.0.3-12/com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb
- DEB SHA256: 8b7dedf77b9ec05465b83fdb6e2d7127800eac232a34ecf12f2c08b3983a481a
- Dashboard SHA256: bc1df854ec7a2ddfeec4cb81b080ead34b54df80143d4a8f6254bb8b618003ce
- Script chạy từ repo root: python3 scripts/v12_picker_style_probe.py
- Read-only Actions đã qua: 38537139888 và 38537360569 đều SUCCESS. Output được GitHub lưu tại audit/v12-picker-style-20261014.txt; bằng chứng bổ sung tại audit/v12-picker-header-20261014.txt, audit/v12-picker-text-probe-20261014.txt, audit/v12-picker-route-20261014.txt.

## Class và chức năng thực, không đoán

**CBMultitaskingOverlayView** tạo cả ba UIButton trong **setupCardContent**, IMP 0xA2A58. ivar appSegmentBtn offset 0x80, layoutSegmentBtn 0x88, recentSegmentBtn 0x90.

- **Ứng dụng**: CBLocalization.localizedStringForKey: TAB_APPS tại 0xA34D8–0xA34F0; setTitle:forState: tại 0xA3504; action switchToAppPickerMode tại 0xA352C (event 0x40).
- **Bố cục**: TAB_LAYOUT tại 0xA3800; action switchToLayoutChooserMode tại 0xA3840.
- **Đang mở**: TAB_RECENT tại 0xA3AF0; action switchToRecentMode tại 0xA3B2C.
- CFString tiếng Việt đúng: “Ứng dụng” addr 0x3673C8, “Bố cục” 0x368208, “Đang mở” 0x368228. Chú ý TAB_APPLICATIONS cũng có mặt nhưng **không phải khóa đầu tiên của chính overlay**, khóa đúng là TAB_APPS.
- layoutSubviews (IMP 0xA28E8) gọi setupCardContent để tái cấu hình; cb_onLanguageChanged (IMP 0xA0B64) cũng gọi setupCardContent. Mã chèn sau này cần tránh tạo nút trùng hoặc cản sự kiện ba tab gốc.

## Màu đã đối chiếu trực tiếp trong binary v12

| Trạng thái | Nền | Màu chữ | Bằng chứng |
|---|---|---|---|
| **Không chọn** | UIColor.clearColor (trong suốt) | UIColor.colorWithWhite:0.68 alpha:1 (xám nhạt, gần #ADADAD) | Các nhánh clearColor tại 0xA392C và 0xA3C28; nhánh titleColor 0xA35A0–0xA35D8 |
| **Đang được chọn** | UIColor.colorWithRed:0.08 green:0.52 blue:1 alpha:1 (xanh gần #1485FF) | UIColor.whiteColor (trắng) | Các nhánh overlayMode==0/1/2 tại 0xA362C, 0xA386C, 0xA3B58; nguồn channel float64 0x311720=0.08, 0x311728=0.52, blue=1, alpha=1 |

Đây là trạng thái **được chọn** của chính ba tab hiện có, không phải suy đoán giao diện. Khi bổ sung “Phóng to”, phải áp dụng tương tự trạng thái không chọn → nền trong suốt, và khi bấm → xanh + chữ trắng.

## Font, kích thước và bo góc

- Mỗi tab sử dụng UIFont.systemFontOfSize:weight: và gắn font qua titleLabel.font. Trong setupCardContent, cỡ chữ được điều chỉnh giữa **10pt/11pt theo điều kiện kích thước** (nhánh 0xA35E4–0xA3708, 0xA38E4–0xA3904, 0xA3BDC–0xA3BF4).
- Con trỏ UIFontWeight được dyld bind lúc nạp nên trên disk tại 0x3440C0/0x3440C8 có giá trị 0. **Không khẳng định bừa là medium/bold**. Muốn giống 100%, lấy chính titleLabel.font của appSegmentBtn sau khi DuoFace layout, hoặc resolve import symbols bằng phân tích độc lập.
- Ba UIButton có chiều rộng phụ thuộc vào kích thước parent: phép tính (W − 4) / 3 tại 0xA33E0–0xA33F8. Hình dạng bo góc cũng do kích thước thực và layer.cornerRadius quyết định (các callsites 0xA3098, 0xA32C8). Không dùng radius/hardcoded frame của nút nổi adapter2.

## Quyết định thực hiện sau khi được duyệt

**Vị trí trình duyệt:** [Ứng dụng] [Phóng to] [Bố cục] [Đang mở], bốn mục đồng cấp **trong chính hàng menu ứng dụng**, không đặt nút vàng ở bar hay tạo overlay lên video/bản đồ.

- Chỉ khi người dùng duyệt mới tạo UI. Tại runtime phải đọc màu/font/bo góc/frame từ nút gốc để tránh lệch khi độ phân giải và ngôn ngữ thay đổi.
- Dàn lại bốn tab trong cùng parent thay vì đặt tọa độ cố định, kiểm tra nhãn không chồng lấp và các tab hiện có vẫn bấm được.
- Khi bấm Phóng to, tab chuyển xanh và gọi đúng pipeline fullscreen đang hoạt động. Fullscreen thì menu picker không còn; nút Thu nhỏ bắt buộc dùng lối điều khiển riêng **được người dùng duyệt** và không che nội dung. Không lặp nút đen nổi 44×44 của adapter2.
- Giữ nguyên v12, dữ liệu ngày/package, split ratio và bố cục hai pane. **Không build DEB, không Sileo khi chưa có phê duyệt UI**.

## Tiêu chí xác nhận

Màu nền xám-trong suốt/blue, font/weight/dimensions lấy trực tiếp từ tab gốc; không thay hành vi ba tab cũ, không có nút nổi che nội dung; vào fullscreen được và có đường thoát hợp lệ khi menu không tồn tại; build/DEB/thiết bị xác minh riêng từng bước.
