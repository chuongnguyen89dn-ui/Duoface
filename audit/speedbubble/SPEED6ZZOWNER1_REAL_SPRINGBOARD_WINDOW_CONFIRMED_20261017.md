# 17/10/2026 — REAL DEVICE: Native12 split CBWindow found in SpringBoard (major breakthrough)

## Source and exact execution

The user uploaded their genuine file `DuoFaceSpeedOwner-SpringBoard.jsonl`, mounted at `/mnt/data/DuoFaceSpeedOwner-SpringBoard.jsonl`, SHA256 `216950e0085396ab40f5db60e45ef12cdd6d3ac6b60f5d691cdb26cce86706f0`, exact length **11,621 bytes**. Using Python `json.loads` for each file line, verified **11/11 valid JSONL**, process **SpringBoard**, PID **54787**, spanning UNIX 1792207536.1597471–1792207657.161181 (121.0 sec). These events from new `0.1.0~native12+speed6zzowner1` SpringBoard read-only owner observer. No private URLs, user coordinates or screen contents in this file.

### Actual state transitions

- `t=0` `SPRINGBOARD_OWNER_PROBE_LOADED`, `read_only=true`, `created_window=false`: injected diagnostic correctly loaded in SpringBoard.
- `t=0` `SPRINGBOARD_NATIVE12_OWNER_PROBE`, reason `manager_not_created`, native `CBBridgeManager` class and native `CBWindow` class from `DuoFaceDashboard.dylib` are present.
- `t=~1.7sec` `manager_exists_no_window`, manager now instance class `CBBridgeManager`, `CBBridgeManager.window=nil`, `+[CBWindow activeCarPlayWindow]=nil`.
- `t=~17sec` still manager exists but window nil.
- `t=~26.0sec` first **`manager_window_present`**, native class **`CBWindow`**; same native CBWindow is returned by BOTH `manager.window` and `+[CBWindow activeCarPlayWindow]`. 7 observer snapshots at approximately 26,41,57,73,89,105,121 sec report window present. In each: `native_CBWindow=true`, `is_visible=true`, `root_class="CBTouchPassThroughRootSceneWindow"`, `root_hidden=false`, `root_alpha=1`, `root_bounds=[507.3333333333333,240]`, `root_has_windowScene=true`, `external_screen=true`, **`scene_role="_UIScreenBasedSceneSession"`** (not CarPlay-string), `content_class="UIVisualEffectView"`, `controller_class="UIView"`, `content_window_is_root=true`, `controller_window_is_root=true`, `content_descends_controller=true`; controller bounds `507.3333×240`. **This is runtime proof actual native window/root hierarchy exists in SpringBoard, not CarPlay.** Retain exact state on implementation.
- Full log: stages Counter `SPRINGBOARD_NATIVE12_OWNER_PROBE=10`, `SPRINGBOARD_OWNER_PROBE_LOADED=1`; reasons `manager_not_created=1`, `manager_exists_no_window=2`, `manager_window_present=7`; `manager_window.class=CBWindow` in 7, nil 3; PID 54787 single. **No HUD attempts are in this read-only module**, so no claim bubble visible.

## Root cause and next design decision

- Prior `CarPlay` PID 54313 Speed6zProbe1 real log: `CBBridgeManagerDashboard.activated` sometimes true, but `+[CBWindow activeCarPlayWindow]=nil`, hook `CBWindow.show/resize=0`, `owner=nil`, 0 HUD `MOUNTED`. New file **confirms missing owner was a process placement issue**, not GOFAHUD, missing speed source, source wake, or data. SpringBoard native owner *does* exist.
- **IMPORTANT**: The correct host's `windowScene.session.role` is **`_UIScreenBasedSceneSession`**, not a role containing "CarPlay". Therefore role-string-only filter would incorrectly reject real host. The reliable runtime-backed predicate is native `CBWindow` whose root is `CBTouchPassThroughRootSceneWindow`, external UIScreen, root visible, content and VC both on same root, and live native manager ownership.
- **Safety issue not resolved**: the 7 snapshots show `CBWindow.isVisible=true` all the way to t=121 seconds; although the user was instructed to show CarPlay Home → split → exit, the upload contains no explicit labeled timestamps for those 3 UI phases. **Do NOT assume isVisible/root.hidden reliably returns false on exit**; cannot conclude Home=0. Must prove a split-active lifecycle signal or ownership lease before exposing live HUD in SpringBoard. This makes any unconditional SpringBoard global UIWindow or window-level overlay unsafe. We must not repeat Speed2's >3 bubbles on CarPlay Home.
- Proposed small next engineering action: research Native12 `CBWindow` / `CBBridgeManager` / `CBBridgedSplitApp` calls/fields to find reliable split-only active signal, and prepare **in-place UIView subview renderer (never extra UIWindow)** attached to `manager.window.rootViewController.view` or verified contentView parent, gated by actual split state. Existing CarPlay-only renderer must be deactivated/replaced **atomically** to avoid duplicates, and legacy visual HUD reused as-is.
- If an explicit split lifecycle signal is not proven from native ABI/device, enhance the existing SpringBoard **read-only** probe to log active split app count/hide/activation before pushing a visual candidate; preserve 0 Home/1 split/0 exit/Waze stability.
- No source/DEB/Sileo modifications in THIS log-analysis checkpoint. Live public is still `0.1.0~native12+speed6zzowner1` SHA256 `d63cf64a5139c7c235b9836b963f2a6a9f25ac414c4eda79bcea07ddda32475a`. No new on-device functional claims.

## Precise next task

1. Verify actual object constructor/owner activation in Native12 `audit/speedbubble/NATIVE12_SPEED4_SPLIT_OWNER_CHAIN_READONLY.json` and `audit/speedbubble/NATIVE12_GOFAHUD_SPLIT_SCENE_OWNER_READONLY.json`. Reinspect `CBBridgeManager` states/fields or native split app container lifecycle.
2. Implement guarded *same native window UIView* mounting in **SpringBoard**, **no global new UIWindow** and **no unproven Home screen shortcut**.
3. Build arm64 rootless DEB; pinned baseline exact 43 payload files from Speed6zzOwner1 (39 Native12 + 2 existing HUD + 2 SpringBoard owner probe) unless intentional 2-file owner probe replace. Preserve original native app/Waze integrity. QA → optional Sileo only after split-only gate evidence; test real device Home=0/split=1/exit=0, no collision.
