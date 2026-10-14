# DuoFace fullscreen — đối chiếu mã và nhị phân ngày 2026-10-14

## Kết luận

Ở main `4f4281d64f9ea26d616f4e7516a3fa4be8722a5a`, bridge chưa triển khai đầy đủ đường fullscreen của Airaw. Có lỗi kiến trúc xác định được từ source, độc lập với việc CI xanh. Chưa có log thiết bị để xác định nhánh nào đã chặn đúng lần bấm người dùng báo lỗi; không gọi đây là bản sửa đã chạy được.

Phạm vi: v12, cả hai pane, ẩn/hiện sidebar, khôi phục layout, nút chỉ trong DuoFace. Giữ package ID, dữ liệu ngày, split/swap/picker và Sileo. Không sửa runtime hoặc phát hành trong lần điều tra này.

## Những điểm sai trong bridge hiện tại

| Vị trí trong runtime/DuoFaceFullscreenBridge.xm | Bằng chứng | Hậu quả / mức chắc chắn |
|---|---|---|
| DFApplyFullscreen, dòng 24–40 | Gửi `setDefaultAppChromeHidden:` tới `DFScene ?: DFHostController`. Nhị phân xác định method là INSTANCE method của `ARWCarPlayManager`, không phải API đã được chứng minh của scene. Bridge không cài manager hoặc method này. | Sai đối tượng theo cơ chế Airaw. Guard `respondsToSelector:` có thể trả NO và bỏ qua. Chưa có runtime evidence scene thật có selector này hay không. |
| DFApplyFullscreen, dòng 36–40 | Kết quả `chrome` chỉ được log; `DFHostFull=YES` vẫn đặt khi chrome=NO. | Lỗi quản lý trạng thái xác định trong source: đánh dấu thành công khi lời gọi chrome thất bại. |
| DFApplyFullscreen, dòng 38–39 | Chỉ gán `v.frame=container.bounds`. Không cập nhật scene settings/insets, không có hook ẩn dock hoặc receiver `jp.airaw.carplay.chrome`. | Không đủ để lấy toàn bộ vùng màn hình. Nếu container vẫn là vùng trừ sidebar thì khung mới vẫn bị giới hạn. |
| DFFullscreenEventReceiver / DFRequestFullscreen | `NSNotificationCenter` nội bộ dùng tên `jp.airaw.host.fullscreen`. Cả sender/receiver đều là code DuoFace, cuối cùng gọi lại DFApplyFullscreen. | Tên giống Airaw không mang theo manager, cross-process receiver, scene transition hay dock logic. Local notification tự nó không sai nếu mọi thành phần cùng process; ở đây các thành phần chrome cần thiết chưa được triển khai. |
| DFSceneID / DFSceneChanged / pressed | Chỉ hỏi trực tiếp 3 selector trên controller, lấy chuỗi đầu tiên rồi so `com.duonavi.app`. Nút và tap đều chặn nếu không match. | Chưa xác minh identity thực tế; package ID không tự chứng minh controller trả chuỗi đó. Đây là khả năng gây nút ẩn/tap no-op, không phải root cause runtime đã đo. |
| DFBarButton / DFInstallBar | Có thể cài nút trên 3 controller nhưng chỉ giữ 1 weak pointer toàn cục; DFUpdateButton chỉ cập nhật pointer cuối cùng. | Nếu đồng thời có nhiều nút, những nút trước có thể giữ trạng thái cũ. Rủi ro source có điều kiện; chưa chứng minh số host trên máy. |
| DFInstallBar | Tự chọn khung 44x44, vàng/xanh, chữ FULL, `setImage:` không cấu hình. | Không khớp cách dựng nút Airaw đã giải từ binary. Không được gọi là port UI gốc. |

## Sửa các kết luận sai trong lịch sử

1. `0x800ca0` trong checkpoint 4f4281d là địa chỉ sai. Lệnh tại `0x14d74` đọc `0x80000+0xca0 = 0x80ca0`; selector là **carplayFullscreen**.
2. `0x6f578` là NSString **arrow.up.left.and.arrow.down.right**. Airaw **có dùng SF Symbol này**. Kết luận trước “SF Symbol là bịa nên không thể là Airaw” quá rộng và sai. Điều khác biệt thực là kích thước/cấu hình, màu, background-image, bố cục và wiring.
3. `0x48cc0` = `configurationWithPointSize:weight:`; hằng 10.0 là **point size**, số 3 là đối số **weight**, không phải radius/mode.
4. `0x4e4e0` = **setBackgroundImage:forState:**, không phải `setImage:forState:`.
5. `setDefaultAppChromeHidden:` / `setFullscreenButtonHidden:` / `requestFullscreenToggle` thuộc **instance ARWCarPlayManager**. Các báo cáo cũ gọi là class method không đúng; receiver được lấy qua `+[ARWCarPlayManager sharedInstance]`.
6. Các đăng ký `toggleFullscreen` tại `0x25514` và `0x2b0d4` liên quan các class `ARWNativeSplitWindow` / `ARWSplitWindow`. Không dùng chúng làm bằng chứng đầy đủ cho app-scene gốc. Scene đường `carplayFullscreen` có đăng ký riêng tại `0xc584` / `0xd73c`.

## Đường gọi đã khôi phục từ đúng binary

- Installer `0x14c94`: UIButton (`classref 0x81280`), CGRect từ `full_x`, `full_y`, `full_size` của `ARWUtils.sharedInstance` (`classref 0x811d8`); cấu hình UIImage point size 10, weight 3; `setBackgroundImage:forState:`, tint white, hidden ban đầu; addTarget **controller sở hữu nút**, action **carplayFullscreen**, event 0x40; addSubview vào controller.view; lưu `fullscreenBtn`.
- Action IMPs `0x14668`, `0x147e8`, `0x149d4` gọi `ARWCarPlayManager.sharedInstance` rồi `requestFullscreenToggle`. Registrations `0x13db4–0x13dc8`, `0x1420c–0x14220`, `0x1448c–0x144a0` nối selector với các IMP đó.
- ObjC relative method entry `0x53034` xác nhận `-[ARWCarPlayManager requestFullscreenToggle]` → IMP `0x19c7c` → `NSDistributedNotificationCenter.defaultCenter` → post `jp.airaw.host.fullscreen`.
- Scene observer tại `0xc584` / `0xd73c` nhận đúng event trên bằng selector **carplayFullscreen**. Scene IMP `0xcb40` / `0xdcf8` có nhánh kiểm tra module native-split, isNativeSplit/isFull, scene `updateSettingsWithBlock:` và host menu. Không được bỏ các nhánh này rồi khẳng định tương đương.
- `-[ARWCarPlayManager setDefaultAppChromeHidden:]` tại `0x19d78` gửi **event khác** `jp.airaw.carplay.chrome`, có userInfo **fullscreenButtonHidden** và **nativeChromeHidden**. Đây là phần hoàn toàn thiếu trong bridge hiện tại.
- Dock installer `0x43a30` đăng ký receiver `0x451f0` của `jp.airaw.carplay.chrome`; receiver đọc `userInfo[nativeChromeHidden].boolValue` rồi `setHidden:` trên dock. Nhãn log iOS26 không chứng minh path này là path iOS16; phải chọn receiver phù hợp iOS16 trước khi port.
- Button receiver `0x14e70` cũng nhận event chrome để đổi hidden và `shouldInterceptHomeForFullscreen`; đây không phải nút luôn bật toàn CarPlay.
- Geometry path có `UIScreen._carScreen.bounds` tại `0xcd04–0xcd14`, không phải chỉ parent.bounds. Cần giải hoàn chỉnh settings block và điều kiện nhánh, không tự biến địa chỉ này thành công thức port đã xác minh.

## Nguồn và phép kiểm đã thực hiện

- Đã đọc ZIP skills 01/02/05 trực tiếp từ Gpt-training- bằng base64/zipfile, đọc handoff phần fullscreen, source, workflow, filter và các báo cáo docs/airaw* liên quan.
- Bản gói cũ đã tìm lại: Library `libfile_a3ceb89ed7e0819183918dd2322e3b8c`, `com.duonavi.app_1.0.3-12_airawtest1_iphoneos-arm64.deb`, SHA256 `34e960c06ab92a4834bdc92682123d4f12f1e01375627bf98ae5bd5938adb824`. Chỉ dùng làm nguồn khôi phục, KHÔNG phải bản phát hành.
- Airaw.dylib 1,214,560 bytes, SHA256 `46115c8f0a1d2d81cf4c003be58468d2a9b5c69e595f0f68d5fff5de53be4a9d`, khớp fingerprint ghi từ DEB gốc trong hồ sơ. Đã so trực tiếp bytes của tar member, không dựa tên file.
- `dpkg-deb -x` bị lỗi ownership uid/gid 1001 trong môi trường mới. Khôi phục bytes an toàn bằng `dpkg-deb --fsys-tarfile` + Python tarfile.extractfile; không cần áp ownership.
- Môi trường không có llvm-objdump; script cũ yêu cầu llvm không chạy ở đây. Dùng Capstone **5.0.7** làm backend cho script bổ sung hash-pinned, parse chained import/rebase và ObjC relative methods. Không thay script cũ.
- Lệnh tại repo root: `python3 scripts/airaw_focus_recovery.py audit/Airaw-1.7.1k-reference.dylib > audit/airaw-focus-recovery-20261014.txt`; `python3 -m py_compile scripts/airaw_focus_recovery.py` đều exit 0. Bản nguồn phân tích nén lossless tại `audit/Airaw-1.7.1k-reference.dylib.gz`; phục hồi bằng `gzip -dc audit/Airaw-1.7.1k-reference.dylib.gz > audit/Airaw-1.7.1k-reference.dylib`. Cài dependency trong môi trường phân tích bằng `python3 -m pip install capstone==5.0.7`. Script tự từ chối binary không đúng SHA256.
- Evidence: `audit/airaw-focus-recovery-20261014.txt` (annotated address ranges, không phải full disassembly). Script: `scripts/airaw_focus_recovery.py`. Binary nguồn chỉ dùng phân tích, không thêm vào DEB runtime.
- CI mới nhất kiểm tra: run **38516659443**, job **115696880908**, head `aab0b9b706691dc1becd44dba38cc9f5f70cb77c`, compile/package/upload SUCCESS; artifact **11871992504**, `duoface-fullscreen-host4`, ZIP 2,036,727 bytes, digest `7bf5b2f4c701c6d134b1b48e97b53d1dc00610406e5e52c24e71ef26c4716c7b`. Không có job in_progress/queued tại lúc kiểm tra. Không khởi động build mới.

## Bước tiếp theo cụ thể

1. Dùng binary/reference và script đã lưu; không tìm lại selector nút, manager owner hay quét 83 file nữa.
2. Theo scene IMP `0xcb40` / `0xdcf8`, giải settings block và nhánh tương thích iOS16; theo đăng ký chrome receiver của DBStatusBarWindow/CARStatusBarWindow và dock tương ứng. Không bê nhánh iOS26/native-split vào iOS16.
3. Xác định DuoFace v12 scene thực và identity lookup từ native controller/binary; hiện chưa đủ căn cứ để viết identity gate mới.
4. Khi đủ call graph: thay bridge bằng module đầy đủ state/scene/chrome/restore, cập nhật mọi host button, bảo toàn cả hai pane. Chỉ build sau thay đổi có chứng cứ và kiểm tra rollback. Source changed ≠ build ≠ device PASS.

Hoàn tất ở lượt này: điều tra, khôi phục reference, giải target/action/owner và chrome receiver, sửa hồ sơ sai. Chưa sửa chức năng runtime, chưa có DEB mới, chưa test thiết bị và chưa phát hành Sileo.
