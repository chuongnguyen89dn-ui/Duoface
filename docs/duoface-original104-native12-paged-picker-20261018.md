# DuoFace Native12 visual rebuild — verified original 1.0.4 paged picker (2026-10-18)

## Nhiệm vụ và phạm vi

Người dùng yêu cầu **tiếp tục dựng đúng giao diện DuoFace Native12 HUD8** (không chỉ QA mở được app). Gốc nghiên cứu là `DuoNavi 1.0.4`, chuẩn kết quả là Native12 HUD8. Phát triển tại `chuongnguyen89dn-ui/Duoface`, nhánh `feature/visual12-duodash-recovery`. Không thay ổn định Native12 Sileo (`com.duoface.independent`); mọi sửa ở lõi UI QA độc lập `com.duoface.visual12`.

## Sửa lỗi bằng chứng rất quan trọng: false negative ở parser

- Trước lượt này, `scripts/audit_original104_scene_lifecycle.py:inventory()` có `classes={"CBBridgedUIAppView","CBWindow","CBBridgedSplitApp"}` và regexp chỉ đọc BA lớp đó. Dùng lại nó để kiểm tra `CBMultitaskingOverlayView` đã trả **false negative** và khiến câu nói "DuoNavi 1.0.4 không có các method picker" **SAI**. Không được lặp lại khẳng định đó.
- Sửa `scripts/audit_original104_ui_callchains.py`: đọc metadata tất cả class trong `TARGETS` qua `inventory_relevant`, thêm `CBMultitaskingOverlayView` (layoutSubviews, setupCardContent, setupAppPickerCardsInCardW:cardH:contentY:, setupRecentAppsCardsInCardW:cardH:contentY:), lưu bounded static assembly và `metadata_class_method_counts`. Commits `da836950146f0aef81140c0fff64f9e599db4830` (mở rộng), `c9e9fa5e311a60629a5b947e81fb7569932babed` (CI 31 methods), `ee1353ae6191f9aa176585b6ac6f1bca29c18f4a` (sửa lớp inventory), `58b3e1816f3a656295f0a49f4508b3e99d51d13b` (sửa literal regex).
- Actions [39097371758](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39097371758) **SUCCESS**, báo cáo `audit/duonavi-original104-ui/ORIGINAL104_UI_CALLCHAINS.json` và `REPORT.md` được ghi bền vững vào đúng repo. 31 method, metadata đầy đủ: `CBWindow=40`, `CBMultitaskingOverlayView=66`, `CBBridgedSplitApp=50`, `CBBridgedUIAppView=31`. Bốn method overlay thực sự có trong original1.0.4, với IMP `layoutSubviews=0xa202c`, `setupCardContent=0xa21c8`, `setupAppPickerCardsInCardW:cardH:contentY:=0xa35cc`, `setupRecentAppsCardsInCardW:cardH:contentY:=0xa5efc`. Static only, không phải đo hành vi trên xe.

## Cơ chế picker của DuoNavi 1.0.4 đã được xác minh từ ARM64

- `CBMultitaskingOverlayView.setupAppPickerCardsInCardW:cardH:contentY:` gọi `CBDashboardSettings.sharedInstance`, `reload`, `gridCols`, `gridRows`, `hideIconLabels`, tạo `CBOverlayScrollView`, `setPagingEnabled:YES`, tắt thanh chỉ cuộn, `setContentSize:`, tạo `UIPageControl` (`setNumberOfPages`, `setCurrentPage`, `setHidesForSinglePage`, nhận `pageControlChanged:`). Tức là **lưới icon phân trang ngang**, khác hoàn toàn bảng `UITableView` QA trước đây và khác cả bản lưới cuộn dọc trước lượt này.
- ARM64 tại `0xa3830–0xa383c` lấy `gridCols`, chỉ nhận 4, 5 hoặc 6, mặc định **4** nếu ngoài phạm vi; tại `0xa3850–0xa385c` nhận `gridRows` 2 hoặc 3, mặc định **2**. Đây là behavior của bản gốc, không phải số tự chọn tùy tiện. `hideIconLabels` là tùy chọn riêng.
- `setupRecentAppsCardsInCardW:cardH:contentY:` là phương thức riêng, có `CBBridgeManager.runningBridgedApplications` và `closeAllBridgedAppsTapped:`. Bản độc lập tiếp tục dùng danh sách ứng dụng do lõi riêng quản lý; không tải hoặc gọi manager/giấy phép vendor.

## Code UI độc lập đã sửa

- `replacement/visual12/engine/runtime/DFINativePickerCards.inc`: `DFINativePickerCardsController` vẫn là lớp do DuoFace sở hữu, không nhúng binary gốc. Tạo `UIPageControl`, vuốt ngang theo trang (`_scrollView.pagingEnabled`), `pageCount=ceil(apps/(gridCols*gridRows))`, tối đa 4/5/6 cột, 2/3 hàng theo cài đặt `DFIPref(@"gridCols"/"gridRows")` và fallback gốc 4×2; `hideIconLabels`; callback tap card và action recent giữ nguyên. Mỗi page có tọa độ local cố định, `contentSize=pageCount*width`, đánh dấu `currentPage` khi vuốt hoặc chọn chấm. Recent cards vẫn cuộn dọc riêng, không nhập chung grid pages. Commits `6f50749189c9cd554ee9134203de199f3adfb93d`, `93e7372c36a727596d964a8b4b620717b0970472`.
- `replacement/visual12/tests/test_native_shell_structure.py` commit `e3bf0992326b80c899f86e1fc6ef8f6201d46eeb` thêm cổng kiểm tra đường phân trang ngang, chấm trang, gridCols/gridRows fallback và recent color/action, không cho regress sang cuộn dọc QA.
- [Actions 39097535139](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39097535139) **SUCCESS**: test cấu trúc native UI / original104 paged picker, iOS16 ARM64 compile+link, package/lifecycle boundaries và upload **compile-only** dylib. Không có DEB/Sileo mới và không có thiết bị CarPlay được kiểm thử trong lượt này.

## Phân biệt bằng chứng và giới hạn

- Việc `gridCols/gridRows=4×2` fallback, pager ngang và chấm trang **đã được xác nhận tĩnh** bởi original1.0.4; **chưa được chứng minh pixel-perfect** về mọi margin, độ lớn icon, card nền, animation và bố cục Recent của Native12 HUD8 trên DiPlay. Giá trị 8pt gap, cornerRadius 10 và kích thước icon responsive vẫn là lựa chọn do dự án mới thiết kế; tiếp tục so với Native12 approved/binary.
- Cửa sổ `UIWindowLevelAlert+100`, dock/status bar và app scene geometry/bị bó, exitMode đều còn chưa được nghiệm thu trên thiết bị; không coi native picker grid PASS là các lỗi đó đã fix. Giữ `standalone6invalidate`, không đưa ràng buộc giấy phép trở lại.
- Phát hành QA Sileo tự động đang tắt (`.github/workflows/duoface-visual12-standalone-qa-deb.yml` chỉ workflow_dispatch). Native12 HUD8 ổn định và phiên QA Sileo cũ vẫn giữ nguyên. Không tạo/publish DEB chỉ vì source build PASS.

## Next action để tiếp tục ngay

1. Đọc lại repo/nhánh/đầu mối bàn giao, CI/head thật; kiểm tra có phiên khác đã sửa chưa.
2. So sánh tiếp bounded ARM64 original picker card geometry `audit/duonavi-original104-ui/ORIGINAL104_UI_CALLCHAINS.json` và bản duyệt `runtime/fullscreen/DFPickerZoomMenu.xm` (header native 120pt logo, 30pt row, App/Zoom/Style/Close và X). Dùng bằng chứng trước khi sửa 8pt gap/rounded margins.
3. Xác nhận thiếu bar thuộc Dock/status CarPlay hay menu picker từ runtime logs ở cả SpringBoard và CarPlay process; không tự ý thay `windowLevel`.
4. Cần ảnh/log so sánh **thiết bị thực** trước khi tuyên bố tương đương Native12 hoặc phát hành bản giao diện tiếp theo. Lỗi app bó và exitMode vẫn chưa rõ.
