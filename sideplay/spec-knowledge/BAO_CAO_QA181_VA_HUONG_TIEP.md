# BÁO CÁO CHO CLAUDE SPEC — Kết quả QA181 + đề xuất hướng tiếp (03/11/2026)
Từ: Muse (triển khai). Nguyen yêu cầu báo cáo thẳng cho Spec qua kênh này; Nguyen chỉ chốt cuối.

## 1. Verdict QA181 [ĐÃ ĐO] — export DuoFaceAudit 6.txt (main 208d92044a)
- Maps, 9 chu kỳ (chưa đủ 20 theo giao thức F): applied 6 (cyc 3–8, đều try=1, kbSrc=enum), exhausted 3 (cyc 1, 2, 9). Đạt 67% < cổng 90%. Mô thức hỏng không đổi so với QA179 (61%) và QA180 (50%).
- kbSrc=hook = 0/18 lần đánh giá. Ở 3 chu kỳ exhausted, receiver bắt từ hook không tồn tại ở MỌI nhịp (0/+0,3/+0,6/+1,2s + sự kiện hiện cửa sổ), trong khi phím đang hiện thật (notification DidShow mang end frame {414,175} tại y=561, key window {595,685}).
- Maps khởi động lại dưới QA181 (R1 + R2 guards=ok listen=1 reg=1 có mặt; dòng fit mang trường kbSrc mới) → code QA181 chạy thật trong process.
- Không hồi quy: app-touch Maps 6 + YouTube 4; qa178-hud-gate 4 dòng; không crash mới (2 .ips đi kèm là cặp diskwrites 2026-11-02 cũ).

## 2. Điều CHƯA biết — lỗi đo của Muse (tự thú, Spec cần biết để không kết luận thừa)
- installPhase MẤT: record hook181 bị marker R2 ghi đè trong cùng lượt constructor (mailbox DF156 một ô, ghi liên tiếp). Vì vậy KHÔNG phân biệt được: (i) hook không cài được (no-hook-symbol / abi-mismatch / no-method / hook-failed) với (ii) hook cài ok nhưng UIKit không gọi getter trên cửa sổ này (P2 sai).
- Tóm tắt qa180-cycle mất 0/9 cùng bệnh (QA180 còn vớt được 1/7).
- Suy luận còn đứng được từ kbSrc: nếu getter từng được gọi trên cửa sổ phím đang sống, weak receiver bắt buộc còn ở các nhịp đánh giá trong lúc phím hiện → cả hai giả thuyết (i)/(ii) đều dẫn tới cùng kết luận thực hành: hướng hook getter này không chạm được các chu kỳ hỏng.
- Sửa đường ghi (làm trước mọi bước phím tiếp theo, bất kể chọn hướng nào): gộp installPhase vào chính record R2; tóm tắt chu kỳ đi nhờ record kbdiag kế tiếp thay vì ô riêng.

## 3. Chẩn đoán cấu trúc (tổng hợp 3 vòng, phần [ĐÃ ĐO] + phần [SUY] ghi rõ)
- [ĐÃ ĐO] Hễ cửa sổ phím liệt kê được trong process thì fit frame trúng 100% ngay nhịp đầu (mọi applied ở cả 3 vòng đều try=1). Điểm hỏng duy nhất: ~1/3–1/2 số lần mở, cửa sổ không có trong bất kỳ danh sách cửa sổ nào của process tại mọi thời điểm thử.
- [ĐÃ ĐO] Cửa sổ phím nằm TRONG process app (đọc/ghi frame của nó được ở các chu kỳ applied) và tự lấy kích thước từ UIScreen.mainScreen {414,736} (refSize đo QA180).
- [ĐÃ ĐO] keyboardScreenReferenceSize chỉ responds trên UIRemoteKeyboardWindow (selprobe QA179) — nhưng responds ≠ được gọi khi layout trong ngữ cảnh host.
- [SUY] Hệ thống phải đặt frame cho cửa sổ đó bằng một đường nào đó trong process (setFrame:/setBounds:/setHidden: trên chính lớp cửa sổ, hoặc qua layer) — chưa đo đường nào chạy thật khi phím hiện trong ngữ cảnh host.

## 4. Ba lựa chọn Muse đã đặt cho Nguyen (Nguyen chưa chốt; chờ Spec phân tích + Nguyen quyết)
- A (Muse khuyến nghị): MỘT vòng dò+sửa cuối cho phím — sửa đường ghi log trước, rồi hook cấp class trên UIRemoteKeyboardWindow ở nhóm method đặt khung/hiện (ứng viên: setFrame:, setBounds:, setHidden:, didMoveToWindow) dạng probe-trước: method nào chạy thật khi phím hiện thì sửa frame tại đó (về frame key window như fit hiện tại) ngay trong cùng vòng nếu cổng probe đạt. Kỷ luật dừng: không method nào chạy → dừng hẳn hướng vá phím. Hết phụ thuộc liệt kê + thời điểm nếu trúng.
- B: Mở băng hình học pane-native (scene mang kích thước đích thật) — sửa gốc như bản gốc; thay đổi lớn nhất dự án, chạm DFSceneHost đóng băng, qua cổng 3 điều kiện (Nguyen duyệt mở băng + triệu chứng phi-phím đã đo + premise readback đầy đủ), rủi ro hồi quy chạm/HUD.
- C: Chấp nhận trạng thái phím hiện tại, dồn sức QA182 (Waze) + mặt trận khác.

## 5. Câu hỏi cho Spec
1. Spec đồng ý A là vòng cuối cho phím không? Nếu không, Spec đề xuất điểm chặn nào khác — yêu cầu liệt kê ứng viên Step-0 cụ thể (method/lớp) kèm cách đo, thay vì hướng liệt kê/getter đã chết.
2. Nếu A: phạm vi probe gồm những method nào là đủ mà không quá tay (blast radius trong process app)? Tiêu chí "trúng" để được phép sửa ngay trong vòng là gì?
3. B: Spec còn giữ đóng băng hình học không, hay với bằng chứng 3 vòng, Spec đề xuất Nguyen mở cổng 3 điều kiện ngay từ vòng sau?
4. Thứ tự: QA182 (Waze — relay sống nhưng pipeline phím im lặng) nên đi trước hay sau vòng phím cuối (A)? Hai việc dùng chung relay nhưng khác bài toán.
5. Nguyen đang sốt ruột vì số vòng (lỗi phím đã ăn QA176–181). Spec tối ưu theo tiêu chí ÍT VÒNG NHẤT tới quyết định dứt điểm, kể cả khi kết luận là dừng.
