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


## 2026-10-18 — CHECK_DIAGRAM_GATE_20261018: xác minh sơ đồ GP/CP và lý do getter VIP không mở CarPlay

**Mục tiêu:** Kiểm chứng sơ đồ do người dùng đưa ra, bao gồm các class GP, CP, phần đan xen và bản VisualTest12 repair1. Đây là **audit chỉ đọc**, KHÔNG chứng minh sửa được thiết bị và KHÔNG thay đổi binary.

### Bằng chứng đối chiếu

1. **Sơ đồ theo hai Mach-O là đúng ở mức inventory:** `DuoFaceUI.app/DuoFaceUI` có `CBLicenseSyncManager`, controller VIP/subscription/expiry và `XXRootViewController.checkAndPresentLicenseModalIfNeeded`; `DuoFaceDashboard.dylib` có `CBBridgeManager` (75 methods), picker, split, scene và `CBBridgeManagerDashboard`. Nhưng nhãn GP/CP không thể là bằng chứng một class có thể bị xóa nguyên khối; `CBLicenseSyncManager` còn 4 implementation CarPlay screen detection trong **mỗi** Mach-O (tổng 8). Các lớp phụ trợ Fullscreen/VisualHook/Grip/SpeedHUD chỉ **chưa phát hiện trực tiếp cơ chế hạn dùng trong audit**, không phải chứng nhận vĩnh viễn "không chứa license".
2. **Repair1 chỉ thay ba *instance getter*** ở `runtime/visualtest12/DFVisual12GateRepair.m`: `isLicenseCurrentlyValid` => `YES`, `remainingLicenseSeconds` => 3650 ngày, `actualLicenseExpirationTimestamp` => now+3650 ngày. `DFVisual12GateRepair.plist` lọc `SpringBoard`, `CarPlayApp`, `DuoFaceUI`, `com.duonavi.app`, nhưng cài hook **có điều kiện**: đúng process, class `CBLicenseSyncManager` đã load, `MSHookMessageEx` tồn tại, cả ba ABI instance khớp. Không có log chứng minh hook thành công ở **mọi** process; hiện VIP thay đổi chỉ chứng minh một luồng hiển thị đã đổi. Không có hook `CBBridgeManagerDashboard`, `CBWindow`, `requestActivation:` hoặc scene owner. `dist/visualtest12-repair1/BAO_CAO.json` xác nhận toàn bộ host/scene/lifecycle cũ byte-identical, chỉ thêm 2 file hook + sửa control.
3. **Native12 thậm chí đã có một số stub giấy phép trong 2 core Mach-O**, không phải chỉ do Repair1: `audit/payload-migration/NATIVE12_LICENSE_ACTIVATION_GATE_READONLY.json` ghi `DuoFaceUI CBLicenseSyncManager.-isLicenseCurrentlyValid` VM `0x10005a7c0` bắt đầu `mov w0,#1; ret`, `DuoFaceDashboard` VM `0x3adb8` cũng trả `BOOL YES`; `remainingLicenseSeconds` và `actualLicenseExpirationTimestamp` dạng fixed constant. `DuoFaceDashboard CBLicenseSyncManager.-checkAndSyncLicenseIfNeeded` VM `0x5fbac` bắt đầu `ret`. Dẫu vậy **iPhone X vẫn không mở được Native12** theo người dùng. Không thể từ đó suy ra licensing hoàn toàn không còn, cũng không thể quy lỗi tất cả cho license.
4. **Đường gọi thật có đan xen:** Trong cùng báo cáo, `DuoFaceDashboard CBBridgeManager.-requestStateChange:` VM `0x13b158` có selector `checkAndSyncLicenseIfNeeded` (xref instruction khoảng `0x13b1f8`), tiếp theo `isDisplayValid`, `isVisible`, `window`, `deactivateCurrentApp`, `loadNewAppFromCurrentRequest:`. Vì audit mới có disassembly tĩnh và dynamic dispatch chưa giải, **không xác định** hàm sync quyết định activate hay chỉ là side-effect.
5. **Policy/activation là cổng khác, chưa nằm trong ba getter:** `CBBridgeManagerDashboard.+isDashboardPolicySignalActive` VM `0x284068`, `+shouldInterceptLaunchForApp:` VM `0x2a314c`, `-requestActivation:` VM `0x2a3ad0` đều có thân ARM64 không-trivial, chưa được chứng minh là proxy trực tiếp của `CBLicenseSyncManager.isLicenseCurrentlyValid`. Kết quả đọc-only DIAG3 được ghi trong `NATIVE12_LICENSE_ACTIVATION_GATE_READONLY.json`: 27 lần policy=false, 8 yêu cầu mở app không chính thức bị intercept, windowCreated=false. **Đây là quan sát, không phải xác minh nguyên nhân**: `license_expiry_cause_proven=false` và `static_direct_call_graph_fully_resolved=false`.
6. `DFDuoDashActivationTrace.m` là một tracer giữ original IMP: thu `CBBridgeManagerDashboard requestActivation:/startBridging:/prepareAndRequestActivation:/bridgeDidActivate:` và `CBBridgeManager requestStateChange:/loadNewAppFromCurrentRequest:/handleCarPlayConnectionChanged:`; ghi `bridge_activated`, `dashboard_policy_active`, `external_display_count`, `duoface_window_class_present` theo process vào `/var/mobile/Documents/DuoFaceDuoDashTrace/{SpringBoard,CarPlayApp,DuoFaceUI}.jsonl`. Chưa thấy dữ liệu probe này trong audit đã đọc chứng minh khác biệt ở đúng event/thiết bị.

### Phân loại kết luận

- **Đã xác minh:** sơ đồ nhóm class theo file; getter Repair1 giới hạn 3 instance methods; Native12 có stub validity/sync; policy/activation vẫn nằm trong code khác; chưa có runtime device pass.
- **Giả thuyết cần kiểm:** policy=false có thể là một điều kiện không cấp scene/window, nhưng cũng có thể là dấu hiệu một lỗi khác (owner, display, khởi tạo, injection, session). Chưa có bằng chứng để khẳng định đồng nhất policy=false với trial expired.
- **Chưa chứng minh:** xóa `CBLicenseSyncManager` hoặc `CBBridgeManager` vẫn giữ CarPlay; thay 3 getter mở được session; bản gốc còn quyền sử dụng renderer độc lập; cách nhị phân can thiệp an toàn cho mọi thiết bị.
- **Bước có thể thực hiện tiếp (chỉ đọc):** lập timeline theo cùng session: CarPlay display connected → `requestActivation:`/policy → `CBBridgeManager.activated` → `CBWindow.createWindows/show` → `CBBridgedUIAppView` scene attached, đối chiếu iPhone X và iPhone 8 Plus nếu có log cùng phiên bản, kèm nguồn, giờ và bundle. Kiểm tra mismatch process của Repair1, quá trình đăng ký original hooks và crash/exitMode tách riêng; không đoán bằng VIP hiển thị.
- **Hướng kiến trúc:** ưu tiên nghiên cứu ranh giới giữ UI Native12 nếu có quyền sử dụng mã gốc hoặc API được phép; không copy/link runtime độc quyền hay vô hiệu hóa license có hiệu lực bằng một bản vá đoán mò. Chưa tự ý chuyển nhánh, build, chỉnh gói ổn định hoặc cập nhật Sileo.

### Tệp nguồn kiểm chứng

- `runtime/visualtest12/DFVisual12GateRepair.{m,plist}`
- `runtime/visualtest12/DFDuoDashActivationTrace.m`
- `dist/visualtest12-repair1/{BAO_CAO.json,CONTENTS.txt}`
- `audit/payload-migration/{NATIVE12_LICENSE_ACTIVATION_GATE_READONLY.json,LICENSE_BOUNDARY_AUDIT.json,VISUALTEST12_ACTUAL_LICENSE_BOUNDARY.json,NATIVE12_LICENSE_CLASSREF_CODE_XREFS.json,NATIVE12_LICENSE_XREF_CALLSITE_OWNERS.json}`
- GitHub baseline: `feature/visual12-duodash-recovery` at `8e77499ed5b49c8337742393e5e751f9549caf8a`; đọc tài liệu ZIP skills từ Gpt-training- qua `DEB_IPA_SKILL.md` fallback text do công cụ không giải được ZIP trực tiếp.
