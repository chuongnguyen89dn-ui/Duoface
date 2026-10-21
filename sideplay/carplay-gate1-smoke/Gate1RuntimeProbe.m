// Independent read-only one-shot runtime audit. No CarPlay mutations.
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <unistd.h>
extern BOOL DFGate1CarPlayHooksReady(void);
extern BOOL DFGate1SpringBoardHooksReady(void);
static NSString *const own=@"com.duoface.gate1smoke";
static NSString *const req=@"/var/mobile/Library/Preferences/com.duoface.gate1smoke.diag-request.plist";
static NSString *const pref=@"/var/mobile/Library/Preferences/com.duoface.gate1smoke.plist";
static NSString *const kill=@"/var/mobile/Library/Preferences/.duoface-gate1smoke-disable";
static NSString *previous=nil;
static NSString *ABI(Class c,SEL s,BOOL cls){
 Method m=c?(cls?class_getClassMethod(c,s):class_getInstanceMethod(c,s)):NULL;
 const char *e=m?method_getTypeEncoding(m):NULL;
 return e?[NSString stringWithUTF8String:e]:@"UNAVAILABLE";
}
static NSString *LSLookup(NSMutableDictionary *r){
 Class c=NSClassFromString(@"LSApplicationProxy");
 SEL s=sel_registerName("applicationProxyForIdentifier:");
 NSString *a=ABI(c,s,YES);r[@"LSLookupABI"]=a;
 if(![a isEqualToString:@"@24@0:8@16"])return @"ABI_UNAVAILABLE";
 @try{
  id proxy=((id(*)(id,SEL,id))objc_msgSend)(c,s,own);
  if(!proxy)return @"APP_NOT_IN_LS";
  SEL idsel=sel_registerName("bundleIdentifier");
  if(![proxy respondsToSelector:idsel])return @"ID_SELECTOR_MISSING";
  id name=((id(*)(id,SEL))objc_msgSend)(proxy,idsel);
  return [name isKindOfClass:NSString.class]&&[name isEqualToString:own]?
         @"OWN_APP_IN_LS":@"WRONG_APP";
 }@catch(NSException *e){return [@"EXCEPTION_" stringByAppendingString:e.name];}
}
static NSString *RosterLookup(NSMutableDictionary *r){
 Class c=NSClassFromString(@"DBApplicationController");
 r[@"DBControllerLoaded"]=@(c!=Nil);
 if(!c)return @"DB_CLASS_NOT_LOADED";
 SEL shared=sel_registerName("sharedInstance");
 SEL get=sel_registerName("applicationWithBundleIdentifier:");
 NSString *a=ABI(c,shared,YES),*b=ABI(c,get,NO);
 r[@"DBSharedABI"]=a;r[@"DBLookupABI"]=b;
 if(![a isEqualToString:@"@16@0:8"]||![b isEqualToString:@"@24@0:8@16"])
  return @"DB_ABI_NOT_VERIFIED";
 @try {
   id ctl=((id(*)(id,SEL))objc_msgSend)(c,shared);
   if(!ctl||![ctl respondsToSelector:get])return @"DB_CONTROLLER_NOT_AVAILABLE";
   id app=((id(*)(id,SEL,id))objc_msgSend)(ctl,get,own);
   return app?@"OWN_APP_IN_DASHBOARD_ROSTER":@"OWN_APP_MISSING_FROM_ROSTER";
 }@catch(NSException *e){return [@"EXCEPTION_" stringByAppendingString:e.name];}
}
static void Inspect(void){
 NSString *process=NSProcessInfo.processInfo.processName;
 BOOL car=[process isEqualToString:@"CarPlay"],sb=[process isEqualToString:@"SpringBoard"];
 if((!car&&!sb)||NSProcessInfo.processInfo.operatingSystemVersion.majorVersion!=16)return;
 if(access(kill.fileSystemRepresentation,F_OK)==0)return;
 NSDictionary *p=[NSDictionary dictionaryWithContentsOfFile:pref];
 if(![p[@"Enabled"] boolValue]||![p[@"RiskAcknowledged"] boolValue]||
    ![p[@"HostBundleID"] isEqualToString:own])return;
 NSDictionary *q=[NSDictionary dictionaryWithContentsOfFile:req];
 NSString *nonce=q[@"RequestID"];
 if(![q[@"Enabled"] boolValue]||![q[@"AuditOnly"] boolValue]||
    ![q[@"HostBundleID"] isEqualToString:own]||
    ![nonce isKindOfClass:NSString.class]||
    ![[NSUUID alloc] initWithUUIDString:nonce]||
    ![q[@"RequestedAt"] isKindOfClass:NSNumber.class]||
    [previous isEqualToString:nonce])return;
 NSTimeInterval age=NSDate.date.timeIntervalSince1970-[q[@"RequestedAt"] doubleValue];
 if(age<0||age>45)return;
 previous=[nonce copy];
 NSMutableDictionary *r=[@{@"Process":process,@"RequestID":nonce,@"AuditOnly":@YES,
    @"Timestamp":@(NSDate.date.timeIntervalSince1970),@"Target":own,
    @"HookReady":@(car?DFGate1CarPlayHooksReady():DFGate1SpringBoardHooksReady()),
    @"CarPlayHomeVerified":@NO,@"UIKitCarSceneVerified":@NO} mutableCopy];
 Class bundle=NSClassFromString(@"LSBundleProxy");
 r[@"LSABI3"]=ABI(bundle,sel_registerName("entitlementValueForKey:ofClass:valuesOfClass:"),NO);
 r[@"LSABI2"]=ABI(bundle,sel_registerName("entitlementValueForKey:ofClass:"),NO);
 r[@"CachedBoolABI"]=ABI(NSClassFromString(@"LSBundleInfoCachedValues"),sel_registerName("boolForKey:"),NO);
 r[@"LSOwn"]=LSLookup(r);
 r[@"DashBoardLoaded"]=@(NSClassFromString(@"DashBoard")!=Nil);
 if(car){
   Class dash=NSClassFromString(@"DashBoard");
   r[@"InclusionABI"]=ABI(dash,sel_registerName("_proxyPassesInclusionFilter:"),YES);
   r[@"DashFactoryABI"]=ABI(dash,sel_registerName("_newApplicationLibrary"),YES);
   r[@"Roster"]=RosterLookup(r);
   r[@"IconLayout"]=@"NOT_PROBED_WITHOUT_VERIFIED_VEHICLE";
 }else r[@"Roster"]=@"CARPLAY_PROCESS_ONLY";
 NSString *file=car?@"/var/mobile/Library/Preferences/com.duoface.gate1smoke.diag-carplay.plist":
   @"/var/mobile/Library/Preferences/com.duoface.gate1smoke.diag-springboard.plist";
 BOOL ok=[r writeToFile:file atomically:YES];
 NSLog(@"[Gate1Diag] process=%@ nonce=%@ hook=%d LS=%@ roster=%@ saved=%d",
   process,nonce,[r[@"HookReady"] boolValue],r[@"LSOwn"],r[@"Roster"],ok);
}
static void Callback(CFNotificationCenterRef c,void *o,CFStringRef n,const void *obj,CFDictionaryRef data){
 (void)c;(void)o;(void)n;(void)obj;(void)data;
 dispatch_async(dispatch_get_main_queue(), ^{Inspect();});
}
__attribute__((constructor))static void InstallListener(void){
 @autoreleasepool{
   NSString *p=NSProcessInfo.processInfo.processName;
   if(![p isEqualToString:@"CarPlay"]&&![p isEqualToString:@"SpringBoard"])return;
   CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
      NULL,Callback,CFSTR("com.duoface.gate1smoke.diag-run"),NULL,
      CFNotificationSuspensionBehaviorDeliverImmediately);
 }
}
