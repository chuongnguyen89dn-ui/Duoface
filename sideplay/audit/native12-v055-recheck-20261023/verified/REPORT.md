# Actual signed Native12 original vs .54 vs .55 DEB binary comparison

Evidence: exact downloads, pinned SHA256 verification, dpkg-deb extraction,
Mach-O inventory, sha256 per Mach-O, Objective-C metadata with otool.
No UIKit rendering, installed hardware logs, or entitlement-based CarPlay PASS.

| Verified package | Version | SHA256 | Mach-O |
|---|---|---|---:|
| com.duoface.independent | 0.1.0~native12+speed8compact | `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad` | 8 |
| com.duoface.jb.embedded | 0.0.54~nativecard1 | `2c582c0227035c136c5f66fc4bb9268f459e68a5c777df7e2f787c11b90aa14d` | 6 |
| com.duoface.jb.embedded | 0.0.55~zoomgrip1 | `6084d2c56e9a4c5eba2bcf4b0b7ca445a37a5edeae34c0dfd72955321193923b` | 6 |

## Actual changed ARM64 images from .54 to .55
- `var/jb/Library/MobileSubstrate/DynamicLibraries/DFCarPlayDockOwner.dylib`: d147dd6178cd061c36966bedbccf0894f2bf29e51c8b1a9b80539162220f6c35 → 2e6da03f4d27d07a777e09ac10931e5616da161d458a0c9793c3244af8addac6
- `var/jb/Library/MobileSubstrate/DynamicLibraries/DFFirstPartyAdmission.dylib`: 4e98eaebb76cc26d3c58829f71a35d1378008c8252af5c04c8921f9902ea7224 → 2888555cdc67bd7e95ddf308280c3d9c1ddfa97aa5e5f5ee6803da5cd064157a
- `var/jb/Library/MobileSubstrate/DynamicLibraries/DFNativeDashboardBridgeQA.dylib`: 40735763ee32164c1c1abf83568bbbfd2e889e7693d1ac7af670c83937afdf4f → d243d1d5d5a1df5b402cd5d4850960a15e3a96a82d27d60b4047639bc0585483
- `var/jb/Library/MobileSubstrate/DynamicLibraries/DFTouchOwnerProbe.dylib`: c17470a2cb0370bd3f766e15daec03b7833681df333c6aa107ee40cfc3e21dd5 → 06cbb71fff8fa3efaa2f7a698378faa3328c1e99e97697bbbb095d6fff31d81f
- `var/jb/Library/MobileSubstrate/DynamicLibraries/DFV1APreflight.dylib`: eba12bad0d116756f70a63141b09332538436ae081e933ae778ae735097ac94e → 145c168e364f279c3d31d97aea591386c3ba027f919949e598201e7b2d0f71f6

## Original vs independent owner/selector proof
- `CBMultitaskingOverlayView`: original ['var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib', 'var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib']; .55 []
- `setupCardContent`: original ['var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib', 'var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib']; .55 []
- `setupAppPickerCardsInCardW`: original ['var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib', 'var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib']; .55 []
- `setupRecentAppsCardsInCardW`: original ['var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib', 'var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib']; .55 []
- `showAppPickerForSlot`: original ['var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib']; .55 []
- `dismissOverlay`: original ['var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib']; .55 []
- `appSelected:`: original ['var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib']; .55 []
- `_appSegmentBtn`: original ['var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib', 'var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib']; .55 []
- `_layoutSegmentBtn`: original ['var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib', 'var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib']; .55 []
- `_recentSegmentBtn`: original ['var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib', 'var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib']; .55 []
- `DuoFace`: original ['var/jb/Applications/DuoFaceUI.app/DuoFaceUI', 'var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib', 'var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib', 'var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceLogoGripOnly.dylib', 'var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceSpeedHUD.dylib', 'var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceSpeedOwner.dylib', 'var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.dylib']; .55 ['var/jb/Applications/DuoFaceNativeHost.app/DuoFaceNativeHost', 'var/jb/Library/MobileSubstrate/DynamicLibraries/DFCarPlayDockOwner.dylib', 'var/jb/Library/MobileSubstrate/DynamicLibraries/DFFirstPartyAdmission.dylib', 'var/jb/Library/MobileSubstrate/DynamicLibraries/DFNativeDashboardBridgeQA.dylib', 'var/jb/Library/MobileSubstrate/DynamicLibraries/DFTouchOwnerProbe.dylib']
- `native12-action-row`: original []; .55 []
- `native12-ellipsis`: original []; .55 ['var/jb/Library/MobileSubstrate/DynamicLibraries/DFTouchOwnerProbe.dylib']
- `native12-zoom-button-touchdown`: original []; .55 ['var/jb/Library/MobileSubstrate/DynamicLibraries/DFTouchOwnerProbe.dylib']
- `Zoom In`: original ['var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib']; .55 ['var/jb/Library/MobileSubstrate/DynamicLibraries/DFTouchOwnerProbe.dylib']
- `Zoom Out`: original ['var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib']; .55 ['var/jb/Library/MobileSubstrate/DynamicLibraries/DFTouchOwnerProbe.dylib']
- `DFNative12Chrome`: original []; .55 ['var/jb/Library/MobileSubstrate/DynamicLibraries/DFTouchOwnerProbe.dylib']

## Verdict boundary
- Native12 original CBMultitaskingOverlayView != independent DFNative12Chrome class; historical binary owner method evidence cannot be equated with current independent implementation.
- Presence of a binary string or Objective-C selector does NOT prove CarPlay touch invocation or physical Dock hide.
- Source and packaging CI passing does NOT prove exact original UI/behavior. Real fullscreen, logo 3s, ratio, video crashing, auto-hide, and restore require device QA.
- No licensing framework or proprietary implementation has been imported through this forensic read-only workflow.
