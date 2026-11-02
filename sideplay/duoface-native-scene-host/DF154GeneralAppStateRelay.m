// First-party app-side lease consumer for a narrow explicitly injected app set.
// It NEVER changes the phone's unrelated scene, UIDevice rotation, root Dock,
// process lifecycle, player input, or other apps. Reverts its own frames only.
#import <UIKit/UIKit.h>
#import "DF154AppStateProtocol.h"
#import "DF155PilotAppScope.h"
#import "DFKBDiag176.h"
#import <dlfcn.h>

// QA176 H3: recursive view search for the keyboard layout view.
static UIView *DF176FindView(UIView *root, NSString *klass, int depth) {
 if(!root || depth>8)return nil;
 if([NSStringFromClass(root.class) isEqualToString:klass])return root;
 for(UIView *sub in root.subviews) {
  UIView *hit=DF176FindView(sub,klass,depth+1);
  if(hit)return hit;
 }
 return nil;
}

@interface DF154WindowOriginal : NSObject
@property(nonatomic) CGRect frame;
@property(nonatomic) CGRect bounds;
@property(nonatomic,weak) UIWindowScene *scene;
@end
@implementation DF154WindowOriginal
@end

@interface DF154GeneralAppStateRelay : NSObject
@property(nonatomic,copy) NSString *bundle;
@property(nonatomic,copy) NSDictionary *state;
@property(nonatomic,weak) UIWindowScene *ownedScene;
@property(nonatomic,strong) NSMapTable<UIWindow *,DF154WindowOriginal *> *originals;
@property(nonatomic,strong) NSTimer *expiry;
@property(nonatomic) NSTimeInterval newest;
@property(nonatomic) BOOL applying;
@property(nonatomic,copy) NSString *lastAckPhase;
@property(nonatomic) NSTimeInterval lastKbDiag176;
- (void)df176KeyboardShown:(NSNotification *)notification;
- (void)postAck:(NSString *)phase count:(NSUInteger)count;
- (void)receive:(NSNotification *)notification;
- (void)reconcile;
- (void)restore:(NSString *)reason;
@end
@implementation DF154GeneralAppStateRelay
- (void)postAck:(NSString *)phase count:(NSUInteger)count {
 NSDictionary *state=self.state;
 if(!DF154String(state[@"requestID"]))return;
 if([self.lastAckPhase isEqualToString:phase] && ![phase isEqual:@"window-adjusted"])return;
 self.lastAckPhase=phase;
 DF155PostAck(@{@"requestID":state[@"requestID"],@"bundleIdentifier":self.bundle,
   @"owner":state[@"owner"],@"sceneIdentifier":state[@"sceneIdentifier"],
   @"issuedAt":@(NSDate.date.timeIntervalSince1970),@"phase":phase,@"count":@(count)});
}
- (void)restore:(NSString *)reason {
 if(!NSThread.isMainThread) {
  dispatch_async(dispatch_get_main_queue(),^{[self restore:reason];});return;
 }
 UIWindowScene *scene=self.ownedScene;
 NSUInteger restored=0;
 for(UIWindow *window in self.originals.keyEnumerator) {
  DF154WindowOriginal *original=[self.originals objectForKey:window];
  if(!window || !original || !scene || original.scene!=scene ||
     window.windowScene!=scene || !window.rootViewController)continue;
  // Revert only the windows we previously changed and still own. Do not
  // reorient the phone or restore stale windows from an older scene.
  window.frame=original.frame;
  window.bounds=original.bounds;
  [window setNeedsLayout];
  [window.rootViewController.view setNeedsLayout];
  ++restored;
 }
 [self postAck:@"restored" count:restored];
 [self.expiry invalidate];self.expiry=nil;
 self.originals=nil;self.state=nil;self.ownedScene=nil;self.applying=NO;
 self.lastAckPhase=nil;
 NSLog(@"[DF154AppState] bundle=%@ restore=%@ windows=%lu",
   self.bundle,reason,(unsigned long)restored);
}
- (void)receive:(NSNotification *)notification {
 NSDictionary *next=[notification.userInfo copy];
 dispatch_async(dispatch_get_main_queue(),^{
  // Never apply a stale or forged host lease after the user disabled the app.
  if(!DF155PilotAppID(self.bundle)) {
    if(self.state)[self restore:@"allowlist-revoked"];
    return;
  }
  NSTimeInterval now=NSDate.date.timeIntervalSince1970;
  if(!DF154Valid(next,now) ||
     ![next[@"bundleIdentifier"] isEqualToString:self.bundle])return;
  NSTimeInterval stamp=[next[@"issuedAt"] doubleValue];
  if(stamp<=self.newest)return;
  if(![next[@"active"] boolValue]) {
   if([next[@"owner"] isEqual:self.state[@"owner"]] &&
      [next[@"sceneIdentifier"] isEqual:self.state[@"sceneIdentifier"]] &&
      [next[@"requestID"] isEqual:self.state[@"requestID"]]) {
      self.newest=stamp;
      [self restore:@"owner-terminal"];
   }
   return;
  }
  // A different owner may replace a previous session, but never restore
  // another scene's frame from the new session's state.
  BOOL same=[next[@"owner"] isEqual:self.state[@"owner"]] &&
            [next[@"sceneIdentifier"] isEqual:self.state[@"sceneIdentifier"]] &&
            [next[@"requestID"] isEqual:self.state[@"requestID"]];
  if(self.state && !same)[self restore:@"owner-replaced"];
  self.state=next;self.newest=stamp;
  [self postAck:@"lease-accepted" count:0];
  if(!self.expiry) {
    __weak typeof(self) weakSelf=self;
    self.expiry=[NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(__unused NSTimer *timer){
      DF154GeneralAppStateRelay *relay=weakSelf;
      if(!relay)return;
      if(!DF154Valid(relay.state,NSDate.date.timeIntervalSince1970))
         [relay restore:@"lease-expired"];
    }];
  }
  [self reconcile];
 });
}
- (void)reconcile {
 if(!NSThread.isMainThread || self.applying)return;
 if(!DF155PilotAppID(self.bundle)) {
   if(self.state)[self restore:@"allowlist-revoked"];
   return;
 }
 if(
    !DF154Valid(self.state,NSDate.date.timeIntervalSince1970) ||
    ![self.state[@"active"] boolValue])return;
 // The original host's actual FBScene ID must match the UIKit scene;
 // a matching bundle name, window dimensions, or phone-main screen alone
 // is NOT proof that the app window belongs to the CarPlay request.
 UIWindowScene *target=nil;
 for(UIScene *candidate in UIApplication.sharedApplication.connectedScenes) {
  if(![candidate isKindOfClass:UIWindowScene.class])continue;
  NSString *identifier=DF154Object(candidate,"_sceneIdentifier");
  if(!DF154String(identifier))identifier=DF154Object(candidate,"identifier");
  if([identifier isEqual:self.state[@"sceneIdentifier"]]) {
    target=(UIWindowScene *)candidate;break;
  }
 }
 if(!target) {
   [self postAck:@"scene-unmatched" count:0];
   return;
 }
 [self postAck:@"scene-matched" count:0];
 if(self.ownedScene && self.ownedScene!=target)
   [self restore:@"UIKit-scene-replaced"];
 if(!self.state)return;
 self.ownedScene=target;
 if(!self.originals)self.originals=[NSMapTable weakToStrongObjectsMapTable];
 CGSize desired=CGSizeMake([self.state[@"width"] doubleValue],
                           [self.state[@"height"] doubleValue]);
 self.applying=YES;
 NSUInteger changed=0;
 for(UIWindow *window in target.windows) {
  if(window.hidden || window.windowScene!=target ||
     window.windowLevel!=UIWindowLevelNormal ||
     !window.rootViewController ||
     [NSStringFromClass(window.class) containsString:@"Keyboard"] ||
     [NSStringFromClass(window.class) containsString:@"TextEffects"])continue;
  if(fabs(window.bounds.size.width-desired.width)<1 &&
     fabs(window.bounds.size.height-desired.height)<1)continue;
  DF154WindowOriginal *original=[self.originals objectForKey:window];
  if(!original) {
    original=[DF154WindowOriginal new];
    original.frame=window.frame;original.bounds=window.bounds;
    original.scene=target;
    [self.originals setObject:original forKey:window];
  }
  CGRect newRect=(CGRect){CGPointZero,desired};
  window.frame=newRect;window.bounds=newRect;
  [window setNeedsLayout];
  [window.rootViewController.view setNeedsLayout];
  ++changed;
 }
 self.applying=NO;
 if(changed)[self postAck:@"window-adjusted" count:changed];
 if(changed)
   NSLog(@"[DF154AppState] bundle=%@ owner=%@ scene=%@ adjusted=%lu size=%@",
     self.bundle,self.state[@"owner"],self.state[@"sceneIdentifier"],
     (unsigned long)changed,NSStringFromCGSize(desired));
}
// QA176 H3: keyboard diagnostics. READ-ONLY: observes one keyboard
// appearance, records the facts that separate the hypotheses (frame
// overflow / ancestor clipping / wrong keyplane / phantom hardware
// keyboard), ships them to SpringBoard via a fixed DF156 mailbox and
// logs locally. It never touches the keyboard, the keyplane, the
// input mode, or any window frame. Flag: DFKBDiag176 (absent = ON).
- (void)df176KeyboardShown:(NSNotification *)note {
 if(!NSThread.isMainThread) {
  dispatch_async(dispatch_get_main_queue(),^{[self df176KeyboardShown:note];});
  return;
 }
 if(!DF176KBDiagEnabled())return;
 NSTimeInterval now=NSDate.date.timeIntervalSince1970;
 if(now-self.lastKbDiag176<2.0)return;
 self.lastKbDiag176=now;
 @try {
  NSMutableArray<UIWindow *> *all=[NSMutableArray array];
  for(UIScene *scene in UIApplication.sharedApplication.connectedScenes)
   if([scene isKindOfClass:UIWindowScene.class])
    [all addObjectsFromArray:((UIWindowScene *)scene).windows];
  [all addObjectsFromArray:UIApplication.sharedApplication.windows];
  UIWindow *kb=nil;
  for(UIWindow *w in all)
   if(!w.hidden && [NSStringFromClass(w.class) containsString:@"Keyboard"]) {
    kb=w;break;
   }
  NSString *keyplane=@"?";
  if(kb) {
   UIView *star=DF176FindView(kb,@"UIKeyboardLayoutStar",0);
   if(star) {
    id kp=DF154Object(star,"keyplaneName");
    if(!DF154String(kp)) {
     id plane=DF154Object(star,"keyplane");
     kp=plane?DF154Object(plane,"name"):nil;
    }
    if(DF154String(kp))keyplane=kp;
   }
  }
  NSString *inputMode=@"?",*lang=@"?";
  @try {
   Class ctl=NSClassFromString(@"UIKeyboardInputModeController");
   id shared=ctl?DF154Object((id)ctl,"sharedInputModeController"):nil;
   id current=shared?DF154Object(shared,"currentInputMode"):nil;
   id ident=current?DF154Object(current,"identifier"):nil;
   if(DF154String(ident))inputMode=ident;
  } @catch(__unused NSException *e) {}
  UITextInputMode *publicMode=UITextInputMode.activeInputModes.firstObject;
  if(DF154String(publicMode.primaryLanguage))lang=publicMode.primaryLanguage;
  NSString *hwGS=@"n/a",*hwBKS=@"n/a";
  @try {
   typedef BOOL (*DF176HWFn)(void);
   DF176HWFn gs=(DF176HWFn)dlsym(RTLD_DEFAULT,"GSEventIsHardwareKeyboardAttached");
   if(gs)hwGS=gs()?@"1":@"0";
   DF176HWFn bks=(DF176HWFn)dlsym(RTLD_DEFAULT,"BKSHIDServicesIsHardwareKeyboardAttached");
   if(bks)hwBKS=bks()?@"1":@"0";
  } @catch(__unused NSException *e) {}
  NSString *appFrame=@"?";
  if(self.ownedScene)
   for(UIWindow *w in self.ownedScene.windows)
    if(!w.hidden && w.windowLevel==UIWindowLevelNormal && w.rootViewController &&
       ![NSStringFromClass(w.class) containsString:@"Keyboard"]) {
     appFrame=NSStringFromCGRect(w.frame);break;
    }
  id endValue=note.userInfo[UIKeyboardFrameEndUserInfoKey];
  NSDictionary *rec=@{@"version":@1,@"bundle":self.bundle?:@"?",
   @"ts":@(now),
   @"kbClass":kb?NSStringFromClass(kb.class):@"none",
   @"kbFrame":kb?NSStringFromCGRect(kb.frame):@"?",
   @"kbScreenBounds":(kb && kb.screen)?NSStringFromCGRect(kb.screen.bounds):@"?",
   @"keyplane":keyplane,@"inputMode":inputMode,@"inputModeLang":lang,
   @"hwGSEvent":hwGS,@"hwBKS":hwBKS,
   @"notifName":note.name?:@"?",
   @"notifEnd":endValue?NSStringFromCGRect([endValue CGRectValue]):@"?",
   @"appFrame":appFrame};
  static DF156Mailbox kbBox;
  static BOOL kbReady=NO;
  if(!kbReady){ DF156Init(&kbBox,DF176KBDiagMailboxName); kbReady=YES; }
  NSData *bytes=[NSJSONSerialization dataWithJSONObject:rec options:0 error:nil];
  uint64_t generation=0;arc4random_buf(&generation,sizeof(generation));
  if(bytes && DF156Write(&kbBox,bytes.bytes,bytes.length,generation?:1))
   notify_post(DF176KBDiagWakeName);
  NSLog(@"[DF176KBDiag] bundle=%@ kb=%@ frame=%@ keyplane=%@ inputMode=%@ hw=%@/%@",
        self.bundle,rec[@"kbClass"],rec[@"kbFrame"],keyplane,inputMode,hwGS,hwBKS);
 } @catch(NSException *e) {
  NSLog(@"[DF176KBDiag] failed %@",e.name);
 }
}
@end

static DF154GeneralAppStateRelay *DF154Relay;
__attribute__((constructor))static void DF154StartAppSide(void) {
 @autoreleasepool {
  NSString *bundle=NSBundle.mainBundle.bundleIdentifier;
  NSString *path=NSBundle.mainBundle.bundlePath;
  if(!DF154String(bundle) || ![path hasSuffix:@".app"] ||
     NSBundle.mainBundle.infoDictionary[@"NSExtension"] ||
     !DF155PilotAppID(bundle) ||
     NSProcessInfo.processInfo.operatingSystemVersion.majorVersion!=16)return;
  dispatch_async(dispatch_get_main_queue(),^{
    DF154GeneralAppStateRelay *relay=[DF154GeneralAppStateRelay new];
    relay.bundle=bundle;
    relay.originals=[NSMapTable weakToStrongObjectsMapTable];
    if(!DF156Listen(bundle,NO,^(NSDictionary *state){
      [relay receive:[NSNotification notificationWithName:DF154StateNotification
          object:nil userInfo:state]];
    })) {
      NSLog(@"[DF154AppState] bundle=%@ transport-unavailable; no UIKit changes",bundle);
      return;
    }
    DF154Relay=relay;
    // QA176 H3: keyboard-appearance diagnostics (log only, flag-gated).
    if(DF176KBDiagEnabled()){
      [[NSNotificationCenter defaultCenter] addObserver:relay
        selector:@selector(df176KeyboardShown:)
        name:UIKeyboardWillShowNotification object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:relay
        selector:@selector(df176KeyboardShown:)
        name:UIKeyboardDidShowNotification object:nil];
    }
    [[NSNotificationCenter defaultCenter] addObserverForName:
      UISceneDidActivateNotification object:nil queue:NSOperationQueue.mainQueue
      usingBlock:^(__unused NSNotification *n){[relay reconcile];}];
    [[NSNotificationCenter defaultCenter] addObserverForName:
      UIWindowDidBecomeVisibleNotification object:nil queue:NSOperationQueue.mainQueue
      usingBlock:^(__unused NSNotification *n){[relay reconcile];}];
    [[NSNotificationCenter defaultCenter] addObserverForName:
      UIApplicationDidBecomeActiveNotification object:nil queue:NSOperationQueue.mainQueue
      usingBlock:^(__unused NSNotification *n){
        if(relay.state && !DF154Valid(relay.state,NSDate.date.timeIntervalSince1970))
          [relay restore:@"app-reentered-after-expiry"];
        else [relay reconcile];
      }];
    NSLog(@"[DF154AppState] bundle=%@ registered=exact-owned-scene-only enabled=%d",
      bundle,DF155EnabledPilotApp(bundle));
  });
 }
}
