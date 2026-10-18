# KIỂM KÊ TOÀN DIỆN SIDEPLAY 1.0.4-1 — 2026-10-18

> **KẾT LUẬN TRẠNG THÁI: CHỈ KHÔI PHỤC ĐƯỢC BẰNG CHỨNG AUDIT TRƯỚC; CHƯA CÓ BYTE DEB ĐỂ QUÉT LẠI.** Không được dùng tài liệu này để khẳng định một cuộc phân tích nhị phân mới, kết quả test máy thật, toàn bộ danh sách 136 file, hoặc tích hợp CarPlay đã thành công.

## 0. Phạm vi, thời điểm, nguồn chứng cứ

- Mục tiêu theo yêu cầu 2026-10-18: tìm lại `com.sideplay_1.0.4-1_iphoneos-arm64.deb` đã được người dùng đưa vào chat ngày 17/10 và quét tổng quát toàn bộ gói trước mọi công việc SidePlay → DuoFace.
- Truy tìm **trong lượt này**: liệt kê `/mnt/data` và tìm `*sideplay*`/`*.deb`; kết quả **không có DEB**. Files: danh sách upload của cuộc chat hiện tại **0**, tìm file SidePlay/DEB trong Library **không thấy binary**; nhưng Library có báo cáo `/tiep tuc du an/phan_tich_SidePlay_1.0.4-1_cho_DuoFace.md` (9.463 byte), đã đọc. GitHub: đối chiếu đủ **5 nhánh** (`main`, `feature/visual12-duodash-recovery`, `feature/duoface-independent-core`, `feature/duoface-exact-payload-migration`, `duoface-carplay-standalone`), **không có đường dẫn tệp SidePlay DEB, ZIP/encoded copy hoặc source SidePlay** trong cây Git hiện tại. Không tìm thấy bản release GitHub có asset của SidePlay. Không suy ra tệp gốc bị xóa khỏi chat cũ, chỉ xác nhận **không truy xuất được byte từ môi trường hiện tại**.
- **Nguồn chính đã xác minh trên GitHub** (nhánh `feature/visual12-duodash-recovery`): `docs/sideplay-1.0.4-1-static-deb-audit-20261017.md`; `docs/doi-chieu-3-deb-duonavi-duodash-sideplay-20261017.md`; `docs/phuong-an-loi-carplay-doc-lap-sideplay-duodash-20261017.md`. Nguồn bổ sung: Library report nêu trên.
- Phân biệt bằng chứng: `HISTORICAL_STATIC` là kết quả do báo cáo ngày **17/10/2026** ghi lại từ DEB được upload; `CURRENT_VERIFIED` là file/chứng cứ đang trực tiếp truy cập và đối chiếu **18/10/2026**; `NEEDS_BINARY` là phần **chưa thể kiểm tra hoặc xác minh lại**.

## 1. Nhận diện package — HISTORICAL_STATIC

| Thuộc tính | Giá trị lịch sử đã ghi trong hai báo cáo độc lập |
|---|---|
| Original filename | `com.sideplay_1.0.4-1_iphoneos-arm64.deb` |
| Package | `com.sideplay` |
| Version | `1.0.4-1` |
| File size DEB | **4.352.576 byte** |
| SHA-256 của DEB | `7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c` |
| Arch / prefix | `iphoneos-arm64`, rootless, đường dẫn gói `var/jb/...` |
| Depends | `firmware (>=15.0), mobilesubstrate, preferenceloader` |
| Nội dung đã giải nén | **136 file** theo báo cáo 17/10 |
| Claim trong control | “Split screen for CarPlay. Run any app on the car screen, one or two side by side.” |
| Source code dạng .m/.mm/.h/.xm/.swift/.c/.cpp hoặc Xcode/Theos project | **Không có trong payload 136 file theo audit cũ** |
| Test trên iPhone/CarPlay | **Không có trong audit cũ, không có trong lượt này** |

Giá trị số ở trên **chưa được tính lại từ byte nguồn trong lượt này**. Không lấy `dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb` làm SidePlay — đó là DEB DuoNavi khác.

## 2. Phân lớp payload và kích thước từng lõi — HISTORICAL_STATIC

| Vai trò | Đường dẫn/tệp ghi trong báo cáo | Byte | Giới hạn |
|---|---|---:|---|
| Lõi tweak SpringBoard / scene host | `var/jb/Library/MobileSubstrate/DynamicLibraries/SidePlay.dylib` | **899088** | Mach-O arm64 `MH_DYLIB`; selector/strings đã quét, chưa trích disassembly hoặc class-by-class source ở lượt này |
| Vỏ ứng dụng CarPlay | `var/jb/Applications/SidePlay.app/SidePlay` | **178672** | CarPlay template scene; không coi là toàn bộ host engine |
| Giao diện Settings/log | `SidePlayPrefs.bundle/SidePlayPrefs` | **613648** | Prefix PreferenceBundles cần đọc đủ path từ binary mới |
| Relay / lifetime HUD | `SidePlayHUDRelay.dylib` | **240128** | Đếm ngược ngắt kết nối ~20 giây theo strings |
| Nguồn GOFA | `SidePlayHUDGofa.dylib` | **129936** | Hook app `com.lumi.GOFA` |
| Nguồn VietMap | `SidePlayHUDVietMap.dylib` | **162752** | Hook app `vn.vietmap.live` |
| Nguồn Waze | `SidePlayHUDWaze.dylib` | **145328** | Hook app `com.waze.iphone` |

Tổng kích thước bảy **binary được liệt kê** là **2.369.552 byte**, không phải tổng payload cài đặt, vì còn file plist/ảnh/settings/tài nguyên, chưa có inventory đầy đủ 136 đường dẫn. Gói nén 4.352.576 byte cũng không tương đương tổng kích thước uncompressed. **Không tự suy diễn số lượng file ảnh/logo, framework hoặc URL.**

### Injection filters

- `SidePlay.plist`: target `com.apple.springboard` và `com.apple.UIKit` (cần đọc lại chính xác cấu trúc filter của plist khi có gói).
- `SidePlayHUDRelay.plist`: SpringBoard.
- HUD GOFA: `com.lumi.GOFA`; HUD VietMap: `vn.vietmap.live`; HUD Waze: `com.waze.iphone`.
- Chuỗi trong core có `com.apple.CarPlayApp`, `com.apple.CarPlayTemplateUIHost` và `CarPlayIsConnectedDidChange`.
- Rủi ro: phạm vi injection & việc hai scene owner chạy song song chưa được thử, KHÔNG được tự cài SidePlay cạnh DuoFace để kết luận không xung đột.

## 3. Phân tích kiến trúc CarPlay và các chuỗi binary — HISTORICAL_STATIC

### 3.1. Detect / boot / CarPlay shell
- `CarPlayIsConnectedDidChange`, `currentCarPlayExternalDevice`, `initForCarPlayShell`.
- Chuỗi log: `CarPlay connection changed: %d`, `auto open on CarPlay (attempt %ld)`, `SidePlay shown again on CarPlay`.
- Giải thích có căn cứ: có xử lý sự kiện màn hình CarPlay và trạng thái reconnect/auto-open. **Không xác định từ strings đơn lẻ** chính xác trình tự callback, queue hoặc mọi tham số.

### 3.2. App selection / scene acquisition
- `SBApplicationController`: lớp tra ứng dụng SpringBoard.
- `SBDeviceApplicationSceneEntity`, `SBAppViewController`, `SBDeviceApplicationSceneView`: dấu hiệu tạo và nhúng scene app qua giao diện riêng của SpringBoard.
- `FBScene`, `FBSceneMonitor`, `FBSSceneSettings`, `FBSSceneParameters`, `UIApplicationSceneSettings`, `sceneHandle`: các lớp/handle thuộc scene management.
- Chuỗi log: `SBAppViewController init failed for %@`.
- Những tên này chứng tỏ **nhị phân có tham chiếu** đến đường scene-host, không chứng minh API nào chạy được trên từng build iOS 16 hoặc có thể copy mã 1:1.

### 3.3. Window / layout / multi-app
- `CPTemplateApplicationSceneDelegate`, `CPTemplateApplicationScene`, `CPInterfaceController`, `CPWindow`: xuất hiện trong `SidePlay.app`.
- Log: `SidePlay opened on %@, window %@, canvas %@`, `geometry update refused: %@`, `quit %lu app(s) opened in SidePlay`.
- `initWithSplit:apps:` và `split` được báo cáo trong core; gợi ý có cấu hình hai app. **Chưa biết** thuật toán ratio, min/max, touch delegation, attach timing, display coordinate space và exact class ownership.
- **Cần binary** để xác định Objective-C class/method implementation, disassembly & call graph cho create → attach → resize → swap → focus → close.

### 3.4. Teardown / foreground / reconnect
- Audit cũ nhận thấy chuỗi về app termination, reconnect và giữ app trên CarPlay khi đổi foreground.
- `SidePlayHUDRelay` có 20-second disconnect countdown; **không suy ra** core CarPlay cũng dùng đúng timer ấy cho scene teardown.
- **Thiếu** crash logs, Instruments, timeline và thử respring; chưa khẳng định SidePlay sẽ giải quyết được exitmode DuoFace.

## 4. Bộ HUD — HISTORICAL_STATIC

- GOFA, VietMap, Waze là các hook mục tiêu cụ thể. `SidePlayHUDWaze.dylib` có `WazeLocationManager`, `MSHookMessageEx` và strings cảnh báo tương thích phiên bản.
- Relay SpringBoard tách khỏi hook bên app nguồn; hướng điều tra bắt buộc là source hook → IPC/relay → UI owner → lifecycle. **Chưa xác định protocol thật, notification keys, data schema, độ mới dữ liệu hay chính xác cách HUD được vẽ**.
- Có `LICENSE-GMapHUD` theo giấy phép MIT **chỉ dành cho thành phần GMapHUD**, không chứng minh tất cả thư viện SidePlay được cấp phép như vậy.
- Các tên `trial` liên quan Waze/GOFA trong strings không đủ chứng minh chính sách giấy phép sản phẩm.

## 5. Cài đặt, phụ thuộc, gỡ bỏ — HISTORICAL_STATIC

- Depends: iOS firmware >=15.0, `mobilesubstrate`, `preferenceloader`, rootless arm64.
- Conflicts: `com.cortex.carplayenable`, `com.pavunato.carsurf`, `com.bmt.dash`, `com.chou.googlemaps.vietmap`. Không thấy DuoFace trong Conflicts; **không** suy ra chạy song song an toàn.
- `postinst` theo báo cáo chạy `uicache -p` cho SidePlay.app; `prerm` chạy `SidePlay --sp-goodbye` để thông báo server khi gỡ và `uicache -u`. Scripts **đã đọc nhưng không thực thi** vào ngày 17/10. Khi kiểm lại tuyệt đối không chạy maintainer scripts hoặc cài package chỉ để đọc tĩnh.
- Chưa có danh sách đầy đủ các architecture slice, LC_LOAD_DYLIB, symbols, entitlements, ký số, file mode, symlink, launchd agents, sandbox, URL schema, app Info.plist, image dimensions; để trạng thái **NEEDS_BINARY**.

## 6. Ranh giới giấy phép, quyền sử dụng và độc lập

- Báo cáo 17/10 quét không thấy `CBLicenseSyncManager`, `CBBridgeManager` hoặc plain `license` trong **SidePlay.dylib**. Đây là bằng chứng **absence of selected strings**; **không** phải chứng nhận SidePlay không có licence/trial hoặc server dependency.
- Uninstall `--sp-goodbye` ghi nhận khả năng liên lạc server. Không khẳng định có activation/licensing server chỉ từ đường uninstall.
- Không có mã nguồn SidePlay hoặc licence cấp phép toàn bộ project trong DEB audit; **không sao chép, đóng gói lại hoặc đổi tên các binary/hook thương mại này** vào DuoFace. Dự án mới phải tự viết phần core, chỉ nghiên cứu mô hình và API hợp lệ.
- Binary SidePlay, DuoNavi `com.duonavi.app_1.0.4`, DuoDash và QA MyTweak là các đối tượng **khác nhau**; không thể lấy DEB của một dự án thay cho file bị thiếu.
- Quyết định người dùng ngày 18/10: **chuyển nền nghiên cứu SidePlay từ đầu**, chỉ lấy UI DuoFace Native12/Visual12/HUD8, không tiếp tục vá lõi DuoNavi hay host QA.

## 7. Những việc để có một bản quét CHI TIẾT THỰC SỰ — NEEDS_BINARY

Ngay khi tìm lại **chính byte DEB** đã upload, phải làm từng bước và lưu raw outputs vào `sideplay/audit/` (không thay đổi DEB gốc):

1. **Identity**: `stat`, `file`, `sha256sum`; so SHA-256 với `7f8520...`; nếu lệch thì đánh dấu khác phiên bản/bản repack, không trộn dữ liệu.
2. **DEB envelope**: `ar t`, `dpkg-deb -I`, `dpkg-deb -c`, `dpkg-deb -f`, kiểm tar/control/archive & compression; lưu control, md5sums, conffiles, postinst/prerm/postrm/triggers **không thực thi**.
3. **Full manifest 136/136**: mọi path, type, mode, uid/gid, symlink target, uncompressed size, SHA256 từng file, tổng size, hash/checksum đối chiếu; nếu khác 136 phải nêu nguyên nhân.
4. **Mọi Mach-O**: slices, `file`, `llvm-objdump --macho --private-headers` hoặc `otool -l`, load commands/LC_LOAD_DYLIB/LC_RPATH, ObjC classes/protocols/categories/selectors, exports/imports/bind symbols, từng dylib/framework external, `__TEXT/__DATA` references, code signatures/entitlements; so từng binary với matching plist filters.
5. **CarPlay graph**: trace detect → request → CPTemplate shell → SpringBoard owner → SBApplicationController → scene entity → SBAppViewController → FBScene attach → geometry update → touch/focus → detach/terminate → disconnect/reconnect. Phân biệt strings hiện diện với call graph disassembly chứng minh đường gọi; chưa thể biết toàn bộ logic từ tên selector.
6. **UI/assets**: đầy đủ storyboard/nib/plist/PNG/PDF/strings/settings, kích thước pixel, color palette, zoom/divider/menu/split ratio, tất cả localized strings, HUD assets; đối chiếu UI DuoFace Visual12/Native12 theo asset inventory.
7. **Security/privacy**: mọi domain/URL/IPC/XPC/Darwin notification (có context tránh false-positive), background jobs, logs/device IDs, outbound uninstall call; không chạy chương trình.
8. **Runtime test sau static**: chỉ trên máy thật và khi được phép cài bản phân lập; scene attach một app rồi hai, touch/swap/ratio, CarPlay disconnect, foreground, respring, SpringBoard crash/exitmode, rollback. Không gọi static pass là runtime pass.
9. **Preservation**: upload **bản gốc bất biến** hoặc bản lưu lossless có SHA256/checkpoint trong repo đúng dự án theo quyền và giới hạn kích thước; lưu báo cáo, raw evidence, script reproducer vào `sideplay/`. Giữ nguyên Sileo/Native12/Visual12/Hub8.

### Lệnh tái thực hiện căn bản (CHƯA CHẠY trong lượt này vì thiếu DEB)

```bash
DEB=com.sideplay_1.0.4-1_iphoneos-arm64.deb
sha256sum "$DEB"
file "$DEB"
ar t "$DEB"
dpkg-deb -I "$DEB"
dpkg-deb -c "$DEB"
mkdir -p sideplay_extract/{payload,control}
dpkg-deb -x "$DEB" sideplay_extract/payload
dpkg-deb -e "$DEB" sideplay_extract/control
find sideplay_extract/payload -type f -print0 | sort -z | xargs -0 sha256sum
find sideplay_extract/payload -type f -print0 | xargs -0 file
```

**Không chạy `dpkg -i`, `postinst`, `prerm` trên máy phân tích.** Các kiểm tra Mach-O/entitlements phải chạy cho từng binary thật sau khi có file.

## 8. Kết luận quyết định kỹ thuật

- **Tìm thấy báo cáo gốc** và xác nhận lần 17/10 đã có cuộc quét tĩnh bằng byte DEB user upload: 136 files, bảy binary trọng tâm, filters và các lớp scene host nêu trên.
- **Không tìm được DEB truy xuất được trong lượt 18/10** nên chưa làm được bản kiểm tra toàn diện 136/136, call graph, hex/ObjC extraction hoặc đối chiếu checksum mới.
- Điểm kỹ thuật đáng ưu tiên khi có file: lõi `SidePlay.dylib` (SpringBoard + scene host), `SidePlay.app` (CPTemplate shell), `HUDRelay`/app hooks (tách riêng); từ đó tự viết core DuoFace độc lập. Không mặc nhiên nhập core SidePlay thương mại vào gói mới.
- **BLOCKER chính xác**: thiếu đúng binary `com.sideplay_1.0.4-1_iphoneos-arm64.deb` có SHA-256 lịch sử bên trên. Không tuyên bố hoàn tất forensic scan cho tới khi có byte và evidence xuất ra.
