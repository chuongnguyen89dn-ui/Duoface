# DuoFace native15 — khôi phục 14 lớp đăng ký giấy phép, giữ hai tính năng

## Xác minh ĐÃ XUẤT BẢN SILEO + PUBLIC SHA (16/10/2026)

- **PUBLISH SUCCESS:** Repo `chuongnguyen89dn-ui/carplaydsp`, commit `8dee4d47fff4f4e7805abf5e1062802c8a46f438`, GitHub Actions run **`38850434530` completed/success** (build job **`116810222179` SUCCESS**, deploy GitHub Pages job **`116810718567` SUCCESS**). Deploy log có `Reported success!`. Publisher log `NATIVE15_RESTORE_CLASSES_PUBLISH_GATE_PASS`, checksum `repo/debs/com.duoface.independent_0.1.0~native15_iphoneos-arm64.deb: OK`, APT Packages 10 entries, verified two modules in package and report with 14 restored classes; other packages untouched.
- **INDEPENDENT PUBLIC WEB PROOF SUCCESS:** DuoFace feature workflow `.github/workflows/duoface-native15-sileo-public-verify.yml` commit `f19b5b1cc74a943c5adeed47e1ed1f5a489d9ef1`, GitHub Actions run **`38850552356` completed/success**, verification job **`116810579983`**. Live fetch from GitHub Pages at `https://chuongnguyen89dn-ui.github.io/carplaydsp` passed: `Packages` exact `Packages.gz`, **exactly 1 `com.duoface.independent` entry version `0.1.0~native15`**, **1 legacy `com.duonavi.app` preserved**, APT SHA256 **`8d111e638dce357dfb1187c5b10fdf776d7485c95198ad4cf248d6b51d1740e3`**, direct downloaded DEB `native15.deb: OK`, Package/Version matches, required six dylibs including both SmartConnection and InCarAddApps found, old NoLease absent. Run log markers `APT_NATIVE15_METADATA_AND_LEGACY_PACKAGE_PRESERVED_PASS` and `PUBLIC_SILEO_NATIVE15_EXACT_SHA_TEST_ARTIFACT_VERIFIED_NOT_DEVICE_TESTED`. Archived verification artifact ID **`12025116430`**.
- **User delivery:** Sileo Source `https://chuongnguyen89dn-ui.github.io/carplaydsp/`, DEB direct `https://chuongnguyen89dn-ui.github.io/carplaydsp/debs/com.duoface.independent_0.1.0~native15_iphoneos-arm64.deb`. Device-install/launch is **NOT TESTED**. Ask user to open Sileo, refresh repo, install **DuoFace 0.1.0~native15**, and FIRST report whether app opens. Only after that test two new features; if still fails immediately rollback known working native12 and obtain crash log.
- **Scope truth:** This restores **14 registration classes removed only in native14** and retains 2 features. **Older native12 neutralized license-method bodies (312 catalogued) remain neutralized**; full original license system not restored. Further destructive license work forbidden while testing recovery.

**2026-10-16, cứu ứng dụng không mở được sau native14; trạng thái lúc ghi: DEB build PASS, Sileo publish job 38850434530 đã khởi động, CHỜ xác minh Pages/thiết bị.**

## Yêu cầu người dùng và nguyên nhân nghi ngờ

Người dùng xác nhận **native14 cài qua Sileo khiến DuoFace không mở được**, yêu cầu **khôi phục phần giấy phép đã xóa**, **giữ cả 2 chức năng Cài đặt** (Smart Connection và Thêm App trực tiếp trong CarPlay) và **build lại DEB lên Sileo**. Không có crash log iPhone; lần đầu mất mở trùng thời gian với việc xóa vật lý 14 class, nhưng CHƯA chứng minh đây là nguyên nhân duy nhất. Các bước kiểm chứng native14 trước đây chỉ là static/CI, không phải device test.

- Bản Sileo hỏng: `com.duoface.independent 0.1.0~native14`, SHA256 `f29cc6bc99950714e0f51785b97744575667b22fa3df1bcc727d09d938f78f10`, publisher commit `e7752eaa396f96735d8ca440a15113f281672f69`, run `38848303901` SUCCESS.
- Nguyên thay đổi nguy hiểm mới của native14: **14 ObjC class registrations (UI 12, Dashboard 2)**, 42 registration/ref pointers, 47 class name literals đã bị ghi 0, hai host đã được ký lại; runtime an toàn không kiểm chứng. `feature:dist/payload-migration/native14/BAO_CAO.json` blob `e0c55a04f5b9a828341859fd95e25567a2da89ca`.
- Bản **native13 (chưa từng thử trên iPhone)** chứa 2 dylib+plist và các host **byte-identical với native12**; SHA256 `cff76573be10a73bfd423e988b803812e3375af4db6567a9229c1b04156f2cf3`, `feature:dist/payload-migration/native13/BAO_CAO.json` blob `42f76b0ee37313ae2846e4c63735ecb46ec46e49`.
- Bản **native12 từng hoạt động trên máy**: SHA256 `85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7`. **Giữ được rollback**. Bản native12 đã có license-related methods stub/neutralized từ các bản native4..native11; đó là trạng thái user từng báo chạy tốt, nên phiên cứu hộ native15 **chỉ undo xóa metadata 14 lớp thử tại native14**, KHÔNG phục hồi 312 method body thuộc các lần neutralization trước. Không nói full license restoration; nếu vẫn không mở được thì cần on-device logs và thử native12.

## Mã, lệnh và kết quả xác thực

- Repo work: `chuongnguyen89dn-ui/Duoface`; branch `feature/duoface-exact-payload-migration`.
- Script `migration/full_payload/native_test/build_native15_restore_license_classes.py`, commit `997785708d85f434ef4c28f4182b54ad98eb2046`.
- Workflow `.github/workflows/duoface-native15-restore-license-classes.yml`, commit `89127be0332c13b0e2327edec7a6ca58051b2caa`.
- GitHub Actions build `38850321097` completed **SUCCESS**, job `116809879401`. Lệnh thực thi tại root repo trên macos-15: `python3 migration/full_payload/native_test/build_native15_restore_license_classes.py --out dist/payload-migration/native15/com.duoface.independent_0.1.0~native15_iphoneos-arm64.deb --report dist/payload-migration/native15/BAO_CAO.json`; `dpkg-deb -R` native13, `dpkg-deb -x` native12, `dpkg-deb --build --root-owner-group`, xác minh sha256 và package metadata. Artifact + report đã `git push` vào feature.
- Artifact exact `dist/payload-migration/native15/com.duoface.independent_0.1.0~native15_iphoneos-arm64.deb`; SHA256 **`8d111e638dce357dfb1187c5b10fdf776d7485c95198ad4cf248d6b51d1740e3`**.
- Report `feature:dist/payload-migration/native15/BAO_CAO.json` blob **`8d30f3f81c7faf4986cb93b3a1bb23b5ad638459`**, current source commit **`e8a54f643939cb435394720ecb7ba3aa1ae56707`**. Parse/readback PASS: registered UI 27 classes / Dashboard 36; 14 named classes restored; **original native12 host binaries, and all native13 payload file contents byte-identical**. Two dylibs included and retained signed hashes:
  - `DuoFaceSmartConnection.dylib` SHA256 `0986cf70b4c613ad011520204337e1e2b403d24111f39f14f70628fb57e61d50`.
  - `DuoFaceInCarAddApps.dylib` SHA256 `d07fbbd3b7caa075e82ec066ca2ad51d0d0cb7126e792b7a1cf19e8435671c68`.
  - A_DuoFaceNativeNoLease vẫn không có (đã bị bỏ trước native12).
- Publisher repo `chuongnguyen89dn-ui/carplaydsp/main`: modified only independent DuoFace stanza in `.github/workflows/build.yml`, commit **`8dee4d47fff4f4e7805abf5e1062802c8a46f438`**, pinned source DEB from exact commit `e8a54f643939cb435394720ecb7ba3aa1ae56707`, exact SHA256, 2 dylib checks, report class-count+provenance checks; deletes previous independent package versions *only*; all other Sileo packages kept. **GitHub Actions publisher run `38850434530`** at `https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/38850434530` queued/in-progress at time of initial report. Not yet safe to say Pages fully published until both jobs SUCCESS.
- Target Sileo source: `https://chuongnguyen89dn-ui.github.io/carplaydsp/`; expected after successful deploy `https://chuongnguyen89dn-ui.github.io/carplaydsp/debs/com.duoface.independent_0.1.0~native15_iphoneos-arm64.deb`.

## Tiếp theo và tiêu chí

1. Check `carplaydsp/actions/runs/38850434530` **build + deploy Pages** success; nếu failed, đọc exact job logs rồi fix đúng lỗi.
2. Independent read-only public `Packages`, `Packages.gz`, DEB sha256 and required 2 modules + **only 1 independent entry native15**; use/persist report to DuoFace.
3. Handoff prepend exact run IDs, commits and proof; đọc lại SHA.
4. User needs **iPhone installation test**. Start app DuoFace; nếu mở được thì test 2 functionalities, reopen after respring/reconnect, 10s close. Nếu vẫn không mở được, **stop experiments with license classes**; ask for crash log and roll back native12 known-working. No automatic background device QA.
