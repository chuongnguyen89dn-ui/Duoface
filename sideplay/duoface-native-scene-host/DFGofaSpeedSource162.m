// DuoFace QA162 - GOFA-only speed source. No GOFA binary patching and no
// private GOFA fields: uses the location permission the user grants to GOFA.
// Reports only valid CoreLocation GPS speed, never an inferred road speed limit.
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import "speed8/DFSpeedTransport.h"
#import "DF165NativeSpeedUptime.h"
#import <math.h>

@interface DFGofaSpeedSource162 : NSObject <CLLocationManagerDelegate>
@property(nonatomic,strong) CLLocationManager *manager;
@property(nonatomic,strong) NSTimer *retryTimer;
@property(nonatomic,assign) BOOL started;
@property(nonatomic,assign) NSTimeInterval initializedAt;
@end
@implementation DFGofaSpeedSource162
+ (instancetype)shared {
    static DFGofaSpeedSource162 *source;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ source=[DFGofaSpeedSource162 new]; });
    return source;
}
- (void)start {
    self.initializedAt=NSProcessInfo.processInfo.systemUptime;
    self.manager=[CLLocationManager new];
    self.manager.delegate=self;
    self.manager.desiredAccuracy=kCLLocationAccuracyNearestTenMeters;
    self.manager.distanceFilter=2.0;
    NSNotificationCenter *center=[NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(applicationActivated:)
                   name:UIApplicationDidBecomeActiveNotification object:nil];
    [center addObserver:self selector:@selector(applicationActivated:)
                   name:UIApplicationWillEnterForegroundNotification object:nil];
    // Authorization may be granted later from GOFA settings; no permission prompt.
    self.retryTimer=[NSTimer scheduledTimerWithTimeInterval:4.0
        target:self selector:@selector(checkAuthorization:)
        userInfo:nil repeats:YES];
    [self checkAuthorization:nil];
}
- (void)applicationActivated:(NSNotification *)notice {
    (void)notice;
    [self checkAuthorization:nil];
}
- (void)checkAuthorization:(NSTimer *)timer {
    (void)timer;
    BOOL services=[CLLocationManager locationServicesEnabled];
    CLAuthorizationStatus status=self.manager.authorizationStatus;
    static NSInteger previousStatus=-999;
    static NSTimeInterval lastDiagnostic=0;
    NSTimeInterval now=NSProcessInfo.processInfo.systemUptime;
    if(previousStatus!=status || now-lastDiagnostic>=30.0) {
        NSLog(@"[DuoFaceSpeed8] GOFA GPS source status auth=%ld services=%d active=%d",
              (long)status,services,self.started);
        previousStatus=status;lastDiagnostic=now;
    }
    if(!services) {
        if(self.started){ [self.manager stopUpdatingLocation];self.started=NO; }
        return;
    }
    BOOL allowed=(status==kCLAuthorizationStatusAuthorizedAlways ||
                  status==kCLAuthorizationStatusAuthorizedWhenInUse);
    // QA170: QA169 compiled this entire publisher out. GOFA's native
    // delegate tap is still preferred, but some Flutter routes have no
    // observable CLLocation delegate callbacks. A second first-party
    // CLLocationManager may be used only as a bounded fallback and only
    // under GOFA's EXISTING authorization. Never request permissions.
    uint64_t nativeLast=DF165LastNativeGPSPublishUptime();
    BOOL nativeHealthy=nativeLast>0 && isfinite(now) && now>=nativeLast &&
                       now-(double)nativeLast<=8.0;
    BOOL fallbackEligible=isfinite(now) &&
                          now-self.initializedAt>=10.0 && !nativeHealthy;
    if(allowed && fallbackEligible && !self.started) {
        [self.manager startUpdatingLocation];
        self.started=YES;
        NSLog(@"[DuoFaceSpeed8] QA170 fallback real GOFA GPS started; passiveSampleMissing=%d",
              nativeLast==0);
    } else if((!allowed || nativeHealthy) && self.started) {
        [self.manager stopUpdatingLocation];
        self.started=NO;
        NSLog(@"[DuoFaceSpeed8] QA170 fallback stopped: permission=%d nativeHealthy=%d",
              allowed,nativeHealthy);
    }
}
- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager {
    (void)manager;
    [self checkAuthorization:nil];
}
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    (void)manager;
    CLLocation *location=locations.lastObject;
    if(!location) return;
    NSTimeInterval age=-location.timestamp.timeIntervalSinceNow;
    BOOL fresh=(isfinite(age) && age>=-2.0 && age<=8.0);
    BOOL speedValid=(isfinite(location.speed) && location.speed>=0.0);
    BOOL accurate=(isfinite(location.horizontalAccuracy) &&
                   location.horizontalAccuracy>=0.0 &&
                   location.horizontalAccuracy<=100.0);
    if(!fresh || !speedValid || !accurate) {
        static NSTimeInterval lastInvalid=0;
        NSTimeInterval now=NSProcessInfo.processInfo.systemUptime;
        if(now-lastInvalid>=30.0) {
            NSLog(@"[DuoFaceSpeed8] GOFA GPS sample REJECTED fresh=%d speedValid=%d accuracyValid=%d",
                  fresh,speedValid,accurate);
            lastInvalid=now;
        }
        return;
    }
    double kmh=location.speed*3.6;
    if(!isfinite(kmh) || kmh>400.0) return;
    NSInteger rounded=(NSInteger)lround(kmh);
    BOOL posted=DFSpeedHUDPublish(DFSpeedAppSourceGOFA,rounded,YES,0,NO);
    if(!posted) {
        static NSTimeInterval lastPublishError=0;
        NSTimeInterval now=NSProcessInfo.processInfo.systemUptime;
        if(now-lastPublishError>=30.0) {
            NSLog(@"[DuoFaceSpeed8] GOFA GPS IPC publication FAILED");
            lastPublishError=now;
        }
    }
    if(posted) {
        static NSTimeInterval lastLog=0;
        NSTimeInterval now=NSProcessInfo.processInfo.systemUptime;
        if(now-lastLog>=30.0) {
            NSLog(@"[DuoFaceSpeed8] GOFA valid GPS speed publish, limit unavailable");
            lastLog=now;
        }
    }
}
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    (void)manager;
    NSLog(@"[DuoFaceSpeed8] GOFA GPS source unavailable: %@",error.domain);
}
@end
__attribute__((constructor)) static void DFStartGOFASpeed162(void) {
    if(![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.lumi.GOFA"])return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[DFGofaSpeedSource162 shared] start];
    });
}

