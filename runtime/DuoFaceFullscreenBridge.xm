// EXPERIMENTAL fullscreen-only bridge. Does not embed Airaw or alter DuoFace's split logic.
// Based on verified Airaw host scene selectors; requires CarPlay runtime validation.
// Do not ship to Sileo without device test.
#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>

// No fullscreen UI may be attached to the DuoFace split pill.
static BOOL DFHostFull = NO;
static __weak UIViewController *DFHostController;
static CGRect DFSavedFrame;
static BOOL DFHasSavedFrame = NO;

static BOOL DFSendBool(id obj, NSString *name, BOOL value) {
    SEL sel = NSSelectorFromString(name);
    if (!obj || ![obj respondsToSelector:sel]) return NO;
    ((void (*)(id, SEL, BOOL))objc_msgSend)(obj, sel, value);
    return YES;
}
static void DFApplyFullscreen(BOOL enable) {
    UIViewController *host = DFHostController;
    if (!host || !host.view || !host.view.superview) {
        NSLog(@"[DuoFaceFullscreen] host unavailable; no change");
        return;
    }
    UIView *v = host.view;
    if (enable) {
        if (!DFHasSavedFrame) {
            DFSavedFrame = v.frame;
            DFHasSavedFrame = YES;
        }
        // Airaw's verified chrome selector, guarded for OS variations.
        BOOL chrome = DFSendBool(host, @"setDefaultAppChromeHidden:", YES);
        UIView *container = v.superview;
        v.transform = CGAffineTransformIdentity;
        v.frame = container.bounds;
        DFHostFull = YES;
        NSLog(@"[DuoFaceFullscreen] enter chrome=%d", chrome);
    } else {
        DFSendBool(host, @"setDefaultAppChromeHidden:", NO);
        v.transform = CGAffineTransformIdentity;
        if (DFHasSavedFrame) v.frame = DFSavedFrame;
        DFHasSavedFrame = NO;
        DFHostFull = NO;
        NSLog(@"[DuoFaceFullscreen] restore");
    }
}
// Airaw 1.7.1k method requestFullscreenToggle sends this exact name.
// Use a local listener so the test remains functional without Airaw installed.
static NSString * const kDFFullscreenEvent = @"jp.airaw.host.fullscreen";
@interface DFFullscreenEventReceiver : NSObject
+ (instancetype)shared;
- (void)received:(NSNotification *)note;
@end
@implementation DFFullscreenEventReceiver
+ (instancetype)shared {
    static DFFullscreenEventReceiver *receiver;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        receiver = [DFFullscreenEventReceiver new];
        [[NSNotificationCenter defaultCenter] addObserver:receiver selector:@selector(received:) name:kDFFullscreenEvent object:nil];
    });
    return receiver;
}
- (void)received:(NSNotification *)note {
    NSNumber *enabled = [note.userInfo objectForKey:@"enabled"];
    DFApplyFullscreen(enabled ? enabled.boolValue : !DFHostFull);
}
@end
static void DFRequestFullscreen(NSNumber *enabled) {
    [DFFullscreenEventReceiver shared];
    [[NSNotificationCenter defaultCenter] postNotificationName:kDFFullscreenEvent object:nil
                                                     userInfo:enabled ? @{@"enabled":enabled} : nil];
}
static void DFToggleFullscreen(void) { DFRequestFullscreen(nil); }

// Diagnostic: constructor runs only if the dylib is actually injected into this process.
__attribute__((constructor)) static void DFBridgeLoaded(void) {
    NSLog(@"[DuoFaceFullscreen] LOADED process=%@ bundle=%@ DBApplicationVC=%d CBSlotPillView=%d DBRootStatusBarVC=%d DBDockRootVC=%d",
          [NSProcessInfo processInfo].processName, [NSBundle mainBundle].bundleIdentifier,
          objc_getClass("DBApplicationViewController") != Nil,
          objc_getClass("CBSlotPillView") != Nil,
          objc_getClass("DBRootStatusBarViewController") != Nil,
          objc_getClass("DBDockRootViewController") != Nil);
}

// Fullscreen UI control will be bound after verifying the CarPlay host lifecycle.
// Host controller is captured by its existing layout callback.
// Bind the existing DuoFace fullscreen pill action to the host fullscreen bridge.
%hook DBApplicationViewController
- (void)viewDidLayoutSubviews {
    %orig;
    DFHostController = (UIViewController *)self;
    // Actual CarPlay pill placement is handled by CBSlotPillView.
}
%end

// Explicit entry point for future DuoFace UI binding.
// Avoid redirecting expandTapped:/restoreTapped: before confirming target ownership.
@interface DuoFaceFullscreenAction : NSObject
+ (void)toggle;
+ (void)restore;
@end
@implementation DuoFaceFullscreenAction
+ (void)toggle { DFToggleFullscreen(); }
+ (void)restore { DFRequestFullscreen(@NO); }
@end


// Split-pill actions deliberately remain untouched. Fullscreen must be triggered
// exclusively by the future top CarPlay status-bar control while DuoFace is visible.
