# Native12 HUD8 vs DuoFace 0.0.66 — nguyên nhân crash và app trong từng ô chia
Ngày 26/10/2026. Repo: `chuongnguyen89dn-ui/Duoface`. Nhánh `feature/duoface-jb-embedded-appbridge-20261020`. Phân tích tài liệu nhị phân gốc và source hiện tại, **không sửa runtime, không build, không phát hành**.

## Bằng chứng gốc
- DEB gốc: `dist/payload-migration/native12-speed8compact/com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb`, commit `1286a3ef868cf7e29804bcddf7e20b2eae707ce1`, SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`. Dashboard Mach-O SHA256 `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`.
- Đã đọc **JSON instruction ARM64 trước đây quét trực tiếp từ đúng binary SHA**: `sideplay/audit/native12-continuation-4888299/original-video-layout-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json` Git blob `aa86461c6f592f0bfe22eb6c3dc71ae89358633f` (9 IMP/2653 lệnh), và `sideplay/audit/native12-continuation-4888299/direct-original-logo-media-20261024/REPORT.md` (CI [40051664327](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40051664327), quét lại original 17 IMP/4378 lệnh SHA xác nhận). Phiên này **không tải/giải nén lại bytes DEB** vì máy chạy không phân giải được raw.githubusercontent.com; không giả nhận có scan mới.
- Source phiên bản .66 ở `DFSceneHost.m` blob `8158cf23288092fb374101ab090b09ab87696539`, `DFNative12Chrome.m` blob `dac3ec533c3e0e9827f555780fa70d50c7f173b5`, `DFAppPickerVC.m` blob `103e6ecf1a122ccb1f55fec2f4ec1d070ad24d9d`. .66 build Actions [40271820331](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40271820331) PASS, SHA256 `7445e1868df33d3823eec7009af882eb18a027f7895f53ff8286ae4782897039`, archive `sideplay/jb-embedded-appbridge/evidence/runs/40271820331/`, **chưa Sileo/hardware**.
- Có đối chiếu cả ghi nhận lịch sử `DuoFaceAudit.txt` và `DuoFaceAudit 4.txt` trong Library; không đưa log có định danh thiết bị lên GitHub.

## Giao diện app phát trong MỖI Ô — nguồn gốc đúng
Original **không tạo một YouTube player giả**. `CBBridgedSplitApp.layoutSplitViews` IMP `0x1044f8` bố trí ô/touch/focus và gọi mỗi `CBBridgedUIAppView`; trong đó có `_appViewController` chính là `SBAppViewController` (ivar offset24) và `_wrapperView` (UIView, offset32). App thật tự hiển thị giao diện player. Chuỗi đã đối chiếu:
1. `CBBridgedUIAppView.refreshSceneLayout` IMP `0xade58`: **updateLayout (0xacc6c) -> updateSceneSettingsFrame (0xad5bc) -> setNeedsLayout/layoutIfNeeded**.
2. `calculateNativeSizeForSlotRect:` IMP `0xacc28`: round(2 × chiều rộng/cao ô). `updateLayout` đặt child native frame, reset transform, dùng scale đồng nhất min(width/nativeW,height/nativeH), căn giữa và guarded `setContentReferenceSize:withContentOrientation:andContainerOrientation:`, `setHomeGrabberDisplayMode:1`.
3. `updateSceneSettingsFrame`: xác định scene owner, có fallback `CBWindow.carPlayUsableBounds`, gửi guarded child2/child3/main2, gọi `updateSettingsWithBlock:` tại `0xadacc` với invoke `0xadc74`: set actual FBS scene frame (và các cờ foreground/occlusion/lock/idle). Không được chép hàng loạt private flags/giấy phép sang bản độc lập.
4. `CBBridgeManager.renderSizeForBundleID:` IMP `0x24c920` (510 lệnh) chứa policy theo app/focus/renderSize/CarPlay usable bounds. `setAudioOnlyBackgroundMode:` IMP `0xac858` điều khiển visibility/touch và relayout. Không thể đồng nhất giao diện của mọi ứng dụng bằng cách xoay cứng landscape.

**Lỗi thiếu đồng bộ đã XÁC MINH trên source .66:** `DFSceneHost.m:129–173` gọi **initial remote geometry seed trước khi `setRequestedMode:2`**, khi child private controller có thể chưa tồn tại; `layoutScene` 184–228 chỉ scale **UIKit host**. Sau khi `ready=YES`, `commitSceneGeometry` 229–269 **luôn đi vào `if(self.ready)` và return**, log `live-scene-private-reference-update-suppressed`; đường child 3-arg / real scene settings phía sau trong chính hàm này không bao giờ được chạy cho scene đã sẵn sàng. Vì vậy thay đổi khung cục bộ không đảm bảo thay đổi viewport render gốc của app. Đây là **source-level remote viewport sync gap**, giải thích giới hạn kiến trúc của UI bị bó; **chưa chứng minh lý do chính xác của mọi khoảng đen/cắt portrait** vì remote pixel/orientation còn phụ thuộc từng app.

**ĐÍNH CHÍNH audit cũ:** `DFNative12Chrome.m:762–782` của **bản hiện hành** đã tạo **MỘT `sharedAppWindow`** chứa bốn `appSceneContainers`, `layoutControls` 1165–1206 chỉ thay child UIView frame. Không được lấy kết luận cũ (.37/.46) “bốn app UIWindow khác nhau” làm nguyên nhân hiện tại nữa. `DFAppPickerVC.m` hiện đã có blur MaterialDark, tab tiếng Việt, badge; khác bản .41 trong báo cáo cũ. App picker ≠ thực thể player trong từng pane.

**Log thiết bị lịch sử KHÔNG được đọc như kết quả .66:** file tích lũy `DuoFaceAudit.txt` có 138 lần dispatch, 85 `child3=1` và 53 `child3=0`; các lần 0 phần lớn xuất hiện trước mode2. Mẫu YouTube `child3=1` xác nhận receiver từng nhận selector trong phiên trước nhưng **không xác nhận pixels đúng, không chứng minh call không crash**; .66 hiện chủ động suppress live writes.

## Crash thực tế — ranh giới chứng minh
Báo cáo đã đọc ba .ips iOS 16.7.16 ở `sideplay/audit/native12-039-regressions-20261023/MEDIA_VIDEO_CRASH_CROSSWALK_20261023.md`: SpringBoard **EXC_CRASH/SIGABRT**, lastExceptionBacktrace tới `-[SBAppViewController sceneHandle:didUpdateSettingsWithDiff:previousSettings:]` **+440**, qua Foundation `_userInfoForFileAndLine`, SBSceneHandle/FBSceneMonitor/FrontBoard. Đây là **lỗi trong xử lý thay đổi scene settings**, không phải stack AVPlayer được chứng minh. IPS không có assertion reason và không xác nhận đúng package đang cài: **chưa thể kết luận selector/invariant chính xác làm abort**, cũng không quy lỗi GhostBoard chỉ vì thư viện được nạp.

Khoảng khác gốc đáng chú ý:
- `DFSceneHost` điều khiển trực tiếp controller, `setAutomatesLifecycle:NO`, `setIgnoresOcclusions:NO`, thiếu bridge state owner như `CBBridgedUIAppView`; `.37 -> .38` từng thêm synchronous layoutIfNeeded sau scene mutation, có thể gây reentry (GIẢ THUYẾT chưa xác nhận).
- `DFSceneHost.m:508–541` stop có generation gate, mode0, remove subview, parent removal, invalidate; original `CBBridgedUIAppView.dismiss` IMP `0xaf01c` có bridge-invalidated/hosting-owner trước khi mode0, remove app view rồi parent/invalidate rồi wrapper. **Không gửi setInvalidated:/setHosting: lên SBAppViewController** vì chúng thuộc bridge view gốc. `sceneSettingsBefore` hiện được copy khi scene ready và xóa trong stop, không reconcile/restore; đây là gap, không thể vá bừa bằng ghi lại snapshot.
- Hiện hành tắt live remote scene mutation sau ready để giảm rủi ro crash, nhưng cũng mất chức năng resize player. Không có test thiết bị .66 khẳng định crash đã hết.

## Kết luận bằng chứng
- **ĐÃ XÁC MINH:** lỗi thiếu đồng bộ **remote viewport khi resize các ô**, dù current shared UIWindow đã đúng hơn; player là nội dung của app thật.
- **ĐÃ XÁC MINH:** ba crash cũ xảy ra trong Apple scene settings-diff handler +440.
- **GIẢ THUYẾT:** race/invalid state giữa thay đổi scene settings, appearance/remote hosting, video/fullscreen/teardown gây abort; nguyên nhân assert cụ thể **CHƯA THU ĐƯỢC**.
- **CHƯA THỬ:** thực tế trên .66 của YouTube, 70mai, Maps khi phát/seek/fullscreen/drag/close/Home; khả năng fix crash và UI. CI PASS không phải device PASS.

## Bước tiếp nối kỹ thuật (không build/test lẻ)
1. Trong nguồn hiện có, đọc thực owner/scene generation + `FBScene.settings.frame` ở các checkpoint sau mode2, scene-attached, stable, Ratio, Zoom, Close; chỉ thêm log **read-only** vào cùng DEB khi có bản sửa, không tự tạo tweak ngoài. So khớp timestamp với IPS mới đã bỏ định danh, không suy nguyên nhân từ tên video app.
2. Tiếp tục decode nhánh `CBBridgeManager.renderSizeForBundleID:` 510 lệnh để lập policy app thật, không cố định orientation landscape, không giả UI; xử lý vùng lệch remote reference-size thông qua owner đúng/safe generation, **tránh đồng loạt private scene frame setter trong lúc drag**.
3. Chỉ vá hẹp sau khi xác minh ABI/owner và lifecycle teardown, giữ các chức năng khác (logo kéo trực tiếp, tỷ lệ, Zoom, Dock, App, Style). Một immutable DEB + CI + Sileo sau khi cho phép triển khai; kiểm tra 2 app thật/phát video trên xe đỗ.
4. Không phát lại .66 chưa có thay đổi, không tự khẳng định đã sửa crash, giữ .65 public rollback.

## Nguồn liên quan
`sideplay/audit/native12-continuation-4888299/SCENE_SETTINGS_BLOCK_DECODE.md`; `sideplay/audit/native12-continuation-4888299/DISMISS_SEQUENCE_ORIGINAL_VS_INDEPENDENT_20261022.md`; `sideplay/audit/native12-039-regressions-20261023/ORIGINAL_VS_CURRENT_LOGO_MEDIA_CRASH_20261024.md`; `sideplay/audit/native12-media-player-split-20261022/REPORT.md`; `sideplay/audit/native12-app-2debs-20261023/APP_BINARY_AUDIT_VERDICT_20261023.md` (.41, cũ); source hiện hành như trên.
