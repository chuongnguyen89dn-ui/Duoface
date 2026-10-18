# Kiểm toán toàn hệ SidePlay 1.0.4 ↔ DuoFace Native12 + HUD8 và thực trạng QA7
<sub>Kiểm tra tĩnh từ ba DEB rootless đã xác minh SHA-256, ngày 18/10/2026; không triển khai hoặc đổi package.</sub>

## 1. Kết luận có căn cứ

1. **SidePlay và Native12/HUD8 là hai kiến trúc host CarPlay khác nhau.** SidePlay đăng ký `CPTemplateApplicationScene` qua `SPCarSceneDelegate` trong `SidePlay.app`, giữ `SPDash/SPPane` làm owner. Native12 dùng `CBBridgeManager/CBWindow/CBBridgedSplitApp` và các module hook SpringBoard, CarPlay/Dashboard + app đích. App `DuoFaceUI.app` trong Native12 không đăng ký CarPlay template scene trong `Info.plist`.
2. **QA7 hiện tại chưa thay hoàn toàn UI SidePlay.** QA7 là tweak inject chỉ SpringBoard; `%hook SPDash` còn `%orig`; chỉ `hidden=YES` một số `chipView/layoutButton` + placeholder. App và Style vẫn đi qua `SPDash.showPickerForPane:` / `layoutChooser`. Cài QA7 không gỡ `SidePlay.app/dylib/prefs/HUD`.
3. **Thanh CarPlay vẫn thiếu theo user:** native có `CBWindow.carPlayContentInsets/carPlayUsableBounds` và adapter `DFDashboardChrome.xm` với `DBStatusBarWindow/CARStatusBarWindow` + ACK khi Zoom. QA7 chỉ sửa `rootView.frame`/`windowLevel` trong SpringBoard, không có Chrome receiver ở CarPlay/Dashboard. Đây là **thiếu kết nối cấp tiến trình**, không sửa được chỉ bằng lề 64pt hay đổi ảnh; subclass thực đang ẩn thanh chưa thể xác định nếu không có log máy.
4. **Bộ HUD khác hoàn toàn.** SidePlay có HUD providers ở tiến trình GOFA, VietMap, Waze và relay SpringBoard. Native12/HUD8 có `DFSpeedNativeHUD` + owner SpringBoard. QA7 chưa có module HUD8. Tên `selectedSource` Native không chứng minh tự động kết nối được với tất cả nguồn SidePlay.
5. **Cần loại trừ giấy phép:** Native `CBBridgeManager` bao gồm `licenseWatchdogTimerFired:`, `scheduleMandatoryDisconnectWatchdog`, `enforceMandatoryDisconnectKill` cùng lớp host; **không sao chép nguyên class** sang DuoFace độc lập. SidePlay có `serviceBlocked/serviceChecked`, chưa chứng minh là cơ chế giấy phép; không đưa nhận định không có chứng cứ.
6. **Không có class Objective-C trùng tên giữa ba hệ**, nhưng SidePlay, QA7 và (nếu Native12 được cài đồng thời) các tweak Native đều có thể inject SpringBoard. Không suy luận được xung đột runtime từ tên class; cần xác minh danh sách gói thật trên máy, filter và log cùng tiến trình.

## 2. Mẫu DEB và phạm vi quét

| Runtime | Gói | File payload | Mach-O | ObjC methods | Class unique | Function starts |
|---|---|---:|---:|---:|---:|---:|
| SidePlay gốc | `com.sideplay 1.0.4-1` | 136 | 7 | 863 | 38 | 1851 |
| Native12+HUD8 | `com.duoface.independent 0.1.0~native12+speed8compact` | 43 | 8 | 1385 | 66 | 2509 |
| DuoFace QA7 | `com.duoface.sideplaydisplay 0.1.5~native12visual7` | 6 | 1 | 110 | 4 | 144 |

**SHA-256 gói:** SidePlay `7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c`; Native12+HUD8 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`; QA7 `c221584b16af24f844dbb968d90ffbcd6efbbc64a312a6582d955fc45348901d`. Toàn bộ ba DEB đã giải nén bằng `dpkg-deb -x/-e` **không chạy maintainer scripts**. Đọc trực tiếp payload (không chỉ từ tên file) và đối chiếu với [method-index.json](../qa7-vs-native12-methods-20261018/method-index.json), lần quét [Actions #39136991320](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39136991320) **SUCCESS**. Danh mục `FUNCTION_CLASS_CROSSWALK.json` chứa **tất cả selector** của class thuộc 13 nhóm bên dưới. Function-start offsets bao gồm hàm C/C++ chưa giải mã logic; không xem 0 ObjC methods là không có mã.

**Lưu ý định danh:** không tìm thấy gói DEB riêng có tên Native8 trong checkpoint/nhánh đã tra. Trong hồ sơ này “Native/HUD8” là đúng bản Native12 kết hợp Speed8Compact, **không tự gán thành Native8 độc lập**.

## 3. Bộ lọc nạp tweak và quyền sở hữu tiến trình

| Hệ/gói con | Bộ lọc thật từ DEB | Vai trò có chứng cứ |
|---|---|---|
| SidePlay.app | `com.sideplay.app`, scene `CPTemplateApplicationScene` và delegate `SPCarSceneDelegate` | Đăng ký CarPlay session và kết nối CarPlay template interface |
| SidePlay.dylib | `Bundles=(com.apple.springboard, com.apple.UIKit)` | `SPDash/SPPane`, bridge, layout, app scene, thao tác input |
| SidePlayHUDRelay.dylib | `Bundles=(com.apple.springboard)` | Relay HUD ở SpringBoard |
| SidePlayHUDGofa.dylib | `Bundles=(com.lumi.GOFA)` | Lấy dữ liệu nguồn GOFA |
| SidePlayHUDVietMap.dylib | `Bundles=(vn.vietmap.live)` | Lấy dữ liệu nguồn VietMap |
| SidePlayHUDWaze.dylib | `Bundles=(com.waze.iphone)` | Lấy dữ liệu nguồn Waze |
| Native DuoFaceDashboard.dylib | SpringBoard, CarPlay/Dashboard, `com.duoface.duofaceui` và nhiều app đích như YouTube, Maps, Waze, VLC... | Native host và app bridge, multi-split, chrome |
| Native DuoFaceFullscreenBridge.dylib | `Bundles=(com.apple.CarPlayApp,com.apple.CarPlay,com.apple.dashboard,com.apple.springboard)`, `Executables=(CarPlay,CarPlayApp,Dashboard,SpringBoard)` | Cross-process fullscreen/ACK coordinator |
| Native DuoFaceLogoGripOnly.dylib | SpringBoard, CarPlay/Dashboard và DuoFaceUI | Logo grip hook |
| Native DuoFaceVisualHook.dylib | SpringBoard, CarPlay/Dashboard và DuoFaceUI | Viền/pill/layout visual hooks |
| Native DuoFaceSpeedHUD.dylib, DuoFaceSpeedOwner.dylib | `Executables=(SpringBoard)` | Native HUD8 display + owner |
| QA7 DuoFaceSidePlayDisplayQA.dylib | `Bundles=(com.apple.springboard)` | Chỉ overlay/vẽ và gọi SidePlay host, **không chạy ở CarPlay/Dashboard** |

**Hệ quả:** QA7 không có cơ chế đối thoại với **status bar window của tiến trình CarPlay**. `SPPane.barHidden`, `scheduleBarHide`, `slideBarHidden:` là tên phương thức xử lý bar ở pane SidePlay; **chưa chứng minh** đó là thanh hệ thống CarPlay, không được gán làm đáp án cho lỗi bar mất.

## 4. Mười ba nhóm chức năng — đối chiếu đến class/selector

| Mã | Chức năng | Native12+HUD8 | SidePlay 1.0.4 | QA7 | Mức |
|---|---|---|---|---|---|
| HOST | Khởi động/CarPlay scene và host | `CBBridgeManager`(75), `CBBridgedUIApp`(16), `CBWindow`(37), `XXAppDelegate`(6) | `SPAppDelegate`(2), `SPCarSceneDelegate`(6), `SPDash`(154), `SPPane`(127) | `DFSPNative12Host`(20), `DFSPNativeAdapter`(8) | P0 |
| CHROME | CarPlay system bar/dock/normal/fullscreen | `CBWindow`(37), `CBDashboardShared`(12), `CBDockSystemMonitorView`(19), `DFFullscreenTransport`(36), `DFHostSnapshot`(23) | `SPDash`(154), `SPPane`(127) | `DFSPNative12Host`(20), `DFSPNativeFrame`(60) | P0 |
| GEOMETRY | Vùng nội dung CarPlay và chuyển scene-frame | `CBWindow`(37), `CBBridgedSplitApp`(49), `CBUIAppContainerView`(6) | `SPDash`(154), `SPPane`(127) | `DFSPNative12Host`(20), `DFSPNativeFrame`(60) | P0 |
| SPLIT | Bố cục/đa ô/ratio/hoán đổi | `CBBridgedSplitApp`(49), `CBSplitContainerView`(6), `CBDashboardSettings`(61) | `SPDash`(154), `SPDashCard`(12), `SPDashQuick`(16), `SPPane`(127) | `DFSPNativeFrame`(60), `DFSPNativeAdapter`(8) | P1 |
| DIVIDER | Thanh chia, kéo tỷ lệ, logo hold/tap | `CBDividerView`(27), `CBDividerButtonInfo`(9), `CBBridgedSplitApp`(49) | `SPDash`(154), `SPPane`(127) | `DFSPNativeFrame`(60), `DFSPNativeAdapter`(8) | P1 |
| PILL | Pill per-pane, focus và hit testing | `CBSlotPillView`(36), `CBSlotPillHitButton`(3), `CBBridgedSplitApp`(49) | `SPPane`(127), `SPDash`(154) | `DFSPNativeSlotPill`(22), `DFSPNativeFrame`(60) | P1 |
| PICKER | App picker, Recent, Style, Close | `CBMultitaskingOverlayView`(66), `CBAppPickerViewController`(16), `CBBridgeManager`(75) | `SPDash`(154), `SPLauncherViewController`(142) | `DFSPNativeFrame`(60), `DFSPNativeAdapter`(8) | P1 |
| STARTUP | Splash/loading và initial layout | `CBSplitSplashScreenView`(32), `CBBridgedSplitApp`(49) | `SPLoadingView`(41), `SPDash`(154), `SPPane`(127) | `DFSPNativeFrame`(60) | P1 |
| BORDER | Đường viền/tín hiệu người dùng | `CBBridgedSplitApp`(49), `CBDividerView`(27) | `SPPane`(127), `SPDash`(154) | `DFSPNativeFrame`(60) | P1 |
| HUD | HUD8 tốc độ, datasource/relay, định vị bong bóng | `DFSpeedNativeHUD`(43), `DFSpeedSplit7Driver`(1), `DFOwnerPollingDriver`(1) | `SPHLocationSession`(67), `SPHOutputEndpoint`(10), `SPHOutputEndpointSidePlay`(2), `SPHNavSource`(6), `SPHWazeOutputStore`(6), `SPHudGestures`(4), `SPHSpeedCardSidePlay`(19) | Không có class riêng | P1 |
| SETTINGS | Cấu hình iPhone và lưu trạng thái | `CBDashboardSettings`(61), `CBGeneralSettingsViewController`(30), `CBAppManager`(21) | `SPRootListController`(9), `SPHPreferencesController`(9), `SPAppSettingsController`(8), `SPDash`(154) | Không có class riêng | P1 |
| EXIT | Close/scene disconnect/respring/softReload | `CBBridgeManager`(75), `CBWindow`(37), `CBBridgedSplitApp`(49) | `SPDash`(154), `SPPane`(127), `SPCarSceneDelegate`(6) | `DFSPNative12Host`(20), `DFSPNativeAdapter`(8) | P0 |
| LICENSE | Giấy phép, dịch vụ và phần không được sao chép | `CBBridgeManager`(75), `CBLicenseSyncManager`(60), `CBLicenseWarningModalView`(12) | `SPDash`(154), `SPReportViewController`(30) | Không có class riêng | P0 |

**Quy ước:** class có thể nằm ở nhiều nhóm chức năng; đừng cộng các số trong bảng để suy ra tổng số method hay phần trăm đã chuyển.


### HOST — Khởi động/CarPlay scene và host

**Khác biệt:** SidePlay đăng ký CPTemplateApplicationScene + SPCarSceneDelegate; Native12 tách SpringBoard/CarPlay Dashboard host. QA7 vẫn giữ SPDash/SPPane làm owner, không phải standalone CarBridge.

**Selector Native12:** `acquireCarPlaySleepAssertion`, `appForBundleIdentifier:frame:`, `appFrame`, `cancelMandatoryDisconnectWatchdog`, `collectActiveAndSessionAppBundleIDs`, `currentApp`, `deactivateCurrentApp`, `dismissLicenseWarningModal`, `enforceMandatoryDisconnectKill`, `evictAppFromPhoneScreen:completion:`, `handleCarPlayConnectionChanged:`.

**Selector SidePlay:** `application:configurationForConnectingSceneSession:options:`, `application:didFinishLaunchingWithOptions:`, `sceneDidBecomeActive:`, `setInterfaceController:`, `templateApplicationScene:didConnectInterfaceController:`, `templateApplicationScene:didDisconnectInterfaceController:`, `animateCardsIn`, `applyServiceState`, `autoCarArea:`, `autoOpenOnCar:`, `buildPickerForPane:`.


### CHROME — CarPlay system bar/dock/normal/fullscreen

**Khác biệt:** QA7 chỉ làm root frame + windowLevel; không sở hữu/ACK cửa sổ DBStatusBarWindow/CARStatusBarWindow. SidePlay có carDockMode/carDockArea/carWindowFrameNow, QA7 không sử dụng để xác nhận dock.

**Selector Native12:** `activeCarPlayWindow`, `carPlayCADisplay`, `carPlayContentInsets`, `carPlayScreenBounds`, `carPlayScreenScale`, `carPlayUIScreen`, `carPlayUsableBounds`, `carPlayWindowScene`, `appFrame`, `createWindows`, `destroyWindows`.

**Selector SidePlay:** `animateCardsIn`, `applyServiceState`, `autoCarArea:`, `autoOpenOnCar:`, `buildPickerForPane:`, `calibrationPending`, `calibrationView`, `canvasTapped:`, `carAreaChanged`, `carConnectedState`, `carDockArea`.


### GEOMETRY — Vùng nội dung CarPlay và chuyển scene-frame

**Khác biệt:** Native12 carPlayContentInsets/carPlayUsableBounds/resizeWindows; SidePlay geometry riêng applySceneFrame/enforceSceneGeometry; QA7 lấy safeAreaInsets với fallback trái 64pt, không có contract chung.

**Selector Native12:** `activeCarPlayWindow`, `carPlayCADisplay`, `carPlayContentInsets`, `carPlayScreenBounds`, `carPlayScreenScale`, `carPlayUIScreen`, `carPlayUsableBounds`, `carPlayWindowScene`, `appFrame`, `createWindows`, `destroyWindows`.

**Selector SidePlay:** `animateCardsIn`, `applyServiceState`, `autoCarArea:`, `autoOpenOnCar:`, `buildPickerForPane:`, `calibrationPending`, `calibrationView`, `canvasTapped:`, `carAreaChanged`, `carConnectedState`, `carDockArea`.


### SPLIT — Bố cục/đa ô/ratio/hoán đổi

**Khác biệt:** Native12 có splitPreset, switchToMultiSplitMode, splitApp1-4 và callbacks đổi ô; QA7 chỉ dùng 2 SPPane/ratio và gọi SidePlay layoutChooser, chưa tái hiện đủ các kiểu Native12.

**Selector Native12:** `appViews`, `focusSlot:animated:`, `focusedSlotIndex`, `handleDividerPan:isVertical:state:`, `handleDividerSwapPressed:`, `initWithBundleIdentifier:frame:`, `initWithBundleIdentifier:frame:showSplash:`, `isTransitioningFocus`, `layoutSplitViews`, `removeAppWithBundleIdentifier:`, `replaceAppInSlot:withBundleIdentifier:`.

**Selector SidePlay:** `animateCardsIn`, `applyServiceState`, `autoCarArea:`, `autoOpenOnCar:`, `buildPickerForPane:`, `calibrationPending`, `calibrationView`, `canvasTapped:`, `carAreaChanged`, `carConnectedState`, `carDockArea`.


### DIVIDER — Thanh chia, kéo tỷ lệ, logo hold/tap

**Khác biệt:** QA7 có track/logo riêng nhưng tỷ lệ logic thuộc SidePlay; tính mid-line theo maxX(a)+minX(b) sai nếu thứ tự pane đảo và tỷ lệ lệch.

**Selector Native12:** `handlePan:`, `initWithFrame:isVertical:`, `layoutSubviews`, `onPanChanged`, `setButtonConfigs:`, `setIsBlinking:`, `setIsVertical:`, `setMoveButtons:`, `setOnActivity:`, `setOnPanChanged:`, `updateGripLayout`.

**Selector SidePlay:** `animateCardsIn`, `applyServiceState`, `autoCarArea:`, `autoOpenOnCar:`, `buildPickerForPane:`, `calibrationPending`, `calibrationView`, `canvasTapped:`, `carAreaChanged`, `carConnectedState`, `carDockArea`.


### PILL — Pill per-pane, focus và hit testing

**Khác biệt:** QA7 tự vẽ 2 pill, nhưng chỉ ẩn chipView/layoutButton của SidePlay và vẫn dựa callback SPDash; chưa tương đương native hit targets/gesture.

**Selector Native12:** `dotsTapped:`, `expandButton`, `expandTapped:`, `initWithSlotIndex:`, `isFocusedMode`, `layoutSubviews`, `onExpandTapped`, `onPillTapped`, `onRestoreTapped`, `restoreButton`, `restoreTapped:`.

**Selector SidePlay:** `appDidLaunchWithTransaction:`, `appReportedOrientation`, `appViewController`, `application`, `applySceneFrame:`, `applySceneOrientation:`, `barHidden`, `barToken`, `checkSettled:run:tick:`, `closeTapped`, `enforceSceneGeometry`.


### PICKER — App picker, Recent, Style, Close

**Khác biệt:** QA7 menu App gọi SPDash.showPickerForPane, Style gọi SPDash.layoutChooser; native recent/presets/card list và close-all không được chuyển.

**Selector Native12:** `addMoreAppsTapped:`, `allApps`, `appPickerPageControl`, `appPickerScrollView`, `appSegmentBtn`, `appSelected:`, `cardShadowContainer`, `closeAllBridgedAppsTapped:`, `closeSingleAppTapped:`, `currentRatio`, `initWithFrame:`.

**Selector SidePlay:** `animateCardsIn`, `applyServiceState`, `autoCarArea:`, `autoOpenOnCar:`, `buildPickerForPane:`, `calibrationPending`, `calibrationView`, `canvasTapped:`, `carAreaChanged`, `carConnectedState`, `carDockArea`.


### STARTUP — Splash/loading và initial layout

**Khác biệt:** Native12 có CBSplitSplashScreenView và owner startup; SidePlay có SPLoadingView/buildViews; QA7 chỉ gắn visual overlay sau khi SPDash window xuất hiện.

**Selector Native12:** `appIconImage`, `initWithFrame:`, `layoutSubviews`, `setOnDismissed:`, `setOnWillDismiss:`, `appViews`, `focusSlot:animated:`, `focusedSlotIndex`, `handleDividerPan:isVertical:state:`, `handleDividerSwapPressed:`, `initWithBundleIdentifier:frame:`.

**Selector SidePlay:** `initWithFrame:`, `layoutSubviews`, `setAnimatingBlock:`, `setArc:`, `setBlock:`, `setBlockScale:`, `setGlow:`, `setGrid:`, `setGridMask:`, `setIconView:`, `setNameLabel:`.


### BORDER — Đường viền/tín hiệu người dùng

**Khác biệt:** Native12 có source DuoFaceBorderRunner: RGB(227,2,15), 1pt, bật theo interaction/idle, không viền fullscreen; QA7 chưa có owner/timer activity tương đương.

**Selector Native12:** `appViews`, `focusSlot:animated:`, `focusedSlotIndex`, `handleDividerPan:isVertical:state:`, `handleDividerSwapPressed:`, `initWithBundleIdentifier:frame:`, `initWithBundleIdentifier:frame:showSplash:`, `isTransitioningFocus`, `layoutSplitViews`, `removeAppWithBundleIdentifier:`, `replaceAppInSlot:withBundleIdentifier:`.

**Selector SidePlay:** `appDidLaunchWithTransaction:`, `appReportedOrientation`, `appViewController`, `application`, `applySceneFrame:`, `applySceneOrientation:`, `barHidden`, `barToken`, `checkSettled:run:tick:`, `closeTapped`, `enforceSceneGeometry`.


### HUD — HUD8 tốc độ, datasource/relay, định vị bong bóng

**Khác biệt:** Native12 có HUD8 native owner SpringBoard và selectedSource/settings/position; SidePlay có 4 dylib Gofa/Relay/VietMap/Waze theo tiến trình; QA7 không cài HUD8, không thể xem SidePlay HUD tương đương.

**Selector Native12:** `didMoveToWindow`, `initWithFrame:`, `layoutSubviews`, `loadSettings`, `pan:`, `refreshSettingsLabels`, `restoreSavedPosition`, `savePosition`, `saveSettings`, `selectedSource`, `setCurrent:`.

**Selector SidePlay:** `applied`, `distanceApplied`, `setApplied:`, `setCallbacks:`, `setDistanceApplied:`, `setForcedRunning:`, `setLastLog:`, `setManager:`, `setRequestedBackground:`, `setRequestedDistance:`, `setRequestedIndicator:`.


### SETTINGS — Cấu hình iPhone và lưu trạng thái

**Khác biệt:** Native có DuoFaceUI.app, prefs app1-4, split preset; SidePlay có SidePlayPrefs bundle; QA7 không có app/prefs độc lập.

**Selector Native12:** `portalAppIconImage`, `portalAppIdentifier`, `splitScreenIconImage`, `appSettings`, `autoLaunchOnConnect`, `bridgedApps`, `dockSystemMonitorEnabled`, `dockSystemMonitorShowAll`, `hideIconLabels`, `portalAppEnabled`, `reloadAppPrefs`.

**Selector SidePlay:** `calibrateCar`, `setPreferenceValue:specifier:`, `setSourceSpecifier:`, `sourceSpecifier`, `viewWillAppear:`, `appID`, `resetApp`, `setting:dict:cell:`, `animateCardsIn`, `applyServiceState`, `autoCarArea:`.


### EXIT — Close/scene disconnect/respring/softReload

**Khác biệt:** Native có state/owner lifecycle; SidePlay có retireCarWindow, sceneMonitor, softReload, reconnect; QA7 chỉ restore overlay/frames, exitmode chưa device-pass.

**Selector Native12:** `acquireCarPlaySleepAssertion`, `appForBundleIdentifier:frame:`, `appFrame`, `cancelMandatoryDisconnectWatchdog`, `collectActiveAndSessionAppBundleIDs`, `currentApp`, `deactivateCurrentApp`, `dismissLicenseWarningModal`, `enforceMandatoryDisconnectKill`, `evictAppFromPhoneScreen:completion:`, `handleCarPlayConnectionChanged:`.

**Selector SidePlay:** `animateCardsIn`, `applyServiceState`, `autoCarArea:`, `autoOpenOnCar:`, `buildPickerForPane:`, `calibrationPending`, `calibrationView`, `canvasTapped:`, `carAreaChanged`, `carConnectedState`, `carDockArea`.


### LICENSE — Giấy phép, dịch vụ và phần không được sao chép

**Khác biệt:** Native CBBridgeManager chứa đồng thời hàm host và licenseWatchdogTimer/mandatoryDisconnect; không chuyển nguyên class/license runtime sang app độc lập. SidePlay cũng có các selector serviceChecked/Blocked, không suy ra đó là license.

**Selector Native12:** `acquireCarPlaySleepAssertion`, `appForBundleIdentifier:frame:`, `appFrame`, `cancelMandatoryDisconnectWatchdog`, `collectActiveAndSessionAppBundleIDs`, `currentApp`, `deactivateCurrentApp`, `dismissLicenseWarningModal`, `enforceMandatoryDisconnectKill`, `evictAppFromPhoneScreen:completion:`, `handleCarPlayConnectionChanged:`.

**Selector SidePlay:** `animateCardsIn`, `applyServiceState`, `autoCarArea:`, `autoOpenOnCar:`, `buildPickerForPane:`, `calibrationPending`, `calibrationView`, `canvasTapped:`, `carAreaChanged`, `carConnectedState`, `carDockArea`.

## 5. Các điểm cụ thể gây mất tính tương đồng QA7

- **Vùng dock/bar:** Source QA7 khai báo `SPDash.carWindowFrameNow` và `setCarWindowFrame:` nhưng có **0 lần nhắc ở thân implementation** sau khi loại `@interface`/comment; tương tự `carDockMode` và `carDockArea` không được dùng trong đường tính vùng hữu dụng. QA7 tự lấy `safeAreaInsets`, fallback **64 pt bên trái**. QA7 `applyNormal` điều chỉnh `contentRoot.frame` và `windowLevel`, **không đăng ký observer/hook statusBarWindow**.
- **Chồng giao diện:** `%hook SPDash.layout:/layoutRootView/setCarWindow:` vẫn `%orig`; `DFSPHideReplacedView` chỉ `hidden=YES` khi overlay đã mount và có thể restore. Khởi động SidePlay gốc `SPLoadingView`, chooser/picker SidePlay và HUD SidePlay không bị xóa/thay thế.
- **Style/8 layouts:** Native `CBBridgedSplitApp.splitPreset/setSplitRatio:/rotateAllSlotsClockwise`, `CBBridgeManager.switchToMultiSplitMode:apps:ratio:`, `CBDashboardSettings.splitApp1..4`; QA7 chỉ có 2 pill, 1 ratio SidePlay `SPDash.layoutChooser`. Không lấy tên 8 styles làm bằng chứng đã vẽ đủ.
- **Divider:** QA7 `DFSPNativeFrame.layoutSubviews` tính line x bằng `(maxX(pane0)+minX(pane1))/2`; sai nếu pane0 nằm phải pane1 với ratio khác 1/2; pan ratio tính từ origin của union theo giả định pane0 trái/trên, đảo pane cần map lại. Thao tác logo giữ 0.30 giây là riêng với kéo line, song cần nghiệm thu hit-test.
- **HUD:** Native `DFSpeedNativeHUD` có 43 method, lưu vị trí, `selectedSource`, settings; SidePlay có nguồn app-specific injection và relay riêng + 112 icon ảnh HUD. QA7 không mang driver Native; một HUD SidePlay đang thấy không chứng minh HUD8 hoạt động.
- **Startup/sự cố scene:** SidePlay `SPDash.retireCarWindow/carScene:foreground:` và `SPPane.sceneMonitor:sceneWasDestroyed:/softReload/enforceSceneGeometry`; Native `CBBridgeManager.handleScreenDidDisconnect` và `CBWindow.destroyWindows`; QA7 chỉ attach overlay và restore viewport. Không tuyên bố hết exitmode/respring crash khi chưa có log.
- **License coupling:** Native `CBBridgeManager` vừa host app vừa có watchdog giấy phép; không thể clone nguyên lõi đó mà nói DuoFace độc lập. SidePlay `prerm` nếu remove có lệnh chạy app `--sp-goodbye`; đây là hành vi package lifecycle đã đọc thấy, **không chạy script**.

## 6. Tài nguyên hình ảnh & cài đặt

| Nhóm | Tổng PNG | Nội dung từ payload |
|---|---:|---|
| Native12+HUD8 | 25 | 18 app icons trên iPhone + 7 logo/visual assets (logo ngang 960×240; logo dọc 640×640; logo picker 627×228; icon 256²; swap 120²; fullscreen 88²; picker 256×70) |
| SidePlay | 119 | 112 ảnh nằm trong `usr/share/sideplay-hud` + 7 icon/app/preferences |
| QA7 | 4 | `duoface-logo-picker-alpha-v2.png` 627×228, `duoface-fullscreen.png` 88×88, `duoface-picker.png` 256×70, `duoface-swap.png` 120×120 |

Cả **4 PNG của QA7 trùng SHA256 byte-với-byte** với bốn asset Native tương ứng; phần còn thiếu chủ yếu là **owner/control logic và asset khác**, không phải các file đã chuyển sai pixel. Không giả định toàn bộ 21 ảnh Native còn thiếu đều là thành phần CarPlay; phần lớn là icon iPhone.

**Gói & maintainer:** Native12 có `preinst` chặn ghi đè file của package khác và `postinst` yêu cầu uicache; SidePlay có `postinst` đăng ký app qua uicache và `prerm` hỗ trợ unregister/--sp-goodbye. QA7 không có maintainer script. Không có giao dịch cài đặt/gỡ gói nào được thực thi trong quá trình kiểm toán.

## 7. Phân định trùng lặp và trình tự chỉnh sửa có thể kiểm chứng

- **P0 / kiểm thử read-only:** lấy Installed package list trên iPhone để biết SidePlay/Native/QA7 nào thật sự cùng inject SpringBoard; ghi process ID, `UIWindow` class, frame, safeArea, bar owner, `hidden`, `carDockMode` và `carWindowFrameNow` sau khi kết nối CarPlay. Không sửa statusbar.hidden hoặc windowFrame bằng giá trị phỏng đoán.
- **P0 / thiết kế sửa:** tạo bridge chrome có ACK và owner hợp pháp, tách editor UI khỏi scene host; không xóa hook SidePlay khi chưa có native independent host; giữ QA7 ổn định.
- **P1 / UI parity:** dựng thống nhất Native12 equivalent cho app picker/recent/Style, ratios/presets, 2 pill đúng ô, divider khi đảo pane, splash, touch red border/idle, bubble HUD8 và settings iPhone. Mỗi mục có test case và diff hình ảnh.
- **P1 / lifecycle:** disconnect/respring/reconnect phải restore scene/overlay/hidden states, không nhân đôi HUD, không exitmode.
- **Nghiệm thu thực:** CarPlay Normal có bar hệ thống, Zoom không che thanh tùy chế độ, App/Style và split ratio đạt đúng hành vi, cả hai app live/touch, HUD ở owner đúng, không crash. Static class/selector count hoặc CI build xanh **không** thay thế nghiệm thu thiết bị.

## 8. Nguồn/đường dẫn và giới hạn kết luận

- **Binary method data:** [method-index.json](../qa7-vs-native12-methods-20261018/method-index.json), [METHOD_AUDIT.md](../qa7-vs-native12-methods-20261018/METHOD_AUDIT.md), run **39136991320** (success), sideplay **154 SPDash**/**127 SPPane**, native **37 CBWindow**, QA7 110 methods, đều đã kiểm.
- **Bao phủ trực tiếp chức năng:** [FUNCTION_CLASS_CROSSWALK.json](./FUNCTION_CLASS_CROSSWALK.json), có **13 nhóm + mọi selector của từng class**, SHA chứng cứ.
- **Source handlers:** `sideplay/sileo-qa/Tweak.xm` ở `beafe5b6ab020859b82e627ca635046796d9d956`, `runtime/fullscreen/DFDashboardChrome.xm`, `DFHostGeometry.xm`, `DFFullscreenCoordinator.mm`, `src/DuoFaceBorderRunner.m`, `runtime/speedbubble/DFSpeedNativeSplit8SpringBoard.mm`. Đây là những file truy xuất được, không có mã nguồn SidePlay 1.0.4 đầy đủ trong DEB.
- **Phân biệt điều xác minh:** đã kiểm tất cả file DEB/method metadata/khai báo cấu hình/filter và các đoạn source; chưa disassemble toàn bộ native instructions hoặc truy vết call-graph máy và chưa chạy CarPlay thật. **Suy đoán nguyên nhân cụ thể bar đang bị ẩn bởi class nào là chưa chứng minh**; thiếu chrome owner/ACK trong QA7 là sự thật source-level.
- **Không thay đổi:** Native12/HUD8 ổn định, SidePlay 1.0.4 gốc, QA7 Sileo, các gói khác. Không build DEB hay cài đặt.
