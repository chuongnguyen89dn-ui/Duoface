# iOS 16 first-party CarPlay admission — confirmed ABI / next engineering gate

## Actual iPhone X, CarPlay process (user supplied 2026-10-20)

The user tested public `com.duoface.carplay.nativejoinprobe 0.0.3~rosterabi1` while **MyTweak, bridge, 45-second Dock trial ALL OFF**.

```
native-admission-abi CARApplication=no allInstalled=class-unavailable byBundleID=class-unavailable
LSBundleProxy=yes
typed3=@40@0:8@16#24#32
typed2=@32@0:8@16#24
bulk=@24@0:8@16
infoDictionary=selector-unavailable
FBSApplicationInfo=yes fbBulk=selector-unavailable
DBApplicationInfo=yes workspaceInitOwner=@24@0:8@16
```

Prior verified from same device:

```
native-workspace-abi workspace=yes requestStateChange=v24@0:8@16
controller=no sharedInstance=class-unavailable request=yes activateApplication=v24@0:8@16 owner=yes
nativeChrome=1 full={{0,0},{507.3333333,240}}
native-bar-frame={{0,0},{45,240}} usable={{45,0},{462.3333333,240}}
```

The ABI strings are Objective-C runtime method type encodings. The read-only probe has **not invoked** these methods. In this **CarPlay process**, the two explicitly queried LSBundleProxy typed entitlement selectors have object returns and expected Class arguments; this is not evidence their return values or policy for our app. Missing `CARApplication` and `DBApplicationController` may be a process/framework-load boundary, not proof such classes never exist elsewhere. Repeated sampling showed the same signatures. No real DuoFace host scene was admitted.

## Design decision (mandatory safety)

**Do not** call `DBApplicationController.sharedInstance`; missing here. **Do not** blindly change the `LSBundleProxy` return value or issue `DBWorkspace.requestStateChange:`: both are high-risk launch/scene APIs and cross-process effects were not verified. Do not set a fake Dock or translate the CarPlay bar by 45pt. Never use the old QA5/QA6 temporary UIWindow crop as native app admission.

Stage B candidate already compiled: `sideplay/duoface-native-scene-host` bundle `com.duoface.native.scenehost`, UIKit CarPlay `UIWindowSceneSessionRoleCarPlay` and delegate. Correct native Dashboard path requires a **system-issued** CarPlay UIWindowScene and an independent, iOS16-version-checked first-party **bundle-only** admission gate; merely shipping the scene manifest is insufficient.

## Next coding milestone

1. Inspect local SpringBoard-side and CarPlay host-side admission symbols with READ-ONLY runtime ABI inventory in an isolated **opt-in** package to establish where `LSBundleProxy` gating really occurs. Never hook any entitlement accessor until both calling convention AND returned instance **class** are safely known; the `FBSApplicationInfo` bulk method did not appear in this process.
2. If building admission, protect it behind an OFF-by-default preference and a one-bundle allowlist exactly `com.duoface.native.scenehost`. Fail closed for unknown iOS versions, missing classes/methods, wrong return types, multi-process disagreement and missing scene cleanup. Preserve all existing app entitlements for other bundles; NO changing LaunchServices database persistently and NO licensing code.
3. First success gate on a parked vehicle: DuoFace icon is admitted to Dashboard without manual Dock trial; tap it, confirm `DFNativeHostCarSceneDelegate` receives a UIKit-owned scene and existing native Dock stays visible for >=2 minutes; leave/reenter, reconnect, verify cleanup and no SpringBoard/CarPlay process restarts. Only then Sileo prototype admission can be called working.
4. Then wire a single existing V1BC hosted iPhone-app live scene + begin/move/end/cancel input and disconnect cleanup; only after one-app device pass connect two V1BC slots, drag ratio, long press swap and Zoom.

## State / evidence

- User device result: verified **passive** native Dock geometry and **passive** ABI only; no admission, no iPhone touch hosting.
- Source branch: `feature/duoface-native-scene-join-v1-20261020`.
- Existing candidate build run: `39382552551` SUCCESS, artifact HEAD `ccc0ee911088b5e0ee817e2779dc68bedc6dcb9b`.
- Public roster ABI diagnostic publish run `39382915334` SUCCESS; iPhone QA can share this log. Host binary remains unpublished.
- Keep QA6, Native12/HUD8, QA11 and MyTweak recovery unchanged.
