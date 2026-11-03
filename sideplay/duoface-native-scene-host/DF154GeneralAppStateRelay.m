// First-party app-side lease consumer for a narrow explicitly injected app set.
// It NEVER changes the phone's unrelated scene, UIDevice rotation, root Dock,
// process lifecycle, player input, or other apps. Reverts its own frames only.
#import <UIKit/UIKit.h>
#import "DF154AppStateProtocol.h"
#import "DF155PilotAppScope.h"
#import "DFKBDiag176.h"
#define DF177_APP_SIDE_SENDER 1
#import "DFAppTouch177.h"
#import <dlfcn.h>
#import <objc/message.h>

// QA178 H1: delayed second keyboard capture after DidShow.
static const NSTimeInterval kDF178KBDelayedCaptureSeconds = 0.3;

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
@property(nonatomic) NSTimeInterval lastKbDid176;
- (void)df176KeyboardShown:(NSNotification *)notification;
- (void)df178CaptureKeyboard:(NSNotification *)note late:(BOOL)late;
- (void)df179KeyboardHidden:(NSNotification *)notification;
- (void)postAck:(NSString *)phase count:(NSUInteger)count;
- (void)receive:(NSNotification *)notification;
- (void)reconcile;
- (void)restore:(NSString *)reason;
@end
// QA179 H1: "keyboard fit" — when a hosted app's window has been
// resized away from the phone screen, the remote keyboard window
// still lays out against UIScreen.mainScreen (QA178 measured
// 414x736 against a 397x685 app window) and its bottom rows clip.
// The fit sets the keyboard window's frame to the app key window's
// frame at DidShow, and restores it at DidHide / when hosting ends.
// Scope: Google Maps + Waze only (the two ids are
// DF155PilotAppScope.h lines 26-27). Flag KeyboardFit179 in the
// qa176 plist, read fresh from file on every check, following the
// DF176KBDiagEnabled pattern; absent = ON; turn off in Filza.
static BOOL DF179KeyboardFitEnabled(void) {
 NSDictionary *p=[NSDictionary dictionaryWithContentsOfFile:
   DF176KBDiagPrefsPath];
 id v=[p isKindOfClass:NSDictionary.class]?p[@"KeyboardFit179"]:nil;
 return v?[v boolValue]:YES;
}
static BOOL DF179FitScope(NSString *bundle) {
 return [bundle isEqualToString:@"com.google.Maps"] ||
        [bundle isEqualToString:@"com.waze.iphone"];
}
static BOOL gDF179KbFitApplied=NO;
static BOOL gDF179KbHasSaved=NO;
static CGRect gDF179KbSavedFrame;
static DF156Mailbox gDF179Box;
static BOOL gDF179BoxReady=NO;
// Standalone fit records (the DidHide restore has no kbdiag capture
// to ride on) go through the same DF156 kbdiag mailbox + wake, with
// a fit179 segment Chrome logs as qa179-kbfit.
static void DF179WriteFitRecord(NSString *bundle, NSString *fitSeg) {
 if(!gDF179BoxReady){ DF156Init(&gDF179Box,DF176KBDiagMailboxName);
  gDF179BoxReady=YES; }
 NSDictionary *rec=@{@"version":@1,@"bundle":bundle?:@"?",
  @"ts":@(NSDate.date.timeIntervalSince1970),
  @"notifName":@"DF179Fit",@"fit179":fitSeg?:@""};
 NSData *bytes=[NSJSONSerialization dataWithJSONObject:rec
   options:0 error:nil];
 uint64_t generation=0;arc4random_buf(&generation,sizeof(generation));
 if(bytes && DF156Write(&gDF179Box,bytes.bytes,bytes.length,
   generation?:1))
  notify_post(DF176KBDiagWakeName);
}
// QA180: standalone record writers for the relay-alive markers (C)
// and the fit-cycle summaries (B). Same proven pattern as
// DF179WriteFitRecord: direct DF156Init on the kbdiag mailbox, so
// the markers do NOT depend on DF156Listen or the pilot channel.
static DF156Mailbox gDF180Box;
static BOOL gDF180BoxReady=NO;
static void DF180WriteSegmentRecord(NSString *bundle, NSString *notifName,
    NSString *key, NSString *seg) {
 @try {
  if(!gDF180BoxReady){ DF156Init(&gDF180Box,DF176KBDiagMailboxName);
   gDF180BoxReady=YES; }
  NSDictionary *rec=@{@"version":@1,@"bundle":bundle?:@"?",
   @"ts":@(NSDate.date.timeIntervalSince1970),
   @"notifName":notifName?:@"?",key:seg?:@""};
  NSData *bytes=[NSJSONSerialization dataWithJSONObject:rec
    options:0 error:nil];
  uint64_t generation=0;arc4random_buf(&generation,sizeof(generation));
  if(bytes && DF156Write(&gDF180Box,bytes.bytes,bytes.length,
    generation?:1))
   notify_post(DF176KBDiagWakeName);
 } @catch(__unused NSException *e) {}
}
static void DF180WriteAliveRecord(NSString *bundle, NSString *seg) {
 DF180WriteSegmentRecord(bundle,@"DF180Alive",@"alive180",seg);
}
// QA180 B: the keyboard-fit CYCLE. QA179 evaluated the fit at two
// fixed beats (DidShow, +0.3s); QA179's device export showed the
// keyboard window often does not exist in-process yet at either
// beat (11/28 evaluations no-kb-window). A cycle opens at each
// accepted DidShow (fit scope only), evaluates at 0/+0.3/+0.6/+1.2s
// and immediately when a Keyboard-class window becomes visible,
// and closes on a terminal outcome, on exhaustion, or on DidHide.
// Flag KeyboardCycle180 in the qa176 plist, read fresh from file
// on every check (DF176KBDiag pattern); absent = ON. Flag OFF =
// exactly the QA179 two-beat behaviour.
static BOOL DF180KeyboardCycleEnabled(void) {
 NSDictionary *p=[NSDictionary dictionaryWithContentsOfFile:
   DF176KBDiagPrefsPath];
 id v=[p isKindOfClass:NSDictionary.class]?p[@"KeyboardCycle180"]:nil;
 return v?[v boolValue]:YES;
}
static uint64_t gDF180CycleID=0;
static NSTimeInterval gDF180CycleStart=0;
static int gDF180CycleTries=0;
static BOOL gDF180CycleOpen=NO;
static BOOL gDF180CycleFound=NO;
static double gDF180CycleFoundAtMs=-1;
static NSNotification *gDF180CycleNote=nil;
static id gDF180CycleObserver=nil;
static int gDF180Checkpoint=-1;
static void DF180CycleFinish(NSString *bundle, NSString *outcome,
    NSString *reason) {
 if(!gDF180CycleOpen)return;
 gDF180CycleOpen=NO;
 if(gDF180CycleObserver){
  [NSNotificationCenter.defaultCenter
    removeObserver:gDF180CycleObserver];
  gDF180CycleObserver=nil;
 }
 double dur=(NSDate.date.timeIntervalSince1970-gDF180CycleStart)*1000.0;
 DF180WriteSegmentRecord(bundle,@"DF180Cycle",@"cyc180",
  [NSString stringWithFormat:
   @"outcome=%@ reason=%@ cyc=%llu tries=%d found=%d foundAt=%.0f dur=%.0f",
   outcome,reason,(unsigned long long)gDF180CycleID,gDF180CycleTries,
   gDF180CycleFound?1:0,gDF180CycleFoundAtMs,dur]);
 gDF180CycleNote=nil;
}
static void DF180CycleBegin(DF154GeneralAppStateRelay *relay,
    NSString *bundle, NSNotification *note) {
 DF180CycleFinish(bundle,@"cancelled",@"superseded");
 gDF180CycleID++;
 gDF180CycleStart=NSDate.date.timeIntervalSince1970;
 gDF180CycleTries=0;
 gDF180CycleFound=NO;
 gDF180CycleFoundAtMs=-1;
 gDF180CycleNote=note;
 gDF180CycleOpen=YES;
 uint64_t token=gDF180CycleID;
 gDF180CycleObserver=[NSNotificationCenter.defaultCenter
  addObserverForName:UIWindowDidBecomeVisibleNotification object:nil
  queue:NSOperationQueue.mainQueue
  usingBlock:^(__unused NSNotification *n){
   if(!gDF180CycleOpen || token!=gDF180CycleID)return;
   id obj=n.object;
   if(![obj isKindOfClass:UIWindow.class])return;
   if(![NSStringFromClass([obj class]) containsString:@"Keyboard"])
    return;
   gDF180Checkpoint=4;
   [relay df178CaptureKeyboard:gDF180CycleNote late:YES];
  }];
 // Scheduled retries: +0.3s (checkpoint 1, the QA178 beat), +0.6s
 // (2) and +1.2s (3, the last scheduled beat — a retryable outcome
 // there ends the cycle as exhausted).
 const double beats[3]={0.3,0.6,1.2};
 for(int cp=1;cp<=3;cp++){
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
    (int64_t)(beats[cp-1]*NSEC_PER_SEC)),dispatch_get_main_queue(),^{
     if(!gDF180CycleOpen || token!=gDF180CycleID)return;
     gDF180Checkpoint=cp;
     [relay df178CaptureKeyboard:gDF180CycleNote late:YES];
    });
 }
}
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
 // QA179: the DidShow capture also carries the keyboard fit, so it
 // may run on the fit path alone (fit flag on, scope bundle) even
 // when the diagnostics flag is off.
 BOOL diagOn=DF176KBDiagEnabled();
 BOOL fitPath=DF179KeyboardFitEnabled() && DF179FitScope(self.bundle) &&
   [note.name isEqualToString:UIKeyboardDidShowNotification];
 if(!diagOn && !fitPath)return;
 NSTimeInterval now=NSDate.date.timeIntervalSince1970;
 // QA177 H3: rate-limit PER notification name. QA176 used one shared
 // 2s gate, so WillShow (keyboard window not yet visible, kbClass=none)
 // always won and the informative DidShow record was swallowed.
 if([note.name isEqualToString:UIKeyboardDidShowNotification]){
  if(now-self.lastKbDid176<2.0)return;
  self.lastKbDid176=now;
 } else {
  if(now-self.lastKbDiag176<2.0)return;
  self.lastKbDiag176=now;
 }
 // QA180 B: in fit scope with the cycle flag on, an accepted
 // DidShow opens a fit cycle (evaluations at 0/+0.3/+0.6/+1.2s and
 // on keyboard-window visibility). Otherwise the QA179 two-beat
 // path below runs unchanged.
 BOOL cycleMode=[note.name isEqualToString:UIKeyboardDidShowNotification] &&
  DF180KeyboardCycleEnabled() && DF179FitScope(self.bundle);
 if(cycleMode){
  DF180CycleBegin(self,self.bundle,note);
  gDF180Checkpoint=0;
  [self df178CaptureKeyboard:note late:NO];
  return;
 }
 [self df178CaptureKeyboard:note late:NO];
 // QA178 H1: one delayed capture ~300ms after an accepted DidShow —
 // the keyboard frame may not be settled in the immediate capture.
 // The late capture runs only off an accepted DidShow and does not
 // pass the rate gates again.
 if([note.name isEqualToString:UIKeyboardDidShowNotification]){
  NSNotification *held=note;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
    (int64_t)(kDF178KBDelayedCaptureSeconds*NSEC_PER_SEC)),
    dispatch_get_main_queue(),^{
     if(DF176KBDiagEnabled() || DF179KeyboardFitEnabled())
      [self df178CaptureKeyboard:held late:YES];
    });
 }
}
- (void)df178CaptureKeyboard:(NSNotification *)note late:(BOOL)late {
 NSTimeInterval now=NSDate.date.timeIntervalSince1970;
 @try {
  NSMutableArray<UIWindow *> *all=[NSMutableArray array];
  for(UIScene *scene in UIApplication.sharedApplication.connectedScenes)
   if([scene isKindOfClass:UIWindowScene.class])
    [all addObjectsFromArray:((UIWindowScene *)scene).windows];
  [all addObjectsFromArray:UIApplication.sharedApplication.windows];
  // QA178 H1: the remote keyboard window is in NEITHER public list
  // (two device rounds: kbClass=none even at DidShow). Merge the
  // private all-windows enumeration (internal windows included),
  // guarded by respondsToSelector + try/catch. Read-only.
  @try {
   SEL allSel=NSSelectorFromString(
     @"allWindowsIncludingInternalWindows:onlyVisibleWindows:");
   if([UIWindow respondsToSelector:allSel]) {
    NSArray *priv=((NSArray *(*)(id,SEL,BOOL,BOOL))objc_msgSend)(
      (id)UIWindow.class,allSel,YES,NO);
    if([priv isKindOfClass:NSArray.class])
     for(id cand in priv)
      if([cand isKindOfClass:UIWindow.class] &&
         ![all containsObject:(UIWindow *)cand])
       [all addObject:(UIWindow *)cand];
   }
  } @catch(__unused NSException *e) {}
  UIWindow *kb=nil,*kbAny=nil;
  for(UIWindow *w in all)
   if([NSStringFromClass(w.class) containsString:@"Keyboard"]) {
    if(!kbAny)kbAny=w;
    if(!w.hidden){kb=w;break;}
   }
  if(!kb)kb=kbAny;
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
  // QA178 H1: the keyplane lookup must not depend on finding the
  // window. Fall back to the keyboard implementation's active
  // instance and its layout star. Read-only, fully guarded.
  if([keyplane isEqualToString:@"?"]) {
   @try {
    Class implCls=NSClassFromString(@"UIKeyboardImpl");
    id active=implCls?DF154Object((id)implCls,"activeInstance"):nil;
    UIView *star=nil;
    if(active) {
     const char *starGetters[]={"layoutStar","keyboardLayoutStar",
                                "_layoutStar"};
     for(int gi=0;gi<3 && !star;gi++) {
      id cand=DF154Object(active,starGetters[gi]);
      if([cand isKindOfClass:UIView.class])star=(UIView *)cand;
     }
    }
    if(star) {
     id kp=DF154Object(star,"keyplaneName");
     if(!DF154String(kp)) {
      id plane=DF154Object(star,"keyplane");
      kp=plane?DF154Object(plane,"name"):nil;
     }
     if(DF154String(kp))keyplane=kp;
    }
   } @catch(__unused NSException *e) {}
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
  // QA177 H3: keyboard window level + the scene's own coordinate
  // bounds (the "settings" size the app lives in) next to the actual
  // window frame above, so the exported block separates scene size
  // from presented size. kb.frame is already in screen coordinates.
  NSString *kbLevel=kb?[NSString stringWithFormat:@"%.1f",kb.windowLevel]:@"?";
  NSString *sceneBounds=self.ownedScene?
   NSStringFromCGRect(self.ownedScene.coordinateSpace.bounds):@"?";
  // QA178 H1: keyboard frame converted to screen coordinates and
  // the window's own transform, so the next export can separate
  // "laid out wide, presented narrow" from "laid out narrow".
  NSString *kbScreenFrame=@"?";
  if(kb && kb.screen){
   @try{ kbScreenFrame=NSStringFromCGRect(
     [kb convertRect:kb.bounds
       toCoordinateSpace:kb.screen.coordinateSpace]);
   } @catch(__unused NSException *e) {}
  }
  NSString *kbTransform=kb?[NSString stringWithFormat:
   @"%.2f,%.2f,%.2f,%.2f,%.0f,%.0f",
   kb.transform.a,kb.transform.b,kb.transform.c,kb.transform.d,
   kb.transform.tx,kb.transform.ty]:@"?";
  // QA178 H1: the size the APP believes it has: main screen bounds,
  // key-window bounds, scene coordinate bounds.
  UIWindow *keyWin=nil;
  for(UIWindow *w in all)if(w.isKeyWindow){keyWin=w;break;}
  NSString *appSelf=[NSString stringWithFormat:@"main=%@ key=%@ scene=%@",
   NSStringFromCGRect(UIScreen.mainScreen.bounds),
   keyWin?NSStringFromCGRect(keyWin.bounds):@"?",sceneBounds];
  // QA178 H1: compact dump of every window found (keyboard first),
  // capped in count and length so the record stays inside the
  // DF156 2048-byte mailbox budget with the other fields.
  NSMutableString *winDump=[NSMutableString string];
  NSMutableArray<UIWindow *> *ordered=[NSMutableArray array];
  if(kb)[ordered addObject:kb];
  for(UIWindow *w in all)if(w!=kb)[ordered addObject:w];
  NSUInteger dumpCount=0;
  for(UIWindow *w in ordered) {
   if(dumpCount>=10)break;
   [winDump appendFormat:@"%@%@{f%@|b%@|h%d|a%.1f|L%.0f|s%@}",
    dumpCount?@";":@"",NSStringFromClass(w.class),
    NSStringFromCGRect(w.frame),NSStringFromCGRect(w.bounds),
    w.hidden?1:0,w.alpha,w.windowLevel,
    w.screen?NSStringFromCGRect(w.screen.bounds):@"?"];
   dumpCount++;
  }
  if(winDump.length>880)
   winDump=[[winDump substringToIndex:880] mutableCopy];
  // QA179 H3: read-only selector-ownership probe, once per app
  // session (computed once, attached to the first 3 captures so a
  // mailbox overwrite cannot lose it). Responds-checks only: no
  // selector is ever invoked and nothing is hooked. i=instances
  // respond, c=the class object responds.
  static NSString *selProbe179=nil;
  static int selAttach179=0;
  if(!selProbe179) {
   @try {
    NSArray *classes=@[@"UIKeyboardImpl",@"UIKeyboardLayoutStar",
     @"UIKeyboard",@"UIRemoteKeyboardWindow",
     @"UIInputWindowController",@"UIKeyboardInputModeController"];
    NSArray *sels=@[@"keyboardWidthForScreen:withOrientation:",
     @"keyboardWidth",@"keyboardScreenReferenceSize"];
    NSMutableString *probe=[NSMutableString string];
    for(NSString *cn in classes) {
     Class cls=NSClassFromString(cn);
     [probe appendFormat:@"%@%@:",probe.length?@";":@"",cn];
     if(!cls){ [probe appendString:@"noclass"]; continue; }
     for(NSString *sn in sels) {
      SEL sel=NSSelectorFromString(sn);
      [probe appendFormat:@" %@=i%dc%d",sn,
       [cls instancesRespondToSelector:sel]?1:0,
       class_respondsToSelector(cls,sel)?1:0];
     }
    }
    selProbe179=[probe copy];
   } @catch(__unused NSException *e) { selProbe179=@"probe-failed"; }
  }
  NSString *selSeg=(selAttach179<3)?selProbe179:nil;
  if(selSeg)selAttach179++;
  // QA179 H1/H2: keyboard fit evaluation. DidShow captures only
  // (the immediate one and the QA178 late one). Everything is
  // guarded; a failure skips the fit and is reported in the segment.
  NSString *fitSeg=nil;
  if([note.name isEqualToString:UIKeyboardDidShowNotification] &&
     DF179FitScope(self.bundle)) {
   @try {
    CGRect screenR=UIScreen.mainScreen.bounds;
    UIWindow *fitKey=nil;
    for(UIWindow *w in all) {
     NSString *wc=NSStringFromClass(w.class);
     if([wc containsString:@"Keyboard"] ||
        [wc containsString:@"TextEffects"])continue;
     if(fabs(w.windowLevel-UIWindowLevelNormal)>0.5)continue;
     if(w.isKeyWindow){fitKey=w;break;}
     if(!fitKey)fitKey=w;
     else if(w.bounds.size.width*w.bounds.size.height >
             fitKey.bounds.size.width*fitKey.bounds.size.height)
      fitKey=w;
    }
    CGRect kbBefore=kb?kb.frame:CGRectNull;
    // QA180 D-B (Spec condition set): log the ORIGINAL value of
    // keyboardScreenReferenceSize on the keyboard window, read
    // BEFORE the fit chain below runs (the late capture re-reads
    // it after the fit, so one export shows pre and post). Read
    // only: respondsToSelector + try/catch, never used for any
    // decision. The selector is not in any test's forbidden list.
    NSString *refSize=@"?";
    if(kb) {
     @try {
      SEL rsSel=NSSelectorFromString(@"keyboardScreenReferenceSize");
      if([kb respondsToSelector:rsSel]) {
       CGSize rv=((CGSize(*)(id,SEL))objc_msgSend)(kb,rsSel);
       refSize=NSStringFromCGSize(rv);
      }
     } @catch(__unused NSException *e) { refSize=@"exc"; }
    }
    NSString *subs=@"";
    if(kb) {
     NSMutableString *sb=[NSMutableString string];
     NSUInteger di=0;
     for(UIView *sv in kb.subviews) {
      if(di>=6)break;
      [sb appendFormat:@"%@%@%@",
       di?@";":@"",NSStringFromClass(sv.class),
       NSStringFromCGRect(sv.frame)];
      NSUInteger ci=0;
      for(UIView *cv in sv.subviews) {
       if(ci>=3)break;
       [sb appendFormat:@">%@%@",NSStringFromClass(cv.class),
        NSStringFromCGRect(cv.frame)];
       ci++;
      }
      di++;
     }
     if(sb.length>320)sb=[[sb substringToIndex:320] mutableCopy];
     subs=sb;
    }
    NSString *action=nil,*reason=@"-";
    if(!DF179KeyboardFitEnabled()) {
     if(gDF179KbFitApplied && kb) {
      CGRect target=gDF179KbHasSaved?gDF179KbSavedFrame:screenR;
      if(!CGRectEqualToRect(kb.frame,target))kb.frame=target;
      gDF179KbFitApplied=NO;gDF179KbHasSaved=NO;
      action=@"restored";reason=@"flag-off";
     } else { action=@"skip";reason=@"flag-off"; }
    } else if(!kb) { action=@"skip";reason=@"no-kb-window"; }
    else if(!fitKey) { action=@"skip";reason=@"no-key-window"; }
    else if(CGSizeEqualToSize(fitKey.bounds.size,screenR.size)) {
     if(gDF179KbFitApplied) {
      CGRect target=gDF179KbHasSaved?gDF179KbSavedFrame:screenR;
      if(!CGRectEqualToRect(kb.frame,target))kb.frame=target;
      gDF179KbFitApplied=NO;gDF179KbHasSaved=NO;
      action=@"restored";reason=@"not-hosted";
     } else { action=@"skip";reason=@"not-hosted"; }
    } else if(CGRectEqualToRect(kb.frame,fitKey.frame)) {
     action=@"skip";reason=@"already-fit";
    } else {
     if(!gDF179KbHasSaved){ gDF179KbSavedFrame=kb.frame;
      gDF179KbHasSaved=YES; }
     kb.frame=fitKey.frame;
     gDF179KbFitApplied=YES;
     action=@"applied";
    }
    // QA180 B: cycle accounting. Only captures that belong to an
    // open cycle (checkpoint set by the cycle scheduler) take
    // part; terminal outcomes close the cycle, retryable ones
    // (no-kb-window / no-key-window) close it as exhausted only
    // at the last scheduled beat (checkpoint 3).
    NSString *cycSeg=@"";
    if(gDF180CycleOpen && gDF180Checkpoint>=0) {
     gDF180CycleTries++;
     if(kb && !gDF180CycleFound) {
      gDF180CycleFound=YES;
      gDF180CycleFoundAtMs=(now-gDF180CycleStart)*1000.0;
     }
     cycSeg=[NSString stringWithFormat:@" cyc=%llu try=%d foundAt=%.0f",
      (unsigned long long)gDF180CycleID,gDF180CycleTries,
      gDF180CycleFoundAtMs];
     BOOL terminal=[action isEqualToString:@"applied"] ||
      [reason isEqualToString:@"already-fit"] ||
      [reason isEqualToString:@"not-hosted"] ||
      [reason isEqualToString:@"flag-off"];
     if(terminal) {
      DF180CycleFinish(self.bundle,
       [action isEqualToString:@"applied"]?@"applied":reason,
       [action isEqualToString:@"applied"]?@"-":reason);
     } else if(gDF180Checkpoint==3) {
      DF180CycleFinish(self.bundle,@"exhausted",reason);
     }
    }
    gDF180Checkpoint=-1;
    fitSeg=[NSString stringWithFormat:
     @"action=%@ reason=%@ late=%d screen=%@ key=%@ kbBefore=%@ kbAfter=%@ subs=%@ refSize=%@ refWhen=%@%@",
     action,reason,late?1:0,NSStringFromCGRect(screenR),
     fitKey?NSStringFromCGRect(fitKey.frame):@"?",
     kb?NSStringFromCGRect(kbBefore):@"?",
     kb?NSStringFromCGRect(kb.frame):@"?",subs,refSize,
     late?@"post":@"pre",cycSeg];
   } @catch(NSException *e) {
    fitSeg=[NSString stringWithFormat:@"action=skip reason=exception-%@",
     e.name?:@"?"];
   }
  }
  // Keep the whole record inside the DF156 mailbox budget when the
  // QA179 segments ride along.
  if((fitSeg || selSeg) && winDump.length>620)
   winDump=[[winDump substringToIndex:620] mutableCopy];
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
   @"appFrame":appFrame,
   @"kbLevel":kbLevel,@"sceneBounds":sceneBounds,
   @"late":@(late?1:0),@"kbScreenFrame":kbScreenFrame,
   @"kbTransform":kbTransform,@"appSelf":appSelf,
   @"winDump":winDump,
   @"notifBegin":note.userInfo[UIKeyboardFrameBeginUserInfoKey]?
    NSStringFromCGRect([note.userInfo[UIKeyboardFrameBeginUserInfoKey]
     CGRectValue]):@"?",
   @"fit179":fitSeg?:@"",@"sel179":selSeg?:@""};
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
// QA179 H1: restore the keyboard window's frame when the keyboard
// hides, so a fitted frame never sticks after the hosted session.
- (void)df179KeyboardHidden:(NSNotification *)note {
 (void)note;
 if(!NSThread.isMainThread) {
  dispatch_async(dispatch_get_main_queue(),
   ^{[self df179KeyboardHidden:note];});
  return;
 }
 // QA180 B: the keyboard going away cancels any open fit cycle.
 DF180CycleFinish(self.bundle,@"cancelled",@"did-hide");
 if(!gDF179KbFitApplied)return;
 @try {
  NSMutableArray<UIWindow *> *all=[NSMutableArray array];
  for(UIScene *scene in UIApplication.sharedApplication.connectedScenes)
   if([scene isKindOfClass:UIWindowScene.class])
    [all addObjectsFromArray:((UIWindowScene *)scene).windows];
  [all addObjectsFromArray:UIApplication.sharedApplication.windows];
  @try {
   SEL allSel=NSSelectorFromString(
     @"allWindowsIncludingInternalWindows:onlyVisibleWindows:");
   if([UIWindow respondsToSelector:allSel]) {
    NSArray *priv=((NSArray *(*)(id,SEL,BOOL,BOOL))objc_msgSend)(
      (id)UIWindow.class,allSel,YES,NO);
    if([priv isKindOfClass:NSArray.class])
     for(id cand in priv)
      if([cand isKindOfClass:UIWindow.class] &&
         ![all containsObject:(UIWindow *)cand])
       [all addObject:(UIWindow *)cand];
   }
  } @catch(__unused NSException *e) {}
  UIWindow *kb=nil;
  for(UIWindow *w in all)
   if([NSStringFromClass(w.class) containsString:@"Keyboard"]) {
    kb=w;if(!w.hidden)break;
   }
  CGRect screenR=UIScreen.mainScreen.bounds;
  CGRect target=gDF179KbHasSaved?gDF179KbSavedFrame:screenR;
  CGRect before=kb?kb.frame:CGRectNull;
  if(kb && !CGRectEqualToRect(kb.frame,target))kb.frame=target;
  gDF179KbFitApplied=NO;gDF179KbHasSaved=NO;
  DF179WriteFitRecord(self.bundle,[NSString stringWithFormat:
   @"action=restored reason=did-hide screen=%@ kbBefore=%@ kbAfter=%@",
   NSStringFromCGRect(screenR),
   kb?NSStringFromCGRect(before):@"?",
   kb?NSStringFromCGRect(kb.frame):@"?"]);
 } @catch(NSException *e) {
  gDF179KbFitApplied=NO;
  NSLog(@"[DF179KBfit] restore failed %@",e.name);
 }
}
@end

static DF154GeneralAppStateRelay *DF154Relay;
__attribute__((constructor))static void DF154StartAppSide(void) {
 @autoreleasepool {
  NSString *bundle=NSBundle.mainBundle.bundleIdentifier;
  NSString *path=NSBundle.mainBundle.bundlePath;
  // QA180 C: relay-alive marker R1 — the very first statement, so
  // its presence proves the dylib was injected into this process.
  // Written directly to the kbdiag mailbox (no DF156Listen, no
  // pilot channel), because the guards below are the suspects.
  DF180WriteAliveRecord(bundle,@"stage=R1");
  // The compound guard is split into named conditions WITHOUT
  // changing its semantics, so marker R2 can name the failing
  // one (b=bundle, p=.app path, e=no NSExtension key, s=pilot
  // scope, i=iOS 16).
  BOOL gB=DF154String(bundle);
  BOOL gP=[path hasSuffix:@".app"];
  BOOL gE=NSBundle.mainBundle.infoDictionary[@"NSExtension"]==nil;
  BOOL gS=gB?DF155PilotAppID(bundle):NO;
  BOOL gI=NSProcessInfo.processInfo.operatingSystemVersion.majorVersion==16;
  if(!(gB && gP && gE && gS && gI)){
   DF180WriteAliveRecord(bundle,[NSString stringWithFormat:
    @"stage=R2 guards=b%d,p%d,e%d,s%d,i%d listen=-1 reg=0",
    gB?1:0,gP?1:0,gE?1:0,gS?1:0,gI?1:0]);
   return;
  }
  dispatch_async(dispatch_get_main_queue(),^{
    DF154GeneralAppStateRelay *relay=[DF154GeneralAppStateRelay new];
    relay.bundle=bundle;
    relay.originals=[NSMapTable weakToStrongObjectsMapTable];
    if(!DF156Listen(bundle,NO,^(NSDictionary *state){
      [relay receive:[NSNotification notificationWithName:DF154StateNotification
          object:nil userInfo:state]];
    })) {
      // QA180 C: marker R2, listen-failure variant.
      DF180WriteAliveRecord(bundle,
       @"stage=R2 guards=ok listen=0 reg=0");
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
    // QA179 H1: keyboard fit. DidHide drives the restore; if the
    // diagnostics flag was off at start, register DidShow on the
    // fit path alone so the fit still runs in its scope bundles.
    if(DF179KeyboardFitEnabled()){
      [[NSNotificationCenter defaultCenter] addObserver:relay
        selector:@selector(df179KeyboardHidden:)
        name:UIKeyboardDidHideNotification object:nil];
      if(!DF176KBDiagEnabled()){
        [[NSNotificationCenter defaultCenter] addObserver:relay
          selector:@selector(df176KeyboardShown:)
          name:UIKeyboardDidShowNotification object:nil];
      }
    }
    // QA177 H1: app-side "user touched" signal for controls recall.
    // This constructor only proceeds inside a DF155 pilot app, so the
    // sendEvent: observation hook (original first, read-only) is
    // installed with the right scope. See DFAppTouch177.h.
    DF177InstallAppTouchHook(bundle);
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
    // QA180 C: marker R2, success variant — guards passed, the
    // transport listens and every observer is registered.
    DF180WriteAliveRecord(bundle,
     @"stage=R2 guards=ok listen=1 reg=1");
    NSLog(@"[DF154AppState] bundle=%@ registered=exact-owned-scene-only enabled=%d",
      bundle,DF155EnabledPilotApp(bundle));
  });
 }
}
