## Checkpoint hiện hành — 2026-10-27 (.73 crash, tra cứu .37)

- Người dùng báo giao diện ứng dụng vẫn bó và SpringBoard crash ngay sau mốc `9f830a97`. Đây là FAIL thiết bị; chưa có IPS tương ứng để chỉ ra riêng lệnh gây crash.
- Đã khôi phục provenance thật của **DEB 0.0.37** (run `39748923126`, SHA256 `2b6f274e684e5a6f1008dac960c87ff51744fddb5342ce42fcd74e5c61314beb`) và đối chiếu 0.0.73; **chưa phát hành lại hoặc sửa runtime**.
- Đọc báo cáo đã bổ sung: [V37_NOT_FULLY_RESTORED_ROOT_DIFF_20261026.md](audit/native12-039-regressions-20261023/V37_NOT_FULLY_RESTORED_ROOT_DIFF_20261026.md), checkpoint commit [4ceb963](https://github.com/chuongnguyen89dn-ui/Duoface/commit/4ceb96396718a88141c09153392dbb4d6624bd8b). Tất cả bước tiếp theo và giới hạn kiểm chứng nằm trong báo cáo này; `sideplay/tiep tuc du an.md` 1.15 MB vượt khả năng sửa qua Contents connector hiện tại nên không được coi là đã cập nhật.

# SidePlay 1.0.4-1 — nơi kiểm kê, giải nén và phát triển DuoFace mới

**Nguồn và quyền sở hữu:** DEB do chủ dự án upload vào repo `Duoface`; đây là **tham chiếu nhị phân của sản phẩm SidePlay**, không phải mã nguồn do DuoFace sở hữu. Việc giải nén không cấp quyền sao chép/phân phối hoặc chuyển nhị phân của bên thứ ba thành ứng dụng DuoFace độc lập. Phần mã độc lập sẽ được viết mới và tách rõ khỏi bản tham chiếu.

## Đường dẫn đã kiểm chứng (18/10/2026)

- **DEB gốc, giữ nguyên:** [`../com.sideplay_1.0.4-1_iphoneos-arm64.deb`](../com.sideplay_1.0.4-1_iphoneos-arm64.deb).
- **Bản giải nén nguyên payload:** [`extracted-1.0.4-1/rootfs/`](./extracted-1.0.4-1/rootfs). Giữ đúng đường dẫn `var/jb/...`, file mode và byte. Empty directories được ghi nhận trong inventory (Git không lưu thư mục rỗng).
- **Debian control và script:** [`extracted-1.0.4-1/control/`](./extracted-1.0.4-1/control) có `control`, `postinst`, `prerm`; không chạy script.
- **Báo cáo kiểm kê thực tế:** [`audit/deb-1.0.4-1/`](./audit/deb-1.0.4-1): `summary.json`, `inventory.json`, `SHA256SUMS.txt`, `archive-file-list.txt`, `macho-load-commands.json`, `plists-decoded.json`, `image-dimensions.json` và `macho-strings/`.
- **Công cụ giải nén tái lập:** [`tools/extract_sideplay_deb.py`](./tools/extract_sideplay_deb.py).
- **GitHub Actions:** [`.github/workflows/sideplay-unpack-original.yml`](../.github/workflows/sideplay-unpack-original.yml); run [39114447674](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39114447674), thành công. Commit chứa payload thực: [`1288472a4bdb120acb7102f4b64b879ff4c7019a`](https://github.com/chuongnguyen89dn-ui/Duoface/commit/1288472a4bdb120acb7102f4b64b879ff4c7019a).
- **Hồ sơ tiếp nối:** [`tiep tuc du an.md`](./tiep%20tuc%20du%20an.md).

## Số liệu có bằng chứng từ run 39114447674

| Chỉ số | Kết quả |
|---|---:|
| SHA256 DEB | `7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c` |
| Kích thước DEB | 4.352.576 B |
| File thường trong rootfs | 136 |
| Mach-O binary (executables/dylibs) | 7 |
| Ảnh PNG | 119 |
| Plist | 9 |
| License-GMapHUD | 1 |
| File control | 3 |
| Symlink rootfs | 0 |
| Thư mục rootfs (kể cả thư mục rỗng) | 14 |

**Lưu ý quan trọng:** 7 Mach-O gồm ba `fat_macho` (`SidePlay.dylib`, `SidePlayHUDRelay.dylib`, `SidePlayPrefs`) và bốn `macho64`. Bảng load commands hiện mới quét trực tiếp các binary thin; với các fat binary, cần phân tích từng architecture slice trước khi có đầy đủ LC_LOAD_DYLIB/ObjC selectors. Dữ liệu `macho-strings/` là các chuỗi printable, không phải mã nguồn đã phục hồi.

Các file `SidePlay.plist`, `SidePlayHUD*.plist` là **OpenStep plist hợp lệ**, nhưng `plistlib` Python chỉ hỗ trợ XML/binary plist; mục `error: Invalid file` trong `plists-decoded.json` có nghĩa **parser không hỗ trợ định dạng này**, không chứng tỏ file gốc lỗi. Nội dung gốc vẫn được giữ nguyên trong `rootfs`.

## Những gì có thể và không thể sửa trực tiếp

| Loại file | Có thể sửa như source text? | Quy tắc |
|---|---|---|
| `control`, `postinst`, `prerm` | Có, nhưng thuộc gói tham chiếu | Không chạy/bê nguyên side effect (ví dụ `--sp-goodbye` kết nối server) vào DuoFace |
| `Info.plist`, `Root.plist`, MobileSubstrate filter plists | Có (XML/binary/OpenStep tùy file) | Sửa bản phát triển riêng; không đụng folder tham chiếu |
| PNG | Có thể thay bằng asset được phép sử dụng | Không mặc nhiên quyền chuyển toàn bộ ảnh sang project DuoFace |
| Mach-O `SidePlay`, `SidePlay.dylib`, HUD binaries và `SidePlayPrefs` | **Không có source .m/.h/.xm trong DEB** | Không thể chỉnh như mã nguồn ObjC; cần tự viết triển khai của DuoFace hoặc có source/ủy quyền hợp pháp |

**Không sửa trực tiếp byte trong `extracted-1.0.4-1/`.** Đây là **bản tham chiếu bất biến** để so sánh; sửa ở một thư mục nguồn mới có thể kiểm toán. Giữ phiên bản DEB gốc và checksum làm chuẩn hồi quy.

## Thứ tự tiếp theo

1. Đối chiếu chi tiết 7 Mach-O (fat slices/ObjC APIs), chẩn đoán IPC, app scene attach, lifecycle, CarPlay template và HUD hook. Việc này hiện **chưa đủ chứng cứ** để gọi là khôi phục source.
2. Lập bản đồ `SidePlay` hành vi ↔ `DuoFace` giao diện đã duyệt (Native12/Visual12/HUD8) và xác định rõ tính năng đã nghiệm thu.
3. **Viết mới** mã nguồn độc lập, sử dụng dữ liệu tham chiếu và API phù hợp; chưa can thiệp Native/Visual/Hub hoặc Sileo.
4. Kiểm thử trên iPhone X/iOS16 từng bước và lưu kết quả thật.

**Trạng thái:** giải nén + commit + báo cáo tĩnh **PASS**. Mã nguồn độc lập, compile, device test, Sileo **CHƯA thực hiện**.
