# Logo .65: kiểm lại lịch sử và gói thật — 26/10/2026

## Phạm vi và khóa thực thi

- Yêu cầu: logo vẫn không kéo lên/xuống sau giữ 3 giây; kiểm lịch sử quét DEB gốc và DEB hiện tại. Đây là lượt điều tra, không thay runtime, build hay Sileo.
- Repo `chuongnguyen89dn-ui/Duoface`, branch `feature/duoface-jb-embedded-appbridge-20261020`, baseline HEAD `acb08afd0b261cd43fe5c12e0b34d23ae8fe938e`.
- Đã đọc toàn bộ nội dung ZIP kỹ năng trung tâm 01-github-continuity, 02-ios-deb-ipa-carplay, 05-research-debug-testing bằng Python zipfile, cùng SKILL_INDEX/PROJECT_INSTRUCTIONS/AGENTS/README.
- API `actions/runs?status=in_progress&per_page=10` trả total_count=0 lúc kiểm tra. Không khởi động job.
- User xác nhận thất bại hiện tại; thông báo không chứa version cài trên thiết bị hoặc log mới. Không quy lỗi cho thao tác người dùng, không đánh dấu .65 device PASS.

## ĐÃ XÁC MINH: lịch sử gốc khác bản bổ sung đã chạy

1. Đọc lại `ban giao du an duoface moi.md`, mục 15/10/2026 (khoảng dòng 2425): người dùng xác nhận native8 **kéo logo được**, đồng thời báo lỗi ratio/nội dung/fullscreen YouTube. Không được gọi native8 đạt toàn bộ.
2. Đọc toàn bộ source lịch sử từ branch `feature/duoface-exact-payload-migration`:
   - `src/DFDividerLogoGrip.inc`, blob `0b14c99ab8ed9283fbb8c98839eb5d0ebc70ad52`.
   - `src/DuoFaceLogoGripOnly.m`, blob `c553782208f716ab47990f0fa2b923d3f32348d7`.
   - `DFLogoGripHold`: Began chốt hold, Changed gọi `DFLogoMoveWithHold`, Ended/Cancelled giữ latch tránh swap muộn. Hàm move lấy tọa độ trong divider, ghi `relativePos`, gọi `updateGripLayout`; native9 giữ nguyên native `handlePan:` bằng compile guard. Ngưỡng lịch sử 0.30s; yêu cầu hiện hành vẫn **3.0s**, không tự đổi về 0.30.
3. Đọc lại toàn bộ 155 instruction của `CBDividerView.handleMoveButtonLongPress:` trong `sideplay/audit/native12-continuation-4888299/direct-original-logo-media-20261024/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json`: `0x10062c cmp state,#1`, `0x100630 b.ne 0x10083c` bỏ qua Changed; nhánh Began gọi onRotate, fallback onSwap. Handler gốc này không phải handler kéo logo liên tục. Di chuyển logo từng thành công là **bổ sung native8/native9**, không thể chỉ nối nguyên handler gốc rồi nói đã có kéo 3 giây.
4. Evidence lịch sử pin original DEB SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`, Dashboard `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`. Lượt này đọc bản quét đã lưu; **không giải nén/quét lại DEB original**, vì artifact original không có trong checkout active branch. Không trình bày việc đọc report là quét binary mới.

## ĐÃ XÁC MINH: gói hiện tại và source tương ứng

- Đã dùng `dpkg-deb -f/-x` trên chính `sideplay/jb-embedded-appbridge/evidence/runs/40165513405/com.duoface.jb.embedded_0.0.65~holdgrip1_iphoneos-arm64.deb`.
- Metadata: `com.duoface.jb.embedded`, `0.0.65~holdgrip1`, `iphoneos-arm64`.
- SHA256 tính lại từ bytes: `7ca600b37430abff1ce2ade68f9fd1a48340f89ed66663395ff4a3f08139fa9c`, đúng provenance đã lưu.
- `DFTouchOwnerProbe.dylib` trong gói có SHA256 `bf75b951db7afbfc182d6e92fe37c664872692609dec9116ba7fc668565cf891`; kiểm bytes chứa đủ marker dedicated recognizer, raw-began, real-touch-timer, moved-position, quick-ratio và `build=0.0.65~holdgrip1`.
- `BUILD_SOURCE.txt`: source `afe19de76365e9c3c64c716c190e8d4d64703f45`, run `40165513405`. `git diff afe19de7 HEAD -- sideplay/duoface-native-scene-host/DFNative12Chrome.m` rỗng.
- Điều này chứng minh candidate chứa phần sửa mới và source hiện tại khớp source build theo provenance. String presence không chứng minh thực thi callback hay thiết bị đang cài gói đó.

## Điểm lệch và đường chặn cụ thể ở .65

Tất cả dòng sau tính trên `DFNative12Chrome.m` tại baseline acb08afd:

| Vị trí | Hành vi xác minh từ source | Giới hạn kết luận |
|---|---|---|
| 906–927 `updateGripBlinkForVisibleSession:` | Pulse 1.18 chạy khi controls visible, không phụ thuộc hold nhận đủ 3s. | Logo nhấp nháy không chứng minh long hold đã nhận. Không đổ lỗi cho animation khi chưa có bằng chứng. |
| 1700–1735 `armLogoRatioDwell` | Perp >=14pt, dominant >1.25 lần parallel, cùng hướng >=~150ms: chốt `logoDraggingRatio=YES`, tăng `logoHoldSerial`. | Đây là lựa chọn Ratio có chủ ý trong thiết kế .63; cũng có thể triệt hold nếu một lần định giữ bị phân loại nhầm. Chưa có quỹ đạo máy hiện tại để xác nhận. |
| 1634–1637, 1774–1780, 1805–1806 | Dedicated recognizer Began, timer và movement backstop **đều** chặn khi `logoDraggingRatio=YES`; timer còn lệch serial. | Thêm UILongPress .65 không cứu được một contact đã chốt Ratio. Không nên tiếp tục tăng allowableMovement để sửa nhánh này. |
| 1653–1655 so với 1783–1789 | Timer/raw có guard hold đã nhận; dedicated Began lại gán lại initial fraction/touch ngay cả khi raw đã nhận hold. | Hai đường cùng viết anchor; có thể mất displacement quanh lúc chuyển quyền, nhưng không đủ chứng minh logo đứng yên suốt lần kéo. |
| 163–171, 1672–1678, 1878–1934 | Raw Ended cập nhật tracked point rồi gọi finish; recognizer Ended không lấy điểm cuối; finish có thể nhận hold tại release nhưng chỉ saveSplitState, không áp dụng delta vị trí cuối. | Nếu không có Changed, release-only fallback không di chuyển logo. Đây là giới hạn code rõ ràng, chưa biết máy hiện tại có thiếu Changed hay không. |
| 124–127, 464–480, 1158–1167 | Nút nới hitbox 12pt nhưng nằm trong UIView/UIWindow divider rộng 32pt; không có mở hit-test tương ứng ở parent/window như CBDividerView gốc. | Phần hitbox nới vượt window không được chứng minh nhận touch; thứ yếu khi chạm đúng tâm. Không dùng làm lời giải duy nhất. |

Nhánh `logoTouchChanged` 1829–1842 có tính fraction và gọi layout thật. Vì vậy nói “thiếu hoàn toàn hàm kéo” hoặc “chưa nối callback nào” là sai. Vấn đề cần phân biệt là **đường chạm có tới nhánh này trong một contact hợp lệ hay không**, hoặc fraction đã đổi mà khung thực bị thay đổi lại.

## Không tái sử dụng sai chứng cứ cũ

- Log .58 theo các báo cáo đã lưu: giữ 3.720475s, UILongPress Failed sau 2.09s với trôi ~12.33pt **song song** và allowableMovement 10pt. Đây không phải bằng chứng người dùng giữ thiếu thời gian, cũng không chứng minh Ratio latch trong .65.
- Các kiểm thử logo trong `tests/test_scenehost_safety.py` chủ yếu `assertIn/assertNotIn` chuỗi source. Ví dụ vẫn cấm tên biến `hold.minimumPressDuration` trong khi .65 dùng `gripHold.minimumPressDuration`; test xanh không chứng minh không có recognizer cạnh tranh hay UIKit gesture PASS.
- Không chạy lại test source và không build trong lượt nghiên cứu này: việc đó không giải đáp input runtime. Không tạo script QA rời cho người dùng.

## Bước kế đủ cụ thể

1. Dùng diagnostic đã tích hợp, không thêm bản log/demo riêng: đối chiếu cùng một contact giữa `raw-began`, `logo-quick-ratio-drag-began-restored-v056`, `logo-3s-timer-suppressed`, `logo-3s-hold-began-*`, `logo-3s-moved-position`, `raw-ended/raw-cancelled`. Xác định version từ build stamp. Chưa có log .65 mới trong dữ liệu đã đọc.
2. Nếu Ratio chốt trước hold: sửa đúng chính sách phân quyền cho contact, bảo toàn quick ratio và yêu cầu 3 giây; không thêm recognizer/timer thứ ba. Nếu mất Changed: sửa ownership/lifecycle và xử lý điểm cuối; không gọi save đơn thuần là đã reposition. Nếu có moved-position nhưng logo đứng: đối chiếu frame/parent/window và dữ liệu layout restore.
3. Khi sửa, dùng một trạng thái contact và một anchor cho Hold; bám nguyên lý native8/native9 (Changed cập nhật vị trí **nút thật**, latch chống swap), giữ runtime độc lập. Bảo toàn Ratio/Swap/Zoom/Dock/video; không copy runtime vendor hay đổi threshold.
4. Tiêu chí: giữ >=3s rồi kéo dọc thực sự di chuyển nút + hitbox, thả giữ vị trí, không swap; quick ratio vẫn resize; reconnect giữ vị trí; menu/Zoom/player không hồi quy. Chỉ nghiệm thu bằng kết quả thiết bị.

## Lệnh thực đã chạy / môi trường

- CWD: `/workspace/scratch/89cd79c46140/Duoface`, Linux, không có UIKit/CarPlay device.
- Clone đúng active branch; `git rev-parse HEAD`, `git status --short`, `git log --oneline -- .../DFNative12Chrome.m`, `rg`/`sed` trên hồ sơ và code.
- Python `zipfile.ZipFile(...).read(...)` cho toàn bộ entries 3 ZIP trung tâm; `json.load(...)` đọc toàn bộ IMP longpress.
- Python `hashlib.sha256(Path(deb).read_bytes())`; `subprocess.check_output(['dpkg-deb','-f',deb,'Package','Version','Architecture'])`; `subprocess.run(['dpkg-deb','-x',deb,tempdir],check=True)` rồi kiểm marker bytes và hash dylib. Temporary extraction tự dọn; binary đầu vào đã lưu trong repo.
- `git diff afe19de76365e9c3c64c716c190e8d4d64703f45 HEAD -- sideplay/duoface-native-scene-host/DFNative12Chrome.m`: không khác.
- Chỉ thêm báo cáo này và checkpoint đầu mối. Không thay source, gói, workflow hay publisher.


- Persistence: local git push failed `could not read Username for https://github.com`; used authenticated GitHub connector instead. Local-only commit 594bf24c is not the remote checkpoint.
