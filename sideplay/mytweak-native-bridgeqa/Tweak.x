// No Logos hooks and no LS admission/entitlements/bootstrap swizzle.
// Separate QA module: read opt-in 10 seconds after process startup, preserving
// existing DuoFace V1BC and Apple CarPlay scene owners.
#import <Foundation/Foundation.h>
#import "DFCPNativeBridgeQA.h"
%ctor {
    @autoreleasepool {
        NSString *process=NSProcessInfo.processInfo.processName;
        if(![@[@"SpringBoard",@"CarPlay",@"CarPlayApp"] containsObject:process])return;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(10*NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [[DFCPNativeBridgeQA shared] start];
        });
    }
}
