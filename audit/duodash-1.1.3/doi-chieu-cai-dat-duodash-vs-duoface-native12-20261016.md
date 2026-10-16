# Đối chiếu từng cài đặt DuoDash 1.1.3 ↔ DuoFace 0.1.0~native12

**Ngày:** 16/10/2026 (Asia/Ho_Chi_Minh)  
**Trạng thái:** READ-ONLY AUDIT; không sửa source/binary, không build, không triển khai DEB.  
**Yêu cầu:** so từng cài đặt/công dụng của DuoDash đã phân tích từ DEB do người dùng gửi với **DuoFace native12 hiện hành**, dựa trên cả hai hồ sơ bàn giao, không điều tra chia ô / UI CarPlay của DuoDash và không tiếp tục việc xóa giấy phép đang tạm hoãn.

## Nguồn, mốc chính xác và giới hạn

1. DuoDash DEB do người dùng tải: `com.sensetechlab.duodash_1.1.3_iphoneos-arm64.deb`, SHA256 `16ffab22b4246dea9978cae92df7ec635d833ec067b4d9f425a231b26edec601`; hồ sơ kiểm tĩnh `audit/duodash-1.1.3/settings_license_static_audit.md` (`main`, blob `eed5af7971e27a56a6be6cceaf89b4dd75a5820b`). Đã giải nén, xem hai plist và ba Mach-O; **không chạy DuoDash thực tế**. Một số hàng có thể không xuất hiện trên trang Settings do có hai nguồn plist khác nhau.
2. Hồ sơ chính DuoFace: `ban giao du an duoface moi.md` (`main` ngay trước phân tích, blob `3e5cbcf0368d9421c2ef1d0cbeddf40d3b4a9a0b`). Hồ sơ lịch sử: `tiep tuc du an.md` (`main`, blob `9722ea67f3a3ebfe2a9b8cb1f35f57374368fa5b`). Hồ sơ cũ chứa xác nhận ảnh thật ngày 11/10: trong iPhone DuoFace có trang **Cài Đặt**, dòng **Tự Động Mở Khi Kết Nối** và phụ đề cũ **Tự mở DuoNavi khi cắm CarPlay**; còn chứa các quy định không đổi hành vi nút Close App thành chức năng khác và điều tra giọng nói upstream 1.0.4.
3. DuoFace đang dùng: `com.duoface.independent`, version `0.1.0~native12`, SHA256 `85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7`; người dùng xác nhận native12 **hoạt động tốt nói chung**, **không xác nhận test từng tùy chọn Settings**. Repo `chuongnguyen89dn-ui/Duoface`, mã branch `feature/duoface-exact-payload-migration` tại thời điểm kiểm `55e7d33cf7d998df25bd5491cfa29ac57fb7d667`.
4. Dữ liệu Objective-C `audit/payload-migration/ORIGINAL_SETTINGS_OBJC_METHODS.json` blob `cf680223058787664e83e20a6b3815590f91f6cf`; `dist/payload-migration/native4/BAO_CAO.json` cho thấy đúng **`CBGeneralSettingsViewController.openSubscriptionScreen`** là 1 phương thức bị neutralized; **29 phương thức khác của lớp 30-selector không bị chọn để thay body trong native4**. Native10 thay 19 lifecycle thuộc các lớp license; native11 xóa 52 literal license; native12 chỉ xóa NoLease dylib+plist, các host binary còn byte-identical với native11 theo `native12/BAO_CAO.json`. Từ đó có chứng cứ **phương thức Settings còn trong host native12**, nhưng chưa chứng minh tác dụng runtime từng switch.
5. `CBDashboardSettings` ở `DuoFaceDashboard.dylib` có 61 methods, bao gồm `autoLaunchOnConnect`, `bridgedApps`, `appSettings`, `hideIconLabels`, `dockSystemMonitorEnabled`, `screenBlankEnabled`, `voiceFeedbackEnabled`, `assistantEnabled`. Đây là getter/setter lưu trạng thái và **không tự chứng minh có cùng feature DuoDash**.
6. `dist/payload-migration/EXACT_COPY_AUDIT.json`: trong gói DuoFace baseline **không có** `PreferenceLoader/Preferences/*.plist` hay `PreferenceBundles/*` như DuoDash; phần cài đặt nằm ở **app iPhone `var/jb/Applications/DuoFaceUI.app/DuoFaceUI`** qua `CBGeneralSettingsViewController`, và phần trạng thái/áp dụng ở **`var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib`**. Thư mục `var/mobile/Library/Preferences` có trong staging, nhưng audit này **chưa chứng minh tên file preferences thực tế hay hành vi ghi từng khóa**.

**Cách đọc trạng thái:** **Có mã + giao diện/đường chạy** = chứng cứ tĩnh/vài ảnh, nhưng không nhất thiết device-QA riêng từng switch. **Một phần/khác cơ chế** = chỉ tương đồng nhu cầu, tuyệt đối không coi chức năng bằng nhau. **Chưa xác nhận** = chưa tìm thấy bằng chứng tương đương trong tài liệu và metadata hiện tại; không khẳng định chắc chắn mã tuyệt đối không tồn tại.

## I. 18 hàng settings trong plist mở rộng của DuoDash

| # | Mục DuoDash / key | Công dụng cụ thể theo DEB | Đối chiếu DuoFace native12 | Đánh giá |
|---|---|---|---|---|
| 01 | HUD Status — `hud_pairing_status` | Chỉ báo ghép HUD Bluetooth, mặc định Not paired | DuoFace có cơ chế phát hiện kết nối CarPlay nhưng **không phải** HUD BLE của DuoDash; chưa thấy mục HUD Status tương ứng | Chưa xác nhận |
| 02 | HUD Paired — `hud_paired` | Ghép/hủy ghép một phần cứng HUD, notification BLE action | Chưa có chứng cứ về hệ thống ghép HUD chuyên dụng ở DuoFace | Chưa xác nhận |
| 03 | HUD Firmware — `hud_firmware_version` | Hiển thị firmware của HUD đã ghép | Chưa thấy mục firmware HUD tương ứng | Chưa xác nhận |
| 04 | Deep Sleep — `deepsleep_enabled` | Chế độ ngủ/tiết kiệm năng lượng; có nhãn liên quan battery/time/Bluetooth/airplane. Chưa xác minh thao tác radio runtime | DuoFace **có** `screenBlankEnabled`, `screenBlankToggleChanged:` trong trang Settings: **che/tắt hiển thị không phải Deep Sleep** hay tự quản Bluetooth/radio | Khác chức năng; chưa có Deep Sleep tương đương |
| 05 | Optimize CPU And Thermal — `perf_tweak_enabled` | Giảm frame rate để hạ tải/nhiệt; DuoDash lưu ý beta, cần reconnect | DuoFace có vận hành UI và logic đồ họa, **chưa có chứng cứ** setting điều chỉnh FPS/thermal riêng tương ứng | Chưa xác nhận |
| 06 | Close Unloaded Pane Apps — `pane_unload_close_enabled` | Tự đóng app khi không còn nằm ở vùng đang dùng, giải phóng RAM/CPU; nguy cơ mất nhạc/dữ liệu | DuoFace có một số native `terminateApplicationWithBundleID:`/`terminateAllBridgedApplications` và các hành động đóng app, **chưa xác minh** có tự động đóng *khi pane unload* | Một phần, khác điều kiện kích hoạt |
| 07 | Auto Start — `appbridge_autostart` | Tự chạy bridge sau khi kết nối | DuoFace **có** `CBGeneralSettingsViewController.autoLaunchOnConnect`, `autoLaunchToggleChanged:`, `setAutoLaunchOnConnect:`; `CBDashboardSettings.autoLaunchOnConnect`, và ảnh người dùng thấy dòng **Tự Động Mở Khi Kết Nối** | Có mã + bằng chứng giao diện, cần QA riêng hoạt động khi reconnect |
| 08 | Close Apps on CarPlay Disconnect — `disconnect_close_enabled` | Tự đóng app sau khi CarPlay ngắt, chú thích khoảng chờ 12 giây | DuoFace có xử lý vòng đời CarPlay/disconnect và tác vụ đóng app tách biệt, **chưa thấy điều khiển hoặc bằng chứng hẹn 12 giây tự đóng app** | Chưa xác nhận |
| 09 | Headunit Resolution — `headunit_resolution` | Hiển thị độ phân giải thực tế, chỉ đọc | DuoFace sử dụng `UIScreen`, geometry cho host và bố cục; **chưa xác minh có hàng chỉ đọc resolution trong Settings** | Có số đo bên trong, chưa có hiển thị tương đương |
| 10 | Recommended video quality — `headunit_video_quality` | Hiển thị đề xuất chất lượng video, không phải chỉnh stream trực tiếp | Chưa thấy công thức đề xuất quality hoặc trang hiển thị tương tự DuoDash | Chưa xác nhận |
| 11 | Enable App Bridge — `appbridge_enabled` | Công tắc bật lớp bridge | DuoFace đang có bridge chạy và `CBDashboardSettings.bridgedApps`/`portalAppEnabled`; **chưa thấy công tắc tách riêng giống DuoDash** | Có tính năng nền, chưa tương đương công tắc |
| 12 | Choose Apps to Bridge — `chooseAppsToBridge:` | Mở picker chọn danh sách ứng dụng | DuoFace **có chọn ứng dụng** (app picker / tab App, `CBAppPickerViewController`, `CBDashboardSettings.bridgedApps`). Không suy ra selector/cơ chế giống nhau | Có chức năng tương đương |
| 13 | Go To CarPlay — `CarKitSettings` | Đưa người dùng đến trang CarPlay trong Settings iOS | DuoFace chưa có bằng chứng nút chuyển trang này trong Settings app | Chưa xác nhận |
| 14 | Splash Screen — `splash_selected` | Cho chọn 3 hình nền `Mountain Road/City Skyline/Light Trails` hoặc `None` | DuoFace có màn chào/loading đã phát hiện `CBSplitSplashScreenView` và tài nguyên logo, **chưa có bằng chứng trình chọn 3 ảnh hay OFF** | Một phần: có splash, không xác minh tùy biến |
| 15 | Tweak Management — `openTweakManagement:` | Quản lý thành phần tweak đi kèm; DuoDash beta. Chưa chứng minh selector hoạt động trên thiết bị | DuoFace có các dylib riêng và có thể quản lý package qua Sileo, **chưa có giao diện quản lý từng tweak tương đương** | Chưa xác nhận |
| 16 | DuoDash Status — `duodash_latch_status` | Trạng thái cơ chế *crash-protection latch*, mặc định OK; không phải license | DuoFace có các dấu trạng thái ứng dụng chạy/ngừng trong menu, **không phải** latch phục hồi crash; chưa có status latch tương ứng | Không tương đương |
| 17 | Re-enable DuoDash Tweaks — `duodash_reenable_tweaks` | Reset latch sau crash, gửi notification và có thể Respring | DuoFace có `CBGeneralSettingsViewController.performRespring`, nhưng **Respring đơn thuần không bằng khôi phục latch sau crash** | Một phần ở tác vụ Respring; chưa có reset latch |
| 18 | Language — `duodash_language` | Chọn 17 ngôn ngữ trong đó có tiếng Việt, notify đổi ngôn ngữ | DuoFace có `showLanguageSelectionSheet`, `handleLanguageChanged` ở Settings, `CBLocalization` và picker rebuild khi đổi ngôn ngữ; **chưa xác nhận DuoFace hỗ trợ đủ đúng 17 ngôn ngữ** | Có chức năng chọn ngôn ngữ |

**Lưu ý cách dựng trang:** DuoDash có `PreferenceLoader/Preferences/DuoDashPrefs.plist` **18 hàng + 8 header/footer nhóm**, nhưng `PreferenceBundles/DuoDashPrefs.bundle/Root.plist` chỉ **8 hàng + 2 nhóm**; `DuoDashRootListController.specifiers` thực sự nạp `Root`. Do đó **không được khẳng định chắc chắn đủ 18 hàng đều đang hiển thị đồng thời** khi người dùng mở Settings trên máy. Bảng là *toàn bộ khả năng được khai báo*, không phải một ảnh chụp trang Settings.

## II. Những mục bổ sung của DuoDash được tạo trong mã, không nằm trọn trong hai plist

### A. Navigation Bubble — dữ liệu tốc độ

| Mục | DuoDash làm gì | DuoFace native12 |
|---|---|---|
| Provider | Chọn nguồn cấp tốc độ độc lập | Chưa tìm thấy trình chọn speed-provider tương ứng |
| Status (Publishing/Not publishing/Not found) | Xem nhà cung cấp có phát dữ liệu hay không | Chưa có status provider tương ứng |
| Auto-start Provider | Tự bật nguồn tốc độ | Auto Launch ở DuoFace bật app/bridge, **không tương đương** tự bật speed-provider |
| Keep Provider Awake | Tránh provider bị ngủ | Chưa thấy cơ chế giữ app cung cấp tốc độ chạy nền tương ứng |
| Show on Pane | Hiển thị bong bóng tốc độ | Chưa có bằng chứng native12 vẽ bong bóng tốc độ |
| Blink When Over Limit | Nháy khi vượt giới hạn | Chưa có |
| Beep When Over Limit | Cảnh báo âm thanh quá tốc độ | Chưa có |
| Beep Volume | Chỉnh âm lượng cảnh báo | Chưa có |
| Speed Source | Chọn `OBD2 Dongle / Navigation App / GPS` | Chưa có bộ chọn nguồn tương đương |
| Speed Correction | Hiệu chỉnh tốc độ đo | Chưa có |
| Fake Test | Tạo dữ liệu giả để thử | Chưa có |
| Send Test Payload | Gửi mẫu dữ liệu sang bubble | Chưa có |
| Last Payload | Xem gói dữ liệu tốc độ vừa nhận | Chưa có |
| How to Build a Provider | Hướng dẫn nhà phát triển tạo provider ngoài | Chưa có hướng dẫn/tích hợp tương đương |

**Cơ chế DuoDash thực tế:** metadata runtime nhắc provider/tweak phát dữ liệu qua plist + notification, đơn vị km/h và nhịp heartbeat khoảng 5 giây. Vì vậy bong bóng DuoDash **không tự tạo dữ liệu giới hạn tốc độ chính xác ở Việt Nam**. Muốn tính năng tương đương trong DuoFace thì cần **nguồn speed-limit đáng tin cậy, tốc độ hiện tại và protocol/permission tương thích**; không nên chỉ sao chép giao diện bong bóng.

### B. Voice Command

| Mục | DuoDash làm gì | DuoFace native12 |
|---|---|---|
| Handler | Chọn tweak/app xử lý sự kiện nút giọng nói | Native12 chưa xác minh có cấu hình steering-wheel handler tương đương |
| Use Steering-Wheel Button | Chuyển nút nói trên vô-lăng khỏi Siri tới handler | Chưa tìm thấy chứng cứ cho phép thay nút Siri; **không tương đương** `assistantEnabled` |
| Send Test Press | Giả lập sự kiện nút để thử handler | Chưa thấy nút thử |
| How to Build a Handler | Hướng dẫn bên thứ ba tạo handler | Chưa thấy protocol/hướng dẫn tương ứng |

**Không nhầm giọng nói các bản:** báo cáo `docs/duoface_104_voice_linkage.md` xác minh **bản upstream DuoNavi 1.0.4** có `CBVoiceSessionManager`, `CBVoiceDirectiveDispatcher`, `CBVoiceSTT...` v.v., **v12 Dashboard làm baseline DuoFace native12 không có cùng bộ lớp đó**. Mặt khác native12 Dashboard có `CBAssistantManager` và settings `assistantEnabled`, `voiceFeedbackEnabled`: bằng chứng có/đã từng có logic assistant nhưng **không chứng minh tính năng điều khiển nút vô-lăng kiểu DuoDash**. Không tự lấy nhị phân upstream 1.0.4 thay vào native12.

### C. Crash Reporter / phục hồi sự cố

DuoDash có trang/chuỗi `Send Report`; các trạng thái `Collecting`, `Packaging`, `Saved on device`, `Saved on device (no server configured)`, `Already sending`, `Failed (no space)`, `Failed (network)`. Có mã sử dụng `NSURLSession`/`NSMutableURLRequest`, **chưa xác minh URL máy chủ/luồng gửi thực**. DuoFace có các log và CI/Sileo để kỹ thuật viên tự thu thập, nhưng **chưa thấy hệ thống báo cáo crash tích hợp với nút gửi/báo trạng thái giống DuoDash**, cũng không thấy crash latch/re-enable. Nhớ rằng báo cáo lỗi có thể chứa thông tin thiết bị/cá nhân; không sao chép cơ chế gửi ngầm.

## III. Những cài đặt riêng DuoFace hiện có, không được bỏ sót

**Vị trí:** `var/jb/Applications/DuoFaceUI.app/DuoFaceUI`, class `CBGeneralSettingsViewController`, **30 phương thức** theo audit original + `var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib`, class `CBDashboardSettings` **61 phương thức**.

| DuoFace Settings | Bằng chứng từ class/selector | Trạng thái |
|---|---|---|
| Tự động mở khi kết nối | `autoLaunchOnConnect`, `autoLaunchToggleChanged:`, `setAutoLaunchOnConnect:` trong app; cùng getter trong Dashboard; ảnh thật trang Cài Đặt cũ | Có code và ảnh thực, chưa đo riêng reconnect native12 |
| Che / tắt màn hình hiển thị | `screenBlankEnabled`, `screenBlankToggleChanged:` (app), getter/setter `screenBlankEnabled` (Dashboard) | Có code, không gọi là Deep Sleep |
| Theo dõi hệ thống Dock | `dockMonitorEnabled`, `dockMonitorToggleChanged:` (app); `dockSystemMonitorEnabled`, `dockSystemMonitorShowAll` (Dashboard) | Có code, không gán thành HUD |
| Ẩn tên/icon labels | `hideLabelsEnabled`, `hideLabelsToggleChanged:` (app), `hideIconLabels` (Dashboard) | Có code, UI thực chưa test riêng |
| Chọn ngôn ngữ | `showLanguageSelectionSheet`, `handleLanguageChanged` | Có code; chưa kiểm đủ số ngôn ngữ |
| Khôi phục mặc định | `performResetDefaults` và `savePreferences`/`loadPreferences` | Có code; chưa xác minh từng preference nào sẽ bị reset |
| Respring | `performRespring` | Có code; không phải reset crash-latch |
| Mục giấy phép cũ | `openSubscriptionScreen` | **Đã neutralized từ native4**, không tính là cài đặt còn hoạt động |

Ngoài Cài đặt trên iPhone, DuoFace có các lựa chọn vận hành app/menu gồm App, Zoom In/Out, Style, Close App; trạng thái Live/X và lựa chọn app. **Đây không phải màn hình settings DuoDash.** Đặc biệt lịch sử dự án xác nhận `Close App` trong menu từng được yêu cầu **giữ callback gốc khi đổi nhãn/icon**, không được tự suy ra đây là tùy chọn `Close Unloaded Pane Apps` hoặc `Close Apps on Disconnect`.

## IV. Gợi ý lựa chọn tính năng nếu có giai đoạn phát triển sau (CHƯA ĐƯỢC DUYỆT TRIỂN KHAI)

- **Không cần chép lại:** Auto Start, app picker, Language — DuoFace đã có cơ sở để chỉnh/làm rõ theo nhu cầu.
- **Dễ xét để bổ sung riêng, ít phụ thuộc phần cứng:** Headunit Resolution dưới dạng read-only; Go To CarPlay; trạng thái cấu hình/phiên bản; theo dõi/cảnh báo lỗi **chỉ lưu tại máy** và cho phép xuất log khi người dùng chủ động.
- **Đáng cân nhắc nhưng phải thiết kế theo luồng đang có:** Close Apps on Disconnect (cần chống đóng nhầm, quy định timeout), Close Unloaded Pane Apps (dễ mất dữ liệu/nhạc), CPU/thermal (cần đo FPS và nhiệt, tránh gây tác dụng ngược).
- **Chỉ có lý do triển khai khi có thiết bị/nguồn:** HUD pairing + Firmware (nếu dùng phần cứng HUD), Navigation Bubble (cần nguồn tốc độ/giới hạn đáng tin), steering-wheel Voice Command (cần kiểm tương thích Siri/CarPlay và xử lý sự kiện).
- **Không tự sao chép:** Crash-latch re-enable/Respring hay Deep Sleep ảnh hưởng nền hệ thống nếu chưa có kỹ thuật vận hành/rollback rõ ràng; splash picker là tùy biến tùy chọn, không cần thay splash hiện có.

## V. Cần kiểm chứng trước khi ghi "có hoạt động trên native12"

1. Mở trang **Cài Đặt** trên iPhone cài native12, chụp danh sách thực tế: Auto Launch, Screen Blank, Dock Monitor, Hide Labels, Language, Reset, Respring — **trạng thái mã tồn tại khác trạng thái nút xuất hiện**.
2. Thử **Auto Launch** sau ngắt/kết nối, **Language** và hiệu ứng mỗi switch với iPhone/CarPlay; không bật Reset hoặc Respring chỉ để thử nếu chưa cần.
3. Nếu bổ sung chức năng DuoDash về sau: chỉ chọn chức năng có ích và phát triển native trong DuoFace; **không copy nguyên tweak DuoDash và không nhập cơ chế ghép HUD không liên quan**.

**Kết luận:** Có thể đối chiếu thực sự **18 hàng settings và 3 nhóm tùy chọn mở rộng**; DuoFace có settings nội bộ đáng kể, nhưng chưa có chứng cứ hỗ trợ hết hệ chức năng DuoDash. Trạng thái physical license removal được người dùng **TẠM HOÃN**, không được kích hoạt lại khi làm danh mục settings. Giữ nguyên native12 và rollback native10, không build/deploy trong nhiệm vụ này.

## Tham chiếu file GitHub

- `main:ban giao du an duoface moi.md` — trạng thái mới nhất, native12 PASS, license pause
- `main:tiep tuc du an.md` — ảnh settings iPhone, selector, quyết định menu và giọng nói upstream
- `main:audit/duodash-1.1.3/settings_license_static_audit.md` — checklist 18 hàng + mở rộng
- `feature/duoface-exact-payload-migration:audit/payload-migration/ORIGINAL_SETTINGS_OBJC_METHODS.json` — 30+61 methods
- `feature/duoface-exact-payload-migration:dist/payload-migration/native4/BAO_CAO.json` — method `openSubscriptionScreen` neutralized
- `feature/duoface-exact-payload-migration:dist/payload-migration/native12/BAO_CAO.json` — provenance native12
- `feature/duoface-exact-payload-migration:dist/payload-migration/EXACT_COPY_AUDIT.json` — package layout (no PreferenceLoader bundle)
- `feature/duoface-exact-payload-migration:docs/duoface_104_voice_linkage.md` — voice difference upstream 1.0.4 vs v12
