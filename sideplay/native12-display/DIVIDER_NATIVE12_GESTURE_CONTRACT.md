# SidePlay → DuoFace Native12 HUD8: thanh chia có logo và hai thao tác kéo

**Quyết định người dùng ngày 2026-10-18:** giao diện mục tiêu = **DuoFace Native12 + HUD8 đã thống nhất**, không phải SidePlay. Không tạo một divider giả chỉ để trang trí. Gốc SidePlay hiện cho chọn preset `Style` nhưng trên máy chưa có kéo tỷ lệ liên tục.

## Giao diện/phân công thao tác BẮT BUỘC

| Thao tác | Tác dụng | Những gì không được làm |
|---|---|---|
| Kéo **thanh chia** (vuông góc trục thanh) | Thay đổi tỷ lệ hai khung **liên tục**, bao gồm khi 2 app thực đang chạy; cập nhật frame của từng `SPPane` / scene | Không chỉ kéo hình vạch; không chọn vòng lại preset Style; không đổi vị trí logo |
| **Chạm nhanh vào logo** trên thanh | Swap/hoán đổi hai app, giữ bố cục hợp lệ | Không coi là lệnh fullscreen hoặc drag |
| **Giữ logo ≥ 0,30 giây rồi kéo dọc theo thanh** | Dịch chuyển vị trí **logo** trên thanh; với thanh dọc vuốt lên/xuống, với thanh ngang vuốt trái/phải; không ảnh hưởng tỷ lệ chia | Không swap vào lúc nhả tay; không gọi `setRatio:`, không resize pane/app scene |
| Kéo logo trước khi long-press được xác lập, nếu cử chỉ được native xử lý như ratio-pan | Chuyển cho đúng recognizer ratio theo nguồn Native12; chấm dứt khi hủy/chạm lên giao diện app | Không gây hai lần ratio update, không nhận một thao tác đồng thời cho cả ratio-pan và logo-move |
| Zoom In/Out toàn CarPlay | Điều khiển fullscreen theo menu Native12 riêng biệt | Không thay tỷ lệ chia, không đổi relative logo position |

Khi thanh chia **dọc**, tỷ lệ được thay đổi bằng vuốt ngang thanh, còn **logo trượt lên/xuống** dọc theo thanh khi đã giữ. Với thanh chia **ngang**, hoán đổi hướng: tỷ lệ thay đổi bằng vuốt lên/xuống, logo di chuyển trái/phải theo thanh. Không nhầm hai thao tác.

### Tham chiếu Native12 đã có — KHÔNG phân tích lại toàn bộ DEB

- `feature/visual12-duodash-recovery:src/DFDividerLogoGrip.inc`: chạm `onSwap`; giữ `minimumPressDuration = 0.30`; xử lý logo move bằng `setRelativePos:` + `updateGripLayout`; phân biệt nhả sau long hold với touch-up gây swap giả. Giữ `handlePan:` ratio của native khi chạm ngoài logo.
- `feature/visual12-duodash-recovery:replacement/visual12/engine/runtime/DFINativeShell.inc`: UI divider `DFINativeDividerTrack` + nút logo `DFINativeDividerLogo` và 2 gesture recognizer có quan hệ `[pan requireGestureRecognizerToFail:hold]`.
- `feature/visual12-duodash-recovery:replacement/visual12/engine/runtime/DFIInterface.inc`: `moveDividerLogo:` lưu `dividerLogoPositions` độc lập với `fraction/secondary` và không thay scene; `drag:` thay `fraction/secondary` theo delta và layout frame/pane.
- Kích thước visual logo đã trích Native12: hình vuông **28pt** nếu chiều dài thanh dưới **280pt**, ngược lại **30pt**, dựa `CBDividerView.updateGripLayout`; vùng touch phải rộng hơn hình. Nguồn `docs/duoface-native12-comprehensive-dimensions-20261018.md`.
- Vị trí logo tương đối `0.10–0.90` trong QA source chỉ là giá trị triển khai trước, **chưa xác minh trên xe**; không tự gán là literal Native12 đã đo.
- SidePlay **có sẵn host scene/app**; metadata tĩnh `sideplay/native12-display/audit/SIDEPLAY_SPLIT_OWNER_SELECTORS.json` kiểm thấy `SPDash -ratio`, `-setRatio:`, `-layout:`, `-panes`; `SPPane -layoutInFrame:scaleMode:`, `-applySceneFrame:`. Đây là điểm nối cần triển khai/truy dấu theo đúng behavior. Tên phương thức chưa chứng minh setter sẽ tự resize 2 app.

### Điều kiện thành công trước khi báo xong

1. Native12 logo thật hiển thị trên vạch chia (không phải nút Zoom QA nổi).
2. Giữ 0,30s rồi vuốt logo **lên/xuống** khi thanh đứng: logo đổi tọa độ; tỷ lệ/app frames không đổi; nhả tay không swap.
3. Kéo vạch chia **ngang** khi thanh đứng: tỷ lệ đổi liên tục, cả 2 app đang chạy resize/touch đúng.
4. Tap logo: swap đúng các app.
5. Chuyển preset Style, reconnect CarPlay, Zoom In/Out: logo position và ratio không bị mất/tự động hoán đổi ngoài ý muốn.
6. Xác minh trên iPhone X + CarPlay thực bằng ảnh và log; **compile-only không đủ**.

**Trạng thái tại thời điểm ghi:** đã xác minh mã Native12 tham chiếu và các selector SidePlay, **chưa ghép divider/gesture vào SidePlay runtime**, chưa build DEB có tính năng và chưa thử máy. Giữ nguyên gói Native12 HUD8 và DEB SidePlay gốc.
