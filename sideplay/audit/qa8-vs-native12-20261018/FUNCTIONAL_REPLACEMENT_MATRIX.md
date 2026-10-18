# Kiểm toán chức năng QA8 ↔ Native12/HUD8 ↔ SidePlay 1.0.4-1 (18/10/2026)

## Nguồn chứng cứ và giới hạn

Ba DEB **đã được tải, kiểm SHA256 trước giải nén**, chạy `dpkg-deb -x/-e` không thực thi maintainer scripts và kiểm SHA256 từng file thông qua GitHub Actions trên macOS. Script: `sideplay/tools/audit_qa8_vs_native12_packages.py`; workflow `.github/workflows/sideplay-qa8-native12-deb-audit.yml`. Kết quả [REPORT.md](./REPORT.md) và toàn bộ `qa8.json`, `native12.json`, `sideplay104.json` nằm cạnh báo cáo này.

| Gói | SHA256 DEB | File payload | Mach-O | PNG |
|---|---|---:|---:|---:|
| QA8 `com.duoface.sideplaydisplay 0.1.6~native12bootstrap8` | `e14a3c8fe9ae6ee44b6dae6fb4521a16c94bf42e837bca2bd79b36a39a3d86d0` | 6 | 1 | 4 |
| Native12+HUD8 `com.duoface.independent 0.1.0~native12+speed8compact` | `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad` | 43 | 8 | 25 |
| SidePlay gốc `com.sideplay 1.0.4-1` | `7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c` | 136 | 7 | 119 |

**ĐỌC CHÍNH XÁC:** SHA256 trùng/không trùng chứng minh byte giống/khác, KHÔNG tự chứng minh tương đương hành vi runtime. Báo cáo quét tất cả path/byte/hash, binary Mach-O class exports, selected printable strings, linked frameworks và plists; **chưa disassemble every function**, chưa chạy trên CarPlay. User báo nhiều lỗi trên máy; chưa có version Installed/log mới để xác nhận gói cụ thể.

## Trả lời trực tiếp: “Đã gỡ tính năng cũ đã thay thế chưa?”

**CHƯA. Không có việc gỡ các module cũ trong QA8.** `QA8/control` có `Depends: ... com.sideplay (>= 1.0.4-1)`, `Conflicts` và `Replaces` rỗng. DEB QA8 **không có file payload trùng đường dẫn** với SidePlay 1.0.4 hoặc Native12. Vì vậy cài QA8 KHÔNG thay thế, xóa hoặc ghi đè `SidePlay.dylib`, `SidePlay.app`, `SidePlayPrefs` và các `SidePlayHUD*.dylib`; bản gốc vẫn dùng để host app.

Source QA8 `sideplay/sileo-qa/Tweak.xm` xác nhận:
- `DFSPHideReplacedView` (dòng ~51–65) chỉ dùng `view.hidden=YES` **khi đã có `DFSPUI` và `DFSPWindow`**, rồi snapshot trạng thái để restore.
- `DFSPRefresh` (~261–294) chỉ ẩn `SPPane.chipView`, `SPPane.layoutButton`, và vài `UILabel/UIButton` placeholder (chứa “trống”, “thêm app”, “add app”, “empty”).
- `%hook SPDash` (~516–555) vẫn gọi `%orig` trong `setCarWindow:`, `layout:`, `layoutRootView`; logic khởi tạo app scene, khung, chrome, header và picker của SidePlay vẫn chạy.
- `DFSPRemove` (~375–401) **khôi phục các UI cũ và window** khi tháo QA; tính reversibility đã cố ý giữ, không phải migration hoàn chỉnh.
- `nativeFrameRequestedAppForSlot` (~318–325) vẫn gọi `SPDash.showPickerForPane:`; `nativeFrameRequestedStyle` (~333–336) gọi `SPDash.layoutChooser`. SidePlay tự vẽ các màn đó.
- `DFSPNative12Host` chỉ thay `rootView.frame` ở normal/fullscreen; QA8 dùng `window.windowLevel` và fallback 64pt, không có system bar owner/ACK đã gắn với Dashboard native.
- Đã có code độc lập cho pill/divider nhưng không chứng minh đủ 3-pane, 8 layouts, HUD8, Settings, recent picker, scene owner hay border rules.

## Ma trận từng tầng

| Native12 + HUD8 đã có trong DEB | QA8 đã mang sang | Legacy SidePlay còn giữ | Nhận định |
|---|---|---|---|
| `DuoFaceDashboard.dylib`: `CBBridgedSplitApp`, `CBBridgeManager`, `CBWindow`, dashboard/native renderer | `DFSPNative12Host` + `DFSPNativeFrame` visual overlay | `SidePlay.dylib` với `SPDash`, `SPPane` và app host chính | **Chưa thay lõi/hệ thống hiển thị**, cũ và overlay cùng hoạt động |
| `CBSplitSplashScreenView`/native startup trong app+dashboard | Không có splash native có bằng chứng, chờ hook lớp SidePlay | `SPLoadingView`, SidePlay startup/session | **Chưa tương đương** |
| `CBSlotPillView` và `DuoFaceVisualHook.dylib` | `DFSPNativeSlotPill` (chỉ 2 pill) 38/44/64/72/76/80 ×19/22; 4 ảnh dùng chung byte | SidePlay `chipView`/`layoutButton` ẩn nếu `DFSPRefresh` đã chạy | **Phần vẽ đạt một số thông số; cấu trúc/hit-test chưa device PASS** |
| `CBDividerView` + `DuoFaceLogoGripOnly.dylib` | Divider pan, logo tap swap, hold ≥0.30s move | `SPDash.setRatio:/layout:` áp lên scene, các handler SidePlay vẫn tồn tại | **Chưa chuyển owner, còn bug đảo pane ratio != 1/2:** `DFSPNativeFrame.m:250-260` |
| `CBMultitaskingOverlayView`, `CBAppPickerViewController`, danh sách app/recent | Sheet menu vẽ thủ công App/Zoom/Style/Close | **SidePlay `showPickerForPane:`, `buildPickerForPane:`** thực hiện App | **App vẫn là picker SidePlay, không phải Native12** |
| Native Style, layouts 1–3 panes / 8 configurations | Overlay chỉ đọc 2 pane và 1 ratio cho split | **SidePlay `layoutChooser` và `SPDash.layout:`** | **Chưa mang 8 layouts và layout ownership Native12** |
| `DuoFaceFullscreenBridge.dylib`, `DFFullscreenCoordinator`, `DFFullscreenTransport`, chrome | QA8 `DFSPNative12Host.applyNormal/applyFullscreen`, thay content root + `windowLevel` | `SPDash.carDockMode/carWindowFrameNow/layoutRootView` vẫn nguyên | **Chưa có owner bar/ACK và chưa chứng minh Normal thấy native CarPlay bar** |
| `DuoFaceSpeedHUD.dylib` + `DuoFaceSpeedOwner.dylib`, `DFSpeedNativeHUD` | **Không có module HUD8** | SidePlay 4 HUD providers/relay riêng vẫn nằm trong gói cũ | **Chưa mang HUD8; không được nhầm bong bóng SidePlay là Native12 HUD8** |
| `DuoFaceUI.app`, native iPhone Settings | **Không chứa app/prefs iPhone** | `SidePlay.app` + `SidePlayPrefs.bundle` | **Chưa có giao diện iPhone DuoFace riêng** |
| Native VisualHook viền/tint/picker original | Có vài màu/blur/asset QA nhưng không có hook border tương đương | SidePlay có styling/header riêng | **Chưa tương đương viền đỏ chỉ khi chạm, auto-hide, không viền fullscreen** |
| Package Native12 có 25 PNG (18 icon iPhone, 7 assets giao diện) | 4 PNG đã **khớp SHA256 từng byte** với Native12: `duoface-fullscreen.png`, `duoface-logo-picker-alpha-v2.png`, `duoface-picker.png`, `duoface-swap.png` | SidePlay 119 PNG (đa số HUD) | **Ảnh đúng; còn thiếu 21 PNG của package Native12, gồm icon/branding, không nên suy ra 21 component CarPlay** |
| Standalone host/lifecycle/teardown đã kiểm ở Native reference | QA8 phụ thuộc sự kiện `SPDash`, lazy hook | `SidePlay.dylib` và its app lifecycle | **Không độc lập, exitmode/reconnect chưa device PASS** |

## Lỗi cấu trúc cần sửa trước test tiếp

1. **P0 UI owner:** Nếu sản phẩm đích là DuoFace, cần source-owned Native12-equivalent UI root có owner duy nhất, tách driver SidePlay host của QA khỏi old SidePlay display renderer. Không được “ẩn vài nút” rồi gọi là đã xóa giao diện cũ. Giữ nguyên vendor app scene host cho tới khi có host độc lập hợp pháp/đã device-test.
2. **P0 Normal system bar:** Chưa có mã xác thực chuyển native Dashboard chrome visibility/usable frame/owner có ACK. Không thử thêm fallback giá trị mới hoặc crop `UIWindow.frame` dựa phỏng đoán.
3. **P1 geometry:** Divider phải dựa adjacency các cạnh thực của `SPPane` và style (layout đảo chiều); QA8 hiện tính x=(maxX(a)+minX(b))/2 hoặc tương đương y, có thể đặt sai line. Cần unit tests 1/3,1/2,2/3 theo thứ tự normal/reverse, có hai app live và test hitTouch.
4. **P1 App/Style/HUD8:** Thay các call `showPickerForPane:`/`layoutChooser` bằng UI/adapter native-owned với live app data, bổ sung layouts/HUD8 sau khi owner và bar hợp lệ. Không xóa SidePlay host các selector đang vận hành scene trước khi có thay thế.
5. **P0 delivery:** QA8 chưa xuất bản Sileo; `carplaydsp:main:.github/workflows/build.yml` vẫn pin QA7 `0.1.5~native12visual7`. User feedback hiện tại chưa xác định Installed version. **Không gán lỗi quan sát trên máy cho QA8 nếu đang cài QA7.**

**Không thay đổi:** Native12+HUD8 ổn định, Visual12, SidePlay original, Sileo package/pins; không build hoặc deploy mới từ báo cáo này. QA8 chỉ được quét tĩnh và so sánh trên GitHub.

## Nghiệm thu bắt buộc để được gọi “đã thay thế”

- Một owner render root/native chrome rõ ràng, toàn bộ old display UI renderer không còn hiện/cướp touch (trong khi scene host còn chạy).
- Normal lên CarPlay hiển thị thanh native; Zoom In/Out theo menu, no cropped Home; test xe đỗ.
- Hai pill top-center của đúng các real panes, App picker/Style Native12, drag line ratio với 2 app active, logo-move và tap-swap tách biệt, 8 layouts/3-pane behavior phù hợp Native12.
- HUD8 gắn đúng owner, hành vi thiết lập/bong bóng không trùng; giữ dữ liệu nguồn tùy điều kiện thực tế.
- Settings riêng, scene close/reconnect và SpringBoard respring không exitmode. Log+ảnh+version Installed minh chứng từng mục.

**Hồ sơ tổng quát:** `sideplay/tiep tuc du an.md`; báo cáo hiện hành ba DEB + JSON trong `sideplay/audit/qa8-vs-native12-20261018/`.
