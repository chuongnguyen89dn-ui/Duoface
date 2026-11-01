# CARPLAYPRO SPEED 0.9.97 — HỒ SƠ AUDIT ĐỘC LẬP

> **Đầu mối tra cứu chuẩn cho các cuộc chat sau.** Không đọc lại toàn bộ `sideplay/tiep tuc du an.md` để lấy dữ liệu CarPlayPro Speed. Hồ sơ này chỉ liên quan **CarPlay Pro Speed** (HUD/cảnh báo tốc độ), không thay thế nhật ký triển khai DuoFace/SidePlay. Cập nhật theo phiên bản DEB và bằng chứng mới, không suy đoán hoạt động runtime.

## 1. Danh tính và trạng thái bằng chứng

| Trường | Giá trị đã kiểm chứng |
|---|---|
| Repo / nhánh | `chuongnguyen89dn-ui/Duoface` / `main` |
| Package / Version | `com.carplaypro.speed` / `0.9.97` |
| Architecture / firmware | `iphoneos-arm64`, iOS >= 15.0 |
| DEB nguyên gốc (không sửa) | [`com.carplaypro.speed_0.9.97_iphoneos-arm64.deb`](./com.carplaypro.speed_0.9.97_iphoneos-arm64.deb) |
| Git blob SHA của DEB | `30f366a8bed8630c88935cac7146c86b875f0851` |
| Dung lượng / SHA256 | `984804` bytes / `e5b0918b3bc1948420f37a8a9e21365756da46fba44d582a3f2893aee9b4102f` |
| Gói đầu vào | `debian-binary`, `control.tar.gz`, `data.tar.lzma` |
| Audit CI đã xác nhận | [Run 41292790813](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41292790813) — `completed/success`, 2026-11-01 |
| Commit lưu trữ static audit | [`85aa37f`](https://github.com/chuongnguyen89dn-ui/Duoface/commit/85aa37f02046d44523015b30c64a23ed39703c57) |
| Commit bản đồ kỹ thuật | [`a29aa6c`](https://github.com/chuongnguyen89dn-ui/Duoface/commit/a29aa6cca57564ec4e9f6cf5e5c3009f948b44f6) |
| Trạng thái | **Đã kiểm kê/giải nén/phân tích tĩnh và lưu lên GitHub.** Chưa cài, chưa chạy script, chưa kiểm thử CarPlay thực tế. |

**Tránh nhầm:** Đây là CarPlayPro **Speed**, không phải một bằng chứng về cơ chế đưa app ngoài lên CarPlay Home hay chuyển Home → lưới app của DuoFace. Các lỗi Dashboard/khởi chạy chậm DuoFace là công việc riêng, đang tạm hoãn theo quyết định người dùng.

## 2. Chỉ mục dữ liệu lưu sẵn (không cần quét lại)

**Thư mục đã quét:** [`carplaypro-0.9.97/`](./carplaypro-0.9.97/)

| Cần tìm | Đường dẫn bằng chứng |
|---|---|
| Bản đồ chức năng, selector, module và giới hạn kết luận | [`TECHNICAL_FEATURE_MAP.md`](./carplaypro-0.9.97/TECHNICAL_FEATURE_MAP.md) — **đọc đầu tiên** |
| Tổng quan kỹ thuật và lệnh tái lập | [`README.md`](./carplaypro-0.9.97/README.md) |
| Số lượng, SHA đầu vào, phạm vi test | [`summary.json`](./carplaypro-0.9.97/summary.json) |
| Toàn bộ file, modes và hash | [`inventory.json`](./carplaypro-0.9.97/inventory.json), [`SHA256SUMS.txt`](./carplaypro-0.9.97/SHA256SUMS.txt), [`archive-file-list.txt`](./carplaypro-0.9.97/archive-file-list.txt) |
| Metadata, Depends, scripts | [`control-fields.txt`](./carplaypro-0.9.97/control-fields.txt), [`package-info.txt`](./carplaypro-0.9.97/package-info.txt), `carplaypro-0.9.97/unpacked/control/` |
| Payload nguyên byte, app, tweak, resources | `carplaypro-0.9.97/unpacked/rootfs/` |
| Preferences, injection filters, plist | [`plists-decoded.json`](./carplaypro-0.9.97/plists-decoded.json) |
| Ảnh | [`images.json`](./carplaypro-0.9.97/images.json) và `unpacked/rootfs/` |
| Binaries và kiến trúc | [`macho-summary.json`](./carplaypro-0.9.97/macho-summary.json), `carplaypro-0.9.97/macho/` |
| Các lệnh ARM64/ARM64e disassembly tĩnh | `carplaypro-0.9.97/disassembly/*.arm64.txt.gz` |
| Công cụ quét có thể chạy lại | [`sideplay/tools/audit_carplaypro_0997.py`](../tools/audit_carplaypro_0997.py) |
| CI tái lập & kiểm checksum | [`.github/workflows/carplaypro-exhaustive-static-audit.yml`](../../.github/workflows/carplaypro-exhaustive-static-audit.yml) |

Audit đã ghi nhận **94 file payload + 3 file control**, 115 entry (bao gồm 18 thư mục), **5 Mach-O universal** với tổng **10 slices arm64/arm64e**, **16 plist**, **69 ảnh**, **85.162 instruction records** disassemble, **1.915 function starts**, **1.852 symbol records**, **3.760 ObjC method names**, **13.188 string records** (có trùng giữa các slices). Số lượng lấy từ báo cáo tĩnh, không có nghĩa đã biết đầy đủ hành vi khi chạy.

## 3. Sơ đồ module và đường nối đã xác minh tĩnh

| Thành phần | Nơi chạy / filter từ plist | Chức năng có dấu vết trong DEB |
|---|---|---|
| `MediaDeclaration.dylib` | `mediaserverd` | Media/audio declaration, dấu vết Navitel |
| `SourceLifecycle.dylib` | `com.apple.springboard` | `openSource`, `closeSource`, `maintain:pid:source:`, kết nối/ngắt CarPlay, giữ phiên nền |
| `SpeedAlerts.dylib` | `com.apple.CarPlayApp`, Vietmap Live, VML V2, GOFA, WYN, Navitel | Thu thập tốc độ/cảnh báo và dựng overlay; các class `SACollector`, `SAOverlay`, `SADisplayWindow`, các dấu vết `CLLocationManager` |
| `CPSActivation.app` | App iPhone (`com.carplaypro.activation`) | UI, kích hoạt qua QR/network, chẩn đoán; URL scheme `cpspeed-activate://` |
| `CPSpeedPrefs.bundle` | PreferenceLoader / Settings | `CPSpeedRootController`, chọn nguồn, style, ngưỡng cảnh báo và kiểm tra thử |

**Nguồn được hiển thị trong cấu hình:** `0=Vietmap Live`, `1=GOFA`, `2=WYN`, `3=Navitel` (mặc định), `4=VML V2`. Metadata gói nói “four selectable sources” nhưng plist thực tế ghi **5**. App bundle filter tương ứng: `vn.vietmap.live`, `com.lumi.GOFA`, `com.wynauto.wyn`, `su.navitel`, `vn.vietmap.live.v2`.

**Cài đặt có bằng chứng:** bật/tắt, âm báo khởi động, mở nguồn khi CarPlay kết nối và đóng nguồn khi ngắt; **7 kiểu overlay**, size 0.6–1.4; cảnh báo đường và dẫn đường, nền tùy chọn (8 preset), opacity/hex, ngưỡng vượt tốc độ, đổi màu/nhấp nháy, diagnostics export, thử tốc độ/giới hạn/cảnh báo 30 giây. Trường/kiểu/mặc định chi tiết nằm trong `plists-decoded.json`; tham chiếu [bản đồ chức năng](./carplaypro-0.9.97/TECHNICAL_FEATURE_MAP.md) trước khi kết luận một tính năng.

## 4. Quy trình tiếp tục (không quét lại từ đầu)

1. Đọc **file này**, rồi [`TECHNICAL_FEATURE_MAP.md`](./carplaypro-0.9.97/TECHNICAL_FEATURE_MAP.md) và [`summary.json`](./carplaypro-0.9.97/summary.json). Chỉ mở `macho/`, `disassembly/`, `unpacked/` theo hàm/selector cần xác minh.
2. Kiểm bản DEB gốc còn đúng SHA256 và audit đúng cùng phiên bản; đừng trộn kết quả với gói CarPlayPro khác. Kiểm commit gần nhất để không ghi đè audit của phiên khác.
3. Khi thực sự phải tái lập từ root repo: `python3 -m venv /tmp/carplaypro-audit-venv`; `/tmp/carplaypro-audit-venv/bin/python -m pip install capstone==5.0.6`; `/tmp/carplaypro-audit-venv/bin/python sideplay/tools/audit_carplaypro_0997.py --replace`. **Chỉ chạy `--replace` nếu cần**, vì sẽ tái tạo thư mục kết quả; kiểm diff và hash trước commit.
4. Mọi phát hiện mới phải ghi ở hồ sơ audit này hoặc bản đồ kỹ thuật liên quan, dẫn tên file/slice/offset/SHA/run; không dồn hàng nghìn dòng data vào `tiep tuc du an.md`. Nhật ký dự án chỉ cần **một liên kết** đến đây.
5. Chỉ đánh dấu chức năng là “hoạt động trên xe” khi có log và test iPhone/CarPlay thực tế, ghi rõ phiên bản cài, thiết bị, các bước lặp lại, kết quả và chứng cứ.

## 5. Giới hạn và quy tắc độc lập

- **Đã xác minh:** bytes DEB, control/maintainer scripts được đọc không thực thi, toàn bộ file được giữ trong repo, kiểm SHA256 từng file trong CI, các dấu vết Mach-O/ObjC/strings và disassembly tĩnh.
- **Chưa xác minh:** dữ liệu app nguồn ở runtime; tính đúng của tốc độ/cảnh báo trên xe; lifecycle khi khóa màn/ngắt CarPlay; đầy đủ control flow do dynamic ObjC/obfuscation; hiệu quả thực tế đối với DuoFace.
- **Không triển khai lại** licensing, activation, khóa bản quyền hoặc sao chép mã/nhị phân độc quyền sang DuoFace độc lập. Khi học kiến trúc, chỉ dùng hành vi có bằng chứng làm yêu cầu để tự triển khai mã riêng.

**Mốc cập nhật hồ sơ:** 2026-11-01 (Asia/Ho_Chi_Minh), dựa trên dữ liệu và CI đã xác minh ở các nguồn liên kết; không có build mới hay Sileo release nào được thực hiện trong lần lập hồ sơ này.
