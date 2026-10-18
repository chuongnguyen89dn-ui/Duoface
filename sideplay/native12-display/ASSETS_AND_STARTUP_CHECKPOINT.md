# SidePlay → Native12 HUD8: kiểm tra ảnh/logo và khởi động ứng dụng

## Chuẩn và phạm vi

- Giao diện đã được duyệt là **DuoFace Native12 + HUD8**. SidePlay chỉ cung cấp khả năng host ứng dụng, không được quyết định giao diện cuối hoặc fullscreen mặc định.
- Nguồn chính: `tiep tuc du an.md`, `ban giao du an duoface moi.md`; tham chiếu `feature/visual12-duodash-recovery:replacement/visual12/engine/runtime/DFINativeShell.inc`, `docs/duoface-native12-complete-ui-class-migration-map-20261018.md` trước khi quét bất kỳ DEB mới.

## Bằng chứng QA3 đã có — phân biệt rõ

| Thành phần | Source/UI | Gói QA3 thực tế |
|---|---|---|
| Logo ngang trên sheet App–Zoom–Style–Close | `DFSPNativeFrame.m` gọi `duoface-logo-picker-alpha-v2.png` | **Đã đóng DEB** tại `/var/jb/Library/Application Support/DuoFaceSidePlayDisplayQA/`, đúng 143191 byte; GitHub Actions [39121326554](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39121326554) log SHA256 `43b6dafb8fc0550c2b3032c11acae1e0712350ca5b4dd235b7dc14c7951c74f7`; **chưa có ảnh xe xác thực bố cục** |
| Logo thanh chia | `DFSPNativeFrame.m` dùng `UIImage systemImageNamed:@"arrow.left.arrow.right"` | **Chưa chuyển artwork Native12** trong QA3 |
| Nút pill lựa chọn ứng dụng | `DFSPNativeFrame.m` dùng `UIImage systemImageNamed:@"ellipsis"` | **Chưa chuyển artwork Native12** trong QA3 |
| Menu App/Zoom/Style/Close | Mã riêng hiện có, nhãn và SF Symbol 16pt | Source/build PASS, kích thước/hit-test/device parity chưa kiểm |
| Toàn bộ hình ảnh và asset Native12 khác | Có asset lịch sử dưới `dist/visual-1.0.3-12/assets/` | QA3 **không** chứa trọn bộ nguồn hình ảnh/logo; không được nói 100% |

## QA4 — thay các hình tạm bằng artwork đã được duyệt

- Nhánh `feature/sideplay-native12-assets-launch` tạo từ trạng thái QA3 đã kiểm.
- `sideplay/native12-display/DFSPNativeFrame.m`: dùng `duoface-picker.png` cho pill, `duoface-swap.png` cho logo vạch chia; chỉ fallback SF Symbol nếu file thiếu. Header giữ alpha-v2 gốc.
- Workflow `.github/workflows/sideplay-visible-zoom-qa-deb.yml` trên nhánh này stage **4 PNG** từ tài sản đã có (không tạo logo thay thế): `duoface-logo-picker-alpha-v2.png`, `duoface-picker.png`, `duoface-swap.png`, `duoface-fullscreen.png`. Bắt buộc chứng minh từng asset nằm trong `dpkg-deb -c`.
- Package QA4 `com.duoface.sideplaydisplay` version `0.1.2~native12assets4`, build run [39121873603](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39121873603). **ĐÃ BUILD VÀ LƯU ARTIFACT QA4:** [Actions run 39121873603](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39121873603) `SUCCESS`; 4 PNG nằm trong `dpkg-deb -c`, toàn bộ `Stage`, `Build`, `Verify`, `Upload`, `Persist` PASS; artifact bền vững `sideplay/artifacts/native12assets4/com.duoface.sideplaydisplay_0.1.2~native12assets4_iphoneos-arm64.deb` SHA256 `82e38059c4f221a2efbf74b090962efe29b7b83c22582dadef4d488e8264a420`, log `QA4_ARTIFACT_PUSH_VERIFIED`. **CHƯA phát hành QA4 lên Sileo, CHƯA test logo trên CarPlay, CHƯA chuyển Native12 splash/app picker.** File fullscreen được stage để chuẩn bị, **chưa được UI QA4 sử dụng**.

## Hai khái niệm khởi động — hiện đều chưa đạt Native12 đầy đủ

1. **Khởi động chính DuoFace trên CarPlay:** Trong Native12, `CBWindow` + `CBSplitContainerView` + `CBSplitSplashScreenView` tham gia xây dựng root và màn khởi động. QA3 hiện móc `SPDash.setCarWindow:` rồi đặt `DFSPNativeFrame` trên SidePlay, **chưa có lớp splash/root chuyển trạng thái Native12 độc lập**. Không tự suy từ việc nút hiện ra rằng đã port startup.
2. **Chọn và khởi động ứng dụng vào một ô:** callback `nativeFrameRequestedAppForSlot:` của QA3 gọi `SPDash.showPickerForPane:`; SidePlay `SPPane.appViewController` + scene host thực mở ứng dụng. **Giữ app host SidePlay là chủ ý** để không phụ thuộc vào mã giấy phép của DuoNavi, nhưng phần trải nghiệm chọn app kiểu Native12 (thẻ app/icon/trang/recent, hành vi khi mở app, trạng thái lỗi, touch) **chưa được port và nghiệm thu**. Source tham khảo Native `DFINativePickerCards.inc`, gốc `CBMultitaskingOverlayView`/`CBSlotPlaceholderView`, nhưng bản QA trước có nhiều bất tương đồng — phải kiểm chứng trên thiết bị, không bê nhầm code QA đã bị từ chối.

## Các bước có thể tiếp tục

- Chờ QA4 build hoàn tất; xác minh 4 PNG trong payload, mã và SHA; giữ QA3 Sileo cho tới khi lựa chọn bản thiết bị test an toàn.
- Chuyển `CBSplitSplashScreenView` **về hành vi giao diện nguồn độc lập**, không import vendor binary; dùng `SPDash` để cung cấp event window/host ready; startup đầu CarPlay phải Normal, native bar hiện.
- Chuyển picker cards UI Native12 (ảnh icon, nhóm/recent, phân trang) nhưng cuối cùng gọi đúng `SPDash`/ `SPPane` để launch app, thay vì dựng scene mới không hoạt động.
- Bảo đảm đã thay phần nào thì ẩn/restore phần cũ tương ứng, không ẩn pane/scene đang chạy. Test thật iPhone X trên CarPlay: app icon → picker → chọn app → chuyển app → Zoom → disconnect → reconnect; đối chiếu screenshot Native12.
