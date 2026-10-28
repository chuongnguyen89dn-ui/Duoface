# Original Native12 22 UI controller methods source-verified ARM64

Original DEB SHA verified. Original machine IMPs/selector references, no runtime execution.

**Only IMP body and direct selector/CFString refs are proved, not on-device UI behavior.**
**iPhone UI controller and CarPlay split/menu owner are separated by binary and process.**
**Follow per-controller actions and screen ownership; never infer vendor license/UI from names.**
**Do NOT assert pixel or device parity from a disassembly output.**

## DuoFaceUI / CBAppPickerViewController.tableView:didSelectRowAtIndexPath: @ 0x10001550c
Instructions: 123
Selector/CFString references:
    100015530:	ldr	x22, [x8, #0x8f8] ; Objc selector ref: deselectRowAtIndexPath:animated:
    100015558:	ldr	x1, [x8, #0xba0] ; Objc selector ref: filteredApps
    100015574:	ldr	x1, [x8, #0x830] ; Objc selector ref: row
    100015590:	ldr	x1, [x8, #0xab0] ; Objc selector ref: objectAtIndexedSubscript:
    1000155b8:	ldr	x22, [x8, #0xb80] ; Objc selector ref: valueForKey:
    1000155bc:	adr	x2, #875020 ; Objc cfstring ref: @"bundleIdentifier"
    1000155e0:	ldr	x1, [x8, #0xba8] ; Objc selector ref: disabledBundleIDs
    1000155fc:	ldr	x1, [x8, #0x5d8] ; Objc selector ref: containsObject:
    10001561c:	ldr	x23, [x8, #0xbc8] ; Objc selector ref: onSelectApp
    100015658:	adr	x2, #874896 ; Objc cfstring ref: @"displayName"
    1000156a0:	ldr	x1, [x8, #0x738] ; Objc selector ref: navigationController
    1000156bc:	ldr	x1, [x8, #0xbd0] ; Objc selector ref: popViewControllerAnimated:

## DuoFaceUI / CBAppPickerViewController.tableView:cellForRowAtIndexPath: @ 0x100014f1c
Instructions: 380
Selector/CFString references:
    100014f4c:	ldr	x23, [x8, #0xb38] ; Objc selector ref: dequeueReusableCellWithIdentifier:
    100014f5c:	adr	x2, #876748 ; Objc cfstring ref: @"PickerCell"
    100014f94:	ldr	x1, [x8, #0x7e8] ; Objc selector ref: initWithStyle:reuseIdentifier:
    100014f98:	adr	x3, #876688 ; Objc cfstring ref: @"PickerCell"
    100014fd4:	ldr	x1, [x8, #0x9b8] ; Objc selector ref: layer
    100014fec:	ldr	x1, [x8, #0x9c0] ; Objc selector ref: setCornerRadius:
    100015024:	ldr	x1, [x8, #0xb40] ; Objc selector ref: setClipsToBounds:
    100015040:	ldr	x1, [x8, #0xba0] ; Objc selector ref: filteredApps
    10001505c:	ldr	x1, [x8, #0x830] ; Objc selector ref: row
    100015078:	ldr	x1, [x8, #0xab0] ; Objc selector ref: objectAtIndexedSubscript:
    1000150a0:	ldr	x23, [x8, #0xb80] ; Objc selector ref: valueForKey:
    1000150a4:	adr	x2, #876324 ; Objc cfstring ref: @"bundleIdentifier"
    1000150c8:	ldr	x1, [x8, #0xba8] ; Objc selector ref: disabledBundleIDs
    1000150e4:	ldr	x1, [x8, #0x5d8] ; Objc selector ref: containsObject:
    1000150fc:	adr	x2, #876364 ; Objc cfstring ref: @"icon"
    100015138:	ldr	x1, [x8, #0x3d0] ; Objc selector ref: systemImageNamed:
    10001513c:	adr	x2, #876332 ; Objc cfstring ref: @"app.dashed"
    100015178:	ldr	x1, [x8, #0x858] ; Objc selector ref: setImage:
    1000151a0:	adr	x2, #876104 ; Objc cfstring ref: @"displayName"
    1000151c4:	ldr	x25, [x8, #0x7f8] ; Objc selector ref: textLabel
    1000151e4:	ldr	x23, [x8, #0x838] ; Objc selector ref: setText:
    100015214:	ldr	x24, [x8, #0xbb0] ; Objc selector ref: tertiaryLabelColor
    100015248:	ldr	x25, [x8, #0x848] ; Objc selector ref: setTextColor:
    10001527c:	ldr	x1, [x8, #0x3c8] ; Objc selector ref: localizedStringForKey:
    100015280:	adr	x2, #876040 ; Objc cfstring ref: @"IN_USE_ELSEWHERE"
    10001529c:	ldr	x1, [x8, #0x520] ; Objc selector ref: stringWithFormat:
    1000152a4:	adr	x2, #875300 ; Objc cfstring ref: @"%@ (%@)"
    100015384:	ldr	x1, [x8, #0xbb8] ; Objc selector ref: setAlpha:
    1000153a4:	ldr	x1, [x8, #0x9f0] ; Objc selector ref: labelColor
    1000153d4:	ldr	x24, [x8, #0x848] ; Objc selector ref: setTextColor:
    1000153f8:	ldr	x21, [x8, #0x810] ; Objc selector ref: detailTextLabel
    100015430:	ldr	x1, [x8, #0x840] ; Objc selector ref: secondaryLabelColor
    100015494:	ldr	x1, [x8, #0xbb8] ; Objc selector ref: setAlpha:
    1000154b4:	ldr	x1, [x8, #0x7f0] ; Objc selector ref: setSelectionStyle:
    1000154c8:	ldr	x1, [x8, #0xbc0] ; Objc selector ref: setUserInteractionEnabled:

## DuoFaceUI / CBAppPickerViewController.viewDidLoad @ 0x100014768
Instructions: 379
Selector/CFString references:
    1000147ac:	ldr	x1, [x8, #0x398] ; Objc selector ref: viewDidLoad
    1000147c4:	ldr	x1, [x8, #0x3c8] ; Objc selector ref: localizedStringForKey:
    1000147c8:	adr	x2, #878560 ; Objc cfstring ref: @"PICK_APP_TITLE"
    1000147e8:	ldr	x1, [x8, #0x478] ; Objc selector ref: setTitle:
    10001480c:	ldr	x1, [x8, #0x548] ; Objc selector ref: array
    100014830:	ldr	x1, [x8, #0xab8] ; Objc selector ref: apps
    100014850:	ldr	x1, [x8, #0x4d8] ; Objc selector ref: countByEnumeratingWithState:objects:count:
    100014888:	ldr	x22, [x8, #0xb80] ; Objc selector ref: valueForKey:
    1000148a4:	ldr	x8, [x8, #0x5e8] ; Objc selector ref: addObject:
    1000148d4:	adr	x2, #878324 ; Objc cfstring ref: @"bundleIdentifier"
    1000148f4:	adr	x2, #878324 ; Objc cfstring ref: @"displayName"
    1000149d0:	adr	x2, #871128 ; Objc cfstring ref: @"BarcodeScanner"
    1000149e8:	adr	x2, #871136 ; Objc cfstring ref: @"PrintKit"
    100014a00:	adr	x2, #871144 ; Objc cfstring ref: @"Print-Center"
    100014a18:	adr	x2, #871152 ; Objc cfstring ref: @"Barcode"
    100014a30:	adr	x2, #871160 ; Objc cfstring ref: @"Scan QR"
    100014a48:	adr	x2, #871168 ; Objc cfstring ref: @"M"
    100014a60:	adr	x2, #871176 ; Objc cfstring ref: @"Code Scanner"
    100014a78:	adr	x2, #871184 ; Objc cfstring ref: @"Print Center"
    100014ae8:	adr	x2, #871104 ; Objc cfstring ref: @"T"
    100014b8c:	ldr	x1, [x8, #0xaf0] ; Objc selector ref: setApps:
    100014bbc:	ldr	x1, [x8, #0xb88] ; Objc selector ref: setFilteredApps:
    100014be4:	ldr	x1, [x8, #0xa60] ; Objc selector ref: initWithSearchResultsController:
    100014c10:	ldr	x1, [x8, #0xa68] ; Objc selector ref: setSearchResultsUpdater:
    100014c24:	ldr	x1, [x8, #0xa78] ; Objc selector ref: setObscuresBackgroundDuringPresentation:
    100014c38:	adr	x2, #876848 ; Objc cfstring ref: @"SEARCH_PLACEHOLDER"
    100014c5c:	ldr	x1, [x8, #0xa70] ; Objc selector ref: searchBar
    100014c74:	ldr	x1, [x8, #0xa80] ; Objc selector ref: setPlaceholder:
    100014c98:	ldr	x20, [x8, #0x758] ; Objc selector ref: navigationItem
    100014cb8:	ldr	x1, [x8, #0xa88] ; Objc selector ref: setSearchController:
    100014ce8:	ldr	x1, [x8, #0xa90] ; Objc selector ref: setHidesSearchBarWhenScrolling:
    100014d00:	ldr	x1, [x8, #0xa98] ; Objc selector ref: setDefinesPresentationContext:

## DuoFaceUI / CBAppsManagerViewController.tableView:cellForRowAtIndexPath: @ 0x100013d94
Instructions: 406
Selector/CFString references:
    100013dcc:	ldr	x1, [x8, #0xb38] ; Objc selector ref: dequeueReusableCellWithIdentifier:
    100013dd0:	adr	x2, #880920 ; Objc cfstring ref: @"CBAppManagerCell"
    100013e04:	ldr	x1, [x8, #0x7e8] ; Objc selector ref: initWithStyle:reuseIdentifier:
    100013e08:	adr	x3, #880864 ; Objc cfstring ref: @"CBAppManagerCell"
    100013e44:	ldr	x24, [x8, #0x9b8] ; Objc selector ref: layer
    100013e60:	ldr	x1, [x8, #0x9c0] ; Objc selector ref: setCornerRadius:
    100013eb8:	ldr	x1, [x8, #0x9c8] ; Objc selector ref: setCornerCurve:
    100013ef0:	ldr	x1, [x8, #0xb40] ; Objc selector ref: setClipsToBounds:
    100013f0c:	ldr	x1, [x8, #0xb48] ; Objc selector ref: appForIndexPath:
    100013f34:	ldr	x1, [x8, #0x690] ; Objc selector ref: displayName
    100013f50:	ldr	x24, [x8, #0x7f8] ; Objc selector ref: textLabel
    100013f70:	ldr	x25, [x8, #0x838] ; Objc selector ref: setText:
    100013fa8:	ldr	x1, [x8, #0x9e0] ; Objc selector ref: systemFontOfSize:weight:
    100013fdc:	ldr	x23, [x8, #0x9e8] ; Objc selector ref: setFont:
    100014000:	ldr	x24, [x8, #0x530] ; Objc selector ref: category
    100014028:	ldr	x1, [x8, #0xb50] ; Objc selector ref: categoryDisplayName
    100014044:	ldr	x27, [x8, #0x520] ; Objc selector ref: stringWithFormat:
    10001404c:	adr	x2, #880316 ; Objc cfstring ref: @"=��� "
    100014074:	ldr	x1, [x8, #0xb50] ; Objc selector ref: categoryDisplayName
    100014090:	ldr	x27, [x8, #0x520] ; Objc selector ref: stringWithFormat:
    100014098:	adr	x2, #880272 ; Objc cfstring ref: @"<ص� "
    1000140a8:	ldr	x1, [x8, #0x538] ; Objc selector ref: isSystem
    1000140c0:	ldr	x1, [x8, #0xb50] ; Objc selector ref: categoryDisplayName
    1000140dc:	ldr	x27, [x8, #0x520] ; Objc selector ref: stringWithFormat:
    1000140e8:	adr	x2, #880224 ; Objc cfstring ref: @"�&� "
    1000140f8:	adr	x2, #880240 ; Objc cfstring ref: @"=��� "
    100014124:	ldr	x26, [x8, #0x5d0] ; Objc selector ref: bundleIdentifier
    100014144:	adr	x2, #880196 ; Objc cfstring ref: @"%"
    100014168:	ldr	x27, [x8, #0x810] ; Objc selector ref: detailTextLabel
    1000141b4:	ldr	x1, [x8, #0x840] ; Objc selector ref: secondaryLabelColor
    1000141e4:	ldr	x1, [x8, #0x848] ; Objc selector ref: setTextColor:
    10001420c:	ldr	x1, [x8, #0xb58] ; Objc selector ref: systemFontOfSize:
    10001425c:	ldr	x1, [x8, #0xb60] ; Objc selector ref: icon
    100014278:	ldr	x1, [x8, #0x850] ; Objc selector ref: imageView
    100014294:	ldr	x1, [x8, #0x858] ; Objc selector ref: setImage:
    1000142b4:	ldr	x1, [x8, #0xb68] ; Objc selector ref: accessoryView
    1000142d8:	ldr	x1, [x8, #0x320] ; Objc selector ref: class
    1000142e8:	ldr	x1, [x8, #0x360] ; Objc selector ref: isKindOfClass:
    100014310:	ldr	x3, [x8, #0xb70] ; Objc selector ref: appSwitchToggled:
    100014330:	ldr	x1, [x8, #0x880] ; Objc selector ref: setAccessoryView:
    100014360:	ldr	x1, [x8, #0x650] ; Objc selector ref: setBundleIdentifier:
    10001437c:	ldr	x1, [x8, #0xae0] ; Objc selector ref: isEnabled
    100014390:	ldr	x1, [x8, #0x868] ; Objc selector ref: setOn:

## DuoFaceUI / CBAppsManagerViewController.tableView:didSelectRowAtIndexPath: @ 0x1000143ec
Instructions: 125
Selector/CFString references:
    10001442c:	ldr	x1, [x8, #0x8f8] ; Objc selector ref: deselectRowAtIndexPath:animated:
    100014444:	ldr	x1, [x8, #0xb48] ; Objc selector ref: appForIndexPath:
    100014468:	ldr	x22, [x8, #0x5d0] ; Objc selector ref: bundleIdentifier
    100014490:	ldr	x1, [x8, #0xae0] ; Objc selector ref: isEnabled
    1000144a4:	ldr	x1, [x8, #0x7c8] ; Objc selector ref: cellForRowAtIndexPath:
    1000144c4:	ldr	x25, [x8, #0xb68] ; Objc selector ref: accessoryView
    1000144e8:	ldr	x1, [x8, #0x320] ; Objc selector ref: class
    1000144f8:	ldr	x1, [x8, #0x360] ; Objc selector ref: isKindOfClass:
    100014530:	ldr	x1, [x8, #0xb78] ; Objc selector ref: setOn:animated:
    100014554:	ldr	x1, [x8, #0x380] ; Objc selector ref: sharedInstance
    100014584:	ldr	x1, [x8, #0xb20] ; Objc selector ref: setApp:enabled:

## DuoFaceUI / CBAppsManagerViewController.setupNavigationItems @ 0x100011634
Instructions: 49
Selector/CFString references:
    100011664:	ldr	x1, [x8, #0x3d0] ; Objc selector ref: systemImageNamed:
    100011668:	adr	x2, #890368 ; Objc cfstring ref: @"ellipsis.circle"
    100011684:	ldr	x5, [x8, #0x998] ; Objc selector ref: showActionMenu
    1000116b4:	ldr	x1, [x8, #0x758] ; Objc selector ref: navigationItem
    1000116d0:	ldr	x1, [x8, #0x760] ; Objc selector ref: setRightBarButtonItem:

## DuoFaceUI / CBGeneralSettingsViewController.tableView:cellForRowAtIndexPath: @ 0x10000ece0
Instructions: 1441
Selector/CFString references:
    10000ed20:	ldr	x1, [x8, #0x7e8] ; Objc selector ref: initWithStyle:reuseIdentifier:
    10000ed38:	ldr	x24, [x8, #0x7f0] ; Objc selector ref: setSelectionStyle:
    10000ed4c:	ldr	x23, [x8, #0x7f8] ; Objc selector ref: textLabel
    10000ed6c:	ldr	x1, [x8, #0x800] ; Objc selector ref: setAdjustsFontSizeToFitWidth:
    10000ed9c:	ldr	x1, [x8, #0x808] ; Objc selector ref: setMinimumScaleFactor:
    10000edb8:	ldr	x21, [x8, #0x810] ; Objc selector ref: detailTextLabel
    10000edd8:	ldr	x1, [x8, #0x818] ; Objc selector ref: setNumberOfLines:
    10000ee08:	ldr	x1, [x8, #0x820] ; Objc selector ref: setLineBreakMode:
    10000ee20:	ldr	x25, [x8, #0x828] ; Objc selector ref: section
    10000ee4c:	ldr	x1, [x8, #0x830] ; Objc selector ref: row
    10000ee68:	ldr	x24, [x9, #0x3c8] ; Objc selector ref: localizedStringForKey:
    10000ee70:	adr	x2, #899896 ; Objc cfstring ref: @"ROW_HIDE_LABELS"
    10000eea8:	ldr	x26, [x8, #0x838] ; Objc selector ref: setText:
    10000eecc:	adr	x2, #899836 ; Objc cfstring ref: @"ROW_HIDE_LABELS_SUB"
    10000ef28:	ldr	x1, [x8, #0x840] ; Objc selector ref: secondaryLabelColor
    10000ef58:	ldr	x1, [x8, #0x848] ; Objc selector ref: setTextColor:
    10000ef80:	ldr	x1, [x8, #0x3d0] ; Objc selector ref: systemImageNamed:
    10000ef84:	adr	x2, #899684 ; Objc cfstring ref: @"eye.slash.fill"
    10000efa0:	ldr	x1, [x8, #0x850] ; Objc selector ref: imageView
    10000efbc:	ldr	x1, [x8, #0x858] ; Objc selector ref: setImage:
    10000efec:	ldr	x1, [x8, #0x8a8] ; Objc selector ref: hideLabelsEnabled
    10000f000:	ldr	x1, [x8, #0x868] ; Objc selector ref: setOn:
    10000f010:	ldr	x3, [x8, #0x8b0] ; Objc selector ref: hideLabelsToggleChanged:
    10000f01c:	ldr	x26, [x8, #0x830] ; Objc selector ref: row
    10000f050:	ldr	x24, [x8, #0x3c8] ; Objc selector ref: localizedStringForKey:
    10000f054:	adr	x2, #899220 ; Objc cfstring ref: @"ROW_SCREEN_BLANK"
    10000f08c:	ldr	x26, [x8, #0x838] ; Objc selector ref: setText:
    10000f0b0:	adr	x2, #899160 ; Objc cfstring ref: @"ROW_SCREEN_BLANK_SUB"
    10000f10c:	ldr	x1, [x8, #0x840] ; Objc selector ref: secondaryLabelColor
    10000f13c:	ldr	x1, [x8, #0x848] ; Objc selector ref: setTextColor:
    10000f164:	ldr	x1, [x8, #0x3d0] ; Objc selector ref: systemImageNamed:
    10000f168:	adr	x2, #899008 ; Objc cfstring ref: @"moon.fill"
    10000f184:	ldr	x1, [x8, #0x850] ; Objc selector ref: imageView
    10000f1a0:	ldr	x1, [x8, #0x858] ; Objc selector ref: setImage:
    10000f1d0:	ldr	x1, [x8, #0x888] ; Objc selector ref: screenBlankEnabled
    10000f1e4:	ldr	x1, [x8, #0x868] ; Objc selector ref: setOn:
    10000f1f4:	ldr	x3, [x8, #0x890] ; Objc selector ref: screenBlankToggleChanged:
    10000f224:	ldr	x1, [x8, #0x8b8] ; Objc selector ref: setAccessoryType:
    10000f240:	ldr	x1, [x8, #0x3c8] ; Objc selector ref: localizedStringForKey:
    10000f244:	adr	x2, #898020 ; Objc cfstring ref: @"ROW_LANGUAGE"
    10000f278:	ldr	x24, [x8, #0x838] ; Objc selector ref: setText:
    10000f2a0:	ldr	x1, [x8, #0x8c0] ; Objc selector ref: currentLanguageCode
    10000f2bc:	ldr	x1, [x8, #0x8c8] ; Objc selector ref: displayNameForLanguageCode:
    10000f320:	ldr	x1, [x8, #0x8d0] ; Objc selector ref: systemBlueColor
    10000f350:	ldr	x1, [x8, #0x848] ; Objc selector ref: setTextColor:
    10000f378:	ldr	x1, [x8, #0x3d0] ; Objc selector ref: systemImageNamed:
    10000f37c:	adr	x2, #898700 ; Objc cfstring ref: @"globe"
    10000f398:	ldr	x1, [x8, #0x850] ; Objc selector ref: imageView
    10000f3b4:	ldr	x1, [x8, #0x858] ; Objc selector ref: setImage:
    10000f3e4:	ldr	x1, [x8, #0x830] ; Objc selector ref: row
    10000f400:	ldr	x1, [x9, #0x3c8] ; Objc selector ref: localizedStringForKey:
    10000f408:	adr	x2, #898656 ; Objc cfstring ref: @"ACTION_RESET_DEFAULTS"
    10000f43c:	ldr	x1, [x8, #0x838] ; Objc selector ref: setText:
    10000f464:	ldr	x21, [x8, #0x8e8] ; Objc selector ref: systemRedColor
    10000f498:	ldr	x1, [x8, #0x848] ; Objc selector ref: setTextColor:
    10000f4c0:	ldr	x1, [x8, #0x3d0] ; Objc selector ref: systemImageNamed:
    10000f4c4:	adr	x2, #898500 ; Objc cfstring ref: @"trash.fill"
    10000f4e0:	ldr	x23, [x8, #0x850] ; Objc selector ref: imageView
    10000f500:	ldr	x1, [x8, #0x858] ; Objc selector ref: setImage:
    10000f554:	ldr	x24, [x8, #0x3c8] ; Objc selector ref: localizedStringForKey:
    10000f558:	adr	x2, #897840 ; Objc cfstring ref: @"ROW_AUTO_LAUNCH"
    10000f590:	ldr	x26, [x8, #0x838] ; Objc selector ref: setText:
    10000f5b4:	adr	x2, #897780 ; Objc cfstring ref: @"ROW_AUTO_LAUNCH_SUB"
    10000f610:	ldr	x1, [x8, #0x840] ; Objc selector ref: secondaryLabelColor
    10000f640:	ldr	x1, [x8, #0x848] ; Objc selector ref: setTextColor:
    10000f668:	ldr	x1, [x8, #0x3d0] ; Objc selector ref: systemImageNamed:
    10000f66c:	adr	x2, #897628 ; Objc cfstring ref: @"bolt.car.fill"
    10000f688:	ldr	x1, [x8, #0x850] ; Objc selector ref: imageView
    10000f6a4:	ldr	x1, [x8, #0x858] ; Objc selector ref: setImage:
    10000f6d4:	ldr	x1, [x8, #0x860] ; Objc selector ref: autoLaunchOnConnect
    10000f6e8:	ldr	x1, [x8, #0x868] ; Objc selector ref: setOn:
    10000f6f8:	ldr	x3, [x8, #0x870] ; Objc selector ref: autoLaunchToggleChanged:
    10000f700:	ldr	x1, [x8, #0x878] ; Objc selector ref: addTarget:action:forControlEvents:
    10000f718:	ldr	x1, [x8, #0x880] ; Objc selector ref: setAccessoryView:
    10000f73c:	adr	x2, #897548 ; Objc cfstring ref: @"ROW_DOCK_MONITOR"
    10000f774:	ldr	x26, [x8, #0x838] ; Objc selector ref: setText:
    10000f798:	adr	x2, #897488 ; Objc cfstring ref: @"ROW_DOCK_MONITOR_SUB"
    10000f7f4:	ldr	x1, [x8, #0x840] ; Objc selector ref: secondaryLabelColor
    10000f824:	ldr	x1, [x8, #0x848] ; Objc selector ref: setTextColor:
    10000f84c:	ldr	x1, [x8, #0x3d0] ; Objc selector ref: systemImageNamed:
    10000f850:	adr	x2, #897336 ; Objc cfstring ref: @"speedometer"
    10000f86c:	ldr	x1, [x8, #0x850] ; Objc selector ref: imageView
    10000f888:	ldr	x1, [x8, #0x858] ; Objc selector ref: setImage:
    10000f8b8:	ldr	x1, [x8, #0x898] ; Objc selector ref: dockMonitorEnabled
    10000f8cc:	ldr	x1, [x8, #0x868] ; Objc selector ref: setOn:
    10000f8dc:	ldr	x3, [x8, #0x8a0] ; Objc selector ref: dockMonitorToggleChanged:
    10000f8e4:	ldr	x1, [x8, #0x878] ; Objc selector ref: addTarget:action:forControlEvents:
    10000f8fc:	ldr	x1, [x8, #0x880] ; Objc selector ref: setAccessoryView:
    10000f928:	ldr	x22, [x8, #0x830] ; Objc selector ref: row
    10000f964:	ldr	x1, [x8, #0x8b8] ; Objc selector ref: setAccessoryType:
    10000f980:	ldr	x24, [x8, #0x3c8] ; Objc selector ref: localizedStringForKey:
    10000f984:	adr	x2, #897444 ; Objc cfstring ref: @"ABOUT_TITLE"
    10000f9bc:	ldr	x22, [x8, #0x838] ; Objc selector ref: setText:
    10000f9e8:	ldr	x1, [x8, #0x3d0] ; Objc selector ref: systemImageNamed:
    10000f9ec:	adr	x2, #897372 ; Objc cfstring ref: @"info.circle.fill"
    10000fa08:	ldr	x1, [x8, #0x850] ; Objc selector ref: imageView
    10000fa24:	ldr	x1, [x8, #0x858] ; Objc selector ref: setImage:
    10000fa4c:	ldr	x23, [x8, #0x380] ; Objc selector ref: sharedInstance
    10000fa68:	ldr	x1, [x8, #0x4e0] ; Objc selector ref: isLicenseCurrentlyValid
    10000fa98:	ldr	x1, [x8, #0x4e8] ; Objc selector ref: actualLicenseExpirationTimestamp

## DuoFaceUI / CBGeneralSettingsViewController.tableView:didSelectRowAtIndexPath: @ 0x100010364
Instructions: 72
Selector/CFString references:
    10001038c:	ldr	x1, [x8, #0x8f8] ; Objc selector ref: deselectRowAtIndexPath:animated:
    1000103a4:	ldr	x21, [x8, #0x828] ; Objc selector ref: section
    1000103c0:	ldr	x1, [x8, #0x830] ; Objc selector ref: row
    1000103e8:	ldr	x21, [x8, #0x830] ; Objc selector ref: row
    100010414:	ldr	x1, [x8, #0x910] ; Objc selector ref: performResetDefaults
    100010434:	ldr	x1, [x8, #0x830] ; Objc selector ref: row
    10001044c:	ldr	x1, [x8, #0x918] ; Objc selector ref: openSubscriptionScreen
    100010458:	ldr	x1, [x8, #0x900] ; Objc selector ref: showLanguageSelectionSheet
    100010464:	ldr	x1, [x8, #0x908] ; Objc selector ref: performRespring

## DuoFaceUI / CBSplitViewController.tableView:cellForRowAtIndexPath: @ 0x100017154
Instructions: 490
Selector/CFString references:
    100017184:	ldr	x20, [x8, #0x828] ; Objc selector ref: section
    1000171bc:	ldr	x1, [x8, #0x7e8] ; Objc selector ref: initWithStyle:reuseIdentifier:
    1000171d4:	ldr	x1, [x8, #0x8b8] ; Objc selector ref: setAccessoryType:
    1000171e4:	ldr	x23, [x8, #0x830] ; Objc selector ref: row
    1000171fc:	ldr	x1, [x8, #0xc10] ; Objc selector ref: splitPreset
    100017210:	ldr	x1, [x8, #0xc50] ; Objc selector ref: slotTitleForIndex:preset:
    100017254:	ldr	x1, [x8, #0xc60] ; Objc selector ref: slotName2
    100017268:	add	x24, x24, #0xc28 ; Objc selector ref: slotApp2
    100017280:	ldr	x1, [x8, #0x7e8] ; Objc selector ref: initWithStyle:reuseIdentifier:
    100017298:	ldr	x21, [x8, #0x830] ; Objc selector ref: row
    1000172b0:	ldr	x1, [x8, #0xc48] ; Objc selector ref: presetTitleForIndex:
    1000172cc:	ldr	x23, [x8, #0x7f8] ; Objc selector ref: textLabel
    1000172ec:	ldr	x1, [x8, #0x838] ; Objc selector ref: setText:
    10001731c:	ldr	x1, [x8, #0xc10] ; Objc selector ref: splitPreset
    10001732c:	ldr	x1, [x8, #0x8b8] ; Objc selector ref: setAccessoryType:
    100017350:	ldr	x1, [x8, #0x8d0] ; Objc selector ref: systemBlueColor
    100017380:	ldr	x1, [x8, #0x848] ; Objc selector ref: setTextColor:
    1000173b4:	ldr	x1, [x8, #0x9e0] ; Objc selector ref: systemFontOfSize:weight:
    1000173e4:	ldr	x1, [x8, #0xc78] ; Objc selector ref: new
    10001740c:	ldr	x1, [x8, #0x9f0] ; Objc selector ref: labelColor
    10001743c:	ldr	x1, [x8, #0x848] ; Objc selector ref: setTextColor:
    100017470:	ldr	x1, [x8, #0x9e0] ; Objc selector ref: systemFontOfSize:weight:
    1000174a4:	ldr	x1, [x8, #0x9e8] ; Objc selector ref: setFont:
    1000174f0:	ldr	x1, [x8, #0x3d0] ; Objc selector ref: systemImageNamed:
    1000174f4:	adr	x2, #859444 ; Objc cfstring ref: @"rectangle.split.2x1.fill"
    100017510:	ldr	x1, [x8, #0x850] ; Objc selector ref: imageView
    100017530:	ldr	x1, [x8, #0x3d0] ; Objc selector ref: systemImageNamed:
    100017534:	adr	x2, #868404 ; Objc cfstring ref: @"rectangle.fill"
    100017550:	ldr	x1, [x8, #0x850] ; Objc selector ref: imageView
    100017568:	ldr	x1, [x8, #0xc58] ; Objc selector ref: slotName1
    10001757c:	add	x24, x24, #0xc20 ; Objc selector ref: slotApp1
    1000175a4:	ldr	x1, [x8, #0x3d0] ; Objc selector ref: systemImageNamed:
    1000175a8:	adr	x2, #868320 ; Objc cfstring ref: @"rectangle.split.1x2.fill"
    1000175c4:	ldr	x1, [x8, #0x850] ; Objc selector ref: imageView
    1000175f0:	ldr	x1, [x8, #0xc68] ; Objc selector ref: slotName3
    100017604:	add	x24, x24, #0xc30 ; Objc selector ref: slotApp3
    10001762c:	ldr	x1, [x8, #0x3d0] ; Objc selector ref: systemImageNamed:
    100017630:	adr	x2, #868216 ; Objc cfstring ref: @"rectangle.split.3x1.fill"
    10001764c:	ldr	x1, [x8, #0x850] ; Objc selector ref: imageView
    100017678:	ldr	x1, [x8, #0xc70] ; Objc selector ref: slotName4
    10001768c:	add	x24, x24, #0xc38 ; Objc selector ref: slotApp4
    1000176b8:	ldr	x1, [x8, #0x520] ; Objc selector ref: stringWithFormat:
    1000176c0:	adr	x2, #868168 ; Objc cfstring ref: @"%@: %@"
    1000176dc:	ldr	x1, [x8, #0x7f8] ; Objc selector ref: textLabel
    1000176f8:	ldr	x26, [x8, #0x838] ; Objc selector ref: setText:
    10001771c:	ldr	x24, [x8, #0x810] ; Objc selector ref: detailTextLabel
    100017758:	ldr	x1, [x8, #0x840] ; Objc selector ref: secondaryLabelColor
    100017788:	ldr	x1, [x8, #0x848] ; Objc selector ref: setTextColor:
    1000177b0:	ldr	x1, [x8, #0x3d0] ; Objc selector ref: systemImageNamed:
    1000177b4:	adr	x2, #867956 ; Objc cfstring ref: @"app.badge.fill"
    1000177d0:	ldr	x1, [x8, #0x850] ; Objc selector ref: imageView
    1000177ec:	ldr	x1, [x8, #0x858] ; Objc selector ref: setImage:
    100017834:	ldr	x1, [x9, #0x3d0] ; Objc selector ref: systemImageNamed:
    100017840:	adr	x2, #867720 ; Objc cfstring ref: @"rectangle.split.2x2.fill"
    10001785c:	ldr	x1, [x8, #0x850] ; Objc selector ref: imageView
    100017870:	adr	x23, #858360 ; Objc cfstring ref: @""
    100017880:	adr	x2, #867688 ; Objc cfstring ref: @"rectangle.3.group.fill"
    10001789c:	ldr	x1, [x8, #0x850] ; Objc selector ref: imageView
    1000178b8:	ldr	x1, [x8, #0x858] ; Objc selector ref: setImage:

## DuoFaceUI / CBSplitViewController.tableView:didSelectRowAtIndexPath: @ 0x1000178fc
Instructions: 299
Selector/CFString references:
    100017940:	ldr	x1, [x8, #0x8f8] ; Objc selector ref: deselectRowAtIndexPath:animated:
    100017958:	ldr	x22, [x8, #0x828] ; Objc selector ref: section
    100017984:	ldr	x1, [x8, #0x830] ; Objc selector ref: row
    100017998:	ldr	x1, [x8, #0xc10] ; Objc selector ref: splitPreset
    1000179ac:	ldr	x1, [x8, #0xc40] ; Objc selector ref: slotCountForPreset:
    1000179c8:	ldr	x1, [x8, #0x550] ; Objc selector ref: set
    1000179ec:	ldr	x25, [x8, #0xc20] ; Objc selector ref: slotApp1
    100017a0c:	ldr	x1, [x8, #0x640] ; Objc selector ref: length
    100017a40:	ldr	x1, [x8, #0x5e8] ; Objc selector ref: addObject:
    100017a6c:	ldr	x25, [x8, #0xc28] ; Objc selector ref: slotApp2
    100017a8c:	ldr	x1, [x8, #0x640] ; Objc selector ref: length
    100017ac0:	ldr	x1, [x8, #0x5e8] ; Objc selector ref: addObject:
    100017aec:	ldr	x25, [x8, #0xc30] ; Objc selector ref: slotApp3
    100017b0c:	ldr	x1, [x8, #0x640] ; Objc selector ref: length
    100017b40:	ldr	x1, [x8, #0x5e8] ; Objc selector ref: addObject:
    100017b6c:	ldr	x24, [x8, #0xc38] ; Objc selector ref: slotApp4
    100017b8c:	ldr	x1, [x8, #0x640] ; Objc selector ref: length
    100017bc0:	ldr	x1, [x8, #0x5e8] ; Objc selector ref: addObject:
    100017bec:	ldr	x1, [x8, #0xbd8] ; Objc selector ref: availableApps
    100017c08:	ldr	x1, [x8, #0xaf0] ; Objc selector ref: setApps:
    100017c24:	ldr	x1, [x8, #0xc90] ; Objc selector ref: setDisabledBundleIDs:
    100017c88:	ldr	x1, [x8, #0xcd8] ; Objc selector ref: setOnSelectApp:
    100017c9c:	ldr	x1, [x8, #0x738] ; Objc selector ref: navigationController
    100017cb8:	ldr	x1, [x8, #0x508] ; Objc selector ref: pushViewController:animated:
    100017cf4:	ldr	x1, [x8, #0x830] ; Objc selector ref: row
    100017d08:	ldr	x1, [x8, #0xc80] ; Objc selector ref: setSplitPreset:
    100017d18:	ldr	x1, [x8, #0xc88] ; Objc selector ref: saveSettings
    100017d28:	ldr	x1, [x8, #0x770] ; Objc selector ref: tableView
    100017d44:	ldr	x1, [x8, #0x778] ; Objc selector ref: reloadData

## DuoFaceDashboard.dylib / CBSlotPillView.dotsTapped: @ 0x85580
Instructions: 70
Selector/CFString references:
    8559c:	ldr	x1, [x8, #0xf18] ; Objc selector ref: bounceButton:
    855b0:	ldr	x1, [x8, #0x518] ; Objc selector ref: sharedInstance
    855c8:	ldr	x21, [x8, #0xf20] ; Objc selector ref: currentApp
    855e4:	ldr	x22, [x8, #0xf28] ; Objc selector ref: noteUserActivity
    85634:	ldr	x21, [x8, #0xe38] ; Objc selector ref: onPillTapped

## DuoFaceDashboard.dylib / CBSlotPillView.expandTapped: @ 0x85698
Instructions: 70
Selector/CFString references:
    856b4:	ldr	x1, [x8, #0xf18] ; Objc selector ref: bounceButton:
    856c8:	ldr	x1, [x8, #0x518] ; Objc selector ref: sharedInstance
    856e0:	ldr	x21, [x8, #0xf20] ; Objc selector ref: currentApp
    856fc:	ldr	x22, [x8, #0xf28] ; Objc selector ref: noteUserActivity
    8574c:	ldr	x21, [x8, #0xf38] ; Objc selector ref: onExpandTapped

## DuoFaceDashboard.dylib / CBSlotPillView.restoreTapped: @ 0x857b0
Instructions: 85
Selector/CFString references:
    857cc:	ldr	x1, [x8, #0xf18] ; Objc selector ref: bounceButton:
    857e0:	ldr	x1, [x8, #0x518] ; Objc selector ref: sharedInstance
    857f8:	ldr	x21, [x8, #0xf20] ; Objc selector ref: currentApp
    85814:	ldr	x22, [x8, #0xf28] ; Objc selector ref: noteUserActivity
    85864:	ldr	x21, [x8, #0xf40] ; Objc selector ref: onRestoreTapped
    858a0:	ldr	x21, [x8, #0xe38] ; Objc selector ref: onPillTapped

## DuoFaceDashboard.dylib / CBDividerView.handleMoveButtonLongPress: @ 0x1005f4
Instructions: 155
Selector/CFString references:
    100624:	ldr	x1, [x8, #0xe50] ; Objc selector ref: state
    100638:	ldr	x20, [x8, #0x8d0] ; Objc selector ref: onActivity
    100688:	ldr	x1, [x8, #0x2f0] ; Objc selector ref: view
    1006b0:	ldr	x1, [x8, #0x8d8] ; Objc selector ref: indexOfObject:
    1006dc:	ldr	x1, [x8, #0x620] ; Objc selector ref: count
    1006f4:	ldr	x1, [x8, #0x8b8] ; Objc selector ref: objectAtIndexedSubscript:
    100774:	ldr	x1, [x8, #0xb30] ; Objc selector ref: animateWithDuration:animations:completion:
    100794:	ldr	x22, [x8, #0x8e8] ; Objc selector ref: onRotate
    1007d0:	ldr	x22, [x8, #0x8e0] ; Objc selector ref: onSwap

## DuoFaceDashboard.dylib / CBDividerView.moveButtonTouchDown: @ 0xffbf8
Instructions: 63
Selector/CFString references:
    ffc20:	ldr	x21, [x8, #0x8d0] ; Objc selector ref: onActivity
    ffca8:	ldr	x21, [x8, #0xab8] ; Objc selector ref: animateWithDuration:animations:

## DuoFaceDashboard.dylib / CBDividerView.moveButtonTouchUp: @ 0xffeb4
Instructions: 132
Selector/CFString references:
    ffee0:	ldr	x21, [x8, #0x8d0] ; Objc selector ref: onActivity
    fffa0:	ldr	x1, [x8, #0xf48] ; Objc selector ref: animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:
    fffe4:	ldr	x1, [x8, #0x8d8] ; Objc selector ref: indexOfObject:
    100010:	ldr	x1, [x8, #0x620] ; Objc selector ref: count
    100028:	ldr	x1, [x8, #0x8b8] ; Objc selector ref: objectAtIndexedSubscript:
    100044:	ldr	x21, [x8, #0x8e0] ; Objc selector ref: onSwap

## DuoFaceDashboard.dylib / CBBridgedSplitApp.moveSlot:direction: @ 0x108f28
Instructions: 40
Selector/CFString references:
    108f58:	ldr	x22, [x8, #0x620] ; Objc selector ref: count
    108fa8:	ldr	x1, [x8, #0x228] ; Objc selector ref: swapSlot:withSlot:

## DuoFaceDashboard.dylib / CBBridgedSplitApp.rotateAllSlotsClockwise @ 0x106560
Instructions: 97
Selector/CFString references:
    106588:	ldr	x20, [x8, #0x620] ; Objc selector ref: count
    1065b4:	ldr	x1, [x8, #0x228] ; Objc selector ref: swapSlot:withSlot:
    1065f0:	ldr	x1, [x8, #0x228] ; Objc selector ref: swapSlot:withSlot:
    10666c:	ldr	x1, [x8, #0x228] ; Objc selector ref: swapSlot:withSlot:

## DuoFaceDashboard.dylib / CBBridgedSplitApp.focusSlot:animated: @ 0x105890
Instructions: 205
Selector/CFString references:
    1058e0:	ldr	x1, [x8, #0x620] ; Objc selector ref: count
    105928:	ldr	x1, [x8, #0x518] ; Objc selector ref: sharedInstance
    105944:	ldr	x1, [x8, #0x9d0] ; Objc selector ref: saveBridgeStateToDisk
    105978:	ldr	x1, [x8, #0x898] ; Objc selector ref: countByEnumeratingWithState:objects:count:
    1059ac:	ldr	x25, [x8, #0x420] ; Objc selector ref: bundleIdentifier
    1059bc:	ldr	x27, [x8, #0x9d8] ; Objc selector ref: sendStateToApp:shouldBridge:
    105b28:	ldr	x1, [x8, #0xf48] ; Objc selector ref: animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:
    105b60:	ldr	x1, [x8, #0x900] ; Objc selector ref: layoutSplitViews

## DuoFaceDashboard.dylib / CBBridgedSplitApp.restoreSplitAnimated: @ 0x105e2c
Instructions: 289
Selector/CFString references:
    105eb4:	ldr	x1, [x8, #0x898] ; Objc selector ref: countByEnumeratingWithState:objects:count:
    10601c:	ldr	x1, [x8, #0x518] ; Objc selector ref: sharedInstance
    106038:	ldr	x1, [x8, #0x9d0] ; Objc selector ref: saveBridgeStateToDisk
    106098:	ldr	x25, [x8, #0x420] ; Objc selector ref: bundleIdentifier
    1060a8:	ldr	x27, [x8, #0x9d8] ; Objc selector ref: sendStateToApp:shouldBridge:
    106214:	ldr	x1, [x8, #0xf48] ; Objc selector ref: animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:
    10624c:	ldr	x1, [x8, #0x900] ; Objc selector ref: layoutSplitViews

## DuoFaceDashboard.dylib / CBMultitaskingOverlayView.showLayoutChooserInParentView: @ 0xaacf0
Instructions: 285
Selector/CFString references:
    aad38:	ldr	x23, [x8, #0x518] ; Objc selector ref: sharedInstance
    aad64:	ldr	x1, [x8, #0x528] ; Objc selector ref: reloadLanguage
    aada4:	ldr	x1, [x8, #0x520] ; Objc selector ref: reload
    aadb0:	ldr	x23, [x8, #0x220] ; Objc selector ref: splitPreset
    aadec:	ldr	x1, [x8, #0x250] ; Objc selector ref: splitMode
    aae10:	ldr	x1, [x8, #0xf58] ; Objc selector ref: splitRatio
    aae38:	ldr	x1, [x8, #0x258] ; Objc selector ref: splitApp1
    aae54:	add	x24, x24, #0x288 ; Objc cfstring ref: @""
    aae6c:	ldr	x1, [x8, #0x260] ; Objc selector ref: splitLeftBundleID
    aae9c:	ldr	x1, [x8, #0x268] ; Objc selector ref: splitApp2
    aaec8:	ldr	x1, [x8, #0x270] ; Objc selector ref: splitRightBundleID
    aaef4:	ldr	x1, [x8, #0x278] ; Objc selector ref: splitApp3
    aaf1c:	ldr	x1, [x8, #0x280] ; Objc selector ref: splitApp4
    aaf4c:	ldr	x1, [x8, #0x550] ; Objc selector ref: arrayWithObjects:count:
    aaf6c:	ldr	x1, [x8, #0xfd8] ; Objc selector ref: arrayWithArray:
    aafe4:	ldr	x1, [x8, #0xfe8] ; Objc selector ref: loadInstalledApps
    aaff4:	ldr	x1, [x8, #0x9b0] ; Objc selector ref: bounds
    ab004:	ldr	x1, [x8, #0xa10] ; Objc selector ref: setFrame:
    ab014:	ldr	x1, [x8, #0xa80] ; Objc selector ref: addSubview:
    ab028:	ldr	x1, [x8, #0x120] ; Objc selector ref: bringSubviewToFront:
    ab044:	ldr	x1, [x8, #0x988] ; Objc selector ref: setAlpha:
    ab058:	ldr	x1, [x8, #0x980] ; Objc selector ref: setHidden:
    ab09c:	ldr	x1, [x8, #0xe30] ; Objc selector ref: setTransform:
    ab0ac:	ldr	x1, [x8, #0xef0] ; Objc selector ref: layoutSubviews
    ab0f4:	ldr	x1, [x8, #0xf48] ; Objc selector ref: animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:

## DuoFaceDashboard.dylib / CBMultitaskingOverlayView.showRecentAppsInParentView: @ 0xab1d4
Instructions: 306
Selector/CFString references:
    ab21c:	ldr	x22, [x8, #0x518] ; Objc selector ref: sharedInstance
    ab248:	ldr	x1, [x8, #0x528] ; Objc selector ref: reloadLanguage
    ab28c:	ldr	x1, [x8, #0x520] ; Objc selector ref: reload
    ab298:	ldr	x22, [x8, #0x220] ; Objc selector ref: splitPreset
    ab2d4:	ldr	x1, [x8, #0x250] ; Objc selector ref: splitMode
    ab2f8:	ldr	x1, [x8, #0xf58] ; Objc selector ref: splitRatio
    ab320:	ldr	x1, [x8, #0x258] ; Objc selector ref: splitApp1
    ab33c:	add	x26, x26, #0x288 ; Objc cfstring ref: @""
    ab354:	ldr	x1, [x8, #0x260] ; Objc selector ref: splitLeftBundleID
    ab384:	ldr	x1, [x8, #0x268] ; Objc selector ref: splitApp2
    ab3b0:	ldr	x1, [x8, #0x270] ; Objc selector ref: splitRightBundleID
    ab3dc:	ldr	x1, [x8, #0x278] ; Objc selector ref: splitApp3
    ab404:	ldr	x1, [x8, #0x280] ; Objc selector ref: splitApp4
    ab434:	ldr	x1, [x8, #0x550] ; Objc selector ref: arrayWithObjects:count:
    ab454:	ldr	x1, [x8, #0xfd8] ; Objc selector ref: arrayWithArray:
    ab4cc:	ldr	x1, [x8, #0xfe8] ; Objc selector ref: loadInstalledApps
    ab4f8:	ldr	x1, [x8, #0x158] ; Objc selector ref: runningBridgedApplications
    ab52c:	ldr	x1, [x8, #0x9b0] ; Objc selector ref: bounds
    ab53c:	ldr	x1, [x8, #0xa10] ; Objc selector ref: setFrame:
    ab54c:	ldr	x1, [x8, #0xa80] ; Objc selector ref: addSubview:
    ab560:	ldr	x1, [x8, #0x120] ; Objc selector ref: bringSubviewToFront:
    ab57c:	ldr	x1, [x8, #0x988] ; Objc selector ref: setAlpha:
    ab590:	ldr	x1, [x8, #0x980] ; Objc selector ref: setHidden:
    ab5d4:	ldr	x1, [x8, #0xe30] ; Objc selector ref: setTransform:
    ab5e4:	ldr	x1, [x8, #0xef0] ; Objc selector ref: layoutSubviews
    ab62c:	ldr	x1, [x8, #0xf48] ; Objc selector ref: animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:

