# DuoFace Mới: native10 — thử nghiệm thực tế và quay lại native9

Ngày: 15/10/2026 (giờ Việt Nam). Chủ sở hữu yêu cầu kiểm tra thực tế thay vì chỉ suy đoán. Đây là bản thử nghiệm có nguy cơ CarPlay hoặc ứng dụng không khởi động; **không báo thiết bị PASS trước khi chủ sở hữu xác nhận**.

## Hai gói độc lập, KHÔNG ghi đè lịch sử

| Thành phần | Phiên bản thử | Phiên bản tốt đã test |
|---|---|---|
| Package ID | `com.duoface.independent` | `com.duoface.independent` |
| Version | `0.1.0~native10` | `0.1.0~native9` |
| Architecture | `iphoneos-arm64` rootless | `iphoneos-arm64` rootless |
| SHA256 DEB | `3d39b181d0089ae9a7797eb1ca05790155d1b242e50ca2cff362e0a818ff8d29` | `e4e1122a494d32af6ec42c97c4288f6effb6716fbb81cb52b81b746280d4d97e` |
| Immutable commit | `b66e436fa06e85dc188c650fa9597336475997ff` | `328d123ae4ae13a56bb75a9916d22be1e2c85f3f` |
| Repo path | `dist/payload-migration/native10/com.duoface.independent_0.1.0~native10_iphoneos-arm64.deb` | `dist/payload-migration/native9/com.duoface.independent_0.1.0~native9_iphoneos-arm64.deb` |

- Source/reports: `migration/full_payload/native_test/build_native10_lifecycle_trial.py`, `verify_native10_lifecycle_trial.py`, `dist/payload-migration/native10/BAO_CAO.json`, `audit/payload-migration/NATIVE10_19_LIFECYCLE_TRIAL_REGRESSION.json`.
- Build workflow: https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/38757634916 (successful).
- New package preserves the original 8 CarPlay method bodies byte-by-byte and all resources, visual controls, split/drag code; 19 Objective-C lifecycle method bodies changed, 15 in UI and 4 in Dashboard.
- Important: return-shape and code hash tests do **not** guarantee runtime. Modified singleton and init may cause CarPlay boot failure, lifecycle cleanup may leak retain references.

## Cài bản thử nếu Sileo Pages/public QA xác nhận

Nguồn Sileo: `https://chuongnguyen89dn-ui.github.io/carplaydsp/`

1. Mở Sileo → Sources → làm mới nguồn CarPlayDSP → DuoFace → Upgrade lên **0.1.0~native10**.
2. Test app iPhone mở được, kết nối CarPlay, màn hình hai ô, đổi tỷ lệ bằng kéo đường chia ngoài logo, giữ logo 0,3 giây rồi kéo lên/xuống, tap logo để hoán đổi hai ứng dụng, nút YouTube fullscreen tròn, menu Zoom/Style/Close, reconnect và không che nội dung.
3. Nếu vẫn tốt, xác nhận bằng tin nhắn; nếu thất bại, nêu lỗi cụ thể để khôi phục ngay **native9**.

## Quay lại native9 (dự phòng)

Đường tải version tốt đã user test từ commit cố định:

`https://raw.githubusercontent.com/chuongnguyen89dn-ui/Duoface/328d123ae4ae13a56bb75a9916d22be1e2c85f3f/dist/payload-migration/native9/com.duoface.independent_0.1.0~native9_iphoneos-arm64.deb`

Nếu Sileo còn dùng được, mở bản DEB native9 đã tải và chọn cài lại phiên bản thấp hơn. Một số trình quản lý gói có thể yêu cầu xác nhận **downgrade**. Không dùng package ID khác để cài song song, vì hai phiên bản sở hữu cùng tệp.

Nếu chỉ cần dùng terminal trên iPhone jailbreak, tải DEB về thiết bị rồi chạy `sudo dpkg -i /đường/dẫn/đến/native9.deb` (dùng đúng tên tệp và đường dẫn đã tải), sau đó respring theo hướng dẫn của jailbreak; kiểm tra `dpkg-query -W com.duoface.independent`. **Không chạy lệnh nếu không có file tương ứng hoặc không hiểu quyền rootless.**

Nếu lỗi nặng khiến Sileo không mở, khởi động môi trường jailbreak ở chế độ an toàn hoặc vô hiệu tweak theo hướng dẫn jailbreak đang dùng, rồi gỡ/cài lại bản native9. Việc Sileo update thành công không chứng minh thao tác trên xe ổn.

## Status

- CI native10 build, byte-diff, 8 CarPlay guard và SHA: PASS.
- GitHub Pages/native10 Sileo: phải kiểm tra riêng, không suy diễn từ CI.
- Real-device native10: **CHƯA kiểm**.
- Original native9: không overwrite/xóa, user đã xác nhận tất cả thao tác OK.
