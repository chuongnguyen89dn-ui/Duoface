# Scene ownership candidate .82 — 2026-10-28

Source baseline: c0da32fa970143b2b3daac82e0b4b2dcb26a16be.
Integrated version: 0.0.82~sceneowner1. NativeHost: 0.1.91~sceneowner1.

## Evidence and change
The pinned Native12 C hook at 0x2c7e08 enforces foreground on FBScene updates independently of geometry; its separate observer hook bypasses callbacks for selected hosts. See ../native12-foreground-hooks-20261027/REPORT.md. The first-party host already disables automatic lifecycle, but previously enforced foreground only during its geometry transaction. Incoming background updates can therefore violate the Live host contract.

This isolated candidate implements only the update-boundary ownership policy, not blanket observer suppression. Register a weak owner before Live admission; resolve the exact current scene through its handle, require the pane and child view to remain attached to the same visible window, and reject replaced scenes. Unregister before teardown. Only main-thread explicit foreground=NO updates for an owned scene are copied and changed to YES; other updates pass through. Preserve context and completion identity, call the original IMP exactly once outside exception handling, and never mutate the caller settings. Check selector ABI and hook availability before creating a host. No UI/Dock/Zoom/logo changes, vendor markers, lock policy overrides or private ivar writes.

## Validation
Local Python tests: 159 PASS (7 integrated, 109 scenehost, 7 admission, 27 independent host, 9 bridge). Missing sparse-checkout fixtures were restored; tests were not weakened. git diff --check PASS.
The macOS Foundation harness executes production DFSceneLifecycle.m with a fake FBScene/hook backend: owned copy, unchanged fields, foreign/stale/off-main/expired owners, revoke, nil/unknown settings, original context/completion, preparation fallback and propagation of original exceptions. Execution awaits CI; this is not SpringBoard integration coverage.

## Remaining uncertainty / acceptance
No device connection, .82 runtime result or crash cure established. The .80 matched IPS show the same observer abort but omit its reason; the older foreground=NO assertion does not prove all later abort causes. An update bypassing this FBScene method or arriving off-main remains uncorrected. The original Native12 observer bypass is deliberately not copied, so failures remain observable. No assertion suppression.
Device acceptance requires app open/replace/close, two panes, YouTube/TikTok playback and background transitions, CarPlay disconnect/reconnect and lock/unlock; correlate .82 DeepTrace timestamps with any new SpringBoard IPS. Confirm boundary-installed and incoming-background-owned-live events, normal close/background after revoke, no Safe Mode and unchanged UI/Dock/Zoom. Source/CI success cannot replace this acceptance.

Build and immutable artifact result will be added after CI completes. No Sileo publication claimed here.
