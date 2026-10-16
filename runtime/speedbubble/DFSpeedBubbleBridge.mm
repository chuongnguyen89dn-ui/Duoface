// DuoFace Native12 candidate: ONE GOFA-inspired speed HUD for FOUR alternative app data sources.
// Inject this module into the verified DuoFace CarPlay process only; no global SpringBoard HUD.
// Native12 CBWindow selectors and rootWindow class are verified by existing audits.
// Speed4 split-host candidate: device visibility is not yet verified.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "DFSpeedTransport.h"
#import <math.h>
#include <string.h>

// Actual DuoFace Native12 owner; not the Apple CarPlay home window.
@interface CBWindow : NSObject
@property(nonatomic,readonly) UIWindow *rootWindow;
@property(nonatomic,readonly) UIViewController *rootViewController;
@property(nonatomic,readonly) UIView *contentView;
@property(nonatomic,readonly) BOOL isVisible;
@end

@interface DFSpeedNativeHUD : UIView
@property(nonatomic,strong) UILabel *current;
@property(nonatomic,strong) UILabel *limit;
@property(nonatomic,strong) UILabel *unit;
@property(nonatomic,strong) UIView *limitRing;
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,strong) UILabel *dismissTarget;
@property(nonatomic,assign) BOOL dismissedForSession;
@property(nonatomic,weak) CBWindow *ownerBridge;
- (void)pan:(UIPanGestureRecognizer *)recognizer;
- (void)restoreSavedPosition;
- (void)tick:(NSTimer *)timer;
- (void)stop;
@end

@implementation DFSpeedNativeHUD
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self=[super initWithFrame:frame])) {
        // GOFA: only the bubble grabs taps/drags; the rest of CarPlay keeps touches.
        self.userInteractionEnabled=YES;
        UIPanGestureRecognizer *move=[[UIPanGestureRecognizer alloc]
            initWithTarget:self action:@selector(pan:)];
        [self addGestureRecognizer:move];
        // GOFA reference: dark horizontal pill, bright speed text, traffic-sign limit.
        self.backgroundColor=[UIColor colorWithRed:0.12 green:0.16 blue:0.20 alpha:0.94];
        self.layer.cornerRadius=32;
        self.layer.masksToBounds=YES;
        _current=[UILabel new];
        _current.textAlignment=NSTextAlignmentCenter;
        _current.textColor=UIColor.whiteColor;
        _current.font=[UIFont monospacedDigitSystemFontOfSize:30 weight:UIFontWeightBold];
        _unit=[UILabel new];
        _unit.text=@"km/h"; _unit.textAlignment=NSTextAlignmentCenter;
        _unit.textColor=[UIColor colorWithWhite:0.9 alpha:1];
        _unit.font=[UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
        _limitRing=[UIView new];
        _limitRing.backgroundColor=UIColor.whiteColor;
        _limitRing.layer.borderColor=[UIColor colorWithRed:0.89 green:0.13 blue:0.13 alpha:1].CGColor;
        _limitRing.layer.borderWidth=4;
        _limitRing.layer.cornerRadius=25;
        _limit=[UILabel new];
        _limit.textAlignment=NSTextAlignmentCenter;
        _limit.textColor=UIColor.blackColor;
        _limit.font=[UIFont monospacedDigitSystemFontOfSize:21 weight:UIFontWeightBold];
        [self addSubview:_current]; [self addSubview:_unit];
        [self addSubview:_limitRing]; [_limitRing addSubview:_limit];
        // CarPlay HUD startup is independent of data availability. Never invent a number.
        _current.text=@"—"; _limit.text=@"—";
        self.hidden=NO;
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    const CGFloat w=self.bounds.size.width, h=self.bounds.size.height;
    // One compact GOFA-style panel: speed left, ONE speed-limit sign right.
    // No camera sign, secondary road sign or separate provider mini-bubble.
    _current.frame=CGRectMake(7,4,w-65,39);
    _unit.frame=CGRectMake(7,40,w-65,15);
    _limitRing.frame=CGRectMake(w-56,(h-50)/2,50,50);
    _limit.frame=_limitRing.bounds;
}
- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window && !_timer) {
        _timer=[NSTimer timerWithTimeInterval:1.0 target:self
                     selector:@selector(tick:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
        [self tick:_timer];
    } else if (!self.window) {
        [self stop];
    }
}
- (void)tick:(NSTimer *)timer {
    (void)timer;
    if (!self.window || self.dismissedForSession) {
        self.hidden=YES; return;
    }
    if (!self.ownerBridge || !self.ownerBridge.isVisible) {
        self.hidden=YES; return;
    }
    DFSpeedHUDRecord sample={};
    if (!DFSpeedHUDReadBest(&sample)) {
        // Visible diagnostic state: no data is not the same as no HUD.
        self.current.text=@"—";
        self.limit.text=@"—";
        self.limitRing.layer.borderColor=UIColor.lightGrayColor.CGColor;
        self.accessibilityLabel=@"DuoFace speed: awaiting a verified source";
        self.hidden=NO;
        return;
    }
    if (self.dismissedForSession) { self.hidden=YES; return; }
    self.hidden=NO;
    self.current.text=sample.hasCurrent
        ? [NSString stringWithFormat:@"%ld",(long)sample.currentKmh] : @"—";
    self.limit.text=sample.hasLimit
        ? [NSString stringWithFormat:@"%ld",(long)sample.limitKmh] : @"—";
    self.limitRing.layer.borderColor=(sample.hasLimit
        ? [UIColor colorWithRed:0.89 green:0.13 blue:0.13 alpha:1]
        : UIColor.lightGrayColor).CGColor;
    self.accessibilityLabel=[NSString stringWithFormat:
        @"DuoFace: speed %@ km/h; limit %@ km/h",
        self.current.text,self.limit.text];
}

static NSString *const kDFSpeedHUDPrefs=@"com.duoface.speedhud";
static NSString *const kDFSpeedPosX=@"positionX";
static NSString *const kDFSpeedPosY=@"positionY";
static CGRect DFAllowedArea(UIView *view) {
    UIView *parent=view.superview;
    if (!parent) return CGRectZero;
    CGRect area=UIEdgeInsetsInsetRect(parent.bounds,parent.safeAreaInsets);
    if (CGRectIsEmpty(area) || !isfinite(area.size.width) || !isfinite(area.size.height))
        area=parent.bounds;
    return CGRectInset(area,6,6);
}
static CGPoint DFClampCenter(CGPoint center,CGRect area,CGSize size) {
    const CGFloat hx=size.width*0.5, hy=size.height*0.5;
    CGFloat minX=CGRectGetMinX(area)+hx, maxX=CGRectGetMaxX(area)-hx;
    CGFloat minY=CGRectGetMinY(area)+hy, maxY=CGRectGetMaxY(area)-hy;
    if (maxX<minX) { minX=CGRectGetMidX(area); maxX=minX; }
    if (maxY<minY) { minY=CGRectGetMidY(area); maxY=minY; }
    return CGPointMake(fmax(minX,fmin(maxX,center.x)),
                       fmax(minY,fmin(maxY,center.y)));
}
- (void)restoreSavedPosition {
    CGRect area=DFAllowedArea(self);
    if (CGRectIsEmpty(area)) return;
    NSUserDefaults *prefs=[[NSUserDefaults alloc] initWithSuiteName:kDFSpeedHUDPrefs];
    if (![prefs objectForKey:kDFSpeedPosX] || ![prefs objectForKey:kDFSpeedPosY]) {
        // GOFA reference image: default upper-right, adjustable everywhere.
        self.center=DFClampCenter(CGPointMake(CGRectGetMaxX(area)-self.bounds.size.width/2,
                     CGRectGetMinY(area)+self.bounds.size.height/2),area,self.bounds.size);
        return;
    }
    double x=[prefs doubleForKey:kDFSpeedPosX], y=[prefs doubleForKey:kDFSpeedPosY];
    if (!isfinite(x) || !isfinite(y) || x<0 || x>1 || y<0 || y>1) return;
    self.center=DFClampCenter(CGPointMake(CGRectGetMinX(area)+area.size.width*x,
              CGRectGetMinY(area)+area.size.height*y),area,self.bounds.size);
}
- (void)savePosition {
    CGRect area=DFAllowedArea(self);
    if (CGRectIsEmpty(area) || area.size.width<=0 || area.size.height<=0) return;
    NSUserDefaults *prefs=[[NSUserDefaults alloc] initWithSuiteName:kDFSpeedHUDPrefs];
    [prefs setDouble:fmax(0,fmin(1,(self.center.x-CGRectGetMinX(area))/area.size.width))
             forKey:kDFSpeedPosX];
    [prefs setDouble:fmax(0,fmin(1,(self.center.y-CGRectGetMinY(area))/area.size.height))
             forKey:kDFSpeedPosY];
}
- (void)showDismissTarget {
    if (!self.superview || self.dismissTarget) return;
    UILabel *target=[[UILabel alloc] initWithFrame:CGRectMake(0,0,62,62)];
    target.backgroundColor=[UIColor colorWithWhite:0.09 alpha:0.92];
    target.layer.cornerRadius=31;
    target.layer.borderWidth=2;
    target.layer.borderColor=[UIColor colorWithRed:0.95 green:0.3 blue:0.3 alpha:1].CGColor;
    target.text=@"×";
    target.font=[UIFont systemFontOfSize:38 weight:UIFontWeightSemibold];
    target.textColor=UIColor.whiteColor;
    target.textAlignment=NSTextAlignmentCenter;
    target.userInteractionEnabled=NO; // Indicator only, not a competing HUD.
    CGRect area=DFAllowedArea(self);
    target.center=CGPointMake(CGRectGetMidX(area),
                       CGRectGetMaxY(area)-target.bounds.size.height/2);
    [self.superview addSubview:target];
    self.dismissTarget=target;
}
- (void)pan:(UIPanGestureRecognizer *)gesture {
    if (!self.superview || self.dismissedForSession) return;
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            [self showDismissTarget];
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint move=[gesture translationInView:self.superview];
            CGPoint next=CGPointMake(self.center.x+move.x,self.center.y+move.y);
            self.center=DFClampCenter(next,DFAllowedArea(self),self.bounds.size);
            [gesture setTranslation:CGPointZero inView:self.superview];
            break;
        }
        case UIGestureRecognizerStateEnded: {
            CGRect drop=self.dismissTarget ? CGRectInset(self.dismissTarget.frame,-18,-18):CGRectZero;
            BOOL hide= !CGRectIsEmpty(drop) && CGRectContainsPoint(drop,self.center);
            [self.dismissTarget removeFromSuperview]; self.dismissTarget=nil;
            if (hide) {
                // GOFA-like drag to X. Session-only: next CarPlay window
                // recreate resets it; no hidden-forever state without restore UI.
                self.dismissedForSession=YES;
                self.hidden=YES;
                [_timer invalidate]; _timer=nil;
            } else {
                [self savePosition];
            }
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            [self.dismissTarget removeFromSuperview]; self.dismissTarget=nil;
            break;
        default: break;
    }
}
- (void)stop {
    [_timer invalidate]; _timer=nil;
    [self.dismissTarget removeFromSuperview]; self.dismissTarget=nil;
    self.hidden=YES;
}

@end

static char kDFSpeedViewKey;
static __weak UIWindow *kDFOnlyWindow;
static __weak UIView *kDFOnlyHost;
static NSString *kDFLastHostStatus;
static void DFHostStatus(NSString *status) {
    if (![status isEqualToString:kDFLastHostStatus]) {
        kDFLastHostStatus=[status copy];
        NSLog(@"[DuoFaceSpeedHUD][split-owner] %@",status);
    }
}
static __weak DFSpeedNativeHUD *kDFOnlyHUD;
static __weak CBWindow *kDFOnlyBridge;
static IMP kDFOriginalShow=NULL, kDFOriginalResize=NULL, kDFOriginalDestroy=NULL;
static BOOL kDFSpeedBridgeInstalled=NO;
static BOOL DFValidBounds(CGRect rect) {
    return isfinite(rect.size.width) && isfinite(rect.size.height) &&
           rect.size.width>=220 && rect.size.height>=120;
}
// Exact Native12 exposes both CBWindow.contentView and rootViewController.
// Verify their REAL view/window relationship: no arbitrary CarPlay-wide windows.
static UIView *DFVerifiedSplitHost(CBWindow *bridge, UIWindow *root) {
    if (![root isKindOfClass:UIWindow.class] || root.hidden ||
        root.alpha<=0.01 || !DFValidBounds(root.bounds)) {
        DFHostStatus(@"WAIT: native CBWindow root hidden/small/unavailable");
        return nil;
    }
    UIView *content=bridge.contentView;
    UIView *controller=bridge.rootViewController.viewIfLoaded;
    if (![content isKindOfClass:UIView.class] || content.window!=root) {
        DFHostStatus(@"WAIT: CBWindow contentView is not in root UIWindow");
        return nil;
    }
    // Prefer root controller's view above BOTH split panes, not either app pane.
    UIView *host=nil;
    if ([controller isKindOfClass:UIView.class] && controller.window==root) {
        for (UIView *v=content;v;v=v.superview) {
            if (v==controller) {host=controller;break;}
        }
    }
    // If Native12 uses a direct root contentView, that is the guarded fallback.
    if (!host) host=content;
    if (!DFValidBounds(host.bounds) || host.hidden || host.alpha<=0.01) {
        DFHostStatus(@"WAIT: verified split host not laid out/visible yet");
        return nil;
    }
    return host;
}
static void DFPlaceSpeedView(CBWindow *bridge) {
    UIWindow *nativeWindow=bridge.rootWindow;
    UIView *host=DFVerifiedSplitHost(bridge,nativeWindow);
    if (!host) return;
    // Singleton is keyed to the split HOST, not to each app pane or Home scene.
    if (kDFOnlyHUD && kDFOnlyHost!=host) {
        [kDFOnlyHUD stop];
        [kDFOnlyHUD removeFromSuperview];
        if (kDFOnlyHost)
            objc_setAssociatedObject(kDFOnlyHost,&kDFSpeedViewKey,nil,
                                     OBJC_ASSOCIATION_ASSIGN);
        kDFOnlyHUD=nil;kDFOnlyWindow=nil;kDFOnlyHost=nil;kDFOnlyBridge=nil;
    }
    DFSpeedNativeHUD *hud=objc_getAssociatedObject(host,&kDFSpeedViewKey);
    BOOL isNew=(hud==nil);
    if (!hud) {
        hud=[[DFSpeedNativeHUD alloc] initWithFrame:CGRectZero];
        hud.ownerBridge=bridge;
        objc_setAssociatedObject(host,&kDFSpeedViewKey,hud,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [host addSubview:hud];
    }
    hud.ownerBridge=bridge;
    hud.bounds=CGRectMake(0,0,142,64);
    if (isNew) [hud restoreSavedPosition];
    [host bringSubviewToFront:hud];
    kDFOnlyBridge=bridge;kDFOnlyWindow=nativeWindow;kDFOnlyHost=host;kDFOnlyHUD=hud;
    [hud tick:nil];
    DFHostStatus(@"MOUNTED: one HUD in CBWindow split host (device visibility still requires visual test)");
}
static void DFAttachHUDToBridgeWindow(id bridge) {
    if (![NSThread isMainThread]) {
        __weak id weakOwner=bridge;
        dispatch_async(dispatch_get_main_queue(), ^{
            id owner=weakOwner;
            if (owner) DFAttachHUDToBridgeWindow(owner);
        });
        return;
    }
    Class cls=object_getClass(bridge);
    const char *image=cls ? class_getImageName(cls):NULL;
    if (!image || !strstr(image,"DuoFaceDashboard.dylib") ||
        ![bridge respondsToSelector:@selector(rootWindow)] ||
        ![bridge respondsToSelector:@selector(isVisible)] ||
        !((CBWindow *)bridge).isVisible) return;
    // Set the owner before the view is added; didMoveToWindow ticks immediately.
    kDFOnlyBridge=(CBWindow *)bridge;
    UIWindow *window=((CBWindow *)bridge).rootWindow;
    DFPlaceSpeedView((CBWindow *)bridge);
    if (kDFOnlyHUD && kDFOnlyWindow==window) {
        kDFOnlyHUD.ownerBridge=(CBWindow *)bridge;
        [kDFOnlyHUD tick:nil];
    }
}
static void DFRemoveHUDFromBridgeWindow(id bridge) {
    if (![NSThread isMainThread] || kDFOnlyBridge!=bridge) return;
    [kDFOnlyHUD stop];
    [kDFOnlyHUD removeFromSuperview];
    if (kDFOnlyHost)
        objc_setAssociatedObject(kDFOnlyHost,&kDFSpeedViewKey,nil,
                                 OBJC_ASSOCIATION_ASSIGN);
    kDFOnlyHUD=nil;kDFOnlyWindow=nil;kDFOnlyHost=nil;kDFOnlyBridge=nil;
    DFHostStatus(@"UNMOUNTED: split owner destroyed/inactive");
}
// Native12 CBBridgeManager.window is the missing direct path to its live
// CBWindow instance (audit: sharedInstanceIfExists + window). No global
// UIWindow scanning, no per-app injection and no simulated GOFA producer.
static id DFCurrentNativeOwner(void) {
    Class cls=NSClassFromString(@"CBBridgeManager");
    SEL shared=NSSelectorFromString(@"sharedInstanceIfExists");
    if (!cls || ![cls respondsToSelector:shared]) {
        DFHostStatus(@"WAIT: CBBridgeManager class unavailable in this process");
        return nil;
    }
    id manager=((id(*)(id,SEL))objc_msgSend)(cls,shared);
    SEL windowSel=NSSelectorFromString(@"window");
    if (!manager || ![manager respondsToSelector:windowSel]) {
        DFHostStatus(@"WAIT: CBBridgeManager singleton/window unavailable");
        return nil;
    }
    id owner=((id(*)(id,SEL))objc_msgSend)(manager,windowSel);
    Class windowClass=NSClassFromString(@"CBWindow");
    if (!windowClass || ![owner isKindOfClass:windowClass]) {
        DFHostStatus(@"WAIT: manager.window is not a native CBWindow");
        return nil;
    }
    return owner;
}
static void DFReconcileSplitHUD(void) {
    if (![NSThread isMainThread]) return;
    id owner=DFCurrentNativeOwner();
    if (owner) {
        if (!((CBWindow *)owner).isVisible) {
            if (kDFOnlyBridge) DFRemoveHUDFromBridgeWindow(kDFOnlyBridge);
            DFHostStatus(@"WAIT: manager CBWindow inactive");
            return;
        }
        DFAttachHUDToBridgeWindow(owner);
    } else if (kDFOnlyBridge && !kDFOnlyBridge.isVisible) {
        DFRemoveHUDFromBridgeWindow(kDFOnlyBridge);
    }
}
@interface DFHUDReconcileDriver : NSObject
- (void)refresh:(NSTimer *)timer;
- (void)windowBecameVisible:(NSNotification *)note;
@end
@implementation DFHUDReconcileDriver
- (void)refresh:(NSTimer *)timer {(void)timer;DFReconcileSplitHUD();}
- (void)windowBecameVisible:(NSNotification *)note {
    (void)note;DFReconcileSplitHUD();
}
@end
static DFHUDReconcileDriver *kDFHUDDriver;
static void DFStartSplitReconcile(void) {
    if (kDFHUDDriver) return;
    kDFHUDDriver=[DFHUDReconcileDriver new];
    NSTimer *timer=[NSTimer timerWithTimeInterval:1.0 target:kDFHUDDriver
                      selector:@selector(refresh:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    [[NSNotificationCenter defaultCenter] addObserver:kDFHUDDriver
        selector:@selector(windowBecameVisible:)
        name:UIWindowDidBecomeVisibleNotification object:nil];
    DFReconcileSplitHUD();
}
static void DFWrappedShow(id self,SEL cmd) {
    ((void(*)(id,SEL))kDFOriginalShow)(self,cmd);
    DFAttachHUDToBridgeWindow(self);
}
static void DFWrappedResize(id self,SEL cmd) {
    ((void(*)(id,SEL))kDFOriginalResize)(self,cmd);
    DFAttachHUDToBridgeWindow(self);
}
static void DFWrappedDestroy(id self,SEL cmd) {
    DFRemoveHUDFromBridgeWindow(self);
    ((void(*)(id,SEL))kDFOriginalDestroy)(self,cmd);
}
static void DFTryInstallBridge(unsigned attempts) {
    if (kDFSpeedBridgeInstalled || !NSThread.isMainThread) return;
    Class cls=NSClassFromString(@"CBWindow");
    const char *image=cls?class_getImageName(cls):NULL;
    if (cls && image && strstr(image,"DuoFaceDashboard.dylib")) {
        SEL sels[]={@selector(show),@selector(resizeWindows),@selector(destroyWindows)};
        IMP wrappers[]={(IMP)DFWrappedShow,(IMP)DFWrappedResize,(IMP)DFWrappedDestroy};
        Method methods[3]={NULL,NULL,NULL};
        IMP originals[3]={NULL,NULL,NULL};
        BOOL valid=YES;
        for (unsigned i=0;i<3;i++) {
            methods[i]=class_getInstanceMethod(cls,sels[i]);
            if (!methods[i] || strcmp(method_getTypeEncoding(methods[i]),"v16@0:8")!=0) {
                valid=NO;break;
            }
            originals[i]=method_getImplementation(methods[i]);
            if (!originals[i] || originals[i]==wrappers[i]) {valid=NO;break;}
        }
        if (valid) {
            // Prevalidate all three original IMPs BEFORE mutating any method:
            // never accidentally capture a wrapper as its own original.
            kDFOriginalShow=originals[0];
            kDFOriginalResize=originals[1];
            kDFOriginalDestroy=originals[2];
            for (unsigned i=0;i<3;i++)
                method_setImplementation(methods[i],wrappers[i]);
            kDFSpeedBridgeInstalled=YES;
            NSLog(@"[DuoFaceSpeedHUD] Native12 CBWindow hooks ready");
            DFReconcileSplitHUD(); // existing split owner, even if show fired earlier
            return;
        }
    }
    if (attempts>=30) {
        DFHostStatus(@"WARN: CBWindow hook timeout; manager reconciliation remains active");
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,2*NSEC_PER_SEC),
        dispatch_get_main_queue(), ^{ DFTryInstallBridge(attempts+1); });
}

__attribute__((constructor)) static void DFStartSpeedHUD(void) {
    @autoreleasepool {
        NSString *bundle=NSBundle.mainBundle.bundleIdentifier.lowercaseString;
        if ([bundle isEqualToString:@"com.apple.carplayapp"]) {
            // Hook the REAL DuoFaceDashboard CBWindow lifecycle only.
            // No global CPWindow/window-scanning code is installed.
            dispatch_async(dispatch_get_main_queue(), ^{ DFStartSplitReconcile(); DFTryInstallBridge(0); });
        }
    }
}
