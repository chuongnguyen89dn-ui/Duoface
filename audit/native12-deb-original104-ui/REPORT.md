# Native12 Speed8 HUD vs DuoNavi 1.0.4 — actual DEB static dimension / asset audit

Status: **NATIVE12_VS_ORIGINAL104_ACTUAL_DEB_READONLY**. Debs pinned by SHA256.
**Only static artifacts/method samples; neither Objective-C dispatch nor live CarPlay rects are established.**
No vendor binary is embedded in independent QA. Distinguish image pixel dimensions from UIKit point dimensions.

## Native12 PNG/logo sources in REAL native DEB

| Asset path | Pixels | Alpha nonblank bbox (pixels) | SHA256 |
|---|---:|---|---|
| `var/jb/Applications/DuoFaceUI.app/AppIcon29x29.png` | 29×29 | `[0, 0, 29, 29]` | `71debbd1ec86ddc0f81ec912b81270cd015e0cbc72b21ba4657d7a89a65c9b66` |
| `var/jb/Applications/DuoFaceUI.app/AppIcon29x29@2x.png` | 58×58 | `[0, 0, 58, 58]` | `7cd2974d10f2ec892957a0e5995f43e81ba0d73efe701d45719765cc57de77cf` |
| `var/jb/Applications/DuoFaceUI.app/AppIcon29x29@3x.png` | 87×87 | `[0, 0, 87, 87]` | `444a05ca1cf748cfd7440fa390e758d3a2e9e365701d3c9787374ae055171295` |
| `var/jb/Applications/DuoFaceUI.app/AppIcon40x40.png` | 40×40 | `[0, 0, 40, 40]` | `9934e080e8d4fe2c7c1ee5feda7f3d1b0ceeabf8dd65834d03fa0baadd49d1ed` |
| `var/jb/Applications/DuoFaceUI.app/AppIcon40x40@2x.png` | 80×80 | `[0, 0, 80, 80]` | `9ab7dc6d37efbed691648cf545ffd490125e24d1a78a3f11043b167c780f5ff6` |
| `var/jb/Applications/DuoFaceUI.app/AppIcon40x40@3x.png` | 120×120 | `[0, 0, 120, 120]` | `ca2e7402c268eb08ecb031b24bce4fd8c9bfde7c169431f7aa860070e6964e7d` |
| `var/jb/Applications/DuoFaceUI.app/AppIcon50x50.png` | 50×50 | `[0, 0, 50, 50]` | `a3d6c1fb86f75aab76dda4dd51368ab903f23cd98be1522edab6a684d23ff420` |
| `var/jb/Applications/DuoFaceUI.app/AppIcon50x50@2x.png` | 100×100 | `[0, 0, 100, 100]` | `a0b2483b684eec28c813a0ba13bf25700c240681905cfd26e86320c96f7a063c` |
| `var/jb/Applications/DuoFaceUI.app/AppIcon57x57.png` | 57×57 | `[0, 0, 57, 57]` | `02954587d7cff643f4805a79df90da4c5d5a4eb7ab5026eb71698b42af85ee52` |
| `var/jb/Applications/DuoFaceUI.app/AppIcon57x57@2x.png` | 114×114 | `[0, 0, 114, 114]` | `a6ef5deaa71c36aaea9e2646f1b9759f62b792a6a0ff3b9720bda88258aecacd` |
| `var/jb/Applications/DuoFaceUI.app/AppIcon57x57@3x.png` | 171×171 | `[0, 0, 171, 171]` | `5d796161858e6dc07bf90283f1528149a5be01437ed242095cb3af3ebc2425bf` |
| `var/jb/Applications/DuoFaceUI.app/AppIcon60x60.png` | 60×60 | `[0, 0, 60, 60]` | `e0cd867606e62b90c9dc9962520ca1d760b47ba7dd9593505f826e757625cb11` |
| `var/jb/Applications/DuoFaceUI.app/AppIcon60x60@2x.png` | 120×120 | `[0, 0, 120, 120]` | `ca2e7402c268eb08ecb031b24bce4fd8c9bfde7c169431f7aa860070e6964e7d` |
| `var/jb/Applications/DuoFaceUI.app/AppIcon60x60@3x.png` | 180×180 | `[0, 0, 180, 180]` | `6cf13a7c3e5aac30d0232a53b8388ae6623b43259afd125ef88e2ff509604d12` |
| `var/jb/Applications/DuoFaceUI.app/AppIcon72x72.png` | 72×72 | `[0, 0, 72, 72]` | `0480a1a0adbc74d7e3272c82e7b0f8fe86352b44c99e7c151aea76eaa085f3ac` |
| `var/jb/Applications/DuoFaceUI.app/AppIcon72x72@2x.png` | 144×144 | `[0, 0, 144, 144]` | `ca01ebbfc396c8f6e1ebffa03c80df4714fc099c6decce0e49ab58eafe3a79a5` |
| `var/jb/Applications/DuoFaceUI.app/AppIcon76x76.png` | 76×76 | `[0, 0, 76, 76]` | `df2a07dc88e81ed07a33fc51161510d1404fc59df0e5231cc7c7e94ac261371c` |
| `var/jb/Applications/DuoFaceUI.app/AppIcon76x76@2x.png` | 152×152 | `[0, 0, 152, 152]` | `3e875d60e256732dbbc2774ed88cbce098fdf81d684e9724d7bbe7c6b17dc3a8` |
| `var/jb/Library/Application Support/DuoFace/VisualAssets/duoface-fullscreen.png` | 88×88 | `[0, 0, 88, 88]` | `10e52f01a16cb7d34a81330373a290bcac1bdb0ba9c91119527ef3dcb13cdb36` |
| `var/jb/Library/Application Support/DuoFace/VisualAssets/duoface-picker.png` | 256×70 | `[6, 0, 251, 70]` | `16a959b71a0d3d8ef86e2ac9163024af457aec180770c757fe4b16d2b0a85f8a` |
| `var/jb/Library/Application Support/DuoFace/VisualAssets/duoface-swap.png` | 120×120 | `[0, 0, 120, 120]` | `d3ec77c783a186896d63bb08732ee78e427f16e1c127c0785b36bf5eaa037275` |
| `var/jb/Library/Application Support/DuoFace/duoface-icon.png` | 256×256 | `[0, 0, 256, 256]` | `03f0a9e31bffced19419f06193d866bb2d66d824c5ba10c5c24eee8718217def` |
| `var/jb/Library/Application Support/DuoFace/duoface-logo-picker-alpha-v2.png` | 627×228 | `[0, 0, 627, 228]` | `43b6dafb8fc0550c2b3032c11acae1e0712350ca5b4dd235b7dc14c7951c74f7` |
| `var/jb/Library/Application Support/DuoFace/duoface-logo-vert.png` | 640×640 | `[0, 0, 640, 640]` | `7fa216e2fa89e4fc32e49045ab29d72f6bee3fef4f974444c98fb5bd631e25d2` |
| `var/jb/Library/Application Support/DuoFace/duoface-logo.png` | 960×240 | `[0, 0, 960, 240]` | `78450d8ee4759353bdc21f27a06016c03fab61038ae60109ba21515c087b0089` |

## Original 1.0.4 and Native12 per-class method comparison

| Class | Original 1.0.4 method entries | Native12 method entries | DuoFace-owned replacement |
|---|---:|---:|---|
| `CBWindow` | 40 | 37 | DFINativeWindowSurface / DFIStart; owns external UIWindow, safe-area |
| `CBMultitaskingOverlayView` | 66 | 66 | DFINativePickerCard + DFINativePickerMenuBar + DFINativePickerCardsController |
| `CBSlotPillView` | 36 | 36 | DFINativeSlotPillView / choose:, zoomPane: |
| `CBDividerView` | 27 | 27 | DFINativeDividerTrack / drag: and DFINativeDividerLogo / swapPanes, moveDividerLogo: |
| `CBBridgedSplitApp` | 50 | 49 | DFV12SplitController / DFIFramesMake, swapPanes, zoomPane: |
| `CBBridgedUIAppView` | 31 | 29 | DFV12SceneHost / attachTo, resizeTo, applySize, close |

## Geometric and callback candidate IMPs (static)

### CBWindow
- `createWindows`: Native12 `0xb1064`; original104 `0xb173c`. Native selector refs: `carPlayWindowScene, +[CBWindow carPlayWindowScene], carPlayUIScreen, -[x0 carPlayUIScreen], screen, -[x0 screen], carPlayCADisplay, -[x0 carPlayCADisplay], displayConfiguration, -[x0 displayConfiguration], _FBSScene, -[x0 _FBSScene], performSelector:, -[x0 performSelector:], settings`. Arithmetic/control samples: 16.
- `resizeWindows`: Native12 `0xb1aac`; original104 `0xb24ac`. Native selector refs: `carPlayScreenBounds, +[CBWindow carPlayScreenBounds], carPlayUsableBounds, -[x0 carPlayUsableBounds], view, -[x0 view], setEffect:, -[x0 setEffect:], setClipsToBounds:, -[x0 setClipsToBounds:], layer, -[x0 layer], setMasksToBounds:, -[x0 setMasksToBounds:], superview`. Arithmetic/control samples: 3.
- `show`: Native12 `0xb1d98`; original104 `0xb2814`. Native selector refs: `resizeWindows, -[x0 resizeWindows], layer, -[x0 layer], removeAllAnimations, -[x0 removeAllAnimations], setAlpha:, -[x0 setAlpha:], setHidden:, -[x0 setHidden:], makeKeyAndVisible, respondsToSelector:, -[x0 respondsToSelector:], frame, -[x0 frame]`. Arithmetic/control samples: 3.
- `carPlayContentInsets`: Native12 `0xb0c98`; original104 `0xb1370`. Native selector refs: `stringWithContentsOfFile:encoding:error:, +[NSString stringWithContentsOfFile:encoding:error:], length, -[x0 length], activeCarPlayWindow, +[CBWindow activeCarPlayWindow], rootWindow, -[x0 rootWindow], safeAreaInsets, respondsToSelector:, -[x0 respondsToSelector:]`. Arithmetic/control samples: 4.
- `carPlayUsableBounds`: Native12 `0xb0ef4`; original104 `0xb15cc`. Native selector refs: `carPlayScreenBounds, -[x0 carPlayScreenBounds], carPlayContentInsets, -[x0 carPlayContentInsets]`. Arithmetic/control samples: 13.
- `showAppPickerForSlot:`: Native12 `0xb25e4`; original104 `0xb3148`. Native selector refs: `contentView, -[x0 contentView], multitaskingOverlay, -[x0 multitaskingOverlay], showAppPickerForSlot:parentView:, -[x0 showAppPickerForSlot:parentView:]`. Arithmetic/control samples: 0.
- `showLayoutChooser`: Native12 `0xb2694`; original104 `0xb31f8`. Native selector refs: `contentView, -[x0 contentView], multitaskingOverlay, -[x0 multitaskingOverlay], showLayoutChooserInParentView:, -[x0 showLayoutChooserInParentView:]`. Arithmetic/control samples: 0.
- `destroyWindows`: Native12 `0xb21f8`; original104 `0xb2d14`. Native selector refs: `-[x0 carPlayCADisplay], contentView, -[x0 contentView], setHidden:, -[x0 setHidden:], isKeyWindow, -[x0 isKeyWindow], resignKeyWindow, -[x0 resignKeyWindow]`. Arithmetic/control samples: 10.

### CBMultitaskingOverlayView
- `initWithFrame:`: Native12 `0xa0420`; original104 `0x9fb70`. Native selector refs: `initWithFrame:, -[[x0 super] initWithFrame:], clearColor, +[UIColor clearColor], setBackgroundColor:, -[x0 setBackgroundColor:], setAutoresizingMask:, -[x0 setAutoresizingMask:], arrayWithObjects:count:, +[NSArray arrayWithObjects:count:], arrayWithArray:, -[x0 arrayWithArray:], bounds, +[UIView bounds], -[x0 bounds]`. Arithmetic/control samples: 14.
- `layoutSubviews`: Native12 `0xa28e8`; original104 `0xa202c`. Native selector refs: `layoutSubviews, -[[x0 super] layoutSubviews], bounds, -[x0 bounds], setFrame:, -[x0 setFrame:], setupCardContent, -[x0 setupCardContent]`. Arithmetic/control samples: 18.
- `setupCardContent`: Native12 `0xa2a58`; original104 `0xa21c8`. Native selector refs: `contentView, -[x0 contentView], subviews, -[x0 subviews], countByEnumeratingWithState:objects:count:, -[x0 countByEnumeratingWithState:objects:count:], bounds, -[x0 bounds], initWithFrame:, +[UIImageView initWithFrame:], setContentMode:, -[x0 setContentMode:], colorWithRed:green:blue:alpha:, -[x0 colorWithRed:green:blue:alpha:], setTintColor:`. Arithmetic/control samples: 40.
- `setupAppPickerCardsInCardW:cardH:contentY:`: Native12 `0xa3e5c`; original104 `0xa35cc`. Native selector refs: `contentView, -[x0 contentView], count, -[x0 count], array, +[NSMutableArray array], -[x0 array], dictionary, +[NSMutableDictionary dictionary], objectAtIndexedSubscript:, numberWithInteger:, -[x0 numberWithInteger:], sharedInstance, +[CBDashboardSettings sharedInstance], reload`. Arithmetic/control samples: 40.
- `setupRecentAppsCardsInCardW:cardH:contentY:`: Native12 `0xa678c`; original104 `0xa5efc`. Native selector refs: `contentView, -[x0 contentView], sharedInstance, +[CBBridgeManager sharedInstance], runningBridgedApplications, -[x0 runningBridgedApplications], initWithFrame:, +[UILabel initWithFrame:], systemFontOfSize:weight:, +[UIFont systemFontOfSize:weight:], setFont:, -[x0 setFont:], colorWithWhite:alpha:, +[UIColor colorWithWhite:alpha:], setTextColor:`. Arithmetic/control samples: 40.

### CBSlotPillView
- `initWithSlotIndex:`: Native12 `0x841c0`; original104 `0x82f74`. Native selector refs: `initWithFrame:, -[[x0 super] initWithFrame:], array, +[NSMutableArray array], colorWithRed:green:blue:alpha:, +[UIColor colorWithRed:green:blue:alpha:], setBackgroundColor:, -[x0 setBackgroundColor:], layer, -[x0 layer], setCornerRadius:, -[x0 setCornerRadius:], setCornerCurve:, -[x0 setCornerCurve:], setMasksToBounds:`. Arithmetic/control samples: 40.
- `updateBoundsSize`: Native12 `0x85184`; original104 `0x83f90`. Native selector refs: `setBounds:, -[x0 setBounds:], configurationWithPointSize:weight:, +[UIImageSymbolConfiguration configurationWithPointSize:weight:], systemImageNamed:withConfiguration:, +[UIImage systemImageNamed:withConfiguration:], setImage:forState:, -[x0 setImage:forState:], setNeedsLayout, -[x0 setNeedsLayout], layoutIfNeeded, -[x0 layoutIfNeeded]`. Arithmetic/control samples: 14.
- `layoutSubviews`: Native12 `0x84c30`; original104 `0x83a10`. Native selector refs: `layoutSubviews, -[[x0 super] layoutSubviews], bounds, -[x0 bounds], layer, -[x0 layer], setCornerRadius:, -[x0 setCornerRadius:], setHidden:, -[x0 setHidden:], setFrame:, -[x0 setFrame:], count, -[x0 count], objectAtIndexedSubscript:`. Arithmetic/control samples: 40.
- `pointInside:withEvent:`: Native12 `0x85348`; original104 `0x84154`. Native selector refs: `isHidden, -[x0 isHidden], alpha, -[x0 alpha], bounds, -[x0 bounds]`. Arithmetic/control samples: 9.
- `dotsTapped:`: Native12 `0x85580`; original104 `0x8438c`. Native selector refs: `bounceButton:, -[x0 bounceButton:], sharedInstance, +[CBBridgeManager sharedInstance], currentApp, -[x0 currentApp], noteUserActivity, -[x0 noteUserActivity], onPillTapped, -[x0 onPillTapped]`. Arithmetic/control samples: 0.
- `expandTapped:`: Native12 `0x85698`; original104 `0x844a4`. Native selector refs: `bounceButton:, -[x0 bounceButton:], sharedInstance, +[CBBridgeManager sharedInstance], currentApp, -[x0 currentApp], noteUserActivity, -[x0 noteUserActivity], onExpandTapped, -[x0 onExpandTapped]`. Arithmetic/control samples: 0.
- `restoreTapped:`: Native12 `0x857b0`; original104 `0x845bc`. Native selector refs: `bounceButton:, -[x0 bounceButton:], sharedInstance, +[CBBridgeManager sharedInstance], currentApp, -[x0 currentApp], noteUserActivity, -[x0 noteUserActivity], onRestoreTapped, -[x0 onRestoreTapped], onPillTapped, -[x0 onPillTapped]`. Arithmetic/control samples: 0.
- `handleLongPress:`: Native12 `0x853f0`; original104 `0x841fc`. Native selector refs: `state, -[x0 state], bounceButton:, -[x0 bounceButton:], sharedInstance, +[CBBridgeManager sharedInstance], currentApp, -[x0 currentApp], noteUserActivity, -[x0 noteUserActivity], onPillLongPressed, -[x0 onPillLongPressed], onPillTapped, -[x0 onPillTapped]`. Arithmetic/control samples: 0.
- `setIsCompactMode:`: Native12 `0x85bec`; original104 `0x84aac`. Native selector refs: ``. Arithmetic/control samples: 0.
- `setIsFocusedMode:`: Native12 `0x85bbc`; original104 `0x84a7c`. Native selector refs: ``. Arithmetic/control samples: 0.
- `setShowsExpandButton:`: Native12 `0x852f0`; original104 `0x840fc`. Native selector refs: `updateBoundsSize, -[x0 updateBoundsSize]`. Arithmetic/control samples: 0.
- `setFocusedMode:`: Native12 `0x85308`; original104 `0x84114`. Native selector refs: `updateBoundsSize, -[x0 updateBoundsSize]`. Arithmetic/control samples: 0.
- `isCompactMode`: Native12 `0x85bdc`; original104 `0x84a9c`. Native selector refs: ``. Arithmetic/control samples: 0.
- `isFocusedMode`: Native12 `0x85bac`; original104 `0x84a6c`. Native selector refs: ``. Arithmetic/control samples: 0.
- `showsExpandButton`: Native12 `0x85bcc`; original104 `0x84a8c`. Native selector refs: ``. Arithmetic/control samples: 0.

### CBDividerView
- `initWithFrame:isVertical:`: Native12 `0xfe7dc`; original104 `0x105a14`. Native selector refs: `initWithFrame:, -[[x0 super] initWithFrame:], clearColor, +[UIColor clearColor], setBackgroundColor:, -[x0 setBackgroundColor:], setUserInteractionEnabled:, -[x0 setUserInteractionEnabled:], setClipsToBounds:, -[x0 setClipsToBounds:], array, +[NSMutableArray array], -[x0 array], new, +[CBDividerButtonInfo new]`. Arithmetic/control samples: 5.
- `layoutSubviews`: Native12 `0xff410`; original104 `0x106648`. Native selector refs: `layoutSubviews, -[[x0 super] layoutSubviews], updateGripLayout, -[x0 updateGripLayout]`. Arithmetic/control samples: 0.
- `updateGripLayout`: Native12 `0xff460`; original104 `0x1066c4`. Native selector refs: `bounds, -[x0 bounds], count, -[x0 count], objectAtIndexedSubscript:, relativePos, setFrame:, -[x0 setFrame:]`. Arithmetic/control samples: 31.
- `pointInside:withEvent:`: Native12 `0xff728`; original104 `0x10698c`. Native selector refs: `isHidden, -[x0 isHidden], alpha, -[x0 alpha], countByEnumeratingWithState:objects:count:, -[x0 countByEnumeratingWithState:objects:count:], frame, -[x0 frame], bounds, -[x0 bounds]`. Arithmetic/control samples: 7.
- `handlePan:`: Native12 `0x10152c`; original104 `0x108954`. Native selector refs: `onActivity, -[x0 onActivity], superview, -[x0 superview], translationInView:, -[x0 translationInView:], onPanChanged, -[x0 onPanChanged], state, -[x0 state]`. Arithmetic/control samples: 0.
- `handleMoveButtonLongPress:`: Native12 `0x1005f4`; original104 `0x107964`. Native selector refs: `state, -[x0 state], onActivity, -[x0 onActivity], view, -[x0 view], indexOfObject:, -[x0 indexOfObject:], count, -[x0 count], objectAtIndexedSubscript:, -[x0 objectAtIndexedSubscript:], animateWithDuration:animations:completion:, +[UIView animateWithDuration:animations:completion:], onRotate`. Arithmetic/control samples: 2.

### CBBridgedSplitApp
- `layoutSplitViews`: Native12 `0x1044f8`; original104 `0x10bad8`. Native selector refs: `carPlayUsableBounds, +[CBWindow carPlayUsableBounds], view, -[x0 view], bounds, -[x0 bounds], isDismissing, -[x0 isDismissing], objectAtIndexedSubscript:, setUserInteractionEnabled:, setAudioOnlyBackgroundMode:, setFrame:, setBounds:, setCornerCurve:, respondsToSelector:`. Arithmetic/control samples: 40.
- `handleDividerPan:isVertical:state:`: Native12 `0x103ee0`; original104 `0x10b4c0`. Native selector refs: `carPlayUsableBounds, +[CBWindow carPlayUsableBounds], view, -[x0 view], bounds, -[x0 bounds], layoutSplitViews, -[x0 layoutSplitViews], sharedInstance, +[CBDashboardSettings sharedInstance], setSplitRatio:, -[x0 setSplitRatio:], dictionaryWithContentsOfFile:, +[NSMutableDictionary dictionaryWithContentsOfFile:], dictionary`. Arithmetic/control samples: 18.
- `focusSlot:animated:`: Native12 `0x105890`; original104 `0x10ce70`. Native selector refs: `count, -[x0 count], sharedInstance, +[CBBridgeManager sharedInstance], saveBridgeStateToDisk, -[x0 saveBridgeStateToDisk], countByEnumeratingWithState:objects:count:, -[x0 countByEnumeratingWithState:objects:count:], bundleIdentifier, sendStateToApp:shouldBridge:, -[x0 sendStateToApp:shouldBridge:], +[CBBridgeManager sendStateToApp:shouldBridge:], animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:, +[UIView animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:], layoutSplitViews`. Arithmetic/control samples: 12.
- `restoreSplitAnimated:`: Native12 `0x105e2c`; original104 `0x10d40c`. Native selector refs: `countByEnumeratingWithState:objects:count:, -[x0 countByEnumeratingWithState:objects:count:], sharedInstance, +[CBBridgeManager sharedInstance], saveBridgeStateToDisk, -[x0 saveBridgeStateToDisk], bundleIdentifier, sendStateToApp:shouldBridge:, -[x0 sendStateToApp:shouldBridge:], +[CBBridgeManager sendStateToApp:shouldBridge:], animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:, +[UIView animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:], layoutSplitViews, -[x0 layoutSplitViews], noteUserActivity`. Arithmetic/control samples: 21.
- `configureDividerButtons`: Native12 `0x1067a4`; original104 `0x10ddf4`. Native selector refs: `count, -[x0 count], carPlayUsableBounds, +[CBWindow carPlayUsableBounds], view, -[x0 view], bounds, -[x0 bounds], objectAtIndexedSubscript:, -[x0 objectAtIndexedSubscript:], class, +[CBDividerView class], isKindOfClass:, -[x0 isKindOfClass:], new`. Arithmetic/control samples: 40.
- `handleDividerSwapPressed:`: Native12 `0x108fc8`; original104 `0x11061c`. Native selector refs: `swapSlot:withSlot:, count, -[x0 count], -[x0 swapSlot:withSlot:], appViews, -[x0 appViews]`. Arithmetic/control samples: 10.
- `swapSlot:withSlot:`: Native12 `0x10915c`; original104 `0x1107b0`. Native selector refs: `count, -[x0 count], objectAtIndexedSubscript:, -[x0 objectAtIndexedSubscript:], view, +[UIView view], transitionWithView:duration:options:animations:completion:, -[x0 transitionWithView:duration:options:animations:completion:], removeFromSuperview, -[x0 removeFromSuperview], bounds, -[x0 bounds], setFrame:, -[x0 setFrame:], insertSubview:atIndex:`. Arithmetic/control samples: 9.

### CBBridgedUIAppView
- `calculateNativeSizeForSlotRect:`: Native12 `0xacc28`; original104 `0xac788`. Native selector refs: ``. Arithmetic/control samples: 8.
- `updateLayout`: Native12 `0xacc6c`; original104 `0xac7cc`. Native selector refs: `bounds, -[x0 bounds], calculateNativeSizeForSlotRect:, -[x0 calculateNativeSizeForSlotRect:], setTransform:, -[x0 setTransform:], setFrame:, -[x0 setFrame:], view, -[x0 view], setAutoresizingMask:, -[x0 setAutoresizingMask:], class, -[x0 class], valueForKey:`. Arithmetic/control samples: 25.
- `updateSceneSettingsFrame`: Native12 `0xad5bc`; original104 `0xad368`. Native selector refs: `bounds, -[x0 bounds], carPlayUsableBounds, +[CBWindow carPlayUsableBounds], calculateNativeSizeForSlotRect:, -[x0 calculateNativeSizeForSlotRect:], valueForKey:, -[x0 valueForKey:], setContentReferenceSize:withInterfaceOrientation:, respondsToSelector:, -[x0 respondsToSelector:], setContentReferenceSize:withContentOrientation:andContainerOrientation:, -[x0 setContentReferenceSize:withContentOrientation:andContainerOrientation:], sceneHandle, -[x0 sceneHandle]`. Arithmetic/control samples: 26.
- `updateSceneFrame`: Native12 `0xade4c`; original104 `0xadc24`. Native selector refs: `refreshSceneLayout, -[x0 refreshSceneLayout]`. Arithmetic/control samples: 0.
- `startInParentViewController:`: Native12 `0xadf30`; original104 `0xadd08`. Native selector refs: `invalidated, -[x0 invalidated], hosting, -[x0 hosting], setHosting:, -[x0 setHosting:], sharedInstanceIfExists, +[CBBridgeManager sharedInstanceIfExists], window, -[x0 window], rootViewController, -[x0 rootViewController], sharedInstance, -[x0 sharedInstance], bundleIdentifier`. Arithmetic/control samples: 40.
- `dismiss`: Native12 `0xaf01c`; original104 `0xaedf8`. Native selector refs: `setInvalidated:, -[x0 setInvalidated:], setHosting:, -[x0 setHosting:], beginAppearanceTransition:animated:, respondsToSelector:, -[x0 respondsToSelector:], endAppearanceTransition, -[x0 endAppearanceTransition], setRequestedMode:, -[x0 setRequestedMode:], view, -[x0 view], willMoveToParentViewController:, -[x0 willMoveToParentViewController:]`. Arithmetic/control samples: 6.

## Decoded Native12 divider geometry literal evidence

Read-only Mach-O LC_SEGMENT_64 mapping, pinned SHA; static, not receiver dimensions.
- Along-divider length threshold: **280pt** at VM 0x312488 (ARM64 ff4bc–ff4d0).
- Native move/grip button frame: square **28x28pt** for divider length less than threshold,
  square **30x30pt** otherwise; setFrame d2=d3=d8 at ff6b0–ff6c0.
- Hit-test literal: **0.01** at VM 0x311948 (ARM64 ff858–ff864).
  This constant alone is not a complete resolved hit rectangle.
- QA divider button visual frame / hit forwarding still require code and parked-CarPlay validation.

## Interpretation and implementation order

1. Use actual Native12 PNG hashes/dimensions and approve asset choice. Never infer UIButton size from PNG pixel size.
2. Recover Native12 class-specific layout, hit rectangles and gestures from the bounded disassembly above; prove owner/selector version by version.
3. Map each component to the independent DuoFace owner in the table; test view-tree, menu actions, scene launch and geometry in isolation.
4. Combine source-owned view and scene binding after per-component proof. No copy of original vendor license/classes or postinst.
5. Actual rects, safe area and visual equivalence still require the user's parked CarPlay screenshot/runtime log. No Sileo release from this audit.


## Native12 pill/divider ARM64 frame evidence

Bounded raw instructions (not decoded point frames). An immediate is NOT a UI dimension.
Compare registers and call sites before changing the independent QA UI.

### CBSlotPillView.layoutSubviews

Native12 IMP 0x84c30, original104 IMP 0x83a10

~~~text
...
84ca8:	69 1c a3 4e	mov.16b	v9, v3
84cac:	68 20 60 1e	fcmp	d3, #0.0
84cb0:	e9 06 00 54	b.ls	0x84d8c
84cb4:	08 10 6c 1e	fmov	d8, #0.50000000
84cb8:	2b 09 68 1e	fmul	d11, d9, d8
84cbc:	c8 17 00 b0	adrp	x8, 761 ; 0x37d000
84cc0:	14 0d 45 f9	ldr	x20, [x8, #0xa18] ; Objc selector ref: layer
84cc4:	e0 03 13 aa	mov	x0, x19
...
84d78:	e2 9f 09 94	bl	0x2ecd00 ; Objc message: -[x0 setHidden:]
84d7c:	60 6a 75 f8	ldr	x0, [x19, x21]
84d80:	c8 17 00 b0	adrp	x8, 761 ; 0x37d000
84d84:	01 09 45 f9	ldr	x1, [x8, #0xa10] ; Objc selector ref: setFrame:
84d88:	de 9f 09 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
84d8c:	fd 7b 49 a9	ldp	x29, x30, [sp, #0x90]
84d90:	f4 4f 48 a9	ldp	x20, x19, [sp, #0x80]
84d94:	f6 57 47 a9	ldp	x22, x21, [sp, #0x70]
...
84e24:	e1 03 17 aa	mov	x1, x23
84e28:	22 00 80 52	mov	w2, #0x1
84e2c:	b5 9f 09 94	bl	0x2ecd00 ; Objc message: -[x0 setHidden:]
84e30:	40 09 68 1e	fmul	d0, d10, d8
84e34:	00 40 62 1e	fcvt	s0, d0
84e38:	00 40 26 1e	frinta	s0, s0
84e3c:	0b c0 22 1e	fcvt	d11, s0
84e40:	60 6a 78 f8	ldr	x0, [x19, x24]
84e44:	c8 17 00 b0	adrp	x8, 761 ; 0x37d000
84e48:	16 09 45 f9	ldr	x22, [x8, #0xa10] ; Objc selector ref: setFrame:
84e4c:	e0 03 67 9e	fmov	d0, xzr
84e50:	e1 03 67 9e	fmov	d1, xzr
84e54:	e1 03 16 aa	mov	x1, x22
84e58:	62 1d ab 4e	mov.16b	v2, v11
84e5c:	23 1d a9 4e	mov.16b	v3, v9
84e60:	a8 9f 09 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
84e64:	00 10 7a 1e	fmov	d0, #-0.25000000
84e68:	60 29 60 1e	fadd	d0, d11, d0
84e6c:	01 90 73 1e	fmov	d1, #-7.00000000
84e70:	21 29 61 1e	fadd	d1, d9, d1
84e74:	02 90 63 1e	fmov	d2, #7.00000000
84e78:	20 21 62 1e	fcmp	d9, d2
84e7c:	02 10 65 1e	fmov	d2, #12.00000000
84e80:	23 cc 62 1e	fcsel	d3, d1, d2, gt
84e84:	60 6a 79 f8	ldr	x0, [x19, x25]
84e88:	01 90 61 1e	fmov	d1, #3.50000000
84e8c:	e1 03 16 aa	mov	x1, x22
84e90:	02 1d a8 4e	mov.16b	v2, v8
84e94:	9b 9f 09 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
84e98:	42 39 6b 1e	fsub	d2, d10, d11
84e9c:	60 6a 7a f8	ldr	x0, [x19, x26]
84ea0:	e1 03 67 9e	fmov	d1, xzr
84ea4:	e1 03 16 aa	mov	x1, x22
84ea8:	60 1d ab 4e	mov.16b	v0, v11
84eac:	23 1d a9 4e	mov.16b	v3, v9
84eb0:	94 9f 09 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
84eb4:	c8 17 00 f0	adrp	x8, 763 ; 0x37f000
84eb8:	08 61 8c b9	ldrsw	x8, [x8, #0xc60]
84ebc:	78 6a 68 38	ldrb	w24, [x19, x8]
...
84ef4:	68 14 00 90	adrp	x8, 652 ; 0x310000
84ef8:	08 01 34 91	add	x8, x8, #0xd00
84efc:	00 59 7a fc	ldr	d0, [x8, w26, uxtw #3]
84f00:	01 10 61 1e	fmov	d1, #3.00000000
84f04:	41 09 61 1e	fmul	d1, d10, d1
84f08:	00 28 61 1e	fadd	d0, d0, d1
84f0c:	60 39 60 1e	fsub	d0, d11, d0
84f10:	0c 08 68 1e	fmul	d12, d0, d8
84f14:	20 39 6a 1e	fsub	d0, d9, d10
84f18:	09 08 68 1e	fmul	d9, d0, d8
84f1c:	1f 03 00 71	cmp	w24, #0x0
84f20:	68 14 00 90	adrp	x8, 652 ; 0x310000
84f24:	00 61 46 fd	ldr	d0, [x8, #0xcc0]
84f28:	01 10 63 1e	fmov	d1, #6.00000000
84f2c:	2d 0c 60 1e	fcsel	d13, d1, d0, eq
84f30:	c8 17 00 b0	adrp	x8, 761 ; 0x37d000
84f34:	18 5d 44 f9	ldr	x24, [x8, #0x8b8] ; Objc selector ref: objectAtIndexedSubscript:
84f38:	48 09 68 1e	fmul	d8, d10, d8
84f3c:	39 13 43 f9	ldr	x25, [x25, #0x620]
84f40:	e0 02 62 9e	scvtf	d0, x23
84f44:	a0 09 60 1e	fmul	d0, d13, d0
84f48:	8b 29 60 1e	fadd	d11, d12, d0
84f4c:	60 6a 7c f8	ldr	x0, [x19, x28]
84f50:	e1 03 18 aa	mov	x1, x24
84f54:	e2 03 17 aa	mov	x2, x23
...
85030:	34 9f 09 94	bl	0x2ecd00 ; Objc message: -[x0 objectAtIndexedSubscript:]
85034:	60 6a 78 f8	ldr	x0, [x19, x24]
85038:	c8 17 00 90	adrp	x8, 760 ; 0x37d000
8503c:	16 09 45 f9	ldr	x22, [x8, #0xa10] ; Objc selector ref: setFrame:
85040:	e1 03 16 aa	mov	x1, x22
85044:	2f 9f 09 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
85048:	c8 17 00 d0	adrp	x8, 762 ; 0x37f000
8504c:	08 61 8c b9	ldrsw	x8, [x8, #0xc60]
85050:	78 6a 68 38	ldrb	w24, [x19, x8]
...
85088:	48 14 00 f0	adrp	x8, 651 ; 0x310000
8508c:	08 01 34 91	add	x8, x8, #0xd00
85090:	00 59 7a fc	ldr	d0, [x8, w26, uxtw #3]
85094:	01 10 61 1e	fmov	d1, #3.00000000
85098:	61 09 61 1e	fmul	d1, d11, d1
8509c:	00 28 61 1e	fadd	d0, d0, d1
850a0:	40 39 60 1e	fsub	d0, d10, d0
850a4:	0c 08 68 1e	fmul	d12, d0, d8
850a8:	20 39 6b 1e	fsub	d0, d9, d11
850ac:	09 08 68 1e	fmul	d9, d0, d8
850b0:	1f 03 00 71	cmp	w24, #0x0
850b4:	48 14 00 f0	adrp	x8, 651 ; 0x310000
850b8:	00 61 46 fd	ldr	d0, [x8, #0xcc0]
850bc:	01 10 63 1e	fmov	d1, #6.00000000
850c0:	2d 0c 60 1e	fcsel	d13, d1, d0, eq
850c4:	c8 17 00 90	adrp	x8, 760 ; 0x37d000
850c8:	18 5d 44 f9	ldr	x24, [x8, #0x8b8] ; Objc selector ref: objectAtIndexedSubscript:
850cc:	68 09 68 1e	fmul	d8, d11, d8
850d0:	39 13 43 f9	ldr	x25, [x25, #0x620]
850d4:	e0 02 62 9e	scvtf	d0, x23
850d8:	a0 09 60 1e	fmul	d0, d13, d0
~~~

### CBSlotPillView.updateBoundsSize

Native12 IMP 0x85184, original104 IMP 0x83f90

~~~text
...
851b0:	68 6a 74 38	ldrb	w8, [x19, x20]
851b4:	1f 01 00 71	cmp	w8, #0x0
851b8:	48 0a e8 d2	mov	x8, #0x4052000000000000
851bc:	00 01 67 9e	fmov	d0, x8
851c0:	88 0a e8 d2	mov	x8, #0x4054000000000000
851c4:	10 00 00 14	b	0x85204
851c8:	c8 17 00 d0	adrp	x8, 762 ; 0x37f000
...
851e0:	1f 01 00 71	cmp	w8, #0x0
851e4:	a9 00 00 34	cbz	w9, 0x851f8
851e8:	08 0a e8 d2	mov	x8, #0x4050000000000000
851ec:	00 01 67 9e	fmov	d0, x8
851f0:	68 0a e8 d2	mov	x8, #0x4053000000000000
851f4:	04 00 00 14	b	0x85204
851f8:	68 08 e8 d2	mov	x8, #0x4043000000000000
851fc:	00 01 67 9e	fmov	d0, x8
85200:	c8 08 e8 d2	mov	x8, #0x4046000000000000
85204:	01 01 67 9e	fmov	d1, x8
85208:	22 0c 60 1e	fcsel	d2, d1, d0, eq
8520c:	00 70 66 1e	fmov	d0, #19.00000000
85210:	01 d0 66 1e	fmov	d1, #22.00000000
85214:	23 0c 60 1e	fcsel	d3, d1, d0, eq
85218:	c8 17 00 90	adrp	x8, 760 ; 0x37d000
8521c:	01 7d 47 f9	ldr	x1, [x8, #0xef8] ; Objc selector ref: setBounds:
85220:	e0 03 67 9e	fmov	d0, xzr
85224:	e1 03 67 9e	fmov	d1, xzr
85228:	e0 03 13 aa	mov	x0, x19
8522c:	b5 9e 09 94	bl	0x2ecd00 ; Objc message: -[x0 setBounds:]
85230:	68 6a 74 38	ldrb	w8, [x19, x20]
85234:	1f 01 00 71	cmp	w8, #0x0
85238:	00 50 64 1e	fmov	d0, #9.00000000
8523c:	01 b0 64 1e	fmov	d1, #10.50000000
85240:	20 0c 60 1e	fcsel	d0, d1, d0, eq
85244:	c8 17 00 d0	adrp	x8, 762 ; 0x37f000
85248:	00 69 44 f9	ldr	x0, [x8, #0x8d0] ; Objc class ref: _OBJC_CLASS_$_UIImageSymbolConfiguration

Full bounded updateBoundsSize CFG for distinguishing size branches:

85184:	f6 57 bd a9	stp	x22, x21, [sp, #-0x30]!
85188:	f4 4f 01 a9	stp	x20, x19, [sp, #0x10]
8518c:	fd 7b 02 a9	stp	x29, x30, [sp, #0x20]
85190:	fd 83 00 91	add	x29, sp, #0x20
85194:	f3 03 00 aa	mov	x19, x0
85198:	c8 17 00 d0	adrp	x8, 762 ; 0x37f000
8519c:	08 59 8c b9	ldrsw	x8, [x8, #0xc58]
851a0:	08 68 68 38	ldrb	w8, [x0, x8]
851a4:	28 01 00 34	cbz	w8, 0x851c8
851a8:	c8 17 00 d0	adrp	x8, 762 ; 0x37f000
851ac:	14 61 8c b9	ldrsw	x20, [x8, #0xc60]
851b0:	68 6a 74 38	ldrb	w8, [x19, x20]
851b4:	1f 01 00 71	cmp	w8, #0x0
851b8:	48 0a e8 d2	mov	x8, #0x4052000000000000
851bc:	00 01 67 9e	fmov	d0, x8
851c0:	88 0a e8 d2	mov	x8, #0x4054000000000000
851c4:	10 00 00 14	b	0x85204
851c8:	c8 17 00 d0	adrp	x8, 762 ; 0x37f000
851cc:	08 5d 8c b9	ldrsw	x8, [x8, #0xc5c]
851d0:	69 6a 68 38	ldrb	w9, [x19, x8]
851d4:	c8 17 00 d0	adrp	x8, 762 ; 0x37f000
851d8:	14 61 8c b9	ldrsw	x20, [x8, #0xc60]
851dc:	68 6a 74 38	ldrb	w8, [x19, x20]
851e0:	1f 01 00 71	cmp	w8, #0x0
851e4:	a9 00 00 34	cbz	w9, 0x851f8
851e8:	08 0a e8 d2	mov	x8, #0x4050000000000000
851ec:	00 01 67 9e	fmov	d0, x8
851f0:	68 0a e8 d2	mov	x8, #0x4053000000000000
851f4:	04 00 00 14	b	0x85204
851f8:	68 08 e8 d2	mov	x8, #0x4043000000000000
851fc:	00 01 67 9e	fmov	d0, x8
85200:	c8 08 e8 d2	mov	x8, #0x4046000000000000
85204:	01 01 67 9e	fmov	d1, x8
85208:	22 0c 60 1e	fcsel	d2, d1, d0, eq
8520c:	00 70 66 1e	fmov	d0, #19.00000000
85210:	01 d0 66 1e	fmov	d1, #22.00000000
85214:	23 0c 60 1e	fcsel	d3, d1, d0, eq
85218:	c8 17 00 90	adrp	x8, 760 ; 0x37d000
8521c:	01 7d 47 f9	ldr	x1, [x8, #0xef8] ; Objc selector ref: setBounds:
85220:	e0 03 67 9e	fmov	d0, xzr
85224:	e1 03 67 9e	fmov	d1, xzr
85228:	e0 03 13 aa	mov	x0, x19
8522c:	b5 9e 09 94	bl	0x2ecd00 ; Objc message: -[x0 setBounds:]
85230:	68 6a 74 38	ldrb	w8, [x19, x20]
85234:	1f 01 00 71	cmp	w8, #0x0
85238:	00 50 64 1e	fmov	d0, #9.00000000
8523c:	01 b0 64 1e	fmov	d1, #10.50000000
85240:	20 0c 60 1e	fcsel	d0, d1, d0, eq
85244:	c8 17 00 d0	adrp	x8, 762 ; 0x37f000
85248:	00 69 44 f9	ldr	x0, [x8, #0x8d0] ; Objc class ref: _OBJC_CLASS_$_UIImageSymbolConfiguration
8524c:	c8 17 00 90	adrp	x8, 760 ; 0x37d000
85250:	01 65 47 f9	ldr	x1, [x8, #0xec8] ; Objc selector ref: configurationWithPointSize:weight:
85254:	e2 00 80 52	mov	w2, #0x7
85258:	aa 9e 09 94	bl	0x2ecd00 ; Objc message: +[UIImageSymbolConfiguration configurationWithPointSize:weight:]
8525c:	fd 03 1d aa	mov	x29, x29
85260:	c0 9e 09 94	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
85264:	f4 03 00 aa	mov	x20, x0
85268:	c8 17 00 d0	adrp	x8, 762 ; 0x37f000
8526c:	00 21 44 f9	ldr	x0, [x8, #0x840] ; Objc class ref: _OBJC_CLASS_$_UIImage
85270:	c8 17 00 90	adrp	x8, 760 ; 0x37d000
85274:	01 69 47 f9	ldr	x1, [x8, #0xed0] ; Objc selector ref: systemImageNamed:withConfiguration:
85278:	42 17 00 d0	adrp	x2, 746 ; 0x36f000
8527c:	42 a0 35 91	add	x2, x2, #0xd68 ; Objc cfstring ref: @"arrow.up.left.and.arrow.down.right"
85280:	e3 03 14 aa	mov	x3, x20
85284:	9f 9e 09 94	bl	0x2ecd00 ; Objc message: +[UIImage systemImageNamed:withConfiguration:]
85288:	fd 03 1d aa	mov	x29, x29
8528c:	b5 9e 09 94	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
85290:	f5 03 00 aa	mov	x21, x0
85294:	c8 17 00 d0	adrp	x8, 762 ; 0x37f000
85298:	08 71 8c b9	ldrsw	x8, [x8, #0xc70]
8529c:	60 6a 68 f8	ldr	x0, [x19, x8]
852a0:	c8 17 00 90	adrp	x8, 760 ; 0x37d000
852a4:	01 6d 47 f9	ldr	x1, [x8, #0xed8] ; Objc selector ref: setImage:forState:
852a8:	e2 03 15 aa	mov	x2, x21
852ac:	03 00 80 d2	mov	x3, #0x0
852b0:	94 9e 09 94	bl	0x2ecd00 ; Objc message: -[x0 setImage:forState:]
852b4:	c8 17 00 90	adrp	x8, 760 ; 0x37d000
852b8:	01 81 47 f9	ldr	x1, [x8, #0xf00] ; Objc selector ref: setNeedsLayout
852bc:	e0 03 13 aa	mov	x0, x19
852c0:	90 9e 09 94	bl	0x2ecd00 ; Objc message: -[x0 setNeedsLayout]
852c4:	c8 17 00 90	adrp	x8, 760 ; 0x37d000
852c8:	01 85 47 f9	ldr	x1, [x8, #0xf08] ; Objc selector ref: layoutIfNeeded
852cc:	e0 03 13 aa	mov	x0, x19
852d0:	8c 9e 09 94	bl	0x2ecd00 ; Objc message: -[x0 layoutIfNeeded]
852d4:	e0 03 15 aa	mov	x0, x21
852d8:	96 9e 09 94	bl	0x2ecd30 ; symbol stub for: _objc_release
852dc:	e0 03 14 aa	mov	x0, x20
852e0:	fd 7b 42 a9	ldp	x29, x30, [sp, #0x20]
852e4:	f4 4f 41 a9	ldp	x20, x19, [sp, #0x10]
852e8:	f6 57 c3 a8	ldp	x22, x21, [sp], #0x30
852ec:	91 9e 09 14	b	0x2ecd30 ; symbol stub for: _objc_release
~~~

### CBSlotPillView.pointInside:withEvent:

Native12 IMP 0x85348, original104 IMP 0x84154

~~~text
...
853ac:	01 d9 44 f9	ldr	x1, [x8, #0x9b0] ; Objc selector ref: bounds
853b0:	e0 03 13 aa	mov	x0, x19
853b4:	53 9e 09 94	bl	0x2ecd00 ; Objc message: -[x0 bounds]
853b8:	04 10 74 1e	fmov	d4, #-8.00000000
853bc:	00 28 64 1e	fadd	d0, d0, d4
853c0:	04 90 74 1e	fmov	d4, #-10.00000000
853c4:	21 28 64 1e	fadd	d1, d1, d4
853c8:	04 10 66 1e	fmov	d4, #16.00000000
853cc:	42 28 64 1e	fadd	d2, d2, d4
853d0:	04 90 66 1e	fmov	d4, #20.00000000
853d4:	63 28 64 1e	fadd	d3, d3, d4
853d8:	24 1d a9 4e	mov.16b	v4, v9
853dc:	05 1d a8 4e	mov.16b	v5, v8
853e0:	fd 7b 42 a9	ldp	x29, x30, [sp, #0x20]
853e4:	f4 4f 41 a9	ldp	x20, x19, [sp, #0x10]
853e8:	e9 23 c3 6c	ldp	d9, d8, [sp], #0x30
853ec:	2b 9d 09 14	b	0x2ec898 ; symbol stub for: _CGRectContainsPoint
~~~

### CBDividerView.layoutSubviews

Native12 IMP 0xff410, original104 IMP 0x106648

~~~text
No bounded method evidence available
~~~

### CBDividerView.updateGripLayout

Native12 IMP 0xff460, original104 IMP 0x1066c4

~~~text
...
ff4bc:	88 10 00 f0	adrp	x8, 531 ; 0x312000
ff4c0:	01 45 42 fd	ldr	d1, [x8, #0x488]
ff4c4:	00 20 61 1e	fcmp	d0, d1
ff4c8:	00 d0 67 1e	fmov	d0, #30.00000000
ff4cc:	01 90 67 1e	fmov	d1, #28.00000000
ff4d0:	28 4c 60 1e	fcsel	d8, d1, d0, mi
ff4d4:	08 14 00 90	adrp	x8, 640 ; 0x37f000
ff4d8:	1b f5 8d b9	ldrsw	x27, [x8, #0xdf4]
...
ff504:	09 5d 44 f9	ldr	x9, [x8, #0x8b8] ; Objc selector ref: objectAtIndexedSubscript:
ff508:	e8 13 00 f0	adrp	x8, 639 ; 0x37e000
ff50c:	17 61 44 f9	ldr	x23, [x8, #0x8c0] ; Objc selector ref: relativePos
ff510:	0b 10 6c 1e	fmov	d11, #0.50000000
ff514:	0c 09 6b 1e	fmul	d12, d8, d11
ff518:	e8 13 00 d0	adrp	x8, 638 ; 0x37d000
ff51c:	08 09 45 f9	ldr	x8, [x8, #0xa10] ; Objc selector ref: setFrame:
ff520:	e8 a7 00 a9	stp	x8, x9, [sp, #0x8]
ff524:	39 13 43 f9	ldr	x25, [x25, #0x620]
ff528:	0d 10 62 1e	fmov	d13, #4.00000000
ff52c:	0e 10 72 1e	fmov	d14, #-4.00000000
ff530:	0f 10 6e 1e	fmov	d15, #1.00000000
ff534:	60 6a 7c f8	ldr	x0, [x19, x28]
ff538:	e1 03 1a aa	mov	x1, x26
ff53c:	f1 b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff540:	bf 02 00 eb	cmp	x21, x0
ff544:	a2 0d 00 54	b.hs	0xff6f8
ff548:	f8 03 1b aa	mov	x24, x27
...
ff550:	fb 0b 40 f9	ldr	x27, [sp, #0x10]
ff554:	e1 03 1b aa	mov	x1, x27
ff558:	e2 03 15 aa	mov	x2, x21
ff55c:	e9 b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff560:	fd 03 1d aa	mov	x29, x29
ff564:	ff b5 07 94	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
ff568:	fa 03 00 aa	mov	x26, x0
...
ff570:	60 6a 7c f8	ldr	x0, [x19, x28]
ff574:	e1 03 1b aa	mov	x1, x27
ff578:	e2 03 15 aa	mov	x2, x21
ff57c:	e1 b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff580:	fd 03 1d aa	mov	x29, x29
ff584:	f7 b5 07 94	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
ff588:	fb 03 00 aa	mov	x27, x0
ff58c:	e0 03 1a aa	mov	x0, x26
ff590:	e1 03 17 aa	mov	x1, x23
ff594:	db b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff598:	08 20 60 1e	fcmp	d0, #0.0
ff59c:	69 1d ab 4e	mov.16b	v9, v11
ff5a0:	6b 01 00 54	b.lt	0xff5cc
ff5a4:	e0 03 1a aa	mov	x0, x26
ff5a8:	e1 03 17 aa	mov	x1, x23
ff5ac:	d5 b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff5b0:	00 20 6f 1e	fcmp	d0, d15
ff5b4:	69 1d ab 4e	mov.16b	v9, v11
ff5b8:	a8 00 00 54	b.hi	0xff5cc
ff5bc:	e0 03 1a aa	mov	x0, x26
ff5c0:	e1 03 17 aa	mov	x1, x23
ff5c4:	cf b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff5c8:	09 1c a0 4e	mov.16b	v9, v0
ff5cc:	fc 03 17 aa	mov	x28, x23
ff5d0:	e8 0f 40 f9	ldr	x8, [sp, #0x18]
ff5d4:	77 6a 68 38	ldrb	w23, [x19, x8]
ff5d8:	e0 03 13 aa	mov	x0, x19
ff5dc:	e1 03 14 aa	mov	x1, x20
ff5e0:	c8 b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff5e4:	37 03 00 34	cbz	w23, 0xff648
ff5e8:	20 09 63 1e	fmul	d0, d9, d3
ff5ec:	00 38 6c 1e	fsub	d0, d0, d12
ff5f0:	09 48 6d 1e	fmax	d9, d0, d13
ff5f4:	0a 29 69 1e	fadd	d10, d8, d9
ff5f8:	e0 03 13 aa	mov	x0, x19
ff5fc:	e1 03 14 aa	mov	x1, x20
ff600:	c0 b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff604:	60 28 6e 1e	fadd	d0, d3, d14
ff608:	40 21 60 1e	fcmp	d10, d0
ff60c:	cd 00 00 54	b.le	0xff624
ff610:	e0 03 13 aa	mov	x0, x19
ff614:	e1 03 14 aa	mov	x1, x20
ff618:	ba b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff61c:	60 28 6e 1e	fadd	d0, d3, d14
ff620:	09 38 68 1e	fsub	d9, d0, d8
ff624:	e0 03 13 aa	mov	x0, x19
ff628:	e1 03 14 aa	mov	x1, x20
ff62c:	b5 b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff630:	40 38 68 1e	fsub	d0, d2, d8
ff634:	00 08 6b 1e	fmul	d0, d0, d11
ff638:	00 40 62 1e	fcvt	s0, d0
ff63c:	00 40 26 1e	frinta	s0, s0
ff640:	0a c0 22 1e	fcvt	d10, s0
ff644:	18 00 00 14	b	0xff6a4
ff648:	20 09 62 1e	fmul	d0, d9, d2
ff64c:	00 38 6c 1e	fsub	d0, d0, d12
ff650:	0a 48 6d 1e	fmax	d10, d0, d13
ff654:	09 29 6a 1e	fadd	d9, d8, d10
ff658:	e0 03 13 aa	mov	x0, x19
ff65c:	e1 03 14 aa	mov	x1, x20
ff660:	a8 b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff664:	40 28 6e 1e	fadd	d0, d2, d14
ff668:	20 21 60 1e	fcmp	d9, d0
ff66c:	cd 00 00 54	b.le	0xff684
ff670:	e0 03 13 aa	mov	x0, x19
ff674:	e1 03 14 aa	mov	x1, x20
ff678:	a2 b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff67c:	40 28 6e 1e	fadd	d0, d2, d14
ff680:	0a 38 68 1e	fsub	d10, d0, d8
ff684:	e0 03 13 aa	mov	x0, x19
ff688:	e1 03 14 aa	mov	x1, x20
ff68c:	9d b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff690:	60 38 68 1e	fsub	d0, d3, d8
ff694:	00 08 6b 1e	fmul	d0, d0, d11
ff698:	00 40 62 1e	fcvt	s0, d0
ff69c:	00 40 26 1e	frinta	s0, s0
ff6a0:	09 c0 22 1e	fcvt	d9, s0
ff6a4:	f7 03 1c aa	mov	x23, x28
ff6a8:	e0 03 1b aa	mov	x0, x27
ff6ac:	e1 07 40 f9	ldr	x1, [sp, #0x8]
...
ff6b4:	21 1d a9 4e	mov.16b	v1, v9
ff6b8:	02 1d a8 4e	mov.16b	v2, v8
ff6bc:	03 1d a8 4e	mov.16b	v3, v8
ff6c0:	90 b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff6c4:	e0 03 1b aa	mov	x0, x27
ff6c8:	9a b5 07 94	bl	0x2ecd30 ; symbol stub for: _objc_release
ff6cc:	e0 03 1a aa	mov	x0, x26
...
ff6d8:	fb 03 18 aa	mov	x27, x24
ff6dc:	60 6a 78 f8	ldr	x0, [x19, x24]
ff6e0:	e1 03 19 aa	mov	x1, x25
ff6e4:	87 b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff6e8:	fa 03 19 aa	mov	x26, x25
ff6ec:	bf 02 00 eb	cmp	x21, x0
ff6f0:	fc 03 16 aa	mov	x28, x22

Full bounded divider grip layout for frame register tracing:

ff460:	ff 03 03 d1	sub	sp, sp, #0xc0
ff464:	ef 3b 02 6d	stp	d15, d14, [sp, #0x20]
ff468:	ed 33 03 6d	stp	d13, d12, [sp, #0x30]
ff46c:	eb 2b 04 6d	stp	d11, d10, [sp, #0x40]
ff470:	e9 23 05 6d	stp	d9, d8, [sp, #0x50]
ff474:	fc 6f 06 a9	stp	x28, x27, [sp, #0x60]
ff478:	fa 67 07 a9	stp	x26, x25, [sp, #0x70]
ff47c:	f8 5f 08 a9	stp	x24, x23, [sp, #0x80]
ff480:	f6 57 09 a9	stp	x22, x21, [sp, #0x90]
ff484:	f4 4f 0a a9	stp	x20, x19, [sp, #0xa0]
ff488:	fd 7b 0b a9	stp	x29, x30, [sp, #0xb0]
ff48c:	fd c3 02 91	add	x29, sp, #0xb0
ff490:	f3 03 00 aa	mov	x19, x0
ff494:	08 14 00 90	adrp	x8, 640 ; 0x37f000
ff498:	08 e9 8d b9	ldrsw	x8, [x8, #0xde8]
ff49c:	e8 0f 00 f9	str	x8, [sp, #0x18]
ff4a0:	15 68 68 38	ldrb	w21, [x0, x8]
ff4a4:	e8 13 00 d0	adrp	x8, 638 ; 0x37d000
ff4a8:	14 d9 44 f9	ldr	x20, [x8, #0x9b0] ; Objc selector ref: bounds
ff4ac:	e1 03 14 aa	mov	x1, x20
ff4b0:	14 b6 07 94	bl	0x2ecd00 ; Objc message: -[x0 bounds]
ff4b4:	bf 02 00 71	cmp	w21, #0x0
ff4b8:	40 0c 63 1e	fcsel	d0, d2, d3, eq
ff4bc:	88 10 00 f0	adrp	x8, 531 ; 0x312000
ff4c0:	01 45 42 fd	ldr	d1, [x8, #0x488]
ff4c4:	00 20 61 1e	fcmp	d0, d1
ff4c8:	00 d0 67 1e	fmov	d0, #30.00000000
ff4cc:	01 90 67 1e	fmov	d1, #28.00000000
ff4d0:	28 4c 60 1e	fcsel	d8, d1, d0, mi
ff4d4:	08 14 00 90	adrp	x8, 640 ; 0x37f000
ff4d8:	1b f5 8d b9	ldrsw	x27, [x8, #0xdf4]
ff4dc:	60 6a 7b f8	ldr	x0, [x19, x27]
ff4e0:	f9 13 00 d0	adrp	x25, 638 ; 0x37d000
ff4e4:	3a 13 43 f9	ldr	x26, [x25, #0x620] ; Objc selector ref: count
ff4e8:	e1 03 1a aa	mov	x1, x26
ff4ec:	05 b6 07 94	bl	0x2ecd00 ; Objc message: -[x0 count]
ff4f0:	40 10 00 b4	cbz	x0, 0xff6f8
ff4f4:	15 00 80 d2	mov	x21, #0x0
ff4f8:	08 14 00 90	adrp	x8, 640 ; 0x37f000
ff4fc:	1c f1 8d b9	ldrsw	x28, [x8, #0xdf0]
ff500:	e8 13 00 d0	adrp	x8, 638 ; 0x37d000
ff504:	09 5d 44 f9	ldr	x9, [x8, #0x8b8] ; Objc selector ref: objectAtIndexedSubscript:
ff508:	e8 13 00 f0	adrp	x8, 639 ; 0x37e000
ff50c:	17 61 44 f9	ldr	x23, [x8, #0x8c0] ; Objc selector ref: relativePos
ff510:	0b 10 6c 1e	fmov	d11, #0.50000000
ff514:	0c 09 6b 1e	fmul	d12, d8, d11
ff518:	e8 13 00 d0	adrp	x8, 638 ; 0x37d000
ff51c:	08 09 45 f9	ldr	x8, [x8, #0xa10] ; Objc selector ref: setFrame:
ff520:	e8 a7 00 a9	stp	x8, x9, [sp, #0x8]
ff524:	39 13 43 f9	ldr	x25, [x25, #0x620]
ff528:	0d 10 62 1e	fmov	d13, #4.00000000
ff52c:	0e 10 72 1e	fmov	d14, #-4.00000000
ff530:	0f 10 6e 1e	fmov	d15, #1.00000000
ff534:	60 6a 7c f8	ldr	x0, [x19, x28]
ff538:	e1 03 1a aa	mov	x1, x26
ff53c:	f1 b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff540:	bf 02 00 eb	cmp	x21, x0
ff544:	a2 0d 00 54	b.hs	0xff6f8
ff548:	f8 03 1b aa	mov	x24, x27
ff54c:	60 6a 7b f8	ldr	x0, [x19, x27]
ff550:	fb 0b 40 f9	ldr	x27, [sp, #0x10]
ff554:	e1 03 1b aa	mov	x1, x27
ff558:	e2 03 15 aa	mov	x2, x21
ff55c:	e9 b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff560:	fd 03 1d aa	mov	x29, x29
ff564:	ff b5 07 94	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
ff568:	fa 03 00 aa	mov	x26, x0
ff56c:	f6 03 1c aa	mov	x22, x28
ff570:	60 6a 7c f8	ldr	x0, [x19, x28]
ff574:	e1 03 1b aa	mov	x1, x27
ff578:	e2 03 15 aa	mov	x2, x21
ff57c:	e1 b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff580:	fd 03 1d aa	mov	x29, x29
ff584:	f7 b5 07 94	bl	0x2ecd60 ; symbol stub for: _objc_retainAutoreleasedReturnValue
ff588:	fb 03 00 aa	mov	x27, x0
ff58c:	e0 03 1a aa	mov	x0, x26
ff590:	e1 03 17 aa	mov	x1, x23
ff594:	db b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff598:	08 20 60 1e	fcmp	d0, #0.0
ff59c:	69 1d ab 4e	mov.16b	v9, v11
ff5a0:	6b 01 00 54	b.lt	0xff5cc
ff5a4:	e0 03 1a aa	mov	x0, x26
ff5a8:	e1 03 17 aa	mov	x1, x23
ff5ac:	d5 b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff5b0:	00 20 6f 1e	fcmp	d0, d15
ff5b4:	69 1d ab 4e	mov.16b	v9, v11
ff5b8:	a8 00 00 54	b.hi	0xff5cc
ff5bc:	e0 03 1a aa	mov	x0, x26
ff5c0:	e1 03 17 aa	mov	x1, x23
ff5c4:	cf b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff5c8:	09 1c a0 4e	mov.16b	v9, v0
ff5cc:	fc 03 17 aa	mov	x28, x23
ff5d0:	e8 0f 40 f9	ldr	x8, [sp, #0x18]
ff5d4:	77 6a 68 38	ldrb	w23, [x19, x8]
ff5d8:	e0 03 13 aa	mov	x0, x19
ff5dc:	e1 03 14 aa	mov	x1, x20
ff5e0:	c8 b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff5e4:	37 03 00 34	cbz	w23, 0xff648
ff5e8:	20 09 63 1e	fmul	d0, d9, d3
ff5ec:	00 38 6c 1e	fsub	d0, d0, d12
ff5f0:	09 48 6d 1e	fmax	d9, d0, d13
ff5f4:	0a 29 69 1e	fadd	d10, d8, d9
ff5f8:	e0 03 13 aa	mov	x0, x19
ff5fc:	e1 03 14 aa	mov	x1, x20
ff600:	c0 b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff604:	60 28 6e 1e	fadd	d0, d3, d14
ff608:	40 21 60 1e	fcmp	d10, d0
ff60c:	cd 00 00 54	b.le	0xff624
ff610:	e0 03 13 aa	mov	x0, x19
ff614:	e1 03 14 aa	mov	x1, x20
ff618:	ba b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff61c:	60 28 6e 1e	fadd	d0, d3, d14
ff620:	09 38 68 1e	fsub	d9, d0, d8
ff624:	e0 03 13 aa	mov	x0, x19
ff628:	e1 03 14 aa	mov	x1, x20
ff62c:	b5 b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff630:	40 38 68 1e	fsub	d0, d2, d8
ff634:	00 08 6b 1e	fmul	d0, d0, d11
ff638:	00 40 62 1e	fcvt	s0, d0
ff63c:	00 40 26 1e	frinta	s0, s0
ff640:	0a c0 22 1e	fcvt	d10, s0
ff644:	18 00 00 14	b	0xff6a4
ff648:	20 09 62 1e	fmul	d0, d9, d2
ff64c:	00 38 6c 1e	fsub	d0, d0, d12
ff650:	0a 48 6d 1e	fmax	d10, d0, d13
ff654:	09 29 6a 1e	fadd	d9, d8, d10
ff658:	e0 03 13 aa	mov	x0, x19
ff65c:	e1 03 14 aa	mov	x1, x20
ff660:	a8 b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff664:	40 28 6e 1e	fadd	d0, d2, d14
ff668:	20 21 60 1e	fcmp	d9, d0
ff66c:	cd 00 00 54	b.le	0xff684
ff670:	e0 03 13 aa	mov	x0, x19
ff674:	e1 03 14 aa	mov	x1, x20
ff678:	a2 b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff67c:	40 28 6e 1e	fadd	d0, d2, d14
ff680:	0a 38 68 1e	fsub	d10, d0, d8
ff684:	e0 03 13 aa	mov	x0, x19
ff688:	e1 03 14 aa	mov	x1, x20
ff68c:	9d b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff690:	60 38 68 1e	fsub	d0, d3, d8
ff694:	00 08 6b 1e	fmul	d0, d0, d11
ff698:	00 40 62 1e	fcvt	s0, d0
ff69c:	00 40 26 1e	frinta	s0, s0
ff6a0:	09 c0 22 1e	fcvt	d9, s0
ff6a4:	f7 03 1c aa	mov	x23, x28
ff6a8:	e0 03 1b aa	mov	x0, x27
ff6ac:	e1 07 40 f9	ldr	x1, [sp, #0x8]
ff6b0:	40 1d aa 4e	mov.16b	v0, v10
ff6b4:	21 1d a9 4e	mov.16b	v1, v9
ff6b8:	02 1d a8 4e	mov.16b	v2, v8
ff6bc:	03 1d a8 4e	mov.16b	v3, v8
ff6c0:	90 b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff6c4:	e0 03 1b aa	mov	x0, x27
ff6c8:	9a b5 07 94	bl	0x2ecd30 ; symbol stub for: _objc_release
ff6cc:	e0 03 1a aa	mov	x0, x26
ff6d0:	98 b5 07 94	bl	0x2ecd30 ; symbol stub for: _objc_release
ff6d4:	b5 06 00 91	add	x21, x21, #0x1
ff6d8:	fb 03 18 aa	mov	x27, x24
ff6dc:	60 6a 78 f8	ldr	x0, [x19, x24]
ff6e0:	e1 03 19 aa	mov	x1, x25
ff6e4:	87 b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 setFrame:]
ff6e8:	fa 03 19 aa	mov	x26, x25
ff6ec:	bf 02 00 eb	cmp	x21, x0
ff6f0:	fc 03 16 aa	mov	x28, x22
ff6f4:	03 f2 ff 54	b.lo	0xff534
ff6f8:	fd 7b 4b a9	ldp	x29, x30, [sp, #0xb0]
ff6fc:	f4 4f 4a a9	ldp	x20, x19, [sp, #0xa0]
ff700:	f6 57 49 a9	ldp	x22, x21, [sp, #0x90]
ff704:	f8 5f 48 a9	ldp	x24, x23, [sp, #0x80]
ff708:	fa 67 47 a9	ldp	x26, x25, [sp, #0x70]
ff70c:	fc 6f 46 a9	ldp	x28, x27, [sp, #0x60]
ff710:	e9 23 45 6d	ldp	d9, d8, [sp, #0x50]
ff714:	eb 2b 44 6d	ldp	d11, d10, [sp, #0x40]
ff718:	ed 33 43 6d	ldp	d13, d12, [sp, #0x30]
ff71c:	ef 3b 42 6d	ldp	d15, d14, [sp, #0x20]
ff720:	ff 03 03 91	add	sp, sp, #0xc0
ff724:	c0 03 5f d6	ret
~~~

### CBDividerView.pointInside:withEvent:

Native12 IMP 0xff728, original104 IMP 0x10698c

~~~text
...
ff858:	1b 01 40 f9	ldr	x27, [x8]
ff85c:	88 10 00 d0	adrp	x8, 530 ; 0x311000
ff860:	0b a5 44 fd	ldr	d11, [x8, #0x948]
ff864:	0a 10 75 1e	fmov	d10, #-12.00000000
ff868:	1c 00 80 d2	mov	x28, #0x0
ff86c:	e8 13 00 f0	adrp	x8, 639 ; 0x37e000
ff870:	19 b1 42 f9	ldr	x25, [x8, #0x560] ; Objc selector ref: frame
...
ff8c8:	0e b5 07 94	bl	0x2ecd00 ; Objc message: -[x0 frame]
ff8cc:	44 1d aa 4e	mov.16b	v4, v10
ff8d0:	45 1d aa 4e	mov.16b	v5, v10
ff8d4:	09 b4 07 94	bl	0x2ec8f8 ; symbol stub for: _CGRectInset
ff8d8:	24 1d a9 4e	mov.16b	v4, v9
ff8dc:	05 1d a8 4e	mov.16b	v5, v8
ff8e0:	ee b3 07 94	bl	0x2ec898 ; symbol stub for: _CGRectContainsPoint
ff8e4:	e0 03 00 37	tbnz	w0, #0x0, 0xff960
ff8e8:	9c 07 00 91	add	x28, x28, #0x1
ff8ec:	1f 03 1c eb	cmp	x24, x28
...
ff92c:	08 e9 8d b9	ldrsw	x8, [x8, #0xde8]
ff930:	88 6a 68 38	ldrb	w8, [x20, x8]
ff934:	1f 01 00 71	cmp	w8, #0x0
ff938:	05 10 74 1e	fmov	d5, #-8.00000000
ff93c:	e6 03 67 9e	fmov	d6, xzr
ff940:	c4 0c 65 1e	fcsel	d4, d6, d5, eq
ff944:	a5 0c 66 1e	fcsel	d5, d5, d6, eq
ff948:	ec b3 07 94	bl	0x2ec8f8 ; symbol stub for: _CGRectInset
ff94c:	24 1d a9 4e	mov.16b	v4, v9
ff950:	05 1d a8 4e	mov.16b	v5, v8
ff954:	d1 b3 07 94	bl	0x2ec898 ; symbol stub for: _CGRectContainsPoint
ff958:	f4 03 00 aa	mov	x20, x0
ff95c:	9b ff ff 17	b	0xff7c8
ff960:	e0 03 17 aa	mov	x0, x23
~~~

**Acceptance still pending:** proven point frame sizes and physical CarPlay
display, divider hit-test and scene layout; do not alter approved Native12.
