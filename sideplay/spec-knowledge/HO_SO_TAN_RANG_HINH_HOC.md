# HỒ SƠ TẬN RĂNG — CHUỖI HÌNH HỌC (DuoFaceDashboard.dylib, bản 1.0.3-12)

Đọc trực tiếp từ disassembly (llvm-objdump-18, có chú thích selector/message). Mỗi hàm ghi: địa chỉ IMP, độ dài, luồng gọi đã giải mã, hằng số, điều chưa đọc hết. Trạng thái: ĐANG LÀM (mục còn thiếu ghi ở cuối).

## 1. +[CBWindow carPlayUsableBounds] — IMP 0xb0ef4, 63 lệnh — ĐỌC HẾT

```
bounds = +[CBWindow carPlayScreenBounds]
insets = +[CBWindow carPlayContentInsets]        // UIEdgeInsets
w = bounds.width  - (insets.left + insets.right)
h = bounds.height - (insets.top  + insets.bottom)
if (w >= 100.0 && h >= 100.0)
    return (bounds.origin + insets.origin, w, h) // CGRectInset(bounds, insets)
else
    // đường dự phòng: kẹp từng thành phần inset —
    // không âm, và giữ lại tối thiểu ~64pt mỗi chiều (hằng 64.0 trong mã)
    return rect đã kẹp
```
Ý nghĩa: "usable" không phải niềm tin mù vào safeArea — có sàn 100×100 để chấp nhận insets, dưới sàn thì kẹp insets thay vì trả rect âm/rỗng.

## 2. +[CBWindow carPlayContentInsets] — IMP 0xb0c98, ~151 lệnh — ĐỌC XONG PHẦN CẤU TRÚC

Thứ tự nguồn, đúng phong cách "file override" của codebase này:
1. Cache tĩnh (4 double) — cả 4 > 0 thì trả ngay.
2. Đọc MỘT FILE bằng `+[NSString stringWithContentsOfFile:encoding:error:]` (đường dẫn nằm ở phần đầu hàm, đọc tiếp ở lượt sau) — nếu có nội dung, parse số từ file.
3. Dự phòng sống: `+[CBWindow activeCarPlayWindow]` → `rootWindow` → `safeAreaInsets` (có respondsToSelector: bảo vệ).
4. Mọi thành phần bị kẹp ≥ 0 trước khi trả/lưu cache.

## 3. -[CBBridgeManager renderSizeForBundleID:] — IMP 0x24c920, 510 lệnh, 55 message send — ĐỌC XONG LUỒNG GỌI, CÒN TOÁN TRONG NHÁNH

Luồng đã giải mã theo thứ tự lời gọi:
1. Giữ lại (retain) bundleID; nil hoặc rỗng → thoát sớm sang đường mặc định (0x24cb6c).
2. `self.activated` sai → nhánh 0x24ce18.
3. `isEqualToString:` đối chiếu bundleID với `self.bundleIdentifier` hiện tại.
4. `currentApp` → `isKindOfClass: [CBBridgedSplitApp class]`:
   - Nhánh split: `focusedSlotIndex`, `appViews` + `count`, lấy view theo chỉ mục, đọc `renderSize` RIÊNG của từng app view; +[CBWindow carPlayUsableBounds]; tạo NSMutableArray; đọc settings `splitPreset`, `splitRatio`; duyệt `containers` của split container; `appFrame`; `CGRectValue`.
   - Hằng số xuất hiện trong toán nhánh: **2.0** (fmov d4 tại 0x24cc74) và **10.0** (0x24cf30) — vai trò chính xác của từng hằng CHƯA kết luận, cần đọc tiếp thân nhánh.
5. Nhánh đơn: carPlayUsableBounds + appFrame là đầu vào chính.

Kết luận tạm (có bằng chứng): renderSize là thuộc tính tính theo (usable bounds × bố cục slot × loại app), mỗi app view trong split giữ renderSize riêng; KHÔNG tồn tại một "logical = pane × hệ số" toàn cục kiểu hợp đồng cũ của ta.

## 4. Các hàm liên quan đã định vị (chưa đọc)
- +[CBWindow carPlayScreenBounds] 0xb0704; +[CBWindow carPlayScreenScale] 0xb059c; +[CBWindow carPlayCADisplay] 0xafffc; +[CBWindow carPlayUIScreen] 0xafe60; +[CBWindow carPlayWindowScene] 0xaf690; +[CBWindow resetCachedBounds] 0xaf570 (bounds có CACHE và có hàm reset cache riêng).
- -[CBBridgeManager renderSize] 0x13ae78 (getter thuộc tính đã lưu).
- -[CBBridgedUIApp renderSize] 0xb9d04.

## 5. Còn thiếu của chuỗi này
- Toán chính xác trong nhánh split của renderSizeForBundleID: (vai trò 2.0/10.0, công thức chia theo ratio/preset).
- Đường dẫn file override trong carPlayContentInsets.
- Hai hook scene settings (updateSceneSettingsFrame, interceptUpdateForScene:withNewSettings:) — là hàm C trong constructor, phải tìm qua bảng đăng ký hook (chuỗi log '[DuoFace] updateSceneSettingsFrame: scene not yet ready' là mỏ neo).
- +carPlayScreenBounds / +carPlayScreenScale (nguồn số: CADisplay mode hay UIScreen bounds, có nhân scale không).

## 6. +[CBWindow carPlayScreenBounds] — IMP 0xb0704 — ĐỌC XONG CẤU TRÚC
Cùng khuôn 3 nguồn như contentInsets: cache tĩnh → file override (stringWithContentsOfFile) → đường sống: `carPlayWindowScene` → `coordinateSpace` → `bounds` (có respondsToSelector: bảo vệ). Tức bounds chuẩn của gốc là bounds của coordinate space thuộc window scene CarPlay, không phải UIScreen.mainScreen.

## 7. updateSceneSettingsFrame (phía CBBridgedUIAppView) — vùng IMP ~0xadafc–0xadbc8 — ĐỌC XONG LUỒNG
- Giải quyết sceneHandle có bẫy exception; chưa sẵn sàng → log 'scene not yet ready' và dừng (không ép).
- Đẩy settings qua `-[FBSScene updateSettingsWithBlock:]` (nhiều đường thử lại), block ghi: **setFrame:** (khung render), **setForeground:**, **setOccluded:**, **setUnderLock:**, **setCanShowWhileLocked:**, **setDeactivationReasons:**, **setIdleModeEnabled:**.
- Chạm tới `_deviceAppViewController` qua KVC (có cảnh báo khi KVC lỗi).
- Sau cập nhật: refreshSceneLayout + updateLayout + setNeedsLayout/layoutIfNeeded trên view.
Đối chiếu: DFSceneHost của ta cũng ghi qua updateSettingsWithBlock: nhưng tập cờ hẹp hơn — các cờ deactivationReasons/idleMode/foreground phía gốc là ứng viên liên quan tới hiện tượng scene bị đóng băng khi CarPlay đổi trạng thái (chưa kiểm chứng trên máy, ghi nhận để đối chiếu log sau).

## 8. Còn thiếu (cập nhật)
- Toán nhánh split của renderSizeForBundleID: (vai trò hằng 2.0 tại 0x24cc74 và 10.0 tại 0x24cf30).
- Hook interceptUpdateForScene:withNewSettings: (hook ở tầng FBSceneManager — khác hàm ở mục 7, chưa định vị).
- Đường dẫn cụ thể của các file override (bounds/insets).

## 9. Toán nhánh split của renderSizeForBundleID: — ĐỌC GẦN HẾT
- Sau khi đọc splitPreset/splitRatio: khởi tạo d4 = **2.0** (mặc định chia đôi) và bộ tích lũy 0; splitRatio được đọc lại để thay mặc định khi có.
- Trong vòng lặp containers: kiểm tra các thành phần của appFrame/usable > 0 rồi tính kích thước render bằng **fadd d, d, d** — tức NHÂN ĐÔI kích thước usable của slot. Kết luận: đường split của gốc dùng supersample ×2 TRÊN KÍCH THƯỚC SLOT (usable bounds), không phải ×2 trên kích thước điện thoại. Hợp đồng cũ của ta nhân đôi sai gốc tham chiếu; QA185 (×1) đúng hướng đích nhưng bỏ supersample này — cần kiểm chứng độ nét chữ trong split trên máy.
- Hằng **10.0** = ngưỡng hợp lệ: thành phần kích thước lưu sẵn ≤ 10pt thì coi như chưa có và tính lại bằng đường nhân đôi ở trên.

## 10. Hook interceptUpdateForScene:withNewSettings: — ĐÃ ĐỊNH VỊ + ĐỌC LUỒNG
- Đăng ký trong constructor (vùng 0x2c7c50+): class **SBSuspendedUnderLockManager**, IMP hook = **0x2c8668**, cạnh hai hook anh em _shouldBeBackgroundUnderLockForScene:withSettings: (IMP 0x2c8768) và shouldBeUnderLockForScene: (IMP 0x2c8a70) trên cùng class — một cụm "giữ scene không bị chìm dưới khóa".
- Luồng hook: giữ lại scene+settings → [CBBridgeManager sharedInstanceIfExists] nil thì qua luôn → isUIAppBridging sai thì qua → lấy bundle của scene, shouldBridge: sai thì qua → gọi renderSizeForBundleID: → chuyển (settings/scene, size) cho hàm nội bộ **0x2c77cc** (ghi frame + gọi IMP gốc nằm trong hàm này — CHƯA đọc thân).

## 11. Nợ còn lại của chuỗi hình học (rút gọn)
- Thân hàm 0x2c77cc (cách ghi frame vào settings + gọi original).
- Đường dẫn literal của "live screen bounds file" (đã biết tên gọi trong log; chuỗi path chưa trích ra — nó được nạp không qua cfstring ref).
- Chiều nhân đôi trong split theo hướng màn (ngang nhân width hay height) — cần đọc kỹ vòng lặp containers thêm một lượt.
