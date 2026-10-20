// DuoFace independent native CarPlay scene CAContext reader. Requires a
// real UIKit-issued CarPlay scene and both existing opt-in switches; never
// creates external windows, changes native Dock, or injects app touches.
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <notify.h>
#import <math.h>
#import "../mytweak-independent-v1a/prototype/MTCPBridgeContract.h"

@interface DFNativeHostSurfaceView : UIView
- (void)start;
- (void)stop;
@end
@interface DFNativeHostSurfaceView ()
@property(nonatomic,strong) NSTimer *lease;
@property(nonatomic,strong) CALayer *remote;
@property(nonatomic,copy) NSString *session;
@property(nonatomic) uint32_t contextID;
@property(nonatomic,weak) UITouch *activeTouch;
@property(nonatomic) unsigned long long commandSequence;
@property(nonatomic) NSTimeInterval lastMoveAt;
@end
@implementation DFNativeHostSurfaceView
- (instancetype)initWithFrame:(CGRect)frame {
    if((self=[super initWithFrame:frame])) {
        self.opaque=NO;
        self.backgroundColor=UIColor.clearColor;
        self.userInteractionEnabled=YES; // Sends session-bound intent only, never synthesizes UIKit app touches.
        self.layer.masksToBounds=YES;
    }
    return self;
}
- (BOOL)hasSystemOwnedCarPlayWindow {
    UIWindow *w=self.window;
    if(!w || !w.windowScene || !w.screen || w.screen==UIScreen.mainScreen)
        return NO;
    if(![w.windowScene.session.role isEqualToString:@"UIWindowSceneSessionRoleCarPlay"])
        return NO;
    return [NSStringFromClass(w.rootViewController.class)
            isEqualToString:@"DFNativeHostRootController"] &&
           w.rootViewController.view==self.superview;
}
- (void)disconnectSurface {
    if(self.remote) {
        [self.remote removeFromSuperlayer];
        self.remote=nil;
        NSLog(@"[DuoFaceNativeHost] native-content-lease-ended");
    }
    self.session=nil;self.contextID=0;
    self.activeTouch=nil;self.commandSequence=0;
    self.lastMoveAt=0;
}
- (void)refresh:(NSTimer *)timer {
    (void)timer;
    if(!NSThread.isMainThread || ![self hasSystemOwnedCarPlayWindow] ||
       !MTCPBridgeExplicitOptIn() || CGRectIsEmpty(self.bounds)) {
        [self disconnectSurface];return;
    }
    NSDictionary *surface=MTCPBridgeReadSurface(nil);
    NSString *session=surface[@"Session"];
    NSNumber *number=surface[@"ContextID"];
    if(![session isKindOfClass:NSString.class] ||
       ![number isKindOfClass:NSNumber.class] ||
       number.unsignedLongLongValue==0 ||
       number.unsignedLongLongValue>UINT32_MAX) {
        [self disconnectSurface];return;
    }
    uint32_t cid=number.unsignedIntValue;
    if(!self.remote || ![self.session isEqualToString:session] || self.contextID!=cid) {
        [self disconnectSurface];
        Class klass=NSClassFromString(@"CALayerHost");
        SEL setter=NSSelectorFromString(@"setContextId:");
        if(!klass || ![klass instancesRespondToSelector:setter])return;
        @try {
            CALayer *layer=[klass layer];
            if(!layer || ![layer respondsToSelector:setter])return;
            ((void(*)(id,SEL,uint32_t))objc_msgSend)(layer,setter,cid);
            layer.masksToBounds=YES;
            [self.layer addSublayer:layer];
            self.remote=layer;
            self.session=[session copy];
            self.contextID=cid;
            self.commandSequence=0;self.lastMoveAt=0;
            NSLog(@"[DuoFaceNativeHost] native-content-context-attached (not CarPlay app admission)");
        } @catch(NSException *e) {
            NSLog(@"[DuoFaceNativeHost] native-content-context-failed %@",e.name);
            [self disconnectSurface];
        }
    }
    self.remote.frame=self.bounds;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.remote.frame=self.bounds;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    // Do not swallow native CarPlay input if there is no active, consented
    // visual source. The native status bar/Dock remain owned by iOS.
    if(!self.remote || !self.session || ![self hasSystemOwnedCarPlayWindow] ||
       !MTCPBridgeExplicitOptIn())return NO;
    return [super pointInside:point withEvent:event];
}
- (void)relayTouch:(UITouch *)touch phase:(NSString *)phase {
    if(!touch || !self.remote || !self.session ||
       ![self hasSystemOwnedCarPlayWindow] || !MTCPBridgeExplicitOptIn() ||
       !MTCPBridgeReadSurface(self.session) || CGRectIsEmpty(self.bounds))return;
    NSTimeInterval now=NSDate.date.timeIntervalSince1970;
    if([phase isEqualToString:@"move"] && now-self.lastMoveAt<1.0/60.0)return;
    if([phase isEqualToString:@"move"])self.lastMoveAt=now;
    CGPoint pt=[touch locationInView:self];
    double x=pt.x/CGRectGetWidth(self.bounds);
    double y=pt.y/CGRectGetHeight(self.bounds);
    if(!isfinite(x) || !isfinite(y))return;
    CGPoint normalized=CGPointMake(fmax(0.0,fmin(1.0,x)),fmax(0.0,fmin(1.0,y)));
    // SpringBoard's current DFCPNativeBridgeQA.deliverPacket: explicitly
    // accepts only its own menu UIButtons, NEVER arbitrary app touch replay.
    if(MTCPBridgeWriteCommand(self.session,@"pointer",++self.commandSequence,phase,normalized))
        notify_post("com.duoface.mytweak.cp-command");
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    (void)event;
    if(self.activeTouch || touches.count!=1)return;
    self.activeTouch=touches.anyObject;
    [self relayTouch:self.activeTouch phase:@"begin"];
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    (void)event;
    if(self.activeTouch && [touches containsObject:self.activeTouch])
        [self relayTouch:self.activeTouch phase:@"move"];
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    (void)event;
    if(self.activeTouch && [touches containsObject:self.activeTouch]) {
        [self relayTouch:self.activeTouch phase:@"end"];
        self.activeTouch=nil;
    }
}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    (void)event;
    if(self.activeTouch && [touches containsObject:self.activeTouch]) {
        [self relayTouch:self.activeTouch phase:@"cancel"];
        self.activeTouch=nil;
    }
}
- (void)start {
    if(self.lease || !NSThread.isMainThread || ![self hasSystemOwnedCarPlayWindow])
        return;
    self.lease=[NSTimer scheduledTimerWithTimeInterval:0.75 target:self
                     selector:@selector(refresh:) userInfo:nil repeats:YES];
    [self refresh:nil];
}
- (void)stop {
    [self.lease invalidate];self.lease=nil;
    [self disconnectSurface];
}
- (void)didMoveToWindow {
    [super didMoveToWindow];
    if(!self.window)[self stop];
}
- (void)dealloc {
    [self.lease invalidate];
    [self.remote removeFromSuperlayer];
}
@end
