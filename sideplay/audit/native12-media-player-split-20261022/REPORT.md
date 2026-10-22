# Kiểm tra giao diện phát video/âm thanh bên trong ô chia — 2026-10-22 ICT

## Kết luận và giới hạn bằng chứng

**CHƯA TÍCH HỢP HOÀN CHỈNH, CHƯA ĐẠT parity Native12 gốc.** Phiên bản DuoFace tích hợp đang được phát hành là `com.duoface.jb.embedded 0.0.27~solo1`. Source đã ghép `SBAppViewController` vào các ô thực, hỗ trợ bố cục/preset/UI, nhưng **chưa có bằng chứng** player controls, touch trong YouTube/video, xoay dọc/ngang, foreground/audio focus và chuyển scene khi đang phát hoạt động đúng như Native12. Crash ExitSafeMode xem video là tồn đọng; KHÔNG ghi nó là đã sửa.

**Phương thức kiểm tra lượt này:** đọc trực tiếp mã hiện tại từ GitHub feature HEAD `18dca8b8685a03d2e16b9df0284f4930c95ab55e`, đối chiếu method index 1.385 phương thức từng trích xuất từ **Native12 gốc** và kiểm tra sự hiện diện của DEB gốc + SHA256SUMS ở commit bất biến. Chạy 13 phép kiểm tra tĩnh trong công cụ phân tích, tất cả cho kết quả phù hợp với mô tả dưới đây. **Không giải nén lại byte DEB gốc trong phiên này**: GitHub text connector không tải binary, môi trường container không có DNS. Không chạy clang/build/thiết bị; không kết luận 1:1 từ tên selector.

## Mẫu đối chiếu đúng (không dùng DuoNavi làm baseline)

- Native12 gốc: `dist/payload-migration/native12-speed8compact/com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb`, tại commit `1286a3ef868cf7e29804bcddf7e20b2eae707ce1`, SHA256 theo `SHA256SUMS` `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`. Metadata GitHub xác minh đúng đối tượng DEB 1,745,196 bytes, Git blob `1aa4f57a75b198f13738b8aff0f0bee41a90f66e`.
- Method index phân tích đã lưu: `sideplay/audit/native12-vs-new-20261021/ALL_NATIVE12_1385_METHODS.json`. Phân tích ban đầu là với 0.0.12, **không** nhầm đó là kiểm thử 0.0.27. Lượt này đối chiếu lại nguồn 0.0.27 cụ thể.
- Các phương thức **có trong index gốc**, `CBBridgedUIAppView`: `startInParentViewController:`, `updateSceneSettingsFrame`, `updateSceneFrame`, `refreshSceneLayout`, `setAppScale:`, `setAudioOnlyBackgroundMode:`, `touchesBegan:withEvent:`, `dismiss`. `CBBridgeManager`: `supportsInterfaceOrientation:forBundleID:`, `sendStateToApp:shouldBridge:`, `acquireCarPlaySleepAssertion`. Có selector/type encoding **không đồng nghĩa** đã xác minh đường gọi/runtime của Native12.

## Hiện trạng 0.0.27 theo mã nguồn thật

| Yêu cầu player trong ô | Bằng chứng mã nguồn hiện tại | Kết luận |
|---|---|---|
| Nhúng app thật vào vùng chia | `sideplay/duoface-native-scene-host/DFSceneHost.m` dùng `SBDeviceApplicationSceneEntity` + `SBAppViewController`, `setRequestedMode: 2`. `DFNative12Chrome.m` có bốn `appSceneWindows`, đổi kích thước theo preset, chỉ cho phép `userInteractionEnabled` khi `sceneHandleReady` | **Có nối host về mặt source**; không chứng minh video đang phát/nhận mọi touch |
| Hiển thị và tương tác player YouTube/video | `DFSceneHost.m` chỉ resize UIKit host bằng transform và nội dung tham chiếu; chưa có mô-đun xử lý riêng play/pause, seek, overlay fullscreen, autoplay hay phản hồi touch trong player | **CHƯA XÁC MINH** hoạt động thực tế; không có kiểm thử xe của 0.0.27 |
| Landscape/video fullscreen và xoay | `DFSceneHost.m` gửi `setContentReferenceSize:withInterfaceOrientation:` hoặc biến thể 3 tham số với `UIInterfaceOrientationPortrait` hardcoded, kích thước logical = 2×frame; Zoom/Style chỉ đổi frame | **KHÔNG ĐẠT tương đương** hướng, tỉ lệ, media UI Native12; cần callback orientation theo từng app, không sửa mù |
| Audio focus và playback khi ô bị che/Zoom/chuyển Style | `DFSceneHost.m` không thấy tuyến `audioOnlyBackgroundMode`, `AVAudioSession` hoặc handshake riêng cho media. Khi ẩn các `UIWindow` theo focus, không có media-state reconciliation | **CHƯA TÍCH HỢP có kiểm chứng**; không được suy ra audio sẽ giữ phát |
| Lifecycle / ExitSafeMode video | `DFSceneHost.m` tránh `updateSettings:withTransitionContext:completion:` với nil context; close gọi mode0/invalidate, log `close-no-private-settings-restore`; không dựng lại luồng FrontBoard đúng gốc | Có thay đổi giảm rủi ro **không phải** giải pháp cuối cho lỗi video |
| Input qua native CAContext | `DFNativeHostSurfaceView.m` nhận `pointer` và ghi command; comment xác nhận consumer cũ chỉ cho menu UIButton, **không có arbitrary app touch replay** | Không thể dùng đường relay này làm bằng chứng người dùng chạm được player. Touch trong app-window SpringBoard là đường riêng, chưa device PASS |
| Tình trạng chứng cứ build/thiết bị | `sideplay/jb-embedded-appbridge/package_integrated.py` vẫn ghi `real_two_app_scene_tested: False`; phát hành 0.0.27 đã public Sileo | Sileo checksum PASS ≠ video/UI/input/audio PASS |

## Các bước tiếp theo có thể thực thi ngay

1. **Giữ nguyên** package công khai `0.0.27` và bản rollback `0.0.23`, không chỉnh nhị phân Native12 gốc. Đo callback/hierarchy ở `DFSceneHost.m` cho 2 ứng dụng thực (YouTube có video và một app bản đồ), có phân biệt HostCreated / SceneHandle / HostingReal / Presented / TouchArrival / MediaState / Orientation, tránh ghi dữ liệu nhạy cảm.
2. Đối chiếu **trực tiếp callsites/callback order/ABI/owner process** trong audit Native12 `CBBridgedUIAppView` và `CBBridgeManager`: resize media scene, xoay, visibility, app focus, audio-only background, invalidate/restore; thiết kế phương án độc lập không chép vendor binary/license.
3. Chỉ sửa code media/orientation và input sau khi xác định đường gọi đúng; viết regression test cho 2 ô live, press/seek/touch, split resize lúc video đang chạy, focus/restore, mute/audio continuation, close/reconnect.
4. Build một candidate phiên bản mới trên GitHub Actions và xác minh signed DEB/artifact; **chỉ** phát hành Sileo khi build pass và cho phép thử. Kiểm tra iPhone X iOS16 jailbreak trên xe đỗ, đối chiếu ảnh player từng ô, lấy SpringBoard .ips + `/var/mobile/Library/Logs/DuoFaceSceneHost.log` và `DuoFaceTouchOwner.log` nếu SafeMode. Chỉ khi thực tế PASS mới đánh dấu player tích hợp thành công.

Không thay nguồn/phát hành trong audit này.