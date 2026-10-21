# DuoFace Native Scene Host — isolated Stage B executable app

Source branch: `feature/duoface-native-scene-join-v1-20261020`.

This is a real UIKit application with independent bundle ID `com.duoface.native.scenehost`, a phone scene and an ordinary **CarPlay UIWindowScene role**. It does not claim CarPlay will admit it: iOS16 uses a private LaunchServices/CarPlaySupport entitlement/capability gate, requiring a distinct, ABI-gated and reversible admission implementation. This app alone does NOT carry an Apple-issued entitlement and merely declaring the role does NOT grant it.

The system must hand a `UIWindowScene` to `DFNativeHostCarSceneDelegate` before it creates `UIWindow initWithWindowScene:`. No manual Dock visibility, 45pt hardcode, FBSDisplayConfiguration, fake Dock, full-screen external SpringBoard window or image transport. The only CarPlay view is an honest placeholder that reports: “Chưa nối hai ứng dụng iPhone”. Stage C later integrates existing live V1BC scenes and real input, not this placeholder.

Status: BUILD CANDIDATE ONLY. Never publish this to public Sileo as a working DuoFace before private admission path and phone/CarPlay device safety have been verified. Does not modify current QA6, QA11, Native12, HUD8 or MyTweak recovery.


## 0.0.4~template1 — CarPlay Home **real scene admission** experiment (NOT device verified)
The original SidePlay 1.0.4 package audit includes a `CPTemplateApplicationScene` marker in its own iPhone app binary; earlier DuoFace NativeHost used ONLY the generic `UIWindowSceneSessionRoleCarPlay` role and never received a confirmed native icon/scene. This experiment adds a **separate genuine CarPlay navigation-template role** to the same independent NativeHost app, plus the exact jailbreak-signed `com.apple.developer.carplay-maps` key. The app still keeps the old ordinary UIKit CarPlay role for regression comparison. The added `DFNativeHostTemplateSceneDelegate` **only** runs if CarPlay provides a `CPWindow`; assigns a minimal no-interaction proof UI to that window and sets `CPMapTemplate` root. Does not use CarBridge/DuoDash/DuoNavi binary or license, does not open arbitrary apps, create a fake Dock or mutate system icon layout.

Important: `ldid -Sentitlements.plist` embeds a claim; it is NOT proof CarPlay accepts the entitlement on iOS16 jailbreak. The CPWindow surface in Apple's navigation model is map-only and isn't a generic interactive two-pane UI. This is a parked-car gate to decide whether a native CarPlay scene can be issued at all, not a claim the full DuoFace app has been delivered. Success criteria: system CarPlay Home icon visible → tap → log `native-carplay-template-scene-connected` and screen evidence → native Dock unchanged, no exitmode. Failure or safe mode: uninstall isolated package; no automatic respring. Native12, HUD8 and stable QA are unchanged. CI can prove code signing/packaging only.
