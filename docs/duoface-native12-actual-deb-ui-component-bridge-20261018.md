# DuoFace — quét DEB Native12 HUD8 và ghép lại từng thành phần từ DuoNavi 1.0.4

Ngày: 2026-10-18. Repo `chuongnguyen89dn-ui/Duoface`, nhánh `feature/visual12-duodash-recovery`.

## Quyết định mới có hiệu lực

**Yêu cầu người dùng:** Chỉ xem `Native12 HUD8` và `DuoNavi 1.0.4` sau khi giải nén/kiểm tra hai DEB thật mới được nhận định kích thước và ảnh/logo gốc. Làm **song song** phân tích đường nối từng lớp (cửa sổ → split → pill/divider → picker → scene), rồi viết nối lại thành DuoFace **độc lập**, không phụ thuộc vendor/license. Chỉ một lớp sau khi đã đối chiếu hình dáng, kích thước và callback; không chắp vá nút QA hay tự ý phát hành DEB.

**Nguồn bất biến (đã kiểm tra checksum trong CI):**
- Native12 HUD8: `dist/payload-migration/native12-speed8compact/com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb`, SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`. `DuoFaceDashboard.dylib` SHA256 `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`.
- DuoNavi original 1.0.4: `dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb`, SHA256 `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`. `DuoNaviDashboard.dylib` SHA256 `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`.
- Tài liệu lịch sử `tiep tuc du an.md`, nhưng đầu mối bàn giao **HIỆN TẠI** vẫn `ban giao du an duoface moi.md` trên nhánh trên. 40pt menu cũ đã bị 30pt chuẩn mới thay thế.

## Kết quả quét asset thật — đơn vị là PX trong PNG, KHÔNG phải point trong UIKit

| File trong DEB Native12 | Pixel thật | Ghi chú |
|---|---:|---|
| `duoface-logo.png` | 960×240 | ngang tỷ lệ 4:1; opaque alpha 255 kể cả bốn góc; trong khung 120×30pt với AspectFit chiếm 120×30pt, nhưng có nền tối |
| `duoface-logo-picker-alpha-v2.png` | 627×228 | logo picker nền trong suốt alpha 0–255; tỷ lệ 2.75:1; trong khung 120×30pt AspectFit chiếm **82.5×30pt**, nên có khoảng trống ~18.75pt mỗi bên |
| `duoface-logo-vert.png` | 640×640 | vuông opaque |
| `VisualAssets/duoface-picker.png` | 256×70 | alpha có độ trong suốt, bbox hình (6,0)–(251,70); tỷ lệ ~3.66:1 |
| `VisualAssets/duoface-fullscreen.png` | 88×88 | vuông, opaque |
| `VisualAssets/duoface-swap.png` | 120×120 | vuông, opaque, bốn góc đen |
| `duoface-icon.png` | 256×256 | icon app, opaque |

**Đặc biệt:** ảnh `duoface-picker.png` nếu vẽ AspectFit trong UIButton **30×26pt** của QA hiện nay sẽ có nội dung tối đa khoảng **30×8.2pt**, không phải 30×26pt. Đây là phép tính tỷ lệ hình học từ ảnh đã kiểm chứng; **chưa** là bằng chứng 30×26pt vốn là khung của bản Native12. Phải tìm thực `CBSlotPillView.updateBoundsSize/layoutSubviews` rồi đối chiếu vùng bấm thật, không đổi kích thước đoán trước.

CI đã xác nhận **6 asset giao diện** trong `replacement/visual12/build_qa.sh` được ghim đúng SHA256 từ bộ Native12, dưới đường dẫn **DuoFaceVisual12 riêng**. Vì vậy việc nhận định UI không giống không thể quy toàn bộ cho sai file ảnh; còn UIKit frame/contentMode/lớp và callback.

Nguồn máy đọc được: `audit/native12-deb-original104-ui/METRICS.json` và `REPORT.md`, [Actions 39099109883](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39099109883), SUCCESS. Phân tích sâu các phương thức đúng của pill/divider chạy [39099571859](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39099571859), SUCCESS. Tệp `PILL_DIVIDER_NATIVE12_ASM.txt` và `COMPACT_UI_CONTRACT.json` sẽ chứa các đoạn máy rút gọn có thể đọc tiếp khi workflow mới lưu thành công.

## Kích thước UIKit thật tìm từ phương thức Native12 (không nhầm với PNG)

Qua bản quét tăng cường `audit/native12-deb-original104-ui/PILL_DIVIDER_NATIVE12_ASM.txt` lấy từ chính `DuoFaceDashboard.dylib` SHA256 đã khóa:

- `CBSlotPillView::initWithSlotIndex:` Native12 IMP `0x841c0`, khoảng `0x84208–0x84224` gọi `-[super initWithFrame:]` bằng thanh ghi UIKit `d0=0,d1=0,d2=76,d3=22` => **kích thước khởi tạo 76×22pt**, bo góc **11pt** ở `0x84328–0x84334`. Original104 cùng phương thức IMP `0x82f74`, không dùng địa chỉ Native12 để thao tác bản cũ.
- `CBSlotPillView::updateBoundsSize` Native12 IMP `0x85184`, `0x851b8–0x85228`: các hằng double IEEE754 gồm 38,44,64,72,76,80pt cho chiều rộng; cao **19 hoặc 22pt**, được `fcsel` theo cờ điều khiển. **Chưa gán được chắc chắn tên cờ cho từng nhánh**, đang quét thêm getter/setter `setIsCompactMode:`, `setIsFocusedMode:`, `setShowsExpandButton:` để tái tạo bảng trạng thái đúng. Không coi tất cả trạng thái đều 76×22.
- `CBDividerView::updateGripLayout` Native12 IMP `0xff460`: tại `0xff4b4–0xff4d0` đọc `bounds`, chọn hằng **28 hoặc 30pt** cho `d8` theo kích thước màn/khung, và dùng `relativePos` để đặt các `moveButtons`. Đây là kích thước nội bộ của grip, **chưa đủ xác định chính xác CGRect của logo bấm** (còn phụ thuộc orientation và thiết lập vị trí).
- Sai lệch QA cũ pill 74×30/bo13 đã sửa **mặc định** sang `76×22`/bo11, `DFINativeShell.inc` commit `e8dd2892c2264365838c49e8064245a8149a8df2` và `DFIInterface.inc` commit `8e008d07fe7618a5b4dd84d12526a2bbc52105f1`. Các nút con được hạ cao về 22pt cho không bị clip; **bề rộng nút con vẫn là ước lượng QA**, cần máy gốc để đo trùng.
- Kiểm thử đã thêm `replacement/visual12/tests/test_native_shell_structure.py` commit `34e5ee86e0be65f85bdef309225ed630da9eb0d9`. `scripts/audit_native12_ui_dimensions.py` đổi sang số đo đã kiểm chứng ở `a57eb7ceb232dc5ad3ee3ed40d717c568a2e0cbf`. CI compile-only cho source mới cần kiểm tra trạng thái run sau commit.
- UI nối riêng `CBSlotPillView.onRestoreTapped` → `DFINativeSlotPillView.restoreAction` → `DFV12SplitController.restorePane:` để thoát focus **không reset fraction/secondary**, commit `13baea7f739b274e3e60fcb07a91496a7612d7fd`, `11031050ff3dc5924ee0e7dc6a9c2461f7859670`. Source contract test commit `7f2c5b5221a609b80e8e51a158cf1986f8128288`, [Actions 39099542478](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39099542478) compile SUCCESS. **Chưa có device UI test**.

## Bản đồ ghép nối trực tiếp từ mã máy hai DEB (không sao chép vendor runtime)

| Chủ sở hữu Native12 (cùng lớp trong original104) | Phương thức gốc đã thấy | Thành phần độc lập DuoFace | Đã nối/đang thiếu |
|---|---|---|---|
| `CBWindow` | `createWindows`, `carPlayContentInsets`, `carPlayUsableBounds`, `showAppPickerForSlot:` | `DFINativeWindowSurface`, `DFIStart`, `DFIFramesMake` | Có root/safeArea. Vẫn phải so stacking Dock/StatusCarPlay và màn thật; QA root `UIWindowLevelAlert+100` chưa chứng minh đúng. |
| `CBMultitaskingOverlayView` | `initWithFrame:`, `layoutSubviews`, `setupCardContent`, `setupAppPickerCardsInCardW:cardH:contentY:`, `setupRecentAppsCardsInCardW:cardH:contentY:` | `DFINativePickerCard`, `DFINativePickerMenuBar`, `DFINativePickerCardsController` | Có blur/card và menu 30pt, app grid 4×2 phân trang; **chưa chứng minh khung thẻ/icon/gap đúng native**. |
| `CBSlotPillView` | `initWithSlotIndex:`, `updateBoundsSize`, `layoutSubviews`, `dotsTapped:`, `expandTapped:`, `restoreTapped:`, `handleLongPress:` | `DFINativeSlotPillView` → `choose:`, `zoomPane:`, **`restorePane:` mới tách** | Ba callback UI nay tách riêng bằng mã DuoFace. Vẫn chưa xác minh kích thước pill Native12, hitbox hay nhận input khi scene live. |
| `CBDividerView` | `initWithFrame:isVertical:`, `updateGripLayout`, `handlePan:`, `handleMoveButtonLongPress:` | `DFINativeDividerTrack` → `drag:`; `DFINativeDividerLogo` → `swapPanes`, `moveDividerLogo:` | Tap hoán đổi, nhấn ≥0.30s kéo vị trí logo, pan ngoài logo đổi tỷ lệ; source-only, chưa kiểm thử live app. |
| `CBBridgedSplitApp` | `layoutSplitViews`, `handleDividerPan:isVertical:state:`, `focusSlot:animated:`, `restoreSplitAnimated:`, `swapSlot:withSlot:` | `DFILayouts.h`, `DFV12SplitController` | Có 8 layout + ratio + swap/focus/restore. Chưa đúng UI thực tế và chưa xác nhận thao tác với 2 app. |
| `CBBridgedUIAppView` | `calculateNativeSizeForSlotRect:`, `updateLayout`, `updateSceneSettingsFrame`, `startInParentViewController:`, `dismiss` | `DFV12SceneHost` `attachTo/resizeTo/applySize/close` | Lõi QA hoạt động ở mức mở ứng dụng, nhưng người dùng vẫn thấy **bó giao diện**, exitMode chỉ giảm; chưa sửa xong. |

**Phân biệt nguyên tắc kết nối:** Khả năng tìm thấy một selector/IMP tại hai bản **không chứng minh** được đường gọi đó chạy ở mọi chế độ. Original104 là hợp đồng vòng đời tham chiếu, Native12 là nguồn giao diện/điều khiển đang duyệt. Phía DuoFace phải cung cấp class, view ownership, callbacks và scene APIs **của chính mình**, không nhúng `DuoFaceDashboard.dylib`, `DuoNaviDashboard.dylib`, `CBBridgeManager` vendor, cơ chế giấy phép/thử thời gian, postinst sửa hệ thống hay webhook của họ.

## Tiến độ kiểm chứng chính xác

- **Đã kiểm chứng trên GitHub:** quét trực tiếp hai DEB, hashes, 25 PNG Native12/21 PNG DuoNavi, sáu họ class, IMP/selector và vùng mẫu lệnh bố cục. Source gate `scripts/check_native12_deb_ui_bridge_contract.py` kiểm tra **6 ảnh SHA + 13 tương quan method→callback độc lập**, ARM64 compile-only [run 39099327766](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39099327766) SUCCESS.
- **Đã sửa thực tế source UI độc lập:** tách `restorePane:` khỏi `zoomPane:` trong `DFINativeSlotPillView`, commit `13baea7f739b274e3e60fcb07a91496a7612d7fd`, `11031050ff3dc5924ee0e7dc6a9c2461f7859670`; regression source check `7f2c5b5221a609b80e8e51a158cf1986f8128288`, [run 39099542478](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39099542478) SUCCESS, đã compile arm64. Không thay tệp Native12 gốc.
- **CHƯA** có ảnh/log máy cho commit mới; chưa có bố cục khung pill/divider exact Native12 trên màn xe; chưa giải quyết app bị bó/exitMode.
- **CHƯA** build/xuất/đưa lên Sileo bản DEB mới. QA `ui8native5` trước đây vẫn bị người dùng bác bỏ, stable Native12 HUD8 không thay.

## Bước bắt đầu ngay ở chat sau

1. Từ `COMPACT_UI_CONTRACT.json` và `PILL_DIVIDER_NATIVE12_ASM.txt` trong `audit/native12-deb-original104-ui/`, giải phép `CBSlotPillView.updateBoundsSize` và `CBDividerView.updateGripLayout` để có point CGRect/hitbox chính xác, phân biệt literal ARM với frame đã xác minh. Nếu chưa giải được, ghi rõ offset lệnh và blocker, không dùng QA 74×30/36×44 làm chuẩn.
2. Chỉnh **một thành phần** theo kích thước/target vừa kiểm chứng, cập nhật source test + CI compile-only. So sánh logo α-v2 và logo ngang gốc đúng nền/tỷ lệ, không bóp méo asset.
3. Khi khung và picker đúng ảnh, tiến hành nối từng callback chọn app/focus/restore/drag/swap/scene và nhận log trong xe; chỉ phát hành QA riêng khi có bản preview nghiệm thu được yêu cầu cụ thể. Đừng chuyển sang HUD speed/data trước khi UI đúng.
