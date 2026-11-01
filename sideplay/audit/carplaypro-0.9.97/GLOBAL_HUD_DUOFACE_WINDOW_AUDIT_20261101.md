# QA163 — CarPlayPro Speed vs DuoFace Speed8: HUD toàn màn CarPlay (audit nguồn và owner)

## Yêu cầu mới 2026-11-01
Người dùng yêu cầu **HUD Speed8 hiển thị bất kể đang dùng GOFA, ứng dụng khác trong DuoFace, ứng dụng CarPlay native hay màn hình CarPlay Dashboard/Home**. Đã phản bác chính xác QA162: HUD mới chỉ xuất hiện khi chọn GOFA pane; CarPlayPro Speed cũng chưa xuất hiện đè lên DuoFace. Việc chọn nguồn tốc độ (GOFA) **không được quyết định vị trí hiển thị HUD**. Tuyệt đối không coi build xanh là hiển thị thực tế.

## Đối chiếu dữ liệu gốc thực tế (không thực thi DEB)
- DEB gốc lưu nguyên byte tại `main:sideplay/audit/com.carplaypro.speed_0.9.97_iphoneos-arm64.deb`, SHA256 `e5b0918b3bc1948420f37a8a9e21365756da46fba44d582a3f2893aee9b4102f`. Toàn bộ 94 payload files, 3 control files, 16 plist, 10 ARM64/e slices, Mach-O section strings/symbols, 85,162 disassembled instructions đã được lưu ở `sideplay/audit/carplaypro-0.9.97/`, workflow scan `41292790813` SUCCESS. Không có phép thử UI/runtime DEB gốc trên thiết bị.
- **SpeedAlerts.dylib Substrate filter** theo `TECHNICAL_FEATURE_MAP.md`: **cả `com.apple.CarPlayApp` và 5 nguồn** `vn.vietmap.live`, `com.lumi.GOFA`, `com.wynauto.wyn`, `su.navitel`, `vn.vietmap.live.v2`. Đây là filter nhiều tiến trình, **không phải overlay chỉ gắn GOFA**.
- `macho/007-SpeedAlerts.dylib-arm64.section-strings.json` chứa class `SADisplayWindow`, `SAOverlay`, `CPSpeedDisplayRootWindow`, property `displayWindow`, `hostWindow`, `windowInventory`, `bubbleAttached`, `hiddenForSource`, selector `setWindowScene:`, `initWithWindowScene:`, `renderTick` và log `bubble-display backend=%@ exists=%d scene=%d ... attached=%d`. Đây là bằng chứng **nhiều backend/nguồn owner hiển thị** ở mức tĩnh, **không chứng minh thực sự overlay trên mọi UIWindow, đặc biệt bên ngoài CarPlayApp**.
- `macho/007-SpeedAlerts.dylib-arm64.symbols.json` xác nhận `_OBJC_CLASS_$_SADisplayWindow`, `_OBJC_CLASS_$_SAOverlay`, `_OBJC_CLASS_$_UIWindow`, `_OBJC_CLASS_$_UIWindowScene`, và `_UISceneDidActivateNotification`, `_UIWindowDidBecomeVisibleNotification`. Đây không phải bằng chứng chọn đúng topmost window ở màn hình DuoFace; cần runtime.
- `SourceLifecycle.dylib` filter vào SpringBoard và có quản lý nguồn/background, không thể dùng để suy ra HUD global. Giấy phép nằm ngay trong module nhị phân; không tái dùng hay sửa vendor dylib/activation.

## Đối chiếu mã DuoFace QA162 thực sự
- Repo `chuongnguyen89dn-ui/Duoface`; base QA162 branch `feature/duoface-qa162-gofa-speed8-20261101`, head tại audit `71670e088d00799b1c23b8ca2188dda5261d8c6e`.
- `sideplay/duoface-native-scene-host/DFNative12Chrome.m`, method `refreshGOFASpeedHUD162`: vòng lặp 4 appSceneWindows, **explicit `[bundle isEqualToString:@"com.lumi.GOFA"]`**, chỉ attach `DFNative8SpeedHUDView` vào `ownerWindow.rootViewController.view` khi có hosted GOFA scene. Nếu không có GOFA thì **removeFromSuperview**. Đây là nguyên nhân **xác định từ code** khiến Speed8 không xuất hiện ở các app DuoFace khác.
- `sideplay/duoface-native-scene-host/speed8/DFNative8SpeedHUDView.mm` là renderer Speed8 do DuoFace có sẵn. `tick:` đòi ownerWindow là external non-main-screen, `DFSpeedHUDReadBest` đọc mẫu speed có TTL. **View reusable**, nhưng không tự chạy độc lập: cần host (UIView/UIWindow) đúng.
- `DFTouchOwnerProbe.plist` injection **chỉ SpringBoard**. `DFNative12Chrome` tự sinh **4 appSceneWindows** cho hosted app panes, bị ẩn ở Home/disconnect theo vòng đời DuoFace. Vì vậy riêng bản build QA162 không thể hiển thị Speed8 trên CarPlay Dashboard/native app ngoài DuoFace.
- `DFCarPlayDockOwner.plist` injection đã có `CarPlay/CarPlayApp/dashboard` (bundle và executable), nhưng `DFCarPlayDockOwner.m` chỉ Dock-owner/scene/probe, **chưa mount Speed8 ở native CarPlay UI**.
- `DFGofaSpeedSource162.m` chỉ inject vào bundle `com.lumi.GOFA`, tạo `CLLocationManager` riêng lấy `location.speed * 3.6`, không hook GOFA data model; `DFSpeedTransport.mm` đưa mẫu vào Darwin notify `com.duoface.speedhud.v1.gofa`, `limitValid=false`. **Đây là tốc độ GPS CoreLocation, không phải dữ liệu camera/giới hạn GOFA**. Dù HUD có hiện ở mọi nơi, khi GOFA không chạy / không được location permission, tốc độ phải hiển thị `—`, không bịa số.

## Phân biệt ba lớp bắt buộc
| Lớp | QA162 thực tế | Cần kiểm chứng QA163 |
|---|---|---|
| Producer GPS | GPS iOS trong process GOFA | Giữ nguyên nguồn GOFA thử nghiệm, TTL & unknown; không phụ thuộc viewer |
| Renderer | `DFNative8SpeedHUDView` bản gốc DuoFace | Tái dùng renderer ở cả DuoFace và CarPlay native; không dùng bản CarPlayPro |
| Display owner | Chỉ root of verified GOFA pane trong SpringBoard | DuoFace: một visible app pane hoặc chrome owner; native CarPlay: view trong **đúng foreground external UIWindow hiện có**, không tạo/chiếm Dock, không tìm màn hình điện thoại |

## Kết luận và giới hạn chứng cứ
- **Có thể sửa lỗi gate GOFA rõ ràng** bằng bỏ phụ thuộc bundle GOFA khi chọn render host, giữ nguồn GOFA độc lập. Đây là bug QA162 được xác minh source, không cần đoán.
- **CarPlay Dashboard/người dùng app native:** bắt buộc bổ sung một đường owner trong process CarPlay/CarPlayApp/dashboard, vì SpringBoard Chrome dừng khi rời DuoFace. Nơi vẽ phải lấy từ native foreground external UIWindow và giữ nguyên Dock/Home/touch. Dữ liệu không giới hạn trong chính GOFA.
- **Không thể bảo đảm “mọi nơi” bằng static scan/build**: iOS 16 host/display z-order, CarPlay Dashboard window class, remote app compositing, repeated reconnect và việc vẽ qua ranh giới tiến trình chỉ xác minh được bằng logs/screenshot thiết bị khi chạy. Cần phân biệt HUD visible và speed sample available. CarPlayPro gốc không hiện trên DuoFace là dữ kiện người dùng đã báo; static symbols không được dùng để phản bác.
- **Hướng QA163**: dùng đúng một `com.duoface.jb.embedded`, tách nguồn dữ liệu khỏi UI owner; dành 2 owner (SpringBoard DuoFace panes / native CarPlayApp + Dashboard) với fail-safe và không nhân bản GUI khi cả hai cùng hiển thị. Bản QA163 chỉ build riêng branch, không tự thay bản Sileo public QA162 trước khi có kiểm chứng z-order và touch. Mọi test tĩnh không phải device PASS.

## Lệnh/bằng chứng tái lập
- Original audit workflow: `python3 sideplay/tools/audit_carplaypro_0997.py --replace` từ root trong môi trường CI capstone 5.0.6; run `41292790813` lưu evidence gốc, không cần quét lại từ đầu.
- Source static review: GitHub `fetch_file` đối chiếu các file liệt kê theo branch QA162; không chạy/patch vendor DEB.
- QA162 baseline: signed integrated DEB `0.0.162~gofaspeed8test1` checksum `c287de0621bb3f61bcc7c80d264a7c110da8a2208e0a49563c9245d08a86cb71`, public Sileo có và giữ để rollback; không đổi package ID.

