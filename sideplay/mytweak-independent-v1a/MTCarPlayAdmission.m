// Independent self-only CarPlay roster admission for jailbroken iOS 16.
// Never changes eligibility, entitlements or Info.plist of ANY other app.
#import "MTCarPlayAdmission.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <mach-o/loader.h>
static NSString *const kOurShell=@"com.duoface.mytweak.shell";
static const void *kTaggedShellCache=&kTaggedShellCache;
static id (*mtOriginalGetEntitlement3)(id,SEL,NSString *,Class,Class)=NULL;
static id (*mtOriginalGetEntitlement2)(id,SEL,NSString *,Class)=NULL;
static id (*mtOriginalGetBulk)(id,SEL,NSArray *)=NULL;
static BOOL (*mtOriginalCachedBool)(id,SEL,NSString *)=NULL;
static BOOL mtInstalled3=NO,mtInstalled2=NO,mtInstalledBulk=NO,mtInstalledCached=NO;
static BOOL mtImageObserverArmed=NO;
static BOOL MTIsOwnProxy(id object) {
    if (!object)return NO;
    SEL s=NSSelectorFromString(@"bundleIdentifier");
    if (![object respondsToSelector:s])return NO;
    @try {
        id bid=((id(*)(id,SEL))objc_msgSend)(object,s);
        return [bid isKindOfClass:NSString.class] && [bid isEqualToString:kOurShell];
    } @catch (NSException *e) { return NO; }
}
static BOOL MTIsCapability(NSString *key) {
    return [key isKindOfClass:NSString.class] &&
         ([key isEqualToString:@"CARCapableApp"] ||
          [key isEqualToString:@"SBStarkCapable"]);
}
static id MTGet3(id object,SEL sel,NSString *key,Class expected,Class expectedValues) {
    id actual=mtOriginalGetEntitlement3 ?
        mtOriginalGetEntitlement3(object,sel,key,expected,expectedValues):nil;
    if (actual || !MTIsCapability(key) || (expected && expected!=NSNumber.class))
        return actual;
    return MTIsOwnProxy(object)?@YES:actual;
}
static id MTGet2(id object,SEL sel,NSString *key,Class expected) {
    id actual=mtOriginalGetEntitlement2 ?
        mtOriginalGetEntitlement2(object,sel,key,expected):nil;
    if (actual || !MTIsCapability(key) || (expected && expected!=NSNumber.class))
        return actual;
    return MTIsOwnProxy(object)?@YES:actual;
}
static id MTGetBulk(id object,SEL sel,NSArray *keys) {
    id result=mtOriginalGetBulk?mtOriginalGetBulk(object,sel,keys):nil;
    if (result && [keys isKindOfClass:NSArray.class] && MTIsOwnProxy(object)) {
        for (id value in keys) {
            if (MTIsCapability(value)) {
                objc_setAssociatedObject(result,kTaggedShellCache,@YES,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                break;
            }
        }
    }
    return result; // Never replace an opaque LSBundleInfoCachedValues with NSDictionary.
}
static BOOL MTCacheBool(id obj,SEL sel,NSString *key) {
    BOOL real=mtOriginalCachedBool?mtOriginalCachedBool(obj,sel,key):NO;
    if (real || !MTIsCapability(key))return real;
    id flag=objc_getAssociatedObject(obj,kTaggedShellCache);
    return [flag respondsToSelector:@selector(boolValue)] && [flag boolValue];
}
static BOOL MTInstall(Class cls,SEL sel,IMP replacement,IMP *out,NSUInteger argCount,char ret) {
    Method m=class_getInstanceMethod(cls,sel);
    if (!m || method_getNumberOfArguments(m)!=argCount)return NO;
    char returnType[8]={0};method_getReturnType(m,returnType,sizeof(returnType));
    if (returnType[0]!=ret)return NO;
    IMP orig=method_getImplementation(m);
    if (!orig || orig==replacement)return NO;
    *out=orig;
    if (!class_addMethod(cls,sel,replacement,method_getTypeEncoding(m)))
        *out=method_setImplementation(class_getInstanceMethod(cls,sel),replacement);
    return YES;
}
static void MTAdmissionTryInstall(void) {
    Class cls=NSClassFromString(@"LSBundleProxy");
    if (cls) {
        if (!mtInstalled3)
            mtInstalled3=MTInstall(cls,NSSelectorFromString(@"entitlementValueForKey:ofClass:valuesOfClass:"),
              (IMP)MTGet3,(IMP *)&mtOriginalGetEntitlement3,5,'@');
        if (!mtInstalled2)
            mtInstalled2=MTInstall(cls,NSSelectorFromString(@"entitlementValueForKey:ofClass:"),
              (IMP)MTGet2,(IMP *)&mtOriginalGetEntitlement2,4,'@');
        if (!mtInstalledBulk)
            mtInstalledBulk=MTInstall(cls,NSSelectorFromString(@"entitlementValuesForKeys:"),
              (IMP)MTGetBulk,(IMP *)&mtOriginalGetBulk,3,'@');
    }
    Class cache=NSClassFromString(@"LSBundleInfoCachedValues");
    if (cache && !mtInstalledCached)
        mtInstalledCached=MTInstall(cache,NSSelectorFromString(@"boolForKey:"),
           (IMP)MTCacheBool,(IMP *)&mtOriginalCachedBool,3,'B');
}
static void MTAdmissionImageMapped(const struct mach_header *image) {
    (void)image;
    MTAdmissionTryInstall();
}
@implementation MTCarPlayAdmission
+ (void)installIfNeeded {
    NSString *name=NSProcessInfo.processInfo.processName;
    if (![name isEqualToString:@"SpringBoard"] &&
        ![name isEqualToString:@"CarPlay"])return;
    MTAdmissionTryInstall();
    if (!mtImageObserverArmed) {
        mtImageObserverArmed=YES;
        objc_addLoadImageFunc(MTAdmissionImageMapped);
    }
}
@end
