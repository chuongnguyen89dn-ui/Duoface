# BÁO CÁO VERDICT QA184 (0.0.184~fit2) — cho Claude Spec

Từ: Muse (implementer) · Ngày: 03/11/2026
Nguồn: export `DuoFaceAudit 8.txt` (main `069cec4a54`, tải lên 16:28 giờ VN,
phiên sau khi Nguyen cập nhật QA184) + 2 ảnh Nguyen chụp 16:24 + lời báo của Nguyen.
Mọi số dưới đây Muse đếm trực tiếp từ export.

## Lời Nguyen (nguyên văn ý)

- Lúc phím mới hiện thì KHÔNG ĐỀU; **sau khi chạm vào thì hiện đều** (ảnh 2).
- Phím chỉ xuất hiện ở Google Maps và Waze; các app khác không hề hiện.

Ảnh 1: Maps trái / Waze phải, phím của Waze vừa mở — hàng phím lệch, cụt mép.
Ảnh 2: Waze — phím đầy đủ, đều, đã gõ được chữ "H", kết quả tìm kiếm cập nhật trực tiếp.

## Số đo Maps

- kbfit: 82 dòng = **8 applied + 66 skip (already-fit) + 8 restored → 8 chu kỳ**,
  mọi chu kỳ đều có applied. Bề ngang cửa sổ qua các chu kỳ: 382 / 441 / 509 / 764
  (toàn bộ là pane ngang; **phiên này không có chu kỳ pane dọc**).
- Fit tầng 2 chạy ở 34/34 lần đánh giá có fit (f2=on, f2=off = 0): a (host sau
  relayout) = c (host sau đặt) = neo đáy bề ngang cửa sổ; b (container) = bounds cửa sổ.
- **Đo sâu: 12/12 dòng deep= cho cùng một chuỗi**
  `UIInputSetContainerView@W > UIInputSetHostView@W > UIView@W > UIKBInputBackdropView@W`
  với W = đúng bề ngang cửa sổ. Tức ở điểm sâu nhất ĐO ĐƯỢC, bề ngang = bề ngang
  cửa sổ ở 100% lần đo.
- **Tầng (d) không kích hoạt lần nào (d=na ×34, d=on ×0)** — đúng điều kiện Spec đặt:
  độ lệch đo được = 0 ≤ 8pt nên (d) không chạy. Hệ quả: ảnh đều/không đều KHÔNG
  phân biệt được theo profile d/nod — cả hai profile đều kết thúc đều, nhờ tầng 2
  cộng dàn trang gốc.
- **Giới hạn của dụng cụ đo (Muse tự khai)**: chuỗi deep dừng ở
  `UIKBInputBackdropView` — tấm nền SAU hàng phím. View hàng phím thật
  (keyplane/LayoutStar) không nằm trong chuỗi đi xuống (nhánh backdrop thắng
  theo bề ngang). Vậy "bề ngang view phím sâu nhất" theo đúng chữ của cổng
  vẫn CHƯA đo trực tiếp được; cái đã chứng minh là container + host + backdrop
  đều đúng bề ngang từ nhịp đo đầu tiên.

## Đối chiếu cổng Spec

- Cổng số (nhịp +0,3s, sâu nhất = cửa sổ ±8, ≥90% chu kỳ): **đạt ở mức dụng cụ
  đo được** (12/12 dòng deep, mọi chu kỳ đều có dòng deep ở nhịp đầu/cuối).
- Cổng ảnh (≥3s, hai hướng, đủ hàng, gõ được): **đạt một phần** — hướng ngang
  đạt khi đang dùng (sau chạm: đều, đủ hàng, gõ được ở cả Maps và Waze);
  khoảnh khắc vừa mở vẫn chưa đều (ảnh 1); **hướng dọc chưa có dữ liệu phiên này**.

Theo bảng quyết định của Spec, trường hợp này gần nhất với ô "đo nói đúng mà
ảnh vẫn sai → báo Spec, không tự kết luận" — với sắc thái: cái "sai" chỉ còn ở
khoảnh khắc mở đầu, nằm DƯỚI tấm backdrop mà dụng cụ đo không với tới, và tự
khép lại ở lần chạm/dàn trang đầu tiên. Muse không tự tuyên bố đóng vụ phím;
chờ Spec phán: (i) chấp nhận trạng thái này và đóng Maps, hay (ii) coi khoảnh
khắc mở đầu là lỗi còn lại — và nếu (ii), cần nói rõ dụng cụ đo nào với tới
được hàng phím, vì chuỗi deep hiện tại đã đi hết đường view con khả thi.

## Waze — LẦN ĐẦU CÓ PHÍM

- kbdiag Waze: **16 bản ghi, ~6 chu kỳ** (10 skip + 6 restored) — bốn export
  trước đều bằng 0. app-touch Waze: 14 (Audit 7: 0). R3 chạy thật:
  `stage=R3 ev={sh:5..11, iwc:4..6, te:30..66, sf:4..7} hw=0` — các hook cửa sổ
  QA182 BẮN trong Waze, hw= đọc được = 0.
- NHƯNG capture trong Waze **không thấy cửa sổ phím**: kbClass=none, kbFrame=?,
  khung end của notification là {{0,732},{414,4}} (cao 4pt, tọa độ điện thoại).
  Fit không chạy trong Waze (0 dòng f2) — và theo ảnh thì **không cần**: phím
  Waze tự đều sau chạm đầu, gõ được. Waze khác Maps ở chỗ cửa sổ phím không
  lộ diện qua liệt kê trong process — cùng họ với lỗi no-kb-window của Maps
  QA179 nhưng thường trực.
- Muse không khẳng định nguyên nhân Waze sống lại (ứng viên: suite QA183 tắt
  mặc định từ QA184 là thay đổi phía Waze duy nhất; hoặc phiên này Nguyen thao
  tác trực tiếp trong Waze khi nó là pane active — app-touch 0→14 ủng hộ vế
  thao tác). Số đo chỉ nói: nó sống, và đường R3 đã chứng minh hook bắn.

## Các app khác + hồi quy

- kbdiag toàn phiên chỉ có Maps (78) và Waze (16). YouTube: app-touch ×2,
  không có lần bật phím nào. Vậy "app khác không hiện phím" trong phiên này =
  không app nào khác *thử* bật phím; phím là của iOS, tweak không tạo phím —
  điều kiện là ô nhập nhận focus, hiện mới chỉ xảy ra tin cậy ở Maps/Waze.
- HUD: qa178-hud-gate ×18, không hồi quy. Không crash SpringBoard trong phiên.
  Suite QA183: s183=off ở mọi dòng f2 (đúng mặc định tắt).

## Kết luận của Muse

QA184 đạt phần việc đã thiết kế: tầng 2 ép đúng container/host/backdrop theo
cửa sổ, (d) đứng ngoài đúng điều kiện, Waze có phím lần đầu, không hồi quy.
Phần chưa khép là khoảnh khắc mở đầu của hàng phím (dưới backdrop, ngoài tầm
dụng cụ đo hiện tại) và pane dọc chưa có dữ liệu. Chờ Spec phán theo bảng
quyết định; Muse không tự build tiếp vòng phím nào.
