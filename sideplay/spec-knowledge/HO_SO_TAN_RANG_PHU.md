# HỒ SƠ TẬN RĂNG — CÁC BINARY PHỤ CỦA GỐC + APP DUOFACEUI + ĐUÔI CHỨC NĂNG DASHBOARD

Bổ sung cho bộ hồ sơ tận răng (hình học / portal / vòng đời / bảng hook).
Đọc từ disassembly + trích selref trực tiếp từ Mach-O.

## 1. DuoFaceFullscreenBridge (107.744 B) — kênh lệnh fullscreen có lease
- 4 class: DFFullscreenTransport (bus lệnh), DFHostSnapshot (mô hình khôi phục),
  DFZoomAction (nút bấm 1 method `pressed:`), DFZoomReceiver (`received:`).
- **10 hook** (trích đủ class/selector/IMP): trên class của CHÍNH Dashboard —
  CBWindow: `+carPlayUsableBounds` (ghi đè usable bounds khi fullscreen!),
  `resizeWindows`, `show`, `hide:`, `destroyWindows`; CBBridgeManager:
  `deactivateCurrentApp`; DBStatusBarWindow + CARStatusBarWindow:
  `layoutSubviews`; CBMultitaskingOverlayView: `setupCardContent`,
  `layoutSubviews`. Tức FB là vệ tinh điều phối chế độ phóng to một app
  trong split lên toàn màn, bám vào vòng đời cửa sổ của Dashboard.
- Transport (`send:enabled:requestID:` IMP 0x5cc4, `handleCommand:` 0x6320 đã
  đọc): lệnh là dictionary {version, client, sequence, operation, expanded,
  requestID} phát trên kênh Darwin `com.duoface.fullscreen.command.v1`
  (state/picker là hai kênh anh em). Operation: `query`, `renew`, `set`.
  Có LEASE theo client: host bị lease bởi session Dashboard khác thì từ
  chối ("host leased to another Dashboard session"); có sequence chống
  phát lại và deadline lease được `tick` gia hạn/hết hạn.
- DFHostSnapshot giữ trọn trạng thái trước khi zoom (manager/window/app/
  content + frame từng cái + transform của appView + renderSize) để thu
  về đúng nguyên trạng.

## 2. DuoFaceVisualHook (75.536 B) — vệ tinh thị giác, hook qua dlsym
- 0 class định nghĩa. Nó dlopen libsubstrate (cả đường /var/jb lẫn rootful)
  và dlsym `MSHookMessageEx` — hook KHÔNG qua import tĩnh (bảng stub trống).
- Constructor gom các class: UIButton, CALayer (của hệ thống) và các class
  UI của chính Dashboard — CBSlotPillView, CBDividerView,
  CBSplitSplashScreenView, CBBridgedSplitApp — kèm type encoding
  `v24@0:8@16` (method một tham số object).
- Nhóm selector nó dùng với phía Dashboard (theo selref): layoutSubviews,
  startContainerBorderBlinking:/stopContainerBorderBlinking:,
  layoutSplitViews, startBlinkingSession/stopBlinkingSession,
  focusSlot:animated:, restoreSplitAnimated: — chức năng: viền nhấp nháy
  quanh container/slot đang được focus + trang trí border/shadow cho pill
  và divider (toàn bộ từ vựng method của nó là thao tác view/layer).
- Mức chắc chắn: cơ chế + class đích + nhóm selector đã rõ; ghép cặp
  selector↔class chính xác từng cái chưa trích hết (đăng ký dạng bảng).

## 3. Đuôi chức năng Dashboard
- **Lan truyền settings**: CBDashboardSettings là property bag (~40 khóa) +
  reload/reloadAppPrefs đọc file `com.duoface.plist` dùng chung; phía
  manager có `handleSettingsChanged:` tiếp nhận tín hiệu đổi settings
  (đồng thời tái kiểm tra giấy phép tại đó — theo chuỗi log
  LICENSE_KILL_TRACE). Không có kênh đồng bộ sống nào khác: ghi file ở app,
  đọc lại ở dylib.
- **CBDockSystemMonitorView** (19 method): dải giám sát hệ thống trong dock —
  `readCpuUsage` (host statistics), `readRamUsage:total:`, nhiệt thiết bị
  (`readDeviceTemperature`), pin (`updateBatteryMetric` + notification pin),
  `updateMetrics` theo nhịp, chạm để bật/tắt detailedMode.
- **CBHttpClient** (2 method chính): GET/POST JSON có timeout + header tùy
  biến trên networkQueue riêng — hạ tầng mạng dùng chung cho đồng bộ giấy
  phép (và là client duy nhất của dylib).

## 4. App DuoFaceUI (522 method, 27 class) — bản đồ chức năng
- Điều hướng: XXRootViewController (appsNav/splitNav, badge, kiểm tra modal
  giấy phép khi active).
- Settings: CBGeneralSettingsViewController (30 — toggles autoLaunch, dock
  monitor, hide labels; loadPreferences), CBSplitViewController (42 —
  loadSettings/saveSettings, preset, slotApp1..4), CBAssistantAboutViewController
  (24 — assistant toggle, preferredMap, reset defaults, respring),
  CBAppsManagerViewController (38) + CBAppManager (20 — bật/tắt app theo
  danh mục: navigation/entertainment/user/system, enableDefaultRecommendedApps).
- CBAppPickerViewController: picker có tìm kiếm/lọc (dùng khi chọn app cho slot).
- Thương mại (chỉ ghi nhận): CBSubscriptionViewController (71) +
  CBSubscriptionOrderCoordinator (36, order/crypto/check status) + các cell
  plan/VIP/giftcode/hardware-ID + CBLicenseExpiredModalViewController (29) +
  CBLicenseSyncManager bản app (24).
- CBLocalization (6): bảng chuỗi theo mã ngôn ngữ, reloadLanguage — khớp các
  khóa UPPER_SNAKE đã thấy trong dylib.
