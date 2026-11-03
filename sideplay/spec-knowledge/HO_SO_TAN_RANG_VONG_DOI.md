# HỒ SƠ TẬN RĂNG — VÒNG ĐỜI KẾT NỐI & TRỢ LÝ (DuoFaceDashboard, 1.0.3-12)

Đọc từ disassembly (luồng gọi + hằng + chuỗi log đối chiếu).

## 1. Kết nối màn hình — handleScreenDidConnect: (IMP 0x1b86c8)
1. Kiểm tra màn vừa nối có phải màn CarPlay không (`isCarPlayScreen:`) và còn kết nối không (`isCarPlayScreenConnected`) — không thì bỏ qua.
2. **Chống flap:** nối lại quá nhanh so với lần nối trước (log ghi khoảng cách tính bằng giây, hai chữ số thập phân) thì bỏ qua — tránh chuỗi connect/disconnect chập chờn làm sập phiên.
3. Giữ sleep assertion (mục 3), hủy watchdog ngắt kết nối, kích hoạt đồng bộ giấy phép (chỉ ghi nhận tồn tại), dọn cache tập hợp, `resetCachedBounds` (xóa cache bounds/insets đã đọc ở hồ sơ hình học).
4. Cửa sổ hiện có mà display không còn hợp lệ → `destroyWindows` dựng lại.
5. Tính `effectiveAutoLaunchBundleID` → hẹn `performAutoResume` + `scheduleAutoResumeFallback` (hai lớp: chính + dự phòng).

## 2. Ngắt màn hình — handleScreenDidDisconnect: (IMP 0x1b82e0)
1. Phân biệt nguồn: notification thường vs "(direct DashBoard IPC)".
2. Nếu **còn một màn CarPlay khác đang hoạt động** (`isCarPlayScreenConnectedExcludingScreen:`) thì không coi là ngắt hẳn.
3. Nhả sleep assertion; **hủy các lệnh performAutoResume đang chờ** (cancelPreviousPerformRequestsWithTarget:) — tránh khôi phục phiên vào màn đã mất.
4. **Lưu autoResumeBundleID ra file `/var/tmp/carbridge_autoresume_bid`** (writeToFile:atomically:) trước khi dọn — phiên sau nối lại đọc chính file này (performAutoResume đọc bằng stringWithUTF8String:).
5. resetCachedBounds; manager đang activated → `deactivateCurrentApp` (gửi shouldBridge:NO xuống từng app con theo DISCONNECT_TRACE), chưa activated → `destroyWindows`; `clearBridgeStateOnDisk`; `notifyStateUpdated`; hẹn watchdog ngắt kết nối bắt buộc (cơ chế gắn với giấy phép — chỉ ghi nhận tồn tại).

## 3. Sleep assertion — acquireCarPlaySleepAssertion (IMP 0x19eaf8)
Tạo IOPM assertion loại `PreventUserIdleSystemSleep` với lý do `"CarBridge.CarPlaySessionActive"` (tên tiền nhiệm CarBridge còn nguyên trong chuỗi). Giữ trong suốt phiên CarPlay, nhả khi ngắt. Phía ta không có cơ chế tương đương.

## 4. Trợ lý — CBAssistantManager (68 method instance)
- Pipeline nghe: AVAudioEngine → ghi PCM (recordedPCMData) → hai đường chép lời: SFSpeechRecognizer (setupSpeechRecognizer) và `transcribeAudioData:completion:` (đường Google Speech API vi-VN đã thấy ở kiểm kê); có silenceTimer (im lặng thì tự kết thúc) + listeningTimeout.
- HUD trợ lý riêng: hudWindow/hudCard, micIconView với pulse animation, statusLabel/transcriptLabel.
- **Bộ định tuyến lệnh** `processVoiceCommand:` → `handleAppLaunchCommand:` (mở app qua triggerBridgeApp:/dismissCarBridgeApp), `handleMusicCommand:`, `handleNavigationCommand:` — lệnh thoại điều khiển hệ thống thật, không chỉ hỏi đáp.
- Phản hồi giọng nói: AVSpeechSynthesizer `speak:completion:`, cờ voiceFeedbackEnabled.
- Quyền micro/nhận dạng: được cấp trước ở tầng TCC (hàm CBGrantTCCSpeechPermissions — đã ghi nhận ở báo cáo A–Z mục 3b; cơ chế rủi ro cao, chỉ ghi nhận).

## 5. Đối chiếu phía ta
- Vòng đời của ta: có disconnect-close coordinator + stop/ack, nhưng không có: chống flap theo thời gian, lưu bundle khôi phục ra file bền, hủy lệnh khôi phục khi ngắt, sleep assertion, reset cache hình học theo sự kiện nối/ngắt (cache của ta không tồn tại vì ta tính bounds mỗi lần — đổi lại gốc phải reset cache thủ công).
- Trợ lý của ta (DFVoiceAssistant, 26 method, trong app) chỉ nghe–đáp; không có định tuyến lệnh điều khiển, không có HUD trợ lý riêng trên xe.
