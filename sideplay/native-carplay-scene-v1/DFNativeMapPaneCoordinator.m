// DuoFace independent user-initiated native CarPlay Maps split experiment.
// Runs ONLY in CarPlay/CarPlayApp process; never writes vendor state,
// creates foreign CPWindow, calls FBS foreground/background or modifies Dock.
// Unlike a static observer this has a real, explicitly opted-in UIKit
// controller attach path, guarded by the already compiled adapter.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <notify.h>
#import <math.h>
#import <fcntl.h>
#import <unistd.h>
#import "DFNativeMapPaneAdapter.h"
#import "DFNativeMapCatalog.h"
#import "DFNativeMapCommandProtocol.h"
#import "DFNativeMapLaunchPolicy.h"
#import "DFNativeMapLaunchRuntime.h"
#import "DFCarPlayNativeMapViewportPlan.h"
#import "DFCarPlayPhysicalPaneBinding.h"
#import "../duoface-native-scene-host/DFNativeMapLeasePolicy.h"
#import "../duoface-native-scene-host/DFCarPlayOwnerLease.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>

static NSString *const DFMapCommandPath=@"/var/mobile/Library/Preferences/com.duoface.nativehost.map-pane.command.v1.plist";
static NSString *const DFMapAckPath=@"/var/mobile/Library/Preferences/com.duoface.nativehost.map-pane.ack.v1.plist";
static NSString *const DFMapOwnerLog=@"/var/mobile/Library/Logs/DuoFaceNativeMapPane.log";
static const char *const DFMapAckNotify="com.duoface.nativehost.map-pane.ack.v1";
static BOOL DFMapProcess(void) {
    NSString *p=NSProcessInfo.processInfo.processName;
    return [p isEqual:@"CarPlay"] || [p isEqual:@"CarPlayApp"];
}
static void DFMapLog(NSString *line) {
    NSString *text=[NSString stringWithFormat:@"[DuoFaceMapPane] %@\n",line?:@""];
    NSLog(@"%@",text);
    int fd=open(DFMapOwnerLog.fileSystemRepresentation,O_CREAT|O_WRONLY|O_APPEND,0644);
    if(fd>=0) {
        NSData *bytes=[text dataUsingEncoding:NSUTF8StringEncoding];
        (void)write(fd,bytes.bytes,bytes.length);close(fd);
    }
}
// Same verified bundle whitelist as DFNativeMapPaneAdapter's FBScene check.
static id DFMapReadObject(id owner,NSString *key) {
 if(!owner)return nil;
 SEL sel=NSSelectorFromString(key);
 Method m=class_getInstanceMethod(object_getClass(owner),sel);
 if(!m || method_getNumberOfArguments(m)!=2)return nil;
 char t[8]={0}; method_getReturnType(m,t,sizeof(t));
 if(t[0]!='@')return nil;
 @try{return ((id(*)(id,SEL))objc_msgSend)(owner,sel);}
 @catch(__unused NSException *e){return nil;}
}
static NSString *DFMapVerifiedBundle(UIViewController *owner){
 id info=DFMapReadObject(owner,@"applicationInfo");
 if(!info)info=DFMapReadObject(owner,@"proxyApplicationInfo");
 id bundle=DFMapReadObject(info,@"bundleIdentifier");
 return DFNativeMapAllowedBundle(bundle)?bundle:nil;
}
static BOOL DFMapUUID(id value) {
    return [value isKindOfClass:NSString.class] &&
           [[NSUUID alloc] initWithUUIDString:value]!=nil;
}
static UIViewController *DFMapFindVC(UIViewController *root,NSUInteger depth,
                                    NSMutableSet<NSValue *> *seen,
                                    NSMutableArray<UIViewController *> *owners) {
    if(!root || depth>12)return nil;
    NSValue *key=[NSValue valueWithNonretainedObject:root];
    if([seen containsObject:key])return nil;
    [seen addObject:key];
    if([NSStringFromClass(root.class) isEqual:@"DBApplicationSceneViewController"]) {
        [owners addObject:root];
    }
    for(UIViewController *child in root.childViewControllers)
       DFMapFindVC(child,depth+1,seen,owners);
    if(root.presentedViewController)
       DFMapFindVC(root.presentedViewController,depth+1,seen,owners);
    return root;
}
static BOOL DFMapIsSceneLive(UIViewController *owner) {
    if(!owner || !owner.isViewLoaded || !owner.view.window ||
       ![NSStringFromClass(owner.class) isEqual:@"DBApplicationSceneViewController"])
       return NO;
    // Map scene identity and UIKit ownership are tested again inside
    // DFNativeMapPaneAdapter.preflightNativeController before any mutation.
    return YES;
}
static UIViewController *DFMapUniqueOwnerForBundle(NSArray<UIViewController *> *owners,
                                                  NSString *bundle) {
    UIViewController *matched=nil;
    for(UIViewController *candidate in owners) {
        if(![DFMapVerifiedBundle(candidate) isEqual:bundle])continue;
        if(matched)return nil; // Never guess between two owners of one app.
        matched=candidate;
    }
    return DFMapIsSceneLive(matched)?matched:nil;
}
static NSUInteger DFMapMatchingOwnerCount(NSArray<UIViewController *> *owners,
                                          NSString *bundle) {
    NSUInteger count=0;
    for(UIViewController *candidate in owners)
        if([DFMapVerifiedBundle(candidate) isEqual:bundle])count++;
    return count;
}
static NSInteger DFMapPhysicalSlot(NSDictionary *physical,NSInteger visualSlot) {
    NSInteger result=-1;
    for(NSDictionary *entry in physical[@"Windows"]) {
        if(!DFPhysicalMapValidSlotNumber(entry[@"VisualSlot"]) ||
           !DFPhysicalMapValidSlotNumber(entry[@"PhysicalSlot"]))return -1;
        if([entry[@"VisualSlot"] integerValue]!=visualSlot)continue;
        if(result>=0)return -1;
        result=[entry[@"PhysicalSlot"] integerValue];
    }
    return result;
}
static id DFMapCatalogLibraryInController(UIViewController *root,NSUInteger depth,
                                         NSMutableSet<NSValue *> *seen) {
    if(!root || depth>6 || seen.count>=128)return nil;
    NSValue *key=[NSValue valueWithNonretainedObject:root];
    if([seen containsObject:key])return nil;
    [seen addObject:key];
    id library=DFNativeMapExistingLibrary(root);
    if(library)return library;
    for(UIViewController *child in root.childViewControllers) {
        library=DFMapCatalogLibraryInController(child,depth+1,seen);
        if(library)return library;
    }
    return DFMapCatalogLibraryInController(root.presentedViewController,depth+1,seen);
}
static NSDictionary *DFMapMeasureLiveDock(UIWindow **outDashboard,
                                         UIViewController **outRoot) {
    NSMutableArray *scenes=[NSMutableArray new];
    UIWindow *dashboard=nil;
    NSUInteger dashboards=0;
    for(UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if(![scene isKindOfClass:UIWindowScene.class])continue;
        UIWindowScene *ws=(UIWindowScene *)scene;
        if(ws.screen==UIScreen.mainScreen ||
           ![ws.session.role isEqual:@"UIWindowSceneSessionRoleCarPlay"])continue;
        for(UIWindow *w in ws.windows) {
            if(!w.hidden && [NSStringFromClass(w.rootViewController.class)
                      isEqual:@"DBDashboardRootViewController"]) {
                dashboards++;dashboard=w;
            }
        }
    }
    if(dashboards!=1 || !dashboard || !dashboard.rootViewController.isViewLoaded)
        return @{@"status":@"dashboard-not-unique"};
    for(UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if(![scene isKindOfClass:UIWindowScene.class])continue;
        UIWindowScene *ws=(UIWindowScene *)scene;
        if(ws.screen!=dashboard.screen ||
           ![ws.session.role isEqual:@"UIWindowSceneSessionRoleCarPlay"])continue;
        NSMutableArray *windows=[NSMutableArray new];
        for(UIWindow *w in ws.windows) {
            if(w.screen!=dashboard.screen)continue;
            CGRect relative=CGRectNull;
            @try {relative=[dashboard convertRect:w.bounds fromWindow:w];}
            @catch(NSException *e){(void)e;}
            [windows addObject:@{
                @"windowClass":NSStringFromClass(w.class),
                @"rootController":w.rootViewController?
                    NSStringFromClass(w.rootViewController.class):@"nil",
                @"hidden":@(w.hidden),
                @"bounds":NSStringFromCGRect(w.bounds),
                @"dashboardRelativeFrame":CGRectIsNull(relative)?@"nil":
                                                   NSStringFromCGRect(relative)}];
        }
        [scenes addObject:@{
            @"sceneRole":ws.session.role?:@"nil",
            @"screenPointer":[NSString stringWithFormat:@"%p",ws.screen],
            @"windows":windows}];
    }
    NSDictionary *layout=[NSDictionary dictionaryWithContentsOfFile:
        @"/var/mobile/Library/Preferences/com.duoface.nativehost.layout.v1.plist"];
    NSDictionary *plan=DFCarPlayNativeMapViewportPlan(scenes,layout);
    if(outDashboard)*outDashboard=dashboard;
    if(outRoot)*outRoot=dashboard.rootViewController;
    return plan;
}
@interface DFMapPaneObservation : NSObject
@property(nonatomic,weak) UIWindow *dashboard;
@property(nonatomic,weak) UIViewController *root;
@property(nonatomic,weak) UIViewController *owner;
@property(nonatomic,copy) NSDictionary *plan;
@property(nonatomic,copy) NSDictionary *binding;
@property(nonatomic,copy) NSString *reason;
@property(nonatomic,assign) CGRect safe;
@property(nonatomic,assign) CGRect target;
@property(nonatomic,assign) NSInteger physicalSlot;
@property(nonatomic,assign) NSUInteger matchingOwners;
@property(nonatomic,assign) BOOL valid;
@end
@implementation DFMapPaneObservation
@end

// Original request data is copied once. The supplied context retains no
// native object: its dashboard/workspace/owner/root/window/screen are weak.
@interface DFMapPendingLaunch : NSObject
@property(nonatomic,copy) NSDictionary *command;
@property(nonatomic,copy) NSString *bundle;
@property(nonatomic,copy) NSString *session;
@property(nonatomic,copy) NSString *target;
@property(nonatomic,copy) NSDictionary *plan;
@property(nonatomic,assign) NSInteger slot;
@property(nonatomic,assign) NSInteger physicalSlot;
@property(nonatomic,assign) uint64_t generation;
@property(nonatomic,assign) uint64_t commandGeneration;
@property(nonatomic,strong) DFNativeMapLaunchContext *context;
@end
@implementation DFMapPendingLaunch
@end

@interface DFNativeMapPaneCoordinator : NSObject {
    DFNativeMapLaunchState _launchState;
}
@property(nonatomic,strong) DFNativeMapPaneAdapter *adapter;
@property(nonatomic,strong) UIView *pane;
@property(nonatomic,weak) UIWindow *dashboard;
@property(nonatomic,weak) UIViewController *owner;
@property(nonatomic,strong) NSString *request;
@property(nonatomic,strong) NSString *lastRequest;
@property(nonatomic,strong) NSTimer *poll;
@property(nonatomic,assign) NSInteger slot;
@property(nonatomic,assign) NSUInteger invalidFrameTicks;
@property(nonatomic,copy) NSString *boundSession;
@property(nonatomic,copy) NSString *boundBundle;
@property(nonatomic,copy) NSString *lastAutoSession;
@property(nonatomic,assign) NSTimeInterval lastLeaseWrite;
@property(nonatomic,assign) NSTimeInterval lastCatalogRead;
@property(nonatomic,assign) BOOL geometryVerified;
@property(nonatomic,assign) BOOL adoptionCommitted;
@property(nonatomic,strong) DFMapPendingLaunch *pendingLaunch;
@property(nonatomic,strong) NSMutableDictionary<NSString *,NSNumber *> *consumedRequests;
@property(nonatomic,assign) uint64_t commandGeneration;
@property(nonatomic,assign) BOOL adoptionInProgress;
@end
@implementation DFNativeMapPaneCoordinator
+ (instancetype)shared {
    static DFNativeMapPaneCoordinator *instance;
    static dispatch_once_t once;
    dispatch_once(&once,^{instance=[DFNativeMapPaneCoordinator new];});
    return instance;
}
- (void)refreshNativeCatalog {
    NSTimeInterval now=NSDate.date.timeIntervalSince1970;
    if(self.lastCatalogRead>0 && now>=self.lastCatalogRead &&
       now-self.lastCatalogRead<15.0)return;
    self.lastCatalogRead=now;
    UIApplication *app=UIApplication.sharedApplication;
    id library=DFNativeMapExistingLibrary(app);
    if(!library)library=DFNativeMapExistingLibrary(app.delegate);
    NSMutableSet<NSValue *> *seen=[NSMutableSet new];
    for(UIScene *scene in app.connectedScenes) {
        if(library)break;
        if(![scene isKindOfClass:UIWindowScene.class])continue;
        for(UIWindow *window in ((UIWindowScene *)scene).windows) {
            library=DFNativeMapExistingLibrary(window);
            if(!library)library=DFMapCatalogLibraryInController(window.rootViewController,0,seen);
            if(library)break;
        }
    }
    NSArray *bundles=DFNativeMapCatalogFromLibrary(library);
    if(!bundles)return; // Missing library is not proof of an empty catalogue.
    if([DFNativeMapCatalogBundles() isEqual:bundles])return;
    NSDictionary *catalog=@{@"Version":@1,@"Bundles":bundles,
        @"Timestamp":@(now),@"Source":@"existing-FBSApplicationLibrary-map-declarations"};
    if([catalog writeToFile:DFNativeMapCatalogPath atomically:YES])
        DFMapLog([NSString stringWithFormat:@"native-map-catalog-observed count=%lu",
                  (unsigned long)bundles.count]);
}
- (void)reply:(NSDictionary *)command status:(NSString *)status reason:(NSString *)reason {
    NSDictionary *ack=DFNativeMapMakeAck(command,status,reason?:@"unknown",
        NSProcessInfo.processInfo.processName,self.adapter.isAttached,
        NSDate.date.timeIntervalSince1970);
    if(!ack){DFMapLog(@"native-map-ack-invalid-no-success-reported");return;}
    if([ack writeToFile:DFMapAckPath atomically:YES])
        notify_post(DFMapAckNotify);
    DFMapLog([NSString stringWithFormat:@"command=%@ status=%@ reason=%@ attached=%d",
              command[@"Operation"]?:@"?",status,reason,self.adapter.isAttached]);
}
- (void)reply:(NSDictionary *)command ok:(BOOL)ok reason:(NSString *)reason {
    [self reply:command status:ok?DFNativeMapStatusApplied:DFNativeMapStatusRejected reason:reason];
}
- (void)replyCurrent:(NSDictionary *)command ok:(BOOL)ok reason:(NSString *)reason
           generation:(uint64_t)generation {
    if(!DFNativeMapCommandGenerationMatches(generation,self.commandGeneration))return;
    [self reply:command ok:ok reason:reason];
}
- (void)finishPending:(DFMapPendingLaunch *)pending status:(NSString *)status
                 reason:(NSString *)reason {
    if(!pending || self.pendingLaunch!=pending ||
       !DFNativeMapLaunchIsCurrent(&_launchState,pending.generation))return;
    DFNativeMapLaunchInvalidate(&_launchState);
    self.pendingLaunch=nil;
    [self reply:pending.command status:status reason:reason];
}
- (void)cancelPending:(NSString *)reason {
    [self finishPending:self.pendingLaunch status:DFNativeMapStatusCancelled reason:reason];
}
- (void)completeAdoption:(NSDictionary *)command pending:(DFMapPendingLaunch *)pending
                      ok:(BOOL)ok reason:(NSString *)reason generation:(uint64_t)generation {
    if(!DFNativeMapCommandGenerationMatches(generation,self.commandGeneration))return;
    if(pending)
        [self finishPending:pending status:ok?DFNativeMapStatusApplied:DFNativeMapStatusRejected
                      reason:reason];
    else [self reply:command ok:ok reason:reason];
}
- (void)removePaneWhenSafe {
    if(self.adapter.isAttached || self.pane.subviews.count)return;
    [self.pane removeFromSuperview];
    self.pane=nil;self.dashboard=nil;self.owner=nil;
    self.request=nil;self.boundSession=nil;self.boundBundle=nil;
    self.invalidFrameTicks=0;self.geometryVerified=NO;self.adoptionCommitted=NO;
}
- (void)invalidateLiveLeaseIfSessionActive {
    NSDictionary *pulse=[NSDictionary dictionaryWithContentsOfFile:DFNativeMapHeartbeatPath];
    if([pulse[@"Active"] isEqual:@YES] &&
       [pulse[@"Session"] isEqual:self.boundSession] &&
       [pulse[@"Timestamp"] isKindOfClass:NSNumber.class] &&
       DFNativeMapSampleFresh(NSDate.date.timeIntervalSince1970,
                             [pulse[@"Timestamp"] doubleValue],2.5)) {
        DFNativeMapClearLeaseForSession(self.boundSession);
        self.lastLeaseWrite=0;
    }
    // Inactive/new session: keep the final 5s observation for the physical
    // unplug coordinator. It cannot block phone hosting without this pulse.
}
- (BOOL)restore:(NSString **)outReason {
    if(!self.adapter.isAttached) {
        [self removePaneWhenSafe];
        return YES;
    }
    NSString *reason=nil;
    BOOL ok=[self.adapter restoreOriginalOwnerWithError:&reason];
    if(!ok && [self.adapter discardDetachedNativeOwner]) {
        ok=YES;reason=@"native-owner-already-detached-empty-pane-released";
        DFMapLog(reason);
    }
    if(ok) {
        self.adapter=nil;
        [self removePaneWhenSafe];
    }
    else {
        DFMapLog([NSString stringWithFormat:@"restore-deferred original-scene-changed reason=%@",reason]);
    }
    if(outReason)*outReason=reason;
    return ok;
}
- (DFMapPaneObservation *)observeBundle:(NSString *)requestedBundle slot:(NSInteger)slot {
    DFMapPaneObservation *result=[DFMapPaneObservation new];
    result.physicalSlot=-1;
    UIWindow *dashboard=nil;UIViewController *root=nil;
    NSDictionary *plan=DFMapMeasureLiveDock(&dashboard,&root);
    result.dashboard=dashboard;result.root=root;result.plan=plan;
    if(![plan[@"status"] isEqual:@"measured-carplay-content-split-plan"]) {
        result.reason=plan[@"status"]?:@"dock-measure-failed";return result;
    }
    NSDictionary *physical=[NSDictionary dictionaryWithContentsOfFile:
        @"/var/mobile/Library/Preferences/com.duoface.nativehost.physical-panes.v1.plist"];
    NSDictionary *heartbeat=[NSDictionary dictionaryWithContentsOfFile:DFNativeMapHeartbeatPath];
    NSDictionary *binding=DFPhysicalMapVerifyPane(physical,heartbeat,plan,
        slot,NSDate.date.timeIntervalSince1970);
    result.binding=binding;
    if(![binding[@"Verified"] isEqual:@YES]) {
        result.reason=binding[@"Reason"]?:@"no-real-duoface-pane-receipt";return result;
    }
    if(DFOwnerSessionRevoked(binding[@"Session"])) {
        result.reason=@"native-map-physical-session-revoked";return result;
    }
    NSDictionary *usable=plan[@"usableRect"];
    CGRect target=CGRectFromString(binding[@"Target"]);
    CGRect safe=CGRectMake([usable[@"x"] doubleValue],[usable[@"y"] doubleValue],
        [usable[@"width"] doubleValue],[usable[@"height"] doubleValue]);
    if(!root.viewIfLoaded || root.viewIfLoaded.window!=dashboard || dashboard.hidden ||
       !CGRectContainsRect(safe,target) || target.size.width<90 || target.size.height<120) {
        result.reason=@"native-dashboard-geometry-not-ready";return result;
    }
    result.physicalSlot=DFMapPhysicalSlot(physical,slot);
    if(result.physicalSlot<0) {result.reason=@"native-physical-slot-unverified";return result;}
    NSMutableArray *owners=[NSMutableArray new];
    DFMapFindVC(root,0,[NSMutableSet new],owners);
    result.matchingOwners=DFMapMatchingOwnerCount(owners,requestedBundle);
    result.owner=DFMapUniqueOwnerForBundle(owners,requestedBundle);
    result.safe=safe;result.target=target;result.valid=YES;
    return result;
}
- (BOOL)pendingRequestRemainsSelected:(DFMapPendingLaunch *)pending {
    if(!pending || self.pendingLaunch!=pending ||
       !DFNativeMapLaunchIsCurrent(&_launchState,pending.generation) ||
       !DFNativeMapCommandGenerationMatches(pending.commandGeneration,self.commandGeneration))return NO;
    // A fresh newer command can arrive while native factories/handlers are
    // reentrant. Cancel now; the normal command reader admits it next tick.
    NSDictionary *latest=[NSDictionary dictionaryWithContentsOfFile:DFMapCommandPath];
    if(DFNativeMapFreshExplicitCommand(latest,NSDate.date.timeIntervalSince1970) &&
       ![latest[@"RequestID"] isEqual:pending.command[@"RequestID"]] &&
       !self.consumedRequests[latest[@"RequestID"]]) {
        [self cancelPending:[latest[@"Operation"] isEqual:@"Restore"]?
            @"native-launch-cancelled-by-restore":@"native-launch-superseded-by-new-command"];
        return NO;
    }
    return YES;
}
- (BOOL)pendingDispatchIsCurrent:(DFMapPendingLaunch *)pending {
    // Final runtime callback reads first-party state and receipts only. The
    // dispatcher has just rechecked native context/presentation; do not call
    // another native getter here and open a new reentrancy gap before event.
    if(![self pendingRequestRemainsSelected:pending] ||
       !_launchState.attempted || _launchState.submitted || _launchState.adopting ||
       self.adoptionInProgress || self.adapter.isAttached || self.boundSession)return NO;
    NSTimeInterval now=NSDate.date.timeIntervalSince1970;
    NSDictionary *physical=[NSDictionary dictionaryWithContentsOfFile:
        @"/var/mobile/Library/Preferences/com.duoface.nativehost.physical-panes.v1.plist"];
    NSDictionary *heartbeat=[NSDictionary dictionaryWithContentsOfFile:DFNativeMapHeartbeatPath];
    NSDictionary *binding=DFPhysicalMapVerifyPane(physical,heartbeat,pending.plan,pending.slot,now);
    DFNativeMapLaunchEvidence evidence={
        .physicalVerified=[binding[@"Verified"] isEqual:@YES] &&
                          !DFOwnerSessionRevoked(pending.session),
        .sameSession=[binding[@"Session"] isEqual:pending.session] &&
                     [pending.context.physicalSession isEqual:pending.session],
        .samePane=[binding[@"Target"] isEqual:pending.target] &&
            DFMapPhysicalSlot(physical,pending.slot)==pending.physicalSlot,
        .leaseAbsent=YES,.matchingOwners=0,.matchingOwnerReady=NO
    };
    DFNativeMapLaunchDecision decision=DFNativeMapLaunchEvaluate(&_launchState,pending.generation,
        NSProcessInfo.processInfo.systemUptime,pending.context,pending.context,evidence);
    if(decision!=DFNativeMapLaunchWaiting || !DFNativeMapFreshExplicitCommand(pending.command,now)) {
        [self finishPending:pending status:DFNativeMapStatusCancelled reason:
            decision==DFNativeMapLaunchWaiting?@"native-launch-command-expired-before-event":
            DFNativeMapLaunchDecisionReason(decision)];
        return NO;
    }
    return YES;
}
- (BOOL)pendingCommitIsCurrent:(DFMapPendingLaunch *)pending {
    if(![self pendingRequestRemainsSelected:pending])return NO;
    NSDictionary *physical=[NSDictionary dictionaryWithContentsOfFile:
        @"/var/mobile/Library/Preferences/com.duoface.nativehost.physical-panes.v1.plist"];
    NSDictionary *heartbeat=[NSDictionary dictionaryWithContentsOfFile:DFNativeMapHeartbeatPath];
    NSDictionary *binding=DFPhysicalMapVerifyPane(physical,heartbeat,pending.plan,pending.slot,
                                                 NSDate.date.timeIntervalSince1970);
    DFNativeMapLaunchEvidence evidence={
        .physicalVerified=[binding[@"Verified"] isEqual:@YES] && !DFOwnerSessionRevoked(pending.session),
        .sameSession=[binding[@"Session"] isEqual:pending.session] &&
                     [pending.context.physicalSession isEqual:pending.session],
        .samePane=[binding[@"Target"] isEqual:pending.target] &&
            DFMapPhysicalSlot(physical,pending.slot)==pending.physicalSlot,
        .leaseAbsent=self.adapter.isAttached && [self.request isEqual:pending.command[@"RequestID"]] &&
            [self.boundSession isEqual:pending.session] && [self.boundBundle isEqual:pending.bundle],
        // The unique scene and geometry were verified before this pure guard.
        .matchingOwners=1,.matchingOwnerReady=self.owner!=nil
    };
    uint64_t (*readHomeGeneration)(void)=(uint64_t(*)(void))dlsym(
        RTLD_DEFAULT,DF_NATIVE_MAP_HOME_GENERATION_SYMBOL);
    uint64_t homeGeneration=readHomeGeneration?readHomeGeneration():0;
    return DFNativeMapLaunchCanCommit(&_launchState,pending.generation,pending.commandGeneration,
        self.commandGeneration,NSProcessInfo.processInfo.systemUptime,pending.context,
        homeGeneration,evidence);
}
- (DFMapPaneObservation *)observePending:(DFMapPendingLaunch *)pending
                          allowOwnedLease:(BOOL)allowOwnedLease
                                decision:(DFNativeMapLaunchDecision *)outDecision {
    if(![self pendingRequestRemainsSelected:pending])return nil;
    DFMapPaneObservation *observation=[self observeBundle:pending.bundle slot:pending.slot];
    NSString *contextReason=nil;
    DFNativeMapLaunchContext *context=DFNativeMapResolveLaunchContext(
        observation.root,observation.dashboard,pending.command[@"RequestID"],&contextReason);
    BOOL ownsLease=allowOwnedLease && self.adapter.isAttached &&
        [self.request isEqual:pending.command[@"RequestID"]] &&
        [self.boundSession isEqual:pending.session] && [self.boundBundle isEqual:pending.bundle];
    DFNativeMapLaunchEvidence evidence={
        .physicalVerified=observation.valid,
        .sameSession=[observation.binding[@"Session"] isEqual:pending.session] &&
                     [context.physicalSession isEqual:pending.session],
        .samePane=[observation.binding[@"Target"] isEqual:pending.target] &&
                  observation.physicalSlot==pending.physicalSlot,
        .leaseAbsent=ownsLease || (!self.adapter.isAttached && !self.boundSession),
        .matchingOwners=observation.matchingOwners,
        .matchingOwnerReady=observation.owner!=nil
    };
    DFNativeMapLaunchDecision decision=DFNativeMapLaunchEvaluate(&_launchState,pending.generation,
        NSProcessInfo.processInfo.systemUptime,pending.context,context,evidence);
    if(outDecision)*outDecision=decision;
    if(decision!=DFNativeMapLaunchWaiting && decision!=DFNativeMapLaunchReadyToAdopt) {
        [self finishPending:pending status:DFNativeMapStatusCancelled
                     reason:DFNativeMapLaunchDecisionReason(decision)];
        return nil;
    }
    return self.pendingLaunch==pending?observation:nil;
}
- (void)adoptCommand:(NSDictionary *)cmd observation:(DFMapPaneObservation *)observation
             pending:(DFMapPendingLaunch *)pending generation:(uint64_t)commandGeneration {
    if(self.adoptionInProgress ||
       !DFNativeMapCommandGenerationMatches(commandGeneration,self.commandGeneration))return;
    UIViewController *root=observation.root,*owner=observation.owner;
    UIWindow *dashboard=observation.dashboard;
    NSString *req=cmd[@"RequestID"],*requestedBundle=cmd[@"BundleID"];
    NSNumber *number=cmd[@"MapSlot"];
    CGRect target=observation.target,safe=observation.safe;
    NSDictionary *binding=observation.binding;
    if(!observation.valid || observation.matchingOwners!=1 || !owner ||
       self.adapter.isAttached || self.boundSession) {
        [self completeAdoption:cmd pending:pending ok:NO reason:@"observed-native-owner-no-longer-ready"
                      generation:commandGeneration];
        return;
    }
    self.adoptionInProgress=YES;
    CGRect inRoot=[root.view convertRect:target fromView:dashboard];
    UIView *pane=[[UIView alloc]initWithFrame:inRoot];
    pane.backgroundColor=UIColor.clearColor;pane.clipsToBounds=YES;pane.userInteractionEnabled=YES;
    [root.view addSubview:pane];
    NSString *preflight=[DFNativeMapPaneAdapter preflightNativeController:
        owner into:root container:pane measuredArea:safe];
    if(![preflight isEqual:@"ready-only-when-explicitly-authorized"]) {
        [pane removeFromSuperview];self.adoptionInProgress=NO;
        [self completeAdoption:cmd pending:pending ok:NO reason:preflight generation:commandGeneration];return;
    }
    // Re-resolve the physical session, full native context and exact unique
    // owner immediately before the containment transaction, not only at tick.
    if(pending) {
        DFNativeMapLaunchDecision decision=DFNativeMapLaunchStaleGeneration;
        DFMapPaneObservation *fresh=[self observePending:pending allowOwnedLease:NO decision:&decision];
        if(!fresh || decision!=DFNativeMapLaunchReadyToAdopt ||
           fresh.owner!=owner || fresh.root!=root || fresh.dashboard!=dashboard ||
           !DFPhysicalMapNearRect(fresh.target,target,0.0) ||
           !DFNativeMapLaunchClaimAdoption(&_launchState,pending.generation,
                                          NSProcessInfo.processInfo.systemUptime)) {
            [pane removeFromSuperview];self.adoptionInProgress=NO;
            [self finishPending:pending status:DFNativeMapStatusCancelled
                         reason:@"native-launch-owner-changed-before-adoption"];
            return;
        }
    } else {
        DFMapPaneObservation *fresh=[self observeBundle:requestedBundle slot:number.integerValue];
        if(!fresh.valid || fresh.owner!=owner || fresh.matchingOwners!=1 ||
           fresh.root!=root || fresh.dashboard!=dashboard ||
           fresh.physicalSlot!=observation.physicalSlot ||
           ![fresh.binding[@"Session"] isEqual:binding[@"Session"]] ||
           !DFPhysicalMapNearRect(fresh.target,target,0.0)) {
            [pane removeFromSuperview];self.adoptionInProgress=NO;
            [self completeAdoption:cmd pending:nil ok:NO reason:@"native-owner-or-session-changed-before-adoption"
                          generation:commandGeneration];
            return;
        }
    }
    if(!DFNativeMapCommandGenerationMatches(commandGeneration,self.commandGeneration)) {
        [pane removeFromSuperview];self.adoptionInProgress=NO;return;
    }
    DFNativeMapPaneAdapter *adapter=[DFNativeMapPaneAdapter new];
    NSString *error=nil;
    if(![adapter adoptNativeController:owner into:root container:pane measuredArea:safe
                 explicitlyAuthorized:YES error:&error]) {
        [pane removeFromSuperview];self.adoptionInProgress=NO;
        [self completeAdoption:cmd pending:pending ok:NO
                         reason:error?:@"native-owner-rejected-adoption" generation:commandGeneration];return;
    }
    self.adapter=adapter;self.pane=pane;self.dashboard=dashboard;
    self.owner=owner;self.request=[req copy];self.slot=number.integerValue;
    self.boundSession=[binding[@"Session"] copy];self.invalidFrameTicks=0;
    self.boundBundle=[requestedBundle copy];self.geometryVerified=NO;self.adoptionCommitted=NO;
    BOOL requestCurrent=DFNativeMapCommandGenerationMatches(commandGeneration,self.commandGeneration);
    if(pending) {
        DFMapPaneObservation *fresh=[self observePending:pending allowOwnedLease:YES decision:NULL];
        requestCurrent=requestCurrent && fresh && fresh.owner==owner &&
            DFNativeMapLaunchIsCurrent(&_launchState,pending.generation);
    }
    CGRect actualInDashboard=[dashboard convertRect:pane.bounds fromView:pane];
    BOOL sessionCurrent=!DFOwnerSessionRevoked(self.boundSession);
    if(!requestCurrent || !sessionCurrent || !DFPhysicalMapNearRect(actualInDashboard,target,2.0) ||
       ![adapter hasVerifiedNativeOwner] ||
       ![DFMapVerifiedBundle(self.owner) isEqual:self.boundBundle]) {
        if(!requestCurrent)
            [self finishPending:pending status:DFNativeMapStatusCancelled
                         reason:@"native-launch-owner-changed-during-adoption"];
        NSString *reason=nil;BOOL restored=[self restore:&reason];
        self.adoptionInProgress=NO;
        if(requestCurrent)
            [self completeAdoption:cmd pending:pending ok:NO reason:!sessionCurrent?
                @"native-map-session-revoked-during-adoption":restored?
                @"map-pane-actual-dash-frame-mismatch-rolled-back":
                @"map-pane-actual-dash-frame-mismatch-restore-deferred" generation:commandGeneration];
        return;
    }
    // All native ownership getters precede this first-party commit guard.
    // Its pure Home-generation read also catches a failed revoke-file write.
    if(pending && ![self pendingCommitIsCurrent:pending]) {
        [self finishPending:pending status:DFNativeMapStatusCancelled
                     reason:@"native-launch-invalidated-before-commit"];
        NSString *reason=nil;[self restore:&reason];self.adoptionInProgress=NO;return;
    }
    NSString *bundle=self.boundBundle;
    // A private getter above may have synchronously admitted another command.
    // Recheck its original generation before any persistence or terminal ACK.
    if(!DFNativeMapCommandGenerationMatches(commandGeneration,self.commandGeneration)) {
        NSString *reason=nil;[self restore:&reason];self.adoptionInProgress=NO;return;
    }
    self.geometryVerified=YES;self.adoptionCommitted=YES;
    // Neither a launch event nor Pending ACK grants a lease. Persist only
    // after exact scene identity, containment and actual geometry readback.
    if(bundle) {
        if(!DFNativeMapSaveChoiceForBundle(self.slot,bundle))DFMapLog(@"native-map-choice-save-failed");
        if(DFNativeMapWriteLease(self.boundSession,bundle,self.slot))
            self.lastLeaseWrite=NSDate.date.timeIntervalSince1970;
        else DFMapLog(@"native-map-lease-write-failed");
    }
    self.lastAutoSession=self.boundSession;self.adoptionInProgress=NO;
    [self completeAdoption:cmd pending:pending ok:YES
                     reason:@"native-owner-attached-physical-frame-observed-map-tiles-not-verified"
                 generation:commandGeneration];
}
- (void)advancePendingLaunch {
    if(self.adoptionInProgress || !self.pendingLaunch)return;
    DFMapPendingLaunch *pending=self.pendingLaunch;
    DFNativeMapLaunchDecision decision=DFNativeMapLaunchStaleGeneration;
    DFMapPaneObservation *observation=[self observePending:pending allowOwnedLease:NO decision:&decision];
    if(observation && decision==DFNativeMapLaunchReadyToAdopt)
        [self adoptCommand:pending.command observation:observation pending:pending
                 generation:pending.commandGeneration];
}
- (void)beginPendingLaunch:(NSDictionary *)cmd observation:(DFMapPaneObservation *)observation
                 generation:(uint64_t)commandGeneration {
    if(!DFNativeMapCommandGenerationMatches(commandGeneration,self.commandGeneration))return;
    NSString *reason=nil;
    DFNativeMapLaunchContext *context=DFNativeMapResolveLaunchContext(
        observation.root,observation.dashboard,cmd[@"RequestID"],&reason);
    if(!DFNativeMapCommandGenerationMatches(commandGeneration,self.commandGeneration))return;
    if(!DFNativeMapLaunchContextsMatch(context,context) ||
       ![context.physicalSession isEqual:observation.binding[@"Session"]]) {
        [self replyCurrent:cmd ok:NO reason:reason?:@"native-launch-context-unverified"
                 generation:commandGeneration];return;
    }
    NSTimeInterval now=NSDate.date.timeIntervalSince1970;
    if(![cmd[@"Operation"] isEqual:@"Attach"] || ![self.lastRequest isEqual:cmd[@"RequestID"]] ||
       !DFNativeMapFreshExplicitCommand(cmd,now) ||
       !DFNativeMapLaunchBeginForCommand(&_launchState,commandGeneration,self.commandGeneration,
           NSProcessInfo.processInfo.systemUptime,now-[cmd[@"Timestamp"] doubleValue])) {
        [self replyCurrent:cmd ok:NO reason:@"native-launch-already-pending-or-clock-invalid"
                 generation:commandGeneration];return;
    }
    DFMapPendingLaunch *pending=[DFMapPendingLaunch new];
    // Copy the original command, including its original Timestamp. This
    // request never reenters handleCommand or gets a renewed freshness window.
    pending.command=@{@"Version":cmd[@"Version"],@"RequestID":[cmd[@"RequestID"] copy],
        @"Operation":@"Attach",@"BundleID":[cmd[@"BundleID"] copy],
        @"MapSlot":cmd[@"MapSlot"],@"Timestamp":cmd[@"Timestamp"]};
    pending.bundle=cmd[@"BundleID"];pending.slot=[cmd[@"MapSlot"] integerValue];
    pending.session=observation.binding[@"Session"];pending.target=observation.binding[@"Target"];
    pending.plan=observation.plan;
    pending.physicalSlot=observation.physicalSlot;pending.context=context;
    pending.generation=_launchState.generation;
    pending.commandGeneration=commandGeneration;
    self.pendingLaunch=pending;
    // Explicit intent owns this session even if the launch is cancelled;
    // do not fall back into reattaching an older saved choice after Home.
    self.lastAutoSession=pending.session;
    if(!DFNativeMapLaunchClaimAttempt(&_launchState,pending.generation,
                                      NSProcessInfo.processInfo.systemUptime)) {
        [self finishPending:pending status:DFNativeMapStatusCancelled reason:@"native-launch-expired-before-dispatch"];
        return;
    }
    [self reply:pending.command status:DFNativeMapStatusPending
         reason:@"native-launch-once-awaiting-observed-scene"];
    DFNativeMapLaunchDecision beforeDispatch=DFNativeMapLaunchStaleGeneration;
    DFMapPaneObservation *fresh=[self observePending:pending allowOwnedLease:NO decision:&beforeDispatch];
    if(!fresh || fresh.matchingOwners!=0 || beforeDispatch!=DFNativeMapLaunchWaiting) {
        [self finishPending:pending status:DFNativeMapStatusCancelled
                     reason:@"native-launch-owner-arrived-before-event"];return;
    }
    __weak typeof(self) weakSelf=self;
    __weak DFMapPendingLaunch *weakPending=pending;
    BOOL dispatched=DFNativeMapDispatchLaunchGuarded(pending.bundle,pending.context,^BOOL{
        DFNativeMapPaneCoordinator *coordinator=weakSelf;DFMapPendingLaunch *captured=weakPending;
        if(!coordinator || !captured)return NO;
        return [coordinator pendingDispatchIsCurrent:captured];
    },&reason);
    if(self.pendingLaunch!=pending ||
       !DFNativeMapLaunchIsCurrent(&_launchState,pending.generation))return;
    if(!dispatched) {
        [self finishPending:pending status:DFNativeMapStatusRejected
                     reason:reason?:@"native-launch-event-not-submitted"];return;
    }
    if(!DFNativeMapLaunchMarkSubmitted(&_launchState,pending.generation,
                                       NSProcessInfo.processInfo.systemUptime)) {
        [self finishPending:pending status:DFNativeMapStatusCancelled reason:@"native-launch-expired-after-dispatch"];
        return;
    }
    [self advancePendingLaunch];
}
- (void)handleAttachCommand:(NSDictionary *)cmd allowLaunch:(BOOL)allowLaunch {
    uint64_t commandGeneration=self.commandGeneration;
    if(!DFNativeMapCommandGenerationMatches(commandGeneration,self.commandGeneration) ||
       (allowLaunch && ![self.lastRequest isEqual:cmd[@"RequestID"]]))return;
    if(self.adapter.isAttached || self.boundSession || self.adoptionInProgress || self.pendingLaunch) {
        [self replyCurrent:cmd ok:NO reason:@"existing-lease-must-restore-first" generation:commandGeneration];return;
    }
    NSNumber *number=cmd[@"MapSlot"];
    if(!DFNativeMapValidSlotValue(number)) {
        [self replyCurrent:cmd ok:NO reason:@"only-two-slot-native-map-supported" generation:commandGeneration];return;
    }
    NSString *requestedBundle=cmd[@"BundleID"];
    if(!DFNativeMapAllowedBundle(requestedBundle)) {
        [self replyCurrent:cmd ok:NO reason:@"explicit-supported-map-bundle-required" generation:commandGeneration];return;
    }
    DFMapPaneObservation *observation=[self observeBundle:requestedBundle slot:number.integerValue];
    if(!DFNativeMapCommandGenerationMatches(commandGeneration,self.commandGeneration))return;
    if(!observation.valid) {
        [self replyCurrent:cmd ok:NO reason:observation.reason generation:commandGeneration];return;
    }
    if(allowLaunch)self.lastAutoSession=observation.binding[@"Session"];
    DFNativeMapAttachAction action=DFNativeMapSelectAttachAction(
        allowLaunch,observation.matchingOwners,observation.owner!=nil);
    switch(action) {
        case DFNativeMapAttachRejectAmbiguous:
            [self replyCurrent:cmd ok:NO reason:@"multiple-matching-native-map-controllers" generation:commandGeneration];return;
        case DFNativeMapAttachRejectNotReady:
            [self replyCurrent:cmd ok:NO reason:@"matching-native-map-controller-not-ready" generation:commandGeneration];return;
        case DFNativeMapAttachExistingOwner:
            [self adoptCommand:cmd observation:observation pending:nil generation:commandGeneration];return;
        case DFNativeMapAttachRejectMissing:
            [self replyCurrent:cmd ok:NO reason:@"one-matching-native-map-controller-not-observed" generation:commandGeneration];return;
        case DFNativeMapAttachStartLaunch:
            [self beginPendingLaunch:cmd observation:observation generation:commandGeneration];return;
    }
}
- (void)handleCommand:(NSDictionary *)cmd {
    if(!NSThread.isMainThread || !DFMapProcess() ||
       !DFNativeMapFreshExplicitCommand(cmd,NSDate.date.timeIntervalSince1970))return;
    NSString *req=cmd[@"RequestID"],*operation=cmd[@"Operation"];
    if([req isEqual:self.lastRequest])return;
    if(!self.consumedRequests)self.consumedRequests=[NSMutableDictionary new];
    if(!DFNativeMapConsumeExplicitRequest(self.consumedRequests,req,
                                          NSProcessInfo.processInfo.systemUptime))return;
    self.lastRequest=[req copy];
    self.commandGeneration=DFNativeMapLaunchNextGeneration(self.commandGeneration);
    uint64_t commandGeneration=self.commandGeneration;
    [self cancelPending:[operation isEqual:@"Restore"]?
        @"native-launch-cancelled-by-restore":@"native-launch-superseded-by-new-command"];
    if(!DFNativeMapCommandGenerationMatches(commandGeneration,self.commandGeneration))return;
    if(self.adoptionInProgress) {
        [self replyCurrent:cmd ok:NO reason:@"native-adoption-in-progress-request-cancelled" generation:commandGeneration];return;
    }
    if([operation isEqual:@"Restore"]) {
        NSString *reason=nil,*session=self.boundSession;
        BOOL ok=[self restore:&reason];
        if(!DFNativeMapCommandGenerationMatches(commandGeneration,self.commandGeneration))return;
        if(ok) {DFNativeMapForgetChoice();DFNativeMapClearLeaseForSession(session);}
        [self replyCurrent:cmd ok:ok reason:ok?(reason?:@"native-owner-restored"):reason
                 generation:commandGeneration];return;
    }
    [self handleAttachCommand:cmd allowLaunch:YES];
}
- (void)handle {
    [self handleCommand:[NSDictionary dictionaryWithContentsOfFile:DFMapCommandPath]];
}
- (void)autoRestoreAfterReconnectIfVerified {
    if(self.adapter.isAttached || self.boundSession || self.pendingLaunch || self.adoptionInProgress)return;
    uint64_t commandGeneration=self.commandGeneration;
    NSDictionary *saved=DFNativeMapRememberedChoice();
    NSString *bundle=DFNativeMapChoiceBundle(saved);
    if(!bundle)return; // Legacy slot-only choices require a new explicit app selection.
    NSDictionary *workspace=[NSDictionary dictionaryWithContentsOfFile:
       @"/var/mobile/Library/Preferences/com.duoface.nativehost.workspace.v1.plist"];
    if(![workspace[@"RestoreOnReconnect"] isEqual:@YES])return;
    NSDictionary *heartbeat=[NSDictionary dictionaryWithContentsOfFile:
       @"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist"];
    NSString *session=heartbeat[@"Session"];
    if(![heartbeat[@"Active"] isEqual:@YES] || !DFMapUUID(session) ||
       [session isEqualToString:self.lastAutoSession] ||
       ![heartbeat[@"Timestamp"] isKindOfClass:NSNumber.class])return;
    double age=NSDate.date.timeIntervalSince1970-[heartbeat[@"Timestamp"] doubleValue];
    if(!isfinite(age)||age<0||age>2.5)return;
    UIWindow *dashboard=nil;UIViewController *root=nil;
    NSDictionary *plan=DFMapMeasureLiveDock(&dashboard,&root);
    if(![plan[@"status"] isEqual:@"measured-carplay-content-split-plan"])return;
    NSInteger slot=[saved[@"Slot"] integerValue];
    NSDictionary *physical=[NSDictionary dictionaryWithContentsOfFile:
       @"/var/mobile/Library/Preferences/com.duoface.nativehost.physical-panes.v1.plist"];
    NSDictionary *binding=DFPhysicalMapVerifyPane(physical,heartbeat,plan,
       slot,NSDate.date.timeIntervalSince1970);
    if(![binding[@"Verified"] isEqual:@YES])return;
    NSMutableArray *owners=[NSMutableArray new];
    DFMapFindVC(root,0,[NSMutableSet new],owners);
    if(!DFMapUniqueOwnerForBundle(owners,bundle))return;
    if(!DFNativeMapCommandGenerationMatches(commandGeneration,self.commandGeneration))return;
    // Exactly one safe attempt per fresh, externally verified CarPlay session.
    // Unlike a fresh Maps launch, this only rehosts an already live native VC.
    self.lastAutoSession=[session copy];
    NSString *request=NSUUID.UUID.UUIDString;
    NSDictionary *cmd=@{@"Version":@1,@"RequestID":request,
       @"Operation":@"Attach",@"MapSlot":@(slot),@"BundleID":bundle,
       @"Timestamp":@(NSDate.date.timeIntervalSince1970)};
    DFMapLog([NSString stringWithFormat:@"native-map-auto-reattach-attempt slot=%ld",(long)slot]);
    [self handleAttachCommand:cmd allowLaunch:NO];
}
- (void)refreshAdoptedNativeMapBounds {
    self.geometryVerified=NO;
    if(!self.adapter.isAttached || !self.dashboard || !self.pane ||
       !self.owner || !self.boundSession || !self.boundBundle)return;
    UIWindow *current=nil;
    UIViewController *root=nil;
    NSDictionary *plan=DFMapMeasureLiveDock(&current,&root);
    NSDictionary *physical=[NSDictionary dictionaryWithContentsOfFile:
      @"/var/mobile/Library/Preferences/com.duoface.nativehost.physical-panes.v1.plist"];
    NSDictionary *session=[NSDictionary dictionaryWithContentsOfFile:
      @"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist"];
    NSDictionary *binding=DFPhysicalMapVerifyPane(physical,session,plan,
                           self.slot,NSDate.date.timeIntervalSince1970);
    BOOL verified=[binding[@"Verified"] isEqual:@YES] &&
        [binding[@"Session"] isEqualToString:self.boundSession] &&
        !DFOwnerSessionRevoked(self.boundSession) &&
        current==self.dashboard && root==self.dashboard.rootViewController &&
        self.owner.parentViewController==root &&
        self.owner.viewIfLoaded.superview==self.pane &&
        [self.adapter hasVerifiedNativeOwner] &&
        [DFMapVerifiedBundle(self.owner) isEqual:self.boundBundle];
    if(!verified){
        [self invalidateLiveLeaseIfSessionActive];
        self.invalidFrameTicks++;
        if(self.invalidFrameTicks>=6){
            NSString *reason=nil;
            BOOL recovered=[self restore:&reason];
            DFMapLog([NSString stringWithFormat:
              @"map-reflow-lost-owner-restored=%d reason=%@",recovered,
              binding[@"Reason"]?:reason?:@"foreign-owner-changed"]);
        }
        return;
    }
    self.invalidFrameTicks=0;
    CGRect target=CGRectFromString(binding[@"Target"]);
    CGRect next=[root.view convertRect:target fromView:self.dashboard];
    if(CGRectIsEmpty(next) || CGRectIsNull(next) || CGRectIsInfinite(next)) {
        [self invalidateLiveLeaseIfSessionActive];
        return;
    }
    if(DFPhysicalMapNearRect(self.pane.frame,next,1)) {
        CGRect actual=[self.dashboard convertRect:self.pane.bounds fromView:self.pane];
        self.geometryVerified=DFPhysicalMapNearRect(actual,target,2);
        if(!self.geometryVerified)[self invalidateLiveLeaseIfSessionActive];
        return;
    }
    // Explicit real native UIKit view bounds, never fictitious scene-size
    // percentages. Scene settings foreground/orientation remain native-owned.
    self.pane.frame=next;
    self.owner.viewIfLoaded.frame=self.pane.bounds;
    [self.owner.viewIfLoaded setNeedsLayout];
    CGRect after=[self.dashboard convertRect:self.pane.bounds fromView:self.pane];
    if(!DFPhysicalMapNearRect(after,target,2)){
        [self invalidateLiveLeaseIfSessionActive];
        NSString *reason=nil;
        BOOL restored=[self restore:&reason];
        DFMapLog([NSString stringWithFormat:
           @"map-reflow-frame-rejected restored=%d reason=%@",restored,reason?:@"frame-mismatch"]);
        return;
    }
    self.geometryVerified=YES;
    DFMapLog([NSString stringWithFormat:
      @"map-physical-reflow-frame-observed=%@ actual-map-tiles-not-proven",
      NSStringFromCGRect(after)]);
}
- (void)tick:(NSTimer *)timer {
    (void)timer;
    if(!NSThread.isMainThread)return;
    // UIKit containment callbacks may reenter the run loop. Fresh commands
    // may cancel the operation, but no reentrant tick may renew its lease.
    if(self.adoptionInProgress){[self handle];return;}
    if(self.adapter.isAttached) {
        if(!self.adoptionCommitted) {
            // A cancelled containment transaction may still await safe UIKit
            // restoration. That occupied pane never gains a later lease.
            [self invalidateLiveLeaseIfSessionActive];
            NSString *reason=nil;[self restore:&reason];
        } else {
            // Native CarPlay role/screen, root ownership and current Maps VC
            // must remain stable. Do not keep a stale foreign VC across Home.
            BOOL live=self.owner && self.dashboard &&
                !self.dashboard.hidden &&
                self.owner.viewIfLoaded.window==self.dashboard &&
                self.pane.window==self.dashboard &&
                self.owner.parentViewController==self.dashboard.rootViewController;
            if(!live) {
                self.geometryVerified=NO;
                [self invalidateLiveLeaseIfSessionActive];
                NSString *reason=nil;
                [self restore:&reason]; // fail closed on a changed UIKit owner
            } else {
                [self refreshAdoptedNativeMapBounds];
                if(self.adapter.isAttached && self.geometryVerified && self.adoptionCommitted &&
                   NSDate.date.timeIntervalSince1970-self.lastLeaseWrite>=1.5){
                    NSString *bundle=DFMapVerifiedBundle(self.owner);
                    if([bundle isEqual:self.boundBundle] &&
                       DFNativeMapWriteLease(self.boundSession,bundle,self.slot))
                        self.lastLeaseWrite=NSDate.date.timeIntervalSince1970;
                }
            }
        }
    }
    [self handle]; // Give fresh explicit iPhone commands priority.
    [self advancePendingLaunch];
    [self autoRestoreAfterReconnectIfVerified];
    [self refreshNativeCatalog];
}
- (void)start {
    if(self.poll || !DFMapProcess() || !NSThread.isMainThread)return;
    if(!self.commandGeneration)self.commandGeneration=1;
    self.poll=[NSTimer scheduledTimerWithTimeInterval:0.5 target:self
                    selector:@selector(tick:) userInfo:nil repeats:YES];
    DFMapLog(@"native-map-pane-listener-ready (auto restores only previous verified explicit opt-in)");
}
@end
__attribute__((constructor))
static void DFMapPaneInstall(void) {
    @autoreleasepool {
        if(!DFMapProcess())return;
        dispatch_async(dispatch_get_main_queue(),^{
            [[DFNativeMapPaneCoordinator shared] start];
        });
    }
}
