# DuoFace native17 — giữ chính xác lõi giấy phép native12, khôi phục giao diện Cài đặt đã mất

**Ngày:** 16/10/2026. **Phạm vi:** DuoFace độc lập `com.duoface.independent`. Trạng thái: **BUILD + SILEO + PUBLIC DEB VERIFY SUCCESS**, **CHƯA QA TRÊN THIẾT BỊ**.

## Yêu cầu và bằng chứng thiết bị

Người dùng xác nhận ảnh ứng dụng đang cài là `0.1.0~native16`: hàng `DuoFace Pro` hiện `Chưa kích hoạt · Chạm để kích hoạt`, trong khi người dùng muốn trạng thái giấy phép đã chạy tốt từ **native12**, không khôi phục cơ chế kích hoạt bản đầu. Cài đặt `Đóng ứng dụng khi ngắt CarPlay` vẫn hiển thị chờ **10 giây**. Đây là ảnh minh họa **hàng UI hiện lại**, không chứng minh runtime đã trở lại yêu cầu kiểm tra giấy phép để vận hành.

Đối chiếu tài liệu/script/commit **bắt buộc**:
- `feature:dist/payload-migration/native12/BAO_CAO.json`, native12 DEB SHA256 `85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7`. `build_native12_without_lease_bridge.py` xóa **cả** thư viện `A_DuoFaceNativeNoLease.dylib`/plist mà vẫn giữ native12 binary intact.
- `feature:.github/workflows/duoface-native2-build.yml`: module cũ đó từng compile từ **hai file** `DuoFaceNoLeaseBridge.mm` **và** `DuoFaceNative2UICleanup.mm`. Phần sau từng ẩn hàng UI DuoFace Pro và được người dùng xác nhận trên iPhone native2. Vì thế khi loại hẳn mixed-purpose dylib khỏi native12, giao diện lọc giấy phép cũng không còn. Không ghép lại thư viện vì kèm hook giấy phép không mong muốn.
- `feature:dist/payload-migration/native15/BAO_CAO.json`, `build_native15_restore_license_classes.py`: native15 khôi phục 14 registration classes bị native14 xóa dựa trên chính binary **native12**, **không** khôi phục method license ban đầu. `native16/BAO_CAO.json`: binary host giữ nguyên SHA của native12, chỉ hai file App picker thay so native15.

## Mã nguồn và bảo vệ hồi quy

Nhánh `feature/duoface-exact-payload-migration`:
- `runtime/settings/DFSettingsUIRestore.mm` commit `17194b0cc6e5093996f5462e2098974d50335510`: swizzle **chỉ 3 callbacks trình bày table** của `CBGeneralSettingsViewController` trên chính app DuoFaceUI, lọc nhóm từ khóa đã chạy ở native2 và ánh xạ lại index tới callbacks hiện có. KHÔNG chạm lớp xác thực/activation/watchdog, KHÔNG thay điều khiển CarPlay; giữ đường fallback khi thiếu class/cell.
- `runtime/settings/DuoFaceSettingsUIRestore.plist` commit `6bf329aff65fafbed3a5f33b7f75576e5288331c`, filter duy nhất DuoFaceUI/Bundle `com.duoface.duofaceui`.
- `migration/full_payload/native_test/build_native17_settings_ui_parity.py` commit `9f64a9f2a3064238697d58693bd962b7fafb712b`, từ exact native16 chỉ thêm `DuoFaceSettingsUIRestore.dylib`/plist, **43 original payload entries byte-identical**. Assert missing prior `A_DuoFaceNativeNoLease`.
- `tests/test_native17_settings_ui_parity.py` commit `b7101cecc33693af83019594fffceb7f8514dc16`, kiểm invariant và không xuất hiện license hooks.
- `.github/workflows/duoface-native17-settings-ui-parity.yml` commit `b7881cc35390ff0c3088a52e039a182803d60f65`.

**GitHub Actions build:** [38855354003](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/38855354003) job `116825460632` completed/success. Compile/link/sign iOS arm64, unittest, package, kiểm diff + sha, commit artifact và upload proof (artifact ID `12026463750`).

**GitHub DEB build artifact thật:** feature branch commit `68ea8e776f7a1629b5945f35fa7dc17797941600`:
- `dist/payload-migration/native17/com.duoface.independent_0.1.0~native17_iphoneos-arm64.deb`
- `dist/payload-migration/native17/BAO_CAO.json`, blob `ae9a7752223275a243ba96d058e578cf40127d5b`
- 1,750,812 bytes, SHA256 **`60f8a4277dd9df912036f93fc8edfd0897a516752f3014863459d5ce89ad5fff`**.
- Host native12: DuoFaceUI `cb40346d8ca504cb399abe31367847b4f980a01ba93810986ce1acf1fbe9eef9`, Dashboard `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`.
- SmartConnection 10s `0986cf70b4c613ad011520204337e1e2b403d24111f39f14f70628fb57e61d50`; AddApps v16 `d0246415f4020f353e5ec7373d8d375cbbda868471fd1a467f8e57654c4d01ad`. Các file đó nguyên byte.

## Phát hành Sileo đã xác nhận và QA công khai

- Distribution repo `chuongnguyen89dn-ui/carplaydsp/main` chỉ sửa block `com.duoface.independent` workflow `.github/workflows/build.yml`, commit **`5d07ff245b52a105d6a574fc70f23a33d55a6046`**, pin GitHub binary+report SHA, không sửa các gói khác.
- Publisher run **[38855615436](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/38855615436)** **completed/success**: build job `116826281662` và Pages deploy job `116826810979` đều success.
- Independent public verifier `feature:.github/workflows/duoface-native17-sileo-public-verify.yml`, commit `8e91d51ccca207a8d8f08967d69c09eeb9455a16`, run **[38855666187](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/38855666187)** **completed/success**, verify job `116826439792`, artifact `12027306301`. Từ public Pages: `Packages` trùng `Packages.gz`, đúng một `com.duoface.independent 0.1.0~native17`, vẫn có `com.duonavi.app`; tải public DEB exact SHA rồi `dpkg-deb -x` và kiểm 5 file host/UI/settings/Smart/AddApps theo SHA.
- Source Sileo: https://chuongnguyen89dn-ui.github.io/carplaydsp/
- DEB trực tiếp: https://chuongnguyen89dn-ui.github.io/carplaydsp/debs/com.duoface.independent_0.1.0~native17_iphoneos-arm64.deb

## Test thiết bị cần thực hiện và giới hạn

1. Sileo làm mới nguồn `carplaydsp` và update `com.duoface.independent` từ native16 lên **native17**.
2. Mở DuoFace iPhone vào **Cài đặt**: xác nhận hàng `DuoFace Pro` cùng thông báo `Chưa kích hoạt` đã biến mất; `Trạng Thái CarPlay`, `DuoFace Team`, công tắc **Đóng ứng dụng khi ngắt CarPlay: 10 giây**, các row còn lại đều có mặt và dùng bình thường.
3. Xác nhận app vẫn mở, các tính năng native12 CarPlay/split/Zoom/Style/Close, SmartConnection ngắt 10s và AddApps CarPlay không hồi quy.
4. Nếu hàng UI vẫn còn, lấy ảnh: có thể do injection/swizzle/ABI/section layout; **không kết luận license core hỏng**. Nếu lỗi app, rollback native16 (SHA `5d5cbd368c24d0c074b081d16aaf7d006467c3e9cfef01ee12378ce79d716fae`) hoặc native12 (SHA ở trên) từ file trong GitHub; không chạy/chỉnh tweak Dopamine.
5. Chưa có on-device QA native17. Không tuyên bố module UI đã ẩn được hàng trên máy cho đến khi người dùng thử. Cũng không tuyên bố mọi bytes lớp giấy phép đã bị xóa; giữ metadata/methods cần thiết để chạy như native12.
