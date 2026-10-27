# Vì sao bản gốc xử lý được YouTube/Facebook, còn DuoFace độc lập .76 crash? — bằng chứng ARM64

Ngày 27/10/2026, nhánh feature/duoface-jb-embedded-appbridge-20261020. Báo cáo chỉ nghiên cứu; KHÔNG sửa runtime/DEB/Sileo và KHÔNG port nhị phân hay giấy phép của bên thứ ba.

## Cuộc quét DEB mới thực sự đã chạy

GitHub Actions [40445716116](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40445716116), job 121996396095: tất cả PASS, đã tải/kiểm SHA256 và quét trực tiếp hai DEB:
- **DuoNavi 1.0.4 GỐC**: dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb; SHA256 f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd. DuoNaviDashboard.dylib SHA256 44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15. 47 ObjC classes, 12 IMP mục tiêu, không thiếu.
- **DuoDash 1.1.3 Fullscreen427 REPACK, KHÔNG PHẢI STOCK**: từ repo DauDat-CarPlay/main, SHA256 ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465. Dylib SHA b41dd7f892bfd3722e95a40f764a989886078b4a30943c1f0b50d47b6e248a47; 40 classes, giải được 5 IMP IPC/app host + source ARM64 đầy đủ cho đúng 5 IMP. **Stock 1.1.3 có SHA 16ffab22... khác repack; chưa có bytes stock để tuyên bố chính xác 100%.**

Dùng Capstone 5.0.7 và MachO parser đã có trong nhánh first-party QA; dpkg-deb --fsys-tarfile chỉ đọc nội dung, không chạy binary/hậu cài. Nguồn và lệnh tái tạo nằm ở sideplay/tools/audit_original_duonavi_duodash_media_20261027.py + .github/workflows/duoface-readonly-duonavi-duodash-media-abi-20261027.yml. Tệp kết quả ĐÃ LƯU và đọc lại từ GitHub: sideplay/audit/duodash-duonavi-media-20261027/ORIGINAL_DUONAVI_VS_DUODASH_REPACK_IMP.json, Git blob e5be6e3f30cba8987830f69e8f97eef3de79fef5, 75,004 bytes. CI đầu 40445456513 FAILED tại MachO tagged classlist pointer 0x100000000db0d0, run 40445580060 SUCCESS nhưng IMP VM còn tagged; đã sửa và xác minh run 40445716116 SUCCESS. Không nhập nhằng failed run với PASS.

## 1. DuoNavi nguyên bản 1.0.4 có CHUỖI HỢP ĐỒNG thực, không chỉ chỉnh UIView

| Class/method và PC GỐC 1.0.4 | Điều xác minh được |
| --- | --- |
| CBBridgeManager.renderSizeForBundleID: @0x26fad0 (510 lệnh) | Chính sách theo bundle, appViews @26fc30, appFrame @26fcf8, splitPreset @26fdfc, splitRatio @26fe14. **Không chỉ round(2×pane) bất kể ứng dụng, focus, layout**. |
| CBBridgedUIAppView.updateLayout @0xac7cc (743 lệnh) | Gọi setFrame và hai ABI setContentReferenceSize:withInterfaceOrientation: @acb24, 3-arg content/container orientation @acb5c. |
| CBBridgedUIAppView.refreshSceneLayout @0xadc30 (54 lệnh) | Lệnh thực theo thứ tự **updateLayout @adc48 → updateSceneSettingsFrame @adc54 → setNeedsLayout @adcb0 → layoutIfNeeded @adcdc**. |
| CBBridgedUIAppView.updateSceneSettingsFrame @0xad368 (559 lệnh) | Kết nối child reference, sceneHandle @ad4d0, sceneIfExists @ad6ac, settings.setFrame @ada70 và các nhánh foreground @adadc, idle @adbe0. Đây là hợp đồng quản trị scene/visibility, không chỉ zoom. |
| CBBridgedUIAppView.setAudioOnlyBackgroundMode: @0xac334 | Thay đổi tương tác, updateLayout @ac3a8, refreshSceneLayout @ac3b8 khi thay đổi focus/background âm thanh. |
| CBBridgedUIAppView.dismiss @0xaedf8 | **setHosting: @aee24 xảy ra trước setRequestedMode: @aee94**. Có chủ thể bridge quản lý vòng đời. |
| CBBridgedSplitApp.layoutSplitViews @0x10bad8 | isDismissing @10bc18, setAudioOnlyBackgroundMode @10bcac và refreshSceneLayout @10bd54 được nối trong đường layout chính. |

KHÁC BIỆT TRỌNG YẾU: Mẫu Native12 HUD8 khác package DuoNavi104; IMP Native12 refresh @0xade58 không được nhầm với DuoNavi104 refresh @0xadc30. Đây là lần xác minh trực tiếp chính xác trong bản nguyên gốc 104. Original filter của DuoNaviDashboard.plist cho SpringBoard, CarPlay và app quá trình YouTube/Netflix/VLC; filter là bằng chứng phạm vi injection, chưa phải bằng chứng callback nào thực chạy trong video.

## 2. DuoDash 1.1.3 REPACK có TÁCH RIÊNG 4 nhiệm vụ

**(a) Host requests:** CNABSpringBoardObserver.onHostRequest: IMP 0xf968 (266 lệnh) và onHostRequestSplit: IMP 0xfd90 (366 lệnh) là 2 đường nhận khác nhau; split path ghi bộ số hình học ở 0xfe40–0xfe58.

**(b) Tạo host:** DDz2.cnabBuildSceneHostForBid:displaySize: @0x1b7a0 (204 lệnh) tạo thật SBDeviceApplicationSceneEntity + SBAppViewController. Luồng có initWithApplicationForMainDisplay: @1b858, initWithIdentifier:andApplicationSceneEntity: @1b8bc, gọi setIgnoresOcclusions:NO @1b8f4, setAutomatesLifecycle:NO @1b918, **setRequestedMode:2 @1b960–1b980**, sau đó mới tìm _deviceAppViewController @1b988, guarded setHomeGrabberDisplayMode:1. **DuoFace cũng tạo SBAppViewController và tắt hai cờ giống hệt: riêng phần tạo host không thể giải thích vì sao bản kia hoàn chỉnh**.

**(c) App-process state:** CNABUIApp.setBridgeState:width:height:orientation: @0x1f514, ABI v44@0:8B16d20d28q36, 114 lệnh. Thực sự nhận bool enabled, 2 kích thước, hướng. Kiểm tra hướng 1..4 tại 1f56c–1f578; chỉ khi enabled và width,height >1 thì ghi rect (0,0,w,h) vào state tại 1f610–1f624, rồi gọi các helper. Khi OFF đổi state lại. **Không phải empty stub**, nhưng chưa giải mã helper cuối tới UIWindowScene/trait: KHÔNG tuyên bố đã chứng minh mọi video tự reflow.

**(d) CarPlay UI:** DDz1.showLayoutPanes:natives:bids: @0x1543c (161 lệnh) nhận riêng mảng pane/native/bundleID, khác owner app scene. Version repack có thêm safety latch như các báo cáo cũ; cơ chế phục hồi sau crash khác với cam kết không crash.

**Sơ đồ đã chứng minh một phần:** SB observer nhận bundle/layout → host factory tạo scene thật/mode2 → app-side bridge-state mang width/height/orientation → in-car layout có consumer riêng. Những tín hiệu trợ giúp không đủ chứng minh Pixel UI hoàn chỉnh, nhưng kiến trúc phân lớp và ABI từng đoạn là thật.

## 3. OmniCar ORIGINAL 1.0.3 bổ sung một bài học khác

Original DEB SHA d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd. ARM64 lưu tại chuongnguyen89dn-ui/Omnicar/audit/OmniCar_AppBridge_exact_scene_settings_and_layout_20261023.md: ABHost.layoutPane: @0xec80 giữ riêng **physical pane bounds**, **logical view bounds = pane/zoom**, uniform transform + sceneBox, rồi sceneHandle → sceneIfExists → updateSettingsWithBlock @0xf048; block @f210 điều chỉnh setFrame @f248, setInterfaceOrientation @f280, setBackgrounded:NO @f2b8, setForeground:YES @f30c. Nói khác: nó quản lý mối liên hệ khung hình / trạng thái app / hướng. QA13–15 từng không giải quyết xoay video trên thiết bị, nên đây KHÔNG phải phép chữa an toàn có thể bê sang.

SidePlay 1.0.4-1 original verified IMP còn có frame-equality guard, restoreSceneFrame và “sceneFrameChanged”; đã lưu ở sideplay/native12-display/audit/SIDEPLAY_SCENE_FRAME_ARM64_CALLS_20261026.json, git blob 926b101f13b3db5b49e7cb9a4ee3866cb3c38086. Khôi phục scene trạng thái là vấn đề cần học, không phải gọi setter bừa.

## 4. Đặt cạnh DUOFACE INDEPENDENT .76: vì sao chưa đủ

Source hiện tại sideplay/duoface-native-scene-host/DFSceneHost.m, Git blob fd02d310fbe459508566fe55d49d076cbec9e335:

1. start @117–149 thêm child vào UIWindow, tắt occlusion/automaticLifecycle, làm layout, **commit geometry khi chưa setRequestedMode:2**, rồi mới mode2. Cả historical .73 đã quan sát child2/child3/main2 all 0 ở seed trước mode2, sau đó xảy ra một exception “bogus reference size” với CarCast. Đây là rủi ro đồng bộ có chứng cứ, **chưa chứng minh đó là lỗi video .76**. Tương phản: DuoDash factory mode2 rồi mới lấy child.
2. layoutScene @160–185 chỉ lấy pane*2 và scale UIView; 0.3s timer yêu cầu scene geometry. Không có bộ chọn kích thước dựa trên bundle/focus/usable bounds như DuoNavi104.
3. commitSceneGeometry @187–306 gọi child reference setters và ready-scene.updateSettingsWithBlock, nhưng **chỉ đổi setFrame**. Câu “media-reference-committed” @296–299 chỉ dựa trên BOOL setter được gọi, **không phải renderer/FBScene/app-window xác nhận đã áp dụng**.
4. pollScene @337–380 coi isHostingAnApp + view.window cùng scene là ready; không biết app UIKit coordinateSpace/trait sau video đã đổi hay chưa. Fullscreen media có thể thay đổi scene state **là giả thuyết ưu tiên**, cần log video thời điểm mới để kiểm.
5. stop @408–439 mode0, remove view/controller, invalidate, **ghi rõ close-no-private-settings-restore**, dù khi attach có lưu sceneSettingsBefore @369. Không có “setHosting” vì không có bridge owner wrapper (không được gắn bừa selector từ vendor lên SBAppViewController).
6. .76 chỉ inject chủ yếu SpringBoard/CarPlay, không có consumer app-side bridge-state tương đương DuoDash; khác biệt kiến trúc là ĐÃ XÁC MINH, nhu cầu thêm app-side injector là CHƯA CHỨNG MINH.

**KẾT LUẬN KỸ THUẬT:** Chúng ta đã dựng vỏ chia màn hình và một phần chức năng SBAppViewController, nhưng **chưa tạo được hợp đồng nhất quán** từ chọn app/focus/render policy → mode/scene ready → logical size + scene frame + orientation + foreground/media → xác nhận scene thực nhận → huỷ cập nhật cũ + khôi phục trạng thái. Các DEB kia chia trách nhiệm thành nhiều owner và quản lý lifecycle. Ta sửa từng triệu chứng bằng thay setFrame, app width/height, timer, dẫn đến màn bó hoặc SpringBoard assertion. Đây là chẩn đoán thiếu hụt CẤU TRÚC từ source, không phải nhận diện duy nhất exception reason.

Ba IPS .74: EXC_CRASH/SIGABRT trong SpringBoard SBAppViewController sceneHandle:didUpdateSettingsWithDiff:+440; một lần chỉ 0.36s sau attach trước frame-request, hai lần khác sau frame request. User báo .76 crash cực nhanh khi PLAY YouTube/Facebook; **chưa có .76 IPS** để khẳng định cùng stack/NGUYÊN NHÂN hoặc do chính AVPlayer. DuoDash chính thức cũng lưu ý tweak inject vào app có thể xung đột, và xử lý video cùng navigation tốn nhiều tài nguyên: https://sensetechlab.com/duodash/faq/ . Không có cơ sở đổ tội một tweak thứ ba chỉ từ usedImages cũ.

## Bước tiếp theo, tránh lặp sai lầm .75

- Dựa trên NHỮNG OWNER đã phân tích, thiết kế một chủ sở hữu state theo từng pane: bundle+sceneHandle+generation+focus+mode+referenceSize+orientation+frame; kích thước ứng dụng dựa trên quy tắc của app/focus/usable bounds **do chúng ta viết**, không ghép native license.
- Mỗi giao dịch trạng thái scene: Created → mode2 request → scene observed → reference+frame requested → state readback → accepted/rejected → video/focus → restore/release; không điều khiển trong khi generation cũ còn callback, không vẽ lại player giả, không hard-off frame vì .75 đã bó giao diện mà vẫn crash.
- Cần file NEW .76 DuoFaceAudit, chứa DuoFaceFatalException.log, và một SpringBoard IPS ngay lần nhấn PLAY ở xe đỗ để biết chính xác NSException.name/reason. Nếu logs .76 không thu được lý do, cần đúng method +440 trên bản iOS cài để kiểm từng invariant, không đoán orientation/flags.
- Mọi fix sau này phải qua source CI, signed DEB, Sileo checksum, và user physical video/Touch/Zoom/Dock acceptance. Chưa sửa runtime/DEB/Sileo vì **đã học được kiến trúc nhưng chưa xác minh assertion .76 cần sửa chính xác chỗ nào**.

## Lệnh tái lập và trạng thái

Runner ubuntu-24.04:
python3 -m pip install --quiet --break-system-packages capstone==5.0.7;
git fetch --no-tags --depth=1 origin feature/visual12-duodash-recovery;
git show FETCH_HEAD:migration/full_payload/native_test/audit_native12_carplay_add_app_chain.py;
git show FETCH_HEAD:migration/full_payload/native_test/audit_native12_license_class_xrefs.py;
sha256sum -c (hai DEB nguyên phiên);
dpkg-deb --fsys-tarfile (chỉ đọc);
python3 sideplay/tools/audit_original_duonavi_duodash_media_20261027.py --duonavi dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb --duodash-repack "$RUNNER_TEMP/DuoDash_repacked_not_original.deb" --out sideplay/audit/duodash-duonavi-media-20261027/ORIGINAL_DUONAVI_VS_DUODASH_REPACK_IMP.json.
Output CI: DUONAVI_DUODASH_ORIGINAL_VS_REPACK_MEDIA_ARM64_PROOF_PASS và MEDIA_EVIDENCE_COMMITTED_GITHUB, all steps successful. Handoff sideplay/README.md là đầu mối, original vendor repos không đổi.
