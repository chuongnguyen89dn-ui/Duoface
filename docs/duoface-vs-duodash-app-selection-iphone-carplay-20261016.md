# Đối chiếu CƠ CHẾ CHỌN APP: DuoDash 1.1.3 và DuoFace native12

**Ngày:** 16/10/2026 (Asia/Ho_Chi_Minh). **Trạng thái:** Tìm nguồn/đối chiếu, không thay mã hay DEB. **Yêu cầu:** Người dùng xác nhận DuoFace **thêm/đưa app vào danh sách từ app trên iPhone, không thêm được ứng dụng mới trực tiếp trên màn hình CarPlay** và hỏi DuoDash khác thế nào. Đây là thông tin runtime từ người dùng, được ưu tiên hơn suy diễn dựa trên tên một selector.

## Kết luận phân biệt HAI thao tác không được nhập làm một

1. **Quản lý ứng dụng được phép chạy / thêm app MỚI vào thư viện bridge**: chọn từ **danh sách app cài trên iPhone**, đánh dấu vào các app muốn phép xuất hiện.
2. **Chọn/chuyển app để hiển thị ngay trên xe**: duyệt **ứng dụng đã thêm** vào thư viện, nhấn icon cho hiện lên giao diện CarPlay. Không đồng nghĩa đã thêm app mới trực tiếp từ CarPlay.

| Mục | DuoFace native12 | DuoDash 1.1.3 |
|---|---|---|
| Đưa ứng dụng mới từ iPhone vào danh sách | **Có, người dùng xác nhận làm trong app DuoFace trên iPhone**; `CBDashboardSettings.bridgedApps` / `setBridgedApps:`. | **Có, App Bridge → Choose Apps to Bridge trên iPhone**; bảng `DuoDashAppPickerController`, `_readBridged`, `_enumerateApps`, `_persistAndNotify`. |
| Đổi ứng dụng đang chạy ngay trên màn hình xe | DuoFace có menu App và picker, đổi từ tập app đã cấu hình. | DuoDash có bộ chọn app **ngay trên CarPlay**; chuyển pane và bấm icon từ danh sách `My Apps`. |
| Thêm một ứng dụng CHƯA được cấu hình, hoàn toàn từ màn hình CarPlay | **User nói native12 hiện không làm được**. Có `CBMultitaskingOverlayView.addMoreAppsTapped:` và tile `Thêm App` / `…` trong binary/UI source, nhưng **không đủ chứng minh đã thêm thẳng ứng dụng vào `bridgedApps` và persist/sync**; phải truy handler thực tế trước. | **Chưa có bằng chứng có thể thêm MỚI từ CarPlay**. Theo tài liệu hãng, `My Apps/System Apps` được quản lý trong **DuoDash iPhone settings**, và in-car picker **chỉ hiện My Apps**. Không nhầm việc chọn app đã thuộc My Apps với add-to-bridge. |
| Nhóm ứng dụng | DuoFace hiện có selection/bridge app; chưa có UX My Apps/System Apps tương tự chứng minh. | `My Apps` và `System Apps`; chuyển nhóm bằng vuốt dòng trong iPhone Settings, app My Apps là nguồn cấp in-car picker. |
| Cập nhật danh sách không restart | Chưa QA hot-refresh native12 sau khi thay lựa chọn trong app iPhone. | Website chính thức tuyên bố add/remove app không cần restart DuoDash. |
| Icon app ở CarPlay Home | DuoFace có bridge/menu theo cài đặt gốc, vị trí/đường add Home screen chưa QA riêng. | DuoDash App Bridge có công tắc `appbridge_enabled`; app đã đánh dấu có thể xuất hiện như icon trên CarPlay Home. |

## Nguồn DuoDash chính xác

**Website nhà phát triển SenseTechLab, tiếng Việt:** `https://sensetechlab.com/vi/duodash/features/` (các mục `App Picker` và `App Bridge`, truy cập ngày 16/10/2026). Theo mô tả: app picker nằm đè lên ô màn hình xe, icon theo trang; `App Bridge` bật rồi chọn app muốn, app thành icon màn hình chính; có `My Apps` / `System Apps`; in-car app picker hiện **My Apps**; ảnh “Bridge Apps” đặt trong **iPhone settings**. Không có mô tả về thao tác add CHƯA cấu hình trực tiếp từ CarPlay.

**DEB user upload**, checksum `16ffab22b4246dea9978cae92df7ec635d833ec067b4d9f425a231b26edec601`:
- `var/jb/Library/PreferenceLoader/Preferences/DuoDashPrefs.plist` `App Bridge`: `appbridge_enabled` key PSSwitchCell + action `chooseAppsToBridge:` của PSButtonCell. `Root.plist` riêng là bản rút gọn không có App Bridge.
- `var/jb/Library/PreferenceBundles/DuoDashPrefs.bundle/DuoDashPrefs` ObjC metadata: `DuoDashRootListController.chooseAppsToBridge:` `0x41cc`; `DuoDashAppPickerController` UITableViewController có `_readBridged` IMP `0x496c`, `_persistAndNotify` `0x4b0c`, `_enumerateApps` `0x4bb4`, methods table datasource. Ngoài ra có chuỗi `Selected apps appear on the CarPlay home screen`.
- `var/jb/usr/lib/TweakInject/DuoDash.dylib` arm64 chứa `CNABAppPickerController`, `My Apps`, `System Apps`, `Only My Apps appear in the in-car picker`, `appbridge_app_sections`, `com.sensetechlab.appbridge.listchanged`, `plus.circle.fill`/`minus.circle.fill`. Cơ chế iPhone prefs và in-car runtime là hai tầng khác nhau; có tên button +/− không chứng minh +/− trên màn hình xe.
- Local read-only extraction đã chạy:
```sh
dpkg-deb -x /mnt/data/com.sensetechlab.duodash_1.1.3_iphoneos-arm64.deb /mnt/data/duodash_audit_113/root
# Extract first FAT arm64 slice per file, offsets 16384; prefs arm64 size 71696, tweak arm64 size 960256.
llvm-objdump --macho --objc-meta-data /mnt/data/duodash_audit_113/prefs_arm64.bin > /mnt/data/duodash_audit_113/prefs_objc.txt
strings -a /mnt/data/duodash_audit_113/tweak_arm64.bin | grep -i -E 'CNABAppPickerController|My Apps|System Apps|in-car picker|appbridge_app_sections'
```
These extracted files are **temporary and not uploaded**; key binary facts/offsets and commands are reproduced here for durable investigation. No execution of installed DuoDash.

## Nguồn DuoFace

- `main:docs/duoface-v12-picker-focus-audit-20261015.md`, blob `d8a95437aee5420cfa18e03c6f7220b37a665885`, CI run `38662510504`: `CBMultitaskingOverlayView.setupAppPickerCardsInCardW:cardH:contentY:` IMP `0xa3e5c`; tile `Thêm App` (key `OVERLAY_ADD_APP`, UTF-16LE source label), action `addMoreAppsTapped:` referenced at `0xa57ac`. Subsequent visual-only tweak đổi icon plus→ellipsis không phải bằng chứng chức năng add đã được triển khai trên native12.
- `feature:audit/payload-migration/NATIVE12_CONNECTION_FULL_OWNERS_READONLY.json` blob `6697155ebe8f6749c7b240aa065baa8044522016`: `CBDashboardSettings.bridgedApps`, `setBridgedApps:`, `CBBridgeManager.runningBridgedApplications`. `main:docs/duoface-picker-running-state-audit-20261015.md` blob `a67d56c32e73195b3b14d59a43448bc56630539c`: state apps bridge vs active slot / pid là độc lập.
- **Người dùng đã xác nhận thực tế rằng việc add app mới vào DuoFace đang yêu cầu thao tác trên iPhone**, nên không nhận tile “Thêm App” là tính năng add từ CarPlay đã chạy.

## Khuyến nghị cho nhóm 2 — CHƯA có phê duyệt lập trình

**Khác biệt lớn đáng làm hơn DuoDash**: Trên CarPlay, dùng **đúng nút/ô `Thêm App` / `…` đang tồn tại của DuoFace**, mở danh sách ứng dụng iPhone đã cài **chưa thuộc bridgedApps**, cho thêm tại chỗ và tự cập nhật cùng danh sách iPhone; sau đó cho chọn app mới vừa thêm ngay trong menu. Không cần tạo một hệ thống picker thứ hai. Cần bảo toàn tất cả App/Zoom/Style/Close, nút Close, logo, màu, cử chỉ và native callback đã có.

**Thứ tự làm khi user đồng ý**:
1. Audit read-only `CBMultitaskingOverlayView.addMoreAppsTapped:` và mạch `CBDashboardSettings.bridgedApps` / `setBridgedApps:`, quá trình app iPhone cập nhật danh sách, hot-refresh và API enumerate installed apps, đúng ABI/owner/IPC process.
2. Dựa trên callback sẵn có, bổ sung flow cho phép **thêm app mới trực tiếp trên CarPlay**, cập nhật data + UI atomically, app add success/error/rollback. Không tự ý hiển thị tất cả app hệ thống hoặc mở app chưa cho phép.
3. Compile-only CI và test static, không đóng DEB/Sileo nếu user chưa giao; QA on device sau candidate.

**Trạng thái lượt này:** Chỉ đối chiếu và lưu báo cáo; native12 và source branch không thay đổi. Nhóm 1 source đã CI PASS nhưng chưa cài/QA on-device; license-removal và điều tra YouTube/Android vẫn PAUSED.
