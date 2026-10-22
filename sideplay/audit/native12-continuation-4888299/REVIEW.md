# Native12 → DuoFace: audit tiếp nối 4888299 (2026-10-22)
## Phạm vi và khóa thực thi
- Repo chuongnguyen89dn-ui/Duoface; nhánh feature/duoface-jb-embedded-appbridge-20261020; HEAD đọc trực tiếp = 4888299bd4e6625323d7a01d894a3c7ab9fd6bb3.
- USER_DECISION: dò lại phần đang có; giao diện và chức năng phải tương đương Native12; không viết lại từ đầu; lưu ngay từng phát hiện. Giữ dự án độc lập, không nhập runtime giấy phép.
- Đã đọc nội dung ZIP trung tâm 01-github-continuity, 02-ios-deb-ipa-carplay, 05-research-debug-testing bằng fetch_file base64 + Python zipfile.
- Handoff tại 4888299 và HEAD có cùng blob cf341fa44273257175916097f82926f01cb7a55e.
- Actions 39729328883 (integrated .31), 39728888190 (host .38), 39729486916 (original count) trực tiếp trả completed/success. 39728980964 trả failure; không đổi thành success. Không khởi động lại job.
## CONFIRMED: nối Zoom chưa thực hiện tác vụ
1. DFNative12Chrome.m menuAction: case 1 chỉ emit:@"Zoom", log native12-global-zoom-owner-ack-pending.
2. DFTouchOwnerProbe.m DFSendCommand nhận Zoom và gửi stateSnapshot như post-action message, không gọi owner Dock.
3. DFNativeHostAppDelegate.m receiveTouchOwnerCommand cho Zoom qua whitelist nhưng chỉ kiểm snapshot rồi trả Accepted=YES; không có thay đổi Dock/usable rect hay rollback.
4. Vì vậy ACK ở tuyến này chỉ chứng minh nhận trạng thái; KHÔNG chứng minh Zoom đã ẩn Dock. Đây là thiếu nối thực tế trong source, không chỉ thiếu test thiết bị.
5. Native12 WIRING_REPORT.md phân biệt owner: CBDashboardShared.appDockVC (0x1217d8), CBBridgeManagerDashboard.updateCarPlayMetrics (0x2a4c24), CBWindow.carPlayUsableBounds (0xb0ef4), fullscreen transport + geometry + chrome + restore. Cần tái kiểm source/callsites trước khi thêm adapter.
## CONFIRMED: media orientation còn hardcode
- DFSceneHost.m layoutSubviews sau readiness gate vẫn gọi setContentReferenceSize:withInterfaceOrientation: với UIInterfaceOrientationPortrait; biến thể ba tham số cũng Portrait cả hai.
- Không được nói bản .28 đã hoàn thiện xoay/video. Readiness gate và tránh lặp resize là phần đã có cần giữ.
## CONFIRMED: 9 preview không đồng nghĩa UI hoàn toàn nguyên bản
- ORIGINAL_NINE_LAYOUT_SHAPES.md tham chiếu original renderer 0x9efe0, jump table 0x310d3e: 9 tag, cuối là 2x2.
- Chính tài liệu original chỉ ra gallery dùng 5 HOẶC 6 cột; DFNative12Chrome.m hiện hardcode 5. Threshold và toàn bộ frame/card/color chưa kiểm từ binary trong lượt này; không đoán.
- selectStylePreset: chuyển Solo chỉ giữ selectedSlot==1 trong hai bố cục 1/2; chưa có logic giữ slot 2/3 khi từ ba/bốn ô. Cần đối chiếu original presetSelected và app ordering trước khi sửa.
## Lịch sử phải đọc theo mốc
- GESTURE_CALLSITE_CROSSWALK.md cũ vẫn nói 8 layouts và hold .30s. Bàn giao mới tại 4888299 đã supersede thành 9 và 3s. Không lấy tài liệu cũ làm yêu cầu mới.
- REPORT.md media cũ phân tích .27; IMPLEMENTATION_0.0.28.md và source hiện tại phải ưu tiên khi đánh giá phần đã sửa.
## Bằng chứng và giới hạn
Đã đọc source, workflow và báo cáo gốc đã lưu; chưa chạy lại DEB gốc, chưa compile iOS, chưa sửa runtime, chưa test trên iPhone. Không tuyên bố giống hoàn toàn. Tool git ls-remote qua git.chatgpt-team.site thất bại xác thực; GitHub connector vẫn đọc/ghi được. Các bản local chỉ là bản đọc tạm.
## Điểm tiếp tục
1. Đọc raw focused callsites và source fullscreen của đúng Native12 để map caller → selector → owner → teardown.
2. Đối chiếu app-slot selection/Solo và gallery branch 5/6 từ original instructions.
3. Ghi bản đồ chức năng có evidence/unknown riêng; sửa từng chỗ đủ chứng cứ, dùng version mới nếu build; giữ nguyên .23–.31.
