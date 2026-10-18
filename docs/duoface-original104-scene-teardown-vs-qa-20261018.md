# Đối chiếu chính xác lifecycle DuoNavi gốc 1.0.4 với DuoFace QA — 2026-10-18

## Phạm vi và nguồn kiểm chứng

- Repository: `chuongnguyen89dn-ui/Duoface`, nhánh `feature/visual12-duodash-recovery`; tiền đề người dùng cung cấp: `a529b39`.
- Mã tham chiếu **gốc**: `dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb`, SHA256 `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`. Mach-O đã giải nén: `DuoNaviDashboard.dylib`, SHA256 `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`.
- Bằng chứng: `audit/duonavi-original104-scene/REPORT.md` (lấy từ `otool` / `llvm-objdump` thật trên macos-15), Actions runs [39082350491](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39082350491) và [39082485471](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39082485471), đều `completed/success`. Report lần 2 được commit `9852ca66bfb55d482283fb8370120a0b575dde12`.
- **Đây là bằng chứng tĩnh ARM64 của DuoNavi 1.0.4, không phải thuật toán V12 được đoán từ tên hàm.** Không chứng minh runtime iOS16 có cùng trạng thái/lần gọi ở mọi nhánh, hoặc giải pháp đề xuất chắc chắn hết crash.

## Các IMP thật trong DuoNavi 1.0.4

| Class và method | IMP trong dylib gốc |
|---|---|
| `CBBridgedUIAppView dismiss` | `0xaedf8` |
| `CBBridgedUIAppView dealloc` | `0xaf4d8` |
| `CBWindow destroyWindows` | `0xb2d14` |
| `CBWindow dismiss` | `0xb30c4` |
| `CBWindow dealloc` | `0xb30d0` |
| `CBBridgedSplitApp closeSlot:` | `0x112318` |
| `CBBridgedSplitApp closeAllSlots` | `0x1128a8` |
| `CBBridgedSplitApp stop` | `0x1136dc` |

Các địa chỉ trên **không** phải offset của `DuoFaceDashboard`/Visual12.

## Chuỗi phương thức đọc được từ mã máy gốc

Trong `-[CBBridgedUIAppView dismiss]` (0xaedf8 đến ngay trước 0xaefb4), các lệnh định danh chỉ rõ đường thực hiện có điều kiện:

1. `setInvalidated:YES` tại 0xaee1c và `setHosting:NO` tại 0xaee30.
2. Khi còn app controller, kết thúc appearance transition (`beginAppearanceTransition:NO animated:NO` / `endAppearanceTransition`; 0xaee78/0xaee88).
3. Gửi `setRequestedMode:0` (0xaeeb4). Lệnh này **khác** `_setCurrentMode:0`.
4. `willMoveToParentViewController:nil` (0xaef0c), `removeFromParentViewController` (0xaef34).
5. Gửi `invalidate` lên controller (0xaef5c), sau đó zero strong ivar (0xaef64) và `objc_release` (0xaef68).
6. Gửi `invalidate` lên wrapper view (0xaef80) rồi zero ivar (0xaef88) và release (0xaef9c).

`CBBridgedUIAppView dealloc` (0xaf4d8) tự gọi `dismiss` (0xaf504) trước `[super dealloc]` (0xaf520), giúp teardown được thực hiện cả trên đường giải phóng lớp.

`CBWindow dismiss` (0xb30c4) chuyển trực tiếp tới `destroyWindows` (0xb30cc); `CBWindow dealloc` (0xb30d0) cũng gọi `destroyWindows` (0xb30fc). Trong `destroyWindows` có cleanup con trỏ, ẩn window, `resignKeyWindow` ở 0xb3054, và release các tham chiếu. Các lệnh trên có điều kiện, không khẳng định mọi nhánh đều chạy.

Trong `CBBridgedSplitApp closeSlot:` (0x112318), giải mã thấy `dismiss` (0x1125e8), `removeFromSuperview` (0x1125fc), và `sendStateToApp:shouldBridge:` (0x112648/0x112664). `stop` (0x1136dc) giải phóng/tháo trạng thái nội bộ. Vì kết quả trích mã máy có giới hạn cửa sổ và nhiều nhánh, chưa kết luận được mọi thứ tự/chuỗi gọi đa cấp ở cả ba phương thức.

## Đối chiếu DuoFace QA hiện tại

Nguồn đọc trực tiếp:
- `replacement/visual12/engine/runtime/DFIRuntime.m`: `DFV12SceneHost close` (vùng dòng ~269–325) và `DFIStop` (~340).
- `replacement/visual12/engine/runtime/DFCarPlaySplitCoordinator.m`: `cancelAndClose` và `stop`.
- `replacement/visual12/engine/runtime/DFCarPlayQARootController.m`: `shutdown`.

`DFV12SceneHost close` đang đánh dấu `closed`, invalidate timer, xóa hook maps; `willMove`/appearance transition; **`_setCurrentMode:0` thay cho `setRequestedMode:0`**; remove parent; restore scene settings và phone display; **không gọi `invalidate` lên `SBAppViewController`**; cuối cùng giữ `retiringController` qua `dispatch_after(5 giây)` rồi nil. Hai crash log sau khi thêm timeout có dấu `SBAppViewController dealloc` trong block disposal, nên timeout không đạt test.

**Khác biệt có chứng cứ có thể thử cô lập:** dùng API yêu cầu đổi mode `setRequestedMode:0` và teardown `invalidate` theo kiểu gốc, thay vì tự ép `_setCurrentMode:0` và giữ controller bằng timeout; bảo vệ idempotence và main thread. Điểm cần chú ý: trong QA, `phoneViews` là phone scene do hệ thống quản lý, **không đồng nhất** với wrapper `CBBridgedUIAppView` gốc; không tự ý invalidate các phone scene này.

## Quy trình sửa/kiểm thử ở bước kế tiếp

1. Patch **chỉ** `DFV12SceneHost close` trên nhánh QA (không sửa Native12/Hub8): log trạng thái trước khi đóng; chuyển `setRequestedMode:0` theo đúng API gốc; gọi `invalidate` nếu `respondsToSelector` sau khi detach; bỏ delay 5 giây khi đã có teardown hợp lệ. Giữ nguyên attach, G1/G2, picker, split, geometry và app bundle IDs.
2. Đổi nhãn version QA mới và output directory khác `dist/visual12-g1g2-qa` khi thực sự được yêu cầu build, **không ghi đè standalone5lifecycle** đang dùng.
3. Chạy compiler/build/sign/verify QA trên GitHub Actions (macOS runner) nếu được yêu cầu; lưu bản thử riêng và SHA256 trong repo, chưa phát hành Sileo tự động.
4. Test trên iPhone X iOS16.7.16: G1/G2, đóng một pane, đóng cả hai, reopen, disconnect/reconnect CarPlay, respring; so hai loại crash `-[SBAppViewController dealloc]` (autorelease vs block dispose). Đánh dấu pass chỉ khi người dùng báo và log xác minh.
5. Nếu vẫn crash, phải đọc exception reason/log/stack và kiểm tra lifecycle state, không lại tăng timeout hoặc gọi selector theo suy đoán.

**Trạng thái ở mốc tài liệu này:** đã giải mã và lập bảng đối chiếu; chưa patch runtime, chưa build DEB mới, chưa Sileo, chưa test thiết bị. Các bước trên là kế hoạch kiểm chứng, không phải kết quả.
