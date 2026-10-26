# Phản hồi yêu cầu “vì sao chưa sửa dù đã lấy bản .37 làm mẫu” — đối chiếu SOURCE THẬT

**2026-10-26 / DuoFace độc lập / không gọi build/test mù.** Người dùng đã chỉ rõ bản tích hợp `0.0.37` phát được video nhưng bị xoay, và đề nghị lấy làm mốc khôi phục; ảnh thiết bị .68 hiển thị app vẫn bó/ngoại hướng. Cần phân biệt **chưa sửa thành công trên máy** với **đã có commit, DEB .69/.70**.

## Kết luận

**Đúng: đã KHÔNG khôi phục toàn bộ cấu trúc chạy được của .37.** Các bản .69/.70 chỉ khôi phục từng *callsite* của `DFSceneHost.m` lên kiến trúc mới, trong khi một ranh giới nguồn scene/window quan trọng từ .37 đã thay đổi và chưa được đối chiếu trên thiết bị. Bởi vậy lời hứa “làm theo .37” chưa tương ứng với việc phục hồi đúng cấu hình hệ thống .37.

### Đối chiếu literal từ GitHub

- **Signed .37 source commit** `a8cdec6252b0e772faa726e92b84ee66246590ed`, `sideplay/duoface-native-scene-host/DFSceneHost.m` blob `d394e19a58023727a7a59d42076606c28dce0fbd`:
  - Lines 177–283: `logical=round(2×size)`, 3 đường child2/child3/main2 sizing **độc lập**, gửi `UIInterfaceOrientationPortrait` cho content reference; lines 231–237 set transform identity/frame/autoresize của `_deviceAppViewController.view`, `setHomeGrabberDisplayMode:1`; lines 245–268 `updateSettingsWithBlock:` gọi setter `setFrame:` trên remote scene; code đánh dấu committed chỉ khi reference selector đã gửi. **Không** chứng minh video xoay đúng.
  - `DFNative12Chrome.m` blob `9601fdc86533026d5f9a753685b9b696cac0c0fa`: lines **560–566** tạo **4 UIWindow riêng** (one `emptyRoot` / physical slot, frame quarter of CarPlay area lúc tạo); **853–877** khi layout cập nhật `appWindow.frame=target`, `slotWindow.rootViewController.view.frame=slot-local`, child frame=bounds, hide/interaction từng UIWindow. **Video worked** dựa trên mô tả kiểm thử người dùng (chưa có đo pixel/player/scene logs chứng minh), **rotation failed** theo lời người dùng.
- **Current .70 source** trên `feature/duoface-jb-embedded-appbridge-20261020`:
  - `DFSceneHost.m` blob `fe08fce10eb34c27b412e6b9eb358f96eccd9d82`: đã khôi phục child2/child3/main2, `inner.frame`, grabber theo bản .37; BUT extra ready-scene age>=1.25s + ABI/readback owner-gated remote settings; riêng YouTube scoped `setInterfaceOrientation:` đến CarPlay UIWindowScene landscape on difference. **Chưa biết device accepted gì**.
  - `DFNative12Chrome.m` blob `dac3ec533c3e0e9827f555780fa70d50c7f173b5`: **770–782** tạo **ONE `sharedAppWindow` + 4 `UIView` child containers**; **1164–1206** thay đổi only view frames, parent external `sharedAppWindow` stays one stable CarPlay window. Đây là **THAY ĐỔI SCENE/WINDOW OWNERSHIP** bắt đầu ở .48 (source commit `eb2a47906df64befcda7cc366f4d468ef1d67fa2`), **không được khôi phục bởi .69/.70**.
  - New `DFSceneHost.layoutScene`: early return `if (CGSizeEqualToSize(size,self.lastApplied)) return;`. New `commitSceneGeometry`: early return if size==`self.committedReferenceSize`. Consequently **YouTube’s internal player/orientation change at a constant split size does not itself trigger a new geometry/orientation policy request**; `pollScene` samples scene settings but currently only accepts an existing requested frame; no independent observed app playback-orientation event hookup. **This is a proven source-level event-coverage gap**, not proof that this is why screenshot was wrong.
  - No component proven to own YouTube app-process `UIWindowScene` trait/viewport. The present `FBScene.settings.interfaceOrientation` update is **SpringBoard scene policy**; sending it (or receiving no ObjC exception) cannot guarantee YouTube player’s UIKit/AVKit rotates its own controls.
- Why `.48` switched to shared: handoff contemporaneous source states 4 separately re-framed `UIRootSceneWindow` were suspected of causing player/scene churn, so .48 created stable shared external UIWindow to match original Native12 `CBWindow`. **Reverting shared to four blindly is not proven safe** and may regress current working dock/logo/zoom and revive old crashes; however keeping shared while claiming “đã khôi phục .37” is demonstrably inaccurate.

## Rejected former assumptions

1. **Rejected:** “Khôi phục callsite child2/3, inner.frame = khôi phục bản .37.” Actual per-pane `UIWindow` ownership changed; current native code is **not same runtime configuration**.
2. **Rejected:** “Đổi scene `setInterfaceOrientation:` theo CarPlay là YouTube tự render đúng.” Scene direction ≠ app-owned `UIWindowScene` orientation/trait and AVKit fullscreen. No device ACK for .70.
3. **Rejected:** “CI xanh + Sileo DEB đã ký là đã sửa giao diện.” Only hardware media play/seek and orientation tests establish real success.
4. **No fabricated cause:** Four-to-one window change is the **major un-restored difference**; it is NOT independently proven to be the unique cause. Source events gap is objectively present; impact on playback not hardware-proven.

## What is actually completed

- **.69** signed integrated recovery candidate from v37 call sequence, immutable DEB SHA256 `ae2ac9366584ef80f5b9ba2174de45b7d0746a08f58232b4f21d4190ab124dce`, preserved for rollback.
- **.70** YouTube scene-orientation extension after four-product static comparison; signed immutable run `40301258985`, public Sileo run `40301774839` SUCCESS build/deploy/public SHA; DEB SHA256 `e21b5931819f9c3abac017e38ffcb430e2b362b05b312b9b628d5dfb93d968e1`. **No validated YouTube playback+orientation on the user's iPhone for .69 or .70 as of report.**
- Known actual image shows **.68 failed** (boxed ChatGPT and 70mai; not a .70 device result).

## Next corrective decision (NOT performed in this record)

**Do not publish .71 yet.** First choose explicitly one coherent scene owner based on source evidence, **not mix .37 per-app UIWindow with .48 shared-window ownership while silently changing geometry**. Study original `CBWindow` vs v37 per-pane host and whether per-pane UIKit window creates separate `windowScene` traits in iOS16 CarPlay. If reverting v37 scene ownership, port the **complete** pane-window create/layout/host attachment/hide/teardown/Fullscreen invariants together, with a dedicated migration test preserving current logo/Zoom; otherwise retain shared owner and implement source-derived *app-side* geometry/orientation state contract (e.g. DuoDash `CNABUIApp`) with verified app-process ABI. Need only ONE versioned integrated candidate after coherent choice. Real-device pass required for YouTube video and controls upright, split, solo, pan/zoom, no SafeMode. .70 pending device validation; **cannot claim solved**.

This report is **SOURCE ANALYSIS / HANDOFF**, not a code fix or user-device test. No changes to other repositories / third-party payload.
