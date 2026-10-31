# Original manager acceptance and root-window policy

2026-10-31. Continue the two preceding route audits. QA147 remains rejected by Log23. Static research only; no new DEB, Sileo publication or physical-device success.

## Pins

Original DuoNaviDashboard.dylib SHA256: `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`.
`verify_manager_window_route.py`: **71 new sparse checkpoints passed**. This is separate from the first route audit's71 and app-state audit's62; none is a full CFG/runtime parity test. Vendor binary is read only; no licensing callees are traversed or reproduced.

First-party comparison head: `dae94d3d7b4feee98f42a47b7772599649672306`. GitHub readback matches local:

- `DFNativeDockSync147.h`: blob `54844255af5fae93c515d994661f7a7daca8ae37`.
- `DFDockLifecycle147.h`: blob `22d6034911a522d7caebfdadef1134b1b14f7672`.
- Other source files retain the verified pins in the preceding app-state audit.

## 1. Request manager branches now connected

`CBBridgeManager.requestStateChange:` begins at15b578. Branch semantics were checked in bounded instruction ranges, not guessed from a flat selector scan.

| Condition | Verified branch | Consequence |
|---|---|---|
| Incoming activate is false | 15b5c8 ->15b7a8 | Clear auto-resume bundle, perform related cleanup, deactivate current app at15b800 and return. The cleared field+48 is `_autoResumeBundleID`, not a pending scene request. |
| Incoming bundle is nil | 15b5f0 ->15b7a8 | Same deactivation branch. This is a nil check, not proof of full string validation. |
| Manager not activated | 15b65c ->15b854 | Call `loadNewAppFromCurrentRequest:` at15b864 with incoming request. |
| Activated with different bundle | Equality result false15b6a0 ->15b808 ->15b844 | Deactivate at15b850, then load incoming request at15b864. |
| Same bundle, stale/missing host | Missing window15b6a8, invalid display15b6b8, not visible15b6cc, missing current app15b6d4, or app view has no window15b714 ->15b814 ->15b844 | Deactivate and reload. Checking object existence alone does not preserve a stale host. |
| Same bundle, all above checks pass | Continues past15b714 into a much larger region | Full reuse path not reconstructed; do not claim its opaque branches or every success path have been proven. |

The load->evict->host continuation link at179cec was proven in the first audit. New branch evidence closes the previously missing direct load/replace/deactivate edges at the manager entry.

## 2. The manager's activation state is distinct from scene-ready/PID ACK

Verified ObjC ivar metadata: manager `_activated` offset8, `_bundleIdentifier`56, `_window`64, `_currentApp`72, `_appFrame`96, `_renderSize`128. These are audit offsets for the exact original image, not offsets to hardcode into DuoFace.

The activation request parser stores app frame at15b4f0/15b4f4 and doubled, float-rounded render size at15b518. In callback18c708, the bounded startup suffix:

1. Loads captured manager at192820, stores computed app frame, stores corresponding doubled/rounded render size.
2. Loads the saved **app-frame width/height** (before doubling), tests both `>50.0` at192864/192870 and stores their conjunction into `_activated` at192880. This threshold concerns app-frame dimensions, not PID or verified pixels.
3. Reuses valid CBWindow and updates frame/resize (19293c/192950), or destroys invalid windows (192968) and creates CBWindow with app frame (19299c).
4. Creates hosted app (`appForBundleIdentifier:frame:`192a90), sends application-side bridge state on the observed non-split branch, starts hosted app in parent (192e10) or fallback start, shows window (192e34), then calls `notifyStateUpdated` (192e44).
5. As previously verified, Dashboard consumes manager `activated`/`bundleIdentifier` response, clears pending and updates native Dock/Home.

There is no intervening read of our custom standalone-ready outcome or VerifiedPID in this bounded activation/start/show/notify suffix. This does NOT assert absence of PID checks in all other original methods, or certify that the original cannot fail during startup.

Current QA147 instead requires matching request/bundle/display, freshness, outcome `scene-hosted-render-and-touch-unverified` AND positive VerifiedPID before `DF147ResultAction` returns Activate. Only that action enters `DF147ActivateDock`, which also sets the native Home button's displayState0. Log23 has0 successful standalone outcomes and0 Dock-active events. Therefore no successful transition through this consumer is demonstrated. Missing native Dock/Home activation follows the missing manager-facing success boundary; the exact sceneReady rejection predicate remains unknown.

This evidence supports separating **manager ownership/activation response** from **scene liveness/PID/render/touch observations**. It does not justify inventing a scene-ready ACK or simply removing checks from the current path. First implement the native preparation, ownership, startup, visible window and symmetric teardown transaction, then publish that transaction's truthful state. PID verification remains necessary for any PID-dependent action such as owned-process termination.

## 3. Root window and content rectangle are separate in the original

CBWindow ivars: `_rootWindow`32, `_rootViewController`40, `_contentView`48, `_appFrame`80.

| Original operation | Verified evidence |
|---|---|
| Resolve native window resources | createWindows atb173c obtains carPlayWindowScene, carPlayUIScreen, carPlayCADisplay/display configuration, with supported initializer fallbacks. |
| Choose root window implementation | Class names UIRootSceneWindow (`332be8`), SBFTouchPassThroughWindow (`332bfa`), UIWindow (`332c14`). A supported path creates/registers runtime subclass `CBTouchPassThroughRootSceneWindow` (`332d87`) and installs hitTest, pointInside and sendEvent implementations atb3a48/b3c24/b3e68. Runtime branch selection still requires device evidence. |
| Root window frame | `resizeWindows`: carPlayScreenBounds b24ec is saved and used by rootWindow.setFrame b254c. |
| Root controller view frame | Same full-screen bounds feed its view.setFrame b25d8. |
| Content frame | carPlayUsableBounds b250c is separately saved and feeds contentView.setFrame b2600. |
| Window level | Supported setWindowLevel branch b1c80 loads constant33e860 =10000.0. This is one part of a coupled clear/pass-through window policy. |
| Show | Resize b2834, remove animations, alpha1, hiddenNO b288c, makeKeyAndVisible where supported b28b8. |
| Destroy | Hides/removes window hierarchy; if key, resignKeyWindow atb3054 before removal. |

Current standalone path assigns `w.frame=content`, root.view bounds=(0,0,content.size), windowLevelNormal+1 and `hidden=NO`. This differs structurally from the original full-root/separate-content policy. It is not by itself proof that a content-sized window is invalid: coordinate transforms, touch pass-through, key ownership and Dock behavior must be established together. A full root window also does not imply hiding the native Dock or using a fullscreen CarPlay template.

## 4. How the high root window avoids simply consuming the Dock

Verified bounded callback behavior:

- `hitTest:withEvent:` b3a48 checks root bounds, checks usable content to record current-app activity, then calls superclass hitTest. If superclass returns the root window itself, it returns nil instead (`b3ba8` /`b3bc8`). A real child result can survive.
- `pointInside:withEvent:` b3c24 rejects outside root bounds. Usable content is accepted (`b3cbc` ->b3e0c). Outside usable content it examines subviews, checks hidden/alpha/interaction, converts the point and queries each eligible child's pointInside; no hit returns NO (`b3dfc`).
- `sendEvent:` b3e68 also tracks user activity for touch events. Full app-side activity/touch effects and every special overlay remain untraced.

Therefore setting only windowLevel10000 or stretching the existing default UIView to full screen is not an equivalent implementation. The original geometry, transparent root, child eligibility and input forwarding are one policy. Preserve actual Dock input and validate window-coordinate conversion before changing that policy.

## 5. Exit evidence

Original `dismiss:` at1bf148 clears auto-resume bundle, deactivates current app (`1bf1c0`), then invokes supplied completion (`1bf1d0`) if present. The earlier audit verified hosted stop/remove/destroy/clear manager state/notify in `deactivateCurrentApp`. The Home hook still forwards Apple's original Home after requesting stop, as already corrected.

Native Home destination remains a device/UI-state question. The missing displayState0 transition in QA147 is consistent with the reported wrong destination, but Apple's internal navigation decision and exact timing have not been traced. Do not report this as a proven sole cause.

## 6. Limits and next execution boundary

Confirmed: direct manager load/replace/deactivate branches, precise source of the activation flag in one host continuation, start/show->manager-notify sequence, original full-root/separate-content geometry and touch pass-through mechanisms, and QA147's extra scene/PID gate before Dock/Home activation.

Unproven: full healthy same-bundle CFG; every special-app/split branch; runtime window initializer/hook selection; Apple exception throw site; exact failed ready predicate; original/independent pixel, orientation, touch latency and Home destination on this device. Old broad headers suggesting a PID getter and examples using processState are not a substitute for this device's actual ABI. Apple ScriptingBridge's unrelated macOS SBApplication class must not be used as SpringBoard evidence.

Next implementation should have distinct manager acceptance and scene observation phases, preserve original native prepare/evict/start/show/state/restore sequence and app-side state recovery, and make stale/reentrant launch outcomes impossible. Each phase requires matching request/bundle/display/generation and live ownership. Measure failed ready predicate and startup exception stage rather than relax checks speculatively. The independent contract is recorded in `INDEPENDENT_BOUNDARY_CONTRACT.md`; it is a design checkpoint, not shipped code.

## Reproduce

```bash
python verify_manager_window_route.py --binary /path/to/DuoNaviDashboard.dylib --parser /path/to/audit_native12_license_class_xrefs.py > MANAGER_WINDOW_CHECKPOINTS.json
```

Python/capstone5.0.7 and the existing metadata parser SHA256 `13e1de1371d02f22b3749878ad5ea1134b630616e82f823c2fef72f25b0eb9ed`. Script emits sparse facts, not an entire vendor disassembly, licensing implementation or plaintext channel names. Named annotations are bounded manual interpretations checked against exact instructions/metadata; they are not a symbolic emulator.
