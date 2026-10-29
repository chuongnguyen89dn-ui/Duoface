# 2026-10-29: Original Native12 vs signed DuoFace .116 — unwanted black band at the Apple Dock seam

## User evidence and exact scope

- User confirms original Native12/HUD8 **does not** show the black band between Apple's native vertical CarPlay Dock and independent pane content. Two real-car photographs at 21:28 and 21:30 +07 show the band. At 21:28 red border makes the GOFA pane origin visible beside the Dock; at 21:30 the red outline auto-hides, but a dark strip remains. User says this is **a display regression that needs original vs current DEB comparison**; previous assistant explicitly acknowledged it.
- Camera photos were provided directly in conversation and are NOT uploaded to public GitHub. No original-DEB comparative pixel screenshot or same-connection `ContentRect` log has been measured in this audit. A photographed strip does not by itself prove the particular setter responsible.
- Distinct issue from delayed YouTube lower-card touch and 4-second logo wake. A common misplaced pane origin is possible but **not proven**.

## Original Native12 DEB — direct immutable ARM64, NOT guessed constants

- Original integrated `com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb` SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`, `DuoFaceDashboard.dylib` Mach-O SHA256 `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`.
- An earlier SHA-verified disassembly exists at `sideplay/audit/native12-layout-forensic-20261021/evidence/REPORT.md`; `CBWindow.carPlayUsableBounds` @`0xb0ef4..0xb0ff0` **directly invokes `carPlayScreenBounds` @`0xb0f14` and `carPlayContentInsets` @`0xb0f34`**. Original `CBBridgedSplitApp.layoutSplitViews` requests `+[CBWindow carPlayUsableBounds]` @`0x10454c`. `CBWindow.resizeWindows` also reads the dynamically computed `carPlayUsableBounds`.
- Therefore the verified original pipeline is **native display bounds → native content insets → usable bounds → split layout/windows**. Do not copy vendor code/license. The actual fallback/default value inside `carPlayContentInsets` and the exact native iOS16 AppDock owner are NOT yet decoded in this source report.
- The expanded SHA-checked read-only extraction of original `carPlayContentInsets`, `carPlayUsableBounds`, `carPlayScreenBounds`, `createWindows`, `resizeWindows`, `layoutSplitViews` is `sideplay/audit/native12-dock-gap-20261029/extract_original_dock_bounds_imp.py`; CI `.github/workflows/duoface-native12-original-dock-bounds-forensics.yml` run `40893202813`. Its runner initially **QUEUED**, so do not call the expanded scan PASS before result exists.

## Signed independent DuoFace .116 path actually used

- Signed integrated `com.duoface.jb.embedded_0.0.116~pane-trace1_iphoneos-arm64.deb`, SHA256 `fc87ceb4a8492469563246c00a9a205b838498f7652f8515bb08b9ca356285a8`; source CI run `40870166155` PASS, pinned immutable archive `sideplay/jb-embedded-appbridge/evidence/runs/40870166155/`, source SHA `6d4174321f2d71190fe11bec6b24a810b58d7eb1`. Audit compares the *exact .116 build source*; images do not expose Sileo-installed version metadata.
- `sideplay/duoface-native-scene-host/DFNativeHostAppDelegate.m:189–196`: uses `CPWindow.frame` and `CPWindow.safeAreaLayoutGuide.layoutFrame` and persists `ContentRect` to the active CarPlay session record. This is already a usable-area proposal.
- **Confirmed independent source deviation:** `DFTouchOwnerProbe.m:378–397` reads that valid `ContentRect`, then applies a second, **hardcoded app-created left guard** `safeLeft=screen.minX+MAX(42,screen.width*.082)`. When `ContentRect` is valid it sets `x=MAX(region.origin.x,safeLeft)`; when missing/invalid it invents a full-height fallback starting at `safeLeft`.
- The source therefore can **increase the left margin beyond the actual native CarPlay Dock**. Example algebra, NOT device measurement: on a 507.3pt screen, `MAX(42,507.3*0.082)=42pt`; when the authoritative window's usable area starts at x=35pt, DuoFace **moves it to x=42pt, adding an artificial 7pt black strip**, clipping 7pt from usable width. That additional 7pt can never be explained as a real native Dock width, since it is manufactured independently of Dock measurements.
- `DFTouchOwnerProbe.m:408–410` passes that overwritten `region` as `contentRect` to `DFNative12Chrome`; `DFNative12Chrome.m:623–625,995–1024,1509–1522` creates and lays out four real physical pane UIWindows **starting at this computed origin**, so the extra strip propagates to the actual viewport rather than being purely ornamental. Red outline disappearing after idle is expected from `DFNative12Chrome.m:1157–1166,1547–1556`; it does not prove the black strip disappeared.
- There is another potential dynamic mismatch: the CarPlay `CPWindow.safeAreaLayoutGuide` may include its own content/navigation padding; actual runtime `ContentRect` and Dock view frame must be read back before independently removing any margin. Never erase Dock, render behind it, or crop/synthesize its width.

## Evidence grade and corrective requirement

**SOURCE-PROVEN: DuoFace .116 adds an arbitrary extra left margin not present as the original Native12 layout input contract.** This is an actual architectural defect/regression risk; it can produce the visible band. **NOT YET PHYSICALLY ATTRIBUTED**: the size of `ContentRect` from the specific user's iOS16 `CPWindow`, the effective 42pt guard branch in that session, and the measured Dock-to-red-border distance.

Do not blindly move all frames to x=0 or hide the system Dock. A safe independent correction must:
1. Read/validate **live native CarPlay usable bounds** (the CPWindow's actual safe rect and, if required, a measured native AppDock-owned rail) without applying arbitrary `42` or `8.2%` floors.
2. Preserve the same coordinate space in template owner, SpringBoard `DFTouchOwnerProbe`, each `UIRootSceneWindow`, scene host and app-touch surface. Record exact initial `screen/CPWindow/safeLayoutFrame/ContentRect`, the derived `region`, and native Dock right edge in a single timed session.
3. Invalidate/recompute on genuine CarPlay display metrics change and reconnect; retain Native12 reference split geometry, .90 YouTube rotation, .92 divider/logo and native Dock. Never compensate by UIKit zoom, negative offsets or hiding Dock.
4. Add source regression contract: with source usable `ContentRect.x=35` inside screen 507.3pt, no second software safety floor may move the origin to 42; invalid or non-system-authoritative geometry must fail closed instead of guessing.
5. Verify on real vehicle: **zero unwanted black band** after 4s UI idle, both visible app panes touchable top/middle/bottom after prolonged time, statusbar/Apple Dock remain unchanged.

**No pane geometry runtime patch or new .117 package is claimed by this binary comparison.** Continue original `carPlayContentInsets` disassembly and measured readbacks before choosing the single correct fix.
