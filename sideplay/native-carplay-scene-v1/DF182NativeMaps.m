// QA182 B1 NEW implementation; no historical three-hook source was recovered.
// Apple's native workspace/scene/input own Maps. No phone-scene fallback.
#import "../duoface-native-scene-host/DF182NativeMapAssignment.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>
#import <string.h>

static id DF182Get(id obj,const char *name) {
 Method m=obj?class_getInstanceMethod(object_getClass(obj),sel_registerName(name)):NULL;
 if(!m || strcmp(method_getTypeEncoding(m),"@16@0:8"))return nil;
 @try{return ((id(*)(id,SEL))objc_msgSend)(obj,sel_registerName(name));}
 @catch(__unused NSException *exception){return nil;}
}
static NSString *DF182Bundle(id info) {return DF182String(DF182Get(info,"bundleIdentifier"));}
static id DF182Scene(id owner) {
 return DF182Get(owner,"scene")?:DF182Get(DF182Get(owner,"sceneHandle"),"sceneIfExists");
}
static NSDictionary *DF182Provenance(UIViewController *owner) {
 id scene=DF182Scene(owner),settings=DF182Get(scene,"settings");
 id info=DF182Get(owner,"applicationInfo")?:DF182Get(owner,"proxyApplicationInfo");
 UIWindow *w=owner.viewIfLoaded.window;
 return @{@"bundle":DF182Bundle(info),@"controller":owner?NSStringFromClass(owner.class):@"unknown",
  @"controllerProvenance":owner?@"existing-native-dashboard-controller-tree":@"unknown",
  @"sceneProvenance":DF182Get(owner,"scene")?@"controller.scene":
     (scene?@"controller.sceneHandle.sceneIfExists":@"unknown"),
  @"sceneID":DF182String(DF182Get(scene,"identifier")),
  @"sceneClass":scene?NSStringFromClass([scene class]):@"unknown",
  @"sceneRole":DF182String(DF182Get(settings,"role")),
  @"sceneClientProcessBundle":DF182String(DF182Get(DF182Get(DF182Get(scene,"client"),"process"),"bundleIdentifier")),
  @"settingsClass":settings?NSStringFromClass([settings class]):@"unknown",
  @"windowRole":DF182String(w.windowScene.session.role),
  @"display":w.screen?NSStringFromCGRect(w.screen.bounds):@"unknown",
  @"external":@(w.screen && w.screen!=UIScreen.mainScreen),
  @"process":NSProcessInfo.processInfo.processName?:@"unknown"};
}
static BOOL DF182NativeOwner(UIViewController *owner) {
 NSDictionary *p=DF182Provenance(owner);
 UIView *host=DF182Get(owner,"sceneHostView"),*view=owner.viewIfLoaded;
 return [p[@"bundle"] isEqual:@"com.google.Maps"] &&
  [p[@"controller"] isEqual:@"DBApplicationSceneViewController"] &&
  [p[@"sceneClass"] isEqual:@"FBScene"] && ![p[@"sceneID"] isEqual:@"unknown"] &&
  [p[@"windowRole"] isEqual:@"UIWindowSceneSessionRoleCarPlay"] &&
  [p[@"external"] isEqual:@YES] && [host isKindOfClass:UIView.class] &&
  (host==view||[host isDescendantOfView:view]) && host.window==view.window &&
  view.window && owner.parentViewController;
}
static BOOL DF182Near(CGRect a,CGRect b) {
 return fabs(a.origin.x-b.origin.x)<=2 && fabs(a.origin.y-b.origin.y)<=2 &&
        fabs(a.size.width-b.size.width)<=2 && fabs(a.size.height-b.size.height)<=2;
}
static void DF182Walk(UIViewController *vc,NSMutableArray *out,NSUInteger depth) {
 if(!vc||depth>10||out.count>48)return;
 if([NSStringFromClass(vc.class) isEqual:@"DBApplicationSceneViewController"] &&
    [DF182Bundle(DF182Get(vc,"applicationInfo")?:DF182Get(vc,"proxyApplicationInfo")) isEqual:@"com.google.Maps"])
  [out addObject:vc];
 for(UIViewController *child in vc.childViewControllers)DF182Walk(child,out,depth+1);
 if(vc.presentedViewController)DF182Walk(vc.presentedViewController,out,depth+1);
}
@interface DF182MapsOwner:NSObject
@property(nonatomic,strong) NSDictionary *assignment;
@property(nonatomic,strong) NSMutableDictionary *gates;
@property(nonatomic,weak) UIViewController *owner;
@property(nonatomic,weak) UIWindow *window;
@property(nonatomic,weak) id scene;
@property(nonatomic,strong) UIViewController *oldParent;
@property(nonatomic,strong) UIView *oldSuperview;
@property(nonatomic,strong) UIView *pane;
@property(nonatomic,assign) CGRect oldFrame;
@property(nonatomic,assign) CGRect target;
@property(nonatomic,assign) UIViewAutoresizing oldAutoresizing;
@property(nonatomic,assign) NSUInteger oldIndex;
@property(nonatomic,assign) BOOL placed;
@property(nonatomic,assign) BOOL stopped;
@property(nonatomic,assign) BOOL launchAttempted;
@property(nonatomic,assign) NSTimeInterval deadline;
@property(nonatomic,strong) NSDictionary *provenance;
- (void)tick;
- (void)summary:(NSString *)reason;
- (void)fail:(NSString *)gate reason:(NSString *)reason;
- (BOOL)owns:(id)controller;
- (BOOL)restore:(NSString *)reason;
@end
static DF182MapsOwner *DF182Owner;
static CGRect (*DF182OriginalFrame)(id,SEL,id,id);
static void (*DF182OriginalDeactivate)(id,SEL,NSUInteger);
static void (*DF182OriginalBackground)(id,SEL,id);
typedef void(*DF182Hook)(Class,SEL,IMP,IMP*);
static CGRect DF182Frame(id obj,SEL sel,id info,id proxy) {
 CGRect r=DF182OriginalFrame(obj,sel,info,proxy);
 if([DF182Owner owns:DF182Owner.owner] &&
   ([DF182Bundle(info) isEqual:@"com.google.Maps"] || [DF182Bundle(proxy) isEqual:@"com.google.Maps"]))
  r.size=DF182Owner.pane.bounds.size; // Actual placement uses explicit UIKit screen conversion below.
 return r;
}
static void DF182Deactivate(id obj,SEL sel,NSUInteger mask) {
 if([DF182Owner owns:obj]) {
  DF182Owner.gates[@"Lifecycle"]=@"PASS";
  DF182Log(@"lifecycle-swallowed",DF182Owner.assignment,
   [NSString stringWithFormat:@"method=deactivateSceneWithReasonMask: mask=%lu",(unsigned long)mask]);
  return;
 }
 DF182OriginalDeactivate(obj,sel,mask);
}
#import "../duoface-native-scene-host/DF182BlockCompletionABI.h"
static void DF182Background(id obj,SEL sel,id completion) {
 if([DF182Owner owns:obj]) {
  if(!DF182VoidCompletion(completion)) {
   [DF182Owner fail:@"Lifecycle" reason:@"background-completion-ABI-unverified"];
   DF182OriginalBackground(obj,sel,completion);return;
  }
  DF182Owner.gates[@"Lifecycle"]=@"PASS";
  DF182Log(@"lifecycle-swallowed",DF182Owner.assignment,@"method=backgroundSceneWithCompletion: completion=verified-void-once-synchronous");
  if(completion)((void(^)(void))completion)();
  return;
 }
 DF182OriginalBackground(obj,sel,completion);
}
static BOOL DF182Method(Class cls,const char *name,const char *ret,NSArray<NSString *> *args,NSDictionary *a) {
 Method m=cls?class_getInstanceMethod(cls,sel_registerName(name)):NULL;
 BOOL match=m && method_getNumberOfArguments(m)==args.count+2;
 char type[256]={0};
 if(m)method_getReturnType(m,type,sizeof(type));
 match=match && !strcmp(type,ret);
 for(NSUInteger i=0;match && i<args.count;i++) {
  method_getArgumentType(m,(unsigned int)i+2,type,sizeof(type));
  match=!strcmp(type,args[i].UTF8String);
 }
 DF182Log(@"hook-ABI",a,[NSString stringWithFormat:@"class=%s method=%s actual=%s match=%d",
  cls?class_getName(cls):"unknown",name,m?method_getTypeEncoding(m):"unknown",match]);
 return match;
}
static BOOL DF182InstallHooks(NSDictionary *a) {
 if(DF182OriginalFrame && DF182OriginalDeactivate && DF182OriginalBackground)return YES;
 Class dash=objc_getClass("DBDashboard"),vc=objc_getClass("DBApplicationSceneViewController");
 BOOL frame=DF182Method(dash,"sceneFrameForAppInfo:proxyAppInfo:",@encode(CGRect),@[@"@",@"@"],a);
 BOOL deactivate=DF182Method(vc,"deactivateSceneWithReasonMask:",@encode(void),@[[NSString stringWithUTF8String:@encode(NSUInteger)]],a);
 BOOL background=DF182Method(vc,"backgroundSceneWithCompletion:",@encode(void),@[@"@?"],a);
 DF182Hook hook=(DF182Hook)dlsym(RTLD_DEFAULT,"MSHookMessageEx");
 if(!frame||!deactivate||!background||!hook)return NO; // No partial installation.
 hook(dash,sel_registerName("sceneFrameForAppInfo:proxyAppInfo:"),(IMP)DF182Frame,(IMP*)&DF182OriginalFrame);
 hook(vc,sel_registerName("deactivateSceneWithReasonMask:"),(IMP)DF182Deactivate,(IMP*)&DF182OriginalDeactivate);
 hook(vc,sel_registerName("backgroundSceneWithCompletion:"),(IMP)DF182Background,(IMP*)&DF182OriginalBackground);
 return DF182OriginalFrame && DF182OriginalDeactivate && DF182OriginalBackground;
}
@implementation DF182MapsOwner
- (void)summary:(NSString *)reason {
 NSMutableDictionary *r=[self.gates mutableCopy];
 r[@"AssignmentID"]=self.assignment[@"AssignmentID"]?:@"unknown";
 r[@"Session"]=self.assignment[@"Session"]?:@"unknown";
 r[@"Reason"]=reason?:@"unknown";r[@"Timestamp"]=@(NSDate.date.timeIntervalSince1970);
 r[@"Touch"]=@"UNVERIFIED";r[@"NativePixels"]=@"UNVERIFIED";
 r[@"StockSettings"]=@"unknown";r[@"Provenance"]=self.provenance?:DF182Provenance(nil);
 BOOL saved=[r writeToFile:DF182ResultPath atomically:YES];
 DF182Log(@"summary",self.assignment,[NSString stringWithFormat:
  @"catalog=%@ launch=%@ scene=%@ frame=%@ lifecycle=%@ native-pixels=UNVERIFIED touch=UNVERIFIED reason=%@ result-saved=%d",
  r[@"Catalog"],r[@"Launch"],r[@"Scene"],r[@"Frame"],r[@"Lifecycle"],r[@"Reason"],saved]);
}
- (BOOL)owns:(id)controller {
 return NSThread.isMainThread && !self.stopped && self.placed && controller &&
  controller==self.owner && [self.assignment[@"AssignmentID"] isEqual:DF182Assignment()[@"AssignmentID"]] &&
  DF182Scene(controller)==self.scene && DF182NativeOwner(controller) &&
  self.owner.viewIfLoaded.superview==self.pane && self.pane.window==self.window;
}
- (BOOL)restore:(NSString *)reason {
 self.stopped=YES; // Revokes swallow BEFORE containment is restored.
 if(!self.placed)return YES;
 UIViewController *vc=self.owner;UIView *v=vc.viewIfLoaded;
 if(!vc||!v||v.superview!=self.pane||!self.oldSuperview||
    self.oldSuperview.window!=self.window || DF182Scene(vc)!=self.scene) {
  self.gates[@"Lifecycle"]=@"FAIL";
  DF182Log(@"lifecycle-restored",self.assignment,@"restoration=FAIL reason=original-owner-or-scene-changed");
  return NO;
 }
 [vc willMoveToParentViewController:nil];[v removeFromSuperview];[vc removeFromParentViewController];
 [self.oldParent addChildViewController:vc];
 [self.oldSuperview insertSubview:v atIndex:MIN(self.oldIndex,self.oldSuperview.subviews.count)];
 v.frame=self.oldFrame;v.autoresizingMask=self.oldAutoresizing;
 [vc didMoveToParentViewController:self.oldParent];
 BOOL verified=vc.parentViewController==self.oldParent && v.superview==self.oldSuperview &&
  DF182Near(v.frame,self.oldFrame) && v.window==self.window;
 if(verified){[self.pane removeFromSuperview];self.pane=nil;self.placed=NO;}
 self.gates[@"Lifecycle"]=verified?@"PASS":@"FAIL";
 DF182Log(@"lifecycle-restored",self.assignment,[NSString stringWithFormat:
  @"restoration=%@ reason=%@ parent=%@ frame=%@ coordinate=original-superview",
  verified?@"PASS":@"FAIL",reason,NSStringFromClass(vc.parentViewController.class),NSStringFromCGRect(v.frame)]);
 return verified;
}
- (void)fail:(NSString *)gate reason:(NSString *)reason {
 self.gates[gate]=@"FAIL";
 [self restore:reason];
 [self summary:reason];
}
- (BOOL)targetForWindow:(UIWindow *)window rect:(CGRect *)out {
 NSDictionary *sample=[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.duoface.nativehost.physical-panes.v1.plist"];
 double age=NSDate.date.timeIntervalSince1970-[sample[@"Timestamp"] doubleValue];
 if(![sample[@"Session"] isEqual:self.assignment[@"Session"]] ||
    ![sample[@"Owner"] isEqual:@"SpringBoard"] || ![sample[@"ActiveSlots"] isEqual:@2] ||
    ![sample[@"Focus"] isEqual:@(-1)] || !isfinite(age)||age<0||age>1.75)return NO;
 NSArray *entries=sample[@"Windows"];
 if(![entries isKindOfClass:NSArray.class]||entries.count!=2)return NO;
 for(NSDictionary *e in entries) {
  if(![e[@"PhysicalSlot"] isEqual:self.assignment[@"PhysicalSlot"]])continue;
  if(![e[@"NativeAssignmentID"] isEqual:self.assignment[@"AssignmentID"]] ||
     ![e[@"WindowVisible"] isEqual:@NO] || ![e[@"HasLiveApp"] isEqual:@NO] ||
     ![e[@"OnExternalScreen"] isEqual:@YES] ||
     ![e[@"CoordinateSpace"] isEqual:@"external-UIScreen-points"])return NO;
  CGRect screenRect=CGRectFromString(e[@"Frame"]);
  if(!isfinite(screenRect.origin.x)||!isfinite(screenRect.origin.y)||
     !isfinite(screenRect.size.width)||!isfinite(screenRect.size.height)||
     screenRect.size.width<90||screenRect.size.height<120 ||
     !CGRectContainsRect(window.screen.bounds,screenRect))return NO;
  *out=[window convertRect:screenRect fromCoordinateSpace:window.screen.coordinateSpace];
  return CGRectContainsRect(window.bounds,*out);
 }
 return NO;
}
- (void)tick {
 NSDictionary *current=DF182Assignment();
 if(![current[@"AssignmentID"] isEqual:self.assignment[@"AssignmentID"]]) {
  if(self.assignment && !self.stopped){[self restore:@"Home-replaced-unassigned-disconnected-or-stale-session"];[self summary:@"assignment-released"];}
  if(!current || self.placed)return; // A failed restore blocks further foreign scene mutation.
  self.assignment=current;self.stopped=NO;self.launchAttempted=NO;self.provenance=nil;
  self.gates=[@{@"Catalog":@"UNVERIFIED",@"Launch":@"UNVERIFIED",@"Scene":@"UNVERIFIED",@"Frame":@"UNVERIFIED",@"Lifecycle":@"UNVERIFIED"} mutableCopy];
  self.deadline=NSProcessInfo.processInfo.systemUptime+10.0;
  if(!DF182InstallHooks(current)){[self fail:@"Scene" reason:@"required-hook-ABI-missing-or-mismatched-STOP"];return;}
 }
 if(self.stopped||!self.assignment)return;
 if(!self.launchAttempted) {
  // Resolve the already-loaded Dock module; never construct a replacement library/workspace.
  typedef NSDictionary *(*Launch)(NSDictionary *);
  Launch launch=(Launch)dlsym(RTLD_DEFAULT,"DF182CatalogAndLaunch");
  if(!launch){[self fail:@"Launch" reason:@"native-dashboard-launch-owner-unavailable-STOP"];return;}
  self.launchAttempted=YES;
  NSDictionary *result=launch(self.assignment);
  self.gates[@"Catalog"]=result[@"Catalog"]?:@"UNVERIFIED";
  self.gates[@"Launch"]=result[@"Launch"]?:@"UNVERIFIED";
  if(![result[@"Issued"] isEqual:@YES]) {
   [self fail:[result[@"Catalog"] isEqual:@"FAIL"]?@"Catalog":@"Launch" reason:result[@"Reason"]?:@"native-launch-not-issued-STOP"];return;
  }
  self.deadline=NSProcessInfo.processInfo.systemUptime+10.0;
 }
 if(self.placed) {
  CGRect target=CGRectZero;
  if(![self owns:self.owner] || ![self targetForWindow:self.window rect:&target]) {
   [self fail:@"Frame" reason:@"native-owner-or-live-pane-binding-lost-STOP"];return;
  }
  if(!DF182Near(self.target,target)) {
   CGRect before=[self.window convertRect:self.pane.bounds fromView:self.pane];
   self.pane.frame=[self.window.rootViewController.view convertRect:target fromView:self.window];
   self.owner.view.frame=self.pane.bounds;
   self.target=target;
   CGRect actual=[self.window convertRect:self.pane.bounds fromView:self.pane];
   if(!DF182Near(actual,target)) {
    [self fail:@"Frame" reason:@"native-reflow-readback-mismatch-STOP"];return;
   }
   DF182Log(@"frame-placed",self.assignment,[NSString stringWithFormat:
    @"before=%@ after=%@ coordinate=native-dashboard-UIWindow-points clipping=1 target-SpringBoard-window=hidden reflow=1",
    NSStringFromCGRect(before),NSStringFromCGRect(target)]);
  }
  return;
 }
 NSMutableArray *candidates=[NSMutableArray new];
 for(UIScene *s in UIApplication.sharedApplication.connectedScenes) {
  if(![s isKindOfClass:UIWindowScene.class])continue;
  UIWindowScene *ws=(UIWindowScene *)s;
  if(ws.screen==UIScreen.mainScreen||![ws.session.role isEqual:@"UIWindowSceneSessionRoleCarPlay"])continue;
  for(UIWindow *w in ws.windows)if(!w.hidden && [NSStringFromClass(w.rootViewController.class) isEqual:@"DBDashboardRootViewController"])
   DF182Walk(w.rootViewController,candidates,0);
 }
 if(candidates.count==1 && DF182NativeOwner(candidates.firstObject)) {
  UIViewController *vc=candidates.firstObject;UIWindow *w=vc.viewIfLoaded.window;
  self.provenance=DF182Provenance(vc);
  if(![self.gates[@"Scene"] isEqual:@"PASS"])
   DF182Log(@"scene-seen",self.assignment,[NSString stringWithFormat:@"provenance=%@",self.provenance]);
  self.gates[@"Scene"]=@"PASS";self.gates[@"Launch"]=@"PASS";
  CGRect target=CGRectZero;
  if(![self targetForWindow:w rect:&target]) {
   if(NSProcessInfo.processInfo.systemUptime<self.deadline)return;
   [self fail:@"Frame" reason:@"full-pane-rect-coordinate-or-hidden-SpringBoard-window-unverified-STOP"];return;
  }
  UIViewController *root=w.rootViewController;
  UIView *v=vc.viewIfLoaded;
  // Preserve parent/frame/subview order; do not change private scene settings directly.
  self.owner=vc;self.window=w;self.scene=DF182Scene(vc);
  self.oldParent=vc.parentViewController;self.oldSuperview=v.superview;
  self.oldIndex=[v.superview.subviews indexOfObject:v];self.oldFrame=v.frame;
  self.oldAutoresizing=v.autoresizingMask;self.target=target;
  UIView *pane=[[UIView alloc]initWithFrame:target];pane.clipsToBounds=YES;
  pane.backgroundColor=UIColor.clearColor;pane.userInteractionEnabled=YES;
  [root.view addSubview:pane];
  // Window rect -> root coordinates, measured rather than assuming matching origins.
  pane.frame=[root.view convertRect:target fromView:w];
  [vc willMoveToParentViewController:nil];[v removeFromSuperview];[vc removeFromParentViewController];
  [root addChildViewController:vc];v.frame=pane.bounds;
  v.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
  [pane addSubview:v];[vc didMoveToParentViewController:root];
  self.pane=pane;self.placed=YES;
  CGRect actual=[w convertRect:pane.bounds fromView:pane];
  if(!DF182Near(actual,target)||!pane.clipsToBounds||v.window!=w||vc.parentViewController!=root) {
   [self fail:@"Frame" reason:@"native-placement-readback-mismatch-STOP"];return;
  }
  self.gates[@"Frame"]=@"PASS";
  DF182Log(@"frame-placed",self.assignment,[NSString stringWithFormat:
   @"before=%@ before-coordinate=original-superview after=%@ coordinate=native-dashboard-UIWindow-points source-coordinate=external-UIScreen-points clipping=1 native-window-level=%.1f native-parent=%@ subview-index=%lu target-SpringBoard-window=hidden touch=UNVERIFIED",
   NSStringFromCGRect(self.oldFrame),NSStringFromCGRect(actual),(double)w.windowLevel,
   NSStringFromClass(root.class),(unsigned long)[root.view.subviews indexOfObject:pane]]);
  [self summary:@"native-placement-observed-vehicle-pixels-and-touch-required"];
 } else if(NSProcessInfo.processInfo.systemUptime>=self.deadline) {
  [self fail:@"Scene" reason:@"native-scene-provenance-timeout-10s-STOP-no-phone-fallback"];
 }
}
@end
void DF182RestoreAssignmentNow(NSString *assignmentID,NSString *reason) {
 if(NSThread.isMainThread && [DF182Owner.assignment[@"AssignmentID"] isEqual:assignmentID] && !DF182Owner.stopped) {
  [DF182Owner restore:reason];[DF182Owner summary:reason];
 }
}
static void DF182Poll(void) {
 @try{[DF182Owner tick];}
 @catch(NSException *e){[DF182Owner fail:@"Scene" reason:[@"exception-STOP-" stringByAppendingString:e.name?:@"unknown"]];}
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(.25*NSEC_PER_SEC)),dispatch_get_main_queue(),^{DF182Poll();});
}
__attribute__((constructor))static void DF182Start(void) {
 if(![NSProcessInfo.processInfo.processName isEqual:@"CarPlay"] ||
    NSProcessInfo.processInfo.operatingSystemVersion.majorVersion!=16)return;
 dispatch_async(dispatch_get_main_queue(),^{DF182Owner=[DF182MapsOwner new];DF182Poll();});
}
