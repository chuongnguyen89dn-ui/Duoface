# DuoFace Native Scene Host — isolated Stage B executable app

Source branch: `feature/duoface-native-scene-join-v1-20261020`.

This is a real UIKit application with independent bundle ID `com.duoface.native.scenehost`, a phone scene and an ordinary **CarPlay UIWindowScene role**. It does not claim CarPlay will admit it: iOS16 uses a private LaunchServices/CarPlaySupport entitlement/capability gate, requiring a distinct, ABI-gated and reversible admission implementation. This app alone does NOT carry an Apple-issued entitlement and merely declaring the role does NOT grant it.

The system must hand a `UIWindowScene` to `DFNativeHostCarSceneDelegate` before it creates `UIWindow initWithWindowScene:`. No manual Dock visibility, 45pt hardcode, FBSDisplayConfiguration, fake Dock, full-screen external SpringBoard window or image transport. The only CarPlay view is an honest placeholder that reports: “Chưa nối hai ứng dụng iPhone”. Stage C later integrates existing live V1BC scenes and real input, not this placeholder.

Status: BUILD CANDIDATE ONLY. Never publish this to public Sileo as a working DuoFace before private admission path and phone/CarPlay device safety have been verified. Does not modify current QA6, QA11, Native12, HUD8 or MyTweak recovery.
