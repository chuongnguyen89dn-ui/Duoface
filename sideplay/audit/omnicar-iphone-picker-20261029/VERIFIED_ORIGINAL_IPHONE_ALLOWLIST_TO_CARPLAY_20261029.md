# Kết luận đã quét lại DEB OmniCar gốc — chọn app iPhone → chỉ app đã chọn trên CarPlay (2026-10-29)

## Yêu cầu và đính chính
User confirms original OmniCar does allow selecting apps in iPhone Settings and only selected apps appear in CarPlay. The previous report that OmniCar Settings app manager was unverified was based on an unrelated scene/zoom-only audit: inadequate scope, not evidence that the feature is absent. The user requests investigation only; NO DuoFace runtime modification, no DEB build, no Sileo publication.

## Original binary integrity / execution
- Repo under investigation: chuongnguyen89dn-ui/Omnicar; original rootless DEB: com.anlai.omnicar_1.0.3_iphoneos-arm64.deb SHA256 d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd.
- Target handoff/research repo: chuongnguyen89dn-ui/Duoface, feature/duoface-jb-embedded-appbridge-20261020.
- Direct real DEB extraction CI runs: 40788354747 SUCCESS (all pref plists and Mach-O), 40788576486 SUCCESS (metadata inventory), 40788857405 SUCCESS (resolve original ObjC method pointers to exact selectors and IMP). Run 40788767727 FAILED on analysis script count upper bound 300 rather than 368 original split methods; analysis-only failure corrected in 40788857405. No runtime or DEB packaging in these runs.
- DEB inventory: 176 payload files, 14 plists, 8 Mach-O binaries. Crucial original PreferenceBundle binary SHA256 15bca4bee19bd9e04300e2c8070f665869df93c0f8913278e87b147ebf895a76. Original split dylib SHA256 f696b518579266cf99cfd46f85cb54931d18e679c793a563ee2fcc9bf8115754.
- Immutable evidence per run:
  - sideplay/audit/omnicar-iphone-picker-20261029/runs/40788354747/ORIGINAL_OMNICAR_IPHONE_PICKER.json and REPORT.md
  - sideplay/audit/omnicar-iphone-picker-20261029/runs/40788857405/ORIGINAL_OMNICAR_RESOLVED_METHODS.json and RESOLVED_105_APP_MANAGER.md

## Verified original iPhone screen (not a mere suggestion)
Root.plist directly defines Preferences section APPS_GROUP, APPS PSLinkCell with detail OMCAppBridgeAppsController, cellClass OMCAppBridgeAppsLinkCell. Another HOME_SCREEN PSLinkCell opens OMCHomeScreenController. The original OmniCar.app main binary includes a Settings launcher; the actual app-selection Settings is owned by OmniCarPrefs.bundle / OmniCarPrefs, not a dummy UI.

Original OMCAppBridgeAppsController original Objective-C method table: 105 entries, 104 decoded selector names. Key original first-party input/settings methods:
- loadState @0x1cdd8
- carplayIDs @0x1dd54
- rebuildRows @0x1e3a8
- storeChoices @0x1e920
- reloadLists @0x1eb78
- tableView:commitEditingStyle:forRowAtIndexPath: @0x2044c
- tableView:cellForRowAtIndexPath: @0x206e4
- tableView:didSelectRowAtIndexPath: @0x214b0
- appAt: @0x20244
- phoneApps @0x24538; carplayApps @0x24588
- included @0x24628; chosen @0x24768; shown @0x246c8
- Search delegate searchBar:textDidChange: @0x1ee74.
OMCHomeScreenController is a separate class inheriting OMCAppBridgeAppsController, and OMCSplitScreenAppPickerController has another 19-method table (18 decoded). Thus iPhone app inventory/allowlist, CarPlay Home app set, and split picker are distinct screen/owner concepts.

## Verified original CarPlay picker owner
Original OmniCarSplitScreen.dylib SCPCarSplit exposes:
- publishCarPlayApps @0x21b1c
- showPickerForSlot: @0x31530
- refreshPickerSheet @0x31eac
- buildPickerSheetForPane: @0x334cc
- pickerAppTapped: @0x362a0
- isCarPlayApp: @0xff20
- openApp:slot: @0x164d4
- SCPCarSplit has 368 direct ObjC method-table entries.
Exact original literal strings in the split dylib include appBridgeApps, allInstalledApplications, and an original log format distinguishing the number of CarPlay apps vs selected iPhone apps: CarSplit: %lu app CarPlay cho Settings, %lu app iPhone da chon (App Bridge). This directly corroborates that the code distinguishes the selected iPhone AppBridge roster from CarPlay-native apps; the user's on-device observation confirms the visible filtering.

## Data/config bridge evidence
- The shared key appBridgeApps exists in original OmniCarPrefs, OmniCarCore.dylib and OmniCarSplitScreen.dylib; original prefs change channel com.anlai.omnicar/prefschanged appears in prefs and the process dylibs. AppBridge settings keys include appBridgeEnabled and appBridgeAdvancedReset.
- High-confidence architecture: iPhone Settings AppBridge list -> select stored app IDs -> split process reads configured list -> in-car picker catalog. Both relevant ends and common preferences key are verified.
- BUT individual ARM64 bodies for loadState/storeChoices/publishCarPlayApps have NOT yet been disassembled as a complete read/write/notification/containsObject call chain. Therefore do not claim the exact save API or exact event granularity/hot-reload latency from this audit alone.

## Lesson for independent DuoFace
Respect the user's confirmed OmniCar workflow and Native12 single-slot picker contract. An allowlist for available apps in iPhone Settings and an app-chosen-for-pane operation in CarPlay are separate. The already-created independent .94 experiment uses EnabledBundleIDs and a Darwin notification, but is not exact OmniCar semantics, and is NOT physically device-accepted. The task here remains original-only research; DO NOT change source, Sileo or packages without explicit new instruction.

## Immediate follow-up
If more forensic detail is requested, use read-only SHA-pinned original ARM64 targeted instruction scan of OmniCarPrefs OMCAppBridgeAppsController.loadState/storeChoices/reloadLists/didSelectRowAtIndexPath and OmniCarSplitScreen SCPCarSplit.publishCarPlayApps/showPickerForSlot/refreshPickerSheet to map exact prefs synchronization, selection filtering, callbacks and empty/default state. Criterion: cite actual IMP and selector/CFString calls, not UI assumptions.

