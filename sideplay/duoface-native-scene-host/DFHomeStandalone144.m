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
#import <dlfcn.h>
#import <string.h>
#import "DFHome140Consent.h"
#import "DFEnabledAppsPolicy.h"
#if defined(DF144_SPRINGBOARD)
#import "DFSceneHost.h"
#endif

static NSString *const DF144Request=@"/var/mobile/Library/Preferences/com.duoface.nativehost.standalone144-request.plist";
static NSString *const DF144Result=@"/var/mobile/Library/Preferences/com.duoface.nativehost.standalone144-result.plist";
static NSString *const DF144OptIn=@"/var/mobile/Library/Preferences/com.duoface.nativehost.standalone144-optin.plist";
static NSString *const DF144LogPath=@"/var/mobile/Library/Logs/DuoFaceStandalone144.log";
static const char *const DF144RequestNotify="com.duoface.nativehost.standalone144.request";
static const char *const DF144StopNotify="com.duoface.nativehost.standalone144.stop";
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
static BOOL DF144ExplicitConsent(void) {
 NSDictionary *p=[NSDictionary dictionaryWithContentsOfFile:DF144OptIn];
 return [p isKindOfClass:NSDictionary.class] && [p[@"Version"] isEqual:@1] &&
       [p[@"StandaloneHomeDirect"] isEqual:@YES] && DFHome140Enabled();
}
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
static void DF144HomeAppeared(id owner,SEL sel,BOOL animated) {
 DF144OriginalHomeAppear(owner,sel,animated);
 // Home/Back must revoke ONLY a prior standalone scene (not a brand-new tap).
 if(DF144LastHomeRequest>0 &&
    NSDate.date.timeIntervalSince1970-DF144LastHomeRequest>0.7) {
   DF144Log(@"native-home-return",@"revoke-standalone-only");
   notify_post(DF144StopNotify);
 }
}

typedef void (*DF144Hook)(Class,SEL,IMP,IMP*);
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
static void DF144Launch(id self,SEL cmd,id manager,id icon) {
 NSString *bundle=DF144Bundle(icon,0);
 if(![icon isKindOfClass:UIView.class] || !DF144Allowed(bundle)) {
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
 int rc=notify_post(DF144RequestNotify);
 if(rc!=0) {
   [[NSFileManager defaultManager] removeItemAtPath:DF144Request error:nil];
   DF144Log(@"notify-error-original-forwarded",[NSString stringWithFormat:@"bid=%@ status=%d",bundle,rc]);
   DF144Original(self,cmd,manager,icon);return;
 }
 // Native Apple Home remains in place while the *separate* SpringBoard
 // standalone scene attempts to attach. No fabricated CarPlay app activation.
 // No success is asserted until receiver verifies the actual hosted scene.
 DF144LastHomeRequest=NSDate.date.timeIntervalSince1970;
 DF144Log(@"standalone-requested-not-yet-ready",[NSString stringWithFormat:
      @"bid=%@ uuid=%@ content=%@",bundle,rid,NSStringFromCGRect(content)]);
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
 dispatch_async(dispatch_get_main_queue(),^{DF144Install(0);});
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
@end
@implementation DF144Solo
- (void)reply:(NSString *)state reason:(NSString *)reason {
 NSDictionary *ack=@{@"Version":@1,@"RequestID":self.request?:@"",
   @"BundleID":self.bundle?:@"",@"Outcome":state?:@"unresolved",
   @"Reason":reason?:@"",@"Timestamp":@(NSDate.date.timeIntervalSince1970)};
 if([ack writeToFile:DF144Result atomically:YES])notify_post(DF144ResultNotify);
 DF144Log(state,[NSString stringWithFormat:@"bid=%@ req=%@ %@",self.bundle,self.request,reason?:@""]);
}
- (void)stop:(NSString *)reason {
 ++self.generation;
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
 id device=DF144Get(NSClassFromString("AVExternalDevice"),"currentCarPlayExternalDevice");
 NSArray *ids=DF144Get(device,"screenIDs");
 NSArray *displays=DF144Get(NSClassFromString("CADisplay"),"displays");
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
   [root.view addSubview:v];
   [self reply:@"pending-scene" reason:@"single-app-window-attached-no-media-ack"];
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
   [self reply:@"failed" reason:e.name];
   [self stop:@"owner-exception"];return NO;
 }
}
- (void)sceneReady:(NSNotification *)notice {
 if(notice.object!=self.surface || !self.window || self.window.hidden)return;
 DFSceneHost *host=[DFSceneHost sharedHost];
 if(![host isLiveSceneForHostedView:self.surface] ||
    ![[host bundleIDForHostedView:self.surface] isEqualToString:self.bundle])return;
 NSNumber *pid=[host verifiedPIDForHostedView:self.surface];
 if(!pid)return; // no fake rendering/real app process claim
 [self reply:@"scene-hosted-render-and-touch-unverified"
       reason:[NSString stringWithFormat:@"verifiedPID=%@",pid]];
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
static void DF144Consume(void) {
 NSDictionary *p=[NSDictionary dictionaryWithContentsOfFile:DF144Request];
 if(!DF144ValidRequest(p,NSDate.date.timeIntervalSince1970) ||
    !DF144Allowed(p[@"BundleID"]))return;
 NSString *uuid=p[@"RequestID"];
 if([uuid isEqualToString:DF144LastRequest])return;
 DF144LastRequest=[uuid copy];
 [[NSFileManager defaultManager] removeItemAtPath:DF144Request error:nil];
 if(![DF144Owner begin:p])
  DF144Log(@"no-valid-standalone-owner",[NSString stringWithFormat:@"bid=%@",p[@"BundleID"]]);
}
__attribute__((constructor))static void DF144StartSpringBoard(void) {
 if(![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"] ||
    NSProcessInfo.processInfo.operatingSystemVersion.majorVersion!=16)return;
 dispatch_async(dispatch_get_main_queue(),^{
  DF144Owner=[DF144Solo new];
  [[NSNotificationCenter defaultCenter] addObserver:DF144Owner
     selector:@selector(sceneReady:) name:DFSceneHostDidBecomeReadyNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:DF144Owner
     selector:@selector(sceneFailed:) name:DFSceneHostDidFailNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:DF144Owner
     selector:@selector(physicalDisconnect:) name:UIScreenDidDisconnectNotification object:nil];
  static int requestToken=-1,stopToken=-1;
  notify_register_dispatch(DF144RequestNotify,&requestToken,dispatch_get_main_queue(),
    ^(__unused int t){DF144Consume();});
  notify_register_dispatch(DF144StopNotify,&stopToken,dispatch_get_main_queue(),
    ^(__unused int t){[DF144Owner stop:@"native-Home-exit"];});
  DF144Log(@"independent-standalone-receiver-registered",
    @"default-off no-DuoFace-CPTemplate no-chrome no-Sileo");
 });
}
#endif
