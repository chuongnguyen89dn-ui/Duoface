#import "MTCPRemoteLayer.h"
#import "MTCPBridgeContract.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <notify.h>
#import <math.h>
// Static linking to Apple's private CAContext API is intentionally avoided.
// No code in this file is installed through a constructor or LS hook.
static NSString *const kControlNotification=@"com.duoface.mytweak.cp-command";
static BOOL MTCPMainThread(void) { return [NSThread isMainThread]; }
static BOOL MTCPIsProcess(NSString *a,NSString *b) {
    NSString *name=NSProcessInfo.processInfo.processName;
    return [name isEqualToString:a] || (b && [name isEqualToString:b]);
}
NSDictionary<NSString *,NSNumber *> *MTCPRemoteLayerCapabilities(void) {
    Class ctx=NSClassFromString(@"CAContext");
    Class host=NSClassFromString(@"CALayerHost");
    BOOL producer=(ctx && [ctx respondsToSelector:NSSelectorFromString(@"remoteContextWithOptions:")] &&
                   [ctx instancesRespondToSelector:NSSelectorFromString(@"setLayer:")] &&
                   [ctx instancesRespondToSelector:NSSelectorFromString(@"contextId")]);
    BOOL consumer=(host && [host instancesRespondToSelector:NSSelectorFromString(@"setContextId:")]);
    return @{@"ProducerAPI":@(producer),@"ReceiverAPI":@(consumer)};
}
@interface MTCPRemoteLayerProducer ()
@property(nonatomic,strong) id remoteContext;
@property(nonatomic,copy,readwrite) NSString *session;
@end
@implementation MTCPRemoteLayerProducer
- (BOOL)publishLayer:(CALayer *)layer normalizedContentBounds:(CGRect)bounds {
    if (!MTCPMainThread() || !MTCPIsProcess(@"SpringBoard",nil) ||
        !MTCPBridgeExplicitOptIn() || ![layer isKindOfClass:CALayer.class] ||
        self.remoteContext)return NO;
    if (![MTCPRemoteLayerCapabilities()[@"ProducerAPI"] boolValue])return NO;
    Class cls=NSClassFromString(@"CAContext");
    id context=nil;
    @try {
        SEL make=NSSelectorFromString(@"remoteContextWithOptions:");
        context=((id(*)(id,SEL,id))objc_msgSend)(cls,make,@{});
        if (!context)return NO;
        ((void(*)(id,SEL,id))objc_msgSend)(context,NSSelectorFromString(@"setLayer:"),layer);
        unsigned int contextID=((unsigned int(*)(id,SEL))objc_msgSend)(
                                 context,NSSelectorFromString(@"contextId"));
        if (!contextID)return NO;
        NSString *session=NSUUID.UUID.UUIDString;
        if (!MTCPBridgeWriteSurface(session,contextID,bounds))return NO;
        self.remoteContext=context;self.session=session;
        return YES;
    } @catch(NSException *ex) {
        NSLog(@"[MyTweakCarPlayPrototype] remote producer rejected %@",ex.name);
        return NO;
    }
}
- (void)invalidate {
    if (self.session)MTCPBridgeInvalidateSurface(self.session);
    // Clearing a remote context must not mutate the source layer hierarchy.
    self.remoteContext=nil;self.session=nil;
}
- (void)dealloc { [self invalidate]; }
@end
@interface MTCPRemoteLayerReceiver ()
@property(nonatomic,strong) CALayer *remoteLayer;
@property(nonatomic,copy,readwrite) NSString *session;
@property(nonatomic,assign) unsigned long long commandSequence;
@property(nonatomic,assign) NSTimeInterval lastMoveAt;
@end
@implementation MTCPRemoteLayerReceiver
- (BOOL)connectWithOwnedContentView:(UIView *)owner {
    if (!MTCPMainThread() || !MTCPIsProcess(@"CarPlay",@"CarPlayApp") ||
        !MTCPBridgeExplicitOptIn() || !owner || !owner.window ||
        !owner.window.windowScene || self.remoteLayer || ![owner.accessibilityIdentifier
             isEqualToString:@"duoface.native.content.host"])return NO;
    // Callers must explicitly supply a native, already system-owned content view.
    // Never search for Dashboard's root window and never replace its view controller.
    if (owner.window.screen==UIScreen.mainScreen)return NO;
    UIEdgeInsets inset=owner.safeAreaInsets;
    if (inset.top<=0 && inset.bottom<=0 && inset.left<=0 && inset.right<=0)return NO;
    CGRect usable=UIEdgeInsetsInsetRect(owner.bounds,inset);
    if (CGRectIsEmpty(usable) || usable.size.width<160 || usable.size.height<80)return NO;
    if (![MTCPRemoteLayerCapabilities()[@"ReceiverAPI"] boolValue])return NO;
    NSDictionary *surface=MTCPBridgeReadSurface(nil);
    if (!surface)return NO;
    Class cls=NSClassFromString(@"CALayerHost");
    @try {
        CALayer *host=[cls layer];
        ((void(*)(id,SEL,unsigned int))objc_msgSend)(host,
             NSSelectorFromString(@"setContextId:"),[surface[@"ContextID"] unsignedIntValue]);
        host.frame=usable;
        host.masksToBounds=YES;
        [owner.layer addSublayer:host];
        self.remoteLayer=host;
        self.frame=usable;self.session=surface[@"Session"];
        self.commandSequence=0;
        // This view does not claim to deliver all UIKit touch semantics.
        // The source-side touch-injection adapter still requires device validation.
        self.backgroundColor=UIColor.clearColor;
        [owner addSubview:self];
        return YES;
    } @catch(NSException *ex) {
        [self disconnect];
        NSLog(@"[MyTweakCarPlayPrototype] remote receiver rejected %@",ex.name);
        return NO;
    }
}
- (void)sendPointer:(NSSet<UITouch *> *)touches phase:(NSString *)phase {
    if (!self.session || !MTCPBridgeExplicitOptIn())return;
    UITouch *touch=touches.anyObject;
    if (!touch || CGRectIsEmpty(self.bounds))return;
    NSTimeInterval now=NSDate.date.timeIntervalSince1970;
    if ([phase isEqualToString:@"move"] && now-self.lastMoveAt<1.0/60.0)return;
    self.lastMoveAt=now;
    CGPoint p=[touch locationInView:self];
    CGPoint normalized=CGPointMake(p.x/CGRectGetWidth(self.bounds),
                                    p.y/CGRectGetHeight(self.bounds));
    if (!isfinite(normalized.x) || !isfinite(normalized.y))return;
    normalized.x=MAX(0,MIN(1,normalized.x));
    normalized.y=MAX(0,MIN(1,normalized.y));
    if (MTCPBridgeWriteCommand(self.session,@"pointer",++self.commandSequence,phase,normalized))
        notify_post(kControlNotification.UTF8String);
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    (void)event;[self sendPointer:touches phase:@"begin"];
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    (void)event;[self sendPointer:touches phase:@"move"];
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    (void)event;[self sendPointer:touches phase:@"end"];
}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    (void)event;[self sendPointer:touches phase:@"cancel"];
}
- (void)disconnect {
    [self.remoteLayer removeFromSuperlayer];
    [self removeFromSuperview];
    self.remoteLayer=nil;self.session=nil;self.commandSequence=0;
}
- (void)dealloc { [self disconnect]; }
@end
