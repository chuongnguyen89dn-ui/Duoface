# DuoFace Native12 UI — độc lập hoá bảng chọn và bằng chứng thanh bar (2026-10-18)

## Yêu cầu và phạm vi

Người dùng yêu cầu tiếp tục tái tạo **giao diện Native12 HUD8 từ mốc gốc DuoNavi 1.0.4**. QA chỉ là lõi CarPlay độc lập có thể host ứng dụng; user đã **bác bỏ UI QA v5** do app bó, thiếu thanh bar và bố cục không giống Native. Không build/phát hành Sileo chỉ vì một số nút hoặc compile PASS. Stable Native12 HUD8 giữ nguyên. Không import vendor Dashboard, license/watchdog, installer hay sửa bản gốc.

## Chênh lệch thực tế đã sửa ở nhánh QA

| Thành phần | QA cũ | Mã hiện tại | Mức bằng chứng |
|---|---|---|---|
| Picker ứng dụng | `DFV12List : UITableViewController`, từng hàng toàn chiều rộng cao 40pt | Mới `replacement/visual12/engine/runtime/DFINativePickerCards.inc`: `DFINativePickerCardsController : UIViewController<UIScrollViewDelegate>`, card icon (44pt)/tên, grid tối đa 4 cột, card gần 84pt; recent dạng card một cột 52pt và action riêng, giữ callback `pick/touch/act`. `DFIInterface.inc` đã loại class table QA và chuyển toàn bộ đường picker sang controller mới. | Source/CI xác minh; **kích thước card chưa được xác nhận trùng pixel Native12**. |
| Header | Logo có thể nhỏ hơn 120 và 4 nút bằng chiều rộng | Trong `DFIInterface.inc`, logo tối đa 120x30; một hàng 30pt; menu native 43/51/47/51pt, gap theo phần dư; dành 48pt cho X. Điều chỉnh tỷ lệ khi màn hình quá hẹp. | Đối chiếu code approved `runtime/fullscreen/DFPickerZoomMenu.xm`, các hằng `menuHeight=30`, `logoWidth=120`, `desired[4]={43,51,47,51}`, `xReserved=48`. Responsive thu nhỏ là quyết định độc lập chứ không phải bằng chứng từ binary. |
| Root & hit region | QA fullscreen level `UIWindowLevelAlert+100` có thể che Dock/status bar CarPlay | Giữ window level hiện tại, **không sửa mù**. `DFIInterface.inc:viewDidAppear` ghi snapshot các UIWindow thấy được trong SpringBoard (class/level/hidden/frame/safeArea), và ghi rõ đây không chứng minh cửa sổ CarPlay-process có/không. `DFIChrome.inc:DFIChromeInstall` ghi snapshot thật `DBStatusBarWindow`, `CARStatusBarWindow`, `DBDockWindow` ở CarPlay process, trước khi `DFIChromeApply`. | Source/compile pass, **chưa có log thiết bị v6 để xác nhận status bar**, chưa sửa window level. |
| Legacy acceptance test | `verify_full_ui_parity.py` còn yêu cầu `DFV12List` | Đã đổi yêu cầu sang `DFINativePickerCardsController`; `test_native_shell_structure.py` kiểm tra card owner, absence table, header widths và callback. | Build and static source check PASS. |

Điểm tham chiếu original104: `audit/duonavi-original104-ui/ORIGINAL104_UI_CALLCHAINS.json` chứa `CBWindow.showAppPickerForSlot:` gọi overlay picker; `audit/v12-picker-sheet-geometry-20261014.txt` có `CBMultitaskingOverlayView setupAppPickerCardsInCardW:cardH:contentY:`. Các method chứng minh app picker là **card UI của overlay**, không phải danh sách QA; chưa có bằng chứng exact number of columns/padding trên mọi head unit. Đã giữ source `DFINativeShell.inc` với window/split/pill/divider/picker class riêng.

## Kiểm thử và giới hạn

- Branch `feature/visual12-duodash-recovery`.
- Commits liên quan: `8d45a879fe78c0b39137a57b6b899d019830007d` tạo cards; `443bcc617e7eea4e9d0545fb50e23b2df6c3790f` đổi owner; `9e4435bcea6d3484116699840a821362d37eae35` căn chỉnh header; `03867903f99a75c56c2c96f1a8857fe388d6e273` thêm kiểm thử; `8f9b617dbff59e6e3e51b6ee8d51fff2310f4173` cập nhật verifier; `806f5e35d171ad6365fbabe86a37a18e14c601b5` sửa nhận dạng recent; `767fc526acf672d5c51c1a056db23210f4556d41` và `9b46f8d76974dc6a179c748fe21e30956f7a354e` thêm log cửa sổ.
- [Actions 39096952259](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39096952259), commit `9b46f8d`, **SUCCESS**, job `117585288987`; bước test view tree PASS, compile/link iOS arm64 PASS, lifecycle / package boundary PASS, uploaded **compile-only dylib**. **Không** phải DEB hay chạy trên máy.
- [Actions 39096819518](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39096819518) **FAILED** tại test structure trên commit trung gian do test đòi verifier mới chưa có; sau đó đã chỉnh verifier và đạt Actions 39096952259. Không ghi thất bại đó là lỗi iOS compiler.
- Workflow `.github/workflows/duoface-visual12-standalone-qa-deb.yml` giữ **workflow_dispatch manual-only**, không xuất bản một bản QA ngoài ý muốn; Sileo mới nhất vẫn `com.duoface.visual12 1.0.3-12~ui8native5` mà user đã bác bỏ, Native12 HUD8 `com.duoface.independent` giữ nguyên. Bản v6 artifact tham khảo `dist/visual12-native-shell6-visual-qa/` là bản **trước các sửa picker cards trong lần này**, không được giới thiệu là bản mới đã nghiệm thu.

## Điểm tiếp tục

1. Kiểm tra có cập nhật song song trên GitHub không; đọc lại handoff trước khi sửa. Đọc các file trên và `runtime/fullscreen/DFPickerZoomMenu.xm`.
2. Vẫn thiếu **screenshot thực tế của màn xe cho source mới**, log SpringBoard/CarPlay process và tỷ lệ pixel gốc. Xác định rõ user đề cập thanh trạng thái/Dock CarPlay hay menu trong picker bằng bằng chứng hình ảnh; không tự đẩy xuống/hạ windowLevel.
3. Tiếp tục tái tạo native picker hierarchy đúng tab/row/border/logo và các bố cục, thực hiện UI-only screenshot acceptance ở độ phân giải CarPlay thật. Nếu cần test Sileo, chỉ build/publish gói QA riêng **sau** khi source visual gate đạt và có kế hoạch test rõ; tuyệt đối không thay Native12 stable.
4. Không nói lỗi app bó, exitMode hoặc HUD speed đã được sửa nhờ source/CI PASS; chúng không nằm trong phạm vi kiểm chứng lượt này.
