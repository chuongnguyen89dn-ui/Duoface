# BÁO CÁO VERDICT QA183 — export DuoFaceAudit 7.txt (03/11/2026, Muse đọc)

Nguồn: commit main de9895292b (tải 15:29 giờ VN), phiên xe
15:23–15:27 chứa CẢ HAI bản: kbsuite1 (pid 12773) rồi kbsuite2
(pid 13080, sau khi Nguyen cập nhật). Nguyen báo miệng + ảnh:
phím chỉ hiện ở Google Maps, app khác không hiện; trong Maps
giao diện phím lỗi (thu hẹp, cụt phía phải). Log KHỚP báo cáo.

## Số đo (toàn phiên)
- kbdiag: 138 bản ghi, 100% com.google.Maps, kbClass =
  UIRemoteKeyboardWindow (69/69 mẫu có trường này).
- kbfit: 76 đánh giá = 9 applied + 7 restored + 60 skip.
- qa183-kbsuite record tới được export: 4 (2 static của
  kbsuite1, 2 p0-182 của kbsuite2) — các record sau bị mất
  trên đường mailbox như các vòng trước; profile p1/p2/p3
  KHÔNG có record nào tới nơi. Hành động suite trong MỌI
  record bắt được: nameFix=0, kpFix=0, twPoint=none
  (toàn file: nameFix>0 = 0 lần, twPoint=factory/lst = 0 lần).
- R2: Maps và Waze ở cả hai bản đều guards=ok listen=1 reg=1
  (relay sống trong Waze — lần xác nhận thứ 4); Waze có
  0 record phím. YouTube: app-touch x7, không mở phím.
- qa178-hud-gate: 10 dòng — không hồi quy HUD trong phiên.

## Cơ chế vỡ trong ảnh — ĐÃ ĐO, không phải suite
Phiên này Maps nằm trong pane NGANG (cao 480) — khác các
phiên trước (pane dọc 685). Dòng fit applied cho thấy:
- kbBefore = {414,736} (cửa sổ phím khổ dọc điện thoại)
  -> kbAfter = khung cửa sổ key NGANG của pane: {441,480},
  {764,480}, {382,480}, {255,480}.
- Nhưng nội dung phím KHÔNG đổi khổ: UIInputSetHostView vẫn
  {414,270}, refSize = {414,...} — layout dựng theo bề ngang
  414 dọc của điện thoại, nằm trong cửa sổ ngang 441–764.
Hệ quả nhìn thấy: dải phím rộng 414 (~54% của 764) lệch giữa,
cụt phải — đúng ảnh 15:26 (dòng fit lúc 15:26:20 ghi kb =
key = {764,480} "already-fit": khung cửa sổ đúng, nội dung
sai). Đây là hợp đồng fit-cửa-sổ (QA179) + layout nội dung
không theo — KHÔNG phải hành động của nhóm B–E (chúng không
bắn gì trong phiên này).
- Tên phím và keyplane BÌNH THƯỜNG ở mọi record:
  iPhone-PortraitTruffle-QWERTY /
  1510_PortraitTruffle_iPhone-Alphabetic-Keyboard_Capital-
  Letters -> nhóm B không có gì để sửa (đúng dự đoán [SUY]
  của Spec ở Q1).
- Điểm ghi traits (factory + setScreenTraits: dự phòng)
  không ghi lần nào trong các record bắt được
  (twPoint=none). Không tách được: factory không được gọi
  trong đường host này, hay record bị mất — NHƯNG hệ quả
  đo được là rõ: bề ngang traits mà layout tiêu thụ vẫn 414.

## Đối chiếu bảng quyết định đã khóa
- Không profile nào đạt (không profile nào có record đạt
  cổng; p1–p3 không quan sát được vì mất record).
- fires của LayoutStar/Impl = {0,0,0} trong mọi record suite
  bắt được trong khi DidShow có bắn (138 capture) — gần điều
  kiện H2 của bảng quyết định ở tầng B/C: hook im lặng dù
  show xảy ra. Muse KHÔNG tự tuyên bố dừng hướng in-process
  vì độ phủ record mỏng (4 record suite) — Spec phán quyết.
- Waze: giữ nguyên trạng từ QA179–182 (relay sống, pipeline
  phím im lặng, phím không hiện theo báo cáo của Nguyen).

## Kết luận của Muse
QA183 (cả hai bản) KHÔNG cải thiện bàn phím; triệu chứng
phiên này do fit cửa sổ ngang + nội dung dọc 414 gây ra và
đã đo được tận số. Lớp suite B–E không tạo hành động đo
được nào trong phiên. Câu hỏi cho Spec:
1. Điểm factory traitsWithScreen:orientation: có thật sự
   không được gọi khi host, hay cần điểm tạo traits khác
   (đo bằng cách nào không phụ thuộc mailbox một ô)?
2. Bảng quyết định: tuyên bố H2 cho tầng B/C được chưa,
   hay còn một nước đi traits nữa?
3. Fit QA179 trong pane ngang: có nên ngừng fit khi khung
   đích là ngang (nội dung không theo được) để tránh làm
   xấu hơn QA182?
DEVICE_TESTED=true cho cả kbsuite1 (ngắn) và kbsuite2.
