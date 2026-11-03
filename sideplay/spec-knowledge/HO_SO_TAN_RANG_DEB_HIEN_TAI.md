# HỒ SƠ TẬN RĂNG — DEB HIỆN TẠI (QA185, từ chính binary đã đóng gói)

Phương pháp: disassembly cả 10 dylib (llvm-objdump-18), trích đăng ký hook,
đối chiếu chuỗi/selector trong binary thô với source. Lưu ý công cụ: với
binary của ta, chú thích cfstring của objdump không hiện đủ — kiểm chứng
bằng grep trên byte thô là chuẩn đáng tin (đã áp dụng).

## 1. Cơ chế hook của ta — khác hẳn gốc, và thưa hơn nhiều
- Import tĩnh MSHookMessageEx: CHỈ DFV1APreflight có (2 call). Không dylib
  nào import tĩnh MSHookFunction.
- `method_setImplementation` trực tiếp: 5 điểm trong toàn bộ sản phẩm
  (relay 1, GOFA speed 2, probe 1, YouTube relay 1).
- Phần còn lại: hook được cài qua con trỏ **dlsym-resolved** — 6 dylib tự
  tra "MSHookMessageEx"/"MSHookFunction" lúc chạy (relay, probe, dock
  owner, first-party admission, YouTube relay, V1A). Toàn bộ lớp phím
  QA181–183 trong relay đi đường này (binary xác nhận các selector:
  setKeyboardName:, traitsWithScreen:orientation:,
  keyboardScreenReferenceSize, GSEventIsHardwareKeyboardAttached).
- Hệ quả so sánh: gốc có 486 đăng ký hook TĨNH trích được trọn vẹn từ một
  constructor; của ta không tồn tại một bảng tương đương — hook nằm rải
  theo tính năng, cài qua helper + dlsym, và tổng số điểm hook ít hơn
  theo cấp độ (hàng chục so với 486).

## 2. Đối chiếu binary ↔ source (QA185)
- Probe chứa `DestSize185` ×5 (hợp đồng render theo kích thước đích đã vào
  đúng binary giao), `updateSettingsWithBlock` ×2 (đường settings của
  DFSceneHost nằm trong probe như source mô tả).
- `setDeactivationReasons` VẮNG trong probe — xác nhận từ binary: giao
  dịch settings của QA185 frame-only, đúng thiết kế QA127.
  (`setIdleModeEnabled`/`setForeground` mỗi cái xuất hiện 1 lần ở nơi khác
  trong probe — không thuộc block frame của DFSceneHost theo source.)
- Kênh Darwin của ta (từ binary probe): họ `com.duoface.nativehost.*`
  (app/disconnect/dockzoom.command+ack/layout.changed/owner/picker/
  enabled) + `com.duoface.ipc.v176.kbdiag`, `v177.apptouch`,
  `apptouch177.wake` — nhiều kênh theo tính năng, mỗi kênh một cặp
  command/ack hoặc mailbox một ô (DF156). Gốc: NSDistributedNotification
  + 1 file state dùng chung + prefs dùng chung.

## 3. Những gì binary xác nhận về kiến trúc của ta
- 10 dylib chuyên biệt theo process/tính năng (probe/SpringBoard, dock
  owner/CarPlay, relay/14 app, GOFA ×2, YouTube, admission, coordinator,
  bridge QA, V1A dormant) + app host với template scene delegate riêng.
- Không có: portal/capture, hook tĩnh diện rộng (phím/dock/media/scene
  getters), settings một file hợp nhất, DB, sleep assertion, kênh lệnh
  có lease cho fullscreen (zoom của ta là dock-zoom coordinator với
  command/ack file — không lease, không snapshot khôi phục).
