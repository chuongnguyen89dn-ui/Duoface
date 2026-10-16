# DuoFace native12 — xác minh watchdog và hòa giải bộ hẹn 10 giây

**Ngày 16/10/2026.** Mục tiêu: hoàn thiện source nhóm Kết nối thông minh, **không đóng DEB**, không thay Sileo. Tham chiếu cả tiep tuc du an.md, ban giao du an duoface moi.md và checkpoint Smart Connection.

## Mốc và nguồn bất biến

- Repo: chuongnguyen89dn-ui/Duoface. Source branch: feature/duoface-exact-payload-migration.
- Baseline: com.duoface.independent 0.1.0~native12, SHA256 85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7. Giữ nguyên trên máy. License cleanup PAUSED.
- Script read-only: migration/full_payload/native_test/audit_native12_disconnect_watchdog.py, commit d86d50f8938de39be7abddd5a4c33b3894d4459c; CI .github/workflows/duoface-native12-disconnect-watchdog-audit.yml, commit 6174aca302fe7b7dd0201c8b9eca12697477216e.
- GitHub Actions run 38843235798 **SUCCESS**; output feature:audit/payload-migration/NATIVE12_DISCONNECT_WATCHDOG_READONLY.json blob SHA 96816976071b825d54cead783ad690147adb62cb, đã fetch/readback.
- Parser disassemble arm64 11 entrypoints trong CBBridgeManager; không sửa DEB, không chạy trên iPhone, không chứng minh live dispatch.

## Kết luận mã máy gốc — vì sao cần kiểm tra ngay

| Method native12 | VM arm64 | Bằng chứng |
|---|---|---|
| scheduleMandatoryDisconnectWatchdog | 0x1b9420 | Có bộ hẹn riêng: tăng token ở 0x1b9518–0x1b9528, tính thời gian ở 0x1b9500–0x1b9520, hằng số float **60.0** ở 0x1b9508 được dùng làm giới hạn lựa chọn, 0x1b9618 gọi dịch vụ thời gian, 0x1b966c đăng ký block ở 0x1cce0c. Không phải hằng 10 giây, thời gian thực phụ thuộc dữ liệu runtime. |
| cancelMandatoryDisconnectWatchdog | 0x1cce6c | Tăng token ở 0x1cce7c–0x1cce90 để vô hiệu tác vụ cũ. |
| enforceMandatoryDisconnectKill | 0x1cceac | Có nhánh xử lý trạng thái màn và app, tại 0x1cd664 nạp **signal 9** rồi gọi external routine tại 0x1cd668. Chưa resolve tên symbol imported, không khẳng định chắc lệnh POSIX cụ thể. |
| handleScreenDidDisconnect: | 0x1b82e0 | Đầu vào ngắt màn native12. |
| handleCarPlayConnectionChanged: | 0x1b8a1c | Đầu vào trạng thái CarPlay gốc; hook gọi original. |
| terminateApplicationWithBundleID: | 0x1cd780 | Đường đóng app theo bundle ID, được adapter mới gọi sau kiểm tra ownership. |

**Kết luận:** Để native mandatory watchdog và timer 10.000ms độc lập khi người dùng bật Close on Disconnect có nguy cơ đóng sớm/trễ/lặp hoặc kill rộng hơn app đã được DuoFace quản lý. Chỉ đổi hằng thời gian mới là chưa đủ.

## Mã đã sửa và kiểm thử thật

- Feature commit **45b2e7bf29cc867329dbed4f98ba3c50749992d3**, file runtime/connection/DFConnectionNativeHooks.xm: bổ sung hooks **scheduleMandatoryDisconnectWatchdog** và **enforceMandatoryDisconnectKill** trên đúng CBBridgeManager.
- Khi switch closeOnCarPlayDisconnect **ON**: hai nhánh mandatory scheduler và forced kill cũ **không gọi original**, chỉ bộ hẹn riêng 10 giây của DFConnectionPolicy + adapter xử lý session-owned apps, kiểm tra lại CarPlay và hủy khi reconnect.
- Khi switch **OFF**: gọi original cả hai để giữ **hành vi legacy của native12**. OFF không có nghĩa bảo đảm mọi xử lý đóng app cũ bị tắt; chỉ tắt *chính sách mới*. Không tự thay đổi cơ chế CarPlay/cleanup trước đây khi người dùng không bật tính năng.
- Kết nối mới: một nút Auto Start cũ, nhớ app cuối, chống open duplicate; iPhone settings thêm một switch Close on Disconnect (OFF mặc định). 10.000ms thay thế 12.000ms của thiết kế trước.
- **GitHub Actions run 38843479440 SUCCESS**, job 116788613850: Theos compile và link hook + iPhone Settings dylib arm64, log chính xác **SMART_CONNECTION_10S_NATIVE_LOGOS_LINK_PASS_NO_DEB** và **NO_DEB_NO_SILEO_NO_DEVICE_INSTALL**. Không make package. C++ 11 scenarios g++/clang++ PASS tại run 38843479456; iOS adapter object compile PASS run 38843479409. Bản native12 không đổi.

## Chưa được chứng minh và phải QA sau

- Đây là **source-wired + compile/link PASS**, CHƯA cài lên iPhone nên chưa xác nhận các hook thực sự chạy sau inject, Settings row hiện ra, shared preference đọc xuyên process hoặc bản nhị phân gốc không có đường kill app khác ngoài watchdog.
- Khi new Close ON, cần thử với một DuoFace-managed app, reconnect trước 10 giây, kiểm không đóng sớm/trùng, và việc ownership vẫn được ghi nhận ở giây thứ 10. Không ép kill ứng dụng phát media ngoài phạm vi DuoFace.
- Khi new Close OFF, hành vi mandatory cleanup cũ tiếp tục, điều này phải được giải thích chính xác nếu người dùng kỳ vọng OFF = không có loại đóng app nào.
- Lần build candidate DEB chỉ thực hiện khi user yêu cầu, không tự đổi native12/Sileo. Giữ native10 rollback và workstream xóa giấy phép tạm hoãn.
