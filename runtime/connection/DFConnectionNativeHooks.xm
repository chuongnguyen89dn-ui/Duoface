// DuoFace-only native12 SpringBoard connection bridge.
// SOURCE-STAGED for compile-only QA; not included in any published DEB.
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
static NSString *const kDFLastApp = @"lastOwnedAppBundleID";
static NSString *const kDFClose = @"closeOnCarPlayDisconnect";
static BOOL DFConnectedKnown = NO;
static NSUInteger DFConnectionEpoch = 0;
static NSUInteger DFLastResumeEpoch = NSUIntegerMax;
static NSString *DFLastResumeBundle = nil;

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
static NSString *DFRememberedApp(void) {
    id value=[DFStore() objectForKey:kDFLastApp];
    return [value isKindOfClass:NSString.class] ? value : nil;
}
static void DFSaveRememberedApp(NSString *bundleID) {
    if (![bundleID isKindOfClass:NSString.class] || !bundleID.length) return;
    [DFStore() setObject:bundleID forKey:kDFLastApp];
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
        DFConnectionLoadRememberedApp(DFRememberedApp());
        DFConnectionVerifiedConnected(app,
            ^BOOL(NSString *bid){return DFOwnedAndRunning(manager,bid);},
            nil, ^(NSString *bid){ DFSaveRememberedApp(bid); });
    } else {
        DFConnectionVerifiedDisconnected(
            ^BOOL {return !DFHostCarPlayConnected();},
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
        DFConnectionManagedAppActivated(bundleID, ^(NSString *bid){ DFSaveRememberedApp(bid); });
    });
}
- (NSString *)effectiveAutoLaunchBundleID {
    NSString *native=%orig;
    // Respect the EXISTING Auto Start switch; never alter its stored key.
    if (!DFAutoEnabled()) return native;
    NSString *remembered=DFRememberedApp();
    // Fail open to original app selection when remembered value was removed.
    if (![remembered isKindOfClass:NSString.class] || !remembered.length) return native;
    return remembered;
}
- (void)performAutoResume {
    // Guard the original launch, not a second custom launcher.
    if (DFHostCarPlayConnected() && DFAutoEnabled()) {
        DFRefreshConnectionState(self);
        NSString *target=[self effectiveAutoLaunchBundleID];
        if ([target isKindOfClass:NSString.class] && target.length) {
            if ([self activated] &&
                [[self bundleIdentifier] isEqualToString:target]) return;
            if (DFLastResumeEpoch==DFConnectionEpoch &&
                [DFLastResumeBundle isEqualToString:target]) return;
            DFLastResumeEpoch=DFConnectionEpoch;
            DFLastResumeBundle=[target copy];
        }
    }
    %orig;
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
