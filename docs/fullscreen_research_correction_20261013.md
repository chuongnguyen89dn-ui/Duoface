# Fullscreen research: cross-checked binary findings

Inputs available locally: user-uploaded Airaw 1.7.1k DEB and DuoFace v12 DEB. Inspection uses extracted arm64 Airaw.dylib and llvm-objdump disassembly.

## Verified

- In Airaw, `DBDockWindow` has a `layoutSubviews` hook. Its body calls the original implementation and Objective-C stubs `isChk` and `setIsChk:`. These are **not** frame resize functions.
- `DBApplicationViewController` has dynamically registered properties `isFull`, `savedRect` (`CGRect`), `savedEdgeInsets` (`UIEdgeInsets`), and `hostMenu`. The registrations coexist with native split properties; the saved geometry properties alone cannot establish which feature uses them.
- Two callsites (`0x254fc` and `0x2b0bc`) load a pointer to the string `toggleFullscreen` (selector reference 0x80498) and dispatch via another function. The callsites do **not** by themselves prove the recipient is the host fullscreen controller, or that a window frame is changed.
- Preference bundle has a distinct Host Menu fullscreen setting separate from native/standard/shared Split View.
- DuoFace v12 has `expandTapped:` but its existing action is pane expansion, not a whole-CarPlay-screen toggle.

## Important correction

Do not infer before/after screen dimensions from `savedRect` or from the `DBDockWindow.layoutSubviews` hook. Neither contains measured values or a demonstrated resize path. The actual fullscreen receiver, dock visibility mutation, and host view geometry mutation remain the required reverse-engineering targets.

## Verification boundary

Static Mach-O analysis was performed. No CarPlay runtime test or new fullscreen v12 DEB was produced. The user-uploaded v12 package should be preserved unchanged. For actual before/after geometry, collect `DBApplicationViewController.view.frame`, parent bounds, `DBDockWindow.frame/hidden`, and safe area in a separate debug hook on the target CarPlay device; then implement an opt-in toggle only after those runtime values are available.
