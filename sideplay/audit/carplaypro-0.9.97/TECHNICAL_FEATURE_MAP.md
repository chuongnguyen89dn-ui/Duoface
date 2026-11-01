# CarPlay Pro Speed 0.9.97 — bản đồ chức năng từ DEB gốc (static, verified)

## Phạm vi và nguồn
- **Nguồn gốc chính xác:** `Duoface/main:sideplay/audit/com.carplaypro.speed_0.9.97_iphoneos-arm64.deb`.
- **Original Git blob:** `30f366a8bed8630c88935cac7146c86b875f0851`; **984,804 bytes**, SHA256 `e5b0918b3bc1948420f37a8a9e21365756da46fba44d582a3f2893aee9b4102f`.
- Audit nguồn/công cụ: `sideplay/tools/audit_carplaypro_0997.py`; workflow `.github/workflows/carplaypro-exhaustive-static-audit.yml`; GitHub Actions [41292790813](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41292790813) **SUCCESS**; bản quét kết quả đầu tiên đầy đủ đa kiến trúc commit `85aa37f02046d44523015b30c64a23ed39703c57`.
- Không cài DEB, không chạy maintainer scripts, không mở đường license, không kiểm thử trên xe. Thông tin là bằng chứng tĩnh từ bytes có trong gói. **Không khẳng định có thể lấy được mã nguồn gốc**, hoặc bao phủ runtime/data bị obfuscate.

## Kiểm kê đã kiểm chứng trên GitHub
- Archive package: 1 DEB, Debian control archive, data archive; **94 file payload**, **3 file control**, **18 thư mục**, tổng **115 entries**.
- **5 executable/dylib Mach-O fat/universal**, mỗi file có arm64 và arm64e ⇒ **10 architecture slices** đã phân tích riêng biệt.
- Có **16 plist được giải mã**, **69 ảnh nhận diện**, tất cả file có pathname/mode/size/SHA256 trong `inventory.json` và `SHA256SUMS.txt`.
- Tất cả 10 slices: **85,162 lệnh ARM64 đã disassemble**, **1,915 function starts**, **1,852 symbol records**, **3,760 tên phương thức ObjC lấy từ section**, **13,188 ASCII/UTF16 string records** (tổng trên 2 kiến trúc, có lặp; không phải số unique). Tất cả file kết quả dạng JSON/gzip đã push vào `macho/` và `disassembly/`.
- Full package bytes đã giải nén giữ nguyên ở `unpacked/rootfs/`, `unpacked/control/`; so SHA256 từng file thành công trong CI. Không có bước chạy bản cài hoặc reset thiết bị.

## Metadata / môi trường
- **Package:** `com.carplaypro.speed`, **Name:** `CarPlay Pro Speed`, **Version:** `0.9.97`, **Architecture:** `iphoneos-arm64`, yêu cầu firmware iOS >= 15.0.
- **Dependencies:** `mobilesubstrate`, `preferenceloader`, firmware; **Conflicts:** `com.carplaypro.navitelprobe`.
- Package Description ghi **“four selectable sources” nhưng menu cấu hình thật chứa 5 lựa chọn** (đây là sai khác tài liệu/metadata; không được lược bỏ VML V2).
- Rootless prefix `/var/jb/`. `postinst` chỉ dùng `uicache -p /var/jb/Applications/CPSActivation.app` nếu có; `postrm` dùng `uicache -u` khi remove/purge. Script đã được đọc **nhưng không thực thi**.
- App iPhone `CPSActivation.app` Bundle ID `com.carplaypro.activation`, bản 0.9.97, iOS 15.0+, chỉ portrait; `UIBackgroundModes=[audio]`, có `NSCameraUsageDescription` cho QR và URL scheme `cpspeed-activate://`.
- Preference bundle `CPSpeedPrefs.bundle` Bundle ID `com.carplaypro.speed.prefs`, controller `CPSpeedRootController`.

## Các module và process hook (từ filter plist, không suy đoán)
| Mach-O chính | Substrate injection filter xác nhận | Bằng chứng chức năng tĩnh |
|---|---|---|
| `MediaDeclaration.dylib` | `Executables: mediaserverd` | Log strings `media declaration`, Navitel-specific audio/media declaration; CydiaSubstrate linked |
| `SourceLifecycle.dylib` | `Bundles: com.apple.springboard` | `openSource`, `closeSource`, `SLMediaSession`, `SLBackgroundSession`, CarPlay connect/disconnect; nguồn app, PID, background/lease |
| `SpeedAlerts.dylib` | `com.apple.CarPlayApp`, `vn.vietmap.live`, `vn.vietmap.live.v2`, `com.lumi.GOFA`, `com.wynauto.wyn`, `su.navitel` | `SACollector`, `SAOverlay`, `SADisplayWindow`, GPS/CoreLocation, source-specific alert and speed data extraction, CarPlay window/bubble |
| `CPSActivation` app | Normal installed iPhone application, not tweak dylib | Preference UI, local/remote activation request, QR scanner, optional audio probe, diagnostics/test screens |
| `CPSpeedPrefs` | PreferenceLoader bundle | Cấu hình từ Settings, preferences + license UI |

**Các nguồn thực tế trong menu** (`Root.plist`, `Source.plist`): `0=Vietmap Live`, `1=GOFA`, `2=WYN`, `3=Navitel` (mặc định), `4=VML V2`. Mapping bundle từ Substrate filter và `SourceLifecycle.dylib` có: `vn.vietmap.live`, `com.lumi.GOFA`, `com.wynauto.wyn`, `su.navitel`, `vn.vietmap.live.v2`. App data path/readability của từng nhà cung cấp **chưa xác minh bằng runtime**.

## Cấu hình UI được trích từ decoded plists (có byte evidence)
- `enabled` bật/tắt tweak; `startupSound` âm thanh mở; `source` lựa chọn nguồn; `launchSourceOnConnect` đánh thức app nguồn chạy nền; `closeSourceOnDisconnect` đóng nguồn khi ngắt CarPlay.
- Overlay chọn `style` với **7 kiểu**: Thẻ gọn, Tròn, Thanh ngang, Viên thuốc, Vuông bo góc, Thẻ dọc, Viên thuốc dọc; `size` slider mô tả 0.6–1.4.
- `showRoadAlerts` biển cảnh báo, `showNavigation` hướng rẽ/khoảng cách; `backgroundTransparent`, `backgroundPreset` có 8 mục (than chì, xanh đêm, xanh biển, xanh rêu, đỏ rượu, tím, trắng ngà, tùy chỉnh), `backgroundOpacity`, `backgroundHex` mặc định `#101820`.
- `tolerance` km/h vượt giới hạn; `warningMode` gồm `Đổi màu` hoặc `Đổi màu và nhấp nháy`.
- `recordDiagnostics`, `exportDiagnostics`; `testSpeed`, `testLimit`, cảnh báo thử 30 giây + dừng.
- Preference notification `com.carplaypro.speed.preferences-changed`; channel string `com.carplaypro.speed.active-source`. Các giá trị cụ thể, kiểu cell, lựa chọn và mặc định nằm trong `plists-decoded.json`.

## Kỹ thuật và hành vi chỉ có bằng chứng tĩnh
- `SpeedAlerts` có ObjC class/method liên quan `CLLocationManager`, `locationManager:didUpdateLocations:`, `gpsFields`, `alertsUpcoming`, `cameraUpcoming`, `gofaAlertGroups`, `navitelAlerts`, `SAStartupLayer`, `SANoninteractiveBorderLayer`, `SASoftWarningBorder`, `renderTick`. Các selector/log strings cho thấy có xử lý tốc độ, giới hạn tốc độ, biển cảnh báo và mô hình hiển thị, **không chứng minh mọi dữ liệu thực tế hoạt động đúng**.
- `SourceLifecycle` chứa `openSource`, `closeSource`, `maintain:pid:source:`, dấu vết connect/disconnect và background resource/audio lease. Phạm vi owner là SpringBoard. Không thể suy ra chính xác response speed chỉ từ selector.
- `MediaDeclaration` liên quan `mediaserverd`, “Navitel only” trong log marker. Không kết luận hiệu quả/cơ chế âm thanh trên xe khi chưa thử.
- `CPSActivation` sử dụng `AVCaptureMetadataOutputObjectsDelegate`, `NSURLSession`, hỗ trợ QR/license và camera permission; `License.plist`, `LicenseTools.plist` được lưu dưới `unpacked`, báo cáo metadata có redaction giá trị giống credential. **Không dùng/viết lại hoặc vượt qua giấy phép của bên thứ ba**.
- Các chữ ký CodeSignature SuperBlob, dylib paths/imports, RPATH, UUID, build version, ARM64/arm64e instructions và symbols được lưu per-slice. Không quan sát/giả vờ có jailbreak device execution traces.

## Đầu mối bằng chứng và lệnh tái lập
- `summary.json`: counts + source SHA + phạm vi/giới hạn.
- `inventory.json`, `SHA256SUMS.txt`, `archive-file-list.txt`, `archive-members.txt`: toàn bộ đường dẫn, mode, kích thước, hashes và archive list.
- `control-fields.txt`, `package-info.txt`, `unpacked/control/{control,postinst,postrm}`: package metadata và shell scripts gốc.
- `unpacked/rootfs/`: toàn bộ file payload binary và resource nguyên gốc.
- `plists-decoded.json`, `images.json`: decoded configs, filters, assets.
- `macho-summary.json`, `macho/*.load-commands.json`, `*.symbols.json`, `*.function-starts.json`, `*.section-strings.json`, `*.strings.txt.gz`: tất cả slice-binaries và metadata.
- `disassembly/*.arm64.txt.gz`: toàn bộ disassembly của arm64 và arm64e per-slice, gzip, **không phải source ObjC/Swift gốc**.

Lệnh workflow chạy từ root `Duoface`: `python3 -m venv /tmp/carplaypro-audit-venv`; `/tmp/carplaypro-audit-venv/bin/python -m pip install capstone==5.0.6`; `/tmp/carplaypro-audit-venv/bin/python sideplay/tools/audit_carplaypro_0997.py --replace`; GitHub Actions kiểm hash mọi file, sau đó `git add -A -- sideplay/audit/carplaypro-0.9.97/`, commit và push `main`. Run `41292790813` **SUCCESS**; full results persisted on `main`.

## Giới hạn phải giữ khi đối chiếu DuoFace
Đây là bản **CarPlayPro Speed cảnh báo tốc độ**, không phải một chứng cứ chứng minh tính năng điều hướng Home hoặc cơ chế đưa app bất kỳ lên màn hình CarPlay như dự án DuoFace. Không kết luận nó giải quyết Home→Dashboard; tạm hoãn lỗi DuoFace theo yêu cầu user. Không áp dụng vendor license, activation server, keys, or closed-source original code vào dự án độc lập. Nếu cần nghiên cứu một selector cụ thể sau này, trích từ `section-strings.json` và `disassembly` với offset/architecture rồi đối chiếu runtime iOS 16.7.16.
