// DuoFace Native12 candidate: ONE GOFA-inspired speed HUD for FOUR alternative app data sources.
// Inject this module into SpringBoard *as part of future DuoFace package*.
// Native12 CBWindow selectors and rootWindow class are verified by existing audits.
// NO build, installation or Sileo changes in this source-only checkpoint.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "DFSpeedTransport.h"
#import <math.h>

@interface DFSpeedNativeHUD : UIView
@property(nonatomic,strong) UILabel *current;
@property(nonatomic,strong) UILabel *limit;
@property(nonatomic,strong) UILabel *unit;
@property(nonatomic,strong) UIView *limitRing;
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,strong) UILabel *dismissTarget;
@property(nonatomic,assign) BOOL dismissedForSession;
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
        self.hidden=YES; // No made-up speed / limit before a live sample.
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
    DFSpeedHUDRecord sample={};
    if (!DFSpeedHUDReadBest(&sample)) {
        self.hidden=YES; // stale/unknown; do not keep last known speed.
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

@interface CBWindow : NSObject
@property(nonatomic,readonly) UIWindow *rootWindow;
@end

static char kDFSpeedViewKey;
static IMP kDFOriginalShow=NULL, kDFOriginalResize=NULL, kDFOriginalDestroy=NULL;
static BOOL kDFSpeedBridgeInstalled=NO;
static BOOL DFValidBounds(CGRect rect) {
    return isfinite(rect.size.width) && isfinite(rect.size.height) &&
           rect.size.width>=220 && rect.size.height>=120;
}
static void DFPlaceSpeedView(UIWindow *nativeWindow) {
    if (![nativeWindow isKindOfClass:UIWindow.class] ||
        nativeWindow.hidden || !DFValidBounds(nativeWindow.bounds)) return;
    DFSpeedNativeHUD *hud=objc_getAssociatedObject(nativeWindow,&kDFSpeedViewKey);
    if (!hud) {
        hud=[[DFSpeedNativeHUD alloc] initWithFrame:CGRectZero];
        objc_setAssociatedObject(nativeWindow,&kDFSpeedViewKey,hud,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [nativeWindow addSubview:hud];
    }
    const CGRect safe=UIEdgeInsetsInsetRect(nativeWindow.bounds,
                               nativeWindow.safeAreaInsets);
    // Noninteractive overlay; never touch the original split scene frame.
    const CGFloat width=142, height=64;
    (void)safe;
    hud.bounds=CGRectMake(0,0,width,height);
    [hud restoreSavedPosition];
    [nativeWindow bringSubviewToFront:hud];
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
    if (![bridge respondsToSelector:@selector(rootWindow)]) return;
    UIWindow *window=((CBWindow *)bridge).rootWindow;
    DFPlaceSpeedView(window);
}
static void DFRemoveHUDFromBridgeWindow(id bridge) {
    if (![NSThread isMainThread]) return;
    if (![bridge respondsToSelector:@selector(rootWindow)]) return;
    UIWindow *root=((CBWindow *)bridge).rootWindow;
    DFSpeedNativeHUD *hud=objc_getAssociatedObject(root,&kDFSpeedViewKey);
    [hud stop]; [hud removeFromSuperview];
    objc_setAssociatedObject(root,&kDFSpeedViewKey,nil,
                             OBJC_ASSOCIATION_ASSIGN);
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
static BOOL DFInstallOne(Class cls, const char *name, IMP replacement,IMP *old) {
    SEL sel=sel_registerName(name);
    Method method=class_getInstanceMethod(cls,sel);
    if (!method || strcmp(method_getTypeEncoding(method),"v16@0:8")!=0)
        return NO; // ABI guarded; fail closed on new DuoFace/native versions.
    *old=method_setImplementation(method,replacement);
    return *old!=NULL;
}
static void DFTryInstallBridge(unsigned attempts) {
    if (kDFSpeedBridgeInstalled) return;
    if (!NSThread.isMainThread) return;
    Class cls=NSClassFromString(@"CBWindow");
    if (cls && class_getInstanceMethod(cls,@selector(show)) &&
        class_getInstanceMethod(cls,@selector(resizeWindows)) &&
        class_getInstanceMethod(cls,@selector(destroyWindows)) &&
        class_getInstanceMethod(cls,@selector(rootWindow))) {
        // A failed partial install must not leave half-wired handlers.
        Method m1=class_getInstanceMethod(cls,@selector(show));
        Method m2=class_getInstanceMethod(cls,@selector(resizeWindows));
        Method m3=class_getInstanceMethod(cls,@selector(destroyWindows));
        if (strcmp(method_getTypeEncoding(m1),"v16@0:8")==0 &&
            strcmp(method_getTypeEncoding(m2),"v16@0:8")==0 &&
            strcmp(method_getTypeEncoding(m3),"v16@0:8")==0) {
            if (DFInstallOne(cls,"show",(IMP)DFWrappedShow,&kDFOriginalShow) &&
                DFInstallOne(cls,"resizeWindows",(IMP)DFWrappedResize,&kDFOriginalResize) &&
                DFInstallOne(cls,"destroyWindows",(IMP)DFWrappedDestroy,&kDFOriginalDestroy)) {
                kDFSpeedBridgeInstalled=YES;
                NSLog(@"[DuoFaceSpeedHUD] Native12 window bridge installed (source-only candidate)");
                return;
            }
        }
    }
    if (attempts>=30) return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,2*NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{ DFTryInstallBridge(attempts+1); });
}
__attribute__((constructor)) static void DFStartSpeedHUD(void) {
    @autoreleasepool {
        if (![NSBundle.mainBundle.bundleIdentifier.lowercaseString
               isEqualToString:@"com.apple.springboard"]) return;
        dispatch_async(dispatch_get_main_queue(), ^{ DFTryInstallBridge(0); });
    }
}
