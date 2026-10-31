// Included only by DFCarPlayDockOwner.m, inside the existing CarPlay receiver.
// Independent implementation from the original's verified Home event semantics.
#import "DFCarPlayOwnerLease.h"
#import "DFHome145Consent.h"
#import "DFCarPlayOwnerSelection.h"
#import <dlfcn.h>
#import <string.h>
static void (*DFOwnerDBHomeOriginal)(id,SEL,id);
static void (*DFOwnerCARHomeOriginal)(id,SEL,id);
static BOOL DFOwnerHomeHooksReady;
static NSString *DFOwnerBoundSession,*DFOwnerBoundHostScene,*DFOwnerBoundNativeScene;
static NSString *DFOwnerRevokedSession;
static __weak UIViewController *DFOwnerBoundController;
static void DFOwnerDBHome(id object,SEL sel,id event);
static void DFOwnerCARHome(id object,SEL sel,id event);
// All present original-listed Home classes must have a verified live replacement.
static BOOL DFOwnerHomeCoverage(void) {
    BOOL found=NO;
    for(NSString *name in @[@"DBRootStatusBarViewController",@"CARRootStatusBarViewController"]) {
        Class cls=NSClassFromString(name);if(!cls)continue;
        found=YES;
        IMP imp=class_getMethodImplementation(cls,NSSelectorFromString(@"homeButtonUp:"));
        if(imp!=(IMP)DFOwnerDBHome && imp!=(IMP)DFOwnerCARHome)return NO;
    }
    return found;
}

static BOOL DFOwnerBool(id object, NSString *name) {
    if(!object)return NO;
    SEL sel=NSSelectorFromString(name);
    Method m=class_getInstanceMethod(object_getClass(object),sel);
    if(!m || method_getNumberOfArguments(m)!=2)return NO;
    char type[16]={0};method_getReturnType(m,type,sizeof(type));
    if(type[0]!='B' && type[0]!='c')return NO;
    @try {return ((BOOL(*)(id,SEL))objc_msgSend)(object,sel);}
    @catch(NSException *e){(void)e;return NO;}
}
static BOOL DFOwnerVisibleController(UIViewController *vc) {
    UIView *view=vc.viewIfLoaded;UIWindow *window=view.window;
    if(!view || !window || view.hidden || view.alpha<.95 || window.hidden ||
       window.alpha<.95 || !window.screen || CGRectIsEmpty(view.bounds))return NO;
    // Every ancestor must actually be visible; a cached offscreen host is not owner.
    for(UIView *v=view;v;v=v.superview)if(v.hidden || v.alpha<.95)return NO;
    CGRect r=[view convertRect:view.bounds toCoordinateSpace:window.screen.coordinateSpace];
    return window.screen.bounds.size.width>=300 && window.screen.bounds.size.height>=145 &&
           !CGRectIsEmpty(CGRectIntersection(r,window.screen.bounds));
}
static void DFOwnerCollect(UIViewController *vc, NSUInteger depth,
                            NSMutableArray<NSDictionary *> *found,
                            NSMutableSet<NSValue *> *seen) {
    if(!vc || depth>12)return;
    NSValue *identity=[NSValue valueWithNonretainedObject:vc];
    if([seen containsObject:identity])return;
    [seen addObject:identity];
    if([NSStringFromClass(vc.class) isEqual:@"DBApplicationSceneViewController"] &&
       DFOwnerVisibleController(vc)) {
        id info=DFGObject(vc,@"applicationInfo")?:DFGObject(vc,@"proxyApplicationInfo");
        id bundle=DFGObject(info,@"bundleIdentifier");
        id scene=DFGObject(vc,@"scene");
        if(!scene)scene=DFGObject(DFGObject(vc,@"sceneHandle"),@"sceneIfExists");
        id nativeID=DFGObject(scene,@"identifier");
        BOOL foreground=DFOwnerBool(DFGObject(scene,@"settings"),@"isForeground");
        if(foreground && [bundle isKindOfClass:NSString.class] &&
           [nativeID isKindOfClass:NSString.class] && [nativeID length]>0)
            [found addObject:@{@"Controller":vc,@"Bundle":bundle,@"SceneID":nativeID}];
    }
    for(UIViewController *child in vc.childViewControllers)
        DFOwnerCollect(child,depth+1,found,seen);
    if(vc.presentedViewController)
        DFOwnerCollect(vc.presentedViewController,depth+1,found,seen);
}
static void DFOwnerObserveNative(void) {
    // One writer, the actual CarPlay UI process; CarPlayApp cannot attest for it.
    if(![NSProcessInfo.processInfo.processName isEqual:@"CarPlay"])return;
    DFOwnerHomeHooksReady=DFOwnerHomeCoverage();
    NSDictionary *pulse=[NSDictionary dictionaryWithContentsOfFile:DFZSession];
    NSString *session=pulse[@"Session"],*hostID=pulse[@"HostSceneID"];
    id stamp=pulse[@"Timestamp"];
    if(!DFOwnerValidSession(session) || ![pulse[@"Active"] isEqual:@YES] ||
       ![stamp isKindOfClass:NSNumber.class] ||
       !isfinite([stamp doubleValue]) ||
       NSDate.date.timeIntervalSince1970<[stamp doubleValue])return;
    NSMutableArray *found=[NSMutableArray new];NSMutableSet *seen=[NSMutableSet new];
    NSMutableOrderedSet<UIWindow *> *windows=[NSMutableOrderedSet orderedSetWithArray:UIApplication.sharedApplication.windows];
    for(UIScene *scene in UIApplication.sharedApplication.connectedScenes)
        if([scene isKindOfClass:UIWindowScene.class])
            [windows addObjectsFromArray:((UIWindowScene *)scene).windows];
    for(UIWindow *window in windows)DFOwnerCollect(window.rootViewController,0,found,seen);
    // Apple can show additional genuine CarPlay app scenes while DuoFace hosts
    // an iPhone scene. Their presence does not revoke DuoFace ownership.
    // More than one visible DuoFace controller still fails closed.
    NSDictionary *candidate=DFOwnerUniqueDuoFaceCandidate(found);
    BOOL sameSession=[session isEqual:DFOwnerBoundSession];
    if(!sameSession) {
        DFOwnerBoundSession=nil;DFOwnerBoundHostScene=nil;
        DFOwnerBoundNativeScene=nil;DFOwnerBoundController=nil;
        // A background app pulse must NEVER acquire or change native ownership.
        if(DFOwnerFreshTime(NSDate.date.timeIntervalSince1970,[stamp doubleValue],2.5) &&
           ![pulse[@"HostBackground"] isEqual:@YES] && DFOwnerHomeHooksReady &&
           !DFOwnerSessionRevoked(session) && [hostID isKindOfClass:NSString.class] && hostID.length &&
           [candidate[@"Bundle"] isEqual:@"com.duoface.native.scenehost"]) {
            DFOwnerBoundSession=[session copy];DFOwnerBoundHostScene=[hostID copy];
            DFOwnerBoundNativeScene=[candidate[@"SceneID"] copy];
            DFOwnerBoundController=candidate[@"Controller"];
        }
    }
    BOOL active=DFOwnerHomeHooksReady && [session isEqual:DFOwnerBoundSession] &&
        ![session isEqual:DFOwnerRevokedSession] && !DFOwnerSessionRevoked(session) &&
        [hostID isEqual:DFOwnerBoundHostScene] &&
        [candidate[@"Bundle"] isEqual:@"com.duoface.native.scenehost"] &&
        [candidate[@"SceneID"] isEqual:DFOwnerBoundNativeScene] &&
        candidate[@"Controller"]==DFOwnerBoundController;
    NSDictionary *record=@{@"Version":@1,@"Session":session,@"HostSceneID":hostID?:@"",
        @"Active":@(active),@"HomeHookReady":@(DFOwnerHomeHooksReady),
        @"Process":@"CarPlay",@"Bundle":candidate[@"Bundle"]?:@"",
        @"NativeSceneID":candidate[@"SceneID"]?:@"",
        @"Timestamp":@(NSDate.date.timeIntervalSince1970)};
    if(![record writeToFile:DFOwnerEvidencePath atomically:YES])
        DFZLog(@"native-owner-evidence-write-failed");
    static NSString *lastState;
    NSString *state=[NSString stringWithFormat:@"%@:%d:%lu:%d",session,active,(unsigned long)found.count,candidate!=nil];
    if(![state isEqual:lastState]) {
        lastState=state;
        DFZLog([NSString stringWithFormat:@"native-owner-state session=%@ active=%d visible-candidates=%lu unique-duoface=%d hooks=%d",
              session,active,(unsigned long)found.count,candidate!=nil,DFOwnerHomeHooksReady]);
    }
}
static void DFOwnerHomeReceived(id receiver) {
    if(!NSThread.isMainThread || ![receiver isKindOfClass:UIViewController.class])return;
    // Require the actual native statusbar receiver/window, including zoom-hidden rail.
    UIView *view=[(UIViewController *)receiver viewIfLoaded];
    UIWindow *window=view.window;
    if(!window.screen || window.screen.bounds.size.width<300)return;
    // QA146: the separate Home-owned app has NO DuoFace CPTemplate session.
    // Actual QA145 Log22: native homeButtonUp: hook ready=1, but Home-return
    // viewDidAppear hook home=0. Revoke only the independent SpringBoard owner
    // on a real external native CarPlay Home press, BEFORE the old session gate.
    // Never consume the Apple Home event; the original handler runs exactly once.
    BOOL nativeRail=([receiver isKindOfClass:NSClassFromString(@"DBRootStatusBarViewController")] ||
                     [receiver isKindOfClass:NSClassFromString(@"CARRootStatusBarViewController")]);
    BOOL carScreen=window.screen!=UIScreen.mainScreen &&
                   [window.windowScene.session.role isEqualToString:@"UIWindowSceneSessionRoleCarPlay"];
    BOOL soloConsent=DFHome145Enabled();
    if(nativeRail && carScreen && soloConsent) {
        int status=notify_post("com.duoface.nativehost.standalone144.stop");
        DFZLog([NSString stringWithFormat:@"native-home-standalone-stop qa146 status=%d independent-from-duoface-session=1",status]);
    }
    NSDictionary *pulse=[NSDictionary dictionaryWithContentsOfFile:DFZSession];
    NSString *session=pulse[@"Session"];
    id stamp=pulse[@"Timestamp"];
    if(!DFOwnerValidSession(session) || ![pulse[@"Version"] isEqual:@1] ||
       ![pulse[@"Active"] isEqual:@YES] || ![stamp isKindOfClass:NSNumber.class] ||
       (!DFOwnerFreshTime(NSDate.date.timeIntervalSince1970,[stamp doubleValue],2.5) &&
        !DFOwnerAcceptPulse(pulse)))return;
    DFOwnerRevokedSession=[session copy];
    NSDictionary *revoke=@{@"Version":@1,@"Session":session,@"Revoked":@YES,
        @"Reason":@"native-home-button",@"Timestamp":@(NSDate.date.timeIntervalSince1970)};
    BOOL saved=[revoke writeToFile:DFOwnerRevokePath atomically:YES];
    DFZRestore();
    if(saved)notify_post(DFOwnerRevokeNotify);
    // A failed write still blocks this system process from renewing its attestation.
    DFZLog([NSString stringWithFormat:@"native-home-revoke session=%@ saved=%d",session,saved]);
}
static void DFOwnerDBHome(id object,SEL sel,id event) {
    @try {DFOwnerHomeReceived(object);} @catch(NSException *e){DFZLog(e.name);}
    DFOwnerDBHomeOriginal(object,sel,event);
}
static void DFOwnerCARHome(id object,SEL sel,id event) {
    @try {DFOwnerHomeReceived(object);} @catch(NSException *e){DFZLog(e.name);}
    DFOwnerCARHomeOriginal(object,sel,event);
}
static BOOL DFOwnerInstallHome(Class cls, IMP replacement, IMP *original) {
    SEL sel=NSSelectorFromString(@"homeButtonUp:");
    Method m=cls?class_getInstanceMethod(cls,sel):NULL;
    char type[32]={0};
    if(!m || method_getNumberOfArguments(m)!=3)return NO;
    method_getReturnType(m,type,sizeof(type));if(strcmp(type,"v"))return NO;
    method_getArgumentType(m,2,type,sizeof(type));if(type[0]!='@')return NO;
    IMP before=method_getImplementation(m);
    if(before==(IMP)DFOwnerDBHome || before==(IMP)DFOwnerCARHome)return NO;
    void (*hook)(Class,SEL,IMP,IMP*)=dlsym(RTLD_DEFAULT,"MSHookMessageEx");
    if(!hook)return NO;
    hook(cls,sel,replacement,original);
    return *original!=NULL && class_getMethodImplementation(cls,sel)==replacement;
}
static void DFOwnerInstallHomeHooks(void) {
    if(![NSProcessInfo.processInfo.processName isEqual:@"CarPlay"])return;
    BOOL db=DFOwnerInstallHome(NSClassFromString(@"DBRootStatusBarViewController"),
        (IMP)DFOwnerDBHome,(IMP *)&DFOwnerDBHomeOriginal);
    BOOL car=DFOwnerInstallHome(NSClassFromString(@"CARRootStatusBarViewController"),
        (IMP)DFOwnerCARHome,(IMP *)&DFOwnerCARHomeOriginal);
    DFOwnerHomeHooksReady=DFOwnerHomeCoverage();
    DFZLog([NSString stringWithFormat:@"native-home-hook-abi db=%d car=%d ready=%d",db,car,DFOwnerHomeHooksReady]);
}
