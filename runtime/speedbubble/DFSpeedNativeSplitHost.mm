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

// Speed6: NEW renderer targeting only the verified Native12 dashboard split.
// Never create a second UIWindow or scan system CarPlay Home windows.
// The class definitions and HUD drawing above are reused byte-for-byte from Speed4.
#import <notify.h>
#import <CoreFoundation/CoreFoundation.h>
#import <stdio.h>
#import <unistd.h>

static __weak CBWindow *s6Owner=nil;
static __weak UIView *s6Host=nil;
static DFSpeedNativeHUD *s6HUD=nil;
static BOOL s6Installed=NO;
static BOOL s6LastMounted=NO;
static NSString *s6LastReason=nil;
static IMP s6OriginalShow=NULL, s6OriginalResize=NULL, s6OriginalDestroy=NULL, s6OriginalHide=NULL;
static IMP s6OriginalActivate=NULL, s6OriginalDeactivate=NULL;
static int s6GOFAForegroundToken=-1;

static void S6Log(NSString *message) {
    if ([s6LastReason isEqualToString:message]) return;
    s6LastReason=[message copy];
    NSDictionary *event=@{@"time":@([[NSDate date] timeIntervalSince1970]),
       @"pid":@(getpid()),@"process":NSProcessInfo.processInfo.processName ?: @"nil",
       @"stage":message ?: @"nil", @"mounted":@(s6LastMounted),
       @"owner":s6Owner?NSStringFromClass([s6Owner class]):@"nil",
       @"host":s6Host?NSStringFromClass([s6Host class]):@"nil"};
    NSData *json=[NSJSONSerialization dataWithJSONObject:event options:0 error:nil];
    FILE *fp=fopen("/var/mobile/Library/Logs/DuoFaceSpeed6-CarPlayApp.jsonl","a");
    if (!fp) {
        NSString *fallback=[NSTemporaryDirectory() stringByAppendingPathComponent:@"DuoFaceSpeed6-CarPlayApp.jsonl"];
        fp=fopen(fallback.fileSystemRepresentation,"a");
    }
    if (fp && json) {fwrite(json.bytes,1,json.length,fp);fputc('\n',fp);fclose(fp);}
    else if(fp) fclose(fp);
    NSLog(@"[DuoFaceSpeed6] %@",message);
}
static void S6Unmount(NSString *reason) {
    if (s6HUD) {
        [s6HUD stop];
        [s6HUD removeFromSuperview];
        s6HUD.ownerBridge=nil;
    }
    s6HUD=nil;
    s6Owner=nil;
    s6Host=nil;
    s6LastMounted=NO;
    S6Log(reason);
}
static BOOL S6IsGOFAActive(void) {
    if (s6GOFAForegroundToken<0) return NO;
    uint64_t active=0;
    return notify_get_state(s6GOFAForegroundToken,&active)==NOTIFY_STATUS_OK && active==1;
}
// A second CarPlay renderer must not coexist. If the original GOFAHUD global
// tweak is running, require its documented carEnabled preference to be OFF.
// We never mutate another tweak's preference or broadcast its "show" event.
static BOOL S6OriginalGOFARendererDisabled(void) {
    if (!NSClassFromString(@"GOFACarGlobalWindow")) return YES;
    CFStringRef domain=CFSTR("local.gofahud");
    CFPreferencesAppSynchronize(domain);
    CFTypeRef enabled=CFPreferencesCopyAppValue(CFSTR("carEnabled"),domain);
    CFTypeRef master=CFPreferencesCopyAppValue(CFSTR("bubbleEnabled"),domain);
    BOOL carOff=enabled && CFGetTypeID(enabled)==CFBooleanGetTypeID() && !CFBooleanGetValue((CFBooleanRef)enabled);
    BOOL masterOff=master && CFGetTypeID(master)==CFBooleanGetTypeID() && !CFBooleanGetValue((CFBooleanRef)master);
    if(enabled) CFRelease(enabled);
    if(master) CFRelease(master);
    return carOff || masterOff;
}
static BOOL S6OwnerClassesOK(void) {
    Class cls=NSClassFromString(@"CBWindow");
    Class dashboard=NSClassFromString(@"CBBridgeManagerDashboard");
    const char *wImage=cls?class_getImageName(cls):NULL;
    const char *dImage=dashboard?class_getImageName(dashboard):NULL;
    return cls && dashboard && wImage && dImage &&
           strstr(wImage,"DuoFaceDashboard.dylib") &&
           strstr(dImage,"DuoFaceDashboard.dylib");
}
static CBWindow *S6CurrentOwner(void) {
    Class cls=NSClassFromString(@"CBWindow");
    SEL selector=NSSelectorFromString(@"activeCarPlayWindow");
    if (!cls || ![cls respondsToSelector:selector]) return nil;
    // Verified from original Native12 Mach-O: +[CBWindow activeCarPlayWindow]
    // @16@0:8. Unlike Speed4, do NOT use the SpringBoard manager singleton.
    id window=((id(*)(id,SEL))objc_msgSend)(cls,selector);
    return [window isKindOfClass:cls] ? (CBWindow *)window : nil;
}
static BOOL S6DashboardActive(void) {
    Class dashboard=NSClassFromString(@"CBBridgeManagerDashboard");
    SEL shared=NSSelectorFromString(@"sharedInstance");
    SEL active=NSSelectorFromString(@"activated");
    if (!dashboard || ![dashboard respondsToSelector:shared]) return NO;
    id manager=((id(*)(id,SEL))objc_msgSend)(dashboard,shared);
    if (!manager || ![manager respondsToSelector:active]) return NO;
    return ((BOOL(*)(id,SEL))objc_msgSend)(manager,active);
}
static UIView *S6VerifiedHost(CBWindow *owner) {
    if (!owner || !owner.isVisible) return nil;
    UIWindow *root=owner.rootWindow;
    if (![root isKindOfClass:UIWindow.class] || root.hidden || root.alpha<0.01 ||
        !isfinite(root.bounds.size.width) || !isfinite(root.bounds.size.height) ||
        root.bounds.size.width<220 || root.bounds.size.height<120) return nil;
    NSString *role=root.windowScene.session.role ?: @"";
    BOOL external=root.screen && root.screen!=UIScreen.mainScreen;
    BOOL carRole=[role rangeOfString:@"CarPlay" options:NSCaseInsensitiveSearch].location!=NSNotFound;
    if (!external && !carRole) return nil;
    UIView *content=owner.contentView;
    UIView *controller=owner.rootViewController.viewIfLoaded;
    if (![content isKindOfClass:UIView.class] || content.window!=root ||
        content.hidden || content.alpha<0.01) return nil;
    // Attach to the root controller *inside the Native12 CBWindow* only,
    // above two panes. Never to an arbitrary CarPlayApp/Apple Home UIWindow.
    if (![controller isKindOfClass:UIView.class] || controller.window!=root ||
        controller.hidden || controller.alpha<0.01) return nil;
    BOOL descendant=NO;
    for (UIView *view=content;view;view=view.superview) {
        if (view==controller) {descendant=YES;break;}
    }
    if (!descendant || controller.bounds.size.width<220 || controller.bounds.size.height<120) return nil;
    return controller;
}
static void S6Reconcile(void) {
    if (!NSThread.isMainThread) return;
    if (!S6OwnerClassesOK()) {
        if(s6HUD) S6Unmount(@"UNMOUNTED: Native12 owner classes not in CarPlayApp");
        else S6Log(@"WAIT: Native12 dashboard/CBWindow classes unavailable");
        return;
    }
    if (!S6OriginalGOFARendererDisabled()) {
        if(s6HUD) S6Unmount(@"UNMOUNTED: original GOFAHUD CarPlay card is enabled");
        else S6Log(@"WAIT: turn OFF GOFA HUD > CarPlay > Hiển thị bong bóng to avoid 2 renderers");
        return;
    }
    if (S6IsGOFAActive()) {
        if(s6HUD) S6Unmount(@"UNMOUNTED: GOFA app is foreground");
        else S6Log(@"WAIT: GOFA foreground");
        return;
    }
    if (!S6DashboardActive()) {
        if(s6HUD) S6Unmount(@"UNMOUNTED: Native12 dashboard bridge deactivated");
        else S6Log(@"WAIT: CBBridgeManagerDashboard.activated=NO");
        return;
    }
    CBWindow *owner=S6CurrentOwner();
    UIView *host=S6VerifiedHost(owner);
    if (!host) {
        if(s6HUD) S6Unmount(@"UNMOUNTED: verified CBWindow split host unavailable");
        else S6Log(@"WAIT: no visible activeCarPlayWindow/content/controller host");
        return;
    }
    if (s6HUD && (s6Owner!=owner || s6Host!=host || s6HUD.superview!=host)) {
        S6Unmount(@"RECREATE: Native12 split host changed");
    }
    if (!s6HUD) {
        s6HUD=[[DFSpeedNativeHUD alloc] initWithFrame:CGRectMake(0,0,142,64)];
        s6HUD.ownerBridge=owner;
        [host addSubview:s6HUD];
        [s6HUD restoreSavedPosition];
    }
    s6Owner=owner;s6Host=host;
    s6HUD.ownerBridge=owner;
    [host bringSubviewToFront:s6HUD];
    // Saved position must stay inside new split geometry after zoom/resize.
    if (s6HUD.dismissTarget==nil && !s6HUD.dismissedForSession) {
        s6HUD.center=CGPointMake(fmax(s6HUD.bounds.size.width/2,
           fmin(host.bounds.size.width-s6HUD.bounds.size.width/2,s6HUD.center.x)),
           fmax(s6HUD.bounds.size.height/2,
           fmin(host.bounds.size.height-s6HUD.bounds.size.height/2,s6HUD.center.y)));
    }
    [s6HUD tick:nil];
    s6LastMounted=!s6HUD.hidden && s6HUD.window==owner.rootWindow;
    S6Log(s6LastMounted?@"MOUNTED: one HUD in Native12 split root view":@"WAIT: host attached but HUD hidden");
}
static void S6WrappedShow(id obj,SEL sel) {
    if(s6OriginalShow) ((void(*)(id,SEL))s6OriginalShow)(obj,sel);
    S6Reconcile();
}
static void S6WrappedResize(id obj,SEL sel) {
    if(s6OriginalResize) ((void(*)(id,SEL))s6OriginalResize)(obj,sel);
    S6Reconcile();
}
static void S6WrappedDestroy(id obj,SEL sel) {
    if(s6Owner==obj) S6Unmount(@"UNMOUNTED: CBWindow destroyed");
    if(s6OriginalDestroy) ((void(*)(id,SEL))s6OriginalDestroy)(obj,sel);
}
static void S6WrappedHide(id obj,SEL sel,id completion) {
    if(s6Owner==obj) S6Unmount(@"UNMOUNTED: CBWindow hidden");
    if(s6OriginalHide) ((void(*)(id,SEL,id))s6OriginalHide)(obj,sel,completion);
}
static void S6WrappedActivate(id obj,SEL sel,id bridge) {
    if(s6OriginalActivate) ((void(*)(id,SEL,id))s6OriginalActivate)(obj,sel,bridge);
    S6Reconcile();
}
static void S6WrappedDeactivate(id obj,SEL sel) {
    S6Unmount(@"UNMOUNTED: Dashboard bridgeDidDeactivate");
    if(s6OriginalDeactivate) ((void(*)(id,SEL))s6OriginalDeactivate)(obj,sel);
}
static void S6InstallHooks(int attempts) {
    if(s6Installed || !NSThread.isMainThread) return;
    Class window=NSClassFromString(@"CBWindow");
    Class dashboard=NSClassFromString(@"CBBridgeManagerDashboard");
    if(S6OwnerClassesOK()) {
        Class owners[]={window,window,window,window,dashboard,dashboard};
        SEL selectors[]={@selector(show),@selector(resizeWindows),@selector(destroyWindows),
                         @selector(hide:),@selector(bridgeDidActivate:),@selector(bridgeDidDeactivate)};
        const char *encoding[]={"v16@0:8","v16@0:8","v16@0:8","v24@0:8@?16",
                                 "v24@0:8@16","v16@0:8"};
        IMP replacements[]={(IMP)S6WrappedShow,(IMP)S6WrappedResize,
                            (IMP)S6WrappedDestroy,(IMP)S6WrappedHide,
                            (IMP)S6WrappedActivate,(IMP)S6WrappedDeactivate};
        IMP *originals[]={&s6OriginalShow,&s6OriginalResize,
                          &s6OriginalDestroy,&s6OriginalHide,
                          &s6OriginalActivate,&s6OriginalDeactivate};
        Method methods[6]={NULL,NULL,NULL,NULL,NULL,NULL};
        BOOL ok=YES;
        for(int i=0;i<6;i++) {
            methods[i]=class_getInstanceMethod(owners[i],selectors[i]);
            const char *type=methods[i]?method_getTypeEncoding(methods[i]):NULL;
            IMP current=methods[i]?method_getImplementation(methods[i]):NULL;
            if(!type || strcmp(type,encoding[i]) || !current || current==replacements[i]) {ok=NO;break;}
        }
        if(ok) {
            for(int i=0;i<6;i++) *originals[i]=method_getImplementation(methods[i]);
            for(int i=0;i<6;i++) method_setImplementation(methods[i],replacements[i]);
            s6Installed=YES;
            S6Log(@"HOOKED: CBWindow + CBBridgeManagerDashboard activation only");
            S6Reconcile();
            return;
        }
    }
    if(attempts==0) S6Log(@"WAIT: Native12 hooks not ready or ABI mismatch");
    if(attempts<30) dispatch_after(dispatch_time(DISPATCH_TIME_NOW,2*NSEC_PER_SEC),
           dispatch_get_main_queue(),^{S6InstallHooks(attempts+1);});
    else S6Log(@"WARN: Native12 host hooks unavailable after 60s");
}
@interface DFSpeed6Driver : NSObject
- (void)tick:(NSTimer *)timer;
- (void)visible:(NSNotification *)note;
@end
@implementation DFSpeed6Driver
- (void)tick:(NSTimer *)timer {(void)timer;S6Reconcile();}
- (void)visible:(NSNotification *)note {(void)note;S6Reconcile();}
@end
static DFSpeed6Driver *s6Driver;
__attribute__((constructor)) static void S6Start(void) {
    if(![NSBundle.mainBundle.bundleIdentifier.lowercaseString isEqualToString:@"com.apple.carplayapp"]) return;
    dispatch_async(dispatch_get_main_queue(),^{
        notify_register_check("local.gofahud.carplay.gofa-active",&s6GOFAForegroundToken);
        S6Log(@"LOADED: Speed6 CarPlayApp Native12 split-host module");
        s6Driver=[DFSpeed6Driver new];
        NSTimer *timer=[NSTimer timerWithTimeInterval:0.5 target:s6Driver
                                     selector:@selector(tick:) userInfo:nil repeats:YES];
        [NSRunLoop.mainRunLoop addTimer:timer forMode:NSRunLoopCommonModes];
        [[NSNotificationCenter defaultCenter] addObserver:s6Driver
                         selector:@selector(visible:) name:UIWindowDidBecomeVisibleNotification object:nil];
        S6InstallHooks(0);
        S6Reconcile();
    });
}
