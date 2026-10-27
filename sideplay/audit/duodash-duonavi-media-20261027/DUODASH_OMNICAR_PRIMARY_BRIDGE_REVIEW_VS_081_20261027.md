# Quyết định kỹ thuật 27/10/2026 — DuoDash + OmniCar làm đối chứng chính, DuoNavi chỉ lịch sử

**Động lực:** Người dùng yêu cầu bỏ ưu tiên DuoNavi, học cơ chế AppBridge của DuoDash và OmniCar trên nền mã nguồn *độc lập* DuoFace. Đây là **đánh giá bằng chứng đã lưu** và **đọc lại source trên GitHub**; **không phải bản sửa crash**. Không sao chép nguyên dylib, không loại bỏ/né cơ chế giấy phép vendor, không đụng repo OmniCar/carplaydsp, không đóng gói DEB.

## Tài sản nào có mã nguồn thực?

1. **DuoFace độc lập**: source `sideplay/duoface-native-scene-host/DFSceneHost.m` (blob `f2eaf11746235a9a7be26a0d59138a67b1ba257b`) và `DFAppViewportRelay.m` (blob `06be1e13b73f3342a469e4342a53887d7cc08d4f`). Bản đã phát hành .81 trên Sileo, user báo YouTube crash ngay lúc mở; **không có device-PASS**.
2. **OmniCar 1.0.3 NGUYÊN GỐC**: có DEB byte-pinned SHA256 `d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd` ở `chuongnguyen89dn-ui/Omnicar/com.anlai.omnicar_1.0.3_iphoneos-arm64.deb`. Thư mục `Omnicar/src/` chứa **mã tweak addon do dự án viết**, *không phải* source gốc của `OmniCarAppBridge.dylib`. Audit ARM64 thực trong `Omnicar/audit/OmniCar_AppBridge_exact_scene_settings_and_layout_20261023.md` blob `65fe107ccf8cdbc9dfbccc9b3f93f73bf006ddef`, GitHub Actions `39929982072` SUCCESS **static**.
3. **DuoDash 1.1.3 Fullscreen427**: audit dựa trên DEB **REPACK** (SHA256 `ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465`), *không phải* stock DuoDash 1.1.3. Full trace 10 IMP chọn lọc ở `sideplay/audit/duodash-duonavi-media-20261027/ORIGINAL_DUONAVI_VS_DUODASH_REPACK_IMP.json`, SHA blob `e5be6e3f30cba8987830f69e8f97eef3de79fef5`, run `40445716116` SUCCESS static. **Không có source gốc vendor đã kiểm chứng**.
4. **Mã nguồn do chúng ta sở hữu liên quan CarPlay**: `chuongnguyen89dn-ui/carplaydsp/independent-split/runtime/CPSRuntime.m` blob `c7ce35ca63f695101c93549c4683d926e5135632`; đây là **CarPlay Split do chính dự án viết**, KHÔNG phải source của DuoDash vendor. Chứa `CPSSceneHost`, nhưng dùng private hooks toàn cục và thao tác transition nil; chưa chứng minh no-crash trên iPhone nên **chỉ tham khảo, không copy mù**.

## Đối chiếu CHÍNH theo đường gọi / owner

| Giai đoạn | Bằng chứng DuoDash repack / OmniCar original | DuoFace .81 đang làm | Gap / mức chắc chắn |
|---|---|---|---|
| Mở host | DuoDash `DDz2.cnabBuildSceneHostForBid:displaySize:` @0x1b7a0 tạo `SBDeviceApplicationSceneEntity`/`SBAppViewController`, `setIgnoresOcclusions:NO`, `setAutomatesLifecycle:NO`, `setRequestedMode:2`. OmniCar `ABHost.openApp:frame:` có flow host gốc. | `DFSceneSurface.start` dòng 134–168: `setIgnoresOcclusions:YES`, `setAutomatesLifecycle:NO`, layout trước yêu cầu mode2, sau đó poll 350ms. | **Khác cờ occlusion có chứng cứ source/ARM64**; KHÔNG chứng minh riêng cờ YES là nguyên nhân crash. |
| App-side bridge state | DuoDash `CNABUIApp.setBridgeState:width:height:orientation:` @0x1f514 nhận bool+width+height+orientation, quản lý app state. | `DFAppViewportRelay.DFVPReconcile` chỉ reflow `UIWindowScene` nếu thực sự là external scene *và* đo width/height đã gần trùng; không tự định tuyến main-phone scene, không có chứng cứ app nhận geometry. | **Source structural mismatch**; còn thiếu contract/ack; chưa chứng minh ảnh hưởng YouTube cụ thể. |
| Kích thước view ↔ scene | OmniCar `ABHost.layoutPane:` @0xec80 tách physical pane/sceneBox khỏi logical `round(pane/zoom)`, scale và center. | `DFSceneSurface.layoutScene` luôn `round(2×pane)` và UIView transform, không theo zoom policy/sceneBox/ứng dụng. | **Khác chính sách kích thước có chứng cứ**; không kết luận 2× nhất thiết sai trong mọi trường hợp. |
| Cập nhật FBScene | OmniCar `ABHost.layoutPane:` → `sceneHandle` → `sceneIfExists` → `updateSettingsWithBlock:` @0xf048. Block @0xf210 guarded `setFrame:` @0xf248, `setInterfaceOrientation:` @0xf280, `setBackgrounded:NO` @0xf2b8, `setForeground:YES` @0xf30c. | `DFSceneSurface.commitSceneGeometry:` lines 310–352 requests `setFrame:` + foreground YES/backgrounded NO **chỉ khi frame khác**, không sở hữu hướng, không readback ACK; `committedReferenceSize` based on method dispatch. | **Khác atomic policy + recheck có chứng cứ**. Không được giải quyết bằng việc copy nguyên các setter: iOS16 may assert on incompatible Live/foreground transition. |
| Scene ready | DuoDash host splits controller/observer/app state in different modules. OmniCar host embeds separate scene owner. | `DFSceneSurface.pollScene` ready khi scene exists + hosting + attached; chưa chắc actual app renderer accepted. | **Thiếu ACK**; causal to .81 user crash unknown. |
| Focus, media, teardown | DuoDash app-side `setBridgeState` has OFF state; OmniCar maintains per-pane sceneBox/orientation and host state; native teardown needs individual audit. | `DFSceneSurface.stop` mode0/removes host without proven complete remote state restore; AppViewportRelay has no observable renderer ACK. | **Further proof needed**: no exact 1:1 teardown parity yet. |
| Source-owned alternative? | `carplaydsp/independent-split/runtime/CPSRuntime.m` handles scene + restore, but globally hooks `FBScene.updateSettings:withTransitionContext:completion:` and issues private transition updates with `nil`. | Different from .81 `updateSettingsWithBlock:`, but neither method device-certified. | **Do not transplant** without matching iOS16 crash logs and proof of safe ABI. |

## Chứng cứ thiết bị và giới hạn

- User-reported .81: YouTube crashes **at opening**; .77 exact `NSInternalInconsistencyException` SpringBoard Live scene received `foreground = BSSettingFlagNo`. This is **not** proof which actor wrote foreground NO for .81.
- DuoDash audit is REPACK and selected 10 IMPs, not complete vendor graph; OmniCar original is byte-verified DEB but audited static only. Source code owned is **our own extensions/CarPlay Split**, not vendor core.
- The local presence of source-owned `CPSSceneHost` does not establish it is stable: it uses broad FBScene hooks; copying those into DuoFace could increase SpringBoard conflict.
- A one-time .37 YouTube playback success with wrong orientation is not a known-good reference.
- Research report `WHY_ORIGINAL_BRIDGES_WORK_BUT_DUOFACE_CRASHES_20261027.md` on same branch also crosschecks DuoDash and OmniCar (not solely DuoNavi).

## Quyết định được yêu cầu

**Đổi thứ tự tham chiếu:** **OmniCar original (host-frame/sceneBox/lifecycle)** là primary; **DuoDash repack (factory + app-side bool/width/height/orientation IPC)** là secondary; **DuoFace first-party source** là implementation target; **carplaydsp first-party CPSSceneHost** chỉ là code-design cross-check; **DuoNavi** ngừng làm primary, vẫn giữ archival evidence, không xóa dữ liệu. Đây là thứ tự nghiên cứu, không đồng nghĩa dùng OmniCar binary hoặc giấy phép vendor.

**Next GO/NO-GO:** Vẽ đường sự kiện chuẩn original `hostRequest→factory→mode2→scene attached→scene-settings→app-side bridge-state→state accepted→layout/media→teardown`, truy từng producer/consumer và ABI, đánh dấu cạnh chỉ static vs runtime. Xác định trực tiếp .81 host scene/foreground stale writer qua IPS cặp phiên bản hoặc log cùng phiên. Chỉ sửa **một first-party owner module** khi causal chain verified; chạy static/ABI CI rồi test iPhone thực mở YouTube trước video + Maps, split/solo/play, không phá Dock. Không phát hành .82 từ setter guesses.

**Tình trạng lượt này:** GitHub evidence READ, report CREATED, handoff cập nhật; **không** có source runtime edit, build, DEB, Sileo, iPhone test.
