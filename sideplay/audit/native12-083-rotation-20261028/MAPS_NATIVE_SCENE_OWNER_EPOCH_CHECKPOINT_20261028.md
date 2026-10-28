# DuoFace native Google Maps — quyền sở hữu, FBScene tồn tại và vòng đời theo epoch (28/10/2026)

## Nguồn và điều không được phá
- Repo `chuongnguyen89dn-ui/Duoface`, nhánh `feature/duoface-jb-embedded-appbridge-20261020`, baseline trước thay đổi `c61fe37ed6b7f6c5dbd8b097556dd944ed4c1532`.
- Người dùng xác nhận **DuoFace .90 YouTube xoay đúng chiều trên xe**. Giữ nguyên chính xác sáu file host/player/Chrome/lifecycle/Dock bằng CI diff guard. Không sửa `DFSceneHost.m` hoặc áp hệ số zoom giả cho Maps.
- Đọc kỹ thuật từ bản OmniCar gốc đã SHA-pin tại `OMNICAR_ALL_UI_NATIVE_MAP_CROSSWALK_20261028.md`; 458 Objective-C methods thuộc split dylib; không sao chép mã hoặc license bên thứ ba.
- Log gốc *trên máy thực*, nguồn `Duoface/main:sideplay/log/DuoFaceCarPlayOwner-4C5C8ADB-EE69-458A-B664-1753AB90C797.jsonl`, blob SHA `ffe9c6e6f0a0382426cf3dd78fd3da45d5a3fecc`, 46 dòng JSONL / 141845 bytes. Đã đọc và parse cả 46 dòng từ GitHub. **Đính chính lịch sử**: nếu đếm từ **1**, Maps ở **#41–#42**, DuoFace ở **#43–#44**; #40/#41 và #42/#43 là các chỉ số zero-based nhầm thành số thứ tự.

## Kết quả xác minh từ snapshot thật — cùng PID 68776 / cùng controller
| Snapshot (1-based) | UTC 28/10/2026 | DBApplicationSceneViewController | FBScene host thực |
|---|---|---|---|
| #41 | 05:02:09 | `0x5d0a14140`; hostView `0x5d0a15160`, window `0x5d0d31600` | `com.google.Maps`, `Car[2-3]:com.apple.CarPlayTemplateUIHost:com.google.Maps` |
| #42 | 05:02:37 | cùng controller/host/window | `com.google.Maps` |
| #43 | 05:03:07 | cùng controller/host/window | **đổi** sang `com.duoface.native.scenehost`, `Car[2-3]:com.apple.CarPlayTemplateUIHost:com.duoface.native.scenehost` |
| #44 | 05:03:37 | cùng controller/host/window | `com.duoface.native.scenehost` |
| #45 | 05:04:07 | controller không còn xuất hiện trong cây controller được duyệt | **Không kết luận scene bị hủy** |
| #46 | 05:04:37 | vẫn không thấy controller | **Không kết luận scene bị hủy** |

- Tại #41–44, `sceneHostViewStatus=present-UIView`, `nativeSceneStatus=present`, `nativeSceneClass=FBScene`, `nativeApplicationInfoStatus=present`; các cờ giới hạn quan sát scenes/windows/controllers đều false. Có native Maps scene thật, không phải Dashboard map widget.
- Đối chiếu 46 snapshot: **0 snapshot** đồng thời nhìn thấy một `DBApplicationSceneViewController` Maps hợp lệ và một owner DuoFace hợp lệ. Việc thay bundle/scene ID trên cùng controller là **rebind quan sát được**, không có bằng chứng hai native app FBScene xuất hiện trong hai ô cùng lúc, càng không chứng minh một map surface có thể được đưa vào pane độc lập.
- Getter scene/client/process chain nếu chưa lấy được `nativeSceneProcessBundleIdentifier` thì để unresolved; không suy diễn app process chỉ từ tên widget hoặc tên bundle.
- Chủ sở hữu window/host thuộc `CarPlayApp` Dashboard; DuoFace không được giả quyền sở hữu FBScene/CPWindow ngoài tiến trình hay đóng điều hướng khi chuyển Home/split.

## Mã first-party hoàn thành và đã kiểm thử nguồn
- `sideplay/native-carplay-scene-v1/DFCarPlayNativeSceneTimeline.h`: pure Foundation state reducer. Theo dõi `probeSession`, PID, tick, owner identity `controllerPointer + bundle + FBScene identifier + sceneHostViewPointer`, generation tăng khi rebind, reset sau restart process/session; phân biệt `not-observed-not-proof-of-destruction` với lifecycle destroy; fail-closed khi thiếu dữ liệu, không bao giờ trả `canAttachPane=true`.
- `sideplay/native-carplay-scene-v1/DFCarPlayLiveOwnerSnapshot.m`: nối reducer vào observer **đã tồn tại trong CarPlayApp**, JSONL schema 3 với `nativeSceneTimeline`; không tạo window, scene, activation, foreground/background, không thao tác Dock hoặc giao diện video.
- `sideplay/native-carplay-scene-v1/tests/native_carplay_scene_timeline_runtime.m`: test chạy lại chính xác chuỗi observed #41–46; kiểm chứng Maps→DuoFace rebind, generation monotonic, trạng thái mất quan sát, partial scan, restart PID/session, giả mạo bundle process, 2 host chỉ tính là candidate, vẫn cấm attach.
- CI `.github/workflows/duoface-native-carplay-scene-identity-source-20261028.yml`: **run [40680676803](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40680676803) SUCCESS**, job `122790290198`; log có `DUOFACE_CARPLAY_NATIVE_MAPS_SCENE_TIMELINE_46_LOG_SEQUENCE_PASS`, `DUOFACE_NATIVE_MAPS_OWNER_REBIND_GENERATION_TIMELINE_PASS`, `DUOFACE_090_WORKING_ORIENTATION_CHROME_MAPS_DOCK_BASELINE_UNCHANGED_PASS`. macOS Foundation executable + iOS16 ARM64 syntax PASS, guard nguồn .90 PASS.
- Hạn chế rất quan trọng: Đây là **test reducer với bản ghi điển hình tái dựng từ log đã đọc**, **không phải** capture trên thiết bị bằng bản observer schema 3 mới. Cũng không phải phép thử render Maps trong pane. `simultaneousPaneRenderingProven=false` / `canAttachPane=false` cố ý.

## Điều kiện duy nhất trước khi nối native vào từng ô
1. Phát hành bản **chẩn đoán riêng qua Sileo** nếu cần đo trực tiếp schema 3; chỉ sau khi có package SHA/CI/publisher. Không thay bản DuoFace .90 đang hoạt động. Trên thiết bị đang đỗ, giữ Google Maps CarPlay dẫn đường, mở DuoFace split, chuyển qua lại Home và Maps; xuất log JSONL mới.
2. Đối chiếu live PID/session/generation/scene identifier/view host/window qua các chuyển trạng thái. Thu nhận **ít nhất một snapshot đồng thời hai native scene hợp lệ nếu thực tế có**, hoặc kết luận chính xác giới hạn host. Không biến candidate thành khả năng hiển thị hai pane khi chưa đo hình/tiếp nhận tương tác.
3. Nếu xác minh hỗ trợ đồng thời và lifecycle không làm đứt navigation, mới viết `DFCarPlayNativePaneAdapter` độc lập, kiểm tra owner/role/generation theo từng slot, chỉ attach theo API/transaction thực tế đã đo. Nếu không, giữ Maps nguyên owner native và dùng UI riêng cho phone scene, **không steal/reparent CPWindow, không copy vendor code**, không tắt native navigation.
4. QA sau cùng bằng **DEB mới qua Sileo**, xác minh map tiles thật trong pane, điều hướng khi switch, Dock, split/solo/swap, YouTube .90 xoay đúng từ đầu, crash/safe-mode.

**Trạng thái:** Owner native của Maps và rebind tuần tự đã xác minh qua log thực. Timeline observer nguồn đã commit + CI source PASS. Coexistence render, native pane bridge và thử thiết bị cho code mới **chưa xác minh**. Không phát hành DEB hay Sileo bằng báo cáo này.
