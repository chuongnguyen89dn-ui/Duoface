// DuoFace independent MyTweak v1a: passive SpringBoard preflight ONLY.
#import <Foundation/Foundation.h>
#import "MTPreflight.h"

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [MTPreflight startReadOnlyDiagnostics];
    });
}
%end
