# Kết quả sao chép nguyên bộ DuoFace đã duyệt — 15/10/2026

## Đã thực hiện thật

Đây **không phải bản DuoFace mới được viết lại từ đầu**. Nguồn duy nhất là DEB chính thức đã duyệt của repo này:

- `dist/candidates/menu-native1/com.duonavi.app_1.0.3-12_menu-native1_iphoneos-arm64.deb`
- SHA256: `ce971b42230d355421b2b1d99793a1f62ffb75008365ea74a3467d859cc1de3a`.
- Lệnh CI: `dpkg-deb --raw-extract`, kiểm nguyên byte bằng SHA256 của **từng** file và mode trước/sau, không thay code nhị phân, không viết lại UI, không thay package ID.
- Tổng cộng **41 tệp**, sau xử lý còn **40 tệp y nguyên**. File duy nhất được bỏ khỏi bản sao: `var/mobile/Library/Preferences/com.duonavi.sync.plist` (dữ liệu trạng thái hạn dùng). Không xóa thêm thành phần khác.
- Bản sao không chỉnh sửa chức năng chia màn hình, giao diện menu gốc, biểu tượng, các helper, `DuoFaceUI`, `DuoFaceDashboard.dylib`, `DuoFaceFullscreenBridge.dylib`, `DuoFaceVisualHook.dylib`.
- Đã xác minh ZIP kỹ năng `Gpt-training-/skills/02-ios-deb-ipa-carplay.zip` (SHA256 `c87b5ed9ef196c13f42dd41df49a032369028742cc8f6d56569637daf76ec7cf`) và đọc `SKILL.md` trong workflow.

### Bằng chứng và đường dẫn tải lại

- `dist/payload-migration/duoface-exact-payload-STAGING-NOT-INDEPENDENT.tar.gz` — bản lưu đầy đủ 40 tệp (**không phải DEB cài đặt**).
- SHA256 TAR tại lần khôi phục đã kiểm: `2ab178abaf8223ddd8bb803c75ff0cd1b44b384fc99bd4cc5f887fa55ab3f9abff`.
- `dist/payload-migration/EXACT_COPY_AUDIT.json`: tất cả đường dẫn, kích thước, mode, SHA256 và bằng chứng file loại trừ.
- `audit/payload-migration/ARCHIVE_RESTORE_AUDIT.json`: đọc **trực tiếp TAR**, khôi phục và so khớp **61 mục filesystem**, **40 tệp**; không bỏ sót một byte hay khác quyền file so với manifest.
- `audit/payload-migration/LICENSE_BOUNDARY_AUDIT.json`: metadata Objective-C và phương thức của lõi gốc, dùng lại parser `scripts/v12_host_recovery.py` của dự án.
- Workflow nguyên byte: `.github/workflows/duoface-exact-payload-audit.yml`, run **38698678753** — thành công.
- Workflow kiểm tra từng class: `.github/workflows/duoface-license-boundary-audit.yml`, run **38699336589** — thành công; có phiên bản hiệu chỉnh để tránh nhầm `watchdog` ngắt kết nối với cấp phép.
- Workflow khôi phục: `.github/workflows/duoface-staging-restore-test.yml`, run **38699821782** — thành công. Run **38699683930** thất bại do `tar | head` gây SIGPIPE trong `pipefail`, đã sửa bằng ghi list ra tệp rồi đọc 8 dòng; **không liên quan mã DuoFace**.

## Vấn đề đã xác định chính xác — KHÔNG được bỏ qua

**Không tồn tại một tệp `license.dylib` tách riêng để chỉ cần bỏ một tệp rồi giữ hai lõi chạy y nguyên.** Hai nhị phân chính vừa chứa chức năng ứng dụng vừa chứa code xác thực:

| Tệp nhị phân gốc | Công năng cần giữ | Bằng chứng tồn tại cấp phép |
| --- | --- | --- |
| `DuoFaceUI.app/DuoFaceUI` (2.456.784 byte) | Giao diện ứng dụng và logic kết nối | Các selector `isLicenseCurrentlyValid`, `remainingLicenseSeconds`, `installAndVerifyLicensePayload:errorMsg:`, `/api/v1/license/sync` |
| `DuoFaceDashboard.dylib` (7.540.464 byte) | Chia màn hình, picker, quản lý scene, bridge | Ngoài selector trên còn `licenseWatchdogTimerFired:`, `LICENSE_KILL_TRACE`, `CBLicenseSyncManager` cùng các method cấp phép |
| `DuoFaceFullscreenBridge.dylib` (124.976 byte) | Các hàm fullscreen do dự án phát triển | Không có **các chuỗi kiểm tra giấy phép đã quét**. Điều này **không** chứng minh dylib hoạt động nếu thiếu `CBBridgeManager` từ Dashboard. |
| `DuoFaceVisualHook.dylib` (75.536 byte) | Biểu tượng, viền, picker hooks | Không có **các chuỗi kiểm tra giấy phép đã quét**; vẫn phụ thuộc các lớp host/picker trong Dashboard. |

**Đã xác minh từ metadata Objective-C thực của Dashboard:** 757 method trên 36 lớp. `CBBridgeManager` vừa có `switchToSplitWithLeft:right:ratio:`, `showAppPickerForSlot:` và `sendStateToApp:shouldBridge:`, vừa có `startLicenseWatchdogTimer`, `stopLicenseWatchdogTimer`, `licenseWatchdogTimerFired:` và các method cảnh báo giấy phép. `CBLicenseSyncManager` là class cấp phép nhưng nằm **bên trong cùng DLL**, không phải file riêng có thể xóa. Các tên `scheduleMandatoryDisconnectWatchdog` hoặc `requestActivation:` không đủ cơ sở để gọi là logic cấp phép — không được phân loại nhầm.

Vì vậy, bản staging **chưa độc lập với DuoNavi** dù đã bỏ plist trạng thái. Muốn có sản phẩm không cần DuoNavi mà giữ đủ 100%, phải xác định biên tương tác và nguồn/quyền sử dụng của lõi trước khi lựa chọn cách triển khai. **Không nói đã loại được giấy phép, không phát hành trên Sileo, không cho người dùng cài TAR này.** Không tự ý vá/giả mạo giấy phép bằng binary patch để che lỗi.

## Cách tái lập có thể kiểm tra

Tại root repository, Linux runner có `dpkg-deb`:

```bash
python3 migration/full_payload/test_exact_copy.py
python3 migration/full_payload/prepare_exact_copy.py \
  --deb dist/candidates/menu-native1/com.duonavi.app_1.0.3-12_menu-native1_iphoneos-arm64.deb \
  --stage /tmp/duoface-exact-stage \
  --report /tmp/duoface-exact-audit.json
sha256sum -c dist/payload-migration/SHA256SUMS.txt
python3 migration/full_payload/verify_archive.py \
  --archive dist/payload-migration/duoface-exact-payload-STAGING-NOT-INDEPENDENT.tar.gz \
  --report dist/payload-migration/EXACT_COPY_AUDIT.json \
  --expected-sha256 2ab178abaf8223ddd8bb803c75ff0cd1b44b384fc99bd4cc5f887fa55ab3f9abff
```

Để đọc trực tiếp metadata nhị phân cần `capstone==5.0.7` và `python3 migration/full_payload/audit_license_boundary.py --dashboard /path/to/DuoFaceDashboard.dylib --report /tmp/license-boundary.json`.

## Điểm tiếp nối đúng

1. Dừng việc tái dựng từng nút của `independent/engine`; giữ bản Sileo alpha2 làm chứng cứ sai UI, không gỡ/sửa bản cũ.
2. Theo dấu **đường gọi cụ thể** giữa `CBBridgeManager`, `CBLicenseSyncManager` và các phương thức khởi tạo/điều khiển chia màn hình, đánh dấu mức chắc chắn; không suy từ selector thành công năng.
3. **Không biến bản staging thành DEB “không cần giấy phép” bằng cách đổi Package ID hoặc chỉ xóa plist.** Lựa chọn thay thế cần giữ 40 file nguyên byte trong nghiên cứu, nhưng phải bảo đảm các binary còn dùng lại không đòi hệ thống cấp phép gốc.
4. Khi có bằng chứng lõi thực sự độc lập và quyền phân phối phù hợp, mới chuẩn bị package `com.duoface.independent`, tăng version, chạy kiểm chứng Sileo và test CarPlay trên iPhone. Yêu cầu giữ nguyên UI và chức năng 100% không đổi.
