# DuoFace Native12 — QA6 CarPlay thực tế (thử nghiệm, chưa nghiệm thu)

## Artefact và giới hạn

- Repo `chuongnguyen89dn-ui/Duoface`, nhánh `feature/duoface-native12-root-geometry-qa6`; gói cô lập `com.duoface.sideplaydisplay` `0.1.4~native12root6`.
- DEB: `sideplay/artifacts/native12root6/com.duoface.sideplaydisplay_0.1.4~native12root6_iphoneos-arm64.deb`, SHA256 `29cf90cef569622d9d5d60dda453c4c8de950960e86b15acef70556615483763`. Build [run 39128366743](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39128366743) SUCCESS.
- CI compile + package PASS **không chứng minh UI CarPlay được sửa**. Chưa có owner cho native bar / native fullscreen ACK. QA6 vẫn phụ thuộc SidePlay 1.0.4-1 cho app host, chỉ một tỉ lệ/tối đa hai pane, App/Style của SidePlay còn hiện, HUD8 chưa ghép.
- Khoanh vùng: **QA6 không thay binary original SidePlay và không thay package Native12 HUD8 stable**. Không coi QA6 là bản độc lập cuối.

## Điều kiện kiểm tra — khi xe đỗ, iPhone X iOS16 rootless

1. Sileo → Sources → Refresh; kiểm `DuoFace Native12 Root Host QA6` version `0.1.4~native12root6` (khác gói Native12 HUD8 ổn định), cập nhật và respring khi được yêu cầu. **Đừng gỡ SidePlay gốc** ở giai đoạn này.
2. Kết nối CarPlay, chưa nhấn Zoom. Chụp toàn màn: **Home tiles không lộ phía sau UI root**, native bar/sidebar có/không, giao diện ban đầu không fullscreen. Nếu vẫn lộ, ghi nhận FAIL.
3. Chia 2 app, mỗi khung có **một pill 2 nút ở chính giữa phía TRÊN của khung**. Không có thêm nút lớn "＋ Chọn ứng dụng" nằm bên dưới pill. Chụp ảnh.
4. Kéo thanh chia: hai app phải đổi kích thước theo cùng một ranh giới; vạch chia phải đi theo pane; chạm logo swap, giữ logo ≥0,30 giây và vuốt dọc thanh chỉ làm dịch logo (không thay ratio). Chụp trước/sau.
5. Nhấn nửa phải pill → focus riêng ô, nhấn Restore → khôi phục chia hai app. Nội dung phải nhận touch đúng, không xoay sai/gây méo.
6. Mở menu (App/Zoom/Style/Close): Zoom In mới phủ toàn CarPlay, Zoom Out phải trả vùng native bar, không đè thanh app; **picker App và Style vẫn là UI SidePlay nên chưa nghiệm thu DuoFace hoàn chỉnh**.
7. Ngắt CarPlay, kết nối lại, respring khi cần. Không SpringBoard crash/exitMode, không mất app icons hoặc dữ liệu.

## Bằng chứng runtime cần để sửa tiếp

- File log thiết bị `/var/mobile/Library/Logs/DuoFaceSidePlayDisplayQA.log`; đoạn `native host apply=...`, `QA6 host refused...`, `Native12 divider requested=...`.
- Cần **window.frame/bounds/windowLevel**, `realRoot.frame`, usable/safe insets, `SPDash.ratio`, actual `SPPane` rectangles, screenshot bar; không cần route, GPS hoặc nội dung app.
- Trạng thái mỗi bước: PASS/FAIL/N/A + ảnh tương ứng. Nếu QA6 làm CarPlay lỗi hoặc SpringBoard bất ổn, gỡ `com.duoface.sideplaydisplay` qua Sileo; gói SidePlay gốc và Native12 HUD8 không được sửa bởi QA6.
- Không kết luận "thanh bar khôi phục" khi chỉ log `windowLevel`; cần **ảnh hoặc owner ACK**.

## Điều kiện release hoàn thiện DuoFace

P0: normal root/window, system bar, 2 pane/scene/gesture; P1: 8 kiểu chia, 1–3 pane/2 ratio source-owned, App picker cards/recent/paging và Style chooser native, startup, HUD8; P2: cảnh chuyển/đóng scene, orientation và stability dài, gỡ mọi UI legacy sau thiết bị PASS; độc lập vendor binary/SidePlay host là giai đoạn riêng chưa giải quyết. Quyết định UI chuẩn: Native12 HUD8 đã duyệt, không phải QA5/QA6 hoặc SidePlay.
