// No hook installed here. This adapter must be called from validated
// SpringBoard CBBridgeManager connect/disconnect and managed-app callbacks.
// Do not treat a Dashboard app deactivation as CarPlay disconnect.
// Existing user preferences and existing activation callbacks remain native.
#import "DFConnectionAdapter.h"
#import "DFConnectionPolicy.hpp"
#import <dispatch/dispatch.h>
#include <string>
#include <vector>

using duoface::connection::Policy;
using duoface::connection::Action;
using duoface::connection::ActionKind;

static Policy& DFPolicy() { static Policy p; return p; }
static void DFAssertOwnerThread() {
    NSCAssert([NSThread isMainThread],
              @"DuoFace connection adapter must run on owner process main thread");
}
static std::string DFUtf8(NSString *value) {
    return [value isKindOfClass:NSString.class] && value.UTF8String
        ? std::string(value.UTF8String) : std::string();
}
static NSString *DFString(const std::string& value) {
    return [NSString stringWithUTF8String:value.c_str()] ?: @"";
}
static std::uint64_t DFUptimeMilliseconds() {
    return static_cast<std::uint64_t>(NSProcessInfo.processInfo.systemUptime*1000.0);
}
static void DFDispatchActions(const std::vector<Action>& actions,
                              DFAppExecutor launch,
                              DFAppExecutor terminate,
                              DFLastAppSaver save) {
    for (const auto& action : actions) {
        NSString *app=DFString(action.bundleId);
        if (!app.length) continue;
        switch (action.kind) {
            case ActionKind::LaunchApp:
                if (launch) launch(app);
                break;
            case ActionKind::TerminateOwnedApp:
                if (terminate) terminate(app);
                break;
            case ActionKind::SaveLastApp:
                if (save) save(app);
                break;
        }
    }
}
void DFConnectionConfigure(BOOL autoStart, BOOL closeOnDisconnect) {
    DFAssertOwnerThread();
    DFPolicy().setAutoStart(autoStart);
    DFPolicy().setCloseOnDisconnect(closeOnDisconnect);
}
void DFConnectionLoadRememberedApp(NSString *bundleID) {
    DFAssertOwnerThread();
    DFPolicy().restoreLastAppFromExistingPreferences(DFUtf8(bundleID));
}
void DFConnectionManagedAppActivated(NSString *bundleID, DFLastAppSaver saveLastApp) {
    DFAssertOwnerThread();
    DFDispatchActions(DFPolicy().onManagedAppActivated(DFUtf8(bundleID)),
                      nil,nil,saveLastApp);
}
void DFConnectionVerifiedConnected(NSString *currentDuoFaceOwnedApp,
                                   DFAppQuery installed, DFAppExecutor launchApp,
                                   DFLastAppSaver saveLastApp) {
    DFAssertOwnerThread();
    // Do NOT issue an app launch unless the real owner supplied a validated,
    // installed candidate, and currentApp has been checked for ownership.
    Policy::Predicate check=[installed](const std::string& bid) {
        return installed && installed(DFString(bid));
    };
    DFDispatchActions(
        DFPolicy().onVerifiedConnected(DFUtf8(currentDuoFaceOwnedApp),check),
        launchApp,nil,saveLastApp);
}
void DFConnectionVerifiedDisconnected(DFConnectionQuery stillDisconnected,
                                      DFAppQuery stillOwnedAndRunning,
                                      DFAppExecutor terminateOwnedApp) {
    DFAssertOwnerThread();
    auto& policy=DFPolicy();
    policy.onVerifiedDisconnected(DFUptimeMilliseconds());
    if (!policy.hasPendingClose()) return;
    const std::uint64_t token=policy.generation();
    // On reconnect policy generation changes, so old timers cannot terminate.
    // Delay exactly 10 seconds; the current preference can cancel at any time.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                   static_cast<int64_t>(Policy::kDisconnectGraceMs)*NSEC_PER_MSEC),
                   dispatch_get_main_queue(), ^{
        DFAssertOwnerThread();
        if (DFPolicy().generation()!=token) return;
        const bool disconnected=stillDisconnected && stillDisconnected();
        Policy::Predicate canClose=[stillOwnedAndRunning](const std::string& bid) {
            // Both owned and running must be proved by the actual host.
            return stillOwnedAndRunning && stillOwnedAndRunning(DFString(bid));
        };
        auto actions=DFPolicy().tick(DFUptimeMilliseconds(), disconnected, canClose);
        DFDispatchActions(actions,nil,terminateOwnedApp,nil);
    });
}
