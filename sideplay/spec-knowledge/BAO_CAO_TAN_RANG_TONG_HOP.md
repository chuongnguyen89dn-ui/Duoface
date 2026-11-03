# BÁO CÁO TẬN RĂNG — TỔNG HỢP ĐỌC THÂN HÀM DEB DUONAVI GỐC (1.0.3-12)

Ngày 2026-11-03. Tiếp nối báo cáo kiểm kê `BAO_CAO_QUET_AZ_DUONAVI_VS_QA185.md` + phụ lục. Tài liệu này là lớp sâu: đọc disassembly từng hàm chịu lực (llvm-objdump-18, 1.528.919 dòng cho dylib lõi), giải mã luồng gọi, hằng số, điều kiện rẽ nhánh. Hồ sơ chi tiết từng chuỗi nằm ở các file đi kèm: hình học, portal/split, vòng đời/trợ lý, và bản đồ hook.

## Độ bao phủ — nói thẳng
| Hạng mục | Tổng | Đã đọc thân hàm | Ghi chú |
|---|---|---|---|
| Đăng ký hook trong constructor Dashboard | 486 | 486 (trích toàn bộ) | 480 message hook/72 class + 6 function hook; IMP đối chiếu khớp đọc tay QA183 |
| Chuỗi hình học (CBWindow geometry + renderSize + settings writer + hook intercept) | ~15 hàm | 12 đầy đủ/cấu trúc, 3 một phần | còn: chiều nhân đôi theo hướng màn; điểm gọi IMP gốc trong helper |
| Portal/split (capture, touch, tra cứu loại app) | ~8 hàm | 5 | còn: điểm quyết định chọn portal theo bundle |
| Vòng đời (connect/disconnect/resume/assertion) | 6 hàm | 5 cấu trúc + 1 đầy đủ | watchdog ngắt kết nối chỉ ghi nhận tồn tại (gắn giấy phép) |
| Trợ lý (CBAssistantManager) | 69 method | cấu trúc cả class | không đọc thân từng lệnh thoại |
| Lớp phím (IMP các hook chính) | ~110 hook | bản đồ đầy đủ; thân hàm lõi đã đọc ở Bước 0 QA183 | chưa đọc lại toàn bộ 110 |
| Class UI phụ (slot/pill/overlay/dock monitor), app DuoFaceUI (522 method), FullscreenBridge (61) | ~700 method | kiểm kê (chưa đọc thân) | đuôi dài, giá trị chẩn đoán thấp |
| Giấy phép/đăng ký/helper optimizer | — | KHÔNG đọc thân | cố ý: chỉ ghi nhận tồn tại như các vòng trước |

## Những kết luận ở mức thân hàm (mới so với kiểm kê)

1. **Hình học là một hệ có cache + override + sàn an toàn.** Bounds lấy từ coordinateSpace của window scene CarPlay; usable = bounds trừ insets với sàn chấp nhận 100×100 và kẹp giữ tối thiểu ~64pt/chiều; insets và bounds đều có cache tĩnh (xóa bằng resetCachedBounds mỗi sự kiện nối/ngắt) và đều đọc được từ file override trên đĩa (file cấu trúc, khóa bounds/insets/pointScale). Render size là hàm của usable bounds × bố cục slot × loại app; nhánh split supersample ×2 **trên kích thước slot** (không phải ×2 màn điện thoại như hợp đồng cũ của ta), tỉ lệ chia mặc định 2.0, ngưỡng hợp lệ của kích thước lưu sẵn là 10pt.
2. **Ghi settings hai tầng.** Tầng một: updateSettingsWithBlock ghi frame + foreground + occluded + underLock + canShowWhileLocked + deactivationReasons + idleMode (qua setter nếu có, không thì ghi thẳng ivar). Tầng hai: hook `interceptUpdateForScene:withNewSettings:` trên SBSuspendedUnderLockManager — mỗi lần scene của app bridge sắp cập nhật, tính lại render size và ghi lại qua hàm phụ; đi cùng hai hook under-lock anh em trên cùng class.
3. **Họ hook cả chiều đọc trạng thái scene** (isOccluded, deactivationReasons, isUnderLock, canShowWhileLocked trên FBSSceneSettings/UIApplicationSceneSettings; _isSuspended, _isDeactivated trên UIWindowScene) — hệ thống hỏi gì cũng nhận câu trả lời "scene đang sống". Cộng với mục 2, đây là chiến lược giữ scene hai mặt: ghi đúng và đọc cũng đúng.
4. **Portal là remote ở tầng hệ thống:** app chạy nguyên trên màn điện thoại; hình lên xe bằng `__UICreateScreenUIImage` theo nhịp display link; chạm xuống bằng `IOHIDEventCreateDigitizerEvent`. Đường này né toàn bộ bệnh của host trực tiếp (phím/chạm/scene ngủ) với giá là app chiếm màn điện thoại.
5. **Vòng đời có kỷ luật file bền:** chống flap khi nối lại quá nhanh; khi ngắt — hủy các lệnh khôi phục đang chờ, lưu bundle khôi phục ra `/var/tmp/carbridge_autoresume_bid` rồi mới dọn; giữ PreventUserIdleSystemSleep suốt phiên. Phía ta thiếu cả bốn cơ chế này.
6. **Trợ lý là bộ điều khiển bằng giọng nói** (định tuyến lệnh mở app/nhạc/dẫn đường + phản hồi giọng nói + HUD riêng), không phải chatbot; quyền nhận dạng được cấp trước bằng ghi thẳng TCC.db (ghi nhận, rủi ro cao).
7. **Quy mô hook thật:** 480 message hook — cụm phím ~110 (UIKeyboardImpl một mình 40), icon/dock ~150, media (AVPlayer/PiP/route/volume) ~30, scene/settings ~25, cửa sổ/ứng dụng ~30. "Lớp thích ứng" của gốc dày hơn mọi ước lượng trước đây của dự án.

## Hệ quả cho phía ta (chỉ nêu, chờ quyết định — không tự build)
- QA185 (render ×1 theo pane) đúng hướng đích nhưng: (a) thiếu supersample ×2 trên slot cho split — cần kiểm chứng nét chữ khi có máy; (b) usable của ta chưa tách khỏi bounds theo insets có sàn an toàn; (c) host của ta chưa ghi deactivationReasons/idleMode và chưa có tầng hook đọc trạng thái — ứng viên cho lỗi scene đóng băng.
- Portal là quyết định kiến trúc riêng nếu muốn né hẳn họ bệnh host-trực-tiếp; không phải một vòng vá.
- Vòng đời: bốn cơ chế ở mục 5 là các ứng viên cụ thể, độc lập với hình học.

## Giới hạn
Đọc tĩnh không thay kiểm chứng máy thật; các kết luận "ứng viên" phải gặp log xe mới thành nguyên nhân. Phần giấy phép/optimizer/TCC giữ nguyên trạng ghi nhận.
