# Bước khởi động phát triển DuoFace độc lập

**Ngày:** 15/10/2026. **Kho mã nguồn:** `chuongnguyen89dn-ui/Duoface`.
**Nhánh thử nghiệm:** `feature/duoface-independent-core`, tách từ `main` tại `5313d965d56b9325a7d93f74b84a6f7214893df8`.
**Hồ sơ bàn giao chuẩn:** `ban giao du an duoface moi.md` trên nhánh `main`.

## Quyết định: bắt đầu từ khả năng chạy hai ứng dụng, không bắt đầu lại giao diện

Bước đầu tiên cần chứng minh là **hai vùng hiển thị ứng dụng CarPlay có thể được tạo và quản lý mà không tải thư viện lõi DuoNavi**. Đây là phần chưa có bản nguồn độc lập trong kho hiện tại. Không cần làm lại menu, logo hoặc fullscreen khi chưa có vùng chứa ứng dụng độc lập.

Mục tiêu nhỏ nhất của nguyên mẫu:
1. Gói thử có định danh riêng `com.duoface.app` và bộ nạp riêng, không đóng kèm `DuoFaceDashboard.dylib`, `DuoFaceUI`, dữ liệu `com.duonavi.*` hay thư viện Airaw.
2. Khởi chạy được trong phiên CarPlay, xác định tiến trình đang sở hữu cửa sổ và hai vùng hiển thị.
3. Hiển thị đồng thời hai nội dung ứng dụng thật, nhận chạm độc lập và có thể thay đổi tỷ lệ trái/phải.
4. Tắt hoặc gỡ nguyên mẫu không làm ảnh hưởng đến bản DuoFace kế thừa đang có.

**Chỉ khi kiểm thử trên iPhone thật đạt các điều kiện này** mới nối lại giao diện đã duyệt và fullscreen của DuoFace. Biên dịch thành công không phải bằng chứng hiển thị được hai ứng dụng.

## Bảng phụ thuộc đã kiểm tra từ mã nguồn thực tế

| Mã nguồn trong kho | Bằng chứng được kiểm tra | Quyết định |
| --- | --- | --- |
| `runtime/fullscreen/DFHostGeometry.xm` | Dòng 61–89 lấy `CBBridgeManager` và `CBBridgedSplitApp`; dòng 151–173 dùng `CBWindow`; dòng 188–219 móc trực tiếp các lớp trên. Blob `6ca7011005ac0e1c99a70975cc3a7f2fc7d44a62`. | **Không thể mang nguyên xi sang bản độc lập.** Thay điểm nạp cửa sổ, bố cục và trạng thái bằng bộ quản lý của DuoFace mới; giữ ý tưởng lưu/khôi phục kích thước. |
| `runtime/fullscreen/DFPickerZoomMenu.xm` | Dòng 521 móc `CBMultitaskingOverlayView`; dòng 583 kiểm tra lớp này tồn tại. Blob `c7b6b62e7c163bf6f71c49822f0dcf49e52d0c4a`. | Giữ quy cách App/Zoom/Style/Close, logo và trạng thái nút; sau này nối vào giao diện do DuoFace tự tạo. |
| `src/DuoFaceVisualHook.m` | Dòng 162–166 tìm `CBSlotPillView`, `CBBridgedSplitApp` và móc bộ viền. Blob `082520583690ea6c6408aa94faa72427f4504ab3`. | Chuyển hành vi viền/điều khiển sang view/host của bản độc lập, không phụ thuộc lớp cũ. |
| `src/DuoFaceBorderRunner.m` | Dòng 127–149 và 165–183 móc `layoutSplitViews`, `restoreSplitAnimated:` của lớp cũ. Blob `fe13400e58a936c5b8854de34e4b1dc3456ef54f`. | Giữ hành vi viền đỏ theo tương tác đã chốt; cần nguồn phát sự kiện mới. |
| `runtime/fullscreen/DFFullscreenTransport.mm` | Dòng 99 gọi `DFHostSetExpanded` của adapter cũ; nguồn còn có kênh lệnh/trạng thái riêng `com.duoface.fullscreen.*`. Blob `5d955555f91cff614dd7def5af66d6ee8decc9e4`. | Có thể tái sử dụng xử lý lệnh/trạng thái sau khi thay phía nhận lệnh. Không đưa nguyên module vào bản độc lập khi vẫn gọi host cũ. |
| `runtime/fullscreen/DFDashboardChrome.xm` | Có xử lý cửa sổ `DBStatusBarWindow`/`CARStatusBarWindow`, lưu và khôi phục trạng thái ẩn. Blob `2abbaa946f770d0faa9b74e8ca2b45e4a35c5220`. | Có thể tái sử dụng sau khi kiểm tra tương thích thực tế với phiên iOS đích; không cần viết lại trước. |
| `runtime/fullscreen/DFFullscreenCoordinator.mm` | Điều phối lệnh vào/ra fullscreen; blob `45cda41e46c4a9b0e718e237aa0856a8471c5038`. | Giữ logic có thể tái dùng, thay phần điều khiển host. |

**Bằng chứng kiến trúc cũ:** `docs/fullscreen-root-cause-20261014.md` ghi nhận cửa sổ chia đôi cũ thuộc tiến trình SpringBoard (`CBBridgeManager`/`CBWindow`), còn phía CarPlay xử lý dock/chrome. `docs/duoface-v12-native-split-focus-20261014.md` xác minh `focusSlot:animated:`/ `restoreSplitAnimated:` là phóng riêng một ô, khác fullscreen toàn host. Không được nhầm hai loại thu phóng.

## Dự án tham khảo: phân biệt đã có mã nguồn với khả năng chạy thực tế

- `pavunato/carsurf`: `sbtweak/CSCarLaunch.m` có logic lấy `DBWorkspace` trong tiến trình CarPlay để yêu cầu mở ứng dụng; `sbtweak/CSSystem.m` mô tả cách kiểm tra runtime CarPlay. **Đây không phải một bộ chia hai cửa sổ hoàn chỉnh**, và chưa xác minh giấy phép tái sử dụng mã nguồn. Tham khảo cơ chế, không sao chép code.
- `blueskycrb/DualPane`: `Sources/DPSceneHost.m` có các bước làm việc với `FBSceneManager`, `SBApplicationController`, view chứa scene; giấy phép MIT trong `LICENSE`. Đây là bộ quản lý cửa sổ, **không phải** bằng chứng đã chạy CarPlay hai ô; chỉ dùng phần được phép và kiểm tra khác biệt giữa màn iPhone và CarPlay.
- Airaw 1.7.1k: `docs/airaw_171k_fullscreen_binary_findings.md` và `audit/airaw-*` chứa quan sát nhị phân đã phân tích. Chỉ dùng để tham chiếu hành vi, không dùng binary vào bản cài DuoFace mới.

## Phần việc kế tiếp: nguyên mẫu độc lập đầu tiên

**Bước 1 — chỉ thu thập bằng chứng:** lập danh mục các lớp hệ thống CarPlay/scene thực sự có mặt trong iOS đích và đường tạo cửa sổ, dựa trên bản thân runtime. Đích cần đo: `CarPlay`/`CarPlayApp`/`SpringBoard`, chủ cửa sổ, bounds, scene host, trạng thái đang kết nối. Không kết luận khả dụng chỉ vì tên selector tồn tại trong mã nguồn tham khảo.

**Bước 2 — tách phần tải ứng dụng:** tạo bộ nạp độc lập, chỉ dùng namespace `DuoFace`, có cờ tắt mặc định để tránh xung đột với bản đang cài. Không nạp hai lõi lên cùng host trong thử nghiệm.

**Bước 3 — kiểm chứng hai ô:** tạo hai vùng chứa, thử mở hai ứng dụng với hai host scene độc lập, đo kích thước và chạm; phải có khôi phục khi ngắt kết nối/đóng ứng dụng. Nếu thất bại, lưu log và nguyên nhân cụ thể thay vì tạo nút giao diện giả.

**Bước 4 — giữ thành quả:** sau khi Bước 3 **thực sự đạt trên thiết bị**, nối lại App/Zoom/Style/Close, swap, viền đỏ, các nút trong danh sách và fullscreen; chỉ sửa adapter không liên quan đến giao diện đã chốt.

## Phạm vi và trạng thái thực thi tại thời điểm ghi

- Đã đọc source thực tế trên `main`, blob SHA được nêu trong bảng; đã đọc hồ sơ mới và các báo cáo kiến trúc cũ.
- Đã đối chiếu danh sách 15 GitHub Actions gần nhất trên `main`: không có run `in_progress`/`queued` trong danh sách kiểm tra; run DEB cũ `38679315617` hoàn thành `success`.
- **Chỉ tạo nhánh và tài liệu kiểm kê này.** Chưa sửa runtime, chưa tạo hoặc đóng DEB `com.duoface.app`, chưa thử nghiệm CarPlay trên thiết bị, chưa phát hành Sileo.
- Chỉ ghi tiến độ hướng độc lập vào `ban giao du an duoface moi.md` (nhánh `main`). Không cập nhật `tiep tuc du an.md` cũ.
