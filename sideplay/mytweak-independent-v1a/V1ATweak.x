// One self-contained v1b+v1c install: passive v1a log + opt-in real scene trial.
// Unmodified original QA11, Native12, HUD8 packages continue to work independently.
#import <Foundation/Foundation.h>
#import "MTPreflight.h"
#import "MTBridgeCoordinator.h"
#import "MTTrialLog.h"
%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [MTPreflight startReadOnlyDiagnostics];
        [[MTBridgeCoordinator sharedCoordinator] start];
        MTTrialLog(@"trial-installed",@"enabled-by-default=0 no-host-until-Filza-opt-in");
    });
}
%end
