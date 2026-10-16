# DuoFace – Smart Connection, checkpoint triển khai source (16/10/2026)

**Trạng thái:** Code core + Objective-C++ adapter đã commit, đã **compile/test CI**, nhưng **CHƯA hook vào host native12**, chưa có row cài đặt mới, chưa đóng DEB, chưa cài/Sileo/device QA. Không đánh đồng compile với feature đang chạy trên iPhone.

## Yêu cầu mới nhất / giới hạn

Người dùng muốn dừng phân tích khác và **tích hợp công dụng Auto Start và Close Apps on Disconnect của DuoDash vào DuoFace, làm mạnh hơn nhưng chỉ giữ 2 mục Cài đặt**. Nhóm 1 phải giữ **một công tắc `Tự động mở` hiện có**, khi ON tự nhớ/khôi phục **app cuối cùng do DuoFace quản lý** và **chống mở trùng**, không thêm switch "nhớ app" hay "chống trùng", không tạo `Kết nối nâng cao` submenu. Công tắc thứ hai `Đóng ứng dụng khi ngắt CarPlay` độc lập, chờ **12 giây**, nếu reconnect thì hủy, chỉ đóng session owned có bằng chứng. Các tính năng nhiều hồ sơ, log UI, giọng nói, tốc độ, Deep Sleep, fullscreen layout, license đều ngoài scope. Giữ quyết định cleanup license PAUSED.

Điều kiện thử âm thanh Youtube trước đây chỉ là **Android display trình chiếu CarPlay, âm thanh phát từ loa iPhone**, chưa thử trên đầu CarPlay của ô tô. Người dùng **đã yêu cầu gác việc chẩn đoán đó sang sau**, không gắn blanket music kill/pause vào feature này.

## Baseline, repo, commits

- Repo `chuongnguyen89dn-ui/Duoface`; source branch **`feature/duoface-exact-payload-migration`**; main chứa handoff `ban giao du an duoface moi.md`. Version hiện có người dùng đã thử **`com.duoface.independent 0.1.0~native12`**, immutable SHA256 **`85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7`**; native10 rollback immutable. Không đè lên native12.
- Đã đọc central `Gpt-training-/SKILL_INDEX.md`, `PROJECT_INSTRUCTIONS.md`, `AGENTS.md`, `DEB_IPA_SKILL.md` và hai handoff, các báo cáo DuoDash/n12. ZIP kỹ năng trung tâm đã được tìm thấy, không tuyên bố đã giải nén ZIP trong lượt này.
- Source feature commits lần lượt: `0a4aa9d5e09d8086be9451c0a8f88330cebd2f93`, `d8ba97fa9fb950ddc66c491933e8694aa8d1fb65`, `47506d9dbfc4fa3e3af36cb844ebd811ed436928`, `afdccb4203c1de3fefa38649fac83b3331381101`, `7c9ae0a585e262d59f33f185c7320f3f7f80bee9`, `6a442251612ac4d8c030f18eff74c092b866d0b4`, `c36d34377f490192f68794093aadefa64e1e4968`. **Đã fetch lại toàn bộ 7 file xác minh blob**.

## Mã mới, nhiệm vụ thật

| File nguồn trên source branch | Trạng thái / vai trò |
|---|---|
| `runtime/connection/DFConnectionPolicy.hpp` | C++17 API thuần dữ liệu, định nghĩa generation, toggle autoStart/closeOnDisconnect, hành động LaunchApp/SaveLastApp/TerminateOwnedApp |
| `runtime/connection/DFConnectionPolicy.cpp` | Đã code: auto-open nhớ last managed app; tránh mở trùng khi đã connected hoặc có active app; giữ session owned set; khi disconnect đã được xác minh hẹn đúng 12,000ms; reconnect/toggle OFF hủy; chỉ emit terminate nếu policy ON, vẫn disconnected, app thuộc session đang được owner kiểm tra |
| `runtime/connection/DFConnectionAdapter.h` + `.mm` | Đã code: bridge Objective-C++ nhận verified events + callbacks đọc key gốc, kiểm installed, mở, lưu app, xác minh/app-owner/đóng; dispatch timer 12s, generation token; **không tự cài hook**. Không tự tạo CFPreferences domain hay copy key DuoDash |
| `tests/connection_policy_tests.cpp` | 11 kịch bản deterministic: OFF, ON mở đúng 1 lần, nhớ app/restore, tắt auto, IDs lỗi, close OFF, close 12s, reconnect cancel, owner guard, tắt close giữa grace, 2 option độc lập |

**Chi tiết safety:** Adapter chỉ phát action khi source hook cung cấp `verified-connected`/`verified-disconnected` + `owned active bundle` + `is installed / still running`; không gọi terminate-all, không sửa callbacks Close App/Zoom/Style hiện hữu. Không dùng `bridgeDidDeactivate:` làm CarPlay disconnect vì có thể chỉ là ứng dụng deactivate. Core chỉ nhớ một bundle ID cho lần launch (không tự restore layout/split/ratio).

## CI/build/test thực tế

1. `.github/workflows/duoface-smart-connection-policy-tests.yml` — GitHub Actions run **`38840229077`** `https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/38840229077` completed SUCCESS, **2 jobs g++ và clang++ đều PASS**, mỗi job `g++/clang++ -std=c++17 -Wall -Wextra -Werror -pedantic -O2 runtime/connection/DFConnectionPolicy.cpp tests/connection_policy_tests.cpp -o ...`, rồi chạy 11 scenarios. Push hậu kỳ tiếp tục chạy same workflow, source chưa được packaging.
2. `.github/workflows/duoface-smart-connection-ios-compile.yml` — GitHub Actions run **`38840462413`** `https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/38840462413` completed SUCCESS, job `116779121929`; macos-15: **`xcrun --sdk iphoneos clang++ -std=c++17 -target arm64-apple-ios15.0 -isysroot "$SDK" -Wall -Wextra -Werror -c DFConnectionPolicy.cpp`** và `-fobjc-arc -fblocks -c DFConnectionAdapter.mm` đều PASS (compile ARM64 objects, **không link/load native dylib**, không build DEB).
3. Baseline native12 read-only audit đã hoàn thành `38838468505` SUCCESS, report `feature:audit/payload-migration/NATIVE12_CONNECT_DISCONNECT_AUDIO_READONLY.json` blob `ddb5ec913f4719027253215ca343653d67909782`. Trong native12 có `CBBridgeManager.handleCarPlayConnectionChanged:`, `effectiveAutoLaunchBundleID`, `terminateApplicationWithBundleID:`, `terminateAllBridgedApplications`, `CBDashboardSettings.autoLaunchOnConnect` và `autoLaunchBundleID`, `CBGeneralSettingsViewController.autoLaunchToggleChanged:`. Có disconnect watchdog và event logging trong nhị phân; **không được viết trùng/override cơ chế native khi chưa có proof callback**.

## Điều còn thiếu để feature THỰC SỰ chạy / next action

1. **Audit read-only native12 pinned** method type encodings / owner + callpaths cho `CBBridgeManager.handleCarPlayConnectionChanged:`, `effectiveAutoLaunchBundleID`, activation `handleStateDict:`, và `CBGeneralSettingsViewController.autoLaunchToggleChanged:` cùng actual CFPreferences domain/key.
2. Tạo Theos/Logos hook tối thiểu **trong đúng SpringBoard host owner** (nếu class/selector/signature khớp) để bind sự kiện connect/disconnect/native app activation vào adapter; phải tránh **auto-launch gốc tự thực hiện song song** (hoặc can thiệp ở một nơi đã xác minh). Hook phải có runtime guards và giữ callback gốc. Kiểm bundle ID thật và app installed/running trước phát action. **Không chỉ include header rồi coi là tích hợp**.
3. Chỉ khi biết đường dựng `CBGeneralSettingsViewController` và preference key chính xác mới thêm **1 hàng switch** `Đóng ứng dụng khi ngắt CarPlay` vào app iPhone. Auto Start row/key giữ nguyên; từ chối giả UI nếu không có callback. Chế độ close OFF mặc định khi nâng cấp.
4. CI compile linked full dylib, test hash/regression và package riêng **native13 candidate** *khi người dùng muốn xuất DEB*, không ghi đè native12. Thử kết nối/ngắt, app đã chạy, reconnect trước/sau 12s trên thiết bị (Android display để test logic; màn CarPlay thật để test audio sau). Không xuất Sileo trừ khi build/test thật.

**Trạng thái cuối lượt đến lúc viết file:** source modules + isolated iOS cross-compile / pure core tests thành công; **không thể tuyên bố feature có trên iPhone** vì chưa nối thực vào host, chưa DEB hay live QA.
