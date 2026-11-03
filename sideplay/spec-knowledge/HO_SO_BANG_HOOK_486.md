# BẢN ĐỒ HOOK TOÀN DYLIB — DuoFaceDashboard (trích từ constructor, disassembly)

Tổng: 480 message hook trên 72 class + 6 function hook. IMP là địa chỉ hàm thay thế trong dylib. Trích tự động bằng parser trên disassembly (đã đối chiếu: IMP của traitsWithScreen:orientation: = 0x2afe1c và setKeyboardName: = 0x2b0340/0x2b053c khớp Bước 0 QA183 đọc tay).

## Function hooks (MSHookFunction)
- `GSEventIsHardwareKeyboardAttached` -> IMP 0x2b1b38 (đăng ký tại 0x2ae680)
- `BKSHIDServicesIsHardwareKeyboardAttached` -> IMP 0x2b1b78 (đăng ký tại 0x2ae6d8)
- `BKSDisplayServicesSetScreenBlanked` -> IMP 0x2b31e4 (đăng ký tại 0x2b30ec)
- `GSEventIsHardwareKeyboardAttached` -> IMP 0x314ea8 (đăng ký tại 0x2b5b40)
- `BKSHIDServicesIsHardwareKeyboardAttached` -> IMP 0x314f1a (đăng ký tại 0x2b5ba4)
- `BKSDisplayServicesSetScreenBlanked` -> IMP 0x30f819 (đăng ký tại 0x2ba8c8)

## Message hooks theo class

### UIKeyboardImpl (40)
- `inputMode` -> 0x2aee78
- `inputModePreference` -> 0x2aeecc
- `inputModeIdentifier` -> 0x2aef20
- `keyboardName` -> 0x2aefbc
- `keyplaneName` -> 0x2af164
- `setDelegate:force:` -> 0x2af20c
- `isInHardwareKeyboardMode` -> 0x2af3a4
- `None` -> 0x2af3ec
- `isHardwareKeyboardAttached` -> 0x2af434
- `None` -> 0x2af47c
- `automaticMinimizationEnabled` -> 0x2af4c4
- `showsSoftwareKeyboard` -> 0x2af50c
- `softwareKeyboardAllowedForFirstResponder:` -> 0x2af554
- `showKeyboard` -> 0x2af5c0
- `None` -> 0x2af63c
- `_defaultSizeForInterfaceOrientation:` -> 0x2af6ec
- `keyboardSizeForInterfaceOrientation:` -> 0x2af79c
- `sizeForInterfaceOrientation:` -> 0x2af84c
- `keyboardWidthForScreen:withOrientation:` -> 0x2af8fc
- `None` -> 0x2af980
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None

### UIKBScreenTraits (22)
- `keyboardWidth` -> 0x2afa94
- `setKeyboardWidth:` -> 0x2afae4
- `bounds` -> 0x2afb4c
- `None` -> 0x2afbac
- `keyboardScreenReferenceSize` -> 0x2afc3c
- `screenSize` -> 0x2afc9c
- `isFloating` -> 0x2afcfc
- `supportsSplit` -> 0x2afd44
- `isKeyboardSplit` -> 0x2afd8c
- `orientation` -> 0x2afdd4
- `traitsWithScreen:orientation:` -> 0x2afe1c
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None

### UIKeyboardLayoutStar (18)
- `None` -> 0x2afff0
- `None` -> 0x2b006c
- `None` -> 0x2b00e8
- `None` -> 0x2b0198
- `setKeyboardName:` -> 0x2b0340
- `setKeyboardName:appearance:` -> 0x2b053c
- `showKeyboardWithInputTraits:screenTraits:splitTraits:` -> 0x2b0750
- `None` -> 0x2b0d08
- `setKeyplaneName:` -> 0x2b0db0
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None

### SBIconListView (18)
- `iconColumnsForCurrentOrientation` -> 0x2cd12c
- `iconRowsForCurrentOrientation` -> 0x2cd1bc
- `maximumIconCount` -> 0x2cd24c
- `maxIconCount` -> 0x2cd31c
- `iconImageInfo` -> 0x2cd3ec
- `originForIconIndex:` -> 0x2cd408
- `centerForIconAtIndex:` -> 0x2cd5ac
- `frameForIconAtIndex:` -> 0x2cd764
- `layoutInsetsForOrientation:` -> 0x2cd920
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None

### AVPlayer (16)
- `setAllowsExternalPlayback:` -> 0x2b2c1c
- `allowsExternalPlayback` -> 0x2b2c60
- `setUsesExternalPlaybackWhileExternalScreenIsActive:` -> 0x2b2ca8
- `usesExternalPlaybackWhileExternalScreenIsActive` -> 0x2b2cec
- `play` -> 0x2b2d34
- `pause` -> 0x2b2d78
- `setRate:` -> 0x2b2dbc
- `None` -> 0x2b2e14
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None

### SBIconListGridLayoutConfiguration (16)
- `numberOfPortraitColumns` -> 0x2cdbb4
- `numberOfPortraitRows` -> 0x2cdc44
- `numberOfLandscapeColumns` -> 0x2cdcd4
- `numberOfLandscapeRows` -> 0x2cdd64
- `None` -> 0x2cddf4
- `iconImageInfoForGridSizeClass:` -> 0x2cde00
- `landscapeLayoutInsets` -> 0x2cde0c
- `portraitLayoutInsets` -> 0x2cde9c
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None

### _CARDashboardHomeViewController (16)
- `_setupIconModel` -> 0x2ea464
- `viewDidAppear:` -> 0x2ea5a0
- `iconManager:launchIconForIconView:` -> 0x2ea6bc
- `iconManager:launchIconForIconView:withActions:` -> 0x2ea860
- `iconManager:launchIcon:` -> 0x2eaa28
- `iconManager:launchIcon:location:` -> 0x2eabcc
- `iconManager:launchIcon:location:animated:` -> 0x2ead94
- `iconManager:launchIcon:location:animated:completionHandler:` -> 0x2eaf60
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None

### SBIconView (14)
- `None` -> 0x2d2840
- `iconImageInfo` -> 0x2d2bf8
- `iconImageFrame` -> 0x2d2c14
- `iconImageSize` -> 0x2d2d98
- `None` -> 0x2d2e98
- `touchesEnded:withEvent:` -> 0x2d3048
- `None` -> 0x2d3178
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None

### CARIconManager (12)
- `None` -> 0x2cfd20
- `None` -> 0x2cfe24
- `launchIcon:` -> 0x2cff50
- `launchIcon:location:animated:completionHandler:` -> 0x2d0058
- `None` -> 0x2d01c4
- `None` -> 0x2d02c8
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None

### UIWindow (10)
- `setFrame:` -> 0x2accbc
- `setBounds:` -> 0x2acdd8
- `_setRotatableViewOrientation:duration:force:` -> 0x2acef4
- `sendEvent:` -> 0x2acf64
- `_rotateWindowToOrientation:updateStatusBar:duration:skipCallbacks:` -> 0x2acfd8
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None

### UIApplication (10)
- `applicationState` -> 0x2ad054
- `statusBarOrientation` -> 0x2ad09c
- `isIdleTimerDisabled` -> 0x2ad0ec
- `setIdleTimerDisabled:` -> 0x2ad134
- `sendEvent:` -> 0x2eb98c
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None

### UIKeyboard (10)
- `setFrame:` -> 0x2ae9b0
- `setBounds:` -> 0x2aea2c
- `None` -> 0x2aeaa8
- `defaultSizeForInterfaceOrientation:` -> 0x2aebf8
- `None` -> 0x2aeca8
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None

### CADisplayLink (8)
- `setPaused:` -> 0x2ad1c0
- `isPaused` -> 0x2ad204
- `setPreferredFramesPerSecond:` -> 0x2ad24c
- `setPreferredFrameRateRange:` -> 0x2ad2e0
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None

### UIWindowScene (8)
- `interfaceOrientation` -> 0x2ad7f0
- `_isSuspended` -> 0x2ad840
- `_isDeactivated` -> 0x2ad888
- `None` -> 0x2add84
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None

### UIScreen (8)
- `_userInterfaceIdiom` -> 0x2ad9d8
- `bounds` -> 0x2ada20
- `nativeBounds` -> 0x2adaec
- `_referenceBounds` -> 0x2adbfc
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None

### SBIconListGridLayout (8)
- `numberOfColumnsForOrientation:` -> 0x2cd9c0
- `numberOfRowsForOrientation:` -> 0x2cda64
- `None` -> 0x2cdb08
- `None` -> 0x2cdb14
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None

### CARIconModel (8)
- `_showInternalApps` -> 0x2cf178
- `_showPrototypeApps` -> 0x2cf180
- `hiddenBundleIdentifiers` -> 0x2cf188
- `loadAllIcons` -> 0x2cf2cc
- `None` -> 0x34e708
- `None` -> None
- `None` -> None
- `None` -> None

### SBHIconManager (8)
- `launchIconForIconView:` -> 0x2cf8d8
- `launchIconForIconView:withActions:` -> 0x2cf9dc
- `iconTapped:` -> 0x2cfb08
- `iconTapped:modifierFlags:` -> 0x2cfc0c
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None

### CARIconView (8)
- `None` -> 0x2d09ec
- `_configureIconImageView:` -> 0x2d0da4
- `None` -> 0x2d0f74
- `None` -> 0x2d115c
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None

### CARLeafIcon (8)
- `displayNameForLocation:` -> 0x2d1c70
- `displayName` -> 0x2d1e08
- `iconImageWithInfo:` -> 0x2d1f7c
- `generateIconImageWithInfo:` -> 0x2d2164
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None

### DBRootStatusBarViewController (8)
- `viewDidAppear:` -> 0x2e8bbc
- `viewDidLayoutSubviews` -> 0x2e8c00
- `viewWillDisappear:` -> 0x2e8c44
- `homeButtonUp:` -> 0x2e8ca0
- `CBDockMonitorView` -> 0x37c328
- `None` -> None
- `None` -> None
- `None` -> None

### CARRootStatusBarViewController (8)
- `None` -> 0x2e8db0
- `None` -> 0x2e8df4
- `None` -> 0x2e8e38
- `None` -> 0x2e8e94
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None

### DBAppDockViewController (8)
- `None` -> 0x2e8fa4
- `None` -> 0x2e901c
- `_refreshAppDock` -> 0x2e9094
- `_dockButtonPressed:` -> 0x2e90c0
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None

### CARAppDockViewController (8)
- `None` -> 0x2e91f0
- `None` -> 0x2e9268
- `None` -> 0x2e92e0
- `None` -> 0x2e930c
- `None` -> None
- `None` -> None
- `None` -> None
- `None` -> None

### UIDevice (6)
- `orientation` -> 0x2ad8d0
- `setOrientation:animated:` -> 0x2ad920
- `setOrientation:` -> 0x2ad980
- `None` -> None
- `None` -> None
- `None` -> None

### UIResponder (6)
- `textInputMode` -> 0x2b0fe0
- `becomeFirstResponder` -> 0x2b107c
- `resignFirstResponder` -> 0x2b10f4
- `None` -> None
- `None` -> None
- `None` -> None

### AVExternalDevice (6)
- `currentCarPlayExternalDevice` -> 0x2b2b08
- `currentExternalDevice` -> 0x2b2b60
- `externalDevices` -> 0x2b2bb8
- `GSEventIsHardwareKeyboardAttached` -> 0x34e708
- `None` -> None
- `None` -> None

### SBSuspendedUnderLockManager (6)
- `interceptUpdateForScene:withNewSettings:` -> 0x2c8668
- `_shouldBeBackgroundUnderLockForScene:withSettings:` -> 0x2c8768
- `shouldBeUnderLockForScene:` -> 0x2c8870
- `None` -> None
- `None` -> None
- `None` -> None

### DBApplicationInfo (6)
- `_loadFromProxy:` -> 0x2cb730
- `isCarPlaySupported` -> 0x2cb7d8
- `canDisplayOnCarScreen` -> 0x2cb898
- `CBDuoFaceBridged` -> None
- `None` -> None
- `None` -> None

### CARApplicationInfo (6)
- `None` -> 0x2cb958
- `None` -> 0x2cba00
- `None` -> 0x2cbac0
- `None` -> None
- `None` -> None
- `None` -> None

### DBIconView (6)
- `configureLabelImageParametersBuilder:` -> 0x2d03dc
- `_handleTapGesture:` -> 0x2d0794
- `layoutSubviews` -> 0x2d09c0
- `None` -> None
- `None` -> None
- `None` -> None

### DBLeafIconDataSource (6)
- `iconDisplayName:forLocation:` -> 0x2d1188
- `icon:displayNameForLocation:` -> 0x2d1340
- `icon:imageWithInfo:` -> 0x2d14f8
- `None` -> None
- `None` -> None
- `None` -> None

### CARLeafIconDataSource (6)
- `None` -> 0x2d16fc
- `None` -> 0x2d18b4
- `None` -> 0x2d1a6c
- `None` -> None
- `None` -> None
- `None` -> None

### DBLeafIcon (6)
- `None` -> 0x2d234c
- `None` -> 0x2d24e4
- `None` -> 0x2d2658
- `None` -> None
- `None` -> None
- `None` -> None

### DashBoard (6)
- `init` -> 0x2ea0a4
- `_newApplicationLibrary` -> 0x2ea1a8
- `None` -> 0x2ea1e0
- `CBDockMonitorView` -> 0x37c3e8
- `None` -> None
- `None` -> None

### CARApplication (6)
- `None` -> 0x2ea218
- `None` -> 0x2ea3bc
- `None` -> 0x2ea410
- `None` -> None
- `None` -> None
- `None` -> None

### _CARDashboardRootViewController (6)
- `None` -> 0x2eb2f4
- `viewDidLayoutSubviews` -> 0x2eb550
- `viewSafeAreaInsetsDidChange` -> 0x2eb620
- `None` -> None
- `None` -> None
- `None` -> None

### UIViewController (4)
- `supportedInterfaceOrientations` -> 0x2acc04
- `__supportedInterfaceOrientations` -> 0x2acc60
- `copy` -> 0x34e008
- `None` -> None

### NSNotificationCenter (4)
- `postNotificationName:object:userInfo:` -> 0x2ad440
- `postNotification:` -> 0x2ad594
- `None` -> None
- `None` -> None

### FBSSceneSettings (4)
- `isOccluded` -> 0x2ad6d0
- `deactivationReasons` -> 0x2ad718
- `None` -> None
- `None` -> None

### UIApplicationSceneSettings (4)
- `isUnderLock` -> 0x2ad760
- `canShowWhileLocked` -> 0x2ad7a8
- `None` -> None
- `None` -> None

### UIKeyboardInputModeController (4)
- `currentInputMode` -> 0x2b0e88
- `activeInputModes` -> 0x2b0ef0
- `None` -> None
- `None` -> None

### UIInputWindowController (4)
- `viewWillAppear:` -> 0x2b116c
- `viewDidAppear:` -> 0x2b11e8
- `None` -> None
- `None` -> None

### UIRemoteKeyboardWindow (4)
- `setHidden:` -> 0x2b1968
- `setAlpha:` -> 0x2b19f0
- `None` -> None
- `None` -> None

### UITextEffectsWindow (4)
- `None` -> 0x2b1a50
- `None` -> 0x2b1ad8
- `None` -> None
- `None` -> None

### AVPlayerItem (4)
- `None` -> 0x2b2e58
- `None` -> 0x2b2e9c
- `None` -> None
- `None` -> None

### AVRouteDetector (4)
- `isRouteDetectionEnabled` -> 0x2b2ee4
- `setRouteDetectionEnabled:` -> 0x2b2f2c
- `None` -> None
- `None` -> None

### AVPictureInPictureController (4)
- `isPictureInPictureSupported` -> 0x2b2f70
- `isPictureInPicturePossible` -> 0x2b2fb8
- `None` -> None
- `None` -> None

### MPVolumeView (4)
- `isWirelessRouteActive` -> 0x2b3000
- `areWirelessRoutesAvailable` -> 0x2b3048
- `None` -> None
- `None` -> None

### FBScene (4)
- `updateSettings:withTransitionContext:completion:` -> 0x2c7e08
- `_applyUpdateWithContext:completion:` -> 0x2c8410
- `BKSDisplayServicesSetScreenBlanked` -> 0x34e708
- `None` -> None

### SBDeviceApplicationSceneViewController (4)
- `setContentReferenceSize:withInterfaceOrientation:` -> 0x2c895c
- `setContentReferenceSize:withContentOrientation:andContainerOrientation:` -> 0x2c8a50
- `None` -> None
- `None` -> None

### SBAppViewController (4)
- `sceneHandle:didUpdateSettingsWithDiff:previousSettings:` -> 0x2c8ca8
- `sceneHandle:didDestroyScene:` -> 0x2c8ef8
- `None` -> None
- `None` -> None

### SpringBoard (4)
- `applicationDidFinishLaunching:` -> 0x2c9a04
- `sendEvent:` -> 0x2c9a30
- `None` -> None
- `None` -> None

### _UIStaticScrollBar (4)
- `layoutSubviews` -> 0x2ca1fc
- `willMoveToSuperview:` -> 0x2ca370
- `None` -> 0x34e708
- `None` -> None

### UIScene (2)
- `activationState` -> 0x2ad178
- `None` -> None

### MTKView (2)
- `None` -> 0x2ad3ac
- `None` -> None

### UIScreenMode (2)
- `size` -> 0x2adcc8
- `None` -> None

### UIWindowSceneGeometry (2)
- `None` -> 0x2add18
- `None` -> None

### UIInputSetContainerView (2)
- `layoutSubviews` -> 0x2ae6f8
- `None` -> 0x37b328

### UIInputSetHostView (2)
- `None` -> 0x2ae8f0
- `None` -> None

### UIKeyboardInputMode (2)
- `isEqualToString:` -> 0x2aed58
- `None` -> None

### UIPeripheralHost (2)
- `getWidthForOrientation:` -> 0x2afa30
- `None` -> None

### _UIScenePresentationView (2)
- `scene:didPrepareUpdateWithContext:` -> 0x2c85d0
- `None` -> None

### SBDeviceApplicationSceneHandle (2)
- `_mainSceneSupportsInterfaceOrientation:` -> 0x2c8b4c
- `None` -> None

### FBApplicationProcess (2)
- `_processDidExitWithContext:` -> 0x2c98dc
- `_frame` -> None

### _UIScrollViewScrollIndicator (2)
- `None` -> 0x2ca4d4
- `None` -> None

### FBSApplicationLibrary (2)
- `allInstalledApplications` -> 0x2cbb80
- `None` -> None

### CRCarPlayAppPolicyEvaluator (2)
- `effectivePolicyForAppDeclaration:` -> 0x2cc0b0
- `None` -> None

### CRCarPlayAppDeclaration (2)
- `declarationForAppProxy:` -> 0x2cc3a4
- `None` -> None

### SBIconListModel (2)
- `maxNumberOfIcons` -> 0x2cdf2c
- `None` -> None

### DBRootViewController (2)
- `None` -> 0x2eb158
- `None` -> None

### DBFocusController (2)
- `takeWithPriority:reason:forWindow:bundleIdentifier:pid:scene:heading:focusedFrame:` -> 0x2eb6d8
- `None` -> None