# DuoFace native12 ↔ DuoDash 1.1.3: Tự động mở và đóng ứng dụng khi ngắt CarPlay

**16/10/2026 — READ-ONLY binary investigation; KHÔNG sửa/built/deploy DEB.**  
**User correction/goal:** **một công tắc `Tự động mở` DUY NHẤT** phải bao gồm chống mở trùng và **ghi nhớ/khôi phục ứng dụng của phiên gần nhất**, KHÔNG có 2 switch "chống mở trùng"/"khôi phục phiên". User đang gặp bug **rút/ngắt CarPlay ở DuoFace mà nhạc vẫn phát**; quan sát DuoDash có vẻ không bị, trong ảnh của user công tắc **`Đóng ứng dụng khi ngắt CarPlay` đang ON**, còn **`Tự động mở` đang OFF**. Vì vậy cần nghiên cứu **hai chức năng riêng**: auto-start khi connect, shutdown app/audio khi disconnect. **Không mặc định có lỗi iOS**, phân biệt music app trên xe và music trên iPhone.

## Binary DuoDash 1.1.3 — xác minh từ byte thực, không chỉ mô tả

- Source user-upload `/mnt/data/com.sensetechlab.duodash_1.1.3_iphoneos-arm64.deb`, sha256 **`16ffab22b4246dea9978cae92df7ec635d833ec067b4d9f425a231b26edec601`**. Extract thực:
```sh
mkdir -p /mnt/data/duodash_connect_audit/{root,control}
dpkg-deb -x /mnt/data/com.sensetechlab.duodash_1.1.3_iphoneos-arm64.deb /mnt/data/duodash_connect_audit/root
dpkg-deb -e /mnt/data/com.sensetechlab.duodash_1.1.3_iphoneos-arm64.deb /mnt/data/duodash_connect_audit/control
# Tách arm64 FAT slice: fat_arch[0], file_offset=16384, size=960256.
llvm-objdump --macho --disassemble --no-show-raw-insn /mnt/data/duodash_connect_audit/tweak_arm64.macho > /mnt/data/duodash_connect_audit/tweak_arm64_disasm.txt
```
  - `var/jb/Library/PreferenceBundles/DuoDashPrefs.bundle/Root.plist`, `Library/PreferenceLoader/Preferences/DuoDashPrefs.plist`: key **`appbridge_autostart`** `default=false`, notify `com.sensetechlab.autostart.changed`; mô tả tự mở vài giây sau connect. Key **`disconnect_close_enabled`** `default=false`; mô tả sẽ dừng apps DuoDash đặt trên màn xe sau **~12s**, rớt ngắn không đóng; nhạc dừng vì app bị đóng, có thể mất công việc chưa lưu. Đó là tác dụng được mô tả; không chứng minh tất cả apps bị đóng.
  - Đã truy được `DuoDash.dylib` **arm64 slice** của DEB bằng cách lấy chuỗi `__cstring` → `__cfstring` pointer record → `__text` ARM64 ADRP+ADD. Vị trí `appbridge_autostart` literal **`0x7d6ca`**, CFString **`0xc95a8`**; xref `0x579c`/ `0x57a0` đọc `CFPreferencesGetAppBooleanValue`, và `0x33348`/ `0x3334c` đến `CFPreferencesSetAppValue` + `CFPreferencesAppSynchronize`. Hành vi bắt connect cụ thể cần thêm runtime.
  - `disconnect_close_enabled` literal **`0x80990`**, CFString **`0xccb08`**: getter `0x4936c` dùng `CFPreferencesSynchronize` và `CFPreferencesCopyValue` tại `0x493ac..0x493c0`, kiểm CFBoolean và trả OFF nếu không có key/khác type. Đây là logic bật/tắt **THẬT** bên trong tweak.
  - Hàm at `0x491c8` lên lịch `dispatch_after` tại **`0x49344`** và tăng generation counter ở `0xdc990`. Delay mặc định ở **`0x49220..0x49228`** nạp `0x00000002CB417800` nanoseconds = **12,000,000,000 ns (12.0s)**. Có đường chọn override file `/var/tmp/duodash_ab_discoclose_secs` (literal `0x809a9`); mã so guard 120.0 seconds ở `0x492c4..0x492e8`. **Không cần tái sử dụng đường override thử nghiệm này**.
  - Callback timer at `0x4941c` so sánh **generation** (giá trị block với counter `0xdc990`) để hủy timer cũ; tại `0x49448` kiểm **CarPlay còn kết nối** qua ObjC selector `carPlayConnected`; tại `0x49458` đọc lại **`disconnect_close_enabled`**; sau đó mới đi vào routine xử lý ứng dụng `0x43f7c` với reason `carplay.disconnect` literal `0x8097d`. Có kiểm kill-switch `/var/tmp/duodash_ab_nodiscoclose`.
  - Mạch nhận tín hiệu thực tồn tại: `UIScreenDidDisconnectNotification` được đăng ký quanh **`0x12cb8..0x12cd4`**; literal event `CarPlayIsConnectedDidChange` được xử lý gần `0x11674..0x116bc`; disconnect routine **`0x115c0..0x115d4`** gọi `notify_post("com.sensetechlab.appbridge.cpdisconnect")`. Đây là **evidence đường disconnect notification**.
  - Routine `0x48eb4..0x490a0` có enumerate collection apps và message selectors kiểm tra/thu thập danh sách; **chưa chứng minh selector kill/close cuối cùng cho từng bundleID, app music cụ thể hoặc hành vi thời gian thực**. Chưa cài DuoDash/chưa chạy call trace trên máy; không kết luận đã đóng app nào trên screenshot.

## DuoFace native12 — phần đã xác minh, phần chưa

- `main:tiep tuc du an.md` ghi ảnh thực trong app iPhone có công tắc **Tự Động Mở Khi Kết Nối**. `CBGeneralSettingsViewController` trong host UI có `autoLaunchOnConnect`, `autoLaunchToggleChanged:`, `setAutoLaunchOnConnect:`, `loadPreferences`, `savePreferences`.
- `CBDashboardSettings` trong `DuoFaceDashboard.dylib` có `autoLaunchOnConnect`, `autoLaunchBundleID`, `bridgedApps`, `splitApp1..4`, `splitLeftBundleID`, `splitRightBundleID`. Phương thức getter không chứng minh có **snapshot+restore của phiên trước khi disconnect**.
- Lịch sử source có `CBBridgeManagerDashboard.handleStateDict:` → `bridgeDidActivate:`/`bridgeDidDeactivate:`, có primitive `terminateApplicationWithBundleID:`/`terminateAllBridgedApplications`. Tuy nhiên **bridgeDidDeactivate có thể là ứng dụng deactivate, không phải sự kiện ngắt CarPlay**; không được dùng thay disconnect detector khi chưa kiểm chứng.
- **Được người dùng báo lỗi thực:** ngắt CarPlay mà âm thanh tiếp tục phát. Chưa có call trace/audio route/NowPlaying ID/video để kết luận chính xác **thiếu hook disconnect, thiếu lệnh pause, hay hệ thống chuyển route về loa iPhone**.
- **Chưa chứng minh trong native12:** từng preference key Auto Launch, duplicate suppression, snapshot last session, ngắt CarPlay native event callback, countdown closure 12s, media pause/termination policy. Không suy đoán feature native12 đang có chỉ vì có selector.

## Apple/iOS explanation

- Apple `AVAudioSessionRouteChangeNotification` báo lý do thay đổi route; `oldDeviceUnavailable` là route cũ bị rút. Apple nhấn mạnh app phát media **nên pause** nếu route bị mất, nhưng nó **không phải cam kết mọi app luôn tự dừng**. Từ iOS 17, system có gián đoạn Now Playing sessions khi disconnect, không phải mọi loại session. Source: `https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/HandlingAudioHardwareRouteChanges/HandlingAudioHardwareRouteChanges.html`, `https://developer.apple.com/documentation/avfaudio/avaudiosession/setprefersinterruptiononroutedisconnect(_:) `.
- Bởi vậy cần phân biệt **CarPlay connected state** (qua host CarPlay) và **audio playback state** (qua media route/player); việc phát tiếp không đủ chứng minh CarPlay còn nối. Không tự phát lệnh toàn hệ thống vào unrelated player.

## Chốt yêu cầu mới thành thiết kế CHỜ triển khai

### Chỉ 2 công tắc chính (sửa đề xuất menu trước)

1. **`Tự động mở`**: duy trì *một* switch DuoFace cũ, **bật =** tự ghi lại session app mà DuoFace điều khiển (bundleIDs/slot if stable), lần connect tới tự khôi phục app **cuối cùng**; check running/session để **không mở trùng**, cancel stale reconnect jobs, validate app installed. **Tắt =** không auto launch và không tự restore. Không thêm switch cho chống trùng hay "nhớ app". Không overwrite user's original autoLaunchBundleID khi chưa có quy tắc migration rõ.
2. **`Đóng ứng dụng khi ngắt CarPlay`**: công tắc **mới, độc lập với Auto Start**, chỉ tác động apps do DuoFace đưa lên màn xe/khởi động, **không đóng app thuộc người dùng ngoài phạm vi và không thay callback Close App trong menu**. `OFF` mặc định khi update an toàn đến lúc user xác nhận; khi `ON`: sau disconnect thật chờ **12s** (theo DuoDash), nếu reconnect thì hủy, recheck state và policy sau delay, đóng app đã được xác minh là do DuoFace quản lý; app đang phát media phải được pause/stop theo scope người dùng mong muốn **sau khi xác minh route/session đúng**, không kill bừa `Music` hoặc mọi app iPhone. Không tự restart/respring. Kiểm history/allowlist cho bản đồ/nhạc chạy ngoài DuoFace trước khi đóng.

**Khác biệt quan trọng:** `Auto Start` không điều khiển `Close on Disconnect`. Trong ảnh DuoDash người dùng đang để auto-start **OFF** và close-disconnect **ON**. Do vậy khi user tắt Auto Start, vẫn cần có thể đóng đúng apps cũ trên disconnect nếu Close ON. Không cần màn `Kết nối nâng cao` với 4 dòng ở giai đoạn này, trừ khi người dùng yêu cầu thêm. **Thay thế đề xuất UI cũ** 8 rows và menu con; chưa phải code thực.

## Bước điều tra tiếp cần làm trước khi sửa/DEB

1. Trên **native12 actual Mach-O SHA-pinned**, trace selector & cstrings cho `autoLaunchOnConnect`, `autoLaunchBundleID`, connect/disconnect event và pause/stop commands; xác minh owner process (SpringBoard/Dashboard) và exact handler, không lẫn `bridgeDidDeactivate`.
2. Trên iPhone với native12: test 3 trường hợp tách biệt: (A) play media qua app được DuoFace bridge → rút CarPlay; (B) phát audio từ ứng dụng native iPhone không do DuoFace quản lý → rút; (C) reconnect trước 12s. Ghi nhạc phát trên loa iPhone hay loa xe, app có chạy không, đang bật Auto Start không. Không gán nguyên nhân nếu chưa có dữ liệu.
3. Nếu yêu cầu build, tạo module settings+disconnect observer, generation counter, scoped session ownership/auto restore; compile/test read-only trước package, giữ native12 rollback, không sửa 8 CarPlay method implementations, visual/fullscreen/menu. **Không build DEB/Sileo ở lượt phân tích này.**

**Bản giữ nguyên:** `com.duoface.independent 0.1.0~native12` SHA256 `85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7` user reported working generally; license physical excision PAUSED.
