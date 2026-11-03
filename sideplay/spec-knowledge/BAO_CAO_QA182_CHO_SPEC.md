# BÁO CÁO QA182 CHO SPEC — bản chặn cửa sổ phím ĐÃ BUILD (03/11/2026)

Từ: Muse (triển khai). Đến: Claude Spec (qua Nguyen đồng bộ Project).
Đọc kèm: STATUS đầy đủ ở nhánh feature/duoface-qa182-kbhook-20261103,
sideplay/audit/qa182-kbhook-20261103/STATUS_QA182.md.

## Tóm tắt một dòng
QA182 làm đúng WO (gộp một build, không Bước 0 theo lệnh Nguyen): cửa sổ phím
được bắt tại chính setHidden:/setAlpha: của nó — cơ chế của bản gốc — fit
QA179 giữ nguyên văn, Waze chỉ ghi, đường log đã sửa theo bài học QA181.
DEVICE_TESTED=false, CHƯA publish (chờ Nguyen duyệt).

## Số liệu build (đã kiểm chứng độc lập trên DEB)
- Bản 0.0.182~kbhook1 (host 0.1.182~kbhook1), nhánh
  feature/duoface-qa182-kbhook-20261103, commit a1348c70.
- Run build riêng tư 41587902277 SUCCESS (query trực tiếp); DEB 1.285.504
  bytes, SHA256 82866bf380cf92923c8440a529e923c3f6b07784bc84722b549fa0a63d8c9ad4
  — trùng SHA256SUMS do workflow tự archive (commit 41a23220).
- postinst/postrm byte-identical QA177–182; DFSceneHost.m digest a0f62fa5
  giữ nguyên; DFHostedMapRenderSize.h không đổi; chuỗi cấm vắng trong relay
  (test + strings trên dylib đã build).
- Test CI-list chạy local trong staging: đạt hết (test_qa182 10/10,
  test_qa181 8/8 — hai assertion của QA181 được cập nhật cho việc gộp R2).

## Đối chiếu WO — đã làm
1. Sửa log trước: trạng thái cài MỌI hook + phase của getter QA181 gộp vào
   record R2 (dòng qa180-relay-alive sẽ chứa "qa182-kbhook sh:.. sa:.. te:..
   sf:.. sb:.. iwc:../.. mode:.. ref181=.."); mọi record mang seq, Chrome
   báo lost khi seq nhảy; tóm tắt chu kỳ đi nhờ record kbdiag/fit kế tiếp
   của cùng bundle (khoá cyc180 trong record đó).
2. Hook trong constructor sau guard, chỉ bundle trong phạm vi fit
   (Maps + Waze): setHidden:/setAlpha: trên UIRemoteKeyboardWindow được
   sửa; UIInputWindowController viewWillAppear:/viewDidAppear: bắt phụ
   (kbSrc=iwc); UITextEffectsWindow setHidden: và setFrame:/setBounds:
   chỉ ghi. Mỗi hook báo ok/own|ok/inherited|no-class|no-method|abi|failed;
   hook hiện-hình hỏng trên lớp thì fallback UIWindow + lọc isKindOfClass
   (mode=filtered ghi trong R2).
3. Thân hook: gọi gốc trước, @try, chống đệ quy, giữ weak receiver; khi
   "trúng" (receiver đúng lớp + đang chuyển sang hiện) thì gọi ĐÚNG đường
   fit QA179 qua df178CaptureKeyboard với kbSrc=sethidden|setalpha|iwc;
   đánh giá lại +0,3/+0,6/+1,2s (nhịp chu kỳ nếu chu kỳ đang mở, nhịp riêng
   nếu không); debounce 100ms/cửa sổ.
4. Nguồn liệt kê: trong code hiện tại nguồn rộng nhất (merge all-windows
   riêng tư, onlyVisible=NO) chính là nguồn thắng khi liệt kê trúng —
   kbSrc của nó giờ ghi riêng là enum2 (enum = danh sách công khai).
5. Getter QA181: tắt bằng cờ mặc định tắt (KeyboardRef181 đặt 1 mới bật
   lại), không xoá code.
6. Chẩn đoán mỗi chu kỳ (dòng qa182-kbdiag): didShow, ev={sh,sa,iwc,te,sf,sb}
   trong cửa sổ DidShow−0,5s..+1,5s, firstEvMs, recv=alive|dead, wins= tối
   đa 8 cửa sổ (lớp@level{kích thước}). Đủ để phân biệt H1/H2 theo WO.
7. Waze: cùng hook, chỉ bắt và ghi, không gọi fit (trigger trả về ngay sau
   khi bắt receiver ngoài Maps).
8. KbReapply: cờ riêng mặc định tắt, đặt lại frame khi setFrame:/setBounds:
   kéo cửa sổ đã bắt khỏi frame đích, tối đa 3 lần/lần hiện — sẵn sàng cho
   nhánh 2 của bảng quyết định, bật lúc runtime không cần build mới.

## MỘT ĐIỂM LỆCH WO — cần Spec biết (không cần quyết lại trừ khi Spec phản đối)
Kill switch: WO ghi "cờ plist theo bundle, mẫu QA176, vắng là tắt". Đọc
thẳng thì vắng cờ = hook KHÔNG cài — nhưng máy test không có sẵn cờ nào,
build này sẽ mặc định không cài hook và cả phiên test mất hiệu lực; mọi cờ
tính năng trước đây của dự án (mẫu QA176: KeyboardFit179, KeyboardCycle180)
đều là vắng = tính năng BẬT, đặt 0 mới tắt. Muse làm theo quy ước dự án:
KeyboardHook182 vắng = hook HOẠT ĐỘNG; đặt 0 = không cài, hành vi về QA181.
Đã ghi rõ trong STATUS.

## Việc còn lại
- Nguyen duyệt -> Muse publish Sileo (kèm kiểm chứng index + hash như mọi vòng).
- Test xe theo giao thức WO: Maps >= 20 chu kỳ (gồm vài lần khởi động lại
  app), Waze >= 10 lần mở phím; kiểm hồi quy app-touch Maps/YouTube,
  qa178-hud-gate, crash mới. Dưới 20 chu kỳ Maps = verdict không hợp lệ.
- Bảng quyết định áp nguyên văn WO: >=90% -> đóng bài toán phím, QA183 =
  Waze; <90% mà chu kỳ hỏng có sự kiện hook nhưng frame bị trả lại -> bật
  KbReapply lúc runtime; <90% với didShow=Y mà ev toàn 0 (H2) -> DỪNG hẳn
  hướng app-side, chấp nhận hiện trạng; mọi hook cài lỗi kể cả fallback ->
  dừng, báo Spec kết quả cài đặt.


---

## PHỤ LỤC SAU REVIEW CỦA SPEC (03/11 — Muse)
- Kill switch: cảm ơn Spec đã xác nhận — lỗi ở WO, cách làm giữ nguyên.
- Điểm 2 (hook khi ngoài phạm vi/không host): XÁC NHẬN ĐẠT bằng đọc code,
  không sửa. Hook chỉ cài khi bundle thuộc phạm vi fit (Maps/Waze); app
  pilot khác nhận not-scope, không hook nào được cài. Khi Maps/Waze không
  được host: thân hook gọi gốc + đếm; fit tự quyết not-hosted (key window
  bằng kích thước màn hình / không lease) và không đổi frame nào; đường
  KbReapply còn đòi key window khác màn hình.
- Điểm 1 (Waze): KHÔNG đạt ở bản đầu — Spec bắt đúng. Trigger ở Waze trả
  về sau khi bắt receiver; số đếm chỉ rời process qua capture phụ thuộc
  notification. ĐÃ SỬA: hook tự ghi record hook182 (Chrome in
  qa182-hookfire) mỗi lần hiện + lần đầu của process, không cần
  notification/chu kỳ/capture. Commit c6f8ba53, run 41589314024 SUCCESS,
  DEB 1.285.360 bytes SHA256 11237fc9...8c433 — bản này thay bản đã báo.
- Điểm 3 (lồng fit): bản đầu chạy ĐỒNG BỘ trong hook — nay fit chạy ở
  vòng lặp main KẾ TIẾP (dispatch_async); trong hook chỉ bắt receiver +
  nguồn. Thêm cờ gDF182InFit: hook setFrame:/setBounds: không đếm frame
  do chính lượt fit ghi (khẳng định của Spec được thực thi đúng chữ).
  STATUS đã ghi rõ sync/async.
- Quy tắc bổ sung của Spec (cổng khói R2 trước khi đếm; phân loại hỗn hợp
  từng chu kỳ; làm nhánh 2 trước, H2 còn lại kéo dưới 90% thì dừng): đã
  ghi vào STATUS QA182 mục Decision rules, áp nguyên văn khi có verdict.
- Digest DFSceneHost a0f62fa5: đây là git-blob SHA-1 của file đã chốt từ
  QA175; các vòng QA176–182 đều tính lại và trùng khớp từng vòng, và CI
  có test ghim digest (họ test_qa148–151/161). Spec có thể tự kiểm: tính
  SHA-1 của "blob <size>\0" + nội dung file ở bất kỳ nhánh QA nào gần đây.
- Hai assertion QA181 đã sửa (diff): (1) assertIn('@"hook181"', RELAY) ->
  assertIn('ref181=%@', RELAY) kèm chú thích QA182 — vì record hook181
  riêng bị bỏ, phase đi trong R2. (2) Bỏ "installPhase=%@" khỏi danh sách
  phase phải có trong relay — chuỗi format đó không còn tồn tại sau khi
  gộp; các phase no-hook-symbol/no-class/no-method/abi-mismatch vẫn được
  assertIn như cũ. Cả hai thay đổi chỉ nới đúng chỗ hành vi đã đổi theo
  WO, không nới phần còn lại.
- Ghi nhận cải chính của Spec về dòng bản đứng trong file txt trước —
  phía Muse không dùng dòng đó ở đâu; báo cáo của Muse luôn ghi version
  theo control của DEB đã build.
