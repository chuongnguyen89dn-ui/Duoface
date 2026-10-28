# DuoFace .91 native Maps split experimental QA — device-gated

Source: `chuongnguyen89dn-ui/Duoface` branch `feature/duoface-jb-embedded-appbridge-20261020`; QA source commit `4dba11e1a95e237f966b44292b9b486a837a8f90`.

**Signed DEB built on macOS** (one integrated package, no vendor payload):
- Immutable GitHub `sideplay/jb-embedded-appbridge/evidence/runs/40689380992/com.duoface.jb.embedded_0.0.91~nativemapqa1_iphoneos-arm64.deb`
- SHA256 `e15b9b2c2da351a64a125f5057c6c6e0f6d44aefbcc73de8fe023b6c4d5ab741`
- macOS build run `40689380992`: compilation/test/package/upload PASS, final archive step FAIL due outdated script expecting .90; separate archive-only verification `40690294670` SUCCESS, actual archive commit `0f7d8a8eb23bcceb923fe319b33975ac5c509d22`, GitHub readback SHA verified.
- `DFNativeMapPaneCoordinator.dylib` signed within integrated package, filter only `CarPlay`/`CarPlayApp`; `DFNativeMapPaneAdapter` compiled as part of it. The iPhone `DuoFaceNativeHost.app` has **Bố cục > Thử nghiệm bản đồ CarPlay native**.
- `.90` user-verified YouTube rotation source unchanged, existing public Sileo rollback DEB SHA256 `c9a6c8f624ce3224ec5cdc7aee9c3280306068c99c9842d4b4f802914c560f27`.

## **Device test only while car parked**
1. Before updating, ensure the existing .90 install is usable and a rollback can be selected in Sileo; do not manually install through Filza. `.91` cannot be described as stable or final OmniCar parity.
2. Open native **Google Maps on the vehicle CarPlay interface** *without removing it from iPhone Settings > CarPlay > Customize*; ideally keep the route active and visible in the CarPlay UI.
3. On the **iPhone DuoFace application**, navigate to **Bố cục > Thử nghiệm bản đồ CarPlay native** and press **Bản đồ bên trái** or **Bản đồ bên phải**. This sends a direct short-lived opt-in action to `CarPlay` / `CarPlayApp`. **Do not treat "đã nhận thao tác" ACK as proof of tiles or route.**
4. Check visually whether real map tiles display in the selected pane, the other DuoFace YouTube pane works with correct orientation, the real native Dock remains and the map is touchable. Test short route progress while CarPlay remains foreground; stop the test if navigation/CarPlay behaves unexpectedly.
5. Use **Khôi phục giao diện Maps** in the same iPhone menu to reverse controller adoption if still the same native owner/window. If CarPlay stops responding, revert the integrated package through **Sileo** to the user-confirmed `.90`; never delete app/Maps configuration or vendor packages manually.
6. Export CarPlay log `/var/mobile/Library/Logs/DuoFaceNativeMapPane.log`, read-only owner log `/var/mobile/Library/Logs/DuoFaceCarPlayOwnerSnapshot.log`, any SpringBoard/CarPlay `.ips`, and a screenshot of maps beside YouTube via the existing iPhone QA sharing mechanism. This allows analysis of rejection `Reason` and timeline `DBApplicationSceneViewController` owner. Note the new map log may require an exporter update if the default QA share action does not include it; the original owner-log exporter is separate historical diagnostic, not a new required tweak.

## Real limitations
- CarPlay native Google Maps FBScene in prior true device snapshot #41–42 was replaced in the SAME Dashboard app-scene VC by DuoFace #43–44. **Not yet proven** that native Maps remains in one pane while the iPhone YouTube bridge is active.
- .91 implements a genuine, guarded UIKit same-process `addChildViewController:/addSubview:` native-controller handoff and restore, but **does not yet issue native `FBScene` size/foreground transactions** like the original OmniCar `pushSceneSizes`. This may mean cropped map, lost route, missed touch or coordinator safely refusing. Do not "fix" by arbitrarily scaling iPhone Maps/using phone MainDisplay.
- No automatic map attachment: only explicit user iPhone UI. Does not claim verified fullscreen/4-pane parity, route continuity or 100% crash-free behavior.
- User explicitly forbids separate diagnostic tweaks and Filza installation for functional QA; this QA code is within a single integrated rootless DuoFace DEB. The earlier separate `nativejoinprobe` diagnostics are optional and **not** needed for the new feature.
