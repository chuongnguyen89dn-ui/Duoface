# DuoFace Native12 HUD8 trên nền host SidePlay — rà soát từ đầu đến hiện tại
Ngày quyết định: **2026-10-18**. Nguồn tiến độ GitHub `chuongnguyen89dn-ui/Duoface`.

## Bản chuẩn và mục tiêu — QUYẾT ĐỊNH NGƯỜI DÙNG
**DuoFace là sản phẩm chính, SidePlay KHÔNG phải giao diện chính**. Giữ bố cục/hình ảnh/điều khiển đã được người dùng duyệt của DuoFace Native12 + HUD8; chỉ sử dụng chức năng CarPlay app-host/scene của SidePlay để QA khi chưa có host độc lập. **Không chép CB vendor binary hoặc cơ chế giấy phép**. Ưu tiên hồ sơ `tiep tuc du an.md`, `ban giao du an duoface moi.md` và tài liệu Native12 đã xác minh, không quét lại DEB tổng quát hoặc suy diễn từ mã QA tự viết.

Mỗi chức năng mới thay tương đương phải **ẩn UI SidePlay cũ (khả năng rollback)**, xác minh với 2 ứng dụng thật trên CarPlay và chỉ loại bỏ legacy UI khỏi package DuoFace độc lập khi thiết bị PASS. Không xóa nền host/scene cần thiết khi đang dùng SidePlay làm substrate.

## Kết quả rà soát QA1 → QA5, phân biệt bằng chứng

| Bản | Source/gói thật | Kết quả xác minh | Thiếu / lỗi |
|---|---|---|---|
| QA1 `0.1.0~zoomqa1` | `sideplay/sileo-qa/Tweak.xm`, [Sileo CI 39119071234](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/39119071234) | **Đã cài thực:** user gửi ảnh Zoom In nổi trên giao diện SidePlay | **FAIL thiết bị:** mất bar CarPlay, SidePlay fullscreen; QA1 chỉ overlay nút/level |
| QA2 `0.1.0~zoomqa2` | hook `SPDash` geometry/dock | Đã build DEB trên feature | Chưa có device PASS; không chứa giao diện Native12 chính |
| QA3 `0.1.1~native12frame3` | `DFSPNativeFrame.m` + `SPDash`, [CI 39121326554](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39121326554) | Có shell, divider gesture, menu, logo ngang source-owned. **Sileo** [39121041655](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/39121041655) | Sai pill (1 nút góc trên trái), app/style vẫn picker SidePlay, startup/HUD8 chưa port, không có device PASS |
| QA4 `0.1.2~native12assets4` | `feature/sideplay-native12-assets-launch`, [CI 39121873603](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39121873603) | DEB hash SHA256 `82e38059c4f221a2efbf74b090962efe29b7b83c22582dadef4d488e8264a420`, 4 PNG thật bên trong | Có ảnh PNG ≠ UI hoàn chỉnh; pill vẫn chỉ 1 nút góc trái; chưa có per-pane focus; **chưa lên Sileo, chưa device PASS** |
| QA5 development | branch `feature/duoface-native12-ui-on-sideplay-host` | Mã mới `DFSPNativeSlotPill.[hm]`, `DFSPNativeFrame.[hm]`, `Tweak.xm`, kiểm thử `check_duoface_qa5_parity.py` | Chưa kết luận build/device; chờ CI, không gọi hoàn thiện |

## Đối chiếu Native12 đã lưu và hành vi hiện hữu

| Hạng mục | Chuẩn đã xác minh / yêu cầu cuối | Status QA5 |
|---|---|---|
| Root CarPlay | Khởi động **NORMAL**, native Dock/bar còn; chỉ Zoom In từ **menu** mới fullscreen; Zoom Out hoàn nguyên | **Chưa device PASS**; code hiện thử SidePlay usableInsets/fallback64 + windowLevel; native Chrome owner chưa nối ACK thật |
| Hai pill | Người dùng xác nhận **mỗi pill GIỮA từng ô**; mỗi pill **hai nút**: App/menu và focus riêng ô; tổng 2 pill/4 nút theo bố cục đôi | **Code QA5 đã thay 1 nút thành 2**, frame dựa `CGRectGetMidX/MidY` từng pane |
| Pill modes | Native12 `CBSlotPillView.updateBoundsSize`: 38/44/64/72/76/80pt × 19/22pt, corner radius11; khi focus nút Restore chiếm trọn pill | **Code QA5** sở hữu `DFSPNativeSlotPill`; chưa biết kích hoạt compact và hitbox đúng trên xe |
| Focus riêng ô | Khác hẳn fullscreen toàn CarPlay, không reset ratio; restore giữ ứng dụng trong hai ô | **Code QA5** gọi `SPPane.layoutInFrame:scaleMode:` (ABI audit xác minh), tạm ẩn sibling view có snapshot; có rollback; **chưa device PASS** |
| Divider logo | 28/30pt theo chiều dài, logo thật, tap swap; giữ 0,30s kéo DỌC thanh để dời logo | Code hiện có; không nhầm với resize ratio; chưa device PASS |
| Ratio kéo | Kéo ngang với divider đứng / kéo dọc với divider ngang, tỷ lệ live 1/3..2/3, snap 4% | `SPDash.setRatio:/layout:` đã nối, scene sizing chưa device PASS |
| Menu | Logo ngang, App – Zoom – Style – Close trong sheet, bar cao30pt | Source & artwork có; cần đối chiếu hoạt ảnh/điều kiện ngữ cảnh/hit |
| Chọn và mở app | **Danh sách/thẻ app/recent/page** theo giao diện Native12, host SidePlay chỉ chạy app | **CHƯA ĐẠT**. Hiện `showPickerForPane:` mở UI **SidePlay**. Không được gọi đây là Native12 picker |
| Style chooser | Giao diện kiểu chia ô của Native12, không phải SidePlay | **CHƯA ĐẠT**, hiện `SPDash.layoutChooser` còn UI SidePlay |
| Màn khởi động | Native12 splash/root/content và chuyển cảnh lúc mới kết nối | **CHƯA ĐẠT**, chỉ chèn view lên `SPDash.setCarWindow:` |
| HUD8 | Bong bóng tốc độ có nguồn/settings và host ổn định như Native12 HUD8 | **CHƯA GHÉP** |
| Dọn giao diện cũ | Không có nút/placeholder kép; giữ original hidden state để phục hồi khi lỗi | Đã có `DFSPHideReplacedView/DFSPRestoreReplacedViews` cho chip/layoutButton/text; UI picker/style SidePlay chưa thay |
| Tính độc lập cuối | Không cần DEB SidePlay/DuoNavi giấy phép sau khi có host độc lập do DuoFace sở hữu | **CHƯA ĐẠT**. QA5 vẫn là tweak phụ thuộc SidePlay 1.0.4 trên máy |
| An toàn iPhone X iOS16 | Không crash SpringBoard/exitMode, không mất touch hai app khi resize, đóng scene/respring hoạt động | **CHƯA DEVICE TEST** |

## Tệp có thể tiếp tục ngay, không làm lại từ đầu

- Giao diện QA5: `sideplay/native12-display/DFSPNativeSlotPill.[hm]` (new), `DFSPNativeFrame.[hm]` (center 2 pills/6 states/gesture), `sideplay/sileo-qa/Tweak.xm` (SPPane focus/restore + old UI hide).
- Tài nguyên đã kiểm bằng DEB: `dist/visual-1.0.3-12/assets/duoface-logo-picker-alpha-v2.png`, `dist/visual-1.0.3-12/assets/VisualAssets/duoface-{picker,swap,fullscreen}.png`. Không lấy hình minh họa bên ngoài làm ảnh gốc.
- Kiểm tĩnh: `python3 sideplay/native12-display/validation/check_duoface_qa5_parity.py`. QA5 workflow `.github/workflows/sideplay-duoface-native12-ui5-static.yml`; Theos DEB `.github/workflows/sideplay-visible-zoom-qa-deb.yml`. Đang theo dõi build.
- Bằng chứng lịch sử Native12: `feature/visual12-duodash-recovery:docs/duoface-native12-comprehensive-dimensions-20261018.md`, `replacement/visual12/engine/runtime/DFINativeShell.inc`, `DFIInterface.inc`, `docs/native12-complete-gui-replacement-map-20261018.md`.
- ABI SidePlay tĩnh: `sideplay/native12-display/audit/SIDEPLAY_SPLIT_OWNER_SELECTORS.json` từ run [39120307831](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39120307831), `SPDash.setRatio:`, `layout:`, `showPickerForPane:`, `SPPane.layoutInFrame:scaleMode:`.

## Bước tiếp theo có tiêu chí rõ ràng

1. **Đóng QA5:** phải hết lỗi compiler, pass static gates, Theos DEB + SHA256 và có link artifact đúng version, không cập nhật Sileo với build lỗi.
2. **Không được coi UI đã hoàn chỉnh chỉ vì QA5 compile:** tìm source-approved Native12 picker, App/recent/paging và startup splash trong lịch sử; nếu chưa có adapter `SPDash` chọn app thật thì chỉ ghi blocker, không dựng UI giả.
3. Kết nối lại Native HUD8 đã duyệt bằng owner riêng và có teardown; giữ app host SidePlay không phụ thuộc CB licensing.
4. Cho người dùng **test qua Sileo** khi gói an toàn, trên iPhone X lúc xe đỗ: root Normal/dock, 2 pill ở giữa, App button, per-pane Focus/Restore, 2 app scene live, ratio/hold/swap, Zoom in/out, close/reconnect/respring. Lưu ảnh và log từng mục.
5. Chỉ sau device PASS mới loại legacy SidePlay UI trong build DuoFace độc lập và ngừng phụ thuộc SidePlay gốc.
