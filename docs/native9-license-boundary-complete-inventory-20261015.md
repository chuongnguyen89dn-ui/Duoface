# DuoFace Mới — giấy phép: giữ CarPlay, ẩn phần còn lại — kiểm kê hiện trạng 15/10/2026

## Mốc chuẩn bắt buộc

- Người dùng xác nhận **native9 hoạt động tốt mọi thao tác trên CarPlay**: logo kéo dọc sau 0,30s, hoán đổi 2 app khi tap, kéo thanh chia đổi tỷ lệ, YouTube nút tròn fullscreen, không che nội dung. Người dùng xác nhận app iPhone hiện **không thấy giao diện/ngày kích hoạt giấy phép**.
- Người dùng yêu cầu tiếp tục: **chỉ giữ mã thực sự cần thiết cho CarPlay và vòng đời/ABI bắt buộc, còn phần giao diện/logic giấy phép phải ẩn**. Trước khi xóa vật lý cần chứng minh an toàn; KHÔNG đánh đồng giấu text, thay thân hàm bằng stub, xóa class metadata và xóa mọi dependence.
- Baseline đã thử: `com.duoface.independent_0.1.0~native9_iphoneos-arm64.deb`, SHA256 `e4e1122a494d32af6ec42c97c4288f6effb6716fbb81cb52b81b746280d4d97e`, hiện phát hành trên `https://chuongnguyen89dn-ui.github.io/carplaydsp/`. **KHÔNG thay artifact, không build gói mới và không cập nhật Sileo trong giai đoạn audit này.**

## 1. Phần đã thay thân hàm/hủy nội dung hiển thị

Đối chiếu **đúng từng (class,selector,method signature), giữ cả multiplicity khi trùng selector** từ `dist/payload-migration/native4/BAO_CAO.json` và `dist/payload-migration/native5/DANH_SACH_CHO_XOA.json` với script audit mới:

| Đối tượng | Số lượng | Trạng thái đã chứng minh |
|---|---:|---|
| DuoFaceUI license-related Objective-C method bodies | 248 | Body gốc đã thay bằng các ABI-compatible stub từ native4, metadata giữ lại |
| DuoFaceDashboard license-related Objective-C method bodies | 43 | Body gốc đã thay bằng các ABI-compatible stub từ native4, metadata giữ lại |
| Hai accessors `XXRootViewController.isShowingExpiredModal`/`setIsShowingExpiredModal:` | 2 | Vô hiệu hóa trong native5; giữ signature cho ABI |
| CarPlay screen detection `CBLicenseSyncManager.isCarPlayScreenConnected`/`isCarPlayScreen:`/`isCarPlayScreenConnectedExcludingScreen:` | 8 bản ghi qua hai binary | **GIỮ thân thật**, cần cho CarPlay dù tên class là License |
| Lifecycle `init`, `sharedInstance`, `dealloc`, `.cxx_destruct` | 19 bản ghi | **GIỮ thân thật**, cần tránh crash Object-C và mất chức năng khởi tạo |

Tổng **320 bản ghi** đã được reconciliation; **291 method body gốc neutralized** và **2 accessor neutralized**; **27** bản ghi bắt buộc giữ (8 CarPlay + 19 lifecycle). Đủ 320, không có bản ghi nào bị bỏ sót trong ledger, nhưng **KHÔNG chứng minh không còn đường logic giấy phép khác qua C function/symbol hoặc dynamic call**. Nguồn cần giữ: `audit/payload-migration/LICENSE_BOUNDARY_AUDIT.json` báo `dynamic_dispatch_fully_resolved=false` và `license_subsystem_separable_by_file=false`.

Lịch sử text: native5 đã che **26 literal** (13 mỗi binary), native6 đã xóa trắng nội dung literal đó bằng byte zero (không bỏ kích thước, metadata), native9 đã **mask thêm 78 literal** (39 text × 2 binaries) bằng dấu cách; các nhãn trial/activation/payment/giftcode phổ biến đã không còn văn bản hiển thị. Không tính metadata/class/selector là những dòng đang thấy trên UI.

## 2. Toàn bộ 256 literal của kiểm kê native6 (gốc của native9)

Audit mới lưu **mọi record** gồm `binary`, offset, chiều dài, SHA256 cũ, nhãn an toàn và nhóm ở `audit/payload-migration/NATIVE9_LICENSE_KEEP_VS_HIDE_READONLY.json`. Tổng 256/256 được phân nhóm; không xóa bừa theo regex chứa chữ license:

| Nhóm | Số | Quyết định |
|---|---:|---|
| 39 giao diện đã che × 2 binary | 78 | DONE trong native9 |
| Opaque (không xuất nội dung vì có khả năng là URL/key/dữ liệu nhạy cảm) | 88 | Chưa biết callsite, giữ |
| Khóa localization (`KEY_`, `SUB_`, `ROW_`, v.v.) | 40 | Giữ để không phá lookup; chỉ ẩn hàng giao diện ở view-level khi còn hiện |
| Diagnostic logs | 18 | Không phải UI, giữ để truy lỗi |
| Khóa state/serialization/protocol | 12 | Giữ, không thay thành dấu cách |
| Objective-C classes/selectors | 8 | Giữ runtime lookup |
| CarPlay và deactivation/scene lifecycle | 5 | Giữ bắt buộc |
| Runtime notification identifiers | 2 | Giữ |
| Apple system identifier | 1 | Giữ |
| Chuỗi `activate` có thể là state/command | 1 | Giữ, chưa xác định callsite |
| Chuỗi `expired` có thể là state | 1 | Giữ, chưa xác định callsite |
| **NSString `Activate` có thể là nhãn UI** | **2** | Cần truy callsite, chưa được phép tự zero |

**178 record chưa mask không đồng nghĩa 178 dòng UI còn hiển thị.** Người dùng xác nhận app iPhone **không thấy gì**, nên hiện chưa có một row license rõ ràng cần ẩn ở view-level.

## 3. Hai `Activate` đã được truy đến binary thật

Tool nguồn `scripts/audit_duoface_native9_activate_refs.py` chỉ đọc bản native9 đã pin SHA256, giải nén sang directory tạm, đọc Mach-O `__cstring`, `__cfstring`, các con trỏ, xref ARM64 ADR/ADRP+ADD/LDR:

| Binary | Offset byte của `Activate` | Object NSString `__cfstring` | ARM64 static address-load candidates | Nằm trong thân hàm đã neutralized native4 |
|---|---|---|---:|---:|
| DuoFaceUI | `719363` | `0x1000efee8` | **13** | **0/13** |
| DuoFaceDashboard.dylib | `3132199` | `0x34a688` | **13** | **0/13** |

Mỗi binary có 1 `__cfstring` trực tiếp trỏ đến literal `Activate`; độ dài 8 khớp và không tìm được ref trực tiếp từ `__objc_selrefs`. Tool đã dịch địa chỉ lệnh VM về **file offset Mach-O** theo section rồi so thật với 291 vùng function-body đã patch (không so nhầm VM của app với file offset). **13 vị trí bên ngoài stub là ứng viên tham chiếu tĩnh, không chứng minh nút đang hiển thị hoặc lệnh đang chạy.** Chưa đầy đủ dynamic dispatch/control flow; không có quyền kết luận "đây chắc chắn là text chỉ để hiển thị", không thay chuỗi trong native9 lúc này. Tất cả địa chỉ và evidence nằm trong `audit/payload-migration/NATIVE9_ACTIVATE_REFS_READONLY.json`.

## 4. Bằng chứng CI và commit

- Script tổng kiểm: `scripts/audit_duoface_native9_license_keep_vs_hide.py`, commit `4248e280605d400edaaca1fc7fc97bba6207cb3a`.
- CI tổng kiểm `.github/workflows/duoface-native9-license-boundary-readonly.yml`, commit `a4f10d5436526a9fea588c2ab589f808c7c5ac77`; GitHub Actions [run 38751758482](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/38751758482) **COMPLETED SUCCESS**, kết quả commit bot `e3f868566f81b4963f4d5a14ebf3068d4f471e27`, report blob `80c96905b977517db1426ce14e7cc9df985b56d0`.
- Truy `Activate`: `scripts/audit_duoface_native9_activate_refs.py` đã mở rộng đối chiếu actual neutralized spans, commit `da4183ae2dcd43ab8ebe66bee5b445a7f33d3ee0`.
- CI `.github/workflows/duoface-native9-activate-refs-readonly.yml` commit `698111bf2e36876a30799925d0cbf75995c74242`, run mới nhất [38753026088](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/38753026088) **COMPLETED SUCCESS**, report blob `da9911681a902ec0bf15d991306ef6f1248a693c`. Các run trước 38752397415 và 38752675384 cũng PASS nhưng report cũ không chứa so sánh inert function span.
- **Không có DEB mới, không sửa carplaydsp, không đổi package live.** Tất cả report là read-only; không cần thiết bị user chạy lại native9 vì hành vi phần mềm chưa bị đổi.

## 5. Tiếp tục từ đâu và tiêu chí đủ an toàn

1. **Ưu tiên duy nhất**: truy 13 static callsites ở hai binary của `__cfstring Activate` đến method/class thật hoặc call graph gốc, xác định sử dụng text trực tiếp hay localization key; đối chiếu xem các vị trí này nằm trong code CarPlay/lifecycle không được chạm hay chỉ là UIKit title đã mất entrypoint. Nếu không chắc, giữ.
2. Bất kỳ proposal ẩn bổ sung nào phải đưa ra **whitelist exact byte offset + original/new hash + chứng minh source** riêng; tuyệt đối không vô hiệu hóa generic `activate`, `activated`, `expired` hoặc `com.apple.DataActivation`.
3. Nếu có view license hiện lại trong tương lai, ẩn **đúng view/row/modal** thông qua scoped hook hoặc display data đã kiểm chứng. Không sửa toàn bộ `DuoFaceVisualHook.dylib` như lỗi native8; giữ nguyên bản native6 visual trong native9 và addon logo độc lập.
4. Khi người dùng yêu cầu đóng DEB: dựng **version mới từ chính native9 SHA-pinned** để bảo toàn mọi chức năng đã thử, báo cáo diff + rootless signing + Sileo public SHA, cài trên xe test lại. Chỉ xử lý việc xóa hẳn class/metadata sau khi xác minh dynamic caller graph; hiện chưa đạt tiêu chí này.

**Kết luận tại thời điểm ghi:** chức năng CarPlay đang ổn trên native9, phần giao diện license không còn nhìn thấy theo feedback user. Phần lớn body license đã được vô hiệu từ native4; phần còn lại là metadata/keys/log/opaque và 2 NSString `Activate` còn xrefs cần kiểm tra. Không được nói "đã xóa sạch code giấy phép".


## 6. Truy tiếp 26 callsite: bản đồ ObjC function + symbol (cập nhật tiếp 15/10/2026)

- Đã tạo **script thực thi read-only** `scripts/audit_duoface_native9_activate_callsite_owners.py` (commit `f6127799065312347afa23ed75f65d7e308ffff0`), thêm parsing `__objc_classlist`, các IMP trong metadata, `LC_FUNCTION_STARTS` và `LC_SYMTAB` (commit `a2a1e239910a804aaf915600bd188264089b4d59`). Script mở đúng SHA pinned native9; không sửa code, gói, giấy phép hay repo Sileo.
- Workflow `.github/workflows/duoface-native9-activate-owner-readonly.yml` commit `a3de7a20c0bd017e9b61c3e2827cf95aaa7a146f`; GitHub Actions lượt mới nhất **[38754191939](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/38754191939) COMPLETED SUCCESS**, job `116488139252`. Report `audit/payload-migration/NATIVE9_ACTIVATE_CALLSITE_OWNERS_READONLY.json` bot commit **`2832a604b2f6ca15806d38ef77f47592a3ca4754`**, blob **`f7cbf677f4b3add56f6b60380929f722efa5161e`** (GitHub đọc lại xác minh). Run trước `38753987791` cũng PASS.
- **DuoFaceUI:** parser xác nhận **522 ObjC methods** và **726 LC_FUNCTION_STARTS**, bảng `LC_SYMTAB` có **78 symbol địa chỉ đặt tên**; cả **13 vị trí ứng viên tham chiếu `Activate` đều có ranh giới hàm**, nhưng **0/13** trùng IMP ObjC metadata **và 0/13** có tên symbol chính xác tại function start.
- **DuoFaceDashboard:** parser xác nhận **757 ObjC methods** và **1526 LC_FUNCTION_STARTS**; symbol table không còn địa chỉ named function phục hồi được. Cả **13/13** ứng viên có ranh giới hàm, nhưng **0/13** trùng ObjC method IMP và **0/13** có named function symbol tại start.
- **Hệ quả chính xác:** Chưa chứng minh các callsite có thể xóa; đây là các vùng C/C++/compiler function **chưa có owner** trong metadata, có khả năng đang dùng dữ liệu NSString. **Không được báo là 26 hàm license còn hoạt động** vì chúng mới là 26 static address-load candidates, chưa có control-flow/runtime trace. Nhưng cũng **không được tự mask `Activate`** khi chưa chứng minh là text thuần.
- **Tiếp tục về kỹ thuật:** có thể lập graph một mức bằng disassembly quanh 26 function starts và xref `__cfstring` tới nơi nạp string, đối chiếu các `objc_msgSend`/UIKit setters ở nơi thật sự dùng `Activate` — nếu code symbol stripped thì cần khoanh đúng hàm không dùng class metadata, không tự đoán. Ưu tiên kiểm mục **không hề hiện trên iPhone theo user**; chưa có lý do làm DEB ngoài chức năng đã hoàn chỉnh.
