# GOFAHUD 0.3.1: cơ chế kích hoạt sau khi rời GOFA, đánh thức nguồn và không vẽ trùng CarPlay / DuoFace

**2026-10-17 (+07), phân tích chỉ-đọc; KHÔNG triển khai Speed6, KHÔNG cập nhật Sileo, KHÔNG thử máy trong lượt này.**

## 0. Đúng DEB và chứng cứ thực

- Upstream chính xác: `manhtien9x/gofahud-repo` commit `e423ac7408d021d6384eba8ef270e79518967ed9`, gói `GOFAHUD-0.3.1-rootless.deb` (release `v0.3.1-1`), SHA256 **`62d6d818384844591217d74ab446404637127752e1b23bc1f9754ef1da297ad5`**, rootless iOS 15/16; trùng DEB người dùng từng đưa.
- Trước đó audit layer thực tại Actions `38990750645` confirmed `GofaCarplayGlobal.dylib` SHA256 `791f3f2de2ce0e6834888db33b17f5f37a424712c9fb07b8c7234ee90ed587ca` và filter CarPlayApp/CarPlayTemplateUIHost.
- Lượt này viết script `migration/full_payload/native_test/audit_gofahud_031_activation_readonly.py` và workflow `.github/workflows/duoface-gofahud031-activation-readonly.yml`, chạy Actions **[38991653621](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/38991653621)** job `117275148218`, **completed/success 2026-10-17 01:37 UTC**. Runner `sha256sum -c` PASS, `dpkg-deb -x/-e/-f`, `strings -a`, check 6 dylib/6 injection plist, Python compile+report JSON parse PASS; bot commit kết quả report vào feature HEAD `9a02b51aa30882cfd149aca3967edc17a5a3842c`.
- **Bằng chứng máy đọc được từ DEB**: `audit/speedbubble/GOFAHUD_031_ACTIVATION_NOTIFY_REAL_DEB.json` blob `80b33452efe645315982a922358404182483faf4`; status `GOFAHUD_031_REAL_DEB_ACTIVATION_SIGNALS_STATIC_PASS`. Strings ở module GOFA Lifecycle: `local.gofahud.gofa.foreground`; Global CarPlay: `local.gofahud.carplay.gofa-active`, `carplay.enabled`, `carplay.show`, `local.gofahud.source.ready`, `local.gofahud.background.carplay`, `activeBundleIdentifier`; LaunchHelper: `autoWake`, `autoExit`, `__ActivateSuspended`, `local.gofahud.background.carplay`, `local.gofahud.background.permission`; PhoneOverlay: `local.gofahud.gofa.foreground`, `local.gofahud.background.phone`. Điều này chứng minh tín hiệu/đường mã có trong **binary**, không tự khẳng định chúng đã chạy trên thiết bị.
- Nhánh mã/source đã đối chiếu với các tín hiệu trong DEB ở `manhtien9x/gofahud-repo@e423ac7:source/rootless/` (tên blob đã ghi trong báo cáo layer trước). `release-layout/DEBIAN/postinst` có thông điệp **“Respring to load the bubbles, then reopen GOFA”**. Tín hiệu sống không tự đồng nghĩa UI đã hiện.
- Run này không install hay stop daemon nào trong iPhone; chỉ runner GitHub đọc archive.

## 1. Chính xác điều kiện xuất hiện sau khi MỞ rồi RỜI GOFA (không cần giả thuyết)

Đây là HAI cơ chế foreground hoàn toàn khác:

### A. CarPlay UI GOFA active
Source `tweak/carplay-global-overlay.m` lines 124–131: `CarPlayApp` lấy `UIApplication.sharedApplication.delegate._currentDashboard.activeBundleIdentifier`; nếu là `com.lumi.GOFA` gọi `GOFACarHUDSetGOFAActive(YES)`, nếu rời GOFA sang Home/Maps/nhạc thì gọi `GOFACarHUDSetGOFAActive(NO)`.

Source `tweak/carplay-overlay.m`:
- lines 20–25: `InitializeCarControls()` register `local.gofahud.carplay.enabled` (state ngầm); `local.gofahud.carplay.gofa-active`; callback `local.gofahud.carplay.show` **chỉ** `notify_set_state(enabledToken,2)`; external display connect cũng set state 2. Không tạo UIWindow, không attach host và không tự cấp data source.
- lines 27–31: `GOFACarHUDSetGOFAActive(active)` ghi `carActive=1` nếu GOFA active, =0 nếu không. Nếu **previous=YES → active=NO** thì set enabled=2, cho hiển thị lại cả sau khi người dùng từng kéo vào X.
- lines 73–78: `GOFACarHUD.refresh` tự **ẩn** nếu window không có, `GOFAHUDEnabled(YES)` false, **enabled==1** (đã dismiss), **carActive==1** (đang hiện app GOFA). Nếu thiếu dữ liệu speed/limit, lines 106–115 vẫn điền `--`, KHÔNG tự ẩn vì thiếu dữ liệu.
- lines 155–158: kéo HUD vào X ⇒ `local.gofahud.carplay.enabled=1` (ẨN); rời GOFA sau khi GOFA đã ở trước ⇒ state 2 (CHO HIỆN).
- File `tweak/test-speed.m` có lệnh `carplay-show` chỉ `notify_post("local.gofahud.carplay.show")`; **không đánh thức GOFA**. Lệnh `carplay-open` phát `local.gofahud.carplay.open-gofa` để CarPlayApp mở GOFA, **khác với lệnh show**. Không tự ý dùng lệnh trên xe/người dùng.

### B. iPhone foreground/background
Source `tweak/gofa-lifecycle.m` lines 9–18 inject vào `com.lumi.GOFA`, đăng ký `UIApplicationDidBecomeActiveNotification` -> `local.gofahud.gofa.foreground=1`, `WillResignActive`, `DidEnterBackground`, `WillTerminate` -> state 0. Nó KHÔNG chịu trách nhiệm trực tiếp cho CarPlay's activeBundleIdentifier.
`tweak/phone-overlay.m` lines 144–154: nếu GOFA foreground thì `overlay.hidden=YES`; khi GOFA rời foreground reset `dismissed=NO`, sau đó hiện nếu phoneEnabled/không khóa v.v. Riêng `local.gofahud.phone.show` reset phone dismissal. Như vậy mô tả “mở GOFA rồi thoát cửa sổ GOFA mới có bong bóng” phù hợp thiết kế **ẩn khi GOFA foreground / phục hồi khi rời GOFA**, không chứng minh GOFA là API bắt buộc duy nhất để **tạo** HUD.

### C. Ai thực sự tạo HUD CarPlay?
`carplay-global-overlay.m` lines 196–215: constructor StartGlobal trong `com.apple.CarPlayApp` hoặc `com.apple.CarPlayTemplateUIHost`, cấp manager riêng, Tick ngay, observer UIWindowDidBecomeVisible, timer 0.5s. Tick tìm eligible system CarPlay window. Nếu base CARNotificationWindow ở CarPlayApp: `[base.rootViewController.viewIfLoaded addSubview:GOFACarHUD]` + `bringSubviewToFront`. Nếu loại khác: tạo `GOFACarGlobalWindow` UIWindow trong scene/screen với level 10000000 và card; cross-process lease `local.gofahud.carplay.global` giữ một owner.
**KHÔNG gọi StartGlobal từ notify_show**. Constructor tạo cơ chế khi dylib được inject; `show` chỉ đổi hidden state; một cửa sổ/owner không hợp lệ thì notify_show không giải quyết.

## 2. Vì sao phải mở GOFA ít nhất một lần để có SỐ TỐC ĐỘ (khác chuyện có bóng)

- Trong DEB thật, `GOFADevProbe.dylib` filter `com.lumi.GOFA` + Google Maps. Source `probe/hud-message-probe.m`: GOFA probe khởi tạo các token producer/speed/limit/camera, source event mới gửi `GOFAHUDProducerName=(uint64_t)getpid()`, speed/limit theo timestamp; lúc constructor còn xóa state cũ. Tạo HUD không phụ thuộc có sample.
- `tweak/native-speed-bridge.m` daemon mỗi khoảng 1 giây tìm tiến trình GOFA, thử `jbctl proc_set_debugged <GOFA PID>` (nếu thành công) rồi xuất `local.gofahud.source.ready=PID`. Khi GOFA PID biến mất đưa ready về 0. Đây là đường “GOFA source prepared”, không phải lệnh vẽ bubble.
- `carplay-overlay.m` lines 106–115: data valid khi `producerPID != 0 && producerPID == readyPID`; nếu không, `--`. GOFA app cần chạy và phát mẫu mới, không được biến notify_show thành dữ liệu thật.
- `tweak/background-supervisor.m` chạy trong SpringBoard khi có module `GofaLaunchHelper`; `autoWake` trong preferences **mặc định OFF** (source `prefs/controller.m` lines 399–401). Nếu bật, có permission location hợp lệ + CarPlay connected + heartbeat host gần đây + không autoExit đang ngắt, supervisor có thể gọi `FBSOpenApplicationService.openApplication(..., {"__ActivateSuspended":YES})` để thử đánh thức GOFA; PID sống thì giữ RunningBoard assertion. **Mã cũng ghi rõ việc launch không bảo đảm dữ liệu tươi hoặc GOFA chạy thực**. Không tự động xảy ra khi chỉ phát `carplay.show`.
- Heartbeat cho supervisor là `local.gofahud.background.carplay` (source `common/background-policy.h`), được cập nhật trong `GOFACarHUD.refresh` lines 73–80. **CHÚ Ý: nếu `carEnabled=NO`, refresh trả về ở nhánh 77 TRƯỚC KHI ghi heartbeat (line 79)**. Đồng nghĩa việc tắt renderer CarPlay bằng prefs có thể làm `autoWake` mất nguồn heartbeat. Trên iPhone, phone HUD heartbeat khác `local.gofahud.background.phone` vẫn có thể hoạt động nếu hiện.

## 3. Yêu cầu mới: không được có 2 bong bóng, không để Home hiện dù có lệnh show

1. **Ưu tiên tắt hiển thị CarPlay của GOFAHUD gốc qua cài đặt chính thống**: `Cài đặt → GOFA HUD → CarPlay → Hiển thị bong bóng` chuyển OFF => preference domain `local.gofahud` key `carEnabled=false`; `bubbleEnabled` là master, không tắt master/GOFA source nếu cần điện thoại. Source `common/bubble-style.m:14–43` tính GOFAHUDEnabled(YES) từ `bubbleEnabled && carEnabled`; `carplay-overlay.m:77` sẽ ẩn card kể cả khi có lệnh show. Cờ này là **ẩn card**, không chứng minh GOFA global UIWindow đã được giải phóng: Tick vẫn có thể tạo UIWindow trong và gọi Refresh nhưng card.hidden=YES. Không tùy tiện can thiệp dylib của third party đang cài.
2. **Không phát lệnh `local.gofahud.carplay.show` để hiện HUD DuoFace**: GOFAHUD nhận tại CarPlayApp/TemplateUIHost, sẽ định vị ở window bên ngoài theo global CarPlay logic, không biết DuoFace. Nếu gốc vẫn carEnabled ON, có thể cùng lúc hiện GOFAHUD ngoài CarPlay và DuoFace HUD (hai renderer không chia lease); đây đúng rủi ro user nêu. Speed2 đã tạo ≥3 HUD trên CarPlay Home theo ảnh.
3. **Nguồn ≠ renderer**: dùng một HUD riêng của DuoFace, không inject thêm GOFA global renderer vào package. Activation gated **split owner đúng + actual activated/current pane**; tạo/destroy một card trong chính host view hoặc scene verified; chỉ dữ liệu đến từ producer GOFA sau khi source ready/valid. `DuoFaceSpeedHUD` version 5 trên SpringBoard chưa chứng minh loaded/owner/visibility; cần tách diagnostic loader/owner khỏi đánh thức GOFA.
4. **Nếu cần tự thức nguồn trong tương lai**: thiết kế heartbeat riêng của DuoFace có hiệu lực **chỉ khi split ACTIVE** và, nếu quyết định dùng GOFA supervisor `autoWake`, cần đồng bộ host-activity heartbeat được pin `local.gofahud.background.carplay` (tại supervisor) với TTL/owner thật; gọi autoWake có kiểm user opt-in + permission và tránh vòng lặp open-GOFA/thành active trên CarPlay → HUD bị ẩn. Phải không đánh thức khi Home, không tự khởi GOFA nếu họ chỉ muốn HUD placeholder, không can thiệp Waze/YouTube Music. Chưa thực hiện bất kỳ thay đổi publisher/wake token nào.
5. **Nếu GOFAHUD vẫn cần chạy trên iPhone**: giữ `phoneEnabled` riêng theo sở thích người dùng, nhưng không phát CarPlay show. Khi GOFA active trên CarPlay, cả renderer DuoFace lẫn GOFAHUD gốc phải không xung đột; toggling activeBundleIdentifier được dùng chỉ như nguồn tín hiệu, không là điều kiện xác nhận split active.

### Tiêu chí test bắt buộc trước khi phát hành
`Home=0`; `GOFA foreground on CarPlay=0`; `DuoFace split active=1` HUD duy nhất; `DuoFace dismissed/disconnected=0`; đổi pane/zoom/reconnect không nhân đôi; Waze không tự thoát; nguồn GOFA chưa mở thì vẫn thấy `--/--` khi split active; khi GOFA chạy và readyPID=producerPID + sample chưa quá hạn thì thay số thật; `carEnabled=OFF` không ngăn hiển thị DuoFace nhưng không tạo GOFAHUD ngoài Home. Tách thành hai gate: **UI mount** và **data wake**. Không thể khẳng định đạt tiêu chí mà chưa chạy thật iPhone iOS16 Dopamine rootless.

## 4. Trạng thái bàn giao và điểm tiếp theo

**ĐÃ XÁC MINH**: published binary GOFAHUD `0.3.1` SHA, presence của notify tokens/autoWake trong đúng dylib, source conditionals/triggers và UI toggles, CI PASS #38991653621. **CHƯA XÁC MINH**: máy user có đúng GOFAHUD rootless 0.3.1 không, GOFAHUD carEnabled hiện ON/OFF không, source data ready PID trên máy, Speed5 SpringBoard injection loaded hay chưa, split host in process nào, có chồng nhau ngoài thực tế không. **KHÔNG kết luận** “chỉ cần GOFA activation signal” sẽ hiện trong DuoFace.

NEXT nếu user chỉ định sửa: đọc Native12 `CBBridgeManagerDashboard` active/foreground/split lifecycle và Speed5 `DFSceneReconcile` chính xác; tạo diagnostic scoped vào đúng host, kiểm event progress (constructor loaded → proper PID/window → split active → attach HUD → render); thêm một duy nhất split owner và disable GOFA CarPlay renderer an toàn không phá third-party preferences. Chỉ sau đó xem xét bật autoWake tùy chọn. Không build / không Sileo / không NewTerm trong lượt này.
