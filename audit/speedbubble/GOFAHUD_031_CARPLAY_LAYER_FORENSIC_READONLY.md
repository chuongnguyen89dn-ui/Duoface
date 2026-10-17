# GOFAHUD 0.3.1 rootless — mổ DEB, đúng lớp bong bóng CarPlay

**2026-10-17 +07 | chỉ phân tích và lưu bằng chứng; không sửa DuoFace runtime, không đóng DEB, không cập nhật Sileo.**

## Đúng gói GOFAHUD, KHÔNG phải GMapHUD

- Nguồn gói gốc: `manhtien9x/gofahud-repo`, release [v0.3.1-1](https://github.com/manhtien9x/gofahud-repo/releases/tag/v0.3.1-1), asset `GOFAHUD-0.3.1-rootless.deb` (648224 bytes). SHA256 công bố và CI đo thực trùng: `62d6d818384844591217d74ab446404637127752e1b23bc1f9754ef1da297ad5`. Cũng trùng SHA bản người dùng đã đưa trong audit 16/10.
- CI chỉ-đọc [run 38990750645](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/38990750645), job 117272408248 `completed/success` lúc ~2026-10-17 01:25 UTC, source ở `.github/workflows/duoface-gofahud031-window-layer-readonly.yml`, script `migration/full_payload/native_test/audit_gofahud_031_carplay_layer.py`. Runner tải release, đối chiếu SHA256, `dpkg-deb -x/-e/-f`, đọc từng plist và `strings -a` dylib rồi commit báo cáo.
- Báo cáo **trích trực tiếp từ DEB**: `audit/speedbubble/GOFAHUD_031_CARPLAY_LAYER_ACTUAL_DEB.json` (tồn tại trên feature), trạng thái `GOFAHUD_031_ACTUAL_ROOTLESS_DEB_LAYER_AUDIT_PASS_STATIC_ONLY`. Giữ nguyên cả hash dylib/filter/original package. Gói `Package=local.gofahud`, `Version=0.3.1`, `Architecture=iphoneos-arm64`, 29 regular payload files, 6 module dylib/plist. File GofaCarplayGlobal.dylib có FAT arm64 + arm64e.
- Log thực: `GOFAHUD031_SOURCE_RELEASE_DEB_SHA256_PASS`, `GOFAHUD031_EXACT_ROOTLESS_SHA256_AND_DEB_METADATA_PASS`, `GOFAHUD031_CARPLAY_GLOBAL_DYLIB_AND_TWO_BUNDLE_FILTERS_PASS`, `GOFAHUD031_REPORT_JSON_PARSE_AND_STATIC_INTEGRITY_PASS`. Đây **không phải test hiển thị trên điện thoại**.

## Injection filter thực tế trong DEB

| Module | Filter chính xác | Vai trò |
|---|---|---|
| `GofaCarplayGlobal.dylib` | `com.apple.CarPlayApp`, `com.apple.CarPlayTemplateUIHost` | HUD toàn CarPlay, cửa sổ mới HOẶC gắn trực tiếp vào cửa sổ hệ thống |
| `GofaCarplayOverlay.dylib` | `com.google.Maps` | Đường dự phòng gắn card vào `CPWindow` bên trong Google Maps; KHÔNG phải global HUD |
| `GofaPhoneOverlay.dylib` | `com.apple.springboard` | Bong bóng trên iPhone, không phải global CarPlay |
| `GofaLaunchHelper.dylib` | `com.apple.springboard` | Launch/background helper; không phải toàn bộ HUD CarPlay |
| `GOFADevProbe.dylib` | `com.lumi.GOFA`, `com.google.Maps` | Source/debug |
| `GofaLifecycle.dylib` | `com.lumi.GOFA` | Đời sống ứng dụng GOFA |

**Chốt rõ:** phiên bản rootless thực **không inject `GofaCarplayGlobal.dylib` vào SpringBoard**. Trong khi DuoFace `DuoFaceSpeedHUD.plist` bản Speed5 filter `Executables=(SpringBoard)` và constructor chỉ chạy khi processName=SpringBoard. Đây là khác biệt process/owner nghiêm trọng, cần thử theo bằng chứng, không chỉ thay tầng số.

## Hai lớp renderer của GOFA HUD (bằng chứng source + selectors/class trong binary)

Nguồn GOFA: `manhtien9x/gofahud-repo@e423ac7408d021d6384eba8ef270e79518967ed9:source/rootless/tweak/carplay-global-overlay.m`; SHA blob `d5b2597dd14b03c293bd623521902c5f71818a05`. `GofaCarplayGlobal.dylib` SHA256 `791f3f2de2ce0e6834888db33b17f5f37a424712c9fb07b8c7234ee90ed587ca`. Runtime classes/selectors sau có trong DEB thật: `GOFACarGlobalWindow`, `GOFACarHUD`, `CARNotificationWindow`, `CARStatusBarHostWindow`, `CPSWindow`, `initWithWindowScene:`, `setScreen:`, `setWindowLevel:`, `addSubview:`, `bringSubviewToFront:`, `hitTest:withEvent:`. Điều đó xác nhận những nhánh thực thi **có mã nhị phân**, không chứng minh nhánh nào chạy trên máy cụ thể.

1. **Đường cửa sổ nổi độc lập** (source lines 159–170): tạo `GOFACarGlobalWindow:UIWindow` cùng `windowScene` của base, hoặc khi không có scene thì `initWithFrame:base.bounds` rồi `overlay.screen=base.screen`. `overlay.windowLevel=10000000`, nền trong suốt; root view controller riêng; `GOFACarHUD` 148×84 tag 41059; `overlay.hidden=NO`; `hitTest` trả nil nếu ngoài card để giữ tương tác CarPlay.
2. **Đường gắn trực tiếp** (lines 150–156): nếu đang trong **process CarPlayApp** và base window class **`CARNotificationWindow`**, lấy `base.rootViewController.viewIfLoaded`, kiểm `host.window==base`, tạo `GOFACarHUD` nếu cần, gọi `[host addSubview:native]` + `[host bringSubviewToFront:native]`. Đây là một UIView trực tiếp trong cửa sổ CarPlay có sẵn, không phải tăng `windowLevel`. GOFA còn hook `CARNotificationWindow hitTest:withEvent:` để card giữ được interaction, nhưng phần còn lại chuyển cho cơ chế hit-test gốc (lines 105–110, 201–206).
3. **Tìm cửa sổ qua nhiều nguồn/process**: chỉ process `CarPlayApp` hoặc `CarPlayTemplateUIHost` (lines 196–199). Duyệt `UIApplication.sharedApplication.windows` cộng `connectedScenes[].windows`; loại cửa sổ của chính GOFA; cần `bounds >= 400×240`, `windowScene.session.role` chứa CarPlay **hoặc** `screen != UIScreen.mainScreen`, `!hidden`, alpha>0 (lines 112–147). Có `Rank`: `CARNotificationWindow=100`, `CARStatusBarHostWindow=80`, `CPSWindow=60`, `UIWindow=40` (lines 20–26). Không phụ thuộc một singleton `CBBridgeManager.window`.
4. **Giữ duy nhất một HUD cross-process**: `local.gofahud.carplay.global` ghi owner lease với PID/uptime, TTL 3s và ưu tiên CarPlayApp; `local.gofahud.carplay.trace` báo visible. Timer .5s + UIWindowDidBecomeVisibleNotification cập nhật (lines 118–216). Gắn native vào `CARNotificationWindow` ưu tiên nếu đủ điều kiện; còn lại overlay độc lập. Khi GOFA active, `GOFACarHUDRefresh` chủ động hide (trong `carplay-overlay.m` lines 73–78).
5. **Dự phòng riêng Google Maps**: `GofaCarplayOverlay.dylib` chỉ filter `com.google.Maps`, `carplay-overlay.m:182–190` bám `CPWindow` và thêm card vào root content; có lease tránh nhân đôi khi global đã hiển thị. Không nhầm điều này với `GMapHUD` dự án khác.

## So đúng DuoFace Speed5 và nghi vấn bị che

DuoFace Speed5 source `runtime/speedbubble/DFSpeedSceneOverlay.mm` blob `111cab47af693f639a651d2def443d7010b5673b`, feature `feature/duoface-exact-payload-migration`. Nó **đã có** `DFSceneHUDWindow:UIWindow`, `hitTest` card-only, `windowLevel=10000000`, `initWithWindowScene`/fallback `screen`, nhưng chỉ inject SpringBoard và đợi `CBBridgeManager.sharedInstanceIfExists.window` kiểu `CBWindow`, `isVisible`, `rootWindow` screen external/CarPlay role. Nó **chưa có** dò `CarPlayApp`/TemplateUIHost base windows + CARNotificationWindow native attach, cũng chưa có cross-process lease.
- Vì GOFAHUD và Speed5 đều có `windowLevel=10000000`, **tăng con số không có cơ sở sửa lỗi**. Nếu Speed5 chưa load/không nhận owner thì không có cửa sổ nào để bị DuoFace che.
- **Giả thuyết ưu tiên**: Speed5 chọn sai process/owner so với chủ sở hữu CarPlay thực tế hoặc bỏ lỡ cửa sổ phù hợp; static evidence hỗ trợ khả năng này mạnh hơn giả thuyết tăng level. **Chưa thể xác nhận** SpringBoard bị che hay loader/injection không chạy vì không có runtime trace thiết bị.
- Nếu thiết kế bản tiếp theo: trước hết đặt read-only diagnostics trong đúng process CarPlay được Native12 xác nhận, enumerate eligible windows, class/root/scene/screen, gắn bản thử một card duy nhất bằng native attach hoặc scene overlay theo chủ sở hữu thực, rollback an toàn; cần loại Home, Waze crash, GOFA active, không làm thay Native12. Phải kiểm process real và gate split=1 trước khi quyết định tạo global overlay để tránh xuất hiện trên Home. Không tự gộp source GOFA vào DuoFace rồi phát hành vì rủi ro xung đột CarPlay.
- Không thể tuyên bố bản 0.3.1 hiển thị được trong **DuoFace split** chỉ từ source/binary; GOFA từng hiển thị trong app CarPlay khác, nhưng cảnh cụ thể chưa thử. Hệ thống scene cross-process khác nhau có thể che/cắt nhau.

## Phạm vi / điểm tiếp tục
- Đã mổ DEB thật và ghi `audit/speedbubble/GOFAHUD_031_CARPLAY_LAYER_ACTUAL_DEB.json`; nguồn `manhtien9x/gofahud-repo` chỉ là tham chiếu, mọi output ở **Duoface**.
- **Không** sửa/built `com.duoface.independent`, không deploy Sileo, không cài/iPhone test, không yêu cầu user NewTerm; giữ `Native12` baseline và yêu cầu Speed5 chỉ hiện split DuoFace.
- Bước kỹ thuật kế: audit read-only CBWindow/CBBridgeManager trong Native12 có thực sự được tạo ở CarPlayApp/TemplateUIHost hay SpringBoard và cách dò native root window; đối chiếu GOFA Rank/window enumeration để chọn host duy nhất trước bất kỳ Speed6 nào.
