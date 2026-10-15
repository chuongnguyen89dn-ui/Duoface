// DuoFace native trial: retain original UI / split engine, redirect license-only
// entrypoints in the project runtime. Never touches split/layout/picker selectors.
// Experimental implementation: real-device reports determine remaining dependencies.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dispatch/dispatch.h>
#import <string.h>

static NSString *const DFILogPrefix = @"[DuoFaceNativeTrial]";
static NSMutableSet<NSString *> *DFIHookedMethods;
static NSUInteger DFIInstallRound = 0;
static BOOL DFIEnabledTestMode = NO;
static BOOL DFIBoolYes(id obj, SEL sel) { (void)obj;(void)sel;return YES; }
static signed char DFICharYes(id obj, SEL sel) { (void)obj;(void)sel;return 1; }
static long long DFILongYes(id obj, SEL sel) { (void)obj;(void)sel;return 1LL; }
static double DFITrialSeconds(id obj, SEL sel) { (void)obj;(void)sel;return 315360000.0; }
static float DFITrialFloat(id obj, SEL sel) { (void)obj;(void)sel;return 315360000.0f; }
static id DFIEmptyEndpoint(id obj, SEL sel) { (void)obj;(void)sel;return nil; }
static void DFINoWork(id obj, SEL sel) { (void)obj;(void)sel; }
static void DFINoWorkArg(id obj, SEL sel, id arg) { (void)obj;(void)sel;(void)arg; }
static BOOL DFIValidateNoPayload(id obj, SEL sel, id payload, id errorOut) {
    (void)obj;(void)sel;(void)payload;(void)errorOut;return YES;
}
static void DFILog(NSString *message) {
    NSLog(@"%@ %@", DFILogPrefix, message);
}
static BOOL DFITargetProcess(void) {
    NSString *bundle=NSBundle.mainBundle.bundleIdentifier.lowercaseString;
    if([bundle isEqualToString:@"com.duoface.duofaceui"])return YES;
    if([bundle isEqualToString:@"com.duoface.independent"])return YES;
    return [@[@"com.apple.springboard",@"com.apple.carplay",
              @"com.apple.carplayapp",@"com.apple.dashboard"] containsObject:bundle];
}
static BOOL DFIHookMethod(Class cls, NSString *selectorName, const char *returnTypes,
                          IMP implementation, NSUInteger arguments) {
    if(!cls || !selectorName.length || !DFIEnabledTestMode)return NO;
    Method method=class_getInstanceMethod(cls,NSSelectorFromString(selectorName));
    if(!method)return NO;
    NSString *key=[NSString stringWithFormat:@"%@.%@",NSStringFromClass(cls),selectorName];
    if([DFIHookedMethods containsObject:key])return YES;
    const char *signature=method_getTypeEncoding(method);
    if(!signature)return NO;
    NSMethodSignature *sig=[NSMethodSignature signatureWithObjCTypes:signature];
    if(!sig || sig.numberOfArguments != arguments) {
        DFILog([NSString stringWithFormat:@"SKIP type/argc mismatch %@ %s",key,signature]);
        return NO;
    }
    char type=sig.methodReturnType[0];
    if(!strchr(returnTypes,type)) {
        DFILog([NSString stringWithFormat:@"SKIP return ABI mismatch %@ %s",key,signature]);
        return NO;
    }
    IMP previous=method_setImplementation(method,implementation);
    if(!previous) {
        DFILog([NSString stringWithFormat:@"SKIP no original IMP %@",key]);
        return NO;
    }
    [DFIHookedMethods addObject:key];
    DFILog([NSString stringWithFormat:@"TEST_REDIRECT %@ signature=%s",key,signature]);
    return YES;
}
static void DFIInstallMethodForValue(Class cls, NSString *sel, BOOL seconds) {
    Method method=class_getInstanceMethod(cls,NSSelectorFromString(sel));
    if(!method)return;
    const char *types=method_getTypeEncoding(method);
    NSMethodSignature *sig=types?[NSMethodSignature signatureWithObjCTypes:types]:nil;
    if(!sig || sig.numberOfArguments!=2)return;
    switch(sig.methodReturnType[0]) {
        case 'B': DFIHookMethod(cls,sel,"B",(IMP)DFIBoolYes,2);break;
        case 'c': DFIHookMethod(cls,sel,"c",(IMP)DFICharYes,2);break;
        case 'i': case 's': case 'l': case 'q': case 'I': case 'S': case 'L': case 'Q':
             DFIHookMethod(cls,sel,"isqlISLQ",(IMP)DFILongYes,2);break;
        case 'd': DFIHookMethod(cls,sel,"d",(IMP)DFITrialSeconds,2);break;
        case 'f': DFIHookMethod(cls,sel,"f",(IMP)DFITrialFloat,2);break;
        default:
            DFILog([NSString stringWithFormat:@"SKIP unknown value ABI %@ %s",sel,types]);
            break;
    }
    (void)seconds;
}
static void DFIInstallIfAvailable(void) {
    if(!DFIEnabledTestMode)return;
    Class manager=NSClassFromString(@"CBLicenseSyncManager");
    if(manager){
        DFIInstallMethodForValue(manager,@"isLicenseCurrentlyValid",NO);
        DFIInstallMethodForValue(manager,@"remainingLicenseSeconds",YES);
        DFIInstallMethodForValue(manager,@"actualLicenseExpirationTimestamp",YES);
        DFIHookMethod(manager,@"checkAndSyncLicenseIfNeeded","v",(IMP)DFINoWork,2);
        DFIHookMethod(manager,@"checkAndSyncLicenseIfNeededWithSource:","v",(IMP)DFINoWorkArg,3);
        DFIHookMethod(manager,@"resolvedLicenseServerEndpoint","@",(IMP)DFIEmptyEndpoint,2);
        // Some builds expose manual install; intentionally leave untouched as
        // native project test does not install or generate license payloads.
    }
    Class bridge=NSClassFromString(@"CBBridgeManager");
    if(bridge){
        DFIHookMethod(bridge,@"startLicenseWatchdogTimer","v",(IMP)DFINoWork,2);
        DFIHookMethod(bridge,@"stopLicenseWatchdogTimer","v",(IMP)DFINoWork,2);
        DFIHookMethod(bridge,@"licenseWatchdogTimerFired:","v",(IMP)DFINoWorkArg,3);
        DFIHookMethod(bridge,@"presentLicenseWarningModalWithType:","v",(IMP)DFINoWorkArg,3);
        // dismissLicenseWarningModal left original so existing popup can close.
    }
    if(DFIInstallRound%10==0)
       DFILog([NSString stringWithFormat:@"hooked=%lu round=%lu core=%@ license=%@",
               (unsigned long)DFIHookedMethods.count,(unsigned long)DFIInstallRound,
               bridge?@"YES":@"NO",manager?@"YES":@"NO"]);
}
__attribute__((constructor)) static void DFILaunchNativeTrial(void) {
    @autoreleasepool {
        if(!DFITargetProcess())return;
        // This namespaced package is not co-installable with the legacy host.
        // Test behavior is always explicit in the package build: do not depend
        // on the user's personal license state.
        DFIEnabledTestMode=YES;
        DFIHookedMethods=[NSMutableSet new];
        dispatch_async(dispatch_get_main_queue(), ^{
            DFIInstallIfAvailable();
            [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer *timer){
                if(++DFIInstallRound>120){[timer invalidate];return;}
                DFIInstallIfAvailable();
            }];
        });
    }
}
