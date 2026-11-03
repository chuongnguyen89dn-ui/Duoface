# QA178 — SO SÁNH DUONAVI GỐC vs DUOFACE: HOST APP KHÔNG HỖ TRỢ CARPLAY, BÀN PHÍM, HUD

Ngày: 2026-11-03. Mục đích: đối chiếu trước khi sửa bàn phím và HUD ở QA178.
Nhãn bằng chứng: [TĨNH] = strings/cấu trúc gói deb gốc (read-only); [CODE] = source DuoFace QA177;
[LOG] = log máy thật QA176/QA177; [SUY] = suy luận từ các bằng chứng trên, chưa kiểm chứng độc lập.

## 0. Nguồn và giới hạn

- Bản gốc: `com.duonavi.app_1.0.3-12_border-focus-red3` — đọc strings từ 3 dylib + app DuoFaceUI, read-only.
- Phía ta: source nhánh QA177 + verdict log 02–03/11.
- Các file DuoNaviObserver trên repo là observer thụ động của chính dự án này (đo ABI của CarPlay/SpringBoard),
  KHÔNG chứa hành vi runtime của bản gốc — không dùng làm bằng chứng về bản gốc.
- Đây là đối chiếu cơ chế/hành vi quan sát được từ strings và cấu trúc gói, không sao chép code của bản gốc.

## 1. Kiến trúc tổng thể — khác nhau từ gốc

| | DuoNavi gốc [TĨNH] | DuoFace (ta) [CODE] |
|---|---|---|
| Số dylib | 3 (Dashboard 7,5MB + FullscreenBridge + VisualHook) + app DuoFaceUI | 10 dylib + app host |
| Mã chính nằm ở đâu | **DuoFaceDashboard.dylib tiêm thẳng vào CÁC APP ĐƯỢC HOST** (YouTube, YT Music, Netflix, VLC, Safari, Twitch, TikTok, Maps, Waze, Spotify, Chrome, Notes, Phone, Music, Settings…) **và** vào SpringBoard/CarPlay | Mã host nằm ở SpringBoard (Chrome + DFSceneHost); phía app chỉ có relay mỏng (DF155 cho 14 app, relay riêng cho YouTube/GOFA) chủ yếu để **báo trạng thái** |
| Hệ quả | Code của họ chạy **cùng process với app và bàn phím của app** → can thiệp trực tiếp được vào cửa sổ/phím của app | Mọi can thiệp vào app đều phải đi vòng qua scene từ xa + mailbox/Darwin → chậm, gián tiếp, và có việc làm không được (xem mục 3) |

## 2. Đưa app không hỗ trợ lên màn hình CarPlay

**Họ — cơ chế "portal" + ép khung scene [TĨNH]:**
- Có lớp `CBBridgedPortalAppView` / `portalView`, tính năng đặt tên "Mirror Screen (Portal)":
  view dạng portal phản chiếu nội dung app lên phía CarPlay.
- Có `CBBridgedUIAppView` với đường **`updateSceneSettingsFrame`** — họ **ghi lại khung/kích thước
  trong scene settings của app được host** về phía hình học đích, qua scene handle.
- Có `renderSizeForBundleID:` — kích thước render được quản lý **theo từng bundle**;
  `CBWindow` đọc "live screen bounds" và `carPlayScreenScale` của màn CarPlay.
- FullscreenBridge (phía CarPlay/SpringBoard) giữ sổ hình học riêng: `contentFrame`, `windowFrame`,
  `appViewFrame`, `managerFrame`, `renderSize` — và có chuỗi log
  **"content geometry did not match CarPlay display"**: họ chủ động kiểm tra hình học nội dung
  có khớp màn hình CarPlay không.
- Kết luận cơ chế [SUY, bám sát các điểm trên]: app được host **tự layout ở kích thước đích**
  (hoặc rất gần), portal chỉ là đường hiển thị. App không bị giữ ở kích thước điện thoại rồi nén lại.

**Ta — remote scene + kích thước logical + transform [CODE/LOG]:**
- `DFSceneHost.layoutScene`: view của scene được đặt frame = **kích thước logical cố định theo bundle**
  (ví dụ 414x736 qua `DFHostedLogicalSizeForBundle`), rồi **scale bằng CGAffineTransform không đồng nhất**
  ép vào pane, canh giữa. Comment trong code: "Scale the existing UIKit scene immediately and
  leave the remote player intact."
- Commit FBScene dùng kích thước pane làm tham chiếu, nhưng khung client của app vẫn ở logical —
  log đọc ngược cho thấy actual {414,736} ≠ target {397,685} **theo thiết kế** [LOG QA176].
- Hệ quả phụ đã biết: vùng letterbox chết (chạm không tới), kéo divider bị giật (đã đỡ ở QA175),
  và lỗi bàn phím ở mục 3.

## 3. Bàn phím — họ "thể hiện" thế nào, ta vì sao lỗi

**Họ có một lớp bàn phím chuyên dụng, chạy TRONG process app [TĨNH]** — thẻ log `[DuoFaceKB]`,
5 nhóm can thiệp (đều là hook vào UIKit của chính app được host):
1. **Tắt tín hiệu bàn phím cứng ảo**: `GSEventIsHardwareKeyboardAttached` và
   `BKSHIDServicesIsHardwareKeyboardAttached` đều bị ép trả NO ("called -> forcing NO") —
   trạng thái hardware-keyboard mode là thứ làm bàn phím mềm bị thu gọn/mất hàng.
2. **Theo dõi UIKeyboardImpl**: chặn `setDelegate`, ép input mode dự phòng khi cần,
   ghi trạng thái `showKeyboard` (inHWMode/autoMin).
3. **Sửa tên bàn phím (keyboardName)**: sửa nil/(null) và bổ sung prefix còn thiếu trong
   `setKeyboardName:` / `setKeyboardName:appearance:` của UIKeyboardLayoutStar.
4. **Sửa keyplane**: khi keyplane là nil lúc hiện phím → kích hoạt bàn phím + keyplane dự phòng;
   sửa keyplaneName nil/null về **"letters"**; ghi lại mọi `setKeyplaneName:`.
   (Keyplane quyết định mặt phím nào được dựng — sai/trống keyplane là ứng viên số một cho triệu chứng mất hàng phím dưới.)
5. **Sửa bề rộng**: thuộc tính `fixedKeyboardWidth`, hook `keyboardWidthForScreen:withOrientation:`,
   `setKeyboardWidth:`, `keyboardScreenReferenceSize` — bề rộng phím được tính theo **kích thước
   tham chiếu của màn đích**, không theo khung điện thoại của app.
   Kèm theo: theo dõi UIRemoteKeyboardWindow/UITextEffectsWindow (hidden/alpha/frame) và dump cây view để chẩn đoán.

**Ta [CODE/LOG]:**
- **Không có lớp bàn phím nào cả.** Relay phía app chỉ *ghi log* (kbdiag QA176/QA177, theo đúng work order chỉ-log);
  test hợp đồng còn cấm relay gọi `setKeyplaneName`/`setKeyboardWidth`. Không hook tín hiệu bàn phím cứng,
  không sửa keyplane, không sửa bề rộng.
- Bàn phím của app được dựng **trong không gian logical 414x736** rồi bị transform nén cùng toàn bộ scene:
  bề rộng hiển thị ≈ 414 × hệ số scale ngang (≈0,65 với pane 270pt) ≈ 270pt trên màn 640pt ≈ 42%
  (khớp ảnh chụp ~45% ngày 02/11); chiều cao bị nén theo hệ số ≈0,47 và neo đáy trong không
 gian 736 → hàng phím dưới (space/enter) bị cắt [LOG QA176/QA177 + ảnh máy].
- Đo trên máy: hwKB=0, input mode Telex bình thường [LOG] — nên ở máy của ta, nguyên nhân chính
  đã chứng minh là **hợp đồng hình học**, còn keyplane **chưa đo được** (kbdiag 2 vòng vẫn
  kbClass=none ngay cả ở DidShow) → không được khẳng định keyplane của ta đang sai, chỉ biết
  ta không có gì bảo vệ khi nó sai.

**Vì sao ta mắc lỗi — 3 nguyên nhân gốc:**
1. **Đặt mã sai process**: việc sửa phím phải làm trong process của app (nơi UIKit dựng phím);
   kiến trúc của ta để relay phía app quá mỏng (chỉ báo trạng thái), còn mã chính ở SpringBoard
   với scene từ xa — ngoài tầm với của cửa sổ bàn phím.
2. **Hợp đồng hình học logical + scale**: giữ app ở 414x736 rồi nén hình — mọi thành phần neo
   theo khung app (bàn phím là điển hình) đều sai tỉ lệ theo. Bản gốc ép khung scene về đích
   nên app tự layout đúng, kể cả phím.
3. **Thiếu hẳn lớp thích ứng CarPlay cho bàn phím**: kể cả khi hình học đúng, môi trường CarPlay
   vẫn có các bệnh riêng (tín hiệu bàn phím cứng ảo, keyplane/name trống) mà bản gốc đã phải
   xử lý bằng 5 nhóm can thiệp trên; ta không có nhóm nào.

## 4. HUD tốc độ — khác biệt cấu trúc

- Gói DuoNavi gốc này **không có HUD bong bóng tốc độ kiểu của ta** [TĨNH]: không có
  chuỗi/cơ chế presenter tốc độ riêng trong DuoFaceDashboard.dylib. Bong bóng tốc độ là
  thành phần do dự án này tự thêm (dòng Speed8), nên bài toán "nhiều presenter tranh nhau"
  **là của riêng ta**, bản gốc không "giải" nó — họ không có nó.
- Ta có 3 presenter ở 2 process (Chrome/SpringBoard, DF144-SB/SpringBoard, overlay163/CarPlay)
  → phải có lease (QA176) và chuyển giao lúc thoát phiên (QA177) — và log 03/11 chứng minh
  chuyển giao QA177 **không khởi động lần nào**, khe chớp khi thoát app host còn nguyên [LOG].
- Điểm cấu trúc đáng học: phía bản gốc, UI của họ sống trong process CarPlay/dashboard —
  không gắn với vòng đời "phiên host app" kiểu Chrome của ta (mở phiên thì dựng cửa sổ,
  đóng phiên thì giấu tất cả cùng lúc) → không có khoảnh khắc "mọi thứ tắt cùng lúc rồi
  bên khác bám lại sau" [SUY từ cấu trúc gói + cơ chế portal].

## 5. Đầu vào cho QA178 (chưa phải work order)

- **Bàn phím — hai hướng, phải chọn/pha:**
  (a) Đổi hợp đồng hình học: cho scene về kích thước pane thật thay vì logical + scale.
  Đúng gốc rễ nhất (khớp cách bản gốc ép scene settings frame) nhưng rủi ro cao nhất —
  DFSceneHost đang bị đóng băng theo digest, và QA175 vừa ổn định cơ chế commit hiện tại.
  (b) Giữ hình học, thêm **lớp bàn phím phía app** vào relay theo đúng 5 nhóm hành vi ở mục 3
  (ép NO cho tín hiệu bàn phím cứng, bảo vệ keyplane/name, tính lại bề rộng phím theo khung đích).
  Ít rủi ro hơn cho scene, nhưng bề rộng phím vẫn phải "đấu" với transform scale của scene —
  cần tính hệ số scale vào bề rộng đích.
  Có thể làm (b) trước, đo lại bằng kbdiag, rồi mới quyết (a).
- **HUD**: QA178 phải (i) ghi log vô điều kiện trạng thái HUD/lease tại thời điểm stop để
  biết cổng nào chặn handover, và (ii) phát tín hiệu Retiring **sớm hơn** (ngay khi có tín hiệu
  kết thúc phiên, trước khi giấu cửa sổ), hoặc giữ HUD bằng chính presenter phía CarPlay
  trong suốt chuyển đổi thoát app host.
- Điều kiện tiên quyết giữ nguyên: không gọi gì là đã sửa trước test máy; decoder GOFA vẫn shadow;
  tốc độ bong bóng vẫn GPS.
