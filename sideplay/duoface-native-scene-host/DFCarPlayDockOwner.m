// DuoFace independent native CarPlay UI Dock owner (iOS16, rootless).
// Separate CarPlay/CarPlayApp process. No Native12 vendor class, binary or license.
// Only acts upon a fresh, foreground DuoFace session + exact request ID.
// Never treat a statusbar or a synthetic left stripe as the Apple AppDock.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <notify.h>
#import <math.h>

static NSString *const DFZSession=@"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist";
static NSString *const DFZCommand=@"/var/mobile/Library/Preferences/com.duoface.nativehost.dockzoom.command.plist";
static NSString *const DFZAck=@"/var/mobile/Library/Preferences/com.duoface.nativehost.dockzoom.ack.plist";
static const char *const DFZNotify="com.duoface.nativehost.dockzoom.command.v1";
static const char *const DFZAckNotify="com.duoface.nativehost.dockzoom.ack.v1";
static UIView *DFZDockView;
static UIWindow *DFZWindow;
static NSString *DFZOwnerSession;
static BOOL DFZSavedHidden;
static NSUInteger DFZLastSequence;
static int DFZToken=-1;
static NSUInteger DFZGeneration;

static BOOL DFZCarPlayProcess(void) {
    NSString *name=NSProcessInfo.processInfo.processName;
    return [name isEqualToString:@"CarPlay"] || [name isEqualToString:@"CarPlayApp"];
}
static BOOL DFZFreshSession(NSString *session) {
    NSDictionary *pulse=[NSDictionary dictionaryWithContentsOfFile:DFZSession];
    id stamp=pulse[@"Timestamp"];
    if(![pulse[@"Active"] isEqual:@YES] ||
       ![pulse[@"Session"] isKindOfClass:NSString.class] ||
       ![pulse[@"Session"] isEqualToString:session] ||
       ![stamp isKindOfClass:NSNumber.class])return NO;
    NSTimeInterval age=NSDate.date.timeIntervalSince1970-[stamp doubleValue];
    return isfinite(age) && age>=0 && age<=2.5;
}
static BOOL DFZVisibleDockGeometry(UIView *view, UIWindow *window) {
    if(!view || !window || window.hidden || !window.screen ||
       view.hidden || view.alpha<0.9 || CGRectIsEmpty(view.bounds) ||
       ![view isDescendantOfView:window])return NO;
    CGRect screen=window.screen.bounds;
    // Dock windows may have a non-zero origin; measure in SCREEN coordinates.
    CGRect r=[view convertRect:view.bounds toCoordinateSpace:window.screen.coordinateSpace];
    CGFloat width=screen.size.width,height=screen.size.height;
    // A real left/right CarPlay launcher rail, not video pane, overlay or bar.
    return width>=300 && height>=145 &&
        r.size.width>=24 && r.size.width<=fmax(105,width*.30) &&
        r.size.height>=height*.48 &&
        (fabs(CGRectGetMinX(r)-CGRectGetMinX(screen))<25 ||
         fabs(CGRectGetMaxX(r)-CGRectGetMaxX(screen))<25);
}
static UIView *DFZControllerDockView(UIViewController *root, UIWindow *window,
                                     NSUInteger depth) {
    if(!root || depth>6)return nil;
    // Historical project evidence names DBDockRootViewController as a native
    // Dock owner. Accept only its loaded view and measured rail, never statusbar.
    Class dockRoot=NSClassFromString(@"DBDockRootViewController");
    if(dockRoot && [root isKindOfClass:dockRoot] &&
       DFZVisibleDockGeometry(root.viewIfLoaded,window))return root.viewIfLoaded;
    // The original Native12 'CBDashboardShared.appDockVC' returned the real
    // Dashboard root's AppDock controller. Here use ONLY a live UIKit owner
    // actually responding to appDockViewController (original selref 0x37eaf8),
    // not the vendor wrapper names appDockVC/currentAppDockVC.
    Class dashboardRoot=NSClassFromString(@"DBDashboardRootViewController");
    if([root respondsToSelector:NSSelectorFromString(@"appDockViewController")] ||
       (dashboardRoot && [root isKindOfClass:dashboardRoot])) {
        for(NSString *key in @[@"appDockViewController",@"appDockVC",@"currentAppDockVC"]) {
            SEL getter=NSSelectorFromString(key);
            if(![root respondsToSelector:getter])continue;
            Method method=class_getInstanceMethod(root.class,getter);
            char ret[16]={0};
            if(!method)continue;
            method_getReturnType(method,ret,sizeof(ret));
            if(ret[0]!='@')continue;
            @try {
                id candidate=((id(*)(id,SEL))objc_msgSend)(root,getter);
                if([candidate isKindOfClass:UIViewController.class]) {
                    UIView *view=[candidate viewIfLoaded];
                    if(DFZVisibleDockGeometry(view,window))return view;
                }
            } @catch(NSException *e) {
                NSLog(@"[DuoFaceDockOwner] getter-rejected %@",e.name);
            }
        }
    }
    for(UIViewController *child in root.childViewControllers) {
        UIView *found=DFZControllerDockView(child,window,depth+1);
        if(found)return found;
    }
    return nil;
}
static UIView *DFZDockClassView(UIView *root, UIWindow *window, NSUInteger depth) {
    if(depth>14 || !root)return nil;
    NSString *name=NSStringFromClass(root.class);
    if([@[@"DBAppDockView",@"DBDockView",@"CARAppDockView"] containsObject:name] &&
       DFZVisibleDockGeometry(root,window))return root;
    for(UIView *child in root.subviews) {
        UIView *found=DFZDockClassView(child,window,depth+1);
        if(found)return found;
    }
    return nil;
}
static BOOL DFZLocateLiveNativeDock(UIView **outView, UIWindow **outWindow,
                                    NSString **outReason) {
    UIView *found=nil;UIWindow *owner=nil;NSUInteger matches=0;
    // iOS16 system UI can retain legacy native windows outside connectedScenes.
    // Deduplicate windows before the one-owner check, or one Dock is counted twice.
    NSMutableOrderedSet<UIWindow *> *windows=[NSMutableOrderedSet orderedSet];
    for(UIWindow *window in UIApplication.sharedApplication.windows) {
        UIWindowScene *scene=window.windowScene;
        if(!scene || scene.activationState==UISceneActivationStateForegroundActive)
            [windows addObject:window];
    }
    for(UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if(![scene isKindOfClass:UIWindowScene.class] ||
           scene.activationState!=UISceneActivationStateForegroundActive)continue;
        [windows addObjectsFromArray:((UIWindowScene *)scene).windows];
    }
    for(UIWindow *window in windows) {
            if(window.hidden || window.alpha<.95 || !window.rootViewController)
                continue;
            UIView *candidate=DFZControllerDockView(window.rootViewController,window,0);
            if(!candidate)
                candidate=DFZDockClassView(window.rootViewController.view,window,0);
            // Some iOS16 dashboards provide a dedicated *native* Dock UIWindow.
            // A class-name match alone is not sufficient: geometry must match.
            if(!candidate && [NSStringFromClass(window.class) isEqualToString:@"DBDockWindow"] &&
               DFZVisibleDockGeometry(window.rootViewController.view,window))
                candidate=window.rootViewController.view;
            if(candidate) {found=candidate;owner=window;matches++;}
    }
    if(matches!=1) {
        if(outReason)*outReason=matches?@"ambiguous-native-dock-owner":@"no-verified-live-native-appdock";
        return NO;
    }
    if(outView)*outView=found;
    if(outWindow)*outWindow=owner;
    return YES;
}
static void DFZRestore(void) {
    if(DFZDockView) {
        // Restore only our saved Dock's own state, never the entire dashboard.
        DFZDockView.hidden=DFZSavedHidden;
        NSLog(@"[DuoFaceDockOwner] native-dock-restored hidden=%d",DFZDockView.hidden);
    }
    DFZDockView=nil;DFZWindow=nil;DFZOwnerSession=nil;
    DFZLastSequence=0;
}
static void DFZReply(NSDictionary *command, BOOL applied, BOOL expanded,
                     NSString *reason, NSString *owner, CGRect bounds) {
    NSDictionary *reply=@{
        @"Version":@1,@"Session":command[@"Session"]?:@"",
        @"RequestID":command[@"RequestID"]?:@"",
        @"Sequence":command[@"Sequence"]?:@0,
        @"Applied":@(applied),@"Expanded":@(expanded),
        @"DockOwnerVerified":@(applied),
        @"DockHidden":@(applied && expanded),
        @"ScreenBounds":NSStringFromCGRect(bounds),
        @"OwnerClass":owner?:@"",
        @"Reason":reason?:@"",
        @"Timestamp":@(NSDate.date.timeIntervalSince1970)
    };
    if([reply writeToFile:DFZAck atomically:YES])notify_post(DFZAckNotify);
    NSLog(@"[DuoFaceDockOwner] request=%@ applied=%d expanded=%d reason=%@",
          reply[@"RequestID"],applied,expanded,reason?:@"ok");
}
static void DFZHandleCommand(void) {
    if(!DFZCarPlayProcess() || !NSThread.isMainThread)return;
    NSDictionary *cmd=[NSDictionary dictionaryWithContentsOfFile:DFZCommand];
    id session=cmd[@"Session"], request=cmd[@"RequestID"];
    id seq=cmd[@"Sequence"], stamp=cmd[@"Timestamp"];
    if(![cmd[@"Version"] isEqual:@1] ||
       ![cmd[@"Operation"] isEqualToString:@"SetDockHidden"] ||
       ![session isKindOfClass:NSString.class] ||
       ![[NSUUID alloc] initWithUUIDString:session] ||
       ![request isKindOfClass:NSString.class] ||
       ![[NSUUID alloc] initWithUUIDString:request] ||
       ![seq isKindOfClass:NSNumber.class] ||
       [seq unsignedLongLongValue]==0 ||
       ![stamp isKindOfClass:NSNumber.class] ||
       ![cmd[@"Expanded"] isKindOfClass:NSNumber.class])return;
    NSTimeInterval age=NSDate.date.timeIntervalSince1970-[stamp doubleValue];
    if(!isfinite(age) || age<0 || age>2.0)return;
    BOOL expanded=[cmd[@"Expanded"] boolValue];
    // A restore belonging to the session that hid the Dock is always allowed:
    // Home may already have revoked the heartbeat before cleanup.
    if(!DFZFreshSession(session) &&
       (expanded || ![DFZOwnerSession isEqualToString:session])){
        DFZReply(cmd,NO,expanded,@"no-fresh-foreground-session",nil,CGRectZero);
        return;
    }
    if(DFZOwnerSession && ![DFZOwnerSession isEqualToString:session]){
        DFZRestore();
        if(expanded) {
            DFZReply(cmd,NO,YES,@"previous-session-owner-revoked",nil,CGRectZero);
            return;
        }
    }
    if(expanded) {
        UIView *view=nil;UIWindow *window=nil;NSString *reason=nil;
        if(!DFZDockView && !DFZLocateLiveNativeDock(&view,&window,&reason)) {
            DFZReply(cmd,NO,YES,reason,nil,CGRectZero);return;
        }
        if(DFZDockView) {view=DFZDockView;window=DFZWindow;}
        if(!view || !window || window.hidden || !window.screen) {
            DFZReply(cmd,NO,YES,@"dock-owner-disconnected",nil,CGRectZero);return;
        }
        if(!DFZDockView) {
            DFZSavedHidden=view.hidden;DFZDockView=view;DFZWindow=window;
            DFZOwnerSession=[session copy];
        }
        view.hidden=YES;
        if(!view.hidden){
            DFZRestore();
            DFZReply(cmd,NO,YES,@"native-dock-refused-hidden",nil,CGRectZero);
            return;
        }
        DFZLastSequence=[seq unsignedIntegerValue];
        DFZReply(cmd,YES,YES,nil,NSStringFromClass(view.class),window.screen.bounds);
    }else{
        if(!DFZDockView || ![DFZOwnerSession isEqualToString:session]) {
            DFZReply(cmd,NO,NO,@"missing-restorable-dock-snapshot",nil,CGRectZero);
            return;
        }
        CGRect bounds=DFZWindow.screen.bounds;
        NSString *klass=NSStringFromClass(DFZDockView.class);
        BOOL desired=DFZSavedHidden;
        DFZDockView.hidden=desired;
        BOOL restored=(DFZDockView.hidden==desired);
        if(restored)DFZRestore();
        DFZReply(cmd,restored,NO,restored?nil:@"dock-restore-not-verified",
                 klass,bounds);
    }
}
static void DFZWatch(NSUInteger generation) {
    if(generation!=DFZGeneration || !DFZCarPlayProcess())return;
    if(DFZDockView) {
        if(!DFZOwnerSession || !DFZFreshSession(DFZOwnerSession) ||
           !DFZWindow || DFZWindow.hidden || !DFZWindow.screen) {
            DFZRestore();
        }
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(.5*NSEC_PER_SEC)),
                   dispatch_get_main_queue(),^{ DFZWatch(generation); });
}
__attribute__((constructor))
static void DFZInstallDockReceiver(void) {
    @autoreleasepool {
        if(!DFZCarPlayProcess())return;
        dispatch_async(dispatch_get_main_queue(), ^{
            int result=notify_register_dispatch(DFZNotify,&DFZToken,
                   dispatch_get_main_queue(),^(int token){
                       (void)token;DFZHandleCommand();
                   });
            if(result==0){
                NSLog(@"[DuoFaceDockOwner] listener-ready process=%@",
                      NSProcessInfo.processInfo.processName);
                DFZWatch(++DFZGeneration);
            }
        });
    }
}
