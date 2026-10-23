# Native12 Zoom In/Out — sửa đúng nút hiển thị và đường callback (2026-10-23 ICT)

## Lỗi đã xác định từ MÃ NGUỒN, không đoán theo ảnh

Người dùng phản ánh trong nhiều bản DuoFace DEB, ở menu chỉ có **chữ Zoom**, không có hai trạng thái **mũi tên hướng ra ngoài / hướng vào trong** như Native12 gốc. Không thể coi nút đã nối xong chỉ vì có tên `Zoom`.

Đối chiếu đối tượng nguồn của **chính dự án này**, `runtime/fullscreen/DFPickerZoomMenu.xm` (đã tham chiếu đến v12 trên GitHub), phương thức `DFLayoutPicker`:
- `DFDecorate(zoom, @"Zoom", expanded?@"arrow.down.right.and.arrow.up.left":@"arrow.up.left.and.arrow.down.right", font)`.
- `zoom.accessibilityLabel=expanded?@"Zoom Out":@"Zoom In"`.
- Gốc là **một nút Zoom hai trạng thái**, mũi tên 16 pt phía trên chữ Zoom 10 pt trong nút cao 30 pt; không phải hai nút chức năng riêng hoặc nút có chữ Zoom đơn độc. Header gốc có 4 hành động `App / Zoom / Style / Close`. Đây là nguồn v12 đã có trong lịch sử dự án, không sáng tác UI mới hoặc sao chép binary/license gốc.

Đối chiếu bản độc lập ngay trước sửa (`0.0.49~logotouch1` source):
- Outer `DFNative12Chrome.m` tạo nút qua `[self button:names[i] ... action:@selector(menuAction:)]` với `names=@[@"App",@"Zoom",@"Style",@"Close"]`, không gắn icon mũi tên cho nút Zoom trong **menu outer**. Đây là thiếu sót **xác minh trực tiếp**; người dùng thấy đúng một chữ Zoom.
- Hai pill mỗi ô dùng icon PNG `duoface-fullscreen` cố định bất kể đang focus hay restore, vì code ưu tiên PNG trước SF Symbol. Vì vậy **không bao giờ thấy hai mũi tên thay đổi trạng thái**, ngay cả khi focus được toggled.
- Nút outer đã `emit:@"Zoom"` ở `menuAction:` → callback của `DFTouchOwnerProbe.m` → `DFDockZoomToggle(sChrome,sSession,...)` trong `DFDockZoomCoordinator.m` → lệnh `SetDockHidden` đến `DFCarPlayDockOwner.m` → owner-check/ACK → host full geometry/rollback. **Code path tồn tại**, KHÔNG phải bằng chứng Dock thật đã bị ẩn trên iPhone. Tài liệu cũ ghi **44 lần thất bại ACK**; trạng thái zoom thực tế chưa đạt nghiệm thu.

## Thay đổi đã ghi trên GitHub — giữ native v12 và chức năng cũ

1. `sideplay/duoface-native-scene-host/DFNative12MenuHeader.h` commit `5b83fede7abce3a482b8e379ddfc4b902a0f83c8`: `DFNative12ZoomArrowSymbol(expanded)` map chính xác hướng ra/hướng vào như nguồn v12. `DFNative12DecorateZoomButton` tạo **mũi tên UIImageView 16×16** tag 197312 phía trên chữ Zoom 10pt; không chặn touch, không thay target/action. Trạng thái Zoom In/Zoom Out được gán accessibilityLabel và cập nhật sau trạng thái Dock ACK.
2. `sideplay/duoface-native-scene-host/DFNative12Chrome.m` commit `769ddbec670aee721c29cda4472a4ef964425e58`: gọi hàm decorate ở **outer menu nút số 1**, do đó không còn text-only; mỗi pill bên ô chuyển mũi tên theo `focused` (Zoom In khi chưa focus / Zoom Out khi restore), không dùng cùng một PNG cố định cho cả 2 trạng thái. Ngoài ra log khi nhấn outer `native12-zoom-in-arrow-pressed-ack-pending` / `native12-zoom-out-arrow-pressed-ack-pending`, rồi phát đúng lệnh `Zoom` cho owner hiện có. Trạng thái biểu tượng outer lấy từ `self.hostFullscreen`, chỉ được đổi khi owner đã áp dụng geometry sau **ACK thực**, không đổi giả khi vừa nhấn.
3. `sideplay/duoface-native-scene-host/tests/test_scenehost_safety.py` commit `50d929e9816a9e1d84c75a88596c46000a5e859b`: test `test_native12_original_zoom_in_out_arrows_visible_and_connected` kiểm biểu tượng v12 gốc/nhãn/trạng thái/nút outer + per-pane + callback/real ACK/rollback. **Đây là source/static contract, không phải test CarPlay.**
4. Các pin build cập nhật riêng bản tích hợp **.50**, NativeHost `0.1.59~zoomarrows1`, one-DEB `com.duoface.jb.embedded 0.0.50~zoomarrows1`, cùng toàn bộ code logo 3 giây đã sửa ở bản .49. Các bản .48/.49 và DEB gốc phải giữ nguyên; không đổi code YouTube, giải pháp crash hoặc giả vờ sửa Dock bằng thay icon.

## Xác minh và trở ngại

- CI source thực có GitHub Actions [39940097450](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39940097450) **completed success** trên source commit `50d929e...` trước cập nhật .50 version; kiểm tra này có suite source contract và clang iOS16 theo workflow hiện có, chưa chứng minh cảm ứng hoặc Dock trên xe.
- CI source sau thay pin toàn phiên bản `985cc77e...` lúc kiểm [39940338706](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39940338706) **pending**. Chỉ xác nhận build khi xem kết quả cuối và log. Chưa nói có .50 signed DEB/Sileo.
- Đã kiểm tra `0.0.49~logotouch1` **được ký/build**, run [39938698098](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39938698098) success, SHA256 `fac9d40418ef350e97a39e9af341c1f6e1b37b42d8c964435969742de1fbe588`, archive `sideplay/jb-embedded-appbridge/evidence/runs/39938698098/`. Bản .49 này **không bao gồm sửa giao diện Zoom** mới và không được gọi là fix Zoom.

## Điều kiện nghiệm thu thực sự

1. Signed QA .50 phải đúng source SHA + package SHA, qua test, ký và lưu artifact; nếu user muốn phát hành Sileo thì phải pin bất biến + verify public Pages.
2. Trên CarPlay (xe đỗ), menu phải hiển thị **Zoom + mũi tên tỏa ra ngoài**. Nhấn nhận log `native12-zoom-in-arrow-pressed-ack-pending`, receiver nhận owner Dock thật và log `native12-whole-host-zoom-applied`. Chỉ sau khi dock biến mất + scene khung bao hết màn hình mới là Zoom In PASS.
3. Mở lại menu phải hiển thị **Zoom + mũi tên hướng vào trong**. Nhấn nhận log `native12-zoom-out-arrow-pressed-ack-pending`, ACK restore; Dock, contentRect/splitRatio và menu phục hồi mới là Zoom Out PASS.
4. Nếu mũi tên có nhưng Dock vẫn không đổi: cần `/var/mobile/Library/Logs/DuoFaceDockOwner.log`, `DuoFaceTouchOwner.log` để kiểm `no-verified-live-native-appdock`, `real-dock-ack-timeout`, `native-dock-restore`; không phát hành tiếp bản chỉ đổi text/icon.

Nguồn kỹ năng: `Gpt-training-/skills/02-ios-deb-ipa-carplay.zip` đã giải nén/đọc ở phiên ngay trước; cùng `Gpt-training-/SKILL_INDEX.md`, `AGENTS.md` kiểm lại lượt này. Không chuyển mã nguồn sang repo kỹ năng.
