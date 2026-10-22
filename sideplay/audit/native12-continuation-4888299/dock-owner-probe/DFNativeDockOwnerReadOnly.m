// Independent read-only iOS16 CarPlay/Dashboard ownership inventory.
// NOT compiled, injected or installed by any current DuoFace workflow.
// Invoked explicitly on the MAIN THREAD in an already-running CarPlay UI process.
// Returns observation only; never mutate the native Apple Dock or windows.
// Original Native12 appDockVC IMP evidence is a reference, NOT a class to invoke.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static BOOL DFInObservedCarPlayProcess(void) {
    NSString *name=[NSProcessInfo processInfo].processName;
    return [name isEqualToString:@"CarPlay"] ||
           [name isEqualToString:@"CarPlayApp"];
}

static BOOL DFWindowMatchesExistingDockClass(UIWindow *w) {
    // DBDockWindow is evidenced in the historical Airaw 1.7.1k static audit.
    // Its runtime presence and whether it is Apple's navigation Dock are UNKNOWN.
    Class dock=NSClassFromString(@"DBDockWindow");
    return dock && [w isKindOfClass:dock];
}

__attribute__((visibility("default")))
NSDictionary<NSString *,id> *DFNativeDockReadOnlySnapshot(void) {
    @autoreleasepool {
        if(!DFInObservedCarPlayProcess())
            return @{@"Status":@"WrongProcess",
                     @"DockOwnerVerified":@NO, @"DockHiddenAck":@NO};
        if(![NSThread isMainThread])
            return @{@"Status":@"NeedsMainThread",
                     @"DockOwnerVerified":@NO, @"DockHiddenAck":@NO};

        NSMutableArray<NSDictionary *> *scenes=[NSMutableArray array];
        NSUInteger seenWindows=0, dockWindowCandidates=0;
        for(UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if(![scene isKindOfClass:[UIWindowScene class]])continue;
            UIWindowScene *ws=(UIWindowScene *)scene;
            NSMutableArray<NSDictionary *> *windows=[NSMutableArray array];
            for(UIWindow *w in ws.windows) {
                BOOL candidate=DFWindowMatchesExistingDockClass(w);
                if(candidate)dockWindowCandidates++;
                seenWindows++;
                [windows addObject:@{
                    @"Class":NSStringFromClass([w class])?:@"",
                    @"RootClass":w.rootViewController?
                        NSStringFromClass([w.rootViewController class]):@"",
                    @"Frame":NSStringFromCGRect(w.frame),
                    @"Bounds":NSStringFromCGRect(w.bounds),
                    @"ScreenBounds":w.screen?
                        NSStringFromCGRect(w.screen.bounds):@"NoScreen",
                    @"Level":@(w.windowLevel),
                    @"Hidden":@(w.hidden),
                    @"Alpha":@(w.alpha),
                    @"IsDBDockWindowCandidate":@(candidate)
                }];
            }
            [scenes addObject:@{
                @"SceneClass":NSStringFromClass([scene class])?:@"",
                @"ActivationState":@(scene.activationState),
                @"ScreenBounds":ws.screen?
                    NSStringFromCGRect(ws.screen.bounds):@"NoScreen",
                @"Windows":windows
            }];
        }
        // Do NOT equate a candidate class/window with a verified live
        // CBDashboardShared.appDockVC, real Dock visibility, or hidden ACK.
        return @{
            @"Status":@"ReadOnlyInventory",
            @"Process":[NSProcessInfo processInfo].processName?:@"",
            @"DBDockWindowClassPresent":@(NSClassFromString(@"DBDockWindow")!=Nil),
            @"DBDashboardRootViewControllerClassPresent":
                @(NSClassFromString(@"DBDashboardRootViewController")!=Nil),
            @"DBDashboardWorkspaceOwnerClassPresent":
                @(NSClassFromString(@"DBDashboardWorkspaceOwner")!=Nil),
            @"SceneCount":@(scenes.count),
            @"WindowCount":@(seenWindows),
            @"DockWindowCandidateCount":@(dockWindowCandidates),
            @"Scenes":scenes,
            @"DockOwnerVerified":@NO,
            @"DockHiddenAck":@NO
        };
    }
}
