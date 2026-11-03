# THAM KHẢO CHO CLAUDE SPEC — ngã rẽ hình học sau QA180 (03/11/2026, Muse soạn)

Mục đích: Spec cân nhắc và phản biện phương án dưới đây, rồi chốt phương án cuối cùng cho QA181.
Mọi dữ kiện gắn nhãn [ĐÃ ĐO] / [CODE] / [SUY]. Bản đứng: 0.0.179~kbfit1, đã test xe.

## 1. Sự thật đã đo (không tranh cãi lại)

- [ĐÃ ĐO] Cơ chế lỗi phím (QA178): app được host bị resize về kích thước suy từ pane (vd 397x685, 595x685) nhưng cửa sổ bàn phím lấy kích thước từ UIScreen.mainScreen = 414x736 của điện thoại → phím rộng/cao hơn cửa sổ app, qua scale 0,5 thì tràn và cụt hàng dưới. Keyplane, input mode, hwKB đều bình thường.
- [ĐÃ ĐO] QA179 fit (đặt frame cửa sổ phím = frame key window trong process app) chạy đúng khi bắt được cửa sổ: 5 applied, frame giữ ở +0,3s, view phím layout lại đúng bề ngang, dải neo đáy app. Nhưng 11/28 lần đánh giá không có cửa sổ phím nào trong process tại thời điểm đánh giá (kể cả +0,3s; cả fallback UIKeyboardImpl cũng 0/31) → fit là vá triệu chứng, phụ thuộc vật thể xuất hiện đúng lúc.
- [CODE] Hợp đồng hình học hiện tại: DFSceneHost giữ scene ở logical = pane x 2 (công thức cứng trong DFHostedMapRenderSize.h, bỏ qua bundle), scale cố định 0,50 bằng transform không đồng nhất, căn giữa pane. Readback trên xe: actual {414,736} so với target {397,685} (Maps), {1190,685} (Waze) — actual khác target là CỐ Ý theo thiết kế hiện tại.
- [TĨNH — deb gốc DuoNavi 1.0.3-12, chỉ strings/tên hàm] Bản gốc: (a) tiêm dylib chính vào chính các app được host; (b) host bằng portal + CBBridgedUIAppView có updateSceneSettingsFrame — viết lại khung scene settings về hình học đích; (c) renderSizeForBundleID: — sổ kích thước render theo từng bundle; (d) kể cả vậy vẫn có lớp [DuoFaceKB] riêng trong process app, trong đó có sửa bề ngang phím theo kích thước tham chiếu (keyboardScreenReferenceSize / fixedKeyboardWidth). Suy luận [SUY]: app của bản gốc tự layout ở (gần) kích thước đích; lớp KB xử lý phần còn lại mà hình học không cứu được (cửa sổ phím vẫn bám màn điện thoại).
- [ĐÃ ĐO — selprobe QA179] keyboardScreenReferenceSize chỉ responds trên UIRemoteKeyboardWindow (i1c1); hai selector bề ngang còn lại không lớp nào có. Selector này không nằm trong danh sách cấm của test.
- Vùng đóng băng hiện hành: DFSceneHost.m (digest chốt), DFHostedMapRenderSize.h, cơ chế HUD/lease/handover (vừa đạt PASS trên xe ở QA178), cơ chế chạm trong app host (QA177 PASS phần gọi lại điều khiển; drag thanh chia đã sửa QA175).

## 2. Hai hướng

**Hướng 1 — tiếp tục vá phía app (giữ hợp đồng hình học):** QA180 như WO v2 (bắt theo sự kiện + thử lại + marker Waze + D-B), QA181 hook keyboardScreenReferenceSize. Ưu: rủi ro thấp từng bước, không đụng phần đang ổn. Nhược: gốc hình học còn nguyên — app vẫn layout ở 414x736 rồi bị nén; các triệu chứng khác của hợp đồng này (chạm lệch vùng, chữ/viền bị scale) vẫn còn đất sống; mỗi triệu chứng một vòng vá.

**Hướng 2 — đổi hợp đồng hình học (mở đóng băng):** cho scene của app chạy ở kích thước pane thật (bỏ công thức x2), transform scale về 1,0 — app tự layout ở kích thước đích như cách bản gốc chứng minh. Ưu: xử lý gốc cho phím + mọi triệu chứng scale khác. Nhược: rủi ro cao nhất dự án — DFSceneHost là lõi hosting, mọi app đang chạy trên hợp đồng cũ; có thể vỡ chạm/HUD/layout đã ổn; phải có đường lùi.

## 3. Phương án Muse đề xuất (phương án cuối cùng — chờ Spec phản biện)

Làm cả hai, theo thứ tự và có khóa an toàn:

1. **QA180 giữ nguyên WO v2** (đã duyệt về nội dung): bắt phím theo sự kiện + thử lại cho Maps, marker R1/R2 cho Waze, D-B ghi giá trị gốc keyboardScreenReferenceSize. Lý do giữ: rẻ, rủi ro thấp, và cả 3 sản phẩm đều cần ở MỌI tương lai (biết Waze chết ở đâu; có số đo giá trị gốc cho hook; fit vẫn là lưới an toàn trong giai đoạn chuyển đổi).
2. **QA181 — hình học pane-native SAU CỜ, từng app một:** thêm cờ thực nghiệm theo bundle trong plist (mẫu cờ QA176, vắng = TẮT). Bật cho riêng Maps trước: logical = kích thước pane thật, scale 1,0. Đo trên xe: scene readback actual == target, bàn phím, chạm trong app, layout Maps. Các app khác giữ hợp đồng cũ. Cờ tắt = quay về nguyên trạng, không cần hạ cấp bản.
3. **QA182 — quyết định mặc định:** nếu Maps đạt, mở rộng Waze/YouTube rồi cân nhắc bật mặc định. Phần phím còn lệch (nếu còn) mới xử lý bằng hook keyboardScreenReferenceSize — lúc đó đã có số đo giá trị gốc từ D-B của QA180 để thiết kế hook, và fit hiện tại giữ vai trò lưới an toàn cho tới khi hook chứng minh được trên xe.

Nguyên tắc xuyên suốt: mỗi bước có đường lùi bằng cờ hoặc bằng bản Sileo trước; không gọi gì là đã sửa trước verdict test xe; vùng HUD/lease/handover không đụng kể cả trong QA181 (chỉ DFSceneHost/DFHostedMapRenderSize thay đổi có kiểm soát).

## 4. Câu hỏi cho Spec

Q1. Đồng ý thứ tự QA180 (giữ WO) → QA181 (hình học sau cờ, Maps trước) → QA182 (mặc định + hook nếu cần) không? Nếu không, thứ tự nào và vì sao?
Q2. QA181 bật cờ cho Maps: tiêu chí đạt để mở rộng là gì (readback, phím mấy chu kỳ, chạm kiểm thế nào)?
Q3. Có nên gộp bước đo giá trị gốc keyboardScreenReferenceSize (D-B) vào QA180 như WO v2 mục G.3, hay tách riêng?
Q4. Rủi ro nào của Hướng 2 mà bản tham khảo này chưa nêu (đặc biệt: app layout ở pane dọc/hẹp bất thường, scene settings transaction, tương tác với cơ chế chạm scene-routed)?
Q5. Nếu QA181 Maps đạt nhưng Waze vẫn im lặng (relay không chạy), thứ tự ưu tiên giữa "truy vết Waze" và "mở rộng hình học" thế nào?
