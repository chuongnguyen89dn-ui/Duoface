# DuoFace Mới — phân tích chính xác thời gian nhấn nút logo trên divider (15/10/2026)

## Mục tiêu / ràng buộc mới
Người dùng xác nhận **tap logo hoán đổi trái-phải; giữ im cũng dẫn đến đổi trái-phải**. Yêu cầu **xác minh chính xác ngưỡng nhấn giữ/đường gọi trước khi tính việc giữ rồi kéo logo lên/xuống dọc thanh chia**; không suy đoán thời gian. Giữ chức năng chạm nhanh hoán đổi, giữ kéo tỷ lệ hai ô, Zoom, Style, Close, app picker, CarPlay. **KHÔNG build/package/export DEB hay phát hành Sileo** cho đến khi user yêu cầu. Không sửa `tiep tuc du an.md`, chỉ tham khảo.

## Bằng chứng kiểm thử mới — ĐÃ XÁC MINH
- Repo `chuongnguyen89dn-ui/Duoface` feature `feature/duoface-exact-payload-migration`. Binary nguồn là `DuoFaceDashboard.dylib` **bên trong DEB native6 hiện có**, SHA256 của binary **`6278cf23ddd78026a67b95de704331d5143dac5e43b97eb25cf3c98f10228788`**. DEB native6 pinned SHA256 `88b0e9358c075e2131ddb9e6ac25689584765d1285120e2e3282ce8a5bb3df15`.
- Script read-only `scripts/audit_duoface_divider_mobility.py` commit **`40d919e7dbe50f1780bd980261e448b3d438373a`**, workflow `.github/workflows/duoface-divider-mobility-audit.yml`, run **`38732477874`** job **`116413390426`** `completed success`. Không tạo DEB hoặc deploy.
- Báo cáo persist trên feature `audit/divider/GRIP_MOBILITY_NATIVE6.json` Git blob **`ce9058bb8b7610e9c5cfeebf9c3606cd1f385bee`**; trace `audit/divider/GRIP_MOBILITY_NATIVE6_ARM64.txt`.
- Trong `CBDividerView.configureWithButtonConfigs:`, `0xfedfc ldr d11, [0x310cb0]` đọc double IEEE754 từ binary, `0xff23c mov v0.16b,v11.16b`, `0xff240 objc_msgSend` gọi selector `setMinimumPressDuration:`. **GIÁ TRỊ ĐÚNG TRONG NATIVE6 = 0.4 giây**. Đây là thời gian tối thiểu để recognizer sang trạng thái Began, **không phải độ trễ đo trên màn hình hoặc thời gian animation hoán đổi**.
- Touch-down `UIControlEventTouchDown = 1` và touch-up `UIControlEventTouchUpInside = 0x40`; `0x180` cho Outside/Cancel gắn ở `0xff1d0–0xff218`. `moveButtonTouchUp:` (IMP `0xffeb4`) sử dụng `CBDividerButtonInfo.onSwap`; `handleMoveButtonLongPress:` (IMP `0x1005f4`) chỉ vào nhánh xử lý khi `recognizer.state == 1` (`0x10062c cmp x0,#1`) và đọc `CBDividerButtonInfo.onRotate`. Hai callback là **khác nhau**, dù với hai app, màn hình có thể nhìn như hoán đổi trong cả hai trường hợp.
- `CBDividerView.gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:` IMP `0xfea48` đúng 2 lệnh `mov w0,#1; ret` => **cho recognizers đồng thời**. `CBDividerView.handlePan:` IMP `0x10152c` nhận location/state rồi gọi `_onPanChanged`, chuyển đến `CBBridgedSplitApp.handleDividerPan:isVertical:state:` IMP `0x103ee0`. Đây là đường resize tỷ lệ **khác** với reposition logo.
- `CBDividerButtonInfo._relativePos` ivar offset `16`, accessor getter IMP `0xfe768`, setter IMP `0xfe770`. Trong cấu hình nút, giá trị gốc `0.5` nằm giữa; `CBDividerView.updateGripLayout` IMP `0xff460` dùng `relativePos` để tính frame nút 28/30pt, có clamp hai đầu. `src/DuoFaceVisualHook.m` chỉ phủ ảnh `VisualAssets/duoface-swap.png` lên native UIButton, `userInteractionEnabled=NO` trên overlay, callbacks vẫn native.

## Kết luận / quyết định thiết kế ĐỀ XUẤT, CHƯA TRIỂN KHAI
**Không đơn thuần thêm pan gesture lên logo và giữ nguyên onRotate.** Nếu không, sau 0.4s có thể kích hoạt onRotate (người dùng thấy swap) ngay trước khi kéo; recognizer đồng thời còn khiến split ratio thay đổi ngoài ý muốn.

State machine đề xuất riêng cho nút logo:
1. `idle -> touching`: bắt đầu chạm vào đúng nút. Trong thời gian **dưới 0.4 giây**, nếu nhả và không phải drag, chạy **đúng native onSwap** như trước.
2. `touching -> repositionReady` ở **0.4 giây**: xác nhận giữ, **không chạy onRotate cho riêng nút này**. Chỉ báo nút sẵn sàng kéo; đứng im không tự swap.
3. `repositionReady -> dragging`: ngón tay di chuyển **dọc trục thanh chia**, tính `relativePos = clamp(locationAlongDivider / availableAxisLength)` với chặn hai đầu dựa trên kích thước/hit area thật; gọi native `updateGripLayout`, không thay `splitRatio`. Hướng ngang hoặc bắt đầu drag trên phần divider bên ngoài nút tiếp tục thuộc native resize logic.
4. `dragging -> idle` khi thả/hủy: lưu vị trí mới trong phiên (bền sau reconnect/rotation chỉ khi sau này có yêu cầu và code giữ cấu hình), **đè chặn onSwap/onRotate phát lại ở touch-up nếu đã nhận long-press**, dọn flags khi cancelled. Tap sau đó vẫn swap.
5. Vì method nhận gesture đồng thời trả YES, cần kiểm soát **đúng nút, đúng gesture và điều kiện loại trừ pan tỷ lệ**, tránh đổi global recognizer delegate, tránh tắt toàn bộ CarPlay divider gestures.

### Bất biến & tiêu chí nghiệm thu trong tương lai
- Bấm nhanh vẫn swap trái/phải chính xác (không tự chờ 0.4s rồi swap).
- Giữ >=0.4s không đổi app; kéo lên/xuống trơn tru, thả không tự swap; logo nằm đúng vị trí trong divider và không che các chi tiết người dùng muốn xem.
- Kéo đường chia bên ngoài logo vẫn resize hai ô; không swap trong khi resize và không resize khi giữ-kéo logo.
- Layout hai hoặc nhiều ô, hướng dọc/ngang, reconnect CarPlay, idle auto-hide/blink, hitTest, Zoom/Style/Close/App, các app đang mở vẫn đúng.
- **Chưa chạy bản thử UI trên thiết bị. Chưa patch binary, chưa compile, chưa build hoặc phát hành DEB** trong nghiên cứu này.

## Tiếp tục
Chỉ sau khi user chấp thuận phương án, nghiên cứu thêm đường gắn `onRotate` theo số ô và ghi nhận `onSwap` từ `configureDividerButtons`; thiết kế source-only handler state gating trên **nút** thay vì toàn bộ `CBDividerView`, kiểm tra static/compile-only, commit. Không đóng DEB nếu chưa có lệnh.

**Nguồn lịch sử cũ (read-only):** `tiep tuc du an.md` các checkpoint 2026-10-11 `CBDividerView`, `updateGripLayout`, `handleMoveButtonLongPress:` — không dùng làm bàn giao chính.
