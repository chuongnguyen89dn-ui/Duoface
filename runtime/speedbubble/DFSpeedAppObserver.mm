// DuoFace-owned source module candidate; built into DuoFace, not separately installed.
// Read CURRENT speed only from GPS updates already delivered to a user-installed
// map app. It does not request location permission, wake apps, or spoof limits.
// A dedicated, version-verified map adapter must provide speed limits later.
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <objc/runtime.h>
#import "DFSpeedTransport.h"
#import <math.h>
#import <string.h>

static DFSpeedAppSource DFRunningApp=DFSpeedAppSourceNone;
static IMP DFOriginalSetDelegate=NULL;
static NSMutableDictionary<NSString *,NSValue *> *DFOriginalDelegates;
static NSObject *DFDelegateLock;

static DFSpeedAppSource DFSourceForBundle(NSString *bundle) {
    if ([bundle isEqualToString:@"com.google.Maps"]) return DFSpeedAppSourceGoogleMaps;
    if ([bundle isEqualToString:@"com.waze.iphone"]) return DFSpeedAppSourceWaze;
    if ([bundle isEqualToString:@"vn.vietmap.live"]) return DFSpeedAppSourceVietMap;
    if ([bundle isEqualToString:@"com.lumi.GOFA"]) return DFSpeedAppSourceGOFA;
    return DFSpeedAppSourceNone;
}
static BOOL DFLocationFresh(CLLocation *loc) {
    if (![loc isKindOfClass:CLLocation.class] ||
        !isfinite(loc.speed) || loc.speed<0 || loc.speed>111.111 ||
        !isfinite(loc.horizontalAccuracy) || loc.horizontalAccuracy<0 ||
        !loc.timestamp) return NO;
    NSTimeInterval age=NSDate.date.timeIntervalSince1970-loc.timestamp.timeIntervalSince1970;
    return isfinite(age) && age>=-1 && age<=5;
}
static void DFObserveFreshAppGPS(id locations) {
    if (![locations isKindOfClass:NSArray.class] ||
        ![(NSArray *)locations count]) return;
    CLLocation *loc=[(NSArray *)locations lastObject];
    if (!DFLocationFresh(loc)) return;
    NSInteger kmh=lround(loc.speed * 3.6);
    // Without a source-backed limit, show unknown, NEVER guess a traffic rule.
    DFSpeedHUDPublish(DFRunningApp,kmh,YES,0,NO);
}
static IMP DFOriginalDelegateIMPFor(id delegate) {
    Class cls=object_getClass(delegate);
    @synchronized(DFDelegateLock) {
        for (Class k=cls; k; k=class_getSuperclass(k)) {
            NSValue *v=DFOriginalDelegates[NSStringFromClass(k)];
            if (v) return (IMP)v.pointerValue;
        }
    }
    return NULL;
}
static void DFWrappedDidUpdate(id delegate,SEL cmd,
                               CLLocationManager *manager,NSArray *locations) {
    DFObserveFreshAppGPS(locations);
    IMP imp=DFOriginalDelegateIMPFor(delegate);
    if (imp && imp!=(IMP)DFWrappedDidUpdate)
        ((void(*)(id,SEL,CLLocationManager *,NSArray *))imp)
          (delegate,cmd,manager,locations);
}
static void DFWrapDelegateIfSafe(id delegate) {
    if (!delegate || !DFDelegateLock) return;
    Class cls=object_getClass(delegate);
    if (!cls || ![delegate respondsToSelector:
                      @selector(locationManager:didUpdateLocations:)]) return;
    SEL sel=@selector(locationManager:didUpdateLocations:);
    Method method=class_getInstanceMethod(cls,sel);
    if (!method || method_getNumberOfArguments(method)!=4) return;
    char *ret=method_copyReturnType(method);
    BOOL valid=ret && strcmp(ret,"v")==0;
    if (ret) free(ret);
    if (!valid) return;
    @synchronized(DFDelegateLock) {
        NSString *name=NSStringFromClass(cls);
        if (DFOriginalDelegates[name]) return;
        IMP original=method_getImplementation(method);
        if (!original || original==(IMP)DFWrappedDidUpdate) return;
        const char *types=method_getTypeEncoding(method);
        if (!types) return;
        // Replace even inherited implementations; class_replaceMethod can
        // legitimately return NULL for inherited methods. Always retain the
        // actual original IMP retrieved above to preserve app callback.
        class_replaceMethod(cls,sel,(IMP)DFWrappedDidUpdate,types);
        DFOriginalDelegates[name]=[NSValue valueWithPointer:(void *)original];
    }
}
static void DFWrappedSetDelegate(CLLocationManager *self,SEL cmd,id delegate) {
    if (delegate) DFWrapDelegateIfSafe(delegate);
    if (DFOriginalSetDelegate)
        ((void(*)(id,SEL,id))DFOriginalSetDelegate)(self,cmd,delegate);
}
static void DFInstallGPSObserver(void) {
    Class cls=NSClassFromString(@"CLLocationManager");
    SEL sel=@selector(setDelegate:);
    Method m=cls ? class_getInstanceMethod(cls,sel):NULL;
    if (!m || method_getNumberOfArguments(m)!=3) return;
    char *ret=method_copyReturnType(m);
    BOOL valid=ret && strcmp(ret,"v")==0;
    if (ret) free(ret);
    if (!valid) return;
    DFDelegateLock=[NSObject new];
    DFOriginalDelegates=[NSMutableDictionary new];
    DFOriginalSetDelegate=method_setImplementation(m,(IMP)DFWrappedSetDelegate);
    if (!DFOriginalSetDelegate)
        NSLog(@"[DuoFaceSpeedHUD] CoreLocation delegate observer unavailable");
}
__attribute__((constructor)) static void DFStartSourceObserver(void) {
    @autoreleasepool {
        DFRunningApp=DFSourceForBundle(NSBundle.mainBundle.bundleIdentifier);
        if (DFRunningApp==DFSpeedAppSourceNone) return;
        DFInstallGPSObserver();
        // This hook observes app-provided CLLocation only. No fallback fake
        // limit is published, and no user app is opened programmatically.
    }
}
