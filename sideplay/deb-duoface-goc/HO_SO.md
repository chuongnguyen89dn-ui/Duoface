# HỒ SƠ GÓC — GÓI DuoFace/DuoNavi "1.0.4-1" (payload DuoFaceUI)

> Hồ sơ tra cứu tĩnh, lập ngày 2026-11-05. Mục đích: bản gốc đối chiếu cho mọi bản DuoFace/DuoNavi về sau, để không phải quét lại.
> Phương pháp: PHÂN TÍCH TĨNH CHỈ-ĐỌC (parse Mach-O/ObjC metadata, strings, disassembly). Không binary/script nào trong gói được thực thi. Không file nguồn nào bị sửa.

Mức bằng chứng dùng trong hồ sơ:
- **[A]** = đọc trực tiếp từ metadata/disassembly của chính binary (load commands, bảng ObjC, điểm gọi hàm đã dịch ngược).
- **[B]** = suy ra từ chuỗi (strings) + symbol import/export + tên hàm — nhất quán nhiều nguồn trong gói nhưng không có điểm gọi đã dịch ngược xác nhận.
- **[C]** = suy luận cơ chế từ tổng hợp [A]/[B]; ghi rõ là suy luận.

## 1. Định danh gói — và giới hạn định danh

### 1.1 Nguồn dữ liệu của hồ sơ này

- **Payload chính (nguồn [A] cho toàn bộ hồ sơ):** cây rootfs đã bóc sẵn tại `~/workspace/duoface-audit/sweep-original/rootfs/` — đây là nội dung của `data.tar` của gói. Kèm `dashboard_strings.txt` cùng thư mục (khớp 1:1 với strings trích mới từ `DuoFaceDashboard.dylib`: cùng 40.671 dòng).
- **File .deb gốc: ĐÃ MẤT.** Không còn file .deb trên máy → **không có SHA256 của .deb, không có `control.tar` đi kèm rootfs này** (thư mục DEBIAN không tồn tại trong rootfs).
- **Đối chiếu từ repo GitHub** (`chuongnguyen89dn-ui/Duoface`, nhánh `spec-main`, chỉ đọc): `sideplay/extracted-1.0.4-1/` (README + `control/`) và `sideplay/audit/deb-1.0.4-1/`.

### 1.2 CẢNH BÁO ĐỊNH DANH — metadata "1.0.4-1" trong repo KHÔNG thuộc payload này

Control duy nhất mang version `1.0.4-1` tìm được trong repo thuộc về một gói **khác hẳn**:

| Trường | Giá trị trong repo (extracted-1.0.4-1/control/control) |
|---|---|
| Package | `com.sideplay` |
| Name | SidePlay |
| Version | 1.0.4-1 |
| Architecture | iphoneos-arm64 |
| Depends | firmware (>= 15.0), mobilesubstrate, preferenceloader |
| Conflicts | com.cortex.carplayenable, com.pavunato.carsurf, com.bmt.dash, com.chou.googlemaps.vietmap |
| Maintainer / Author | SidePlay / SidePlay |
| Section | Tweaks |
| Installed-Size | 7196 |
| Description | Split screen for CarPlay. Run any app on the car screen, one or two side by side. |

Payload của gói `com.sideplay` đó (theo `sideplay/audit/deb-1.0.4-1/SHA256SUMS.txt`, SHA256 của chính file deb SidePlay là `7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c`) gồm `SidePlay.app`, `SidePlay.dylib`, các dylib HUD (`SidePlayHUDGofa/Waze/VietMap/Relay`), `SidePlayPrefs.bundle` — **không có file nào trùng với rootfs DuoFace của hồ sơ này**. SHA256 của mọi file nhị phân trong rootfs DuoFace (mục 1.3) đều **không xuất hiện** trong SHA256SUMS của gói SidePlay.

Hệ quả — những gì KHÔNG xác nhận được cho payload DuoFace này:
- **Package ID, Version, Depends, Maintainer của gói DuoFace chứa payload này: CHƯA XÁC ĐỊNH ĐƯỢC** từ dữ liệu hiện có. Nhãn "1.0.4-1" trong tên hồ sơ là nhãn do chủ dự án gán khi giao việc, không có bằng chứng trong payload (app trong payload tự khai version `1.0.0`, xem Info.plist mục 9.1; một chuỗi hiển thị trong app ghi `1.0.3 (DuoFace Commercial Pro Edition)` [B]).
- Thư mục audit `sideplay/audit/deb-1.0.4-1/` trong repo bị **trộn nhiều nguồn**: `control-fields.txt`/`SHA256SUMS.txt` là của gói SidePlay; `package-info.txt` lại liệt kê bộ binary thứ ba (`CBridgeManager.dylib`, `CBSceneHost.dylib`, executable `SidePlay`); còn `plists-decoded.json` trong cùng thư mục lại chứa đúng các plist của payload DuoFace trong hồ sơ này. Không dùng thư mục audit đó làm chuẩn định danh được.

Những gì payload tự xác nhận được [A]:
- App: bundle `com.duoface.duofaceui`, tên hiển thị **DuoFace**, executable `DuoFaceUI`, version app `1.0.0` (Info.plist, mục 9.1).
- Hai "đợt build" khác nhau trong cùng payload (xem mục 3): đợt `d0920c2e` (DuoFaceUI + DuoFaceDashboard + cboptimize_helper; SDK iOS 16.5) và đợt `804c181c` (DuoFaceFullscreenBridge; SDK iOS 18.5). DuoFaceVisualHook không mang chuỗi build-tag nhưng cùng thông số SDK 18.5 như Bridge.

### 1.3 SHA256 của từng file nhị phân trong rootfs (thay cho SHA của .deb đã mất)

| File | Kích thước (byte) | SHA256 |
|---|---:|---|
| `var/jb/Applications/DuoFaceUI.app/DuoFaceUI` | 2,456,784 | `3d0f8eac292d2c22d7a773e520ff396d33498a4a14bf6e0f72eb62ccc9c174e3` |
| `var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib` | 7,540,464 | `bc1df854ec7a2ddfeec4cb81b080ead34b54df80143d4a8f6254bb8b618003ce` |
| `var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib` | 107,744 | `cdb7f4f6c1a7e3db63c22f6e4551423d4a193a66c4708a549e2045a2d1d40088` |
| `var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.dylib` | 75,536 | `4ebf68b630c102dee1bbaac87dcadddd3e13f618331cacd9c47ae1a27437959d` |
| `var/jb/usr/bin/duoface-cboptimize` | 3,364 | `73b19cdafe1624f089d54ae06aa0f00b1545ca5f11fd62fc6e69dcf44417eb46` |
| `var/jb/usr/libexec/duoface_cboptimize_helper` | 150,528 | `bd77f7594b649b722d71094f5a1d650d2bb9541a0827e12e21254d82f4a93906` |

SHA256 của **toàn bộ 37 file** có trong bảng cây file ở mục 2.

## 2. Cây file 100% của rootfs

Rootfs gồm đúng **37 file thường, 0 symlink**. Không có thư mục `DEBIAN/` (control/prerm/postinst của gói này không nằm trong bản bóc), không có PreferenceLoader entry, không có LaunchDaemon.

| # | Đường dẫn (gốc /) | Byte | Mode | SHA256 |
|---:|---|---:|---|---|
| 1 | `/var/jb/Applications/DuoFaceUI.app/AppIcon29x29.png` | 1,625 | -rw-r--r-- | `71debbd1ec86ddc0f81ec912b81270cd015e0cbc72b21ba4657d7a89a65c9b66` |
| 2 | `/var/jb/Applications/DuoFaceUI.app/AppIcon29x29@2x.png` | 4,927 | -rw-r--r-- | `7cd2974d10f2ec892957a0e5995f43e81ba0d73efe701d45719765cc57de77cf` |
| 3 | `/var/jb/Applications/DuoFaceUI.app/AppIcon29x29@3x.png` | 9,504 | -rw-r--r-- | `444a05ca1cf748cfd7440fa390e758d3a2e9e365701d3c9787374ae055171295` |
| 4 | `/var/jb/Applications/DuoFaceUI.app/AppIcon40x40.png` | 2,650 | -rw-r--r-- | `9934e080e8d4fe2c7c1ee5feda7f3d1b0ceeabf8dd65834d03fa0baadd49d1ed` |
| 5 | `/var/jb/Applications/DuoFaceUI.app/AppIcon40x40@2x.png` | 8,309 | -rw-r--r-- | `9ab7dc6d37efbed691648cf545ffd490125e24d1a78a3f11043b167c780f5ff6` |
| 6 | `/var/jb/Applications/DuoFaceUI.app/AppIcon40x40@3x.png` | 16,021 | -rw-r--r-- | `ca2e7402c268eb08ecb031b24bce4fd8c9bfde7c169431f7aa860070e6964e7d` |
| 7 | `/var/jb/Applications/DuoFaceUI.app/AppIcon50x50.png` | 3,845 | -rw-r--r-- | `a3d6c1fb86f75aab76dda4dd51368ab903f23cd98be1522edab6a684d23ff420` |
| 8 | `/var/jb/Applications/DuoFaceUI.app/AppIcon50x50@2x.png` | 11,898 | -rw-r--r-- | `a0b2483b684eec28c813a0ba13bf25700c240681905cfd26e86320c96f7a063c` |
| 9 | `/var/jb/Applications/DuoFaceUI.app/AppIcon57x57.png` | 4,818 | -rw-r--r-- | `02954587d7cff643f4805a79df90da4c5d5a4eb7ab5026eb71698b42af85ee52` |
| 10 | `/var/jb/Applications/DuoFaceUI.app/AppIcon57x57@2x.png` | 14,778 | -rw-r--r-- | `a6ef5deaa71c36aaea9e2646f1b9759f62b792a6a0ff3b9720bda88258aecacd` |
| 11 | `/var/jb/Applications/DuoFaceUI.app/AppIcon57x57@3x.png` | 28,859 | -rw-r--r-- | `5d796161858e6dc07bf90283f1528149a5be01437ed242095cb3af3ebc2425bf` |
| 12 | `/var/jb/Applications/DuoFaceUI.app/AppIcon60x60.png` | 5,185 | -rw-r--r-- | `e0cd867606e62b90c9dc9962520ca1d760b47ba7dd9593505f826e757625cb11` |
| 13 | `/var/jb/Applications/DuoFaceUI.app/AppIcon60x60@2x.png` | 16,021 | -rw-r--r-- | `ca2e7402c268eb08ecb031b24bce4fd8c9bfde7c169431f7aa860070e6964e7d` |
| 14 | `/var/jb/Applications/DuoFaceUI.app/AppIcon60x60@3x.png` | 31,467 | -rw-r--r-- | `6cf13a7c3e5aac30d0232a53b8388ae6623b43259afd125ef88e2ff509604d12` |
| 15 | `/var/jb/Applications/DuoFaceUI.app/AppIcon72x72.png` | 7,026 | -rw-r--r-- | `0480a1a0adbc74d7e3272c82e7b0f8fe86352b44c99e7c151aea76eaa085f3ac` |
| 16 | `/var/jb/Applications/DuoFaceUI.app/AppIcon72x72@2x.png` | 21,616 | -rw-r--r-- | `ca01ebbfc396c8f6e1ebffa03c80df4714fc099c6decce0e49ab58eafe3a79a5` |
| 17 | `/var/jb/Applications/DuoFaceUI.app/AppIcon76x76.png` | 7,628 | -rw-r--r-- | `df2a07dc88e81ed07a33fc51161510d1404fc59df0e5231cc7c7e94ac261371c` |
| 18 | `/var/jb/Applications/DuoFaceUI.app/AppIcon76x76@2x.png` | 23,597 | -rw-r--r-- | `3e875d60e256732dbbc2774ed88cbce098fdf81d684e9724d7bbe7c6b17dc3a8` |
| 19 | `/var/jb/Applications/DuoFaceUI.app/DuoFaceUI` | 2,456,784 | -rwxr-xr-x | `3d0f8eac292d2c22d7a773e520ff396d33498a4a14bf6e0f72eb62ccc9c174e3` |
| 20 | `/var/jb/Applications/DuoFaceUI.app/Info.plist` | 2,303 | -rw-r--r-- | `d34a7d08c593dd2ee29b0fbe79d51b369253a8728282b1fff2b757302b7a5e67` |
| 21 | `/var/jb/Library/Application Support/DuoFace/VisualAssets/duoface-fullscreen.png` | 6,400 | -rw-r--r-- | `10e52f01a16cb7d34a81330373a290bcac1bdb0ba9c91119527ef3dcb13cdb36` |
| 22 | `/var/jb/Library/Application Support/DuoFace/VisualAssets/duoface-picker.png` | 15,225 | -rw-r--r-- | `16a959b71a0d3d8ef86e2ac9163024af457aec180770c757fe4b16d2b0a85f8a` |
| 23 | `/var/jb/Library/Application Support/DuoFace/VisualAssets/duoface-swap.png` | 22,085 | -rw-r--r-- | `d3ec77c783a186896d63bb08732ee78e427f16e1c127c0785b36bf5eaa037275` |
| 24 | `/var/jb/Library/Application Support/DuoFace/asset-manifest.json` | 1,998 | -rw-r--r-- | `5b5eaf4958ae7e2898c69f2b2dc95672aecb08d6ca5952d13df513c56d7ede29` |
| 25 | `/var/jb/Library/Application Support/DuoFace/duoface-icon.png` | 64,297 | -rw-r--r-- | `03f0a9e31bffced19419f06193d866bb2d66d824c5ba10c5c24eee8718217def` |
| 26 | `/var/jb/Library/Application Support/DuoFace/duoface-logo-vert.png` | 378,795 | -rw-r--r-- | `7fa216e2fa89e4fc32e49045ab29d72f6bee3fef4f974444c98fb5bd631e25d2` |
| 27 | `/var/jb/Library/Application Support/DuoFace/duoface-logo.png` | 147,482 | -rw-r--r-- | `78450d8ee4759353bdc21f27a06016c03fab61038ae60109ba21515c087b0089` |
| 28 | `/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib` | 7,540,464 | -rwxr-xr-x | `bc1df854ec7a2ddfeec4cb81b080ead34b54df80143d4a8f6254bb8b618003ce` |
| 29 | `/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.plist` | 1,446 | -rw-r--r-- | `584038db14fd6d61b7e56e096b6ca2f020dd8b4f97fb5485ee72763d817fcd10` |
| 30 | `/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib` | 107,744 | -rwxr-xr-x | `cdb7f4f6c1a7e3db63c22f6e4551423d4a193a66c4708a549e2045a2d1d40088` |
| 31 | `/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.plist` | 594 | -rw-r--r-- | `d0d7082b78fb83dc15d0a02cb6e247486d982d9870871e698c2a64b70c1bf2af` |
| 32 | `/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.dylib` | 75,536 | -rwxr-xr-x | `4ebf68b630c102dee1bbaac87dcadddd3e13f618331cacd9c47ae1a27437959d` |
| 33 | `/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.plist` | 511 | -rw-r--r-- | `9b3e9dc8b5e1d195b5b0fe0a6c6f12104a17683273582408c8a398f1a8529966` |
| 34 | `/var/jb/etc/sudoers.d/duoface` | 28 | -rw-r--r-- | `72fd64f87a8564969df22bedc7c2e36e46776b3ad6bc4d2014f4b8029599ac5a` |
| 35 | `/var/jb/usr/bin/duoface-cboptimize` | 3,364 | -rwxr-xr-x | `73b19cdafe1624f089d54ae06aa0f00b1545ca5f11fd62fc6e69dcf44417eb46` |
| 36 | `/var/jb/usr/libexec/duoface_cboptimize_helper` | 150,528 | -rwxr-xr-x | `bd77f7594b649b722d71094f5a1d650d2bb9541a0827e12e21254d82f4a93906` |
| 37 | `/var/mobile/Library/Preferences/com.duonavi.sync.plist` | 531 | -rw-r--r-- | `8029b953c8de4f280e664063741b7909d48d615c2bd84d861b3800c931db2a20` |

Ghi chú về nội dung ngoài nhị phân:
- `var/jb/etc/sudoers.d/duoface` (28 byte, mode 644): nội dung đúng một dòng `ALL ALL=(ALL) NOPASSWD: ALL` — cấp sudo không mật khẩu cho mọi user/lệnh [A, đọc trực tiếp].
- `var/mobile/Library/Preferences/com.duonavi.sync.plist` nằm **ngay trong payload** — tức gói cài sẵn một file trạng thái đồng bộ license xuống máy (chi tiết mục 9.3).
- `asset-manifest.json` ghi nguồn gốc bộ ảnh giao diện (zip `DuoFace_5_images_REVIEW_before_upload.zip`) kèm SHA256 + kích thước pixel của từng ảnh output — các SHA trong manifest khớp SHA thực của file trong rootfs [A, đã đối chiếu 3/3 VisualAssets + icon].

## 3. Từng file nhị phân — thông số Mach-O, chữ ký, điểm nạp

Điểm chung cho cả 5 binary Mach-O [A]:
- `LC_ENCRYPTION_INFO_64` với **cryptid = 0** ở mọi slice → không mã hoá FairPlay, đọc tĩnh trực tiếp được.
- Chữ ký số kiểu **ldid ad-hoc**: superblob chỉ có blob requirements/designated-requirement; **không có blob entitlements** (không tồn tại blob magic `0xfade7171`) ở bất kỳ binary nào → các binary **không nhúng entitlements**. Mọi đặc quyền thực tế đến từ việc chạy trong tiến trình host (SpringBoard/CarPlay) và file sudoers đi kèm.
- RPATH giống nhau: `/var/jb/Library/Frameworks`, `/var/jb/usr/lib`, `@loader_path/.jbroot/Library/Frameworks`, `@loader_path/.jbroot/usr/lib` (rootless + jbroot).
- Install name của cả 3 dylib: `@rpath/<TênDylib>.dylib`.

### 3.1 DuoFaceUI (executable của app)

- Đường dẫn: `/var/jb/Applications/DuoFaceUI.app/DuoFaceUI` — 2.456.784 byte; FAT 2 slice: arm64 (offset 16384, 1.214.224 byte, UUID `9d789c67-bf82-3c8f-8127-17d1ae50e08e`), arm64e (offset 1245184, 1.211.600 byte, UUID `d35a8ee9-720f-3585-a194-b41d09c596d6`). PIE, `LC_MAIN` entryoff 0x7294 (arm64).
- LC_BUILD_VERSION: platform iOS, **min iOS 15.0, SDK 16.5**; build tag trong strings: `DuoFaceUI.d0920c2e.unsigned` [B].
- Thư viện liên kết (arm64 và arm64e giống nhau): libobjc.A, Foundation (1971.0.0), CoreFoundation (1971.0.0), UIKit (6441.1.101), CoreGraphics, QuartzCore, Security (60420.102.1), IOKit, SafariServices, MobileCoreServices, CoreServices, libSystem.B (1319.100.3). **Không** liên kết CydiaSubstrate (đây là app, không phải tweak).
- Điểm nạp: `main` chuẩn của app iOS (`_main` là symbol defined duy nhất dạng code ngoài các class); không có `__mod_init_func`/`__init_offsets`.
- Filter: không áp dụng (app chạy độc lập, bundle `com.duoface.duofaceui`).

### 3.2 DuoFaceDashboard.dylib (dylib lõi)

- Đường dẫn: `/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib` — 7.540.464 byte; FAT 2 slice: arm64 (offset 16384, 3.741.760 byte, UUID `e585ce1c-acc6-3e74-b017-d760ffc77c02`), arm64e (offset 3768320, 3.772.144 byte, UUID `1f83d158-6c9f-3789-8eb7-dbb394b89f9c`). Build tag `DuoFaceDashboard.dylib.d0920c2e.unsigned`; min iOS 15.0, SDK 16.5.
- Thư viện liên kết: libobjc.A, Foundation, CoreFoundation, UIKit, CoreGraphics, IOKit, Security, AVFoundation, QuartzCore, **libsqlite3**, PrivateFrameworks **AppSupport**, **BackBoardServices**, AVFAudio, **@rpath/CydiaSubstrate.framework/CydiaSubstrate**; Speech.framework liên kết **weak**. (Cùng danh sách cho cả 2 slice.)
- **Symbol table bất thường [A]:** slice arm64 có 295 symbol và **toàn bộ là undefined (import)** — symtab **không chứa một defined symbol nào** (kể cả symbol class ObjC). Mọi class chỉ khám phá được qua `__objc_classlist`; mọi hàm C đều là static/stripped. Đối chiếu: Bridge còn giữ 23 defined symbol, VisualHook giữ 121, DuoFaceUI giữ 78.
- Điểm nạp [A]: `__mod_init_func` (arm64) có **2 initializer**: `0x6258` (initializer nhỏ, có dispatch_once + NSLog — khởi tạo singleton/dữ liệu tĩnh) và **`0x2a803c` (constructor chính kiểu Logos `%ctor`** — toàn bộ 243 điểm gọi hook nằm trong vùng thân hàm bắt đầu từ đây, mục 6.1). Slice arm64e có `__init_offsets` tương ứng 2 initializer tại 0x62f0 / 0x2aeff0.
- Filter (`DuoFaceDashboard.plist`, mục 9.2): nạp vào **23 bundle** — CarPlayApp, CarPlay, dashboard, springboard/SpringBoard, YouTube, YouTube Music, Netflix, VLC, MobileSafari, Twitch, TikTok (com.zhiliaoapp.musically), Google Maps, Waze, Spotify, Preferences, Notes, Phone, Music, Chrome, BarcodeScanner, Print Center, và chính `com.duoface.duofaceui`.

### 3.3 DuoFaceFullscreenBridge.dylib (cầu fullscreen)

- Đường dẫn: `/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib` — 107.744 byte; **chỉ 1 slice arm64** (thin), UUID `73d4c0fd-2723-3e01-b4aa-cd7e6668100b`. Build tag `DuoFaceFullscreenBridge.dylib.804c181c.unsigned`; **min iOS 14.0, SDK 18.5** (đợt build sau, cùng đợt VisualHook). Dùng dyld chained fixups (imports_format 1, 80 imports).
- Thư viện liên kết: libobjc.A, Foundation (3502.0.0), CoreFoundation (3502.0.0), UIKit (8506.1.101), **libc++.1** (có mã C++), libSystem.B (1351.0.0), CoreGraphics, @rpath/CydiaSubstrate.framework/CydiaSubstrate.
- Điểm nạp [A]: `__init_offsets` — 1 initializer tại `0x4000`.
- Filter (`DuoFaceFullscreenBridge.plist`): Bundles = CarPlayApp, CarPlay, dashboard, springboard; Executables = CarPlay, CarPlayApp, Dashboard, SpringBoard (chỉ tiến trình hệ thống CarPlay/SpringBoard — **không** nạp vào app thứ ba).
- Export 14 hàm C `DF*` (mục 5.3) làm API công khai — nhưng **không binary nào trong gói import các hàm này** (đã kiểm tra bảng import của cả 4 binary còn lại): Bridge phối hợp với Dashboard qua Darwin notification, không qua liên kết tĩnh [A].

### 3.4 DuoFaceVisualHook.dylib (hook thị giác)

- Đường dẫn: `/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.dylib` — 75.536 byte; 1 slice arm64 (thin), UUID `3732552b-441e-34f4-ab72-c70568ce673c`; min iOS 15.0, **SDK 18.5**; chained fixups (51 imports).
- Thư viện liên kết: UIKit (8506.1.101), Foundation (3502.0.0), QuartzCore, CoreGraphics, libSystem.B (1351.0.0), CoreFoundation, libobjc.A. **Không liên kết CydiaSubstrate** — nó tự `dlopen` libsubstrate lúc chạy (mục 6.3) [A].
- Điểm nạp [A]: `__init_offsets` — 1 initializer tại `0x4000`, chính là hàm có symbol `_DFInit`.
- Filter (`DuoFaceVisualHook.plist`): Bundles = CarPlayApp, CarPlay, dashboard, springboard, SpringBoard, `com.duoface.duofaceui` (chỉ hệ thống + app DuoFace — nơi các view `CB*` của Dashboard tồn tại).
- Không định nghĩa class ObjC nào (`__objc_classlist` không tồn tại); toàn bộ logic là hàm C `DF*` có symbol đầy đủ (mục 5.4).

### 3.5 duoface_cboptimize_helper (helper dòng lệnh)

- Đường dẫn: `/var/jb/usr/libexec/duoface_cboptimize_helper` — 150.528 byte; FAT arm64 (UUID `08150583-fe7a-38d8-b7d6-bea87ecf801f`) + arm64e (UUID `5ba5e15b-fda8-34ab-a9e8-b1234ddd689a`); min iOS 15.0, SDK 16.5 (đợt `d0920c2e`, chuỗi tag `cboptimize_helper.d0920c2e.unsigned` nằm trong vùng chữ ký).
- Thuần C: không ObjC (không section ObjC nào), chỉ liên kết CoreFoundation, IOKit, Security, libSystem.B. Symbol defined duy nhất: `_main`.
- Import đáng chú ý [A]: `IORegistryEntryCreateCFProperty`, `IOServiceGetMatchingService`, `IOServiceMatching`, `sysctlbyname`, `posix_spawn`, `setuid`, `setgid`, `waitpid`, `access`, `vm_read_overwrite`.

### 3.6 duoface-cboptimize (script shell)

- Đường dẫn: `/var/jb/usr/bin/duoface-cboptimize` — 3.364 byte, **shell script POSIX** (`#!/bin/sh`), SHA256 ở mục 1.3. Nội dung đầy đủ được tóm ở mục 9.4 (đây là file văn bản, đọc trực tiếp [A]).

## 4. Bảng class / method / property / ivar đầy đủ (metadata ObjC, slice arm64)

Đọc trực tiếp từ `__objc_classlist`/`class_ro_t` bằng parser tự viết (điểm kiểm chứng: parser cho ra đúng 75 method của `CBBridgeManager`, khớp con số đã biết từ các vòng audit trước). IMP là địa chỉ ảo trong slice arm64. Slice arm64e: danh sách class **trùng 100%** với arm64 ở cả DuoFaceUI (27) và Dashboard (36) — đã đối chiếu; bảng method của arm64e không giải độc lập (xem mục 10).

### 4.1 DuoFaceUI — 27 class, 522 method, 16 protocol

#### XXAppDelegate
- Superclass: `UIResponder` · địa chỉ class struct (arm64): `0x10011be80` · instanceSize: 24 · flags: `0x184`
- Protocols: `UIApplicationDelegate`
- Ivars (2):
  - `_window` — type `@"UIWindow"` — offset 8
  - `_rootViewController` — type `@"UIViewController"` — offset 16
- Properties (6):
  - `window` — attributes `T@"UIWindow",&,N,V_window`
  - `rootViewController` — attributes `T@"UIViewController",&,N,V_rootViewController`
  - `hash` — attributes `TQ,R`
  - `superclass` — attributes `T#,R`
  - `description` — attributes `T@"NSString",R,C`
  - `debugDescription` — attributes `T@"NSString",R,C`
- Instance methods (6):
  - - `application:didFinishLaunchingWithOptions:` — types `B32@0:8@16@24` — IMP `0x100007314`
  - - `window` — types `@16@0:8` — IMP `0x100007644`
  - - `setWindow:` — types `v24@0:8@16` — IMP `0x100007654`
  - - `rootViewController` — types `@16@0:8` — IMP `0x100007668`
  - - `setRootViewController:` — types `v24@0:8@16` — IMP `0x100007678`
  - - `.cxx_destruct` — types `v16@0:8` — IMP `0x10000768c`

#### XXRootViewController
- Superclass: `UITabBarController` · địa chỉ class struct (arm64): `0x10011bea8` · instanceSize: 40 · flags: `0x184`
- Ivars (4):
  - `_isShowingExpiredModal` — type `B` — offset 8
  - `_appsNav` — type `@"UINavigationController"` — offset 16
  - `_splitNav` — type `@"UINavigationController"` — offset 24
  - `_settingsNav` — type `@"UINavigationController"` — offset 32
- Properties (4):
  - `appsNav` — attributes `T@"UINavigationController",&,N,V_appsNav`
  - `splitNav` — attributes `T@"UINavigationController",&,N,V_splitNav`
  - `settingsNav` — attributes `T@"UINavigationController",&,N,V_settingsNav`
  - `isShowingExpiredModal` — attributes `TB,N,V_isShowingExpiredModal`
- Instance methods (17):
  - - `viewDidLoad` — types `v16@0:8` — IMP `0x10000784c`
  - - `viewDidAppear:` — types `v20@0:8B16` — IMP `0x100007e58`
  - - `dealloc` — types `v16@0:8` — IMP `0x100007ff0`
  - - `handleAppsUpdated` — types `v16@0:8` — IMP `0x100008068`
  - - `handleLanguageChanged` — types `v16@0:8` — IMP `0x1000080e0`
  - - `handleAppDidBecomeActive` — types `v16@0:8` — IMP `0x1000082e0`
  - - `checkAndPresentLicenseModalIfNeeded` — types `v16@0:8` — IMP `0x100008348`
  - - `updateBadge` — types `v16@0:8` — IMP `0x100008aec`
  - - `appsNav` — types `@16@0:8` — IMP `0x100008be4`
  - - `setAppsNav:` — types `v24@0:8@16` — IMP `0x100008bf4`
  - - `splitNav` — types `@16@0:8` — IMP `0x100008c08`
  - - `setSplitNav:` — types `v24@0:8@16` — IMP `0x100008c18`
  - - `settingsNav` — types `@16@0:8` — IMP `0x100008c2c`
  - - `setSettingsNav:` — types `v24@0:8@16` — IMP `0x100008c3c`
  - - `isShowingExpiredModal` — types `B16@0:8` — IMP `0x100008c50`
  - - `setIsShowingExpiredModal:` — types `v20@0:8B16` — IMP `0x100008c60`
  - - `.cxx_destruct` — types `v16@0:8` — IMP `0x100008c70`

#### CBAppModel
- Superclass: `NSObject` · địa chỉ class struct (arm64): `0x10011bf20` · instanceSize: 48 · flags: `0x184`
- Ivars (6):
  - `_isSystem` — type `B` — offset 8
  - `_isEnabled` — type `B` — offset 9
  - `_bundleIdentifier` — type `@"NSString"` — offset 16
  - `_displayName` — type `@"NSString"` — offset 24
  - `_icon` — type `@"UIImage"` — offset 32
  - `_category` — type `q` — offset 40
- Properties (7):
  - `bundleIdentifier` — attributes `T@"NSString",C,N,V_bundleIdentifier`
  - `displayName` — attributes `T@"NSString",C,N,V_displayName`
  - `icon` — attributes `T@"UIImage",&,N,V_icon`
  - `isSystem` — attributes `TB,N,V_isSystem`
  - `isEnabled` — attributes `TB,N,V_isEnabled`
  - `category` — attributes `Tq,N,V_category`
  - `isDefaultRecommendedCategory` — attributes `TB,R,N`
- Instance methods (15):
  - - `isDefaultRecommendedCategory` — types `B16@0:8` — IMP `0x100008cc4`
  - - `categoryDisplayName` — types `@16@0:8` — IMP `0x100008d0c`
  - - `bundleIdentifier` — types `@16@0:8` — IMP `0x100008dc4`
  - - `setBundleIdentifier:` — types `v24@0:8@16` — IMP `0x100008dd0`
  - - `displayName` — types `@16@0:8` — IMP `0x100008dd8`
  - - `setDisplayName:` — types `v24@0:8@16` — IMP `0x100008de4`
  - - `icon` — types `@16@0:8` — IMP `0x100008dec`
  - - `setIcon:` — types `v24@0:8@16` — IMP `0x100008df4`
  - - `isSystem` — types `B16@0:8` — IMP `0x100008e00`
  - - `setIsSystem:` — types `v20@0:8B16` — IMP `0x100008e08`
  - - `isEnabled` — types `B16@0:8` — IMP `0x100008e10`
  - - `setIsEnabled:` — types `v20@0:8B16` — IMP `0x100008e18`
  - - `category` — types `q16@0:8` — IMP `0x100008e20`
  - - `setCategory:` — types `v24@0:8q16` — IMP `0x100008e28`
  - - `.cxx_destruct` — types `v16@0:8` — IMP `0x100008e30`

#### CBAppManager
- Superclass: `NSObject` · địa chỉ class struct (arm64): `0x10011bf48` · instanceSize: 49 · flags: `0x184`
- Ivars (6):
  - `_allApps` — type `@"NSMutableArray"` — offset 8
  - `_userApps` — type `@"NSMutableArray"` — offset 16
  - `_systemApps` — type `@"NSMutableArray"` — offset 24
  - `_enabledBundleIDs` — type `@"NSMutableSet"` — offset 32
  - `_completionHandlers` — type `@"NSMutableArray"` — offset 40
  - `_isLoading` — type `B` — offset 48
- Properties (5):
  - `allApps` — attributes `T@"NSArray",R,N`
  - `userApps` — attributes `T@"NSArray",R,N`
  - `systemApps` — attributes `T@"NSArray",R,N`
  - `enabledBundleIDs` — attributes `T@"NSSet",R,N`
  - `isLoading` — attributes `TB,R,N`
- Instance methods (20):
  - - `init` — types `@16@0:8` — IMP `0x100008ed8`
  - - `allApps` — types `@16@0:8` — IMP `0x100009004`
  - - `userApps` — types `@16@0:8` — IMP `0x100009024`
  - - `systemApps` — types `@16@0:8` — IMP `0x100009044`
  - - `enabledBundleIDs` — types `@16@0:8` — IMP `0x100009064`
  - - `isLoading` — types `B16@0:8` — IMP `0x100009084`
  - - `enabledCount` — types `Q16@0:8` — IMP `0x10000908c`
  - - `reloadPreferences` — types `v16@0:8` — IMP `0x10000909c`
  - - `savePreferences` — types `v16@0:8` — IMP `0x100009274`
  - - `syncEnabledFlags` — types `v16@0:8` — IMP `0x100009490`
  - - `isAppEnabled:` — types `B24@0:8@16` — IMP `0x1000095f0`
  - - `setApp:enabled:` — types `v28@0:8@16B24` — IMP `0x10000960c`
  - - `enableAllApps` — types `v16@0:8` — IMP `0x100009690`
  - - `enableAllUserApps` — types `v16@0:8` — IMP `0x100009820`
  - - `enableDefaultRecommendedApps` — types `v16@0:8` — IMP `0x1000099b0`
  - - `enableAllNavigationApps` — types `v16@0:8` — IMP `0x100009b7c`
  - - `enableAllEntertainmentApps` — types `v16@0:8` — IMP `0x100009d4c`
  - - `disableAllApps` — types `v16@0:8` — IMP `0x100009f1c`
  - - `loadInstalledAppsWithCompletion:` — types `v24@0:8@?16` — IMP `0x10000a05c`
  - - `.cxx_destruct` — types `v16@0:8` — IMP `0x10000c370`
- Class methods (1):
  - + `sharedInstance` — types `@16@0:8` — IMP `0x100008e6c`

#### CBGeneralSettingsViewController
- Superclass: `UITableViewController` · địa chỉ class struct (arm64): `0x10011bf98` · instanceSize: 12 · flags: `0x80`
- Ivars (4):
  - `_autoLaunchOnConnect` — type `B` — offset 8
  - `_screenBlankEnabled` — type `B` — offset 9
  - `_dockMonitorEnabled` — type `B` — offset 10
  - `_hideLabelsEnabled` — type `B` — offset 11
- Properties (4):
  - `autoLaunchOnConnect` — attributes `TB,N,V_autoLaunchOnConnect`
  - `screenBlankEnabled` — attributes `TB,N,V_screenBlankEnabled`
  - `dockMonitorEnabled` — attributes `TB,N,V_dockMonitorEnabled`
  - `hideLabelsEnabled` — attributes `TB,N,V_hideLabelsEnabled`
- Instance methods (30):
  - - `init` — types `@16@0:8` — IMP `0x10000cf68`
  - - `viewDidLoad` — types `v16@0:8` — IMP `0x10000cfa0`
  - - `openSubscriptionScreen` — types `v16@0:8` — IMP `0x10000d2f4`
  - - `viewWillAppear:` — types `v20@0:8B16` — IMP `0x10000d35c`
  - - `dealloc` — types `v16@0:8` — IMP `0x10000d488`
  - - `handleLanguageChanged` — types `v16@0:8` — IMP `0x10000d5c8`
  - - `handleAppDidBecomeActive` — types `v16@0:8` — IMP `0x10000d6ac`
  - - `loadPreferences` — types `v16@0:8` — IMP `0x10000d7c4`
  - - `savePreferences` — types `v16@0:8` — IMP `0x10000da34`
  - - `autoLaunchToggleChanged:` — types `v24@0:8@16` — IMP `0x10000dde0`
  - - `screenBlankToggleChanged:` — types `v24@0:8@16` — IMP `0x10000de2c`
  - - `dockMonitorToggleChanged:` — types `v24@0:8@16` — IMP `0x10000de78`
  - - `hideLabelsToggleChanged:` — types `v24@0:8@16` — IMP `0x10000dec4`
  - - `showLanguageSelectionSheet` — types `v16@0:8` — IMP `0x10000df10`
  - - `performRespring` — types `v16@0:8` — IMP `0x10000e61c`
  - - `performResetDefaults` — types `v16@0:8` — IMP `0x10000e89c`
  - - `numberOfSectionsInTableView:` — types `q24@0:8@16` — IMP `0x10000ec00`
  - - `tableView:numberOfRowsInSection:` — types `q32@0:8@16q24` — IMP `0x10000ec08`
  - - `tableView:titleForHeaderInSection:` — types `@32@0:8@16q24` — IMP `0x10000ec28`
  - - `tableView:titleForFooterInSection:` — types `@32@0:8@16q24` — IMP `0x10000ecd8`
  - - `tableView:cellForRowAtIndexPath:` — types `@32@0:8@16@24` — IMP `0x10000ece0`
  - - `tableView:didSelectRowAtIndexPath:` — types `v32@0:8@16@24` — IMP `0x100010364`
  - - `autoLaunchOnConnect` — types `B16@0:8` — IMP `0x100010484`
  - - `setAutoLaunchOnConnect:` — types `v20@0:8B16` — IMP `0x100010494`
  - - `screenBlankEnabled` — types `B16@0:8` — IMP `0x1000104a4`
  - - `setScreenBlankEnabled:` — types `v20@0:8B16` — IMP `0x1000104b4`
  - - `dockMonitorEnabled` — types `B16@0:8` — IMP `0x1000104c4`
  - - `setDockMonitorEnabled:` — types `v20@0:8B16` — IMP `0x1000104d4`
  - - `hideLabelsEnabled` — types `B16@0:8` — IMP `0x1000104e4`
  - - `setHideLabelsEnabled:` — types `v20@0:8B16` — IMP `0x1000104f4`

#### CBAppSection
- Superclass: `NSObject` · địa chỉ class struct (arm64): `0x10011c010` · instanceSize: 40 · flags: `0x184`
- Ivars (4):
  - `_isUserSection` — type `B` — offset 8
  - `_title` — type `@"NSString"` — offset 16
  - `_footer` — type `@"NSString"` — offset 24
  - `_apps` — type `@"NSArray"` — offset 32
- Properties (4):
  - `title` — attributes `T@"NSString",C,N,V_title`
  - `footer` — attributes `T@"NSString",C,N,V_footer`
  - `apps` — attributes `T@"NSArray",&,N,V_apps`
  - `isUserSection` — attributes `TB,N,V_isUserSection`
- Instance methods (9):
  - - `title` — types `@16@0:8` — IMP `0x100010e28`
  - - `setTitle:` — types `v24@0:8@16` — IMP `0x100010e34`
  - - `footer` — types `@16@0:8` — IMP `0x100010e3c`
  - - `setFooter:` — types `v24@0:8@16` — IMP `0x100010e48`
  - - `apps` — types `@16@0:8` — IMP `0x100010e50`
  - - `setApps:` — types `v24@0:8@16` — IMP `0x100010e58`
  - - `isUserSection` — types `B16@0:8` — IMP `0x100010e64`
  - - `setIsUserSection:` — types `v20@0:8B16` — IMP `0x100010e6c`
  - - `.cxx_destruct` — types `v16@0:8` — IMP `0x100010e74`

#### CBAppSwitch
- Superclass: `UISwitch` · địa chỉ class struct (arm64): `0x10011c060` · instanceSize: 16 · flags: `0x184`
- Ivars (1):
  - `_bundleIdentifier` — type `@"NSString"` — offset 8
- Properties (1):
  - `bundleIdentifier` — attributes `T@"NSString",C,N,V_bundleIdentifier`
- Instance methods (3):
  - - `bundleIdentifier` — types `@16@0:8` — IMP `0x100010eb0`
  - - `setBundleIdentifier:` — types `v24@0:8@16` — IMP `0x100010ec0`
  - - `.cxx_destruct` — types `v16@0:8` — IMP `0x100010ecc`

#### CBAppsManagerViewController
- Superclass: `UIViewController` · địa chỉ class struct (arm64): `0x10011c088` · instanceSize: 64 · flags: `0x184`
- Protocols: `UITableViewDataSource`, `UITableViewDelegate`, `UISearchResultsUpdating`, `UISearchBarDelegate`
- Ivars (7):
  - `_tableView` — type `@"UITableView"` — offset 8
  - `_searchController` — type `@"UISearchController"` — offset 16
  - `_filterSegment` — type `@"UISegmentedControl"` — offset 24
  - `_spinner` — type `@"UIActivityIndicatorView"` — offset 32
  - `_emptyLabel` — type `@"UILabel"` — offset 40
  - `_sections` — type `@"NSArray"` — offset 48
  - `_currentFilterIndex` — type `q` — offset 56
- Properties (11):
  - `tableView` — attributes `T@"UITableView",&,N,V_tableView`
  - `searchController` — attributes `T@"UISearchController",&,N,V_searchController`
  - `filterSegment` — attributes `T@"UISegmentedControl",&,N,V_filterSegment`
  - `spinner` — attributes `T@"UIActivityIndicatorView",&,N,V_spinner`
  - `emptyLabel` — attributes `T@"UILabel",&,N,V_emptyLabel`
  - `sections` — attributes `T@"NSArray",&,N,V_sections`
  - `currentFilterIndex` — attributes `Tq,N,V_currentFilterIndex`
  - `hash` — attributes `TQ,R`
  - `superclass` — attributes `T#,R`
  - `description` — attributes `T@"NSString",R,C`
  - `debugDescription` — attributes `T@"NSString",R,C`
- Instance methods (38):
  - - `viewDidLoad` — types `v16@0:8` — IMP `0x100010ee0`
  - - `viewWillAppear:` — types `v20@0:8B16` — IMP `0x100011254`
  - - `viewDidLayoutSubviews` — types `v16@0:8` — IMP `0x100011344`
  - - `dealloc` — types `v16@0:8` — IMP `0x1000115bc`
  - - `setupNavigationItems` — types `v16@0:8` — IMP `0x100011634`
  - - `setupFilterHeader` — types `v16@0:8` — IMP `0x1000116f8`
  - - `setupTableView` — types `v16@0:8` — IMP `0x100011f6c`
  - - `setupSearchController` — types `v16@0:8` — IMP `0x10001235c`
  - - `handleAppsUpdated` — types `v16@0:8` — IMP `0x1000124f0`
  - - `handleLanguageChanged` — types `v16@0:8` — IMP `0x10001258c`
  - - `filterChanged:` — types `v24@0:8@16` — IMP `0x100012708`
  - - `appForIndexPath:` — types `@24@0:8@16` — IMP `0x10001274c`
  - - `refreshData` — types `v16@0:8` — IMP `0x1000128b8`
  - - `updateSearchResultsForSearchController:` — types `v24@0:8@16` — IMP `0x1000135ec`
  - - `searchBarCancelButtonClicked:` — types `v24@0:8@16` — IMP `0x1000135f8`
  - - `showActionMenu` — types `v16@0:8` — IMP `0x100013604`
  - - `appSwitchToggled:` — types `v24@0:8@16` — IMP `0x100013ab4`
  - - `numberOfSectionsInTableView:` — types `q24@0:8@16` — IMP `0x100013ba8`
  - - `tableView:numberOfRowsInSection:` — types `q32@0:8@16q24` — IMP `0x100013bc0`
  - - `tableView:titleForHeaderInSection:` — types `@32@0:8@16q24` — IMP `0x100013c6c`
  - - `tableView:titleForFooterInSection:` — types `@32@0:8@16q24` — IMP `0x100013d00`
  - - `tableView:cellForRowAtIndexPath:` — types `@32@0:8@16@24` — IMP `0x100013d94`
  - - `tableView:didSelectRowAtIndexPath:` — types `v32@0:8@16@24` — IMP `0x1000143ec`
  - - `tableView` — types `@16@0:8` — IMP `0x1000145e0`
  - - `setTableView:` — types `v24@0:8@16` — IMP `0x1000145f0`
  - - `searchController` — types `@16@0:8` — IMP `0x100014604`
  - - `setSearchController:` — types `v24@0:8@16` — IMP `0x100014614`
  - - `filterSegment` — types `@16@0:8` — IMP `0x100014628`
  - - `setFilterSegment:` — types `v24@0:8@16` — IMP `0x100014638`
  - - `spinner` — types `@16@0:8` — IMP `0x10001464c`
  - - `setSpinner:` — types `v24@0:8@16` — IMP `0x10001465c`
  - - `emptyLabel` — types `@16@0:8` — IMP `0x100014670`
  - - `setEmptyLabel:` — types `v24@0:8@16` — IMP `0x100014680`
  - - `sections` — types `@16@0:8` — IMP `0x100014694`
  - - `setSections:` — types `v24@0:8@16` — IMP `0x1000146a4`
  - - `currentFilterIndex` — types `q16@0:8` — IMP `0x1000146b8`
  - - `setCurrentFilterIndex:` — types `v24@0:8q16` — IMP `0x1000146c8`
  - - `.cxx_destruct` — types `v16@0:8` — IMP `0x1000146d8`

#### CBAppPickerViewController
- Superclass: `UITableViewController` · địa chỉ class struct (arm64): `0x10011c0d8` · instanceSize: 48 · flags: `0x184`
- Protocols: `UISearchResultsUpdating`
- Ivars (5):
  - `_apps` — type `@"NSArray"` — offset 8
  - `_filteredApps` — type `@"NSArray"` — offset 16
  - `_disabledBundleIDs` — type `@"NSSet"` — offset 24
  - `_onSelectApp` — type `@?` — offset 32
  - `_searchController` — type `@"UISearchController"` — offset 40
- Properties (9):
  - `apps` — attributes `T@"NSArray",&,N,V_apps`
  - `filteredApps` — attributes `T@"NSArray",&,N,V_filteredApps`
  - `disabledBundleIDs` — attributes `T@"NSSet",&,N,V_disabledBundleIDs`
  - `onSelectApp` — attributes `T@?,C,N,V_onSelectApp`
  - `searchController` — attributes `T@"UISearchController",&,N,V_searchController`
  - `hash` — attributes `TQ,R`
  - `superclass` — attributes `T#,R`
  - `description` — attributes `T@"NSString",R,C`
  - `debugDescription` — attributes `T@"NSString",R,C`
- Instance methods (16):
  - - `viewDidLoad` — types `v16@0:8` — IMP `0x100014768`
  - - `updateSearchResultsForSearchController:` — types `v24@0:8@16` — IMP `0x100014d54`
  - - `tableView:numberOfRowsInSection:` — types `q32@0:8@16q24` — IMP `0x100014ed0`
  - - `tableView:cellForRowAtIndexPath:` — types `@32@0:8@16@24` — IMP `0x100014f1c`
  - - `tableView:didSelectRowAtIndexPath:` — types `v32@0:8@16@24` — IMP `0x10001550c`
  - - `apps` — types `@16@0:8` — IMP `0x1000156f8`
  - - `setApps:` — types `v24@0:8@16` — IMP `0x100015708`
  - - `filteredApps` — types `@16@0:8` — IMP `0x10001571c`
  - - `setFilteredApps:` — types `v24@0:8@16` — IMP `0x10001572c`
  - - `disabledBundleIDs` — types `@16@0:8` — IMP `0x100015740`
  - - `setDisabledBundleIDs:` — types `v24@0:8@16` — IMP `0x100015750`
  - - `onSelectApp` — types `@?16@0:8` — IMP `0x100015764`
  - - `setOnSelectApp:` — types `v24@0:8@?16` — IMP `0x100015774`
  - - `searchController` — types `@16@0:8` — IMP `0x100015780`
  - - `setSearchController:` — types `v24@0:8@16` — IMP `0x100015790`
  - - `.cxx_destruct` — types `v16@0:8` — IMP `0x1000157a4`

#### CBSplitViewController
- Superclass: `UITableViewController` · địa chỉ class struct (arm64): `0x10011c128` · instanceSize: 96 · flags: `0x184`
- Ivars (11):
  - `_splitEnabled` — type `B` — offset 8
  - `_availableApps` — type `@"NSArray"` — offset 16
  - `_splitPreset` — type `q` — offset 24
  - `_slotApp1` — type `@"NSString"` — offset 32
  - `_slotApp2` — type `@"NSString"` — offset 40
  - `_slotApp3` — type `@"NSString"` — offset 48
  - `_slotApp4` — type `@"NSString"` — offset 56
  - `_slotName1` — type `@"NSString"` — offset 64
  - `_slotName2` — type `@"NSString"` — offset 72
  - `_slotName3` — type `@"NSString"` — offset 80
  - `_slotName4` — type `@"NSString"` — offset 88
- Properties (11):
  - `splitEnabled` — attributes `TB,N,V_splitEnabled`
  - `splitPreset` — attributes `Tq,N,V_splitPreset`
  - `slotApp1` — attributes `T@"NSString",C,N,V_slotApp1`
  - `slotApp2` — attributes `T@"NSString",C,N,V_slotApp2`
  - `slotApp3` — attributes `T@"NSString",C,N,V_slotApp3`
  - `slotApp4` — attributes `T@"NSString",C,N,V_slotApp4`
  - `slotName1` — attributes `T@"NSString",C,N,V_slotName1`
  - `slotName2` — attributes `T@"NSString",C,N,V_slotName2`
  - `slotName3` — attributes `T@"NSString",C,N,V_slotName3`
  - `slotName4` — attributes `T@"NSString",C,N,V_slotName4`
  - `availableApps` — attributes `T@"NSArray",&,N,V_availableApps`
- Instance methods (42):
  - - `init` — types `@16@0:8` — IMP `0x100015820`
  - - `viewDidLoad` — types `v16@0:8` — IMP `0x100015858`
  - - `dealloc` — types `v16@0:8` — IMP `0x100015ab4`
  - - `handleAppsLoaded` — types `v16@0:8` — IMP `0x100015b2c`
  - - `handleLanguageChanged` — types `v16@0:8` — IMP `0x100015ca8`
  - - `viewWillAppear:` — types `v20@0:8B16` — IMP `0x100015d8c`
  - - `loadSettings` — types `v16@0:8` — IMP `0x100015f20`
  - - `nameForBundleID:` — types `@24@0:8@16` — IMP `0x1000164b8`
  - - `updateNames` — types `v16@0:8` — IMP `0x1000166b4`
  - - `saveSettings` — types `v16@0:8` — IMP `0x1000167b0`
  - - `presetTitleForIndex:` — types `@24@0:8q16` — IMP `0x100016bbc`
  - - `slotCountForPreset:` — types `q24@0:8q16` — IMP `0x100016c7c`
  - - `slotTitleForIndex:preset:` — types `@32@0:8q16q24` — IMP `0x100016c9c`
  - - `numberOfSectionsInTableView:` — types `q24@0:8@16` — IMP `0x100017038`
  - - `tableView:numberOfRowsInSection:` — types `q32@0:8@16q24` — IMP `0x100017040`
  - - `tableView:titleForHeaderInSection:` — types `@32@0:8@16q24` — IMP `0x100017094`
  - - `tableView:titleForFooterInSection:` — types `@32@0:8@16q24` — IMP `0x100017110`
  - - `tableView:cellForRowAtIndexPath:` — types `@32@0:8@16@24` — IMP `0x100017154`
  - - `tableView:didSelectRowAtIndexPath:` — types `v32@0:8@16@24` — IMP `0x1000178fc`
  - - `availableApps` — types `@16@0:8` — IMP `0x100017ef0`
  - - `setAvailableApps:` — types `v24@0:8@16` — IMP `0x100017f00`
  - - `splitEnabled` — types `B16@0:8` — IMP `0x100017f14`
  - - `setSplitEnabled:` — types `v20@0:8B16` — IMP `0x100017f24`
  - - `splitPreset` — types `q16@0:8` — IMP `0x100017f34`
  - - `setSplitPreset:` — types `v24@0:8q16` — IMP `0x100017f44`
  - - `slotApp1` — types `@16@0:8` — IMP `0x100017f54`
  - - `setSlotApp1:` — types `v24@0:8@16` — IMP `0x100017f64`
  - - `slotApp2` — types `@16@0:8` — IMP `0x100017f70`
  - - `setSlotApp2:` — types `v24@0:8@16` — IMP `0x100017f80`
  - - `slotApp3` — types `@16@0:8` — IMP `0x100017f8c`
  - - `setSlotApp3:` — types `v24@0:8@16` — IMP `0x100017f9c`
  - - `slotApp4` — types `@16@0:8` — IMP `0x100017fa8`
  - - `setSlotApp4:` — types `v24@0:8@16` — IMP `0x100017fb8`
  - - `slotName1` — types `@16@0:8` — IMP `0x100017fc4`
  - - `setSlotName1:` — types `v24@0:8@16` — IMP `0x100017fd4`
  - - `slotName2` — types `@16@0:8` — IMP `0x100017fe0`
  - - `setSlotName2:` — types `v24@0:8@16` — IMP `0x100017ff0`
  - - `slotName3` — types `@16@0:8` — IMP `0x100017ffc`
  - - `setSlotName3:` — types `v24@0:8@16` — IMP `0x10001800c`
  - - `slotName4` — types `@16@0:8` — IMP `0x100018018`
  - - `setSlotName4:` — types `v24@0:8@16` — IMP `0x100018028`
  - - `.cxx_destruct` — types `v16@0:8` — IMP `0x100018034`

#### CBAssistantAboutViewController
- Superclass: `UITableViewController` · địa chỉ class struct (arm64): `0x10011c178` · instanceSize: 24 · flags: `0x80`
- Ivars (3):
  - `_assistantEnabled` — type `B` — offset 8
  - `_voiceFeedbackEnabled` — type `B` — offset 9
  - `_preferredMapIndex` — type `q` — offset 16
- Properties (3):
  - `assistantEnabled` — attributes `TB,N,V_assistantEnabled`
  - `preferredMapIndex` — attributes `Tq,N,V_preferredMapIndex`
  - `voiceFeedbackEnabled` — attributes `TB,N,V_voiceFeedbackEnabled`
- Instance methods (24):
  - - `init` — types `@16@0:8` — IMP `0x10001886c`
  - - `viewDidLoad` — types `v16@0:8` — IMP `0x1000188a4`
  - - `viewWillAppear:` — types `v20@0:8B16` — IMP `0x100018a0c`
  - - `dealloc` — types `v16@0:8` — IMP `0x100018ad0`
  - - `handleLanguageChanged` — types `v16@0:8` — IMP `0x100018b48`
  - - `loadPreferences` — types `v16@0:8` — IMP `0x100018c2c`
  - - `savePreferences` — types `v16@0:8` — IMP `0x100018df0`
  - - `assistantToggleChanged:` — types `v24@0:8@16` — IMP `0x100019048`
  - - `mapAppChanged:` — types `v24@0:8@16` — IMP `0x100019094`
  - - `voiceFeedbackToggleChanged:` — types `v24@0:8@16` — IMP `0x1000190e0`
  - - `performRespring` — types `v16@0:8` — IMP `0x10001912c`
  - - `performResetDefaults` — types `v16@0:8` — IMP `0x1000193ac`
  - - `numberOfSectionsInTableView:` — types `q24@0:8@16` — IMP `0x100019710`
  - - `tableView:numberOfRowsInSection:` — types `q32@0:8@16q24` — IMP `0x100019718`
  - - `tableView:titleForHeaderInSection:` — types `@32@0:8@16q24` — IMP `0x100019738`
  - - `tableView:titleForFooterInSection:` — types `@32@0:8@16q24` — IMP `0x1000197c8`
  - - `tableView:cellForRowAtIndexPath:` — types `@32@0:8@16@24` — IMP `0x100019808`
  - - `tableView:didSelectRowAtIndexPath:` — types `v32@0:8@16@24` — IMP `0x10001a790`
  - - `assistantEnabled` — types `B16@0:8` — IMP `0x10001a840`
  - - `setAssistantEnabled:` — types `v20@0:8B16` — IMP `0x10001a850`
  - - `preferredMapIndex` — types `q16@0:8` — IMP `0x10001a860`
  - - `setPreferredMapIndex:` — types `v24@0:8q16` — IMP `0x10001a870`
  - - `voiceFeedbackEnabled` — types `B16@0:8` — IMP `0x10001a880`
  - - `setVoiceFeedbackEnabled:` — types `v20@0:8B16` — IMP `0x10001a890`

#### CBSubscriptionViewController
- Superclass: `UIViewController` · địa chỉ class struct (arm64): `0x10011c1c8` · instanceSize: 96 · flags: `0x184`
- Protocols: `UITableViewDelegate`, `UITableViewDataSource`, `UITextFieldDelegate`, `CBSubscriptionOrderCoordinatorDelegate`, `CBSubscriptionCheckoutCellDelegate`, `CBSubscriptionPendingOrderCellDelegate`, `CBSubscriptionGiftcodeInputCellDelegate`, `CBSubscriptionGiftcodeRedeemCellDelegate`, `CBSubscriptionHardwareIDCellDelegate`
- Ivars (14):
  - `_isLoadingPlans` — type `B` — offset 8
  - `_plansLoadFailed` — type `B` — offset 9
  - `_isCheckoutLoading` — type `B` — offset 10
  - `_isGiftRedeeming` — type `B` — offset 11
  - `_tableView` — type `@"UITableView"` — offset 16
  - `_segmentedHeaderView` — type `@"UIView"` — offset 24
  - `_modeSegmentedControl` — type `@"UISegmentedControl"` — offset 32
  - `_currentMode` — type `q` — offset 40
  - `_plansData` — type `@"NSArray"` — offset 48
  - `_rawPlansData` — type `@"NSArray"` — offset 56
  - `_selectedTierIndex` — type `q` — offset 64
  - `_orderCoordinator` — type `@"CBSubscriptionOrderCoordinator"` — offset 72
  - `_giftCodeTextField` — type `@"UITextField"` — offset 80
  - `_giftRedeemCell` — type `@"CBSubscriptionGiftcodeRedeemCell"` — offset 88
- Properties (18):
  - `tableView` — attributes `T@"UITableView",&,N,V_tableView`
  - `segmentedHeaderView` — attributes `T@"UIView",&,N,V_segmentedHeaderView`
  - `modeSegmentedControl` — attributes `T@"UISegmentedControl",&,N,V_modeSegmentedControl`
  - `currentMode` — attributes `Tq,N,V_currentMode`
  - `plansData` — attributes `T@"NSArray",&,N,V_plansData`
  - `rawPlansData` — attributes `T@"NSArray",&,N,V_rawPlansData`
  - `selectedTierIndex` — attributes `Tq,N,V_selectedTierIndex`
  - `isLoadingPlans` — attributes `TB,N,V_isLoadingPlans`
  - `plansLoadFailed` — attributes `TB,N,V_plansLoadFailed`
  - `orderCoordinator` — attributes `T@"CBSubscriptionOrderCoordinator",&,N,V_orderCoordinator`
  - `isCheckoutLoading` — attributes `TB,N,V_isCheckoutLoading`
  - `giftCodeTextField` — attributes `T@"UITextField",W,N,V_giftCodeTextField`
  - `giftRedeemCell` — attributes `T@"CBSubscriptionGiftcodeRedeemCell",W,N,V_giftRedeemCell`
  - `isGiftRedeeming` — attributes `TB,N,V_isGiftRedeeming`
  - `hash` — attributes `TQ,R`
  - `superclass` — attributes `T#,R`
  - `description` — attributes `T@"NSString",R,C`
  - `debugDescription` — attributes `T@"NSString",R,C`
- Instance methods (71):
  - - `viewDidLoad` — types `v16@0:8` — IMP `0x10001ad14`
  - - `viewWillAppear:` — types `v20@0:8B16` — IMP `0x10001b138`
  - - `viewWillDisappear:` — types `v20@0:8B16` — IMP `0x10001b314`
  - - `dealloc` — types `v16@0:8` — IMP `0x10001b384`
  - - `keyboardWillShow:` — types `v24@0:8@16` — IMP `0x10001b464`
  - - `keyboardWillHide:` — types `v24@0:8@16` — IMP `0x10001b6c4`
  - - `dismissKeyboard` — types `v16@0:8` — IMP `0x10001b7a8`
  - - `setupTableView` — types `v16@0:8` — IMP `0x10001b7ec`
  - - `setupTableHeader` — types `v16@0:8` — IMP `0x10001bd64`
  - - `isVIPActiveWithSufficientDays` — types `B16@0:8` — IMP `0x10001c320`
  - - `updateTableHeaderForCurrentState` — types `v16@0:8` — IMP `0x10001c3f0`
  - - `modeSegmentChanged:` — types `v24@0:8@16` — IMP `0x10001c508`
  - - `numberOfSectionsInTableView:` — types `q24@0:8@16` — IMP `0x10001c604`
  - - `tableView:numberOfRowsInSection:` — types `q32@0:8@16q24` — IMP `0x10001c678`
  - - `tableView:titleForHeaderInSection:` — types `@32@0:8@16q24` — IMP `0x10001c834`
  - - `tableView:titleForFooterInSection:` — types `@32@0:8@16q24` — IMP `0x10001c984`
  - - `tableView:cellForRowAtIndexPath:` — types `@32@0:8@16@24` — IMP `0x10001cab0`
  - - `tableView:didSelectRowAtIndexPath:` — types `v32@0:8@16@24` — IMP `0x10001d468`
  - - `fetchPlansFromServer` — types `v16@0:8` — IMP `0x10001d6c4`
  - - `handleLanguageChanged` — types `v16@0:8` — IMP `0x10001e03c`
  - - `formattedPriceForPlan:` — types `@24@0:8@16` — IMP `0x10001e1c4`
  - - `displayNameForTier:` — types `@24@0:8@16` — IMP `0x10001e3a0`
  - - `currentCheckoutButtonTitle` — types `@16@0:8` — IMP `0x10001e710`
  - - `showPlansLoadFailureAlertWithError:` — types `v24@0:8@16` — IMP `0x10001eb5c`
  - - `checkoutCellDidTapCheckout:` — types `v24@0:8@16` — IMP `0x10001ee24`
  - - `pendingOrderCellDidTapResume:` — types `v24@0:8@16` — IMP `0x10001f7d8`
  - - `pendingOrderCellDidTapCheckStatus:` — types `v24@0:8@16` — IMP `0x10001f818`
  - - `pendingOrderCellDidTapCancel:` — types `v24@0:8@16` — IMP `0x10001f858`
  - - `giftcodeInputCellDidTapPaste:` — types `v24@0:8@16` — IMP `0x10001f898`
  - - `giftcodeRedeemCellDidTapRedeem:` — types `v24@0:8@16` — IMP `0x10001fa2c`
  - - `hardwareIDCellDidTapCopy:` — types `v24@0:8@16` — IMP `0x10001fa38`
  - - `redeemGiftCodeTapped` — types `v16@0:8` — IMP `0x10001fc54`
  - - `setGiftRedeemLoading:` — types `v20@0:8B16` — IMP `0x1000214c8`
  - - `textFieldShouldReturn:` — types `B24@0:8@16` — IMP `0x100021524`
  - - `orderCoordinatorDidUpdatePendingOrder:` — types `v24@0:8@16` — IMP `0x1000215f4`
  - - `orderCoordinatorDidClearPendingOrder:` — types `v24@0:8@16` — IMP `0x100021634`
  - - `orderCoordinatorDidCompletePaymentSuccessfully:` — types `v24@0:8@16` — IMP `0x100021674`
  - - `orderCoordinator:shouldPresentAlert:` — types `v32@0:8@16@24` — IMP `0x100021784`
  - - `orderCoordinator:shouldPresentSafari:` — types `v32@0:8@16@24` — IMP `0x100021868`
  - - `orderCoordinator:setCheckoutLoading:` — types `v28@0:8@16B24` — IMP `0x10002194c`
  - - `orderCoordinator:setCheckStatusButtonChecking:` — types `v28@0:8@16B24` — IMP `0x1000219a4`
  - - `showAlertWithTitle:message:` — types `v32@0:8@16@24` — IMP `0x1000219a8`
  - - `tableView` — types `@16@0:8` — IMP `0x100021b48`
  - - `setTableView:` — types `v24@0:8@16` — IMP `0x100021b58`
  - - `segmentedHeaderView` — types `@16@0:8` — IMP `0x100021b6c`
  - - `setSegmentedHeaderView:` — types `v24@0:8@16` — IMP `0x100021b7c`
  - - `modeSegmentedControl` — types `@16@0:8` — IMP `0x100021b90`
  - - `setModeSegmentedControl:` — types `v24@0:8@16` — IMP `0x100021ba0`
  - - `currentMode` — types `q16@0:8` — IMP `0x100021bb4`
  - - `setCurrentMode:` — types `v24@0:8q16` — IMP `0x100021bc4`
  - - `plansData` — types `@16@0:8` — IMP `0x100021bd4`
  - - `setPlansData:` — types `v24@0:8@16` — IMP `0x100021be4`
  - - `rawPlansData` — types `@16@0:8` — IMP `0x100021bf8`
  - - `setRawPlansData:` — types `v24@0:8@16` — IMP `0x100021c08`
  - - `selectedTierIndex` — types `q16@0:8` — IMP `0x100021c1c`
  - - `setSelectedTierIndex:` — types `v24@0:8q16` — IMP `0x100021c2c`
  - - `isLoadingPlans` — types `B16@0:8` — IMP `0x100021c3c`
  - - `setIsLoadingPlans:` — types `v20@0:8B16` — IMP `0x100021c4c`
  - - `plansLoadFailed` — types `B16@0:8` — IMP `0x100021c5c`
  - - `setPlansLoadFailed:` — types `v20@0:8B16` — IMP `0x100021c6c`
  - - `orderCoordinator` — types `@16@0:8` — IMP `0x100021c7c`
  - - `setOrderCoordinator:` — types `v24@0:8@16` — IMP `0x100021c8c`
  - - `isCheckoutLoading` — types `B16@0:8` — IMP `0x100021ca0`
  - - `setIsCheckoutLoading:` — types `v20@0:8B16` — IMP `0x100021cb0`
  - - `giftCodeTextField` — types `@16@0:8` — IMP `0x100021cc0`
  - - `setGiftCodeTextField:` — types `v24@0:8@16` — IMP `0x100021ce0`
  - - `giftRedeemCell` — types `@16@0:8` — IMP `0x100021cf4`
  - - `setGiftRedeemCell:` — types `v24@0:8@16` — IMP `0x100021d14`
  - - `isGiftRedeeming` — types `B16@0:8` — IMP `0x100021d28`
  - - `setIsGiftRedeeming:` — types `v20@0:8B16` — IMP `0x100021d38`
  - - `.cxx_destruct` — types `v16@0:8` — IMP `0x100021d48`

#### CBLicenseExpiredModalViewController
- Superclass: `UIViewController` · địa chỉ class struct (arm64): `0x10011c218` · instanceSize: 88 · flags: `0x184`
- Ivars (10):
  - `_onActivateTapped` — type `@?` — offset 8
  - `_onDismissTapped` — type `@?` — offset 16
  - `_blurBackdrop` — type `@"UIVisualEffectView"` — offset 24
  - `_dimmerOverlay` — type `@"UIView"` — offset 32
  - `_cardView` — type `@"UIView"` — offset 40
  - `_iconImageView` — type `@"UIImageView"` — offset 48
  - `_titleLabel` — type `@"UILabel"` — offset 56
  - `_messageLabel` — type `@"UILabel"` — offset 64
  - `_activateButton` — type `@"UIButton"` — offset 72
  - `_laterButton` — type `@"UIButton"` — offset 80
- Properties (10):
  - `blurBackdrop` — attributes `T@"UIVisualEffectView",&,N,V_blurBackdrop`
  - `dimmerOverlay` — attributes `T@"UIView",&,N,V_dimmerOverlay`
  - `cardView` — attributes `T@"UIView",&,N,V_cardView`
  - `iconImageView` — attributes `T@"UIImageView",&,N,V_iconImageView`
  - `titleLabel` — attributes `T@"UILabel",&,N,V_titleLabel`
  - `messageLabel` — attributes `T@"UILabel",&,N,V_messageLabel`
  - `activateButton` — attributes `T@"UIButton",&,N,V_activateButton`
  - `laterButton` — attributes `T@"UIButton",&,N,V_laterButton`
  - `onActivateTapped` — attributes `T@?,C,N,V_onActivateTapped`
  - `onDismissTapped` — attributes `T@?,C,N,V_onDismissTapped`
- Instance methods (29):
  - - `viewDidLoad` — types `v16@0:8` — IMP `0x10002251c`
  - - `viewWillAppear:` — types `v20@0:8B16` — IMP `0x1000225f0`
  - - `setupBackdrop` — types `v16@0:8` — IMP `0x1000228ac`
  - - `setupCardView` — types `v16@0:8` — IMP `0x100022b14`
  - - `setupContent` — types `v16@0:8` — IMP `0x100023168`
  - - `handleActivateTapped` — types `v16@0:8` — IMP `0x100024528`
  - - `handleLaterTapped` — types `v16@0:8` — IMP `0x100024644`
  - - `dismissWithCompletion:` — types `v24@0:8@?16` — IMP `0x100024760`
  - - `onActivateTapped` — types `@?16@0:8` — IMP `0x100024998`
  - - `setOnActivateTapped:` — types `v24@0:8@?16` — IMP `0x1000249a8`
  - - `onDismissTapped` — types `@?16@0:8` — IMP `0x1000249b4`
  - - `setOnDismissTapped:` — types `v24@0:8@?16` — IMP `0x1000249c4`
  - - `blurBackdrop` — types `@16@0:8` — IMP `0x1000249d0`
  - - `setBlurBackdrop:` — types `v24@0:8@16` — IMP `0x1000249e0`
  - - `dimmerOverlay` — types `@16@0:8` — IMP `0x1000249f4`
  - - `setDimmerOverlay:` — types `v24@0:8@16` — IMP `0x100024a04`
  - - `cardView` — types `@16@0:8` — IMP `0x100024a18`
  - - `setCardView:` — types `v24@0:8@16` — IMP `0x100024a28`
  - - `iconImageView` — types `@16@0:8` — IMP `0x100024a3c`
  - - `setIconImageView:` — types `v24@0:8@16` — IMP `0x100024a4c`
  - - `titleLabel` — types `@16@0:8` — IMP `0x100024a60`
  - - `setTitleLabel:` — types `v24@0:8@16` — IMP `0x100024a70`
  - - `messageLabel` — types `@16@0:8` — IMP `0x100024a84`
  - - `setMessageLabel:` — types `v24@0:8@16` — IMP `0x100024a94`
  - - `activateButton` — types `@16@0:8` — IMP `0x100024aa8`
  - - `setActivateButton:` — types `v24@0:8@16` — IMP `0x100024ab8`
  - - `laterButton` — types `@16@0:8` — IMP `0x100024acc`
  - - `setLaterButton:` — types `v24@0:8@16` — IMP `0x100024adc`
  - - `.cxx_destruct` — types `v16@0:8` — IMP `0x100024af0`
- Class methods (1):
  - + `modalWithActivateHandler:dismissHandler:` — types `@32@0:8@?16@?24` — IMP `0x100022470`

#### CBSubscriptionCheckoutCell
- Superclass: `UITableViewCell` · địa chỉ class struct (arm64): `0x10011c268` · instanceSize: 32 · flags: `0x184`
- Ivars (3):
  - `_delegate` — type `@"<CBSubscriptionCheckoutCellDelegate>"` — offset 8
  - `_checkoutButton` — type `@"UIButton"` — offset 16
  - `_checkoutSpinner` — type `@"UIActivityIndicatorView"` — offset 24
- Properties (3):
  - `checkoutButton` — attributes `T@"UIButton",&,N,V_checkoutButton`
  - `checkoutSpinner` — attributes `T@"UIActivityIndicatorView",&,N,V_checkoutSpinner`
  - `delegate` — attributes `T@"<CBSubscriptionCheckoutCellDelegate>",W,N,V_delegate`
- Instance methods (10):
  - - `initWithStyle:reuseIdentifier:` — types `@32@0:8q16@24` — IMP `0x100024bd0`
  - - `configureWithTitle:loading:` — types `v28@0:8@16B24` — IMP `0x100025330`
  - - `checkoutTapped` — types `v16@0:8` — IMP `0x100025424`
  - - `delegate` — types `@16@0:8` — IMP `0x1000254d0`
  - - `setDelegate:` — types `v24@0:8@16` — IMP `0x1000254f0`
  - - `checkoutButton` — types `@16@0:8` — IMP `0x100025504`
  - - `setCheckoutButton:` — types `v24@0:8@16` — IMP `0x100025514`
  - - `checkoutSpinner` — types `@16@0:8` — IMP `0x100025528`
  - - `setCheckoutSpinner:` — types `v24@0:8@16` — IMP `0x100025538`
  - - `.cxx_destruct` — types `v16@0:8` — IMP `0x10002554c`

#### CBSubscriptionVIPStatusCell
- Superclass: `UITableViewCell` · địa chỉ class struct (arm64): `0x10011c2b8` · instanceSize: 8 · flags: `0x80`
- Instance methods (2):
  - - `initWithStyle:reuseIdentifier:` — types `@32@0:8q16@24` — IMP `0x10002559c`
  - - `configureWithExpirationTimestamp:` — types `v24@0:8Q16` — IMP `0x100025860`

#### CBSubscriptionHardwareIDCell
- Superclass: `UITableViewCell` · địa chỉ class struct (arm64): `0x10011c308` · instanceSize: 32 · flags: `0x184`
- Ivars (3):
  - `_delegate` — type `@"<CBSubscriptionHardwareIDCellDelegate>"` — offset 8
  - `_hwLabel` — type `@"UILabel"` — offset 16
  - `_clipboardButton` — type `@"UIButton"` — offset 24
- Properties (3):
  - `hwLabel` — attributes `T@"UILabel",&,N,V_hwLabel`
  - `clipboardButton` — attributes `T@"UIButton",&,N,V_clipboardButton`
  - `delegate` — attributes `T@"<CBSubscriptionHardwareIDCellDelegate>",W,N,V_delegate`
- Instance methods (10):
  - - `initWithStyle:reuseIdentifier:` — types `@32@0:8q16@24` — IMP `0x100025a00`
  - - `configureWithHardwareHash:` — types `v24@0:8@16` — IMP `0x1000262a4`
  - - `copyTapped` — types `v16@0:8` — IMP `0x10002644c`
  - - `delegate` — types `@16@0:8` — IMP `0x1000264f8`
  - - `setDelegate:` — types `v24@0:8@16` — IMP `0x100026518`
  - - `hwLabel` — types `@16@0:8` — IMP `0x10002652c`
  - - `setHwLabel:` — types `v24@0:8@16` — IMP `0x10002653c`
  - - `clipboardButton` — types `@16@0:8` — IMP `0x100026550`
  - - `setClipboardButton:` — types `v24@0:8@16` — IMP `0x100026560`
  - - `.cxx_destruct` — types `v16@0:8` — IMP `0x100026574`

#### CBSubscriptionGiftcodeInputCell
- Superclass: `UITableViewCell` · địa chỉ class struct (arm64): `0x10011c358` · instanceSize: 32 · flags: `0x184`
- Ivars (3):
  - `_delegate` — type `@"<CBSubscriptionGiftcodeInputCellDelegate>"` — offset 8
  - `_textField` — type `@"UITextField"` — offset 16
  - `_pasteButton` — type `@"UIButton"` — offset 24
- Properties (3):
  - `textField` — attributes `T@"UITextField",&,N,V_textField`
  - `pasteButton` — attributes `T@"UIButton",&,N,V_pasteButton`
  - `delegate` — attributes `T@"<CBSubscriptionGiftcodeInputCellDelegate>",W,N,V_delegate`
- Instance methods (9):
  - - `initWithStyle:reuseIdentifier:` — types `@32@0:8q16@24` — IMP `0x1000265c4`
  - - `pasteTapped` — types `v16@0:8` — IMP `0x100026f18`
  - - `delegate` — types `@16@0:8` — IMP `0x100026fc4`
  - - `setDelegate:` — types `v24@0:8@16` — IMP `0x100026fe4`
  - - `textField` — types `@16@0:8` — IMP `0x100026ff8`
  - - `setTextField:` — types `v24@0:8@16` — IMP `0x100027008`
  - - `pasteButton` — types `@16@0:8` — IMP `0x10002701c`
  - - `setPasteButton:` — types `v24@0:8@16` — IMP `0x10002702c`
  - - `.cxx_destruct` — types `v16@0:8` — IMP `0x100027040`

#### CBSubscriptionGiftcodeRedeemCell
- Superclass: `UITableViewCell` · địa chỉ class struct (arm64): `0x10011c3a8` · instanceSize: 32 · flags: `0x184`
- Ivars (3):
  - `_delegate` — type `@"<CBSubscriptionGiftcodeRedeemCellDelegate>"` — offset 8
  - `_redeemButton` — type `@"UIButton"` — offset 16
  - `_spinner` — type `@"UIActivityIndicatorView"` — offset 24
- Properties (3):
  - `redeemButton` — attributes `T@"UIButton",&,N,V_redeemButton`
  - `spinner` — attributes `T@"UIActivityIndicatorView",&,N,V_spinner`
  - `delegate` — attributes `T@"<CBSubscriptionGiftcodeRedeemCellDelegate>",W,N,V_delegate`
- Instance methods (10):
  - - `initWithStyle:reuseIdentifier:` — types `@32@0:8q16@24` — IMP `0x100027090`
  - - `redeemTapped` — types `v16@0:8` — IMP `0x10002783c`
  - - `setLoading:` — types `v20@0:8B16` — IMP `0x1000278e8`
  - - `delegate` — types `@16@0:8` — IMP `0x100027984`
  - - `setDelegate:` — types `v24@0:8@16` — IMP `0x1000279a4`
  - - `redeemButton` — types `@16@0:8` — IMP `0x1000279b8`
  - - `setRedeemButton:` — types `v24@0:8@16` — IMP `0x1000279c8`
  - - `spinner` — types `@16@0:8` — IMP `0x1000279dc`
  - - `setSpinner:` — types `v24@0:8@16` — IMP `0x1000279ec`
  - - `.cxx_destruct` — types `v16@0:8` — IMP `0x100027a00`

#### CBSubscriptionPendingOrderCell
- Superclass: `UITableViewCell` · địa chỉ class struct (arm64): `0x10011c3f8` · instanceSize: 56 · flags: `0x184`
- Ivars (6):
  - `_delegate` — type `@"<CBSubscriptionPendingOrderCellDelegate>"` — offset 8
  - `_titleLabel` — type `@"UILabel"` — offset 16
  - `_descLabel` — type `@"UILabel"` — offset 24
  - `_resumeBtn` — type `@"UIButton"` — offset 32
  - `_checkStatusButton` — type `@"UIButton"` — offset 40
  - `_cancelBtn` — type `@"UIButton"` — offset 48
- Properties (6):
  - `titleLabel` — attributes `T@"UILabel",&,N,V_titleLabel`
  - `descLabel` — attributes `T@"UILabel",&,N,V_descLabel`
  - `resumeBtn` — attributes `T@"UIButton",&,N,V_resumeBtn`
  - `checkStatusButton` — attributes `T@"UIButton",&,N,V_checkStatusButton`
  - `cancelBtn` — attributes `T@"UIButton",&,N,V_cancelBtn`
  - `delegate` — attributes `T@"<CBSubscriptionPendingOrderCellDelegate>",W,N,V_delegate`
- Instance methods (18):
  - - `initWithStyle:reuseIdentifier:` — types `@32@0:8q16@24` — IMP `0x100027a50`
  - - `configureWithTitle:description:` — types `v32@0:8@16@24` — IMP `0x10002872c`
  - - `resumeTapped` — types `v16@0:8` — IMP `0x1000287ec`
  - - `checkStatusTapped` — types `v16@0:8` — IMP `0x100028898`
  - - `cancelTapped` — types `v16@0:8` — IMP `0x100028944`
  - - `delegate` — types `@16@0:8` — IMP `0x1000289f0`
  - - `setDelegate:` — types `v24@0:8@16` — IMP `0x100028a10`
  - - `titleLabel` — types `@16@0:8` — IMP `0x100028a24`
  - - `setTitleLabel:` — types `v24@0:8@16` — IMP `0x100028a34`
  - - `descLabel` — types `@16@0:8` — IMP `0x100028a48`
  - - `setDescLabel:` — types `v24@0:8@16` — IMP `0x100028a58`
  - - `resumeBtn` — types `@16@0:8` — IMP `0x100028a6c`
  - - `setResumeBtn:` — types `v24@0:8@16` — IMP `0x100028a7c`
  - - `checkStatusButton` — types `@16@0:8` — IMP `0x100028a90`
  - - `setCheckStatusButton:` — types `v24@0:8@16` — IMP `0x100028aa0`
  - - `cancelBtn` — types `@16@0:8` — IMP `0x100028ab4`
  - - `setCancelBtn:` — types `v24@0:8@16` — IMP `0x100028ac4`
  - - `.cxx_destruct` — types `v16@0:8` — IMP `0x100028ad8`

#### CBSubscriptionPlanCardCell
- Superclass: `UITableViewCell` · địa chỉ class struct (arm64): `0x10011c448` · instanceSize: 48 · flags: `0x184`
- Ivars (5):
  - `_nameLabel` — type `@"UILabel"` — offset 8
  - `_badgeLabel` — type `@"UILabel"` — offset 16
  - `_descLabel` — type `@"UILabel"` — offset 24
  - `_priceLabel` — type `@"UILabel"` — offset 32
  - `_checkIcon` — type `@"UIImageView"` — offset 40
- Properties (5):
  - `nameLabel` — attributes `T@"UILabel",&,N,V_nameLabel`
  - `badgeLabel` — attributes `T@"UILabel",&,N,V_badgeLabel`
  - `descLabel` — attributes `T@"UILabel",&,N,V_descLabel`
  - `priceLabel` — attributes `T@"UILabel",&,N,V_priceLabel`
  - `checkIcon` — attributes `T@"UIImageView",&,N,V_checkIcon`
- Instance methods (13):
  - - `initWithStyle:reuseIdentifier:` — types `@32@0:8q16@24` — IMP `0x100028b64`
  - - `configureWithPlan:selected:formattedPrice:` — types `v36@0:8@16B24@28` — IMP `0x100029554`
  - - `nameLabel` — types `@16@0:8` — IMP `0x100029a58`
  - - `setNameLabel:` — types `v24@0:8@16` — IMP `0x100029a68`
  - - `badgeLabel` — types `@16@0:8` — IMP `0x100029a7c`
  - - `setBadgeLabel:` — types `v24@0:8@16` — IMP `0x100029a8c`
  - - `descLabel` — types `@16@0:8` — IMP `0x100029aa0`
  - - `setDescLabel:` — types `v24@0:8@16` — IMP `0x100029ab0`
  - - `priceLabel` — types `@16@0:8` — IMP `0x100029ac4`
  - - `setPriceLabel:` — types `v24@0:8@16` — IMP `0x100029ad4`
  - - `checkIcon` — types `@16@0:8` — IMP `0x100029ae8`
  - - `setCheckIcon:` — types `v24@0:8@16` — IMP `0x100029af8`
  - - `.cxx_destruct` — types `v16@0:8` — IMP `0x100029b0c`

#### CBSubscriptionStatusCell
- Superclass: `UITableViewCell` · địa chỉ class struct (arm64): `0x10011c498` · instanceSize: 8 · flags: `0x80`
- Instance methods (2):
  - - `initWithStyle:reuseIdentifier:` — types `@32@0:8q16@24` — IMP `0x100029b88`
  - - `configureWithLoading:failed:` — types `v24@0:8B16B20` — IMP `0x100029e58`

#### CBSubscriptionVIPCardCell
- Superclass: `UITableViewCell` · địa chỉ class struct (arm64): `0x10011c4e8` · instanceSize: 80 · flags: `0x184`
- Ivars (9):
  - `_badgeIcon` — type `@"UIImageView"` — offset 8
  - `_titleLabel` — type `@"UILabel"` — offset 16
  - `_statusPillLabel` — type `@"UILabel"` — offset 24
  - `_durationKeyLabel` — type `@"UILabel"` — offset 32
  - `_durationValueLabel` — type `@"UILabel"` — offset 40
  - `_serverExpiryKeyLabel` — type `@"UILabel"` — offset 48
  - `_serverExpiryValueLabel` — type `@"UILabel"` — offset 56
  - `_licenseValidationKeyLabel` — type `@"UILabel"` — offset 64
  - `_licenseValidationValueLabel` — type `@"UILabel"` — offset 72
- Properties (9):
  - `badgeIcon` — attributes `T@"UIImageView",&,N,V_badgeIcon`
  - `titleLabel` — attributes `T@"UILabel",&,N,V_titleLabel`
  - `statusPillLabel` — attributes `T@"UILabel",&,N,V_statusPillLabel`
  - `durationKeyLabel` — attributes `T@"UILabel",&,N,V_durationKeyLabel`
  - `durationValueLabel` — attributes `T@"UILabel",&,N,V_durationValueLabel`
  - `serverExpiryKeyLabel` — attributes `T@"UILabel",&,N,V_serverExpiryKeyLabel`
  - `serverExpiryValueLabel` — attributes `T@"UILabel",&,N,V_serverExpiryValueLabel`
  - `licenseValidationKeyLabel` — attributes `T@"UILabel",&,N,V_licenseValidationKeyLabel`
  - `licenseValidationValueLabel` — attributes `T@"UILabel",&,N,V_licenseValidationValueLabel`
- Instance methods (24):
  - - `initWithStyle:reuseIdentifier:` — types `@32@0:8q16@24` — IMP `0x10002a0b8`
  - - `keyLabel` — types `@16@0:8` — IMP `0x10002af0c`
  - - `valueLabel` — types `@16@0:8` — IMP `0x10002afdc`
  - - `keyValuePairWithKeyLabel:valueLabel:` — types `@32@0:8@16@24` — IMP `0x10002b0c0`
  - - `configureWithExpirationTimestamp:tierName:` — types `v32@0:8Q16@24` — IMP `0x10002b184`
  - - `badgeIcon` — types `@16@0:8` — IMP `0x10002b898`
  - - `setBadgeIcon:` — types `v24@0:8@16` — IMP `0x10002b8a8`
  - - `titleLabel` — types `@16@0:8` — IMP `0x10002b8bc`
  - - `setTitleLabel:` — types `v24@0:8@16` — IMP `0x10002b8cc`
  - - `statusPillLabel` — types `@16@0:8` — IMP `0x10002b8e0`
  - - `setStatusPillLabel:` — types `v24@0:8@16` — IMP `0x10002b8f0`
  - - `durationKeyLabel` — types `@16@0:8` — IMP `0x10002b904`
  - - `setDurationKeyLabel:` — types `v24@0:8@16` — IMP `0x10002b914`
  - - `durationValueLabel` — types `@16@0:8` — IMP `0x10002b928`
  - - `setDurationValueLabel:` — types `v24@0:8@16` — IMP `0x10002b938`
  - - `serverExpiryKeyLabel` — types `@16@0:8` — IMP `0x10002b94c`
  - - `setServerExpiryKeyLabel:` — types `v24@0:8@16` — IMP `0x10002b95c`
  - - `serverExpiryValueLabel` — types `@16@0:8` — IMP `0x10002b970`
  - - `setServerExpiryValueLabel:` — types `v24@0:8@16` — IMP `0x10002b980`
  - - `licenseValidationKeyLabel` — types `@16@0:8` — IMP `0x10002b994`
  - - `setLicenseValidationKeyLabel:` — types `v24@0:8@16` — IMP `0x10002b9a4`
  - - `licenseValidationValueLabel` — types `@16@0:8` — IMP `0x10002b9b8`
  - - `setLicenseValidationValueLabel:` — types `v24@0:8@16` — IMP `0x10002b9c8`
  - - `.cxx_destruct` — types `v16@0:8` — IMP `0x10002b9dc`

#### CBSubscriptionOrderCoordinator
- Superclass: `NSObject` · địa chỉ class struct (arm64): `0x10011c538` · instanceSize: 80 · flags: `0x184`
- Protocols: `SFSafariViewControllerDelegate`
- Ivars (9):
  - `_delegate` — type `@"<CBSubscriptionOrderCoordinatorDelegate>"` — offset 8
  - `_activeOrderId` — type `@"NSString"` — offset 16
  - `_activePaymentUrl` — type `@"NSString"` — offset 24
  - `_activeTierName` — type `@"NSString"` — offset 32
  - `_activeAmountCrypto` — type `@"NSString"` — offset 40
  - `_activeCurrency` — type `@"NSString"` — offset 48
  - `_activeNetwork` — type `@"NSString"` — offset 56
  - `_pollTimer` — type `@"NSTimer"` — offset 64
  - `_safariVC` — type `@"SFSafariViewController"` — offset 72
- Properties (13):
  - `pollTimer` — attributes `T@"NSTimer",&,N,V_pollTimer`
  - `safariVC` — attributes `T@"SFSafariViewController",&,N,V_safariVC`
  - `delegate` — attributes `T@"<CBSubscriptionOrderCoordinatorDelegate>",W,N,V_delegate`
  - `activeOrderId` — attributes `T@"NSString",C,N,V_activeOrderId`
  - `activePaymentUrl` — attributes `T@"NSString",C,N,V_activePaymentUrl`
  - `activeTierName` — attributes `T@"NSString",C,N,V_activeTierName`
  - `activeAmountCrypto` — attributes `T@"NSString",C,N,V_activeAmountCrypto`
  - `activeCurrency` — attributes `T@"NSString",C,N,V_activeCurrency`
  - `activeNetwork` — attributes `T@"NSString",C,N,V_activeNetwork`
  - `hash` — attributes `TQ,R`
  - `superclass` — attributes `T#,R`
  - `description` — attributes `T@"NSString",R,C`
  - `debugDescription` — attributes `T@"NSString",R,C`
- Instance methods (36):
  - - `dealloc` — types `v16@0:8` — IMP `0x10002baa8`
  - - `hasActivePendingOrder` — types `B16@0:8` — IMP `0x10002baf4`
  - - `currentServerBaseURL` — types `@16@0:8` — IMP `0x10002bb8c`
  - - `fetchActivePendingOrderFromServer` — types `v16@0:8` — IMP `0x10002bba0`
  - - `startCheckoutForTier:forceNew:` — types `v28@0:8@16B24` — IMP `0x10002c334`
  - - `resumePayment` — types `v16@0:8` — IMP `0x10002cd98`
  - - `checkStatusManual` — types `v16@0:8` — IMP `0x10002ce40`
  - - `cancelActiveOrderWithCompletion:` — types `v24@0:8@?16` — IMP `0x10002d69c`
  - - `requestCancelPendingOrder` — types `v16@0:8` — IMP `0x10002db7c`
  - - `openPaymentGatewayURL:` — types `v24@0:8@16` — IMP `0x10002dff4`
  - - `safariViewControllerDidFinish:` — types `v24@0:8@16` — IMP `0x10002e0cc`
  - - `startPollingOrderStatus:` — types `v24@0:8@16` — IMP `0x10002e2b8`
  - - `stopPollingOrderStatus` — types `v16@0:8` — IMP `0x10002e368`
  - - `pollTimerFired` — types `v16@0:8` — IMP `0x10002e3fc`
  - - `checkOrderStatusOnce:` — types `v24@0:8@16` — IMP `0x10002e4dc`
  - - `handlePaymentCompletedSuccess` — types `v16@0:8` — IMP `0x10002e978`
  - - `showAlertWithTitle:message:` — types `v32@0:8@16@24` — IMP `0x10002eee8`
  - - `delegate` — types `@16@0:8` — IMP `0x10002efe8`
  - - `setDelegate:` — types `v24@0:8@16` — IMP `0x10002f000`
  - - `activeOrderId` — types `@16@0:8` — IMP `0x10002f00c`
  - - `setActiveOrderId:` — types `v24@0:8@16` — IMP `0x10002f018`
  - - `activePaymentUrl` — types `@16@0:8` — IMP `0x10002f020`
  - - `setActivePaymentUrl:` — types `v24@0:8@16` — IMP `0x10002f02c`
  - - `activeTierName` — types `@16@0:8` — IMP `0x10002f034`
  - - `setActiveTierName:` — types `v24@0:8@16` — IMP `0x10002f040`
  - - `activeAmountCrypto` — types `@16@0:8` — IMP `0x10002f048`
  - - `setActiveAmountCrypto:` — types `v24@0:8@16` — IMP `0x10002f054`
  - - `activeCurrency` — types `@16@0:8` — IMP `0x10002f05c`
  - - `setActiveCurrency:` — types `v24@0:8@16` — IMP `0x10002f068`
  - - `activeNetwork` — types `@16@0:8` — IMP `0x10002f070`
  - - `setActiveNetwork:` — types `v24@0:8@16` — IMP `0x10002f07c`
  - - `pollTimer` — types `@16@0:8` — IMP `0x10002f084`
  - - `setPollTimer:` — types `v24@0:8@16` — IMP `0x10002f08c`
  - - `safariVC` — types `@16@0:8` — IMP `0x10002f098`
  - - `setSafariVC:` — types `v24@0:8@16` — IMP `0x10002f0a0`
  - - `.cxx_destruct` — types `v16@0:8` — IMP `0x10002f0ac`

#### CBLocalization
- Superclass: `NSObject` · địa chỉ class struct (arm64): `0x10011c588` · instanceSize: 48 · flags: `0x184`
- Ivars (5):
  - `_activeLanguageCode` — type `@"NSString"` — offset 8
  - `_cachedStringTables` — type `@"NSMutableDictionary"` — offset 16
  - `_activeLanguageTable` — type `@"NSDictionary"` — offset 24
  - `_viTable` — type `@"NSDictionary"` — offset 32
  - `_enTable` — type `@"NSDictionary"` — offset 40
- Instance methods (6):
  - - `init` — types `@16@0:8` — IMP `0x10002fa80`
  - - `reloadLanguage` — types `v16@0:8` — IMP `0x100030888`
  - - `activeLanguageCode` — types `@16@0:8` — IMP `0x100030da0`
  - - `stringTableForLanguageCode:` — types `@24@0:8@16` — IMP `0x100030fcc`
  - - `localizedStringForKey:` — types `@24@0:8@16` — IMP `0x1000313e0`
  - - `.cxx_destruct` — types `v16@0:8` — IMP `0x1000314f4`
- Class methods (7):
  - + `sharedInstance` — types `@16@0:8` — IMP `0x10002fa14`
  - + `speechVoiceLanguageCode` — types `@16@0:8` — IMP `0x10002fba8`
  - + `supportedLanguages` — types `@16@0:8` — IMP `0x10002fe9c`
  - + `displayNameForLanguageCode:` — types `@24@0:8@16` — IMP `0x10003057c`
  - + `currentLanguageCode` — types `@16@0:8` — IMP `0x100030d44`
  - + `setCurrentLanguageCode:` — types `v24@0:8@16` — IMP `0x100030de4`
  - + `localizedStringForKey:` — types `@24@0:8@16` — IMP `0x10003135c`

#### CBSplitSplashScreenView
- Superclass: `UIView` · địa chỉ class struct (arm64): `0x10011c5d8` · instanceSize: 112 · flags: `0x184`
- Ivars (14):
  - `_glowImageView` — type `@"UIImageView"` — offset 8
  - `_horizonLineView` — type `@"UIView"` — offset 16
  - `_horizonGradient` — type `@"CAGradientLayer"` — offset 24
  - `_horizonDashedMask` — type `@"CAShapeLayer"` — offset 32
  - `_logoImageView` — type `@"UIImageView"` — offset 40
  - `_trackView` — type `@"UIView"` — offset 48
  - `_progressView` — type `@"UIView"` — offset 56
  - `_progressGradient` — type `@"CAGradientLayer"` — offset 64
  - `_badgeLabel` — type `@"UILabel"` — offset 72
  - `_isDismissing` — type `B` — offset 80
  - `_hasStartedAnimation` — type `B` — offset 81
  - `_animationStartTime` — type `d` — offset 88
  - `_onWillDismiss` — type `@?` — offset 96
  - `_onDismissed` — type `@?` — offset 104
- Properties (3):
  - `isDismissing` — attributes `TB,R,N`
  - `onWillDismiss` — attributes `T@?,C,N,V_onWillDismiss`
  - `onDismissed` — attributes `T@?,C,N,V_onDismissed`
- Instance methods (13):
  - - `initWithFrame:` — types `@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16` — IMP `0x100056b94`
  - - `layoutSubviews` — types `v16@0:8` — IMP `0x100057818`
  - - `startLoadingAnimation` — types `v16@0:8` — IMP `0x100057bf8`
  - - `handleTap:` — types `v24@0:8@16` — IMP `0x100057e20`
  - - `isDismissing` — types `B16@0:8` — IMP `0x100057ea8`
  - - `dismissAnimated:` — types `v20@0:8B16` — IMP `0x100057eb8`
  - - `dismissAnimated:completion:` — types `v28@0:8B16@?20` — IMP `0x100057ec8`
  - - `dealloc` — types `v16@0:8` — IMP `0x100058160`
  - - `onWillDismiss` — types `@?16@0:8` — IMP `0x100058244`
  - - `setOnWillDismiss:` — types `v24@0:8@?16` — IMP `0x100058254`
  - - `onDismissed` — types `@?16@0:8` — IMP `0x100058260`
  - - `setOnDismissed:` — types `v24@0:8@?16` — IMP `0x100058270`
  - - `.cxx_destruct` — types `v16@0:8` — IMP `0x10005827c`
- Class methods (3):
  - + `logoImage` — types `@16@0:8` — IMP `0x100055f14`
  - + `appIconImage` — types `@16@0:8` — IMP `0x1000566f8`
  - + `radialGlowImageForDiameter:` — types `@24@0:8d16` — IMP `0x1000568dc`

#### CBHttpClient
- Superclass: `NSObject` · địa chỉ class struct (arm64): `0x10011c628` · instanceSize: 16 · flags: `0x184`
- Ivars (1):
  - `_networkQueue` — type `@"NSObject<OS_dispatch_queue>"` — offset 8
- Properties (1):
  - `networkQueue` — attributes `T@"NSObject<OS_dispatch_queue>",&,N,V_networkQueue`
- Instance methods (6):
  - - `init` — types `@16@0:8` — IMP `0x1000583dc`
  - - `postJSON:toURL:timeout:customHeaders:completion:` — types `v56@0:8@16@24d32@40@?48` — IMP `0x100058444`
  - - `getJSONFromURL:timeout:customHeaders:completion:` — types `v48@0:8@16d24@32@?40` — IMP `0x100058b2c`
  - - `networkQueue` — types `@16@0:8` — IMP `0x100059114`
  - - `setNetworkQueue:` — types `v24@0:8@16` — IMP `0x10005911c`
  - - `.cxx_destruct` — types `v16@0:8` — IMP `0x100059128`
- Class methods (1):
  - + `sharedClient` — types `@16@0:8` — IMP `0x100058370`

#### CBLicenseSyncManager
- Superclass: `NSObject` · địa chỉ class struct (arm64): `0x10011c678` · instanceSize: 32 · flags: `0x184`
- Ivars (3):
  - `_isSyncing` — type `B` — offset 8
  - `_syncQueue` — type `@"NSObject<OS_dispatch_queue>"` — offset 16
  - `_lastAttemptTimestamp` — type `Q` — offset 24
- Properties (3):
  - `isSyncing` — attributes `TB,N,V_isSyncing`
  - `syncQueue` — attributes `T@"NSObject<OS_dispatch_queue>",&,N,V_syncQueue`
  - `lastAttemptTimestamp` — attributes `TQ,N,V_lastAttemptTimestamp`
- Instance methods (24):
  - - `init` — types `@16@0:8` — IMP `0x1000591a0`
  - - `deviceHardwareHashHex` — types `@16@0:8` — IMP `0x10005920c`
  - - `isLicenseCurrentlyValid` — types `B16@0:8` — IMP `0x10005a7c0`
  - - `remainingLicenseSeconds` — types `Q16@0:8` — IMP `0x10006cba4`
  - - `isCarPlayScreenConnected` — types `B16@0:8` — IMP `0x10007f590`
  - - `checkAndSyncLicenseIfNeeded` — types `v16@0:8` — IMP `0x10007f5b4`
  - - `checkAndSyncLicenseIfNeededWithSource:` — types `v24@0:8@16` — IMP `0x10007f654`
  - - `forceSyncWithCompletion:` — types `v24@0:8@?16` — IMP `0x100091e70`
  - - `resolvedBackendBaseURL` — types `@16@0:8` — IMP `0x100092a74`
  - - `resolvedLicenseServerEndpoint` — types `@16@0:8` — IMP `0x100092a88`
  - - `performSyncWithForce:isManualUserAction:completion:` — types `v32@0:8B16B20@?24` — IMP `0x100092b64`
  - - `performSyncWithForce:isManualUserAction:source:completion:` — types `v40@0:8B16B20@24@?32` — IMP `0x100092bf4`
  - - `installAndVerifyLicensePayload:errorMsg:` — types `B32@0:8@16^@24` — IMP `0x100094078`
  - - `actualLicenseExpirationTimestamp` — types `Q16@0:8` — IMP `0x1000a0624`
  - - `setActualLicenseExpirationTimestamp:` — types `v24@0:8Q16` — IMP `0x1000a07e8`
  - - `actualLicenseTierName` — types `@16@0:8` — IMP `0x1000a0984`
  - - `setActualLicenseTierName:` — types `v24@0:8@16` — IMP `0x1000a0acc`
  - - `isSyncing` — types `B16@0:8` — IMP `0x1000a0c54`
  - - `setIsSyncing:` — types `v20@0:8B16` — IMP `0x1000a0c5c`
  - - `syncQueue` — types `@16@0:8` — IMP `0x1000a0c64`
  - - `setSyncQueue:` — types `v24@0:8@16` — IMP `0x1000a0c6c`
  - - `lastAttemptTimestamp` — types `Q16@0:8` — IMP `0x1000a0c78`
  - - `setLastAttemptTimestamp:` — types `v24@0:8Q16` — IMP `0x1000a0c80`
  - - `.cxx_destruct` — types `v16@0:8` — IMP `0x1000a0c88`
- Class methods (6):
  - + `sharedInstance` — types `@16@0:8` — IMP `0x100059134`
  - + `isCarPlayScreen:` — types `B24@0:8@16` — IMP `0x10007ef6c`
  - + `isCarPlayScreenConnectedExcludingScreen:` — types `B24@0:8@16` — IMP `0x10007f1c0`
  - + `isCarPlayScreenConnected` — types `B16@0:8` — IMP `0x10007f580`
  - + `formatBaseURLString:` — types `@24@0:8@16` — IMP `0x100091f8c`
  - + `resolvedBackendBaseURL` — types `@16@0:8` — IMP `0x10009231c`

#### Protocols của DuoFaceUI (16)

#### Protocol NSObject
- Instance methods (19):
  - `isEqual:` — types `B24@0:8@16`
  - `class` — types `#16@0:8`
  - `self` — types `@16@0:8`
  - `performSelector:` — types `@24@0:8:16`
  - `performSelector:withObject:` — types `@32@0:8:16@24`
  - `performSelector:withObject:withObject:` — types `@40@0:8:16@24@32`
  - `isProxy` — types `B16@0:8`
  - `isKindOfClass:` — types `B24@0:8#16`
  - `isMemberOfClass:` — types `B24@0:8#16`
  - `conformsToProtocol:` — types `B24@0:8@16`
  - `respondsToSelector:` — types `B24@0:8:16`
  - `retain` — types `@16@0:8`
  - `release` — types `Vv16@0:8`
  - `autorelease` — types `@16@0:8`
  - `retainCount` — types `Q16@0:8`
  - `zone` — types `^{_NSZone=}16@0:8`
  - `hash` — types `Q16@0:8`
  - `superclass` — types `#16@0:8`
  - `description` — types `@16@0:8`
- Optional instance methods (1):
  - `debugDescription` — types `@16@0:8`
- Instance properties: `hash`, `superclass`, `description`, `debugDescription`

#### Protocol UIApplicationDelegate
- Kế thừa protocols: NSObject
- Optional instance methods (55):
  - `applicationDidFinishLaunching:` — types `v24@0:8@16`
  - `application:willFinishLaunchingWithOptions:` — types `B32@0:8@16@24`
  - `application:didFinishLaunchingWithOptions:` — types `B32@0:8@16@24`
  - `applicationDidBecomeActive:` — types `v24@0:8@16`
  - `applicationWillResignActive:` — types `v24@0:8@16`
  - `application:handleOpenURL:` — types `B32@0:8@16@24`
  - `application:openURL:sourceApplication:annotation:` — types `B48@0:8@16@24@32@40`
  - `application:openURL:options:` — types `B40@0:8@16@24@32`
  - `applicationDidReceiveMemoryWarning:` — types `v24@0:8@16`
  - `applicationWillTerminate:` — types `v24@0:8@16`
  - `applicationSignificantTimeChange:` — types `v24@0:8@16`
  - `application:willChangeStatusBarOrientation:duration:` — types `v40@0:8@16q24d32`
  - `application:didChangeStatusBarOrientation:` — types `v32@0:8@16q24`
  - `application:willChangeStatusBarFrame:` — types `v56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24`
  - `application:didChangeStatusBarFrame:` — types `v56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24`
  - `application:didRegisterUserNotificationSettings:` — types `v32@0:8@16@24`
  - `application:didRegisterForRemoteNotificationsWithDeviceToken:` — types `v32@0:8@16@24`
  - `application:didFailToRegisterForRemoteNotificationsWithError:` — types `v32@0:8@16@24`
  - `application:didReceiveRemoteNotification:` — types `v32@0:8@16@24`
  - `application:didReceiveLocalNotification:` — types `v32@0:8@16@24`
  - `application:handleActionWithIdentifier:forLocalNotification:completionHandler:` — types `v48@0:8@16@24@32@?40`
  - `application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:` — types `v56@0:8@16@24@32@40@?48`
  - `application:handleActionWithIdentifier:forRemoteNotification:completionHandler:` — types `v48@0:8@16@24@32@?40`
  - `application:handleActionWithIdentifier:forLocalNotification:withResponseInfo:completionHandler:` — types `v56@0:8@16@24@32@40@?48`
  - `application:didReceiveRemoteNotification:fetchCompletionHandler:` — types `v40@0:8@16@24@?32`
  - `application:performFetchWithCompletionHandler:` — types `v32@0:8@16@?24`
  - `application:performActionForShortcutItem:completionHandler:` — types `v40@0:8@16@24@?32`
  - `application:handleEventsForBackgroundURLSession:completionHandler:` — types `v40@0:8@16@24@?32`
  - `application:handleWatchKitExtensionRequest:reply:` — types `v40@0:8@16@24@?32`
  - `applicationShouldRequestHealthAuthorization:` — types `v24@0:8@16`
  - `application:handlerForIntent:` — types `@32@0:8@16@24`
  - `application:handleIntent:completionHandler:` — types `v40@0:8@16@24@?32`
  - `applicationDidEnterBackground:` — types `v24@0:8@16`
  - `applicationWillEnterForeground:` — types `v24@0:8@16`
  - `applicationProtectedDataWillBecomeUnavailable:` — types `v24@0:8@16`
  - `applicationProtectedDataDidBecomeAvailable:` — types `v24@0:8@16`
  - `application:supportedInterfaceOrientationsForWindow:` — types `Q32@0:8@16@24`
  - `application:shouldAllowExtensionPointIdentifier:` — types `B32@0:8@16@24`
  - `application:viewControllerWithRestorationIdentifierPath:coder:` — types `@40@0:8@16@24@32`
  - `application:shouldSaveSecureApplicationState:` — types `B32@0:8@16@24`
  - `application:shouldRestoreSecureApplicationState:` — types `B32@0:8@16@24`
  - `application:willEncodeRestorableStateWithCoder:` — types `v32@0:8@16@24`
  - `application:didDecodeRestorableStateWithCoder:` — types `v32@0:8@16@24`
  - `application:shouldSaveApplicationState:` — types `B32@0:8@16@24`
  - `application:shouldRestoreApplicationState:` — types `B32@0:8@16@24`
  - `application:willContinueUserActivityWithType:` — types `B32@0:8@16@24`
  - `application:continueUserActivity:restorationHandler:` — types `B40@0:8@16@24@?32`
  - `application:didFailToContinueUserActivityWithType:error:` — types `v40@0:8@16@24@32`
  - `application:didUpdateUserActivity:` — types `v32@0:8@16@24`
  - `application:userDidAcceptCloudKitShareWithMetadata:` — types `v32@0:8@16@24`
  - `application:configurationForConnectingSceneSession:options:` — types `@40@0:8@16@24@32`
  - `application:didDiscardSceneSessions:` — types `v32@0:8@16@24`
  - `applicationShouldAutomaticallyLocalizeKeyCommands:` — types `B24@0:8@16`
  - `window` — types `@16@0:8`
  - `setWindow:` — types `v24@0:8@16`
- Instance properties: `window`

#### Protocol UITableViewDataSource
- Kế thừa protocols: NSObject
- Instance methods (2):
  - `tableView:numberOfRowsInSection:` — types `q32@0:8@16q24`
  - `tableView:cellForRowAtIndexPath:` — types `@32@0:8@16@24`
- Optional instance methods (9):
  - `numberOfSectionsInTableView:` — types `q24@0:8@16`
  - `tableView:titleForHeaderInSection:` — types `@32@0:8@16q24`
  - `tableView:titleForFooterInSection:` — types `@32@0:8@16q24`
  - `tableView:canEditRowAtIndexPath:` — types `B32@0:8@16@24`
  - `tableView:canMoveRowAtIndexPath:` — types `B32@0:8@16@24`
  - `sectionIndexTitlesForTableView:` — types `@24@0:8@16`
  - `tableView:sectionForSectionIndexTitle:atIndex:` — types `q40@0:8@16@24q32`
  - `tableView:commitEditingStyle:forRowAtIndexPath:` — types `v40@0:8@16q24@32`
  - `tableView:moveRowAtIndexPath:toIndexPath:` — types `v40@0:8@16@24@32`

#### Protocol UIScrollViewDelegate
- Kế thừa protocols: NSObject
- Optional instance methods (14):
  - `scrollViewDidScroll:` — types `v24@0:8@16`
  - `scrollViewDidZoom:` — types `v24@0:8@16`
  - `scrollViewWillBeginDragging:` — types `v24@0:8@16`
  - `scrollViewWillEndDragging:withVelocity:targetContentOffset:` — types `v48@0:8@16{CGPoint=dd}24N^{CGPoint=dd}40`
  - `scrollViewDidEndDragging:willDecelerate:` — types `v28@0:8@16B24`
  - `scrollViewWillBeginDecelerating:` — types `v24@0:8@16`
  - `scrollViewDidEndDecelerating:` — types `v24@0:8@16`
  - `scrollViewDidEndScrollingAnimation:` — types `v24@0:8@16`
  - `viewForZoomingInScrollView:` — types `@24@0:8@16`
  - `scrollViewWillBeginZooming:withView:` — types `v32@0:8@16@24`
  - `scrollViewDidEndZooming:withView:atScale:` — types `v40@0:8@16@24d32`
  - `scrollViewShouldScrollToTop:` — types `B24@0:8@16`
  - `scrollViewDidScrollToTop:` — types `v24@0:8@16`
  - `scrollViewDidChangeAdjustedContentInset:` — types `v24@0:8@16`

#### Protocol UITableViewDelegate
- Kế thừa protocols: NSObject, UIScrollViewDelegate
- Optional instance methods (53):
  - `tableView:willDisplayCell:forRowAtIndexPath:` — types `v40@0:8@16@24@32`
  - `tableView:willDisplayHeaderView:forSection:` — types `v40@0:8@16@24q32`
  - `tableView:willDisplayFooterView:forSection:` — types `v40@0:8@16@24q32`
  - `tableView:didEndDisplayingCell:forRowAtIndexPath:` — types `v40@0:8@16@24@32`
  - `tableView:didEndDisplayingHeaderView:forSection:` — types `v40@0:8@16@24q32`
  - `tableView:didEndDisplayingFooterView:forSection:` — types `v40@0:8@16@24q32`
  - `tableView:heightForRowAtIndexPath:` — types `d32@0:8@16@24`
  - `tableView:heightForHeaderInSection:` — types `d32@0:8@16q24`
  - `tableView:heightForFooterInSection:` — types `d32@0:8@16q24`
  - `tableView:estimatedHeightForRowAtIndexPath:` — types `d32@0:8@16@24`
  - `tableView:estimatedHeightForHeaderInSection:` — types `d32@0:8@16q24`
  - `tableView:estimatedHeightForFooterInSection:` — types `d32@0:8@16q24`
  - `tableView:viewForHeaderInSection:` — types `@32@0:8@16q24`
  - `tableView:viewForFooterInSection:` — types `@32@0:8@16q24`
  - `tableView:accessoryTypeForRowWithIndexPath:` — types `q32@0:8@16@24`
  - `tableView:accessoryButtonTappedForRowWithIndexPath:` — types `v32@0:8@16@24`
  - `tableView:shouldHighlightRowAtIndexPath:` — types `B32@0:8@16@24`
  - `tableView:didHighlightRowAtIndexPath:` — types `v32@0:8@16@24`
  - `tableView:didUnhighlightRowAtIndexPath:` — types `v32@0:8@16@24`
  - `tableView:willSelectRowAtIndexPath:` — types `@32@0:8@16@24`
  - `tableView:willDeselectRowAtIndexPath:` — types `@32@0:8@16@24`
  - `tableView:didSelectRowAtIndexPath:` — types `v32@0:8@16@24`
  - `tableView:didDeselectRowAtIndexPath:` — types `v32@0:8@16@24`
  - `tableView:canPerformPrimaryActionForRowAtIndexPath:` — types `B32@0:8@16@24`
  - `tableView:performPrimaryActionForRowAtIndexPath:` — types `v32@0:8@16@24`
  - `tableView:editingStyleForRowAtIndexPath:` — types `q32@0:8@16@24`
  - `tableView:titleForDeleteConfirmationButtonForRowAtIndexPath:` — types `@32@0:8@16@24`
  - `tableView:editActionsForRowAtIndexPath:` — types `@32@0:8@16@24`
  - `tableView:leadingSwipeActionsConfigurationForRowAtIndexPath:` — types `@32@0:8@16@24`
  - `tableView:trailingSwipeActionsConfigurationForRowAtIndexPath:` — types `@32@0:8@16@24`
  - `tableView:shouldIndentWhileEditingRowAtIndexPath:` — types `B32@0:8@16@24`
  - `tableView:willBeginEditingRowAtIndexPath:` — types `v32@0:8@16@24`
  - `tableView:didEndEditingRowAtIndexPath:` — types `v32@0:8@16@24`
  - `tableView:targetIndexPathForMoveFromRowAtIndexPath:toProposedIndexPath:` — types `@40@0:8@16@24@32`
  - `tableView:indentationLevelForRowAtIndexPath:` — types `q32@0:8@16@24`
  - `tableView:shouldShowMenuForRowAtIndexPath:` — types `B32@0:8@16@24`
  - `tableView:canPerformAction:forRowAtIndexPath:withSender:` — types `B48@0:8@16:24@32@40`
  - `tableView:performAction:forRowAtIndexPath:withSender:` — types `v48@0:8@16:24@32@40`
  - `tableView:canFocusRowAtIndexPath:` — types `B32@0:8@16@24`
  - `tableView:shouldUpdateFocusInContext:` — types `B32@0:8@16@24`
  - `tableView:didUpdateFocusInContext:withAnimationCoordinator:` — types `v40@0:8@16@24@32`
  - `indexPathForPreferredFocusedViewInTableView:` — types `@24@0:8@16`
  - `tableView:selectionFollowsFocusForRowAtIndexPath:` — types `B32@0:8@16@24`
  - `tableView:shouldSpringLoadRowAtIndexPath:withContext:` — types `B40@0:8@16@24@32`
  - `tableView:shouldBeginMultipleSelectionInteractionAtIndexPath:` — types `B32@0:8@16@24`
  - `tableView:didBeginMultipleSelectionInteractionAtIndexPath:` — types `v32@0:8@16@24`
  - `tableViewDidEndMultipleSelectionInteraction:` — types `v24@0:8@16`
  - `tableView:contextMenuConfigurationForRowAtIndexPath:point:` — types `@48@0:8@16@24{CGPoint=dd}32`
  - `tableView:previewForHighlightingContextMenuWithConfiguration:` — types `@32@0:8@16@24`
  - `tableView:previewForDismissingContextMenuWithConfiguration:` — types `@32@0:8@16@24`
  - `tableView:willPerformPreviewActionForMenuWithConfiguration:animator:` — types `v40@0:8@16@24@32`
  - `tableView:willDisplayContextMenuWithConfiguration:animator:` — types `v40@0:8@16@24@32`
  - `tableView:willEndContextMenuInteractionWithConfiguration:animator:` — types `v40@0:8@16@24@32`

#### Protocol UISearchResultsUpdating
- Kế thừa protocols: NSObject
- Instance methods (1):
  - `updateSearchResultsForSearchController:` — types `v24@0:8@16`
- Optional instance methods (1):
  - `updateSearchResultsForSearchController:selectingSearchSuggestion:` — types `v32@0:8@16@24`

#### Protocol UIBarPositioningDelegate
- Kế thừa protocols: NSObject
- Optional instance methods (1):
  - `positionForBar:` — types `q24@0:8@16`

#### Protocol UISearchBarDelegate
- Kế thừa protocols: UIBarPositioningDelegate
- Optional instance methods (11):
  - `searchBarShouldBeginEditing:` — types `B24@0:8@16`
  - `searchBarTextDidBeginEditing:` — types `v24@0:8@16`
  - `searchBarShouldEndEditing:` — types `B24@0:8@16`
  - `searchBarTextDidEndEditing:` — types `v24@0:8@16`
  - `searchBar:textDidChange:` — types `v32@0:8@16@24`
  - `searchBar:shouldChangeTextInRange:replacementText:` — types `B48@0:8@16{_NSRange=QQ}24@40`
  - `searchBarSearchButtonClicked:` — types `v24@0:8@16`
  - `searchBarBookmarkButtonClicked:` — types `v24@0:8@16`
  - `searchBarCancelButtonClicked:` — types `v24@0:8@16`
  - `searchBarResultsListButtonClicked:` — types `v24@0:8@16`
  - `searchBar:selectedScopeButtonIndexDidChange:` — types `v32@0:8@16q24`

#### Protocol UITextFieldDelegate
- Kế thừa protocols: NSObject
- Optional instance methods (12):
  - `textFieldShouldBeginEditing:` — types `B24@0:8@16`
  - `textFieldDidBeginEditing:` — types `v24@0:8@16`
  - `textFieldShouldEndEditing:` — types `B24@0:8@16`
  - `textFieldDidEndEditing:` — types `v24@0:8@16`
