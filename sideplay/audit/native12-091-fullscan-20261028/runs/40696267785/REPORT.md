# Native12 gốc ↔ DuoFace mới — TOÀN BỘ file và 1.385 method

**KẾT LUẬN: KHÔNG ĐẠT tương đồng Native12.**

Bản gốc: 2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad
Bản mới: e15b9b2c2da351a64a125f5057c6c6e0f6d44aefbcc73de8fe023b6c4d5ab741

## Kiểm kê bytecode
- Native12: 43 file, 8 Mach-O, 66 ObjC classes, 1385 ObjC methods.
- DuoFace mới: 34 file, 8 Mach-O.
- Tên selector gốc còn xuất hiện trong ít nhất một Mach-O mới: 309/1385 (chỉ dấu chữ, KHÔNG phải hàm tương đương).
- File trùng basename và toàn bộ bytes: 13. Tính năng giao diện KHÔNG tự đạt nhờ trùng logo.

## 25 cổng tương đồng — tất cả KHÔNG ĐẠT
| Nhóm | Method Native12 gốc | Kết quả |
|---|---:|---|
| CarPlay native scene/admission | 76 | **KHÔNG ĐẠT** |
| Khởi động splash logo ngang và thanh tiến trình | 32 | **KHÔNG ĐẠT** |
| Bộ chọn app cards/icon/Recent/paging | 82 | **KHÔNG ĐẠT** |
| Host app iPhone bình thường | 45 | **KHÔNG ĐẠT** |
| YouTube/video/audio phát không Safe Mode | 45 | **KHÔNG ĐẠT** |
| Hiển thị hai app thật độc lập | 78 | **KHÔNG ĐẠT** |
| Cảm ứng hai app, scroll, player control | 29 | **KHÔNG ĐẠT** |
| Chia màn và kéo tỷ lệ, nhớ tỷ lệ | 76 | **KHÔNG ĐẠT** |
| Hoán đổi trái-phải, giữ logo | 63 | **KHÔNG ĐẠT** |
| Phóng to một ô, hoàn tác | 85 | **KHÔNG ĐẠT** |
| Phóng to thật sự ẩn Dock, hoàn tác | 76 | **KHÔNG ĐẠT** |
| Tám layout, chế độ đa khung Native12 | 127 | **KHÔNG ĐẠT** |
| Thay app slot/close/restore/atomic state | 124 | **KHÔNG ĐẠT** |
| Đúng vị trí/timer/hitbox của các pill | 36 | **KHÔNG ĐẠT** |
| Viền đỏ khi chạm và tự ẩn | 76 | **KHÔNG ĐẠT** |
| Logo, icon, màu sắc, bo góc và hiệu ứng | 98 | **KHÔNG ĐẠT** |
| Về CarPlay Home ẩn thanh/menu tức thì | 76 | **KHÔNG ĐẠT** |
| Reconnect, exitmode, SpringBoard stability | 112 | **KHÔNG ĐẠT** |
| Dock và geometry nhiều màn CarPlay | 76 | **KHÔNG ĐẠT** |
| Audio focus và playback video | 29 | **KHÔNG ĐẠT** |
| Bong bóng HUD8 4 nguồn/tự ẩn | 45 | **KHÔNG ĐẠT** |
| Trợ lý nói chuyện/voice mic | 84 | **KHÔNG ĐẠT** |
| Cài đặt app iPhone/preferences | 93 | **KHÔNG ĐẠT** |
| Đồng bộ SpringBoard/CarPlay/app process | 114 | **KHÔNG ĐẠT** |
| Injection filters/entitlement lifecycle | 112 | **KHÔNG ĐẠT** |

## Các tệp kết quả
- FILE_INVENTORY.json: đầy đủ từng file, SHA-256, Info.plist, tweak filters, ảnh byte-identical.
- ALL_NATIVE12_1385_METHODS.json: đầy đủ selector, type encoding, IMP, lớp, binary và tên nào có mặt trên binary mới.
- CLASSES_AND_NEW_MACHO.json: đủ lớp gốc, mọi Mach-O mới.
- FEATURE_GATES.json: 25 chức năng chưa chứng minh parity.
- SUMMARY.json: thống kê và NO-GO.

**Không có DuoNavi.** Không đánh dấu PASS bằng cách so chữ tên hàm. Phải chứng minh callback/receiver/ABI/scene lifecycle và kiểm tra trên xe. Không copy/bypass license bên thứ ba.

Ghi chú: 2.509 function starts của original bao gồm hàm C, optimized objc stubs; không được hiểu 1.385 ObjC methods là mọi function trong mọi binary.
