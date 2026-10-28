// Only observes existing CarPlay Dashboard owner. Never admits applications,
// constructs a window, displays a bar, repositions Apple's chrome or injects touch.
#import "DFNativeSceneContract.h"
extern void DFCarPlayCaptureLiveOwnerSnapshot(NSString *probeSession);
#import <UIKit/UIKit.h>
#import <fcntl.h>
#import <unistd.h>
#import <math.h>
#import <objc/runtime.h>
@interface DFNativeSceneProbe : NSObject
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,copy) NSString *session;
@property(nonatomic,copy) NSString *lastDescription;
@property(nonatomic,assign) NSUInteger ticks;
@end
@implementation DFNativeSceneProbe
static void DFProbeLog(NSString *message) {
    NSString *line=[NSString stringWithFormat:@"[DuoFaceNativeSceneJoin] %@\n",message];
    NSLog(@"%@",line);
    int fd=open("/var/mobile/Library/Logs/DuoFaceNativeSceneJoin.log",
                O_WRONLY|O_APPEND|O_CREAT,0644);
    if(fd>=0){NSData *d=[line dataUsingEncoding:NSUTF8StringEncoding];
        (void)write(fd,d.bytes,d.length);close(fd);}
}
// ABI introspection only; NEVER invoke private workspace API here.
static NSString *DFProbeMethodABI(Class cls,SEL selector,BOOL classMethod) {
    if(!cls)return @"class-unavailable";
    Method m=classMethod?class_getClassMethod(cls,selector):class_getInstanceMethod(cls,selector);
    if(!m)return @"selector-unavailable";
    const char *abi=method_getTypeEncoding(m);
    return abi?[NSString stringWithUTF8String:abi]:@"ABI-unavailable";
}
static void DFProbeNativeWorkspaceABI(void) {
    Class workspace=NSClassFromString(@"DBWorkspace");
    Class controller=NSClassFromString(@"DBApplicationController");
    Class request=NSClassFromString(@"DBMutableWorkspaceStateChangeRequest");
    Class owner=NSClassFromString(@"DBDashboardWorkspaceOwner");
    DFProbeLog([NSString stringWithFormat:
      @"native-workspace-abi workspace=%@ requestStateChange=%@ controller=%@ sharedInstance=%@ request=%@ activateApplication=%@ owner=%@",
      workspace?@"yes":@"no",DFProbeMethodABI(workspace,@selector(requestStateChange:),NO),
      controller?@"yes":@"no",DFProbeMethodABI(controller,@selector(sharedInstance),YES),
      request?@"yes":@"no",DFProbeMethodABI(request,@selector(activateApplication:),NO),
      owner?@"yes":@"no"]);
}
// First-party app-admission ABI survey only. No private method invocation or swizzle.
static void DFProbeNativeAppAdmissionABI(void) {
    Class catalog=NSClassFromString(@"CARApplication");
    Class proxy=NSClassFromString(@"LSBundleProxy");
    Class fb=NSClassFromString(@"FBSApplicationInfo");
    Class workspace=NSClassFromString(@"DBWorkspace");
    Class appInfo=NSClassFromString(@"DBApplicationInfo");
    DFProbeLog([NSString stringWithFormat:
      @"native-admission-abi CARApplication=%@ allInstalled=%@ byBundleID=%@ "
      @"LSBundleProxy=%@ typed3=%@ typed2=%@ bulk=%@ infoDictionary=%@ "
      @"FBSApplicationInfo=%@ fbBulk=%@ DBApplicationInfo=%@ workspaceInitOwner=%@",
      catalog?@"yes":@"no",
      DFProbeMethodABI(catalog,@selector(_allInstalledApplications),YES),
      DFProbeMethodABI(catalog,@selector(_allInstalledApplicationsByBundleIdentifier),YES),
      proxy?@"yes":@"no",
      DFProbeMethodABI(proxy,NSSelectorFromString(@"entitlementValueForKey:ofClass:valuesOfClass:"),NO),
      DFProbeMethodABI(proxy,NSSelectorFromString(@"entitlementValueForKey:ofClass:"),NO),
      DFProbeMethodABI(proxy,@selector(entitlementValuesForKeys:),NO),
      DFProbeMethodABI(proxy,@selector(infoDictionary),NO),
      fb?@"yes":@"no",
      DFProbeMethodABI(fb,@selector(entitlementValuesForKeys:),NO),
      appInfo?@"yes":@"no",
      DFProbeMethodABI(workspace,@selector(initWithOwner:),NO)]);
}
+ (instancetype)shared {
    static DFNativeSceneProbe *o;
    static dispatch_once_t once;
    dispatch_once(&once,^{o=[self new];});return o;
}
- (void)start {
    if(self.timer || !NSThread.isMainThread)return;
    NSString *p=NSProcessInfo.processInfo.processName;
    if(![p isEqual:@"CarPlay"] && ![p isEqual:@"CarPlayApp"])return;
    self.session=NSUUID.UUID.UUIDString;
    DFProbeLog([NSString stringWithFormat:@"passive-start process=%@ version=0.0.1 no-ui-mutation",p]);
    DFProbeNativeWorkspaceABI();
    DFProbeNativeAppAdmissionABI();
    self.timer=[NSTimer scheduledTimerWithTimeInterval:1.5 target:self
        selector:@selector(tick) userInfo:nil repeats:YES];
    [self tick];
}
- (void)tick {
    if(!NSThread.isMainThread)return;
    self.ticks++;
    // CarPlaySupport classes may load after application startup.
    // Repeat type-only inspection every ~30 seconds, never call admission APIs.
    if(self.ticks%20==0)DFProbeNativeAppAdmissionABI();
    // Record actual controller/scene associations in the running CarPlay process.
    // Do not create/foreground/background scenes, mutate Dock, or host Maps.
    if(self.ticks==1 || self.ticks%20==0)
        DFCarPlayCaptureLiveOwnerSnapshot(self.session);
    CGRect full=CGRectNull, usable=CGRectNull;
    BOOL chrome=NO, dashboard=NO;
    UIWindow *dashboardWindow=nil;
    UIWindow *nativeBarWindow=nil;
    CGRect barInScene=CGRectNull;
    NSUInteger inspected=0;
    // FIRST: find the real Dashboard root on the external display.
    for(UIScene *scene in UIApplication.sharedApplication.connectedScenes){
        if(![scene isKindOfClass:UIWindowScene.class] ||
           scene.activationState!=UISceneActivationStateForegroundActive)continue;
        UIWindowScene *ws=(UIWindowScene *)scene;
        if(ws.screen==UIScreen.mainScreen)continue;
        for(UIWindow *w in ws.windows){
            if(++inspected>64)break;
            if(w.screen!=ws.screen || w.hidden || w.alpha<0.95)continue;
            if([NSStringFromClass(w.rootViewController.class)
                isEqual:@"DBDashboardRootViewController"]){
                dashboardWindow=w;dashboard=YES;
                full=w.bounds;break;
            }
        }
        if(dashboardWindow)break;
    }
    if(dashboardWindow){
        // SECOND: Apple can host the sidebar in a SIBLING UIWindowScene on
        // the SAME UIScreen. Never assume the bar belongs to Dashboard's scene.
        inspected=0;
        for(UIScene *scene in UIApplication.sharedApplication.connectedScenes){
            if(![scene isKindOfClass:UIWindowScene.class] ||
               scene.activationState!=UISceneActivationStateForegroundActive)continue;
            UIWindowScene *ws=(UIWindowScene *)scene;
            if(ws.screen!=dashboardWindow.screen)continue;
            for(UIWindow *w in ws.windows){
                if(++inspected>64)break;
                if(w.screen!=dashboardWindow.screen ||
                   w.hidden || w.alpha<0.95)continue;
                NSString *kind=NSStringFromClass(w.class);
                if(![kind isEqual:@"DBDockWindow"] &&
                   ![kind isEqual:@"DBStatusBarWindow"] &&
                   ![kind isEqual:@"CARStatusBarWindow"])continue;
                CGRect converted=[dashboardWindow convertRect:w.bounds fromWindow:w];
                if(!isfinite(converted.origin.x) || !isfinite(converted.origin.y) ||
                   !isfinite(converted.size.width) || !isfinite(converted.size.height))
                    continue;
                CGRect visible=CGRectIntersection(full,converted);
                if(CGRectIsNull(visible) || CGRectIsEmpty(visible))continue;
                chrome=YES; // Observed visible system window; not a show command.
                // Keep the largest visible system bar; do not synthesize geometry.
                if(!nativeBarWindow ||
                   CGRectGetWidth(visible)*CGRectGetHeight(visible)>
                   CGRectGetWidth(barInScene)*CGRectGetHeight(barInScene)){
                    nativeBarWindow=w;barInScene=visible;
                }
            }
            if(inspected>64)break;
        }
    }
    if(dashboardWindow){
        UIEdgeInsets i=dashboardWindow.safeAreaInsets;
        CGFloat t=i.top,l=i.left,b=i.bottom,r=i.right;
        NSString *measurement=@"dashboard-safe-area";
        if(nativeBarWindow && !CGRectIsNull(barInScene)){
            // Derive actual bar thickness ONLY if a visible bar touches exactly
            // one native scene edge; never guess pixels or reposition the bar.
            CGFloat epsilon=1.0;
            BOOL leftEdge=fabs(CGRectGetMinX(barInScene)-CGRectGetMinX(full))<epsilon;
            BOOL rightEdge=fabs(CGRectGetMaxX(barInScene)-CGRectGetMaxX(full))<epsilon;
            BOOL topEdge=fabs(CGRectGetMinY(barInScene)-CGRectGetMinY(full))<epsilon;
            BOOL bottomEdge=fabs(CGRectGetMaxY(barInScene)-CGRectGetMaxY(full))<epsilon;
            if(CGRectGetHeight(barInScene)>full.size.height*0.65 &&
               CGRectGetWidth(barInScene)<full.size.width*0.30 &&
               leftEdge!=rightEdge){
                CGFloat x=CGRectGetWidth(barInScene);
                if(leftEdge)l=MAX(l,x);else r=MAX(r,x);
                measurement=@"native-bar-frame-vertical";
            }else if(CGRectGetWidth(barInScene)>full.size.width*0.65 &&
                     CGRectGetHeight(barInScene)<full.size.height*0.30 &&
                     topEdge!=bottomEdge){
                CGFloat y=CGRectGetHeight(barInScene);
                if(topEdge)t=MAX(t,y);else b=MAX(b,y);
                measurement=@"native-bar-frame-horizontal";
            }
        }
        if(!DFNativeSceneUsable(full,t,l,b,r,&usable)){
            usable=full;measurement=@"unresolved-full-scene-no-guess";
        }
        if(nativeBarWindow && ![self.lastDescription containsString:@"native-bar-frame="]){
            DFProbeLog([NSString stringWithFormat:
                @"native-bar-frame=%@ window=%@ method=%@ safeInsets=%@",
                NSStringFromCGRect(barInScene),NSStringFromClass(nativeBarWindow.class),
                measurement,NSStringFromUIEdgeInsets(i)]);
        }
        NSDictionary *record=DFNativeSceneOwnerRecord(self.session,full,usable,
                              chrome,NSDate.date.timeIntervalSince1970);
        if(record && DFNativeSceneValidateOwnerRecord(record,self.session,
                                                  NSDate.date.timeIntervalSince1970)){
            // Short lease expires within 3s if the real owner is disconnected.
            [record writeToFile:DFNativeSceneOwnerRecordPath atomically:YES];
        }
    } else {
        // Never erase a record written by the other CarPlay host process.
        NSDictionary *previous=[NSDictionary dictionaryWithContentsOfFile:DFNativeSceneOwnerRecordPath];
        if([previous[@"Session"] isEqual:self.session])
          [[NSFileManager defaultManager] removeItemAtPath:DFNativeSceneOwnerRecordPath error:nil];
    }
    NSString *state=[NSString stringWithFormat:@"dashboard=%d nativeChrome=%d full=%@ usable=%@ native-bar-frame=%@",
      dashboard,chrome,NSStringFromCGRect(full),NSStringFromCGRect(usable),NSStringFromCGRect(barInScene)];
    if(![self.lastDescription isEqual:state] || self.ticks%20==0){
        self.lastDescription=state;DFProbeLog(state);
    }
}
@end
void DFNativeSceneProbeStart(void){[[DFNativeSceneProbe shared] start];}
