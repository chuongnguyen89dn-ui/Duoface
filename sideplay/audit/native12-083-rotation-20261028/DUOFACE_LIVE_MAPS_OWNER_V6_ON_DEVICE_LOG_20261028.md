# 2026-10-28 — Đã đọc log V6 thực địa: Dashboard host có thật, Maps scene owner CHƯA xác định

## Nguồn chính xác (không suy đoán)
- GitHub repo `chuongnguyen89dn-ui/Duoface`, **nhánh main**, upload commit [78bccd3c85be5a13c644b1360ab208296ad15514](https://github.com/chuongnguyen89dn-ui/Duoface/commit/78bccd3c85be5a13c644b1360ab208296ad15514) lúc 2026-10-28 04:42:09 UTC.
- File JSONL gốc: [sideplay/log/DuoFaceCarPlayOwner-D48F4C0E-A72B-4621-ABA3-36DF83CFF037.jsonl](https://github.com/chuongnguyen89dn-ui/Duoface/blob/main/sideplay/log/DuoFaceCarPlayOwner-D48F4C0E-A72B-4621-ABA3-36DF83CFF037.jsonl); Git blob `f38eb00d`, 34,008 bytes; 3 dòng JSON hợp lệ.
- Source phát sinh log: `sideplay/native-carplay-scene-v1/DFCarPlayLiveOwnerSnapshot.m` trên nhánh `feature/duoface-jb-embedded-appbridge-20261020` (phiên bản read-only). Không cần suy diễn hành vi runtime từ tên một class.

## Số liệu quan sát được
| Snapshot | Giờ Việt Nam (UTC+7) | CarPlay PID | DBApplicationScene VC pointer | sceneHostView pointer |
|---|---|---:|---|---|
| 1 | 2026-10-28 11:39:58 | 68379 | `0xb8eba5ed0` | `0xb8ecab6d0` |
| 2 | 2026-10-28 11:40:27 | 68379 | `0xb8e911950` | `0xb8e912410` |
| 3 | 2026-10-28 11:40:57 | 68379 | `0xb8e813bc0` | `0xb8e80d090` |

Tất cả thuộc cùng `probeSession=E17A0D34-2059-4070-AF13-C2F1853B34B0`, `process=CarPlay`, `bundle=com.apple.CarPlayApp`, PID 68379. Mỗi snapshot có **2 UIWindowScene** foreground-active, **21 UIViewController**, 9 UIWindow, `limitedScenes=0`, `limitedControllers=0`, `limitedWindows=0`.

Hai scene UIKit có vai trò `UIWindowSceneSessionRoleCarPlay`:
- `statusbar-Car[2-3]`: `DBStatusBarWindow` 45×240 và `UITextEffectsWindow`.
- `DBDashboard-Car[2-3]`: Dashboard `UIWindow` 427×240, root `DBDashboardRootViewController`, `DBDashboardHomeViewController` bounds 382×240; **Dock/sidebar thuộc scene cửa sổ riêng**, không được crop/giả định là content native Maps.

**Có 3 `sceneHostView` hiện hữu, tất cả `_UIScenePresentationView` gắn vào Dashboard UIWindow**:
1. `DBApplicationSceneViewController`, `sceneHostViewStatus=present-UIView`, frame/bounds **427×240**, `viewSceneIdentifier=DBDashboard-Car[2-3]`; `hasSceneSelector=1`, `hasApplicationInfoSelector=1`, `hasSceneHandleSelector=0`. Object VC và host view **thay đổi ở cả 3 snapshot**, nhưng frame giống nhau. Điều này có ý nghĩa quản lý vòng đời; **không được cache pointer cũ/giả định duy nhất một VC luôn tồn tại**.
2. `DBMapsNavigationWidgetViewController`: host view **179×224**, Dashboard scene. Đây là widget bản đồ trong Dashboard, **không phải bằng chứng Maps app scene**.
3. `DBMapsWidgetViewController`: host view **179×69.5**, Dashboard scene. Đây cũng là widget, không thể làm host cho bản đồ điều hướng toàn cảnh.

18 controller còn lại `sceneHostViewStatus=selector-missing`. Các scene, cửa sổ và controller khác ổn định giữa 3 bản ghi; `DBApplicationSceneViewController` pointer và host pointer là hai trường thay đổi (ngoài UTC).

## Kết luận theo mức bằng chứng
- **ĐÃ XÁC MINH:** Máy thực chạy V6 đúng trong `com.apple.CarPlayApp`, không chỉ build CI. `DBApplicationSceneViewController` thực có `_UIScenePresentationView` trong Dashboard, và host controller được thay mới trong khoảng quan sát; Dock/sidebar native được phân scene riêng. Đây là tiến triển thực chứng so với suy đoán `SCPHostedAppVC` placeholder trên original OmniCar V5.
- **CHƯA XÁC MINH:** `DBApplicationSceneViewController` ở từng thời điểm chứa scene **Apple Maps** hay DuoFace/ứng dụng khác. `viewSceneIdentifier` và `sceneHostViewScene` đều là *Dashboard UIKit scene*, **không phải identity của hosted FBS application scene**. Log chưa gọi/ghi lại kết quả getter `scene`, `applicationInfo` hay bundle identifier của **hosted app**; cũng không ghi state Maps navigation. Không có chứng cứ rằng một native Maps view có thể chuyển sang một ô khi vẫn giữ dẫn đường không gián đoạn.
- **Bẫy cần tránh:** `mapsNativeOwnerProven=false` **được hard-code** trong source V6 để ngăn suy đoán, không phải phép thử trả lời Maps có tồn tại hay không. `present-UIView` của dashboard widgets không có nghĩa chúng là native Maps full-screen scene; `frame=427×240` không được dùng làm lý do tự scale/crop phần Dock.
- **Không thấy lỗi crash trong 3 JSONL snapshot này**, nhưng đây không phải crash-report và không chứng minh toàn bộ máy không crash. Các `.ips` cũ trong `main/sideplay/log` có timestamp trước đợt 11:40 (ví dụ 08:32).

## Bước tiếp đúng kỹ thuật (KHÔNG bắt chước license vendor, không thử zoom %)
1. Bổ sung **cùng probe read-only hiện có**, không tạo thêm tweak/app mới: giới hạn chỉ với `DBApplicationSceneViewController` và `DBMapsNavigationWidgetViewController`, kiểm tra Objective-C getter ABI và đọc kết quả `scene`, `applicationInfo` nếu thực sự là object getter 0 đối số; ghi **class, identity, app bundle ID nếu xác định được an toàn, scene ID**, quan hệ với `sceneHostView`, cùng thời điểm thay thế VC. Không gọi private setters hay lifecycle.
2. Khi có bằng chứng **native Maps hosted scene** cùng app bundle/owner generation, đối chiếu log khi mở Maps gốc → DuoFace split trong lúc dẫn đường; phân biệt native app scene với Dashboard widget, xử lý controller bị đổi owner/scene.
3. Chỉ sau đó mới lập adapter native độc lập có kiểm tra scene/handle/lifecycle, giữ Dock hệ thống và bảo toàn DuoFace engine **.83**. YouTube orientation vẫn là vấn đề riêng. Không phát hành lại giải pháp `.85` scale 80%.
4. Đừng ghi `NATIVE_MAPS_OWNER_VERIFIED=true` hoặc `DEVICE_FUNCTIONAL_PASS=true` trước khi có đúng bằng chứng.

**Trạng thái hành động lượt này:** chỉ đọc file JSONL 3 dòng, đối chiếu source V6, báo cáo/bàn giao; **chưa sửa code runtime, chưa build DEB, chưa thử trên xe thêm lần nào**.
