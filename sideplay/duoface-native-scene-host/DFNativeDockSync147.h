// Independent Dock lifecycle. Receivers/ABI from physical observer 8170d2a.
// Original semantic evidence: audit qa147 ORIGINAL_DOCK_HOME_ARGUMENTS.json.
#import "DFDockLifecycle147.h"
static DF147Lifecycle DF147Life;
static NSString *DF147RequestID,*DF147Bundle,*DF147Session,*DF147Previous;
static NSTimeInterval DF147RequestedAt,DF147LastResultAt;
static __weak id DF147Dock,DF147Home;
static NSUInteger DF147HomeBefore;
static BOOL DF147HaveHome,DF147Applying,DF147Captured;
static void (*DF147NativeActiveOriginal)(id,SEL,id,BOOL);
static BOOL DF147ABI(id object,const char *name,const char *encoding) {
 Method m=object?class_getInstanceMethod(object_getClass(object),sel_registerName(name)):NULL;
 return m && !strcmp(method_getTypeEncoding(m),encoding);
}
static id DF147FindDock(NSString *session,id *home) {
 NSMutableArray *matches=[NSMutableArray array];
 for(UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
  if(![scene isKindOfClass:UIWindowScene.class] ||
     ![scene.session.persistentIdentifier isEqualToString:session] ||
     ![scene.session.role isEqualToString:@"UIWindowSceneSessionRoleCarPlay"] ||
     scene.activationState==UISceneActivationStateBackground)continue;
  for(UIWindow *w in ((UIWindowScene *)scene).windows) {
   if(![NSStringFromClass(w.class) isEqualToString:@"DBStatusBarWindow"] ||
      w.hidden || w.screen==UIScreen.mainScreen ||
      ![NSStringFromClass(w.rootViewController.class) isEqualToString:@"DBRootStatusBarViewController"])continue;
   NSMutableArray *queue=[NSMutableArray arrayWithObject:w.rootViewController];
   for(NSUInteger i=0;i<queue.count && i<64;i++) {
    UIViewController *vc=queue[i];
    if([NSStringFromClass(vc.class) isEqualToString:@"DBAppDockViewController"])
     [matches addObject:vc];
    for(UIViewController *child in vc.childViewControllers)
     if(queue.count<64 && ![queue containsObject:child])[queue addObject:child];
   }
   id h=DF144Get(w.rootViewController,"homeButton");
   if([NSStringFromClass([h class]) isEqualToString:@"DBStatusBarHomeButton"])*home=h;
  }
 }
 return matches.count==1?matches.firstObject:nil;
}
static BOOL DF147DockABI(id dock) {
 return DF147ABI(dock,"activeBundleIdentifier","@16@0:8") &&
        DF147ABI(dock,"appHistory","@16@0:8") &&
        DF147ABI(dock,"setActiveBundleIdentifier:animated:","v28@0:8@16B24") &&
        DF147ABI(dock,"_refreshAppDock","v16@0:8");
}
static void DF147RestoreDock(NSString *reason) {
 if(!DF147Captured)return;
 id dock=DF147Dock,home=nil;
 id current=DF147FindDock(DF147Session,&home);
 // Do not overwrite a native app that has already taken ownership of the Dock.
 if(dock && current==dock && DF147DockABI(dock) &&
    [DF144Get(dock,"activeBundleIdentifier") isEqual:DF147Bundle]) {
  @try {
   DF147Applying=YES;
   ((void(*)(id,SEL,id,BOOL))objc_msgSend)(dock,sel_registerName("setActiveBundleIdentifier:animated:"),DF147Previous,NO);
   ((void(*)(id,SEL))objc_msgSend)(dock,sel_registerName("_refreshAppDock"));
   if(DF147HaveHome && home==DF147Home && DF147ABI(home,"setDisplayState:","v24@0:8Q16"))
    ((void(*)(id,SEL,NSUInteger))objc_msgSend)(home,sel_registerName("setDisplayState:"),DF147HomeBefore);
   DF144Log(@"qa147-native-dock-restored",reason);
  } @catch(NSException *e){DF144Log(@"qa147-native-dock-restore-exception",e.name);}
  @finally{DF147Applying=NO;}
 } else DF144Log(@"qa147-native-owner-changed-restore-skipped",reason);
}
static void DF147Reset(NSString *reason) {
 if(DF147RevokeGeneration(&DF147Life)==DF147Restore)DF147RestoreDock(reason);
 DF147Captured=NO;DF147HaveHome=NO;DF147Dock=nil;DF147Home=nil;
 DF147RequestID=nil;DF147Bundle=nil;DF147Session=nil;DF147Previous=nil;
}
static void DF147Prepare(NSDictionary *p) {
 DF147Reset(@"replacement-request");
 DF147BeginGeneration(&DF147Life);
 DF147RequestID=[p[@"RequestID"] copy];DF147Bundle=[p[@"BundleID"] copy];
 DF147Session=[p[@"CarDisplayID"] copy];DF147RequestedAt=[p[@"Timestamp"] doubleValue];DF147LastResultAt=DF147RequestedAt;
}
static BOOL DF147ActivateDock(void) {
 id home=nil,dock=DF147FindDock(DF147Session,&home);
 if(!DF147DockABI(dock)) {DF144Log(@"qa147-native-dock-abi-refused",DF147Bundle);return NO;}
 id history=DF144Get(dock,"appHistory");
 if(![NSStringFromClass([history class]) isEqualToString:@"DBAppHistory"] ||
    !DF147ABI(history,"_bundleIdentifierDidBecomeVisible:previousBundleIdentifier:","v32@0:8@16@24"))return NO;
 id old=DF144Get(dock,"activeBundleIdentifier");
 if(old && ![old isKindOfClass:NSString.class])return NO;
 DF147Previous=[old copy];DF147Dock=dock;DF147Home=home;
 DF147HaveHome=DF147ABI(home,"displayState","Q16@0:8") && DF147ABI(home,"setDisplayState:","v24@0:8Q16");
 if(DF147HaveHome)DF147HomeBefore=((NSUInteger(*)(id,SEL))objc_msgSend)(home,sel_registerName("displayState"));
 DF147Captured=YES;
 @try {
  DF147Applying=YES;
  // Original DuoNavi @0x2c7378 loads x3=0: previousBundleIdentifier is nil.
  ((void(*)(id,SEL,id,id))objc_msgSend)(history,sel_registerName("_bundleIdentifierDidBecomeVisible:previousBundleIdentifier:"),DF147Bundle,nil);
  ((void(*)(id,SEL,id,BOOL))objc_msgSend)(dock,sel_registerName("setActiveBundleIdentifier:animated:"),DF147Bundle,NO);
  ((void(*)(id,SEL))objc_msgSend)(dock,sel_registerName("_refreshAppDock"));
  // Original setHomeButtonInApp:YES computes !YES => 0. Restore saved state later.
  if(DF147HaveHome)((void(*)(id,SEL,NSUInteger))objc_msgSend)(home,sel_registerName("setDisplayState:"),(NSUInteger)0);
  BOOL applied=[DF144Get(dock,"activeBundleIdentifier") isEqual:DF147Bundle];
  DF144Log(applied?@"qa147-native-dock-active":@"qa147-native-dock-readback-mismatch",
   [NSString stringWithFormat:@"bid=%@ req=%@ homeCaptured=%d",DF147Bundle,DF147RequestID,DF147HaveHome]);
  return applied;
 } @catch(NSException *e){DF144Log(@"qa147-native-dock-activate-exception",e.name);return NO;}
 @finally{DF147Applying=NO;}
}
static void DF147ConsumeResult(void) {
 NSDictionary *a=[NSDictionary dictionaryWithContentsOfFile:DF144Result];
 if(![a isKindOfClass:NSDictionary.class] || ![a[@"Version"] isEqual:@2] ||
    ![a[@"Timestamp"] isKindOfClass:NSNumber.class])return;
 NSString *outcome=a[@"Outcome"];
 BOOL identity=[a[@"RequestID"] isEqual:DF147RequestID] && [a[@"BundleID"] isEqual:DF147Bundle] &&
               [a[@"CarDisplayID"] isEqual:DF147Session];
 double stamp=[a[@"Timestamp"] doubleValue],age=NSDate.date.timeIntervalSince1970-stamp;
 BOOL hosted=[outcome isEqual:@"scene-hosted-render-and-touch-unverified"];
 BOOL terminal=[outcome isEqual:@"failed"] || [outcome isEqual:@"stopped"];
 BOOL fresh=isfinite(age)&&age>=0&&(terminal||age<=5.0)&&stamp>=DF147LastResultAt;
 if(identity&&fresh)DF147LastResultAt=stamp;
 BOOL pid=[a[@"VerifiedPID"] isKindOfClass:NSNumber.class] && [a[@"VerifiedPID"] longLongValue]>0;
 DF147Action action=DF147ResultAction(&DF147Life,identity,fresh,hosted,terminal,pid);
 if(action==DF147Activate) {
  if(!DF147ActivateDock())DF147Reset(@"activation-refused");
 } else if(action==DF147Restore) {
  DF147RestoreDock(outcome);DF147Reset(outcome);
 } else if(identity&&fresh&&terminal)DF147Reset(outcome);
}
static void DF147NativeActiveChanged(id object,SEL sel,id bundle,BOOL animated) {
 DF147NativeActiveOriginal(object,sel,bundle,animated);
 if(NSThread.isMainThread && !DF147Applying && DF147Life.active && object==DF147Dock && ![bundle isEqual:DF147Bundle]) {
  DF147Reset(@"native-app-switch");
  notify_post(DF148NativeSwitchStopNotify); // Hide ours; preserve the NEW native Dock app.
 }
}
static void DF147InstallNativeSwitchHook(void) {
 if(DF147NativeActiveOriginal)return;
 Class cls=NSClassFromString(@"DBAppDockViewController");
 SEL sel=sel_registerName("setActiveBundleIdentifier:animated:");
 Method m=cls?class_getInstanceMethod(cls,sel):NULL;
 DF144Hook hook=(DF144Hook)dlsym(RTLD_DEFAULT,"MSHookMessageEx");
 if(hook && m && !strcmp(method_getTypeEncoding(m),"v28@0:8@16B24"))
  hook(cls,sel,(IMP)DF147NativeActiveChanged,(IMP *)&DF147NativeActiveOriginal);
}
static void DF147Watch(void) {
 DF147InstallNativeSwitchHook();
 if(DF147Life.pending||DF147Life.active) {
  id home=nil,dock=DF147FindDock(DF147Session,&home);
  if(!DF144ExplicitConsent() || !dock) {
   DF147Reset(@"disconnect-or-consent-revoked");
   notify_post(DF148OwnerRevokeStopNotify);
  } else if(DF147Life.pending && NSDate.date.timeIntervalSince1970-DF147RequestedAt>10.0) {
   // Keep watchdog expiry separate from a REAL DBRootStatusBar Home press.
   // Never attribute the timeout to user navigation in device logs.
   DF144Log(@"qa148-pending-watchdog-expired",
       [NSString stringWithFormat:@"req=%@ bid=%@",DF147RequestID,DF147Bundle]);
   DF147Reset(@"pending-watchdog-expired");
   notify_post(DF148WatchdogStopNotify);
  }
 }
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),dispatch_get_main_queue(),^{DF147Watch();});
}
static void DF147Start(void) {
 static int resultToken=-1,stopToken=-1;
 notify_register_dispatch(DF144ResultNotify,&resultToken,dispatch_get_main_queue(),^(__unused int token){DF147ConsumeResult();});
 notify_register_dispatch(DF144StopNotify,&stopToken,dispatch_get_main_queue(),^(__unused int token){DF147Reset(@"native-home-stop");});
 DF147Watch();
 DF144Log(@"qa147-native-dock-result-consumer-installed",@"request-bundle-session scoped; no fake Dock");
}
