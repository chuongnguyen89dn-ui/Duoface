# GMapHUD / TW Hub 0.2.4 — lớp hiển thị bong bóng trên CarPlay (audit DEB thực)

**17/10/2026 | xác minh DEB rootless thực tế, chỉ đọc; không build, không cài, không phát hành.**

## Nguồn và bằng chứng
- Gói tham chiếu: `bechou0410/gmaphud` release tag `v0.2.4`; file `com.chou.googlemaps.vietmap_0.2.4_iphoneos-arm64.deb`.
- SHA256 do GitHub Release xác nhận và **runner thực tính khớp**: `abd49f874b5f0df80d44de03368cb0d965ff498b1cc3e77d4dbabf4de28b804d`.
- GitHub Actions **run [38990250201](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/38990250201)**, job `117270839120`, `completed/success`; log: `GMAPHUD024_ACTUAL_DEB_DIGEST_AND_PACKAGE_VERIFIED_PASS`, `GMAPHUD024_ACTUAL_DEB_LAYER_MODULES_EXTRACTED_PASS; ON_DEVICE_NOT_TESTED`.
- Nguồn audit có thể chạy lại: `.github/workflows/duoface-gmaphud-layer-audit.yml`, commit `0921569dd55c6789a865605620367230af1d2888`. Bung gói bằng `dpkg-deb -x`, metadata `dpkg-deb -e/-f`, quét dylib với `strings -a`. Report chi tiết trong artifact của run: `gmaphud024-actual-deb-layer-static-audit` (artifact ID `12084708434`).
- Kết quả DEB: `Package=com.chou.googlemaps.vietmap`, `Version=0.2.4`; tổng **146 file** payload; 7 file `*.plist` injection, 7 dylib.
- GitHub Contents API trong phiên chat không chuyển được byte nhị phân DEB lớn; **chính runner GH Actions đã tải / kiểm hash / giải nén thành công**, không giả vờ giải nén trong chat.

## Đã xác nhận ngay trong DEB
| Dylib | SHA256 | Filter gói | Chức năng có bằng chứng |
|---|---|---|---|
| `GoogleMapsVietMap.dylib` | `e8859aea550f5a5e6c40be18406cb1132f977ccb1af3e6cf9dd5e5297b43d1ec` | bundle `com.google.Maps` | chứa `AZCarPlayView`, `GMSNSpeedLimitView`, `GVMClassicSpeedCard`, `GVMHaloSpeedCard`, selectors `addSubview:`, `addSublayer:` |
| `GMapHUDOverspeedScreen.dylib` | `f975c4b8be59c9d2a53336ab3dea5e0595c49c2d4961218acd0cdb8ba122f70f` | bundle `com.apple.CarPlayApp` | chứa `GVMOverspeedFrame`, `addSublayer:`; riêng **viền cảnh báo**, không phải card số tốc độ |
| `GMapHUDPlacementRelay.dylib` | `b5e07e033fcb1909894bf51907c6822d51283f6ec887008c108f95138696f592` | bundles `com.apple.springboard`, `com.apple.CarPlayApp` | relay vị trí/cấu hình; không suy ra tự render card trong SpringBoard |
| `GMapHUDGuidanceRelay.dylib` | `371341b445529ff855eb0a06256db7814d967984c935b892715d62652fcc36b8` | bundle `com.apple.CarPlayTemplateUIHost` | đọc tọa độ điều hướng cho card chứ không chứa renderer card |
| `GofaGMapHUDSource.dylib`, `WazeGMapHUDSource.dylib`, `VietMapGoogleMapsSource.dylib` | xem run artifact | bundles GOFA, Waze, VietMap | nguồn tín hiệu, không phải chủ sở hữu bubble trên CarPlay |

Các filter DEB là binary plist `bplist00`; chuỗi bundle được đọc trong log. Trên source tag `v0.2.4` các plist có nội dung text tương đương, khớp tên bundle.

## LỚP RENDER CHÍNH XÁC (theo source v0.2.4 và có class/selector tương ứng trong DEB)
1. Card số tốc độ: `tweak/google-hook.m` hook ObjC `AZCarPlayView` + `GMSNSpeedLimitView` **bên trong tiến trình Google Maps**, không phải inject card vào global SpringBoard. `tweak/carplay-style.m:GVMUpdateSpeedCard` tạo `GVMClassicSpeedCard` hoặc `GVMHaloSpeedCard`, gọi `[map addSubview:card]` (dòng 291); cập nhật bằng `GVMLayoutSpeedCard(map)`; điều kiện `ExternalMap(map)` đòi `AZCarPlayView` và `map.window.screen != UIScreen.mainScreen` (dòng 57–58). Card là **UIView con của bản đồ Google Maps** trong UIWindow của ứng dụng, không phải UIWindow toàn cục đặt `windowLevel=10000000`.
2. Viền cảnh báo: `tweak/overspeed-screen.m` trong `CarPlayApp`: duyệt `UIApplication.sharedApplication.windows`, thêm `GVMOverspeedFrame.layer` vào `window.layer`, đặt `frame.layer.zPosition=10000`; một dạng CALayer trên cửa sổ có sẵn, **không phải card số tốc độ**, và không đảm bảo vượt qua UIWindow của tiến trình khác.
3. `tweak/carplay-style.m` còn có `[map.layer addSublayer:frame.layer]` và `zPosition=10000` cho viền local, không thay vị trí card trong UIWindow.
4. `tweak/google-hook.m` (dòng 54–58) ghi rõ **Google Maps full-map CPWindow và Dashboard UIWindow có thể không có `UIWindowScene`**; fallback xác định active qua `UIApplication.sharedApplication.applicationState`, trong khi Speed5 dùng root `CBWindow` SpringBoard + external screen hoặc CarPlay role.

## So với DuoFace Speed5 đang cài
- `runtime/speedbubble/DFSpeedSceneOverlay.mm` (`feature/duoface-exact-payload-migration`) tạo **UIWindow mới** `DFSceneHUDWindow` từ `CBWindow.rootWindow.windowScene` hoặc `base.screen`, đặt `w.windowLevel=10000000`, gắn `DFSpeedNativeHUD` dưới `rootViewController.view`. SpringBoard process gate và `CBBridgeManager.sharedInstanceIfExists.window` gate. **Không đồng dạng với HUD Google Maps**.
- `zPosition` (trong cùng CALayer hierarchy) **không so sánh số học được** với `UIWindow.windowLevel` (thứ tự UIWindow trong ngữ cảnh scene/process).
- Nếu DuoFace sở hữu UIWindow/compositor ở phía trên Google Maps, card GMapHUD nằm trong Google Maps có thể bị nó che/clipped. **Nhưng đây chỉ là khả năng compositing**; chưa có ảnh test chứng minh và **không tự động giải thích** Speed5 không có log LOADED ở đường chính.
- Với mục tiêu hiển thị **trong DuoFace split**, mô hình gần sát GMapHUD là móc renderer vào **UIView thực của split DuoFace** sau khi owner/view/window đã xác nhận; không chuyển nguyên filter `com.google.Maps` hoặc tăng `windowLevel` đơn thuần. Cần xác minh process/host và đảm bảo không phủ CarPlay Home/Waze/GOFA.
- Không có dữ liệu runtime/iPhone nào tại audit này để xác định DuoFace thực sự che HUD; `SpringBoard` Speed5 loader và bridge owner vẫn unverified.

## Trạng thái và bước tiếp
- **CONFIRMED**: DEB GMapHUD 0.2.4 thực, hash và nội dung module/plist; source tag đối chiếu renderer.
- **NOT CONFIRMED**: TW Hub trên iPhone của người dùng đúng version 0.2.4 hay hiện version khác; thứ tự compositing DuoFace với app window trên CarPlay; Speed5 có thực sự được SpringBoard load. Không đánh đồng "DEB có code" với "đã hiện trên thiết bị".
- **NEXT**: audit static `DuoFaceDashboard.dylib` Native12 để định danh view owner và lớp root hiển thị split so với external Google Maps app window, chỉ khi có bằng chứng đổi mô hình gắn HUD. Không tăng windowLevel và không phát hành thêm Speed6 chỉ dựa trên suy luận; giữ Native12 baseline. Không yêu cầu user nhập thêm lệnh Terminal.
