// Independent long-lived native CarPlay input owner, session-scoped for iOS 16.
// The system CPWindow stays untouched. No vendor binary, app hosting,
// system Dock manipulation, fabricated UIKit touches, or autorun overlay.
#import <UIKit/UIKit.h>
#import "DFDeepTrace.h"
#import "DFNative12Chrome.h"
#import "DFDockZoomCoordinator.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <notify.h>
#import <math.h>
#import <float.h>
#import <fcntl.h>
#import <unistd.h>

static const char *const kStart = "com.duoface.nativehost.touchowner.start.v1";
static const char *const kStop  = "com.duoface.nativehost.touchowner.stop.v1";
static DFNative12Chrome *sChrome;
static NSString *sSession;
static NSUInteger sSequence, sGeneration;

static BOOL sActivated;
static int sStartToken=-1, sStopToken=-1, sAckToken=-1, sLayoutToken=-1;
static NSUInteger sLastAckSequence=0;
static NSUInteger sRetryCount=0;
static NSTimeInterval sRetryAt=0;
static NSString *const kSessionFile=@"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist";
static NSString *const kCommandFile=@"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.command.plist";
static NSDictionary<NSString *,id> *sZoomReceipt;
static BOOL sZoomFinishing;
static BOOL DFSessionStillActive(void);
// CrashReporter .ips names the exact SpringBoard assertion receiver at
// SBAppViewController sceneHandle:didUpdateSettingsWithDiff:+440, but omits
// NSException.name/reason. Do not hook private SpringBoard methods or swallow
// its exceptions. Record ONLY the uncaught reason during a live DuoFace
// CarPlay session and chain the pre-existing process-wide handler.
static NSUncaughtExceptionHandler *sPreviousFatalHandler;
static BOOL sFatalHandlerInstalled;
static void DFCaptureFatalException(NSException *exception) {
    if (sActivated && sChrome) {
        @try {
            NSString *name=exception.name?:@"(nil)";
            NSString *reason=exception.reason?:@"(nil)";
            if(reason.length>1024)reason=[reason substringToIndex:1024];
            NSArray<NSString *> *stack=exception.callStackSymbols;
            NSString *callers=stack.count?[[stack subarrayWithRange:
                 NSMakeRange(0,MIN((NSUInteger)12,stack.count))]
                 componentsJoinedByString:@" | "]:@"(unavailable)";
            NSString *line=[NSString stringWithFormat:
               @"pid=%d build=0.0.82~sceneowner1 name=%@ reason=%@ stack=%@\n",
                getpid(),name,reason,callers];
            NSData *data=[line dataUsingEncoding:NSUTF8StringEncoding];
            int fd=open("/var/mobile/Library/Logs/DuoFaceFatalException.log",
                        O_WRONLY|O_APPEND|O_CREAT,0644);
            if(fd>=0) {
                if(data.length)(void)write(fd,data.bytes,data.length);
                (void)fsync(fd);
                (void)close(fd);
            }
        } @catch (NSException *ignored) { (void)ignored; }
    }
    // An existing exception handler must retain control of exception policy.
    // This handler neither returns success nor attempts to keep SpringBoard
    // running after an NSAssertionHandler/ObjC uncaught exception.
    if(sPreviousFatalHandler && sPreviousFatalHandler!=DFCaptureFatalException)
        sPreviousFatalHandler(exception);
}
static void DFArmFatalReasonRecorder(void) {
    if(sFatalHandlerInstalled)return;
    sPreviousFatalHandler=NSGetUncaughtExceptionHandler();
    NSSetUncaughtExceptionHandler(DFCaptureFatalException);
    sFatalHandlerInstalled=YES;
}
static NSString *const kAckFile=@"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.ack.plist";
static const char *const kAckNotify="com.duoface.nativehost.touchowner.ack.v1";
static const char *const kCommandNotify="com.duoface.nativehost.touchowner.command.v1";

static void DFTOLog(NSString *event, NSString *detail) {
    // Exact command sequence/ACK and touch owner events share the same
    // timestamped 2 MiB log as real player, system Dock and native CPWindow.
    DFDeepTrace(@"touch-owner",[NSString stringWithFormat:
        @"event=%@ %@",event?:@"-",detail?:@""]);
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
    if(![record[@"Active"] isEqual:@YES] ||
       ![record[@"Version"] isEqual:@1] ||
       ![value isKindOfClass:NSString.class] ||
       ![[NSUUID alloc] initWithUUIDString:value] ||
       ![stamp isKindOfClass:NSNumber.class])return NO;
    NSTimeInterval age=NSDate.date.timeIntervalSince1970-[stamp doubleValue];
    if(!isfinite(age) || age<0 || age>2.5)return NO;
    sSession=[value copy];sSequence=0;sLastAckSequence=0;
    sRetryCount=0;sRetryAt=0;
    return YES;
}
static void DFSendCommand(NSString *action,NSNumber *ratio) {
    NSDictionary *pulse=[NSDictionary dictionaryWithContentsOfFile:kSessionFile];
    id stamp=pulse[@"Timestamp"];
    NSTimeInterval age=[stamp isKindOfClass:NSNumber.class]?
         NSDate.date.timeIntervalSince1970-[stamp doubleValue]:DBL_MAX;
    if(![pulse[@"Active"] isEqual:@YES] ||
       ![pulse[@"Session"] isEqualToString:sSession] ||
       !isfinite(age) || age<0 || age>2.5)return;
    if(!sChrome || !sSession || ![NSProcessInfo.processInfo.processName
                              isEqualToString:@"SpringBoard"])return;
    if(![@[@"App",@"Zoom",@"Style",@"Close",@"SWAP",@"Ratio",
           @"FocusLeft",@"FocusRight",@"FocusSlot2",@"FocusSlot3",@"Restore"] containsObject:action])return;
    if([action isEqualToString:@"Ratio"] &&
       (![ratio isKindOfClass:NSNumber.class] ||
        !isfinite(ratio.doubleValue) ||
        ratio.doubleValue<1.0/3.0 || ratio.doubleValue>2.0/3.0))return;
    if([action isEqualToString:@"Zoom"] && !sZoomFinishing){
        // The source window still has not changed. Ask the *actual* CarPlay
        // Dock owner first, then use its real ACK to apply the pane geometry.
        DFDockZoomToggle(sChrome,sSession,^(BOOL applied,BOOL expanded,
                                            NSDictionary *receipt){
            if(!sChrome || !DFSessionStillActive())return;
            sZoomReceipt=[receipt copy];
            [sChrome completeWholeHostZoomRequest:applied];
            DFTOLog(applied?@"native12-whole-host-zoom-applied":
                              @"native12-whole-host-zoom-rejected",
                    [NSString stringWithFormat:@"expanded=%d %@",expanded,
                     receipt[@"Reason"]?:receipt[@"OwnerClass"]?:@"unknown"]);
            sZoomFinishing=YES;
            DFSendCommand(@"Zoom",nil);
            sZoomFinishing=NO;
            sZoomReceipt=nil;
        });
        return;
    }
    // Source UI action already executed before this post-action message.
    // Send a snapshot of the REAL owner, never a command that a second
    // controller will "pretend" to execute or mutate independently.
    NSDictionary *state=[sChrome stateSnapshot];
    if(![state[@"Owner"] isEqualToString:@"SpringBoard"] ||
       ![state[@"SlotCount"] isKindOfClass:NSNumber.class])return;
    if([action isEqualToString:@"App"]||[action isEqualToString:@"Close"]){
        if(!ratio||![ratio isKindOfClass:NSNumber.class]||
           (ratio.integerValue<0||ratio.integerValue>3))return;
    }else if(![action isEqualToString:@"Ratio"] && ratio)return;
    NSMutableDictionary *message=[@{@"Version":@2,@"Session":sSession,
       @"Timestamp":@(NSDate.date.timeIntervalSince1970),
       @"Sequence":@(++sSequence),@"Action":action,
       @"State":state} mutableCopy];
    if(ratio)message[@"Ratio"]=ratio;
    if([action isEqualToString:@"Zoom"] && sZoomReceipt)
        message[@"ZoomReceipt"]=sZoomReceipt;
    if(![message writeToFile:kCommandFile atomically:YES]){
        DFTOLog(@"command-write-failed",action);return;
    }
    sRetryCount=0;sRetryAt=NSDate.date.timeIntervalSince1970;
    int rc=notify_post(kCommandNotify);
    DFTOLog(@"command-dispatched",[NSString stringWithFormat:
       @"action=%@ seq=%lu status=%d",action,(unsigned long)sSequence,rc]);
}
static void DFReceiveAck(void) {
    NSDictionary *ack=[NSDictionary dictionaryWithContentsOfFile:kAckFile];
    id session=ack[@"Session"],number=ack[@"Sequence"];
    if(!sChrome || ![ack[@"Version"] isEqual:@2] ||
       ![ack[@"Accepted"] isKindOfClass:NSNumber.class] ||
       ![session isKindOfClass:NSString.class] ||
       ![session isEqualToString:sSession] ||
       ![number isKindOfClass:NSNumber.class])return;
    NSUInteger sequence=[number unsignedIntegerValue];
    if(sequence<=sLastAckSequence || sequence>sSequence)return;
    sLastAckSequence=sequence;
    // A negative ACK is a terminal result for this state observation.
    // Consume its sequence so the 0.8-second retry never claims success.
    if(![ack[@"Accepted"] boolValue]){
        NSString *reason=[ack[@"Reason"] isKindOfClass:NSString.class]?
            ack[@"Reason"]:@"rejected";
        DFTOLog(@"carplay-action-not-applied",[NSString stringWithFormat:
            @"session=%@ seq=%lu action=%@ reason=%@",
            session,(unsigned long)sequence,ack[@"Action"],reason]);
        return;
    }
    DFTOLog(@"carplay-state-ack", [NSString stringWithFormat:
         @"session=%@ seq=%lu action=%@ owner=%@",
         session,(unsigned long)sequence,ack[@"Action"],ack[@"Owner"]]);
}
static void DFStopProbe(NSString *reason) {
    // Revoke the current generation BEFORE any potentially slow media-scene
    // teardown. Queued start/ACK commands can never revive a closed session.
    sGeneration++;
    // Exact old-session cleanup while its ID still exists. The CarPlay
    // process also has an independent heartbeat watchdog restoring the Dock.
    DFDockZoomDetach(sChrome,sSession);
    sZoomReceipt=nil;sZoomFinishing=NO;
    sActivated=NO;
    sSession=nil;
    sLastAckSequence=0;
    sRetryCount=0;sRetryAt=0;
    DFNative12Chrome *old=sChrome;
    sChrome=nil;
    if(old){
        [old stop];
        DFTOLog(@"window-detached",reason);
    }
}
static BOOL DFSessionStillActive(void) {
    NSDictionary *pulse=[NSDictionary dictionaryWithContentsOfFile:kSessionFile];
    id timestamp=pulse[@"Timestamp"];
    if(!sSession || ![pulse[@"Session"] isEqualToString:sSession] ||
       ![pulse[@"Active"] isEqual:@YES] ||
       ![timestamp isKindOfClass:NSNumber.class])return NO;
    NSTimeInterval age=NSDate.date.timeIntervalSince1970-[timestamp doubleValue];
    return isfinite(age) && age>=0 && age<=2.5;
}
// Independent SpringBoard watchdog: works even if CarPlay app crashes,
// is suspended on Home, or fails to deliver a scene disconnect callback.
static void DFWatchdog(NSUInteger generation) {
    if(generation!=sGeneration || !sChrome || !sActivated)return;
    NSDictionary *pulse=[NSDictionary dictionaryWithContentsOfFile:kSessionFile];
    id stamp=pulse[@"Timestamp"];
    NSTimeInterval age=[stamp isKindOfClass:NSNumber.class]?
        NSDate.date.timeIntervalSince1970-[stamp doubleValue]:DBL_MAX;
    if(![pulse[@"Active"] isEqual:@YES] ||
       ![pulse[@"Session"] isEqualToString:sSession] ||
       !isfinite(age) || age<0 || age>2.5){
        DFTOLog(@"watchdog-detach",
           [NSString stringWithFormat:@"age=%.2f active=%@ session-match=%d",
            age,pulse[@"Active"],[pulse[@"Session"] isEqualToString:sSession]]);
        DFStopProbe(@"inactive-or-stale-heartbeat");
        return;
    }
    // Darwin notifies may be coalesced or dropped when the CarPlay process is
    // briefly busy. A single atomic file contains the LATEST real-state
    // observation, so retry only its notify/receipt (never re-run a UI command).
    // Also read persisted ACK in case the return notification was dropped.
    DFReceiveAck();
    NSTimeInterval now=NSDate.date.timeIntervalSince1970;
    if(sSequence>sLastAckSequence && sRetryCount<3 &&
       sRetryAt>0 && now-sRetryAt>=.8){
        NSDictionary *last=[NSDictionary dictionaryWithContentsOfFile:kCommandFile];
        if([last[@"Version"] isEqual:@2] &&
           [last[@"Session"] isEqualToString:sSession] &&
           [last[@"Sequence"] unsignedIntegerValue]==sSequence){
            NSMutableDictionary *retry=[last mutableCopy];
            retry[@"Timestamp"]=@(now);
            if([retry writeToFile:kCommandFile atomically:YES]){
                sRetryAt=now;
                ++sRetryCount;
                int result=notify_post(kCommandNotify);
                DFTOLog(@"latest-state-ack-retry", [NSString stringWithFormat:
                   @"seq=%lu attempt=%lu notify=%d",
                   (unsigned long)sSequence,(unsigned long)sRetryCount,result]);
            }
        }
    }
    // A .5-second watchdog only backs up the immediate CarPlay stop signal.
    // No arbitrary session-expiry timer: active trips must run indefinitely.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(.5*NSEC_PER_SEC)),
        dispatch_get_main_queue(),^{DFWatchdog(generation);});
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
        // CarPlay Home may be pressed after the initial file read but before
        // expensive CADisplay/window ABI probing completes. Never show
        // anything from a revoked session or an obsolete queued start.
        if(!DFSessionStillActive()){
            DFStopProbe(@"session-revoked-before-window-start");return;
        }
        sChrome=[[DFNative12Chrome alloc] initWithDisplay:display
                 configuration:configuration windowClass:windowClass
                 contentRect:region command:^(NSString *action,NSNumber *ratio){
            DFSendCommand(action,ratio);
        }];
        if(![sChrome start]) {
            DFStopProbe(@"chrome-window-create-failed");return;
        }
        if(!DFSessionStillActive()){
            DFStopProbe(@"session-revoked-during-window-start");return;
        }
        DFTOLog(@"native12-ui-owner-visible",
          [NSString stringWithFormat:@"windowCount=4 content=%@",
           NSStringFromCGRect(region)]);
        // Arm only after the real external CarPlay scene + chrome exist.
        // No system-method swizzles; leave app/video geometry unchanged.
        DFArmFatalReasonRecorder();
        DFTOLog(@"fatal-exception-reason-recorder-armed",
                @"uncaught-only chain-previous no-exception-swallow");
        NSUInteger generation=++sGeneration;
        // Native12 parity: remain active as long as CarPlay's foreground
        // owner sends fresh heartbeats; Home disconnect/revoke tears down.
        DFWatchdog(generation);
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
            int ack=notify_register_dispatch(kAckNotify,&sAckToken,
                       dispatch_get_main_queue(),^(int t) {
                (void)t;DFReceiveAck();
            });
            int layout=notify_register_dispatch(
                    "com.duoface.nativehost.layout.changed.v1",&sLayoutToken,
                    dispatch_get_main_queue(),^(int t) {
                (void)t;
                if(sChrome && sActivated){
                    if(![sChrome applyLayoutSettingsFromDisk])
                        DFTOLog(@"layout-update-rejected",@"invalid-persisted-layout");
                }
            });
            DFTOLog(@"listener-registered",
                [NSString stringWithFormat:@"start=%d stop=%d ack=%d layout=%d",
                 a,b,ack,layout]);
        });
    }
}
