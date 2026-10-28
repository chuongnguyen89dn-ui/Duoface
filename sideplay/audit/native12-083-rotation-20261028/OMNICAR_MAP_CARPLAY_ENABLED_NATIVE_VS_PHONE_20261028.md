# OmniCar 1.0.3: hiển thị bản đồ native mà KHÔNG bỏ Maps khỏi CarPlay — kiểm chứng riêng (2026-10-28)

## Mục tiêu do người dùng xác nhận
- DuoFace hiển thị **bản đồ thực (map tiles, thao tác xem/chạm bản đồ)** trong ô chia như OmniCar, trong khi native Google/Apple Maps **vẫn được phép và vẫn hoạt động trong CarPlay**, không yêu cầu xóa/tắt Maps tại iPhone Settings > General > CarPlay > Customize.
- Điều hướng tiếp tục chạy khi đổi sang DuoFace/Home; không đánh tráo màn hình hướng dẫn rẽ của điện thoại thành bản đồ native; không áp hệ số zoom 80% để chữa sai scene.
- **KHÓA .90** YouTube phát/rotation đã được người dùng xác nhận PASS; giữ nguyên sáu file player/host/lifecycle/Chrome/Dock đã được guard bởi CI 40680676803. Không sao chép vendor code/dylib/license; không gọi private native-scene setter khi chưa có owner được xác minh.

## Kết quả điều tra thực tế — vì sao cấu hình Maps CarPlay không cần bị tắt?

### ĐÃ XÁC MINH qua original OmniCar binary, KHÔNG PHẢI phỏng đoán giao diện
- Original SHA-pinned `Omnicar/com.anlai.omnicar_1.0.3_iphoneos-arm64.deb` SHA256 `d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd`. Các audit đã chạy thành công: GHA `40626272871` (6 dylib + injection filters), `40627902229` (full branch trace + CFString), `40628918504` (owner/lifecycle), `40630009621` (hosted-controller nil-versus-real), `40679042884` (458 split ObjC methods).
- `OmniCarSplitScreen.dylib` **injected into CarPlayApp và SpringBoard** qua gói original; `OmniCarAppBridge.dylib` inject vào UIKit, **là tuyến khác**. Đây là bằng chứng process-path, *không phải* chứng minh đã chạy trên thiết bị này.
- `SCPCarSplit.isCarPlayApp:` IMP `0xff20`: mã ARM64 nhánh `0xff50 → 0xffb4` / `0xff64 → 0x101bc`, xác thực `bundleIdentifier`, `carPlayDeclaration` (CFStrings tại `0x100a0,0x100c4,0x10100`), loại trừ các process CarPlay nội bộ và kiểm `presentsFullScreen`, `appBridge`. Đây là **native app classification** bằng declaration; không cần biến Maps thành một ứng dụng phone-only để hiển thị bằng AppBridge.
- `SCPCarSplit.publishCarPlayApps` IMP `0x21b1c` ghi log hai roster độc lập: **native CarPlay apps for OmniCar Settings** và **user-selected iPhone apps (App Bridge)** (CFString PC `0x21c68`). Lưu ý từ `Settings` trong chuỗi log có thể là **UI settings của OmniCar**, KHÔNG phải bằng chứng sửa danh sách CarPlay Customize của iOS.
- `SCPCarSplit.openApp:slot:` IMP `0x164d4`: từ chối ứng dụng thiếu giao diện CarPlay (`0x165a4`), phát hiện đã mở ở pane khác/floating (`0x166cc`, `0x16880`). `sendLaunch:bundle:tries:` IMP `0x16e04` có `currentBaseViewController`, chờ hệ thống Dashboard trở lại Home trước khi mở khi cần (PC `0x16ff4`). Đây là thao tác launch có phân biệt chủ native.
- **Đường hiển thị map native**: `adoptViewController:` `0x18d20` → `adopt:slot:` `0x1942c` xác định `applicationInfo`/`proxyApplicationInfo`; `sceneOfViewController:` `0x1aaf4` dùng `sceneHandle`/`scene`; `SCPCarPane` chứa các trường VC, host, bundleID, hostFrame và sceneSize; `pushSceneSizes` `0x1c550` dùng `foregroundSceneWithSettings:completion:` (`0x1c738`) và guarded `sceneHostView` (`0x1ca04/0x1ca40`). Đây là đường **CarPlay scene owner + native rendering host**, không phải zoom iPhone SBAppViewController.
- Vòng đời `verifySceneOfPane:expected:retry:` IMP `0x1cce0`: kiểm scene settings/frame thật, **chỉ khi điều kiện lệch có nhánh** background (`0x1d084`) → foreground (`0x1d2fc`). `scene:destroyedForViewController:ownScene:` `0x1ad58` có hai nhánh riêng, scene của pane thì đóng pane; scene foreign/replaced thì **giữ pane**, log `0x1afc4`. Không được áp background/foreground tự động trong DuoFace khi Maps đang dẫn đường.
- `SCPHostedAppVC.sceneHostView` `0xfdbc` thực chất trả **nil** (ARM64 `mov x0,#0;ret`); lớp placeholder của AppBridge KHÔNG phải nguồn hiển thị native map. Đây là khác biệt quan trọng với native app-owned `DBApplicationSceneViewController`.

### ĐÃ XÁC MINH từ thiết bị thực và Apple
- 46 dòng owner JSONL thật trên `Duoface/main:sideplay/log/DuoFaceCarPlayOwner-4C5C8ADB-EE69-458A-B664-1753AB90C797.jsonl`: 1-based **#41–42** native `com.google.Maps` `FBScene` trong `CarPlayApp` PID 68776; **#43–44** cùng `DBApplicationSceneViewController`/host view/window đổi sang native DuoFace scene; #45–46 không quan sát thấy controller. Không có snapshot nào cùng lúc thấy hai native owner đầy đủ. Chưa thể kết luận scene bị hủy hoặc hai scene cùng render.
- Apple: https://developer.apple.com/documentation/carplay/displaying-content-in-carplay — chỉ **navigation app** được cấp CarPlay scene window để vẽ bản đồ thực; template/dashboard có scene role riêng. https://support.apple.com/en-mide/guide/iphone/iph206c570e3/ios — ứng dụng tương thích CarPlay xuất hiện tự động và có thể cấu hình Home; app native navigation có thể hiện trên Dashboard. **Customize/Remove icon ≠ chuyển một app thành native/phone map scene.**
- No original literal `CPMapTemplate`, `CPWindow`, `MKMapView` in ASCII scan of 6 modules. **Không đủ để chứng minh OmniCar không gọi các API này bằng dynamic lookup.** Nhưng bằng chứng native owner/scene-host ở trên mạnh hơn giả thuyết OmniCar tự vẽ bản đồ.

### Phân biệt ĐÃ XÁC MINH và CHƯA XÁC MINH
- **Bằng chứng ủng hộ rất mạnh**: OmniCar không cần yêu cầu người dùng gỡ/ẩn Maps trong CarPlay để ép sang AppBridge, vì nó *nhận diện native CarPlay app từ declaration* và đi qua hệ thống scene owner/host của CarPlayApp; AppBridge chỉ dành cho app iPhone.
- **Chưa chứng minh**: máy người dùng đã giữ icon Maps trong Customize khi test OmniCar; original không hề có nhánh thay đổi CarPlay settings ở đâu (scan tên/literal không phải formal proof); một native Maps `CPWindow` đồng thời host cả trong màn bản đồ riêng lẫn một pane DuoFace; hay giới hạn scene rendering thực trên Hyundai Tucson. Không khẳng định chắc chắn đó là *duy nhất* lý do OmniCar hiển thị map.

## Điểm sai cụ thể của DuoFace .90 — có source
- `sideplay/duoface-native-scene-host/DFSceneHost.m:759–822` xử lý toàn bộ bundle bằng SpringBoard `SBDeviceApplicationSceneEntity initWithApplicationForMainDisplay:` (`line 780`), ngay cả Maps, sau đó `SBAppViewController`. Đây là **iPhone MAIN display scene**, không phải native `Car[...]:com.apple.CarPlayTemplateUIHost:com.google.Maps` mà log đã thấy.
- Do đó phóng to/giảm tỷ lệ hoặc cố đổi hướng source iPhone không thể biến nội dung turn-instructions thành native CarPlay map. Cần native branch trong **CarPlayApp**, app roster riêng, app owner, live FBScene, sceneHostView và owner generation; phone bridge tiếp tục làm các app iPhone/YouTube.
- `DFCarPlayLiveOwnerSnapshot.m`/ `DFCarPlayNativeSceneTimeline.h` đã có đọc-only owner classifier/rebind; source-only CI 40680676803 SUCCESS, bảo vệ .90. **Chưa có** native CarPlay pane renderer, chưa có bằng chứng owner concurrent và chưa có thiết bị test bản observer mới.

## Quyết định kỹ thuật và điều kiện mở khóa trước khi sửa giao diện Maps
1. **Đường native Maps, không ép tắt app trong CarPlay Customize**. Nhận `com.google.Maps` / `com.apple.Maps` từ CarPlay native roster/scene owner thực, không đi `DFSceneHost` phone/MainDisplay. Chỉ nhận owner có `DBApplicationSceneViewController + FBScene + sceneHostView` và scene ID bundle khớp, process + generation đang hoạt động; ứng dụng khác tiếp tục dùng phone bridge.
2. Khi user chọn Maps slot, không cố đưa `SCPHostedAppVC` hoặc `CPWindow` bên ngoài vào ô bằng reparent/copy/mirror; trước tiên **chứng minh** cách tạo native pane host an toàn trong CarPlayApp và quyền sở hữu view + quản lý vòng đời. Hai scene đồng thời có thể không tồn tại dưới cùng Dashboard controller; không đoán.
3. Nếu không chứng minh hai full native surfaces cùng tồn tại, đo cụ thể **một native Maps scene + một phone bridged pane** ở split (đây là mục tiêu thực tế của người dùng), thay vì đòi hai full native Maps cùng lúc. Cần xác minh ownership contract, native map tiles in pane, touch, native guidance remains active và Home/split switching an toàn.
4. Chỉ sau đó build **DuoFace độc lập one-DEB** phiên bản mới và xuất Sileo cho iPhone X rootless iOS16 đỗ xe để kiểm thử; không đè .90, giữ Dock/YouTube/split/menu/SOLO/seek. Không dùng DEB Omnicar gốc, không copy code/license.
5. Chưa làm bản render native mới trong lượt điều tra này vì không thể chứng minh host/scene lifetime chỉ từ static audit và log hiện tại; hành động sai có thể dừng navigation hoặc crash CarPlayApp. Giữ nguyên baseline, không thử zoom giả.

## Nguồn kiểm tra tiếp
- `sideplay/audit/native12-083-rotation-20261028/OMNICAR_ORIGINAL_NATIVE_MAP_BRANCHES_V2_RUN_40627902229.json`
- `sideplay/audit/native12-083-rotation-20261028/OMNICAR_ORIGINAL_NATIVE_OWNER_V3_RUN_40628918504.json`
- `sideplay/audit/native12-083-rotation-20261028/OMNICAR_ORIGINAL_HOSTED_VC_V5_RUN_40630009621.json`
- `sideplay/audit/native12-083-rotation-20261028/MAPS_NATIVE_SCENE_OWNER_EPOCH_CHECKPOINT_20261028.md`
- `sideplay/native-carplay-scene-v1/DFCarPlayLiveOwnerSnapshot.m`
- `sideplay/native-carplay-scene-v1/DFCarPlayNativeSceneTimeline.h`
- `sideplay/duoface-native-scene-host/DFSceneHost.m`
