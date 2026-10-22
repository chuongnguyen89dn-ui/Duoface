# Native12 gốc: đường KVC → ivar của child scene controller (bằng chứng máy)

- Căn cứ: DEB Native12 bất biến SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`; `DuoFaceDashboard.dylib` SHA256 `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`.
- Nguồn disassembly thực lưu trong `sideplay/audit/native12-continuation-4888299/gallery-media-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json`; `CBBridgedUIAppView.updateSceneSettingsFrame` IMP `0xad5bc`, workflow xác thực `39732740224`.
- **Nhìn callsite/register chứ không diễn dịch theo chú thích `Objc message` cuối dòng** (một số annotations không theo giá trị x1 mới được nạp). Đây là bằng chứng tĩnh, chưa phải log thiết bị.

## Đường gọi được giải mã từ ARM64

1. `ad644` nhận controller chính từ ivar của `CBBridgedUIAppView`; `ad648..ad658` gửi `valueForKey:@"_deviceAppViewController"` đến chính controller đó, x19 là object con trả về.
2. `ad6a4` điều kiện child `setContentReferenceSize:withInterfaceOrientation:`, orientation w2=1 tại `ad6a0`. `ad6bc` kiểm `respondsToSelector:` đối với selector ba tham số, `ad6dc` gọi ba tham số với w2=w3=1. Hai điều kiện **độc lập**, không phải `else if`.
3. `ad6ec` kiểm selector hai tham số trên **controller chính**, `ad708` gọi nếu có với w2=1.
4. **Quan trọng hơn**: handler exception của bước KVC `adb18..adb94` có log nguyên văn tại `adb40` là `...KVC failed in updateSceneSettingsFrame, falling back to ivar...`. Sau đó `adb48` nạp controller chính, `adb54` đọc class; `adb5c` nạp literal `"_deviceAppViewController"`, `adb60` gọi `_class_getInstanceVariable`, `adb70` nạp controller chính, `adb70`..`adb74` dùng `_object_getIvar`, x19 nhận controller con; `adb94` **quay về** `ad668` để thực hiện các setter. Nếu class không có ivar: `adb84` x19=nil, vẫn đi qua guard rồi sang controller chính.
5. Một handler khác `adae0..adb10` xử lý exception của `updateSettingsWithBlock:`. **Chưa giải mã nội dung block/ABI scene settings hoặc callback; không thêm block giả để tuyên bố video đã chạy.**
6. `ad70c..ad96c` truy `sceneHandle`, `sceneIfExists`, `scene`, ivar `_scene` và associated objects. Đây là owner khác việc lấy child controller; không tự sao chép các associated keys/phương thức vào runtime độc lập.

## Khác biệt chính xác trong DuoFace độc lập

- `sideplay/duoface-native-scene-host/DFSceneHost.m`, `commitSceneGeometry:`: hiện `valueForKey:@"_deviceAppViewController"` bên trong một `@try` lớn; nếu KVC ném `NSException`, `@catch` ngoài **bỏ qua toàn bộ child 2/3 + main 2 setter**, kể cả trên runtime có ivar thật.
- Phương án vá giới hạn rõ: bọc **duy nhất lời gọi KVC** trong `@try/@catch` lồng; chỉ khi KVC thất bại mới thực hiện `class_getInstanceVariable([self.appController class], "_deviceAppViewController")` và `object_getIvar` với guard ivar != nil. Giữ nguyên Portrait=1, thứ tự 2/3/main, readiness/debounce, teardown, tên gói, 9 Style. Không tiếp tục khi không có controller, không bịa scene Handle/ACK.
- Kiểm tra tự động phải buộc nguồn địa chỉ trên bản dump SHA-pin, nguồn có đường `KVC->ivar` và không dùng ivar nếu KVC thành công; thêm test vào bộ nativehost hiện có.
- Trạng thái thời điểm phát hiện: **ĐÃ ĐỐI CHIẾU TĨNH**, sửa runtime/chạy CI chưa được tuyên bố. Chưa kết luận đây là nguyên nhân ExitSafeMode, video rotation hay media audio.
