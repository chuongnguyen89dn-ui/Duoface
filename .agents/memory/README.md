# Mục lục trí nhớ DuoFace (chỉ là con trỏ)

Mỗi mục: tài liệu gì, ở đâu, khi nào phải mở, và cảnh báo khi dùng.

## Trạng thái hiện tại — đọc TRƯỚC mọi nhiệm vụ
| Tài liệu | Vị trí | Dùng để | Cảnh báo |
|---|---|---|---|
| `LOI_HIEN_TAI.md` | `sideplay/spec-knowledge/` (spec-main) | Verdict nén mới nhất của các vòng QA, lỗi hiện tại, bước tiếp theo | Đây là nguồn trạng thái chính. Đoạn nào trong file lịch sử mâu thuẫn với file này thì file này thắng |
| `CAU_TRUC_DEB_GOC.md` | `sideplay/spec-knowledge/` (spec-main) | Cây cấu trúc gói DEB gốc (chỉ-đọc) | Chỉ là sự thật về gói gốc, không phải mã nguồn biên dịch được |

## Lịch sử — chỉ mở đúng đoạn cần
| Tài liệu | Vị trí | Dùng để | Cảnh báo |
|---|---|---|---|
| `tiep tuc du an.md` (sideplay) | `sideplay/` (~491 KB) | Diễn biến từng vòng QA, quyết định và lý do | Không nạp nguyên khối. Tìm theo từ khóa/commit rồi đọc quanh đoạn đó |
| `tiep tuc du an.md` (gốc) | gốc repo (~699 KB) | Lịch sử workstream DuoFace độc lập | Khác workstream với bản sideplay — xác định đúng việc trước khi đọc |
| Các thư mục audit `qa176`–`qa179` | `sideplay/` | Hồ sơ audit chi tiết từng vòng | Không dùng làm trí nhớ thường trực; verdict của chúng đã nén trong `LOI_HIEN_TAI.md` |

## Hồ sơ phân tích chuyên sâu (phía Muse, không nằm trong repo)
| Hồ sơ | Vị trí | Dùng để |
|---|---|---|
| `OMNICAR_BAN_PHIM.md`, `OMNICAR_BAN_PHIM_SAU.md` | `~/workspace/duoface-audit/` | Cơ chế bàn phím tự vẽ của OmniCar, đối chiếu khi làm việc về bàn phím |
| `OMNICAR_CO_CHE_APP.md`, `OMNICAR_APP_BAN_DO.md` | `~/workspace/duoface-audit/` | Cơ chế host app / app bản đồ của OmniCar |
| `LOG_2104_2111_PHIM.md` | `~/workspace/duoface-audit/` | Đính chính timeline máy tối 04/11 (bản đã cài thực tế vs bản đứng Sileo) |

## Quy tắc sinh trạng thái (chống lệch nguồn)
- File trạng thái hiện tại phía repo chỉ có MỘT nguồn: `LOI_HIEN_TAI.md`.
  Không tạo thêm file `current-state.md` viết tay song song.
- Sau mỗi vòng QA: cập nhật `LOI_HIEN_TAI.md` + ghi một mục vào file lịch sử
  của đúng workstream, trong cùng một commit checkpoint của vòng đó.
- Trí nhớ riêng phía Muse (ngoài repo) và mục lục này phải trỏ về cùng một
  nguồn trạng thái; khi hai bên lệch nhau, dừng và đối chiếu trước khi làm tiếp.

## Việc cần kiểm tra khi triển khai (chưa xác minh tại thời điểm soạn nháp)
- [ ] Repo DuoFace đang ở chế độ công khai hay riêng tư — quyết định mức chi tiết được phép viết vào các file quy tắc trong repo.
- [ ] Commit `97328d5` trên spec-main (tài liệu nghiên cứu 1) — tác giả báo đã lưu, Muse chưa tự truy vấn xác minh.
- [ ] spec-main hiện có `AGENTS.md` / `.agents/` / `.muse/` hay chưa — tác giả tài liệu 1 báo là chưa có; cần truy vấn trực tiếp một lần khi triển khai.
