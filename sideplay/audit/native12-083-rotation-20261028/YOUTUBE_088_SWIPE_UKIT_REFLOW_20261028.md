# DuoFace .87 device failure + swipe-down orientation transition — investigation and .88 candidate (2026-10-28)

## Latest DEVICE evidence (supersedes .87's unverified expectation)
- User installed/tests DuoFace .87 through Sileo and confirms **FAIL**: YouTube video remains upside down / wrong orientation in the split layout; using a single-pane / YouTube's own fullscreen makes it correct.
- **NEW user observation**: swiping downward from the top of the YouTube interface can *also* make video orientation correct WITHOUT the prior fullscreen workflow. Record this exact transition as physical evidence; it may trigger UIKit layout/orientation/visibility reconciliation. Do **NOT** assert that the swipe is specifically Notification Center, Control Center, an AVPlayer bug, or a known value 1/3/4 without device trace. This observation weakens fixed width/rotation/aspect-ratio explanations.
- Images provided by user in current conversation (not claimed stored in GitHub): initial video inverted relative to DuoFace/CarPlay Dock; when fullscreen the YouTube UI is oriented consistently. New symptom independently confirms a UI transition can correct it without replacing media.
- Reported Maps untested/unchanged; do not touch Maps, Dock, logo, menu or known working .83 media lifecycle.

## Independently rechecked ORIGINAL Native12 ARM64 on GitHub
- Original verified DEB SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`.
- Source: `NATIVE12_ORIGINAL_APP_ORIENTATION_HELPER_RUN_40648090838.json` (GitHub preserved, ~364 kB); `NATIVE12_ORIGINAL_HOST_TO_APP_YOUTUBE_HANDSHAKE_20261028.md`.
- Original app-process reconciler @0x2aa2e4 references `UIWindow` **class**, @0x2aa2ec sends class-selector `+allWindowsIncludingInternalWindows:onlyVisibleWindows:`; @0x2aa348..0x2aa3cc uses underscored class-selector fallback when necessary. It then processes extra windows and invokes private window rotation + frame/bounds + layout @0x2aa44c..0x2aa520.
- Separate @0x2aa554..0x2aa600 calls `updateLayoutToCurrentInterfaceOrientation` specifically on `UIKeyboardImpl activeInstance` (when available). Do NOT misapply that original keyboard selector to arbitrary YouTube root view controllers.
- In .87 `DFYouTubeOrientationRelay.m` loops **only** `owned.windows` and skips other UIKit internal UIWindow instances even if those windows belong to the same exact owned scene. The missing enumeration is **proven source difference**. It is NOT proven from user screenshots that the problematic video is in such an internal window.

## .88 scoped change (independent source, no vendor copy)
- `DFYouTubeHostState.h`: verify UIWindow **class-method ABI** before optional enumeration; try both original selector spellings. Do not mistakenly call an application instance selector. The result is only an array of candidates and provides NO authorization to mutate unrelated windows.
- `DFYouTubeOrientationRelay.m`: merge `owned.windows` and optional UIWindow internal list, dedup and strictly require `window.windowScene==owned`, visible, normal-level, nonkeyboard/text, exact owner/scene and fresh lease. Apply existing portrait/size-window reconciliation and UIKit layout on current scene; restore original snapshots only for same live scene.
- `DFSceneHost.m`: surface an ACK with counts of scene windows, internal windows, layout calls and real UIWindowScene orientation/geometry. This differentiates app injection missing, scene ID mismatch, extra video UIWindow absent, and app/AVPlayer presentation disagreement.
- No global hooks, no hardcoded landscape 3/4, no arbitrary map scale/percentage. `DFSceneLifecycle.m` known good .83 unchanged. No change in Maps/Dock. All patches compile/test via existing macOS CI before version delivery.
- `tests/test_youtube_internal_reflow_088.py` verifies ownership/filter, original class-side API, baseline and diagnostic receipts. **Source tests and CI are not device acceptance**.

## Acceptance and diagnostic path
1. Build an *isolated* .88 signed rootless DEB via the existing first-party GitHub macOS workflow. Archive run ID, SHA256, exact branch commit. Keep .87/.86/.83 rollback immutable.
2. Publish only that proven binary in existing Sileo APT, verify remote Packages and remote DEB SHA; no speculative user-install claims.
3. On parked actual CarPlay test: YouTube immediately after opening in two panes; one-pane DuoFace focus; swipe down from top of YouTube interface; YouTube built-in fullscreen and restore; capture log `/var/mobile/Library/Logs/DuoFaceSceneHost.log` `youtube-app-handshake-ack` with `phase,windowsApplied,normalSeen,internalSeen,layoutRefreshed,sceneOrientation,sceneWidth,sceneHeight`. Record which transition first makes video correct. Do not confuse full-screen of pane with full-screen of video.
4. **If app relay ACK is absent / phase scene-id-unmatched / internalSeen=0:** investigate exact YouTube process injection/filter and server-vs-client scene ID before applying more orientation patches. If ACK proves owned video windows reflow but video still wrong, focus on player-specific presentation or orientation event, not repeated FBScene setter/zoom guesses.

Status: user .87 DEVICE-FAIL for orientation. .88 patch in progress, no physical .88 test yet.
