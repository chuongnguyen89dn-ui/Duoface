# DuoNavi 1.0.4 — read-only original UI method/call-chain audit

Original DEB SHA256: \`f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd\`.
Original Dashboard SHA256: \`44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15\`.

**Static metadata/assembly only.** Calls in other branches, objc runtime dispatch, actual event order and Native12 matching are **not** established by this output.

## CBWindow::createWindows — 0xb173c
Instructions sampled: 586 to 0xb2064.

- \`carPlayWindowScene\`
- \`+[CBWindow carPlayWindowScene]\`
- \`carPlayUIScreen\`
- \`-[x0 carPlayUIScreen]\`
- \`screen\`
- \`-[x0 screen]\`
- \`carPlayCADisplay\`
- \`-[x0 carPlayCADisplay]\`
- \`displayConfiguration\`
- \`-[x0 displayConfiguration]\`
- \`_FBSScene\`
- \`-[x0 _FBSScene]\`
- \`performSelector:\`
- \`-[x0 performSelector:]\`
- \`settings\`
- \`-[x0 settings]\`
- \`initWithCADisplay:isMainDisplay:\`
- \`-[x0 initWithCADisplay:isMainDisplay:]\`
- \`hitTest:withEvent:\`
- \`pointInside:withEvent:\`
- \`sendEvent:\`
- \`initWithDisplayConfiguration:\`
- \`-[x0 initWithDisplayConfiguration:]\`
- \`initWithWindowScene:\`
- \`-[x0 initWithWindowScene:]\`
- \`initWithScreen:\`
- \`-[x0 initWithScreen:]\`
- \`initWithFrame:\`
- \`-[x0 initWithFrame:]\`
- \`setWindowScene:\`
- \`-[x0 setWindowScene:]\`
- \`setScreen:\`
- \`-[x0 setScreen:]\`
- \`setWindowLevel:\`
- \`-[x0 setWindowLevel:]\`
- \`carPlayUsableBounds\`
- \`-[x0 carPlayUsableBounds]\`
- \`setFrame:\`
- \`-[x0 setFrame:]\`
- \`setHidden:\`
- \`-[x0 setHidden:]\`
- \`clearColor\`
- \`+[UIColor clearColor]\`
- \`setBackgroundColor:\`
- \`-[x0 setBackgroundColor:]\`
- \`+[UIViewController setBackgroundColor:]\`
- \`view\`
- \`-[x0 view]\`
- \`setAutoresizingMask:\`
- \`-[x0 setAutoresizingMask:]\`
- \`setRootViewController:\`
- \`-[x0 setRootViewController:]\`
- \`initWithEffect:\`
- \`+[UIVisualEffectView initWithEffect:]\`
- \`-[x0 initWithEffect:]\`

<details omitted: raw bounded refs preserved in JSON>

## CBWindow::show — 0xb2814
Instructions sampled: 103 to 0xb29b0.

- \`resizeWindows\`
- \`-[x0 resizeWindows]\`
- \`layer\`
- \`-[x0 layer]\`
- \`removeAllAnimations\`
- \`-[x0 removeAllAnimations]\`
- \`setAlpha:\`
- \`-[x0 setAlpha:]\`
- \`setHidden:\`
- \`-[x0 setHidden:]\`
- \`makeKeyAndVisible\`
- \`respondsToSelector:\`
- \`-[x0 respondsToSelector:]\`
- \`view\`
- \`-[x0 view]\`
- \`bringSubviewToFront:\`
- \`-[x0 bringSubviewToFront:]\`
- \`wakeBubble\`
- \`-[x0 wakeBubble]\`
- \`frame\`
- \`-[x0 frame]\`
- \`isHidden\`
- \`-[x0 isHidden]\`
- \`windowLevel\`
- \`-[x0 windowLevel]\`

<details omitted: raw bounded refs preserved in JSON>

## CBWindow::resizeWindows — 0xb24ac
Instructions sampled: 218 to 0xb2814.

- \`carPlayScreenBounds\`
- \`+[CBWindow carPlayScreenBounds]\`
- \`carPlayUsableBounds\`
- \`-[x0 carPlayUsableBounds]\`
- \`setEffect:\`
- \`-[x0 setEffect:]\`
- \`setClipsToBounds:\`
- \`-[x0 setClipsToBounds:]\`
- \`layer\`
- \`-[x0 layer]\`
- \`setMasksToBounds:\`
- \`-[x0 setMasksToBounds:]\`
- \`superview\`
- \`-[x0 superview]\`
- \`bounds\`
- \`-[x0 bounds]\`
- \`updateBoundaryBounds:\`
- \`-[x0 updateBoundaryBounds:]\`
- \`bringSubviewToFront:\`
- \`-[x0 bringSubviewToFront:]\`

<details omitted: raw bounded refs preserved in JSON>

## CBWindow::showAppPickerForSlot: — 0xb3148
Instructions sampled: 44 to 0xb31f8.

- \`contentView\`
- \`-[x0 contentView]\`
- \`multitaskingOverlay\`
- \`-[x0 multitaskingOverlay]\`
- \`showAppPickerForSlot:parentView:\`
- \`-[x0 showAppPickerForSlot:parentView:]\`

<details omitted: raw bounded refs preserved in JSON>

## CBWindow::showLayoutChooser — 0xb31f8
Instructions sampled: 42 to 0xb32a0.

- \`contentView\`
- \`-[x0 contentView]\`
- \`multitaskingOverlay\`
- \`-[x0 multitaskingOverlay]\`
- \`showLayoutChooserInParentView:\`
- \`-[x0 showLayoutChooserInParentView:]\`

<details omitted: raw bounded refs preserved in JSON>

## CBWindow::showRecentApps — 0xb32a0
Instructions sampled: 42 to 0xb3348.

- \`contentView\`
- \`-[x0 contentView]\`
- \`multitaskingOverlay\`
- \`-[x0 multitaskingOverlay]\`
- \`showRecentAppsInParentView:\`
- \`-[x0 showRecentAppsInParentView:]\`

<details omitted: raw bounded refs preserved in JSON>

## CBWindow::destroyWindows — 0xb2d14
Instructions sampled: 236 to 0xb30c4.

- \`-[x0 carPlayCADisplay]\`
- \`contentView\`
- \`-[x0 contentView]\`
- \`setHidden:\`
- \`-[x0 setHidden:]\`
- \`isKeyWindow\`
- \`-[x0 isKeyWindow]\`
- \`resignKeyWindow\`
- \`-[x0 resignKeyWindow]\`

<details omitted: raw bounded refs preserved in JSON>

## CBBridgedSplitApp::handleDividerPan:isVertical:state: — 0x10b4c0
Instructions sampled: 390 to 0x10bad8.

- \`carPlayUsableBounds\`
- \`+[CBWindow carPlayUsableBounds]\`
- \`view\`
- \`-[x0 view]\`
- \`bounds\`
- \`-[x0 bounds]\`
- \`layoutSplitViews\`
- \`-[x0 layoutSplitViews]\`
- \`sharedInstance\`
- \`+[CBDashboardSettings sharedInstance]\`
- \`setSplitRatio:\`
- \`-[x0 setSplitRatio:]\`
- \`dictionaryWithContentsOfFile:\`
- \`+[NSMutableDictionary dictionaryWithContentsOfFile:]\`
- \`dictionary\`
- \`-[x0 dictionary]\`
- \`numberWithDouble:\`
- \`+[NSNumber numberWithDouble:]\`
- \`setObject:forKeyedSubscript:\`
- \`-[x0 setObject:forKeyedSubscript:]\`
- \`writeToFile:atomically:\`
- \`-[x0 writeToFile:atomically:]\`
- \`countByEnumeratingWithState:objects:count:\`
- \`-[x0 countByEnumeratingWithState:objects:count:]\`
- \`+[CBBridgeManager countByEnumeratingWithState:objects:count:]\`
- \`saveBridgeStateToDisk\`
- \`-[x0 saveBridgeStateToDisk]\`
- \`bundleIdentifier\`
- \`sendStateToApp:shouldBridge:\`
- \`-[x0 sendStateToApp:shouldBridge:]\`

<details omitted: raw bounded refs preserved in JSON>

## CBBridgedSplitApp::layoutSplitViews — 0x10bad8
Instructions sampled: 1000 to 0x10ccd8.

- \`carPlayUsableBounds\`
- \`+[CBWindow carPlayUsableBounds]\`
- \`view\`
- \`-[x0 view]\`
- \`bounds\`
- \`-[x0 bounds]\`
- \`isDismissing\`
- \`-[x0 isDismissing]\`
- \`objectAtIndexedSubscript:\`
- \`setUserInteractionEnabled:\`
- \`setAudioOnlyBackgroundMode:\`
- \`setFrame:\`
- \`setBounds:\`
- \`setCornerCurve:\`
- \`respondsToSelector:\`
- \`setBorderWidth:\`
- \`CGColor\`
- \`setMasksToBounds:\`
- \`bundleIdentifier\`
- \`length\`
- \`setNeedsLayout\`
- \`setFocusedMode:\`
- \`-[x0 setFocusedMode:]\`
- \`+[UIColor setFocusedMode:]\`
- \`countByEnumeratingWithState:objects:count:\`
- \`-[x0 countByEnumeratingWithState:objects:count:]\`
- \`setHidden:\`
- \`-[x0 setHidden:]\`
- \`array\`
- \`+[NSMutableArray array]\`
- \`-[x0 array]\`
- \`setShowsExpandButton:\`
- \`setCompactMode:\`
- \`-[x0 setCompactMode:]\`
- \`+[UIColor setCompactMode:]\`

<details omitted: raw bounded refs preserved in JSON>

## CBBridgedSplitApp::focusSlot:animated: — 0x10ce70
Instructions sampled: 359 to 0x10d40c.

- \`count\`
- \`-[x0 count]\`
- \`sharedInstance\`
- \`+[CBBridgeManager sharedInstance]\`
- \`saveBridgeStateToDisk\`
- \`-[x0 saveBridgeStateToDisk]\`
- \`countByEnumeratingWithState:objects:count:\`
- \`-[x0 countByEnumeratingWithState:objects:count:]\`
- \`bundleIdentifier\`
- \`sendStateToApp:shouldBridge:\`
- \`-[x0 sendStateToApp:shouldBridge:]\`
- \`+[CBBridgeManager sendStateToApp:shouldBridge:]\`
- \`animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:\`
- \`+[UIView animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:]\`
- \`layoutSplitViews\`
- \`-[x0 layoutSplitViews]\`
- \`noteUserActivity\`
- \`-[x0 noteUserActivity]\`
- \`refreshSceneLayout\`
- \`-[x0 refreshSceneLayout]\`
- \`+[CBBridgeManager refreshSceneLayout]\`

<details omitted: raw bounded refs preserved in JSON>

## CBBridgedSplitApp::restoreSplitAnimated: — 0x10d40c
Instructions sampled: 443 to 0x10daf8.

- \`countByEnumeratingWithState:objects:count:\`
- \`-[x0 countByEnumeratingWithState:objects:count:]\`
- \`sharedInstance\`
- \`+[CBBridgeManager sharedInstance]\`
- \`saveBridgeStateToDisk\`
- \`-[x0 saveBridgeStateToDisk]\`
- \`bundleIdentifier\`
- \`sendStateToApp:shouldBridge:\`
- \`-[x0 sendStateToApp:shouldBridge:]\`
- \`+[CBBridgeManager sendStateToApp:shouldBridge:]\`
- \`animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:\`
- \`+[UIView animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:]\`
- \`layoutSplitViews\`
- \`-[x0 layoutSplitViews]\`
- \`noteUserActivity\`
- \`-[x0 noteUserActivity]\`
- \`refreshSceneLayout\`
- \`-[x0 refreshSceneLayout]\`
- \`+[CBBridgeManager refreshSceneLayout]\`

<details omitted: raw bounded refs preserved in JSON>

## CBBridgedSplitApp::toggleFocusForSlot: — 0x10daf8
Instructions sampled: 18 to 0x10db40.

- \`restoreSplitAnimated:\`
- \`-[x0 restoreSplitAnimated:]\`
- \`focusSlot:animated:\`
- \`-[x0 focusSlot:animated:]\`

<details omitted: raw bounded refs preserved in JSON>

## CBBridgedSplitApp::configureDividerButtons — 0x10ddf4
Instructions sampled: 1000 to 0x10eff4.

- \`count\`
- \`-[x0 count]\`
- \`carPlayUsableBounds\`
- \`+[CBWindow carPlayUsableBounds]\`
- \`view\`
- \`-[x0 view]\`
- \`bounds\`
- \`-[x0 bounds]\`
- \`objectAtIndexedSubscript:\`
- \`-[x0 objectAtIndexedSubscript:]\`
- \`class\`
- \`+[CBDividerView class]\`
- \`isKindOfClass:\`
- \`-[x0 isKindOfClass:]\`
- \`new\`
- \`+[CBDividerButtonInfo new]\`
- \`setIconName:\`
- \`-[x0 setIconName:]\`
- \`setRelativePos:\`
- \`-[x0 setRelativePos:]\`
- \`setOnSwap:\`
- \`-[x0 setOnSwap:]\`
- \`setOnRotate:\`
- \`-[x0 setOnRotate:]\`
- \`arrayWithObjects:count:\`
- \`+[NSArray arrayWithObjects:count:]\`
- \`configureWithButtonConfigs:\`
- \`-[x0 configureWithButtonConfigs:]\`
- \`-[x0 class]\`
- \`countByEnumeratingWithState:objects:count:\`
- \`-[x0 countByEnumeratingWithState:objects:count:]\`
- \`+[CBDividerButtonInfo configureWithButtonConfigs:]\`
- \`+[NSArray configureWithButtonConfigs:]\`

<details omitted: raw bounded refs preserved in JSON>

## CBBridgedSplitApp::swapSlot:withSlot: — 0x1107b0
Instructions sampled: 496 to 0x110f70.

- \`count\`
- \`-[x0 count]\`
- \`objectAtIndexedSubscript:\`
- \`-[x0 objectAtIndexedSubscript:]\`
- \`view\`
- \`+[UIView view]\`
- \`transitionWithView:duration:options:animations:completion:\`
- \`-[x0 transitionWithView:duration:options:animations:completion:]\`
- \`removeFromSuperview\`
- \`-[x0 removeFromSuperview]\`
- \`bounds\`
- \`-[x0 bounds]\`
- \`setFrame:\`
- \`-[x0 setFrame:]\`
- \`insertSubview:atIndex:\`
- \`-[x0 insertSubview:atIndex:]\`
- \`setObject:atIndexedSubscript:\`
- \`-[x0 setObject:atIndexedSubscript:]\`
- \`isHidden\`
- \`-[x0 isHidden]\`
- \`setHidden:\`
- \`-[x0 setHidden:]\`
- \`updateLayout\`
- \`-[x0 updateLayout]\`
- \`refreshSceneLayout\`
- \`-[x0 refreshSceneLayout]\`
- \`persistSlotOrder\`
- \`-[x0 persistSlotOrder]\`
- \`sharedInstance\`
- \`+[CBBridgeManager sharedInstance]\`
- \`saveBridgeStateToDisk\`
- \`-[x0 saveBridgeStateToDisk]\`
- \`bundleIdentifier\`
- \`-[x0 bundleIdentifier]\`
- \`sendStateToApp:shouldBridge:\`
- \`-[x0 sendStateToApp:shouldBridge:]\`
- \`layoutSplitViews\`
- \`-[x0 layoutSplitViews]\`

<details omitted: raw bounded refs preserved in JSON>

## CBBridgedSplitApp::updateScale:forSlot: — 0x11042c
Instructions sampled: 84 to 0x11057c.

- \`count\`
- \`-[x0 count]\`
- \`objectAtIndexedSubscript:\`
- \`-[x0 objectAtIndexedSubscript:]\`
- \`refreshSceneLayout\`
- \`-[x0 refreshSceneLayout]\`
- \`sharedInstance\`
- \`+[CBBridgeManager sharedInstance]\`
- \`saveBridgeStateToDisk\`
- \`-[x0 saveBridgeStateToDisk]\`
- \`bundleIdentifier\`
- \`-[x0 bundleIdentifier]\`
- \`sendStateToApp:shouldBridge:\`
- \`-[x0 sendStateToApp:shouldBridge:]\`

<details omitted: raw bounded refs preserved in JSON>

## CBBridgedSplitApp::closeSlot: — 0x112318
Instructions sampled: 356 to 0x1128a8.

- \`count\`
- \`-[x0 count]\`
- \`countByEnumeratingWithState:objects:count:\`
- \`-[x0 countByEnumeratingWithState:objects:count:]\`
- \`setHidden:\`
- \`-[x0 setHidden:]\`
- \`objectAtIndexedSubscript:\`
- \`-[x0 objectAtIndexedSubscript:]\`
- \`bundleIdentifier\`
- \`-[x0 bundleIdentifier]\`
- \`copy\`
- \`-[x0 copy]\`
- \`dismiss\`
- \`-[x0 dismiss]\`
- \`removeFromSuperview\`
- \`-[x0 removeFromSuperview]\`
- \`length\`
- \`-[x0 length]\`
- \`sendStateToApp:shouldBridge:\`
- \`-[x0 sendStateToApp:shouldBridge:]\`
- \`initWithBundleIdentifier:\`
- \`+[CBBridgedUIAppView initWithBundleIdentifier:]\`
- \`bounds\`
- \`-[x0 bounds]\`
- \`setFrame:\`
- \`-[x0 setFrame:]\`
- \`setAutoresizingMask:\`
- \`-[x0 setAutoresizingMask:]\`
- \`insertSubview:atIndex:\`
- \`-[x0 insertSubview:atIndex:]\`
- \`setObject:atIndexedSubscript:\`
- \`-[x0 setObject:atIndexedSubscript:]\`
- \`persistSlotOrder\`
- \`-[x0 persistSlotOrder]\`
- \`sharedInstance\`
- \`+[CBBridgeManager sharedInstance]\`
- \`saveBridgeStateToDisk\`
- \`-[x0 saveBridgeStateToDisk]\`
- \`layoutSplitViews\`
- \`-[x0 layoutSplitViews]\`

<details omitted: raw bounded refs preserved in JSON>

## CBBridgedSplitApp::stop — 0x1136dc
Instructions sampled: 291 to 0x113b68.

- \`stopBlinkingSession\`
- \`-[x0 stopBlinkingSession]\`
- \`countByEnumeratingWithState:objects:count:\`
- \`-[x0 countByEnumeratingWithState:objects:count:]\`
- \`removeAllObjects\`
- \`-[x0 removeAllObjects]\`
- \`view\`
- \`-[x0 view]\`

<details omitted: raw bounded refs preserved in JSON>

## CBBridgedUIAppView::calculateNativeSizeForSlotRect: — 0xac788
Instructions sampled: 17 to 0xac7cc.

- No resolvable selector refs in this bounded assembly window

<details omitted: raw bounded refs preserved in JSON>

## CBBridgedUIAppView::updateLayout — 0xac7cc
Instructions sampled: 743 to 0xad368.

- \`bounds\`
- \`-[x0 bounds]\`
- \`calculateNativeSizeForSlotRect:\`
- \`-[x0 calculateNativeSizeForSlotRect:]\`
- \`setTransform:\`
- \`-[x0 setTransform:]\`
- \`setFrame:\`
- \`-[x0 setFrame:]\`
- \`view\`
- \`-[x0 view]\`
- \`setAutoresizingMask:\`
- \`-[x0 setAutoresizingMask:]\`
- \`class\`
- \`-[x0 class]\`
- \`valueForKey:\`
- \`-[x0 valueForKey:]\`
- \`setContentReferenceSize:withInterfaceOrientation:\`
- \`-[x0 setContentReferenceSize:withInterfaceOrientation:]\`
- \`setContentReferenceSize:withContentOrientation:andContainerOrientation:\`
- \`-[x0 setContentReferenceSize:withContentOrientation:andContainerOrientation:]\`
- \`setHomeGrabberDisplayMode:\`
- \`-[x0 setHomeGrabberDisplayMode:]\`
- \`setCenter:\`
- \`-[x0 setCenter:]\`
- \`layer\`
- \`-[x0 layer]\`
- \`setCornerRadius:\`
- \`-[x0 setCornerRadius:]\`
- \`setCornerCurve:\`
- \`-[x0 setCornerCurve:]\`
- \`setClipsToBounds:\`
- \`-[x0 setClipsToBounds:]\`
- \`initWithFormat:arguments:\`
- \`+[NSString initWithFormat:arguments:]\`
- \`date\`
- \`+[NSDate date]\`
- \`stringWithFormat:\`
- \`-[x0 stringWithFormat:]\`
- \`defaultManager\`
- \`+[NSFileManager defaultManager]\`
- \`attributesOfItemAtPath:error:\`
- \`-[x0 attributesOfItemAtPath:error:]\`
- \`fileSize\`
- \`-[x0 fileSize]\`
- \`writeToFile:atomically:encoding:error:\`
- \`-[x0 writeToFile:atomically:encoding:error:]\`
- \`UTF8String\`
- \`-[x0 UTF8String]\`
- \`fileHandleForWritingAtPath:\`
- \`+[NSFileHandle fileHandleForWritingAtPath:]\`
- \`-[x0 fileHandleForWritingAtPath:]\`
- \`data\`
- \`+[NSData data]\`
- \`createFileAtPath:contents:attributes:\`
- \`-[x0 createFileAtPath:contents:attributes:]\`

<details omitted: raw bounded refs preserved in JSON>

## CBBridgedUIAppView::updateSceneSettingsFrame — 0xad368
Instructions sampled: 559 to 0xadc24.

- \`bounds\`
- \`-[x0 bounds]\`
- \`carPlayUsableBounds\`
- \`+[CBWindow carPlayUsableBounds]\`
- \`calculateNativeSizeForSlotRect:\`
- \`-[x0 calculateNativeSizeForSlotRect:]\`
- \`valueForKey:\`
- \`-[x0 valueForKey:]\`
- \`setContentReferenceSize:withInterfaceOrientation:\`
- \`-[x0 setContentReferenceSize:withInterfaceOrientation:]\`
- \`setContentReferenceSize:withContentOrientation:andContainerOrientation:\`
- \`-[x0 setContentReferenceSize:withContentOrientation:andContainerOrientation:]\`
- \`sceneHandle\`
- \`-[x0 sceneHandle]\`
- \`performSelector:\`
- \`-[x0 performSelector:]\`
- \`numberWithBool:\`
- \`+[NSNumber numberWithBool:]\`
- \`-[x0 numberWithBool:]\`
- \`bundleIdentifier\`
- \`-[x0 bundleIdentifier]\`
- \`class\`
- \`-[x0 class]\`
- \`sceneIfExists\`
- \`-[x0 sceneIfExists]\`
- \`scene\`
- \`-[x0 scene]\`
- \`updateSettingsWithBlock:\`
- \`-[x0 updateSettingsWithBlock:]\`
- \`setFrame:\`
- \`-[x0 setFrame:]\`
- \`setForeground:\`
- \`-[x0 setForeground:]\`
- \`setOccluded:\`
- \`-[x0 setOccluded:]\`
- \`setUnderLock:\`
- \`-[x0 setUnderLock:]\`
- \`setCanShowWhileLocked:\`
- \`-[x0 setCanShowWhileLocked:]\`
- \`setDeactivationReasons:\`
- \`-[x0 setDeactivationReasons:]\`
- \`setIdleModeEnabled:\`
- \`-[x0 setIdleModeEnabled:]\`

<details omitted: raw bounded refs preserved in JSON>

## CBBridgedUIAppView::updateSceneFrame — 0xadc24
Instructions sampled: 3 to 0xadc30.

- \`refreshSceneLayout\`
- \`-[x0 refreshSceneLayout]\`

<details omitted: raw bounded refs preserved in JSON>

## CBBridgedUIAppView::refreshSceneLayout — 0xadc30
Instructions sampled: 54 to 0xadd08.

- \`updateLayout\`
- \`-[x0 updateLayout]\`
- \`updateSceneSettingsFrame\`
- \`-[x0 updateSceneSettingsFrame]\`
- \`view\`
- \`-[x0 view]\`
- \`setNeedsLayout\`
- \`-[x0 setNeedsLayout]\`
- \`layoutIfNeeded\`
- \`-[x0 layoutIfNeeded]\`

<details omitted: raw bounded refs preserved in JSON>

## CBBridgedUIAppView::startInParentViewController: — 0xadd08
Instructions sampled: 1000 to 0xaede8.

- \`invalidated\`
- \`-[x0 invalidated]\`
- \`hosting\`
- \`-[x0 hosting]\`
- \`setHosting:\`
- \`-[x0 setHosting:]\`
- \`sharedInstanceIfExists\`
- \`+[CBBridgeManager sharedInstanceIfExists]\`
- \`window\`
- \`-[x0 window]\`
- \`rootViewController\`
- \`-[x0 rootViewController]\`
- \`sharedInstance\`
- \`-[x0 sharedInstance]\`
- \`bundleIdentifier\`
- \`-[x0 bundleIdentifier]\`
- \`applicationWithBundleIdentifier:\`
- \`-[x0 applicationWithBundleIdentifier:]\`
- \`initWithApplicationForMainDisplay:\`
- \`-[x0 initWithApplicationForMainDisplay:]\`
- \`UUID\`
- \`+[NSUUID UUID]\`
- \`UUIDString\`
- \`-[x0 UUIDString]\`
- \`initWithIdentifier:andApplicationSceneEntity:\`
- \`-[x0 initWithIdentifier:andApplicationSceneEntity:]\`
- \`numberWithBool:\`
- \`+[NSNumber numberWithBool:]\`
- \`-[x0 numberWithBool:]\`
- \`addChildViewController:\`
- \`-[x0 addChildViewController:]\`
- \`setIgnoresOcclusions:\`
- \`-[x0 setIgnoresOcclusions:]\`
- \`setAutomatesLifecycle:\`
- \`-[x0 setAutomatesLifecycle:]\`
- \`bounds\`
- \`-[x0 bounds]\`
- \`calculateNativeSizeForSlotRect:\`
- \`-[x0 calculateNativeSizeForSlotRect:]\`
- \`carPlayUsableBounds\`
- \`+[CBWindow carPlayUsableBounds]\`
- \`view\`
- \`-[x0 view]\`
- \`setRequestedMode:\`
- \`-[x0 setRequestedMode:]\`
- \`initWithFrame:\`
- \`+[UIView initWithFrame:]\`
- \`blackColor\`
- \`+[UIColor blackColor]\`
- \`setBackgroundColor:\`
- \`-[x0 setBackgroundColor:]\`
- \`setOpaque:\`
- \`-[x0 setOpaque:]\`
- \`setTransform:\`
- \`-[x0 setTransform:]\`

<details omitted: raw bounded refs preserved in JSON>

## CBBridgedUIAppView::hitTest:withEvent: — 0xac448
Instructions sampled: 86 to 0xac5a0.

- \`sharedInstance\`
- \`+[CBBridgeManager sharedInstance]\`
- \`currentApp\`
- \`-[x0 currentApp]\`
- \`noteUserActivity\`
- \`-[x0 noteUserActivity]\`
- \`hitTest:withEvent:\`
- \`-[[x0 super] hitTest:withEvent:]\`

<details omitted: raw bounded refs preserved in JSON>

## CBBridgedUIAppView::dismiss — 0xaedf8
Instructions sampled: 111 to 0xaefb4.

- \`setInvalidated:\`
- \`-[x0 setInvalidated:]\`
- \`setHosting:\`
- \`-[x0 setHosting:]\`
- \`beginAppearanceTransition:animated:\`
- \`-[x0 beginAppearanceTransition:animated:]\`
- \`endAppearanceTransition\`
- \`-[x0 endAppearanceTransition]\`
- \`setRequestedMode:\`
- \`-[x0 setRequestedMode:]\`
- \`view\`
- \`-[x0 view]\`
- \`willMoveToParentViewController:\`
- \`-[x0 willMoveToParentViewController:]\`
- \`removeFromParentViewController\`
- \`-[x0 removeFromParentViewController]\`
- \`invalidate\`
- \`-[x0 invalidate]\`

<details omitted: raw bounded refs preserved in JSON>

## Next implementation gate

Compare individual picker, focus, divider and native-size paths with Native12 same-method evidence, then reconnect independent QA controller/scene-host interfaces. Do not import vendor CBBridgeManager, license validation or original postinst. Test on iPhone before claiming visual or functional parity.
