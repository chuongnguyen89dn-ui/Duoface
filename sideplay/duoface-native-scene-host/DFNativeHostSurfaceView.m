// DuoFace independent native CarPlay scene CAContext reader. Requires a
// real UIKit-issued CarPlay scene and both existing opt-in switches; never
// creates external windows, changes native Dock, or injects app touches.
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/message.h>
#import <objc/runtime.h>
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
@end
@implementation DFNativeHostSurfaceView
- (instancetype)initWithFrame:(CGRect)frame {
    if((self=[super initWithFrame:frame])) {
        self.opaque=NO;
        self.backgroundColor=UIColor.clearColor;
        self.userInteractionEnabled=NO; // No unverified touch replay.
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
