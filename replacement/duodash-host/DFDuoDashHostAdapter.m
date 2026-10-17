// Interoperability with an existing, separately installed DuoDash scene owner.
// No code from the original DuoFace binaries or unrelated plugins is referenced.
#import "DFDuoDashHostAdapter.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <string.h>
#import <math.h>

NSString * const DFDDHostErrorDomain = @"com.duoface.replacement.duodash";

static BOOL DFDDReject(NSError **error, NSInteger code, NSString *reason) {
    if (error) *error = [NSError errorWithDomain:DFDDHostErrorDomain code:code
                                       userInfo:@{NSLocalizedDescriptionKey:reason}];
    return NO;
}

static BOOL DFDDVerifyRuntime(NSError **error) {
    // A SpringBoard scene controller cannot be instantiated from a CarPlay UI process.
    if (![[NSBundle mainBundle].bundleIdentifier.lowercaseString
          isEqualToString:@"com.apple.springboard"])
        return DFDDReject(error, 1, @"Scene host must run inside SpringBoard");

    Class klass = NSClassFromString(@"DDz2");
    if (!klass)
        return DFDDReject(error, 2, @"The authorized DuoDash runtime is not loaded");

    Method shared = class_getClassMethod(klass, NSSelectorFromString(@"shared"));
    const char *sharedABI = shared ? method_getTypeEncoding(shared) : NULL;
    if (!sharedABI || strcmp(sharedABI, "@16@0:8") != 0)
        return DFDDReject(error, 3, @"DuoDash shared instance ABI differs");

    Method factory = class_getInstanceMethod(klass,
                         NSSelectorFromString(@"cnabBuildSceneHostForBid:displaySize:"));
    const char *factoryABI = factory ? method_getTypeEncoding(factory) : NULL;
    if (!factoryABI ||
        strcmp(factoryABI, "@40@0:8@16{CGSize=dd}24") != 0)
        return DFDDReject(error, 4, @"DuoDash scene factory ABI differs");

    return YES;
}

@implementation DFDuoDashHostAdapter
+ (BOOL)isAvailableWithError:(NSError **)error {
    return DFDDVerifyRuntime(error);
}
+ (UIViewController *)createUnattachedSceneForBundleID:(NSString *)bundleID
                                             renderSize:(CGSize)size
                                                  error:(NSError **)error {
    if (![NSThread isMainThread]) {
        DFDDReject(error, 5, @"Call scene factory on SpringBoard main thread");
        return nil;
    }
    if (bundleID.length < 3 || bundleID.length > 255 ||
        [bundleID rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound ||
        size.width < 1 || size.height < 1 ||
        !isfinite(size.width) || !isfinite(size.height)) {
        DFDDReject(error, 6, @"Invalid app identifier or rendering size");
        return nil;
    }
    if (!DFDDVerifyRuntime(error)) return nil;

    Class klass = NSClassFromString(@"DDz2");
    SEL getter = NSSelectorFromString(@"shared");
    SEL builder = NSSelectorFromString(@"cnabBuildSceneHostForBid:displaySize:");
    @try {
        id (*ownerGetter)(id,SEL) = (id (*)(id,SEL))objc_msgSend;
        id owner = ownerGetter(klass, getter);
        if (!owner || ![owner isKindOfClass:klass]) {
            DFDDReject(error, 7, @"DuoDash scene owner unavailable");
            return nil;
        }

        // No secondary SpringBoard scene owner is created here. The original
        // DuoDash owner is called exactly once; callers must coordinate layout
        // and lifetime before attaching the returned controller to a window.
        id (*factoryCall)(id,SEL,id,CGSize) = (id (*)(id,SEL,id,CGSize))objc_msgSend;
        id controller = factoryCall(owner, builder, bundleID, size);
        if (![controller isKindOfClass:UIViewController.class]) {
            DFDDReject(error, 8, @"Scene factory did not return a view controller");
            return nil;
        }
        return (UIViewController *)controller;
    } @catch (NSException *exception) {
        DFDDReject(error, 9, exception.reason ?: @"DuoDash scene exception");
        return nil;
    }
}
@end
