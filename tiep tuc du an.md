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
