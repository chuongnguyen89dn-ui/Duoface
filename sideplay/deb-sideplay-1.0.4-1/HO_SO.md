# HỒ SƠ QUÉT TĨNH TẬN GỐC — SIDEPLAY 1.0.4-1

> Loại tài liệu: hồ sơ tra cứu, phân tích **chỉ-đọc** (static analysis). Không binary/script nào của gói được thực thi. Ngày quét: 2026-11-05. Công cụ: GitHub API (chỉ-đọc), `llvm-otool-18`, `llvm-objdump-18`, `llvm-nm-18`, `strings`, parser ObjC tự viết (đọc `__objc_classlist`/method list/ivar/property trực tiếp từ Mach-O).

---

## 1. KẾT LUẬN ĐỊNH DANH + BẰNG CHỨNG

### 1.1. Kết luận

**"SidePlay 1.0.4-1" là một gói ĐỘC LẬP, KHÔNG phải tên gọi khác của DuoFace 1.0.4-1.**

- Package ID: `com.sideplay` — khác hẳn `com.duonavi.app` (DuoNavi/DuoFace 1.0.4).
- Gói có bộ binary, app, preference bundle và hệ thống HUD riêng mang tiền tố `SP`/`SPH`, không dùng chung payload với DuoFace.
- Trên máy phân tích **không tồn tại file .deb rời** của SidePlay; nguồn quét là cây đã giải nén được lưu trong repo (xem 1.3), đã đối chiếu toàn vẹn 139/139 file theo SHA-256 của bản kiểm kê gốc (xem 1.4).

### 1.2. Bằng chứng quyết định — file `control` (đọc trực tiếp từ nguồn)

```
Package: com.sideplay
Name: SidePlay
Description: Split screen for CarPlay. Run any app on the car screen, one or two side by side.
Depends: firmware (>= 15.0), mobilesubstrate, preferenceloader
Conflicts: com.cortex.carplayenable, com.pavunato.carsurf, com.bmt.dash, com.chou.googlemaps.vietmap
Maintainer: SidePlay
Author: SidePlay
Section: Tweaks
SileoDepiction: https://sideplay.pages.dev/depictions/com.sideplay.json
Icon: https://sideplay.pages.dev/CydiaIcon.png
Architecture: iphoneos-arm64
Version: 1.0.4-1
Installed-Size: 7196
```

### 1.3. Nguồn đã quét (đường dẫn đầy đủ)

| # | Nguồn | Vai trò |
|---|---|---|
| 1 | GitHub `chuongnguyen89dn-ui/Duoface`, nhánh `spec-main`, thư mục `sideplay/extracted-1.0.4-1/` (README trong thư mục ghi: *"SidePlay 1.0.4-1 unpacked original — rootfs/ = original package payload; control/ = Debian control scripts and metadata. Paths are unmodified."*) | **Nguồn quét chính**: 136 file payload + 3 file control, tải về `work/src/` và quét tại chỗ |
| 2 | GitHub, cùng repo/nhánh: `sideplay/audit/deb-1.0.4-1/` (`summary.json`, `package-info.txt`, `archive-members.txt`, `control-fields.txt`, `inventory.json`, `SHA256SUMS.txt`) | Đối chiếu định danh cấp .deb và toàn vẹn từng file |
| 3 | GitHub, cùng repo/nhánh: `sideplay/AUDIT_SIDEPLAY_1.0.4-1_20261018.md` | Hồ sơ audit lịch sử 18/10/2026 (thời điểm đó chưa có byte để quét lại — nay đã có cây extracted nên hồ sơ này thay thế bằng quét trực tiếp) |
| 4 | `/home/hatch/workspace` (toàn bộ cây, `find -iname '*sideplay*'` và `find -iname '*.deb'`) | Truy tìm bản .deb rời: **không có** .deb nào của SidePlay; các .deb tìm thấy thuộc DuoNavi/QA/MyTweak/OmniCar/demo — không liên quan |

### 1.4. Chuỗi toàn vẹn (integrity chain)

| Hạng mục | Giá trị |
|---|---|
| Tên file .deb gốc | `com.sideplay_1.0.4-1_iphoneos-arm64.deb` |
| Kích thước .deb | 4.352.576 byte |
| SHA-256 của .deb (theo `sideplay/audit/deb-1.0.4-1/summary.json`, ghi từ lần bóc gói gốc 18/10/2026) | `7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c` |
| Thành viên archive .deb | `debian-binary`, `control.tar.xz`, `data.tar.xz` (Debian package v2.0) |
| Số file payload (rootfs) | 136 file thường, 0 symlink, 14 thư mục |
| Đối chiếu cây extracted tải về ↔ `inventory.json` (SHA-256 + size từng file) | **139/139 file khớp tuyệt đối** (136 payload + control/postinst/prerm), 0 lệch, 0 thiếu. Kích thước từng blob trên Git cũng khớp 140/140 (kể cả README của thư mục extracted) |
| Hệ quả | Cây extracted trong repo là **bản sao byte-chính-xác** của payload .deb gốc; kết quả quét dưới đây có giá trị như quét trực tiếp từ .deb. Riêng SHA-256 của chính file .deb không tính lại được vì không còn file .deb — giá trị trên là số liệu kiểm kê gốc, đã ghi rõ nguồn |

### 1.5. Maintainer scripts (đọc, KHÔNG chạy)

- `postinst` (241 byte): chạy `uicache -p /var/jb/Applications/SidePlay.app` để đăng ký app lên Home Screen/CarPlay.
- `prerm` (530 byte): khi `remove`/`purge`, chạy nền `SidePlay --sp-goodbye` (app tự báo server là máy đã gỡ — ghi chú trong script: "anonymous install list"), rồi `uicache -u` hủy đăng ký app.

---

## 2. CÂY FILE 100% CỦA NGUỒN ĐÃ QUÉT

Tổng: **140 blob** trong thư mục extracted (= 136 file payload + 3 file control + 1 README của chính thư mục extracted). Dưới đây liệt kê 139 file thuộc gói (payload + control). Kích thước = byte. SHA-256 của 7 Mach-O và các file then chốt nằm ở mục 3 và đối chiếu đầy đủ ở `sideplay/audit/deb-1.0.4-1/SHA256SUMS.txt` trong repo.

### 2.1. control/

| File | Byte |
|---|---:|
| `control/control` | 536 |
| `control/postinst` | 241 |
| `control/prerm` | 530 |

### 2.2. rootfs/ (payload cài đặt, tiền tố `var/jb/`)

| File | Byte |
|---|---:|
| `rootfs/var/jb/Applications/SidePlay.app/AppIcon40x40@2x.png` | 3392 |
| `rootfs/var/jb/Applications/SidePlay.app/AppIcon40x40@3x.png` | 5746 |
| `rootfs/var/jb/Applications/SidePlay.app/AppIcon60x60@2x.png` | 5746 |
| `rootfs/var/jb/Applications/SidePlay.app/AppIcon60x60@3x.png` | 9274 |
| `rootfs/var/jb/Applications/SidePlay.app/Info.plist` | 2688 |
| `rootfs/var/jb/Applications/SidePlay.app/SidePlay` | 178672 |
| `rootfs/var/jb/Library/MobileSubstrate/DynamicLibraries/SidePlay.dylib` | 899088 |
| `rootfs/var/jb/Library/MobileSubstrate/DynamicLibraries/SidePlay.plist` | 76 |
| `rootfs/var/jb/Library/MobileSubstrate/DynamicLibraries/SidePlayHUDGofa.dylib` | 129936 |
| `rootfs/var/jb/Library/MobileSubstrate/DynamicLibraries/SidePlayHUDGofa.plist` | 49 |
| `rootfs/var/jb/Library/MobileSubstrate/DynamicLibraries/SidePlayHUDRelay.dylib` | 240128 |
| `rootfs/var/jb/Library/MobileSubstrate/DynamicLibraries/SidePlayHUDRelay.plist` | 57 |
| `rootfs/var/jb/Library/MobileSubstrate/DynamicLibraries/SidePlayHUDVietMap.dylib` | 162752 |
| `rootfs/var/jb/Library/MobileSubstrate/DynamicLibraries/SidePlayHUDVietMap.plist` | 51 |
| `rootfs/var/jb/Library/MobileSubstrate/DynamicLibraries/SidePlayHUDWaze.dylib` | 145328 |
| `rootfs/var/jb/Library/MobileSubstrate/DynamicLibraries/SidePlayHUDWaze.plist` | 51 |
| `rootfs/var/jb/Library/PreferenceBundles/SidePlayPrefs.bundle/Info.plist` | 676 |
| `rootfs/var/jb/Library/PreferenceBundles/SidePlayPrefs.bundle/Root.plist` | 5762 |
| `rootfs/var/jb/Library/PreferenceBundles/SidePlayPrefs.bundle/SidePlayPrefs` | 613648 |
| `rootfs/var/jb/Library/PreferenceBundles/SidePlayPrefs.bundle/icon.png` | 1121 |
| `rootfs/var/jb/Library/PreferenceBundles/SidePlayPrefs.bundle/icon@2x.png` | 2798 |
| `rootfs/var/jb/Library/PreferenceBundles/SidePlayPrefs.bundle/icon@3x.png` | 4602 |
| `rootfs/var/jb/Library/PreferenceLoader/Preferences/SidePlay.plist` | 513 |
| `rootfs/var/jb/usr/share/sideplay-hud/LICENSE-GMapHUD` | 1077 |
| `rootfs/var/jb/usr/share/sideplay-hud/accident-minor.png` | 57015 |
| `rootfs/var/jb/usr/share/sideplay-hud/accident.png` | 64727 |
| `rootfs/var/jb/usr/share/sideplay-hud/animal.png` | 58217 |
| `rootfs/var/jb/usr/share/sideplay-hud/assistance.png` | 64442 |
| `rootfs/var/jb/usr/share/sideplay-hud/average-speed-enforcement.png` | 86541 |
| `rootfs/var/jb/usr/share/sideplay-hud/bad-weather.png` | 56487 |
| `rootfs/var/jb/usr/share/sideplay-hud/blocked-lane.png` | 41269 |
| `rootfs/var/jb/usr/share/sideplay-hud/both-shoulders-ending.png` | 44793 |
| `rootfs/var/jb/usr/share/sideplay-hud/bus-lane-cam.png` | 82292 |
| `rootfs/var/jb/usr/share/sideplay-hud/camera_ai.png` | 20949 |
| `rootfs/var/jb/usr/share/sideplay-hud/closed-lane-construction.png` | 55349 |
| `rootfs/var/jb/usr/share/sideplay-hud/closed-lane-crash.png` | 60765 |
| `rootfs/var/jb/usr/share/sideplay-hud/closure.png` | 45463 |
| `rootfs/var/jb/usr/share/sideplay-hud/cyclist.png` | 79644 |
| `rootfs/var/jb/usr/share/sideplay-hud/dangerous-curves.png` | 46880 |
| `rootfs/var/jb/usr/share/sideplay-hud/dangerous-intersection.png` | 36709 |
| `rootfs/var/jb/usr/share/sideplay-hud/dangerous-zone.png` | 61222 |
| `rootfs/var/jb/usr/share/sideplay-hud/distance-between-vehicles-camera.png` | 89957 |
| `rootfs/var/jb/usr/share/sideplay-hud/dummy-camera.png` | 84532 |
| `rootfs/var/jb/usr/share/sideplay-hud/emergency-vehicle.png` | 52284 |
| `rootfs/var/jb/usr/share/sideplay-hud/fork.png` | 49748 |
| `rootfs/var/jb/usr/share/sideplay-hud/hazard-animals.png` | 56332 |
| `rootfs/var/jb/usr/share/sideplay-hud/hazard-broken-light.png` | 56583 |
| `rootfs/var/jb/usr/share/sideplay-hud/hazard-construction.png` | 52101 |
| `rootfs/var/jb/usr/share/sideplay-hud/hazard-object-on-road.png` | 47802 |
| `rootfs/var/jb/usr/share/sideplay-hud/hazard-on-shoulder.png` | 49116 |
| `rootfs/var/jb/usr/share/sideplay-hud/hazard-pothole.png` | 53713 |
| `rootfs/var/jb/usr/share/sideplay-hud/hazard-roadkill.png` | 76723 |
| `rootfs/var/jb/usr/share/sideplay-hud/hazard-stopped.png` | 48005 |
| `rootfs/var/jb/usr/share/sideplay-hud/hazard-weather-flood.png` | 57704 |
| `rootfs/var/jb/usr/share/sideplay-hud/hazard-weather-fog.png` | 48630 |
| `rootfs/var/jb/usr/share/sideplay-hud/hazard-weather-hail.png` | 59158 |
| `rootfs/var/jb/usr/share/sideplay-hud/hazard-weather-ice.png` | 53307 |
| `rootfs/var/jb/usr/share/sideplay-hud/hazard-weather-snow.png` | 61552 |
| `rootfs/var/jb/usr/share/sideplay-hud/hazard.png` | 63954 |
| `rootfs/var/jb/usr/share/sideplay-hud/hazardonroad.png` | 52021 |
| `rootfs/var/jb/usr/share/sideplay-hud/highway-crosswalk.png` | 53665 |
| `rootfs/var/jb/usr/share/sideplay-hud/highway_rest_area.png` | 17538 |
| `rootfs/var/jb/usr/share/sideplay-hud/hov-camera.png` | 82860 |
| `rootfs/var/jb/usr/share/sideplay-hud/intersection.png` | 36709 |
| `rootfs/var/jb/usr/share/sideplay-hud/khu_dan_cu.png` | 6294 |
| `rootfs/var/jb/usr/share/sideplay-hud/lanes-merging.png` | 44093 |
| `rootfs/var/jb/usr/share/sideplay-hud/left-lane-ending.png` | 43185 |
| `rootfs/var/jb/usr/share/sideplay-hud/left-shoulder-ending.png` | 39018 |
| `rootfs/var/jb/usr/share/sideplay-hud/leftAndRightTurnOnly.png` | 9036 |
| `rootfs/var/jb/usr/share/sideplay-hud/leftTurnOnly.png` | 7766 |
| `rootfs/var/jb/usr/share/sideplay-hud/limit_80.png` | 19310 |
| `rootfs/var/jb/usr/share/sideplay-hud/merge.png` | 44093 |
| `rootfs/var/jb/usr/share/sideplay-hud/missing-sign.png` | 43818 |
| `rootfs/var/jb/usr/share/sideplay-hud/narrow-bridge.png` | 50467 |
| `rootfs/var/jb/usr/share/sideplay-hud/noEntry.png` | 13539 |
| `rootfs/var/jb/usr/share/sideplay-hud/noEntryNoLeftTurn.png` | 14997 |
| `rootfs/var/jb/usr/share/sideplay-hud/noEntryNoRightTurn.png` | 14912 |
| `rootfs/var/jb/usr/share/sideplay-hud/noLeftTurn.png` | 13613 |
| `rootfs/var/jb/usr/share/sideplay-hud/noLeftTurnNoRightTurn.png` | 15166 |
| `rootfs/var/jb/usr/share/sideplay-hud/noLeftTurnUTurn.png` | 14774 |
| `rootfs/var/jb/usr/share/sideplay-hud/noRightTurn.png` | 13953 |
| `rootfs/var/jb/usr/share/sideplay-hud/noRightTurnUTurn.png` | 14986 |
| `rootfs/var/jb/usr/share/sideplay-hud/noUTurnLeft.png` | 13885 |
| `rootfs/var/jb/usr/share/sideplay-hud/noUTurnRight.png` | 13544 |
| `rootfs/var/jb/usr/share/sideplay-hud/no_passing_in.png` | 16505 |
| `rootfs/var/jb/usr/share/sideplay-hud/no_passing_out.png` | 30608 |
| `rootfs/var/jb/usr/share/sideplay-hud/noise-camera.png` | 83204 |
| `rootfs/var/jb/usr/share/sideplay-hud/oil-spill.png` | 50831 |
| `rootfs/var/jb/usr/share/sideplay-hud/penalty_camera.png` | 17248 |
| `rootfs/var/jb/usr/share/sideplay-hud/phone-camera.png` | 80136 |
| `rootfs/var/jb/usr/share/sideplay-hud/police-mobile-camera.png` | 58254 |
| `rootfs/var/jb/usr/share/sideplay-hud/police.png` | 60031 |
| `rootfs/var/jb/usr/share/sideplay-hud/railway.png` | 12929 |
| `rootfs/var/jb/usr/share/sideplay-hud/rain.png` | 51796 |
| `rootfs/var/jb/usr/share/sideplay-hud/raised-crosswalk.png` | 54170 |
| `rootfs/var/jb/usr/share/sideplay-hud/red-light-and-speed-camera.png` | 85834 |
| `rootfs/var/jb/usr/share/sideplay-hud/residential_area_in.png` | 6294 |
| `rootfs/var/jb/usr/share/sideplay-hud/residential_area_out.png` | 7247 |
| `rootfs/var/jb/usr/share/sideplay-hud/retrict_unknown.png` | 14122 |
| `rootfs/var/jb/usr/share/sideplay-hud/right-lane-ending.png` | 43456 |
| `rootfs/var/jb/usr/share/sideplay-hud/right-shoulder-ending.png` | 39255 |
| `rootfs/var/jb/usr/share/sideplay-hud/rightTurnOnly.png` | 7665 |
| `rootfs/var/jb/usr/share/sideplay-hud/school-zone.png` | 65548 |
| `rootfs/var/jb/usr/share/sideplay-hud/seatbelt-camera.png` | 87592 |
| `rootfs/var/jb/usr/share/sideplay-hud/slippery-road.png` | 54907 |
| `rootfs/var/jb/usr/share/sideplay-hud/slow_down.png` | 12575 |
| `rootfs/var/jb/usr/share/sideplay-hud/speed-bumps.png` | 37479 |
| `rootfs/var/jb/usr/share/sideplay-hud/speed_limit_10.png` | 15811 |
| `rootfs/var/jb/usr/share/sideplay-hud/speed_limit_100.png` | 19023 |
| `rootfs/var/jb/usr/share/sideplay-hud/speed_limit_110.png` | 16335 |
| `rootfs/var/jb/usr/share/sideplay-hud/speed_limit_120.png` | 18291 |
| `rootfs/var/jb/usr/share/sideplay-hud/speed_limit_15.png` | 73861 |
| `rootfs/var/jb/usr/share/sideplay-hud/speed_limit_20.png` | 17707 |
| `rootfs/var/jb/usr/share/sideplay-hud/speed_limit_25.png` | 82584 |
| `rootfs/var/jb/usr/share/sideplay-hud/speed_limit_30.png` | 18659 |
| `rootfs/var/jb/usr/share/sideplay-hud/speed_limit_35.png` | 86294 |
| `rootfs/var/jb/usr/share/sideplay-hud/speed_limit_40.png` | 16785 |
| `rootfs/var/jb/usr/share/sideplay-hud/speed_limit_45.png` | 77455 |
| `rootfs/var/jb/usr/share/sideplay-hud/speed_limit_5.png` | 72022 |
| `rootfs/var/jb/usr/share/sideplay-hud/speed_limit_50.png` | 18036 |
| `rootfs/var/jb/usr/share/sideplay-hud/speed_limit_60.png` | 18950 |
| `rootfs/var/jb/usr/share/sideplay-hud/speed_limit_70.png` | 16706 |
| `rootfs/var/jb/usr/share/sideplay-hud/speed_limit_80.png` | 19310 |
| `rootfs/var/jb/usr/share/sideplay-hud/speed_limit_90.png` | 19010 |
| `rootfs/var/jb/usr/share/sideplay-hud/speed_limit_camera.png` | 19742 |
| `rootfs/var/jb/usr/share/sideplay-hud/stop-sign-camera.png` | 84703 |
| `rootfs/var/jb/usr/share/sideplay-hud/stop_lane.png` | 33121 |
| `rootfs/var/jb/usr/share/sideplay-hud/straightAheadOnly.png` | 7500 |
| `rootfs/var/jb/usr/share/sideplay-hud/straightAndLeftTurnOnly.png` | 8917 |
| `rootfs/var/jb/usr/share/sideplay-hud/straightAndRightTurnOnly.png` | 8878 |
| `rootfs/var/jb/usr/share/sideplay-hud/toll.png` | 9803 |
| `rootfs/var/jb/usr/share/sideplay-hud/toll_etc.png` | 12245 |
| `rootfs/var/jb/usr/share/sideplay-hud/topes.png` | 37645 |
| `rootfs/var/jb/usr/share/sideplay-hud/traffic_camera.png` | 18633 |
| `rootfs/var/jb/usr/share/sideplay-hud/tunnel.png` | 10761 |
| `rootfs/var/jb/usr/share/sideplay-hud/unplowed-road.png` | 58229 |

Phân bố payload: 7 Mach-O (2.369.552 byte), 9 plist, 119 PNG (4 icon app + 3 icon prefs + 112 biểu tượng cảnh báo/giới hạn tốc độ trong `usr/share/sideplay-hud/`), 1 file giấy phép `LICENSE-GMapHUD` (MIT, 1.077 byte — chỉ áp cho thành phần GMapHUD).

---

## 3. TỪNG BINARY — ĐỊNH DANH KỸ THUẬT

Bảng tổng quan (kiến trúc/SHA-256 tính trực tiếp trên file đã tải về; mọi binary đều có `LC_CODE_SIGNATURE` — chữ ký kiểu jailbreak/ldid, xem ghi chú entitlements):

| Binary | Kích thước | Kiến trúc | Loại | SHA-256 |
|---|---:|---|---|---|
| `SidePlay.dylib` | 899.088 | **fat: arm64 + arm64e** | MH_DYLIB | `0fc34c6c8e47283d2223d70facfe3e86ed76bd568958786b67a9430127242971` |
| `SidePlayHUDRelay.dylib` | 240.128 | **fat: arm64 + arm64e** | MH_DYLIB | `513142a87eb45a9279850bc6a7a1420ebf7e7766b7f5a78b2525f1a6e9606736` |
| `SidePlayPrefs` (bundle) | 613.648 | **fat: arm64 + arm64e** | MH_DYLIB (BNDL) | `3b68dd567ffdc9ec11672ed2aee9391d50f84c2f019f7709458d5c720f874636` |
| `SidePlay` (app) | 178.672 | arm64 | MH_EXECUTE, PIE | `338173777cc588c7dadb46ad2a01f25e74f7231e7ffca325cd3bfdca189d9ba2` |
| `SidePlayHUDVietMap.dylib` | 162.752 | arm64 | MH_DYLIB | `b79905049c97f496733c6614b0f1f18b9b7b888766a867f0b3c2ef7024a159ec` |
| `SidePlayHUDWaze.dylib` | 145.328 | arm64 | MH_DYLIB | `b6f2e0896d401202e1847ba07e2094d37ca94e245451ba388cd9b35fb9e92057` |
| `SidePlayHUDGofa.dylib` | 129.936 | arm64 | MH_DYLIB | `ab655d41a8abee367a654c151e26261ee2e5b08d73e8e06a08dea058e1bb473e` |

**Entitlements** (giải mã trực tiếp từ superblob chữ ký):
- `SidePlay.app/SidePlay` — có XML entitlements: `application-identifier = com.sideplay.app`, **`com.apple.developer.carplay-audio = true`**, `platform-application = true`, `com.apple.private.security.no-container = true`, `com.apple.private.security.container-required = false`. (Có cả DER entitlements.) → App là *platform app* có entitlement CarPlay audio thật, chạy không container.
- Cả 6 binary còn lại: **không có XML entitlements** trong chữ ký (đúng thông lệ dylib tweak ký bằng ldid không entitlement).

**Ghi chú bản build**: trong các HUD dylib còn sót chuỗi tên file tạm lúc liên kết dạng `SidePlayHUD*.dylib.8ffb3193.unsigned` — dấu vết pipeline build (ký sau), không có ý nghĩa vận hành.

### 3.1. `SidePlay.dylib` — LÕI TWEAK (SpringBoard scene host)

- **Đường dẫn cài**: `var/jb/Library/MobileSubstrate/DynamicLibraries/SidePlay.dylib`
- **Install name**: `@rpath/SidePlay.dylib`
- **Filter** (`SidePlay.plist`): `{ Filter = { Bundles = ("com.apple.springboard", "com.apple.UIKit"); }; }` → nạp vào SpringBoard và **mọi tiến trình UIKit** (filter UIKit là filter bao trùm; hành vi thực tế trong app thường bị chặn bởi kiểm tra tiến trình trong constructor — xem mục 7).
- **Thư viện liên kết**: libobjc, Foundation, CoreFoundation, UIKit, QuartzCore, libc++, libSystem, CoreGraphics, **CydiaSubstrate** (`@rpath/CydiaSubstrate.framework/CydiaSubstrate`).
- **API hook/IPC import**: `MSHookMessageEx`, `MSHookFunction`, `CFNotificationCenterGetDarwinNotifyCenter/AddObserver/PostNotification`, bộ `notify_*` của libnotify (`notify_register_dispatch`, `notify_register_check`, `notify_get_state`, `notify_set_state`, `notify_post`, `notify_cancel`), `objc_getClass`.
- **Bằng chứng nạp thành công** (chuỗi log trong binary): `SidePlay loaded in SpringBoard`, `[SidePlay] kill switch present, not loading` (kill switch = file `/var/mobile/Library/Preferences/.sideplay-disable`), `[SidePlay] disabled after %ld quick SpringBoard restarts` (đếm boot ở `.sideplay-boot-count` — cơ chế chống vòng lặp crash).
- **Class riêng**: 11 class, **418 method** (bảng đầy đủ ở 4.1): `SPDash` (bộ điều phối chính, instanceSize 272), `SPPane` (mỗi ô app được host, instanceSize 320), `SPCardScroll`, `SPDashCard`, `SPDashQuick`, `SPCalibrationView`, `SPLoadingView`, `SPHudGestures`, và 3 class HUD nhúng phía lõi: `SPHOutputEndpointSidePlay`, `SPHSpeedCardSidePlay`, `SPHOverspeedFrameSidePlay`.
- **Class SpringBoard/FrontBoard mà lõi tham chiếu** (chuỗi + classrefs — bằng chứng mức *tham chiếu*, cặp class+selector hook chính xác cần disassembly, xem mục 7): `SBApplicationController`, `SBDeviceApplicationSceneEntity`, `SBAppViewController`, `SBDeviceApplicationSceneView`, `SBApplicationSceneView`, `SBSceneView`, `FBScene`, `FBSceneMonitor`, `FBSSceneSettings`, `FBSSceneParameters`, `FBSMutableSceneSettings`, `FBSOpenApplicationService`, `SBSceneManagerCoordinator`, `SBMainDisplaySceneLayoutViewController`, `SBMainSwitcherViewController`, `SBSuspendedUnderLockManager`, `SBMediaController`, `SBHomeGesturePanGestureRecognizer`, `FBSDisplayConfiguration`.
- **Hàm C riêng**: 102 hàm (danh sách đầy đủ ở 4.8) — gồm họ `SPH*` dùng chung với HUD (protocol bong bóng tốc độ), họ `SPAudio*` (nghe sự kiện âm thanh/media để giữ phiên), `SPAppSupportsPad`, họ hình học thẻ CarPlay `SPHCarPlayCardSizeForLayout`/`SPHCardCanvasSize`/`SPHClampCardOrigin`…

### 3.2. `SidePlayHUDRelay.dylib` — RELAY PHÍA SPRINGBOARD CHO HUD

- **Đường dẫn cài**: `.../DynamicLibraries/SidePlayHUDRelay.dylib`; install name `@rpath/SidePlayHUDRelay.dylib`.
- **Filter**: `{ Filter = { Bundles = ("com.apple.springboard"); }; }` → chỉ SpringBoard.
- **Thư viện liên kết**: libobjc, Foundation, CoreFoundation, **CoreLocation**, UIKit, CydiaSubstrate, libSystem. (Không import MSHook* — relay không hook message; nó chạy bằng constructor + notify.)
- **Class ObjC riêng**: chỉ 1 — `SPHOutputEndpoint` (đầu cuối nhận dữ liệu HUD, dùng chung mã nguồn với các HUD source). Toàn bộ logic còn lại là **48 hàm C** họ `SPH*` (bảng 4.8): encode/decode mọi loại payload HUD (sample tốc độ, alert, placement, size, bubble layout/visibility, module order, phone placement, overspeed lease), hàm publish/read qua notify: `SPHPublishSourceOutput`, `SPHReadSourceOutput`, `SPHOutputRequestName`, `SPHSelectOutputSource`, `SPHPublishOverspeedLease`, tên hiển thị cảnh báo `SPHRoadAlertName`, tên icon `SPHRoadAlertIconName` (ánh xạ sang 112 PNG trong `usr/share/sideplay-hud/`).
- Vai trò: nhận dữ liệu từ các HUD source (trong tiến trình app bản đồ) qua kênh notify/Darwin + trạng thái chia sẻ, chọn nguồn đang hoạt động, và cấp dữ liệu cho phần vẽ bong bóng ở lõi/`SidePlay.app`.

### 3.3. `SidePlayHUDGofa.dylib` — NGUỒN HUD TRONG APP GOFA

- **Filter**: `com.lumi.GOFA`. Install name `@rpath/SidePlayHUDGofa.dylib`.
- **Thư viện liên kết**: libobjc, Foundation, CoreFoundation, UIKit, **CoreLocation**, CydiaSubstrate, libSystem, **libswiftCore (Swift 5.8)** — binary lai ObjC/Swift.
- **Hook**: import `MSHookMessageEx` + bộ `notify_*`.
- **Class ObjC riêng**: `SPHOutputEndpoint`, `SPHLocationSession` (quản lý phiên GPS dùng chung cho cả 3 nguồn).
- **Phần Swift** (module `SPHGofa`, thấy qua symbol đã demangle một phần): `SPHGofa.gofaSpeedBoard(...)` và `SPHGofa.gofaPoints(...)` — đọc dữ liệu từ các model của chính app GOFA: `GOFA.SpeedBoardModel`, `GOFA.DatapointModel`, `GOFA.GofaLocationManager` (chuỗi tên class Swift của app đích).
- **Hàm C riêng**: 29 hàm họ `SPH*` (bảng 4.8).

### 3.4. `SidePlayHUDVietMap.dylib` — NGUỒN HUD TRONG APP VIETMAP LIVE

- **Filter**: `vn.vietmap.live`. Install name `@rpath/SidePlayHUDVietMap.dylib`.
- **Thư viện liên kết**: như Gofa trừ libswiftCore (thuần ObjC/C).
- **Hook**: `MSHookMessageEx` + `notify_*`.
- **Class ObjC riêng**: `SPHOutputEndpoint`, `SPHLocationSession`, **`SPHNavSource`** (bắt dữ liệu dẫn đường/overlay của VietMap; hàm C hỗ trợ: `_SPHNavPayload`, `_SPHNavCopyOverlayArguments`, `_SPHVietMapAlertObservation`).
- Chuỗi trạng thái: `SidePlay HUD VietMap source loaded`, `VietMap overlay handler registered`.
- **Hàm C riêng**: 45 hàm họ `SPH*` (bảng 4.8).

### 3.5. `SidePlayHUDWaze.dylib` — NGUỒN HUD TRONG APP WAZE

- **Filter**: `com.waze.iphone`. Install name `@rpath/SidePlayHUDWaze.dylib`.
- **Thư viện liên kết**: như VietMap. **Hook**: `MSHookMessageEx` + `notify_*`.
- **Class ObjC riêng**: `SPHOutputEndpoint`, `SPHLocationSession`, **`SPHWazeOutputStore`**; điểm vào C: `_SPHInitializeWazeNavigation`, `_SPHStopWazeNavigation`.
- **Kiểm tra ABI theo phiên bản Waze** (chuỗi bằng chứng): hook vào `WazeLocationManager` của app Waze; `Waze output v1 alert hook active 5.25.0`, `Waze %@ startup ABI inventory`, `Waze alert ABI mismatch; scalar fields checked independently`, `Waze image UUID mismatch`, `Unsupported Waze version` → nguồn tự kiểm tra cấu trúc dữ liệu của Waze 5.25.0 và thoái lui từng phần khi lệch ABI.
- **Hàm C riêng**: 30 hàm họ `SPH*` (bảng 4.8).

### 3.6. `SidePlay.app/SidePlay` — ỨNG DỤNG (VỎ CARPLAY + UI ĐIỆN THOẠI)

- **Bundle**: `var/jb/Applications/SidePlay.app`, `CFBundleIdentifier = com.sideplay.app`, bản `1.0.4 (5)`, `MinimumOSVersion 15.0`, region `vi`, giao diện Dark, chỉ portrait trên điện thoại, `UIBackgroundModes = [audio]`, URL scheme **`sideplay://`**.
- **Thư viện liên kết**: libobjc, Foundation, CoreFoundation, UIKit, **CarPlay.framework**, CoreLocation, libSystem, CoreGraphics, QuartzCore.
- **Scene manifest** (bằng chứng kiến trúc hai mặt):
  - Điện thoại: `UIWindowScene` + `SPPhoneSceneDelegate` (configuration "Phone").
  - CarPlay: **`CPTemplateApplicationScene`** + `SPCarSceneDelegate` (configuration "CarPlay") — tức app là CarPlay app dạng template thật (kèm entitlement `com.apple.developer.carplay-audio`), dùng CPWindow của template scene làm bề mặt đặt nội dung.
- **Class riêng**: 6 class, **199 method** (bảng 4.6): `SPAppDelegate`, `SPPhoneSceneDelegate`, `SPCarSceneDelegate`, `SPLauncherViewController`, `SPBeamTrack`, `SPRingSpinner`. Tham chiếu `CPTemplateApplicationScene`, `CPListTemplate`, `CPWindow` (qua UIKit/CarPlay).
- **Hàm C riêng**: 9 (`_main`, `_SPAppPost`, `_SPAppPref`, `_SPAppSetPref`, họ trang trí `_SPTech*`).
- **IPC**: dùng Darwin notify (`CFNotificationCenterGetDarwinNotifyCenter`, Post/AddObserver, `RemoveEveryObserver`) với họ tên lệnh `com.sideplay/...` (mục 5.3) để nói chuyện với lõi trong SpringBoard; xử lý cả cờ `--sp-goodbye` khi gỡ gói.
- **Mạng**: `NSURLSession` + 2 endpoint `https://sideplay.pages.dev/api/status` và `https://sideplay.pages.dev/api/report` (báo lỗi/trạng thái — chi tiết ở 5.6).

### 3.7. `SidePlayPrefs.bundle/SidePlayPrefs` — GIAO DIỆN CÀI ĐẶT

- **Bundle**: `var/jb/Library/PreferenceBundles/SidePlayPrefs.bundle`, ID `com.sideplay.prefs`, principal class `SPRootListController`; PreferenceLoader entry trỏ `SPRootListController`, nhãn "SidePlay".
- **Install name**: `/var/jb/Library/PreferenceBundles/SidePlayPrefs.bundle/SidePlayPrefs`.
- **Thư viện liên kết**: libobjc, Foundation, CoreFoundation, UIKit, **PhotosUI**, **Preferences.framework (private)**, libSystem, CoreGraphics, QuartzCore.
- **Class riêng**: 18 class, **159 method** (bảng 4.7): `SPRootListController`, `SPQuickProfileController`, `SPAppListController`, `SPAppSettingsController`, `SPReportViewController`, và họ controller HUD dùng chung tiền tố SPH: `SPHPreferencesController`, `SPHPositionController`, `SPHPhonePositionController`, `SPHSurfaceController`, `SPHSizeSliderCell`, `SPHSegmentedCell`, `SPHMenuCell`, `SPHModuleOrderCell`, `SPHModuleOrderDataSource`, `SPHOutputEndpoint`, `SPHOverspeedController`, `SPHDiagnosticsController`, `SPHPositionPreviewCell`.
- **IPC**: post Darwin notify khi đổi giá trị (`SPHPreferencesValueChanged`, dùng cả `notify_*` state) để lõi/HUD áp dụng ngay.

---

## 4. BẢNG CLASS + METHOD / HÀM C TỪNG BINARY

Đọc trực tiếp từ `__objc_classlist`/`__objc_data` của slice arm64 (parser tự viết): mỗi class liệt kê superclass (ghi `?` khi superclass là class ngoài binary — runtime resolve — tên superclass suy từ classrefs nằm ở ghi chú), ivars kèm kiểu/kích thước, properties kèm attributes, method thể hiện bằng `-`, class method bằng `+`, kèm địa chỉ IMP (offset trong slice). Các class của framework (NSObject, UIView…) chỉ được *tham chiếu* chứ không định nghĩa trong gói nên không liệt kê ở đây — danh sách classrefs đầy đủ có trong đầu ra `llvm-objdump --objc-meta-data` lưu tại thư mục làm việc `work/analysis/objc_*.txt`.

### 4.1. SidePlay.dylib — 11 class, 418 method

```
CLASS SPCalibrationView : ?  (instanceSize=152)
  IVAR _onDone : @? (8B)
  IVAR _onCancel : @? (8B)
  IVAR _dim : @"CAShapeLayer" (8B)
  IVAR _border : @"CAShapeLayer" (8B)
  IVAR _handles : @"NSArray" (8B)
  IVAR _title : @"UILabel" (8B)
  IVAR _card : @"UIView" (8B)
  IVAR _done : @"UIButton" (8B)
  IVAR _reset : @"UIButton" (8B)
  IVAR _cancel : @"UIButton" (8B)
  IVAR _area : {CGRect="origin"{CGPoint="x"d"y"d}"size"{CGSize="width"d"height"d}} (32B)
  IVAR _autoArea : {CGRect="origin"{CGPoint="x"d"y"d}"size"{CGSize="width"d"height"d}} (32B)
  PROP dim  [T@"CAShapeLayer",&,N,V_dim]
  PROP border  [T@"CAShapeLayer",&,N,V_border]
  PROP handles  [T@"NSArray",&,N,V_handles]
  PROP title  [T@"UILabel",&,N,V_title]
  PROP card  [T@"UIView",&,N,V_card]
  PROP done  [T@"UIButton",&,N,V_done]
  PROP reset  [T@"UIButton",&,N,V_reset]
  PROP cancel  [T@"UIButton",&,N,V_cancel]
  PROP area  [T{CGRect={CGPoint=dd}{CGSize=dd}},N,V_area]
  PROP autoArea  [T{CGRect={CGPoint=dd}{CGSize=dd}},N,V_autoArea]
  PROP onDone  [T@?,C,N,V_onDone]
  PROP onCancel  [T@?,C,N,V_onCancel]
  - initWithFrame:  imp=0xe47c
  - setArea:  imp=0xf34c
  - layoutSubviews  imp=0xf394
  - dragged:  imp=0xfe94
  - resetTapped  imp=0x10274
  - doneTapped  imp=0x10328
  - cancelTapped  imp=0x103b8
  - area  imp=0x10434
  - autoArea  imp=0x1044c
  - setAutoArea:  imp=0x10464
  - onDone  imp=0x1047c
  - setOnDone:  imp=0x1048c
  - onCancel  imp=0x10498
  - setOnCancel:  imp=0x104a8
  - dim  imp=0x104b4
  - setDim:  imp=0x104c4
  - border  imp=0x104d8
  - setBorder:  imp=0x104e8
  - handles  imp=0x104fc
  - setHandles:  imp=0x1050c
  - title  imp=0x10520
  - setTitle:  imp=0x10530
  - card  imp=0x10544
  - setCard:  imp=0x10554
  - done  imp=0x10568
  - setDone:  imp=0x10578
  - reset  imp=0x1058c
  - setReset:  imp=0x1059c
  - cancel  imp=0x105b0
  - setCancel:  imp=0x105c0
  - .cxx_destruct  imp=0x105d4

CLASS SPDashCard : ?  (instanceSize=32)
  IVAR _split : q (8B)
  IVAR _diagram : @"UIView" (8B)
  IVAR _diagramPanes : @"NSArray" (8B)
  PROP split  [Tq,N,V_split]
  PROP diagram  [T@"UIView",&,N,V_diagram]
  PROP diagramPanes  [T@"NSArray",&,N,V_diagramPanes]
  - initWithSplit:title:  imp=0x106b4
  - applyStyle  imp=0x10b24
  - setSelected:  imp=0x10e3c
  - setHighlighted:  imp=0x10e8c
  - layoutSubviews  imp=0x10fd4
  - split  imp=0x119e4
  - setSplit:  imp=0x119f4
  - diagram  imp=0x11a04
  - setDiagram:  imp=0x11a14
  - diagramPanes  imp=0x11a28
  - setDiagramPanes:  imp=0x11a38
  - .cxx_destruct  imp=0x11a4c

CLASS SPCardScroll : ?  (instanceSize=8)
  - touchesShouldCancelInContentView:  imp=0x11a8c

CLASS SPDashQuick : ?  (instanceSize=56)
  IVAR _split : q (8B)
  IVAR _apps : @"NSArray" (8B)
  IVAR _diagram : @"UIView" (8B)
  IVAR _diagramPanes : @"NSArray" (8B)
  IVAR _icons : @"NSArray" (8B)
  IVAR _nameLabel : @"UILabel" (8B)
  PROP split  [Tq,N,V_split]
  PROP apps  [T@"NSArray",C,N,V_apps]
  PROP diagram  [T@"UIView",&,N,V_diagram]
  PROP diagramPanes  [T@"NSArray",&,N,V_diagramPanes]
  PROP icons  [T@"NSArray",&,N,V_icons]
  PROP nameLabel  [T@"UILabel",&,N,V_nameLabel]
  - initWithSplit:apps:  imp=0x11a94
  - setHighlighted:  imp=0x12398
  - layoutSubviews  imp=0x125c0
  - split  imp=0x12a64
  - setSplit:  imp=0x12a74
  - apps  imp=0x12a84
  - setApps:  imp=0x12a94
  - diagram  imp=0x12aa0
  - setDiagram:  imp=0x12ab0
  - diagramPanes  imp=0x12ac4
  - setDiagramPanes:  imp=0x12ad4
  - icons  imp=0x12ae8
  - setIcons:  imp=0x12af8
  - nameLabel  imp=0x12b0c
  - setNameLabel:  imp=0x12b1c
  - .cxx_destruct  imp=0x12b30

CLASS SPDash : ?  (instanceSize=272)
  IVAR _isOpen : B (1B)
  IVAR _onPhone : B (1B)
  IVAR _serviceBlocked : B (1B)
  IVAR _serviceWaiting : B (1B)
  IVAR _serviceChecked : B (1B)
  IVAR _calibrationPending : B (1B)
  IVAR _showingChooser : B (1B)
  IVAR _openedAt : d (8B)
  IVAR _window : @"UIWindow" (8B)
  IVAR _carWindow : @"UIWindow" (8B)
  IVAR _carWindowScreen : @"NSString" (8B)
  IVAR _offeredVersion : @"NSString" (8B)
  IVAR _glowView : @"UIView" (8B)
  IVAR _rootView : @"UIView" (8B)
  IVAR _chooserView : @"UIView" (8B)
  IVAR _cards : @"NSArray" (8B)
  IVAR _cardScroll : @"SPCardScroll" (8B)
  IVAR _cardStep : d (8B)
  IVAR _quickButtons : @"NSArray" (8B)
  IVAR _quickCaption : @"UILabel" (8B)
  IVAR _noticeView : @"UIView" (8B)
  IVAR _versionCycle : @"NSTimer" (8B)
  IVAR _calibrationView : @"SPCalibrationView" (8B)
  IVAR _areaView : @"UIView" (8B)
  IVAR _pickerView : @"UIView" (8B)
  IVAR _panes : @"NSArray" (8B)
  IVAR _slotOrder : @"NSArray" (8B)
  IVAR _split : q (8B)
  IVAR _ratio : d (8B)
  IVAR _scaleMode : q (8B)
  IVAR _paneApps : @"NSMutableArray" (8B)
  IVAR _sessionApps : @"NSMutableSet" (8B)
  IVAR _carConnectedState : @"NSNumber" (8B)
  IVAR _carWatchTimer : @"NSTimer" (8B)
  IVAR _carMissedChecks : q (8B)
  IVAR _carWindowFrame : {CGRect="origin"{CGPoint="x"d"y"d}"size"{CGSize="width"d"height"d}} (32B)
  PROP isOpen  [TB,N,V_isOpen]
  PROP onPhone  [TB,N,V_onPhone]
  PROP openedAt  [Td,N,V_openedAt]
  PROP window  [T@"UIWindow",&,N,V_window]
  PROP carWindow  [T@"UIWindow",&,N,V_carWindow]
  PROP carWindowFrame  [T{CGRect={CGPoint=dd}{CGSize=dd}},N,V_carWindowFrame]
  PROP carWindowScreen  [T@"NSString",C,N,V_carWindowScreen]
  PROP offeredVersion  [T@"NSString",C,N,V_offeredVersion]
  PROP glowView  [T@"UIView",&,N,V_glowView]
  PROP rootView  [T@"UIView",&,N,V_rootView]
  PROP chooserView  [T@"UIView",&,N,V_chooserView]
  PROP cards  [T@"NSArray",&,N,V_cards]
  PROP cardScroll  [T@"SPCardScroll",&,N,V_cardScroll]
  PROP cardStep  [Td,N,V_cardStep]
  PROP quickButtons  [T@"NSArray",&,N,V_quickButtons]
  PROP quickCaption  [T@"UILabel",&,N,V_quickCaption]
  PROP noticeView  [T@"UIView",&,N,V_noticeView]
  PROP serviceBlocked  [TB,N,V_serviceBlocked]
  PROP serviceWaiting  [TB,N,V_serviceWaiting]
  PROP serviceChecked  [TB,N,V_serviceChecked]
  PROP versionCycle  [T@"NSTimer",&,N,V_versionCycle]
  PROP calibrationPending  [TB,N,V_calibrationPending]
  PROP calibrationView  [T@"SPCalibrationView",&,N,V_calibrationView]
  PROP areaView  [T@"UIView",&,N,V_areaView]
  PROP pickerView  [T@"UIView",&,N,V_pickerView]
  PROP panes  [T@"NSArray",&,N,V_panes]
  PROP showingChooser  [TB,N,V_showingChooser]
  PROP slotOrder  [T@"NSArray",&,N,V_slotOrder]
  PROP split  [Tq,N,V_split]
  PROP ratio  [Td,N,V_ratio]
  PROP scaleMode  [Tq,N,V_scaleMode]
  PROP paneApps  [T@"NSMutableArray",&,N,V_paneApps]
  PROP sessionApps  [T@"NSMutableSet",&,N,V_sessionApps]
  PROP carConnectedState  [T@"NSNumber",&,N,V_carConnectedState]
  PROP carWatchTimer  [T@"NSTimer",&,N,V_carWatchTimer]
  PROP carMissedChecks  [Tq,N,V_carMissedChecks]
  PROP isVisible  [TB,R,N]
  PROP hash  [TQ,R]
  PROP superclass  [T#,R]
  PROP description  [T@"NSString",R,C]
  PROP debugDescription  [T@"NSString",R,C]
  - init  imp=0x12c18
  - setIsOpen:  imp=0x12dc0
  - isVisible  imp=0x12dd4
  - setOnPhone:  imp=0x12e78
  - panes  imp=0x12e8c
  - readPrefs  imp=0x12f60
  - open  imp=0x12fd0
  - hideOnPhone  imp=0x12fe0
  - hideOnPhoneNow:  imp=0x13060
  - homeGestureBegan:  imp=0x13244
  - homeGestureEnded  imp=0x13610
  - revealIfAppStayed  imp=0x13820
  - revealOnPhone  imp=0x1391c
  - openOnPhone  imp=0x13a50
  - makeMainScreenWindow  imp=0x13a88
  - openOn:  imp=0x13ee0
  - close  imp=0x16440
  - reloadPrefs  imp=0x16de0
  - carPlayConnectionChanged  imp=0x170e4
  - watchCar:  imp=0x17420
  - updateCarConnection  imp=0x17674
  - retireCarWindow  imp=0x17a5c
  - carDockMode  imp=0x17b78
  - carDockArea  imp=0x17bc8
  - carWindowFrameNow  imp=0x17df0
  - carAreaChanged  imp=0x17e38
  - carScene:foreground:  imp=0x18058
  - hideOnCar:  imp=0x18160
  - showOnCarAgain  imp=0x1826c
  - autoOpenOnCar:  imp=0x18388
  - autoCarArea:  imp=0x18598
  - manualCarArea:  imp=0x19500
  - saveManualCarArea:windowBounds:  imp=0x197b0
  - startCalibration  imp=0x19b58
  - showCalibration  imp=0x19ca4
  - endCalibration:  imp=0x1a15c
  - layoutRootView  imp=0x1a2f0
  - tapFeedback  imp=0x1aec8
  - iconButton:size:action:  imp=0x1af2c
  - buildChooser  imp=0x1b0dc
  - buildQuickButtons  imp=0x1be6c
  - quickTapped:  imp=0x1c63c
  - showNote:  imp=0x1c9ec
  - saveLastLayout  imp=0x1d1e0
  - restoreLastLayout  imp=0x1d67c
  - layoutChooser  imp=0x1ddb4
  - cardOffsetForIndex:  imp=0x1e760
  - scrollViewWillEndDragging:withVelocity:targetContentOffset:  imp=0x1e840
  - revealChosenLayout:  imp=0x1e96c
  - showUpdateInVersion:  imp=0x1ec38
  - noticeViewFor:  imp=0x1f100
  - whatsNewDone  imp=0x202ec
  - laterTapped  imp=0x20430
  - openInSileo  imp=0x205d8
  - previewService:  imp=0x20b48
  - applyServiceState  imp=0x20be0
  - showChooser:  imp=0x20f6c
  - animateCardsIn  imp=0x2132c
  - cardTapped:  imp=0x21a60
  - chooseLayoutFromCard:  imp=0x21b10
  - loadPaneApps  imp=0x22190
  - quitAppsOutOfPanes  imp=0x22cbc
  - exitTapped  imp=0x23218
  - goHomeFromPhone  imp=0x233bc
  - layout:  imp=0x23624
  - paneAppDidTerminate:  imp=0x241a4
  - paneRequestsLayouts:  imp=0x24314
  - paneRequestsSwap:  imp=0x24398
  - paneRequestsClose:  imp=0x24708
  - paneRequestsAppPicker:  imp=0x249b0
  - gestureRecognizer:shouldReceiveTouch:  imp=0x24a0c
  - canvasTapped:  imp=0x24a78
  - handleCanvasTap:  imp=0x24b10
  - installedApps  imp=0x24de4
  - showPickerForPane:  imp=0x25618
  - buildPickerForPane:  imp=0x256d8
  - pickerAppTapped:  imp=0x26588
  - pickApp:  imp=0x26620
  - isShowingOverlay  imp=0x268d8
  - dismissPicker  imp=0x26938
  - hostedAppViewControllerForSceneHandle:  imp=0x26990
  - refreshMainScreenPlaceholders  imp=0x26b58
  - restoreMainScreenSceneForHandle:  imp=0x26fac
  - isOpen  imp=0x27164
  - onPhone  imp=0x2716c
  - openedAt  imp=0x27174
  - setOpenedAt:  imp=0x2717c
  - window  imp=0x27184
  - setWindow:  imp=0x2718c
  - carWindow  imp=0x27198
  - setCarWindow:  imp=0x271a0
  - carWindowFrame  imp=0x271ac
  - setCarWindowFrame:  imp=0x271b8
  - carWindowScreen  imp=0x271cc
  - setCarWindowScreen:  imp=0x271d8
  - offeredVersion  imp=0x271e0
  - setOfferedVersion:  imp=0x271ec
  - glowView  imp=0x271f4
  - setGlowView:  imp=0x271fc
  - rootView  imp=0x27208
  - setRootView:  imp=0x27210
  - chooserView  imp=0x2721c
  - setChooserView:  imp=0x27224
  - cards  imp=0x27230
  - setCards:  imp=0x27238
  - cardScroll  imp=0x27244
  - setCardScroll:  imp=0x2724c
  - cardStep  imp=0x27258
  - setCardStep:  imp=0x27260
  - quickButtons  imp=0x27268
  - setQuickButtons:  imp=0x27270
  - quickCaption  imp=0x2727c
  - setQuickCaption:  imp=0x27284
  - noticeView  imp=0x27290
  - setNoticeView:  imp=0x27298
  - serviceBlocked  imp=0x272a4
  - setServiceBlocked:  imp=0x272ac
  - serviceWaiting  imp=0x272b4
  - setServiceWaiting:  imp=0x272bc
  - serviceChecked  imp=0x272c4
  - setServiceChecked:  imp=0x272cc
  - versionCycle  imp=0x272d4
  - setVersionCycle:  imp=0x272dc
  - calibrationPending  imp=0x272e8
  - setCalibrationPending:  imp=0x272f0
  - calibrationView  imp=0x272f8
  - setCalibrationView:  imp=0x27300
  - areaView  imp=0x2730c
  - setAreaView:  imp=0x27314
  - pickerView  imp=0x27320
  - setPickerView:  imp=0x27328
  - setPanes:  imp=0x27334
  - showingChooser  imp=0x27340
  - setShowingChooser:  imp=0x27348
  - slotOrder  imp=0x27350
  - setSlotOrder:  imp=0x27358
  - split  imp=0x27364
  - setSplit:  imp=0x2736c
  - ratio  imp=0x27374
  - setRatio:  imp=0x2737c
  - scaleMode  imp=0x27384
  - setScaleMode:  imp=0x2738c
  - paneApps  imp=0x27394
  - setPaneApps:  imp=0x2739c
  - sessionApps  imp=0x273a8
  - setSessionApps:  imp=0x273b0
  - carConnectedState  imp=0x273bc
  - setCarConnectedState:  imp=0x273c4
  - carWatchTimer  imp=0x273d0
  - setCarWatchTimer:  imp=0x273d8
  - carMissedChecks  imp=0x273e4
  - setCarMissedChecks:  imp=0x273ec
  - .cxx_destruct  imp=0x273f4
  + shared  imp=0x12bac

CLASS SPHudGestures : ?  (instanceSize=8)
  - lift:  imp=0x27874
  - panned:  imp=0x279c4
  - tapped:  imp=0x287cc
  + shared  imp=0x27800

CLASS SPLoadingView : ?  (instanceSize=120)
  IVAR _showing : B (1B)
  IVAR _animatingBlock : B (1B)
  IVAR _grid : @"CAReplicatorLayer" (8B)
  IVAR _gridMask : @"CAGradientLayer" (8B)
  IVAR _block : @"UIView" (8B)
  IVAR _glow : @"CAGradientLayer" (8B)
  IVAR _track : @"CAShapeLayer" (8B)
  IVAR _arc : @"CAShapeLayer" (8B)
  IVAR _outerArc : @"CAShapeLayer" (8B)
  IVAR _iconView : @"UIImageView" (8B)
  IVAR _nameLabel : @"UILabel" (8B)
  IVAR _statusLabel : @"UILabel" (8B)
  IVAR _progressTrack : @"UIView" (8B)
  IVAR _progressBeam : @"CAGradientLayer" (8B)
  IVAR _blockScale : d (8B)
  PROP showing  [TB,N,V_showing]
  PROP grid  [T@"CAReplicatorLayer",&,N,V_grid]
  PROP gridMask  [T@"CAGradientLayer",&,N,V_gridMask]
  PROP block  [T@"UIView",&,N,V_block]
  PROP glow  [T@"CAGradientLayer",&,N,V_glow]
  PROP track  [T@"CAShapeLayer",&,N,V_track]
  PROP arc  [T@"CAShapeLayer",&,N,V_arc]
  PROP outerArc  [T@"CAShapeLayer",&,N,V_outerArc]
  PROP iconView  [T@"UIImageView",&,N,V_iconView]
  PROP nameLabel  [T@"UILabel",&,N,V_nameLabel]
  PROP statusLabel  [T@"UILabel",&,N,V_statusLabel]
  PROP progressTrack  [T@"UIView",&,N,V_progressTrack]
  PROP progressBeam  [T@"CAGradientLayer",&,N,V_progressBeam]
  PROP blockScale  [Td,N,V_blockScale]
  PROP animatingBlock  [TB,N,V_animatingBlock]
  - initWithFrame:  imp=0x29568
  - buildGrid  imp=0x29668
  - buildBlock  imp=0x29ba8
  - ringLayer:color:width:  imp=0x2afa8
  - layoutSubviews  imp=0x2b12c
  - startAnimations  imp=0x2b450
  - stopAnimations  imp=0x2b9d0
  - showApp:icon:status:  imp=0x2bac4
  - setStatus:  imp=0x2bef4
  - dismissAnimated:  imp=0x2c0c8
  - showing  imp=0x2c464
  - setShowing:  imp=0x2c474
  - grid  imp=0x2c484
  - setGrid:  imp=0x2c494
  - gridMask  imp=0x2c4a8
  - setGridMask:  imp=0x2c4b8
  - block  imp=0x2c4cc
  - setBlock:  imp=0x2c4dc
  - glow  imp=0x2c4f0
  - setGlow:  imp=0x2c500
  - track  imp=0x2c514
  - setTrack:  imp=0x2c524
  - arc  imp=0x2c538
  - setArc:  imp=0x2c548
  - outerArc  imp=0x2c55c
  - setOuterArc:  imp=0x2c56c
  - iconView  imp=0x2c580
  - setIconView:  imp=0x2c590
  - nameLabel  imp=0x2c5a4
  - setNameLabel:  imp=0x2c5b4
  - statusLabel  imp=0x2c5c8
  - setStatusLabel:  imp=0x2c5d8
  - progressTrack  imp=0x2c5ec
  - setProgressTrack:  imp=0x2c5fc
  - progressBeam  imp=0x2c610
  - setProgressBeam:  imp=0x2c620
  - blockScale  imp=0x2c634
  - setBlockScale:  imp=0x2c644
  - animatingBlock  imp=0x2c654
  - setAnimatingBlock:  imp=0x2c664
  - .cxx_destruct  imp=0x2c674

CLASS SPPane : ?  (instanceSize=320)
  IVAR _showsSwap : B (1B)
  IVAR _swapVertical : B (1B)
  IVAR _sceneFrameChanged : B (1B)
  IVAR _coldStart : B (1B)
  IVAR _settleReloadDone : B (1B)
  IVAR _softReloading : B (1B)
  IVAR _barHidden : B (1B)
  IVAR _view : @"UIView" (8B)
  IVAR _bundleID : @"NSString" (8B)
  IVAR _appViewController : @ (8B)
  IVAR _index : q (8B)
  IVAR _swapSymbol : @"NSString" (8B)
  IVAR _hostedIdiom : @"NSString" (8B)
  IVAR _delegate : @"<SPPaneDelegate>" (8B)
  IVAR _chipView : @"UIView" (8B)
  IVAR _titleLabel : @"UILabel" (8B)
  IVAR _chipIcon : @"UIImageView" (8B)
  IVAR _layoutButton : @"UIButton" (8B)
  IVAR _swapButton : @"UIButton" (8B)
  IVAR _closeButton : @"UIButton" (8B)
  IVAR _contentView : @"UIView" (8B)
  IVAR _canvasView : @"UIView" (8B)
  IVAR _placeholderLabel : @"UILabel" (8B)
  IVAR _addButton : @"UIButton" (8B)
  IVAR _application : @ (8B)
  IVAR _sceneMonitor : @ (8B)
  IVAR _orientation : q (8B)
  IVAR _scaleMode : q (8B)
  IVAR _settleRun : Q (8B)
  IVAR _watchToken : Q (8B)
  IVAR _loadingView : @"SPLoadingView" (8B)
  IVAR _loadingToken : Q (8B)
  IVAR _loadedAt : d (8B)
  IVAR _sidewaysSince : d (8B)
  IVAR _sidewaysStage : q (8B)
  IVAR _sidewaysStageAt : d (8B)
  IVAR _watchTicks : q (8B)
  IVAR _geometryChecks : q (8B)
  IVAR _orientationAskedAt : d (8B)
  IVAR _barToken : Q (8B)
  IVAR _grabber : @"UIButton" (8B)
  IVAR _touchNotification : @"NSString" (8B)
  IVAR _audioBundle : @"NSString" (8B)
  IVAR _sceneSize : {CGSize="width"d"height"d} (16B)
  PROP view  [T@"UIView",&,N,V_view]
  PROP chipView  [T@"UIView",&,N,V_chipView]
  PROP titleLabel  [T@"UILabel",&,N,V_titleLabel]
  PROP chipIcon  [T@"UIImageView",&,N,V_chipIcon]
  PROP layoutButton  [T@"UIButton",&,N,V_layoutButton]
  PROP swapButton  [T@"UIButton",&,N,V_swapButton]
  PROP closeButton  [T@"UIButton",&,N,V_closeButton]
  PROP contentView  [T@"UIView",&,N,V_contentView]
  PROP canvasView  [T@"UIView",&,N,V_canvasView]
  PROP placeholderLabel  [T@"UILabel",&,N,V_placeholderLabel]
  PROP addButton  [T@"UIButton",&,N,V_addButton]
  PROP bundleID  [T@"NSString",C,N,V_bundleID]
  PROP appViewController  [T@,&,N,V_appViewController]
  PROP application  [T@,&,N,V_application]
  PROP sceneMonitor  [T@,&,N,V_sceneMonitor]
  PROP orientation  [Tq,N,V_orientation]
  PROP scaleMode  [Tq,N,V_scaleMode]
  PROP sceneFrameChanged  [TB,N,V_sceneFrameChanged]
  PROP sceneSize  [T{CGSize=dd},N,V_sceneSize]
  PROP coldStart  [TB,N,V_coldStart]
  PROP settleReloadDone  [TB,N,V_settleReloadDone]
  PROP settleRun  [TQ,N,V_settleRun]
  PROP softReloading  [TB,N,V_softReloading]
  PROP watchToken  [TQ,N,V_watchToken]
  PROP loadingView  [T@"SPLoadingView",&,N,V_loadingView]
  PROP loadingToken  [TQ,N,V_loadingToken]
  PROP loadedAt  [Td,N,V_loadedAt]
  PROP sidewaysSince  [Td,N,V_sidewaysSince]
  PROP sidewaysStage  [Tq,N,V_sidewaysStage]
  PROP sidewaysStageAt  [Td,N,V_sidewaysStageAt]
  PROP watchTicks  [Tq,N,V_watchTicks]
  PROP geometryChecks  [Tq,N,V_geometryChecks]
  PROP orientationAskedAt  [Td,N,V_orientationAskedAt]
  PROP hostedIdiom  [T@"NSString",C,N,V_hostedIdiom]
  PROP barHidden  [TB,N,V_barHidden]
  PROP barToken  [TQ,N,V_barToken]
  PROP grabber  [T@"UIButton",&,N,V_grabber]
  PROP touchNotification  [T@"NSString",C,N,V_touchNotification]
  PROP audioBundle  [T@"NSString",C,N,V_audioBundle]
  PROP index  [Tq,N,V_index]
  PROP showsSwap  [TB,N,V_showsSwap]
  PROP swapVertical  [TB,N,V_swapVertical]
  PROP swapSymbol  [T@"NSString",C,N,V_swapSymbol]
  PROP delegate  [T@"<SPPaneDelegate>",W,N,V_delegate]
  - initWithIndex:  imp=0x2d834
  - chipButton:action:  imp=0x2d898
  - setChipSymbol:on:  imp=0x2d990
  - buildViews  imp=0x2da8c
  - grabberTapped  imp=0x2eec8
  - noteActivity  imp=0x2eed4
  - scheduleBarHide  imp=0x2ef20
  - slideBarHidden:  imp=0x2f174
  - pickTapped  imp=0x2f358
  - isEmpty  imp=0x2f480
  - layoutTapped  imp=0x2f4bc
  - swapTapped  imp=0x2f578
  - closeTapped  imp=0x2f634
  - layoutInFrame:scaleMode:  imp=0x2f6e0
  - orientationForBundleID:idiom:  imp=0x307a0
  - requestAppOrientation:  imp=0x308bc
  - applySceneOrientation:  imp=0x31050
  - applySceneFrame:  imp=0x313f8
  - restoreSceneFrame  imp=0x31468
  - setSceneFrame:orientation:  imp=0x31500
  - sceneHandle  imp=0x31830
  - desiredIdiomForBundleID:  imp=0x318cc
  - loadApp:  imp=0x31a78
  - softReload  imp=0x333e0
  - scheduleGeometryChecksFor:  imp=0x334f4
  - listenForTouchesIn:  imp=0x33844
  - watchOrientationFor:token:  imp=0x33ac8
  - fixIfSideways  imp=0x33d40
  - turnSceneBack  imp=0x3414c
  - enforceSceneGeometry  imp=0x3467c
  - showLoadingFor:app:status:  imp=0x34960
  - appReportedOrientation  imp=0x34e38
  - sceneViewOrientation  imp=0x34f70
  - revealWhenSettled  imp=0x35104
  - checkSettled:run:tick:  imp=0x351f8
  - appDidLaunchWithTransaction:  imp=0x356ac
  - sceneMonitor:sceneWasDestroyed:  imp=0x35a74
  - unloadApp  imp=0x35bb8
  - view  imp=0x36644
  - setView:  imp=0x3664c
  - bundleID  imp=0x36658
  - setBundleID:  imp=0x36664
  - appViewController  imp=0x3666c
  - setAppViewController:  imp=0x36674
  - index  imp=0x36680
  - setIndex:  imp=0x36688
  - showsSwap  imp=0x36690
  - setShowsSwap:  imp=0x36698
  - swapVertical  imp=0x366a0
  - setSwapVertical:  imp=0x366a8
  - swapSymbol  imp=0x366b0
  - setSwapSymbol:  imp=0x366bc
  - hostedIdiom  imp=0x366c4
  - setHostedIdiom:  imp=0x366d0
  - delegate  imp=0x366d8
  - setDelegate:  imp=0x366f0
  - chipView  imp=0x366fc
  - setChipView:  imp=0x36704
  - titleLabel  imp=0x36710
  - setTitleLabel:  imp=0x36718
  - chipIcon  imp=0x36724
  - setChipIcon:  imp=0x3672c
  - layoutButton  imp=0x36738
  - setLayoutButton:  imp=0x36740
  - swapButton  imp=0x3674c
  - setSwapButton:  imp=0x36754
  - closeButton  imp=0x36760
  - setCloseButton:  imp=0x36768
  - contentView  imp=0x36774
  - setContentView:  imp=0x3677c
  - canvasView  imp=0x36788
  - setCanvasView:  imp=0x36790
  - placeholderLabel  imp=0x3679c
  - setPlaceholderLabel:  imp=0x367a4
  - addButton  imp=0x367b0
  - setAddButton:  imp=0x367b8
  - application  imp=0x367c4
  - setApplication:  imp=0x367cc
  - sceneMonitor  imp=0x367d8
  - setSceneMonitor:  imp=0x367e0
  - orientation  imp=0x367ec
  - setOrientation:  imp=0x367f4
  - scaleMode  imp=0x367fc
  - setScaleMode:  imp=0x36804
  - sceneFrameChanged  imp=0x3680c
  - setSceneFrameChanged:  imp=0x36814
  - sceneSize  imp=0x3681c
  - setSceneSize:  imp=0x36824
  - coldStart  imp=0x36830
  - setColdStart:  imp=0x36838
  - settleReloadDone  imp=0x36840
  - setSettleReloadDone:  imp=0x36848
  - settleRun  imp=0x36850
  - setSettleRun:  imp=0x36858
  - softReloading  imp=0x36860
  - setSoftReloading:  imp=0x36868
  - watchToken  imp=0x36870
  - setWatchToken:  imp=0x36878
  - loadingView  imp=0x36880
  - setLoadingView:  imp=0x36888
  - loadingToken  imp=0x36894
  - setLoadingToken:  imp=0x3689c
  - loadedAt  imp=0x368a4
  - setLoadedAt:  imp=0x368ac
  - sidewaysSince  imp=0x368b4
  - setSidewaysSince:  imp=0x368bc
  - sidewaysStage  imp=0x368c4
  - setSidewaysStage:  imp=0x368cc
  - sidewaysStageAt  imp=0x368d4
  - setSidewaysStageAt:  imp=0x368dc
  - watchTicks  imp=0x368e4
  - setWatchTicks:  imp=0x368ec
  - geometryChecks  imp=0x368f4
  - setGeometryChecks:  imp=0x368fc
  - orientationAskedAt  imp=0x36904
  - setOrientationAskedAt:  imp=0x3690c
  - barHidden  imp=0x36914
  - setBarHidden:  imp=0x3691c
  - barToken  imp=0x36924
  - setBarToken:  imp=0x3692c
  - grabber  imp=0x36934
  - setGrabber:  imp=0x3693c
  - touchNotification  imp=0x36948
  - setTouchNotification:  imp=0x36954
  - audioBundle  imp=0x3695c
  - setAudioBundle:  imp=0x36968
  - .cxx_destruct  imp=0x36970

CLASS SPHOutputEndpointSidePlay : ?  (instanceSize=105)
  IVAR tokens : [8i] (32B)
  IVAR previous : {?="words"[6Q]} (48B)
  IVAR previousSelection : Q (8B)
  IVAR previousCommit : Q (8B)
  IVAR published : B (1B)
  - initWithSourceID:  imp=0x3d038
  - dealloc  imp=0x3d250

CLASS SPHSpeedCardSidePlay : ?  (instanceSize=64)
  IVAR _night : B (1B)
  IVAR _compact : B (1B)
  IVAR _speed : @"NSNumber" (8B)
  IVAR _limit : @"NSNumber" (8B)
  IVAR _alerts : @"NSArray" (8B)
  IVAR _sourceID : Q (8B)
  IVAR _moduleOrder : @"NSArray" (8B)
  IVAR _clarity : d (8B)
  PROP speed  [T@"NSNumber",C,N,V_speed]
  PROP limit  [T@"NSNumber",C,N,V_limit]
  PROP alerts  [T@"NSArray",C,N,V_alerts]
  PROP night  [TB,N,V_night]
  PROP compact  [TB,N,V_compact]
  PROP sourceID  [TQ,N,V_sourceID]
  PROP moduleOrder  [T@"NSArray",C,N,V_moduleOrder]
  PROP clarity  [Td,N,V_clarity]
  - pointInside:withEvent:  imp=0x411d8
  - drawRect:  imp=0x41248
  - speed  imp=0x43180
  - setSpeed:  imp=0x43190
  - limit  imp=0x4319c
  - setLimit:  imp=0x431ac
  - alerts  imp=0x431b8
  - setAlerts:  imp=0x431c8
  - night  imp=0x431d4
  - setNight:  imp=0x431e4
  - compact  imp=0x431f4
  - setCompact:  imp=0x43204
  - sourceID  imp=0x43214
  - setSourceID:  imp=0x43224
  - moduleOrder  imp=0x43234
  - setModuleOrder:  imp=0x43244
  - clarity  imp=0x43250
  - setClarity:  imp=0x43260
  - .cxx_destruct  imp=0x43270

CLASS SPHOverspeedFrameSidePlay : ?  (instanceSize=49)
  IVAR _rim : @"CALayer" (8B)
  IVAR _renderedSize : {CGSize="width"d"height"d} (16B)
  IVAR _requested : B (1B)
  IVAR _level : Q (8B)
  IVAR _wholeScreen : B (1B)
  PROP wholeScreen  [TB,N,V_wholeScreen]
  - initWithFrame:  imp=0x448f0
  - hitTest:withEvent:  imp=0x44ae4
  - pointInside:withEvent:  imp=0x44aec
  - canBecomeFocused  imp=0x44af4
  - layoutSubviews  imp=0x44afc
  - setWholeScreen:  imp=0x44f64
  - setWarningLevel:  imp=0x44fdc
  - setWarningActive:  imp=0x45050
  - didMoveToWindow  imp=0x45350
  - wholeScreen  imp=0x453ac
  - .cxx_destruct  imp=0x453bc
```

### 4.2. SidePlayHUDRelay.dylib — 1 class ObjC (phần còn lại là hàm C, xem 4.8)

```
CLASS SPHOutputEndpoint : ?  (instanceSize=105)
  IVAR tokens : [8i] (32B)
  IVAR previous : {?="words"[6Q]} (48B)
  IVAR previousSelection : Q (8B)
  IVAR previousCommit : Q (8B)
  IVAR published : B (1B)
  - initWithSourceID:  imp=0x7dcc
  - dealloc  imp=0x7fe4
```

### 4.3. SidePlayHUDGofa.dylib — class ObjC (phần Swift xem 3.3)

```
CLASS SPHOutputEndpoint : ?  (instanceSize=105)
  IVAR tokens : [8i] (32B)
  IVAR previous : {?="words"[6Q]} (48B)
  IVAR previousSelection : Q (8B)
  IVAR previousCommit : Q (8B)
  IVAR published : B (1B)
  - initWithSourceID:  imp=0x996c
  - dealloc  imp=0x9b84

CLASS SPHLocationSession : ?  (instanceSize=48)
  IVAR _requestedBackground : B (1B)
  IVAR _requestedPause : B (1B)
  IVAR _requestedIndicator : B (1B)
  IVAR _running : B (1B)
  IVAR _forcedRunning : B (1B)
  IVAR _sourceGPS : B (1B)
  IVAR _distanceApplied : B (1B)
  IVAR _applied : B (1B)
  IVAR _manager : @"CLLocationManager" (8B)
  IVAR _requestedDistance : d (8B)
  IVAR _callbacks : Q (8B)
  IVAR _lastLog : d (8B)
  PROP manager  [T@"CLLocationManager",W,N,V_manager]
  PROP requestedBackground  [TB,V_requestedBackground]
  PROP requestedPause  [TB,V_requestedPause]
  PROP requestedIndicator  [TB,V_requestedIndicator]
  PROP running  [TB,N,V_running]
  PROP forcedRunning  [TB,N,V_forcedRunning]
  PROP sourceGPS  [TB,N,V_sourceGPS]
  PROP requestedDistance  [Td,V_requestedDistance]
  PROP distanceApplied  [TB,V_distanceApplied]
  PROP applied  [TB,V_applied]
  PROP callbacks  [TQ,N,V_callbacks]
  PROP lastLog  [Td,N,V_lastLog]
  - manager  imp=0xb014
  - setManager:  imp=0xb02c
  - requestedBackground  imp=0xb038
  - setRequestedBackground:  imp=0xb044
  - requestedPause  imp=0xb04c
  - setRequestedPause:  imp=0xb058
  - requestedIndicator  imp=0xb060
  - setRequestedIndicator:  imp=0xb06c
  - running  imp=0xb074
  - setRunning:  imp=0xb07c
  - forcedRunning  imp=0xb084
  - setForcedRunning:  imp=0xb08c
  - sourceGPS  imp=0xb094
  - setSourceGPS:  imp=0xb09c
  - requestedDistance  imp=0xb0a4
  - setRequestedDistance:  imp=0xb0b0
  - distanceApplied  imp=0xb0bc
  - setDistanceApplied:  imp=0xb0c8
  - applied  imp=0xb0d0
  - setApplied:  imp=0xb0dc
  - callbacks  imp=0xb0e4
  - setCallbacks:  imp=0xb0ec
  - lastLog  imp=0xb0f4
  - setLastLog:  imp=0xb0fc
  - .cxx_destruct  imp=0xb104
```

### 4.4. SidePlayHUDVietMap.dylib

```
CLASS SPHOutputEndpoint : ?  (instanceSize=105)
  IVAR tokens : [8i] (32B)
  IVAR previous : {?="words"[6Q]} (48B)
  IVAR previousSelection : Q (8B)
  IVAR previousCommit : Q (8B)
  IVAR published : B (1B)
  - initWithSourceID:  imp=0xa79c
  - dealloc  imp=0xa9b4

CLASS SPHLocationSession : ?  (instanceSize=40)
  IVAR _requestedBackground : B (1B)
  IVAR _requestedPause : B (1B)
  IVAR _requestedIndicator : B (1B)
  IVAR _running : B (1B)
  IVAR _forcedRunning : B (1B)
  IVAR _sourceGPS : B (1B)
  IVAR _applied : B (1B)
  IVAR _manager : @"CLLocationManager" (8B)
  IVAR _callbacks : Q (8B)
  IVAR _lastLog : d (8B)
  PROP manager  [T@"CLLocationManager",W,N,V_manager]
  PROP requestedBackground  [TB,V_requestedBackground]
  PROP requestedPause  [TB,V_requestedPause]
  PROP requestedIndicator  [TB,V_requestedIndicator]
  PROP running  [TB,N,V_running]
  PROP forcedRunning  [TB,N,V_forcedRunning]
  PROP sourceGPS  [TB,N,V_sourceGPS]
  PROP applied  [TB,V_applied]
  PROP callbacks  [TQ,N,V_callbacks]
  PROP lastLog  [Td,N,V_lastLog]
  - manager  imp=0xf030
  - setManager:  imp=0xf048
  - requestedBackground  imp=0xf054
  - setRequestedBackground:  imp=0xf060
  - requestedPause  imp=0xf068
  - setRequestedPause:  imp=0xf074
  - requestedIndicator  imp=0xf07c
  - setRequestedIndicator:  imp=0xf088
  - running  imp=0xf090
  - setRunning:  imp=0xf098
  - forcedRunning  imp=0xf0a0
  - setForcedRunning:  imp=0xf0a8
  - sourceGPS  imp=0xf0b0
  - setSourceGPS:  imp=0xf0b8
  - applied  imp=0xf0c0
  - setApplied:  imp=0xf0cc
  - callbacks  imp=0xf0d4
  - setCallbacks:  imp=0xf0dc
  - lastLog  imp=0xf0e4
  - setLastLog:  imp=0xf0ec
  - .cxx_destruct  imp=0xf0f4

CLASS SPHNavSource : ?  (instanceSize=33)
  IVAR _values : @"NSMutableDictionary" (8B)
  IVAR _times : @"NSMutableDictionary" (8B)
  IVAR _lastUpdate : d (8B)
  IVAR _hasUpdate : B (1B)
  - init  imp=0x140b0
  - applyArguments:receivedAt:  imp=0x14154
  - applyMainSpeedLimit:receivedAt:  imp=0x143cc
  - payloadAtUptime:timestamp:  imp=0x14554
  - freshSamplesAtUptime:  imp=0x14774
  - .cxx_destruct  imp=0x14ab4
```

### 4.5. SidePlayHUDWaze.dylib

```
CLASS SPHOutputEndpoint : ?  (instanceSize=105)
  IVAR tokens : [8i] (32B)
  IVAR previous : {?="words"[6Q]} (48B)
  IVAR previousSelection : Q (8B)
  IVAR previousCommit : Q (8B)
  IVAR published : B (1B)
  - initWithSourceID:  imp=0xa510
  - dealloc  imp=0xa728

CLASS SPHLocationSession : ?  (instanceSize=40)
  IVAR _requestedBackground : B (1B)
  IVAR _requestedPause : B (1B)
  IVAR _requestedIndicator : B (1B)
  IVAR _running : B (1B)
  IVAR _forcedRunning : B (1B)
  IVAR _sourceGPS : B (1B)
  IVAR _applied : B (1B)
  IVAR _manager : @"CLLocationManager" (8B)
  IVAR _callbacks : Q (8B)
  IVAR _lastLog : d (8B)
  PROP manager  [T@"CLLocationManager",W,N,V_manager]
  PROP requestedBackground  [TB,V_requestedBackground]
  PROP requestedPause  [TB,V_requestedPause]
  PROP requestedIndicator  [TB,V_requestedIndicator]
  PROP running  [TB,N,V_running]
  PROP forcedRunning  [TB,N,V_forcedRunning]
  PROP sourceGPS  [TB,N,V_sourceGPS]
  PROP applied  [TB,V_applied]
  PROP callbacks  [TQ,N,V_callbacks]
  PROP lastLog  [Td,N,V_lastLog]
  - manager  imp=0xbbb8
  - setManager:  imp=0xbbd0
  - requestedBackground  imp=0xbbdc
  - setRequestedBackground:  imp=0xbbe8
  - requestedPause  imp=0xbbf0
  - setRequestedPause:  imp=0xbbfc
  - requestedIndicator  imp=0xbc04
  - setRequestedIndicator:  imp=0xbc10
  - running  imp=0xbc18
  - setRunning:  imp=0xbc20
  - forcedRunning  imp=0xbc28
  - setForcedRunning:  imp=0xbc30
  - sourceGPS  imp=0xbc38
  - setSourceGPS:  imp=0xbc40
  - applied  imp=0xbc48
  - setApplied:  imp=0xbc54
  - callbacks  imp=0xbc5c
  - setCallbacks:  imp=0xbc64
  - lastLog  imp=0xbc6c
  - setLastLog:  imp=0xbc74
  - .cxx_destruct  imp=0xbc7c

CLASS SPHWazeOutputStore : ?  (instanceSize=32)
  IVAR _alerts : @"NSMutableDictionary" (8B)
  IVAR _samples : @"NSDictionary" (8B)
  IVAR _lastGPS : d (8B)
  - init  imp=0x125d4
  - updateIdentifier:icon:type:subtype:trait:distance:valid:passed:atUptime:  imp=0x1265c
  - updateSpeed:timestamp:now:uptime:optionalLimit:  imp=0x12c94
  - updateLimit:uptime:  imp=0x13034
  - outputAtUptime:  imp=0x1310c
  - .cxx_destruct  imp=0x13330
```

### 4.6. SidePlay.app — 6 class, 199 method

```
CLASS SPAppDelegate : ?  (instanceSize=8)
  PROP window  [T@"UIWindow",&,N]
  PROP hash  [TQ,R]
  PROP superclass  [T#,R]
  PROP description  [T@"NSString",R,C]
  PROP debugDescription  [T@"NSString",R,C]
  - application:didFinishLaunchingWithOptions:  imp=0x1000047e4
  - application:configurationForConnectingSceneSession:options:  imp=0x1000047ec

CLASS SPPhoneSceneDelegate : ?  (instanceSize=16)
  IVAR _window : @"UIWindow" (8B)
  PROP window  [T@"UIWindow",&,N,V_window]
  PROP hash  [TQ,R]
  PROP superclass  [T#,R]
  PROP description  [T@"NSString",R,C]
  PROP debugDescription  [T@"NSString",R,C]
  - scene:willConnectToSession:options:  imp=0x1000048fc
  - scene:openURLContexts:  imp=0x100004af4
  - sceneWillEnterForeground:  imp=0x100004bb0
  - sceneDidBecomeActive:  imp=0x100004c10
  - sceneWillResignActive:  imp=0x100004c70
  - sceneDidEnterBackground:  imp=0x100004c7c
  - window  imp=0x100004ce8
  - setWindow:  imp=0x100004cf8
  - .cxx_destruct  imp=0x100004d0c

CLASS SPCarSceneDelegate : ?  (instanceSize=16)
  IVAR _interfaceController : @"CPInterfaceController" (8B)
  PROP interfaceController  [T@"CPInterfaceController",&,N,V_interfaceController]
  PROP hash  [TQ,R]
  PROP superclass  [T#,R]
  PROP description  [T@"NSString",R,C]
  PROP debugDescription  [T@"NSString",R,C]
  - templateApplicationScene:didConnectInterfaceController:  imp=0x100004d20
  - sceneDidBecomeActive:  imp=0x100005068
  - templateApplicationScene:didDisconnectInterfaceController:  imp=0x100005088
  - interfaceController  imp=0x100005098
  - setInterfaceController:  imp=0x1000050a8
  - .cxx_destruct  imp=0x1000050bc

CLASS SPLauncherViewController : ?  (instanceSize=344)
  IVAR _showingFallback : B (1B)
  IVAR _introRunning : B (1B)
  IVAR _calibrateMode : B (1B)
  IVAR _previewCar : B (1B)
  IVAR _showingConnected : B (1B)
  IVAR _showingDisconnected : B (1B)
  IVAR _idleView : @"UIView" (8B)
  IVAR _idleFrame : @"UIView" (8B)
  IVAR _statusLabel : @"UILabel" (8B)
  IVAR _openButton : @"UIButton" (8B)
  IVAR _respringButton : @"UIButton" (8B)
  IVAR _introView : @"UIView" (8B)
  IVAR _introGrid : @"CAReplicatorLayer" (8B)
  IVAR _introBlock : @"UIView" (8B)
  IVAR _introSpinner : @"SPRingSpinner" (8B)
  IVAR _introStatus : @"UILabel" (8B)
  IVAR _calibrateView : @"UIView" (8B)
  IVAR _calibrateStatus : @"UILabel" (8B)
  IVAR _calibrateGrid : @"CAReplicatorLayer" (8B)
  IVAR _calibrateHolder : @"UIView" (8B)
  IVAR _calibrateFrame : @"UIView" (8B)
  IVAR _calibrateKnobs : @"NSArray" (8B)
  IVAR _calibrateArrows : @"NSArray" (8B)
  IVAR _calibrateSteps : @"NSArray" (8B)
  IVAR _previewScreen : @"NSString" (8B)
  IVAR _previewBar : @"UIStackView" (8B)
  IVAR _connectedView : @"UIView" (8B)
  IVAR _ripples : @"UIView" (8B)
  IVAR _connectedLogo : @"SPRingSpinner" (8B)
  IVAR _connectedGrid : @"CAReplicatorLayer" (8B)
  IVAR _statusRow : @"UIView" (8B)
  IVAR _statusDot : @"UIView" (8B)
  IVAR _flowRow : @"UIView" (8B)
  IVAR _flowBeam : @"SPBeamTrack" (8B)
  IVAR _flowCut : @"UIImageView" (8B)
  IVAR _hintLabel : @"UILabel" (8B)
  IVAR _connectedTitle : @"UILabel" (8B)
  IVAR _countdownBar : @"UIView" (8B)
  IVAR _countdownFill : @"CALayer" (8B)
  IVAR _connectedLabel : @"UILabel" (8B)
  IVAR _disconnectTimer : @"NSTimer" (8B)
  IVAR _disconnectRemaining : q (8B)
  IVAR _disconnectTap : @"UITapGestureRecognizer" (8B)
  IVAR _calibrateRest : {CGRect="origin"{CGPoint="x"d"y"d}"size"{CGSize="width"d"height"d}} (32B)
  PROP idleView  [T@"UIView",&,N,V_idleView]
  PROP idleFrame  [T@"UIView",&,N,V_idleFrame]
  PROP statusLabel  [T@"UILabel",&,N,V_statusLabel]
  PROP openButton  [T@"UIButton",&,N,V_openButton]
  PROP showingFallback  [TB,N,V_showingFallback]
  PROP respringButton  [T@"UIButton",&,N,V_respringButton]
  PROP introView  [T@"UIView",&,N,V_introView]
  PROP introGrid  [T@"CAReplicatorLayer",&,N,V_introGrid]
  PROP introBlock  [T@"UIView",&,N,V_introBlock]
  PROP introSpinner  [T@"SPRingSpinner",&,N,V_introSpinner]
  PROP introStatus  [T@"UILabel",&,N,V_introStatus]
  PROP introRunning  [TB,N,V_introRunning]
  PROP calibrateMode  [TB,N,V_calibrateMode]
  PROP calibrateView  [T@"UIView",&,N,V_calibrateView]
  PROP calibrateStatus  [T@"UILabel",&,N,V_calibrateStatus]
  PROP calibrateGrid  [T@"CAReplicatorLayer",&,N,V_calibrateGrid]
  PROP calibrateHolder  [T@"UIView",&,N,V_calibrateHolder]
  PROP calibrateFrame  [T@"UIView",&,N,V_calibrateFrame]
  PROP calibrateKnobs  [T@"NSArray",&,N,V_calibrateKnobs]
  PROP calibrateArrows  [T@"NSArray",&,N,V_calibrateArrows]
  PROP calibrateRest  [T{CGRect={CGPoint=dd}{CGSize=dd}},N,V_calibrateRest]
  PROP calibrateSteps  [T@"NSArray",&,N,V_calibrateSteps]
  PROP previewScreen  [T@"NSString",C,N,V_previewScreen]
  PROP previewCar  [TB,N,V_previewCar]
  PROP previewBar  [T@"UIStackView",&,N,V_previewBar]
  PROP connectedView  [T@"UIView",&,N,V_connectedView]
  PROP ripples  [T@"UIView",&,N,V_ripples]
  PROP connectedLogo  [T@"SPRingSpinner",&,N,V_connectedLogo]
  PROP connectedGrid  [T@"CAReplicatorLayer",&,N,V_connectedGrid]
  PROP statusRow  [T@"UIView",&,N,V_statusRow]
  PROP statusDot  [T@"UIView",&,N,V_statusDot]
  PROP flowRow  [T@"UIView",&,N,V_flowRow]
  PROP flowBeam  [T@"SPBeamTrack",&,N,V_flowBeam]
  PROP flowCut  [T@"UIImageView",&,N,V_flowCut]
  PROP hintLabel  [T@"UILabel",&,N,V_hintLabel]
  PROP connectedTitle  [T@"UILabel",&,N,V_connectedTitle]
  PROP countdownBar  [T@"UIView",&,N,V_countdownBar]
  PROP countdownFill  [T@"CALayer",&,N,V_countdownFill]
  PROP showingConnected  [TB,N,V_showingConnected]
  PROP showingDisconnected  [TB,N,V_showingDisconnected]
  PROP connectedLabel  [T@"UILabel",&,N,V_connectedLabel]
  PROP disconnectTimer  [T@"NSTimer",&,N,V_disconnectTimer]
  PROP disconnectRemaining  [Tq,N,V_disconnectRemaining]
  PROP disconnectTap  [T@"UITapGestureRecognizer",&,N,V_disconnectTap]
  - dealloc  imp=0x1000050d0
  - viewDidLoad  imp=0x10000511c
  - viewWillAppear:  imp=0x100005520
  - makeTitleLabel  imp=0x100005570
  - buildIdleView  imp=0x10000563c
  - buildIntro  imp=0x10000650c
  - layoutIntro  imp=0x100006cfc
  - playIntroThenOpen  imp=0x10000713c
  - showFrameAnimated:  imp=0x1000079b0
  - viewDidLayoutSubviews  imp=0x100007c2c
  - setShowingFallback:  imp=0x100008114
  - needsRespring  imp=0x100008340
  - notOpenedReason  imp=0x100008544
  - respringTapped  imp=0x10000868c
  - checkOpenedSoon  imp=0x1000087a8
  - retryTapped  imp=0x100008960
  - buildConnectedView  imp=0x100008998
  - startConnectedAnimations  imp=0x10000b770
  - stopConnectedAnimations  imp=0x10000bc18
  - playConnectedEntrance  imp=0x10000bd20
  - carPlayConnected  imp=0x10000c660
  - refreshStatus  imp=0x10000c72c
  - openURL:  imp=0x10000cc14
  - startPreview:  imp=0x10000cd18
  - previewService:  imp=0x10000d160
  - previewConnected  imp=0x10000d234
  - previewUnplug  imp=0x10000d55c
  - previewPlugIn  imp=0x10000d5c4
  - showPreviewActions  imp=0x10000d630
  - hidePreviewBar  imp=0x10000e628
  - endPreview  imp=0x10000e74c
  - exitPreview  imp=0x10000e798
  - abandonPreview  imp=0x10000e830
  - startCalibrationGuide  imp=0x10000ea24
  - startCalibrateDemo  imp=0x10000f3c4
  - stopCalibrateDemo  imp=0x10000fa48
  - setCalibrateLook:dim:animated:  imp=0x10000ff20
  - buildCalibrateView  imp=0x100010684
  - updateCalibrateText  imp=0x100012254
  - calibrationFinished:  imp=0x10001249c
  - leaveCalibrationGuide  imp=0x1000127a8
  - appWentBackground  imp=0x1000129d0
  - setStatusText:color:dot:  imp=0x1000129dc
  - setHintText:  imp=0x100012de4
  - beginDisconnected  imp=0x100012f68
  - startCountdownBar:  imp=0x1000138d8
  - updateDisconnectHint  imp=0x100013cbc
  - disconnectTapped  imp=0x100013d34
  - stopDisconnectCountdown  imp=0x100013d78
  - endDisconnected  imp=0x100013e18
  - resetDisconnectedLook  imp=0x10001417c
  - finishDisconnected  imp=0x100014510
  - appBecameActive  imp=0x1000148cc
  - openSidePlay  imp=0x100014a94
  - idleView  imp=0x100014b54
  - setIdleView:  imp=0x100014b64
  - idleFrame  imp=0x100014b78
  - setIdleFrame:  imp=0x100014b88
  - statusLabel  imp=0x100014b9c
  - setStatusLabel:  imp=0x100014bac
  - openButton  imp=0x100014bc0
  - setOpenButton:  imp=0x100014bd0
  - showingFallback  imp=0x100014be4
  - respringButton  imp=0x100014bf4
  - setRespringButton:  imp=0x100014c04
  - introView  imp=0x100014c18
  - setIntroView:  imp=0x100014c28
  - introGrid  imp=0x100014c3c
  - setIntroGrid:  imp=0x100014c4c
  - introBlock  imp=0x100014c60
  - setIntroBlock:  imp=0x100014c70
  - introSpinner  imp=0x100014c84
  - setIntroSpinner:  imp=0x100014c94
  - introStatus  imp=0x100014ca8
  - setIntroStatus:  imp=0x100014cb8
  - introRunning  imp=0x100014ccc
  - setIntroRunning:  imp=0x100014cdc
  - calibrateMode  imp=0x100014cec
  - setCalibrateMode:  imp=0x100014cfc
  - calibrateView  imp=0x100014d0c
  - setCalibrateView:  imp=0x100014d1c
  - calibrateStatus  imp=0x100014d30
  - setCalibrateStatus:  imp=0x100014d40
  - calibrateGrid  imp=0x100014d54
  - setCalibrateGrid:  imp=0x100014d64
  - calibrateHolder  imp=0x100014d78
  - setCalibrateHolder:  imp=0x100014d88
  - calibrateFrame  imp=0x100014d9c
  - setCalibrateFrame:  imp=0x100014dac
  - calibrateKnobs  imp=0x100014dc0
  - setCalibrateKnobs:  imp=0x100014dd0
  - calibrateArrows  imp=0x100014de4
  - setCalibrateArrows:  imp=0x100014df4
  - calibrateRest  imp=0x100014e08
  - setCalibrateRest:  imp=0x100014e20
  - calibrateSteps  imp=0x100014e38
  - setCalibrateSteps:  imp=0x100014e48
  - previewScreen  imp=0x100014e5c
  - setPreviewScreen:  imp=0x100014e6c
  - previewCar  imp=0x100014e78
  - setPreviewCar:  imp=0x100014e88
  - previewBar  imp=0x100014e98
  - setPreviewBar:  imp=0x100014ea8
  - connectedView  imp=0x100014ebc
  - setConnectedView:  imp=0x100014ecc
  - ripples  imp=0x100014ee0
  - setRipples:  imp=0x100014ef0
  - connectedLogo  imp=0x100014f04
  - setConnectedLogo:  imp=0x100014f14
  - connectedGrid  imp=0x100014f28
  - setConnectedGrid:  imp=0x100014f38
  - statusRow  imp=0x100014f4c
  - setStatusRow:  imp=0x100014f5c
  - statusDot  imp=0x100014f70
  - setStatusDot:  imp=0x100014f80
  - flowRow  imp=0x100014f94
  - setFlowRow:  imp=0x100014fa4
  - flowBeam  imp=0x100014fb8
  - setFlowBeam:  imp=0x100014fc8
  - flowCut  imp=0x100014fdc
  - setFlowCut:  imp=0x100014fec
  - hintLabel  imp=0x100015000
  - setHintLabel:  imp=0x100015010
  - connectedTitle  imp=0x100015024
  - setConnectedTitle:  imp=0x100015034
  - countdownBar  imp=0x100015048
  - setCountdownBar:  imp=0x100015058
  - countdownFill  imp=0x10001506c
  - setCountdownFill:  imp=0x10001507c
  - showingConnected  imp=0x100015090
  - setShowingConnected:  imp=0x1000150a0
  - showingDisconnected  imp=0x1000150b0
  - setShowingDisconnected:  imp=0x1000150c0
  - connectedLabel  imp=0x1000150d0
  - setConnectedLabel:  imp=0x1000150e0
  - disconnectTimer  imp=0x1000150f4
  - setDisconnectTimer:  imp=0x100015104
  - disconnectRemaining  imp=0x100015118
  - setDisconnectRemaining:  imp=0x100015128
  - disconnectTap  imp=0x100015138
  - setDisconnectTap:  imp=0x100015148
  - .cxx_destruct  imp=0x10001515c

CLASS SPRingSpinner : ?  (instanceSize=80)
  IVAR _iconView : @"UIImageView" (8B)
  IVAR _side : d (8B)
  IVAR _iconSize : d (8B)
  IVAR _glow : @"CAGradientLayer" (8B)
  IVAR _track : @"CAShapeLayer" (8B)
  IVAR _arc : @"CAShapeLayer" (8B)
  IVAR _outerArc : @"CAShapeLayer" (8B)
  IVAR _pulse : @"CAShapeLayer" (8B)
  IVAR _period : d (8B)
  PROP iconView  [T@"UIImageView",&,N,V_iconView]
  PROP side  [Td,N,V_side]
  PROP iconSize  [Td,N,V_iconSize]
  PROP glow  [T@"CAGradientLayer",&,N,V_glow]
  PROP track  [T@"CAShapeLayer",&,N,V_track]
  PROP arc  [T@"CAShapeLayer",&,N,V_arc]
  PROP outerArc  [T@"CAShapeLayer",&,N,V_outerArc]
  PROP pulse  [T@"CAShapeLayer",&,N,V_pulse]
  PROP period  [Td,N,V_period]
  - initWithIconSize:cornerRadius:  imp=0x100015a5c
  - intrinsicContentSize  imp=0x1000166e8
  - layoutSubviews  imp=0x100016734
  - startAnimating  imp=0x100016a04
  - startAnimatingWithPeriod:  imp=0x100016a14
  - drawInWithPeriod:  imp=0x10001737c
  - stopAnimating  imp=0x1000177c0
  - settle  imp=0x100017a50
  - setPulsing:  imp=0x1000181a8
  - iconView  imp=0x100018824
  - setIconView:  imp=0x100018834
  - side  imp=0x100018848
  - setSide:  imp=0x100018858
  - iconSize  imp=0x100018868
  - setIconSize:  imp=0x100018878
  - glow  imp=0x100018888
  - setGlow:  imp=0x100018898
  - track  imp=0x1000188ac
  - setTrack:  imp=0x1000188bc
  - arc  imp=0x1000188d0
  - setArc:  imp=0x1000188e0
  - outerArc  imp=0x1000188f4
  - setOuterArc:  imp=0x100018904
  - pulse  imp=0x100018918
  - setPulse:  imp=0x100018928
  - period  imp=0x10001893c
  - setPeriod:  imp=0x10001894c
  - .cxx_destruct  imp=0x10001895c

CLASS SPBeamTrack : ?  (instanceSize=16)
  IVAR _beam : @"CAGradientLayer" (8B)
  PROP beam  [T@"CAGradientLayer",&,N,V_beam]
  PROP animating  [TB,R,N,GisAnimating]
  - initWithFrame:  imp=0x1000189ec
  - intrinsicContentSize  imp=0x100018ddc
  - layoutSubviews  imp=0x100018df0
  - startAnimating  imp=0x100018f30
  - stopAnimating  imp=0x100019148
  - isAnimating  imp=0x1000191d4
  - fadeOut  imp=0x10001928c
  - growIn  imp=0x1000194b0
  - setLineColor:animated:  imp=0x100019818
  - beam  imp=0x1000198e8
  - setBeam:  imp=0x1000198f8
  - .cxx_destruct  imp=0x10001990c
```

### 4.7. SidePlayPrefs — 18 class, 159 method

```
CLASS SPRootListController : ?  (instanceSize=16)
  - specifiers  imp=0x6b30
  - installedVersion:  imp=0x6c70
  - readPreferenceValue:  imp=0x6cc8
  - setPreferenceValue:specifier:  imp=0x6dd8
  - calibrateCar  imp=0x6ee8
  - reportBug  imp=0x6f78
  - resetAll  imp=0x7024
  - performReset  imp=0x7194
  - respring  imp=0x73c8

CLASS SPAppSettingsController : ?  (instanceSize=16)
  - appID  imp=0x74e4
  - group:footer:  imp=0x7540
  - setting:dict:cell:  imp=0x7554
  - specifiers  imp=0x7644
  - viewDidLoad  imp=0x7d98
  - readPreferenceValue:  imp=0x7e38
  - setPreferenceValue:specifier:  imp=0x8010
  - resetApp  imp=0x82e0

CLASS SPAppListController : ?  (instanceSize=16)
  - specifiers  imp=0x8478
  - viewDidLoad  imp=0x8c60

CLASS SPQuickProfileController : ?  (instanceSize=16)
  - profile  imp=0x8cb8
  - key:  imp=0x8d38
  - listNamed:key:values:titles:fallback:  imp=0x8dc0
  - specifiers  imp=0x8f30
  - viewDidLoad  imp=0x97b4
  - readPreferenceValue:  imp=0x9854
  - setPreferenceValue:specifier:  imp=0x9910

CLASS SPReportViewController : ?  (instanceSize=64)
  IVAR _scroll : @"UIScrollView" (8B)
  IVAR _carField : @"UITextField" (8B)
  IVAR _descriptionView : @"UITextView" (8B)
  IVAR _photoRow : @"UIStackView" (8B)
  IVAR _photos : @"NSMutableArray" (8B)
  IVAR _sendItem : @"UIBarButtonItem" (8B)
  IVAR _busyView : @"UIView" (8B)
  PROP scroll  [T@"UIScrollView",&,N,V_scroll]
  PROP carField  [T@"UITextField",&,N,V_carField]
  PROP descriptionView  [T@"UITextView",&,N,V_descriptionView]
  PROP photoRow  [T@"UIStackView",&,N,V_photoRow]
  PROP photos  [T@"NSMutableArray",&,N,V_photos]
  PROP sendItem  [T@"UIBarButtonItem",&,N,V_sendItem]
  PROP busyView  [T@"UIView",&,N,V_busyView]
  PROP hash  [TQ,R]
  PROP superclass  [T#,R]
  PROP description  [T@"NSString",R,C]
  PROP debugDescription  [T@"NSString",R,C]
  - viewDidLoad  imp=0x9adc
  - sectionLabel:  imp=0xb528
  - panel  imp=0xb610
  - textFieldShouldReturn:  imp=0xb7d8
  - textViewDidChange:  imp=0xb820
  - trimmed:  imp=0xb82c
  - updateSend  imp=0xb8d8
  - cancel  imp=0xba50
  - rebuildPhotos  imp=0xba64
  - removePhoto:  imp=0xc890
  - addPhotos  imp=0xc978
  - picker:didFinishPicking:  imp=0xcab8
  - showBusy:  imp=0xd028
  - send  imp=0xd788
  - showThanks  imp=0xf750
  - scroll  imp=0x108b8
  - setScroll:  imp=0x108c8
  - carField  imp=0x108dc
  - setCarField:  imp=0x108ec
  - descriptionView  imp=0x10900
  - setDescriptionView:  imp=0x10910
  - photoRow  imp=0x10924
  - setPhotoRow:  imp=0x10934
  - photos  imp=0x10948
  - setPhotos:  imp=0x10958
  - sendItem  imp=0x1096c
  - setSendItem:  imp=0x1097c
  - busyView  imp=0x10990
  - setBusyView:  imp=0x109a0
  - .cxx_destruct  imp=0x109b4

CLASS SPHDiagnosticsController : ?  (instanceSize=56)
  IVAR _refreshing : B (1B)
  IVAR _reportView : @"UITextView" (8B)
  IVAR _includeCrashes : @"UISwitch" (8B)
  IVAR _crashFiles : @"NSArray" (8B)
  IVAR _reportButtons : @"NSArray" (8B)
  PROP reportView  [T@"UITextView",&,N,V_reportView]
  PROP includeCrashes  [T@"UISwitch",&,N,V_includeCrashes]
  PROP crashFiles  [T@"NSArray",C,N,V_crashFiles]
  PROP reportButtons  [T@"NSArray",C,N,V_reportButtons]
  PROP refreshing  [TB,N,V_refreshing]
  - specifiers  imp=0x10eec
  - viewDidLoad  imp=0x10f44
  - refreshReport  imp=0x11ecc
  - message:  imp=0x12598
  - copyReport  imp=0x12658
  - exportReport:  imp=0x12708
  - reportView  imp=0x12f20
  - setReportView:  imp=0x12f30
  - includeCrashes  imp=0x12f44
  - setIncludeCrashes:  imp=0x12f54
  - crashFiles  imp=0x12f68
  - setCrashFiles:  imp=0x12f78
  - reportButtons  imp=0x12f84
  - setReportButtons:  imp=0x12f94
  - refreshing  imp=0x12fa0
  - setRefreshing:  imp=0x12fb0
  - .cxx_destruct  imp=0x12fc0

CLASS SPHModuleOrderCell : ?  (instanceSize=40)
  IVAR _moduleTable : @"UITableView" (8B)
  IVAR _moduleDataSource : @"SPHModuleOrderDataSource" (8B)
  IVAR _horizontalPreview : @"UIStackView" (8B)
  IVAR _verticalPreview : @"UIStackView" (8B)
  PROP moduleTable  [T@"UITableView",&,N,V_moduleTable]
  PROP moduleDataSource  [T@"SPHModuleOrderDataSource",&,N,V_moduleDataSource]
  PROP horizontalPreview  [T@"UIStackView",&,N,V_horizontalPreview]
  PROP verticalPreview  [T@"UIStackView",&,N,V_verticalPreview]
  - initWithStyle:reuseIdentifier:specifier:  imp=0x13028
  - dealloc  imp=0x13e1c
  - layoutSubviews  imp=0x13e94
  - settingsChanged  imp=0x13f44
  - refreshPreview  imp=0x14050
  - resetOrder  imp=0x1538c
  - moduleTable  imp=0x1557c
  - setModuleTable:  imp=0x1558c
  - moduleDataSource  imp=0x155a0
  - setModuleDataSource:  imp=0x155b0
  - horizontalPreview  imp=0x155c4
  - setHorizontalPreview:  imp=0x155d4
  - verticalPreview  imp=0x155e8
  - setVerticalPreview:  imp=0x155f8
  - .cxx_destruct  imp=0x1560c

CLASS SPHModuleOrderDataSource : ?  (instanceSize=32)
  IVAR _order : @"NSMutableArray" (8B)
  IVAR _preferenceKey : @"NSString" (8B)
  IVAR _orderChanged : @? (8B)
  PROP order  [T@"NSMutableArray",&,N,V_order]
  PROP preferenceKey  [T@"NSString",C,N,V_preferenceKey]
  PROP orderChanged  [T@?,C,N,V_orderChanged]
  PROP hash  [TQ,R]
  PROP superclass  [T#,R]
  PROP description  [T@"NSString",R,C]
  PROP debugDescription  [T@"NSString",R,C]
  - numberOfSectionsInTableView:  imp=0x15674
  - tableView:numberOfRowsInSection:  imp=0x1567c
  - tableView:cellForRowAtIndexPath:  imp=0x156c8
  - tableView:canMoveRowAtIndexPath:  imp=0x159d4
  - tableView:editingStyleForRowAtIndexPath:  imp=0x159dc
  - tableView:shouldIndentWhileEditingRowAtIndexPath:  imp=0x159e4
  - tableView:moveRowAtIndexPath:toIndexPath:  imp=0x159ec
  - order  imp=0x15cb8
  - setOrder:  imp=0x15cc0
  - preferenceKey  imp=0x15ccc
  - setPreferenceKey:  imp=0x15cd8
  - orderChanged  imp=0x15ce0
  - setOrderChanged:  imp=0x15cec
  - .cxx_destruct  imp=0x15cf4

CLASS SPHSegmentedCell : ?  (instanceSize=24)
  IVAR _picker : @"UISegmentedControl" (8B)
  IVAR _settingSpecifier : @"PSSpecifier" (8B)
  PROP picker  [T@"UISegmentedControl",&,N,V_picker]
  PROP settingSpecifier  [T@"PSSpecifier",&,N,V_settingSpecifier]
  - initWithStyle:reuseIdentifier:specifier:  imp=0x15d30
  - layoutSubviews  imp=0x16568
  - changed:  imp=0x16618
  - picker  imp=0x16894
  - setPicker:  imp=0x168a4
  - settingSpecifier  imp=0x168b8
  - setSettingSpecifier:  imp=0x168c8
  - .cxx_destruct  imp=0x168dc

CLASS SPHSizeSliderCell : ?  (instanceSize=40)
  IVAR _offset : B (1B)
  IVAR _sizeKey : @"NSString" (8B)
  IVAR _sizeSlider : @"UISlider" (8B)
  IVAR _valueLabel : @"UILabel" (8B)
  PROP sizeKey  [T@"NSString",C,N,V_sizeKey]
  PROP sizeSlider  [T@"UISlider",&,N,V_sizeSlider]
  PROP valueLabel  [T@"UILabel",&,N,V_valueLabel]
  PROP offset  [TB,N,V_offset]
  - initWithStyle:reuseIdentifier:specifier:  imp=0x1691c
  - layoutSubviews  imp=0x17748
  - updateValue  imp=0x177f8
  - sizeChanged:  imp=0x1793c
  - resetSize  imp=0x17bd0
  - sizeKey  imp=0x17c90
  - setSizeKey:  imp=0x17ca0
  - sizeSlider  imp=0x17cac
  - setSizeSlider:  imp=0x17cbc
  - valueLabel  imp=0x17cd0
  - setValueLabel:  imp=0x17ce0
  - offset  imp=0x17cf4
  - setOffset:  imp=0x17d04
  - .cxx_destruct  imp=0x17d14

CLASS SPHPreferencesController : ?  (instanceSize=24)
  IVAR _sourceSpecifier : @"PSSpecifier" (8B)
  PROP sourceSpecifier  [T@"PSSpecifier",&,N,V_sourceSpecifier]
  - refreshControlHeights  imp=0x17d68
  - traitCollectionDidChange:  imp=0x1806c
  - viewWillAppear:  imp=0x1817c
  - specifiers  imp=0x18244
  - readPreferenceValue:  imp=0x192b4
  - setPreferenceValue:specifier:  imp=0x193a4
  - sourceSpecifier  imp=0x19934
  - setSourceSpecifier:  imp=0x19944
  - .cxx_destruct  imp=0x19958

CLASS SPHPositionPreviewCell : ?  (instanceSize=24)
  IVAR _preview : @"UIImageView" (8B)
  IVAR _positionKey : @"NSString" (8B)
  PROP preview  [T@"UIImageView",&,N,V_preview]
  PROP positionKey  [T@"NSString",C,N,V_positionKey]
  - initWithStyle:reuseIdentifier:specifier:  imp=0x1996c
  - dealloc  imp=0x19f1c
  - layoutSubviews  imp=0x19f94
  - refreshPreview  imp=0x1a044
  - preview  imp=0x1a354
  - setPreview:  imp=0x1a364
  - positionKey  imp=0x1a378
  - setPositionKey:  imp=0x1a388
  - .cxx_destruct  imp=0x1a394

CLASS SPHPositionController : SPHPreferencesController  (instanceSize=24)
  - specifiers  imp=0x1a3d4

CLASS SPHMenuCell : ?  (instanceSize=32)
  IVAR _menuButton : @"UIButton" (8B)
  IVAR _settingLabel : @"UILabel" (8B)
  IVAR _settingSpecifier : @"PSSpecifier" (8B)
  PROP menuButton  [T@"UIButton",&,N,V_menuButton]
  PROP settingLabel  [T@"UILabel",&,N,V_settingLabel]
  PROP settingSpecifier  [T@"PSSpecifier",&,N,V_settingSpecifier]
  - initWithStyle:reuseIdentifier:specifier:  imp=0x1a810
  - traitCollectionDidChange:  imp=0x1b2c4
  - layoutSubviews  imp=0x1b3bc
  - refreshMenu  imp=0x1b578
  - menuButton  imp=0x1c1bc
  - setMenuButton:  imp=0x1c1cc
  - settingLabel  imp=0x1c1e0
  - setSettingLabel:  imp=0x1c1f0
  - settingSpecifier  imp=0x1c204
  - setSettingSpecifier:  imp=0x1c214
  - .cxx_destruct  imp=0x1c228

CLASS SPHSurfaceController : SPHPreferencesController  (instanceSize=24)
  - specifiers  imp=0x1c27c

CLASS SPHPhonePositionController : SPHPreferencesController  (instanceSize=24)
  - specifiers  imp=0x1d210

CLASS SPHOverspeedController : SPHPreferencesController  (instanceSize=24)
  - specifiers  imp=0x1d768

CLASS SPHOutputEndpoint : ?  (instanceSize=105)
  IVAR tokens : [8i] (32B)
  IVAR previous : {?="words"[6Q]} (48B)
  IVAR previousSelection : Q (8B)
  IVAR previousCommit : Q (8B)
  IVAR published : B (1B)
  - initWithSourceID:  imp=0x20480
  - dealloc  imp=0x20698
```

### 4.8. Hàm C/C++ định nghĩa trong từng binary (toàn bộ symbol `T/t` đã export/local)

**SidePlay.dylib — 102 hàm:**

```
_SPAppSupportsPad
_SPAudioListen
_SPAudioStart
_SPAudioStopListening
_SPHBubbleEnabled
_SPHCarPlayCardSizeForLayout
_SPHCarPlayCardSizeForView
_SPHCardCanvasSize
_SPHCardOriginFor
_SPHCardSizeFor
_SPHClampCardOrigin
_SPHCreateSpeedCard
_SPHDecodeAlert
_SPHDecodeAlertWithin
_SPHDecodeBubbleLayout
_SPHDecodeBubbleVisibility
_SPHDecodeModuleOrder
_SPHDecodePhonePlacement
_SPHDecodePlacement
_SPHDecodeSample
_SPHDecodeSize
_SPHDecodeSourceOutput
_SPHEncodeAlert
_SPHEncodeBubbleConfiguration
_SPHEncodeBubbleVisibility
_SPHEncodeOverspeedLease
_SPHEncodePhonePlacement
_SPHEncodePlacement
_SPHEncodeSample
_SPHEncodeSizes
_SPHEncodeSourceOutput
_SPHMigratePhoneOffsets
_SPHModuleFrame
_SPHNextTapSize
_SPHNormalizeModuleOrder
_SPHNormalizeSourceOutput
_SPHOffsetPercent
_SPHOffsetPercentFromPoints
_SPHOutputFrameReadable
_SPHOutputRequestName
_SPHOverspeedLeaseActive
_SPHOverspeedMode
_SPHPhoneCardOriginFor
_SPHPhoneCardSizeFor
_SPHPhoneCardSizeForLayout
_SPHProgressFor
_SPHPublishOverspeedLease
_SPHPublishSavedSizes
_SPHPublishSourceOutput
_SPHReadSourceOutput
_SPHRequestSelectedSource
_SPHRestoreOutputSelection
_SPHRoadAlertIconName
_SPHRoadAlertName
_SPHSavePhoneDrag
_SPHScaleCardSize
_SPHSelectOutputSource
_SPHSelectedSourceID
_SPHSetSpeedCard
_SPHSetSpeedCardClarity
_SPHShouldRequestSource
_SPHSizePercent
_SPHSourceDisplayName
_SPHSourceEnabled
_SPHSourceIDForSelection
_SPHSourceIDValid
_SPHSourceOutput
_SPHTrashDrop
_SPHTrashShow
_SPHTrashTrack
_SPHWarningFor
_SPHudHide
_SPHudShow
_SPHudStart
_SPKeepAliveAdd
_SPKeepAliveContains
_SPKeepAliveCount
_SPKeepAliveRemove
_SPLog
_SPNoticeButton
_SPNoticeCard
_SPNoticeTitle
_SPPaneOrientation
_SPPref
_SPPrefBool
_SPPrefInt
_SPPrefRatio
_SPPrefSplit
_SPServiceBlock
_SPServiceOffer
_SPServiceRefresh
_SPServiceRefreshThen
_SPServiceSetPreview
_SPServiceSnoozeOffer
_SPServiceStart
_SPServiceUpdateLine
_SPServiceWhatsNew
_SPServiceWhatsNewSeen
_SPSetPaneOrientation
_SPSetPref
_SPTerminateApp
_SPWeakDevice
```

**SidePlayHUDRelay.dylib — 48 hàm:**

```
_SPHBubbleEnabled
_SPHDecodeAlert
_SPHDecodeAlertWithin
_SPHDecodeBubbleLayout
_SPHDecodeBubbleVisibility
_SPHDecodeModuleOrder
_SPHDecodePhonePlacement
_SPHDecodePlacement
_SPHDecodeSample
_SPHDecodeSize
_SPHDecodeSourceOutput
_SPHEncodeAlert
_SPHEncodeBubbleConfiguration
_SPHEncodeBubbleVisibility
_SPHEncodeOverspeedLease
_SPHEncodePhonePlacement
_SPHEncodePlacement
_SPHEncodeSample
_SPHEncodeSizes
_SPHEncodeSourceOutput
_SPHMigratePhoneOffsets
_SPHNextTapSize
_SPHNormalizeModuleOrder
_SPHNormalizeSourceOutput
_SPHOffsetPercent
_SPHOffsetPercentFromPoints
_SPHOutputFrameReadable
_SPHOutputRequestName
_SPHOverspeedLeaseActive
_SPHOverspeedMode
_SPHPublishOverspeedLease
_SPHPublishSavedSizes
_SPHPublishSourceOutput
_SPHReadSourceOutput
_SPHRequestSelectedSource
_SPHRestoreOutputSelection
_SPHRoadAlertIconName
_SPHRoadAlertName
_SPHSavePhoneDrag
_SPHSelectOutputSource
_SPHSelectedSourceID
_SPHShouldRequestSource
_SPHSizePercent
_SPHSourceDisplayName
_SPHSourceEnabled
_SPHSourceIDForSelection
_SPHSourceIDValid
_SPHSourceOutput
```

**SidePlayHUDGofa.dylib — 29 hàm (+ Swift, xem 3.3):**

```
_$s7SPHGofa10gofaPointsySiSV_s5Int32VSpySiGAESpySdGAFSitF
_$s7SPHGofa14gofaSpeedBoardys5Int32VSV_SpySiGAEtF
_SPHDecodeAlert
_SPHDecodeAlertWithin
_SPHDecodeSample
_SPHDecodeSourceOutput
_SPHEncodeAlert
_SPHEncodeSample
_SPHEncodeSourceOutput
_SPHGofaPoints
_SPHGofaSpeedBoard
_SPHNormalizeSourceOutput
_SPHOutputFrameReadable
_SPHOutputRequestName
_SPHPublishSourceOutput
_SPHReadSourceOutput
_SPHRefreshLocationSession
_SPHRequestSelectedSource
_SPHRestoreOutputSelection
_SPHRoadAlertIconName
_SPHRoadAlertName
_SPHSelectOutputSource
_SPHSelectedSourceID
_SPHShouldRequestSource
_SPHSourceDisplayName
_SPHSourceEnabled
_SPHSourceIDForSelection
_SPHSourceIDValid
_SPHSourceOutput
```

**SidePlayHUDVietMap.dylib — 45 hàm:**

```
_SPHDecodeAlert
_SPHDecodeAlertWithin
_SPHDecodeSample
_SPHDecodeSourceOutput
_SPHDescribeDiagnostic
_SPHDiagnosticsAppVersion
_SPHDiagnosticsCrashFiles
_SPHDiagnosticsFindCrashes
_SPHDiagnosticsRecord
_SPHDiagnosticsReport
_SPHDiagnosticsStart
_SPHEncodeAlert
_SPHEncodeDiagnostic
_SPHEncodeSample
_SPHEncodeSourceOutput
_SPHNavCopyOverlayArguments
_SPHNavPayload
_SPHNormalizeSourceOutput
_SPHOutputFrameReadable
_SPHOutputRequestName
_SPHPublishSourceOutput
_SPHReadSourceOutput
_SPHRefreshLocationSession
_SPHRequestSelectedSource
_SPHRestoreOutputSelection
_SPHRoadAlertIconName
_SPHRoadAlertName
_SPHSelectOutputSource
_SPHSelectedSourceID
_SPHShouldRequestSource
_SPHSourceDisplayName
_SPHSourceEnabled
_SPHSourceIDForSelection
_SPHSourceIDValid
_SPHSourceOutput
_SPHVietMapAlertObservation
_SPHVietMapAlertsFromPayload
_SPHVietMapAssetName
_SPHVietMapKindForAssetName
_SPHVietMapKindForImage
_SPHVietMapKindForImageDigest
_SPHVietMapOutput
_SPHVietMapOutputAlert
_SPHVietMapOverlayObservation
_SPHVietMapOverlayStickyAlerts
```

**SidePlayHUDWaze.dylib — 30 hàm:**

```
_SPHDecodeAlert
_SPHDecodeAlertWithin
_SPHDecodeSample
_SPHDecodeSourceOutput
_SPHEncodeAlert
_SPHEncodeSample
_SPHEncodeSourceOutput
_SPHInitializeWazeNavigation
_SPHNormalizeSourceOutput
_SPHOutputFrameReadable
_SPHOutputRequestName
_SPHPublishSourceOutput
_SPHReadSourceOutput
_SPHRefreshLocationSession
_SPHRequestSelectedSource
_SPHRestoreOutputSelection
_SPHRoadAlertIconName
_SPHRoadAlertName
_SPHSelectOutputSource
_SPHSelectedSourceID
_SPHShouldRequestSource
_SPHSourceDisplayName
_SPHSourceEnabled
_SPHSourceIDForSelection
_SPHSourceIDValid
_SPHSourceOutput
_SPHStopWazeNavigation
_SPHWazeNavigationInitializing
_SPHWazeOwnsNavigation
_SPHWazeTransferNavigation
```

**SidePlay.app — 9 hàm:**

```
_SPAppPost
_SPAppPref
_SPAppSetPref
_SPTechAccent
_SPTechCyan
_SPTechLayoutGrid
_SPTechMakeGrid
__mh_execute_header
_main
```

**SidePlayPrefs — 56 hàm:**

```
_SPHBubbleEnabled
_SPHDecodeAlert
_SPHDecodeAlertWithin
_SPHDecodeBubbleLayout
_SPHDecodeBubbleVisibility
_SPHDecodeModuleOrder
_SPHDecodePhonePlacement
_SPHDecodePlacement
_SPHDecodeSample
_SPHDecodeSize
_SPHDecodeSourceOutput
_SPHDescribeDiagnostic
_SPHDiagnosticsAppVersion
_SPHDiagnosticsCrashFiles
_SPHDiagnosticsFindCrashes
_SPHDiagnosticsRecord
_SPHDiagnosticsReport
_SPHDiagnosticsStart
_SPHEncodeAlert
_SPHEncodeBubbleConfiguration
_SPHEncodeBubbleVisibility
_SPHEncodeDiagnostic
_SPHEncodeOverspeedLease
_SPHEncodePhonePlacement
_SPHEncodePlacement
_SPHEncodeSample
_SPHEncodeSizes
_SPHEncodeSourceOutput
_SPHMigratePhoneOffsets
_SPHNextTapSize
_SPHNormalizeModuleOrder
_SPHNormalizeSourceOutput
_SPHOffsetPercent
_SPHOffsetPercentFromPoints
_SPHOutputFrameReadable
_SPHOutputRequestName
_SPHOverspeedLeaseActive
_SPHOverspeedMode
_SPHPublishOverspeedLease
_SPHPublishSavedSizes
_SPHPublishSourceOutput
_SPHReadSourceOutput
_SPHRequestSelectedSource
_SPHRestoreOutputSelection
_SPHRoadAlertIconName
_SPHRoadAlertName
_SPHSavePhoneDrag
_SPHSelectOutputSource
_SPHSelectedSourceID
_SPHShouldRequestSource
_SPHSizePercent
_SPHSourceDisplayName
_SPHSourceEnabled
_SPHSourceIDForSelection
_SPHSourceIDValid
_SPHSourceOutput
```

### 4.9. Chuỗi (strings) đáng chú ý đã trích

Toàn bộ strings thô lưu ở `work/analysis/strings_*.txt` (6.506 dòng cho riêng lõi). Các họ chuỗi then chốt:

- **Darwin notify / IPC của HUD** (tiền tố `com.sideplay.hud.`): `background.carplay`, `background.location-session`, `background.location-source`, `background.permission`, `background.phone`, `background.sideplay`, `bubble-configuration`, `bubble-visibility`, `overspeed.lease`, `overspeed.mode`, `phone-placement-percent`, `placement-state`, `size-changed`, `size-state`, `source.vietmap.request`, và họ legacy: `legacy.speed`, `legacy.limit`, `legacy.alert.first`, `legacy.alert.second` (+ biến thể `.test.`), mẫu debug `com.sideplay.hud.debug.v1.%@.%@`.
- **Kênh lệnh app ↔ lõi** (tiền tố `com.sideplay/`): `open`, `close`, `go-home`, `phone`, `phone-hide`, `ping`, `state`, `prefs`, `calibrate`, `calibrate-saved`, `calibrate-cancelled`, `car-area`, `refresh-status`, `app-closed`, `audio-began/`, `audio-ended/`, `audio-ended-resume/`, `touch/`, tiền tố `preview-`. Thêm: `com.sideplay.orientation`, `com.sideplay.log`, `com.sideplay.hosted.plist` (tên file trạng thái các app đang được host).
- **Đường dẫn file**: `/var/mobile/Library/Preferences/com.sideplay.install` (hồ sơ cài đặt nặc danh), `/var/mobile/Library/Preferences/.sideplay-disable` (kill switch), `/var/mobile/Library/Preferences/.sideplay-boot-count`, log `/var/mobile/Library/Logs/SidePlay.log` và `/var/mobile/Library/Logs/SidePlay-hud.log`, thư mục icon HUD `/usr/share/sideplay-hud` (tiền tố cài đặt `/var/jb/usr/share/sideplay-hud`).
- **Mạng**: `https://sideplay.pages.dev/`, `/api/status`, `/api/report`; depiction Sileo trong control trỏ cùng domain.
- **Log hành vi của lõi** (mẫu): `SidePlay opened on %@, window %@, canvas %@`, `[SidePlay] geometry update refused: %@`, `quit %lu app(s) opened in SidePlay`, `SidePlay app %@: SidePlay keeps running on CarPlay`, `car gone: closing SidePlay on CarPlay`, `open on phone ignored: SidePlay is on CarPlay`, `[SidePlay] %@ uses the iPad interface`, `sp_isHostedBySidePlay` (khóa đánh dấu app đang được host).

---

## 5. CƠ CHẾ A→Z

### 5.1. Cài đặt & nạp

1. dpkg cài payload vào tiền tố rootless `/var/jb/`; `postinst` chạy `uicache -p` đăng ký `SidePlay.app`.
2. MobileSubstrate/ElleKit nạp các dylib theo filter: lõi `SidePlay.dylib` vào SpringBoard (+ mọi tiến trình UIKit theo filter), `SidePlayHUDRelay.dylib` vào SpringBoard, 3 HUD source vào đúng tiến trình app bản đồ của chúng (GOFA/VietMap Live/Waze), `SidePlayPrefs` được PreferenceLoader nạp trong Settings.
3. Constructor của lõi kiểm tra an toàn trước khi hoạt động (chuỗi bằng chứng): nếu có file kill switch `.sideplay-disable` → không nạp tiếp; nếu SpringBoard khởi động lại quá nhanh nhiều lần (`.sideplay-boot-count`) → tự vô hiệu để tránh vòng lặp crash. Log `SidePlay loaded in SpringBoard` khi qua cổng.

### 5.2. Phía xe: app template + lõi host scene

1. Người dùng mở SidePlay trên CarPlay → hệ thống tạo `CPTemplateApplicationScene` cho `SidePlay.app` (entitlement CarPlay audio + platform-application), `SPCarSceneDelegate` dựng giao diện template/launcher (`SPLauncherViewController`, `CPListTemplate`).
2. App gửi lệnh qua Darwin notify `com.sideplay/open` (và các lệnh họ hàng) sang lõi trong SpringBoard.
3. `SPDash` (lõi) tạo cửa sổ phía xe (`_carWindow`, ghi lại `_carWindowScreen`, `_carWindowFrame`), dựng lưới thẻ app (`SPCardScroll`/`SPDashCard`/`SPDashQuick`) và các ô chứa `SPPane`.
4. Khi chọn một app: lõi tra `SBApplicationController`, tạo scene entity `SBDeviceApplicationSceneEntity`, dựng `SBAppViewController`/`SBDeviceApplicationSceneView` gắn vào `SPPane` (`_appViewController`, `_sceneMonitor` = FBSceneMonitor theo dõi scene), đặt hình học theo khung ô (`SPHCardCanvasSize`, `SPHClampCardOrigin`, từ chối cập nhật hình học không hợp lệ — `geometry update refused`).
5. Bố cục: 1 app toàn ô hoặc 2 app cạnh nhau (`_split`, `_ratio`, `_slotOrder`, `_paneApps`); có nút đổi chỗ (swap, cả chiều dọc), đóng ô, nút layout, chip tiêu đề/icon từng ô; app có thể bị ép dùng giao diện iPad (`hostedIdiom`, log `uses the iPad interface`) và `scaleMode` (Mặc định/Giữ tỉ lệ/Phủ kín ô) cho từng ô.
6. Chu kỳ sống: theo dõi kết nối CarPlay (`CarPlayIsConnectedDidChange`, `_carWatchTimer`, `_carMissedChecks` — chuỗi lịch sử ghi nhận lõi tham chiếu sự kiện này); mất xe → đóng SidePlay phía xe (`car gone: closing SidePlay on CarPlay`); ẩn trên xe vẫn giữ app chạy (`SidePlay hidden on CarPlay (apps kept)`); thoát hẳn → `quit %lu app(s) opened in SidePlay`. Trạng thái phiên được khôi phục theo preference `restoreLast`.
7. Tương tác chéo điện thoại ↔ xe: lệnh `com.sideplay/phone`, `phone-hide`, `go-home`, `app-closed`, họ `audio-began/ended` (đồng bộ khi app được host phát/kết thúc âm thanh — lõi có họ hàm `SPAudioStart/StopListening`), `orientation` (xoay). Mở trên điện thoại khi đang hiện trên xe bị từ chối có chủ đích (`open on phone ignored: SidePlay is on CarPlay`).
8. Hiệu chỉnh màn hình xe: `SPCalibrationView` + lệnh `calibrate`/`calibrate-saved`/`calibrate-cancelled`/`car-area`, preference `carZoom` (70–130%) và `autoFitCar`.

### 5.3. Kênh IPC tổng thể

Ba kênh được dùng đồng thời (bằng chứng import + chuỗi):
