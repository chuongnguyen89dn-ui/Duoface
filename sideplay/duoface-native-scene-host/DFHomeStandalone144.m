// Independent QA144 native CarPlay Home -> single-app scene bridge (no DuoFace split UI).
// Source-only staging: requires explicit new opt-in and real owner/ABI check.
// Do NOT publish Sileo until original-native scene/interaction parity is observed.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <notify.h>
#import <math.h>
#import <fcntl.h>
#import <unistd.h>
#import <signal.h>
#import <errno.h>
#import <limits.h>
#import <dlfcn.h>
#import <string.h>
#import "DFHome145Consent.h"
#import "DFEnabledAppsPolicy.h"
#if defined(DF144_SPRINGBOARD)
#import "DFSceneHost.h"
#import "DF154AppStateProtocol.h"
#import "DFHostedMapRenderSize.h"
#endif

static NSString *const DF144Request=@"/var/mobile/Library/Preferences/com.duoface.nativehost.standalone144-request.plist";
static NSString *const DF144Result=@"/var/mobile/Library/Preferences/com.duoface.nativehost.standalone144-result.plist";
static NSString *const DF144LeasePath=@"/var/mobile/Library/Preferences/com.duoface.nativehost.standalone144-sb-lease.plist";
static NSString *const DF144LogPath=@"/var/mobile/Library/Logs/DuoFaceStandalone144.log";
static const char *const DF144RequestNotify="com.duoface.nativehost.standalone144.request";
static const char *const DF144StopNotify="com.duoface.nativehost.standalone144.stop";
static const char *const DF148WatchdogStopNotify="com.duoface.nativehost.standalone144.stop.pending-watchdog";
static const char *const DF148NativeSwitchStopNotify="com.duoface.nativehost.standalone144.stop.native-switch";
static const char *const DF148OwnerRevokeStopNotify="com.duoface.nativehost.standalone144.stop.owner-revoke";
static const char *const DF144ResultNotify="com.duoface.nativehost.standalone144.result";
static NSString *const DF144HostApp=@"com.duoface.native.scenehost";
static void DF144Log(NSString *tag,NSString *detail) {
 NSString *line=[NSString stringWithFormat:@"[DFStandalone144] time=%.3f process=%@ stage=%@ %@\n",
  NSDate.date.timeIntervalSince1970,NSProcessInfo.processInfo.processName,tag,detail?:@""];
 int fd=open(DF144LogPath.fileSystemRepresentation,O_WRONLY|O_APPEND|O_CREAT,0644);
 if(fd<0)return;
 NSData *d=[line dataUsingEncoding:NSUTF8StringEncoding];
 if(d.length)(void)write(fd,d.bytes,d.length);
 close(fd);
}
#import "DFWorkspaceABIProbe150.h"
static BOOL DF144ExplicitConsent(void) { return DFHome145Enabled(); }
static BOOL DF144Allowed(NSString *bid) {
 return DF144ExplicitConsent() &&
        [bid isKindOfClass:NSString.class] && ![bid isEqualToString:DF144HostApp] &&
        DFIsRecommendedAppID(bid) &&
        DFPickerAllowsApp(bid,DFConfiguredEnabledAppIDs());
}
static id DF144Get(id object,const char *getter) {
 if(!object)return nil;
 SEL sel=sel_registerName(getter);
 Method m=class_getInstanceMethod(object_getClass(object),sel);
 if(!m || strcmp(method_getTypeEncoding(m),"@16@0:8")!=0)return nil;
 @try{return ((id (*)(id,SEL))objc_msgSend)(object,sel);}
 @catch(__unused NSException *e){return nil;}
}
#if defined(DF144_CARPLAY)
static NSString *DF144Bundle(id object,int depth) {
 if(!object || depth>=3)return nil;
 const char *const name[]={"bundleIdentifier","bundleID","applicationIdentifier","displayIdentifier",NULL};
 for(int i=0;name[i];i++){
  id val=DF144Get(object,name[i]);
  if([val isKindOfClass:NSString.class] && [val length])return val;
 }
 const char *const child[]={"application","representedApplication","applicationInfo","icon","representedIcon","model",NULL};
 for(int i=0;child[i];i++){
  id c=DF144Get(object,child[i]);
  if(c && c!=object){NSString *bid=DF144Bundle(c,depth+1);if(bid.length)return bid;}
 }
 return nil;
}
#endif
static BOOL DF144ValidRect(CGRect r,CGRect whole) {
 return isfinite(r.origin.x)&&isfinite(r.origin.y)&&isfinite(r.size.width)&&
        isfinite(r.size.height)&&whole.size.width>=300&&whole.size.height>=145&&
        r.size.width>=300&&r.size.height>=145&&
        CGRectContainsRect(CGRectInset(whole,-1.5,-1.5),r);
}
static BOOL DF144ValidRequest(NSDictionary *p,NSTimeInterval now) {
 if(![p isKindOfClass:NSDictionary.class] || ![p[@"Version"] isEqual:@1] ||
    ![p[@"Origin"] isEqualToString:@"CarPlayHomeStandalone144"] ||
    ![p[@"RequestID"] isKindOfClass:NSString.class] ||
    ![[NSUUID alloc] initWithUUIDString:p[@"RequestID"]] ||
    ![p[@"BundleID"] isKindOfClass:NSString.class] ||
    ![p[@"CarDisplayID"] isKindOfClass:NSString.class] ||
    ![p[@"ContentRect"] isKindOfClass:NSString.class] ||
    ![p[@"ScreenBounds"] isKindOfClass:NSString.class] ||
    ![p[@"Timestamp"] isKindOfClass:NSNumber.class])return NO;
 NSTimeInterval age=now-[p[@"Timestamp"] doubleValue];
 CGRect whole=CGRectFromString(p[@"ScreenBounds"]),content=CGRectFromString(p[@"ContentRect"]);
 return isfinite(age)&&age>=0&&age<=2.0&&DF144ValidRect(content,whole);
}
#if defined(DF144_CARPLAY)
// Original real iOS16 Home tap ABI from user's physical Log21; no substitute
// DuoFace icon, no app picker, no accidental native-app click override.
static void (*DF144Original)(id,SEL,id,id);
static void (*DF144OriginalHomeAppear)(id,SEL,BOOL);
static NSTimeInterval DF144LastHomeRequest;
static void DF152RevokeNativePreparation(void);
static void DF144HomeAppeared(id owner,SEL sel,BOOL animated) {
 DF144OriginalHomeAppear(owner,sel,animated);
 // Home/Back must revoke ONLY a prior standalone scene (not a brand-new tap).
 if(DF144LastHomeRequest>0 &&
    NSDate.date.timeIntervalSince1970-DF144LastHomeRequest>0.7) {
   DF144Log(@"native-home-return",@"revoke-standalone-only");
   DF152RevokeNativePreparation();
   notify_post(DF144StopNotify);
 }
}

typedef void (*DF144Hook)(Class,SEL,IMP,IMP*);
#import "DF151WorkspaceOwnerCapture.h"
static UIWindow *DF144UniqueNativeContentWindow(CGRect *frame,CGRect *whole,NSString **displayID) {
 NSMutableOrderedSet<UIWindow *> *windows=[NSMutableOrderedSet orderedSetWithArray:UIApplication.sharedApplication.windows];
 for(UIScene *scene in UIApplication.sharedApplication.connectedScenes)
  if([scene isKindOfClass:UIWindowScene.class])
    [windows addObjectsFromArray:((UIWindowScene *)scene).windows];
 UIWindow *result=nil;NSUInteger pairs=0;
 for(UIWindow *rail in windows) {
  if(![@[@"DBStatusBarWindow",@"CARStatusBarWindow"] containsObject:NSStringFromClass(rail.class)] ||
     rail.hidden || rail.alpha<.95 || !rail.screen ||
     rail.screen==UIScreen.mainScreen || !rail.windowScene ||
     ![rail.windowScene.session.role isEqualToString:@"UIWindowSceneSessionRoleCarPlay"] ||
     rail.windowScene.activationState==UISceneActivationStateBackground ||
     ![NSStringFromClass(rail.rootViewController.class) isEqualToString:@"DBRootStatusBarViewController"])continue;
  CGRect screen=rail.screen.bounds;
  CGRect dockrail=[rail convertRect:rail.bounds toCoordinateSpace:rail.screen.coordinateSpace];
  if(dockrail.size.width<20 || dockrail.size.width>=screen.size.width*.30 ||
     fabs(CGRectGetMinX(dockrail)-CGRectGetMinX(screen))>1.5)continue;
  for(UIWindow *window in windows) {
    if(![NSStringFromClass(window.class) isEqualToString:@"DBNotificationWindow"] ||
       window.hidden || window.alpha<.9 || window.screen!=rail.screen ||
       !window.windowScene ||
       ![window.windowScene.session.role isEqualToString:@"UIWindowSceneSessionRoleCarPlay"])continue;
    CGRect content=[window convertRect:window.bounds toCoordinateSpace:window.screen.coordinateSpace];
    if(!DF144ValidRect(content,screen) ||
       fabs(CGRectGetMinX(content)-CGRectGetMaxX(dockrail))>1.5 ||
       fabs(CGRectGetMaxX(content)-CGRectGetMaxX(screen))>1.5 ||
       fabs(CGRectGetMinY(content)-CGRectGetMinY(screen))>1.5 ||
       fabs(CGRectGetMaxY(content)-CGRectGetMaxY(screen))>1.5)continue;
    result=window;*frame=content;*whole=screen;
    *displayID=rail.windowScene.session.persistentIdentifier;
    pairs++;
  }
 }
 return pairs==1&&(*displayID).length?result:nil;
}
static BOOL DF144LiveReceiver(void) {
 NSDictionary *p=[NSDictionary dictionaryWithContentsOfFile:DF144LeasePath];
 NSTimeInterval now=NSDate.date.timeIntervalSince1970;
 if(![p isKindOfClass:NSDictionary.class] || ![p[@"Version"] isEqual:@1] ||
    ![p[@"Role"] isEqualToString:@"SpringBoard-Standalone144"] ||
    ![p[@"Alive"] isEqual:@YES] || ![p[@"Timestamp"] isKindOfClass:NSNumber.class])return NO;
 NSTimeInterval age=now-[p[@"Timestamp"] doubleValue];
 return isfinite(age) && age>=0 && age<=2.0;
}
#import "DFNativeDockSync147.h"
#import "DF152NativeWorkspacePrepare.h"
static void DF144Launch(id self,SEL cmd,id manager,id icon) {
 NSString *bundle=DF144Bundle(icon,0);
 if(![icon isKindOfClass:UIView.class] || !DF144Allowed(bundle) || !DF144LiveReceiver()) {
   DF144Original(self,cmd,manager,icon);return;
 }
 CGRect content=CGRectZero,screen=CGRectZero;
 NSString *display=nil;
 if(!DF144UniqueNativeContentWindow(&content,&screen,&display)) {
   DF144Log(@"native-geometry-not-owned-original-forwarded",bundle);
   DF144Original(self,cmd,manager,icon);return;
 }
 // A *separate* broker not the ordinary DuoFace icon or split owner.
 NSString *rid=NSUUID.UUID.UUIDString;
 NSDictionary *p=@{@"Version":@1,@"Origin":@"CarPlayHomeStandalone144",
   @"RequestID":rid,@"BundleID":bundle,@"Timestamp":@(NSDate.date.timeIntervalSince1970),
   @"CarDisplayID":display,@"ContentRect":NSStringFromCGRect(content),
   @"ScreenBounds":NSStringFromCGRect(screen)};
 if(!DF144ValidRequest(p,NSDate.date.timeIntervalSince1970) ||
    ![p writeToFile:DF144Request atomically:YES]) {
   DF144Log(@"invalid-request-original-forwarded",bundle);
   DF144Original(self,cmd,manager,icon);return;
 }
 DF147Prepare(p);
 // Native Apple Home remains active until the first-party transaction owns a
 // valid remote scene. Only a verified official foreground app is deactivated,
 // and its native Dashboard workspace completion is bounded to 250ms.
 DF144LastHomeRequest=NSDate.date.timeIntervalSince1970;
 DF150ProbeWorkspaceForRequest(rid,bundle,display,NO);
 DF151WorkspaceSnapshot(rid,bundle,display,self);
 DF152PrepareThenContinue(rid,bundle,display,self,^{
   // A delayed Apple completion must not activate a revoked or replaced app.
   CGRect liveContent=CGRectZero,liveScreen=CGRectZero;
   NSString *liveDisplay=nil;
   NSDictionary *still=[NSDictionary dictionaryWithContentsOfFile:DF144Request];
   BOOL same=[DF147RequestID isEqualToString:rid] && DF147Life.pending &&
     [still[@"RequestID"] isEqualToString:rid] &&
     [still[@"BundleID"] isEqualToString:bundle] &&
     [still[@"CarDisplayID"] isEqualToString:display];
   if(!same || !DF144Allowed(bundle) || !DF144LiveReceiver() ||
      !DF144UniqueNativeContentWindow(&liveContent,&liveScreen,&liveDisplay) ||
      ![liveDisplay isEqualToString:display]) {
     DF144Log(@"qa152-native-prep-owner-revoked",
       [NSString stringWithFormat:@"req=%@ same=%d",rid,same]);
     if([DF147RequestID isEqualToString:rid])DF147Reset(@"native-prep-owner-revoked");
     if([still[@"RequestID"] isEqualToString:rid])
       [[NSFileManager defaultManager] removeItemAtPath:DF144Request error:nil];
     return;
   }
   int rc=notify_post(DF144RequestNotify);
   if(rc!=0) {
     DF147Reset(@"request-notify-failed");
     [[NSFileManager defaultManager] removeItemAtPath:DF144Request error:nil];
     DF144Log(@"qa152-notify-failure",
       [NSString stringWithFormat:@"req=%@ code=%d",rid,rc]);
     return;
   }
   DF144Log(@"standalone-requested-not-yet-ready",
      [NSString stringWithFormat:@"bid=%@ uuid=%@ content=%@",
         bundle,rid,NSStringFromCGRect(liveContent)]);
 });
}
static void DF144Install(int tryNo) {
 if(DF144Original || tryNo>15)return;
 Class home=objc_getClass("DBDashboardHomeViewController");
 SEL sel=sel_registerName("iconManager:launchIconForIconView:");
 Method m=home?class_getInstanceMethod(home,sel):NULL;
 DF144Hook hook=(DF144Hook)dlsym(RTLD_DEFAULT,"MSHookMessageEx");
 if(hook&&m&&!strcmp(method_getTypeEncoding(m),"v32@0:8@16@24"))
   hook(home,sel,(IMP)DF144Launch,(IMP*)&DF144Original);
 if(DF144Original && !DF144OriginalHomeAppear) {
   SEL appeared=sel_registerName("viewDidAppear:");
   Method original=class_getInstanceMethod(home,appeared);
   const char *type=original?method_getTypeEncoding(original):NULL;
   if(type && (!strcmp(type,"v24@0:8B16") || !strcmp(type,"v24@0:8c16")))
     hook(home,appeared,(IMP)DF144HomeAppeared,(IMP*)&DF144OriginalHomeAppear);
 }
 if(!DF144Original && tryNo<15)
   dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),
                  dispatch_get_main_queue(),^{DF144Install(tryNo+1);});
 else DF144Log(DF144Original?@"native-home-hook-installed":@"native-home-hook-not-available",
               [NSString stringWithFormat:@"tap=%d home=%d",DF144Original!=NULL,
                                             DF144OriginalHomeAppear!=NULL]);
}
__attribute__((constructor))static void DF144StartCarPlay(void) {
 if(![NSProcessInfo.processInfo.processName isEqualToString:@"CarPlay"] ||
    NSProcessInfo.processInfo.operatingSystemVersion.majorVersion!=16)return;
 // Install at startup; DBWorkspace initWithOwner: may precede the first tap.
 DF151StartCapture();
 dispatch_async(dispatch_get_main_queue(),^{DF147Start();DF144Install(0);});
}
#endif
#if defined(DF144_SPRINGBOARD)
@interface DF144Solo : NSObject
@property(nonatomic,strong) UIWindow *window;
@property(nonatomic,strong) UIViewController *root;
@property(nonatomic,strong) UIView *surface;
@property(nonatomic,copy) NSString *bundle;
@property(nonatomic,copy) NSString *request;
@property(nonatomic,copy) NSString *carDisplayID;
@property(nonatomic,strong) id display;
@property(nonatomic,assign) NSUInteger generation;
@property(nonatomic,assign) BOOL emittedHosted;
@property(nonatomic,assign) BOOL emittedManager;
@property(nonatomic,assign) BOOL emittedTerminal;
@property(nonatomic,copy) NSString *generalOwner;
@property(nonatomic,copy) NSString *generalScene;
@property(nonatomic,copy) NSDictionary *lastAppLease;
- (void)appStateAck:(NSNotification *)notice;
- (void)publishGeneralAppState:(BOOL)active;
@end
@implementation DF144Solo
// A genuine externally hosted FBScene is the ONLY authority for the app-side
// per-scene lease. Generic app receiver is never used by YT/GOFA or native apps.
- (void)publishGeneralAppState:(BOOL)active {
 if(!self.bundle.length ||
    [self.bundle isEqualToString:@"com.google.ios.youtube"] ||
    [self.bundle isEqualToString:@"com.lumi.GOFA"])return;
 NSString *sceneID=self.generalScene;
 CGSize size=CGSizeZero;
 if(active) {
   if(!self.emittedManager || !self.surface || !self.window ||
      self.window.hidden ||
      ![[DFSceneHost sharedHost] isLiveSceneForHostedView:self.surface] ||
      ![[[DFSceneHost sharedHost] bundleIDForHostedView:self.surface]
        isEqualToString:self.bundle])return;
   id remoteScene=DF144Get(self.surface,"scene");
   NSString *actual=DF144Get(remoteScene,"identifier");
   if(!DF154String(actual))return;
   if(self.generalScene && ![self.generalScene isEqual:actual])
     [self publishGeneralAppState:NO];
   if(!self.generalOwner)self.generalOwner=NSUUID.UUID.UUIDString;
   self.generalScene=actual;sceneID=actual;
   size=DFHostedLogicalSizeForBundle(self.surface.bounds.size,self.bundle);
 }
 if(!DF154String(self.generalOwner) || !DF154String(sceneID) ||
    !DF154String(self.request))return;
 NSDictionary *state=@{@"version":@1,@"bundleIdentifier":self.bundle,
    @"requestID":self.request,@"owner":self.generalOwner,
    @"sceneIdentifier":sceneID,@"issuedAt":@(NSDate.date.timeIntervalSince1970),
    @"active":@(active),@"width":@(size.width),@"height":@(size.height)};
 DF154Post(state);
 if(!active) {
   self.lastAppLease=@{@"requestID":self.request,@"bundleIdentifier":self.bundle,
      @"owner":self.generalOwner,@"sceneIdentifier":sceneID,
      @"issuedAt":@(NSDate.date.timeIntervalSince1970)};
   DF144Log(@"qa154-general-app-restore",
     [NSString stringWithFormat:@"req=%@ bid=%@ scene=%@",
       self.request,self.bundle,sceneID]);
   self.generalOwner=nil;self.generalScene=nil;
 }
}
// Exact process/app receipt: callback evidence only, not CarPlay pixels/touch.
- (void)appStateAck:(NSNotification *)notice {
 NSDictionary *a=notice.userInfo;
 if(![a isKindOfClass:NSDictionary.class] ||
    !DF154String(a[@"phase"]) ||
    ![a[@"issuedAt"] isKindOfClass:NSNumber.class])return;
 double age=NSDate.date.timeIntervalSince1970-[a[@"issuedAt"] doubleValue];
 if(!isfinite(age)||age<0||age>3)return;
 BOOL current=[a[@"requestID"] isEqual:self.request] &&
  [a[@"bundleIdentifier"] isEqual:self.bundle] &&
  [a[@"owner"] isEqual:self.generalOwner] &&
  [a[@"sceneIdentifier"] isEqual:self.generalScene];
 NSDictionary *old=self.lastAppLease;
 BOOL stopped=[a[@"phase"] isEqual:@"restored"] && old &&
  NSDate.date.timeIntervalSince1970-[old[@"issuedAt"] doubleValue]<=3 &&
  [a[@"requestID"] isEqual:old[@"requestID"]] &&
  [a[@"bundleIdentifier"] isEqual:old[@"bundleIdentifier"]] &&
  [a[@"owner"] isEqual:old[@"owner"]] &&
  [a[@"sceneIdentifier"] isEqual:old[@"sceneIdentifier"]];
 if(!current && !stopped)return;
 if(![@[@"lease-accepted",@"scene-unmatched",@"scene-matched",
        @"window-adjusted",@"restored"] containsObject:a[@"phase"]])return;
 DF144Log(@"qa155-app-side-ack",[NSString stringWithFormat:
  @"req=%@ bid=%@ scene=%@ phase=%@ count=%@",
    a[@"requestID"],a[@"bundleIdentifier"],a[@"sceneIdentifier"],
    a[@"phase"],a[@"count"]?:@0]);
}
// Only the real, process-owned SBApplication object and matching live scene
// can authorize this alternative processState.pid ABI on iOS16. Do not use
// generic UIApplication's pid, cached process lists or a fabricated value.
- (NSNumber *)verifiedProcessStatePIDForView:(UIView *)view {
 DFSceneHost *host=[DFSceneHost sharedHost];
 if(!view || !self.bundle.length || ![host isLiveSceneForHostedView:view] ||
    ![[host bundleIDForHostedView:view] isEqualToString:self.bundle])return nil;
 id registry=DF144Get(NSClassFromString(@"SBApplicationController"),"sharedInstance");
 SEL lookup=sel_registerName("applicationWithBundleIdentifier:");
 Method appLookup=registry?class_getInstanceMethod(object_getClass(registry),lookup):NULL;
 if(!appLookup || strcmp(method_getTypeEncoding(appLookup),"@24@0:8@16"))return nil;
 @try {
   id app=((id(*)(id,SEL,id))objc_msgSend)(registry,lookup,self.bundle);
   if(![DF144Get(app,"bundleIdentifier") isEqualToString:self.bundle])return nil;
   id process=DF144Get(app,"processState");
   SEL getter=sel_registerName("pid");
   Method m=process?class_getInstanceMethod(object_getClass(process),getter):NULL;
   if(!m || method_getNumberOfArguments(m)!=2)return nil;
   char ret[16]={0};
   method_getReturnType(m,ret,sizeof(ret));
   long long candidate=0;
   if(ret[0]=='i' || ret[0]=='I')
      candidate=((int(*)(id,SEL))objc_msgSend)(process,getter);
   else if(ret[0]=='q' || ret[0]=='Q')
      candidate=((long long(*)(id,SEL))objc_msgSend)(process,getter);
   else return nil;
   if(candidate<=1 || candidate>INT_MAX || candidate==getpid())return nil;
   errno=0;
   if(kill((pid_t)candidate,0)!=0 && errno!=EPERM)return nil;
   DF144Log(@"qa148-real-processstate-pid",
       [NSString stringWithFormat:@"req=%@ bid=%@ pid=%lld",self.request,self.bundle,candidate]);
   return @((pid_t)candidate);
 } @catch(NSException *e) {
   DF144Log(@"qa148-processstate-abi-exception",e.name);
   return nil;
 }
}
- (void)reply:(NSString *)state reason:(NSString *)reason verifiedPID:(NSNumber *)verifiedPID {
 if(self.emittedTerminal) {
   DF144Log(@"qa150-terminal-result-already-written",
       [NSString stringWithFormat:@"req=%@ suppressed=%@",self.request,state]);
   return;
 }
 BOOL terminal=[state isEqualToString:@"failed"] || [state isEqualToString:@"stopped"];
 NSNumber *pid=verifiedPID?: (self.surface?[[DFSceneHost sharedHost] verifiedPIDForHostedView:self.surface]:nil);
 NSDictionary *ack=@{@"Version":@2,@"RequestID":self.request?:@"",
   @"CarDisplayID":self.carDisplayID?:@"",@"VerifiedPID":pid?:@0,
   @"BundleID":self.bundle?:@"",@"Outcome":state?:@"unresolved",
   @"Reason":reason?:@"",@"Timestamp":@(NSDate.date.timeIntervalSince1970)};
 BOOL saved=[ack writeToFile:DF144Result atomically:YES];
 if(saved) {
   if(terminal)self.emittedTerminal=YES;
   notify_post(DF144ResultNotify);
 } else DF144Log(@"qa150-result-write-failed",self.request);
 DF144Log(state,[NSString stringWithFormat:@"bid=%@ req=%@ %@",self.bundle,self.request,reason?:@""]);
}
- (void)reply:(NSString *)state reason:(NSString *)reason {
 [self reply:state reason:reason verifiedPID:nil];
}
- (void)stop:(NSString *)reason {
 [self publishGeneralAppState:NO];
 ++self.generation;
 self.emittedHosted=NO;
 self.emittedManager=NO;
 if(self.window)self.window.hidden=YES; // hide external content before scene invalidate
 UIView *view=self.surface;self.surface=nil;
 self.window.rootViewController=nil;self.window=nil;self.root=nil;
 if(view)[[DFSceneHost sharedHost] releaseHostedView:view];
 if(self.request.length)[self reply:@"stopped" reason:reason];
 self.request=nil;self.bundle=nil;self.display=nil;self.carDisplayID=nil;
}
- (id)currentCarDisplayWithID:(NSString *)identifier {
 // Same actual AVExternalDevice/CADisplay relationship as existing DFTouchOwnerProbe,
 // but never assumes a DuoFace CPTemplate foreground lease.
 id device=DF144Get(NSClassFromString(@"AVExternalDevice"),"currentCarPlayExternalDevice");
 NSArray *ids=DF144Get(device,"screenIDs");
 NSArray *displays=DF144Get(NSClassFromString(@"CADisplay"),"displays");
 if(![ids isKindOfClass:NSArray.class]||![displays isKindOfClass:NSArray.class])return nil;
 for(id display in displays) {
   id uid=DF144Get(display,"uniqueId");
   if(uid&&[ids containsObject:uid])return display;
 }
 (void)identifier;return nil;
}
- (BOOL)begin:(NSDictionary *)p {
 if(!NSThread.isMainThread || !DF144ValidRequest(p,NSDate.date.timeIntervalSince1970) ||
    !DF144Allowed(p[@"BundleID"]))return NO;
 // Only one *independent* Home-owned surface; do not replace or consume
 // any real DuoFace split CPTemplate session.
 NSDictionary *cp=[NSDictionary dictionaryWithContentsOfFile:
   @"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist"];
 NSTimeInterval cpAge=NSDate.date.timeIntervalSince1970-[cp[@"Timestamp"] doubleValue];
 if([cp[@"Active"] boolValue] && cpAge>=0 && cpAge<2.0) {
   DF144Log(@"standalone-refuse-duoface-active",p[@"BundleID"]);return NO;
 }
 Class configuration=NSClassFromString(@"FBSDisplayConfiguration");
 Class windowClass=NSClassFromString(@"UIRootSceneWindow");
 SEL cfgSel=NSSelectorFromString(@"initWithCADisplay:isMainDisplay:");
 SEL winSel=NSSelectorFromString(@"initWithDisplayConfiguration:");
 id display=[self currentCarDisplayWithID:p[@"CarDisplayID"]];
 if(!configuration||!windowClass||!display||
    ![configuration instancesRespondToSelector:cfgSel] ||
    ![windowClass instancesRespondToSelector:winSel])return NO;
 CGRect content=CGRectFromString(p[@"ContentRect"]);
 CGRect expectedScreen=CGRectFromString(p[@"ScreenBounds"]);
 if(!DF144ValidRect(content,expectedScreen))return NO;
 if(self.window)[self stop:@"next-home-selection"];
 self.bundle=p[@"BundleID"];self.request=p[@"RequestID"];
 self.emittedHosted=NO;self.emittedManager=NO;self.emittedTerminal=NO;
 self.generalOwner=nil;self.generalScene=nil;
 self.carDisplayID=p[@"CarDisplayID"];self.display=display;
 NSUInteger generation=++self.generation;
 @try {
   id config=((id(*)(id,SEL,id,BOOL))objc_msgSend)([configuration alloc],cfgSel,display,NO);
   UIWindow *w=((id(*)(id,SEL,id))objc_msgSend)([windowClass alloc],winSel,config);
   if(![w isKindOfClass:UIWindow.class] || !w.screen ||
      w.screen==UIScreen.mainScreen ||
      fabs(w.screen.bounds.size.width-expectedScreen.size.width)>2 ||
      fabs(w.screen.bounds.size.height-expectedScreen.size.height)>2) {
     [self reply:@"failed" reason:@"external-screen-mismatch"];
     [self stop:@"external-screen-mismatch"];return NO;
   }
   w.frame=content;
   if(!CGRectEqualToRect(w.frame,content)){
     [self reply:@"failed" reason:@"window-frame-not-applied"];
     [self stop:@"window-frame-not-applied"];return NO;
   }
   w.windowLevel=UIWindowLevelNormal+1;
   w.backgroundColor=UIColor.clearColor;w.opaque=NO;
   UIViewController *root=[UIViewController new];
   root.view=[[UIView alloc]initWithFrame:(CGRect){CGPointZero,content.size}];
   root.view.backgroundColor=UIColor.clearColor;
   root.view.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
   w.rootViewController=root;
   self.window=w;self.root=root;w.hidden=NO;
   NSError *err=nil;
   UIView *v=[[DFSceneHost sharedHost] hostViewForBundleID:self.bundle error:&err];
   if(!v) {
     [self reply:@"failed" reason:err.localizedDescription?:@"scene-factory-refused"];
     [self stop:@"scene-factory-refused"];return NO;
   }
   self.surface=v;
   v.frame=root.view.bounds;v.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
   // Explicit SOLO, never call DFNative12Chrome or its app picker.
   [[DFSceneHost sharedHost] setSplitMode:NO forHostedView:v];
   // didMoveToWindow -> start -> sceneReady/sceneFailed can synchronously run
   // inside addSubview. Publish nonterminal pending FIRST, never after ready/fail.
   [self reply:@"pending-scene" reason:@"single-app-window-mounting-no-media-ack"];
   DF144Log(@"before-standalone-mount",
       [NSString stringWithFormat:@"req=%@ content=%@ window=%@ root=%@ surface=%@",
       p[@"RequestID"],NSStringFromCGRect(content),NSStringFromCGRect(w.bounds),
       NSStringFromCGRect(root.view.bounds),NSStringFromCGRect(v.bounds)]);
   [root.view addSubview:v];
   // An attach failure can synchronously call sceneFailed -> stop -> clear owner.
   // Never report a completed mount or create another timeout in that case.
   if(self.generation!=generation || self.surface!=v || self.window!=w ||
      ![self.request isEqualToString:p[@"RequestID"]]) {
     DF144Log(@"mount-reentrancy-terminal",
        [NSString stringWithFormat:@"req=%@ bid=%@",p[@"RequestID"],p[@"BundleID"]]);
     return NO;
   }
   DF144Log(@"after-standalone-mount",
       [NSString stringWithFormat:@"req=%@ window=%@ root=%@ surface=%@",
       p[@"RequestID"],NSStringFromCGRect(w.bounds),
       NSStringFromCGRect(root.view.bounds),NSStringFromCGRect(v.bounds)]);
   __weak typeof(self) weakSelf=self;
   dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(9.0*NSEC_PER_SEC)),
                  dispatch_get_main_queue(),^{
    DF144Solo *owner=weakSelf;
    if(owner && owner.generation==generation &&
       owner.surface && ![[DFSceneHost sharedHost] isLiveSceneForHostedView:owner.surface]){
      [owner reply:@"failed" reason:@"remote-scene-timeout"];
      [owner stop:@"remote-scene-timeout"];
    }
   });
   return YES;
 } @catch(NSException *e) {
   // Do not overwrite a terminal result from a synchronous nested failure.
   if(self.generation==generation && [self.request isEqualToString:p[@"RequestID"]]) {
     [self reply:@"failed" reason:e.name];
     [self stop:@"owner-exception"];
   } else {
     DF144Log(@"owner-exception-after-terminal",
       [NSString stringWithFormat:@"req=%@ exception=%@",p[@"RequestID"],e.name]);
   }
   return NO;
 }
}
- (void)attemptOwnedReadyForView:(UIView *)v request:(NSString *)rid
                       generation:(NSUInteger)generation attempt:(NSUInteger)attempt {
 // No delayed callback may attach an old PID to a replaced or revoked surface.
 if(self.generation!=generation || self.surface!=v ||
    ![self.request isEqualToString:rid] || self.emittedHosted)return;
 if(!self.window || self.window.hidden) {
   DF144Log(@"qa147-ready-window-refused",rid);return;
 }
 DFSceneHost *host=[DFSceneHost sharedHost];
 if(![host isLiveSceneForHostedView:v]) {
   DF144Log(@"qa147-ready-scene-not-live",rid);return;
 }
 if(![[host bundleIDForHostedView:v] isEqualToString:self.bundle]) {
   DF144Log(@"qa147-ready-bundle-mismatch",rid);return;
 }
 // This is a distinct, TRUE manager-owned live-scene/window event. It does
 // NOT attest pixels, user touch, process PID or original native workspace.
 // Native Dock state may follow this owner receipt; PID remains an observation.
 if(!self.emittedManager) {
   self.emittedManager=YES;
   [self publishGeneralAppState:YES];
   DF144Log(@"qa149-manager-live-scene-owned",
      [NSString stringWithFormat:@"req=%@ bid=%@ generation=%lu window=%@",
        rid,self.bundle,(unsigned long)generation,NSStringFromCGRect(self.window.bounds)]);
   [self reply:@"manager-owned-live-scene-pixels-unverified"
       reason:@"SB-owned-scene-handle-and-window-confirmed-PID-observed-separately"];
 }
 NSNumber *pid=[host verifiedPIDForHostedView:v];
 if(!pid)pid=[self verifiedProcessStatePIDForView:v];
 if(pid) {
   self.emittedHosted=YES;
   DF144Log(@"qa147-ready-verified-pid",
       [NSString stringWithFormat:@"req=%@ attempt=%lu pid=%@",rid,(unsigned long)attempt,pid]);
   [self reply:@"scene-hosted-render-and-touch-unverified"
       reason:[NSString stringWithFormat:@"verifiedPID=%@",pid] verifiedPID:pid];
   return;
 }
 // Scene liveness and process identity are different clocks. Retry only the
 // existing real PID verifier, bounded within native pending's 10s watchdog.
 if(attempt==0 || attempt==4 || attempt==14)
   DF144Log(@"qa147-ready-pid-unavailable",
     [NSString stringWithFormat:@"req=%@ attempt=%lu generation=%lu",
      rid,(unsigned long)attempt,(unsigned long)generation]);
 if(attempt>=14)return;
 __weak typeof(self) weakSelf=self;
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.5*NSEC_PER_SEC)),
                dispatch_get_main_queue(),^{
   [weakSelf attemptOwnedReadyForView:v request:rid
                         generation:generation attempt:attempt+1];
 });
}
- (void)sceneReady:(NSNotification *)notice {
 if(notice.object!=self.surface) {
   DF144Log(@"qa147-ready-foreign-surface",@"not-owned-surface");
   return;
 }
 [self attemptOwnedReadyForView:self.surface request:[self.request copy]
                       generation:self.generation attempt:0];
}
- (void)sceneFailed:(NSNotification *)notice {
 if(notice.object!=self.surface)return;
 NSString *reason=[notice.userInfo[@"error"] localizedDescription]?:@"scene-host-failed";
 [self reply:@"failed" reason:reason];[self stop:@"remote-host-failed"];
}
- (void)physicalDisconnect:(NSNotification *)notice {
 (void)notice;
 if(self.window && ![self currentCarDisplayWithID:self.carDisplayID])
    [self stop:@"CarPlay-display-disconnected"];
}
@end
static DF144Solo *DF144Owner;
static NSString *DF144LastRequest;
#import "DF153PhoneEviction.h"
static void DF144LeaseHeartbeat(void) {
 if(![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"])return;
 BOOL usable=NSClassFromString(@"FBSDisplayConfiguration")!=nil &&
             NSClassFromString(@"UIRootSceneWindow")!=nil &&
             NSClassFromString(@"SBAppViewController")!=nil;
 NSDictionary *record=@{@"Version":@1,@"Role":@"SpringBoard-Standalone144",
      @"Alive":@(usable),@"Timestamp":@(NSDate.date.timeIntervalSince1970)};
 if(![record writeToFile:DF144LeasePath atomically:YES])
   DF144Log(@"standalone-receiver-lease-write-failed",@"");
 if(DF144Owner && DF144Owner.window) {
   if(!DFHome145Enabled() || !DF144Allowed(DF144Owner.bundle) ||
       !DF144Owner.window.screen ||
      DF144Owner.window.screen==UIScreen.mainScreen ||
      ![DF144Owner currentCarDisplayWithID:DF144Owner.carDisplayID])
       [DF144Owner stop:@"owner-revoked-consent-or-external-display"];
   else if(DF144Owner.emittedManager && DF144Owner.surface &&
          ![[DFSceneHost sharedHost] isLiveSceneForHostedView:DF144Owner.surface])
       [DF144Owner stop:@"manager-live-scene-revoked"];
   else if(DF144Owner.emittedManager && DF144Owner.surface)
       [DF144Owner publishGeneralAppState:YES]; // renew short app-side lease
 }
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.7*NSEC_PER_SEC)),
                dispatch_get_main_queue(),^{DF144LeaseHeartbeat();});
}
// Exactly one truthful terminal response for a fresh, permitted request even
// when the SB receiver refuses before it has installed a standalone owner.
// Preserve an already emitted synchronous failed/stopped result.
static void DF150ReplyRejected(NSDictionary *p) {
 NSDictionary *existing=[NSDictionary dictionaryWithContentsOfFile:DF144Result];
 NSString *outcome=existing[@"Outcome"];
 if([existing[@"RequestID"] isEqual:p[@"RequestID"]] &&
    [existing[@"BundleID"] isEqual:p[@"BundleID"]] &&
    [existing[@"CarDisplayID"] isEqual:p[@"CarDisplayID"]] &&
    ([outcome isEqualToString:@"failed"] || [outcome isEqualToString:@"stopped"])) {
   DF144Log(@"qa150-preflight-terminal-preserved",p[@"RequestID"]);
   return;
 }
 NSDictionary *terminal=@{@"Version":@2,@"RequestID":p[@"RequestID"],
    @"BundleID":p[@"BundleID"],@"CarDisplayID":p[@"CarDisplayID"],
    @"Outcome":@"failed",@"VerifiedPID":@0,
    @"Reason":@"receiver-preflight-rejected-no-scene-owner",
    @"Timestamp":@(NSDate.date.timeIntervalSince1970)};
 if([terminal writeToFile:DF144Result atomically:YES]) {
   notify_post(DF144ResultNotify);
   DF144Log(@"qa150-preflight-rejected-terminal",
     [NSString stringWithFormat:@"req=%@ bid=%@",p[@"RequestID"],p[@"BundleID"]]);
 } else DF144Log(@"qa150-preflight-write-failed",p[@"RequestID"]);
}
static void DF144Consume(void) {
 NSDictionary *p=[NSDictionary dictionaryWithContentsOfFile:DF144Request];
 if(!DF144ValidRequest(p,NSDate.date.timeIntervalSince1970) ||
    !DF144Allowed(p[@"BundleID"]))return;
 NSString *uuid=p[@"RequestID"];
 if([uuid isEqualToString:DF144LastRequest])return;
 DF144LastRequest=[uuid copy];
 [[NSFileManager defaultManager] removeItemAtPath:DF144Request error:nil];
 DF150ProbeWorkspaceForRequest(uuid,p[@"BundleID"],p[@"CarDisplayID"],YES);
 DF153PreparePhoneForSelectedApp(uuid,p[@"BundleID"],^{
   // The actual phone foreground transition may be asynchronous. Never open
   // an obsolete scene after Home, disconnect, a replaced request or opt-out.
   if(![DF144LastRequest isEqualToString:uuid] ||
      !DF144ValidRequest(p,NSDate.date.timeIntervalSince1970) ||
      !DF144Allowed(p[@"BundleID"])) {
      DF144Log(@"qa153-phone-prep-owner-revoked",
        [NSString stringWithFormat:@"req=%@ bid=%@",uuid,p[@"BundleID"]]);
      return;
   }
   if(![DF144Owner begin:p]) {
     DF144Log(@"no-valid-standalone-owner",
        [NSString stringWithFormat:@"req=%@ bid=%@",uuid,p[@"BundleID"]]);
     DF150ReplyRejected(p);
   }
 });
}
__attribute__((constructor))static void DF144StartSpringBoard(void) {
 if(![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"] ||
    NSProcessInfo.processInfo.operatingSystemVersion.majorVersion!=16)return;
 dispatch_async(dispatch_get_main_queue(),^{
  DF144Owner=[DF144Solo new];
  id ackCenter=DF154Center();
  if(ackCenter)[ackCenter addObserver:DF144Owner selector:@selector(appStateAck:)
     name:DF155AckNotification object:nil];
  else DF144Log(@"qa155-ack-transport-unavailable",@"no app receipt");
  [[NSNotificationCenter defaultCenter] addObserver:DF144Owner
     selector:@selector(sceneReady:) name:DFSceneHostDidBecomeReadyNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:DF144Owner
     selector:@selector(sceneFailed:) name:DFSceneHostDidFailNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:DF144Owner
     selector:@selector(physicalDisconnect:) name:UIScreenDidDisconnectNotification object:nil];
  static int requestToken=-1,stopToken=-1,watchdogToken=-1;
  static int switchToken=-1,revokeToken=-1;
  notify_register_dispatch(DF144RequestNotify,&requestToken,dispatch_get_main_queue(),
    ^(__unused int t){DF144Consume();});
  notify_register_dispatch(DF144StopNotify,&stopToken,dispatch_get_main_queue(),
    ^(__unused int t){DF153PhoneRevoke();[DF144Owner stop:@"native-Home-exit"];});
  // A CarPlay pending-watchdog expiry is NOT a physical Home press.
  notify_register_dispatch(DF148WatchdogStopNotify,&watchdogToken,dispatch_get_main_queue(),
    ^(__unused int t){DF153PhoneRevoke();[DF144Owner stop:@"native-pending-watchdog-expiry"];});
  notify_register_dispatch(DF148NativeSwitchStopNotify,&switchToken,dispatch_get_main_queue(),
    ^(__unused int t){DF153PhoneRevoke();[DF144Owner stop:@"native-app-switch"];});
  notify_register_dispatch(DF148OwnerRevokeStopNotify,&revokeToken,dispatch_get_main_queue(),
    ^(__unused int t){DF153PhoneRevoke();[DF144Owner stop:@"native-owner-or-consent-revoked"];});
  DF144LeaseHeartbeat();
  DF144Log(@"independent-standalone-receiver-registered",
    @"default-off no-DuoFace-CPTemplate no-chrome no-Sileo");
 });
}
#endif
