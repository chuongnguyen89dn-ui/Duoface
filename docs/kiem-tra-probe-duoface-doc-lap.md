# Quy trình kiểm tra DuoFace độc lập trên thiết bị (chưa bắt đầu)

**Phạm vi:** iPhone jailbreak rootless, CarPlay, mã nguồn nhánh `feature/duoface-independent-core`. Tài liệu này là **quy trình tương lai**, không phải bằng chứng đã cài hoặc đã chạy.

## Tại sao kiểm tra theo thứ tự này?

Bản đang sử dụng có các lớp cửa sổ `CB*` của lõi cũ. Để độc lập, trước hết cần xác định **các lớp hệ thống CarPlay** để dựng lại host theo cách mới mà không sửa chương trình kế thừa.

## Giai đoạn 1: chỉ đọc, không thay đổi giao diện

- Nguồn: `independent/DFIProbe.mm`, cài thông qua `DuoFaceIndependentProbe.plist`.
- Trạng thái mặc định: **tắt**, trừ khi có tệp `/var/mobile/Library/Preferences/com.duoface.independent.probe.enabled`. Không tạo tệp này trong gói cài.
- Khi bật và nạp vào đúng tiến trình, chương trình log tên tiến trình, hiện diện lớp và selector `DBWorkspace`, `DBApplicationController`, `DBDashboardWorkspaceOwner`, `FBSceneManager`, `SBApplicationController`, cùng danh sách kích thước màn hình `UIScreen`.
- Chỉ trên tiến trình `CarPlay`, khi tìm thấy mã Substrate, trình đo móc `DBWorkspace initWithOwner:` để quan sát việc tạo workspace gốc và trả về đối tượng gốc; **không** thay hành vi chuyển ứng dụng.
- Sự kiện kích hoạt chụp lại là thông báo Darwin `com.duoface.independent.probe.snapshot`; chỉ dùng khi có công cụ gửi thông báo trên iPhone.
- Mọi log dùng tiền tố `[DuoFaceIndependent]`. Không chụp UID/UDID, tài khoản, giấy phép hay nội dung ứng dụng.

**Điều kiện đạt:** trong một phiên CarPlay thực tế, log xác định được tiến trình CarPlay, các selector có thật, màn hình ngoài và workspace dashboard (nếu hook/owner phù hợp). Nếu lớp/selector không có, phải ghi `present=0`, không gọi được hỗ trợ.

## Giai đoạn 2: host thật

Bộ bố cục `independent/DFISplitLayout.mm` chỉ **chấp nhận hai UIView đã chứa scene thật**; bộ bố cục không khởi chạy app hoặc chế tạo nội dung. Để được gọi là đã tạo độc lập hai ứng dụng, cần thêm bộ quản lý host lấy được **hai scene khác nhau**, có kích thước hợp lệ, có khả năng nhận chạm và tự khôi phục khi kết thúc. Không dùng ảnh chụp/static placeholder làm bằng chứng thành công.

## Nguyên tắc an toàn

- Tuyệt đối không cài gói thử song song với một tweak khác móc cùng tiến trình nếu chưa chuẩn bị cách tắt/gỡ; có thể dùng thiết bị phụ hoặc môi trường thử có phương án khôi phục.
- Không thay dữ liệu giấy phép, mã máy, bundle của bản cũ.
- Bất kỳ gói thử nào phải không chứa `DuoFaceDashboard.dylib`, `DuoFaceUI` kế thừa hay `com.duonavi.*`; chỉ phát hành khi đã kiểm tra quyền sử dụng các thành phần.
- Hệ thống kiểm tra biên dịch `.github/workflows/duoface-independent-compile.yml` **không tạo DEB**, không cài lên iPhone và không phát hành Sileo. Đừng tự hiểu biên dịch xanh là đã chạy được hai ứng dụng.

## Nhật ký kiểm tra thực tế

Chưa có lần cài đặt/thử CarPlay thật nào cho bản độc lập. Khi có: ghi ngày, thiết bị/iOS không chứa mã định danh riêng tư, SHA DEB, sha mã nguồn, bước thử, log và kết luận vào **`ban giao du an duoface moi.md` trên nhánh main**.
