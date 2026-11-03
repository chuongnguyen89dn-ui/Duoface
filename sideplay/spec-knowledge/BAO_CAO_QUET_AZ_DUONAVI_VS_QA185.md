# QUÉT A–Z: DEB DUONAVI GỐC vs DEB HIỆN TẠI (QA185) — BÁO CÁO ĐỐI CHIẾU

Ngày: 2026-11-03. Người làm: Muse (implementer). Mục đích: đối chiếu toàn diện hai gói cài đặt để biết chính xác hai bên khác nhau ở đâu, phần nào đã hội tụ, phần nào còn là khoảng trống thật.

## 0. Đối tượng, phương pháp, giới hạn

- **Phía gốc:** `com.duonavi.app` phiên bản `1.0.3-12+border-focus-red3` (2.048.980 byte; control tự ghi "full-payload rootless test, runtime and signature unverified" — đây là bản test của chính dòng sản phẩm gốc, và là cùng một bản đã dùng cho mọi Bước 0 trước đây: QA183 sửa tên phím/idiom, QA185 renderSize).
- **Phía ta:** `com.duoface.jb.embedded` phiên bản `0.0.185~destsize1` (1.295.088 byte, SHA256 `3cf5aeb9…433`), bản đang đứng trên Sileo.
- **Phương pháp (chỉ đọc, không chạy bất kỳ binary nào):** trích xuất cả hai deb; giải mã cấu trúc Mach-O bằng parser tự viết — danh sách class định nghĩa thật (đọc `__objc_classlist` → class_ro), toàn bộ method của từng class kể cả class method, từ vựng selector (`__objc_methname`), chuỗi C (notification, tên Darwin, đường dẫn plist, URL, thẻ log), filter tiêm của Substrate, script postinst/prerm, Info.plist. Số liệu dưới đây đều truy được về các bảng này.
- **Giới hạn:** đây là kiểm kê tĩnh. Nó trả lời chắc chắn "có class/method/selector/chuỗi nào, tiêm vào process nào, đọc/ghi file nào". Nó không trả lời "hàm chạy ra sao theo thời gian" — những chỗ như vậy được ghi rõ là *chưa kết luận*, cần dịch ngược sâu từng hàm hoặc log máy thật.

## 1. Tổng quan gói

| | DuoNavi gốc 1.0.3-12 | Ta QA185 |
|---|---|---|
| Package | com.duonavi.app | com.duoface.jb.embedded |
| Tên hiển thị | DuoFace | DuoFace Independent (Integrated CarPlay Beta) |
| Phụ thuộc | mobilesubstrate ≥ 0.9.5000, firmware ≥ 13.0 | firmware ≥ 16.0, mobilesubstrate |
| Dung lượng cài | ~10.253 KB | ~1.295.088 byte file deb |
| App | DuoFaceUI (2.456.784 B) | DuoFaceNativeHost (348.832 B) |
| Dylib | 3 (Dashboard, FullscreenBridge, VisualHook) | 10 |
| Công cụ dòng lệnh + helper root | **Có** (duoface-cboptimize + helper setuid) | Không |
| sudoers drop-in | **Có** | Không |
| postinst | Dài: seed prefs, migrate prefs CarBridge cũ, chmod state, setuid helper, uicache | Ngắn: chỉ uicache |
| Xung đột khai báo | Không khai Conflicts | Khai Conflicts/Replaces với chính com.duonavi.app và các module QA cũ |

## 2. Kiến trúc tổng thể — khác biệt gốc

**Phía gốc là kiến trúc nguyên khối sống-trong-mọi-process.** Một dylib lõi duy nhất `DuoFaceDashboard.dylib` (7.540.464 B, 36 class, 757 method) được tiêm vào **24 bundle**: SpringBoard, các process CarPlay (CarPlayApp, CarPlay, dashboard), app DuoFaceUI, **và chính các app được host** (YouTube, YouTube Music, Netflix, VLC, Safari, Twitch, TikTok, Google Maps, Waze, Spotify, Settings, Notes, Phone, Music, Chrome, BarcodeScanner, Print Center). Mọi tầng — host, UI, bàn phím, trợ lý, giấy phép — đều là các class `CB*` trong cùng dylib này, chạy cùng process với thứ nó điều khiển.

**Phía ta là kiến trúc mô-đun theo process.** 10 dylib, mỗi dylib một vai và một filter hẹp: DFTouchOwnerProbe (693.232 B, 12 class, 660 method) chỉ vào SpringBoard và chứa host + chrome; DFCarPlayDockOwner vào process CarPlay; DF155GeneralAppStateRelay vào 14 app thí điểm; các relay riêng cho GOFA (×2) và YouTube; DFFirstPartyAdmission (0 class định nghĩa — hook thuần C) vào CarPlay+SpringBoard; DFV1APreflight là nguyên mẫu scene host đời đầu, mặc định tắt. App của ta (10 class, 188 method) chủ yếu là điều khiển + chẩn đoán + một template scene delegate.

Hệ quả đo được trong từ vựng selector: hai bên có **2.590 (gốc) vs 2.658 (ta)** selector riêng, chỉ **chung 640**. Hai hệ thống giải cùng một bài toán bằng hai bản đồ gần như không trùng nhau.

## 3. Đối chiếu theo từng mảng

### A. Hosting & hình học
- Gốc: `CBBridgeManager` (73 method instance + 2 class) là trung tâm: `appForBundleIdentifier:frame:`, `loadNewAppFromCurrentRequest:`, `sendStateToApp:shouldBridge:`, và đặc biệt bộ ba **`renderSize` / `renderSizeForBundleID:` / `setRenderSize:`** — hợp đồng render theo kích thước đích tồn tại ở tầng API của manager. Selector hook phía scene: `interceptUpdateForScene:withNewSettings:`, `updateSceneSettingsFrame`, `sceneHandle:didUpdateSettingsWithDiff:previousSettings:` (đúng selector xuất hiện trong backtrace crash 26/10), `takeWithPriority:reason:forWindow:bundleIdentifier:pid:scene:heading:focusedFrame:`.
- Ta: `DFSceneHost` chỉ 15 method + `DFSceneSurface` 91 method; hợp đồng hình học nằm ở header dùng chung chứ không ở manager. **QA185 vừa hội tụ về hướng render-theo-đích** (scene = pane, scale 1.0) — cùng chiều với `renderSizeForBundleID:` của gốc, nhưng cơ chế phân phối khác (ta: một header; gốc: manager giữ state renderSize theo bundle và đẩy qua settings update).
- Chưa kết luận: gốc tính renderSize theo bundle bằng công thức nào trong từng tình huống (cần dịch ngược thân hàm hoặc log); Bước 0 QA185 chỉ xác nhận được sự tồn tại và vai trò của bộ ba selector.

### B. Portal & chế độ bắt hình (gốc có, ta không có)
- Gốc có hẳn một họ class: `CBBridgedPortalApp` / `CBBridgedPortalAppView` — view này có `displayLink`, `captureFrame:`, `imageView`, `touchCloneView`: tức một chế độ hiển thị bằng **bắt khung hình theo nhịp display link vào image view**, song song với chế độ host scene trực tiếp (`CBBridgedUIApp`/`CBBridgedUIAppView`, 16/29 method) và chế độ chia (`CBBridgedSplitApp`, 49 method). Cờ `portalAppEnabled` + `portalAppIdentifier` trong settings cho thấy portal là chế độ chọn được theo app.
- Ta: chỉ có một chế độ host scene trực tiếp; không có đường bắt hình.

### C. Chạm
- Gốc: `CBTouchCloneView` (5 method) gắn với portal view + selector `sendTouchEventAtPoint:isDown:` — chạm được tổng hợp và phát lại theo tọa độ; cộng với việc lõi chạy ngay trong process app nên phần lớn chạm là chạm thật của app.
- Ta: chạm dựa vào scene hosting của iOS + relay sự kiện (`-[UIApplication sendEvent:]` read-only từ QA177). Đã biết từ các vòng trước: `DFSceneSurface.hitTest` không chạy trong sử dụng thật; chưa bản nào đạt kiểm chứng chạm đầy đủ trong app được host. Đây vẫn là mảng chênh lệch có bằng chứng máy thật rõ nhất.

### D. Bàn phím
- Gốc: lớp `[DuoFaceKB]` hiện diện ở tầng selector tĩnh: `keyboardName`, `keyplaneName`, `keyboardScreenReferenceSize`, `keyboardWidthForScreen:withOrientation:`, `inputMode`… — 13 selector phím chuyên dụng, khớp với kết quả Bước 0 QA183 (5 nhóm can thiệp, chạy trong process app vì filter Dashboard bao gồm các app).
- Ta: từ vựng selector tĩnh có **0** selector phím — toàn bộ phần phím của ta (fit QA179–184, suite QA183) đi qua tra cứu runtime bằng chuỗi C trong relay, không phải selector biên dịch sẵn. Khác biệt này phản ánh đúng khác biệt kiến trúc ở mục 2: gốc sửa phím từ bên trong process app bằng hook trực tiếp; ta sửa từ SpringBoard/relay.

### E. Cửa sổ, chia màn, UI trên xe
- Gốc: `CBWindow` (28+9 method: `createWindows`, `resizeWindows`, rootWindow + multitasking overlay/pill), `CBMultitaskingOverlayView` (66), `CBSlotPillView` (36), `CBDividerView` (27), `CBSplitContainerView`, `CBSplitSplashScreenView`. Settings hỗ trợ **chia tới 4 app** (splitApp1..4), preset, ratio, grid cols/rows cho picker.
- Ta: `DFNative12Chrome` một mình 251 method (gần bằng cả cụm UI của gốc cộng lại, nhưng dồn trong một class), `DFAppPickerVC` 109, splash/divider/pill nằm rải trong probe và dock owner. Ta chia 2 khung (pane trái/phải + divider kéo được); chưa có chia 4, chưa có grid picker dạng lưới cấu hình được.

### F. Dock & giám sát hệ thống
- Gốc: `CBDockSystemMonitorView` (19) + `CBDockMetricItemView` (11) + cờ `dockSystemMonitorEnabled/ShowAll`: dock của gốc hiển thị **chỉ số hệ thống** (dạng metric items) và có hook theo dõi dock (`[CBHook_DockMonitor]`).
- Ta: có dock-zoom và home publisher, không có lớp metric hệ thống trên dock.

### G. Trợ lý giọng nói
- Gốc: `CBAssistantManager` 68 method + `CBBridgedAssistantApp/View`; nhận dạng bằng SFSpeechRecognizer, tổng hợp bằng AVSpeechSynthesizer, và có URL `https://www.google.com/speech-api/v2/recognize?...&lang=vi-VN&key=%@` — một đường nhận dạng qua Google Speech API (khóa truyền theo tham số). Có `processVoiceCommand:` — trợ lý của gốc xử lý **lệnh thoại để điều khiển hệ thống** (không chỉ hỏi đáp).
- Ta: `DFVoiceAssistant` 26 method trong app host (SFSpeech + AVSpeech), phạm vi hẹp hơn, không có lớp bridged-assistant riêng, không có đường Google Speech.

### H. Settings & mô hình dữ liệu
- Gốc: **một** file prefs `com.duoface.plist` + class `CBDashboardSettings` (56+5 method, ~40 khóa): bridgedApps, splitScreenEnabled, splitMode/Preset/Ratio, splitLeft/RightBundleID, autoLaunchOnConnect + autoLaunchBundleID, portalApp*, assistantEnabled, voiceFeedbackEnabled, screenBlankEnabled, dockSystemMonitor*, gridCols/Rows, hideIconLabels, scale theo từng bundle (`scaleForBundleID:`), agreedToEULA. postinst tự seed file này (danh sách app mặc định gồm Maps, YouTube, Music, Podcasts, TV, TikTok, **Zalo**) và migrate từ prefs của sản phẩm tiền nhiệm CarBridge (`com.tiz.carbridge.plist`).
- Ta: **nhiều** file plist phiên bản hóa (nativehost.*.v1, qa176/qa177 cho các cờ vòng QA…) — linh hoạt cho thử nghiệm nhưng rời rạc; chưa có một settings store thống nhất kiểu trên, chưa có scale theo từng bundle, chưa có screenBlank, chưa có auto-launch theo bundle cấu hình sẵn trong postinst.

### I. IPC liên process
- Gốc: NSDistributedNotificationCenter + file state dùng chung (`com.duoface.bridgestate.plist` ở /var/tmp, chmod 0666 trong postinst) + prefs dùng chung. FullscreenBridge là dylib riêng với bộ kênh `com.duoface.fullscreen.command/state/picker.v1`.
- Ta: Darwin notify + hộp thư một ô DF156 (JSON nén vào notify state) + loạt file plist command/ack theo từng tính năng. Đã biết điểm yếu đo được: hộp thư một ô làm mất record (QA180/181/183). Gốc dùng file state bền + distributed notification nên không có kiểu mất đó — đổi lại phụ thuộc quyền ghi file dùng chung.

### J. Fullscreen & zoom
- Gốc tách hẳn `DuoFaceFullscreenBridge.dylib` (107.744 B, 4 class: DFFullscreenTransport, DFHostSnapshot, DFZoomAction, DFZoomReceiver; filter chỉ 4 process CarPlay/SpringBoard).
- Ta: fullscreen/zoom nằm trong chrome + dock owner, không có dylib chuyên trách và không có cơ chế snapshot host riêng.

### K. Lớp thị giác
- Gốc: `DuoFaceVisualHook.dylib` (75.536 B, 0 class định nghĩa — hook thuần) với thẻ `[DuoFaceBorder]`, `[DuoFaceVisual12]`: vẽ viền/focus trực tiếp trong cả SpringBoard lẫn app DuoFaceUI.
- Ta: styling nằm trong chrome của probe; không có dylib thị giác độc lập tiêm vào app cấu hình.

### L. GOFA & HUD tốc độ — mảng ta có, gốc (bản này) không có
- Trong toàn bộ từ vựng của Dashboard/UI bản 1.0.3-12: **0 selector tốc độ**. HUD tốc độ đọc GOFA là mảng của dòng CarPlayPro, không nằm trong deb DuoNavi này.
- Ta: cả một chồng riêng — DFGofaSpeedSource162 + decoder QA172 (DFGofaDecoder172), DFGofaMapResize141, DFNative8SpeedHUDView (66 method, có mặt trong 2 dylib), cơ chế handover HUD QA177/178. Đây là năng lực phía ta tự xây, không phải phần "thiếu so với gốc".

### M. Giấy phép & thương mại (ghi nhận tồn tại — ngoài phạm vi làm theo)
- Gốc có đầy đủ một chồng giấy phép: `CBLicenseSyncManager` (24+6, có cả trong app lẫn dylib — code dùng chung), `CBLicenseWarningModalView`, `CBLicenseShieldIconView`, watchdog giấy phép trong CBBridgeManager (`licenseWatchdogTimerFired:`, `presentLicenseWarningModalWithType:`, thẻ `[LICENSE_KILL_TRACE]`, `enforceMandatoryDisconnectKill`, `killProcessesForBundleIdentifiers:`), file lease `com.duonavi.sync.plist` đóng sẵn trong deb (status SUCCESS, lease ~5 năm), `CBHttpClient` dùng chung, và trong app là cả tầng thương mại đăng ký: CBSubscriptionViewController + order coordinator + các cell plan/VIP/giftcode/hardware-ID.
- Ta: không có bất kỳ phần nào của chồng này. Khác biệt này là cố ý và giữ nguyên.

### N. "System optimizer" & helper root (ghi nhận tồn tại — rủi ro khác hẳn)
- Gốc cài thêm: script `duoface-cboptimize` + helper Mach-O được postinst đặt **setuid root (4755)** + mục sudoers. Lệnh `optimize` tắt 12 daemon hệ thống qua launchctl (ReportCrash, healthd, softwareupdated, triald, routined, duetexpertd…) và xóa sạch thư mục CrashReporter. Cờ `systemOptimizerEnabled` được seed bật sẵn.
- Ta: không có helper, không sudoers, postinst chỉ chạy uicache. Hồ sơ rủi ro hai bên khác hẳn nhau ở điểm này: bản gốc thay đổi trạng thái hệ thống ngoài phạm vi tweak hiển thị.

### O. Vòng đời kết nối
- Gốc: nghe CARSession*/AVExternalDevice* notifications, giữ **sleep assertion** cho CarPlay (`acquireCarPlaySleepAssertion`), auto-resume (`performAutoResume`, `scheduleAutoResumeFallback`), watchdog ngắt kết nối bắt buộc, lưu/xóa bridge state trên đĩa (`saveBridgeStateToDisk`/`clearBridgeStateOnDisk`).
- Ta: có disconnect-close coordinator và stop/ack tương đương một phần; chưa có sleep assertion và auto-resume theo phiên.

### P. App cấu hình
- Gốc: DuoFaceUI 27 class — quản lý app (CBAppManager/CBAppsManagerViewController), picker, settings tổng, subscription, localization dùng chung với dylib (CBLocalization, CBHttpClient, CBLicenseSyncManager xuất hiện ở cả hai binary).
- Ta: DuoFaceNativeHost thiên về vận hành + chẩn đoán (DFNativeDiagnostics, xuất log), có template scene delegate riêng (DFNativeHostTemplateSceneDelegate 37 method) — phía gốc ngược lại chỉ có đúng 1 selector template (`setLaunchUsingTemplateUI:`): **gốc không chạy template scene của chính nó; ta thì có** (đây chính là đánh đổi dock đã biết: template lấy được dock gốc nhưng bị khóa UI mẫu; host tự vẽ thì tự do UI nhưng không giữ dock).

### Q. Log & dữ liệu
- Gốc: liên kết libsqlite3 + thẻ `[DuoFaceDB]` (có tầng cơ sở dữ liệu), file log ở /var/mobile/duoface*.log (script optimizer biết và dọn các file này).
- Ta: log qua exporter trong app + audit records; không có tầng DB.

## 4. Bảng chênh lệch tổng hợp

**Gốc có — ta chưa có (khoảng trống chức năng thật):**
1. Chế độ portal bắt hình (displayLink → imageView) song song host trực tiếp.
2. Lớp bàn phím tĩnh trong-process (mục D) — khoảng trống kiến trúc đã biết, là gốc của chuỗi vòng QA179–185.
3. Chạm tổng hợp kiểu touch-clone gắn với portal (`sendTouchEventAtPoint:isDown:`).
4. Chia 4 app + preset/ratio + grid picker cấu hình được; scale riêng theo từng bundle; screenBlank.
5. Dock system monitor (metric CPU/hệ thống trên dock).
6. Trợ lý giọng nói cấp hệ thống (bridged assistant + lệnh thoại điều khiển + đường Google Speech vi-VN).
7. Sleep assertion + auto-resume phiên CarPlay; bridge state bền trên đĩa.
8. Settings store thống nhất một file + seed/migrate trong postinst.
9. Fullscreen/zoom là dylib chuyên trách có snapshot transport.
10. Tầng dữ liệu sqlite cho trạng thái/log.

**Ta có — gốc (bản này) không có:**
1. GOFA: nguồn tốc độ + decoder payload + resize bản đồ GOFA + HUD tốc độ với handover đa presenter.
2. Template scene delegate của riêng app (mục P).
3. Bộ chẩn đoán xuất log phục vụ phân tích (audit exporter, kbdiag/kbfit, R2/R3) — hạ tầng đo mà gốc không có (gốc chỉ có log text + DB nội bộ).
4. Khai báo Conflicts/Replaces dọn module cũ; postinst tối thiểu không đụng hệ thống.

**Đã hội tụ:**
- Hướng hình học render-theo-kích-thước-đích: gốc có ở tầng API (`renderSizeForBundleID:`); ta vừa chuyển ở QA185 (chờ kiểm chứng xe).
- Picker/slot/split/divider/logo/swap/fullscreen: hai bên đều có, khác cơ chế.
- Nhận dạng + tổng hợp giọng nói tiếng Việt bằng framework hệ thống: hai bên đều có, khác phạm vi.

**Khác biệt cố ý, không phải khoảng trống:** chồng giấy phép/thương mại (M) và optimizer + helper setuid root (N). Báo cáo chỉ ghi nhận; không thuộc phạm vi làm theo.

## 5. Những điều kiểm kê tĩnh không trả lời được
- Công thức renderSize theo bundle của gốc trong từng chế độ (host trực tiếp vs portal vs split).
- Điều kiện gốc chọn portal thay vì host trực tiếp cho một app cụ thể.
- Hành vi thật của touch-clone khi kéo/thả đa điểm.
- Nội dung tầng DB sqlite (bảng gì, ghi gì).
Muốn trả lời phải dịch ngược sâu từng hàm cụ thể (chọn điểm, không quét diện) hoặc đối chiếu bằng log máy thật khi có máy.

## 6. Kết luận một dòng
Hai deb giải cùng bài toán bằng hai kiến trúc đối ngược: gốc là một lõi nguyên khối sống trong mọi process kèm các chồng phụ (portal, trợ lý, giấy phép, optimizer); ta là hệ mô-đun theo process, mạnh hơn ở GOFA/chẩn đoán/template, và khoảng trống thật còn lại tập trung ở portal, bàn phím/chạm trong-process, và độ rộng của settings — không nằm ở hình học nữa sau QA185.
