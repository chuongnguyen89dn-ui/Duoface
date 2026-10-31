// First-party app-side lease consumer for a narrow explicitly injected app set.
// It NEVER changes the phone's unrelated scene, UIDevice rotation, root Dock,
// process lifecycle, player input, or other apps. Reverts its own frames only.
#import <UIKit/UIKit.h>
#import "DF154AppStateProtocol.h"

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
- (void)receive:(NSNotification *)notification;
- (void)reconcile;
- (void)restore:(NSString *)reason;
@end
@implementation DF154GeneralAppStateRelay
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
 [self.expiry invalidate];self.expiry=nil;
 self.originals=nil;self.state=nil;self.ownedScene=nil;self.applying=NO;
 NSLog(@"[DF154AppState] bundle=%@ restore=%@ windows=%lu",
   self.bundle,reason,(unsigned long)restored);
}
- (void)receive:(NSNotification *)notification {
 NSDictionary *next=[notification.userInfo copy];
 dispatch_async(dispatch_get_main_queue(),^{
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
 if(!NSThread.isMainThread || self.applying ||
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
 if(!target)return;
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
 if(changed)
   NSLog(@"[DF154AppState] bundle=%@ owner=%@ scene=%@ adjusted=%lu size=%@",
     self.bundle,self.state[@"owner"],self.state[@"sceneIdentifier"],
     (unsigned long)changed,NSStringFromCGSize(desired));
}
@end

static DF154GeneralAppStateRelay *DF154Relay;
__attribute__((constructor))static void DF154StartAppSide(void) {
 @autoreleasepool {
  NSString *bundle=NSBundle.mainBundle.bundleIdentifier;
  NSString *path=NSBundle.mainBundle.bundlePath;
  if(!DF154String(bundle) || ![path hasSuffix:@".app"] ||
     NSBundle.mainBundle.infoDictionary[@"NSExtension"] ||
     [bundle isEqualToString:@"com.google.ios.youtube"] ||
     [bundle isEqualToString:@"com.lumi.GOFA"] ||
     NSProcessInfo.processInfo.operatingSystemVersion.majorVersion!=16)return;
  dispatch_async(dispatch_get_main_queue(),^{
    id center=DF154Center();
    if(!center)return;
    DF154GeneralAppStateRelay *relay=[DF154GeneralAppStateRelay new];
    relay.bundle=bundle;
    relay.originals=[NSMapTable weakToStrongObjectsMapTable];
    DF154Relay=relay;
    [center addObserver:relay selector:@selector(receive:)
                  name:DF154StateNotification object:nil];
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
    NSLog(@"[DF154AppState] bundle=%@ registered=exact-owned-scene-only",bundle);
  });
 }
}
