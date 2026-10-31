# Kết quả log Observer mới: đã xác minh Dock thật trên iOS 16.7.16

Nguồn chính xác: main `8170d2ac92cf5fad400efa289b4b928b194438f8`, file `sideplay/log/DuoNaviObserver-13F1C6F7-9C8D-4DB1-93FE-023925D68C47.txt`, 435387 byte, blob `15c05af45d227e42cb2572df339eceaec9dd231e`, SHA256 `82b6660ffcec0c859ec4317d6d271528f7d7d1ac7d81e70d781f761f1c52daf8`. Export iOS 16.7.16, lúc 2026-10-31 10:55:56 UTC. Không phải Log22 cũ.

Đã chạy analyzer cũ: `METADATA_CAPTURE_AVAILABLE missing=0`. Đã chạy script mới khóa đúng blob: `PINNED_USER_CAPTURE_VERIFIED ... samples 24 signatures 8 dock_nodes 24`. 24 mẫu liên tiếp kéo dài 68.79 giây, CarPlay PID 94485, 480 bản ghi class/480 bản ghi cây controller, 20 class duy nhất. Các hàm trong bảng hiện diện với cùng ABI ở cả 24 mẫu.

| Class thật | Hàm | ABI thực đo |
|---|---|---|
| DBAppHistory | _bundleIdentifierDidBecomeVisible:previousBundleIdentifier: | v32@0:8@16@24 |
| DBAppDockViewController | appHistory | @16@0:8 |
| DBAppDockViewController | setActiveBundleIdentifier:animated: | v28@0:8@16B24 |
| DBAppDockViewController | _refreshAppDock | v16@0:8 |
| DBStatusBarHomeButton | setDisplayState: | v24@0:8Q16 |
| DBWorkspace | requestStateChange: | v24@0:8@16 |
| DBMutableWorkspaceStateChangeRequest | activateApplication: | v24@0:8@16 |
| DBMutableWorkspaceStateChangeRequest | deactivateApplication: | v24@0:8@16 |

Image khai báo là Apple `/System/Library/PrivateFrameworks/DashBoard.framework/DashBoard`. Quan trọng hơn việc class chỉ có tên trong binary: instance `DBAppDockViewController` thực sự xuất hiện 24/24 lần trong containment công khai `UIWindowSceneSessionRoleCarPlay → DBStatusBarWindow → DBRootStatusBarViewController → DBAppDockViewController`. Có thể tìm receiver từ cây scene/controller thật, không cần tạo Dock giả hay hardcode offset ivar.

Khai báo `_appHistory` của Dock có type `DBAppHistory`; root status controller có `_appDockViewController` type `DBAppDockViewController` và `_homeButton` type `DBStatusBarHomeButton`. Đây vẫn là khai báo: chưa đọc private ivar value để chứng minh instance history/Home cụ thể.

## Đối chiếu với source QA146 và bằng chứng gốc

DuoNavi `setAppDockActiveBundleID:` và DuoDash `onHostState:` đã được phân tích ở checkpoint trước có các tham chiếu history/active/refresh. Log mới xác nhận Apple iOS16.7.16 có đúng các ABI đó và Dock controller thật có thể tìm qua cây UIKit. Như vậy phần ABI chưa rõ trước đây đã có bằng chứng vật lý; không cần lặp lại chỉ quét tên hàm gốc.

Source QA146 `sideplay/duoface-native-scene-host/DFHomeStandalone144.m` có `DF144ResultNotify`, SpringBoard `reply:reason:` phát kết quả; `sceneReady:` chỉ ACK `scene-hosted-render-and-touch-unverified` sau khi kiểm tra đúng hosted view, đúng bundle, scene live, PID và chống trùng. Trước đó `pending-scene` chỉ là window/surface đã gắn. File này không có listener consume result để đồng bộ Dock CarPlay, không gọi active/history/refresh. Đây là thiếu sót source đã xác định trước, nay có receiver/ABI vật lý làm cơ sở triển khai; log mới không tự chứng minh hàm đã được gọi hay app nào đang hiện.

## Bước triển khai cụ thể kế tiếp

1. Trong CarPlay, dùng scene/window/controller containment đang tồn tại để chọn duy nhất Dock receiver đúng loại và kiểm ABI đo được. Không new DBAppDockViewController, không offset ivar cứng, không quét SpringBoard để tìm Dock.
2. Thiết kế consumer kết quả standalone có RequestID/bundle/session/generation kiểm tra chặt. Chỉ xem scene-hosted ACK có PID là cổng scene-ready; không dùng pending-scene hay coi đó là first frame/touch ACK. Kiểm chứng stale/duplicate/mismatched result, failed/stop/disconnect cleanup trước khi thay đổi Dock.
3. Ghi nhận active/previous app thật và nguồn native workspace; đối chiếu ngữ nghĩa tham số history/active trong original method flow trước khi gọi. ABI đúng không đồng nghĩa tham số đúng. Home `setDisplayState:` nhận unsigned 64-bit enum; giá trị enum CHƯA đo, không tự gán 0/1 theo suy đoán.
4. Giữ native Home/Dashboard và Dock gốc. Kiểm thử native app pass-through, app không được chọn, app chuyển nhanh, Home, disconnect, split; sau đó mới build ứng viên sửa. Không phát hành bản sửa chỉ vì metadata đã đủ.

## Giới hạn của log này

Không có manual marker, BundleID app đang chọn, RequestID broker hay method-call trace; không thể gán chính xác tap nào với app nào, đánh giá độ trễ hoặc chứng minh Home đã trả đúng/sai màn từ TXT này. Controller Home/Today vẫn nằm trong cây không có nghĩa nó là pixels đang hiển thị. `orientation=0` là unknown, không phải bằng chứng app xoay sai; status window ban đầu x=-45 rồi x=0 chỉ là biến đổi quan sát được, chưa chứng minh nguyên nhân khoảng đen. Log không kiểm kê bridge đang cài; không tự chứng minh phiên QA146 hay DuoNavi. Không có căn cứ từ log này để kết luận một crash mới.

Không sửa bridge production, không build DEB hay đổi Sileo trong lượt kiểm log. Kết quả vật lý mới là ABI và containment, chưa phải fix.

## Tái hiện

Từ repo DuoFace, lấy raw log đúng main commit nêu trên rồi chạy:

```bash
python3 sideplay/duonavi-observer/analyze_native_dock.py --log /tmp/duoface-observer-8170d2a.txt --output /tmp/native-dock-full.json
python3 sideplay/audit/qa146-native-home-dock-parity-20261031/analyze_user_observer_8170d2a.py --log /tmp/duoface-observer-8170d2a.txt --output sideplay/audit/qa146-native-home-dock-parity-20261031/runs/user-observer-8170d2a/DEVICE_DOCK_ABI_FINDINGS.json
```

Kết quả thu gọn và thông tin tái hiện nằm trong JSON trên; raw log đã được lưu bất biến ở main, không sao chép dữ liệu dài vào handoff.
