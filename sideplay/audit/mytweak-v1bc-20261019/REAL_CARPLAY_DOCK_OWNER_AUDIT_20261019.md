# MyTweak v1b+c — Apple CarPlay AppDock absent: owner/window audit (2026-10-19)

## 1. Verified runtime facts (separate source vs user evidence)
- Real CarPlay head unit photo showed the independent MyTweak interface, two live app panels (70mai and ChatGPT), an App / Single / Swap / Zoom / Close menu and a center divider. User confirmed these tested functions worked on real head unit.
- New user observation: **“Ko. Nó ko hiện.”** directly answers whether the *native Apple CarPlay AppDock/sidebar* appears. **Dock currently ABSENT on head unit (USER_REPORTED_FAIL).** This replaces earlier `REAL_APPDOCK=NOT_YET_CONFIRMED` markers, but says nothing about why it is absent.
- Preserve existing working **`com.duoface.mytweak.v1a.preflight` `0.2.0~v1bc1`**, DEB SHA256 `764cd0bcce701da4271af92e9daf8e4599b881d57d3ef16c1bfdb916462345ab`, and QA11/Native12/HUD8; no build or Sileo deployment is justified by this observation alone.

## 2. Exact local source tracing and implications
Source on `feature/mytweak-v1bc-combined-20261019`:
- `sideplay/mytweak-independent-v1a/MTBridgeCoordinator.m`, method `attachToCarPlayDisplay:`:
  - uses `AVExternalDevice currentCarPlayExternalDevice` + `screenIDs` matched to `CADisplay displays.uniqueId`;
  - creates a new `FBSDisplayConfiguration initWithCADisplay:isMainDisplay:` with `NO`, then `UIRootSceneWindow initWithDisplayConfiguration:`;
  - sets `window.rootViewController=MTBridgeRootViewController`, `window.backgroundColor=UIColor.clearColor`, `window.opaque=NO`, `window.windowLevel=UIWindowLevelNormal`, `window.hidden=NO`;
  - *does not* attach to a CarPlay `DBWorkspace`, discover `DBDockWindow`, reserve an existing Dock region or request system Dock visibility.
- `MTBridgeRootViewController.m` creates its own root view; `MTSplitContainerViewController.m` covers root bounds with split/single app slots. Thus a full-screen **parallel window** is confirmed from source; **it may obscure the system-owned Dock**, but there is no runtime window stack proof yet.
- `DFV1APreflight.plist` filters only `com.apple.springboard`. The private-class probes in `MTPreflight.m` execute **only in SpringBoard**. Its `DBAppDockViewController/CARAppDockViewController init encoding=missing` observations, and SpringBoard `UIWindowScene` enumeration (12 windows on iPhone screen) **cannot prove Dock classes/windows do not exist inside the CarPlay UI process.**
- `MTSceneHost.m` does achieve user-confirmed app hosting, so do not discard its successful single/dual scene code to address Dock.

## 3. External independent comparison (read-only research; DO NOT copy vendor code/licenses)
- Public `pavunato/carsurf` (GitHub main, inspected 2026-10-19) describes iOS 15–17 CarPlay admission via LaunchServices and a **separate CarPlay UI process** from SpringBoard. Its `sbtweak/CSSystem.plist` filters executables `SpringBoard`, `CarPlay`, `CarPlayApp`, `CarPlayTemplateUIHost`, etc. `sbtweak/CSCarLaunch.m` tests process name `CarPlay`, uses `DBApplicationController` and `DBWorkspace`, and restricts to `DBDashboardWorkspaceOwner` (not instrument-cluster owner). Sources: https://github.com/pavunato/carsurf, https://github.com/pavunato/carsurf/blob/main/sbtweak/CSCarLaunch.m
- Prior project audit `docs/airaw_dock_notification_receiver_20261013.md` documents **`DBDockWindow.layoutSubviews`** in an existing tweak: evidence of an actual Dock-window class and its own lifecycle. This is a REFERENCE about window ownership, not permission to copy Airaw binary or its license. Distinguish the Apple CarPlay app Dock from unrelated Native12 setting **“Giám Sát Dock”** (performance/status monitor), which is not a substitute for system navigation Dock.
- Apple's CarPlay docs distinguish system-managed `CPTemplateApplicationScene` / `CPTemplateApplicationDashboardScene` windows; they do not say arbitrary SpringBoard `UIRootSceneWindow` overlays automatically inherit the system sidebar. References: https://developer.apple.com/documentation/carplay/cptemplateapplicationdashboardscene, https://developer.apple.com/documentation/carplay/cpwindow
- Sources above support the process/owner distinction, **not** a definitive claim about z-order or an exact native API to restore the sidebar on this head unit.

## 4. Ranked hypotheses and next non-disruptive engineering gate
**H1 (leading but unproven):** MyTweak's full-display SpringBoard-created external window visually occludes the CarPlay-owned `DBDockWindow`. Check real window levels, dimensions, hidden state, and process ownership before touching positioning.

**H2:** MyTweak launches as a separate unmanaged scene/window outside CarPlay Dashboard's `DBWorkspace` / `DBDashboardWorkspaceOwner`; the system Dock may be hidden by the scene transition rather than merely covered. Inspect dashboard lifecycle and workspace state *on the CarPlay process*, not SpringBoard-only.

**H3:** CarPlay native Dock is currently hidden under some normal/full-screen mode flag/window state even when apps are in split normal. Check observed mode and whether Dock reappears after closing this trial, without asserting either cause until actual logs.

**Next scoped implementation** (separate source-only branch/stage; preserve v1bc Sileo):
1. Build a **passive, read-only CarPlay-process Dock/Workspace probe** (executable filter `CarPlay` only, opt-in/default off). Log only class availability and real `DBDockWindow` / `DBWorkspace` owner, window level/hidden/frame & relationship to CarPlay display. No window mutation, no fake sidebar, no code from vendor binary, no user-private data.
2. Compile and unit-test; compare against v1bc SpringBoard window log `/var/mobile/Library/Logs/MyTweakV1BC.log` **when needed** (user can share via Filza, not terminal). Determine actual process/owner/layering on iOS16 before changing the already-functional host.
3. Build minimal independent integration that preserves the existing **native Apple Dock in Normal/Split** while retaining two app surfaces and all controls; use CarPlay-managed scene/display where feasible; never merely paint a 48/64px fake bar, hard-code icons, or claim that reducing UIWindow width restores the actual Dock.
4. Require one **combined** device acceptance: native Apple Dock icons/home/menu work, 1/2 app scenes work, ratio/swap/zoom/close work, reconnect/respring no crash/exitmode. **No repeat Sileo pushes for speculative changes; do not touch QA11/Native12/HUD8.**

## Current outcome
**ROOT_CAUSE_CONFIRMED=false; SYSTEM_DOCK_VISIBLE=false (user); BUILD_CHANGED=false; SILEO_CHANGED=false.**
Only project audit/handoff are updated. No claims of a device-tested Dock fix.
