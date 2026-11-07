// QA182 B1 NEW implementation; no historical three-hook source was recovered.
// Apple's native workspace/scene/input own Maps. No phone-scene fallback.
#import "../duoface-native-scene-host/DF182NativeMapAssignment.h"
#import "../duoface-native-scene-host/DF184NativeMapMembership.h"
#import "../duoface-native-scene-host/DF185LaunchAdmission.h"
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
#import "DF186NativePaneController.h"

@interface DF182MapsOwner:NSObject
@property(nonatomic,strong) NSDictionary *assignment;
@property(nonatomic,copy) NSDictionary *launchAssignment;
@property(nonatomic,strong) NSMutableDictionary *gates;
@property(nonatomic,weak) UIViewController *owner;
@property(nonatomic,weak) UIWindow *window;
@property(nonatomic,weak) id scene;
@property(nonatomic,strong) UIViewController *oldParent;
@property(nonatomic,strong) UIView *oldSuperview;
@property(nonatomic,strong) UIView *pane;
@property(nonatomic,strong) DF186NativePaneController *paneController;
@property(nonatomic,strong) UIView *mountedView;
@property(nonatomic,assign) BOOL refreshingLayout;
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
- (BOOL)layoutOwnedPane;
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
  // Audit16: this override changed a real 640x360 FBScene to 198x360.
  // Restoring controller.view does NOT reverse a private scene-size request.
  // Until the paired inverse scene-size transaction is verified, preserve
  // the OS frame byte-for-byte. This is safety only, not split-size PASS.
  DF182Log(@"scene-frame-original-preserved",DF182Owner.assignment,[NSString stringWithFormat:
   @"original=%@ requested-pane=%@ override=DISABLED native-split-size=UNVERIFIED",
   NSStringFromCGRect(r),NSStringFromCGRect(target)]);
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
    ![base isKindOfClass:UIViewController.class])return;
 UIViewController *vc=(UIViewController *)base;
 NSDictionary *currentChoice=[NSDictionary dictionaryWithContentsOfFile:DFNativeMapChoicePath];
 NSString *bundle=DF182Bundle(DF182Get(vc,"applicationInfo")?:DF182Get(vc,"proxyApplicationInfo"));
 if(!DF185LaunchIdentityMatches(owner.launchAssignment,currentChoice,bundle)) {
  DF182Log(@"present-identity-rejected",owner.assignment,
   @"source=captured-launch-assignment reason=replaced-unassigned-or-wrong-native-bundle");
  return;
 }
 if(![NSStringFromClass([root class]) isEqual:@"DBDashboardRootViewController"] ||
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

// Diagnostic only: missing values stay explicit; no fallback grants admission.
static id DF185Value(id value) { return value ?: @"<missing>"; }
static BOOL DF185Check(BOOL ok,NSString *stage,NSString *key,id actual,id expected,
                       NSString *source,NSDictionary *assignment) {
 if(!ok) {
  NSDictionary *picker=[NSDictionary dictionaryWithContentsOfFile:
   @"/var/mobile/Library/Preferences/com.duoface.nativehost.picker-evidence185.plist"];
  NSDictionary *record=@{@"stage":DF185Value(stage),@"key":key,
   @"actual":DF185Value(actual),@"expected":DF185Value(expected),@"source":source,
   @"pickerSource":@"/var/mobile/Library/Preferences/com.duoface.nativehost.picker-evidence185.plist",
   @"picker":DF185Value(picker),@"pickerRead":@"diagnostic-only-not-admission",
   @"assignment":DF185Value(assignment)};
  NSData *data=[NSJSONSerialization dataWithJSONObject:record options:NSJSONWritingSortedKeys error:nil];
  DF182Log(@"membership-reject-detail",assignment,data?
   [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]:@"diagnostic-serialization-failed");
 }
 return ok;
}
#define DF185_REQUIRE(ok,key,actual,expected,source) \
 do { if(!DF185Check((ok),stage,(key),(actual),(expected),(source),self.assignment)) return NO; } while(0)

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
 notify_post(DF184MapMembershipChanged); // Revoke or expiration restores prior pane.
}
- (BOOL)publishMembershipStage:(NSString *)stage controller:(UIViewController *)vc {
 BOOL committed=[stage isEqual:@"COMMITTED"],presented=[stage isEqual:@"PRESENTED"];
 DF185_REQUIRE(committed||presented,@"stage",stage,@"PRESENTED|COMMITTED",@"argument");
 DF185_REQUIRE(!self.stopped,@"stopped",@(self.stopped),@NO,@"DF182MapsOwner");
 DF185_REQUIRE(self.assignment!=nil,@"assignment",@(self.assignment!=nil),@YES,@"DF182MapsOwner");
 NSDictionary *choiceRead=[NSDictionary dictionaryWithContentsOfFile:DFNativeMapChoicePath];
 NSString *nativeBundle=DF182Bundle(DF182Get(vc,"applicationInfo")?:DF182Get(vc,"proxyApplicationInfo"));
 DF185_REQUIRE(DF185LaunchIdentityMatches(self.launchAssignment,choiceRead,nativeBundle),
  @"launchIdentity",choiceRead?:@{},self.launchAssignment?:@{},
  @"captured-launch-assignment versus atomic native-map-choice; no physical-pane session read");
 DF185_REQUIRE(vc==self.presentedController,@"presentedController",@(vc==self.presentedController),@YES,@"DF182MapsOwner");
 DF185_REQUIRE(DF182Scene(vc)==self.presentedScene,@"presentedScene",@(DF182Scene(vc)==self.presentedScene),@YES,@"controller.scene|sceneHandle.sceneIfExists");
 NSDictionary *provenance=DF182Provenance(vc);
 UIView *proofHost=DF182Get(vc,"sceneHostView"),*proofView=vc.viewIfLoaded;
 NSMutableDictionary *ownerProof=[provenance mutableCopy];
 ownerProof[@"sceneHostView.isUIView"]=@([proofHost isKindOfClass:UIView.class]);
 ownerProof[@"sceneHostView.isViewOrDescendant"]=@([proofHost isKindOfClass:UIView.class] && (proofHost==proofView||[proofHost isDescendantOfView:proofView]));
 ownerProof[@"sceneHostView.sameWindow"]=@([proofHost isKindOfClass:UIView.class] && proofHost.window==proofView.window);
 ownerProof[@"view.window.exists"]=@(proofView.window!=nil);
 ownerProof[@"parentViewController.exists"]=@(vc.parentViewController!=nil);
 DF185_REQUIRE(DF182NativeOwner(vc),@"nativeOwner",ownerProof,@"native CarPlay owner + attached host + parent",@"DF182NativeOwner(controller)");
 UIWindow *w=vc.viewIfLoaded.window;
 DF185_REQUIRE(w!=nil,@"window",@(w!=nil),@YES,@"controller.viewIfLoaded.window");
 DF185_REQUIRE(w==self.presentedWindow,@"presentedWindow",@(w==self.presentedWindow),@YES,@"DF182MapsOwner");
 DF185_REQUIRE(w==self.window,@"ownerWindow",@(w==self.window),@YES,@"DF182MapsOwner");
 DF185_REQUIRE(!w.hidden,@"hidden",@(w.hidden),@NO,@"controller.viewIfLoaded.window");
 DF185_REQUIRE(!(w.alpha<.95),@"alpha",@(w.alpha),@0.95,@"controller.viewIfLoaded.window; minimum");
 // Visibility is verified only AFTER identity admission, never during animated PRESENTED.
 if(committed) {
  DF185_REQUIRE(DF185PostAdmissionVisible(vc.viewIfLoaded.hidden,vc.viewIfLoaded.alpha),
   @"postAdmissionViewVisible",(@{@"hidden":@(vc.viewIfLoaded.hidden),@"alpha":@(vc.viewIfLoaded.alpha)}),
   @"hidden=false alpha>=0.95",@"COMMITTED controller.viewIfLoaded");
 }
 DF185_REQUIRE([NSStringFromClass(w.rootViewController.class) isEqual:@"DBDashboardRootViewController"],
  @"rootViewController.class",NSStringFromClass(w.rootViewController.class),@"DBDashboardRootViewController",@"window");
 // Target was measured before launch and captured beside that exact assignment.
 // Re-read live geometry only at COMMITTED/reflow, not to decide membership.
 CGRect target=CGRectFromString(self.launchAssignment[@"LaunchPaneFrame"]);
 if(committed)
  DF185_REQUIRE([self targetForWindow:w rect:&target],@"targetForWindow",@NO,@YES,@"COMMITTED live physical-target predicate record");
 DF185_REQUIRE(DF182Near(target,self.target),@"target",
  NSStringFromCGRect(target),NSStringFromCGRect(self.target),@"targetForWindow result versus DF182MapsOwner.target; tolerance=2");
 NSTimeInterval now=NSDate.date.timeIntervalSince1970;
 DF185_REQUIRE(isfinite(self.presentedAt),@"presentedAt.finite",@(isfinite(self.presentedAt)),@YES,@"DF182MapsOwner");
 DF185_REQUIRE(self.presentedAt>0,@"presentedAt",@(self.presentedAt),@">0",@"DF182MapsOwner");
 DF185_REQUIRE(now>=self.presentedAt,@"presentedAt",@(self.presentedAt),@(now),@"DF182MapsOwner; must not exceed now");
 DF185_REQUIRE(!presented||DF184Fresh(now,@(self.presentedAt),0.85),@"presentationAge",@(now-self.presentedAt),@0.85,@"DF182MapsOwner.presentedAt; max seconds");
 UIView *host=DF182Get(vc,"sceneHostView");
 BOOL hostAttached=[host isKindOfClass:UIView.class] &&
   (host==vc.viewIfLoaded || [host isDescendantOfView:vc.viewIfLoaded]) && host.window==w;
 DF185_REQUIRE(hostAttached,@"hostAttached",@(hostAttached),@YES,@"controller.sceneHostView");
 BOOL frameVerified=NO,hitVerified=NO;
 if(committed) {
  DF185_REQUIRE([self owns:vc],@"owns",@NO,@YES,@"DF182MapsOwner.owns");
  DF185_REQUIRE(vc.viewIfLoaded==self.mountedView,@"mountedView.identity",@(vc.viewIfLoaded==self.mountedView),@YES,@"exact UIView captured at adoption");
  DF185_REQUIRE(vc.parentViewController==self.paneController,@"paneController",@(vc.parentViewController==self.paneController),@YES,@"independent UIKit containment owner");
  DF185_REQUIRE(self.pane.clipsToBounds,@"clipsToBounds",@(self.pane.clipsToBounds),@YES,@"DF182MapsOwner.pane");
  DF185_REQUIRE(DF182Near(vc.viewIfLoaded.frame,self.pane.bounds),@"view.frame",NSStringFromCGRect(vc.viewIfLoaded.frame),NSStringFromCGRect(self.pane.bounds),@"pane bounds; tolerance=2");
  CGRect actual=[w convertRect:self.pane.bounds fromView:self.pane];
  frameVerified=DF182Near(target,actual);
  CGPoint center=CGPointMake(CGRectGetMidX(self.pane.bounds),CGRectGetMidY(self.pane.bounds));
  UIView *hit=[self.pane hitTest:center withEvent:nil];
  hitVerified=hit && (hit==vc.viewIfLoaded || [hit isDescendantOfView:vc.viewIfLoaded]);
  DF185_REQUIRE(frameVerified,@"paneFrame",NSStringFromCGRect(actual),NSStringFromCGRect(target),@"window converted pane.bounds; tolerance=2");
  DF185_REQUIRE(hitVerified,@"hitVerified",@(hitVerified),@YES,@"pane.hitTest:center");
 }
 NSString *sceneID=DF182String(DF182Get(DF182Scene(vc),"identifier"));
 DF185_REQUIRE(![sceneID isEqual:@"unknown"],@"identifier",sceneID,@"known",@"controller.scene");
 DF185_REQUIRE([w.windowScene.session.role isEqual:@"UIWindowSceneSessionRoleCarPlay"],@"role",DF185Value(w.windowScene.session.role),@"UIWindowSceneSessionRoleCarPlay",@"window.windowScene.session");
 DF185_REQUIRE(w.screen!=nil,@"screen.exists",@(w.screen!=nil),@YES,@"window");
 DF185_REQUIRE(w.screen!=UIScreen.mainScreen,@"screen.isMain",@(w.screen==UIScreen.mainScreen),@NO,@"window.screen versus UIScreen.mainScreen");
 NSDictionary *receipt=@{@"Version":@1,@"Process":@"CarPlay",
  @"Session":self.launchAssignment[@"Session"],@"HostSceneID":self.launchAssignment[@"HostSceneID"],
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
 DF185_REQUIRE(saved,@"writeToFile",@(saved),@YES,DF184MapMembershipPath);
 if(saved)notify_post(DF184MapMembershipChanged);
 if(saved && presented)DF182Log(@"identity-admitted",self.assignment,
  [NSString stringWithFormat:@"stage=PRESENTED source=launch-assignment viewHidden=%d pixels=UNVERIFIED touch=UNVERIFIED",
   vc.viewIfLoaded.hidden]);
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
  self.owner.viewIfLoaded==self.mountedView &&
  self.owner.parentViewController==self.paneController &&
  self.paneController.parentViewController==self.window.rootViewController &&
  self.mountedView.superview==self.pane && self.pane.window==self.window;
}
- (BOOL)restore:(NSString *)reason {
 self.stopped=YES; // Revokes swallow BEFORE containment is restored.
 self.paneController.layoutAuthorized=nil;
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
 if(verified){
  [self.paneController willMoveToParentViewController:nil];
  [self.pane removeFromSuperview];[self.paneController removeFromParentViewController];
  self.paneController=nil;self.mountedView=nil;self.pane=nil;self.placed=NO;
 }
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
 NSString *stage=@"physical-target";
 NSString *source=@"/var/mobile/Library/Preferences/com.duoface.nativehost.physical-panes.v1.plist";
 DF185_REQUIRE(window!=nil,@"window.exists",@(window!=nil),@YES,@"targetForWindow argument");
 DF185_REQUIRE(window.screen!=nil,@"screen.exists",@(window.screen!=nil),@YES,@"window");
 DF185_REQUIRE(window.screen!=UIScreen.mainScreen,@"screen.isMain",@(window.screen==UIScreen.mainScreen),@NO,@"window.screen versus UIScreen.mainScreen");
 NSDictionary *sample=[NSDictionary dictionaryWithContentsOfFile:source];
 double age=NSDate.date.timeIntervalSince1970-[sample[@"Timestamp"] doubleValue];
 DF185_REQUIRE([sample[@"Session"] isEqual:self.assignment[@"Session"]],@"Session",DF185Value(sample[@"Session"]),DF185Value(self.assignment[@"Session"]),source);
 DF185_REQUIRE([sample[@"Owner"] isEqual:@"SpringBoard"],@"Owner",DF185Value(sample[@"Owner"]),@"SpringBoard",source);
 DF185_REQUIRE([sample[@"ActiveSlots"] isEqual:@2],@"ActiveSlots",DF185Value(sample[@"ActiveSlots"]),@2,source);
 DF185_REQUIRE([sample[@"Focus"] isEqual:@(-1)],@"Focus",DF185Value(sample[@"Focus"]),@(-1),source);
 DF185_REQUIRE(isfinite(age),@"Timestamp.age.finite",@(isfinite(age)),@YES,source);
 DF185_REQUIRE(age>=0,@"Timestamp.age",@(age),@">=0",source);
 DF185_REQUIRE(age<=1.75,@"Timestamp.age",@(age),@1.75,source);
 NSArray *entries=sample[@"Windows"];
 DF185_REQUIRE([entries isKindOfClass:NSArray.class],@"Windows.type",DF185Value(entries),@"NSArray",source);
 DF185_REQUIRE(entries.count==2,@"Windows.count",@(entries.count),@2,source);
 for(NSDictionary *e in entries) {
  if(![e[@"PhysicalSlot"] isEqual:self.assignment[@"PhysicalSlot"]])continue;
  DF185_REQUIRE([e[@"NativeAssignmentID"] isEqual:self.assignment[@"AssignmentID"]],@"Windows[PhysicalSlot].NativeAssignmentID",e,self.assignment,source);
  // QA189 two-phase: old target is VISIBLE before native launch.
  // AFTER actual CarPlay PRESENTED, require independent hidden readback
  // before moving the native controller into its physical pane.
  BOOL requiresHidden=self.presentedAt>0 || self.placed;
  NSNumber *expectedVisible=requiresHidden?@NO:@YES;
  DF185_REQUIRE([e[@"WindowVisible"] isEqual:expectedVisible],
   @"Windows[PhysicalSlot].WindowVisible",DF185Value(e[@"WindowVisible"]),
   expectedVisible,requiresHidden?@"PRESENTED-or-COMMITTED-target-hidden":@"PRELAUNCH-target-visible");
  DF185_REQUIRE([e[@"OnExternalScreen"] isEqual:@YES],@"Windows[PhysicalSlot].OnExternalScreen",DF185Value(e[@"OnExternalScreen"]),@YES,source);
  DF185_REQUIRE([e[@"CoordinateSpace"] isEqual:@"external-UIScreen-points"],@"Windows[PhysicalSlot].CoordinateSpace",DF185Value(e[@"CoordinateSpace"]),@"external-UIScreen-points",source);
  CGRect screenRect=CGRectFromString(e[@"Frame"]);
  DF185_REQUIRE(isfinite(screenRect.origin.x),@"Windows[PhysicalSlot].Frame.x.finite",e,@YES,source);
  DF185_REQUIRE(isfinite(screenRect.origin.y),@"Windows[PhysicalSlot].Frame.y.finite",e,@YES,source);
  DF185_REQUIRE(isfinite(screenRect.size.width),@"Windows[PhysicalSlot].Frame.width.finite",e,@YES,source);
  DF185_REQUIRE(isfinite(screenRect.size.height),@"Windows[PhysicalSlot].Frame.height.finite",e,@YES,source);
  DF185_REQUIRE(!(screenRect.size.width<90),@"Windows[PhysicalSlot].Frame.width",@(screenRect.size.width),@90,source);
  DF185_REQUIRE(!(screenRect.size.height<120),@"Windows[PhysicalSlot].Frame.height",@(screenRect.size.height),@120,source);
  DF185_REQUIRE(CGRectContainsRect(window.screen.bounds,screenRect),@"Windows[PhysicalSlot].Frame.screenContainment",NSStringFromCGRect(screenRect),NSStringFromCGRect(window.screen.bounds),source);
  for(NSDictionary *other in entries) {
   if(other==e)continue;
   DF185_REQUIRE([other[@"CoordinateSpace"] isEqual:@"external-UIScreen-points"],@"Windows[peer].CoordinateSpace",DF185Value(other[@"CoordinateSpace"]),@"external-UIScreen-points",source);
   CGRect intersection=CGRectIntersection(screenRect,CGRectFromString(other[@"Frame"]));
   DF185_REQUIRE(CGRectIsNull(intersection)||!(intersection.size.width>2 && intersection.size.height>2),@"Windows.intersection",NSStringFromCGRect(intersection),@"no overlap >2 points",source);
  }
  *out=[window convertRect:screenRect fromCoordinateSpace:window.screen.coordinateSpace];
  DF185_REQUIRE(CGRectContainsRect(window.bounds,*out),@"convertedTarget.windowContainment",NSStringFromCGRect(*out),NSStringFromCGRect(window.bounds),@"window.convertRect from screen.coordinateSpace");
  return YES;
 }
 DF185_REQUIRE(NO,@"Windows.PhysicalSlot",entries,DF185Value(self.assignment[@"PhysicalSlot"]),source);
 return NO;
}
- (BOOL)layoutOwnedPane {
 if(self.refreshingLayout || ![self owns:self.owner])return NO;
 CGRect target=CGRectZero;
 if(![self targetForWindow:self.window rect:&target])return NO;
 self.refreshingLayout=YES;
 @try {
  UIView *root=self.window.rootViewController.view;
  CGRect before=self.mountedView.frame;
  self.pane.frame=[root convertRect:target fromView:self.window];
  self.target=target;
  [self.pane setNeedsLayout];[self.pane layoutIfNeeded];
  [self.paneController layoutNativeContent];
  CGRect actual=[self.window convertRect:self.pane.bounds fromView:self.pane];
  BOOL verified=[self owns:self.owner] && DF182Near(actual,target) &&
    DF182Near(self.mountedView.frame,self.pane.bounds);
  if(!DF182Near(before,self.mountedView.frame))
   DF182Log(@"pane-layout-reconciled",self.assignment,[NSString stringWithFormat:
    @"view=%p controller=%p sceneHostView=%p before=%@ after=%@ pane=%@ post-layout-verified=%d",
    self.mountedView,self.owner,DF182Get(self.owner,"sceneHostView"),
    NSStringFromCGRect(before),NSStringFromCGRect(self.mountedView.frame),
    NSStringFromCGRect(self.pane.bounds),verified]);
  return verified;
 } @finally {self.refreshingLayout=NO;}
}
- (void)tick {
 NSDictionary *current=DF182Assignment();
 if(![current[@"AssignmentID"] isEqual:self.assignment[@"AssignmentID"]]) {
  if(self.assignment && !self.stopped){[self restore:@"Home-replaced-unassigned-disconnected-or-stale-session"];[self summary:@"assignment-released"];}
  if(!current || self.placed)return; // A failed restore blocks further foreign scene mutation.
  self.assignment=current;self.launchAssignment=nil;self.stopped=NO;self.launchAttempted=NO;self.provenance=nil;
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
  // Capture exact launch identity once. It survives a delayed geometry snapshot;
  // replacement/Home still invalidates it through the atomic assignment.
  NSMutableDictionary *launchRecord=[self.assignment mutableCopy];
  launchRecord[@"LaunchPaneFrame"]=NSStringFromCGRect(measured);
  self.launchAssignment=[launchRecord copy];
  DF182Log(@"launch-identity-captured",self.launchAssignment,
   [NSString stringWithFormat:@"source=assignment-at-native-launch origin=%@ frame=%@",
    self.launchAssignment[@"RequestOrigin"]?:@"unknown",self.launchAssignment[@"LaunchPaneFrame"]]);
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
  // Reconcile the owned UIKit layout before sampling its post-layout state.
  // Identity/scene/window loss still fails immediately; no grace lease.
  if(![self layoutOwnedPane]) {
   [self fail:@"Frame" reason:@"native-owner-or-live-pane-binding-lost-STOP"];return;
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
  // Post-admission rendering/input gate. Never force UIKit visibility or renew
  // an uncommitted PRESENTED lease indefinitely.
  if(!DF185PostAdmissionVisible(vc.viewIfLoaded.hidden,vc.viewIfLoaded.alpha)) {
   DF182Log(@"post-admission-visibility",self.assignment,
    [NSString stringWithFormat:@"stage=WAIT hidden=%d alpha=%.3f presentedAge=%.3f pixels=UNVERIFIED touch=UNVERIFIED",
     vc.viewIfLoaded.hidden,(double)vc.viewIfLoaded.alpha,
     NSDate.date.timeIntervalSince1970-self.presentedAt]);
   if(!DF184Fresh(NSDate.date.timeIntervalSince1970,@(self.presentedAt),0.85))
    [self fail:@"Frame" reason:@"post-admission-visible-view-timeout-STOP"];
   return;
  }
  // PRESENTED is a short, bounded grant. Never extend it while waiting
  // for the target UIWindow to yield; fail and restore after its 0.85s.
  if(!DF184Fresh(NSDate.date.timeIntervalSince1970,@(self.presentedAt),0.85)) {
   [self fail:@"Frame" reason:@"presented-target-yield-expired-before-COMMITTED-STOP"];return;
  }
  CGRect target=CGRectZero;
  if(![self targetForWindow:w rect:&target]) {
   if(NSProcessInfo.processInfo.systemUptime<self.deadline)return;
   [self fail:@"Frame" reason:@"full-pane-rect-coordinate-or-hidden-SpringBoard-window-unverified-STOP"];return;
  }
  UIViewController *root=w.rootViewController;
  UIView *v=vc.viewIfLoaded;
  // Preserve original parent/frame/order for rollback; native sceneFrame hook owns requested size.
  self.owner=vc;self.window=w;self.scene=DF182Scene(vc);
  self.oldParent=vc.parentViewController;self.oldSuperview=v.superview;
  self.oldIndex=[v.superview.subviews indexOfObject:v];self.oldFrame=v.frame;
  self.oldAutoresizing=v.autoresizingMask;self.target=target;
  DF186NativePaneController *container=[DF186NativePaneController new];
  self.paneController=container;self.mountedView=v;
  [root addChildViewController:container];
  UIView *pane=container.view;
  pane.frame=[root.view convertRect:target fromView:w];
  [root.view addSubview:pane];[container didMoveToParentViewController:root];
  [vc willMoveToParentViewController:nil];[v removeFromSuperview];[vc removeFromParentViewController];
  [container addChildViewController:vc];v.frame=pane.bounds;
  v.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
  [pane addSubview:v];[vc didMoveToParentViewController:container];
  container.nativeController=vc;container.mountedView=v;
  self.pane=pane;self.placed=YES;
  __weak DF182MapsOwner *weakOwner=self;
  container.layoutAuthorized=^BOOL{ return [weakOwner owns:weakOwner.owner]; };
  if(![self layoutOwnedPane]) {
   [self fail:@"Frame" reason:@"native-placement-readback-mismatch-STOP"];return;
  }
  CGRect actual=[w convertRect:pane.bounds fromView:pane];
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
