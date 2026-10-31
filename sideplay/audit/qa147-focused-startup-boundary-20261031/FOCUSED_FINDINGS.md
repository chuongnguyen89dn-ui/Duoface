# Khoanh đúng lỗi QA147: kích thước host, startup và ACK Dock/Home

Ngày2026-10-31. Phạm vi theo yêu cầu mới: chỉ các mắt xích liên quan lỗi giao diện sai chiều, mở app chậm/lỗi, Dock không nhận app và Home sai đích. Đây là điều tra, chưa sửa production, chưa có DEB/Sileo mới hay kiểm thử thiết bị mới.

Nguồn: Log23 SHA256 `c327274898d8d7285259d4bdbfc04b623a81e3cb6263ccda7ccf948d9cca267d`; source head `3d5046614dc82c1ff04a04c175ff146cd607c3ef`, DFSceneHost.m blob `ec2924c145be4edaaa27b7320bb869b18de12c6b`; dylib gốc SHA256 `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`.

## 1. Có lỗi hình dạng vùng host thực sự, không chỉ suy từ orientation

Trong26 request QA147,24 có resize đầu tiên cùng kích thước yêu cầu; **2 request có width/height bị đảo ngay tại host**:

| Request | App | Vùng CarPlay yêu cầu | Host resize đầu tiên |
|---|---|---|---|
| 07D0259B-BF77-4072-8105-02E96679C3CF | YouTube | 595 ×331.333 | 331.333 ×595 |
| F1ADEC5E-3D54-436F-8261-784AE56424E3 | Facebook | 595 ×331.333 | 331.333 ×595 |

Ca YouTube có đường chứng cứ rõ:

| Sau request | Sự kiện |
|---|---|
| 0.054s | Host resize331.333×595, mặc dù request595×331.333 |
| 0.214s | Hoàn tất checkpointmode-2-requested, vẫn bounds dọc331.333×595 |
| 0.218s | Host ghi scene-handle-observed, vẫn bounds dọc |
| 0.519s | geometry-before-reference-setters nhận kích thước dọc |
| 0.527s | Yêu cầu geometry target663×1190 được ghi nhận |
| 0.529s | Commit viewport dọc331.333×595 được ghi nhận |
| 1.105s | App-side ACK phaseapp-reflow-measured, orientation/client/server1, split0, mismatch0 |

Đây là bằng chứng kích thước đầu vào sai hình dạng đã đi tới commit và có phản hồi phía app. Không cần đổi orientation thành landscape để giải thích ca này: orientation1 vẫn có thể đúng hợp đồng gốc nhưng width/height đã bị đảo. Công thức2× hiện tại cho ra663×1190 từ bounds dọc; công thức không tự sửa được đầu vào sai. Không có bằng chứng pixel/touch cuối cùng hoặc post-commit FBScene frame để tuyên bố tất cả đã đúng/sai như nhau.

Chỗ cần tìm writer thu hẹp vào khoảng **request ContentRect -> gắn surface/start -> bounds mà layoutScene đọc**. Log không ghi rootWindow/root.view frame tại từng bước, nên chưa xác định UIKit hay thao tác nào đã đổi bounds. Không khẳng định rootWindow chắc chắn bị đổi chỉ từ surface bounds.

Ca này đồng thời có host observation và app reflow ACK, nhưng không có standalone-ready ACK hay Dock-active. Vì vậy lỗi kích thước và lỗi ACK là hai biên cần xử lý riêng; không được kết luận mọi thiếu Dock đều do host chưa từng hoạt động.

## 2. Khoanh 8 lỗi bogus-reference-size bằng timeline thật

Cả8 lỗi attach đều có thứ tự:

`host-created -> media-viewport-ui-only -> resize -> scene-failed: Scene attach exception: bogus reference size -> teardown`

Không request lỗi nào có checkpointmode-2-requested, scene-ready observation hoặc geometry-before-reference-setters trong cùng vòng đời. Log23 xác nhận chúng tập trung ở Facebook4, ChatGPT3, Gemini1.

Điều này khoanh vùng phần startup trước khi hoàn tất checkpointmode2, thay vì tiếp tục quy lỗi cho bộ setter reference-size muộn sauready. Nhưng eventmode-2-requested được ghi SAU beginAppearance, setRequestedMode, didMove và endAppearance; thiếu event không chứng minh setRequestedMode chưa được gọi. Resize có thể xảy ra reentrant bên trong addSubview. **Chưa có stack/operation marker để nêu chính xác lệnh Apple đã ném exception.**

Ca Facebook bị đảo bounds chỉ là1/8 lỗi;7 ca còn lại vẫn resize ngang nhưng cũng lỗi. Do đó đảo width/height không phải điều kiện cần để có bogus reference size, và chưa thể coi đó là nguyên nhân duy nhất.

## 3. Chỉ đối chiếu thứ tự gốc liên quan startup

Các điểm dưới đây đã được kiểm tra trực tiếp trên đúng dylib gốc; selector có guard được hiểu là chạy khi ABI hỗ trợ.

| Bước | Gốc CBBridgedUIAppView | Mã hiện tại |
|---|---|---|
| Chuẩn bị lifecycle | Cờ occlusion/lifecycleae228/ae254 trước lấy hosted viewae2d8 | Factory đã loadViewIfNeeded; start gắn appView rồi mới đặt cờ |
| Mode2 | ae310, trước gắn hosted view vào wrapper/surface | Đặt sau addSubview và layoutScene |
| Frame trước mount | Lấy bounds wrapperae414, đặt native host view.frameae424 rồi mới addSubviewae44c/ae464 | addSubview trước, layoutScene đặt frame2× và transform sau |
| Reference setters | ae61c/ae658/ae690, SAU mount, trước didMoveae9c8 | Chờready và timer300ms |
| Ổn định cửa sổ khi show | Sau hosted start, window.show gọi resizeWindowsb2834; cập nhật root/content theo policy đã xác minh | Standalone đặt window/root trước gắn surface, sau mount ghi pending; chưa có bước tương đương resize lại container theo ContentRect đã nhận |

**Không suy diễn rằng gốc đặt mọi reference setter trước mount.** Chỉ19 fact liên quan được thêm trong RELEVANT_ORIGINAL_ORDER.json. Original root controller cũng dùng UIViewController (dyld classref3aab48), giống đối tượng cơ sở của standalone hiện tại; chưa có căn cứ đổ lỗi cho thiếu một custom root-controller rotation override.

Thứ tự khác là ứng viên có cơ sở để sửa/đo startup; chưa phải bằng chứng một thao tác riêng lẻ gây mọi lỗi.

## 4. Biên ACK liên quan trực tiếp Dock/Home

Ca YouTube trên vẫn thiếu standalone-ready trong khi có app reflow. Toàn phiên có16 host observations nhưng0 standalone-ready và0 Dock-active. Source đã chứng minh QA147 chỉ cập nhật native Dock và Home displayState0 khi nhận đúng hosted-outcome cùng VerifiedPID. Original bounded manager route publish trạng thái saustart/show, không đọc ACK tùy biến này tại biên đó (xem audit manager-window trước).

Log23 không có dump SBApplication capability/PID và không có log từng nhánh từ chối trong sceneReady. Vì vậy chưa thể phân biệt PID chưa có, ABI getter không phù hợp, window/owner/bundle mismatch hay nhánh khác. Một lần đọc PID thất bại không có readiness retry; đây vẫn là giả thuyết cấu trúc, không phải nguyên nhân đã đo.

Home sai đích phù hợp với việc chưa cập nhật trạng thái native in-app, nhưng chưa có trace quyết định navigation bên Apple. Không thay thế điều tra bằng việc chỉ chặn/forward Home: gốc cũng forward Home như các checkpoint trước đã ghi rõ.

## Bước thực thi chỉ giới hạn ở các biên này

1. Startup: đo marker quanh addSubview, cờ lifecycle, layout, beginAppearance, mode2, didMove, endAppearance; giữ exact request/generation và nhận diện reentrancy.
2. Geometry: ghi ContentRect, rootWindow frame/bounds, root.view frame/bounds, surface frame/bounds trước/sau mount và trước commit. Bảo toàn hình dạng vùng CarPlay đã nhận; phân biệt orientation1 với việc width/height bị đảo. Đối chiếu bước show/resize của gốc.
3. ACK: ghi từng guard của sceneReady và kết quả ABI/PID thật; tách manager activation khỏi scene/PID observations theo contract đã lưu. Ngăn ghi pending sau một launch đã fail/hoàn tất.

Các phép đo này nhằm xác định một thay đổi có căn cứ, không mở rộng sang chức năng khác. Chưa có build mới được phát hành chỉ để lặp lại triệu chứng.

## Tái lập

```bash
python analyze_focused_boundary.py --log /path/to/DuoFaceAudit23.txt --repo /path/to/Duoface > FOCUSED_LOG23_EVIDENCE.json
python verify_relevant_original_order.py --binary /path/to/DuoNaviDashboard.dylib --parser /path/to/audit_native12_license_class_xrefs.py > RELEVANT_ORIGINAL_ORDER.json
```

Python/capstone5.0.7; metadata parser dùng chung ở recovery branch như các audit trước. Script pin SHA; scene event không mang requestID nên ghép bằng bundle+UTC trong cửa sổ request không chồng nhau và kiểm tra đúng1host-created/request. Output không chứa toàn bộ disassembly hay logic thương mại.
