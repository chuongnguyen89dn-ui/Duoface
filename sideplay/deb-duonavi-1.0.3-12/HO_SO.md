# HỒ SƠ QUÉT TĨNH TẬN GỐC — DuoNavi 1.0.3-12 (gói `com.duonavi.app`)

- **Ngày quét:** 05/11/2026
- **Đối tượng:** đúng 1 file deb gốc (mục 1.1). Mọi kết quả trong hồ sơ này chỉ thuộc về file này.
- **Phương pháp:** phân tích tĩnh **chỉ đọc** — bóc gói bằng `dpkg-deb -x/-e`, đọc control/scripts, parse Mach-O bằng parser tự viết (load commands, symtab, exports trie, code signature, metadata Objective-C gồm class/method/property/ivar, bind opcodes của LC_DYLD_INFO và imports của LC_DYLD_CHAINED_FIXUPS để khôi phục superclass/classrefs), trích chuỗi bằng `strings`. **Không chạy/không nạp bất kỳ binary, dylib hay script nào trích từ gói** (kể cả maintainer scripts — chỉ đọc nội dung).
- **Quy ước mức bằng chứng:** mỗi nhận định cơ chế đều ghi căn cứ: *(symbol)* = tên hàm/biến trong symtab; *(chuỗi)* = chuỗi tĩnh trong binary; *(metadata)* = metadata Objective-C; *(plist)* = file cấu hình kèm gói; *(script)* = nội dung maintainer script. Chỗ nào không đọc được/không chắc được ghi thẳng vào Mục 10, không suy đoán thay số liệu.

---

## 1. Định danh gói

### 1.1 File deb

| Trường | Giá trị |
|---|---|
| Tên file | `com.duonavi.app_1.0.3-12_border-focus-red3_iphoneos-arm64.deb` |
| Kích thước | 2.048.980 bytes |
| SHA256 | `3e32825ccab63ce06f2ba02f4d629ad86d96a7d801e29858954a378c3bb35915` (đã kiểm lại bằng `sha256sum`, khớp) |
| Định dạng | Debian package version 2.0; control archive 1.552 bytes; Installed-Size khai báo 10.253 (KiB) |

### 1.2 Toàn bộ file `control`

```
Package: com.duonavi.app
Name: DuoFace
Description: DuoFace full-payload rootless test, runtime and signature unverified.
Maintainer: DuoFace Team
Author: DuoFace Team
Section: Tweaks
Depends: mobilesubstrate (>= 0.9.5000), firmware (>= 13.0)
Architecture: iphoneos-arm64
Version: 1.0.3-12+border-focus-red3
```

- Không có các trường `Conflicts`, `Replaces`, `Provides`, `Pre-Depends`, `Icon` trong control.
- Lưu ý: tên hiển thị (Name/Description) là **DuoFace**, còn Package ID là `com.duonavi.app` và Version là `1.0.3-12+border-focus-red3` — tức hậu tố build `border-focus-red3` nằm trong trường Version của gói, ngoài phần `1.0.3-12`.

### 1.3 Maintainer scripts

Gói có đúng 2 script: `postinst` (2.956 bytes, 82 dòng) và `prerm` (75 bytes, 3 dòng). Không có `preinst`, `postrm`, `extrainst_`.

#### 1.3.1 `postinst` — nội dung đầy đủ

```sh
#!/bin/sh
set -e

# Fix tweak preference and state permissions
chmod 0666 /var/jb/Library/MobileSubstrate/DynamicLibraries/CarBridgeDashboard.plist 2>/dev/null || true
chmod 0666 /Library/MobileSubstrate/DynamicLibraries/CarBridgeDashboard.plist 2>/dev/null || true
chmod 0666 /var/tmp/com.duoface.bridgestate.plist 2>/dev/null || true
chmod 0666 /var/tmp/com.tiz.carbridge.bridgestate.plist 2>/dev/null || true

# Set setuid root permissions for root helper tool
chown 0:0 /var/jb/usr/libexec/duoface_cboptimize_helper 2>/dev/null || true
chmod 4755 /var/jb/usr/libexec/duoface_cboptimize_helper 2>/dev/null || true
chown 0:0 /var/jb/usr/libexec/duoface_cboptimize_helper 2>/dev/null || true
chmod 4755 /var/jb/usr/libexec/duoface_cboptimize_helper 2>/dev/null || true

# Set sudoers drop-in permissions if present
chown 0:0 /var/jb/etc/sudoers.d/duoface /var/jb/etc/sudoers.d/carbridge 2>/dev/null || true
chmod 0440 /var/jb/etc/sudoers.d/duoface /var/jb/etc/sudoers.d/carbridge 2>/dev/null || true

# Auto-initialize initial settings for fresh jailbroken devices
PREF_FILE="/var/mobile/Library/Preferences/com.duoface.plist"
LEGACY_PREF_FILE="/var/mobile/Library/Preferences/com.tiz.carbridge.plist"
if [ ! -f "$PREF_FILE" ] && [ -f "$LEGACY_PREF_FILE" ]; then
    cp "$LEGACY_PREF_FILE" "$PREF_FILE" 2>/dev/null || true
fi
if [ ! -f "$PREF_FILE" ]; then
    cat << 'EOF' > "$PREF_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>bridgedApps</key>
	<array>
		<string>com.google.Maps</string>
		<string>com.apple.Maps</string>
		<string>com.google.ios.youtube</string>
		<string>com.apple.Music</string>
		<string>com.apple.podcasts</string>
		<string>com.apple.tv</string>
		<string>com.ss.iphone.ugc.Ame</string>
		<string>com.ss.iphone.ugc.tiktok.lite</string>
		<string>vn.com.vng.zingalo</string>
	</array>
	<key>userAppsDefaultInitialized</key>
	<true/>
	<key>splitScreenEnabled</key>
	<true/>
	<key>autoLaunchOnConnect</key>
	<true/>
	<key>autoLaunchBundleID</key>
	<string>com.apple.BarcodeScanner</string>
	<key>systemOptimizerEnabled</key>
	<true/>
</dict>
</plist>
EOF
    chown 501:501 "$PREF_FILE" 2>/dev/null || true
    chmod 0644 "$PREF_FILE" 2>/dev/null || true
fi

# Preserve all helper files; do not alter unrelated iOS daemons or delete logs.

# Refresh SpringBoard & LaunchServices Icon / App cache
if command -v uicache >/dev/null 2>&1; then
    uicache -a 2>/dev/null || true
elif [ -x /var/jb/usr/bin/uicache ]; then
    /var/jb/usr/bin/uicache -a 2>/dev/null || true
elif [ -x /usr/bin/uicache ]; then
    /usr/bin/uicache -a 2>/dev/null || true
fi

if [ -n "${CYDIA:-}" ]; then
    read -r finish_fd finish_ver <<EOF
$CYDIA
EOF
    case "$finish_fd" in
        [0-9]|[0-9][0-9]) case "$finish_ver" in
            [1-9]*) echo 'finish:restart' >&$finish_fd ;;
        esac ;;
    esac
fi
exit 0
```

#### 1.3.2 `postinst` — hành vi, tách từng khối

1. **Mở quyền ghi file trạng thái (0666 — mọi user đều đọc/ghi được):**
   - `CarBridgeDashboard.plist` (cả đường rootless `/var/jb/...` lẫn rootful `/Library/...`) — lưu ý đây là tên **CarBridge**, không phải tên file filter `DuoFaceDashboard.plist` mà gói này cài (xem Mục 2); file `CarBridgeDashboard.plist` không nằm trong gói này.
   - `/var/tmp/com.duoface.bridgestate.plist` và file legacy `/var/tmp/com.tiz.carbridge.bridgestate.plist` — đây là **file trạng thái liên tiến trình** của tweak (xem Mục 7.3).
2. **Đặt setuid-root cho helper:** `chown 0:0` + `chmod 4755` lên `/var/jb/usr/libexec/duoface_cboptimize_helper` (lặp lại nguyên khối 2 lần giống hệt nhau). Helper này phân tích ở Mục 3.5/7.6.
3. **Sudoers:** đặt owner root + `0440` cho `/var/jb/etc/sudoers.d/duoface` (có trong gói) và `/var/jb/etc/sudoers.d/carbridge` (**không** có trong gói này — chỉ xử lý "nếu tồn tại"). Nội dung drop-in `duoface` kèm gói là một dòng duy nhất: `ALL ALL=(ALL) NOPASSWD: ALL` — tức mọi user được chạy mọi lệnh qua sudo không cần mật khẩu *(plist/file, xem Mục 2)*.
4. **Khởi tạo preferences lần đầu:** nếu chưa có `/var/mobile/Library/Preferences/com.duoface.plist` thì (a) sao chép từ file legacy `com.tiz.carbridge.plist` nếu có; (b) nếu vẫn chưa có thì ghi file mặc định với các key ở Mục 8.2, owner `501:501` (mobile), quyền 0644.
5. **Làm mới icon/cache:** chạy `uicache -a` (tìm theo thứ tự PATH → `/var/jb/usr/bin/uicache` → `/usr/bin/uicache`).
6. **Báo trình quản lý gói:** nếu biến môi trường `CYDIA` có mặt, gửi `finish:restart` (yêu cầu respring) qua fd của Cydia.
7. Mọi lệnh đều có `2>/dev/null || true` — lỗi ở từng bước bị bỏ qua, `set -e` thực tế không chặn được gì.

#### 1.3.3 `prerm` — nội dung đầy đủ

```sh
#!/bin/sh
# No system-wide daemon state is changed by this package.
exit 0
```

Không làm gì khi gỡ gói: không xóa preferences, không xóa file trạng thái `/var/tmp`, không khôi phục daemon đã bị "optimize" tắt (Mục 7.6), không gỡ sudoers ngoài việc dpkg tự gỡ file theo danh sách gói.

---

## 2. Cây file 100% (data.tar)

Tổng: **37 file thường, 0 symlink, 0 thư mục rỗng đáng chú ý ngoài cây chuẩn**. Mọi đường dẫn đều nằm dưới tiền tố rootless `/var/jb/` trừ 1 file preferences nằm ở `/var/mobile/...`.

| # | Đường dẫn | Kích thước (bytes) | SHA256 |
|---|---|---|---|
| 1 | `/var/jb/Applications/DuoFaceUI.app/AppIcon29x29.png` | 1625 | `71debbd1ec86ddc0f81ec912b81270cd015e0cbc72b21ba4657d7a89a65c9b66` |
| 2 | `/var/jb/Applications/DuoFaceUI.app/AppIcon29x29@2x.png` | 4927 | `7cd2974d10f2ec892957a0e5995f43e81ba0d73efe701d45719765cc57de77cf` |
| 3 | `/var/jb/Applications/DuoFaceUI.app/AppIcon29x29@3x.png` | 9504 | `444a05ca1cf748cfd7440fa390e758d3a2e9e365701d3c9787374ae055171295` |
| 4 | `/var/jb/Applications/DuoFaceUI.app/AppIcon40x40.png` | 2650 | `9934e080e8d4fe2c7c1ee5feda7f3d1b0ceeabf8dd65834d03fa0baadd49d1ed` |
| 5 | `/var/jb/Applications/DuoFaceUI.app/AppIcon40x40@2x.png` | 8309 | `9ab7dc6d37efbed691648cf545ffd490125e24d1a78a3f11043b167c780f5ff6` |
| 6 | `/var/jb/Applications/DuoFaceUI.app/AppIcon40x40@3x.png` | 16021 | `ca2e7402c268eb08ecb031b24bce4fd8c9bfde7c169431f7aa860070e6964e7d` |
| 7 | `/var/jb/Applications/DuoFaceUI.app/AppIcon50x50.png` | 3845 | `a3d6c1fb86f75aab76dda4dd51368ab903f23cd98be1522edab6a684d23ff420` |
| 8 | `/var/jb/Applications/DuoFaceUI.app/AppIcon50x50@2x.png` | 11898 | `a0b2483b684eec28c813a0ba13bf25700c240681905cfd26e86320c96f7a063c` |
| 9 | `/var/jb/Applications/DuoFaceUI.app/AppIcon57x57.png` | 4818 | `02954587d7cff643f4805a79df90da4c5d5a4eb7ab5026eb71698b42af85ee52` |
| 10 | `/var/jb/Applications/DuoFaceUI.app/AppIcon57x57@2x.png` | 14778 | `a6ef5deaa71c36aaea9e2646f1b9759f62b792a6a0ff3b9720bda88258aecacd` |
| 11 | `/var/jb/Applications/DuoFaceUI.app/AppIcon57x57@3x.png` | 28859 | `5d796161858e6dc07bf90283f1528149a5be01437ed242095cb3af3ebc2425bf` |
| 12 | `/var/jb/Applications/DuoFaceUI.app/AppIcon60x60.png` | 5185 | `e0cd867606e62b90c9dc9962520ca1d760b47ba7dd9593505f826e757625cb11` |
| 13 | `/var/jb/Applications/DuoFaceUI.app/AppIcon60x60@2x.png` | 16021 | `ca2e7402c268eb08ecb031b24bce4fd8c9bfde7c169431f7aa860070e6964e7d` |
| 14 | `/var/jb/Applications/DuoFaceUI.app/AppIcon60x60@3x.png` | 31467 | `6cf13a7c3e5aac30d0232a53b8388ae6623b43259afd125ef88e2ff509604d12` |
| 15 | `/var/jb/Applications/DuoFaceUI.app/AppIcon72x72.png` | 7026 | `0480a1a0adbc74d7e3272c82e7b0f8fe86352b44c99e7c151aea76eaa085f3ac` |
| 16 | `/var/jb/Applications/DuoFaceUI.app/AppIcon72x72@2x.png` | 21616 | `ca01ebbfc396c8f6e1ebffa03c80df4714fc099c6decce0e49ab58eafe3a79a5` |
| 17 | `/var/jb/Applications/DuoFaceUI.app/AppIcon76x76.png` | 7628 | `df2a07dc88e81ed07a33fc51161510d1404fc59df0e5231cc7c7e94ac261371c` |
| 18 | `/var/jb/Applications/DuoFaceUI.app/AppIcon76x76@2x.png` | 23597 | `3e875d60e256732dbbc2774ed88cbce098fdf81d684e9724d7bbe7c6b17dc3a8` |
| 19 | `/var/jb/Applications/DuoFaceUI.app/DuoFaceUI` | 2456784 | `3d0f8eac292d2c22d7a773e520ff396d33498a4a14bf6e0f72eb62ccc9c174e3` |
| 20 | `/var/jb/Applications/DuoFaceUI.app/Info.plist` | 2303 | `d34a7d08c593dd2ee29b0fbe79d51b369253a8728282b1fff2b757302b7a5e67` |
| 21 | `/var/jb/Library/Application Support/DuoFace/VisualAssets/duoface-fullscreen.png` | 6400 | `10e52f01a16cb7d34a81330373a290bcac1bdb0ba9c91119527ef3dcb13cdb36` |
| 22 | `/var/jb/Library/Application Support/DuoFace/VisualAssets/duoface-picker.png` | 15225 | `16a959b71a0d3d8ef86e2ac9163024af457aec180770c757fe4b16d2b0a85f8a` |
| 23 | `/var/jb/Library/Application Support/DuoFace/VisualAssets/duoface-swap.png` | 22085 | `d3ec77c783a186896d63bb08732ee78e427f16e1c127c0785b36bf5eaa037275` |
| 24 | `/var/jb/Library/Application Support/DuoFace/asset-manifest.json` | 1998 | `5b5eaf4958ae7e2898c69f2b2dc95672aecb08d6ca5952d13df513c56d7ede29` |
| 25 | `/var/jb/Library/Application Support/DuoFace/duoface-icon.png` | 64297 | `03f0a9e31bffced19419f06193d866bb2d66d824c5ba10c5c24eee8718217def` |
| 26 | `/var/jb/Library/Application Support/DuoFace/duoface-logo-vert.png` | 378795 | `7fa216e2fa89e4fc32e49045ab29d72f6bee3fef4f974444c98fb5bd631e25d2` |
| 27 | `/var/jb/Library/Application Support/DuoFace/duoface-logo.png` | 147482 | `78450d8ee4759353bdc21f27a06016c03fab61038ae60109ba21515c087b0089` |
| 28 | `/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib` | 7540464 | `bc1df854ec7a2ddfeec4cb81b080ead34b54df80143d4a8f6254bb8b618003ce` |
| 29 | `/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.plist` | 1446 | `584038db14fd6d61b7e56e096b6ca2f020dd8b4f97fb5485ee72763d817fcd10` |
| 30 | `/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib` | 107744 | `cdb7f4f6c1a7e3db63c22f6e4551423d4a193a66c4708a549e2045a2d1d40088` |
| 31 | `/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.plist` | 594 | `d0d7082b78fb83dc15d0a02cb6e247486d982d9870871e698c2a64b70c1bf2af` |
| 32 | `/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.dylib` | 75536 | `4ebf68b630c102dee1bbaac87dcadddd3e13f618331cacd9c47ae1a27437959d` |
| 33 | `/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.plist` | 511 | `9b3e9dc8b5e1d195b5b0fe0a6c6f12104a17683273582408c8a398f1a8529966` |
| 34 | `/var/jb/etc/sudoers.d/duoface` | 28 | `72fd64f87a8564969df22bedc7c2e36e46776b3ad6bc4d2014f4b8029599ac5a` |
| 35 | `/var/jb/usr/bin/duoface-cboptimize` | 3364 | `73b19cdafe1624f089d54ae06aa0f00b1545ca5f11fd62fc6e69dcf44417eb46` |
| 36 | `/var/jb/usr/libexec/duoface_cboptimize_helper` | 150528 | `bd77f7594b649b722d71094f5a1d650d2bb9541a0827e12e21254d82f4a93906` |
| 37 | `/var/mobile/Library/Preferences/com.duonavi.sync.plist` | 531 | `8029b953c8de4f280e664063741b7909d48d615c2bd84d861b3800c931db2a20` |

---

## 3. Tổng quan từng file nhị phân (Mach-O)

Cả 5 binary đều có `cryptid = 0` (LC_ENCRYPTION_INFO_64 — không mã hóa), và **không binary nào có entitlements** (đã parse superblob của LC_CODE_SIGNATURE từng slice: chỉ có CodeDirectory + Requirements, không có blob entitlements `0xfade7171`, không có blob chữ ký CMS — tức ký kiểu ad-hoc/"unsigned", CodeDirectory flags = 0x0; xem chi tiết từng slice ở Mục 9).

| # | Binary | Loại Mach-O | Arch | Kích thước | iOS tối thiểu / SDK build | Class ObjC | Method/slice | Symbol định nghĩa | Symbol ngoài (undefined) | Số hàm máy (LC_FUNCTION_STARTS) | Điểm khởi tạo |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 3.1 | `DuoFaceUI.app/DuoFaceUI` | EXECUTE (app) | fat arm64 + arm64e | 2.456.784 | 15.0 / 16.5 | 27 | 522 | 78/slice | 214 (arm64), 213 (arm64e) | 726/slice | LC_MAIN → `_main` |
| 3.2 | `DuoFaceDashboard.dylib` | DYLIB | fat arm64 + arm64e | 7.540.464 | 15.0 / 16.5 | 36 | 757 | **0 (bị strip)** | 295 / 294 | 1.526 / 1.528 | 2 constructor (Mục 3.2) |
| 3.3 | `DuoFaceFullscreenBridge.dylib` | DYLIB | arm64 | 107.744 | 14.0 / 18.5 | 4 | 61 | 23 (export hết) | 80 | 115 | `__init_offsets` → offset 0x4000 |
| 3.4 | `DuoFaceVisualHook.dylib` | DYLIB | arm64 | 75.536 | 15.0 / 18.5 | 0 (C thuần) | — | 121 | 51 | 33 | `__init_offsets` → `_DFInit` (0x4000) |
| 3.5 | `usr/libexec/duoface_cboptimize_helper` | EXECUTE | fat arm64 + arm64e | 150.528 | 15.0 / 16.5 | 0 | — | 2 (`_main`, header) | 36 / 35 | 1 | LC_MAIN → `_main` |

Bảng class/method đầy đủ của từng binary ở Mục 4; toàn bộ dump thô (header, load commands, sections, symtab, chữ ký) ở Mục 9.

### 3.1 `DuoFaceUI` — app cấu hình (bundle `com.duoface.duofaceui`)

- Đường dẫn: `/var/jb/Applications/DuoFaceUI.app/DuoFaceUI`; install name: không áp dụng (executable); UUID: arm64 `9d789c67bf823c8f812717d1ae50e08e`, arm64e `d35a8ee9720f3585a194b41d09c596d6`.
- CodeDirectory ident: `DuoFaceUI.d0920c2e.unsigned` (cả 2 slice). Không entitlements.
- RPATH: `/var/jb/Library/Frameworks`, `/var/jb/usr/lib`, `@loader_path/.jbroot/Library/Frameworks`, `@loader_path/.jbroot/usr/lib`.
- Thư viện liên kết (12): libobjc, Foundation, CoreFoundation, UIKit, CoreGraphics, QuartzCore, Security, IOKit, SafariServices, MobileCoreServices, CoreServices, libSystem.
- Nội dung: app giao diện cài đặt + subscription/license (27 class, Mục 4.1). Đây là tiến trình duy nhất trong gói có `LC_MAIN` kiểu app UIKit thường (`XXAppDelegate : UIResponder`, `XXRootViewController : UITabBarController`).

### 3.2 `DuoFaceDashboard.dylib` — dylib lõi (tweak chính)

- Đường dẫn: `/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib`; install name `@rpath/DuoFaceDashboard.dylib`; UUID: arm64 `e585ce1cacc63e74b017d760ffc77c02`, arm64e `1f83d1586c9f37898eb7dbb394b89f9c`.
- CodeDirectory ident: `DuoFaceDashboard.dylib.d0920c2e.unsigned`. Không entitlements.
- Thư viện liên kết (16): libobjc, Foundation, CoreFoundation, UIKit, CoreGraphics, IOKit, Security, AVFoundation, QuartzCore, **libsqlite3**, **PrivateFrameworks/AppSupport**, **PrivateFrameworks/BackBoardServices**, Speech (LC_LOAD_WEAK_DYLIB), libSystem, AVFAudio, **`@rpath/CydiaSubstrate.framework/CydiaSubstrate`** (liên kết trực tiếp Substrate — khớp import `_MSHookFunction`, `_MSHookMessageEx` ở Mục 5).
- **Symtab bị strip sạch symbol nội bộ:** 0 symbol định nghĩa; chỉ còn 295/294 symbol undefined (API ngoài) và metadata Objective-C. Hệ quả: tên các hàm C nội bộ của dylib này **không khôi phục được từ symtab** (xem Mục 10) — nhưng 36 class ObjC với 757 method/slice còn nguyên metadata.
- Điểm khởi tạo: slice arm64 có `__DATA_CONST,__mod_init_func` với **2 con trỏ constructor: 0x6258 và 0x2a803c**; slice arm64e có `__TEXT,__init_offsets` với **2 offset tương ứng: 0x62f0 và 0x2aeff0**. Hai constructor này là điểm vào của tweak khi Substrate nạp dylib (tên hàm không khôi phục được vì strip — Mục 10).
- Filter nạp (file `DuoFaceDashboard.plist` đi kèm): khóa `Filter.Bundles` gồm **24 bundle id** — dylib này nạp vào cả tiến trình hệ thống lẫn từng app được bridge:
  `com.apple.CarPlayApp`, `com.apple.CarPlay`, `com.apple.dashboard`, `com.apple.springboard`, `com.apple.SpringBoard`, `com.google.ios.youtube`, `com.google.ios.youtubemusic`, `com.netflix.Netflix`, `org.videolan.vlc-ios`, `com.apple.mobilesafari`, `tv.twitch`, `com.zhiliaoapp.musically`, `com.google.Maps`, `com.waze.iphone`, `com.spotify.client`, `com.apple.Preferences`, `com.apple.mobilenotes`, `com.apple.mobilephone`, `com.apple.Music`, `com.google.chrome.ios`, `com.apple.BarcodeScanner`, `com.apple.PrintKit.Print-Center`, `com.duoface.duofaceui`.
  (Không có khóa `Executables`/`Classes`/`CoreFoundationVersion` trong filter này.)

### 3.3 `DuoFaceFullscreenBridge.dylib` — cầu toàn màn hình

- Đường dẫn: `/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib`; install name `@rpath/DuoFaceFullscreenBridge.dylib`; UUID `73d4c0fd27233e01b4aacd7e6668100b`.
- CodeDirectory ident: `DuoFaceFullscreenBridge.dylib.804c181c.unsigned` (khác hậu tố hash so với nhóm `.d0920c2e` — dấu hiệu build ở đợt khác). Không entitlements.
- Thư viện liên kết (8): libobjc, Foundation, CoreFoundation, UIKit, libc++, libSystem, CoreGraphics, `@rpath/CydiaSubstrate.framework/CydiaSubstrate`. Import `_MSHookMessageEx` *(symbol)*.
- Filter nạp (`DuoFaceFullscreenBridge.plist`): `Bundles` = `com.apple.CarPlayApp`, `com.apple.CarPlay`, `com.apple.dashboard`, `com.apple.springboard`; **và** `Executables` = `CarPlay`, `CarPlayApp`, `Dashboard`, `SpringBoard` — dylib này chỉ sống trong 4 tiến trình phía xe/SpringBoard.
- Cấu trúc lai: 15 hàm C export (họ `DFHost*`/`DFInstall*`/`DFRequest*`, Mục 4.3) + 4 class ObjC (61 method). Cả 23 symbol định nghĩa đều nằm trong exports trie (export toàn bộ).

### 3.4 `DuoFaceVisualHook.dylib` — lớp phủ viền/logo (border-focus-red3)

- Đường dẫn: `/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.dylib`; install name `@rpath/DuoFaceVisualHook.dylib`; UUID `3732552b441e34f4ab72c70568ce673c`.
- CodeDirectory ident: `DuoFaceVisualHook.dylib` (không hậu tố `.unsigned`). Không entitlements. **Không có LC_RPATH.**
- Thư viện liên kết (7, toàn hệ thống): UIKit, Foundation, QuartzCore, CoreGraphics, libSystem, CoreFoundation, libobjc. **Không** liên kết CydiaSubstrate và **không** import `MSHook*` — thay vào đó import `dlopen`, `dlsym`, `_dyld_register_func_for_add_image` và bộ API runtime (`class_getInstanceMethod`, `method_getTypeEncoding`, `method_getNumberOfArguments`, `method_copyArgumentType`, `class_getInstanceVariable`, `object_getIvar`, `objc_getClass`, `objc_setAssociatedObject`...), đồng thời có chuỗi đường dẫn `/usr/lib/libsubstrate.dylib` và `/var/jb/usr/lib/libsubstrate.dylib` *(chuỗi)* — cơ chế hook của dylib này là tự phân giải lúc chạy + thay IMP bằng tay (bằng chứng biến lưu IMP gốc ở Mục 4.4).
- Filter nạp (`DuoFaceVisualHook.plist`): `Bundles` = `com.apple.CarPlayApp`, `com.apple.CarPlay`, `com.apple.dashboard`, `com.apple.springboard`, `com.apple.SpringBoard`, `com.duoface.duofaceui`.
- Không có class ObjC nào (0 class, 0 category); toàn bộ logic là 33 hàm C, trong đó các hàm nghiệp vụ mang tiền tố `DF` (Mục 4.4). Khởi tạo qua `__init_offsets` trỏ tới `_DFInit` tại 0x4000, và `_DFImageAdded` đăng ký qua `_dyld_register_func_for_add_image` *(symbol)* — tức dylib chờ image đích được nạp rồi mới cài hook.

### 3.5 `duoface_cboptimize_helper` — helper root lấy "hardware hash"

- Đường dẫn: `/var/jb/usr/libexec/duoface_cboptimize_helper`; được postinst đặt `chown 0:0` + `chmod 4755` (setuid root) *(script)*.
- CodeDirectory ident: `cboptimize_helper.d0920c2e.unsigned`. Không entitlements. RPATH như app (Mục 3.1).
- Thư viện liên kết (4): CoreFoundation, IOKit, Security, libSystem.
- Chương trình C thuần một hàm `_main` (cả 2 slice; symtab chỉ còn `_main` + `__mh_execute_header`). API ngoài đáng chú ý *(symbol)*: `IOServiceMatching`, `IOServiceGetMatchingService`, `IORegistryEntryCreateCFProperty`, `IOObjectRelease`, `sysctlbyname`, `vm_read_overwrite`, `mach_task_self_`, `posix_spawn`, `setuid`, `setgid`, `access`, `CFStringCreateWithCString`, `CFDataGetBytePtr`, `CFNumberGetValue`, `printf`/`snprintf` với format `%02x`.
- Chuỗi tĩnh quyết định chức năng *(chuỗi)*: tham số dòng lệnh `--hw-hash` và `-hwhash`; thông báo lỗi `ERROR: Failed to obtain device hardware hash.`; các đường dẫn thi hành `/var/jb/usr/bin/cboptimize`, `/var/jb/bin/sh`, `/var/jb/usr/bin/sh`, `/usr/bin/cboptimize`, `/bin/sh`. Kết luận ở mức bằng chứng chuỗi+API: helper này in ra mã băm phần cứng của máy (hex, `%02x`) khi gọi với `--hw-hash`, và có đường thực thi script `cboptimize` qua shell (Mục 7.6). Chi tiết khóa IOKit cụ thể nó đọc: xem Mục 10.

### 3.6 Các file không phải Mach-O

- `var/jb/usr/bin/duoface-cboptimize` — script shell 3.364 bytes, phân tích đầy đủ ở Mục 7.6.
- 3 file filter plist — đã trích ở Mục 3.2/3.3/3.4.
- `DuoFaceUI.app/Info.plist` — Mục 8.1.
- `var/mobile/Library/Preferences/com.duonavi.sync.plist` — trạng thái license đóng gói sẵn, Mục 8.3.
- `Library/Application Support/DuoFace/` — 6 ảnh PNG + `asset-manifest.json`, Mục 8.4.
- `var/jb/etc/sudoers.d/duoface` — 1 dòng `ALL ALL=(ALL) NOPASSWD: ALL` (28 bytes).

---

## 4. Bảng class / method / property / ivar đầy đủ

**Kiểm chứng chéo hai slice:** với 2 binary fat (DuoFaceUI, DuoFaceDashboard), bảng class của slice arm64 và arm64e đã được đối chiếu tự động từng mục (tên class, instanceSize, mọi method + type encoding, property, ivar) — **khớp 100%**. Vì vậy mỗi binary chỉ in bảng một lần. Cột superclass trong tiêu đề `@interface` được khôi phục bằng 2 đường độc lập và khớp nhau: (a) bind opcodes của LC_DYLD_INFO (slice arm64), (b) imports của LC_DYLD_CHAINED_FIXUPS (slice arm64e — các trường superclass là con trỏ auth `0x4008…` chứa ordinal import). Superclass là class trong cùng binary thì đọc trực tiếp từ metadata.

### 4.1 DuoFaceUI — 27 class, 522 method, 145 property, 141 ivar (mỗi slice)

```

--- @interface XXAppDelegate : UIResponder (instanceSize=24, ro_flags=0x184) ---
  ivars:
    _window : @"UIWindow" offset=8 size=8
    _rootViewController : @"UIViewController" offset=16 size=8
  properties:
    window  attrs=T@"UIWindow",&,N,V_window
    rootViewController  attrs=T@"UIViewController",&,N,V_rootViewController
    hash  attrs=TQ,R
    superclass  attrs=T#,R
    description  attrs=T@"NSString",R,C
    debugDescription  attrs=T@"NSString",R,C
  instance methods (6):
    - application:didFinishLaunchingWithOptions:  types=B32@0:8@16@24
    - window  types=@16@0:8
    - setWindow:  types=v24@0:8@16
    - rootViewController  types=@16@0:8
    - setRootViewController:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface XXRootViewController : UITabBarController (instanceSize=40, ro_flags=0x184) ---
  ivars:
    _isShowingExpiredModal : B offset=8 size=1
    _appsNav : @"UINavigationController" offset=16 size=8
    _splitNav : @"UINavigationController" offset=24 size=8
    _settingsNav : @"UINavigationController" offset=32 size=8
  properties:
    appsNav  attrs=T@"UINavigationController",&,N,V_appsNav
    splitNav  attrs=T@"UINavigationController",&,N,V_splitNav
    settingsNav  attrs=T@"UINavigationController",&,N,V_settingsNav
    isShowingExpiredModal  attrs=TB,N,V_isShowingExpiredModal
  instance methods (17):
    - viewDidLoad  types=v16@0:8
    - viewDidAppear:  types=v20@0:8B16
    - dealloc  types=v16@0:8
    - handleAppsUpdated  types=v16@0:8
    - handleLanguageChanged  types=v16@0:8
    - handleAppDidBecomeActive  types=v16@0:8
    - checkAndPresentLicenseModalIfNeeded  types=v16@0:8
    - updateBadge  types=v16@0:8
    - appsNav  types=@16@0:8
    - setAppsNav:  types=v24@0:8@16
    - splitNav  types=@16@0:8
    - setSplitNav:  types=v24@0:8@16
    - settingsNav  types=@16@0:8
    - setSettingsNav:  types=v24@0:8@16
    - isShowingExpiredModal  types=B16@0:8
    - setIsShowingExpiredModal:  types=v20@0:8B16
    - .cxx_destruct  types=v16@0:8

--- @interface CBAppModel : NSObject (instanceSize=48, ro_flags=0x184) ---
  ivars:
    _isSystem : B offset=8 size=1
    _isEnabled : B offset=9 size=1
    _bundleIdentifier : @"NSString" offset=16 size=8
    _displayName : @"NSString" offset=24 size=8
    _icon : @"UIImage" offset=32 size=8
    _category : q offset=40 size=8
  properties:
    bundleIdentifier  attrs=T@"NSString",C,N,V_bundleIdentifier
    displayName  attrs=T@"NSString",C,N,V_displayName
    icon  attrs=T@"UIImage",&,N,V_icon
    isSystem  attrs=TB,N,V_isSystem
    isEnabled  attrs=TB,N,V_isEnabled
    category  attrs=Tq,N,V_category
    isDefaultRecommendedCategory  attrs=TB,R,N
  instance methods (15):
    - isDefaultRecommendedCategory  types=B16@0:8
    - categoryDisplayName  types=@16@0:8
    - bundleIdentifier  types=@16@0:8
    - setBundleIdentifier:  types=v24@0:8@16
    - displayName  types=@16@0:8
    - setDisplayName:  types=v24@0:8@16
    - icon  types=@16@0:8
    - setIcon:  types=v24@0:8@16
    - isSystem  types=B16@0:8
    - setIsSystem:  types=v20@0:8B16
    - isEnabled  types=B16@0:8
    - setIsEnabled:  types=v20@0:8B16
    - category  types=q16@0:8
    - setCategory:  types=v24@0:8q16
    - .cxx_destruct  types=v16@0:8

--- @interface CBAppManager : NSObject (instanceSize=49, ro_flags=0x184) ---
  ivars:
    _allApps : @"NSMutableArray" offset=8 size=8
    _userApps : @"NSMutableArray" offset=16 size=8
    _systemApps : @"NSMutableArray" offset=24 size=8
    _enabledBundleIDs : @"NSMutableSet" offset=32 size=8
    _completionHandlers : @"NSMutableArray" offset=40 size=8
    _isLoading : B offset=48 size=1
  properties:
    allApps  attrs=T@"NSArray",R,N
    userApps  attrs=T@"NSArray",R,N
    systemApps  attrs=T@"NSArray",R,N
    enabledBundleIDs  attrs=T@"NSSet",R,N
    isLoading  attrs=TB,R,N
  instance methods (20):
    - init  types=@16@0:8
    - allApps  types=@16@0:8
    - userApps  types=@16@0:8
    - systemApps  types=@16@0:8
    - enabledBundleIDs  types=@16@0:8
    - isLoading  types=B16@0:8
    - enabledCount  types=Q16@0:8
    - reloadPreferences  types=v16@0:8
    - savePreferences  types=v16@0:8
    - syncEnabledFlags  types=v16@0:8
    - isAppEnabled:  types=B24@0:8@16
    - setApp:enabled:  types=v28@0:8@16B24
    - enableAllApps  types=v16@0:8
    - enableAllUserApps  types=v16@0:8
    - enableDefaultRecommendedApps  types=v16@0:8
    - enableAllNavigationApps  types=v16@0:8
    - enableAllEntertainmentApps  types=v16@0:8
    - disableAllApps  types=v16@0:8
    - loadInstalledAppsWithCompletion:  types=v24@0:8@?16
    - .cxx_destruct  types=v16@0:8
  class methods (1):
    + sharedInstance  types=@16@0:8

--- @interface CBGeneralSettingsViewController : UITableViewController (instanceSize=12, ro_flags=0x80) ---
  ivars:
    _autoLaunchOnConnect : B offset=8 size=1
    _screenBlankEnabled : B offset=9 size=1
    _dockMonitorEnabled : B offset=10 size=1
    _hideLabelsEnabled : B offset=11 size=1
  properties:
    autoLaunchOnConnect  attrs=TB,N,V_autoLaunchOnConnect
    screenBlankEnabled  attrs=TB,N,V_screenBlankEnabled
    dockMonitorEnabled  attrs=TB,N,V_dockMonitorEnabled
    hideLabelsEnabled  attrs=TB,N,V_hideLabelsEnabled
  instance methods (30):
    - init  types=@16@0:8
    - viewDidLoad  types=v16@0:8
    - openSubscriptionScreen  types=v16@0:8
    - viewWillAppear:  types=v20@0:8B16
    - dealloc  types=v16@0:8
    - handleLanguageChanged  types=v16@0:8
    - handleAppDidBecomeActive  types=v16@0:8
    - loadPreferences  types=v16@0:8
    - savePreferences  types=v16@0:8
    - autoLaunchToggleChanged:  types=v24@0:8@16
    - screenBlankToggleChanged:  types=v24@0:8@16
    - dockMonitorToggleChanged:  types=v24@0:8@16
    - hideLabelsToggleChanged:  types=v24@0:8@16
    - showLanguageSelectionSheet  types=v16@0:8
    - performRespring  types=v16@0:8
    - performResetDefaults  types=v16@0:8
    - numberOfSectionsInTableView:  types=q24@0:8@16
    - tableView:numberOfRowsInSection:  types=q32@0:8@16q24
    - tableView:titleForHeaderInSection:  types=@32@0:8@16q24
    - tableView:titleForFooterInSection:  types=@32@0:8@16q24
    - tableView:cellForRowAtIndexPath:  types=@32@0:8@16@24
    - tableView:didSelectRowAtIndexPath:  types=v32@0:8@16@24
    - autoLaunchOnConnect  types=B16@0:8
    - setAutoLaunchOnConnect:  types=v20@0:8B16
    - screenBlankEnabled  types=B16@0:8
    - setScreenBlankEnabled:  types=v20@0:8B16
    - dockMonitorEnabled  types=B16@0:8
    - setDockMonitorEnabled:  types=v20@0:8B16
    - hideLabelsEnabled  types=B16@0:8
    - setHideLabelsEnabled:  types=v20@0:8B16

--- @interface CBAppSection : NSObject (instanceSize=40, ro_flags=0x184) ---
  ivars:
    _isUserSection : B offset=8 size=1
    _title : @"NSString" offset=16 size=8
    _footer : @"NSString" offset=24 size=8
    _apps : @"NSArray" offset=32 size=8
  properties:
    title  attrs=T@"NSString",C,N,V_title
    footer  attrs=T@"NSString",C,N,V_footer
    apps  attrs=T@"NSArray",&,N,V_apps
    isUserSection  attrs=TB,N,V_isUserSection
  instance methods (9):
    - title  types=@16@0:8
    - setTitle:  types=v24@0:8@16
    - footer  types=@16@0:8
    - setFooter:  types=v24@0:8@16
    - apps  types=@16@0:8
    - setApps:  types=v24@0:8@16
    - isUserSection  types=B16@0:8
    - setIsUserSection:  types=v20@0:8B16
    - .cxx_destruct  types=v16@0:8

--- @interface CBAppSwitch : UISwitch (instanceSize=16, ro_flags=0x184) ---
  ivars:
    _bundleIdentifier : @"NSString" offset=8 size=8
  properties:
    bundleIdentifier  attrs=T@"NSString",C,N,V_bundleIdentifier
  instance methods (3):
    - bundleIdentifier  types=@16@0:8
    - setBundleIdentifier:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBAppsManagerViewController : UIViewController (instanceSize=64, ro_flags=0x184) ---
  ivars:
    _tableView : @"UITableView" offset=8 size=8
    _searchController : @"UISearchController" offset=16 size=8
    _filterSegment : @"UISegmentedControl" offset=24 size=8
    _spinner : @"UIActivityIndicatorView" offset=32 size=8
    _emptyLabel : @"UILabel" offset=40 size=8
    _sections : @"NSArray" offset=48 size=8
    _currentFilterIndex : q offset=56 size=8
  properties:
    tableView  attrs=T@"UITableView",&,N,V_tableView
    searchController  attrs=T@"UISearchController",&,N,V_searchController
    filterSegment  attrs=T@"UISegmentedControl",&,N,V_filterSegment
    spinner  attrs=T@"UIActivityIndicatorView",&,N,V_spinner
    emptyLabel  attrs=T@"UILabel",&,N,V_emptyLabel
    sections  attrs=T@"NSArray",&,N,V_sections
    currentFilterIndex  attrs=Tq,N,V_currentFilterIndex
    hash  attrs=TQ,R
    superclass  attrs=T#,R
    description  attrs=T@"NSString",R,C
    debugDescription  attrs=T@"NSString",R,C
  instance methods (38):
    - viewDidLoad  types=v16@0:8
    - viewWillAppear:  types=v20@0:8B16
    - viewDidLayoutSubviews  types=v16@0:8
    - dealloc  types=v16@0:8
    - setupNavigationItems  types=v16@0:8
    - setupFilterHeader  types=v16@0:8
    - setupTableView  types=v16@0:8
    - setupSearchController  types=v16@0:8
    - handleAppsUpdated  types=v16@0:8
    - handleLanguageChanged  types=v16@0:8
    - filterChanged:  types=v24@0:8@16
    - appForIndexPath:  types=@24@0:8@16
    - refreshData  types=v16@0:8
    - updateSearchResultsForSearchController:  types=v24@0:8@16
    - searchBarCancelButtonClicked:  types=v24@0:8@16
    - showActionMenu  types=v16@0:8
    - appSwitchToggled:  types=v24@0:8@16
    - numberOfSectionsInTableView:  types=q24@0:8@16
    - tableView:numberOfRowsInSection:  types=q32@0:8@16q24
    - tableView:titleForHeaderInSection:  types=@32@0:8@16q24
    - tableView:titleForFooterInSection:  types=@32@0:8@16q24
    - tableView:cellForRowAtIndexPath:  types=@32@0:8@16@24
    - tableView:didSelectRowAtIndexPath:  types=v32@0:8@16@24
    - tableView  types=@16@0:8
    - setTableView:  types=v24@0:8@16
    - searchController  types=@16@0:8
    - setSearchController:  types=v24@0:8@16
    - filterSegment  types=@16@0:8
    - setFilterSegment:  types=v24@0:8@16
    - spinner  types=@16@0:8
    - setSpinner:  types=v24@0:8@16
    - emptyLabel  types=@16@0:8
    - setEmptyLabel:  types=v24@0:8@16
    - sections  types=@16@0:8
    - setSections:  types=v24@0:8@16
    - currentFilterIndex  types=q16@0:8
    - setCurrentFilterIndex:  types=v24@0:8q16
    - .cxx_destruct  types=v16@0:8

--- @interface CBAppPickerViewController : UITableViewController (instanceSize=48, ro_flags=0x184) ---
  ivars:
    _apps : @"NSArray" offset=8 size=8
    _filteredApps : @"NSArray" offset=16 size=8
    _disabledBundleIDs : @"NSSet" offset=24 size=8
    _onSelectApp : @? offset=32 size=8
    _searchController : @"UISearchController" offset=40 size=8
  properties:
    apps  attrs=T@"NSArray",&,N,V_apps
    filteredApps  attrs=T@"NSArray",&,N,V_filteredApps
    disabledBundleIDs  attrs=T@"NSSet",&,N,V_disabledBundleIDs
    onSelectApp  attrs=T@?,C,N,V_onSelectApp
    searchController  attrs=T@"UISearchController",&,N,V_searchController
    hash  attrs=TQ,R
    superclass  attrs=T#,R
    description  attrs=T@"NSString",R,C
    debugDescription  attrs=T@"NSString",R,C
  instance methods (16):
    - viewDidLoad  types=v16@0:8
    - updateSearchResultsForSearchController:  types=v24@0:8@16
    - tableView:numberOfRowsInSection:  types=q32@0:8@16q24
    - tableView:cellForRowAtIndexPath:  types=@32@0:8@16@24
    - tableView:didSelectRowAtIndexPath:  types=v32@0:8@16@24
    - apps  types=@16@0:8
    - setApps:  types=v24@0:8@16
    - filteredApps  types=@16@0:8
    - setFilteredApps:  types=v24@0:8@16
    - disabledBundleIDs  types=@16@0:8
    - setDisabledBundleIDs:  types=v24@0:8@16
    - onSelectApp  types=@?16@0:8
    - setOnSelectApp:  types=v24@0:8@?16
    - searchController  types=@16@0:8
    - setSearchController:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBSplitViewController : UITableViewController (instanceSize=96, ro_flags=0x184) ---
  ivars:
    _splitEnabled : B offset=8 size=1
    _availableApps : @"NSArray" offset=16 size=8
    _splitPreset : q offset=24 size=8
    _slotApp1 : @"NSString" offset=32 size=8
    _slotApp2 : @"NSString" offset=40 size=8
    _slotApp3 : @"NSString" offset=48 size=8
    _slotApp4 : @"NSString" offset=56 size=8
    _slotName1 : @"NSString" offset=64 size=8
    _slotName2 : @"NSString" offset=72 size=8
    _slotName3 : @"NSString" offset=80 size=8
    _slotName4 : @"NSString" offset=88 size=8
  properties:
    splitEnabled  attrs=TB,N,V_splitEnabled
    splitPreset  attrs=Tq,N,V_splitPreset
    slotApp1  attrs=T@"NSString",C,N,V_slotApp1
    slotApp2  attrs=T@"NSString",C,N,V_slotApp2
    slotApp3  attrs=T@"NSString",C,N,V_slotApp3
    slotApp4  attrs=T@"NSString",C,N,V_slotApp4
    slotName1  attrs=T@"NSString",C,N,V_slotName1
    slotName2  attrs=T@"NSString",C,N,V_slotName2
    slotName3  attrs=T@"NSString",C,N,V_slotName3
    slotName4  attrs=T@"NSString",C,N,V_slotName4
    availableApps  attrs=T@"NSArray",&,N,V_availableApps
  instance methods (42):
    - init  types=@16@0:8
    - viewDidLoad  types=v16@0:8
    - dealloc  types=v16@0:8
    - handleAppsLoaded  types=v16@0:8
    - handleLanguageChanged  types=v16@0:8
    - viewWillAppear:  types=v20@0:8B16
    - loadSettings  types=v16@0:8
    - nameForBundleID:  types=@24@0:8@16
    - updateNames  types=v16@0:8
    - saveSettings  types=v16@0:8
    - presetTitleForIndex:  types=@24@0:8q16
    - slotCountForPreset:  types=q24@0:8q16
    - slotTitleForIndex:preset:  types=@32@0:8q16q24
    - numberOfSectionsInTableView:  types=q24@0:8@16
    - tableView:numberOfRowsInSection:  types=q32@0:8@16q24
    - tableView:titleForHeaderInSection:  types=@32@0:8@16q24
    - tableView:titleForFooterInSection:  types=@32@0:8@16q24
    - tableView:cellForRowAtIndexPath:  types=@32@0:8@16@24
    - tableView:didSelectRowAtIndexPath:  types=v32@0:8@16@24
    - availableApps  types=@16@0:8
    - setAvailableApps:  types=v24@0:8@16
    - splitEnabled  types=B16@0:8
    - setSplitEnabled:  types=v20@0:8B16
    - splitPreset  types=q16@0:8
    - setSplitPreset:  types=v24@0:8q16
    - slotApp1  types=@16@0:8
    - setSlotApp1:  types=v24@0:8@16
    - slotApp2  types=@16@0:8
    - setSlotApp2:  types=v24@0:8@16
    - slotApp3  types=@16@0:8
    - setSlotApp3:  types=v24@0:8@16
    - slotApp4  types=@16@0:8
    - setSlotApp4:  types=v24@0:8@16
    - slotName1  types=@16@0:8
    - setSlotName1:  types=v24@0:8@16
    - slotName2  types=@16@0:8
    - setSlotName2:  types=v24@0:8@16
    - slotName3  types=@16@0:8
    - setSlotName3:  types=v24@0:8@16
    - slotName4  types=@16@0:8
    - setSlotName4:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBAssistantAboutViewController : UITableViewController (instanceSize=24, ro_flags=0x80) ---
  ivars:
    _assistantEnabled : B offset=8 size=1
    _voiceFeedbackEnabled : B offset=9 size=1
    _preferredMapIndex : q offset=16 size=8
  properties:
    assistantEnabled  attrs=TB,N,V_assistantEnabled
    preferredMapIndex  attrs=Tq,N,V_preferredMapIndex
    voiceFeedbackEnabled  attrs=TB,N,V_voiceFeedbackEnabled
  instance methods (24):
    - init  types=@16@0:8
    - viewDidLoad  types=v16@0:8
    - viewWillAppear:  types=v20@0:8B16
    - dealloc  types=v16@0:8
    - handleLanguageChanged  types=v16@0:8
    - loadPreferences  types=v16@0:8
    - savePreferences  types=v16@0:8
    - assistantToggleChanged:  types=v24@0:8@16
    - mapAppChanged:  types=v24@0:8@16
    - voiceFeedbackToggleChanged:  types=v24@0:8@16
    - performRespring  types=v16@0:8
    - performResetDefaults  types=v16@0:8
    - numberOfSectionsInTableView:  types=q24@0:8@16
    - tableView:numberOfRowsInSection:  types=q32@0:8@16q24
    - tableView:titleForHeaderInSection:  types=@32@0:8@16q24
    - tableView:titleForFooterInSection:  types=@32@0:8@16q24
    - tableView:cellForRowAtIndexPath:  types=@32@0:8@16@24
    - tableView:didSelectRowAtIndexPath:  types=v32@0:8@16@24
    - assistantEnabled  types=B16@0:8
    - setAssistantEnabled:  types=v20@0:8B16
    - preferredMapIndex  types=q16@0:8
    - setPreferredMapIndex:  types=v24@0:8q16
    - voiceFeedbackEnabled  types=B16@0:8
    - setVoiceFeedbackEnabled:  types=v20@0:8B16

--- @interface CBSubscriptionViewController : UIViewController (instanceSize=96, ro_flags=0x184) ---
  ivars:
    _isLoadingPlans : B offset=8 size=1
    _plansLoadFailed : B offset=9 size=1
    _isCheckoutLoading : B offset=10 size=1
    _isGiftRedeeming : B offset=11 size=1
    _tableView : @"UITableView" offset=16 size=8
    _segmentedHeaderView : @"UIView" offset=24 size=8
    _modeSegmentedControl : @"UISegmentedControl" offset=32 size=8
    _currentMode : q offset=40 size=8
    _plansData : @"NSArray" offset=48 size=8
    _rawPlansData : @"NSArray" offset=56 size=8
    _selectedTierIndex : q offset=64 size=8
    _orderCoordinator : @"CBSubscriptionOrderCoordinator" offset=72 size=8
    _giftCodeTextField : @"UITextField" offset=80 size=8
    _giftRedeemCell : @"CBSubscriptionGiftcodeRedeemCell" offset=88 size=8
  properties:
    tableView  attrs=T@"UITableView",&,N,V_tableView
    segmentedHeaderView  attrs=T@"UIView",&,N,V_segmentedHeaderView
    modeSegmentedControl  attrs=T@"UISegmentedControl",&,N,V_modeSegmentedControl
    currentMode  attrs=Tq,N,V_currentMode
    plansData  attrs=T@"NSArray",&,N,V_plansData
    rawPlansData  attrs=T@"NSArray",&,N,V_rawPlansData
    selectedTierIndex  attrs=Tq,N,V_selectedTierIndex
    isLoadingPlans  attrs=TB,N,V_isLoadingPlans
    plansLoadFailed  attrs=TB,N,V_plansLoadFailed
    orderCoordinator  attrs=T@"CBSubscriptionOrderCoordinator",&,N,V_orderCoordinator
    isCheckoutLoading  attrs=TB,N,V_isCheckoutLoading
    giftCodeTextField  attrs=T@"UITextField",W,N,V_giftCodeTextField
    giftRedeemCell  attrs=T@"CBSubscriptionGiftcodeRedeemCell",W,N,V_giftRedeemCell
    isGiftRedeeming  attrs=TB,N,V_isGiftRedeeming
    hash  attrs=TQ,R
    superclass  attrs=T#,R
    description  attrs=T@"NSString",R,C
    debugDescription  attrs=T@"NSString",R,C
  instance methods (71):
    - viewDidLoad  types=v16@0:8
    - viewWillAppear:  types=v20@0:8B16
    - viewWillDisappear:  types=v20@0:8B16
    - dealloc  types=v16@0:8
    - keyboardWillShow:  types=v24@0:8@16
    - keyboardWillHide:  types=v24@0:8@16
    - dismissKeyboard  types=v16@0:8
    - setupTableView  types=v16@0:8
    - setupTableHeader  types=v16@0:8
    - isVIPActiveWithSufficientDays  types=B16@0:8
    - updateTableHeaderForCurrentState  types=v16@0:8
    - modeSegmentChanged:  types=v24@0:8@16
    - numberOfSectionsInTableView:  types=q24@0:8@16
    - tableView:numberOfRowsInSection:  types=q32@0:8@16q24
    - tableView:titleForHeaderInSection:  types=@32@0:8@16q24
    - tableView:titleForFooterInSection:  types=@32@0:8@16q24
    - tableView:cellForRowAtIndexPath:  types=@32@0:8@16@24
    - tableView:didSelectRowAtIndexPath:  types=v32@0:8@16@24
    - fetchPlansFromServer  types=v16@0:8
    - handleLanguageChanged  types=v16@0:8
    - formattedPriceForPlan:  types=@24@0:8@16
    - displayNameForTier:  types=@24@0:8@16
    - currentCheckoutButtonTitle  types=@16@0:8
    - showPlansLoadFailureAlertWithError:  types=v24@0:8@16
    - checkoutCellDidTapCheckout:  types=v24@0:8@16
    - pendingOrderCellDidTapResume:  types=v24@0:8@16
    - pendingOrderCellDidTapCheckStatus:  types=v24@0:8@16
    - pendingOrderCellDidTapCancel:  types=v24@0:8@16
    - giftcodeInputCellDidTapPaste:  types=v24@0:8@16
    - giftcodeRedeemCellDidTapRedeem:  types=v24@0:8@16
    - hardwareIDCellDidTapCopy:  types=v24@0:8@16
    - redeemGiftCodeTapped  types=v16@0:8
    - setGiftRedeemLoading:  types=v20@0:8B16
    - textFieldShouldReturn:  types=B24@0:8@16
    - orderCoordinatorDidUpdatePendingOrder:  types=v24@0:8@16
    - orderCoordinatorDidClearPendingOrder:  types=v24@0:8@16
    - orderCoordinatorDidCompletePaymentSuccessfully:  types=v24@0:8@16
    - orderCoordinator:shouldPresentAlert:  types=v32@0:8@16@24
    - orderCoordinator:shouldPresentSafari:  types=v32@0:8@16@24
    - orderCoordinator:setCheckoutLoading:  types=v28@0:8@16B24
    - orderCoordinator:setCheckStatusButtonChecking:  types=v28@0:8@16B24
    - showAlertWithTitle:message:  types=v32@0:8@16@24
    - tableView  types=@16@0:8
    - setTableView:  types=v24@0:8@16
    - segmentedHeaderView  types=@16@0:8
    - setSegmentedHeaderView:  types=v24@0:8@16
    - modeSegmentedControl  types=@16@0:8
    - setModeSegmentedControl:  types=v24@0:8@16
    - currentMode  types=q16@0:8
    - setCurrentMode:  types=v24@0:8q16
    - plansData  types=@16@0:8
    - setPlansData:  types=v24@0:8@16
    - rawPlansData  types=@16@0:8
    - setRawPlansData:  types=v24@0:8@16
    - selectedTierIndex  types=q16@0:8
    - setSelectedTierIndex:  types=v24@0:8q16
    - isLoadingPlans  types=B16@0:8
    - setIsLoadingPlans:  types=v20@0:8B16
    - plansLoadFailed  types=B16@0:8
    - setPlansLoadFailed:  types=v20@0:8B16
    - orderCoordinator  types=@16@0:8
    - setOrderCoordinator:  types=v24@0:8@16
    - isCheckoutLoading  types=B16@0:8
    - setIsCheckoutLoading:  types=v20@0:8B16
    - giftCodeTextField  types=@16@0:8
    - setGiftCodeTextField:  types=v24@0:8@16
    - giftRedeemCell  types=@16@0:8
    - setGiftRedeemCell:  types=v24@0:8@16
    - isGiftRedeeming  types=B16@0:8
    - setIsGiftRedeeming:  types=v20@0:8B16
    - .cxx_destruct  types=v16@0:8

--- @interface CBLicenseExpiredModalViewController : UIViewController (instanceSize=88, ro_flags=0x184) ---
  ivars:
    _onActivateTapped : @? offset=8 size=8
    _onDismissTapped : @? offset=16 size=8
    _blurBackdrop : @"UIVisualEffectView" offset=24 size=8
    _dimmerOverlay : @"UIView" offset=32 size=8
    _cardView : @"UIView" offset=40 size=8
    _iconImageView : @"UIImageView" offset=48 size=8
    _titleLabel : @"UILabel" offset=56 size=8
    _messageLabel : @"UILabel" offset=64 size=8
    _activateButton : @"UIButton" offset=72 size=8
    _laterButton : @"UIButton" offset=80 size=8
  properties:
    blurBackdrop  attrs=T@"UIVisualEffectView",&,N,V_blurBackdrop
    dimmerOverlay  attrs=T@"UIView",&,N,V_dimmerOverlay
    cardView  attrs=T@"UIView",&,N,V_cardView
    iconImageView  attrs=T@"UIImageView",&,N,V_iconImageView
    titleLabel  attrs=T@"UILabel",&,N,V_titleLabel
    messageLabel  attrs=T@"UILabel",&,N,V_messageLabel
    activateButton  attrs=T@"UIButton",&,N,V_activateButton
    laterButton  attrs=T@"UIButton",&,N,V_laterButton
    onActivateTapped  attrs=T@?,C,N,V_onActivateTapped
    onDismissTapped  attrs=T@?,C,N,V_onDismissTapped
  instance methods (29):
    - viewDidLoad  types=v16@0:8
    - viewWillAppear:  types=v20@0:8B16
    - setupBackdrop  types=v16@0:8
    - setupCardView  types=v16@0:8
    - setupContent  types=v16@0:8
    - handleActivateTapped  types=v16@0:8
    - handleLaterTapped  types=v16@0:8
    - dismissWithCompletion:  types=v24@0:8@?16
    - onActivateTapped  types=@?16@0:8
    - setOnActivateTapped:  types=v24@0:8@?16
    - onDismissTapped  types=@?16@0:8
    - setOnDismissTapped:  types=v24@0:8@?16
    - blurBackdrop  types=@16@0:8
    - setBlurBackdrop:  types=v24@0:8@16
    - dimmerOverlay  types=@16@0:8
    - setDimmerOverlay:  types=v24@0:8@16
    - cardView  types=@16@0:8
    - setCardView:  types=v24@0:8@16
    - iconImageView  types=@16@0:8
    - setIconImageView:  types=v24@0:8@16
    - titleLabel  types=@16@0:8
    - setTitleLabel:  types=v24@0:8@16
    - messageLabel  types=@16@0:8
    - setMessageLabel:  types=v24@0:8@16
    - activateButton  types=@16@0:8
    - setActivateButton:  types=v24@0:8@16
    - laterButton  types=@16@0:8
    - setLaterButton:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8
  class methods (1):
    + modalWithActivateHandler:dismissHandler:  types=@32@0:8@?16@?24

--- @interface CBSubscriptionCheckoutCell : UITableViewCell (instanceSize=32, ro_flags=0x184) ---
  ivars:
    _delegate : @"<CBSubscriptionCheckoutCellDelegate>" offset=8 size=8
    _checkoutButton : @"UIButton" offset=16 size=8
    _checkoutSpinner : @"UIActivityIndicatorView" offset=24 size=8
  properties:
    checkoutButton  attrs=T@"UIButton",&,N,V_checkoutButton
    checkoutSpinner  attrs=T@"UIActivityIndicatorView",&,N,V_checkoutSpinner
    delegate  attrs=T@"<CBSubscriptionCheckoutCellDelegate>",W,N,V_delegate
  instance methods (10):
    - initWithStyle:reuseIdentifier:  types=@32@0:8q16@24
    - configureWithTitle:loading:  types=v28@0:8@16B24
    - checkoutTapped  types=v16@0:8
    - delegate  types=@16@0:8
    - setDelegate:  types=v24@0:8@16
    - checkoutButton  types=@16@0:8
    - setCheckoutButton:  types=v24@0:8@16
    - checkoutSpinner  types=@16@0:8
    - setCheckoutSpinner:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBSubscriptionVIPStatusCell : UITableViewCell (instanceSize=8, ro_flags=0x80) ---
  instance methods (2):
    - initWithStyle:reuseIdentifier:  types=@32@0:8q16@24
    - configureWithExpirationTimestamp:  types=v24@0:8Q16

--- @interface CBSubscriptionHardwareIDCell : UITableViewCell (instanceSize=32, ro_flags=0x184) ---
  ivars:
    _delegate : @"<CBSubscriptionHardwareIDCellDelegate>" offset=8 size=8
    _hwLabel : @"UILabel" offset=16 size=8
    _clipboardButton : @"UIButton" offset=24 size=8
  properties:
    hwLabel  attrs=T@"UILabel",&,N,V_hwLabel
    clipboardButton  attrs=T@"UIButton",&,N,V_clipboardButton
    delegate  attrs=T@"<CBSubscriptionHardwareIDCellDelegate>",W,N,V_delegate
  instance methods (10):
    - initWithStyle:reuseIdentifier:  types=@32@0:8q16@24
    - configureWithHardwareHash:  types=v24@0:8@16
    - copyTapped  types=v16@0:8
    - delegate  types=@16@0:8
    - setDelegate:  types=v24@0:8@16
    - hwLabel  types=@16@0:8
    - setHwLabel:  types=v24@0:8@16
    - clipboardButton  types=@16@0:8
    - setClipboardButton:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBSubscriptionGiftcodeInputCell : UITableViewCell (instanceSize=32, ro_flags=0x184) ---
  ivars:
    _delegate : @"<CBSubscriptionGiftcodeInputCellDelegate>" offset=8 size=8
    _textField : @"UITextField" offset=16 size=8
    _pasteButton : @"UIButton" offset=24 size=8
  properties:
    textField  attrs=T@"UITextField",&,N,V_textField
    pasteButton  attrs=T@"UIButton",&,N,V_pasteButton
    delegate  attrs=T@"<CBSubscriptionGiftcodeInputCellDelegate>",W,N,V_delegate
  instance methods (9):
    - initWithStyle:reuseIdentifier:  types=@32@0:8q16@24
    - pasteTapped  types=v16@0:8
    - delegate  types=@16@0:8
    - setDelegate:  types=v24@0:8@16
    - textField  types=@16@0:8
    - setTextField:  types=v24@0:8@16
    - pasteButton  types=@16@0:8
    - setPasteButton:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBSubscriptionGiftcodeRedeemCell : UITableViewCell (instanceSize=32, ro_flags=0x184) ---
  ivars:
    _delegate : @"<CBSubscriptionGiftcodeRedeemCellDelegate>" offset=8 size=8
    _redeemButton : @"UIButton" offset=16 size=8
    _spinner : @"UIActivityIndicatorView" offset=24 size=8
  properties:
    redeemButton  attrs=T@"UIButton",&,N,V_redeemButton
    spinner  attrs=T@"UIActivityIndicatorView",&,N,V_spinner
    delegate  attrs=T@"<CBSubscriptionGiftcodeRedeemCellDelegate>",W,N,V_delegate
  instance methods (10):
    - initWithStyle:reuseIdentifier:  types=@32@0:8q16@24
    - redeemTapped  types=v16@0:8
    - setLoading:  types=v20@0:8B16
    - delegate  types=@16@0:8
    - setDelegate:  types=v24@0:8@16
    - redeemButton  types=@16@0:8
    - setRedeemButton:  types=v24@0:8@16
    - spinner  types=@16@0:8
    - setSpinner:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBSubscriptionPendingOrderCell : UITableViewCell (instanceSize=56, ro_flags=0x184) ---
  ivars:
    _delegate : @"<CBSubscriptionPendingOrderCellDelegate>" offset=8 size=8
    _titleLabel : @"UILabel" offset=16 size=8
    _descLabel : @"UILabel" offset=24 size=8
    _resumeBtn : @"UIButton" offset=32 size=8
    _checkStatusButton : @"UIButton" offset=40 size=8
    _cancelBtn : @"UIButton" offset=48 size=8
  properties:
    titleLabel  attrs=T@"UILabel",&,N,V_titleLabel
    descLabel  attrs=T@"UILabel",&,N,V_descLabel
    resumeBtn  attrs=T@"UIButton",&,N,V_resumeBtn
    checkStatusButton  attrs=T@"UIButton",&,N,V_checkStatusButton
    cancelBtn  attrs=T@"UIButton",&,N,V_cancelBtn
    delegate  attrs=T@"<CBSubscriptionPendingOrderCellDelegate>",W,N,V_delegate
  instance methods (18):
    - initWithStyle:reuseIdentifier:  types=@32@0:8q16@24
    - configureWithTitle:description:  types=v32@0:8@16@24
    - resumeTapped  types=v16@0:8
    - checkStatusTapped  types=v16@0:8
    - cancelTapped  types=v16@0:8
    - delegate  types=@16@0:8
    - setDelegate:  types=v24@0:8@16
    - titleLabel  types=@16@0:8
    - setTitleLabel:  types=v24@0:8@16
    - descLabel  types=@16@0:8
    - setDescLabel:  types=v24@0:8@16
    - resumeBtn  types=@16@0:8
    - setResumeBtn:  types=v24@0:8@16
    - checkStatusButton  types=@16@0:8
    - setCheckStatusButton:  types=v24@0:8@16
    - cancelBtn  types=@16@0:8
    - setCancelBtn:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBSubscriptionPlanCardCell : UITableViewCell (instanceSize=48, ro_flags=0x184) ---
  ivars:
    _nameLabel : @"UILabel" offset=8 size=8
    _badgeLabel : @"UILabel" offset=16 size=8
    _descLabel : @"UILabel" offset=24 size=8
    _priceLabel : @"UILabel" offset=32 size=8
    _checkIcon : @"UIImageView" offset=40 size=8
  properties:
    nameLabel  attrs=T@"UILabel",&,N,V_nameLabel
    badgeLabel  attrs=T@"UILabel",&,N,V_badgeLabel
    descLabel  attrs=T@"UILabel",&,N,V_descLabel
    priceLabel  attrs=T@"UILabel",&,N,V_priceLabel
    checkIcon  attrs=T@"UIImageView",&,N,V_checkIcon
  instance methods (13):
    - initWithStyle:reuseIdentifier:  types=@32@0:8q16@24
    - configureWithPlan:selected:formattedPrice:  types=v36@0:8@16B24@28
    - nameLabel  types=@16@0:8
    - setNameLabel:  types=v24@0:8@16
    - badgeLabel  types=@16@0:8
    - setBadgeLabel:  types=v24@0:8@16
    - descLabel  types=@16@0:8
    - setDescLabel:  types=v24@0:8@16
    - priceLabel  types=@16@0:8
    - setPriceLabel:  types=v24@0:8@16
    - checkIcon  types=@16@0:8
    - setCheckIcon:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBSubscriptionStatusCell : UITableViewCell (instanceSize=8, ro_flags=0x80) ---
  instance methods (2):
    - initWithStyle:reuseIdentifier:  types=@32@0:8q16@24
    - configureWithLoading:failed:  types=v24@0:8B16B20

--- @interface CBSubscriptionVIPCardCell : UITableViewCell (instanceSize=80, ro_flags=0x184) ---
  ivars:
    _badgeIcon : @"UIImageView" offset=8 size=8
    _titleLabel : @"UILabel" offset=16 size=8
    _statusPillLabel : @"UILabel" offset=24 size=8
    _durationKeyLabel : @"UILabel" offset=32 size=8
    _durationValueLabel : @"UILabel" offset=40 size=8
    _serverExpiryKeyLabel : @"UILabel" offset=48 size=8
    _serverExpiryValueLabel : @"UILabel" offset=56 size=8
    _licenseValidationKeyLabel : @"UILabel" offset=64 size=8
    _licenseValidationValueLabel : @"UILabel" offset=72 size=8
  properties:
    badgeIcon  attrs=T@"UIImageView",&,N,V_badgeIcon
    titleLabel  attrs=T@"UILabel",&,N,V_titleLabel
    statusPillLabel  attrs=T@"UILabel",&,N,V_statusPillLabel
    durationKeyLabel  attrs=T@"UILabel",&,N,V_durationKeyLabel
    durationValueLabel  attrs=T@"UILabel",&,N,V_durationValueLabel
    serverExpiryKeyLabel  attrs=T@"UILabel",&,N,V_serverExpiryKeyLabel
    serverExpiryValueLabel  attrs=T@"UILabel",&,N,V_serverExpiryValueLabel
    licenseValidationKeyLabel  attrs=T@"UILabel",&,N,V_licenseValidationKeyLabel
    licenseValidationValueLabel  attrs=T@"UILabel",&,N,V_licenseValidationValueLabel
  instance methods (24):
    - initWithStyle:reuseIdentifier:  types=@32@0:8q16@24
    - keyLabel  types=@16@0:8
    - valueLabel  types=@16@0:8
    - keyValuePairWithKeyLabel:valueLabel:  types=@32@0:8@16@24
    - configureWithExpirationTimestamp:tierName:  types=v32@0:8Q16@24
    - badgeIcon  types=@16@0:8
    - setBadgeIcon:  types=v24@0:8@16
    - titleLabel  types=@16@0:8
    - setTitleLabel:  types=v24@0:8@16
    - statusPillLabel  types=@16@0:8
    - setStatusPillLabel:  types=v24@0:8@16
    - durationKeyLabel  types=@16@0:8
    - setDurationKeyLabel:  types=v24@0:8@16
    - durationValueLabel  types=@16@0:8
    - setDurationValueLabel:  types=v24@0:8@16
    - serverExpiryKeyLabel  types=@16@0:8
    - setServerExpiryKeyLabel:  types=v24@0:8@16
    - serverExpiryValueLabel  types=@16@0:8
    - setServerExpiryValueLabel:  types=v24@0:8@16
    - licenseValidationKeyLabel  types=@16@0:8
    - setLicenseValidationKeyLabel:  types=v24@0:8@16
    - licenseValidationValueLabel  types=@16@0:8
    - setLicenseValidationValueLabel:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBSubscriptionOrderCoordinator : NSObject (instanceSize=80, ro_flags=0x184) ---
  ivars:
    _delegate : @"<CBSubscriptionOrderCoordinatorDelegate>" offset=8 size=8
    _activeOrderId : @"NSString" offset=16 size=8
    _activePaymentUrl : @"NSString" offset=24 size=8
    _activeTierName : @"NSString" offset=32 size=8
    _activeAmountCrypto : @"NSString" offset=40 size=8
    _activeCurrency : @"NSString" offset=48 size=8
    _activeNetwork : @"NSString" offset=56 size=8
    _pollTimer : @"NSTimer" offset=64 size=8
    _safariVC : @"SFSafariViewController" offset=72 size=8
  properties:
    pollTimer  attrs=T@"NSTimer",&,N,V_pollTimer
    safariVC  attrs=T@"SFSafariViewController",&,N,V_safariVC
    delegate  attrs=T@"<CBSubscriptionOrderCoordinatorDelegate>",W,N,V_delegate
    activeOrderId  attrs=T@"NSString",C,N,V_activeOrderId
    activePaymentUrl  attrs=T@"NSString",C,N,V_activePaymentUrl
    activeTierName  attrs=T@"NSString",C,N,V_activeTierName
    activeAmountCrypto  attrs=T@"NSString",C,N,V_activeAmountCrypto
    activeCurrency  attrs=T@"NSString",C,N,V_activeCurrency
    activeNetwork  attrs=T@"NSString",C,N,V_activeNetwork
    hash  attrs=TQ,R
    superclass  attrs=T#,R
    description  attrs=T@"NSString",R,C
    debugDescription  attrs=T@"NSString",R,C
  instance methods (36):
    - dealloc  types=v16@0:8
    - hasActivePendingOrder  types=B16@0:8
    - currentServerBaseURL  types=@16@0:8
    - fetchActivePendingOrderFromServer  types=v16@0:8
    - startCheckoutForTier:forceNew:  types=v28@0:8@16B24
    - resumePayment  types=v16@0:8
    - checkStatusManual  types=v16@0:8
    - cancelActiveOrderWithCompletion:  types=v24@0:8@?16
    - requestCancelPendingOrder  types=v16@0:8
    - openPaymentGatewayURL:  types=v24@0:8@16
    - safariViewControllerDidFinish:  types=v24@0:8@16
    - startPollingOrderStatus:  types=v24@0:8@16
    - stopPollingOrderStatus  types=v16@0:8
    - pollTimerFired  types=v16@0:8
    - checkOrderStatusOnce:  types=v24@0:8@16
    - handlePaymentCompletedSuccess  types=v16@0:8
    - showAlertWithTitle:message:  types=v32@0:8@16@24
    - delegate  types=@16@0:8
    - setDelegate:  types=v24@0:8@16
    - activeOrderId  types=@16@0:8
    - setActiveOrderId:  types=v24@0:8@16
    - activePaymentUrl  types=@16@0:8
    - setActivePaymentUrl:  types=v24@0:8@16
    - activeTierName  types=@16@0:8
    - setActiveTierName:  types=v24@0:8@16
    - activeAmountCrypto  types=@16@0:8
    - setActiveAmountCrypto:  types=v24@0:8@16
    - activeCurrency  types=@16@0:8
    - setActiveCurrency:  types=v24@0:8@16
    - activeNetwork  types=@16@0:8
    - setActiveNetwork:  types=v24@0:8@16
    - pollTimer  types=@16@0:8
    - setPollTimer:  types=v24@0:8@16
    - safariVC  types=@16@0:8
    - setSafariVC:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBLocalization : NSObject (instanceSize=48, ro_flags=0x184) ---
  ivars:
    _activeLanguageCode : @"NSString" offset=8 size=8
    _cachedStringTables : @"NSMutableDictionary" offset=16 size=8
    _activeLanguageTable : @"NSDictionary" offset=24 size=8
    _viTable : @"NSDictionary" offset=32 size=8
    _enTable : @"NSDictionary" offset=40 size=8
  instance methods (6):
    - init  types=@16@0:8
    - reloadLanguage  types=v16@0:8
    - activeLanguageCode  types=@16@0:8
    - stringTableForLanguageCode:  types=@24@0:8@16
    - localizedStringForKey:  types=@24@0:8@16
    - .cxx_destruct  types=v16@0:8
  class methods (7):
    + sharedInstance  types=@16@0:8
    + speechVoiceLanguageCode  types=@16@0:8
    + supportedLanguages  types=@16@0:8
    + displayNameForLanguageCode:  types=@24@0:8@16
    + currentLanguageCode  types=@16@0:8
    + setCurrentLanguageCode:  types=v24@0:8@16
    + localizedStringForKey:  types=@24@0:8@16

--- @interface CBSplitSplashScreenView : UIView (instanceSize=112, ro_flags=0x184) ---
  ivars:
    _glowImageView : @"UIImageView" offset=8 size=8
    _horizonLineView : @"UIView" offset=16 size=8
    _horizonGradient : @"CAGradientLayer" offset=24 size=8
    _horizonDashedMask : @"CAShapeLayer" offset=32 size=8
    _logoImageView : @"UIImageView" offset=40 size=8
    _trackView : @"UIView" offset=48 size=8
    _progressView : @"UIView" offset=56 size=8
    _progressGradient : @"CAGradientLayer" offset=64 size=8
    _badgeLabel : @"UILabel" offset=72 size=8
    _isDismissing : B offset=80 size=1
    _hasStartedAnimation : B offset=81 size=1
    _animationStartTime : d offset=88 size=8
    _onWillDismiss : @? offset=96 size=8
    _onDismissed : @? offset=104 size=8
  properties:
    isDismissing  attrs=TB,R,N
    onWillDismiss  attrs=T@?,C,N,V_onWillDismiss
    onDismissed  attrs=T@?,C,N,V_onDismissed
  instance methods (13):
    - initWithFrame:  types=@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - layoutSubviews  types=v16@0:8
    - startLoadingAnimation  types=v16@0:8
    - handleTap:  types=v24@0:8@16
    - isDismissing  types=B16@0:8
    - dismissAnimated:  types=v20@0:8B16
    - dismissAnimated:completion:  types=v28@0:8B16@?20
    - dealloc  types=v16@0:8
    - onWillDismiss  types=@?16@0:8
    - setOnWillDismiss:  types=v24@0:8@?16
    - onDismissed  types=@?16@0:8
    - setOnDismissed:  types=v24@0:8@?16
    - .cxx_destruct  types=v16@0:8
  class methods (3):
    + logoImage  types=@16@0:8
    + appIconImage  types=@16@0:8
    + radialGlowImageForDiameter:  types=@24@0:8d16

--- @interface CBHttpClient : NSObject (instanceSize=16, ro_flags=0x184) ---
  ivars:
    _networkQueue : @"NSObject<OS_dispatch_queue>" offset=8 size=8
  properties:
    networkQueue  attrs=T@"NSObject<OS_dispatch_queue>",&,N,V_networkQueue
  instance methods (6):
    - init  types=@16@0:8
    - postJSON:toURL:timeout:customHeaders:completion:  types=v56@0:8@16@24d32@40@?48
    - getJSONFromURL:timeout:customHeaders:completion:  types=v48@0:8@16d24@32@?40
    - networkQueue  types=@16@0:8
    - setNetworkQueue:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8
  class methods (1):
    + sharedClient  types=@16@0:8

--- @interface CBLicenseSyncManager : NSObject (instanceSize=32, ro_flags=0x184) ---
  ivars:
    _isSyncing : B offset=8 size=1
    _syncQueue : @"NSObject<OS_dispatch_queue>" offset=16 size=8
    _lastAttemptTimestamp : Q offset=24 size=8
  properties:
    isSyncing  attrs=TB,N,V_isSyncing
    syncQueue  attrs=T@"NSObject<OS_dispatch_queue>",&,N,V_syncQueue
    lastAttemptTimestamp  attrs=TQ,N,V_lastAttemptTimestamp
  instance methods (24):
    - init  types=@16@0:8
    - deviceHardwareHashHex  types=@16@0:8
    - isLicenseCurrentlyValid  types=B16@0:8
    - remainingLicenseSeconds  types=Q16@0:8
    - isCarPlayScreenConnected  types=B16@0:8
    - checkAndSyncLicenseIfNeeded  types=v16@0:8
    - checkAndSyncLicenseIfNeededWithSource:  types=v24@0:8@16
    - forceSyncWithCompletion:  types=v24@0:8@?16
    - resolvedBackendBaseURL  types=@16@0:8
    - resolvedLicenseServerEndpoint  types=@16@0:8
    - performSyncWithForce:isManualUserAction:completion:  types=v32@0:8B16B20@?24
    - performSyncWithForce:isManualUserAction:source:completion:  types=v40@0:8B16B20@24@?32
    - installAndVerifyLicensePayload:errorMsg:  types=B32@0:8@16^@24
    - actualLicenseExpirationTimestamp  types=Q16@0:8
    - setActualLicenseExpirationTimestamp:  types=v24@0:8Q16
    - actualLicenseTierName  types=@16@0:8
    - setActualLicenseTierName:  types=v24@0:8@16
    - isSyncing  types=B16@0:8
    - setIsSyncing:  types=v20@0:8B16
    - syncQueue  types=@16@0:8
    - setSyncQueue:  types=v24@0:8@16
    - lastAttemptTimestamp  types=Q16@0:8
    - setLastAttemptTimestamp:  types=v24@0:8Q16
    - .cxx_destruct  types=v16@0:8
  class methods (6):
    + sharedInstance  types=@16@0:8
    + isCarPlayScreen:  types=B24@0:8@16
    + isCarPlayScreenConnectedExcludingScreen:  types=B24@0:8@16
    + isCarPlayScreenConnected  types=B16@0:8
    + formatBaseURLString:  types=@24@0:8@16
    + resolvedBackendBaseURL  types=@16@0:8
```


### 4.2 DuoFaceDashboard — 36 class, 757 method, 179 property, 215 ivar (mỗi slice)

```

--- @interface CBLocalization : NSObject (instanceSize=48, ro_flags=0x194) ---
  ivars:
    _activeLanguageCode : @"NSString" offset=8 size=8
    _cachedStringTables : @"NSMutableDictionary" offset=16 size=8
    _activeLanguageTable : @"NSDictionary" offset=24 size=8
    _viTable : @"NSDictionary" offset=32 size=8
    _enTable : @"NSDictionary" offset=40 size=8
  instance methods (6):
    - init  types=@16@0:8
    - reloadLanguage  types=v16@0:8
    - activeLanguageCode  types=@16@0:8
    - stringTableForLanguageCode:  types=@24@0:8@16
    - localizedStringForKey:  types=@24@0:8@16
    - .cxx_destruct  types=v16@0:8
  class methods (7):
    + sharedInstance  types=@16@0:8
    + speechVoiceLanguageCode  types=@16@0:8
    + supportedLanguages  types=@16@0:8
    + displayNameForLanguageCode:  types=@24@0:8@16
    + currentLanguageCode  types=@16@0:8
    + setCurrentLanguageCode:  types=v24@0:8@16
    + localizedStringForKey:  types=@24@0:8@16

--- @interface CBAssistantManager : NSObject (instanceSize=152, ro_flags=0x194) ---
  ivars:
    _isListening : B offset=8 size=1
    _voiceFeedbackEnabled : B offset=9 size=1
    _preferredMapIndex : q offset=16 size=8
    _onStatusUpdate : @? offset=24 size=8
    _speechRecognizer : @"SFSpeechRecognizer" offset=32 size=8
    _recognitionRequest : @"SFSpeechAudioBufferRecognitionRequest" offset=40 size=8
    _recognitionTask : @"SFSpeechRecognitionTask" offset=48 size=8
    _audioEngine : @"AVAudioEngine" offset=56 size=8
    _speechSynthesizer : @"AVSpeechSynthesizer" offset=64 size=8
    _recordedPCMData : @"NSMutableData" offset=72 size=8
    _speakCompletion : @? offset=80 size=8
    _silenceTimer : @"NSTimer" offset=88 size=8
    _lastTranscribedText : @"NSString" offset=96 size=8
    _hudWindow : @"UIWindow" offset=104 size=8
    _hudCard : @"UIVisualEffectView" offset=112 size=8
    _micIconView : @"UIImageView" offset=120 size=8
    _statusLabel : @"UILabel" offset=128 size=8
    _transcriptLabel : @"UILabel" offset=136 size=8
    _pulseAnimation : @"CABasicAnimation" offset=144 size=8
  properties:
    speechRecognizer  attrs=T@"SFSpeechRecognizer",&,N,V_speechRecognizer
    recognitionRequest  attrs=T@"SFSpeechAudioBufferRecognitionRequest",&,N,V_recognitionRequest
    recognitionTask  attrs=T@"SFSpeechRecognitionTask",&,N,V_recognitionTask
    audioEngine  attrs=T@"AVAudioEngine",&,N,V_audioEngine
    speechSynthesizer  attrs=T@"AVSpeechSynthesizer",&,N,V_speechSynthesizer
    recordedPCMData  attrs=T@"NSMutableData",&,N,V_recordedPCMData
    isListening  attrs=TB,N,V_isListening
    speakCompletion  attrs=T@?,C,N,V_speakCompletion
    silenceTimer  attrs=T@"NSTimer",&,N,V_silenceTimer
    lastTranscribedText  attrs=T@"NSString",C,N,V_lastTranscribedText
    hudWindow  attrs=T@"UIWindow",&,N,V_hudWindow
    hudCard  attrs=T@"UIVisualEffectView",&,N,V_hudCard
    micIconView  attrs=T@"UIImageView",&,N,V_micIconView
    statusLabel  attrs=T@"UILabel",&,N,V_statusLabel
    transcriptLabel  attrs=T@"UILabel",&,N,V_transcriptLabel
    pulseAnimation  attrs=T@"CABasicAnimation",&,N,V_pulseAnimation
    preferredMapIndex  attrs=Tq,N,V_preferredMapIndex
    voiceFeedbackEnabled  attrs=TB,N,V_voiceFeedbackEnabled
    onStatusUpdate  attrs=T@?,C,N,V_onStatusUpdate
    hash  attrs=TQ,R
    superclass  attrs=T#,R
    description  attrs=T@"NSString",R,C
    debugDescription  attrs=T@"NSString",R,C
  instance methods (68):
    - init  types=@16@0:8
    - dealloc  types=v16@0:8
    - cb_onLanguageChanged:  types=v24@0:8@16
    - reloadPreferences  types=v16@0:8
    - setupSpeechSynthesizer  types=v16@0:8
    - setupSpeechRecognizer  types=v16@0:8
    - speak:completion:  types=v32@0:8@16@?24
    - stopSpeaking  types=v16@0:8
    - speechSynthesizer:didFinishSpeechUtterance:  types=v32@0:8@16@24
    - toggleListening  types=v16@0:8
    - startListening  types=v16@0:8
    - beginRecordingSession  types=v16@0:8
    - resetSilenceTimer  types=v16@0:8
    - listeningTimeout  types=v16@0:8
    - finishListeningAndProcess  types=v16@0:8
    - stopListening  types=v16@0:8
    - transcribeAudioData:completion:  types=v32@0:8@16@?24
    - processVoiceCommand:  types=v24@0:8@16
    - handleNavigationCommand:  types=v24@0:8@16
    - handleAppLaunchCommand:  types=v24@0:8@16
    - handleMusicCommand:  types=v24@0:8@16
    - triggerBridgeApp:  types=v24@0:8@16
    - dismissCarBridgeApp  types=v16@0:8
    - showHUD  types=v16@0:8
    - startMicPulseAnimation  types=v16@0:8
    - stopMicPulseAnimation  types=v16@0:8
    - updateHUDStatus:subtext:  types=v32@0:8@16@24
    - stopListeningAndDismiss  types=v16@0:8
    - dismissHUD  types=v16@0:8
    - isListening  types=B16@0:8
    - setIsListening:  types=v20@0:8B16
    - preferredMapIndex  types=q16@0:8
    - setPreferredMapIndex:  types=v24@0:8q16
    - voiceFeedbackEnabled  types=B16@0:8
    - setVoiceFeedbackEnabled:  types=v20@0:8B16
    - onStatusUpdate  types=@?16@0:8
    - setOnStatusUpdate:  types=v24@0:8@?16
    - speechRecognizer  types=@16@0:8
    - setSpeechRecognizer:  types=v24@0:8@16
    - recognitionRequest  types=@16@0:8
    - setRecognitionRequest:  types=v24@0:8@16
    - recognitionTask  types=@16@0:8
    - setRecognitionTask:  types=v24@0:8@16
    - audioEngine  types=@16@0:8
    - setAudioEngine:  types=v24@0:8@16
    - speechSynthesizer  types=@16@0:8
    - setSpeechSynthesizer:  types=v24@0:8@16
    - recordedPCMData  types=@16@0:8
    - setRecordedPCMData:  types=v24@0:8@16
    - speakCompletion  types=@?16@0:8
    - setSpeakCompletion:  types=v24@0:8@?16
    - silenceTimer  types=@16@0:8
    - setSilenceTimer:  types=v24@0:8@16
    - lastTranscribedText  types=@16@0:8
    - setLastTranscribedText:  types=v24@0:8@16
    - hudWindow  types=@16@0:8
    - setHudWindow:  types=v24@0:8@16
    - hudCard  types=@16@0:8
    - setHudCard:  types=v24@0:8@16
    - micIconView  types=@16@0:8
    - setMicIconView:  types=v24@0:8@16
    - statusLabel  types=@16@0:8
    - setStatusLabel:  types=v24@0:8@16
    - transcriptLabel  types=@16@0:8
    - setTranscriptLabel:  types=v24@0:8@16
    - pulseAnimation  types=@16@0:8
    - setPulseAnimation:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8
  class methods (1):
    + sharedInstance  types=@16@0:8

--- @interface CBDashboardSettings : NSObject (instanceSize=144, ro_flags=0x194) ---
  ivars:
    _portalAppEnabled : B offset=8 size=1
    _screenBlankEnabled : B offset=9 size=1
    _splitScreenEnabled : B offset=10 size=1
    _assistantEnabled : B offset=11 size=1
    _voiceFeedbackEnabled : B offset=12 size=1
    _hideIconLabels : B offset=13 size=1
    _dockSystemMonitorEnabled : B offset=14 size=1
    _dockSystemMonitorShowAll : B offset=15 size=1
    _autoLaunchOnConnect : B offset=16 size=1
    _agreedToEULA : B offset=17 size=1
    _bridgedApps : @"NSArray" offset=24 size=8
    _appSettings : @"NSDictionary" offset=32 size=8
    _preferredMapIndex : q offset=40 size=8
    _splitLeftBundleID : @"NSString" offset=48 size=8
    _splitRightBundleID : @"NSString" offset=56 size=8
    _splitPreset : q offset=64 size=8
    _splitMode : q offset=72 size=8
    _splitApp1 : @"NSString" offset=80 size=8
    _splitApp2 : @"NSString" offset=88 size=8
    _splitApp3 : @"NSString" offset=96 size=8
    _splitApp4 : @"NSString" offset=104 size=8
    _splitRatio : d offset=112 size=8
    _gridCols : q offset=120 size=8
    _gridRows : q offset=128 size=8
    _autoLaunchBundleID : @"NSString" offset=136 size=8
  properties:
    bridgedApps  attrs=T@"NSArray",&,N,V_bridgedApps
    appSettings  attrs=T@"NSDictionary",&,N,V_appSettings
    portalAppEnabled  attrs=TB,N,V_portalAppEnabled
    screenBlankEnabled  attrs=TB,N,V_screenBlankEnabled
    splitScreenEnabled  attrs=TB,N,V_splitScreenEnabled
    assistantEnabled  attrs=TB,N,V_assistantEnabled
    preferredMapIndex  attrs=Tq,N,V_preferredMapIndex
    voiceFeedbackEnabled  attrs=TB,N,V_voiceFeedbackEnabled
    splitLeftBundleID  attrs=T@"NSString",C,N,V_splitLeftBundleID
    splitRightBundleID  attrs=T@"NSString",C,N,V_splitRightBundleID
    splitPreset  attrs=Tq,N,V_splitPreset
    splitMode  attrs=Tq,N,V_splitMode
    splitApp1  attrs=T@"NSString",C,N,V_splitApp1
    splitApp2  attrs=T@"NSString",C,N,V_splitApp2
    splitApp3  attrs=T@"NSString",C,N,V_splitApp3
    splitApp4  attrs=T@"NSString",C,N,V_splitApp4
    splitRatio  attrs=Td,N,V_splitRatio
    gridCols  attrs=Tq,N,V_gridCols
    gridRows  attrs=Tq,N,V_gridRows
    hideIconLabels  attrs=TB,N,V_hideIconLabels
    dockSystemMonitorEnabled  attrs=TB,N,V_dockSystemMonitorEnabled
    dockSystemMonitorShowAll  attrs=TB,N,V_dockSystemMonitorShowAll
    autoLaunchOnConnect  attrs=TB,N,V_autoLaunchOnConnect
    autoLaunchBundleID  attrs=T@"NSString",C,N,V_autoLaunchBundleID
    agreedToEULA  attrs=TB,N,V_agreedToEULA
  instance methods (56):
    - init  types=@16@0:8
    - scaleForBundleID:  types=d24@0:8@16
    - setScale:forBundleID:  types=v32@0:8d16@24
    - setDockSystemMonitorEnabled:  types=v20@0:8B16
    - setDockSystemMonitorShowAll:  types=v20@0:8B16
    - reload  types=v16@0:8
    - reloadAppPrefs  types=v16@0:8
    - bridgedApps  types=@16@0:8
    - setBridgedApps:  types=v24@0:8@16
    - appSettings  types=@16@0:8
    - setAppSettings:  types=v24@0:8@16
    - portalAppEnabled  types=B16@0:8
    - setPortalAppEnabled:  types=v20@0:8B16
    - screenBlankEnabled  types=B16@0:8
    - setScreenBlankEnabled:  types=v20@0:8B16
    - splitScreenEnabled  types=B16@0:8
    - setSplitScreenEnabled:  types=v20@0:8B16
    - assistantEnabled  types=B16@0:8
    - setAssistantEnabled:  types=v20@0:8B16
    - preferredMapIndex  types=q16@0:8
    - setPreferredMapIndex:  types=v24@0:8q16
    - voiceFeedbackEnabled  types=B16@0:8
    - setVoiceFeedbackEnabled:  types=v20@0:8B16
    - splitLeftBundleID  types=@16@0:8
    - setSplitLeftBundleID:  types=v24@0:8@16
    - splitRightBundleID  types=@16@0:8
    - setSplitRightBundleID:  types=v24@0:8@16
    - splitPreset  types=q16@0:8
    - setSplitPreset:  types=v24@0:8q16
    - splitMode  types=q16@0:8
    - setSplitMode:  types=v24@0:8q16
    - splitApp1  types=@16@0:8
    - setSplitApp1:  types=v24@0:8@16
    - splitApp2  types=@16@0:8
    - setSplitApp2:  types=v24@0:8@16
    - splitApp3  types=@16@0:8
    - setSplitApp3:  types=v24@0:8@16
    - splitApp4  types=@16@0:8
    - setSplitApp4:  types=v24@0:8@16
    - splitRatio  types=d16@0:8
    - setSplitRatio:  types=v24@0:8d16
    - gridCols  types=q16@0:8
    - setGridCols:  types=v24@0:8q16
    - gridRows  types=q16@0:8
    - setGridRows:  types=v24@0:8q16
    - hideIconLabels  types=B16@0:8
    - setHideIconLabels:  types=v20@0:8B16
    - dockSystemMonitorEnabled  types=B16@0:8
    - dockSystemMonitorShowAll  types=B16@0:8
    - autoLaunchOnConnect  types=B16@0:8
    - setAutoLaunchOnConnect:  types=v20@0:8B16
    - autoLaunchBundleID  types=@16@0:8
    - setAutoLaunchBundleID:  types=v24@0:8@16
    - agreedToEULA  types=B16@0:8
    - setAgreedToEULA:  types=v20@0:8B16
    - .cxx_destruct  types=v16@0:8
  class methods (5):
    + sharedInstance  types=@16@0:8
    + assistantIconImage  types=@16@0:8
    + portalAppIconImage  types=@16@0:8
    + splitScreenIconImage  types=@16@0:8
    + portalAppIdentifier  types=@16@0:8

--- @interface CBHttpClient : NSObject (instanceSize=16, ro_flags=0x194) ---
  ivars:
    _networkQueue : @"NSObject<OS_dispatch_queue>" offset=8 size=8
  properties:
    networkQueue  attrs=T@"NSObject<OS_dispatch_queue>",&,N,V_networkQueue
  instance methods (6):
    - init  types=@16@0:8
    - postJSON:toURL:timeout:customHeaders:completion:  types=v56@0:8@16@24d32@40@?48
    - getJSONFromURL:timeout:customHeaders:completion:  types=v48@0:8@16d24@32@?40
    - networkQueue  types=@16@0:8
    - setNetworkQueue:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8
  class methods (1):
    + sharedClient  types=@16@0:8

--- @interface CBLicenseSyncManager : NSObject (instanceSize=32, ro_flags=0x194) ---
  ivars:
    _isSyncing : B offset=8 size=1
    _syncQueue : @"NSObject<OS_dispatch_queue>" offset=16 size=8
    _lastAttemptTimestamp : Q offset=24 size=8
  properties:
    isSyncing  attrs=TB,N,V_isSyncing
    syncQueue  attrs=T@"NSObject<OS_dispatch_queue>",&,N,V_syncQueue
    lastAttemptTimestamp  attrs=TQ,N,V_lastAttemptTimestamp
  instance methods (24):
    - init  types=@16@0:8
    - deviceHardwareHashHex  types=@16@0:8
    - isLicenseCurrentlyValid  types=B16@0:8
    - remainingLicenseSeconds  types=Q16@0:8
    - isCarPlayScreenConnected  types=B16@0:8
    - checkAndSyncLicenseIfNeeded  types=v16@0:8
    - checkAndSyncLicenseIfNeededWithSource:  types=v24@0:8@16
    - forceSyncWithCompletion:  types=v24@0:8@?16
    - resolvedBackendBaseURL  types=@16@0:8
    - resolvedLicenseServerEndpoint  types=@16@0:8
    - performSyncWithForce:isManualUserAction:completion:  types=v32@0:8B16B20@?24
    - performSyncWithForce:isManualUserAction:source:completion:  types=v40@0:8B16B20@24@?32
    - installAndVerifyLicensePayload:errorMsg:  types=B32@0:8@16^@24
    - actualLicenseExpirationTimestamp  types=Q16@0:8
    - setActualLicenseExpirationTimestamp:  types=v24@0:8Q16
    - actualLicenseTierName  types=@16@0:8
    - setActualLicenseTierName:  types=v24@0:8@16
    - isSyncing  types=B16@0:8
    - setIsSyncing:  types=v20@0:8B16
    - syncQueue  types=@16@0:8
    - setSyncQueue:  types=v24@0:8@16
    - lastAttemptTimestamp  types=Q16@0:8
    - setLastAttemptTimestamp:  types=v24@0:8Q16
    - .cxx_destruct  types=v16@0:8
  class methods (6):
    + sharedInstance  types=@16@0:8
    + isCarPlayScreen:  types=B24@0:8@16
    + isCarPlayScreenConnectedExcludingScreen:  types=B24@0:8@16
    + isCarPlayScreenConnected  types=B16@0:8
    + formatBaseURLString:  types=@24@0:8@16
    + resolvedBackendBaseURL  types=@16@0:8

--- @interface CBTouchCloneView : UIView (instanceSize=8, ro_flags=0x90) ---
  instance methods (5):
    - sendTouchEventAtPoint:isDown:  types=v36@0:8{CGPoint=dd}16B32
    - touchesBegan:withEvent:  types=v32@0:8@16@24
    - touchesMoved:withEvent:  types=v32@0:8@16@24
    - touchesEnded:withEvent:  types=v32@0:8@16@24
    - touchesCancelled:withEvent:  types=v32@0:8@16@24

--- @interface CBBridgedPortalAppView : UIView (instanceSize=32, ro_flags=0x194) ---
  ivars:
    _imageView : @"UIImageView" offset=8 size=8
    _touchCloneView : @"CBTouchCloneView" offset=16 size=8
    _displayLink : @"CADisplayLink" offset=24 size=8
  properties:
    imageView  attrs=T@"UIImageView",&,N,V_imageView
    touchCloneView  attrs=T@"CBTouchCloneView",&,N,V_touchCloneView
    displayLink  attrs=T@"CADisplayLink",&,N,V_displayLink
  instance methods (12):
    - initWithFrame:  types=@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - start  types=v16@0:8
    - stop  types=v16@0:8
    - captureFrame:  types=v24@0:8@16
    - dealloc  types=v16@0:8
    - imageView  types=@16@0:8
    - setImageView:  types=v24@0:8@16
    - touchCloneView  types=@16@0:8
    - setTouchCloneView:  types=v24@0:8@16
    - displayLink  types=@16@0:8
    - setDisplayLink:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBMultitaskingPillView : UIView (instanceSize=40, ro_flags=0x194) ---
  ivars:
    _onPillTapped : @? offset=8 size=8
    _blurView : @"UIVisualEffectView" offset=16 size=8
    _iconView : @"UIImageView" offset=24 size=8
    _titleLabel : @"UILabel" offset=32 size=8
  properties:
    onPillTapped  attrs=T@?,C,N,V_onPillTapped
    blurView  attrs=T@"UIVisualEffectView",&,N,V_blurView
    iconView  attrs=T@"UIImageView",&,N,V_iconView
    titleLabel  attrs=T@"UILabel",&,N,V_titleLabel
  instance methods (12):
    - initWithFrame:  types=@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - pillTapped  types=v16@0:8
    - pillPanned:  types=v24@0:8@16
    - onPillTapped  types=@?16@0:8
    - setOnPillTapped:  types=v24@0:8@?16
    - blurView  types=@16@0:8
    - setBlurView:  types=v24@0:8@16
    - iconView  types=@16@0:8
    - setIconView:  types=v24@0:8@16
    - titleLabel  types=@16@0:8
    - setTitleLabel:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBSlotPillHitButton : UIButton (instanceSize=40, ro_flags=0x90) ---
  ivars:
    _hitInsets : {UIEdgeInsets="top"d"left"d"bottom"d"right"d} offset=8 size=32
  properties:
    hitInsets  attrs=T{UIEdgeInsets=dddd},N,V_hitInsets
  instance methods (3):
    - pointInside:withEvent:  types=B40@0:8{CGPoint=dd}16@32
    - hitInsets  types={UIEdgeInsets=dddd}16@0:8
    - setHitInsets:  types=v48@0:8{UIEdgeInsets=dddd}16

--- @interface CBSlotPillView : UIView (instanceSize=96, ro_flags=0x194) ---
  ivars:
    _dotViews : @"NSMutableArray" offset=8 size=8
    _isFocusedMode : B offset=16 size=1
    _showsExpandButton : B offset=17 size=1
    _isCompactMode : B offset=18 size=1
    _onPillTapped : @? offset=24 size=8
    _onPillLongPressed : @? offset=32 size=8
    _onExpandTapped : @? offset=40 size=8
    _onRestoreTapped : @? offset=48 size=8
    _slotIndex : q offset=56 size=8
    _dotsButton : @"UIButton" offset=64 size=8
    _expandButton : @"UIButton" offset=72 size=8
    _restoreButton : @"UIButton" offset=80 size=8
    _separatorView : @"UIView" offset=88 size=8
  properties:
    onPillTapped  attrs=T@?,C,N,V_onPillTapped
    onPillLongPressed  attrs=T@?,C,N,V_onPillLongPressed
    onExpandTapped  attrs=T@?,C,N,V_onExpandTapped
    onRestoreTapped  attrs=T@?,C,N,V_onRestoreTapped
    slotIndex  attrs=Tq,N,V_slotIndex
    isFocusedMode  attrs=TB,N,V_isFocusedMode
    showsExpandButton  attrs=TB,N,V_showsExpandButton
    isCompactMode  attrs=TB,N,V_isCompactMode
    dotsButton  attrs=T@"UIButton",&,N,V_dotsButton
    expandButton  attrs=T@"UIButton",&,N,V_expandButton
    restoreButton  attrs=T@"UIButton",&,N,V_restoreButton
    separatorView  attrs=T@"UIView",&,N,V_separatorView
  instance methods (36):
    - initWithSlotIndex:  types=@24@0:8q16
    - layoutSubviews  types=v16@0:8
    - updateBoundsSize  types=v16@0:8
    - setShowsExpandButton:  types=v20@0:8B16
    - setFocusedMode:  types=v20@0:8B16
    - setCompactMode:  types=v20@0:8B16
    - pointInside:withEvent:  types=B40@0:8{CGPoint=dd}16@32
    - handleLongPress:  types=v24@0:8@16
    - dotsTapped:  types=v24@0:8@16
    - expandTapped:  types=v24@0:8@16
    - restoreTapped:  types=v24@0:8@16
    - bounceButton:  types=v24@0:8@16
    - onPillTapped  types=@?16@0:8
    - setOnPillTapped:  types=v24@0:8@?16
    - onPillLongPressed  types=@?16@0:8
    - setOnPillLongPressed:  types=v24@0:8@?16
    - onExpandTapped  types=@?16@0:8
    - setOnExpandTapped:  types=v24@0:8@?16
    - onRestoreTapped  types=@?16@0:8
    - setOnRestoreTapped:  types=v24@0:8@?16
    - slotIndex  types=q16@0:8
    - setSlotIndex:  types=v24@0:8q16
    - isFocusedMode  types=B16@0:8
    - setIsFocusedMode:  types=v20@0:8B16
    - showsExpandButton  types=B16@0:8
    - isCompactMode  types=B16@0:8
    - setIsCompactMode:  types=v20@0:8B16
    - dotsButton  types=@16@0:8
    - setDotsButton:  types=v24@0:8@16
    - expandButton  types=@16@0:8
    - setExpandButton:  types=v24@0:8@16
    - restoreButton  types=@16@0:8
    - setRestoreButton:  types=v24@0:8@16
    - separatorView  types=@16@0:8
    - setSeparatorView:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBOverlayScrollView : UIScrollView (instanceSize=8, ro_flags=0x90) ---
  instance methods (4):
    - initWithFrame:  types=@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - touchesShouldCancelInContentView:  types=B24@0:8@16
    - addSubview:  types=v24@0:8@16
    - layoutSubviews  types=v16@0:8

--- @interface CBMultitaskingOverlayView : UIView (instanceSize=160, ro_flags=0x194) ---
  ivars:
    _onCloseRequested : @? offset=8 size=8
    _onMultiSplitSelected : @? offset=16 size=8
    _dimBackground : @"UIView" offset=24 size=8
    _cardShadowContainer : @"UIView" offset=32 size=8
    _sheetCard : @"UIVisualEffectView" offset=40 size=8
    _allApps : @"NSArray" offset=48 size=8
    _appPickerScrollView : @"UIScrollView" offset=56 size=8
    _appPickerPageControl : @"UIPageControl" offset=64 size=8
    _slotBIDs : @"NSMutableArray" offset=72 size=8
    _currentPreset : q offset=80 size=8
    _currentRatio : d offset=88 size=8
    _targetSlotIndex : q offset=96 size=8
    _overlayMode : q offset=104 size=8
    _headerIcon : @"UIImageView" offset=112 size=8
    _titleLabel : @"UILabel" offset=120 size=8
    _appSegmentBtn : @"UIButton" offset=128 size=8
    _layoutSegmentBtn : @"UIButton" offset=136 size=8
    _recentSegmentBtn : @"UIButton" offset=144 size=8
    _runningApps : @"NSArray" offset=152 size=8
  properties:
    onCloseRequested  attrs=T@?,C,N,V_onCloseRequested
    onMultiSplitSelected  attrs=T@?,C,N,V_onMultiSplitSelected
    dimBackground  attrs=T@"UIView",&,N,V_dimBackground
    cardShadowContainer  attrs=T@"UIView",&,N,V_cardShadowContainer
    sheetCard  attrs=T@"UIVisualEffectView",&,N,V_sheetCard
    allApps  attrs=T@"NSArray",&,N,V_allApps
    appPickerScrollView  attrs=T@"UIScrollView",&,N,V_appPickerScrollView
    appPickerPageControl  attrs=T@"UIPageControl",&,N,V_appPickerPageControl
    slotBIDs  attrs=T@"NSMutableArray",&,N,V_slotBIDs
    currentPreset  attrs=Tq,N,V_currentPreset
    currentRatio  attrs=Td,N,V_currentRatio
    targetSlotIndex  attrs=Tq,N,V_targetSlotIndex
    overlayMode  attrs=Tq,N,V_overlayMode
    headerIcon  attrs=T@"UIImageView",&,N,V_headerIcon
    titleLabel  attrs=T@"UILabel",&,N,V_titleLabel
    appSegmentBtn  attrs=T@"UIButton",&,N,V_appSegmentBtn
    layoutSegmentBtn  attrs=T@"UIButton",&,N,V_layoutSegmentBtn
    recentSegmentBtn  attrs=T@"UIButton",&,N,V_recentSegmentBtn
    runningApps  attrs=T@"NSArray",&,N,V_runningApps
    hash  attrs=TQ,R
    superclass  attrs=T#,R
    description  attrs=T@"NSString",R,C
    debugDescription  attrs=T@"NSString",R,C
  instance methods (66):
    - initWithFrame:  types=@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - dealloc  types=v16@0:8
    - cb_onLanguageChanged:  types=v24@0:8@16
    - loadInstalledApps  types=v16@0:8
    - layoutSubviews  types=v16@0:8
    - setupCardContent  types=v16@0:8
    - setupAppPickerCardsInCardW:cardH:contentY:  types=v40@0:8d16d24d32
    - scrollViewDidScroll:  types=v24@0:8@16
    - pageControlChanged:  types=v24@0:8@16
    - setupPresetCardsInCardW:cardH:contentY:  types=v40@0:8d16d24d32
    - setupRecentAppsCardsInCardW:cardH:contentY:  types=v40@0:8d16d24d32
    - addMoreAppsTapped:  types=v24@0:8@16
    - dismissCustomAlert:  types=v24@0:8@16
    - restartSingleAppTapped:  types=v24@0:8@16
    - closeSingleAppTapped:  types=v24@0:8@16
    - closeAllBridgedAppsTapped:  types=v24@0:8@16
    - switchToAppPickerMode  types=v16@0:8
    - switchToLayoutChooserMode  types=v16@0:8
    - switchToRecentMode  types=v16@0:8
    - toggleMode  types=v16@0:8
    - saveSlotIndex:bid:toSettings:prefs:  types=v48@0:8q16@24@32@40
    - appSelected:  types=v24@0:8@16
    - presetSelected:  types=v24@0:8@16
    - showAppPickerForSlot:parentView:  types=v32@0:8q16@24
    - showLayoutChooserInParentView:  types=v24@0:8@16
    - showRecentAppsInParentView:  types=v24@0:8@16
    - dismissOverlay  types=v16@0:8
    - onCloseRequested  types=@?16@0:8
    - setOnCloseRequested:  types=v24@0:8@?16
    - onMultiSplitSelected  types=@?16@0:8
    - setOnMultiSplitSelected:  types=v24@0:8@?16
    - dimBackground  types=@16@0:8
    - setDimBackground:  types=v24@0:8@16
    - cardShadowContainer  types=@16@0:8
    - setCardShadowContainer:  types=v24@0:8@16
    - sheetCard  types=@16@0:8
    - setSheetCard:  types=v24@0:8@16
    - allApps  types=@16@0:8
    - setAllApps:  types=v24@0:8@16
    - appPickerScrollView  types=@16@0:8
    - setAppPickerScrollView:  types=v24@0:8@16
    - appPickerPageControl  types=@16@0:8
    - setAppPickerPageControl:  types=v24@0:8@16
    - slotBIDs  types=@16@0:8
    - setSlotBIDs:  types=v24@0:8@16
    - currentPreset  types=q16@0:8
    - setCurrentPreset:  types=v24@0:8q16
    - currentRatio  types=d16@0:8
    - setCurrentRatio:  types=v24@0:8d16
    - targetSlotIndex  types=q16@0:8
    - setTargetSlotIndex:  types=v24@0:8q16
    - overlayMode  types=q16@0:8
    - setOverlayMode:  types=v24@0:8q16
    - headerIcon  types=@16@0:8
    - setHeaderIcon:  types=v24@0:8@16
    - titleLabel  types=@16@0:8
    - setTitleLabel:  types=v24@0:8@16
    - appSegmentBtn  types=@16@0:8
    - setAppSegmentBtn:  types=v24@0:8@16
    - layoutSegmentBtn  types=@16@0:8
    - setLayoutSegmentBtn:  types=v24@0:8@16
    - recentSegmentBtn  types=@16@0:8
    - setRecentSegmentBtn:  types=v24@0:8@16
    - runningApps  types=@16@0:8
    - setRunningApps:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBBridgedUIAppView : UIView (instanceSize=48, ro_flags=0x194) ---
  ivars:
    _hosting : B offset=8 size=1
    _invalidated : B offset=9 size=1
    _audioOnlyBackgroundMode : B offset=10 size=1
    _bundleIdentifier : @"NSString" offset=16 size=8
    _appViewController : @"SBAppViewController" offset=24 size=8
    _wrapperView : @"UIView" offset=32 size=8
    _appScale : d offset=40 size=8
  properties:
    bundleIdentifier  attrs=T@"NSString",C,N,V_bundleIdentifier
    appViewController  attrs=T@"SBAppViewController",&,N,V_appViewController
    wrapperView  attrs=T@"UIView",&,N,V_wrapperView
    appScale  attrs=Td,N,V_appScale
    hosting  attrs=TB,N,V_hosting
    invalidated  attrs=TB,N,V_invalidated
    audioOnlyBackgroundMode  attrs=TB,N,V_audioOnlyBackgroundMode
  instance methods (29):
    - initWithBundleIdentifier:  types=@24@0:8@16
    - initWithBundleIdentifier:scale:  types=@32@0:8@16d24
    - setAppScale:  types=v24@0:8d16
    - setAudioOnlyBackgroundMode:  types=v20@0:8B16
    - layoutSubviews  types=v16@0:8
    - hitTest:withEvent:  types=@40@0:8{CGPoint=dd}16@32
    - touchesBegan:withEvent:  types=v32@0:8@16@24
    - calculateNativeSizeForSlotRect:  types={CGSize=dd}48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - updateLayout  types=v16@0:8
    - updateSceneSettingsFrame  types=v16@0:8
    - updateSceneFrame  types=v16@0:8
    - refreshSceneLayout  types=v16@0:8
    - startInParentViewController:  types=v24@0:8@16
    - start  types=v16@0:8
    - dismiss  types=v16@0:8
    - dealloc  types=v16@0:8
    - bundleIdentifier  types=@16@0:8
    - setBundleIdentifier:  types=v24@0:8@16
    - appViewController  types=@16@0:8
    - setAppViewController:  types=v24@0:8@16
    - wrapperView  types=@16@0:8
    - setWrapperView:  types=v24@0:8@16
    - appScale  types=d16@0:8
    - hosting  types=B16@0:8
    - setHosting:  types=v20@0:8B16
    - invalidated  types=B16@0:8
    - setInvalidated:  types=v20@0:8B16
    - audioOnlyBackgroundMode  types=B16@0:8
    - .cxx_destruct  types=v16@0:8

--- @interface CBWindow : NSObject (instanceSize=104, ro_flags=0x194) ---
  ivars:
    _boundDisplay : @"CADisplay" offset=8 size=8
    _boundDisplayConfig : @"FBSDisplayConfiguration" offset=16 size=8
    _isVisible : B offset=24 size=1
    _rootWindow : @"UIWindow" offset=32 size=8
    _rootViewController : @"UIViewController" offset=40 size=8
    _contentView : @"UIVisualEffectView" offset=48 size=8
    _multitaskingPill : @"CBMultitaskingPillView" offset=56 size=8
    _multitaskingOverlay : @"CBMultitaskingOverlayView" offset=64 size=8
    _appFrame : {CGRect="origin"{CGPoint="x"d"y"d}"size"{CGSize="width"d"height"d}} offset=72 size=32
  properties:
    appFrame  attrs=T{CGRect={CGPoint=dd}{CGSize=dd}},N,V_appFrame
    rootWindow  attrs=T@"UIWindow",&,N,V_rootWindow
    rootViewController  attrs=T@"UIViewController",&,N,V_rootViewController
    contentView  attrs=T@"UIVisualEffectView",&,N,V_contentView
    multitaskingPill  attrs=T@"CBMultitaskingPillView",&,N,V_multitaskingPill
    multitaskingOverlay  attrs=T@"CBMultitaskingOverlayView",&,N,V_multitaskingOverlay
    isVisible  attrs=TB,N,V_isVisible
  instance methods (28):
    - initWithAppFrame:  types=@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - getCarPlayDisplay  types=@16@0:8
    - createWindows  types=v16@0:8
    - multitaskingOverlay  types=@16@0:8
    - resizeWindows  types=v16@0:8
    - show  types=v16@0:8
    - hide:  types=v24@0:8@?16
    - isDisplayValid  types=B16@0:8
    - destroyWindows  types=v16@0:8
    - dismiss  types=v16@0:8
    - dealloc  types=v16@0:8
    - showAppPickerForSlot:  types=v24@0:8q16
    - showLayoutChooser  types=v16@0:8
    - showRecentApps  types=v16@0:8
    - appFrame  types={CGRect={CGPoint=dd}{CGSize=dd}}16@0:8
    - setAppFrame:  types=v48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - rootWindow  types=@16@0:8
    - setRootWindow:  types=v24@0:8@16
    - rootViewController  types=@16@0:8
    - setRootViewController:  types=v24@0:8@16
    - contentView  types=@16@0:8
    - setContentView:  types=v24@0:8@16
    - multitaskingPill  types=@16@0:8
    - setMultitaskingPill:  types=v24@0:8@16
    - setMultitaskingOverlay:  types=v24@0:8@16
    - isVisible  types=B16@0:8
    - setIsVisible:  types=v20@0:8B16
    - .cxx_destruct  types=v16@0:8
  class methods (9):
    + activeCarPlayWindow  types=@16@0:8
    + resetCachedBounds  types=v16@0:8
    + carPlayWindowScene  types=@16@0:8
    + carPlayUIScreen  types=@16@0:8
    + carPlayCADisplay  types=@16@0:8
    + carPlayScreenScale  types=d16@0:8
    + carPlayScreenBounds  types={CGRect={CGPoint=dd}{CGSize=dd}}16@0:8
    + carPlayContentInsets  types={UIEdgeInsets=dddd}16@0:8
    + carPlayUsableBounds  types={CGRect={CGPoint=dd}{CGSize=dd}}16@0:8

--- @interface CBDockMetricItemView : UIView (instanceSize=32, ro_flags=0x194) ---
  ivars:
