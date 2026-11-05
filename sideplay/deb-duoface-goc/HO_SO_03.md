  - - `setPendingCompletion:` — types `v24@0:8@?16` — IMP `0x6f04`
  - - `stateChanged` — types `@?16@0:8` — IMP `0x6f0c`
  - - `setStateChanged:` — types `v24@0:8@?16` — IMP `0x6f14`
  - - `ownsFullscreen` — types `B16@0:8` — IMP `0x6f1c`
  - - `setOwnsFullscreen:` — types `v20@0:8B16` — IMP `0x6f24`
  - - `desiredExpanded` — types `B16@0:8` — IMP `0x6f2c`
  - - `setDesiredExpanded:` — types `v20@0:8B16` — IMP `0x6f34`
  - - `timer` — types `@16@0:8` — IMP `0x6f3c`
  - - `setTimer:` — types `v24@0:8@16` — IMP `0x6f44`
  - - `leaseOwner` — types `@16@0:8` — IMP `0x6f50`
  - - `setLeaseOwner:` — types `v24@0:8@16` — IMP `0x6f58`
  - - `leaseDeadline` — types `d16@0:8` — IMP `0x6f60`
  - - `setLeaseDeadline:` — types `v24@0:8d16` — IMP `0x6f68`
  - - `lastSequences` — types `@16@0:8` — IMP `0x6f70`
  - - `setLastSequences:` — types `v24@0:8@16` — IMP `0x6f78`
  - - `.cxx_destruct` — types `v16@0:8` — IMP `0x6f84`

#### DFZoomAction
- Superclass: `NSObject` · địa chỉ class struct (arm64): `0x14e98` · instanceSize: 8 · flags: `0x80`
- Instance methods (1):
  - - `pressed:` — types `v24@0:8@16` — IMP `0x80ac`

#### DFZoomReceiver
- Superclass: `NSObject` · địa chỉ class struct (arm64): `0x14ee8` · instanceSize: 8 · flags: `0x80`
- Instance methods (1):
  - - `received:` — types `v24@0:8@16` — IMP `0x9b78`

### 4.4 DuoFaceVisualHook.dylib và duoface_cboptimize_helper

- VisualHook: **0 class ObjC** (không có `__objc_classlist`) — toàn bộ là hàm C, xem mục 5.4 và bảng hook 6.3.
- Helper: **0 class ObjC**, thuần C — xem mục 5.5.
- Cả 4 binary ObjC đều có **0 category** (`__objc_catlist` rỗng) → không binary nào hook bằng category; mọi hook đều qua MSHookMessageEx/MSHookFunction lúc chạy (mục 6) [A].

## 5. Symbols C/C++ và imports

### 5.1 Defined symbols — DuoFaceUI (78)

Symbol class/metaclass `_OBJC_CLASS_$_*`/`_OBJC_METACLASS_$_*` cho đủ 27 class ở mục 4.1, cộng các symbol dữ liệu/hàm sau:

- `_CBAppsListUpdatedNotification`
- `_CBLanguageChangedNotification`
- `_CBLocTable_ar`
- `_CBLocTable_de`
- `_CBLocTable_en`
- `_CBLocTable_es`
- `_CBLocTable_fr`
- `_CBLocTable_hi`
- `_CBLocTable_id`
- `_CBLocTable_it`
- `_CBLocTable_ja`
- `_CBLocTable_ko`
- `_CBLocTable_ms`
- `_CBLocTable_nl`
- `_CBLocTable_pl`
- `_CBLocTable_pt`
- `_CBLocTable_ru`
- `_CBLocTable_th`
- `_CBLocTable_tr`
- `_CBLocTable_vi`
- `_CBLocTable_zh`
- `_CBLocTable_zh_Hant`
- `__mh_execute_header`
- `_main`

(20 bảng chuỗi bản địa hoá `CBLocTable_<lang>` cho 20 ngôn ngữ: ar, de, en, es, fr, hi, id, it, ja, ko, ms, nl, pl, pt, ru, th, tr, vi, zh, zh_Hant — cùng bộ bảng này cũng nhúng trong Dashboard qua class `CBLocalization`.)

### 5.2 Defined symbols — Dashboard

**Không có.** Symtab slice arm64 gồm 295 symbol, 100% là undefined/import (mục 3.2). Mọi khám phá về Dashboard dựa vào metadata ObjC + strings + disassembly.

### 5.3 Defined symbols — FullscreenBridge (23)

4 class + metaclass (mục 4.3) và 14 hàm C API (đây là bề mặt API công khai của Bridge) [A]:

- `_DFDashboardRestoreChrome`
- `_DFDashboardSetChromeHidden`
- `_DFHostCanExpand`
- `_DFHostIsExpanded`
- `_DFHostRestore`
- `_DFHostSetExpanded`
- `_DFHostSetLifecycleCallback`
- `_DFInstallDashboardChromeHooks`
- `_DFInstallHostGeometryHooks`
- `_DFInstallPickerZoomMenuHooks`
- `_DFPickerZoomMenuRefresh`
- `_DFQueryFullscreenHost`
- `_DFRequestHostFullscreen`
- `_DFStartFullscreenAdapter`
- `_DFStartFullscreenTransport`

### 5.4 Defined symbols — VisualHook (121)

Gồm các hàm hook (IMP đích, đối chiếu mục 6.3), hàm layout thay thế, hàm tiện ích và biến toàn cục (địa chỉ là slice arm64):

- `0x6094` [t] `_DFApplyButton`
- `0xc263` [b] `_DFBorderHooksInstalled`
- `0x5dac` [t] `_DFBorderLogoRed`
- `0x5260` [t] `_DFBorderStartHook`
- `0x5308` [t] `_DFBorderStopHook`
- `0x4d74` [t] `_DFDividerLayout`
- `0xc2d9` [b] `_DFFocusAssociation`
- `0x599c` [t] `_DFFocusHidden`
- `0x5708` [t] `_DFFocusSlotHook`
- `0x660c` [t] `_DFImage`
- `0xc2e0` [b] `_DFImage.cache`
- `0x4030` [t] `_DFImageAdded`
- `0x4000` [t] `_DFInit`
- `0x408c` [t] `_DFInstall`
- `0xc264` [b] `_DFInstall.triedLibrary`
- `0x4518` [t] `_DFInstallBorderRunner`
- `0x59d0` [t] `_DFKnownBorderViewsFor`
- `0xc2da` [b] `_DFKnownBorderViewsKey`
- `0xc2a8` [b] `_DFNativeBorderStart`
- `0xc2b0` [b] `_DFNativeBorderStop`
- `0xc2c8` [b] `_DFNativeFocusSlot`
- `0xc2d0` [b] `_DFNativeRestoreSplit`
- `0xc2b8` [b] `_DFNativeSessionStart`
- `0xc2c0` [b] `_DFNativeSessionStop`
- `0xc2a0` [b] `_DFNativeSplitLayout`
- `0x6564` [t] `_DFObjectIvar`
- `0x4a9c` [t] `_DFPillLayout`
- `0x5b60` [t] `_DFRemoveLegacyBorderEffects`
- `0x577c` [t] `_DFRestoreSplitHook`
- `0xc2d8` [b] `_DFRunningAssociation`
- `0x53c8` [t] `_DFSessionStartHook`
- `0x5568` [t] `_DFSessionStopHook`
- `0x5a40` [t] `_DFSetBorderVisible`
- `0x43d8` [t] `_DFSetButtonBackgroundColor`
- `0x44a4` [t] `_DFSetLayerBorderColor`
- `0x4444` [t] `_DFSetLayerBorderWidth`
- `0x4f64` [t] `_DFSplashLayout`
- `0x5224` [t] `_DFSplitLayoutHook`
- `0x5ed8` [t] `_DFTrackBorderView`
- `0x57e0` [t] `_DFUpdateFocusBorders`
- `0x5df0` [t] `___DFBorderStartHook_block_invoke`
- `0x5fd8` [t] `___DFBorderStopHook_block_invoke`
- `0x43b0` [t] `___DFImageAdded_block_invoke`
- `0x4064` [t] `___DFInit_block_invoke`
- `0x8120` [s] `___block_descriptor_32_e5_v8?0l`
- `0x8180` [s] `___block_descriptor_48_e8_32o40o_e5_v8?0l`
- `0x8140` [s] `___block_literal_global`
- `0x8160` [s] `___block_literal_global.1`
- `0x5f38` [t] `___copy_helper_block_e8_32o40o`
- `0x5f94` [t] `___destroy_helper_block_e8_32o40o`
- `0xc261` [b] `_dividerInstalled`
- `0xc2dc` [b] `_fullscreenLogged`
- `0xc2dd` [b] `_kOverlayKey`
- `0xc298` [b] `_kVisualOnlyKey`
- `0x6820` [s] `_objc_msgSend$CGColor`
- `0x6840` [s] `_objc_msgSend$addObject:`
- `0x6860` [s] `_objc_msgSend$addObjectsFromArray:`
- `0x6880` [s] `_objc_msgSend$addSubview:`
- `0x68a0` [s] `_objc_msgSend$allObjects`
- `0x68c0` [s] `_objc_msgSend$arrayWithArray:`
- `0x68e0` [s] `_objc_msgSend$arrayWithObject:`
- `0x6900` [s] `_objc_msgSend$backgroundImageForState:`
- `0x6920` [s] `_objc_msgSend$begin`
- `0x6940` [s] `_objc_msgSend$blackColor`
- `0x6960` [s] `_objc_msgSend$boolValue`
- `0x6980` [s] `_objc_msgSend$bounds`
- `0x69a0` [s] `_objc_msgSend$bringSubviewToFront:`
- `0x69c0` [s] `_objc_msgSend$clearColor`
- `0x69e0` [s] `_objc_msgSend$colorWithRed:green:blue:alpha:`
- `0x6a00` [s] `_objc_msgSend$commit`
- `0x6a20` [s] `_objc_msgSend$count`
- `0x6a40` [s] `_objc_msgSend$countByEnumeratingWithState:objects:count:`
- `0x6a60` [s] `_objc_msgSend$imageView`
- `0x6a80` [s] `_objc_msgSend$imageWithContentsOfFile:`
- `0x6aa0` [s] `_objc_msgSend$initWithFrame:`
- `0x6ac0` [s] `_objc_msgSend$isEqualToString:`
- `0x6ae0` [s] `_objc_msgSend$isMainThread`
- `0x6b00` [s] `_objc_msgSend$lastObject`
- `0x6b20` [s] `_objc_msgSend$layer`
- `0x6b40` [s] `_objc_msgSend$objectForKey:`
- `0x6b60` [s] `_objc_msgSend$removeAllAnimations`
- `0x6b80` [s] `_objc_msgSend$removeAnimationForKey:`
- `0x6ba0` [s] `_objc_msgSend$removeFromSuperlayer`
- `0x6bc0` [s] `_objc_msgSend$removeLastObject`
- `0x6be0` [s] `_objc_msgSend$setAutoresizingMask:`
- `0x6c00` [s] `_objc_msgSend$setBackgroundColor:`
- `0x6c20` [s] `_objc_msgSend$setBackgroundImage:forState:`
- `0x6c40` [s] `_objc_msgSend$setBorderColor:`
- `0x6c60` [s] `_objc_msgSend$setBorderWidth:`
- `0x6c80` [s] `_objc_msgSend$setClipsToBounds:`
- `0x6ca0` [s] `_objc_msgSend$setContentMode:`
- `0x6cc0` [s] `_objc_msgSend$setCornerRadius:`
- `0x6ce0` [s] `_objc_msgSend$setDisableActions:`
- `0x6d00` [s] `_objc_msgSend$setFrame:`
- `0x6d20` [s] `_objc_msgSend$setHidden:`
- `0x6d40` [s] `_objc_msgSend$setImage:`
- `0x6d60` [s] `_objc_msgSend$setIsAccessibilityElement:`
- `0x6d80` [s] `_objc_msgSend$setObject:forKey:`
- `0x6da0` [s] `_objc_msgSend$setShadowColor:`
- `0x6dc0` [s] `_objc_msgSend$setShadowOffset:`
- `0x6de0` [s] `_objc_msgSend$setShadowOpacity:`
- `0x6e00` [s] `_objc_msgSend$setShadowRadius:`
- `0x6e20` [s] `_objc_msgSend$setUserInteractionEnabled:`
- `0x6e40` [s] `_objc_msgSend$stringByAppendingString:`
- `0x6e60` [s] `_objc_msgSend$sublayers`
- `0x6e80` [s] `_objc_msgSend$subviews`
- `0x6ea0` [s] `_objc_msgSend$text`
- `0x6ec0` [s] `_objc_msgSend$weakObjectsHashTable`
- `0x6ee0` [s] `_objc_msgSend$zPosition`
- `0xc268` [b] `_oldButtonSetBackgroundColor`
- `0xc288` [b] `_oldDividerLayout`
- `0xc278` [b] `_oldLayerSetBorderColor`
- `0xc270` [b] `_oldLayerSetBorderWidth`
- `0xc280` [b] `_oldPillLayout`
- `0xc290` [b] `_oldSplashLayout`
- `0xc2db` [b] `_pickerLogged`
- `0xc260` [b] `_pillInstalled`
- `0xc262` [b] `_splashInstalled`
- `0xc2e9` [b] `_splashLogged`
- `0xc2e8` [b] `_swapLogged`
- `0xc265` [b] `_visualSetterHooksInstalled`

### 5.5 Defined symbols — Helper (2)

- `__mh_execute_header`, `_main` — ngoài ra không còn gì (thuần C, đã strip).

### 5.6 Imports tiêu biểu theo binary (bằng chứng năng lực) [A]

| Binary | Imports đáng chú ý | Ý nghĩa |
|---|---|---|
| DuoFaceUI | CFNotificationCenter (Darwin) Add/Post/RemoveObserver, notify_post, SecItem Add/CopyMatching/Update (Keychain), IORegistryEntryCreateCFProperty + IOServiceMatching (định danh phần cứng), posix_spawn, sysctl/sysctlbyname, objc_getClass | App: nghe/phát Darwin notification, lưu license vào Keychain, lấy ID phần cứng, chạy tiến trình con |
| Dashboard | **MSHookFunction, MSHookMessageEx** (CydiaSubstrate), CFNotificationCenter Darwin + notify_post + **notify_register_dispatch**, **sqlite3_open/exec/close**, dlopen/dlsym, SecItem (Keychain), IORegistry, sysctl, class_addMethod, method_getTypeEncoding, objc_getClass | Dylib lõi: hook ObjC + hook hàm C, IPC Darwin 2 chiều, ghi TCC.db bằng SQL, tự nạp framework lúc chạy |
| Bridge | **MSHookMessageEx**, objc_getClass (chỉ 2 import "động" này ngoài các import ObjC/Foundation thường) | Chỉ hook method ObjC; không hook hàm C, không sqlite, không Darwin-API trực tiếp (IPC qua ObjC/Darwin qua CFNotification qua Foundation) |
| VisualHook | dlopen, dlsym, objc_getClass, method_getNumberOfArguments, method_getTypeEncoding — **không có MSHook\*** trong bảng import | Tự resolve MSHookMessageEx bằng dlsym từ libsubstrate nạp động; kiểm tra chữ ký method trước khi hook |
| Helper | IORegistryEntryCreateCFProperty, IOServiceMatching, sysctlbyname, posix_spawn, setuid, setgid, waitpid, access | Lấy định danh phần cứng; chạy cboptimize qua shell với đổi uid/gid |

Danh sách import đầy đủ (undefined symbols) của từng binary nằm trong các file `work/nmu_*.txt` đi kèm bộ dữ liệu quét (DuoFaceUI 214, Dashboard 295, Bridge 80, VisualHook 51, Helper 36). Các class hệ thống được tham chiếu (classrefs đã resolve qua bind table/chained imports): DuoFaceUI 66 class ngoài, Dashboard 75, Bridge 21 ngoài + 4 nội bộ, VisualHook 13.

## 6. Bảng hook đầy đủ

### 6.1 Dashboard — 243 điểm gọi hook trong constructor (240 MSHookMessageEx + 3 MSHookFunction)

Toàn bộ nằm trong thân constructor chính tại `0x2a803c` (vùng 0x2ac6bc–0x2b30ec). Bảng dưới trích từ disassembly slice arm64: Class/Selector là giá trị nạp vào x0/x1 ngay trước điểm gọi (theo dõi provenance thanh ghi trên disassembly đã annotate của llvm-objdump) — mức bằng chứng **[A]** cho từng dòng có đủ Class+Selector. IMP = địa chỉ hàm hook thay thế; Orig = ô nhớ lưu IMP gốc.

| # | Class đích | Selector | IMP hook | Ô orig |
|---:|---|---|---|---|
| 1 | `UIViewController` | `supportedInterfaceOrientations` | `0x2acc04` | `0x381d00` |
| 2 | `UIViewController` | `__supportedInterfaceOrientations` | `0x2acc60` | `0x381d08` |
| 3 | `UIWindow` | `setFrame:` | `0x2accbc` | `0x381d10` |
| 4 | `UIWindow` | `setBounds:` | `0x2acdd8` | `0x381d18` |
| 5 | `UIWindow` | `_setRotatableViewOrientation:duration:force:` | `0x2acef4` | `0x381d20` |
| 6 | `UIWindow` | `sendEvent:` | `0x2acf64` | `0x381d28` |
| 7 | `UIWindow` | `_rotateWindowToOrientation:updateStatusBar:duration:skipCallbacks:` | `0x2acfd8` | `0x381d30` |
| 8 | `UIApplication` | `applicationState` | `0x2ad054` | `0x381d38` |
| 9 | `UIApplication` | `statusBarOrientation` | `0x2ad09c` | `0x381d40` |
| 10 | `UIApplication` | `isIdleTimerDisabled` | `0x2ad0ec` | `0x381d48` |
| 11 | `UIApplication` | `setIdleTimerDisabled:` | `0x2ad134` | `0x381d50` |
| 12 | `UIScene` | `activationState` | `0x2ad178` | `0x381d58` |
| 13 | `CADisplayLink` | `setPaused:` | `0x2ad1c0` | `0x381d60` |
| 14 | `CADisplayLink` | `isPaused` | `0x2ad204` | `0x381d68` |
| 15 | `CADisplayLink` | `setPreferredFramesPerSecond:` | `0x2ad24c` | `0x381d70` |
| 16 | `CADisplayLink` | `setPreferredFrameRateRange:` | `0x2ad2e0` | `0x381d78` |
| 17 | `MTKView` | `setPreferredFramesPerSecond:` | `0x2ad3ac` | `0x381d80` |
| 18 | `NSNotificationCenter` | `postNotificationName:object:userInfo:` | `0x2ad440` | `0x381d88` |
| 19 | `NSNotificationCenter` | `postNotification:` | `0x2ad594` | `0x381d90` |
| 20 | `FBSSceneSettings` | `isOccluded` | `0x2ad6d0` | `0x381d98` |
| 21 | `FBSSceneSettings` | `deactivationReasons` | `0x2ad718` | `0x381da0` |
| 22 | `UIApplicationSceneSettings` | `isUnderLock` | `0x2ad760` | `0x381da8` |
| 23 | `UIApplicationSceneSettings` | `canShowWhileLocked` | `0x2ad7a8` | `0x381db0` |
| 24 | `UIWindowScene` | `interfaceOrientation` | `0x2ad7f0` | `0x381db8` |
| 25 | `UIWindowScene` | `_isSuspended` | `0x2ad840` | `0x381dc0` |
| 26 | `UIWindowScene` | `_isDeactivated` | `0x2ad888` | `0x381dc8` |
| 27 | `UIDevice` | `orientation` | `0x2ad8d0` | `0x381dd0` |
| 28 | `UIDevice` | `setOrientation:animated:` | `0x2ad920` | `0x381dd8` |
| 29 | `UIDevice` | `setOrientation:` | `0x2ad980` | `0x381de0` |
| 30 | `UIScreen` | `_userInterfaceIdiom` | `0x2ad9d8` | `0x381de8` |
| 31 | `UIScreen` | `bounds` | `0x2ada20` | `0x381df0` |
| 32 | `UIScreen` | `nativeBounds` | `0x2adaec` | `0x381df8` |
| 33 | `UIScreen` | `_referenceBounds` | `0x2adbfc` | `0x381e00` |
| 34 | `UIScreenMode` | `size` | `0x2adcc8` | `0x381e08` |
| 35 | `UIWindowSceneGeometry` | `interfaceOrientation` | `0x2add18` | `0x381e10` |
| 36 | `UIWindowScene` | `requestGeometryUpdateWithPreferences:errorHandler:` | `0x2add84` | `0x381e18` |
| 37 | `UIInputSetContainerView` | `layoutSubviews` | `0x2ae6f8` | `0x381e30` |
| 38 | `UIInputSetHostView` | `layoutSubviews` | `0x2ae8f0` | `0x381e38` |
| 39 | `UIKeyboard` | `setFrame:` | `0x2ae9b0` | `0x381e40` |
| 40 | `UIKeyboard` | `setBounds:` | `0x2aea2c` | `0x381e48` |
| 41 | `UIKeyboard` | `layoutSubviews` | `0x2aeaa8` | `0x381e50` |
| 42 | `UIKeyboard (metaclass)` | `defaultSizeForInterfaceOrientation:` | `0x2aebf8` | `0x381e58` |
| 43 | `UIKeyboard` | `defaultSizeForInterfaceOrientation:` | `0x2aeca8` | `0x381e60` |
| 44 | `UIKeyboardInputMode` | `isEqualToString:` | `0x2aed58` | `0x381e68` |
| 45 | `UIKeyboardImpl` | `inputMode` | `0x2aee78` | `0x381e70` |
| 46 | `UIKeyboardImpl` | `inputModePreference` | `0x2aeecc` | `0x381e78` |
| 47 | `UIKeyboardImpl` | `inputModeIdentifier` | `0x2aef20` | `0x381e80` |
| 48 | `UIKeyboardImpl` | `keyboardName` | `0x2aefbc` | `0x381e88` |
| 49 | `UIKeyboardImpl` | `keyplaneName` | `0x2af164` | `0x381e90` |
| 50 | `UIKeyboardImpl` | `setDelegate:force:` | `0x2af20c` | `0x381e98` |
| 51 | `UIKeyboardImpl` | `isInHardwareKeyboardMode` | `0x2af3a4` | `0x381ea0` |
| 52 | `UIKeyboardImpl (metaclass)` | `isInHardwareKeyboardMode` | `0x2af3ec` | `0x381ea8` |
| 53 | `UIKeyboardImpl` | `isHardwareKeyboardAttached` | `0x2af434` | `0x381eb0` |
| 54 | `UIKeyboardImpl (metaclass)` | `isHardwareKeyboardAttached` | `0x2af47c` | `0x381eb8` |
| 55 | `UIKeyboardImpl` | `automaticMinimizationEnabled` | `0x2af4c4` | `0x381ec0` |
| 56 | `UIKeyboardImpl` | `showsSoftwareKeyboard` | `0x2af50c` | `0x381ec8` |
| 57 | `UIKeyboardImpl` | `softwareKeyboardAllowedForFirstResponder:` | `0x2af554` | `0x381ed0` |
| 58 | `UIKeyboardImpl` | `showKeyboard` | `0x2af5c0` | `0x381ed8` |
| 59 | `UIKeyboardImpl (metaclass)` | `defaultSizeForInterfaceOrientation:` | `0x2af63c` | `0x381ee0` |
| 60 | `UIKeyboardImpl (metaclass)` | `_defaultSizeForInterfaceOrientation:` | `0x2af6ec` | `0x381ee8` |
| 61 | `UIKeyboardImpl (metaclass)` | `keyboardSizeForInterfaceOrientation:` | `0x2af79c` | `0x381ef0` |
| 62 | `UIKeyboardImpl (metaclass)` | `sizeForInterfaceOrientation:` | `0x2af84c` | `0x381ef8` |
| 63 | `UIKeyboardImpl (metaclass)` | `keyboardWidthForScreen:withOrientation:` | `0x2af8fc` | `0x381f00` |
| 64 | `UIKeyboardImpl` | `defaultSizeForInterfaceOrientation:` | `0x2af980` | `0x381f08` |
| 65 | `UIPeripheralHost` | `getWidthForOrientation:` | `0x2afa30` | `0x381f10` |
| 66 | `UIKBScreenTraits` | `keyboardWidth` | `0x2afa94` | `0x381f18` |
| 67 | `UIKBScreenTraits` | `setKeyboardWidth:` | `0x2afae4` | `0x381f20` |
| 68 | `UIKBScreenTraits` | `bounds` | `0x2afb4c` | `0x381f28` |
| 69 | `UIKBScreenTraits` | `setBounds:` | `0x2afbac` | `0x381f30` |
| 70 | `UIKBScreenTraits` | `keyboardScreenReferenceSize` | `0x2afc3c` | `0x381f38` |
| 71 | `UIKBScreenTraits` | `screenSize` | `0x2afc9c` | `0x381f40` |
| 72 | `UIKBScreenTraits` | `isFloating` | `0x2afcfc` | `0x381f48` |
| 73 | `UIKBScreenTraits` | `supportsSplit` | `0x2afd44` | `0x381f50` |
| 74 | `UIKBScreenTraits` | `isKeyboardSplit` | `0x2afd8c` | `0x381f58` |
| 75 | `UIKBScreenTraits` | `orientation` | `0x2afdd4` | `0x381f60` |
| 76 | `UIKBScreenTraits (metaclass)` | `traitsWithScreen:orientation:` | `0x2afe1c` | `0x381f68` |
| 77 | `UIKeyboardLayoutStar` | `setFrame:` | `0x2afff0` | `0x381f70` |
| 78 | `UIKeyboardLayoutStar` | `setBounds:` | `0x2b006c` | `0x381f78` |
| 79 | `UIKeyboardLayoutStar` | `layoutSubviews` | `0x2b00e8` | `0x381f80` |
| 80 | `UIKeyboardLayoutStar` | `keyboardName` | `0x2b0198` | `0x381f88` |
| 81 | `UIKeyboardLayoutStar` | `setKeyboardName:` | `0x2b0340` | `0x381f90` |
| 82 | `UIKeyboardLayoutStar` | `setKeyboardName:appearance:` | `0x2b053c` | `0x381f98` |
| 83 | `UIKeyboardLayoutStar` | `showKeyboardWithInputTraits:screenTraits:splitTraits:` | `0x2b0750` | `0x381fa0` |
| 84 | `UIKeyboardLayoutStar` | `keyplaneName` | `0x2b0d08` | `0x381fa8` |
| 85 | `UIKeyboardLayoutStar` | `setKeyplaneName:` | `0x2b0db0` | `0x381fb0` |
| 86 | `UIKeyboardInputModeController` | `currentInputMode` | `0x2b0e88` | `0x381fb8` |
| 87 | `UIKeyboardInputModeController` | `activeInputModes` | `0x2b0ef0` | `0x381fc0` |
| 88 | `UIResponder` | `textInputMode` | `0x2b0fe0` | `0x381fc8` |
| 89 | `UIResponder` | `becomeFirstResponder` | `0x2b107c` | `0x381fd0` |
| 90 | `UIResponder` | `resignFirstResponder` | `0x2b10f4` | `0x381fd8` |
| 91 | `UIInputWindowController` | `viewWillAppear:` | `0x2b116c` | `0x381fe0` |
| 92 | `UIInputWindowController` | `viewDidAppear:` | `0x2b11e8` | `0x381fe8` |
| 93 | `UIRemoteKeyboardWindow` | `setHidden:` | `0x2b1968` | `0x381ff0` |
| 94 | `UIRemoteKeyboardWindow` | `setAlpha:` | `0x2b19f0` | `0x381ff8` |
| 95 | `UITextEffectsWindow` | `setHidden:` | `0x2b1a50` | `0x382000` |
| 96 | `UITextEffectsWindow` | `setAlpha:` | `0x2b1ad8` | `0x382008` |
| 97 | `AVExternalDevice (metaclass)` | `currentCarPlayExternalDevice` | `0x2b2b08` | `0x382030` |
| 98 | `AVExternalDevice (metaclass)` | `currentExternalDevice` | `0x2b2b60` | `0x382038` |
| 99 | `AVExternalDevice (metaclass)` | `externalDevices` | `0x2b2bb8` | `0x382040` |
| 100 | `AVPlayer` | `setAllowsExternalPlayback:` | `0x2b2c1c` | `0x382048` |
| 101 | `AVPlayer` | `allowsExternalPlayback` | `0x2b2c60` | `0x382050` |
| 102 | `AVPlayer` | `setUsesExternalPlaybackWhileExternalScreenIsActive:` | `0x2b2ca8` | `0x382058` |
| 103 | `AVPlayer` | `usesExternalPlaybackWhileExternalScreenIsActive` | `0x2b2cec` | `0x382060` |
| 104 | `AVPlayer` | `play` | `0x2b2d34` | `0x382068` |
| 105 | `AVPlayer` | `pause` | `0x2b2d78` | `0x382070` |
| 106 | `AVPlayer` | `setRate:` | `0x2b2dbc` | `0x382078` |
| 107 | `AVPlayer` | `dealloc` | `0x2b2e14` | `0x382080` |
| 108 | `AVPlayerItem` | `setAllowsExternalPlayback:` | `0x2b2e58` | `0x382088` |
| 109 | `AVPlayerItem` | `allowsExternalPlayback` | `0x2b2e9c` | `0x382090` |
| 110 | `AVRouteDetector` | `isRouteDetectionEnabled` | `0x2b2ee4` | `0x382098` |
| 111 | `AVRouteDetector` | `setRouteDetectionEnabled:` | `0x2b2f2c` | `0x3820a0` |
| 112 | `AVPictureInPictureController (metaclass)` | `isPictureInPictureSupported` | `0x2b2f70` | `0x3820a8` |
| 113 | `AVPictureInPictureController` | `isPictureInPicturePossible` | `0x2b2fb8` | `0x3820b0` |
| 114 | `MPVolumeView` | `isWirelessRouteActive` | `0x2b3000` | `0x3820b8` |
| 115 | `MPVolumeView` | `areWirelessRoutesAvailable` | `0x2b3048` | `0x3820c0` |
| 116 | `FBScene` | `updateSettings:withTransitionContext:completion:` | `0x2c7e08` | `0x382108` |
| 117 | `FBScene` | `_applyUpdateWithContext:completion:` | `0x2c8410` | `0x382110` |
| 118 | `_UIScenePresentationView` | `scene:didPrepareUpdateWithContext:` | `0x2c85d0` | `0x382118` |
| 119 | `SBSuspendedUnderLockManager` | `interceptUpdateForScene:withNewSettings:` | `0x2c8668` | `0x382120` |
| 120 | `SBSuspendedUnderLockManager` | `_shouldBeBackgroundUnderLockForScene:withSettings:` | `0x2c8768` | `0x382128` |
| 121 | `SBSuspendedUnderLockManager` | `shouldBeUnderLockForScene:` | `0x2c8870` | `0x382130` |
| 122 | `SBDeviceApplicationSceneViewController` | `setContentReferenceSize:withInterfaceOrientation:` | `0x2c895c` | `0x382138` |
| 123 | `SBDeviceApplicationSceneViewController` | `setContentReferenceSize:withContentOrientation:andContainerOrientation:` | `0x2c8a50` | `0x382140` |
| 124 | `SBDeviceApplicationSceneHandle` | `_mainSceneSupportsInterfaceOrientation:` | `0x2c8b4c` | `0x382148` |
| 125 | `SBAppViewController` | `sceneHandle:didUpdateSettingsWithDiff:previousSettings:` | `0x2c8ca8` | `0x382150` |
| 126 | `SBAppViewController` | `sceneHandle:didDestroyScene:` | `0x2c8ef8` | `0x382158` |
| 127 | `FBApplicationProcess` | `_processDidExitWithContext:` | `0x2c98dc` | `0x382180` |
| 128 | `SpringBoard` | `applicationDidFinishLaunching:` | `0x2c9a04` | `0x382188` |
| 129 | `SpringBoard` | `sendEvent:` | `0x2c9a30` | `0x382190` |
| 130 | `_UIStaticScrollBar` | `layoutSubviews` | `0x2ca1fc` | `0x3821a8` |
| 131 | `_UIStaticScrollBar` | `willMoveToSuperview:` | `0x2ca370` | `0x3821b0` |
| 132 | `_UIScrollViewScrollIndicator` | `layoutSubviews` | `0x2ca4d4` | `0x3821b8` |
| 133 | `DBApplicationInfo` | `_loadFromProxy:` | `0x2cb730` | `0x3821c0` |
| 134 | `DBApplicationInfo` | `isCarPlaySupported` | `0x2cb7d8` | `0x3821c8` |
| 135 | `DBApplicationInfo` | `canDisplayOnCarScreen` | `0x2cb898` | `0x3821d0` |
| 136 | `CARApplicationInfo` | `_loadFromProxy:` | `0x2cb958` | `0x3821d8` |
| 137 | `CARApplicationInfo` | `isCarPlaySupported` | `0x2cba00` | `0x3821e0` |
| 138 | `CARApplicationInfo` | `canDisplayOnCarScreen` | `0x2cbac0` | `0x3821e8` |
| 139 | `FBSApplicationLibrary` | `allInstalledApplications` | `0x2cbb80` | `0x3821f0` |
| 140 | `CRCarPlayAppPolicyEvaluator` | `effectivePolicyForAppDeclaration:` | `0x2cc0b0` | `0x3821f8` |
| 141 | `CRCarPlayAppDeclaration (metaclass)` | `declarationForAppProxy:` | `0x2cc3a4` | `0x382200` |
| 142 | `SBIconListView` | `iconColumnsForCurrentOrientation` | `0x2cd12c` | `0x382248` |
| 143 | `SBIconListView` | `iconRowsForCurrentOrientation` | `0x2cd1bc` | `0x382250` |
| 144 | `SBIconListView` | `maximumIconCount` | `0x2cd24c` | `0x382258` |
| 145 | `SBIconListView` | `maxIconCount` | `0x2cd31c` | `0x382260` |
| 146 | `SBIconListView` | `iconImageInfo` | `0x2cd3ec` | `0x382268` |
| 147 | `SBIconListView` | `originForIconIndex:` | `0x2cd408` | `0x382270` |
| 148 | `SBIconListView` | `centerForIconAtIndex:` | `0x2cd5ac` | `0x382278` |
| 149 | `SBIconListView` | `frameForIconAtIndex:` | `0x2cd764` | `0x382280` |
| 150 | `SBIconListView` | `layoutInsetsForOrientation:` | `0x2cd920` | `0x382288` |
| 151 | `SBIconListGridLayout` | `numberOfColumnsForOrientation:` | `0x2cd9c0` | `0x382290` |
| 152 | `SBIconListGridLayout` | `numberOfRowsForOrientation:` | `0x2cda64` | `0x382298` |
| 153 | `SBIconListGridLayout` | `iconImageInfo` | `0x2cdb08` | `0x3822a0` |
| 154 | `SBIconListGridLayout` | `layoutInsetsForOrientation:` | `0x2cdb14` | `0x3822a8` |
| 155 | `SBIconListGridLayoutConfiguration` | `numberOfPortraitColumns` | `0x2cdbb4` | `0x3822b0` |
| 156 | `SBIconListGridLayoutConfiguration` | `numberOfPortraitRows` | `0x2cdc44` | `0x3822b8` |
| 157 | `SBIconListGridLayoutConfiguration` | `numberOfLandscapeColumns` | `0x2cdcd4` | `0x3822c0` |
| 158 | `SBIconListGridLayoutConfiguration` | `numberOfLandscapeRows` | `0x2cdd64` | `0x3822c8` |
| 159 | `SBIconListGridLayoutConfiguration` | `iconImageInfo` | `0x2cddf4` | `0x3822d0` |
| 160 | `SBIconListGridLayoutConfiguration` | `iconImageInfoForGridSizeClass:` | `0x2cde00` | `0x3822d8` |
| 161 | `SBIconListGridLayoutConfiguration` | `landscapeLayoutInsets` | `0x2cde0c` | `0x3822e0` |
| 162 | `SBIconListGridLayoutConfiguration` | `portraitLayoutInsets` | `0x2cde9c` | `0x3822e8` |
| 163 | `SBIconListModel` | `maxNumberOfIcons` | `0x2cdf2c` | `0x3822f0` |
| 164 | `CARIconModel` | `_showInternalApps` | `0x2cf178` | `0x3822f8` |
| 165 | `CARIconModel` | `_showPrototypeApps` | `0x2cf180` | `0x382300` |
| 166 | `CARIconModel` | `hiddenBundleIdentifiers` | `0x2cf188` | `0x382308` |
| 167 | `CARIconModel` | `loadAllIcons` | `0x2cf2cc` | `0x382310` |
| 168 | `SBHIconManager` | `launchIconForIconView:` | `0x2cf8d8` | `0x382318` |
| 169 | `SBHIconManager` | `launchIconForIconView:withActions:` | `0x2cf9dc` | `0x382320` |
| 170 | `SBHIconManager` | `iconTapped:` | `0x2cfb08` | `0x382328` |
| 171 | `SBHIconManager` | `iconTapped:modifierFlags:` | `0x2cfc0c` | `0x382330` |
| 172 | `CARIconManager` | `launchIconForIconView:` | `0x2cfd20` | `0x382338` |
| 173 | `CARIconManager` | `launchIconForIconView:withActions:` | `0x2cfe24` | `0x382340` |
| 174 | `CARIconManager` | `launchIcon:` | `0x2cff50` | `0x382348` |
| 175 | `CARIconManager` | `launchIcon:location:animated:completionHandler:` | `0x2d0058` | `0x382350` |
| 176 | `CARIconManager` | `iconTapped:` | `0x2d01c4` | `0x382358` |
| 177 | `CARIconManager` | `iconTapped:modifierFlags:` | `0x2d02c8` | `0x382360` |
| 178 | `DBIconView` | `configureLabelImageParametersBuilder:` | `0x2d03dc` | `0x382368` |
| 179 | `DBIconView` | `_handleTapGesture:` | `0x2d0794` | `0x382370` |
| 180 | `DBIconView` | `layoutSubviews` | `0x2d09c0` | `0x382378` |
| 181 | `CARIconView` | `configureLabelImageParametersBuilder:` | `0x2d09ec` | `0x382380` |
| 182 | `CARIconView` | `_configureIconImageView:` | `0x2d0da4` | `0x382388` |
| 183 | `CARIconView` | `_handleTapGesture:` | `0x2d0f74` | `0x382390` |
| 184 | `CARIconView` | `layoutSubviews` | `0x2d115c` | `0x382398` |
| 185 | `DBLeafIconDataSource` | `iconDisplayName:forLocation:` | `0x2d1188` | `0x3823a0` |
| 186 | `DBLeafIconDataSource` | `icon:displayNameForLocation:` | `0x2d1340` | `0x3823a8` |
| 187 | `DBLeafIconDataSource` | `icon:imageWithInfo:` | `0x2d14f8` | `0x3823b0` |
| 188 | `CARLeafIconDataSource` | `iconDisplayName:forLocation:` | `0x2d16fc` | `0x3823b8` |
| 189 | `CARLeafIconDataSource` | `icon:displayNameForLocation:` | `0x2d18b4` | `0x3823c0` |
| 190 | `CARLeafIconDataSource` | `icon:imageWithInfo:` | `0x2d1a6c` | `0x3823c8` |
| 191 | `CARLeafIcon` | `displayNameForLocation:` | `0x2d1c70` | `0x3823d0` |
| 192 | `CARLeafIcon` | `displayName` | `0x2d1e08` | `0x3823d8` |
| 193 | `CARLeafIcon` | `iconImageWithInfo:` | `0x2d1f7c` | `0x3823e0` |
| 194 | `CARLeafIcon` | `generateIconImageWithInfo:` | `0x2d2164` | `0x3823e8` |
| 195 | `DBLeafIcon` | `displayNameForLocation:` | `0x2d234c` | `0x3823f0` |
| 196 | `DBLeafIcon` | `displayName` | `0x2d24e4` | `0x3823f8` |
| 197 | `DBLeafIcon` | `iconImageWithInfo:` | `0x2d2658` | `0x382400` |
| 198 | `SBIconView` | `configureLabelImageParametersBuilder:` | `0x2d2840` | `0x382408` |
| 199 | `SBIconView` | `iconImageInfo` | `0x2d2bf8` | `0x382410` |
| 200 | `SBIconView` | `iconImageFrame` | `0x2d2c14` | `0x382418` |
| 201 | `SBIconView` | `iconImageSize` | `0x2d2d98` | `0x382420` |
| 202 | `SBIconView` | `_handleTapGesture:` | `0x2d2e98` | `0x382428` |
| 203 | `SBIconView` | `touchesEnded:withEvent:` | `0x2d3048` | `0x382430` |
| 204 | `SBIconView` | `layoutSubviews` | `0x2d3178` | `0x382438` |
| 205 | `DBRootStatusBarViewController` | `viewDidAppear:` | `0x2e8bbc` | `0x382480` |
| 206 | `DBRootStatusBarViewController` | `viewDidLayoutSubviews` | `0x2e8c00` | `0x382488` |
| 207 | `DBRootStatusBarViewController` | `viewWillDisappear:` | `0x2e8c44` | `0x382490` |
| 208 | `DBRootStatusBarViewController` | `homeButtonUp:` | `0x2e8ca0` | `0x382498` |
| 209 | `CARRootStatusBarViewController` | `viewDidAppear:` | `0x2e8db0` | `0x3824a0` |
| 210 | `CARRootStatusBarViewController` | `viewDidLayoutSubviews` | `0x2e8df4` | `0x3824a8` |
| 211 | `CARRootStatusBarViewController` | `viewWillDisappear:` | `0x2e8e38` | `0x3824b0` |
| 212 | `CARRootStatusBarViewController` | `homeButtonUp:` | `0x2e8e94` | `0x3824b8` |
| 213 | `DBAppDockViewController` | `viewDidAppear:` | `0x2e8fa4` | `0x3824c0` |
| 214 | `DBAppDockViewController` | `viewDidLayoutSubviews` | `0x2e901c` | `0x3824c8` |
| 215 | `DBAppDockViewController` | `_refreshAppDock` | `0x2e9094` | `0x3824d0` |
| 216 | `DBAppDockViewController` | `_dockButtonPressed:` | `0x2e90c0` | `0x3824d8` |
| 217 | `CARAppDockViewController` | `viewDidAppear:` | `0x2e91f0` | `0x3824e0` |
| 218 | `CARAppDockViewController` | `viewDidLayoutSubviews` | `0x2e9268` | `0x3824e8` |
| 219 | `CARAppDockViewController` | `_refreshAppDock` | `0x2e92e0` | `0x3824f0` |
| 220 | `CARAppDockViewController` | `_dockButtonPressed:` | `0x2e930c` | `0x3824f8` |
| 221 | `DashBoard` | `init` | `0x2ea0a4` | `0x382548` |
| 222 | `DashBoard (metaclass)` | `_newApplicationLibrary` | `0x2ea1a8` | `0x382550` |
| 223 | `DashBoard` | `_newApplicationLibrary` | `0x2ea1e0` | `0x382558` |
| 224 | `CARApplication` | `init` | `0x2ea218` | `0x382560` |
| 225 | `CARApplication (metaclass)` | `_newApplicationLibrary` | `0x2ea3bc` | `0x382568` |
| 226 | `CARApplication` | `_newApplicationLibrary` | `0x2ea410` | `0x382570` |
| 227 | `_CARDashboardHomeViewController` | `_setupIconModel` | `0x2ea464` | `0x382578` |
| 228 | `_CARDashboardHomeViewController` | `viewDidAppear:` | `0x2ea5a0` | `0x382580` |
| 229 | `_CARDashboardHomeViewController` | `iconManager:launchIconForIconView:` | `0x2ea6bc` | `0x382588` |
| 230 | `_CARDashboardHomeViewController` | `iconManager:launchIconForIconView:withActions:` | `0x2ea860` | `0x382590` |
| 231 | `_CARDashboardHomeViewController` | `iconManager:launchIcon:` | `0x2eaa28` | `0x382598` |
| 232 | `_CARDashboardHomeViewController` | `iconManager:launchIcon:location:` | `0x2eabcc` | `0x3825a0` |
| 233 | `_CARDashboardHomeViewController` | `iconManager:launchIcon:location:animated:` | `0x2ead94` | `0x3825a8` |
| 234 | `_CARDashboardHomeViewController` | `iconManager:launchIcon:location:animated:completionHandler:` | `0x2eaf60` | `0x3825b0` |
| 235 | `DBRootViewController` | `viewDidAppear:` | `0x2eb158` | `0x3825b8` |
| 236 | `_CARDashboardRootViewController` | `viewDidAppear:` | `0x2eb2f4` | `0x3825c0` |
| 237 | `_CARDashboardRootViewController` | `viewDidLayoutSubviews` | `0x2eb550` | `0x3825c8` |
| 238 | `_CARDashboardRootViewController` | `viewSafeAreaInsetsDidChange` | `0x2eb620` | `0x3825d0` |
| 239 | `DBFocusController` | `takeWithPriority:reason:forWindow:bundleIdentifier:pid:scene:heading:focusedFrame:` | `0x2eb6d8` | `0x3825d8` |
| 240 | `UIApplication` | `sendEvent:` | `0x2eb98c` | `0x3825e0` |

3 hook hàm C (MSHookFunction, đích lấy qua dlopen+dlsym ngay trước điểm gọi) [A]:

| # | Framework nạp động | Symbol đích | IMP hook | Ô orig |
|---:|---|---|---|---|
| 1 | `/System/Library/PrivateFrameworks/GraphicsServices.framework/GraphicsServices` | `GSEventIsHardwareKeyboardAttached` | `0x2b1b38` | `0x382030` |
| 2 | `/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices` | `BKSHIDServicesIsHardwareKeyboardAttached` | `0x2b1ba0` | `0x382038` |
| 3 | `/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices` | `BKSDisplayServicesSetScreenBlanked` | `0x2b31e4` | `0x3820c8` |

Đọc bảng 6.1 theo nhóm (tự nhóm từ selector, vẫn là dữ kiện [A] từng dòng): hook cửa sổ/xoay (UIWindow setFrame:/setBounds:/xoay, UIViewController supportedInterfaceOrientations, UIWindowScene), hook trạng thái sống của app (UIApplication applicationState, UIScene activationState, FBSSceneSettings isOccluded/deactivationReasons, UIApplicationSceneSettings isUnderLock/canShowWhileLocked, SBSuspendedUnderLockManager…), hook bàn phím (UIKeyboard và họ UIInputSet*, 2 hook C về hardware-keyboard, GSEvent/BKSHID), hook media/âm thanh, hook thông báo (NSNotificationCenter postNotificationName:/postNotification:), hook CADisplayLink (setPaused:/isPaused — 2 IMP khác nhau cho cùng selector `isPaused`, tức có biến thể theo điều kiện), và hook các class CarPlay (`CAR*`/`DB*` nếu xuất hiện trong bảng). Việc mỗi hook chỉ "có hiệu lực" trong đúng tiến trình chứa class đích là hệ quả tự nhiên: class không tồn tại trong tiến trình thì objc_getClass trả nil và MSHookMessageEx không gắn được — đây là cơ chế tự-giới-hạn theo tiến trình của Dashboard [C, nhất quán với mẫu gate kiểm tra class ở Bridge].

### 6.2 Bridge — 10 hook MSHookMessageEx (3 cụm cài đặt) [A]

Giải mã từ disassembly: mỗi cụm kiểm tra sự tồn tại của class bằng NSClassFromString/objc_getClass trước khi hook; selector lấy từ bảng selrefs (đã resolve địa chỉ → tên). IMP là hàm static trong Bridge (không có symbol tên).

| Cụm (hàm cài đặt) | Class đích | Selector | IMP hook | Ghi chú |
|---|---|---|---|---|
| Cụm chrome dashboard (gate: `CBWindow`, `CBBridgeManager`, `CBBridgedSplitApp` phải tồn tại) | `CBWindow` (metaclass) | `carPlayUsableBounds` | `0x5828` | x0 qua object_getClass → hook class method |
| ″ | `CBWindow` | `resizeWindows` | `0x5880` | |
| ″ | `CBWindow` | `show` | `0x58fc` | |
| ″ | `CBWindow` | `hide:` | `0x5984` | |
| ″ | `CBWindow` | `destroyWindows` | `0x5ab8` | |
| ″ | `CBBridgeManager` | `deactivateCurrentApp` | `0x5b3c` | |
| Cụm menu zoom của picker (gate: `DBStatusBarWindow`, `CARStatusBarWindow`) | `DBStatusBarWindow` | `layoutSubviews` | `0x8054` | cửa sổ status bar của Dashboard (tiến trình CarPlay) |
| ″ | `CARStatusBarWindow` | `layoutSubviews` | `0x8080` | cửa sổ status bar CarPlay gốc |
| Cụm overlay đa nhiệm (gate: `CBMultitaskingOverlayView`) | `CBMultitaskingOverlayView` | `setupCardContent` | `0x8498` | |
| ″ | `CBMultitaskingOverlayView` | `layoutSubviews` | `0x84c4` | |

Cả 10 hook đều nhắm vào **class của chính Dashboard** (`CBWindow`, `CBBridgeManager`, `CBMultitaskingOverlayView`) hoặc cửa sổ status bar — Bridge không hook hành vi app thứ ba; nó nắn hình học/chrome của tầng Dashboard từ phía tiến trình CarPlay/SpringBoard [A].

### 6.3 VisualHook — hook qua MSHookMessageEx nạp động [A]

Hàm `_DFInstall` (0x408c): thử `dlsym(RTLD_DEFAULT, "MSHookMessageEx")` trước; nếu chưa có thì `dlopen("/var/jb/usr/lib/libsubstrate.dylib")`, dự phòng `dlopen("/usr/lib/libsubstrate.dylib")`, rồi dlsym. Cờ `_DFInstall.triedLibrary` chống thử lại; cờ `_DFBorderHooksInstalled` chống cài trùng. Sau đó gọi con trỏ hàm đã resolve (blr) cho từng hook:

| Class đích | Selector | IMP hook (có symbol) | Ô orig |
|---|---|---|---|
| `UIButton` | `setBackgroundColor:` | `_DFSetButtonBackgroundColor` (0x43d8) | `0xc268` |
| `CALayer` | `setBorderWidth:` | `_DFSetLayerBorderWidth` (0x4444) | (biến orig tương ứng) |
| `CALayer` | `setBorderColor:` | `_DFSetLayerBorderColor` (0x44a4) | (biến orig tương ứng) |
| `CBSlotPillView` | `layoutSubviews` | `_DFPillLayout` (0x4a9c) | — |
| `CBDividerView` | `layoutSubviews` | `_DFDividerLayout` (0x4d74) | — |
| `CBSplitSplashScreenView` | `layoutSubviews` | `_DFSplashLayout` (0x4f64) | — |
| `CBBridgedSplitApp` | `layoutSubviews` | `_DFSplitLayoutHook` (0x5224) | `_DFNativeSplitLayout` |

Nhóm hook "border/session" (hàm `_DFInstallBorderRunner` 0x4518 + các IMP `_DFBorderStartHook` 0x5260, `_DFBorderStopHook` 0x5308, `_DFSessionStartHook` 0x53c8, `_DFSessionStopHook` 0x5568, `_DFFocusSlotHook` 0x5708, `_DFRestoreSplitHook` 0x577c; ô orig là các biến `_DFNativeBorderStart/Stop`, `_DFNativeSessionStart/Stop`, `_DFNativeFocusSlot`, `_DFNativeRestoreSplit`): các selector đích là method **của chính `CBBridgedSplitApp`** (đã đối chiếu: cả 6 selector đều tồn tại trong bảng method của CBBridgedSplitApp ở Dashboard, mục 4.2) [A cho selector + IMP; B cho việc gán class đích là CBBridgedSplitApp vì điểm gọi cài đặt của nhóm này không mang literal tên class riêng — nó dùng class đã lấy ở `_DFInstall`]:

| Selector đích (trên CBBridgedSplitApp) | IMP hook |
|---|---|
| `startContainerBorderBlinking:` | `_DFBorderStartHook` |
| `stopContainerBorderBlinking:` | `_DFBorderStopHook` |
| `startBlinkingSession` | `_DFSessionStartHook` |
| `stopBlinkingSession` | `_DFSessionStopHook` |
| `focusSlot:animated:` | `_DFFocusSlotHook` |
| `restoreSplitAnimated:` | `_DFRestoreSplitHook` |

Trước khi hook nhóm border, VisualHook **kiểm tra type encoding** của method đích bằng `method_getTypeEncoding`/`method_getNumberOfArguments` so với mẫu (`v24@0:8@16`, `B`, `Q`, `c`, `q` là các literal encoding trong code) — không khớp thì bỏ qua và ghi log `[DuoFaceBorder] signature mismatch start=%s stop=%s` [A].

## 7. Chuỗi quan trọng (strings) — IPC, preferences, endpoint, đường dẫn, log

### 7.1 Tên Darwin notification / kênh IPC [A — chuỗi + import CFNotificationCenter Darwin/notify_*]

| Tên | Nơi xuất hiện | Vai trò (theo ngữ cảnh chuỗi/method) |
|---|---|---|
| `com.duoface.fullscreen.command.v1` | Bridge | Kênh lệnh fullscreen (Dashboard → Bridge): DFFullscreenTransport có method `send:enabled:requestID:`, `post:info:` |
| `com.duoface.fullscreen.state.v1` | Bridge | Kênh trạng thái fullscreen (Bridge → Dashboard): method `publish:client:reason:`, `handleState:`, thuộc tính lease (leaseOwner/leaseDeadline/sequence) |
| `com.duoface.fullscreen.picker.v1` | Bridge | Kênh liên quan picker/zoom menu của Bridge |
| `com.duoface.license.sync` | DuoFaceUI + Dashboard | Định danh liên quan đồng bộ license (cũng là tên của global notification trong app; CBLicenseSyncManager tồn tại ở cả app và Dashboard) |
| `com.duoface.http.client` | DuoFaceUI + Dashboard | Định danh của CBHttpClient (cả hai binary đều chứa class này) |
| `CBAppsListUpdatedNotification`, `CBLanguageChangedNotification` | DuoFaceUI (symbol defined dạng dữ liệu) | Notification nội bộ app (NSNotificationCenter thường, không phải Darwin) |

Ngoài ra Dashboard import `notify_register_dispatch` + `notify_post` (libnotify thuần) — tên token notify_* cụ thể không xuất hiện dạng chuỗi rõ trong strings đã trích → xem mục 10.

### 7.2 Endpoint / URL [A]

- Đường dẫn API license: **`/api/v1/license/sync`** (trong DuoFaceUI). **Hostname không xuất hiện dạng literal** trong strings của bất kỳ binary nào → host có thể được ghép lúc chạy hoặc lấy từ cấu hình; xem mục 10.
- Nhận dạng giọng nói: `https://www.google.com/speech-api/v2/recognize?client=chromium&lang=vi-VN&key=%@&maxresults=5&pFilter=0` (Dashboard) — API key truyền qua tham số `key=%@`; trong strings có một chuỗi khớp mẫu khoá Google API (`AIza…`) — hồ sơ này **không chép nguyên văn khoá** (giá trị nhạy cảm, và bản trích xuất qua công cụ đã bị che).
- `http://maps.apple.com/?daddr=%@&dirflg=d` (mở chỉ đường Apple Maps), `https://m.youtube.com/results?search_query=%@` (tìm YouTube).
- Tài liệu tham chiếu ngoài gói (từ control của gói SidePlay — không thuộc payload này): depiction `https://sideplay.pages.dev/depictions/com.sideplay.json` — chỉ ghi để tránh nhầm lẫn nguồn.

### 7.3 Đường dẫn file / thư mục mà code chạm tới [A/B]

- Ảnh giao diện: `/var/jb/Library/Application Support/DuoFace/` (+ biến thể không tiền tố /var/jb và biến thể thư mục legacy `CarBridge/`): `duoface-icon.png`, `duoface-logo.png`, `duoface-logo-vert.png`, `VisualAssets/duoface-fullscreen.png`, `VisualAssets/duoface-picker.png`, `VisualAssets/duoface-swap.png`; Dashboard còn tham chiếu `AssistantAppIcon.png`, `PortalAppIcon.png` (**không có trong payload** — file do runtime tạo/tải, xem mục 10).
- TCC: `/var/mobile/Library/TCC/TCC.db` (và biến thể `/var/jb/var/mobile/...`, `/Library/TCC/TCC.db`) — Dashboard mở bằng sqlite3.
- `/var/tmp/carbridge_autoresume_bid` — file chứa bundle id để tự khôi phục phiên (Dashboard).
- Log (từ script cboptimize, mục 9.4): `/var/mobile/duoface.log`, `/var/mobile/duoface_live.log`, `/var/mobile/carbridge.log`, `/var/mobile/carbridge_live.log`.
- `/var/jb/usr/bin/killall` (DuoFaceUI tham chiếu), `/var/jb/usr/bin/cboptimize` + `/usr/bin/cboptimize` và shell `/var/jb/usr/bin/sh`, `/var/jb/bin/sh`, `/bin/sh` (Helper).
- `/var/jb/usr/lib/libsubstrate.dylib`, `/usr/lib/libsubstrate.dylib` (VisualHook dlopen).
- Filter plist của chính Dashboard: `/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.plist` (chuỗi tự tham chiếu trong Dashboard).

### 7.4 Câu SQL ghi TCC (nguyên văn từ strings của Dashboard) [A]

```sql
INSERT OR REPLACE INTO access (service, client, client_type, auth_value, auth_reason, auth_version, last_modified) VALUES ('kTCCServiceSpeechRecognition', 'com.apple.springboard', 0, 2, 1, 1, strftime('%s','now'));
INSERT OR REPLACE INTO access (service, client, client_type, auth_value, auth_reason, auth_version, last_modified) VALUES ('kTCCServiceMicrophone', 'com.apple.springboard', 0, 2, 1, 1, strftime('%s','now'));
```

Tức: Dashboard tự cấp cho `com.apple.springboard` quyền **Nhận dạng giọng nói** và **Microphone** (auth_value=2 = allowed) trong TCC.db — điều kiện để tính năng giọng nói (Speech framework + endpoint Google ở 7.2) chạy trong tiến trình SpringBoard mà không cần hộp thoại xin quyền [A cho câu SQL; C cho diễn giải mục đích].

### 7.5 Nhãn log (log tags) [A]

- Dashboard: tiền tố `[DuoFace] …` (vd `[DuoFace] _applyUpdate error: %@`).
- Bridge: `[DuoFaceFullscreen] …` — các mẫu đáng chú ý: `bootstrap pending picker=%d transport=%d`, `candidate adapter started in %@`, `candidate adapter unavailable in %@ after class-load retries`, `host geometry applied %@`, `Zoom In ACK host+chrome`, `Zoom Out ACK host`, `rollback %@`.
- VisualHook: `[DuoFaceBorder] …` (`RED ON user activity view=%p focus=%d`, `RED OFF native idle`, `install %@ start=%p stop=%p focus=%p restore=%p`, `native interaction session START/IDLE`, `signature mismatch start=%s stop=%s`, `native start/stop selectors missing`, `native activity session hook unavailable; using per-container START/STOP`) và `[DuoFaceVisual12] …` (`CBDividerView hook installed`, `CBSlotPillView hook installed`, `CBSplitSplashScreenView hook installed`, `divider applied; touch/long-press/pan unchanged`, `picker applied; dots hidden`, …).
- Số hiệu bản nội bộ trong log VisualHook là "Visual12"; trong Dashboard có các định danh thuộc tính kiểu `CBDuoFaceBridged`, `CBDuoFaceBundleID`, `CBDuoFaceFake`, `CBDuoFaceHosted` (khoá metadata gắn lên app được host) [B].

## 8. Cơ chế A→Z

### 8.1 Điểm nạp và khởi tạo

1. **MobileSubstrate/ElleKit nạp dylib theo filter plist** khi tiến trình đích khởi động [A]: Dashboard vào 23 bundle (hệ thống CarPlay/SpringBoard + các app được hỗ trợ + app DuoFace), Bridge chỉ vào 4 tiến trình hệ thống CarPlay/SpringBoard, VisualHook vào hệ thống + app DuoFace (mục 3, 9.2).
2. **Dashboard**: dyld chạy 2 initializer; initializer chính `0x2a803c` (kiểu Logos `%ctor`) thực thi toàn bộ việc cài hook (243 điểm, mục 6.1) và khởi tạo các singleton (`CBBridgeManager`, `CBDashboardShared`, `CBAssistantManager`, `CBLicenseSyncManager`…). Initializer nhỏ `0x6258` lo dispatch_once/NSLog phụ trợ [A].
3. **Bridge**: initializer duy nhất tại `0x4000` → gọi các hàm `DFStart*`/`DFInstall*` (mục 5.3): khởi động "transport" fullscreen (`DFStartFullscreenTransport`), khởi động "adapter" phía host (`DFStartFullscreenAdapter` — log `candidate adapter started in %@`, có vòng thử lại chờ class Dashboard nạp: `after class-load retries`), và cài 3 cụm hook (mục 6.2) [A/B].
4. **VisualHook**: `_DFInit` (0x4000) → `_DFInstall` resolve MSHookMessageEx (dlsym/dlopen libsubstrate) → cài hook thị giác + border (mục 6.3); `_DFImageAdded` (0x4030) là callback theo dõi image/class mới nạp để cài bổ sung khi class đích xuất hiện muộn [A cho hàm/cờ; B cho vai trò callback].
5. **App DuoFaceUI**: luồng app iOS chuẩn — `XXAppDelegate`/`XXRootViewController` điều phối các màn hình `CB*` (mục 8.5). Helper và script chỉ chạy khi được gọi (mục 8.6).

### 8.2 Luồng chính phía xe (Dashboard trong SpringBoard/CarPlay)

- `CBBridgeManager` (75 method, 14 ivar, 8 property) là trung tâm: quản lý các app được đưa lên màn xe qua họ class `CBBridgeRequest`, `CBBridgedApp` và 4 lớp con theo kiểu hiển thị — `CBBridgedSplitApp` (chia đôi), `CBBridgedPortalApp` (portal), `CBBridgedUIApp` (UI app), `CBBridgedAssistantApp` (trợ lý) [A — bảng class 4.2].
- Tầng hiển thị: `CBWindow` (cửa sổ riêng trên màn xe; có `carPlayScreenBounds`/`carPlayUsableBounds`, `resizeWindows`, `show`, `hide:`, `destroyWindows` — chính các method này bị Bridge hook, mục 6.2), `CBSplitContainerView` + `CBDividerView` (vách chia, kéo đổi tỉ lệ), `CBSlotPlaceholderView`, `CBUIAppContainerView`, `CBBridgedPortalAppView`/`CBBridgedUIAppView`, `CBMultitaskingOverlayView` + `CBMultitaskingPillView`/`CBSlotPillView` (lớp phủ đa nhiệm + pill chọn ô), `CBTouchCloneView` (nhân bản chạm), `CBDockSystemMonitorView`/`CBDockMetricItemView` (thanh dock + đo hệ thống), `CBSplitSplashScreenView` (màn chờ) [A — tên class/method].
- Để app nền "sống" và hiển thị đúng trên xe, Dashboard hook sâu vào vòng đời scene/trạng thái (mục 6.1): FBSSceneSettings (isOccluded, deactivationReasons), UIApplicationSceneSettings (isUnderLock, canShowWhileLocked), UIScene activationState, UIApplication applicationState, cửa sổ/xoay (UIWindow/UIScene geometry), và chặn blank màn hình bằng hook `BKSDisplayServicesSetScreenBlanked` [A]. Cơ chế tổng quát: giữ scene của app được host không bị hệ thống coi là bị che/khoá/huỷ, đồng thời nắn geometry của scene đó theo khung ô trên xe [C — diễn giải từ tập hook].
- Chạm: `CBTouchCloneView` + các hook trên UIWindow `sendEvent:` và họ bàn phím (UIKeyboard/UIInputSet*) cho thấy Dashboard can thiệp đường đi của sự kiện chạm và việc dựng bàn phím trong app được host [A cho hook; C cho diễn giải].

### 8.3 Kênh fullscreen (Dashboard ⇄ Bridge) — "lease" qua Darwin notification

- Bridge đóng vai trò phía **host hình học** trong tiến trình CarPlay/SpringBoard: các hàm `DFHostSetExpanded`, `DFHostRestore`, `DFHostCanExpand`, `DFHostIsExpanded`, `DFDashboardSetChromeHidden`, `DFDashboardRestoreChrome` thao tác cửa sổ/chrome của Dashboard từ bên ngoài [A — tên hàm + log `host geometry applied`, `host restored sameOwner=%d`].
- Đồng bộ hai phía qua 3 Darwin notification `com.duoface.fullscreen.command.v1` (lệnh), `.state.v1` (trạng thái), `.picker.v1` (picker) [A — chuỗi]. Class `DFFullscreenTransport` (36 method) triển khai giao thức: gửi `send:enabled:requestID:`, nhận `received:`, phát `publish:client:reason:`, xử lý `handleCommand:`/`handleState:`, nhịp `tick` bằng timer, và cơ chế **lease** (thuê quyền fullscreen): thuộc tính `leaseOwner`, `leaseDeadline`, `sequence`, `ownsFullscreen`, `desiredExpanded`, `pendingEnabled/pendingID/pendingCompletion` [A — bảng method/property 4.3]. `DFHostSnapshot` (23 method) chụp trạng thái host (appFrame, contentFrame, windowFrame, renderSize, managerFrame…) để khôi phục khi rollback [A].
- Zoom: `DFZoomAction`/`DFZoomReceiver` + `DFRequestHostFullscreen`/`DFQueryFullscreenHost` và các hook `layoutSubviews` trên `DBStatusBarWindow`/`CARStatusBarWindow` tạo nút zoom trong menu picker của status bar [A/B; log `native picker zoom requested=%d`, `Zoom In ACK host+chrome`, `Zoom Out ACK host`].
- Vì Bridge chỉ nạp vào tiến trình hệ thống còn Dashboard nạp cả vào app, cặp đôi này cho phép Dashboard (phía nội dung) nhờ Bridge (phía host) phóng toàn màn hình và khôi phục nguyên trạng khi thôi [C — tổng hợp].

### 8.4 Tầng thị giác (VisualHook)

- VisualHook không định nghĩa class; nó **nắn lại diện mạo của chính các view của Dashboard** trong tiến trình chứa chúng: thay `layoutSubviews` của `CBSlotPillView`/`CBDividerView`/`CBSplitSplashScreenView`/`CBBridgedSplitApp` bằng các hàm layout riêng (`_DFPillLayout`, `_DFDividerLayout`, `_DFSplashLayout`, `_DFSplitLayoutHook`) — theo log là để áp hình fullscreen/restore, ẩn chấm (dots) của picker, giữ nguyên chạm/long-press/pan gốc [A hook + log].
- Hiệu ứng viền (border): hook `UIButton.setBackgroundColor:`, `CALayer.setBorderWidth:`/`setBorderColor:` và nhóm method border/session của `CBBridgedSplitApp` để vẽ **viền đỏ nhấp nháy quanh ô đang được focus/tương tác** (log `RED ON user activity`, biến `_DFBorderLogoRed`, ảnh `duoface-logo*.png` + `VisualAssets/*` đọc từ `/var/jb/Library/Application Support/DuoFace/`) [A/B].
- Mọi hook của VisualHook đều là "trang trí/hiển thị" — chính log của nó khẳng định không đổi hành vi chạm/hành động (`actions unchanged`, `touch/long-press/pan unchanged`, `original loading untouched`) [B — chuỗi log].

### 8.5 App DuoFaceUI (phía điện thoại)

- Điều hướng: `XXAppDelegate`, `XXRootViewController`, `CBSplitViewController` (+ `CBSplitSplashScreenView`). Quản lý app được chọn: `CBAppManager`/`CBAppModel`/`CBAppSection`/`CBAppSwitch`, màn hình `CBAppsManagerViewController`, `CBAppPickerViewController` [A — 4.1].
- Cài đặt chung: `CBGeneralSettingsViewController` (có `loadPreferences`/`savePreferences`/`reloadPreferences` trong strings; `AUTO_LAUNCH_DUOFACE` là một khoá cài đặt thấy trong strings của cả app và Dashboard) [A/B].
- License/thanh toán (toàn bộ nằm trong app): `CBSubscriptionViewController` + 9 cell chuyên biệt (plan card, VIP status/card, hardware ID, giftcode input/redeem, pending order, checkout, status), `CBSubscriptionOrderCoordinator` (+ delegate protocol riêng), `CBLicenseExpiredModalViewController`, `CBLicenseSyncManager`, `CBHttpClient` (endpoint `/api/v1/license/sync`). Định danh phần cứng lấy qua IOKit (IOServiceMatching/IORegistryEntryCreateCFProperty) và/hoặc qua helper (mục 8.6); license lưu Keychain (SecItem*) [A — class/import/endpoint].
- `SFSafariViewControllerDelegate` trong bảng protocol cho thấy luồng mua/gia hạn mở trang web trong app (SafariServices) [A].
- Bản địa hoá: `CBLocalization` + 20 bảng `CBLocTable_*` — cùng một module localization được biên dịch vào **cả app lẫn Dashboard** (Dashboard cũng có class `CBLocalization` riêng cùng 20 bảng? — Dashboard chứa cùng bộ chuỗi dịch; class CBLocalization có mặt ở cả hai) [A/B].

### 8.6 Tối ưu hệ thống & định danh phần cứng (helper + script + sudoers)

- Chuỗi gọi [A/B]: thành phần cần định danh/quyền (app hoặc Dashboard, qua Keychain/IOKit) dùng `duoface_cboptimize_helper`: với đối số `--hw-hash`/`-hwhash`, helper tính **hardware hash** từ thuộc tính IORegistry (và sysctlbyname) rồi in hex (`%02x`), lỗi in `ERROR: Failed to obtain device hardware hash.`; không đối số hash, helper `setuid/setgid` rồi `posix_spawn` shell chạy `/var/jb/usr/bin/cboptimize` (dự phòng `/usr/bin/cboptimize`).
- Script `duoface-cboptimize`: `status` (uptime/vm_stat/launchctl print-disabled), `optimize` (**disable + kill 12 daemon hệ thống** — ReportCrash, ReportCrash.SimulateCrash, AggregateDictionary.addaily, symptomsd-diag, healthd, healthrecordsd, OTATaskingAgent, softwareupdated, triald, biomesyncd, routined, duetexpertd — và **xoá crash log** + truncate 4 file log DuoFace/CarBridge), `restore` (enable lại 12 daemon), `clean-logs` [A — đọc trực tiếp script, mục 9.4].
- Điều kiện để helper/script chạy với quyền cao: file **sudoers `ALL ALL=(ALL) NOPASSWD: ALL`** mà gói cài vào `/var/jb/etc/sudoers.d/duoface` [A].

### 8.7 License — những gì payload cho thấy (chỉ mô tả, không can thiệp)

- File `com.duonavi.sync.plist` **đi kèm payload** chứa sẵn một lease: `status=SUCCESS`, `leaseSeconds=157766400` (đúng 5 năm), `expiresAt`/`actualExpireTimestamp` = 1949370760 (2031-10-10 03:52:40 UTC), `lastSyncTimestamp` = 1791604360 (2026-10-10 03:52:40 UTC), `lastAttemptTimestamp` = 1791700039 (2026-10-11 06:27:19 UTC) [A — mục 9.3].
- Trên máy thật, trạng thái license được duy trì bởi `CBLicenseSyncManager` (có ở cả app và Dashboard) đồng bộ với server qua `CBHttpClient` (`/api/v1/license/sync`), đối chiếu định danh phần cứng (mục 8.6), và Dashboard có thêm tầng hiển thị khi hết hạn: `CBLicenseWarningModalView` + `CBLicenseShieldIconView` (Dashboard) và `CBLicenseExpiredModalViewController` (app) [A].
- Nói cách khác, payload này là bản thương mại ("DuoFace Commercial Pro Edition" theo chuỗi hiển thị) có hạ tầng license đầy đủ: sync server + keychain + hardware ID + modal cảnh báo ở cả hai phía [B/C].

### 8.8 Đọc/ghi dữ liệu — tổng kết luồng

| Kênh | Ai đọc/ghi | Nội dung |
|---|---|---|
| Darwin notification (CFNotificationCenter Darwin + notify_*) | Dashboard ⇄ Bridge, Dashboard ⇄ app | Lệnh/trạng thái fullscreen (mục 8.3), license sync, thay đổi cài đặt |
| TCC.db (sqlite3 trực tiếp) | Dashboard (trong SpringBoard) | Tự cấp quyền Mic + Speech Recognition cho SpringBoard (mục 7.4) |
| Keychain (SecItem*) | DuoFaceUI + Dashboard | Dữ liệu license/định danh |
| IORegistry + sysctl | App, Dashboard, Helper | Định danh phần cứng (serial/IOPlatformUUID/hash) |
| File thường | Dashboard | `/var/tmp/carbridge_autoresume_bid` (bundle id khôi phục phiên); ảnh trong Application Support/DuoFace |
| File log | Dashboard/Bridge/VisualHook (NSLog + file log) | `/var/mobile/duoface*.log`, `carbridge*.log` (đường dẫn suy từ script dọn log) |
| launchctl + rm | script cboptimize (qua helper/sudo) | Bật/tắt 12 daemon, xoá crash log |
| Mạng | CBHttpClient (app + Dashboard) | POST/GET `/api/v1/license/sync` (host chưa xác định); Google speech-api (Dashboard) |

## 9. Tài nguyên và cấu hình đóng gói

### 9.1 Info.plist của DuoFaceUI.app (đầy đủ) [A]

| Key | Giá trị |
|---|---|
| CFBundleDisplayName / CFBundleName | DuoFace |
| CFBundleExecutable | DuoFaceUI |
| CFBundleIdentifier | com.duoface.duofaceui |
| CFBundleVersion / CFBundleShortVersionString | 1.0.0 / 1.0.0 |
| CFBundlePackageType / CFBundleSignature | APPL / ???? |
| CFBundleSupportedPlatforms | iPhoneOS |
| LSRequiresIPhoneOS | true |
| UIDeviceFamily | [1, 2] (iPhone + iPad) |
| UIRequiredDeviceCapabilities | [arm64] |
| UISupportedInterfaceOrientations | Portrait, LandscapeLeft, LandscapeRight |
| CFBundleIconFile / Icons | AppIcon60x60; bộ AppIcon29/40/50/57/60/72/76 (có biến thể ~ipad) |

Không có `CFBundleURLTypes` (app **không đăng ký URL scheme**), không có `UIBackgroundModes`, không có `NS*UsageDescription` nào trong Info.plist này [A].

### 9.2 Filter plist của 3 dylib (đầy đủ) [A]

- **DuoFaceDashboard.plist** — Filter.Bundles (23): com.apple.CarPlayApp, com.apple.CarPlay, com.apple.dashboard, com.apple.springboard, com.apple.SpringBoard, com.google.ios.youtube, com.google.ios.youtubemusic, com.netflix.Netflix, org.videolan.vlc-ios, com.apple.mobilesafari, tv.twitch, com.zhiliaoapp.musically, com.google.Maps, com.waze.iphone, com.spotify.client, com.apple.Preferences, com.apple.mobilenotes, com.apple.mobilephone, com.apple.Music, com.google.chrome.ios, com.apple.BarcodeScanner, com.apple.PrintKit.Print-Center, com.duoface.duofaceui.
- **DuoFaceFullscreenBridge.plist** — Filter.Bundles (4): com.apple.CarPlayApp, com.apple.CarPlay, com.apple.dashboard, com.apple.springboard; Filter.Executables (4): CarPlay, CarPlayApp, Dashboard, SpringBoard.
- **DuoFaceVisualHook.plist** — Filter.Bundles (6): com.apple.CarPlayApp, com.apple.CarPlay, com.apple.dashboard, com.apple.springboard, com.apple.SpringBoard, com.duoface.duofaceui.

### 9.3 com.duonavi.sync.plist trong payload (đầy đủ) [A]

| Key | Giá trị thô | Diễn giải |
|---|---|---|
| status | SUCCESS | — |
| leaseSeconds | 157766400 | đúng 5 năm (157766400 giây) |
| expiresAt | 1949370760 | 2031-10-10 03:52:40 UTC |
| actualExpireTimestamp | 1949370760 | 2031-10-10 03:52:40 UTC |
| lastSyncTimestamp | 1791604360 | 2026-10-10 03:52:40 UTC |
| lastAttemptTimestamp | 1791700039 | 2026-10-11 06:27:19 UTC |

### 9.4 Script duoface-cboptimize (tóm tắt trung thực, nguyên văn đã đọc) [A]

- 4 action: `status`, `optimize`, `restore`, `clean-logs` (mặc định `status`). Biến SERVICES liệt kê 12 daemon (mục 8.6). `optimize`/`clean-logs` xoá `/var/mobile/Library/Logs/CrashReporter/*`, `/Library/Logs/CrashReporter/*` và truncate `/var/mobile/duoface.log`, `/var/mobile/duoface_live.log`, `/var/mobile/carbridge.log`, `/var/mobile/carbridge_live.log`. Dùng launchctl tại `/var/jb/usr/bin/launchctl` (dự phòng `/usr/bin/launchctl`).

### 9.5 Bộ ảnh giao diện

- `duoface-icon.png` 256×256, `duoface-logo.png` 960×240, `duoface-logo-vert.png` 640×640, `VisualAssets/duoface-swap.png` 120×120, `VisualAssets/duoface-fullscreen.png` 88×88, `VisualAssets/duoface-picker.png` 256×70 (theo asset-manifest.json, khớp SHA thực). Icon app: đủ bộ 18 file AppIcon (29→76, @1x/@2x/@3x).

## 10. CHƯA XÁC ĐỊNH ĐƯỢC (trung thực — không suy đoán thay thế)

1. **Định danh Debian của gói DuoFace này** (Package ID, Version, Depends, maintainer scripts postinst/prerm của chính nó): file .deb gốc đã mất, rootfs không chứa DEBIAN/; metadata 1.0.4-1 duy nhất trong repo thuộc gói com.sideplay khác payload (mục 1.2). Không khẳng định được gói này tên/version gì trên Sileo/Cydia.
2. **Hostname của API license**: chỉ thấy path `/api/v1/license/sync`; host không nằm dạng literal trong strings (có thể ghép từ nhiều mảnh, tải cấu hình, hoặc nằm trong vùng chuỗi đã bị nén/khác). Belonging: hành vi mạng thực tế của CBHttpClient (method, header, body, cơ chế ký) chưa dịch ngược tới mức khẳng định.
3. **Token notify_\* của libnotify** mà Dashboard đăng ký qua `notify_register_dispatch`: tên token không xuất hiện dạng chuỗi rõ trong trích xuất strings hiện tại.
4. **Domain/khoá preferences chính xác** của CBDashboardSettings/CBGeneralSettings: thấy các method load/save/reloadPreferences và khoá `AUTO_LAUNCH_DUOFACE`, nhưng tên suite/domain CFPreferences cụ thể (và toàn bộ khoá + giá trị mặc định) chưa trích được từ metadata — settings có thể lưu qua CFPreferences theo bundle id của tiến trình host hoặc file riêng; chưa khẳng định.
5. **Bảng method của slice arm64e**: parser xác nhận danh sách class trùng 100% với arm64 (cả 2 binary FAT) nhưng chưa giải độc lập bảng method/ivar của arm64e (định dạng chained-fixup + relative list của slice này khiến parser hiện tại trả rỗng). Mặc định coi arm64e tương đương arm64 về mặt API — đây là giả định, chưa kiểm chứng từng method.
6. **Hai file ảnh `AssistantAppIcon.png`/`PortalAppIcon.png`** mà Dashboard tham chiếu không có trong payload — nguồn gốc (runtime tải về, app ghi ra, hay bản khác của gói có) chưa xác định.
7. **Nội dung thân hàm hook của Dashboard**: hồ sơ ghi được *điểm cài* hook (class/selector/IMP) ở mức [A], nhưng chưa dịch ngược logic bên trong từng IMP (757 method + 243 IMP hook là khối lượng vượt một vòng quét); hành vi chi tiết của từng hook được mô tả ở mức cơ chế (mục 8) là [C].
8. **`DuoFaceVisualHook` không có chuỗi build-tag** như các binary khác — không gắn được nó vào đợt build `804c181c` bằng chuỗi; chỉ biết SDK 18.5 giống Bridge và mtime trong rootfs cùng ngày 14/10 như Bridge.
9. **Vai trò chính xác của `_DFImageAdded`** (VisualHook) và của initializer nhỏ `0x6258` (Dashboard): suy ra từ tên/ngữ cảnh [B], chưa dịch ngược toàn thân.
10. **Quan hệ "DuoFace" ↔ "DuoNavi" ↔ "SidePlay" ↔ "CarBridge"**: payload chứa đồng thời thương hiệu DuoFace (app/UI), định danh `com.duonavi.*` (file sync), đường dẫn legacy `CarBridge/` (ảnh + log) và repo chứa gói chị em com.sideplay cùng version 1.0.4-1 khác payload. Hồ sơ chỉ ghi nhận sự cùng tồn tại này; không khẳng định quan hệ phát hành/chủ thể.

---

## Phụ lục A. Thống kê quét

| Binary | Class | Method (inst+class) | Property | Ivar | Protocol | Selrefs | Classrefs | Defined sym | Imports | Điểm hook |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| DuoFaceUI | 27 | 522 | 145 | 141 | 16 | 772 | 92 | 78 | 214 | 0 |
| DuoFaceDashboard.dylib | 36 | 757 | 179 | 215 | 5 | 1316 | 109 | 0 | 295 | 243 |
| DuoFaceFullscreenBridge.dylib | 4 | 62 | 25 | 25 | 0 | 178 | 25 | 23 | 80 | 10 |
| DuoFaceVisualHook.dylib | 0 | 0 | 0 | 0 | 0 | 63 | 13 | 121 | 51 | ~13 |
| duoface_cboptimize_helper | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 2 | 36 | 0 |

(Method của Bridge = 23+36+1+1 = 61, toàn bộ là instance method; cả 4 class không có class method. IMP của method thuộc protocol hiển thị dạng `None`/trống vì protocol chỉ khai báo, không chứa implementation.)

## Phụ lục B. Dữ liệu quét thô đi kèm (thư mục work/)

- `parsed_*.json` — metadata ObjC đã parse (class/method/property/ivar/protocol/selrefs/classrefs) cho từng binary, là nguồn sinh mục 4.
- `hooks_Dashboard.json` — 243 điểm hook Dashboard dạng máy đọc, nguồn sinh mục 6.1.
- `objc_parse.py`, `macho_info.py`, `hook_scan.py` — parser/analyzer tự viết cho vòng quét này (chỉ đọc).
- `nm_*.txt`, `nmdef_*.txt`, `nmu_*.txt`, `bind_*.txt`, `strings_*.txt`, `dis_Bridge.txt`, `dis_VisualHook.txt`, `dis_Dashboard.txt`, `objc_*.txt` — dump thô từ llvm-nm/llvm-objdump/strings.

*Hết hồ sơ.*
