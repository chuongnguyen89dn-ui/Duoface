# DuoFace Native12 — phân tích sâu Tắt Màn Hình iPhone và Giám Sát Dock

Ngày: 2026-10-16 (+07:00)  
Trạng thái: **ĐÃ PHÂN TÍCH TĨNH BẢN GỐC, CHƯA CÓ THỬ NGHIỆM TRÊN IPHONE**.  
Yêu cầu: Người dùng nhận xét đúng rằng iPhone vốn có tự khóa/tắt màn hình khi dùng CarPlay; tìm chức năng thực tế của hai công tắc. Không build DEB, không thay Sileo, không dùng binary native13–21 làm nền.

## 1. Mốc dữ liệu đã xác minh

- Repository: `chuongnguyen89dn-ui/Duoface`.
- Branch điều tra: `feature/duoface-exact-payload-migration`.
- DEB duy nhất được phân tích: `dist/payload-migration/native12/com.duoface.independent_0.1.0~native12_iphoneos-arm64.deb` trong commit nền gốc `f08b6f4a7be0bc3a38cce1b0c9b52f8179841064`; SHA256 `85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7`.
- DuoFaceUI Mach-O SHA256 `cb40346d8ca504cb399abe31367847b4f980a01ba93810986ce1acf1fbe9eef9`; DuoFaceDashboard dylib SHA256 `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`.
- Script thực đã chạy: `migration/full_payload/native_test/audit_native12_screenblank_dock_deep.py --deb dist/payload-migration/native12/com.duoface.independent_0.1.0~native12_iphoneos-arm64.deb --out audit/payload-migration/NATIVE12_SCREENBLANK_DOCK_DEEP_READONLY.json`. Python 3, capstone 5.0.6, `dpkg-deb -x` trong Ubuntu 24.04 GitHub Actions.
- Source script và workflow: `feature:migration/full_payload/native_test/audit_native12_screenblank_dock_deep.py` và `feature:.github/workflows/duoface-native12-screenblank-dock-deep-readonly.yml`.
- Workflow [run 38878439739](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/38878439739), job `116899047742`, **completed/success**. Báo cáo evidence: `feature:audit/payload-migration/NATIVE12_SCREENBLANK_DOCK_DEEP_READONLY.json`, Git blob `429983844b46fba9d34ce5076354be79fa1e6b86`. Workflow đã đọc trực tiếp 3 ZIP kỹ năng trung tâm: `01-github-continuity.zip`, `02-ios-deb-ipa-carplay.zip`, `05-research-debug-testing.zip`.
- Audit trước về selectors CPU, thermal: `feature:audit/payload-migration/NATIVE12_CPU_THERMAL_READONLY.json`, CI `38877337186` PASS.
- Không có ghi/chạy ứng dụng lên thiết bị. Khác biệt **static method existence** và **runtime activation** phải giữ nguyên.

## 2. Công tắc “Tắt Màn Hình iPhone” — mã thực

### 2.1. Trong DuoFaceUI: cài đặt chỉ thay trạng thái và lưu

Class `CBGeneralSettingsViewController`:
- `screenBlankToggleChanged:` IMP `0x10000de2c`: tại `0x10000de40` gọi `isOn`, `0x10000de54` gọi `setScreenBlankEnabled:`, `0x10000de64` gọi `savePreferences`.
- `loadPreferences` IMP `0x10000d7c4` đọc dictionary cấu hình; `savePreferences` IMP `0x10000da34` ghi plist.
- `CBDashboardSettings.screenBlankEnabled` IMP `0x37ec0`, `setScreenBlankEnabled:` IMP `0x37ec8`: getter đọc 1 byte trạng thái ở `[x0,#9]`, setter chỉ ghi byte.
- **Đã chứng minh:** switch lưu thiết lập. **Chưa chứng minh:** switch trực tiếp gọi hàm tắt màn hình, tự hẹn tắt khi CarPlay kết nối, hoặc có tiêu thụ pin tiết kiệm hơn iOS.

### 2.2. Mã gọi API riêng của hệ thống

Trong bản Native12 có chuỗi `BKSDisplayServicesSetScreenBlanked` (BackBoardServices, tìm qua `dlsym`). Các vị trí **đã tìm được từ các method Objective-C**:
1. `CBAssistantManager.processVoiceCommand:` tại `0x31af0–0x31b08`: `mov w0,#1`, `blr x8` → yêu cầu **blank ON** tại một nhánh xử lý lệnh giọng nói.
2. `CBBridgedUIAppView.startInParentViewController:` tại `0xae554–0xae568`: `mov w0,#0`, `blr x8` → yêu cầu **blank OFF** trong đường khởi tạo vùng ứng dụng.
3. `CBBridgeManager.deactivateCurrentApp` tại `0x19d7f8–0x19d80c`: `mov w0,#0`, `blr x8` → yêu cầu **blank OFF** khi vô hiệu hóa ứng dụng.

Không có chứng cứ từ các callsite trên cho thấy tùy chọn `screenBlankEnabled` tự kích hoạt đường blank ON trong lúc kết nối CarPlay. Kiểm tra method riêng `screenBlankToggleChanged:` chỉ thấy set flag + save. **Phán đoán có giới hạn:** công tắc có thể bị thiếu kết nối runtime hoặc không cần thiết trong trường hợp iOS vốn tắt màn hình. Chưa loại trừ consumer động, helper C/C++ hoặc các hook khác ngoài phương pháp xref được audit; không kết luận tuyệt đối “không hoạt động”.

**Đặc biệt:** hai callsite khởi tạo/vô hiệu hóa đều dùng `blank OFF`, nên không được tuyên bố DuoFace đảm bảo màn hình tự tắt liên tục hay giúp tiết kiệm pin chỉ từ tên switch. Việc có bật màn hình vật lý ngoài ý muốn phải thử trên thiết bị mới xác nhận.

### 2.3. iOS đã làm gì?

Apple xác nhận `Auto-Lock` giảm sáng/khóa màn hình theo thời gian (Cài đặt → Màn hình & Độ sáng → Tự động khóa). Trên thiết bị hỗ trợ Always-On Display, **Always-On display tự tắt khi phiên CarPlay bắt đầu**, không cần chức năng của tweak. Tài liệu chính thức: https://support.apple.com/vi-vn/guide/iphone/iph7117338a8/27/ios/27.

Do vậy, với người dùng đã quan sát màn iPhone tắt khi kết nối CarPlay, **chưa có lý do kỹ thuật được kiểm chứng để giữ công tắc Screen Blank bật**. Thử nghiệm không phá dữ liệu: tắt công tắc trong DuoFace, ngắt/kết nối lại CarPlay, quan sát iPhone vẫn tự tắt/khóa như bình thường hay không và menu/đa cửa sổ CarPlay còn hoạt động. Không cần chỉnh DEB.

## 3. “Giám Sát Dock” — mã thực, thông số và hạn chế

Class `CBDockSystemMonitorView` trong `DuoFaceDashboard.dylib`, các hàm xác minh:

- `startMonitoring` IMP `0xb49dc`: có `scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:`, theo sau `addTimer:forMode:`, gọi `updateMetrics`. Kiểm tra cờ `showAll`, nhánh `fcsel` cho interval: `12.0` giây nếu thu gọn, `5.0` giây khi mở rộng; timer cũ bị `invalidate` trước khi tạo mới.
- `stopMonitoring` IMP `0xb4ad4`: invalidate và release timer.
- `setShowAll:` IMP `0xb42a8`: nếu đang giám sát và đổi cách hiển thị, stop/start lại timer với interval thích hợp.
- `updateMetrics` IMP `0xb4dbc`: gọi `readDeviceTemperature` và `readCpuUsage`, đồng thời có kiểm tra `isHidden`; `updateBatteryMetric` IMP `0xb4b4c` lấy `UIDevice.currentDevice`, `batteryLevel`, `batteryState`, sử dụng `setBatteryMonitoringEnabled:` nếu trước đó chưa bật.

### CPU

`readCpuUsage` IMP `0xb5414` gọi `mach_host_self` / `host_statistics` với `HOST_CPU_LOAD_INFO=3`, lấy các bộ đếm thời gian CPU, trừ mẫu trước, tính busy ticks / total ticks ×100%, giới hạn 100%. Đây là **tải CPU toàn hệ thống**, không phải riêng DuoFace hay một app đang mở trên CarPlay. Ở mẫu đầu chưa có chênh lệch lịch sử, mã trả về **8.0%** làm giá trị khởi tạo; 8% này không phải số đo thật, phải đợi mẫu tiếp theo.

### Nhiệt độ

`readDeviceTemperature` IMP `0xb5230` thử IOKit `AppleSmartBattery` rồi `AppleTemperatureSensor` / `AppleEmbeddedNVMeTemperatureSensor`, đọc thông số, có các nhánh chia 10 hoặc 100 tùy giá trị. Khi không có kết quả cảm biến, dùng `NSProcessInfo.processInfo.thermalState` và bảng 4 số dấu phẩy động lấy trực tiếp tại VM `0x3119c0`:
- nominal = **33,5**
- fair = **38,0**
- serious = **43,5**
- critical = **48,0**

Đây là **giá trị ước lệ được lập trình sẵn**, không chứng minh nhiệt độ CPU iPhone theo độ C. Người dùng không nên coi số này là nhiệt kế phần cứng chính xác; cần hiện nhãn “ước lượng” nếu sau này muốn hiển thị minh bạch.

### Đánh giá

- Công tắc Dock thực sự có logic thống kê + hẹn giờ + hiển thị; nó **không giảm FPS, hạ xung CPU hay làm mát máy**.
- Khi bật có chi phí lấy mẫu nhưng chưa có benchmark CPU/pin để định lượng. Không khuyến cáo bỏ qua số liệu tĩnh để gọi “nặng” hay “rất nhẹ”.
- Nếu người dùng không cần xem các con số, tắt Giám Sát Dock là hợp lý để giảm hoạt động lấy mẫu không cần thiết.
- Không phải cơ chế Optimize CPU & Thermal beta của DuoDash, không được lấy binary hậu Native12 để thêm thay thế.

## 4. Trạng thái và bước xác nhận tiếp theo

**Đã hoàn tất:** scan payload gốc đúng SHA, kiểm ObjC methods, disasm thanh toán 3 callsites `BKSDisplayServicesSetScreenBlanked`, interval NSTimer, CPU formula, IOKit sensor/fallback thermal table; commit báo cáo tĩnh vào repo DuoFace.

**Chưa thực hiện:** không có log runtime iPhone xác nhận Screen Blank ON vs OFF tác động màn hình, chưa benchmark CPU trước/sau Dock, không có test nhiệt kế ngoài, không kiểm trên xe.

**Bước nếu được yêu cầu:** thử ON/OFF hai công tắc riêng rẽ trên Native12 cài thật; đặt iPhone và CarPlay trạng thái tương tự, xem màn iPhone có tự tắt dù Screen Blank OFF hay không; với Dock so hiển thị bình thường/thu gọn/mở rộng. Lưu bằng chứng, chỉ sau đó mới quyết định ẩn hoặc loại bỏ công tắc Screen Blank và chỉ bằng **candidate xây từ Native12 immutable**. Không thay publisher Sileo, không tự build DEB trong đợt nghiên cứu này.
