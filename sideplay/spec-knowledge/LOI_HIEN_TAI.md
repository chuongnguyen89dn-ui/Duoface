# LỖI HIỆN TẠI — bản đứng 0.0.184~fit2 (cập nhật 03/11/2026, Muse)

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
- ĐÃ PUBLISH Sileo 03/11/2026: bản 0.0.183~kbsuite2 (host
  0.1.183~kbsuite1) là bản đứng hiện tại. Publisher run
  41598365512 SUCCESS đủ 5 job; index công khai kiểm chứng độc
  lập: đúng 1 stanza, DEB tải về trùng hash; retained 129;
  QA182 còn tải được. DEVICE_TESTED=false — chờ test xe theo
  giao thức WO (bật KbRotate183=1 trước phiên).
- kbsuite2 (thay kbsuite1 cùng ngày): CHỈ khác một điểm —
  KbRotate183 vắng mặt = xoay profile BẬT sẵn, để phiên test
  KHÔNG cần sửa plist bằng Filza (Nguyen phản đối đúng: bước
  đó là việc của Muse; file plist có thể chưa tồn tại trên
  máy anh). Build run 41600272820, DEB 1.292.260 bytes,
  SHA256 bdb7dd0d...b65; publisher run 41601332726 SUCCESS;
  kiểm chứng độc lập đạt; retained 130. Lệch bước bật-cờ của
  WO là có chủ đích, Spec đọc mục này là đủ.
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

## VERDICT QA183 (export Audit 7, 03/11/2026) — KHÔNG ĐẠT
- Phiên chứa cả kbsuite1 (static) và kbsuite2 (p0-182); suite
  KHÔNG bắn hành động nào đo được: nameFix=0, kpFix=0,
  twPoint=none ở mọi record (4 record tới nơi, p1–p3 mất
  record qua mailbox). Tên/kp bình thường sẵn -> B không có
  gì sửa. Điểm traits không ghi lần nào.
- Vỡ trong ảnh đã đo: Maps ở pane NGANG 480; fit đặt cửa sổ
  phím {414,736} -> khung ngang {255..764,480} nhưng nội
  dung giữ {414,270} refSize 414 -> dải phím 414 lệch giữa,
  cụt phải. Là fit QA179 + layout không theo, không phải
  suite.
- Waze: R2 sống lần 4, 0 record phím, Nguyen báo phím không
  hiện. HUD không hồi quy (hud-gate x10).
- Chi tiết + 3 câu hỏi cho Spec: BAO_CAO_VERDICT_QA183.md.
  Chờ Spec phán theo bảng quyết định (H2 tầng B/C?).


## QA184 ĐÃ PUBLISH (03/11/2026) + trả Spec 2 mục

- Bản đứng mới: **0.0.184~fit2 ĐÃ PUBLISH Sileo** (publisher ca5ec688, run 41608884476 SUCCESS 5/5; index công khai 1 stanza SHA 9c9f643b… Size 1293960, DEB tải về trùng, retained 131). Nội dung: fit tầng 2 a/b/c ép nội dung theo cửa sổ + đo sâu class@width vào kbfit + giãn ngang (d) có điều kiện xoay vòng lẻ/chẵn + suite B–E mặc định TẮT + R2 hw= + stage R3 cho Waze. DEVICE_TESTED=false — chờ test xe theo §5 của Spec (ảnh ≥3s, cổng bề ngang view phím sâu nhất nhịp +0,3s ≥90% chu kỳ).
- **Cổng theo CHU KỲ từ Audit 7**: 76 dòng kbfit → 8 chu kỳ, **8/8 có ≥1 applied/already-fit = 100%** tầng cửa sổ (đếm theo nhịp là 91%; đếm utc-only sót dòng tiền tố Chrome).
- **hookfire**: code `DF182Trigger` chỉ ghi record DF182HookFire ở nhánh NGOÀI Maps; Maps đi thẳng vào fit → record không tồn tại theo thiết kế. Waze: record do hook tự ghi qua mailbox đã chứng minh sống; vắng ở 4 export = trigger chưa chạy trong Waze. Đính chính cách nói ở Bước 0 QA184.


## Verdict QA184 (Audit 8, 03/11) — chờ Spec phán

- Maps: 8 chu kỳ pane ngang; fit tầng 2 chạy đủ, chuỗi deep tới UIKBInputBackdropView đều bằng bề ngang cửa sổ (12/12); (d) không kích hoạt (không lệch ở tầng backdrop). Còn dở: khoảnh khắc mở đầu hàng phím vẫn chưa đều (ảnh Nguyen), chạm thì đều + gõ được; chuỗi deep dừng ở backdrop nên hàng phím thật chưa đo trực tiếp; pane dọc chưa có dữ liệu. Chi tiết: BAO_CAO_VERDICT_QA184.md cùng thư mục này.
- Waze: phím sống lần đầu (16 kbdiag, R3 hook bắn, hw=0) nhưng cửa sổ phím vô hình với capture (kbClass=none) — không cần fit theo ảnh.
- App khác không hiện phím: trong phiên không app nào khác thử bật phím; phím là của iOS, điều kiện là ô nhập nhận focus.


## QA185 ĐÃ PUBLISH (03/11) — vòng hình học theo lệnh trực tiếp của Nguyen (thông báo cho Spec)

- Bản đứng mới: **0.0.185~destsize1 ĐÃ PUBLISH Sileo** (publisher 94aab60e, run 41617977680 SUCCESS 5/5; index 1 stanza SHA 3cf5aeb9… Size 1295088, retained 132). DEVICE_TESTED=false.
- Nội dung: đổi hợp đồng hình học sang RENDER THEO KÍCH THƯỚC ĐÍCH (scene = pane, scale 1.0) trong DFHostedMapRenderSize.h, sau cờ DestSize185 (vắng = bật; =0 khôi phục ×2/0.5). DFSceneHost.m không đổi byte nào. Fallback kbdiag của Chrome thêm tiêu chí khớp kích thước (fallback185).
- Ghi rõ để Spec nắm: đây là quyết định của chủ dự án, thay cho (a) trạng thái đóng băng của render-size và (b) tuyên bố QA184 là vòng phím cuối trong phán quyết QA184 của Spec — QA185 là vòng HÌNH HỌC, không phải vòng vá phím. Bước 0 QA185 (bản đồ nơi tiêu thụ hợp đồng ×2, kiểm chứng từng dòng) nằm trong STATUS_QA185 trên nhánh feature/duoface-qa185-destsize-20261103. Verdict QA184 (Audit 8) vẫn chờ Spec phán như cũ; kết quả xe của QA185 sẽ cho biết hợp đồng mới có khép luôn vết phím mở đầu hay không.


## Báo cáo quét A–Z DuoNavi vs QA185 (03/11, chờ Spec đọc)

File: `BAO_CAO_QUET_AZ_DUONAVI_VS_QA185.md` trong thư mục này. Kiểm kê tĩnh toàn diện cả hai deb (class/method/selector/filter/script): gốc là lõi nguyên khối 1 dylib tiêm 24 bundle kèm portal bắt hình, lớp phím tĩnh trong-process, settings một file ~40 khóa, trợ lý 68 method, dock system monitor, sleep assertion/auto-resume, tầng sqlite — và hai chồng ngoài phạm vi làm theo (giấy phép/thương mại, optimizer + helper setuid). Phía ta: 10 dylib theo process, mạnh ở GOFA/decoder/HUD, template scene riêng, hạ tầng chẩn đoán; khoảng trống thật còn lại: portal, phím/chạm trong-process, độ rộng settings (chia 4, scale theo bundle, screenBlank), fullscreen chuyên trách. Hình học đã hội tụ ở QA185 (chờ test xe). Các câu tĩnh không trả lời được liệt kê ở mục 5 của báo cáo.


## Hồ sơ TẬN RĂNG đã nộp (03/11 tối) — đọc thân hàm deb gốc

Bộ 5 file trong spec-knowledge: `BAO_CAO_TAN_RANG_TONG_HOP.md` (tổng hợp + bảng độ bao phủ) và 4 hồ sơ chuỗi: HINH_HOC, PORTAL, VONG_DOI, BANG_HOOK_486. Kết luận thân hàm chính: (1) hình học có cache + file override + sàn usable 100pt, split supersample ×2 trên SLOT (không phải ×2 màn phone) — QA185 thiếu supersample này, cần kiểm chứng nét chữ split khi có máy; (2) ghi settings 2 tầng + hook cả GETTER trạng thái scene (chiến lược giữ scene hai mặt) — host của ta thiếu deactivationReasons/idleMode và tầng đọc; (3) portal = app ở yên màn phone + __UICreateScreenUIImage + chạm IOHIDEvent — né toàn bộ bệnh host trực tiếp; (4) vòng đời: chống flap, lưu bundle khôi phục ra /var/tmp/carbridge_autoresume_bid, hủy lệnh khôi phục khi ngắt, sleep assertion — ta thiếu cả 4; (5) bản đồ 486 hook (phím ~110, icon/dock ~150, media ~30). Mọi hệ quả cho phía ta mới ở mức ỨNG VIÊN, chờ quyết định + log máy, chưa build gì.
