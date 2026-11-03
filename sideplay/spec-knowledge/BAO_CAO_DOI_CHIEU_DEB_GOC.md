# ĐỐI CHIẾU TOÀN DIỆN: DEB GỐC (DuoNavi 1.0.3-12) vs DEB HIỆN TẠI (QA181) — VÌ SAO PHÍM CỦA TA HỎNG MÀ CỦA HỌ KHÔNG

Ngày: 03/11/2026. Phương pháp: phân tích read-only (bung deb, strings) trên DuoFaceDashboard.dylib của bản gốc và DF155GeneralAppStateRelay.dylib của QA181 (DEB tải từ repo Sileo, SHA256 d0f34b95…a7e khớp bản đã publish). Không chạy bất kỳ binary nào. Bằng chứng là chuỗi log/selector trong chính binary của họ — mức cơ chế, không phải code của họ.

## 1. Bề mặt hiện diện
- Bản gốc: DuoFaceDashboard.dylib (7,2MB) tiêm vào SpringBoard/CarPlay VÀ ~22 app, **có cả com.google.Maps và com.waze.iphone**. Toàn bộ lớp phím [DuoFaceKB] (82 chuỗi) nằm trong dylib này — tức code của họ chạy ngay trong process của Maps/Waze.
- Ta: DF155GeneralAppStateRelay tiêm vào 14 app pilot, có Maps + Waze. Phạm vi hiện diện tương đương — khác nhau ở CƠ CHẾ bên trong.

## 2. Khác biệt quyết định: kiến trúc kích hoạt NGƯỢC nhau

| Bề mặt (đếm chuỗi trong binary) | Bản gốc | QA181 của ta |
|---|---|---|
| Dựa vào UIKeyboardDidShowNotification | **0** | 2 (toàn bộ pipeline fit của ta) |
| Hook setHidden: / setAlpha: trên cửa sổ phím | 6 / 6 | **0 / 0** |
| Hook vòng đời UIInputWindowController (viewWillAppear/viewDidAppear) | có (log riêng) | 0 |
| Can thiệp UIKeyboardImpl (setDelegate:, showKeyboard, ép inputMode dự phòng) | có | 0 (chỉ đọc activeInstance) |
| Mô phỏng idiom trên traits (setIdiomToEmulate:) | có | 0 |
| Họ hàm bề ngang (fixedKeyboardWidth, setKeyboardWidth:, keyboardWidthForScreen:) | có | chỉ có getter QA181 (đo ra không được gọi) |
| Liệt kê cửa sổ (allWindowsIncludingInternalWindows:) | 4 (dùng cho việc khác) | 1 — nguồn cửa sổ DUY NHẤT của ta |
| renderSize / updateSceneSettingsFrame (hình học phía app) | 8 / 6 | 0 |

Chuỗi log của chính họ xác nhận cách làm:
- `[DuoFaceKB] [UIRemoteKeyboardWindow setHidden:%d] frame=%@`
- `[DuoFaceKB] [UIRemoteKeyboardWindow setAlpha:%.2f]`
- `[DuoFaceKB] [UITextEffectsWindow setHidden:%d] frame=%@`
- `[DuoFaceKB] [UIInputWindowController viewWillAppear:%d]`

## 3. Chẩn đoán: lỗi của ta nằm ở đâu
1. **Ta đi tìm cửa sổ; họ để cửa sổ tự đến.** Mọi lần phím hiện, hệ thống PHẢI gọi setHidden:(NO)/setAlpha: trên chính cửa sổ phím — họ chặn đúng hai method đó (và của UITextEffectsWindow), receiver của lời gọi chính là cửa sổ, kèm frame ngay tại thời điểm hiện. Không liệt kê, không thông báo, không đua thời gian — nên họ không bao giờ "không thấy cửa sổ". Ta thì: nhận notification → liệt kê cửa sổ ở 4 nhịp → ~1/3–1/2 số lần cửa sổ không nằm trong bất kỳ danh sách nào của process (đã đo QA179/180/181) → bó tay. Thang thử lại hay hook getter (QA181) đều không chạm được vì sai điểm chặn: getter không được gọi trong ngữ cảnh host [ĐÃ ĐO qua kbSrc=hook 0/18].
2. **Ta thiếu lớp sửa bề ngang ở tầng keyboard implementation** (họ hàm fixedKeyboardWidth) — ta chỉ có fit frame sau khi bắt được cửa sổ và hook getter (không hiệu lực).
3. **Ta thiếu mô phỏng idiom trên traits** — yếu tố phụ ảnh hưởng cách phím tự layout.
4. Hình học phía app (renderSize) là khác biệt đã biết và đang đóng băng; nhưng lưu ý lớp KB của họ tồn tại độc lập với hình học — chính họ cũng không dùng hình học để sửa phím. Điểm chặn cửa sổ mới là thứ làm phím của họ ổn định trong một kiến trúc mà cửa sổ vẫn do hệ thống tạo.

Hệ quả phụ cho Waze: pipeline của ta im lặng trong Waze vì nó sống bằng notification + kênh hub; cơ chế chặn method KHÔNG phụ thuộc notification — nếu áp cùng cơ chế, bài toán Waze có thể mở ra cùng lúc (hook cài được + setHidden: bắn là tự có bản ghi).

## 4. Hướng sửa dứt điểm (một bản, không dò từng chút)
Viết lại khâu bắt cửa sổ phím trong relay theo cơ chế chặn (code của ta, theo bằng chứng cơ chế ở trên):
- Hook MSHookMessageEx trên **UIRemoteKeyboardWindow setHidden: + setAlpha:** và **UITextEffectsWindow setHidden:**, cộng **UIInputWindowController viewWillAppear:/viewDidAppear:** làm đường bắt phụ. Receiver = cửa sổ phím → giữ weak như D3 của QA181 (code đó chuyển nguyên sang, chỉ đổi method nguồn).
- Ngay tại setHidden:(NO) khi đang host: đặt frame cửa sổ = frame key window (đúng phép sửa fit hiện tại) — cửa sổ vừa hiện là đã đúng khung và đúng neo đáy, không chờ nhịp nào.
- Giữ fit theo notification hiện tại làm dự phòng; giữ nguyên cờ kill switch (mở rộng cờ KeyboardRef181 hoặc cờ mới); sửa đường ghi log trước (installPhase gộp vào record R2; tóm tắt chu kỳ đi nhờ record kbdiag) để bản này không mù như QA181.
- Phạm vi: Maps trước như kỷ luật cũ, nhưng cơ chế không phụ thuộc notification nên Waze vào cùng bản ở chế độ chỉ-bắt-và-ghi (chưa sửa) để trả lời luôn câu hỏi QA182, hoặc gộp sửa nếu Nguyen duyệt.
- Tiêu chí đạt giữ nguyên: (applied + already-fit) ≥ 90% trên ≥ 20 chu kỳ, lần này "applied" tính cả các lần sửa ngay tại setHidden:.

Giới hạn trung thực: bằng chứng là chuỗi log/selector của họ (họ chặn gì) chứ không phải code; việc sửa frame tại setHidden: có đủ cho layout phím bên trong hay phải thêm tầng bề ngang kiểu fixedKeyboardWidth là câu hỏi thiết bị — nhưng khác QA181, setHidden: CHẮC CHẮN bắn mỗi lần phím hiện (đó là cách cửa sổ hiện lên), và mẫu chặn này đã được chính bản gốc chứng minh trong đúng ngữ cảnh Maps/Waze bị host.
