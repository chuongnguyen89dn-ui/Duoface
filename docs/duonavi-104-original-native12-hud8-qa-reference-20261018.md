# DuoFace độc lập — bản đồ tham chiếu DuoNavi 1.0.4 → Native12 HUD8 → QA (2026-10-18)

## Quyết định mới nhất của người dùng

**USER_DECISION:** coi `DuoNavi 1.0.4` là sản phẩm gốc trước khi dự án đổi đường dẫn/nhận diện thành các bản Native12. **Native12 HUD8** là chuẩn đầu ra đã được sửa/duyệt đối với giao diện và chức năng thực tế; **Visual12 QA** chỉ là lõi CarPlay độc lập đã chứng minh chạy được hai ứng dụng và hiển thị HUD, không phải giao diện gốc. Tiếp nối bằng cách phân tích trình tự gọi và cách nối các lớp/method của 1.0.4, so với phiên bản Native12; tự viết phần tương đương chạy trên lõi độc lập. Không tiếp tục tô giao diện alpha hiện có rồi nhận là Native.

Đọc kỹ năng trung tâm `Gpt-training-/skills/01-github-continuity.zip`, `02-ios-deb-ipa-carplay.zip`, `05-research-debug-testing.zip` (`SKILL.md` trong từng ZIP), `AGENTS.md`, `PROJECT_INSTRUCTIONS.md`, `SKILL_INDEX.md`. Chỉ nghiên cứu/ghi tài liệu trong checkpoint này, **không build/publish/đổi source UI**.

## Ba mốc phải phân biệt

| Vai trò | File / nguồn | Bằng chứng |
|---|---|---|
| **Gốc upstream (tham chiếu hành vi)** | `dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb` | SHA256 `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`, `audit/duonavi-original104-scene/REPORT.md` từ phân tích ARM64 thực, Actions `39082350491` và `39082485471`. Gói `com.duonavi.app`, bản `1.0.4`; binary `DuoNaviDashboard.dylib` SHA256 `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`. |
| **Bản đã tùy biến/chấp thuận** | `dist/payload-migration/native12-speed8compact/com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb` | SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`, báo cáo `BAO_CAO.json`, script `migration/full_payload/native_test/build_native12_speed8compact_candidate.py`. Chính script xác nhận Speed8 kế thừa **Speed7**, giữ nguyên 42 file, chỉ cập nhật `DuoFaceSpeedHUD.dylib`; do đó toàn bộ Native12 UI vẫn được chứa trong payload **`DuoFaceDashboard.dylib`** đã biên dịch, không có lại toàn bộ source renderer. |
| **Lõi độc lập đang thử** | `com.duoface.visual12`, QA `1.0.3-12~ui8native2` | `replacement/visual12/engine/runtime/DFIRuntime.m` tạo `DFV12SplitController` (`DFIInterface.inc`), không phải renderer Native. User đã test: hai app + HUD hiển thị, nhưng UI sai chuẩn, zoom từng ô thiếu, thao tác chia tỉ lệ khi có app thất bại và có exitMode lần đầu respring. |

**Hạn chế lineage:** 1.0.4 và Native12 sử dụng cùng hệ lớp/method `CBBridgedSplitApp/CBWindow` có chứng cứ tĩnh, **không có chứng cứ ở checkpoint này rằng hai DEB/renderer giống nhau từng byte hoặc mọi callback hoàn toàn đồng nhất**. Bản gốc 1.0.4 và file tiền thân của Native12 `dist/candidates/menu-native1/com.duonavi.app_1.0.3-12_menu-native1_iphoneos-arm64.deb` là hai mốc khác nhau. Tài liệu `migration/full_payload/KET_QUA_CHUYEN_NGUYEN_RUOT.md` mô tả bản sao payload từ bản 1.0.3-12 đã duyệt, **không phải** từ 1.0.4. Đối chiếu theo từng version/binary, không suy ra chỉ đổi tên đường dẫn.

## Các đường nối từ binary DuoNavi 1.0.4 đã chứng minh bằng metadata thật

IMP sau đây thuộc **DuoNavi 1.0.4**, tuyệt đối không áp dụng địa chỉ máy cho Native12 (ASLR, version khác).

| Phạm vi | Method + địa chỉ IMP (gốc 1.0.4) | Vai trò cần truy vết |
|---|---|---|
| Root/window | `CBWindow createWindows` 0xb173c; `show` 0xb2814; `resizeWindows` 0xb24ac | Chuỗi tạo/chọn window thật, root, content/scene views, usable bounds. |
| App picker | `CBWindow showAppPickerForSlot:` 0xb3148; `showLayoutChooser` 0xb31f8; `showRecentApps` 0xb32a0 | Ai sở hữu sheet/picker, hành động theo từng ô thay vì nút ellipsis của QA. |
| Divider/ratio | `CBBridgedSplitApp handleDividerPan:isVertical:state:` 0x10b4c0; `layoutSplitViews` 0x10bad8; `configureDividerButtons` 0x10ddf4 | Cách đưa delta cảm ứng vào `splitRatio` khi scene thật đang hiển thị, cập nhật frame app và divider. |
| Zoom từng ô | `CBBridgedSplitApp focusSlot:animated:` 0x10ce70; `restoreSplitAnimated:` 0x10d40c; `toggleFocusForSlot:` 0x10daf8 | `focusedSlotIndex` riêng, không phải phóng to toàn bộ cửa sổ CarPlay. |
| Swap / phân ô | `CBBridgedSplitApp rotateAllSlotsClockwise` 0x10db40; `handleDividerSwapPressed:` 0x11061c; `swapSlot:withSlot:` 0x1107b0; `updateScale:forSlot:` 0x11042c | Giữ liên kết scene/slot, thao tác logo/hoán đổi và tỷ lệ scale. |
| Per-app view | `CBBridgedUIAppView calculateNativeSizeForSlotRect:` 0xac788; `updateLayout` 0xac7cc; `updateSceneSettingsFrame` 0xad368; `updateSceneFrame` 0xadc24; `refreshSceneLayout` 0xadc30 | Nhóm phải nghiên cứu sâu trước khi sửa hiện tượng QA bó app và sai tỷ lệ/touch transform. |
| App scene life | `CBBridgedUIAppView startInParentViewController:` 0xadd08; `dismiss` 0xaedf8 | Vòng đời host/controller, chính xác nhóm attach/remove/invalidate. |
| Teardown | `CBWindow destroyWindows` 0xb2d14; `CBBridgedSplitApp closeSlot:` 0x112318; `stop` 0x1136dc | Làm rõ exitMode respring riêng và đường close scene đã từng fix trong QA. |

**Bằng chứng code path bổ sung:** giải mã `restoreSplitAnimated:` gốc có call `CBBridgeManager sharedInstance`, `saveBridgeStateToDisk`, `sendStateToApp:shouldBridge:` tại khoảng `0x10d5fc–0x10d778`. Đây là dấu vết quản lý trạng thái, **không đồng nghĩa** QA nên gọi/nhúng `CBBridgeManager` của vendor. Lõi độc lập phải tạo API quản lý state tương ứng riêng. Tại `closeSlot:` gốc, có `dismiss` (`0x1125e8`), `removeFromSuperview` (`0x1125fc`), và `sendStateToApp:shouldBridge:` (`0x112648/0x112664`). Tại `CBBridgedUIAppView dismiss` gốc, có `setRequestedMode:0`, UIKit parent detach và `invalidate` (`0xaee14–0xaef80`); chính nhóm này là tiền đề fix `standalone6invalidate` của QA. Không suy ra thứ tự mọi nhánh từ báo cáo chỉ trích mẫu assembly.

## So với Native12 đã sửa

- `src/DuoFaceVisualHook.m` cho biết pill **Native thật** có `_dotsButton`, `_expandButton`, `_restoreButton`; hook chỉ đổi artwork `VisualAssets/duoface-picker.png`, `VisualAssets/duoface-fullscreen.png`, giữ target/callback gốc.
- `src/DFDividerLogoGrip.inc` thay đổi yêu cầu giữ `CBDividerView.handlePan:` để resize tỉ lệ trong lúc chỉ riêng thao tác logo chạm/nhấn giữ xử lý đổi vị trí/hoán đổi. Phân tích `audit/divider/GRIP_MOBILITY_NATIVE6.json` cho biết bản Native (hậu chỉnh) dùng `moveButtonTouchDown/Up`, `handleMoveButtonLongPress:`, `handlePan:`, `CBBridgedSplitApp.handleDividerPan:isVertical:state:`. Đây là code/evidence của **Native**, không được gán IMP từ 1.0.4 cho nó.
- `runtime/fullscreen/DFPickerZoomMenu.xm` định dạng approved horizontal logo + một hàng App/Zoom/Style/Close cao 30pt trong sheet native; nó **không tạo lại toàn bộ sheet**. QA `DFV12List` dựng mới nên khác nút và cách nhận cảm ứng của Native.
- `audit/payload-migration/ORIGINAL_SETTINGS_OBJC_METHODS.json` ghi `CBGeneralSettingsViewController` và `CBDashboardSettings` (trên binary Native hậu chỉnh). QA hiện sử dụng `replacement/visual12/engine/shared/DFISettings.m` 4 nhóm, nhãn version `alpha2`. Đối chiếu nội dung cài đặt không chứa giấy phép dựa trên gốc & Native, không nhập license/subscription/endpoint.
- `migration/full_payload/native_test/build_native12_speed8compact_candidate.py` chứng minh giai đoạn Speed7→Speed8 chỉ đổi HUD dylib; **không phải** giai đoạn có thể lấy source Native Dashboard GUI để sao chép trực tiếp.

## Giới hạn kiểm chứng / rủi ro

- `audit/duonavi-original104-scene/REPORT.md` hiện tập trung lifecycle; nó chỉ chứng thực selector+IMP cho nhóm class được trích. **Chưa có đồ thị callback đầy đủ** cho các đường `showAppPickerForSlot`, `focusSlot:animated:`, `toggleFocusForSlot:`, `handleDividerPan`, `calculateNativeSizeForSlotRect:` từ binary 1.0.4; tên phương thức là điểm bắt đầu, không chứng minh thuật toán.
- `CBSlotPillView` trong báo cáo gốc hiện được thấy qua type `notchPill`; chưa xác minh class method implementation đầy đủ trong cùng báo cáo. Cần phân tích binary/selector class riêng, sau đó xác nhận callback chain đến `CBWindow` / `CBBridgedSplitApp`.
- Postinst gốc 1.0.4 có thao tác quyền root/OldABI, TCC, disables ReportCrash/services, sửa preference vendor; **không đưa những script này qua QA độc lập**. Đặc biệt không tắt CrashReporter khi đang debug exitMode.
- So khớp đặc tính để làm bản độc lập, không nhập mã thực thi hoặc phụ thuộc/giấy phép runtime vendor; không tuyên bố có thể tái tạo 100% khi chưa có user device pass.
- CI static ≠ thiết bị. Chưa chạy lệnh extract/objdump mới, chưa build/deploy/sửa runtime ở checkpoint này; các chứng cứ assembly là phân tích đã lưu từ hai Actions run trên.

## Bước tiếp theo có thể thực hiện ngay (trên nhánh QA, đọc trước sửa)

1. Viết/hoặc chạy **một** workflow CI read-only, dựa trên pipeline audit 1.0.4 thành công (Actions `39082350491`/`39082485471`), extract original DEB và `DuoNaviDashboard.dylib` trong `$RUNNER_TEMP`; `otool -ov`, `llvm-objdump -d`/Capstone, trích đầy đủ chuỗi selector/IMP cho 5 khối: (a) app pill/menu, (b) per-slot focus/restore, (c) splitter/ratio, (d) native size + scene transforms, (e) window attach/close. Lưu JSON/Markdown từ output với SHA binary/version, không lưu nguồn/binary vendor mới. Không chạy job trùng.
2. Từ source hook/binary Native12, xác lập bảng mapping từng method ở 1.0.4 → Native12 HUD8 (method tồn tại, khác implementation/chữ ký, không chỉ cùng tên). Ưu tiên kích thước app & divider chạm được khi scene live.
3. Thiết kế adapter **riêng** giữa `DFV12SceneHost` / `DFIRuntime` và UI `CBSlotPillView/CBDividerView`-equivalent mới. Chức năng per-slot App, Focus/Restore, ratio drag phải chạy cùng hai app trước khi làm đẹp giao diện.
4. Sửa source từng chức năng, bảo toàn teardown `standalone6invalidate`; build/publish gói QA riêng chỉ sau static/compile tests; User kiểm trên CarPlay; lỗi exitMode respring thu thập SpringBoard `.ips` và log runtime đúng thời điểm.

## Resume lock

- Repository: `chuongnguyen89dn-ui/Duoface`; branch: `feature/visual12-duodash-recovery`; baseline khi khảo sát: `22c0d682a89fab474fcb2f78cbd9c0cfe4592107` (verify again before edit).
- Source cần đọc: `audit/duonavi-original104-scene/REPORT.md`, `docs/duoface-original104-scene-teardown-vs-qa-20261018.md`, `audit/divider/GRIP_MOBILITY_NATIVE6.json`, `src/DuoFaceVisualHook.m`, `src/DFDividerLogoGrip.inc`, `runtime/fullscreen/DFPickerZoomMenu.xm`, `replacement/visual12/engine/runtime/DFIRuntime.m`, `DFIInterface.inc`, `migration/full_payload/native_test/build_native12_speed8compact_candidate.py`.
- Build environment only if separately authorized for implementation: existing GitHub Actions macOS iOS SDK / dpkg/ldid; Sileo publisher `chuongnguyen89dn-ui/carplaydsp` remains untouched in this checkpoint.
