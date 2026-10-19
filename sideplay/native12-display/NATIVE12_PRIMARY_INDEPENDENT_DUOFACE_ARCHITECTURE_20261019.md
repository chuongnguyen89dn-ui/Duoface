# Quyết định kiến trúc — Native12 là sản phẩm, SidePlay chỉ là khung sườn tham khảo

## Bổ sung quyết định mới: giữ SidePlay CHỈ để host app/CarBridge (2026-10-19)

Yêu cầu mới nhất của người dùng **điều chỉnh** chủ trương cũ “gỡ toàn bộ SidePlay runtime”: do lõi Native12 trước đây có giấy phép gắn với CarPlay, người dùng muốn **tạm thời hoặc lâu dài giữ đúng phần SidePlay đã hoạt động để host ứng dụng/CarBridge lên CarPlay, bao gồm kiểm tra cấp phép hợp lệ nếu SidePlay có**, sau đó **loại bỏ mọi SidePlay UI/ratio/picker/Style/HUD/menu** khi đã có bản thay thế từ Native12. Đây là phương án hybrid **DuoFace product + SidePlay host-only provider**, không có hai chủ UI. Chỉ giữ khả năng kết nối đã được thử; không cố gỡ hay vô hiệu hóa giấy phép bên thứ ba.

**Sự thật đã xác minh:** trong DEB SidePlay 1.0.4-1 không phát hiện được một “CarPlay license dylib” tách riêng được chứng minh. Gói có `SidePlay.app` scene delegate `SPCarSceneDelegate`, `SidePlay.dylib` (`SPDash/SPPane`), và các module UI/HUD/phụ khác. Các selector `serviceBlocked/serviceChecked` tồn tại, nhưng không đủ để khẳng định đó là giấy phép. **Không được cắt nhị phân vendor hoặc bỏ dependency chỉ dựa trên suy đoán**. Nếu SidePlay không cấp API host-only chính thức, sử dụng **adapter gọi có kiểm soát những selector host/scene đã đo từ DEB**, giữ package hợp lệ như dependency cho tới khi thay thế/không cần đến nó; không chỉnh giấy phép hay watchdog.

### Bước triển khai thực tế M1 (đã sửa mã, chưa tuyên bố nghiệm thu xe)

- Branch riêng `feature/duoface-native12-host-only-bridge-m1` **fork QA11** (QA11 Sileo vẫn giữ nguyên). Source `sideplay/host-only/DFSPSceneHostBridge.h/.m` chỉ tương tác 5 method SidePlay 1.0.4 đã tìm trong ObjC ABI: `SPDash.panes`, `SPPane.view`, `SPPane.appViewController`, `SPPane.loadApp:`, `SPPane.unloadApp`. **Không import** lớp SidePlay chooser/style/ratio/menu, không gọi license/service API, không nhúng vendor binary.
- `sideplay/sileo-qa/Tweak.xm`: ở đường **render hai ô**, trạng thái app và CGRect scene được chuyển qua `DFSPSceneHostBridge`; kiểm liveness owner/window, release lease khi disconnect. Phần App picker, Close, ratio/Style vẫn đang gọi SidePlay trong QA11, chưa tuyên bố thay hay xóa được. `Makefile` đã thêm module mới.
- `sideplay/host-only/validation/check_host_only_bridge_m1.py` kiểm đúng ranh giới, version QA11 không đổi, audit selector; `.github/workflows/sideplay-host-only-m1-compile.yml` biên dịch iOS16 rootless **không tạo DEB hoặc cập nhật Sileo**, ghi `sideplay/host-only/validation/M1_CI_RESULT.txt` nếu compile PASS thực. Không tự suy từ việc commit mã là build PASS.
- Đã chứng minh ABI host tại SidePlay arm64 selector index `sideplay/native12-display/audit/SIDEPLAY_SPLIT_OWNER_SELECTORS.json` và audit ba gói trước; Native12/HUD8/Visual12 là chuẩn toàn bộ UI.


**Sửa lại phân định M1 sau kiểm tra ABI:** `SPPane.loadApp:` có type encoding `v24@0:8@16`: đây chỉ là `id`, **chưa biết đó là `SBApplication`, `NSString` hay kiểu khác**. Từng có prototype M1 truyền trực tiếp `NSString *`, đã gỡ hẳn khỏi `DFSPSceneHostBridge.h/.m` **trước khi build/triển khai**. M1 chỉ đọc 2 scene và không gọi load/unload. Lượt CI duy nhất được dùng để kiểm `make clean all`; không được xem đó là test CarPlay hoặc cấp phép.

### Danh mục thay từng chức năng — chỉ cắt code SidePlay sau nghiệm thu

| Thứ tự | Chức năng | SidePlay còn phải dùng | DuoFace cần sở hữu | Trạng thái |
|---|---|---|---|---|
| M1 | Hai scene sống, app-present, geometry đọc lại | `SPDash.panes`, `SPPane.view/appViewController` | Native12 visual shell nhận trạng thái qua host-only adapter | **ĐÃ SỬA CODE READ-ONLY; CI/device chưa rõ** |
| M2 | App picker + chọn ứng dụng | `SPPane.loadApp:` chỉ được gọi sau khi xác minh đúng kiểu đối tượng tham số; chưa gọi ở M1 | Picker UI, danh sách app, menu Native12; bỏ `SPDash.showPickerForPane` | Chưa làm |
| M3 | Close, swap và kéo tỷ lệ | `SPPane.unloadApp`, hosted scene views | Native12 split owner, gesture/logo/ratio, slot order; bỏ `paneRequestsClose/Swap`, `SPDash.setRatio/layout` khi ổn | Chưa làm |
| M4 | Dock/Normal/Zoom | CarPlay scene/window do iOS + host SidePlay hoạt động | Native12 AppDock/window/chrome policy; đo controller thật trên xe trước khi thay | Chưa đạt nghiệm thu |
| M5 | Style, 8 layouts, viền, HUD8, cấu hình | Chỉ app scene hosting | Native12 UI và HUD8 source-owned, không SidePlay HUD/Style/menu | Chưa làm |
| M6 | Dọn phụ thuộc UI SidePlay | App/CarPlay bridge hợp lệ **nếu vẫn cần** | Bỏ 100% SidePlay GUI/HUD hooks/asset/interface, kiểm clean install và giấy phép được giữ nguyên | Chưa làm |

**Điểm dừng kỹ thuật:** SidePlay package gốc vẫn có giao diện tích hợp trong cùng `SidePlay.dylib`; **chưa có source độc lập hoặc API được kiểm chứng để đóng gói chỉ “CarPlay license”**. Không được nói đã cắt nhị phân gốc; chỉ có thể thay owner DuoFace từng chức năng và chặn UI vendor có chọn lọc cho đến khi đủ bằng chứng/giải pháp được phép. Mọi milestone phải test trên xe thực, nhất là Dock, scene và hai ứng dụng.

---


Ngày ghi: 2026-10-19. Nguồn yêu cầu mới nhất của người dùng: “Tại sao ta vẫn còn phụ thuộc SidePlay? Bạn biết Native12 là một app mạnh hơn hoàn toàn không? SidePlay chỉ là khung sườn để ta không phải dựng lại từ đầu thôi.”

## 1. Quyết định bắt buộc, thay thế hướng “SidePlay host lâu dài”

- **DuoFace độc lập** là sản phẩm duy nhất. **Native12 + HUD8/Visual12** là chuẩn hành vi, giao diện, lifecycle, thanh Dock, màn chia, logo, app picker, ứng dụng iPhone và cấu hình. SidePlay 1.0.4 chỉ giúp tiết kiệm giai đoạn nghiên cứu khởi tạo CarPlay, không phải thành phần runtime của sản phẩm sau cùng.
- **Không giữ** `com.sideplay` làm phụ thuộc vĩnh viễn, không giữ `SPDash`/`SPPane` làm chủ quản giao diện và tỷ lệ, không giữ SidePlay app picker/Style/menu, scene delegate, riêng nếu mã thay thế đã có nghiệm thu. Phần đã thay phải **xóa khỏi bản độc lập**, không chỉ `hidden=YES` hoặc gọi `%orig`.
- **Không sao chép** dịch vụ/giấy phép/watchdog bên ngoài. Native12 trong gói tham chiếu có `CBBridgeManager` ghép host và watchdog giấy phép, nên không lấy nguyên nhị phân/lớp đó làm lõi sản phẩm. Đọc API/hành vi để viết owner độc lập của chính DuoFace. Giữ các bản Native12/HUD8 và QA11 trên Sileo hiện có như nhánh so sánh/rollback cho đến khi thay thế thực sự chạy.
- **Không tự động bỏ Depends hoặc uninstall SidePlay trên bản QA11 hiện tại**: runtime vẫn yêu cầu `SPDash`/`SPPane`. Gỡ sớm sẽ làm ứng dụng CarPlay không chạy. Loại phụ thuộc là tiêu chí nghiệm thu **sau** khi host/scene/split/picker mới đã được build và thử máy.

## 2. Hiện trạng đã xác minh, không nhầm với kế hoạch

- Repo: `chuongnguyen89dn-ui/Duoface`; nhánh QA đang phát hành `feature/duoface-qa11-restore-native-dock-split-menu`, HEAD artifact `d49fa099f3c100607d1e7e6fd1f35922f34eb01c`; source `sideplay/sileo-qa/control` blob `e708367feb9537636454f843ae9c2e91db45ccec` ghi `Package: com.duoface.sideplaydisplay`, `Version: 0.1.9~native12dock11`, **`Depends: ... com.sideplay (>= 1.0.4-1)`**.
- `sideplay/sileo-qa/Tweak.xm` blob `b07cc3eda565d9e982452fbf959aa8b852182337` khai báo `SPDash`/`SPPane`, hook `SPDash`, điều khiển `[manager setRatio:]`/`[manager layout:]`, picker `[manager showPickerForPane:]`, Style `[manager layoutChooser]`. Đây là hook vào hệ thống SidePlay, KHÔNG phải app host DuoFace sở hữu.
- `sideplay/native12-display/DFSPNative12Host.m` blob `31f311f085d89c46549e2030df70f27b24c4cca0` chỉ điều chỉnh frame của `contentRoot` trong cửa sổ mà SidePlay cung cấp. Tên Native12Host **không có nghĩa đã tạo/host ứng dụng độc lập**.
- QA11 tweak hiện chỉ có `DuoFaceSidePlayDisplayQA.dylib` + visual frame/pill + Dock helper; DEB reference `native12+speed8compact` có 8 Mach-O và ứng dụng iPhone riêng, 1.385 method Objective-C/66 class; SidePlay gốc 7 Mach-O 863 method/38 class; QA7 1 dylib 110 method/4 class. Đây chỉ là inventory, không phải phần trăm tương đương.
- Native12 reference: `CBWindow`, `CBBridgedSplitApp`, `CBBridgeManager`, `CBDashboardSettings`, `CBMultitaskingOverlayView`, `CBDividerView`, `CBSlotPillView`, `DFSpeedNativeHUD` và apple `DBAppDockViewController`/`CARAppDockViewController`. Đặc biệt hai appDock controller do Apple tạo không thể “port ảnh” để thay thế chủ sở hữu thật.
- Sileo công khai đã xác minh QA11 bản `0.1.9~native12dock11` qua `chuongnguyen89dn-ui/carplaydsp:main:release-checkpoints/qa11-native12dock11-pages-verified.txt`, run `39185194359`, SHA `0d20390c560452b0c68c9311ae3c58a48bc9d3e7528de1b130c6bca58c87c1b9`. **Chưa đạt nghiệm thu thực tế** về trái Dock, tỷ lệ, menu và scene theo phản hồi QA10; không nhận mặc nhiên QA11 sửa xong.

## 3. Bảng owner mục tiêu (KHÔNG đồng sở hữu giao diện)

| Phân hệ | QA11 hiện tại | DuoFace độc lập mục tiêu | Tiêu chí bỏ SidePlay |
|---|---|---|---|
| Bootstrap CarPlay | `SidePlay.app`/`SPCarSceneDelegate` | Scene/connection dispatcher do DuoFace sở hữu | Connect/disconnect, Respring, reconnect chạy trên xe |
| Host app iPhone | `SPDash`/`SPPane` và các app scenes | DuoFace `SceneHost` tự mở/quản lý app không được CarPlay hỗ trợ | 2 app thật, touch, audio, orientation, foreground, exit |
| Cửa sổ/geometry | SidePlay window + `DFSPNative12Host` crop root | Native12-equivalent `CBWindow` policy + owner riêng (không import license) | Không che dock Apple, Normal/Zoom/rotation ổn định |
| Split/ratio/logo | `SPDash.setRatio/layout` + overlay `DFSPNativeFrame` | DuoFace split owner + divider/pan/hold có một chủ quản | Kéo/đảo/preset + layout ổn định, không lộ thanh SidePlay |
| App/Style picker | SidePlay `showPickerForPane/layoutChooser` | Native12-equivalent `CBMultitaskingOverlayView`/picker do DuoFace sở hữu | Không còn SidePlay modal, không chồng pill/logo |
| HUD8/cài đặt | QA thiếu hoàn chỉnh, SidePlay có HUD riêng | Native12/HUD8 source-owned overlay + own settings | Chỉ một HUD, hoạt động sau đóng scene, không chứa SidePlay relay |
| Packaging | `Depends: com.sideplay`, hook `SP*` | Package ID mới/độc lập, không Depends vendor | Thử cài sạch sau tháo SidePlay, không thiếu class và không crash |

## 4. Trình tự thay thế (không ghép hên xui)

1. **Đọc đúng mẫu Native12/HUD8, Visual12 và bản QA11 đã kiểm chứng** ở `sideplay/audit/qa7-vs-native12-methods-20261018/method-index.json` và `sideplay/audit/system-sideplay-vs-native12-hud8-20261018/FUNCTION_CLASS_CROSSWALK.json`; ưu tiên source kiểm chứng so với phỏng đoán từ selector. Xác minh class, UIView hierarchy, tiến trình CarPlay, callback, lifecycle và thứ tự owner.
2. **Triển khai scene/app hosting do DuoFace sở hữu** ở nhánh làm việc tách biệt, dùng SidePlay chỉ làm tài liệu tham khảo cho phần bootstrap. Không dùng `SPDash` dưới adapter mới; không clone `CBBridgeManager` có license.
3. Thay hoàn chỉnh `SPDash/SPPane` bằng split controller/host riêng, bao gồm gestures và 2 slot; sau khi on-device pass mới cắt mã cũ.
4. Chuyển toàn bộ Native12 window geometry/App Dock, picker/Style, 8 presets, viền tương tác, fullscreen, HUD8 và iPhone settings theo từng lớp với kiểm thử; **một owner cho mỗi UI/gesture/scene**.
5. **Build độc lập qua GitHub Actions**: `dpkg-deb -f` không có `com.sideplay` Depends, kiểm `nm/strings` không có gọi runtime `SPDash`/`SPPane`/SidePlay bundles; thử uninstall SidePlay và cài standalone trên thiết bị tham chiếu. Nghiệm thu xe thật Normal Dock có đồng hồ và app icons, tỷ lệ chia kéo được, picker không lộ thanh cũ, scene không exitmode, ứng dụng không đen.
6. Chỉ khi hoàn tất mới cập nhật package Sileo độc lập. Không sửa/ghi đè stable Native12/HUD8 và không cắt QA11 trên Sileo khi sản phẩm mới chưa sẵn sàng.

## 5. Điều chưa rõ và cần kiểm nghiệm

- Native12 reference binary có nhiều selector, nhưng không có chứng cứ toàn bộ source tương đương host app đã sẵn sàng để lấy nguyên. Chuyển toàn bộ UI khác với port app scene host, công việc khó nhất.
- CarPlay Dock là hệ thống Apple; giữ vùng/đúng window owner khác với vẽ sidebar. Không hứa lập tức hiện chỉ nhờ thay `windowLevel` hoặc lề 64pt.
- Không có thay đổi mã runtime, build, Sileo, xóa package ở checkpoint quyết định này. Chỉ cập nhật yêu cầu/kiến trúc có bằng chứng và bước tiếp theo.
