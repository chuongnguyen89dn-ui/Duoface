# DuoFace QA .48 — kiểm tra bản build thực tế so với hành vi trên CarPlay

Thời điểm kiểm tra: 2026-10-23 ~17:07 ICT. Repo `chuongnguyen89dn-ui/Duoface`, nhánh `feature/duoface-jb-embedded-appbridge-20261020`, nguồn QA pin `f5d4e61d8b5791b53e2e5c159b938f409933413f`, checkpoint ngay trước kiểm tra `e6ec87b943f5a755aebcb99cac185ae9adb70044`.

## Xác minh được — KHÔNG suy diễn thành tính năng đã chạy

1. **Đúng nhánh/đúng gói được build:** so sánh GitHub `e6ec87b...feature/duoface-jb-embedded-appbridge-20261020` = identical (0 commits lệch). `sideplay/duoface-native-scene-host/control` tại source pin khai báo NativeHost `0.1.57~sharedwindow1`; staging `com.duoface.jb.embedded 0.0.48~sharedwindow1`. GitHub Actions source signed/package run [39935089723](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39935089723), job 120352568249 **success**, log có `DUOFACE_JB_EMBEDDED_CANDIDATE_BUILT` kèm SHA-256 `0af21a8409d320f4e83e8ab219b51460539ba20e9e488d9c4778b90cae65590c`; `BUILD_SOURCE.txt` cho run và source pin khớp. DEB lưu tại `sideplay/jb-embedded-appbridge/evidence/runs/39935089723/com.duoface.jb.embedded_0.0.48~sharedwindow1_iphoneos-arm64.deb`.
2. **Đúng phiên bản xuất bản từ artifact bất biến:** `carplaydsp/.github/workflows/build.yml` Step18 lấy DEB cố định từ repo DuoFace commit `0700b386f1e666e104b6f9b0c0036c32ff501bd9`, không tự build lại bản cũ rồi gắn tên .48. Publisher [39935527143](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/39935527143) có build 120354002678, deploy 120355210147, verify 120355297889 đều **success**; log verify thật `DUOFACE_ONE_PACKAGE_PUBLIC_SILEO_INDEX_VERIFIED`, `DUOFACE_PUBLIC_SILEO_DEB_DOWNLOAD_AND_CHECKSUM_VERIFIED`. Nguồn Sileo `https://chuongnguyen89dn-ui.github.io/carplaydsp/`. Đây là xác minh bản **được đăng lên kho**, KHÔNG chứng minh iPhone đã cài đúng bản.
3. **Đã thay đổi code có thật nhưng chỉ một lớp:** `DFNative12Chrome.m` commit `eb2a47906df64befcda7cc366f4d468ef1d67fa2` dùng **một** `sharedAppWindow` chứa 4 `appSceneContainers` (các vùng hiển thị con), cập nhật `UIView.frame` thay vì 4 external `UIRootSceneWindow`. Đối chiếu báo cáo mã máy Native12 `sideplay/audit/native12-wiring-20261019/WIRING_REPORT.md` có `CBWindow` và `CBBridgedSplitApp.layoutSplitViews`. Đó là *đổi cấu trúc vùng chứa*, không có chứng cứ đổi được kích thước/định hướng nội bộ YouTube trên máy.

## Tại sao người dùng vẫn có thể thấy y hệt — điểm lệch mã hiện hữu

- `sideplay/duoface-native-scene-host/DFSceneHost.m`: khi `self.ready`, nhánh `live-scene-private-reference-update-suppressed` **return sớm** và không đổi remote scene content-reference-size; lúc chưa ready còn hạt giống `UIInterfaceOrientationPortrait`. Bản .48 thay bố cục UIView ngoài, nhưng **không đảm bảo** viewport bên trong ứng dụng mở rộng thành CarPlay landscape. Đây là nguyên nhân nghi vấn có **cơ sở trực tiếp từ mã**, chưa thể kết luận duy nhất khi thiếu actual app/frame/device logs.
- `DFNative12Chrome.m`: logo có `UILongPressGestureRecognizer.minimumPressDuration=3`, cùng `UIPanGestureRecognizer` với `requireGestureRecognizerToFail:hold`. Mã có handler dịch logo và ratio, nhưng chỉ kiểm tra source CI; trước đó báo cáo thiết bị có touch-down mà **0 long-press recognized**. Không đủ căn cứ tuyên bố giữ 3 giây/kéo ratio đã chạy.
- `DFNative12Chrome.m` menu global Zoom chỉ `emit:@"Zoom"`; `DFDockZoomCoordinator.m` từ chối Zoom nếu thiếu heartbeat thật, ACK xác thực owner Dock và xác nhận nguồn host geometry. Không có log ACK thật của .48 => không được ghi tính năng Zoom đã hoàn thành.
- Lỗi YouTube/SpringBoard `Exit Safe Mode` có báo cáo thực từ .47; suppression các private setter ở .48 chỉ là biện pháp giảm rủi ro. Chưa có IPS .48 và chưa có test phát video CarPlay trên máy nên **không có kết quả hết crash**.
- Người dùng vừa phản ánh **không thấy chức năng nào thay đổi**. Đây là **phản hồi nghiệm thu thất bại**, nhưng chưa xác minh được máy đang cài `0.0.48~sharedwindow1` (không có ảnh Sileo Installed hoặc `dpkg-query`).

## Trạng thái trung thực

- Code khác .47: **Có** (một shared UIWindow). Signed DEB đúng commit: **Có**. Kho Sileo public trỏ đúng DEB/hash: **Có**.
- iPhone cài đúng gói .48: **Chưa xác minh**. Mở YouTube không crash: **Chưa chứng minh**. YouTube trình phát đầy khung: **Chưa chứng minh**. Kéo tỷ lệ: **Chưa chứng minh**. Giữ 3 giây dịch logo: **Chưa chứng minh**. Zoom ẩn Dock: **Chưa chứng minh**. Giống Native12 về hành vi: **Không đạt nghiệm thu / chưa thể khẳng định**.
- Đừng phát hành tiếp .49 chỉ bằng static assert hoặc đổi bề ngoài; dừng lặp release khi thiếu chẩn đoán từ bản cài. Bảo toàn .37, .47, .48, Native12 gốc; không mang code hoặc licensing bên thứ ba.

## Bước tiếp theo cụ thể (không chạy job trùng)

1. Đối chiếu bản **Installed** `com.duoface.jb.embedded` trên iPhone: phiên bản `0.0.48~sharedwindow1` hay cũ; ghi một screenshot hoặc read-only `dpkg-query -W -f='\u0024{Package} \u0024{Version}\n' com.duoface.jb.embedded`. Không suy diễn từ trang Sileo available/latest.
2. Nếu đã .48: chạy an toàn khi xe dừng, lấy `/var/mobile/Library/Logs/DuoFaceDockOwner.log`, nhật ký DuoFace scene audit (tra path thực trước khi yêu cầu), file `Crash-*-SpringBoard-*.ips` sau lỗi, và so readback `media-pane-frame-readback` trước/sau khi mở YouTube. Đối chiếu host UIView.frame, nguồn UIWindow.screen và inner SBAppViewController reference/bounds. Xác minh riêng ratio, logo-hold, Dock ACK.
3. Dựa vào chứng cứ frame/scene, sửa **đúng lớp remote app scene geometry/ownership**, không chỉ shared UIWindow bên ngoài; kiểm thử host ownership/parenting; kiểm tra gesture recognizer thực nhận event; đối chiếu Dock owner hiện hữu. Chỉ tạo signed QA mới khi có lỗi xác định và test thất bại/đậu rõ ràng.
4. Check GitHub Actions đã chạy, source code và branch head **trước** khi sửa; không tự kích hoạt package workflow khác. Thành công phải gồm actual installed SHA/version, ảnh/đo frame đúng, YouTube video chạy không Exit Safe Mode, 3s grip + ratio riêng biệt, Zoom In/Out Dock và rollback đúng trên thiết bị.

Kỹ năng đã đọc trực tiếp: `Gpt-training-/skills/02-ios-deb-ipa-carplay.zip`, ZIP blob SHA `14978becab3e5bcab39b160fda1dae848dc28101`, đọc đủ 6 entry bao gồm SKILL.md và reference. Không tạo mã nguồn ở repo kỹ năng.
