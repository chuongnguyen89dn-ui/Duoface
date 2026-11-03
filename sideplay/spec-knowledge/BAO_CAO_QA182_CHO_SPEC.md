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
