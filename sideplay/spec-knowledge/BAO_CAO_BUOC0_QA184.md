# BƯỚC 0 QA184 — đọc Audit 7 + các export cũ (03/11/2026, Muse)

Chưa viết code. Bốn mục theo WO, trả lời bằng số đo.

## 1. Trạng thái cài hook QA183 trong R2 (Maps VÀ Waze, cả hai bản)
ls-show = **no-method**; ls-name = ok/own; ls-nameapp =
ok/own; ls-kp = ok/own; ls-traits = ok/inherited;
impl-show = ok/own; impl-del = ok/own; **traits-factory =
ok**; hw-gs = ok; hw-bks = **no-sym**.
Kết luận:
- `UIKeyboardLayoutStar` KHÔNG có method showKeyboard trên
  iOS 16.7.16 -> hook ls-show không tồn tại về cấu trúc;
  fires của nó bằng 0 là tất yếu, KHÔNG phải bằng chứng H2
  và không phải lỗi cài đặt theo nghĩa thông thường.
- ls-name/ls-kp/impl-show/impl-del/factory ĐỀU cài thành
  công -> fires {0,0,0} của chúng không đổ cho cài đặt
  được. Factory cài ok nhưng không record nào tới export
  (twPoint=none) — "không được gọi" và "record mất" vẫn
  không tách được; theo phán quyết của Spec, không cần
  tách nữa.
- hw-bks no-sym: hàm BKS không có symbol trên máy này ->
  một nửa nhóm D chưa từng hook (nửa GSEvent có chạy,
  hwForced=3 ở một record kbsuite1).

## 2. Vì sao 60 skip + 7 restored (Audit 7)
- 60/60 skip đều là reason=already-fit (late=0: 23,
  late=1: 37). KHÔNG có lần nào no-kb-window trong phiên
  này — cửa sổ phím được tìm thấy ở mọi đánh giá.
- 7/7 restored đều reason=did-hide: fit trả cửa sổ về
  {414,736} khi phím ẩn (đúng thiết kế vòng đời, không
  phải lỗi).
- Tỉ lệ cổng ở tầng CỬA SỔ trong phiên này: (9 applied +
  60 already-fit) / 76 = 91%. Bài toán tìm cửa sổ của
  QA179–181 coi như không còn trong phiên này; phần hỏng
  nằm ở tầng NỘI DUNG (mục 4).

## 3. Waze
- hookfire (record độc lập): 0 trong TOÀN export — kể cả
  Maps cũng 0; loại record này không tới được export lần
  này, không dùng kết luận riêng cho Waze được.
- app-touch Waze: 0 (Maps 14, YouTube 7) — khớp gợi ý của
  Spec: chưa có bằng chứng ô nhập Waze nhận focus/touch
  trong export.
- hwKB: 69 mẫu, tất cả = 0, nhưng TẤT CẢ lấy từ capture
  của Maps (Waze không có kbdiag nào) -> không tồn tại
  số đọc hwKB của Waze. Muốn có phải ghi qua record tới
  được export của chính Waze (R2 đã tới được).

## 4. Đối chiếu phiên dọc (audit5 QA179, Audit QA180,
## Audit_6 QA181) với Audit 7 — ĐO THEO NHỊP, và một sửa
## premise chung
Đo HostView width so với bề ngang cửa sổ sau fit, tách
theo nhịp ghi:
- Nhịp applied (late=0, ngay khi fit đặt khung): HostView
  = 414 ở 10/10 (dọc, audit5) và 7/9 (ngang, Audit 7; 2
  lần còn lại đã bằng bề ngang pane 382/509). Tức tại
  khoảnh khắc fit, nội dung CHƯA theo — ở cả hai hướng.
- Các nhịp sau (dòng skip late=0/late=1 của cùng chu kỳ):
  HostView == bề ngang cửa sổ ở 18/18 lần có ghi subs
  (dọc) và 56 lần (ngang: 19 late=0 + 37 late=1), KHÔNG
  lần nào kẹt 414 ở late=1. (Một số dòng không mang subs
  nên không tính.)
- Lần mở gần nhất với ảnh 15:26 (cửa sổ 764, 15:26:20):
  applied ghi HostView=414, nhưng ngay trong cùng giây
  các dòng kế tiếp ghi HostView=764 (2 lần late=0, 3 lần
  late=1). Ảnh chụp trong phút 15:26 có thể rơi vào
  khoảnh khắc đầu của một lần mở (nội dung chưa kịp theo)
  hoặc lần mở ở pane 441 lúc 15:26:08 (một dòng ghi 414,
  dòng kế tiếp cùng giây đã 441).
SỬA PREMISE: câu "pane ngang thì nội dung không theo"
mạnh hơn dữ liệu. Đo đúng là: nội dung CÓ theo ở các
nhịp sau trong CẢ hai hướng; chỗ hỏng tập trung ở nhịp
đầu (và có thể ở những lần mở mà nhịp sau không tới
được người dùng kịp nhìn/gõ). Hệ quả cho WO: fit tầng 2
vẫn đúng hướng — nó ép nội dung theo NGAY và GIỮ — và
tiêu chí đạt nên xét ở nhịp +0,3s + ảnh chụp, không chỉ
trạng thái cuối. Bộ đếm fires đi nhờ dòng kbfit như Spec
đã phán; Muse sẽ gắn cả trạng thái cài (lấy từ R2) vào
lần ghi đầu của phiên trong kbfit để khỏi phải tra R2.

## Việc Muse sẽ làm khi được duyệt (không đổi phạm vi WO)
- Tầng 2 (a)/(b)/(c) chạy ở các nhịp sẵn có của chu kỳ
  fit (0/+0,3/+0,6/+1,2s), ghi frame Container/HostView/
  Replicant vào chính dòng kbfit của nhịp đó.
- (c) lấy h = chiều cao HostView hiện tại (đo thực tế
  216–270), neo đáy cửa sổ sau khi (b) đã đặt Container
  bằng bounds cửa sổ.
- Đếm fires: ls-name, ls-kp, impl-show, impl-del, factory,
  ls-traits (ls-show không đếm vì no-method — ghi rõ
  no-method thay vì 0 để không gây hiểu nhầm H2).
- B–E + KbRotate183: mặc định TẮT bằng cờ tổng KbSuite183
  (vắng = tắt từ QA184; đặt 1 mới chạy lại). Kill switch
  KbFit2_184 vắng = bật.
Chờ Spec/Nguyen duyệt Bước 0 này rồi mới viết code.
