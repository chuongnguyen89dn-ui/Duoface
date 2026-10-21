// Independent, 30-second, on-demand CarPlay touch-owner diagnostic for iOS 16.
// The system CPWindow stays untouched. No vendor binary, app hosting,
// system Dock manipulation, fabricated UIKit touches, or autorun overlay.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <notify.h>
#import <math.h>
#import <fcntl.h>
#import <unistd.h>

static const char *const kStart = "com.duoface.nativehost.touchowner.start.v1";
static const char *const kStop  = "com.duoface.nativehost.touchowner.stop.v1";
static UIWindow *sWindow;
static UILabel *sGestureLabel;
static NSString *sSession;
static NSUInteger sTaps, sGeneration, sSequence;
static CGFloat sRatio=0.5, sDragStartRatio=0.5;
static NSTimeInterval sLastRatioSent;
static BOOL sActivated;
static int sStartToken=-1, sStopToken=-1;
static NSString *const kSessionFile=@"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist";
static NSString *const kCommandFile=@"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.command.plist";
static const char *const kCommandNotify="com.duoface.nativehost.touchowner.command.v1";

static void DFTOLog(NSString *event, NSString *detail) {
    NSString *line=[NSString stringWithFormat:@"[DFTouchOwner] %@ %@\n",
        event?:@"-", detail?:@""];
    NSLog(@"%@",line);
    int fd=open("/var/mobile/Library/Logs/DuoFaceTouchOwner.log",
                O_WRONLY|O_APPEND|O_CREAT,0644);
    if(fd>=0) {
        NSData *d=[line dataUsingEncoding:NSUTF8StringEncoding];
        (void)write(fd,d.bytes,d.length);
        close(fd);
    }
}
static id DFGetObject(id object,NSString *name) {
    if(!object)return nil;
    SEL sel=NSSelectorFromString(name);
    if(![object respondsToSelector:sel])return nil;
    Class cls=object_isClass(object)?(Class)object:object_getClass(object);
    Method method=object_isClass(object)?class_getClassMethod(cls,sel):
                                 class_getInstanceMethod(cls,sel);
    char ret[16]={0};
    if(!method)return nil;
    method_getReturnType(method,ret,sizeof(ret));
    if(ret[0]!='@')return nil;
    @try{return ((id(*)(id,SEL))objc_msgSend)(object,sel);}
    @catch(NSException *exception) {
        DFTOLog(@"getter-exception",NSStringFromClass(exception.class));
        return nil;
    }
}
static id DFConnectedCarDisplay(void) {
    id device=DFGetObject(NSClassFromString(@"AVExternalDevice"),
                          @"currentCarPlayExternalDevice");
    NSArray *ids=DFGetObject(device,@"screenIDs");
    NSArray *displays=DFGetObject(NSClassFromString(@"CADisplay"),@"displays");
    if(![ids isKindOfClass:NSArray.class] ||
       ![displays isKindOfClass:NSArray.class] || ids.count==0)return nil;
    for(id display in displays) {
        id uid=DFGetObject(display,@"uniqueId");
        if(uid && [ids containsObject:uid])return display;
    }
    return nil;
}
static BOOL DFReadFreshSession(void) {
    NSDictionary *record=[NSDictionary dictionaryWithContentsOfFile:kSessionFile];
    id value=record[@"Session"], stamp=record[@"Timestamp"];
    if(![record[@"Version"] isEqual:@1] ||
       ![value isKindOfClass:NSString.class] ||
       ![[NSUUID alloc] initWithUUIDString:value] ||
       ![stamp isKindOfClass:NSNumber.class])return NO;
    NSTimeInterval age=NSDate.date.timeIntervalSince1970-[stamp doubleValue];
    if(!isfinite(age) || age<0 || age>5)return NO;
    sSession=[value copy];sSequence=0;sRatio=0.5;sLastRatioSent=0;
    return YES;
}
static void DFSendCommand(NSString *action,NSNumber *ratio) {
    if(!sWindow || !sSession || ![NSProcessInfo.processInfo.processName
                              isEqualToString:@"SpringBoard"])return;
    if(![@[@"App",@"Zoom",@"Style",@"Close",@"SWAP",@"Ratio"] containsObject:action])return;
    if([action isEqualToString:@"Ratio"] &&
       (![ratio isKindOfClass:NSNumber.class] ||
        !isfinite(ratio.doubleValue) ||
        ratio.doubleValue<1.0/3.0 || ratio.doubleValue>2.0/3.0))return;
    NSMutableDictionary *message=[@{@"Version":@1,@"Session":sSession,
       @"Timestamp":@(NSDate.date.timeIntervalSince1970),
       @"Sequence":@(++sSequence),@"Action":action} mutableCopy];
    if(ratio)message[@"Ratio"]=ratio;
    if(![message writeToFile:kCommandFile atomically:YES]){
        DFTOLog(@"command-write-failed",action);return;
    }
    int rc=notify_post(kCommandNotify);
    DFTOLog(@"command-dispatched",[NSString stringWithFormat:
       @"action=%@ seq=%lu status=%d",action,(unsigned long)sSequence,rc]);
}
static void DFStopProbe(NSString *reason) {
    sGeneration++;
    if(sWindow) {
        sWindow.hidden=YES;
        sWindow.rootViewController=nil;
        sWindow=nil;
        sGestureLabel=nil;
        DFTOLog(@"window-detached",reason);
    }
    sActivated=NO;sSession=nil;
}
@interface DFTouchOwnerHandler : NSObject
@end
@implementation DFTouchOwnerHandler
- (void)tapped:(UIButton *)sender {
    if(!sActivated || !sWindow)return;
    NSArray *actions=@[@"App",@"Zoom",@"Style",@"SWAP",@"Close"];
    if(sender.tag<0 || sender.tag>=(NSInteger)actions.count)return;
    NSString *action=actions[(NSUInteger)sender.tag];
    sTaps++;
    DFTOLog(@"real-button-action",[NSString stringWithFormat:
      @"action=%@ count=%lu",action,(unsigned long)sTaps]);
    DFSendCommand(action,nil);
}
- (void)dividerPanned:(UIPanGestureRecognizer *)pan {
    if(!sWindow || !sGestureLabel || !sSession)return;
    if(pan.state==UIGestureRecognizerStateBegan){
        sDragStartRatio=sRatio;
        DFTOLog(@"divider-pan-begin",[NSString stringWithFormat:@"ratio=%.3f",sRatio]);
        return;
    }
    if(pan.state==UIGestureRecognizerStateChanged ||
       pan.state==UIGestureRecognizerStateEnded){
        CGFloat dx=[pan translationInView:sWindow].x;
        CGFloat ratio=MAX(1.0/3.0,MIN(2.0/3.0,
                      sDragStartRatio+dx/230.0));
        sRatio=ratio;
        sGestureLabel.text=[NSString stringWithFormat:
           @"KÉO CHIA %.0f/%.0f",ratio*100,(1-ratio)*100];
        NSTimeInterval now=NSDate.date.timeIntervalSince1970;
        BOOL ended=(pan.state==UIGestureRecognizerStateEnded);
        if(ended || now-sLastRatioSent>=0.05){
            DFSendCommand(@"Ratio",@(ratio));
            sLastRatioSent=now;
        }
        if(ended)DFTOLog(@"divider-pan-end",
             [NSString stringWithFormat:@"ratio=%.3f",ratio]);
    } else if(pan.state==UIGestureRecognizerStateCancelled){
        sRatio=sDragStartRatio;
        sGestureLabel.text=[NSString stringWithFormat:
           @"KÉO CHIA %.0f/%.0f",sRatio*100,(1-sRatio)*100];
        DFSendCommand(@"Ratio",@(sRatio));
        DFTOLog(@"divider-pan-cancel",@"rollback");
    }
}
@end
static DFTouchOwnerHandler *sHandler;
static void DFStartProbe(void) {
    if(sActivated || sWindow)return;
    sActivated=YES; // one attempt per CarPlay activation, no retry storm.
    if(!DFReadFreshSession()){
        DFTOLog(@"session-rejected",@"missing-stale-or-invalid-launch");return;
    }
    id display=DFConnectedCarDisplay();
    Class configuration=NSClassFromString(@"FBSDisplayConfiguration");
    Class windowClass=NSClassFromString(@"UIRootSceneWindow");
    SEL makeConfig=NSSelectorFromString(@"initWithCADisplay:isMainDisplay:");
    SEL makeWindow=NSSelectorFromString(@"initWithDisplayConfiguration:");
    if(!display || !configuration || !windowClass ||
       ![configuration instancesRespondToSelector:makeConfig] ||
       ![windowClass instancesRespondToSelector:makeWindow]) {
        DFTOLog(@"preflight-rejected",
           [NSString stringWithFormat:@"display=%d config=%d window=%d",
               display!=nil,configuration!=nil,windowClass!=nil]);
        return;
    }
    @try {
        id config=((id(*)(id,SEL,id,BOOL))objc_msgSend)(
            [configuration alloc],makeConfig,display,NO);
        UIWindow *window=((id(*)(id,SEL,id))objc_msgSend)(
            [windowClass alloc],makeWindow,config);
        if(!window || ![window isKindOfClass:UIWindow.class] ||
           !window.screen || window.screen==UIScreen.mainScreen) {
            DFTOLog(@"window-rejected",@"not-an-external-UIWindow");
            return;
        }
        // A bounded 230 x 80pt QA strip, never covering Apple Dock.
        CGRect screen=window.screen.bounds;
        if(CGRectGetWidth(screen)<320 || CGRectGetHeight(screen)<160) {
            DFTOLog(@"window-rejected",@"screen-bounds-too-small");
            return;
        }
        CGRect target=CGRectMake(CGRectGetMaxX(screen)-242,
                                 CGRectGetMinY(screen)+8,230,80);
        window.frame=target;
        if(fabs(window.frame.size.width-230)>1 ||
           fabs(window.frame.size.height-80)>1) {
            DFTOLog(@"window-rejected",@"window-does-not-support-bounded-frame");
            return;
        }
        UIViewController *root=[UIViewController new];
        root.view=[[UIView alloc]initWithFrame:CGRectMake(0,0,230,80)];
        root.view.backgroundColor=[UIColor colorWithWhite:0.15 alpha:0.96];
        root.view.layer.cornerRadius=10;
        root.view.clipsToBounds=YES;
        NSArray<NSString *> *labels=@[@"App",@"Zoom",@"Style",@"Swap",@"Close"];
        for(NSUInteger i=0;i<labels.count;i++){
            UIButton *button=[UIButton buttonWithType:UIButtonTypeSystem];
            button.tag=(NSInteger)i;
            button.frame=CGRectMake(i*46,0,46,35);
            button.backgroundColor=[UIColor colorWithWhite:.25 alpha:1.0];
            [button setTitle:labels[i] forState:UIControlStateNormal];
            [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
            button.titleLabel.font=[UIFont boldSystemFontOfSize:11];
            [button addTarget:sHandler action:@selector(tapped:)
                      forControlEvents:UIControlEventTouchUpInside];
            [root.view addSubview:button];
        }
        UILabel *drag=[UILabel new];
        drag.frame=CGRectMake(0,40,230,40);
        drag.backgroundColor=[UIColor colorWithRed:.1 green:.55 blue:.86 alpha:1];
        drag.text=@"KÉO CHIA 50/50";
        drag.textAlignment=NSTextAlignmentCenter;
        drag.textColor=UIColor.whiteColor;
        drag.font=[UIFont boldSystemFontOfSize:13];
        drag.userInteractionEnabled=YES;
        UIPanGestureRecognizer *pan=[[UIPanGestureRecognizer alloc]
                  initWithTarget:sHandler action:@selector(dividerPanned:)];
        [drag addGestureRecognizer:pan];
        [root.view addSubview:drag];
        window.rootViewController=root;
        window.backgroundColor=UIColor.clearColor;
        window.opaque=NO;
        window.windowLevel=UIWindowLevelNormal+1;
        sWindow=window;sGestureLabel=drag;sTaps=0;
        window.hidden=NO;
        DFTOLog(@"gesture-owner-window-visible",
           [NSString stringWithFormat:@"class=%@ frame=%@ screen=%@",
               NSStringFromClass(window.class),NSStringFromCGRect(window.frame),
               NSStringFromCGRect(screen)]);
        NSUInteger generation=++sGeneration;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,30*NSEC_PER_SEC),
                       dispatch_get_main_queue(), ^{
            if(sGeneration==generation)DFStopProbe(@"timeout-30s");
        });
    } @catch(NSException *exception) {
        DFTOLog(@"window-exception",exception.reason);
        DFStopProbe(@"exception");
    }
}
__attribute__((constructor))
static void DFInstallTouchOwnerProbe(void) {
    @autoreleasepool {
        if(![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"])return;
        dispatch_async(dispatch_get_main_queue(), ^{
            sHandler=[DFTouchOwnerHandler new];
            int a=notify_register_dispatch(kStart,&sStartToken,
                      dispatch_get_main_queue(),^(int t) {
                (void)t;DFStartProbe();
            });
            int b=notify_register_dispatch(kStop,&sStopToken,
                      dispatch_get_main_queue(),^(int t) {
                (void)t;DFStopProbe(@"nativehost-disconnected");
            });
            DFTOLog(@"listener-registered",
                [NSString stringWithFormat:@"start=%d stop=%d",a,b]);
        });
    }
}
