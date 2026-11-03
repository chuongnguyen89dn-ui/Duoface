# PHỤ LỤC A–Z ĐẦY ĐỦ — kiểm kê từng binary (DuoNavi gốc vs QA185)

Sinh tự động từ parser Mach-O (chỉ đọc): class định nghĩa + toàn bộ method, từ vựng class tham chiếu, ký hiệu import, chuỗi thông báo/Darwin/plist/URL, và toàn bộ chuỗi log có định dạng. Phụ lục này là dữ liệu gốc đứng sau báo cáo BAO_CAO_QUET_AZ_DUONAVI_VS_QA185.md.


## [GỐC] DuoFaceDashboard.dylib
- Kích thước: 7540464 byte; SHA256: bc1df854ec7a2ddfeec4cb81b080ead34b54df80143d4a8f6254bb8b618003ce
- Thư viện nạp (19): libobjc.A.dylib, Foundation, CoreFoundation, UIKit, CoreGraphics, IOKit, Security, AVFoundation, QuartzCore, libsqlite3.dylib, AppSupport, BackBoardServices, libSystem.B.dylib, AVFAudio, CydiaSubstrate, Frameworks, lib, Frameworks, lib
- Ký hiệu import C/ObjC: 0 (binary đã strip bảng ký hiệu)
- Từ vựng: 1700 selector, 2809 chuỗi C, 66 tên class tham chiếu

### Class định nghĩa (36) và toàn bộ method

**CBAppMetadataItem** — 7 instance, 0 class
- instance: .cxx_destruct, displayName, icon, isUserApp, setDisplayName:, setIcon:, setIsUserApp:

**CBAppStateListener** — 5 instance, 1 class
- instance: checkStateFile, handleAppDidBecomeActive:, handleAppStateNotification:, init, sendStateRequest
- class: sharedInstance

**CBAssistantManager** — 68 instance, 1 class
- instance: .cxx_destruct, audioEngine, beginRecordingSession, cb_onLanguageChanged:, dealloc, dismissCarBridgeApp, dismissHUD, finishListeningAndProcess, handleAppLaunchCommand:, handleMusicCommand:, handleNavigationCommand:, hudCard, hudWindow, init, isListening, lastTranscribedText, listeningTimeout, micIconView, onStatusUpdate, preferredMapIndex, processVoiceCommand:, pulseAnimation, recognitionRequest, recognitionTask, recordedPCMData, reloadPreferences, resetSilenceTimer, setAudioEngine:, setHudCard:, setHudWindow:, setIsListening:, setLastTranscribedText:, setMicIconView:, setOnStatusUpdate:, setPreferredMapIndex:, setPulseAnimation:, setRecognitionRequest:, setRecognitionTask:, setRecordedPCMData:, setSilenceTimer:, setSpeakCompletion:, setSpeechRecognizer:, setSpeechSynthesizer:, setStatusLabel:, setTranscriptLabel:, setVoiceFeedbackEnabled:, setupSpeechRecognizer, setupSpeechSynthesizer, showHUD, silenceTimer, speak:completion:, speakCompletion, speechRecognizer, speechSynthesizer, speechSynthesizer:didFinishSpeechUtterance:, startListening, startMicPulseAnimation, statusLabel, stopListening, stopListeningAndDismiss, stopMicPulseAnimation, stopSpeaking, toggleListening, transcribeAudioData:completion:, transcriptLabel, triggerBridgeApp:, updateHUDStatus:subtext:, voiceFeedbackEnabled
- class: sharedInstance

**CBBridgeManager** — 73 instance, 2 class
- instance: .cxx_destruct, acquireCarPlaySleepAssertion, activated, appForBundleIdentifier:frame:, appFrame, autoResumeBundleID, bundleIdentifier, cancelMandatoryDisconnectWatchdog, clearBridgeStateOnDisk, collectActiveAndSessionAppBundleIDs, currentApp, deactivateCurrentApp, dismiss:, dismissLicenseWarningModal, effectiveAutoLaunchBundleID, enforceMandatoryDisconnectKill, evictAppFromPhoneScreen:completion:, handleCarPlayConnectionChanged:, handleGenericScreenOrCarPlayNotification:, handleScreenDidConnect:, handleScreenDidDisconnect:, handleSettingsChanged, init, isCurrentlyBridging:, isUIAppBridging, killProcessesForBundleIdentifiers:, licenseWarningModal, licenseWatchdogTimerFired:, loadNewAppFromCurrentRequest:, notifyStateUpdated, performAutoResume, presentLicenseWarningModalWithType:, receivedAppRequestNotification:, receivedDashboardReadyNotification:, receivedDockTapNotification:, receivedMetricsUpdatedNotification:, receivedStateChangeRequestNotificiation:, registerForNotifications, releaseCarPlaySleepAssertion, renderSize, renderSizeForBundleID:, requestStateChange:, requestStateChangeWithDictionary:, restartApplicationWithBundleID:, runningBridgedApplications, saveBridgeStateToDisk, scheduleAutoResumeFallback, scheduleMandatoryDisconnectWatchdog, sendStateToApp:shouldBridge:, setActivated:, setAppFrame:, setAutoResumeBundleID:, setBundleIdentifier:, setCurrentApp:, setLicenseWarningModal:, setRenderSize:, setWindow:, shouldBridge:, showAppPickerForSlot:, showLayoutChooser, showRecentApps, startLicenseWatchdogTimer, stopLicenseWatchdogTimer, supportsInterfaceOrientation:forBundleID:, switchToMultiSplitMode:apps:ratio:, switchToSplitWithLeft:right:ratio:, syncDashboardPolicySignalToDisk, terminate, terminateAllBridgedApplications, terminateApplicationWithBundleID:, trackBridgedBundleID:, updateScale:forSlot:, window
- class: sharedInstance, sharedInstanceIfExists

**CBBridgeManagerDashboard** — 33 instance, 6 class
- instance: .cxx_destruct, activated, bridgeDidActivate:, bridgeDidDeactivate, closeOfficialTopApp:, getAppFrame, getDockDimension, getDockEdge, getDockWidth, handleDockIconTap:, handleSBStateChange:, handleScreenDidConnect:, handleScreenDidDisconnect:, handleStateDict:, init, pending, pendingCompletion, prepareAndRequestActivation:, prepareHomeScreenForBridge:, registerForNotifications, requestActivation:, requestDismiss, requestStateChange:, setActivated:, setAppDockActiveBundleID:, setHomeButtonInApp:, setPending:, setPendingCompletion:, startBridging:, startBridging:withCompletion:, stopBridging, stopBridgingWithCompletion:, updateCarPlayMetrics
- class: bridgedApps, isBridgedApp:, isDashboardPolicySignalActive, isOfficialApp:, sharedInstance, shouldInterceptLaunchForApp:

**CBBridgeRequest** — 6 instance, 0 class
- instance: .cxx_destruct, activate, bundleIdentifier, initWithDictionary:, setActivate:, setBundleIdentifier:

**CBBridgedApp** — 12 instance, 0 class
- instance: .cxx_destruct, bundleIdentifier, delegate, initWithBundleIdentifier:frame:, noteUserActivity, setBundleIdentifier:, setDelegate:, setView:, start, startInParentViewController:, stop, view

**CBBridgedAssistantApp** — 6 instance, 0 class
- instance: .cxx_destruct, assistantView, initWithBundleIdentifier:frame:, setAssistantView:, start, stop

**CBBridgedAssistantView** — 15 instance, 0 class
- instance: .cxx_destruct, initWithFrame:, micIcon, pulseAnimation, setMicIcon:, setPulseAnimation:, setSubtitleLabel:, setTitleLabel:, startPulse, startSession, stopPulse, stopSession, subtitleLabel, tapMicToggled, titleLabel

**CBBridgedPortalApp** — 6 instance, 0 class
- instance: .cxx_destruct, initWithBundleIdentifier:frame:, portalView, setPortalView:, start, stop

**CBBridgedPortalAppView** — 12 instance, 0 class
- instance: .cxx_destruct, captureFrame:, dealloc, displayLink, imageView, initWithFrame:, setDisplayLink:, setImageView:, setTouchCloneView:, start, stop, touchCloneView

**CBBridgedSplitApp** — 49 instance, 0 class
- instance: .cxx_destruct, appViews, closeAllSlots, closeSlot:, configureDividerButtons, containers, dividers, focusSlot:animated:, focusedSlotIndex, handleDividerPan:isVertical:state:, handleDividerSwapPressed:, initWithBundleIdentifier:frame:, initWithBundleIdentifier:frame:showSplash:, isTransitioningFocus, layoutSplitViews, moveSlot:direction:, noteUserActivity, persistSlotOrder, placeholders, removeAppWithBundleIdentifier:, replaceAppInSlot:withBundleIdentifier:, restartAppWithBundleIdentifier:, restartSlot:, restoreSplitAnimated:, rotateAllSlotsClockwise, setAppViews:, setContainers:, setDividers:, setFocusedSlotIndex:, setIsTransitioningFocus:, setPlaceholders:, setSlotPills:, setSplashScreenView:, setSplitPreset:, setSplitRatio:, slotPills, splashScreenView, splitPreset, splitRatio, start, startBlinkingSession, startContainerBorderBlinking:, startInParentViewController:, stop, stopBlinkingSession, stopContainerBorderBlinking:, swapSlot:withSlot:, toggleFocusForSlot:, updateScale:forSlot:

**CBBridgedUIApp** — 16 instance, 0 class
- instance: .cxx_destruct, appView, customScale, hideNotchPill, initWithBundleIdentifier:frame:, layoutSubviews, notchPill, noteUserActivity, renderSize, setAppView:, setCustomScale:, setNotchPill:, showNotchPillSession, start, startInParentViewController:, stop

**CBBridgedUIAppView** — 29 instance, 0 class
- instance: .cxx_destruct, appScale, appViewController, audioOnlyBackgroundMode, bundleIdentifier, calculateNativeSizeForSlotRect:, dealloc, dismiss, hitTest:withEvent:, hosting, initWithBundleIdentifier:, initWithBundleIdentifier:scale:, invalidated, layoutSubviews, refreshSceneLayout, setAppScale:, setAppViewController:, setAudioOnlyBackgroundMode:, setBundleIdentifier:, setHosting:, setInvalidated:, setWrapperView:, start, startInParentViewController:, touchesBegan:withEvent:, updateLayout, updateSceneFrame, updateSceneSettingsFrame, wrapperView

**CBDashboardSettings** — 56 instance, 5 class
- instance: .cxx_destruct, agreedToEULA, appSettings, assistantEnabled, autoLaunchBundleID, autoLaunchOnConnect, bridgedApps, dockSystemMonitorEnabled, dockSystemMonitorShowAll, gridCols, gridRows, hideIconLabels, init, portalAppEnabled, preferredMapIndex, reload, reloadAppPrefs, scaleForBundleID:, screenBlankEnabled, setAgreedToEULA:, setAppSettings:, setAssistantEnabled:, setAutoLaunchBundleID:, setAutoLaunchOnConnect:, setBridgedApps:, setDockSystemMonitorEnabled:, setDockSystemMonitorShowAll:, setGridCols:, setGridRows:, setHideIconLabels:, setPortalAppEnabled:, setPreferredMapIndex:, setScale:forBundleID:, setScreenBlankEnabled:, setSplitApp1:, setSplitApp2:, setSplitApp3:, setSplitApp4:, setSplitLeftBundleID:, setSplitMode:, setSplitPreset:, setSplitRatio:, setSplitRightBundleID:, setSplitScreenEnabled:, setVoiceFeedbackEnabled:, splitApp1, splitApp2, splitApp3, splitApp4, splitLeftBundleID, splitMode, splitPreset, splitRatio, splitRightBundleID, splitScreenEnabled, voiceFeedbackEnabled
- class: assistantIconImage, portalAppIconImage, portalAppIdentifier, sharedInstance, splitScreenIconImage

**CBDashboardShared** — 0 instance, 12 class
- class: appDockVC, carApp, currentAppDockVC, currentDashboardRootVC, currentRootStatusBarVC, dashboard, folderController, homeVC, rootVC, setCurrentAppDockVC:, setCurrentDashboardRootVC:, setCurrentRootStatusBarVC:

**CBDividerButtonInfo** — 9 instance, 0 class
- instance: .cxx_destruct, iconName, onRotate, onSwap, relativePos, setIconName:, setOnRotate:, setOnSwap:, setRelativePos:

**CBDividerView** — 27 instance, 0 class
- instance: .cxx_destruct, buttonConfigs, configureWithButtonConfigs:, gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:, handleMoveButtonLongPress:, handlePan:, hitTest:withEvent:, initWithFrame:isVertical:, isBlinking, isVertical, layoutSubviews, moveButtonTouchCancelled:, moveButtonTouchDown:, moveButtonTouchUp:, moveButtons, onActivity, onPanChanged, pointInside:withEvent:, setButtonConfigs:, setIsBlinking:, setIsVertical:, setMoveButtons:, setOnActivity:, setOnPanChanged:, startBlinking, stopBlinking, updateGripLayout

**CBDockMetricItemView** — 11 instance, 0 class
- instance: .cxx_destruct, fallbackIconLabel, iconImageView, initWithFrame:, layoutSubviews, setFallbackIconLabel:, setIconImageView:, setIconSystemName:fallbackEmoji:, setValue:color:, setValueLabel:, valueLabel

**CBDockSystemMonitorView** — 19 instance, 0 class
- instance: .cxx_destruct, dealloc, detailedMode, handleBatteryNotification:, handleTapGesture:, initWithFrame:, isMonitoring, layoutSubviews, readCpuUsage, readDeviceTemperature, readRamUsage:total:, setDetailedMode:, setShowAll:, showAll, startMonitoring, stopMonitoring, updateBatteryMetric, updateMetrics, willMoveToWindow:

**CBHttpClient** — 6 instance, 1 class
- instance: .cxx_destruct, getJSONFromURL:timeout:customHeaders:completion:, init, networkQueue, postJSON:toURL:timeout:customHeaders:completion:, setNetworkQueue:
- class: sharedClient

**CBLicenseShieldIconView** — 2 instance, 0 class
- instance: drawRect:, initWithFrame:

**CBLicenseSyncManager** — 24 instance, 6 class
- instance: .cxx_destruct, actualLicenseExpirationTimestamp, actualLicenseTierName, checkAndSyncLicenseIfNeeded, checkAndSyncLicenseIfNeededWithSource:, deviceHardwareHashHex, forceSyncWithCompletion:, init, installAndVerifyLicensePayload:errorMsg:, isCarPlayScreenConnected, isLicenseCurrentlyValid, isSyncing, lastAttemptTimestamp, performSyncWithForce:isManualUserAction:completion:, performSyncWithForce:isManualUserAction:source:completion:, remainingLicenseSeconds, resolvedBackendBaseURL, resolvedLicenseServerEndpoint, setActualLicenseExpirationTimestamp:, setActualLicenseTierName:, setIsSyncing:, setLastAttemptTimestamp:, setSyncQueue:, syncQueue
- class: formatBaseURLString:, isCarPlayScreen:, isCarPlayScreenConnected, isCarPlayScreenConnectedExcludingScreen:, resolvedBackendBaseURL, sharedInstance

**CBLicenseWarningModalView** — 12 instance, 0 class
- instance: .cxx_destruct, dismissAnimated:, handleDismissButtonTap:, initWithFrame:modalType:, layoutSubviews, modalType, onDismiss, setModalType:, setOnDismiss:, setupSubviews, showAnimated:, updateContentForType:

**CBLocalization** — 6 instance, 7 class
- instance: .cxx_destruct, activeLanguageCode, init, localizedStringForKey:, reloadLanguage, stringTableForLanguageCode:
- class: currentLanguageCode, displayNameForLanguageCode:, localizedStringForKey:, setCurrentLanguageCode:, sharedInstance, speechVoiceLanguageCode, supportedLanguages

**CBMultitaskingOverlayView** — 66 instance, 0 class
- instance: .cxx_destruct, addMoreAppsTapped:, allApps, appPickerPageControl, appPickerScrollView, appSegmentBtn, appSelected:, cardShadowContainer, cb_onLanguageChanged:, closeAllBridgedAppsTapped:, closeSingleAppTapped:, currentPreset, currentRatio, dealloc, dimBackground, dismissCustomAlert:, dismissOverlay, headerIcon, initWithFrame:, layoutSegmentBtn, layoutSubviews, loadInstalledApps, onCloseRequested, onMultiSplitSelected, overlayMode, pageControlChanged:, presetSelected:, recentSegmentBtn, restartSingleAppTapped:, runningApps, saveSlotIndex:bid:toSettings:prefs:, scrollViewDidScroll:, setAllApps:, setAppPickerPageControl:, setAppPickerScrollView:, setAppSegmentBtn:, setCardShadowContainer:, setCurrentPreset:, setCurrentRatio:, setDimBackground:, setHeaderIcon:, setLayoutSegmentBtn:, setOnCloseRequested:, setOnMultiSplitSelected:, setOverlayMode:, setRecentSegmentBtn:, setRunningApps:, setSheetCard:, setSlotBIDs:, setTargetSlotIndex:, setTitleLabel:, setupAppPickerCardsInCardW:cardH:contentY:, setupCardContent, setupPresetCardsInCardW:cardH:contentY:, setupRecentAppsCardsInCardW:cardH:contentY:, sheetCard, showAppPickerForSlot:parentView:, showLayoutChooserInParentView:, showRecentAppsInParentView:, slotBIDs, switchToAppPickerMode, switchToLayoutChooserMode, switchToRecentMode, targetSlotIndex, titleLabel, toggleMode

**CBMultitaskingPillView** — 12 instance, 0 class
- instance: .cxx_destruct, blurView, iconView, initWithFrame:, onPillTapped, pillPanned:, pillTapped, setBlurView:, setIconView:, setOnPillTapped:, setTitleLabel:, titleLabel

**CBOverlayScrollView** — 4 instance, 0 class
- instance: addSubview:, initWithFrame:, layoutSubviews, touchesShouldCancelInContentView:

**CBSlotPillHitButton** — 3 instance, 0 class
- instance: hitInsets, pointInside:withEvent:, setHitInsets:

**CBSlotPillView** — 36 instance, 0 class
- instance: .cxx_destruct, bounceButton:, dotsButton, dotsTapped:, expandButton, expandTapped:, handleLongPress:, initWithSlotIndex:, isCompactMode, isFocusedMode, layoutSubviews, onExpandTapped, onPillLongPressed, onPillTapped, onRestoreTapped, pointInside:withEvent:, restoreButton, restoreTapped:, separatorView, setCompactMode:, setDotsButton:, setExpandButton:, setFocusedMode:, setIsCompactMode:, setIsFocusedMode:, setOnExpandTapped:, setOnPillLongPressed:, setOnPillTapped:, setOnRestoreTapped:, setRestoreButton:, setSeparatorView:, setShowsExpandButton:, setSlotIndex:, showsExpandButton, slotIndex, updateBoundsSize

**CBSlotPlaceholderView** — 16 instance, 0 class
- instance: .cxx_destruct, dealloc, iconView, initWithSlotIndex:, layoutSubviews, onTap, placeholderTapped:, setIconView:, setOnTap:, setSlotIndex:, setTapButton:, setTitleLabel:, slotIndex, tapButton, titleLabel, updateLocalizedTexts

**CBSplitContainerView** — 6 instance, 0 class
- instance: .cxx_destruct, hitTest:withEvent:, layoutSubviews, setSplitApp:, splitApp, touchesBegan:withEvent:

**CBSplitSplashScreenView** — 13 instance, 3 class
- instance: .cxx_destruct, dealloc, dismissAnimated:, dismissAnimated:completion:, handleTap:, initWithFrame:, isDismissing, layoutSubviews, onDismissed, onWillDismiss, setOnDismissed:, setOnWillDismiss:, startLoadingAnimation
- class: appIconImage, logoImage, radialGlowImageForDiameter:

**CBTouchCloneView** — 5 instance, 0 class
- instance: sendTouchEventAtPoint:isDown:, touchesBegan:withEvent:, touchesCancelled:withEvent:, touchesEnded:withEvent:, touchesMoved:withEvent:

**CBUIAppContainerView** — 6 instance, 0 class
- instance: .cxx_destruct, hitTest:withEvent:, layoutSubviews, setUiApp:, touchesBegan:withEvent:, uiApp

**CBWindow** — 28 instance, 9 class
- instance: .cxx_destruct, appFrame, contentView, createWindows, dealloc, destroyWindows, dismiss, getCarPlayDisplay, hide:, initWithAppFrame:, isDisplayValid, isVisible, multitaskingOverlay, multitaskingPill, resizeWindows, rootViewController, rootWindow, setAppFrame:, setContentView:, setIsVisible:, setMultitaskingOverlay:, setMultitaskingPill:, setRootViewController:, setRootWindow:, show, showAppPickerForSlot:, showLayoutChooser, showRecentApps
- class: activeCarPlayWindow, carPlayCADisplay, carPlayContentInsets, carPlayScreenBounds, carPlayScreenScale, carPlayUIScreen, carPlayUsableBounds, carPlayWindowScene, resetCachedBounds

### Chuỗi hạ tầng
- notifications: AVExternalDeviceCarPlayIsConnectedDidChangeNotification; AVExternalDeviceScreenDidConnectNotification; AVExternalDeviceScreenDidDisconnectNotification; CARSessionDidConnectNotification; CARSessionDidDisconnectNotification; CARSessionStatusDidChangeNotification; CBLanguageChangedNotification; NSDistributedNotificationCenter; NSNotificationCenter; UISceneDidEnterBackgroundNotification; UISceneWillDeactivateNotification; [DuoFaceApp] Notification indicated not bridged for %@. Resetting to phone mode.; [DuoFaceApp] Received handleAppStateNotification: %@; [DuoFaceSB] [DISCONNECT_TRACE] NSNotificationCenter received: name=%@ | object=%@ | userInfo=%@; [DuoFaceSB] receivedAppRequestNotification for: %@; postNotificationName:object:userInfo:deliverImmediately:; setShowsNotifications:; v16@?0@"NSNotification"8
- tên miền/tên Darwin com.*: com.duoface.duofaceui; com.duoface.http.client; com.duoface.license.sync
- đường dẫn plist: /Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.plist; /var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.plist
- URL: http://; http://maps.apple.com/?daddr=%@&dirflg=d; https://; https://m.youtube.com/results?search_query=%@; https://www.google.com/speech-api/v2/recognize?client=chromium&lang=vi-VN&key=%@&maxresults=5&pFilter=0
- thẻ log: [CBAppCategory] [CBAssistantManager] [CBBridgedUIAppView] [CBHook_AppStateSync] [CBHook_DockMonitor] [CBWindow] [CONNECT_TRACE] [CRASH_FATAL] [DISCONNECT_TRACE] [DuoFaceApp] [DuoFaceCarPlay] [DuoFaceDB] [DuoFaceKB] [DuoFaceLicense] [DuoFaceSB] [DuoFaceWindow] [DuoFace] [DuoFace_DEBUG] [INIT_TRACE] [LICENSE_KILL_TRACE]

### Chuỗi log có định dạng (258)
- Code [%@] activated successfully!
Duration: %@.
All CarPlay multitasking features are now ready.
- Code [%@] has been applied.
Duration: %@.
All CarPlay multitasking features are ready.
- [CBAppCategory] Warning: Exception checking DashBoard app proxy for %@: %@
- [CBAppCategory] Warning: Exception checking LSApplicationProxy for %@: %@
- [CBAssistantManager] Warning: Error writing assistant log: %@
- [CBBridgedUIAppView] Warning: Exception resolving sceneHandle: %@
- [CBBridgedUIAppView] Warning: _deviceAppViewController KVC failed in updateSceneSettingsFrame, falling back to ivar: %@
- [CBBridgedUIAppView] Warning: _deviceAppViewController KVC failed: %@
- [CBHook_AppStateSync] Warning: Exception resizing player layer: %@
- [CBHook_AppStateSync] Warning: Exception restoring phone window layout: %@
- [CBHook_DockMonitor] Warning: _appDockViewController KVC failed: %@
- [CBHook_DockMonitor] Warning: _audioAppButton KVC failed: %@
- [CBHook_DockMonitor] Warning: _homeButton KVC failed: %@
- [CBHook_DockMonitor] Warning: _keylineView KVC failed: %@
- [CBHook_DockMonitor] Warning: _navigationAppButton KVC failed: %@
- [CBHook_DockMonitor] Warning: _otherAppButton KVC failed: %@
- [CBHook_DockMonitor] Warning: _statusBarView KVC failed: %@
- [CBHook_DockMonitor] Warning: _statusBarViewController KVC failed: %@
- [CBHook_DockMonitor] Warning: homeButton KVC failed: %@
- [CBWindow] Warning: Exception getting carPlayScreenScale: %@
- [CBWindow] Warning: Exception getting carPlayWindowScene: %@
- [CBWindow] Warning: Exception querying carPlayCADisplay bounds: %@
- [CBWindow] Warning: Exception querying carPlayUIScreen bounds: %@
- [CBWindow] Warning: Exception querying carPlayWindowScene bounds: %@
- [CBWindow] Warning: Exception reading live screen bounds file: %@
- [CBWindow] Warning: Exception resolving FBSScene displayConfiguration: %@
- [CRASH_FATAL] Caught signal %d (%s) in pid %d (%@)! Fault addr: %p
Backtrace:
%@
- [CRASH_FATAL] Uncaught Objective-C Exception in pid %d (%@): %@
Reason: %@
UserInfo: %@
CallStack:
%@
- [DuoFaceApp] Activated via disk state file: size={%.1f, %.1f}, o=%ld, isSplit=%d
- [DuoFaceApp] Error in recursive VC relayout: %@
- [DuoFaceApp] Error laying out window: %@
- [DuoFaceApp] Notification indicated not bridged for %@. Resetting to phone mode.
- [DuoFaceApp] Received handleAppStateNotification: %@
- [DuoFaceApp] Sending NOTIFY_APP_REQUEST for %@
- [DuoFaceApp] State file indicates not bridged for %@. Resetting to phone mode.
- [DuoFaceApp] State updated via notification: bridging=%d, size={%.1f, %.1f}, o=%ld
- [DuoFaceApp] Waking app to active foreground state for CarPlay presentation: %@
- [DuoFaceApp] checkStateFile: bid=%@, dict=%@
- [DuoFaceCarPlay] Calculated dock screen frame df=%@ (sw=%.1f, sh=%.1f)
- [DuoFaceCarPlay] Exception in updateCarPlayMetrics: %@
- [DuoFaceCarPlay] Warning: Failed to write dock path: %@
- [DuoFaceCarPlay] Warning: Failed to write inset path: %@
- [DuoFaceCarPlay] Warning: Failed to write screen path: %@
- [DuoFaceCarPlay] safeInsets=%@, dockInsets=%@
- [DuoFaceCarPlay] updateCarPlayMetrics: Screen=%@, Insets=%@, Edge=%@
- [DuoFaceDB] CARAppDockViewController _dockButtonPressed: bundleID=%@
- [DuoFaceDB] CARApplication +_newApplicationLibrary: %@
- [DuoFaceDB] CARApplication -_newApplicationLibrary: %@
- [DuoFaceDB] CARIconManager iconTapped: iconView=%@, bid=%@, isBridged=%d
- [DuoFaceDB] CARIconManager iconTapped:modifierFlags: iconView=%@, bid=%@, isBridged=%d
- [DuoFaceDB] CARIconManager launchIcon: icon=%@, bid=%@, isBridged=%d
- [DuoFaceDB] CARIconManager launchIcon:location:animated:completionHandler: bid=%@, isBridged=%d
- [DuoFaceDB] CARIconManager launchIconForIconView: iconView=%@, bid=%@, isBridged=%d
- [DuoFaceDB] CARIconManager launchIconForIconView:withActions: iconView=%@, bid=%@, isBridged=%d
- [DuoFaceDB] CARIconModel addIcon exception: %@
- [DuoFaceDB] CARIconModel check leafIconForIdentifier:%@ -> %@
- [DuoFaceDB] CARIconModel loadAllIcons EXCEPTION: %@
- [DuoFaceDB] CARIconView _handleTapGesture: state=%ld, bid=%@, isBridged=%d
- [DuoFaceDB] CARIconView intercepted bridged app tap: %@
- [DuoFaceDB] CARRootStatusBarViewController homeButtonUp: activated=%d
- [DuoFaceDB] CBBundleIDForIconView FAILED: iconView=%@, icon=%@
- [DuoFaceDB] CBUpdateApplicationLibrary executing on library: %@
- [DuoFaceDB] CBUpdateApplicationLibrary registered info for %@
- [DuoFaceDB] DBIconView _handleTapGesture: state=%ld, bid=%@, isBridged=%d
- [DuoFaceDB] DBIconView intercepted bridged app tap: %@
- [DuoFaceDB] DBRootStatusBarViewController homeButtonUp: activated=%d
- [DuoFaceDB] Explicitly adding leaf icon %@ to CARIconModel
- [DuoFaceDB] Explicitly adding leaf icon %@ to rootFolder
- [DuoFaceDB] FBSApplicationLibrary allInstalledApplications injected special app: %@
- [DuoFaceDB] Failed to save request plist: %@
- [DuoFaceDB] LayoutSafety: targetFrame %@ intersects dockRect %@! Adjusting...
- [DuoFaceDB] License inactive/expired for native CarPlay app %@ -> PASS-THROUGH to native launcher
- [DuoFaceDB] License inactive/expired for non-native app %@ -> INTERCEPTING to present warning modal
- [DuoFaceDB] Notifying library of %lu added applications
- [DuoFaceDB] SBHIconManager iconTapped: iconView=%@, bid=%@, isBridged=%d
- [DuoFaceDB] SBHIconManager iconTapped:modifierFlags: iconView=%@, bid=%@, isBridged=%d
- [DuoFaceDB] SBHIconManager launchIconForIconView: iconView=%@, bid=%@, isBridged=%d
- [DuoFaceDB] SBHIconManager launchIconForIconView:withActions: iconView=%@, bid=%@, isBridged=%d
- [DuoFaceDB] SBIconView _handleTapGesture: state=%ld, bid=%@, isBridged=%d
- [DuoFaceDB] SBIconView intercepted bridged app tap: %@
- [DuoFaceDB] SBIconView touchesEnded intercepted bridged app: %@
- [DuoFaceDB] SystemMonitor applied targetFrame=%@ (dockMinY=%.1f, lowestItemY=%.1f, highestItemY=%.1f)
- [DuoFaceDB] Warning: Exception querying dataSource property: %@
- [DuoFaceDB] Warning: Exception querying icon application bundleID: %@
- [DuoFaceDB] Warning: Exception querying icon property %@: %@
- [DuoFaceDB] Warning: Exception querying iconView property %@: %@
- [DuoFaceDB] Warning: Failed to write req plist on disconnect (req=%d, tmp=%d)
- [DuoFaceDB] Warning: Failed to write request plist (req=%d, tmp=%d)
- [DuoFaceDB] [CONNECT_TRACE] DashBoard received screen connected notification: %@
- [DuoFaceDB] [DISCONNECT_TRACE] DashBoard received screen disconnected notification: %@
- [DuoFaceDB] _CARDashboardHomeViewController iconManager:launchIcon: bid=%@, isBridged=%d
- [DuoFaceDB] _CARDashboardHomeViewController iconManager:launchIcon:location: bid=%@, isBridged=%d
- [DuoFaceDB] _CARDashboardHomeViewController iconManager:launchIcon:location:animated: bid=%@, isBridged=%d
- [DuoFaceDB] _CARDashboardHomeViewController iconManager:launchIconForIconView: iconView=%@, bid=%@, isBridged=%d
- [DuoFaceDB] _CARDashboardHomeViewController iconManager:launchIconForIconView:withActions: iconView=%@, bid=%@, isBridged=%d
- [DuoFaceDB] _CARDashboardRootViewController viewSafeAreaInsetsDidChange: %@
- [DuoFaceDB] effectivePolicyForAppDeclaration: policy signal inactive for native app %@ -> 100%% %%orig pass-through
- [DuoFaceDB] requestActivation called for bundleID=%@ (pending=%d)
- [DuoFaceDB] requestDismiss called (current pending=%d)
- [DuoFaceDB] setHomeButtonInApp exception: %@
- [DuoFaceKB-Mode] kim cur=%@ active=%@
- [DuoFaceKB-Mode] kimc=%@ cur=%@ active=%@
- [DuoFaceKB-Tree] %@%@ frame=%@ bounds=%@ hidden=%d alpha=%.2f layer=%@ layerBounds=%@
- [DuoFaceKB]   starLayer=%@ frame=%@ hidden=%d opacity=%.2f
- [DuoFaceKB] Added prefix to setKeyboardName: from %@ to %@
- [DuoFaceKB] Added prefix to setKeyboardName:appearance: from %@ to %@
- [DuoFaceKB] Corrected (null) in setKeyboardName: from %@ to %@
- [DuoFaceKB] Corrected (null) in setKeyboardName:appearance: from %@ to %@
- [DuoFaceKB] Corrected nil setKeyboardName: to %@
- [DuoFaceKB] Corrected nil setKeyboardName:appearance: to %@
- [DuoFaceKB] Warning: Exception getting currentInputMode: %@
- [DuoFaceKB] Warning: Exception getting keyboardInputModeWithIdentifier: %@
- [DuoFaceKB] Warning: Exception in CBDumpViewHierarchy: %@
- [DuoFaceKB] Warning: Exception in activeInstance inputMode setup: %@
- [DuoFaceKB] Warning: Exception querying keyplane: %@
- [DuoFaceKB] Warning: Exception recovering keyplane: %@
- [DuoFaceKB] Warning: Exception setting idiom emulation on traits: %@
- [DuoFaceKB] [UIInputWindowController viewDidAppear:%d] view=%@
- [DuoFaceKB] [UIInputWindowController viewWillAppear:%d] view=%@
- [DuoFaceKB] [UIKeyboardImpl forcing fallback inputMode identifier: %@]
- [DuoFaceKB] [UIKeyboardImpl setDelegate:%@ force:%d]
- [DuoFaceKB] [UIKeyboardImpl showKeyboard] called! inHWMode=%d, autoMin=%d
- [DuoFaceKB] [UIKeyboardLayoutStar after showKeyboard] frame=%@ hidden=%d alpha=%.2f keyplane=%@ subviews=%lu sublayers=%lu
- [DuoFaceKB] [UIKeyboardLayoutStar setKeyboardName:%@ appearance:%ld]
- [DuoFaceKB] [UIKeyboardLayoutStar setKeyplaneName:%@]
- [DuoFaceKB] [UIKeyboardLayoutStar showKeyboard forcing inputMode: %@]
- [DuoFaceKB] [UIKeyboardLayoutStar showKeyboard] inputTraits=%@ screenTraits=%@
- [DuoFaceKB] [UIRemoteKeyboardWindow setAlpha:%.2f]
- [DuoFaceKB] [UIRemoteKeyboardWindow setHidden:%d] frame=%@
- [DuoFaceKB] [UIResponder becomeFirstResponder] class=%@ ret=%d
- [DuoFaceKB] [UIResponder resignFirstResponder] class=%@ ret=%d
- [DuoFaceKB] [UITextEffectsWindow setAlpha:%.2f]
- [DuoFaceKB] [UITextEffectsWindow setHidden:%d] frame=%@
- [DuoFaceKB] activeImpl=%@ inHWMode=%d autoMin=%d inMode=%@ kpName=%@
- [DuoFaceKB] layoutStar=%@ frame=%@ bounds=%@ hidden=%d alpha=%.2f subviews=%lu sublayers=%lu
- [DuoFaceKB] setDelegate exception: %@
- [DuoFaceKB] viewDidAppear inspection exception: %@
- [DuoFaceLicense] %@
- [DuoFaceLicense] Automated sync attempt detected from another process %llu s ago (< 10s cooldown). Skipping duplicate trigger.
- [DuoFaceLicense] Automated sync was already initiated %llu s ago (< 10s cooldown). Skipping duplicate trigger.
- [DuoFaceLicense] Dispatching async license sync request to %@ for HW: %@ (source: %@)
- [DuoFaceLicense] License refresh interval reached (interval=%llu s, last=%llu s, now=%llu s). Triggering background refresh...
- [DuoFaceLicense] Network request failed: %@
- [DuoFaceLicense] Offline license is valid (rem: %llu s). Next refresh in %llu s. Using cached license.
- [DuoFaceLicense] Server returned non-200 status code: %ld (Error: %@)
- [DuoFaceLicense] Warning: Ignoring invalid/negative expiration header: %@
- [DuoFaceLicense] Warning: Ignoring invalid/negative expiration in JSON: %@
- [DuoFaceSB] >>> AUTO-LAUNCHING/RESUMING APP AFTER CARPLAY CONNECT: %@ <<<
- [DuoFaceSB] >>> PRE-RENDER CHECK <<< CarPlay Screen: %@, UsableCanvas: %@, RenderCanvas: %@
- [DuoFaceSB] CarPlay display already present at init, scheduling auto-resume for: %@
- [DuoFaceSB] Close All (Fallback): Killing background PID %d for %@
- [DuoFaceSB] Close All: Killing background PID %d for %@
- [DuoFaceSB] Currently active app %@ was disabled -> deactivating
- [DuoFaceSB] Exception in notifyStateUpdated file write: %@
- [DuoFaceSB] Exception while terminating %@: %@
- [DuoFaceSB] Killing process %d for %@
- [DuoFaceSB] Live replacing slot %ld with %@
- [DuoFaceSB] Live switching split preset to %ld, apps: %@
- [DuoFaceSB] Metrics updated: %@
- [DuoFaceSB] Posting NOTIFY_APP_STATE to %@: %@
- [DuoFaceSB] Restart single app: Killing PID %d for %@
- [DuoFaceSB] Restart: Killing PID %d for %@
- [DuoFaceSB] Restarting slot %ld for app: %@
- [DuoFaceSB] Session tracked bridged app: %@ (Total: %lu)
- [DuoFaceSB] UI closeSingleAppTapped: %@
- [DuoFaceSB] UI restartSingleAppTapped: %@
- [DuoFaceSB] Warning: Exception in CBExtractBundleIDFromScene: %@
- [DuoFaceSB] Warning: Exception in updateSettings:withTransitionContext: %@
- [DuoFaceSB] Warning: Exception killing background process %@: %@
- [DuoFaceSB] Warning: Exception reading auto-resume bid: %@
- [DuoFaceSB] Warning: Exception setting scene association for %@: %@
- [DuoFaceSB] Warning: Failed to write bridge state file(s) (state=%d, tmp=%d)
- [DuoFaceSB] Warning: Failed to write clear bridge state file(s) (state=%d, tmp=%d)
- [DuoFaceSB] Warning: Failed to write notifyStateUpdated file(s) (state=%d, tmp=%d)
- [DuoFaceSB] [CONNECT_TRACE] CarPlay CADisplay available: %@
- [DuoFaceSB] [CONNECT_TRACE] Detected autoResume/autoLaunch BundleID: %@, scheduling launch...
- [DuoFaceSB] [CONNECT_TRACE] Ignoring rapid screen connect flap (%.2fs since last connect).
- [DuoFaceSB] [CONNECT_TRACE] handleScreenDidConnect triggered. Object screen: %@
- [DuoFaceSB] [DISCONNECT_TRACE]   - CADisplay[%lu]: %@ | name: %@ | uid: %@ | isMain: %d | screenType: %u
- [DuoFaceSB] [DISCONNECT_TRACE]   - Screen[%lu]: %@ | bounds: %@ | scale: %.1f | isMain: %d
- [DuoFaceSB] [DISCONNECT_TRACE] -> Sending shouldBridge:NO to child app: %@
- [DuoFaceSB] [DISCONNECT_TRACE] -> Sending shouldBridge:NO to single app: %@
- [DuoFaceSB] [DISCONNECT_TRACE] === Screen & Display State Dump (%@) ===
- [DuoFaceSB] [DISCONNECT_TRACE] >>> MANDATORY 1-MIN WATCHDOG EXPIRED: Unconditionally terminating %lu CarPlay session app(s) (ZERO EXCEPTION) <<<
- [DuoFaceSB] [DISCONNECT_TRACE] >>> MANDATORY 1-MIN WATCHDOG STARTED (token: %llu): %lu app(s) scheduled for forced termination in %d seconds <<<
- [DuoFaceSB] [DISCONNECT_TRACE] Cancelling mandatory disconnect watchdog (CarPlay reconnected, newToken: %llu).
- [DuoFaceSB] [DISCONNECT_TRACE] Current state -> activated: %d, bundleID: %@, currentApp: %@, sessionBridgedCount: %lu
- [DuoFaceSB] [DISCONNECT_TRACE] Darwin screen/CarPlay notification fired: %@
- [DuoFaceSB] [DISCONNECT_TRACE] DashBoard process exited (%@) -> Ensuring CarPlay disconnect cleanup in SpringBoard!
- [DuoFaceSB] [DISCONNECT_TRACE] Deactivating SplitApp (DuoFace) with %lu appViews
- [DuoFaceSB] [DISCONNECT_TRACE] Disconnect watchdog GCD block fired but token %llu is obsolete (current: %llu) -> Cancelled.
- [DuoFaceSB] [DISCONNECT_TRACE] Exception while forcibly terminating %@: %@
- [DuoFaceSB] [DISCONNECT_TRACE] Mandatory Watchdog: Forcibly terminating PID %d for %@ (Zero Exception)
- [DuoFaceSB] [DISCONNECT_TRACE] NSNotificationCenter received: name=%@ | object=%@ | userInfo=%@
- [DuoFaceSB] [DISCONNECT_TRACE] Preserved autoResumeBundleID before disconnect: %@
- [DuoFaceSB] [DISCONNECT_TRACE] Query Results -> carPlayCADisplay: %@ | carPlayUIScreen: %@ | carPlayWindowScene: %@
- [DuoFaceSB] [DISCONNECT_TRACE] Stopping and removing _currentApp (%@)...
- [DuoFaceSB] [DISCONNECT_TRACE] Total CADisplay count: %lu
- [DuoFaceSB] [DISCONNECT_TRACE] Total UIScreen count: %lu
- [DuoFaceSB] [DISCONNECT_TRACE] deactivateCurrentApp START -> activated: %d, bundleID: %@, currentApp: %@
- [DuoFaceSB] [DISCONNECT_TRACE] handleCarPlayConnectionChanged notification: %@
- [DuoFaceSB] [DISCONNECT_TRACE] handleScreenDidDisconnect triggered. Object screen: %@ (notif=%@)
- [DuoFaceSB] [LICENSE_KILL_TRACE] -> App %@ PID not active or already terminated.
- [DuoFaceSB] [LICENSE_KILL_TRACE] -> Found active Split slot %ld app: %@
- [DuoFaceSB] [LICENSE_KILL_TRACE] -> Found active single app: %@
- [DuoFaceSB] [LICENSE_KILL_TRACE] -> Found running background bridged app: %@ (PID: %@)
- [DuoFaceSB] [LICENSE_KILL_TRACE] -> FrontBoard resolved PID %d for %@
- [DuoFaceSB] [LICENSE_KILL_TRACE] -> KILLING PID %d for %@ via SIGKILL (POSIX signal 9)...
- [DuoFaceSB] [LICENSE_KILL_TRACE] -> SpringBoard resolved PID %d for %@
- [DuoFaceSB] [LICENSE_KILL_TRACE] -> kill(%d, SIGKILL) returned result: %d
- [DuoFaceSB] [LICENSE_KILL_TRACE] >>> IMMEDIATE KILL EXECUTION: Forcibly killing %lu application(s) <<<
- [DuoFaceSB] [LICENSE_KILL_TRACE] Adding %lu session-tracked bridged apps: %@
- [DuoFaceSB] [LICENSE_KILL_TRACE] Cleared %lu entries from _sessionBridgedBundleIDs.
- [DuoFaceSB] [LICENSE_KILL_TRACE] Exception while forcibly terminating %@: %@
- [DuoFaceSB] [LICENSE_KILL_TRACE] Scanning Split Screen (%lu slots) for active apps...
- [DuoFaceSB] [LICENSE_KILL_TRACE] Skipping protected system/internal BID: %@
- [DuoFaceSB] [LICENSE_KILL_TRACE] Step 3: Presenting license warning modal (type=%ld)...
- [DuoFaceSB] [LICENSE_KILL_TRACE] Step 4: Immediately killing all %lu targeted CarPlay app processes...
- [DuoFaceSB] [LICENSE_KILL_TRACE] Terminating app: %@ (sending shouldBridge:NO)...
- [DuoFaceSB] [LICENSE_KILL_TRACE] Total apps targeted for immediate termination: %lu %@
- [DuoFaceSB] [LICENSE_KILL_TRACE] handleSettingsChanged: License expired/invalid during settings sync (loaded=%d, status=%d, mask=0x%llx). Deactivating and presenting modal.
- [DuoFaceSB] [LICENSE_KILL_TRACE] licenseWatchdogTimerFired: Runtime license expired or invalid during session (loaded=%d, status=%d, mask=0x%llx).
- [DuoFaceSB] [LICENSE_KILL_TRACE] loadNewAppFromCurrentRequest: License validation failed (loaded=%d, status=%d, mask=0x%llx) for bid=%@.
- [DuoFaceSB] [LICENSE_KILL_TRACE] reconfigureSplitMode: License invalid (loaded=%d, status=%d, mask=0x%llx). Aborting split configuration.
- [DuoFaceSB] [LICENSE_KILL_TRACE] requestStateChange: App %@ active but license invalid (loaded=%d, status=%d, mask=0x%llx).
- [DuoFaceSB] evictAppFromPhoneScreen exception: %@
- [DuoFaceSB] performAutoResume: CarPlay CADisplay not ready, retrying #%ld in 1.0s...
- [DuoFaceSB] performAutoResume: License is inactive/expired (loaded=%d, status=%d). Skipping auto-launch.
- [DuoFaceSB] receivedAppRequestNotification for: %@
- [DuoFaceSB] requestStateChange: App %@ already active and visible, re-showing window.
- [DuoFaceSB] requestStateChange: App %@ marked active but window/display stale or detached (e.g. after CarPlay reconnect). Performing clean reload...
- [DuoFaceSB] restartApplicationWithBundleID: %@
- [DuoFaceSB] saveBridgeStateToDisk: %@
- [DuoFaceSB] syncDashboardPolicySignalToDisk: isValid=%d, exp=%llu, ts=%llu
- [DuoFaceSB] terminateApplicationWithBundleID: %@
- [DuoFaceWindow] createWindows completed: _rootWindow=%@, rootVC=%@, screenBounds=%@, usableBounds=%@, config=%@
- [DuoFaceWindow] resizeWindows completed: screenBounds=%@, usableBounds=%@
- [DuoFaceWindow] show: _rootWindow=%@, frame=%@, hidden=%d, level=%.1f
- [DuoFace] Acquired PreventUserIdleSystemSleep assertion result: %d, id: %u
- [DuoFace] Assistant start exception: %@
- [DuoFace] Assistant stop exception: %@
- [DuoFace] Assistant toggle exception: %@
- [DuoFace] Client App Modular Hooks initialized successfully for: %@
- [DuoFace] Dynamically updated tweak filter plist with %lu bundles
- [DuoFace] Initializing App hooks for target app: %@
- [DuoFace] Initializing Client App Modular Hooks for: %@...
- [DuoFace] Initializing DashBoard hooks in process: %@
- [DuoFace] Released PreventUserIdleSystemSleep assertion id: %u
- [DuoFace] SBAppViewController didUpdateSettingsWithDiff exception: %@
- [DuoFace] Tweak constructor loaded in process: %@ (PID %d)
- [DuoFace] Warning: Failed writing to log file: %@
- [DuoFace] _applyUpdate error: %@
- [DuoFace] carPlayCADisplay exception: %@
- [DuoFace] updateSceneSettingsFrame: scene not yet ready: %@
- [DuoFace] updateSettingsWithBlock error: %@
- [DuoFace_DEBUG] resolvedBackendBaseURL Tier 1 (File Override): %@
- [DuoFace_DEBUG] resolvedBackendBaseURL Tier 2 (Plist Override): %@
- [DuoFace_DEBUG] resolvedBackendBaseURL Tier 3 (Production Default): %@

### Class hệ thống/private đáng chú ý trong từ vựng tham chiếu (36)
CBAppMetadataItem, CBAppStateListener, CBAssistantManager, CBBridgeManager, CBBridgeManagerDashboard, CBBridgeRequest, CBBridgedApp, CBBridgedAssistantApp, CBBridgedAssistantView, CBBridgedPortalApp, CBBridgedPortalAppView, CBBridgedSplitApp, CBBridgedUIApp, CBBridgedUIAppView, CBDashboardSettings, CBDashboardShared, CBDividerButtonInfo, CBDividerView, CBDockMetricItemView, CBDockSystemMonitorView, CBHttpClient, CBLicenseShieldIconView, CBLicenseSyncManager, CBLicenseWarningModalView, CBLocalization, CBMultitaskingOverlayView, CBMultitaskingPillView, CBOverlayScrollView, CBSlotPillHitButton, CBSlotPillView, CBSlotPlaceholderView, CBSplitContainerView, CBSplitSplashScreenView, CBTouchCloneView, CBUIAppContainerView, CBWindow

## [GỐC] DuoFaceUI
- Kích thước: 2456784 byte; SHA256: 3d0f8eac292d2c22d7a773e520ff396d33498a4a14bf6e0f72eb62ccc9c174e3
- Thư viện nạp (16): libobjc.A.dylib, Foundation, CoreFoundation, UIKit, CoreGraphics, QuartzCore, Security, IOKit, SafariServices, MobileCoreServices, libSystem.B.dylib, CoreServices, Frameworks, lib, Frameworks, lib
- Ký hiệu import C/ObjC: 0 (binary đã strip bảng ký hiệu)
- Từ vựng: 1185 selector, 2212 chuỗi C, 58 tên class tham chiếu

### Class định nghĩa (27) và toàn bộ method

**CBAppManager** — 20 instance, 1 class
- instance: .cxx_destruct, allApps, disableAllApps, enableAllApps, enableAllEntertainmentApps, enableAllNavigationApps, enableAllUserApps, enableDefaultRecommendedApps, enabledBundleIDs, enabledCount, init, isAppEnabled:, isLoading, loadInstalledAppsWithCompletion:, reloadPreferences, savePreferences, setApp:enabled:, syncEnabledFlags, systemApps, userApps
- class: sharedInstance

**CBAppModel** — 15 instance, 0 class
- instance: .cxx_destruct, bundleIdentifier, category, categoryDisplayName, displayName, icon, isDefaultRecommendedCategory, isEnabled, isSystem, setBundleIdentifier:, setCategory:, setDisplayName:, setIcon:, setIsEnabled:, setIsSystem:

**CBAppPickerViewController** — 16 instance, 0 class
- instance: .cxx_destruct, apps, disabledBundleIDs, filteredApps, onSelectApp, searchController, setApps:, setDisabledBundleIDs:, setFilteredApps:, setOnSelectApp:, setSearchController:, tableView:cellForRowAtIndexPath:, tableView:didSelectRowAtIndexPath:, tableView:numberOfRowsInSection:, updateSearchResultsForSearchController:, viewDidLoad

**CBAppSection** — 9 instance, 0 class
- instance: .cxx_destruct, apps, footer, isUserSection, setApps:, setFooter:, setIsUserSection:, setTitle:, title

**CBAppSwitch** — 3 instance, 0 class
- instance: .cxx_destruct, bundleIdentifier, setBundleIdentifier:

**CBAppsManagerViewController** — 38 instance, 0 class
- instance: .cxx_destruct, appForIndexPath:, appSwitchToggled:, currentFilterIndex, dealloc, emptyLabel, filterChanged:, filterSegment, handleAppsUpdated, handleLanguageChanged, numberOfSectionsInTableView:, refreshData, searchBarCancelButtonClicked:, searchController, sections, setCurrentFilterIndex:, setEmptyLabel:, setFilterSegment:, setSearchController:, setSections:, setSpinner:, setTableView:, setupFilterHeader, setupNavigationItems, setupSearchController, setupTableView, showActionMenu, spinner, tableView, tableView:cellForRowAtIndexPath:, tableView:didSelectRowAtIndexPath:, tableView:numberOfRowsInSection:, tableView:titleForFooterInSection:, tableView:titleForHeaderInSection:, updateSearchResultsForSearchController:, viewDidLayoutSubviews, viewDidLoad, viewWillAppear:

**CBAssistantAboutViewController** — 24 instance, 0 class
- instance: assistantEnabled, assistantToggleChanged:, dealloc, handleLanguageChanged, init, loadPreferences, mapAppChanged:, numberOfSectionsInTableView:, performResetDefaults, performRespring, preferredMapIndex, savePreferences, setAssistantEnabled:, setPreferredMapIndex:, setVoiceFeedbackEnabled:, tableView:cellForRowAtIndexPath:, tableView:didSelectRowAtIndexPath:, tableView:numberOfRowsInSection:, tableView:titleForFooterInSection:, tableView:titleForHeaderInSection:, viewDidLoad, viewWillAppear:, voiceFeedbackEnabled, voiceFeedbackToggleChanged:

**CBGeneralSettingsViewController** — 30 instance, 0 class
- instance: autoLaunchOnConnect, autoLaunchToggleChanged:, dealloc, dockMonitorEnabled, dockMonitorToggleChanged:, handleAppDidBecomeActive, handleLanguageChanged, hideLabelsEnabled, hideLabelsToggleChanged:, init, loadPreferences, numberOfSectionsInTableView:, openSubscriptionScreen, performResetDefaults, performRespring, savePreferences, screenBlankEnabled, screenBlankToggleChanged:, setAutoLaunchOnConnect:, setDockMonitorEnabled:, setHideLabelsEnabled:, setScreenBlankEnabled:, showLanguageSelectionSheet, tableView:cellForRowAtIndexPath:, tableView:didSelectRowAtIndexPath:, tableView:numberOfRowsInSection:, tableView:titleForFooterInSection:, tableView:titleForHeaderInSection:, viewDidLoad, viewWillAppear:

**CBHttpClient** — 6 instance, 1 class
- instance: .cxx_destruct, getJSONFromURL:timeout:customHeaders:completion:, init, networkQueue, postJSON:toURL:timeout:customHeaders:completion:, setNetworkQueue:
- class: sharedClient

**CBLicenseExpiredModalViewController** — 29 instance, 1 class
- instance: .cxx_destruct, activateButton, blurBackdrop, cardView, dimmerOverlay, dismissWithCompletion:, handleActivateTapped, handleLaterTapped, iconImageView, laterButton, messageLabel, onActivateTapped, onDismissTapped, setActivateButton:, setBlurBackdrop:, setCardView:, setDimmerOverlay:, setIconImageView:, setLaterButton:, setMessageLabel:, setOnActivateTapped:, setOnDismissTapped:, setTitleLabel:, setupBackdrop, setupCardView, setupContent, titleLabel, viewDidLoad, viewWillAppear:
- class: modalWithActivateHandler:dismissHandler:

**CBLicenseSyncManager** — 24 instance, 6 class
- instance: .cxx_destruct, actualLicenseExpirationTimestamp, actualLicenseTierName, checkAndSyncLicenseIfNeeded, checkAndSyncLicenseIfNeededWithSource:, deviceHardwareHashHex, forceSyncWithCompletion:, init, installAndVerifyLicensePayload:errorMsg:, isCarPlayScreenConnected, isLicenseCurrentlyValid, isSyncing, lastAttemptTimestamp, performSyncWithForce:isManualUserAction:completion:, performSyncWithForce:isManualUserAction:source:completion:, remainingLicenseSeconds, resolvedBackendBaseURL, resolvedLicenseServerEndpoint, setActualLicenseExpirationTimestamp:, setActualLicenseTierName:, setIsSyncing:, setLastAttemptTimestamp:, setSyncQueue:, syncQueue
- class: formatBaseURLString:, isCarPlayScreen:, isCarPlayScreenConnected, isCarPlayScreenConnectedExcludingScreen:, resolvedBackendBaseURL, sharedInstance

**CBLocalization** — 6 instance, 7 class
- instance: .cxx_destruct, activeLanguageCode, init, localizedStringForKey:, reloadLanguage, stringTableForLanguageCode:
- class: currentLanguageCode, displayNameForLanguageCode:, localizedStringForKey:, setCurrentLanguageCode:, sharedInstance, speechVoiceLanguageCode, supportedLanguages

**CBSplitSplashScreenView** — 13 instance, 3 class
- instance: .cxx_destruct, dealloc, dismissAnimated:, dismissAnimated:completion:, handleTap:, initWithFrame:, isDismissing, layoutSubviews, onDismissed, onWillDismiss, setOnDismissed:, setOnWillDismiss:, startLoadingAnimation
- class: appIconImage, logoImage, radialGlowImageForDiameter:

**CBSplitViewController** — 42 instance, 0 class
- instance: .cxx_destruct, availableApps, dealloc, handleAppsLoaded, handleLanguageChanged, init, loadSettings, nameForBundleID:, numberOfSectionsInTableView:, presetTitleForIndex:, saveSettings, setAvailableApps:, setSlotApp1:, setSlotApp2:, setSlotApp3:, setSlotApp4:, setSlotName1:, setSlotName2:, setSlotName3:, setSlotName4:, setSplitEnabled:, setSplitPreset:, slotApp1, slotApp2, slotApp3, slotApp4, slotCountForPreset:, slotName1, slotName2, slotName3, slotName4, slotTitleForIndex:preset:, splitEnabled, splitPreset, tableView:cellForRowAtIndexPath:, tableView:didSelectRowAtIndexPath:, tableView:numberOfRowsInSection:, tableView:titleForFooterInSection:, tableView:titleForHeaderInSection:, updateNames, viewDidLoad, viewWillAppear:

**CBSubscriptionCheckoutCell** — 10 instance, 0 class
- instance: .cxx_destruct, checkoutButton, checkoutSpinner, checkoutTapped, configureWithTitle:loading:, delegate, initWithStyle:reuseIdentifier:, setCheckoutButton:, setCheckoutSpinner:, setDelegate:

**CBSubscriptionGiftcodeInputCell** — 9 instance, 0 class
- instance: .cxx_destruct, delegate, initWithStyle:reuseIdentifier:, pasteButton, pasteTapped, setDelegate:, setPasteButton:, setTextField:, textField

**CBSubscriptionGiftcodeRedeemCell** — 10 instance, 0 class
- instance: .cxx_destruct, delegate, initWithStyle:reuseIdentifier:, redeemButton, redeemTapped, setDelegate:, setLoading:, setRedeemButton:, setSpinner:, spinner

**CBSubscriptionHardwareIDCell** — 10 instance, 0 class
- instance: .cxx_destruct, clipboardButton, configureWithHardwareHash:, copyTapped, delegate, hwLabel, initWithStyle:reuseIdentifier:, setClipboardButton:, setDelegate:, setHwLabel:

**CBSubscriptionOrderCoordinator** — 36 instance, 0 class
- instance: .cxx_destruct, activeAmountCrypto, activeCurrency, activeNetwork, activeOrderId, activePaymentUrl, activeTierName, cancelActiveOrderWithCompletion:, checkOrderStatusOnce:, checkStatusManual, currentServerBaseURL, dealloc, delegate, fetchActivePendingOrderFromServer, handlePaymentCompletedSuccess, hasActivePendingOrder, openPaymentGatewayURL:, pollTimer, pollTimerFired, requestCancelPendingOrder, resumePayment, safariVC, safariViewControllerDidFinish:, setActiveAmountCrypto:, setActiveCurrency:, setActiveNetwork:, setActiveOrderId:, setActivePaymentUrl:, setActiveTierName:, setDelegate:, setPollTimer:, setSafariVC:, showAlertWithTitle:message:, startCheckoutForTier:forceNew:, startPollingOrderStatus:, stopPollingOrderStatus

**CBSubscriptionPendingOrderCell** — 18 instance, 0 class
- instance: .cxx_destruct, cancelBtn, cancelTapped, checkStatusButton, checkStatusTapped, configureWithTitle:description:, delegate, descLabel, initWithStyle:reuseIdentifier:, resumeBtn, resumeTapped, setCancelBtn:, setCheckStatusButton:, setDelegate:, setDescLabel:, setResumeBtn:, setTitleLabel:, titleLabel

**CBSubscriptionPlanCardCell** — 13 instance, 0 class
- instance: .cxx_destruct, badgeLabel, checkIcon, configureWithPlan:selected:formattedPrice:, descLabel, initWithStyle:reuseIdentifier:, nameLabel, priceLabel, setBadgeLabel:, setCheckIcon:, setDescLabel:, setNameLabel:, setPriceLabel:

**CBSubscriptionStatusCell** — 2 instance, 0 class
- instance: configureWithLoading:failed:, initWithStyle:reuseIdentifier:

**CBSubscriptionVIPCardCell** — 24 instance, 0 class
- instance: .cxx_destruct, badgeIcon, configureWithExpirationTimestamp:tierName:, durationKeyLabel, durationValueLabel, initWithStyle:reuseIdentifier:, keyLabel, keyValuePairWithKeyLabel:valueLabel:, licenseValidationKeyLabel, licenseValidationValueLabel, serverExpiryKeyLabel, serverExpiryValueLabel, setBadgeIcon:, setDurationKeyLabel:, setDurationValueLabel:, setLicenseValidationKeyLabel:, setLicenseValidationValueLabel:, setServerExpiryKeyLabel:, setServerExpiryValueLabel:, setStatusPillLabel:, setTitleLabel:, statusPillLabel, titleLabel, valueLabel

**CBSubscriptionVIPStatusCell** — 2 instance, 0 class
- instance: configureWithExpirationTimestamp:, initWithStyle:reuseIdentifier:

**CBSubscriptionViewController** — 71 instance, 0 class
- instance: .cxx_destruct, checkoutCellDidTapCheckout:, currentCheckoutButtonTitle, currentMode, dealloc, dismissKeyboard, displayNameForTier:, fetchPlansFromServer, formattedPriceForPlan:, giftCodeTextField, giftRedeemCell, giftcodeInputCellDidTapPaste:, giftcodeRedeemCellDidTapRedeem:, handleLanguageChanged, hardwareIDCellDidTapCopy:, isCheckoutLoading, isGiftRedeeming, isLoadingPlans, isVIPActiveWithSufficientDays, keyboardWillHide:, keyboardWillShow:, modeSegmentChanged:, modeSegmentedControl, numberOfSectionsInTableView:, orderCoordinator, orderCoordinator:setCheckStatusButtonChecking:, orderCoordinator:setCheckoutLoading:, orderCoordinator:shouldPresentAlert:, orderCoordinator:shouldPresentSafari:, orderCoordinatorDidClearPendingOrder:, orderCoordinatorDidCompletePaymentSuccessfully:, orderCoordinatorDidUpdatePendingOrder:, pendingOrderCellDidTapCancel:, pendingOrderCellDidTapCheckStatus:, pendingOrderCellDidTapResume:, plansData, plansLoadFailed, rawPlansData, redeemGiftCodeTapped, segmentedHeaderView, selectedTierIndex, setCurrentMode:, setGiftCodeTextField:, setGiftRedeemCell:, setGiftRedeemLoading:, setIsCheckoutLoading:, setIsGiftRedeeming:, setIsLoadingPlans:, setModeSegmentedControl:, setOrderCoordinator:, setPlansData:, setPlansLoadFailed:, setRawPlansData:, setSegmentedHeaderView:, setSelectedTierIndex:, setTableView:, setupTableHeader, setupTableView, showAlertWithTitle:message:, showPlansLoadFailureAlertWithError:, tableView, tableView:cellForRowAtIndexPath:, tableView:didSelectRowAtIndexPath:, tableView:numberOfRowsInSection:, tableView:titleForFooterInSection:, tableView:titleForHeaderInSection:, textFieldShouldReturn:, updateTableHeaderForCurrentState, viewDidLoad, viewWillAppear:, viewWillDisappear:

**XXAppDelegate** — 6 instance, 0 class
- instance: .cxx_destruct, application:didFinishLaunchingWithOptions:, rootViewController, setRootViewController:, setWindow:, window

**XXRootViewController** — 17 instance, 0 class
- instance: .cxx_destruct, appsNav, checkAndPresentLicenseModalIfNeeded, dealloc, handleAppDidBecomeActive, handleAppsUpdated, handleLanguageChanged, isShowingExpiredModal, setAppsNav:, setIsShowingExpiredModal:, setSettingsNav:, setSplitNav:, settingsNav, splitNav, updateBadge, viewDidAppear:, viewDidLoad

### Chuỗi hạ tầng
- notifications: CBAppsListUpdatedNotification; CBLanguageChangedNotification
- tên miền/tên Darwin com.*: com.duoface.http.client; com.duoface.license.sync
- đường dẫn plist: (không có)
- URL: http://; https://
- thẻ log: [DuoFaceDB] [DuoFaceLicense] [DuoFace] [DuoFace_DEBUG] [cd]

### Chuỗi log có định dạng (16)
- Code [%@] activated successfully!
Duration: %@.
All CarPlay multitasking features are now ready.
- Code [%@] has been applied.
Duration: %@.
All CarPlay multitasking features are ready.
- [DuoFaceLicense] %@
- [DuoFaceLicense] Automated sync attempt detected from another process %llu s ago (< 10s cooldown). Skipping duplicate trigger.
- [DuoFaceLicense] Automated sync was already initiated %llu s ago (< 10s cooldown). Skipping duplicate trigger.
- [DuoFaceLicense] Dispatching async license sync request to %@ for HW: %@ (source: %@)
- [DuoFaceLicense] License refresh interval reached (interval=%llu s, last=%llu s, now=%llu s). Triggering background refresh...
- [DuoFaceLicense] Network request failed: %@
- [DuoFaceLicense] Offline license is valid (rem: %llu s). Next refresh in %llu s. Using cached license.
- [DuoFaceLicense] Server returned non-200 status code: %ld (Error: %@)
- [DuoFaceLicense] Warning: Ignoring invalid/negative expiration header: %@
- [DuoFaceLicense] Warning: Ignoring invalid/negative expiration in JSON: %@
- [DuoFace] Warning: Failed writing to log file: %@
- [DuoFace_DEBUG] resolvedBackendBaseURL Tier 1 (File Override): %@
- [DuoFace_DEBUG] resolvedBackendBaseURL Tier 2 (Plist Override): %@
- [DuoFace_DEBUG] resolvedBackendBaseURL Tier 3 (Production Default): %@

### Class hệ thống/private đáng chú ý trong từ vựng tham chiếu (31)
CBAppManager, CBAppModel, CBAppPickerViewController, CBAppSection, CBAppSwitch, CBAppsManagerViewController, CBAssistantAboutViewController, CBGeneralSettingsViewController, CBHttpClient, CBLicenseExpiredModalViewController, CBLicenseSyncManager, CBLocalization, CBSplitSplashScreenView, CBSplitViewController, CBSubscriptionCheckoutCell, CBSubscriptionCheckoutCellDelegate, CBSubscriptionGiftcodeInputCell, CBSubscriptionGiftcodeInputCellDelegate, CBSubscriptionGiftcodeRedeemCell, CBSubscriptionGiftcodeRedeemCellDelegate, CBSubscriptionHardwareIDCell, CBSubscriptionHardwareIDCellDelegate, CBSubscriptionOrderCoordinator, CBSubscriptionOrderCoordinatorDelegate, CBSubscriptionPendingOrderCell, CBSubscriptionPendingOrderCellDelegate, CBSubscriptionPlanCardCell, CBSubscriptionStatusCell, CBSubscriptionVIPCardCell, CBSubscriptionVIPStatusCell, CBSubscriptionViewController

## [GỐC] DuoFaceFullscreenBridge.dylib
- Kích thước: 107744 byte; SHA256: cdb7f4f6c1a7e3db63c22f6e4551423d4a193a66c4708a549e2045a2d1d40088
- Thư viện nạp (12): libobjc.A.dylib, Foundation, CoreFoundation, UIKit, libc++.1.dylib, libSystem.B.dylib, CoreGraphics, CydiaSubstrate, Frameworks, lib, Frameworks, lib
- Ký hiệu import C/ObjC: 0 (binary đã strip bảng ký hiệu)
- Từ vựng: 228 selector, 94 chuỗi C, 6 tên class tham chiếu

### Class định nghĩa (4) và toàn bộ method

**DFFullscreenTransport** — 36 instance, 0 class
- instance: .cxx_destruct, center, client, desiredExpanded, handleCommand:, handleState:, host, lastSequences, leaseDeadline, leaseOwner, ownsFullscreen, pendingCompletion, pendingEnabled, pendingID, post:info:, publish:client:reason:, received:, send:enabled:requestID:, sequence, setCenter:, setClient:, setDesiredExpanded:, setHost:, setLastSequences:, setLeaseDeadline:, setLeaseOwner:, setOwnsFullscreen:, setPendingCompletion:, setPendingEnabled:, setPendingID:, setSequence:, setStateChanged:, setTimer:, stateChanged, tick, timer

**DFHostSnapshot** — 23 instance, 0 class
- instance: .cxx_destruct, app, appView, appViewFrame, appViewTransform, content, contentFrame, manager, managerFrame, renderSize, setApp:, setAppView:, setAppViewFrame:, setAppViewTransform:, setContent:, setContentFrame:, setManager:, setManagerFrame:, setRenderSize:, setWindow:, setWindowFrame:, window, windowFrame

**DFZoomAction** — 1 instance, 0 class
- instance: pressed:

**DFZoomReceiver** — 1 instance, 0 class
- instance: received:

### Chuỗi hạ tầng
- notifications: NSDistributedNotificationCenter
- tên miền/tên Darwin com.*: com.duoface.fullscreen.command.v1; com.duoface.fullscreen.picker.v1; com.duoface.fullscreen.state.v1
- đường dẫn plist: (không có)
- URL: (không có)
- thẻ log: [DuoFaceFullscreen]

### Chuỗi log có định dạng (10)
- [DuoFaceFullscreen] Zoom Out failed %@
- [DuoFaceFullscreen] bootstrap pending picker=%d transport=%d
- [DuoFaceFullscreen] candidate adapter started in %@
- [DuoFaceFullscreen] candidate adapter unavailable in %@ after class-load retries
- [DuoFaceFullscreen] host geometry applied %@
- [DuoFaceFullscreen] host restored sameOwner=%d
- [DuoFaceFullscreen] native picker zoom requested=%d
- [DuoFaceFullscreen] picker sheet width invalid %.1f
- [DuoFaceFullscreen] rollback %@
- [DuoFaceFullscreen] rollback restored=%d %@

### Class hệ thống/private đáng chú ý trong từ vựng tham chiếu (4)
DFFullscreenTransport, DFHostSnapshot, DFZoomAction, DFZoomReceiver

## [GỐC] DuoFaceVisualHook.dylib
- Kích thước: 75536 byte; SHA256: 4ebf68b630c102dee1bbaac87dcadddd3e13f618331cacd9c47ae1a27437959d
- Thư viện nạp (7): UIKit, Foundation, QuartzCore, CoreGraphics, libSystem.B.dylib, CoreFoundation, libobjc.A.dylib
- Ký hiệu import C/ObjC: 0 (binary đã strip bảng ký hiệu)
- Từ vựng: 63 selector, 48 chuỗi C, 0 tên class tham chiếu

### Class định nghĩa (0) và toàn bộ method

### Chuỗi hạ tầng
- notifications: (không có)
- tên miền/tên Darwin com.*: (không có)
- đường dẫn plist: (không có)
- URL: (không có)
- thẻ log: [DuoFaceBorder] [DuoFaceVisual12]

### Chuỗi log có định dạng (5)
- [DuoFaceBorder] RED OFF native idle view=%p
- [DuoFaceBorder] RED ON user activity view=%p focus=%d
- [DuoFaceBorder] install %@ start=%p stop=%p focus=%p restore=%p
- [DuoFaceBorder] signature mismatch start=%s stop=%s
- [DuoFaceVisual12] splash %@ applied; original loading untouched

## [GỐC] duoface_cboptimize_helper
- Kích thước: 150528 byte; SHA256: bd77f7594b649b722d71094f5a1d650d2bb9541a0827e12e21254d82f4a93906
- Thư viện nạp (8): CoreFoundation, IOKit, Security, libSystem.B.dylib, Frameworks, lib, Frameworks, lib
- Ký hiệu import C/ObjC: 0 (binary đã strip bảng ký hiệu)
- Từ vựng: 0 selector, 9 chuỗi C, 0 tên class tham chiếu

### Class định nghĩa (0) và toàn bộ method

### Chuỗi hạ tầng
- notifications: (không có)
- tên miền/tên Darwin com.*: (không có)
- đường dẫn plist: (không có)
- URL: (không có)
- thẻ log: (không có)

## [TA] DFTouchOwnerProbe.dylib
- Kích thước: 693232 byte; SHA256: 777ffa3b90be1b43ad50fd669e77cb7c5e065b4dadda6531322b3be592a7a345
- Thư viện nạp (8): UIKit, Foundation, QuartzCore, CoreGraphics, libc++.1.dylib, libobjc.A.dylib, libSystem.B.dylib, CoreFoundation
- Ký hiệu import C/ObjC: 0 (binary đã strip bảng ký hiệu)
- Từ vựng: 1474 selector, 1120 chuỗi C, 32 tên class tham chiếu

### Class định nghĩa (12) và toàn bộ method

**DF144Solo** — 64 instance, 0 class
- instance: .cxx_destruct, appPicker:closeRunningBundleID:, appPicker:didSelectBundleID:displayName:, appPicker:restartRunningBundleID:, appPicker:rotateRunningClockwise:, appPickerCloseAllRunning:, appPickerDidCancel:, appPickerDidRequestLayout:, appPickerDidRequestRunningApps:, appPickerDidRequestZoom:, appStateAck:, attemptOwnedReadyForView:request:generation:attempt:, begin:, bundle, carDisplayID, currentCarDisplayWithID:, df157InstallSoloMenuWithUsableRect:, df157ReturnHomeToPicker, display, emittedHosted, emittedManager, emittedTerminal, generalOwner, generalScene, generation, homeChooser, lastAppLease, physicalDisconnect:, publishGeneralAppState:, reply:reason:, reply:reason:verifiedPID:, request, root, sceneFailed:, sceneReady:, setBundle:, setCarDisplayID:, setDisplay:, setEmittedHosted:, setEmittedManager:, setEmittedTerminal:, setGeneralOwner:, setGeneralScene:, setGeneration:, setHomeChooser:, setLastAppLease:, setRequest:, setRoot:, setSoloPicker:, setSoloPill:, setSpeedDismissWindow:, setSpeedHUD:, setSpeedWindow:, setSurface:, setWindow:, soloPicker, soloPill, speedDismissWindow, speedHUD, speedWindow, stop:, surface, verifiedProcessStatePIDForView:, window

**DFAppInfo** — 5 instance, 0 class
- instance: .cxx_destruct, bundleID, displayName, setBundleID:, setDisplayName:

**DFAppLibrary** — 0 instance, 1 class
- class: installedUserApps

**DFAppPickerVC** — 109 instance, 0 class
- instance: .cxx_destruct, appSettingsNotifyToken, appSettingsObserverActive, apps, cards, cardsPerPage, closeAllRunningButton, closeAllRunningTapped:, closeButton, closeRunningTapped:, closeTapped, collectionView:cellForItemAtIndexPath:, collectionView:didSelectItemAtIndexPath:, collectionView:layout:sizeForItemAtIndexPath:, collectionView:numberOfItemsInSection:, currentMode, currentSlotBundleID, dealloc, delegate, displayNotifyToken, displayObserverActive, emptyImage, emptyTitle, gridColumns, gridRows, habitNotifyToken, habitObserverActive, headerIcon, headerSeparator, hostExpanded, installedIconForBundle:, inventoryGeneration, modeButtons, modes, nativeModePressed:, otherSlotBundleIDs, pageControl, pageControlChanged:, pageCount, pendingSlotBundleID, presentInstalledApps, presentRunningApps:, refreshInstalledApps, reloadCards, restartRunningTapped:, rotateBackwardButton, rotateBackwardTapped, rotateForwardButton, rotateForwardTapped, runningAppDetails, runningBundleIDs, runningCountLabel, runningMode, runningRotateCapacity, scrollViewDidEndDecelerating:, scrollViewDidEndDragging:willDecelerate:, scrollViewDidEndScrollingAnimation:, setAppSettingsNotifyToken:, setAppSettingsObserverActive:, setApps:, setCards:, setCardsPerPage:, setCloseAllRunningButton:, setCloseButton:, setCurrentMode:, setCurrentSlotBundleID:, setDelegate:, setDisplayNotifyToken:, setDisplayObserverActive:, setEmptyImage:, setEmptyTitle:, setGridColumns:, setGridRows:, setHabitNotifyToken:, setHabitObserverActive:, setHeaderIcon:, setHeaderSeparator:, setHostExpanded:, setInventoryGeneration:, setModeButtons:, setModes:, setOtherSlotBundleIDs:, setPageControl:, setPendingSlotBundleID:, setRotateBackwardButton:, setRotateForwardButton:, setRunningAppDetails:, setRunningBundleIDs:, setRunningCountLabel:, setRunningMode:, setRunningRotateCapacity:, setSheet:, setSheetMaterial:, setShowAppNames:, setTitleLabel:, setZoomButton:, sheet, sheetMaterial, showAppNames, titleLabel, updateCurrentPage, updateNativeModeButtons, updatePickerDisplayConfiguration, verifiedRunningIDForIndex:, viewDidLayoutSubviews, viewDidLoad, visibleApps, zoomButton, zoomTapped

**DFNative12Chrome** — 251 instance, 0 class
- instance: .cxx_destruct, actualTwoPaneWindowReadback, appPicker:closeRunningBundleID:, appPicker:didSelectBundleID:displayName:, appPicker:restartRunningBundleID:, appPicker:rotateRunningClockwise:, appPickerCloseAllRunning:, appPickerController, appPickerDidCancel:, appPickerDidRequestLayout:, appPickerDidRequestRunningApps:, appPickerDidRequestZoom:, appPickerVisible, appPickerWindow, appSceneContainers, appSceneWindows, applyHostFullscreenToScreenBoundsAfterDockAck:, applyLayoutSettingsFromDisk, beginDividerDragAt:, beginSavedWorkspaceRestore, borderGeneration, borderUntil, button:tag:action:, callback, closeHostedSlot:, closeMenu:, closeStylePicker:, completeWholeHostZoomRequest:, configurationClass, contentRect, controlsUntil, df175RefreshDividerVisibility:secondaryRect:, df176HUDLeaseTick:, df176LogKeyboardContext, df177FinishHUDHandover:, df177HUDHandoverTick, df177HandleAppTouch, df178HUDSnapshotUp, df178LogHUDGate:, disconnectTerminationCandidates, display, dividerDrag, dividerLogo, dividerOwnerSuspended, dividerPan:, dividerTouchOnScreen:, dividerTrack, dividerWindow, dragStartSecondary, emit:ratio:, emptyRoot:, externalWindowClass, finishDividerDragAt:cancelled:, focus, geometryReadback119, gestureRecognizer:shouldReceiveTouch:, gofaSpeedHUD, handover177HUD, handover177Window, hideAllExternalWindowsImmediately, homeReentrySkipsSplash, hostFullscreen, hostedScenes, hudHandover177Active, hudHandover177Deadline, hudHandover177Timer, hudLease176Generation, hudLease176Published, hudWasVisibleAt176, initWithDisplay:configuration:windowClass:contentRect:command:, installedBundleIDsForRestore, kbDiag176Token, lastActivityLayoutAt176, lastKbDiag176Timestamp, lastSent, layoutContextMenuForPane:, layoutControls, logoFraction, logoTouchChanged:, logoTouchDown:, logoTouchFinished:inside:cancelled:, logoTouchPending, logoWakeOnlyTap, makeWindow:root:level:, menuAction:, menuActions, menuBrandImage, menuContext, menuDismiss, normalContentRect, noteUserActivity, observeActivityInWindow:, openAppPickerForSlot:, openRunningAppManager, openSelectedHomeBundleID143:, openStylePicker, ownedRunningBundleIDs, panActive, pendingScenes, physicalForVisual:, pickerBrand, pickerVisible, pickerWindow, pillMenu, pillPressed:, pillWindows, pillZoom, preset, ratio, realAppTouched:, refreshGlobalSpeedHUD164, renderDividerDragFinal:, restoreGeneration, restoreHostFullscreenGeometry, restoreNextSavedWorkspaceApp, restorePending, restoreQueue, restoreRetryCounts, restoringPhysical, rotateHostedAppsClockwise:, saveSplitState, sceneFailed:, sceneHandleReady, sceneReady:, scheduleFailedRestoreRetryForPhysical:reason:, secondaryDividerPan:, secondaryDividerTrack, secondaryDividerWindow, secondaryDragStartPoint, secondaryRatio, secondaryTouchOnScreen:, selectStylePreset:, selectedSlot, setAppPickerController:, setAppPickerVisible:, setAppPickerWindow:, setAppSceneContainers:, setAppSceneWindows:, setBorderGeneration:, setBorderUntil:, setCallback:, setConfigurationClass:, setContentRect:, setControlsUntil:, setDisplay:, setDividerDrag:, setDividerLogo:, setDividerOwnerSuspended:, setDividerTrack:, setDividerWindow:, setDragStartSecondary:, setExternalWindowClass:, setFocus:, setGofaSpeedHUD:, setHandover177HUD:, setHandover177Window:, setHomeReentrySkipsSplash:, setHostFullscreen:, setHostedScenes:, setHudHandover177Active:, setHudHandover177Deadline:, setHudHandover177Timer:, setHudLease176Generation:, setHudLease176Published:, setHudWasVisibleAt176:, setKbDiag176Token:, setLastActivityLayoutAt176:, setLastKbDiag176Timestamp:, setLastSent:, setLogoFraction:, setLogoTouchPending:, setLogoWakeOnlyTap:, setMenuActions:, setMenuBrandImage:, setMenuContext:, setMenuDismiss:, setNormalContentRect:, setPanActive:, setPendingScenes:, setPickerBrand:, setPickerVisible:, setPickerWindow:, setPillMenu:, setPillWindows:, setPillZoom:, setPreset:, setRatio:, setRestoreGeneration:, setRestorePending:, setRestoreQueue:, setRestoreRetryCounts:, setRestoringPhysical:, setSceneHandleReady:, setSecondaryDividerTrack:, setSecondaryDividerWindow:, setSecondaryDragStartPoint:, setSecondaryRatio:, setSelectedSlot:, setSpeedDismissWindow:, setSpeedHUDWindow:, setSplashWindow:, setStartupActive:, setStyleChoices:, setStyleHeaderActions:, setStyleHeaderLogo:, setStyleHeaderTitle:, setStyleModeBar:, setStyleSelectionBadges:, setStyleVisible:, setStyleWindow:, setStyleZoom:, setSwapped:, setTouch177Bundles:, setTouch177LastBundle:, setTouchWake177Token:, setVerticalDivider:, setWindows:, setWorkspace:, skipStartupSplashForHomeReentry, speedDismissWindow, speedHUDWindow, splashWindow, start, startupActive, stateSnapshot, stop, styleChoices, styleHeaderActions, styleHeaderLogo, styleHeaderTitle, styleModeBar, styleSelectionBadges, styleVisible, styleWindow, styleZoom, swapPressed:, swapped, touch177Bundles, touch177LastBundle, touchWake177Token, updateDividerDragAt:, updateGripBlinkForVisibleSession:, verifiedRunningDetails, verticalDivider, visualForPhysical:, visualSlotForVerifiedRunningBundleID:, windows, workspace, zoomButtonTouchCancelled:, zoomButtonTouchDown:, zoomPressed:

**DFNative8SpeedHUDView** — 66 instance, 0 class
- instance: .cxx_destruct, compactIndicator, compactRestoreCenter, compactTemporarily, current, deleteDropRect, dfCollapseFloatingSettings, dfDisplayCenter, dfExpandFloatingSettings, dfSetDisplayCenter:, didMoveToWindow, dismissTarget, dismissWindow, displayLimit, floatingCompactCenter, floatingDragBounds, floatingWindowMode, initWithFrame:, layoutSubviews, limit, limitRing, loadSettings, ownerWindow, pan:, refreshSettingsLabels, refreshStyle, refreshVisibility169, removeDismissTarget, restoreSavedPosition, savePosition, saveSettings, selectedSource, setCompactIndicator:, setCompactRestoreCenter:, setCompactTemporarily:, setCurrent:, setDismissTarget:, setDismissWindow:, setDisplayLimit:, setFloatingCompactCenter:, setFloatingDragBounds:, setFloatingWindowMode:, setLimit:, setLimitRing:, setOwnerWindow:, setSelectedSource:, setSettingsPanel:, setTimer:, setUnit:, setVisualOpacity:, setVisualScale:, setWindowHiddenForDisable:, settingsAction:, settingsPanel, showDismissTarget, showSettings:, sourceTitle, stop, tapCompact169:, temporarilyCompact169, tick:, timer, unit, visualOpacity, visualScale, windowHiddenForDisable

**DFNativeActivityObserver** — 6 instance, 0 class
- instance: .cxx_destruct, activity, canBePreventedByGestureRecognizer:, canPreventGestureRecognizer:, setActivity:, touchesBegan:withEvent:

**DFNativeAppCard** — 23 instance, 0 class
- instance: .cxx_destruct, appBadgeKind, appGridColumns, appStateBadge, closeRunning, icon, initWithFrame:, layoutSubviews, restartRunning, runningControls, runningDetail, setAppBadgeKind:, setAppGridColumns:, setAppStateBadge:, setCloseRunning:, setIcon:, setRestartRunning:, setRunningControls:, setRunningDetail:, setShowsAppName:, setTitle:, showsAppName, title

**DFNativeDividerGripButton** — 23 instance, 0 class
- instance: .cxx_destruct, activeTouch, pointInside:withEvent:, screenPointForTouch:, setActiveTouch:, setTouchBegan:, setTouchEnded:, setTouchMoved:, setTouchTracked:, setTraceID:, setTraceStarted:, setTrackedScreenPoint:, touchBegan, touchEnded, touchMoved, touchTracked, touchesBegan:withEvent:, touchesCancelled:withEvent:, touchesEnded:withEvent:, touchesMoved:withEvent:, traceID, traceStarted, trackedScreenPoint

**DFNativePanePassthroughView** — 6 instance, 0 class
- instance: .cxx_destruct, hitTest:withEvent:, lastPaneTouchAt, setLastPaneTouchAt:, setTouchBeganInPane:, touchBeganInPane

**DFSceneHost** — 14 instance, 1 class
- instance: .cxx_destruct, bundleIDForHostedView:, didFinishSurface:, hostViewForBundleID:error:, init, isLiveSceneForHostedView:, live, releaseHostedView:, setFastInitialPolling:forHostedView:, setLive:, setSplitMode:forHostedView:, stopAllHosts, verifiedPIDForHostedView:, wasProcessAbsentBeforeHostedView:
- class: sharedHost

**DFSceneSurface** — 91 instance, 0 class
- instance: .cxx_destruct, appController, bundleID, commitSceneGeometry:, committedReferenceSize, committingSceneGeometry, df175NoteGeometrySkip, didMoveToWindow, entity, failed:, fastInitialPolling, findParentController, geometryCommitAttempts, geometryCommitTimer, gofaLastPublish, gofaLayoutAcknowledged:, gofaOwner, hitTest:withEvent:, lastApplied, lastHitLogAt, lastLoggedResizeSize, lastObservedForeground, lastViewportLogAt, layingOutScene, layoutScene, layoutSubviews, observersRegistered175, owner, parentController, pendingReferenceSize, policyDeviceController, policySceneHandle, pollScene:, processDidNotExistBeforeHost, publishGofaLayoutRequest, publishYouTubeState, ready, registerOwnedOrientationForDeviceController:, revokeOrientationPolicy, revokeYouTubeState, scene, sceneGeneration, sceneSettingsBefore, scheduleGeometryCommit, setAppController:, setBundleID:, setCommittedReferenceSize:, setCommittingSceneGeometry:, setEntity:, setFastInitialPolling:, setGeometryCommitAttempts:, setGeometryCommitTimer:, setGofaLastPublish:, setGofaOwner:, setLastApplied:, setLastHitLogAt:, setLastLoggedResizeSize:, setLastObservedForeground:, setLastViewportLogAt:, setLayingOutScene:, setObserversRegistered175:, setOwner:, setParentController:, setPendingReferenceSize:, setPolicyDeviceController:, setPolicySceneHandle:, setProcessDidNotExistBeforeHost:, setReady:, setScene:, setSceneGeneration:, setSceneSettingsBefore:, setSplitUIVisible:, setStarted:, setStopped:, setTimer:, setTries:, setYoutubeLastPublish:, setYoutubeOwner:, setYoutubeState:, splitUIVisible, start, started, stop, stopped, timer, tries, youtubeLastPublish, youtubeOwner, youtubeState, youtubeStateAcknowledged:, youtubeStateRequested:

### Chuỗi hạ tầng
- notifications: DBNotificationWindow; NSDistributedNotificationCenter; v16@?0@"NSNotification"8
- tên miền/tên Darwin com.*: com.duoface.; com.duoface.apptouch177.wake; com.duoface.gofa.layout-ack.v140; com.duoface.gofa.layout-state.v140; com.duoface.independent.app-state.ack.v155; com.duoface.ipc.v156.%@.%@; com.duoface.ipc.v176.kbdiag; com.duoface.ipc.v177.apptouch; com.duoface.kbdiag176.wake; com.duoface.native.scenehost; com.duoface.nativehost.app-choices.changed.v1; com.duoface.nativehost.disconnect-close.changed.v1; com.duoface.nativehost.dockzoom.ack.v1; com.duoface.nativehost.dockzoom.command.v1; com.duoface.nativehost.enabled-apps.changed.v1; com.duoface.nativehost.layout.changed.v1; com.duoface.nativehost.owner-revoke.v1; com.duoface.nativehost.picker-display.changed.v1; com.duoface.nativehost.solo-picker.request; com.duoface.nativehost.standalone144.request; com.duoface.nativehost.standalone144.result; com.duoface.nativehost.standalone144.stop; com.duoface.nativehost.standalone144.stop.native-switch; com.duoface.nativehost.standalone144.stop.owner-revoke; com.duoface.nativehost.standalone144.stop.pending-watchdog; com.duoface.nativehost.touchowner.ack.v1; com.duoface.nativehost.touchowner.command.v1; com.duoface.nativehost.touchowner.start.v1; com.duoface.nativehost.touchowner.stop.v1; com.duoface.scene; com.duoface.scene.actual.touch; com.duoface.scene.failure; com.duoface.scene.ready; com.duoface.speedhud; com.duoface.speedhud.v1.gofa; com.duoface.speedhud.visibility.v1.changed; com.duoface.trafficnav.v2.gofa.cpnavigation; com.duoface.youtube.host-ack.v1; com.duoface.youtube.host-request.v1; com.duoface.youtube.host-state.v1
- đường dẫn plist: /var/mobile/Library/Preferences/com.duoface.nativehost.app-choices.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.app-usage.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.disconnect-close.ack.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.disconnect-close.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.dockzoom.ack.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.dockzoom.command.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.enabled-apps.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.extended-settings.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.home-publisher136.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.home140-consent.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.layout.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.native-map-lease.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.native-owner.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.native-rail.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.owner-revoke.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.physical-panes.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.picker-display.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.qa173.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.qa175.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.qa176.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.qa177.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.solo-picker-request.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.standalone144-optin.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.standalone144-request.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.standalone144-result.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.standalone144-sb-lease.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.ack.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.command.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.workspace.v1.plist; /var/mobile/Library/Preferences/com.duoface.speedhud.lease176.chrome.plist; /var/mobile/Library/Preferences/com.duoface.speedhud.overlay163.plist; /var/mobile/Library/Preferences/com.duoface.speedhud.visibility.v1.plist
- URL: (không có)
- thẻ log: [DF156IPC] [DFHome137] [DFNative12Chrome] [DFStandalone144] [DFTouchOwner] [DuoFaceDisconnect] [DuoFaceDockZoom] [DuoFaceHomeABI] [DuoFaceScene] [DuoFaceSpeed8] [DuoFace]

### Chuỗi log có định dạng (15)
- /var/mobile/Library/Logs/DuoFaceGeometry119-%@.jsonl
- DuoFace: speed %@ km/h; limit %@ km/h
- [DF156IPC] transport-write-failed bundle=%@ ack=%d
- [DFHome137] process=%@ pid=%d %@

- [DFNative12Chrome] %@
- [DFStandalone144] time=%.3f process=%@ stage=%@ %@

- [DFTouchOwner] %@ %@
- [DuoFaceDisconnect] %@ %@

- [DuoFaceDockZoom] nonowner-awaiting-real-ack=%@
- [DuoFaceDockZoom] verified-two-owner-zoom=%d
- [DuoFaceHomeABI] process=%@ pid=%d %@

- [DuoFaceScene] event=%@ bundle=%@ %@
- [DuoFaceSpeed8] viewer NO_FRESH_SAMPLE source=GOFA ttl=5s process=%@
- [DuoFace] native-card-picker real-installed-apps=%lu
- abi %c[%s %s] %@

### Class hệ thống/private đáng chú ý trong từ vựng tham chiếu (13)
DF144Solo, DFAppInfo, DFAppLibrary, DFAppPickerDelegate, DFAppPickerVC, DFNative12Chrome, DFNative8SpeedHUDView, DFNativeActivityObserver, DFNativeAppCard, DFNativeDividerGripButton, DFNativePanePassthroughView, DFSceneHost, DFSceneSurface

## [TA] DuoFaceNativeHost
- Kích thước: 348832 byte; SHA256: 19c17dea105c8c33cb985245a68df2542b9db7c8440ec1b7edfbd59dd168af43
- Thư viện nạp (11): UIKit, CarPlay, Foundation, QuartzCore, CoreGraphics, AVFoundation, Speech, libobjc.A.dylib, libSystem.B.dylib, AVFAudio, CoreFoundation
- Ký hiệu import C/ObjC: 0 (binary đã strip bảng ký hiệu)
- Từ vựng: 689 selector, 411 chuỗi C, 27 tên class tham chiếu

### Class định nghĩa (10) và toàn bộ method

**DFAppHabitsController** — 10 instance, 0 class
- instance: .cxx_destruct, closeHabitSettings, initWithInventory:, inventory, saveDefault:pinned:, setInventory:, tableView:cellForRowAtIndexPath:, tableView:didSelectRowAtIndexPath:, tableView:numberOfRowsInSection:, viewDidLoad

**DFNative12BasicController** — 1 instance, 0 class
- instance: viewDidLoad

**DFNativeDiagnostics** — 0 instance, 2 class
- class: prepareShareFiles, tailAtPath:maxBytes:

**DFNativeHostAppDelegate** — 2 instance, 0 class
- instance: application:configurationForConnectingSceneSession:options:, application:didFinishLaunchingWithOptions:

**DFNativeHostCarSceneDelegate** — 7 instance, 0 class
- instance: .cxx_destruct, scene:willConnectToSession:options:, sceneDidBecomeActive:, sceneDidDisconnect:, sceneWillResignActive:, setWindow:, window

**DFNativeHostPhoneSceneDelegate** — 5 instance, 0 class
- instance: .cxx_destruct, scene:willConnectToSession:options:, sceneDidDisconnect:, setWindow:, window

**DFNativeHostRootController** — 68 instance, 0 class
- instance: .cxx_destruct, allEligibleBundleIDs, appSearch, appSettingsSaveFailed, appSwitchToggled:, appsInGroup:, appsTable, art:, carPlay, currentPreset, diagnosticsButton, disconnectCloseSwitchChanged:, dockMonitorButton, home136SwitchChanged:, home145SwitchChanged:, initWithCarPlay:, installedApps, loadView, mainLogo, makeText:, nativeMapPaneAlert:detail:, nativeMapPaneCommand:slot:, nativeSurface, numberOfSectionsInTableView:, queryInstalledApps, readSavedPreset, refreshSpeedBubbleButton, reloadLiveStatus, searchBar:textDidChange:, setAppSearch:, setAppsTable:, setCarPlay:, setCurrentPreset:, setDiagnosticsButton:, setDockMonitorButton:, setInstalledApps:, setMainLogo:, setNativeSurface:, setSpeedBubbleButton:, setStateLabel:, setTabs:, setVoiceAssistant:, setVoiceButton:, shareCarPlayDiagnostics:, showAppSettingsActions, showDockMonitor:, showHabitSettings, showLanguageOptions, showNativeMapPaneChoices, showPickerDisplaySettings, showResetOptions, showWorkspaceRestoreMenu, speedBubbleButton, stateLabel, tabChanged:, tableView:cellForRowAtIndexPath:, tableView:didSelectRowAtIndexPath:, tableView:numberOfRowsInSection:, tableView:titleForHeaderInSection:, tabs, toggleSpeedBubble:, toggleVoiceAssistant:, viewDidAppear:, viewDidLoad, viewWillDisappear:, voiceAssistant, voiceButton, writeNativeLayoutPreset:

**DFNativeHostSurfaceView** — 30 instance, 0 class
- instance: .cxx_destruct, activeTouch, commandSequence, contextID, dealloc, didMoveToWindow, disconnectSurface, hasSystemOwnedCarPlayWindow, initWithFrame:, lastMoveAt, layoutSubviews, lease, pointInside:withEvent:, refresh:, relayTouch:phase:, remote, session, setActiveTouch:, setCommandSequence:, setContextID:, setLastMoveAt:, setLease:, setRemote:, setSession:, start, stop, touchesBegan:withEvent:, touchesCancelled:withEvent:, touchesEnded:withEvent:, touchesMoved:withEvent:

**DFNativeHostTemplateSceneDelegate** — 37 instance, 0 class
- instance: .cxx_destruct, basicController, carWindow, consumeTouchCommand, geometrySample, geometrySampleTime, interfaceController, lastTouchSequence, nativeOwnerRevokeRegistered, nativeOwnerRevokeToken, renewTouchOwnerHeartbeat:, sceneDidBecomeActive:, sceneDidDisconnect:, sceneDidEnterBackground:, sceneWillResignActive:, setBasicController:, setCarWindow:, setGeometrySample:, setGeometrySampleTime:, setInterfaceController:, setLastTouchSequence:, setNativeOwnerRevokeRegistered:, setNativeOwnerRevokeToken:, setTouchCount:, setTouchHeartbeat:, setTouchOwnerScene:, setTouchRelayToken:, setTouchSession:, startTouchOwnerForScene:, stopTouchOwnerWithReason:, templateApplicationScene:didConnectInterfaceController:toWindow:, templateApplicationScene:didDisconnectInterfaceController:fromWindow:, touchCount, touchHeartbeat, touchOwnerScene, touchRelayToken, touchSession

**DFVoiceAssistant** — 26 instance, 0 class
- instance: .cxx_destruct, dealloc, done, engine, finishTranscript:generation:, generation, init, isListening, ownsVoiceAudioSession, recognizer, request, setDone:, setEngine:, setGeneration:, setListening:, setOwnsVoiceAudioSession:, setRecognizer:, setRequest:, setSpeaker:, setTask:, speaker, startWithPermission:, stop, task, toggleFromController:completed:, voiceReply:

### Chuỗi hạ tầng
- notifications: (không có)
- tên miền/tên Darwin com.*: com.duoface.; com.duoface.mytweak.cp-command; com.duoface.native.scenehost; com.duoface.nativehost.app-choices.changed.v1; com.duoface.nativehost.disconnect-close.changed.v1; com.duoface.nativehost.enabled-apps.changed.v1; com.duoface.nativehost.extended-settings.changed.v1; com.duoface.nativehost.home-publisher136.changed.v1; com.duoface.nativehost.layout.changed.v1; com.duoface.nativehost.map-pane.command.v1; com.duoface.nativehost.owner-revoke.v1; com.duoface.nativehost.picker-display.changed.v1; com.duoface.nativehost.standalone144.consent.changed.v1; com.duoface.nativehost.standalone144.stop; com.duoface.nativehost.touchowner.ack.v1; com.duoface.nativehost.touchowner.command.v1; com.duoface.nativehost.touchowner.start.v1; com.duoface.nativehost.touchowner.stop.v1; com.duoface.speedhud.visibility.v1.changed; com.duoface.trafficnav.v1.gofa.discovery; com.duoface.trafficnav.v2.gofa.cpnavigation; com.duoface.trafficnav.v2.gofa.decoder
- đường dẫn plist: /var/mobile/Library/Preferences/com.duoface.mytweak.carplay-bridge.plist; /var/mobile/Library/Preferences/com.duoface.mytweak.cp-command.plist; /var/mobile/Library/Preferences/com.duoface.mytweak.cp-host-fullscreen.plist; /var/mobile/Library/Preferences/com.duoface.mytweak.cp-receiver-ack.plist; /var/mobile/Library/Preferences/com.duoface.mytweak.cp-surface.plist; /var/mobile/Library/Preferences/com.duoface.mytweak.v1bc.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.app-choices.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.app-usage.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.disconnect-close.ack.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.disconnect-close.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.dockzoom.ack.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.enabled-apps.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.extended-settings.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.home-publisher136.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.home140-consent.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.layout.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.map-pane.ack.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.map-pane.command.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.native-map-choice.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.native-map-lease.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.native-owner.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.owner-revoke.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.physical-panes.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.picker-display.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.standalone144-optin.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.standalone144-result.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.standalone144-sb-lease.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.ack.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.command.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.workspace.v1.plist; /var/mobile/Library/Preferences/com.duoface.speedhud.visibility.v1.plist
- URL: (không có)
- thẻ log: [DuoFaceNativeHost] [DuoFacePhone] [DuoFaceSpeed8]

### Chuỗi log có định dạng (7)
- /var/mobile/Library/Logs/DuoFaceGeometry119-%@.jsonl
- DuoFace CarPlay / media scene diagnostic (manual export)
Date: %@
iOS: %@
App: %@
This file contains technical diagnostics; share only with a trusted recipient.

- DuoFaceAudit-%lld
- DuoFaceGeometry119-%@.jsonl
- [DuoFaceNativeHost] %@

- [DuoFaceNativeHost] native-content-context-failed %@
- [DuoFacePhone] installed-app-list error=%@

### Class hệ thống/private đáng chú ý trong từ vựng tham chiếu (11)
CPTemplateApplicationSceneDelegate, DFAppHabitsController, DFNative12BasicController, DFNativeDiagnostics, DFNativeHostAppDelegate, DFNativeHostCarSceneDelegate, DFNativeHostPhoneSceneDelegate, DFNativeHostRootController, DFNativeHostSurfaceView, DFNativeHostTemplateSceneDelegate, DFVoiceAssistant

## [TA] DFCarPlayDockOwner.dylib
- Kích thước: 296496 byte; SHA256: 245f70c2268021bb6813ac1c6974fd0f7500a1370ac29e3b135b8b5484cc9089
- Thư viện nạp (8): UIKit, Foundation, CoreGraphics, QuartzCore, libc++.1.dylib, libobjc.A.dylib, libSystem.B.dylib, CoreFoundation
- Ký hiệu import C/ObjC: 0 (binary đã strip bảng ký hiệu)
- Từ vựng: 301 selector, 747 chuỗi C, 7 tên class tham chiếu

### Class định nghĩa (3) và toàn bộ method

**DFHomeLaunch142** — 0 instance, 1 class
- class: sample

**DFNative8SpeedHUDView** — 66 instance, 0 class
- instance: .cxx_destruct, compactIndicator, compactRestoreCenter, compactTemporarily, current, deleteDropRect, dfCollapseFloatingSettings, dfDisplayCenter, dfExpandFloatingSettings, dfSetDisplayCenter:, didMoveToWindow, dismissTarget, dismissWindow, displayLimit, floatingCompactCenter, floatingDragBounds, floatingWindowMode, initWithFrame:, layoutSubviews, limit, limitRing, loadSettings, ownerWindow, pan:, refreshSettingsLabels, refreshStyle, refreshVisibility169, removeDismissTarget, restoreSavedPosition, savePosition, saveSettings, selectedSource, setCompactIndicator:, setCompactRestoreCenter:, setCompactTemporarily:, setCurrent:, setDismissTarget:, setDismissWindow:, setDisplayLimit:, setFloatingCompactCenter:, setFloatingDragBounds:, setFloatingWindowMode:, setLimit:, setLimitRing:, setOwnerWindow:, setSelectedSource:, setSettingsPanel:, setTimer:, setUnit:, setVisualOpacity:, setVisualScale:, setWindowHiddenForDisable:, settingsAction:, settingsPanel, showDismissTarget, showSettings:, sourceTitle, stop, tapCompact169:, temporarilyCompact169, tick:, timer, unit, visualOpacity, visualScale, windowHiddenForDisable

**DFSpeedNativeOverlay163** — 17 instance, 1 class
- instance: .cxx_destruct, detach, detachWithReason:, duoFaceOwnsExternalChrome, hud, install, isCarPlayProcess, ownerWindow, poll:, previousWindowCount, sceneChanged:, setHud:, setOwnerWindow:, setPreviousWindowCount:, setTimer:, timer, visibleExternalOwner
- class: shared

### Chuỗi hạ tầng
- notifications: DBNotificationWindow
- tên miền/tên Darwin com.*: com.duoface.; com.duoface.native.scenehost; com.duoface.nativehost.dockzoom.ack.v1; com.duoface.nativehost.dockzoom.command.v1; com.duoface.nativehost.enabled-apps.changed.v1; com.duoface.nativehost.home-publisher136.changed.v1; com.duoface.nativehost.owner-revoke.v1; com.duoface.nativehost.standalone144.request; com.duoface.nativehost.standalone144.result; com.duoface.nativehost.standalone144.stop; com.duoface.nativehost.standalone144.stop.native-switch; com.duoface.nativehost.standalone144.stop.owner-revoke; com.duoface.nativehost.standalone144.stop.pending-watchdog; com.duoface.speedhud; com.duoface.speedhud.v1.gofa; com.duoface.speedhud.visibility.v1.changed; com.duoface.trafficnav.v2.gofa.cpnavigation
- đường dẫn plist: /var/mobile/Library/Preferences/com.duoface.nativehost.dockzoom.ack.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.dockzoom.command.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.enabled-apps.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.home-publisher136.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.home140-consent.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.layout.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.native-owner.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.native-rail.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.owner-revoke.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.standalone144-optin.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.standalone144-request.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.standalone144-result.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.standalone144-sb-lease.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist; /var/mobile/Library/Preferences/com.duoface.speedhud.lease176.chrome.plist; /var/mobile/Library/Preferences/com.duoface.speedhud.overlay163.plist; /var/mobile/Library/Preferences/com.duoface.speedhud.visibility.v1.plist
- URL: (không có)
- thẻ log: [DFHome136] [DFHome137] [DFHome141] [DFHome142] [DFHome165] [DFStandalone144] [DuoFaceDockOwner] [DuoFaceHomeABI] [DuoFaceMapOwner] [DuoFaceSpeed8]

### Chuỗi log có định dạng (18)
- /var/mobile/Library/Logs/DuoFaceGeometry119-%@.jsonl
- DuoFace: speed %@ km/h; limit %@ km/h
- [DFHome136] pid=%d %@

- [DFHome137] process=%@ pid=%d %@

- [DFHome141] time=%.3f pid=%d %@

- [DFHome142] %@

- [DFHome165] selected=%@ decision=%@ (icon visibility UNVERIFIED)

- [DFStandalone144] time=%.3f process=%@ stage=%@ %@

- [DuoFaceDockOwner] %@

- [DuoFaceDockOwner] getter-rejected %@
- [DuoFaceDockOwner] native-dock-restored hidden=%d
- [DuoFaceHomeABI] process=%@ pid=%d %@

- [DuoFaceMapOwner] log-open-failed errno=%d
- [DuoFaceSpeed8] %@

- [DuoFaceSpeed8] QA163 native owner attached process=%@ class=%@
- [DuoFaceSpeed8] viewer NO_FRESH_SAMPLE source=GOFA ttl=5s process=%@
- abi %c[%s %s] %@
- method=%c[%s %s] types=%s

### Class hệ thống/private đáng chú ý trong từ vựng tham chiếu (3)
DFHomeLaunch142, DFNative8SpeedHUDView, DFSpeedNativeOverlay163

## [TA] DFNativeDashboardBridgeQA.dylib
- Kích thước: 275520 byte; SHA256: a6878d0e35598d274759bfca5c9ea5d411473f6dddbfc3ce12606f7abb2a789d
- Thư viện nạp (11): libobjc.A.dylib, Foundation, CoreFoundation, UIKit, QuartzCore, libSystem.B.dylib, CoreGraphics, Frameworks, lib, Frameworks, lib
- Ký hiệu import C/ObjC: 0 (binary đã strip bảng ký hiệu)
- Từ vựng: 338 selector, 148 chuỗi C, 15 tên class tham chiếu

### Class định nghĩa (6) và toàn bộ method

**DFCPNativeBridgeQA** — 54 instance, 1 class
- instance: .cxx_destruct, ackLostSince, activeV1BCRootWithWindow:, capture:, currentRoot, currentWindow, deliverPacket:toRoot:, exhaustedYieldSession, expectedSourceFrame, lastImageTime, mirrorLayer, nativeDashboardRoot, owner, pointerDown, publisher, relay, remoteDividerActive, restoreYieldedSourceWindow:, savedSourceFrame, setAckLostSince:, setCurrentRoot:, setCurrentWindow:, setExhaustedYieldSession:, setExpectedSourceFrame:, setLastImageTime:, setMirrorLayer:, setOwner:, setPointerDown:, setPublisher:, setRelay:, setRemoteDividerActive:, setSavedSourceFrame:, setSidebarTrial:, setTapDown:, setTicks:, setTimer:, setWholeHostFullscreen:, setYieldSession:, setYieldedSourceWindow:, sidebarTrial, sourceYieldExperimentEnabled, start, stopPublisher, tapDown, tick, tickCarPlay, tickNativeDashboardSourceYield:, tickSpringBoard, ticks, timer, toggleWholeHostFullscreen, wholeHostFullscreen, yieldSession, yieldedSourceWindow
- class: shared

**DFNativeSidebarTrial** — 20 instance, 0 class
- instance: .cxx_destruct, active, beganAt, changedWindow, dealloc, exhaustedSession, expectedFrame, lastValidAckAt, leaseSession, originalFrame, setActive:, setBeganAt:, setChangedWindow:, setExhaustedSession:, setExpectedFrame:, setLastValidAckAt:, setLeaseSession:, setOriginalFrame:, stop, tickWithSurface:

**MTCPCommandRelay** — 13 instance, 0 class
- instance: .cxx_destruct, dealloc, handler, init, lastSequence, session, setHandler:, setLastSequence:, setSession:, setToken:, startForSession:handler:, stop, token

**MTCPDashboardOwner** — 33 instance, 0 class
- instance: .cxx_destruct, activeContentRect, applyHostFullscreen:, attachToDashboardRoot:, attached, contentRect, contentView, dashboardRoot, dealloc, detach, isHostFullscreen, nativeChromeModified, receiver, receiverSession, refresh, savedNativeBarFrame, savedNativeBarHidden, savedNativeBarWindow, savedNormalContentRect, savedNormalScreenRect, setAttached:, setContentRect:, setContentView:, setDashboardRoot:, setHostFullscreen:, setNativeChromeModified:, setReceiver:, setSavedNativeBarFrame:, setSavedNativeBarHidden:, setSavedNativeBarWindow:, setSavedNormalContentRect:, setSavedNormalScreenRect:, writeLiveReceiverAck:

**MTCPRemoteLayerProducer** — 15 instance, 0 class
- instance: .cxx_destruct, advertisedBounds, advertisedContextID, dealloc, invalidate, leaseTimer, publishLayer:normalizedContentBounds:, refreshLease:, remoteContext, session, setAdvertisedBounds:, setAdvertisedContextID:, setLeaseTimer:, setRemoteContext:, setSession:

**MTCPRemoteLayerReceiver** — 24 instance, 0 class
- instance: .cxx_destruct, checkLease:, commandSequence, connectWithOwnedContentView:, contextID, dealloc, disconnect, lastMoveAt, leaseTimer, nativeOwner, remoteLayer, sendPointer:phase:, session, setCommandSequence:, setContextID:, setLastMoveAt:, setLeaseTimer:, setNativeOwner:, setRemoteLayer:, setSession:, touchesBegan:withEvent:, touchesCancelled:withEvent:, touchesEnded:withEvent:, touchesMoved:withEvent:

### Chuỗi hạ tầng
- notifications: (không có)
- tên miền/tên Darwin com.*: com.duoface.mytweak.cp-command
- đường dẫn plist: /var/mobile/Library/Preferences/com.duoface.mytweak.carplay-bridge.plist; /var/mobile/Library/Preferences/com.duoface.mytweak.cp-command.plist; /var/mobile/Library/Preferences/com.duoface.mytweak.cp-host-fullscreen.plist; /var/mobile/Library/Preferences/com.duoface.mytweak.cp-receiver-ack.plist; /var/mobile/Library/Preferences/com.duoface.mytweak.cp-surface.plist; /var/mobile/Library/Preferences/com.duoface.mytweak.v1bc.plist
- URL: (không có)
- thẻ log: [DuoFaceNativeBridgeQA] [DuoFaceNativeGeometry] [DuoFaceNativeSidebar] [MyTweakCarPlayPrototype]

### Chuỗi log có định dạng (6)
- [DuoFaceNativeBridgeQA] %@ %@

- [DuoFaceNativeGeometry] enter normal=%@ full=%@ barHidden=%d
- [DuoFaceNativeGeometry] restore normal=%@ full=%@ barHidden=%d
- [DuoFaceNativeSidebar] %@ %@

- [MyTweakCarPlayPrototype] remote producer rejected %@
- [MyTweakCarPlayPrototype] remote receiver rejected %@

### Class hệ thống/private đáng chú ý trong từ vựng tham chiếu (6)
DFCPNativeBridgeQA, DFNativeSidebarTrial, MTCPCommandRelay, MTCPDashboardOwner, MTCPRemoteLayerProducer, MTCPRemoteLayerReceiver

## [TA] DFNativeMapPaneCoordinator.dylib
- Kích thước: 122912 byte; SHA256: 5709cff506cb8cea54b10681ad9c77a1bb202f080d1d324fd4ccfd0ea3b54df2
- Thư viện nạp (6): UIKit, Foundation, CoreGraphics, libobjc.A.dylib, libSystem.B.dylib, CoreFoundation
- Ký hiệu import C/ObjC: 0 (binary đã strip bảng ký hiệu)
- Từ vựng: 212 selector, 151 chuỗi C, 5 tên class tham chiếu

### Class định nghĩa (2) và toàn bộ method

**DFNativeMapPaneAdapter** — 31 instance, 1 class
- instance: .cxx_destruct, adoptNativeController:into:container:measuredArea:explicitlyAuthorized:error:, assignedContainer, assignedParent, isAttached, nativeOwner, oldAlpha, oldAutoresizing, oldFrame, oldHidden, oldParent, oldSafeInsets, oldSubviewIndex, oldSuperview, oldTransform, oldWindow, restoreOriginalOwnerWithError:, setAssignedContainer:, setAssignedParent:, setAttached:, setNativeOwner:, setOldAlpha:, setOldAutoresizing:, setOldFrame:, setOldHidden:, setOldParent:, setOldSafeInsets:, setOldSubviewIndex:, setOldSuperview:, setOldTransform:, setOldWindow:
- class: preflightNativeController:into:container:measuredArea:

**DFNativeMapPaneCoordinator** — 34 instance, 1 class
- instance: .cxx_destruct, adapter, autoRestoreAfterReconnectIfVerified, boundSession, dashboard, handle, handleCommand:, invalidFrameTicks, lastAutoSession, lastLeaseWrite, lastRequest, owner, pane, poll, refreshAdoptedNativeMapBounds, removePaneWhenSafe, reply:ok:reason:, request, restore:, setAdapter:, setBoundSession:, setDashboard:, setInvalidFrameTicks:, setLastAutoSession:, setLastLeaseWrite:, setLastRequest:, setOwner:, setPane:, setPoll:, setRequest:, setSlot:, slot, start, tick:
- class: shared

### Chuỗi hạ tầng
- notifications: (không có)
- tên miền/tên Darwin com.*: com.duoface.nativehost.map-pane.ack.v1
- đường dẫn plist: /var/mobile/Library/Preferences/com.duoface.nativehost.layout.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.map-pane.ack.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.map-pane.command.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.native-map-choice.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.native-map-lease.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.physical-panes.v1.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.workspace.v1.plist
- URL: (không có)
- thẻ log: [DuoFaceMapPane]

### Chuỗi log có định dạng (1)
- [DuoFaceMapPane] %@


### Class hệ thống/private đáng chú ý trong từ vựng tham chiếu (2)
DFNativeMapPaneAdapter, DFNativeMapPaneCoordinator

## [TA] DFV1APreflight.dylib
- Kích thước: 292160 byte; SHA256: a91a6f0badea1634a83434ec99b2fc117c8040f6dde3eff889710bed0c1350ac
- Thư viện nạp (11): libobjc.A.dylib, Foundation, CoreFoundation, UIKit, libSystem.B.dylib, CoreGraphics, CydiaSubstrate, Frameworks, lib, Frameworks, lib
- Ký hiệu import C/ObjC: 0 (binary đã strip bảng ký hiệu)
- Từ vựng: 483 selector, 180 chuỗi C, 30 tên class tham chiếu

### Class định nghĩa (12) và toàn bộ method

**MTAppInfo** — 5 instance, 0 class
- instance: .cxx_destruct, bundleID, displayName, setBundleID:, setDisplayName:

**MTAppLauncher** — 1 instance, 1 class
- instance: launchAppWithBundleID:error:
- class: sharedLauncher

**MTAppLibrary** — 0 instance, 1 class
- class: installedUserApps

**MTAppPickerViewController** — 15 instance, 0 class
- instance: .cxx_destruct, apps, closeTapped, delegate, setApps:, setDelegate:, setTableView:, setToolbar:, tableView, tableView:cellForRowAtIndexPath:, tableView:didSelectRowAtIndexPath:, tableView:numberOfRowsInSection:, toolbar, viewDidLayoutSubviews, viewDidLoad

**MTAppSession** — 7 instance, 0 class
- instance: .cxx_destruct, bundleID, displayName, hostedView, setBundleID:, setDisplayName:, setHostedView:

**MTAppSlotViewController** — 27 instance, 0 class
- instance: .cxx_destruct, clearContentKeepTitle, clearSlot, contentDoubleTapped, contentView, dealloc, delegate, pickButton, pickButtonTapped, placeholderLabel, sceneHostDidFail:, session, setContentView:, setDelegate:, setPickButton:, setPlaceholderLabel:, setSession:, setSlotIndex:, setTitleLabel:, setTopBar:, showLaunchError:, slotIndex, slotName, titleLabel, topBar, viewDidLayoutSubviews, viewDidLoad

**MTBridgeCoordinator** — 21 instance, 3 class
- instance: .cxx_destruct, attachToCarPlayDisplay:, attemptedForThisConnection, bridgeWindow, detach, hadDisplay, isCarPlayConnected, lastEnabled, observing, poll:, pollTimer, setAttemptedForThisConnection:, setBridgeWindow:, setCarPlayConnected:, setHadDisplay:, setLastEnabled:, setObserving:, setPollTimer:, start, stop, stopAndDisable
- class: setTrialEnabled:, sharedCoordinator, trialEnabled

**MTBridgeRootViewController** — 21 instance, 0 class
- instance: .cxx_destruct, appPicker:didSelectBundleID:displayName:, appPickerDidCancel:, chooseApp, closeTrial, makeButton:action:, menuButtons, pickerTargetSlot, presentAppPickerForSlot:, remoteDividerPhase:normalizedPoint:, setMenuButtons:, setPickerTargetSlot:, setSplitContainer:, slotDidDoubleTap:, slotDidRequestAppPicker:, splitContainer, swapApps, toggleSplit, toggleZoom, viewDidLayoutSubviews, viewDidLoad

**MTPreflight** — 4 instance, 2 class
- instance: screenChanged:, setStarted:, snapshot, started
- class: shared, startReadOnlyDiagnostics

**MTSceneHost** — 8 instance, 1 class
- instance: .cxx_destruct, didFinishSurface:, hostViewForBundleID:error:, init, live, releaseHostedView:, setLive:, stopAllHosts
- class: sharedHost

**MTSceneSurface** — 35 instance, 0 class
- instance: .cxx_destruct, appController, bundleID, didMoveToWindow, entity, failed:, findParentController, lastApplied, layoutScene, layoutSubviews, owner, parentController, pollScene:, ready, scene, sceneSettingsBefore, setAppController:, setBundleID:, setEntity:, setLastApplied:, setOwner:, setParentController:, setReady:, setScene:, setSceneSettingsBefore:, setStarted:, setStopped:, setTimer:, setTries:, start, started, stop, stopped, timer, tries

**MTSplitContainerViewController** — 20 instance, 0 class
- instance: .cxx_destruct, dividerHeld:, dividerPanned:, dividerView, fullscreenSlot, leftRatio, leftSlot, remoteDividerPhase:localPoint:, rightSlot, setDividerView:, setFullscreenSlot:, setLeftRatio:, setLeftSlot:, setRightSlot:, setSinglePaneMode:, singlePaneMode, swapSlots, toggleFullscreenForSlot:, viewDidLayoutSubviews, viewDidLoad

### Chuỗi hạ tầng
- notifications: (không có)
- tên miền/tên Darwin com.*: com.duoface.mytweak
- đường dẫn plist: /var/mobile/Library/Preferences/com.duoface.mytweak.v1bc.plist
- URL: (không có)
- thẻ log: [MyTweakScene] [MyTweakV1A] [MyTweakV1BC] [MyTweak]

### Chuỗi log có định dạng (7)
- [MyTweakScene] event=%@ bundle=%@ %@
- [MyTweakScene] event=scene-pending bundle=%@
- [MyTweakV1A] event=%@ %@
- [MyTweakV1BC] event=%@ %@
- [MyTweakV1BC] event=app-proxy-skipped type=%@
- [MyTweak] App picker loaded %lu apps
- [MyTweak] Slot %ld launch error: %@

### Class hệ thống/private đáng chú ý trong từ vựng tham chiếu (14)
MTAppInfo, MTAppLauncher, MTAppLibrary, MTAppPickerDelegate, MTAppPickerViewController, MTAppSession, MTAppSlotDelegate, MTAppSlotViewController, MTBridgeCoordinator, MTBridgeRootViewController, MTPreflight, MTSceneHost, MTSceneSurface, MTSplitContainerViewController

## [TA] DF155GeneralAppStateRelay.dylib
- Kích thước: 162768 byte; SHA256: b859505cfed800e4e0e6cf3d0c1209233e4346d0bb37ea1197ac46298ea3c037
- Thư viện nạp (6): UIKit, Foundation, CoreGraphics, libobjc.A.dylib, libSystem.B.dylib, CoreFoundation
- Ký hiệu import C/ObjC: 0 (binary đã strip bảng ký hiệu)
- Từ vựng: 161 selector, 302 chuỗi C, 5 tên class tham chiếu

### Class định nghĩa (2) và toàn bộ method

**DF154GeneralAppStateRelay** — 28 instance, 0 class
- instance: .cxx_destruct, applying, bundle, df176KeyboardShown:, df178CaptureKeyboard:late:, df179KeyboardHidden:, expiry, lastAckPhase, lastKbDiag176, lastKbDid176, newest, originals, ownedScene, postAck:count:, receive:, reconcile, restore:, setApplying:, setBundle:, setExpiry:, setLastAckPhase:, setLastKbDiag176:, setLastKbDid176:, setNewest:, setOriginals:, setOwnedScene:, setState:, state

**DF154WindowOriginal** — 7 instance, 0 class
- instance: .cxx_destruct, bounds, frame, scene, setBounds:, setFrame:, setScene:

### Chuỗi hạ tầng
- notifications: v16@?0@"NSNotification"8
- tên miền/tên Darwin com.*: com.duoface.apptouch177.wake; com.duoface.independent.app-state.v154; com.duoface.ipc.v156.%@.%@; com.duoface.ipc.v176.kbdiag; com.duoface.ipc.v177.apptouch; com.duoface.kbdiag176.wake
- đường dẫn plist: /var/mobile/Library/Preferences/com.duoface.nativehost.qa176.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.qa177.plist
- URL: (không có)
- thẻ log: [DF154AppState] [DF156IPC] [DF176KBDiag] [DF179KBfit]

### Chuỗi log có định dạng (8)
- [DF154AppState] bundle=%@ owner=%@ scene=%@ adjusted=%lu size=%@
- [DF154AppState] bundle=%@ registered=exact-owned-scene-only enabled=%d
- [DF154AppState] bundle=%@ restore=%@ windows=%lu
- [DF154AppState] bundle=%@ transport-unavailable; no UIKit changes
- [DF156IPC] transport-write-failed bundle=%@ ack=%d
- [DF176KBDiag] bundle=%@ kb=%@ frame=%@ keyplane=%@ inputMode=%@ hw=%@/%@
- [DF176KBDiag] failed %@
- [DF179KBfit] restore failed %@

### Class hệ thống/private đáng chú ý trong từ vựng tham chiếu (2)
DF154GeneralAppStateRelay, DF154WindowOriginal

## [TA] DFGofaSpeedSource162.dylib
- Kích thước: 174000 byte; SHA256: 1ad9c288d469f91d87426b66a515597e49686743c3c0622c5b41d99d3cc31e7e
- Thư viện nạp (9): UIKit, Foundation, CoreLocation, CarPlay, libc++.1.dylib, libobjc.A.dylib, libSystem.B.dylib, CoreFoundation, libswiftCore.dylib
- Ký hiệu import C/ObjC: 0 (binary đã strip bảng ký hiệu)
- Từ vựng: 152 selector, 119 chuỗi C, 4 tên class tham chiếu

### Class định nghĩa (2) và toàn bộ method

**DFGofaDecoder172** — 1 instance, 2 class
- instance: init
- class: decodeAlertPointsWithNotificationName:userInfo:, decodeSpeedBoardWithUserInfo:

**DFGofaSpeedSource162** — 15 instance, 1 class
- instance: .cxx_destruct, applicationActivated:, checkAuthorization:, initializedAt, locationManager:didFailWithError:, locationManager:didUpdateLocations:, locationManagerDidChangeAuthorization:, manager, retryTimer, setInitializedAt:, setManager:, setRetryTimer:, setStarted:, start, started
- class: shared

### Chuỗi hạ tầng
- notifications: v16@?0@"NSNotification"8
- tên miền/tên Darwin com.*: com.duoface.gofa.decoder172; com.duoface.gofa.probe166; com.duoface.speedhud.v1.gofa; com.duoface.speedhud.visibility.v1.changed; com.duoface.trafficnav.v1.gofa.discovery; com.duoface.trafficnav.v2.gofa.cpnavigation; com.duoface.trafficnav.v2.gofa.decoder
- đường dẫn plist: /System/Library/CoreServices/SystemVersion.plist; /var/mobile/Library/Preferences/com.duoface.speedhud.visibility.v1.plist
- URL: (không có)
- thẻ log: [DuoFaceDecoder172] [DuoFaceSpeed8]

### Chuỗi log có định dạng (10)
- [DuoFaceDecoder172] alerts event=%lu type=%@ kind=%lu accepted=%lu rejected=%lu
- [DuoFaceDecoder172] speed type=%@ kind=%lu present=0x%lx rejected=0x%lx userSpeed=%@ speed=%@ currentAllowSpeed=%@ limit=%@
- [DuoFaceGOFAProbe QA171] %@
- [DuoFaceSpeed8] GOFA GPS sample REJECTED fresh=%d speedValid=%d accuracyValid=%d
- [DuoFaceSpeed8] GOFA GPS source status auth=%ld services=%d active=%d
- [DuoFaceSpeed8] GOFA GPS source unavailable: %@
- [DuoFaceSpeed8] QA165 GOFA native CoreLocation delegate OBSERVED hooked=1 class=%@
- [DuoFaceSpeed8] QA165 GOFA native location CALLBACK fresh=%d accuracyOK=%d speedOK=%d
- [DuoFaceSpeed8] QA170 fallback real GOFA GPS started; passiveSampleMissing=%d
- [DuoFaceSpeed8] QA170 fallback stopped: permission=%d nativeHealthy=%d

### Class hệ thống/private đáng chú ý trong từ vựng tham chiếu (1)
DFGofaSpeedSource162

## [TA] DFGofaMapResize141.dylib
- Kích thước: 77280 byte; SHA256: 2c2162a18aaf835f55541904f5bc3c82795bb4f5147a599c4cae79930b16a5da
- Thư viện nạp (6): UIKit, Foundation, CoreGraphics, libobjc.A.dylib, libSystem.B.dylib, CoreFoundation
- Ký hiệu import C/ObjC: 0 (binary đã strip bảng ký hiệu)
- Từ vựng: 86 selector, 56 chuỗi C, 2 tên class tham chiếu

### Class định nghĩa (1) và toàn bộ method

**DFGofaMapResize141** — 13 instance, 0 class
- instance: .cxx_destruct, expiry, lease, newest, receive:, repair:state:, restoreMasks, savedMasks, setExpiry:, setLease:, setNewest:, setSavedMasks:, snapshot:

### Chuỗi hạ tầng
- notifications: NSDistributedNotificationCenter
- tên miền/tên Darwin com.*: com.duoface.gofa.layout-ack.v140; com.duoface.gofa.layout-state.v140
- đường dẫn plist: (không có)
- URL: (không có)
- thẻ log: (không có)

### Class hệ thống/private đáng chú ý trong từ vựng tham chiếu (1)
DFGofaMapResize141

## [TA] DFYouTubeOrientationRelay.dylib
- Kích thước: 120672 byte; SHA256: 04d7993e3ae6c316bba97e06c308e365779b15e652c69103b74c4a0882ac9c97
- Thư viện nạp (6): UIKit, Foundation, CoreGraphics, libobjc.A.dylib, libSystem.B.dylib, CoreFoundation
- Ký hiệu import C/ObjC: 0 (binary đã strip bảng ký hiệu)
- Từ vựng: 144 selector, 86 chuỗi C, 4 tên class tham chiếu

### Class định nghĩa (2) và toàn bộ method

**DFYTWindowSnapshot** — 6 instance, 0 class
- instance: bounds, frame, orientation, setBounds:, setFrame:, setOrientation:

**DFYouTubeOrientationRelay** — 32 instance, 0 class
- instance: .cxx_destruct, apply, applying, df175ResetRestoringSnapshots:, expiryTimer, frameClock, frameClockScene, frameClockTick:, frameClockTicks, lastFrameClockReportAt, lastGeometryCheckKey, newestStamp, receive:, reportFrameClockIfDue, request:, reset, scene, setApplying:, setExpiryTimer:, setFrameClock:, setFrameClockScene:, setFrameClockTicks:, setLastFrameClockReportAt:, setLastGeometryCheckKey:, setNewestStamp:, setScene:, setSnapshots:, setState:, snapshots, startFrameClockObservation:, state, windowVisible:

### Chuỗi hạ tầng
- notifications: NSDistributedNotificationCenter
- tên miền/tên Darwin com.*: com.duoface.apptouch177.wake; com.duoface.ipc.v177.apptouch; com.duoface.youtube.host-ack.v1; com.duoface.youtube.host-request.v1; com.duoface.youtube.host-state.v1
- đường dẫn plist: /var/mobile/Library/Preferences/com.duoface.nativehost.qa175.plist; /var/mobile/Library/Preferences/com.duoface.nativehost.qa177.plist
- URL: (không có)
- thẻ log: [DuoFaceYouTube]

### Chuỗi log có định dạng (3)
- [DuoFaceYouTube] original-ABI-backed first-party hooks installed %lu
- [DuoFaceYouTube] reflow failed %@
- [DuoFaceYouTube] restore failed %@

### Class hệ thống/private đáng chú ý trong từ vựng tham chiếu (2)
DFYTWindowSnapshot, DFYouTubeOrientationRelay

## [TA] DFFirstPartyAdmission.dylib
- Kích thước: 187024 byte; SHA256: dac57b1322aa6085596e8030b91ac28d385723a3bf67b83e7d60d058ca9ab2d5
- Thư viện nạp (8): libobjc.A.dylib, Foundation, CoreFoundation, libSystem.B.dylib, Frameworks, lib, Frameworks, lib
- Ký hiệu import C/ObjC: 0 (binary đã strip bảng ký hiệu)
- Từ vựng: 34 selector, 104 chuỗi C, 0 tên class tham chiếu

### Class định nghĩa (0) và toàn bộ method

### Chuỗi hạ tầng
- notifications: (không có)
- tên miền/tên Darwin com.*: com.duoface.admission-trace.preflight; com.duoface.firstparty-admission.refresh; com.duoface.firstparty-admission.roster-readonly; com.duoface.native.scenehost
- đường dẫn plist: /var/mobile/Library/Preferences/com.duoface.admission-trace.request.plist; /var/mobile/Library/Preferences/com.duoface.admission-trace.status.plist; /var/mobile/Library/Preferences/com.duoface.firstparty-admission.plist; /var/mobile/Library/Preferences/com.duoface.firstparty-roster.request.plist
- URL: (không có)
- thẻ log: [DFTrace] [DuoFaceRosterSB]

### Chuỗi log có định dạng (2)
- [DFAdmission/CarPlay] %@

- [DFTrace] wall=%.3f uptime=%.3f pid=%d %@
