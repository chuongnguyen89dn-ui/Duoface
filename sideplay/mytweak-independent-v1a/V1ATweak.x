// Combined V1BC + real Apple Dock cooperative geometry candidate.
// No vendor license or pre-rendered/fake Apple dock.
#import <Foundation/Foundation.h>
#import "MTPreflight.h"
#import "MTBridgeCoordinator.h"
#import "MTTrialLog.h"
#import "MTDashboardContext.h"
#import "MTDashboardWorkspace.h"

%group MTSpringBoardHook
%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [MTPreflight startReadOnlyDiagnostics];
        [[MTBridgeCoordinator sharedCoordinator] start];
        MTTrialLog(@"trial-installed",@"enabled-by-default=0 carplay-native-dock-bridge=1");
    });
}
%end
%end

%ctor {
    @autoreleasepool {
        NSString *process=NSProcessInfo.processInfo.processName;
        if ([process isEqualToString:@"SpringBoard"]) {
            %init(MTSpringBoardHook);
        } else if ([process isEqualToString:@"CarPlay"] ||
                   [process isEqualToString:@"CarPlayApp"]) {
            if ([process isEqualToString:@"CarPlay"])
                [MTDashboardWorkspace installEarlyObserver];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                // Read-only scene/root geometry owner discovery first.
                [MTDashboardContext startIfCarPlayUIProcess];
            });
        }
    }
}
