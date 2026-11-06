# QA181 — DuoFaceAudit 10, kiểm tra lượt native forward (2026-11-07)

## Nguồn và xác minh
Repo chuongnguyen89dn-ui/Duoface main commit 2406d1f1c7df7fa7419aa2aa15eaca6076176f1c.
File sideplay/log/DuoFaceAudit 10.txt, bytes 5898283; tính Git blob SHA-1 khớp 5a4718133a22401bf61e601be16bf698e38c5b1f.
27408 dòng theo Python splitlines(). Date export 2026-11-06 23:09:56 +0000 = 2026-11-07 06:09:56 Asia/Ho_Chi_Minh.
Runtime trace build 0.0.181~b0probe1. Dòng exporter 171 là chuỗi cũ, không được dùng để kết luận đang chạy QA171.
Log là bản tail tích lũy nhiều build/phiên. Phải tách các sự kiện mới khỏi accepted cũ trong Audit 9.

## Kết quả quan trọng
Dòng 27393: Standalone Home: enabled=NO receiverAlive=YES. Công tắc đã OFF tại export.
Trong cửa sổ mới UTC epoch >=1794006320:
| App | Original forwarded | Standalone accepted |
|---|---:|---:|
| Google Maps | 2 | 0 |
| Waze | 3 | 0 |

Các cú bấm forward, giờ VN:
- Maps 06:05:28.492 (15619), 06:08:45.073 (15681).
- Waze 06:05:48.182 (15625), 06:06:55.685 (15645), 06:07:18.991 (15651).
- CarPlay Settings 06:06:00.074 (15631) cũng forwarded.
9 bridge-accepted trong toàn file là các lần cũ UTC1794005036–5238 (Maps 7/Waze 2), không phải bypass thất bại.
Như vậy contamination ở DF144 tap interceptor đã được loại khỏi 5 cú bấm mới. Forward xác nhận gọi handler Apple; không tự chứng minh scene Apple đã render hoặc mọi hook khác không tham gia.

## Đường split DuoFace vẫn quan sát được
Các lần activate/poll thuộc process SpringBoard pid4906, owner=SBAppViewController/FBScene:
Google Maps sceneID:com.google.Maps-default; Waze sceneID:com.waze.iphone-8C5B6DAE-6AE7-4FE1-A2BE-88B75A1C26ED.
Pane {297.5,360}, external display {640,360}.
Ví dụ 27301/27303 và 27324/27326, ready sau đó 27364/27365.
8 scene-frame-readback trong cửa sổ mới đều actual {414,736}, target {595,720}, same=0:
Maps 26741,27004,27199,27349; Waze 26754,27019,27212,27358.
Đây là mismatch tại thời điểm readback, không phải bằng chứng mọi setter/lần layout sau đều thất bại. Nó KHÔNG tự chứng minh nguyên nhân giao diện danh sách, scene role hay renderer bị chuyển; chưa có app-side role/controller evidence.
Ảnh trước cho thấy hai vùng danh sách chỉ đường; có thể đối chiếu với hosting split, nhưng không có timestamp ảnh đủ để gán chính xác một activate event.

## Điểm bộ đo còn thiếu
Snapshot section 17789–17790 vẫn [không đọc được hoặc file chưa tồn tại].
394 timestamped area=qa181-b0: duoface393, stock1. Stock duy nhất dòng25255 là observer-ready từ CarPlay pid4939, UTC1794004394, trước lượt bypass mới; không có bundle/scene timeline native Maps/Waze.
Home page snapshots có DBApplicationSceneViewController nhưng không có sceneID/bundle tương ứng, không đủ xác định map owner.
Đối chiếu source đã đọc trên feature HEAD1e5eec45475b45dedfd611857a0ed577a69ca100:
DFCarPlayDockOwner.m:DFZMapSceneWatch chỉ gọi snapshot ở CarPlayApp.
DFCarPlayLiveOwnerSnapshot.m hàm nhận hỗ trợ CarPlay và CarPlayApp. Vì thế watcher ở CarPlay đang có listener sẽ skip lời gọi. Đây là defect coverage của instrumentation, chưa đủ gán nguyên nhân toàn bộ lỗi file vắng hoặc nơi native scene thực sự nằm.
Không bắt người dùng lặp lại cùng test trên cùng instrumentation để chờ snapshot tự xuất hiện.

## Q3
4 bks-blank-observed trong toàn trace (25673/25674/26672/26674).
1 underlock-observed dòng26673 UTC1794005548.813354, detail owned=0 foreground=1, bundle=native-carplay sceneID=unavailable.
Underlock này xảy ra trước lượt native forward mới, không có Maps/Waze identity, không chứng minh scene stock map allowed-under-lock hoặc ai blank/restore.
Không giữ kết luận cũ “zero underlock” của Audit9 cho Audit10.

## Kết luận và bước tiếp nối
- Native Home tap bypass: VERIFIED với log mới (Maps2/Waze3 forwarded).
- Q1 exact native Maps/Waze owner: UNRESOLVED vì observer gap, không còn bị chặn bởi DF144 tap bridge trong 5 lượt mới.
- Q2 split path: SBAppViewController + FBScene có bằng chứng; pixel/touch/navigation không suy từ ready.
- Q3 native correlation/writer: UNRESOLVED.
- Triệu chứng danh sách thay mặt bản đồ chưa có root cause được chứng minh. Mismatch geometry là phát hiện thật, không gán thành nguyên nhân duy nhất.
- Bước kỹ thuật kế: sửa instrumentation call coverage trên cả hai process đã hỗ trợ, ghi write/skip/exception provenance và app-side scene role/controller read-only. Cần work order/version/build cho phần instrumentation; không sửa presenter/scene selection/roster/QA180 H1/Darwin để bù thiếu log, không bắt đầu B1/B2.
- Lượt này chỉ kiểm log/đọc source/lưu bằng chứng. Không thay mã chạy, build, CI, DEB hoặc Sileo.

## Lệnh thực tế
Từ /workspace/scratch/f9a10e281851/Duoface:
curl -sfL --max-time 60 'https://raw.githubusercontent.com/chuongnguyen89dn-ui/Duoface/2406d1f1c7df7fa7419aa2aa15eaca6076176f1c/sideplay/log/DuoFaceAudit%2010.txt' -o /workspace/scratch/f9a10e281851/evidence/DuoFaceAudit10.txt
Python stdlib: read_bytes, SHA1(b'blob '+str(len(bytes)).encode()+b'\\0'+bytes); splitlines; enumerate 1-based; chọn event tag và utc>=1794006320; đếm riêng stage=qa160-native-icon-forwarded theo bundle. Các số dòng/event và phiên bản nguồn ở trên đủ đối chiếu trực tiếp. Không test/build chạy trong lượt chỉ kiểm log.
