// Included only by DFCarPlayDockOwner.m, inside the existing CarPlay receiver.
// Independent implementation from the original's verified Home event semantics.
#import "DFCarPlayOwnerLease.h"
#import "DFCarPlayOwnerSelection.h"
#import "../native-carplay-scene-v1/DFNativeMapOwnedBasePolicy.h"
#import <dlfcn.h>
#import <string.h>
extern void DF157NativeHomeCallbackObserved(void);
extern void DF160NativeHomeTrace(NSString *stage,id receiver);
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

// First-party in-process readiness for the bounded native-map launch context.
// This only inspects the existing replacements; it never installs a hook.
BOOL DFNativeMapHomeHooksReadyV1(void) {
    return NSThread.isMainThread &&
        [NSProcessInfo.processInfo.processName isEqualToString:@"CarPlay"] &&
        DFOwnerHomeCoverage();
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

static NSDictionary *DFNativeMapFinishBaseEvidence(NSDictionary *result,NSDictionary *originalPulse,
                                                  NSString **reason) {
    NSDictionary *latest=[NSDictionary dictionaryWithContentsOfFile:DFZSession];
    NSString *session=latest[@"Session"];
    BOOL revoked=DFOwnerSessionRevoked(session) || [session isEqual:DFOwnerRevokedSession];
    NSString *fresh=DFNativeMapFreshLaunchSession(latest,revoked,
                                                 NSDate.date.timeIntervalSince1970);
    if(!fresh || !DFOwnerAcceptPulse(latest) ||
       ![fresh isEqual:originalPulse[@"Session"]] ||
       ![latest[@"HostSceneID"] isEqual:originalPulse[@"HostSceneID"]]) {
        if(reason)*reason=@"native-launch-physical-session-changed-during-read";return nil;
    }
    return result;
}
NSDictionary *DFNativeMapReadOwnedBaseEvidenceV1(id expectedRoot,id expectedWindow,
                                               NSString **reason) {
    if(reason)*reason=nil;
    if(!DFNativeMapHomeHooksReadyV1() ||
       ![expectedRoot isKindOfClass:UIViewController.class] ||
       ![expectedWindow isKindOfClass:UIWindow.class]) {
        if(reason)*reason=@"native-launch-owner-context-unverified";return nil;
    }
    NSDictionary *pulse=[NSDictionary dictionaryWithContentsOfFile:DFZSession];
    NSString *session=pulse[@"Session"];
    BOOL revoked=DFOwnerSessionRevoked(session) || [session isEqual:DFOwnerRevokedSession];
    NSString *fresh=DFNativeMapFreshLaunchSession(pulse,revoked,
                                                 NSDate.date.timeIntervalSince1970);
    if(!fresh || !DFOwnerAcceptPulse(pulse)) {
        if(reason)*reason=@"native-launch-physical-session-inactive-stale-or-revoked";return nil;
    }
    // The stable session remains observable after launch even when a new
    // native map replaces currentBase. Missing own-base evidence only denies
    // a new owned-base dispatch; it does not fabricate a live owner.
    NSMutableDictionary *result=[@{@"PhysicalSession":fresh} mutableCopy];
    UIViewController *boundController=DFOwnerBoundController;
    if(!boundController)return DFNativeMapFinishBaseEvidence(result,pulse,reason);
    NSDictionary *bound=@{@"Session":DFOwnerBoundSession?:@"",
        @"HostSceneID":DFOwnerBoundHostScene?:@"",
        @"NativeSceneID":DFOwnerBoundNativeScene?:@"",
        @"Controller":boundController};
    NSMutableArray *found=[NSMutableArray new];NSMutableSet *seen=[NSMutableSet new];
    NSMutableOrderedSet<UIWindow *> *windows=[NSMutableOrderedSet orderedSetWithArray:UIApplication.sharedApplication.windows];
    for(UIScene *scene in UIApplication.sharedApplication.connectedScenes)
        if([scene isKindOfClass:UIWindowScene.class])
            [windows addObjectsFromArray:((UIWindowScene *)scene).windows];
    for(UIWindow *window in windows)DFOwnerCollect(window.rootViewController,0,found,seen);
    NSDictionary *candidate=DFOwnerUniqueDuoFaceCandidate(found);
    if(!DFNativeMapOwnedBaseRecordMatches(pulse,bound,candidate,revoked,
                                          NSDate.date.timeIntervalSince1970))
        return DFNativeMapFinishBaseEvidence(result,pulse,reason);
    UIViewController *root=expectedRoot;UIWindow *window=expectedWindow;
    UIViewController *controller=candidate[@"Controller"];
    if(![NSStringFromClass(controller.class) isEqual:@"DBApplicationSceneViewController"] ||
       controller.viewIfLoaded.window!=window || root.viewIfLoaded.window!=window ||
       window.rootViewController!=root || !window.screen ||
       window.screen==UIScreen.mainScreen || !window.windowScene ||
       window.windowScene.screen!=window.screen ||
       ![window.windowScene.session.role isEqual:@"UIWindowSceneSessionRoleCarPlay"] ||
       DFGObject(root,@"currentBaseViewController")!=controller)
        return DFNativeMapFinishBaseEvidence(result,pulse,reason);
    id scene=DFGObject(controller,@"scene");
    if(!scene)scene=DFGObject(DFGObject(controller,@"sceneHandle"),@"sceneIfExists");
    if(![NSStringFromClass([scene class]) isEqual:@"FBScene"] ||
       ![DFGObject(scene,@"identifier") isEqual:bound[@"NativeSceneID"]])
        return DFNativeMapFinishBaseEvidence(result,pulse,reason);
    BOOL related=NO;
    NSMutableSet<NSValue *> *ancestry=[NSMutableSet new];
    for(UIViewController *cursor=controller;cursor && ancestry.count<32;cursor=cursor.parentViewController) {
        NSValue *identity=[NSValue valueWithNonretainedObject:cursor];
        if([ancestry containsObject:identity])break;
        [ancestry addObject:identity];
        if(cursor==root){related=YES;break;}
    }
    if(!related)return DFNativeMapFinishBaseEvidence(result,pulse,reason);
    // Read the pulse/revocation again after private getters. This helper only
    // observes existing ownership; it never calls DFOwnerObserveNative or
    // writes an Active flag, bound pointer, lease or attestation file.
    NSDictionary *latest=[NSDictionary dictionaryWithContentsOfFile:DFZSession];
    BOOL latestRevoked=DFOwnerSessionRevoked(session) || [session isEqual:DFOwnerRevokedSession];
    if(!DFNativeMapOwnedBaseRecordMatches(latest,bound,candidate,latestRevoked,
                                          NSDate.date.timeIntervalSince1970) ||
       controller!=DFOwnerBoundController ||
       ![bound[@"Session"] isEqual:DFOwnerBoundSession] ||
       ![bound[@"HostSceneID"] isEqual:DFOwnerBoundHostScene] ||
       ![bound[@"NativeSceneID"] isEqual:DFOwnerBoundNativeScene])
        return DFNativeMapFinishBaseEvidence(result,pulse,reason);
    result[@"OwnedBase"]=controller;
    return DFNativeMapFinishBaseEvidence(result,pulse,reason);
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
    // QA145 physical Log22: independent Home scene is hosted by SpringBoard,
    // not a DuoFace CPTemplate session. The original gate below could only
    // revoke a fresh *DuoFace* session, leaving the standalone window over Home.
    // This callback is the existing verified native statusbar homeButtonUp: ABI
    // (Log22 db=1 ready=1); stop ONLY our separate standalone owner, then keep
    // the old native Home handling and original callback unchanged.
    // Native Home hook lives in DFCarPlayDockOwner.m, while the SOLO/Dock
    // manager is in DFHomeStandalone144.m: cross a link-visible C function,
    // NEVER refer to other translation unit's file-static objects.
    DF157NativeHomeCallbackObserved();
    int soloStop=notify_post("com.duoface.nativehost.standalone144.stop");
    DFZLog([NSString stringWithFormat:
       @"qa146-native-home-standalone-stop-notified status=%d",soloStop]);
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
    DF160NativeHomeTrace(@"before-Apple-Home",object);
    @try {DFOwnerHomeReceived(object);} @catch(NSException *e){DFZLog(e.name);}
    DFOwnerDBHomeOriginal(object,sel,event);
    DF160NativeHomeTrace(@"after-Apple-Home",object);
    __weak id weakReceiver=object;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.20*NSEC_PER_SEC)),
       dispatch_get_main_queue(),^{id live=weakReceiver;if(live)DF160NativeHomeTrace(@"plus-200ms",live);});
}
static void DFOwnerCARHome(id object,SEL sel,id event) {
    DF160NativeHomeTrace(@"before-Apple-Home",object);
    @try {DFOwnerHomeReceived(object);} @catch(NSException *e){DFZLog(e.name);}
    DFOwnerCARHomeOriginal(object,sel,event);
    DF160NativeHomeTrace(@"after-Apple-Home",object);
    __weak id weakReceiver=object;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.20*NSEC_PER_SEC)),
       dispatch_get_main_queue(),^{id live=weakReceiver;if(live)DF160NativeHomeTrace(@"plus-200ms",live);});
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
