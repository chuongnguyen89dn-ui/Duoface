#import "DFFullscreenCoordinator.h"
#import "DFFullscreenTransport.h"
#import "DFDashboardChrome.h"
#import "DFPickerZoomMenu.h"
static NSString * const DFMenuZoomEvent=@"com.duoface.fullscreen.picker.v1";
static BOOL DFTransitionPending, DFHostActive, DFFullscreenConfirmed, DFAdapterStarted;
static NSUInteger DFTransitionGeneration;
@interface NSObject (DFDistributedObserve)
+ (id)defaultCenter;
- (void)addObserver:(id)observer selector:(SEL)sel name:(NSString *)name object:(id)obj;
@end
static void DFRestoreAfterFailure(NSString *reason) {
    NSLog(@"[DuoFaceFullscreen] rollback %@",reason);
    DFDashboardRestoreChrome(); DFFullscreenConfirmed=NO;
    DFRequestHostFullscreen(NO,^(BOOL ok, NSString *hostReason) {
        DFTransitionPending=NO;
        NSLog(@"[DuoFaceFullscreen] rollback restored=%d %@",ok,hostReason);
    });
}
static void DFEnterFullscreen(void) {
    if (!DFHostActive || DFTransitionPending || DFFullscreenConfirmed) return;
    DFTransitionPending=YES; NSUInteger gen=++DFTransitionGeneration;
    DFRequestHostFullscreen(YES,^(BOOL applied,NSString *reason) {
        if (gen!=DFTransitionGeneration) {
            DFRestoreAfterFailure(@"owner changed"); return;
        }
        if (!applied || !DFHostActive) {
            DFRestoreAfterFailure(reason?:@"host unavailable"); return;
        }
        NSString *chromeReason=nil;
        if (!DFDashboardSetChromeHidden(YES,&chromeReason)) {
            DFRestoreAfterFailure(chromeReason); return;
        }
        DFFullscreenConfirmed=YES; DFTransitionPending=NO;
        NSLog(@"[DuoFaceFullscreen] Zoom In ACK host+chrome");
    });
}
static void DFExitFullscreen(void) {
    if (DFTransitionPending || !DFFullscreenConfirmed) return;
    DFTransitionPending=YES; ++DFTransitionGeneration;
    DFRequestHostFullscreen(NO,^(BOOL restored,NSString *reason) {
        if (restored) {
            DFDashboardRestoreChrome(); DFFullscreenConfirmed=NO;
            NSLog(@"[DuoFaceFullscreen] Zoom Out ACK host");
        } else {
            DFQueryFullscreenHost();
            NSLog(@"[DuoFaceFullscreen] Zoom Out failed %@",reason);
        }
        DFTransitionPending=NO;
    });
}
@interface DFZoomReceiver:NSObject
- (void)received:(NSNotification *)notification;
@end
@implementation DFZoomReceiver
- (void)received:(NSNotification *)notification {
    NSDictionary *info=notification.userInfo;
    if (![info isKindOfClass:NSDictionary.class] || ![info[@"version"] isEqual:@1] ||
        ![info[@"expanded"] isKindOfClass:NSNumber.class] ||
        ![info[@"requestID"] isKindOfClass:NSString.class] ||
        [info[@"requestID"] length]==0) return;
    BOOL expanded=[info[@"expanded"] boolValue];
    dispatch_async(dispatch_get_main_queue(),^{
        if (expanded) DFEnterFullscreen(); else DFExitFullscreen();
    });
}
@end
static DFZoomReceiver *DFReceiver;
BOOL DFStartFullscreenAdapter(void) {
    NSCAssert(NSThread.isMainThread,@"main thread");
    if (DFAdapterStarted) return YES;
    NSString *bundle=NSBundle.mainBundle.bundleIdentifier.lowercaseString;
    if ([bundle isEqualToString:@"com.apple.springboard"]) {
        if (!DFStartFullscreenTransport(YES,nil)) return NO;
        DFAdapterStarted=DFInstallPickerZoomMenuHooks();
        return DFAdapterStarted;
    }
    if (![@[@"com.apple.carplayapp",@"com.apple.carplay",@"com.apple.dashboard"]
        containsObject:bundle]) return NO;
    if (!DFInstallDashboardChromeHooks()) return NO;
    if (!DFStartFullscreenTransport(NO,^(NSDictionary *state) {
        BOOL active=[state[@"active"] boolValue], expanded=[state[@"expanded"] boolValue];
        if (!active && DFHostActive) ++DFTransitionGeneration;
        DFHostActive=active;
        if (!active || !expanded) {
            DFDashboardRestoreChrome();
            DFFullscreenConfirmed=NO; DFTransitionPending=NO;
        }
    })) return NO;
    Class cls=NSClassFromString(@"NSDistributedNotificationCenter");
    id center=[cls respondsToSelector:@selector(defaultCenter)]?[cls defaultCenter]:nil;
    if (![center respondsToSelector:@selector(addObserver:selector:name:object:)]) return NO;
    DFReceiver=[DFZoomReceiver new];
    [center addObserver:DFReceiver selector:@selector(received:)
                  name:DFMenuZoomEvent object:nil];
    DFAdapterStarted=YES; return YES;
}
