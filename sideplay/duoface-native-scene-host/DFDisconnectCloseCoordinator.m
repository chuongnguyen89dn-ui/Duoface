// DuoFace-owned teardown only. 10 second delay on real physical disconnect.
// The comparator is original DuoDash 1.1.3 arm64; no vendor implementation copied.
#import "DFDisconnectCloseCoordinator.h"
#import "DFDisconnectClosePolicy.h"
#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <signal.h>
#import <errno.h>
#import <unistd.h>
#import <fcntl.h>

static NSArray<NSDictionary *> *gCandidates;
static NSString *gSession;
static NSUInteger gGeneration;
static BOOL gHadPhysicalDisconnect;
static BOOL gScheduled;
static BOOL (^gProbe)(void);

static void DFDiscLog(NSString *event,NSString *detail) {
 NSString *line=[NSString stringWithFormat:
   @"[DuoFaceDisconnect] %@ %@\n",event?:@"event",detail?:@""];
 NSLog(@"%@",line);
 int fd=open("/var/mobile/Library/Logs/DuoFaceDisconnectClose.log",
            O_WRONLY|O_APPEND|O_CREAT,0644);
 if(fd>=0){NSData *data=[line dataUsingEncoding:NSUTF8StringEncoding];
   (void)write(fd,data.bytes,data.length);close(fd);}
}
static void DFDiscAck(NSString *status,NSUInteger attempted,NSUInteger verified) {
 // Exposes only counts/status to iPhone. No persistent PIDs or session IDs.
 NSDictionary *record=@{@"Version":@1,@"Status":status?:@"unknown",
   @"Attempted":@(attempted),@"VerifiedExited":@(verified),
   @"Timestamp":@(NSDate.date.timeIntervalSince1970)};
 (void)[record writeToFile:
  @"/var/mobile/Library/Preferences/com.duoface.nativehost.disconnect-close.ack.v1.plist"
       atomically:YES];
}
static id DFDiscCall0(id obj,NSString *name) {
 SEL sel=NSSelectorFromString(name);
 if(!obj||![obj respondsToSelector:sel])return nil;
 Method m=class_getInstanceMethod(object_getClass(obj),sel);
 if(!m)return nil;
 char output[8]={0};method_getReturnType(m,output,sizeof(output));
 if(output[0]!='@')return nil;
 @try{return ((id(*)(id,SEL))objc_msgSend)(obj,sel);}
 @catch(__unused NSException *exception){return nil;}
}
static NSNumber *DFDiscVerifiedCurrentPID(NSString *bundle) {
 if(![bundle isKindOfClass:NSString.class]||!bundle.length)return nil;
 Class appController=NSClassFromString(@"SBApplicationController");
 SEL shared=NSSelectorFromString(@"sharedInstance");
 if(![appController respondsToSelector:shared])return nil;
 id registry=((id(*)(id,SEL))objc_msgSend)(appController,shared);
 id app=nil;
 SEL lookup=NSSelectorFromString(@"applicationWithBundleIdentifier:");
 if(![registry respondsToSelector:lookup])return nil;
 app=((id(*)(id,SEL,id))objc_msgSend)(registry,lookup,bundle);
 if(![DFDiscCall0(app,@"bundleIdentifier") isEqual:bundle])return nil;
 for(NSString *n in @[@"pid",@"processIdentifier"]){
   SEL selector=NSSelectorFromString(n);
   if(![app respondsToSelector:selector])continue;
   Method method=class_getInstanceMethod(object_getClass(app),selector);
   if(!method)continue;
   char type[8]={0};method_getReturnType(method,type,sizeof(type));
   if(!strchr("iIqQsSlL",type[0]))continue;
   pid_t pid=((pid_t(*)(id,SEL))objc_msgSend)(app,selector);
   if(pid<=1||pid==getpid())continue;
   errno=0;
   if(kill(pid,0)==0 || errno==EPERM)return @(pid);
 }
 return nil;
}
static BOOL DFDiscPhoneForegroundIsSafeForClose(NSString *bundle) {
 // Return NO unless a trusted SpringBoard source can observe the PHONE frontmost
 // app and verify it is NOT the process targeted by the user policy.
 Class ctrl=NSClassFromString(@"SBUIController");
 SEL shared=NSSelectorFromString(@"sharedInstance");
 id owner=[ctrl respondsToSelector:shared]?
  ((id(*)(id,SEL))objc_msgSend)(ctrl,shared):nil;
 for(id target in @[owner?:NSNull.null,UIApplication.sharedApplication?:NSNull.null]){
   if(target==NSNull.null)continue;
   for(NSString *method in @[@"activeApplication",@"_accessibilityFrontMostApplication"]){
      SEL selector=NSSelectorFromString(method);
      if(![target respondsToSelector:selector])continue;
      id app=DFDiscCall0(target,method);
      if(!app)continue; // nil could mean unknown, not safely Home.
      NSString *actual=[app isKindOfClass:NSString.class]?app:DFDiscCall0(app,@"bundleIdentifier");
      if(![actual isKindOfClass:NSString.class])continue;
      return ![actual isEqualToString:bundle];
   }
 }
 return NO;
}
static BOOL DFDiscRequestTermination(NSString *bundle,NSString **reason){
 // RunningBoardServices private API is probed at runtime, no signal-kill.
 // A request return is NEVER proof of app process exit.
 dlopen("/System/Library/PrivateFrameworks/RunningBoardServices.framework/RunningBoardServices",RTLD_LAZY);
 Class pred=NSClassFromString(@"RBSProcessPredicate");
 Class ctx=NSClassFromString(@"RBSTerminateContext");
 Class req=NSClassFromString(@"RBSTerminateRequest");
 SEL make=NSSelectorFromString(@"predicateMatchingBundleIdentifier:");
 SEL explanation=NSSelectorFromString(@"initWithExplanation:");
 SEL init=NSSelectorFromString(@"initWithPredicate:context:");
 SEL execute=NSSelectorFromString(@"execute:error:");
 if(!pred||!ctx||!req||![pred respondsToSelector:make]||
    ![ctx instancesRespondToSelector:explanation] ||
    ![req instancesRespondToSelector:init] ||
    ![req instancesRespondToSelector:execute]){
   if(reason)*reason=@"runningboard-selector-missing";return NO;
 }
 Method m=class_getInstanceMethod(req,execute);
 if(!m||method_getNumberOfArguments(m)!=4){
   if(reason)*reason=@"runningboard-abi-unsupported";return NO;
 }
 @try{
   id predicate=((id(*)(id,SEL,id))objc_msgSend)(pred,make,bundle);
   id context=((id(*)(id,SEL,id))objc_msgSend)(
                   [ctx alloc],explanation,@"DuoFace user-enabled CarPlay physical disconnect");
   id request=((id(*)(id,SEL,id,id))objc_msgSend)([req alloc],init,predicate,context);
   if(!predicate||!context||!request){
      if(reason)*reason=@"runningboard-request-construction-failed";return NO;
   }
   NSError *error=nil;id response=nil;
   ((void(*)(id,SEL,id *,NSError **))objc_msgSend)(request,execute,&response,&error);
   if(error){if(reason)*reason=error.domain?:@"runningboard-error";return NO;}
   return YES;
 }@catch(__unused NSException *e){
   if(reason)*reason=@"runningboard-exception";return NO;
 }
}
static void DFDiscCancel(NSString *reason,BOOL clear) {
 ++gGeneration;gScheduled=NO;gHadPhysicalDisconnect=NO;
 if(clear){gCandidates=nil;gSession=nil;}
 DFDiscLog(@"cancel",reason);
 DFDiscAck(reason?:@"cancelled",0,0);
}
void DFDisconnectCloseSetConnectionProbe(BOOL (^probe)(void)){
 gProbe=[probe copy];
}
void DFDisconnectCloseNewActiveSession(void){
 DFDiscCancel(@"new-verified-carplay-session",YES);
}
void DFDisconnectCloseCapture(NSArray<NSDictionary *> *candidates,NSString *session) {
 if(!DFDisconnectCloseEnabled() || gCandidates.count ||
    ![session isKindOfClass:NSString.class] ||
    ![[NSUUID alloc]initWithUUIDString:session])return;
 NSMutableArray *accepted=[NSMutableArray new];
 NSMutableSet *ids=[NSMutableSet new];
 for(id item in candidates){
  if(![item isKindOfClass:NSDictionary.class])continue;
  NSString *bundle=item[@"BundleID"];
  NSNumber *pid=item[@"PID"];
  if(![bundle isKindOfClass:NSString.class]||!bundle.length||bundle.length>180||
     ![pid isKindOfClass:NSNumber.class]||pid.intValue<=1 ||
     [ids containsObject:bundle] ||
     [bundle hasPrefix:@"com.apple."] ||
     [bundle hasPrefix:@"com.duoface."])continue;
  [ids addObject:bundle];[accepted addObject:@{@"BundleID":bundle,@"PID":pid}];
 }
 if(!accepted.count)return;
 gCandidates=[accepted copy];gSession=[session copy];
 DFDiscLog(@"captured-owned-new-processes",[NSString stringWithFormat:@"count=%lu",(unsigned long)accepted.count]);
 DFDiscAck(@"candidates-captured-awaiting-physical-disconnect",0,0);
}
BOOL DFDisconnectCloseNeedsMonitoring(void) {return gCandidates.count>0;}
void DFDisconnectClosePolicyChanged(void) {
 if(!DFDisconnectCloseEnabled() && (gScheduled || gCandidates.count))
    DFDiscCancel(@"setting-disabled-before-close",YES);
}
void DFDisconnectClosePhysicalObserved(BOOL connected) {
 if(!gCandidates.count)return;
 if(connected) {
    if(gHadPhysicalDisconnect)DFDiscCancel(@"physical-reconnected-cancel-grace",YES);
    return; // CarPlay Home alone is NOT physical disconnect.
 }
 if(gScheduled||gHadPhysicalDisconnect)return;
 gHadPhysicalDisconnect=YES;
 if(!DFDisconnectCloseEnabled()){
    DFDiscCancel(@"disconnect-setting-off",YES);return;
 }
 gScheduled=YES;
 const NSUInteger generation=++gGeneration;
 const NSTimeInterval scheduledAt=NSDate.date.timeIntervalSince1970;
 NSArray *items=[gCandidates copy];NSString *session=[gSession copy];
 DFDiscLog(@"scheduled",[NSString stringWithFormat:@"delay=10s owned=%lu",(unsigned long)items.count]);
 DFDiscAck(@"grace-period-10-seconds",0,0);
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(DFDisconnectCloseGrace*NSEC_PER_SEC)),
                dispatch_get_main_queue(),^{
  BOOL stillDisconnected=(gProbe && !gProbe());
  if(!DFDisconnectCloseMayExecute(generation,gGeneration,stillDisconnected,
                   DFDisconnectCloseEnabled(),NSDate.date.timeIntervalSince1970-scheduledAt) ||
     ![session isEqualToString:gSession]){
    DFDiscCancel(@"grace-cancelled-reconnected-disabled-or-stale",YES);return;
  }
  gScheduled=NO;
  gCandidates=nil;gSession=nil; // one-shot; cannot act on another session
  NSUInteger requested=0,verified=0;
  for(NSDictionary *item in items){
    NSString *bundle=item[@"BundleID"];
    NSNumber *before=item[@"PID"];
    NSNumber *now=DFDiscVerifiedCurrentPID(bundle);
    if(!now || ![now isEqual:before]){
       DFDiscLog(@"skipped-pid-changed",bundle);continue;
    }
    if(!DFDiscPhoneForegroundIsSafeForClose(bundle)){
       DFDiscLog(@"skipped-foreground-unverified",bundle);continue;
    }
    // Revalidate disconnect and policy immediately before every request.
    if(!gProbe || gProbe() || !DFDisconnectCloseEnabled())break;
    // RunningBoard may block crossing OS processes; never block SpringBoard UI.
    requested++;
    pid_t original=before.intValue;
    NSUInteger sent=requested;
    NSString *ownedBundle=[bundle copy];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
       // Closing an app is destructive: the worker can start AFTER a fast
       // CarPlay reconnect even when its original 10s timer was valid.
       // Every worker must recheck session generation, physical connection,
       // same verified PID and phone foreground on the SpringBoard main queue.
       __block BOOL stillEligible=NO;
       dispatch_sync(dispatch_get_main_queue(),^{
          stillEligible=(generation==gGeneration && gProbe && !gProbe() &&
              DFDisconnectCloseEnabled() &&
              [DFDiscVerifiedCurrentPID(ownedBundle) isEqual:before] &&
              DFDiscPhoneForegroundIsSafeForClose(ownedBundle));
       });
       if(!stillEligible){
          DFDiscLog(@"worker-stale-reconnected-or-pid-changed",ownedBundle);
          return;
       }
       NSString *reason=nil;
       BOOL accepted=DFDiscRequestTermination(ownedBundle,&reason);
       dispatch_async(dispatch_get_main_queue(),^{
          if(generation!=gGeneration || !gProbe || gProbe()){
             DFDiscLog(@"worker-response-ignored-after-reconnect",ownedBundle);
             return; // Never overwrite the new active session's ACK.
          }
          if(!accepted){
             DFDiscLog(@"terminate-request-rejected",
               [NSString stringWithFormat:@"%@ %@",ownedBundle,reason?:@"unknown"]);
             DFDiscAck(@"runningboard-request-rejected",sent,0);
             return;
          }
          DFDiscLog(@"terminate-requested",ownedBundle);
          __block NSUInteger count=0;
          [NSTimer scheduledTimerWithTimeInterval:.4 repeats:YES
            block:^(NSTimer *t){
               count++;
               NSNumber *current=DFDiscVerifiedCurrentPID(ownedBundle);
               errno=0;
               BOOL oldExited=(kill(original,0)!=0 && errno==ESRCH);
               if(oldExited){
                  [t invalidate];
                  DFDiscLog(@"verified-process-exited",ownedBundle);
                  DFDiscAck(current?@"old-pid-exited-app-restarted":
                                     @"verified-process-exited",sent,1);
               }else if(count>=10){
                  [t invalidate];
                  DFDiscLog(@"termination-unconfirmed-pid-still-alive",ownedBundle);
                  DFDiscAck(@"process-still-running",sent,0);
               }
            }];
       });
    });
  }
  (void)verified;
  DFDiscAck(requested?@"termination-workers-dispatched-not-yet-confirmed":
                     @"no-eligible-owned-process",requested,0);
 });
}
