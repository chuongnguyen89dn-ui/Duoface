# Original Native12 Speed8 vs DuoFace .53: actual DEB re-scan

Original DEB SHA256: 2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad
Current signed .53 DEB SHA256: 86dbb29a71c50712ada1a1d4d6efb8efdffa0535f91454026e11494323be960c
Original package/version: com.duoface.independent 0.1.0~native12+speed8compact
Current package/version: com.duoface.jb.embedded 0.0.53~zoommenulive1
Original Mach-O count: 8
Current Mach-O count: 6

## Original Objective-C selector evidence from extracted Mach-O
- CBMultitaskingOverlayView: var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib, var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib
- setupCardContent: var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib, var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib
- setupAppPickerCardsInCardW: var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib, var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib
- setupRecentAppsCardsInCardW: var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib, var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib
- showAppPickerForSlot: var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib
- dismissOverlay: var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib
- appSelected:: var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib
- _appSegmentBtn: var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib, var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib
- _layoutSegmentBtn: var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib, var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib
- _recentSegmentBtn: var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib, var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib
- DuoFace: var/jb/Applications/DuoFaceUI.app/DuoFaceUI, var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib, var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib, var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceLogoGripOnly.dylib, var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceSpeedHUD.dylib, var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceSpeedOwner.dylib, var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.dylib
- native12-action-row: not seen
- native12-ellipsis: not seen
- native12-zoom-button-touchdown: not seen
- Zoom In: var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib
- Zoom Out: var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib
- DFNative12Chrome: not seen

## Independent .53 actual binary evidence
- CBMultitaskingOverlayView: not seen
- setupCardContent: not seen
- setupAppPickerCardsInCardW: not seen
- setupRecentAppsCardsInCardW: not seen
- showAppPickerForSlot: not seen
- dismissOverlay: not seen
- appSelected:: not seen
- _appSegmentBtn: not seen
- _layoutSegmentBtn: not seen
- _recentSegmentBtn: not seen
- DuoFace: var/jb/Applications/DuoFaceNativeHost.app/DuoFaceNativeHost, var/jb/Library/MobileSubstrate/DynamicLibraries/DFCarPlayDockOwner.dylib, var/jb/Library/MobileSubstrate/DynamicLibraries/DFFirstPartyAdmission.dylib, var/jb/Library/MobileSubstrate/DynamicLibraries/DFNativeDashboardBridgeQA.dylib, var/jb/Library/MobileSubstrate/DynamicLibraries/DFTouchOwnerProbe.dylib
- native12-action-row: var/jb/Library/MobileSubstrate/DynamicLibraries/DFTouchOwnerProbe.dylib
- native12-ellipsis: not seen
- native12-zoom-button-touchdown: var/jb/Library/MobileSubstrate/DynamicLibraries/DFTouchOwnerProbe.dylib
- Zoom In: var/jb/Library/MobileSubstrate/DynamicLibraries/DFTouchOwnerProbe.dylib
- Zoom Out: var/jb/Library/MobileSubstrate/DynamicLibraries/DFTouchOwnerProbe.dylib
- DFNative12Chrome: var/jb/Library/MobileSubstrate/DynamicLibraries/DFTouchOwnerProbe.dylib

## 2026-10-23 physical screenshot comparison
The user photo shows only a narrow custom floating App / Zoom In / Style
/ Close strip covering two empty panes. The original DEB has native
CBMultitaskingOverlayView card lifecycle, setupCardContent and app
card method machinery. A lone 30pt detached toolbar cannot substitute
for that modal content. This report is real binary inspection and does
not authorize copying any proprietary license or binary.
The current unbuilt source change opening the existing complete first-party
App card is a candidate, not yet validated visually or on device.
For whole-host Zoom: real touch dispatch -> global Zoom -> actual native
CarPlay Dock hidden -> both scene panes fill screen -> reversible restore.
Selector presence never proves execution.
