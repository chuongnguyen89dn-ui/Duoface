#import "DFSPNative12ChromeOwner.h"

@interface DFSPNative12ChromeOwner ()
@property(nonatomic,copy) NSArray<UIWindow *> *windows;
@property(nonatomic,strong) NSMapTable<UIWindow *, NSNumber *> *originalHidden;
@property(nonatomic,readwrite) BOOL active;
@property(nonatomic,readwrite) BOOL chromeHidden;
@end
@implementation DFSPNative12ChromeOwner
- (instancetype)initWithObservedWindows:(NSArray<UIWindow *> *)windows {
    if ((self=[super init])) {
        _windows=[windows copy];
        _originalHidden=[NSMapTable weakToStrongObjectsMapTable];
        _active=NO;
        _chromeHidden=NO;
    }
    return self;
}
- (BOOL)beginActiveSessionShowingBar {
    NSCAssert(NSThread.isMainThread,@"Native CarPlay chrome must be set on main");
    if (self.active || self.windows.count==0) return NO;
    // The caller must have verified these are SidePlay's live CarPlay chrome
    // windows. Never obtain a global UIWindow list from this module.
    for (UIWindow *window in self.windows)
        [self.originalHidden setObject:@(window.hidden) forKey:window];
    self.active=YES;
    if (![self setSystemBarHidden:NO]) {
        [self endSessionRestoreOriginalVisibility];
        return NO;
    }
    return YES;
}
- (BOOL)setSystemBarHidden:(BOOL)hidden {
    NSCAssert(NSThread.isMainThread,@"Native CarPlay chrome must be set on main");
    if (!self.active || self.windows.count==0) return NO;
    for (UIWindow *window in self.windows) {
        if (![self.originalHidden objectForKey:window]) return NO;
        window.hidden=hidden;
    }
    for (UIWindow *window in self.windows)
        if (window.hidden!=hidden) return NO;
    self.chromeHidden=hidden;
    // The observed UIWindow.hidden value is NOT proof that SidePlay's higher
    // windowLevel no longer covers this bar. Device screenshots still required.
    return YES;
}
- (void)endSessionRestoreOriginalVisibility {
    NSCAssert(NSThread.isMainThread,@"Native CarPlay chrome must be set on main");
    for (UIWindow *window in self.windows) {
        NSNumber *saved=[self.originalHidden objectForKey:window];
        if (saved) window.hidden=saved.boolValue;
    }
    [self.originalHidden removeAllObjects];
    self.chromeHidden=NO;
    self.active=NO;
}
@end
