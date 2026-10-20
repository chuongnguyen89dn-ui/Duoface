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
static id DFEntitlement3(id proxy, SEL sel, id key, Class expected, Class valueClass) {
    if(!DFOriginal3)return nil; // Hook original missing: fail closed, never dereference NULL.
    id real=DFOriginal3(proxy,sel,key,expected,valueClass);
    if(real)return real;
    if(!DFEligible(proxy,key,expected,valueClass))return real;
    DFLog([NSString stringWithFormat:@"bundle=%@ selector=typed3 key=%@ original=nil result=number",DFHostID,key]);
    return @YES;
}
static id DFEntitlement2(id proxy, SEL sel, id key, Class expected) {
    if(!DFOriginal2)return nil;
    id real=DFOriginal2(proxy,sel,key,expected);
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
        DFLog(@"loaded: consent + one-shot roster observer registered (no implicit entitlement change)");
        dispatch_async(dispatch_get_main_queue(), ^{DFCheckConsentAndArm(@"startup");});
    }
}
