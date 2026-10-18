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
- `initWithFrame:`: Native12 `not in catalog`; original104 `not in catalog`. Native selector refs: ``. Arithmetic/control samples: 0.
- `layoutSubviews`: Native12 `0x84c30`; original104 `0x83a10`. Native selector refs: `layoutSubviews, -[[x0 super] layoutSubviews], bounds, -[x0 bounds], layer, -[x0 layer], setCornerRadius:, -[x0 setCornerRadius:], setHidden:, -[x0 setHidden:], setFrame:, -[x0 setFrame:], count, -[x0 count], objectAtIndexedSubscript:`. Arithmetic/control samples: 40.
- `updateLayout`: Native12 `not in catalog`; original104 `not in catalog`. Native selector refs: ``. Arithmetic/control samples: 0.

### CBDividerView
- `initWithFrame:`: Native12 `not in catalog`; original104 `not in catalog`. Native selector refs: ``. Arithmetic/control samples: 0.
- `layoutSubviews`: Native12 `0xff410`; original104 `0x106648`. Native selector refs: `layoutSubviews, -[[x0 super] layoutSubviews], updateGripLayout, -[x0 updateGripLayout]`. Arithmetic/control samples: 0.
- `updateGripLayout`: Native12 `0xff460`; original104 `0x1066c4`. Native selector refs: `bounds, -[x0 bounds], count, -[x0 count], objectAtIndexedSubscript:, relativePos, setFrame:, -[x0 setFrame:]`. Arithmetic/control samples: 31.
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

## Interpretation and implementation order

1. Use actual Native12 PNG hashes/dimensions and approve asset choice. Never infer UIButton size from PNG pixel size.
2. Recover Native12 class-specific layout, hit rectangles and gestures from the bounded disassembly above; prove owner/selector version by version.
3. Map each component to the independent DuoFace owner in the table; test view-tree, menu actions, scene launch and geometry in isolation.
4. Combine source-owned view and scene binding after per-component proof. No copy of original vendor license/classes or postinst.
5. Actual rects, safe area and visual equivalence still require the user's parked CarPlay screenshot/runtime log. No Sileo release from this audit.
