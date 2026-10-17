# DuoFace CarPlay QA G1/G2 — hướng dẫn bản thử Sileo

Ngày 2026-10-17. Đây là bộ thử nghiệm lõi CarPlay do DuoFace sở hữu, KHÔNG phải sản phẩm DuoFace hoàn chỉnh. Không tuyên bố đã QA trên iPhone hoặc hiển thị được Waze+YouTube.

## Định danh / bằng chứng đã xác minh

- Repo mã nguồn: chuongnguyen89dn-ui/Duoface; nhánh feature/visual12-duodash-recovery.
- Package APT: com.duoface.visual12; version 1.0.3-12~standalone2qa; kiến trúc iphoneos-arm64; rootless iOS 16.
- DEB lưu GitHub commit 20c3e74654c2dd87c12fff3316967948393b9fc7, đường dẫn dist/visual12-g1g2-qa/com.duoface.visual12_1.0.3-12~standalone2qa_iphoneos-arm64.deb.
- DEB byte SHA256: 12b3e874175bae3059c499c10a365d62e724b2eb27cc3e67178dca2413423daa; bytes: 1068472.
- CI build: https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39047207433 (success). Artifacts ZIP: 12105814338; thư viện/ký/payload được kiểm tra. Bản chưa device tested.
- Sileo repo URL: https://chuongnguyen89dn-ui.github.io/carplaydsp/ ; Sileo publisher commit 26ddc181d4777854846093ed15d79555a1d10425 (đang chờ xác minh Pages vào lúc soạn file).
- Native12+Hub8 com.duoface.independent 0.1.0~native12+speed8compact: không thay package ID, không động bản đang dùng.

## Cách thử trên iPhone JB khi Pages đã xác minh

1. Mở Sileo, làm mới nguồn CarPlayDSP; chọn **DuoFace CarPlay QA G1/G2 (experimental)** với package ID com.duoface.visual12 và version standalone2qa. Đây là bản thử, không phải DuoFace Native12+Hub8.
2. Cài hoặc cập nhật rồi respring theo Sileo; mở ứng dụng **DuoFace QA** trên Home Screen của iPhone.
3. Khi xe DỪNG và iPhone kết nối CarPlay, bật **Bật chế độ QA thủ công**. Mặc định OFF.
4. Điền bundle ID app thực sự đã cài vào App 1/App 2; giá trị gợi ý com.waze và com.google.ios.youtube, có thể sửa.
5. Nhấn **Khởi tạo cửa sổ QA**; sau đó **G1: mở một ứng dụng**, rồi **G2: mở hai ứng dụng**. Không suy ra thành công chỉ từ status gửi lệnh; phải đọc log scene-attached. Nhấn **Dừng QA** để teardown.

**ĐIỀU KIỆN NGĂN XUNG ĐỘT:** nếu SpringBoard đã nạp class CBBridgeManager từ DuoNavi/VisualTest12/Native12 legacy, QA sẽ từ chối mở CarPlay root. Package có thể hiển thị trong Sileo nhưng KHÔNG có nghĩa scene chạy khi đang dùng lõi vendor cũ. Không tự gỡ, tắt hoặc thay đổi các tweak/hub đang sử dụng chỉ để thử; chỉ dùng môi trường kiểm thử có một scene owner và phương án rollback. Ngoài ra private iOS API có thể fail dù không có CBBridgeManager.

## Lấy bằng chứng / xác nhận

- Log QA: /var/mobile/Library/Logs/DuoFaceCarPlayQA.log; chỉ G1-scene-attached mới xác nhận scene đầu tiên, G2-two-scenes-present mới là điều kiện cần (chưa đủ để khẳng định touch/reconnect).
- Log owner/khởi tạo lỗi: /var/mobile/Library/Logs/DuoFaceVisual12-runtime.log, SpringBoard unified log; crash .ips nếu có.
- QA G1: ghi xác nhận app mở và touch, scene có handle thật, không crash.
- QA G2: Waze + YouTube hai pane, touch/resize/swap, ngắt nối CarPlay và teardown không crash.
- Bản build static PASS ≠ device PASS. Nếu báo lỗi, cần log thực tế và chuỗi bước tái hiện.

## Gỡ bản thử và khôi phục

Chỉ gỡ package **com.duoface.visual12** trong Sileo rồi respring. Không uninstall hoặc sửa com.duoface.independent Native12+Hub8 hay com.duonavi.app. App QA không tự bật và không tự xóa dữ liệu các gói khác.

## Source kiểm chứng

- replacement/visual12/build_g1g2_qa.sh — đóng DEB QA.
- replacement/visual12/verify_g1g2_qa.py — xác minh metadata, ký Mach-O, plist inject SpringBoard-only, UI controls và symbol scene-owner.
- replacement/visual12/engine/app/DFCarPlayQAApp.m — ứng dụng điều khiển iPhone.
- replacement/visual12/engine/runtime/DFCarPlaySplitCoordinator.m, DFCarPlayQARootController.m, DFIRuntime.m — host và QA entry.
- .github/workflows/duoface-carplay-g1g2-qa-deb.yml — cách build, lưu DEB trên repo DuoFace.
