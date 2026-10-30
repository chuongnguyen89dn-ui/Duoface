#import "DFDeepTrace.h"
#import "DFGeometrySnapshot119.h"
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
#import <fcntl.h>
#import <unistd.h>

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
static NSString *DFZHandledSession;
static NSUInteger DFZHandledSequence;

// One-shot ownership diagnostics when Zoom is pressed. Writes no app IDs or
// user content. Failure to write must never affect Dock ownership/restore.
static void DFZLog(NSString *message) {
    DFDeepTrace(@"dock",message);
    NSString *line=[NSString stringWithFormat:@"[DuoFaceDockOwner] %@\n",message?:@""];
    NSLog(@"%@",line);
    int fd=open("/var/mobile/Library/Logs/DuoFaceDockOwner.log",
                O_WRONLY|O_APPEND|O_CREAT,0644);
    if(fd>=0) {
        NSData *data=[line dataUsingEncoding:NSUTF8StringEncoding];
        (void)write(fd,data.bytes,data.length);
        close(fd);
    }
}

static BOOL DFZCarPlayProcess(void) {
    NSString *name=NSProcessInfo.processInfo.processName;
    // Historical working v12 fullscreen adapter registered Dashboard alongside
    // CarPlay and CarPlayApp. Keep the extra process strictly bundle-gated:
    // only a REAL measured Apple Dock under its own UIKit owner may get an ACK.
    NSString *bundle=NSBundle.mainBundle.bundleIdentifier.lowercaseString;
    return [name isEqualToString:@"CarPlay"] || [name isEqualToString:@"CarPlayApp"] ||
           ([bundle isEqualToString:@"com.apple.dashboard"] &&
            [name.lowercaseString isEqualToString:@"dashboard"]);
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
    // The source audit recorded real DBAppDockViewController and
    // CARAppDockViewController candidates. Their root UIKit view may be
    // an ordinary UIView; do not require a vendor/custom view class.
    // Still require the measured live native rail and one unique owner.
    NSString *dockControllerClass=NSStringFromClass(root.class);
    if(( [dockControllerClass isEqualToString:@"DBAppDockViewController"] ||
         [dockControllerClass isEqualToString:@"CARAppDockViewController"]) &&
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
// Historical iOS16 adapter DFDashboardChrome.xm owns the native rail through
// these dedicated system windows. AppDock-only discovery dropped this route.
static BOOL DFZHistoricalChromeWindow(UIWindow *window) {
    if(!window || window.hidden || window.alpha<.95 || !window.screen)return NO;
    BOOL native=NO;
    for(NSString *name in @[@"DBStatusBarWindow",@"CARStatusBarWindow"]) {
        Class cls=NSClassFromString(name);
        if(cls && [window isKindOfClass:cls]){native=YES;break;}
    }
    CGRect screen=window.screen.bounds;
    return native && screen.size.width>=300 && screen.size.height>=145 &&
           !CGRectIsEmpty(window.bounds);
}
static BOOL DFZLocateLiveNativeDock(UIView **outView, UIWindow **outWindow,
                                    NSString **outReason) {
    UIView *found=nil;UIWindow *owner=nil;NSUInteger matches=0;
    // iOS16 system UI can retain legacy native windows outside connectedScenes.
    // Deduplicate windows before the one-owner check, or one Dock is counted twice.
    NSMutableOrderedSet<UIWindow *> *windows=[NSMutableOrderedSet orderedSet];
    // A native CarPlay Dock can remain VISIBLE when its UIWindowScene is
    // foreground-inactive: e.g. DuoFace's separate CPTemplate scene owns input.
    // The old active-only enumeration rejected that actual dock before it
    // could pass the stricter dock-class, measured-rail and unique-owner gate.
    // Background scenes must still be excluded (no global window hiding).
    NSUInteger activeScenes=0,inactiveScenes=0;
    for(UIWindow *window in UIApplication.sharedApplication.windows) {
        UIWindowScene *scene=window.windowScene;
        UISceneActivationState state=scene?scene.activationState:
                                                UISceneActivationStateUnattached;
        if(!scene || state==UISceneActivationStateForegroundActive ||
           state==UISceneActivationStateForegroundInactive)
            [windows addObject:window];
    }
    for(UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if(![scene isKindOfClass:UIWindowScene.class])continue;
        if(scene.activationState==UISceneActivationStateForegroundActive)
            activeScenes++;
        else if(scene.activationState==UISceneActivationStateForegroundInactive)
            inactiveScenes++;
        else continue;
        [windows addObjectsFromArray:((UIWindowScene *)scene).windows];
    }
    DFZLog([NSString stringWithFormat:
        @"dock-scene-inventory active=%lu foreground-inactive=%lu candidate-windows=%lu",
        (unsigned long)activeScenes,(unsigned long)inactiveScenes,
        (unsigned long)windows.count]);
    for(UIWindow *window in windows) {
            if(window.hidden || window.alpha<.95)continue;
            UIViewController *root=window.rootViewController;
            UIView *candidate=root?DFZControllerDockView(root,window,0):nil;
            if(!candidate && root)
                candidate=DFZDockClassView(root.viewIfLoaded,window,0);
            // On iOS16 the real DB Dock may be hosted directly by its
            // dedicated UIWindow without a rootViewController. Earlier
            // code discarded such windows before looking for AppDock.
            // Search only the known native Dock window class; a generic
            // SpringBoard overlay is never an acceptable owner.
            if(!candidate &&
               [NSStringFromClass(window.class) isEqualToString:@"DBDockWindow"])
                candidate=DFZDockClassView(window,window,0);
            if(!candidate &&
               [NSStringFromClass(window.class) isEqualToString:@"DBDockWindow"] &&
               DFZVisibleDockGeometry(window,window))
                candidate=window;
            if(candidate) {
                DFZLog([NSString stringWithFormat:
                    @"dock-candidate view=%@ window=%@ frame=%@ screen=%@",
                    NSStringFromClass(candidate.class),NSStringFromClass(window.class),
                    NSStringFromCGRect(candidate.frame),NSStringFromCGRect(window.screen.bounds)]);
                found=candidate;owner=window;matches++;
            }
    }
    // Only use the documented iOS16 route if no AppDock view was found.
    // A single owner is required; never hide unrelated generic windows.
    if(matches==0) {
        for(UIWindow *window in windows) {
            if(!DFZHistoricalChromeWindow(window))continue;
            found=window;owner=window;matches++;
            DFZLog([NSString stringWithFormat:@"historic-ios16-chrome-candidate class=%@ frame=%@ screen=%@",
                NSStringFromClass(window.class),NSStringFromCGRect(window.frame),
                NSStringFromCGRect(window.screen.bounds)]);
        }
    }
    if(matches!=1) {
        DFZLog([NSString stringWithFormat:@"native-dock-discovery-rejected matches=%lu windows=%lu",
                (unsigned long)matches,(unsigned long)windows.count]);
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
    if(!applied) {
        // Preserve the same-request positive ACK from the genuine system
        // AppDock owner, even when another CarPlay process lacks a Dock.
        NSDictionary *prior=[NSDictionary dictionaryWithContentsOfFile:DFZAck];
        if([prior[@"Version"] isEqual:@1] &&
           [prior[@"Session"] isEqualToString:command[@"Session"]] &&
           [prior[@"RequestID"] isEqualToString:command[@"RequestID"]] &&
           [prior[@"Sequence"] isEqual:command[@"Sequence"]] &&
           [prior[@"Applied"] isEqual:@YES] &&
           [prior[@"DockOwnerVerified"] isEqual:@YES]) {
            DFZLog(@"nonowner-reply-preserved-verified-positive");
            return;
        }
    }
    if([reply writeToFile:DFZAck atomically:YES])notify_post(DFZAckNotify);
    DFZLog([NSString stringWithFormat:@"dock-reply applied=%d expanded=%d owner=%@ reason=%@",
          applied,expanded,owner?:@"-",reason?:@"ok"]);
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
    if(!isfinite(age) || age<0 || age>3.0)return;
    // Deduplicate notification and poll of the same real request.
    NSUInteger sequence=[seq unsignedIntegerValue];
    if([session isEqualToString:DFZHandledSession] &&
       sequence<=DFZHandledSequence)return;
    DFZHandledSession=[session copy];
    DFZHandledSequence=sequence;
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
        if(!view || !window || (window.hidden && view!=window) || !window.screen) {
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
// QA120: derive an independently measured usable rect from the ACTUAL native
// CarPlay status-rail UIWindow plus its attached AppDock controller, corroborated
// by the native notification/content window. The AppDock's buttons occupy only
// ~111pt of a 360pt screen, so the old >=48%-height AppDock filter wrongly
// rejected the real 45pt native rail in QA119. This resolver is READ-ONLY to
// system windows and fails closed unless the three original owners agree.
// It never treats an arbitrary status bar or a 45pt constant as the Dock.
static NSString *const DFZNativeRailFile=
    @"/var/mobile/Library/Preferences/com.duoface.nativehost.native-rail.v1.plist";
static UIViewController *DFZFindNativeRailDockController(UIViewController *root,
                                                        NSUInteger depth) {
    if(!root || depth>9)return nil;
    NSString *name=NSStringFromClass(root.class);
    if([name isEqualToString:@"DBAppDockViewController"] ||
       [name isEqualToString:@"CARAppDockViewController"])return root;
    for(UIViewController *child in root.childViewControllers) {
        UIViewController *found=DFZFindNativeRailDockController(child,depth+1);
        if(found)return found;
    }
    return nil;
}
static NSDictionary *DFZVerifiedRailForPulse(NSDictionary *pulse,
                                            NSArray<UIWindow *> *windows) {
    if(!DFGFresh(pulse,NSDate.date.timeIntervalSince1970))return nil;
    if(![NSProcessInfo.processInfo.processName isEqualToString:@"CarPlay"])return nil;
    NSMutableArray<NSDictionary *> *accepted=[NSMutableArray new];
    for(UIWindow *railWindow in windows) {
        if(![NSStringFromClass(railWindow.class) isEqualToString:@"DBStatusBarWindow"] &&
           ![NSStringFromClass(railWindow.class) isEqualToString:@"CARStatusBarWindow"])continue;
        if(railWindow.hidden || railWindow.alpha<.95 || !railWindow.screen ||
           railWindow.screen==UIScreen.mainScreen)continue;
        UIWindowScene *ownerScene=railWindow.windowScene;
        if(![ownerScene.session.role isEqualToString:UIWindowSceneSessionRoleCarPlay] ||
           ownerScene.activationState==UISceneActivationStateBackground)continue;
        UIViewController *root=railWindow.rootViewController;
        if(!root || ![NSStringFromClass(root.class)
                       isEqualToString:@"DBRootStatusBarViewController"])continue;
        UIViewController *appDock=DFZFindNativeRailDockController(root,0);
        UIView *dock=appDock.viewIfLoaded;
        if(!dock || dock.hidden || dock.alpha<.9 || !dock.userInteractionEnabled ||
           ![dock isDescendantOfView:railWindow])continue;
        CGRect full=railWindow.screen.bounds;
        CGRect rail=[railWindow convertRect:railWindow.bounds
                         toCoordinateSpace:railWindow.screen.coordinateSpace];
        CGRect dockRect=[dock convertRect:dock.bounds
                         toCoordinateSpace:railWindow.screen.coordinateSpace];
        if(!isfinite(rail.origin.x)||!isfinite(rail.size.width)||
           !isfinite(rail.size.height)||!isfinite(dockRect.size.height)||
           full.size.width<300 || full.size.height<145 || rail.size.width<20 ||
           rail.size.width>=full.size.width*.3 ||
           fabs(CGRectGetMinX(rail)-CGRectGetMinX(full))>1.5 ||
           fabs(CGRectGetMinY(rail)-CGRectGetMinY(full))>1.5 ||
           fabs(rail.size.height-full.size.height)>1.5 ||
           CGRectIsEmpty(dockRect) ||
           CGRectGetMinX(dockRect)<CGRectGetMinX(rail)-1.5 ||
           CGRectGetMaxX(dockRect)>CGRectGetMaxX(rail)+1.5 ||
           CGRectGetMinY(dockRect)<CGRectGetMinY(rail)-1.5 ||
           CGRectGetMaxY(dockRect)>CGRectGetMaxY(rail)+1.5)continue;
        // Require the independently owned native content boundary to agree
        // with the measured rail edge. No guessed pixel/percentage offsets.
        NSUInteger matchingContent=0;
        UIWindow *contentWindow=nil;
        CGRect content=CGRectZero;
        for(UIWindow *candidate in windows) {
            if(![NSStringFromClass(candidate.class) isEqualToString:@"DBNotificationWindow"] ||
               candidate.hidden || candidate.alpha<.9 ||
               candidate.screen!=railWindow.screen || !candidate.windowScene ||
               ![candidate.windowScene.session.role
                    isEqualToString:UIWindowSceneSessionRoleCarPlay])continue;
            CGRect frame=[candidate convertRect:candidate.bounds
                             toCoordinateSpace:candidate.screen.coordinateSpace];
            if(fabs(CGRectGetMinX(frame)-CGRectGetMaxX(rail))<=1.5 &&
               fabs(CGRectGetMaxX(frame)-CGRectGetMaxX(full))<=1.5 &&
               fabs(frame.origin.y-full.origin.y)<=1.5 &&
               fabs(frame.size.height-full.size.height)<=1.5) {
                matchingContent++;contentWindow=candidate;content=frame;
            }
        }
        if(matchingContent!=1 || !contentWindow)continue;
        [accepted addObject:@{@"Version":@1,@"Session":pulse[@"Session"],
           @"Sample":pulse[@"GeometrySample"],@"Timestamp":@(NSDate.date.timeIntervalSince1970),
           @"OwnerProcess":@"CarPlay",@"Status":@"verified-native-rail",
           @"ScreenBounds":NSStringFromCGRect(full),
           @"ScreenScale":@(railWindow.screen.scale),
           @"RailFrameInScreen":NSStringFromCGRect(rail),
           @"ContentFrameInScreen":NSStringFromCGRect(content),
           @"DockViewFrameInScreen":NSStringFromCGRect(dockRect),
           @"RailOwnerClass":NSStringFromClass(railWindow.class),
           @"RootControllerClass":NSStringFromClass(root.class),
           @"DockControllerClass":NSStringFromClass(appDock.class),
           @"ContentWindowClass":NSStringFromClass(contentWindow.class)}];
    }
    return accepted.count==1?accepted.firstObject:nil;
}
// Diagnostics only; the measured rectangles are NEVER passed to layout/Zoom.
static void DFZGeometry119(void) {
    NSDictionary *pulse=[NSDictionary dictionaryWithContentsOfFile:DFZSession];
    static NSString *lastSample;
    if(!DFGFresh(pulse,NSDate.date.timeIntervalSince1970) ||
       [lastSample isEqual:pulse[@"GeometrySample"]])return;
    lastSample=[pulse[@"GeometrySample"] copy];
    NSMutableOrderedSet<UIWindow *> *all=[NSMutableOrderedSet orderedSetWithArray:UIApplication.sharedApplication.windows];
    for(UIScene *scene in UIApplication.sharedApplication.connectedScenes)
        if([scene isKindOfClass:UIWindowScene.class])
            [all addObjectsFromArray:((UIWindowScene *)scene).windows];
    NSMutableArray *windows=[NSMutableArray new],*docks=[NSMutableArray new];
    for(UIWindow *w in all){
        if(windows.count>=48)break;
        NSMutableDictionary *item=[DFGWindow(w) mutableCopy];
        // rootWindow is optional and may be a vendor wrapper in the original.
        // Do not equate ordinary CPWindow with the original native root owner.
        id root=DFGObject(w,@"rootWindow");
        item[@"RootWindowGetterStatus"]=[root isKindOfClass:UIWindow.class]?@"observed":@"unresolved";
        if([root isKindOfClass:UIWindow.class])item[@"RootWindow"]=DFGWindow(root);
        [windows addObject:item];
        UIView *dock=DFZControllerDockView(w.rootViewController,w,0);
        if(!dock)dock=DFZDockClassView(w,w,0);
        if(!dock && [NSStringFromClass(w.class) isEqual:@"DBDockWindow"] &&
           DFZVisibleDockGeometry(w,w))dock=w;
        if(dock){
            CGRect rect=[dock convertRect:dock.bounds toCoordinateSpace:w.screen.coordinateSpace];
            [docks addObject:@{@"ViewClass":NSStringFromClass(dock.class),
                @"FrameInScreen":NSStringFromCGRect(rect),@"OwnerWindow":DFGWindow(w)}];
        }
    }
    // Do not accept the historical statusbar fallback as a measured AppDock.
    NSMutableArray *activeRoots=[NSMutableArray new];
    for(id source in @[UIApplication.sharedApplication,(id)UIApplication.sharedApplication.delegate?:NSNull.null]){
        id active=DFGObject(source,@"activeCarPlayWindow");
        id root=DFGObject(active,@"rootWindow");
        if([root isKindOfClass:UIWindow.class])
            [activeRoots addObject:@{@"GetterOwner":NSStringFromClass([source class]),@"RootWindow":DFGWindow(root)}];
    }
    DFGWrite(pulse,@{@"NativeWindows":windows,@"DockCandidates":docks,
        @"ActiveCarPlayRootCandidates":activeRoots,
        @"OriginalRootOwnerStatus":activeRoots.count==1?@"getter-observed-not-yet-crosschecked":@"unresolved",
        @"InventoryTruncated":@(all.count>48),@"LayoutChanged":@NO});
    // A verified native rail belongs to exactly this fresh CarPlay session.
    // Publishing is atomic; a missing/unverified source leaves the .118 Dock
    // fallback unchanged. This probe never changes native UIWindow geometry.
    NSDictionary *nativeRail=DFZVerifiedRailForPulse(pulse,all.array);
    if(nativeRail) {
        BOOL saved=[nativeRail writeToFile:DFZNativeRailFile atomically:YES];
        DFZLog([NSString stringWithFormat:
           @"qa120-native-rail-owner %@ rail=%@ content=%@ appDock=%@",
           saved?@"published":@"write-failed",
           nativeRail[@"RailFrameInScreen"],nativeRail[@"ContentFrameInScreen"],
           nativeRail[@"DockViewFrameInScreen"]]);
    } else if([NSProcessInfo.processInfo.processName isEqualToString:@"CarPlay"]) {
        DFZLog(@"qa120-native-rail-owner-unresolved-no-geometry-change");
    }
}
static void DFZWatch(NSUInteger generation) {
    if(generation!=DFZGeneration || !DFZCarPlayProcess())return;
    // Unlike before, recover a missed Darwin command edge by re-reading only
    // the validated, fresh Session/RequestID/Sequence request record.
    DFZHandleCommand();
    DFZGeometry119();
    if(DFZDockView) {
        if(!DFZOwnerSession || !DFZFreshSession(DFZOwnerSession) ||
           !DFZWindow || (DFZWindow.hidden && DFZDockView!=DFZWindow) || !DFZWindow.screen) {
            DFZRestore();
        }
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(.5*NSEC_PER_SEC)),
                   dispatch_get_main_queue(),^{ DFZWatch(generation); });
}
// Original OmniCar 1.0.3 native map pipeline uses CarPlayApp scene ownership.
// Reuse the independently built V7 read-only iOS16 Dashboard controller/FBScene
// observer in this SINGLE DuoFace package. Never steal/clone/reparent Maps CPWindow.
extern void DFIntegratedCarPlayCaptureLiveOwnerSnapshot(NSString *probeSession);
static void DFZMapSceneWatch(NSUInteger generation) {
    if(generation!=DFZGeneration || !DFZCarPlayProcess())return;
    if([NSProcessInfo.processInfo.processName isEqualToString:@"CarPlayApp"])
        DFIntegratedCarPlayCaptureLiveOwnerSnapshot(@"duoface-integrated-native-map-owner-v8");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(8.0*NSEC_PER_SEC)),
                   dispatch_get_main_queue(),^{ DFZMapSceneWatch(generation); });
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
                DFZLog([NSString stringWithFormat:@"listener-ready process=%@",
                      NSProcessInfo.processInfo.processName]);
                DFZWatch(++DFZGeneration);
                // Eight-second native owner samples distinguish Google Maps
                // current FBScene from DuoFace after Dashboard foreground swap.
                // An absent controller does NOT prove Maps' scene was destroyed.
                DFZMapSceneWatch(DFZGeneration);
            }
        });
    }
}
