// Independent DuoFace per-app viewport reconciliation.
// A SpringBoard host request alone is NOT renderer acceptance.
// Never spoof scene roles, modify device idiom, or touch system CarPlay Dock.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <notify.h>
#import <math.h>
#import "DFAppViewportProtocol.h"
#import "DFAppEligibility.h"

static int sDuoViewportToken=-1;
static NSString *sDuoBundle;
static NSTimeInterval sDuoLastLog;
static BOOL sDuoActive;
static void DFVPLog(NSString *state, UIWindowScene *scene, CGSize target) {
    NSTimeInterval now=NSDate.date.timeIntervalSince1970;
    if(now-sDuoLastLog<1.5 && ![state isEqualToString:@"reflow-applied"])return;
    sDuoLastLog=now;
    NSLog(@"[DuoFaceAppViewport] bundle=%@ phase=%@ scene=%@ target=%@",
          sDuoBundle,state,scene?NSStringFromCGRect(scene.coordinateSpace.bounds):@"unavailable",
          NSStringFromCGSize(target));
}
static BOOL DFVPMatches(CGSize measured,CGSize expected) {
    return isfinite(measured.width) && isfinite(measured.height) &&
      fabs(measured.width-expected.width)<2.5 &&
      fabs(measured.height-expected.height)<2.5;
}
static void DFVPReconcile(void) {
    if(!NSThread.isMainThread){
        dispatch_async(dispatch_get_main_queue(),^{DFVPReconcile();});
        return;
    }
    if(sDuoViewportToken<0)return;
    uint64_t raw=0;
    uint32_t now=(uint32_t)NSDate.date.timeIntervalSince1970;
    if(notify_get_state(sDuoViewportToken,&raw)!=NOTIFY_STATUS_OK)return;
    unsigned width=0,height=0;
    int active=0;
    if(!DFVPUnpack(raw,now,&width,&height,&active)){
        if(sDuoActive)DFVPLog(@"stale-or-invalid-state",nil,CGSizeZero);
        sDuoActive=NO;
        return;
    }
    sDuoActive=active!=0;
    if(!active)return;
    CGSize requested=CGSizeMake(width,height);
    // Only the app's ACTUAL UIKit UIWindowScene may authorize reflow.
    // A stale FBScene frame, the ordinary phone scene, and legacy portrait
    // renderers are left untouched rather than forced into a landscape crop.
    for(UIScene *candidate in UIApplication.sharedApplication.connectedScenes) {
        if(![candidate isKindOfClass:UIWindowScene.class])continue;
        UIWindowScene *scene=(UIWindowScene *)candidate;
        if(!DFVPMatches(scene.coordinateSpace.bounds.size,requested)){
            DFVPLog(@"app-scene-rejected-host-frame",scene,requested);
            continue;
        }
        for(UIWindow *window in scene.windows) {
            if(window.hidden || window.windowScene!=scene)continue;
            if(!window.rootViewController ||
               [NSStringFromClass(window.class) containsString:@"TextEffects"] ||
               [NSStringFromClass(window.class) containsString:@"Keyboard"])continue;
            CGRect target=(CGRect){CGPointZero,requested};
            if(DFVPMatches(window.bounds.size,requested) &&
               DFVPMatches(window.frame.size,requested))continue;
            window.frame=target;
            [window.rootViewController.view setNeedsLayout];
            [window.rootViewController.view layoutIfNeeded];
            DFVPLog(@"reflow-applied",scene,requested);
        }
    }
}
__attribute__((constructor)) static void DFVPStart(void) {
    @autoreleasepool {
        NSString *bundle=NSBundle.mainBundle.bundleIdentifier;
        // Only installed, user-facing .app bundles admitted by the very
        // same policy as DuoFace's existing on-screen app picker.
        // All other UIKit processes, extensions, daemons and DuoFace
        // internals exit without registering callbacks or modifying UIKit.
        NSString *bundlePath=NSBundle.mainBundle.bundlePath;
        if(!DFIsEligibleAppID(bundle) || ![bundlePath hasSuffix:@".app"] ||
           NSBundle.mainBundle.infoDictionary[@"NSExtension"])return;
        if(NSProcessInfo.processInfo.operatingSystemVersion.majorVersion!=16)return;
        sDuoBundle=[bundle copy];
        NSString *name=[@"com.duoface.viewport.v1." stringByAppendingString:bundle];
        int token=-1;
        int status=notify_register_dispatch(name.UTF8String,&token,
              dispatch_get_main_queue(),^(int ignored){(void)ignored;DFVPReconcile();});
        if(status!=NOTIFY_STATUS_OK)return;
        sDuoViewportToken=token;
        [[NSNotificationCenter defaultCenter] addObserverForName:
            UISceneDidActivateNotification object:nil queue:NSOperationQueue.mainQueue
            usingBlock:^(NSNotification *event){(void)event;DFVPReconcile();}];
        [[NSNotificationCenter defaultCenter] addObserverForName:
            UIWindowDidBecomeVisibleNotification object:nil queue:NSOperationQueue.mainQueue
            usingBlock:^(NSNotification *event){(void)event;DFVPReconcile();}];
        dispatch_async(dispatch_get_main_queue(),^{DFVPReconcile();});
        NSLog(@"[DuoFaceAppViewport] ready bundle=%@, scene-verified-only",bundle);
    }
}
