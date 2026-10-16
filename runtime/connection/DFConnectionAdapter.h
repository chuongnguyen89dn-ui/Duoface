#pragma once
// SpringBoard owner adapter interface; callbacks must be bound to verified
// native DuoFace methods only after their signature and process are audited.
// This file does not install hooks or change the user's existing settings.
#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
typedef BOOL (^DFConnectionQuery)(void);
typedef BOOL (^DFAppQuery)(NSString *bundleID);
typedef void (^DFAppExecutor)(NSString *bundleID);
typedef void (^DFLastAppSaver)(NSString *bundleID);
FOUNDATION_EXPORT void DFConnectionConfigure(BOOL autoStart, BOOL closeOnDisconnect);
FOUNDATION_EXPORT void DFConnectionLoadRememberedApp(NSString * _Nullable existingPreferenceBundleID);
FOUNDATION_EXPORT void DFConnectionManagedAppActivated(NSString *bundleID,
                                                       DFLastAppSaver saveLastApp);
FOUNDATION_EXPORT void DFConnectionVerifiedConnected(NSString * _Nullable currentDuoFaceOwnedApp,
                                                      DFAppQuery installed,
                                                      DFAppExecutor launchApp,
                                                      DFLastAppSaver saveLastApp);
FOUNDATION_EXPORT void DFConnectionVerifiedDisconnected(DFConnectionQuery stillDisconnected,
                                                         DFAppQuery stillOwnedAndRunning,
                                                         DFAppExecutor terminateOwnedApp);
NS_ASSUME_NONNULL_END
