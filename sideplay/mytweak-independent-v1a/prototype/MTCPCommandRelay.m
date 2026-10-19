#import "MTCPCommandRelay.h"
#import "MTCPBridgeContract.h"
#import <notify.h>
@interface MTCPCommandRelay ()
@property(nonatomic,copy) NSString *session;
@property(nonatomic,copy) void (^handler)(NSDictionary *message);
@property(nonatomic,assign) unsigned long long lastSequence;
@property(nonatomic,assign) int token;
@end
@implementation MTCPCommandRelay
- (BOOL)startForSession:(NSString *)session handler:(void (^)(NSDictionary *))handler {
    if (self.session || ![NSThread isMainThread] ||
        ![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"] ||
        !MTCPBridgeExplicitOptIn() || session.length!=36 || !handler)return NO;
    self.session=[session copy];self.handler=[handler copy];self.lastSequence=0;
    self.token=-1;
    __weak typeof(self) weakSelf=self;
    int result=notify_register_dispatch("com.duoface.mytweak.cp-command",
                       &_token,dispatch_get_main_queue(),^(int token) {
        (void)token;
        typeof(self) strongSelf=weakSelf;
        if (!strongSelf || !MTCPBridgeExplicitOptIn())return;
        NSDictionary *record=MTCPBridgeReadCommand(strongSelf.session,strongSelf.lastSequence);
        if (!record)return;
        strongSelf.lastSequence=[record[@"Sequence"] unsignedLongLongValue];
        if (strongSelf.handler)strongSelf.handler(record);
    });
    if (result!=NOTIFY_STATUS_OK) { [self stop];return NO; }
    return YES;
}
- (void)stop {
    if (_token>=0)notify_cancel(_token);
    _token=-1;self.session=nil;self.handler=nil;self.lastSequence=0;
}
- (void)dealloc { [self stop]; }
@end
