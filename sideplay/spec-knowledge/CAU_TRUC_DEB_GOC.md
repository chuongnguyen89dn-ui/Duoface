# CẤU TRÚC DEB GỐC — com.sideplay 1.0.4-1 (iphoneos-arm64, rootless)

Nguồn: bung từ file `com.sideplay_1.0.4-1_iphoneos-arm64.deb` ở gốc repo
(SHA256 `7f8520b9a290…a9c`, 4.352.576 B). Cây đã bung nằm sẵn trong repo tại
`sideplay/extracted-1.0.4-1/`; bản kiểm kê chi tiết tại
`sideplay/audit/deb-1.0.4-1/` (inventory.json, macho-load-commands.json,
macho-strings/). Tổng rootfs: 136 file, 14 thư mục, ~7,0 MB; 7 file Mach-O,
9 plist, 119 PNG. Đây là bản đồ CẤU TRÚC ĐÓNG GÓI (layout), không phải source —
các dylib là binary đã biên dịch.

## Control (DEBIAN/control)
- Package: `com.sideplay` — Name: SidePlay — Version: `1.0.4-1`
- Description: "Split screen for CarPlay. Run any app on the car screen, one or two side by side."
- Depends: firmware (>= 15.0), mobilesubstrate, preferenceloader
- Conflicts: com.cortex.carplayenable, com.pavunato.carsurf, com.bmt.dash, com.chou.googlemaps.vietmap
- DEBIAN còn có: postinst (241 B), prerm (530 B)

## Cây rootfs (var/jb/…)
```
Applications/SidePlay.app/            — app cấu hình (com.sideplay.app, bản 1.0.4, scene manifest gồm
                                        Phone scene + CPTemplateApplicationScene "CarPlay")
  SidePlay (178.672 B), Info.plist, AppIcon…
Library/MobileSubstrate/DynamicLibraries/
  SidePlay.dylib        899.088 B  ← Filter: com.apple.springboard + com.apple.UIKit (dylib chính: host app lên màn xe, chia khung)
  SidePlayHUDRelay.dylib 240.128 B ← Filter: com.apple.springboard (relay sự kiện cho HUD)
  SidePlayHUDGofa.dylib  129.936 B ← Filter: com.lumi.GOFA
  SidePlayHUDVietMap.dylib 162.752 B ← Filter: vn.vietmap.live
  SidePlayHUDWaze.dylib  145.328 B ← Filter: com.waze.iphone
  (mỗi dylib kèm .plist Filter cùng tên, 49–76 B)
Library/PreferenceBundles/SidePlayPrefs.bundle/ — SidePlayPrefs 613.648 B, Root.plist (bảng cài đặt)
Library/PreferenceLoader/Preferences/SidePlay.plist (513 B)
usr/share/sideplay-hud/               — ~110 PNG: icon biển báo/giới hạn tốc độ/camera cho HUD + LICENSE-GMapHUD
```

## Ghi chú cho Spec
- Kiến trúc đóng gói: 1 dylib chính chạy trong SpringBoard lo việc host/chia màn;
  HUD tách thành relay (SpringBoard) + mỗi app bản đồ một dylib HUD riêng nạp
  trong process của app đó qua Filter theo bundle id.
- Bản DuoFace QA mà Muse đang triển khai là MỘT package khác, viết lại qua các
  vòng QA (không phải bản này); source hiện tại ở `sideplay/duoface-native-scene-host/`
  trên nhánh spec-main. File này chỉ để nắm cấu trúc deb gốc làm tham chiếu.
