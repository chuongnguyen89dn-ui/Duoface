# HỒ SƠ QUÉT TĨNH TẬN GỐC — GÓI "DUODASH" (ỨNG VIÊN TRONG REPO DUOFACE)

Ngày quét: 05/11/2026 · Phương pháp: phân tích tĩnh chỉ-đọc (dpkg-deb, parser Mach-O/ObjC tự viết bằng Python, strings). Không binary nào được thực thi.

## 0. KẾT LUẬN ĐỊNH DANH (đọc trước)

- **Không tìm thấy gói DuoDash chính hãng của SenseTechLab** (bản bán trên Chariz, 1.1.6) ở bất kỳ nguồn nào trong tầm kiểm tra: toàn bộ .deb trên máy local và toàn bộ thư mục `dist/` của repo `chuongnguyen89dn-ui/Duoface` trên các nhánh `spec-main`, `feature/duoface-exact-payload-migration`, `feature/visual12-duodash-recovery`. Không có gói nào mang Package/Name/Maintainer của SenseTechLab.
- **Gói được quét trong hồ sơ này** là gói nằm trên nhánh `feature/visual12-duodash-recovery` (nhánh mang tên "duodash-recovery") tại `dist/payload-migration/native12-speed8compact/com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb`. Control của chính nó khai: Package `com.duoface.independent`, Name "DuoFace Mới (Native thử nghiệm)", Maintainer "DuoFace Independent", Author "DuoFace Team", Description ghi rõ "thuc nghiem khong dong bo cap phep" (thử nghiệm, không đồng bộ cấp phép). Đây là **gói repack/recovery do dự án tự đóng gói lại từ payload của DuoFace gốc**, không phải DuoDash chính hãng.
- Bằng chứng repack đo được (chi tiết ở mục 8): 33/37 file của bản bóc DuoFace gốc 1.0.4-1 xuất hiện trong gói này **giống hệt từng byte**; 3 binary còn lại khác ở mức đóng gói lại (fat arm64+arm64e → thin arm64) nhưng **bộ class và bộ method giống hệt 100%** (36 class / 757 method của DuoFaceDashboard.dylib; 27 class / 522 method của DuoFaceUI). Gói có thêm 3 dylib mới không có trong bản gốc (DuoFaceLogoGripOnly, DuoFaceSpeedHUD, DuoFaceSpeedOwner) và 1 ảnh mới.

## 1. BƯỚC 0 — QUÁ TRÌNH TÌM NGUỒN VÀ BẰNG CHỨNG

### 1.1 Trên máy local — ÂM TÍNH
Quét toàn bộ file `.deb` dưới `/home/hatch/workspace` (gồm deb-demo, user/files, duoface-audit, az-compare, omnicar-kb, các thư mục QA172–QA187, qa186-stage, duoface-wakefix/tree với hàng chục deb nativescenehost/jb-embedded, mytweak 0.2.0–0.3.0): đọc control của từng gói. Kết quả: **không gói nào nhắc "DuoDash" hay "SenseTechLab"** trong Package/Name/Description/Maintainer. Các gói tìm thấy đều thuộc nhóm đã biết (DuoNavi, DuoFace voice104 test, OmniCar, DuoFace QA jb.embedded, MyTweak, NativeSceneHost, demotool).

### 1.2 Trong repo GitHub — các deb đã kiểm bằng control

| Vị trí | File | Package / Version (theo control) | SHA256 |
|---|---|---|---|
| spec-main `dist/` | com.duonavi.app_1.0.4_iphoneos-arm64.deb (1.739.158 B) | `com.duonavi.app` / DuoNavi / 1.0.4 — DuoNavi Team <support@duonavi.com> | f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd |
| spec-main `dist/main-export/` | com.duoface.app_1.0.3-11_integratedtest_iphoneos-arm64.deb (2.080.480 B) | `com.duoface.app` / DuoFace / 1.0.3-11~integratedtest — DuoFace Team, "TEST ONLY… NOT released to Sileo" | 100566ae52190f8b948c4acc2f4a9d4f10cfa155164efe457ad805a864ebedc7 |
| spec-main `dist/visual-1.0.3-12/` | com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb (2.231.998 B) | `com.duonavi.app` / DuoFace / 1.0.3-12~visualtest — DuoFace Team, "runtime and signature unverified" | 8b7dedf77b9ec05465b83fdb6e2d7127800eac232a34ecf12f2c08b3983a481a |
| 2 nhánh migration/recovery `dist/payload-migration/native12-speed8compact/` | **com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb (1.745.196 B)** | **`com.duoface.independent` / 0.1.0~native12+speed8compact — DuoFace Independent** | **2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad** |

- SHA256 của file tải về **khớp** file `SHA256SUMS` đặt cạnh nó trong repo và khớp tiền tố kỳ vọng `2fe8892c`.
- File trên 2 nhánh có **cùng git blob SHA `1aa4f57a75b198f13738b8aff0f0bee41a90f66e`** và cùng kích thước 1.745.196 B → cùng một file.
- Thư mục đi kèm còn có `BAO_CAO.json` (báo cáo của pipeline migration: "SPEED8_COMPACT_SETTINGS_GMAP_WIRE_QA_STATIC_PASS_NOT_DEVICE_TESTED", `sileo_published: false`, `device_tested: false`, 42 file giữ nguyên từng byte so với baseline speed7split, chỉ thay đúng 1 file DuoFaceSpeedHUD.dylib) và `CONTENTS.txt` (danh sách data.tar).
- `dist/candidates/` (spec-main) gồm 11 thư mục biến thể giao diện (border-focus-red1..3, fullscreen-adapter1..2, menu-*) của dòng DuoNavi 1.0.3-12; `dist/payload-migration/` (nhánh migration) gồm ~30 thư mục biến thể native1..native21/speed1..speed8 cùng 1 tar staging — tất cả đều thuộc dòng repack của dự án, không có gói SenseTechLab.

## 2. ĐỊNH DANH GÓI ĐƯỢC QUÉT

```
Package: com.duoface.independent
Name: DuoFace Mới (Native thử nghiệm)
Description: DuoFace UI va loi goc, thuc nghiem khong dong bo cap phep. Can thiet bi test va khong cai dong thoi goi cu.
Maintainer: DuoFace Independent
Author: DuoFace Team
Section: Tweaks
Depends: mobilesubstrate (>= 0.9.5000), firmware (>= 13.0)
Architecture: iphoneos-arm64
Version: 0.1.0~native12+speed8compact
Installed-Size: 10253
Kích thước file .deb: 1.745.196 bytes
SHA256: 2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad
Control archive chứa: control, md5sums (43 file), preinst, postinst, prerm. Không có postrm/extrainst_.
```

### 2.1 Maintainer scripts (đọc tĩnh, không chạy)
- **preinst** (679 B, `#!/bin/sh`, `set -eu`): với 4 file payload cốt lõi (`DuoFaceUI`, `DuoFaceDashboard.dylib`, `DuoFaceFullscreenBridge.dylib`, `DuoFaceVisualHook.dylib`), tra `dpkg-query -S`; nếu file đang thuộc một gói khác `com.duoface.independent` thì in lỗi "another installed package owns …; refusing overwrite" và **hủy cài đặt (exit 1)**. Đây là chốt chống ghi đè lên gói gốc.
- **postinst** (181 B): chạy `uicache -a` (bỏ qua lỗi), in dòng "DuoFace Native TEST installed. Restart SpringBoard/CarPlay before device testing."
- **prerm** (17 B): `#!/bin/sh` + `exit 0` — không làm gì.

## 3. CÂY FILE 100% CỦA GÓI (data.tar)

| # | Path | Kích thước (B) | SHA256 (chỉ file nhị phân/tài liệu chính) |
|---|---|---|---|
| 1 | var/jb/Applications/DuoFaceUI.app/AppIcon29x29.png | 1625 |  |
| 2 | var/jb/Applications/DuoFaceUI.app/AppIcon29x29@2x.png | 4927 |  |
| 3 | var/jb/Applications/DuoFaceUI.app/AppIcon29x29@3x.png | 9504 |  |
| 4 | var/jb/Applications/DuoFaceUI.app/AppIcon40x40.png | 2650 |  |
| 5 | var/jb/Applications/DuoFaceUI.app/AppIcon40x40@2x.png | 8309 |  |
| 6 | var/jb/Applications/DuoFaceUI.app/AppIcon40x40@3x.png | 16021 |  |
| 7 | var/jb/Applications/DuoFaceUI.app/AppIcon50x50.png | 3845 |  |
| 8 | var/jb/Applications/DuoFaceUI.app/AppIcon50x50@2x.png | 11898 |  |
| 9 | var/jb/Applications/DuoFaceUI.app/AppIcon57x57.png | 4818 |  |
| 10 | var/jb/Applications/DuoFaceUI.app/AppIcon57x57@2x.png | 14778 |  |
| 11 | var/jb/Applications/DuoFaceUI.app/AppIcon57x57@3x.png | 28859 |  |
| 12 | var/jb/Applications/DuoFaceUI.app/AppIcon60x60.png | 5185 |  |
| 13 | var/jb/Applications/DuoFaceUI.app/AppIcon60x60@2x.png | 16021 |  |
| 14 | var/jb/Applications/DuoFaceUI.app/AppIcon60x60@3x.png | 31467 |  |
| 15 | var/jb/Applications/DuoFaceUI.app/AppIcon72x72.png | 7026 |  |
| 16 | var/jb/Applications/DuoFaceUI.app/AppIcon72x72@2x.png | 21616 |  |
| 17 | var/jb/Applications/DuoFaceUI.app/AppIcon76x76.png | 7628 |  |
| 18 | var/jb/Applications/DuoFaceUI.app/AppIcon76x76@2x.png | 23597 |  |
| 19 | var/jb/Applications/DuoFaceUI.app/DuoFaceUI | 1220256 | cb40346d8ca504cb399abe31367847b4f980a01ba93810986ce1acf1fbe9eef9 |
| 20 | var/jb/Applications/DuoFaceUI.app/Info.plist | 2303 | d34a7d08c593dd2ee29b0fbe79d51b369253a8728282b1fff2b757302b7a5e67 |
| 21 | var/jb/Library/Application Support/DuoFace/VisualAssets/duoface-fullscreen.png | 6400 |  |
| 22 | var/jb/Library/Application Support/DuoFace/VisualAssets/duoface-picker.png | 15225 |  |
| 23 | var/jb/Library/Application Support/DuoFace/VisualAssets/duoface-swap.png | 22085 |  |
| 24 | var/jb/Library/Application Support/DuoFace/asset-manifest.json | 1998 |  |
| 25 | var/jb/Library/Application Support/DuoFace/duoface-icon.png | 64297 |  |
| 26 | var/jb/Library/Application Support/DuoFace/duoface-logo-picker-alpha-v2.png | 143191 |  |
| 27 | var/jb/Library/Application Support/DuoFace/duoface-logo-vert.png | 378795 |  |
| 28 | var/jb/Library/Application Support/DuoFace/duoface-logo.png | 147482 |  |
| 29 | var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib | 3760032 | 9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea |
| 30 | var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.plist | 1446 |  |
| 31 | var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib | 124976 | 0bcd172dedbbffe7ad5d549770c1c1769323e21b0127528a661bbe144c10f3fe |
| 32 | var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.plist | 594 |  |
| 33 | var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceLogoGripOnly.dylib | 72320 | 2091b8aae40bf06a3151f7cd88889d5c23273022e933ab11aee3f23dbc2f8ba1 |
| 34 | var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceLogoGripOnly.plist | 511 |  |
| 35 | var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceSpeedHUD.dylib | 106928 | 8968e1724afda7087c258cd1146eac014e29daf2bf823e734bca91a81881a364 |
| 36 | var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceSpeedHUD.plist | 49 |  |
| 37 | var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceSpeedOwner.dylib | 70736 | d3725aca26dbee03cc1ad8697612004f405b2f3759c94656eb3451f39422fee3 |
| 38 | var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceSpeedOwner.plist | 49 |  |
| 39 | var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.dylib | 75536 | 4ebf68b630c102dee1bbaac87dcadddd3e13f618331cacd9c47ae1a27437959d |
| 40 | var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.plist | 511 |  |
| 41 | var/jb/etc/sudoers.d/duoface | 28 |  |
| 42 | var/jb/usr/bin/duoface-cboptimize | 3364 | 73b19cdafe1624f089d54ae06aa0f00b1545ca5f11fd62fc6e69dcf44417eb46 |
| 43 | var/jb/usr/libexec/duoface_cboptimize_helper | 150528 | bd77f7594b649b722d71094f5a1d650d2bb9541a0827e12e21254d82f4a93906 |

Gói **không chứa symlink nào** (đã kiểm tra toàn cây). Không có thư mục Preferences/payload plist sẵn trong data.tar (chỉ có thư mục trống `./var/mobile/Library/Preferences/` theo CONTENTS.txt).

## 4. PHÂN TÍCH TỪNG BINARY

Quy ước đọc bảng method: mỗi dòng là `selector — types=<type encoding> — imp=<địa chỉ ảo trong slice arm64>`. Superclass chỉ ghi được khi resolve tĩnh trong cùng binary; class kế thừa class của framework ngoài sẽ ghi "— (class ngoài binary, không resolve tĩnh được)". Cột "imports hook/IPC" và danh sách class ngoài được tham chiếu lấy từ symbol table + `__objc_selrefs` (bản đầy đủ lưu trong thư mục làm việc `analysis/selrefs/`).

### 4.1 DuoFaceDashboard.dylib
- Đường dẫn trong gói: `var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib`
- Bộ lọc nạp: DuoFaceDashboard.plist — Filter.Bundles: 24 bundle (xem mục 5)
- Slice 0: **arm64**, symbols defined=1, undefined/imports=295
  - Code signature: chỉ có CodeDirectory + requirements, **không có blob entitlements** (chi tiết: {"blob_type_0": ["0xfade0c02", 18291], "blob_type_2": ["0xfade0c01", 140], "blob_type_4096": ["0xfade0c02", 29199]}).
  - Class ObjC: 36 · Category: 0 · Protocol khai báo: 5
- Selector được tham chiếu qua `__objc_selrefs`: 1316 (danh sách đầy đủ trong `analysis/selrefs/DuoFaceDashboard.txt`).
- Class ngoài binary được tham chiếu (`_OBJC_CLASS_$_*`): 76 — danh sách ở cuối mục này.
- Thư viện liên kết: `/usr/lib/libobjc.A.dylib`, `/System/Library/Frameworks/Foundation.framework/Foundation`, `/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation`, `/System/Library/Frameworks/UIKit.framework/UIKit`, `/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics`, `/System/Library/Frameworks/IOKit.framework/Versions/A/IOKit`, `/System/Library/Frameworks/Security.framework/Security`, `/System/Library/Frameworks/AVFoundation.framework/AVFoundation`, `/System/Library/Frameworks/QuartzCore.framework/QuartzCore`, `/usr/lib/libsqlite3.dylib`, `/System/Library/PrivateFrameworks/AppSupport.framework/AppSupport`, `/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices`, `/System/Library/Frameworks/Speech.framework/Speech`, `/usr/lib/libSystem.B.dylib`, `/System/Library/Frameworks/AVFAudio.framework/AVFAudio`, `@rpath/CydiaSubstrate.framework/CydiaSubstrate`
- Constructor (`__mod_init_func`): ['0x6258', '0x2a803c']
- Imports liên quan hook/IPC: `_CFNotificationCenterAddObserver`, `_CFNotificationCenterGetDarwinNotifyCenter`, `_CFNotificationCenterPostNotification`, `_MSHookFunction`, `_MSHookMessageEx`, `_OBJC_CLASS_$_NSDistributedNotificationCenter`, `_dlopen`, `_dlsym`, `_notify_post`, `_notify_register_dispatch`, `_objc_allocateClassPair`, `_objc_msgSend`, `_objc_msgSendSuper`, `_objc_msgSendSuper2`

#### Class `CBLocalization` : —
- Ivars: `_activeLanguageCode` : `@"NSString"` (8 B); `_cachedStringTables` : `@"NSMutableDictionary"` (8 B); `_activeLanguageTable` : `@"NSDictionary"` (8 B); `_viTable` : `@"NSDictionary"` (8 B); `_enTable` : `@"NSDictionary"` (8 B)
- Instance methods (6):
  - `init` — types=`@16@0:8` — imp=`0x7098`
  - `reloadLanguage` — types=`v16@0:8` — imp=`0x7ea0`
  - `activeLanguageCode` — types=`@16@0:8` — imp=`0x83b8`
  - `stringTableForLanguageCode:` — types=`@24@0:8@16` — imp=`0x85e4`
  - `localizedStringForKey:` — types=`@24@0:8@16` — imp=`0x89f8`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0x8b0c`
- Class methods (7):
  - `+sharedInstance` — types=`@16@0:8` — imp=`0x702c`
  - `+speechVoiceLanguageCode` — types=`@16@0:8` — imp=`0x71c0`
  - `+supportedLanguages` — types=`@16@0:8` — imp=`0x74b4`
  - `+displayNameForLanguageCode:` — types=`@24@0:8@16` — imp=`0x7b94`
  - `+currentLanguageCode` — types=`@16@0:8` — imp=`0x835c`
  - `+setCurrentLanguageCode:` — types=`v24@0:8@16` — imp=`0x83fc`
  - `+localizedStringForKey:` — types=`@24@0:8@16` — imp=`0x8974`

#### Class `CBAssistantManager` : —
- Protocol tuân thủ: SFSpeechRecognizerDelegate, AVSpeechSynthesizerDelegate
- Ivars: `_isListening` : `B` (1 B); `_voiceFeedbackEnabled` : `B` (1 B); `_preferredMapIndex` : `q` (8 B); `_onStatusUpdate` : `@?` (8 B); `_speechRecognizer` : `@"SFSpeechRecognizer"` (8 B); `_recognitionRequest` : `@"SFSpeechAudioBufferRecognitionRequest"` (8 B); `_recognitionTask` : `@"SFSpeechRecognitionTask"` (8 B); `_audioEngine` : `@"AVAudioEngine"` (8 B); `_speechSynthesizer` : `@"AVSpeechSynthesizer"` (8 B); `_recordedPCMData` : `@"NSMutableData"` (8 B); `_speakCompletion` : `@?` (8 B); `_silenceTimer` : `@"NSTimer"` (8 B); `_lastTranscribedText` : `@"NSString"` (8 B); `_hudWindow` : `@"UIWindow"` (8 B); `_hudCard` : `@"UIVisualEffectView"` (8 B); `_micIconView` : `@"UIImageView"` (8 B); `_statusLabel` : `@"UILabel"` (8 B); `_transcriptLabel` : `@"UILabel"` (8 B); `_pulseAnimation` : `@"CABasicAnimation"` (8 B)
- Properties: `speechRecognizer` (T@"SFSpeechRecognizer",&,N,V_speechRecognizer); `recognitionRequest` (T@"SFSpeechAudioBufferRecognitionRequest",&,N,V_recognitionRequest); `recognitionTask` (T@"SFSpeechRecognitionTask",&,N,V_recognitionTask); `audioEngine` (T@"AVAudioEngine",&,N,V_audioEngine); `speechSynthesizer` (T@"AVSpeechSynthesizer",&,N,V_speechSynthesizer); `recordedPCMData` (T@"NSMutableData",&,N,V_recordedPCMData); `isListening` (TB,N,V_isListening); `speakCompletion` (T@?,C,N,V_speakCompletion); `silenceTimer` (T@"NSTimer",&,N,V_silenceTimer); `lastTranscribedText` (T@"NSString",C,N,V_lastTranscribedText); `hudWindow` (T@"UIWindow",&,N,V_hudWindow); `hudCard` (T@"UIVisualEffectView",&,N,V_hudCard); `micIconView` (T@"UIImageView",&,N,V_micIconView); `statusLabel` (T@"UILabel",&,N,V_statusLabel); `transcriptLabel` (T@"UILabel",&,N,V_transcriptLabel); `pulseAnimation` (T@"CABasicAnimation",&,N,V_pulseAnimation); `preferredMapIndex` (Tq,N,V_preferredMapIndex); `voiceFeedbackEnabled` (TB,N,V_voiceFeedbackEnabled); `onStatusUpdate` (T@?,C,N,V_onStatusUpdate); `hash` (TQ,R); `superclass` (T#,R); `description` (T@"NSString",R,C); `debugDescription` (T@"NSString",R,C)
- Instance methods (68):
  - `init` — types=`@16@0:8` — imp=`0x2e990`
  - `dealloc` — types=`v16@0:8` — imp=`0x2ecf8`
  - `cb_onLanguageChanged:` — types=`v24@0:8@16` — imp=`0x2ed70`
  - `reloadPreferences` — types=`v16@0:8` — imp=`0x2ee10`
  - `setupSpeechSynthesizer` — types=`v16@0:8` — imp=`0x2ef58`
  - `setupSpeechRecognizer` — types=`v16@0:8` — imp=`0x2efa0`
  - `speak:completion:` — types=`v32@0:8@16@?24` — imp=`0x2f54c`
  - `stopSpeaking` — types=`v16@0:8` — imp=`0x2f790`
  - `speechSynthesizer:didFinishSpeechUtterance:` — types=`v32@0:8@16@24` — imp=`0x2f838`
  - `toggleListening` — types=`v16@0:8` — imp=`0x2f8c8`
  - `startListening` — types=`v16@0:8` — imp=`0x2f910`
  - `beginRecordingSession` — types=`v16@0:8` — imp=`0x2f9dc`
  - `resetSilenceTimer` — types=`v16@0:8` — imp=`0x303b4`
  - `listeningTimeout` — types=`v16@0:8` — imp=`0x30484`
  - `finishListeningAndProcess` — types=`v16@0:8` — imp=`0x304c8`
  - `stopListening` — types=`v16@0:8` — imp=`0x308ac`
  - `transcribeAudioData:completion:` — types=`v32@0:8@16@?24` — imp=`0x309a8`
  - `processVoiceCommand:` — types=`v24@0:8@16` — imp=`0x31294`
  - `handleNavigationCommand:` — types=`v24@0:8@16` — imp=`0x324b8`
  - `handleAppLaunchCommand:` — types=`v24@0:8@16` — imp=`0x32a5c`
  - `handleMusicCommand:` — types=`v24@0:8@16` — imp=`0x33088`
  - `triggerBridgeApp:` — types=`v24@0:8@16` — imp=`0x33550`
  - `dismissCarBridgeApp` — types=`v16@0:8` — imp=`0x337c8`
  - `showHUD` — types=`v16@0:8` — imp=`0x339b0`
  - `startMicPulseAnimation` — types=`v16@0:8` — imp=`0x34300`
  - `stopMicPulseAnimation` — types=`v16@0:8` — imp=`0x344b8`
  - `updateHUDStatus:subtext:` — types=`v32@0:8@16@24` — imp=`0x34524`
  - `stopListeningAndDismiss` — types=`v16@0:8` — imp=`0x34704`
  - `dismissHUD` — types=`v16@0:8` — imp=`0x34738`
  - `isListening` — types=`B16@0:8` — imp=`0x348ac`
  - `setIsListening:` — types=`v20@0:8B16` — imp=`0x348b4`
  - `preferredMapIndex` — types=`q16@0:8` — imp=`0x348bc`
  - `setPreferredMapIndex:` — types=`v24@0:8q16` — imp=`0x348c4`
  - `voiceFeedbackEnabled` — types=`B16@0:8` — imp=`0x348cc`
  - `setVoiceFeedbackEnabled:` — types=`v20@0:8B16` — imp=`0x348d4`
  - `onStatusUpdate` — types=`@?16@0:8` — imp=`0x348dc`
  - `setOnStatusUpdate:` — types=`v24@0:8@?16` — imp=`0x348e8`
  - `speechRecognizer` — types=`@16@0:8` — imp=`0x348f0`
  - `setSpeechRecognizer:` — types=`v24@0:8@16` — imp=`0x348f8`
  - `recognitionRequest` — types=`@16@0:8` — imp=`0x34904`
  - `setRecognitionRequest:` — types=`v24@0:8@16` — imp=`0x3490c`
  - `recognitionTask` — types=`@16@0:8` — imp=`0x34918`
  - `setRecognitionTask:` — types=`v24@0:8@16` — imp=`0x34920`
  - `audioEngine` — types=`@16@0:8` — imp=`0x3492c`
  - `setAudioEngine:` — types=`v24@0:8@16` — imp=`0x34934`
  - `speechSynthesizer` — types=`@16@0:8` — imp=`0x34940`
  - `setSpeechSynthesizer:` — types=`v24@0:8@16` — imp=`0x34948`
  - `recordedPCMData` — types=`@16@0:8` — imp=`0x34954`
  - `setRecordedPCMData:` — types=`v24@0:8@16` — imp=`0x3495c`
  - `speakCompletion` — types=`@?16@0:8` — imp=`0x34968`
  - `setSpeakCompletion:` — types=`v24@0:8@?16` — imp=`0x34974`
  - `silenceTimer` — types=`@16@0:8` — imp=`0x3497c`
  - `setSilenceTimer:` — types=`v24@0:8@16` — imp=`0x34984`
  - `lastTranscribedText` — types=`@16@0:8` — imp=`0x34990`
  - `setLastTranscribedText:` — types=`v24@0:8@16` — imp=`0x3499c`
  - `hudWindow` — types=`@16@0:8` — imp=`0x349a4`
  - `setHudWindow:` — types=`v24@0:8@16` — imp=`0x349ac`
  - `hudCard` — types=`@16@0:8` — imp=`0x349b8`
  - `setHudCard:` — types=`v24@0:8@16` — imp=`0x349c0`
  - `micIconView` — types=`@16@0:8` — imp=`0x349cc`
  - `setMicIconView:` — types=`v24@0:8@16` — imp=`0x349d4`
  - `statusLabel` — types=`@16@0:8` — imp=`0x349e0`
  - `setStatusLabel:` — types=`v24@0:8@16` — imp=`0x349e8`
  - `transcriptLabel` — types=`@16@0:8` — imp=`0x349f4`
  - `setTranscriptLabel:` — types=`v24@0:8@16` — imp=`0x349fc`
  - `pulseAnimation` — types=`@16@0:8` — imp=`0x34a08`
  - `setPulseAnimation:` — types=`v24@0:8@16` — imp=`0x34a10`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0x34a1c`
- Class methods (1):
  - `+sharedInstance` — types=`@16@0:8` — imp=`0x2e8f4`

#### Class `CBDashboardSettings` : —
- Ivars: `_portalAppEnabled` : `B` (1 B); `_screenBlankEnabled` : `B` (1 B); `_splitScreenEnabled` : `B` (1 B); `_assistantEnabled` : `B` (1 B); `_voiceFeedbackEnabled` : `B` (1 B); `_hideIconLabels` : `B` (1 B); `_dockSystemMonitorEnabled` : `B` (1 B); `_dockSystemMonitorShowAll` : `B` (1 B); `_autoLaunchOnConnect` : `B` (1 B); `_agreedToEULA` : `B` (1 B); `_bridgedApps` : `@"NSArray"` (8 B); `_appSettings` : `@"NSDictionary"` (8 B); `_preferredMapIndex` : `q` (8 B); `_splitLeftBundleID` : `@"NSString"` (8 B); `_splitRightBundleID` : `@"NSString"` (8 B); `_splitPreset` : `q` (8 B); `_splitMode` : `q` (8 B); `_splitApp1` : `@"NSString"` (8 B); `_splitApp2` : `@"NSString"` (8 B); `_splitApp3` : `@"NSString"` (8 B); `_splitApp4` : `@"NSString"` (8 B); `_splitRatio` : `d` (8 B); `_gridCols` : `q` (8 B); `_gridRows` : `q` (8 B); `_autoLaunchBundleID` : `@"NSString"` (8 B)
- Properties: `bridgedApps` (T@"NSArray",&,N,V_bridgedApps); `appSettings` (T@"NSDictionary",&,N,V_appSettings); `portalAppEnabled` (TB,N,V_portalAppEnabled); `screenBlankEnabled` (TB,N,V_screenBlankEnabled); `splitScreenEnabled` (TB,N,V_splitScreenEnabled); `assistantEnabled` (TB,N,V_assistantEnabled); `preferredMapIndex` (Tq,N,V_preferredMapIndex); `voiceFeedbackEnabled` (TB,N,V_voiceFeedbackEnabled); `splitLeftBundleID` (T@"NSString",C,N,V_splitLeftBundleID); `splitRightBundleID` (T@"NSString",C,N,V_splitRightBundleID); `splitPreset` (Tq,N,V_splitPreset); `splitMode` (Tq,N,V_splitMode); `splitApp1` (T@"NSString",C,N,V_splitApp1); `splitApp2` (T@"NSString",C,N,V_splitApp2); `splitApp3` (T@"NSString",C,N,V_splitApp3); `splitApp4` (T@"NSString",C,N,V_splitApp4); `splitRatio` (Td,N,V_splitRatio); `gridCols` (Tq,N,V_gridCols); `gridRows` (Tq,N,V_gridRows); `hideIconLabels` (TB,N,V_hideIconLabels); `dockSystemMonitorEnabled` (TB,N,V_dockSystemMonitorEnabled); `dockSystemMonitorShowAll` (TB,N,V_dockSystemMonitorShowAll); `autoLaunchOnConnect` (TB,N,V_autoLaunchOnConnect); `autoLaunchBundleID` (T@"NSString",C,N,V_autoLaunchBundleID); `agreedToEULA` (TB,N,V_agreedToEULA)
- Instance methods (56):
  - `init` — types=`@16@0:8` — imp=`0x36054`
  - `scaleForBundleID:` — types=`d24@0:8@16` — imp=`0x3618c`
  - `setScale:forBundleID:` — types=`v32@0:8d16@24` — imp=`0x36194`
  - `setDockSystemMonitorEnabled:` — types=`v20@0:8B16` — imp=`0x364d0`
  - `setDockSystemMonitorShowAll:` — types=`v20@0:8B16` — imp=`0x36670`
  - `reload` — types=`v16@0:8` — imp=`0x36810`
  - `reloadAppPrefs` — types=`v16@0:8` — imp=`0x3681c`
  - `bridgedApps` — types=`@16@0:8` — imp=`0x37e88`
  - `setBridgedApps:` — types=`v24@0:8@16` — imp=`0x37e90`
  - `appSettings` — types=`@16@0:8` — imp=`0x37e9c`
  - `setAppSettings:` — types=`v24@0:8@16` — imp=`0x37ea4`
  - `portalAppEnabled` — types=`B16@0:8` — imp=`0x37eb0`
  - `setPortalAppEnabled:` — types=`v20@0:8B16` — imp=`0x37eb8`
  - `screenBlankEnabled` — types=`B16@0:8` — imp=`0x37ec0`
  - `setScreenBlankEnabled:` — types=`v20@0:8B16` — imp=`0x37ec8`
  - `splitScreenEnabled` — types=`B16@0:8` — imp=`0x37ed0`
  - `setSplitScreenEnabled:` — types=`v20@0:8B16` — imp=`0x37ed8`
  - `assistantEnabled` — types=`B16@0:8` — imp=`0x37ee0`
  - `setAssistantEnabled:` — types=`v20@0:8B16` — imp=`0x37ee8`
  - `preferredMapIndex` — types=`q16@0:8` — imp=`0x37ef0`
  - `setPreferredMapIndex:` — types=`v24@0:8q16` — imp=`0x37ef8`
  - `voiceFeedbackEnabled` — types=`B16@0:8` — imp=`0x37f00`
  - `setVoiceFeedbackEnabled:` — types=`v20@0:8B16` — imp=`0x37f08`
  - `splitLeftBundleID` — types=`@16@0:8` — imp=`0x37f10`
  - `setSplitLeftBundleID:` — types=`v24@0:8@16` — imp=`0x37f1c`
  - `splitRightBundleID` — types=`@16@0:8` — imp=`0x37f24`
  - `setSplitRightBundleID:` — types=`v24@0:8@16` — imp=`0x37f30`
  - `splitPreset` — types=`q16@0:8` — imp=`0x37f38`
  - `setSplitPreset:` — types=`v24@0:8q16` — imp=`0x37f40`
  - `splitMode` — types=`q16@0:8` — imp=`0x37f48`
  - `setSplitMode:` — types=`v24@0:8q16` — imp=`0x37f50`
  - `splitApp1` — types=`@16@0:8` — imp=`0x37f58`
  - `setSplitApp1:` — types=`v24@0:8@16` — imp=`0x37f64`
  - `splitApp2` — types=`@16@0:8` — imp=`0x37f6c`
  - `setSplitApp2:` — types=`v24@0:8@16` — imp=`0x37f78`
  - `splitApp3` — types=`@16@0:8` — imp=`0x37f80`
  - `setSplitApp3:` — types=`v24@0:8@16` — imp=`0x37f8c`
  - `splitApp4` — types=`@16@0:8` — imp=`0x37f94`
  - `setSplitApp4:` — types=`v24@0:8@16` — imp=`0x37fa0`
  - `splitRatio` — types=`d16@0:8` — imp=`0x37fa8`
  - `setSplitRatio:` — types=`v24@0:8d16` — imp=`0x37fb0`
  - `gridCols` — types=`q16@0:8` — imp=`0x37fb8`
  - `setGridCols:` — types=`v24@0:8q16` — imp=`0x37fc0`
  - `gridRows` — types=`q16@0:8` — imp=`0x37fc8`
  - `setGridRows:` — types=`v24@0:8q16` — imp=`0x37fd0`
  - `hideIconLabels` — types=`B16@0:8` — imp=`0x37fd8`
  - `setHideIconLabels:` — types=`v20@0:8B16` — imp=`0x37fe0`
  - `dockSystemMonitorEnabled` — types=`B16@0:8` — imp=`0x37fe8`
  - `dockSystemMonitorShowAll` — types=`B16@0:8` — imp=`0x37ff0`
  - `autoLaunchOnConnect` — types=`B16@0:8` — imp=`0x37ff8`
  - `setAutoLaunchOnConnect:` — types=`v20@0:8B16` — imp=`0x38000`
  - `autoLaunchBundleID` — types=`@16@0:8` — imp=`0x38008`
  - `setAutoLaunchBundleID:` — types=`v24@0:8@16` — imp=`0x38014`
  - `agreedToEULA` — types=`B16@0:8` — imp=`0x3801c`
  - `setAgreedToEULA:` — types=`v20@0:8B16` — imp=`0x38024`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0x3802c`
- Class methods (5):
  - `+sharedInstance` — types=`@16@0:8` — imp=`0x353dc`
  - `+assistantIconImage` — types=`@16@0:8` — imp=`0x35478`
  - `+portalAppIconImage` — types=`@16@0:8` — imp=`0x357ac`
  - `+splitScreenIconImage` — types=`@16@0:8` — imp=`0x35ae0`
  - `+portalAppIdentifier` — types=`@16@0:8` — imp=`0x36014`

#### Class `CBHttpClient` : —
- Ivars: `_networkQueue` : `@"NSObject<OS_dispatch_queue>"` (8 B)
- Properties: `networkQueue` (T@"NSObject<OS_dispatch_queue>",&,N,V_networkQueue)
- Instance methods (6):
  - `init` — types=`@16@0:8` — imp=`0x38a04`
  - `postJSON:toURL:timeout:customHeaders:completion:` — types=`v56@0:8@16@24d32@40@?48` — imp=`0x38a6c`
  - `getJSONFromURL:timeout:customHeaders:completion:` — types=`v48@0:8@16d24@32@?40` — imp=`0x39124`
  - `networkQueue` — types=`@16@0:8` — imp=`0x3970c`
  - `setNetworkQueue:` — types=`v24@0:8@16` — imp=`0x39714`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0x39720`
- Class methods (1):
  - `+sharedClient` — types=`@16@0:8` — imp=`0x38998`

#### Class `CBLicenseSyncManager` : —
- Ivars: `_isSyncing` : `B` (1 B); `_syncQueue` : `@"NSObject<OS_dispatch_queue>"` (8 B); `_lastAttemptTimestamp` : `Q` (8 B)
- Properties: `isSyncing` (TB,N,V_isSyncing); `syncQueue` (T@"NSObject<OS_dispatch_queue>",&,N,V_syncQueue); `lastAttemptTimestamp` (TQ,N,V_lastAttemptTimestamp)
- Instance methods (24):
  - `init` — types=`@16@0:8` — imp=`0x39798`
  - `deviceHardwareHashHex` — types=`@16@0:8` — imp=`0x39804`
  - `isLicenseCurrentlyValid` — types=`B16@0:8` — imp=`0x3adb8`
  - `remainingLicenseSeconds` — types=`Q16@0:8` — imp=`0x4d19c`
  - `isCarPlayScreenConnected` — types=`B16@0:8` — imp=`0x5fb88`
  - `checkAndSyncLicenseIfNeeded` — types=`v16@0:8` — imp=`0x5fbac`
  - `checkAndSyncLicenseIfNeededWithSource:` — types=`v24@0:8@16` — imp=`0x5fc4c`
  - `forceSyncWithCompletion:` — types=`v24@0:8@?16` — imp=`0x72468`
  - `resolvedBackendBaseURL` — types=`@16@0:8` — imp=`0x730a0`
  - `resolvedLicenseServerEndpoint` — types=`@16@0:8` — imp=`0x730b4`
  - `performSyncWithForce:isManualUserAction:completion:` — types=`v32@0:8B16B20@?24` — imp=`0x73190`
  - `performSyncWithForce:isManualUserAction:source:completion:` — types=`v40@0:8B16B20@24@?32` — imp=`0x73220`
  - `installAndVerifyLicensePayload:errorMsg:` — types=`B32@0:8@16^@24` — imp=`0x74694`
  - `actualLicenseExpirationTimestamp` — types=`Q16@0:8` — imp=`0x80c40`
  - `setActualLicenseExpirationTimestamp:` — types=`v24@0:8Q16` — imp=`0x80e04`
  - `actualLicenseTierName` — types=`@16@0:8` — imp=`0x80fa0`
  - `setActualLicenseTierName:` — types=`v24@0:8@16` — imp=`0x810e8`
  - `isSyncing` — types=`B16@0:8` — imp=`0x81270`
  - `setIsSyncing:` — types=`v20@0:8B16` — imp=`0x81278`
  - `syncQueue` — types=`@16@0:8` — imp=`0x81280`
  - `setSyncQueue:` — types=`v24@0:8@16` — imp=`0x81288`
  - `lastAttemptTimestamp` — types=`Q16@0:8` — imp=`0x81294`
  - `setLastAttemptTimestamp:` — types=`v24@0:8Q16` — imp=`0x8129c`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0x812a4`
- Class methods (6):
  - `+sharedInstance` — types=`@16@0:8` — imp=`0x3972c`
  - `+isCarPlayScreen:` — types=`B24@0:8@16` — imp=`0x5f564`
  - `+isCarPlayScreenConnectedExcludingScreen:` — types=`B24@0:8@16` — imp=`0x5f7b8`
  - `+isCarPlayScreenConnected` — types=`B16@0:8` — imp=`0x5fb78`
  - `+formatBaseURLString:` — types=`@24@0:8@16` — imp=`0x725b8`
  - `+resolvedBackendBaseURL` — types=`@16@0:8` — imp=`0x72948`

#### Class `CBTouchCloneView` : —
- Instance methods (5):
  - `sendTouchEventAtPoint:isDown:` — types=`v36@0:8{CGPoint=dd}16B32` — imp=`0x82d4c`
  - `touchesBegan:withEvent:` — types=`v32@0:8@16@24` — imp=`0x82ff8`
  - `touchesMoved:withEvent:` — types=`v32@0:8@16@24` — imp=`0x83058`
  - `touchesEnded:withEvent:` — types=`v32@0:8@16@24` — imp=`0x830b8`
  - `touchesCancelled:withEvent:` — types=`v32@0:8@16@24` — imp=`0x83118`

#### Class `CBBridgedPortalAppView` : —
- Ivars: `_imageView` : `@"UIImageView"` (8 B); `_touchCloneView` : `@"CBTouchCloneView"` (8 B); `_displayLink` : `@"CADisplayLink"` (8 B)
- Properties: `imageView` (T@"UIImageView",&,N,V_imageView); `touchCloneView` (T@"CBTouchCloneView",&,N,V_touchCloneView); `displayLink` (T@"CADisplayLink",&,N,V_displayLink)
- Instance methods (12):
  - `initWithFrame:` — types=`@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16` — imp=`0x83238`
  - `start` — types=`v16@0:8` — imp=`0x833bc`
  - `stop` — types=`v16@0:8` — imp=`0x83488`
  - `captureFrame:` — types=`v24@0:8@16` — imp=`0x834d4`
  - `dealloc` — types=`v16@0:8` — imp=`0x83568`
  - `imageView` — types=`@16@0:8` — imp=`0x835b4`
  - `setImageView:` — types=`v24@0:8@16` — imp=`0x835c4`
  - `touchCloneView` — types=`@16@0:8` — imp=`0x835d8`
  - `setTouchCloneView:` — types=`v24@0:8@16` — imp=`0x835e8`
  - `displayLink` — types=`@16@0:8` — imp=`0x835fc`
  - `setDisplayLink:` — types=`v24@0:8@16` — imp=`0x8360c`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0x83620`

#### Class `CBMultitaskingPillView` : —
- Ivars: `_onPillTapped` : `@?` (8 B); `_blurView` : `@"UIVisualEffectView"` (8 B); `_iconView` : `@"UIImageView"` (8 B); `_titleLabel` : `@"UILabel"` (8 B)
- Properties: `onPillTapped` (T@?,C,N,V_onPillTapped); `blurView` (T@"UIVisualEffectView",&,N,V_blurView); `iconView` (T@"UIImageView",&,N,V_iconView); `titleLabel` (T@"UILabel",&,N,V_titleLabel)
- Instance methods (12):
  - `initWithFrame:` — types=`@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16` — imp=`0x83674`
  - `pillTapped` — types=`v16@0:8` — imp=`0x83cb4`
  - `pillPanned:` — types=`v24@0:8@16` — imp=`0x83eb0`
  - `onPillTapped` — types=`@?16@0:8` — imp=`0x83fbc`
  - `setOnPillTapped:` — types=`v24@0:8@?16` — imp=`0x83fcc`
  - `blurView` — types=`@16@0:8` — imp=`0x83fd8`
  - `setBlurView:` — types=`v24@0:8@16` — imp=`0x83fe8`
  - `iconView` — types=`@16@0:8` — imp=`0x83ffc`
  - `setIconView:` — types=`v24@0:8@16` — imp=`0x8400c`
  - `titleLabel` — types=`@16@0:8` — imp=`0x84020`
  - `setTitleLabel:` — types=`v24@0:8@16` — imp=`0x84030`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0x84044`

#### Class `CBSlotPillHitButton` : —
- Ivars: `_hitInsets` : `{UIEdgeInsets="top"d"left"d"bottom"d"right"d}` (32 B)
- Properties: `hitInsets` (T{UIEdgeInsets=dddd},N,V_hitInsets)
- Instance methods (3):
  - `pointInside:withEvent:` — types=`B40@0:8{CGPoint=dd}16@32` — imp=`0x840ac`
  - `hitInsets` — types=`{UIEdgeInsets=dddd}16@0:8` — imp=`0x84190`
  - `setHitInsets:` — types=`v48@0:8{UIEdgeInsets=dddd}16` — imp=`0x841a8`

#### Class `CBSlotPillView` : —
- Ivars: `_dotViews` : `@"NSMutableArray"` (8 B); `_isFocusedMode` : `B` (1 B); `_showsExpandButton` : `B` (1 B); `_isCompactMode` : `B` (1 B); `_onPillTapped` : `@?` (8 B); `_onPillLongPressed` : `@?` (8 B); `_onExpandTapped` : `@?` (8 B); `_onRestoreTapped` : `@?` (8 B); `_slotIndex` : `q` (8 B); `_dotsButton` : `@"UIButton"` (8 B); `_expandButton` : `@"UIButton"` (8 B); `_restoreButton` : `@"UIButton"` (8 B); `_separatorView` : `@"UIView"` (8 B)
- Properties: `onPillTapped` (T@?,C,N,V_onPillTapped); `onPillLongPressed` (T@?,C,N,V_onPillLongPressed); `onExpandTapped` (T@?,C,N,V_onExpandTapped); `onRestoreTapped` (T@?,C,N,V_onRestoreTapped); `slotIndex` (Tq,N,V_slotIndex); `isFocusedMode` (TB,N,V_isFocusedMode); `showsExpandButton` (TB,N,V_showsExpandButton); `isCompactMode` (TB,N,V_isCompactMode); `dotsButton` (T@"UIButton",&,N,V_dotsButton); `expandButton` (T@"UIButton",&,N,V_expandButton); `restoreButton` (T@"UIButton",&,N,V_restoreButton); `separatorView` (T@"UIView",&,N,V_separatorView)
- Instance methods (36):
  - `initWithSlotIndex:` — types=`@24@0:8q16` — imp=`0x841c0`
  - `layoutSubviews` — types=`v16@0:8` — imp=`0x84c30`
  - `updateBoundsSize` — types=`v16@0:8` — imp=`0x85184`
  - `setShowsExpandButton:` — types=`v20@0:8B16` — imp=`0x852f0`
  - `setFocusedMode:` — types=`v20@0:8B16` — imp=`0x85308`
  - `setCompactMode:` — types=`v20@0:8B16` — imp=`0x85320`
  - `pointInside:withEvent:` — types=`B40@0:8{CGPoint=dd}16@32` — imp=`0x85348`
  - `handleLongPress:` — types=`v24@0:8@16` — imp=`0x853f0`
  - `dotsTapped:` — types=`v24@0:8@16` — imp=`0x85580`
  - `expandTapped:` — types=`v24@0:8@16` — imp=`0x85698`
  - `restoreTapped:` — types=`v24@0:8@16` — imp=`0x857b0`
  - `bounceButton:` — types=`v24@0:8@16` — imp=`0x85904`
  - `onPillTapped` — types=`@?16@0:8` — imp=`0x85b1c`
  - `setOnPillTapped:` — types=`v24@0:8@?16` — imp=`0x85b2c`
  - `onPillLongPressed` — types=`@?16@0:8` — imp=`0x85b38`
  - `setOnPillLongPressed:` — types=`v24@0:8@?16` — imp=`0x85b48`
  - `onExpandTapped` — types=`@?16@0:8` — imp=`0x85b54`
  - `setOnExpandTapped:` — types=`v24@0:8@?16` — imp=`0x85b64`
  - `onRestoreTapped` — types=`@?16@0:8` — imp=`0x85b70`
  - `setOnRestoreTapped:` — types=`v24@0:8@?16` — imp=`0x85b80`
  - `slotIndex` — types=`q16@0:8` — imp=`0x85b8c`
  - `setSlotIndex:` — types=`v24@0:8q16` — imp=`0x85b9c`
  - `isFocusedMode` — types=`B16@0:8` — imp=`0x85bac`
  - `setIsFocusedMode:` — types=`v20@0:8B16` — imp=`0x85bbc`
  - `showsExpandButton` — types=`B16@0:8` — imp=`0x85bcc`
  - `isCompactMode` — types=`B16@0:8` — imp=`0x85bdc`
  - `setIsCompactMode:` — types=`v20@0:8B16` — imp=`0x85bec`
  - `dotsButton` — types=`@16@0:8` — imp=`0x85bfc`
  - `setDotsButton:` — types=`v24@0:8@16` — imp=`0x85c0c`
  - `expandButton` — types=`@16@0:8` — imp=`0x85c20`
  - `setExpandButton:` — types=`v24@0:8@16` — imp=`0x85c30`
  - `restoreButton` — types=`@16@0:8` — imp=`0x85c44`
  - `setRestoreButton:` — types=`v24@0:8@16` — imp=`0x85c54`
  - `separatorView` — types=`@16@0:8` — imp=`0x85c68`
  - `setSeparatorView:` — types=`v24@0:8@16` — imp=`0x85c78`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0x85c8c`

#### Class `CBOverlayScrollView` : —
- Instance methods (4):
  - `initWithFrame:` — types=`@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16` — imp=`0x9ff68`
  - `touchesShouldCancelInContentView:` — types=`B24@0:8@16` — imp=`0xa0074`
  - `addSubview:` — types=`v24@0:8@16` — imp=`0xa007c`
  - `layoutSubviews` — types=`v16@0:8` — imp=`0xa016c`

#### Class `CBMultitaskingOverlayView` : —
- Protocol tuân thủ: UIScrollViewDelegate
- Ivars: `_onCloseRequested` : `@?` (8 B); `_onMultiSplitSelected` : `@?` (8 B); `_dimBackground` : `@"UIView"` (8 B); `_cardShadowContainer` : `@"UIView"` (8 B); `_sheetCard` : `@"UIVisualEffectView"` (8 B); `_allApps` : `@"NSArray"` (8 B); `_appPickerScrollView` : `@"UIScrollView"` (8 B); `_appPickerPageControl` : `@"UIPageControl"` (8 B); `_slotBIDs` : `@"NSMutableArray"` (8 B); `_currentPreset` : `q` (8 B); `_currentRatio` : `d` (8 B); `_targetSlotIndex` : `q` (8 B); `_overlayMode` : `q` (8 B); `_headerIcon` : `@"UIImageView"` (8 B); `_titleLabel` : `@"UILabel"` (8 B); `_appSegmentBtn` : `@"UIButton"` (8 B); `_layoutSegmentBtn` : `@"UIButton"` (8 B); `_recentSegmentBtn` : `@"UIButton"` (8 B); `_runningApps` : `@"NSArray"` (8 B)
- Properties: `onCloseRequested` (T@?,C,N,V_onCloseRequested); `onMultiSplitSelected` (T@?,C,N,V_onMultiSplitSelected); `dimBackground` (T@"UIView",&,N,V_dimBackground); `cardShadowContainer` (T@"UIView",&,N,V_cardShadowContainer); `sheetCard` (T@"UIVisualEffectView",&,N,V_sheetCard); `allApps` (T@"NSArray",&,N,V_allApps); `appPickerScrollView` (T@"UIScrollView",&,N,V_appPickerScrollView); `appPickerPageControl` (T@"UIPageControl",&,N,V_appPickerPageControl); `slotBIDs` (T@"NSMutableArray",&,N,V_slotBIDs); `currentPreset` (Tq,N,V_currentPreset); `currentRatio` (Td,N,V_currentRatio); `targetSlotIndex` (Tq,N,V_targetSlotIndex); `overlayMode` (Tq,N,V_overlayMode); `headerIcon` (T@"UIImageView",&,N,V_headerIcon); `titleLabel` (T@"UILabel",&,N,V_titleLabel); `appSegmentBtn` (T@"UIButton",&,N,V_appSegmentBtn); `layoutSegmentBtn` (T@"UIButton",&,N,V_layoutSegmentBtn); `recentSegmentBtn` (T@"UIButton",&,N,V_recentSegmentBtn); `runningApps` (T@"NSArray",&,N,V_runningApps); `hash` (TQ,R); `superclass` (T#,R); `description` (T@"NSString",R,C); `debugDescription` (T@"NSString",R,C)
- Instance methods (66):
  - `initWithFrame:` — types=`@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16` — imp=`0xa0420`
  - `dealloc` — types=`v16@0:8` — imp=`0xa0aec`
  - `cb_onLanguageChanged:` — types=`v24@0:8@16` — imp=`0xa0b64`
  - `loadInstalledApps` — types=`v16@0:8` — imp=`0xa0c48`
  - `layoutSubviews` — types=`v16@0:8` — imp=`0xa28e8`
  - `setupCardContent` — types=`v16@0:8` — imp=`0xa2a58`
  - `setupAppPickerCardsInCardW:cardH:contentY:` — types=`v40@0:8d16d24d32` — imp=`0xa3e5c`
  - `scrollViewDidScroll:` — types=`v24@0:8@16` — imp=`0xa5d18`
  - `pageControlChanged:` — types=`v24@0:8@16` — imp=`0xa5de4`
  - `setupPresetCardsInCardW:cardH:contentY:` — types=`v40@0:8d16d24d32` — imp=`0xa5e78`
  - `setupRecentAppsCardsInCardW:cardH:contentY:` — types=`v40@0:8d16d24d32` — imp=`0xa678c`
  - `addMoreAppsTapped:` — types=`v24@0:8@16` — imp=`0xa7f20`
  - `dismissCustomAlert:` — types=`v24@0:8@16` — imp=`0xa9024`
  - `restartSingleAppTapped:` — types=`v24@0:8@16` — imp=`0xa91ec`
  - `closeSingleAppTapped:` — types=`v24@0:8@16` — imp=`0xa9484`
  - `closeAllBridgedAppsTapped:` — types=`v24@0:8@16` — imp=`0xa9838`
  - `switchToAppPickerMode` — types=`v16@0:8` — imp=`0xa9a88`
  - `switchToLayoutChooserMode` — types=`v16@0:8` — imp=`0xa9b2c`
  - `switchToRecentMode` — types=`v16@0:8` — imp=`0xa9bd8`
  - `toggleMode` — types=`v16@0:8` — imp=`0xa9ce0`
  - `saveSlotIndex:bid:toSettings:prefs:` — types=`v48@0:8q16@24@32@40` — imp=`0xa9d1c`
  - `appSelected:` — types=`v24@0:8@16` — imp=`0xa9ea8`
  - `presetSelected:` — types=`v24@0:8@16` — imp=`0xaa4f0`
  - `showAppPickerForSlot:parentView:` — types=`v32@0:8q16@24` — imp=`0xaa800`
  - `showLayoutChooserInParentView:` — types=`v24@0:8@16` — imp=`0xaacf0`
  - `showRecentAppsInParentView:` — types=`v24@0:8@16` — imp=`0xab1d4`
  - `dismissOverlay` — types=`v16@0:8` — imp=`0xab70c`
  - `onCloseRequested` — types=`@?16@0:8` — imp=`0xab8c0`
  - `setOnCloseRequested:` — types=`v24@0:8@?16` — imp=`0xab8d0`
  - `onMultiSplitSelected` — types=`@?16@0:8` — imp=`0xab8dc`
  - `setOnMultiSplitSelected:` — types=`v24@0:8@?16` — imp=`0xab8ec`
  - `dimBackground` — types=`@16@0:8` — imp=`0xab8f8`
  - `setDimBackground:` — types=`v24@0:8@16` — imp=`0xab908`
  - `cardShadowContainer` — types=`@16@0:8` — imp=`0xab91c`
  - `setCardShadowContainer:` — types=`v24@0:8@16` — imp=`0xab92c`
  - `sheetCard` — types=`@16@0:8` — imp=`0xab940`
  - `setSheetCard:` — types=`v24@0:8@16` — imp=`0xab950`
  - `allApps` — types=`@16@0:8` — imp=`0xab964`
  - `setAllApps:` — types=`v24@0:8@16` — imp=`0xab974`
  - `appPickerScrollView` — types=`@16@0:8` — imp=`0xab988`
  - `setAppPickerScrollView:` — types=`v24@0:8@16` — imp=`0xab998`
  - `appPickerPageControl` — types=`@16@0:8` — imp=`0xab9ac`
  - `setAppPickerPageControl:` — types=`v24@0:8@16` — imp=`0xab9bc`
  - `slotBIDs` — types=`@16@0:8` — imp=`0xab9d0`
  - `setSlotBIDs:` — types=`v24@0:8@16` — imp=`0xab9e0`
  - `currentPreset` — types=`q16@0:8` — imp=`0xab9f4`
  - `setCurrentPreset:` — types=`v24@0:8q16` — imp=`0xaba04`
  - `currentRatio` — types=`d16@0:8` — imp=`0xaba14`
  - `setCurrentRatio:` — types=`v24@0:8d16` — imp=`0xaba24`
  - `targetSlotIndex` — types=`q16@0:8` — imp=`0xaba34`
  - `setTargetSlotIndex:` — types=`v24@0:8q16` — imp=`0xaba44`
  - `overlayMode` — types=`q16@0:8` — imp=`0xaba54`
  - `setOverlayMode:` — types=`v24@0:8q16` — imp=`0xaba64`
  - `headerIcon` — types=`@16@0:8` — imp=`0xaba74`
  - `setHeaderIcon:` — types=`v24@0:8@16` — imp=`0xaba84`
  - `titleLabel` — types=`@16@0:8` — imp=`0xaba98`
  - `setTitleLabel:` — types=`v24@0:8@16` — imp=`0xabaa8`
  - `appSegmentBtn` — types=`@16@0:8` — imp=`0xababc`
  - `setAppSegmentBtn:` — types=`v24@0:8@16` — imp=`0xabacc`
  - `layoutSegmentBtn` — types=`@16@0:8` — imp=`0xabae0`
  - `setLayoutSegmentBtn:` — types=`v24@0:8@16` — imp=`0xabaf0`
  - `recentSegmentBtn` — types=`@16@0:8` — imp=`0xabb04`
  - `setRecentSegmentBtn:` — types=`v24@0:8@16` — imp=`0xabb14`
  - `runningApps` — types=`@16@0:8` — imp=`0xabb28`
  - `setRunningApps:` — types=`v24@0:8@16` — imp=`0xabb38`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0xabb4c`

#### Class `CBBridgedUIAppView` : —
- Ivars: `_hosting` : `B` (1 B); `_invalidated` : `B` (1 B); `_audioOnlyBackgroundMode` : `B` (1 B); `_bundleIdentifier` : `@"NSString"` (8 B); `_appViewController` : `@"SBAppViewController"` (8 B); `_wrapperView` : `@"UIView"` (8 B); `_appScale` : `d` (8 B)
- Properties: `bundleIdentifier` (T@"NSString",C,N,V_bundleIdentifier); `appViewController` (T@"SBAppViewController",&,N,V_appViewController); `wrapperView` (T@"UIView",&,N,V_wrapperView); `appScale` (Td,N,V_appScale); `hosting` (TB,N,V_hosting); `invalidated` (TB,N,V_invalidated); `audioOnlyBackgroundMode` (TB,N,V_audioOnlyBackgroundMode)
- Instance methods (29):
  - `initWithBundleIdentifier:` — types=`@24@0:8@16` — imp=`0xac6f4`
  - `initWithBundleIdentifier:scale:` — types=`@32@0:8@16d24` — imp=`0xac704`
  - `setAppScale:` — types=`v24@0:8d16` — imp=`0xac83c`
  - `setAudioOnlyBackgroundMode:` — types=`v20@0:8B16` — imp=`0xac858`
  - `layoutSubviews` — types=`v16@0:8` — imp=`0xac8f0`
  - `hitTest:withEvent:` — types=`@40@0:8{CGPoint=dd}16@32` — imp=`0xac940`
  - `touchesBegan:withEvent:` — types=`v32@0:8@16@24` — imp=`0xaca6c`
  - `calculateNativeSizeForSlotRect:` — types=`{CGSize=dd}48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16` — imp=`0xacc28`
  - `updateLayout` — types=`v16@0:8` — imp=`0xacc6c`
  - `updateSceneSettingsFrame` — types=`v16@0:8` — imp=`0xad5bc`
  - `updateSceneFrame` — types=`v16@0:8` — imp=`0xade4c`
  - `refreshSceneLayout` — types=`v16@0:8` — imp=`0xade58`
  - `startInParentViewController:` — types=`v24@0:8@16` — imp=`0xadf30`
  - `start` — types=`v16@0:8` — imp=`0xaf00c`
  - `dismiss` — types=`v16@0:8` — imp=`0xaf01c`
  - `dealloc` — types=`v16@0:8` — imp=`0xaf1d8`
  - `bundleIdentifier` — types=`@16@0:8` — imp=`0xaf224`
  - `setBundleIdentifier:` — types=`v24@0:8@16` — imp=`0xaf234`
  - `appViewController` — types=`@16@0:8` — imp=`0xaf240`
  - `setAppViewController:` — types=`v24@0:8@16` — imp=`0xaf250`
  - `wrapperView` — types=`@16@0:8` — imp=`0xaf264`
  - `setWrapperView:` — types=`v24@0:8@16` — imp=`0xaf274`
  - `appScale` — types=`d16@0:8` — imp=`0xaf288`
  - `hosting` — types=`B16@0:8` — imp=`0xaf298`
  - `setHosting:` — types=`v20@0:8B16` — imp=`0xaf2a8`
  - `invalidated` — types=`B16@0:8` — imp=`0xaf2b8`
  - `setInvalidated:` — types=`v20@0:8B16` — imp=`0xaf2c8`
  - `audioOnlyBackgroundMode` — types=`B16@0:8` — imp=`0xaf2d8`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0xaf2e8`

#### Class `CBWindow` : —
- Ivars: `_boundDisplay` : `@"CADisplay"` (8 B); `_boundDisplayConfig` : `@"FBSDisplayConfiguration"` (8 B); `_isVisible` : `B` (1 B); `_rootWindow` : `@"UIWindow"` (8 B); `_rootViewController` : `@"UIViewController"` (8 B); `_contentView` : `@"UIVisualEffectView"` (8 B); `_multitaskingPill` : `@"CBMultitaskingPillView"` (8 B); `_multitaskingOverlay` : `@"CBMultitaskingOverlayView"` (8 B); `_appFrame` : `{CGRect="origin"{CGPoint="x"d"y"d}"size"{CGSize="width"d"height"d}}` (32 B)
- Properties: `appFrame` (T{CGRect={CGPoint=dd}{CGSize=dd}},N,V_appFrame); `rootWindow` (T@"UIWindow",&,N,V_rootWindow); `rootViewController` (T@"UIViewController",&,N,V_rootViewController); `contentView` (T@"UIVisualEffectView",&,N,V_contentView); `multitaskingPill` (T@"CBMultitaskingPillView",&,N,V_multitaskingPill); `multitaskingOverlay` (T@"CBMultitaskingOverlayView",&,N,V_multitaskingOverlay); `isVisible` (TB,N,V_isVisible)
- Instance methods (28):
  - `initWithAppFrame:` — types=`@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16` — imp=`0xaf4bc`
  - `getCarPlayDisplay` — types=`@16@0:8` — imp=`0xb0ff0`
  - `createWindows` — types=`v16@0:8` — imp=`0xb1064`
  - `multitaskingOverlay` — types=`@16@0:8` — imp=`0xb1974`
  - `resizeWindows` — types=`v16@0:8` — imp=`0xb1aac`
  - `show` — types=`v16@0:8` — imp=`0xb1d98`
  - `hide:` — types=`v24@0:8@?16` — imp=`0xb1ec0`
  - `isDisplayValid` — types=`B16@0:8` — imp=`0xb20a4`
  - `destroyWindows` — types=`v16@0:8` — imp=`0xb21f8`
  - `dismiss` — types=`v16@0:8` — imp=`0xb258c`
  - `dealloc` — types=`v16@0:8` — imp=`0xb2598`
  - `showAppPickerForSlot:` — types=`v24@0:8q16` — imp=`0xb25e4`
  - `showLayoutChooser` — types=`v16@0:8` — imp=`0xb2694`
  - `showRecentApps` — types=`v16@0:8` — imp=`0xb273c`
  - `appFrame` — types=`{CGRect={CGPoint=dd}{CGSize=dd}}16@0:8` — imp=`0xb27e4`
  - `setAppFrame:` — types=`v48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16` — imp=`0xb27f0`
  - `rootWindow` — types=`@16@0:8` — imp=`0xb2804`
  - `setRootWindow:` — types=`v24@0:8@16` — imp=`0xb280c`
  - `rootViewController` — types=`@16@0:8` — imp=`0xb2818`
  - `setRootViewController:` — types=`v24@0:8@16` — imp=`0xb2820`
  - `contentView` — types=`@16@0:8` — imp=`0xb282c`
  - `setContentView:` — types=`v24@0:8@16` — imp=`0xb2834`
  - `multitaskingPill` — types=`@16@0:8` — imp=`0xb2840`
  - `setMultitaskingPill:` — types=`v24@0:8@16` — imp=`0xb2848`
  - `setMultitaskingOverlay:` — types=`v24@0:8@16` — imp=`0xb2854`
  - `isVisible` — types=`B16@0:8` — imp=`0xb2860`
  - `setIsVisible:` — types=`v20@0:8B16` — imp=`0xb2868`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0xb2870`
- Class methods (9):
  - `+activeCarPlayWindow` — types=`@16@0:8` — imp=`0xaf554`
  - `+resetCachedBounds` — types=`v16@0:8` — imp=`0xaf570`
  - `+carPlayWindowScene` — types=`@16@0:8` — imp=`0xaf690`
  - `+carPlayUIScreen` — types=`@16@0:8` — imp=`0xafe60`
  - `+carPlayCADisplay` — types=`@16@0:8` — imp=`0xafffc`
  - `+carPlayScreenScale` — types=`d16@0:8` — imp=`0xb059c`
  - `+carPlayScreenBounds` — types=`{CGRect={CGPoint=dd}{CGSize=dd}}16@0:8` — imp=`0xb0704`
  - `+carPlayContentInsets` — types=`{UIEdgeInsets=dddd}16@0:8` — imp=`0xb0c98`
  - `+carPlayUsableBounds` — types=`{CGRect={CGPoint=dd}{CGSize=dd}}16@0:8` — imp=`0xb0ef4`

#### Class `CBDockMetricItemView` : —
- Ivars: `_iconImageView` : `@"UIImageView"` (8 B); `_fallbackIconLabel` : `@"UILabel"` (8 B); `_valueLabel` : `@"UILabel"` (8 B)
- Properties: `iconImageView` (T@"UIImageView",&,N,V_iconImageView); `fallbackIconLabel` (T@"UILabel",&,N,V_fallbackIconLabel); `valueLabel` (T@"UILabel",&,N,V_valueLabel)
- Instance methods (11):
  - `initWithFrame:` — types=`@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16` — imp=`0xb3364`
  - `layoutSubviews` — types=`v16@0:8` — imp=`0xb3700`
  - `setIconSystemName:fallbackEmoji:` — types=`v32@0:8@16@24` — imp=`0xb3930`
  - `setValue:color:` — types=`v32@0:8@16@24` — imp=`0xb3a60`
  - `iconImageView` — types=`@16@0:8` — imp=`0xb3c64`
  - `setIconImageView:` — types=`v24@0:8@16` — imp=`0xb3c74`
  - `fallbackIconLabel` — types=`@16@0:8` — imp=`0xb3c88`
  - `setFallbackIconLabel:` — types=`v24@0:8@16` — imp=`0xb3c98`
  - `valueLabel` — types=`@16@0:8` — imp=`0xb3cac`
  - `setValueLabel:` — types=`v24@0:8@16` — imp=`0xb3cbc`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0xb3cd0`

#### Class `CBDockSystemMonitorView` : —
- Ivars: `_battItem` : `@"CBDockMetricItemView"` (8 B); `_tempItem` : `@"CBDockMetricItemView"` (8 B); `_cpuItem` : `@"CBDockMetricItemView"` (8 B); `_ramItem` : `@"CBDockMetricItemView"` (8 B); `_refreshTimer` : `@"NSTimer"` (8 B); `_prevCpuUser` : `I` (4 B); `_prevCpuSystem` : `I` (4 B); `_prevCpuNice` : `I` (4 B); `_prevCpuIdle` : `I` (4 B); `_hasCpuHistory` : `B` (1 B); `_showAll` : `B` (1 B)
- Properties: `isMonitoring` (TB,R,N); `showAll` (TB,N,V_showAll); `detailedMode` (TB,N)
- Instance methods (19):
  - `initWithFrame:` — types=`@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16` — imp=`0xb3d24`
  - `dealloc` — types=`v16@0:8` — imp=`0xb4204`
  - `detailedMode` — types=`B16@0:8` — imp=`0xb428c`
  - `setDetailedMode:` — types=`v20@0:8B16` — imp=`0xb429c`
  - `setShowAll:` — types=`v20@0:8B16` — imp=`0xb42a8`
  - `willMoveToWindow:` — types=`v24@0:8@16` — imp=`0xb4344`
  - `handleTapGesture:` — types=`v24@0:8@16` — imp=`0xb43ac`
  - `layoutSubviews` — types=`v16@0:8` — imp=`0xb4604`
  - `startMonitoring` — types=`v16@0:8` — imp=`0xb49dc`
  - `stopMonitoring` — types=`v16@0:8` — imp=`0xb4ad4`
  - `isMonitoring` — types=`B16@0:8` — imp=`0xb4b20`
  - `handleBatteryNotification:` — types=`v24@0:8@16` — imp=`0xb4b40`
  - `updateBatteryMetric` — types=`v16@0:8` — imp=`0xb4b4c`
  - `updateMetrics` — types=`v16@0:8` — imp=`0xb4dbc`
  - `readDeviceTemperature` — types=`f16@0:8` — imp=`0xb5230`
  - `readCpuUsage` — types=`f16@0:8` — imp=`0xb5414`
  - `readRamUsage:total:` — types=`f32@0:8^Q16^Q24` — imp=`0xb553c`
  - `showAll` — types=`B16@0:8` — imp=`0xb564c`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0xb565c`

#### Class `CBSplitSplashScreenView` : —
- Ivars: `_glowImageView` : `@"UIImageView"` (8 B); `_horizonLineView` : `@"UIView"` (8 B); `_horizonGradient` : `@"CAGradientLayer"` (8 B); `_horizonDashedMask` : `@"CAShapeLayer"` (8 B); `_logoImageView` : `@"UIImageView"` (8 B); `_trackView` : `@"UIView"` (8 B); `_progressView` : `@"UIView"` (8 B); `_progressGradient` : `@"CAGradientLayer"` (8 B); `_badgeLabel` : `@"UILabel"` (8 B); `_isDismissing` : `B` (1 B); `_hasStartedAnimation` : `B` (1 B); `_animationStartTime` : `d` (8 B); `_onWillDismiss` : `@?` (8 B); `_onDismissed` : `@?` (8 B)
- Properties: `isDismissing` (TB,R,N); `onWillDismiss` (T@?,C,N,V_onWillDismiss); `onDismissed` (T@?,C,N,V_onDismissed)
- Instance methods (13):
  - `initWithFrame:` — types=`@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16` — imp=`0xb6358`
  - `layoutSubviews` — types=`v16@0:8` — imp=`0xb6fdc`
  - `startLoadingAnimation` — types=`v16@0:8` — imp=`0xb73bc`
  - `handleTap:` — types=`v24@0:8@16` — imp=`0xb75e4`
  - `isDismissing` — types=`B16@0:8` — imp=`0xb766c`
  - `dismissAnimated:` — types=`v20@0:8B16` — imp=`0xb767c`
  - `dismissAnimated:completion:` — types=`v28@0:8B16@?20` — imp=`0xb768c`
  - `dealloc` — types=`v16@0:8` — imp=`0xb7924`
  - `onWillDismiss` — types=`@?16@0:8` — imp=`0xb7a08`
  - `setOnWillDismiss:` — types=`v24@0:8@?16` — imp=`0xb7a18`
  - `onDismissed` — types=`@?16@0:8` — imp=`0xb7a24`
  - `setOnDismissed:` — types=`v24@0:8@?16` — imp=`0xb7a34`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0xb7a40`
- Class methods (3):
  - `+logoImage` — types=`@16@0:8` — imp=`0xb56d8`
  - `+appIconImage` — types=`@16@0:8` — imp=`0xb5ebc`
  - `+radialGlowImageForDiameter:` — types=`@24@0:8d16` — imp=`0xb60a0`

#### Class `CBLicenseShieldIconView` : —
- Instance methods (2):
  - `initWithFrame:` — types=`@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16` — imp=`0xb7b34`
  - `drawRect:` — types=`v48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16` — imp=`0xb7bcc`

#### Class `CBLicenseWarningModalView` : —
- Ivars: `_blurBackdrop` : `@"UIVisualEffectView"` (8 B); `_scrimView` : `@"UIView"` (8 B); `_cardView` : `@"UIView"` (8 B); `_shieldIconView` : `@"CBLicenseShieldIconView"` (8 B); `_titleLabel` : `@"UILabel"` (8 B); `_bodyLabel` : `@"UILabel"` (8 B); `_dismissButton` : `@"UIButton"` (8 B); `_lastTapTimestamp` : `d` (8 B); `_isDismissing` : `B` (1 B); `_onDismiss` : `@?` (8 B); `_modalType` : `q` (8 B)
- Properties: `onDismiss` (T@?,C,N,V_onDismiss); `modalType` (Tq,N,V_modalType)
- Instance methods (12):
  - `initWithFrame:modalType:` — types=`@56@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16q48` — imp=`0xb8004`
  - `setupSubviews` — types=`v16@0:8` — imp=`0xb80f0`
  - `setModalType:` — types=`v24@0:8q16` — imp=`0xb8a48`
  - `updateContentForType:` — types=`v24@0:8q16` — imp=`0xb8a60`
  - `layoutSubviews` — types=`v16@0:8` — imp=`0xb8d60`
  - `handleDismissButtonTap:` — types=`v24@0:8@16` — imp=`0xb8fb8`
  - `showAnimated:` — types=`v20@0:8B16` — imp=`0xb9028`
  - `dismissAnimated:` — types=`v20@0:8B16` — imp=`0xb91e0`
  - `onDismiss` — types=`@?16@0:8` — imp=`0xb9408`
  - `setOnDismiss:` — types=`v24@0:8@?16` — imp=`0xb9418`
  - `modalType` — types=`q16@0:8` — imp=`0xb9424`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0xb9434`

#### Class `CBBridgedApp` : —
- Ivars: `_bundleIdentifier` : `@"NSString"` (8 B); `_view` : `@"UIView"` (8 B); `_delegate` : `@"CBBridgeManager"` (8 B)
- Properties: `bundleIdentifier` (T@"NSString",C,N,V_bundleIdentifier); `view` (T@"UIView",&,N,V_view); `delegate` (T@"CBBridgeManager",W,N,V_delegate)
- Instance methods (12):
  - `initWithBundleIdentifier:frame:` — types=`@56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24` — imp=`0xb94ec`
  - `start` — types=`v16@0:8` — imp=`0xb956c`
  - `startInParentViewController:` — types=`v24@0:8@16` — imp=`0xb957c`
  - `stop` — types=`v16@0:8` — imp=`0xb9580`
  - `noteUserActivity` — types=`v16@0:8` — imp=`0xb9584`
  - `bundleIdentifier` — types=`@16@0:8` — imp=`0xb9588`
  - `setBundleIdentifier:` — types=`v24@0:8@16` — imp=`0xb9594`
  - `view` — types=`@16@0:8` — imp=`0xb959c`
  - `setView:` — types=`v24@0:8@16` — imp=`0xb95a4`
  - `delegate` — types=`@16@0:8` — imp=`0xb95b0`
  - `setDelegate:` — types=`v24@0:8@16` — imp=`0xb95c8`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0xb95d4`

#### Class `CBBridgedPortalApp` : `CBBridgedApp`
- Ivars: `_portalView` : `@"CBBridgedPortalAppView"` (8 B)
- Properties: `portalView` (T@"CBBridgedPortalAppView",&,N,V_portalView)
- Instance methods (6):
  - `initWithBundleIdentifier:frame:` — types=`@56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24` — imp=`0xb960c`
  - `start` — types=`v16@0:8` — imp=`0xb96c8`
  - `stop` — types=`v16@0:8` — imp=`0xb96e0`
  - `portalView` — types=`@16@0:8` — imp=`0xb96f8`
  - `setPortalView:` — types=`v24@0:8@16` — imp=`0xb9708`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0xb971c`

#### Class `CBUIAppContainerView` : —
- Ivars: `_uiApp` : `@"CBBridgedUIApp"` (8 B)
- Properties: `uiApp` (T@"CBBridgedUIApp",W,N,V_uiApp)
- Instance methods (6):
  - `layoutSubviews` — types=`v16@0:8` — imp=`0xb9730`
  - `hitTest:withEvent:` — types=`@40@0:8{CGPoint=dd}16@32` — imp=`0xb97cc`
  - `touchesBegan:withEvent:` — types=`v32@0:8@16@24` — imp=`0xb9888`
  - `uiApp` — types=`@16@0:8` — imp=`0xb98f8`
  - `setUiApp:` — types=`v24@0:8@16` — imp=`0xb9918`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0xb992c`

#### Class `CBBridgedUIApp` : `CBBridgedApp`
- Ivars: `_notchIdleTimer` : `@"NSTimer"` (8 B); `_lastActivityTime` : `d` (8 B); `_appView` : `@"CBBridgedUIAppView"` (8 B); `_notchPill` : `@"CBSlotPillView"` (8 B); `_customScale` : `d` (8 B)
- Properties: `appView` (T@"CBBridgedUIAppView",&,N,V_appView); `notchPill` (T@"CBSlotPillView",&,N,V_notchPill); `customScale` (Td,N,V_customScale)
- Instance methods (16):
  - `initWithBundleIdentifier:frame:` — types=`@56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24` — imp=`0xb993c`
  - `renderSize` — types=`{CGSize=dd}16@0:8` — imp=`0xb9d04`
  - `layoutSubviews` — types=`v16@0:8` — imp=`0xb9db0`
  - `noteUserActivity` — types=`v16@0:8` — imp=`0xd2dd4`
  - `showNotchPillSession` — types=`v16@0:8` — imp=`0xd2ea0`
  - `hideNotchPill` — types=`v16@0:8` — imp=`0xe6494`
  - `start` — types=`v16@0:8` — imp=`0xe6654`
  - `startInParentViewController:` — types=`v24@0:8@16` — imp=`0xe6664`
  - `stop` — types=`v16@0:8` — imp=`0xfe5dc`
  - `appView` — types=`@16@0:8` — imp=`0xfe630`
  - `setAppView:` — types=`v24@0:8@16` — imp=`0xfe640`
  - `notchPill` — types=`@16@0:8` — imp=`0xfe654`
  - `setNotchPill:` — types=`v24@0:8@16` — imp=`0xfe664`
  - `customScale` — types=`d16@0:8` — imp=`0xfe678`
  - `setCustomScale:` — types=`v24@0:8d16` — imp=`0xfe688`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0xfe698`

#### Class `CBDividerButtonInfo` : —
- Ivars: `_iconName` : `@"NSString"` (8 B); `_relativePos` : `d` (8 B); `_onSwap` : `@?` (8 B); `_onRotate` : `@?` (8 B)
- Properties: `iconName` (T@"NSString",C,N,V_iconName); `relativePos` (Td,N,V_relativePos); `onSwap` (T@?,C,N,V_onSwap); `onRotate` (T@?,C,N,V_onRotate)
- Instance methods (9):
  - `iconName` — types=`@16@0:8` — imp=`0xfe754`
  - `setIconName:` — types=`v24@0:8@16` — imp=`0xfe760`
  - `relativePos` — types=`d16@0:8` — imp=`0xfe768`
  - `setRelativePos:` — types=`v24@0:8d16` — imp=`0xfe770`
  - `onSwap` — types=`@?16@0:8` — imp=`0xfe778`
  - `setOnSwap:` — types=`v24@0:8@?16` — imp=`0xfe784`
  - `onRotate` — types=`@?16@0:8` — imp=`0xfe78c`
  - `setOnRotate:` — types=`v24@0:8@?16` — imp=`0xfe798`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0xfe7a0`

#### Class `CBDividerView` : —
- Protocol tuân thủ: UIGestureRecognizerDelegate
- Ivars: `_isVertical` : `B` (1 B); `_isBlinking` : `B` (1 B); `_moveButtons` : `@"NSMutableArray"` (8 B); `_buttonConfigs` : `@"NSMutableArray"` (8 B); `_onPanChanged` : `@?` (8 B); `_onActivity` : `@?` (8 B)
- Properties: `isVertical` (TB,N,V_isVertical); `isBlinking` (TB,N,V_isBlinking); `moveButtons` (T@"NSMutableArray",&,N,V_moveButtons); `buttonConfigs` (T@"NSMutableArray",&,N,V_buttonConfigs); `onPanChanged` (T@?,C,N,V_onPanChanged); `onActivity` (T@?,C,N,V_onActivity); `hash` (TQ,R); `superclass` (T#,R); `description` (T@"NSString",R,C); `debugDescription` (T@"NSString",R,C)
- Instance methods (27):
  - `initWithFrame:isVertical:` — types=`@52@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16B48` — imp=`0xfe7dc`
  - `gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:` — types=`B32@0:8@16@24` — imp=`0xfea48`
  - `configureWithButtonConfigs:` — types=`v24@0:8@16` — imp=`0xfea50`
  - `layoutSubviews` — types=`v16@0:8` — imp=`0xff410`
  - `updateGripLayout` — types=`v16@0:8` — imp=`0xff460`
  - `pointInside:withEvent:` — types=`B40@0:8{CGPoint=dd}16@32` — imp=`0xff728`
  - `hitTest:withEvent:` — types=`@40@0:8{CGPoint=dd}16@32` — imp=`0xff974`
  - `moveButtonTouchDown:` — types=`v24@0:8@16` — imp=`0xffbf8`
  - `moveButtonTouchUp:` — types=`v24@0:8@16` — imp=`0xffeb4`
  - `moveButtonTouchCancelled:` — types=`v24@0:8@16` — imp=`0x1002e0`
  - `handleMoveButtonLongPress:` — types=`v24@0:8@16` — imp=`0x1005f4`
  - `startBlinking` — types=`v16@0:8` — imp=`0x1009d4`
  - `stopBlinking` — types=`v16@0:8` — imp=`0x1010bc`
  - `handlePan:` — types=`v24@0:8@16` — imp=`0x10152c`
  - `isVertical` — types=`B16@0:8` — imp=`0x101668`
  - `setIsVertical:` — types=`v20@0:8B16` — imp=`0x101678`
  - `isBlinking` — types=`B16@0:8` — imp=`0x101688`
  - `setIsBlinking:` — types=`v20@0:8B16` — imp=`0x101698`
  - `moveButtons` — types=`@16@0:8` — imp=`0x1016a8`
  - `setMoveButtons:` — types=`v24@0:8@16` — imp=`0x1016b8`
  - `buttonConfigs` — types=`@16@0:8` — imp=`0x1016cc`
  - `setButtonConfigs:` — types=`v24@0:8@16` — imp=`0x1016dc`
  - `onPanChanged` — types=`@?16@0:8` — imp=`0x1016f0`
  - `setOnPanChanged:` — types=`v24@0:8@?16` — imp=`0x101700`
  - `onActivity` — types=`@?16@0:8` — imp=`0x10170c`
  - `setOnActivity:` — types=`v24@0:8@?16` — imp=`0x10171c`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0x101728`

#### Class `CBSplitContainerView` : —
- Ivars: `_splitApp` : `@"CBBridgedSplitApp"` (8 B)
- Properties: `splitApp` (T@"CBBridgedSplitApp",W,N,V_splitApp)
- Instance methods (6):
  - `layoutSubviews` — types=`v16@0:8` — imp=`0x101790`
  - `hitTest:withEvent:` — types=`@40@0:8{CGPoint=dd}16@32` — imp=`0x10182c`
  - `touchesBegan:withEvent:` — types=`v32@0:8@16@24` — imp=`0x1018e8`
  - `splitApp` — types=`@16@0:8` — imp=`0x101958`
  - `setSplitApp:` — types=`v24@0:8@16` — imp=`0x101978`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0x10198c`

#### Class `CBSlotPlaceholderView` : —
- Ivars: `_slotIndex` : `q` (8 B); `_onTap` : `@?` (8 B); `_iconView` : `@"UIImageView"` (8 B); `_titleLabel` : `@"UILabel"` (8 B); `_tapButton` : `@"UIButton"` (8 B)
- Properties: `slotIndex` (Tq,N,V_slotIndex); `onTap` (T@?,C,N,V_onTap); `iconView` (T@"UIImageView",&,N,V_iconView); `titleLabel` (T@"UILabel",&,N,V_titleLabel); `tapButton` (T@"UIButton",&,N,V_tapButton)
- Instance methods (16):
  - `initWithSlotIndex:` — types=`@24@0:8q16` — imp=`0x10199c`
  - `dealloc` — types=`v16@0:8` — imp=`0x101ff0`
  - `updateLocalizedTexts` — types=`v16@0:8` — imp=`0x102068`
  - `layoutSubviews` — types=`v16@0:8` — imp=`0x1020cc`
  - `placeholderTapped:` — types=`v24@0:8@16` — imp=`0x1022c8`
  - `slotIndex` — types=`q16@0:8` — imp=`0x1024c4`
  - `setSlotIndex:` — types=`v24@0:8q16` — imp=`0x1024d4`
  - `onTap` — types=`@?16@0:8` — imp=`0x1024e4`
  - `setOnTap:` — types=`v24@0:8@?16` — imp=`0x1024f4`
  - `iconView` — types=`@16@0:8` — imp=`0x102500`
  - `setIconView:` — types=`v24@0:8@16` — imp=`0x102510`
  - `titleLabel` — types=`@16@0:8` — imp=`0x102524`
  - `setTitleLabel:` — types=`v24@0:8@16` — imp=`0x102534`
  - `tapButton` — types=`@16@0:8` — imp=`0x102548`
  - `setTapButton:` — types=`v24@0:8@16` — imp=`0x102558`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0x10256c`

#### Class `CBBridgedSplitApp` : `CBBridgedApp`
- Ivars: `_dragStartRatio` : `d` (8 B); `_isBlinking` : `B` (1 B); `_blinkingIdleTimer` : `@"NSTimer"` (8 B); `_lastActivityTime` : `d` (8 B); `_isTransitioningFocus` : `B` (1 B); `_splashScreenView` : `@"CBSplitSplashScreenView"` (8 B); `_appViews` : `@"NSMutableArray"` (8 B); `_placeholders` : `@"NSMutableArray"` (8 B); `_containers` : `@"NSMutableArray"` (8 B); `_dividers` : `@"NSMutableArray"` (8 B); `_slotPills` : `@"NSMutableArray"` (8 B); `_splitPreset` : `q` (8 B); `_splitRatio` : `d` (8 B); `_focusedSlotIndex` : `q` (8 B)
- Properties: `splashScreenView` (T@"CBSplitSplashScreenView",&,N,V_splashScreenView); `appViews` (T@"NSMutableArray",&,N,V_appViews); `placeholders` (T@"NSMutableArray",&,N,V_placeholders); `containers` (T@"NSMutableArray",&,N,V_containers); `dividers` (T@"NSMutableArray",&,N,V_dividers); `slotPills` (T@"NSMutableArray",&,N,V_slotPills); `splitPreset` (Tq,N,V_splitPreset); `splitRatio` (Td,N,V_splitRatio); `focusedSlotIndex` (Tq,N,V_focusedSlotIndex); `isTransitioningFocus` (TB,N,V_isTransitioningFocus)
- Instance methods (49):
  - `initWithBundleIdentifier:frame:` — types=`@56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24` — imp=`0x1025d4`
  - `initWithBundleIdentifier:frame:showSplash:` — types=`@60@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24B56` — imp=`0x1025e4`
  - `handleDividerPan:isVertical:state:` — types=`v44@0:8{CGPoint=dd}16B32q36` — imp=`0x103ee0`
  - `layoutSplitViews` — types=`v16@0:8` — imp=`0x1044f8`
  - `focusSlot:animated:` — types=`v28@0:8q16B24` — imp=`0x105890`
  - `restoreSplitAnimated:` — types=`v20@0:8B16` — imp=`0x105e2c`
  - `toggleFocusForSlot:` — types=`v24@0:8q16` — imp=`0x106518`
  - `rotateAllSlotsClockwise` — types=`v16@0:8` — imp=`0x106560`
  - `configureDividerButtons` — types=`v16@0:8` — imp=`0x1067a4`
  - `updateScale:forSlot:` — types=`v32@0:8d16q24` — imp=`0x108dd8`
  - `moveSlot:direction:` — types=`v32@0:8q16q24` — imp=`0x108f28`
  - `handleDividerSwapPressed:` — types=`v24@0:8q16` — imp=`0x108fc8`
  - `swapSlot:withSlot:` — types=`v32@0:8q16q24` — imp=`0x10915c`
  - `replaceAppInSlot:withBundleIdentifier:` — types=`v32@0:8q16@24` — imp=`0x1098c0`
  - `restartSlot:` — types=`v24@0:8q16` — imp=`0x109fe4`
  - `restartAppWithBundleIdentifier:` — types=`v24@0:8@16` — imp=`0x10a8b8`
  - `removeAppWithBundleIdentifier:` — types=`v24@0:8@16` — imp=`0x10a9f0`
  - `closeSlot:` — types=`v24@0:8q16` — imp=`0x10ab28`
  - `closeAllSlots` — types=`v16@0:8` — imp=`0x10b0b8`
  - `persistSlotOrder` — types=`v16@0:8` — imp=`0x10b4ac`
  - `start` — types=`v16@0:8` — imp=`0x10bb0c`
  - `startInParentViewController:` — types=`v24@0:8@16` — imp=`0x10bb1c`
  - `stop` — types=`v16@0:8` — imp=`0x10beec`
  - `noteUserActivity` — types=`v16@0:8` — imp=`0x10c378`
  - `startBlinkingSession` — types=`v16@0:8` — imp=`0x10c464`
  - `stopBlinkingSession` — types=`v16@0:8` — imp=`0x11f558`
  - `startContainerBorderBlinking:` — types=`v24@0:8@16` — imp=`0x11fa88`
  - `stopContainerBorderBlinking:` — types=`v24@0:8@16` — imp=`0x11fcd4`
  - `splashScreenView` — types=`@16@0:8` — imp=`0x11fddc`
  - `setSplashScreenView:` — types=`v24@0:8@16` — imp=`0x11fdec`
  - `appViews` — types=`@16@0:8` — imp=`0x11fe00`
  - `setAppViews:` — types=`v24@0:8@16` — imp=`0x11fe10`
  - `placeholders` — types=`@16@0:8` — imp=`0x11fe24`
  - `setPlaceholders:` — types=`v24@0:8@16` — imp=`0x11fe34`
  - `containers` — types=`@16@0:8` — imp=`0x11fe48`
  - `setContainers:` — types=`v24@0:8@16` — imp=`0x11fe58`
  - `dividers` — types=`@16@0:8` — imp=`0x11fe6c`
  - `setDividers:` — types=`v24@0:8@16` — imp=`0x11fe7c`
  - `slotPills` — types=`@16@0:8` — imp=`0x11fe90`
  - `setSlotPills:` — types=`v24@0:8@16` — imp=`0x11fea0`
  - `splitPreset` — types=`q16@0:8` — imp=`0x11feb4`
  - `setSplitPreset:` — types=`v24@0:8q16` — imp=`0x11fec4`
  - `splitRatio` — types=`d16@0:8` — imp=`0x11fed4`
  - `setSplitRatio:` — types=`v24@0:8d16` — imp=`0x11fee4`
  - `focusedSlotIndex` — types=`q16@0:8` — imp=`0x11fef4`
  - `setFocusedSlotIndex:` — types=`v24@0:8q16` — imp=`0x11ff04`
  - `isTransitioningFocus` — types=`B16@0:8` — imp=`0x11ff14`
  - `setIsTransitioningFocus:` — types=`v20@0:8B16` — imp=`0x11ff24`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0x11ff34`

#### Class `CBBridgedAssistantView` : —
- Ivars: `_micIcon` : `@"UIImageView"` (8 B); `_titleLabel` : `@"UILabel"` (8 B); `_subtitleLabel` : `@"UILabel"` (8 B); `_pulseAnimation` : `@"CABasicAnimation"` (8 B)
- Properties: `micIcon` (T@"UIImageView",&,N,V_micIcon); `titleLabel` (T@"UILabel",&,N,V_titleLabel); `subtitleLabel` (T@"UILabel",&,N,V_subtitleLabel); `pulseAnimation` (T@"CABasicAnimation",&,N,V_pulseAnimation)
- Instance methods (15):
  - `initWithFrame:` — types=`@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16` — imp=`0x120338`
  - `startSession` — types=`v16@0:8` — imp=`0x120974`
  - `stopSession` — types=`v16@0:8` — imp=`0x120d70`
  - `tapMicToggled` — types=`v16@0:8` — imp=`0x120e28`
  - `startPulse` — types=`v16@0:8` — imp=`0x120ed4`
  - `stopPulse` — types=`v16@0:8` — imp=`0x1210ac`
  - `micIcon` — types=`@16@0:8` — imp=`0x121128`
  - `setMicIcon:` — types=`v24@0:8@16` — imp=`0x121138`
  - `titleLabel` — types=`@16@0:8` — imp=`0x12114c`
  - `setTitleLabel:` — types=`v24@0:8@16` — imp=`0x12115c`
  - `subtitleLabel` — types=`@16@0:8` — imp=`0x121170`
  - `setSubtitleLabel:` — types=`v24@0:8@16` — imp=`0x121180`
  - `pulseAnimation` — types=`@16@0:8` — imp=`0x121194`
  - `setPulseAnimation:` — types=`v24@0:8@16` — imp=`0x1211a4`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0x1211b8`

#### Class `CBBridgedAssistantApp` : `CBBridgedApp`
- Ivars: `_assistantView` : `@"CBBridgedAssistantView"` (8 B)
- Properties: `assistantView` (T@"CBBridgedAssistantView",&,N,V_assistantView)
- Instance methods (6):
  - `initWithBundleIdentifier:frame:` — types=`@56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24` — imp=`0x121220`
  - `start` — types=`v16@0:8` — imp=`0x1212dc`
  - `stop` — types=`v16@0:8` — imp=`0x1212f4`
  - `assistantView` — types=`@16@0:8` — imp=`0x12130c`
  - `setAssistantView:` — types=`v24@0:8@16` — imp=`0x12131c`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0x121330`

#### Class `CBBridgeRequest` : —
- Ivars: `_activate` : `B` (1 B); `_bundleIdentifier` : `@"NSString"` (8 B)
- Properties: `bundleIdentifier` (T@"NSString",C,N,V_bundleIdentifier); `activate` (TB,N,V_activate)
- Instance methods (6):
  - `initWithDictionary:` — types=`@24@0:8@16` — imp=`0x121344`
  - `bundleIdentifier` — types=`@16@0:8` — imp=`0x121430`
  - `setBundleIdentifier:` — types=`v24@0:8@16` — imp=`0x12143c`
  - `activate` — types=`B16@0:8` — imp=`0x121444`
  - `setActivate:` — types=`v20@0:8B16` — imp=`0x12144c`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0x121454`

#### Class `CBDashboardShared` : —
- Class methods (12):
  - `+setCurrentDashboardRootVC:` — types=`v24@0:8@16` — imp=`0x121460`
  - `+currentDashboardRootVC` — types=`@16@0:8` — imp=`0x121470`
  - `+setCurrentAppDockVC:` — types=`v24@0:8@16` — imp=`0x12148c`
  - `+currentAppDockVC` — types=`@16@0:8` — imp=`0x12149c`
  - `+setCurrentRootStatusBarVC:` — types=`v24@0:8@16` — imp=`0x1214b8`
  - `+currentRootStatusBarVC` — types=`@16@0:8` — imp=`0x1214c8`
  - `+carApp` — types=`@16@0:8` — imp=`0x1214e4`
  - `+dashboard` — types=`@16@0:8` — imp=`0x121580`
  - `+rootVC` — types=`@16@0:8` — imp=`0x121634`
  - `+homeVC` — types=`@16@0:8` — imp=`0x1216e0`
  - `+folderController` — types=`@16@0:8` — imp=`0x121758`
  - `+appDockVC` — types=`@16@0:8` — imp=`0x1217d8`

#### Class `CBBridgeManager` : —
- Ivars: `_activated` : `B` (1 B); `_isAutoResuming` : `B` (1 B); `_autoResumeRetryCount` : `q` (8 B); `_isApplyingSplitMode` : `B` (1 B); `_sessionBridgedBundleIDs` : `@"NSMutableSet"` (8 B); `_disconnectWatchdogToken` : `Q` (8 B); `_autoResumeBundleID` : `@"NSString"` (8 B); `_bundleIdentifier` : `@"NSString"` (8 B); `_window` : `@"CBWindow"` (8 B); `_currentApp` : `@"CBBridgedApp"` (8 B); `_licenseWarningModal` : `@"CBLicenseWarningModalView"` (8 B); `_licenseWatchdogTimer` : `@"NSTimer"` (8 B); `_appFrame` : `{CGRect="origin"{CGPoint="x"d"y"d}"size"{CGSize="width"d"height"d}}` (32 B); `_renderSize` : `{CGSize="width"d"height"d}` (16 B)
- Properties: `window` (T@"CBWindow",&,N,V_window); `currentApp` (T@"CBBridgedApp",&,N,V_currentApp); `licenseWarningModal` (T@"CBLicenseWarningModalView",&,N,V_licenseWarningModal); `bundleIdentifier` (T@"NSString",C,N,V_bundleIdentifier); `activated` (TB,N,V_activated); `appFrame` (T{CGRect={CGPoint=dd}{CGSize=dd}},N,V_appFrame); `renderSize` (T{CGSize=dd},N,V_renderSize); `autoResumeBundleID` (T@"NSString",C,N,V_autoResumeBundleID)
- Instance methods (73):
  - `trackBridgedBundleID:` — types=`v24@0:8@16` — imp=`0x280b60`
  - `runningBridgedApplications` — types=`@16@0:8` — imp=`0x280d48`
  - `renderSizeForBundleID:` — types=`{CGSize=dd}24@0:8@16` — imp=`0x24c920`
  - `supportsInterfaceOrientation:forBundleID:` — types=`B32@0:8q16@24` — imp=`0x24d118`
  - `switchToSplitWithLeft:right:ratio:` — types=`v40@0:8@16@24d32` — imp=`0x24d120`
  - `switchToMultiSplitMode:apps:ratio:` — types=`v40@0:8q16@24d32` — imp=`0x24d228`
  - `handleSettingsChanged` — types=`v16@0:8` — imp=`0x267764`
  - `showAppPickerForSlot:` — types=`v24@0:8q16` — imp=`0x27fee4`
  - `showLayoutChooser` — types=`v16@0:8` — imp=`0x280014`
  - `updateScale:forSlot:` — types=`v32@0:8d16q24` — imp=`0x280130`
  - `showRecentApps` — types=`v16@0:8` — imp=`0x280208`
  - `registerForNotifications` — types=`v16@0:8` — imp=`0x1d07fc`
  - `receivedDashboardReadyNotification:` — types=`v24@0:8@16` — imp=`0x1d0f10`
  - `receivedMetricsUpdatedNotification:` — types=`v24@0:8@16` — imp=`0x1d1400`
  - `sendStateToApp:shouldBridge:` — types=`v28@0:8@16B24` — imp=`0x1d1624`
  - `saveBridgeStateToDisk` — types=`v16@0:8` — imp=`0x1fd280`
  - `clearBridgeStateOnDisk` — types=`v16@0:8` — imp=`0x229748`
  - `syncDashboardPolicySignalToDisk` — types=`v16@0:8` — imp=`0x229e8c`
  - `receivedAppRequestNotification:` — types=`v24@0:8@16` — imp=`0x248e70`
  - `isUIAppBridging` — types=`B16@0:8` — imp=`0x249154`
  - `shouldBridge:` — types=`B24@0:8@16` — imp=`0x2491b0`
  - `isCurrentlyBridging:` — types=`B24@0:8@16` — imp=`0x24960c`
  - `receivedStateChangeRequestNotificiation:` — types=`v24@0:8@16` — imp=`0x24968c`
  - `receivedDockTapNotification:` — types=`v24@0:8@16` — imp=`0x249868`
  - `notifyStateUpdated` — types=`v16@0:8` — imp=`0x249a54`
  - `evictAppFromPhoneScreen:completion:` — types=`v32@0:8@16@?24` — imp=`0x24a024`
  - `scheduleMandatoryDisconnectWatchdog` — types=`v16@0:8` — imp=`0x1b9420`
  - `cancelMandatoryDisconnectWatchdog` — types=`v16@0:8` — imp=`0x1cce6c`
  - `enforceMandatoryDisconnectKill` — types=`v16@0:8` — imp=`0x1cceac`
  - `terminateApplicationWithBundleID:` — types=`v24@0:8@16` — imp=`0x1cd780`
  - `restartApplicationWithBundleID:` — types=`v24@0:8@16` — imp=`0x1cde94`
  - `terminateAllBridgedApplications` — types=`v16@0:8` — imp=`0x1ce480`
  - `collectActiveAndSessionAppBundleIDs` — types=`@16@0:8` — imp=`0x1cf0b0`
  - `killProcessesForBundleIdentifiers:` — types=`v24@0:8@16` — imp=`0x1cf874`
  - `acquireCarPlaySleepAssertion` — types=`v16@0:8` — imp=`0x19eaf8`
  - `releaseCarPlaySleepAssertion` — types=`v16@0:8` — imp=`0x19eb90`
  - `effectiveAutoLaunchBundleID` — types=`@16@0:8` — imp=`0x19ec10`
  - `scheduleAutoResumeFallback` — types=`v16@0:8` — imp=`0x19ed98`
  - `performAutoResume` — types=`v16@0:8` — imp=`0x19ee24`
  - `handleGenericScreenOrCarPlayNotification:` — types=`v24@0:8@16` — imp=`0x1b816c`
  - `handleScreenDidDisconnect:` — types=`v24@0:8@16` — imp=`0x1b82e0`
  - `handleScreenDidConnect:` — types=`v24@0:8@16` — imp=`0x1b86c8`
  - `handleCarPlayConnectionChanged:` — types=`v24@0:8@16` — imp=`0x1b8a1c`
  - `init` — types=`@16@0:8` — imp=`0x12192c`
  - `renderSize` — types=`{CGSize=dd}16@0:8` — imp=`0x13ae78`
  - `requestStateChangeWithDictionary:` — types=`v24@0:8@16` — imp=`0x13aee8`
  - `requestStateChange:` — types=`v24@0:8@16` — imp=`0x13b158`
  - `loadNewAppFromCurrentRequest:` — types=`v24@0:8@16` — imp=`0x153544`
  - `presentLicenseWarningModalWithType:` — types=`v24@0:8q16` — imp=`0x185110`
  - `dismissLicenseWarningModal` — types=`v16@0:8` — imp=`0x185450`
  - `startLicenseWatchdogTimer` — types=`v16@0:8` — imp=`0x185494`
  - `stopLicenseWatchdogTimer` — types=`v16@0:8` — imp=`0x1854fc`
  - `licenseWatchdogTimerFired:` — types=`v24@0:8@16` — imp=`0x185540`
  - `deactivateCurrentApp` — types=`v16@0:8` — imp=`0x19d458`
  - `dismiss:` — types=`v24@0:8@?16` — imp=`0x19d870`
  - `terminate` — types=`v16@0:8` — imp=`0x19d910`
  - `appForBundleIdentifier:frame:` — types=`@56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24` — imp=`0x19d984`
  - `window` — types=`@16@0:8` — imp=`0x19daf0`
  - `setWindow:` — types=`v24@0:8@16` — imp=`0x19daf8`
  - `currentApp` — types=`@16@0:8` — imp=`0x19db04`
  - `setCurrentApp:` — types=`v24@0:8@16` — imp=`0x19db0c`
  - `licenseWarningModal` — types=`@16@0:8` — imp=`0x19db18`
  - `setLicenseWarningModal:` — types=`v24@0:8@16` — imp=`0x19db20`
  - `bundleIdentifier` — types=`@16@0:8` — imp=`0x19db2c`
  - `setBundleIdentifier:` — types=`v24@0:8@16` — imp=`0x19db38`
  - `activated` — types=`B16@0:8` — imp=`0x19db40`
  - `setActivated:` — types=`v20@0:8B16` — imp=`0x19db48`
  - `appFrame` — types=`{CGRect={CGPoint=dd}{CGSize=dd}}16@0:8` — imp=`0x19db50`
  - `setAppFrame:` — types=`v48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16` — imp=`0x19db5c`
  - `setRenderSize:` — types=`v32@0:8{CGSize=dd}16` — imp=`0x19db70`
  - `autoResumeBundleID` — types=`@16@0:8` — imp=`0x19db7c`
  - `setAutoResumeBundleID:` — types=`v24@0:8@16` — imp=`0x19db88`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0x19db90`
- Class methods (2):
  - `+sharedInstance` — types=`@16@0:8` — imp=`0x121884`
  - `+sharedInstanceIfExists` — types=`@16@0:8` — imp=`0x121920`

#### Class `CBAppMetadataItem` : —
- Ivars: `_isUserApp` : `B` (1 B); `_displayName` : `@"NSString"` (8 B); `_icon` : `@"UIImage"` (8 B)
- Properties: `displayName` (T@"NSString",C,N,V_displayName); `icon` (T@"UIImage",&,N,V_icon); `isUserApp` (TB,N,V_isUserApp)
- Instance methods (7):
  - `displayName` — types=`@16@0:8` — imp=`0x280af8`
  - `setDisplayName:` — types=`v24@0:8@16` — imp=`0x280b04`
  - `icon` — types=`@16@0:8` — imp=`0x280b0c`
  - `setIcon:` — types=`v24@0:8@16` — imp=`0x280b14`
  - `isUserApp` — types=`B16@0:8` — imp=`0x280b20`
  - `setIsUserApp:` — types=`v20@0:8B16` — imp=`0x280b28`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0x280b30`

#### Class `CBBridgeManagerDashboard` : —
- Ivars: `_activated` : `B` (1 B); `_pending` : `B` (1 B); `_pendingCompletion` : `@?` (8 B)
- Properties: `activated` (TB,N,V_activated); `pending` (TB,N,V_pending); `pendingCompletion` (T@?,C,N,V_pendingCompletion)
- Instance methods (33):
  - `init` — types=`@16@0:8` — imp=`0x282cc4`
  - `registerForNotifications` — types=`v16@0:8` — imp=`0x282d2c`
  - `handleScreenDidDisconnect:` — types=`v24@0:8@16` — imp=`0x283064`
  - `handleScreenDidConnect:` — types=`v24@0:8@16` — imp=`0x283a3c`
  - `startBridging:` — types=`v24@0:8@16` — imp=`0x2a33c0`
  - `startBridging:withCompletion:` — types=`v32@0:8@16@?24` — imp=`0x2a33d0`
  - `stopBridging` — types=`v16@0:8` — imp=`0x2a3434`
  - `stopBridgingWithCompletion:` — types=`v24@0:8@?16` — imp=`0x2a3444`
  - `prepareAndRequestActivation:` — types=`v24@0:8@16` — imp=`0x2a3478`
  - `prepareHomeScreenForBridge:` — types=`v24@0:8@?16` — imp=`0x2a3600`
  - `closeOfficialTopApp:` — types=`v24@0:8@?16` — imp=`0x2a37f0`
  - `requestActivation:` — types=`v24@0:8@16` — imp=`0x2a3ad0`
  - `requestDismiss` — types=`v16@0:8` — imp=`0x2a3d34`
  - `requestStateChange:` — types=`v24@0:8@16` — imp=`0x2a3f04`
  - `handleSBStateChange:` — types=`v24@0:8@16` — imp=`0x2a4418`
  - `handleStateDict:` — types=`v24@0:8@16` — imp=`0x2a45f4`
  - `bridgeDidActivate:` — types=`v24@0:8@16` — imp=`0x2a4738`
  - `bridgeDidDeactivate` — types=`v16@0:8` — imp=`0x2a47ac`
  - `handleDockIconTap:` — types=`v24@0:8@16` — imp=`0x2a47fc`
  - `setAppDockActiveBundleID:` — types=`v24@0:8@16` — imp=`0x2a4934`
  - `setHomeButtonInApp:` — types=`v20@0:8B16` — imp=`0x2a4a3c`
  - `updateCarPlayMetrics` — types=`v16@0:8` — imp=`0x2a4c24`
  - `getAppFrame` — types=`{CGRect={CGPoint=dd}{CGSize=dd}}16@0:8` — imp=`0x2a5fd8`
  - `getDockDimension` — types=`d16@0:8` — imp=`0x2a6228`
  - `getDockWidth` — types=`d16@0:8` — imp=`0x2a63c8`
  - `getDockEdge` — types=`@16@0:8` — imp=`0x2a63d4`
  - `activated` — types=`B16@0:8` — imp=`0x2a64c8`
  - `setActivated:` — types=`v20@0:8B16` — imp=`0x2a64d0`
  - `pending` — types=`B16@0:8` — imp=`0x2a64d8`
  - `setPending:` — types=`v20@0:8B16` — imp=`0x2a64e0`
  - `pendingCompletion` — types=`@?16@0:8` — imp=`0x2a64e8`
  - `setPendingCompletion:` — types=`v24@0:8@?16` — imp=`0x2a64f4`
  - `.cxx_destruct` — types=`v16@0:8` — imp=`0x2a64fc`
- Class methods (6):
  - `+sharedInstance` — types=`@16@0:8` — imp=`0x282c28`
  - `+isOfficialApp:` — types=`B24@0:8@16` — imp=`0x283c4c`
  - `+isBridgedApp:` — types=`B24@0:8@16` — imp=`0x283ea8`
  - `+isDashboardPolicySignalActive` — types=`B16@0:8` — imp=`0x284068`
  - `+shouldInterceptLaunchForApp:` — types=`B24@0:8@16` — imp=`0x2a314c`
  - `+bridgedApps` — types=`@16@0:8` — imp=`0x2a3364`

#### Class `CBAppStateListener` : —
- Instance methods (5):
  - `init` — types=`@16@0:8` — imp=`0x2ab0a0`
  - `checkStateFile` — types=`v16@0:8` — imp=`0x2ab1e4`
  - `sendStateRequest` — types=`v16@0:8` — imp=`0x2ab7a4`
  - `handleAppDidBecomeActive:` — types=`v24@0:8@16` — imp=`0x2ab948`
  - `handleAppStateNotification:` — types=`v24@0:8@16` — imp=`0x2ab98c`
- Class methods (1):
  - `+sharedInstance` — types=`@16@0:8` — imp=`0x2ab004`

#### Protocols khai báo trong binary
- `NSObject`: instance=19, class=0, optional-inst=1, optional-class=0
  - `-isEqual:` — types=`B24@0:8@16`
  - `-class` — types=`#16@0:8`
  - `-self` — types=`@16@0:8`
  - `-performSelector:` — types=`@24@0:8:16`
  - `-performSelector:withObject:` — types=`@32@0:8:16@24`
  - `-performSelector:withObject:withObject:` — types=`@40@0:8:16@24@32`
  - `-isProxy` — types=`B16@0:8`
  - `-isKindOfClass:` — types=`B24@0:8#16`
  - `-isMemberOfClass:` — types=`B24@0:8#16`
  - `-conformsToProtocol:` — types=`B24@0:8@16`
  - `-respondsToSelector:` — types=`B24@0:8:16`
  - `-retain` — types=`@16@0:8`
  - `-release` — types=`Vv16@0:8`
  - `-autorelease` — types=`@16@0:8`
  - `-retainCount` — types=`Q16@0:8`
  - `-zone` — types=`^{_NSZone=}16@0:8`
  - `-hash` — types=`Q16@0:8`
  - `-superclass` — types=`#16@0:8`
  - `-description` — types=`@16@0:8`
- `SFSpeechRecognizerDelegate`: instance=0, class=0, optional-inst=1, optional-class=0
- `AVSpeechSynthesizerDelegate`: instance=0, class=0, optional-inst=6, optional-class=0
- `UIScrollViewDelegate`: instance=0, class=0, optional-inst=14, optional-class=0
- `UIGestureRecognizerDelegate`: instance=0, class=0, optional-inst=7, optional-class=0

- Defined symbols (slice arm64, 1):
  - `radr://5614542` @ 90260802
- Undefined/imported symbols (slice arm64, 295):
  - `_AVAudioSessionCategoryPlayAndRecord`
  - `_AVAudioSessionModeMeasurement`
  - `_CACurrentMediaTime`
  - `_CAFrameRateRangeMake`
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
  - `_CGColorSpaceCreateDeviceRGB`
  - `_CGColorSpaceRelease`
  - `_CGContextDrawLinearGradient`
  - `_CGContextDrawRadialGradient`
  - `_CGContextRestoreGState`
  - `_CGContextSaveGState`
  - `_CGGradientCreateWithColors`
  - `_CGGradientRelease`
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
  - `_OBJC_CLASS_$_AVAudioEngine`
  - `_OBJC_CLASS_$_AVAudioSession`
  - `_OBJC_CLASS_$_AVSpeechSynthesisVoice`
  - `_OBJC_CLASS_$_AVSpeechSynthesizer`
  - `_OBJC_CLASS_$_AVSpeechUtterance`
  - `_OBJC_CLASS_$_CABasicAnimation`
  - `_OBJC_CLASS_$_CADisplay`
  - `_OBJC_CLASS_$_CADisplayLink`
  - `_OBJC_CLASS_$_CAGradientLayer`
  - `_OBJC_CLASS_$_CAMediaTimingFunction`
  - `_OBJC_CLASS_$_CAShapeLayer`
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
  - `_OBJC_CLASS_$_NSUUID`
  - `_OBJC_CLASS_$_NSValue`
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
  - `_UIWindowLevelAlert`
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
  - `___stack_chk_fail`
  - `___stack_chk_guard`
  - `__dispatch_main_q`
  - `__objc_empty_cache`
  - `__tlv_bootstrap`
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
  - `_dispatch_once`
  - `_dispatch_queue_create`
  - `_dispatch_time`
  - `_dlopen`
  - `_dlsym`
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
  - `_objc_unsafeClaimAutoreleasedReturnValue`
  - `_object_getClass`
  - `_object_getIvar`
  - `_object_setIvar`
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
  - `_strsignal`
  - `_strstr`
  - `_sysctl`
  - `_sysctlbyname`
  - `_time`
  - `_vm_kernel_page_size`
  - `_vm_read_overwrite`
  - `dyld_stub_binder`

### 4.2 DuoFaceFullscreenBridge.dylib
- Đường dẫn trong gói: `var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib`
- Bộ lọc nạp: DuoFaceFullscreenBridge.plist — Filter.Bundles: 4 + Filter.Executables: 4 (xem mục 5)
- Slice 0: **arm64**, symbols defined=24, undefined/imports=90
  - Code signature: chỉ có CodeDirectory + requirements, **không có blob entitlements** (chi tiết: {"blob_type_0": ["0xfade0c02", 758], "blob_type_2": ["0xfade0c01", 148], "blob_type_4096": ["0xfade0c02", 1142]}).
  - Class ObjC: 0 · Category: 0 · Protocol khai báo: 0
- Selector được tham chiếu qua `__objc_selrefs`: 0 (danh sách đầy đủ trong `analysis/selrefs/DuoFaceFullscreenBridge.txt`).
- Class ngoài binary được tham chiếu (`_OBJC_CLASS_$_*`): 27 — danh sách ở cuối mục này.
- Thư viện liên kết: `/usr/lib/libobjc.A.dylib`, `/System/Library/Frameworks/Foundation.framework/Foundation`, `/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation`, `/System/Library/Frameworks/UIKit.framework/UIKit`, `/usr/lib/libc++.1.dylib`, `/usr/lib/libSystem.B.dylib`, `/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics`, `@rpath/CydiaSubstrate.framework/CydiaSubstrate`
- Constructor: không có `__mod_init_func` dạng pointer cổ điển (có `__init_offsets`).
- Imports liên quan hook/IPC: `_MSHookMessageEx`, `_objc_msgSend`

- Defined symbols (slice arm64, 24):
  - `radr://5614542` @ 90260802
  - `_DFDashboardRestoreChrome` @ 30856
  - `_DFDashboardSetChromeHidden` @ 31392
  - `_DFHostCanExpand` @ 17476
  - `_DFHostIsExpanded` @ 18412
  - `_DFHostRestore` @ 19184
  - `_DFHostSetExpanded` @ 20084
  - `_DFHostSetLifecycleCallback` @ 19104
