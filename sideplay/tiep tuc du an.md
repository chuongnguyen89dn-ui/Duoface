# SIDEPLAY — HỒ SƠ THEO DÕI VÀ BÀN GIAO (DuoFace)

> **ĐẦU MỐI HOẠT ĐỘNG TỪ 2026-10-18 15:52 ICT.**
> Đây là luồng phát triển **SidePlay → DuoFace độc lập** nằm trong repo `chuongnguyen89dn-ui/Duoface`, KHÔNG phải nhánh QA/MyTweak cũ, KHÔNG phải bản Native12/Visual12 đang được phân phối. Hồ sơ này là nơi ghi checkpoint mới cho hướng SidePlay; giữ các hồ sơ cũ làm lịch sử.


> **CHECKPOINT 2026-10-18 — DEB SIDEPLAY:** Đã tìm lại **báo cáo audit tĩnh từ chính DEB user upload ngày 17/10**; **chưa tìm lại được byte DEB trong chat hiện tại, Library hoặc 5 nhánh GitHub**, nên không thể quét lại 136/136 file hôm nay. Bảng kỹ thuật đầy đủ, chứng cứ, thiếu sót và lệnh tái kiểm tra: **[AUDIT_SIDEPLAY_1.0.4-1_20261018.md](./AUDIT_SIDEPLAY_1.0.4-1_20261018.md)**. SHA-256 lịch sử `7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c`, kích thước 4.352.576 byte. **Không phải kết quả hash mới.** Việc đầu tiên tiếp theo: phục hồi chính byte DEB và chạy forensic inventory trước khi code.

> **CURRENT CHECKPOINT — 2026-10-18 ~16:13 ICT — CONFIRMED BY GITHUB:** Bản gốc `com.sideplay_1.0.4-1_iphoneos-arm64.deb` do user upload ở root repo tại `acae0bd11887d1acd6260a309017825b64391b9d`. Run Actions [39114447674](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39114447674), job `117637251783`, **SUCCESS**, đã tính lại SHA256 đúng `7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c`, không thực thi postinst/prerm. Toàn bộ payload **136 file** và control 3 file được commit vào `sideplay/extracted-1.0.4-1/` tại [`1288472a4bdb120acb7102f4b64b879ff4c7019a`](https://github.com/chuongnguyen89dn-ui/Duoface/commit/1288472a4bdb120acb7102f4b64b879ff4c7019a). Audit: `sideplay/audit/deb-1.0.4-1/` (inventory/hashes, Mach-O, plists, ảnh); index: [`sideplay/README.md`](./README.md), tool: `sideplay/tools/extract_sideplay_deb.py`, workflow: `.github/workflows/sideplay-unpack-original.yml`. **Bản báo cáo cũ ghi không tìm thấy DEB đã bị supersede.** Quan trọng: DEB **KHÔNG chứa mã nguồn ObjC**, chỉ 7 binary Mach-O (3 fat, 4 thin), 119 PNG, 9 plist và 1 license GMapHUD; mọi thay đổi runtime phải viết source độc lập hoặc có nguồn gốc/quyền sử dụng hợp lệ. Chưa sửa logic, compile, build gói mới, test CarPlay hoặc Sileo. NEXT: phân tích từng fat-slice, ABI/ObjC/scene graph, sau đó tạo source-owned core tách bản gốc.

> **MỚI NHẤT 2026-10-18 — ƯU TIÊN GIỮ THANH BAR CARPLAY:** Người dùng yêu cầu **tạm dừng phân tích nhị phân sâu/scene/HUD**, chỉ đưa SidePlay từ trạng thái fullscreen ngay khi kết nối về chế độ CarPlay thường kiểu DuoNavi 1.0.4 (dock/bar hệ thống vẫn còn). Đã xác minh từ bản giải nén: `SidePlayPrefs.bundle/Root.plist` đặt `carDock.default=false`; core có `carDockMode/carDockArea/carWindowFrame`. Code candidate độc lập ở nhánh [`feature/sideplay-normal-carplay-dock`](https://github.com/chuongnguyen89dn-ui/Duoface/tree/feature/sideplay-normal-carplay-dock), hồ sơ chi tiết [NORMAL_104_COMPARISON_AND_FIX.md](https://github.com/chuongnguyen89dn-ui/Duoface/blob/feature/sideplay-normal-carplay-dock/sideplay/normal-carplay/NORMAL_104_COMPARISON_AND_FIX.md). Chỉ đổi default `carDock` sang true ở bản copy, script giữ các prefs khác; run [39115213941](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39115213941) **static PASS**, DEB nguyên bản không đổi. **Chưa device PASS/chưa sửa binary/chưa có DEB phát hành**. Muốn kiểm chứng hiệu quả thực tế cần bật SidePlay > Hiển thị > Thanh dock CarPlay trên máy đang cài và reconnect. Không tự merge hoặc thay bản Native/Visual/Hub/QA/Sileo.


> **TEST RECHECK — 2026-10-18 ~16:26 ICT:** GitHub Actions [run 39115299884](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39115299884), job `117639771876`, commit `29531b274343efe91c9bbab46fc9d2491bd62f8b` **SUCCESS**: 4/4 Python regression tests pass, SHA256 kiểm tra DEB gốc `OK`. Kết quả **chỉ áp dụng cho preset cấu hình**, không chứng minh đã thấy thanh dock thực tế trên xe.

> **ĐÍNH CHÍNH 2026-10-18 — CHƯA XÁC MINH TÙY CHỌN TRÊN MÁY:** User chất vấn hướng dẫn sai rằng SidePlay có thể vào Settings và bật thanh bar. **Chứng cứ duy nhất tại thời điểm này**: trong DEB `SidePlayPrefs.bundle/Root.plist` có hàng `PSSwitchCell`, `key=carDock`, `label=Thanh dock CarPlay`, `default=false`. Chưa kiểm chứng liệu mục đó được PreferenceLoader hiển thị trên thiết bị; chưa chứng minh nó điều khiển thanh bar/sidebar hệ thống hay đưa host về vùng `carPlayUsableBounds` như DuoNavi 1.0.4. Không tiếp tục hướng dẫn người dùng bật mục này như một biện pháp đã xác thực. Nhánh candidate hiện tại `feature/sideplay-normal-carplay-dock` chỉ đổi **default metadata**, **không phải fix runtime**; test 4/4 chỉ xác minh cấu hình. Kế tiếp phải chứng minh cơ chế/window-level/geometry và runtime trước khi gọi nó là sửa fullscreen. Giữ nguyên DEB gốc và không build hay phát hành.

> **USER TEST + ORIGINAL BINARY TRACE — 2026-10-18 ~16:40 ICT — NEW TOP PRIORITY:** Ảnh và xác nhận user chứng minh `SidePlay > Thanh dock CarPlay` **có tồn tại, công tắc đang bật nhưng thanh CarPlay hệ thống vẫn không hiện** khi SidePlay đang hiển thị 2 pane. Thử `carDock=true` **FAIL theo mục tiêu**; bản candidate chỉ đổi `Root.plist.default` **không sửa lỗi** và không merge/build. Hash-verified direct arm64 audit trên nhánh `feature/sideplay-normal-carplay-dock`: original `SidePlay.dylib` SHA256 `0fc34c6c8e47283d2223d70facfe3e86ed76bd568958786b67a9430127242971`. Disassembly `0x14648–0x1467c` thiết lập cửa sổ bằng `_UIWindowLevelAlert + 10.0` và `setWindowLevel:`; `0x17b88–0x17bbc` `SPPrefBool("carDock", false)` kiểm `carDockArea`/`CGRectIsNull`; `0x17e04–0x17e34` lựa chọn `carDockArea` vs `carWindowFrame`. **Khả năng che native Dashboard dock do z-order rất cao**, CHƯA thiết bị xác minh thứ tự z-order, KHÔNG tuyên bố fix. GitHub Actions [39115979117](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39115979117) và [39116112514](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39116112514) SUCCESS, artifacts static tại `sideplay/normal-carplay/audit/geometry-selector-evidence.json` + `geometry-objc-window-trace.txt`. Báo cáo [NORMAL_104_COMPARISON_AND_FIX.md](https://github.com/chuongnguyen89dn-ui/Duoface/blob/feature/sideplay-normal-carplay-dock/sideplay/normal-carplay/NORMAL_104_COMPARISON_AND_FIX.md), report commit `8ba29e424e91cec3f9946ffef547ac74240ad18b`. **Bước kế:** thiết kế chỉnh z-order chỉ cho cửa sổ CarPlay SidePlay (không global UIWindow), lấy usable region DuoNavi 1.0.4, fallback an toàn; static + device test trước khi nói dock trở lại. Chưa build DEB/IPA, chưa thay Native/Visual/Hub/Sileo. Bằng chứng ảnh user nằm trong cuộc chat, chưa chuyển vào GitHub.

## 1. QUYẾT ĐỊNH MỚI NHẤT — USER_DECISION (2026-10-18)

- Hướng CarPlay DuoFace hiện tại được chủ dự án tuyên bố **thất bại vì chưa tách được phụ thuộc giấy phép**. Không tiếp tục vá giấy phép hoặc trộn lõi DuoNavi/QA vào DuoFace để cứu phương án cũ.
- **Chuyển hướng:** xây dựng **nền tương thích chức năng SidePlay từ đầu, độc lập**, rồi đưa **toàn bộ giao diện và tương tác DuoFace** sang nền mới; không làm UI QA thay thế.
- SidePlay là **tài liệu tham chiếu về hành vi, cơ chế kết nối và luồng scene**, không tự động đồng nghĩa có mã nguồn SidePlay được cấp phép sử dụng. Chỉ triển khai mã do dự án tự viết / thành phần được phép dùng; **không bê cơ chế giấy phép, trial, nhị phân độc quyền hoặc cách vô hiệu hóa bảo vệ** vào sản phẩm.
- **Bảo toàn** mọi bản hiện có Native12, Visual12, Hub8 và nhánh QA/MyTweak; không tự ghi đè package/bundle ID, phát hành Sileo hay tự chạy workflow đóng gói. Kiểm thử độc lập rồi mới cân nhắc thay thế theo yêu cầu mới.

## 2. EXECUTION LOCK / CHECKPOINT

| Trường | Trạng thái tại lúc tạo hồ sơ |
|---|---|
| Repository lưu mã và bàn giao | `chuongnguyen89dn-ui/Duoface` |
| Nhánh viết hồ sơ | `main` |
| Base commit main đã đối chiếu | `56321974682442693f9bdca3ba7d386b99e0f457` (2026-10-18 06:01:20 UTC) |
| QA để tham khảo, không chỉnh | `feature/visual12-duodash-recovery` tại `c11ff1181eeda01dfc5e81f5166c99ba0287cfed` (2026-10-18 08:50:24 UTC): ghi dừng đường MyTweak QA trùng lặp |
| Thư mục làm việc SidePlay | `sideplay/` (tạo hồ sơ trước; **chưa có source SidePlay mới** trong lần ghi này) |
| Đầu mối bàn giao SidePlay | `sideplay/tiep tuc du an.md` (file này) |
| Bàn giao DuoFace cũ | `ban giao du an duoface moi.md` (lịch sử độc lập cũ); `tiep tuc du an.md` (lịch sử thế hệ trước); không thay/xóa |
| Nguồn hình ảnh/giao diện tham chiếu | `dist/visual-1.0.3-12/assets/`, `dist/visual-1.0.3-12/CONTENTS.txt`, `dist/visual-1.0.3-12/verification.json`; xác minh chi tiết trước khi sử dụng |
| Loại sản phẩm đích | DEB rootless `iphoneos-arm64` cho iOS 16 / CarPlay; **chưa build gói SidePlay-DuoFace** |
| Thiết bị nghiệm thu dự kiến | iPhone X rootless iOS 16.7.x, iPhone 8 Plus iOS 16, màn CarPlay DiPlay/Mazda CX-5; nghiệm thu thực tế **chưa diễn ra** |
| Phát hành đích | GitHub Actions artifact → Sileo **chỉ sau khi có yêu cầu đóng gói/phát hành** |
| Tình trạng Actions tại lần kiểm tra | Truy vấn `status=in_progress` và `status=queued` cho repo đều có 0 run; chỉ phản ánh thời điểm kiểm tra, không phải giám sát liên tục |
| Việc đã làm | Xác minh repo/nhánh, các hướng cũ, đọc ZIP kỹ năng 01/02/06, tạo hồ sơ theo dõi SidePlay; **không sửa code, không build, không test thiết bị** |
| Phần bị chặn | Chưa kiểm kê/đọc bản SidePlay gốc trong repo và chưa xác nhận giấy phép sử dụng/source của thành phần nào; chưa có baseline SidePlay hoạt động trên máy thật |

## 3. PHẠM VI TRIỂN KHAI VÀ TIÊU CHÍ NGHIỆM THU

**G0 — Chốt baseline.** Xác minh gói SidePlay được tham chiếu trong trao đổi trước đây (`com.sideplay_1.0.4-1_iphoneos-arm64.deb`, chỉ là tên được nhắc tới, **không khẳng định đang có trong repo hoặc đã giải nén**). Đối chiếu control, payload, lớp nạp, app/tweak, entitlements, lifecycle, API và điều kiện độc lập; lưu inventory + checksum chính xác nếu có file. Không nhầm `dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb` với SidePlay.

**G1 — Nền CarPlay độc lập.** Thiết kế/thực hiện từ đầu bootstrap, danh sách app, tạo/quản lý scene/window, host app iPhone không hỗ trợ CarPlay, lifecycle/teardown an toàn trên iOS 16 rootless. Không gọi `CB*`/watchdog giấy phép của DuoNavi; không chép nhị phân/proprietary code của SidePlay. Phải test mở–đóng–mở lại và SpringBoard restart trên thiết bị thật.

**G2 — Mang giao diện DuoFace sang ĐẦY ĐỦ.** Đối chiếu inventory file/assets, kích thước/màu sắc, lớp UI, các khung chia, biểu tượng, logo, nút và logic của bản Native12/Visual12/HUD8 trước khi cấy ghép. Bảo toàn trải nghiệm DuoFace, không mang khung UI hoặc thanh che khởi động từ QA. Ghi mapping từng thành phần, file nguồn, file đích và bằng chứng kiểm thử.

**G3 — Tương tác giao diện.** Split ratio kéo được; nhấn giữ đường chia để hoán đổi; menu App/Zoom/Style/Close với đúng hành vi đã chốt; fullscreen chỉ ở Zoom; viền đỏ lúc chạm và tự ẩn, không giữ viền trong fullscreen. HUD tốc độ đã có trong bản tham chiếu cần kiểm kê để ghép sau khi host và UI nền ổn định; không ưu tiên phát triển tính năng HUD mới trước khi chuyển UI xong.

**G4 — Ổn định.** Không mất kết nối CarPlay, không treo/exitmode khi đóng scene hoặc respring; app launcher hoạt động thật trên iPhone X và 8 Plus. Dùng log SpringBoard/scene và test thiết bị, không ghi PASS chỉ vì compile hoặc tạo DEB.

**G5 — Phân phối độc lập.** Package/bundle ID và đường dẫn riêng không phụ thuộc DuoNavi/SidePlay; không xung đột các bản Native/Hub/Sileo cũ. Xuất DEB, checksum, build artifact, bản thử Sileo **theo yêu cầu phát hành cụ thể** sau G1–G4.

## 4. QUY TẮC KHÔNG ĐƯỢC THAY ĐỔI ÂM THẦM

- Không tiếp tục ghép nhân lõi QA/MyTweak hoặc DuoNavi rồi gọi đó là SidePlay mới.
- Không sửa/xóa/ghi đè bản Native12/Hub8/Visual12 đã có hoặc tự chuyển nhánh đang được người khác sử dụng.
- Không bỏ bớt các thành phần giao diện để lấy bản build có vẻ chạy được; chuyển nguyên vẹn có kiểm kê.
- Không suy luận DEB tham chiếu chứa mã nguồn, không khẳng định SidePlay không có giấy phép nếu chưa xác minh.
- Không sửa cơ chế giấy phép của bên thứ ba; dự án mới phải độc lập về mã nguồn, package, identifiers và hạ tầng phân phối.

## 5. BƯỚC TIẾP THEO CÓ THỂ THỰC HIỆN NGAY

1. Kiểm tra README này và checkout trạng thái mới nhất của `main`, QA branch; rà lại jobs chạy tránh chạy trùng.
2. Xác định file tham chiếu SidePlay thật trong GitHub/đầu vào đã có, có checksum và khả năng đọc; nếu chỉ có DEB, đánh dấu `binary reference, no source`.
3. Tạo `sideplay/INVENTORY.md` ghi so sánh từng tầng SidePlay với G1–G5 và DuoFace Native12/Visual12; *chưa viết appbridge bằng suy đoán*.
4. Chỉ sau khi inventory & quyền sử dụng rõ ràng: tạo branch/source SidePlay độc lập và compile-only test, lưu commit và logs, không build DEB ngoài phạm vi cho phép.
5. Tiếp tục bổ sung **file này** mỗi khi có thay đổi yêu cầu, code, kết quả test, lỗi, checkpoint; sau khi ghi phải đọc lại chính file trên GitHub.

## 6. EVENT LOG — CẬP NHẬT THEO SỰ KIỆN

- **2026-10-18 ~16:13 ICT — CONFIRMED:** DEB gốc đã được user upload và xác minh trong repo; `3854de4511e9373ccc3808646511061bb30528fc` tạo workflow tự động tĩnh; `1213672a1e5b324e8ea34ac3c2811f72a67a5efe` thêm script giải nén có SHA-256 guard; run `39114447674` job `117637251783` SUCCESS, checksum khớp; bot commit `1288472a4bdb120acb7102f4b64b879ff4c7019a` lưu nguyên 136 file và 3 control file cùng audit. Upload artifact `12131847528` là bản sao phụ, Git main chứa dữ liệu bền vững. Lưu index giải nén tại `sideplay/README.md` (commit `edfd303c02f61049927dfa2449adcee8e5efb587`). Không chạy binary/maintainer scripts; không build/deploy. **Handoff 18/10 trước đó về việc không tìm được DEB đã bị thay thế, giữ lại làm lịch sử.** Next: audit fat slices, ObjC/scene lifecycle và mapping giao diện, sau đó phát triển mã riêng, không chỉnh sửa binary tham chiếu.

- **2026-10-18 — CONFIRMED / BLOCKED:** Đã kiểm tra runtime `/mnt/data`, Library (tìm binary; đọc lại báo cáo `phan_tich_SidePlay_1.0.4-1_cho_DuoFace.md`), đủ 5 nhánh GitHub và releases; không có DEB SidePlay có thể đọc byte từ phiên này. Khôi phục được static audit SidePlay 17/10 (đã ghi 136 files; 7 binary trọng tâm, filters, hooks, scene strings, package scripts). Lưu báo cáo phân loại `HISTORICAL_STATIC/CURRENT_VERIFIED/NEEDS_BINARY` tại `sideplay/AUDIT_SIDEPLAY_1.0.4-1_20261018.md`; chưa chạy `dpkg-deb`/hash mới, chưa sửa code hoặc build. Next: tìm lại DEB gốc, đối chiếu SHA256, quét toàn bộ payload, bảo toàn bằng chứng.

- **2026-10-18 15:52 ICT — USER_DECISION:** Dừng hướng CarPlay DuoFace hiện tại do phụ thuộc giấy phép không thể giải quyết; mở hướng SidePlay từ đầu + chuyển nguyên vẹn giao diện DuoFace. Không coi MyTweak QA là nền được chọn.
- **2026-10-18 15:52 ICT — CONFIRMED:** Đã truy cập `Gpt-training-` và đọc thực tế `skills/01-github-continuity.zip`, `skills/02-ios-deb-ipa-carplay.zip`, `skills/06-artifact-zip-handoff.zip` (các `SKILL.md` bên trong); kiểm tra repo DuoFace `main`, nhánh QA, workflows và cấu trúc assets. Không có đường dẫn `sideplay/` trong cây `main` trước khi tạo.
- **2026-10-18 15:52 ICT — NOT_YET:** Chưa sửa mã nguồn, chưa tạo baseline chạy CarPlay/DEB SidePlay, chưa kiểm thử thực tế hoặc xuất bản.
