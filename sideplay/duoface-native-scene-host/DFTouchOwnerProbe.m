// Independent, 30-second, on-demand CarPlay touch-owner diagnostic for iOS 16.
// The system CPWindow stays untouched. No vendor binary, app hosting,
// system Dock manipulation, fabricated UIKit touches, or autorun overlay.
#import <UIKit/UIKit.h>
#import "DFNative12Chrome.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <notify.h>
#import <math.h>
#import <fcntl.h>
#import <unistd.h>

static const char *const kStart = "com.duoface.nativehost.touchowner.start.v1";
static const char *const kStop  = "com.duoface.nativehost.touchowner.stop.v1";
static DFNative12Chrome *sChrome;
static NSString *sSession;
static NSUInteger sSequence, sGeneration;

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
    sSession=[value copy];sSequence=0;
    return YES;
}
static void DFSendCommand(NSString *action,NSNumber *ratio) {
    if(!sChrome || !sSession || ![NSProcessInfo.processInfo.processName
                              isEqualToString:@"SpringBoard"])return;
    if(![@[@"App",@"Zoom",@"Style",@"Close",@"SWAP",@"Ratio",
           @"FocusLeft",@"FocusRight",@"Restore"] containsObject:action])return;
    if([action isEqualToString:@"Ratio"] &&
       (![ratio isKindOfClass:NSNumber.class] ||
        !isfinite(ratio.doubleValue) ||
        ratio.doubleValue<1.0/3.0 || ratio.doubleValue>2.0/3.0))return;
    NSMutableDictionary *message=[@{@"Version":@1,@"Session":sSession,
       @"Timestamp":@(NSDate.date.timeIntervalSince1970),
       @"Sequence":@(++sSequence),@"Action":action} mutableCopy];
    if([action isEqualToString:@"App"]||[action isEqualToString:@"Close"]){
        if(!ratio||![ratio isKindOfClass:NSNumber.class]||
           (ratio.integerValue!=0&&ratio.integerValue!=1))return;
    }else if(![action isEqualToString:@"Ratio"] && ratio)return;
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
    if(sChrome){
        [sChrome stop];sChrome=nil;
        DFTOLog(@"window-detached",reason);
    }
    sSession=nil;sActivated=NO;
}
static void DFStartProbe(void) {
    if(sActivated||sChrome)return;
    sActivated=YES;
    if(!DFReadFreshSession()){
        DFTOLog(@"session-rejected",@"missing-stale-or-invalid-launch");
        sActivated=NO;return;
    }
    id display=DFConnectedCarDisplay();
    Class configuration=NSClassFromString(@"FBSDisplayConfiguration");
    Class windowClass=NSClassFromString(@"UIRootSceneWindow");
    SEL makeConfig=NSSelectorFromString(@"initWithCADisplay:isMainDisplay:");
    SEL makeWindow=NSSelectorFromString(@"initWithDisplayConfiguration:");
    if(!display || !configuration || !windowClass ||
       ![configuration instancesRespondToSelector:makeConfig] ||
       ![windowClass instancesRespondToSelector:makeWindow]) {
        DFTOLog(@"preflight-rejected",@"external-display-or-window-ABI-missing");
        DFStopProbe(@"preflight-failed");return;
    }
    @try {
        // Inspect only; never show a discovery window.
        id config=((id(*)(id,SEL,id,BOOL))objc_msgSend)(
            [configuration alloc],makeConfig,display,NO);
        UIWindow *discovery=((id(*)(id,SEL,id))objc_msgSend)(
            [windowClass alloc],makeWindow,config);
        if(![discovery isKindOfClass:UIWindow.class] ||
           !discovery.screen || discovery.screen==UIScreen.mainScreen){
            DFStopProbe(@"external-display-unavailable");return;
        }
        CGRect screen=discovery.screen.bounds;
        NSDictionary *launch=[NSDictionary dictionaryWithContentsOfFile:kSessionFile];
        id value=launch[@"ContentRect"];
        CGRect region=CGRectNull;
        if([value isKindOfClass:NSString.class])region=CGRectFromString(value);
        // CarPlay Dock owns the left rail. Even a mistaken client geometry
        // cannot place our touch windows in that area.
        CGFloat safeLeft=CGRectGetMinX(screen)+MAX(42,screen.size.width*.082);
        if(CGRectIsNull(region) || CGRectIsEmpty(region) ||
           !isfinite(region.origin.x) || !isfinite(region.origin.y) ||
           !CGRectContainsRect(screen,CGRectInset(region,1,1))) {
            region=CGRectMake(safeLeft,screen.origin.y,
                    CGRectGetMaxX(screen)-safeLeft,screen.size.height);
        }else{
            CGFloat x=MAX(region.origin.x,safeLeft);
            CGFloat right=MIN(CGRectGetMaxX(region),CGRectGetMaxX(screen));
            CGFloat y=MAX(region.origin.y,screen.origin.y);
            CGFloat bottom=MIN(CGRectGetMaxY(region),CGRectGetMaxY(screen));
            region=CGRectMake(x,y,MAX(0,right-x),MAX(0,bottom-y));
        }
        if(region.size.width<300 || region.size.height<145) {
            DFTOLog(@"preflight-rejected",@"content-too-small");
            DFStopProbe(@"content-invalid");return;
        }
        sChrome=[[DFNative12Chrome alloc] initWithDisplay:display
                 configuration:configuration windowClass:windowClass
                 contentRect:region command:^(NSString *action,NSNumber *ratio){
            DFSendCommand(action,ratio);
        }];
        if(![sChrome start]) {
            DFStopProbe(@"chrome-window-create-failed");return;
        }
        DFTOLog(@"native12-ui-owner-visible",
          [NSString stringWithFormat:@"windowCount=4 content=%@",
           NSStringFromCGRect(region)]);
        NSUInteger generation=++sGeneration;
        // QA fail-safe only; no overlay survives disconnect and restart.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,600*NSEC_PER_SEC),
                       dispatch_get_main_queue(), ^{
            if(sGeneration==generation)DFStopProbe(@"safety-expiry-600s");
        });
    }@catch(NSException *exception){
        DFTOLog(@"window-exception",exception.name);
        DFStopProbe(@"exception");
    }
}
__attribute__((constructor))
static void DFInstallTouchOwnerProbe(void) {
    @autoreleasepool {
        if(![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"])return;
        dispatch_async(dispatch_get_main_queue(), ^{
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
