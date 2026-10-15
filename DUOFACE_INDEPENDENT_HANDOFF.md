# DuoFace độc lập — hồ sơ bàn giao chính thức

> **ĐẦU MỐI HOẠT ĐỘNG MỚI, từ 2026-10-15 (ICT).** File này là nơi lưu trạng thái và nhật ký của hướng **DuoFace độc lập**, không cần DuoNavi. Đọc file này **trước** khi sửa/chạy/build. Cập nhật chính file này sau các mốc làm việc có ý nghĩa; đừng ghi tiến độ của hướng mới vào hồ sơ cũ.
> **Lưu ý:** `tiep tuc du an.md` ở root repository là **kho lịch sử DuoFace trên nền DuoNavi** để tra cứu kỹ thuật; giữ nguyên, không xóa hay đánh đồng với đầu mối mới. Không tạo thêm hồ sơ tương tự.

## 1. Nhận diện dự án và quyết định mới nhất

- **Repository duy nhất:** `chuongnguyen89dn-ui/Duoface` (`https://github.com/chuongnguyen89dn-ui/Duoface`). Không nhầm với repo `Gpt-training-` (chỉ cung cấp kỹ năng), `carplaydsp`/`Duoface` khác hoặc repo của DuoNavi.
- **Nhánh nguồn để đối chiếu khi khởi tạo:** `main`, HEAD **`c57d962c832708e46f16eaca86786ddfbfed238c`** (kiểm tra lúc 2026-10-15). Đây là commit hồ sơ của bản *kế thừa*, **không phải commit của một lõi độc lập đã hoàn tất**.
- **Hướng phát triển đã được người dùng phê duyệt ngày 2026-10-15:** DuoFace trở thành một tweak/ứng dụng CarPlay độc lập. Không phụ thuộc ứng dụng, thư viện lõi, tài khoản, UID dùng cho cấp phép, ngày dùng thử, mã kích hoạt hay máy chủ cấp phép của DuoNavi. Không can thiệp hay sửa giấy phép gốc; tự xây các thành phần thay thế hợp lệ.
- **Trải nghiệm đích:** DEB rootless cài lên iPhone jailbreak, kết nối CarPlay, hiển thị/chạy hai ứng dụng, điều chỉnh chia màn hình, đổi ứng dụng, Zoom/fullscreen toàn giao diện, UI DuoFace hiện có; khởi chạy không cần DuoNavi hay dữ liệu kích hoạt của DuoNavi.
- **Chiến lược:** không vứt bỏ công việc DuoFace đã xây; tái sử dụng mã, hình ảnh và ý tưởng do dự án sở hữu; phân tích nhị phân cũ như tài liệu hành vi để thiết kế lại bằng mã nguồn Objective-C/Objective-C++ riêng. Kiểm tra điều kiện sử dụng của mọi dự án tham khảo; không mặc định có quyền sao chép/phân phối nhị phân thương mại.
- **Giấy phép DuoFace tương lai:** bản độc lập đầu tiên không có thời hạn/UID cấp phép. Việc bổ sung giấy phép do DuoFace tự quản lý là lựa chọn **trong tương lai**, chưa được yêu cầu triển khai bây giờ.
- **Cực kỳ quan trọng:** những giới hạn của DuoNavi là chính sách sản phẩm gốc, **không phải yêu cầu kỹ thuật của CarPlay**. Nhưng không suy luận từ đó rằng gỡ một plist hoặc đổi package ID sẽ khiến gói kế thừa trở thành độc lập.

## 2. Phạm vi bảo toàn và điều không được làm

1. **Đóng băng bản DuoFace đang có:** không ghi đè DEB/commit/bản Sileo đã xây trên nền cũ; phát triển bằng nhánh hoặc khu vực thử nghiệm tách biệt khi bắt đầu viết code. Không cài đè trên điện thoại mà chưa có phương án khôi phục.
2. **Giữ thành quả DuoFace:** logo hai khuôn mặt, màu đen/trắng/đỏ đã duyệt; menu App / Zoom / Style / Close; Clear All; icon; ứng dụng gần đây với `logo app — tên app — chấm xanh/đỏ`; Refresh xanh, nút X trong vòng tròn đỏ; viền đỏ báo hoạt động; đổi app, swap, split focus/restore, fullscreen toàn giao diện; xử lý picker native X không chồng nút. Không tự thiết kế ảnh mới.
3. **Không làm lại phần đã hoàn thiện chỉ vì tạo dự án độc lập.** Khi một tính năng phụ thuộc class nhị phân gốc, chỉ thay adapter/phụ thuộc tương ứng và hồi quy chức năng cũ.
4. **Không tìm cách cấp mã DuoNavi, thay hạn hoặc giả dạng entitlement gốc.** Tập trung vào bộ khởi tạo/cửa sổ/scene/điều khiển độc lập; không phân phối mã của bên thứ ba không được phép.
5. **Không tự phát hành Sileo, không tuyên bố chạy trên CarPlay thực tế từ một bản CI xanh.** Mỗi chặng: source → commit → compile → DEB → SHA/audit → cài đặt → test trên máy → (nếu có) phát hành.
6. **Chỉ tạo DEB khi người dùng thực sự yêu cầu build.** Việc chốt kiến trúc hoặc ghi hồ sơ không phải lệnh khởi chạy workflow đóng DEB.

## 3. Bối cảnh đã phát triển từ nền cũ — làm nguồn chuyển giao, không coi là độc lập

| Mốc | Tóm tắt, giới hạn bằng chứng |
| --- | --- |
| 2026-10-11–12 | Rebrand DuoNavi 1.0.3 thành DuoFace v12, đồ họa/logo/biểu tượng, các gói rootless; nhiều lỗi đóng gói/cài đặt ban đầu. Các gói đã xác minh qua Actions/DEB không đồng nghĩa tất cả đã test trên máy. |
| 2026-10-13 | Thử tích hợp một số phần 1.0.4 vào v12; có khác biệt dữ liệu ngày/ID cài đặt và kết quả giữa thiết bị. Đây là lịch sử kỹ thuật, **không phải** chiến lược cấp phép của DuoFace độc lập. |
| 2026-10-13–14 | Phân tích Airaw 1.7.1k và v12, truy đường gọi fullscreen, host SpringBoard, dock/chrome, split focus/restore, và menu picker. Kết quả disassembly có hash, script và docs trong repo. |
| 2026-10-14–15 | Đã viết các module fullscreen transport/host-geometry/chrome/picker, UI 4 mục, logo, viền và danh sách app theo yêu cầu. Có nhiều ứng viên DEB và các run CI; những thành phần sử dụng class `CB*` của lõi cũ vẫn không độc lập. |
| 2026-10-15 | Người dùng chốt hướng **DuoFace độc lập**: tải/cài/dùng như một tweak CarPlay, không cần cơ chế cấp phép hay ứng dụng DuoNavi; dùng phân tích nhị phân để tái hiện hành vi bằng source riêng; bản hiện hành giữ để đối chiếu, không làm hỏng. **Chưa tạo DEB độc lập.** |

### Baseline ổn định để đối chiếu (chưa phải bản DuoFace độc lập)

- Đường dẫn DEB GitHub: `dist/candidates/menu-native1/com.duonavi.app_1.0.3-12_menu-native1_iphoneos-arm64.deb`.
- Tên gói **thực tế**: `com.duonavi.app`, version `1.0.3-12+menu-native1`, rootless `iphoneos-arm64` (2,197,192 bytes); SHA256 `ce971b42230d355421b2b1d99793a1f62ffb75008365ea74a3467d859cc1de3a`.
- Đã build/persist: Actions run `38679315617` SUCCESS, job `116239986449`, artifact `11947453212` (`duoface-menu-native1`), commit chứa DEB `2053fa0b13a75a31c0afb62dee1ce9ac331bc1b8`. Các bằng chứng: `dist/candidates/menu-native1/{BUILD_AUDIT.json,SHA256SUMS.txt,CONTENTS.txt}`.
- Quan sát CI: chỉ `DuoFaceFullscreenBridge.dylib` khác bản nền `menu-opaque1`; Dashboard kế thừa **giữ nguyên** SHA256 `bc1df854ec7a2ddfeec4cb81b080ead34b54df80143d4a8f6254bb8b618003ce`.
- **Trạng thái chính xác:** `PACKAGE_BUILT_NOT_DEVICE_TESTED_NOT_SILEO`. Bản `menu-native1` chưa được người dùng xác nhận test thiết bị hoặc phát hành Sileo. Không tự ghi thành PASS.
- Nội dung gói vẫn chứa `DuoFaceDashboard.dylib`, `DuoFaceUI` kế thừa và `com.duonavi.sync.plist`. Vì thế **không thể gọi là ứng dụng độc lập** và cũng không dùng làm gói phát hành độc lập.

## 4. Tài sản kỹ thuật có thể dùng lại / ranh giới phụ thuộc

| Source đã có trong repo | Kết quả kiểm tra tĩnh / hướng xử lý khi độc lập |
| --- | --- |
| `runtime/fullscreen/DFFullscreenTransport.mm` | Bộ truyền lệnh và trạng thái `com.duoface.fullscreen.*` riêng; cân nhắc tái sử dụng, hiện vẫn include adapter host cũ. |
| `runtime/fullscreen/DFDashboardChrome.xm` | Điều khiển một số cửa sổ dock/status-bar CarPlay; cần kiểm thử trên runtime mục tiêu. |
| `runtime/fullscreen/DFFullscreenCoordinator.mm` | Điều phối fullscreen/ACK và state; dùng lại logic độc lập nơi phù hợp. |
| `runtime/fullscreen/DFHostGeometry.xm` | **Phụ thuộc trực tiếp** `CBWindow`, `CBBridgeManager`, `CBBridgedSplitApp`; phải thay bằng bộ quản lý host/window của DuoFace độc lập. |
| `runtime/fullscreen/DFPickerZoomMenu.xm` | `%hook CBMultitaskingOverlayView`; giữ UX/menu đã duyệt, thay lớp picker phụ thuộc khi có UI riêng. |
| `src/DuoFaceVisualHook.m`, `src/DuoFaceBorderRunner.m` | Móc vào `CBSlotPillView`, `CBBridgedSplitApp` và các lớp visual cũ; chỉ chuyển thành hook/view độc lập theo kiến trúc mới, không bê nguyên callback cũ. |
| `Makefile.fullscreen`, `DuoFaceFullscreenBridge.plist` | Cấu hình build/injection trên môi trường Theos rootless, có thể tham khảo khi thiết kế gói mới; không ghi đè các file bản ổn định. |

**Các bằng chứng sẵn có cần đọc trước khi viết mã:** `docs/fullscreen-root-cause-20261014.md`, `docs/duoface-v12-native-split-focus-20261014.md`, `docs/airaw_171k_fullscreen_binary_findings.md`, `audit/v12-host-path-20261014.txt`, `audit/v12-split-focus-restore-chain-20261014.txt`, `audit/v12-picker-close-app-chain-20261014.txt`, `scripts/v12_host_recovery.py`, `scripts/airaw_focus_recovery.py`. Chỉ tra lại khi có nhu cầu cụ thể; không bắt đầu quét toàn bộ binary như chưa từng nghiên cứu.

**Nguồn tham khảo bên ngoài để đánh giá, chưa chọn làm dependency:** Airaw và DuoDash (tham khảo hành vi, kiểm tra quyền dùng trước khi lấy mã), CarPlay Cast (cần xác nhận licence/phiên bản khi tái sử dụng), CarSurf `pavunato/carsurf` (repo công khai, chưa chứng minh có quyền tái phân phối vì chưa thấy license rõ), DualPane `blueskycrb/DualPane` (đã thấy LICENSE MIT; quản lý scene/window, **không phải** bộ chia CarPlay hoàn chỉnh). Không tuyên bố các dự án này tương đương DuoFace hoặc hoạt động trực tiếp trên máy đích.

## 5. Trạng thái độc lập ở checkpoint khởi tạo

- **Đã chốt yêu cầu:** không phụ thuộc DuoNavi, không sửa license gốc, bảo toàn trải nghiệm DuoFace, tạo đầu mối bàn giao tách khỏi lịch sử phiên bản cũ.
- **Đã đối chiếu:** đúng repo/branch/HEAD và các file nguồn, bản DEB cuối và audit. GitHub Actions mới nhất `38679315617` đã `completed/success`; tại lần kiểm tra danh sách 8 run mới nhất không thấy run đang chạy.
- **Chưa làm:** chưa tạo nhánh code độc lập; chưa có window/scene manager viết riêng; chưa tạo `com.duoface.app` độc lập; chưa compile/build/test DEB độc lập; chưa cài thử trên thiết bị; chưa phát hành Sileo.
- **Chưa rõ, phải xác minh bằng thực nghiệm:** các API/private class khả dụng trên bản iOS jailbreak đích; host/scene lifetime; tương tác hai cửa sổ, bàn phím, audio, xoay màn hình, tỉ lệ split và thao tác chạm; license nguồn mở của mọi thành phần định dùng; liệu module fullscreen sẵn có kết nối được với host mới.
- **Không lưu dữ liệu bí mật:** tuyệt đối không commit UID/UDID, token, chứng thực, mã kích hoạt, file giấy phép của người dùng hoặc dữ liệu máy chủ.

## 6. Bước tiếp theo cụ thể — điểm tiếp tục cho chat sau

1. **Đọc file này trước**, rồi `README.md`, `tiep tuc du an.md` cũ *chỉ ở các đoạn có liên quan*, `docs/` và `runtime/` được liệt kê; xác minh `main` HEAD/commit và các Actions jobs thực tế, tránh build trùng.
2. Khi người dùng giao lập trình, tạo nhánh công việc độc lập (ví dụ `feature/duoface-independent-core`), không sửa/ghi đè `dist/candidates/menu-native1` hay package bản ổn định. Ghi chính xác tên nhánh + commit ở đây ngay khi tạo.
3. Dựng bảng trách nhiệm cụ thể của native `CB*` đang được gọi trong source DuoFace; phân tách chức năng CarPlay system, quản lý host/scene, split view, picker, command/ACK, và bất kỳ chỗ nào gọi sang thư viện kế thừa.
4. Lập nguyên mẫu **tự nạp** rootless Theos, package dự kiến `com.duoface.app` (khác gói cũ), không gói bất kỳ binary core hay plist giấy phép DuoNavi. Chứng minh quản lý được hai host/app scenes độc lập; ghi log/window bounds và rollback. Đây là **mốc kỹ thuật quan trọng nhất**.
5. Chỉ khi nguyên mẫu thực sự chạy trên thiết bị mục tiêu: chuyển lần lượt split/resize, chọn app/đổi app, focus/restore, giao diện 4 mục, Zoom fullscreen, swap, Clear All/Close, viền đỏ và tài nguyên thương hiệu. Hồi quy trên CarPlay thật từng đợt.
6. **Tiêu chí nghiệm thu độc lập:** `dpkg-deb -I/-c/-x` chứng minh đúng `Package`, `Architecture`, không có file/nhị phân/identity/license DuoNavi; có SHA256; thiết bị không cài DuoNavi vẫn khởi động và dùng đủ split, fullscreen, menu, âm thanh, keyboard, restore; log thực tế và ảnh/test người dùng. Sau đó mới hỏi quyền phát hành.
7. Sau mỗi quyết định/commit/build/test/blocker, **đọc lại file đang có và ghi nối tiếp nhật ký bên dưới**, nêu lệnh/đường dẫn/SHAs/logs/job IDs/bước tiếp, rồi đọc lại xác minh GitHub commit. Không cập nhật `tiep tuc du an.md` cũ cho hướng độc lập.

## 7. Nhật ký tiến triển

### 2026-10-15 ICT — Chuyển đầu mối bàn giao sang dự án DuoFace độc lập

- **Yêu cầu người dùng:** ngay tại repository `Duoface` tạo đầu mối bàn giao **mới, tách riêng** để lưu toàn bộ quyết định và các mốc kỹ thuật của hướng DuoFace độc lập. Không ghi tiếp hồ sơ DuoNavi/v12 cũ.
- **Đã quyết định:** tập trung phát triển mã nguồn/tweak độc lập, không phụ thuộc giấy phép hoặc lõi DuoNavi; giữ mọi tính năng DuoFace đã phát triển nếu có thể chứng minh tương thích; tách khỏi sản phẩm cũ bằng nghiên cứu và tự triển khai thay thế phù hợp. Không xây cấp phép DuoFace ở phiên bản đầu tiên.
- **Đã thực hiện trong lượt này:** đọc GitHub nguồn kỹ năng `Gpt-training-` (SKILL_INDEX/AGENTS/DEB_IPA/PROJECT_INSTRUCTIONS), đọc hồ sơ cũ, xác minh HEAD và audit DEB; tạo **file bàn giao mới này** và trỏ README sang nó. Không sửa mã nguồn runtime, không build DEB, không chạy deploy.
- **Kiểm chứng:** bước ghi/đọc lại commit của file này và README cần được xác nhận từ GitHub. Nếu việc ghi thành công nhưng readback lỗi, phải báo rõ readback chưa xác minh thay vì xem như thành công hoàn chỉnh.

---

**Nhắc cho phiên mới:** Nguồn trạng thái DuoFace độc lập **là file này**. `tiep tuc du an.md` root chỉ chứa lịch sử bản kế thừa. Ghi chứng cứ đã làm, không suy đoán và không lặp lại các tác vụ đã hoàn tất.
