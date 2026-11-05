# HỒ SƠ TẬN GỐC — OmniCar 1.0.3 (`com.anlai.omnicar`)

> Hồ sơ phân tích tĩnh **chỉ-đọc** (static analysis) gói deb gốc, lập ngày 05/11/2026.
> Phương pháp: bóc gói bằng `dpkg-deb -x/-e`; parse Mach-O/ObjC metadata bằng parser tự viết trên slice arm64; giải mã dyld chained-fixups imports; trích xuất call-site `MSHookMessageEx`/`MSHookFunction`/`notify_*` bằng trình theo dõi thanh ghi (register tracking) trên disassembly của các hàm constructor (`__init_offsets`), đối chiếu đọc tay ở các điểm chưa rõ.
> **Không** chạy/kích hoạt bất kỳ binary, dylib hay script nào của gói. Mọi khẳng định đều gắn mức bằng chứng; phần không chốt được nằm ở mục 7 "CHƯA XÁC ĐỊNH ĐƯỢC".
> Bảng class/method/property/ivar, selector refs và CFString constants được trích **toàn bộ** từ metadata của slice arm64. Slice arm64e có cùng danh sách thư viện liên kết, cùng entitlements và cùng số import (đã kiểm chứng) nên không lặp lại bảng; chỉ UUID khác.

---

## 1. Định danh gói

| Mục | Giá trị |
|---|---|
| Tên file | `omnicar.deb` |
| Kích thước | 1.306.228 bytes |
| SHA256 của deb | `d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd` (khớp SHA đã công bố của repo `chuongnguyen89dn-ui/Omnicar` @ `bafc2441`) |
| Định dạng | Debian package version 2.0; control archive 1.141 bytes; data archive chứa cây `var/jb/...` (rootless) |

### 1.1. Toàn bộ file `control`

```
Package: com.anlai.omnicar
Name: OmniCar
Description: The power of CarPlay.
 OmniCar takes CarPlay beyond what Apple allows: more freedom, more features and everything you need on the road, in one package.
 .
 APP BRIDGE
  - iPhone apps without CarPlay, such as YouTube or TikTok, on the car screen
  - In a Split Screen pane or full screen, resized live
  - Built in: no CarBridge needed
 .
 SPEED BUBBLE
  - Current speed and the posted limit from Vietmap Live, GOFA, Waze or Wyn
  - On the CarPlay screen, or on the iPhone when no car is connected
  - 9 styles; drag, pinch to resize, tap to reopen the app
  - Over-speed warning with light effects and sound
 .
 STARTUP SCREEN
  - Your own video every time CarPlay connects
  - Clips from Photos or Files, duration, Fill or Fit
  - Sound through the car speakers, tap to skip
 .
 SPLIT SCREEN
  - Two or three CarPlay apps side by side, each with its real interface
  - Layouts: 2 panes, 3 panes or 1 large + 2
  - Drag the divider to resize, swap panes, floating window
  - Three favorite layouts; the last split reopens on connect
  - Siri and Shortcuts through the omnicar:// URL scheme
 .
 SETTINGS
  - Every feature has its own switch and page under Settings > OmniCar
  - Changes apply the next time CarPlay connects
  - Respring once after installing
 .
 COMPATIBILITY
  - iOS 15 and 16
  - Rootless jailbreaks: Dopamine, palera1n
Icon: file:///var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/PackageIcon.png
Maintainer: OmniCar <omnicartweak@gmail.com>
Author: OmniCar <omnicartweak@gmail.com>
Section: Tweaks
Depends: mobilesubstrate (>= 0.9.5000), preferenceloader, firmware (>= 15.0)
Conflicts: carsplash-rootless, carspeed, com.anlai97.speedpop, com.anlai97.carduo, com.anpham.splitcarplay
Replaces: carsplash-rootless, carspeed, com.anlai97.speedpop, com.anlai97.carduo, com.anpham.splitcarplay
Architecture: iphoneos-arm64
Version: 1.0.3
Installed-Size: 6160
```

### 1.2. Maintainer scripts

Control archive **chỉ chứa đúng một file `control`** (1.932 bytes, 46 dòng — theo `dpkg-deb -I`). **Không có** `preinst`, `postinst`, `prerm`, `postrm`, `config` hay `templates`. Gói không tự chạy script nào khi cài/gỡ; mọi hành vi nằm trong các dylib và app.

### 1.3. Nhận xét nhanh về `Depends`/`Conflicts`

- `Depends: mobilesubstrate (>= 0.9.5000), preferenceloader, firmware (>= 15.0)`.
- `Conflicts` + `Replaces`: `carsplash-rootless`, `carspeed`, `com.anlai97.speedpop`, `com.anlai97.carduo`, `com.anpham.splitcarplay` — các tweak CarPlay/tốc độ đời trước của cùng hệ tác giả, bị thay thế bắt buộc.

---

## 2. Cây file đầy đủ (176 file, 0 symlink)

Đường dẫn tính từ gốc hệ thống sau khi cài (gói rootless, tiền tố `/var/jb` đã nằm sẵn trong cây). Không có symlink nào trong gói (đã kiểm `find -type l` = 0).

| # | Đường dẫn | Kích thước (bytes) |
|---|---|---|
| 1 | `var/jb/Applications/OmniCar.app/AppIcon60x60@2x.png` | 24,659 |
| 2 | `var/jb/Applications/OmniCar.app/AppIcon60x60@3x.png` | 44,470 |
| 3 | `var/jb/Applications/OmniCar.app/Info.plist` | 897 |
| 4 | `var/jb/Applications/OmniCar.app/OmniCar` | 168,880 |
| 5 | `var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarAppBridge.dylib` | 613,376 |
| 6 | `var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarAppBridge.plist` | 87 |
| 7 | `var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarCarProbe.dylib` | 242,784 |
| 8 | `var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarCarProbe.plist` | 92 |
| 9 | `var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarCore.dylib` | 276,832 |
| 10 | `var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarCore.plist` | 93 |
| 11 | `var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarSpeedBubble.dylib` | 649,808 |
| 12 | `var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarSpeedBubble.plist` | 194 |
| 13 | `var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarSplitScreen.dylib` | 1,229,920 |
| 14 | `var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarSplitScreen.plist` | 118 |
| 15 | `var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarStartupScreen.dylib` | 567,792 |
| 16 | `var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarStartupScreen.plist` | 118 |
| 17 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/FeatureSpeedBubble.plist` | 438 |
| 18 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/FeatureSplitScreen.plist` | 453 |
| 19 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/FeatureStartupScreen.plist` | 4,055 |
| 20 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/Info.plist` | 402 |
| 21 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/OmniCarPrefs` | 1,303,344 |
| 22 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/PackageIcon.png` | 74,767 |
| 23 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/Root.plist` | 1,033 |
| 24 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/SpeedBubbleIcon.png` | 2,092 |
| 25 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/SpeedBubbleIcon@2x.png` | 4,963 |
| 26 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/SpeedBubbleIcon@3x.png` | 7,688 |
| 27 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/StartupScreenIcon.png` | 1,567 |
| 28 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/StartupScreenIcon@2x.png` | 3,150 |
| 29 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/StartupScreenIcon@3x.png` | 4,912 |
| 30 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/WhatsNew.plist` | 334 |
| 31 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ar.lproj/AppBridge.strings` | 663 |
| 32 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ar.lproj/Car.strings` | 5,582 |
| 33 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ar.lproj/HomeScreen.strings` | 3,835 |
| 34 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ar.lproj/Localizable.strings` | 15,237 |
| 35 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ar.lproj/Onboarding.strings` | 2,515 |
| 36 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ar.lproj/Profiles.strings` | 893 |
| 37 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ar.lproj/SpeedBubble.strings` | 5,182 |
| 38 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ar.lproj/SplitScreen.strings` | 4,587 |
| 39 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ar.lproj/StartupScreen.strings` | 4,995 |
| 40 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ar.lproj/WhatsNew.strings` | 1,120 |
| 41 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/de.lproj/AppBridge.strings` | 553 |
| 42 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/de.lproj/Car.strings` | 5,723 |
| 43 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/de.lproj/HomeScreen.strings` | 3,970 |
| 44 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/de.lproj/Localizable.strings` | 15,344 |
| 45 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/de.lproj/Onboarding.strings` | 2,799 |
| 46 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/de.lproj/Profiles.strings` | 920 |
| 47 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/de.lproj/SpeedBubble.strings` | 5,070 |
| 48 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/de.lproj/SplitScreen.strings` | 4,509 |
| 49 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/de.lproj/StartupScreen.strings` | 4,975 |
| 50 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/de.lproj/WhatsNew.strings` | 1,156 |
| 51 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/en.lproj/AppBridge.strings` | 462 |
| 52 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/en.lproj/Car.strings` | 3,245 |
| 53 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/en.lproj/HomeScreen.strings` | 2,609 |
| 54 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/en.lproj/Localizable.strings` | 10,556 |
| 55 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/en.lproj/Onboarding.strings` | 2,063 |
| 56 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/en.lproj/Profiles.strings` | 594 |
| 57 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/en.lproj/SpeedBubble.strings` | 4,134 |
| 58 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/en.lproj/SplitScreen.strings` | 3,741 |
| 59 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/en.lproj/StartupScreen.strings` | 5,452 |
| 60 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/en.lproj/WhatsNew.strings` | 834 |
| 61 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/es.lproj/AppBridge.strings` | 503 |
| 62 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/es.lproj/Car.strings` | 5,259 |
| 63 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/es.lproj/HomeScreen.strings` | 3,885 |
| 64 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/es.lproj/Localizable.strings` | 15,568 |
| 65 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/es.lproj/Onboarding.strings` | 2,903 |
| 66 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/es.lproj/Profiles.strings` | 959 |
| 67 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/es.lproj/SpeedBubble.strings` | 5,369 |
| 68 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/es.lproj/SplitScreen.strings` | 4,465 |
| 69 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/es.lproj/StartupScreen.strings` | 5,225 |
| 70 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/es.lproj/WhatsNew.strings` | 1,150 |
| 71 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/fr.lproj/AppBridge.strings` | 691 |
| 72 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/fr.lproj/Car.strings` | 6,013 |
| 73 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/fr.lproj/HomeScreen.strings` | 4,434 |
| 74 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/fr.lproj/Localizable.strings` | 16,972 |
| 75 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/fr.lproj/Onboarding.strings` | 3,076 |
| 76 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/fr.lproj/Profiles.strings` | 1,046 |
| 77 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/fr.lproj/SpeedBubble.strings` | 5,494 |
| 78 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/fr.lproj/SplitScreen.strings` | 4,797 |
| 79 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/fr.lproj/StartupScreen.strings` | 5,611 |
| 80 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/fr.lproj/WhatsNew.strings` | 1,408 |
| 81 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/icon.png` | 2,481 |
| 82 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/icon@2x.png` | 7,968 |
| 83 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/icon@3x.png` | 14,988 |
| 84 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/id.lproj/AppBridge.strings` | 478 |
| 85 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/id.lproj/Car.strings` | 4,438 |
| 86 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/id.lproj/HomeScreen.strings` | 2,826 |
| 87 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/id.lproj/Localizable.strings` | 11,228 |
| 88 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/id.lproj/Onboarding.strings` | 2,213 |
| 89 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/id.lproj/Profiles.strings` | 697 |
| 90 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/id.lproj/SpeedBubble.strings` | 4,273 |
| 91 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/id.lproj/SplitScreen.strings` | 3,929 |
| 92 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/id.lproj/StartupScreen.strings` | 3,885 |
| 93 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/id.lproj/WhatsNew.strings` | 846 |
| 94 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/it.lproj/AppBridge.strings` | 500 |
| 95 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/it.lproj/Car.strings` | 5,370 |
| 96 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/it.lproj/HomeScreen.strings` | 3,588 |
| 97 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/it.lproj/Localizable.strings` | 13,854 |
| 98 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/it.lproj/Onboarding.strings` | 2,726 |
| 99 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/it.lproj/Profiles.strings` | 881 |
| 100 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/it.lproj/SpeedBubble.strings` | 4,910 |
| 101 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/it.lproj/SplitScreen.strings` | 4,115 |
| 102 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/it.lproj/StartupScreen.strings` | 4,206 |
| 103 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/it.lproj/WhatsNew.strings` | 990 |
| 104 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ja.lproj/AppBridge.strings` | 495 |
| 105 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ja.lproj/Car.strings` | 4,431 |
| 106 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ja.lproj/HomeScreen.strings` | 2,662 |
| 107 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ja.lproj/Localizable.strings` | 11,304 |
| 108 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ja.lproj/Onboarding.strings` | 1,712 |
| 109 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ja.lproj/Profiles.strings` | 569 |
| 110 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ja.lproj/SpeedBubble.strings` | 3,989 |
| 111 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ja.lproj/SplitScreen.strings` | 3,564 |
| 112 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ja.lproj/StartupScreen.strings` | 3,932 |
| 113 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ja.lproj/WhatsNew.strings` | 724 |
| 114 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ko.lproj/AppBridge.strings` | 489 |
| 115 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ko.lproj/Car.strings` | 4,433 |
| 116 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ko.lproj/HomeScreen.strings` | 2,697 |
| 117 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ko.lproj/Localizable.strings` | 11,245 |
| 118 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ko.lproj/Onboarding.strings` | 1,818 |
| 119 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ko.lproj/Profiles.strings` | 613 |
| 120 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ko.lproj/SpeedBubble.strings` | 4,059 |
| 121 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ko.lproj/SplitScreen.strings` | 3,552 |
| 122 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ko.lproj/StartupScreen.strings` | 4,048 |
| 123 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ko.lproj/WhatsNew.strings` | 812 |
| 124 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/logo.png` | 9,406 |
| 125 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/logo@2x.png` | 27,891 |
| 126 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/logo@3x.png` | 48,665 |
| 127 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/pt-BR.lproj/AppBridge.strings` | 612 |
| 128 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/pt-BR.lproj/Car.strings` | 5,629 |
| 129 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/pt-BR.lproj/HomeScreen.strings` | 3,943 |
| 130 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/pt-BR.lproj/Localizable.strings` | 15,011 |
| 131 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/pt-BR.lproj/Onboarding.strings` | 2,747 |
| 132 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/pt-BR.lproj/Profiles.strings` | 925 |
| 133 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/pt-BR.lproj/SpeedBubble.strings` | 4,819 |
| 134 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/pt-BR.lproj/SplitScreen.strings` | 4,323 |
| 135 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/pt-BR.lproj/StartupScreen.strings` | 5,383 |
| 136 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/pt-BR.lproj/WhatsNew.strings` | 1,054 |
| 137 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ru.lproj/AppBridge.strings` | 715 |
| 138 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ru.lproj/Car.strings` | 6,315 |
| 139 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ru.lproj/HomeScreen.strings` | 4,264 |
| 140 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ru.lproj/Localizable.strings` | 17,450 |
| 141 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ru.lproj/Onboarding.strings` | 3,107 |
| 142 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ru.lproj/Profiles.strings` | 1,093 |
| 143 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ru.lproj/SpeedBubble.strings` | 5,960 |
| 144 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ru.lproj/SplitScreen.strings` | 5,157 |
| 145 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ru.lproj/StartupScreen.strings` | 5,617 |
| 146 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/ru.lproj/WhatsNew.strings` | 1,338 |
| 147 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/th.lproj/AppBridge.strings` | 577 |
| 148 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/th.lproj/Car.strings` | 5,477 |
| 149 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/th.lproj/HomeScreen.strings` | 3,475 |
| 150 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/th.lproj/Localizable.strings` | 14,455 |
| 151 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/th.lproj/Onboarding.strings` | 2,375 |
| 152 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/th.lproj/Profiles.strings` | 849 |
| 153 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/th.lproj/SpeedBubble.strings` | 5,179 |
| 154 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/th.lproj/SplitScreen.strings` | 4,283 |
| 155 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/th.lproj/StartupScreen.strings` | 5,029 |
| 156 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/th.lproj/WhatsNew.strings` | 1,102 |
| 157 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/vi.lproj/AppBridge.strings` | 572 |
| 158 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/vi.lproj/HomeScreen.strings` | 3,588 |
| 159 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/vi.lproj/Localizable.strings` | 14,526 |
| 160 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/vi.lproj/Onboarding.strings` | 2,479 |
| 161 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/vi.lproj/Profiles.strings` | 853 |
| 162 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/vi.lproj/SpeedBubble.strings` | 5,233 |
| 163 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/vi.lproj/SplitScreen.strings` | 4,302 |
| 164 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/vi.lproj/StartupScreen.strings` | 7,408 |
| 165 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/vi.lproj/WhatsNew.strings` | 1,212 |
| 166 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/zh-Hans.lproj/AppBridge.strings` | 469 |
| 167 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/zh-Hans.lproj/Car.strings` | 3,778 |
| 168 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/zh-Hans.lproj/HomeScreen.strings` | 2,398 |
| 169 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/zh-Hans.lproj/Localizable.strings` | 9,498 |
| 170 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/zh-Hans.lproj/Onboarding.strings` | 1,410 |
| 171 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/zh-Hans.lproj/Profiles.strings` | 477 |
| 172 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/zh-Hans.lproj/SpeedBubble.strings` | 3,634 |
| 173 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/zh-Hans.lproj/SplitScreen.strings` | 3,243 |
| 174 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/zh-Hans.lproj/StartupScreen.strings` | 3,354 |
| 175 | `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/zh-Hans.lproj/WhatsNew.strings` | 620 |
| 176 | `var/jb/Library/PreferenceLoader/Preferences/OmniCarPrefs.plist` | 186 |

Tổng dung lượng đã bóc: 5,909,467 bytes (khớp `Installed-Size: 6160` KB ≈ 6.307.840 bytes ở mức block đĩa).

---

## 3. Tổng quan các file nhị phân (8 binary)

Đính chính một mô tả mơ hồ trước đây ("một dylib ba vai"): gói có **6 dylib tweak riêng biệt** + 1 app + 1 preference bundle, mỗi dylib có filter và vai riêng (xem cột Filter ở mục 4). Điểm "ba vai" chỉ đúng một phần cho `OmniCarAppBridge.dylib`: nhờ filter `com.apple.UIKit` nó hiện diện đồng thời ở 3 loại tiến trình (app thường, SpringBoard, CarPlayApp) và trong mỗi nơi nó bật nhóm hook khác nhau theo bundle id của tiến trình chủ.

| Binary | Kích thước | SHA256 | Slices | Hàm (LC_FUNCTION_STARTS, arm64) | Class tự định nghĩa |
|---|---|---|---|---|---|
| OmniCar (executable của OmniCar.app) | 168,880 | `8e7dc4ddaf98a73b80910c0d5d00e38a084bfef2e9f97084f8bbdf76313807c8` | arm64 @off 16384, size 70576 · arm64e @off 98304, size 70576 | 8 | 1 |
| OmniCarCore.dylib | 276,832 | `c95c66f46d960702e2f7f4ea930b85fd96d01709c2733a14373b37eaca9ed0a5` | arm64 @off 16384, size 129376 · arm64e @off 147456, size 129376 | 103 | 0 |
| OmniCarCarProbe.dylib | 242,784 | `85db0c33e9a918e9dfd944dcdc53e3326fb83259554d5c1a3fd976fcb9c6026f` | arm64 @off 16384, size 111712 · arm64e @off 131072, size 111712 | 82 | 0 |
| OmniCarAppBridge.dylib | 613,376 | `d99b8d00dc60f69db7b54fc1addaec6b8cb866b8dcdde6f1d85e06ce5b7d6e79` | arm64 @off 16384, size 285488 · arm64e @off 311296, size 302080 | 383 | 8 |
| OmniCarSpeedBubble.dylib | 649,808 | `f9531a646d5ce11f70cba34d1b30c6ffed3311d347922b890e41b9b330b8a836` | arm64 @off 16384, size 305520 · arm64e @off 327680, size 322128 | 495 | 9 |
| OmniCarSplitScreen.dylib | 1,229,920 | `f696b518579266cf99cfd46f85cb54931d18e679c793a563ee2fcc9bf8115754` | arm64 @off 16384, size 590720 · arm64e @off 622592, size 607328 | 880 | 11 |
| OmniCarStartupScreen.dylib | 567,792 | `2cd8b29434f7f81e07a222298952696a0fced9139e543c6877aaa7f8b0d72037` | arm64 @off 16384, size 272864 · arm64e @off 294912, size 272880 | 352 | 8 |
| OmniCarPrefs (PreferenceBundle) | 1,303,344 | `15bca4bee19bd9e04300e2c8070f665869df93c0f8913278e87b147ebf895a76` | arm64 @off 16384, size 631360 · arm64e @off 655360, size 647984 | 976 | 29 |

---

## 4. Từng binary — hồ sơ chi tiết

### 4.1. OmniCar (executable của OmniCar.app)

- Đường dẫn cài đặt: `/var/jb/Applications/OmniCar.app/OmniCar`
- Kích thước file: 168,880 bytes · SHA256 (bản fat): `8e7dc4ddaf98a73b80910c0d5d00e38a084bfef2e9f97084f8bbdf76313807c8`
- Slices: arm64 @off 16384, size 70576 · arm64e @off 98304, size 70576 (cả hai slice cùng danh sách thư viện + entitlements; bảng dưới đây trích slice arm64)
- Filter/điểm nạp: — (app độc lập, không phải tweak)
- Số hàm theo LC_FUNCTION_STARTS (arm64): 8
- Symbol C/ObjC **định nghĩa** (export, 4):

```
_OBJC_CLASS_$_OMCAppDelegate
_OBJC_METACLASS_$_OMCAppDelegate
__mh_execute_header
_main
```
- Symbol **import** (undefined, 0): danh sách đầy đủ chính là bảng import của chained-fixups — các symbol tiêu biểu được nhắc trong phần hook/IPC; toàn bộ 0 tên nằm trong file nm đi kèm hồ sơ thô.

- Install name (LC_ID_DYLIB): None
- LC_BUILD_VERSION: platform=2 minos=15.0.0 sdk=16.4.0
- LC_SOURCE_VERSION: 0.0.0.0.0
- UUID (arm64 slice): daf904be27fb3a55b76a5dae329f6a3a
- Encryption info (cryptid): 0
- RPATH: /var/jb/Library/Frameworks, /var/jb/usr/lib, @loader_path/.jbroot/Library/Frameworks, @loader_path/.jbroot/usr/lib
- Linked libraries (arm64 slice):
  - [LOAD] /usr/lib/libobjc.A.dylib (current 228.0.0, compat 1.0.0)
  - [LOAD] /System/Library/Frameworks/Foundation.framework/Foundation (current 1971.0.0, compat 300.0.0)
  - [LOAD] /System/Library/Frameworks/CoreFoundation.framework/CoreFoundation (current 1971.0.0, compat 150.0.0)
  - [LOAD] /System/Library/Frameworks/UIKit.framework/UIKit (current 6441.1.101, compat 1.0.0)
  - [LOAD] /usr/lib/libSystem.B.dylib (current 1319.100.3, compat 1.0.0)
  - [LOAD] /System/Library/Frameworks/CoreGraphics.framework/CoreGraphics (current 1690.5.4, compat 64.0.0)
- Entitlements (từ code signature, XML):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.private.security.no-container</key>
	<true/>
	<key>platform-application</key>
	<true/>
</dict>
</plist>
```
- Số import (chained fixups): 38

### Classes định nghĩa trong binary (1)

#### @interface OMCAppDelegate : (import) _OBJC_CLASS_$_UIResponder
- Protocols: UIApplicationDelegate
- instanceSize: 16, flags: 0x184
- Ivars:
  - _window : @"UIWindow" (offset 8, align 3, size 8)
- Properties:
  - window  [T@"UIWindow",&,N,V_window]
  - hash  [TQ,R]
  - superclass  [T#,R]
  - description  [T@"NSString",R,C]
  - debugDescription  [T@"NSString",?,R,C]
- Instance methods (6):
  - application:didFinishLaunchingWithOptions:  [types: B32@0:8@16@24] @ 0x100004000
  - openSettings  [types: v16@0:8] @ 0x1000043f4
  - application:openURL:options:  [types: B40@0:8@16@24@32] @ 0x100004468
  - window  [types: @16@0:8] @ 0x100004624
  - setWindow:  [types: v24@0:8@16] @ 0x100004634
  - .cxx_destruct  [types: v16@0:8] @ 0x100004674

### Protocols định nghĩa (2)

#### @protocol NSObject
- Required instance methods:
  - isEqual:  [types: B24@0:8@16] @ 0x100004cc0
  - class  [types: #16@0:8] @ 0x100004ccc
  - self  [types: @16@0:8] @ 0x100004cd8
  - performSelector:  [types: @24@0:8:16] @ 0x100004ce4
  - performSelector:withObject:  [types: @32@0:8:16@24] @ 0x100004cf0
  - performSelector:withObject:withObject:  [types: @40@0:8:16@24@32] @ 0x100004cfc
  - isProxy  [types: B16@0:8] @ 0x100004d08
  - isKindOfClass:  [types: B24@0:8#16] @ 0x100004d14
  - isMemberOfClass:  [types: B24@0:8#16] @ 0x100004d20
  - conformsToProtocol:  [types: B24@0:8@16] @ 0x100004d2c
  - respondsToSelector:  [types: B24@0:8:16] @ 0x100004d38
  - retain  [types: @16@0:8] @ 0x100004d44
  - release  [types: Vv16@0:8] @ 0x100004d50
  - autorelease  [types: @16@0:8] @ 0x100004d5c
  - retainCount  [types: Q16@0:8] @ 0x100004d68
  - zone  [types: ^{_NSZone=}16@0:8] @ 0x100004d74
  - hash  [types: Q16@0:8] @ 0x100004d80
  - superclass  [types: #16@0:8] @ 0x100004d8c
  - description  [types: @16@0:8] @ 0x100004d98
- Optional instance methods:
  - debugDescription  [types: @16@0:8] @ 0x100004db0
- Properties:
  - hash  [TQ,R]
  - superclass  [T#,R]
  - description  [T@"NSString",R,C]
  - debugDescription  [T@"NSString",?,R,C]

#### @protocol UIApplicationDelegate
- Optional instance methods:
  - applicationDidFinishLaunching:  [types: v24@0:8@16] @ 0x100004dc8
  - application:willFinishLaunchingWithOptions:  [types: B32@0:8@16@24] @ 0x100004dd4
  - application:didFinishLaunchingWithOptions:  [types: B32@0:8@16@24] @ 0x100004de0
  - applicationDidBecomeActive:  [types: v24@0:8@16] @ 0x100004dec
  - applicationWillResignActive:  [types: v24@0:8@16] @ 0x100004df8
  - application:handleOpenURL:  [types: B32@0:8@16@24] @ 0x100004e04
  - application:openURL:sourceApplication:annotation:  [types: B48@0:8@16@24@32@40] @ 0x100004e10
  - application:openURL:options:  [types: B40@0:8@16@24@32] @ 0x100004e1c
  - applicationDidReceiveMemoryWarning:  [types: v24@0:8@16] @ 0x100004e28
  - applicationWillTerminate:  [types: v24@0:8@16] @ 0x100004e34
  - applicationSignificantTimeChange:  [types: v24@0:8@16] @ 0x100004e40
  - application:willChangeStatusBarOrientation:duration:  [types: v40@0:8@16q24d32] @ 0x100004e4c
  - application:didChangeStatusBarOrientation:  [types: v32@0:8@16q24] @ 0x100004e58
  - application:willChangeStatusBarFrame:  [types: v56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24] @ 0x100004e64
  - application:didChangeStatusBarFrame:  [types: v56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24] @ 0x100004e70
  - application:didRegisterUserNotificationSettings:  [types: v32@0:8@16@24] @ 0x100004e7c
  - application:didRegisterForRemoteNotificationsWithDeviceToken:  [types: v32@0:8@16@24] @ 0x100004e88
  - application:didFailToRegisterForRemoteNotificationsWithError:  [types: v32@0:8@16@24] @ 0x100004e94
  - application:didReceiveRemoteNotification:  [types: v32@0:8@16@24] @ 0x100004ea0
  - application:didReceiveLocalNotification:  [types: v32@0:8@16@24] @ 0x100004eac
  - application:handleActionWithIdentifier:forLocalNotification:completionHandler:  [types: v48@0:8@16@24@32@?40] @ 0x100004eb8
  - application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:  [types: v56@0:8@16@24@32@40@?48] @ 0x100004ec4
  - application:handleActionWithIdentifier:forRemoteNotification:completionHandler:  [types: v48@0:8@16@24@32@?40] @ 0x100004ed0
  - application:handleActionWithIdentifier:forLocalNotification:withResponseInfo:completionHandler:  [types: v56@0:8@16@24@32@40@?48] @ 0x100004edc
  - application:didReceiveRemoteNotification:fetchCompletionHandler:  [types: v40@0:8@16@24@?32] @ 0x100004ee8
  - application:performFetchWithCompletionHandler:  [types: v32@0:8@16@?24] @ 0x100004ef4
  - application:performActionForShortcutItem:completionHandler:  [types: v40@0:8@16@24@?32] @ 0x100004f00
  - application:handleEventsForBackgroundURLSession:completionHandler:  [types: v40@0:8@16@24@?32] @ 0x100004f0c
  - application:handleWatchKitExtensionRequest:reply:  [types: v40@0:8@16@24@?32] @ 0x100004f18
  - applicationShouldRequestHealthAuthorization:  [types: v24@0:8@16] @ 0x100004f24
  - application:handlerForIntent:  [types: @32@0:8@16@24] @ 0x100004f30
  - application:handleIntent:completionHandler:  [types: v40@0:8@16@24@?32] @ 0x100004f3c
  - applicationDidEnterBackground:  [types: v24@0:8@16] @ 0x100004f48
  - applicationWillEnterForeground:  [types: v24@0:8@16] @ 0x100004f54
  - applicationProtectedDataWillBecomeUnavailable:  [types: v24@0:8@16] @ 0x100004f60
  - applicationProtectedDataDidBecomeAvailable:  [types: v24@0:8@16] @ 0x100004f6c
  - application:supportedInterfaceOrientationsForWindow:  [types: Q32@0:8@16@24] @ 0x100004f78
  - application:shouldAllowExtensionPointIdentifier:  [types: B32@0:8@16@24] @ 0x100004f84
  - application:viewControllerWithRestorationIdentifierPath:coder:  [types: @40@0:8@16@24@32] @ 0x100004f90
  - application:shouldSaveSecureApplicationState:  [types: B32@0:8@16@24] @ 0x100004f9c
  - application:shouldRestoreSecureApplicationState:  [types: B32@0:8@16@24] @ 0x100004fa8
  - application:willEncodeRestorableStateWithCoder:  [types: v32@0:8@16@24] @ 0x100004fb4
  - application:didDecodeRestorableStateWithCoder:  [types: v32@0:8@16@24] @ 0x100004fc0
  - application:shouldSaveApplicationState:  [types: B32@0:8@16@24] @ 0x100004fcc
  - application:shouldRestoreApplicationState:  [types: B32@0:8@16@24] @ 0x100004fd8
  - application:willContinueUserActivityWithType:  [types: B32@0:8@16@24] @ 0x100004fe4
  - application:continueUserActivity:restorationHandler:  [types: B40@0:8@16@24@?32] @ 0x100004ff0
  - application:didFailToContinueUserActivityWithType:error:  [types: v40@0:8@16@24@32] @ 0x100004ffc
  - application:didUpdateUserActivity:  [types: v32@0:8@16@24] @ 0x100005008
  - application:userDidAcceptCloudKitShareWithMetadata:  [types: v32@0:8@16@24] @ 0x100005014
  - application:configurationForConnectingSceneSession:options:  [types: @40@0:8@16@24@32] @ 0x100005020
  - application:didDiscardSceneSessions:  [types: v32@0:8@16@24] @ 0x10000502c
  - applicationShouldAutomaticallyLocalizeKeyCommands:  [types: B24@0:8@16] @ 0x100005038
  - window  [types: @16@0:8] @ 0x100005044
  - setWindow:  [types: v24@0:8@16] @ 0x100005050
- Properties:
  - window  [T@"UIWindow",?,&,N]

### __objc_classrefs (13 refs)
- OMCAppDelegate
- _OBJC_CLASS_$_NSDictionary
- _OBJC_CLASS_$_NSLocale
- _OBJC_CLASS_$_NSString
- _OBJC_CLASS_$_NSURL
- _OBJC_CLASS_$_UIApplication
- _OBJC_CLASS_$_UIButton
- _OBJC_CLASS_$_UIColor
- _OBJC_CLASS_$_UIFont
- _OBJC_CLASS_$_UILabel
- _OBJC_CLASS_$_UIScreen
- _OBJC_CLASS_$_UIViewController
- _OBJC_CLASS_$_UIWindow

### Selector refs — các selector binary tham chiếu (112)
- .cxx_destruct
- URLWithString:
- absoluteString
- addSubview:
- addTarget:action:forControlEvents:
- application:configurationForConnectingSceneSession:options:
- application:continueUserActivity:restorationHandler:
- application:didChangeStatusBarFrame:
- application:didChangeStatusBarOrientation:
- application:didDecodeRestorableStateWithCoder:
- application:didDiscardSceneSessions:
- application:didFailToContinueUserActivityWithType:error:
- application:didFailToRegisterForRemoteNotificationsWithError:
- application:didFinishLaunchingWithOptions:
- application:didReceiveLocalNotification:
- application:didReceiveRemoteNotification:
- application:didReceiveRemoteNotification:fetchCompletionHandler:
- application:didRegisterForRemoteNotificationsWithDeviceToken:
- application:didRegisterUserNotificationSettings:
- application:didUpdateUserActivity:
- application:handleActionWithIdentifier:forLocalNotification:completionHandler:
- application:handleActionWithIdentifier:forLocalNotification:withResponseInfo:completionHandler:
- application:handleActionWithIdentifier:forRemoteNotification:completionHandler:
- application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:
- application:handleEventsForBackgroundURLSession:completionHandler:
- application:handleIntent:completionHandler:
- application:handleOpenURL:
- application:handleWatchKitExtensionRequest:reply:
- application:handlerForIntent:
- application:openURL:options:
- application:openURL:sourceApplication:annotation:
- application:performActionForShortcutItem:completionHandler:
- application:performFetchWithCompletionHandler:
- application:shouldAllowExtensionPointIdentifier:
- application:shouldRestoreApplicationState:
- application:shouldRestoreSecureApplicationState:
- application:shouldSaveApplicationState:
- application:shouldSaveSecureApplicationState:
- application:supportedInterfaceOrientationsForWindow:
- application:userDidAcceptCloudKitShareWithMetadata:
- application:viewControllerWithRestorationIdentifierPath:coder:
- application:willChangeStatusBarFrame:
- application:willChangeStatusBarOrientation:duration:
- application:willContinueUserActivityWithType:
- application:willEncodeRestorableStateWithCoder:
- application:willFinishLaunchingWithOptions:
- applicationDidBecomeActive:
- applicationDidEnterBackground:
- applicationDidFinishLaunching:
- applicationDidReceiveMemoryWarning:
- applicationProtectedDataDidBecomeAvailable:
- applicationProtectedDataWillBecomeUnavailable:
- applicationShouldAutomaticallyLocalizeKeyCommands:
- applicationShouldRequestHealthAuthorization:
- applicationSignificantTimeChange:
- applicationWillEnterForeground:
- applicationWillResignActive:
- applicationWillTerminate:
- autorelease
- bounds
- buttonWithType:
- class
- colorWithRed:green:blue:alpha:
- conformsToProtocol:
- debugDescription
- defaultCenter
- description
- dictionaryWithObjects:forKeys:count:
- firstObject
- hasPrefix:
- hash
- initWithFrame:
- isEqual:
- isEqualToString:
- isKindOfClass:
- isMemberOfClass:
- isProxy
- mainScreen
- makeKeyAndVisible
- openSettings
- openURL:options:completionHandler:
- performSelector:
- performSelector:withObject:
- performSelector:withObject:withObject:
- postNotificationName:object:userInfo:
- preferredLanguages
- release
- respondsToSelector:
- retain
- retainCount
- scheme
- self
- setAutoresizingMask:
- setBackgroundColor:
- setFont:
- setFrame:
- setNumberOfLines:
- setRootViewController:
- setText:
- setTextAlignment:
- setTextColor:
- setTitle:forState:
- setWindow:
- sharedApplication
- stringWithFormat:
- superclass
- suspend
- systemFontOfSize:
- view
- whiteColor
- window
- zone

### CFString constants (15)
- `vi`
- `OmniCar

%@

%@

omnicar://splitscreen/open?left=com.apple.Maps&right=com.spotify.client

omnicar://splitscreen/fav?n=1

omnicar://splitscreen/close

%@`
- `App này nhận lệnh từ Shortcuts / Siri.`
- `This app receives commands from Shortcuts / Siri.`
- `Tạo Shortcut với hành động "Mở URL":`
- `Create a Shortcut with the "Open URL" action:`
- `Cài đặt chi tiết: Cài đặt > OmniCar`
- `Settings: Settings > OmniCar`
- `Mở Cài đặt OmniCar`
- `Open OmniCar Settings`
- `prefs:root=OmniCar`
- `omnicar`
- `NSDistributedNotificationCenter`
- `com.anlai.omnicar/url`
- `url`


#### Ghi chú về app OmniCar

App là launcher mỏng: 1 class `OMCAppDelegate`, 8 hàm, entitlements `platform-application` + `com.apple.private.security.no-container`. Info.plist khai URL scheme `omnicar` (xem mục 6). Không chứa logic CarPlay — vai của nó là điểm chạm cho người dùng/Siri/Shortcuts (mở `omnicar://...`) và nhiều khả năng phát kênh `com.anlai.omnicar/url` (chuỗi này nằm trong OmniCarCore) để Core phía SpringBoard xử lý tiếp. Chi tiết method của `OMCAppDelegate` ở bảng class bên dưới.


---

### 4.2. OmniCarCore.dylib

- Đường dẫn cài đặt: `/var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarCore.dylib`
- Kích thước file: 276,832 bytes · SHA256 (bản fat): `c95c66f46d960702e2f7f4ea930b85fd96d01709c2733a14373b37eaca9ed0a5`
- Slices: arm64 @off 16384, size 129376 · arm64e @off 147456, size 129376 (cả hai slice cùng danh sách thư viện + entitlements; bảng dưới đây trích slice arm64)
- Filter/điểm nạp: Filter Bundles: `com.apple.springboard` → chỉ nạp vào **SpringBoard**
- Số hàm theo LC_FUNCTION_STARTS (arm64): 103
- Symbol C/ObjC **định nghĩa** (export, 21):

```
_OMCCarClass
_OMCCarLaunchInfo
_OMCCarWireless
_OMCCheckHooks
_OMCCrashGuard
_OMCCurrentLanguage
_OMCEnabled
_OMCExpired
_OMCFeatureEnabled
_OMCHasMethod
_OMCLiteActive
_OMCLogRelayStart
_OMCLogWrite
_OMCLogoMeshImage
_OMCMissingSelector
_OMCPref
_OMCPrefsSync
_OMCProfileKeys
_OMCSupportedLanguages
_OMCTr
_OMCTrustedTimeStart
```
- Symbol **import** (undefined, 0): danh sách đầy đủ chính là bảng import của chained-fixups — các symbol tiêu biểu được nhắc trong phần hook/IPC; toàn bộ 0 tên nằm trong file nm đi kèm hồ sơ thô.

- Install name (LC_ID_DYLIB): ('@rpath/OmniCarCore.dylib', '0.0.0', '0.0.0')
- LC_BUILD_VERSION: platform=2 minos=15.0.0 sdk=16.4.0
- LC_SOURCE_VERSION: 0.0.0.0.0
- UUID (arm64 slice): f4217823cc6d336bbceb972852a3c095
- Encryption info (cryptid): 0
- RPATH: /var/jb/Library/Frameworks, /var/jb/usr/lib, @loader_path/.jbroot/Library/Frameworks, @loader_path/.jbroot/usr/lib
- Linked libraries (arm64 slice):
  - [LOAD] /usr/lib/libobjc.A.dylib (current 228.0.0, compat 1.0.0)
  - [LOAD] /System/Library/Frameworks/Foundation.framework/Foundation (current 1971.0.0, compat 300.0.0)
  - [LOAD] /System/Library/Frameworks/CoreFoundation.framework/CoreFoundation (current 1971.0.0, compat 150.0.0)
  - [LOAD] /System/Library/Frameworks/UIKit.framework/UIKit (current 6441.1.101, compat 1.0.0)
  - [LOAD] /usr/lib/libSystem.B.dylib (current 1319.100.3, compat 1.0.0)
  - [LOAD] /System/Library/Frameworks/CoreGraphics.framework/CoreGraphics (current 1690.5.4, compat 64.0.0)
- Entitlements: KHÔNG có blob entitlements trong code signature.
- Số import (chained fixups): 165

### Classes định nghĩa trong binary (0)

### __objc_classrefs (32 refs)
- _OBJC_CLASS_$_NSArray
- _OBJC_CLASS_$_NSBundle
- _OBJC_CLASS_$_NSCharacterSet
- _OBJC_CLASS_$_NSDate
- _OBJC_CLASS_$_NSDateFormatter
- _OBJC_CLASS_$_NSDictionary
- _OBJC_CLASS_$_NSFileManager
- _OBJC_CLASS_$_NSHTTPURLResponse
- _OBJC_CLASS_$_NSLocale
- _OBJC_CLASS_$_NSMutableArray
- _OBJC_CLASS_$_NSMutableDictionary
- _OBJC_CLASS_$_NSMutableOrderedSet
- _OBJC_CLASS_$_NSMutableSet
- _OBJC_CLASS_$_NSMutableURLRequest
- _OBJC_CLASS_$_NSNotificationCenter
- _OBJC_CLASS_$_NSNumber
- _OBJC_CLASS_$_NSObject
- _OBJC_CLASS_$_NSOperationQueue
- _OBJC_CLASS_$_NSProcessInfo
- _OBJC_CLASS_$_NSRunLoop
- _OBJC_CLASS_$_NSString
- _OBJC_CLASS_$_NSTimeZone
- _OBJC_CLASS_$_NSTimer
- _OBJC_CLASS_$_NSURL
- _OBJC_CLASS_$_NSURLComponents
- _OBJC_CLASS_$_NSURLSession
- _OBJC_CLASS_$_UIApplication
- _OBJC_CLASS_$_UIColor
- _OBJC_CLASS_$_UIDevice
- _OBJC_CLASS_$_UIGraphicsImageRenderer
- _OBJC_CLASS_$_UIGraphicsImageRendererFormat
- _OBJC_CLASS_$_UIScreen

### Selector refs — các selector binary tham chiếu (126)
- CGContext
- URLWithString:
- UTF8String
- addObject:
- addObjectsFromArray:
- addObserverForName:object:queue:usingBlock:
- addToRunLoop:forMode:
- allHeaderFields
- array
- arrayByAddingObject:
- arrayWithArray:
- attributesOfItemAtPath:error:
- boolValue
- bounds
- bundleIdentifier
- callStackReturnAddresses
- callStackSymbols
- colorWithRed:green:blue:alpha:
- componentsJoinedByString:
- componentsSeparatedByCharactersInSet:
- componentsSeparatedByString:
- componentsWithURL:resolvingAgainstBaseURL:
- containsObject:
- containsString:
- copy
- count
- countByEnumeratingWithState:objects:count:
- currentDevice
- dataTaskWithRequest:completionHandler:
- date
- dateFromString:
- defaultCenter
- defaultManager
- description
- dictionary
- dictionaryWithContentsOfFile:
- dictionaryWithObjects:forKeys:count:
- displayLinkWithTarget:selector:
- doubleValue
- fileModificationDate
- fileSize
- fileSystemRepresentation
- firstObject
- hasPrefix:
- host
- imageWithActions:
- initWithSize:format:
- integerValue
- invalidate
- isEqual:
- isEqualToString:
- isLowPowerModeEnabled
- lastPathComponent
- length
- localeWithLocaleIdentifier:
- lowercaseString
- mainBundle
- mainQueue
- mainRunLoop
- mainScreen
- maximumFramesPerSecond
- moveItemAtPath:toPath:error:
- mutableCopy
- name
- nativeBounds
- newlineCharacterSet
- numberWithBool:
- numberWithDouble:
- numberWithInteger:
- numberWithLong:
- numberWithUnsignedInteger:
- object
- objectAtIndexedSubscript:
- objectForKeyedSubscript:
- orderedSet
- orderedSetWithArray:
- pathComponents
- postNotificationName:object:userInfo:
- preferredFormat
- preferredLanguages
- processInfo
- processName
- queryItems
- reason
- removeAllObjects
- removeItemAtPath:error:
- removeObject:
- requestWithURL:
- resume
- scale
- scheduledTimerWithTimeInterval:repeats:block:
- scheme
- screens
- set
- setCachePolicy:
- setDateFormat:
- setFill
- setHTTPMethod:
- setLocale:
- setObject:forKeyedSubscript:
- setOpaque:
- setScale:
- setTimeZone:
- setTimeoutInterval:
- sharedApplication
- sharedSession
- stringByAppendingPathComponent:
- stringByAppendingString:
- stringByDeletingPathExtension
- stringFromDate:
- stringWithContentsOfFile:encoding:error:
- stringWithFormat:
- stringWithUTF8String:
- substringFromIndex:
- substringToIndex:
- systemVersion
- thermalState
- timeIntervalSince1970
- timeIntervalSinceNow
- timeZoneForSecondsFromGMT:
- unsignedIntegerValue
- unsignedLongLongValue
- userInfo
- value
- valueForKey:
- writeToFile:atomically:

### CFString constants (288)
- `Core`
- `free period over (%s)`
- `free period over (%s): features off`
- `loaded into %@ enabled=%d`
- `com.anlai.omnicar/url`
- `url`
- `https://www.apple.com/`
- `HEAD`
- `Date`
- `en_US_POSIX`
- `EEE, dd MMM yyyy HH:mm:ss zzz`
- `trustedTime`
- `com.anlai.omnicar`
- `rescueFeatures`
- `, `
- `O·m·n·i·C·a·r·:· ·c`
- `OmniCar: rescue mode`
- `CarPlay bị sập %d lần liền ngay sau khi cắm, nên OmniCar đã tắt: %@.

Vào Cài đặt > OmniCar để bật lại hoặc gửi log cho tác giả.`
- `CarPlay crashed %d times in a row right after connecting, so OmniCar turned off: %@.

Open Settings > OmniCar to turn it back on or send the log to the developer.`
- `thong bao che do cuu: %@ (notice=%d)`
- `OK`
- `splitScreen`
- `Chia màn hình`
- `Split Screen`
- `startupScreen`
- `Màn hình khởi động`
- `Startup Screen`
- `speedBubble`
- `Bong bóng tốc độ`
- `Speed Bubble`
- `appBridge`
- `App trên màn xe`
- `Apps on the car screen`
- `cleanRamOnConnect`
- `currentCarPlayExternalDevice`
- `bundleIdentifier`
- `%@ (%@)`
- `diagCleanRam`
- `date`
- `closed`
- `running`
- `don RAM (%@, xe=%d): %lu app dang chay, dong %lu: %@ | giu lai: %@`
- `bam tay`
- `cam xe`
- `don RAM: van con chay sau 2s: %@`
- `sharedInstance`
- `runningApplications`
- `allApplications`
- `isRunning`
- `processState`
- `com.apple.mobilephone`
- `com.apple.MobileSMS`
- `com.apple.InCallService`
- `com.apple.Preferences`
- `com.apple.facetime`
- `system`
- `com.apple.Music`
- `com.apple.Maps`
- `com.apple.podcasts`
- `vn.vietmap.live`
- `com.lumi.GOFA`
- `com.waze.iphone`
- `car`
- `splitScreenCarPlayApps`
- `appBridgeApps`
- `nowPlayingApplication`
- `playing`
- `_accessibilityFrontMostApplication`
- `front`
- `applicationProxyForIdentifier:`
- `applicationType`
- `User`
- `System`
- `appTags`
- `hidden`
- `OmniCar: free memory`
- `sharedService`
- `terminateApplication:forReason:andReport:withDescription:`
- `omnicar`
- `feature`
- `splitscreen`
- `splitScreenEnabled`
- `appbridge`
- `appBridgeEnabled`
- `speedbubble`
- `speedBubbleEnabled`
- `startupscreen`
- `startupScreenEnabled`
- `all`
- `enabled`
- `URL: khong co tinh nang %@`
- `on`
- `toggle`
- `URL: %@ = %d`
- `lite`
- `off`
- `always`
- `auto`
- `mode`
- `liteMode`
- `URL: che do nhe = %@`
- `startup`
- `video`
- `logo`
- `greeting`
- `weather`
- `style`
- `startupScreenStyle`
- `URL: kieu khoi dong = %@`
- `cleanram`
- `Enabled`
- `diagCar`
- `session`
- `configuration`
- `wireless`
- `1`
- `0`
- `wired`
- `transport`
- `wifi`
- `wi-fi`
- `usb`
- `/var/mobile/Documents/OmniCar.log`
- `[OmniCar/%@] %@`
- `yyyy-MM-dd HH:mm:ss.SSS`
- `%@ [%@:%d] %@: %@
`
- `com.anlai.omnicar/log`
- `line`
- `+`
- ` `
- `%@=%@`
- `-`
- `%@%@@%@`
- `diagHooks.`
- `total`
- `missing`
- `ios`
- `iOS %@: lop CarPlay %@`
- `iOS %@: %lu/%lu hook KHONG co tren iOS nay (tinh nang lien quan se khong chay): %@`
- `iOS %@: du %lu hook`
- `%@ %@`
- `THIEU METHOD (iOS %@): %@ -> bo qua`
- `DashBoard`
- `DB`
- `CAR`
- `_CAR`
- `launchInfoForApplication:`
- `launchInfoForApplication:withActivationSettings:`
- `THIEU METHOD: %@ khong tao duoc launchInfo`
- `features`
- `%@ dang tat boi che do cuu (tu %@): khong cai hook trong CarPlay`
- `rescueDate`
- `%@ bat lai sau che do cuu`
- `SpringBoard`
- `CarPlay`
- `build %s (%s) loaded into %@`
- `%@%s@%@`
- `diagLoaded.`
- `version`
- `1.0.3`
- `build`
- `fbebb21`
- `com.apple.springboard`
- `.old`
- `NSDistributedNotificationCenter`
- `com.apple.CarPlayApp`
- `OmniCar-CarPlay-crash.txt`
- `early`
- `suspects`
- `CARPLAY SAP LAN TRUOC:
%@`
- `
`
- `omc-crash `
- `age=`
- `suspect=`
- `last=`
- `age`
- `suspect`
- `diagLastCrash`
- `CarPlay sap som %ld/%d lan lien (nghi: %@)`
- `connected`
- `disconnected`
- `CHE DO CUU: CarPlay sap %d lan lien trong %ds dau -> tat %@`
- `uncaught %@: %@
%@
`
- `points`
- `pixels`
- `scale`
- `maxFPS`
- `CARSessionStatus`
- `currentSession`
- `CarKit loi: %@`
- `man xe %@ pt, %@ px, %@ fps, session=%d`
- `do hieu nang: bat dau, %lu tweak khac trong CarPlay: %@`
- `OmniCar`
- `CarPlay do %.1fs (OmniCar gan nhat: %@)`
- `heat`
- `hangs`
- `frames`
- `che do nhe tu dong: %@%@`
- `BAT`
- `tat`
- ` vi `
- `start`
- `updated`
- `seconds`
- `fps`
- `late`
- `worstMs`
- `freezes`
- `hangMaxMs`
- `hangWho`
- `cpuAvg`
- `cpuMax`
- `memMB`
- `memMaxMB`
- `availMinMB`
- `sysFreeMinMB`
- `thermalMax`
- `lowPower`
- `tweaks`
- `liteCount`
- `liteReason`
- `diagPerf`
- `%.0fx%.0f`
- `_`
- `description`
- `debugDescription`
- `hash`
- `superclass`
- `nil`
- `...`
- `carProfilesEnabled`
- `modelName`
- `name`
- `vehicleName`
- `accessoryName`
- `model`
- `vehicleIdentifier`
- `identifier`
- `uniqueIdentifier`
- `accessoryID`
- `deviceID`
- `serialNumber`
- `%@|%@`
- `?`
- `carProfiles`
- `carProfileCurrent`
- `values`
- `ho so xe moi: %@ (%@)`
- `nap ho so xe %@ (%@)`
- `Xe`
- `Car`
- `lastSeen`
- `(null)`
- `do hieu nang: %.0fs, tre %.0f/%.0f khung, do %.0f lan (max %.0f ms), CPU tb %.0f%%, RAM %.0f MB`
- `OmniCar-crashguard.plist`
- `splitScreenLastLeft`
- `splitScreenLastRight`
- `splitScreenSplitRatio`
- `splitScreenSplitDirection`
- `splitScreenPaneOrientation`
- `splitScreenAutoLaunch`
- `splitScreenPinnedApp`
- `speedBubbleSizeCar`
- `speedBubbleLook`
- `startupScreenVideoName`
- `startupScreenCarName`
- `startupScreenTempo`
- `appBridgeZoom`
- `vi`
- `en`
- `es`
- `pt-BR`
- `de`
- `fr`
- `it`
- `ru`
- `zh-Hans`
- `ja`
- `ko`
- `ar`
- `th`
- `id`
- `language`
- `zh`
- `2027-04-30`
- `yyyy-MM-dd`
- `%@/%@.lproj/Car.strings`
- `/Library/PreferenceBundles/OmniCarPrefs.bundle`


#### Hook & IPC của OmniCarCore (bằng chứng: disassembly constructor + danh sách import)

- **Không hook bằng Substrate**: binary **không import** `_MSHookMessageEx`/`_MSHookFunction` (đã kiểm danh sách import). Vai của Core là **điều phối trung tâm phía SpringBoard**: lắng nghe/phát các kênh Darwin notify, đồng bộ prefs, trông coi trạng thái xe.
- Đăng ký trong constructor `sub_46f0` (init @0x46f0):
  - `notify_register_dispatch("com.anlai.omnicar/rescue")`
  - `notify_register_dispatch("com.anlai.omnicar/car.connected")`
  - `notify_register_dispatch("com.anlai.omnicar/cleanram.now")`
- Các điểm phát/đọc rải trong binary:
  - `notify_post("com.anlai.omnicar/prefschanged")` (nhiều điểm: sub_464c, sub_5728, sub_7de8, sub_9bc0)
  - `notify_post("com.anlai.omnicar/car.connected")` (sub_9bc0)
  - `notify_post("com.anlai.omnicar/rescue")` (sub_7de8)
  - `notify_register_check("com.anlai.omnicar/lite")` + `notify_post("com.anlai.omnicar/lite")` (sub_6688, sub_aee4) — cơ chế trạng thái "lite" qua notifyd state token.
- `class_addMethod(?, "tick:", ?, "v@:@")` tại sub_b40c — mẫu code dùng chung của cả bộ (thêm method `tick:` kiểu timer vào một class nội bộ; class đích không giải được tĩnh — xem mục 7).
- Import đáng chú ý khác: `CFUserNotificationDisplayNotice` (hiện thông báo hệ thống), bộ `notify_get_state/notify_set_state` (đọc/ghi state số nguyên qua notifyd).


---

### 4.3. OmniCarCarProbe.dylib

- Đường dẫn cài đặt: `/var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarCarProbe.dylib`
- Kích thước file: 242,784 bytes · SHA256 (bản fat): `85db0c33e9a918e9dfd944dcdc53e3326fb83259554d5c1a3fd976fcb9c6026f`
- Slices: arm64 @off 16384, size 111712 · arm64e @off 131072, size 111712 (cả hai slice cùng danh sách thư viện + entitlements; bảng dưới đây trích slice arm64)
- Filter/điểm nạp: Filter Bundles: `com.apple.CarPlayApp` → chỉ nạp vào **CarPlayApp** (tiến trình giao diện xe)
- Số hàm theo LC_FUNCTION_STARTS (arm64): 82
- Symbol C/ObjC **định nghĩa** (export, 20):

```
_OMCCarClass
_OMCCarLaunchInfo
_OMCCarWireless
_OMCCheckHooks
_OMCCrashGuard
_OMCCurrentLanguage
_OMCEnabled
_OMCExpired
_OMCFeatureEnabled
_OMCHasMethod
_OMCLiteActive
_OMCLogRelayStart
_OMCLogWrite
_OMCLogoMeshImage
_OMCMissingSelector
_OMCPref
_OMCPrefsSync
_OMCProfileKeys
_OMCSupportedLanguages
_OMCTr
```
- Symbol **import** (undefined, 0): danh sách đầy đủ chính là bảng import của chained-fixups — các symbol tiêu biểu được nhắc trong phần hook/IPC; toàn bộ 0 tên nằm trong file nm đi kèm hồ sơ thô.

- Install name (LC_ID_DYLIB): ('@rpath/OmniCarCarProbe.dylib', '0.0.0', '0.0.0')
- LC_BUILD_VERSION: platform=2 minos=15.0.0 sdk=16.4.0
- LC_SOURCE_VERSION: 0.0.0.0.0
- UUID (arm64 slice): 60eabe8128c1328c8b0353aac26bc7e0
- Encryption info (cryptid): 0
- RPATH: /var/jb/Library/Frameworks, /var/jb/usr/lib, @loader_path/.jbroot/Library/Frameworks, @loader_path/.jbroot/usr/lib
- Linked libraries (arm64 slice):
  - [LOAD] /usr/lib/libobjc.A.dylib (current 228.0.0, compat 1.0.0)
  - [LOAD] /System/Library/Frameworks/Foundation.framework/Foundation (current 1971.0.0, compat 300.0.0)
  - [LOAD] /System/Library/Frameworks/CoreFoundation.framework/CoreFoundation (current 1971.0.0, compat 150.0.0)
  - [LOAD] /System/Library/Frameworks/UIKit.framework/UIKit (current 6441.1.101, compat 1.0.0)
  - [LOAD] /usr/lib/libSystem.B.dylib (current 1319.100.3, compat 1.0.0)
  - [LOAD] /System/Library/Frameworks/CoreGraphics.framework/CoreGraphics (current 1690.5.4, compat 64.0.0)
- Entitlements: KHÔNG có blob entitlements trong code signature.
- Số import (chained fixups): 153

### Classes định nghĩa trong binary (0)

### __objc_classrefs (25 refs)
- _OBJC_CLASS_$_NSArray
- _OBJC_CLASS_$_NSBundle
- _OBJC_CLASS_$_NSCharacterSet
- _OBJC_CLASS_$_NSDate
- _OBJC_CLASS_$_NSDateFormatter
- _OBJC_CLASS_$_NSDictionary
- _OBJC_CLASS_$_NSFileManager
- _OBJC_CLASS_$_NSLocale
- _OBJC_CLASS_$_NSMutableArray
- _OBJC_CLASS_$_NSMutableDictionary
- _OBJC_CLASS_$_NSMutableOrderedSet
- _OBJC_CLASS_$_NSMutableSet
- _OBJC_CLASS_$_NSNotificationCenter
- _OBJC_CLASS_$_NSNumber
- _OBJC_CLASS_$_NSObject
- _OBJC_CLASS_$_NSOperationQueue
- _OBJC_CLASS_$_NSProcessInfo
- _OBJC_CLASS_$_NSRunLoop
- _OBJC_CLASS_$_NSString
- _OBJC_CLASS_$_NSTimeZone
- _OBJC_CLASS_$_UIColor
- _OBJC_CLASS_$_UIDevice
- _OBJC_CLASS_$_UIGraphicsImageRenderer
- _OBJC_CLASS_$_UIGraphicsImageRendererFormat
- _OBJC_CLASS_$_UIScreen

### Selector refs — các selector binary tham chiếu (109)
- CGContext
- UTF8String
- addObject:
- addObjectsFromArray:
- addObserverForName:object:queue:usingBlock:
- addToRunLoop:forMode:
- array
- arrayByAddingObject:
- arrayWithArray:
- attributesOfItemAtPath:error:
- boolValue
- bounds
- bundleIdentifier
- callStackReturnAddresses
- callStackSymbols
- colorWithRed:green:blue:alpha:
- componentsJoinedByString:
- componentsSeparatedByCharactersInSet:
- componentsSeparatedByString:
- containsObject:
- containsString:
- copy
- count
- countByEnumeratingWithState:objects:count:
- currentDevice
- date
- dateFromString:
- defaultCenter
- defaultManager
- description
- dictionary
- dictionaryWithContentsOfFile:
- dictionaryWithObjects:forKeys:count:
- displayLinkWithTarget:selector:
- doubleValue
- fileModificationDate
- fileSize
- fileSystemRepresentation
- firstObject
- hasPrefix:
- imageWithActions:
- initWithSize:format:
- integerValue
- invalidate
- isEqual:
- isEqualToString:
- isLowPowerModeEnabled
- lastPathComponent
- length
- localeWithLocaleIdentifier:
- lowercaseString
- mainBundle
- mainQueue
- mainRunLoop
- mainScreen
- maximumFramesPerSecond
- moveItemAtPath:toPath:error:
- mutableCopy
- name
- nativeBounds
- newlineCharacterSet
- numberWithBool:
- numberWithDouble:
- numberWithInteger:
- numberWithLong:
- numberWithUnsignedInteger:
- object
- objectAtIndexedSubscript:
- objectForKeyedSubscript:
- orderedSet
- orderedSetWithArray:
- postNotificationName:object:userInfo:
- preferredFormat
- preferredLanguages
- processInfo
- processName
- reason
- removeAllObjects
- removeItemAtPath:error:
- removeObject:
- scale
- screens
- set
- setDateFormat:
- setFill
- setLocale:
- setObject:forKeyedSubscript:
- setOpaque:
- setScale:
- setTimeZone:
- stringByAppendingPathComponent:
- stringByAppendingString:
- stringByDeletingPathExtension
- stringFromDate:
- stringWithContentsOfFile:encoding:error:
- stringWithFormat:
- stringWithUTF8String:
- substringFromIndex:
- substringToIndex:
- systemVersion
- thermalState
- timeIntervalSince1970
- timeIntervalSinceNow
- timeZoneForSecondsFromGMT:
- unsignedIntegerValue
- unsignedLongLongValue
- userInfo
- valueForKey:
- writeToFile:atomically:

### CFString constants (189)
- `com.anlai.omnicar`
- `enabled`
- `Enabled`
- `liteMode`
- `diagCar`
- `session`
- `configuration`
- `wireless`
- `1`
- `0`
- `wired`
- `transport`
- `wifi`
- `wi-fi`
- `usb`
- `/var/mobile/Documents/OmniCar.log`
- `[OmniCar/%@] %@`
- `yyyy-MM-dd HH:mm:ss.SSS`
- `%@ [%@:%d] %@: %@
`
- `com.anlai.omnicar/log`
- `line`
- `+`
- ` `
- `%@=%@`
- `-`
- `%@%@@%@`
- `diagHooks.`
- `total`
- `missing`
- `ios`
- `iOS %@: lop CarPlay %@`
- `, `
- `iOS %@: %lu/%lu hook KHONG co tren iOS nay (tinh nang lien quan se khong chay): %@`
- `iOS %@: du %lu hook`
- `%@ %@`
- `THIEU METHOD (iOS %@): %@ -> bo qua`
- `DashBoard`
- `DB`
- `CAR`
- `_CAR`
- `launchInfoForApplication:`
- `launchInfoForApplication:withActivationSettings:`
- `Core`
- `THIEU METHOD: %@ khong tao duoc launchInfo`
- `features`
- `rescueFeatures`
- `%@ dang tat boi che do cuu (tu %@): khong cai hook trong CarPlay`
- `rescueDate`
- `%@ bat lai sau che do cuu`
- `SpringBoard`
- `CarPlay`
- `CarProbe`
- `build %s (%s) loaded into %@`
- `%@%s@%@`
- `diagLoaded.`
- `version`
- `1.0.3`
- `build`
- `fbebb21`
- `date`
- `com.apple.springboard`
- `.old`
- `NSDistributedNotificationCenter`
- `com.apple.CarPlayApp`
- `OmniCar-CarPlay-crash.txt`
- `early`
- `suspects`
- `CARPLAY SAP LAN TRUOC:
%@`
- `
`
- `omc-crash `
- `age=`
- `suspect=`
- `last=`
- `age`
- `suspect`
- `diagLastCrash`
- `CarPlay sap som %ld/%d lan lien (nghi: %@)`
- `connected`
- `disconnected`
- `CHE DO CUU: CarPlay sap %d lan lien trong %ds dau -> tat %@`
- `uncaught %@: %@
%@
`
- `points`
- `pixels`
- `scale`
- `maxFPS`
- `CARSessionStatus`
- `currentSession`
- `CarKit loi: %@`
- `man xe %@ pt, %@ px, %@ fps, session=%d`
- `do hieu nang: bat dau, %lu tweak khac trong CarPlay: %@`
- `OmniCar`
- `CarPlay do %.1fs (OmniCar gan nhat: %@)`
- `heat`
- `hangs`
- `frames`
- `che do nhe tu dong: %@%@`
- `BAT`
- `tat`
- ` vi `
- `start`
- `updated`
- `seconds`
- `fps`
- `late`
- `worstMs`
- `freezes`
- `hangMaxMs`
- `hangWho`
- `cpuAvg`
- `cpuMax`
- `memMB`
- `memMaxMB`
- `availMinMB`
- `sysFreeMinMB`
- `thermalMax`
- `lowPower`
- `tweaks`
- `liteCount`
- `liteReason`
- `diagPerf`
- `%.0fx%.0f`
- `_`
- `description`
- `debugDescription`
- `hash`
- `superclass`
- `nil`
- `...`
- `carProfilesEnabled`
- `modelName`
- `name`
- `vehicleName`
- `accessoryName`
- `model`
- `vehicleIdentifier`
- `identifier`
- `uniqueIdentifier`
- `accessoryID`
- `deviceID`
- `serialNumber`
- `%@|%@`
- `?`
- `carProfiles`
- `carProfileCurrent`
- `values`
- `ho so xe moi: %@ (%@)`
- `nap ho so xe %@ (%@)`
- `Xe`
- `Car`
- `lastSeen`
- `(null)`
- `do hieu nang: %.0fs, tre %.0f/%.0f khung, do %.0f lan (max %.0f ms), CPU tb %.0f%%, RAM %.0f MB`
- `OmniCar-crashguard.plist`
- `trustedTime`
- `splitScreenLastLeft`
- `splitScreenLastRight`
- `splitScreenSplitRatio`
- `splitScreenSplitDirection`
- `splitScreenPaneOrientation`
- `splitScreenAutoLaunch`
- `splitScreenPinnedApp`
- `speedBubbleSizeCar`
- `speedBubbleLook`
- `startupScreenVideoName`
- `startupScreenStyle`
- `startupScreenCarName`
- `startupScreenTempo`
- `appBridgeZoom`
- `vi`
- `en`
- `es`
- `pt-BR`
- `de`
- `fr`
- `it`
- `ru`
- `zh-Hans`
- `ja`
- `ko`
- `ar`
- `th`
- `id`
- `language`
- `zh`
- `2027-04-30`
- `en_US_POSIX`
- `yyyy-MM-dd`
- `%@/%@.lproj/Car.strings`
- `/Library/PreferenceBundles/OmniCarPrefs.bundle`


#### Hook & IPC của OmniCarCarProbe (bằng chứng: disassembly constructor + import)

- **Không import** `_MSHookMessageEx`/`_MSHookFunction` — không hook method nào. Đây là "đầu dò xe" chạy trong CarPlayApp: theo dõi màn hình xe (`UIScreenDidConnectNotification`/`UIScreenDidDisconnectNotification` có trong chuỗi) và phát trạng thái kết nối xe cho cả hệ.
- Sự kiện đã xác minh trong disassembly:
  - `notify_post("com.anlai.omnicar/car.connected")` (sub_7b6c)
  - `notify_post("com.anlai.omnicar/prefschanged")` (sub_5d94, sub_7b6c)
  - `notify_post("com.anlai.omnicar/rescue")` (sub_5d94)
  - `notify_register_check("com.anlai.omnicar/lite")` + `notify_post("com.anlai.omnicar/lite")` (sub_4608, sub_8e90)
  - `class_addMethod(?, "tick:", ?, "v@:@")` (sub_93b8) — mẫu dùng chung, class đích chưa xác định.


---

### 4.4. OmniCarAppBridge.dylib

- Đường dẫn cài đặt: `/var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarAppBridge.dylib`
- Kích thước file: 613,376 bytes · SHA256 (bản fat): `d99b8d00dc60f69db7b54fc1addaec6b8cb866b8dcdde6f1d85e06ce5b7d6e79`
- Slices: arm64 @off 16384, size 285488 · arm64e @off 311296, size 302080 (cả hai slice cùng danh sách thư viện + entitlements; bảng dưới đây trích slice arm64)
- Filter/điểm nạp: Filter Bundles: `com.apple.UIKit` → nạp vào **MỌI tiến trình có UIKit** (mọi app, SpringBoard, CarPlayApp)
- Số hàm theo LC_FUNCTION_STARTS (arm64): 383
- Symbol C/ObjC **định nghĩa** (export, 38):

```
_ABMissingSelector
_ABTelexApply
_OBJC_CLASS_$_ABBarButton
_OBJC_CLASS_$_ABBoxView
_OBJC_CLASS_$_ABHost
_OBJC_CLASS_$_ABKey
_OBJC_CLASS_$_ABKeyboard
_OBJC_CLASS_$_ABKnobView
_OBJC_CLASS_$_ABPane
_OBJC_CLASS_$_ABShieldView
_OBJC_METACLASS_$_ABBarButton
_OBJC_METACLASS_$_ABBoxView
_OBJC_METACLASS_$_ABHost
_OBJC_METACLASS_$_ABKey
_OBJC_METACLASS_$_ABKeyboard
_OBJC_METACLASS_$_ABKnobView
_OBJC_METACLASS_$_ABPane
_OBJC_METACLASS_$_ABShieldView
_OMCCarClass
_OMCCarLaunchInfo
_OMCCarWireless
_OMCCheckHooks
_OMCCrashGuard
_OMCCurrentLanguage
_OMCEnabled
_OMCExpired
_OMCFeatureEnabled
_OMCHasMethod
_OMCLiteActive
_OMCLogRelayStart
_OMCLogWrite
_OMCLogoMeshImage
_OMCMissingSelector
_OMCPref
_OMCPrefsSync
_OMCProfileKeys
_OMCSupportedLanguages
_OMCTr
```
- Symbol **import** (undefined, 0): danh sách đầy đủ chính là bảng import của chained-fixups — các symbol tiêu biểu được nhắc trong phần hook/IPC; toàn bộ 0 tên nằm trong file nm đi kèm hồ sơ thô.

- Install name (LC_ID_DYLIB): ('@rpath/OmniCarAppBridge.dylib', '0.0.0', '0.0.0')
- LC_BUILD_VERSION: platform=2 minos=15.0.0 sdk=16.4.0
- LC_SOURCE_VERSION: 0.0.0.0.0
- UUID (arm64 slice): 81ef5920bb7a37e8b953d88453f2ea89
- Encryption info (cryptid): 0
- RPATH: /var/jb/Library/Frameworks, /var/jb/usr/lib, @loader_path/.jbroot/Library/Frameworks, @loader_path/.jbroot/usr/lib
- Linked libraries (arm64 slice):
  - [LOAD] /usr/lib/libobjc.A.dylib (current 228.0.0, compat 1.0.0)
  - [LOAD] /System/Library/Frameworks/Foundation.framework/Foundation (current 1971.0.0, compat 300.0.0)
  - [LOAD] /System/Library/Frameworks/CoreFoundation.framework/CoreFoundation (current 1971.0.0, compat 150.0.0)
  - [LOAD] /System/Library/Frameworks/UIKit.framework/UIKit (current 6441.1.101, compat 1.0.0)
  - [LOAD] /usr/lib/libc++.1.dylib (current 1500.65.0, compat 1.0.0)
  - [LOAD] /usr/lib/libSystem.B.dylib (current 1319.100.3, compat 1.0.0)
  - [LOAD] /System/Library/Frameworks/CoreGraphics.framework/CoreGraphics (current 1690.5.4, compat 64.0.0)
  - [LOAD] /System/Library/Frameworks/QuartzCore.framework/QuartzCore (current 1.11.0, compat 1.2.0)
  - [LOAD] @rpath/CydiaSubstrate.framework/CydiaSubstrate (current 0.0.0, compat 0.0.0)
- Entitlements: KHÔNG có blob entitlements trong code signature.
- Số import (chained fixups): 241

### Classes định nghĩa trong binary (8)

#### @interface ABBoxView : (import) _OBJC_CLASS_$_UIView
- instanceSize: 88, flags: 0x184
- Ivars:
  - _handleHit : @"UIView" (offset 8, align 3, size 8)
  - _bar : @"UIView" (offset 16, align 3, size 8)
  - _passInsets : {UIEdgeInsets="top"d"left"d"bottom"d"right"d} (offset 24, align 3, size 32)
  - _hole : {CGRect="origin"{CGPoint="x"d"y"d}"size"{CGSize="width"d"height"d}} (offset 56, align 3, size 32)
- Properties:
  - passInsets  [T{UIEdgeInsets=dddd},N,V_passInsets]
  - handleHit  [T@"UIView",W,N,V_handleHit]
  - bar  [T@"UIView",W,N,V_bar]
  - hole  [T{CGRect={CGPoint=dd}{CGSize=dd}},N,V_hole]
- Instance methods (12):
  - pointInside:withEvent:  [types: B40@0:8{CGPoint=dd}16@32] @ 0x98a0
  - setHole:  [types: v48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16] @ 0x9b2c
  - applyHole  [types: v16@0:8] @ 0x9c10
  - layoutSubviews  [types: v16@0:8] @ 0x9e50
  - passInsets  [types: {UIEdgeInsets=dddd}16@0:8] @ 0x9ea8
  - setPassInsets:  [types: v48@0:8{UIEdgeInsets=dddd}16] @ 0x9ec0
  - handleHit  [types: @16@0:8] @ 0x9ed8
  - setHandleHit:  [types: v24@0:8@16] @ 0x9ef8
  - bar  [types: @16@0:8] @ 0x9f0c
  - setBar:  [types: v24@0:8@16] @ 0x9f2c
  - hole  [types: {CGRect={CGPoint=dd}{CGSize=dd}}16@0:8] @ 0x9f40
  - .cxx_destruct  [types: v16@0:8] @ 0x9f58

#### @interface ABBarButton : (import) _OBJC_CLASS_$_UIButton
- instanceSize: 8, flags: 0x80
- Instance methods (2):
  - pointInside:withEvent:  [types: B40@0:8{CGPoint=dd}16@32] @ 0x9f90
  - setHighlighted:  [types: v20@0:8B16] @ 0xa02c

#### @interface ABPane : (import) _OBJC_CLASS_$_NSObject
- instanceSize: 176, flags: 0x184
- Ivars:
  - _ready : B (offset 8, align 0, size 1)
  - _bundleID : @"NSString" (offset 16, align 3, size 8)
  - _box : @"ABBoxView" (offset 24, align 3, size 8)
  - _application : @ (offset 32, align 3, size 8)
  - _appViewController : @ (offset 40, align 3, size 8)
  - _sceneMonitor : @ (offset 48, align 3, size 8)
  - _orientation : q (offset 56, align 3, size 8)
  - _requestedOrientation : q (offset 64, align 3, size 8)
  - _handle : @"UIView" (offset 72, align 3, size 8)
  - _handleHit : @"UIView" (offset 80, align 3, size 8)
  - _bar : @"UIView" (offset 88, align 3, size 8)
  - _popButton : @"UIButton" (offset 96, align 3, size 8)
  - _soloButton : @"UIButton" (offset 104, align 3, size 8)
  - _handleOffset : d (offset 112, align 3, size 8)
  - _shield : @"UIView" (offset 120, align 3, size 8)
  - _sceneBox : {CGSize="width"d"height"d} (offset 128, align 3, size 16)
  - _frame : {CGRect="origin"{CGPoint="x"d"y"d}"size"{CGSize="width"d"height"d}} (offset 144, align 3, size 32)
- Properties:
  - bundleID  [T@"NSString",C,N,V_bundleID]
  - box  [T@"ABBoxView",&,N,V_box]
  - application  [T@,&,N,V_application]
  - appViewController  [T@,&,N,V_appViewController]
  - sceneMonitor  [T@,&,N,V_sceneMonitor]
  - orientation  [Tq,N,V_orientation]
  - requestedOrientation  [Tq,N,V_requestedOrientation]
  - frame  [T{CGRect={CGPoint=dd}{CGSize=dd}},N,V_frame]
  - sceneBox  [T{CGSize=dd},N,V_sceneBox]
  - ready  [TB,N,V_ready]
  - handle  [T@"UIView",&,N,V_handle]
  - handleHit  [T@"UIView",&,N,V_handleHit]
  - bar  [T@"UIView",&,N,V_bar]
  - popButton  [T@"UIButton",&,N,V_popButton]
  - soloButton  [T@"UIButton",&,N,V_soloButton]
  - handleOffset  [Td,N,V_handleOffset]
  - shield  [T@"UIView",&,N,V_shield]
- Instance methods (35):
  - bundleID  [types: @16@0:8] @ 0xa180
  - setBundleID:  [types: v24@0:8@16] @ 0xa188
  - box  [types: @16@0:8] @ 0xa190
  - setBox:  [types: v24@0:8@16] @ 0xa198
  - application  [types: @16@0:8] @ 0xa1c8
  - setApplication:  [types: v24@0:8@16] @ 0xa1d0
  - appViewController  [types: @16@0:8] @ 0xa200
  - setAppViewController:  [types: v24@0:8@16] @ 0xa208
  - sceneMonitor  [types: @16@0:8] @ 0xa238
  - setSceneMonitor:  [types: v24@0:8@16] @ 0xa240
  - orientation  [types: q16@0:8] @ 0xa270
  - setOrientation:  [types: v24@0:8q16] @ 0xa278
  - requestedOrientation  [types: q16@0:8] @ 0xa280
  - setRequestedOrientation:  [types: v24@0:8q16] @ 0xa288
  - frame  [types: {CGRect={CGPoint=dd}{CGSize=dd}}16@0:8] @ 0xa290
  - setFrame:  [types: v48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16] @ 0xa29c
  - sceneBox  [types: {CGSize=dd}16@0:8] @ 0xa2a8
  - setSceneBox:  [types: v32@0:8{CGSize=dd}16] @ 0xa2b0
  - ready  [types: B16@0:8] @ 0xa2b8
  - setReady:  [types: v20@0:8B16] @ 0xa2c0
  - handle  [types: @16@0:8] @ 0xa2c8
  - setHandle:  [types: v24@0:8@16] @ 0xa2d0
  - handleHit  [types: @16@0:8] @ 0xa300
  - setHandleHit:  [types: v24@0:8@16] @ 0xa308
  - bar  [types: @16@0:8] @ 0xa338
  - setBar:  [types: v24@0:8@16] @ 0xa340
  - popButton  [types: @16@0:8] @ 0xa370
  - setPopButton:  [types: v24@0:8@16] @ 0xa378
  - soloButton  [types: @16@0:8] @ 0xa3a8
  - setSoloButton:  [types: v24@0:8@16] @ 0xa3b0
  - handleOffset  [types: d16@0:8] @ 0xa3e0
  - setHandleOffset:  [types: v24@0:8d16] @ 0xa3e8
  - shield  [types: @16@0:8] @ 0xa3f0
  - setShield:  [types: v24@0:8@16] @ 0xa3f8
  - .cxx_destruct  [types: v16@0:8] @ 0xa428

#### @interface ABShieldView : (import) _OBJC_CLASS_$_UIView
- instanceSize: 8, flags: 0x80
- Instance methods (1):
  - touchesBegan:withEvent:  [types: v32@0:8@16@24] @ 0xa4c4

#### @interface ABKnobView : (import) _OBJC_CLASS_$_UIView
- instanceSize: 40, flags: 0x184
- Ivars:
  - _index : i (offset 8, align 2, size 4)
  - _dot : @"UIView" (offset 16, align 3, size 8)
  - _lastSent : {CGPoint="x"d"y"d} (offset 24, align 3, size 16)
- Properties:
  - index  [Ti,N,V_index]
  - lastSent  [T{CGPoint=dd},N,V_lastSent]
  - dot  [T@"UIView",&,N,V_dot]
- Instance methods (12):
  - relay:touches:  [types: v28@0:8i16@20] @ 0xa58c
  - touchesBegan:withEvent:  [types: v32@0:8@16@24] @ 0xa90c
  - touchesMoved:withEvent:  [types: v32@0:8@16@24] @ 0xa918
  - touchesEnded:withEvent:  [types: v32@0:8@16@24] @ 0xa924
  - touchesCancelled:withEvent:  [types: v32@0:8@16@24] @ 0xa930
  - index  [types: i16@0:8] @ 0xa93c
  - setIndex:  [types: v20@0:8i16] @ 0xa94c
  - lastSent  [types: {CGPoint=dd}16@0:8] @ 0xa95c
  - setLastSent:  [types: v32@0:8{CGPoint=dd}16] @ 0xa970
  - dot  [types: @16@0:8] @ 0xa984
  - setDot:  [types: v24@0:8@16] @ 0xa994
  - .cxx_destruct  [types: v16@0:8] @ 0xa9d4

#### @interface ABHost : (import) _OBJC_CLASS_$_NSObject
- instanceSize: 80, flags: 0x184
- Ivars:
  - _shieldOn : B (offset 8, align 0, size 1)
  - _window : @"UIWindow" (offset 16, align 3, size 8)
  - _displayID : @"NSString" (offset 24, align 3, size 8)
  - _panes : @"NSMutableArray" (offset 32, align 3, size 8)
  - _knobViews : @"NSMutableArray" (offset 40, align 3, size 8)
  - _carAppArea : {CGRect="origin"{CGPoint="x"d"y"d}"size"{CGSize="width"d"height"d}} (offset 48, align 3, size 32)
- Properties:
  - window  [T@"UIWindow",&,N,V_window]
  - shieldOn  [TB,N,V_shieldOn]
  - displayID  [T@"NSString",C,N,V_displayID]
  - panes  [T@"NSMutableArray",&,N,V_panes]
  - knobViews  [T@"NSMutableArray",&,N,V_knobViews]
  - carAppArea  [T{CGRect={CGPoint=dd}{CGSize=dd}},N,V_carAppArea]
- Instance methods (61):
  - count  [types: Q16@0:8] @ 0xaaa0
  - hostsApp:  [types: B24@0:8@16] @ 0xaaf0
  - paneFor:  [types: @24@0:8@16] @ 0xac84
  - zoom  [types: d16@0:8] @ 0xae20
  - ensureWindow  [types: B16@0:8] @ 0xaea8
  - dropWindowIfEmpty  [types: v16@0:8] @ 0xb89c
  - openApp:frame:  [types: v56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24] @ 0xb8a0
  - revealPane:  [types: v24@0:8@16] @ 0xc178
  - setupLiveAppViewForPane:  [types: v24@0:8@16] @ 0xc2bc
  - sceneMonitor:sceneWasDestroyed:  [types: v32@0:8@16@24] @ 0xe9e8
  - layoutPane:  [types: v24@0:8@16] @ 0xec80
  - effectiveOrientation:  [types: q24@0:8@16] @ 0xf364
  - carWindow  [types: @16@0:8] @ 0xf3d0
  - bundleForHash:  [types: @24@0:8Q16] @ 0xf40c
  - frameOfApp:  [types: {CGRect={CGPoint=dd}{CGSize=dd}}24@0:8@16] @ 0xf5ec
  - appWithHash:changedOrientation:supportedMask:  [types: v36@0:8Q16i24Q28] @ 0xf6b0
  - nudgePane:  [types: v24@0:8@16] @ 0xf9ac
  - setFrame:forApp:live:handle:passInsets:  [types: v96@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16@48B56B60{UIEdgeInsets=dddd}64] @ 0xfe68
  - setPassInsets:forApp:  [types: v56@0:8{UIEdgeInsets=dddd}16@48] @ 0x1038c
  - setCornerRadius:corners:forApp:  [types: v40@0:8d16Q24@32] @ 0x10438
  - buildBarForPane:  [types: @24@0:8@16] @ 0x105b8
  - layoutBarForPane:  [types: v24@0:8@16] @ 0x11690
  - setBarVisible:pop:dim:single:forApp:  [types: v40@0:8B16i20B24B28@32] @ 0x11868
  - hideBarForPane:  [types: v24@0:8@16] @ 0x12610
  - setShieldAll:  [types: v20@0:8B16] @ 0x128a4
  - setShield:forPane:  [types: v28@0:8B16@20] @ 0x129d8
  - setHole:forApp:  [types: v56@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16@48] @ 0x12ce4
  - outsideTouched  [types: v16@0:8] @ 0x12e08
  - paneOfBarButton:  [types: @24@0:8@16] @ 0x12f78
  - postBarAction:from:  [types: v32@0:8@16@24] @ 0x13148
  - barReplace:  [types: v24@0:8@16] @ 0x13378
  - barPop:  [types: v24@0:8@16] @ 0x13388
  - barFull:  [types: v24@0:8@16] @ 0x13398
  - barBackground:  [types: v24@0:8@16] @ 0x133a8
  - barClose:  [types: v24@0:8@16] @ 0x133b8
  - setupHandleForPane:  [types: v24@0:8@16] @ 0x133c8
  - setHandleVisible:forPane:  [types: v28@0:8B16@20] @ 0x137cc
  - raiseKnobs  [types: v16@0:8] @ 0x13918
  - setKnobs:  [types: v24@0:8@16] @ 0x13abc
  - setHandleOffset:forApp:  [types: v32@0:8d16@24] @ 0x14c7c
  - handlePanned:  [types: v24@0:8@16] @ 0x14d34
  - setFront:forApp:  [types: v28@0:8B16@20] @ 0x151a8
  - handleTapped:  [types: v24@0:8@16] @ 0x152d4
  - teardownPane:  [types: v24@0:8@16] @ 0x155b0
  - closeApp:terminate:  [types: v28@0:8@16B24] @ 0x15ca0
  - closeAll  [types: v16@0:8] @ 0x160ec
  - closeAllExcept:  [types: v24@0:8@16] @ 0x160f4
  - carDisconnected  [types: v16@0:8] @ 0x163e8
  - carAppArea  [types: {CGRect={CGPoint=dd}{CGSize=dd}}16@0:8] @ 0x166b4
  - setCarAppArea:  [types: v48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16] @ 0x166c0
  - window  [types: @16@0:8] @ 0x166cc
  - setWindow:  [types: v24@0:8@16] @ 0x166d4
  - shieldOn  [types: B16@0:8] @ 0x16704
  - setShieldOn:  [types: v20@0:8B16] @ 0x1670c
  - displayID  [types: @16@0:8] @ 0x16714
  - setDisplayID:  [types: v24@0:8@16] @ 0x1671c
  - panes  [types: @16@0:8] @ 0x16724
  - setPanes:  [types: v24@0:8@16] @ 0x1672c
  - knobViews  [types: @16@0:8] @ 0x1675c
  - setKnobViews:  [types: v24@0:8@16] @ 0x16764
  - .cxx_destruct  [types: v16@0:8] @ 0x16794
- Class methods (1):
  - shared  [types: @16@0:8] @ 0xa9e8

#### @interface ABKey : (import) _OBJC_CLASS_$_UIButton
- instanceSize: 72, flags: 0x184
- Ivars:
  - _lit : B (offset 8, align 0, size 1)
  - _value : @"NSString" (offset 16, align 3, size 8)
  - _command : @"NSString" (offset 24, align 3, size 8)
  - _weight : d (offset 32, align 3, size 8)
  - _restColor : @"UIColor" (offset 40, align 3, size 8)
  - _restTint : @"UIColor" (offset 48, align 3, size 8)
  - _hint : @"UILabel" (offset 56, align 3, size 8)
  - _accent : @"CAGradientLayer" (offset 64, align 3, size 8)
- Properties:
  - value  [T@"NSString",C,N,V_value]
  - command  [T@"NSString",C,N,V_command]
  - weight  [Td,N,V_weight]
  - lit  [TB,N,V_lit]
  - restColor  [T@"UIColor",&,N,V_restColor]
  - restTint  [T@"UIColor",&,N,V_restTint]
  - hint  [T@"UILabel",&,N,V_hint]
  - accent  [T@"CAGradientLayer",&,N,V_accent]
- Instance methods (20):
  - paint:  [types: v20@0:8B16] @ 0x181dc
  - setHighlighted:  [types: v20@0:8B16] @ 0x187d4
  - layoutSubviews  [types: v16@0:8] @ 0x189c8
  - value  [types: @16@0:8] @ 0x18afc
  - setValue:  [types: v24@0:8@16] @ 0x18b0c
  - command  [types: @16@0:8] @ 0x18b18
  - setCommand:  [types: v24@0:8@16] @ 0x18b28
  - weight  [types: d16@0:8] @ 0x18b34
  - setWeight:  [types: v24@0:8d16] @ 0x18b44
  - lit  [types: B16@0:8] @ 0x18b54
  - setLit:  [types: v20@0:8B16] @ 0x18b64
  - restColor  [types: @16@0:8] @ 0x18b74
  - setRestColor:  [types: v24@0:8@16] @ 0x18b84
  - restTint  [types: @16@0:8] @ 0x18bc4
  - setRestTint:  [types: v24@0:8@16] @ 0x18bd4
  - hint  [types: @16@0:8] @ 0x18c14
  - setHint:  [types: v24@0:8@16] @ 0x18c24
  - accent  [types: @16@0:8] @ 0x18c64
  - setAccent:  [types: v24@0:8@16] @ 0x18c74
  - .cxx_destruct  [types: v16@0:8] @ 0x18cb4

#### @interface ABKeyboard : (import) _OBJC_CLASS_$_NSObject
- instanceSize: 120, flags: 0x184
- Ivars:
  - _numbers : B (offset 8, align 0, size 1)
  - _shift : B (offset 9, align 0, size 1)
  - _vietnamese : B (offset 10, align 0, size 1)
  - _app : @"NSString" (offset 16, align 3, size 8)
  - _panel : @"UIView" (offset 24, align 3, size 8)
  - _glass : @"UIVisualEffectView" (offset 32, align 3, size 8)
  - _bubble : @"UILabel" (offset 40, align 3, size 8)
  - _field : @"UIView" (offset 48, align 3, size 8)
  - _preview : @"UILabel" (offset 56, align 3, size 8)
  - _langButton : @"UIButton" (offset 64, align 3, size 8)
  - _hideButton : @"UIButton" (offset 72, align 3, size 8)
  - _keysView : @"UIView" (offset 80, align 3, size 8)
  - _rows : @"NSMutableArray" (offset 88, align 3, size 8)
  - _returnType : q (offset 96, align 3, size 8)
  - _word : @"NSMutableString" (offset 104, align 3, size 8)
  - _typed : @"NSMutableString" (offset 112, align 3, size 8)
- Properties:
  - app  [T@"NSString",C,N,V_app]
  - panel  [T@"UIView",&,N,V_panel]
  - glass  [T@"UIVisualEffectView",&,N,V_glass]
  - bubble  [T@"UILabel",&,N,V_bubble]
  - field  [T@"UIView",&,N,V_field]
  - preview  [T@"UILabel",&,N,V_preview]
  - langButton  [T@"UIButton",&,N,V_langButton]
  - hideButton  [T@"UIButton",&,N,V_hideButton]
  - keysView  [T@"UIView",&,N,V_keysView]
  - rows  [T@"NSMutableArray",&,N,V_rows]
  - numbers  [TB,N,V_numbers]
  - shift  [TB,N,V_shift]
  - vietnamese  [TB,N,V_vietnamese]
  - returnType  [Tq,N,V_returnType]
  - word  [T@"NSMutableString",&,N,V_word]
  - typed  [T@"NSMutableString",&,N,V_typed]
- Instance methods (48):
  - showForApp:keyboardType:returnType:  [types: v40@0:8@16q24q32] @ 0x18db4
  - hideForApp:  [types: v24@0:8@16] @ 0x1935c
  - layoutPanelIn:  [types: v24@0:8@16] @ 0x196d0
  - key:pressed:  [types: v28@0:8@16B24] @ 0x199cc
  - buildPanel  [types: v16@0:8] @ 0x1a200
  - key:symbol:value:command:weight:  [types: @56@0:8@16@24@32@40d48] @ 0x1abb0
  - key:value:command:weight:  [types: @48@0:8@16@24@32d40] @ 0x1b408
  - rebuildKeys  [types: v16@0:8] @ 0x1b430
  - layoutKeys  [types: v16@0:8] @ 0x1bf5c
  - updatePreview  [types: v16@0:8] @ 0x1c5c8
  - langTapped  [types: v16@0:8] @ 0x1c7b8
  - send:del:text:  [types: v40@0:8@16Q24@32] @ 0x1c81c
  - typeCharacter:  [types: v24@0:8@16] @ 0x1ca2c
  - keyTapped:  [types: v24@0:8@16] @ 0x1cdd4
  - hideTapped  [types: v16@0:8] @ 0x1d244
  - app  [types: @16@0:8] @ 0x1d27c
  - setApp:  [types: v24@0:8@16] @ 0x1d284
  - panel  [types: @16@0:8] @ 0x1d28c
  - setPanel:  [types: v24@0:8@16] @ 0x1d294
  - glass  [types: @16@0:8] @ 0x1d2c4
  - setGlass:  [types: v24@0:8@16] @ 0x1d2cc
  - bubble  [types: @16@0:8] @ 0x1d2fc
  - setBubble:  [types: v24@0:8@16] @ 0x1d304
  - field  [types: @16@0:8] @ 0x1d334
  - setField:  [types: v24@0:8@16] @ 0x1d33c
  - preview  [types: @16@0:8] @ 0x1d36c
  - setPreview:  [types: v24@0:8@16] @ 0x1d374
  - langButton  [types: @16@0:8] @ 0x1d3a4
  - setLangButton:  [types: v24@0:8@16] @ 0x1d3ac
  - hideButton  [types: @16@0:8] @ 0x1d3dc
  - setHideButton:  [types: v24@0:8@16] @ 0x1d3e4
  - keysView  [types: @16@0:8] @ 0x1d414
  - setKeysView:  [types: v24@0:8@16] @ 0x1d41c
  - rows  [types: @16@0:8] @ 0x1d44c
  - setRows:  [types: v24@0:8@16] @ 0x1d454
  - numbers  [types: B16@0:8] @ 0x1d484
  - setNumbers:  [types: v20@0:8B16] @ 0x1d48c
  - shift  [types: B16@0:8] @ 0x1d494
  - setShift:  [types: v20@0:8B16] @ 0x1d49c
  - vietnamese  [types: B16@0:8] @ 0x1d4a4
  - setVietnamese:  [types: v20@0:8B16] @ 0x1d4ac
  - returnType  [types: q16@0:8] @ 0x1d4b4
  - setReturnType:  [types: v24@0:8q16] @ 0x1d4bc
  - word  [types: @16@0:8] @ 0x1d4c4
  - setWord:  [types: v24@0:8@16] @ 0x1d4cc
  - typed  [types: @16@0:8] @ 0x1d4fc
  - setTyped:  [types: v24@0:8@16] @ 0x1d504
  - .cxx_destruct  [types: v16@0:8] @ 0x1d534
- Class methods (1):
  - shared  [types: @16@0:8] @ 0x18d44

### Protocols định nghĩa (3)

#### @protocol NSObject
- Required instance methods:
  - isEqual:  [types: B24@0:8@16] @ 0x28c10
  - class  [types: #16@0:8] @ 0x28c1c
  - self  [types: @16@0:8] @ 0x28c28
  - performSelector:  [types: @24@0:8:16] @ 0x28c34
  - performSelector:withObject:  [types: @32@0:8:16@24] @ 0x28c40
  - performSelector:withObject:withObject:  [types: @40@0:8:16@24@32] @ 0x28c4c
  - isProxy  [types: B16@0:8] @ 0x28c58
  - isKindOfClass:  [types: B24@0:8#16] @ 0x28c64
  - isMemberOfClass:  [types: B24@0:8#16] @ 0x28c70
  - conformsToProtocol:  [types: B24@0:8@16] @ 0x28c7c
  - respondsToSelector:  [types: B24@0:8:16] @ 0x28c88
  - retain  [types: @16@0:8] @ 0x28c94
  - release  [types: Vv16@0:8] @ 0x28ca0
  - autorelease  [types: @16@0:8] @ 0x28cac
  - retainCount  [types: Q16@0:8] @ 0x28cb8
  - zone  [types: ^{_NSZone=}16@0:8] @ 0x28cc4
  - hash  [types: Q16@0:8] @ 0x28cd0
  - superclass  [types: #16@0:8] @ 0x28cdc
  - description  [types: @16@0:8] @ 0x28ce8
- Optional instance methods:
  - debugDescription  [types: @16@0:8] @ 0x28d00
- Properties:
  - hash  [TQ,R]
  - superclass  [T#,R]
  - description  [T@"NSString",R,C]
  - debugDescription  [T@"NSString",?,R,C]

#### @protocol UITextInputTraits
- Optional instance methods:
  - autocapitalizationType  [types: q16@0:8] @ 0x28d18
  - setAutocapitalizationType:  [types: v24@0:8q16] @ 0x28d24
  - autocorrectionType  [types: q16@0:8] @ 0x28d30
  - setAutocorrectionType:  [types: v24@0:8q16] @ 0x28d3c
  - spellCheckingType  [types: q16@0:8] @ 0x28d48
  - setSpellCheckingType:  [types: v24@0:8q16] @ 0x28d54
  - smartQuotesType  [types: q16@0:8] @ 0x28d60
  - setSmartQuotesType:  [types: v24@0:8q16] @ 0x28d6c
  - smartDashesType  [types: q16@0:8] @ 0x28d78
  - setSmartDashesType:  [types: v24@0:8q16] @ 0x28d84
  - smartInsertDeleteType  [types: q16@0:8] @ 0x28d90
  - setSmartInsertDeleteType:  [types: v24@0:8q16] @ 0x28d9c
  - keyboardType  [types: q16@0:8] @ 0x28da8
  - setKeyboardType:  [types: v24@0:8q16] @ 0x28db4
  - keyboardAppearance  [types: q16@0:8] @ 0x28dc0
  - setKeyboardAppearance:  [types: v24@0:8q16] @ 0x28dcc
  - returnKeyType  [types: q16@0:8] @ 0x28dd8
  - setReturnKeyType:  [types: v24@0:8q16] @ 0x28de4
  - enablesReturnKeyAutomatically  [types: B16@0:8] @ 0x28df0
  - setEnablesReturnKeyAutomatically:  [types: v20@0:8B16] @ 0x28dfc
  - isSecureTextEntry  [types: B16@0:8] @ 0x28e08
  - setSecureTextEntry:  [types: v20@0:8B16] @ 0x28e14
  - textContentType  [types: @16@0:8] @ 0x28e20
  - setTextContentType:  [types: v24@0:8@16] @ 0x28e2c
  - passwordRules  [types: @16@0:8] @ 0x28e38
  - setPasswordRules:  [types: v24@0:8@16] @ 0x28e44
- Properties:
  - autocapitalizationType  [Tq,?,N]
  - autocorrectionType  [Tq,?,N]
  - spellCheckingType  [Tq,?,N]
  - smartQuotesType  [Tq,?,N]
  - smartDashesType  [Tq,?,N]
  - smartInsertDeleteType  [Tq,?,N]
  - keyboardType  [Tq,?,N]
  - keyboardAppearance  [Tq,?,N]
  - returnKeyType  [Tq,?,N]
  - enablesReturnKeyAutomatically  [TB,?,N]
  - secureTextEntry  [TB,?,N,GisSecureTextEntry]
  - textContentType  [T@"NSString",?,C,N]
  - passwordRules  [T@"UITextInputPasswordRules",?,C,N]

#### @protocol UIKeyInput
- Required instance methods:
  - insertText:  [types: v24@0:8@16] @ 0x28e58
  - deleteBackward  [types: v16@0:8] @ 0x28e64
  - hasText  [types: B16@0:8] @ 0x28e70
- Properties:
  - hasText  [TB,R,N]

### __objc_classrefs (60 refs)
- ABBarButton
- ABBoxView
- ABHost
- ABKey
- ABKeyboard
- ABKnobView
- ABPane
- ABShieldView
- _OBJC_CLASS_$_CAGradientLayer
- _OBJC_CLASS_$_CALayer
- _OBJC_CLASS_$_CAShapeLayer
- _OBJC_CLASS_$_CATransaction
- _OBJC_CLASS_$_NSArray
- _OBJC_CLASS_$_NSBundle
- _OBJC_CLASS_$_NSCharacterSet
- _OBJC_CLASS_$_NSDate
- _OBJC_CLASS_$_NSDateFormatter
- _OBJC_CLASS_$_NSDictionary
- _OBJC_CLASS_$_NSException
- _OBJC_CLASS_$_NSFileManager
- _OBJC_CLASS_$_NSHashTable
- _OBJC_CLASS_$_NSInvocation
- _OBJC_CLASS_$_NSLocale
- _OBJC_CLASS_$_NSMutableArray
- _OBJC_CLASS_$_NSMutableDictionary
- _OBJC_CLASS_$_NSMutableOrderedSet
- _OBJC_CLASS_$_NSMutableSet
- _OBJC_CLASS_$_NSMutableString
- _OBJC_CLASS_$_NSNotificationCenter
- _OBJC_CLASS_$_NSNull
- _OBJC_CLASS_$_NSNumber
- _OBJC_CLASS_$_NSObject
- _OBJC_CLASS_$_NSOperationQueue
- _OBJC_CLASS_$_NSProcessInfo
- _OBJC_CLASS_$_NSRunLoop
- _OBJC_CLASS_$_NSString
- _OBJC_CLASS_$_NSTimeZone
- _OBJC_CLASS_$_UIApplication
- _OBJC_CLASS_$_UIBezierPath
- _OBJC_CLASS_$_UIBlurEffect
- _OBJC_CLASS_$_UIButton
- _OBJC_CLASS_$_UIColor
- _OBJC_CLASS_$_UICubicTimingParameters
- _OBJC_CLASS_$_UIDevice
- _OBJC_CLASS_$_UIFont
- _OBJC_CLASS_$_UIGraphicsImageRenderer
- _OBJC_CLASS_$_UIGraphicsImageRendererFormat
- _OBJC_CLASS_$_UIImage
- _OBJC_CLASS_$_UIImageSymbolConfiguration
- _OBJC_CLASS_$_UIImageView
- _OBJC_CLASS_$_UILabel
- _OBJC_CLASS_$_UIPanGestureRecognizer
- _OBJC_CLASS_$_UIScreen
- _OBJC_CLASS_$_UITapGestureRecognizer
- _OBJC_CLASS_$_UITextField
- _OBJC_CLASS_$_UIView
- _OBJC_CLASS_$_UIViewPropertyAnimator
- _OBJC_CLASS_$_UIVisualEffectView
- _OBJC_CLASS_$_UIWindow
- _OBJC_CLASS_$_UIWindowScene

### __objc_superrefs (3 refs)
- ABBarButton
- ABBoxView
- ABKey

### Selector refs — các selector binary tham chiếu (529)
- .cxx_destruct
- CGColor
- CGContext
- CGPath
- UTF8String
- _setRotatableViewOrientation:duration:force:
- _shouldBeBackgroundUnderLockForScene:withSettings:
- _updateReferenceSize:andOrientation:
- accent
- addAnimations:
- addArcWithCenter:radius:startAngle:endAngle:clockwise:
- addCompletion:
- addGestureRecognizer:
- addLineToPoint:
- addObject:
- addObjectsFromArray:
- addObserverForName:object:queue:usingBlock:
- addSublayer:
- addSubview:
- addTarget:action:forControlEvents:
- addToRunLoop:forMode:
- allObjects
- alpha
- animateWithDuration:animations:
- animateWithDuration:animations:completion:
- animateWithDuration:delay:options:animations:completion:
- animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:
- anyObject
- app
- appViewController
- appWithHash:changedOrientation:supportedMask:
- appendPath:
- appendString:
- application
- applicationDidFinishLaunching:
- applyHole
- array
- arrayByAddingObject:
- arrayWithArray:
- arrayWithObjects:count:
- attemptRotationToDeviceOrientation
- attributesOfItemAtPath:error:
- autocapitalizationType
- autocorrectionType
- autorelease
- bar
- barBackground:
- barClose:
- barFull:
- barPop:
- barReplace:
- becomeFirstResponder
- begin
- beginGeneratingDeviceOrientationNotifications
- bezierPath
- bezierPathWithRect:
- bezierPathWithRoundedRect:cornerRadius:
- blackColor
- boolValue
- bounds
- box
- bringSubviewToFront:
- bubble
- buildBarForPane:
- buildPanel
- bundleForHash:
- bundleID
- bundleIdentifier
- bundlePath
- buttonWithType:
- callStackReturnAddresses
- callStackSymbols
- carAppArea
- carDisconnected
- carWindow
- characterAtIndex:
- characterIsMember:
- childViewControllers
- class
- clearColor
- closeAll
- closeAllExcept:
- closeApp:terminate:
- colorWithAlphaComponent:
- colorWithRed:green:blue:alpha:
- colorWithWhite:alpha:
- command
- commit
- componentsJoinedByString:
- componentsSeparatedByCharactersInSet:
- componentsSeparatedByString:
- configurationWithPointSize:weight:
- conformsToProtocol:
- connectedScenes
- containsObject:
- containsString:
- contentView
- convertRect:fromView:
- copy
- cornerRadius
- count
- countByEnumeratingWithState:objects:count:
- currentDevice
- date
- dateFromString:
- debugDescription
- defaultCenter
- defaultManager
- delegate
- deleteBackward
- deleteCharactersInRange:
- description
- dictionary
- dictionaryWithContentsOfFile:
- dictionaryWithObjects:forKeys:count:
- displayID
- displayLinkWithTarget:selector:
- dot
- doubleValue
- dropWindowIfEmpty
- effectWithStyle:
- effectiveOrientation:
- enablesReturnKeyAutomatically
- ensureWindow
- field
- fileModificationDate
- fileSize
- fileSystemRepresentation
- fill
- firstObject
- floatValue
- frame
- frameOfApp:
- getArgumentTypeAtIndex:
- getReturnValue:
- glass
- handle
- handleHit
- handleOffset
- handlePanned:
- handleTapped:
- hasPrefix:
- hasText
- hash
- hideBarForPane:
- hideButton
- hideForApp:
- hideTapped
- hint
- hitTest:withEvent:
- hole
- hostsApp:
- imageWithActions:
- imageWithRenderingMode:
- index
- initWithControlPoint1:controlPoint2:
- initWithDuration:timingParameters:
- initWithEffect:
- initWithFrame:
- initWithImage:
- initWithSize:
- initWithSize:format:
- initWithTarget:action:
- inputView
- insertObject:atIndex:
- insertSublayer:atIndex:
- insertSublayer:below:
- insertSubview:atIndex:
- insertText:
- intValue
- integerValue
- interfaceOrientations
- invalidate
- invocationWithMethodSignature:
- invoke
- isBeingDismissed
- isDescendantOfView:
- isEditable
- isEqual:
- isEqualToString:
- isFirstResponder
- isHidden
- isHighlighted
- isKeyWindow
- isKindOfClass:
- isLowPowerModeEnabled
- isMemberOfClass:
- isProxy
- isSecureTextEntry
- isViewLoaded
- key:pressed:
- key:symbol:value:command:weight:
- key:value:command:weight:
- keyTapped:
- keyboardAppearance
- keyboardType
- keysView
- knobViews
- langButton
- langTapped
- lastObject
- lastPathComponent
- lastSent
- layer
- layoutBarForPane:
- layoutKeys
- layoutPane:
- layoutPanelIn:
- layoutSubviews
- length
- letterCharacterSet
- lit
- localeWithLocaleIdentifier:
- locationInView:
- longLongValue
- lowercaseString
- mainBundle
- mainQueue
- mainRunLoop
- mainScreen
- makeObjectsPerformSelector:
- mask
- maximumFramesPerSecond
- methodReturnLength
- methodSignatureForSelector:
- moveItemAtPath:toPath:error:
- moveToPoint:
- mutableCopy
- name
- nativeBounds
- newlineCharacterSet
- nudgePane:
- null
- numberOfArguments
- numberWithBool:
- numberWithDouble:
- numberWithFloat:
- numberWithInt:
- numberWithInteger:
- numberWithLong:
- numberWithLongLong:
- numberWithUnsignedInteger:
- numbers
- object
- objectAtIndexedSubscript:
- objectForKeyedSubscript:
- opacity
- openApp:frame:
- orderedSet
- orderedSetWithArray:
- orientation
- outsideTouched
- paint:
- paneFor:
- paneOfBarButton:
- panel
- panes
- passInsets
- passwordRules
- performSelector:
- performSelector:withObject:
- performSelector:withObject:withObject:
- pointInside:withEvent:
- popButton
- postBarAction:from:
- postNotificationName:object:
- postNotificationName:object:userInfo:
- preferredFormat
- preferredLanguages
- presentedViewController
- preview
- processInfo
- processName
- raise:format:
- raiseKnobs
- rangeOfString:
- rangeOfString:options:
- ready
- reason
- rebuildKeys
- relay:touches:
- release
- removeAllObjects
- removeFromSuperlayer
- removeFromSuperview
- removeItemAtPath:error:
- removeLastObject
- removeObject:
- replaceCharactersInRange:withString:
- requestGeometryUpdateWithPreferences:errorHandler:
- requestedOrientation
- resignFirstResponder
- respondsToSelector:
- restColor
- restTint
- retain
- retainArguments
- retainCount
- returnKeyType
- returnType
- revealPane:
- rootViewController
- rows
- scale
- sceneBox
- sceneMonitor
- sceneMonitor:sceneWasDestroyed:
- screens
- self
- send:del:text:
- sendActionsForControlEvents:
- set
- setAccent:
- setAccessibilityLabel:
- setAdjustsFontSizeToFitWidth:
- setAlpha:
- setAnchorPoint:
- setApp:
- setAppViewController:
- setApplication:
- setArgument:atIndex:
- setAutocapitalizationType:
- setAutocorrectionType:
- setAutoresizingMask:
- setBackgroundColor:
- setBar:
- setBarVisible:pop:dim:single:forApp:
- setBorderColor:
- setBorderWidth:
- setBounds:
- setBox:
- setBubble:
- setBundleID:
- setCarAppArea:
- setCenter:
- setClipsToBounds:
- setColors:
- setCommand:
- setContentMode:
- setCornerCurve:
- setCornerRadius:
- setCornerRadius:corners:forApp:
- setDateFormat:
- setDisableActions:
- setDisplayID:
- setDot:
- setEnablesReturnKeyAutomatically:
- setEndPoint:
- setField:
- setFill
- setFillRule:
- setFont:
- setFrame:
- setFrame:forApp:live:handle:passInsets:
- setFront:forApp:
- setGlass:
- setHandle:
- setHandleHit:
- setHandleOffset:
- setHandleOffset:forApp:
- setHandleVisible:forPane:
- setHidden:
- setHideButton:
- setHighlighted:
- setHint:
- setHole:
- setHole:forApp:
- setImage:
- setImage:forState:
- setIndex:
- setInputView:
- setKeyboardAppearance:
- setKeyboardType:
- setKeysView:
- setKnobViews:
- setKnobs:
- setLangButton:
- setLastSent:
- setLineBreakMode:
- setLineCapStyle:
- setLineJoinStyle:
- setLineWidth:
- setLit:
- setLocale:
- setMask:
- setMaskedCorners:
- setMasksToBounds:
- setMaximumNumberOfTouches:
- setMultipleTouchEnabled:
- setName:
- setNeedsUpdateOfSupportedInterfaceOrientations
- setNumbers:
- setObject:forKeyedSubscript:
- setOpacity:
- setOpaque:
- setOrientation:
- setOrientation:animated:
- setPanel:
- setPanes:
- setPassInsets:
- setPassInsets:forApp:
- setPasswordRules:
- setPath:
- setPopButton:
- setPreferredFrameRateRange:
- setPreferredFramesPerSecond:
- setPreview:
- setReady:
- setRequestedOrientation:
- setRestColor:
- setRestTint:
- setReturnKeyType:
- setReturnType:
- setRows:
- setScale:
- setSceneBox:
- setSceneMonitor:
- setSecureTextEntry:
- setSelector:
- setShadowColor:
- setShadowOffset:
- setShadowOpacity:
- setShadowPath:
- setShadowRadius:
- setShield:
- setShield:forPane:
- setShieldAll:
- setShieldOn:
- setShift:
- setSmartDashesType:
- setSmartInsertDeleteType:
- setSmartQuotesType:
- setSoloButton:
- setSpellCheckingType:
- setStartPoint:
- setString:
- setTag:
- setTarget:
- setText:
- setTextAlignment:
- setTextColor:
- setTextContentType:
- setTimeZone:
- setTintColor:
- setTitle:forState:
- setTitleColor:forState:
- setTransform:
- setTyped:
- setUserInteractionEnabled:
- setValue:
- setValue:forKey:
- setVietnamese:
- setWeight:
- setWindow:
- setWindowLevel:
- setWord:
- setupHandleForPane:
- setupLiveAppViewForPane:
- shared
- sharedApplication
- shield
- shieldOn
- shift
- showForApp:keyboardType:returnType:
- smartDashesType
- smartInsertDeleteType
- smartQuotesType
- soloButton
- spellCheckingType
- startAnimation
- state
- string
- stringByAppendingPathComponent:
- stringByAppendingString:
- stringByDeletingPathExtension
- stringFromDate:
- stringWithCharacters:length:
- stringWithContentsOfFile:encoding:error:
- stringWithFormat:
- stringWithUTF8String:
- stroke
- sublayers
- substringFromIndex:
- substringToIndex:
- substringWithRange:
- subviews
- superclass
- superview
- supportedInterfaceOrientations
- systemFontOfSize:
- systemFontOfSize:weight:
- systemImageNamed:withConfiguration:
- systemVersion
- teardownPane:
- textContentType
- textFieldShouldReturn:
- thermalState
- timeIntervalSince1970
- timeIntervalSinceNow
