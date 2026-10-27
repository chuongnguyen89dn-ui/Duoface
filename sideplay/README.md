## HOÀN TÁC SILEO .75 — ĐÃ XÁC MINH CÔNG KHAI (27/10/2026 09:58 ICT)
- Sileo source `https://chuongnguyen89dn-ui.github.io/carplaydsp/` **đã thôi quảng bá .75** (user-confirmed màn bó + crash) và trở lại **.74** là bản hiển thị trong index.
- `carplaydsp/main` commit `51469c2f165a1802ad64fb408e3d9c2e9f74cea7`, YAML/actionlint run [40441233073](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/40441233073) SUCCESS; Sileo run [40441233181](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/40441233181): build SUCCESS, deploy SUCCESS, public DuoFace verifier job **121982567393 SUCCESS**. At 09:57:58 ICT verifer confirmed **one package** `0.0.74~media37host1`, SHA `5db93e7f4cfafb318dffd29b4e407122cb0235938353663a61c8e70c86e96034`; independently fetched public DEB checksum **OK**. Immutable .75 still hosted for forensic rollback/history, but is no longer Sileo selected.
- **NO FIX to crash**: 3 authentic .74 IPS still show SpringBoard SIGABRT; .75 user reports it also crashes, without fresh .75 IPS; user already installed .75 **must manually downgrade**, since Sileo will not auto-install an older version. For stability avoid running DuoFace until actual crash root found; disable tweak if repeated SpringBoard abort.
- Head source at commit `c992e881` restores .74/.37 effective content frame, source regression CI [40441197476](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40441197476) **SUCCESS**. This source is not a repackaged DEB, and .75 immutable binary remains unchanged. Do not claim hardware fix. Required next: fresh .75 IPS + time-aligned DeepTrace; examine 37→74 ownership and settings mutation, then only compile a new immutable version after evidence.

## KHẨN: .75 HỎNG HÌNH + VẪN CRASH / HOÀN TÁC GATE — 2026-10-27
- **LATEST DEVICE USER REPORT:** `0.0.75~framegate1` lại BÓ TRÌNH PHÁT **và** crash khi vào app. Báo cáo này thay thế giả định `.75` giữ trình phát `.37`. KHÔNG ĐƯỢC phát hành lại .75 hoặc tuyên bố crash đã sửa.
- **NGUYÊN NHÂN BÓ ĐÃ ĐỊNH VỊ THEO DIFF:** .75 hard-coded `DFEnableUnverifiedFBSceneFrameMutation()->NO`, làm chặn `FBScene updateSettingsWithBlock:/setFrame:` vốn hiện diện ở mã gốc .37 và .74. Chỉ giữ cửa sổ riêng/selector reference là **không đủ** để giữ hình video không bó. Quyết định ban đầu bỏ transaction này để thử crash là sai. Đối chiếu 3 phiên bản tại ref .37 `a8cdec6252b0e772faa726e92b84ee66246590ed`, .74 `6fa66d47ad0e2362448d49cc187c87d1ef9b187d`, .75 `120f6f4529a044f9be0282b60067fe1b04ffcfec`.
- **CRASH CHƯA KẾT LUẬN GỐC:** Ba IPS 09:13/09:20 chỉ thuộc .74; một lần không có marker frame-write mà vẫn SpringBoard SIGABRT +440. .75 user báo còn crash, **chưa có IPS của .75 để xác nhận stack**. Không suy diễn lỗi là do chỉ một lệnh frame hay từ YouTube, không đoán mã.
- **ĐÃ THỰC HIỆN TRONG SOURCE:** `DFSceneHost.m` bỏ hard-OFF gate, khôi phục đường frame .37/.74 commit `07dd6bbd`; `tests/test_scenehost_safety.py` đổi hồi quy để cấm chặn âm thầm frame commit `c992e881`; source-only test run [40441197476](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40441197476) COMPLETED SUCCESS. Đây **không** phải bản mới trên iPhone và **không** chứng minh crash sửa xong.
- **XỬ LÝ SILEO:** Distributor `carplaydsp/main` commit `51469c2f165a1802ad64fb408e3d9c2e9f74cea7` khôi phục quảng bá bản **.74 không bó** thay vì .75, giữ nguyên cả hai file DEB đã đóng dấu SHA; `40441233073` actionlint success; build/deploy/public SHA run [40441233181](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/40441233181) đang xử lý lúc ghi. **.74 vẫn crash theo 3 IPS cũ!** Chỉ là rollback hình ảnh, không phải bản ổn định. Máy đã cài .75 không tự hạ phiên bản qua Sileo.
- **TÀI LIỆU ĐIỂM TIẾP:** [FRAMEGATE075_DEVICE_FAIL_ROOT_DIFF_20261027.md](audit/native12-039-regressions-20261023/FRAMEGATE075_DEVICE_FAIL_ROOT_DIFF_20261027.md) — commit `9de3ecbc`. Tiếp theo: đợi kết quả publisher (không tạo run trùng); so .75 IPS mới và `DuoFaceDeepTrace.log` để tìm tác nhân scene observer crash; tuyệt đối giữ frame có thật của .37 trước khi xuất bản bất kỳ candidate mới, test thiết bị tách riêng source CI.
- Không có .76 DEB; các version `.74` / `.75` là immutable và KHÔNG được rebuild/reuse sau sửa source. `package_integrated.py` vẫn chứa `.75` frozen contract nên lần sau phải increment version đồng bộ trước build; `REQUEST.md` của bản .75 vẫn còn, không chạy lại khi chưa có crash evidence.

## .75 FRAMEGATE1 ĐÃ XUẤT SILEO — 2026-10-27 09:40 ICT (hardware still untested)
- **Real installed .74 FAIL evidence**: three 2026-10-27 SpringBoard SIGABRT +440 after application scene attach, cross-correlated with `DuoFaceAudit 2.txt` `build=0.0.74~media37host1`. Source note [CRASH_074_SPRINGBOARD_SCENE_DIFF_20261027.md](audit/native12-039-regressions-20261023/CRASH_074_SPRINGBOARD_SCENE_DIFF_20261027.md). Old label .67 in exporter is not installed binary version. `.74` had media .37 unboxed UI per user.
- **One A/B code change**: .75 `DFSceneHost.m` hard-OFF unsupported `FBScene updateSettingsWithBlock:/setFrame:` transactions; retain .37 child content-reference calls and four physical per-pane UIWindow ownership, current controls, logo, App, Zoom, Dock, ratio. Source-only static suite [40439048511](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40439048511) SUCCESS.
- **Signed .75 immutable DEB**: [packaging run 40439139227](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40439139227) SUCCESS, artifact archive commit `da0c1325d2a7864a22135f96a318ec16ba9b8e4d`, package `com.duoface.jb.embedded`, Version `0.0.75~framegate1`, arch `iphoneos-arm64`, path `sideplay/jb-embedded-appbridge/evidence/runs/40439139227/com.duoface.jb.embedded_0.0.75~framegate1_iphoneos-arm64.deb`, SHA256 `1d3b7301b71c1cdeeaeb80ec83282f5a6efc1d8da7b802cb362b7d0d47501c3e`; 30 payload files verified in provenance.
- **Sileo PUBLIC VERIFIED**: publisher `carplaydsp/main` commit `473b869ef509878339484b949977e4323617a77e`; YAML validator [40439428167](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/40439428167) SUCCESS; [build/deploy/verify-duoface-integrated-pages/verify-qa11-pages run 40439428179](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/40439428179) **ALL SUCCESS**. Public `Packages` advertises exactly `.75` package and matching SHA256; public DEB re-downloaded + SHA checked by job `121976854386` at 2026-10-27 09:39:43 ICT. Source `https://chuongnguyen89dn-ui.github.io/carplaydsp/`. Previous .74/.37 binaries retained for rollback.
- **NEVER claim fixed crash or unboxed viewport on .75 until phone test.** Crash at 09:13:19 had no frame-write marker; even with .75 OFF, another scene lifecycle/settings path may SIGABRT. User should update from Sileo only when parked, respring manually, select YouTube several times, test 70mai/ChatGPT and pane ratio/Zoom/Home. On failure, collect `.75` SpringBoard IPS + `DuoFaceDeepTrace.log`; correlate `fbscene-frame-write-disabled-crash074` and last observed scene/mode2 with exception. Do not enable frame mutation without device proof. No automatic device installation or reboot performed.

## .75 SIGNED DEB SOURCE BUILD PASS + SILEO PUBLISH STARTED — 2026-10-27 09:37 ICT
- Source-only run [40439048511](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40439048511) SUCCESS.
- Integrated macOS signing + package [40439139227](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40439139227) **SUCCESS**, source SHA `120f6f4529a044f9be0282b60067fe1b04ffcfec`; artifact archival commit [da0c1325](https://github.com/chuongnguyen89dn-ui/Duoface/commit/da0c1325d2a7864a22135f96a318ec16ba9b8e4d) read back.
- Exact integrated binary `sideplay/jb-embedded-appbridge/evidence/runs/40439139227/com.duoface.jb.embedded_0.0.75~framegate1_iphoneos-arm64.deb`, **SHA256 `1d3b7301b71c1cdeeaeb80ec83282f5a6efc1d8da7b802cb362b7d0d47501c3e`**, 30 files, 4 independent source-built modules; nativehost `0.1.84~framegate1` SHA `79e5a4dc01f8751930939300e88f27b1839463f574b20492c75333d8f357d0f2`. CI `PACKAGING_PROVENANCE.json` and `SHA256SUMS.txt` mutually agree.
- Publisher `chuongnguyen89dn-ui/carplaydsp/main` commit `473b869ef509878339484b949977e4323617a77e` adds only immutable .75 to Pages build, retaining .74/.37 binaries; expected APT entries=45, filter exactly one .75 and SHA verifies signed DEB. YAML validation [40439428167](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/40439428167) and Sileo build/deploy/public verifier [40439428179](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/40439428179) in progress at this checkpoint; **NOT YET claim Sileo public PASS**.
- Real device .75 / YouTube media size / no crash / orientations remain **UNTESTED**. This is controlled diagnostic candidate: only hard-off unsafe FBScene frame writes; user confirmed .74 playback full pane, must re-check .75 did not regress that.
- Continue: verify both publisher runs and exact public APT SHA, update checkpoint with actual results, then parked iPhone update/repro. If crash persists, collect new IPS and compare `FBScene` frame-gate log vs live child3/scene start without guessing.

## .75 FRAMEGATE1 — 2026-10-27 | CRASH .74 DEVICE FORENSICS & CONTROLLED SOURCE TEST
- User submitted `DuoFaceAudit 2.txt` and three SpringBoard .ips (09:13:19, 09:13:55, 09:20:32 ICT). All three are **SpringBoard EXC_CRASH/SIGABRT**, identical exception stack `SBAppViewController sceneHandle:didUpdateSettingsWithDiff:previousSettings:+440`, consecutive crashes 11–13 on iOS16.7.16. DeepTrace correlated each crash process PID to **installed running 0.0.74~media37host1**; top-of-audit label `.67` is outdated exporter version, not runtime evidence. They are not YouTube process crashes. Exact ObjC assertion reason is missing; no unique root cause proven.
- Exact sanitized timeline, retained raw attachment names and evidence classification: [CRASH_074_SPRINGBOARD_SCENE_DIFF_20261027.md](audit/native12-039-regressions-20261023/CRASH_074_SPRINGBOARD_SCENE_DIFF_20261027.md), committed `ddd7c955`. Raw IPS/audit have device/session identifiers and are **not uploaded**.
- 09:13:55 and 09:20:32 had explicit `native12-scene-settings-frame-requested` 8.65 s and 15.5 s before abort respectively; 09:13:19 aborted after YouTube attach **without that logged event**. Evidence supports isolating frame mutation in A/B; does **not** prove this one write caused all three.
- Implemented narrow .75 source-only candidate: `DFSceneHost.m` hard-OFF `DFEnableUnverifiedFBSceneFrameMutation()` guard around `FBScene updateSettingsWithBlock:/setFrame:`, while retaining .37 content-reference selectors, UIKit media scene scaling and 4 physical per-pane UIWindows in unchanged Chrome. The earlier unreleased `sceneHandle` stale-pointer owner gate from `26bc899d` is also present. No copy of licensed binaries.
- Version synchronization **source only**: nativescenehost `0.1.84~framegate1`, one integrated package `0.0.75~framegate1`; updated build.sh, control, DFDeepTrace, package_integrated.py, GitHub package workflow and source-contract tests. A historic assertion expecting unconditional ready-scene frame transaction failed [source CI 40438904889](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40438904889); it was corrected to assert the explicit OFF gate by `d49f00eb`. This was a source-test expectation, not an Objective-C runtime failure.
- Source CI [40439048511](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40439048511) at `d49f00eb` is **COMPLETED SUCCESS** (source contract and Objective-C iOS16 syntax). Build-request commit `120f6f45` triggered one integrated macOS package [run 40439139227](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40439139227), in progress at this checkpoint. This is NOT device test; do not announce .75 Sileo without publisher verification.
- Continue: confirm source CI PASS (including Objective-C iOS16 syntax), trigger existing combined macOS build only through `sideplay/jb-embedded-appbridge/build-request/REQUEST.md`, inspect immutable signed artifact/hash and publisher; then parked-device compare .75 v .74 including video viewport and 3 crash reproductions. If .75 still aborts without FBScene frame writes, next isolate child3 content-reference update or mode2 scene start with new IPS, not bulk surgery. Keep old immutable .74 for rollback and avoid claims of fixed crash/rotations until device evidence.

## .74 MEDIA ĐÃ HẾT BÓ, NHƯNG MỞ APP VẪN CRASH — 2026-10-27 09:17 ICT
- **DEVICE USER REPORT:** phiên bản đang trải nghiệm đã phục hồi cách trình phát .37 và ứng dụng không còn bị bó trong ô. Khi mở app, máy/app văng liên tục. Đây là **media viewport PASS theo báo cáo người dùng / launch crash FAIL**, chưa có `.ips` và `dpkg-query` xác định package/process trên đúng lần crash. Không được gọi .74 là ổn định hoặc suy kết luận từ CI.
- **CRASH TRIAGE:** IPS trước đây (2026-10-23) đã cho SpringBoard SIGABRT trong `-[SBAppViewController sceneHandle:didUpdateSettingsWithDiff:previousSettings:]+440`, nhưng **không phải IPS của bản .74**. Source .74 `sideplay/duoface-native-scene-host/DFSceneHost.m` vẫn gọi guarded content reference và `updateSettingsWithBlock:/setFrame:` sau scene-ready; việc này *có thể* cần đối chiếu nếu lại thấy đúng stack. Không tự chặn toàn bộ remote viewport setters vì người dùng vừa xác nhận hết bó hình.
- **SOURCE VULNERABILITY VERIFIED:** `pollScene:` trước đây chỉ nhận `self.scene` khi nil; khi `sceneHandle` đổi thực thể qua vòng đời app nó giữ scene cũ. `commitSceneGeometry:` trước đây không kiểm tra scene hiện tại đúng `self.scene` sau khi ready, có thể gửi lệnh sang stale FBScene. Đây là bug trạng thái rõ trên source; **chưa chứng minh nó là nguyên nhân crash người dùng**.
- **TARGETED SOURCE PATCH, KHÔNG ĐỔI UI .74:** commit [26bc899d](https://github.com/chuongnguyen89dn-ui/Duoface/commit/26bc899d89626276434a52846c89aee2ecb9011f) thêm gate `sceneIfExists == self.scene`, `isHostingAnApp` và child view attached trước private remote geometry writes; nếu scene bị thay đổi thì hủy timer cũ, reset ready/committed geometry, attach scene mới trong `pollScene:`. Không chặn initial .37 seed/mode2, không sửa `DFNative12Chrome.m` hay các nút, không đụng Dock, Zoom hoặc chức năng phát đúng .37.
- **TEST SOURCE CONTRACT:** commit [3966dbcd](https://github.com/chuongnguyen89dn-ui/Duoface/commit/3966dbcd8e4b0e0ca5e96b4aad65d80abca83c2b) bổ sung hai regression assertions về lệnh private chỉ xuất hiện sau xác nhận owner và stale timer bị hủy trước rebind. Source-only CI [run 40438173968](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40438173968) được GitHub tự kích hoạt **COMPLETED SUCCESS** tại 2026-10-27 09:24 ICT, job `121971882883`: 68/68 scenehost unit tests PASS (bao gồm cả hai ca SceneGenerationSafety074), 3/3 bridge, 7/7 palette, 9/9 preview, 7/7 package, 3/3 speed8, 9/9 divider PASS; Objective-C iOS16 SDK syntax checks PASS. **Chỉ là source CI: chưa build DEB mới, chưa xuất Sileo, chưa kiểm thử máy**.
- **CẦN BẰNG CHỨNG CHO CRASH MỚI (trước khi chữa sâu hoặc phát hành):** phiên bản đang cài từ `dpkg-query -W -f='${Version}\n' com.duoface.jb.embedded`, thời điểm văng, process SpringBoard/YouTube/ứng dụng khác, file IPS mới ở Cài đặt → Quyền riêng tư và Bảo mật → Phân tích & Cải tiến → Dữ liệu Phân tích, kèm 100 dòng cuối ở `/var/mobile/Library/Logs/DuoFaceDeepTrace.log` và `/var/mobile/Library/Logs/DuoFaceSceneHost.log`. Chia sẻ báo cáo đã ẩn ID thiết bị nếu cần. Đối chiếu `scene-instance-changed`/`scene-geometry-stale-owner-skip` với stack mới để tách crash lúc `setRequestedMode:2` khỏi crash do `updateSettingsWithBlock:`; tuyệt đối không gộp các giả thuyết thành kết luận.
- **NEXT:** source CI đã PASS; cần thu file IPS của đúng lần văng trên bản mới cùng log scene, khẳng định tên tiến trình + callsite trước khi đóng DEB tiếp theo. Không phát hành ngay guard chưa được thiết bị xác nhận. Giữ Sileo .74 hiện tại và immutable SHA256 `5db93e7f4cfafb318dffd29b4e407122cb0235938353663a61c8e70c86e96034` làm baseline; sau khi có IPS/log mới thì sửa đúng callsite/owner rồi build một DEB mới và xuất Sileo theo yêu cầu phát hành.

## .74 ĐÃ XUẤT SILEO — 2026-10-27
- Run https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/40436112173: build, deploy, verify-duoface-integrated-pages và verify-qa11-pages đều SUCCESS.
- Public Sileo duy nhất cho com.duoface.jb.embedded là 0.0.74~media37host1; public SHA256 5db93e7f4cfafb318dffd29b4e407122cb0235938353663a61c8e70c86e96034 được job tải lại kiểm chứng.
- .74 là build mới giữ chrome/menu/logo/Zoom hiện tại, media host theo .37; thay thế mục rollback nguyên .37 đã xuất nhầm. DEB các phiên bản trước giữ bất biến.
- Hướng dẫn: refresh https://chuongnguyen89dn-ui.github.io/carplaydsp/ rồi cập nhật DuoFace Independent lên .74, respring thủ công. Cả máy đã cài .37 hoặc .73 đều có thể cập nhật .74.
- CHƯA KIỂM CHỨNG: cài trên iPhone, phát/tua/xoay YouTube và các app khác, giao diện hết bó, không crash. .37 có lịch sử lỗi xoay nên không tuyên bố đã chữa xoay; cần kết quả .74 thực tế.

## .74 build PASS, Sileo đang triển khai — 2026-10-27
- Source commit 6fa66d47ad0e2362448d49cc187c87d1ef9b187d; source-contract run 40435764361 SUCCESS; integrated macOS compile/package run 40435764417 SUCCESS.
- Artifact bất biến commit cc11faf495c3d485f3b80f963e9cacff78a11304: sideplay/jb-embedded-appbridge/evidence/runs/40435764417/com.duoface.jb.embedded_0.0.74~media37host1_iphoneos-arm64.deb; SHA256 5db93e7f4cfafb318dffd29b4e407122cb0235938353663a61c8e70c86e96034. Đã tải lại, sha256sum và dpkg-deb -f khớp.
- Nativehost .83 SHA256 0dd8e4358d45c4e6c13a25462189c5983729139c7caaf07d6d4fcce877103b68; 4 module, 30 file, không có DFAppViewportRelay. Chrome nguyên mã .73; .37 chỉ là nguồn cơ chế media host.
- Publisher carplaydsp commit 02004c7735a5a8a93f777b424df011f7e3ca5393; run 40436112173 đang chạy. Sau verify-duoface-integrated-pages SUCCESS mới báo .74 đã lên Sileo.
- Shell git push không có credential (fatal: could not read Username); đã dùng GitHub connector tạo tree/commit và update ref với expected SHA, không force. Auto-review chặn dry-run ban đầu được xử lý bằng xác minh đúng repo/branch và tất cả suite pass trước thao tác gửi lại.
- Device playback/orientation/crash và nghiệm thu UI chưa thử. Bước tiếp: xác minh Sileo, cài .74 và thử khi đỗ xe.

## Yêu cầu sửa lại: .74 media37host1 — 2026-10-27
- SUPERSEDED: tái phát hành nguyên .37 là hiểu sai yêu cầu. Người dùng yêu cầu giữ UI/chức năng hiện tại và sửa giao diện phát theo .37, đóng DEB mới và xuất Sileo.
- Đã sửa local DFSceneHost.m theo nativehost .47 source 7cd4004d; giữ touch wake, deep trace và guard chống tái nhập. Chrome nguyên blob 9e5772b9d6fef1e2c6f7c0baca23367bda03113a; .73 thực tế đã có 4 UIWindow riêng, nhận định một-window trước đây sai.
- Bỏ relay .73 khỏi build/package; giữ source relay để nghiên cứu. Candidate .74 / nativehost .83, chưa có compile/device PASS tại thời điểm ghi.
- Kiểm tra local: nativehost 102, packaging 7, admission 7, v1a 27, bridgeqa 9 PASS; YAML parse, git diff --check PASS. Các assertion về luồng .73 đã bỏ được lưu trong audit thay vì coi là hồi quy hiện hành.
- Bằng chứng và phạm vi: [media37-current-ui-20261027](audit/native12-039-regressions-20261023/media37-current-ui-20261027/CHANGE_SCOPE.md).
- Bước tiếp: push build-request → workflow macOS → kiểm tra ký/payload → phát hành đúng artifact .74 lên publisher carplaydsp. Không quảng bá nguyên .37 là bản sửa. Thiết bị cần xác minh phát/tua/xoay, menu/logo/Zoom/timer/split và crash.

## Kết quả phục hồi .37 — Sileo PASS 2026-10-27
- Run 40434804592: build SUCCESS, deploy SUCCESS, verify-duoface-integrated-pages SUCCESS, verify-qa11-pages SUCCESS. Public Packages và DEB được job kiểm tra đúng version 0.0.37~native12dockzoom1, SHA256 2b6f274e684e5a6f1008dac960c87ff51744fddb5342ce42fcd74e5c61314beb.
- Sileo source: https://chuongnguyen89dn-ui.github.io/carplaydsp/
- Đây là tái phát hành nguyên DEB .37 đã có, không phải compile mới. Khôi phục đầy đủ payload .37, không ghép .73; chưa xác minh cài đặt, playback hoặc hết crash trên iPhone.
- Bước tiếp trên máy: refresh source, chọn DuoFace Independent → hạ phiên bản 0.0.37~native12dockzoom1; kiểm tra version và respring thủ công, thử split/phát/tua/xoay. Không gọi bản .37 là đã sửa lỗi xoay.
- CI: https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/40434804592

## Khôi phục toàn bộ .37 — 2026-10-27
- USER_DECISION: yêu cầu phục hồi cơ chế đúng bản 37, DEB và xuất Sileo. Cho phép phát hành rollback toàn gói.
- Đã tải nguyên DEB từ checkpoint d70d6b4, chạy sha256sum, dpkg-deb -I/-c/-e; SHA256 2b6f274e684e5a6f1008dac960c87ff51744fddb5342ce42fcd74e5c61314beb; 953968 bytes; package com.duoface.jb.embedded version 0.0.37~native12dockzoom1, iphoneos-arm64. Script cài chỉ uicache, không tự respring. Không chạy script trên host.
- Phục hồi bằng đúng binary lưu trữ từ run 39748923126, không rebuild từ .73 hoặc ghép riêng hàm. Các sửa UI sau .37 cũng trở về trạng thái .37. Không xác nhận hết lỗi xoay/crash trên thiết bị.
- Publisher carplaydsp/main commit 0417e7130b37e5d8037bcddd1f9417a56c0fd9d8: thêm nguyên .37 vào kho, giữ các DEB cũ, chỉ quảng bá .37 cho package này và kiểm tra SHA public. Run 40434804592 đang chạy lúc ghi; chưa tuyên bố deploy PASS.
- Bước tiếp: kiểm tra run https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/40434804592 và job verify-duoface-integrated-pages; sau PASS hướng dẫn chọn Downgrade .37 trong Sileo vì phiên bản thấp hơn .73. Xác minh phiên bản đã cài rồi respring thủ công và thử phát/tua/xoay khi đỗ xe.
- Nguồn dự án hiện tại chưa bị ghi đè về .37; bản phát hành phục hồi là artifact bất biến, nguồn nativehost gốc 7cd4004d422a79d9df85f23f16ff8f6f38af1125. Không có build compile mới hay test thiết bị trong lượt này.

## Checkpoint hiện hành — 2026-10-27 (.73 crash, tra cứu .37)

- Người dùng báo giao diện ứng dụng vẫn bó và SpringBoard crash ngay sau mốc `9f830a97`. Đây là FAIL thiết bị; chưa có IPS tương ứng để chỉ ra riêng lệnh gây crash.
- Đã khôi phục provenance thật của **DEB 0.0.37** (run `39748923126`, SHA256 `2b6f274e684e5a6f1008dac960c87ff51744fddb5342ce42fcd74e5c61314beb`) và đối chiếu 0.0.73; **chưa phát hành lại hoặc sửa runtime**.
- Đọc báo cáo đã bổ sung: [V37_NOT_FULLY_RESTORED_ROOT_DIFF_20261026.md](audit/native12-039-regressions-20261023/V37_NOT_FULLY_RESTORED_ROOT_DIFF_20261026.md), checkpoint commit [e170649](https://github.com/chuongnguyen89dn-ui/Duoface/commit/e17064946a78f8288adb0ff627132139551fdf7f). Tất cả bước tiếp theo và giới hạn kiểm chứng nằm trong báo cáo này; `sideplay/tiep tuc du an.md` 1.15 MB vượt khả năng sửa qua Contents connector hiện tại nên không được coi là đã cập nhật.

# SidePlay 1.0.4-1 — nơi kiểm kê, giải nén và phát triển DuoFace mới

**Nguồn và quyền sở hữu:** DEB do chủ dự án upload vào repo `Duoface`; đây là **tham chiếu nhị phân của sản phẩm SidePlay**, không phải mã nguồn do DuoFace sở hữu. Việc giải nén không cấp quyền sao chép/phân phối hoặc chuyển nhị phân của bên thứ ba thành ứng dụng DuoFace độc lập. Phần mã độc lập sẽ được viết mới và tách rõ khỏi bản tham chiếu.

## Đường dẫn đã kiểm chứng (18/10/2026)

- **DEB gốc, giữ nguyên:** [`../com.sideplay_1.0.4-1_iphoneos-arm64.deb`](../com.sideplay_1.0.4-1_iphoneos-arm64.deb).
- **Bản giải nén nguyên payload:** [`extracted-1.0.4-1/rootfs/`](./extracted-1.0.4-1/rootfs). Giữ đúng đường dẫn `var/jb/...`, file mode và byte. Empty directories được ghi nhận trong inventory (Git không lưu thư mục rỗng).
- **Debian control và script:** [`extracted-1.0.4-1/control/`](./extracted-1.0.4-1/control) có `control`, `postinst`, `prerm`; không chạy script.
- **Báo cáo kiểm kê thực tế:** [`audit/deb-1.0.4-1/`](./audit/deb-1.0.4-1): `summary.json`, `inventory.json`, `SHA256SUMS.txt`, `archive-file-list.txt`, `macho-load-commands.json`, `plists-decoded.json`, `image-dimensions.json` và `macho-strings/`.
- **Công cụ giải nén tái lập:** [`tools/extract_sideplay_deb.py`](./tools/extract_sideplay_deb.py).
- **GitHub Actions:** [`.github/workflows/sideplay-unpack-original.yml`](../.github/workflows/sideplay-unpack-original.yml); run [39114447674](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39114447674), thành công. Commit chứa payload thực: [`1288472a4bdb120acb7102f4b64b879ff4c7019a`](https://github.com/chuongnguyen89dn-ui/Duoface/commit/1288472a4bdb120acb7102f4b64b879ff4c7019a).
- **Hồ sơ tiếp nối:** [`tiep tuc du an.md`](./tiep%20tuc%20du%20an.md).

## Số liệu có bằng chứng từ run 39114447674

| Chỉ số | Kết quả |
|---|---:|
| SHA256 DEB | `7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c` |
| Kích thước DEB | 4.352.576 B |
| File thường trong rootfs | 136 |
| Mach-O binary (executables/dylibs) | 7 |
| Ảnh PNG | 119 |
| Plist | 9 |
| License-GMapHUD | 1 |
| File control | 3 |
| Symlink rootfs | 0 |
| Thư mục rootfs (kể cả thư mục rỗng) | 14 |

**Lưu ý quan trọng:** 7 Mach-O gồm ba `fat_macho` (`SidePlay.dylib`, `SidePlayHUDRelay.dylib`, `SidePlayPrefs`) và bốn `macho64`. Bảng load commands hiện mới quét trực tiếp các binary thin; với các fat binary, cần phân tích từng architecture slice trước khi có đầy đủ LC_LOAD_DYLIB/ObjC selectors. Dữ liệu `macho-strings/` là các chuỗi printable, không phải mã nguồn đã phục hồi.

Các file `SidePlay.plist`, `SidePlayHUD*.plist` là **OpenStep plist hợp lệ**, nhưng `plistlib` Python chỉ hỗ trợ XML/binary plist; mục `error: Invalid file` trong `plists-decoded.json` có nghĩa **parser không hỗ trợ định dạng này**, không chứng tỏ file gốc lỗi. Nội dung gốc vẫn được giữ nguyên trong `rootfs`.

## Những gì có thể và không thể sửa trực tiếp

| Loại file | Có thể sửa như source text? | Quy tắc |
|---|---|---|
| `control`, `postinst`, `prerm` | Có, nhưng thuộc gói tham chiếu | Không chạy/bê nguyên side effect (ví dụ `--sp-goodbye` kết nối server) vào DuoFace |
| `Info.plist`, `Root.plist`, MobileSubstrate filter plists | Có (XML/binary/OpenStep tùy file) | Sửa bản phát triển riêng; không đụng folder tham chiếu |
| PNG | Có thể thay bằng asset được phép sử dụng | Không mặc nhiên quyền chuyển toàn bộ ảnh sang project DuoFace |
| Mach-O `SidePlay`, `SidePlay.dylib`, HUD binaries và `SidePlayPrefs` | **Không có source .m/.h/.xm trong DEB** | Không thể chỉnh như mã nguồn ObjC; cần tự viết triển khai của DuoFace hoặc có source/ủy quyền hợp pháp |

**Không sửa trực tiếp byte trong `extracted-1.0.4-1/`.** Đây là **bản tham chiếu bất biến** để so sánh; sửa ở một thư mục nguồn mới có thể kiểm toán. Giữ phiên bản DEB gốc và checksum làm chuẩn hồi quy.

## Thứ tự tiếp theo

1. Đối chiếu chi tiết 7 Mach-O (fat slices/ObjC APIs), chẩn đoán IPC, app scene attach, lifecycle, CarPlay template và HUD hook. Việc này hiện **chưa đủ chứng cứ** để gọi là khôi phục source.
2. Lập bản đồ `SidePlay` hành vi ↔ `DuoFace` giao diện đã duyệt (Native12/Visual12/HUD8) và xác định rõ tính năng đã nghiệm thu.
3. **Viết mới** mã nguồn độc lập, sử dụng dữ liệu tham chiếu và API phù hợp; chưa can thiệp Native/Visual/Hub hoặc Sileo.
4. Kiểm thử trên iPhone X/iOS16 từng bước và lưu kết quả thật.

**Trạng thái:** giải nén + commit + báo cáo tĩnh **PASS**. Mã nguồn độc lập, compile, device test, Sileo **CHƯA thực hiện**.
