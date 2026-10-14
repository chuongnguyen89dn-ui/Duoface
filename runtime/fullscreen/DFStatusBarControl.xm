#import "DFStatusBarControl.h"
#import <objc/message.h>

// Airaw: defaults 0x8330–0x83d0; installer 0x14c94–0x14dd0.
// x=12.5, y=42, size=20. Symbol pointSize=10, weight=3, background image,
// white tint, initially hidden, target is the owning bar controller.
@interface DBDockRootViewController : UIViewController
- (void)df_carplayFullscreen;
@end
@interface DBRootStatusBarViewController : UIViewController
- (void)df_carplayFullscreen;
@end
@interface CARRootStatusBarViewController : UIViewController
- (void)df_carplayFullscreen;
@end
static NSMapTable<UIViewController *, UIButton *> *DFControls;
static BOOL DFControlVisible;
static BOOL DFControlEnabled;
static BOOL DFControlInstalled;
static void (^DFControlPressed)(void);

static void DFLayoutControl(UIViewController *owner) {
    if (!owner.isViewLoaded) return;
    UIButton *button = [DFControls objectForKey:owner];
    if (!button) {
        button = [[UIButton alloc] initWithFrame:CGRectMake(12.5, 42, 20, 20)];
        UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration
            configurationWithPointSize:10 weight:(UIImageSymbolWeight)3];
        UIImage *image = [UIImage systemImageNamed:@"arrow.up.left.and.arrow.down.right"
                                withConfiguration:configuration];
        [button setBackgroundImage:image forState:UIControlStateNormal];
        [button addTarget:owner action:NSSelectorFromString(@"df_carplayFullscreen")
            forControlEvents:UIControlEventTouchUpInside];
        button.hidden = YES; button.tintColor = UIColor.whiteColor;
        button.accessibilityLabel = @"DuoFace fullscreen";
        [owner.view addSubview:button];
        [DFControls setObject:button forKey:owner];
    }
    button.hidden = !DFControlVisible;
    button.enabled = DFControlEnabled;
}
void DFSetStatusBarControlState(BOOL visible, BOOL enabled) {
    NSCAssert(NSThread.isMainThread, @"Control state requires main thread");
    DFControlVisible = visible; DFControlEnabled = enabled;
    for (UIViewController *owner in DFControls.keyEnumerator) DFLayoutControl(owner);
}
static void DFBarPressed(void) {
    if (DFControlVisible && DFControlEnabled && DFControlPressed) DFControlPressed();
}

%group DFStatusControlDock
%hook DBDockRootViewController
- (void)viewDidLoad {
    %orig;
    DFLayoutControl((UIViewController *)self);
}
- (void)viewDidLayoutSubviews {
    %orig;
    DFLayoutControl((UIViewController *)self);
}
%new
- (void)df_carplayFullscreen { DFBarPressed(); }
%end
%end
%group DFStatusControlDB
%hook DBRootStatusBarViewController
- (void)viewDidLoad {
    %orig;
    DFLayoutControl((UIViewController *)self);
}
- (void)viewDidLayoutSubviews {
    %orig;
    DFLayoutControl((UIViewController *)self);
}
%new
- (void)df_carplayFullscreen { DFBarPressed(); }
%end
%end
%group DFStatusControlCAR
%hook CARRootStatusBarViewController
- (void)viewDidLoad {
    %orig;
    DFLayoutControl((UIViewController *)self);
}
- (void)viewDidLayoutSubviews {
    %orig;
    DFLayoutControl((UIViewController *)self);
}
%new
- (void)df_carplayFullscreen { DFBarPressed(); }
%end
%end

BOOL DFInstallStatusBarControlHooks(void (^pressed)(void)) {
    if (DFControlInstalled) return YES;
    NSString *bundle = NSBundle.mainBundle.bundleIdentifier.lowercaseString;
    if (![@[@"com.apple.carplayapp", @"com.apple.carplay", @"com.apple.dashboard"] containsObject:bundle])
        return NO;
    DFControls = [NSMapTable weakToStrongObjectsMapTable];
    DFControlPressed = [pressed copy];
    // Same availability priority as Airaw; only one host family, avoiding duplicates.
    if (NSClassFromString(@"DBDockRootViewController")) {
        %init(DFStatusControlDock); DFControlInstalled = YES;
    } else if (NSClassFromString(@"DBRootStatusBarViewController")) {
        %init(DFStatusControlDB); DFControlInstalled = YES;
    } else if (NSClassFromString(@"CARRootStatusBarViewController")) {
        %init(DFStatusControlCAR); DFControlInstalled = YES;
    }
    return DFControlInstalled;
}
