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

## Lô 2: đọc instruction gốc, không dựa tên hàm (2026-10-22)
- Fetch_blob c14525b4c0fa1dd13e93a7e754d892b160db1fc3 đọc đủ ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json; fetch_file đối tượng >1MB trả content rỗng, không phải file rỗng trong repo.
- setupPresetCardsInCardW:cardH:contentY: 0xa5e78 có 581 instructions. Gallery thực tạo CBOverlayScrollView (a5ef0–a5f1c); hiện tại bản mới tạo UIView trực tiếp, chưa có scroll gallery.
- Chính xác: inset ngang 14, khoảng cách cột 10, width=(cardW-28-(columns-1)*10)/columns; góc card 12; first row y=22; previewWidth=roundf(cellWidth-14), previewHeight=54, previewTop=6. Selected border 2 và unselected 1; selected card có checkmark.circle.fill 17x17.
- Bản mới: inset6/gap4/corner7, previewHeight<=23, thêm UILabel tiếng Việt cạnh preview và chưa thấy checkmark selected. Đây là khác biệt thực, không được gọi 9 thẻ đồng nghĩa đúng giao diện gốc. Hằng ngưỡng 5/6, row stride, card height đang decode từ địa chỉ Mach-O 0x3117d8/e0/e8/f8, không tự chọn giá trị.
- presetSelected: 0xaa4f0: ghi cùng tag vào splitPreset tại aa55c và splitMode tại aa570; lưu prefs tại aa6a4, post Darwin aa6f0, gọi block onMultiSplitSelected với (tag, copy apps, ratio) tại aa73c–aa76c; dismissOverlay cuối aa78c. Callback không chứng minh chọn Solo tự đảo selected slot, nên CHƯA sửa app order theo giả định.
- CẢNH BÁO chất lượng chứng cứ: LLVM nhiều dòng gắn “Objc message: ...bringSubviewToFront:” dù x1 đã reload selector khác từ stack. Phải theo register/stack/selector ref, KHÔNG lấy annotation cuối dòng làm đích chắc chắn.
- Đã đọc DFHostGeometry.xm, DFFullscreenTransport.mm, DFDashboardChrome.xm: transport có requestID/sequence/lease6s/timeout3s + restore; geometry adapter phụ thuộc CBBridgeManager/CBWindow/CBBridgedSplitApp và không thể nối thẳng sang independent DFNative12Chrome. Chrome hook DB/CARStatusBarWindow không tự chứng minh Apple AppDock. Giữ cơ chế owner validation + rollback, cần adapter riêng có receiver đúng process.
- Đã lưu script decode_gallery_constants.py và workflow native12-original-gallery-constants.yml (commits ea1e0a9,31999f4); tái dùng decoder Mach-O SHA-checked sẵn có, không chạy binary gốc, không phát hành. Local python -m py_compile PASS chỉ kiểm syntax.
- GitHub connector không trả byte DEB gốc: fetch API báo UTF-8 only; fetch_blob binary UnicodeDecodeError. Do đó workflow audit trên runner dùng git show immutable ref như pipeline có sẵn; không yêu cầu upload lại DEB.

## Lô 3: chứng cứ byte mới và sửa gallery có giới hạn rõ
- CI audit 39731899695 SUCCESS giải nén lại DEB immutable SHA 2fe889... và decode trực tiếp Dashboard SHA 9e02a4...; constants/GALLERY_CONSTANTS.json đã lưu. Lượt v2 thêm palette lưu constants-v2/GALLERY_CONSTANTS.json (blob af40cd4cbbf4f606a42cc10a3cbd819aa2bafb30).
- Giá trị thực: threshold560, rowStride78, cardHeight66, contentHeight194. Selected fill RGB(.04,.20,.45)/alpha.95; unselected(.14,.15,.19)/alpha.95; selected border(.12,.58,1)/alpha1; unselected white/alpha.18; badge palette white +(.08,.52,1).
- Source sửa DFNative12Chrome.m: vùng scroll gallery, card frame/margins/gap/radius theo original, bỏ UILabel cạnh preview nhưng giữ accessibilityLabel, thêm checkmark chọn và màu selection gốc. Giữ nguyên 9 tag/selector selectStylePreset và app host/slot dispatch.
- DFNative12GalleryGeometry.h tính đúng nhánh 5/6 và frame metrics. Chưa đổi outer sheet width cap470/header height46 vì chưa xác minh original caller geometry. Vì cap470, nhánh6 chưa được sử dụng trên UI hiện tại; không nói toàn bộ gallery parity hoàn tất. Preview vẫn dùng layout engine hiện có, chưa port đầy đủ raster padding/colors từ helper0x9efe0.
- Local command (cwd /workspace/scratch/0b439c8a40e7): python -m unittest discover -s Duoface/sideplay/duoface-native-scene-host/tests -p test_original_gallery_geometry.py -v → 2/2 PASS. Test thực compile/chạy header C với cc cho widths320,450.3333333,470,559.999,560,600,960 đối chiếu constants gốc và 63 card bounds; test thứ hai kiểm wiring selection + accessibility.
- Chuẩn bị host version 0.1.39~originalgallery1 bằng pipeline hiện có; chưa có kết quả build mới tại lúc ghi. Không ghi đè .38/.31; chưa thay package public; Zoom/Dock, orientation/audio, ExitSafeMode vẫn chưa sửa.
