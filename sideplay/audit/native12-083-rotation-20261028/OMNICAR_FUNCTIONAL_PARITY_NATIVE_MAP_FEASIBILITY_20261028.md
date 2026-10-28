# DuoFace có thể làm giống OmniCar không? — Kiểm kê chức năng, native Maps và điểm thiếu thực tế

**Ngày:** 2026-10-28. **Repo thực thi:** `chuongnguyen89dn-ui/Duoface`, branch `feature/duoface-jb-embedded-appbridge-20261020`; before analysis HEAD `7767edbb24539e0a11c527fca49267ab15089d70`.

## Kết luận một câu
**CÓ THỂ xây dựng độc lập cơ chế tương đương OmniCar về kiến trúc chọn app, split, native CarPlay map, quản lý scene/lifecycle; nhưng CHƯA ĐỦ chứng cứ để cam kết Map sẽ hiển thị đúng và dẫn đường liên tục trong DuoFace ở bản hiện tại.** Original có native-owner pipeline; DuoFace .90 chưa có native-pane renderer thực chạy. Không thể coi việc tìm selector hoặc source unit-test là chứng minh hiển thị map trên xe.

## Đã phân tích gì — và phạm vi đúng của từ "toàn bộ"
- Đọc lại output SHA-pinned ORIGINAL OmniCar `com.anlai.omnicar_1.0.3_iphoneos-arm64.deb` SHA256 `d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd`; không sử dụng source/nhánh QA sửa đổi của OmniCar làm bản gốc.
- **6 dylib** và injection plist đã quét ở run [40626272871](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40626272871): `OmniCarSplitScreen` (CarPlayApp/SpringBoard), `OmniCarCarProbe` (CarPlayApp), `OmniCarCore` (SpringBoard), `OmniCarAppBridge` (UIKit), `OmniCarSpeedBubble` (map bundles + CarPlayApp/SpringBoard), `OmniCarStartupScreen` (CarPlayApp/SpringBoard).
- Disassembly/index `OmniCarSplitScreen.dylib` **458 phương thức Objective-C / 10 lớp**, run [40679042884](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40679042884), `OMNICAR_ALL_UI_NATIVE_MAP_CROSSWALK_RUN_40679042884.json`, blob `b4a54156e7e5df5d05f5e9e2eb999d2b98ce7129`. Một số vùng native owner đã quét sâu bằng ARM64/CFString/conditional branch trong run `40627902229`, `40628918504`, `40630009621`. **Lượt này đối chiếu và phân loại lại dữ liệu binary đã chạy, không tự nhận chạy lại unpack/ARM64 scan mới.**
- Đây KHÔNG phải hoàn tất disassembly mọi C/C++/block function của cả sáu dylib. `OmniCarCarProbe/Core/StartupScreen/SpeedBubble` mới có module/filter/string inventory chứ chưa được chứng minh đủ toàn bộ method flow; không dùng kết luận "đã quét sạch 100% mã nguồn".

## Bảng chức năng nguyên bản và độ chứng cứ — kiểm kê từ 458 Objective-C IMP

| Nhóm | Đường gọi/offset ARM64 từ gói gốc | Mức hiểu từ mã gốc | Khác biệt của DuoFace .90 |
|---|---|---|---|
| 1. **Phân biệt CarPlay native** | `SCPCarSplit.isCarPlayApp:` @`0xff20`, `carPlayDeclaration` @`0x100a0,0x100c4,0x10100`; kiểm bundle, fullscreen/hidden, AppBridge | **Static confirmed** branch/CFString; chưa có trace branch của Maps thực tế | Không có route riêng cho native app trước khi gọi phone host |
| 2. **Hai danh sách native/phone** | `publishCarPlayApps` @`0x21b1c`: "app CarPlay cho Settings, app iPhone da chon (App Bridge)" @`0x21c68` | **Static confirmed** hai roster. "Settings" trong original không chứng minh iOS Customize bị thay đổi | Picker chọn bundle chưa được gắn loại scene/role native |
| 3. **Mở app native** | `openApp:slot:` @`0x164d4`: app CarPlay support, pinned slot, already open/floating; `sendLaunch:bundle:tries:` @`0x16e04` kiểm Dashboard `currentBaseViewController`, chờ về Home khi cần | **Static confirmed** quyết định/điều kiện gốc | Chưa có native CarPlay app scene launch/route tương ứng |
| 4. **Ghép view/controller vào ô** | `isAdoptableViewController:` @`0x18b5c` → `adoptViewController:` @`0x18d20` → `adopt:slot:` @`0x1942c`; `applicationInfo`/`proxyApplicationInfo` | **Static confirmed** intent + selected reads. Chưa có runtime ownership permission proof | Native pane adapter chưa có |
| 5. **Lấy scene thật** | `sceneOfViewController:` @`0x1aaf4`, getter `sceneHandle` @`0x1ac64`, `scene` @`0x1ac84` | **Static confirmed** VC↔scene; receiver phụ thuộc VC thật | Read-only scene route/classifier đã có, chưa kết nối UI |
| 6. **Giao diện bản đồ native, frame** | `paneSize:forBundle:` @`0x1b328`, `relayoutAnimated:pushScenes:` @`0x1b44c`, `pushSceneSizes` @`0x1c550` ⇒ `foregroundSceneWithSettings:completion:` @`0x1c738`, `sceneHostView` @`0x1ca04,0x1ca40` | **Static confirmed** native scene size/host controls; chưa biết hai surface đồng thời được CarPlay cho phép | `DFSceneHost.m:780` dùng `initWithApplicationForMainDisplay:`, là iPhone scene, không phải native Maps |
| 7. **Khắc phục kích thước scene sai** | `verifySceneOfPane:expected:retry:` @`0x1cce0`, readback `settings/frame`; conditional background @`0x1d084` → foreground @`0x1d2fc` | **Static confirmed** conditional retry, KHÔNG đồng nghĩa an toàn để luôn background Maps đang dẫn đường | Chưa có owner-aware native frame transaction; không copy recovery hook mù |
| 8. **Ứng dụng vẫn chạy nền** | `detachVC:background:` @`0x1a77c`; `showBackgroundToastFor:slot:` @`0x28c48`: "is running in the background"/"Reopen" | **Static confirmed** semantics UI và background call; không chứng minh native navigation sẽ tiếp tục mọi lúc | Chưa có định nghĩa trạng thái native navigation xuyên Home/split |
| 9. **Bảo vệ scene khi đổi ứng dụng** | `scene:destroyedForViewController:ownScene:` @`0x1ad58` log `0x1aec4` owned destroyed → close pane; `0x1afc4` foreign destroyed → KEEP pane | **Static confirmed** foreign-vs-owned scene check, điều cốt lõi cho Maps | `DFCarPlayNativeSceneTimeline.h` chỉ theo dõi identity/generation, chưa quản lý pane |
| 10. **Ứng dụng iPhone** | `hostApp:inPane:` @`0x3e490`, `com.anlai.omnicar/appbridge.open` @`0x3ea84`; `sendHostFrameForPane:live:` @`0x3dfac` IPC frame | **Static confirmed** tách riêng phone path, KHÔNG dùng để render native map | Phone bridge DuoFace .90 hoạt động và YouTube xoay đúng theo user |
| 11. **SOLO khác nhau theo native/phone** | `soloBundle:` @`0x1e33c`: "app iPhone -> App Bridge toan man" @`0x1e3ac`; native `presentBaseViewController:animated:launchSource:completion:` @`0x1e5b4`, scene native `foregroundSceneWithSettings` @`0x1ea28`, `sceneHostView` @`0x1ebe4` | **NEW focus from archived original:** cả SOLO cũng tách native và phone, không phải shared zoom | DuoFace hiện host cùng route phone cho mọi app, thiếu native SOLO |
| 12. **Dock/usable frame** | `appAreaInParent:` @`0x11dfc` đọc `contentView`, `appDockViewController`, `statusBarInsets`, báo app-area @`0x12388` | **Static confirmed** thực sự xem system chrome geometry, không crop theo số giả | Phải tiếp tục bảo vệ Dock hệ thống .90 |
| 13. **Split/Swap/SOLO/Zoom** | `dividerPanned:` @`0x2d05c`, `dividerPan:state:location:translation:` @`0x2d210`, `swapSlot:with:` @`0x1d494`, `soloBundle:` @`0x1e33c`, `toggleZoomForPane:` @`0x251b0` | **Static confirmed** các hàm/nhánh gốc riêng biệt, không gộp logic | Giữ các tương tác .90; map adapter phải thích ứng khi kéo/tách/solo |
| 14. **Menu + timer** | `setupBarForPane:` @`0x22adc` (Change app, Full screen, Float, Background, Close); `setBarVisible:forPane:` @`0x241fc`; `showRatioMenuForDivider:` @`0x2f614`; `restartTrayTimer` @`0x3bc20` | **Static confirmed** owner/timer khác nhau; không kết luận tất cả nút cùng ẩn | Không phá timer/nút/Logo bản .90 |
| 15. **Hosted fallback KHÔNG phải map** | `SCPHostedAppVC.sceneHostView` @`0xfdbc` trả nil; `applicationInfo` @`0xfdac`, `proxyApplicationInfo` @`0xfdb4` nil | **Machine-code confirmed**. KHÔNG giả vờ biến placeholder thành native scene | Không được bịa placeholder mới để hiển thị Map |

### Điểm chốt riêng: Vì sao OmniCar không cần loại Maps khỏi CarPlay Customize?
- **Đã chứng minh trên binary:** OmniCar **chọn native branch bằng `carPlayDeclaration`**, có native roster, Dashboard app launch, scene/host management; song song AppBridge dành cho phone apps. `soloBundle:` còn có đường SOLO native vs AppBridge rất rõ. Vậy việc "tắt Maps để dùng giao diện iPhone" **không phải tiền đề của thiết kế OmniCar**.
- **Chưa chứng minh:** original luôn giữ trạng thái CarPlay Customize của mọi máy và có thể render chính xác native Maps + iPhone YouTube đồng thời trên màn xe người dùng. Không thấy hard-coded `CPWindow` hoặc `CPMapTemplate` trong string scan cả 6 dylib, nhưng thiếu literal không đồng nghĩa không dùng private app-scene owner. Không khẳng định OmniCar tự tạo/cấp entitlement của ứng dụng Google Maps.
- Apple official: `CPTemplateApplicationScene`/ `CPWindow` chỉ navigation app nhận cửa sổ vẽ bản đồ, thuộc scene app navigation; không được lấy `CPWindow` app khác làm tài sản DuoFace. https://developer.apple.com/documentation/carplay/cptemplateapplicationscene ; https://developer.apple.com/documentation/carplay/cpwindow . `CPWindow` base map mặc định không nhận tap/drag; UI split/controls nếu có thuộc lớp giao diện/host khác.

## Dữ liệu THẬT từ máy DuoFace (không nhầm là OmniCar runtime proof)
- `Duoface/main:sideplay/log/DuoFaceCarPlayOwner-4C5C8ADB-EE69-458A-B664-1753AB90C797.jsonl`, 46 snapshots / 141845 bytes. 1-based `#41–42` Google Maps thật `DBApplicationSceneViewController` + `FBScene` bundle `com.google.Maps`, CarPlay PID 68776; `#43–44` **cùng controller + host/window** đổi sang `com.duoface.native.scenehost`; `#45–46` controller vắng mặt. Không đủ bằng chứng native Maps bị hủy hay two-owner coexistence; 0 snapshots có hai owner cùng lúc.
- Có mã source-only `DFCarPlayLiveOwnerSnapshot.m`, `DFCarPlayNativeSceneTimeline.h`, CI [40680676803](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40680676803) SUCCESS Foundation + iOS16 ARM64 + .90 no-diff guard; **không phải một native map pane đã chạy**.
- **Correction to earlier overly strict gate:** User chỉ cần **MỘT** native Maps scene + **MỘT** phone YouTube scene trong hai ô. Không nhất thiết hai native Maps FBScene chạy song song. Nhưng vẫn phải chứng minh map host tồn tại và render được khi DuoFace split hiển thị mà CarPlayApp owner không thay thành DuoFace.

## Phân loại khả thi
| Mục tiêu | Đánh giá dựa trên dữ liệu | Điều kiện còn thiếu |
|---|---|---|
| UI split, divider, SOLO, swap, menu, startup gần OmniCar | **Có thể tái tạo bằng first-party source; một phần đã có** | Device comparison từng luồng, không copy binary |
| Bỏ yêu cầu tắt/ẩn Maps trong danh sách CarPlay | **Đúng hướng về mặt kiến trúc — native-first route** | Chưa device-confirm toàn bộ behavior khi Maps enabled |
| Map tiles đúng native Maps bên cạnh YouTube | **Có cơ sở kỹ thuật nhưng chưa xác nhận làm được với CarPlayApp/iOS 16.7.16 hiện tại** | Host scene + adoption/ownership + appearance continuity + Map tiles on parked vehicle |
| Điều hướng giữ hoạt động khi đổi Home/DuoFace | **Có cấu trúc bảo vệ foreign owner, chưa kiểm chứng tính năng** | Device log khi navigation liên tục, scene transitions không teardown |
| Cam kết 100% không crash và không cần update .90 | **Không thể cam kết trước thử** | Build rootless Sileo + on-device crash/rotation/seek tests |

## Các bước thực tế tiếp theo, không làm mò
1. Tiếp tục **native path read-only** từ CarPlayApp với Google Maps đã hiển thị và vẫn enabled trong CarPlay Customize. Log process/scene role/VC/window/hostView identity, owner generation, foreground, bounds, actual native map tiles khi trình DuoFace mở; không tự terminate/disable Maps.
2. Đo **một** native Maps + **một** phone YouTube slot thay vì đòi hai Maps native. Xác minh VC có thể được CarPlay system host giữ hợp lệ trong container native split. Không clone/steal foreign CPWindow, không đăng ký giả quyền điều hướng.
3. Chỉ khi hoàn tất phép đo, xây native-pane adapter first-party tách khỏi existing `DFSceneHost` phone path. Preserve .90 six protected files, Dock/chrome/preset/ratio/seek. Không thêm zoom hack.
4. Kiểm thử source/compile riêng, đóng một DEB rootless có manifest/SHA, phát hành qua Sileo theo workflow đã xác minh, **parked CarPlay QA**: Maps map tiles, Maps icon vẫn có, dẫn đường tiếp tục chuyển app, YouTube đúng chiều/không crash, touch/split/solo/swap/zoom.
5. Không lấy static binary grep làm bằng chứng MAPS-PASS. Nếu native host không thể render trong split, báo rõ giới hạn đó; lựa chọn first-party independent map rendering chỉ khi có nguồn map/điều hướng hợp lệ (không giả UI Maps).

## Trạng thái thay đổi lượt này
- **Chỉ phân tích/ghi chép; KHÔNG sửa/chạy runtime, không build hay publish DEB.** Nguồn đã rà soát: original split 458-method JSON + V2/V3/V5 machine reports + DuoFace .90 source + device owner log + official CarPlay docs.
- Báo cáo này là *functional audit bổ sung* từ các binary disassembly đã có, không tuyên bố đã full-decompile mọi dylib.
