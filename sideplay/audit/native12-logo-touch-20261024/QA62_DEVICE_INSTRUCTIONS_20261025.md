# DuoFace 0.0.62 — đo logo trên thiết bị, không build bản mới

**Mục tiêu duy nhất:** xác minh bản `0.0.62~rawgrip1` hiện có có nhận raw touch, Hold 3 giây, Ratio kéo ngay và sau 0,8 giây, Swap hay không. Không áp dụng thuật toán Muse Candidate trước khi có kết quả máy. Script không sửa tweak, scene settings, SpringBoard, Sileo, hoặc các log gốc. Nó **có ghi** tệp QA riêng vào `/var/mobile/Library/Logs/DuoFaceQA62/` trên điện thoại.

**Nguồn kiểm chứng:** branch `feature/duoface-jb-embedded-appbridge-20261020`, source `sideplay/duoface-native-scene-host/DFNative12Chrome.m` blob `01de5dc0e827680d7af7504abd5c645ee17d8eeb`, runtime marker `DFDeepTrace.h` build `0.0.62~rawgrip1`. Signed/public package previously published from run 40053489952 / publisher 40053794389; installed state/device status unknown.

## Chạy trong NewTerm (khi xe **đỗ**, CarPlay đang hiện hai ô)

Script lưu ở commit bất biến `9a8ac4b6b9b82d51063216ba3e8cfd56fda43266`:

```sh
cd /var/mobile
curl -fL 'https://raw.githubusercontent.com/chuongnguyen89dn-ui/Duoface/9a8ac4b6b9b82d51063216ba3e8cfd56fda43266/sideplay/audit/native12-logo-touch-20261024/collect_062_device_touch_qa.sh' -o dfqa62.sh
sh dfqa62.sh
```

Nếu thiết bị thiếu `curl`, tải `collect_062_device_touch_qa.sh` qua Filza hoặc trình duyệt và chạy `sh /duong/dan/den/file.sh`. **Không dùng** `curl | sh`; script lưu về file trước khi chạy. Script chặn nếu không xác minh được gói `com.duoface.jb.embedded` có version `0.0.62~rawgrip1` qua dpkg, hoặc chưa có `DuoFaceDeepTrace.log`.

Script hiện hướng dẫn 5 nhóm, mỗi nhóm 3 lượt, bấm Enter để bắt đầu/kết thúc và trả lời số lượt **nhìn thấy thành công** (0–3):

1. `hold_still`: giữ tâm logo >3,5 giây **rồi kéo dọc** đường chia 1–2cm và nhả
2. `hold_jitter`: rung tay nhẹ vuông góc, trả lại tâm, giữ >3,5 giây rồi kéo dọc
3. `ratio_immediate`: kéo vuông góc ngay khi chạm logo
4. `ratio_delayed`: đợi 0,8–1 giây rồi kéo vuông góc đổi tỷ lệ
5. `swap_tap`: chạm ngắn logo để hoán đổi hai ô

Cần đang ở giao diện split, hết startup, không mở picker/menu/style, logo hiển thị. Không test khi lái xe. **Nếu sai version, dừng và gửi lại dòng báo lỗi, không cài bừa hoặc thử trên phiên bản khác.**

## Dữ liệu sau khi kết thúc

Đầu ra: `/var/mobile/Library/Logs/DuoFaceQA62/DuoFaceQA62_<timestamp>_<pid>.tar.gz` hoặc folder cùng tên nếu máy thiếu tar. Dùng Filza chia sẻ tệp này vào chat (kiểm tra nội dung nếu muốn trước khi chia sẻ). Tệp chỉ chứa:

- `manifest.txt`: tên phiên, version dpkg, thời điểm bắt đầu/kết thúc;
- `groups.tsv`: nhãn và thời gian 5 nhóm, số lần người dùng thấy thành công;
- `deeptrace-labelled.log`: marker `area=chrome` và `area=logo-control` trong khoảng đo, đọc `DuoFaceDeepTrace.log` và `.previous` nếu tồn tại;
- `touchowner-new.log`: chỉ các byte được nối thêm vào `DuoFaceTouchOwner.log` kể từ lúc bắt đầu, nếu file không bị thu nhỏ;
- `summary.txt`: số raw/hold/moved/ratio/timer suppressed/swap/cancelled **theo nhóm**, KHÔNG chứng minh được từng touch ID là nguyên nhân nào, có thể lệch khoảng 1 giây ở ranh giới nhóm.

Nếu không thấy marker runtime `build=0.0.62~rawgrip1`, script ghi **WARNING**, không được kết luận từ các số 0 rằng chức năng hỏng. Raw và chrome có cấu trúc ID khác nhau, phải đánh giá với giới hạn tương quan đã ghi ở vòng 3. Script không upload hoặc truyền log ra mạng.

## Kiểm thử script trong môi trường shell trước khi commit

- Tại môi trường thực thi cục bộ, file `sh -n collect_062_device_touch_qa.sh`: **PASS**.
- Chạy dry run trên dữ liệu fixture giả lập `utc`, `area=logo-control raw-began/ended`, `area=chrome logo-3s-hold-began-real-touch-timer`, `logo-3s-moved-position`; tạo `manifest.txt`, `groups.tsv`, `summary.txt`, tệp tar: **PASS**.
- Fixture đều có timestamp trong cùng giây nên các marker được tính ở nhiều nhóm; đây là bằng chứng parser chạy, **không phải** chứng cứ thống kê chính xác theo nhóm hay test trên iPhone.
- Chưa thử script trực tiếp trên NewTerm/iPhone, chưa xác minh `curl` và `tar` có sẵn trên máy đích; script dùng `/bin/sh`, `awk`, `date`, `tail`, `dpkg-query` và có thông báo thiếu khả năng.

## Quy tắc quyết định sau khi nhận file QA

- `raw-began` không có: xác minh build/runtime, startup/split/focus/popup, hit routing; không vội sửa timer.
- `raw-cancelled`: có hủy chạm, nhưng **chưa kết luận** parent pan gây ra; truy window lifecycle.
- Nhóm Hold có `logo-quick-ratio-drag-began-restored-v056`: nghi ratio latch, cần log-only per-touch nếu chưa đủ nối đúng touch.
- Không có Ratio, timer suppressed: kiểm tra serial/pending/hidden guard; so thời điểm.
- Có hold-began nhưng không `logo-3s-moved-position`: kiểm delta/span/anchor/persistence.
- Nếu tất cả nghiệm thu thiết bị PASS: **không sửa** logo; chuyển sang lỗi player/crash với dữ liệu riêng.
- Nếu không đủ phân biệt: nâng cấp đo log-only, không áp dụng trước thuật toán Candidate/dwell/Swap.

**Chưa thay source .62, DEB, Sileo hay private scene setter.**