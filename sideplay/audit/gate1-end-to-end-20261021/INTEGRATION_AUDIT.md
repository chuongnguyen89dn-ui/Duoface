# DuoFace Gate 1: audit toàn tuyến CarPlay Home/scene, KHÔNG PHÁT HÀNH DEB
**Ngày:** 2026-10-21 (GMT+7) · **Repo:** `chuongnguyen89dn-ui/Duoface` · **Branch:** `feature/duoface-jb-embedded-appbridge-20261020` · **Mã đã kiểm:** `2f9b881a240aaac6ba8df8665e6143833a2058a0`
**Kết luận nghiệm thu: FAIL thiết bị / BLOCKED tiếp tục giao diện.** Người dùng bật bản `com.duoface.carplay.gate1smoke 0.0.3~enablefix1`, ảnh có `GATE1_ENABLED=YES` và `OLD_GATE_PAUSED_BY_GATE1=YES`, **không có icon trên CarPlay Home**. Cấu hình được bật, **KHÔNG** có bằng chứng entitlement gate đã được hỏi/trả lời lúc Dashboard dựng danh sách, ứng dụng có tên trong roster, icon-layout có ô, hay CarPlay cấp native UIWindowScene. Log được chụp dừng/cắt ở dòng startup cũ, chưa thấy đầy đủ log sau lần BẬT.

## Nguồn đã đối chiếu THỰC TẾ

1. Gốc DuoFace: `sideplay/carplay-gate1-smoke/{Gate1App.m,prepare.py,Info.plist,control,postinst,prerm,DFGate1SmokeAdmission.plist,tests/test_gate1.py}`, SHA blob trong `CHECKS.json`; `sideplay/firstparty-carplay-admission/{DFFirstPartyAdmission.m,DFFirstPartySpringBoard.m}`. Không đọc log mới từ thiết bị hoặc truy cập máy thật trong lần audit này.
2. iPhone X iOS16 ABI đã đo thực từ hồ sơ `sideplay/duoface-native-scene-host/ABI_ADMISSION_GATE_20261020.md`: CarPlay `LSBundleProxy` typed3 `@40@0:8@16#24#32`, typed2 `@32@0:8@16#24`, bulk `@24@0:8@16`; SpringBoard cached `boolForKey: B24@0:8@16`; CarPlay có `DBWorkspace.initWithOwner: @24@0:8@16`. Các ABI này chỉ là dấu chữ ký; không chứng minh phương thức trả kết quả, class `DBApplicationController` đã được load đúng thời điểm, hay quyền tạo scene.
3. Tham chiếu công khai nghiên cứu **kiến trúc, không sao chép**: `pavunato/carsurf` commit `72cd0f8bf8d0bd1086e78fe7c7be6fff715702f8`, `sbtweak/CSSceneManifestSpoof.m`, `sbtweak/CSSystem.m`, `sbtweak/CSCarKitPolicy.m`, `sbtweak/CSCarLaunch.m`, `apptweak/CSSceneBridge.m`, `docs/carplay-live-icon-sync.md`, `docs/troubleshooting-framework.md`; upstream README báo đo trên iPhone X iOS16.7.12. **Đó là tuyên bố upstream, không phải kiểm thử DuoFace**. Không thấy file LICENSE trong danh sách root tại commit đã xem: **không đưa mã nguồn hay binary upstream vào DuoFace**.
4. Apple `Displaying Content in CarPlay` (https://developer.apple.com/documentation/CarPlay/displaying-content-in-carplay): scene/scene delegate/manifest thông thường còn chịu sự quản lý CarPlay; chỉ khai báo `UISceneConfigurations` không tự khiến xe cấp một scene. Tài liệu này là luồng Apple chính thức, **không mô tả quyền jailbreak**.

## Kiểm toán theo thứ tự xử lý (KHÔNG đánh đồng status với chạy được)

| Giai đoạn | Trạng thái có bằng chứng | File/logic đã kiểm | Điều gì vẫn thiếu / chưa chứng minh |
|---|---|---|---|
| G0. DEB/LaunchServices/uicache iPhone | **STATIC PRESENT** | `control`, `postinst`, `build.sh`; Sileo run `39528590666` đã kiểm tải DEB | `uicache -p` đăng ký iPhone, không bắt buộc CarPlay Home tiếp nhận |
| G1. Injection SpringBoard + CarPlay | **DEVICE REPORTED LOADED** | Hai ảnh trước thấy `gate1-smoke-SpringBoard-loaded`, `[DFAdmission/CarPlay] loaded` | Ảnh không chứa đầy đủ callback/ABI sau khi bật |
| G2. Quyền thử nghiệm user | **DEVICE PASS PREF ONLY** | `Gate1App.m`: YES, manual timeout, khóa gate cũ | Không phải entitlement-return PASS |
| G3. Capability LSBundleProxy | **STATIC SOURCE PRESENT / RUNTIME UNKNOWN** | `DFFirstPartyAdmission.m`: typed2/3; được sinh qua `prepare.py` | Chưa có dòng sau bật `opt-in two typed getters armed` hay real getter call của bundle Gate1 |
| G4. Cached LSBundleInfo SpringBoard | **STATIC SOURCE PRESENT / RUNTIME UNKNOWN** | `DFFirstPartySpringBoard.m` tags original object, `boolForKey:` | Chưa có post-enable `springboard-firstparty-roster-hooks-armed`, `firstparty-bulk-cache-tagged`, `firstparty-flag-queried`; iOS16 app library có thể đọc accessor khác |
| G5. Inclusion/list của DashBoard | **KHÔNG IMPLEMENT LUỒNG CẬP NHẬT** | Gate1 không dùng `DBApplicationController`, `application-library-change`, không chạy chính thức `_newApplicationLibrary` | Cần xác định iOS16 đang gọi inclusion filter, roster có bundle hay không, khi enable sau startup phải có refresh hợp lệ. `DFFirstPartyAdmission.m` chỉ nêu tên selector trong **probe read-only**, không invoke factory |
| G6. Icon-layout riêng xe | **KHÔNG IMPLEMENT LUỒNG ĐỒNG BỘ** | Gate1 không dùng `CRSIconLayoutService`, `CRSIconLayoutState` | Có thể chưa phải blocker đầu tiên; phải chứng minh G5 trước. Không tự ghi/carve `CarDisplayIconState.plist`, không rebuild trắng toàn bộ icon |
| G7. Home icon hiển thị | **DEVICE FAIL** | Người dùng xác nhận vẫn không có icon | CANNOT infer thành công từ `GATE1_ENABLED=YES` |
| G8. Người dùng chọn icon / CarPlay DBWorkspace | **CHƯA TÍCH HỢP/NHIỆM VỤ CHƯA ĐẾN** | Không có `DBApplicationController.applicationWithBundleIdentifier:` + `DBWorkspace` launch path trong Gate1 | Khi có icon, hệ thống có thể tự xử lý click; chỉ quan sát workspace/launch trước, không tự gửi `requestStateChange:` |
| G9. UIKit-issued CarPlay scene | **DELEGATE ONLY / DEVICE UNPROVEN** | `Info.plist`, `Gate1App.m` có scene role & blue marker `GATE1_CARPLAY_SCENE_CONNECTED` | Scene do UIKit cấp vẫn chưa có. Không dựng fake window/che Dock. |
| G10. Phát app iPhone, touch, 2 ô | **OUT-OF-SCOPE GATE 1** | Gói độc lập cố ý không chứa host 2 app | Chỉ bắt đầu sau G7–G9 trên máy thật. |

**Đính chính gốc quan trọng:** không thể khẳng định duy nhất là thiếu Dashboard refresh; đó là **một khoảng trống mã được xác minh**. Vẫn có khả năng G3/G4 không arm sau notify, return-type không đúng, class chưa load, bundle Gate1 không có trong danh sách trước refresh, hoặc iOS16 cảnh báo scene role. Phải lấy phép đo _trên phiên sau Enable_ để cô lập điểm rơi, không vá kiểu đoán.

## Đối chiếu phương pháp đang thiếu so với ứng dụng tham chiếu

- **iOS16/17 không phải iOS18:** CarSurf tách nhánh iOS <18 dựa LS/scene spoof; iOS18+ mới dùng CarKit declaration. Không port nhánh policy iOS18 vào iPhone X.
- **Bắt đúng lifecycle:** CarSurf kiểm tra class/libraries load muộn và Dashboard inclusion filter. Hook Gate1 chỉ chuẩn bị typed getter, **không kích hoạt re-evaluate app library**; bật sau khi Dashboard cache xong sẽ không tự hiện icon. Vẫn cần biết Dashboard host iOS16 đang sống và quyền ABI trước khi thêm cơ chế refresh.
- **App library khác icon-layout:** `DBApplicationController` là bảng ứng dụng/roster, `CRSIconLayoutService` là bố cục icon theo xe; không dùng `CRSIconLayoutController` như đường ghi thật. Upstream cảnh báo từng có crash vì thao tác sai đối tượng; phải giữ nguyên icon OEM và các app khác.
- **Home click khác scene:** CarSurf có thành phần launch/workspace riêng cùng app-side scene role bridge. Gate1 chỉ khai báo vai trò `UIWindowSceneSessionRoleCarPlay` và chờ scene; đó là code xử lý scene **nếu hệ thống cấp**, không phải điều kiện khiến hệ thống cấp.
- **Không tái dùng code upstream thiếu giấy phép xác thực.** Học luồng/ABI/kiểm tra lỗi, viết độc lập đúng 1 bundle Gate1, tôn trọng ứng dụng khác.

## Thiết kế triển khai KẾ TIẾP (chưa code, KHÔNG PHÁT HÀNH)

**Bước 0 — read-only ABI & luồng runtime đầu tiên, tối thiểu**: thông qua Gate1 app hiện có, cần log sau bật (khác dòng startup), trong chính tiến trình CarPlay lúc đã kết nối: callback nhận notify, `DFHooksInstalled`, lớp DashBoard/`DBApplicationController`, selector `_proxyPassesInclusionFilter:` (nếu có) và ABI, `DBApplicationController` chứa `com.duoface.gate1smoke` hay không, per-vehicle icon thuộc pages/hidden (chỉ đọc), scene delegate. Không dựa vào class SpringBoard vì đã đo `DBApplicationController` không hiện ở SpringBoard. Không invoke mutation, không crash/respring.
**Bước 1 — khi và CHỈ khi có ABI/luồng thật:** module độc lập CarPlay-owner cho đúng 1 bundle, coalesced notify; hỏi lại bộ lọc và cập nhật roster qua pathway **đã đo**; không reset toàn bộ thư viện, không sửa persisted per-vehicle layout trừ khi đã biết exact service và snapshot/rollback. Log `INCLUSION_QUERY→ROSTER_HAS_BUNDLE→ICON_PRESENT` độc lập.
**Bước 2 — launch:** icon thật do CarPlay Home cung cấp → nhấn thật → `GATE1_CARPLAY_SCENE_CONNECTED` rồi Dock còn, không fake scene. Nếu scene không có, bắt callstack/role/entrypoint thực rồi sửa đúng khâu đó.
**Bước 3 — xác nhận hoàn chỉnh Gate1 trước feature:** ít nhất 2 phút Dock ổn định, rút/cắm, tắt kill switch và gỡ Gate1 không mất app cũ. Chỉ khi cả G7–G9 PASS mới bàn tới Native12/HUD8, menu, tách đôi.

### Ràng buộc phát hành cứng
- Sileo giữ phiên `0.0.3~enablefix1`; **không** tăng version/nhét thêm DEB/chạy job respring chỉ vì audit tĩnh.
- Không thay `Native12/HUD8`, gói QA ổn định, không thay SpringBoard Dock/window level, không cài CarSurf/SidePlay/DuoNavi làm tiền đề.
- Build + checksum + Sileo = bước kỹ thuật, **không** phải tiêu chí Home icon. Nếu thiếu ABI runtime chính xác, trạng thái là **BLOCKED/BẰNG CHỨNG THIẾU**, không đoán tên selector.
- Khi Gate1 đang bật nhưng không có icon, nên dùng nút `TẮT NGAY / KHÓA AN TOÀN` để hoàn nguyên marker gate cũ; không tự respring.

## Kết quả kiểm tra tĩnh lần này
Đã đọc 11 tệp DuoFace trực tiếp từ GitHub; kiểm tra có/mất các điểm nối từ nội dung mã, không sửa code runtime. Static evidence: gói tách riêng + UI/kill/consent + LS getters + manifest + delegate tồn tại; **không có luồng Gallery/Home roster refresh, icon-layout sync, DBWorkspace launch** ở Gate1. Lưu hash mã nguồn theo `CHECKS.json`. Kết quả người dùng đo máy thật **Home icon: FAIL**; scene **NOT_VERIFIED**. Không suy ra mọi hook hoạt động chỉ từ image `GATE1_ENABLED=YES`.

**Next actionable:** thu thập đúng *post-enable* process evidence G3/G4 và app roster G5 (có thể từ QA log đã ghi) rồi viết duy nhất adapter CarPlay Dashboard có guard ABI; chưa thể phát hành phiên tiếp theo có cam kết hoạt động nếu thiếu phép đo này.