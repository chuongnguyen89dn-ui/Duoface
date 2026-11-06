# B0 — Vì sao native-map ACK QA176 không đồng nghĩa Maps nằm trong ô

Ngày 06/11/2026. Repo: `chuongnguyen89dn-ui/Duoface`; nhánh `fix/qa180-owned-wake-map-replace-20261106`. Đây là chẩn đoán **read-only** ở đường native map, độc lập với A1 logo. Không sửa coordinator, không build/deploy/package; không được xem là B1 PASS.

## Nguồn đã kiểm tra

- Trực tiếp đọc `sideplay/native-carplay-scene-v1/DFNativeMapLaunchRuntime.m` blob `d23bfd140bd19d1d13ad6275d3a59aff9d0c9e5d`, `DFNativeMapPaneCoordinator.m` blob `7d70264250da60d705dbaf31e2411c0b6231778f`, `DFNativeMapLaunchContext.h` blob `d3d6947be820aaf9bd237073bb159bad7b525804`.
- Log thiết bị: `main:sideplay/log/DuoFaceAudit 5.txt`, blob `5eedbc8aadea7558329ea2e1ce4e49054fe24ede`, chỉ các dòng có `build=0.0.176~appwake1`. QA176 đã phát hành `0.0.176~appwake1`, chưa có test xe bản A1 mới.
- Hồ sơ bàn giao `sideplay/tiep tuc du an.md` chứa bằng chứng ACK/teardown, 3 lần (Maps x1, Waze x2), phân biệt thời gian tương quan với nguyên nhân.

## Điều đã chứng minh từ mã nguồn

1. `DFNativeMapLaunchRuntime.m` yêu cầu `DBDashboardRootViewController`, `DBApplicationSceneViewController` thuộc DuoFace, `currentBaseViewController`, và ABI `handleEvent:` tại thời điểm phát hành launch. Các tiền điều kiện này kiểm tra **trước launch/adoption**, không định nghĩa hậu-điều kiện quyền foreground.
2. `DFNativeMapPaneCoordinator.m` `beginPendingLaunch:` khoảng 620–686 gửi launch event một lần bằng `DFNativeMapDispatchLaunchGuarded`. `adoptCommand:` khoảng 490–609 gắn native controller vào pane và kiểm bundle, controller ancestry, adapter `hasVerifiedNativeOwner`, frame. Đến khoảng 596–608, nó ghi `geometryVerified=YES`, `adoptionCommitted=YES`, lưu lease rồi **trả Applied ngay** với `reason=native-owner-attached-physical-frame-observed-map-tiles-not-verified`. Đây là xác nhận adoption/controller/frame, KHÔNG chứng minh pixel bản đồ/touch hay DuoFace còn foreground sau launch.
3. `refreshAdoptedNativeMapBounds` khoảng 794–835 có hậu kiểm hình học/owner một cách định kỳ và logic khôi phục sau một số invalid-frame ticks; **chưa** có cổng để từ chối/thu hồi Applied nếu DuoFace host mất foreground ngay sau ACK. Vì vậy mà màn xe có thể hiện Home mặc dù publisher đã đánh `applied=YES`.
4. Mã Home và picker là các bài toán độc lập. QA175 có đủ 8 request UUID, QA176 có map picker request; **không được sửa lại roster/picker** chỉ vì launch/ownership lỗi. Kiểm roster trên xe chưa PASS (Maps cần hiện trực tiếp trong lưới bất kể CarPlay Settings gốc); icon CarPlay Home phải nghiệm thu riêng.
5. Người dùng cung cấp chỉ mục OmniCar/DuoNavi local và giới hạn `_loadFromProxy:` cho app bridge thiếu declaration; code bản gốc/ABI selectors `sceneFrameForAppInfo:`, `_launchAppWithInfo:` chưa được đọc lại trong môi trường hiện tại. Không được gọi giải pháp 7 hooks là đã được xác nhận trên iOS16.7.16. Không sao chép code/license vendor.

## Điều đã chứng minh từ log QA176

- Google Maps: `07:32:00.771259Z` `qa180-map-replace-finish ... applied=1 ... native-attach-ack`; `07:32:01.196769Z` `qa124-scene-resign-retained-await-background`; `07:32:01.695602Z` CarPlay `native-owner-state ... active=0 visible-candidates=0`; `07:32:02.148482Z` `native12-chrome-stop`.
- Waze có hai chuỗi tương tự `07:32:41–42Z` và `07:33:10–11Z`. QA176 còn `touchowner-stop reason=scene-background-or-external-window-lost` và `dock-reply reason=no-fresh-foreground-session`.
- **Kết luận log:** ba lần ACK gần như ngay trước khi DuoFace mất owner/foreground; đây là timeline correlation mạnh. Chưa đủ để nói chính xác private Dashboard nào chuyển foreground, hoặc scene pixel do ai vẽ. `map-tiles-not-verified` là chưa PASS.

## Cổng triển khai tiếp theo

- **B0 trước thay kiến trúc:** lấy scene identifier + bundle/process + `currentBaseViewController` trước/sau launch và sau 0.3 s, 1 s, 2 s; ghi `DuoFaceActive`, `visibleCandidateCount`, từng UIWindow CarPlay, native Map scene, layout pane; cần log qua đường export có thật (SpringBoard/CarPlay), không phụ thuộc NSLog relay mà logger không thu. Không bỏ owner guard chỉ để lấy ACK.
- **B1 proof một Maps:** trong một pane, không bị takeover fullscreen, đúng bundle/process scene/target frame, Maps render tiles + nhận pan/zoom, DuoFace chrome/foreground vẫn hiển thị, app khác trong ô còn hoạt động, picker roster trên xe đạt; **đặc biệt** idle-hide logo → cú đầu chỉ wake → cú sau Maps nhận ngay trên *scene native*, và direct-logo không SWAP lúc ẩn. Nếu thiếu 1 cổng thì B1 FAILED, kể cả ACK Applied.
- **B2 chỉ sau B1:** thêm Waze/đa ô/resize/Home/lifecycle và giữ scene sống nếu nguyên nhân thật sự lock/background. Không gộp các thay đổi vào cùng một bản phát hành A1; giữ gói signed QA174–176 nguyên byte để rollback.

**Trạng thái:** `B0_SOURCE_TRACE=VERIFIED`; `QA176_LOG_SEQUENCE=VERIFIED`; `NATIVE_POST_ACK_ROOT_CAUSE=HYPOTHESIS`; `B1_DEVICE_TESTED=NO`. Các thay đổi sản phẩm duy nhất trong lượt này thuộc A1, chưa có test vật lý hay bản phát hành mới.
