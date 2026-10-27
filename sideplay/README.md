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
