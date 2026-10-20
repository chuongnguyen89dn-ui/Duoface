// Independent iOS 16 CarPlay admission candidate. NOT a SpringBoard tweak.
// Fail-closed, disabled by default; only the first-party UIKit scene host is eligible.
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <CoreFoundation/CoreFoundation.h>
#import <unistd.h>
#import <fcntl.h>
#import <string.h>
#import <dlfcn.h>
typedef void (*DFHookMethod)(Class, SEL, IMP, IMP *);

static NSString *const DFHostID=@"com.duoface.native.scenehost";
static NSString *const DFPrefs=@"/var/mobile/Library/Preferences/com.duoface.firstparty-admission.plist";
static const char *DFDisable="/var/mobile/Library/Preferences/.duoface-firstparty-admission-disable";
static NSString *const DFLogFile=@"/var/mobile/Library/Logs/DuoFaceFirstPartyAdmission.log";
static id (*DFOriginal3)(id, SEL, id, Class, Class)=NULL;
static id (*DFOriginal2)(id, SEL, id, Class)=NULL;
static BOOL DFHooksInstalled=NO;
static CFStringRef const DFRefreshSignal=CFSTR("com.duoface.firstparty-admission.refresh");
static CFStringRef const DFRosterSignal=CFSTR("com.duoface.firstparty-admission.roster-readonly");
static NSString *const DFRosterRequest=@"/var/mobile/Library/Preferences/com.duoface.firstparty-roster.request.plist";
static NSString *DFLastRosterRequestID=nil;
// The diagnostic borrows the EXISTING two typed hooks. No extra method hook.
static NSString *const DFTraceRequest=@"/var/mobile/Library/Preferences/com.duoface.admission-trace.request.plist";
static NSString *const DFTraceLogFile=@"/var/mobile/Library/Logs/DuoFaceAdmissionTrace.log";
static const char *DFTraceDisable="/var/mobile/Library/Preferences/.duoface-admission-trace-disable";
static volatile int DFTraceSamples=0;
static NSString *DFTraceRunID=nil;
static CFStringRef const DFTraceSignal=CFSTR("com.duoface.admission-trace.preflight");
static NSString *const DFTraceStatus=@"/var/mobile/Library/Preferences/com.duoface.admission-trace.status.plist";

static void DFLog(NSString *message) {
    NSString *s=[NSString stringWithFormat:@"[DFAdmission/CarPlay] %@\n",message];
    NSLog(@"%@",s);
    int fd=open(DFLogFile.fileSystemRepresentation,O_WRONLY|O_APPEND|O_CREAT,0644);
    if(fd>=0){ NSData *data=[s dataUsingEncoding:NSUTF8StringEncoding];
        if(data.length) (void)write(fd,data.bytes,data.length); close(fd); }
}
static BOOL DFExplicitConsent(void) {
    if(access(DFDisable,F_OK)==0) return NO;
    NSDictionary *d=[NSDictionary dictionaryWithContentsOfFile:DFPrefs];
    return [d isKindOfClass:NSDictionary.class] &&
        [d[@"Enabled"] isKindOfClass:NSNumber.class] && [d[@"Enabled"] boolValue] &&
        [d[@"HostBundleID"] isKindOfClass:NSString.class] &&
        [d[@"HostBundleID"] isEqualToString:DFHostID] &&
        [d[@"RiskAcknowledged"] isKindOfClass:NSNumber.class] &&
        [d[@"RiskAcknowledged"] boolValue];
}
static BOOL DFKeyAllowed(id key) {
    if(![key isKindOfClass:NSString.class])return NO;
    return [key isEqualToString:@"CARCapableApp"] ||
           [key isEqualToString:@"SBStarkCapable"];
}
static BOOL DFEligible(id proxy, id key, Class expected, Class valuesExpected) {
    if(!DFKeyAllowed(key) || !DFExplicitConsent())return NO;
    if(expected && expected!=NSNumber.class)return NO;
    if(valuesExpected && valuesExpected!=NSNumber.class)return NO;
    // Only this first-party bundle. Do not change other apps or their entitlements.
    @try {
        SEL sel=sel_registerName("bundleIdentifier");
        if(![proxy respondsToSelector:sel])return NO;
        id name=((id (*)(id,SEL))objc_msgSend)(proxy,sel);
        return [name isKindOfClass:NSString.class] && [name isEqualToString:DFHostID];
    } @catch(NSException *e) { return NO; }
}

static NSDictionary *DFTraceActiveRequest(void) {
    if(!DFExplicitConsent() || access(DFDisable,F_OK)==0 ||
       access(DFTraceDisable,F_OK)==0)return nil;
    NSDictionary *r=[NSDictionary dictionaryWithContentsOfFile:DFTraceRequest];
    if(![r isKindOfClass:NSDictionary.class] ||
       ![r[@"Enabled"] isKindOfClass:NSNumber.class] || ![r[@"Enabled"] boolValue] ||
       ![r[@"AuditOnly"] isKindOfClass:NSNumber.class] || ![r[@"AuditOnly"] boolValue] ||
       ![r[@"HostBundleID"] isEqualToString:DFHostID] ||
       ![r[@"RequestID"] isKindOfClass:NSString.class] ||
       ![[NSUUID alloc] initWithUUIDString:r[@"RequestID"]] ||
       ![r[@"RequestAt"] isKindOfClass:NSNumber.class])return nil;
    NSTimeInterval age=NSDate.date.timeIntervalSince1970-[r[@"RequestAt"] doubleValue];
    return age>=0 && age<=180 ? r : nil;
}
static BOOL DFTraceOwnBundle(id proxy) {
    @try {
        SEL s=sel_registerName("bundleIdentifier");
        if(![proxy respondsToSelector:s])return NO;
        id bundle=((id(*)(id,SEL))objc_msgSend)(proxy,s);
        return [bundle isKindOfClass:NSString.class] && [bundle isEqualToString:DFHostID];
    } @catch(NSException *exception) {return NO;}
}
static NSString *DFTraceClass(Class c) {return c?NSStringFromClass(c):@"nil";}
static void DFTraceLog(NSString *s) {
    NSString *line=[NSString stringWithFormat:@"[DFTrace] wall=%.3f uptime=%.3f pid=%d %@\n",
        NSDate.date.timeIntervalSince1970,NSProcessInfo.processInfo.systemUptime,getpid(),s];
    int fd=open(DFTraceLogFile.fileSystemRepresentation,O_WRONLY|O_CREAT|O_APPEND,0644);
    if(fd>=0){NSData *d=[line dataUsingEncoding:NSUTF8StringEncoding];
       if(d.length)(void)write(fd,d.bytes,d.length);close(fd);}
}
static BOOL DFTraceObserve(id proxy,id key,Class expected,Class valuesExpected,id real,NSString *selector) {
    // Diagnostic never logs unrelated app IDs, methods or any personal data.
    // Idle hot path exits before inspecting any app metadata.
    NSDictionary *request=DFTraceActiveRequest();
    if(!request)return NO;
    if(!DFTraceOwnBundle(proxy))return NO;
    NSString *run=request[@"RequestID"];
    @synchronized(DFHostID){
        if(![DFTraceRunID isEqualToString:run]){DFTraceRunID=[run copy];DFTraceSamples=0;}
        if(DFTraceSamples>=16)return YES; // AuditOnly pass-through, even after log cap.
        DFTraceSamples++;
        NSString *keyName=[key isKindOfClass:NSString.class]?key:@"non-string";
        NSString *kind=real?NSStringFromClass([real class]):@"nil";
        DFTraceLog([NSString stringWithFormat:
            @"run=%@ sample=%d/16 selector=%@ key=%@ expected=%@ valuesExpected=%@ originalClass=%@ originalNil=%d auditOnly=true",
            run,DFTraceSamples,selector,keyName,DFTraceClass(expected),
            DFTraceClass(valuesExpected),kind,real==nil]);
        if(DFTraceSamples==16)DFTraceLog([NSString stringWithFormat:
            @"run=%@ log-cap-reached; pass-through continues until 180s expiry or QA stop",run]);
    }
    return YES;
}
static id DFEntitlement3(id proxy, SEL sel, id key, Class expected, Class valueClass) {
    if(!DFOriginal3)return nil; // Hook original missing: fail closed, never dereference NULL.
    id real=DFOriginal3(proxy,sel,key,expected,valueClass);
    if(DFTraceObserve(proxy,key,expected,valueClass,real,@"typed3"))return real;
    if(real)return real;
    if(!DFEligible(proxy,key,expected,valueClass))return real;
    DFLog([NSString stringWithFormat:@"bundle=%@ selector=typed3 key=%@ original=nil result=number",DFHostID,key]);
    return @YES;
}
static id DFEntitlement2(id proxy, SEL sel, id key, Class expected) {
    if(!DFOriginal2)return nil;
    id real=DFOriginal2(proxy,sel,key,expected);
    if(DFTraceObserve(proxy,key,expected,Nil,real,@"typed2"))return real;
    if(real)return real;
    if(!DFEligible(proxy,key,expected,Nil))return real;
    DFLog([NSString stringWithFormat:@"bundle=%@ selector=typed2 key=%@ original=nil result=number",DFHostID,key]);
    return @YES;
}
// Keep hooks inert until explicit QA consent. A fresh Darwin event also works
// if the CarPlay process was already running when the user tapped Enable.
static void DFCheckConsentAndArm(NSString *reason) {
    NSOperatingSystemVersion os=NSProcessInfo.processInfo.operatingSystemVersion;
    if(os.majorVersion!=16){DFLog(@"idle: unsupported iOS; no hook");return;}
    if(!DFExplicitConsent()){
        DFLog([NSString stringWithFormat:@"idle: disabled (%@); no hook",reason]);
        return;
    }
    if(DFHooksInstalled){
        DFLog([NSString stringWithFormat:@"already armed: %@; effective permission read for each call",reason]);
        return;
    }
    Class c=NSClassFromString(@"LSBundleProxy");
    SEL s3=sel_registerName("entitlementValueForKey:ofClass:valuesOfClass:");
    SEL s2=sel_registerName("entitlementValueForKey:ofClass:");
    Method m3=c?class_getInstanceMethod(c,s3):NULL;
    Method m2=c?class_getInstanceMethod(c,s2):NULL;
    const char *t3=m3?method_getTypeEncoding(m3):NULL;
    const char *t2=m2?method_getTypeEncoding(m2):NULL;
    // Exact observed iOS16 ABI, otherwise fail closed.
    if(!t3 || strcmp(t3,"@40@0:8@16#24#32")!=0 ||
       !t2 || strcmp(t2,"@32@0:8@16#24")!=0) {
        DFLog(@"ABI mismatch or LSBundleProxy unavailable: no hook");
        return;
    }
    DFHookMethod hook=(DFHookMethod)dlsym(RTLD_DEFAULT,"MSHookMessageEx");
    if(!hook){DFLog(@"hook API missing: no admission hooks installed");return;}
    // This runs only on CarPlay's main queue, and only once after successful setup.
    hook(c,s3,(IMP)DFEntitlement3,(IMP *)&DFOriginal3);
    if(!DFOriginal3){DFLog(@"hook original3 unavailable; no capability granted");return;}
    hook(c,s2,(IMP)DFEntitlement2,(IMP *)&DFOriginal2);
    if(!DFOriginal2){DFLog(@"hook original2 unavailable; no capability granted");return;}
    DFHooksInstalled=YES;
    if(DFTraceActiveRequest())DFTraceLog([NSString stringWithFormat:@"run=%@ hook-ready via=%@ (not proof of library filter order)",DFTraceActiveRequest()[@"RequestID"],reason]);
    DFLog([NSString stringWithFormat:@"opt-in two typed getters armed via %@; only first-party bundle; no SpringBoard hook",reason]);
}
static void DFRefreshCallback(CFNotificationCenterRef center,void *observer,
    CFStringRef name,const void *object,CFDictionaryRef info) {
    (void)center;(void)observer;(void)name;(void)object;(void)info;
    dispatch_async(dispatch_get_main_queue(), ^{
        DFLog(@"consent signal received: checking current preferences");
        DFCheckConsentAndArm(@"qa-notify");
    });
}

static NSString *DFSafeEncoding(Class c,SEL selector,BOOL isClassMethod) {
    Method m=c?(isClassMethod?class_getClassMethod(c,selector):class_getInstanceMethod(c,selector)):NULL;
    if(!m)return @"unavailable";
    const char *enc=method_getTypeEncoding(m);
    return enc?[NSString stringWithUTF8String:enc]:@"missing-encoding";
}
// An explicit ONE-SHOT diagnostic: query only our own app identifier,
// only after verifying the ABI. No writes to LaunchServices or SpringBoard.
static void DFReadOnlyRosterProbe(void) {
    if(!DFExplicitConsent()){DFLog(@"roster-readonly denied: opt-in off");return;}
    if(NSProcessInfo.processInfo.operatingSystemVersion.majorVersion!=16) {
        DFLog(@"roster-readonly skipped: not iOS16");return;
    }
    NSDictionary *req=[NSDictionary dictionaryWithContentsOfFile:DFRosterRequest];
    NSString *rid=req[@"RequestID"];
    NSNumber *created=req[@"RequestAt"];
    if(![rid isKindOfClass:NSString.class] || ![[NSUUID alloc] initWithUUIDString:rid] ||
       ![created isKindOfClass:NSNumber.class] ||
       ![req[@"Enabled"] isKindOfClass:NSNumber.class] || ![req[@"Enabled"] boolValue] ||
       ![req[@"HostBundleID"] isEqualToString:DFHostID] ||
       [rid isEqualToString:DFLastRosterRequestID]) return;
    NSTimeInterval age=[NSDate.date timeIntervalSince1970]-[created doubleValue];
    if(age<0 || age>30)return;
    DFLastRosterRequestID=[rid copy];
    NSMutableDictionary *off=[req mutableCopy];
    off[@"Enabled"]=@NO;
    if(![off writeToFile:DFRosterRequest atomically:YES]){
        DFLog(@"roster-readonly aborted: failed to disarm request");return;
    }
    @try {
        Class app=NSClassFromString(@"LSApplicationProxy");
        SEL lookup=sel_registerName("applicationProxyForIdentifier:");
        NSString *encoding=DFSafeEncoding(app,lookup,YES);
        if(![encoding isEqualToString:@"@24@0:8@16"]) {
            DFLog([NSString stringWithFormat:@"roster-readonly lookup ABI=%@; no invocation",encoding]);
            return;
        }
        id candidate=((id (*)(id,SEL,id))objc_msgSend)(app,lookup,DFHostID);
        if(!candidate) {DFLog(@"roster-readonly appProxy=absent in CarPlay process");return;}
        SEL bundleSelector=sel_registerName("bundleIdentifier");
        NSString *actualID=@"unavailable";
        if([candidate respondsToSelector:bundleSelector]) {
            id value=((id (*)(id,SEL))objc_msgSend)(candidate,bundleSelector);
            if([value isKindOfClass:NSString.class])actualID=value;
        }
        SEL readManifest=sel_registerName("objectForInfoDictionaryKey:ofClass:");
        NSString *manifestABI=DFSafeEncoding([candidate class],readManifest,NO);
        NSString *role=@"unknown-ABI";
        if([actualID isEqualToString:DFHostID] &&
           [manifestABI isEqualToString:@"@32@0:8@16#24"]) {
            id result=((id (*)(id,SEL,id,Class))objc_msgSend)(
                candidate,readManifest,@"UIApplicationSceneManifest",NSDictionary.class);
            if([result isKindOfClass:NSDictionary.class]) {
                id configs=result[@"UISceneConfigurations"];
                role=[configs isKindOfClass:NSDictionary.class] &&
                     [configs[@"UIWindowSceneSessionRoleCarPlay"] isKindOfClass:NSArray.class]?
                      @"declared":@"not-declared";
            } else role=result?@"not-dictionary":@"nil";
        }
        DFLog([NSString stringWithFormat:
            @"roster-readonly appProxy=present bundleMatches=%d lookupABI=%@ manifestABI=%@ CarPlayRole=%@ (NOT Dashboard admission)",
            [actualID isEqualToString:DFHostID],encoding,manifestABI,role]);
    } @catch(NSException *e) {
        DFLog([NSString stringWithFormat:@"roster-readonly exception=%@; no mutation",e.name]);
    }
}
static void DFRosterCallback(CFNotificationCenterRef center,void *observer,
    CFStringRef name,const void *object,CFDictionaryRef info) {
    (void)center;(void)observer;(void)name;(void)object;(void)info;
    dispatch_async(dispatch_get_main_queue(), ^{DFReadOnlyRosterProbe();});
}

// A deterministic handshake from ALREADY RUNNING CarPlay; replaces any need
// to reload SpringBoard or assume package installation means a dylib is loaded.
// Only one target UUID, read-only class/ABI introspection, no app library calls.
static void DFTracePreflight(void) {
    NSDictionary *req=DFTraceActiveRequest();
    if(!req){DFLog(@"trace-preflight ignored: consent, kill switch or request invalid");return;}
    NSString *run=req[@"RequestID"];
    DFCheckConsentAndArm(@"trace-preflight");
    Class bundle=NSClassFromString(@"LSBundleProxy");
    SEL s3=sel_registerName("entitlementValueForKey:ofClass:valuesOfClass:");
    Method getter=bundle?class_getInstanceMethod(bundle,s3):NULL;
    NSString *typed=getter&&method_getTypeEncoding(getter)?
        [NSString stringWithUTF8String:method_getTypeEncoding(getter)]:@"unavailable";
    Class dash=NSClassFromString(@"DashBoard");
    SEL library=sel_registerName("_newApplicationLibrary");
    Method method=dash?class_getClassMethod(dash,library):NULL;
    NSString *factoryABI=method&&method_getTypeEncoding(method)?
        [NSString stringWithUTF8String:method_getTypeEncoding(method)]:@"unavailable";
    BOOL ready=DFHooksInstalled&&DFOriginal3&&DFOriginal2;
    NSDictionary *status=@{
       @"Version":@5, @"Process":@"CarPlay", @"RequestID":run,
       @"Timestamp":@(NSDate.date.timeIntervalSince1970),@"PID":@(getpid()),
       @"HooksReady":@(ready), @"Kind":@"firstparty-trace-preflight",
       @"Typed3ABI":typed, @"DashBoardFactoryABI":factoryABI,
       @"Reason":ready?@"existing-getters-armed":@"hooks-not-ready"
    };
    BOOL written=[status writeToFile:DFTraceStatus atomically:YES];
    DFTraceLog([NSString stringWithFormat:
       @"run=%@ preflightAck=%d version=5 hooksReady=%d typed3ABI=%@ DashBoardFactoryABI=%@; no application library invoked",
       run,written,ready,typed,factoryABI]);
}
static void DFTraceCallback(CFNotificationCenterRef center,void *observer,
    CFStringRef name,const void *object,CFDictionaryRef info) {
    (void)center;(void)observer;(void)name;(void)object;(void)info;
    dispatch_async(dispatch_get_main_queue(), ^{DFTracePreflight();});
}
__attribute__((constructor)) static void DFAdmissionEntry(void) {
    @autoreleasepool {
        // SpringBoard must NEVER load this candidate.
        if(![NSProcessInfo.processInfo.processName isEqualToString:@"CarPlay"])return;
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
            NULL,DFRefreshCallback,DFRefreshSignal,NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
            NULL,DFRosterCallback,DFRosterSignal,NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
            NULL,DFTraceCallback,DFTraceSignal,NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately);
        if(DFTraceActiveRequest())DFTraceLog([NSString stringWithFormat:@"run=%@ module-constructor process=CarPlay (library timing unknown)",DFTraceActiveRequest()[@"RequestID"]]);
        DFLog(@"loaded: consent + one-shot roster observer registered (no implicit entitlement change)");
        DFCheckConsentAndArm(@"constructor-early");
    }
}
