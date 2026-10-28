# DuoFace .88 original Native12 internal-window YouTube reflow — 2026-10-28

User DEVICE-FAIL .87: video orientation still wrong in split; correct after solo/fullscreen, additionally correct after swipe down from top of YouTube. NOT proof which UIKit event is responsible. Original SHA-pinned Native12 ARM64 window layout helper @0x2aa2e4 class-side UIWindow +internal visible windows; .87 only enumerated owned UIWindowScene.windows. .88 reconciles additional windows ONLY under exact same owned UIWindowScene and current lease/generation; runtime signature ABI guard, ACK counts, no guessed aspect ratios or fixed landscape; existing .83 video lifecycle, Maps/Dock/UI unchanged.

Source-only macOS run 40655737990 SUCCESS (including native Foundation ABI executable gate and iOS16 SDK source syntax/link). Trigger ONE full existing integrated rootless .88 package. New host 0.1.97~uikitreflow1 and integrated 0.0.88~uikitreflow1. Verify actual package, checksum, immutable archive and handoff on GitHub. DO NOT assume device rotation now passes; Sileo release separate verified gate. Preserve .83/.84/.86/.87 rollback.

Build marker: 088-original-uikitreflow-1.

## CI rerun after exact regression failure
Run 40655833401 FAILED only at unit source assertions with stale .87/.1.96 version literals in test_nativeowner_086.py and test_orientation_policy_084.py; new .88 test itself PASS. Updated expected strings to .88/.1.97 at commits 231abdbb and 2d53ca63. No binary compiled in failed run. Re-run current source full package.
Build marker: 088-original-uikitreflow-2.

## Re-run archiver version gate
Run 40655957242 passed source/unit/runtime and signed .88 integrated package before archive, but evidence-saving script failed: `ValueError: expected exactly one staged .87 DEB` from `sideplay/tools/append_086_ci_handoff.py`. Corrected script to match .88 artifact, include physical .87 fail and swipe evidence. Re-run immutable export; no device/Sileo claim.
Build marker: 088-original-uikitreflow-3.
