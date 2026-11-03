# QUÉT BÀN PHÍM TOÀN BỘ CÁC DEB — NGƯỜI TA LÀM THẾ NÀO (03/11/2026)

Yêu cầu của Nguyen: làm có cơ sở, không suy đoán — quét toàn bộ deb của các
app khác xem họ xử lý bàn phím thế nào. Phương pháp: đọc strings (chỉ đọc,
không chạy binary) trên mọi binary tiếp cận được, đối chiếu theo cùng một
bộ từ khoá bàn phím.

Mức bằng chứng dùng trong báo cáo:
- [LOG] = chuỗi log runtime của chính gói đó (họ tự ghi khi hook chạy) —
  selector có dòng [LOG] đi kèm là ĐÃ HOOK, chắc chắn.
- [SEL] = selector/chuỗi có trong binary — đã tham chiếu/sử dụng; strings
  một mình không phân biệt được "gọi" hay "hook".
- [SUY] = suy luận của Muse, ghi rõ.

## Nguồn đã quét
1. DuoNavi gốc com.duonavi.app 1.0.3-12 (DuoFaceDashboard.dylib 7,2MB) —
   bản Nguyen đang dùng làm chuẩn.
2. Biến thể DuoNavi trong deb voice104 test (DuoNaviDashboard.dylib) —
   lớp KB y hệt bản 1, chỉ khác tiền tố log [DuoNaviKB] thay [DuoFaceKB].
3. DuoFace gốc của SidePlay com.sideplay 1.0.4-1 (SidePlay.dylib + 4 dylib
   HUD + app + prefs — strings dump đầy đủ trong repo audit/deb-1.0.4-1).
4. CarPlayPro com.carplaypro.speed 0.9.97 (danh sách hook targets + stub
   selectors đầy đủ từ đợt phân tích QA166).
5. Bản của ta: QA182 (DF155GeneralAppStateRelay.dylib đã build).

## Kết quả theo gói

### DuoNavi gốc — có lớp bàn phím [DuoFaceKB] đầy đủ, 5 nhóm can thiệp

Nhóm A — cửa sổ phím (QA182 ĐÃ làm nhóm này):
- [LOG] hook `-[UIRemoteKeyboardWindow setHidden:]` (log frame),
  `-[UIRemoteKeyboardWindow setAlpha:]`.
- [LOG] hook `-[UITextEffectsWindow setHidden:]` và `setAlpha:` (cả hai —
  QA182 mới làm setHidden: ở mức chỉ-ghi).
- [LOG] hook `-[UIInputWindowController viewWillAppear:]` /
  `viewDidAppear:` (QA182 đã làm đường bắt này).

Nhóm B — UIKeyboardLayoutStar, bộ máy DỰNG phím thật (ta CHƯA làm):
- [LOG] hook `setKeyboardName:appearance:` và `setKeyboardName:` —
  họ CHẶN VÀ SỬA TÊN BÀN PHÍM: "Added prefix to setKeyboardName: from
  %@ to %@", "Corrected nil setKeyboardName: to %@", "Corrected (null)
  in setKeyboardName: from %@ to %@". Tên bàn phím mã hoá dạng layout
  (thiết bị/bề ngang/keyplane), sửa tên = đổi layout được dựng.
- [LOG] hook `setKeyplaneName:`; [LOG] "Corrected nil/null keyplaneName
  to letters" — keyplane rỗng thì họ cứu về "letters".
- [LOG] hook `showKeyboard` trên LayoutStar: đọc inputTraits +
  screenTraits (UIKBScreenTraits), "forcing inputMode: %@".
- [LOG] sau showKeyboard họ kiểm tra frame/hidden/alpha/keyplane/
  subviews/sublayers của LayoutStar; nếu keyplane nil: "Activating
  fallback keyboard & keyplane..." — có đường cứu chủ động.
- [SEL] updateKeyplaneName; keyplane/keyplaneName.

Nhóm C — UIKeyboardImpl (ta CHƯA làm):
- [LOG] hook `-[UIKeyboardImpl setDelegate:force:]`.
- [LOG] hook `-[UIKeyboardImpl showKeyboard]` (ghi inHWMode, autoMin).
- [LOG] "forcing fallback inputMode identifier" qua
  UIKeyboardInputModeController `keyboardInputModeWithIdentifier:`
  (có bọc exception); đọc currentInputMode/activeInputModes.

Nhóm D — ép "không có bàn phím cứng" (ta mới ĐỌC, họ ÉP):
- [LOG] BKSHIDServicesIsHardwareKeyboardAttached -> forcing NO;
  GSEventIsHardwareKeyboardAttached -> forcing NO.
  (QA182 chỉ đọc hai hàm này để ghi log chẩn đoán — không ép giá trị.)

Nhóm E — giả lập idiom trên traits (ta CHƯA làm):
- [SEL] setIdiomToEmulate:, setIsEmulatingIdiom:; [LOG] "Warning:
  Exception setting idiom emulation on traits" — họ đặt idiom giả lập
  lên screen traits của bàn phím.

Nhóm F — họ selector bề ngang (đã tham chiếu trong module KB):
- [SEL] fixedKeyboardWidth, keyboardWidth, setKeyboardWidth:,
  keyboardWidthForScreen:withOrientation:, keyboardScreenReferenceSize,
  keyboardSizeForInterfaceOrientation:.
  Đọc thận trọng: strings chứng minh module KB *dùng* các API bề ngang
  này; không tách được từng cái là gọi-hay-hook chỉ bằng strings.

### SidePlay 1.0.4-1 — KHÔNG có lớp bàn phím
- SidePlay.dylib: chỉ có 4 symbol notification UIKeyboard* (Did/Will
  Show/Hide) — mức "nghe thông báo", không hook cửa sổ, không LayoutStar,
  không Impl.
- App, 4 dylib HUD: 0 chuỗi bàn phím. Prefs: chỉ keyboardLayoutGuide /
  setKeyboardDismissMode: (code giao diện thường).
- Kết luận [ĐÃ ĐO]: dòng sản phẩm SidePlay không sửa bàn phím trong
  process app. Lớp KB là của riêng dòng DuoNavi.

### CarPlayPro 0.9.97 — KHÔNG có bàn phím
- 0 selector bàn phím trong cả hook targets lẫn stub selectors (nó là
  app HUD tốc độ, không host app khác nên không có bài toán này).

### Bản của ta (QA182)
- Có: nhóm A (chặn cửa sổ + IWC), fit frame cửa sổ, chẩn đoán.
- Chuỗi UIKeyboardImpl/UIKeyboardLayoutStar/UIKeyboardInputModeController
  có xuất hiện nhưng chỉ là TÊN LỚP để đọc chẩn đoán (tìm keyplane/
  inputMode qua UIKeyboardImpl.activeInstance) — không hook, không sửa.
- Thiếu toàn bộ nhóm B, C, E và tính "ép" của nhóm D.

## Vì sao QA182 lên xe "không khác gì" — phần có cơ sở
- [ĐÃ ĐO] QA178 đã đo: cửa sổ app bị resize (397x685) còn cửa sổ phím
  theo màn điện thoại 414x736. QA179–182 sửa ở mức FRAME cửa sổ.
- [ĐÃ ĐO từ log của họ] Bản gốc coi frame và keyplane là hai việc riêng:
  dòng log sau showKeyboard ghi đồng thời frame VÀ keyplane; khi
  keyplane nil họ cứu riêng keyplane. Tức sửa frame không thay được
  layout phím đã chọn theo tên/traits của điện thoại.
- [SUY — có cơ sở trên] Triệu chứng cụt hàng dưới do LAYOUT bên trong
  (LayoutStar dựng theo keyboardName/screenTraits/idiom của điện thoại)
  chứ không chỉ frame cửa sổ; chừng nào chưa can thiệp nhóm B/C/E thì
  sửa frame — dù bắt cửa sổ bằng cách nào — cũng không đổi hình. Đây là
  lời giải thích khớp nhất với verdict xe QA182, nhưng vẫn là [SUY]:
  chưa có log đo trực tiếp LayoutStar trên xe của ta.

## Kết luận cho Spec (để soạn WO nếu Nguyen quyết làm tiếp)
Phạm vi đúng của một bản "làm như bản gốc" phải gồm, theo đúng các
selector đã có bằng chứng ở trên: hook LayoutStar setKeyboardName:/
setKeyboardName:appearance:/setKeyplaneName:/showKeyboard (sửa tên +
cứu keyplane nil -> letters + ép inputMode dự phòng), hook Impl
setDelegate:/showKeyboard + fallback inputMode, ép hai hàm
hardware-keyboard về NO, đặt idiom giả lập trên screen traits — cộng
nhóm A đã có. Không cần thêm vòng chẩn đoán: verdict xe (phím đủ hàng
hay không) tự nó là nghiệm thu; log LayoutStar frame/keyplane (theo
đúng định dạng log của họ) đã có sẵn trong thiết kế nếu cần đọc lại.
