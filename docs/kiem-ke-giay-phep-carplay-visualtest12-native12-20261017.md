# Kiểm kê giấy phép lẫn với CarPlay — VisualTest12 và Native12 + Hub8 (17/10/2026)

**Loại báo cáo:** Chỉ đọc audit tĩnh đã lưu và danh sách nội dung DEB; KHÔNG khẳng định đã tách sạch hay đã khôi phục trên iPhone X. Báo cáo tải về trong lượt chat: `duoface_kiem_ke_giay_phep_carplay_2026-10-17.md` (bản diễn giải chi tiết). File này là checkpoint GitHub để các cuộc chat khác tiếp nối.

**Kết luận phân loại theo FILE: 2 tệp lõi còn đan xen.** Đây là hai đường dẫn trong *mỗi* gói VisualTest12 và Native12+Hub8, không phải tổng số classes hoặc tất cả file có tham chiếu `CB*`.

| Đường dẫn file trong DEB | VisualTest12 (B) | Native12+Hub8 (B) | Ranh giới chưa chứng minh tách an toàn |
|---|---:|---:|---|
| `/var/jb/Applications/DuoFaceUI.app/DuoFaceUI` | 2.456.784 | 1.220.256 | UI + sync/trial/modal/activation UI + 4 implementation phát hiện CarPlay trong `CBLicenseSyncManager` |
| `/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib` | 7.540.464 | 3.760.032 | `CBBridgeManager` chứa cả quản lý window/split/scene/picker và 7 phương thức license warning/watchdog; `CBLicenseSyncManager` chứa 4 detector CarPlay khác; `CBBridgeManagerDashboard` quyết định activation/policy |

### Bên trong `DuoFaceUI` chưa tách

- **VisualTest12:** 13 lớp tên/nhóm giấy phép nhúng trực tiếp trong cùng Mach-O (bao gồm `CBSubscriptionViewController` — 71 phương thức; `CBLicenseExpiredModalViewController` — 30; `CBLicenseSyncManager` — 30; nhiều VIP/giftcode/checkout/status cells). **13 lớp không phải 13 file.**
- `XXRootViewController -checkAndPresentLicenseModalIfNeeded` có tham chiếu trực tiếp đến `CBSubscriptionViewController` và `CBLicenseExpiredModalViewController`; `CBGeneralSettingsViewController -openSubscriptionScreen` nằm cạnh các luồng settings khác.
- Trong `CBLicenseSyncManager` vẫn có `isCarPlayScreenConnected`, `isCarPlayScreen:`, `isCarPlayScreenConnectedExcludingScreen:` (4 implementation gồm class/instance). **Không thể loại class nguyên khối chỉ căn cứ vào tên License.**
- Liveness/call graph qua ObjC dynamic dispatch, classrefs/selrefs và lifecycle chưa giải xong; chưa chứng minh chức năng ứng dụng vẫn hoạt động khi loại các lớp này.

### Bên trong `DuoFaceDashboard.dylib` chưa tách

- `CBBridgeManager` có 75 phương thức (báo cáo audit bản gốc); 16 phương thức host chọn lọc liên quan split/app/picker/state/window trong `LICENSE_BOUNDARY_AUDIT.json`.
- **7 phương thức giấy phép trong cùng `CBBridgeManager`:** `presentLicenseWarningModalWithType:`, `dismissLicenseWarningModal`, `startLicenseWatchdogTimer`, `stopLicenseWatchdogTimer`, `licenseWatchdogTimerFired:`, `licenseWarningModal`, `setLicenseWarningModal:`.
- **3 lớp tên/nhóm giấy phép** trong Dashboard VisualTest12: `CBLicenseSyncManager` (30 phương thức), `CBLicenseShieldIconView` (2), `CBLicenseWarningModalView` (12). Có **4 implementation detector CarPlay** khác trong `CBLicenseSyncManager`.
- `CBBridgedSplitApp` (49 phương thức), picker/overlay (66 phương thức), `CBBridgeManagerDashboard` activation/policy nằm trong hệ host cũ và liên kết qua callback/dispatch chưa được chứng minh độc lập. **Chưa chứng minh chính xác branch nào chặn activation trên iPhone X hết trial.**

### Các nhóm KHÔNG được đánh đồng với hai file lõi

1. `/var/mobile/Library/Preferences/com.duonavi.sync.plist`: **có trong DEB VisualTest12 repair1**, là dữ liệu đồng bộ/hạn dùng; không phải executable tạo scene. **Không xuất hiện trong manifest payload Native12 Speed8**, không có nghĩa dữ liệu cũ trên máy đã biến mất.
2. `DFVisual12GateRepair.dylib` và filter: tweak thử riêng trong VisualTest12 repair1, thay trạng thái/giá trị ngày VIP hiển thị; trên thiết bị **vẫn khóa CarPlay**. Không phải lõi scene độc lập.
3. `A_DuoFaceNativeNoLease.dylib/.plist` **đã bị xóa khỏi gói Native12**, đúng 2 file/92.815 bytes; nhưng giấy phép trong `DuoFaceUI` và `DuoFaceDashboard.dylib` chưa được chứng minh tách.
4. `DuoFaceFullscreenBridge.dylib`, `DuoFaceVisualHook.dylib`, `DuoFaceLogoGripOnly.dylib`, `DuoFaceSpeedHUD.dylib`, `DuoFaceSpeedOwner.dylib`: **phụ thuộc các class/window CarPlay hoặc host**; không có kết luận bằng chứng rằng bản thân chúng kiểm trial. Speed8 chờ `CBWindow`; thiếu window là triệu chứng hậu quả.
5. Logo/picker PNG, app icons, `Info.plist`, filter .plist khác: không được tính như phần license logic khi không có chứng cứ.

### Giải thích con số audit Native12 (đừng nhầm phạm vi)

- Audit ngày 16/10 có **14 ứng viên lớp/249 phương thức** (12 lớp/235 phương thức trong UI, 2 lớp/14 phương thức trong Dashboard) để nghiên cứu loại nội dung giấy phép. **Đây là inventory candidates, chưa xóa thành công, chưa chứng minh class không còn được gọi.**
- Loại trừ khỏi tập này các chủ sở hữu *vừa liên quan giấy phép vừa dùng cho CarPlay* gồm `XXRootViewController`, `CBGeneralSettingsViewController`, `CBLicenseSyncManager`, `CBBridgeManager`. **Các điểm trộn thực sự nằm ở ranh giới này.**
- Có **8 implementation phát hiện CarPlay** trong `CBLicenseSyncManager` của 2 binaries, các audit xác nhận đã giữ nguyên byte qua một số build. Không có phép suy ra xóa nguyên class là an toàn.
- Báo cáo `LICENSE_BOUNDARY_AUDIT.json` tự ghi `license_subsystem_separable_by_file=false`, `dynamic_dispatch_fully_resolved=false`, `independent_release_ready=false`.

### Những việc hiện vẫn chưa thể xác nhận/tách hoàn chỉnh

- Dynamic call graph và tương quan giữa license-status/watchdog, `CBBridgeManager`, `CBBridgeManagerDashboard`, `CBWindow` và scene activation trên iPhone X.
- Các tham chiếu class/selector ở Mach-O đã ký (ObjC metadata, classref/superref, dyld fixups) sau khi loại lớp; **xóa chuỗi/đổi package ID** không giải quyết runtime contract.
- Khả năng nối **giao diện Visual12 nguyên bản** với engine `DFIRuntime`/facade mà không dùng `DFIInterface.inc` alpha. CI đã build engine nhưng thiết bị chưa chứng minh 1/2 app thực chạy độc lập.
- Giải pháp chưa được kiểm chứng chạy với trial hết hạn; **cả VisualTest12 và Native12+Hub8 kế thừa DuoNavi đều bị khóa trên iPhone X** theo người thử.

### Hướng nghiên cứu tiếp nối (không sửa gói đang dùng)

1. Khoá baseline VisualTest12 + Native12 Speed8 và SHA, không đổi UI/fullscreen/Hub8; chọn VisualTest12 làm đối tượng nghiên cứu trước.
2. Dùng dữ liệu Objective-C và logs hiện có để xác minh **UI -> host** và **license -> activation** bằng sơ đồ selector/callsite, phân biệt direct xrefs với dispatch động.
3. Kiểm chứng khả năng dùng scene host độc lập trong môi trường được phép, mỗi lần một app trước, rồi hai app, không xung đột owner; không gọi CI/Sileo success là test CarPlay.
4. Chỉ cân nhắc adapter UI chính khi host chứng minh hoạt động; nếu renderer bên thứ ba không được phép sử dụng ngoài giấy phép hiện tại, phải chọn hướng có quyền sử dụng hợp lệ hoặc phương án nguồn tự kiểm soát.

### Bằng chứng GitHub đã đọc (chung nhánh `feature/visual12-duodash-recovery`)

- `dist/visualtest12-repair1/{CONTENTS.txt,BAO_CAO.json}`
- `dist/payload-migration/native12-speed8compact/{CONTENTS.txt,BAO_CAO.json}`
- `audit/payload-migration/{LICENSE_BOUNDARY_AUDIT.json,VISUALTEST12_ACTUAL_LICENSE_BOUNDARY.json,VISUALTEST12_CLASSREFS_READONLY.json,VISUALTEST12_NATIVE12_BYTE_LINEAGE.json}`
- `audit/payload-migration/{NATIVE12_ACTUAL_LICENSE_CLASS_XREFS.json,NATIVE12_LICENSE_XREF_CALLSITE_OWNERS.json,NATIVE12_LICENSE_ACTIVATION_GATE_READONLY.json,NATIVE12_WHOLE_LEASE_PLUGIN_REMOVAL_REGRESSION.json}`
- `audit/payload-migration/native12-license-excision-candidate-map-20261016.json`
- `audit/payload-migration/VISUALTEST12_HISTORICAL_CORE_SOURCES.json`

**Trạng thái:** Báo cáo đọc-only. Chưa chỉnh binary, build DEB, update Sileo, thử trên thiết bị trong lượt kiểm kê. Không được mô tả việc loại trial bằng phương pháp bypass entitlement của nhị phân bên thứ ba như việc đã hoàn tất.
