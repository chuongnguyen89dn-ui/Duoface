# DuoFace DIAG2 — đọc trước khi cài (iPhone X, iOS 16 jailbreak rootless)
- DIAG2 chỉ thay thế gói chẩn đoán `com.duoface.diagnostic` (v0.1 DIAG1 → v0.2 DIAG2); không thay `com.duoface.independent` Speed8 và không phát hành qua Sileo.
- Chỉ cài vào iPhone X đang lỗi. Không cài vào iPhone 8 Plus hoạt động tốt.
- Tệp lấy từ GitHub nhánh `feature/duoface-exact-payload-migration`, thư mục `dist/diagnostic/diag2/`. Chỉ thử sau khi CI build success và có file DEB + SHA256SUMS.
- Cài DEB bằng Filza hoặc trình cài phù hợp và **respring**. Trong lúc xe đang đỗ, kết nối CarPlay, chạm biểu tượng DuoFace hai lần cách nhau khoảng 5–10 giây, ghi giờ chính xác và để CarPlay kết nối thêm ít nhất 30 giây.
- Gửi **hai file** trong `/var/mobile/Library/Logs/`: `DuoFaceDiagnostic2-SpringBoard.jsonl` và `DuoFaceDiagnostic2-CarPlay.jsonl`. File CarPlay có thể không tồn tại nếu chưa có process matching/injection: đó là phát hiện cần ghi lại, không được coi là đã log click. Hãy gửi ảnh danh sách file nếu không thấy.
- Log `HOOK_INSTALLED` chứng minh selector được gắn hook. `HOOK_SKIPPED_ABI` chứng minh không gắn do chữ ký không hợp; `HOOK_UNAVAILABLE` nghĩa là thiếu MSHookMessageEx. `ENTER_DashIconTap` rồi `ENTER_DashRequestActivation` là các bước click/activation; `ENTER_SBAppRequest` / `ENTER_SBStateChange` ở SpringBoard thể hiện relay; `ENTER_SBSetWindow`, `ENTER_WindowCreate` giúp khoanh vùng dựng cửa sổ.
- **Không kết luận click thất bại chỉ từ sự thiếu log**, trừ khi `LOADED` và hook tương ứng đã cài đúng process. Trường hợp process CarPlay tên/bundle ID khác lọc, cần khảo sát process trước khi thay bộ lọc.
- Khi cần quay lại: gỡ riêng `com.duoface.diagnostic`, respring; DuoFace Speed8 giữ nguyên.
- Không nhập lệnh xóa dữ liệu, không reset CarPlay, không cài lại DuoFace. Đây là probe READ-ONLY tại API, chưa kiểm thử thực tế cho tới khi người dùng gửi log.
