# TRÌNH BÀY LỖI HIỆN TẠI — gửi Claude Spec (cập nhật 03/11/2026)

## Trạng thái đứng
- Bản DuoFace đang trên Sileo: **0.0.179~kbfit1**, đã publish và ĐÃ TEST TRÊN XE
  (iPhone X, palera1n rootless, iOS 16.7.16). Nhánh làm việc hiện tại có đầu
  `1b147c89`; nhánh `spec-main` (nhánh bạn đang đọc) trỏ đúng đầu này.
- Cấu trúc deb gốc làm tham chiếu: file `CAU_TRUC_DEB_GOC.md` cùng thư mục này.
  Source bản QA hiện tại: `sideplay/duoface-native-scene-host/`.
- Chi tiết từng vòng: `sideplay/audit/qa179-kbfit-selprobe-20261103/STATUS.md`
  (vòng gần nhất) và lịch sử sống `sideplay/tiep tuc du an.md` (mục mới nhất ở trên cùng).

## Lỗi 1 — Bàn phím trong app được host (Google Maps): lúc được lúc không [ĐÃ ĐO]
Cơ chế đã đo dứt điểm ở QA178, không tranh luận lại:
- Cửa sổ app được host bị resize (397x685 hoặc 595x685) nhưng cửa sổ bàn phím
  `UIRemoteKeyboardWindow` vẫn lấy kích thước từ `UIScreen.mainScreen` = 414x736
  của điện thoại (transform identity, window level 10000001) → bàn phím tràn
  cửa sổ app, khi trình diễn scale 0,5 thì cụt hàng phím dưới.
- Keyplane đo bình thường (`1510_PortraitTruffle_iPhone-…-Capital-Letters`),
  input mode/hwKB đều bình thường → giả thuyết keyplane ĐÃ LOẠI.
- QA179 đã thêm lớp fit: lúc bàn phím hiện (DidShow), nếu app đang bị host thì
  đặt frame cửa sổ bàn phím = frame key window. Kết quả test xe: **hoạt động khi
  bắt được cửa sổ** (5 lần applied, frame giữ nguyên ở +0,3s) — nhưng **11/28 lần
  đánh giá là skip/no-kb-window**: tại thời điểm đánh giá (kể cả nhịp trễ +0,3s)
  cửa sổ bàn phím KHÔNG có trong danh sách cửa sổ liệt kê được của process.
  Đây chính là gốc của "lúc được lúc không".
- Selprobe QA179 (đo chỉ-đọc, đã có đáp án): `keyboardWidthForScreen:` và
  `keyboardWidth` KHÔNG lớp nào trong 6 lớp được probe responds;
  **`keyboardScreenReferenceSize` chỉ responds trên `UIRemoteKeyboardWindow`**
  → đòn bẩy bề ngang/kích thước tham chiếu nằm ngay trên cửa sổ bàn phím.

## Lỗi 2 — Waze: relay im lặng hoàn toàn, chưa rõ nguyên nhân [CHƯA ĐO ĐƯỢC]
- Qua 4 phiên test, Waze KHÔNG sinh bất kỳ bản ghi relay nào (0 kbdiag / kbfit /
  selprobe / app-touch), dù Waze có trong filter plist + pilot scope và vẫn được host.
- Chưa phân biệt được: dylib không nạp vào process Waze / constructor bail sớm /
  notification không bắn. Chưa có dữ kiện → chưa được sửa mò.

## Việc mở cho QA180 — CHƯA CHỐT, chờ Spec quyết phương án
(a) Tăng độ tin cậy bắt cửa sổ bàn phím cho Maps: thử lại có giới hạn sau DidShow
    thay vì chỉ 2 nhịp 0/+0,3s; và/hoặc hook `keyboardScreenReferenceSize` trên
    `UIRemoteKeyboardWindow` theo đáp án selprobe.
(b) Marker "relay-alive" theo bundle cho mọi app pilot để chốt nguyên nhân Waze
    TRƯỚC khi sửa.
(c) Giữ nguyên cơ chế Maps đang chạy đúng; 1 vòng QA = 1 bài toán chính.

## Vùng đóng băng (không đề xuất đụng)
- `DFSceneHost.m` (theo digest đã chốt), `DFHostedMapRenderSize.h`.
- Hợp đồng hình học: scene giữ logical 414x736 rồi nén bằng transform
  (DFSceneHost.layoutScene) — không đổi.
- Decoder GOFA vẫn shadow: HUD tốc độ vẫn lấy GPS.
- Cấm các chuỗi `setKeyplaneName` / `setKeyboardName` / `setKeyboardWidth` trong relay.

## Cập nhật 03/11 — BƯỚC 0 QA180 (đọc code + đối chiếu log DuoFaceAudit 5, chưa sửa gì)

1. **Maps — vì sao fit lúc được lúc không**: 31/77 lần capture không thấy cửa sổ phím, và đường dự phòng qua UIKeyboardImpl cũng không chạm được đối tượng phím nào (keyplane 0/31). Lúc trượt, trong process app chưa có vật thể bàn phím nào — fit đánh giá quá sớm (2 nhịp 0/+0,3s; 7/11 lần trượt ngay cả ở +0,3s). Hướng: đánh giá fit theo sự kiện UIWindowDidBecomeVisible của cửa sổ Keyboard + thử lại có giới hạn (+0,6/+1,2s, log foundAt).
2. **Waze — relay im lặng**: constructor của relay app-side có 2 tầng dừng không để lại bản ghi: (a) guard đầu vào, nghi phạm riêng là key NSExtension trong Info.plist (chưa kiểm chứng); (b) DF156Listen thất bại thì chỉ NSLog rồi rút, mất cả observer phím lẫn app-touch. Cần marker bisection 2 điểm trong QA180: R1 đầu constructor (không có = dylib không nạp vào Waze), R2 cuối khối async (guard/listen/đăng ký). Chưa sửa Waze trước khi marker trả lời.
3. **Hook keyboardScreenReferenceSize** (chỉ UIRemoteKeyboardWindow responds, i1c1; không thuộc danh sách cấm của test): có thể sửa bề ngang tại nguồn nhưng neo chiều cao vẫn cần fit frame — đề xuất để sau 1 vòng đo giá trị gốc, không làm trong QA180 trừ khi Spec quyết khác.
