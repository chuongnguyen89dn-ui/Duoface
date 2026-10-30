# Original DuoNavi / OmniCar — backlight, idle, lock and foreground binary crosscheck

This is **read-only SHA-checked binary string metadata**, not decompilation of playback
or a proof which original method executes. Does not ship original binary or license.

Hardware report QA120: sizing **works**; YouTube scrolling and other taps **work**,
but Play requires visibly lit iPhone. In originals, phone remains dimly lit.
A screen illumination correlation alone cannot distinguish media foreground policy
from touch target, app suspension, screen power and audio-session state.

## Original signed reference identity

### DuoNavi_1.0.4
- Package: `com.duonavi.app`
- Original exact SHA256: `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`
- Mach-O files scanned: 4

#### Original power/sleep candidate metadata from var/jb/Applications/DuoNaviUI.app/DuoNaviUI
- ROW_SCREEN_BLANK
- ROW_SCREEN_BLANK_SUB
- TB,N,V_screenBlankEnabled
- _screenBlankEnabled
- screenBlankEnabled
- screenBlankToggleChanged:
- setScreenBlankEnabled:

#### `var/jb/Applications/DuoNaviUI.app/DuoNaviUI`
- SHA256: `98607086f52c489a32fadff54f0868ca7d0bf07608573c2244319f0722ab995c`
- Backlight/idle/screen/foreground-related string candidates (25 shown):
  - `@_NSForegroundColorAttributeName`
  - `@_OBJC_CLASS_$_UIScreen`
  - `CADisplay`
  - `Disable background daemons to reduce temperature and RAM usage`
  - `Nonaktifkan background daemon untuk kurangi panas dan RAM`
  - `OVERLAY_BACKGROUND_TAG`
  - `RAM is in optimal state. No background apps running.`
  - `System optimization turns off background diagnostic and telemetry services, keeping your device cool during continuous CarPlay usage.`
  - `Termina i daemon in background per ridurre temperatura e RAM`
  - `Unlock full split-screen and multitasking on CarPlay.`
  - `[DuoNaviLicense] [DECISION: AUTO-HEAL] Missing actual subscription expiration metadata in sync.plist. Triggering immediate background sync...`
  - `[DuoNaviLicense] [DECISION: REFRESH REQUIRED] License refresh threshold reached (interval=%llu s, elapsed since last sync=%llu s). Triggering background refresh...`
  - `_NSForegroundColorAttributeName`
  - `_OBJC_CLASS_$_UIScreen`
  - `application:handleEventsForBackgroundURLSession:completionHandler:`
  - `applicationDidEnterBackground:`
  - `applicationWillEnterForeground:`
  - `caDisplay`
  - `com.apple.ScreenTimeUnlock`
  - `configureWithDefaultBackground`
  - `secondarySystemGroupedBackgroundColor`
  - `setBackgroundColor:`
  - `setObscuresBackgroundDuringPresentation:`
  - `setScreenBlankEnabled:`
  - `systemGroupedBackgroundColor`

#### Original power/sleep candidate metadata from var/jb/Library/MobileSubstrate/DynamicLibraries/DuoNaviDashboard.dylib
- BKSDisplayServicesSetScreenBlanked
- IOPMAssertionCreateWithName
- IOPMAssertionRelease
- PreventUserIdleSystemSleep
- ROW_SCREEN_BLANK
- ROW_SCREEN_BLANK_SUB
- SBSuspendedUnderLockManager
- TB,N,V_screenBlankEnabled
- [DuoNavi] Acquired PreventUserIdleSystemSleep assertion result: %d, id: %u
- [DuoNavi] Released PreventUserIdleSystemSleep assertion id: %u
- _screenBlankEnabled
- _shouldBeBackgroundUnderLockForScene:withSettings:
- _underLock
- acquireCarPlaySleepAssertion
- isUnderLock
- releaseCarPlaySleepAssertion
- screenBlankEnabled
- setScreenBlankEnabled:
- setUnderLock:
- shouldBeUnderLockForScene:

#### `var/jb/Library/MobileSubstrate/DynamicLibraries/DuoNaviDashboard.dylib`
- SHA256: `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`
- Backlight/idle/screen/foreground-related string candidates (89 shown):
  - `@"CADisplay"`
  - `@"CADisplayLink"`
  - `@_NSForegroundColorAttributeName`
  - `@_OBJC_CLASS_$_CADisplay`
  - `@_OBJC_CLASS_$_CADisplayLink`
  - `@_OBJC_CLASS_$_UIScreen`
  - `@_UIApplicationDidEnterBackgroundNotification`
  - `@_UIApplicationWillEnterForegroundNotification`
  - `@_UISceneWillEnterForegroundNotification`
  - `@_UIScreenDidConnectNotification`
  - `@_UIScreenDidDisconnectNotification`
  - `@_UIScreenModeDidChangeNotification`
  - `BKSDisplayServicesSetScreenBlanked`
  - `CADisplay`
  - `CADisplayLink`
  - `Disable background daemons to reduce temperature and RAM usage`
  - `Nonaktifkan background daemon untuk kurangi panas dan RAM`
  - `OVERLAY_BACKGROUND_TAG`
  - `RAM is in optimal state. No background apps running.`
  - `System optimization turns off background diagnostic and telemetry services, keeping your device cool during continuous CarPlay usage.`
  - `T@"CADisplayLink",&,N,V_displayLink`
  - `T@"UIView",&,N,V_dimBackground`
  - `TB,N,V_audioOnlyBackgroundMode`
  - `Termina i daemon in background per ridurre temperatura e RAM`
  - `UISceneDidEnterBackgroundNotification`
  - `UIScreen`
  - `UIScreenMode`
  - `URLSessionDidFinishEventsForBackgroundURLSession:`
  - `Unlock full split-screen and multitasking on CarPlay.`
  - `[CBWindow] Warning: Exception querying carPlayCADisplay bounds: %@`
  - `[CBWindow] Warning: Exception querying carPlayUIScreen bounds: %@`
  - `[DuoNaviApp] Waking app to active foreground state for CarPlay presentation: %@`
  - `[DuoNaviLicense] [DECISION: AUTO-HEAL] Missing actual subscription expiration metadata in sync.plist. Triggering immediate background sync...`
  - `[DuoNaviLicense] [DECISION: REFRESH REQUIRED] License refresh threshold reached (interval=%llu s, elapsed since last sync=%llu s). Triggering background refresh...`
  - `[DuoNaviSB] >>> CLOSE ALL: Terminating background applications & restarting active on-screen apps <<<`
  - `[DuoNaviSB] Close All (Fallback): Killing background PID %d for %@`
  - `[DuoNaviSB] Close All: Killing background PID %d for %@`
  - `[DuoNaviSB] UI closeAllBridgedAppsTapped: Killing background apps & restarting active on-screen apps`
  - `[DuoNaviSB] Warning: Exception killing background process %@: %@`
  - `[DuoNaviSB] [CONNECT_TRACE] CarPlay CADisplay available: %@`
  - `[DuoNaviSB] [DISCONNECT_TRACE]   - CADisplay[%lu]: %@ | name: %@ | uid: %@ | isMain: %d | screenType: %u`
  - `[DuoNaviSB] [DISCONNECT_TRACE] Disconnected screen is [UIScreen mainScreen] -> Ignoring.`
  - `[DuoNaviSB] [DISCONNECT_TRACE] No CarPlay CADisplay/UIScreen found -> CarPlay IS DISCONNECTED. Starting teardown.`
  - `[DuoNaviSB] [DISCONNECT_TRACE] Query Results -> carPlayCADisplay: %@ | carPlayUIScreen: %@ | carPlayWindowScene: %@`
  - `[DuoNaviSB] [DISCONNECT_TRACE] Total CADisplay count: %lu`
  - `[DuoNaviSB] [DISCONNECT_TRACE] Total UIScreen count: %lu`
  - `[DuoNaviSB] [LICENSE_KILL_TRACE] -> Found running background bridged app: %@ (PID: %@)`
  - `[DuoNaviSB] performAutoResume: CarPlay CADisplay not ready, retrying #%ld in 1.0s...`
  - `[DuoNaviSB] performAutoResume: CarPlay CADisplay still nil after 5 retries, giving up.`
  - `[DuoNavi] carPlayCADisplay exception: %@`
  - `_NSForegroundColorAttributeName`
  - `_OBJC_CLASS_$_CADisplay`
  - `_OBJC_CLASS_$_CADisplayLink`
  - `_OBJC_CLASS_$_UIScreen`
  - `_UIApplicationDidEnterBackgroundNotification`
  - `_UIApplicationWillEnterForegroundNotification`
  - `_UISceneWillEnterForegroundNotification`
  - `_UIScreenDidConnectNotification`
  - `_UIScreenDidDisconnectNotification`
  - `_UIScreenModeDidChangeNotification`
  - `_audioOnlyBackgroundMode`
  - `_blinkingIdleTimer`
  - `_dimBackground`
  - `_foreground`
  - `_foregroundActiveScene`
  - `_idleTimer`
  - `_notchIdleTimer`
  - `_shouldBeBackgroundUnderLockForScene:withSettings:`
  - `acquireCarPlaySleepAssertion`
  - `audioOnlyBackgroundMode`
  - `caDisplay`
  - `cancelIdleTimer`
  - `carPlayCADisplay`
  - `carPlayUIScreen`
  - `dimBackground`
  - `initWithCADisplay:isMainDisplay:`
  - `isForeground`
  - `isIdleTimerDisabled`
  - `releaseCarPlaySleepAssertion`
  - `restartIdleTimer`
  - `setAudioOnlyBackgroundMode:`
  - `setBackgroundColor:`
  - `setDimBackground:`
  - `setForeground:`
  - `setIdleAlpha:`
  - `setIdleModeEnabled:`
  - `setIdleTimerDisabled:`
  - `setScreen:`
  - `setScreenBlankEnabled:`

### OmniCar_1.0.3
- Package: `com.anlai.omnicar`
- Original exact SHA256: `d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd`
- Mach-O files scanned: 8

#### `var/jb/Applications/OmniCar.app/OmniCar`
- SHA256: `8e7dc4ddaf98a73b80910c0d5d00e38a084bfef2e9f97084f8bbdf76313807c8`
- Backlight/idle/screen/foreground-related string candidates (5 shown):
  - `_OBJC_CLASS_$_UIScreen`
  - `application:handleEventsForBackgroundURLSession:completionHandler:`
  - `applicationDidEnterBackground:`
  - `applicationWillEnterForeground:`
  - `setBackgroundColor:`

#### Original power/sleep candidate metadata from var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarAppBridge.dylib
- BKSDisplayServicesSetScreenBlanked
- SBSuspendedUnderLockManager
- SBSuspendedUnderLockManager -_shouldBeBackgroundUnderLockForScene:withSettings:
- _shouldBeBackgroundUnderLockForScene:withSettings:
- khong tim thay BKSDisplayServicesSetScreenBlanked

#### `var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarAppBridge.dylib`
- SHA256: `d99b8d00dc60f69db7b54fc1addaec6b8cb866b8dcdde6f1d85e06ce5b7d6e79`
- Backlight/idle/screen/foreground-related string candidates (17 shown):
  - `BKSDisplayServicesSetScreenBlanked`
  - `Background`
  - `CADisplay`
  - `CADisplayLink`
  - `SBSuspendedUnderLockManager -_shouldBeBackgroundUnderLockForScene:withSettings:`
  - `_OBJC_CLASS_$_UIScreen`
  - `_UIScreenDidConnectNotification`
  - `_UIScreenDidDisconnectNotification`
  - `_shouldBeBackgroundUnderLockForScene:withSettings:`
  - `barBackground:`
  - `initWithCADisplay:isMainDisplay:`
  - `isForeground`
  - `khong tim thay BKSDisplayServicesSetScreenBlanked`
  - `khong tim thay CADisplay cua CarPlay`
  - `setBackgroundColor:`
  - `setBackgrounded:`
  - `setForeground:`

#### `var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarCarProbe.dylib`
- SHA256: `85db0c33e9a918e9dfd944dcdc53e3326fb83259554d5c1a3fd976fcb9c6026f`
- Backlight/idle/screen/foreground-related string candidates (3 shown):
  - `_OBJC_CLASS_$_UIScreen`
  - `_UIScreenDidConnectNotification`
  - `_UIScreenDidDisconnectNotification`

#### `var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarCore.dylib`
- SHA256: `c95c66f46d960702e2f7f4ea930b85fd96d01709c2733a14373b37eaca9ed0a5`
- Backlight/idle/screen/foreground-related string candidates (3 shown):
  - `_OBJC_CLASS_$_UIScreen`
  - `_UIScreenDidConnectNotification`
  - `_UIScreenDidDisconnectNotification`

#### `var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarSpeedBubble.dylib`
- SHA256: `f9531a646d5ce11f70cba34d1b30c6ffed3311d347922b890e41b9b330b8a836`
- Backlight/idle/screen/foreground-related string candidates (16 shown):
  - `CADisplay`
  - `GetCarPlayCADisplay`
  - `UIBackgroundModes`
  - `_NSForegroundColorAttributeName`
  - `_OBJC_CLASS_$_UIScreen`
  - `_SPPGetCarPlayCADisplay`
  - `_UISceneDidEnterBackgroundNotification`
  - `_UISceneWillEnterForegroundNotification`
  - `_UIScreenDidConnectNotification`
  - `_UIScreenDidDisconnectNotification`
  - `anyAppForeground`
  - `initWithCADisplay:isMainDisplay:`
  - `setAllowsBackgroundLocationUpdates:`
  - `setBackgroundColor:`
  - `updateSpeed:limit:appForeground:`
  - `updateSpeed:limit:appForeground:app:`

#### Original power/sleep candidate metadata from var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarSplitScreen.dylib
- NoopLayoutAssertion
- SCPNoopLayoutAssertion
- _OBJC_CLASS_$_SCPNoopLayoutAssertion
- _OBJC_METACLASS_$_SCPNoopLayoutAssertion

#### `var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarSplitScreen.dylib`
- SHA256: `f696b518579266cf99cfd46f85cb54931d18e679c793a563ee2fcc9bf8115754`
- Backlight/idle/screen/foreground-related string candidates (27 shown):
  - `%@ is running in the background`
  - `%@ moved to the background`
  - `Background`
  - `CarSplit: background loi %@`
  - `CarSplit: chan background scene cua app trong ngan`
  - `CarSplit: foregroundScene loi %@`
  - `CarSplit: foregroundScene toan man loi %@`
  - `DBApplicationSceneViewController -backgroundSceneWithCompletion:`
  - `Tq,N,V_allowBackground`
  - `_OBJC_CLASS_$_UIScreen`
  - `_UIScreenDidConnectNotification`
  - `_UIScreenDidDisconnectNotification`
  - `_allowBackground`
  - `allowBackground`
  - `backgroundScene`
  - `backgroundSceneWithCompletion:`
  - `closeSlot:background:`
  - `detachVC:background:`
  - `foregroundSceneWithSettings:completion:`
  - `initWithCADisplay:isMainDisplay:`
  - `paneBackground:`
  - `removePaneAt:background:`
  - `runBackgroundForPane:`
  - `setAllowBackground:`
  - `setBackgroundColor:`
  - `setPreventsDisplaySleepDuringVideoPlayback:`
  - `showBackgroundToastFor:slot:`

#### `var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarStartupScreen.dylib`
- SHA256: `2cd8b29434f7f81e07a222298952696a0fced9139e543c6877aaa7f8b0d72037`
- Backlight/idle/screen/foreground-related string candidates (11 shown):
  - `@"CADisplayLink"`
  - `@"UIScreen"`
  - `T@"CADisplayLink",&,N,V_displayLink`
  - `T@"UIScreen",W,N,V_screen`
  - `_NSForegroundColorAttributeName`
  - `_OBJC_CLASS_$_CADisplayLink`
  - `_OBJC_CLASS_$_UIScreen`
  - `_UIScreenDidConnectNotification`
  - `_UIScreenDidDisconnectNotification`
  - `setBackgroundColor:`
  - `setScreen:`

#### `var/jb/Library/PreferenceBundles/OmniCarPrefs.bundle/OmniCarPrefs`
- SHA256: `15bca4bee19bd9e04300e2c8070f665869df93c0f8913278e87b147ebf895a76`
- Backlight/idle/screen/foreground-related string candidates (14 shown):
  - `@"CADisplayLink"`
  - `BackgroundColor`
  - `_NSForegroundColorAttributeName`
  - `_OBJC_CLASS_$_CADisplayLink`
  - `_OBJC_CLASS_$_UIScreen`
  - `_OMCBackgroundColor`
  - `colorWithHue:saturation:brightness:alpha:`
  - `getHue:saturation:brightness:alpha:`
  - `setBackgroundColor:`
  - `setBackgroundImage:forState:`
  - `setBackgroundView:`
  - `setBaseBackgroundColor:`
  - `setBaseForegroundColor:`
  - `systemBackgroundColor`

## Next precise gate

- Presence/absence of `SBBacklightController`, `setIdleTimerDisabled:forReason:`, `_setScreenBrightness:` or another selector is **not a proof** of execution or causal dependency.
- If strong candidates appear, disassemble exact original owner callsites + compare first-party current source; preserve system lock and avoid indefinite full-brightness display.
- If absent, identify YouTube UIApplication/scene activation while iPhone locked vs awake with a minimal read-only app-process state probe, and distinguish Play from scrolling.
- Preserve QA120 measured native geometry, .90 video rotation, .92 controls; do not publish guessed fixes or copy the original payload.
