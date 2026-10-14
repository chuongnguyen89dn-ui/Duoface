# DuoFace v12 — truy đúng nút Phóng to / Thu nhỏ trong từng ô chia (14-10-2026)

## Điều chỉnh hiểu đúng yêu cầu

Người dùng chỉ rõ: khi đang chia hai pane, nhấn nút **Phóng to của ô đã chọn**; khi phóng, hàng menu không còn; nhấn lại điều khiển của chính ô đó để **Thu nhỏ** về hai pane và menu trở lại. Người dùng **không yêu cầu gesture vuốt mép để mở menu**. Những suy luận trước về menu picker biến mất khiến không thể thu nhỏ cần được kiểm tra lại dựa trên **CBSlotPillView** và hàm focus gốc, không giả định picker là phần tử duy nhất có thể tương tác.

Yêu cầu UI người dùng đã nêu từ trước vẫn giữ: muốn thêm chữ **“Phóng to”** cạnh tab **“Ứng dụng”**, cùng font/màu/chọn xanh; khi expanded đổi thành **“Thu nhỏ”**, restored đổi lại. **Chưa có chứng cứ rằng UIButton nằm trong picker được giữ khi picker đã bị dismiss**, nên cần phân biệt hai view: (1) per-pane slot-pill controls tồn tại trong split content và (2) menu picker overlay được show/dismiss riêng. Không tuyên bố chắc nút ở picker có thể được bấm lần thứ hai nếu chưa kiểm tra ownership/hit testing khi fullscreen.

## Các hàm và địa chỉ lấy từ bản v12 hash-pinned

Input: dist/visual-1.0.3-12/com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb
DEB SHA256 8b7dedf77b9ec05465b83fdb6e2d7127800eac232a34ecf12f2c08b3983a481a.
Binary: DuoFaceDashboard.dylib, SHA256 bc1df854ec7a2ddfeec4cb81b080ead34b54df80143d4a8f6254bb8b618003ce.

1. CBSlotPillView (điều khiển từng ô):
   - ivar _slotIndex offset 0x38 (56), _isFocusedMode 0x10 (16), _showsExpandButton 0x11 (17), _expandButton 0x48 (72), _restoreButton 0x50 (80).
   - expandTapped: IMP **0x85698**: bounceButton: rồi đọc block onExpandTapped (selector ref 0x8574c) và invoke block at **0x8578c**.
   - restoreTapped: IMP **0x857b0**: bounceButton: rồi đọc block onRestoreTapped (ref 0x85864); có callback thì invoke; nếu nil còn fallback onPillTapped.
   - setFocusedMode: IMP **0x85308** ghi isFocusedMode rồi gọi updateBoundsSize; setShowsExpandButton: IMP **0x852f0** tương tự; layoutSubviews **0x84c30** có logic setHidden/frame cho _expandButton/_restoreButton/_dotsButton theo trạng thái. Nút không đơn thuần chỉ đổi icon bằng text.
2. CBBridgedSplitApp (chủ thực sự của các ô chia):
   - initWithBundleIdentifier:frame:showSplash: IMP **0x1025e4** tạo từng CBSlotPillView cho slot và đăng ký callback:
     * setOnExpandTapped: SEL ref tại **0x102f48** (được gọi gần **0x1034b8**), block invoke **0x103b10** → **focusSlot:animated:** selector tại 0x103b50, animated=YES.
     * setOnRestoreTapped: SEL ref tại **0x102f50** (gọi gần **0x1034f4**), block invoke **0x103b80** → **restoreSplitAnimated:** selector tại 0x103bb4, animated=YES.
     * setOnPillTapped: ref 0x102f34: callback khác dùng mở menu/đổi ứng dụng, không được nhầm thành fullscreen.
   - **toggleFocusForSlot:** IMP **0x106518**: guard khi isTransitioningFocus khác 0; so sánh requested slot với _focusedSlotIndex; **bằng nhau thì restoreSplitAnimated:YES** tại **0x106544–0x10654c**, **khác nhau thì focusSlot:animated:YES** tại **0x106550–0x10655c**. Đây là toggle hai chiều gốc; không cần bịa một hàm fake.
   - **focusSlot:animated:** IMP **0x105890**: cập nhật focused slot/layout state; animation layoutSplitViews, gửi bridge state/refresh layout (xem disassembly full).
   - **restoreSplitAnimated:** IMP **0x105e2c**: khôi phục split và cập nhật state, animation/layoutSplitViews; reset tương tác phù hợp.
   - **layoutSplitViews** IMP **0x1044f8**: dùng **setFocusedMode:** (ref 0x104794), **setShowsExpandButton:** và **setFocusedMode:** (ref 0x104fa4, 0x104fac). Trạng thái visual của pill do layout gốc quyết định.
   - CBBridgeManager.showAppPickerForSlot: IMP **0x27fee4**: nếu focusedSlotIndex hợp lệ thì **restoreSplitAnimated:NO** ở **0x27ff80–0x27ff8c** trước khi gọi CBWindow.showAppPickerForSlot: ở **0x27ffdc**. Vì vậy luồng menu/focus liên quan nhau, không cần suy đoán menu ở đâu.
3. Quan trọng: Native split focus/restore ở CBBridgedSplitApp **không đồng nhất** với immersive fullscreen của adapter Airaw:
   - Native focus có thể phóng **một ô** trong split, thay đổi focusedSlotIndex và geometry/controls.
   - Adapter hiện tại DFFullscreenCoordinator.mm khi bấm nút status-bar chỉ gửi DFRequestHostFullscreen(YES) để mở rộng toàn host và ẩn chrome, chưa có toggle event khi bấm lại. DFFullscreenTransport.mm có sẵn DFRequestHostFullscreen(NO), SpringBoard DFHostSetExpanded(NO)→DFHostRestore().
   - Cần xác định UI thực người dùng muốn tái dùng (nút per-slot focus/restore hay status-bar host fullscreen) trước khi quyết định duy nhất đường action cho chữ Phóng to/Thu nhỏ. Không tùy tiện ghép native focus vào host fullscreen rồi nói tương đương.

## Đường kiểm chứng — không sửa runtime

- CI read-only https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/38539438510: COMPLETED SUCCESS. Workflow dùng scripts/v12_host_recovery.py với ranges:
  0x841c0:0x84c30 0x84c30:0x85348 0x85348:0x85904
  0x105890:0x105e2c 0x105e2c:0x106518 0x106518:0x106560 0x1067a4:0x106f00 0x27fee4:0x280014
- Evidence lưu audit/v12-split-pill-button-chain-20261014.txt và audit/v12-split-focus-restore-chain-20261014.txt.
- CI read-only https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/38539740615: COMPLETED SUCCESS. Workflow dùng các ranges:
  0x1025e4:0x103ee0 0x103ee0:0x1044f8 0x1044f8:0x105890 0x106f00:0x108dd8
- Evidence audit/v12-split-slot-wiring-full-20261014.txt và audit/v12-split-slot-wiring-extract-20261014.txt. Tất cả đã được đọc trực tiếp trên GitHub.

## Các bước tiếp theo; khóa an toàn

1. Đối chiếu ảnh thiết bị với exact view/hit target của CBSlotPillView: có nút expand/restore thuộc từng ô, vẫn hoạt động khi không hiện picker overlay; truy lifecycle setFocusedMode và updateBoundsSize.
2. Đối chiếu native focusSlot/restoreSplit với Airaw-style host fullscreen đang được báo chạy được; bảo đảm không gắn nhầm callback sẽ chỉ focus pane mà không ẩn native chrome.
3. Trình người dùng thiết kế duy nhất: mục Phóng to/Thu nhỏ nằm cạnh tab Ứng dụng, lấy font/màu nền/chọn từ chính appSegmentBtn, nhưng xác minh vị trí điều khiển đó sẽ tồn tại/hit-test được sau khi picker đóng; không đề xuất gesture hay nút nổi trừ khi người dùng chọn.
4. Sau khi được người dùng duyệt hành vi/vị trí, mới sửa code toggle với state đã xác nhận, CI compile/candidate và device test; không tự phát hành Sileo.
5. Giữ v12, split ratio/picker của 3 tab, day data, package ID và giao diện khác. Không thay source runtime trong bước nghiên cứu này.

**Trạng thái:** phân tích native callchain DONE bằng SHA/hash & CI; CHƯA patch runtime, CHƯA đóng DEB, CHƯA test CarPlay với menu 4 tab. Giữ checkpoint này làm nguồn tiếp nối, không quay về lập luận sai “không thể thu nhỏ chỉ vì picker menu biến mất”.


## Bổ sung truy nguyên khác biệt giữa pill và menu

- Block **onPillTapped** tại **0x103A78** (được gắn gần **0x103454–0x10345C**) lấy CBBridgeManager.sharedInstance, truyền slotIndex captured tại offset +0x20 vào **showAppPickerForSlot:** ở **0x103AB0–0x103AB4**.
- CBBridgeManager.showAppPickerForSlot: IMP **0x27FEE4** kiểm tra currentApp có phải CBBridgedSplitApp; nếu đang có focusedSlotIndex hợp lệ thì **restoreSplitAnimated:NO** (0x27FF80), tiếp đến gọi CBWindow.showAppPickerForSlot: (0x27FFDC). Nói cách khác, **nút “...” trên từng pill mới là lối mở picker**, còn nút Phóng to/Thu nhỏ gốc thuộc **cùng pill của từng pane**, không phải một trong ba nút tab của picker.
- Vì vậy mô tả người dùng “menu biến mất khi phóng lớn nhưng vẫn nhấn lại được nút thu nhỏ” phù hợp với **lifecycle khác nhau** của 2 nhóm view: CBSlotPillView là điều khiển slot, CBMultitaskingOverlayView là menu tạm. Không được đổ lỗi chỉ cho menu ẩn và đề xuất gesture vuốt nếu chưa nghiên cứu đúng slot-pill.
- Native toggleFocusForSlot: có thể được dùng làm logic tham chiếu hoặc đưa vào action của UI mới, nhưng **không phải** host fullscreen của adapter Airaw. Việc nhân bản UI tab picker mà không có cơ chế giữ hit target khi overlay đóng vẫn là rủi ro kỹ thuật độc lập.
