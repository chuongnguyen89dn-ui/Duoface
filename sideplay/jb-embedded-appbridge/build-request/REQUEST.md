# DuoFace .88 original Native12 internal-window YouTube reflow — 2026-10-28

User DEVICE-FAIL .87: video orientation still wrong in split; correct after solo/fullscreen, additionally correct after swipe down from top of YouTube. NOT proof which UIKit event is responsible. Original SHA-pinned Native12 ARM64 window layout helper @0x2aa2e4 class-side UIWindow +internal visible windows; .87 only enumerated owned UIWindowScene.windows. .88 reconciles additional windows ONLY under exact same owned UIWindowScene and current lease/generation; runtime signature ABI guard, ACK counts, no guessed aspect ratios or fixed landscape; existing .83 video lifecycle, Maps/Dock/UI unchanged.

Source-only macOS run 40655737990 SUCCESS (including native Foundation ABI executable gate and iOS16 SDK source syntax/link). Trigger ONE full existing integrated rootless .88 package. New host 0.1.97~uikitreflow1 and integrated 0.0.88~uikitreflow1. Verify actual package, checksum, immutable archive and handoff on GitHub. DO NOT assume device rotation now passes; Sileo release separate verified gate. Preserve .83/.84/.86/.87 rollback.

Build marker: 088-original-uikitreflow-1.
