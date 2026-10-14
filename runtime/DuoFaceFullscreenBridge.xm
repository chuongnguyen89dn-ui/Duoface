// EXPERIMENTAL fullscreen-only bridge. Does not embed Airaw or alter DuoFace's split logic.
// Based on verified Airaw host scene selectors; requires CarPlay runtime validation.
// Do not ship to Sileo without device test.
#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>

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
static void DFToggleFullscreen(void) { DFApplyFullscreen(!DFHostFull); }

// Fullscreen UI control will be bound after verifying the CarPlay host lifecycle.
// Host controller is captured by its existing layout callback.
// Bind the existing DuoFace fullscreen pill action to the host fullscreen bridge.
%hook DBApplicationViewController
- (void)viewDidLayoutSubviews {
    %orig;
    DFHostController = (UIViewController *)self;
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
+ (void)restore { DFApplyFullscreen(NO); }
@end

// Bind to DuoFace v12's known expand/restore controls without altering their
// button target-action lists. The fullscreen bridge runs after the original
// action so the original split-pane behavior is preserved by default.
// For whole-host fullscreen, the user can reverse this order if device tests
// show the original per-pane animation conflicts with host layout.
%hook CBSlotPillView
- (void)expandTapped:(id)sender {
    %orig;
    dispatch_async(dispatch_get_main_queue(), ^{ DFApplyFullscreen(YES); });
}
- (void)restoreTapped:(id)sender {
    %orig;
    dispatch_async(dispatch_get_main_queue(), ^{ DFApplyFullscreen(NO); });
}
%end
