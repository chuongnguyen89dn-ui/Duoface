# Hội đồng kỹ thuật DuoFace x Muse AI — vòng 1 (2026-10-25 ICT)

**Trạng thái:** GPT nghiên cứu độc lập, **CHƯA có câu trả lời từ Muse AI**; nghiên cứu và phản biện trước khi sửa mã. Không build, không kích hoạt workflow, không sửa Sileo trong vòng này.

## Execution lock và nguồn
- Repo: `chuongnguyen89dn-ui/Duoface`; nhánh hoạt động: `feature/duoface-jb-embedded-appbridge-20261020`; checkpoint người dùng: `98f1c141c87b7ce30b8157e7bd452638740b4233` (24/10 UTC).
- Gpt-training-: đọc SKILL_INDEX.md, AGENTS.md, PROJECT_INSTRUCTIONS.md; đọc được trực tiếp từ ZIP `skills/01-github-continuity.zip`, `skills/02-ios-deb-ipa-carplay.zip`, `skills/05-research-debug-testing.zip` (SKILL.md và phần VERIFICATION), không cần tải ZIP lên ChatGPT.
- Bản phát hành được chứng minh theo checkpoint: `com.duoface.jb.embedded 0.0.62~rawgrip1`; packaging run `40053489952` SUCCESS; SHA256 `2a2589e2fa39fcf272890b55d0cdf02c9a91ff5df5f8ea6c47acd85b4eef9627`; Sileo public publisher `carplaydsp` run `40053794389` SUCCESS theo hồ sơ. Mốc này chỉ chứng minh phát hành, **không chứng minh tay người dùng đã cài .62 / chức năng hoạt động**.
- File gốc hướng dẫn/đối chiếu: `sideplay/tiep tuc du an.md`; `sideplay/audit/native12-logo-touch-20261024/RAW_GRIP_062_BUILD_AND_SILEO.md`; `sideplay/audit/native12-039-regressions-20261023/ORIGINAL_VS_CURRENT_LOGO_MEDIA_CRASH_20261024.md`; original ARM64 report `sideplay/audit/native12-continuation-4888299/direct-original-logo-media-20261024/REPORT.md`.
- Source mới đọc từ GitHub branch: `sideplay/duoface-native-scene-host/DFNative12Chrome.m` (blob `930ea9...` cần xác nhận SHA riêng nếu sử dụng), `DFSceneHost.m` blob `8158cf23288092fb374101ab090b09ab87696539`. Chỉ dùng các tệp repo này; không sao chép hay bỏ qua giấy phép của tác giả khác.

## ĐÃ XÁC MINH
1. Người dùng đã phản hồi logo KHÔNG chạy ở bản **trước khi** .62 được chấp nhận thực tế. Log .58 có chạm thực **3.720475 giây**, nhưng `UILongPress` Failed ở 2.09 giây khi ngón tay dịch ~12.33pt so với ngưỡng 10pt. Người dùng đã giữ đủ lâu; không quy lỗi thao tác.
2. Tại `DFNative12Chrome.m` .62, `DFNativeDividerGripButton` là subclass UIButton xử lý trực tiếp `touchesBegan/Moved/Ended/Cancelled` (~113–184), callback đến `logoTouchDown/Changed/Finished` (~1572–1735). Giữ 3s mở chế độ dời LogoFraction; kéo vuông góc đổi Ratio; chạm ngắn Swap. Parent `dividerTrack` có `UIPanGestureRecognizer` và delegate `shouldReceiveTouch` bỏ qua vùng logo (~468–474, ~870–876).
3. `layoutControls` tạo cửa sổ divider rộng **32pt**, `dividerWindow.frame` bám mép chia (~1104–1129); logo 28–30pt, `pointInside:` mở rộng thêm **12pt mỗi hướng** (~124–128). **Vấn đề hình học ở mã:** UIHitTest UIView/UIWindow mặc định không truyền touch từ phần nằm **ngoài bounds cửa sổ cha**. Vì vậy lời bình luận "expanded 12pt target" không đúng với toàn bộ phần vượt 32pt window. Đây là **cấu trúc có thể chứng minh từ source và nguyên lý UIKit**, còn việc người dùng chạm vào phần đó gây lỗi hay không **CHƯA THỬ**.
4. `DFNativeActivityObserver` gắn lên chính external window, `cancelsTouchesInView=NO`, thất bại ngay sau khi quan sát touchesBegan (~188–206, ~357–375). Việc ảnh hưởng thật đến raw UIButton/chạm sau 3s chưa có log .62.
5. `DFSceneHost.m` (~229–270) hoãn hoặc bỏ remote content-reference cập nhật ở nhánh `if(self.ready)` để tránh crash; local UIView transform 2x (~188–223) không chứng minh thay đổi kích thước native player. Báo cáo gốc cho thấy **85 lần child3=1 ở session cũ**; tuy nhiên 3 .ips SpringBoard SIGABRT đều đi qua `SBAppViewController sceneHandle:didUpdateSettingsWithDiff:previousSettings:` +440. Chưa biết assertion nguyên văn. Không được bật bừa private frame mutation hay ép landscape.
6. Actions API truy vấn 2026-10-25: `status=in_progress` của repo DuoFace trả **0**; trạng thái chỉ đúng tại lúc truy vấn.

## GIẢ THUYẾT CẦN MUSE PHẢN BIỆN
- **H1 (hit routing):** 32pt external UIWindow cắt vùng nhận touch dù UIButton nới pointInside 12pt; cùng lúc nhiều UIWindow menu/slot có z-order và chế độ hidden thay đổi khi user tap; cần chứng minh `UIWindow hitTest:withEvent:` trả về đúng button trên thiết bị ở ba vị trí trong/ngoài cửa sổ.
- **H2 (touch ownership):** `observeActivityInWindow`, parent UIPan, CarPlay remote input hoặc relayout sau `noteUserActivity` ngắt chuỗi `raw-began → held → moved → raw-ended`. Chỉ suy luận sau khi xem log .62 có ID + timestamp. Cần biết liệu `touchesCancelled` xảy ra và `dispatch_after` có bị vô hiệu vì `dividerWindow.hidden`.
- **H3 (media and crashes):** thiếu owner/scene commit theo lifecycle và per-app renderSize; trường hợp .58 private setter/chủ scene nhận trước khi ready dễ tạo lỗi. Phải thiết kế reader-only selector probe và test isolated guarded transaction, tuyệt đối không bật toàn cục ngay.

## Câu hỏi chính chuyển Muse AI
Dựa trên mã và log/ARM64 ORIGINAL thực (không phỏng đoán), hãy **phản biện** giải pháp .62 raw-grip: Vì sao vẫn có thể không kéo logo sau 3 giây? Đưa ra **ba nguyên nhân xếp theo sức mạnh bằng chứng**, ghi chính xác file/hàm/dòng, một ma trận quan sát giúp phân biệt từng nguyên nhân trên thiết bị và **một bản vá tối thiểu duy nhất** không phá Ratio, Swap, Zoom, Dock và video. Sau đó nêu phương án tách biệt cho remote player không bó khung và SIGABRT scene-settings, kèm điều kiện dừng/rút lại khi crash. Nghiêm cấm cho rằng CI/DEB xanh là đã nghiệm thu thực tế; không chỉnh mã/giấy phép/DEB khi đang phản biện.

## Kế hoạch xác nhận chung, chưa thực hiện
A. Xác nhận thiết bị đang cài đúng `0.0.62~rawgrip1` chứ không phải .61; ghi log chính xác `/var/mobile/Library/Logs/DuoFaceTouchOwner.log`, `DuoFaceDeepTrace.log` và `DuoFaceSceneHost.log`.
B. Chỉ thực hiện tại xe đỗ; test chạm vào tâm logo rồi giữ 3s, dịch **song song** đường chia, buông; riêng test kéo **vuông góc**, nhấn ngắn Swap. Đối chiếu `logo-control raw-began` → `logo-3s-hold-began-real-touch-timer` → `logo-3s-moved-position` → `raw-ended` cùng state `LogoFraction`; đọc `raw-cancelled`/suppressed khi fail.
C. Không có `raw-began` dù bản .62 đang cài: ưu tiên hit-route/window owner; có `raw-began` nhưng cancelled/missing held: xử lý touch lifecycle; có held+moved nhưng không di chuyển: kiểm offset/coordinate-space và persist.
D. Media: chỉ read-only log nguồn selector/callback và scene generation trước khi cho phép 1 giao dịch frame có rollback; cùng lúc lấy .ips mới, không kích hoạt thử nếu xe đang di chuyển.

## Bằng chứng ngoài repo
- Apple UIView hit test: https://developer.apple.com/documentation/uikit/uiview/hittest%28_%3Awith%3A%29
- Apple QA1812 (outside parent bounds): https://developer.apple.com/library/archive/qa/qa2013/qa1812.html
- Apple UIGestureRecognizer cancellation: https://developer.apple.com/documentation/uikit/uigesturerecognizer

## Vòng tiếp theo
- Muse AI phải trả lời với phân loại `ĐÃ XÁC MINH / GIẢ THUYẾT / CHƯA THỬ`; GPT đối chiếu từng khẳng định với repo trước khi chấp thuận thay đổi.
- Đến khi có dữ liệu .62/Muse: **không chỉnh source, không tạo DEB 0.0.63, không push Sileo**.
