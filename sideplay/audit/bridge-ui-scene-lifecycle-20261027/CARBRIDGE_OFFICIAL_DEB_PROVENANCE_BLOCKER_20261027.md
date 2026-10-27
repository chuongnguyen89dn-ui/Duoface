# CarBridge chính hãng: hồ sơ tham khảo DEB — 2026-10-27

## ĐÍNH CHÍNH YÊU CẦU 2026-10-27 — CarBridge chỉ là tài liệu tham khảo
- Người dùng làm rõ: **DuoFace đã có AppBridge tích hợp sẵn; CarBridge chính hãng chỉ là mẫu để tham khảo kỹ thuật**, **không phải dependency cần thêm, không phải điều kiện tiên quyết để tiếp tục phát triển DuoFace**. Yêu cầu tìm DEB chính hãng ở phần dưới là **một yêu cầu nghiên cứu tham khảo chưa có artifact**, không còn là blocker kỹ thuật của DuoFace.
- Source đã xác minh trên chính nhánh: `sideplay/jb-embedded-appbridge/README.md` ghi "CarBridge-EQUIVALENT ... inside independent DuoFace, without installing a separate CarBridge package"; `sideplay/jb-embedded-appbridge/package_integrated.py` định danh `com.duoface.jb.embedded`, `EXCLUDED` gồm CarBridge vendor, `Depends` chỉ firmware/mobilesubstrate, `contains_third_party_carbridge=False`, `separate_carbridge_dependency=False`; `sideplay/duoface-native-scene-host/DFSceneHost.m` là bộ host scene tự phát triển với SBAppViewController/mode2. Đây là **cơ chế bridge tương đương của dự án**, không có bằng chứng nó chứa binary/license CarBridge official.
- **Không yêu cầu người dùng tải/mua/gửi CarBridge DEB để làm tiếp**. Tiếp tục kiểm lỗi Live/foreground của code hiện có theo Native12/DuoNavi/OmniCar và tài liệu công khai; khi nào có DEB CarBridge original rõ provenance thì audit **chỉ để tham khảo kiến trúc**, không trộn mã máy vào gói.
- Thông tin lịch sử về CarBridge v2.0.14/v2.0.15 và việc chưa có official DEB vẫn được giữ ở dưới nhưng **không quyết định tiến độ DuoFace**.


## Yêu cầu người dùng
Phân tích **DEB CarBridge gốc của leftyfl1p** để học đường tạo host, Bridge UI, scene lifecycle, foreground/Live, thay app, focus, close và restore cho DuoFace độc lập. **Không nhầm** DuoNavi có tên/selector CarBridge hoặc CarPlayEnable mã nguồn mở với CarBridge chính hãng. Không thay license/vendor code. Không vá foreground đoán mò, không cài thử file không được xác thực.

## Kết quả truy tìm (ĐÃ XÁC MINH)
1. Official site: https://carbridge.app/download — tác giả tuyên bố **chỉ** phát hành qua Havoc Marketplace, các nguồn tải khác không chính thức.
2. Listing official: https://havoc.app/package/carbridge — **CarBridge 2.0.15**, ngày **2025-02-23**, seller **leftyfl1p**, **hỗ trợ rootless**, iOS **13.0–16.7.16** theo trang cập nhật kiểm tra ngày 2026-10-27. Listing không phải DEB byte hay source.
3. Official changelog https://havoc.app/package/carbridge/changes — công bố **v2.0.14** sửa crash khi **chuyển giữa các bridged apps trên một số iOS16** và cải thiện **bridged app không chiếm đầy đủ app window lúc khởi động**; **v2.0.15** sửa không tải được trên iOS13. Đó là **chứng cứ sản phẩm đã từng gặp đúng 2 loại triệu chứng** giống DuoFace (crash khi đổi app, bị bó trong cửa sổ), **KHÔNG tiết lộ patch/source hay khẳng định nguyên nhân giống DuoFace .79**.
4. Catalog package ID lịch sử: `com.leftyfl1p.carbridge13` theo https://idevicecentral.com/tweaksdb/package/com.leftyfl1p.carbridge13 (v2.0.13; listing cũ, architecture được ghi rootful). **KHÔNG dùng catalog cũ làm kết luận rootless control v2.0.15**; phải đọc `dpkg-deb -f` từ DEB đã tải. GitHub epeth0mus/carbridge chỉ README/khẳng định hỗ trợ, không phải source gốc và không được xem là package provenance.
5. GitHub main + branch `feature/duoface-jb-embedded-appbridge-20261020` + các nhánh `feature/visual12-duodash-recovery`, `feature/duoface-exact-payload-migration`, `feature/duoface-independent-core`, `duoface-carplay-standalone` đã xem recursive tree: **KHÔNG có file đặt tên `CarBridge`, `com.leftyfl1p` hoặc `carbridge13`** trong tree. Các repo có quyền truy cập đã rà `chuongnguyen89dn-ui/carplaydsp`, `Omnicar`, `Gpt-training-`, `DauDat-CarPlay` ở default branch cũng không có entry CarBridge.
6. Current `sideplay/jb-embedded-appbridge/audit_reference_debs.py` và `evidence/REFERENCE_DEB_AUDIT.json` chỉ quét **SidePlay 1.0.4-1 và DuoNavi 1.0.4**. `.github/workflows/duoface-jb-carbridge-deb-audit.yml` có chữ `carbridge` trong **tên workflow**, nhưng bước run ghi `Inspect original SidePlay and DuoNavi DEBs`, chỉ **2** gói. ***Đây không phải CarBridge chính hãng đã được quét.***
7. Quan trọng: DEB DuoNavi 1.0.4 có metadata `Conflicts: ... com.leftyfl1p.carbridge13`, `Replaces: ... com.leftyfl1p.carbridge13`, `Provides: ... com.leftyfl1p.carbridge13`; Mach-O có string `CarBridge` và `CBBridgeManager`. Điều này **không biến DuoNavi DEB thành CarBridge official**, không dùng nó như evidence original.
8. User Project/Library file search với tên `CarBridge` và `com.leftyfl1p.carbridge13` **không tìm thấy DEB**, chỉ log / báo cáo nói đến CarBridge. Đây không phải chứng minh bytes không tồn tại ở một nguồn chưa cấp quyền; chỉ kết luận **chưa có DEB gốc truy cập được**.

## Kết quả phân tích trực tiếp DEB CarBridge gốc
- **CHƯA THỰC HIỆN: không có bytes DEB được xác minh nguồn, nên chưa có SHA256, control thực, filter inject, Mach-O classes/methods, IMP, callgraph, scene settings block, ABI, postinst hoặc test thiết bị nào của v2.0.15.**
- KHÔNG nói đã phân tích binary CarBridge chỉ dựa tên selector trong DuoNavi hay source CarPlayEnable.
- Không có DEB mới, CI mới, phát hành Sileo hoặc sửa DuoFace runtime từ yêu cầu này.

## Quy trình read-only khi có DEB chính hãng đã tải bằng tài khoản Havoc hợp lệ
**Chỉ trên artifact local được chủ sở hữu cung cấp, không commit/publish binary vendor.** Có thể tạo `sideplay/audit/bridge-ui-scene-lifecycle-20261027/` report sanitized theo schema đã dùng.
1. Xác thực DEB source/provenance và snapshot SHA trước khi mở; xác nhận `Package`, `Version`, `Architecture`, `Depends`, `Conflicts`, `Replaces`, `Provides`, `Installed-Size`. Luôn giữ bản v2.0.15 phân biệt v2.0.14 và v2.0.13.
2. Dùng `dpkg-deb -f <purchased.deb>`; `dpkg-deb --ctrl-tarfile <purchased.deb> | tar -tvf -`; `dpkg-deb --fsys-tarfile <purchased.deb> | tar -tvf -`; unpack vào `mktemp -d` bằng `dpkg-deb -x` và `-e`, kiểm tra DynamicLibraries `.plist`, `.dylib`, dependencies, architecture rootless prefix. **Không cài, không gọi scripts**.
3. Xác định process injection theo đúng `.plist`: SpringBoard/CarPlay/CarPlaySupport/Dashboard/target app. Mach-O method index và disassembly bằng **các audit scripts/parsers first-party đã có** (trong `sideplay/tools` và workflow) và so SHA từng Mach-O; chưa được suy receiver chỉ từ string/selector.
4. Từ đúng IMP xác nhận các tuyến: `SBDeviceApplicationSceneEntity`, `SBAppViewController`, `sceneHandle`, `sceneIfExists`, `updateSettingsWithBlock:`, mode Live, origin proposed foreground diff, `scene monitor`/termination, scene focus/host ownership, teardown/restore, app-side hooks. Đặc biệt so bản .14/.15 nếu **có cả hai artifact chính hãng**: crash on switching và full-window regressions trên iOS16.
5. So với DuoFace .79 YouTube PID64243, TikTok PID64262, Facebook PID64281 chỉ khi có chính xác ABI/version-matched evidence; không port private foreground blocker/hooks, không tái sử dụng vendor binaries/license. Tạo design first-party và regression checks, build DEB + Sileo chỉ sau có căn cứ.

### Lệnh đọc metadata thực tế (chưa chạy vì thiếu DEB)
```bash
set -euo pipefail
DEB='/duong-dan/CarBridge-mua-hop-le_2.0.15_iphoneos-arm64.deb' # ví dụ placeholder, KHÔNG phải path đã xác minh
test -s "$DEB"
sha256sum "$DEB"
dpkg-deb -f "$DEB"
dpkg-deb --ctrl-tarfile "$DEB" | tar -tvf -
dpkg-deb --fsys-tarfile "$DEB" | tar -tvf -
```
Bảo đảm **không** chạy install/postinst, không đổi tweak trên iPhone; chỉ ghi sanitized JSON & đường dẫn SHA evidence. Chính tác giả chỉ cho tải qua Havoc, do đó **không tự lấy từ mirror không tin cậy, không bẻ entitlement/mua hàng**.

## Checkpoint và next action
- Nguồn chính: `sideplay/README.md`. Đã đọc lại code audit hiện có, workflow và hai package metadata, đã kiểm tra GitHub history.
- **Blocker duy nhất để phân tích mã máy CarBridge chính hãng:** cần **file DEB mua hợp lệ từ Havoc** (ưu tiên 2.0.15 rootless; thêm v2.0.14 nếu có để so diff). Không tự coi `com.duonavi.app` là file đó.
- Sau khi có file và SHA, chạy audit read-only trước tiên, lưu metadata/callgraph vào file tại đây; đánh dấu explicitly static vs runtime, rồi thiết kế/kiểm thử thay đổi DuoFace nếu evidence đủ.
