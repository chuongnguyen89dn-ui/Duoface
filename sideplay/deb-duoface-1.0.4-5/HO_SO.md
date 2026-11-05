# HỒ SƠ TĨNH TOÀN DIỆN — DuoFace 1.0.4-5 (bản test voice104)

> Phương pháp: phân tích tĩnh CHỈ ĐỌC trên bản sao bóc gói của file .deb (dpkg-deb -x/-e), parser Mach-O/ObjC metadata viết tay bằng Python, `strings`, `sha256sum`. Không chạy bất kỳ binary/script nào trích từ gói. Mức bằng chứng được ghi ngay tại từng mục; chỗ không đọc được nằm ở mục cuối «CHƯA XÁC ĐỊNH ĐƯỢC».

## 1. Định danh gói

- Tên file: `com.duoface.voice104.test_1.0.4-5_iphoneos-arm64.deb`
- Kích thước: 2.603.282 bytes
- SHA256: `d78ad0f3c4d115fe9153255ff9b930446aa90ae707534578893a54e0f45229f6` (đã kiểm khớp với mã do chủ dự án cung cấp)
- Định dạng: Debian package version 2.0; control archive 2.124 bytes; Installed-Size khai báo: 11060 (KB)

### 1.1. control (toàn văn)
```
Package: com.duoface.voice104.test
Name: DuoFace
Description: Split your screen and run apps side-by-side on Apple CarPlay.
Maintainer: DuoNavi Team <support@duonavi.com>
Author: DuoNavi Team
Section: Tweaks
Depends: mobilesubstrate (>= 0.9.5000), firmware (>= 13.0)
Conflicts: oldabi, com.yourcompany.carbridgedashboard, com.bvn.carbridge13, com.leftyfl1p.carbridge13
Replaces: oldabi, com.yourcompany.carbridgedashboard, com.bvn.carbridge13, com.leftyfl1p.carbridge13
Provides: oldabi, com.yourcompany.carbridgedashboard, com.leftyfl1p.carbridge13
SileoDepiction: https://repo.duonavi.com/com.duonavi.app.json
Icon: https://chuongnguyen89dn-ui.github.io/carplaydsp/duoface-icon.png
Architecture: iphoneos-arm64
Version: 1.0.4-5~duofacetest
Installed-Size: 11060
```

### 1.2. Maintainer scripts

Gói có đúng 2 script: `postinst` (4.856 bytes, 120 dòng) và `prerm` (634 bytes, 13 dòng). Không có preinst/postrm/extrainst_.

**postinst — hành vi (đọc từ mã shell, KHÔNG chạy):**
1. `chmod 0666` cho filter plist `CarBridgeDashboard.plist` (cả đường /var/jb lẫn /Library) và 2 file state `/var/tmp/com.duonavi.bridgestate.plist`, `/var/tmp/com.tiz.carbridge.bridgestate.plist`.
2. Nếu có `/var/jb/usr/lib/ellekit/OldABI.dylib`: chmod 0755 + chown 0:0 (root:wheel).
3. Đặt chủ root + setuid (`chmod 4755`) cho `/var/jb/usr/libexec/cboptimize_helper` (và bản /usr/libexec).
4. Chạy `cboptimize_helper --grant-tcc` — mục đích ghi trong comment: cấp sẵn quyền Speech Recognition + Microphone trong TCC.db cho SpringBoard.
5. chown 0:0 + chmod 0440 cho sudoers drop-in `/var/jb/etc/sudoers.d/duonavi` và `.../carbridge`.
6. Khởi tạo preferences: nếu chưa có `/var/mobile/Library/Preferences/com.duonavi.plist` mà có bản legacy `com.tiz.carbridge.plist` thì copy sang; nếu vẫn chưa có thì TẠO MỚI với các mặc định: `bridgedApps` = [com.google.Maps, com.apple.Maps, com.google.ios.youtube, com.apple.Music, com.apple.podcasts, com.apple.tv, com.ss.iphone.ugc.Ame, com.ss.iphone.ugc.tiktok.lite, vn.com.vng.zingalo], `userAppsDefaultInitialized=true`, `splitScreenEnabled=true`, `autoLaunchOnConnect=true`, `autoLaunchBundleID=com.apple.BarcodeScanner`, `systemOptimizerEnabled=true`; chown 501:501, chmod 0644.
7. System Optimizer: đọc key `systemOptimizerEnabled` trong prefs (nếu = false thì bỏ qua). Nếu bật: dùng launchctl `disable` + `kill SIGKILL` 12 dịch vụ hệ thống: com.apple.ReportCrash, com.apple.ReportCrash.SimulateCrash, com.apple.AggregateDictionary.addaily, com.apple.symptomsd-diag, com.apple.healthd, com.apple.healthrecordsd, com.apple.OTATaskingAgent, com.apple.softwareupdated, com.apple.triald, com.apple.biomesyncd, com.apple.routined, com.apple.duetexpertd. Đồng thời xoá sạch `/var/mobile/Library/Logs/CrashReporter/*` và `/Library/Logs/CrashReporter/*`, truncate 4 file log: /var/mobile/duonavi.log, duonavi_live.log, carbridge.log, carbridge_live.log. Nếu user tắt optimizer: `enable` lại cả 12 dịch vụ.
8. Cuối: chạy `uicache -a` làm mới cache icon/LaunchServices.

**prerm — hành vi:** khi gỡ gói, `launchctl enable` lại đúng 12 dịch vụ hệ thống ở trên (khôi phục daemon về mặc định).

Toàn văn postinst:
```sh
#!/bin/sh
set -e

# Fix tweak preference and state permissions
chmod 0666 /var/jb/Library/MobileSubstrate/DynamicLibraries/CarBridgeDashboard.plist 2>/dev/null || true
chmod 0666 /Library/MobileSubstrate/DynamicLibraries/CarBridgeDashboard.plist 2>/dev/null || true
chmod 0666 /var/tmp/com.duonavi.bridgestate.plist 2>/dev/null || true
chmod 0666 /var/tmp/com.tiz.carbridge.bridgestate.plist 2>/dev/null || true

# Auto-configure OldABI permissions on A12+ PAC devices
if [ -f /var/jb/usr/lib/ellekit/OldABI.dylib ]; then
    chmod 0755 /var/jb/usr/lib/ellekit/OldABI.dylib 2>/dev/null || true
    chown 0:0 /var/jb/usr/lib/ellekit/OldABI.dylib 2>/dev/null || true
fi

# Set setuid root permissions for root helper tool
chown 0:0 /var/jb/usr/libexec/cboptimize_helper 2>/dev/null || true
chmod 4755 /var/jb/usr/libexec/cboptimize_helper 2>/dev/null || true
chown 0:0 /usr/libexec/cboptimize_helper 2>/dev/null || true
chmod 4755 /usr/libexec/cboptimize_helper 2>/dev/null || true

# Pre-grant Speech Recognition and Microphone permissions in TCC.db for SpringBoard
/var/jb/usr/libexec/cboptimize_helper --grant-tcc 2>/dev/null || /usr/libexec/cboptimize_helper --grant-tcc 2>/dev/null || true

# Set sudoers drop-in permissions if present
chown 0:0 /var/jb/etc/sudoers.d/duonavi /var/jb/etc/sudoers.d/carbridge 2>/dev/null || true
chmod 0440 /var/jb/etc/sudoers.d/duonavi /var/jb/etc/sudoers.d/carbridge 2>/dev/null || true

# Auto-initialize initial settings for fresh jailbroken devices
PREF_FILE="/var/mobile/Library/Preferences/com.duonavi.plist"
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

# System Optimization for CarPlay (Rootless & Rootful compatible)
LAUNCHCTL_BIN="/var/jb/usr/bin/launchctl"
[ -x "$LAUNCHCTL_BIN" ] || LAUNCHCTL_BIN="/usr/bin/launchctl"

# Check if user explicitly disabled system optimizer in preferences (e.g. iPhone 15 Pro Max)
PREF_FILE="/var/mobile/Library/Preferences/com.duonavi.plist"
[ -f "$PREF_FILE" ] || PREF_FILE="/var/mobile/Library/Preferences/com.tiz.carbridge.plist"
OPT_ENABLED=1
if [ -f "$PREF_FILE" ]; then
    if grep -A 1 "<key>systemOptimizerEnabled</key>" "$PREF_FILE" 2>/dev/null | grep -q "<false/>"; then
        OPT_ENABLED=0
    fi
fi

SERVICES="com.apple.ReportCrash com.apple.ReportCrash.SimulateCrash com.apple.AggregateDictionary.addaily com.apple.symptomsd-diag com.apple.healthd com.apple.healthrecordsd com.apple.OTATaskingAgent com.apple.softwareupdated com.apple.triald com.apple.biomesyncd com.apple.routined com.apple.duetexpertd"

if [ "$OPT_ENABLED" -eq 1 ]; then
    if [ -x "$LAUNCHCTL_BIN" ]; then
        for svc in $SERVICES; do
            "$LAUNCHCTL_BIN" disable "system/$svc" 2>/dev/null || true
            "$LAUNCHCTL_BIN" kill SIGKILL "system/$svc" 2>/dev/null || true
        done
    fi

    # Clean stale crash logs and huge debug logs
    rm -rf /var/mobile/Library/Logs/CrashReporter/* 2>/dev/null || true
    rm -rf /Library/Logs/CrashReporter/* 2>/dev/null || true
    for logfile in /var/mobile/duonavi.log /var/mobile/duonavi_live.log /var/mobile/carbridge.log /var/mobile/carbridge_live.log; do
        if [ -f "$logfile" ]; then
            > "$logfile" || true
        fi
    done
else
    # User chose to keep/restore stock daemons
    if [ -x "$LAUNCHCTL_BIN" ]; then
        for svc in $SERVICES; do
            "$LAUNCHCTL_BIN" enable "system/$svc" 2>/dev/null || true
        done
    fi
fi

# Refresh SpringBoard & LaunchServices Icon / App cache
if command -v uicache >/dev/null 2>&1; then
    uicache -a 2>/dev/null || true
elif [ -x /var/jb/usr/bin/uicache ]; then
    /var/jb/usr/bin/uicache -a 2>/dev/null || true
elif [ -x /usr/bin/uicache ]; then
    /usr/bin/uicache -a 2>/dev/null || true
fi

exit 0
```
Toàn văn prerm:
```sh
#!/bin/sh
# Re-enable system daemons when CarBridge package is removed
LAUNCHCTL_BIN="/var/jb/usr/bin/launchctl"
[ -x "$LAUNCHCTL_BIN" ] || LAUNCHCTL_BIN="/usr/bin/launchctl"

if [ -x "$LAUNCHCTL_BIN" ]; then
    SERVICES="com.apple.ReportCrash com.apple.ReportCrash.SimulateCrash com.apple.AggregateDictionary.addaily com.apple.symptomsd-diag com.apple.healthd com.apple.healthrecordsd com.apple.OTATaskingAgent com.apple.softwareupdated com.apple.triald com.apple.biomesyncd com.apple.routined com.apple.duetexpertd"
    for svc in $SERVICES; do
        "$LAUNCHCTL_BIN" enable "system/$svc" 2>/dev/null || true
    done
fi

exit 0
```

## 2. Cây file 100% trong data.tar

Đường dẫn gốc cài đặt là rootless `/var/jb/...`. Cột: kích thước (bytes) — đường dẫn — (đích symlink nếu có).
```
     1625  /var/jb/Applications/DuoNaviUI.app/AppIcon29x29.png
     4927  /var/jb/Applications/DuoNaviUI.app/AppIcon29x29@2x.png
     9504  /var/jb/Applications/DuoNaviUI.app/AppIcon29x29@3x.png
     2650  /var/jb/Applications/DuoNaviUI.app/AppIcon40x40.png
     8309  /var/jb/Applications/DuoNaviUI.app/AppIcon40x40@2x.png
    16021  /var/jb/Applications/DuoNaviUI.app/AppIcon40x40@3x.png
     3845  /var/jb/Applications/DuoNaviUI.app/AppIcon50x50.png
    11898  /var/jb/Applications/DuoNaviUI.app/AppIcon50x50@2x.png
     4818  /var/jb/Applications/DuoNaviUI.app/AppIcon57x57.png
    14778  /var/jb/Applications/DuoNaviUI.app/AppIcon57x57@2x.png
    28859  /var/jb/Applications/DuoNaviUI.app/AppIcon57x57@3x.png
     5185  /var/jb/Applications/DuoNaviUI.app/AppIcon60x60.png
    16021  /var/jb/Applications/DuoNaviUI.app/AppIcon60x60@2x.png
    31467  /var/jb/Applications/DuoNaviUI.app/AppIcon60x60@3x.png
     7026  /var/jb/Applications/DuoNaviUI.app/AppIcon72x72.png
    21616  /var/jb/Applications/DuoNaviUI.app/AppIcon72x72@2x.png
     7628  /var/jb/Applications/DuoNaviUI.app/AppIcon76x76.png
    23597  /var/jb/Applications/DuoNaviUI.app/AppIcon76x76@2x.png
  2435008  /var/jb/Applications/DuoNaviUI.app/DuoNaviUI
     2304  /var/jb/Applications/DuoNaviUI.app/Info.plist
     1998  /var/jb/Library/Application Support/DuoFace/asset-manifest.json
    64297  /var/jb/Library/Application Support/DuoFace/duoface-icon.png
   378795  /var/jb/Library/Application Support/DuoFace/duoface-logo-vert.png
   147482  /var/jb/Library/Application Support/DuoFace/duoface-logo.png
     6400  /var/jb/Library/Application Support/DuoFace/VisualAssets/duoface-fullscreen.png
    15225  /var/jb/Library/Application Support/DuoFace/VisualAssets/duoface-picker.png
    22085  /var/jb/Library/Application Support/DuoFace/VisualAssets/duoface-swap.png
    25090  /var/jb/Library/Application Support/DuoNavi/Audio/ting.caf
    15129  /var/jb/Library/Application Support/DuoNavi/Audio/ar/error.mp3
    12861  /var/jb/Library/Application Support/DuoNavi/Audio/de/error.mp3
     9945  /var/jb/Library/Application Support/DuoNavi/Audio/en/error.mp3
    11241  /var/jb/Library/Application Support/DuoNavi/Audio/es/error.mp3
    11889  /var/jb/Library/Application Support/DuoNavi/Audio/fr/error.mp3
    12753  /var/jb/Library/Application Support/DuoNavi/Audio/hi/error.mp3
    12753  /var/jb/Library/Application Support/DuoNavi/Audio/id/error.mp3
    10161  /var/jb/Library/Application Support/DuoNavi/Audio/it/error.mp3
    17073  /var/jb/Library/Application Support/DuoNavi/Audio/ja/error.mp3
    14157  /var/jb/Library/Application Support/DuoNavi/Audio/ko/error.mp3
    11565  /var/jb/Library/Application Support/DuoNavi/Audio/ms/error.mp3
    10593  /var/jb/Library/Application Support/DuoNavi/Audio/nl/error.mp3
    11673  /var/jb/Library/Application Support/DuoNavi/Audio/pl/error.mp3
    15777  /var/jb/Library/Application Support/DuoNavi/Audio/pt/error.mp3
    12969  /var/jb/Library/Application Support/DuoNavi/Audio/ru/error.mp3
    14049  /var/jb/Library/Application Support/DuoNavi/Audio/th/error.mp3
    14913  /var/jb/Library/Application Support/DuoNavi/Audio/tr/error.mp3
    10161  /var/jb/Library/Application Support/DuoNavi/Audio/vi/error.mp3
    11781  /var/jb/Library/Application Support/DuoNavi/Audio/zh/error.mp3
    11997  /var/jb/Library/Application Support/DuoNavi/Audio/zh-Hant/error.mp3
    77744  /var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.dylib
      553  /var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.plist
  7921472  /var/jb/Library/MobileSubstrate/DynamicLibraries/DuoNaviDashboard.dylib
     1446  /var/jb/Library/MobileSubstrate/DynamicLibraries/DuoNaviDashboard.plist
       28  /var/jb/etc/sudoers.d/duonavi
     3364  /var/jb/usr/bin/cboptimize
    67552  /var/jb/usr/lib/ellekit/OldABI.dylib
   150720  /var/jb/usr/libexec/cboptimize_helper
```

Ghi chú cây file: gói KHÔNG chứa symlink nào. Ngoài 5 file nhị phân Mach-O còn có script shell `usr/bin/cboptimize` (mục riêng ở dưới), 20 file âm thanh error.mp3 theo 20 ngôn ngữ + 1 file ting.caf trong `Library/Application Support/DuoNavi/Audio/`, và các ảnh trong `Library/Application Support/DuoFace/` kèm `asset-manifest.json` (liệt kê nguồn zip `DuoFace_5_images_REVIEW_before_upload.zip` + SHA256 từng ảnh nguồn/đầu ra — nội dung manifest đã đọc đủ, các hash trong manifest khớp định dạng SHA256).

## 3. DuoNaviDashboard.dylib — dylib chính (inject đa tiến trình)

- Đường dẫn trong gói: `/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoNaviDashboard.dylib`
- Kích thước file: 7921472 bytes
- SHA256 file: `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`
- Số slice (kiến trúc): 2 — arm64, arm64e
- Slice 1 (arm64): filetype=MH_DYLIB (dylib), UUID=`12616bb91d3e314e90d5e231ee45c0e0`, LC_BUILD_VERSION platform=2 (2=iOS), min iOS=15.0.0, SDK=16.5.0, chained_fixups=False, encryption(cryptoff,cryptsize,cryptid)=(16384, 3588096, 0) → cryptid=0 = KHÔNG mã hoá FairPlay
- Slice 2 (arm64e): filetype=MH_DYLIB (dylib), UUID=`66809fc503713f0da04876b2244be0a2`, LC_BUILD_VERSION platform=2 (2=iOS), min iOS=15.0.0, SDK=16.5.0, chained_fixups=True, encryption(cryptoff,cryptsize,cryptid)=(16384, 3620864, 0) → cryptid=0 = KHÔNG mã hoá FairPlay
- Install name (LC_ID_DYLIB): `@rpath/DuoNaviDashboard.dylib`
- Chữ ký mã: superblob CHỈ gồm CodeDirectory + Requirements (designated requirement dạng ldid: tên `.unsigned`, `subject.CN`) — **KHÔNG có blob entitlements (slot 5/7)** → không binary nào trong gói mang entitlements nhúng.
- Hàm khởi tạo: __mod_init_func có 2 mục (arm64) / __init_offsets có 2 mục (arm64e) — 2 constructor chạy khi nạp
- Số hàm theo LC_FUNCTION_STARTS: 1788 (gồm cả hàm C nội bộ không tên — symtab đã bị strip, xem mục chưa xác định)

### Thư viện liên kết (LC_LOAD_DYLIB)
- [load] `/usr/lib/libobjc.A.dylib`
- [load] `/System/Library/Frameworks/Foundation.framework/Foundation`
- [load] `/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation`
- [load] `/System/Library/Frameworks/UIKit.framework/UIKit`
- [load] `/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics`
- [load] `/System/Library/Frameworks/IOKit.framework/Versions/A/IOKit`
- [load] `/System/Library/Frameworks/Security.framework/Security`
- [load] `/System/Library/Frameworks/AVFoundation.framework/AVFoundation`
- [load] `/System/Library/Frameworks/QuartzCore.framework/QuartzCore`
- [load] `/System/Library/Frameworks/AudioToolbox.framework/AudioToolbox`
- [load] `/System/Library/Frameworks/Speech.framework/Speech`
- [load] `/System/Library/Frameworks/CoreMedia.framework/CoreMedia`
- [load] `/System/Library/PrivateFrameworks/AppSupport.framework/AppSupport`
- [load] `/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices`
- [load] `/usr/lib/libsqlite3.dylib`
- [load] `/usr/lib/libSystem.B.dylib`
- [load] `/System/Library/Frameworks/AVFAudio.framework/AVFAudio`
- [load] `@rpath/CydiaSubstrate.framework/CydiaSubstrate`

### Sections (slice arm64)
- `__TEXT,__text` addr=0x5f30 size=3199520
- `__TEXT,__stubs` addr=0x313150 size=2064
- `__TEXT,__stub_helper` addr=0x313960 size=2088
- `__TEXT,__objc_methlist` addr=0x314188 size=11140
- `__TEXT,__gcc_except_tab` addr=0x316d0c size=20680
- `__TEXT,__objc_methname` addr=0x31bdd4 size=39413
- `__TEXT,__cstring` addr=0x3257c9 size=93874
- `__TEXT,__const` addr=0x33c680 size=38073
- `__TEXT,__ustring` addr=0x345b3a size=161552
- `__TEXT,__objc_classname` addr=0x36d24a size=1388
- `__TEXT,__objc_methtype` addr=0x36d7b6 size=4797
- `__TEXT,__unwind_info` addr=0x36ea74 size=5516
- `__DATA_CONST,__got` addr=0x370000 size=536
- `__DATA_CONST,__mod_init_func` addr=0x370218 size=16
- `__DATA_CONST,__const` addr=0x370228 size=9848
- `__DATA_CONST,__cfstring` addr=0x3728a0 size=183008
- `__DATA_CONST,__objc_classlist` addr=0x39f380 size=376
- `__DATA_CONST,__objc_catlist` addr=0x39f4f8 size=0
- `__DATA_CONST,__objc_protolist` addr=0x39f4f8 size=104
- `__DATA_CONST,__objc_imageinfo` addr=0x39f560 size=8
- `__DATA,__la_symbol_ptr` addr=0x3a0000 size=1376
- `__DATA,__objc_const` addr=0x3a0560 size=30288
- `__DATA,__objc_selrefs` addr=0x3a7bb0 size=11744
- `__DATA,__objc_classrefs` addr=0x3aa990 size=1000
- `__DATA,__objc_superrefs` addr=0x3aad78 size=288
- `__DATA,__objc_ivar` addr=0x3aae98 size=1108
- `__DATA,__objc_data` addr=0x3ab2f0 size=3760
- `__DATA,__thread_vars` addr=0x3ac1a0 size=576
- `__DATA,__data` addr=0x3ac3e0 size=1264
- `__DATA,__thread_bss` addr=0x3ac8d0 size=480
- `__DATA,__bss` addr=0x3acab0 size=6872
- `__DATA,__common` addr=0x3ae590 size=672

### Symbols
- Defined trong symtab: 0; Undefined (import): 325; Exports trie: (không có/rỗng)
- Defined symbols: symtab đã bị strip gần hết — không còn tên hàm/class dạng symbol (metadata Objective-C ở dưới vẫn đọc được đầy đủ từ section __objc_*).
- Class Objective-C bên ngoài được tham chiếu (85):
  - `_OBJC_CLASS_$_AVAudioConverter`
  - `_OBJC_CLASS_$_AVAudioEngine`
  - `_OBJC_CLASS_$_AVAudioFormat`
  - `_OBJC_CLASS_$_AVAudioPCMBuffer`
  - `_OBJC_CLASS_$_AVAudioPlayer`
  - `_OBJC_CLASS_$_AVAudioSession`
  - `_OBJC_CLASS_$_CABasicAnimation`
  - `_OBJC_CLASS_$_CADisplay`
  - `_OBJC_CLASS_$_CADisplayLink`
  - `_OBJC_CLASS_$_CAGradientLayer`
  - `_OBJC_CLASS_$_CAKeyframeAnimation`
  - `_OBJC_CLASS_$_CAMediaTimingFunction`
  - `_OBJC_CLASS_$_CAShapeLayer`
  - `_OBJC_CLASS_$_CATransaction`
  - `_OBJC_CLASS_$_NSArray`
  - `_OBJC_CLASS_$_NSAttributedString`
  - `_OBJC_CLASS_$_NSBundle`
  - `_OBJC_CLASS_$_NSCache`
  - `_OBJC_CLASS_$_NSCharacterSet`
  - `_OBJC_CLASS_$_NSData`
  - `_OBJC_CLASS_$_NSDate`
  - `_OBJC_CLASS_$_NSDictionary`
  - `_OBJC_CLASS_$_NSDistributedNotificationCenter`
  - `_OBJC_CLASS_$_NSError`
  - `_OBJC_CLASS_$_NSFileHandle`
  - `_OBJC_CLASS_$_NSFileManager`
  - `_OBJC_CLASS_$_NSHTTPURLResponse`
  - `_OBJC_CLASS_$_NSHashTable`
  - `_OBJC_CLASS_$_NSJSONSerialization`
  - `_OBJC_CLASS_$_NSLocale`
  - `_OBJC_CLASS_$_NSMutableArray`
  - `_OBJC_CLASS_$_NSMutableAttributedString`
  - `_OBJC_CLASS_$_NSMutableData`
  - `_OBJC_CLASS_$_NSMutableDictionary`
  - `_OBJC_CLASS_$_NSMutableParagraphStyle`
  - `_OBJC_CLASS_$_NSMutableSet`
  - `_OBJC_CLASS_$_NSMutableString`
  - `_OBJC_CLASS_$_NSMutableURLRequest`
  - `_OBJC_CLASS_$_NSNotification`
  - `_OBJC_CLASS_$_NSNotificationCenter`
  - `_OBJC_CLASS_$_NSNumber`
  - `_OBJC_CLASS_$_NSObject`
  - `_OBJC_CLASS_$_NSOperationQueue`
  - `_OBJC_CLASS_$_NSProcessInfo`
  - `_OBJC_CLASS_$_NSRecursiveLock`
  - `_OBJC_CLASS_$_NSRunLoop`
  - `_OBJC_CLASS_$_NSSet`
  - `_OBJC_CLASS_$_NSString`
  - `_OBJC_CLASS_$_NSThread`
  - `_OBJC_CLASS_$_NSTimer`
  - `_OBJC_CLASS_$_NSURL`
  - `_OBJC_CLASS_$_NSURLSession`
  - `_OBJC_CLASS_$_NSURLSessionConfiguration`
  - `_OBJC_CLASS_$_NSURLSessionWebSocketMessage`
  - `_OBJC_CLASS_$_NSUUID`
  - `_OBJC_CLASS_$_NSValue`
  - `_OBJC_CLASS_$_SFSpeechAudioBufferRecognitionRequest`
  - `_OBJC_CLASS_$_SFSpeechRecognizer`
  - `_OBJC_CLASS_$_UIApplication`
  - `_OBJC_CLASS_$_UIBezierPath`
  - `_OBJC_CLASS_$_UIBlurEffect`
  - `_OBJC_CLASS_$_UIButton`
  - `_OBJC_CLASS_$_UIColor`
  - `_OBJC_CLASS_$_UIDevice`
  - `_OBJC_CLASS_$_UIFont`
  - `_OBJC_CLASS_$_UIImage`
  - `_OBJC_CLASS_$_UIImageSymbolConfiguration`
  - `_OBJC_CLASS_$_UIImageView`
  - `_OBJC_CLASS_$_UILabel`
  - `_OBJC_CLASS_$_UILongPressGestureRecognizer`
  - `_OBJC_CLASS_$_UIPageControl`
  - `_OBJC_CLASS_$_UIPanGestureRecognizer`
  - `_OBJC_CLASS_$_UIScreen`
  - `_OBJC_CLASS_$_UIScrollView`
  - `_OBJC_CLASS_$_UITapGestureRecognizer`
  - `_OBJC_CLASS_$_UITextInputMode`
  - `_OBJC_CLASS_$_UIView`
  - `_OBJC_CLASS_$_UIViewController`
  - `_OBJC_CLASS_$_UIVisualEffectView`
  - `_OBJC_CLASS_$_UIWindow`
  - `_OBJC_CLASS_$_UIWindowScene`
  - `_OBJC_METACLASS_$_NSObject`
  - `_OBJC_METACLASS_$_UIButton`
  - `_OBJC_METACLASS_$_UIScrollView`
  - `_OBJC_METACLASS_$_UIView`
- Toàn bộ undefined/imported symbols:
  - `_AVAudioSessionCategoryPlayAndRecord`
  - `_AVAudioSessionCategoryPlayback`
  - `_AVAudioSessionInterruptionNotification`
  - `_AVAudioSessionInterruptionTypeKey`
  - `_AVAudioSessionModeDefault`
  - `_AVAudioSessionRouteChangeNotification`
  - `_AVAudioSessionRouteChangeReasonKey`
  - `_CACurrentMediaTime`
  - `_CAFrameRateRangeMake`
  - `_CCHmac`
  - `_CC_SHA256`
  - `_CFDataGetBytePtr`
  - `_CFDataGetLength`
  - `_CFDataGetTypeID`
  - `_CFGetTypeID`
  - `_CFNotificationCenterAddObserver`
  - `_CFNotificationCenterGetDarwinNotifyCenter`
  - `_CFNotificationCenterPostNotification`
  - `_CFNumberGetTypeID`
  - `_CFNumberGetValue`
  - `_CFRelease`
  - `_CFStringCreateWithCString`
  - `_CFStringGetCString`
  - `_CFStringGetTypeID`
  - `_CGAffineTransformIdentity`
  - `_CGAffineTransformMakeScale`
  - `_CGAffineTransformMakeTranslation`
  - `_CGColorSpaceCreateDeviceRGB`
  - `_CGColorSpaceRelease`
  - `_CGContextDrawLinearGradient`
  - `_CGContextDrawRadialGradient`
  - `_CGContextRestoreGState`
  - `_CGContextSaveGState`
  - `_CGGradientCreateWithColors`
  - `_CGGradientRelease`
  - `_CGPathRetain`
  - `_CGPointZero`
  - `_CGRectContainsPoint`
  - `_CGRectEqualToRect`
  - `_CGRectGetMaxX`
  - `_CGRectGetMaxY`
  - `_CGRectGetMidX`
  - `_CGRectGetMidY`
  - `_CGRectGetMinX`
  - `_CGRectGetMinY`
  - `_CGRectInset`
  - `_CGRectIntersectsRect`
  - `_CGRectIsEmpty`
  - `_CGRectZero`
  - `_CGSizeFromString`
  - `_CGSizeZero`
  - `_IOHIDEventAppendEvent`
  - `_IOHIDEventCreateDigitizerEvent`
  - `_IOHIDEventCreateDigitizerFingerEvent`
  - `_IOHIDEventSetSenderID`
  - `_IOHIDEventSystemClientCreate`
  - `_IOHIDEventSystemClientDispatchEvent`
  - `_IOObjectRelease`
  - `_IORegistryEntryCreateCFProperty`
  - `_IOServiceGetMatchingService`
  - `_IOServiceMatching`
  - `_MSHookFunction`
  - `_MSHookMessageEx`
  - `_NSFilePosixPermissions`
  - `_NSFontAttributeName`
  - `_NSForegroundColorAttributeName`
  - `_NSKernAttributeName`
  - `_NSLocalizedDescriptionKey`
  - `_NSLog`
  - `_NSParagraphStyleAttributeName`
  - `_NSRunLoopCommonModes`
  - `_NSSelectorFromString`
  - `_NSSetUncaughtExceptionHandler`
  - `_NSStringFromCGRect`
  - `_NSStringFromCGSize`
  - `_NSStringFromClass`
  - `_NSStringFromUIEdgeInsets`
  - `_OBJC_CLASS_$_AVAudioConverter`
  - `_OBJC_CLASS_$_AVAudioEngine`
  - `_OBJC_CLASS_$_AVAudioFormat`
  - `_OBJC_CLASS_$_AVAudioPCMBuffer`
  - `_OBJC_CLASS_$_AVAudioPlayer`
  - `_OBJC_CLASS_$_AVAudioSession`
  - `_OBJC_CLASS_$_CABasicAnimation`
  - `_OBJC_CLASS_$_CADisplay`
  - `_OBJC_CLASS_$_CADisplayLink`
  - `_OBJC_CLASS_$_CAGradientLayer`
  - `_OBJC_CLASS_$_CAKeyframeAnimation`
  - `_OBJC_CLASS_$_CAMediaTimingFunction`
  - `_OBJC_CLASS_$_CAShapeLayer`
  - `_OBJC_CLASS_$_CATransaction`
  - `_OBJC_CLASS_$_NSArray`
  - `_OBJC_CLASS_$_NSAttributedString`
  - `_OBJC_CLASS_$_NSBundle`
  - `_OBJC_CLASS_$_NSCache`
  - `_OBJC_CLASS_$_NSCharacterSet`
  - `_OBJC_CLASS_$_NSData`
  - `_OBJC_CLASS_$_NSDate`
  - `_OBJC_CLASS_$_NSDictionary`
  - `_OBJC_CLASS_$_NSDistributedNotificationCenter`
  - `_OBJC_CLASS_$_NSError`
  - `_OBJC_CLASS_$_NSFileHandle`
  - `_OBJC_CLASS_$_NSFileManager`
  - `_OBJC_CLASS_$_NSHTTPURLResponse`
  - `_OBJC_CLASS_$_NSHashTable`
  - `_OBJC_CLASS_$_NSJSONSerialization`
  - `_OBJC_CLASS_$_NSLocale`
  - `_OBJC_CLASS_$_NSMutableArray`
  - `_OBJC_CLASS_$_NSMutableAttributedString`
  - `_OBJC_CLASS_$_NSMutableData`
  - `_OBJC_CLASS_$_NSMutableDictionary`
  - `_OBJC_CLASS_$_NSMutableParagraphStyle`
  - `_OBJC_CLASS_$_NSMutableSet`
  - `_OBJC_CLASS_$_NSMutableString`
  - `_OBJC_CLASS_$_NSMutableURLRequest`
  - `_OBJC_CLASS_$_NSNotification`
  - `_OBJC_CLASS_$_NSNotificationCenter`
  - `_OBJC_CLASS_$_NSNumber`
  - `_OBJC_CLASS_$_NSObject`
  - `_OBJC_CLASS_$_NSOperationQueue`
  - `_OBJC_CLASS_$_NSProcessInfo`
  - `_OBJC_CLASS_$_NSRecursiveLock`
  - `_OBJC_CLASS_$_NSRunLoop`
  - `_OBJC_CLASS_$_NSSet`
  - `_OBJC_CLASS_$_NSString`
  - `_OBJC_CLASS_$_NSThread`
  - `_OBJC_CLASS_$_NSTimer`
  - `_OBJC_CLASS_$_NSURL`
  - `_OBJC_CLASS_$_NSURLSession`
  - `_OBJC_CLASS_$_NSURLSessionConfiguration`
  - `_OBJC_CLASS_$_NSURLSessionWebSocketMessage`
  - `_OBJC_CLASS_$_NSUUID`
  - `_OBJC_CLASS_$_NSValue`
  - `_OBJC_CLASS_$_SFSpeechAudioBufferRecognitionRequest`
  - `_OBJC_CLASS_$_SFSpeechRecognizer`
  - `_OBJC_CLASS_$_UIApplication`
  - `_OBJC_CLASS_$_UIBezierPath`
  - `_OBJC_CLASS_$_UIBlurEffect`
  - `_OBJC_CLASS_$_UIButton`
  - `_OBJC_CLASS_$_UIColor`
  - `_OBJC_CLASS_$_UIDevice`
  - `_OBJC_CLASS_$_UIFont`
  - `_OBJC_CLASS_$_UIImage`
  - `_OBJC_CLASS_$_UIImageSymbolConfiguration`
  - `_OBJC_CLASS_$_UIImageView`
  - `_OBJC_CLASS_$_UILabel`
  - `_OBJC_CLASS_$_UILongPressGestureRecognizer`
  - `_OBJC_CLASS_$_UIPageControl`
  - `_OBJC_CLASS_$_UIPanGestureRecognizer`
  - `_OBJC_CLASS_$_UIScreen`
  - `_OBJC_CLASS_$_UIScrollView`
  - `_OBJC_CLASS_$_UITapGestureRecognizer`
  - `_OBJC_CLASS_$_UITextInputMode`
  - `_OBJC_CLASS_$_UIView`
  - `_OBJC_CLASS_$_UIViewController`
  - `_OBJC_CLASS_$_UIVisualEffectView`
  - `_OBJC_CLASS_$_UIWindow`
  - `_OBJC_CLASS_$_UIWindowScene`
  - `_OBJC_EHTYPE_$_NSException`
  - `_OBJC_METACLASS_$_NSObject`
  - `_OBJC_METACLASS_$_UIButton`
  - `_OBJC_METACLASS_$_UIScrollView`
  - `_OBJC_METACLASS_$_UIView`
  - `_SecItemAdd`
  - `_SecItemCopyMatching`
  - `_SecItemUpdate`
  - `_UIApplicationDidBecomeActiveNotification`
  - `_UIApplicationDidEnterBackgroundNotification`
  - `_UIApplicationWillEnterForegroundNotification`
  - `_UIApplicationWillResignActiveNotification`
  - `_UIDeviceBatteryLevelDidChangeNotification`
  - `_UIDeviceBatteryStateDidChangeNotification`
  - `_UIEdgeInsetsFromString`
  - `_UIEdgeInsetsZero`
  - `_UIFontWeightBlack`
  - `_UIFontWeightBold`
  - `_UIFontWeightMedium`
  - `_UIFontWeightRegular`
  - `_UIFontWeightSemibold`
  - `_UIGraphicsBeginImageContextWithOptions`
  - `_UIGraphicsEndImageContext`
  - `_UIGraphicsGetCurrentContext`
  - `_UIGraphicsGetImageFromCurrentImageContext`
  - `_UISceneDidActivateNotification`
  - `_UISceneWillEnterForegroundNotification`
  - `_UIScreenDidConnectNotification`
  - `_UIScreenDidDisconnectNotification`
  - `_UIScreenModeDidChangeNotification`
  - `_UIWindowLevelNormal`
  - `__Block_object_assign`
  - `__Block_object_dispose`
  - `__NSConcreteGlobalBlock`
  - `__NSConcreteStackBlock`
  - `__UICreateScreenUIImage`
  - `__Unwind_Resume`
  - `___CFConstantStringClassReference`
  - `___NSArray0__`
  - `___NSDictionary0__`
  - `___memcpy_chk`
  - `___objc_personality_v0`
  - `___snprintf_chk`
  - `___stack_chk_fail`
  - `___stack_chk_guard`
  - `__dispatch_main_q`
  - `__dispatch_source_type_timer`
  - `__objc_empty_cache`
  - `__tlv_bootstrap`
  - `_arc4random_buf`
  - `_backtrace`
  - `_backtrace_symbols`
  - `_bzero`
  - `_chmod`
  - `_chown`
  - `_class_addMethod`
  - `_class_getInstanceMethod`
  - `_class_getInstanceVariable`
  - `_class_getName`
  - `_class_getSuperclass`
  - `_dispatch_after`
  - `_dispatch_async`
  - `_dispatch_get_global_queue`
  - `_dispatch_once`
  - `_dispatch_queue_create`
  - `_dispatch_resume`
  - `_dispatch_source_cancel`
  - `_dispatch_source_create`
  - `_dispatch_source_set_event_handler`
  - `_dispatch_source_set_timer`
  - `_dispatch_time`
  - `_dlopen`
  - `_dlsym`
  - `_environ`
  - `_fclose`
  - `_fopen`
  - `_fread`
  - `_free`
  - `_fwrite`
  - `_getpid`
  - `_host_statistics`
  - `_host_statistics64`
  - `_ivar_getOffset`
  - `_kCACornerCurveContinuous`
  - `_kCAMediaTimingFunctionEaseInEaseOut`
  - `_kCAMediaTimingFunctionLinear`
  - `_kCFAllocatorDefault`
  - `_kCFCoreFoundationVersionNumber`
  - `_kIOMasterPortDefault`
  - `_kSecAttrAccessible`
  - `_kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`
  - `_kSecAttrAccount`
  - `_kSecAttrService`
  - `_kSecClass`
  - `_kSecClassGenericPassword`
  - `_kSecMatchLimit`
  - `_kSecMatchLimitOne`
  - `_kSecReturnData`
  - `_kSecValueData`
  - `_kill`
  - `_mach_absolute_time`
  - `_mach_host_self`
  - `_mach_task_self_`
  - `_memcpy`
  - `_method_getTypeEncoding`
  - `_notify_post`
  - `_notify_register_dispatch`
  - `_objc_alloc`
  - `_objc_alloc_init`
  - `_objc_allocateClassPair`
  - `_objc_autorelease`
  - `_objc_autoreleasePoolPop`
  - `_objc_autoreleasePoolPush`
  - `_objc_autoreleaseReturnValue`
  - `_objc_begin_catch`
  - `_objc_copyWeak`
  - `_objc_destroyWeak`
  - `_objc_end_catch`
  - `_objc_enumerationMutation`
  - `_objc_exception_rethrow`
  - `_objc_getAssociatedObject`
  - `_objc_getClass`
  - `_objc_getProperty`
  - `_objc_initWeak`
  - `_objc_loadWeakRetained`
  - `_objc_msgSend`
  - `_objc_msgSendSuper`
  - `_objc_msgSendSuper2`
  - `_objc_registerClassPair`
  - `_objc_release`
  - `_objc_retain`
  - `_objc_retainAutorelease`
  - `_objc_retainAutoreleaseReturnValue`
  - `_objc_retainAutoreleasedReturnValue`
  - `_objc_retainBlock`
  - `_objc_setAssociatedObject`
  - `_objc_setProperty_nonatomic_copy`
  - `_objc_storeStrong`
  - `_objc_storeWeak`
  - `_objc_sync_enter`
  - `_objc_sync_exit`
  - `_objc_terminate`
  - `_objc_unsafeClaimAutoreleasedReturnValue`
  - `_object_getClass`
  - `_object_getIvar`
  - `_object_setIvar`
  - `_posix_spawn`
  - `_rename`
  - `_sel_registerName`
  - `_sigaction`
  - `_snprintf`
  - `_sqlite3_close`
  - `_sqlite3_exec`
  - `_sqlite3_free`
  - `_sqlite3_open`
  - `_stat`
  - `_strlen`
  - `_strncasecmp`
  - `_strsignal`
  - `_strstr`
  - `_sysctl`
  - `_sysctlbyname`
  - `_time`
  - `_vm_kernel_page_size`
  - `_vm_read_overwrite`
  - `_waitpid`
  - `dyld_stub_binder`

### Classes Objective-C (toàn bộ — metadata giống hệt ở cả 2 slice, đã kiểm parity)
#### class `CBLocalization`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Ivars:
  - `_activeLanguageCode` : `@"NSString"` (size 8)
  - `_cachedStringTables` : `@"NSMutableDictionary"` (size 8)
  - `_activeLanguageTable` : `@"NSDictionary"` (size 8)
  - `_viTable` : `@"NSDictionary"` (size 8)
  - `_enTable` : `@"NSDictionary"` (size 8)
- Instance methods (6):
  - `- P�1` — types: `@16@0:8`
  - `- A�1` — types: `v16@0:8`
  - `- �1` — types: `@16@0:8`
  - `- �1` — types: `@24@0:8@16`
  - `- p�1` — types: `@24@0:8@16`
  - `- ��1` — types: `v16@0:8`
- Class methods (6):
  - `+ +�1` — types: `@16@0:8`
  - `+ ��1` — types: `@16@0:8`
  - `+ ��1` — types: `@24@0:8@16`
  - `+ ��1` — types: `@16@0:8`
  - `+ ��1` — types: `v24@0:8@16`
  - `+ p�1` — types: `@24@0:8@16`

#### class `CBDashboardSettings`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Ivars:
  - `_portalAppEnabled` : `B` (size 1)
  - `_screenBlankEnabled` : `B` (size 1)
  - `_splitScreenEnabled` : `B` (size 1)
  - `_hideIconLabels` : `B` (size 1)
  - `_dockSystemMonitorEnabled` : `B` (size 1)
  - `_dockSystemMonitorShowAll` : `B` (size 1)
  - `_autoLaunchOnConnect` : `B` (size 1)
  - `_agreedToEULA` : `B` (size 1)
  - `_aiBubbleIsLeft` : `B` (size 1)
  - `_bridgedApps` : `@"NSArray"` (size 8)
  - `_appSettings` : `@"NSDictionary"` (size 8)
  - `_splitLeftBundleID` : `@"NSString"` (size 8)
  - `_splitRightBundleID` : `@"NSString"` (size 8)
  - `_splitPreset` : `q` (size 8)
  - `_splitMode` : `q` (size 8)
  - `_splitApp1` : `@"NSString"` (size 8)
  - `_splitApp2` : `@"NSString"` (size 8)
  - `_splitApp3` : `@"NSString"` (size 8)
  - `_splitApp4` : `@"NSString"` (size 8)
  - `_splitRatio` : `d` (size 8)
  - `_gridCols` : `q` (size 8)
  - `_gridRows` : `q` (size 8)
  - `_autoLaunchBundleID` : `@"NSString"` (size 8)
  - `_aiBubbleNormalizedY` : `d` (size 8)
- Properties:
  - `bridgedApps` — attrs: `T@"NSArray",&,N,V_bridgedApps`
  - `appSettings` — attrs: `T@"NSDictionary",&,N,V_appSettings`
  - `portalAppEnabled` — attrs: `TB,N,V_portalAppEnabled`
  - `screenBlankEnabled` — attrs: `TB,N,V_screenBlankEnabled`
  - `splitScreenEnabled` — attrs: `TB,N,V_splitScreenEnabled`
  - `splitLeftBundleID` — attrs: `T@"NSString",C,N,V_splitLeftBundleID`
  - `splitRightBundleID` — attrs: `T@"NSString",C,N,V_splitRightBundleID`
  - `splitPreset` — attrs: `Tq,N,V_splitPreset`
  - `splitMode` — attrs: `Tq,N,V_splitMode`
  - `splitApp1` — attrs: `T@"NSString",C,N,V_splitApp1`
  - `splitApp2` — attrs: `T@"NSString",C,N,V_splitApp2`
  - `splitApp3` — attrs: `T@"NSString",C,N,V_splitApp3`
  - `splitApp4` — attrs: `T@"NSString",C,N,V_splitApp4`
  - `splitRatio` — attrs: `Td,N,V_splitRatio`
  - `gridCols` — attrs: `Tq,N,V_gridCols`
  - `gridRows` — attrs: `Tq,N,V_gridRows`
  - `hideIconLabels` — attrs: `TB,N,V_hideIconLabels`
  - `dockSystemMonitorEnabled` — attrs: `TB,N,V_dockSystemMonitorEnabled`
  - `dockSystemMonitorShowAll` — attrs: `TB,N,V_dockSystemMonitorShowAll`
  - `autoLaunchOnConnect` — attrs: `TB,N,V_autoLaunchOnConnect`
  - `autoLaunchBundleID` — attrs: `T@"NSString",C,N,V_autoLaunchBundleID`
  - `agreedToEULA` — attrs: `TB,N,V_agreedToEULA`
  - `aiBubbleIsLeft` — attrs: `TB,N,V_aiBubbleIsLeft`
  - `aiBubbleNormalizedY` — attrs: `Td,N,V_aiBubbleNormalizedY`
- Instance methods (55):
  - `- P�1` — types: `@16@0:8`
  - `- ^�1` — types: `d24@0:8@16`
  - `- p�1` — types: `v32@0:8d16@24`
  - `- ��1` — types: `v20@0:8B16`
  - `- ��1` — types: `v20@0:8B16`
  - `- ��1` — types: `v28@0:8B16d20`
  - `- :�1` — types: `v16@0:8`
  - `- ��1` — types: `v16@0:8`
  - `- ��1` — types: `@16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- �1` — types: `@16@0:8`
  - `- �1` — types: `v24@0:8@16`
  - `-  �1` — types: `B16@0:8`
  - `- 1�1` — types: `v20@0:8B16`
  - `- F�1` — types: `B16@0:8`
  - `- Y�1` — types: `v20@0:8B16`
  - `- p�1` — types: `B16@0:8`
  - `- ��1` — types: `v20@0:8B16`
  - `- ��1` — types: `@16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `@16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `q16@0:8`
  - `- ��1` — types: `v24@0:8q16`
  - `- �1` — types: `q16@0:8`
  - `- �1` — types: `v24@0:8q16`
  - `-  �1` — types: `@16@0:8`
  - `- *�1` — types: `v24@0:8@16`
  - `- 8�1` — types: `@16@0:8`
  - `- B�1` — types: `v24@0:8@16`
  - `- P�1` — types: `@16@0:8`
  - `- Z�1` — types: `v24@0:8@16`
  - `- h�1` — types: `@16@0:8`
  - `- r�1` — types: `v24@0:8@16`
  - `- ��1` — types: `d16@0:8`
  - `- ��1` — types: `v24@0:8d16`
  - `- ��1` — types: `q16@0:8`
  - `- ��1` — types: `v24@0:8q16`
  - `- ��1` — types: `q16@0:8`
  - `- ��1` — types: `v24@0:8q16`
  - `- ��1` — types: `B16@0:8`
  - `- ��1` — types: `v20@0:8B16`
  - `- ��1` — types: `B16@0:8`
  - `- �1` — types: `B16@0:8`
  - `- �1` — types: `B16@0:8`
  - `- .�1` — types: `v20@0:8B16`
  - `- F�1` — types: `@16@0:8`
  - `- Y�1` — types: `v24@0:8@16`
  - `- p�1` — types: `B16@0:8`
  - `- }�1` — types: `v20@0:8B16`
  - `- ��1` — types: `B16@0:8`
  - `- ��1` — types: `v20@0:8B16`
  - `- ��1` — types: `d16@0:8`
  - `- ��1` — types: `v24@0:8d16`
  - `- ��1` — types: `v16@0:8`
- Class methods (4):
  - `+ +�1` — types: `@16@0:8`
  - `+ "�1` — types: `@16@0:8`
  - `+ 5�1` — types: `@16@0:8`
  - `+ J�1` — types: `@16@0:8`

#### class `CBHttpClient`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Instance methods (3):
  - `- P�1` — types: `@16@0:8`
  - `- ��1` — types: `v56@0:8@16@24d32@40@?48`
  - `- �1` — types: `v48@0:8@16d24@32@?40`
- Class methods (1):
  - `+ ��1` — types: `@16@0:8`

#### class `CBLicenseSyncManager`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Ivars:
  - `_isSyncing` : `B` (size 1)
  - `_syncQueue` : `@"NSObject<OS_dispatch_queue>"` (size 8)
  - `_lastAttemptTimestamp` : `Q` (size 8)
- Properties:
  - `isSyncing` — attrs: `TB,N,V_isSyncing`
  - `syncQueue` — attrs: `T@"NSObject<OS_dispatch_queue>",&,N,V_syncQueue`
  - `lastAttemptTimestamp` — attrs: `TQ,N,V_lastAttemptTimestamp`
- Instance methods (24):
  - `- P�1` — types: `@16@0:8`
  - `- |�1` — types: `@16@0:8`
  - `- ��1` — types: `B16@0:8`
  - `- 
�1` — types: `Q16@0:8`
  - `- ��1` — types: `B16@0:8`
  - `- %�1` — types: `v16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- A�1` — types: `v24@0:8@?16`
  - `- "�1` — types: `@16@0:8`
  - `- ��1` — types: `@16@0:8`
  - `- Z�1` — types: `v32@0:8B16B20@?24`
  - `- "�1` — types: `v40@0:8B16B20@24@?32`
  - `- ��1` — types: `B32@0:8@16^@24`
  - `- ��1` — types: `Q16@0:8`
  - `- ��1` — types: `v24@0:8Q16`
  - `- ��1` — types: `@16@0:8`
  - `- v�1` — types: `v24@0:8@16`
  - `- ��1` — types: `B16@0:8`
  - `- 9�1` — types: `v20@0:8B16`
  - `- ��1` — types: `@16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `Q16@0:8`
  - `- G�1` — types: `v24@0:8Q16`
  - `- ��1` — types: `v16@0:8`
- Class methods (6):
  - `+ +�1` — types: `@16@0:8`
  - `+ `�1` — types: `B24@0:8@16`
  - `+ z�1` — types: `B24@0:8@16`
  - `+ ��1` — types: `B16@0:8`
  - `+ 
�1` — types: `@24@0:8@16`
  - `+ "�1` — types: `@16@0:8`

#### class `CBTouchCloneView`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Instance methods (5):
  - `- ��1` — types: `v36@0:8{CGPoint=dd}16B32`
  - `- ��1` — types: `v32@0:8@16@24`
  - `- ��1` — types: `v32@0:8@16@24`
  - `- ��1` — types: `v32@0:8@16@24`
  - `- ��1` — types: `v32@0:8@16@24`

#### class `CBBridgedPortalAppView`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Ivars:
  - `_imageView` : `@"UIImageView"` (size 8)
  - `_touchCloneView` : `@"CBTouchCloneView"` (size 8)
  - `_displayLink` : `@"CADisplayLink"` (size 8)
- Properties:
  - `imageView` — attrs: `T@"UIImageView",&,N,V_imageView`
  - `touchCloneView` — attrs: `T@"CBTouchCloneView",&,N,V_touchCloneView`
  - `displayLink` — attrs: `T@"CADisplayLink",&,N,V_displayLink`
- Instance methods (12):
  - `- �1` — types: `@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16`
  - `- �1` — types: `v16@0:8`
  - `- �1` — types: `v16@0:8`
  - `- x�1` — types: `v24@0:8@16`
  - `- 	�1` — types: `v16@0:8`
  - `- ��1` — types: `@16@0:8`
  - `- �1` — types: `v24@0:8@16`
  - `- %�1` — types: `@16@0:8`
  - `- 4�1` — types: `v24@0:8@16`
  - `- G�1` — types: `@16@0:8`
  - `- S�1` — types: `v24@0:8@16`
  - `- ��1` — types: `v16@0:8`

#### class `CBMultitaskingPillView`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Ivars:
  - `_onPillTapped` : `@?` (size 8)
  - `_blurView` : `@"UIVisualEffectView"` (size 8)
  - `_iconView` : `@"UIImageView"` (size 8)
  - `_titleLabel` : `@"UILabel"` (size 8)
- Properties:
  - `onPillTapped` — attrs: `T@?,C,N,V_onPillTapped`
  - `blurView` — attrs: `T@"UIVisualEffectView",&,N,V_blurView`
  - `iconView` — attrs: `T@"UIImageView",&,N,V_iconView`
  - `titleLabel` — attrs: `T@"UILabel",&,N,V_titleLabel`
- Instance methods (12):
  - `- �1` — types: `@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16`
  - `- j�1` — types: `v16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- �1` — types: `@?16@0:8`
  - `- `�1` — types: `v24@0:8@?16`
  - `- q�1` — types: `@16@0:8`
  - `- z�1` — types: `v24@0:8@16`
  - `- ��1` — types: `@16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `@16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `v16@0:8`

#### class `CBSlotPillHitButton`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Ivars:
  - `_hitInsets` : `{UIEdgeInsets="top"d"left"d"bottom"d"right"d}` (size 32)
- Properties:
  - `hitInsets` — attrs: `T{UIEdgeInsets=dddd},N,V_hitInsets`
- Instance methods (3):
  - `- w�1` — types: `B40@0:8{CGPoint=dd}16@32`
  - `- m�1` — types: `{UIEdgeInsets=dddd}16@0:8`
  - `- ��1` — types: `v48@0:8{UIEdgeInsets=dddd}16`

#### class `CBSlotPillView`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Ivars:
  - `_dotViews` : `@"NSMutableArray"` (size 8)
  - `_isFocusedMode` : `B` (size 1)
  - `_showsExpandButton` : `B` (size 1)
  - `_isCompactMode` : `B` (size 1)
  - `_onPillTapped` : `@?` (size 8)
  - `_onPillLongPressed` : `@?` (size 8)
  - `_onExpandTapped` : `@?` (size 8)
  - `_onRestoreTapped` : `@?` (size 8)
  - `_slotIndex` : `q` (size 8)
  - `_dotsButton` : `@"UIButton"` (size 8)
  - `_expandButton` : `@"UIButton"` (size 8)
  - `_restoreButton` : `@"UIButton"` (size 8)
  - `_separatorView` : `@"UIView"` (size 8)
- Properties:
  - `onPillTapped` — attrs: `T@?,C,N,V_onPillTapped`
  - `onPillLongPressed` — attrs: `T@?,C,N,V_onPillLongPressed`
  - `onExpandTapped` — attrs: `T@?,C,N,V_onExpandTapped`
  - `onRestoreTapped` — attrs: `T@?,C,N,V_onRestoreTapped`
  - `slotIndex` — attrs: `Tq,N,V_slotIndex`
  - `isFocusedMode` — attrs: `TB,N,V_isFocusedMode`
  - `showsExpandButton` — attrs: `TB,N,V_showsExpandButton`
  - `isCompactMode` — attrs: `TB,N,V_isCompactMode`
  - `dotsButton` — attrs: `T@"UIButton",&,N,V_dotsButton`
  - `expandButton` — attrs: `T@"UIButton",&,N,V_expandButton`
  - `restoreButton` — attrs: `T@"UIButton",&,N,V_restoreButton`
  - `separatorView` — attrs: `T@"UIView",&,N,V_separatorView`
- Instance methods (36):
  - `- �1` — types: `@24@0:8q16`
  - `- ��1` — types: `v16@0:8`
  - `- 5�1` — types: `v16@0:8`
  - `- �1` — types: `v20@0:8B16`
  - `- 0�1` — types: `v20@0:8B16`
  - `- @�1` — types: `v20@0:8B16`
  - `- w�1` — types: `B40@0:8{CGPoint=dd}16@32`
  - `- 7�1` — types: `v24@0:8@16`
  - `- �1` — types: `v24@0:8@16`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `v24@0:8@16`
  - `- F�1` — types: `v24@0:8@16`
  - `- �1` — types: `@?16@0:8`
  - `- `�1` — types: `v24@0:8@?16`
  - `- p�1` — types: `@?16@0:8`
  - `- P�1` — types: `v24@0:8@?16`
  - `- ��1` — types: `@?16@0:8`
  - `- f�1` — types: `v24@0:8@?16`
  - `- ��1` — types: `@?16@0:8`
  - `- y�1` — types: `v24@0:8@?16`
  - `- ��1` — types: `q16@0:8`
  - `- ��1` — types: `v24@0:8q16`
  - `- ��1` — types: `B16@0:8`
  - `- ��1` — types: `v20@0:8B16`
  - `- ��1` — types: `B16@0:8`
  - `- ��1` — types: `B16@0:8`
  - `- ��1` — types: `v20@0:8B16`
  - `- ��1` — types: `@16@0:8`
  - `- �1` — types: `v24@0:8@16`
  - `- �1` — types: `@16@0:8`
  - `- �1` — types: `v24@0:8@16`
  - `- /�1` — types: `@16@0:8`
  - `- =�1` — types: `v24@0:8@16`
  - `- O�1` — types: `@16@0:8`
  - `- ]�1` — types: `v24@0:8@16`
  - `- ��1` — types: `v16@0:8`

#### class `CBOverlayScrollView`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Instance methods (4):
  - `- �1` — types: `@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16`
  - `- ��1` — types: `B24@0:8@16`
  - `- l�1` — types: `v24@0:8@16`
  - `- ��1` — types: `v16@0:8`

#### class `CBMultitaskingOverlayView`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Protocols nhận: `UIScrollViewDelegate`
- Ivars:
  - `_onCloseRequested` : `@?` (size 8)
  - `_onMultiSplitSelected` : `@?` (size 8)
  - `_dimBackground` : `@"UIView"` (size 8)
  - `_cardShadowContainer` : `@"UIView"` (size 8)
  - `_sheetCard` : `@"UIVisualEffectView"` (size 8)
  - `_allApps` : `@"NSArray"` (size 8)
  - `_appPickerScrollView` : `@"UIScrollView"` (size 8)
  - `_appPickerPageControl` : `@"UIPageControl"` (size 8)
  - `_slotBIDs` : `@"NSMutableArray"` (size 8)
  - `_currentPreset` : `q` (size 8)
  - `_currentRatio` : `d` (size 8)
  - `_targetSlotIndex` : `q` (size 8)
  - `_overlayMode` : `q` (size 8)
  - `_headerIcon` : `@"UIImageView"` (size 8)
  - `_titleLabel` : `@"UILabel"` (size 8)
  - `_appSegmentBtn` : `@"UIButton"` (size 8)
  - `_layoutSegmentBtn` : `@"UIButton"` (size 8)
  - `_recentSegmentBtn` : `@"UIButton"` (size 8)
  - `_runningApps` : `@"NSArray"` (size 8)
- Properties:
  - `onCloseRequested` — attrs: `T@?,C,N,V_onCloseRequested`
  - `onMultiSplitSelected` — attrs: `T@?,C,N,V_onMultiSplitSelected`
  - `dimBackground` — attrs: `T@"UIView",&,N,V_dimBackground`
  - `cardShadowContainer` — attrs: `T@"UIView",&,N,V_cardShadowContainer`
  - `sheetCard` — attrs: `T@"UIVisualEffectView",&,N,V_sheetCard`
  - `allApps` — attrs: `T@"NSArray",&,N,V_allApps`
  - `appPickerScrollView` — attrs: `T@"UIScrollView",&,N,V_appPickerScrollView`
  - `appPickerPageControl` — attrs: `T@"UIPageControl",&,N,V_appPickerPageControl`
  - `slotBIDs` — attrs: `T@"NSMutableArray",&,N,V_slotBIDs`
  - `currentPreset` — attrs: `Tq,N,V_currentPreset`
  - `currentRatio` — attrs: `Td,N,V_currentRatio`
  - `targetSlotIndex` — attrs: `Tq,N,V_targetSlotIndex`
  - `overlayMode` — attrs: `Tq,N,V_overlayMode`
  - `headerIcon` — attrs: `T@"UIImageView",&,N,V_headerIcon`
  - `titleLabel` — attrs: `T@"UILabel",&,N,V_titleLabel`
  - `appSegmentBtn` — attrs: `T@"UIButton",&,N,V_appSegmentBtn`
  - `layoutSegmentBtn` — attrs: `T@"UIButton",&,N,V_layoutSegmentBtn`
  - `recentSegmentBtn` — attrs: `T@"UIButton",&,N,V_recentSegmentBtn`
  - `runningApps` — attrs: `T@"NSArray",&,N,V_runningApps`
  - `hash` — attrs: `TQ,R`
  - `superclass` — attrs: `T#,R`
  - `description` — attrs: `T@"NSString",R,C`
  - `debugDescription` — attrs: `T@"NSString",R,C`
- Instance methods (66):
  - `- �1` — types: `@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16`
  - `- 	�1` — types: `v16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `v16@0:8`
  - `- ��1` — types: `v16@0:8`
  - `- <�1` — types: `v16@0:8`
  - `- �1` — types: `v40@0:8d16d24d32`
  - `- ��1` — types: `v24@0:8@16`
  - `- v�1` — types: `v24@0:8@16`
  - `- >�1` — types: `v40@0:8d16d24d32`
  - `- f�1` — types: `v40@0:8d16d24d32`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `v24@0:8@16`
  - `- m�1` — types: `v24@0:8@16`
  - `- ��1` — types: `v16@0:8`
  - `- ��1` — types: `v16@0:8`
  - `- ` — types: `v16@0:8`
  - `- r�1` — types: `v16@0:8`
  - `-  �1` — types: `v48@0:8q16@24@32@40`
  - `- ��1` — types: `v24@0:8@16`
  - `- B�1` — types: `v24@0:8@16`
  - `- }�1` — types: `v32@0:8q16@24`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `v16@0:8`
  - `- ��1` — types: `@?16@0:8`
  - `- ��1` — types: `v24@0:8@?16`
  - `- ��1` — types: `@?16@0:8`
  - `- ��1` — types: `v24@0:8@?16`
  - `- �1` — types: `@16@0:8`
  - `- �1` — types: `v24@0:8@16`
  - `- '�1` — types: `@16@0:8`
  - `- ;�1` — types: `v24@0:8@16`
  - `- S�1` — types: `@16@0:8`
  - `- ]�1` — types: `v24@0:8@16`
  - `- k�1` — types: `@16@0:8`
  - `- s�1` — types: `v24@0:8@16`
  - `- �1` — types: `@16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `@16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `@16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `q16@0:8`
  - `- ��1` — types: `v24@0:8q16`
  - `- �1` — types: `d16@0:8`
  - `- �1` — types: `v24@0:8d16`
  - `- -�1` — types: `q16@0:8`
  - `- =�1` — types: `v24@0:8q16`
  - `- Q�1` — types: `q16@0:8`
  - `- ]�1` — types: `v24@0:8q16`
  - `- m�1` — types: `@16@0:8`
  - `- x�1` — types: `v24@0:8@16`
  - `- ��1` — types: `@16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `@16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `@16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `@16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `@16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `v16@0:8`

#### class `CBBridgedUIAppView`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Ivars:
  - `_hosting` : `B` (size 1)
  - `_invalidated` : `B` (size 1)
  - `_audioOnlyBackgroundMode` : `B` (size 1)
  - `_bundleIdentifier` : `@"NSString"` (size 8)
  - `_appViewController` : `@"SBAppViewController"` (size 8)
  - `_wrapperView` : `@"UIView"` (size 8)
  - `_appScale` : `d` (size 8)
- Properties:
  - `bundleIdentifier` — attrs: `T@"NSString",C,N,V_bundleIdentifier`
  - `appViewController` — attrs: `T@"SBAppViewController",&,N,V_appViewController`
  - `wrapperView` — attrs: `T@"UIView",&,N,V_wrapperView`
  - `appScale` — attrs: `Td,N,V_appScale`
  - `hosting` — attrs: `TB,N,V_hosting`
  - `invalidated` — attrs: `TB,N,V_invalidated`
  - `audioOnlyBackgroundMode` — attrs: `TB,N,V_audioOnlyBackgroundMode`
- Instance methods (31):
  - `- ��1` — types: `@24@0:8@16`
  - `- }�1` — types: `@32@0:8@16d24`
  - `- ��1` — types: `v24@0:8d16`
  - `- ` — types: `v20@0:8B16`
  - `- ��1` — types: `v16@0:8`
  - `- ��1` — types: `@40@0:8{CGPoint=dd}16@32`
  - `- ��1` — types: `v32@0:8@16@24`
  - `- ��1` — types: `{CGSize=dd}48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16`
  - `- ��1` — types: `v16@0:8`
  - `- r�1` — types: `v16@0:8`
  - `- �1` — types: `v16@0:8`
  - `- ��1` — types: `v16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- �1` — types: `v16@0:8`
  - `- ��1` — types: `v16@0:8`
  - `- ��1` — types: `@16@0:8`
  - `- -�1` — types: `B24@0:8@16`
  - `- 	�1` — types: `v16@0:8`
  - `- ߽1` — types: `@16@0:8`
  - `- =�1` — types: `v24@0:8@16`
  - `- R�1` — types: `@16@0:8`
  - `- d�1` — types: `v24@0:8@16`
  - `- z�1` — types: `@16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `d16@0:8`
  - `- ��1` — types: `B16@0:8`
  - `- ��1` — types: `v20@0:8B16`
  - `- ��1` — types: `B16@0:8`
  - `- �1` — types: `v20@0:8B16`
  - `- ��1` — types: `B16@0:8`
  - `- ��1` — types: `v16@0:8`

#### class `CBWindow`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Protocols nhận: `CBVoiceSessionStateDelegate`
- Ivars:
  - `_boundDisplay` : `@"CADisplay"` (size 8)
  - `_boundDisplayConfig` : `@"FBSDisplayConfiguration"` (size 8)
  - `_isVisible` : `B` (size 1)
  - `_rootWindow` : `@"UIWindow"` (size 8)
  - `_rootViewController` : `@"UIViewController"` (size 8)
  - `_contentView` : `@"UIVisualEffectView"` (size 8)
  - `_multitaskingPill` : `@"CBMultitaskingPillView"` (size 8)
  - `_multitaskingOverlay` : `@"CBMultitaskingOverlayView"` (size 8)
  - `_aiBubbleView` : `@"CBAIBubbleView"` (size 8)
  - `_appFrame` : `{CGRect="origin"{CGPoint="x"d"y"d}"size"{CGSize="width"d"height"d}}` (size 32)
- Properties:
  - `appFrame` — attrs: `T{CGRect={CGPoint=dd}{CGSize=dd}},N,V_appFrame`
  - `rootWindow` — attrs: `T@"UIWindow",&,N,V_rootWindow`
  - `rootViewController` — attrs: `T@"UIViewController",&,N,V_rootViewController`
  - `contentView` — attrs: `T@"UIVisualEffectView",&,N,V_contentView`
  - `multitaskingPill` — attrs: `T@"CBMultitaskingPillView",&,N,V_multitaskingPill`
  - `multitaskingOverlay` — attrs: `T@"CBMultitaskingOverlayView",&,N,V_multitaskingOverlay`
  - `aiBubbleView` — attrs: `T@"CBAIBubbleView",&,N,V_aiBubbleView`
  - `isVisible` — attrs: `TB,N,V_isVisible`
  - `hash` — attrs: `TQ,R`
  - `superclass` — attrs: `T#,R`
  - `description` — attrs: `T@"NSString",R,C`
  - `debugDescription` — attrs: `T@"NSString",R,C`
- Instance methods (31):
  - `- n�1` — types: `@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16`
  - `- ��1` — types: `@16@0:8`
  - `- ��1` — types: `v16@0:8`
  - `- ��1` — types: `@16@0:8`
  - `- J�1` — types: `v32@0:8@16q24`
  - `- �1` — types: `@16@0:8`
  - `- ��1` — types: `v16@0:8`
  - `- ��1` — types: `v16@0:8`
  - `- ��1` — types: `v24@0:8@?16`
  - `- ��1` — types: `B16@0:8`
  - `- �1` — types: `v16@0:8`
  - `- ��1` — types: `v16@0:8`
  - `- 	�1` — types: `v16@0:8`
  - `- ��1` — types: `v24@0:8q16`
  - `- ��1` — types: `v16@0:8`
  - `- ��1` — types: `v16@0:8`
  - `- ��1` — types: `{CGRect={CGPoint=dd}{CGSize=dd}}16@0:8`
  - `- ��1` — types: `v48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16`
  - `- ��1` — types: `@16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `@16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- %�1` — types: `@16@0:8`
  - `- �1` — types: `v24@0:8@16`
  - `- �1` — types: `@16@0:8`
  - `- )�1` — types: `v24@0:8@16`
  - `- >�1` — types: `v24@0:8@16`
  - `- V�1` — types: `v24@0:8@16`
  - `- g�1` — types: `B16@0:8`
  - `- q�1` — types: `v20@0:8B16`
  - `- ��1` — types: `v16@0:8`
- Class methods (9):
  - `+ ��1` — types: `@16@0:8`
  - `+ %�1` — types: `v16@0:8`
  - `+ ��1` — types: `@16@0:8`
  - `+ �1` — types: `@16@0:8`
  - `+ |�1` — types: `@16@0:8`
  - `+ 7�1` — types: `d16@0:8`
  - `+ ��1` — types: `{CGRect={CGPoint=dd}{CGSize=dd}}16@0:8`
  - `+ ��1` — types: `{UIEdgeInsets=dddd}16@0:8`
  - `+ ��1` — types: `{CGRect={CGPoint=dd}{CGSize=dd}}16@0:8`

#### class `CBDockMetricItemView`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Ivars:
  - `_iconImageView` : `@"UIImageView"` (size 8)
  - `_fallbackIconLabel` : `@"UILabel"` (size 8)
  - `_valueLabel` : `@"UILabel"` (size 8)
- Properties:
  - `iconImageView` — attrs: `T@"UIImageView",&,N,V_iconImageView`
  - `fallbackIconLabel` — attrs: `T@"UILabel",&,N,V_fallbackIconLabel`
  - `valueLabel` — attrs: `T@"UILabel",&,N,V_valueLabel`
- Instance methods (11):
  - `- �1` — types: `@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16`
  - `- ��1` — types: `v16@0:8`
  - `- ` — types: `v32@0:8@16@24`
  - `- 1` — types: `v32@0:8@16@24`
  - `- ` — types: `@16@0:8`
  - `- A` — types: `v24@0:8@16`
  - `- S` — types: `@16@0:8`
  - `- e` — types: `v24@0:8@16`
  - `- ��1` — types: `@16@0:8`
  - `- {` — types: `v24@0:8@16`
  - `- ��1` — types: `v16@0:8`

#### class `CBDockSystemMonitorView`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Ivars:
  - `_battItem` : `@"CBDockMetricItemView"` (size 8)
  - `_tempItem` : `@"CBDockMetricItemView"` (size 8)
  - `_cpuItem` : `@"CBDockMetricItemView"` (size 8)
  - `_ramItem` : `@"CBDockMetricItemView"` (size 8)
  - `_refreshTimer` : `@"NSTimer"` (size 8)
  - `_prevCpuUser` : `I` (size 4)
  - `_prevCpuSystem` : `I` (size 4)
  - `_prevCpuNice` : `I` (size 4)
  - `_prevCpuIdle` : `I` (size 4)
  - `_hasCpuHistory` : `B` (size 1)
  - `_showAll` : `B` (size 1)
- Properties:
  - `isMonitoring` — attrs: `TB,R,N`
  - `showAll` — attrs: `TB,N,V_showAll`
  - `detailedMode` — attrs: `TB,N`
- Instance methods (19):
  - `- �1` — types: `@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16`
  - `- 	�1` — types: `v16@0:8`
  - `- �2` — types: `B16@0:8`
  - `- �2` — types: `v20@0:8B16`
  - `- g2` — types: `v20@0:8B16`
  - `- �2` — types: `v24@0:8@16`
  - `- 2` — types: `v24@0:8@16`
  - `- ��1` — types: `v16@0:8`
  - `- �2` — types: `v16@0:8`
  - `- X2` — types: `v16@0:8`
  - `- s2` — types: `B16@0:8`
  - `- /2` — types: `v24@0:8@16`
  - `- 2` — types: `v16@0:8`
  - `- J2` — types: `v16@0:8`
  - `- �2` — types: `f16@0:8`
  - `- �2` — types: `f16@0:8`
  - `- �2` — types: `f32@0:8^Q16^Q24`
  - `- �2` — types: `B16@0:8`
  - `- ��1` — types: `v16@0:8`

#### class `CBSplitSplashScreenView`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Ivars:
  - `_glowImageView` : `@"UIImageView"` (size 8)
  - `_horizonLineView` : `@"UIView"` (size 8)
  - `_horizonGradient` : `@"CAGradientLayer"` (size 8)
  - `_horizonDashedMask` : `@"CAShapeLayer"` (size 8)
  - `_logoImageView` : `@"UIImageView"` (size 8)
  - `_trackView` : `@"UIView"` (size 8)
  - `_progressView` : `@"UIView"` (size 8)
  - `_progressGradient` : `@"CAGradientLayer"` (size 8)
  - `_badgeLabel` : `@"UILabel"` (size 8)
  - `_isDismissing` : `B` (size 1)
  - `_hasStartedAnimation` : `B` (size 1)
  - `_animationStartTime` : `d` (size 8)
  - `_onWillDismiss` : `@?` (size 8)
  - `_onDismissed` : `@?` (size 8)
- Properties:
  - `isDismissing` — attrs: `TB,R,N`
  - `onWillDismiss` — attrs: `T@?,C,N,V_onWillDismiss`
  - `onDismissed` — attrs: `T@?,C,N,V_onDismissed`
- Instance methods (13):
  - `- �1` — types: `@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16`
  - `- ��1` — types: `v16@0:8`
  - `- �2` — types: `v16@0:8`
  - `- �2` — types: `v24@0:8@16`
  - `- 2` — types: `B16@0:8`
  - `- 2` — types: `v20@0:8B16`
  - `- �2` — types: `v28@0:8B16@?20`
  - `- 	�1` — types: `v16@0:8`
  - `- �2` — types: `@?16@0:8`
  - `- "2` — types: `v24@0:8@?16`
  - `- �2` — types: `@?16@0:8`
  - `- 42` — types: `v24@0:8@?16`
  - `- ��1` — types: `v16@0:8`
- Class methods (3):
  - `+ X2` — types: `@16@0:8`
  - `+ �2` — types: `@16@0:8`
  - `+ �2` — types: `@24@0:8d16`

#### class `CBAIBubbleView`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Protocols nhận: `UIGestureRecognizerDelegate`
- Ivars:
  - `_blurView` : `@"UIVisualEffectView"` (size 8)
  - `_coreContainer` : `@"UIView"` (size 8)
  - `_auraPulseView` : `@"UIView"` (size 8)
  - `_borderGradient` : `@"CAGradientLayer"` (size 8)
  - `_iconContainerView` : `@"UIView"` (size 8)
  - `_leftEyeLayer` : `@"CAShapeLayer"` (size 8)
  - `_rightEyeLayer` : `@"CAShapeLayer"` (size 8)
  - `_mouthLayer` : `@"CAShapeLayer"` (size 8)
  - `_coreDotLayer` : `@"CAShapeLayer"` (size 8)
  - `_isDragging` : `B` (size 1)
  - `_idleTimer` : `@"NSTimer"` (size 8)
  - `_lastTapTime` : `d` (size 8)
  - `_activated` : `B` (size 1)
  - `_visualState` : `q` (size 8)
  - `_onBubbleTapped` : `@?` (size 8)
  - `_onPositionChanged` : `@?` (size 8)
  - `_idleAlpha` : `d` (size 8)
  - `_boundaryBounds` : `{CGRect="origin"{CGPoint="x"d"y"d}"size"{CGSize="width"d"height"d}}` (size 32)
- Properties:
  - `visualState` — attrs: `Tq,N,V_visualState`
  - `onBubbleTapped` — attrs: `T@?,C,N,V_onBubbleTapped`
  - `onPositionChanged` — attrs: `T@?,C,N,V_onPositionChanged`
  - `activated` — attrs: `TB,N,GisActivated,V_activated`
  - `boundaryBounds` — attrs: `T{CGRect={CGPoint=dd}{CGSize=dd}},N,V_boundaryBounds`
  - `idleAlpha` — attrs: `Td,N,V_idleAlpha`
  - `hash` — attrs: `TQ,R`
  - `superclass` — attrs: `T#,R`
  - `description` — attrs: `T@"NSString",R,C`
  - `debugDescription` — attrs: `T@"NSString",R,C`
- Instance methods (37):
  - `- ��1` — types: `@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16`
  - `- O2` — types: `v16@0:8`
  - `- ^2` — types: `v16@0:8`
  - `- n2` — types: `v16@0:8`
  - `- �2` — types: `^{CGPath=}24@0:8q16`
  - `- �2` — types: `^{CGPath=}24@0:8q16`
  - `- �2` — types: `^{CGPath=}24@0:8q16`
  - `- �2` — types: `^{CGPath=}24@0:8q16`
  - `- �2` — types: `@16@0:8`
  - `- �2` — types: `v28@0:8q16B24`
  - `- �2` — types: `v16@0:8`
  - `- 	�1` — types: `v16@0:8`
  - `- �2` — types: `v24@0:8@16`
  - `- 2` — types: `v16@0:8`
  - `- �2` — types: `v16@0:8`
  - `- R�1` — types: `v16@0:8`
  - `- H�1` — types: `v16@0:8`
  - `- 2` — types: `v24@0:8@16`
  - `- x2` — types: `v20@0:8B16`
  - `- �2` — types: `v24@0:8@16`
  - `- 8
2` — types: `v24@0:8B16B20`
  - `- /�1` — types: `v28@0:8q16B24`
  - `- ��1` — types: `v48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16`
  - `- w�1` — types: `B40@0:8{CGPoint=dd}16@32`
  - `- O
2` — types: `q16@0:8`
  - `- [
2` — types: `v24@0:8q16`
  - `- �2` — types: `@?16@0:8`
  - `- 
�1` — types: `v24@0:8@?16`
  - `- �2` — types: `@?16@0:8`
  - `- k
2` — types: `v24@0:8@?16`
  - `- �
2` — types: `B16@0:8`
  - `- �
2` — types: `v20@0:8B16`
  - `- �
2` — types: `{CGRect={CGPoint=dd}{CGSize=dd}}16@0:8`
  - `- �
2` — types: `v48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16`
  - `- �
2` — types: `d16@0:8`
  - `- �
2` — types: `v24@0:8d16`
  - `- ��1` — types: `v16@0:8`

#### class `CBLicenseShieldIconView`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Instance methods (2):
  - `- �1` — types: `@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16`
  - `- �2` — types: `v48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16`

#### class `CBLicenseWarningModalView`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Ivars:
  - `_blurBackdrop` : `@"UIVisualEffectView"` (size 8)
  - `_scrimView` : `@"UIView"` (size 8)
  - `_cardView` : `@"UIView"` (size 8)
  - `_shieldIconView` : `@"CBLicenseShieldIconView"` (size 8)
  - `_titleLabel` : `@"UILabel"` (size 8)
  - `_bodyLabel` : `@"UILabel"` (size 8)
  - `_dismissButton` : `@"UIButton"` (size 8)
  - `_lastTapTimestamp` : `d` (size 8)
  - `_isDismissing` : `B` (size 1)
  - `_onDismiss` : `@?` (size 8)
  - `_modalType` : `q` (size 8)
- Properties:
  - `onDismiss` — attrs: `T@?,C,N,V_onDismiss`
  - `modalType` — attrs: `Tq,N,V_modalType`
- Instance methods (12):
  - `- 
2` — types: `@56@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16q48`
  - `- �2` — types: `v16@0:8`
  - `- +
2` — types: `v24@0:8q16`
  - `- �2` — types: `v24@0:8q16`
  - `- ��1` — types: `v16@0:8`
  - `- �2` — types: `v24@0:8@16`
  - `- 9
2` — types: `v20@0:8B16`
  - `- 2` — types: `v20@0:8B16`
  - `- 
2` — types: `@?16@0:8`
  - `- G
2` — types: `v24@0:8@?16`
  - `- U
2` — types: `q16@0:8`
  - `- ��1` — types: `v16@0:8`

#### class `CBBridgedApp`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Ivars:
  - `_bundleIdentifier` : `@"NSString"` (size 8)
  - `_view` : `@"UIView"` (size 8)
  - `_delegate` : `@"CBBridgeManager"` (size 8)
- Properties:
  - `bundleIdentifier` — attrs: `T@"NSString",C,N,V_bundleIdentifier`
  - `view` — attrs: `T@"UIView",&,N,V_view`
  - `delegate` — attrs: `T@"CBBridgeManager",W,N,V_delegate`
- Instance methods (12):
  - `- �
2` — types: `@56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24`
  - `- �1` — types: `v16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- �1` — types: `v16@0:8`
  - `- _�1` — types: `v16@0:8`
  - `- ߽1` — types: `@16@0:8`
  - `- =�1` — types: `v24@0:8@16`
  - `- ��1` — types: `@16@0:8`
  - `- 2` — types: `v24@0:8@16`
  - `- "2` — types: `@16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `v16@0:8`

#### class `CBBridgedPortalApp`
- Superclass: `CBBridgedApp`
- Ivars:
  - `_portalView` : `@"CBBridgedPortalAppView"` (size 8)
- Properties:
  - `portalView` — attrs: `T@"CBBridgedPortalAppView",&,N,V_portalView`
- Instance methods (6):
  - `- �
2` — types: `@56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24`
  - `- �1` — types: `v16@0:8`
  - `- �1` — types: `v16@0:8`
  - `- t2` — types: `@16@0:8`
  - `- 2` — types: `v24@0:8@16`
  - `- ��1` — types: `v16@0:8`

#### class `CBUIAppContainerView`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Ivars:
  - `_uiApp` : `@"CBBridgedUIApp"` (size 8)
- Properties:
  - `uiApp` — attrs: `T@"CBBridgedUIApp",W,N,V_uiApp`
- Instance methods (6):
  - `- ��1` — types: `v16@0:8`
  - `- ��1` — types: `@40@0:8{CGPoint=dd}16@32`
  - `- ��1` — types: `v32@0:8@16@24`
  - `- �2` — types: `@16@0:8`
  - `- �2` — types: `v24@0:8@16`
  - `- ��1` — types: `v16@0:8`

#### class `CBBridgedUIApp`
- Superclass: `CBBridgedApp`
- Ivars:
  - `_notchIdleTimer` : `@"NSTimer"` (size 8)
  - `_lastActivityTime` : `d` (size 8)
  - `_appView` : `@"CBBridgedUIAppView"` (size 8)
  - `_notchPill` : `@"CBSlotPillView"` (size 8)
  - `_customScale` : `d` (size 8)
- Properties:
  - `appView` — attrs: `T@"CBBridgedUIAppView",&,N,V_appView`
  - `notchPill` — attrs: `T@"CBSlotPillView",&,N,V_notchPill`
  - `customScale` — attrs: `Td,N,V_customScale`
- Instance methods (16):
  - `- �
2` — types: `@56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24`
  - `- D2` — types: `{CGSize=dd}16@0:8`
  - `- ��1` — types: `v16@0:8`
  - `- _�1` — types: `v16@0:8`
  - `- �2` — types: `v16@0:8`
  - `- 2` — types: `v16@0:8`
  - `- �1` — types: `v16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- �1` — types: `v16@0:8`
  - `- O2` — types: `@16@0:8`
  - `- W2` — types: `v24@0:8@16`
  - `- c2` — types: `@16@0:8`
  - `- m2` — types: `v24@0:8@16`
  - `- {2` — types: `d16@0:8`
  - `- �2` — types: `v24@0:8d16`
  - `- ��1` — types: `v16@0:8`

#### class `CBDividerButtonInfo`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Ivars:
  - `_iconName` : `@"NSString"` (size 8)
  - `_relativePos` : `d` (size 8)
  - `_onSwap` : `@?` (size 8)
  - `_onRotate` : `@?` (size 8)
- Properties:
  - `iconName` — attrs: `T@"NSString",C,N,V_iconName`
  - `relativePos` — attrs: `Td,N,V_relativePos`
  - `onSwap` — attrs: `T@?,C,N,V_onSwap`
  - `onRotate` — attrs: `T@?,C,N,V_onRotate`
- Instance methods (9):
  - `- 52` — types: `@16@0:8`
  - `- >2` — types: `v24@0:8@16`
  - `- K2` — types: `d16@0:8`
  - `- W2` — types: `v24@0:8d16`
  - `- g2` — types: `@?16@0:8`
  - `- n2` — types: `v24@0:8@?16`
  - `- y2` — types: `@?16@0:8`
  - `- �2` — types: `v24@0:8@?16`
  - `- ��1` — types: `v16@0:8`

#### class `CBDividerView`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Protocols nhận: `UIGestureRecognizerDelegate`
- Ivars:
  - `_isVertical` : `B` (size 1)
  - `_isBlinking` : `B` (size 1)
  - `_moveButtons` : `@"NSMutableArray"` (size 8)
  - `_buttonConfigs` : `@"NSMutableArray"` (size 8)
  - `_onPanChanged` : `@?` (size 8)
  - `_onActivity` : `@?` (size 8)
- Properties:
  - `isVertical` — attrs: `TB,N,V_isVertical`
  - `isBlinking` — attrs: `TB,N,V_isBlinking`
  - `moveButtons` — attrs: `T@"NSMutableArray",&,N,V_moveButtons`
  - `buttonConfigs` — attrs: `T@"NSMutableArray",&,N,V_buttonConfigs`
  - `onPanChanged` — attrs: `T@?,C,N,V_onPanChanged`
  - `onActivity` — attrs: `T@?,C,N,V_onActivity`
  - `hash` — attrs: `TQ,R`
  - `superclass` — attrs: `T#,R`
  - `description` — attrs: `T@"NSString",R,C`
  - `debugDescription` — attrs: `T@"NSString",R,C`
- Instance methods (27):
  - `- 
2` — types: `@52@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16B48`
  - `- 	2` — types: `B32@0:8@16@24`
  - `- 2` — types: `v24@0:8@16`
  - `- ��1` — types: `v16@0:8`
  - `- �2` — types: `v16@0:8`
  - `- w�1` — types: `B40@0:8{CGPoint=dd}16@32`
  - `- ��1` — types: `@40@0:8{CGPoint=dd}16@32`
  - `- U2` — types: `v24@0:8@16`
  - `- j2` — types: `v24@0:8@16`
  - `- }2` — types: `v24@0:8@16`
  - `- �2` — types: `v24@0:8@16`
  - `- �2` — types: `v16@0:8`
  - `- '2` — types: `v16@0:8`
  - `- 2` — types: `v24@0:8@16`
  - `- 42` — types: `B16@0:8`
  - `- ?2` — types: `v20@0:8B16`
  - `- N2` — types: `B16@0:8`
  - `- Y2` — types: `v20@0:8B16`
  - `- h2` — types: `@16@0:8`
  - `- t2` — types: `v24@0:8@16`
  - `- �2` — types: `@16@0:8`
  - `- �2` — types: `v24@0:8@16`
  - `- ` — types: `@?16@0:8`
  - `- �2` — types: `v24@0:8@?16`
  - `- �2` — types: `@?16@0:8`
  - `- �2` — types: `v24@0:8@?16`
  - `- ��1` — types: `v16@0:8`

#### class `CBSplitContainerView`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Ivars:
  - `_splitApp` : `@"CBBridgedSplitApp"` (size 8)
- Properties:
  - `splitApp` — attrs: `T@"CBBridgedSplitApp",W,N,V_splitApp`
- Instance methods (6):
  - `- ��1` — types: `v16@0:8`
  - `- ��1` — types: `@40@0:8{CGPoint=dd}16@32`
  - `- ��1` — types: `v32@0:8@16@24`
  - `- �2` — types: `@16@0:8`
  - `- �2` — types: `v24@0:8@16`
  - `- ��1` — types: `v16@0:8`

#### class `CBSlotPlaceholderView`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Ivars:
  - `_slotIndex` : `q` (size 8)
  - `_onTap` : `@?` (size 8)
  - `_iconView` : `@"UIImageView"` (size 8)
  - `_titleLabel` : `@"UILabel"` (size 8)
  - `_tapButton` : `@"UIButton"` (size 8)
- Properties:
  - `slotIndex` — attrs: `Tq,N,V_slotIndex`
  - `onTap` — attrs: `T@?,C,N,V_onTap`
  - `iconView` — attrs: `T@"UIImageView",&,N,V_iconView`
  - `titleLabel` — attrs: `T@"UILabel",&,N,V_titleLabel`
  - `tapButton` — attrs: `T@"UIButton",&,N,V_tapButton`
- Instance methods (16):
  - `- �1` — types: `@24@0:8q16`
  - `- 	�1` — types: `v16@0:8`
  - `- 2` — types: `v16@0:8`
  - `- ��1` — types: `v16@0:8`
  - `- 2` — types: `v24@0:8@16`
  - `- ��1` — types: `q16@0:8`
  - `- ��1` — types: `v24@0:8q16`
  - `- ,2` — types: `@?16@0:8`
  - `- 22` — types: `v24@0:8@?16`
  - `- ��1` — types: `@16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `@16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- <2` — types: `@16@0:8`
  - `- F2` — types: `v24@0:8@16`
  - `- ��1` — types: `v16@0:8`

#### class `CBBridgedSplitApp`
- Superclass: `CBBridgedApp`
- Ivars:
  - `_dragStartRatio` : `d` (size 8)
  - `_isBlinking` : `B` (size 1)
  - `_blinkingIdleTimer` : `@"NSTimer"` (size 8)
  - `_lastActivityTime` : `d` (size 8)
  - `_isTransitioningFocus` : `B` (size 1)
  - `_splashScreenView` : `@"CBSplitSplashScreenView"` (size 8)
  - `_appViews` : `@"NSMutableArray"` (size 8)
  - `_placeholders` : `@"NSMutableArray"` (size 8)
  - `_containers` : `@"NSMutableArray"` (size 8)
  - `_dividers` : `@"NSMutableArray"` (size 8)
  - `_slotPills` : `@"NSMutableArray"` (size 8)
  - `_splitPreset` : `q` (size 8)
  - `_splitRatio` : `d` (size 8)
  - `_focusedSlotIndex` : `q` (size 8)
- Properties:
  - `splashScreenView` — attrs: `T@"CBSplitSplashScreenView",&,N,V_splashScreenView`
  - `appViews` — attrs: `T@"NSMutableArray",&,N,V_appViews`
  - `placeholders` — attrs: `T@"NSMutableArray",&,N,V_placeholders`
  - `containers` — attrs: `T@"NSMutableArray",&,N,V_containers`
  - `dividers` — attrs: `T@"NSMutableArray",&,N,V_dividers`
  - `slotPills` — attrs: `T@"NSMutableArray",&,N,V_slotPills`
  - `splitPreset` — attrs: `Tq,N,V_splitPreset`
  - `splitRatio` — attrs: `Td,N,V_splitRatio`
  - `focusedSlotIndex` — attrs: `Tq,N,V_focusedSlotIndex`
  - `isTransitioningFocus` — attrs: `TB,N,V_isTransitioningFocus`
- Instance methods (50):
  - `- �
2` — types: `@56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24`
  - `- �2` — types: `@60@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24B56`
  - `- �2` — types: `v44@0:8{CGPoint=dd}16B32q36`
  - `- �2` — types: `v16@0:8`
  - `- �2` — types: `v28@0:8q16B24`
  - `- �2` — types: `v20@0:8B16`
  - `- �2` — types: `v24@0:8q16`
  - `- �2` — types: `v16@0:8`
  - `- 2` — types: `v16@0:8`
  - `- �2` — types: `v32@0:8d16q24`
  - `- �2` — types: `v32@0:8q16q24`
  - `- �2` — types: `v24@0:8q16`
  - `- T�1` — types: `v32@0:8q16q24`
  - `- 2` — types: `v24@0:8@16`
  - `- g�1` — types: `v32@0:8q16@24`
  - `- Q2` — types: `v24@0:8q16`
  - `- 2` — types: `v24@0:8@16`
  - `- /2` — types: `v24@0:8@16`
  - `- ^2` — types: `v24@0:8q16`
  - `- N2` — types: `v16@0:8`
  - `- �2` — types: `v16@0:8`
  - `- �1` — types: `v16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- �1` — types: `v16@0:8`
  - `- _�1` — types: `v16@0:8`
  - `- Z2` — types: `v16@0:8`
  - `- i2` — types: `v16@0:8`
  - `- }2` — types: `v24@0:8@16`
  - `- �2` — types: `v24@0:8@16`
  - `- \2` — types: `@16@0:8`
  - `- E2` — types: `v24@0:8@16`
  - `- �2` — types: `@16@0:8`
  - `- m2` — types: `v24@0:8@16`
  - `- z2` — types: `@16@0:8`
  - `- �2` — types: `v24@0:8@16`
  - `- 12` — types: `@16@0:8`
  - `- �2` — types: `v24@0:8@16`
  - `- <2` — types: `@16@0:8`
  - `- �2` — types: `v24@0:8@16`
  - `- �2` — types: `@16@0:8`
  - `- �2` — types: `v24@0:8@16`
  - `- ��1` — types: `q16@0:8`
  - `- ��1` — types: `v24@0:8q16`
  - `- ��1` — types: `d16@0:8`
  - `- ��1` — types: `v24@0:8d16`
  - `- �2` — types: `q16@0:8`
  - `- �2` — types: `v24@0:8q16`
  - `- �2` — types: `B16@0:8`
  - `- 2` — types: `v20@0:8B16`
  - `- ��1` — types: `v16@0:8`

#### class `CBVoiceSpeechResponse`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Ivars:
  - `_audioStreamFollowing` : `B` (size 1)
  - `_text` : `@"NSString"` (size 8)
- Properties:
  - `text` — attrs: `T@"NSString",C,N,V_text`
  - `audioStreamFollowing` — attrs: `TB,N,V_audioStreamFollowing`
- Instance methods (5):
  - `- ��1` — types: `@16@0:8`
  - `- 1�1` — types: `v24@0:8@16`
  - `- �2` — types: `B16@0:8`
  - `- �2` — types: `v20@0:8B16`
  - `- ��1` — types: `v16@0:8`
- Class methods (1):
  - `+ �2` — types: `@24@0:8@16`

#### class `CBVoiceDirective`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Ivars:
  - `_expectFollowUp` : `B` (size 1)
  - `_domain` : `@"NSString"` (size 8)
  - `_action` : `@"NSString"` (size 8)
  - `_category` : `@"NSString"` (size 8)
  - `_appInfo` : `@"NSDictionary"` (size 8)
  - `_rawParams` : `@"NSDictionary"` (size 8)
  - `_speech` : `@"CBVoiceSpeechResponse"` (size 8)
  - `_timeoutSec` : `q` (size 8)
  - `_executionTiming` : `@"NSString"` (size 8)
- Properties:
  - `domain` — attrs: `T@"NSString",C,N,V_domain`
  - `action` — attrs: `T@"NSString",C,N,V_action`
  - `category` — attrs: `T@"NSString",C,N,V_category`
  - `appInfo` — attrs: `T@"NSDictionary",&,N,V_appInfo`
  - `rawParams` — attrs: `T@"NSDictionary",&,N,V_rawParams`
  - `speech` — attrs: `T@"CBVoiceSpeechResponse",&,N,V_speech`
  - `expectFollowUp` — attrs: `TB,N,V_expectFollowUp`
  - `timeoutSec` — attrs: `Tq,N,V_timeoutSec`
  - `executionTiming` — attrs: `T@"NSString",C,N,V_executionTiming`
  - `parameters` — attrs: `T@"NSDictionary",R,N`
  - `resolvedBundleID` — attrs: `T@"NSString",R,C,N`
  - `resolvedLaunchURL` — attrs: `T@"NSString",R,C,N`
  - `resolvedTargetSlot` — attrs: `Tq,R,N`
  - `shouldExecuteImmediately` — attrs: `TB,R,N`
- Instance methods (24):
  - `- +2` — types: `@16@0:8`
  - `- <2` — types: `@16@0:8`
  - `- N2` — types: `q16@0:8`
  - `- a2` — types: `@16@0:8`
  - `- l2` — types: `B16@0:8`
  - `- 2` — types: `@16@0:8`
  - `- �2` — types: `v24@0:8@16`
  - `- 2` — types: `@16@0:8`
  - `- �2` — types: `v24@0:8@16`
  - `- v2` — types: `@16@0:8`
  - `- �2` — types: `v24@0:8@16`
  - `- 2` — types: `@16@0:8`
  - `- �2` — types: `v24@0:8@16`
  - `- \2` — types: `@16@0:8`
  - `- �2` — types: `v24@0:8@16`
  - `- �2` — types: `@16@0:8`
  - `- �2` — types: `v24@0:8@16`
  - `- �2` — types: `B16@0:8`
  - `- �2` — types: `v20@0:8B16`
  - `- �2` — types: `q16@0:8`
  - `- �2` — types: `v24@0:8q16`
  - `- f2` — types: `@16@0:8`
  - `- �2` — types: `v24@0:8@16`
  - `- ��1` — types: `v16@0:8`
- Class methods (1):
  - `+ 2` — types: `@24@0:8@16`

#### class `CBVoiceInstalledApp`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Ivars:
  - `_bundleID` : `@"NSString"` (size 8)
  - `_name` : `@"NSString"` (size 8)
  - `_aliases` : `@"NSArray"` (size 8)
  - `_urlScheme` : `@"NSString"` (size 8)
- Properties:
  - `bundleID` — attrs: `T@"NSString",C,N,V_bundleID`
  - `name` — attrs: `T@"NSString",C,N,V_name`
  - `aliases` — attrs: `T@"NSArray",&,N,V_aliases`
  - `urlScheme` — attrs: `T@"NSString",C,N,V_urlScheme`
- Instance methods (10):
  - `- �2` — types: `@16@0:8`
  - `- j2` — types: `@16@0:8`
  - `- :2` — types: `v24@0:8@16`
  - `- ]�1` — types: `@16@0:8`
  - `- G2` — types: `v24@0:8@16`
  - `- s2` — types: `@16@0:8`
  - `- P2` — types: `v24@0:8@16`
  - `- {2` — types: `@16@0:8`
  - `- \2` — types: `v24@0:8@16`
  - `- ��1` — types: `v16@0:8`
- Class methods (1):
  - `+ �2` — types: `@48@0:8@16@24@32@40`

#### class `CBVoiceContext`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Ivars:
  - `_hwHash` : `@"NSString"` (size 8)
  - `_carModel` : `@"NSString"` (size 8)
  - `_lang` : `@"NSString"` (size 8)
  - `_defaultMusicApp` : `@"NSString"` (size 8)
  - `_installedApps` : `@"NSArray"` (size 8)
- Properties:
  - `hwHash` — attrs: `T@"NSString",C,N,V_hwHash`
  - `carModel` — attrs: `T@"NSString",C,N,V_carModel`
  - `lang` — attrs: `T@"NSString",C,N,V_lang`
  - `defaultMusicApp` — attrs: `T@"NSString",C,N,V_defaultMusicApp`
  - `installedApps` — attrs: `T@"NSArray",&,N,V_installedApps`
- Instance methods (12):
  - `- 62` — types: `@16@0:8`
  - `- 2` — types: `@16@0:8`
  - `- I2` — types: `v24@0:8@16`
  - `- 2` — types: `@16@0:8`
  - `- T2` — types: `v24@0:8@16`
  - `- �2` — types: `@16@0:8`
  - `- �2` — types: `v24@0:8@16`
  - `- 2` — types: `@16@0:8`
  - `- a2` — types: `v24@0:8@16`
  - `- �2` — types: `@16@0:8`
  - `- �2` — types: `v24@0:8@16`
  - `- ��1` — types: `v16@0:8`
- Class methods (2):
  - `+ u2` — types: `@16@0:8`
  - `+ '2` — types: `@16@0:8`

#### class `CBVoiceAudioCapture`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Ivars:
  - `_audioEngine` : `@"AVAudioEngine"` (size 8)
  - `_activeStrategy` : `@"<CBVoiceSTTStrategy>"` (size 8)
  - `_isRecording` : `B` (size 1)
  - `_delegate` : `@"<CBVoiceAudioCaptureDelegate>"` (size 8)
  - `_mode` : `q` (size 8)
- Properties:
  - `isRecording` — attrs: `TB,V_isRecording`
  - `delegate` — attrs: `T@"<CBVoiceAudioCaptureDelegate>",W,N,V_delegate`
  - `mode` — attrs: `Tq,N,V_mode`
- Instance methods (11):
  - `- P�1` — types: `@16@0:8`
  - `- 	�1` — types: `v16@0:8`
  - `- �!2` — types: `B24@0:8^@16`
  - `-  2` — types: `v16@0:8`
  - `- "2` — types: `@16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- � 2` — types: `q16@0:8`
  - `- �!2` — types: `v24@0:8q16`
  - `-  2` — types: `B16@0:8`
  - `- �!2` — types: `v20@0:8B16`
  - `- ��1` — types: `v16@0:8`
- Class methods (1):
  - `+ +�1` — types: `@16@0:8`

#### class `CBVoiceSTTAppleOnDeviceProvider`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Protocols nhận: `CBVoiceSTTStrategy`
- Ivars:
  - `_ctx` : `{?="recognizer"^v"request"^v"task"^v}` (size 24)
  - `_silenceTimer` : `@"NSObject<OS_dispatch_source>"` (size 8)
  - `_currentTranscript` : `@"NSString"` (size 8)
  - `_isSessionActive` : `B` (size 1)
  - `_audioConverter` : `@"AVAudioConverter"` (size 8)
  - `_targetFormat` : `@"AVAudioFormat"` (size 8)
  - `_delegate` : `@"<CBVoiceAudioCaptureDelegate>"` (size 8)
- Properties:
  - `delegate` — attrs: `T@"<CBVoiceAudioCaptureDelegate>",W,N,V_delegate`
  - `hash` — attrs: `TQ,R`
  - `superclass` — attrs: `T#,R`
  - `description` — attrs: `T@"NSString",R,C`
  - `debugDescription` — attrs: `T@"NSString",R,C`
- Instance methods (9):
  - `- 	�1` — types: `v16@0:8`
  - `- k#2` — types: `v24@0:8d16`
  - `- e"2` — types: `v16@0:8`
  - `- ` — types: `B32@0:8@16^@24`
  - `- #!2` — types: `v24@0:8@16`
  - `- }!2` — types: `v16@0:8`
  - `- "2` — types: `@16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `v16@0:8`

#### class `CBVoiceSTTCloudStreamingProvider`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Protocols nhận: `CBVoiceSTTStrategy`
- Ivars:
  - `_targetFormat` : `@"AVAudioFormat"` (size 8)
  - `_converter` : `@"AVAudioConverter"` (size 8)
  - `_isSessionActive` : `B` (size 1)
  - `_delegate` : `@"<CBVoiceAudioCaptureDelegate>"` (size 8)
- Properties:
  - `delegate` — attrs: `T@"<CBVoiceAudioCaptureDelegate>",W,N,V_delegate`
  - `hash` — attrs: `TQ,R`
  - `superclass` — attrs: `T#,R`
  - `description` — attrs: `T@"NSString",R,C`
  - `debugDescription` — attrs: `T@"NSString",R,C`
- Instance methods (8):
  - `- P�1` — types: `@16@0:8`
  - `- 	�1` — types: `v16@0:8`
  - `- ` — types: `B32@0:8@16^@24`
  - `- #!2` — types: `v24@0:8@16`
  - `- }!2` — types: `v16@0:8`
  - `- "2` — types: `@16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- ��1` — types: `v16@0:8`

#### class `CBVoiceAudioPlayer`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Protocols nhận: `AVAudioPlayerDelegate`
- Ivars:
  - `_audioBuffer` : `@"NSMutableData"` (size 8)
  - `_audioPlayer` : `@"AVAudioPlayer"` (size 8)
  - `_chimePlayer` : `@"AVAudioPlayer"` (size 8)
  - `_playCompletion` : `@?` (size 8)
  - `_chimeCompletion` : `@?` (size 8)
  - `_isPlaying` : `B` (size 1)
- Properties:
  - `isPlaying` — attrs: `TB,N,V_isPlaying`
  - `bufferedBytesCount` — attrs: `TQ,R,N`
  - `hash` — attrs: `TQ,R`
  - `superclass` — attrs: `T#,R`
  - `description` — attrs: `T@"NSString",R,C`
  - `debugDescription` — attrs: `T@"NSString",R,C`
- Instance methods (16):
  - `- P�1` — types: `@16@0:8`
  - `- %2` — types: `v16@0:8`
  - `- �&2` — types: `Q16@0:8`
  - `- �&2` — types: `v24@0:8@16`
  - `- �!2` — types: `v16@0:8`
  - `- =%2` — types: `v20@0:8B16`
  - `- �&2` — types: `v16@0:8`
  - `- �%2` — types: `v24@0:8@?16`
  - `- �&2` — types: `v16@0:8`
  - `- �&2` — types: `v24@0:8@?16`
  - `- '2` — types: `v24@0:8@?16`
  - `- �%2` — types: `v28@0:8@16B24`
  - `- �%2` — types: `v32@0:8@16@24`
  - `- o%2` — types: `B16@0:8`
  - `- �%2` — types: `v20@0:8B16`
  - `- ��1` — types: `v16@0:8`
- Class methods (1):
  - `+ +�1` — types: `@16@0:8`

#### class `CBVoiceTransport`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Protocols nhận: `NSURLSessionWebSocketDelegate`
- Ivars:
  - `_urlSession` : `@"NSURLSession"` (size 8)
  - `_webSocketTask` : `@"NSURLSessionWebSocketTask"` (size 8)
  - `_sendQueue` : `@"NSObject<OS_dispatch_queue>"` (size 8)
  - `_workQueue` : `@"NSOperationQueue"` (size 8)
  - `_sessionKey` : `@"NSMutableData"` (size 8)
  - `_sessionGeneration` : `Q` (size 8)
  - `_pendingPCMChunksCount` : `q` (size 8)
  - `_pendingConnectCompletion` : `@?` (size 8)
  - `_pendingContext` : `@"CBVoiceContext"` (size 8)
  - `_isConnected` : `B` (size 1)
  - `_delegate` : `@"<CBVoiceTransportDelegate>"` (size 8)
- Properties:
  - `isConnected` — attrs: `TB,N,V_isConnected`
  - `delegate` — attrs: `T@"<CBVoiceTransportDelegate>",W,N,V_delegate`
  - `hash` — attrs: `TQ,R`
  - `superclass` — attrs: `T#,R`
  - `description` — attrs: `T@"NSString",R,C`
  - `debugDescription` — attrs: `T@"NSString",R,C`
- Instance methods (17):
  - `- �'2` — types: `v16@0:8`
  - `- 	�1` — types: `v16@0:8`
  - `- P�1` — types: `@16@0:8`
  - `- --2` — types: `v32@0:8@16@?24`
  - `- �(2` — types: `v40@0:8@16@24Q32`
  - `- L-2` — types: `v24@0:8@16`
  - `- Z-2` — types: `v24@0:8@16`
  - `- o-2` — types: `v16@0:8`
  - `- 1$2` — types: `v16@0:8`
  - `- �(2` — types: `v24@0:8q16`
  - `- �,2` — types: `v40@0:8@16@24@32`
  - `- �,2` — types: `v48@0:8@16@24q32@40`
  - `- "2` — types: `@16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- �'2` — types: `B16@0:8`
  - `- (2` — types: `v20@0:8B16`
  - `- ��1` — types: `v16@0:8`
- Class methods (2):
  - `+ +�1` — types: `@16@0:8`
  - `+ o*2` — types: `v24@0:8@16`

#### class `CBVoiceSceneDispatcher`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Instance methods (3):
  - `- �.2` — types: `v48@0:8@16@24q32@?40`
  - `- a.2` — types: `v56@0:8@16@24q32@40@?48`
  - `- �.2` — types: `v24@0:8@16`
- Class methods (1):
  - `+ +�1` — types: `@16@0:8`

#### class `CBVoiceDirectiveDispatcher`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Ivars:
  - `_handlers` : `@"NSMutableArray"` (size 8)
- Instance methods (6):
  - `- P�1` — types: `@16@0:8`
  - `- 8/2` — types: `v24@0:8@16`
  - `- �/2` — types: `@24@0:8@16`
  - `- �/2` — types: `B24@0:8@16`
  - `- �/2` — types: `v32@0:8@16@?24`
  - `- ��1` — types: `v16@0:8`
- Class methods (1):
  - `+ +�1` — types: `@16@0:8`

#### class `CBAppLaunchDirectiveHandler`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Protocols nhận: `CBVoiceDirectiveHandler`
- Properties:
  - `hash` — attrs: `TQ,R`
  - `superclass` — attrs: `T#,R`
  - `description` — attrs: `T@"NSString",R,C`
  - `debugDescription` — attrs: `T@"NSString",R,C`
- Instance methods (3):
  - `- I/2` — types: `B24@0:8@16`
  - `- ]/2` — types: `B32@0:8@16@24`
  - `- �/2` — types: `v32@0:8@16@?24`

#### class `CBVoiceSessionManager`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Protocols nhận: `CBVoiceTransportDelegate`, `CBVoiceAudioCaptureDelegate`, `CBVoiceTriggerDelegate`
- Ivars:
  - `_speechTimeoutTimer` : `@"NSTimer"` (size 8)
  - `_thinkingTimeoutTimer` : `@"NSTimer"` (size 8)
  - `_expectFollowUp` : `B` (size 1)
  - `_followUpTimeoutSec` : `q` (size 8)
  - `_turnCount` : `Q` (size 8)
  - `_pcmChunksSent` : `AQ` (size 8)
  - `_warmupChunksToDrop` : `AQ` (size 8)
  - `_pendingDirective` : `@"CBVoiceDirective"` (size 8)
  - `_wasMediaPlayingBeforeSession` : `B` (size 1)
  - `_latestTranscript` : `@"NSString"` (size 8)
  - `_lastToggleTime` : `d` (size 8)
  - `_mediaResumeToken` : `Q` (size 8)
  - `_sessionGenerationToken` : `Q` (size 8)
  - `_stateDelegate` : `@"<CBVoiceSessionStateDelegate>"` (size 8)
  - `_state` : `q` (size 8)
- Properties:
  - `state` — attrs: `Tq,N,V_state`
  - `stateDelegate` — attrs: `T@"<CBVoiceSessionStateDelegate>",W,N,V_stateDelegate`
  - `isActive` — attrs: `TB,R,N`
  - `hash` — attrs: `TQ,R`
  - `superclass` — attrs: `T#,R`
  - `description` — attrs: `T@"NSString",R,C`
  - `debugDescription` — attrs: `T@"NSString",R,C`
- Instance methods (33):
  - `- P�1` — types: `@16@0:8`
  - `- 	�1` — types: `v16@0:8`
  - `- 02` — types: `v24@0:8@16`
  - `- �/2` — types: `v24@0:8@16`
  - `- �12` — types: `B16@0:8`
  - `- q02` — types: `v24@0:8q16`
  - `- ��1` — types: `v16@0:8`
  - `- d02` — types: `v16@0:8`
  - `- �02` — types: `v16@0:8`
  - `- �02` — types: `v16@0:8`
  - `- �02` — types: `v24@0:8d16`
  - `- �02` — types: `v16@0:8`
  - `- �02` — types: `v16@0:8`
  - `- H02` — types: `v16@0:8`
  - `- �02` — types: `v16@0:8`
  - `- {02` — types: `v16@0:8`
  - `- 212` — types: `v16@0:8`
  - `- N12` — types: `v16@0:8`
  - `- i12` — types: `v16@0:8`
  - `- �$2` — types: `v24@0:8@16`
  - `- x"2` — types: `v28@0:8@16B24`
  - `- 12` — types: `v24@0:8@16`
  - `- V*2` — types: `v16@0:8`
  - `- #)2` — types: `v24@0:8@16`
  - `- �)2` — types: `v24@0:8@16`
  - `- F)2` — types: `v28@0:8B16q20`
  - `- 6*2` — types: `v24@0:8q16`
  - `- �(2` — types: `v24@0:8@16`
  - `- �)2` — types: `v24@0:8@16`
  - `- V02` — types: `@16@0:8`
  - `- �1` — types: `v24@0:8@16`
  - `- 1�1` — types: `q16@0:8`
  - `- ��1` — types: `v16@0:8`
- Class methods (1):
  - `+ +�1` — types: `@16@0:8`

#### class `CBBridgeRequest`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Ivars:
  - `_activate` : `B` (size 1)
  - `_bundleIdentifier` : `@"NSString"` (size 8)
- Properties:
  - `bundleIdentifier` — attrs: `T@"NSString",C,N,V_bundleIdentifier`
  - `activate` — attrs: `TB,N,V_activate`
- Instance methods (6):
  - `- �.2` — types: `@24@0:8@16`
  - `- ߽1` — types: `@16@0:8`
  - `- =�1` — types: `v24@0:8@16`
  - `- 32` — types: `B16@0:8`
  - `- 32` — types: `v20@0:8B16`
  - `- ��1` — types: `v16@0:8`

#### class `CBDashboardShared`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Class methods (12):
  - `+ �32` — types: `v24@0:8@16`
  - `+ �32` — types: `@16@0:8`
  - `+ �32` — types: `v24@0:8@16`
  - `+ �32` — types: `@16@0:8`
  - `+ �32` — types: `v24@0:8@16`
  - `+ 42` — types: `@16@0:8`
  - `+ ��1` — types: `@16@0:8`
  - `+ S32` — types: `@16@0:8`
  - `+ ]32` — types: `@16@0:8`
  - `+ w32` — types: `@16@0:8`
  - `+ ~32` — types: `@16@0:8`
  - `+ /42` — types: `@16@0:8`

#### class `CBBridgeManager`
- Superclass: không resolve được từ metadata trong file (class cha nằm ngoài binary — dạng bind)
- Ivars:
  - `_activated` : `B` (size 1)
  - `_isAutoResuming` : `B` (size 1)
  - `_autoResumeRetryCount` : `q` (size 8)
  - `_isApplyingSplitMode` : `B` (size 1)
  - `_sessionBridgedBundleIDs` : `@"NSMutableSet"` (size 8)
  - `_disconnectWatchdogToken` : `Q` (size 8)
  - `_autoResumeBundleID` : `@"NSString"` (size 8)
  - `_bundleIdentifier` : `@"NSString"` (size 8)
  - `_window` : `@"CBWindow"` (size 8)
  - `_currentApp` : `@"CBBridgedApp"` (size 8)
  - `_licenseWarningModal` : `@"CBLicenseWarningModalView"` (size 8)
  - `_licenseWatchdogTimer` : `@"NSTimer"` (size 8)
  - `_appFrame` : `{CGRect="origin"{CGPoint="x"d"y"d}"size"{CGSize="width"d"height"d}}` (size 32)
  - `_renderSize` : `{CGSize="width"d"height"d}` (size 16)
- Properties:
  - `window` — attrs: `T@"CBWindow",&,N,V_window`
  - `currentApp` — attrs: `T@"CBBridgedApp",&,N,V_currentApp`
  - `licenseWarningModal` — attrs: `T@"CBLicenseWarningModalView",&,N,V_licenseWarningModal`
  - `bundleIdentifier` — attrs: `T@"NSString",C,N,V_bundleIdentifier`
  - `activated` — attrs: `TB,N,V_activated`
  - `appFrame` — attrs: `T{CGRect={CGPoint=dd}{CGSize=dd}},N,V_appFrame`
  - `renderSize` — attrs: `T{CGSize=dd},N,V_renderSize`
  - `autoResumeBundleID` — attrs: `T@"NSString",C,N,V_autoResumeBundleID`
- Instance methods (73):
  - `- �52` — types: `v24@0:8@16`
  - `- R�1` — types: `@16@0:8`
  - `- �:2` — types: `{CGSize=dd}24@0:8@16`
  - `- t<2` — types: `B32@0:8q16@24`
  - `- �<2` — types: `v40@0:8@16@24d32`
  - `- j�1` — types: `v40@0:8q16@24d32`
  - `- ^<2` — types: `v16@0:8`
  - `- ��1` — types: `v24@0:8q16`
  - `- ��1` — types: `v16@0:8`
  - `- �2` — types: `v32@0:8d16q24`
  - `- ��1` — types: `v16@0:8`
  - `- �42` — types: `v16@0:8`
  - `- �:2` — types: `v24@0:8@16`
  - `- �:2` — types: `v24@0:8@16`
  - `- �2` — types: `v28@0:8@16B24`
  - `- o2` — types: `v16@0:8`
  - `- �42` — types: `v16@0:8`
  - `- �42` — types: `v16@0:8`
  - `- ~:2` — types: `v24@0:8@16`
  - `- D�1` — types: `B16@0:8`
  - `- �;2` — types: `B24@0:8@16`
  - `- r;2` — types: `B24@0:8@16`
  - `- 8:2` — types: `v24@0:8@16`
  - `- a:2` — types: `v24@0:8@16`
  - `- x52` — types: `v16@0:8`
  - `- �2` — types: `v32@0:8@16@?24`
  - `- x92` — types: `v16@0:8`
  - `- �92` — types: `v16@0:8`
  - `- �92` — types: `v16@0:8`
  - `- ��1` — types: `v24@0:8@16`
  - `- a�1` — types: `v24@0:8@16`
  - `- ��1` — types: `v16@0:8`
  - `- �42` — types: `@16@0:8`
  - `- U52` — types: `v24@0:8@16`
  - `- 942` — types: `v16@0:8`
  - `- [92` — types: `v16@0:8`
