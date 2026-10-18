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
| Pane pill | 74x30; upper-right 2pt | `replacement/visual12/engine/runtime/DFIInterface.inc:281` | qa / not-native-proven |
| App button | 30x26 at (4,2) | `replacement/visual12/engine/runtime/DFINativeShell.inc:132` | qa / not-native-proven |
| Expand/restore button | 30x26 at (39,2) | `replacement/visual12/engine/runtime/DFINativeShell.inc:133` | qa / not-native-proven |
| Divider pan touch | 16pt; thin stroke 1pt | `replacement/visual12/engine/runtime/DFIInterface.inc:290` | qa / not-native-proven |
| Divider logo control | 36x44pt | `replacement/visual12/engine/runtime/DFIInterface.inc:290` | qa / not-native-proven |
| Approved native logo hold | 0.30s | `src/DFDividerLogoGrip.inc:10` | approved-native / missing-in-qa |
| Current independent logo action | tap opens menu, should swap | `replacement/visual12/engine/runtime/DFIInterface.inc:163` | qa / known-wrong |
| Sheet width | max 470, responsive min180, 8pt margins | `replacement/visual12/engine/runtime/DFINativeShell.inc:238` | qa / not-native-proven |
| Sheet height | max 280, min140, content 40pt*count+55 | `replacement/visual12/engine/runtime/DFINativeShell.inc:239` | qa / not-native-proven |
| Sheet rounding | 20pt original V12 | `replacement/visual12/engine/runtime/DFINativeShell.inc:215` | original12 / reference |
| Sheet outline | 0pt approved; original was 1pt | `replacement/visual12/engine/runtime/DFINativeShell.inc:217` | approved-native / reference |
| Picker menu row | 30pt, replaces old 40pt experiment | `replacement/visual12/engine/runtime/DFIInterface.inc:310` | approved-native / reference |
| Header logo | 120x30pt at full width | `runtime/fullscreen/DFPickerZoomMenu.xm:404` | approved-native / reference |
| App/Zoom/Style/Close widths | 43/51/47/51pt | `replacement/visual12/engine/runtime/DFIInterface.inc:312` | approved-native / reference |
| Close X reserved | 48pt; QA X 32x26 | `replacement/visual12/engine/runtime/DFIInterface.inc:310` | approved-native / partial |
| Menu icon | 16pt | `replacement/visual12/engine/runtime/DFIApprovedVisuals.h:55` | approved-native / reference |
| Menu label | 10pt | `replacement/visual12/engine/runtime/DFIApprovedVisuals.h:38` | approved-native / reference |
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
| Pane touched border | 1pt active, 0 otherwise | `replacement/visual12/engine/runtime/DFIInterface.inc:263` | qa / needs-device |
| Approved logo red | RGB 227/2/15 | `replacement/visual12/engine/runtime/DFIApprovedVisuals.h:10` | approved-native / reference |

## Lỗi chênh lệch và thứ tự sửa

1. **Đã sửa có chứng cứ:** bo góc picker 20pt, viền 0pt theo native đã duyệt; CI [39098247134](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39098247134) compile ARM64 PASS. Kích thước ngang menu 30pt (không 40pt).
2. **Đã dựng nhưng chưa xác minh:** 8 bố cục, pill/chọn app/zoom, đường chia, logo. Thao tác logo hiện **tap → menu** trong QA, trái yêu cầu **tap → swap, giữ 0,30s → di chuyển logo**. Tính năng nhấn giữ đúng này hiện chỉ nằm trong hook Native cũ `src/DFDividerLogoGrip.inc`, không tự động đi sang QA.
3. **Chưa đo được từ bản đang truy cập:** độ rộng/cao pill Native12 thực tế; tọa độ logo và divider hit-test native; kích thước từng card/ảnh/chấm trang native sau renderer; các frame ứng dụng khi mở thật; vị trí hệ thống Dock/status từng đầu màn.
4. **Điều kiện đạt:** cần xuất log frame ở chính CarPlay, ảnh màn hình thực cho 8 layout + picker + từng pane ở độ phân giải máy, đối chiếu thông số pixel/point và callbacks; compiler PASS ≠ CarPlay UI PASS.

## Khôi phục công việc

- Repo `chuongnguyen89dn-ui/Duoface`, nhánh `feature/visual12-duodash-recovery`; script quét có thể chạy từ root repo: `python3 scripts/audit_native12_ui_dimensions.py --strict --json audit/native12-ui-dimensions-20261018.json --md docs/duoface-native12-comprehensive-dimensions-20261018.md`.
- CI compile-only `.github/workflows/duoface-visual12-engine-bind-ci.yml` chạy script cùng test cây giao diện; không đóng DEB. Bản Native12 HUD8 ổn định trên Sileo không chỉnh sửa.
- Dữ liệu JSON có **nguồn/lượt/line và mức bằng chứng** để cuộc chat tiếp tục không phải đoán kích thước.
