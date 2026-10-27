# DuoFace .80 — hai crash thực tế lúc 19:44–19:45 ngày 27/10/2026

## Nguồn bất biến và phiên bản

- Repo log: `chuongnguyen89dn-ui/Duoface`, branch `main`, commit `05739ff4c85ef95f9de2a07f41dc8b1bd18aeba9`; commit này thay **đúng** bốn đường dẫn `sideplay/log/Crash-0-SpringBoard-2026-10-27-194502.ips`, `Crash-1-SpringBoard-2026-10-27-194420.ips`, `Crash-2-SpringBoard-2026-10-27-170537.ips`, `DuoFaceAudit 5.txt`. Tệp 17:05 là sự kiện cũ, KHÔNG tính là crash .80 mới.
- `Crash-1-SpringBoard-2026-10-27-194420.ips` Git blob `53dd52456198f41cbb9f1ca745cc9d2687180671`, 48,423 byte; `Crash-0-SpringBoard-2026-10-27-194502.ips` blob `c89afc3066228b5517e986362f97b358bd8e1d4d`, 48,424 byte.
- `DuoFaceAudit 5.txt` Git blob `c7ed67c9fde09a8466e5956f06f07b674fe71874`, 2,404,218 byte, 13,947 dòng. **Runtime `build=0.0.80~lifecycleorder1`** được ghi trực tiếp từ SpringBoard PIDs **65025** và **65079**, không suy từ workflow/Sileo.
- Máy theo IPS: `iPhone10,6`, `iPhone OS 16.7.16 (20H392)`.

## Hai lần crash độc lập của bản .80

| Lần | Ứng dụng liên kết bằng PID trong audit | IPS / thời điểm | Bằng chứng |
| --- | --- | --- | --- |
| 1 | YouTube `com.google.ios.youtube` | 2026-10-27 **19:44:20 +0700**, incident `0E2272C3-28AD-4DFD-B131-DF914E5F2EC2`, PID **65025**, consecutiveCrashCount **23** | `Crash-1-...194420.ips` + audit dòng 13885–13905 |
| 2 | TikTok `com.ss.iphone.ugc.Ame` | 2026-10-27 **19:45:02 +0700**, incident `B2A6E702-C818-47C7-9C3F-D7E66875B7B9`, PID **65079**, consecutiveCrashCount **24** | `Crash-0-...194502.ips` + audit dòng 13917–13936 |

CẢ HAI: `EXC_CRASH / SIGABRT`, `objc_exception_throw` → `_userInfoForFileAndLine` → `-[SBAppViewController sceneHandle:didUpdateSettingsWithDiff:previousSettings:] +440`, theo sau bởi `SBSceneHandle` → `FBSceneMonitor`/FrontBoard. Đây **đúng cùng điểm assert** đã thấy ở .77 (với exception.reason được ghi), .79; sửa thứ tự `setRequestedMode:2` trước `didMoveToParentViewController:` của .80 **không loại bỏ crash**.

### Thứ tự scene / thời gian thực trong audit

**YouTube PID 65025** (audit dòng 13885–13905):
- 19:44:05.357 — `mode-2-requested`.
- 19:44:05.714 — `scene-attached`.
- 19:44:05.715 — `scene-foreground-observed-only ... foreground=1 hosting=1`. Đây là điểm đọc **ban đầu**, KHÔNG phải xác minh foreground vẫn YES ở thời điểm crash.
- 19:44:06.026 — `native12-scene-settings-frame-requested` sau readback 375×812, mục tiêu 711×663; không có ACK app renderer/video.
- 19:44:15.877 — IPS captureTime, crash được ghi timestamp 19:44:20; sau frame request ~9.85 giây tới captureTime.

**TikTok PID 65079** (audit dòng 13917–13936):
- 19:44:48.583 — `mode-2-requested`.
- 19:44:48.948 — `scene-attached`.
- 19:44:48.949 — `scene-foreground-observed-only ... foreground=1 hosting=1`.
- 19:44:49.263 — `native12-scene-settings-frame-requested`, readback 375×812, mục tiêu 711×663.
- 19:44:56.542 — IPS captureTime, crash timestamp 19:45:02; sau frame request ~7.28 giây tới captureTime.

**Nhận định chặt chẽ**:
1. Bản .80 **FAILED trên thiết bị** với ít nhất 2 lần SpringBoard SIGABRT — YouTube và TikTok. Không được lấy xanh CI hay ảnh giao diện để gọi ổn định.
2. Cả hai lần crash khớp **cùng method +440** của SpringBoard mà .77 từng xuất `NSInternalInconsistencyException` nguyên văn: `Something changed the scene's ... foreground status out from underneath us (current mode: Live, ... foreground=BSSettingFlagNo)`. **Tuy nhiên 2 IPS .80 không chứa `NSException.reason`**; audit5 không có `DuoFaceFatalException.log` mới được xuất kèm. Do đó nói **rất phù hợp với cùng lỗi foreground ownership**, nhưng KHÔNG được xác quyết .80 có đúng `foreground=BSSettingFlagNo` hoặc actor nào đã đặt nó.
3. Log `foreground=1` chỉ chứng minh state tại thời điểm gắn scene; không bắt được thời điểm foreground đổi và không có dòng `foreground=0` trước SpringBoard chết. Polling 350ms không bảo đảm quan sát trước exception. Điểm hạn chế của recorder mới đã được chứng thực.
4. IPS có các dylib khác như `GhostBoardXFeatures.dylib`, `OhMyRotate.dylib`, nhiều `SnowBoard`; chỉ là chứng cứ đã nạp, **không phải bằng chứng thủ phạm**. Không sửa/xóa gói khác khi chưa chứng minh xung đột.
5. Không có bằng chứng trong tệp mới rằng chính **động tác bấm Play** (thay vì lifecycle/foreground của app) trực tiếp gây chuyển trạng thái; không suy đoán video codec, AVKit hoặc viewport. Không chạm UI đang tốt.

## Đối chiếu code và kết luận kỹ thuật

- Runtime `sideplay/duoface-native-scene-host/DFSceneHost.m`: `start` đặt `setRequestedMode:2` trước `didMoveToParentViewController:` theo Native12. `commitSceneGeometry:` giữ owner/sceneGeneration guard; trong `updateSettingsWithBlock:` **chỉ setFrame** và ghi rõ KHÔNG tự đặt foreground/backgrounded do chưa kiểm chứng rollback. Đã tránh frame duplicates nhưng không giữ hợp đồng foreground Live.
- Tài liệu original: `sideplay/audit/native12-continuation-4888299/scene-block-invoke/SCENE_SETTINGS_BLOCK_INVOKE_ARM64.json` đã giải mã có guarded `setForeground:`; OmniCar original có `setBackgrounded:NO` và `setForeground:YES` trong một scene transaction. Sự khác biệt có thật về mặt mã máy, **chưa xác nhận actor foreground NO trên máy**.
- So `.37` lịch sử: người dùng từng **phát được YouTube** trong một phiên nhưng xoay sai; không chứng minh không crash lâu dài. Xem `sideplay/audit/native12-039-regressions-20261023/HISTORICAL_DEVICE_VIDEO_CRASH_VERDICTS_20261027.md`.

## Tiến độ và bước làm tiếp theo có căn cứ

- **ĐÃ LÀM trong lượt này:** truy xuất đúng blob log mới từ main, tách 2 crash .80 và trùng method, đối sánh PID/phiên bản/timing/sự kiện; **CHƯA sửa mã runtime, build bản tiếp theo, Sileo hay thử thiết bị**.
- **BƯỚC TIẾP:** (a) Bổ sung telemetry **trước assertion**, an toàn đọc thôi, vào đúng điểm nhận FBScene changes để log scene id + requestedMode + foreground diff + owner/sceneGeneration, đồng thời bảo đảm uncaught-exception recorder được xuất ra file; không swallow/assert suppress. (b) Dùng crash mới để xác minh actor gây foreground NO và lifecycle, đối chiếu riêng Native12/OmniCar, rồi mới quyết định xem điều phối foreground YES có điều kiện khi Live có chủ sở hữu, với rollback và không gây update loop. (c) Biên dịch theo workflow hiện có → đúng **một** bản DEB kế tiếp → Sileo → test YouTube/TikTok/Facebook thực tế khi xe đỗ. Không sửa UI/Zoom/chia ô/Dock, không tự đổi renderer.
- **Tiêu chí thành công:** build runtime bản mới xác minh + thiết bị phát/seek YouTube/TikTok/Facebook không SpringBoard SIGABRT, không phát sinh log scene Live/background mismatch, giữ UI hiện tại.

