# Independent SpringBoard app-admission ABI probe

Branch: `feature/duoface-sb-admission-probe-20261020`.

This is a **read-only diagnostic**, NOT an application admission hook. Target ONLY SpringBoard, never CarPlay/Carkitd/other applications. On injection, register one Darwin notification callback; do nothing else except log an idle marker. When the user explicitly presses the **Kiểm tra API SpringBoard** button inside DuoFace QA, the app sets `Enabled=true` with a UUID/timestamp in `/var/mobile/Library/Preferences/com.duoface.sb-admission-probe.request.plist` and posts `com.duoface.nativejoin.sborder.probe`. Only a fresh (<=30s) UUID-valid opt-in is accepted, then the callback resets Enabled=false BEFORE read-only class/selector inspection. Output `/var/mobile/Library/Logs/DuoFaceSBAdmissionProbe.log` + status `/var/mobile/Library/Preferences/com.duoface.sb-admission-probe.status.plist`. The user shares both logs with existing DuoFace QA's share UI. There is **no automatic SpringBoard restart**, so if the dylib hasn't loaded, the app will show no new status, never a false pass.

The only observed APIs are Objective-C class existence and `method_getTypeEncoding` for: `FBSApplicationInfo.entitlementValuesForKeys:`, `LSBundleInfoCachedValues.boolForKey:` and object/number getters, `LSBundleProxy` typed2/typed3 entitlement getters, bulk getter, `objectForInfoDictionaryKey:ofClass:`, `LSApplicationProxy.applicationProxyForIdentifier:`, and native CarPlay classes. **This cannot determine live return-object class** — don't claim `LSBundleInfoCachedValues` was actually returned before a separate strictly controlled runtime path captures a value.

No `%hook`, `MSHookMessageEx`, `method_setImplementation`, `objc_msgSend`, entitlement override, bundle rewriting, `sbreload`, Dock window operation or scene window.

Package `com.duoface.carplay.sbadmissionprobe` has no conflicts/replaces or maintainer scripts, and installs as a **separate** module; QA6, nativejoinprobe, Native12/HUD8, QA11, recovery remain unchanged. To roll back uninstall ONLY this diagnostic package in Sileo. Since no auto-respring, it may take the next normal SpringBoard injection lifecycle to become active (one-time explicit user testing only when needed).

**Next stage after actual iOS16 SpringBoard ABI logs:** independent first-party bundle-only `com.duoface.native.scenehost` admission, default-off kill switch, strict typed-return safety and actual Dashboard app icon/scene testing on parked car; then existing V1BC live scene+full touch bridge.
