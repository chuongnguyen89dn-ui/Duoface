# Original Native12 single-slot picker vs SEPARATE iPhone app-manager

Original DEB SHA verified. Original machine IMPs/selector references, no runtime execution.

**CarPlay appSelected:** 1 tapped bundle selected for 1 requested slot, not multi-select.
**iPhone CBAppManager:** enableAll*/disableAll selectors exist, but do not attribute them to CarPlay app picker.
**iPhone CBAppsManagerViewController.showActionMenu:** exists; actual UI prompts/actions require method callback decoding or device evidence.
**Do NOT assert that the CarPlay picker has a choose-all function.**

## DuoFaceUI / CBAppsManagerViewController.showActionMenu @ 0x100013604
Instructions: 231
Selector/CFString references:
    100013644:	ldr	x21, [x8, #0x3c8] ; Objc selector ref: localizedStringForKey:
    100013648:	adr	x2, #882720 ; Objc cfstring ref: @"ACTION_MENU"
    100013668:	ldr	x1, [x8, #0x438] ; Objc selector ref: alertControllerWithTitle:message:preferredStyle:
    1000136a0:	adr	x2, #882664 ; Objc cfstring ref: @"ROW_ENABLE_RECOMMENDED"
    1000136f0:	ldr	x22, [x8, #0x440] ; Objc selector ref: actionWithTitle:style:handler:
    10001371c:	ldr	x23, [x8, #0x448] ; Objc selector ref: addAction:
    10001374c:	adr	x2, #882524 ; Objc cfstring ref: @"ROW_ENABLE_ALL"
    1000137d4:	adr	x2, #882420 ; Objc cfstring ref: @"ROW_DISABLE_ALL"
    10001385c:	adr	x2, #880300 ; Objc cfstring ref: @"CANCEL"
    1000138c0:	ldr	x21, [x8, #0x7b8] ; Objc selector ref: popoverPresentationController
    1000138e8:	ldr	x1, [x8, #0x758] ; Objc selector ref: navigationItem
    100013904:	ldr	x1, [x8, #0xb10] ; Objc selector ref: rightBarButtonItem
    100013934:	ldr	x1, [x8, #0xb18] ; Objc selector ref: setBarButtonItem:
    10001395c:	ldr	x1, [x8, #0x450] ; Objc selector ref: presentViewController:animated:completion:

## DuoFaceUI / CBAppsManagerViewController.appSwitchToggled: @ 0x100013ab4
Instructions: 61
Selector/CFString references:
    100013adc:	ldr	x1, [x8, #0x320] ; Objc selector ref: class
    100013aec:	ldr	x1, [x8, #0x360] ; Objc selector ref: isKindOfClass:
    100013b00:	ldr	x20, [x8, #0x5d0] ; Objc selector ref: bundleIdentifier
    100013b30:	ldr	x1, [x8, #0x380] ; Objc selector ref: sharedInstance
    100013b60:	ldr	x1, [x8, #0x780] ; Objc selector ref: isOn
    100013b74:	ldr	x1, [x8, #0xb20] ; Objc selector ref: setApp:enabled:

## DuoFaceUI / CBAppManager.enableAllApps @ 0x100009690
Instructions: 100
Selector/CFString references:
    1000096dc:	ldr	x1, [x8, #0x4d8] ; Objc selector ref: countByEnumeratingWithState:objects:count:
    10000970c:	ldr	x23, [x8, #0x5d0] ; Objc selector ref: bundleIdentifier
    1000097d8:	ldr	x1, [x8, #0x5f8] ; Objc selector ref: savePreferences

## DuoFaceUI / CBAppManager.disableAllApps @ 0x100009f1c
Instructions: 80
Selector/CFString references:
    100009f58:	ldr	x1, [x8, #0x580] ; Objc selector ref: removeAllObjects
    100009f7c:	ldr	x21, [x8, #0x4d8] ; Objc selector ref: countByEnumeratingWithState:objects:count:
    10000a014:	ldr	x1, [x8, #0x5f8] ; Objc selector ref: savePreferences

## DuoFaceUI / CBAppManager.enableAllUserApps @ 0x100009820
Instructions: 100
Selector/CFString references:
    10000986c:	ldr	x1, [x8, #0x4d8] ; Objc selector ref: countByEnumeratingWithState:objects:count:
    10000989c:	ldr	x23, [x8, #0x5d0] ; Objc selector ref: bundleIdentifier
    100009968:	ldr	x1, [x8, #0x5f8] ; Objc selector ref: savePreferences

## DuoFaceUI / CBAppManager.enableAllNavigationApps @ 0x100009b7c
Instructions: 116
Selector/CFString references:
    100009bcc:	ldr	x1, [x8, #0x4d8] ; Objc selector ref: countByEnumeratingWithState:objects:count:
    100009bfc:	ldr	x23, [x8, #0x5d0] ; Objc selector ref: bundleIdentifier
    100009c18:	ldr	x26, [x8, #0x5e0] ; Objc selector ref: setIsEnabled:
    100009d04:	ldr	x1, [x8, #0x5f8] ; Objc selector ref: savePreferences

## DuoFaceUI / CBAppManager.setApp:enabled: @ 0x10000960c
Instructions: 33
Selector/CFString references:
    100009638:	add	x8, x8, #0x5e8 ; Objc selector ref: addObject:
    100009644:	add	x9, x9, #0x5f0 ; Objc selector ref: removeObject:
    100009660:	ldr	x1, [x8, #0x588] ; Objc selector ref: syncEnabledFlags
    100009670:	ldr	x1, [x8, #0x5f8] ; Objc selector ref: savePreferences

## DuoFaceDashboard.dylib / CBMultitaskingOverlayView.appSelected: @ 0xa9ea8
Instructions: 402
Selector/CFString references:
    a9ed0:	ldr	x1, [x8, #0x200] ; Objc selector ref: tag
    a9ef4:	ldr	x22, [x8, #0x620] ; Objc selector ref: count
    a9f10:	ldr	x25, [x8, #0x8b8] ; Objc selector ref: objectAtIndexedSubscript:
    a9f30:	ldr	x1, [x8, #0x560] ; Objc selector ref: objectForKeyedSubscript:
    a9f38:	add	x2, x2, #0xd28 ; Objc cfstring ref: @"bundleIdentifier"
    a9f94:	ldr	x1, [x8, #0xbb8] ; Objc selector ref: array
    aa004:	ldr	x26, [x8, #0x448] ; Objc selector ref: isEqualToString:
    aa07c:	ldr	x1, [x8, #0x518] ; Objc selector ref: sharedInstance
    aa0c0:	ldr	x1, [x8, #0x558] ; Objc selector ref: dictionaryWithContentsOfFile:
    aa0f4:	ldr	x1, [x8, #0x590] ; Objc selector ref: dictionary
    aa148:	ldr	x27, [x8, #0x208] ; Objc selector ref: setObject:atIndexedSubscript:
    aa178:	ldr	x27, [x8, #0x210] ; Objc selector ref: saveSlotIndex:bid:toSettings:prefs:
    aa1c4:	ldr	x1, [x8, #0x208] ; Objc selector ref: setObject:atIndexedSubscript:
    aa1dc:	ldr	x1, [x8, #0x210] ; Objc selector ref: saveSlotIndex:bid:toSettings:prefs:
    aa210:	ldr	x1, [x8, #0x5a0] ; Objc selector ref: writeToFile:atomically:
    aa28c:	ldr	x1, [x8, #0x218] ; Objc selector ref: isUIAppBridging
    aa29c:	ldr	x26, [x8, #0xf20] ; Objc selector ref: currentApp
    aa2c4:	ldr	x1, [x8, #0x610] ; Objc selector ref: class
    aa2d4:	ldr	x1, [x8, #0x618] ; Objc selector ref: isKindOfClass:
    aa30c:	ldr	x1, [x8, #0x220] ; Objc selector ref: splitPreset
    aa330:	ldr	x1, [x8, #0x228] ; Objc selector ref: swapSlot:withSlot:
    aa354:	ldr	x23, [x8, #0x238] ; Objc selector ref: onMultiSplitSelected
    aa3a0:	ldr	x1, [x8, #0x818] ; Objc selector ref: copy
    aa40c:	ldr	x1, [x8, #0xfe0] ; Objc selector ref: dismissOverlay
    aa438:	ldr	x1, [x8, #0x230] ; Objc selector ref: replaceAppInSlot:withBundleIdentifier:
    aa450:	ldr	x1, [x8, #0xfe0] ; Objc selector ref: dismissOverlay

## DuoFaceDashboard.dylib / CBMultitaskingOverlayView.saveSlotIndex:bid:toSettings:prefs: @ 0xa9d1c
Instructions: 99
Selector/CFString references:
    a9d80:	ldr	x1, [x8, #0x1d0] ; Objc selector ref: setSplitApp1:
    a9d94:	ldr	x1, [x8, #0x1d8] ; Objc selector ref: setSplitLeftBundleID:
    a9da8:	ldr	x22, [x8, #0x598] ; Objc selector ref: setObject:forKeyedSubscript:
    a9db0:	add	x3, x3, #0x248 ; Objc cfstring ref: @"splitApp1"
    a9dc8:	add	x3, x3, #0x1c8 ; Objc cfstring ref: @"splitLeftBundleID"
    a9dd4:	ldr	x1, [x8, #0x1e0] ; Objc selector ref: setSplitApp2:
    a9de8:	ldr	x1, [x8, #0x1e8] ; Objc selector ref: setSplitRightBundleID:
    a9dfc:	ldr	x22, [x8, #0x598] ; Objc selector ref: setObject:forKeyedSubscript:
    a9e04:	add	x3, x3, #0x268 ; Objc cfstring ref: @"splitApp2"
    a9e1c:	add	x3, x3, #0x1e8 ; Objc cfstring ref: @"splitRightBundleID"
    a9e30:	ldr	x1, [x8, #0x1f0] ; Objc selector ref: setSplitApp3:
    a9e44:	ldr	x1, [x8, #0x598] ; Objc selector ref: setObject:forKeyedSubscript:
    a9e4c:	add	x3, x3, #0x288 ; Objc cfstring ref: @"splitApp3"
    a9e58:	ldr	x1, [x8, #0x1f8] ; Objc selector ref: setSplitApp4:
    a9e6c:	ldr	x1, [x8, #0x598] ; Objc selector ref: setObject:forKeyedSubscript:
    a9e74:	add	x3, x3, #0x2a8 ; Objc cfstring ref: @"splitApp4"

## DuoFaceDashboard.dylib / CBMultitaskingOverlayView.showAppPickerForSlot:parentView: @ 0xaa800
Instructions: 288
Selector/CFString references:
    aa84c:	ldr	x24, [x8, #0x518] ; Objc selector ref: sharedInstance
    aa878:	ldr	x1, [x8, #0x528] ; Objc selector ref: reloadLanguage
    aa8c0:	ldr	x1, [x8, #0x520] ; Objc selector ref: reload
    aa8cc:	ldr	x23, [x8, #0x220] ; Objc selector ref: splitPreset
    aa908:	ldr	x1, [x8, #0x250] ; Objc selector ref: splitMode
    aa92c:	ldr	x1, [x8, #0xf58] ; Objc selector ref: splitRatio
    aa954:	ldr	x1, [x8, #0x258] ; Objc selector ref: splitApp1
    aa970:	add	x24, x24, #0x288 ; Objc cfstring ref: @""
    aa988:	ldr	x1, [x8, #0x260] ; Objc selector ref: splitLeftBundleID
    aa9b8:	ldr	x1, [x8, #0x268] ; Objc selector ref: splitApp2
    aa9e4:	ldr	x1, [x8, #0x270] ; Objc selector ref: splitRightBundleID
    aaa10:	ldr	x1, [x8, #0x278] ; Objc selector ref: splitApp3
    aaa38:	ldr	x1, [x8, #0x280] ; Objc selector ref: splitApp4
    aaa68:	ldr	x1, [x8, #0x550] ; Objc selector ref: arrayWithObjects:count:
    aaa88:	ldr	x1, [x8, #0xfd8] ; Objc selector ref: arrayWithArray:
    aab00:	ldr	x1, [x8, #0xfe8] ; Objc selector ref: loadInstalledApps
    aab10:	ldr	x1, [x8, #0x9b0] ; Objc selector ref: bounds
    aab20:	ldr	x1, [x8, #0xa10] ; Objc selector ref: setFrame:
    aab30:	ldr	x1, [x8, #0xa80] ; Objc selector ref: addSubview:
    aab44:	ldr	x1, [x8, #0x120] ; Objc selector ref: bringSubviewToFront:
    aab60:	ldr	x1, [x8, #0x988] ; Objc selector ref: setAlpha:
    aab74:	ldr	x1, [x8, #0x980] ; Objc selector ref: setHidden:
    aabb8:	ldr	x1, [x8, #0xe30] ; Objc selector ref: setTransform:
    aabc8:	ldr	x1, [x8, #0xef0] ; Objc selector ref: layoutSubviews
    aac10:	ldr	x1, [x8, #0xf48] ; Objc selector ref: animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:

## DuoFaceDashboard.dylib / CBMultitaskingOverlayView.addMoreAppsTapped: @ 0xa7f20
Instructions: 991
Selector/CFString references:
    a7fd4:	ldr	x1, [x8, #0xb30] ; Objc selector ref: animateWithDuration:animations:completion:
    a7ff8:	add	x0, x0, #0xfa8 ; Objc cfstring ref: @"[DuoFaceSB] UI addMoreAppsTapped -> presenting custom frosted alert modal"
    a8004:	ldr	x1, [x8, #0x188] ; Objc selector ref: viewWithTag:
    a8030:	ldr	x21, [x8, #0x9b0] ; Objc selector ref: bounds
    a8084:	ldr	x1, [x8, #0x9b8] ; Objc selector ref: initWithFrame:
    a809c:	ldr	x22, [x8, #0x100] ; Objc selector ref: setTag:
    a80c0:	ldr	x1, [x8, #0x9d0] ; Objc selector ref: clearColor
    a80dc:	ldr	x28, [x8, #0x9d8] ; Objc selector ref: setBackgroundColor:
    a8100:	ldr	x23, [x8, #0xdc0] ; Objc selector ref: setAutoresizingMask:
    a814c:	ldr	x1, [x8, #0xa38] ; Objc selector ref: colorWithWhite:alpha:
    a81ac:	ldr	x3, [x8, #0x190] ; Objc selector ref: dismissCustomAlert:
    a81b8:	ldr	x1, [x8, #0x9f0] ; Objc selector ref: initWithTarget:action:
    a81d0:	ldr	x1, [x8, #0x9f8] ; Objc selector ref: addGestureRecognizer:
    a81e0:	ldr	x1, [x8, #0xa80] ; Objc selector ref: addSubview:
    a8290:	ldr	x1, [x8, #0xdb8] ; Objc selector ref: blackColor
    a82ac:	ldr	x22, [x8, #0xa40] ; Objc selector ref: CGColor
    a82c0:	ldr	x28, [x8, #0xa18] ; Objc selector ref: layer
    a82e0:	ldr	x1, [x8, #0xe00] ; Objc selector ref: setShadowColor:
    a8318:	ldr	x1, [x8, #0xe18] ; Objc selector ref: setShadowOpacity:
    a8348:	ldr	x1, [x8, #0xe10] ; Objc selector ref: setShadowRadius:
    a837c:	ldr	x1, [x8, #0xe08] ; Objc selector ref: setShadowOffset:
    a83b0:	ldr	x25, [x8, #0xa28] ; Objc selector ref: setMasksToBounds:
    a83d8:	ldr	x1, [x8, #0xa00] ; Objc selector ref: effectWithStyle:
    a8404:	ldr	x1, [x8, #0xa08] ; Objc selector ref: initWithEffect:
    a8428:	ldr	x1, [x8, #0xa10] ; Objc selector ref: setFrame:
    a8454:	ldr	x1, [x8, #0xa20] ; Objc selector ref: setCornerRadius:
    a8498:	ldr	x1, [x8, #0xe88] ; Objc selector ref: setCornerCurve:
    a84fc:	ldr	x1, [x8, #0xa30] ; Objc selector ref: setBorderWidth:
    a8568:	ldr	x1, [x8, #0xa48] ; Objc selector ref: setBorderColor:
    a8590:	ldr	x20, [x8, #0xb68] ; Objc selector ref: colorWithRed:green:blue:alpha:
    a85d0:	ldr	x22, [x8, #0xa78] ; Objc selector ref: contentView
    a8640:	ldr	x1, [x8, #0x5a8] ; Objc selector ref: localizedStringForKey:
    a864c:	add	x2, x2, #0x228 ; Objc cfstring ref: @"ADD_MORE_APPS_ALERT_TITLE"
    a867c:	ldr	x1, [x8, #0xa88] ; Objc selector ref: systemFontOfSize:weight:
    a86b4:	ldr	x1, [x8, #0x548] ; Objc selector ref: dictionaryWithObjects:forKeys:count:
    a86d8:	ldr	x1, [x8, #0x198] ; Objc selector ref: sizeWithAttributes:
    a877c:	ldr	x1, [x8, #0xec8] ; Objc selector ref: configurationWithPointSize:weight:
    a87a4:	ldr	x1, [x8, #0xed0] ; Objc selector ref: systemImageNamed:withConfiguration:
    a87ac:	add	x2, x2, #0xfc8 ; Objc cfstring ref: @"iphone.and.arrow.forward"
    a87c8:	ldr	x1, [x8, #0xa58] ; Objc selector ref: setImage:
    a881c:	ldr	x1, [x8, #0xa68] ; Objc selector ref: setTintColor:
    a883c:	ldr	x1, [x8, #0xa70] ; Objc selector ref: setContentMode:
    a88a0:	ldr	x20, [x8, #0xaa8] ; Objc selector ref: setText:
    a88b4:	ldr	x24, [x8, #0xa90] ; Objc selector ref: setFont:
    a88d4:	ldr	x1, [x8, #0xa98] ; Objc selector ref: whiteColor
    a88f0:	ldr	x22, [x8, #0xaa0] ; Objc selector ref: setTextColor:
    a8910:	ldr	x21, [x8, #0x98] ; Objc selector ref: setTextAlignment:
    a8928:	ldr	x1, [x8, #0x38] ; Objc selector ref: setAdjustsFontSizeToFitWidth:
    a893c:	ldr	x1, [x8, #0x40] ; Objc selector ref: setMinimumScaleFactor:
    a89a8:	add	x2, x2, #0x268 ; Objc cfstring ref: @"ADD_MORE_APPS_ALERT_MSG"
    a8a70:	ldr	x1, [x8, #0xab0] ; Objc selector ref: setNumberOfLines:
    a8a9c:	ldr	x1, [x8, #0xe90] ; Objc selector ref: buttonWithType:
    a8bc4:	add	x2, x2, #0x2a8 ; Objc cfstring ref: @"ADD_MORE_APPS_ALERT_OK"
    a8be0:	ldr	x1, [x8, #0x50] ; Objc selector ref: setTitle:forState:
    a8c18:	ldr	x1, [x8, #0x60] ; Objc selector ref: setTitleColor:forState:
    a8c5c:	ldr	x1, [x8, #0x68] ; Objc selector ref: titleLabel
    a8c94:	ldr	x1, [x8, #0xeb0] ; Objc selector ref: addTarget:action:forControlEvents:
    a8cf0:	ldr	x1, [x8, #0x988] ; Objc selector ref: setAlpha:
    a8d28:	ldr	x1, [x8, #0xe30] ; Objc selector ref: setTransform:
    a8d6c:	ldr	x20, [x8, #0xf48] ; Objc selector ref: animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:

## DuoFaceDashboard.dylib / CBMultitaskingOverlayView.loadInstalledApps @ 0xa0c48
Instructions: 595
Selector/CFString references:
    a0c8c:	ldr	x1, [x8, #0xbb8] ; Objc selector ref: array
    a0cac:	ldr	x1, [x8, #0x518] ; Objc selector ref: sharedInstance
    a0cc4:	ldr	x1, [x8, #0x520] ; Objc selector ref: reload
    a0cd0:	ldr	x1, [x8, #0xff8] ; Objc selector ref: bridgedApps
    a0cf0:	ldr	x1, [x8, #0x620] ; Objc selector ref: count
    a0d28:	ldr	x1, [x8, #0x610] ; Objc selector ref: class
    a0d40:	ldr	x1, [x8, #0xb80] ; Objc selector ref: set
    a0d6c:	ldr	x20, [x8, #0x940] ; Objc selector ref: defaultWorkspace
    a0dac:	ldr	x19, [x8, #0x948] ; Objc selector ref: allInstalledApplications
    a0dc8:	ldr	x25, [x8, #0xfc8] ; Objc selector ref: performSelector:
    a0e30:	ldr	x21, [x8, #0x958] ; Objc selector ref: applicationIdentifier
    a0e4c:	ldr	x8, [x8, #0x950] ; Objc selector ref: localizedName
    a0e58:	ldr	x8, [x8] ; Objc selector ref: itemName
    a0e64:	ldr	x9, [x8, #0x568] ; Objc selector ref: length
    a0e6c:	ldr	x10, [x8, #0x8] ; Objc selector ref: _applicationIconImageForBundleIdentifier:format:scale:
    a0e74:	ldr	x8, [x8, #0xa50] ; Objc selector ref: systemImageNamed:
    a0e80:	ldr	x8, [x8, #0x10] ; Objc selector ref: numberWithInteger:
    a0e8c:	ldr	x8, [x8, #0x548] ; Objc selector ref: dictionaryWithObjects:forKeys:count:
    a0e98:	ldr	x8, [x8, #0xbe8] ; Objc selector ref: addObject:
    a1048:	add	x8, x8, #0xd28 ; Objc cfstring ref: @"bundleIdentifier"
    a1054:	add	x8, x8, #0xda8 ; Objc cfstring ref: @"displayName"
    a1068:	add	x8, x8, #0xdc8 ; Objc cfstring ref: @"icon"
    a1090:	add	x2, x2, #0xde8 ; Objc cfstring ref: @"app.fill"
    a10b4:	add	x8, x8, #0xe08 ; Objc cfstring ref: @"categoryRank"
    a1200:	ldr	x27, [x8, #0x5c8] ; Objc selector ref: containsObject:
    a1208:	ldr	x26, [x8, #0x8] ; Objc selector ref: _applicationIconImageForBundleIdentifier:format:scale:
    a1210:	ldr	x9, [x8, #0x5d8] ; Objc selector ref: respondsToSelector:
    a1224:	ldr	x9, [x8, #0x18] ; Objc selector ref: lastObject
    a1238:	ldr	x8, [x8, #0xa50] ; Objc selector ref: systemImageNamed:
    a1244:	ldr	x9, [x8, #0x10] ; Objc selector ref: numberWithInteger:
    a124c:	ldr	x8, [x8, #0x548] ; Objc selector ref: dictionaryWithObjects:forKeys:count:
    a1258:	ldr	x8, [x8, #0xbe8] ; Objc selector ref: addObject:
    a12fc:	add	x2, x2, #0xe28 ; Objc cfstring ref: @"."
    a1388:	add	x9, x8, #0xd28 ; Objc cfstring ref: @"bundleIdentifier"
    a1390:	add	x8, x8, #0xda8 ; Objc cfstring ref: @"displayName"
    a13a0:	add	x8, x8, #0xdc8 ; Objc cfstring ref: @"icon"
    a13c8:	add	x2, x2, #0xde8 ; Objc cfstring ref: @"app.fill"
    a13ec:	add	x8, x8, #0xe08 ; Objc cfstring ref: @"categoryRank"
    a14c8:	ldr	x1, [x8, #0x30] ; Objc selector ref: sortUsingComparator:
    a14e4:	ldr	x1, [x8, #0x818] ; Objc selector ref: copy

