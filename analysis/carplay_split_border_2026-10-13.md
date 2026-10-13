# DuoFace 12 / DuoNavi 1.0.3 — split-pane border blinking (static DEB inspection)

## Evidence and inputs
- User photo `IMG_7929.jpeg`: two dark side-by-side CarPlay panes outlined in thin blue, with vertical divider.
- Original package local: `/mnt/data/com.duonavi.app_1.0.3_iphoneos-arm64 2.deb`.
- DuoFace 12 local: `/mnt/data/duoface12_base.deb` (previously verified against v12 artifact).
- Commands: `dpkg-deb -x PACKAGE.deb OUTPUT_DIR`; `strings PATH_TO_DYLIB | grep -Ei 'border|blink|touch|pulse'`; `llvm-objdump --macho --objc-meta-data PATH_TO_DYLIB`; `llvm-objdump --macho -d PATH_TO_DYLIB`.
- Original dylib `var/jb/Library/MobileSubstrate/DynamicLibraries/DuoNaviDashboard.dylib`, SHA256 `4fcf2f6b75828075736f942cde7721e808bbc5699f73045842266bdc865b7cd0`.
- DuoFace dylib `var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib`, SHA256 `bc1df854ec7a2ddfeec4cb81b080ead34b54df80143d4a8f6254bb8b618003ce`.

## Directly recovered Objective-C implementation
- `startContainerBorderBlinking:` implementation offset `0x11fa88` in original dylib; `stopContainerBorderBlinking:` offset `0x11fcd4`. Methods in split screen controller class metadata (near `startBlinkingSession`/`stopBlinkingSession`).
- `startContainerBorderBlinking:` gets target view's `layer`, removes prior animation named `borderPulse`, constructs `CABasicAnimation animationWithKeyPath:@"borderColor"`, sets color values, duration, `setAutoreverses:YES`, `setRepeatCount:` with float infinity `0x7f800000`, timing `kCAMediaTimingFunctionEaseInEaseOut`, then `addAnimation:forKey:`.
- `stopContainerBorderBlinking:` obtains target `layer` and calls `removeAnimationForKey:@"borderPulse"`.
- Other selectors `setBorderWidth:`, `setBorderColor:`, `systemTealColor`, `layoutSplitViews`, `handleDividerPan:isVertical:state:`, `touchesBegan:withEvent:`, `touchesMoved:withEvent:`, `touchesEnded:withEvent:`, `startBlinkingSession`, `stopBlinkingSession` are present.
- `DuoFaceVisualHook.dylib` strings explicitly say `[DuoFaceVisual12] divider applied; touch/long-press/pan unchanged`, meaning the visual hook does not claim to replace touch handling.
- Therefore blue outlines are CALayer-based and blinking is a Core Animation `borderColor` pulse. Exact user-touch -> start/stop event path and numeric animation duration/color remain to be fully traced; do not claim verified runtime trigger without a device.
- This does NOT require changing CarPlay injection filters, package IDs, or licensing. No DEB modified or deployed.

## Next
Trace callers of `startBlinkingSession` and `startContainerBorderBlinking:` using Objective-C selector references/disassembly, and extract animation constants. If user later requests a change, patch only relevant visual logic with existing signed hook while preserving drag/long-press/CarPlay split.
