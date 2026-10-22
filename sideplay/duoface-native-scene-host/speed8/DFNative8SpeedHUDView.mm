// DuoFace OWN source from historical Speed8 native commit:
 // 1286a3ef868cf7e29804bcddf7e20b2eae707ce1, visual renderer only.
 // No proprietary bridge or third-party compiled binaries are linked.
 // Not yet enabled/mounted in current integrated package.
// DuoFace Native12 candidate: ONE GOFA-inspired speed HUD for FOUR alternative app data sources.
// Speed8 candidate: compact, draggable on exact same verified split-only SpringBoard owner.
// Native12 CBWindow selectors and rootWindow class are verified by existing audits.
// Speed4 split-host candidate: device visibility is not yet verified.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "DFSpeedTransport.h"
#import "DFNative8SpeedHUDView.h"
#import <math.h>
#include <string.h>

// Actual DuoFace Native12 owner; not the Apple CarPlay home window.
// Legacy native Window owner removed; UIKit owner now explicitly supplied.

@interface DFNative8SpeedHUDView ()
@property(nonatomic,strong) UILabel *current;
@property(nonatomic,strong) UILabel *limit;
@property(nonatomic,strong) UILabel *unit;
@property(nonatomic,strong) UIView *limitRing;
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,strong) UILabel *dismissTarget;
@property(nonatomic,assign) BOOL dismissedForSession;
@property(nonatomic,strong) UIView *settingsPanel;
@property(nonatomic,assign) CGFloat visualScale;
@property(nonatomic,assign) CGFloat visualOpacity;
@property(nonatomic,assign) BOOL displayLimit;
@property(nonatomic,assign) NSInteger selectedSource;
- (void)pan:(UIPanGestureRecognizer *)recognizer;
- (void)restoreSavedPosition;
- (void)tick:(NSTimer *)timer;
- (void)stop;
- (void)loadSettings;
- (void)saveSettings;
- (void)refreshStyle;
- (void)showSettings:(UILongPressGestureRecognizer *)recognizer;
- (void)settingsAction:(UIButton *)button;
- (void)refreshSettingsLabels;
- (NSString *)sourceTitle;
- (void)savePosition;
@end

static CGRect DFAllowedArea(UIView *view);
static CGPoint DFClampCenter(CGPoint center,CGRect area,CGSize size);
@implementation DFNative8SpeedHUDView
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self=[super initWithFrame:frame])) {
        // GOFA: only the bubble grabs taps/drags; the rest of CarPlay keeps touches.
        self.userInteractionEnabled=YES;
        UIPanGestureRecognizer *move=[[UIPanGestureRecognizer alloc]
            initWithTarget:self action:@selector(pan:)];
        [self addGestureRecognizer:move];
        UILongPressGestureRecognizer *settings=[[UILongPressGestureRecognizer alloc]
            initWithTarget:self action:@selector(showSettings:)];
        settings.minimumPressDuration=0.6;
        [self addGestureRecognizer:settings];
        // GOFA reference: dark horizontal pill, bright speed text, traffic-sign limit.
        self.backgroundColor=[UIColor colorWithRed:0.12 green:0.16 blue:0.20 alpha:0.94];
        self.layer.cornerRadius=23;
        self.layer.masksToBounds=YES;
        _current=[UILabel new];
        _current.textAlignment=NSTextAlignmentCenter;
        _current.textColor=UIColor.whiteColor;
        _current.font=[UIFont monospacedDigitSystemFontOfSize:22 weight:UIFontWeightBold];
        _unit=[UILabel new];
        _unit.text=@"km/h"; _unit.textAlignment=NSTextAlignmentCenter;
        _unit.textColor=[UIColor colorWithWhite:0.9 alpha:1];
        _unit.font=[UIFont systemFontOfSize:9 weight:UIFontWeightMedium];
        _limitRing=[UIView new];
        _limitRing.backgroundColor=UIColor.whiteColor;
        _limitRing.layer.borderColor=[UIColor colorWithRed:0.89 green:0.13 blue:0.13 alpha:1].CGColor;
        _limitRing.layer.borderWidth=3;
        _limitRing.layer.cornerRadius=17;
        _limit=[UILabel new];
        _limit.textAlignment=NSTextAlignmentCenter;
        _limit.textColor=UIColor.blackColor;
        _limit.font=[UIFont monospacedDigitSystemFontOfSize:17 weight:UIFontWeightBold];
        [self addSubview:_current]; [self addSubview:_unit];
        [self addSubview:_limitRing]; [_limitRing addSubview:_limit];
        // CarPlay HUD startup is independent of data availability. Never invent a number.
        _current.text=@"—"; _limit.text=@"—";
        self.hidden=NO;
        [self loadSettings];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    const CGFloat w=self.bounds.size.width, h=self.bounds.size.height;
    // Speed8: proportional geometry, never use old 142x64 fixed subframes.
    const CGFloat sc=fmax(0.7,fmin(1.45,h/46.0));
    const CGFloat sign=34*sc;
    const CGFloat speedW=self.displayLimit?w-sign-10*sc:w-12*sc;
    _current.frame=CGRectMake(5*sc,1*sc,speedW,27*sc);
    _unit.frame=CGRectMake(5*sc,27*sc,speedW,15*sc);
    _limitRing.frame=CGRectMake(w-sign-4*sc,(h-sign)/2,sign,sign);
    _limitRing.layer.cornerRadius=sign/2;
    _limitRing.layer.borderWidth=2.5*sc;
    _limit.frame=_limitRing.bounds;
    _current.font=[UIFont monospacedDigitSystemFontOfSize:22*sc weight:UIFontWeightBold];
    _unit.font=[UIFont systemFontOfSize:9*sc weight:UIFontWeightMedium];
    _limit.font=[UIFont monospacedDigitSystemFontOfSize:17*sc weight:UIFontWeightBold];
    _limitRing.hidden=!self.displayLimit;
    self.layer.cornerRadius=h/2;
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
    if (!self.ownerWindow || self.ownerWindow.hidden ||
        !self.ownerWindow.screen || self.ownerWindow.screen==UIScreen.mainScreen) {
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
    // Native12 rootWindow owns the full external screen, NOT one app pane.
    CGRect area=parent.bounds;
    if(CGRectIsEmpty(area)||!isfinite(area.size.width)||!isfinite(area.size.height))
        return CGRectZero;
    return CGRectInset(area,3,3);
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
    if (!self.superview || self.dismissedForSession || self.settingsPanel) return;
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
    [self.settingsPanel removeFromSuperview]; self.settingsPanel=nil;
    self.hidden=YES;
}
- (void)loadSettings {
    NSUserDefaults *p=[[NSUserDefaults alloc] initWithSuiteName:@"com.duoface.speedhud"];
    self.visualScale=[p objectForKey:@"scale"] ? [p doubleForKey:@"scale"]:1.0;
    self.visualScale=fmax(0.8,fmin(1.35,self.visualScale));
    self.visualOpacity=[p objectForKey:@"opacity"] ? [p doubleForKey:@"opacity"]:0.93;
    self.visualOpacity=fmax(0.5,fmin(1.0,self.visualOpacity));
    self.displayLimit=[p objectForKey:@"showLimit"] ? [p boolForKey:@"showLimit"]:YES;
    self.selectedSource=[p integerForKey:@"source"];
    if(self.selectedSource!=0 && self.selectedSource!=2 &&
       self.selectedSource!=3 && self.selectedSource!=4)self.selectedSource=0;
    [self refreshStyle];
}
- (void)saveSettings {
    NSUserDefaults *p=[[NSUserDefaults alloc] initWithSuiteName:@"com.duoface.speedhud"];
    [p setDouble:self.visualScale forKey:@"scale"];
    [p setDouble:self.visualOpacity forKey:@"opacity"];
    [p setBool:self.displayLimit forKey:@"showLimit"];
    [p setInteger:self.selectedSource forKey:@"source"];
}
- (void)refreshStyle {
    const CGSize size=CGSizeMake(104*self.visualScale,46*self.visualScale);
    CGPoint prior=self.center;
    self.bounds=(CGRect){CGPointZero,size};
    self.center=prior;
    self.alpha=self.visualOpacity;
    [self setNeedsLayout];
    if(self.superview)self.center=DFClampCenter(self.center,DFAllowedArea(self),size);
}
- (NSString *)sourceTitle {
    switch(self.selectedSource){
        case 2:return @"Waze";
        case 3:return @"VietMap";
        case 4:return @"GOFA";
        default:return @"Auto";
    }
}
- (void)showSettings:(UILongPressGestureRecognizer *)recognizer {
    if(recognizer.state!=UIGestureRecognizerStateBegan || !self.superview)return;
    if(self.settingsPanel){[self.settingsPanel removeFromSuperview];self.settingsPanel=nil;return;}
    [self.dismissTarget removeFromSuperview];self.dismissTarget=nil;
    CGRect b=self.superview.bounds;
    const CGFloat w=fmin(320,MAX(220,b.size.width-12));
    UIView *panel=[[UIView alloc] initWithFrame:CGRectMake((b.size.width-w)/2,
                             (b.size.height-169)/2,w,169)];
    panel.backgroundColor=[UIColor colorWithWhite:0.08 alpha:0.97];
    panel.layer.cornerRadius=13;
    panel.layer.borderWidth=1;
    panel.layer.borderColor=[UIColor colorWithWhite:0.8 alpha:0.4].CGColor;
    UILabel *heading=[[UILabel alloc] initWithFrame:CGRectMake(12,5,w-24,28)];
    heading.text=@"DuoFace • Bong bóng tốc độ";
    heading.font=[UIFont boldSystemFontOfSize:14];
    heading.textAlignment=NSTextAlignmentCenter;
    heading.textColor=UIColor.whiteColor;
    [panel addSubview:heading];
    for(NSInteger i=1;i<=8;i++){
        UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];
        b.tag=i;
        const CGFloat pad=8, gap=5, bw=(w-2*pad-3*gap)/4;
        const NSInteger column=(i-1)%4,row=(i-1)/4;
        b.frame=CGRectMake(pad+(bw+gap)*column,38+row*57,bw,49);
        b.backgroundColor=[UIColor colorWithWhite:0.25 alpha:0.98];
        b.layer.cornerRadius=8;
        b.titleLabel.font=[UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        b.titleLabel.adjustsFontSizeToFitWidth=YES;
        b.titleLabel.minimumScaleFactor=0.7;
        [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [b addTarget:self action:@selector(settingsAction:) forControlEvents:UIControlEventTouchUpInside];
        [panel addSubview:b];
    }
    [self.superview addSubview:panel];
    self.settingsPanel=panel;
    [self refreshSettingsLabels];
}
- (void)refreshSettingsLabels {
    for(UIView *v in self.settingsPanel.subviews){
        if(![v isKindOfClass:UIButton.class])continue;
        UIButton *b=(UIButton *)v;
        NSString *label=@"";
        switch(b.tag){
            case 1:label=@"Cỡ −";break;
            case 2:label=@"Cỡ +";break;
            case 3:label=@"Mờ −";break;
            case 4:label=@"Mờ +";break;
            case 5:label=self.displayLimit?@"Biển: Có":@"Biển: Không";break;
            case 6:label=[NSString stringWithFormat:@"Nguồn: %@",[self sourceTitle]];break;
            case 7:label=@"Đặt lại";break;
            case 8:label=@"Đóng";break;
            default:break;
        }
        [b setTitle:label forState:UIControlStateNormal];
    }
}
- (void)settingsAction:(UIButton *)button {
    switch(button.tag){
        case 1:self.visualScale=fmax(0.8,self.visualScale-0.1);break;
        case 2:self.visualScale=fmin(1.35,self.visualScale+0.1);break;
        case 3:self.visualOpacity=fmax(0.5,self.visualOpacity-0.1);break;
        case 4:self.visualOpacity=fmin(1.0,self.visualOpacity+0.1);break;
        case 5:self.displayLimit=!self.displayLimit;break;
        case 6:self.selectedSource=self.selectedSource==0?2:
             self.selectedSource==2?3:self.selectedSource==3?4:0;break;
        case 7:{
            NSUserDefaults *p=[[NSUserDefaults alloc] initWithSuiteName:@"com.duoface.speedhud"];
            [p removeObjectForKey:@"positionX"];
            [p removeObjectForKey:@"positionY"];
            [self restoreSavedPosition];
            break;
        }
        case 8:[self.settingsPanel removeFromSuperview];self.settingsPanel=nil;return;
        default:return;
    }
    [self saveSettings];
    [self refreshStyle];
    [self refreshSettingsLabels];
}

@end
