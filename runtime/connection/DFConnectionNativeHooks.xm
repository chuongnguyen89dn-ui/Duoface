// DuoFace-only native12 SpringBoard connection bridge.
// native21: keep 10-second disconnect only; native12 owns Auto Resume.
// Preserve every original callback. No DuoDash code, logos, assets or UI.
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "DFConnectionAdapter.h"

@interface CBLicenseSyncManager : NSObject
+ (BOOL)isCarPlayScreenConnected;  // native12 B16@0:8, byte-exact preserved
@end

@interface CBDashboardSettings : NSObject
+ (instancetype)sharedInstance;
- (BOOL)autoLaunchOnConnect;
@end

@interface CBBridgeManager : NSObject
+ (instancetype)sharedInstanceIfExists;
- (BOOL)activated;
- (NSString *)bundleIdentifier;
- (BOOL)isCurrentlyBridging:(NSString *)bundleID;
- (NSArray *)runningBridgedApplications;
- (NSString *)effectiveAutoLaunchBundleID;
- (void)terminateApplicationWithBundleID:(NSString *)bundleID;
@end

static NSString *const kDFSmartPrefs = @"com.duoface.smartconnection";
static NSString *const kDFClose = @"closeOnCarPlayDisconnect";
static BOOL DFConnectedKnown = NO;
static NSUInteger DFConnectionEpoch = 0;

static NSUserDefaults *DFStore(void) {
    return [[NSUserDefaults alloc] initWithSuiteName:kDFSmartPrefs];
}
static BOOL DFHostCarPlayConnected(void) {
    Class cls=NSClassFromString(@"CBLicenseSyncManager");
    if (!cls || ![cls respondsToSelector:@selector(isCarPlayScreenConnected)])
        return NO; // Fail closed when host cannot prove a real CarPlay screen.
    return [cls isCarPlayScreenConnected];
}
static BOOL DFOwnedAndRunning(CBBridgeManager *manager, NSString *bundleID) {
    if (![bundleID isKindOfClass:NSString.class] || !bundleID.length) return NO;
    if ([manager isCurrentlyBridging:bundleID]) return YES;
    NSArray *running = [manager runningBridgedApplications];
    return [running isKindOfClass:NSArray.class] && [running containsObject:bundleID];
}
static BOOL DFAutoEnabled(void) {
    Class cls=NSClassFromString(@"CBDashboardSettings");
    if (!cls || ![cls respondsToSelector:@selector(sharedInstance)]) return NO;
    CBDashboardSettings *settings=[cls sharedInstance];
    return settings && [settings respondsToSelector:@selector(autoLaunchOnConnect)]
        && settings.autoLaunchOnConnect;
}
static void DFRefreshConnectionState(CBBridgeManager *manager) {
    if (![NSThread isMainThread] || !manager) return;
    // The old CarPlay detection implementation is observed, never swizzled.
    Class detector=NSClassFromString(@"CBLicenseSyncManager");
    if (!detector || ![detector respondsToSelector:@selector(isCarPlayScreenConnected)])
        return; // Without a verified event owner, do nothing.
    BOOL connected=DFHostCarPlayConnected();
    DFConnectionConfigure(DFAutoEnabled(),[DFStore() boolForKey:kDFClose]);
    if (connected==DFConnectedKnown) return;
    DFConnectedKnown=connected;
    ++DFConnectionEpoch;
    if (connected) {
        // The native CBBridgeManager's own performAutoResume does the launch;
        // deliberately pass NO launch executor to prevent a second launch.
        NSString *app=([manager activated] &&
                        DFOwnedAndRunning(manager,[manager bundleIdentifier]))
                      ? [manager bundleIdentifier] : nil;
        DFConnectionLoadRememberedApp(nil); // native12 owns Auto Resume preferences
        DFConnectionVerifiedConnected(app,
            ^BOOL(NSString *bid){return DFOwnedAndRunning(manager,bid);},
            nil, ^(NSString *bid){ (void)bid; }); // do not persist single-app recall
    } else {
        DFConnectionVerifiedDisconnected(
            ^BOOL {
                // Re-read cross-process preference at grace expiry.
                DFConnectionConfigure(DFAutoEnabled(),[DFStore() boolForKey:kDFClose]);
                return !DFHostCarPlayConnected();
            },
            ^BOOL(NSString *bid){return DFOwnedAndRunning(manager,bid);},
            ^(NSString *bid){
                if (!DFHostCarPlayConnected() && DFOwnedAndRunning(manager,bid))
                    [manager terminateApplicationWithBundleID:bid];
            });
    }
}
static void DFObserveNativeConnection(CBBridgeManager *manager) {
    if ([NSThread isMainThread]) { DFRefreshConnectionState(manager); return; }
    dispatch_async(dispatch_get_main_queue(), ^{
        DFRefreshConnectionState(manager);
    });
}

// These exact native12 classes and ABIs were audited in GitHub Actions.
// All callbacks call %orig. Only DuoFace-owned app IDs are recorded.
%hook CBBridgeManager
- (void)handleCarPlayConnectionChanged:(id)notification {
    %orig;
    DFObserveNativeConnection(self);
}
// The immutable native12 contains its own unconditional mandatory watchdog.
// While the NEW close-on-disconnect option is ON, our scoped 10-second timer
// must be the only shutdown authority. Otherwise the original watchdog could
// forcibly kill apps before the user-selected grace period or kill twice.
// OFF deliberately preserves existing native12 behavior; no global override.
- (void)scheduleMandatoryDisconnectWatchdog {
    if ([DFStore() boolForKey:kDFClose]) {
        NSLog(@"[DuoFaceSmartConnection] prevent parallel native watchdog; managed 10s timer owns close");
        return;
    }
    %orig;
}
- (void)enforceMandatoryDisconnectKill {
    if ([DFStore() boolForKey:kDFClose]) {
        NSLog(@"[DuoFaceSmartConnection] ignore stale native mandatory kill; scoped 10s policy active");
        return;
    }
    %orig;
}
- (void)handleScreenDidConnect:(id)notification {
    %orig;
    DFObserveNativeConnection(self);
}
- (void)handleScreenDidDisconnect:(id)notification {
    %orig;
    DFObserveNativeConnection(self);
}
- (void)trackBridgedBundleID:(id)rawBundleID {
    %orig;
    if (![rawBundleID isKindOfClass:NSString.class]) return;
    NSString *bundleID=(NSString *)rawBundleID;
    CBBridgeManager *manager=self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!DFHostCarPlayConnected() || !DFOwnedAndRunning(manager,bundleID)) return;
        DFRefreshConnectionState(manager);
        DFConnectionManagedAppActivated(bundleID, nil);
    });
}
%end

__attribute__((constructor)) static void DFSmartConnectionBoot(void) {
    @autoreleasepool {
        NSString *bundle=NSBundle.mainBundle.bundleIdentifier.lowercaseString;
        if (![bundle isEqualToString:@"com.apple.springboard"]) return;
        // Hooks are only compiled in the isolated candidate dylib; do not
        // change native12 or touch CarPlay geometry/UI at constructor time.
        NSLog(@"[DuoFaceSmartConnection] source bridge loaded in SpringBoard");
    }
}
