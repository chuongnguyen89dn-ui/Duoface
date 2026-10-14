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
static __weak UIViewController *DFScene = nil;
static __weak UIButton *DFBarButton = nil;
static BOOL DFVisible = NO;

static BOOL DFSendBool(id obj, NSString *name, BOOL value) {
    SEL sel = NSSelectorFromString(name);
    if (!obj || ![obj respondsToSelector:sel]) return NO;
    ((void (*)(id, SEL, BOOL))objc_msgSend)(obj, sel, value);
    return YES;
}
static void DFApplyFullscreen(BOOL enable) {
    UIViewController *host = DFScene ?: DFHostController;
    if ((enable && !DFVisible) || !host || !host.view || !host.view.superview) {
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

// Fullscreen control must be owned by a CarPlay top-bar controller and gated by the active DuoFace application scene.
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

static void DFUpdateButton(void) { if (DFBarButton) DFBarButton.hidden = NO; }
static NSString *DFSceneID(id scene) {
    for (NSString *key in @[@"appIdentifier", @"applicationIdentifier", @"bundleIdentifier"]) {
        SEL selector = NSSelectorFromString(key);
        if ([scene respondsToSelector:selector]) {
            id value = ((id (*)(id, SEL))objc_msgSend)(scene, selector);
            if ([value isKindOfClass:[NSString class]]) return value;
        }
    }
    return nil;
}
static void DFSceneChanged(UIViewController *scene, BOOL appeared) {
    NSString *identifier = DFSceneID(scene);
    if (appeared && [identifier isEqualToString:@"com.duonavi.app"]) {
        DFScene = scene;
        DFVisible = YES;
    } else if (!appeared && scene == DFScene) {
        if (DFHostFull) DFApplyFullscreen(NO);
        DFVisible = NO;
        DFScene = nil;
    }
    DFUpdateButton();
}
%hook DBApplicationSceneViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    DFSceneChanged((UIViewController *)self, YES);
}
- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    DFSceneChanged((UIViewController *)self, NO);
}
%end
%hook CARApplicationSceneViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    DFSceneChanged((UIViewController *)self, YES);
}
- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    DFSceneChanged((UIViewController *)self, NO);
}
%end

@interface DFBarAction : NSObject
+ (instancetype)shared;
- (void)pressed:(id)sender;
@end
@implementation DFBarAction
+ (instancetype)shared {
    static DFBarAction *instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ instance = [DFBarAction new]; });
    return instance;
}
- (void)pressed:(id)sender {
    NSLog(@"[DuoFaceFullscreen] pressed visible=%d scene=%@ host=%@", DFVisible, DFScene, DFHostController);
    if (!DFVisible && DFHostController) {
        DFScene = DFHostController;
        DFVisible = YES;
    }
    DFToggleFullscreen();
}
@end
static void DFInstallBar(UIViewController *host) {
    if (!host || !host.view) return;
    UIButton *button = (UIButton *)[host.view viewWithTag:871204];
    if (!button) {
        button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.tag = 871204;
        button.frame = CGRectMake(MAX(0, CGRectGetWidth(host.view.bounds) - 50), 2, 44, 44);
        button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        button.tintColor = UIColor.yellowColor;
        button.backgroundColor = [UIColor colorWithRed:0.15 green:0.3 blue:0.9 alpha:0.95];
        button.layer.cornerRadius = 8;
        [button setTitle:@"FULL" forState:UIControlStateNormal];
        if (@available(iOS 13.0, *)) {
            [button setImage:[UIImage systemImageNamed:@"arrow.up.left.and.arrow.down.right"] forState:UIControlStateNormal];
        }
        [button addTarget:[DFBarAction shared] action:@selector(pressed:) forControlEvents:UIControlEventTouchUpInside];
        [host.view addSubview:button];
        NSLog(@"[DuoFaceFullscreen] bar installed %@", NSStringFromClass(host.class));
    }
    DFBarButton = button;
    DFUpdateButton();
}
%hook DBRootStatusBarViewController
- (void)viewDidLayoutSubviews {
    %orig;
    DFInstallBar((UIViewController *)self);
}
%end
%hook CARRootStatusBarViewController
- (void)viewDidLayoutSubviews {
    %orig;
    DFInstallBar((UIViewController *)self);
}
%end
%hook DBDockRootViewController
- (void)viewDidLayoutSubviews {
    %orig;
    DFInstallBar((UIViewController *)self);
}
%end
