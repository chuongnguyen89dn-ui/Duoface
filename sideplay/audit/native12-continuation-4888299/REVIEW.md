# Native12 → DuoFace: audit tiếp nối 4888299 (2026-10-22)
## Phạm vi và khóa thực thi
- Repo chuongnguyen89dn-ui/Duoface; nhánh feature/duoface-jb-embedded-appbridge-20261020; HEAD đọc trực tiếp = 4888299bd4e6625323d7a01d894a3c7ab9fd6bb3.
- USER_DECISION: dò lại phần đang có; giao diện và chức năng phải tương đương Native12; không viết lại từ đầu; lưu ngay từng phát hiện. Giữ dự án độc lập, không nhập runtime giấy phép.
- Đã đọc nội dung ZIP trung tâm 01-github-continuity, 02-ios-deb-ipa-carplay, 05-research-debug-testing bằng fetch_file base64 + Python zipfile.
- Handoff tại 4888299 và HEAD có cùng blob cf341fa44273257175916097f82926f01cb7a55e.
- Actions 39729328883 (integrated .31), 39728888190 (host .38), 39729486916 (original count) trực tiếp trả completed/success. 39728980964 trả failure; không đổi thành success. Không khởi động lại job.
## CONFIRMED: nối Zoom chưa thực hiện tác vụ
1. DFNative12Chrome.m menuAction: case 1 chỉ emit:@"Zoom", log native12-global-zoom-owner-ack-pending.
2. DFTouchOwnerProbe.m DFSendCommand nhận Zoom và gửi stateSnapshot như post-action message, không gọi owner Dock.
3. DFNativeHostAppDelegate.m receiveTouchOwnerCommand cho Zoom qua whitelist nhưng chỉ kiểm snapshot rồi trả Accepted=YES; không có thay đổi Dock/usable rect hay rollback.
4. Vì vậy ACK ở tuyến này chỉ chứng minh nhận trạng thái; KHÔNG chứng minh Zoom đã ẩn Dock. Đây là thiếu nối thực tế trong source, không chỉ thiếu test thiết bị.
5. Native12 WIRING_REPORT.md phân biệt owner: CBDashboardShared.appDockVC (0x1217d8), CBBridgeManagerDashboard.updateCarPlayMetrics (0x2a4c24), CBWindow.carPlayUsableBounds (0xb0ef4), fullscreen transport + geometry + chrome + restore. Cần tái kiểm source/callsites trước khi thêm adapter.
## CONFIRMED: media orientation còn hardcode
- DFSceneHost.m layoutSubviews sau readiness gate vẫn gọi setContentReferenceSize:withInterfaceOrientation: với UIInterfaceOrientationPortrait; biến thể ba tham số cũng Portrait cả hai.
- Không được nói bản .28 đã hoàn thiện xoay/video. Readiness gate và tránh lặp resize là phần đã có cần giữ.
## CONFIRMED: 9 preview không đồng nghĩa UI hoàn toàn nguyên bản
- ORIGINAL_NINE_LAYOUT_SHAPES.md tham chiếu original renderer 0x9efe0, jump table 0x310d3e: 9 tag, cuối là 2x2.
- Chính tài liệu original chỉ ra gallery dùng 5 HOẶC 6 cột; DFNative12Chrome.m hiện hardcode 5. Threshold và toàn bộ frame/card/color chưa kiểm từ binary trong lượt này; không đoán.
- selectStylePreset: chuyển Solo chỉ giữ selectedSlot==1 trong hai bố cục 1/2; chưa có logic giữ slot 2/3 khi từ ba/bốn ô. Cần đối chiếu original presetSelected và app ordering trước khi sửa.
## Lịch sử phải đọc theo mốc
- GESTURE_CALLSITE_CROSSWALK.md cũ vẫn nói 8 layouts và hold .30s. Bàn giao mới tại 4888299 đã supersede thành 9 và 3s. Không lấy tài liệu cũ làm yêu cầu mới.
- REPORT.md media cũ phân tích .27; IMPLEMENTATION_0.0.28.md và source hiện tại phải ưu tiên khi đánh giá phần đã sửa.
## Bằng chứng và giới hạn
Đã đọc source, workflow và báo cáo gốc đã lưu; chưa chạy lại DEB gốc, chưa compile iOS, chưa sửa runtime, chưa test trên iPhone. Không tuyên bố giống hoàn toàn. Tool git ls-remote qua git.chatgpt-team.site thất bại xác thực; GitHub connector vẫn đọc/ghi được. Các bản local chỉ là bản đọc tạm.
## Điểm tiếp tục
1. Đọc raw focused callsites và source fullscreen của đúng Native12 để map caller → selector → owner → teardown.
2. Đối chiếu app-slot selection/Solo và gallery branch 5/6 từ original instructions.
3. Ghi bản đồ chức năng có evidence/unknown riêng; sửa từng chỗ đủ chứng cứ, dùng version mới nếu build; giữ nguyên .23–.31.

## Lô 2: đọc instruction gốc, không dựa tên hàm (2026-10-22)
- Fetch_blob c14525b4c0fa1dd13e93a7e754d892b160db1fc3 đọc đủ ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json; fetch_file đối tượng >1MB trả content rỗng, không phải file rỗng trong repo.
- setupPresetCardsInCardW:cardH:contentY: 0xa5e78 có 581 instructions. Gallery thực tạo CBOverlayScrollView (a5ef0–a5f1c); hiện tại bản mới tạo UIView trực tiếp, chưa có scroll gallery.
- Chính xác: inset ngang 14, khoảng cách cột 10, width=(cardW-28-(columns-1)*10)/columns; góc card 12; first row y=22; previewWidth=roundf(cellWidth-14), previewHeight=54, previewTop=6. Selected border 2 và unselected 1; selected card có checkmark.circle.fill 17x17.
- Bản mới: inset6/gap4/corner7, previewHeight<=23, thêm UILabel tiếng Việt cạnh preview và chưa thấy checkmark selected. Đây là khác biệt thực, không được gọi 9 thẻ đồng nghĩa đúng giao diện gốc. Hằng ngưỡng 5/6, row stride, card height đang decode từ địa chỉ Mach-O 0x3117d8/e0/e8/f8, không tự chọn giá trị.
- presetSelected: 0xaa4f0: ghi cùng tag vào splitPreset tại aa55c và splitMode tại aa570; lưu prefs tại aa6a4, post Darwin aa6f0, gọi block onMultiSplitSelected với (tag, copy apps, ratio) tại aa73c–aa76c; dismissOverlay cuối aa78c. Callback không chứng minh chọn Solo tự đảo selected slot, nên CHƯA sửa app order theo giả định.
- CẢNH BÁO chất lượng chứng cứ: LLVM nhiều dòng gắn “Objc message: ...bringSubviewToFront:” dù x1 đã reload selector khác từ stack. Phải theo register/stack/selector ref, KHÔNG lấy annotation cuối dòng làm đích chắc chắn.
- Đã đọc DFHostGeometry.xm, DFFullscreenTransport.mm, DFDashboardChrome.xm: transport có requestID/sequence/lease6s/timeout3s + restore; geometry adapter phụ thuộc CBBridgeManager/CBWindow/CBBridgedSplitApp và không thể nối thẳng sang independent DFNative12Chrome. Chrome hook DB/CARStatusBarWindow không tự chứng minh Apple AppDock. Giữ cơ chế owner validation + rollback, cần adapter riêng có receiver đúng process.
- Đã lưu script decode_gallery_constants.py và workflow native12-original-gallery-constants.yml (commits ea1e0a9,31999f4); tái dùng decoder Mach-O SHA-checked sẵn có, không chạy binary gốc, không phát hành. Local python -m py_compile PASS chỉ kiểm syntax.
- GitHub connector không trả byte DEB gốc: fetch API báo UTF-8 only; fetch_blob binary UnicodeDecodeError. Do đó workflow audit trên runner dùng git show immutable ref như pipeline có sẵn; không yêu cầu upload lại DEB.

## Lô 3: chứng cứ byte mới và sửa gallery có giới hạn rõ
- CI audit 39731899695 SUCCESS giải nén lại DEB immutable SHA 2fe889... và decode trực tiếp Dashboard SHA 9e02a4...; constants/GALLERY_CONSTANTS.json đã lưu. Lượt v2 thêm palette lưu constants-v2/GALLERY_CONSTANTS.json (blob af40cd4cbbf4f606a42cc10a3cbd819aa2bafb30).
- Giá trị thực: threshold560, rowStride78, cardHeight66, contentHeight194. Selected fill RGB(.04,.20,.45)/alpha.95; unselected(.14,.15,.19)/alpha.95; selected border(.12,.58,1)/alpha1; unselected white/alpha.18; badge palette white +(.08,.52,1).
- Source sửa DFNative12Chrome.m: vùng scroll gallery, card frame/margins/gap/radius theo original, bỏ UILabel cạnh preview nhưng giữ accessibilityLabel, thêm checkmark chọn và màu selection gốc. Giữ nguyên 9 tag/selector selectStylePreset và app host/slot dispatch.
- DFNative12GalleryGeometry.h tính đúng nhánh 5/6 và frame metrics. Chưa đổi outer sheet width cap470/header height46 vì chưa xác minh original caller geometry. Vì cap470, nhánh6 chưa được sử dụng trên UI hiện tại; không nói toàn bộ gallery parity hoàn tất. Preview vẫn dùng layout engine hiện có, chưa port đầy đủ raster padding/colors từ helper0x9efe0.
- Local command (cwd /workspace/scratch/0b439c8a40e7): python -m unittest discover -s Duoface/sideplay/duoface-native-scene-host/tests -p test_original_gallery_geometry.py -v → 2/2 PASS. Test thực compile/chạy header C với cc cho widths320,450.3333333,470,559.999,560,600,960 đối chiếu constants gốc và 63 card bounds; test thứ hai kiểm wiring selection + accessibility.
- Chuẩn bị host version 0.1.39~originalgallery1 bằng pipeline hiện có; chưa có kết quả build mới tại lúc ghi. Không ghi đè .38/.31; chưa thay package public; Zoom/Dock, orientation/audio, ExitSafeMode vẫn chưa sửa.

## Lô 4: signed host đã build và lưu; media callsites đọc tiếp
- Host source 5d6560003d015f13f6150b732802e24da211bd84; Actions39732379936 job119670131296 toàn bộ SUCCESS (compile/sign/dpkg/direct original audit/upload/persist).
- packages/CI_RESULT.txt: BUILD_AND_SIGNATURE=PASS, SILEO_PUBLISHED=false, HOME_ICON_DEVICE_VERIFIED=false, CARPLAY_SCENE_DEVICE_VERIFIED=false, DUAL_APP_TOUCH_VERIFIED=false.
- Artifact packages/com.duoface.carplay.nativescenehost_0.1.39~originalgallery1_iphoneos-arm64.deb SHA256 d939605bb02488aa05a7858ef0740995292e1a2d95f92e2a96016839689231e9. Không ghi đè cũ.
- Đang nối package_integrated.py/workflow sang host .39 đúng SHA; integrated version0.0.32~native12gallery1, cùng package ID. Chưa publish Sileo trong lượt này.
- Đã decode read-only DuoFaceDashboard.dylib.json.gz và FOCUSED_METHODS.json.gz; Dashboard SHA khớp 9e02a4... . CBBridgedUIAppView.refreshSceneLayout 0xade58: updateLayout@ade74 → updateSceneSettingsFrame@ade84 → setNeedsLayout/ layoutIfNeeded. updateSceneSettingsFrame 0xad5bc: carPlayUsableBounds@ad620 → calculateNativeSizeForSlotRect:@ad638 → setContentReferenceSize:withContentOrientation:andContainerOrientation:@ad6bc... → sceneHandle@ad720 → sceneIfExists@ad900 → updateSettingsWithBlock:@ad980... . Đây là selector callsites, ABI/orientation arguments và blocks chưa giải toàn bộ, không ghép mù.
- setAudioOnlyBackgroundMode:0xac858 gọi setAlpha@ac888/setUserInteractionEnabled@ac8b0,ac8c4/updateLayout@ac8d4: không đồng nghĩa AVAudioSession route. dismiss0xaf01c có setInvalidated/setHosting trước appearance/mode0/removeFromParent/invalidate; cần đối chiếu DFSceneHost ownership ordering và actual crash log trước sửa ExitSafeMode.

## Lô 5 — PHÁT HIỆN THAY THẾ SUY LUẬN PORTRAIT, integrated build hoàn tất
**SUPERSEDED:** báo cáo media cũ coi hardcoded Portrait tự nó là không tương đương Native12 là chưa đủ căn cứ. Fresh original DEB audit Actions39732740224 SUCCESS, 7 IMP/1027 instructions, lưu gallery-media-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json và REPORT.md.
- calculateNativeSizeForSlotRect:@0xacc28 thực hiện roundf(2*w), roundf(2*h), size invalid trả CGSizeZero. Cách scale2x mới tương ứng công thức gốc; double-round so với float-round là chi tiết cần kiểm ở biên, không lý do xoay bừa.
- updateSceneSettingsFrame: receiver deviceAppVC x19, selector2arg x21; ad6a0 mov w2,#1 → ad6a4 objc_msgSend. selector3arg x23; ad6d4 w2=1 + ad6d8 w3=1 → ad6dc objc_msgSend. Sau đó controller chính tại [x20,x24] cũng kiểm selector2arg và gọi tại ad708 với w2=1. **Original cũng dùng Portrait=1. GIỮ PORTRAIT, không tự ép Landscape.**
- Khác biệt đã chứng minh: original dùng HAI if độc lập (setter2arg rồi setter3arg nếu cả hai có), sau đó setter2arg trên controller chính; DFSceneHost hiện if/else-if trên controller con và không có đường controller chính. Phần sceneHandle/scene/updateSettingsWithBlock phía sau cần giải blocks/ABI trước nối, do crash video chưa xác định.
- audio-only gốc YES: alpha0 + interactionNO rồi return. NO: alpha1 + interactionYES + updateLayout + tailcall refreshSceneLayout (ac8ec). Không gán nghĩa AVAudioSession nếu chưa có bằng chứng.
- Outer gallery layoutSubviews@a28e8: width-dependent subtraction10/24, height-dependent8/18, clamp max width/height từ literal addresses311740,311748,311758,311760 rồi roundf centering. Original gọi setupCardContent, không chỉ vẽ9thẻ; cần đọc setupCardContent và literals trước đổi cap470/header46.
- **Integrated 0.0.32~native12gallery1 SUCCESS**, Actions39732625073, job119670904647 tất cả steps success. Archive sideplay/jb-embedded-appbridge/evidence/runs/39732625073/com.duoface.jb.embedded_0.0.32~native12gallery1_iphoneos-arm64.deb, SHA256 ed1b5d0f9a14254fc6bbf7a2cd8e36bed17974ff849fdb1c5b493c547bf84bef. Đã đọc lại SHA256SUMS và PACKAGING_PROVENANCE: đúng host .39 d939605b...,28 payload files, sileo_published=false, device=false. Không phát hành candidate này sang repo khác.
## Trạng thái hiện tại để tiếp nối ngay
- Đã làm: audit byte gốc, chỉnh card gallery (không viết lại app), 40 host tests + signed build, integrated candidate .32, bằng chứng+script+workflows trong repo.
- Còn thiếu: outer sheet/header/preview raster và 6-column visibility (cap470 vẫn có); Dock Zoom owner+geometry+restore; exact scene settings blocks/dual setter/main-controller wiring; audio-only state; HUD/settings/assistant; device interaction/media/crash validation.
- Không được sửa: bản frozen.23–.31, IDs, app host đang chạy,3s logo hold/top-centered pills, giấy phép/binary gốc. Không đánh dấu toàn bộ parity đạt.
- Next cụ thể: decode 4 outer literals (311740/48/58/60) + setupCardContent từ original IMP; hoàn tất gallery outer/thumbnail. Đối chiếu ABI và order của updateSceneSettingsFrame với DFSceneHost.commitSceneGeometry: nhưng giữ Portrait; đọc scene blocks và crash trace trước bổ sung mutations. Zoom cần receiver trong process sở hữu Dock, không ACK nhận bản tin rồi ghi success.
