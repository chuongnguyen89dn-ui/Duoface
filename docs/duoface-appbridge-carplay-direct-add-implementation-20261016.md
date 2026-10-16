# DuoFace — Chọn và thêm ứng dụng trực tiếp trên CarPlay (source 16/10/2026)

## Mục tiêu và quyết định UI

Người dùng đồng ý triển khai **thêm app mới trực tiếp trên màn CarPlay** qua ô `Thêm App / …` đang có trong menu DuoFace. **Không cần giữ một mục “chọn ứng dụng” riêng bắt buộc trên iPhone sau khi tính năng mới hoạt động tốt; nhưng trong giai đoạn triển khai phải giữ nguyên phần quản lý ứng dụng iPhone làm phương án dự phòng và hiển thị cùng một danh sách**, chỉ cân nhắc hạ cấp thành phần quản lý phụ sau khi có kiểm thử thiết bị xác nhận CarPlay add và sync. Không tạo thêm menu App/Zoom/Style/Close hoặc giữ hai kho dữ liệu tách biệt.

**Không build DEB, không đưa Sileo**. Đang phát triển `feature/duoface-exact-payload-migration`; source baseline `com.duoface.independent 0.1.0~native12`, SHA256 `85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7`, giữ nguyên. Xóa license PAUSED; music YouTube qua Android Display để sau.

## Đã xác minh đúng mã native12

- GitHub Actions `38845146288` SUCCESS, `38845399511` SUCCESS, `38845513118` SUCCESS. Script `migration/full_payload/native_test/audit_native12_carplay_add_app_chain.py`, workflow `.github/workflows/duoface-native12-carplay-add-app-chain-audit.yml`, output `feature:audit/payload-migration/NATIVE12_CARPLAY_ADD_APP_CHAIN_READONLY.json`, lần đọc mới nhất blob `098b1f5ef1d210ae6f7fa95f4122f3bea6019436` (phải kiểm blob/current sau khi update).
- `CBMultitaskingOverlayView.addMoreAppsTapped:` `v24@0:8@16` IMP `0xa7f20` thực sự hiển thị **chỉ hộp hướng dẫn iPhone**: literal `[DuoFaceSB] UI addMoreAppsTapped -> presenting custom frosted alert modal` và `ADD_MORE_APPS_ALERT_TITLE / MSG / OK`; không phải picker.
- `CBDashboardSettings.bridgedApps` IMP `0x37e88`: `ldr x0, [x0,#0x18]` (ivar); `setBridgedApps:` IMP `0x37e90`: `mov x1,x2; add x0,x0,#0x18; b _objc_storeStrong`. **Setter chỉ thay iVar, không ghi file**.
- `CBDashboardSettings.reloadAppPrefs` IMP `0x3681c` sử dụng `initWithContentsOfFile:` và `objectForKeyedSubscript:`; sau đó `writeToFile:atomically:` với cấu hình nền và `postNotificationName:object:userInfo:` (không quy tất cả ghi cho riêng key bridgedApps). `DuoFaceUI.CBGeneralSettingsViewController.savePreferences` IMP `0x10000da34` cũng sử dụng `dictionaryWithContentsOfFile:` và `writeToFile:atomically:`, không phải bằng chứng dùng CFPreferencesSetAppValue. `DuoFaceDashboard` nhúng literal `bridgedApps`, `com.duoface.duofaceui`; chưa có bằng chứng đường file chính xác từ static pointer globals, **không đoán tên domain**.

## Source đã thêm (staged, CHƯA CÀI)

- `feature:runtime/appbridge/DFInCarAppPicker.xm`, commit `754594f9cd74c75dd54f1fcf52c8863f0770031b`: Logos hook chính xác **một selector `addMoreAppsTapped:`** của `CBMultitaskingOverlayView`, process-filter chỉ SpringBoard. Các nút App/Zoom/Style/Close, xử lý split, ratio, native Close, menu hình/màu và app picker callback khác không đổi.
- Hook tự dựng danh sách `LSApplicationWorkspace.allInstalledApplications` qua API private khi có; chỉ lấy ứng dụng User đã cài, có bundleID hợp lệ, chưa thuộc danh sách `CBDashboardSettings.bridgedApps`, bỏ app hệ thống. Trình bày bảng scrollable trên chính overlay với nhãn `Thêm ứng dụng` và `Hủy`. Nếu workspace, owner settings, preferences path không đủ bằng chứng hoặc không có app, gọi `%orig` để giữ hộp hướng dẫn cũ; **không ghi guess**.
- Để tránh tạo kho dữ liệu mới, **không hardcode preferences domain**: quét có giới hạn thư mục `/var/mobile/Library/Preferences` cho plist đã có với tên dự án/di sản hợp lệ, key `bridgedApps` array khớp chính xác và **duy nhất** danh sách `CBDashboardSettings.bridgedApps` đang dùng. Nếu không tìm ra duy nhất, không cập nhật. Khi chọn app: re-read list tránh overwrite, append ID **không sắp xếp**, thay đúng key trong dictionary (giữ mọi key khác) bằng `writeToFile:atomically:YES`, gọi `CBDashboardSettings.reload` và xác nhận list mới thấy trong memory; nếu không thì **rollback file và state**. Sau đó gọi `CBBridgeManager.handleSettingsChanged` nếu có và chuyển về native `switchToAppPickerMode` để thấy app mới. Không dùng `setBridgedApps:` riêng vì không persist.
- **Ràng buộc giới hạn:** Vẫn chưa được thử trên iPhone/CarPlay; lúc runtime có thể không tìm thấy plist key/top-level hoặc class LSApplicationWorkspace, khi đó hiển thị cảnh báo gốc, không lặng lẽ tạo bản song song. Đồng thời chưa đo việc hot-refresh native Dashboard và cùng danh sách iPhone sau khi viết; phải QA trên thiết bị.

## Mốc compile/test/source

- `feature:Makefile.appbridge-stage`, commit `e1e854a93e3b558fdf9fa81272e5abbf9facdb87`: standalone rootless Theos target `DuoFaceInCarAddApps`, chỉ compile/link dylib, filter `SpringBoard`. `feature:DuoFaceInCarAddApps.plist` commit `985a1e0c3e63a12fea8b88d8c54746d4b94cfdca`.
- `feature:.github/workflows/duoface-in-car-add-app-compile-only.yml` commit `ec59974f72b1dcd0200e2315d097647861129abf`, GitHub Actions **`38845796658`** đang chạy lần đầu lúc ghi file. macos-15 clone Theos + sdk, `make clean all FINALPACKAGE=1`, check arch arm64, no `make package`, no Sileo. **Không được báo compile PASS trước khi GitHub trả SUCCESS**; nếu FAIL phải xem log sửa.
- Các file gốc ngoài scope `runtime/fullscreen/DFPickerZoomMenu.xm` và `runtime/connection/*` KHÔNG sửa. Mọi source/artifact duy trì feature branch, handoff main.
- Các bài test cần làm sau candidate DEB khi user cho phép: (1) CarPlay add app mới + hiển thị lập tức; (2) app iPhone thấy cùng danh sách; (3) reboot vẫn còn app; (4) repeat add không duplicate; (5) thiếu prefs không ghi sai; (6) ngoài CarPlay không phá iPhone Settings; (7) menu App/Zoom/Style/Close và Close vẫn hoạt động; (8) app chưa cài lại/ra khỏi iPhone được lọc.

## Tiếp tục ngay khi có kết quả CI

1. Xem GitHub Actions `38845796658`, lấy job log nếu lỗi; sửa source cho compiler/run lại đến khi PASS; checkpoint SHA/CI.
2. Kiểm chứng nguồn prefs thực trên một iPhone trước khi đổi bất kỳ nút Cài đặt iPhone; runtime fallback nguyên bản nếu chưa verify.
3. Chỉ cân nhắc ẩn mục chọn ứng dụng iPhone sau khi có test thật của phiên bản đóng DEB và được người dùng duyệt; hiện duy trì nguyên mục đó.

