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
#import "DFCarPlayNativeMapViewportPlan.h"

static NSString *const DFMapCommandPath=@"/var/mobile/Library/Preferences/com.duoface.nativehost.map-pane.command.v1.plist";
static NSString *const DFMapAckPath=@"/var/mobile/Library/Preferences/com.duoface.nativehost.map-pane.ack.v1.plist";
static NSString *const DFMapOwnerLog=@"/var/mobile/Library/Logs/DuoFaceNativeMapPane.log";
static const char *const DFMapCommandNotify="com.duoface.nativehost.map-pane.command.v1";
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
@interface DFNativeMapPaneCoordinator : NSObject
@property(nonatomic,strong) DFNativeMapPaneAdapter *adapter;
@property(nonatomic,strong) UIView *pane;
@property(nonatomic,weak) UIWindow *dashboard;
@property(nonatomic,weak) UIViewController *owner;
@property(nonatomic,strong) NSString *request;
@property(nonatomic,strong) NSString *lastRequest;
@property(nonatomic,strong) NSTimer *poll;
@property(nonatomic,assign) NSInteger slot;
@end
@implementation DFNativeMapPaneCoordinator
+ (instancetype)shared {
    static DFNativeMapPaneCoordinator *instance;
    static dispatch_once_t once;
    dispatch_once(&once,^{instance=[DFNativeMapPaneCoordinator new];});
    return instance;
}
- (void)reply:(NSDictionary *)command ok:(BOOL)ok reason:(NSString *)reason {
    NSDictionary *ack=@{@"Version":@1,
        @"RequestID":command[@"RequestID"]?:@"",
        @"Applied":@(ok),@"Operation":command[@"Operation"]?:@"",
        @"Reason":reason?:@"unknown",
        @"Timestamp":@(NSDate.date.timeIntervalSince1970),
        @"OwnerProcess":NSProcessInfo.processInfo.processName?:@"unknown",
        @"PaneAttached":@(self.adapter.isAttached)};
    if([ack writeToFile:DFMapAckPath atomically:YES])
        notify_post(DFMapAckNotify);
    DFMapLog([NSString stringWithFormat:@"command=%@ ok=%d reason=%@ attached=%d",
              command[@"Operation"]?:@"?",ok,reason,self.adapter.isAttached]);
}
- (void)removePaneWhenSafe {
    if(self.adapter.isAttached)return;
    [self.pane removeFromSuperview];
    self.pane=nil;self.dashboard=nil;self.owner=nil;
    self.request=nil;
}
- (BOOL)restore:(NSString **)outReason {
    if(!self.adapter.isAttached) {
        [self removePaneWhenSafe];
        return YES;
    }
    NSString *reason=nil;
    BOOL ok=[self.adapter restoreOriginalOwnerWithError:&reason];
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
- (void)handle {
    if(!NSThread.isMainThread || !DFMapProcess())return;
    NSDictionary *cmd=[NSDictionary dictionaryWithContentsOfFile:DFMapCommandPath];
    id req=cmd[@"RequestID"], stamp=cmd[@"Timestamp"],operation=cmd[@"Operation"];
    if(![cmd[@"Version"] isEqual:@1] || !DFMapUUID(req) ||
       ![stamp isKindOfClass:NSNumber.class] ||
       ![@[@"Attach",@"Restore"] containsObject:operation])return;
    double age=NSDate.date.timeIntervalSince1970-[stamp doubleValue];
    if(!isfinite(age) || age<0 || age>5.0)return;
    if([req isEqualToString:self.lastRequest])return;
    self.lastRequest=[req copy];
    if([operation isEqual:@"Restore"]) {
        NSString *reason=nil;
        BOOL ok=[self restore:&reason];
        [self reply:cmd ok:ok reason:ok?@"native-owner-restored":reason];
        return;
    }
    if(self.adapter.isAttached){
        [self reply:cmd ok:NO reason:@"existing-lease-must-restore-first"];
        return;
    }
    NSNumber *number=cmd[@"MapSlot"];
    if(![number isKindOfClass:NSNumber.class] ||
       (number.integerValue!=0 && number.integerValue!=1)) {
        [self reply:cmd ok:NO reason:@"only-two-slot-native-map-supported"];
        return;
    }
    UIWindow *dashboard=nil;
    UIViewController *root=nil;
    NSDictionary *plan=DFMapMeasureLiveDock(&dashboard,&root);
    if(![plan[@"status"] isEqual:@"measured-carplay-content-split-plan"]) {
        [self reply:cmd ok:NO reason:plan[@"status"]?:@"dock-measure-failed"];
        return;
    }
    NSString *slotKey=number.integerValue==0?@"visualSlot0":@"visualSlot1";
    NSDictionary *slot=plan[slotKey],*usable=plan[@"usableRect"];
    CGRect target=CGRectMake([slot[@"x"] doubleValue],[slot[@"y"] doubleValue],
                       [slot[@"width"] doubleValue],[slot[@"height"] doubleValue]);
    CGRect safe=CGRectMake([usable[@"x"] doubleValue],[usable[@"y"] doubleValue],
                       [usable[@"width"] doubleValue],[usable[@"height"] doubleValue]);
    if(!root.view.window || dashboard.hidden || !CGRectContainsRect(safe,target) ||
       target.size.width<90 || target.size.height<120) {
        [self reply:cmd ok:NO reason:@"native-dashboard-geometry-not-ready"];
        return;
    }
    NSMutableArray *owners=[NSMutableArray new];
    DFMapFindVC(root,0,[NSMutableSet new],owners);
    if(owners.count!=1 || !DFMapIsSceneLive(owners.firstObject)){
        [self reply:cmd ok:NO reason:@"one-native-app-controller-not-observed"];
        return;
    }
    // A transparent first-party in-process pane is created INSIDE the
    // existing native Dashboard view. It never creates another CPWindow.
    CGRect inRoot=[root.view convertRect:target fromView:dashboard];
    UIView *pane=[[UIView alloc]initWithFrame:inRoot];
    pane.backgroundColor=UIColor.clearColor;
    pane.clipsToBounds=YES;
    pane.userInteractionEnabled=YES;
    [root.view addSubview:pane];
    NSString *preflight=[DFNativeMapPaneAdapter preflightNativeController:
         owners.firstObject into:root container:pane measuredArea:safe];
    if(![preflight isEqual:@"ready-only-when-explicitly-authorized"]) {
        [pane removeFromSuperview];
        [self reply:cmd ok:NO reason:preflight];
        return;
    }
    DFNativeMapPaneAdapter *adapter=[DFNativeMapPaneAdapter new];
    NSString *error=nil;
    // The explicit user command + live in-process owner/geometry preflight
    // is the authorization for this isolated, reversible QA experiment.
    if(![adapter adoptNativeController:owners.firstObject into:root
              container:pane measuredArea:safe explicitlyAuthorized:YES error:&error]) {
        [pane removeFromSuperview];
        [self reply:cmd ok:NO reason:error?:@"native-owner-rejected-adoption"];
        return;
    }
    self.adapter=adapter;self.pane=pane;self.dashboard=dashboard;
    self.owner=owners.firstObject;self.request=[req copy];self.slot=number.integerValue;
    [self reply:cmd ok:YES reason:@"native-controller-attached-visual-not-yet-device-verified"];
}
- (void)tick:(NSTimer *)timer {
    (void)timer;
    if(!NSThread.isMainThread)return;
    if(self.adapter.isAttached) {
        // Native CarPlay role/screen, root ownership and current Maps VC
        // must remain stable. Do not keep a stale foreign VC across Home.
        BOOL live=self.owner && self.dashboard &&
            !self.dashboard.hidden &&
            self.owner.viewIfLoaded.window==self.dashboard &&
            self.pane.window==self.dashboard &&
            self.owner.parentViewController==self.dashboard.rootViewController;
        if(!live) {
            NSString *reason=nil;
            [self restore:&reason]; // fail closed on a changed UIKit owner
        }
    }
    [self handle];
}
- (void)start {
    if(self.poll || !DFMapProcess() || !NSThread.isMainThread)return;
    self.poll=[NSTimer scheduledTimerWithTimeInterval:0.5 target:self
                    selector:@selector(tick:) userInfo:nil repeats:YES];
    DFMapLog(@"native-map-pane-opt-in-listener-ready (no auto attach)");
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
