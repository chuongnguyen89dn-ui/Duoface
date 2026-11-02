// QA169 independent CPNavigationSession source hook, grounded in the ORIGINAL
// CarPlayPro Speed 0.9.97 binary, not an invented GOFA Swift ABI.
// Machine addresses: MSHookMessageEx(0x2fae4) selector at 0x6b000 is
// setUpcomingManeuvers:, MSHookMessageEx(0x2fb00) selector at 0x6b008 is
// updateTravelEstimates:forManeuver: (verified by original arm64 selref bytes).
// Our code is independently authored, GOFA process only, forwards originals
// FIRST and publishes only real, public Apple maneuver/estimate objects.
// Does NOT fabricate camera, road limit, route name, location or turn distance.
#import <Foundation/Foundation.h>
#import <CarPlay/CarPlay.h>
#import <objc/runtime.h>
#import <math.h>
#import "DF168NativeManeuver.h"

FOUNDATION_EXPORT BOOL DF168PublishNativeCarPlayManeuver(CPManeuver *maneuver,
                                                          CPTravelEstimates *estimate);
static void (*DF169OriginalSet)(id,SEL,NSArray *);
static void (*DF169OriginalUpdate)(id,SEL,CPTravelEstimates *,CPManeuver *);
static __weak CPManeuver *DF169LastManeuver;

static void DF169SetUpcoming(id owner,SEL cmd,NSArray *maneuvers) {
    if(DF169OriginalSet)DF169OriginalSet(owner,cmd,maneuvers);
    CPManeuver *first=([maneuvers isKindOfClass:NSArray.class] ?
                       maneuvers.firstObject : nil);
    if(![first isKindOfClass:CPManeuver.class]) {
        DF169LastManeuver=nil;
        // Previous live state expires in the IPC TTL; no invented zero meter.
        return;
    }
    DF169LastManeuver=first;
    (void)DF168PublishNativeCarPlayManeuver(first,first.initialTravelEstimates);
}
static void DF169UpdateTravelEstimates(id owner,SEL cmd,
                                      CPTravelEstimates *estimates,
                                      CPManeuver *maneuver) {
    if(DF169OriginalUpdate)
        DF169OriginalUpdate(owner,cmd,estimates,maneuver);
    if(maneuver && maneuver==DF169LastManeuver &&
       [estimates isKindOfClass:CPTravelEstimates.class])
        (void)DF168PublishNativeCarPlayManeuver(maneuver,estimates);
}
static BOOL DF169ExactObjCReturnAndArguments(Method m,unsigned count) {
    if(!m || method_getNumberOfArguments(m)!=count)return NO;
    char ret[16]={0};method_getReturnType(m,ret,sizeof(ret));
    if(ret[0]!='v')return NO;
    for(unsigned i=2;i<count;i++){
        char arg[32]={0};method_getArgumentType(m,i,arg,sizeof(arg));
        if(arg[0]!='@')return NO;
    }
    return YES;
}
__attribute__((constructor)) static void DF169InstallOriginalBasedNavigationSource(void) {
    @autoreleasepool {
        if(![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.lumi.GOFA"])return;
        dispatch_async(dispatch_get_main_queue(), ^{
            Class cls=NSClassFromString(@"CPNavigationSession");
            if(!cls)return; // GOFA may not use Apple's native navigation API
            Method setter=class_getInstanceMethod(cls,
                NSSelectorFromString(@"setUpcomingManeuvers:"));
            Method updater=class_getInstanceMethod(cls,
                NSSelectorFromString(@"updateTravelEstimates:forManeuver:"));
            if(!DF169ExactObjCReturnAndArguments(setter,3) ||
               !DF169ExactObjCReturnAndArguments(updater,4)) {
                NSLog(@"[DuoFaceTrafficNav] QA169 original selectors absent/incompatible; not hooking");
                return;
            }
            DF169OriginalSet=(void(*)(id,SEL,NSArray *))
                method_setImplementation(setter,(IMP)DF169SetUpcoming);
            DF169OriginalUpdate=(void(*)(id,SEL,CPTravelEstimates *,CPManeuver *))
                method_setImplementation(updater,(IMP)DF169UpdateTravelEstimates);
            NSLog(@"[DuoFaceTrafficNav] QA169 original-binary-proven native navigation methods observed; on-device events NOT yet proven");
        });
    }
}
