# Bàn giao dự án DuoFace mới

> **ĐẦU MỐI BÀN GIAO CHÍNH THỨC TỪ NGÀY 15/10/2026.** File `ban giao du an duoface moi.md` là nơi lưu trạng thái và nhật ký của dự án **DuoFace mới, hoạt động độc lập, không cần DuoNavi**. Đọc file này **trước** khi sửa/chạy/build. Cập nhật chính file này sau các mốc làm việc có ý nghĩa; đừng ghi tiến độ của hướng mới vào hồ sơ cũ.
> **Lưu ý:** `tiep tuc du an.md` ở root repository là **kho lịch sử DuoFace trên nền DuoNavi** để tra cứu kỹ thuật; giữ nguyên, không xóa hay đánh đồng với đầu mối mới. Không tạo thêm hồ sơ tương tự.

## TRẠNG THÁI HIỆN TẠI — 15/10/2026, đã biên dịch thành công các tệp mã nhưng CI đang xác minh lại

- Nhánh thử nghiệm `feature/duoface-independent-core` có mã đo lớp CarPlay, quan sát workspace và bố cục hai view thật: `independent/DFIProbe.mm`, `independent/DFISplitLayout.h`, `independent/DFISplitLayout.mm`, `Makefile.independent`, `DuoFaceIndependentProbe.plist`, tệp kiểm tra tĩnh và workflow. Có hướng dẫn `docs/kiem-tra-probe-duoface-doc-lap.md`.
- **Bằng chứng biên dịch trực tiếp:** run `38686738047`, job `116263204183`: bước kiểm tra tĩnh SUCCESS; Theos SDK + ldid SUCCESS; log thực đã biên dịch/link/ký `DuoFaceIndependentProbe.dylib` arm64, SHA256 `792844fd8c970eb9ddcd5a5b3162401f39d961053a2104c60a83daaccf2f275b`, `otool -L` không thấy DuoNavi/Airaw. **Workflow tổng thể FAILED** do câu kiểm tra nhầm toàn bộ DEB cũ trong `dist/` là output mới.
- **Đã sửa lỗi kiểm tra chính xác:** file `.github/workflows/duoface-independent-compile.yml` commit `8a5a4f37ae92c89620a349a138b5dd148a3f1b9e`, chỉ quét `.theos` và `packages` cho DEB mới. Run **`38686933037` đang xếp hàng** tại checkpoint này. Trước đó run `38686641800` FAILED vì `git clone` thư mục SDK có sẵn (đã sửa trong commit `d41984cb`).
- **Không ngộ nhận:** Chưa có minh chứng chạy độc lập trên iPhone; hai ứng dụng/scene thực chưa được tạo; không có DEB mới, không cài lên thiết bị, không Sileo.
- **Bước tiếp:** xác minh kết quả cuối của run `38686933037`; nếu PASS chốt mã probe/host-layout compile-only. Sau đó xây module khởi tạo hai scene thật dựa trên số liệu runtime đích và kiểm tra trên máy khi có gói thử được phép build.


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


---

**Nhắc khi mở cuộc trò chuyện mới:** Nguồn trạng thái DuoFace độc lập **là `ban giao du an duoface moi.md`**. `tiep tuc du an.md` root chỉ chứa lịch sử bản kế thừa. Ghi chứng cứ đã làm, không suy đoán và không lặp lại các tác vụ đã hoàn tất.
