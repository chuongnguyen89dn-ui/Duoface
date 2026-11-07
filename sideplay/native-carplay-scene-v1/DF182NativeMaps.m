// QA182 B1 NEW implementation; no historical three-hook source was recovered.
// Apple's native workspace/scene/input own Maps. No phone-scene fallback.
#import "../duoface-native-scene-host/DF182NativeMapAssignment.h"
#import "../duoface-native-scene-host/DF184NativeMapMembership.h"
#import <UIKit/UIKit.h>
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
@property(nonatomic,weak) UIViewController *presentedController;
@property(nonatomic,weak) UIWindow *presentedWindow;
@property(nonatomic,weak) id presentedScene;
@property(nonatomic,assign) NSTimeInterval presentedAt;
- (void)clearMembership;
- (BOOL)publishMembershipStage:(NSString *)stage controller:(UIViewController *)vc;
- (BOOL)ownsOrPresenting:(id)controller;
- (void)tick;
- (void)summary:(NSString *)reason;
- (void)fail:(NSString *)gate reason:(NSString *)reason;
- (BOOL)owns:(id)controller;
- (BOOL)targetForWindow:(UIWindow *)window rect:(CGRect *)out;
- (BOOL)restore:(NSString *)reason;
@end
static DF182MapsOwner *DF182Owner;
static CGRect (*DF182OriginalFrame)(id,SEL,id,id);
static void (*DF182OriginalPresent)(id,SEL,id,BOOL,NSUInteger,id);
static void (*DF182OriginalDeactivate)(id,SEL,NSUInteger);
static void (*DF182OriginalBackground)(id,SEL,id);
typedef void(*DF182Hook)(Class,SEL,IMP,IMP*);
static CGRect DF182Frame(id obj,SEL sel,id info,id proxy) {
 CGRect r=DF182OriginalFrame(obj,sel,info,proxy);
 // Size is needed DURING native creation, before there is a controller to adopt.
 // No lifecycle protection is granted here; that still requires a verified live scene.
 CGRect target=CGRectZero;
 if(!DF182Owner.stopped && DF182Owner.assignment &&
   [DF182Owner.assignment[@"AssignmentID"] isEqual:DF182Assignment()[@"AssignmentID"]] &&
   ([DF182Bundle(info) isEqual:@"com.google.Maps"] || [DF182Bundle(proxy) isEqual:@"com.google.Maps"]) &&
   [DF182Owner targetForWindow:DF182Owner.window rect:&target]) {
  CGRect before=r;r.size=target.size;
  DF182Log(@"scene-frame-request",DF182Owner.assignment,[NSString stringWithFormat:
   @"before=%@ after=%@ coordinate=system-scene-frame-origin-preserved size-source=native-dashboard-UIWindow-points placement=UNVERIFIED",
   NSStringFromCGRect(before),NSStringFromCGRect(r)]);
 }
 return r;
}
// Admission begins at the actual Apple presentation gate (post-original).
// A launch request or assignment intent is not native Maps pane ownership.
static void DF182Present(id root,SEL sel,id base,BOOL animated,
                         NSUInteger source,id completion) {
 DF182OriginalPresent(root,sel,base,animated,source,completion);
 DF182MapsOwner *owner=DF182Owner;
 if(!owner || owner.stopped || !owner.assignment || source!=0 ||
    ![owner.assignment[@"AssignmentID"] isEqual:DF182Assignment()[@"AssignmentID"]] ||
    ![base isKindOfClass:UIViewController.class])return;
 UIViewController *vc=(UIViewController *)base;
 if(![NSStringFromClass(root.class) isEqual:@"DBDashboardRootViewController"] ||
    ![NSStringFromClass(vc.class) isEqual:@"DBApplicationSceneViewController"] ||
    vc.viewIfLoaded.window.rootViewController!=root ||
    vc.viewIfLoaded.window!=owner.window || !DF182NativeOwner(vc))return;
 owner.presentedController=vc;
 owner.presentedWindow=vc.viewIfLoaded.window;
 owner.presentedScene=DF182Scene(vc);
 owner.presentedAt=NSDate.date.timeIntervalSince1970;
 if(![owner publishMembershipStage:@"PRESENTED" controller:vc]) {
  owner.presentedController=nil;owner.presentedWindow=nil;
  owner.presentedScene=nil;owner.presentedAt=0;
  DF182Log(@"present-member-rejected",owner.assignment,
   @"native-scene-or-physical-pane-proof-rejected-post-original");
  return;
 }
 DF182Log(@"present-member",owner.assignment,
   @"stage=PRESENTED actor=CarPlay CarPlay-window-verified=1 awaiting-pane-commit");
}
static void DF182Deactivate(id obj,SEL sel,NSUInteger mask) {
 if([DF182Owner ownsOrPresenting:obj]) {
  DF182Owner.gates[@"Lifecycle"]=@"PASS";
  DF182Log(@"lifecycle-swallowed",DF182Owner.assignment,
   [NSString stringWithFormat:@"method=deactivateSceneWithReasonMask: mask=%lu",(unsigned long)mask]);
  return;
 }
 DF182OriginalDeactivate(obj,sel,mask);
}
#import "../duoface-native-scene-host/DF182BlockCompletionABI.h"
static void DF182Background(id obj,SEL sel,id completion) {
 if([DF182Owner ownsOrPresenting:obj]) {
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
 if(DF182OriginalFrame && DF182OriginalDeactivate && DF182OriginalBackground &&
    DF182OriginalPresent)return YES;
 Class dash=objc_getClass("DBDashboard"),vc=objc_getClass("DBApplicationSceneViewController");
 Class root=objc_getClass("DBDashboardRootViewController");
 BOOL frame=DF182Method(dash,"sceneFrameForAppInfo:proxyAppInfo:",@encode(CGRect),@[@"@",@"@"],a);
 BOOL deactivate=DF182Method(vc,"deactivateSceneWithReasonMask:",@encode(void),@[[NSString stringWithUTF8String:@encode(NSUInteger)]],a);
 BOOL background=DF182Method(vc,"backgroundSceneWithCompletion:",@encode(void),@[@"@?"],a);
 BOOL present=DF182Method(root,"presentBaseViewController:animated:launchSource:completion:",
    @encode(void),@[@"@",@"B",@"Q",@"@?"],a);
 DF182Hook hook=(DF182Hook)dlsym(RTLD_DEFAULT,"MSHookMessageEx");
 if(!frame||!deactivate||!background||!present||!hook)return NO; // No partial installation.
 hook(root,sel_registerName("presentBaseViewController:animated:launchSource:completion:"),
   (IMP)DF182Present,(IMP*)&DF182OriginalPresent);
 hook(dash,sel_registerName("sceneFrameForAppInfo:proxyAppInfo:"),(IMP)DF182Frame,(IMP*)&DF182OriginalFrame);
 hook(vc,sel_registerName("deactivateSceneWithReasonMask:"),(IMP)DF182Deactivate,(IMP*)&DF182OriginalDeactivate);
 hook(vc,sel_registerName("backgroundSceneWithCompletion:"),(IMP)DF182Background,(IMP*)&DF182OriginalBackground);
 return DF182OriginalFrame && DF182OriginalDeactivate && DF182OriginalBackground && DF182OriginalPresent;
}
@implementation DF182MapsOwner
- (void)clearMembership {
 NSDictionary *old=[NSDictionary dictionaryWithContentsOfFile:DF184MapMembershipPath];
 if(![old[@"Session"] isEqual:self.assignment[@"Session"]] ||
    ![old[@"AssignmentID"] isEqual:self.assignment[@"AssignmentID"]])return;
 NSMutableDictionary *dead=[old mutableCopy];
 dead[@"Stage"]=@"REVOKED";dead[@"PaneBound"]=@NO;
 dead[@"PaneFrameVerified"]=@NO;
 dead[@"Timestamp"]=@(NSDate.date.timeIntervalSince1970);
 if(![dead writeToFile:DF184MapMembershipPath atomically:YES])
  (void)[NSFileManager.defaultManager removeItemAtPath:DF184MapMembershipPath error:nil];
}
- (BOOL)publishMembershipStage:(NSString *)stage controller:(UIViewController *)vc {
 BOOL committed=[stage isEqual:@"COMMITTED"],presented=[stage isEqual:@"PRESENTED"];
 if((!committed&&!presented)||self.stopped||!self.assignment||
    ![self.assignment[@"AssignmentID"] isEqual:DF182Assignment()[@"AssignmentID"]] ||
    vc!=self.presentedController || DF182Scene(vc)!=self.presentedScene ||
    !DF182NativeOwner(vc))return NO;
 UIWindow *w=vc.viewIfLoaded.window;
 if(!w || w!=self.presentedWindow || w!=self.window ||
    w.hidden || w.alpha<.95 || vc.viewIfLoaded.hidden ||
    vc.viewIfLoaded.alpha<.95 ||
    ![NSStringFromClass(w.rootViewController.class) isEqual:@"DBDashboardRootViewController"])
  return NO;
 CGRect target=CGRectZero;
 if(![self targetForWindow:w rect:&target] || !DF182Near(target,self.target))
  return NO;
 NSTimeInterval now=NSDate.date.timeIntervalSince1970;
 if(!isfinite(self.presentedAt)||self.presentedAt<=0||now<self.presentedAt ||
    (presented && !DF184Fresh(now,@(self.presentedAt),0.85)))return NO;
 UIView *host=DF182Get(vc,"sceneHostView");
 BOOL hostAttached=[host isKindOfClass:UIView.class] &&
   (host==vc.viewIfLoaded || [host isDescendantOfView:vc.viewIfLoaded]) &&
   host.window==w;
 if(!hostAttached)return NO;
 BOOL frameVerified=NO,hitVerified=NO;
 if(committed) {
  if(![self owns:vc] || !self.pane.clipsToBounds ||
     !DF182Near(vc.viewIfLoaded.frame,self.pane.bounds))return NO;
  CGRect actual=[w convertRect:self.pane.bounds fromView:self.pane];
  frameVerified=DF182Near(target,actual);
  CGPoint center=CGPointMake(CGRectGetMidX(self.pane.bounds),CGRectGetMidY(self.pane.bounds));
  UIView *hit=[self.pane hitTest:center withEvent:nil];
  hitVerified=hit && (hit==vc.viewIfLoaded ||
                       [hit isDescendantOfView:vc.viewIfLoaded]);
  if(!frameVerified || !hitVerified)return NO;
 }
 NSDictionary *pulse=DF182Pulse();
 NSString *sceneID=DF182String(DF182Get(DF182Scene(vc),"identifier"));
 if(!DF184UUID(pulse[@"Session"]) ||
    ![pulse[@"Session"] isEqual:self.assignment[@"Session"]] ||
    ![pulse[@"Active"] isEqual:@YES] ||
    ![pulse[@"HostSceneID"] isKindOfClass:NSString.class] ||
    [pulse[@"HostSceneID"] length]==0 ||
    [sceneID isEqual:@"unknown"] || ![w.windowScene.session.role isEqual:
      @"UIWindowSceneSessionRoleCarPlay"] || !w.screen ||
    w.screen==UIScreen.mainScreen)return NO;
 NSDictionary *receipt=@{@"Version":@1,@"Process":@"CarPlay",
  @"Session":pulse[@"Session"],@"HostSceneID":pulse[@"HostSceneID"],
  @"AssignmentID":self.assignment[@"AssignmentID"],
  @"PhysicalSlot":self.assignment[@"PhysicalSlot"],@"BundleID":@"com.google.Maps",
  @"ControllerClass":@"DBApplicationSceneViewController",
  @"SceneClass":@"FBScene",@"NativeSceneID":sceneID,
  @"PresentationSource":@"DBDashboardRootViewController.presentBase:post-original",
  @"WindowRole":@"UIWindowSceneSessionRoleCarPlay",
  @"WindowExternal":@YES,@"WindowVisible":@YES,
  @"SceneHostAttached":@YES,
  @"PaneBound":@(committed),@"PaneFrameVerified":@(frameVerified),
  @"HitRegionVerified":@(hitVerified),
  @"PaneFrame":NSStringFromCGRect(target),
  @"Stage":stage,@"PresentedAt":@(self.presentedAt),@"Timestamp":@(now)};
 BOOL saved=[receipt writeToFile:DF184MapMembershipPath atomically:YES];
 if(saved && committed)DF182Log(@"pane-member-committed",self.assignment,
   [NSString stringWithFormat:@"scene=%@ slot=%@ frame=%@ stage=COMMITTED hit-region-readback=1 actual-pixels=UNVERIFIED",
    sceneID,self.assignment[@"PhysicalSlot"],NSStringFromCGRect(target)]);
 return saved;
}
- (BOOL)ownsOrPresenting:(id)controller {
 if([self owns:controller])return YES;
 if(self.stopped||!self.presentedAt||controller!=self.presentedController ||
    DF182Scene(controller)!=self.presentedScene ||
    !DF182NativeOwner(controller) ||
    !DF184Fresh(NSDate.date.timeIntervalSince1970,@(self.presentedAt),0.85))
  return NO;
 NSDictionary *receipt=[NSDictionary dictionaryWithContentsOfFile:DF184MapMembershipPath];
 return [receipt[@"Stage"] isEqual:@"PRESENTED"] &&
   [receipt[@"Session"] isEqual:self.assignment[@"Session"]] &&
   [receipt[@"AssignmentID"] isEqual:self.assignment[@"AssignmentID"]] &&
   [receipt[@"NativeSceneID"] isEqual:DF182String(DF182Get(DF182Scene(controller),"identifier"))] &&
   DF184Fresh(NSDate.date.timeIntervalSince1970,receipt[@"Timestamp"],0.85);
}
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
 [self clearMembership];
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
 if(verified){self.oldParent=nil;self.oldSuperview=nil;self.owner=nil;self.scene=nil;self.window=nil;}
 return verified;
}
- (void)fail:(NSString *)gate reason:(NSString *)reason {
 self.gates[gate]=@"FAIL";
 [self restore:reason];
 if([DF182Assignment()[@"AssignmentID"] isEqual:self.assignment[@"AssignmentID"]])
   DF182Revoke(reason?:@"native-pane-admission-failed");
 [self summary:reason];
}
- (BOOL)targetForWindow:(UIWindow *)window rect:(CGRect *)out {
 if(!window || !window.screen || window.screen==UIScreen.mainScreen)return NO;
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
     ![e[@"WindowVisible"] isEqual:@NO] ||
     ![e[@"OnExternalScreen"] isEqual:@YES] ||
     ![e[@"CoordinateSpace"] isEqual:@"external-UIScreen-points"])return NO;
  CGRect screenRect=CGRectFromString(e[@"Frame"]);
  if(!isfinite(screenRect.origin.x)||!isfinite(screenRect.origin.y)||
     !isfinite(screenRect.size.width)||!isfinite(screenRect.size.height)||
     screenRect.size.width<90||screenRect.size.height<120 ||
     !CGRectContainsRect(window.screen.bounds,screenRect))return NO;
  for(NSDictionary *other in entries) {
   if(other==e)continue;
   if(![other[@"CoordinateSpace"] isEqual:@"external-UIScreen-points"])return NO;
   CGRect intersection=CGRectIntersection(screenRect,CGRectFromString(other[@"Frame"]));
   if(!CGRectIsNull(intersection) && intersection.size.width>2 && intersection.size.height>2)return NO;
  }
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
  self.presentedController=nil;self.presentedWindow=nil;self.presentedScene=nil;self.presentedAt=0;
  self.gates=[@{@"Catalog":@"UNVERIFIED",@"Launch":@"UNVERIFIED",@"Scene":@"UNVERIFIED",@"Frame":@"UNVERIFIED",@"Lifecycle":@"UNVERIFIED"} mutableCopy];
  self.deadline=NSProcessInfo.processInfo.systemUptime+10.0;
  if(!DF182InstallHooks(current)){[self fail:@"Scene" reason:@"required-hook-ABI-missing-or-mismatched-STOP"];return;}
 }
 if(self.stopped||!self.assignment)return;
 if(!self.launchAttempted) {
  // A fresh single-writer geometry receipt must exist BEFORE launch invokes sceneFrame.
  NSMutableArray<UIWindow *> *windows=[NSMutableArray new];
  for(UIScene *s in UIApplication.sharedApplication.connectedScenes) {
   if(![s isKindOfClass:UIWindowScene.class])continue;
   UIWindowScene *ws=(UIWindowScene *)s;
   if(ws.screen==UIScreen.mainScreen || ![ws.session.role isEqual:@"UIWindowSceneSessionRoleCarPlay"])continue;
   for(UIWindow *w in ws.windows)
    if(!w.hidden && [NSStringFromClass(w.rootViewController.class) isEqual:@"DBDashboardRootViewController"])
     [windows addObject:w];
  }
  CGRect measured=CGRectZero;
  if(windows.count!=1 || ![self targetForWindow:windows.firstObject rect:&measured]) {
   if(NSProcessInfo.processInfo.systemUptime>=self.deadline)
    [self fail:@"Frame" reason:@"prelaunch-native-window-or-single-writer-geometry-timeout-STOP"];
   return;
  }
  self.window=windows.firstObject;self.target=measured;
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
  if(![self publishMembershipStage:@"COMMITTED" controller:self.owner]) {
   [self fail:@"Frame" reason:@"committed-native-pane-attestation-lost-STOP"];return;
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
 if(candidates.count==1 && candidates.firstObject==self.presentedController &&
    DF182NativeOwner(candidates.firstObject)) {
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
  if(![self publishMembershipStage:@"COMMITTED" controller:vc]) {
   [self fail:@"Frame" reason:@"presented-scene-not-committed-to-verified-pane-STOP"];return;
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
