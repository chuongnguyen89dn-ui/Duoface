# Verified read-only original104 vs Native12 startup, placeholder and CarPlay window ARM64

This is static disassembly only, never native UI/device validation.

| Binary | Class | Methods in binary | Selected methods and IMPs |
| --- | --- | ---: | --- |
| native12 | CBWindow | 37 | createWindows 0xb1064, resizeWindows 0xb1aac, show 0xb1d98, hide: 0xb1ec0, carPlayContentInsets 0xb0c98, carPlayUsableBounds 0xb0ef4 |
| native12 | CBSplitSplashScreenView | 16 | initWithFrame: 0xb6358, layoutSubviews 0xb6fdc, startLoadingAnimation 0xb73bc, handleTap: 0xb75e4, dismissAnimated: 0xb767c, dismissAnimated:completion: 0xb768c |
| native12 | CBSlotPlaceholderView | 16 | initWithSlotIndex: 0x10199c, updateLocalizedTexts 0x102068, layoutSubviews 0x1020cc, placeholderTapped: 0x1022c8 |
| native12 | CBSplitContainerView | 6 | layoutSubviews 0x101790, hitTest:withEvent: 0x10182c, touchesBegan:withEvent: 0x1018e8 |
| native12 | CBUIAppContainerView | 6 | layoutSubviews 0xb9730, hitTest:withEvent: 0xb97cc, touchesBegan:withEvent: 0xb9888 |
| native12 | CBMultitaskingOverlayView | 66 | setupCardContent 0xa2a58, setupAppPickerCardsInCardW:cardH:contentY: 0xa3e5c, setupRecentAppsCardsInCardW:cardH:contentY: 0xa678c |
| native12 | CBDividerView | 27 | handlePan: 0x10152c, handleMoveButtonLongPress: 0x1005f4, gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer: 0xfea48 |
| original104 | CBWindow | 40 | createWindows 0xb173c, resizeWindows 0xb24ac, show 0xb2814, hide: 0xb29b0, carPlayContentInsets 0xb1370, carPlayUsableBounds 0xb15cc |
| original104 | CBSplitSplashScreenView | 16 | initWithFrame: 0xb72b0, layoutSubviews 0xb7f34, startLoadingAnimation 0xb8340, handleTap: 0xb85a8, dismissAnimated: 0xb8640, dismissAnimated:completion: 0xb8650 |
| original104 | CBSlotPlaceholderView | 16 | initWithSlotIndex: 0x108e48, updateLocalizedTexts 0x10956c, layoutSubviews 0x1095d0, placeholderTapped: 0x1097f8 |
| original104 | CBSplitContainerView | 6 | layoutSubviews 0x108bb8, hitTest:withEvent: 0x108c80, touchesBegan:withEvent: 0x108d68 |
| original104 | CBUIAppContainerView | 6 | layoutSubviews 0xbfa44, hitTest:withEvent: 0xbfb0c, touchesBegan:withEvent: 0xbfbf4 |
| original104 | CBMultitaskingOverlayView | 66 | setupCardContent 0xa21c8, setupAppPickerCardsInCardW:cardH:contentY: 0xa35cc, setupRecentAppsCardsInCardW:cardH:contentY: 0xa5efc |
| original104 | CBDividerView | 27 | handlePan: 0x108954, handleMoveButtonLongPress: 0x107964, gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer: 0x105c80 |

## Geometry / compositing method review gates
Review ARM64 in METHODS.json at each method's `arithmetic_and_uikit_windows`;
do not invent UIWindowLevel, color, CGRect or live CarPlay safeArea.
Port startup splash/slot placeholder/window/input behaviors as independent UIKit.
Never link original Dashboard binary, CBBridgeManager or trial/license code.
