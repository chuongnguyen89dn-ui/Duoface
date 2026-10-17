// VisualTest12 functional recovery candidate: narrow activation-gate repair.
// Keep every original scene/bridge/lifecycle implementation. Do not stub the
// original 291 methods or copy proprietary DuoDash/Airaw binaries.
// Technical model: DuoDash's scene host is not dependent on DuoFace license UI.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dispatch/dispatch.h>
#import <dlfcn.h>
#import <string.h>

typedef void (*DFSubstrateHook)(Class, SEL, IMP, IMP *);
static DFSubstrateHook DFHook = NULL;
static BOOL (*DFOriginalValid)(id,SEL) = NULL;
static unsigned long long (*DFOriginalRemaining)(id,SEL) = NULL;
static unsigned long long (*DFOriginalExpires)(id,SEL) = NULL;

static BOOL DFValid(id self, SEL cmd) { (void)self; (void)cmd; return YES; }
static unsigned long long DFRemaining(id self, SEL cmd) {
    (void)self; (void)cmd; return 3650ULL*24ULL*60ULL*60ULL;
}
static unsigned long long DFExpires(id self, SEL cmd) {
    (void)self; (void)cmd;
    return (unsigned long long)[NSDate date].timeIntervalSince1970 + DFRemaining(nil,NULL);
}
static BOOL DFRoleAllowed(void) {
    NSString *bid=[NSBundle mainBundle].bundleIdentifier.lowercaseString;
    return [bid isEqualToString:@"com.apple.springboard"] ||
           [bid isEqualToString:@"com.apple.carplayapp"] ||
           [bid isEqualToString:@"com.duoface.duofaceui"] ||
           [bid isEqualToString:@"com.duonavi.app"];
}
static BOOL DFABI(Class cls, NSString *name, const char *expected) {
    Method method=class_getInstanceMethod(cls,NSSelectorFromString(name));
    const char *types=method ? method_getTypeEncoding(method) : NULL;
    return types && strcmp(types,expected)==0;
}
static void DFInstallOnce(void) {
    static BOOL installed=NO;
    if (installed || !DFRoleAllowed()) return;
    if (!DFHook) DFHook=(DFSubstrateHook)dlsym(RTLD_DEFAULT,"MSHookMessageEx");
    Class gate=NSClassFromString(@"CBLicenseSyncManager");
    if (!gate || !DFHook) return;
    // Match the original VisualTest12 ABIs before changing ANY method.
    if (!DFABI(gate,@"isLicenseCurrentlyValid","B16@0:8") ||
        !DFABI(gate,@"remainingLicenseSeconds","Q16@0:8") ||
        !DFABI(gate,@"actualLicenseExpirationTimestamp","Q16@0:8")) {
        NSLog(@"[DFVisual12GateRepair] ABI mismatch; original untouched");
        return;
    }
    installed=YES; // Never retry a partially installed hook.
    DFHook(gate,NSSelectorFromString(@"isLicenseCurrentlyValid"),
           (IMP)DFValid,(IMP *)&DFOriginalValid);
    DFHook(gate,NSSelectorFromString(@"remainingLicenseSeconds"),
           (IMP)DFRemaining,(IMP *)&DFOriginalRemaining);
    DFHook(gate,NSSelectorFromString(@"actualLicenseExpirationTimestamp"),
           (IMP)DFExpires,(IMP *)&DFOriginalExpires);
    NSLog(@"[DFVisual12GateRepair] narrow functional repair installed");
}
__attribute__((constructor)) static void DFVisual12RepairStart(void) {
    @autoreleasepool {
        if (!DFRoleAllowed()) return;
        DFInstallOnce();
        dispatch_async(dispatch_get_main_queue(),^{
            DFInstallOnce();
            for (NSNumber *delay in @[@1,@3,@8]) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                    (int64_t)(delay.doubleValue*NSEC_PER_SEC)),
                    dispatch_get_main_queue(),^{DFInstallOnce();});
            }
        });
    }
}
