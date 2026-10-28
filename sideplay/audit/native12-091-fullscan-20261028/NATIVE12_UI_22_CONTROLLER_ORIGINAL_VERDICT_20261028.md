# Bổ sung 22 hàm giao diện Native12 gốc — iPhone/CarPlay split, picker, pill, logo, Settings

Ngày 2026-10-28. Original-only ARM64 static audit, không nhập proprietary runtime / giấy phép, không build DEB, không test xe.
**GitHub Actions run [40700551205](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40700551205) SUCCESS**, output đã lưu trong `sideplay/audit/native12-091-fullscan-20261028/original-ui-controller-22-imp/` (JSON 339576 bytes, REPORT.md 35140 bytes), commit artifact `f34b1ee22a97cd8e34aa54de057a38f8bd334f1d`. 22 Objective-C method bodies thực sự được trích, mọi selector/cfstring callsite dưới đây lấy từ dữ liệu mới.

## Phát hiện 1: có ba luồng riêng, KHÔNG có CarPlay batch picker

| UI original | Bằng chứng mã máy | Ý nghĩa chính xác |
|---|---|---|
| CarPlay CBMultitaskingOverlayView.appSelected: | 12-method original batch run 40699487806: 0xa9ea8 -> saveSlotIndex:bid:toSettings:prefs: -> swapSlot:withSlot: / replaceAppInSlot:withBundleIdentifier: -> dismissOverlay | Chọn một ứng dụng cho một slot, không multi-select |
| iPhone CBAppPickerViewController.tableView:didSelectRowAtIndexPath: @0x10001550c | Đọc filteredApps, row, bundleIdentifier, disabledBundleIDs, onSelectApp, popViewControllerAnimated: | **Một app cho một slot trên giao diện cài đặt iPhone**; kiểm tra app đã dùng ở ô khác qua disabledBundleIDs. `IN_USE_ELSEWHERE` ở rendering @0x100014f1c; chưa test chữ hiển thị thật |
| iPhone CBAppsManagerViewController | setupNavigationItems @0x100011634 có ellipsis.circle -> showActionMenu; tableView:cellForRowAtIndexPath: @0x100013d94 tạo appSwitchToggled: / setOn; didSelect @0x1000143ec gọi setApp:enabled: | **Màn bật/tắt nguồn app** tách khỏi chọn một app cho một slot. IPhone ShowActionMenu chứa Enable Recommended/All/Disable All (batch trước) |
| CarPlay Add More | addMoreAppsTapped: @0xa7f20 dựng frosted info alert, label ADD_MORE_APPS_ALERT_TITLE/MSG/OK và icon iphone.and.arrow.forward | Không phải menu chọn hàng loạt trong CarPlay |

**KẾT LUẬN:** iPhone gốc có cả app manager (cho phép toggles/bulk enable) và picker CHỌN MỘT APP khi cấu hình slot. CarPlay cũng chọn MỘT app vào một slot. Mượn hàm enableAllApps của iPhone để yêu cầu CarPlay picker đa chọn là **SAI**.

## Phát hiện 2: iPhone Split Settings gốc không phải tab Bố cục 9 dòng đơn giản

- CBSplitViewController.tableView:cellForRowAtIndexPath: @0x100017154 (490 instructions) đọc splitPreset, slotTitleForIndex:preset:, slotName1..4, slotApp1..4, presetTitleForIndex: và icon geometry; có các dòng ứng dụng cụ thể theo ô.
- CBSplitViewController.tableView:didSelectRowAtIndexPath: @0x1000178fc (299 instructions) đọc slotCountForPreset:, app1..4 và availableApps, tạo CBAppPickerViewController (setApps:, setDisabledBundleIDs:, setOnSelectApp:) và pushViewController:animated:. Một nhánh chọn preset gọi setSplitPreset:, saveSettings, reloadData.
- DuoFace .91 DFNativeHostRootController.m tại tab Bố cục hiện hiển thị 9 preset và một lệnh Maps QA; **thiếu luồng chọn từng ứng dụng cho slot từ iPhone** như gốc. Đây là khoảng thiếu source-level quan trọng hơn việc tạo thêm bulk app tiles.

## Phát hiện 3: App pill, Divider và Focus gốc có callback cụ thể

- CBSlotPillView.dotsTapped: @0x85580 -> bounceButton:, noteUserActivity, onPillTapped.
- CBSlotPillView.expandTapped: @0x85698 -> bounceButton:, noteUserActivity, onExpandTapped.
- CBSlotPillView.restoreTapped: @0x857b0 -> bounceButton:, noteUserActivity, onRestoreTapped, onPillTapped (các ref xuất hiện trong hàm, chưa chứng minh luôn cùng xảy ra).
- CBDividerView.handleMoveButtonLongPress: @0x1005f4 (155 instructions) có UIGestureRecognizer.state, onActivity, onRotate, onSwap; TouchDown @0xffbf8 và TouchUp @0xffeb4 điều phối onActivity và onSwap. Cơ chế giữ 3 giây là **yêu cầu tùy chỉnh của người dùng**, không tuyên bố đây là thời gian original. Current .91 DFNative12Chrome.logoTouchDown/Changed/Finished bắt đầu kéo ngay, chưa đạt yêu cầu 3s.
- CBBridgedSplitApp.moveSlot:direction: @0x108f28 (40 instructions) dùng count và swapSlot:withSlot:; rotateAllSlotsClockwise @0x106560 (97 instructions) cũng dùng count và swapSlot:withSlot:. DuoFace .91 hiện dựa trên swapped boolean cho hai ô; chưa có điều phối vòng slot 3/4 ô tương ứng.
- CBBridgedSplitApp.focusSlot:animated: @0x105890 / restoreSplitAnimated: @0x105e2c gọi **sendStateToApp:shouldBridge:**, saveBridgeStateToDisk, layoutSplitViews và UIKit animations. Quan hệ thay đổi trạng thái app khi Focus/Restore có bằng chứng mã máy; không nên coi chỉ thay frame / Zoom menu là giống original.

## Phát hiện 4: các trang iPhone Settings đã có hành động cụ thể trong DEB

- CBGeneralSettingsViewController.tableView:cellForRowAtIndexPath: @0x10000ece0 (1441 instructions) dùng ROW_HIDE_LABELS (hideLabelsToggleChanged:), ROW_SCREEN_BLANK (screenBlankToggleChanged:), ROW_LANGUAGE, ACTION_RESET_DEFAULTS, ROW_AUTO_LAUNCH (autoLaunchToggleChanged:), ROW_DOCK_MONITOR (dockMonitorToggleChanged:) và các mục About/CarPlay status.
- didSelectRowAtIndexPath: @0x100010364 điều phối performResetDefaults, showLanguageSelectionSheet, performRespring và mở trang Subscription. **Subscription/license bị loại khỏi DuoFace độc lập**, không được tái tạo hay bypass.
- DuoFace .91 app iPhone hiện chỉ có Status/Ứng dụng/Bố cục với danh sách đơn giản; các settings tương ứng **không được nối như UI gốc**.

## Phạm vi và giới hạn

Original DEB SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`; exact 22 IMP method bodies stored in `sideplay/audit/native12-091-fullscan-20261028/original-ui-controller-22-imp/ORIGINAL_UI_CONTROLLER_IMP.json` and REPORT.md. New workflow `.github/workflows/duoface-native12-ui-controllers-22methods-original-20261028.yml` commit `769c19120f2cb52045cce25161d553072341961d` corrected archive path. **Earlier run 40700217106 falsely appeared successful for 22-IMP archival due old SUB and upload path**; do not count it as persisted evidence. Correct run 40700551205 has uploaded and archived actual 22-IMP JSON, read back.

Next action: investigate original native scene owner/foreground/reconnect IPC and image dimensions/hitboxes, then wire only first-party equivalents. This scan confirms 22 method callsite sets, NOT every block/indirect control flow, runtime callbacks or pixel parity. .91 binary/source unchanged and Sileo unchanged.
