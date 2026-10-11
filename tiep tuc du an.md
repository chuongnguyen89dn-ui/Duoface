# DUOFACE — TIẾP TỤC DỰ ÁN (HỒ SƠ BÀN GIAO CHÍNH)

Cập nhật: 2026-10-11. Repository: chuongnguyen89dn-ui/Duoface. Trạng thái: CHƯA CÓ BẢN DUOFACE ĐƯỢC XÁC NHẬN CÀI/CHẠY THÀNH CÔNG.

## 1. Yêu cầu bất biến của chủ dự án

- Dùng gói DuoNavi 1.0.3 gốc làm chuẩn để chuyển thương hiệu sang **DuoFace**; giữ nguyên **100% chức năng** đã có, đặc biệt giao diện CarPlay và split-screen. Không tự ý xóa file/thư viện/script/chức năng.
- Nhận diện DuoFace: biểu tượng hai gương mặt nữ sân khấu ghép liền, một trắng một đen, môi/điểm nhấn đỏ, nền đen; chữ **DuoFace** và khẩu hiệu **TWO FACES ONE SCREEN** (không dấu chấm). Có icon ứng dụng và logo ngang/dọc.
- DuoFace phải có package ID và bundle ID riêng; cài độc lập, không tự động xóa/thay thế/ghi đè DuoNavi. Không suy luận việc cài hai app nghĩa là mở cả hai cùng lúc. Phải kiểm tra khả năng các tweak được nạp đồng thời riêng biệt.
- Không yêu cầu người dùng gõ lệnh dài trên iPhone nếu có cách kiểm tra trực tiếp file/log. Không yêu cầu gửi lại file đã có trong môi trường làm việc.
- Tự cập nhật đầu mối `tiep tuc du an.md` trong repo mỗi lần có thay đổi, kèm lệnh, kết quả, lỗi, phiên bản, quyết định, đường dẫn và bước tiếp theo. Không nói đã hoàn thành khi chưa xác minh.

## 2. Kết quả thực tế trên iPhone (người dùng cung cấp)

- iPhone jailbreak **rootless**, dpkg database ở `/var/jb/Library/dpkg`. Chạy `dpkg -C` với tài khoản mobile báo Permission denied; `/usr/bin/dpkg` không tồn tại ở đường dẫn đó. Dùng `sudo dpkg-query` đã truy vấn được.
- Sau cài thử **DuoFace 1.0.3-4** và **1.0.3-5**, lệnh `sudo dpkg-query -s com.duoface.app` hiển thị **`Status: install ok not-installed`**.
- Không thấy icon DuoFace trên SpringBoard; Sileo không hiển thị gói đã cài. Ảnh Sileo trước đó có bước **Unpacking** / **Hoàn Thành** nhưng không chứng minh gói đã cài hoàn chỉnh.
- Chưa thu được log lỗi cài đặt thực tế của Sileo/apt; chưa thể kết luận nguyên nhân. Không được quy kết chắc chắn do đường dẫn, thiếu thư viện, chữ ký hoặc xung đột với DuoNavi.
- **1.0.3-6 chưa được người dùng xác nhận cài hoặc chạy thành công.** Không khuyên gỡ DuoNavi gốc.

## 3. Danh sách bản dựng và sự cố

| File DEB trong môi trường phiên làm việc | Trạng thái |
|---|---|
| `DuoFace_1.0.3_REBRAND_UNSIGNED_TEST.deb` | Rebrand thử, unsigned, chưa xác minh |
| `DuoFace_1.0.3-2_REPLACES_OLD_UNSIGNED_TEST.deb` | Bản thử có ý định replace: KHÔNG dùng nếu có nguy cơ xóa DuoNavi |
| `DuoFace_1.0.3-3_ISOLATED_UNVERIFIED.deb` | Bản thử độc lập, chưa xác minh |
| `DuoFace_1.0.3-4_FULL_COPY_UNSIGNED_TEST.deb` | Thử cài; dpkg not-installed; payload dạng `var/jb/...` |
| `DuoFace_1.0.3-5_ROOTLESS_SAFE_TEST.deb` | Thử cài; dpkg not-installed; loại bỏ thành phần gốc trái yêu cầu |
| `DuoFace_1.0.3-6_FULL_PAYLOAD_ROOTLESS_UNVERIFIED.deb` | Khôi phục payload, chưa có kết quả cài thực tế |
| `DuoNavi_1.0.3_5years_UNSIGNED_TEST.deb` | Bản chỉnh sửa thử nghiệm, **KHÔNG được gọi là DEB phát hành gốc** |

Các file DEB được liệt kê là file cục bộ của phiên làm việc ChatGPT, **chưa được upload lên GitHub**; link sandbox không phải URL GitHub. Cần xác minh DEB gốc `com.duonavi.app_1.0.3_iphoneos-arm64.deb` với file thực tế trước khi kết luận so sánh 100%.

## 4. Những gì bị xóa/sửa sai ở 1.0.3-5

- Đã bỏ `OldABI.dylib`, `cboptimize`, `cboptimize_helper`, cấu hình `etc/sudoers.d/duonavi` (bản đổi tên `duoface`), cùng các control script `postinst`, `prerm`.
- Chuyển đường dẫn từ `var/jb/Applications/...`, `var/jb/Library/...` sang `Applications/...`, `Library/...`. Đường dẫn rootless phải được kiểm chứng theo bootstrap/package manager thực tế, không mặc định một phương án là đúng.
- Đã sửa byte trong nhị phân Mach-O để thay định danh; nguy cơ làm mất hiệu lực code signature, thay đổi tham chiếu nhị phân hoặc cấu hình nạp dylib. Không thể chứng minh hoạt động chỉ bằng dpkg-deb.
- Chủ dự án **không yêu cầu xóa** các thành phần này. Việc xóa không có căn cứ về phụ thuộc; **không lặp lại**. Bản 1.0.3-4 cũng không cài thành công, do đó thiếu file ở bản 5 không giải thích được toàn bộ sự cố.
- `1.0.3-6` được tạo để khôi phục thành phần gốc, giữ `com.duoface.app`; **chưa xác nhận chức năng và chữ ký**.

## 5. Metadata đã đọc trực tiếp từ các DEB cục bộ ngày 2026-10-11

- 1.0.3-4: Package `com.duoface.app`; Version `1.0.3-4`; Architecture `iphoneos-arm64`; Depends `mobilesubstrate (>= 0.9.5000), firmware (>= 13.0)`; payload có `./var/jb/usr/lib/ellekit/OldABI.dylib` và `./var/jb/usr/libexec/cboptimize_helper`.
- 1.0.3-5: Package `com.duoface.app`; Version `1.0.3-5`; cùng Architecture/Depends; có `./Applications/DuoFaceUI.app`, `./Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib`, `./Library/Application Support/DuoFace/`.
- 1.0.3-6: Package `com.duoface.app`; Version `1.0.3-6`; cùng Architecture/Depends; có `./usr/bin/cboptimize`, `./usr/lib/ellekit/OldABI.dylib`, `./usr/libexec/cboptimize_helper`.
- Metadata trên chỉ chứng minh nội dung gói, **không chứng minh cài đặt hoặc chạy thành công**.

## 6. Công việc phải tiếp tục theo đúng thứ tự

1. Xác định **file DEB phát hành gốc** DuoNavi và SHA-256; không lấy bản thử 5-years làm gốc nếu chưa được xác nhận.
2. Tạo inventory đầy đủ gốc/4/5/6: từng path, size, SHA-256, mode, symlink, control metadata/scripts, entitlements, Mach-O install names, bundle IDs, filter plist; đối chiếu đầy đủ, không chỉ đếm file.
3. Bảo toàn toàn bộ chức năng gốc; chỉ thay tên/icon/package ID/bundle ID/đường dẫn tham chiếu thực sự cần thiết. Với file hệ thống dùng chung, phải xác định cách tránh ghi đè DuoNavi; không tự ý xóa hoặc nhân bản sai.
4. Kiểm tra chữ ký mã thực thi, định dạng DEB, đường dẫn rootless, control scripts, phụ thuộc và tính độc lập. Không tuyên bố hoạt động 100% trước khi có kết quả thực tế.
5. Khi cần log cài đặt, ưu tiên log Sileo bằng ảnh hoặc cách sao chép ngắn, không bắt người dùng nhập đường dẫn dài.
6. Xác minh thứ tự: gói được dpkg ghi `install ok installed` → icon xuất hiện → mở app → CarPlay nhận app → split-screen/điều khiển hoạt động → không ảnh hưởng DuoNavi.
7. Mỗi lần sửa: ghi commit, lệnh, kết quả, diff, bản DEB tương ứng và các giới hạn chưa kiểm chứng vào chính file này.

## 7. Phân định rõ trạng thái

**ĐÃ XÁC NHẬN:** Repo GitHub có thật; tài khoản có quyền admin; trạng thái dpkg not-installed cho bản 4/5; các metadata bản 4/5/6 nêu trên; người dùng yêu cầu giữ đầy đủ thành phần.

**CHƯA XÁC NHẬN:** nguyên nhân cài thất bại; chữ ký và chức năng CarPlay của 1.0.3-6; độc lập runtime hoàn toàn; bản DuoNavi gốc đã được đối chiếu byte-for-byte; upload DEB lên GitHub.

**Không được ghi công việc là hoàn tất** cho tới khi các bước này có bằng chứng. Tài liệu này là hồ sơ bàn giao sống, không phải xác nhận phát hành.


## Checkpoint 2026-10-11 — cài DuoFace và tìm ảnh giao diện DuoNavi
- Người dùng xác nhận DuoFace 1.0.3-9 đã cài thành công bằng Sileo và mở được app trên iPhone; **CarPlay chưa test**, không được ghi là đã hoạt động trên màn hình xe.
- Lịch sử lỗi: 1.0.3-6 rootful `./Applications/DuoFaceUI.app` gặp read-only filesystem; 1.0.3-7 trùng `/var/jb/usr/bin/cboptimize` với `com.duonavi.app 1.0.3`. Workflow phát hành và repack nằm tại `chuongnguyen89dn-ui/carplaydsp`, nhánh main, `.github/workflows/build.yml`, `scripts/repack-duoface-rootless.py`. 1.0.3-9 yêu cầu Sileo restart sau cài. Kết quả thành công chỉ dựa trên phản hồi người dùng.
- Yêu cầu mới nhất: tìm và gửi tất cả **hình ảnh giao diện thật DuoNavi**; phân biệt screenshot thực tế với icon/logo/ảnh tweak khác.
- Đã đọc các file tại /mnt/data: `DuoNaviUI.zip` chứa `DuoNaviUI.app/` với 19 AppIcon PNG, Info.plist và binary; `DuoNaviDashboard.zip` chứa `DuoNaviDashboard.dylib`. Gói gốc tại `/mnt/data/duoface_work/orig/var/jb/Library/Application Support/DuoNavi/` có `duonavi-logo.png`, `duonavi-logo-vert.png`, `duonavi-icon.png`. Bảng ghép icon đã có tại `/mnt/data/duonavi_assets_contact_sheet.png` (chỉ local, không khẳng định đã đưa lên GitHub).
- Tìm web `DuoNavi CarPlay tweak app screenshots interface`: **chưa tìm được screenshot DuoNavi xác thực**; ảnh Airaw/DuoDash/CarPlay thường không được gán nhãn DuoNavi. Không tự chế ảnh và nhận là ảnh thật.
- Tiếp theo: tìm ảnh thực tế trong nguồn chính thức, lịch sử repo hoặc video, và/hoặc chụp app DuoNavi đang chạy trên thiết bị khi có quyền truy cập; nếu không có, thông báo rõ giới hạn. Không sửa code DuoFace khi người dùng chỉ yêu cầu tìm ảnh.


## Checkpoint 2026-10-11 — ảnh tham chiếu giao diện split CarPlay
- Người dùng cung cấp ảnh tham chiếu trong chat (file tải lên `D51EF8A9-82C8-4602-97C1-57CDA0E023DD.jpeg`; file này không mặc nhiên nằm trên GitHub). Ảnh 1536×922 thể hiện Google Maps bên trái, video bên phải, dock CarPlay trái; khung viền xanh bo tròn mỗi cửa sổ; hai thanh nổi dạng viên thuốc trên cùng có nút ba chấm và phóng to; nút tròn xanh hai mũi tên giữa hai cửa sổ.
- Người dùng muốn hình ảnh các thành phần giao diện tương tự được **trích/đối chiếu từ DEB DuoNavi gốc**, không phải icon/logo. Ảnh tham chiếu không tự chứng minh đó là DuoNavi; cần xác minh nguồn. Chưa xác minh những phần tử có được vẽ bởi `DuoNaviDashboard.dylib` hay không. Không nhận diện ảnh này là screenshot gốc khi chưa có bằng chứng.
- Bước tiếp: phân tích assets/binary và nếu có thể trích screenshot thực tế; bảo toàn DuoFace đang cài được, không thay đổi mã khi chưa có yêu cầu.


## Checkpoint 2026-10-11 — xác minh điều khiển UI từ DEB DuoNavi gốc
- Đã mở DEB tại local `/mnt/data/com.duonavi.app_1.0.3_iphoneos-arm64(1).deb` (bản (2) trùng SHA256 `99ff5b886276d868f139bb24b1ee8800c01551c139dca2523a42ada88061fe7f`); `dpkg-deb -f` xác nhận Package `com.duonavi.app`, Version `1.0.3`. `dpkg-deb -c` xác nhận chứa `var/jb/Library/MobileSubstrate/DynamicLibraries/DuoNaviDashboard.dylib` (7,540,464 bytes).
- Đã chạy `strings -a /mnt/data/duoface_work/orig/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoNaviDashboard.dylib | grep -Ei 'cornerRadius|borderWidth|swap|expand|arrow|divider|pill'`. Xác nhận chuỗi/class: `CBSlotPillView`, `CBMultitaskingPillView`, `CBDividerView`, `CBSplitContainerView`, `CBSlotPillHitButton`; selector `handleDividerSwapPressed:`, `handleDividerPan:isVertical:state:`, `expandTapped:`, `setCornerRadius:`, `setBorderWidth:`, `setBorderColor:`; SF Symbols `arrow.left.arrow.right.circle.fill`, `arrow.up.left.and.arrow.down.right`.
- Kết luận **đã kiểm chứng bằng strings**: DEB gốc có code/metadata điều khiển pill, chia màn, swap, expand và bo viền. **Chưa xác minh** màu sắc, tọa độ, kích thước, hiển thị thực tế hay ảnh mẫu do người dùng gửi là screenshot chính DuoNavi. Không có ảnh PNG riêng của các điều khiển này; nhiều khả năng UIKit/SF Symbols dựng lúc chạy.
- Không sửa code/deploy. Bước tiếp: disassembly theo từng class và selector để xác minh hình dạng/behavior; đối chiếu runtime trên CarPlay thực.


## Checkpoint 2026-10-11 — phương án tùy chỉnh giao diện (chưa thực hiện)
- Người dùng hỏi cách thay đổi giao diện các điều khiển DuoNavi trong DuoFace: viền bo góc, thanh pill, nút ba chấm, expand/fullscreen, swap, divider.
- Đề xuất kỹ thuật: ưu tiên lớp tùy chỉnh runtime trong tweak DuoFace thay vì patch byte trực tiếp vào DuoNaviDashboard.dylib; giữ nguyên hành vi chọn app, split ratio kéo, swap và fullscreen. Để cấu hình riêng các thuộc tính UIKit (cornerRadius, borderWidth, borderColor, backgroundColor, frame) và các biểu tượng SF Symbols; cần xác minh điểm hook, tương thích runtime và kiểm tra CarPlay thực tế trước khi tuyên bố khả thi/hoàn tất.
- Đây là **đề xuất**, chưa chỉnh sửa mã, chưa build hay deploy. Không được thay đổi DuoNavi gốc. Trạng thái DuoFace 1.0.3-9: người dùng xác nhận cài và mở app trên iPhone; chưa test CarPlay.


## Checkpoint 2026-10-11 — yêu cầu thiết kế UI V2 và khôi phục checkpoint bị chặn
- Yêu cầu mới: DuoFace UI phải **khác giao diện DuoNavi**; không chỉ sao chép. Đề xuất (CHƯA THỰC HIỆN): viền cửa sổ mảnh 1 pt bo 14 pt; thanh nổi nền đen mờ tự ẩn; nút swap nhỏ trên divider; fullscreen bật/tắt khôi phục split; app picker dạng lưới icon; divider mảnh nhưng vùng kéo đủ rộng. Giữ nguyên split ratio drag, swap, app picker, fullscreen, không ảnh hưởng DuoNavi gốc. Chưa có xác nhận lựa chọn thiết kế cuối cùng hoặc build/test.
- Yêu cầu vận hành: nếu thao tác cập nhật GitHub bị chặn, lượt sau **phải đọc lại file và thử lưu lại phần còn thiếu**, xác minh commit và nội dung; không báo đã lưu khi chưa có commit.
- Khôi phục phần ghi chép bị chặn ở lượt trước: phân tích ARM64 của `DuoNaviDashboard.dylib` gốc đã được báo trong chat: `CBSlotPillView initWithSlotIndex:` tại `0x841c0`, `initWithFrame:` tại `0x84208` với kích thước 76 x 22 pt, cornerRadius 11 pt, nền RGB (16,18,26), alpha 0.88, borderWidth 0.6 pt; các hằng số được mô tả đọc từ arm64 slice có offset 0x4000. **Đây là số liệu báo cáo từ lượt phân tích trước, chưa được kiểm chứng lại trong lượt này**, cần xác minh lại trên DEB gốc trước khi dùng làm cơ sở patch hoặc khẳng định là số liệu đã kiểm chứng độc lập. File chứng cứ local từng được báo `/mnt/data/DuoNavi_UI_binary_audit_2026-10-11.md`, `/mnt/data/DuoNavi_UI_reverse_evidence_2026-10-11.zip`, không xác nhận đã có trên GitHub.
- Trạng thái: DuoFace 1.0.3-9 người dùng xác nhận cài và mở trên iPhone; chưa test CarPlay. Không chỉnh sửa mã, build hoặc deploy trong checkpoint này.


## Checkpoint 2026-10-11 — người dùng xác nhận ảnh chính là UI DuoNavi gốc
- **Xác nhận mới trực tiếp từ người dùng:** ảnh 1536×922 đã gửi trong chat là **giao diện DuoNavi gốc**, không phải ảnh minh họa hay một tweak khác. Thay thế đánh giá trước đó 'chưa rõ ảnh có phải DuoNavi' bằng xác nhận nguồn ảnh từ người dùng; không diễn đạt như đã tự xác minh nguồn ảnh độc lập.
- Ảnh là chuẩn trực quan cho việc thiết kế DuoFace khác biệt: khung viền xanh bo góc của hai app, pill toolbar trên mỗi cửa sổ (ba chấm, expand), nút tròn swap giữa hai app, divider kéo tỷ lệ, CarPlay dock bên trái.
- Cách làm cập nhật: lấy ảnh này làm baseline thị giác, đối chiếu từng thành phần với mã UI gốc; dựng mockup UI V2 để người dùng duyệt **trước khi sửa binary hoặc build**; giữ nguyên logic split, chọn app, swap, fullscreen, kéo divider và không thay DuoNavi gốc.
- Chưa sửa mã, chưa build, chưa deploy. Ảnh người dùng gửi chỉ nằm trong chat trừ khi được đưa vào repo và xác minh thành công.


## Checkpoint 2026-10-11 — dựng ảnh xem trước DuoFace UI V2
- Đã mở ảnh gốc người dùng xác nhận `/mnt/data/D51EF8A9-82C8-4602-97C1-57CDA0E023DD.jpeg` (1536x922) và tạo **mockup ảnh thực tế** `/mnt/data/DuoFace_UI_V2_preview.png` (1536x1062) bằng script `/mnt/data/make_duoface_preview.py` (Pillow). Đây là **ảnh mô phỏng overlay**, không phải screenshot runtime hoặc DEB đã sửa. Ảnh/script mới chỉ ở container tạm, **chưa được upload vào GitHub**.
- Mockup đổi pill cũ thành thanh tiêu đề MAPS/MEDIA có nút menu và fullscreen, thu nhỏ swap giữa divider, thêm tay nắm kéo, viền mảnh; giữ hình bản đồ/video/dock gốc làm nền. Cần người dùng duyệt hoặc yêu cầu điều chỉnh trước khi sửa mã.
- Không chỉnh sửa DuoFace binary, không build, không deploy, không tác động DuoNavi gốc. Bước tiếp: chốt bản vẽ, xác minh hook/runtime, thực hiện từng phần có kiểm thử; phải lưu ảnh/script vào repo khi có cách upload bền vững, không nhầm đường dẫn container là GitHub.


## Checkpoint 2026-10-11 — xác nhận ba nút phải thiết kế lại, tách UI và hành vi
- Người dùng xác nhận **đúng ba mục cần sửa**: nút ba chấm `…` (chọn app), nút phóng to cạnh nó, và nút hoán đổi hai ứng dụng. Lo ngại: nút trong DEB gốc được dựng bằng code chứ không phải ảnh, liệu có thiết kế theo ý muốn được không.
- Giải thích/đề xuất kỹ thuật (CHƯA KIỂM CHỨNG RUNTIME): giao diện UIKit dựng bằng code vẫn có thể thay màu, bo góc, vị trí, SF Symbols hoặc dùng vector/PNG; có thể dựng control mới và nối event tới selector gốc hoặc hook ở lớp controller. Cần xác minh từng selector và nơi gắn view trước khi sửa. Không được suy ra chỉ từ tên hàm rằng có thể hook an toàn.
- Hướng ưu tiên: **giữ hành vi split/app picker/expand/swap gốc**, chỉ thay visual của ba nút; thiết kế hình trước, kiểm thử trên CarPlay sau. Không thay divider logic và không sửa DuoNavi gốc. Chưa có thay đổi code/build/deploy.


## Checkpoint 2026-10-11 — thay icon swap bằng logo hai mặt người DuoFace
- Người dùng hỏi xác nhận: nút swap trong ảnh DuoNavi gốc là biểu tượng hai mũi tên trái/phải, và có thể đổi sang logo hai mặt người của DuoFace không. **Xác nhận**: ảnh người dùng cung cấp thể hiện nút tròn xanh hai mũi tên ở ranh giới hai app; binary có chuỗi SF Symbol `arrow.left.arrow.right.circle.fill` (chưa tự kiểm tra lại binary trong lượt này).
- Yêu cầu thiết kế mới: thay **chỉ biểu tượng hiển thị** của nút swap bằng logo hai mặt người DuoFace; vẫn nhấn để đổi vị trí hai app, không phá chức năng kéo divider, không sửa DuoNavi gốc. PNG trong suốt hoặc vector đều là hướng kỹ thuật khả thi, nhưng cần kiểm tra nơi tạo button/hit area và ảnh logo hiện có trước khi thực thi. **Chưa chỉnh code, build hoặc deploy**.


## Checkpoint 2026-10-11 — xác minh vị trí cấu hình icon swap trong DEB gốc
- Đã đọc trực tiếp `/mnt/data/duonavi_divider_init_arm64.txt` và `/mnt/data/duonavi_ui_objc_metadata.txt` tương ứng `DuoNaviDashboard.dylib` gốc. Trong `CBDividerView` initializer: `0xFE928` CFString `arrow.left.arrow.right`; `0xFE930` CFString `arrow.up.arrow.down`; `0xFE938` `csel` chọn theo orientation; `0xFE940–0xFE944` selector `setIconName:` trên `CBDividerButtonInfo`; `0xFE950–0xFE958` `setRelativePos:` với `0.5`; `0xFE988–0xFE998` `configureWithButtonConfigs:`. Metadata xác nhận `CBDividerButtonInfo.iconName` là NSString.
- Kết luận đã kiểm chứng: tìm thấy **điểm cấu hình SF Symbol của swap button**, không có bằng chứng `setIconName:` nhận đường dẫn PNG. **Chưa tìm được** chính xác UIButton/UIImageView hoặc lớp renderer và chưa thử hook/runtime.
- Phương án dự định (chưa code): giữ cấu hình nút/hit area/callback gốc, hook đúng view renderer sau khi kiểm tra class, thay ảnh bằng logo DuoFace từ tài nguyên riêng; không chỉ patch chuỗi `arrow.left.arrow.right` thành tên file. Mã `UIButton setImage:forState:` chỉ là ví dụ có điều kiện, không phải patch hoạt động đã kiểm chứng.
- Đã kiểm tra local binary tồn tại, không thay mã, build hoặc deploy. Bước tiếp: disassemble `CBDividerView configureWithButtonConfigs:` và lớp tạo image từ `CBDividerButtonInfo.iconName` để xác định điểm hook cụ thể, sau đó làm thử trên bản DuoFace riêng.


## Checkpoint 2026-10-11 — tiến triển mới: renderer nút swap được xác định trong ARM64
- Đã kiểm tra lại file nhị phân thực tế `/mnt/data/duoface_work/orig/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoNaviDashboard.dylib` bằng `llvm-objdump --macho --arch=arm64 --disassemble <binary>` và đối chiếu metadata Objective-C (`/mnt/data/duonavi_ui_objc_metadata.txt`). Trong class `CBDividerView`, method `configureWithButtonConfigs:` có IMP bắt đầu tại `0xfea50`, kết thúc trước `layoutSubviews` tại `0xff410`.
- Các địa chỉ quan trọng trong disassembly method: `0xfec20` class `UIImageSymbolConfiguration`; `0xfec48` selector `configurationWithPointSize:weight:`; `0xfed60` selector `iconName`; `0xfed68` selector `systemImageNamed:withConfiguration:`; `0xfed74` selector `setImage:forState:`; `0xfed94` selector `addTarget:action:forControlEvents:`; `0xfee7c` class `UIButton`; `0xfee04` selector `moveButtonTouchUp:`; `0xfee18` selector `handleMoveButtonLongPress:`. Các selector/class được nạp trong cùng hàm; cần trace thanh ghi tại lệnh objc_msgSend để khẳng định call site chính xác. Chú thích tự động của llvm-objdump ở lệnh `bl` có thể **sai tên selector** vì `x1` được nạp từ stack/register, không dùng làm chứng cứ duy nhất.
- **Kết luận tiến triển:** nút trong divider được tạo bằng UIKit `UIButton`, lấy SF Symbol từ `iconName`, gán qua `setImage:forState:` và có handler touch. Vì vậy cách thay logo PNG có cơ sở mạnh: hook `CBDividerView configureWithButtonConfigs:` sau khi original hoàn thành, nhận đúng UIButton từ `moveButtons` (property trong metadata) rồi thay image. Tuy nhiên **chưa xác minh runtime** đối tượng trong `moveButtons` là UIButton trực tiếp hay wrapper, cần kiểm tra `isKindOfClass:` và kiểm soát button được dựng lại khi xoay/chia dọc; tránh thay mọi nút nếu nhiều config.
- Chưa sửa mã, build, deploy; chưa xác minh logo hai mặt người file nào trong repo. Lệnh disassembly thực tế chạy ở `/mnt/data`, trace cục bộ `/mnt/data/duonavi_swap_renderer_trace.txt` (625 dòng); chưa upload trace lên GitHub. Bước tiếp: đọc `moveButtons` và trace `configureWithButtonConfigs:` chính xác đến objc_msgSend, tạo hook chỉ nhắm nút swap; test trên CarPlay thật.


## Checkpoint 2026-10-11 — RÀNG BUỘC TUYỆT ĐỐI: CHỈ THAY HÌNH ẢNH
- Người dùng xác nhận rõ: **CHỈ thay đổi hình ảnh/giao diện, KHÔNG thay đổi BẤT KỲ chức năng nào** của DuoNavi/DuoFace. Ràng buộc này ưu tiên hơn các đề xuất UI V2 trước đây về thay vị trí nút, cấu trúc control, menu hoặc cơ chế.
- Phạm vi: thay hình/icon nút `…`, fullscreen và swap (hai mũi tên -> logo hai mặt người DuoFace) trên control hiện có. Không đổi target/action, callback, recognizer, vùng chạm, vị trí/logic divider, kéo tỷ lệ, chọn app, swap, fullscreen/restore, xử lý orientation, hoặc bất kỳ hành vi nào. Không thay DuoNavi gốc.
- Triển khai chỉ khi chứng minh được hook thuần hiển thị (UIImage/UIImageView/UIButton image) không ảnh hưởng hành vi; kiểm tra trước/sau và test CarPlay. Nếu không chứng minh được, dừng thay đổi và báo rủi ro, không tự thay logic để đạt mục tiêu.
- Chưa chỉnh mã/build/deploy trong lượt này.


## Checkpoint 2026-10-11 — duyệt logo swap và ý tưởng hai nút còn lại
- Người dùng **đã duyệt mẫu nút hoán đổi** ở ảnh mockup mới: logo hai khuôn mặt trắng/đen viền đỏ, hình tròn, vùng xung quanh trong suốt, chỉ nội dung logo nổi; tự ẩn khi không sử dụng. Logo nguồn do người dùng gửi trong chat (`A50B1544-2793-44A5-95EF-22A921B76B14.jpeg`); ảnh mockup đã tạo trong chat (`a_crisp_high_resolution_ui_mockup_composite_image.png`). Đây là mẫu giao diện được duyệt, **chưa được cài vào DEB**. Thời gian tự ẩn chưa được chốt; không tự ý thay timeout gốc vì yêu cầu tuyệt đối không đổi chức năng.
- Người dùng hỏi phương án thiết kế hai nút còn lại theo màu chủ đạo logo. Đề xuất **chưa duyệt**: nút `•••` trắng bạc trên nền đen kính mờ với nét nhấn đỏ; nút phóng to/thu nhỏ dùng biểu tượng mũi tên chéo trắng bạc, hiệu ứng đỏ khi chạm; giữ hai nút trong pill chung, viền bạc mảnh, bo tròn, nền trong suốt. Không thay target/action, vùng cảm ứng, logic, hoặc hành vi tự ẩn.
- Chưa sửa code, build, deploy. Cần duyệt mẫu hai nút bằng hình trực quan trước khi can thiệp UI.


## Checkpoint 2026-10-11 — người dùng yêu cầu chỉ thiết kế nút chọn ứng dụng
- Người dùng sửa yêu cầu: **chỉ xuất hình riêng của nút `…`**, không tạo mockup CarPlay. Hình tham chiếu người dùng gửi `IMG_7917.jpeg`: hai thanh ngang, mỗi thanh một vòng tròn rỗng; vòng tròn trên lệch phải, dưới lệch trái. Giữ bố cục, làm thanh mảnh, nền ngoài trong suốt, phối màu nhận diện DuoFace. Không tự ý biến bố cục thành hình mặt người/chi tiết khác nếu chưa được duyệt.
- Đã tạo một phương án hình riêng qua công cụ tạo ảnh trong chat, chưa được người dùng duyệt. **Chưa sửa DEB/code/build/deploy**. Yêu cầu bất biến: chỉ thay hình ảnh, không thay bất kỳ chức năng hoặc vùng chạm/callback nào.


## Checkpoint 2026-10-11 — chốt nút chọn ứng dụng; đề xuất nút phóng to
- **Người dùng đã duyệt chính thức** mẫu nút chọn ứng dụng trong ảnh upload `F721EFDC-E56A-4C31-B325-F635E8B3FEB7.png`: hai thanh ngang đen viền bạc, nét đỏ mảnh, vòng tròn trên lệch phải và dưới lệch trái, mỗi vòng chứa logo hai khuôn mặt trắng/đen DuoFace; giữ nguyên hình đã duyệt, không tự ý thiết kế lại. File ảnh nằm trong chat và được mount ở `/mnt/data/F721EFDC-E56A-4C31-B325-F635E8B3FEB7.png`, **chưa xác nhận đã lưu file ảnh vào GitHub**.
- Người dùng hỏi ý tưởng nút phóng to. **Đề xuất, chưa duyệt:** nút tròn trong suốt, hai mũi tên chéo hướng ra ngoài với nét đỏ ánh kim, đầu bạc và thân đen; trạng thái thu nhỏ là hai mũi tên hướng vào trong. Tránh đặt logo hai mặt nguyên vẹn vào nút nhỏ gây khó nhận biết. Chỉ đổi hình ảnh, tuyệt đối không đổi logic fullscreen, callback, hit area hoặc các chức năng khác.
- Chưa sửa mã, build hay deploy. Tiếp theo: tạo hình riêng nút phóng to để người dùng duyệt, không kèm giao diện CarPlay.


## Checkpoint 2026-10-11 — mẫu phóng to 4 góc theo ảnh người dùng
- Người dùng cung cấp `IMG_7918.jpeg` (ảnh biểu tượng fullscreen gồm 4 góc dạng chữ L tách rời) và yêu cầu thiết kế **nút phóng to từ logo DuoFace** theo đúng bố cục này. Đã tạo một ảnh đề xuất riêng qua công cụ tạo ảnh trong chat: bốn góc L đen/bạc với ánh đỏ, chi tiết khuôn mặt trắng ở góc trên phải, khuôn mặt đen ở góc dưới trái; không có giao diện CarPlay. **Chưa được người dùng duyệt** và chưa xác nhận file ảnh đã lưu lên GitHub.
- Yêu cầu bất biến: chỉ thay hình ảnh nút fullscreen trên control hiện có; không thay bất kỳ chức năng, callback, vùng chạm, logic split/fullscreen/restore, không sửa DuoNavi gốc. Nút chọn app hai thanh đã duyệt ở checkpoint trước; nút swap hai mặt đã duyệt.
- Chưa sửa mã, build hoặc deploy.


## Checkpoint 2026-10-11 — CHỐT CHÍNH THỨC CẢ BA MẪU NÚT DUOFACE
- Người dùng **DUYỆT CHÍNH THỨC** mẫu fullscreen bốn góc L trong ảnh tạo trước đó (`a_clean_high_contrast_futuristic_graphic_icon_il.png`, ảnh chat), theo tham chiếu người dùng `IMG_7918.jpeg`: bốn góc tách rời đen/bạc/đỏ, khuôn mặt trắng ở góc trên phải, mặt đen ở góc dưới trái. Không tự ý sửa mẫu.
- Ba mẫu đã duyệt: (1) swap: huy hiệu tròn chứa logo hai khuôn mặt trắng/đen, nền xung quanh trong suốt, tự ẩn theo hành vi gốc; (2) app-picker `…`: hai thanh ngang đen viền bạc ánh đỏ mảnh, mỗi đầu tròn chứa logo hai khuôn mặt, thanh trên đầu tròn bên phải, thanh dưới bên trái, ảnh người dùng chốt `F721EFDC-E56A-4C31-B325-F635E8B3FEB7.png`; (3) fullscreen: bốn góc L theo ảnh được duyệt lượt này.
- **BẤT BIẾN:** CHỈ thay hình ảnh, tuyệt đối không đổi chức năng, callback, target/action, gesture, hit area, thời gian tự ẩn, logic chia màn, kéo divider, swap, fullscreen/restore; không sửa DuoNavi gốc.
- Trạng thái: chỉ duyệt thiết kế; chưa sửa code, chưa build DEB, chưa deploy hoặc test CarPlay. File ảnh tham chiếu/ảnh tạo hiện trong chat và đường dẫn container, **chưa xác nhận có bản ảnh lưu bền vững trong GitHub**. Trước khi thực thi phải lưu assets chuẩn vào repo và xác minh byte/đường dẫn.


## Checkpoint 2026-10-11 — truy vết splash/loading gốc và DuoFace (đã kiểm tra local)
- Người dùng gửi ảnh chụp iPhone `IMG_B44E8E8F-BE04-4E30-B6C6-812FD5A9A476.jpeg`: màn hình khởi động vẫn có logo DuoNavi, slogan `TWO SCREENS. ZERO LIMITS.`, `WORKS WITH APPLE CARPLAY`, thanh loading có màu gốc; yêu cầu tìm đúng vị trí trong DEB gốc. **Chưa được phép sửa chức năng**; chỉ thay giao diện khi triển khai.
- Đã kiểm tra DEB gốc local `/mnt/data/com.duonavi.app_1.0.3_iphoneos-arm64(1).deb` và payload giải nén `/mnt/data/duoface_work/orig/var/jb/`. Logo gốc ở `var/jb/Library/Application Support/DuoNavi/duonavi-logo.png` (960x240 RGBA), `duonavi-logo-vert.png` (640x640 RGBA), `duonavi-icon.png` (256x256 RGBA). Không thấy file ảnh splash hoàn chỉnh: splash được dựng bằng mã.
- `strings -a` trên `var/jb/Applications/DuoNaviUI.app/DuoNaviUI` xác nhận class `CBSplitSplashScreenView`, selector `startLoadingAnimation`, ivars `_progressView`, `_progressGradient`, literal `TWO SCREENS. ZERO LIMITS.`, `WORKS WITH APPLE CARPLAY`, đường dẫn `/var/jb/Library/Application Support/DuoNavi/duonavi-logo.png` và fallback CarBridge. Cùng các chuỗi trong dylib Dashboard. **Chưa disassemble chính xác hàm đặt màu gradient**, không được khẳng định màu đỏ do asset nào khi chưa trace.
- Đã đối chiếu bản DuoFace local `/mnt/data/duoface_work/fixed/Applications/DuoFaceUI.app/DuoFaceUI` và `/mnt/data/duoface_work/fixed/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib`: cả hai **vẫn chứa hai chuỗi slogan** (mỗi chuỗi xuất hiện 2 lần trong mỗi binary), class splash và animation; logo mới riêng tại `/mnt/data/duoface_work/fixed/Library/Application Support/DuoFace/duoface-logo.png`. Điều này giải thích vì sao chỉ đổi logo không xóa được chữ/thanh loading.
- Đã chạy: `strings -a <binary> | grep -Ei 'splash|progressGradient|progressView|duonavi-logo|two screens|works with|startLoadingAnimation'`; Python `Path.read_bytes().count()` trên hai binary DuoFace. **Chưa chỉnh mã, build, deploy.** Bước tiếp: disassemble `CBSplitSplashScreenView` (hai binary), tìm selector gán label, gradient/colors, đường dẫn logo đang được dùng và chọn phương án thay *chỉ visual*; so sánh với DEB 1.0.3-9 thực tế trước khi patch, tránh giả định local `fixed` trùng bản đang cài.


## Checkpoint 2026-10-11 — phương án thay hình thức thanh loading splash
- Người dùng hỏi thanh loading có thể đổi mẫu và cách đổi. Đã đề xuất ba mẫu **chưa duyệt**: (1) thanh ngang đen viền bạc, vệt đỏ ánh kim; (2) hai luồng trắng/đỏ hội tụ; (3) ba vạch sáng tối giản. Khuyến nghị mẫu (1) vì có thể giữ nguyên view/animation gốc, chỉ đổi phần hiển thị.
- Kỹ thuật: splash class `CBSplitSplashScreenView` có `_progressView`, `_progressGradient`, `startLoadingAnimation`. Phải trace đúng đoạn khởi tạo gradient/màu và runtime view trước khi patch; chưa xác minh chính xác điểm hook. Thay hình ảnh/gradient/bo góc không được đổi thời gian, trạng thái, tiến trình khởi tạo, callback, CarPlay hoặc logic khác. Phương án thay cả kiểu loading bằng overlay có rủi ro cao hơn, chỉ làm sau khi kiểm chứng.
- Chưa có mẫu loading được người dùng duyệt; chưa chỉnh code, build, deploy. Ba mẫu nút DuoFace đã duyệt vẫn giữ nguyên.


## Checkpoint 2026-10-11 — giải thích cơ chế chuyển động loading, chưa xác minh kiểu animation
- Người dùng hỏi thanh loading hoạt động/chuyển động bằng cơ chế nào. Đã giải thích từ chứng cứ hiện có: `CBSplitSplashScreenView` có `_progressView`, `_progressGradient`, selector `startLoadingAnimation`; giao diện được tạo/điều khiển bằng code, không phải GIF/video đã chứng minh. Hai khả năng kỹ thuật: thay đổi width/progress hoặc dịch chuyển gradient/vệt sáng; **chưa thể xác định chính xác kiểu animation từ screenshot tĩnh và tên selector**.
- Để kết luận cần disassemble `startLoadingAnimation` và xác định `CABasicAnimation`/`CAKeyframeAnimation` hoặc UIView animation, keyPath (`locations`, `position`, `bounds`, `transform`...), duration, repeatCount, timingFunction và stop trigger trong binary gốc; không tự tuyên bố có progress thực hoặc % hoàn tất nếu chưa có chứng cứ.
- Không sửa mã, build hoặc deploy. Giữ yêu cầu tuyệt đối chỉ thay visual, không thay hoạt động/timing của loading.


## Checkpoint 2026-10-11 — yêu cầu mới: splash bỏ chữ, thay nền, áp 3 icon đúng kích thước gốc
- **Yêu cầu người dùng:** trên màn hình khởi động DuoFace bỏ các dòng chữ DuoNavi (`TWO SCREENS. ZERO LIMITS.`, `WORKS WITH APPLE CARPLAY`); thay ảnh nền mới phù hợp logo; thay cả ba nút bằng ba mẫu đã chốt; **bắt buộc giữ kích thước hiển thị/vùng chạm gốc** và không thay bất kỳ chức năng nào. Đây là yêu cầu thực thi, **chưa được thực hiện trên DEB**.
- Đã tạo **concept nền splash** theo màu đen–đỏ–bạc (ảnh trong chat `a_dark_high_contrast_digital_ui_graphic_compositi.png`), **CHƯA được người dùng duyệt**; ảnh concept có cả icon minh họa nên KHÔNG được dùng nguyên làm background production. Không tự ý thay nền trước khi duyệt mẫu.
- Đã đóng gói **bản sao assets tham chiếu** local `/mnt/data/DuoFace_visual_assets_2026-10-11.zip` (chưa upload GitHub): `app_picker_APPROVED.png` 1536x1024 RGBA từ ảnh user chốt; `fullscreen_APPROVED.png` 1254x1254 RGBA từ ảnh tạo đã chốt; `swap_APPROVED_REFERENCE_MOCKUP.png` 1619x971 RGBA chỉ là mockup có cả UI, cần tách đúng logo, không được dùng trực tiếp làm icon; `splash_BACKGROUND_CONCEPT_NOT_APPROVED.png` 1536x1024 RGB. README kèm lưu ý.
- **Không được nhầm kích thước file PNG nguồn với kích thước nút UIKit thực tế**. Phải disassemble/layout inspect `CBDividerView`, `CBSlotPillView`, `CBSplitSplashScreenView` và xác minh frame/hit area hiện tại, tạo PNG @2x/@3x phù hợp, alpha trong suốt. Không sửa logic auto-hide, callback, animation/timing.
- Trạng thái: chỉ chuẩn bị concept và gói asset local, **chưa sửa binary, build, deploy, test**. Local zip không tính là lưu bền vững; thông tin bàn giao được ghi vào GitHub tại checkpoint này. Bước tiếp: xác định chính xác nơi gán splash labels/background và nút UIKit; chuẩn bị patch visuals-only riêng, đối chiếu bản DuoFace 1.0.3-9 đang cài trước khi build; tránh sửa DuoNavi gốc.
