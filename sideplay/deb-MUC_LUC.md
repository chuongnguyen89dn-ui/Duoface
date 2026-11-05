# Thư viện hồ sơ deb gốc — mục lục

Lập ngày 05/11/2026 theo lệnh của Nguyen: quét tận gốc từng deb (từ a đến z, từng hàm một), mỗi deb một mục riêng trong `sideplay/`, để sau này tra cứu không phải quét lại.

Phương pháp: quét tĩnh CHỈ ĐỌC (bóc gói, cây file, bảng class/method, điểm hook, chuỗi, cơ chế). Không chạy bất kỳ binary/script nào trích từ deb. Chỗ không đọc được đều ghi ở mục "CHƯA XÁC ĐỊNH ĐƯỢC" cuối mỗi hồ sơ.

## Các hồ sơ đã có

| Thư mục | Gói (theo control của chính gói) | Nguồn quét | Quy mô |
|---|---|---|---|
| `deb-duonavi-1.0.3-12/` | `com.duonavi.app` 1.0.3-12 (lõi DuoFaceDashboard + app DuoFaceUI) | File .deb gốc trên máy, SHA256 `3e32825c…35915` | 10.262 dòng |
| `deb-duoface-1.0.4-5/` | `com.duoface.voice104.test` 1.0.4-5~duofacetest | File .deb gốc trên máy, SHA256 `d78ad0f3…29f6` | 8.110 dòng |
| `deb-duoface-goc/` | Gói DuoFace gốc — control đã mất cùng file .deb gốc nên không khẳng định được Package/Version; app tự khai 1.0.0; nhãn "1.0.4-1" là nhãn chủ dự án gán | Cây rootfs đã bóc sẵn (sweep-original), đối chiếu repo | 3.685 dòng; 243 điểm hook giải từ disassembly constructor |
| `deb-sideplay-1.0.4-1/` | `com.sideplay` 1.0.4-1 — gói ĐỘC LẬP, chính là nội dung của thư mục `extracted-1.0.4-1` bấy lâu nay | Cây extracted trong repo; 139/139 file khớp SHA bản kiểm kê gốc (SHA256 của .deb theo kiểm kê: `7f8520b9…`) | 2.315 dòng |
| `deb-omnicar-1.0.3/` | `com.anlai.omnicar` 1.0.3 | File .deb trên máy, SHA256 `d9297b01…9fd` (khớp SHA công bố trong repo Omnicar) | 14.286 dòng |
| `deb-duodash-repack/` | `com.duoface.independent` 0.1.0~native12+speed8compact — gói repack/recovery của dự án, KHÔNG phải DuoDash chính hãng (xem dưới) | File .deb trong repo, nhánh `feature/visual12-duodash-recovery`, SHA256 `2fe8892c…8ad` | 3.169 dòng |

## Hai kết luận định danh quan trọng

1. **Thư mục `extracted-1.0.4-1` là của SidePlay** (`com.sideplay`), không phải DuoFace. Hai gói "1.0.4-1" là hai sản phẩm khác nhau.
2. **Không có deb DuoDash chính hãng** (SenseTechLab, Chariz 1.1.6) ở bất kỳ đâu trong máy hay repo. Gói mang tên duodash-recovery trong repo là repack của DuoFace gốc: 33/37 file giống hệt từng byte, 3 binary khác chỉ ở mức đóng gói lại (fat → thin) với bộ class/method giống 100%, cộng 3 dylib thêm (LogoGripOnly, SpeedHUD, SpeedOwner). Hồ sơ của nó nằm ở `deb-duodash-repack/` dưới đúng tên thật.

## Chưa có hồ sơ — thiếu nguồn

- **CarPlayPro Speed 0.9.97** (SpeedAlerts.dylib): file .deb gốc (SHA256 `e5b0918b…4102f`) và bản đã bóc đều đã mất khỏi máy (đã băm toàn bộ 1.114 file .deb trên máy, không file nào khớp). Cần gửi lại file .deb để quét.
- **DuoDash chính hãng** (SenseTechLab): chưa từng có file trong máy/repo. Cần file .deb để quét.
