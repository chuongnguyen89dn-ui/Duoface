// macOS real cross-process Darwin test of the shipping protocol header.
// Does not establish sandbox permission/scene acceptance on physical iOS.
#import "../DF154AppStateProtocol.h"
#import <assert.h>
static NSString *const bundle=@"org.videolan.vlc-ios";
static NSString *request;
static NSDictionary *Lease(BOOL active) {
 return @{@"version":@1,@"bundleIdentifier":bundle,@"requestID":request,
   @"owner":@"runtime-test-owner",@"sceneIdentifier":@"runtime-test-scene",
   @"issuedAt":@(NSDate.date.timeIntervalSince1970),@"active":@(active),
   @"width":@(active?800:0),@"height":@(active?480:0)};
}
int main(int argc,const char *argv[]) {
 @autoreleasepool {
  request=argc>2?[NSString stringWithUTF8String:argv[2]]:NSUUID.UUID.UUIDString;
  assert(DF154Valid(Lease(YES),NSDate.date.timeIntervalSince1970));
  NSMutableDictionary *bad=[Lease(YES) mutableCopy];bad[@"issuedAt"]=@0;
  assert(!DF154Valid(bad,NSDate.date.timeIntervalSince1970));
  bad=[Lease(YES) mutableCopy];bad[@"sceneIdentifier"]=@"";
  assert(!DF154Valid(bad,NSDate.date.timeIntervalSince1970));
  bad=[Lease(YES) mutableCopy];bad[@"width"]=@(-1);
  assert(!DF154Valid(bad,NSDate.date.timeIntervalSince1970));
  __block BOOL done=NO,accepted=NO,restored=NO;
  if(argc>1 && !strcmp(argv[1],"child")) {
   assert(DF156Listen(bundle,NO,^(NSDictionary *s){
     if(!DF154Valid(s,NSDate.date.timeIntervalSince1970) ||
        ![s[@"requestID"] isEqual:request] ||
        ![s[@"owner"] isEqual:@"runtime-test-owner"] ||
        ![s[@"sceneIdentifier"] isEqual:@"runtime-test-scene"])return;
     BOOL active=[s[@"active"] boolValue];
     NSMutableDictionary *ack=[s mutableCopy];ack[@"phase"]=active?@"scene-matched":@"restored";
     ack[@"issuedAt"]=@(NSDate.date.timeIntervalSince1970);
     DF155PostAck(ack);
     if(!active)dispatch_after(dispatch_time(DISPATCH_TIME_NOW,250*NSEC_PER_MSEC),dispatch_get_main_queue(),^{done=YES;});
   }));
  } else {
   assert(DF156Listen(bundle,YES,^(NSDictionary *s){
     if(![s[@"requestID"] isEqual:request] ||
        ![s[@"owner"] isEqual:@"runtime-test-owner"] ||
        ![s[@"sceneIdentifier"] isEqual:@"runtime-test-scene"])return;
     if([s[@"phase"] isEqual:@"scene-matched"])accepted=YES;
     if([s[@"phase"] isEqual:@"restored"])restored=done=YES;
   }));
   NSTask *child=[NSTask new];child.executableURL=[NSURL fileURLWithPath:
       NSProcessInfo.processInfo.arguments[0]];child.arguments=@[@"child",request];
   assert([child launchAndReturnError:nil]);
   NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:8];
   while(!done && deadline.timeIntervalSinceNow>0) {
     DF154Post(Lease(!accepted));
     [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
   }
   if(child.running)[child terminate];
   [child waitUntilExit];
   assert(accepted && restored);
   puts("DF156_REAL_DARWIN_CROSS_PROCESS_STATE_ACK_REVOKE_PASS_MACOS_ONLY");
   return 0;
  }
  NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:8];
  while(!done && deadline.timeIntervalSinceNow>0)
   [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
  return done?0:1;
 }
}
