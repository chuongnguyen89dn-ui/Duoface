# DuoFace YouTube .86 — phát hiện mới qua 5 DEB gốc và SidePlay ARM64 đầy đủ (2026-10-28)

## Phạm vi và tính xác thực
- User xác nhận DuoFace .86 YouTube vẫn sai chiều; **Maps tạm giữ nguyên**, không sửa Dock, logo, split, video lifecycle .83, không đoán tỷ lệ zoom.
- Repo: `chuongnguyen89dn-ui/Duoface`, branch `feature/duoface-jb-embedded-appbridge-20261020`.
- 5 SHA-pinned DEB tải và kiểm checksum bằng GitHub Actions run **40644998131 PASS** và **40645293974 PASS**; report `YOUTUBE_ORIGINAL_DATAFLOW_RUN_40644998131.json`, `YOUTUBE_SIDEPLAY_CALLBACK_RUN_40645293974.json`. **DuoDash 1.1.3 chỉ là repack, không gán là binary stock**. Mỗi DEB chỉ giải mã tĩnh, không chạy trên iPhone.
- Run **40645451914 PASS** của bộ giải mã LLVM sâu hơn, report `SIDEPLAY_YOUTUBE_ORIENTATION_CALLBACK_RUN_40645451914.json`; run **40645451791 PASS** đồng bộ chuỗi kiểm toán mới. SHA original SidePlay DEB `7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c`, SidePlay.dylib `0fc34c6c8e47283d2223d70facfe3e86ed76bd568958786b67a9430127242971`.

## Khác biệt CÓ BẰNG CHỨNG MÃ MÁY quan trọng nhất: 2 hướng scene khác nhau
Trong original SidePlay 1.0.4-1 (ARM64 thật):
1. **`SPPane.applySceneOrientation:` @0x31050**: lấy live `sceneHandle → sceneIfExists → settings.interfaceOrientation` tại @0x3107c–0x31148. Nếu giá trị scene setting đã giống input, bỏ qua; nếu khác, tạo transaction CHỈ hướng `updateSettingsWithBlock:` @0x3128c–0x312d4 hoặc fallback `mutableSettings` / `updateSettings:withTransitionContext:completion:` @0x312dc–0x3135c. Block riêng @0x31388–0x313f4 gửi `setInterfaceOrientation:`. **Không cần thay đổi frame mới kích hoạt.**
2. **`SPPane.appReportedOrientation` @0x34e38**: đọc **`FBScene.clientSettings.interfaceOrientation`** (get `clientSettings` @0x34e90–0x34ed4 và `interfaceOrientation` @0x34ee0–0x34f18). Đây là **trạng thái phía client/app**, khác với `FBScene.settings.interfaceOrientation` phía host ở bước 1.
3. **`SPPane.enforceSceneGeometry` @0x3467c**: lấy desired `orientation` rồi gọi `applySceneOrientation:` @0x34704–0x3470c; đọc `appReportedOrientation` @0x34714–0x34738; so sánh nhóm portrait/landscape @0x3473c–0x34758; có đường gửi thông báo `com.sideplay.orientation` với `orientation` qua `NSDistributedNotificationCenter` @0x347a8–0x34874, và gọi `applySceneFrame:` nếu `sceneSize>0` @0x3489c–0x348cc. Đó là reconciliation **scene host → app báo trạng thái → IPC reflow** chứ không chỉ ép khung.
4. **`SPPane.watchOrientationFor:token:` @0x33ac8 và block @0x33bd8**: đọc `watchToken` @0x33c08–0x33c1c để tránh callback cũ, quản lý `watchTicks` @0x33c90–0x33cb0, gọi lại `enforceSceneGeometry` @0x33cd0–0x33cd8 rồi hẹn `watchOrientationFor:token:` tiếp @0x33d10–0x33d18. Không khẳng định mọi vòng đều thực hiện cùng một mutation.
5. **`SPPane.requestAppOrientation:` @0x308bc**: có `applySceneOrientation:` @0x30f2c–0x30f30 và distributed notification `com.sideplay.orientation` @0x30f34–0x30fd4; `orientationForBundleID:idiom:` @0x307a0 dùng cấu hình `appOrientations` và kích thước UI `bounds`. Không phải hardcode LandscapeLeft/Right cho mọi app.
6. **`SPPane.setSceneFrame:orientation:` @0x31500** gọi block @0x31768 thiết lập `setFrame:` và orientation nếu ≥1, nhưng có nhánh early-return nếu `CGRectEqualToRect` @0x31618–0x31620. Vì vậy original có đường `applySceneOrientation:` riêng để xử lý hướng dù frame không đổi.

## Đối chiếu DuoFace .86 (đã đọc source hiện tại)
- `sideplay/duoface-native-scene-host/DFSceneHost.m:272–276` bỏ qua `layoutScene` khi `bounds.size == lastApplied`.
- `DFSceneHost.m:302–310` bỏ qua `commitSceneGeometry` khi `bounds.size == committedReferenceSize`.
- `DFSceneHost.m:399–468` chỉ đọc **`scene.settings.interfaceOrientation`**, quyết định mutation khi nó là 2/3/4 và bundle YouTube, sau đó set Portrait=1; **không đọc `clientSettings.interfaceOrientation`**; không có nguồn orientation app xác nhận, không có cơ chế đối chiếu app client report và stage transition fullscreen.
- `DFAppViewportRelay.m` hiện chỉ reflow `UIWindow.frame` khi target size đã match; **không có kênh orientation state / clientSettings ACK**.
- User 3 hình: pane zoom video sai → YouTube own fullscreen đúng → restore split vẫn đúng. Như vậy **chỉ phát hành .86 sửa remote scene.settings là không đủ**. ĐÃ XÁC MINH khoảng trống kết nối hai trạng thái; **CHƯA XÁC MINH** cụ thể hướng clientSettings trước/sau fullscreen trên máy người dùng hoặc nguyên nhân duy nhất dẫn đến rotation.

## Hướng sửa độc lập, không sao chép vendor / không sửa khi chưa biết đầu vào
- Bước mã nguồn kế tiếp phải có cơ chế **YouTube-only** phân biệt exact owned `FBScene.settings.interfaceOrientation` và `FBScene.clientSettings.interfaceOrientation`, cùng owner + generation và thời điểm fullscreen/Zoom; không suy từ aspect ratio.
- Sau khi xác định bất đồng thực tế, tổ chức orientation-only reconciliation riêng khỏi size/frame commit, không ép 3/4 tùy ý; cần app-owned/UIKit side handshaking nếu client orientation không theo host. Dùng cơ chế IPC first-party riêng, không dùng `com.sideplay.orientation`, mã vendor hay license; không set foreground/background lung tung do lịch sử crash.
- **Không phát hành .87, không nói đã sửa video**, khi chưa có change có kiểm thử và chưa có xác thực máy. Maps giữ nguyên.

## Chứng cứ/khôi phục
- Script `sideplay/tools/audit_youtube_original_orientation_dataflow_20261028.py` và `sideplay/tools/audit_sideplay_youtube_orientation_callback_20261028.py`.
- Workflows `.github/workflows/duoface-youtube-original-orientation-dataflow-20261028.yml` và `.github/workflows/duoface-sideplay-youtube-orientation-callback-audit-20261028.yml`.
- GHA `https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40645451914` PASS; `https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40645451791` PASS.
- CI đã append `sideplay/tiep tuc du an.md` ở commit SHA từ workflow; sau thay đổi quan trọng phải đọc lại current handoff/HEAD trước khi lưu tiếp.
