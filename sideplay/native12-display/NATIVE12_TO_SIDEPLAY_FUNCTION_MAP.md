# DuoFace Native12 HUD8 → SidePlay host — map nối chức năng, QA3

**USER_DECISION 2026-10-18:** SidePlay chỉ là bộ máy chạy ứng dụng CarPlay; **bộ khung, cử chỉ và chức năng phải theo DuoFace Native12 HUD8 đã duyệt**. Không duy trì hai bộ giao diện chồng nhau. Gỡ/ẩn SidePlay UI cũ tạm, chỉ xóa vĩnh viễn sau nghiệm thu thiết bị. Native12/DuoNavi DEB gốc là nguồn tham khảo, không phải file mã nguồn Objective-C để copy.

## Nguồn ưu tiên đã đọc

1. `tiep tuc du an.md`, `ban giao du an duoface moi.md` (repo DuoFace, bản QA có nội dung nếu main API trả rỗng).
2. `feature/visual12-duodash-recovery:docs/native12-complete-gui-replacement-map-20261018.md` và `docs/duoface-native12-complete-ui-class-migration-map-20261018.md`.
3. Mã tham khảo sở hữu DuoFace `replacement/visual12/engine/runtime/DFINativeShell.inc`, `DFIInterface.inc`, `DFIApprovedVisuals.h`, `runtime/fullscreen/DFPickerZoomMenu.xm`.
4. Địa chỉ kích thước/asset đã xác minh tại `audit/native12-deb-original104-ui/COMPACT_UI_CONTRACT.json`, `docs/duoface-native12-comprehensive-dimensions-20261018.md`.
5. Chỉ để nối host SidePlay: `sideplay/native12-display/audit/SIDEPLAY_SPLIT_OWNER_SELECTORS.json` tạo từ DEB gốc checksum-pinned, run [39120307831](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39120307831); không mở lại audit tổng quát.

## Mapping hiện tại (QA3 source, chưa device PASS)

| UI hành vi Native12 đã duyệt | Source-owned GUI / delegate | SidePlay host method thực có, được xác minh ObjC ABI |
|---|---|---|
| Root CarPlay **không fullscreen**, dock còn thấy | `sideplay/sileo-qa/Tweak.xm` Native usable geometry, không dùng SidePlay dock mode khi Normal | `SPDash.setCarWindow:`, `setCarWindowFrame:`, `carWindowFrameNow`, `layoutRootView` |
| Pill chọn app hai ô, 76×22 bo góc 11 | `DFSPNativeFrame.m` tạo 2 pill; ẩn `SPPane.chipView` + `layoutButton` gốc | `SPDash.panes`, `SPPane.view`, `SPDash.showPickerForPane:` |
| Mặc định placeholder `＋ Chọn ứng dụng`, không dùng `Trống / Thêm app` của SidePlay | `DFSPNativeFrame`, hạn chế chính xác label placeholder cũ chỉ trong pane **khi chưa có app** | `SPPane.appViewController`, `SPPane.view` |
| Native picker sheet: dark material blur, 20pt radius, approved logo, App/Zoom/Style/Close 30pt | `DFSPNativeFrame` sheet riêng, DuoFace logo source `dist/visual-1.0.3-12/assets/duoface-logo-picker-alpha-v2.png`; không render toolbar nổi ở root | Native `DFPickerZoomMenu.xm`; `SPDash.showPickerForPane:`, `layoutChooser`, `paneRequestsClose:` |
| **Zoom In/Out** chỉ sau khi user bấm | Trong Native sheet `Zoom` -> `DFSPApply`, không có Zoom nổi từ QA1/QA2 | `SPDash.setCarWindowFrame:` và window level scoped |
| **Kéo tỷ lệ liên tục** 1/3–2/3; 3 mốc snap 4% | `DFSPNativeFrame` 32pt invisible divider track + 1pt stroke, 30pt logo, `UIPanGestureRecognizer`; callback mỗi move và end | `SPDash.setRatio:(double)` (ABI `v24@0:8d16`), `SPDash.layout:(BOOL)` (`v20@0:8B16`), `SPDash.ratio`, `SPPane.layoutInFrame:scaleMode:` do SidePlay host tự quản lý |
| Tap logo chia màn hình = Swap | `DFSPNativeFrame` logo action | `SPDash.paneRequestsSwap:(SPPane *)` |
| Giữ logo 0,30s để kéo **dọc thanh chia**, không thay ratio khi giữ | `DFSPNativeFrame` long-press adjust `logoRelativePosition`; pan khác để thay tỷ lệ | SidePlay host không biết vị trí logo, chỉ lưu trên native frame QA3 |
| Style preset | `DFSPNativeFrame` Style action | `SPDash.layoutChooser` |
| App picker thực, close, app lifecycle | Native Frame chỉ gọi delegate để SidePlay host thực thi; **không copy CBScene/license** | `SPDash.showPickerForPane:`, `paneRequestsClose:`, `SPPane.appViewController` |

**Các điều kiện giới hạn đã xác định:**
- UI default/pill/divider/sheet mới **đã có source**, chưa có ảnh xe xác nhận kích thước, nút, menu/scene hoạt động.
- Khi chọn App/Style, QA3 còn gọi picker/style SidePlay gốc như bộ chọn dữ liệu/chức năng phía sau. **Chưa thay chính nội dung app picker Style** thành Native12; đừng gọi 100% giao diện hoàn chỉnh.
- Zoom fullscreen system chrome còn phụ thuộc lớp window/z-order CarPlay thực tế; việc set frame chưa chứng minh bar hệ thống tự hiện.
- SidePlay app host hỗ trợ `setRatio:`, nhưng chưa có log *hai ứng dụng đang mở* chứng minh `layout:` cập nhật real scene; chỉ static ABI confirmed. Cần thực tế thử kéo khi **cả hai ô có app**.
- Pill QA3 hiện một ellipsis thay vì đầy đủ nút focus/restore per-slot của Native12. Giai đoạn tiếp phải thêm callback focus/restore theo cách độc lập và kiểm tra chạm.
- Chưa tích hợp HUD8, settings, per-pane focus, nguồn dữ liệu hay scene crash fix vào QA3. Giữ bản Native12 HUD8 Sileo độc lập và không ghi đè.

## Release gate QA3

Mã tại `sideplay/native12-display/DFSPNativeFrame.h/.m`, adapter ở `sideplay/sileo-qa/Tweak.xm`; gói thử `com.duoface.sideplaydisplay` version `0.1.1~native12frame3`. Theos build phải xác minh dynamic dylib **và duy nhất logo thuộc namespace QA**, không nhúng bất kỳ Mach-O SidePlay/DuoNavi. Device test thực phải qua các bước: normal boot thấy dock, hai app thật, native pill/menu, drag ratio xung quanh trung điểm và snap, swap, Zoom In/Out, close/reconnect, lỗi SpringBoard/exitmode không tái diễn.

**Giới hạn lưu:** mọi mã và hồ sơ chỉ ở `sideplay/`; sửa source Native QA cũ hay các gói phát hành đã duyệt đều bị cấm.
