# NATIVE12/HUD8 — Sơ đồ nối hàm thực từ DEB và thứ tự tích hợp DuoFace

**2026-10-19 — Kiểm tra tĩnh, KHÔNG phải runtime trace trên xe. Không sửa chương trình hay phát hành Sileo.**

## 1. Nguồn chính xác và quy tắc chứng minh

DEB được đọc: **com.duoface.independent 0.1.0~native12+speed8compact**, rootless arm64; SHA-256 **2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad**. Nguồn byte bất biến: commit 1286a3ef868cf7e29804bcddf7e20b2eae707ce1 tại dist/payload-migration/native12-speed8compact. Đã giải nén bằng dpkg-deb -x và kiểm hash; KHÔNG chạy DEB, không chạy binaries/maintainer scripts.

Phương thức/IMP/ABI lấy từ audit trước: sideplay/audit/qa7-vs-native12-methods-20261018/method-index.json, blob efa45df59bc3c16887cc979bf3aedc0c93c92111. Lần này dùng LLVM Mach-O disassembly trên macos-15, liên kết PC lệnh ARM64 với khoảng phương thức tương ứng và xử lý cả hàm C/hook không có Objective-C method list.

**4 loại chứng cứ:**
- **B**: tồn tại byte, thông tin Info.plist, lớp/selector, IMP, type encoding hoặc filter.
- **I**: trong thân hàm tại PC đó có lệnh gửi Objective-C selector tương ứng. Điều này xác nhận *caller gọi selector*, không xác nhận receiver lúc runtime.
- **C**: cạnh đến một class/method ứng viên do ghép selector; Objective-C receiver có thể là x0 và class thực chỉ biết khi chạy. **Không được giả làm mũi tên gọi chắc chắn.**
- **P**: mạch từ source .xm/.mm dự án có thể đọc, cần kiểm đã đóng chính xác vào binary.
- **R**: quan sát thực tế trên iPhone/CarPlay — **chưa có ở báo cáo này**.

Output máy đầy đủ: SUMMARY.json, 8 file tên [MachO].json.gz và FOCUSED_METHODS.json.gz trong cùng thư mục; tạo bởi sideplay/tools/audit_native12_macho_wiring.py và workflow native12-full-function-wiring-audit.yml. Các file này lưu đầy đủ selector, vị trí lệnh, receiver, danh sách đích ứng viên và các hàm C. Không phải chỉ bản tóm tắt tên lớp.

## 2. Bao phủ cả DEB

| Mach-O | ObjC methods | LC_FUNCTION_STARTS | Vai trò |
|---|---:|---:|---|
| DuoFaceUI.app/DuoFaceUI | 522 | 726 | iPhone UI, picker, danh sách app, cấu hình, license UI |
| DuoFaceDashboard.dylib | 757 | 1526 | CarPlay bridge, CBWindow, split, divider, appDock, assistant |
| DuoFaceFullscreenBridge.dylib | 61 | 123 | Zoom transport, receiver, snapshot |
| DuoFaceLogoGripOnly.dylib | 0 | 23 | Hook/closure logo (không export ObjC method) |
| DuoFaceSpeedHUD.dylib | 44 | 66 | Bong bóng tốc độ + lựa chọn nguồn |
| DuoFaceSpeedOwner.dylib | 1 | 11 | Owner HUD trên SpringBoard |
| DuoFaceVisualHook.dylib | 0 | 33 | Hook native giao diện |
| duoface_cboptimize_helper | 0 | 1 | Binary helper, vai trò cụ thể chưa chứng minh |
| **Tổng** | **1385** | **2509** | **Tất cả 8 Mach-O** |

**Kết quả GitHub Actions:** 7827 ObjC selector callsites trong method IMP, 3895 selector callsites trong hàm C/hook khác, **1087 lời gọi tới __objc_stubs chưa giải được selector**. Các module Fullscreen/Speed dùng một dạng ObjC stub khiến LLVM không gắn sẵn selector; không được suy luận 0 annotation là không gọi phương thức. Lần quét này bao phủ method và lệnh, nhưng **chưa giải mã tất cả dynamic dispatch, callback block, target gián tiếp, hoặc IPC runtime**.

## 3. Mô hình tiến trình: Không thể dùng một owner cho tất cả

DuoFaceDashboard.dylib Filter Bundles bao gồm com.apple.CarPlayApp, com.apple.CarPlay, com.apple.dashboard, SpringBoard, DuoFaceUI và những app đích như YouTube/Maps/Waze/VLC. DuoFaceFullscreenBridge.dylib nạp CarPlay/CarPlayApp/Dashboard/SpringBoard theo cả Bundles lẫn Executables. LogoGrip/VisualHook nạp nhiều tiến trình. SpeedHUD và SpeedOwner Filter Executables=(SpringBoard). DuoFaceUI là app iPhone riêng.

~~~mermaid
flowchart TD
 PHONE["DuoFaceUI.app / CBAppManager / CBSplitViewController"] -. "B: preference + settings" .-> STATE["Settings + saved bridge state"]
 SB["SpringBoard: CBBridgeManager"] -. "C: commands/notification" .-> CP["CarPlay: CBBridgeManagerDashboard / CBDashboardShared"]
 SB -. "C: CBBridgedApp app host" .-> APP["iPhone app scene, touches, orientation"]
 CP -. "C: Apple AppDock VC / rootVC" .-> DOCK["Apple CarPlay system Dock"]
 SB -.-> WIN["CBWindow / CBBridgedSplitApp / CBDividerView"]
 WIN -. "C: CarPlay geometry" .-> DOCK
 ZOOM["DFFullscreenTransport / HostGeometry / Chrome"] -. "P: command & rollback" .-> WIN
 SPEED["DFSpeedOwner + DFSpeedHUD (SpringBoard)"] -. "B: independent HUD" .-> SB
~~~

**Kết luận:** bản Native12 có owner SpringBoard + receiver CarPlay/Dashboard + app scene đích; một overlay chỉ chỉnh frame ở SpringBoard không thay thế cả hệ thống.

## 4. Đường A — từ kết nối CarPlay đến mở ứng dụng

~~~mermaid
flowchart TD
 A["CarPlay UIScene / CADisplay"] -. "B/C" .-> W["CBWindow.carPlayWindowScene / carPlayUIScreen"]
 W -.-> G["CBWindow.carPlayScreenBounds + carPlayContentInsets"]
 G -. "I" .-> U["CBWindow.carPlayUsableBounds"]
 U -. "C" .-> CW["CBWindow.createWindows / resizeWindows / show"]
 BOOT["CBBridgeManager.init / registerForNotifications"] -. "C" .-> REQ["CBBridgeManager.requestStateChange:"]
 REQ -. "I: 0x13b414" .-> LOAD["loadNewAppFromCurrentRequest:"]
 LOAD -. "C" .-> SCENE["CBBridgedApp / CBBridgedUIApp"]
 SCENE -. "C" .-> CW
 LIC["License check (KHÔNG sao chép)"] -. "I" .-> REQ
~~~

**Callsite cụ thể:**
- CBBridgeManager.init: IMP **0x12192c**, selector carPlayUsableBounds, registerForNotifications, effectiveAutoLaunchBundleID, checkAndSyncLicenseIfNeeded.
- CBBridgeManager.requestStateChange: IMP **0x13b158**, tại **0x13b1fc** và **0x13b21c** có checkAndSyncLicenseIfNeeded; tại **0x13b414** có loadNewAppFromCurrentRequest:; tại **0x141244** có show.
- CBWindow.createWindows: IMP **0xb1064**, selector carPlayWindowScene, carPlayUIScreen, carPlayCADisplay, setRootViewController:, setWindowLevel:, carPlayUsableBounds.
- CBWindow.carPlayUsableBounds: IMP **0xb0ef4**, carPlayScreenBounds tại **0xb0f14**, carPlayContentInsets tại **0xb0f34**.
- CBWindow.resizeWindows: IMP **0xb1aac**, nhiều lần gọi carPlayUsableBounds (PC **0xb1b0c, 0xb1b4c, 0xb1b58, 0xb1b74**).

**Ranh giới quan trọng:** CBBridgeManager có cả host và logic giấy phép. Không đưa nguyên nhị phân/class này vào DuoFace; giữ SidePlay host hợp lệ như bên cung cấp app scene trong giai đoạn ghép, đưa Native12 policy vào các lớp UI độc lập.

## 5. Đường B — preset, chia ô, logo và kéo tỷ lệ

~~~mermaid
flowchart TD
 CONFIG["CBDashboardSettings: splitPreset/splitMode/splitRatio/slot IDs"] -. "I" .-> SWITCH["CBBridgeManager.switchToMultiSplitMode:apps:ratio:"]
 SWITCH -. "I: usable bounds" .-> BOUNDS["CBWindow.carPlayUsableBounds"]
 SWITCH -. "I: split initializer" .-> SPLIT["CBBridgedSplitApp"]
 SPLIT -. "I" .-> FRAME["layoutSplitViews / startInParentViewController"]
 SPLIT -. "I" .-> BUTTONS["configureDividerButtons"]
 BUTTONS -. "C: handlers" .-> GRIP["CBDividerView.handlePan:"]
 GRIP -. "I: onPanChanged" .-> PAN["CBBridgedSplitApp.handleDividerPan:isVertical:state:"]
 PAN -. "I" .-> BOUNDS
 PAN -. "I" .-> CONFIG
 PAN -. "I" .-> FRAME
 PAN -. "I" .-> SAVE["saveBridgeStateToDisk / sendStateToApp"]
~~~

**Cơ sở địa chỉ:**

| Phương thức | IMP | Lời gọi quan trọng được quan sát |
|---|---|---|
| CBBridgeManager.switchToSplitWithLeft:right:ratio: | 0x24d120 | switchToMultiSplitMode:apps:ratio: @0x24d1d4 |
| CBBridgeManager.switchToMultiSplitMode:apps:ratio: | 0x24d228 | setSplitRatio: @0x24d4a4; **CBWindow** carPlayUsableBounds @0x254f68; resizeWindows @0x2552a4/0x2552bc/0x2552e0; initWithBundleIdentifier:frame:showSplash: @0x255560 |
| CBBridgedSplitApp.initWithBundleIdentifier:frame:showSplash: | 0x1025e4 | cấu hình presets/mode/ratio, containers/dividers |
| CBBridgedSplitApp.startInParentViewController: | 0x10bb1c | rootVC/frame, layoutSplitViews, startBlinkingSession |
| CBBridgedSplitApp.layoutSplitViews | 0x1044f8 | carPlayUsableBounds, setFocusedMode:, setFrame:, setZPosition:, bringSubviewToFront: |
| CBBridgedSplitApp.configureDividerButtons | 0x1067a4 | carPlayUsableBounds, setOnSwap:, setOnRotate:, configureWithButtonConfigs: |
| CBDividerView.handlePan: | 0x10152c | onPanChanged @0x1015f0 / 0x101610 |
| CBBridgedSplitApp.handleDividerPan:isVertical:state: | 0x103ee0 | **CBWindow** carPlayUsableBounds @0x103f68; setSplitRatio: @0x104100; layoutSplitViews @0x104254; saveBridgeStateToDisk @0x104330 |
| CBBridgedSplitApp.focusSlot:animated: | 0x105890 | saveBridgeStateToDisk, sendStateToApp:shouldBridge:, layoutSplitViews |
| CBBridgedSplitApp.replaceAppInSlot:withBundleIdentifier: | 0x1098c0 | scene dismiss, insertSubview, persistSlotOrder |
| CBBridgedSplitApp.persistSlotOrder | 0x10b4ac | setSplitApp1-4:, setSplitLeftBundleID:, setSplitRightBundleID:, writeToFile:atomically: |

**Kết quả kiến trúc:** Native12 không kéo mỗi thanh chia độc lập rồi chờ SidePlay tự layout. Kéo pan → ghi splitRatio → tính lại CBWindow usable bounds → layout toàn bộ app views → lưu state. Phần tỷ lệ, swap, focus, container, persistence cần **một giao diện điều khiển duy nhất**. Không để SPDash.setRatio/layout cùng lúc tranh quyền CBBridgedSplitApp.

## 6. Đường C — App / Style / Close / Picker

~~~mermaid
flowchart LR
 MENU["CBBridgeManager.showAppPickerForSlot:"] -. "C" .-> WIN["CBWindow.showAppPickerForSlot:"]
 WIN -. "I @0xb2674" .-> O["CBMultitaskingOverlayView.showAppPickerForSlot:parentView:"]
 ST["CBBridgeManager.showLayoutChooser"] -. "C" .-> WS["CBWindow.showLayoutChooser"]
 WS -. "I" .-> OO["CBMultitaskingOverlayView.showLayoutChooserInParentView:"]
 O -. "C: selection" .-> IDS["Selected bundle ID for slot"]
 IDS -. "M2: proven host request only" .-> SP["SidePlay app scene host"]
 IPHONE["DuoFaceUI.CBAppPickerViewController"] -. "settings / app list" .-> PREF["CBAppManager + CBSplitViewController"]
~~~

- CBBridgeManager.showAppPickerForSlot: IMP **0x27fee4**, CBWindow.showAppPickerForSlot: IMP **0xb25e4** và selector showAppPickerForSlot:parentView: tại **0xb2674**.
- CBBridgeManager.showLayoutChooser IMP **0x280014**, CBWindow.showLayoutChooser IMP **0xb2694**, showRecentApps IMP **0xb273c**.
- **CBAppPickerViewController của DuoFaceUI.app là UI picker trên iPhone**, không phải chứng cứ chính nó làm CarPlay overlay. Phải chuyển CBMultitaskingOverlayView (CarPlay) và picker iPhone theo hai đường riêng.
- **Chưa có chứng cứ tham số SPPane.loadApp:** là NSString bundle ID. Type encoding v24@0:8@16 chỉ chứng minh id. M1 đã cố ý bỏ lời gọi truyền NSString chưa được chứng minh. Không nối M2 trước khi xác định đúng kiểu object/callsite.

## 7. Đường D — Apple App Dock ≠ StatusBar ≠ Dock giám sát

~~~mermaid
flowchart LR
 ROOT["CarPlay Dashboard rootVC"] -. "C" .-> DS["CBDashboardShared.appDockVC"]
 DS -. "I" .-> ACT["CBBridgeManagerDashboard.setAppDockActiveBundleID:"]
 ACT -. "I: private selector" .-> APP["Apple AppDockViewController._refreshAppDock"]
 APP -.-> ICON["Apple icon + launcher Dock"]
 MET["CBBridgeManagerDashboard.updateCarPlayMetrics"] -. "C" .-> MEAS["getDockDimension / view.frame"]
 MEAS -. "C" .-> GEO["CBWindow.carPlayContentInsets / usableBounds"]
 CHROME["DFDashboardChrome"] -. "P" .-> STATUS["DB/CARStatusBarWindow"]
 SYS["CBDockSystemMonitorView"] -.-> TEMP["pin / RAM / CPU / nhiệt"]
~~~

**Chứng cứ:** CBDashboardShared.appDockVC IMP **0x1217d8** đọc rootVC @0x121820; CBBridgeManagerDashboard.setAppDockActiveBundleID: IMP **0x2a4934**, class selector appDockVC @**0x2a4968**, selector _refreshAppDock @**0x2a4a08/0x2a4a18**; getDockDimension IMP **0x2a6228** đọc view.frame; updateCarPlayMetrics IMP **0x2a4c24** đọc cả màn, Dock controller và cấu hình vùng.

**Điểm phải dừng nếu thiếu chứng cứ:** một statusbar window hoặc inset bên trái **không tạo được App Dock Apple**. Phải chứng minh tiến trình và CarPlay scene có AppDockVC thật, cùng window z-order. Vì thế QA10/QA11 có code hook class chưa đồng nghĩa thanh Dock đã xuất hiện trên xe.

## 8. Đường E — Zoom, lifecycle, restore

~~~mermaid
flowchart TD
 UI["CBMultitaskingOverlayView / DFPickerZoomMenu"] -. "P: picker.v1" .-> TRAN["DFFullscreenTransport"]
 TRAN -. "P: DFHostSetExpanded" .-> GEO["DFHostGeometry"]
 GEO -. "P: owner check + snapshot" .-> SNAP["CBWindow / content / app host frame"]
 SNAP -. "P" .-> CH["DFDashboardChrome DB/CARStatusBarWindow"]
 TRAN -. "P: state.v1" .-> UI
 GEO -. "P: teardown/owner loss" .-> BACK["DFHostRestore, reattach, original chrome"]
~~~

Có source thật trong repo: runtime/fullscreen/DFFullscreenTransport.mm, DFHostGeometry.xm, DFDashboardChrome.xm, DFPickerZoomMenu.xm. Tên command được thấy cả trong binary: com.duoface.fullscreen.command.v1, picker.v1, state.v1. **FullscreenBridge có 61 ObjC methods và 123 function starts nhưng nhiều gọi qua ObjC optimized stubs chưa biết selector**; sơ đồ ở mục này là theo mã nguồn [P], không mạo nhận disassembly đã chứng minh mọi cạnh.

## 9. HUD8, trợ lý và vùng giấy phép

**HUD8:** DuoFaceSpeedHUD 44 method / 66 function starts, DuoFaceSpeedOwner 1 method / 11 function starts, filter SpringBoard. Binary SpeedHUD có bốn nhãn nguồn com.duoface.speedhud.v1.gofa / .googlemaps / .vietmap / .waze. Những nhãn này **không chứng minh bốn nguồn đã cung cấp dữ liệu thực tế**. Không ghép HUD relay SidePlay cũ khi chưa đánh giá sự cần thiết.

**Trợ lý:** CBAssistantManager (69 selector) thuộc DuoFaceDashboard, các hàm speechSynthesizer, handleNavigationCommand:, handleAppLaunchCommand:, triggerBridgeApp:; không ghép nó với giấy phép/CarPlay host chỉ từ tên hàm.

**License tách khỏi thiết kế mới:** CBBridgeManager.init IMP 0x12192c dùng checkAndSyncLicenseIfNeeded. requestStateChange: IMP 0x13b158 gọi selector license tại 0x13b1fc/0x13b21c; cùng class còn licenseWatchdogTimerFired:, scheduleMandatoryDisconnectWatchdog, enforceMandatoryDisconnectKill, presentLicenseWarningModalWithType:. DuoFaceUI.XXAppDelegate.application:didFinishLaunchingWithOptions: IMP **0x100007314** có checkAndSyncLicenseIfNeededWithSource: @**0x10000751c**. Không sao chép nguyên lớp/binary có license; cũng không sửa hay vô hiệu hóa giấy phép hợp lệ của SidePlay.

## 10. Trình tự nối và tiêu chí dừng — KHÔNG chuyển khi thiếu owner

| Giai đoạn | DuoFace Native12 là chuẩn | Phần SidePlay được phép giữ | GO / NO-GO |
|---|---|---|---|
| **M0: audit (lượt này)** | Đủ 8 Mach-O; method, PC, selector, process filter và sơ đồ; phân biệt C/P/R | Không thay runtime | Số lượng/hash/IMP có thể tái lập, lỗ hổng ghi rõ |
| **M1: read-only bridge (đã có trước)** | Hai slot + CGRect đi vào shell Native12 | SPDash.panes/SPPane.view/appViewController còn sống | Theos compile PASS; **chưa test scene trên xe** |
| **M2: App picker/menu** | CBMultitaskingOverlayView + UI slot picker là một owner | Chỉ lời gọi host open được xác minh đối tượng tham số | Chọn/mở/đóng 2 app thật; sau khi pass mới bỏ SidePlay picker |
| **M3: split/ratio/logo** | CBBridgedSplitApp + CBDividerView + persistence/focus | Chỉ hosting view/scene | Kéo, swap, ratio, frame, reconnect đạt; rồi bỏ SPDash.setRatio/layout/UI |
| **M4: Dock/Normal/Zoom** | CBDashboardShared.appDockVC + CBWindow usable bounds + fullscreen restore | CarPlay scene host hợp lệ | Normal thấy toàn bộ Apple Dock, Zoom và restore đúng trên xe, không fake |
| **M5: Style/HUD8/settings** | Native12/Visual12/HUD8/iPhone prefs duy nhất | Không SidePlay UI/HUD trùng | Không còn nút/viền/menu/hud thừa |
| **M6: cleanup** | DuoFace UI/controller là sản phẩm | Giữ SidePlay host provider hợp lệ nếu còn cần | File/UI legacy bỏ sau nghiệm thu, không can thiệp giấy phép |

**Các khoảng trống cần điều tra bằng lần chạy thật:** SidePlay loadApp: nhận đối tượng gì; SP scene owner có thể tách UI được bao nhiêu; Dock App VC đang tạo ở process nào và có bị window SidePlay che; điều kiện callback/IPC cross-process; optimized objc_stubs trong Fullscreen/HUD; các đường C/callback không được giải từ selector. Không tự gọi thứ chưa được chứng minh.

## 11. Tài liệu và khả năng phục hồi

- sideplay/audit/native12-wiring-20261019/SUMMARY.json — số đo 8 Mach-O, SHA của từng tệp.
- sideplay/audit/native12-wiring-20261019/[MachO].json.gz — **toàn bộ các method IMP đã quét**, callsite PC, receiver, confidence, ứng viên target, hàm C không có ObjC metadata.
- sideplay/audit/native12-wiring-20261019/FOCUSED_METHODS.json.gz — trích nhanh các đường host/split/Dock/menu/HUD.
- sideplay/tools/audit_native12_macho_wiring.py — script tái lập.
- .github/workflows/native12-full-function-wiring-audit.yml — CI macos-15; chỉ static audit, không build/test/deploy DuoFace mới.
- Source nghiệp vụ đã xác minh: runtime/fullscreen/DFHostGeometry.xm, DFFullscreenTransport.mm, DFDashboardChrome.xm, DFPickerZoomMenu.xm.

**Quyết định:** Sau khi kiểm tra báo cáo và những chỗ chưa giải quyết, chỉ nối một chức năng khi biết 4 điểm: **caller → selector → receiver/owner → lifecycle/rollback**. Giữ Native12 ổn định, QA11 Sileo và SidePlay hiện có làm nguồn so sánh; tuyệt đối không gọi CI xanh là CarPlay UI thành công.
