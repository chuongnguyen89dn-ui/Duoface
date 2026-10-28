# Original OmniCar iPhone selected-app persistence and CarPlay catalog assembly — ARM64 callsite scan

Original binary SHA: d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd
Only actual instructions in each original method IMP range; these are read-only proofs, not an iPhone test.

## OMCAppBridgeAppsController.loadState @ 0x1cdd8
Instructions 981
Relevant direct branch / selector lines:
  1ce10:	add	x0, x0, #0x28 ; Objc cfstring ref: @"com.anlai.omnicar"
  1ce14:	bl	0x55850 ; symbol stub for: _CFPreferencesAppSynchronize
  1ce34:	bl	0x565c0
  1ce3c:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1ce4c:	bl	0x55d0c ; symbol stub for: _objc_getClass
  1ce54:	add	x1, x1, #0x7e8 ; Objc cfstring ref: @"defaultWorkspace"
  1ce58:	bl	0x24d80
  1ce60:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1ce6c:	add	x1, x1, #0xca8 ; Objc cfstring ref: @"allInstalledApplications"
  1ce70:	bl	0x24d80
  1ce78:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1ce84:	bl	0x55d78 ; symbol stub for: _objc_release
  1ce8c:	ldr	x0, [x8, #0x9b0] ; Objc class ref: _OBJC_CLASS_$_NSSet
  1ce98:	bl	0x5c900
  1cea0:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1cec0:	bl	0x55d84 ; symbol stub for: _objc_retain
  1ced4:	bl	0x573e0
  1cee4:	add	x23, x23, #0xd48 ; Objc cfstring ref: @"bundleIdentifier"
  1cf0c:	bl	0x55cf4 ; symbol stub for: _objc_enumerationMutation
  1cf20:	bl	0x24d80
  1cf28:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1cf34:	ldr	x0, [x8, #0x958] ; Objc class ref: _OBJC_CLASS_$_NSString
  1cf38:	bl	0x55d48 ; symbol stub for: _objc_opt_class
  1cf44:	bl	0x55d54 ; symbol stub for: _objc_opt_isKindOfClass
  1cf50:	bl	0x58c20
  1cf60:	bl	0x571c0
  1cf70:	add	x1, x1, #0xd68 ; Objc cfstring ref: @"applicationType"
  1cf74:	bl	0x24d80
  1cf7c:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1cf88:	add	x2, x2, #0xd88 ; Objc cfstring ref: @"User"
  1cf8c:	bl	0x58800
  1cfa0:	add	x2, x2, #0xda8 ; Objc cfstring ref: @"System"
  1cfa4:	bl	0x58800
  1cfb4:	add	x1, x1, #0xdc8 ; Objc cfstring ref: @"appTags"
  1cfb8:	bl	0x24d80
  1cfc0:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1cfcc:	ldr	x0, [x8, #0x960] ; Objc class ref: _OBJC_CLASS_$_NSArray
  1cfd0:	bl	0x55d48 ; symbol stub for: _objc_opt_class
  1cfdc:	bl	0x55d54 ; symbol stub for: _objc_opt_isKindOfClass
  1cfec:	add	x2, x2, #0xde8 ; Objc cfstring ref: @"hidden"
  1cff0:	bl	0x571c0
  1d000:	add	x1, x1, #0xe08 ; Objc cfstring ref: @"isLaunchProhibited"
  1d004:	bl	0x24e0c
  1d014:	add	x1, x1, #0xe28 ; Objc cfstring ref: @"isPlaceholder"
  1d018:	bl	0x24e0c
  1d024:	bl	0x24e90
  1d034:	add	x1, x1, #0xc88 ; Objc cfstring ref: @"localizedName"
  1d038:	bl	0x24d80
  1d040:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1d04c:	ldr	x0, [x8, #0x958] ; Objc class ref: _OBJC_CLASS_$_NSString
  1d050:	bl	0x55d48 ; symbol stub for: _objc_opt_class
  1d05c:	bl	0x55d54 ; symbol stub for: _objc_opt_isKindOfClass
  1d068:	bl	0x58c20
  1d074:	add	x9, x8, #0x3e8 ; Objc cfstring ref: @"id"
  1d07c:	add	x8, x8, #0x1e8 ; Objc cfstring ref: @"name"
  1d08c:	add	x8, x8, #0xe48 ; Objc cfstring ref: @"system"
  1d098:	ldr	x0, [x8, #0x928] ; Objc class ref: _OBJC_CLASS_$_NSNumber
  1d0a0:	bl	0x59300
  1d0a8:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1d0b8:	ldr	x0, [x8, #0x970] ; Objc class ref: _OBJC_CLASS_$_NSDictionary
  1d0c8:	bl	0x577e0
  1d0d0:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1d0e0:	bl	0x56140
  1d0e8:	bl	0x55d78 ; symbol stub for: _objc_release
  1d0f0:	bl	0x55d78 ; symbol stub for: _objc_release
  1d0f8:	bl	0x55d78 ; symbol stub for: _objc_release
  1d100:	bl	0x55d78 ; symbol stub for: _objc_release
  1d10c:	bl	0x55d78 ; symbol stub for: _objc_release
  1d118:	bl	0x55d78 ; symbol stub for: _objc_release
  1d138:	bl	0x573e0
  1d148:	bl	0x55d78 ; symbol stub for: _objc_release
  1d150:	ldr	x0, [x8, #0xb80] ; Objc class ref: _OBJC_CLASS_$_NSSortDescriptor
  1d158:	ldr	x4, [x8, #0xb10] ; Objc selector ref: localizedCaseInsensitiveCompare:
  1d160:	add	x2, x2, #0x1e8 ; Objc cfstring ref: @"name"
  1d168:	bl	0x5cc60
  1d170:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1d180:	ldr	x0, [x8, #0x960] ; Objc class ref: _OBJC_CLASS_$_NSArray
  1d18c:	bl	0x56640
  1d194:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1d1a8:	bl	0x5cca0
  1d1b0:	bl	0x55d78 ; symbol stub for: _objc_release
  1d1b8:	bl	0x55d78 ; symbol stub for: _objc_release
  1d1c0:	bl	0x55d78 ; symbol stub for: _objc_release
  1d1c8:	bl	0x55d78 ; symbol stub for: _objc_release
  1d1d8:	bl	0x55d78 ; symbol stub for: _objc_release
  1d1e0:	ldr	x0, [x9, #0x988] ; Objc class ref: _OBJC_CLASS_$_NSMutableArray
  1d1e4:	bl	0x565c0
  1d1ec:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1d1f8:	ldr	x0, [x8, #0x9d0] ; Objc class ref: _OBJC_CLASS_$_NSMutableDictionary
  1d1fc:	bl	0x57780
  1d204:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1d210:	ldr	x0, [x8, #0x9a0] ; Objc class ref: _OBJC_CLASS_$_NSMutableSet
  1d214:	bl	0x5a220
  1d21c:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1d234:	add	x0, x0, #0x1e8 ; Objc cfstring ref: @"homeScreenCarApps"
  1d238:	bl	0x1dc60
  1d240:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1d254:	bl	0x573e0
  1d270:	add	x24, x24, #0x3e8 ; Objc cfstring ref: @"id"
  1d28c:	bl	0x55cf4 ; symbol stub for: _objc_enumerationMutation
  1d29c:	bl	0x55d48 ; symbol stub for: _objc_opt_class
  1d2a8:	bl	0x55d54 ; symbol stub for: _objc_opt_isKindOfClass
  1d2b8:	bl	0x593c0
  1d2c0:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1d2cc:	ldr	x0, [x8, #0x958] ; Objc class ref: _OBJC_CLASS_$_NSString
  1d2d0:	bl	0x55d48 ; symbol stub for: _objc_opt_class
  1d2dc:	bl	0x55d54 ; symbol stub for: _objc_opt_isKindOfClass
  1d2e8:	bl	0x55d78 ; symbol stub for: _objc_release
  1d2f8:	bl	0x593c0
  1d300:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue

## OMCAppBridgeAppsController.carplayIDs @ 0x1dd54
Instructions 152
Relevant direct branch / selector lines:
  1dd8c:	ldr	x0, [x8, #0x988] ; Objc class ref: _OBJC_CLASS_$_NSMutableArray
  1dd90:	bl	0x565c0
  1dd98:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1ddac:	bl	0x562c0
  1ddb4:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1ddc4:	bl	0x5cce0
  1ddcc:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1ddd8:	bl	0x55d78 ; symbol stub for: _objc_release
  1ddec:	bl	0x56c20
  1de14:	bl	0x56600
  1de1c:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1de30:	bl	0x573e0
  1de64:	bl	0x55cf4 ; symbol stub for: _objc_enumerationMutation
  1de74:	bl	0x55d48 ; symbol stub for: _objc_opt_class
  1de80:	bl	0x55d54 ; symbol stub for: _objc_opt_isKindOfClass
  1de94:	bl	0x571c0
  1dea4:	bl	0x571c0
  1deb4:	bl	0x56140
  1ded4:	bl	0x573e0
  1dee4:	bl	0x55d78 ; symbol stub for: _objc_release
  1deec:	bl	0x55d78 ; symbol stub for: _objc_release
  1df28:	b	0x55cb8 ; symbol stub for: _objc_autoreleaseReturnValue
  1df2c:	bl	0x55b98 ; symbol stub for: ___stack_chk_fail
  1df4c:	bl	0x55d84 ; symbol stub for: _objc_retain
  1df54:	bl	0x1c620
  1df5c:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1df68:	bl	0x1c620
  1df70:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1df7c:	bl	0x55d78 ; symbol stub for: _objc_release
  1df88:	bl	0x58d80
  1df94:	bl	0x55d78 ; symbol stub for: _objc_release
  1df9c:	bl	0x55d78 ; symbol stub for: _objc_release

## OMCAppBridgeAppsController.rebuildRows @ 0x1e3a8
Instructions 275
Relevant direct branch / selector lines:
  1e3e8:	bl	0x58c20
  1e400:	bl	0x55d84 ; symbol stub for: _objc_retain
  1e408:	ldr	x0, [x19, #0x988] ; Objc class ref: _OBJC_CLASS_$_NSMutableArray
  1e40c:	bl	0x565c0
  1e414:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1e420:	bl	0x565c0
  1e428:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1e460:	bl	0x55d84 ; symbol stub for: _objc_retain
  1e470:	bl	0x55da8 ; symbol stub for: _objc_retainBlock
  1e488:	bl	0x56c40
  1e490:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1e4a4:	bl	0x573e0
  1e4b8:	add	x25, x25, #0x1e8 ; Objc cfstring ref: @"name"
  1e4d8:	bl	0x55cf4 ; symbol stub for: _objc_enumerationMutation
  1e4ec:	add	x8, x8, #0x3e8 ; Objc cfstring ref: @"id"
  1e4f8:	bl	0x1c620
  1e500:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1e50c:	add	x8, x8, #0x328 ; Objc cfstring ref: @"carplay"
  1e528:	ldr	x0, [x8, #0x970] ; Objc class ref: _OBJC_CLASS_$_NSDictionary
  1e538:	bl	0x577e0
  1e540:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1e54c:	bl	0x55d78 ; symbol stub for: _objc_release
  1e558:	bl	0x57fa0
  1e570:	bl	0x593c0
  1e578:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1e598:	bl	0x55d78 ; symbol stub for: _objc_release
  1e5a8:	bl	0x56140
  1e5b0:	bl	0x55d78 ; symbol stub for: _objc_release
  1e5d0:	bl	0x573e0
  1e5e0:	bl	0x55d78 ; symbol stub for: _objc_release
  1e600:	bl	0x55d84 ; symbol stub for: _objc_retain
  1e618:	bl	0x573e0
  1e630:	add	x25, x25, #0x3e8 ; Objc cfstring ref: @"id"
  1e64c:	bl	0x55cf4 ; symbol stub for: _objc_enumerationMutation
  1e66c:	bl	0x593c0
  1e674:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1e684:	bl	0x571c0
  1e690:	bl	0x55d78 ; symbol stub for: _objc_release
  1e6a4:	add	x2, x2, #0x1e8 ; Objc cfstring ref: @"name"
  1e6a8:	bl	0x593c0
  1e6b0:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1e6d0:	bl	0x55d78 ; symbol stub for: _objc_release
  1e6e0:	bl	0x56140
  1e700:	bl	0x573e0
  1e710:	bl	0x55d78 ; symbol stub for: _objc_release
  1e728:	bl	0x55d84 ; symbol stub for: _objc_retain
  1e730:	bl	0x55d78 ; symbol stub for: _objc_release
  1e74c:	bl	0x55d84 ; symbol stub for: _objc_retain
  1e754:	bl	0x55d78 ; symbol stub for: _objc_release
  1e75c:	bl	0x55d78 ; symbol stub for: _objc_release
  1e764:	bl	0x55d78 ; symbol stub for: _objc_release
  1e76c:	bl	0x55d78 ; symbol stub for: _objc_release
  1e774:	bl	0x55d78 ; symbol stub for: _objc_release
  1e77c:	bl	0x55d78 ; symbol stub for: _objc_release
  1e7b8:	bl	0x55b98 ; symbol stub for: ___stack_chk_fail
  1e7d4:	bl	0x59b60

## OMCAppBridgeAppsController.storeChoices @ 0x1e920
Instructions 150
Relevant direct branch / selector lines:
  1e958:	ldr	x0, [x8, #0x988] ; Objc class ref: _OBJC_CLASS_$_NSMutableArray
  1e95c:	bl	0x565c0
  1e964:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1e988:	bl	0x55d84 ; symbol stub for: _objc_retain
  1e99c:	bl	0x573e0
  1e9b8:	add	x22, x22, #0x3e8 ; Objc cfstring ref: @"id"
  1e9d4:	bl	0x55cf4 ; symbol stub for: _objc_enumerationMutation
  1e9f0:	bl	0x593c0
  1e9f8:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1ea08:	bl	0x571c0
  1ea14:	bl	0x55d78 ; symbol stub for: _objc_release
  1ea24:	bl	0x593c0
  1ea2c:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1ea3c:	bl	0x56140
  1ea44:	bl	0x55d78 ; symbol stub for: _objc_release
  1ea64:	bl	0x573e0
  1ea74:	bl	0x55d78 ; symbol stub for: _objc_release
  1ea7c:	add	x0, x0, #0x928 ; Objc cfstring ref: @"appBridgeApps"
  1ea88:	bl	0x1cda0
  1ea98:	bl	0x562c0
  1eaa0:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1eaac:	ldr	x22, [x8, #0x388] ; Objc selector ref: compare:
  1eab4:	bl	0x5cd00
  1eabc:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1eac8:	add	x0, x0, #0x208 ; Objc cfstring ref: @"homeScreenHiddenApps"
  1ead0:	bl	0x1cda0
  1ead8:	bl	0x55d78 ; symbol stub for: _objc_release
  1eae0:	bl	0x55d78 ; symbol stub for: _objc_release
  1eaf0:	bl	0x562c0
  1eaf8:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1eb04:	bl	0x5cd00
  1eb0c:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1eb18:	add	x0, x0, #0x228 ; Objc cfstring ref: @"homeScreenShownApps"
  1eb20:	bl	0x1cda0
  1eb28:	bl	0x55d78 ; symbol stub for: _objc_release
  1eb30:	bl	0x55d78 ; symbol stub for: _objc_release
  1eb38:	bl	0x55d78 ; symbol stub for: _objc_release
  1eb74:	bl	0x55b98 ; symbol stub for: ___stack_chk_fail

## OMCAppBridgeAppsController.reloadLists @ 0x1eb78
Instructions 191
Relevant direct branch / selector lines:
  1ebac:	bl	0x59280
  1ebbc:	bl	0x59280
  1ebc8:	bl	0x59bc0
  1ebd0:	ldr	x0, [x21, #0x988] ; Objc class ref: _OBJC_CLASS_$_NSMutableArray
  1ebd4:	bl	0x565c0
  1ebdc:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1ebe8:	bl	0x565c0
  1ebf0:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1ec14:	bl	0x58300
  1ec1c:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1ec2c:	bl	0x56140
  1ec34:	bl	0x55d78 ; symbol stub for: _objc_release
  1ec50:	bl	0x5d900
  1ec6c:	bl	0x58300
  1ec74:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1ec84:	bl	0x56140
  1ec8c:	bl	0x55d78 ; symbol stub for: _objc_release
  1eca0:	bl	0x5d900
  1ece8:	bl	0x55d84 ; symbol stub for: _objc_retain
  1ecf0:	bl	0x55d84 ; symbol stub for: _objc_retain
  1ed00:	bl	0x59680
  1ed08:	bl	0x5dd80
  1ed10:	bl	0x55d78 ; symbol stub for: _objc_release
  1ed18:	bl	0x55d78 ; symbol stub for: _objc_release
  1ed20:	bl	0x55d78 ; symbol stub for: _objc_release
  1ed44:	b	0x55d78 ; symbol stub for: _objc_release
  1ed60:	bl	0x5d8c0
  1ed68:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1ed74:	ldr	x0, [x8, #0x968] ; Objc class ref: _OBJC_CLASS_$_NSIndexSet
  1ed7c:	bl	0x58340
  1ed84:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1eda4:	bl	0x59d00
  1edac:	bl	0x55d78 ; symbol stub for: _objc_release
  1edb4:	bl	0x55d78 ; symbol stub for: _objc_release
  1edbc:	bl	0x5d8c0
  1edc4:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1edd4:	bl	0x576c0
  1eddc:	bl	0x55d78 ; symbol stub for: _objc_release
  1ede4:	bl	0x5d8c0
  1edec:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1edfc:	bl	0x58660
  1ee10:	b	0x55d78 ; symbol stub for: _objc_release
  1ee28:	bl	0x55d84 ; symbol stub for: _objc_retain
  1ee30:	bl	0x55d84 ; symbol stub for: _objc_retain
  1ee40:	b	0x55d84 ; symbol stub for: _objc_retain
  1ee58:	bl	0x55d78 ; symbol stub for: _objc_release
  1ee60:	bl	0x55d78 ; symbol stub for: _objc_release
  1ee70:	b	0x55d78 ; symbol stub for: _objc_release

## OMCAppBridgeAppsController.tableView:commitEditingStyle:forRowAtIndexPath: @ 0x2044c
Instructions 88
Relevant direct branch / selector lines:
  2046c:	bl	0x563c0
  20474:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  20484:	add	x2, x2, #0x3e8 ; Objc cfstring ref: @"id"
  2048c:	bl	0x593c0
  20494:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  204a0:	add	x2, x2, #0x328 ; Objc cfstring ref: @"carplay"
  204a8:	bl	0x593c0
  204b0:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  204b8:	bl	0x569c0
  204c4:	bl	0x55d78 ; symbol stub for: _objc_release
  204e4:	bl	0x59e40
  204f8:	bl	0x571c0
  20534:	bl	0x571c0
  20544:	bl	0x59e40
  2055c:	bl	0x56140
  20564:	ldr	x0, [x8, #0x938] ; Objc class ref: _OBJC_CLASS_$_UISelectionFeedbackGenerator
  20568:	bl	0x55d60 ; symbol stub for: _objc_opt_new
  20570:	bl	0x5a200
  20578:	bl	0x55d78 ; symbol stub for: _objc_release
  20580:	bl	0x5d3a0
  20588:	bl	0x59cc0
  20590:	bl	0x55d78 ; symbol stub for: _objc_release
  205a8:	b	0x55d78 ; symbol stub for: _objc_release

## OMCAppBridgeAppsController.tableView:didSelectRowAtIndexPath: @ 0x214b0
Instructions 77
Relevant direct branch / selector lines:
  214d0:	bl	0x55d84 ; symbol stub for: _objc_retain
  214e0:	bl	0x57740
  214e8:	bl	0x59f60
  214f4:	bl	0x5a180
  21504:	ldr	x21, [x8, #0x928] ; Objc class ref: _OBJC_CLASS_$_NSNumber
  2150c:	bl	0x5a180
  21518:	bl	0x59320
  21520:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  21538:	bl	0x571c0
  2154c:	bl	0x59e40
  21554:	bl	0x56140
  2155c:	bl	0x5df60
  21564:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  21570:	bl	0x579a0
  21578:	bl	0x55d78 ; symbol stub for: _objc_release
  2158c:	ldr	x22, [x8, #0x968] ; Objc class ref: _OBJC_CLASS_$_NSIndexSet
  21594:	bl	0x5a180
  215a0:	bl	0x58340
  215a8:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  215bc:	bl	0x59d00
  215c4:	bl	0x55d78 ; symbol stub for: _objc_release
  215cc:	bl	0x55d78 ; symbol stub for: _objc_release
  215e0:	b	0x55d78 ; symbol stub for: _objc_release

## OMCSplitScreenAppPickerController.viewDidLoad @ 0x36438
Instructions 548
Relevant direct branch / selector lines:
  36470:	ldr	x8, [x8, #0xd90] ; Objc class ref: OMCSplitScreenAppPickerController
  3647c:	ldr	x1, [x8, #0xda0] ; Objc selector ref: viewDidLoad
  36484:	bl	0x55d3c ; Objc message: -[[x0 super] viewDidLoad]
  36488:	bl	_OMCLoadStrings
  36490:	bl	0x5cdc0
  36498:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  364a0:	bl	0x590e0
  364a8:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  364b8:	bl	0x5c5e0
  364c0:	bl	0x55d78 ; symbol stub for: _objc_release
  364c8:	bl	0x55d78 ; symbol stub for: _objc_release
  364cc:	bl	_OMCAccentColor
  364d4:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  364e0:	bl	0x5df60
  364e8:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  364f4:	bl	0x5c5c0
  364fc:	bl	0x55d78 ; symbol stub for: _objc_release
  36504:	bl	0x55d78 ; symbol stub for: _objc_release
  36508:	bl	_OMCBackgroundColor
  36510:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  36528:	bl	0x5a560
  36530:	bl	0x55d78 ; symbol stub for: _objc_release
  36538:	add	x0, x0, #0x28 ; Objc cfstring ref: @"com.anlai.omnicar"
  3653c:	bl	0x55850 ; symbol stub for: _CFPreferencesAppSynchronize
  36544:	add	x0, x0, #0x8a8 ; Objc cfstring ref: @"splitScreenCarPlayApps"
  36548:	bl	0x36280
  36550:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  3655c:	ldr	x0, [x8, #0x960] ; Objc class ref: _OBJC_CLASS_$_NSArray
  36560:	bl	0x55d48 ; symbol stub for: _objc_opt_class
  3656c:	bl	0x55d54 ; symbol stub for: _objc_opt_isKindOfClass
  36578:	bl	0x573c0
  3659c:	ldr	x0, [x8, #0x9a0] ; Objc class ref: _OBJC_CLASS_$_NSMutableSet
  365a0:	bl	0x5a220
  365a8:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  365b4:	ldr	x0, [x23, #0x988] ; Objc class ref: _OBJC_CLASS_$_NSMutableArray
  365b8:	bl	0x565c0
  365c0:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  365e0:	bl	0x56160
  365ec:	ldr	x0, [x8, #0x9b0] ; Objc class ref: _OBJC_CLASS_$_NSSet
  365f8:	bl	0x5c900
  36600:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  36610:	bl	0x565c0
  36618:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  3662c:	bl	0x378b8
  36634:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  36648:	bl	0x573e0
  36660:	add	x28, x28, #0xd48 ; Objc cfstring ref: @"bundleIdentifier"
  36668:	add	x20, x20, #0xe88 ; Objc cfstring ref: @"com.apple.developer.carplay"
  3668c:	bl	0x55cf4 ; symbol stub for: _objc_enumerationMutation
  3669c:	bl	0x55b08 ; symbol stub for: _NSSelectorFromString
  366a8:	bl	0x55d30 ; Objc message: +[NSSet viewDidLoad]
  366b0:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  366b8:	bl	0x58c20
  366c8:	bl	0x571c0
  366d8:	bl	0x56140
  366e4:	add	x0, x0, #0xe68 ; Objc cfstring ref: @"entitlements"
  366e8:	bl	0x55b08 ; symbol stub for: _NSSelectorFromString
  366f4:	bl	0x55d6c ; symbol stub for: _objc_opt_respondsToSelector
  36700:	add	x0, x0, #0xe68 ; Objc cfstring ref: @"entitlements"
  36704:	bl	0x55b08 ; symbol stub for: _NSSelectorFromString
  36710:	bl	0x55d30 ; Objc message: -[x0 viewDidLoad]
  36718:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  36738:	bl	0x573e0
  36764:	bl	0x55cf4 ; symbol stub for: _objc_enumerationMutation
  36778:	bl	0x57ea0
  36788:	add	x2, x2, #0xea8 ; Objc cfstring ref: @"com.apple.developer.playable-content"
  3678c:	bl	0x58800
  367b0:	bl	0x573e0
  367d0:	bl	0x56140
  367dc:	bl	0x55d78 ; symbol stub for: _objc_release
  367e8:	add	x28, x28, #0xd48 ; Objc cfstring ref: @"bundleIdentifier"
  367f0:	bl	0x55d78 ; symbol stub for: _objc_release
  36810:	bl	0x573e0
  36820:	bl	0x55d78 ; symbol stub for: _objc_release
  36828:	bl	0x55d78 ; symbol stub for: _objc_release
  36838:	bl	0x56160
  36840:	bl	0x55d78 ; symbol stub for: _objc_release
  36850:	bl	0x36a7c
  36858:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  36874:	bl	0x55d78 ; symbol stub for: _objc_release
  3687c:	add	x0, x0, #0x928 ; Objc cfstring ref: @"appBridgeApps"
  36880:	bl	0x36280
  36888:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  36894:	ldr	x0, [x8, #0x960] ; Objc class ref: _OBJC_CLASS_$_NSArray
  36898:	bl	0x55d48 ; symbol stub for: _objc_opt_class
  368a4:	bl	0x55d54 ; symbol stub for: _objc_opt_isKindOfClass
  368b0:	bl	0x573c0
  368bc:	ldr	x0, [x8, #0x9b0] ; Objc class ref: _OBJC_CLASS_$_NSSet
  368c4:	bl	0x5c900
  368cc:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  368d8:	ldr	x0, [x8, #0x988] ; Objc class ref: _OBJC_CLASS_$_NSMutableArray
  368dc:	bl	0x565c0
  368e4:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  368f8:	bl	0x378b8
  36900:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  36914:	bl	0x573e0
  3692c:	add	x19, x19, #0xd48 ; Objc cfstring ref: @"bundleIdentifier"
  36948:	bl	0x55cf4 ; symbol stub for: _objc_enumerationMutation
  36958:	bl	0x55b08 ; symbol stub for: _NSSelectorFromString
  36964:	bl	0x55d30 ; Objc message: +[NSMutableArray viewDidLoad]
  3696c:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  36974:	bl	0x58c20
  36984:	bl	0x571c0
  36994:	bl	0x56140
  3699c:	bl	0x55d78 ; symbol stub for: _objc_release
  369bc:	bl	0x573e0
  369cc:	bl	0x55d78 ; symbol stub for: _objc_release
  369d4:	bl	0x55d78 ; symbol stub for: _objc_release
  369e8:	ldr	x21, [x21, #0x1a0] ; literal pool symbol address: ___NSArray0__struct
  369f0:	bl	0x55d78 ; symbol stub for: _objc_release

## OMCSplitScreenAppPickerController.currentValue @ 0x36cc8
Instructions 39
Relevant direct branch / selector lines:
  36cd8:	bl	0x5cdc0
  36ce0:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  36cec:	add	x2, x2, #0xfc8 ; Objc cfstring ref: @"key"
  36cf0:	bl	0x59aa0
  36cf8:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  36d00:	bl	0x36280
  36d08:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  36d14:	bl	0x55d78 ; symbol stub for: _objc_release
  36d1c:	bl	0x55d78 ; symbol stub for: _objc_release
  36d24:	ldr	x0, [x8, #0x958] ; Objc class ref: _OBJC_CLASS_$_NSString
  36d28:	bl	0x55d48 ; symbol stub for: _objc_opt_class
  36d34:	bl	0x55d54 ; symbol stub for: _objc_opt_isKindOfClass
  36d44:	bl	0x55d84 ; symbol stub for: _objc_retain
  36d4c:	bl	0x55d78 ; symbol stub for: _objc_release
  36d60:	b	0x55cb8 ; symbol stub for: _objc_autoreleaseReturnValue

## OMCSplitScreenAppPickerController.tableView:didSelectRowAtIndexPath: @ 0x37444
Instructions 196
Relevant direct branch / selector lines:
  37470:	bl	0x55d84 ; symbol stub for: _objc_retain
  37478:	bl	0x55d84 ; symbol stub for: _objc_retain
  37488:	bl	0x57740
  37490:	bl	0x5cdc0
  37498:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  374a4:	add	x2, x2, #0xfc8 ; Objc cfstring ref: @"key"
  374a8:	bl	0x59aa0
  374b0:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  374bc:	bl	0x55d78 ; symbol stub for: _objc_release
  374c4:	ldr	x0, [x8, #0x958] ; Objc class ref: _OBJC_CLASS_$_NSString
  374c8:	bl	0x55d48 ; symbol stub for: _objc_opt_class
  374d4:	bl	0x55d54 ; symbol stub for: _objc_opt_isKindOfClass
  374e0:	bl	0x5a180
  374ec:	bl	0x5a180
  374f8:	bl	0x59fc0
  37500:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  3750c:	bl	0x59f60
  37518:	bl	0x59380
  37520:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  3752c:	add	x2, x2, #0x3e8 ; Objc cfstring ref: @"id"
  37530:	bl	0x593c0
  37538:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  37548:	bl	0x37698
  37550:	bl	0x55d78 ; symbol stub for: _objc_release
  37558:	bl	0x55d78 ; symbol stub for: _objc_release
  37560:	bl	0x55d78 ; symbol stub for: _objc_release
  37570:	bl	0x37698
  37578:	add	x0, x0, #0x1b1 ; literal pool for: "com.anlai.omnicar/prefschanged"
  3757c:	bl	0x55c70 ; symbol stub for: _notify_post
  37584:	bl	0x59ca0
  3758c:	add	x0, x0, #0xa68 ; Objc cfstring ref: @"parentController"
  37590:	bl	0x55b08 ; symbol stub for: _NSSelectorFromString
  3759c:	bl	0x55d6c ; symbol stub for: _objc_opt_respondsToSelector
  375a8:	add	x0, x0, #0xa68 ; Objc cfstring ref: @"parentController"
  375ac:	bl	0x55b08 ; symbol stub for: _NSSelectorFromString
  375b8:	bl	0x55d30 ; Objc message: +[NSString _applicationIconImageForBundleIdentifier:format:scale:]
  375c0:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  375d4:	ldr	x1, [x8, #0xef8] ; Objc selector ref: reloadSpecifier:
  375dc:	bl	0x55d6c ; symbol stub for: _objc_opt_respondsToSelector
  375e8:	bl	0x5cdc0
  375f0:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  37600:	bl	0x59d20
  37608:	bl	0x55d78 ; symbol stub for: _objc_release
  37618:	bl	0x55c28 ; symbol stub for: _dispatch_time
  37658:	bl	0x55bd4 ; symbol stub for: _dispatch_after
  37660:	bl	0x55d78 ; symbol stub for: _objc_release
  37668:	bl	0x55d78 ; symbol stub for: _objc_release
  37670:	bl	0x55d78 ; symbol stub for: _objc_release
  37678:	bl	0x55d78 ; symbol stub for: _objc_release
  376b0:	bl	0x55d84 ; symbol stub for: _objc_retain
  376b8:	bl	0x55d84 ; symbol stub for: _objc_retain
  376c0:	ldr	x0, [x8, #0x958] ; Objc class ref: _OBJC_CLASS_$_NSString
  376c4:	bl	0x55d48 ; symbol stub for: _objc_opt_class
  376d0:	bl	0x55d54 ; symbol stub for: _objc_opt_isKindOfClass
  376dc:	add	x21, x21, #0x28 ; Objc cfstring ref: @"com.anlai.omnicar"
  376ec:	bl	0x55874 ; symbol stub for: _CFPreferencesSetAppValue
  376f4:	bl	0x55850 ; symbol stub for: _CFPreferencesAppSynchronize
  376fc:	bl	0x55d78 ; symbol stub for: _objc_release
  37710:	b	0x55d78 ; symbol stub for: _objc_release
  37724:	bl	0x59180
  3772c:	bl	0x55d9c ; symbol stub for: _objc_retainAutoreleasedReturnValue
  37738:	bl	0x59820
  37740:	bl	0x55dfc ; symbol stub for: _objc_unsafeClaimAutoreleasedReturnValue
  37750:	b	0x55d78 ; symbol stub for: _objc_release

## SCPCarSplit.publishCarPlayApps @ 0x21b1c
Instructions 770
Relevant direct branch / selector lines:
  21b4c:	ldr	x0, [x8, #0x708] ; Objc class ref: _OBJC_CLASS_$_NSMutableArray
  21b50:	bl	0x56fe0
  21b58:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  21b6c:	bl	0x21d4c
  21b74:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  21b88:	bl	0x57a00
  21ba0:	add	x21, x21, #0xe20 ; Objc cfstring ref: @"id"
  21bbc:	bl	0x5671c ; symbol stub for: _objc_enumerationMutation
  21bcc:	bl	0x59660
  21bd4:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  21be4:	bl	0x56ca0
  21bec:	bl	0x567b8 ; symbol stub for: _objc_release
  21c0c:	bl	0x57a00
  21c1c:	bl	0x567b8 ; symbol stub for: _objc_release
  21c24:	bl	0x579e0
  21c30:	ldr	x0, [x8, #0x6d0] ; Objc class ref: SCPPrefs
  21c38:	bl	0x5a980
  21c40:	ldr	x21, [x8, #0x678] ; Objc class ref: _OBJC_CLASS_$_NSString
  21c48:	bl	0x579e0
  21c50:	bl	0x22210
  21c58:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  21c60:	bl	0x579e0
  21c6c:	add	x2, x2, #0xe00 ; Objc cfstring ref: @"CarSplit: %lu app CarPlay cho Settings, %lu app iPhone da chon (App Bridge)"
  21c74:	bl	0x5c440
  21c7c:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  21c88:	add	x0, x0, #0x5c0 ; Objc cfstring ref: @"SplitScreen"
  21c90:	bl	_OMCLogWrite
  21c98:	bl	0x567b8 ; symbol stub for: _objc_release
  21ca0:	bl	0x567b8 ; symbol stub for: _objc_release
  21ca8:	bl	0x567b8 ; symbol stub for: _objc_release
  21ce0:	bl	0x56404 ; symbol stub for: ___stack_chk_fail
  21cec:	bl	0x567b8 ; symbol stub for: _objc_release
  21d04:	bl	0x567b8 ; symbol stub for: _objc_release
  21d20:	bl	0x567b8 ; symbol stub for: _objc_release
  21d30:	bl	0x567b8 ; symbol stub for: _objc_release
  21d38:	bl	0x567b8 ; symbol stub for: _objc_release
  21d48:	bl	0x563e0 ; symbol stub for: __Unwind_Resume
  21d80:	ldr	x0, [x8, #0x708] ; Objc class ref: _OBJC_CLASS_$_NSMutableArray
  21d84:	bl	0x56fe0
  21d8c:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  21d94:	bl	0x4672c
  21d9c:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  21db0:	bl	0x567c4 ; symbol stub for: _objc_retain
  21db8:	add	x0, x0, #0x9a0 ; Objc cfstring ref: @"allInstalledApplications"
  21dbc:	bl	0x56374 ; symbol stub for: _NSSelectorFromString
  21dcc:	bl	0x567a0 ; symbol stub for: _objc_opt_respondsToSelector
  21ddc:	bl	0x56758 ; Objc message: +[NSMutableArray init]
  21de4:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  21dfc:	add	x1, x1, #0x9a0 ; Objc cfstring ref: @"allInstalledApplications"
  21e04:	bl	_SCPMissingSelector
  21e10:	bl	0x567b8 ; symbol stub for: _objc_release
  21e14:	bl	0xdb30
  21e1c:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  21e38:	bl	0x567c4 ; symbol stub for: _objc_retain
  21e4c:	bl	0x57a00
  21e60:	add	x23, x23, #0x80 ; Objc cfstring ref: @"displayName"
  21e68:	add	x25, x25, #0x800 ; Objc cfstring ref: @"bundleIdentifier"
  21e88:	bl	0x5671c ; symbol stub for: _objc_enumerationMutation
  21e98:	bl	0xffb4
  21ea4:	bl	0x567c4 ; symbol stub for: _objc_retain
  21eac:	bl	0x56374 ; symbol stub for: _NSSelectorFromString
  21ebc:	bl	0x567a0 ; symbol stub for: _objc_opt_respondsToSelector
  21ecc:	bl	0x56758 ; Objc message: -[x0 init]
  21ed4:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  21ee8:	bl	_SCPMissingSelector
  21ef4:	bl	0x567b8 ; symbol stub for: _objc_release
  21efc:	bl	0x567c4 ; symbol stub for: _objc_retain
  21f04:	bl	0x56374 ; symbol stub for: _NSSelectorFromString
  21f14:	bl	0x567a0 ; symbol stub for: _objc_opt_respondsToSelector
  21f24:	bl	0x56758 ; Objc message: -[x0 init]
  21f2c:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  21f40:	bl	_SCPMissingSelector
  21f54:	bl	0x567b8 ; symbol stub for: _objc_release
  21f64:	bl	0x57820
  21f70:	add	x8, x8, #0xe20 ; Objc cfstring ref: @"id"
  21f7c:	add	x8, x8, #0x840 ; Objc cfstring ref: @"name"
  21f88:	bl	0x590c0
  21f9c:	ldr	x0, [x8, #0x6b8] ; Objc class ref: _OBJC_CLASS_$_NSDictionary
  21fac:	bl	0x57bc0
  21fb4:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  21fc4:	bl	0x56ca0
  21fcc:	bl	0x567b8 ; symbol stub for: _objc_release
  21fd4:	bl	0x567b8 ; symbol stub for: _objc_release
  21fdc:	bl	0x567b8 ; symbol stub for: _objc_release
  21ffc:	bl	0x57a00
  2200c:	bl	0x567b8 ; symbol stub for: _objc_release
  22044:	bl	0x567c4 ; symbol stub for: _objc_retain
  22054:	bl	0x5c260
  22064:	ldr	x0, [x8, #0x810] ; Objc class ref: _OBJC_CLASS_$_NSSortDescriptor
  2206c:	ldr	x4, [x8, #0xc08] ; Objc selector ref: localizedCaseInsensitiveCompare:
  22074:	add	x2, x2, #0x840 ; Objc cfstring ref: @"name"
  2207c:	bl	0x5c240
  22084:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  22094:	ldr	x0, [x8, #0x680] ; Objc class ref: _OBJC_CLASS_$_NSArray
  220a0:	bl	0x57080
  220a8:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  220b8:	bl	0x5c280
  220c0:	bl	0x567b8 ; symbol stub for: _objc_release
  220c8:	bl	0x567b8 ; symbol stub for: _objc_release
  220d0:	bl	0x567b8 ; symbol stub for: _objc_release
  220d8:	bl	0x567b8 ; symbol stub for: _objc_release
  220e0:	bl	0x567b8 ; symbol stub for: _objc_release
  2211c:	b	0x566e0 ; symbol stub for: _objc_autoreleaseReturnValue
  22120:	bl	0x56404 ; symbol stub for: ___stack_chk_fail
  2212c:	bl	0x567b8 ; symbol stub for: _objc_release
  2213c:	bl	0x567b8 ; symbol stub for: _objc_release
  22154:	bl	0x567b8 ; symbol stub for: _objc_release
  2217c:	bl	0x567b8 ; symbol stub for: _objc_release
  22190:	bl	0x567b8 ; symbol stub for: _objc_release
  221b4:	bl	0x567b8 ; symbol stub for: _objc_release

## SCPCarSplit.showPickerForSlot: @ 0x31530
Instructions 268
Relevant direct branch / selector lines:
  31554:	bl	0x56b00
  31564:	bl	0x5ca60
  31570:	bl	0x57140
  31580:	bl	0x597e0
  31588:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  3159c:	bl	0x5a3e0
  315ac:	bl	0x5a340
  315b4:	ldr	x0, [x25, #0x710] ; Objc class ref: _OBJC_CLASS_$_UIView
  315b8:	bl	0x566c8 ; symbol stub for: _objc_alloc_init
  315c8:	bl	0x5b580
  315d4:	bl	0x58360
  315e4:	bl	0x5ae20
  315ec:	ldr	x0, [x23, #0x730] ; Objc class ref: _OBJC_CLASS_$_UIColor
  3160c:	bl	0x576e0
  31614:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  31624:	bl	0x5a860
  3162c:	bl	0x567b8 ; symbol stub for: _objc_release
  31638:	bl	0x5a820
  3165c:	bl	0x576e0
  31664:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  3166c:	bl	0x567d0 ; symbol stub for: _objc_retainAutorelease
  31670:	bl	0x569a0
  3167c:	bl	0x58fa0
  31684:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  31690:	bl	0x5a8e0
  31698:	bl	0x567b8 ; symbol stub for: _objc_release
  316a0:	bl	0x567b8 ; symbol stub for: _objc_release
  316a8:	ldr	x0, [x8, #0x790] ; Objc class ref: _OBJC_CLASS_$_UILabel
  316ac:	bl	0x566bc ; symbol stub for: _objc_alloc
  316b8:	bl	0x57320
  316c0:	bl	0x589c0
  316cc:	add	x2, x2, #0x720 ; Objc cfstring ref: @"+"
  316d0:	bl	0x5bb00
  316d4:	bl	0x2b380
  316dc:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  316ec:	bl	0x576a0
  316f4:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  31704:	bl	0x5bb40
  3170c:	bl	0x567b8 ; symbol stub for: _objc_release
  31714:	bl	0x567b8 ; symbol stub for: _objc_release
  3171c:	ldr	x0, [x8, #0x798] ; Objc class ref: _OBJC_CLASS_$_UIFont
  31734:	bl	0x5c5c0
  3173c:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  3174c:	bl	0x5ade0
  31754:	bl	0x567b8 ; symbol stub for: _objc_release
  31760:	bl	0x5bb20
  3176c:	bl	0x5a820
  31778:	bl	0x56d40
  31780:	ldr	x0, [x8, #0x768] ; Objc class ref: _OBJC_CLASS_$_UITapGestureRecognizer
  31784:	bl	0x566bc ; symbol stub for: _objc_alloc
  3178c:	ldr	x3, [x8, #0xbc8] ; Objc selector ref: pickerPaneTapped:
  31794:	bl	0x58a40
  317a4:	bl	0x56c60
  317ac:	bl	0x567b8 ; symbol stub for: _objc_release
  317b4:	bl	0x5cb60
  317bc:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  317c8:	bl	0x56d40
  317d0:	bl	0x567b8 ; symbol stub for: _objc_release
  317d8:	bl	0x5cb60
  317e0:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  317ec:	bl	0x583c0
  317f4:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  31804:	bl	0x573e0
  3180c:	bl	0x567b8 ; symbol stub for: _objc_release
  31814:	bl	0x567b8 ; symbol stub for: _objc_release
  31820:	bl	0x5a160
  3182c:	bl	0x5a7c0
  31864:	bl	0x567c4 ; symbol stub for: _objc_retain
  31878:	bl	0x56ea0
  31880:	bl	0x5a100
  31888:	bl	0x567b8 ; symbol stub for: _objc_release
  31890:	bl	0x567b8 ; symbol stub for: _objc_release
  31898:	bl	0x567b8 ; symbol stub for: _objc_release
  318a0:	bl	0x567b8 ; symbol stub for: _objc_release
  318ec:	bl	0x567b8 ; symbol stub for: _objc_release
  31900:	bl	0x567b8 ; symbol stub for: _objc_release
  31938:	bl	0x567b8 ; symbol stub for: _objc_release
  31940:	bl	0x567b8 ; symbol stub for: _objc_release
  31948:	bl	0x567b8 ; symbol stub for: _objc_release
  31950:	bl	0x563e0 ; symbol stub for: __Unwind_Resume

## SCPCarSplit.refreshPickerSheet @ 0x31eac
Instructions 264
Relevant direct branch / selector lines:
  31ee0:	bl	0x56b60
  31eec:	bl	0x56e20
  31ef4:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  31f04:	ldr	x19, [x19, #0x238] ; literal pool symbol address: ___NSArray0__struct
  31f0c:	bl	0x59aa0
  31f14:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  31f1c:	bl	0x599e0
  31f24:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  31f38:	bl	0x57820
  31f44:	bl	0x567b8 ; symbol stub for: _objc_release
  31f50:	bl	0x567b8 ; symbol stub for: _objc_release
  31f5c:	bl	0x56b60
  31f68:	bl	0x59900
  31f70:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  31f80:	ldr	x21, [x21, #0x238] ; literal pool symbol address: ___NSArray0__struct
  31f94:	bl	0x567c4 ; symbol stub for: _objc_retain
  31fa8:	bl	0x57a00
  31fd4:	bl	0x5671c ; symbol stub for: _objc_enumerationMutation
  31fe8:	bl	0x599e0
  31ff0:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  31ffc:	bl	0x567b8 ; symbol stub for: _objc_release
  32008:	bl	0x567c4 ; symbol stub for: _objc_retain
  32034:	bl	0x57a00
  32044:	bl	0x567b8 ; symbol stub for: _objc_release
  32050:	bl	0x5b620
  3205c:	bl	0x57800
  32064:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  3206c:	bl	0x5cc20
  32074:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  32080:	bl	0x567b8 ; symbol stub for: _objc_release
  32088:	bl	0x567b8 ; symbol stub for: _objc_release
  32094:	ldr	x23, [x8, #0x678] ; Objc class ref: _OBJC_CLASS_$_NSString
  3209c:	bl	0x5c100
  320a8:	bl	0x579e0
  320b4:	bl	0x59260
  320c0:	bl	0x57800
  320c8:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  320d0:	bl	0x57320
  320dc:	bl	0x563a4 ; symbol stub for: _NSStringFromCGSize
  320e4:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  320fc:	add	x2, x2, #0x760 ; Objc cfstring ref: @"%p/%d/%lu/%d/%@"
  32104:	bl	0x5c440
  3210c:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  32118:	bl	0x567b8 ; symbol stub for: _objc_release
  32120:	bl	0x567b8 ; symbol stub for: _objc_release
  32128:	bl	0x59a40
  32130:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  32140:	bl	0x59a60
  32148:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  32158:	bl	0x58d00
  32164:	bl	0x567b8 ; symbol stub for: _objc_release
  3216c:	bl	0x567b8 ; symbol stub for: _objc_release
  3217c:	bl	0x57400
  32188:	bl	0x5b5e0
  32190:	bl	0x592e0
  32198:	bl	0x567b8 ; symbol stub for: _objc_release
  321a4:	bl	0x5a400
  321ac:	bl	0x567b8 ; symbol stub for: _objc_release
  321b4:	bl	0x567b8 ; symbol stub for: _objc_release
  321bc:	bl	0x567b8 ; symbol stub for: _objc_release
  321f8:	bl	0x56404 ; symbol stub for: ___stack_chk_fail
  32204:	bl	0x567b8 ; symbol stub for: _objc_release
  32214:	bl	0x567b8 ; symbol stub for: _objc_release
  32224:	bl	0x567b8 ; symbol stub for: _objc_release
  32238:	bl	0x567b8 ; symbol stub for: _objc_release
  32248:	bl	0x567b8 ; symbol stub for: _objc_release
  32258:	bl	0x567b8 ; symbol stub for: _objc_release
  3227c:	bl	0x567b8 ; symbol stub for: _objc_release
  322a0:	bl	0x567b8 ; symbol stub for: _objc_release
  322a8:	bl	0x567b8 ; symbol stub for: _objc_release
  322b0:	bl	0x567b8 ; symbol stub for: _objc_release
  322b8:	bl	0x567b8 ; symbol stub for: _objc_release
  322c8:	bl	0x563e0 ; symbol stub for: __Unwind_Resume

## SCPCarSplit.buildPickerSheetForPane: @ 0x334cc
Instructions 2933
Relevant direct branch / selector lines:
  33518:	bl	0x567c4 ; symbol stub for: _objc_retain
  33520:	bl	0x59a40
  33528:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  33534:	bl	0x59ae0
  3353c:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  33548:	bl	0x57800
  33550:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  33560:	bl	0x5c8e0
  33568:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  33574:	bl	0x567b8 ; symbol stub for: _objc_release
  33584:	bl	0x57800
  3358c:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  33598:	bl	0x57800
  335a0:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  335a8:	bl	0x57320
  335b4:	bl	0x57960
  335cc:	bl	0x567b8 ; symbol stub for: _objc_release
  335d4:	bl	0x567b8 ; symbol stub for: _objc_release
  335e0:	bl	0x567c4 ; symbol stub for: _objc_retain
  335f0:	bl	0x57800
  335f8:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  33600:	bl	0x57320
  33618:	bl	0x567b8 ; symbol stub for: _objc_release
  33620:	bl	0x57800
  33628:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  33638:	bl	0x5a2c0
  33640:	ldr	x0, [x26, #0x708] ; Objc class ref: _OBJC_CLASS_$_NSMutableArray
  33644:	bl	0x56fe0
  3364c:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  33658:	bl	0x58200
  33660:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  3366c:	bl	0x567b8 ; symbol stub for: _objc_release
  3367c:	bl	0x21d4c
  33684:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  3368c:	bl	0x22210
  33694:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  336a4:	bl	0x57020
  336ac:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  336b8:	bl	0x567b8 ; symbol stub for: _objc_release
  336c0:	bl	0x567b8 ; symbol stub for: _objc_release
  336d4:	bl	0x57a00
  336ec:	add	x22, x22, #0xe20 ; Objc cfstring ref: @"id"
  33708:	bl	0x5671c ; symbol stub for: _objc_enumerationMutation
  33728:	bl	0x59660
  33730:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  33738:	bl	0x101bc
  33744:	bl	0x567b8 ; symbol stub for: _objc_release
  33754:	bl	0x56ca0
  33774:	bl	0x57a00
  33784:	bl	0x567b8 ; symbol stub for: _objc_release
  3378c:	bl	0x57800
  33794:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  3379c:	bl	0x57320
  337ac:	bl	0x567b8 ; symbol stub for: _objc_release
  337f0:	bl	0x58200
  337f8:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  33818:	add	x0, x0, #0x7c0 ; Objc cfstring ref: @"C"
  33820:	add	x1, x1, #0x7e0 ; Objc cfstring ref: @"Choose an app for pane %d"
  33824:	bl	_OMCTr
  3382c:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  33838:	bl	0x5c100
  3384c:	bl	0x5c440
  33854:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  33860:	bl	0x567b8 ; symbol stub for: _objc_release
  3386c:	add	x0, x0, #0x780 ; Objc cfstring ref: @"C"
  33874:	add	x1, x1, #0x7a0 ; Objc cfstring ref: @"Choose an app for the floating window"
  33878:	bl	_OMCTr
  33880:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  3388c:	bl	0x567b8 ; symbol stub for: _objc_release
  33894:	add	x0, x0, #0x800 ; Objc cfstring ref: @"C"
  3389c:	add	x1, x1, #0x820 ; Objc cfstring ref: @"Tap an app to open it here"
  338a0:	bl	_OMCTr
  338a8:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  338b4:	ldr	x0, [x19, #0x798] ; Objc class ref: _OBJC_CLASS_$_UIFont
  338c8:	bl	0x5c5c0
  338d0:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  338e0:	bl	0x5c5a0
  338e8:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  3390c:	ldr	x0, [x21, #0x6b8] ; Objc class ref: _OBJC_CLASS_$_NSDictionary
  3391c:	bl	0x57bc0
  33924:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  33950:	bl	0x57300
  3395c:	bl	0x567b8 ; symbol stub for: _objc_release
  3397c:	bl	0x57bc0
  33984:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  339a4:	bl	0x57300
  339b0:	bl	0x567b8 ; symbol stub for: _objc_release
  339bc:	bl	0x579e0
  33a0c:	bl	0x579e0
  33a5c:	bl	0x579e0
  33b30:	bl	0x562cc ; symbol stub for: _CGRectGetMidX
  33b48:	bl	0x562d8 ; symbol stub for: _CGRectGetMidY
  33b54:	ldr	x0, [x8, #0x710] ; Objc class ref: _OBJC_CLASS_$_UIView
  33b58:	bl	0x566bc ; symbol stub for: _objc_alloc
  33ba0:	bl	0x589c0
  33bac:	bl	0x58fa0
  33bb4:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  33bc0:	bl	0x5aaa0
  33bc8:	bl	0x567b8 ; symbol stub for: _objc_release
  33bd0:	bl	0x58fa0
  33bd8:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  33bf0:	bl	0x5aa80
  33bf8:	bl	0x567b8 ; symbol stub for: _objc_release
  33c00:	ldr	x0, [x8, #0x730] ; Objc class ref: _OBJC_CLASS_$_UIColor
  33c28:	bl	0x576e0
  33c30:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  33c38:	bl	0x567d0 ; symbol stub for: _objc_retainAutorelease
  33c40:	bl	0x569a0
  33c4c:	bl	0x58fa0
  33c54:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue

## SCPCarSplit.pickerAppTapped: @ 0x362a0
Instructions 140
Relevant direct branch / selector lines:
  362c4:	bl	0x567c4 ; symbol stub for: _objc_retain
  362cc:	bl	0x59aa0
  362d4:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  362e8:	bl	0x59840
  362f0:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  36300:	bl	0x56aa0
  36308:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  36314:	ldr	x23, [x8, #0x678] ; Objc class ref: _OBJC_CLASS_$_NSString
  3631c:	bl	0x5c100
  36328:	add	x2, x2, #0x8e0 ; Objc cfstring ref: @"CarSplit: chon %@ cho o %d"
  36330:	bl	0x5c440
  36338:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  36344:	add	x0, x0, #0x5c0 ; Objc cfstring ref: @"SplitScreen"
  3634c:	bl	_OMCLogWrite
  36354:	bl	0x567b8 ; symbol stub for: _objc_release
  3635c:	bl	0x5c100
  3636c:	bl	0x596a0
  36374:	bl	0x599e0
  3637c:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  36384:	bl	0x567b8 ; symbol stub for: _objc_release
  36390:	bl	0x5a100
  36398:	bl	0x567b8 ; symbol stub for: _objc_release
  363a0:	bl	0x567b8 ; symbol stub for: _objc_release
  363bc:	b	0x567b8 ; symbol stub for: _objc_release
  363d4:	bl	0x567b8 ; symbol stub for: _objc_release
  36400:	bl	0x567b8 ; symbol stub for: _objc_release
  36408:	bl	0x567b8 ; symbol stub for: _objc_release
  36418:	bl	0x566ec ; symbol stub for: _objc_begin_catch
  36420:	bl	0x567c4 ; symbol stub for: _objc_retain
  36428:	ldr	x21, [x8, #0x678] ; Objc class ref: _OBJC_CLASS_$_NSString
  36430:	bl	0x574a0
  36438:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  36448:	add	x2, x2, #0x900 ; Objc cfstring ref: @"CarSplit: loi chon app %@
  36450:	bl	0x5c440
  36458:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  36464:	add	x0, x0, #0x5c0 ; Objc cfstring ref: @"SplitScreen"
  3646c:	bl	_OMCLogWrite
  36474:	bl	0x567b8 ; symbol stub for: _objc_release
  3647c:	bl	0x567b8 ; symbol stub for: _objc_release
  36484:	bl	0x567b8 ; symbol stub for: _objc_release
  36488:	bl	0x56710 ; symbol stub for: _objc_end_catch
  36498:	bl	0x567b8 ; symbol stub for: _objc_release
  364a8:	bl	0x567b8 ; symbol stub for: _objc_release
  364b8:	bl	0x567b8 ; symbol stub for: _objc_release
  364bc:	bl	0x56710 ; symbol stub for: _objc_end_catch
  364c4:	bl	0x567b8 ; symbol stub for: _objc_release
  364cc:	bl	0x563e0 ; symbol stub for: __Unwind_Resume

## SCPCarSplit.isCarPlayApp: @ 0xff20
Instructions 223
Relevant direct branch / selector lines:
  ff38:	bl	0x567c4 ; symbol stub for: _objc_retain
  ff40:	bl	0xe324
  ff48:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  ff50:	bl	0xffb4
  ff64:	bl	0x101bc
  ff70:	bl	0x567b8 ; symbol stub for: _objc_release
  ff78:	bl	0x567b8 ; symbol stub for: _objc_release
  ffa0:	bl	0x567b8 ; symbol stub for: _objc_release
  ffa8:	bl	0x567b8 ; symbol stub for: _objc_release
  ffb0:	bl	0x563e0 ; symbol stub for: __Unwind_Resume
  ffc8:	bl	0x567c4 ; symbol stub for: _objc_retain
  ffd4:	bl	0x567c4 ; symbol stub for: _objc_retain
  ffdc:	add	x0, x0, #0x800 ; Objc cfstring ref: @"bundleIdentifier"
  ffe0:	bl	0x56374 ; symbol stub for: _NSSelectorFromString
  fff0:	bl	0x567a0 ; symbol stub for: _objc_opt_respondsToSelector
  10000:	bl	0x56758 ; Objc message: +[NSMutableDictionary init]
  10008:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  10020:	add	x1, x1, #0x800 ; Objc cfstring ref: @"bundleIdentifier"
  10028:	bl	_SCPMissingSelector
  10034:	bl	0x567b8 ; symbol stub for: _objc_release
  1003c:	bl	0x590c0
  10048:	add	x2, x2, #0x60 ; Objc cfstring ref: @"com.apple.CarPlayTemplateUIHost"
  10050:	bl	0x58d00
  1005c:	add	x2, x2, #0x580 ; Objc cfstring ref: @"com.apple.CarPlayApp"
  10064:	bl	0x58d00
  10070:	add	x2, x2, #0xa60 ; Objc cfstring ref: @"com.apple.CarPlaySettings"
  10078:	bl	0x58d00
  10084:	add	x2, x2, #0xd20 ; Objc cfstring ref: @"com.apple.InCallService"
  1008c:	bl	0x58d00
  10098:	bl	_SCPIsInjectedPhoneApp
  100a4:	add	x0, x0, #0x9e0 ; Objc cfstring ref: @"carPlayDeclaration"
  100a8:	bl	0x56374 ; symbol stub for: _NSSelectorFromString
  100b4:	bl	0x567a0 ; symbol stub for: _objc_opt_respondsToSelector
  100c0:	bl	0x567c4 ; symbol stub for: _objc_retain
  100c8:	add	x0, x0, #0x9e0 ; Objc cfstring ref: @"carPlayDeclaration"
  100cc:	bl	0x56374 ; symbol stub for: _NSSelectorFromString
  100dc:	bl	0x567a0 ; symbol stub for: _objc_opt_respondsToSelector
  100ec:	bl	0x56758 ; Objc message: -[x0 init]
  100f4:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  10104:	add	x1, x1, #0x9e0 ; Objc cfstring ref: @"carPlayDeclaration"
  1010c:	bl	_SCPMissingSelector
  10118:	bl	0x567b8 ; symbol stub for: _objc_release
  10120:	bl	0x567b8 ; symbol stub for: _objc_release
  1012c:	add	x1, x1, #0x580 ; Objc cfstring ref: @"isHidden"
  10134:	bl	0x17d84
  10144:	bl	0x567b8 ; symbol stub for: _objc_release
  1014c:	bl	0x567b8 ; symbol stub for: _objc_release
  10168:	add	x1, x1, #0x5c0 ; Objc cfstring ref: @"presentsFullScreen"
  10170:	bl	0x17d84
  10188:	bl	0x567b8 ; symbol stub for: _objc_release
  101a8:	bl	0x567b8 ; symbol stub for: _objc_release
  101b0:	bl	0x567b8 ; symbol stub for: _objc_release
  101b8:	bl	0x563e0 ; symbol stub for: __Unwind_Resume
  101d0:	bl	0x567c4 ; symbol stub for: _objc_retain
  101d8:	bl	0x590c0
  101e4:	add	x0, x0, #0x380 ; Objc cfstring ref: @"appBridge"
  101e8:	bl	_OMCFeatureEnabled
  101f4:	bl	_SCPIsInjectedPhoneApp
  10208:	bl	0xe324
  10210:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  10218:	bl	0xffb4
  10224:	bl	0x567b8 ; symbol stub for: _objc_release
  10234:	bl	0x567b8 ; symbol stub for: _objc_release
  1024c:	bl	0x48864
  10254:	bl	0x567dc ; symbol stub for: _objc_retainAutoreleasedReturnValue
  10260:	bl	0x57820
  1026c:	bl	0x567b8 ; symbol stub for: _objc_release
  10280:	bl	0x567b8 ; symbol stub for: _objc_release
  10290:	bl	0x567b8 ; symbol stub for: _objc_release
  10298:	bl	0x563e0 ; symbol stub for: __Unwind_Resume

## Next
Trace Objective-C stub target selectors for the verified branch callsites before claiming a specific persistence API.
Keep separate iPhone allowlist, CarPlay native system apps, in-car slot selection and CarPlay Home app publication.
No DuoFace runtime changes or Sileo release.
