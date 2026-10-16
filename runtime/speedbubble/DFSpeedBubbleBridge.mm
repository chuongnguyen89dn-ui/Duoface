// DuoFace native12 candidate: SPEED HUD OWNED BY DUOFACE, not external tweak.
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
- (void)tick:(NSTimer *)timer;
- (void)stop;
@end

@implementation DFSpeedNativeHUD
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self=[super initWithFrame:frame])) {
        self.userInteractionEnabled=NO; // Never intercept CarPlay/menu taps.
        self.backgroundColor=[UIColor colorWithWhite:0.08 alpha:0.90];
        self.layer.cornerRadius=13;
        self.layer.masksToBounds=YES;
        _current=[UILabel new];
        _current.textAlignment=NSTextAlignmentCenter;
        _current.textColor=UIColor.whiteColor;
        _current.font=[UIFont monospacedDigitSystemFontOfSize:29 weight:UIFontWeightBold];
        _unit=[UILabel new];
        _unit.text=@"km/h"; _unit.textAlignment=NSTextAlignmentCenter;
        _unit.textColor=[UIColor colorWithWhite:0.9 alpha:1];
        _unit.font=[UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
        _limitRing=[UIView new];
        _limitRing.backgroundColor=UIColor.whiteColor;
        _limitRing.layer.borderColor=[UIColor colorWithRed:0.89 green:0.13 blue:0.13 alpha:1].CGColor;
        _limitRing.layer.borderWidth=4;
        _limitRing.layer.cornerRadius=26;
        _limit=[UILabel new];
        _limit.textAlignment=NSTextAlignmentCenter;
        _limit.textColor=UIColor.blackColor;
        _limit.font=[UIFont monospacedDigitSystemFontOfSize:19 weight:UIFontWeightBold];
        [self addSubview:_current]; [self addSubview:_unit];
        [self addSubview:_limitRing]; [_limitRing addSubview:_limit];
        self.hidden=YES; // No made-up speed / limit before a live sample.
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    const CGFloat w=self.bounds.size.width, h=self.bounds.size.height;
    _current.frame=CGRectMake(7,5,w-73,39);
    _unit.frame=CGRectMake(7,43,w-73,19);
    _limitRing.frame=CGRectMake(w-59,(h-52)/2,52,52);
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
    if (!self.window) { self.hidden=YES; return; }
    DFSpeedHUDRecord sample={};
    if (!DFSpeedHUDReadBest(&sample)) {
        self.hidden=YES; // stale/unknown; do not keep last known speed.
        return;
    }
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
- (void)stop { [_timer invalidate]; _timer=nil; self.hidden=YES; }
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
    const CGFloat width=136, height=68, margin=10;
    CGRect bounds=DFValidBounds(safe)?safe:nativeWindow.bounds;
    hud.frame=CGRectMake(CGRectGetMaxX(bounds)-width-margin,
                         CGRectGetMinY(bounds)+margin,width,height);
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
