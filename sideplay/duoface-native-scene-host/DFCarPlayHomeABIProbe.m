// QA135: first-party read-only ABI verifier for genuine iOS16 CarPlay Home.
// Source contract: original DuoNavi 1.0.4 CARApplication._newApplicationLibrary
// and DBApplicationInfo/CARApplicationInfo factory. No vendor code is used.
// This does NOT install hooks, mutate a system roster, or launch applications.
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <notify.h>
#import <dispatch/dispatch.h>
#import <fcntl.h>
#import <unistd.h>
#import <string.h>
#import "DFEnabledAppsPolicy.h"

static NSString *const DFHomeABILogPath=
    @"/var/mobile/Library/Logs/DuoFaceHomeCatalogABI.log";
static NSUInteger sHomeABIGeneration=0;

static BOOL DFHomeABIAllowedProcess(void) {
    NSString *name=NSProcessInfo.processInfo.processName;
    NSString *bundle=NSBundle.mainBundle.bundleIdentifier;
    if ([name isEqualToString:@"SpringBoard"])
        return [bundle isEqualToString:@"com.apple.springboard"];
    if ([name isEqualToString:@"CarPlay"] || [name isEqualToString:@"CarPlayApp"])
        return YES;
    return [name isEqualToString:@"dashboard"] &&
           [bundle.lowercaseString isEqualToString:@"com.apple.dashboard"];
}
static void DFHomeABILog(NSString *body) {
    NSString *line=[NSString stringWithFormat:
        @"[DuoFaceHomeABI] process=%@ pid=%d %@\n",
        NSProcessInfo.processInfo.processName,getpid(),body?:@""];
    NSLog(@"%@",line);
    int fd=open(DFHomeABILogPath.fileSystemRepresentation,
                O_WRONLY|O_CREAT|O_APPEND,0644);
    if(fd<0)return;
    NSData *bytes=[line dataUsingEncoding:NSUTF8StringEncoding];
    if(bytes.length) (void)write(fd,bytes.bytes,bytes.length);
    close(fd);
}
static NSString *DFHomeABIDescription(Class cls,SEL selector,BOOL isClassMethod) {
    if(!cls || !selector)return @"unavailable";
    Method method=isClassMethod?class_getClassMethod(cls,selector):
                                class_getInstanceMethod(cls,selector);
    if(!method)return @"absent";
    const char *types=method_getTypeEncoding(method);
    char ret[48]={0};
    method_getReturnType(method,ret,sizeof(ret));
    return [NSString stringWithFormat:@"type=%s return=%s argc=%u",
            types?: "nil",ret,method_getNumberOfArguments(method)];
}
static void DFHomeABISelector(NSString *clsname,NSString *selector,BOOL isClass) {
    Class cls=objc_getClass(clsname.UTF8String);
    NSString *description=DFHomeABIDescription(cls,NSSelectorFromString(selector),isClass);
    DFHomeABILog([NSString stringWithFormat:@"%@ %@[%@ %@]",
      cls?@"loaded":@"unloaded",isClass?@"+":@"-",clsname,selector]);
    DFHomeABILog([NSString stringWithFormat:@"abi %@ %@ %@",
       clsname,selector,description]);
}
static void DFHomeABISample(NSUInteger generation) {
    if(!DFHomeABIAllowedProcess() ||
       NSProcessInfo.processInfo.operatingSystemVersion.majorVersion!=16 ||
       generation!=sHomeABIGeneration)return;
    NSString *proc=NSProcessInfo.processInfo.processName;
    NSArray<NSString *> *enabled=DFConfiguredEnabledAppIDs();
    DFHomeABILog([NSString stringWithFormat:
        @"sample generation=%lu version=16 configured=%lu preference=%@",
        (unsigned long)generation,(unsigned long)enabled.count,
        enabled?@"present":@"absent"]);
    // Strictly read Objective-C metadata; never invoke private methods,
    // fabricate an app declaration, or alter native CarPlay Home.
    if([proc isEqualToString:@"CarPlay"] ||
       [proc isEqualToString:@"CarPlayApp"] ||
       [proc isEqualToString:@"dashboard"]) {
        DFHomeABISelector(@"CARApplication",@"_newApplicationLibrary",YES);
        DFHomeABISelector(@"CARApplication",@"_newApplicationLibrary",NO);
        DFHomeABISelector(@"CARApplication",@"init",NO);
        DFHomeABISelector(@"FBSApplicationLibrary",@"addApplicationProxy:",NO);
        DFHomeABISelector(@"FBSApplicationLibrary",@"addApplicationProxy:withOverrideURL:",NO);
        DFHomeABISelector(@"FBSApplicationLibrary",@"applicationInfoForBundleIdentifier:",NO);
        DFHomeABISelector(@"FBSApplicationLibrary",@"_notifyDidAddApplications:",NO);
        DFHomeABISelector(@"FBSApplicationLibrary",@"_notifyDidRemoveApplications:",NO);
        DFHomeABISelector(@"DBApplicationInfo",@"_loadFromProxy:",NO);
        DFHomeABISelector(@"CARApplicationInfo",@"_loadFromProxy:",NO);
        DFHomeABISelector(@"CRCarPlayAppPolicyEvaluator",
                          @"effectivePolicyForAppDeclaration:",NO);
        DFHomeABISelector(@"DBApplicationController",
                          @"applicationWithBundleIdentifier:",NO);
    } else {
        DFHomeABISelector(@"FBSApplicationInfo",@"entitlementValuesForKeys:",NO);
        DFHomeABISelector(@"LSBundleInfoCachedValues",@"boolForKey:",NO);
        DFHomeABISelector(@"LSBundleInfoCachedValues",@"objectForKey:",NO);
        DFHomeABISelector(@"LSBundleProxy",
             @"entitlementValueForKey:ofClass:valuesOfClass:",NO);
        DFHomeABISelector(@"LSBundleProxy",
             @"entitlementValueForKey:ofClass:",NO);
    }
}
__attribute__((constructor)) static void DFHomeABIInstall(void) {
    @autoreleasepool {
        if(!DFHomeABIAllowedProcess() ||
           NSProcessInfo.processInfo.operatingSystemVersion.majorVersion!=16)return;
        dispatch_async(dispatch_get_main_queue(), ^{
            const NSUInteger generation=++sHomeABIGeneration;
            DFHomeABISample(generation);
            // Bounded late-load sampling rather than process-wide hook/retries.
            for(NSNumber *seconds in @[@3,@12]) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                      (int64_t)(seconds.doubleValue*NSEC_PER_SEC)),
                      dispatch_get_main_queue(), ^{
                    DFHomeABISample(generation);
                });
            }
            static int token=-1;
            int status=notify_register_dispatch(DFEnabledAppsChangedNotification,
                  &token,dispatch_get_main_queue(),^(__unused int t) {
                DFHomeABISample(sHomeABIGeneration);
            });
            DFHomeABILog([NSString stringWithFormat:@"notify-listener=%d",status]);
        });
    }
}
