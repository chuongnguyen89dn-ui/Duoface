# QA181 — B0 stock baseline qua công tắc hiện có (2026-11-07)

## Nguồn đã đọc và đối chiếu
- Repo: chuongnguyen89dn-ui/Duoface; source branch feature/duoface-qa181-b0probe1-20261106, HEAD 1e5eec45475b45dedfd611857a0ed577a69ca100.
- Handoff trên feature có Audit 9 mới hơn spec-main; phải đọc cả nhánh đang làm, không lấy mục thiếu icon cũ làm trạng thái hiện tại.
- Log: main commit ce11def244ae8eb3996764f6ce05d57d99160292, sideplay/log/DuoFaceAudit 9.txt; bytes 5568491; Git blob f6a7abfd2706c5855b858b70b038f80cb4e88e5a. Đã tải nguyên bytes và tính Git blob SHA-1 khớp. Python splitlines() cho 26646 dòng (checkpoint cũ nói 26647; không ảnh hưởng các số dòng dẫn dưới).
- Source signed CI 42237345803 job 127959363702 rechecked completed/success. Actions API status=in_progress và queued đều total_count=0 khi kiểm tra trong lượt này. Không khởi động job/build/deploy.

## Kết quả đếm lại Audit 9
| Bundle | Grid pressed | Bridge accepted | Original forwarded |
|---|---:|---:|---:|
| com.google.Maps | 7 | 7 | 0 |
| com.waze.iphone | 2 | 2 | 0 |

Maps pressed: 14845,14959,15044,15130,15199,15281,15374.
Maps accepted: 14863,14977,15062,15148,15217,15299,15392.
Waze pressed: 15438,15564; accepted:15456,15582.
250 timestamped area=qa181-b0 records: duoface=249, stock=1.
Stock duy nhất dòng 25212: observer-ready, process=CarPlay pid=4939; không phải scene-owner của Maps.
Snapshot section dòng 17754: [không đọc được hoặc file chưa tồn tại].
underlock-observed=0. Q1 và tương quan Q3 stock vẫn chưa xác minh.

## Phát hiện mới: có thể bypass hook bằng UI đã có, không cần bản mới
DFNativeHostRootController.m:519–550 có dòng Quản lý trong tab ứng dụng:
“Mở trực tiếp App từ CarPlay Home” (row 9), riêng với “Hiện app trên CarPlay Home” (row 8).
home145SwitchChanged: nhánh OFF gọi DFHome145Write(NO), báo lỗi nếu ghi thất bại, rồi notify standalone144.stop.
DFHome145Consent.h: DFHome145Enabled() đọc lại StandaloneHomeDirect với parent consent.
DFHomeStandalone144.m: DF144Allowed yêu cầu DF144ExplicitConsent() -> DFHome145Enabled().
DF144BeginSelectedBridge trả NO ngay khi !DF144Allowed; DF144Launch gọi DF144Original khi !bridged.
Do đó OFF công tắc này tạo đường forward theo mã hiện tại mà không cần sửa roster, đổi allowlist, gỡ tweak hoặc viết thêm bypass. Đây là chứng minh luồng source; chưa chứng minh thao tác trên xe.
Nó ảnh hưởng mọi app qua standalone Home/Dock khi OFF (kể cả Safari/GOFA), không phải chỉ Maps/Waze. Có thể bật lại bằng cùng UI sau khi đo. Không tự coi tác dụng ngoài xe đã được kiểm chứng.

## Phát hiện mới: lỗ hổng process ở bộ lấy mẫu
DFCarPlayDockOwner.m:521–528 DFZMapSceneWatch chỉ gọi DFIntegratedCarPlayCaptureLiveOwnerSnapshot khi processName == CarPlayApp.
DFCarPlayLiveOwnerSnapshot.m:187–190 chính hàm nhận hỗ trợ CarPlayApp HOẶC CarPlay.
Log 9 QA181 listener-ready và observer-ready hiện diện tại CarPlay (25211–25212), không có timestamped QA181 CarPlayApp observer-ready được tìm thấy.
Vì thế ở process CarPlay đang được quan sát, vòng gọi hiện tại chắc chắn không lấy snapshot. Điều này giải thích một thiếu sót instrumentation có thật; KHÔNG chứng minh CarPlayApp không chạy hoặc Maps nằm ở CarPlay.
Không thể hứa tắt standalone là đủ trả lời Q1: còn thiếu snapshot và bằng chứng owner. Không sửa guard hay phát hành bản mới trong lượt này.
Nếu log sau vẫn thiếu snapshot, thay đổi được đề xuất cho work order instrumentation riêng: cho vòng lấy mẫu chạy ở hai process đã được hàm hỗ trợ, ghi kết quả write/skip để phân biệt chưa gọi với lỗi I/O; bổ sung HomeRoster165 vào exporter. Giữ nguyên roster/presenter/scene/lifecycle và QA180 H1/Darwin. Cần đánh giá/build/version riêng trước phát hành; chưa thực hiện.

## Bước tiếp theo trên thiết bị, dùng QA181 hiện có
1. Khi xe đang đỗ, trong DuoFace trên iPhone mở tab ứng dụng, phần Quản lý, tắt “Mở trực tiếp App từ CarPlay Home”. Giữ “Hiện app trên CarPlay Home” và lựa chọn My Apps như hiện tại.
2. Quay về Home gốc, mở Google Maps khoảng 10 giây, về Home, mở Waze khoảng 10 giây. Sau đó thử Maps từ lưới chia ô DuoFace một lần.
3. Xuất log. Gate đầu: phải thấy qa160-native-icon-forwarded cho Maps/Waze và không có standalone bridge-accepted tương ứng SAU lúc OFF. Nếu vẫn accepted thì dừng gán stock, kiểm tra ghi consent/phiên CarPlay.
4. Gate Q1: cần owner snapshot có bundle/sceneID/process/controller/display/time gắn lượt mở đã forwarded; thiếu thì vẫn unresolved. Observer-ready không đủ. Route-preview/active-navigation trong ảnh không đủ.
5. Gate Q3: cần blank/underlock quan sát gắn đúng scene/time; không suy writer, pause/restore từ hai mức blank đơn lẻ.
6. Nếu muốn khôi phục standalone sau phép đo, bật lại công tắc đã tắt bằng UI hiện có. Chưa tự thao tác được thiết bị của người dùng.

## Kiểm tra thực tế và giới hạn
Lệnh tại repo:
`python3 -m unittest discover -s sideplay/duoface-native-scene-host/tests -p 'test_qa145_controlled_home.py' -v`
Kết quả: 5 tests, 4 PASS, 1 FAIL: test_qa145_distinct_signed_artifact_no_old_home_to_split còn pin “0.1.171~gofadiag1” trong build.sh nay version 181. Đây là stale historical version assertion, không phải bằng chứng runtime công tắc hỏng. Không sửa assertion để lấy xanh, không báo suite PASS.
Đã đọc đối chiếu hồ sơ DuoNavi gốc QA136 và QA146: catalog/admission, workspace và bridge ownership là các bước riêng. Không lấy presence selector hoặc tên controller làm chứng cứ scene live; không sao chép vendor code/license.
Không có thay đổi mã chạy, DEB, Sileo, logo, touch gate hay Darwin protocol; B1/B2 chưa bắt đầu.
