// Independent long-lived native CarPlay input owner, session-scoped for iOS 16.
// The system CPWindow stays untouched. No vendor binary, app hosting,
// system Dock manipulation, fabricated UIKit touches, or autorun overlay.
#import <UIKit/UIKit.h>
#import "DFDeepTrace.h"
#import "DFGeometrySnapshot119.h"
#import "DFCarPlayOwnerLease.h"
#import "DFNative12Chrome.h"
#import "DFDockZoomCoordinator.h"
#import "DFDisconnectCloseCoordinator.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <notify.h>
#import <math.h>
#import <float.h>
#import <fcntl.h>
#import <unistd.h>
#import <dlfcn.h>
#import <CoreFoundation/CoreFoundation.h>

static const char *const kStart = "com.duoface.nativehost.touchowner.start.v1";
static const char *const kStop  = "com.duoface.nativehost.touchowner.stop.v1";
static DFNative12Chrome *sChrome;
static NSString *sSession;
static NSUInteger sSequence, sGeneration;

static NSString *sGeometrySample119;
static NSDictionary *sLaunchGeometry119;
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
static void DFEnsureDisconnectMonitor(void);
static BOOL sDisconnectMonitorArmed;
static BOOL sShownFirstSplashForPhysicalConnection;
static NSUInteger sNativeRail120WaitCount;
static NSString *const kNativeRail120File=
    @"/var/mobile/Library/Preferences/com.duoface.nativehost.native-rail.v1.plist";
// QA120: only an independently validated native CarPlay AppDock/status-rail
// and matching content-window edge may replace the .118 emergency left guard.
// The counterpart verifies actual UIKit controller/view/window ancestry.
// No zero-offset, fixed 45pt, or guessed percentage is accepted here.
static BOOL DFVerifiedNativeContent120(NSDictionary *rail, NSString *session,
                                       UIScreen *screen, CGRect *outContent) {
    if(![rail isKindOfClass:NSDictionary.class] || !screen ||
       ![rail[@"Version"] isEqual:@1] ||
       ![rail[@"Status"] isEqualToString:@"verified-native-rail"] ||
       ![rail[@"OwnerProcess"] isEqualToString:@"CarPlay"] ||
       ![rail[@"Session"] isEqualToString:session] ||
       ![rail[@"RailOwnerClass"] isEqualToString:@"DBStatusBarWindow"] ||
       ![rail[@"RootControllerClass"] isEqualToString:@"DBRootStatusBarViewController"] ||
       ![@[@"DBAppDockViewController",@"CARAppDockViewController"]
                   containsObject:rail[@"DockControllerClass"]] ||
       ![rail[@"ContentWindowClass"] isEqualToString:@"DBNotificationWindow"] ||
       ![rail[@"Timestamp"] isKindOfClass:NSNumber.class] ||
       ![rail[@"ScreenScale"] isKindOfClass:NSNumber.class])return NO;
    NSTimeInterval age=NSDate.date.timeIntervalSince1970-[rail[@"Timestamp"] doubleValue];
    if(!isfinite(age)||age<0||age>2.5||
       fabs([rail[@"ScreenScale"] doubleValue]-screen.scale)>.01)return NO;
    CGRect whole=CGRectFromString(rail[@"ScreenBounds"]?:@"");
    CGRect dockRail=CGRectFromString(rail[@"RailFrameInScreen"]?:@"");
    CGRect dockView=CGRectFromString(rail[@"DockViewFrameInScreen"]?:@"");
    CGRect content=CGRectFromString(rail[@"ContentFrameInScreen"]?:@"");
    CGRect actual=screen.bounds;
    if(CGRectIsNull(whole)||CGRectIsEmpty(whole)||
       CGRectIsNull(dockRail)||CGRectIsEmpty(dockRail)||
       CGRectIsNull(dockView)||CGRectIsEmpty(dockView)||
       CGRectIsNull(content)||CGRectIsEmpty(content)||
       fabs(whole.origin.x-actual.origin.x)>.5 ||
       fabs(whole.origin.y-actual.origin.y)>.5 ||
       fabs(whole.size.width-actual.size.width)>.5 ||
       fabs(whole.size.height-actual.size.height)>.5 ||
       fabs(CGRectGetMinX(dockRail)-CGRectGetMinX(actual))>1.5 ||
       fabs(CGRectGetMaxX(dockRail)-CGRectGetMinX(content))>1.5 ||
       fabs(CGRectGetMaxX(content)-CGRectGetMaxX(actual))>1.5 ||
       fabs(CGRectGetMaxY(content)-CGRectGetMaxY(actual))>1.5 ||
       fabs(CGRectGetMinY(content)-CGRectGetMinY(actual))>1.5 ||
       CGRectGetMinX(dockView)<CGRectGetMinX(dockRail)-1.5 ||
       CGRectGetMaxX(dockView)>CGRectGetMaxX(dockRail)+1.5)return NO;
    if(outContent)*outContent=content;
    return YES;
}
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
               @"pid=%d build=0.0.86~nativeowner1 name=%@ reason=%@ stack=%@\n",
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
static void DFEnsureDisconnectMonitor(void) {
 if(sDisconnectMonitorArmed)return;
 if(!sChrome && !DFDisconnectCloseNeedsMonitoring() &&
    !sShownFirstSplashForPhysicalConnection)return;
 sDisconnectMonitorArmed=YES;
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),
                dispatch_get_main_queue(),^{
    sDisconnectMonitorArmed=NO;
    if(sChrome || DFDisconnectCloseNeedsMonitoring() ||
       sShownFirstSplashForPhysicalConnection){
       // Actual unplug resets first-start status; CarPlay Home never does.
       BOOL connected=DFConnectedCarDisplay()!=nil;
       if(!connected && sShownFirstSplashForPhysicalConnection){
          sShownFirstSplashForPhysicalConnection=NO;
          DFTOLog(@"physical-carplay-disconnected-reset-splash",@"");
       }
       DFDisconnectClosePhysicalObserved(connected);
       DFEnsureDisconnectMonitor();
    }
 });
}
static BOOL DFReadFreshSession(void) {
    NSDictionary *record=[NSDictionary dictionaryWithContentsOfFile:kSessionFile];
    id value=record[@"Session"], stamp=record[@"Timestamp"];
    if(!DFOwnerAcceptPulse(record) || ![record[@"Active"] isEqual:@YES] ||
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
    if(!DFOwnerAcceptPulse(pulse) ||
       ![pulse[@"Session"] isEqualToString:sSession])return;
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
// QA121 independent iOS16 system-idle assertion, scoped to the REAL active
// CarPlay foreground session. Original DuoNavi 1.0.4 signed ARM64 separately
// proves CBBridgeManager has a real acquire/release IOPMAssertion pair
// (0x1c05b8/0x1c0650) of type PreventUserIdleSystemSleep. We use the public
// IOKit C ABI with our OWN session state, not original binary or license.
// This does NOT force the iPhone display bright/on, spoof lock state, unlock,
// change video scene geometry, or override SpringBoard background transitions.
// A hardware power button may still lock. Always release on Home/disconnect,
// even if the CarPlay host crashes and only the 2.5s watchdog detects it.
static uint32_t sDFCarPlaySystemSleepID121;
static NSString *sDFCarPlaySystemSleepSession121;
static void *sDFCarPlayIOKit121;
typedef int32_t (*DFIOPMCreate121)(CFStringRef,uint32_t,CFStringRef,uint32_t *);
typedef int32_t (*DFIOPMRelease121)(uint32_t);
static DFIOPMRelease121 sDFIOPMRelease121;
static void DFCarPlayReleaseIdleSystem121(void) {
    if(sDFCarPlaySystemSleepID121 && sDFIOPMRelease121) {
        uint32_t oldID=sDFCarPlaySystemSleepID121;
        sDFCarPlaySystemSleepID121=0;
        int32_t result=sDFIOPMRelease121(oldID);
        DFTOLog(@"qa121-system-idle-assertion-released",
              [NSString stringWithFormat:@"status=%d",result]);
    }
    sDFCarPlaySystemSleepID121=0;
    sDFCarPlaySystemSleepSession121=nil;
}
static void DFCarPlayPreventIdleSystemSleep121(void) {
    if(!sChrome || !sActivated || !sSession || !DFSessionStillActive() ||
       !DFConnectedCarDisplay())return;
    if(sDFCarPlaySystemSleepID121) {
        if([sSession isEqualToString:sDFCarPlaySystemSleepSession121])return;
        DFCarPlayReleaseIdleSystem121();
    }
    if(!sDFCarPlayIOKit121)
        sDFCarPlayIOKit121=dlopen("/System/Library/Frameworks/IOKit.framework/IOKit",
                                  RTLD_LAZY|RTLD_LOCAL);
    if(!sDFCarPlayIOKit121) {
        DFTOLog(@"qa121-system-idle-assertion-unavailable",@"IOKit not loaded");
        return;
    }
    DFIOPMCreate121 acquire=(DFIOPMCreate121)dlsym(sDFCarPlayIOKit121,
                                                     "IOPMAssertionCreateWithName");
    sDFIOPMRelease121=(DFIOPMRelease121)dlsym(sDFCarPlayIOKit121,
                                                "IOPMAssertionRelease");
    if(!acquire || !sDFIOPMRelease121) {
        DFTOLog(@"qa121-system-idle-assertion-unavailable",
              @"IOPM create/release symbol missing");
        return;
    }
    uint32_t acquired=0;
    // PreventUserIdleSystemSleep retains system activity; unlike a display
    // sleep assertion it does NOT request screen brightness or disable lock.
    int32_t result=acquire(CFSTR("PreventUserIdleSystemSleep"),255,
                            CFSTR("DuoFace active CarPlay session"),&acquired);
    if(result==0 && acquired!=0) {
        sDFCarPlaySystemSleepID121=acquired;
        sDFCarPlaySystemSleepSession121=[sSession copy];
    }
    DFTOLog(result==0 && acquired?@"qa121-system-idle-assertion-acquired":
                                  @"qa121-system-idle-assertion-rejected",
           [NSString stringWithFormat:@"status=%d active=%d",result,
                                         result==0 && acquired!=0]);
}
// QA132: independent owner-scoped blank -> deferred unblank implementation.
// Proof inputs: exact original OmniCar ARM64 BKS(1), 1s guarded BKS(0);
// original DuoNavi and Native12 use conditional delayed restoration too.
// Apple's original blank request ALWAYS runs first. No touch replay, passcode
// bypass, brightness write or unconditional phone wake when CarPlay is absent.
typedef void (*DFScreenBlankFn132)(int);
typedef void (*DFHookFn132)(void *,void *,void **);
static DFScreenBlankFn132 sDFBKSOriginal132;
static BOOL sDFBKSInstalled132, sDFBKSUnblanked132, sDFBKSPending132;
static NSString *sDFBKSSession132;
static NSUInteger sDFBKSSerial132;
static void *sDFBKSFramework132;

static BOOL DFActiveHostedLockedPane132(void) {
    if(!NSThread.isMainThread || !sChrome || !sActivated || !sSession ||
       !DFSessionStillActive() || !DFConnectedCarDisplay())return NO;
    // A layout with 2 empty panes MUST NOT hold the iPhone display unblanked.
    NSDictionary *snapshot=[sChrome stateSnapshot];
    if(![snapshot[@"RunningScenes"] respondsToSelector:@selector(integerValue)] ||
       [snapshot[@"RunningScenes"] integerValue]<1 ||
       [snapshot[@"StartupActive"] boolValue])return NO;
    // Protected data is a read-only lock-phase observation, not an unlock.
    // If this signal is unavailable/false-positive on this iOS16 phone, this
    // experimental branch fails closed and QA132 can be rolled back.
    if(UIApplication.sharedApplication.protectedDataAvailable)return NO;
    return YES;
}
static void DFMaybeRestoreDisplay132(NSString *cause) {
    if(!sDFBKSInstalled132 || !sDFBKSOriginal132 ||
       sDFBKSUnblanked132 || sDFBKSPending132 ||
       !DFActiveHostedLockedPane132())return;
    const NSUInteger serial=sDFBKSSerial132;
    const NSUInteger generation=sGeneration;
    NSString *session=[sSession copy];
    sDFBKSPending132=YES;
    // Follow the original BKS(1) first. Recheck all owner evidence after delay.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.8*NSEC_PER_SEC)),
                   dispatch_get_main_queue(),^{
        if(serial!=sDFBKSSerial132 || generation!=sGeneration ||
           ![session isEqualToString:sSession] ||
           !DFActiveHostedLockedPane132()) {
            if(serial==sDFBKSSerial132)sDFBKSPending132=NO;
            return;
        }
        sDFBKSPending132=NO;
        sDFBKSOriginal132(0);
        sDFBKSUnblanked132=YES;
        sDFBKSSession132=[session copy];
        DFTOLog(@"qa132-bks-owned-unblank",
            [NSString stringWithFormat:@"cause=%@ running=%@ locked-data=1",
              cause,[sChrome stateSnapshot][@"RunningScenes"]]);
    });
}
static void DFOriginalScreenBlank132(int blanked) {
    DFScreenBlankFn132 original=sDFBKSOriginal132;
    if(!original)return;
    // All non-1 requests and all unrelated sessions get the original call.
    original(blanked);
    if(blanked!=1)return;
    // BKS runs on arbitrary queues. UIKit/pane/session checks are main-only.
    dispatch_async(dispatch_get_main_queue(),^{
        sDFBKSUnblanked132=NO;
        sDFBKSSession132=nil;
        DFMaybeRestoreDisplay132(@"system-blank");
    });
}
static void DFInstallScopedBlankPolicy132(void) {
    if(sDFBKSInstalled132)return;
    void *original=dlsym(RTLD_DEFAULT,"BKSDisplayServicesSetScreenBlanked");
    if(!original) {
        sDFBKSFramework132=dlopen(
            "/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices",
            RTLD_NOW|RTLD_LOCAL);
        if(sDFBKSFramework132)
            original=dlsym(sDFBKSFramework132,"BKSDisplayServicesSetScreenBlanked");
    }
    DFHookFn132 hook=(DFHookFn132)dlsym(RTLD_DEFAULT,"MSHookFunction");
    if(!original || !hook) {
        DFTOLog(@"qa132-bks-install-skipped",
                original?@"runtime-hook-provider-unavailable":
                         @"bks-export-unavailable");
        return;
    }
    void *trampoline=NULL;
    hook(original,(void *)DFOriginalScreenBlank132,&trampoline);
    if(!trampoline) {
        DFTOLog(@"qa132-bks-install-skipped",@"original-trampoline-null");
        return;
    }
    sDFBKSOriginal132=(DFScreenBlankFn132)trampoline;
    sDFBKSInstalled132=YES;
    DFTOLog(@"qa132-bks-interceptor-installed",
            @"original-first owned-pane protected-data-locked 0.8s unblank");
}
static void DFReleaseScopedBlankPolicy132(void) {
    // Cancel callbacks immediately before Home, reconnect or disconnect.
    ++sDFBKSSerial132;
    sDFBKSPending132=NO;
    if(sDFBKSUnblanked132 && sDFBKSOriginal132 &&
       sDFBKSSession132 && [sDFBKSSession132 isEqualToString:sSession] &&
       !UIApplication.sharedApplication.protectedDataAvailable) {
        // The old car-only restoration is no longer owned. Do not leave an
        // indefinite unblanked phone on true CarPlay Home/disconnect.
        sDFBKSOriginal132(1);
        DFTOLog(@"qa132-bks-restore-system-blank",@"locked-old-owner-revoked");
    }
    sDFBKSUnblanked132=NO;
    sDFBKSSession132=nil;
}
static void DFStopProbe(NSString *reason) {
    // Revoke the current generation BEFORE any potentially slow media-scene
    // teardown. Queued start/ACK commands can never revive a closed session.
    sGeneration++;
    DFReleaseScopedBlankPolicy132();
    DFCarPlayReleaseIdleSystem121();
    sNativeRail120WaitCount=0;
    // Exact old-session cleanup while its ID still exists. The CarPlay
    // process also has an independent heartbeat watchdog restoring the Dock.
    // On Home the old external overlays must disappear BEFORE any Dock
    // owner request or slow scene invalidation. Never touch native Dock.
    [sChrome hideAllExternalWindowsImmediately];
    DFDockZoomDetach(sChrome,sSession);
    sZoomReceipt=nil;sZoomFinishing=NO;
    NSString *previousSession=[sSession copy];
    sActivated=NO;
    sGeometrySample119=nil;sLaunchGeometry119=nil;
    sSession=nil;
    sLastAckSequence=0;
    sRetryCount=0;sRetryAt=0;
    DFNative12Chrome *old=sChrome;
    // Visible windows were concealed before Dock detach; only now capture
    // exact managed session PIDs while the scene hosts still exist.
    // Capture EXACT live, owner-verified new-process PIDs before stopAllHosts
    // invalidates the views. These are NOT the saved app favorites/workspace.
    if(old && previousSession)DFDisconnectCloseCapture(
        [old disconnectTerminationCandidates],previousSession);
    sChrome=nil;
    if(old){
        [old stop];
        DFTOLog(@"window-detached",reason);
    }
    DFEnsureDisconnectMonitor();
}
static BOOL DFSessionStillActive(void) {
    NSDictionary *pulse=[NSDictionary dictionaryWithContentsOfFile:kSessionFile];
    return sSession && [pulse[@"Session"] isEqualToString:sSession] &&
           DFOwnerAcceptPulse(pulse);
}
// Independent SpringBoard watchdog: works even if CarPlay app crashes,
// is suspended on Home, or fails to deliver a scene disconnect callback.
static void DFWatchdog(NSUInteger generation) {
    if(generation!=sGeneration || !sChrome || !sActivated)return;
    NSDictionary *pulse=[NSDictionary dictionaryWithContentsOfFile:kSessionFile];
    id stamp=pulse[@"Timestamp"];
    NSTimeInterval age=[stamp isKindOfClass:NSNumber.class]?
        NSDate.date.timeIntervalSince1970-[stamp doubleValue]:DBL_MAX;
    if(!DFOwnerAcceptPulse(pulse) ||
       ![pulse[@"Session"] isEqualToString:sSession]){
        DFTOLog(@"watchdog-detach",
           [NSString stringWithFormat:@"age=%.2f active=%@ session-match=%d",
            age,pulse[@"Active"],[pulse[@"Session"] isEqualToString:sSession]]);
        DFStopProbe(@"inactive-or-stale-heartbeat");
        return;
    }
    if(DFGFresh(pulse,NSDate.date.timeIntervalSince1970) &&
       ![sGeometrySample119 isEqual:pulse[@"GeometrySample"]]){
        sGeometrySample119=[pulse[@"GeometrySample"] copy];
        DFGWrite(pulse,@{@"LaunchGeometry":sLaunchGeometry119?:@{},
            @"CurrentPulseContentRect":pulse[@"ContentRect"]?:@"unavailable",
            @"PhysicalGeometry":[sChrome geometryReadback119]});
    }
    // Lock episode may start before the selected hosted scene exists. Retry
    // only after it actually exists; never touch an empty split layout.
    if(UIApplication.sharedApplication.protectedDataAvailable) {
        sDFBKSUnblanked132=NO;
        sDFBKSSession132=nil;
    } else DFMaybeRestoreDisplay132(@"locked-hosted-pane-watchdog");
    // Independent live SpringBoard geometry snapshot for *read-only*
    // cross-process native map pane alignment. A stale/revoked session fails closed.
    NSDictionary *physical=[sChrome stateSnapshot];
    NSArray *frames=physical[@"PhysicalWindowReadback"];
    if([physical[@"Owner"] isEqual:@"SpringBoard"] &&
       [physical[@"ActiveSlots"] isEqual:@2] &&
       [frames isKindOfClass:NSArray.class] && frames.count==2 &&
       [sSession isKindOfClass:NSString.class]){
       NSDictionary *record=@{@"Version":@1,@"Owner":@"SpringBoard",
          @"Session":sSession,@"Timestamp":@(NSDate.date.timeIntervalSince1970),
          @"ActiveSlots":@2,@"Focus":physical[@"Focus"]?:@(-2),
          @"Preset":physical[@"Preset"]?:@(-1),@"Windows":frames};
       if(![record writeToFile:@"/var/mobile/Library/Preferences/com.duoface.nativehost.physical-panes.v1.plist"
                        atomically:YES])
          DFTOLog(@"physical-map-window-snapshot-save-failed",@"");
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
        // EMERGENCY ROLLBACK .118: .117 passed CPWindow ContentRect x=0
        // directly to fullscreen appSceneWindows and user confirmed native
        // Apple Dock disappeared on physical connection. Restore EXACT
        // .116 verified-Dock-visible geometry behavior pending measured
        // CarPlay rootWindow.safeAreaInsets/active Dock owner audit.
        // This retains the known .116 black seam; NOT a seam correction.
        // CarPlay Dock owns the left rail. Even a mistaken client geometry
        // cannot place our touch windows in that area.
        CGFloat safeLeft=CGRectGetMinX(screen)+MAX(42,screen.size.width*.082);
        NSDictionary *nativeRail=[NSDictionary dictionaryWithContentsOfFile:kNativeRail120File];
        CGRect verifiedNativeContent=CGRectNull;
        BOOL nativeOwned=DFVerifiedNativeContent120(nativeRail,sSession,
                                                  discovery.screen,&verifiedNativeContent);
        if(!nativeOwned && sNativeRail120WaitCount<5) {
            // The native CarPlay process publishes measured geometry on its
            // 0.5s monitor. Wait briefly for the same active session before
            // making the one-time fallback choice. No external window exists yet.
            sNativeRail120WaitCount++;
            sActivated=NO;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(.20*NSEC_PER_SEC)),
                           dispatch_get_main_queue(),^{DFStartProbe();});
            return;
        }
        sNativeRail120WaitCount=0;
        if(nativeOwned && !CGRectIsNull(region) && !CGRectIsEmpty(region) &&
           region.origin.x<=CGRectGetMinX(verifiedNativeContent)+1.5 &&
           CGRectGetMaxX(region)>=CGRectGetMaxX(verifiedNativeContent)-1.5) {
            safeLeft=CGRectGetMinX(verifiedNativeContent);
            DFTOLog(@"qa120-native-usable-bounds-owned",
               [NSString stringWithFormat:@"system=%@ appPre=%@ left=%.3f",
                  NSStringFromCGRect(verifiedNativeContent),
                  NSStringFromCGRect(region),safeLeft]);
        }else{
            DFTOLog(@"qa120-safe-dock-fallback",
                 nativeOwned?@"CPWindow does not cover verified native content":
                             @"native Dock/root owner not verified in this session");
        }
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
        sLaunchGeometry119=@{@"Timestamp":@(NSDate.date.timeIntervalSince1970),
            @"PreClampContentRect":value?:@"unavailable",
            @"PostClampRegion":NSStringFromCGRect(region),
            @"ScreenBounds":NSStringFromCGRect(screen),@"DiscoveryWindow":DFGWindow(discovery)};
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
        if(sShownFirstSplashForPhysicalConnection){
            [sChrome skipStartupSplashForHomeReentry];
            DFTOLog(@"home-reentry-splash-skipped",@"same-physical-connection");
        }
        if(![sChrome start]) {
            DFStopProbe(@"chrome-window-create-failed");return;
        }
        sShownFirstSplashForPhysicalConnection=YES;
        if(!DFSessionStillActive()){
            DFStopProbe(@"session-revoked-during-window-start");return;
        }
        DFDisconnectCloseNewActiveSession();
        DFDisconnectCloseSetConnectionProbe(^BOOL{
            return DFConnectedCarDisplay()!=nil;
        });
        DFEnsureDisconnectMonitor();
        DFTOLog(@"native12-ui-owner-visible",
          [NSString stringWithFormat:@"windowCount=4 content=%@",
           NSStringFromCGRect(region)]);
        // Preserve system awake state ONLY for a verified active CarPlay
        // host; release immediately on Home/disconnect or watchdog teardown.
        DFCarPlayPreventIdleSystemSleep121();
        DFInstallScopedBlankPolicy132();
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
                (void)t;
                // A delayed old stop edge must not tear down a fresh new UUID.
                if(!DFSessionStillActive())DFStopProbe(@"nativehost-disconnected");
            });
            static int nativeRevokeToken=-1;
            notify_register_dispatch(DFOwnerRevokeNotify,&nativeRevokeToken,
                dispatch_get_main_queue(),^(int t) {
                    (void)t;
                    if(sSession && DFOwnerSessionRevoked(sSession))
                        DFStopProbe(@"native-home-button");
                });
            int ack=notify_register_dispatch(kAckNotify,&sAckToken,
                       dispatch_get_main_queue(),^(int t) {
                (void)t;DFReceiveAck();
            });
            static int sClosePolicyToken=-1;
            notify_register_dispatch("com.duoface.nativehost.disconnect-close.changed.v1",
               &sClosePolicyToken,dispatch_get_main_queue(),^(__unused int t){
                  DFDisconnectClosePolicyChanged();
               });
            // Physical notifications wake the same guarded monitor sooner,
            // but never use scene/Home deactivation as physical proof.
            for(NSString *name in @[UIScreenDidDisconnectNotification,
                                      UIScreenDidConnectNotification,
                                      @"CarPlayIsConnectedDidChange"]){
                [[NSNotificationCenter defaultCenter] addObserverForName:name
                   object:nil queue:NSOperationQueue.mainQueue
                   usingBlock:^(__unused NSNotification *note){
                      if(sChrome || DFDisconnectCloseNeedsMonitoring()){
                         DFDisconnectClosePhysicalObserved(DFConnectedCarDisplay()!=nil);
                         DFEnsureDisconnectMonitor();
                      }
                   }];
            }
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
