# 2026-10-28 — 3 ảnh thiết bị: lỗi khởi tạo hướng video, fullscreen làm đúng rồi giữ nguyên khi thu nhỏ

## Nguồn / ranh giới chứng cứ

Người dùng gửi 3 ảnh thiết bị đang hiển thị DuoFace/YouTube, theo đúng trình tự:
1. **Hình 1:** vừa phóng to một ô bằng DuoFace; giao diện CarPlay/dock giữ chiều đúng nhưng nội dung và controls video của YouTube hiển thị xoay ngang sai chiều (quan sát ≈90 độ so với Chrome của CarPlay).
2. **Hình 2:** nhấn phóng to video riêng lên toàn màn hình (theo mô tả người dùng); video hiển thị đúng chiều, dock vẫn hiện. Chưa tách được chắc chắn đây là YouTube built-in full-screen hay một loại zoom khác chỉ từ ảnh.
3. **Hình 3:** thu nhỏ về chia 2 ô, video **tiếp tục đúng chiều**, dù kích thước ô đã thay đổi.

Ảnh do người dùng cung cấp trong lượt chat này, chưa upload GitHub; bản ghi ở đây chứa sự kiện và phân tích, không nhận là có file ảnh trong repo. User chưa chỉ rõ version trong ảnh; theo ngữ cảnh vừa phát hành .84 nhưng **chưa có màn hình Settings/dpkg xác nhận thực sự đang cài .84**. Cũng chưa có trace đồng thời với ba ảnh.

**Device behavior ĐÃ XÁC NHẬN bằng ảnh/lời người dùng:** renderer/video *có khả năng* phát đúng trên cùng phiên, sau một chuyển chế độ riêng; thu nhỏ **không làm mất** trạng thái hướng đúng. Không phải lỗi toàn bộ màn CarPlay xoay, không phải media file mã hóa cố định theo chiều sai. Hướng không lệ thuộc duy nhất vào độ rộng của ô; có yếu tố **trạng thái/sự kiện chuyển chế độ**.

## Đối chiếu đúng mã nguồn hiện tại (nhánh feature/duoface-jb-embedded-appbridge-20261020)

- `sideplay/duoface-native-scene-host/DFNative12Chrome.m` dòng ~1274-1290: `zoomPressed:` chỉ đổi `self.focus`, gửi `FocusLeft/Right` hoặc `Restore`, gọi `layoutControls`; không hề gọi phương thức thay đổi/recompute orientation của UIKit/FBScene.
- Cùng file dòng ~1169-1190: `layoutControls` đổi `UIWindow.frame`, `root.frame`, `appSceneContainers.frame` và child bounds tương ứng với focus. Đây là **geometry của vỏ chứa**, chưa phải xác nhận hướng của view controller/player bên trong app.
- `sideplay/duoface-native-scene-host/DFSceneHost.m` `layoutScene` ~199-227: `if (CGSizeEqualToSize(size,self.lastApplied)) return;`; chỉ thay UIView.transform scale theo logical `round(2×pane)`, hẹn `commitSceneGeometry` sau **0.30s**.
- `commitSceneGeometry` ~229-423: if `size == self.committedReferenceSize`, trả về; gửi content-reference orientation **Portrait=1** cho child/main, rồi `FBScene.updateSettingsWithBlock:` **chỉ khi frame khác**; bên trong chỉ `setFrame:`, `setForeground:`, `setBackgrounded:`, **không cập nhật interfaceOrientation**. Kết quả: chưa có đường **orientation-only reconciliation** nếu video/player thay hướng trong khi ô/frame không đổi; host chỉ biết frame chứ không biết player vừa đổi orientation.
- `DFSceneHost.m` ~271-302: `DFSceneOrientationPolicyInstall/Register` của bản .84 được gọi **trong `commitSceneGeometry`** sau khi đã có live hosted scene và timer 0.30s, không phải trước initial main-scene orientation negotiation. Nên **có nguy cơ đăng ký quá muộn cho lần hỏi supported orientation ban đầu**; hook có mặt ở binary không có nghĩa UIKit đã hỏi lại một lần sau khi đăng ký. Đây là sai khác về **thời điểm**, không chỉ thiếu selector.
- `DFSceneOrientationPolicy.m` ~59-82: hook `_mainSceneSupportsInterfaceOrientation:` trả portrait=1 cho owned handle; hai size setters đổi logical size/giữ orientation parameters. Không có `setNeedsUpdateOfSupportedInterfaceOrientations`, app-owned `requestGeometryUpdate` hay cách đồng bộ riêng player presentation; không ép landscape 3/4. Scope/ABI guard của .84 vẫn phải giữ để tránh crash hệ thống.
- Crash mitigation **known-good**: `DFSceneLifecycle.m` .83 manual-scoped observer và immutable .83 Sileo binary SHA `ced5f42db8b9a3285ccf159386f25e8e5ea0fa976e14c3b35ea24dd625534c9b`. Không chỉnh khi chẩn đoán hướng.

## Diễn giải và mức chắc chắn

**[ĐÃ XÁC MINH từ ảnh + source]** DuoFace pane-focus hiện chỉ cập nhật hình học. Hook hướng của .84 được đăng ký muộn sau khi scene sẵn sàng; không có đường orientation-only sync khi frame giữ nguyên. Video có thể tự đưa về đúng hướng bằng thao tác fullscreen riêng và giữ trạng thái đó khi restore.

**[GIẢ THUYẾT MẠNH, CHƯA DEVICE-TRACE]** YouTube/App remote UIWindowScene hoặc video fullscreen presenter lúc đầu sử dụng orientation/trait/player transform cũ (có thể portrait), còn CarPlay đang landscape. Thao tác fullscreen làm UIKit/AVPlayer đổi orientation/presentation; sau khi trở về 2 ô nó vẫn giữ orientation đã hợp lệ. Không thể chỉ từ ảnh xác định lỗi nằm ở `FBScene.settings.interfaceOrientation`, `UIWindowScene.interfaceOrientation` hay `AVPlayerViewController` internal transform. Không kết luận số orientation phải là 3 hay 4.

**[BÁC BỎ]** Không phải đơn thuần chiều ngang video không hỗ trợ, lỗi bitstream, chỉ sai Dock hoặc chỉ sai aspect ratio của ô: cùng media đúng ngay sau chuyển fullscreen và vẫn đúng khi quay về size ban đầu.

Apple reference:
- https://developer.apple.com/documentation/uikit/uiwindowscene/requestgeometryupdate%28_%3Aerrorhandler%3A%29 — scene geometry/orientation requests là bước riêng, có thể bị từ chối.
- https://developer.apple.com/documentation/uikit/uiwindowscene/geometry/interfaceorientation — interfaceOrientation là giá trị của scene, không suy từ CGRect.

## Bước kỹ thuật tiếp, tuyệt đối không lặp thử vô căn cứ

1. Dùng chính chuỗi tái hiện 3 ảnh để lấy 3 snapshots **before focus → focused wrong → own-video fullscreen right → restored right**, ghi timestamp, bundle, exact live scene/handle generation, pane frame, logical reference size, reference orientations, read-only `FBScene.settings.interfaceOrientation` nếu ABI hợp lệ, và app-owned `UIWindowScene.interfaceOrientation` nếu có một app-side observer đã được xác nhận có quyền/owner. Đọc `DuoFaceDeepTrace.log` các marker `scene-orientation`, `orientation-owner-registered`, `scene-frame-readback`, `scene-frame-unchanged-no-duplicate-diff`, `original-native12-scene-size-dispatch`. Không suy từ việc có hook trên dylib.
2. Kiểm **thời điểm đăng ký** policy với lần đầu queried `_mainSceneSupportsInterfaceOrientation:`; nếu registration sau lần query, cần thiết kế first-party safe owner/generation handshake khởi tạo lại theo scene thật, không broad global hook và không kích hoạt sớm trước sở hữu được kiểm chứng.
3. Chỉ sau khi phân biệt host-scene orientation khác app/video presentation mới quyết định sửa tầng đúng. Nếu owned FBScene đã cùng hướng nhưng video vẫn sai thì tập trung app-owned fullscreen/presentation, không spam `FBScene.updateSettingsWithBlock`. Không force landscape 3/4, không reset YouTube, không ghi đè .83 known-good hoặc sửa Dock/logo/UI.
4. Khi có patch kiểm chứng, đóng gói 1 DEB rootless phiên bản **mới** trên Sileo, vẫn giữ .83 .84 immutable để rollback; tiêu chí nghiệm thu: **vừa bấm DuoFace phóng một ô đã đúng** mà không cần bấm nút fullscreen video; trở lại 2 ô vẫn đúng, video play/seek, không crash.

**State:** Mới là checkpoint phân tích và hình ảnh thiết bị, KHÔNG có source patch .85, signed build hay device-fix-pass trong lượt này.
