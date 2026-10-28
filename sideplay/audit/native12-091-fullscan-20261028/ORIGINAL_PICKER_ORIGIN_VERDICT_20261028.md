# Đính chính từ quét ARM64: Native12 App CarPlay khác màn quản lý Apps trên iPhone (2026-10-28)

**Chạy MỚI ĐÃ THÀNH CÔNG:** GitHub Actions [40699487806](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40699487806), job 122855086274 SUCCESS. Original DEB SHA256 2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad được kiểm tra, hai original Mach-O SHA-check, tổng **12 original ARM64 Objective-C method bodies** được trích theo địa chỉ IMP. Evidence full 171755-byte JSON và 16873-byte Markdown đã được GitHub Actions tự commit ở thư mục original-app-picker-single-vs-bulk-imp/. Đây là static audit, KHÔNG phải thử UI thiết bị.

## 1. CarPlay: một ứng dụng cho một ô (đã chứng minh luồng mã máy)

- CBMultitaskingOverlayView.showAppPickerForSlot:parentView: @0xaa800 đọc splitPreset/splitRatio/splitApp1..4 và mở picker cho slot.
- CBMultitaskingOverlayView.appSelected: @0xa9ea8 lấy tapped-card tag, bundleIdentifier @0xa9f38, lưu 1 ứng dụng/1 slot qua saveSlotIndex:bid:toSettings:prefs: @aa178/aa1dc, sau đó swapSlot:withSlot: @aa330 HOẶC replaceAppInSlot:withBundleIdentifier: @aa438, dismissOverlay @aa40c/aa450.
- saveSlotIndex:bid:toSettings:prefs: @0xa9d1c ghi splitApp1/2/3/4 và splitLeftBundleID/splitRightBundleID, đều là trạng thái từng ô.
- Không có bằng chứng picker này cho phép chọn hoặc bật nhiều app trong một thao tác. Không áp dụng các hàm Enable All của iPhone vào menu App của CarPlay.

## 2. CarPlay Add More Apps thực tế là một thông báo, KHÔNG phải multiselect

- addMoreAppsTapped: @0xa7f20 (991 ARM64 instructions) dựng custom frosted modal; label ADD_MORE_APPS_ALERT_TITLE @a864c, ADD_MORE_APPS_ALERT_MSG @a89a8, ADD_MORE_APPS_ALERT_OK @a8bc4, icon iphone.and.arrow.forward @a87ac và dismissCustomAlert: @a81ac.
- Đây là UI giải thích/hướng tới iPhone. Nội dung chuỗi đã dịch trên màn vẫn cần truy nguồn localization. Không có chứng cứ trong method body này về trình chọn hàng loạt trong CarPlay.

## 3. Enable All/Disable All là menu trong ứng dụng iPhone gốc

- CBAppsManagerViewController.showActionMenu @0x100013604 trên original DuoFaceUI app có alertControllerWithTitle:message:preferredStyle: và ROW_ENABLE_RECOMMENDED @0x1000136a0, ROW_ENABLE_ALL @0x10001374c, ROW_DISABLE_ALL @0x1000137d4, CANCEL @0x10001385c, presentViewController @0x10001395c.
- CBAppsManagerViewController.appSwitchToggled: @0x100013ab4 đọc trạng thái isOn rồi gọi CBAppManager.setApp:enabled: @0x10000960c; enableAllApps @0x100009690; disableAllApps @0x100009f1c; enableAllUserApps @0x100009820, các hàm đều xử lý preferences.
- Kết luận đủ cơ sở: bản gốc có **menu bật/tắt hàng loạt trong phần quản lý ứng dụng iPhone**, nhưng **không đồng nghĩa CarPlay picker có đa chọn**. Báo cáo trước trộn hai giao diện là sai.

## 4. Khác biệt catalog chính xác giữa Native12 và DuoFace .91

- Original CBMultitaskingOverlayView.loadInstalledApps @0xa0c48: trước khi gọi LSApplicationWorkspace.allInstalledApplications @a0dac, đọc CBDashboardSettings.bridgedApps @a0cd0, count @a0cf0; có containsObject: @a1200, categoryRank @a10b4/a13ec, và sortUsingComparator @a14c8. Danh sách CarPlay chịu ảnh hưởng cấu hình app đã enable ở iPhone; cần giải kỹ fallback khi bridgedApps rỗng để biết phạm vi chính xác.
- New DuoFace .91 DFAppLibrary.m gọi allInstalledApplications, lọc DFIsEligibleAppID, sắp xếp tên; **không có gate dựa trên bridgedApps do iPhone bật**. DFAppPickerVC.m hiển thị danh mục rộng qua nhiều card/page nhưng didSelectItemAtIndexPath: chỉ dispatch một bundleID; *nhiều card hiển thị* khác *multi-select*.
- Vì vậy việc người dùng thấy chọn ứng dụng quá nhiều không đồng nghĩa bản gốc có chức năng chọn hàng loạt. Cần tái tạo đúng danh mục whitelist và App per-slot, không tự dựng giao diện bulk picker.

## 5. Bằng chứng & trạng thái

- New run 40699487806 SUCCESS, original IMP extract saved: sideplay/audit/native12-091-fullscan-20261028/original-app-picker-single-vs-bulk-imp/ORIGINAL_PICKER_VS_SETTINGS_IMP.json + REPORT.md.
- Historical true original Add More and loadInstalledApps: sideplay/audit/native12-app-2debs-20261023/runs/39895316677/extra-original-app-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json.
- Original picker appSelected: evidence: sideplay/audit/native12-continuation-4888299/original-picker-close-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json.
- Independent .91 source provenance commit 4dba11e1a95e237f966b44292b9b486a837a8f90: sideplay/duoface-native-scene-host/DFAppLibrary.m, DFAppPickerVC.m, DFNativeHostRootController.m.

**Chưa làm:** full C/indirect graph, original localization precise text, on-car touch/screenshot test; chưa sửa runtime, chưa build/publish DEB. Next: original iPhone Apps Manager persistence callbacks, native catalog enabled-list/fallback, then other UI controllers and scene lifecycle. Vendor license code remains excluded.
