# LỖI HIỆN TẠI — bản đứng 0.0.183~kbsuite1 (cập nhật 03/11/2026, Muse)

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
- ĐÃ PUBLISH Sileo 03/11/2026: bản 0.0.183~kbsuite1 (host
  0.1.183~kbsuite1) là bản đứng hiện tại. Publisher run
  41598365512 SUCCESS đủ 5 job; index công khai kiểm chứng độc
  lập: đúng 1 stanza, DEB tải về trùng hash; retained 129;
  QA182 còn tải được. DEVICE_TESTED=false — chờ test xe theo
  giao thức WO (bật KbRotate183=1 trước phiên).
- Nội dung: đủ 5 nhóm phím + nguồn layoutstar/impl + xoay
  profile; ĐÃ gồm amendment theo Lựa chọn 1 của Spec (Nguyen
  chọn): hook factory +[UIKBScreenTraits
  traitsWithScreen:orientation:] ghi idiom + bề ngang
  (KbTraitsWidth183 / bề ngang key window) lúc traits tạo,
  setScreenTraits: dự phòng, log trước/sau twPoint/twIdiom/
  twW/twSrc; reset bộ đếm chuyển về đầu show. Build cuối: run
  41597779226 SUCCESS, DEB 1.291.816 bytes, SHA256
  b7dbdce0...c72. Hai bản ứng viên bị thay (66012b70 tiền
  amendment; 6a4baf26 bản số Bước 0 giả) KHÔNG hề publish.
- Verdict đọc theo HÀNH ĐỘNG trong log qa183-kbsuite (nameFix>0,
  twPoint/twIdiom/twW đã ghi), không chỉ nhãn profile=; cổng
  khói R2 + bảng quyết định WO giữ nguyên (Spec đã xác nhận ở
  Q1–Q4, báo cáo BAO_CAO_QA183_CHO_SPEC.md).
