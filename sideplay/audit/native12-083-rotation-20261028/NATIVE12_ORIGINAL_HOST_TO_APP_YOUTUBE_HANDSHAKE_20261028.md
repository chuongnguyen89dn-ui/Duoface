# Native12 ORIGINAL Host ↔ YouTube application: scene orientation dataflow

Original Native12 DEB: 2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad
Original Native12 Dashboard: 9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea
Raw original ARM64 run: https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40648313067
Raw immutable original Git blob: 2b80f8ff77247807f7eeba2fe24cae59c3e470b5
No SidePlay inference; no independent app changes.

## ORIGINAL per-application filter

{"Bundles": ["com.apple.CarPlayApp", "com.apple.CarPlay", "com.apple.dashboard", "com.apple.springboard", "com.apple.SpringBoard", "com.google.ios.youtube", "com.google.ios.youtubemusic", "com.netflix.Netflix", "org.videolan.vlc-ios", "com.apple.mobilesafari", "tv.twitch", "com.zhiliaoapp.musically", "com.google.Maps", "com.waze.iphone", "com.spotify.client", "com.apple.Preferences", "com.apple.mobilenotes", "com.apple.mobilephone", "com.apple.Music", "com.google.chrome.ios", "com.apple.BarcodeScanner", "com.apple.PrintKit.Print-Center", "com.duoface.duofaceui"]}

## Original exact function boundaries and value/selector references

### original_host_send_state_to_app 0x1d1624..0x1fd218
Original ARM64 instructions: 44797
Original ObjC owner: {"class": "CBBridgeManager", "selector": "sendStateToApp:shouldBridge:", "type": "v28@0:8@16B24"}
- 0x1d169c ldr	x1, [x8, #0xbb8] ; Objc selector ref: trackBridgedBundleID:
- 0x1d8a2c ldr	x1, [x8, #0xcf0] ; Objc selector ref: renderSizeForBundleID:
- 0x1d8bb4 add	x8, x8, #0x268 ; Objc cfstring ref: @"shouldBridge"
- 0x1d8be8 add	x8, x8, #0x288 ; Objc cfstring ref: @"bridgeToken"
- 0x1d8c18 add	x8, x8, #0x2a8 ; Objc cfstring ref: @"fixedKeyboardWidth"
- 0x1d8c4c add	x8, x8, #0x2c8 ; Objc cfstring ref: @"displayWidth"
- 0x1d8c78 add	x8, x8, #0x2e8 ; Objc cfstring ref: @"displayHeight"
- 0x1d8ca4 add	x8, x8, #0x308 ; Objc cfstring ref: @"orientation"
- 0x1d8cd4 add	x8, x8, #0x328 ; Objc cfstring ref: @"isSplit"
- 0x1d8ce4 ldr	x1, [x8, #0x420] ; Objc selector ref: bundleIdentifier
- 0x1d8d54 add	x8, x8, #0xd28 ; Objc cfstring ref: @"bundleIdentifier"
- 0x1d8de0 add	x0, x0, #0x348 ; Objc cfstring ref: @"[DuoFaceSB] Posting NOTIFY_APP_STATE to %@: %@"
- 0x1d8e0c ldr	x2, [x8, #0xcf8] ; Objc selector ref: postNotificationName:object:userInfo:deliverImmediately:
- 0x1d8e24 add	x0, x0, #0xb91 ; literal pool for: "postNotificationName:object:userInfo:deliverImmediately:"
- 0x1d8e9c ldr	x1, [x8, #0x970] ; Objc selector ref: postNotificationName:object:userInfo:

### original_host_notification_registration 0x1d07fc..0x1d0e00
Original ARM64 instructions: 385
Original ObjC owner: {"class": "CBBridgeManager", "selector": "registerForNotifications", "type": "v16@0:8"}
- 0x1d0858 ldr	x23, [x8, #0xcb8] ; Objc selector ref: receivedStateChangeRequestNotificiation:
- 0x1d0960 ldr	x23, [x8, #0xcc0] ; Objc selector ref: receivedDockTapNotification:
- 0x1d09b8 ldr	x23, [x8, #0xcc8] ; Objc selector ref: receivedAppRequestNotification:
- 0x1d0a10 ldr	x23, [x8, #0xcd0] ; Objc selector ref: receivedDashboardReadyNotification:
- 0x1d0a68 ldr	x23, [x8, #0xcd8] ; Objc selector ref: receivedMetricsUpdatedNotification:
- 0x1d0ae0 add	x8, x8, #0xc8 ; Objc cfstring ref: @"AVExternalDeviceCarPlayIsConnectedDidChangeNotification"
- 0x1d0ae8 add	x9, x9, #0xe8 ; Objc cfstring ref: @"AVExternalDeviceScreenDidDisconnectNotification"
- 0x1d0af4 add	x8, x8, #0x108 ; Objc cfstring ref: @"AVExternalDeviceScreenDidConnectNotification"
- 0x1d0afc add	x9, x9, #0x128 ; Objc cfstring ref: @"CARSessionStatusDidChangeNotification"
- 0x1d0b08 add	x8, x8, #0x148 ; Objc cfstring ref: @"CARSessionDidDisconnectNotification"
- 0x1d0b10 add	x9, x9, #0x168 ; Objc cfstring ref: @"CARSessionDidConnectNotification"
- 0x1d0b54 ldr	x1, [x8, #0x898] ; Objc selector ref: countByEnumeratingWithState:objects:count:
- 0x1d0b88 ldr	x25, [x8, #0xce0] ; Objc selector ref: handleGenericScreenOrCarPlayNotification:
- 0x1d0c2c add	x3, x3, #0x188 ; Objc cfstring ref: @"com.apple.carkit.sessionStatusChanged"
- 0x1d0c48 add	x3, x3, #0x1a8 ; Objc cfstring ref: @"com.apple.springboard.displayChanged"
- 0x1d0c68 add	x3, x3, #0x1c8 ; Objc cfstring ref: @"com.apple.springboard.screenStateChanged"
- 0x1d0c88 add	x3, x3, #0x1e8 ; Objc cfstring ref: @"com.apple.CarPlay.screenDisconnected"
- 0x1d0ca8 add	x3, x3, #0x208 ; Objc cfstring ref: @"com.apple.CarPlay.screenConnected"
- 0x1d0cc8 add	x3, x3, #0xe8 ; Objc cfstring ref: @"AVExternalDeviceScreenDidDisconnectNotification"
- 0x1d0ce8 add	x3, x3, #0x108 ; Objc cfstring ref: @"AVExternalDeviceScreenDidConnectNotification"

### original_host_app_request_receiver 0x248e70..0x248fb4
Original ARM64 instructions: 81
Original ObjC owner: {"class": "CBBridgeManager", "selector": "receivedAppRequestNotification:", "type": "v24@0:8@16"}
- 0x248ee0 add	x2, x2, #0xd28 ; Objc cfstring ref: @"bundleIdentifier"
- 0x248f00 add	x0, x0, #0x4e8 ; Objc cfstring ref: @"[DuoFaceSB] receivedAppRequestNotification for: %@"
- 0x248f24 ldr	x1, [x8, #0x9d8] ; Objc selector ref: sendStateToApp:shouldBridge:

### original_host_state_change_notifier 0x249a54..0x24a024
Original ARM64 instructions: 372
Original ObjC owner: {"class": "CBBridgeManager", "selector": "notifyStateUpdated", "type": "v16@0:8"}
- 0x249acc add	x8, x8, #0xd28 ; Objc cfstring ref: @"bundleIdentifier"
- 0x249ad8 ldr	x1, [x8, #0x420] ; Objc selector ref: bundleIdentifier
- 0x249b80 ldr	x1, [x8, #0x970] ; Objc selector ref: postNotificationName:object:userInfo:
- 0x249c3c add	x0, x0, #0x528 ; Objc cfstring ref: @"[DuoFaceSB] Warning: Failed to write notifyStateUpdated file(s) (state=%d, tmp=%d)"
- 0x249ff8 add	x0, x0, #0x548 ; Objc cfstring ref: @"[DuoFaceSB] Exception in notifyStateUpdated file write: %@"

### original_host_render_size_policy 0x24c920..0x24d118
Original ARM64 instructions: 510
Original ObjC owner: {"class": "CBBridgeManager", "selector": "renderSizeForBundleID:", "type": "{CGSize=dd}24@0:8@16"}
- 0x24c98c ldr	x22, [x27, #0x420] ; Objc selector ref: bundleIdentifier
- 0x24c9e8 ldr	x20, [x8, #0xf20] ; Objc selector ref: currentApp
- 0x24ca80 ldr	x24, [x8, #0xa18] ; Objc selector ref: appViews
- 0x24cb70 ldr	x1, [x8, #0xd60] ; Objc selector ref: renderSize
- 0x24cc4c ldr	x1, [x8, #0x220] ; Objc selector ref: splitPreset
- 0x24cc64 ldr	x1, [x8, #0xf58] ; Objc selector ref: splitRatio
- 0x24ce18 ldr	x20, [x26, #0xd70] ; Objc selector ref: appFrame
- BL 0x24cc98 -> 0x860f4

### original_host_request_state_change 0x13b158..0x153544
Original ARM64 instructions: 24827
Original ObjC owner: {"class": "CBBridgeManager", "selector": "requestStateChange:", "type": "v24@0:8@16"}
- 0x13b1b0 ldr	x25, [x8, #0x420] ; Objc selector ref: bundleIdentifier
- 0x13b260 ldr	x1, [x8, #0xb60] ; Objc selector ref: isDisplayValid
- 0x13b2a4 ldr	x1, [x8, #0x2d8] ; Objc selector ref: window
- 0x13b390 add	x2, x2, #0x348 ; Objc cfstring ref: @"/var/tmp/carbridge_autoresume_bid"
- 0x13b3a8 ldr	x1, [x8, #0x978] ; Objc selector ref: deactivateCurrentApp
- 0x13b3e4 add	x0, x0, #0x548 ; Objc cfstring ref: @"[DuoFaceSB] requestStateChange: App %@ marked active but window/display stale or detached (e.g. after CarPlay reconnect). Performing clean reload..."
- 0x13b3f8 ldr	x1, [x8, #0x978] ; Objc selector ref: deactivateCurrentApp
- 0x13b408 ldr	x1, [x8, #0xb98] ; Objc selector ref: loadNewAppFromCurrentRequest:
- 0x1410ec add	x0, x0, #0x488 ; Objc cfstring ref: @"[DuoFaceSB] [LICENSE_KILL_TRACE] requestStateChange: App %@ active but license invalid (loaded=%d, status=%d, mask=0x%llx)."
- 0x14110c ldr	x1, [x8, #0xb70] ; Objc selector ref: collectActiveAndSessionAppBundleIDs
- 0x141188 ldr	x1, [x8, #0x978] ; Objc selector ref: deactivateCurrentApp
- 0x141228 add	x0, x0, #0x528 ; Objc cfstring ref: @"[DuoFaceSB] requestStateChange: App %@ already active and visible, re-showing window."
- 0x14124c ldr	x1, [x8, #0xb90] ; Objc selector ref: notifyStateUpdated
- 0x141268 add	x1, x1, #0x8f5 ; literal pool for: "BKSDisplayServicesSetScreenBlanked"
- 0x1412d0 add	x0, x0, #0x508 ; Objc cfstring ref: @"[DuoFaceSB] [LICENSE_KILL_TRACE] Step 4: Immediately killing all %lu targeted CarPlay app processes..."
- 0x1412dc ldr	x1, [x8, #0xb80] ; Objc selector ref: killProcessesForBundleIdentifiers:
- BL 0x1411ac -> 0x2d52c

### app_state_check_on_process_start 0x2ab1e4..0x2ab764
Original ARM64 instructions: 352
Original ObjC owner: {"class": "CBAppStateListener", "selector": "checkStateFile", "type": "v16@0:8"}
- 0x2ab2ac adr	x0, #817820 ; Objc cfstring ref: @"[DuoFaceApp] checkStateFile: bid=%@, dict=%@"
- 0x2ab2f0 adr	x2, #815224 ; Objc cfstring ref: @"bridgedBundleID"
- 0x2ab310 adr	x2, #815256 ; Objc cfstring ref: @"activeBridgedBundleIDs"
- 0x2ab330 adr	x2, #814904 ; Objc cfstring ref: @"shouldBridge"
- 0x2ab36c adr	x2, #814876 ; Objc cfstring ref: @"bridgeToken"
- 0x2ab3a4 adr	x2, #814884 ; Objc cfstring ref: @"displayWidth"
- 0x2ab3e0 adr	x2, #814856 ; Objc cfstring ref: @"displayHeight"
- 0x2ab414 adr	x2, #814740 ; Objc cfstring ref: @"fixedKeyboardWidth"
- 0x2ab45c adr	x2, #814892 ; Objc cfstring ref: @"size_%@"
- 0x2ab5b4 adr	x2, #814420 ; Objc cfstring ref: @"orientation"
- 0x2ab5f8 adr	x2, #814384 ; Objc cfstring ref: @"isSplit"
- 0x2ab660 adr	x0, #816904 ; Objc cfstring ref: @"[DuoFaceApp] Activated via disk state file: size={%.1f, %.1f}, o=%ld, isSplit=%d"
- 0x2ab6d0 adr	x0, #816824 ; Objc cfstring ref: @"[DuoFaceApp] State file indicates not bridged for %@. Resetting to phone mode."
- BL 0x2ab20c -> 0x2a80cc
- BL 0x2ab2b4 -> 0x2a96b4
- BL 0x2ab62c -> 0x2a8068
- BL 0x2ab638 -> 0x2a8074
- BL 0x2ab644 -> 0x2a80ac
- BL 0x2ab64c -> 0x2a808c
- BL 0x2ab654 -> 0x2a80c0
- BL 0x2ab668 -> 0x2a96b4
- BL 0x2ab670 -> 0x2aadec
- BL 0x2ab674 -> 0x2a9e38
- BL 0x2ab6c4 -> 0x2a8068
- BL 0x2ab6d8 -> 0x2a96b4
- BL 0x2ab6dc -> 0x2aa684

### app_state_received_notification 0x2ab98c..0x2abd98
Original ARM64 instructions: 259
Original ObjC owner: {"class": "CBAppStateListener", "selector": "handleAppStateNotification:", "type": "v24@0:8@16"}
- 0x2ab9d4 adr	x0, #816148 ; Objc cfstring ref: @"[DuoFaceApp] Received handleAppStateNotification: %@"
- 0x2aba28 adr	x2, #799488 ; Objc cfstring ref: @"bundleIdentifier"
- 0x2aba64 adr	x2, #813060 ; Objc cfstring ref: @"shouldBridge"
- 0x2abaa0 adr	x2, #813032 ; Objc cfstring ref: @"bridgeToken"
- 0x2abad8 adr	x2, #813040 ; Objc cfstring ref: @"displayWidth"
- 0x2abb14 adr	x2, #813012 ; Objc cfstring ref: @"displayHeight"
- 0x2abb48 adr	x2, #812896 ; Objc cfstring ref: @"fixedKeyboardWidth"
- 0x2abb90 adr	x2, #813048 ; Objc cfstring ref: @"size_%@"
- 0x2abc78 adr	x2, #812688 ; Objc cfstring ref: @"orientation"
- 0x2abcb0 adr	x2, #812664 ; Objc cfstring ref: @"isSplit"
- BL 0x2ab9dc -> 0x2a96b4
- BL 0x2aba10 -> 0x2a80cc

### app_state_async_state_apply_block 0x2abd98..0x2abeb4
Original ARM64 instructions: 71
Original ObjC owner: null
- 0x2abe08 adr	x0, #815104 ; Objc cfstring ref: @"[DuoFaceApp] State updated via notification: bridging=%d, size={%.1f, %.1f}, o=%ld"
- 0x2abe88 adr	x0, #815008 ; Objc cfstring ref: @"[DuoFaceApp] Notification indicated not bridged for %@. Resetting to phone mode."
- BL 0x2abdac -> 0x2a8068
- BL 0x2abdb8 -> 0x2a8074
- BL 0x2abddc -> 0x2a80ac
- BL 0x2abde4 -> 0x2a808c
- BL 0x2abdec -> 0x2a80c0
- BL 0x2abe10 -> 0x2a96b4
- BL 0x2abe20 -> 0x2aadec
- BL 0x2abe24 -> 0x2a9e38
- BL 0x2abe90 -> 0x2a96b4

### app_state_UIKit_reflow_dispatch 0x2a9e38..0x2aa684
Original ARM64 instructions: 531
Original ObjC owner: null
- 0x2a9eac ldr	x1, #0xd3a7c ; Objc selector ref: sharedApplication
- 0x2a9f04 ldr	x1, #0xd3a94 ; Objc selector ref: mainScreen
- 0x2a9f5c ldr	x1, #0xd4fe4 ; Objc selector ref: windows
- 0x2a9f8c ldr	x1, #0xd390c ; Objc selector ref: countByEnumeratingWithState:objects:count:
- 0x2a9fd8 ldr	x8, #0xd4590 ; Objc selector ref: windowLevel
- 0x2a9ff4 ldr	x8, #0xd4ffc ; Objc selector ref: _rotateWindowToOrientation:updateStatusBar:duration:skipCallbacks:
- 0x2aa01c ldr	x10, #0xd39f4 ; Objc selector ref: setFrame:
- 0x2aa024 ldr	x8, #0xd3ed4 ; Objc selector ref: setBounds:
- 0x2aa048 ldr	x9, #0xd3eb8 ; Objc selector ref: setNeedsLayout
- 0x2aa058 ldr	x8, #0xd3eb0 ; Objc selector ref: layoutIfNeeded
- 0x2aa0ec adr	x0, #403688 ; literal pool for: "_rotateWindowToOrientation:updateStatusBar:duration:skipCallbacks:"
- 0x2aa290 adr	x0, #821816 ; Objc cfstring ref: @"[DuoFaceApp] Error laying out window: %@"
- 0x2aa2ec ldr	x20, #0xd4c9c ; Objc selector ref: allWindowsIncludingInternalWindows:onlyVisibleWindows:
- 0x2aa34c ldr	x20, #0xd4cac ; Objc selector ref: _allWindowsIncludingInternalWindows:onlyVisibleWindows:
- 0x2aa44c ldr	x23, #0xd35c4 ; Objc selector ref: setFrame:
- 0x2aa454 ldr	x24, #0xd3aa4 ; Objc selector ref: setBounds:
- 0x2aa45c ldr	x25, #0xd4b94 ; Objc selector ref: _rotateWindowToOrientation:updateStatusBar:duration:skipCallbacks:
- 0x2aa464 ldr	x26, #0xd3a9c ; Objc selector ref: setNeedsLayout
- 0x2aa4ec adr	x0, #402664 ; literal pool for: "_rotateWindowToOrientation:updateStatusBar:duration:skipCallbacks:"
- 0x2aa5b0 ldr	x23, #0xd4a58 ; Objc selector ref: updateLayoutToCurrentInterfaceOrientation
- 0x2aa5dc ldr	x23, #0xd3924 ; Objc selector ref: setNeedsLayout
- BL 0x2a9e78 -> 0x2a8068
- BL 0x2a9e80 -> 0x2a8080
- BL 0x2a9e8c -> 0x2a8080
- BL 0x2a9ec4 -> 0x2a8098
- BL 0x2aa1d4 -> 0x2a92d0
- BL 0x2aa204 -> 0x2a9a24
- BL 0x2aa244 -> 0x2a90f4
- BL 0x2aa298 -> 0x2a96b4
- BL 0x2aa48c -> 0x2a8390
- BL 0x2aa494 -> 0x2a9024

### app_state_first_attach 0x2aadec..0x2ab004
Original ARM64 instructions: 134
Original ObjC owner: null
- 0x2aae28 ldr	x1, #0xd2b00 ; Objc selector ref: sharedApplication
- 0x2aae54 adr	x0, #818900 ; Objc cfstring ref: @"[DuoFaceApp] Waking app to active foreground state for CarPlay presentation: %@"
- 0x2aae98 ldr	x21, #0xd2720 ; Objc selector ref: postNotificationName:object:
- 0x2aaed4 ldr	x1, #0xd3584 ; Objc selector ref: connectedScenes
- 0x2aaef4 ldr	x23, #0xd29a4 ; Objc selector ref: countByEnumeratingWithState:objects:count:
- BL 0x2aae40 -> 0x2a80cc
- BL 0x2aae5c -> 0x2a96b4

### app_state_reset_phone_mode 0x2aa684..0x2aadec
Original ARM64 instructions: 474
Original ObjC owner: null
- 0x2aa6f4 ldr	x1, #0xd3234 ; Objc selector ref: sharedApplication
- 0x2aa718 ldr	x1, #0xd3280 ; Objc selector ref: mainScreen
- 0x2aa764 ldr	x1, #0xd47dc ; Objc selector ref: windows
- 0x2aa794 ldr	x1, #0xd3104 ; Objc selector ref: countByEnumeratingWithState:objects:count:
- 0x2aa7e4 ldr	x24, #0xd3d84 ; Objc selector ref: windowLevel
- 0x2aa7ec ldr	x9, #0xd4804 ; Objc selector ref: _rotateWindowToOrientation:updateStatusBar:duration:skipCallbacks:
- 0x2aa7fc ldr	x8, #0xd3214 ; Objc selector ref: setFrame:
- 0x2aa808 ldr	x9, #0xd36f0 ; Objc selector ref: setBounds:
- 0x2aa828 ldr	x9, #0xd36d8 ; Objc selector ref: setNeedsLayout
- 0x2aa838 ldr	x8, #0xd36d0 ; Objc selector ref: layoutIfNeeded
- 0x2aa8b0 adr	x0, #401700 ; literal pool for: "_rotateWindowToOrientation:updateStatusBar:duration:skipCallbacks:"
- 0x2aaa08 adr	x0, #819936 ; Objc cfstring ref: @"[CBHook_AppStateSync] Warning: Exception restoring phone window layout: %@"
- 0x2aaa64 ldr	x20, #0xd4524 ; Objc selector ref: allWindowsIncludingInternalWindows:onlyVisibleWindows:
- 0x2aaac4 ldr	x20, #0xd4534 ; Objc selector ref: _allWindowsIncludingInternalWindows:onlyVisibleWindows:
- 0x2aabb0 ldr	x23, #0xd2e60 ; Objc selector ref: setFrame:
- 0x2aabb8 ldr	x24, #0xd3340 ; Objc selector ref: setBounds:
- 0x2aabc0 ldr	x25, #0xd4430 ; Objc selector ref: _rotateWindowToOrientation:updateStatusBar:duration:skipCallbacks:
- 0x2aabc8 ldr	x26, #0xd3338 ; Objc selector ref: setNeedsLayout
- 0x2aac44 adr	x0, #400784 ; literal pool for: "_rotateWindowToOrientation:updateStatusBar:duration:skipCallbacks:"
- 0x2aad04 ldr	x23, #0xd4304 ; Objc selector ref: updateLayoutToCurrentInterfaceOrientation
- 0x2aad30 ldr	x23, #0xd31d0 ; Objc selector ref: setNeedsLayout
- 0x2aad60 adr	x0, #819112 ; Objc cfstring ref: @"[DuoFaceApp] Reset app to normal phone state completed."
- BL 0x2aa6c4 -> 0x2a8074
- BL 0x2aa6d4 -> 0x2a80ac
- BL 0x2aa6dc -> 0x2a808c
- BL 0x2aa6e4 -> 0x2a80c0
- BL 0x2aa944 -> 0x2a92d0
- BL 0x2aa974 -> 0x2a9a24
- BL 0x2aa9b0 -> 0x2a90f4
- BL 0x2aaa10 -> 0x2a96b4
- BL 0x2aabf0 -> 0x2a8390
- BL 0x2aad68 -> 0x2a96b4

### app_state_initialization 0x2ab0a0..0x2ab1e4
Original ARM64 instructions: 81
Original ObjC owner: {"class": "CBAppStateListener", "selector": "init", "type": "@16@0:8"}
- 0x2ab0e0 ldr	x1, #0xd3f30 ; Objc selector ref: checkStateFile
- 0x2ab114 ldr	x22, #0xd3f04 ; Objc selector ref: handleAppStateNotification:
- 0x2ab178 ldr	x3, #0xd3ea8 ; Objc selector ref: handleAppDidBecomeActive:
- 0x2ab1a4 ldr	x1, #0xd3e84 ; Objc selector ref: sendStateRequest

### app_state_send_request 0x2ab7a4..0x2ab948
Original ARM64 instructions: 105
Original ObjC owner: {"class": "CBAppStateListener", "selector": "sendStateRequest", "type": "v16@0:8"}
- 0x2ab7e0 adr	x0, #816584 ; Objc cfstring ref: @"[DuoFaceApp] Sending NOTIFY_APP_REQUEST for %@"
- 0x2ab7ec adr	x8, #800060 ; Objc cfstring ref: @"bundleIdentifier"
- 0x2ab848 ldr	x2, #0xd34b0 ; Objc selector ref: postNotificationName:object:userInfo:deliverImmediately:
- 0x2ab85c adr	x0, #394037 ; literal pool for: "postNotificationName:object:userInfo:deliverImmediately:"
- 0x2ab8bc ldr	x1, #0xd20b4 ; Objc selector ref: postNotificationName:object:userInfo:
- BL 0x2ab7c8 -> 0x2a80cc
- BL 0x2ab7e8 -> 0x2a96b4

## Correctness scope
Original Native12 appStateListener handles its own per-app bridge state and orientation; any fix must maintain verified owner/timeout and leave .83 video lifecycle alone.
Original had private UIKit rotations and app-process injection; do not copy unsafe vendor hooks, licensing, global device rotation, or arbitrary zoom.
Unverified actual user iOS16 YouTube scene/client geometry: DO NOT assert fixed or package to Sileo from this report alone.


## 2026-10-28 — Hướng khắc phục CHỈ từ Native12 gốc (không dùng SidePlay làm mẫu)

**Đã giải mã chuỗi Native12 Host → app process → UIKit:**

1. Native12 nguyên bản có DuoFaceDashboard.plist lọc com.google.ios.youtube. CBAppStateListener.init @0x2ab0a0 lấy NSDistributedNotificationCenter @0x2ab100, đăng ký handleAppStateNotification: @0x2ab134..0x2ab14c, và đăng ký callback app active @0x2ab178..0x2ab194. Ứng dụng tự gửi yêu cầu state lúc khởi động @0x2ab1a4..0x2ab1ac.
2. CBBridgeManager.sendStateToApp:shouldBridge: @0x1d1624 tạo payload với các khóa shouldBridge, bridgeToken, fixedKeyboardWidth, displayWidth, displayHeight, orientation, isSplit, bundleIdentifier @0x1d8bb4..0x1d8d54. **Tại @0x1d8cb4..0x1d8cbc có mov w2,#1 → NSNumber numberWithInt: cho orientation**: Portrait=1 là đầu vào đã chứng minh của Native12, không suy ra landscape 3/4 hay tỷ lệ zoom. Post thông báo @0x1d8e0c/@0x1d8e9c. CBBridgeManager.receivedAppRequestNotification: @0x248e70 phản hồi bằng sendStateToApp:shouldBridge: @0x248f24..0x248f38.
3. CBAppStateListener.handleAppStateNotification: @0x2ab98c kiểm bundle, đọc các khóa trên @0x2aba28..0x2abcb0. Main-thread async block @0x2abd98 cập nhật local bridging/size/orientation/split @0x2abdb8..0x2abdec, gọi attach @0x2abe20 và **UIWindow UIKit reflow @0x2abe24→0x2a9e38**. Hàm @0x2a9e38 sử dụng UIApplication.windows, setFrame/setBounds/setNeedsLayout, kiểm selector _rotateWindowToOrientation:updateStatusBar:duration:skipCallbacks: @0x2a9ff4/@0x2aa45c và refresh updateLayoutToCurrentInterfaceOrientation @0x2aa5b0. Đây là khác biệt ở bên trong ứng dụng, không phải chỉ remote FBScene.
4. Cold start cũng đọc trạng thái từ CBAppStateListener.checkStateFile @0x2ab1e4, gọi attach + reflow @0x2ab670..0x2ab674. Khi tắt bridge dùng nhánh reset phone-mode @0x2aa684..0x2aadec; không được bỏ qua phục hồi.

**Thiếu sót DuoFace .86 đã chứng minh bằng source/build:** DFSceneOrientationPolicy có hook Portrait và native reference, DFSceneHost commit scene từ SpringBoard; nhưng build.sh chỉ tạo host/Dock dylibs và package_integrated.py loại bỏ DFAppViewportRelay. DFAppViewportRelay.m đang ở source nhưng không có orientation payload hoặc UIKit rotation handshake, và loại phone-main UIWindowScene. Vì thế .86 thiếu đúng một chặng app-process presenter/reflow mà Native12 gốc đang có. Đây là **khoảng trống kiến trúc có chứng cứ**, chưa chứng minh nguyên nhân duy nhất trên thiết bị.

**Hướng sửa tối thiểu và riêng cho YouTube:** tạo giao thức độc lập host→app với bundleID + host scene owner/generation + timestamp expiry + display native width/height + orientation Portrait=1 + active flag. Chỉ gửi khi pane thực sự host YouTube và khi focus/zoom/restore; nhận trong app process theo filter chỉ com.google.ios.youtube, main thread, đo UIWindow/scene thực, cập nhật bố cục đúng ABI, đo ACK; hủy khi owner đổi và phục hồi trạng thái điện thoại khi ngắt. Học luồng Native12 nhưng KHÔNG chép vendor code, license, hoặc hook private UIKit toàn cục. Bảo toàn .83 video lifecycle, Maps/Dock/Logo. Không lặp ép zoom %, không force landscape và không gắn cờ foreground sai gây crash.

**Tiêu chí thiết bị:** video YouTube đúng chiều ngay ở lần phóng ô đầu, không cần tự bật fullscreen trong YouTube; thu về split vẫn đúng; playback không crash. Báo cáo này không build, chưa phát hành Sileo và chưa thử thiết bị.

Chứng cứ: original Native12 DEB SHA256 2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad; raw ARM64 GitHub Actions 40648313067 SUCCESS; summary GitHub Actions 40648501475 SUCCESS. Chi tiết machine code ở NATIVE12_ORIGINAL_HOST_TO_APP_YOUTUBE_HANDSHAKE_20261028.json.
