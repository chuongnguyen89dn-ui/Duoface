# Kiểm toán hình học/toàn bộ giao diện — QA5 thực tế so với DuoFace Native12 HUD8

**Ngày kiểm:** 2026-10-18 · **Mức độ:** static/source + ảnh người dùng (KHÔNG có log frame thiết bị).
**Chuẩn duyệt:** DuoFace Native12 + HUD8. SidePlay dùng làm host scene tạm thời, tuyệt đối không dùng layout/skin SidePlay làm giao diện chính.

## Dữ liệu đối chiếu

- User screenshot `IMG_7962(1).jpeg` của phiên CarPlay sau cài QA5: Home CarPlay lộ ngoài cửa sổ ở hai mép, vùng nội dung không ăn khớp; pill từng ô ở giữa chiều cao (bản QA5 phát hành); thanh app CarPlay chưa trở lại; nội dung app/scene bị co cắt. Đây là **quan sát**, không quy nguyên nhân cho một API duy nhất khi thiếu log.
- Approved history: root `tiep tuc du an.md`; `feature/visual12-duodash-recovery:ban giao du an duoface moi.md`; `docs/duoface-native12-comprehensive-dimensions-20261018.md`, `docs/duoface-native12-pill-divider-arm64-evidence-20261018.md`.
- Approved independent geometry reference `feature/visual12-duodash-recovery:replacement/visual12/engine/DFILayouts.h` (`DFIFramesMake` supports 1–8), `replacement/visual12/engine/runtime/DFIInterface.inc`; real Native12/original104 disassembly report `audit/native12-deb-original104-ui/ORIGINAL104_LAYOUT_PILL_MODE_ARM64.txt`.
- **QA5 actually linked:** `sideplay/sileo-qa/Makefile` includes only `Tweak.xm`, `DFSPNativeFrame.m`, `DFSPNativeSlotPill.m`; does **NOT** compile `DFSPNative12Host.m`, `DFSPNative12ChromeOwner.m`, `DFSPDisplayCoordinator.m`, `DFSPDisplayState.c`. Their **existence in repo is not deployment**.

## Điểm không tương đương — không được ghi QA5 = Native12

| Priority | Chỉ tiêu / Native12 target | QA5 source hiện tại | Bằng chứng / kết luận |
|---|---|---|---|
| **P0** | Window full-screen, app surface restricted to usable bounds; native CarPlay bar visible in Normal | `Tweak.xm:DFSPApply` sets `window.frame=desired`; `layoutRootView` repeats; `carWindowFrameNow`/setter overridden | **SAI OWNER**: resize UIWindow instead of its content root; Home wallpaper/tiles leaking in screenshot. Not a fixed native bar |
| **P0** | Native bar controlled by distinct owner with ACK, visible on connect & Zoom Out | No `DFSPNative12ChromeOwner` or `DFSPDisplayCoordinator` in Makefile or tweak | **NOT WIRED**. `window.windowLevel=UIWindowLevelStatusBar-1` and `carDockMode=NO` are not system-bar controls |
| **P0** | Correct usable area measured in CarPlay window/scene coordinates | `DFSPSystemUsableRect` uses `window.screen.bounds` and `window.safeAreaInsets`, fallback left **64pt**; no explicit transform from screen to content owner before changing window | **PARTIAL / RISK**: 64pt is original104 constant, not a confirmed screen-specific CarPlay inset; no orientation/scale validation |
| **P0** | 8 layout shapes (1–8), 1–3 real panes, 0–2 dividers | `DFSPNativeFrame` creates fixed **2 pills, 2 placeholders, 1 divider**, stores `firstRect/secondRect` only | **NOT PORTED**: cannot produce 3-pane styles 4–8; own frame controller has no 8-layout state |
| **P0** | 2 independent fractional layout parameters on 3-pane layouts | `currentRatio` only, `SPDash.setRatio:` adapter; no `secondary` | **NOT PORTED**. A single ratio cannot reproduce all 8 original shapes |
| **P0** | Application scene/client frame updates consistent with visible pane after drag/focus/Zoom | `SPDash.layout:` + `SPPane.layoutInFrame:scaleMode:` reused; no confirmed `applySceneFrame:/restoreSceneFrame` sequence on host | **UNVERIFIED** on two live CarPlay apps; screenshot shows clipping/rotation indicators, needs logs |
| **P1** | Divider line coincides with actual pane boundary and follows continuous ratio drag | `DFSPNativeFrame:dragDivider:` sends ratio, `layoutSubviews` positions line from `firstRect/secondRect`; `DFSPRefresh` reconstructs those from `SPPane.view.frame` while `DFSPUpdatingRatio` suppresses interim refresh | **PARTIAL / LIKELY LAG**: logical ratio update and rendered divider use different frames; observed drag moves content yet bar stays near center. Needs before/after ratio + actual pane rect log |
| **P1** | Logo 28/30pt according divider length 280pt, hold 0.30s moves along line, tap swap | Source renders 28/30pt, recognizers, position `logoRelativePosition` | **CODE PRESENT**, but gestures/position after layout/style/reconnect NOT DEVICE-PROVEN |
| **P1** | Per-pane pill 6 widths 38/44/64/72/76/80pt, heights 19/22, radius11 | `DFSPNativeSlotPill` implements all six; compact rule width<320 / height<220 is original104-based heuristic | **SIZES PORTED; state trigger not runtime-verified** |
| **P1** | Two pills at **TOP CENTER of each pane**, App + Expand / Restore separately | Published QA5 midY-center; feature source was corrected to `x=midX-width/2, y=minY+3pt` | **SOURCE CORRECTED, NOT PUBLISHED/DEVICE-PROVEN**. +3pt is reference-based trial offset, not a DEB-verified global alignment |
| **P1** | No duplicated old/new placeholder; conceal only replaced SidePlay UI | `DFSPHideReplacedView` hides `chipView/layoutButton` and text matches; QA's own extra big “＋ Chọn ứng dụng” still appears below pill; SidePlay picker/Style still run | **OVERLAP / PARTIAL**; dangerous to blanket-hide scene view |
| **P1** | App/Zoom/Style/Close menu uses native sheet, startup and picker cards | QA own sheet; App calls `showPickerForPane:`, Style `layoutChooser`, startup `SPDash.setCarWindow:` | **VISUAL/BEHAVIOR NOT PORTED**; SidePlay old App/Style surfaces remain |
| **P1** | Native12 speed HUD8 104×46pt + 34pt speed limit circle | No HUD8 owner in QA5 Makefile | **NOT PORTED** |
| **P1** | Split focus vs whole-CarPlay Zoom independent, ratio preserved across Restore | Separate QA5 callbacks exist. Focus host sets pane union frame and hides sibling, restore calls `SPDash.layout:NO` | **PARTIAL** until 2 live scene resize/touch and app orientation verified |
| **P2** | Approved menu 30pt, logo 120×30pt, icon 16/label10, panel blur radius20 no outline | Code uses 30pt menu, logo image staged, but sheet height/formula and presentation changed | **VISUAL PARTIAL**; QA colors/insets not confirmed from device |

## Root-window/CarPlay bar — immediate correction boundary

Source `DFSPNative12Host.m` **already exists** and implements an isolated pattern (leave `UIWindow.frame` untouched, position `contentRoot.frame` inside window, restore snapshot) with strict checks. `DFSPDisplayState.c` + `DFSPDisplayCoordinator.m` schedule **SHOW_BAR → HOST_NORMAL**, **HOST_FULL → HIDE_BAR**, **SHOW_BAR → HOST_NORMAL** on Zoom Out. `DFSPNative12ChromeOwner.m` can change `hidden` only on **caller-verified** real CarPlay chrome windows; caller/owner binding is currently absent.

**Do NOT blindly link these modules or hide arbitrary system windows**: status bar and sidebar might belong to different process/windows, and source has no verified runtime class/owner binding. Next code change must (1) replace whole-UIWindow contraction with full-window + content-region owner, preserving scene orientation; (2) discover correct real chrome owner and require ACK; (3) measure both windows/panes/scene relative to same window coordinate space; (4) retain reversible rollback to QA3/original SidePlay when geometry validation fails. Build only after static/iOS tests, Sileo only after QA package verification.

## Minimum exact device log required

For `connect`, `layoutRootView`, `setCarWindowFrame:`, drag began/changed/ended, `Zoom In/Out`, `disconnect`: record `screen.bounds`, `window.bounds/frame/safeAreaInsets/windowLevel`, `rootView.frame/bounds`, `SPDash.ratio/split`, `SPPane[0..2].view.frame`, `sceneViewOrientation`, `scaleMode`, `sceneSize/sceneFrameChanged`, `DFSPUI.firstRect/secondRect`, divider x/y, pill x/y, and system bar visibility/owner acknowledgment. **Do not record app content, user routes, coordinates, passwords or tokens.**

## Build/release gate

Last Sileo QA5: `com.duoface.sideplaydisplay 0.1.3~native12ui5` from [carplaydsp run 39124769881](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/39124769881), **deployed but observed device UI FAIL**. The **top-center-only source correction** commit `5c88c69e90238ced215c78192721f1da1b9ad558` passed static [39126662869](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39126662869), is not adequate root cause remediation and **must not be advertised as fixed**. Do not overwrite stable Native12 HUD8 or publish another surface-only QA pretending UI complete.
