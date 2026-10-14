// Only enables the already compiled v12 Dashboard <-> SpringBoard adapter.
// The original split dashboard and license/day payload remain untouched.
#import <Foundation/Foundation.h>
#import "DFFullscreenCoordinator.h"

static void DFStartAdapterWhenLoaded(NSUInteger attempt) {
    NSCAssert(NSThread.isMainThread, @"Fullscreen bootstraps on main thread");
    if (DFStartFullscreenAdapter()) {
        NSLog(@"[DuoFaceFullscreen] candidate adapter started in %@",
              NSProcessInfo.processInfo.processName);
        return;
    }
    if (attempt >= 30) {
        NSLog(@"[DuoFaceFullscreen] candidate adapter unavailable in %@ after class-load retries",
              NSProcessInfo.processInfo.processName);
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        DFStartAdapterWhenLoaded(attempt + 1);
    });
}
__attribute__((constructor)) static void DFCandidateAdapterEntry(void) {
    @autoreleasepool {
        NSString *bundle = NSBundle.mainBundle.bundleIdentifier.lowercaseString;
        if (![@[@"com.apple.springboard", @"com.apple.carplayapp",
                 @"com.apple.carplay", @"com.apple.dashboard"] containsObject:bundle]) return;
        dispatch_async(dispatch_get_main_queue(), ^{ DFStartAdapterWhenLoaded(0); });
    }
}
