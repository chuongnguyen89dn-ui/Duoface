# DuoFace Settings Pro — Nhóm 1: Kết nối thông minh (đối chiếu DuoDash 1.1.3, native12)

**Ngày:** 16/10/2026 · **Trạng thái:** Phân tích và thiết kế, **chưa triển khai mã, chưa build DEB**.  
**Mục tiêu:** Giữ nguyên thiết kế hoạt động DuoFace native12, kế thừa tính năng Auto Start đang có, sử dụng các ý tưởng phù hợp từ DuoDash, làm tốt hơn về ổn định, khôi phục phiên, chính sách khi ngắt kết nối và khả năng quan sát. Không sao chép binary/assets/code/giao diện DuoDash.

## Nguồn và mốc khôi phục

- Repo: `chuongnguyen89dn-ui/Duoface`; bản cài đã được user báo hoạt động tốt: `com.duoface.independent` `0.1.0~native12`, SHA256 `85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7`, source branch `feature/duoface-exact-payload-migration` HEAD lúc đọc `55e7d33cf7d998df25bd5491cfa29ac57fb7d667`.
- Handoff cả hai: `main:tiep tuc du an.md` (blob `9722ea67f3a3ebfe2a9b8cb1f35f57374368fa5b`) và `main:ban giao du an duoface moi.md`; plan 8 nhóm/30 tính năng `docs/duoface-settings-pro-hop-nhat-duodash-20261016.md` + `audit/duodash-1.1.3/duoface-settings-pro-feature-manifest.json`.
- DuoDash quét từ DEB đã cung cấp: `main:audit/duodash-1.1.3/settings_license_static_audit.md` và `main:audit/duodash-1.1.3/doi-chieu-cai-dat-duodash-vs-duoface-native12-20261016.md`. **DuoDash chưa được quan sát runtime**; nhãn trong plist không đủ chứng minh hành vi kết nối từng trường hợp.
- DuoFace method proof: `feature:audit/payload-migration/ORIGINAL_SETTINGS_OBJC_METHODS.json` blob `cf680223058787664e83e20a6b3815590f91f6cf`, `feature:dist/payload-migration/native4/BAO_CAO.json` và `feature:dist/payload-migration/native12/BAO_CAO.json`. Settings host Mach-O không có source toàn phần; không khẳng định execution flow đã được chứng minh chỉ bằng selector.
- Docs Apple đối chiếu khả năng: `https://developer.apple.com/documentation/carplay/cptemplateapplicationscenedelegate/`, `https://developer.apple.com/documentation/uikit/uiscenedelegate`, `https://developer.apple.com/documentation/uikit/uiscreen/didconnectnotification`. iOS cũ có UIScreen notifications nhưng Apple đã deprecate và nói *không phát sự kiện connect cho màn đã gắn từ trước khi app start*. **Không mặc định DuoFace hook được CPTemplate scene**: cần xác minh host SpringBoard/Dashboard thực nhận sự kiện nào.

## 1. DuoDash 1.1.3 thực sự cho người dùng cấu hình gì?

| Mục / lưu key tĩnh | Hành vi mô tả trong DEB | Ràng buộc bằng chứng |
|---|---|---|
| `Auto Start` — `appbridge_autostart` default OFF, Darwin notification `com.sensetechlab.autostart.changed` | Tự mở chức năng DuoDash sau khi kết nối với màn hình | Chỉ thấy plist/description, chưa định lượng delay hay xác nhận hoạt động trên thiết bị |
| `Close Apps on CarPlay Disconnect` — `disconnect_close_enabled` default OFF | Đóng các app sau khi ngắt CarPlay; ghi chú khoảng chờ **12 giây** | Chưa xác minh timer thực và app được đóng cụ thể |
| `Enable App Bridge` — `appbridge_enabled`, `com.sensetechlab.settings.changed` | Bật/tắt cơ chế bridge | Không suy ra iOS process thật sự được mở/đóng thế nào |
| `Choose Apps to Bridge` — `chooseAppsToBridge:` | Chọn app dùng với DuoDash | Có controller/picker trong binary prefs, không mượn cấu trúc của họ |
| `Headunit Resolution` — `headunit_resolution` | Hiện độ phân giải màn hình, chỉ đọc | Không phải cấu hình thiết bị riêng |
| `Deep Sleep` — `deepsleep_enabled` | Ngủ/tiết kiệm điện, có chuỗi `carsleeper`, `sleep_time`, `bt_prior`, `air_prior` | Chưa chứng minh radio thực bị điều khiển; **không gộp vào kết nối vì dễ làm mất CarPlay** |
| `HUD Paired` | Ghép HUD Bluetooth theo phần cứng riêng | **Không đồng nhất với ghép CarPlay**; không đưa vào nhóm này nếu không có phần cứng |

**Chưa thấy từ bằng chứng tĩnh DuoDash:** chế độ nhớ và phục hồi đúng phiên app khi mất mạng/kết nối; chống trigger Auto Start lặp; cấu hình khác nhau theo từng xe; nhật ký nguyên nhân lỗi reconnect; rollback phiên. Đây là khoảng trống thiết kế để DuoFace làm mạnh hơn, **không phải tuyên bố DuoDash chắc chắn không có code ẩn**.

## 2. DuoFace native12 đang có gì?

| Thành phần | Bằng chứng thực tế | Kết luận |
|---|---|---|
| Cài đặt **Tự Động Mở Khi Kết Nối** trong app iPhone | Ảnh người dùng đã xác nhận trong `tiep tuc du an.md` (11/10); `CBGeneralSettingsViewController.autoLaunchOnConnect`, `autoLaunchToggleChanged:`, `setAutoLaunchOnConnect:`, `loadPreferences`, `savePreferences` | Có UI và phương thức, **chưa QA lại ON/OFF với native12 từng lần** |
| Preference / runtime Auto Launch | `CBDashboardSettings.autoLaunchOnConnect`, `setAutoLaunchOnConnect:`, `autoLaunchBundleID`, `setAutoLaunchBundleID:` | Có chỗ lưu trạng thái/tên app mục tiêu; **chưa chứng minh trên native12 trình tự tự chạy app** |
| Chọn app và lưu vị trí | `CBDashboardSettings.bridgedApps`, `appSettings`, `splitApp1..4`, `splitLeftBundleID`, `splitRightBundleID`, `splitRatio`; picker hiện tại user đã thử | Có mô hình thông tin ứng dụng/bố cục; **chưa đủ chứng cứ snapshot được ghi khi disconnect hay tự restore phiên** |
| Phát hiện màn CarPlay | 8 methods gồm `CBLicenseSyncManager.isCarPlayScreenConnected`, `isCarPlayScreen:`, `isCarPlayScreenConnectedExcludingScreen:` (trong 2 host binary). Native12 audit đã bảo vệ SHA8/8 | Những methods phải giữ hành vi hiện tại, không lấy tên chứa License để xóa, không tái kích hoạt workstream license |
| Theo dõi trạng thái bridge/app | Hồ sơ `tiep tuc du an.md`: `CBBridgeManagerDashboard.handleStateDict:` đọc `activated` + `bundleIdentifier`, gọi `bridgeDidActivate:`/`bridgeDidDeactivate:`. `CBBridgeManager` sở hữu window và app phía SpringBoard | Có trạng thái ứng dụng active/inactive để làm chỗ tham chiếu; **không nhầm với sự kiện cắm/rút vật lý CarPlay** |
| Đóng một ứng dụng xác định | Hồ sơ cũ có `terminateApplicationWithBundleID:`, `closeSingleAppTapped:`, `terminateAllBridgedApplications` | Có primitive kill app nhưng **không có bằng chứng bộ hẹn sau disconnect 12 giây**; không tái nối nút `Close App` sang callback khác |
| Trạng thái reset/splash/Screen Blank | `screenBlankEnabled`, `performResetDefaults`; riêng bridge fullscreen nhận trạng thái `active/expanded` | Có thành phần lân cận, không phải bằng chứng reconnect FSM đã tồn tại |
| Hồ sơ cấu hình theo nhiều xe | Chưa thấy mô hình profile + stable headunit key trong danh sách settings đã audit | **Đề xuất mới** chứ không tuyên bố native12 đang làm |

**Điểm chưa được kiểm tra sâu:** chính xác key CFPreferences và notification được tự mở dùng, code nhận disconnect/scene, chuỗi call tới `autoLaunchBundleID`, debounce hiện hữu và timer disconnect. Không tạo key/bằng chứng từ suy đoán.

## 3. Phương án hợp nhất đề xuất — đúng một nhóm "Kết nối thông minh"

| Thứ tự UI đề xuất | Mục DuoFace | Nguồn | Mặc định khi thêm tính năng | Công dụng và ưu thế |
|---|---|---|---|---|
| 1 | **Tự mở khi kết nối** | Giữ DuoFace + tham khảo Auto Start | **Giữ giá trị người dùng đang lưu** | Không tạo switch trùng; duy nhất một nơi chỉnh Auto Launch |
| 2 | **Ứng dụng tự mở** | `autoLaunchBundleID` DuoFace + chọn app | **Giữ lựa chọn hiện tại** | Cho chọn app mặc định hoặc dùng phiên gần nhất nếu đã bật restore |
| 3 | **Khôi phục phiên gần nhất** | Chức năng mới | **TẮT** | Khi kết nối lại, phục hồi các app/slot thực đã lưu, nếu app còn cài và đủ quyền; không tự ghi đè cấu hình bố cục hiện tại |
| 4 | **Tự phục hồi khi mất kết nối ngắn** | Chức năng mới | **TẮT** cho đến khi được QA, không bật ngầm | Phân biệt ngắt tạm thời/vĩnh viễn, chống auto-start trùng; cho thấy đang kết nối/lỗi |
| 5 | **Khi ngắt CarPlay** | Tham khảo Close on Disconnect của DuoDash | **Giữ ứng dụng** | Tùy chọn `Giữ nguyên` / `Dừng tác vụ DuoFace` / `Đóng app DuoFace quản lý` (OFF), khi đóng có countdown tham khảo 12s và hủy nếu reconnect |
| 6 | **Cấu hình theo xe/màn hình** | Chức năng mới | **1 hồ sơ mặc định**, không fingerprint xe | Chỉ tạo hồ sơ riêng khi có ID display khả dụng và người dùng chủ động gán nhãn; lưu từng cấu hình mà không lẫn nhau |
| 7 | **Trạng thái kết nối** | Tăng khả năng quan sát | **Chỉ đọc** | Đang kết nối/ổn định/ngắt/lỗi, app được chọn để tự mở, lý do không phục hồi (không có app/không có sự kiện) |
| 8 | **Lịch sử & chẩn đoán kết nối** | Chức năng mới | **Chỉ lưu trên máy**, vòng đệm giới hạn | Đếm lượt kết nối/ngắt, lỗi duplicate, duration; khi cần mới xuất log, lọc ID riêng tư |

**Không nên sao chép trực tiếp:** `Enable App Bridge` thành một công tắc mới vì có thể vô hiệu hóa ngay luồng chính DuoFace; `Deep Sleep` của DuoDash vì chưa xác minh khả năng ngủ có cắt kết nối. Nếu cần "dừng bridge", phải có cơ chế tắt an toàn, không chỉ ngắt một hook.

## 4. Trình tự hoạt động kỹ thuật đề xuất

Thiết kế một nguồn trạng thái kết nối duy nhất tại **đúng owner event** của DuoFace (không suy diễn tất cả source callback là CarPlay connect). Trạng thái đề xuất:

`DISCONNECTED → CONNECT_DETECTED → STABILIZING → ACTIVE → DISCONNECT_GRACE → DISCONNECTED`, có `ERROR` và `RECOVERING`. Mỗi phiên có **generation ID** và một job auto-launch đang hoạt động tối đa; sự kiện mới làm vô hiệu job/timer cũ.

- **Kết nối:** verify màn thật + quyền, lấy 1 profile đang chọn, đọc Auto Launch cũ, quyết định mở preset hoặc last session **không mở trùng app đang chạy**. Khi app không có/không còn quyền: báo lý do và không thay app ngẫu nhiên.
- **Ngắt thoáng qua:** snapshot chỉ các bundle IDs/slot/ratio/last-active app đã xác minh đang hiển thị trước khi mất host; giữ cấu hình người dùng, hẹn xử lý theo chính sách, không vội kill.
- **Kết nối lại trong grace:** hủy timer đóng app; invalidate generation cũ; xác nhận trạng thái host, áp lại **nếu bật restore**; không mở thêm phiên thứ hai nếu app đã sống.
- **Hết grace:** `Giữ nguyên` mặc định. Nếu user đã chọn `Dừng` thì chỉ dừng phần runtime của DuoFace. Chỉ khi bật riêng `Đóng app`, chỉ đóng app có provenance do DuoFace khởi động/quản lý và không đang active/media/nav/app hệ thống; log và cho hủy; không gọi terminate-all tùy tiện.
- **Chống vòng lặp:** nếu khởi động thất bại lặp nhiều lần thì tạm dừng tự phục hồi và hiển thị lỗi; không tự respring, không tự thay nút menu, không tác động Wi-Fi/Bluetooth/Airplane Mode.
- **Quyền và privacy:** chỉ dùng thông tin CarPlay/session đủ cho kết nối, không lấy VIN, địa điểm, serial hoặc ID thiết bị bền vững nếu không cần. **Mọi công dụng đều chỉ là kế hoạch, chưa có hook/CI/DEB thực**.

## 5. Cần làm nếu user duyệt việc lập trình Nhóm 1

1. CI **read-only** native12 đúng SHA để truy event chain: `CBGeneralSettingsViewController.autoLaunchToggleChanged:` → prefs key/notification → `CBDashboardSettings.autoLaunchOnConnect`/`autoLaunchBundleID` → handler thật; audit connect/disconnect và nơi snapshot trạng thái. Kết quả phải lưu **fileoffset / selector / callpath / confidence**, không đụng 8 CarPlay guards.
2. Trên source độc lập DuoFace, tạo **settings adapter** giữ key user hiện có + controller riêng với khả năng `SUPPORTED/UNSUPPORTED/ERROR`; phát triển FSM idempotent, không sửa CBBridgeManager native class hoặc callback `Close App` hiện hành trong giai đoạn đầu.
3. QA synthetic sequences: cold connect khi app chưa chạy; connect khi màn đã được attach; rapid connect/disconnect/reconnect; auto-launch OFF; app thiếu; preset vs last; double-event; CarPlay screen changed; background music/maps; tắt máy quá grace; crash trong lúc restore; mất permission.
4. Version candidate riêng khi được yêu cầu build; pass metadata, không thay Logo/App/Zoom/Style/Close, fullscreen, ratio và splash; ghi hashes, Sileo không đổi trước QA; native12 + native10 rollback giữ nguyên.

**Quyết định chưa chốt/không được tự biến thành requirement:** 12s chỉ tham khảo từ DuoDash và là *đề xuất* chứ không bắt buộc; số profile tối đa/UX, restore ratio, hành vi khi app nhạc đang mở, độ dài grace, tên lựa chọn và mặc định của tính năng mới có thể sửa sau. AutoLaunch và app picker hiện có **không được reset mặc định**.

## 6. Kết luận

DuoFace có lợi thế là đã có **mô hình app và layout cùng Auto Launch trong app iPhone**. DuoDash cung cấp 2 quy tắc tiện ích có thể học: `Auto Start` và `Close on Disconnect`. Hướng mạnh hơn là hệ thống kết nối **ổn định, khôi phục đúng phiên, chống mở trùng, profile theo màn hình và chính sách đóng an toàn có thể hủy**, chứ không làm lại split/menu hay bê plugin từ DuoDash.

**Cấm nhầm trạng thái:** báo cáo này là **phân tích**; không thực thi native12, không tích hợp UI/backend, không build native13 và không publish Sileo. Workstream xóa giấy phép 14 classes/249 methods vẫn TẠM HOÃN theo người dùng.
