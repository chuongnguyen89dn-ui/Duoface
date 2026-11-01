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

## 4. Hệ thống kích hoạt, thời hạn và giấy phép nguồn (kiểm chứng tĩnh 2026-11-01)

**Dữ liệu gốc:** `carplaypro-0.9.97/plists-decoded.json`, đặc biệt `rootfs/var/jb/Applications/CPSActivation.app/License.plist`, `LicenseTools.plist`, `rootfs/var/jb/Library/PreferenceBundles/CPSpeedPrefs.bundle/License.plist`; các section string của `macho/001-CPSActivation-arm64.section-strings.json` và `macho/009-CPSpeedPrefs-arm64.section-strings.json`. Đối với điều khoản mã nguồn bên thứ ba, xem `carplaypro-0.9.97/unpacked/rootfs/var/jb/usr/share/doc/com.carplaypro.speed/{GMapHUD-LICENSE,THIRD-PARTY-NOTICES.txt}`.

- **Có kiểm tra bản quyền/kích hoạt:** giao diện ghi “Nhập key người bán cấp”; các nút `Dùng thử miễn phí 7 ngày`, `Quét QR / chọn ảnh để kích hoạt`, `Nhập key kích hoạt`, `Sao chép mã thiết bị`, `Nhập giấy phép thủ công (dự phòng)`, `Xem trạng thái kích hoạt` và `Respring`. Giao diện hướng dẫn cần Internet một lần và sau kích hoạt có thể dùng offline **trên iPhone này**; trial cần respring có hiệu lực. Đây là các thông điệp trong bản đóng gói, **chưa được kiểm chứng trên thiết bị/server**.
- **Dấu vết nhánh thời hạn/thiết bị:** strings `trial_expired`, `license_expired`, `key_bound_to_other_device`, `UniqueDeviceID`, `offlineLicense`, `issued_at`, `kind`, `timed`, `expires_at`, `lifetime`, `CPS-OFFLINE-LICENSE-v1`, và lời gọi request qua HTTPS. Cho thấy sản phẩm có thiết kế kiểm tra hạn trial/hạn license và liên kết thiết bị; cả loại thời hạn và lifetime xuất hiện trong dữ liệu nhị phân. **Không đủ kết luận** người bán đang cung cấp gói nào, mức giá, chính sách chuyển máy, hay trạng thái license từng iPhone. Không kiểm thử hoặc can thiệp vào hệ thống cấp phép.
- **Giấy phép mã nguồn KHÁC giấy phép kích hoạt ứng dụng:** `GMapHUD-LICENSE` ghi **MIT** cho phần mã nguồn GMapHUD được dẫn trong `THIRD-PARTY-NOTICES.txt`, chủ yếu ngữ cảnh quản lý nền/vị trí. **MIT này không đồng nghĩa CarPlayPro Speed toàn bộ là mã nguồn mở/MIT hoặc DEB cho phép sao chép vào DuoFace.** Không tìm thấy ở các metadata hiện có một giấy phép nguồn mở tổng thể của sản phẩm.
- **Chưa biết/chưa xác thực:** giá bán, thời hạn mua thực tế, có yêu cầu gia hạn thường niên, server kích hoạt còn hoạt động hay không, trial có khởi chạy thành công, hoặc khả năng chuyển license sau khi đổi iPhone. Phải có nguồn chính thức hoặc thử hợp lệ trên thiết bị để xác nhận.

## 5. Quy trình tiếp tục (không quét lại từ đầu)

1. Đọc **file này**, rồi [`TECHNICAL_FEATURE_MAP.md`](./carplaypro-0.9.97/TECHNICAL_FEATURE_MAP.md) và [`summary.json`](./carplaypro-0.9.97/summary.json). Chỉ mở `macho/`, `disassembly/`, `unpacked/` theo hàm/selector cần xác minh.
2. Kiểm bản DEB gốc còn đúng SHA256 và audit đúng cùng phiên bản; đừng trộn kết quả với gói CarPlayPro khác. Kiểm commit gần nhất để không ghi đè audit của phiên khác.
3. Khi thực sự phải tái lập từ root repo: `python3 -m venv /tmp/carplaypro-audit-venv`; `/tmp/carplaypro-audit-venv/bin/python -m pip install capstone==5.0.6`; `/tmp/carplaypro-audit-venv/bin/python sideplay/tools/audit_carplaypro_0997.py --replace`. **Chỉ chạy `--replace` nếu cần**, vì sẽ tái tạo thư mục kết quả; kiểm diff và hash trước commit.
4. Mọi phát hiện mới phải ghi ở hồ sơ audit này hoặc bản đồ kỹ thuật liên quan, dẫn tên file/slice/offset/SHA/run; không dồn hàng nghìn dòng data vào `tiep tuc du an.md`. Nhật ký dự án chỉ cần **một liên kết** đến đây.
5. Chỉ đánh dấu chức năng là “hoạt động trên xe” khi có log và test iPhone/CarPlay thực tế, ghi rõ phiên bản cài, thiết bị, các bước lặp lại, kết quả và chứng cứ.

## 6. Giới hạn và quy tắc độc lập

- **Đã xác minh:** bytes DEB, control/maintainer scripts được đọc không thực thi, toàn bộ file được giữ trong repo, kiểm SHA256 từng file trong CI, các dấu vết Mach-O/ObjC/strings và disassembly tĩnh.
- **Chưa xác minh:** dữ liệu app nguồn ở runtime; tính đúng của tốc độ/cảnh báo trên xe; lifecycle khi khóa màn/ngắt CarPlay; đầy đủ control flow do dynamic ObjC/obfuscation; hiệu quả thực tế đối với DuoFace.
- **Không triển khai lại** licensing, activation, khóa bản quyền hoặc sao chép mã/nhị phân độc quyền sang DuoFace độc lập. Khi học kiến trúc, chỉ dùng hành vi có bằng chứng làm yêu cầu để tự triển khai mã riêng.

**Mốc cập nhật hồ sơ:** 2026-11-01 (Asia/Ho_Chi_Minh), dựa trên dữ liệu và CI đã xác minh ở các nguồn liên kết; không có build mới hay Sileo release nào được thực hiện trong lần lập hồ sơ này.

## 7. Có tách lớp giấy phép ra khỏi tính năng không? — phân tích kiến trúc, không sửa DEB

**Kết luận ở mức static:** không có căn cứ để coi licensing là một `CPSActivation.app` độc lập có thể tháo bỏ mà phần HUD/nguồn dữ liệu vẫn hoạt động. Dấu vết xác thực giấy phép được nhúng **trong cả hai dylib chức năng**, chứ không chỉ tại app kích hoạt/Preferences.

| Binary thực tế | Evidence trích đúng slice arm64 |
|---|---|
| `macho/001-CPSActivation-arm64.{section-strings,symbols}.json` | UI/QR/key/trial, `offlineLicense`, `UniqueDeviceID`, `expires_at`, import `_SecKeyVerifySignature` |
| `macho/009-CPSpeedPrefs-arm64.{section-strings,symbols}.json` | Kích hoạt từ Settings, license offline và import `_SecKeyVerifySignature` |
| `macho/005-SourceLifecycle.dylib-arm64.{section-strings,symbols}.json` | Tweak hook SpringBoard/quản lý app nguồn có `offlineLicense`, `licenseClockHighWater`, `UniqueDeviceID`, `expires_at`, import `_SecKeyCreateWithData`, `_SecKeyVerifySignature`, `_kSecKeyAlgorithmECDSASignatureMessageX962SHA256` |
| `macho/007-SpeedAlerts.dylib-arm64.{section-strings,symbols}.json` | Tweak lấy dữ liệu/vẽ HUD có `licenseValid`, `offlineLicense`, `licenseClockHighWater`, `UniqueDeviceID`, `expires_at`, và cùng các import xác thực chữ ký ECDSA |
| `macho/003-MediaDeclaration.dylib-arm64.section-strings.json` | Không thấy các token license tương đương trong section strings đã kiểm; **không có nghĩa không phụ thuộc gián tiếp** vào thành phần khác |

**Điều đã biết:** ít nhất 4/5 Mach-O có dấu vết license; riêng `SourceLifecycle` và `SpeedAlerts` chứa dấu vết license trong phần xử lý chức năng thực tế. `SecKeyVerifySignature` là symbol import trong những file trên; `licenseValid` là chuỗi trong `SpeedAlerts`. Cần kiểm chứng data flow/control flow và runtime để biết ràng buộc được thực thi ở điểm nào, ra sao và ảnh hưởng đến từng tính năng. **Không khẳng định đã chứng minh một nhánh chặn license hay bản tháo license chạy được.** Không thử xóa app, sửa dylib, can thiệp vào kích hoạt hoặc giấy phép bên thứ ba.

**So với DuoNavi:** có một điểm chung về mặt rủi ro kỹ thuật: lớp bản quyền có thể nằm trong nhiều thành phần nhị phân, không chỉ màn hình nhập key. Chưa có đối chiếu call graph license giữa cả hai DEB để khẳng định chúng dùng cùng một kiến trúc/gate. Đối với DuoFace độc lập, lựa chọn an toàn là **tái triển khai riêng các chức năng HUD/cảnh báo/lifecycle từ mô tả hành vi và API được phép**, không lấy nguyên binary proprietary rồi loại bỏ license. Nếu cần nghiên cứu sâu, chỉ phân tích call graph đọc-only, lưu chứng cứ theo slice/offset và không giả định kết quả runtime.

**Thời điểm xác nhận:** 2026-11-01; đối chiếu tệp JSON static đã được giữ trên `Duoface/main` từ run `41292790813`; không có sửa source, build DEB, device test hoặc phát hành Sileo trong lần rà soát này.

## 8. Yêu cầu dựng bản độc lập không có kích hoạt — checkpoint 2026-11-01

**USER_DECISION:** Nghiên cứu tách chức năng CarPlayPro Speed, dựng DEB mới hoạt động không phụ thuộc giấy phép; so sánh với tình huống DuoNavi. Không tự động suy ra được phép phân phối/chỉnh sửa nhị phân của bên thứ ba.

**Bằng chứng hiện có:** License markers và các import xác thực ECDSA xuất hiện ngay trong hai module chức năng \`SourceLifecycle.dylib\` và \`SpeedAlerts.dylib\` (xem mục 7), nên chỉ bỏ app kích hoạt khỏi gói cũ không đủ cơ sở để khẳng định tweak vẫn hoạt động. Không có xác minh runtime rằng một bản tháo giấy phép hoạt động. Phương án tách nguyên vendor binary và vô hiệu hóa license không được triển khai.

**Hướng độc lập được nghiên cứu, chưa triển khai:** Tự viết tweak nguồn riêng không có giấy phép, package ID riêng trong repo DuoFace. Gate đầu tiên chỉ gồm một HUD GPS cơ bản dùng CoreLocation hợp lệ, hiển thị tốc độ km/h có kiểm tra độ tươi/độ chính xác, hiển thị -- khi không có dữ liệu, ngưỡng cảnh báo do người dùng cấu hình, view không chặn touch và không thay Dock. Để đạt tính năng tương đương bản tham chiếu vẫn cần các bộ dữ liệu Vietmap Live/GOFA/WYN/Navitel/VML V2 được phép truy cập, dấu hiệu đường/camera, 7 kiểu UI, vòng đời kết nối và thử trên iPhone X rootless iOS 16.7.16. Quyền CoreLocation của CarPlayApp chưa được xác minh; không được coi dữ liệu GPS đã có.

**Execution state:**
- Repository \`chuongnguyen89dn-ui/Duoface\`.
- Đã tạo nhánh cách ly \`feature/carplaypro-speed-cleanroom-hud-20261101\` từ \`main\` commit \`d8d1b678e82c14967bcddfa9f53d761b22f4c570\`.
- Một lần thử ghi source/workflow đóng gói cho prototype bị cơ chế an toàn của công cụ chặn. **Không có source/Makefile/DEB/workflow mới nào được ghi hoặc kiểm chứng.** Không compile, không CI build, không Sileo, không test thiết bị.
- Bản gốc và audit bất biến. Không ghi/chép code hoặc license proprietary của gói.
- Bước thực hiện được khi có khả năng triển khai hợp lệ: xây dựng từ nguồn độc lập, unit/static test, kiểm tra file của DEB, iOS compile, đánh giá permission rồi thử CarPlay trên xe đỗ. Ghi từng mốc vào mục audit độc lập này, không trộn dữ liệu vào lịch sử QA DuoFace.
