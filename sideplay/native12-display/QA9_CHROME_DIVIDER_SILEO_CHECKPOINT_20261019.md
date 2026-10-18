# QA9 — CarPlay chrome recovery + split geometry: code, CI, Sileo release checkpoint

**Checkpoint ngày:** 2026-10-19 (Asia/Bangkok). **Baseline theo user:** QA7 `0.1.5~native12visual7`, UI khá đồng bộ nhưng không có thanh bar CarPlay; SidePlay gốc 1.0.4-1 vẫn host app. Native12+HUD8 độc lập phải giữ nguyên.

## Chính xác đã sửa ở QA9 (từ QA7, không nâng theo QA8)

- Branch `feature/duoface-qa9-chrome-divider-recovery` tạo từ `feature/duoface-native12-qa7-no-legacy-fallback`. Không sửa native12/hud8/stable, không thay binary vendor.
- `sideplay/sileo-qa/DFSPChromeBridge.h/.xm`: tạo independent sender SpringBoard và receiver ở các process `com.apple.CarPlayApp`/`com.apple.carplayapp`/`com.apple.CarPlay`/`com.apple.carplay`/`com.apple.dashboard`. Nhận request có `generation`/`normalVisible`; dò đúng `DBStatusBarWindow` hoặc `CARStatusBarWindow`, snapshot `hidden`, áp trạng thái Normal/Fullscreen, ACK `statusbarObserved`/`visibilityApplied`. Disconnect khôi phục trạng thái cũ; không hook mọi UIWindow; chống spam ACK trên mỗi frame. **Receiver/IPC chưa có device ACK thực**.
- `sideplay/sileo-qa/Tweak.xm`: gửi yêu cầu bar theo trạng thái Normal/Zoom/fallback; log dock mode, dock area và frame thật từ `SPDash` (có type/selector được kiểm ObjC ABI); KHÔNG ép frame của SidePlay window. Dùng `DFSPHideLegacyPaneControls` để ẩn các `SPPane` chip/layout/add/close/swap/grabber/titleLabel đã được DuoFace thay, không ẩn app scene/canvas; disconnect restore trạng thái hide. App/Style vẫn giữ host SidePlay.
- `sideplay/native12-display/DFSPNativeFrame.m`: vị trí đường chia tính theo **thứ tự thực** hai pane, không phải index slot; kéo ratio invert 1-ratio khi pane0 nằm phải/dưới; giữ kéo logo hold 0.30s.
- `sideplay/sileo-qa/Makefile`: compile `DFSPChromeBridge.xm` cùng các file display đã tồn tại. `DuoFaceSidePlayDisplayQA.plist` thêm process CarPlay/Dashboard; gói có cùng ID `com.duoface.sideplaydisplay`, version **`0.1.7~native12chrome9`**, `Depends: com.sideplay (>= 1.0.4-1)`.
- Test `sideplay/native12-display/validation/check_qa9_chrome_divider.py` 16 QA9 static/geometry checks, duy trì QA5/QA7 checks đã thích ứng. Workflow `.github/workflows/sideplay-qa9-chrome-divider-deb.yml`.

## Build và kiểm thử thực tế

- GitHub Actions DuoFace **run [39177377623](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39177377623)**: source tests PASS nhưng compile FAIL với lỗi nguyên văn `DFSPChromeBridge.xm:101:31: error: 'windows' is deprecated: first deprecated in iOS 15.0 - Use UIWindowScene.windows on a relevant window scene instead [-Werror,-Wdeprecated-declarations]`. Đã sửa duy nhất đường enum sang `UIWindowScene.windows` commit `8fac1e746b70dbfa0a4f0c15e4b382acbaddb451`; không giữ deprecated API.
- GitHub Actions DuoFace **run [39177535040](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39177535040)** `build-qa`: **COMPLETED SUCCESS**. Steps: Theos iOS16 arm64 compile success; QA5/QA7 source gates success; QA9 `QA9_STATIC_SOURCE_AND_GEOMETRY_PASS`; dpkg control/arch/filter/assets/vendor exclusions success; upload artifact success; commit/push package success.
- SHA256 `ab5dba7165d5a860d93a1047c5ca95f17540b560edc4b371521bcbcc833e3346`.
- **Artifact GitHub verified:** branch commit [`f99aba274febda46e21f2fa9249a94ed86f50363`](https://github.com/chuongnguyen89dn-ui/Duoface/commit/f99aba274febda46e21f2fa9249a94ed86f50363): `sideplay/artifacts/native12chrome9/com.duoface.sideplaydisplay_0.1.7~native12chrome9_iphoneos-arm64.deb` và `sideplay/artifacts/native12chrome9/SHA256SUMS.txt` (đã đọc lại hash). **Không phải thiết bị test:** mã và DEB đã qua CI, chưa có ảnh CarPlay/ACK thực tế.

## Sileo — phân biệt thay đổi nguồn và Pages deploy

- Repo Sileo `chuongnguyen89dn-ui/carplaydsp`, `main:.github/workflows/build.yml` đã đổi đúng **một gói** SidePlay display QA từ SHA QA7 `c221584...` sang QA9 `ab5dba...` tại commit [`ba57cd9c15878c9680c429d2ce726a69747729dd`](https://github.com/chuongnguyen89dn-ui/carplaydsp/commit/ba57cd9c15878c9680c429d2ce726a69747729dd). Source GH raw theo commit artifact `f99aba...`, version `0.1.7~native12chrome9`, cùng package ID. Đã **đọc lại** workflow main, thấy pin QA9/hash đúng và **không còn** pin QA7; gói Visual12 riêng và Native12/HUD8 vẫn giữ nguyên.
- **Pages/apt publish chưa có bằng chứng:** GitHub connector chỉ có fetch run by ID, không có list workflows; không xác minh được run ID của `carplaydsp` theo commit source mới; môi trường container không có DNS để đọc GitHub Pages. **Không nói Sileo build/deploy SUCCESS** khi chưa thấy cả build/deploy job SUCCESS và Packages index/DEB trên Pages. Nếu người dùng thấy QA7 sau Refresh, kiểm tình trạng Actions/Pages của commit `ba57cd9`.
- URL gói độc lập (không phụ thuộc Pages): https://raw.githubusercontent.com/chuongnguyen89dn-ui/Duoface/f99aba274febda46e21f2fa9249a94ed86f50363/sideplay/artifacts/native12chrome9/com.duoface.sideplaydisplay_0.1.7~native12chrome9_iphoneos-arm64.deb

## Việc chưa hoàn thành và tiếp theo

1. **Sileo deployment:** dùng GitHub Actions/Pages chính repo `carplaydsp` để kiểm cả build/deploy và `Packages` có QA9 SHA. Không gán build QA9 Duoface thành trạng thái phát hành Sileo.
2. **CarPlay runtime test khi xe đỗ:** Sileo Refresh/cài `0.1.7~native12chrome9` và respring; thử Normal sau connect; tìm dòng `[DuoFaceQA9Chrome] SpringBoard ACK generation=... normal=1 observed=1 applied=1 class=DBStatusBarWindow/CARStatusBarWindow` trong syslog; nhìn thanh hệ thống trên màn. Nếu `observed=0`, filter/class/CarPlay window owner không đúng; không ép giả định. Nếu ACK nhưng bar vẫn ẩn, cần xác định thanh người dùng muốn chính xác là dock/statusbar nào (Apple CarPlay riêng với `SPPane.barHidden`).
3. **App/pane:** kiểm nút cũ không còn chồng, cả 2 app bấm/chạm tốt; đảo hai ô và kéo tỷ lệ (ngang/dọc), logo giữ 0.3s; Menu Zoom Out quay Normal, disconnect restore, không exitmode.
4. **Parity còn thiếu:** Native12 Style 8 layouts, native picker/recent, HUD8/bubble ownership, iPhone prefs, độc lập hoàn toàn scene/bridge. QA9 là bản test có sửa P0/P1 cụ thể, không gọi đã hoàn thiện toàn bộ DuoFace.
5. **Rollback:** QA7 tại commit `beafe5b6ab020859b82e627ca635046796d9d956`, hash `c221584b16af24f844dbb968d90ffbcd6efbbc64a312a6582d955fc45348901d`; không xóa SidePlay hoặc Native12/HUD8 khi xử lý QA9.

**Lệnh/workdir từ CI:** Runner macos-15 tại checkout root `$GITHUB_WORKSPACE`; `python3 sideplay/native12-display/validation/check_duoface_qa5_parity.py`, `check_qa7_visual_recovery.py`, `check_qa9_chrome_divider.py`, `cd sideplay/sileo-qa && make clean package FINALPACKAGE=1`; xác nhận `dpkg-deb -f`, `dpkg-deb -c`, `dpkg-deb -x`, filter và `shasum -a 256`. Không cần token/cookie. Gói URL commit-pinned.
