// DuoFace QA163 native CarPlay overlay owner. Independently authored.
// Reuse existing Speed8 renderer, do NOT create/steal UIWindow or modify Dock.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "DFCarPlayOwnerLease.h"
#import "speed8/DFNative8SpeedHUDView.h"
#import <math.h>

static NSString *const DF163SessionPath =
    @"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist";
static NSString *const DF165StandaloneLease =
    @"/var/mobile/Library/Preferences/com.duoface.nativehost.standalone144-sb-lease.plist";

@interface DFSpeedNativeOverlay163 : NSObject
@property(nonatomic,strong) DFNative8SpeedHUDView *hud;
@property(nonatomic,weak) UIWindow *ownerWindow;
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,assign) NSUInteger previousWindowCount;
@end

@implementation DFSpeedNativeOverlay163
+ (instancetype)shared {
    static DFSpeedNativeOverlay163 *controller;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ controller=[DFSpeedNativeOverlay163 new]; });
    return controller;
}
- (BOOL)isCarPlayProcess {
    NSString *process=NSProcessInfo.processInfo.processName;
    NSString *bundle=NSBundle.mainBundle.bundleIdentifier.lowercaseString;
    return [process isEqualToString:@"CarPlay"] ||
           [process isEqualToString:@"CarPlayApp"] ||
           ([bundle isEqualToString:@"com.apple.dashboard"] &&
             [process.lowercaseString isEqualToString:@"dashboard"]);
}
- (void)install {
    if(![self isCarPlayProcess])return;
    NSNotificationCenter *n=NSNotificationCenter.defaultCenter;
    [n addObserver:self selector:@selector(sceneChanged:)
              name:UIApplicationDidBecomeActiveNotification object:nil];
    [n addObserver:self selector:@selector(sceneChanged:)
              name:UIApplicationWillResignActiveNotification object:nil];
    [n addObserver:self selector:@selector(sceneChanged:)
              name:UIWindowDidBecomeVisibleNotification object:nil];
    [n addObserver:self selector:@selector(sceneChanged:)
              name:UIWindowDidBecomeHiddenNotification object:nil];
    [n addObserver:self selector:@selector(sceneChanged:)
              name:UISceneDidActivateNotification object:nil];
    [n addObserver:self selector:@selector(sceneChanged:)
              name:UISceneDidEnterBackgroundNotification object:nil];
    self.timer=[NSTimer scheduledTimerWithTimeInterval:1.5 target:self
                      selector:@selector(poll:) userInfo:nil repeats:YES];
    [self poll:nil];
}
- (void)sceneChanged:(NSNotification *)note { (void)note; [self poll:nil]; }
- (BOOL)duoFaceOwnsExternalChrome {
    // Reuse exact QA162 validated lease policy, including Home revoke.
    // Native CarPlay bubble is suppressed when DuoFace SpringBoard Chrome owns
    // the display. The DuoFace pane mounts its own Speed8 renderer then.
    NSDictionary *pulse=[NSDictionary dictionaryWithContentsOfFile:DF163SessionPath];
    return [pulse isKindOfClass:NSDictionary.class] && DFOwnerAcceptPulse(pulse);
}
- (UIWindow *)visibleExternalOwner {
    NSMutableOrderedSet<UIWindow *> *set=[NSMutableOrderedSet orderedSet];
    for(UIWindow *w in UIApplication.sharedApplication.windows)
        if([w isKindOfClass:UIWindow.class])[set addObject:w];
    for(UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if(![scene isKindOfClass:UIWindowScene.class])continue;
        UIWindowScene *windowScene=(UIWindowScene *)scene;
        if(windowScene.activationState==UISceneActivationStateBackground ||
           windowScene.activationState==UISceneActivationStateUnattached)continue;
        [set addObjectsFromArray:windowScene.windows];
    }
    // Selection is an owned REAL UIKit window, not a guessed external screen,
    // cloned Apple CPWindow, private frame, or newly created top-level window.
    UIWindow *winner=nil;
    CGFloat maxArea=0;
    for(UIWindow *w in set){
        if(w.hidden || w.alpha<0.05 || !w.screen ||
           w.screen==UIScreen.mainScreen || !w.rootViewController ||
           w.windowLevel<UIWindowLevelNormal-1.0 ||
           w.windowLevel>UIWindowLevelNormal+2.0)continue;
        UIWindowScene *scene=w.windowScene;
        if(scene && (scene.activationState==UISceneActivationStateBackground ||
                     scene.activationState==UISceneActivationStateUnattached))continue;
        NSString *klass=NSStringFromClass(w.class);
        if([klass containsString:@"Keyboard"] || [klass containsString:@"TextEffects"] ||
           [klass containsString:@"StatusBar"] || [klass containsString:@"Dock"] ||
           [klass containsString:@"Alert"])continue;
        UIView *root=w.rootViewController.viewIfLoaded;
        if(!root || root.hidden || root.alpha<0.05)continue;
        CGSize sz=w.bounds.size;
        if(sz.width<280 || sz.height<150 || !isfinite(sz.width) ||
           !isfinite(sz.height))continue;
        CGFloat area=sz.width*sz.height;
        if(area>maxArea){ winner=w; maxArea=area; }
    }
    return winner;
}
- (void)detach {
    [self.hud removeFromSuperview];
    self.hud.ownerWindow=nil;
    self.hud=nil;
    self.ownerWindow=nil;
}
- (void)poll:(NSTimer *)timer {
    (void)timer;
    // Never cover native CarPlay Home when an attested DuoFace pane owner is
    // visible; otherwise the native CarPlay process draws its own HUD.
    if([self duoFaceOwnsExternalChrome]){ [self detach]; return; }
    // A native-Home standalone Safari/other selected app is SpringBoard-owned.
    // Its Speed8 bubble must be attached to that real external UIWindow, not
    // the lower CarPlayApp native window. A fresh lease prevents doubles.
    NSDictionary *standalone=[NSDictionary dictionaryWithContentsOfFile:DF165StandaloneLease];
    NSTimeInterval age=NSDate.date.timeIntervalSince1970-
                         [standalone[@"Timestamp"] doubleValue];
    if([standalone[@"HUDOwnerVisible"] boolValue] &&
       [standalone[@"Role"] isEqualToString:@"SpringBoard-Standalone144"] &&
       age>=0 && age<2.0){
        if(self.hud)NSLog(@"[DuoFaceSpeed8] QA165 native HUD suppressed for standalone owner");
        [self detach];return;
    }
    UIWindow *candidate=[self visibleExternalOwner];
    if(!candidate){
        if(self.ownerWindow)[self detach];
        return;
    }
    UIView *root=candidate.rootViewController.viewIfLoaded;
    if(!root)return;
    if(self.ownerWindow==candidate && self.hud.superview==root)return;
    [self detach];
    DFNative8SpeedHUDView *view=[[DFNative8SpeedHUDView alloc]
                                  initWithFrame:CGRectMake(0,0,104,46)];
    // Only the actual 104x46 HUD bubble is interactive for drag/long-press.
    // All other CarPlay inputs remain bound to original UIKit/Dock handlers.
    self.ownerWindow=candidate;
    self.hud=view;
    view.ownerWindow=candidate;
    [root addSubview:view];
    [view restoreSavedPosition];
    NSLog(@"[DuoFaceSpeed8] QA163 native owner attached process=%@ class=%@",
          NSProcessInfo.processInfo.processName,NSStringFromClass(candidate.class));
}
@end

__attribute__((constructor)) static void DF163StartNativeSpeedOverlay(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[DFSpeedNativeOverlay163 shared] install];
    });
}
