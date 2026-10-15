# Bàn giao dự án DuoFace mới

> **ĐẦU MỐI BÀN GIAO CHÍNH THỨC TỪ NGÀY 15/10/2026.** File `ban giao du an duoface moi.md` là nơi lưu trạng thái và nhật ký của dự án **DuoFace mới, hoạt động độc lập, không cần DuoNavi**. Đọc file này **trước** khi sửa/chạy/build. Cập nhật chính file này sau các mốc làm việc có ý nghĩa; đừng ghi tiến độ của hướng mới vào hồ sơ cũ.
> **Lưu ý:** `tiep tuc du an.md` ở root repository là **kho lịch sử DuoFace trên nền DuoNavi** để tra cứu kỹ thuật; giữ nguyên, không xóa hay đánh đồng với đầu mối mới. Không tạo thêm hồ sơ tương tự.

## YÊU CẦU BẮT BUỘC MỚI NHẤT — BẢO TOÀN 100% DUOFACE ĐÃ HOÀN THIỆN

- **Người dùng xác nhận hai lần: “giữ toàn bộ 100”.** Yêu cầu này **thay thế** các diễn đạt cũ “giữ tối đa”, “giữ nếu có thể”. Khi chuyển sang lõi độc lập **không được tự ý loại bỏ hoặc thay đổi** bất kỳ chức năng, thao tác, giao diện hay tài nguyên nào đã hoàn thiện và được duyệt trong DuoFace trước đó.
- **Phải giữ nguyên 100% phần người dùng nhìn thấy và sử dụng:** logo/bảng màu/hình ảnh gốc; nền menu native đã duyệt (không xanh lạ, không trong suốt gây chồng ứng dụng); bố cục, kích thước, khoảng cách, tên các mục App – Zoom In/Zoom Out – Style – Close App, icon menu; dòng `logo ứng dụng – tên ứng dụng – chấm xanh/đỏ`, nút Refresh xanh và X trong vòng tròn đỏ; Clear All, trạng thái/viền, chọn ứng dụng, đổi ứng dụng, hoán đổi hai ô, chia màn hình, điều chỉnh tỉ lệ, focus/restore, phóng to/thu nhỏ toàn giao diện, đóng ứng dụng và toàn bộ hành vi đã chốt khác. Đối chiếu DEB/mã/ảnh gốc để đảm bảo không thiếu mục.
- **Chỉ được thay thế lớp triển khai bên trong** còn phụ thuộc DuoNavi: scene/window host, adapter, cơ chế điều phối, đường gọi tới lớp/thư viện nhị phân DuoNavi. Bản độc lập sử dụng `com.duoface.independent`, không cần kích hoạt, giấy phép, ngày sử dụng, máy chủ hay thư viện DuoNavi.
- **Tiêu chí bắt buộc:** lập bảng đối chiếu từng chức năng giữa bản đã duyệt và bản độc lập, kiểm tra bằng mã nguồn/DEB, thử nghiệm trên iPhone jailbreak + CarPlay, xác nhận không còn crash. Không được báo đã đạt 100% nếu còn thiếu chức năng, giao diện khác bản đã duyệt, hoặc chưa có bằng chứng kiểm thử. Nếu có trở ngại kỹ thuật phải giữ nguyên yêu cầu và ghi rõ mục chưa đạt, **không tự ý giảm phạm vi** để build nhanh.
- **Bảo toàn bản đang dùng:** không ghi đè, xóa, làm hỏng DEB cũ; phát hành bản thử qua Sileo với package ID mới và đánh dấu thử nghiệm. Không chuyển 100% có nghĩa là đã đạt 100%: hiện đây là **yêu cầu nghiệm thu**, chưa phải kết quả thực thi.

## PHẢN HỒI THIẾT BỊ MỚI NHẤT — 15/10/2026: ALPHA2 SAI GIAO DIỆN ĐÃ CHỐT, KHÔNG NGHIỆM THU

- **Nguyên văn người dùng:** “Giao diện j lạ vậy a bạn? Đây đâu phải giao diện của ta?”; ảnh chụp bản alpha2 hiển thị **thanh floating logo + App/Zoom/Style/Close đặt trực tiếp bên mép màn chia vùng**, **viền đỏ quanh các ô**, các vùng nội dung trống.
- **XÁC ĐỊNH NGUYÊN NHÂN QUA CODE:** `independent/engine/runtime/DFIInterface.inc` tạo `self.toolbar=[self glass]` trong `viewDidLoad`, gắn logo + 4 tab vào **root view chia màn hình**; `viewDidLayoutSubviews` cố định ở đáy màn bằng `toolbar.frame=(...,bounds.height-44,...,36)`. Trong khi giao diện đã duyệt **KHÔNG PHẢI floating toolbar**: `runtime/fullscreen/DFPickerZoomMenu.xm` dòng ~373-502 bố trí logo 120pt + App/Zoom/Style/Close trên **cùng dòng 30pt bên TRONG bảng chọn ứng dụng native**, giữ native blur, X riêng cách 48pt, các nút/đường viền chuẩn. Việc copy logo/font/tab nhưng giữ lớp toolbar tạm là **thay đổi sai thiết kế**, không phải “đã chuyển xong 100%”.
- **Viền:** `DFIInterface.inc` tự viết `updateInteractionBorders` theo việc `toolbar.hidden` và `hosts[i]!=NSNull`, không ràng buộc scene thực/phiên tương tác; vì vậy có thể tạo viền đỏ quá nhiều nơi, khác logic `DuoFaceBorderRunner.m` gốc chỉ hiển thị khi phiên tương tác đang chạy, ẩn khi idle/focus.
- **Quyết định sửa:** không tiếp tục copy skin lên toolbar tạm; chuyển menu 4 mục, logo, nút X, app list vào **picker sheet độc lập** theo hình học từ `DFPickerZoomMenu.xm`, không cần nhị phân DuoNavi; không nổi menu trên toàn màn chia vùng; khôi phục điều kiện border theo phiên tương tác, không viền quanh vùng trống. Giao diện native blur gốc phải tham chiếu code và ảnh đã duyệt, không tự chọn một bảng màu mới.
- **Trạng thái:** alpha2 **đã lên Sileo nhưng KHÔNG ĐẠT giao diện**; giữ bản này để đối chiếu, không tự nhận bản UI đúng. Chưa có bản vá/UI đúng nghiệm thu. Đường tiếp nối: sửa mã trên nhánh feature, CI kiểm tra, dùng package ID `com.duoface.independent`, nâng version mới khi phát hành, xác minh Sileo public và đợi người dùng xác nhận ảnh/trải nghiệm thật.
- **Không đụng:** gói DuoFace kế thừa `com.duonavi.app`, file `tiep tuc du an.md` cũ, mã giấy phép và dữ liệu thiết bị.

## TRẠNG THÁI HIỆN TẠI — 15/10/2026: chuyển giao diện/ảnh DuoFace sang lõi độc lập; bản alpha2 đã xuất bản Sileo và kiểm chứng trực tiếp

- **YÊU CẦU HIỆN TẠI:** Di trú **100%** dữ liệu ảnh, giao diện, thao tác và chức năng DuoFace đã hoàn thiện sang `com.duoface.independent`, không giữ phụ thuộc nhị phân/giấy phép DuoNavi. 100% là **tiêu chí nghiệm thu**, chưa đạt đủ trên thiết bị.
- **ĐÃ CHUYỂN/ĐÃ ĐÓNG GÓI 10/10 tài nguyên gốc:** `independent/engine/assets/transfer_approved_assets.py` kiểm 7 SHA256 ảnh chuẩn, lưu đường dẫn riêng `/var/jb/Library/Application Support/DuoFaceIndependent/`. Logo ngang và menu 4 mục App/Zoom/Style/Close, chấm xanh đỏ, Refresh/X, Clear All, Swap, viền đỏ 1pt, iPhone icon hết hidden; bộ chrome zoom độc lập đã thêm ở `DFIChrome.inc`. Bảng đối chiếu: `docs/doi-chieu-100-phan-tram-duoface-moi.md`.
- **BUILD alpha2 thành công:** `Duoface` run **38695321782**, job **116290417943**, result SUCCESS, nguồn `4e347cfb6aa5bca7f8966ccc6c61b8112ee619f3`. DEB `dist/independent/alpha2/com.duoface.independent_0.1.0~alpha2_iphoneos-arm64.deb` trên nhánh `feature/duoface-independent-core`, 1.078.180 byte, SHA256 **`e0b9f509a847da56a90dc390394e808e5418cf402989e00fa321e89e0f4f5d19`**. Artifact build **11953119034**, báo cáo `BAO_CAO.json`.
- **SILEO alpha2 ĐÃ PUBLISH & VERIFIED:** repo `chuongnguyen89dn-ui/carplaydsp`, workflow `.github/workflows/build.yml` commit `264bdc10c7b027a5a57180e30cd0804e958d85ed`, run **38695614033 completed/success** (cả build và deploy). Kiểm tra tải thực từ GitHub Pages run `Duoface` **38696092565 completed/success**, job **116292882513**, source `695ee8a7ce9f29e36e74313933ce964a13967987`: `Packages`, `Packages.gz`, DEB alpha2 đều OK; Package ID `com.duoface.independent`, Version `0.1.0~alpha2`, hash khớp, gói cũ `com.duonavi.app` vẫn có. Artifact kiểm chứng **11953709330**.
- **Chưa đạt 100% chức năng:** chưa chạy bản alpha2 trên CarPlay/iPhone thực, chưa biết đã khắc phục crash chọn app alpha1 hay chưa. Zoom hình học và viền/native picker/độ ổn định còn phải kiểm tra trên máy. Các phần chuyển mã chỉ mới compile/pass package, **không phải chứng minh tương đương 100%**.
- **Bước tiếp:** chủ dự án refresh nguồn Sileo `https://chuongnguyen89dn-ui.github.io/carplaydsp/`, cập nhật `DuoFace Mới (Thử nghiệm)` lên `0.1.0~alpha2`; test mở/đổi app nhiều lần, Zoom/Style/Close, icon trên iPhone, danh sách app, màu/chấm/viền, so với bản duyệt và cung cấp crash log nếu lỗi. Tiếp tục sửa theo kết quả; mọi bản cập nhật dùng package ID mới, không đè bản cũ.


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

### Bản gốc đối chiếu đã đóng gói (chưa phải bản DuoFace độc lập)

- Đường dẫn DEB GitHub: `dist/candidates/menu-native1/com.duonavi.app_1.0.3-12_menu-native1_iphoneos-arm64.deb`.
- Tên gói **thực tế**: `com.duonavi.app`, version `1.0.3-12+menu-native1`, rootless `iphoneos-arm64` (2,197,192 bytes); SHA256 `ce971b42230d355421b2b1d99793a1f62ffb75008365ea74a3467d859cc1de3a`.
- Đã build/persist: Actions run `38679315617` SUCCESS, job `116239986449`, artifact `11947453212` (`duoface-menu-native1`), commit chứa DEB `2053fa0b13a75a31c0afb62dee1ce9ac331bc1b8`. Các bằng chứng: `dist/candidates/menu-native1/{BUILD_AUDIT.json,SHA256SUMS.txt,CONTENTS.txt}`.
- Quan sát CI: chỉ `DuoFaceFullscreenBridge.dylib` khác bản nền `menu-opaque1`; Dashboard kế thừa **giữ nguyên** SHA256 `bc1df854ec7a2ddfeec4cb81b080ead34b54df80143d4a8f6254bb8b618003ce`.
- **Trạng thái chính xác:** `PACKAGE_BUILT_NOT_DEVICE_TESTED_NOT_SILEO`. Bản `menu-native1` chưa được người dùng xác nhận test thiết bị hoặc phát hành Sileo. Không tự ghi thành PASS.
- Nội dung gói vẫn chứa `DuoFaceDashboard.dylib`, `DuoFaceUI` kế thừa và `com.duonavi.sync.plist`. Vì thế **không thể gọi là ứng dụng độc lập** và cũng không dùng làm gói phát hành độc lập.

## 4. Tài sản kỹ thuật có thể dùng lại / ranh giới phụ thuộc

| Mã nguồn hiện có trong kho | Kết quả kiểm tra / hướng xử lý khi xây dựng bản độc lập |
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

## 5. Trạng thái khi bắt đầu dự án độc lập

- **Đã chốt yêu cầu:** không phụ thuộc DuoNavi, không sửa license gốc, bảo toàn trải nghiệm DuoFace, tạo đầu mối bàn giao tách khỏi lịch sử phiên bản cũ.
- **Đã đối chiếu:** đúng repo/branch/HEAD và các file nguồn, bản DEB cuối và audit. GitHub Actions mới nhất `38679315617` đã `completed/success`; tại lần kiểm tra danh sách 8 run mới nhất không thấy run đang chạy.
- **Chưa làm:** chưa tạo nhánh code độc lập; chưa có window/scene manager viết riêng; chưa tạo `com.duoface.app` độc lập; chưa compile/build/test DEB độc lập; chưa cài thử trên thiết bị; chưa phát hành Sileo.
- **Chưa rõ, phải xác minh bằng thực nghiệm:** các API/private class khả dụng trên bản iOS jailbreak đích; host/scene lifetime; tương tác hai cửa sổ, bàn phím, audio, xoay màn hình, tỉ lệ split và thao tác chạm; license nguồn mở của mọi thành phần định dùng; liệu module fullscreen sẵn có kết nối được với host mới.
- **Không lưu dữ liệu bí mật:** tuyệt đối không commit UID/UDID, token, chứng thực, mã kích hoạt, file giấy phép của người dùng hoặc dữ liệu máy chủ.

## 6. Bước tiếp theo cụ thể — điểm tiếp nối cho cuộc trò chuyện sau

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
- **Đã thực hiện trong lượt đó:** đọc nguồn kỹ năng GitHub `Gpt-training-`, hồ sơ cũ, xác minh bản sửa đổi và báo cáo DEB; tạo đầu mối bàn giao riêng và cập nhật README. Không sửa mã nguồn chạy ứng dụng, không đóng DEB, không triển khai.
- **Kiểm chứng tại thời điểm lập hồ sơ:** file bàn giao đầu tiên `DUOFACE_INDEPENDENT_HANDOFF.md` đã được ghi tại commit `b469f2e845341950eac1a7593383367d8fca809c`, sau đó README được cập nhật tại `34ed66943096201628d96f8a09383737af30c40e`; cả hai đã được đọc lại từ GitHub.

### 2026-10-15 — Người dùng yêu cầu đặt tên hoàn toàn bằng tiếng Việt

- **Yêu cầu mới:** đặt tên hồ sơ chính thức đúng là `ban giao du an duoface moi.md` và dùng tiêu đề **Bàn giao dự án DuoFace mới**.
- **Thay đổi:** chuyển nguyên vẹn nội dung bàn giao từ file tên tiếng Anh `DUOFACE_INDEPENDENT_HANDOFF.md` sang tên tiếng Việt, giữ lịch sử và đường dẫn tham chiếu cũ; cập nhật liên kết trong `README.md` và xóa **chỉ** file tên tiếng Anh vừa tạo nhằm tránh hai đầu mối cùng hoạt động.
- **Không thay đổi:** `tiep tuc du an.md` của các phiên bản kế thừa DuoNavi, mã nguồn chương trình, gói DEB, quy trình build hay phát hành. Hồ sơ được giữ trong đúng kho `chuongnguyen89dn-ui/Duoface`.
- **Điểm tiếp nối:** kiểm tra GitHub chỉ còn một đầu mối của hướng DuoFace mới với tên tiếng Việt; sau đó triển khai lõi DuoFace độc lập khi người dùng giao nhiệm vụ phát triển.

### 2026-10-15 — Bắt đầu thực hiện công việc DuoFace độc lập

- **Ý người dùng:** “bây giờ ta bắt đầu từ đâu?”; bám quyết định đã chốt: DuoFace mới không phụ thuộc lõi hoặc giấy phép DuoNavi; bảo toàn thành quả đã phát triển. Không yêu cầu đóng DEB trong lượt này.
- **Kiểm tra nơi làm việc:** GitHub `chuongnguyen89dn-ui/Duoface` nhánh `main` tại `5313d965d56b9325a7d93f74b84a6f7214893df8`. Bản đối chiếu vẫn `menu-native1` SHA256 `ce971b42230d355421b2b1d99793a1f62ffb75008365ea74a3467d859cc1de3a`; run `38679315617` success, chưa được xác nhận thiết bị/Sileo. Mười lăm run gần nhất trong kết quả API không có run `in_progress`/`queued`.
- **Hành động GitHub đã xác minh:** tạo nhánh `feature/duoface-independent-core` tại main HEAD trước thay đổi; thêm báo cáo `docs/khoi-dong-duoface-doc-lap.md`, commit `366084e81527c291ce9dd20fb1fe4980d4d60d61`, Git blob `c84dad1f185a7f7ebad14933c658fcf893381c39`. Đã đọc lại nhánh, tài liệu, mã nguồn; **không sửa lõi kế thừa và không build**.
- **Kết luận kiểm tra nguồn:** `DFHostGeometry.xm` vẫn gọi `CB*` để quản lý window/host; `DFPickerZoomMenu.xm` móc `CBMultitaskingOverlayView`; `DuoFaceVisualHook.m`/`DuoFaceBorderRunner.m` cần class của bản kế thừa. Kênh fullscreen và chrome do DuoFace viết có thể giữ logic sau khi đổi phần nhận lệnh, nhưng chưa chứng minh chạy độc lập. **Điểm nghẽn đầu tiên là host hai app scenes**, không phải menu, màu nền hay cơ chế cấp phép.
- **Bước tiếp theo có thể thực hiện ngay:** viết probe/nguồn thử trên nhánh này để xác nhận tiến trình sở hữu CarPlay, class/window/scene API sẵn có, khởi tạo hai host độc lập có khôi phục an toàn; kiểm tra compile tĩnh trước, chỉ đóng/cài DEB theo yêu cầu riêng. Tiêu chí đầu tiên: chạy hai app trên màn CarPlay mà không cài/lấy dữ liệu DuoNavi; log chứng minh hai scene, chạm riêng, thay tỷ lệ và thoát an toàn.
- **Không thay đổi:** `main` runtime, `tiep tuc du an.md` cũ, tất cả DEB, Sileo, giấy phép và dữ liệu ngày của phiên bản kế thừa.


### 2026-10-15 — Đã viết nguyên mẫu đo host và bộ bố cục hai vùng độc lập

- Người dùng ra lệnh **“được rồi làm đi”**, thực hiện bước đầu của DuoFace độc lập trên nhánh riêng. Không cấp phép tự đóng/publish DEB, không đụng bản cũ.
- Repo/nhánh: `chuongnguyen89dn-ui/Duoface`, `feature/duoface-independent-core` (khởi tạo tại `5313d965d56b9325a7d93f74b84a6f7214893df8`). Mã nguồn hiện tại tại `59a7335b0510c8a20d7e1349110c91b343cb6fc5`.
- Các lệnh thực tế thực hiện qua GitHub connector: tạo liên tiếp `independent/DFISplitLayout.h` (commit `e60c0c98d3cb379e1e1a61599a96fddf05bf0639`), `DFISplitLayout.mm` (`a6ab602a5aea746a107dc4399690e89ee6d569b9`), `DFIProbe.mm` (`4dbdd0ae9aee94d6455b55a812580d25124d7f01`), `Makefile.independent` (`e8aedeea3b562d64c4c7029e1dc006ef10bd60ac`), `DuoFaceIndependentProbe.plist` (`f3f3e868d536fb9cba13527422f958c8185d1732`), `independent/tests/validate_probe.py` (`4e2a4e61d53307c981554f75dbfb3e2a50116db4`), `.github/workflows/duoface-independent-compile.yml` (`59a7335b0510c8a20d7e1349110c91b343cb6fc5`). Repo root là thư mục hiện hành trong workflow; chưa dùng git push từ máy do container không DNS GitHub.
- Thiết kế probe: tệp cờ mặc định **không có**, do đó không can thiệp runtime nếu được cài trong tương lai; khi được bật, đăng ký event `com.duoface.independent.probe.snapshot`, dò hiện diện method, quan sát `DBWorkspace.initWithOwner:` và đăng xuất thông số màn CarPlay bằng log tiền tố `[DuoFaceIndependent]`. Chưa tự mở app, chưa dựng overlay, không đụng code giấy phép.
- Bộ bố cục: chỉ tiếp nhận **hai UIView host không trùng nhau đã tồn tại và chưa có cha**, bố cục tỷ lệ trái/phải 0.2–0.8 trên luồng UI, có hàm `detach`. Tuyệt đối **không đánh đồng đây với 2 host scene thật đã hoạt động**.
- CI biên dịch: workflow `duoface-independent-compile.yml` chỉ chạy khi push thay đổi mã của nhánh độc lập, `contents:read`, macOS Theos `make clean all` và upload **log/chỉ số**, cấm tạo `.deb`. Đã xác nhận GitHub run **38686641800** trạng thái ban đầu **queued**, link `https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/38686641800`. **CHƯA có kết quả biên dịch** tại checkpoint này.
- Không thay đổi: `main` mã app gốc, tệp `tiep tuc du an.md` lịch sử, bản DEB `menu-native1`, Sileo/thiết bị.
- Điểm tiếp: xem run `38686641800` và log lỗi chính xác, sửa trên nhánh riêng nếu cần; ghi lại SHA/run/artifact; chưa có kiểm thử chức năng khi chưa cài lên iPhone.


### 2026-10-15 — Phát hiện và sửa hai lỗi CI, biên dịch được thư viện arm64

- CI **38686641800** (job `116262901186`) hoàn thành **failure**, không phải lỗi source: bước Theos clone làm `git clone theos/sdks` đè đường dẫn `$RUNNER_TEMP/theos/sdks` đã tồn tại; log nguyên văn: `fatal: destination path '/Users/runner/work/_temp/theos/sdks' already exists and is not an empty directory.` Sửa workflow thêm `rm -rf "$RUNNER_TEMP/theos/sdks"` trước clone, commit **`d41984cbcd7f74cb17231db554f2cd8d641baa4b`**.
- CI **38686738047** (job **116263204183**) hoàn thành **failure**, nhưng các bước kiểm tra tĩnh + chuẩn bị SDK **success**; log đã xác minh `Compiling independent/DFIProbe.mm (arm64)`, `Compiling independent/DFISplitLayout.mm (arm64)`, `Linking tweak DuoFaceIndependentProbe (arm64)`, `Signing DuoFaceIndependentProbe`. `file` xác nhận `Mach-O 64-bit dynamically linked shared library arm64`; SHA256 **`792844fd8c970eb9ddcd5a5b3162401f39d961053a2104c60a83daaccf2f275b`**. `otool -L` có UIKit/Foundation/objc/libSystem, không thấy tên thư viện DuoNavi hoặc Airaw.
- **Nguyên nhân failure run 38686738047:** sau biên dịch, step kiểm tra `test "$(find . -name '*.deb' -type f | wc -l | tr -d ' ')" = '0'` sai phạm vi vì repo đã có nhiều DEB lịch sử dưới `dist/`. Không tạo DEB nào trong workflow. Đã thay câu kiểm tra bằng chỉ quét `.theos` và đảm bảo không tạo `packages`, commit **`8a5a4f37ae92c89620a349a138b5dd148a3f1b9e`**. GitHub tự mở run **38686933037** lúc kiểm tra: **queued**. Chưa xác nhận conclusion của run mới.
- Có thêm hướng dẫn `docs/kiem-tra-probe-duoface-doc-lap.md` tại commit **`733dc893dc1cc594eb4cf8868d98264cce08e7f1`**, ghi rõ quy trình đo trên iPhone về sau nhưng chưa thực hiện. Không tác động bản ổn định/DEB/Sileo.


### 2026-10-15 — Mốc biên dịch ĐẠT: mã probe DuoFace độc lập, chưa thử thiết bị

- **Xác minh GitHub Actions:** run **38686933037** lúc 05:29:43 UTC, job **116263824980**, `completed/success`; source commit **8a5a4f37ae92c89620a349a138b5dd148a3f1b9e**; toàn bộ bước đều `success` gồm kiểm tra tĩnh, Theos + SDK + ldid, `make clean all`, lipo arm64, `otool -L`, SHA256 và không tạo DEB.
- **Log trích nguyên văn:** `Compiling independent/DFIProbe.mm (arm64)…`; `Compiling independent/DFISplitLayout.mm (arm64)…`; `Linking tweak DuoFaceIndependentProbe (arm64)…`; `Signing DuoFaceIndependentProbe…`; `.theos/obj/debug/DuoFaceIndependentProbe.dylib: Mach-O 64-bit dynamically linked shared library arm64`; `COMPILE_ONLY_SUCCESS_NOT_DEVICE_PASS`. SHA256 **acbbf8ce4b8a99b42f3786691e976cb5bf77cbc8a94db03e9bc2b9781571e709**.
- **Bằng chứng lưu repo nhánh feature:** `audit/duoface-independent-compile-38686933037.json` commit **f9b2870066e2ecfa80593cb56ee925c8f45706f7**. Workflow artifact ID **11949972916** `duoface-independent-compile-38686933037`, digest `7a5415b9741fcf652e4bb5bacba32db438ab56816b4b3442f8958c25dced35c4`, chỉ có báo cáo/log nhỏ, không có binary DEB.
- **Lý do hai lần CI trước thất bại và đã sửa:** 38686641800 do clone SDK đè thư mục đã tồn tại → fix `d41984cb`; 38686738047 do đếm sai các DEB cũ trong `dist/` → fix `8a5a4f37`. Không còn blocker biên dịch cho hai file thử nghiệm này.
- **Giới hạn không được nhầm:** `DFIProbe.mm` chỉ là trình đo (có cờ mặc định TẮT); `DFISplitLayout.mm` nhận hai view có sẵn, chưa thực hiện tạo hai scene. Kết quả này chỉ chứng minh nguồn độc lập **biên dịch và link được**. Để xác nhận ứng dụng độc lập, vẫn phải xây tầng scene host và kiểm thử 2 app thật trên CarPlay mà không có DuoNavi. Không có bản DEB mới; không cài trên thiết bị; Sileo giữ nguyên.
- **Các lệnh đã chạy trong CI tại repo root:** `python3 independent/tests/validate_probe.py`; `python3 -m py_compile independent/tests/validate_probe.py`; `git clone --depth 1 --recursive https://github.com/theos/theos.git "$RUNNER_TEMP/theos"`; `rm -rf "$RUNNER_TEMP/theos/sdks"`; `git clone --depth 1 https://github.com/theos/sdks.git "$RUNNER_TEMP/theos/sdks"`; `brew install ldid`; `cp Makefile.independent Makefile`; `make clean all`; `xcrun lipo "$dylib" -verify_arch arm64`; `shasum -a 256 "$dylib"`; `xcrun otool -L "$dylib"`; và kiểm tra không có DEB mới tại `.theos`/`packages`. Xem thêm chi tiết tại `audit/duoface-independent-compile-38686933037.json`.
- **Bước làm tiếp:** xây tầng scene-host độc lập sau khi kiểm chứng môi trường runtime mục tiêu bằng probe. Giữ nhánh feature và file bàn giao này làm nguồn tiếp nối; chỉ build/cài DEB khi có lệnh riêng.


### 2026-10-15 — Chốt ID gói mới, bắt đầu chuẩn bị cập nhật Sileo và chuyển lõi hai scene

- **Yêu cầu mới thay thế lệnh cấm đóng/publish thử trước đây:** chủ dự án yêu cầu tiếp tục thực hiện và **đưa lên Sileo**, vì tải DEB thủ công nhiều lần bất tiện. Không gỡ/ghi đè bản `com.duonavi.app`; tạo **gói mới `com.duoface.independent`**.
- **Xác minh nơi phát hành:** đã đọc `chuongnguyen89dn-ui/carplaydsp/.github/workflows/build.yml` và `duoface-sileo.yml`; `build.yml` deploy Pages từ `repo/debs`, có DuoFace bản cũ (metadata `com.duonavi.app`). `duoface-sileo.yml` mới staging không deploy. Repo Pages `https://chuongnguyen89dn-ui.github.io/carplaydsp/`. Đã thấy quyền push tới repo phát hành, chưa thay đổi repo đó trong mốc này.
- **Tái sử dụng nguồn thuộc cùng chủ sở hữu:** tìm thấy `carplaydsp/independent-split` đã viết lớp `CPSSceneHost`, `CPSSplitController` cho SpringBoard, tạo cửa sổ trên màn CarPlay bằng `FBSDisplayConfiguration`/`UIRootSceneWindow`, scene qua `SBDeviceApplicationSceneEntity`/`SBAppViewController`; dự án cũ đã kiểm chứng nhiều bố cục và lỗi chữ ký Mach-O trong Alpha1, nhưng chưa có chứng cứ thực tế chức năng hai app trên điện thoại mục tiêu. Đã **chỉ đọc** nguồn repo `carplaydsp`; mã được chuyển/đổi namespace để phát triển tại `Duoface/independent/engine`, không sửa các dự án khác.
- **Nguồn đã lưu vào feature:** `independent/engine/DFI{GeometryTypes,Layout,Layouts}.h`, `runtime/DFIRuntime.{h,m}`, `DFIInterface.inc`, `DFIPerformance.inc`, `app/main.m`, `app/Info.plist`, `shared/DFISettings.{h,m}`, `preferences/`, `packaging/`, `tests/layouts.c`, `verify_package.py`, `build.sh`. Các file tên `CPS`/app bundle cũ được đổi thành `DFI`/`DuoFaceIndependent`; toàn bộ bundle+Darwin notification sang `com.duoface.independent`. `DFIEnabled()` sửa mặc định **NO**, không kích hoạt tự động. Định danh mới không khai báo Conflicts/Replaces buộc Sileo gỡ bản khác.
- **Bộ nguồn tài nguyên:** dùng nguyên ảnh DUOFACE gốc trong kho `dist/visual-1.0.3-12/assets/duoface-icon.png` (Git blob `80d59baa4ae0704e997a6ef0d36bb3c2aa847c65`) rồi `sips` tạo icon kích thước CarPlay; không phát sinh ảnh thiết kế mới.
- **Tạo workflow build thử:** `.github/workflows/duoface-independent-alpha.yml` trên nhánh feature; commit **`c26c350ce05442e3d3a064101de3c4c5dea40a61`**, GitHub Actions run **38687886637** đang `queued` lúc ghi. Workflow đóng gói alpha riêng **chỉ** nếu kiểm thử tĩnh, build, ký, xác minh gói pass; lưu DEB và `BAO_CAO.json` trong `dist/independent/alpha1`, KHÔNG tự triển khai Pages. Tệp chỉ được xem là đã lưu khi GitHub xác nhận commit kết quả.
- **Giảm trùng CI:** sửa `.github/workflows/duoface-independent-compile.yml` chỉ theo dõi `independent/DFIProbe.mm`, `DFISplitLayout.*`, `tests/validate_probe.py` và workflow của chính nó (trước đây `independent/**` gây nhiều run không cần thiết), commit `3844d9641acd6b6c14486a35e917a77492918967`.
- **Chưa đạt:** chưa có DEB `0.1.0~alpha1` đã xác minh, chưa có tên gói mới trong chỉ mục Sileo, chưa thiết bị xác nhận chạy hai app, chưa có giao diện DuoFace gốc. **Không báo đã đưa lên Sileo khi chưa có chứng cứ Pages và gói.**
- **Điểm tiếp tục sau checkpoint:** kiểm tra run `38687886637` tại `https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/38687886637`. Nếu fail đọc job logs, sửa đúng lỗi. Nếu pass đọc `BAO_CAO.json`, git blob DEB; cập nhật `carplaydsp` duy nhất phần index/build DuoFace mới và xác nhận GitHub Pages, APT, SHA256. Sau đó chuẩn bị bước gắn UI DuoFace đã duyệt.


### 2026-10-15 — Đã tạo DEB ID mới và cấu hình cập nhật Sileo hiện có

- Yêu cầu mới: tiến hành tiếp, đưa lên **Sileo**, không yêu cầu tải DEB trực tiếp; ID độc lập.
- Kho mã: `Duoface` nhánh `feature/duoface-independent-core`; đã chuyển scene engine độc lập từ chính code của chủ ở `carplaydsp/independent-split`, thay namespace + app/prefs ID `com.duoface.independent`, xây dựng alpha 0.1.0~alpha1, giữ nguồn thiết kế/logo gốc, không đóng kèm DuoNavi, DuoDash, Airaw. Bản thử mặc định TẮT để tránh hai host đụng nhau.
- Run 38687886637 của DuoFace có các bước build/ký/kiểm tra DEB thành công, nhưng **overall FAILURE** do cố `git push` trong lúc nhánh thay đổi; log `! [rejected] HEAD -> feature/duoface-independent-core (fetch first)`. Đã thêm `git fetch` + `git rebase` trước `git push`, commit `aa9cab5faa8dace1daa2f347a801db1de5938d9e`. CI kế tiếp **38688216990 SUCCESS**, artifact+DEB đã push và được đọc lại.
- **Kết quả thực tế của run 38688216990:** DEB `dist/independent/alpha1/com.duoface.independent_0.1.0~alpha1_iphoneos-arm64.deb` được lưu thật ở commit nhánh **`cab4d9b725a0066c9840a7837a9a0a3a3ea32349`**, blob **`c1a8f1d63ed1a96fbe4d8253f5defb236d6538bd`**, dài 151944 byte, SHA256 **`e1ac3ec78285924308bdb5f7a2d503c39cbf567f8a8293ad87ea1dc551d99439`**. `BAO_CAO.json` Git blob `ec51aeaffd762dca2668805679f8d8962bf5a8d6`, `nguon_commit` `aa9cab5faa8dace1daa2f347a801db1de5938d9e`. Có kiểm thử 2592 bố cục, mã arm64/arm64e và cấu trúc gói; **CHƯA cài hay chạy CarPlay thật**.
- Sileo: đã xác định nguồn đang sử dụng là `https://chuongnguyen89dn-ui.github.io/carplaydsp/`. Repo xuất bản `chuongnguyen89dn-ui/carplaydsp`, workflow `.github/workflows/build.yml` (không dùng `duoface-sileo.yml` vì chỉ staging). Đã đưa khối tải DEB SHA-pinned, kiểm tra Package ID `com.duoface.independent`, Version `0.1.0~alpha1`, Arch `iphoneos-arm64`, payload `DuoFaceIndependent.dylib`, và thêm Icon vào Packages. Commit `78797dd61c67482d8b8af3f56046a58bce55363e`. Sửa Python APT metadata vì cần escape `'\\n'` đúng, commit **`a57e1cb7e7369251d3a2886da2d338852515556d`**.
- Kiểm tra workflow ở mốc này: `carplaydsp` run **38688368476** còn `in_progress`, run mới nhất **38688392804** `pending` do workflow concurrency Pages; **chưa xác minh deploy Sileo thành công**. Bước tiếp: mở `https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/38688392804`, đọc kết quả; nếu thành công phải tải lại Pages `Packages`, `Packages.gz`, DEB và so hash; nếu thất bại sửa đúng log rồi kiểm tra lại.
- Những dự án khác trong repo `carplaydsp` không chỉnh source hay package: **chỉ sửa workflow phát hành chung để thêm đúng gói DuoFace mới**. Không thay các bản DuoNavi/Sileo cũ, không sửa `tiep tuc du an.md` cũ.


### 2026-10-15 — Phát hành Sileo: đã xác định và sửa lỗi băm gói cũ

- Repo xuất bản `chuongnguyen89dn-ui/carplaydsp` commit **`a57e1cb7e7369251d3a2886da2d338852515556d`** bắt đầu run **38688392804**, nhưng **FAILED** tại bước `Build APT repository`. Log chính xác: `shasum: WARNING: 1 computed checksum did NOT match` và `com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb: FAILED`. Lỗi nằm ở **SHA cũ hardcoded** trong workflow phát hành, chưa tới gói mới; không được nhầm với lỗi `com.duoface.independent`.
- Đã đọc hồ sơ hash trong **đúng repo DuoFace**: `dist/visual-1.0.3-12/SHA256SUMS` xác nhận SHA256 của file old `com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb` là **`8b7dedf77b9ec05465b83fdb6e2d7127800eac232a34ecf12f2c08b3983a481a`**, khác giá trị cũ `ed50ed8258762510974c763c15e9d59e082dea3474d618e9626141c8df9182e5` trong `carplaydsp/build.yml`. Không sửa/đổi byte gói cũ; chỉ sửa giá trị kiểm SHA theo tệp manifest và pin tải gói old về revision `fab16e4bd06f7f25611740a556739bfb9393d002` để tránh source biến đổi về sau.
- **Đã đẩy bản sửa** `carplaydsp/.github/workflows/build.yml` commit **`a2cecb1aad39f73f65c19a9a635c4b12f5e2eacd`**; workflow phát hành tiếp **38688787996**, lần đầu kiểm tra `queued`, tiếp theo `in_progress`/đang cài Theos SDK; **CHƯA xác minh success/Pages** tại checkpoint này.
- **Đã giữ nguyên** nội dung DEB DuoFace Mới mới `com.duoface.independent`, SHA256 `e1ac3ec78285924308bdb5f7a2d503c39cbf567f8a8293ad87ea1dc551d99439`, bản thử độc lập package alpha1. Tệp đã lưu trong `Duoface/dist/independent/alpha1/`.
- **Điểm tiếp tục:** kiểm tra run `38688787996` kết thúc; nếu bước Sileo thành công thì xác minh chỉ mục `Packages`/Gzip/DEB thực trên Pages, trước khi báo Sileo hoạt động. Nếu thất bại, đọc log bước gây lỗi, không đoán.


### 2026-10-15 — PHÁT HÀNH VÀ XÁC MINH SILEO THÀNH CÔNG cho DuoFace Mới alpha1

- **Đã đạt mục tiêu phân phối không tải DEB thủ công:** gói mới `com.duoface.independent` phiên bản `0.1.0~alpha1` **đã lên trang Sileo hiện tại**, không thay thế bản DuoFace cũ `com.duonavi.app`.
- **Commit nguồn DuoFace chứa DEB:** `cab4d9b725a0066c9840a7837a9a0a3a3ea32349`, path `dist/independent/alpha1/com.duoface.independent_0.1.0~alpha1_iphoneos-arm64.deb`, SHA256 `e1ac3ec78285924308bdb5f7a2d503c39cbf567f8a8293ad87ea1dc551d99439`, 151944 byte. `BAO_CAO.json` được đọc lại xác nhận. Build source run 38688216990 `completed/success`.
- **Phát hành Sileo sau hai lỗi và sửa đã lưu:** (1) `carplaydsp` run `38688392804` failed tại SHA DEB legacy hardcoded `ed50ed...` không còn đúng với `Duoface/dist/visual-1.0.3-12/SHA256SUMS`; manifest cho SHA `8b7dedf77b9ec05465b83fdb6e2d7127800eac232a34ecf12f2c08b3983a481a`. Sửa workflow trỏ legacy đúng commit `fab16e4bd06f7f25611740a556739bfb9393d002`, SHA trên; **không đụng binary legacy**, commit `a2cecb1aad39f73f65c19a9a635c4b12f5e2eacd`. (2) lỗi Python escape của Sileo metadata trước đó sửa ở `a57e1cb7e7369251d3a2886da2d338852515556d`.
- **GitHub Pages run THÀNH CÔNG:** `chuongnguyen89dn-ui/carplaydsp` Actions **38688787996**, source `a2cecb1aad39f73f65c19a9a635c4b12f5e2eacd`, job **116269656974** build `success`, job **116270387977** deploy `success`. Nội dung vẫn gồm package ID cũ và mới.
- **Kiểm tra độc lập trực tiếp Pages THÀNH CÔNG:** tạo workflow `Duoface/.github/workflows/duoface-sileo-live-verify.yml`, commit `6045179a1a37fcce81dc6926243819b8d5c02e37`. Actions **38689115404**, job `116270683769` `completed/success`. Đã tải lại thực tế từ `https://chuongnguyen89dn-ui.github.io/carplaydsp/Packages`, `Packages.gz`, `debs/com.duoface.independent_0.1.0~alpha1_iphoneos-arm64.deb`. Kiểm tra gzip giải nén khớp Packages, đúng một stanza ID `com.duoface.independent`, phiên bản `0.1.0~alpha1`, kiến trúc `iphoneos-arm64`, Icon URL và `Filename`, `Size` và `SHA256` khớp **DEB thật tải từ Pages**; gói cũ `com.duonavi.app` vẫn có đúng 1 stanza.
- **Log nguyên văn tiêu biểu:** `APT_PKG_INDEX_PASS com.duoface.independent 0.1.0~alpha1 debs/com.duoface.independent_0.1.0~alpha1_iphoneos-arm64.deb`; `APT_OLD_PKG_PRESERVED 1`; `duoface.deb: OK`; `SILEO_LIVE_VERIFIED: APT, GZIP, DEB, SHA256, ID, VERSION, ARCH, OLD_PKG`. Kiểm chứng artifact **11951356178**, ZIP digest `sha256:8802e5facc9a41d4a4dbcd4bf404aea92fc7fed08ca5e82f2f4a9e415988eec8`.
- **Chưa được đánh đồng:** Đây là `SILEO_PUBLISHED_AND_INDEX_VERIFIED / DEVICE_RUNTIME_NOT_TESTED`. Chưa có nhật ký thiết bị xác minh 2 ứng dụng và chưa có đủ giao diện DuoFace truyền thống. Alpha mặc định off, firmware `>=16.0,<17.0`. Không tự xóa bản cũ.
- **Công việc tiếp:** kiểm thử scene chủ bằng log iPhone trong bản alpha, kết nối logic App/Zoom/Style/Close, icon dấu chấm xanh/đỏ và fullscreen toàn màn vào lõi này; tăng version, build, cập nhật dòng package pin trong `carplaydsp/build.yml`, chạy xác minh Pages như mẫu. Giữ mọi thành quả cũ/DEB lịch sử.


### 2026-10-15 13:28 +07 — Phản hồi thử nghiệm alpha1 trên thiết bị thật và điều tra ban đầu

- **BẰNG CHỨNG NGƯỜI DÙNG:** ảnh người dùng gửi cho thấy giao diện chia màn hình 3 vùng (hai vùng phía trên, một vùng dưới), thanh kéo giữa, các nút ba chấm; người dùng xác nhận giao diện hiện và điều khiển được, có mục trong Settings. **Ban đầu có thể mở app, về sau chọn app bị crash.** Không thấy biểu tượng DuoFace Mới trên màn hình chính để bật/tắt. Đây là báo cáo kiểm thử thiết bị đầu tiên; **chưa xác minh 2 scene đồng thời ổn định**, không ghi là PASS.
- **PHÁT HIỆN XÁC THỰC TỪ SOURCE:** `independent/engine/app/Info.plist` trên nhánh `feature/duoface-independent-core`, Git blob `5bf01a6424856ae1c4f8f3694ad4d27a81cf389f`, khai báo `SBAppTags = [hidden]`. Đây là nguyên nhân trực tiếp có thể giải thích biểu tượng không hiện trên màn hình chính; **chưa sửa** để không gây tác động ngoài yêu cầu xác nhận.
- **Vị trí cần truy crash:** `independent/engine/runtime/DFIRuntime.m` (Git blob `161d3e0663c9088df0b7a32ca2ec3e237cd9d4e6`) có `DFISceneHost`, `pollScene`, `updateSettings:withTransitionContext:completion:`, quản lý scene handle, savedSettings, scene closure và class riêng SpringBoard. Cần lấy log `/var/mobile/Library/Logs/DuoFaceIndependent-runtime.log` và crash log SpringBoard khi nhấn chọn app, xác định stack trước khi sửa.
- **Quyết định:** bảo toàn logic chia vùng đang chạy, ưu tiên điều tra crash, sau đó bỏ tag `hidden` nếu người dùng muốn biểu tượng app trên màn hình iPhone. Không suy diễn nguyên nhân crash khi chưa có crash report. Chưa tạo bản DEB tiếp theo, chưa cập nhật Sileo trong lượt này.
- **Bước tiếp:** truy chuỗi chọn app trong `DFIRuntime.m`, kiểm tra lifecycle scene, thêm bảo vệ cần thiết, kiểm thử build; tăng version, phát hành Sileo với SHA-pinned và xác minh nguồn; đề nghị user cung cấp crash log nếu không thể xác định từ source.


### 2026-10-15 — Chốt kết thúc thử nghiệm giao diện lõi, chuyển sang di trú DuoFace độc lập

- **YÊU CẦU MỚI NHẤT:** chủ dự án xác nhận giai đoạn thử nghiệm alpha với giao diện 3 vùng đã đủ để quyết định hướng đi. **Không tiếp tục làm đẹp/phát triển UI alpha**. Mục tiêu từ đây là **mang các chức năng DuoFace đã hoàn thiện trước đây sang lõi hoạt động độc lập, không còn phụ thuộc DuoNavi**.
- **Phạm vi giữ nguyên:** logo gốc, bảng màu/nền menu đã duyệt, App, Zoom In/Out, Style, Close App, cách chia màn hình, thao tác và các chi tiết đã chốt. Không tự ý làm lại chức năng đã xong. Bản DuoFace cũ và lịch sử chỉ để đối chiếu, không xóa hay ghi đè.
- **Phần phải thay:** mọi đường gọi tới binary/lớp riêng của DuoNavi, điều kiện giấy phép/ngày/server/thiết bị của họ; kết nối lại giao diện DuoFace với scene/window host độc lập do chính dự án quản lý. Không dùng thư viện nhị phân DuoNavi/Airaw/DuoDash trong gói mới.
- **Rủi ro đã ghi nhận từ test thực tế:** alpha hiển thị/chỉnh bố cục được, nhưng chọn app bị crash sau lần đầu; chưa xác minh nhiều app chạy bền vững. Phải khắc phục đường chọn app/scene lifecycle trong lúc di trú, không tuyên bố lõi đã ổn định.
- **Package/Sileo:** tiếp tục `com.duoface.independent`, nâng version mỗi bản, dùng nguồn Sileo đã xác minh `https://chuongnguyen89dn-ui.github.io/carplaydsp/`. Không yêu cầu người dùng tải DEB liên tục.
- **Bước kỹ thuật ngay sau đây:** đối chiếu `runtime/fullscreen/`, `src/DuoFaceVisualHook.m`, menu/logo/assets và cơ chế tương tác của DEB cũ với `independent/engine/runtime/DFIRuntime.m`. Lập bảng từng tính năng: nguồn hiện tại, phụ thuộc CB/DuoNavi, API nội bộ mới thay thế, cách test; chuyển từng lớp giao diện/chức năng; xử lý crash, build, Sileo, kiểm thử thiết bị. Không cần dựng lại UI alpha riêng.
- **Tình trạng lượt này:** chỉ chốt hướng và lưu bàn giao; **chưa sửa code, chưa build hay phát hành**.


### 2026-10-15 — Chốt yêu cầu bảo toàn 100% DuoFace

- **Nguyên văn yêu cầu mới nhắc lại hai lần:** “giữ toàn bộ 100”. Người dùng yêu cầu giữ nguyên **toàn bộ** giao diện, logo/tài nguyên, nút, menu, hành vi, khả năng chia màn hình và fullscreen cùng các chức năng đã hoàn thiện ở bản DuoFace cũ, không phải giữ một phần.
- **Quyết định thay thế:** các cách nói trước đây “giữ tối đa” / “giữ nếu có thể” không còn là tiêu chí chấp nhận. Chỉ thay phần phụ thuộc DuoNavi bên trong, không được xóa hoặc làm khác những gì người dùng đã chốt.
- **Kiểm chứng:** đây mới là yêu cầu/phạm vi và tiêu chí nghiệm thu; **chưa phát triển hoặc test chứng minh chuyển được 100%**. Lỗi chọn app crash ở alpha1 vẫn tồn tại theo phản hồi thiết bị, phải được xử lý khi chuyển lõi. Mọi bản alpha lên Sileo phải ghi đúng tình trạng.
- **Bước tiếp:** lập kiểm kê đối chiếu tính năng–đồ họa giữa `menu-native1` và mã DuoFace với `independent/engine`, ghi các phần còn thiếu và phụ thuộc CB*; chuyển mã/UI vào lõi độc lập, build và thử nghiệm từng nhóm; cuối cùng xác nhận tương đương 100% trên CarPlay thật.


### 2026-10-15 — Bắt đầu chuyển tài nguyên và mã DuoFace 100% sang nhánh độc lập

- **Yêu cầu vừa nhận:** “được rồi bây giờ bạn chuyển toàn bộ dữ liệu sang duo mới được chưa?” — thực hiện chuyển toàn bộ chức năng và tài nguyên DuoFace đã chốt sang `com.duoface.independent`, không bớt bất kỳ chức năng nào, không sao chép binary giấy phép/cốt lõi DuoNavi.
- **Đã kiểm tra trạng thái trước sửa:** `Duoface` nhánh `main` HEAD `d1b7e826716c1bc16a6f5ec3f6ff661ef026bf49`; nhánh đang phát triển `feature/duoface-independent-core` HEAD `6045179a1a37fcce81dc6926243819b8d5c02e37`; run mới nhất `38689549365` (snapshot) success, bản alpha1 Sileo `0.1.0~alpha1` vẫn giữ. Không thấy job build/Pages của DuoFace đang chạy trong danh sách 15 run gần nhất.
- **Phân tích nguồn:** Bản duyệt cũ có mã UI tại `runtime/fullscreen/DFPickerZoomMenu.xm`, `DFDashboardChrome.xm`, `DFFullscreenTransport.mm`, `src/DuoFaceVisualHook.m` và assets ở `dist/visual-1.0.3-12/assets/`. Bản độc lập có scene/window thật ở `independent/engine/runtime/DFIRuntime.m` và UI tạm ở `DFIInterface.inc`. Các hook UI cũ phụ thuộc `CBMultitaskingOverlayView`/`CBBridgeManager` nên **không thể chép nguyên nhị phân** mà phải chuyển giao diện/hành vi qua view/scene của bản mới.
- **Kế hoạch thực thi của mốc này:** chuyển toàn bộ ảnh/đồ họa gốc không biến đổi vào đường dẫn asset RIÊNG để tránh 2 package ghi đè nhau; chuyển menu 4 mục, chọn/recent app, màu/chấm/nút và chức năng sang source lõi độc lập; sửa `SBAppTags:hidden` để biểu tượng có thể hiện trên iPhone; thêm kiểm thử parity/static và build nhánh thử. Bản nguồn cũ giữ nguyên. Không đánh dấu 100% khi chưa test CarPlay/khắc phục crash.
- **Nguồn kỹ năng:** đã đọc `Gpt-training-/SKILL_INDEX.md`, `AGENTS.md`, `DEB_IPA_SKILL.md`, `PROJECT_INSTRUCTIONS.md`; đã xác minh có `skills/02-ios-deb-ipa-carplay.zip` trên GitHub nhưng chỉ lấy được base64 qua connector, tài liệu MD đã đọc là bản hướng dẫn áp dụng; không tự tuyên bố giải nén ZIP.
- **Tình trạng:** đã phân tích nguồn, bước ghi sửa mã bắt đầu sau checkpoint này. Chưa sửa hoặc build/deploy tại thời điểm ghi.


### 2026-10-15 — Đã chuyển mã tài nguyên và một phần giao diện chuẩn sang lõi độc lập (CHƯA BUILD)

- **Nguồn và nhánh:** `Duoface/feature/duoface-independent-core`, giữ nguyên `main` cũ. Mã thay đổi đã được commit thực tế: `assets/transfer_approved_assets.py` (`37e59988`), `build.sh` (`9bf8851d`), `verify_package.py` (`ccaac08b`), `app/Info.plist` (`a0396212`), `runtime/DFIApprovedVisuals.h` (`cfa46b7e`), `runtime/DFIChrome.inc` (`1a0cc7c6`), `DFIRuntime.m` (`0f97e1c4`), `DFIInterface.inc` mới nhất (`312ebd74`).
- **Asset transfer:** script `independent/engine/assets/transfer_approved_assets.py` copy nguyên byte **mọi file** trong `dist/visual-1.0.3-12/assets/**`, kiểm SHA256 cho 7 ảnh gốc, lưu vào `/var/jb/Library/Application Support/DuoFaceIndependent/`, không trùng thư mục `DuoFace/` của bản cũ, và tạo `asset-transfer-manifest.json`. `independent/engine/build.sh` gọi script; `verify_package.py` kiểm lại SHA manifest + không mang DuoNavi plist/binary; **chưa có bằng chứng build chạy trong lượt này**.
- **Các chức năng đang chuyển:** logo ngang đúng source, đỏ #E3020F, menu App/Zoom/Style/Close cùng 10pt và active màu đỏ, bỏ border viền menu; danh sách ứng dụng có icon/tên/chấm xanh đỏ và nút Refresh hoặc X, Clear All; Swap/Thoát giữ ở Style; viền đỏ 1pt khi tương tác, ẩn khi nghỉ/phóng 1 ô; app icon iPhone bỏ `SBAppTags:hidden`; Zoom qua adapter chrome riêng và thông báo. Trước đây bản alpha menu khác, các thay đổi này **chưa xác minh biên dịch hoặc nghiệm thu thực tế**.
- **Bảo vệ crash bước đầu:** `DFIInterface.inc` thêm `pendingPanes` để chặn thao tác chọn trùng khi scene đang mở; đây là phòng vệ có căn cứ chứ không phải xác định nguyên nhân crash. Chưa có log crash SpringBoard từ thiết bị.
- **Kiểm kê 100% được lưu:** `docs/doi-chieu-100-phan-tram-duoface-moi.md` nhánh feature commit `190cc099` liệt kê các chức năng đã duyệt, nguồn gốc, nơi di trú và mục thiếu/test. Chưa nhận 100% vì còn nhiều mục chưa test, Zoom hình học cũ chưa chứng minh, scene lifecycle còn lỗi báo cáo.
- **CI:** đã thay `.github/workflows/duoface-independent-alpha.yml` sang `workflow_dispatch` thủ công, commit `a15c4139` để tránh xuất bản trùng package alpha1 khi đang di trú; không đổi bản đã có trên Sileo. **Bước kế:** kiểm tra tính đúng đắn nguồn bằng CI, sửa lỗi compile, đóng DEB ứng viên `0.1.0~alpha2` tách biệt, kiểm nghiệm tài nguyên/ID, rồi chỉ sau khi đủ bằng chứng mới đưa bản thử lên Sileo theo cách tăng version.
- **Nhắc rõ:** người dùng yêu cầu bảo toàn **100%**. Chưa có xác nhận 100% đã hoàn thành. Không được lặng lẽ bỏ chức năng chưa chuyển.


### 2026-10-15 — Mốc build alpha2 đạt, nguồn Sileo đang cập nhật

- **GitHub Actions di trú alpha2:** `.github/workflows/duoface-independent-migration-ci.yml` commit `4e347cfb6aa5bca7f8966ccc6c61b8112ee619f3` khởi chạy **38695321782**. Job **116290417943** completed **success**, các bước test và lưu artifact đều success. Các lệnh: `brew install dpkg ldid`; `sips -s format png -z 120 120 ...` / `sips -z 180 180...`; `bash independent/engine/build.sh`; `python3 independent/engine/verify_package.py "$p"`; `dpkg-deb -f/-c "$p"`; `shasum -a 256 "$p"`, commit lại báo cáo/binary sau `git fetch` + `git rebase` + `git push`.
- **Bằng chứng đóng gói:** log có `DUOFACE_APPROVED_ASSETS_COPIED: 10 files; 7 hashes validated`; `Verified visible iPhone Home Screen icon`; `Verified approved DuoFace artwork copied byte-for-byte into independent resource path.`; `ALPHA2_COMPILED_ASSETS_VERIFIED_NOT_DEVICE_TESTED_NOT_100_PERCENT`. Các cảnh báo compile chỉ gồm UIKit API deprecated và sign-compare, chưa có error. DEB `dist/independent/alpha2/com.duoface.independent_0.1.0~alpha2_iphoneos-arm64.deb` blob `226fbd1b300e2bc1f3a90b339a8dbf84bbf20582`, SHA `e0b9f509a847da56a90dc390394e808e5418cf402989e00fa321e89e0f4f5d19`, 1078180 byte; run artifact **11953119034** zip digest `sha256:0d62de041286b4cd5c42f7f785bbd681a754f1b0af77b438315c8c93869fad19`.
- **Đang triển khai Sileo:** `carplaydsp/.github/workflows/build.yml` commit `264bdc10c7b027a5a57180e30cd0804e958d85ed` thay riêng URL/hash/version `com.duoface.independent` từ `alpha1` sang `alpha2`, chỉ dọn DEB alpha1 của **cùng package**, không chạm packages khác. Run **38695614033** ở trạng thái queued lúc ghi; chưa có bằng chứng Pages/đường tải mới.
- **Tài liệu test parity:** `docs/doi-chieu-100-phan-tram-duoface-moi.md` trên nhánh feature commit `2a09671c8537fddf1d2a7c3a167261277808b02c`. Không đánh dấu PASS toàn bộ: các bước test ảnh/ui/lifecycle real-device chưa xong; fix guard scene chỉ được xem là giảm khả năng reentrant, không thay thế crash trace.
- **Việc tiếp:** kiểm tra run `38695614033`, cập nhật kiểm chứng Pages live alpha2 và chỉ sau đó báo Sileo. Kết quả test người dùng về giao diện thật và crash là cần thiết để hoàn tất yêu cầu “100%”.


### 2026-10-15 — Bản DuoFace Mới alpha2 ĐÃ CẬP NHẬT QUA SILEO, KIỂM CHỨNG PUBLIC

- GitHub Pages `chuongnguyen89dn-ui/carplaydsp` run **38695614033** `completed/success`, cả job build **116291370217** và deploy **116292270143** `success`. Code deploy commit `264bdc10c7b027a5a57180e30cd0804e958d85ed`; chỉ cập nhật gói `com.duoface.independent` lên `0.1.0~alpha2`, vẫn giữ `com.duonavi.app`.
- Workflow kiểm tra live `Duoface/.github/workflows/duoface-sileo-live-verify.yml` đã đổi alpha1 → alpha2 và SHA, commit **695ee8a7ce9f29e36e74313933ce964a13967987**; run **38696092565** `completed/success`, job **116292882513**. Script tải từ `https://chuongnguyen89dn-ui.github.io/carplaydsp/Packages`, `Packages.gz`, `debs/com.duoface.independent_0.1.0~alpha2_iphoneos-arm64.deb`, so khớp gzip, ID, version, arch, icon, size, hash và gói cũ. Log nguyên văn `APT_PKG_INDEX_PASS com.duoface.independent 0.1.0~alpha2 debs/com.duoface.independent_0.1.0~alpha2_iphoneos-arm64.deb`, `APT_OLD_PKG_PRESERVED 1`, `duoface.deb: OK`, `SILEO_LIVE_VERIFIED: APT, GZIP, DEB, SHA256, ID, VERSION, ARCH, OLD_PKG`.
- Artifact kiểm chứng public **11953709330**, ZIP digest `sha256:64264a1e9bde471e984506b5671c1b08380a09b9dd60ddc1b17bf3b365290cf4`. DEB source bản alpha2 SHA256 `e0b9f509a847da56a90dc390394e808e5418cf402989e00fa321e89e0f4f5d19`, 1078180 byte, trong `Duoface/feature/duoface-independent-core/dist/independent/alpha2/`.
- **Đạt:** mã chuyển + asset gốc 10/10 build PASS, Sileo phát hành, public Packages/deb xác thực. **Chưa đạt:** chạy thực tế trên iPhone/CarPlay, xác minh đầy đủ 100%, sửa triệt để crash (chưa có log thực).
- **Bước tới:** kiểm thử bản alpha2 qua Sileo trên thiết bị; ghi crash stack hoặc log runtime nếu app crash, so ảnh menu, Zoom/fullscreen/swap/clear close; tiếp tục di trú thành phần thiếu sau khi có dữ liệu.


---

**Nhắc khi mở cuộc trò chuyện mới:** Nguồn trạng thái DuoFace độc lập **là `ban giao du an duoface moi.md`**. `tiep tuc du an.md` root chỉ chứa lịch sử bản kế thừa. Ghi chứng cứ đã làm, không suy đoán và không lặp lại các tác vụ đã hoàn tất.
