// iOS16 independent passive CarPlay observer: reads state, never hooks policy.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dispatch/dispatch.h>
#import <fcntl.h>
#import <unistd.h>
static NSString *dnFile,*dnProcess,*dnPreviousABI;
static NSDictionary *dnPreviousState;
static NSTimeInterval dnLastTime;
static dispatch_queue_t dnQueue;
static void DNLog(NSString *event,NSDictionary *fields) {
 if(!dnFile||!dnQueue)return;
 NSMutableDictionary *d=[NSMutableDictionary dictionaryWithDictionary:fields?:@{}];
 d[@"utc"]=@([NSDate.date timeIntervalSince1970]);
 d[@"event"]=event;d[@"process"]=dnProcess?:@"unknown";
 d[@"pid"]=@([NSProcessInfo processInfo].processIdentifier);
 NSData *json=[NSJSONSerialization dataWithJSONObject:d options:0 error:nil];
 if(!json)return;
 dispatch_async(dnQueue,^{
  NSFileManager *fm=NSFileManager.defaultManager;
  [fm createDirectoryAtPath:@"/var/mobile/Library/Logs" withIntermediateDirectories:YES attributes:nil error:nil];
  unsigned long long bytes=[[fm attributesOfItemAtPath:dnFile error:nil][NSFileSize] unsignedLongLongValue];
  if(bytes>2097152) {
   NSString *prev=[dnFile stringByAppendingString:@".previous"];
   [fm removeItemAtPath:prev error:nil];[fm moveItemAtPath:dnFile toPath:prev error:nil];
  }
  int fd=open(dnFile.fileSystemRepresentation,O_WRONLY|O_CREAT|O_APPEND,0644);
  if(fd<0)return;
  (void)write(fd,json.bytes,json.length);(void)write(fd,"\n",1);(void)close(fd);
 });
}
#import "NativeDockABI.h"
static NSDictionary *DNState(void) {
 NSMutableArray *displays=[NSMutableArray array];
 for(UIScreen *s in UIScreen.screens)if(s!=UIScreen.mainScreen)
  [displays addObject:@{@"width":@(s.bounds.size.width),@"height":@(s.bounds.size.height),@"scale":@(s.scale)}];
 UIApplication *a=UIApplication.sharedApplication;
 NSInteger active=0,inactive=0,background=0;
 for(UIScene *s in a.connectedScenes){
  if(s.activationState==UISceneActivationStateForegroundActive)active++;
  else if(s.activationState==UISceneActivationStateForegroundInactive)inactive++;
  else if(s.activationState==UISceneActivationStateBackground)background++;
 }
 return @{@"external_displays":displays,@"own_scene_active":@(active),
   @"own_scene_inactive":@(inactive),@"own_scene_background":@(background),
   @"app_state":@(a.applicationState),@"protected_data":@(a.protectedDataAvailable)};
}
static void DNCheckABI(void) {
 Class cls=NSClassFromString(@"SBSuspendedUnderLockManager");
 NSMutableDictionary *methods=[NSMutableDictionary dictionary];
 for(NSString *name in @[@"interceptUpdateForScene:withNewSettings:",
   @"_shouldBeBackgroundUnderLockForScene:withSettings:",
   @"shouldBeUnderLockForScene:"]) {
  SEL sel=NSSelectorFromString(name);
  Method im=cls?class_getInstanceMethod(cls,sel):NULL;
  Method cm=cls?class_getClassMethod(cls,sel):NULL;
  const char *i=im?method_getTypeEncoding(im):NULL;
  const char *c=cm?method_getTypeEncoding(cm):NULL;
  methods[name]=@{@"instance_exists":@(im!=NULL),@"class_exists":@(cm!=NULL),
    @"instance_arg_count":@(im?method_getNumberOfArguments(im):0),
    @"instance_encoding":i?[NSString stringWithUTF8String:i]:@"missing",
    @"class_encoding":c?[NSString stringWithUTF8String:c]:@"missing"};
 }
 NSDictionary *d=@{@"manager_class_exists":@(cls!=Nil),@"methods":methods};
 NSData *bytes=[NSJSONSerialization dataWithJSONObject:d options:NSJSONWritingSortedKeys error:nil];
 NSString *fingerprint=[[NSString alloc] initWithData:bytes encoding:NSUTF8StringEncoding];
 if(![fingerprint isEqualToString:dnPreviousABI]){
  dnPreviousABI=fingerprint;
  DNLog(@"underlock_method_abi_read_only",d);
 }
}
static void DNSample(void) {
 DNNativeDockSample();
 NSDictionary *d=DNState();
 NSTimeInterval now=NSDate.date.timeIntervalSince1970;
 if(![d isEqualToDictionary:dnPreviousState]||now-dnLastTime>=12) {
  DNLog(@"ui_state_sample",d);dnPreviousState=d;dnLastTime=now;
 }
 if([dnProcess isEqualToString:@"SpringBoard"])DNCheckABI();
}
static void DNStart(void) {
 DNLog(@"observer_started",@{@"mode":@"read-only-no-hook"});
 NSArray *events=@[UIScreenDidConnectNotification,UIScreenDidDisconnectNotification,
  UIApplicationDidBecomeActiveNotification,UIApplicationWillResignActiveNotification,
  UIApplicationDidEnterBackgroundNotification,UIApplicationWillEnterForegroundNotification,
  UIApplicationProtectedDataWillBecomeUnavailable,UIApplicationProtectedDataDidBecomeAvailable,
  UISceneDidActivateNotification,UISceneWillDeactivateNotification,
  UISceneDidEnterBackgroundNotification,UISceneWillEnterForegroundNotification];
 for(NSString *event in events){
  [[NSNotificationCenter defaultCenter] addObserverForName:event object:nil
    queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
     (void)note;
     DNLog(@"uikit_notification",@{@"name":event,@"state":DNState()});
  }];
 }
 DNSample();
 static dispatch_source_t timer;
 timer=dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_get_main_queue());
 dispatch_source_set_timer(timer,dispatch_time(DISPATCH_TIME_NOW,3*NSEC_PER_SEC),
    3*NSEC_PER_SEC,500*NSEC_PER_MSEC);
 dispatch_source_set_event_handler(timer,^{DNSample();});
 dispatch_resume(timer);
}
__attribute__((constructor))static void DNLoad(void) {
 @autoreleasepool {
  dnProcess=NSProcessInfo.processInfo.processName;
  if(![@[@"SpringBoard",@"CarPlay",@"CarPlayApp"] containsObject:dnProcess])return;
  dnFile=[@"/var/mobile/Library/Logs" stringByAppendingPathComponent:
     [NSString stringWithFormat:@"DuoNaviObserver-%@.jsonl",dnProcess]];
  dnQueue=dispatch_queue_create("com.duoface.duonaviobserver.log",DISPATCH_QUEUE_SERIAL);
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW,2*NSEC_PER_SEC),
     dispatch_get_main_queue(),^{DNStart();});
 }
}
