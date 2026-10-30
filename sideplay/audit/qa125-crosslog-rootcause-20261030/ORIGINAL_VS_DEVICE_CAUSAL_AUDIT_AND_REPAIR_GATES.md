# DuoFace QA125 — đối chiếu chứng cứ gốc, crash và khóa màn hình (30/10/2026)

**Phạm vi:** nghiên cứu trước khi sửa, KHÔNG thử ngẫu nhiên, KHÔNG tự nhận đã sửa. GitHub nguồn chính; iPhone X iOS 16.7.16 JB rootless. Đích phát hành sau khi có bản sửa đã qua gate là Sileo `chuongnguyen89dn-ui/carplaydsp`. Giữ nguyên QA90 xoay YouTube, QA92 chia ô, QA120 Dock/kích thước, cải thiện một phần QA125.

## 1. Nguồn và độ tin cậy

| Nguồn | Dữ liệu thực đọc | Giới hạn |
|---|---|---|
| Original DuoNavi 1.0.4 signed ARM64 | `sideplay/audit/lock-native-duonavi-fullscan-20261030/DEEP_QA122_DUONAVI_LOCK_CONFIRMED_20261030.md`; `DUONAVI_13_LOCK_AND_WORKSPACE_HOOKS_ARM64.json` và `DUONAVI_UNDERLOCK_EXTRA_GUARD_VERDICT.md`; DEB `dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb` SHA256 `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd` | Đã giải mã registration/nhánh gốc trong các báo cáo có checksum; không phải live trace các hàm vendor |
| Native12 original signed ARM64 | `sideplay/audit/native12-foreground-hooks-20261027/REPORT.md`, `HOOKS_AND_ARM64.json`; đã kiểm chứng 11 hook, gồm update/apply/observer/destroy | Static proof, không thay cho log thiết bị |
| Live DuoNavi observer | `main:sideplay/log/DuoNaviObserver-69D22C75-5122-4EFC-B21F-59FAE0B60498.txt`, blob `8eb93be5464e710c17a7635d22537dc999be5ab6` (79 JSONL bản ghi) | Ghi UIKit/system scene, KHÔNG ghi vendor callback/YouTube Play ACK |
| Live DuoFace trước QA125 | `main:sideplay/log/DuoFaceAudit 10.txt`, blob `81b6ae1aa699ec383af85112f8eddf524c409e9f` (4,685,543 ký tự, 19,448 dòng, đọc thành công bằng `fetch_blob`; `fetch_file` cho tệp lớn trả rỗng) | Thực tế QA124, không tự gán là QA125 |
| Crash mới | `main:sideplay/log/Crash-0-SpringBoard-2026-10-30-121458.ips`, blob `ab96c9a3d417a235d2e10546897032d1532ff3c4` | Không có NSException.name/reason và bản trace ngay trước thao tác Zoom |
| Đang chạy | `DFSceneLifecycle.m`, `DFSceneHost.m`, `DFNativeHostAppDelegate.m`, `DFTouchOwnerProbe.m`, `DFDockZoomCoordinator.m` ở `feature/duoface-jb-embedded-appbridge-20261020` | Đây là source repository; IPS riêng không chứng minh hash của dylib đang được nạp |

Không nhầm các phiên bản: QA125 được build/signed run `41005523412` và public Sileo verified run `41006218095`; điều đó **không đồng nghĩa** Play/Zoom trên iPhone đã PASS. Handoff gần nhất trước phân tích là commit `c846c88d2cf4cf78bdcbc815fe4b045f1109e4d0`.

## 2. Phân tích lại TẤT CẢ 17 tệp Crash-*.ips trên GitHub/main

Đã thực sự fetch + parse 17 IPS; lấy `captureTime`, `exception`, `lastExceptionBacktrace`, `usedImages`. Kết quả:

- **11 file** `EXC_CRASH/SIGABRT` có `SBAppViewController sceneHandle:didUpdateSettingsWithDiff:previousSettings:` trong `lastExceptionBacktrace`. Trong đó **2 file** ghi `DFManagedSceneObserver` **và** `DFUpdateScene`: 28/10 13:18:21 PID69116 và 30/10 12:14:54 PID83708. Hai file 27/10 17:04:49 (`Crash-0`, `Crash-2`) là cùng một PID64281/thời điểm, do đó không đếm là 2 sự cố riêng.
- **6 file** khác `EXC_BREAKPOINT/SIGTRAP` ngày 28/10, chưa được quy kết cùng nguyên nhân vì thiếu trace `lastExceptionBacktrace` tương ứng.
- Trong các file `SIGABRT`, `AppData.dylib` được nạp và vài stack thể hiện `ImmortalizerHooks`; **đây là hiện diện/chuỗi hook, KHÔNG chứng minh AppData là thủ phạm**. Tương tự, dùng `DFTouchOwnerProbe.dylib` trong process không chứng minh một callback DuoFace là đầu tạo sai settings.
- Không đưa ra kết luận rằng QA125 *tạo ra* lỗi crash: cùng đích Apple observer có trong IPS từ 27/10, trước QA125.
- Tại 12:14:54.8427 ICT: SpringBoard PID83708 `EXC_CRASH/SIGABRT`, uncaught ObjC exception → Apple `SBAppViewController sceneHandle:didUpdateSettingsWithDiff:previousSettings:` (+440) → `DFManagedSceneObserver`; stack sâu hơn `DFUpdateScene` → original `FBScene updateSettings`. `isLocked=0` **tại snapshot crash**; không được dùng làm phản bác việc Play lúc khóa khác bị lỗi.

## 3. Ba thiếu hụt ĐÃ CHỨNG MINH trong source, phân biệt với nguyên nhân runtime CHƯA CHỨNG MINH

### A. Apple observer nhận callback có thể assert (crash Zoom / scene)

- `DFSceneLifecycle.m:93-129`: `DFManagedSceneObserver` **chỉ consume** khi controller có trong weak-owner table, retained owner block trả scene thực, callback handle == `controller.sceneHandle`, `handle.sceneIfExists` == scene đó, và `automatesLifecycle == NO`. Nếu BẤT KỲ guard nào sai, gọi `sPreviousSceneObserver` (Apple). IPS với frame Apple ngay trên frame `DFManagedSceneObserver` cho biết **lần đó đã forward**, nếu binary nạp thực sự theo source này. Crash không chỉ rõ guard nào sai: owner mất, handle đổi, generation, automatesLifecycle, hoặc callback của controller khác.
- `DFSceneHost.m:328-335` đăng ký owner bằng block yếu dựa vào `surface.window`, `appController.viewIfLoaded.window` và `sceneIfExists`; `pollScene:` có thể đổi `self.scene` và `sceneGeneration`. Mất xác thực vào đúng lúc chuyển trạng thái là một **đường cần đo**, không phải khẳng định nó thực sự xảy ra ở 12:14.
- `DFSceneHost.m:508-555`: khi thay đổi frame (không chỉ Zoom mà cả resize), trong transaction có thể gọi `setFrame:`, `setForeground:YES`, `setBackgrounded:NO`. `DFSceneLifecycle.m:55-85` cũng độc lập chặn `foreground=NO` trong `FBScene` updates cho scene đang nhận diện được; hai điểm này tương tác trong cùng call stack. Chưa có trace chứng minh lệnh nào tạo inconsistency.
- Native12 ARM64 original `0x2c8ca8` có policy observer riêng; `0x2c8ef8` **scene-destroy handler** riêng. DuoFace source hiện chỉ hook observer update, **không có tương đương riêng cho destroy**. Đây là khác biệt cấu trúc có thật, **chưa chứng minh** bổ sung destroy hook sẽ chữa crash. Không sao chép vendor marker hay bỏ qua Apple observer toàn cục.

### B. Owner phiên CarPlay bị thu hồi (đen pane, không còn interaction)

- `DuoFaceAudit 10`: QA124 log 10:50:16.443 resign; **10:50:16.448** `touchowner-stop reason=scene-background`; đến 10:50:16.505 YouTube/FB host invalidated và Chrome detached; tương tự 10:50:47 và 10:51:04. **Causal sequence teardown đã được chứng minh cho QA124**.
- `DFNativeHostAppDelegate.m:186-220` gia hạn pulse mỗi 0.75s khi CPTemplate ForegroundActive/Inactive; `:265-280` còn **vô điều kiện** gọi `stopTouchOwnerWithReason:@"scene-background"` khi chính CPTemplate scene background, dẫn đến tombstone session và `DFTouchOwnerProbe.m:364-375` hide windows. `CPTemplate` app scene và native `CarPlay` system scenes là hai chủ thể khác nhau, không được gán chúng cùng activationState.
- Live original observer: trong khoảng `protected_data=false`, **hai UIScene của process CarPlay vẫn ForegroundActive** và còn display; lúc unplug mới background/disconnect. Điều đó **không đo trạng thái CPTemplate của DuoFace**, nhưng chứng minh nhầm `iPhone khóa` thành `CarPlay global inactive` là không hợp lệ.
- User physical QA125 cho biết hai pane không còn đen, nhưng remote Play/cảm ứng dưới lock vẫn lỗi. Vì không có **QA125 same-session new audit** nên không thể tuyên bố QA125 vẫn thu hồi session lúc phone lock; chỉ xác minh source vẫn có tuyến này.

### C. Quyền giữ remote YouTube scene dưới lock không tương đương original

- DuoNavi ARM64 gốc **đã chứng minh** đăng ký `SBSuspendedUnderLockManager interceptUpdateForScene:withNewSettings:`, `_shouldBeBackgroundUnderLockForScene:withSettings:`, `shouldBeUnderLockForScene:`, và helper owner/identity `0x2eeb24` (xem `DEEP_QA122...`). DuoFace QA125 chỉ hook **một selector có thật trên iOS16.7.16**, `_shouldBeBackgroundUnderLockForScene:withSettings:` đúng ABI `B32@0:8@16@24`; selector thứ ba **không có trên thiết bị** nên TUYỆT ĐỐI không thêm hook mù.
- DuoNavi có `CBBridgeManager`, `CBBridgedUIAppView` `setAudioOnlyBackgroundMode:` và `refreshSceneLayout` làm việc cùng app-scene; DuoFace không tái tạo đủ quy trình xác nhận foreground/owner/media. Một IO `PreventUserIdleSystemSleep` chỉ giữ system idle, **không tự duy trì quyền tương tác video**.
- Cách ưu tiên thực nghiệm: xác nhận trên **CHÍNH scene của YouTube** trạng thái `isHostingAnApp`, scene handle/generation, foreground, input hit delivered và Play ACK trong cùng một lần khóa iPhone. Không có log per-tap này thì không được khẳng định root cause của media Play.

## 4. Kế hoạch sửa có cổng xác minh, không đưa bản thử ngẫu nhiên

**Gate 0 — giữ bản ổn định:** QA125 public SHA256 `1914f4e2c6e8dce0fadb5035166c0869966759fb74eb1c89424712dcf71cbe93` là rollback; không sửa trực tiếp Sileo hoặc hệ thống Apple Dock, không sửa passcode/activation và không thử khi đang lái.

**Gate 1 — crash, đo đúng ở ranh giới có IPS:** Trong hook first-party của chúng ta, trước khi forward Apple observer, phát một bản ghi đồng bộ, tối giản (`controller`, callback `handle`, `controller.sceneHandle`, `handle.sceneIfExists`, owner scene, `automatesLifecycle`, `isHostingAnApp`, session+generation và trạng thái Zoom/ACK). Không thay đổi forward/suppress behavior. Kết hợp reason từ `DuoFaceFatalException.log` nếu có. Đo một lần Zoom → assertion; xác định **chính xác guard nào** sai và liệu incoming `FBScene` foreground là 0 hay 1. Đây là cách lấy thông tin đang thiếu, **không phải thêm tweak quét tràn lan**.

**Gate 2 — sửa vòng đời dựa trên Gate 1:** Nếu callback là current owned manual scene nhưng gate sai do đổi handle/generation, dùng owner registry có trạng thái `attached/live/closing/replaced` và xử lý settings/destroy riêng cho **current generation**, giữ Apple original cho mọi controller khác. Nếu callback không thuộc DuoFace thì không được swallow; xác định nguồn settings từ trace trước khi thay đổi code. Không cho stale generation được sửa foreground. Tách geometry-only Zoom khỏi thay đổi activation state chỉ khi readback và ownership invariant chứng minh. Unit tests: owner, foreign, obsolete handle, destroy, actual Home, unplug, zoom-in/out, split preset.

**Gate 3 — Play dưới lock dựa trên owner:** Phân biệt native system CarPlay foreground với actual CPTemplate frontmost owner; không giữ overlay qua Home nếu không có owner proof. Khi underlock hook đang chạy, ghi rõ vì sao `DFIsOwnedHostedLockScene123` return false (pulse stale, appController/handle mismatch, window, auto/manual, hosting false...) và scene thực tế bị background/Play có nhận input hay không. Chỉ thay **chính guard fail được đo**. Không đụng các workspace/passcode hook vendor.

**Gate 4 — Sileo:** chỉ sau khi trace xác định đúng đường lỗi và test source pass, build rootless qua workflow macOS hiện có, lưu DEB/hash/CI vào Duoface, pin publish `carplaydsp`, kiểm tra APT/Pages; cuối cùng physical validation parked CarPlay. `CI PASS` ≠ `vehicle PASS`. Cấm tuyên bố đã sửa khi chưa test thiết bị.

## 5. Tình trạng và câu trả lời kỹ thuật

- **Đã tìm được**: đường crash Apple observer qua hook DuoFace; QA124 chính xác từng mất touch owner rồi invalidate; missing iOS16 selector và đã sửa ở QA125; khác biệt cơ chế scene-destroy/bridge giữa original và độc lập; phân loại hồi cứu **17 IPS**.
- **Chưa có bằng chứng** về exact assertion text, guard fail, incoming setting writer, post-QA125 touch failure sequence. Nên không thể có một bản patch được gọi là 'đã chữa' nếu chỉ thay hàng loạt flags.
- Không cần quét lại cả DEB từ đầu; phải tập trung vào **cặp callback thật từ original** và một phiên runtime do chúng ta kiểm soát. Không phát hành bản tiếp theo chỉ với giả thuyết; chỉ instrument chính xác callsite đã được IPS chỉ ra và đo quyết định.
- **Trong lượt nghiên cứu này:** đã đọc GitHub source, reports ARM64 trước đây, 79 original records, fetch/parse 17 IPS, source active và docs Apple; KHÔNG sửa mã nguồn, KHÔNG build DEB/đẩy Sileo, KHÔNG có device test mới. Không sử dụng local iOS toolchain (GitHub connector read; container không resolve github.com).
