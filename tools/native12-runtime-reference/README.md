# Native12 running UI reference: deterministic QA reconstruction

Status: SOURCE-ONLY, NOT INSTALLED, NOT TESTED ON A DEVICE. QA7 visual parity rejected.

## Why a new method is necessary

The actual Native12 HUD8 DEB has 43 regular files, 25 PNG, 6 dylibs, and 7 non-icon UI PNG assets. All 7 UI PNG assets already match those in rejected QA7 byte-for-byte; the missing UI is NOT missing artwork. Objective-C methods, color construction, hit-test ownership, scene sizing, UIKit window/safe area and gesture-state-dependent behavior cannot be reconstructed completely by counting files or changing the alpha QA UI constants.

Treat the **running Native12 on a normally functional reference CarPlay device** as the measured reference, not the static DEB or a QA mock screen. Original DuoNavi 1.0.4 binary callchains remain static guidance for transition rules, not linked runtime components or licensing.

## Optional passive reference inspector: source-only

- Native12ReferenceCapture.m registers a manual, opt-in Darwin notification named com.duoface.native12.reference.capture. It has no automatic startup snapshot and must NOT modify a UIKit view, call original native methods, bypass a license, or send any network requests.
- Native12ReferenceTrigger.m can post that notification when separately compiled/installed in a future approved diagnostics-only package.
- A manual notification requests one JSON snapshot to /var/mobile/Library/Logs/DuoFaceNative12Reference/ui-<unix-ms>.json on a separately instrumented reference device. It inspects UIScreen bounds/scale, UIWindow level/safe-area/bounds, UIView class/subview tree/frame/colors/blur-related layer properties, gesture parameters and UIControl event bits.
- It deliberately omits UILabel.text, text inputs, images, bundle IDs, user content, credentials and device identifiers. Traversal limited to 2,500 UIView nodes per window. Colors from runtime UIKit can fail conversion (record null); never fill unknown values by guessing.
- Only external-screen windows or windows exposing native CB-style view classes are captured. UIApplication.windows / UIWindowScene.windows may miss unusual native windows; that is a **coverage gap** to investigate rather than an absent-UI claim.
- This source has not been deployed. Installing any tweak into SpringBoard requires a separate reviewed build, user approval, rollback path and device-test slot. No respring or Sileo update has been requested.

## Reference capture matrix (same receiver, matching scale, screenshots alongside JSON)

| State | What to measure | What constitutes behavioral proof |
| --- | --- | --- |
| Connect, native splash | Native startup window bounds, safe area, CarPlay status/Dock | Dock/status remain correctly available throughout startup |
| Initial split, zero/one app | Native placeholder root and slot pill frames, colors, logo, touch | Placeholder tap invokes picker; pane-sized scene unchanged |
| Two live apps | Scene host and nested content frame/orientation, divider position | Both apps visible and touchable, no overlapping labels |
| Divider pan from line and logo | Split CGRect before and after, gesture recognizers, custom fraction | Drag changes sizes of both live apps, persists after close/open |
| Divider short tap / 0.30s hold | Swap and along-divider logo position | Short tap swaps, long hold moves logo WITHOUT resizing |
| Picker App/Recent/Layout/Style/Close | Overlay tree, cards, paging, menu, blur, button frames | Every action works; no extra alpha QA control |
| Focus, Restore, Zoom | Focused pill mode, remembered ratio, CarPlay chrome | Return to previous split and preserve app scenes and saved ratio |
| All eight layouts and HUD/Settings | Container tree, layouts, options and output labels | Compare native and QA with same device conditions |

For each state retain: a manual state ID; matching timestamp; sanitised JSON and file SHA256; screen resolution and scale; screenshot (shared separately, with consent); Native12 package SHA; known missing observations. Do NOT claim 100% source/runtime behavior from a single snapshot.

## Concrete independent architecture

1. Freeze QA7 UI acceptance (REJECTED) and preserve a proven source-owned app/scene playback facade only. QA alpha root, placeholder, picker and bar overlay remain rejected; delete them as replacements pass, not merely hide them.
2. Build an independent Native12-measured UIKit UI module, in order: **CarPlay window and chrome → native-style splash/root → split hit-test/panes → placeholders/pills → divider pan/swap/hold → picker and menu → settings/HUD**. Do not link source/binaries from the original runtime, license manager, or its time/device restrictions.
3. Produce a structured diff for each state: bounds/safe area, UIWindow level, frame in receiver coordinates, colors (where resolved), z-order, gesture/hit regions, functional outcome. If device conditions match, propose a <=1pt geometric tolerance only AFTER collecting native measurement; differences otherwise explicitly fail.
4. Port one component with a source test, compilation and the matching real CarPlay A/B capture. Keep QA UI outside the package once that component's independent replacement is verified. Do not silently leave dormant QA widgets.
5. Gate any new separately-versioned QA DEB on measured reference equivalence and interactive two-app tests. Do not publish unverified QA on Sileo. Stable Native12 HUD8 must remain unchanged.

## Current limitations and next action

The files above are newly created **source-only**. They do not mean a native runtime has been observed; neither a diagnostic DEB nor a tested capture file currently exists. Next verify ARM64 compile in GitHub Actions, review the SpringBoard-safe read-only boundary, then (after approval to install diagnostic instrumentation) collect Native12 reference snapshots, starting with startup window + divider gestures. UIKit runtime snapshots alone cannot guarantee exact pixel-by-pixel rendering, identify all private callpaths or replace tests on the real CarPlay receiver.
