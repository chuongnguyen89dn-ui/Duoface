// Independent read-only, one-shot ABI inventory for DuoFace iOS16.
// Default ABI inventory; optional validated request reads ONLY two own-bundle
// original getter return classes. No hooks, cached-value substitution,
// LS database writes, scene activation, Dock change, restart or respring.
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <fcntl.h>
#import <unistd.h>
#import <math.h>

static NSString *const DFRequestPath=@"/var/mobile/Library/Preferences/com.duoface.sb-admission-probe.request.plist";
static NSString *const DFStatusPath=@"/var/mobile/Library/Preferences/com.duoface.sb-admission-probe.status.plist";
static NSString *const DFLogPath=@"/var/mobile/Library/Logs/DuoFaceSBAdmissionProbe.log";
static CFStringRef const DFSignal=CFSTR("com.duoface.nativejoin.sborder.probe");
static BOOL DFTryScan=NO;

static void DFLog(NSString *message) {
    NSString *line=[NSString stringWithFormat:@"[DuoFaceSBAdmission] %@\n",message];
    NSLog(@"%@",line);
    int fd=open(DFLogPath.fileSystemRepresentation,O_CREAT|O_APPEND|O_WRONLY,0644);
    if(fd>=0) {
        NSData *data=[line dataUsingEncoding:NSUTF8StringEncoding];
        if(data.length) (void)write(fd,data.bytes,data.length);
        close(fd);
    }
}
static NSString *DFEncoding(Class cls,SEL sel,BOOL classMethod) {
    if(!cls)return @"class-unavailable";
    Method m=classMethod?class_getClassMethod(cls,sel):class_getInstanceMethod(cls,sel);
    if(!m)return @"selector-unavailable";
    const char *enc=method_getTypeEncoding(m);
    return enc?[NSString stringWithUTF8String:enc]:@"encoding-unavailable";
}
static NSString *DFClassName(Class cls) {
    return cls?NSStringFromClass(cls):@"class-unavailable";
}
static void DFFinish(NSString *state,NSString *details,NSString *requestID) {
    NSMutableDictionary *status=[NSMutableDictionary dictionaryWithDictionary:@{
        @"Version":@1,@"Kind":@"springboard-admission-readonly",
        @"State":state,@"Timestamp":@(NSDate.date.timeIntervalSince1970),
        @"RequestID":requestID?:@"", @"Process":@"SpringBoard",
        @"Summary":details?:@""
    }];
    BOOL wrote=[status writeToFile:DFStatusPath atomically:YES];
    DFLog([NSString stringWithFormat:@"result state=%@ statusWritten=%d request=%@ %@",
        state,wrote,requestID?:@"-",details?:@""]);
}

// Runs ONLY after the existing one-shot request has been validated and disarmed.
// Reads a single own-bundle proxy, original selectors only; no hooks or LS writes.
static NSString *DFTargetReadOnlySummary(void) {
    Class app=NSClassFromString(@"LSApplicationProxy");
    SEL lookup=sel_registerName("applicationProxyForIdentifier:");
    NSString *abi=DFEncoding(app,lookup,YES);
    if(![abi isEqualToString:@"@24@0:8@16"])return [NSString stringWithFormat:@"target-skipped lookup-ABI=%@",abi];
    Method m=class_getClassMethod(app,lookup);
    if(!m)return @"target-skipped class-selector-unavailable";
    id proxy=((id(*)(id,SEL,id))method_getImplementation(m))(app,lookup,@"com.duoface.native.scenehost");
    if(!proxy)return @"target-absent SpringBoard LSApplicationProxy";
    SEL bid=sel_registerName("bundleIdentifier");
    if(![proxy respondsToSelector:bid])return @"target-skipped missing bundleIdentifier";
    id actual=((id(*)(id,SEL))objc_msgSend)(proxy,bid);
    if(![actual isKindOfClass:NSString.class] ||
       ![actual isEqualToString:@"com.duoface.native.scenehost"])
       return @"target-skipped wrong bundleID";
    NSString *typedABI=DFEncoding([proxy class],
          sel_registerName("entitlementValueForKey:ofClass:valuesOfClass:"),NO);
    if(![typedABI isEqualToString:@"@40@0:8@16#24#32"])
      return [NSString stringWithFormat:@"target-found typed3-ABI=%@ NO PRIVATE GETTER CALLED",typedABI];
    SEL selector=sel_registerName("entitlementValueForKey:ofClass:valuesOfClass:");
    Method getter=class_getInstanceMethod([proxy class],selector);
    if(!getter)return @"target-found getter-missing";
    IMP original=method_getImplementation(getter);
    if(!original)return @"target-found getter-IMP-missing";
    NSMutableArray *results=[NSMutableArray array];
    for(NSString *key in @[@"CARCapableApp",@"SBStarkCapable"]) {
        id value=((id(*)(id,SEL,id,Class,Class))original)(
           proxy,selector,key,NSNumber.class,NSNumber.class);
        [results addObject:[NSString stringWithFormat:@"%@=%@",key,
          value?NSStringFromClass([value class]):@"nil"]];
    }
    return [NSString stringWithFormat:
       @"target-found process=SpringBoard pid=%d wall=%.3f uptime=%.3f typed3ABI=%@ classes=%@ cached-values-origin=UNKNOWN (not Dashboard membership)",
       getpid(),NSDate.date.timeIntervalSince1970,NSProcessInfo.processInfo.systemUptime,
       typedABI,[results componentsJoinedByString:@","]];
}
static void DFReadOnlyInventory(NSString *requestID) {
    Class fbs=NSClassFromString(@"FBSApplicationInfo");
    Class cached=NSClassFromString(@"LSBundleInfoCachedValues");
    Class proxy=NSClassFromString(@"LSBundleProxy");
    Class appProxy=NSClassFromString(@"LSApplicationProxy");
    Class carApp=NSClassFromString(@"CARApplication");
    Class dbWorkspace=NSClassFromString(@"DBWorkspace");
    // Base inventory reads method encodings. Only an optional one-shot target
    // request invokes the two original getters after ABI and bundle checks.
    NSString *details=[NSString stringWithFormat:
       @"FBSApplicationInfo=%@ fbBulk=%@ "
        @"LSBundleInfoCachedValues=%@ boolForKey=%@ objectForKey=%@ numberForKey=%@ "
        @"LSBundleProxy=%@ typed3=%@ typed2=%@ bulk=%@ infoKey=%@ "
        @"LSApplicationProxy=%@ byBundle=%@ CARApplication=%@ workspace=%@",
       DFClassName(fbs),DFEncoding(fbs,@selector(entitlementValuesForKeys:),NO),
       DFClassName(cached),DFEncoding(cached,@selector(boolForKey:),NO),
       DFEncoding(cached,@selector(objectForKey:),NO),
       DFEncoding(cached,@selector(numberForKey:),NO),
       DFClassName(proxy),
       DFEncoding(proxy,NSSelectorFromString(@"entitlementValueForKey:ofClass:valuesOfClass:"),NO),
       DFEncoding(proxy,NSSelectorFromString(@"entitlementValueForKey:ofClass:"),NO),
       DFEncoding(proxy,@selector(entitlementValuesForKeys:),NO),
       DFEncoding(proxy,NSSelectorFromString(@"objectForInfoDictionaryKey:ofClass:"),NO),
       DFClassName(appProxy),
       DFEncoding(appProxy,NSSelectorFromString(@"applicationProxyForIdentifier:"),YES),
       DFClassName(carApp),DFClassName(dbWorkspace)];
    NSDictionary *request=[NSDictionary dictionaryWithContentsOfFile:DFRequestPath];
    if([request[@"Kind"] isEqualToString:@"consolidated-target"]) {
        NSString *summary=DFTargetReadOnlySummary();
        details=[NSString stringWithFormat:@"%@ | %@",details,summary];
    }
    DFFinish(@"complete",details,requestID);
}
static void DFRunOnce(void) {
    if(DFTryScan)return;
    // The preferred/default state is DISABLED. An explicit, recent, one-time
    // request from the iPhone QA UI is required every time.
    NSDictionary *req=[NSDictionary dictionaryWithContentsOfFile:DFRequestPath];
    NSNumber *enabled=req[@"Enabled"];
    NSNumber *timestamp=req[@"RequestAt"];
    NSString *rid=req[@"RequestID"];
    if(![enabled isKindOfClass:NSNumber.class] || !enabled.boolValue ||
       ![timestamp isKindOfClass:NSNumber.class] ||
       ![rid isKindOfClass:NSString.class] ||
       ![[NSUUID alloc] initWithUUIDString:rid])return;
    NSTimeInterval age=NSDate.date.timeIntervalSince1970-timestamp.doubleValue;
    if(!isfinite(age) || age<0 || age>30)return;
    DFTryScan=YES;
    // Disarm BEFORE touching any runtime class: no stale opt-in after a crash.
    NSMutableDictionary *off=[req mutableCopy];
    off[@"Enabled"]=@NO;
    if(![off writeToFile:DFRequestPath atomically:YES]){
        DFTryScan=NO;
        DFLog(@"aborted-failed-to-disarm-request no scan");
        return;
    }
    NSOperatingSystemVersion os=NSProcessInfo.processInfo.operatingSystemVersion;
    if(os.majorVersion!=16){
        DFFinish(@"unsupported",@"iOS version outside 16; no ABI invocation",rid);
        DFTryScan=NO;
        return;
    }
    @try { DFReadOnlyInventory(rid); }
    @catch(NSException *e) {
        DFFinish(@"error",[NSString stringWithFormat:@"runtime-exception=%@",e.name],rid);
    }
    DFTryScan=NO;
}
static void DFSignalCallback(CFNotificationCenterRef center,void *observer,
                              CFStringRef name,const void *object,CFDictionaryRef userInfo) {
    (void)center;(void)observer;(void)name;(void)object;(void)userInfo;
    // Darwin callbacks may arrive on arbitrary threads; run on the main queue.
    dispatch_async(dispatch_get_main_queue(), ^{ DFRunOnce(); });
}
__attribute__((constructor))
static void DFEntry(void) {
    @autoreleasepool {
        if(![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"])return;
        // Observer registration is the ONLY default-on behavior. No scan,
        // method hook, bundle discovery or disk mutation at launch.
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
             NULL,DFSignalCallback,DFSignal,NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
        DFLog(@"loaded idle opt-in-only; no app admission or private API invocation");
    }
}
