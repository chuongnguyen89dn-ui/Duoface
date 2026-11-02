// QA165: passive, GOFA-process-only CoreLocation callback observer.
// This reads speed on GOFA's ACTUAL CLLocationManager delegate deliveries;
// it does not create another location manager, request a license, or read
// proprietary camera/road-speed-limit data. It preserves the original callback.
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <math.h>
#import "speed8/DFSpeedTransport.h"
#import "DF165NativeSpeedUptime.h"
#include <stdatomic.h>

static atomic_uint_fast64_t DF165LastGoodPublishSeconds=0;
uint64_t DF165LastNativeGPSPublishUptime(void) {
    return (uint64_t)atomic_load_explicit(&DF165LastGoodPublishSeconds,memory_order_relaxed);
}
static IMP DF165SetDelegateOriginal;
static NSMutableDictionary<NSString *,NSValue *> *DF165OriginalCallbacks;
static NSTimeInterval DF165LastAttachLog;
static NSTimeInterval DF165LastSpeedLog;

static NSString *DF165ClassKey(Class cls) {
    return cls ? NSStringFromClass(cls) : @"";
}
static void DF165OriginalDidUpdate(id receiver,SEL cmd,
                                  CLLocationManager *manager,NSArray *locations) {
    IMP imp=NULL;
    @synchronized(DF165OriginalCallbacks) {
        imp=[DF165OriginalCallbacks[DF165ClassKey(object_getClass(receiver))] pointerValue];
    }
    if(imp && imp!=(IMP)DF165OriginalDidUpdate)
        ((void(*)(id,SEL,CLLocationManager *,NSArray *))imp)(receiver,cmd,manager,locations);
}
static void DF165DidUpdate(id receiver,SEL cmd,CLLocationManager *manager,NSArray *locations) {
    // Forward first so location behavior observed by GOFA remains unchanged.
    DF165OriginalDidUpdate(receiver,cmd,manager,locations);
    CLLocation *point=[locations isKindOfClass:NSArray.class]?locations.lastObject:nil;
    if(![point isKindOfClass:CLLocation.class])return;
    NSTimeInterval age=-point.timestamp.timeIntervalSinceNow;
    BOOL fresh=isfinite(age) && age>=-2.0 && age<=8.0;
    BOOL accurate=isfinite(point.horizontalAccuracy) &&
        point.horizontalAccuracy>=0 && point.horizontalAccuracy<=100;
    BOOL speedOK=isfinite(point.speed) && point.speed>=0 && point.speed<=111.12;
    BOOL valid=fresh && accurate && speedOK;
    NSTimeInterval now=NSProcessInfo.processInfo.systemUptime;
    if(now-DF165LastSpeedLog>30.0) {
        NSLog(@"[DuoFaceSpeed8] QA165 GOFA native location CALLBACK fresh=%d accuracyOK=%d speedOK=%d",
              fresh,accurate,speedOK);
        DF165LastSpeedLog=now;
    }
    if(!valid)return;
    NSInteger kmh=(NSInteger)lround(point.speed*3.6);
    if(DFSpeedHUDPublish(DFSpeedAppSourceGOFA,kmh,YES,0,NO)) {
        if(isfinite(now) && now>=1 && now<=UINT32_MAX)
            atomic_store_explicit(&DF165LastGoodPublishSeconds,
                                  (uint_fast64_t)floor(now),memory_order_relaxed);
    } else NSLog(@"[DuoFaceSpeed8] QA165 GOFA native GPS IPC FAILED");
}
static void DF165ObserveDelegate(id delegate) {
    if(!delegate)return;
    Class cls=object_getClass(delegate);
    // QA170: do NOT wrap DuoFace's own conditional fallback delegate.
    // Otherwise its own GPS publish is misidentified as a GOFA native source,
    // then the watchdog stops itself every 8 seconds.
    if([DF165ClassKey(cls) isEqualToString:@"DFGofaSpeedSource162"])return;
    SEL callback=@selector(locationManager:didUpdateLocations:);
    Method method=class_getInstanceMethod(cls,callback);
    if(!method)return;
    // Only exact void(ObjC object, SEL, object, object) methods are wrapped.
    const char *type=method_getTypeEncoding(method);
    if(!type || method_getNumberOfArguments(method)!=4)return;
    char returnType[8]={0},arg2[8]={0},arg3[8]={0};
    method_getReturnType(method,returnType,sizeof(returnType));
    method_getArgumentType(method,2,arg2,sizeof(arg2));
    method_getArgumentType(method,3,arg3,sizeof(arg3));
    if(returnType[0]!='v'||arg2[0]!='@'||arg3[0]!='@')return;
    NSString *key=DF165ClassKey(cls);
    @synchronized(DF165OriginalCallbacks) {
        if(DF165OriginalCallbacks[key])return;
        IMP original=method_getImplementation(method);
        if(original==(IMP)DF165DidUpdate)return;
        // Add the override to the *actual delegate class* if the callback is
        // inherited. Never mutate a superclass that might belong to other apps.
        if(!class_addMethod(cls,callback,(IMP)DF165DidUpdate,type)) {
            Method local=class_getInstanceMethod(cls,callback);
            original=method_setImplementation(local,(IMP)DF165DidUpdate);
        }
        DF165OriginalCallbacks[key]=[NSValue valueWithPointer:original];
    }
    NSTimeInterval now=NSProcessInfo.processInfo.systemUptime;
    if(now-DF165LastAttachLog>=15.0) {
        NSLog(@"[DuoFaceSpeed8] QA165 GOFA native CoreLocation delegate OBSERVED hooked=1 class=%@",key);
        DF165LastAttachLog=now;
    }
}
static void DF165SetDelegate(CLLocationManager *manager,SEL cmd,id delegate) {
    if(DF165SetDelegateOriginal)
        ((void(*)(id,SEL,id))DF165SetDelegateOriginal)(manager,cmd,delegate);
    if(delegate)DF165ObserveDelegate(delegate);
}
__attribute__((constructor)) static void DF165InstallGOFALocationTap(void) {
    @autoreleasepool {
        if(![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.lumi.GOFA"])return;
        DF165OriginalCallbacks=[NSMutableDictionary new];
        Method setter=class_getInstanceMethod(CLLocationManager.class,@selector(setDelegate:));
        if(!setter)return;
        // Keep original, including all delegate reassignment semantics.
        DF165SetDelegateOriginal=method_setImplementation(setter,(IMP)DF165SetDelegate);
        NSLog(@"[DuoFaceSpeed8] QA165 GOFA native GPS delegate probe installed");
    }
}
