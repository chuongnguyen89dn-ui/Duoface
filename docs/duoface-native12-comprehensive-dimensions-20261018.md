# DuoFace Native12 HUD8 — kiểm kê kích thước giao diện toàn diện (2026-10-18)

**Phạm vi:** Đối chiếu `DuoNavi 1.0.4` (cơ chế máy), `Native12 HUD8` (bản giao diện duyệt), hồ sơ cũ `tiep tuc du an.md` và lõi UI DuoFace độc lập. Đây là **kiểm kê mã nguồn**, chưa phải đo pixel/chạy thử trên CarPlay.

## Kết luận về phiên bản và bằng chứng

- Hồ sơ `tiep tuc du an.md` chứa **phương án cũ 40pt** ngày 14/10 cho thanh menu. Đã được thay thế bằng **30pt một hàng** theo mã `runtime/fullscreen/DFPickerZoomMenu.xm` và kiểm kê `audit/duoface-picker-layout-sanity-20261015.json`. **Không đưa lại 40pt**.
- Original104: vùng content dùng safe area và fallback trái **64pt**; lưới App dùng **4×2** mặc định, 4–6 cột/2–3 hàng hợp lệ, phân trang ngang. Không có quyền suy luận toàn bộ hình dáng Native12 từ original104.
- Native12: picker **logo ngang 120×30pt**, menu 30pt, các nút rộng 43/51/47/51pt, SF Symbol 16pt, label 10pt, chừa 48pt cho X. Original picker sheet bo 20pt và có border1pt, nhưng **bản đã duyệt bỏ border = 0pt, giữ blur**. Đã sửa lớp QA từ 14/1 thành **20/0** commit `f311628`.
- Speed8 HUD: **104×46pt** (nhân scale tùy chỉnh); biển giới hạn mặc định tròn 34pt; bảng cài đặt cao 169pt; giữ độc lập nguồn tốc độ (chưa kết nối).
- **Các số 74×30 pill, 36×44 logo chia, 16pt vùng nhận kéo, 8pt khoảng thẻ và 52pt recent là ước lượng QA, KHÔNG phải đo Native12.** Không được ghi thành 'đã đúng' nếu chưa phân tích bản Native12 hoặc có ảnh màn hình thực.

## Ma trận nguồn/kích thước

| Thành phần | Kích thước/điều kiện | Mã nguồn | Mức xác nhận |
|---|---|---|---|
| Window usable area | source: safe area -> left 64 fallback | `replacement/visual12/engine/runtime/DFINativeShell.inc:48` | original104 / reference |
| Minimum usable size | 100x100 | `replacement/visual12/engine/runtime/DFINativeShell.inc:50` | original104 / fallback |
| Layout modes | 8 kinds (1,2,3,4,5,6,7,8) | `replacement/visual12/engine/DFILayouts.h:10` | approved / needs-device |
| Pane pill | 38..80pt wide; 19/22pt tall, native flags | `replacement/visual12/engine/runtime/DFINativeShell.inc:145` | native12-actual-deb-updateBoundsSize / six-modes-corrected-source-not-device |
| App button | Left half of actual pill width, full pill height | `replacement/visual12/engine/runtime/DFINativeShell.inc:170` | native12-actual-deb-layoutSubviews / corrected-source-not-device |
| Expand/restore button | Right half of actual pill width, full pill height | `replacement/visual12/engine/runtime/DFINativeShell.inc:171` | native12-actual-deb-layoutSubviews / corrected-source-not-device |
| Divider pan touch | 16pt; thin stroke 1pt | `replacement/visual12/engine/runtime/DFIInterface.inc:308` | qa / not-native-proven |
| Divider logo control | Square 28pt if divider length <280pt; else square 30pt | `replacement/visual12/engine/runtime/DFIInterface.inc:319` | native12-actual-deb-updateGripLayout / corrected-source-not-device |
| Approved native logo hold | 0.30s | `src/DFDividerLogoGrip.inc:10` | approved-native / missing-in-qa |
| Approved independent logo action | tap swaps apps | `replacement/visual12/engine/runtime/DFIInterface.inc:172` | approved-native / corrected |
| Independent hold recognizer | 0.30s | `replacement/visual12/engine/runtime/DFINativeShell.inc:243` | approved-native / corrected |
| Independent logo position storage | fraction 0.10..0.90 of divider | `replacement/visual12/engine/runtime/DFIInterface.inc:595` | qa / needs-device |
| Restore the prior ratio | do not reset fraction/secondary | `replacement/visual12/engine/runtime/DFIInterface.inc:460` | qa / corrected |
| Sheet width | max 470, responsive min180, 8pt margins | `replacement/visual12/engine/runtime/DFINativeShell.inc:286` | qa / not-native-proven |
| Sheet height | max 280, min140, content 40pt*count+55 | `replacement/visual12/engine/runtime/DFINativeShell.inc:287` | qa / not-native-proven |
| Sheet rounding | 20pt original V12 | `replacement/visual12/engine/runtime/DFINativeShell.inc:263` | original12 / reference |
| Sheet outline | 0pt approved; original was 1pt | `replacement/visual12/engine/runtime/DFINativeShell.inc:265` | approved-native / reference |
| Picker menu row | 30pt, replaces old 40pt experiment | `replacement/visual12/engine/runtime/DFIInterface.inc:332` | approved-native / reference |
| Header logo | 120x30pt at full width | `runtime/fullscreen/DFPickerZoomMenu.xm:404` | approved-native / reference |
| App/Zoom/Style/Close widths | 43/51/47/51pt | `replacement/visual12/engine/runtime/DFIInterface.inc:334` | approved-native / reference |
| Close X reserved | 48pt; QA X 32x26 | `replacement/visual12/engine/runtime/DFIInterface.inc:332` | approved-native / partial |
| Menu icon | 16pt | `replacement/visual12/engine/runtime/DFIApprovedVisuals.h:64` | approved-native / reference |
| Menu label | 10pt | `replacement/visual12/engine/runtime/DFIApprovedVisuals.h:53` | approved-native / reference |
| App grid columns | valid 4..6; default 4 | `replacement/visual12/engine/runtime/DFINativePickerCards.inc:58` | original104 / reference |
| App grid rows | valid 2..3; default 2 | `replacement/visual12/engine/runtime/DFINativePickerCards.inc:63` | original104 / reference |
| App grid orientation | horizontal paged with UIPageControl | `replacement/visual12/engine/runtime/DFINativePickerCards.inc:151` | original104 / reference |
| Card spacing | 8pt | `replacement/visual12/engine/runtime/DFINativePickerCards.inc:146` | qa / not-native-proven |
| App card icon | 22..44pt | `replacement/visual12/engine/runtime/DFINativePickerCards.inc:186` | qa / not-native-proven |
| Recent card height | 52pt | `replacement/visual12/engine/runtime/DFINativePickerCards.inc:162` | qa / not-native-proven |
| Layout preview inset | 9x8pt and 1.2pt outline | `replacement/visual12/engine/runtime/DFIInterface.inc:68` | qa / not-native-proven |
| Speed8 floating HUD | 104x46pt * scale | `replacement/visual12/engine/runtime/DFV12NativeHUD8.inc:250` | native8-source / reference |
| HUD limit circle | 34pt ring, 17 radius | `replacement/visual12/engine/runtime/DFV12NativeHUD8.inc:66` | native8-source / reference |
| HUD settings | 169pt tall; 220..320pt wide | `replacement/visual12/engine/runtime/DFV12NativeHUD8.inc:273` | native8-source / reference |
| HUD eight settings | 4 columns, each height49, stride57 | `replacement/visual12/engine/runtime/DFV12NativeHUD8.inc:289` | native8-source / reference |
| HUD settings hold | 0.6s | `replacement/visual12/engine/runtime/DFV12NativeHUD8.inc:48` | native8-source / reference |
| Pane touched border | 1pt active, 0 otherwise | `replacement/visual12/engine/runtime/DFIInterface.inc:272` | qa / needs-device |
| Approved logo red | RGB 227/2/15 | `replacement/visual12/engine/runtime/DFIApprovedVisuals.h:10` | approved-native / reference |


**Sau quét DEB Native12 thật:** `CBSlotPillView.updateBoundsSize` chính thức chọn một trong 6 chiều rộng **38/44/64/72/76/80pt**, và chiều cao **19/22pt**, theo cờ isFocusedMode, showsExpandButton, isCompactMode. Source-owned `DFINativeSlotPillView.nativeReferenceSize` + `DFIInterface.inc` hiện dùng bảng này. **Mới chứng minh mã nguồn; chưa kiểm tra cảm ứng/hitbox/Compact trigger trên xe.** Chi tiết tại [báo cáo DEB](duoface-native12-actual-deb-ui-component-bridge-20261018.md).

## Lỗi chênh lệch và thứ tự sửa

1. **Đã sửa có chứng cứ:** bo góc picker 20pt, viền 0pt theo native đã duyệt; CI [39098247134](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39098247134) compile ARM64 PASS. Kích thước ngang menu 30pt (không 40pt).
2. **Đã sửa mã nguồn, chưa nghiệm thu thiết bị:** logo chia nay **tap → swap**, **giữ ≥0,30s → kéo dọc thanh chia**; riêng từng logo lưu vị trí tương đối 0,10–0,90; pan trên thanh ngoài logo vẫn thay tỷ lệ; thoát focus giữ `fraction/secondary` gốc. Các handler được viết độc lập, chưa có ảnh hoặc log CarPlay chứng minh đúng hành vi.
3. **Chưa đo được trên thiết bị thật:** tọa độ logo và hit-test runtime, trigger compact của pill, kích thước từng card/ảnh/chấm trang native sau renderer; các frame ứng dụng khi mở thật; vị trí hệ thống Dock/status từng đầu màn.
4. **Điều kiện đạt:** cần xuất log frame ở chính CarPlay, ảnh màn hình thực cho 8 layout + picker + từng pane ở độ phân giải máy, đối chiếu thông số pixel/point và callbacks; compiler PASS ≠ CarPlay UI PASS.

## Khôi phục công việc

- Repo `chuongnguyen89dn-ui/Duoface`, nhánh `feature/visual12-duodash-recovery`; script quét có thể chạy từ root repo: `python3 scripts/audit_native12_ui_dimensions.py --strict --json audit/native12-ui-dimensions-20261018.json --md docs/duoface-native12-comprehensive-dimensions-20261018.md`.
- CI compile-only `.github/workflows/duoface-visual12-engine-bind-ci.yml` chạy script cùng test cây giao diện; không đóng DEB. Bản Native12 HUD8 ổn định trên Sileo không chỉnh sửa.
- Dữ liệu JSON có **nguồn/lượt/line và mức bằng chứng** để cuộc chat tiếp tục không phải đoán kích thước.

## Bằng chứng binary Native12 cần đào sâu — không thay bằng suy đoán

- `audit/visual-methods-arm64.txt` kiểm kê chính xác `CBSlotPillView.layoutSubviews` tại IMP `0x84c30` và `updateBoundsSize` tại `0x85184`; các callback riêng `dotsTapped:` `0x85580`, `expandTapped:` `0x85698`, `restoreTapped:` `0x857b0`. Tệp **chưa chứa phép đo kích thước pill** từ phần disassembly tương ứng, do đó không được xác nhận 74×30 là Native12.
- Cùng nguồn ghi `CBDividerView.layoutSubviews` `0xff410` và `updateGripLayout` `0xff460`, `pointInside:withEvent:` `0xff728`, `hitTest:withEvent:` `0xff974`. Đã giải được khung nút vuông 28/30pt từ `setFrame:` tại 0xff6c0 và ngưỡng chiều dài divider 280pt (literal VM 0x312488). Nút QA 36×44pt cũ đã được thay. Dải pan 16pt vẫn là QA, chưa được xác nhận từ native hay thiết bị.
- iOS 16 source-only ARM64 compiler cảnh báo `UIButton.titleEdgeInsets` có thể bị bỏ qua khi button có configuration. Đã sửa riêng `DFIApprovedVisuals.h` để căn **16pt icon trên, nhãn 10pt dưới** bằng UIImageView/UILabel có frame; không thay callback. Commit `55610b042fcb9c257a4e1000c762951a3902a126`, static regression `e30ce515370d9224613f6c81d0b7a8d7ae33406b`. Chỉ là kiểm tra code, chưa có ảnh xe.
- Chưa chốt pixel sheet/card/toolbar theo độ phân giải thật; muốn kết luận phải có frame log từ CarPlay và ảnh Native12 đã cài. Không tự ép `UIWindowLevelAlert+100` thành số khác trước khi xác minh window stacking.

## Bổ sung: kích thước divider gốc đã được giải mã 18/10/2026

- Hệ thống kiểm chứng read-only [Actions 39100554270](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39100554270) đọc DEB Native12 pinned SHA256 và ánh xạ LC_SEGMENT_64. Giá trị `0x312488` = **280.0pt**; `0x311948` = ngưỡng alpha **0.01**, không phải kích thước.
- Ở ARM64 `CBDividerView.updateGripLayout` `ff4b4–ff4d0`: `fcsel d0,d2,d3,eq` chọn **bounds.width** cho divider ngang, **bounds.height** cho divider dọc. Đây là **chiều dài vạch chia**, không phải độ dày; `d8` = 28pt nếu chiều dài <280pt, ngược lại 30pt. `setFrame:` tại `ff6a8–ff6c0` đặt **hình vuông d2=d3=d8**.
- Native `CBDividerView.pointInside:withEvent:` có `CGRectInset(...,-12,-12)` quanh nút; QA đã sửa kích thước hiển thị và vùng chạm tương ứng tại `DFIInterface.inc`, `DFINativeShell.inc`. Giữ hoạt động tap/hold/pan cũ, không thay scene/window.
- Tình trạng: **đã sửa nguồn QA và kiểm chứng ARM64 tĩnh, chưa đo/duyệt giao diện trên CarPlay thật**; chưa đóng DEB hoặc phát hành Sileo.

### Bổ sung: bố trí nút bên trong pill

- `CBSlotPillView.layoutSubviews` (Native12 IMP 0x84c30) lấy độ rộng/chiều cao từ `bounds`, chia độ rộng pill làm hai (`fmul width×0.5` rồi làm tròn) để đặt nút đầu `CGRect(0,0,half,height)` và nút còn lại `CGRect(half,0,width-half,height)`; hai nút cùng chiều cao pill.
- Sáu độ rộng Native12 đã xác minh đều là số chẵn 38/44/64/72/76/80pt, nên QA `half=width*0.5` chính xác trên các kích thước đó. Thay các nút 30pt trước đây vốn chồng nhau khi pill còn 38pt.
- Nút focus/restore đã có callback QA, nhưng `setFocused`/ẩn hiện/gesture thực vẫn cần nghiệm thu trên CarPlay; không đồng nhất source/công thức với kiểm thử cảm ứng.
