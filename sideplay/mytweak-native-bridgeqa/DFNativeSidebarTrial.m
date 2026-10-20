#import "DFNativeSidebarTrial.h"
#import "../mytweak-independent-v1a/prototype/MTCPBridgeContract.h"
#import <math.h>
#import <fcntl.h>
#import <unistd.h>
static NSString *const DFNativePrefs=
    @"/var/mobile/Library/Preferences/com.duoface.mytweak.carplay-bridge.plist";
static BOOL DFNativeExplicitTrial(void) {
    NSDictionary *cfg=[NSDictionary dictionaryWithContentsOfFile:DFNativePrefs];
    return [cfg[@"Enabled"] isKindOfClass:NSNumber.class] && [cfg[@"Enabled"] boolValue] &&
           [cfg[@"NativeSidebarTrial"] isKindOfClass:NSNumber.class] &&
           [cfg[@"NativeSidebarTrial"] boolValue];
}
static void DFNativeLog(NSString *event,NSString *detail) {
    NSString *s=[NSString stringWithFormat:@"[DuoFaceNativeSidebar] %@ %@\n",event,detail];
    NSLog(@"%@",s);
    int fd=open("/var/mobile/Library/Logs/DuoFaceNativeBridgeQA.log",
                O_WRONLY|O_APPEND|O_CREAT,0644);
    if(fd>=0){NSData *d=[s dataUsingEncoding:NSUTF8StringEncoding];
        (void)write(fd,d.bytes,d.length);close(fd);}
}
@interface DFNativeSidebarTrial ()
@property(nonatomic,weak) UIWindow *changedWindow;
@property(nonatomic,assign) CGRect originalFrame;
@property(nonatomic,assign) CGRect expectedFrame;
@property(nonatomic,copy) NSString *leaseSession;
@property(nonatomic,copy) NSString *exhaustedSession;
@property(nonatomic,assign) NSTimeInterval beganAt;
@property(nonatomic,assign) NSTimeInterval lastValidAckAt;
@property(nonatomic,assign,readwrite) BOOL active;
@end
@implementation DFNativeSidebarTrial
static BOOL DFClose(CGFloat a,CGFloat b) {
    return isfinite(a)&&isfinite(b)&&fabs(a-b)<1.5;
}
static BOOL DFRectMatches(CGRect a,CGRect b) {
    return DFClose(a.origin.x,b.origin.x)&&DFClose(a.origin.y,b.origin.y) &&
           DFClose(a.size.width,b.size.width)&&DFClose(a.size.height,b.size.height);
}
- (void)stop {
    UIWindow *w=self.changedWindow;
    if(w && self.active && DFRectMatches(w.frame,self.expectedFrame)) {
        // Restore ONLY our own frame. If Dashboard moved it since, leave the
        // system's newer native layout untouched.
        w.frame=self.originalFrame;
        DFNativeLog(@"original-native-frame-restored",NSStringFromCGRect(w.frame));
    }
    self.active=NO;self.changedWindow=nil;self.leaseSession=nil;
    self.lastValidAckAt=0;
    self.originalFrame=CGRectNull;self.expectedFrame=CGRectNull;
}
- (void)tickWithSurface:(NSDictionary *)surface {
    if(![NSThread isMainThread])return;
    NSString *proc=NSProcessInfo.processInfo.processName;
    BOOL allowed=[proc isEqualToString:@"CarPlay"]||[proc isEqualToString:@"CarPlayApp"];
    NSString *session=[surface[@"Session"] isKindOfClass:NSString.class]?surface[@"Session"]:nil;
    if(!allowed || !DFNativeExplicitTrial() || !session) {[self stop];return;}
    if(self.active) {
        NSTimeInterval now=NSDate.date.timeIntervalSince1970;
        // Permit 45s bootstrap, then require refreshed exact-session
        // receiver ACK; do not retain the native window from surface alone.
        NSDictionary *ack=MTCPBridgeReadReceiverAck(session);
        if(ack)self.lastValidAckAt=now;
        BOOL bootstrapExpired=(self.lastValidAckAt<=0 && now-self.beganAt>45);
        BOOL ackLost=(self.lastValidAckAt>0 && now-self.lastValidAckAt>4.0);
        if(![session isEqualToString:self.leaseSession] ||
           bootstrapExpired || ackLost ||
           !self.changedWindow || self.changedWindow.hidden) {
            if(bootstrapExpired || ackLost)
                DFNativeLog(@"native-ack-lease-ended",bootstrapExpired?
                    @"bootstrap-45s-no-ack":@"ack-missing-more-than-4s");
            self.exhaustedSession=self.leaseSession;
            [self stop];return;
        }
        if(!DFRectMatches(self.changedWindow.frame,self.expectedFrame)) {
            DFNativeLog(@"system-changed-frame",@"refusing to fight Dashboard");
            self.exhaustedSession=self.leaseSession;
            // Do not override a more recent system layout.
            self.active=NO;self.changedWindow=nil;self.leaseSession=nil;
            return;
        }
        return;
    }
    if([session isEqualToString:self.exhaustedSession])return;
    // The native window must have actually been observed wholly beyond the
    // LEFT screen edge (x roughly -its own width), NOT merely hidden.
    NSUInteger seen=0;
    UIWindow *candidate=nil;
    CGRect original=CGRectNull, destination=CGRectNull;
    for(UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if(![scene isKindOfClass:UIWindowScene.class] ||
           scene.activationState!=UISceneActivationStateForegroundActive)continue;
        UIWindowScene *ws=(UIWindowScene *)scene;
        if(ws.screen==UIScreen.mainScreen)continue;
        for(UIWindow *w in ws.windows) {
            if(++seen>32)return;
            if(![NSStringFromClass(w.class) isEqualToString:@"DBStatusBarWindow"] ||
               !w.rootViewController ||
               ![NSStringFromClass(w.rootViewController.class)
                            isEqualToString:@"DBRootStatusBarViewController"] ||
               w.hidden || w.alpha<0.95 || w.screen!=ws.screen)continue;
            CGRect display=ws.screen.bounds;
            CGRect f=w.frame;
            if(!isfinite(f.origin.x)||!isfinite(f.origin.y) ||
               f.size.width<20 || f.size.width>display.size.width*0.25 ||
               !DFClose(f.size.height,display.size.height) ||
               !DFClose(f.origin.y,0) || !DFClose(f.origin.x,-f.size.width))
                continue;
            if(candidate)return; // Two possible owners: no frame writes.
            candidate=w;original=f;destination=CGRectOffset(f,f.size.width,0);
        }
    }
    if(!candidate)return;
    @try {
        // One controlled positional trial on the REAL system-owned UIWindow,
        // no private setter and no class hook, never writes opacity or hidden.
        candidate.frame=destination;
        if(!DFRectMatches(candidate.frame,destination)){
            if(DFRectMatches(candidate.frame,original))return;
            DFNativeLog(@"native-frame-rejected",@"system did not accept trial");
            return;
        }
        self.changedWindow=candidate;
        self.originalFrame=original;
        self.expectedFrame=destination;
        self.leaseSession=session;
        self.beganAt=NSDate.date.timeIntervalSince1970;
        self.lastValidAckAt=0;
        self.active=YES;
        DFNativeLog(@"native-frame-trial",
            [NSString stringWithFormat:@"original=%@ new=%@ bootstrapMaxSeconds=45 nativeAckRequired=1",
                NSStringFromCGRect(original),NSStringFromCGRect(destination)]);
    }@catch(NSException *ex){
        self.exhaustedSession=session;
        DFNativeLog(@"native-frame-exception",ex.name);
    }
}
- (void)dealloc {[self stop];}
@end
