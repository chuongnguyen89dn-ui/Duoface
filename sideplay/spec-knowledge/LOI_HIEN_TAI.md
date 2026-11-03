# LỖI HIỆN TẠI — bản đứng 0.0.182~kbhook1 (cập nhật 03/11/2026, Muse)

## Bản đứng
- DuoFace 0.0.182~kbhook1 (host 0.1.182~kbhook1), nhánh
  feature/duoface-qa182-kbhook-20261103, ĐÃ BUILD + kiểm chứng và ĐÃ PUBLISH Sileo ngày 03/11/2026
  (publisher run 41590841195 SUCCESS đủ 5 job; index công khai đã kiểm
  chứng đúng 1 stanza, DEB tải về trùng hash; retained 128).
- QA182 VERDICT MÁY (Nguyen báo miệng 03/11, không kèm log): KHÔNG
  khác gì — QA182 KHÔNG đạt. Lớp còn thiếu so với bản gốc lúc đó:
  B/C/E + tính ép của D (đúng như mục quét deb đã kết luận).
- Báo cáo đầy đủ cho Spec: BAO_CAO_QA182_CHO_SPEC.md trong thư mục này;
  STATUS ở nhánh QA182: sideplay/audit/qa182-kbhook-20261103/STATUS_QA182.md.

## Trạng thái hai lỗi
- Lỗi 1 (phím Maps): QA181 (hook getter) đã có verdict — DỪNG hướng getter
  (kbSrc=hook 0/18, 6/9 = 67% < cổng 90%). QA182 thay cơ chế bắt cửa sổ:
  chặn setHidden:/setAlpha: của chính UIRemoteKeyboardWindow (cơ chế bản
  gốc tự giao cửa sổ), fit QA179 nguyên văn, kbSrc mới
  sethidden/setalpha/iwc/enum2. Chờ verdict xe theo bảng quyết định của WO
  QA182 (đã khóa): >=90% đóng bài toán; nhánh H2 (ev toàn 0) thì dừng hẳn
  hướng app-side.
- Lỗi 2 (Waze): relay sống (R1/R2 ok) nhưng pipeline phím im ở QA179–181.
  QA182 gộp hook chặn vào Waze ở chế độ CHỈ GHI — nếu hook bắt được cửa sổ
  trong process Waze thì câu hỏi "cửa sổ có trong process không" được trả
  lời dứt điểm ngay vòng này; sửa Waze (nếu cần) để QA183.

## Vùng đóng băng (không đổi)
- DFSceneHost.m, DFHostedMapRenderSize.h, HUD/lease/handover, cơ chế chạm.
- Hình học pane-native: vẫn đóng băng (mới đạt 1/3 điều kiện mở).

## QA183 (cập nhật 03/11/2026 chiều)
- ĐÃ BUILD theo WO (đủ 5 nhóm + nguồn layoutstar + xoay profile),
  bản 0.0.183~kbsuite1, build đúng: run 41594761935 SUCCESS, DEB
  1.291.168 bytes SHA256 66012b70...aaa0. CHƯA publish — chờ Spec
  review (báo cáo BAO_CAO_QA183_CHO_SPEC.md trong thư mục này, có
  Q1–Q4) và lệnh publish của Nguyen. DEVICE_TESTED=false.
- Sự cố đã khai trong báo cáo: build đầu dựng trên 3 giá trị Bước 0
  GIẢ (tiền tố CarPlay_, idiom pad, height 270) từ một tóm tắt
  trung gian mạo danh agent Bước 0; báo cáo thật mâu thuẫn cả ba;
  đã sửa trước publish, bản sai chưa lên Sileo.
- Bước 0 thật (tóm tắt): sửa tên 3 nhánh với token
  iPhone-Portrait/iPhone-Landscape (nil -> ...-QWERTY; "(null)" ->
  thay token; thiếu token thiết bị -> thêm "<token>-"); idiom = 0
  (phone) + emulating YES; bề ngang KHÔNG có số cứng (tính runtime;
  hằng 50/480/500 chưa rõ vai trò); helper width còn ghi
  setKeyboardWidth: lên traits; candidate-list + setInputMode:
  vẫn ngoài phạm vi, chờ Spec quyết (Q3 trong báo cáo).
