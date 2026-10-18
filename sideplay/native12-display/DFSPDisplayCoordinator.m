#import "DFSPDisplayCoordinator.h"

@interface DFSPDisplayCoordinator ()
@property(nonatomic,copy) DFSPDisplayOwnerPort hostPort;
@property(nonatomic,copy) DFSPDisplayOwnerPort chromePort;
@end
@implementation DFSPDisplayCoordinator {
    DFSPDisplay _display;
}
- (instancetype)initWithHostPort:(DFSPDisplayOwnerPort)host
                      chromePort:(DFSPDisplayOwnerPort)chrome {
    NSParameterAssert(host && chrome);
    if ((self=[super init])) {
        _hostPort=[host copy];
        _chromePort=[chrome copy];
        DFSPDisplayInit(&_display);
    }
    return self;
}
- (DFSPMode)mode { return _display.mode; }
- (BOOL)fullscreenConfirmed { return DFSPDisplayIsFull(&_display); }
- (NSString *)zoomAccessibilityLabel {
    return [NSString stringWithUTF8String:DFSPDisplayZoomLabel(&_display)];
}
- (void)dispatchStep:(DFSPStep)step {
    NSCAssert(NSThread.isMainThread,@"CarPlay display events must be on main thread");
    if (step == DFSP_NONE || !_display.connected) return;
    uint64_t token = _display.transaction;
    BOOL isHost=(step==DFSP_APPLY_HOST_NORMAL || step==DFSP_APPLY_HOST_FULL);
    BOOL enabled=(step==DFSP_APPLY_HOST_FULL || step==DFSP_HIDE_SYSTEM_BAR);
    DFSPDisplayOwnerPort port=isHost?self.hostPort:self.chromePort;
    if (!port) {
        DFSPStep next=DFSPDisplayAck(&_display,token,step,false);
        if (next!=DFSP_NONE) [self dispatchStep:next];
        return;
    }
    __weak typeof(self) weakSelf=self;
    port(enabled,token,^(BOOL applied){
        dispatch_async(dispatch_get_main_queue(),^{
            typeof(self) strongSelf=weakSelf;
            if (!strongSelf) return;
            // Drop delayed ACK from an older session or different operation.
            if (!strongSelf->_display.connected ||
                strongSelf->_display.transaction!=token ||
                strongSelf->_display.waiting!=step) return;
            DFSPStep next=DFSPDisplayAck(&strongSelf->_display,token,step,applied);
            [strongSelf dispatchStep:next];
        });
    });
}
- (void)carPlayDidConnect {
    NSCAssert(NSThread.isMainThread,@"Main thread required");
    if (_display.connected) return;
    [self dispatchStep:DFSPDisplayConnect(&_display)];
}
- (void)existingNativeZoomPressed {
    NSCAssert(NSThread.isMainThread,@"Main thread required");
    DFSPStep step=DFSP_NONE;
    if (DFSPDisplayIsFull(&_display)) step=DFSPDisplayZoomOut(&_display);
    else if (_display.mode==DFSP_NORMAL) step=DFSPDisplayZoomIn(&_display);
    [self dispatchStep:step];
}
- (void)carPlayWillDisconnect {
    NSCAssert(NSThread.isMainThread,@"Main thread required");
    if (!_display.connected) return;
    DFSPDisplayDisconnect(&_display);
    // Best effort: do not wait for an ACK from a scene being destroyed.
    // The real window owner must release its snapshot during teardown.
    uint64_t token=_display.transaction;
    self.chromePort(NO,token,^(BOOL unused){ (void)unused; });
    self.hostPort(NO,token,^(BOOL unused){ (void)unused; });
}
@end
