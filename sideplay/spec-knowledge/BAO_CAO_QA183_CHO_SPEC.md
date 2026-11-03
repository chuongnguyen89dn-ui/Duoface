# BÁO CÁO QA183 CHO SPEC — bản kbsuite ĐÃ BUILD (đã sửa theo Bước 0 thật), CHƯA publish, chờ Spec review + lệnh publish của Nguyen

Từ: Muse (implementer). Ngày: 03/11/2026.
Bản: 0.0.183~kbsuite1 (host 0.1.183~kbsuite1), nhánh
feature/duoface-qa183-kbsuite-20261103. DEVICE_TESTED=false.
Build ĐÚNG hiện tại: run 41594761935 SUCCESS (query trực tiếp),
DEB 1.291.168 bytes, SHA256
66012b70b15f892acb0add9246cee020e20713362f83f97ca7e75406930aaaa0
(tải từ evidence về đối chiếu trùng). STATUS đầy đủ ở nhánh QA183:
sideplay/duoface-native-scene-host/STATUS_QA183.md (đọc bản trên
GitHub ở nhánh đó; mục CORRECTION ở đầu file là phần mới nhất).

## 1. SỰ CỐ PHẢI KHAI TRƯỚC (build đầu dựng trên số Bước 0 GIẢ)
Build đầu của vòng này (run 41594008308, DEB 6a4baf26...) được cài
theo ba giá trị lấy từ một bản tóm tắt trung gian GIẢ mạo danh kết
quả của agent Bước 0: tiền tố @"CarPlay_", idiom 1 (pad), refSize
height 270. Báo cáo Bước 0 THẬT (agent tự parse Mach-O bằng tay,
giải mã IMP; về sau build đầu) mâu thuẫn cả ba. Muse phát hiện khi
báo cáo thật về, cảnh báo Nguyen NGAY và TRƯỚC mọi quyết định
publish — bản sai chưa từng lên Sileo. Đã build lại theo số thật
(run ở trên), STATUS + lịch sử đều có mục đính chính. Bài học đã
ghi: không cài code theo kết quả agent khi chưa có báo cáo ở dạng
kiểm chứng được trong tay.

## 2. Bước 0 THẬT (arm64, DuoFaceDashboard.dylib — parse tay + giải mã IMP)
- Sửa tên phím: 2 IMP (setKeyboardName: 0x2b0340,
  setKeyboardName:appearance: 0x2b053c) dùng CHUNG một thuật toán
  3 nhánh: (a) tên nil -> "iPhone-Portrait-QWERTY" hoặc
  "iPhone-Landscape-QWERTY"; (b) tên chứa "(null)" -> thay đoạn
  "(null)" bằng token hướng (log "Corrected (null)..."); (c) tên
  chứa NEITHER "iPhone" NOR "iPad" -> newName =
  "<token>-<tên cũ>" (format @"%@-%@", log "Added prefix...").
  Token chọn theo một biến mode hướng runtime (mode 3-4 ->
  Landscape, ngoài -> Portrait). Tên đã có token thiết bị: giữ
  nguyên (x22 mặc định = tên gốc).
- Idiom: IMP thay thế traitsWithScreen:orientation: (0x2afe1c)
  ghi lên object traits mà orig trả về: setIdiomToEmulate: với
  đối số nguyên 0 truyền qua khe withObject: của
  performSelector:withObject: (movz x3, #0) => idiom = 0 (PHONE);
  setIsEmulatingIdiom: = YES (objc_msgSend trực tiếp, movz x2,#1).
  Có respondsToSelector: guard + bọc exception (log "Exception
  setting idiom emulation on traits").
- Bề ngang: hook keyboardScreenReferenceSize CÓ tồn tại (IMP
  0x2afc3c) nhưng KHÔNG trả số cứng: cờ host tắt -> gọi orig; bật
  -> CGSize{helperW(), helperH()} tính từ CADisplay bounds,
  UIScreen nativeBounds/nativeScale/scale, một double runtime, và
  quét windows của UIApplication. Toàn pool __const không có
  414/736/390/393/768/1024; trong đường width chỉ có 3 hằng số
  học: 50.0, 480.0, 500.0 — vai trò chính xác (sàn/clamp/fallback)
  bộ giải mã tay CHƯA tách hết, ghi là chưa rõ. Helper width này
  còn nuôi keyboardWidthForScreen:withOrientation: (0x2af8fc),
  keyboardWidth (0x2afa94) và một lần ghi setKeyboardWidth: lên
  traits (0x2afed4) — tức bản gốc CÓ ghi bề ngang lên traits,
  QA183 chưa làm việc này.
- Ngoài WO (đã ghi ở vòng quét): hook candidate-list
  (setCandidates:/setCandidateSet:...) và -[UIKeyboardImpl
  setInputMode:]. QA183 không cài.

## 3. Bản build ĐÚNG đã cài gì (đối chiếu WO)
- Nguồn thứ ba layoutstar/impl + nhóm A giữ nguyên (WO mục 2, 1).
- Nhóm B: cài đúng thuật toán 3 nhánh ở mục 2 trên cả hai setter;
  token hướng suy từ hình dạng cửa sổ host (rộng>cao -> Landscape,
  mặc định Portrait — tương đương nhánh mặc định của bản gốc).
  nameFix trong record: 1 = nil->QWERTY, 2 = "(null)" thay, 3 =
  thêm tiền tố. Keyplane nil -> "letters" + cứu sau show như WO.
  KbNamePrefix183=0 tắt toàn bộ sửa tên (chỉ ghi).
- Nhóm C, D: như WO (fallback chỉ khi im-nil/kp-nil; D ghi gốc
  trước khi ép NO khi host; hwOrig trong record là giá trị gốc
  đã ghi, không phải kết quả sau hook).
- Nhóm E: giá trị idiom = 0 (phone) + isEmulating = YES theo Bước
  0 thật; KbIdiom183 trống = phone, "pad" ép 1. ĐIỂM HOOK lệch
  bản gốc: bản gốc ghi trong traitsWithScreen:orientation:, ta
  ghi trong -[UIKeyboardLayoutStar setScreenTraits:] trên cùng
  object traits trước khi layout tiêu thụ — xin Spec phán tính
  tương đương.
- KbRefSize183: giữ vai trò tham số override bề ngang trên đường
  getter QA181 (vẫn mặc định tắt); con số 270 đã xoá, test pin
  sự vắng mặt của nó.
- Xoay profile, log qa183-kbsuite, cổng khói, bảng quyết định:
  nguyên theo WO (STATUS mục Test protocol).

## 4. Câu hỏi cho Spec
Q1. Chấp nhận Bước 0 thật (mục 2) làm cơ sở thay cho các tham số
    WO đã ghi theo hướng tiền tố/idiom cũ?
Q2. Điểm hook nhóm E (setScreenTraits: thay vì
    traitsWithScreen:orientation:) có tương đương đủ để giữ,
    hay phải chuyển điểm hook cho khớp bản gốc ở QA184?
Q3. Ba cơ chế ngoài WO nay đã có bằng chứng code (candidate-list
    hooks, setInputMode: trên Impl, ghi setKeyboardWidth: lên
    traits bằng helper width runtime): đưa vào phạm vi QA184
    ngay, hay giữ nguyên kỷ luật "chờ verdict QA183 rồi tính"?
Q4. Về phía Spec: bản build đúng này đủ điều kiện publish cho
    Nguyen test theo giao thức WO chưa?
