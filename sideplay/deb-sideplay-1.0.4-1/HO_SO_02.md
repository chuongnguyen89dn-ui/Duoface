- **Darwin notify (libnotify `notify_*`)** — kênh trạng thái số/dạng nhẹ, đặc biệt cho HUD: mỗi loại dữ liệu có tên notify riêng và giá trị trạng thái đi kèm (`notify_set_state`/`notify_get_state`), cộng họ hàm `SPHEncode*/SPHDecode*` đóng gói payload (sample tốc độ, cảnh báo, vị trí, kích thước, lease quá tốc độ…).
- **CFNotificationCenter (Darwin)** — kênh lệnh app ↔ lõi (`com.sideplay/...`) và thông báo đổi preference (`SPHPreferencesValueChanged`).
- **File dùng chung trong `/var/mobile/Library/Preferences/`** — `com.sideplay.hosted.plist` (danh sách app đang host), `com.sideplay.install`, các file dotfile điều khiển (kill switch/boot count); log ghi ra `/var/mobile/Library/Logs/SidePlay.log` / `SidePlay-hud.log`.

### 5.4. Hệ HUD bong bóng tốc độ (kiến trúc 3 tầng)

1. **Nguồn (trong tiến trình app bản đồ)**: mỗi HUD source hook vào app của nó (`MSHookMessageEx`), đọc tốc độ/giới hạn/cảnh báo từ chính đối tượng của app (GOFA: Swift `SpeedBoardModel`/`DatapointModel`; Waze: `WazeLocationManager` + kiểm tra ABI theo bản 5.25.0; VietMap: handler overlay qua `SPHNavSource`). `SPHLocationSession` quản lý phiên GPS dùng chung (xin chạy nền, khoảng cách lọc — chuỗi GOFA ghi `distance filter lease=%d requested=%.1f`).
2. **Xuất bản**: nguồn đóng gói dữ liệu bằng họ `SPHEncode*` và publish qua `SPHOutputEndpoint` (class dùng chung cả 4 binary HUD) theo cơ chế token/phiên (`tokens`, `previous`, `previousSelection`, `previousCommit`, `published`) lên các notify `com.sideplay.hud.*`; nguồn nào đang được chọn do `SPHSelectOutputSource`/`SPHOutputRequestName` quyết định, có họ notify `background.*` để giữ nguồn sống theo ngữ cảnh (xe/điện thoại/SidePlay/từng app).
3. **Relay (SpringBoard)**: `SidePlayHUDRelay.dylib` nhận & giải mã (`SPHDecode*`, `SPHReadSourceOutput`), chuẩn hoá (`SPHNormalizeSourceOutput`), tính tên cảnh báo + tên icon (`SPHRoadAlertName`/`SPHRoadAlertIconName` → 112 PNG trong `usr/share/sideplay-hud/`), quản lý **lease quá tốc độ** (`SPHPublishOverspeedLease`, `SPHOverspeedLeaseActive`, `com.sideplay.hud.overspeed.lease/.mode`) và trạng thái kích thước/vị trí bong bóng (`size-state`, `phone-placement-percent`, `SPHNextTapSize` — chạm để đổi cỡ).
4. **Vẽ**: phía lõi có `SPHSpeedCardSidePlay` (thẻ tốc độ) + `SPHOverspeedFrameSidePlay` (khung cảnh báo quá tốc độ) + `SPHudGestures`; phía prefs có các controller cấu hình bong bóng (vị trí/kích thước/bề mặt/thứ tự module — `sideplayModules`, `sideplayPosition`, `sideplayScale`, `sideplayClarity`, `sideplayXPercent/YPercent`). Họ notify `legacy.*` cho thấy còn một đường tương thích ngược với định dạng HUD đời trước.

### 5.5. Cài đặt (preferences)

- PreferenceLoader entry → `SPRootListController` (bundle `com.sideplay.prefs`); giá trị lưu dưới domain `com.sideplay` (xem mục 6 để biết toàn bộ key công khai trong Root.plist).
- Đổi cài đặt → prefs post Darwin notify → lõi/HUD áp dụng trực tiếp (không cần respring cho phần lớn key; vẫn có nút Respring thủ công trong giao diện).
- Có 2 "Lối tắt" (quick profile 1/2 — `SPQuickProfileController`), tuỳ chỉnh từng app (`SPAppListController`/`SPAppSettingsController`), chẩn đoán (`SPHDiagnosticsController`) và báo lỗi (`SPReportViewController`).

### 5.6. Mạng & gỡ gói

- App kiểm tra trạng thái qua `GET https://sideplay.pages.dev/api/status` và gửi báo lỗi qua `/api/report` (NSURLSession có trong cả app và prefs).
- `prerm`: khi gỡ, app chạy nền với cờ `--sp-goodbye` để báo server (danh sách cài đặt nặc danh theo ghi chú script), rồi `uicache -u`.
- Depiction/Icon trong control trỏ `https://sideplay.pages.dev/...` — gói phân phối qua repo Sileo/Cydia thông thường.

---

## 6. TÀI NGUYÊN / PLIST / KEYS

### 6.1. Filter plist (tiến trình đích) — trích nguyên văn

| Dylib | Filter |
|---|---|
| `SidePlay.dylib` | `Bundles = ("com.apple.springboard", "com.apple.UIKit")` |
| `SidePlayHUDRelay.dylib` | `Bundles = ("com.apple.springboard")` |
| `SidePlayHUDGofa.dylib` | `Bundles = ("com.lumi.GOFA")` |
| `SidePlayHUDVietMap.dylib` | `Bundles = ("vn.vietmap.live")` |
| `SidePlayHUDWaze.dylib` | `Bundles = ("com.waze.iphone")` |

### 6.2. Preference keys công khai (từ `Root.plist` của SidePlayPrefs, domain `com.sideplay`)

| Key | Kiểu / mặc định | Ý nghĩa (nhãn giao diện tiếng Việt trong gói) |
|---|---|---|
| `enabled` | bool, `true` | "Bật SidePlay" |
| `autoOpen` | bool, `true` | "Tự mở khi cắm CarPlay" |
| `restoreLast` | bool, `true` | "Mở lại bố cục lần cuối" |
| `scaleMode` | int, `3` (giá trị hợp lệ 3/0/1) | "Cách hiển thị app": Mặc định / Giữ tỉ lệ / Phủ kín ô |
| `autoHideBar` | bool, `true` | "Tự ẩn thanh điều khiển" |
| `barHideDelay` | int, `5` (5/10/30/60) | "Ẩn sau" (giây) |
| `carDock` | bool, `false` | "Thanh dock CarPlay" |
| `autoFitCar` | bool, `true` | "Tự động theo màn hình xe" |
| `carZoom` | real, `100` (70–130) | "Thu phóng khung (%)" |

Hành động (không lưu key): `calibrateCar` ("Căn màn hình thủ công"), `respring`, `resetAll`, `reportBug`. Trang con: Lối tắt 1/2 (`SPQuickProfileController`), Bong bóng tốc độ (`SPHPreferencesController`), Tuỳ chỉnh từng app (`SPAppListController`).

Key nội bộ thấy trong binary (không có trong Root.plist): họ `sideplayLayout`, `sideplayModules`, `sideplayPosition`, `sideplayScale`, `sideplayClarity`, `sideplayXPercent`, `sideplayYPercent`, `bubbleEnabled` — cấu hình chi tiết của bong bóng HUD.

### 6.3. Plist khác

- `SidePlay.app/Info.plist` (2.688 byte): xem 3.6 — đáng chú ý: scene manifest hai cấu hình Phone/CarPlay, URL scheme `sideplay`, `UIBackgroundModes=[audio]`, region `vi`.
- `SidePlayPrefs.bundle/Info.plist` (676 byte): ID `com.sideplay.prefs`, principal class `SPRootListController`, bản `1.0.4 (5)`.
- `PreferenceLoader/Preferences/SidePlay.plist` (513 byte): entry PSLinkCell → bundle `SidePlayPrefs`, controller `SPRootListController`.
- App icons: 40/60pt @2x/@3x (4 file); prefs icons 3 cỡ; **112 PNG cảnh báo giao thông** trong `usr/share/sideplay-hud/` (camera, giới hạn tốc độ 5–120, nguy hiểm, thi công…) + `LICENSE-GMapHUD`.

---

## 7. CHƯA XÁC ĐỊNH ĐƯỢC (trung thực)

1. **SHA-256 của chính file .deb không tính lại được** — máy không còn file .deb; giá trị `7f8520b9…` là số kiểm kê gốc 18/10/2026 trong repo. Toàn vẹn của *payload* thì đã chứng minh độc lập (139/139 file khớp inventory), nên rủi ro sai lệch nội dung thực tế bằng 0; chỉ thiếu đối chiếu ở tầng vỏ archive.
2. **Cặp (class, selector) hook chính xác của lõi và của từng HUD source chưa tách được** — binary đã strip symbol method; `MSHookMessageEx`/`MSHookFunction` được import và các class đích hiện diện dạng chuỗi/classref, nhưng ánh xạ 1-1 "hook class X method Y" cần disassembly vùng constructor/`__mod_init_func` và lần theo tham số gọi — chưa làm trong lượt này. Mọi khẳng định về hook trong hồ sơ đều giữ ở mức *tham chiếu/điểm vào đã biết*.
3. **Superclass trực tiếp của các class SP/SPH hiện `?`** trong bảng mục 4 — parser đọc superclass pointer trỏ ra class ngoài binary (vd NSObject/UIView) nên không resolve tên tại chỗ; đây là giới hạn trình bày của parser, không phải thiếu dữ kiện trong binary (classref đầy đủ có trong `work/analysis/objc_*.txt`).
4. **Slice arm64e chưa dump class/method riêng** — bảng mục 4 lấy từ slice arm64; ba binary fat (lõi, relay, prefs) có thêm slice arm64e. Cấu trúc ObjC hai slice theo thông lệ là tương đương, nhưng chưa đối chiếu từng method.
5. **Định dạng payload chính xác của kênh notify HUD** (layout byte của `SPHEncode*/SPHDecode*`, ý nghĩa từng trường token/lease) chưa giải mã — mới xác định được danh tính hàm và tên kênh; cần disassembly các hàm encode/decode để mô tả byte-level.
6. **Logic Swift trong HUD Gofa** mới đọc ở mức symbol/demangle một phần (`gofaSpeedBoard`, `gofaPoints`); chưa dựng lại luồng dữ liệu đầy đủ bên trong các hàm Swift.
7. **Hành vi runtime chưa kiểm chứng** — hồ sơ này thuần tĩnh: chưa cài/chạy gói trên máy thật trong phạm vi nhiệm vụ (và quy tắc cấm thực thi). Các chuỗi log được dùng làm bằng chứng ý đồ thiết kế, không phải bằng chứng hành vi đã quan sát.
8. **Nội dung phản hồi của `api/status` và điều kiện `serviceBlocked/serviceWaiting` trong SPDash** (biến trạng thái có trong ivar) chưa rõ — binary có cơ chế "chờ/bị chặn dịch vụ" và gọi API trạng thái, nhưng tiêu chí máy chủ quyết định thế nào thì không suy ra được từ phía client. Không khẳng định đây là cơ chế bản quyền/giấy phép — dữ kiện hiện có không đủ kết luận.
9. **Audit lịch sử 17–18/10/2026** từng ghi lõi tham chiếu `initForCarPlayShell` — chuỗi này **không xuất hiện** trong lần quét strings trực tiếp lần này của lõi (có thể do khác cách trích strings hoặc khác lát cắt); giữ trạng thái chưa đối chiếu, không khẳng định đúng/sai.

---

*Hết hồ sơ. Dữ kiện thô của lượt quét (dump ObjC, nm, strings, cây thư mục, inventory đối chiếu) lưu tại `work/analysis/` cạnh hồ sơ này.*
