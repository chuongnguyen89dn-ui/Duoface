// DuoFace Native12 candidate: ONE GOFA-inspired speed HUD for FOUR alternative app data sources.
// Speed7: same visual HUD implementation, now hosted in native SpringBoard split view.
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


// Speed7: Native12 SpringBoard in-place split host, no UIWindow created.
// Unlike Speed5 (global transparent UIWindow) or Speed6 (wrong CarPlay process),
// this only inserts ONE UIView into the verified CBWindow.rootViewController.view.
// Fail closed unless currentApp is a native CBBridgedSplitApp with TWO live,
// attached appViews on the same real external root UIWindow.
#import <CoreFoundation/CoreFoundation.h>
#import <notify.h>
#import <stdio.h>
#import <unistd.h>

static __weak CBWindow *s7Owner=nil;
static __weak UIView *s7Host=nil;
static DFSpeedNativeHUD *s7HUD=nil;
static NSString *s7LastReason=nil;
static NSTimeInterval s7LastLog=0;
static BOOL s7WasMounted=NO;
static int s7GofaActive=-1;

static id S7Read(id object,SEL selector) {
    if (!object || ![object respondsToSelector:selector]) return nil;
    return ((id(*)(id,SEL))objc_msgSend)(object,selector);
}
static void S7Log(NSString *reason,NSDictionary *details) {
    NSTimeInterval now=NSDate.date.timeIntervalSince1970;
    if ([s7LastReason isEqualToString:reason] && now-s7LastLog<15) return;
    s7LastReason=[reason copy];s7LastLog=now;
    NSMutableDictionary *line=[@{@"time":@(now),@"pid":@(getpid()),
        @"stage":reason ?: @"nil", @"mounted":@(s7WasMounted),
        @"process":NSProcessInfo.processInfo.processName ?: @"nil"} mutableCopy];
    if(details) line[@"gate"]=details;
    NSData *data=[NSJSONSerialization dataWithJSONObject:line options:0 error:nil];
    if(!data)return;
    [[NSFileManager defaultManager]
      createDirectoryAtPath:@"/var/mobile/Library/Logs"
      withIntermediateDirectories:YES attributes:nil error:nil];
    FILE *fp=fopen("/var/mobile/Library/Logs/DuoFaceSpeedSplit7-SpringBoard.jsonl","a");
    if(!fp)fp=fopen([[NSTemporaryDirectory() stringByAppendingPathComponent:
             @"DuoFaceSpeedSplit7-SpringBoard.jsonl"] fileSystemRepresentation],"a");
    if(fp){fwrite(data.bytes,1,data.length,fp);fputc('\n',fp);fclose(fp);}
    NSLog(@"[DuoFaceSpeedSplit7] %@",reason);
}
static void S7Unmount(NSString *reason) {
    if(s7HUD){
        [s7HUD stop];
        [s7HUD removeFromSuperview];
        s7HUD.ownerBridge=nil;
    }
    s7HUD=nil;s7Owner=nil;s7Host=nil;s7WasMounted=NO;
    S7Log(reason,nil);
}
static BOOL S7OriginalGOFADisabled(void) {
    BOOL present=[[NSFileManager defaultManager] fileExistsAtPath:
       @"/var/jb/Library/MobileSubstrate/DynamicLibraries/GofaCarplayGlobal.dylib"];
    if(!present) return YES;
    CFStringRef domain=CFSTR("local.gofahud");
    CFPreferencesAppSynchronize(domain);
    CFTypeRef car=CFPreferencesCopyAppValue(CFSTR("carEnabled"),domain);
    CFTypeRef master=CFPreferencesCopyAppValue(CFSTR("bubbleEnabled"),domain);
    BOOL carOff=car && CFGetTypeID(car)==CFBooleanGetTypeID() &&
         !CFBooleanGetValue((CFBooleanRef)car);
    BOOL allOff=master && CFGetTypeID(master)==CFBooleanGetTypeID() &&
         !CFBooleanGetValue((CFBooleanRef)master);
    if(car)CFRelease(car);
    if(master)CFRelease(master);
    return carOff || allOff;
}
static BOOL S7GOFAForeground(void) {
    if(s7GofaActive<0)return NO;
    uint64_t active=0;
    return notify_get_state(s7GofaActive,&active)==NOTIFY_STATUS_OK && active==1;
}
static BOOL S7DuoFaceClasses(Class *managerOut,Class *windowOut,Class *splitOut) {
    Class m=NSClassFromString(@"CBBridgeManager");
    Class w=NSClassFromString(@"CBWindow");
    Class s=NSClassFromString(@"CBBridgedSplitApp");
    const char *mi=m?class_getImageName(m):NULL;
    const char *wi=w?class_getImageName(w):NULL;
    const char *si=s?class_getImageName(s):NULL;
    BOOL ok=m&&w&&s&&mi&&wi&&si&&
       strstr(mi,"DuoFaceDashboard.dylib") &&
       strstr(wi,"DuoFaceDashboard.dylib") &&
       strstr(si,"DuoFaceDashboard.dylib");
    if(managerOut)*managerOut=m;
    if(windowOut)*windowOut=w;
    if(splitOut)*splitOut=s;
    return ok;
}
static BOOL S7Ancestor(UIView *child, UIView *parent) {
    if(!child||!parent)return NO;
    for(UIView *p=child;p;p=p.superview)
        if(p==parent)return YES;
    return NO;
}
static UIView *S7AppView(id item) {
    if([item isKindOfClass:UIView.class])return item;
    id v=S7Read(item,@selector(view));
    return [v isKindOfClass:UIView.class] ? (UIView *)v:nil;
}
static void S7Reconcile(void) {
    if(!NSThread.isMainThread)return;
    Class m=nil,w=nil,s=nil;
    NSString *reason=@"SPLIT7_WAIT_UNKNOWN";
    NSMutableDictionary *metrics=[NSMutableDictionary new];
    do {
        if(!S7DuoFaceClasses(&m,&w,&s)){
            reason=@"SPLIT7_WAIT_NATIVE12_CLASSES";break;
        }
        id manager=S7Read(m,@selector(sharedInstanceIfExists));
        if(!manager || ![manager isKindOfClass:m]){
            reason=@"SPLIT7_WAIT_MANAGER";break;
        }
        id owner=S7Read(manager,@selector(window));
        if(![owner isKindOfClass:w]){
            reason=@"SPLIT7_WAIT_CBWINDOW";break;
        }
        CBWindow *bridge=(CBWindow *)owner;
        id current=S7Read(manager,@selector(currentApp));
        metrics[@"current_app_class"]=current?NSStringFromClass([current class]):@"nil";
        if(!current||![current isKindOfClass:s]){
            reason=@"SPLIT7_WAIT_NOT_NATIVE_SPLIT_APP";break;
        }
        NSArray *apps=S7Read(current,@selector(appViews));
        NSUInteger count=[apps isKindOfClass:NSArray.class]?apps.count:0;
        metrics[@"split_app_views"]=@(count);
        // CarPlay Home/single app cannot satisfy two attached Native12 panes.
        if(count<2 || count>4){
            reason=@"SPLIT7_WAIT_NOT_TWO_NATIVE_PANES";break;
        }
        if(!bridge.isVisible){
            reason=@"SPLIT7_WAIT_BRIDGE_NOT_VISIBLE";break;
        }
        UIWindow *root=bridge.rootWindow;
        UIView *controller=bridge.rootViewController.viewIfLoaded;
        UIView *content=bridge.contentView;
        if(![root isKindOfClass:UIWindow.class] || root.hidden || root.alpha<0.01 ||
           !root.screen || root.screen==UIScreen.mainScreen ||
           !isfinite(root.bounds.size.width) || !isfinite(root.bounds.size.height) ||
           root.bounds.size.width<220 || root.bounds.size.height<120){
            reason=@"SPLIT7_WAIT_NATIVE_EXTERNAL_ROOT";break;
        }
        // Actual iOS16 owner scene role is "_UIScreenBasedSceneSession", not "CarPlay".
        if(![NSStringFromClass([root class])
            isEqualToString:@"CBTouchPassThroughRootSceneWindow"]){
            reason=@"SPLIT7_WAIT_NOT_DUOFACE_ROOT_CLASS";break;
        }
        if(![controller isKindOfClass:UIView.class] || controller.window!=root ||
           ![content isKindOfClass:UIView.class] || content.window!=root ||
           !S7Ancestor(content,controller) || controller.hidden || content.hidden ||
           controller.alpha<0.01 || content.alpha<0.01){
            reason=@"SPLIT7_WAIT_NATIVE_VIEW_CHAIN";break;
        }
        UIView *splitRoot=S7AppView(current);
        if(!splitRoot || splitRoot.window!=root || !S7Ancestor(splitRoot,controller)
           || splitRoot.hidden || splitRoot.alpha<0.01){
            reason=@"SPLIT7_WAIT_SPLIT_APP_VIEW_NOT_IN_ROOT";break;
        }
        NSUInteger attached=0;
        for(id item in apps){
            UIView *pane=S7AppView(item);
            if(pane && pane.window==root && S7Ancestor(pane,splitRoot) &&
               !pane.hidden && pane.alpha>=0.01 && pane.bounds.size.width>=60 &&
               pane.bounds.size.height>=60)attached++;
        }
        metrics[@"attached_visible_panels"]=@(attached);
        if(attached<2){
            reason=@"SPLIT7_WAIT_PANES_NOT_ATTACHED";break;
        }
        if(!S7OriginalGOFADisabled()){
            reason=@"SPLIT7_WAIT_GOFAHUD_ORIGINAL_CARPLAY_ENABLED";break;
        }
        if(S7GOFAForeground()){
            reason=@"SPLIT7_WAIT_GOFA_ACTIVE";break;
        }
        if(s7HUD && (s7Owner!=bridge || s7Host!=controller || s7HUD.superview!=controller))
            S7Unmount(@"SPLIT7_RECREATE_NATIVE_SPLIT_OWNER_CHANGED");
        if(!s7HUD){
            s7HUD=[[DFSpeedNativeHUD alloc] initWithFrame:CGRectMake(0,0,142,64)];
            s7HUD.ownerBridge=bridge;
            [controller addSubview:s7HUD];
            [s7HUD restoreSavedPosition];
        }
        s7Owner=bridge;s7Host=controller;
        s7HUD.ownerBridge=bridge;
        [controller bringSubviewToFront:s7HUD];
        // Limit top-right placement to the live native split content geometry.
        s7HUD.center=CGPointMake(fmax(71,fmin(controller.bounds.size.width-71,s7HUD.center.x)),
                                  fmax(32,fmin(controller.bounds.size.height-32,s7HUD.center.y)));
        [s7HUD tick:nil];
        s7WasMounted=s7HUD.superview==controller && s7HUD.window==root && !s7HUD.hidden;
        reason=s7WasMounted?@"SPLIT7_MOUNTED_ONE_NATIVE_HOST":
                  @"SPLIT7_WAIT_HUD_ATTACHED_BUT_HIDDEN";
        break;
    }while(NO);
    if(![reason isEqualToString:@"SPLIT7_MOUNTED_ONE_NATIVE_HOST"] && s7HUD)
        S7Unmount(reason);
    // While not mounted, logs carry granular gate reasons & pane counts;
    // preserve changes and heartbeat, no pointer, URL, GPS, bundle IDs.
    S7Log(reason,metrics);
}
@interface DFSpeedSplit7Driver:NSObject
-(void)tick:(NSTimer *)timer;
@end
@implementation DFSpeedSplit7Driver
-(void)tick:(NSTimer *)timer {(void)timer;S7Reconcile();}
@end
static DFSpeedSplit7Driver *s7Driver=nil;
__attribute__((constructor)) static void S7Start(void) {
    if(![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"])return;
    dispatch_async(dispatch_get_main_queue(), ^{
        notify_register_check("local.gofahud.carplay.gofa-active",&s7GofaActive);
        S7Log(@"SPLIT7_LOADED_SPRINGBOARD",nil);
        s7Driver=[DFSpeedSplit7Driver new];
        NSTimer *timer=[NSTimer timerWithTimeInterval:0.5 target:s7Driver
                        selector:@selector(tick:) userInfo:nil repeats:YES];
        [NSRunLoop.mainRunLoop addTimer:timer forMode:NSRunLoopCommonModes];
        S7Reconcile();
    });
}
