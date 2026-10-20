// Independent read-only, one-shot ABI inventory for DuoFace iOS16.
// NO entitlement getter invocation, method hook, cached-value substitution,
// LS database writes, scene activation, Dock change, daemon restart or respring.
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>
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
static void DFReadOnlyInventory(NSString *requestID) {
    Class fbs=NSClassFromString(@"FBSApplicationInfo");
    Class cached=NSClassFromString(@"LSBundleInfoCachedValues");
    Class proxy=NSClassFromString(@"LSBundleProxy");
    Class appProxy=NSClassFromString(@"LSApplicationProxy");
    Class carApp=NSClassFromString(@"CARApplication");
    Class dbWorkspace=NSClassFromString(@"DBWorkspace");
    // Read method type encodings ONLY. Do not construct / invoke private APIs.
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
