# DuoFace QA7 — khắc phục regression UI quay lại SidePlay sau QA6

**Trạng thái:** QA6 thất bại khi thử máy (ảnh user ~20:14 ICT 2026-10-18), QA7 build và kiểm tĩnh SUCCESS; **chưa nghiệm thu trên CarPlay**, **không phải giao diện Native12 hoàn chỉnh**.

## Quan sát được, không nhầm với phỏng đoán

- Ảnh user `IMG_6129F0FC-044F-4AD0-8C4A-9C236DA1E383.jpeg` trong cuộc chat: bản đồ/ứng dụng đang loading bên trong hai panel xanh SidePlay, thanh tiêu đề "YouTube" và "Waze", nút Grid / mũi tên / X, không thấy pill đôi và logo divider DuoFace, thanh ứng dụng CarPlay vẫn không xuất hiện. Screenshot không chứa Installed package version.
- Sileo repo `chuongnguyen89dn-ui/carplaydsp` trước QA7 pin `com.duoface.sideplaydisplay 0.1.4~native12root6`, SHA `29cf90cef569622d9d5d60dda453c4c8de950960e86b15acef70556615483763`; build+Pages QA6 [39128558985](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/39128558985) PASS. Đã phát hành QA6 ≠ đã khởi tạo UI.
- **Đường fallback có thật từ source:** QA6 `sideplay/sileo-qa/Tweak.xm` 419–427 nếu `DFSPNative12Host init` trả nil thì `DFSPRemove()`; 443–447 nếu `DFSPApply(NO,startup)` thất bại cũng `DFSPRemove()`. Cả hai đều phục hồi `hidden` SidePlay view và gỡ `DFSPNativeFrame`. Điều kiện root không descendant, transform không identity, invalid usable frame ... đều có thể gây từ chối, **chưa biết điều kiện nào đúng trên máy user**.

## QA7 source patch, đúng phạm vi

- Nhánh `feature/duoface-native12-qa7-no-legacy-fallback`, `sideplay/sileo-qa/Tweak.xm`, commit `3c97be817b0b7109cb22c50298ac67a2c553f07c`.
- Nếu Native12 root host invalid ⇒ `DFSPVisualCompatibility=YES`, **vẫn gắn `DFSPNativeFrame` và gọi `DFSPRefresh`**, ẩn `chipView/layoutButton` gốc, KHÔNG resize `UIWindow`, KHÔNG động vào scene app. Nếu `applyNormal` thất bại ⇒ `restoreAndDetach` root, trả nguyên level/background, giữ view DuoFace trên cửa sổ, ghi marker.
- Trong fallback, **khóa Zoom** vì host/chrome chưa được xác nhận, không giả vờ khôi phục thanh hệ thống. Khi re-connect chỉ retry geometry nếu owner đã valid. Khi kết thúc phiên, restore hidden state, content root và window flags.
- Log runtime `/var/mobile/Library/Logs/DuoFaceSidePlayDisplayQA.log`: marker `QA7 injection and SPDash hooks installed (0.1.5~native12visual7)`, `QA7 owner-check attached=`, `QA7 VISUAL_COMPATIBILITY`, `QA7: host Normal failed`, `QA7: Zoom blocked`, `SPDash class missing`. Không lưu vị trí GPS/tuyến đường/ứng dụng đang phát.
- Package `com.duoface.sideplaydisplay`, version `0.1.5~native12visual7`, vẫn phụ thuộc `com.sideplay >=1.0.4-1`. **KHÔNG** chép vendor SidePlay hoặc DuoNavi binary, Native12/HUD8 stable không bị sửa.
- GitHub build QA7 [39131070908](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39131070908) **SUCCESS**; checks 2 pills + fallback + Theos + manifest + artifact. Gói `sideplay/artifacts/native12visual7/com.duoface.sideplaydisplay_0.1.5~native12visual7_iphoneos-arm64.deb`, SHA256 `c221584b16af24f844dbb968d90ffbcd6efbbc64a312a6582d955fc45348901d`. **Static/build PASS, NOT CarPlay pass.**
- Sileo QA entry update `chuongnguyen89dn-ui/carplaydsp:.github/workflows/build.yml` commit `387f407a1110d55904d81624d52787de80448cdd` pin immutable artifact commit `beafe5b6ab020859b82e627ca635046796d9d956`; Pages run [39131231625](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/39131231625). Chỉ coi RELEASE sau khi **build và deploy SUCCESS**, không dự đoán.

## Các mục vẫn CHƯA đạt

- **Thanh bar CarPlay:** chưa có owner chrome runtime/IPC hai process; QA7 không phục hồi bar. Không giới thiệu tạm offset 64pt và z-order như một fix bar.
- Hai ứng dụng scene resize cùng divider/touch; 8 kiểu chia Native12; menu picker/cards/Style Native12, startup/splash Native12; HUD8; tích hợp CarPlay app-host độc lập khỏi SidePlay vendor.
- QA7 visual fallback vẫn có thể để khung SidePlay và bar sai **bên dưới**; mục tiêu QA7 chỉ là không tự xóa giao diện DuoFace khi host fail. Nếu QA7 vẫn chỉ hiện UI SidePlay, log xác định liệu tweak không inject, window không external, class SPDash không tìm được, hay root/pane hình học không hợp lệ.

## Kiểm tra trên thiết bị để xác nhận đúng lỗi

1. Sileo → cập nhật source → chọn **DuoFace Native12 UI Recovery QA7** package ID `com.duoface.sideplaydisplay`, version `0.1.5~native12visual7`; cài và respring nếu được yêu cầu. Không gỡ SidePlay gốc hoặc Native12/HUD8 stable.
2. Xe đỗ, kết nối CarPlay chưa nhấn Zoom, chụp cả màn: có hai pill DuoFace **giữa phía trên** hai pane hay vẫn header SidePlay; native bar có/không. Đây là test FAIL/PASS riêng.
3. Qua Filza (hoặc ứng dụng file có quyền root) mở `/var/mobile/Library/Logs/DuoFaceSidePlayDisplayQA.log` và gửi tệp. **Chỉ giữ các dòng marker QA7/QA6 khi có thể**, không cần gửi vị trí/ứng dụng nhạy cảm.
4. Nếu không thấy marker QA7 dù Sileo hiển thị bản QA7: xác minh injection/loader/filter `{ Filter = { Bundles = ( "com.apple.springboard" ); }; }`, plist và payload đã cài. Nếu marker QA7 có nhưng UI chưa hiện: xem owner-check/frame và sửa chính điểm đó.
5. Nếu gây crash/exitMode: gỡ riêng `com.duoface.sideplaydisplay` bằng Sileo và respring. Giữ SidePlay và Native12/HUD8 nguyên trạng.

**Bước tiếp theo:** xử lý chính nguyên nhân từ log iPhone thay vì đoán thêm UIPill vị trí hoặc windowLevel; sau đó chuyển các class UI picker/Style và native bar owner đúng process với xác nhận frame; không công bố "DuoFace hoàn thiện" trước device PASS.
