// QA137 — bounded READ-ONLY iOS16 Home ownership and policy ABI trace.
// Runs in already-filtered CarPlay / CarPlayApp / dashboard / SpringBoard.
// Does NOT hook LaunchServices, spoof entitlements, patch a system plist,
// change the Dashboard icon model, activate an app, or touch GOFA.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dispatch/dispatch.h>
#import <dlfcn.h>
#import <fcntl.h>
#import <unistd.h>
#import <string.h>
#import "DFHomePublisher136Config.h"

static NSString *const DF137LogPath =
    @"/var/mobile/Library/Logs/DuoFaceHomeAdmission137.log";
static NSUInteger DF137InfoSamples = 0;

static BOOL DF137InScope(void) {
    if (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion != 16)
        return NO;
    NSString *process = NSProcessInfo.processInfo.processName;
    NSString *bundle = NSBundle.mainBundle.bundleIdentifier.lowercaseString;
    if ([process isEqualToString:@"CarPlay"] ||
        [process isEqualToString:@"CarPlayApp"]) return YES;
    if ([process isEqualToString:@"SpringBoard"])
        return [bundle isEqualToString:@"com.apple.springboard"];
    return [process.lowercaseString isEqualToString:@"dashboard"] &&
           [bundle isEqualToString:@"com.apple.dashboard"];
}

static void DF137Log(NSString *message) {
    if (!DF137InScope()) return;
    NSString *line = [NSString stringWithFormat:
        @"[DFHome137] process=%@ pid=%d %@\n",
        NSProcessInfo.processInfo.processName, getpid(), message ?: @""];
    int fd = open(DF137LogPath.fileSystemRepresentation,
                  O_CREAT | O_WRONLY | O_APPEND, 0644);
    if (fd < 0) return;
    NSData *bytes = [line dataUsingEncoding:NSUTF8StringEncoding];
    if (bytes.length) (void)write(fd, bytes.bytes, bytes.length);
    close(fd);
}

// Exact ObjC metadata only. No class constructors or private method calls.
static NSString *DF137MethodABI(const char *className,
                                const char *selectorName,
                                BOOL classSide) {
    Class cls = objc_getClass(className);
    if (!cls) return @"class-absent";
    SEL selector = sel_registerName(selectorName);
    Method method = classSide ? class_getClassMethod(cls, selector) :
                                class_getInstanceMethod(cls, selector);
    if (!method) return @"method-absent";
    const char *encoding = method_getTypeEncoding(method);
    IMP imp = method_getImplementation(method);
    Dl_info sym = {0};
    NSString *image = @"unknown";
    if (imp && dladdr((const void *)imp, &sym) && sym.dli_fname)
        image = [[NSString stringWithUTF8String:sym.dli_fname] lastPathComponent];
    return [NSString stringWithFormat:@"type=%s image=%@",
            encoding ?: "<null>", image];
}

static void DF137Sample(NSString *phase) {
    if (!DF137InScope()) return;
    DF137Log([NSString stringWithFormat:
        @"sample=%@ iOS=%@ switch=%d pid-identity=%@",
        phase, UIDevice.currentDevice.systemVersion, DFHome136Enabled(),
        NSBundle.mainBundle.bundleIdentifier ?: @"none"]);
    static const struct {
        const char *name;
        const char *selector;
        BOOL classSide;
    } methods[] = {
        {"DashBoard", "_newApplicationLibrary", YES},
        {"CARApplication", "_newApplicationLibrary", YES},
        {"CARApplication", "_newApplicationLibrary", NO},
        {"CARApplication", "_allInstalledApplications", YES},
        {"CARApplication", "_allInstalledApplicationsByBundleIdentifier", YES},
        {"_CARDashboardHomeViewController", "_setupIconModel", NO},
        {"_CARDashboardHomeViewController", "viewDidAppear:", NO},
        {"_CARDashboardHomeViewController", "iconManager:launchIcon:", NO},
        {"_CARDashboardHomeViewController", "iconManager:launchIconForIconView:", NO},
        {"DBApplicationController", "sharedInstance", YES},
        {"DBApplicationController", "applicationWithBundleIdentifier:", NO},
        {"DBWorkspace", "initWithOwner:", NO},
        {"FBSApplicationLibrary", "allInstalledApplications", NO},
        {"FBSApplicationLibrary", "applicationInfoForBundleIdentifier:", NO},
        {"FBSApplicationLibrary", "_notifyDidAddApplications:", NO},
        {"DBApplicationInfo", "carPlayDeclaration", NO},
        {"DBApplicationInfo", "isCarPlaySupported", NO},
        {"DBApplicationInfo", "canDisplayOnCarScreen", NO},
        {"DBApplicationInfo", "launchAsCarApplication", NO},
        {"CARApplicationInfo", "canDisplayOnCarScreen", NO},
        {"CRCarPlayAppDeclaration", "declarationForAppProxy:", YES},
        {"CRCarPlayAppPolicyEvaluator", "effectivePolicyForAppDeclaration:", NO},
        {"LSBundleProxy", "entitlementValueForKey:ofClass:valuesOfClass:", NO},
        {"LSBundleProxy", "entitlementValueForKey:ofClass:", NO},
        {"FBSApplicationInfo", "entitlementValuesForKeys:", NO},
        {"LSBundleInfoCachedValues", "boolForKey:", NO}
    };
    for (NSUInteger i = 0; i < sizeof(methods) / sizeof(methods[0]); ++i) {
        DF137Log([NSString stringWithFormat:@"abi %c[%s %s] %@",
            methods[i].classSide ? '+' : '-', methods[i].name,
            methods[i].selector,
            DF137MethodABI(methods[i].name, methods[i].selector,
                           methods[i].classSide)]);
    }
}

// Called ONLY on an info object that QA136 already looked up from its
// verified live FBSApplicationLibrary. Do not log bundle IDs, app titles,
// user content, entitlement values, addresses, or app scene identifiers.
void DF137ObserveExistingAppInfo(id info, NSString *stage) {
    if (!info || !DF137InScope() || DF137InfoSamples >= 32) return;
    DF137InfoSamples++;
    Class cls = object_getClass(info);
    Class db = objc_getClass("DBApplicationInfo");
    DF137Log([NSString stringWithFormat:
        @"fbs-info sample=%lu stage=%@ concrete-class=%@ isDBApplicationInfo=%d",
        (unsigned long)DF137InfoSamples, stage ?: @"unknown",
        cls ? NSStringFromClass(cls) : @"nil",
        db ? [info isKindOfClass:db] : NO]);
    for (NSString *getter in @[@"carPlayDeclaration", @"isCarPlaySupported",
                               @"canDisplayOnCarScreen", @"launchAsCarApplication"]) {
        SEL selector = NSSelectorFromString(getter);
        Method m = cls ? class_getInstanceMethod(cls, selector) : NULL;
        const char *type = m ? method_getTypeEncoding(m) : NULL;
        // Runtime type and presence prove ABI shape without executing any
        // private getter that may be unsafe on an FBSApplicationInfo proxy.
        DF137Log([NSString stringWithFormat:@"fbs-info-abi %@ type=%s",
            getter, type ?: "method-absent"]);
    }
}

__attribute__((constructor)) static void DF137InstallProbe(void) {
    @autoreleasepool {
        if (!DF137InScope()) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            DF137Sample(@"startup");
            for (NSNumber *delay in @[@3, @12, @30]) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                    (int64_t)(delay.doubleValue * NSEC_PER_SEC)),
                    dispatch_get_main_queue(), ^{
                        DF137Sample([NSString stringWithFormat:@"late-%@s",delay]);
                    });
            }
        });
    }
}
