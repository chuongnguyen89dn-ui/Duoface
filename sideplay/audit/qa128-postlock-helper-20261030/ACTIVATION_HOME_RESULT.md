# Original activation and explicit CarPlay Home trace — 2026-10-30

The original has an explicit Home event path. CPTemplate Background alone is not the original Home discriminator found here. This resolves the previously unknown Home entry point; it does not establish that locked YouTube Play is repaired.

## Reproducible input and scope

Read-only original DuoNavi 1.0.4 dylib SHA256 `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`, from DEB SHA256 `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`. No original code is executed. Scanner uses LC_FUNCTION_STARTS and requires every selected body to decode completely: 14 functions, 1,177 ARM64 instructions. JSON contains all bodies, exact selector refs and CFStrings. Classref 0x3aad68 is verified against CBBridgeManagerDashboard metadata.

Run with Capstone 5.0.7 installed and the project's existing `audit_native12_license_class_xrefs.py` and `audit_native12_carplay_add_app_chain.py` on parser-dir (under migration/full_payload/native_test on feature/visual12-duodash-recovery):

```bash
python trace_original_activation.py --binary /path/to/DuoNaviDashboard.dylib --parser-dir /path/to/native_test --out /path/to/evidence
```

## Exact Home request path

| Boundary | Address and observed behavior |
| --- | --- |
| Register DB Home | Initializer 0x30f1ac loads DBRootStatusBarViewController; selector homeButtonUp: loaded into x23 at 0x30f23c from 0x3aa8b8. Hook call 0x30f258 uses x1=x23, replacement 0x30f4d4, original storage 0x3ae3c8. |
| Register CAR Home | Same initializer loads CARRootStatusBarViewController; preserves x23 across calls; hook call 0x30f2d4 uses the SAME homeButtonUp: selector, replacement 0x30f6c8, original storage 0x3ae3e8. This resolves the earlier registry's missing selector caused by register reuse. |
| Home callbacks | Both 68-instruction replacements obtain CBBridgeManagerDashboard.sharedInstance and check activated. If true, call stopBridging (DB call 0x30f5a0, CAR 0x30f794). Both branches converge on the saved original Home IMP (DB 0x30f5c0, CAR 0x30f7b4); the original is called once with saved receiver/selector/event. |
| Stop request | stopBridging 0x2c5d44 -> stopBridgingWithCompletion: 0x2c5d54 -> requestDismiss 0x2c669c. |
| Request payload | requestDismiss sets pending=YES. Creates a two-key dictionary: source="CBBridgeManagerCarPlay:requestDismiss", activate=NO (numberWithBool: with w2=0 at 0x2c6774). Calls requestStateChange: at 0x2c67d0. |
| Transport boundary | Dashboard requestStateChange: 0x2c686c includes writeToFile:atomically: and notification operations. This report does not claim a complete transport/receiver trace or copy its implementation. |

## Activated is not one global flag

Dashboard handleStateDict: at 0x2c6f88 reads the dictionary's `activated` bool; true calls bridgeDidActivate:, false calls bridgeDidDeactivate. Activation sets the Dashboard flag YES and updates Dock bundle/Home-in-app YES. Deactivation sets the Dashboard flag NO at 0x2c715c, clears Dock bundle and sets Home-in-app NO. This is a state-response path, distinct from Home sending a dismissal request.

CBBridgeManager is a separate owner object: isUIAppBridging at 0x26c04c requires its activated byte AND non-nil currentApp. Its getter 0x1bf3cc reads self+8; setter 0x1bf3d4 writes self+8. deactivateCurrentApp 0x1bec84 removes/stops views, destroys windows and clears self's activated byte at 0x1beff4 (x19 is saved self). Do not equate this byte with CBBridgeManagerDashboard's flag, and do not treat serialization STRB instructions as manager state writes. This trace does not enumerate every possible activated writer or prove a single synchronous Home-to-SpringBoard transport chain.

## Concrete first-party difference and next implementation boundary

Current DFNativeHostAppDelegate.m sceneDidEnterBackground: unconditionally calls stopTouchOwnerWithReason:scene-background. Heartbeat also revokes on Background; SpringBoard watchdog subsequently requires a fresh active lease. Audit13 shows this explicit teardown with external-window=1, both protected-data=0 and =1. Those log entries do not tell which physical action the user took.

The original supplies a concrete event suitable for independently separating intentional Home dismissal from a phone-lock lifecycle transition. A first-party implementation should validate the actual runtime class/method ABI, forward original exactly once, and issue its own scoped/session-bound revocation on explicit Home. App switching, focus transfer and disconnect still need their own ownership/revocation treatment. Merely suppressing CPTemplate background teardown without replacing heartbeat/watchdog ownership would be incomplete; background alone must not create a new owner. Keep stale/foreign scene rejection, explicit Home cleanup, disconnect cleanup and loss-of-display cleanup. Apply existing post-lock settings candidate only to the authenticated current owner.

Runtime presence/signature of DB/CAR homeButtonUp: on this user's iOS has NOT been checked by this static original trace. Original registration does not establish runtime availability. No new DEB, build or Sileo update in this tracing task. QA128 user's crash+GOFA success remains baseline; locked input/Play remains unresolved. Next implement first-party owner transitions with runtime ABI checks and scoped event evidence, then SDK checks and a uniquely versioned package only after coherent lifecycle handling is reviewable.
