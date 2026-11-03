# ĐẦU VÀO QA179 — Lớp bàn phím tối thiểu (gói gửi Claude soạn spec)

Ngày 03/11/2026. Nguồn: verdict máy thật QA178 (export 08:25 VN, DuoFaceAudit 4.txt), QA178 đã publish Sileo và DEVICE_TESTED=true.

## 1. Kết quả QA178 (đã chốt)

**H2 (HUD chớp lúc thoát) — PASS.** Handover QA177 đã chạy thật: cổng `qa178-hud-gate` ở deactivate/stop ghi pub=1, hidden=0, wasAge=0,64; handover start (snapshotAge=0,65) → done=overlay-visible sau 0,25s. Người dùng xác nhận chớp đã khắc phục tương đối. Phần còn lại (nếu còn) nằm ở đường overlay fallback (attach reason=native-fallback), không thuộc bài toán cổng nữa.

**H1 (chẩn đoán bàn phím) — PASS.** Đo được cửa sổ bàn phím (`UIRemoteKeyboardWindow`), keyplane, dump cửa sổ. Hành vi bàn phím không đổi (đúng thiết kế vòng đo).

## 2. Cơ chế lỗi bàn phím — ĐÃ ĐO ĐƯỢC (không còn là giả thuyết)

Số đo trong process Google Maps khi app được host (kbdiag vòng 3):

- Cửa sổ app (key window): **397x685** (một bố cục khác: 595x685) — app ĐÃ được resize về kích thước suy từ pane.
- `UIScreen.mainScreen.bounds` trong app: **414x736** (kích thước điện thoại).
- Cửa sổ bàn phím `UIRemoteKeyboardWindow`: frame/bounds **414x736**, windowLevel 10000001, transform identity, không hidden.
- Keyplane: `1510_PortraitTruffle_iPhone-Alphabetic-Keyboard_Capital-Letters` — BÌNH THƯỜNG.
- Input mode Telex QWERTY bình thường; tín hiệu bàn phím cứng hwKB=0 (không có bàn phím cứng ảo).
- Host trình diễn scene ở scale 0,500/0,500 (hostT qua fallback của Chrome).

Kết luận cơ chế: hệ thống bàn phím lấy kích thước từ `UIScreen.mainScreen` (414x736) thay vì cửa sổ app đã host (397x685), nên bàn phím rộng và cao hơn không gian hiển thị của nó; khi trình diễn qua scene scale 0,5, phần neo đáy ở y=736 trong không gian cao 685 bị cụt → mất hàng space/enter và bề ngang bị nén/tràn. Đây đúng là mục tiêu can thiệp `keyboardScreenReferenceSize` / `fixedKeyboardWidth` / `setKeyboardWidth:` của bản gốc DuoNavi (đối chiếu tĩnh QA178).

Điểm chưa đo: phiên này chỉ có Google Maps; bàn phím Waze chưa có bản ghi.

## 3. Phạm vi đề xuất cho QA179 (nhờ Claude soạn work order)

Làm lớp bàn phím TỐI THIỂU trong process app (relay DF155 hiện có, và relay YouTube nếu cùng cơ chế):

- Chỉ sửa kích thước tham chiếu/bề ngang mà hệ thống bàn phím dùng để tính layout: làm cho nó tính theo kích thước cửa sổ app đang host (ví dụ 397x685) thay vì `UIScreen.mainScreen` 414x736.
- KHÔNG cần 5 nhóm như bản gốc: keyplane, input mode, tín hiệu bàn phím cứng phía ta đều bình thường (bằng chứng mục 2). Không hook sửa keyplane/input mode/hwKB trong vòng này.
- Vẫn giữ kbdiag vòng 3 để nghiệm thu bằng số: sau khi sửa, frame cửa sổ bàn phím / frame kết thúc thông báo phải bám kích thước cửa sổ app, và ảnh chụp phải thấy đủ hàng space/enter.
- Có công tắc tắt (kill switch) riêng, mặc định trạng thái do spec quyết định; phạm vi app: Maps + Waze trước (Waze đồng thời được đo lần đầu trong cùng vòng).
- Giữ nguyên: DFSceneHost.m (đóng băng digest), DFHostedMapRenderSize.h, hợp đồng hình học logical+scale, decoder GOFA shadow, HUD (QA178 vừa PASS — không đụng cơ chế handover/lease).

## 4. Câu hỏi để spec chốt

1. Điểm hook tối thiểu nào đúng: `keyboardScreenReferenceSize` / `keyboardWidthForScreen:withOrientation:` của UIKeyboardImpl, frame của UIRemoteKeyboardWindow, hay `UIScreen.bounds` (quá rộng — rủi ro toàn app)? Cần Bước 0 đọc code + chọn điểm ít blast radius nhất.
2. Relay lấy kích thước đích từ đâu: tự đọc key window trong cùng process (đã thấy 397x685 ngay trong process — không cần vận chuyển liên process), hay nhận từ SpringBoard qua mailbox DF156?
3. Thứ tự an toàn: Maps trước hay cả Maps + Waze cùng vòng? Tiêu chí dừng nếu frame bàn phím không đổi sau hook.
