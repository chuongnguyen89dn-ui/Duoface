# QA7 đang cài ↔ Native12/HUD8 — đối chiếu đường gọi source theo chức năng (2026-10-18 ICT)

## Cơ sở / phạm vi

- **USER-VERIFIED:** máy đang dùng **QA7**; đồng bộ tương đối tốt, còn nhiều khác biệt với Native12, **thanh CarPlay không hiện**. **Chưa có log/ảnh mới** để nhận diện subclass/window có lỗi.
- **QA7 published**: `com.duoface.sideplaydisplay 0.1.5~native12visual7`; artifact SHA256 `c221584b16af24f844dbb968d90ffbcd6efbbc64a312a6582d955fc45348901d`, branch `feature/duoface-native12-qa8-late-host-bootstrap:sideplay/artifacts/native12visual7/`, mã nguồn chuẩn release commit `beafe5b6ab020859b82e627ca635046796d9d956`. Sileo workflow `carplaydsp:main:.github/workflows/build.yml` vẫn pin QA7. **QA8 0.1.6 chưa phát hành**, không coi QA8 đang chạy máy.
- **Native12+HUD8 reference**: `com.duoface.independent 0.1.0~native12+speed8compact`, SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`; source-owned handlers `runtime/fullscreen/DFDashboardChrome.xm` (`2abbaa94...`), `DFFullscreenCoordinator.mm` (`45cda41e...`), `DFFullscreenTransport.mm`, `DFHostGeometry.xm` (`6ca7011...`), `DFPickerZoomMenu.xm`, `src/DuoFaceVisualHook.m`, `src/DuoFaceBorderRunner.m`; class trong native binary CB* thuộc payload gốc, không phải source được truy xuất đầy đủ.
- **SidePlay gốc**: 1.0.4-1, SHA256 `7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c`; `sideplay/native12-display/audit/SIDEPLAY_SPLIT_OWNER_SELECTORS.json` kiểm kê class `SPDash` **154** method, `SPPane` **127** method nhưng curated selector chỉ **66** và **30**; không được gọi đây là method-level toàn diện.
- **New whole-binary scanner**: `sideplay/tools/audit_qa7_native12_method_abis.py`; workflow `.github/workflows/sideplay-qa7-native12-method-audit.yml` pin SHA cả ba DEB, quét arm64 method lists/IMP/class/categories và LC_FUNCTION_STARTS, lưu `sideplay/audit/qa7-vs-native12-methods-20261018/METHOD_AUDIT.md`, `method-index.json`, `summary.json` và Actions raw otool gzip. **Trạng thái tại thời điểm viết: workflow được COMMIT, chưa xác nhận workflow thành công/đã persist output.** Không báo Method-index đầy đủ nếu chưa có file thật và cross-check SPDash/SPPane count.

## Call graph thanh bar Native12 (nguồn source, không suy đoán)

**Native12/reference**:
1. `DFRuntimeEntry.mm:DFCandidateAdapterEntry` bootstrap trong SpringBoard **và** `com.apple.carplayapp/com.apple.carplay/com.apple.dashboard`.
2. `DFFullscreenCoordinator.mm:DFStartFullscreenAdapter`: SpringBoard cài `DFInstallPickerZoomMenuHooks` + `DFStartFullscreenTransport(YES)`, phía CarPlay cài `DFInstallDashboardChromeHooks` + `DFStartFullscreenTransport(NO)` và receiver thông báo distributed.
3. `DFEnterFullscreen` → `DFRequestHostFullscreen(YES, completion)` → chỉ sau host ACK mới gọi `DFDashboardSetChromeHidden(YES)` → xác nhận host+chrome, rollback khi thất bại.
4. `DFExitFullscreen` → `DFRequestHostFullscreen(NO, completion)` → chỉ sau restored ACK mới `DFDashboardRestoreChrome()`.
5. `DFDashboardChrome.xm` hook `DBStatusBarWindow.layoutSubviews` hoặc `CARStatusBarWindow.layoutSubviews` **trong CarPlay process**; snapshot trạng thái `window.hidden`; restore về trạng thái cũ. **Lưu ý:** Restore không tự tạo thanh nếu hệ thống/SidePlay đã ẩn nó từ trước. Không thể suy ra thanh thực luôn hiện chỉ từ hàm.
6. `DFHostGeometry.xm`: `CBBridgeManager.sharedInstanceIfExists`, `CBWindow`, `CBBridgedSplitApp` có owner-check; dùng `CBWindow.carPlayUsableBounds`, `carPlayScreenBounds`, `resizeWindows` và lưu original để rollback.

**QA7 đang cài**:
- `sideplay/sileo-qa/DuoFaceSidePlayDisplayQA.plist` chỉ inject **SpringBoard**. `Tweak.xm:DFSPApply` gọi `DFSPNative12Host.applyNormal/applyFullscreen`, đổi `window.windowLevel` thành `UIWindowLevelStatusBar-1` khi Normal; `DFSPNative12Host.m:applyNormal` chỉ set `rootView.frame`; `DFSPSystemUsableRect` nếu insets 0 dùng left64.
- **Không có** source-owned distributed command/ACK từ host tới CarPlay process, không có `DFDashboardChrome` receiver/hook trong QA7; không có kiểm tra statusBarWindow thực tế. **P0 architecture gap** giải thích vì sao không có bảo đảm khôi phục thanh bar. Đây là lý do từ mã, **không đủ khẳng định subclass nào bị ẩn trên máy**.
- Không sửa bằng cách co lại `UIWindow.frame`, ép `windowLevel` hoặc đổi 64pt. Cần trace correct host/window + bar receiver với CarPlay thực và an toàn scene.

## QA7 bỏ qua chính các hàm định kích thước CarPlay của SidePlay

Đối chiếu chuỗi thực thi **Tweak.xm tại commit QA7 release** `beafe5b6...`:
- `-carWindowFrameNow`: **1 lần xuất hiện và chỉ ở khai báo `@interface SPDash`**, **0 lần gọi thực thi**.
- `-setCarWindowFrame:`: **1 lần xuất hiện chỉ ở khai báo**, **0 lần gọi**.
- `-carDockMode`: khai báo 1 lần + một lần trong comment nói không cưỡng ép `carDockMode=NO`; **0 lần dùng để tính usable bounds**.
- `DFSPSystemUsableRect`: 3 lần trong logic, tự lấy `window.safeAreaInsets` và dùng lề trái 64pt nếu inset không xác định.

Trong SidePlay gốc, selector audit xác minh `SPDash.carWindowFrameNow` tại IMP `0x17df0`, `SPDash.carDockMode` tại `0x17b78`, `SPDash.layoutRootView` tại `0x1a2f0`, `SPDash.saveManualCarArea:windowBounds:` tại `0x197b0`. Vì vậy QA7 **chưa đọc đúng cơ chế mode/area đang được SidePlay sử dụng** dù đã khai báo selector. Đây là sai khác **có bằng chứng ở đường gọi**, không chứng minh trực tiếp window nào che thanh bar trên máy. Khi sửa phải lấy dữ liệu usable/chrome từ owner đáng tin và trạng thái trên xe, không đơn giản gọi `setCarWindowFrame:` vì nó có nguy cơ crop scene.

## Đường gọi chức năng: Native12 → QA7 → SidePlay

| Nhóm | Native12/HUD8 có gì | QA7 đang làm | Độ tương đồng chắc chắn |
|---|---|---|---|
| App/scene host | `CBBridgeManager` → `CBWindow` → `CBBridgedSplitApp` → native hosted scenes | `SPDash`/ `SPPane` owner; `Tweak.xm:%hook SPDash.setCarWindow/layout/layoutRootView` vẫn `%orig` | **Khác owner**; host SidePlay hoạt động nhưng không độc lập |
| Native usable geometry | `CBWindow.carPlayUsableBounds`, `resizeWindows` gắn owner check | `DFSPSystemUsableRect` dựa `UIWindow.safeAreaInsets` / left64, `DFSPNative12Host` set `rootView.frame` | **Không tương đương**; chưa biết real window hierarchy |
| Native chrome | `DFDashboardChrome` + `DFHostGeometry` + cross-process ACK | Không có module CarPlay chrome; chỉ đổi z-order/usable rect | **Thiếu P0** |
| Start screen | `CBSplitSplashScreenView` native controller, `DuoFaceUI.app` | SidePlay `SPLoadingView`, own `DFSPNativeFrame` gắn sau `setCarWindow:` | **Chưa thay splash/owner** |
| Pill 2 app | `CBSlotPillView`, `CBMultitaskingOverlayView`, `DuoFaceVisualHook` | 2 `DFSPNativeSlotPill` dùng kích thước 38/44/64/72/76/80 × 19/22; top-center `CGRectGetMinY(rect)+3` chưa real QA | **Partial**, user đã thấy phần đồng bộ tốt |
| App picker | Native overlay app catalog/recent/native owner | `DFSPNativeFrame.menuTapped` → `DFSPNativeAdapter.nativeFrameRequestedAppForSlot` → `SPDash.showPickerForPane:` | **Vẫn SidePlay picker** |
| Style 8 layouts | Native `CBBridgedSplitApp` layouts/3-pane/owner/fraction | `nativeFrameRequestedStyle` → `SPDash.layoutChooser`, UI chỉ đọc 2 pane | **Chưa đủ** |
| Divider | `CBDividerView` pan/change ratio, `DuoFaceLogoGripOnly` (hold 0.30s) | `DFSPNativeFrame.dragDivider` → `SPDash.setRatio:` + `layout:`, logo hold/tap; binary native callback owner khác | **Partial**; edge formula khi đảo pane khác 1/2 vẫn sai |
| Red border | `src/DuoFaceBorderRunner.m`: 1pt RGB 227,2,15 khi hoạt động, idle clear, fullscreen hidden | Không có border-owner/time/session hooks như Native12 | **Chưa đủ** |
| Fullscreen focus vs Zoom | Native per-pane focus/restore tách menu Zoom, dashboard cross-process | QA7 per-pane focus dùng `SPPane.layoutInFrame:scaleMode:`; menu Zoom dùng QA apply root frame | **Partial**; layout scene/hit-test chưa QA |
| Speed HUD8 | `DFSpeedNativeHUD`, `DFSpeedSplit7Driver`, `DFOwnerPollingDriver`, real settings | Không có `DuoFaceSpeedHUD/SpeedOwner` trong gói QA7; SidePlay gốc có HUD provider/relay riêng | **Chưa chuyển HUD8** |
| iPhone prefs | `DuoFaceUI.app`, native settings | QA7 không có iPhone app, phụ thuộc SidePlay app/prefs | **Chưa chuyển** |
| Legacy UI | Native UI own renderer | `DFSPHideReplacedView` chỉ set `hidden=YES` cho `chipView/layoutButton` và placeholder khi install; `DFSPRestoreReplacedViews` khôi phục | **Vẫn chạy SidePlay display, chưa remove toàn bộ** |

## Root-cause confidence / next actions

- **CONFIRMED FROM CODE:** thiếu process-level CarPlay chrome receiver/ACK trong QA7; App/Style do SidePlay dựng; original old UI không xóa; chưa có HUD8/settings/native 8 layouts; divider reversed pane formula không đúng khi lệch tỷ lệ; QA7 source Native frame + Host SHA `58a775d...` và `31f311f...` khớp nhánh QA8 (QA8 chỉ thêm lazy bootstrap).
- **UNVERIFIED ON DEVICE:** `DBStatusBarWindow` hay `CARStatusBarWindow` có tồn tại trên head unit cụ thể; trạng thái `hidden`; SidePlay `carDockMode`, layering & root transforms; scene rơi sau detach/reconnect; gesture hit-test; chính QA7 installed byte version. User cho biết version QA7 là dữ liệu device-reported.
- **P0**: đọc lại tất cả class/method raw report khi CI sẵn sàng, kiểm tổng count class SPDash/SPPane với audit gốc; phân loại chức năng 1:1, chỉ chấp nhận có bằng chứng code hoặc runtime; dựng chính xác owner/ACK iOS16 CarPlay mà không đổi vendor binary. **Không publish/cài QA8; không sửa Native12/HUD8**, giữ gói QA7 vì user báo đồng bộ khá tốt.
- **QA chỉ compile ≠ runtime**: mọi sửa về chrome cần QA candidate độc lập với log class/process, ACK, window hierarchy, và test CarPlay thực trước release.
