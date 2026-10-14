#import "DFDashboardChrome.h"

// Airaw receiver 0xe610 uses nativeChromeHidden -> statusbarWindow.setHidden:.
// The iOS26 dock hook is deliberately not substituted for the iOS16 receiver.
@interface DBStatusBarWindow : UIWindow
@end
@interface CARStatusBarWindow : UIWindow
@end

static NSHashTable<UIWindow *> *DFChromeWindows;
static NSMapTable<UIWindow *, NSNumber *> *DFChromeSnapshots;
static BOOL DFChromeHidden;
static BOOL DFChromeHooksInstalled;

static void DFObserveChromeWindow(UIWindow *window) {
    if (!window) return;
    [DFChromeWindows addObject:window];
    if (DFChromeHidden) {
        if (![DFChromeSnapshots objectForKey:window])
            [DFChromeSnapshots setObject:@(window.hidden) forKey:window];
        window.hidden = YES;
    }
}
void DFDashboardRestoreChrome(void) {
    NSCAssert(NSThread.isMainThread, @"Chrome restore requires main thread");
    DFChromeHidden = NO;
    for (UIWindow *window in DFChromeSnapshots.keyEnumerator) {
        NSNumber *hidden = [DFChromeSnapshots objectForKey:window];
        if (hidden) window.hidden = hidden.boolValue;
    }
    [DFChromeSnapshots removeAllObjects];
}
BOOL DFDashboardSetChromeHidden(BOOL hidden, NSString **reason) {
    NSCAssert(NSThread.isMainThread, @"Chrome transition requires main thread");
    if (!hidden) { DFDashboardRestoreChrome(); return YES; }
    if (!DFChromeHooksInstalled || DFChromeWindows.allObjects.count == 0) {
        if (reason) *reason = @"Airaw-compatible statusbar window has not been observed";
        return NO;
    }
    DFChromeHidden = YES;
    for (UIWindow *window in DFChromeWindows.allObjects) DFObserveChromeWindow(window);
    for (UIWindow *window in DFChromeWindows.allObjects) {
        if (!window.hidden) {
            DFDashboardRestoreChrome();
            if (reason) *reason = @"statusbar window did not accept hidden state";
            return NO;
        }
    }
    return YES;
}

%group DFDashboardChromeDB
%hook DBStatusBarWindow
- (void)layoutSubviews {
    %orig;
    DFObserveChromeWindow((UIWindow *)self);
}
%end
%end
%group DFDashboardChromeCAR
%hook CARStatusBarWindow
- (void)layoutSubviews {
    %orig;
    DFObserveChromeWindow((UIWindow *)self);
}
%end
%end

BOOL DFInstallDashboardChromeHooks(void) {
    if (DFChromeHooksInstalled) return YES;
    NSString *bundle = NSBundle.mainBundle.bundleIdentifier.lowercaseString;
    if (![@[@"com.apple.carplayapp", @"com.apple.carplay", @"com.apple.dashboard"] containsObject:bundle])
        return NO;
    DFChromeWindows = [NSHashTable weakObjectsHashTable];
    DFChromeSnapshots = [NSMapTable weakToStrongObjectsMapTable];
    if (NSClassFromString(@"DBStatusBarWindow")) {
        %init(DFDashboardChromeDB);
        DFChromeHooksInstalled = YES;
    } else if (NSClassFromString(@"CARStatusBarWindow")) {
        %init(DFDashboardChromeCAR);
        DFChromeHooksInstalled = YES;
    }
    return DFChromeHooksInstalled;
}
