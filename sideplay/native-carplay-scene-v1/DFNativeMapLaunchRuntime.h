// A one-shot native launch request. Success means event submission only;
// scene observation, pending cancellation and adoption remain coordinator-owned.
#ifndef DF_NATIVE_MAP_LAUNCH_RUNTIME_H
#define DF_NATIVE_MAP_LAUNCH_RUNTIME_H
#import <Foundation/Foundation.h>
#import "DFNativeMapLaunchContext.h"

FOUNDATION_EXPORT DFNativeMapLaunchContext *DFNativeMapResolveLaunchContext(
 id expectedRoot,id expectedWindow,NSString *requestID,NSString **reason);

// The caller MUST install its immutable pending request and claim its sole
// dispatch attempt before entering this function: handleEvent: may reenter.
// stillCurrent reads first-party state/receipts only; it must not rescan native
// controllers or invoke another private API after the dispatcher verifies them.
typedef BOOL (^DFNativeMapLaunchRequestGuard)(void);
FOUNDATION_EXPORT BOOL DFNativeMapDispatchLaunchGuarded(
 NSString *bundle,DFNativeMapLaunchContext *expected,
 DFNativeMapLaunchRequestGuard stillCurrent,NSString **reason);

// The same production dispatcher is exercised by a Foundation harness with
// controlled native-shaped classes and a first-party context provider. The
// shipped entry point above always supplies objc_getClass and dlsym itself.
typedef struct {
 Class (*classNamed)(const char *name);
 DFNativeMapLaunchContextProvider contextProvider;
 uint64_t (*homeGeneration)(void);
} DFNativeMapLaunchRuntime;
FOUNDATION_EXPORT BOOL DFNativeMapDispatchLaunchUsingRuntime(
 NSString *bundle,DFNativeMapLaunchContext *expected,
 DFNativeMapLaunchRuntime runtime,DFNativeMapLaunchRequestGuard stillCurrent,
 NSString **reason);
#endif
