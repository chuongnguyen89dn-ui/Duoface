#import "DFFullscreenCoordinator.h"
#import "DFFullscreenTransport.h"
#import "DFDashboardChrome.h"
#import "DFStatusBarControl.h"

static BOOL DFTransitionPending;
static BOOL DFHostActive;
static BOOL DFFullscreenConfirmed;
static BOOL DFAdapterStarted;
static NSUInteger DFTransitionGeneration;

static void DFRefreshControl(void) {
    DFSetStatusBarControlState(DFHostActive && !DFFullscreenConfirmed,
                              !DFTransitionPending);
}
static void DFRestoreAfterFailure(NSString *reason) {
    NSLog(@"[DuoFaceFullscreen] rollback: %@", reason);
    DFDashboardRestoreChrome();
    DFFullscreenConfirmed = NO;
    DFRequestHostFullscreen(NO, ^(BOOL restored, NSString *hostReason) {
        DFTransitionPending = NO;
        NSLog(@"[DuoFaceFullscreen] host restore ACK=%d %@", restored, hostReason);
        DFRefreshControl();
    });
}
static void DFEnterFullscreen(void) {
    if (!DFHostActive || DFTransitionPending || DFFullscreenConfirmed) return;
    DFTransitionPending = YES;
    NSUInteger generation = ++DFTransitionGeneration;
    DFRefreshControl();
    DFRequestHostFullscreen(YES, ^(BOOL geometryApplied, NSString *reason) {
        if (generation != DFTransitionGeneration) {
            DFRestoreAfterFailure(@"active host changed during enter"); return;
        }
        if (!geometryApplied || !DFHostActive) {
            DFRestoreAfterFailure(reason ?: @"host no longer active"); return;
        }
        NSString *chromeReason = nil;
        if (!DFDashboardSetChromeHidden(YES, &chromeReason)) {
            DFRestoreAfterFailure(chromeReason); return;
        }
        DFFullscreenConfirmed = YES;
        DFTransitionPending = NO;
        DFRefreshControl();
        NSLog(@"[DuoFaceFullscreen] host geometry and chrome acknowledged");
    });
}
BOOL DFStartFullscreenAdapter(void) {
    NSCAssert(NSThread.isMainThread, @"Adapter starts on main thread");
    if (DFAdapterStarted) return YES;
    NSString *bundle = NSBundle.mainBundle.bundleIdentifier.lowercaseString;
    if ([bundle isEqualToString:@"com.apple.springboard"]) {
        DFAdapterStarted = DFStartFullscreenTransport(YES, nil);
        return DFAdapterStarted;
    }
    if (![@[@"com.apple.carplayapp", @"com.apple.carplay", @"com.apple.dashboard"] containsObject:bundle])
        return NO;
    if (!DFInstallDashboardChromeHooks() || !DFInstallStatusBarControlHooks(^{ DFEnterFullscreen(); }))
        return NO;
    DFAdapterStarted = DFStartFullscreenTransport(NO, ^(NSDictionary *state) {
        BOOL active = [state[@"active"] boolValue];
        BOOL expanded = [state[@"expanded"] boolValue];
        if (!active && DFHostActive) ++DFTransitionGeneration;
        DFHostActive = active;
        // Close callback, owner loss, lease expiry, or a failed geometry request.
        if (!expanded || !active) {
            DFDashboardRestoreChrome();
            DFFullscreenConfirmed = NO;
        }
        DFRefreshControl();
    });
    return DFAdapterStarted;
}
