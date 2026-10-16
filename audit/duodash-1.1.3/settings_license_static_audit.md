# DuoDash 1.1.3 — kiểm kê Cài đặt và cơ chế giấy phép (đọc DEB, 16/10/2026)

## Nguồn và giới hạn

- Nguồn đọc trực tiếp: file người dùng gửi `com.sensetechlab.duodash_1.1.3_iphoneos-arm64.deb`; SHA256 **`16ffab22b4246dea9978cae92df7ec635d833ec067b4d9f425a231b26edec601`**; gói rootless, kiến trúc `iphoneos-arm64`. Metadata cho biết đã repack bằng `dpkg-repack` ngày 25/09/2026. Có thể khác DEB phát hành gốc; không suy diễn nguồn gốc bổ sung.
- Chỉ kiểm kê **phần Cài đặt và những chỉ dấu license**. Người dùng yêu cầu **không truy mạch chia ô, UI CarPlay hay bố cục của DuoDash**, và chưa yêu cầu chuyển chức năng sang DuoFace. Không cài/chạy DEB, không kiểm thử thiết bị hoặc quan sát lưu lượng thực tế.
- Đã thực thi `dpkg-deb -e/-x`, `python plistlib`, tách ba file Mach-O FAT sang slice arm64, `strings`, `llvm-objdump --macho --arch=arm64 --objc-meta-data` và disassembly; kiểm tra maintainer script.
- Repo đích ghi bằng chứng: `chuongnguyen89dn-ui/Duoface`, không phải repo kỹ năng. DEB gốc là file upload từ người dùng trong chat; không tuyên bố đã push file binary gốc lên GitHub.

## File nào tạo trang cài đặt?

| Đường dẫn tương đối bên trong DEB | Vai trò đã xác minh |
|---|---|
| `var/jb/Library/PreferenceLoader/Preferences/DuoDashPrefs.plist` | 26 phần tử = **8 nhóm và 18 hàng** settings; có các `PSSwitchCell`, `PSStaticTextCell`, `PSButtonCell`, `PSLinkListCell` |
| `var/jb/Library/PreferenceBundles/DuoDashPrefs.bundle/Root.plist` | **10 phần tử = 2 nhóm và 8 hàng**: HUD Device + Performance Tweak |
| `var/jb/Library/PreferenceBundles/DuoDashPrefs.bundle/Info.plist` | `NSPrincipalClass=DuoDashRootListController` |
| `var/jb/Library/PreferenceBundles/DuoDashPrefs.bundle/DuoDashPrefs` | FAT arm64/arm64e; Objective-C controller và app picker; `-[DuoDashRootListController specifiers]` tại arm64 address **0x4000** gọi nạp plist **`Root`**, xác nhận Root.plist có code path, không chỉ là dữ liệu thừa. `setPreferenceValue:specifier:` ở **0x42e4**, `chooseAppsToBridge:` ở **0x41cc**, `_readPrefForKey:defaultValue:` ở **0x48e8** |
| `var/jb/usr/lib/TweakInject/DuoDash.dylib` | FAT arm64/arm64e; chứa nhiều chuỗi `prefs.*`, code xử lý HUD BLE và phần setting tạo động. Tweak injection filter bao gồm `com.apple.Preferences`. |

**Đối chiếu hai plist:** chúng không đồng nhất. Một lớp controller thật sự tải `Root`; còn file PreferenceLoader khai báo nhiều hàng hơn và dylib có nhãn cho những trang tạo động. Không có quan sát trực tiếp trên máy nên chưa xác nhận 100% thứ tự/trang cụ thể người dùng nhìn thấy.

Các switch cơ bản đều có `defaults=com.sensetechlab.duodash.settings`; thường được CFPreferences lưu ở domain có đường dẫn dạng `/var/mobile/Library/Preferences/com.sensetechlab.duodash.settings.plist` (đường dẫn dự kiến khi chạy, **không hiện diện dưới dạng dữ liệu người dùng trong DEB**).

## 18 hàng settings trong PreferenceLoader (8 hàng đầu có trong Root.plist)

| Nhóm | Tên hiển thị | Key / thông báo | Công dụng theo dữ liệu gói |
|---|---|---|---|
| HUD Device | Status | `hud_pairing_status` (read-only) | Tình trạng HUD, mặc định `Not paired` |
| HUD Device | Paired | `hud_paired` (OFF); notify `com.sensetechlab.ble.action` | Ghép/hủy ghép HUD Bluetooth với iPhone; theo footer HUD chỉ chấp nhận máy đã ghép |
| HUD Device | Firmware | `hud_firmware_version` (read-only) | Phiên bản firmware của HUD, mặc định `Unknown` |
| Performance | Deep Sleep | `deepsleep_enabled` (OFF); notify `com.sensetechlab.settings.changed` | Tiết kiệm điện/sleep; có chuỗi liên quan `carsleeper`, `sleep_battery`, `sleep_time`, `bt_prior`, `air_prior`; lúc nào thao tác với radio/chế độ ngủ **chưa kiểm chứng runtime** |
| Performance | Optimize CPU And Thermal | `perf_tweak_enabled` (OFF); notify settings.changed | Theo chú thích: giảm frame rate để giảm nóng và giảm quá tải; bản beta, cần kết nối lại sau đổi |
| Performance | Close Unloaded Pane Apps | `pane_unload_close_enabled` (OFF) | Theo chú thích: đóng ứng dụng bị thay thế để tiết kiệm CPU/RAM, có thể dừng nhạc và mất dữ liệu chưa lưu; không truy mã chia ô |
| Performance | Auto Start | `appbridge_autostart` (OFF); notify `com.sensetechlab.autostart.changed` | Tự mở chức năng chính vài giây sau khi kết nối |
| Performance | Close Apps on CarPlay Disconnect | `disconnect_close_enabled` (OFF) | Đóng app sau ngắt kết nối, theo chú thích chờ **khoảng 12 giây** |
| Headunit Info | Resolution | `headunit_resolution` (read-only) | Độ phân giải; mặc định `Unknown` |
| Headunit Info | Recommended video quality | `headunit_video_quality` (read-only) | Đề xuất chất lượng video, không phải switch tự chỉnh video |
| App Bridge | Enable App Bridge | `appbridge_enabled` (OFF); notify settings.changed | Bật cơ chế tích hợp ứng dụng; không điều tra cách trình bày |
| App Bridge | Choose Apps to Bridge | `chooseAppsToBridge:` | Mở picker từ class `DuoDashAppPickerController` |
| App Bridge | Go To CarPlay | `PSLinkCell`, bundle `CarKitSettings` | Đi tới cấu hình CarPlay hệ thống |
| Splash | Splash Screen | `splash_selected`, default `"1"` | `1` Mountain Road, `2` City Skyline, `3` Light Trails, `0` None |
| Tweaks | Tweak Management | action `openTweakManagement:` | Theo nội dung: quản lý tweak đi kèm, beta. **Cần lưu ý:** method **không có** trong 11 method của class `DuoDashRootListController` thuộc bundle; có thể do controller khác hoặc injection xử lý, chưa chứng minh sẽ bấm được |
| Tweaks | DuoDash Status | `duodash_latch_status` (read-only), default `OK` | Tình trạng bảo vệ sau crash, **không phải license status** |
| Tweaks | Re-enable DuoDash Tweaks | `duodash_reenable_tweaks` (OFF), notify `com.sensetechlab.latch.reset` | Chỉ khi có lỗi, reset crash protection và respring; tự tắt switch theo mô tả |
| Language | Language | `duodash_language`, default `en`, notify `com.sensetechlab.language.changed` | 17 ngôn ngữ gồm tiếng Việt (`vi`) |

Tất cả switch ẩn định OFF ở cấu hình tĩnh. `About` là nhóm footer copyright, không có item điều khiển. Mục hiệu năng nhấn mạnh **cảnh báo beta**.

## Nhóm cấu hình được tạo trong `DuoDash.dylib`, ngoài hai plist

Các nhãn/key `prefs.*` nằm trong Mach-O arm64; đây là **bằng chứng về code/nhãn trang**, chưa có ảnh chụp UI thực tế.

**Navigation Bubble:** `Provider`, `Status` (Publishing/Not publishing/Not found), `Auto-start Provider`, `Keep Provider Awake`, `Show on Pane`, `Blink When Over Limit`, `Beep When Over Limit`, `Beep Volume`, `Speed Source` (OBD2 Dongle/Navigation App/GPS), `Speed Correction`, `Fake Test`, `Send Test Payload`, `Last Payload`, `How to Build a Provider`. Nhãn và chú thích runtime cho biết dữ liệu được provider/tweak riêng công bố qua plist + thông báo, tốc độ tính km/h, nên phát heartbeat ít nhất mỗi 5 giây. Không mặc định có dữ liệu tốc độ trực tiếp từ mạng.

**Voice Command:** `Handler`, `Use Steering-Wheel Button`, `Send Test Press`, `How to Build a Handler`. Chú thích nói dùng tweak handler bên ngoài, chuyển sự kiện nút giọng nói từ Siri sang app được chọn; event một chiều, không có ACK.

**Crash Reporter:** `Send Report`, tình trạng `Collecting`, `Packaging`, `Saved on device`, `Saved on device (no server configured)`, `Already sending`, `Failed (no space)`, `Failed (network)`; chú thích có thể gửi logs/crash/device details cho developer. Binary có `NSURLSession`, `NSMutableURLRequest`, nhưng **không phát hiện URL HTTP(S) ASCII rõ ràng** trong dylib.

Ngoài ra binary có code/chuỗi cho `Tweak Management`, `Respring`, danh sách trạng thái HUD và các thao tác BLE.

## Giấy phép và ràng buộc phần cứng: đối chiếu chính xác

1. Đã quét các chuỗi ASCII trong **3 Mach-O arm64**: `Applications/DuoDash.app/DuoDash` (69.104 bytes/arch), `PreferenceBundles/DuoDashPrefs.bundle/DuoDashPrefs` (71.696 bytes/arm64), `TweakInject/DuoDash.dylib` (960.256 bytes/arm64); đồng thời đọc cả hai plist và script `postinst`/`prerm`.
2. **Không thấy** mục hay nhãn software license trong plist: `License`, `Activation`, `Subscription`, `Trial`, `Purchase`, `Renew`, `Gift Code`, `VIP` hoặc ngày sử dụng. Bộ quét không thấy literal license/subscription/trial/payment/receipt tương ứng trong ba Mach-O. Một vài chuỗi `activate`, `activationRequest` thuộc Siri/voice hoặc state chung; `applyExpiry`, `_expiryTimer` không đủ để coi là kiểm tra license.
3. Có **ràng buộc ghép thiết bị HUD**: khóa `hud_paired`, `hud_paired_uuid`, `hud_paired_uuid_sha256`; BLE CoreBluetooth UUID/service/characteristic và import `_CC_SHA256`, event `com.sensetechlab.ble.action`. Chú thích hãng nói HUD ghép một iPhone, muốn đổi máy phải unpair. Đây là **pairing phần cứng**, không có bằng chứng là khóa giấy phép phần mềm/thời hạn.
4. `cydia::commercial` ở metadata cho biết cách gắn nhãn gói thương mại, **không chứng minh** có code kiểm tra thời gian/thuê bao.
5. **Giới hạn:** Không tìm thấy literal hoặc UI không chứng minh software license hoàn toàn vắng mặt. Có thể có dữ liệu mã hóa, URL tạo động, server/receipt ngoài gói; cần call graph đầy đủ và quan sát runtime nếu muốn khẳng định tuyệt đối. Không kết luận “không có giấy phép” như một sự thật đã test.

**So với DuoFace `0.1.0~native12`:** audit repo DuoFace đã chứng minh các class/selector và metadata license di sản còn trong host Mach-O, mặc dù 312 thân hàm đã vô hiệu hóa và 52 literal contents/2 file hook đã xóa. Trong DuoDash 1.1.3 này **chưa phát hiện hệ thống license phần mềm tương ứng**; không được đồng nhất HUD BLE pairing với hạn dùng DuoFace.

## Tính tái hiện / Bàn giao

```sh
# Chỉ chạy trên bản DEB người dùng đã cung cấp, không cài thực thi tweak
sha256sum com.sensetechlab.duodash_1.1.3_iphoneos-arm64.deb
dpkg-deb -e com.sensetechlab.duodash_1.1.3_iphoneos-arm64.deb /mnt/data/duodash_audit_113/control
dpkg-deb -x com.sensetechlab.duodash_1.1.3_iphoneos-arm64.deb /mnt/data/duodash_audit_113/root
python /mnt/data/duodash_audit_113/audit_static.py
llvm-objdump --macho --arch=arm64 --objc-meta-data /mnt/data/duodash_audit_113/root/var/jb/Library/PreferenceBundles/DuoDashPrefs.bundle/DuoDashPrefs
llvm-objdump --macho --arch=arm64 --disassemble /mnt/data/duodash_audit_113/root/var/jb/Library/PreferenceBundles/DuoDashPrefs.bundle/DuoDashPrefs
```

Local runtime evidence: `/mnt/data/duodash_audit_113/audit_static.py`, `audit_report.json` (bao gồm string offsets), `tweak_objc_arm64.txt`, `prefs_objc_arm64.txt`, `tweak_disasm_arm64.txt`, file rootless extracted (chỉ tồn tại trong môi trường thực thi chat, **không tự xem là đã upload GitHub**). Tiếp theo nếu người dùng muốn: trace thực tế runtime cài đặt/giấy phép riêng, không truy các tính năng chia ô hay UI, và không sửa DEB DuoFace khi chưa yêu cầu.
