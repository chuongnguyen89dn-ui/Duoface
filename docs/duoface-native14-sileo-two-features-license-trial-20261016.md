# DuoFace native14 — 2 tính năng + xóa lớp giấy phép thực — phát hành Sileo THỬ NGHIỆM

**Thời điểm xác minh:** 16/10/2026 ~11:03 ICT (GitHub Actions logs 04:02 UTC). **Trạng thái:** GitHub Actions build/Pages + download QA **SUCCESS**; **CHƯA thử trên iPhone, KHÔNG khẳng định không lỗi**.

## Yêu cầu đã giao / phạm vi

User: “Kiểm tra đi. Nếu hoàn thành thì build deb ở lượt này lên sileo để test luôn 2 mục mới. Bao gồm trước đó cần xoá giấy phép j đó nx.”

Đã thực hiện tạo 2 tầng candidate, phát hành bản **`com.duoface.independent 0.1.0~native14`** trên nguồn Sileo (user test). Chỉ thay **gói independent DuoFace**, không sửa DuoDash, Airaw, carplaydsp apps khác hoặc gói legacy `com.duonavi.app`. Native12 và native10 immutable backup. Cần hiểu **14 lớp cô lập đã được gỡ đăng ký và xóa tên vật lý**, nhưng vẫn còn metadata phương thức và một số literal dùng chung; **không được nói đã xóa 100% dấu vết**.

## Nội dung chính xác của bản native14

**Tính năng 1 — Kết nối thông minh (nhóm 1):** Giữ một công tắc `Tự động mở` gốc; source `feature:runtime/connection/DFConnectionNativeHooks.xm`, `DFConnectionAdapter.mm`, `DFConnectionPolicy.cpp` tích hợp nhớ app cuối DuoFace quản lý/chống mở trùng qua native `performAutoResume`. Bổ sung một công tắc `Đóng ứng dụng khi ngắt CarPlay` trên iPhone `CBGeneralSettingsViewController`, OFF mặc định, khi ON chờ **10.000 ms** và hủy khi reconnect, chỉ close owned+running. Hai methods `scheduleMandatoryDisconnectWatchdog`/`enforceMandatoryDisconnectKill` được guard khi ON, giữ native original khi OFF. Đã CI pure C++ 11 kịch bản và arm64 Theos PASS, nhưng chưa kiểm runtime.

**Tính năng 2 — Thêm App trên CarPlay (nhóm 2):** `feature:runtime/appbridge/DFInCarAppPicker.xm`, hook đúng ô `CBMultitaskingOverlayView.addMoreAppsTapped:` (mã native12 gốc chỉ báo “điện thoại”), enumerate installed user apps, hiện bảng chọn, kiểm đúng một plist preferences chứa `bridgedApps` khớp trạng thái thật, cập nhật atomically, reload và rollback nếu không thấy list mới. Fail-open trở về alert cũ nếu không xác định được path/user apps, không ghi đè danh sách giả. **Bộ chọn ứng dụng iPhone vẫn giữ nguyên** để dự phòng, UI App/Zoom/Style/Close không bị thay hình thức. Compile Theos PASS run `38846229342`.

**Xóa giấy phép thật (thử nghiệm):** Native12 đã xóa 52 chuỗi nội dung license trong native11 và 2 file hook license riêng trong native12; bản native14 tiếp tục gỡ **14 class registrations** (12 DuoFaceUI + 2 DuoFaceDashboard), null **42 con trỏ** trong `__objc_classlist/__objc_classrefs/__objc_superrefs`, xóa **47 bản sao tên lớp** sau khi xác minh exact string, ký lại nhị phân, giữ toàn bộ code `__text` CarPlay. 3 ARM64 static xrefs đến 2 lớp thuộc duy nhất `XXRootViewController.checkAndPresentLicenseModalIfNeeded` — phương thức entry đã được vô hiệu hóa từ native4. **Phần còn lại**: 249 method metadata records từ các class không đăng ký, một số strings/keys/protocol (khoảng 126 string records theo bảng gốc, con số có thể giảm với name wiping); 8 hàm CarPlay trong shared `CBLicenseSyncManager` được giữ. **KHÔNG xóa mù protocol `CBSubscriptionCheckoutCellDelegate` và type encodings**. Đây là **thử nghiệm trên máy**, chưa chứng minh 100% loại bỏ logic/dấu vết hay runtime safety.

## Bản dựng, commit và SHA256 — đã kiểm chứng

| Hạng mục | Nơi / ID | Kết quả |
|---|---|---|
| Native12 baseline | `dist/payload-migration/native12/com.duoface.independent_0.1.0~native12_iphoneos-arm64.deb` | SHA `85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7`, đã user test |
| Native13 2 module | `feature:dist/payload-migration/native13/*.deb` | SHA `cff76573be10a73bfd423e988b803812e3375af4db6567a9229c1b04156f2cf3`; Actions `38847147300` SUCCESS; không publish |
| Native14 2 module + class removal | `feature:dist/payload-migration/native14/com.duoface.independent_0.1.0~native14_iphoneos-arm64.deb` | SHA **`f29cc6bc99950714e0f51785b97744575667b22fa3df1bcc727d09d938f78f10`**, feature commit `f1b31a6eeda585450d4e118911b3c56b2cb72a17` |
| Native14 physical removal report | `feature:dist/payload-migration/native14/BAO_CAO.json` | blob `e0c55a04f5b9a828341859fd95e25567a2da89ca`; `38848132130` SUCCESS |
| Sileo repo publisher source commit | `carplaydsp/main:.github/workflows/build.yml` | `e7752eaa396f96735d8ca440a15113f281672f69`; ONLY independent block pinned native14 commit+SHA |
| Build + GitHub Pages deployment | `https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/38848303901` | **completed/success**, build job `116803706305`, deploy job `116804343397` both SUCCESS |
| Independent public verifier | `https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/38848380985` | **completed/success**, job `116803928812`; log `APT_NATIVE14_METADATA_AND_LEGACY_PACKAGE_PRESERVED_PASS` và `PUBLIC_SILEO_NATIVE14_EXACT_SHA_TEST_ARTIFACT_VERIFIED_NOT_DEVICE_TESTED` |

**Nguồn Sileo:** `https://chuongnguyen89dn-ui.github.io/carplaydsp/`

**DEB trực tiếp đã kiểm sha trên Pages:** `https://chuongnguyen89dn-ui.github.io/carplaydsp/debs/com.duoface.independent_0.1.0~native14_iphoneos-arm64.deb`

**Rollback native12 pinned raw:** `https://raw.githubusercontent.com/chuongnguyen89dn-ui/Duoface/f08b6f4a7be0bc3a38cce1b0c9b52f8179841064/dist/payload-migration/native12/com.duoface.independent_0.1.0~native12_iphoneos-arm64.deb`

**Đường dẫn scripts/workflows thực sự chạy:** `feature:migration/full_payload/native_test/build_native13_features_candidate.py`; `feature:.github/workflows/duoface-native13-dual-feature-candidate.yml`; `feature:migration/full_payload/native_test/build_native14_license_class_trial.py`; `feature:.github/workflows/duoface-native14-license-class-trial.yml`; `feature:.github/workflows/duoface-native14-sileo-public-verify.yml`. Runtime source `feature:runtime/connection/*` và `feature:runtime/appbridge/DFInCarAppPicker.xm`. Không có file thủ công tạm nào được tính là đã lưu bền.

## QA trên iPhone cần người dùng thực hiện — ưu tiên an toàn

1. **Cài thử chỉ khi xe đỗ**, khởi động app DuoFace từ iPhone và kết nối CarPlay. Nếu app crash/không thấy CarPlay, **quay về native12 ngay** theo link pinned; báo triệu chứng trước khi tiếp tục.
2. Cài đặt DuoFace trên iPhone: công tắc Auto Start cũ giữ nguyên; công tắc mới `Đóng ứng dụng khi ngắt CarPlay` phải có nhãn và bật/tắt lưu được. Thử Auto Start ON bằng app A, chuyển app B, ngắt/kết nối lại xem restore B **một lần**, không mở trùng.
3. Thử đóng khi ngắt CarPlay ON: ngắt 5 giây rồi reconnect → không đóng, ngắt 10+ giây → chỉ app do DuoFace mở bị đóng. OFF → giữ legacy behavior. Đừng dùng những app có dữ liệu đang soạn chưa lưu.
4. Trên CarPlay, mở menu App nhấn ô **Thêm App/…**. Phải hiện danh sách ứng dụng iPhone chưa có; chọn một app rồi kiểm xuất hiện trên màn xe và app DuoFace iPhone, không mất các app đã chọn.
5. Kiểm hồi quy menu App/Zoom/Style/Close, logo, màu, fullscreen, âm thanh, hoạt động iPhone app. Dừng ngay nếu lỗi để tránh gián đoạn điều khiển/điều hướng.

**Pending:** User's device PASS/FAIL; all leftover shared license metadata/strings not fully physically deleted. No background job implied; run verification has finished and handoff must be updated after user feedback.
