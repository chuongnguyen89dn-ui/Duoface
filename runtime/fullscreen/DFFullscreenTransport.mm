#import "DFFullscreenTransport.h"
#import "DFHostGeometry.h"
#import <objc/message.h>

// Separate namespace prevents collisions with an installed copy of Airaw.
static NSString * const DFCommandEvent = @"com.duoface.fullscreen.command.v1";
static NSString * const DFStateEvent = @"com.duoface.fullscreen.state.v1";
static const NSTimeInterval DFLeaseSeconds = 6.0;

@interface NSObject (DFDistributedCenterSelectors)
+ (id)defaultCenter;
- (void)addObserver:(id)observer selector:(SEL)selector name:(NSString *)name object:(id)object;
- (void)postNotificationName:(NSString *)name object:(id)object userInfo:(NSDictionary *)info;
@end

@interface DFFullscreenTransport : NSObject
@property(nonatomic, strong) id center;
@property(nonatomic) BOOL host;
@property(nonatomic, copy) NSString *client;
@property(nonatomic) NSUInteger sequence;
@property(nonatomic, copy) NSString *pendingID;
@property(nonatomic) BOOL pendingEnabled;
@property(nonatomic, copy) void (^pendingCompletion)(BOOL, NSString *);
@property(nonatomic, copy) void (^stateChanged)(NSDictionary *);
@property(nonatomic) BOOL ownsFullscreen;
@property(nonatomic) BOOL desiredExpanded;
@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic, copy) NSString *leaseOwner;
@property(nonatomic) NSTimeInterval leaseDeadline;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *lastSequences;
- (void)received:(NSNotification *)notification;
- (void)send:(NSString *)operation enabled:(BOOL)enabled requestID:(NSString *)requestID;
- (void)publish:(NSString *)requestID client:(NSString *)client reason:(NSString *)reason;
- (void)handleCommand:(NSDictionary *)info;
- (void)handleState:(NSDictionary *)info;
@end

static DFFullscreenTransport *DFTransport;
static NSTimeInterval DFNow(void) { return NSProcessInfo.processInfo.systemUptime; }
static BOOL DFToken(id token) {
    return [token isKindOfClass:NSString.class] && [token length] > 0 && [token length] <= 64;
}

@implementation DFFullscreenTransport
- (void)post:(NSString *)name info:(NSDictionary *)info {
    [self.center postNotificationName:name object:nil userInfo:info];
}
- (void)send:(NSString *)operation enabled:(BOOL)enabled requestID:(NSString *)requestID {
    [self post:DFCommandEvent info:@{@"version":@1, @"client":self.client,
        @"sequence":@(++self.sequence), @"operation":operation,
        @"expanded":@(enabled), @"requestID":requestID ?: @""}];
}
- (void)publish:(NSString *)requestID client:(NSString *)client reason:(NSString *)reason {
    [self post:DFStateEvent info:@{@"version":@1, @"active":@(DFHostCanExpand()),
        @"expanded":@(DFHostIsExpanded()), @"requestID":requestID ?: @"",
        @"client":client ?: @"", @"owner":self.leaseOwner ?: @"",
        @"reason":reason ?: @""}];
}
- (void)received:(NSNotification *)notification {
    NSDictionary *info = [notification.userInfo copy];
    if (![info isKindOfClass:NSDictionary.class] || ![info[@"version"] isEqual:@1]) return;
    // Distributed notifications need not arrive on the UI thread.
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.host) [self handleCommand:info];
        else [self handleState:info];
    });
}
- (void)handleCommand:(NSDictionary *)info {
    NSString *client = info[@"client"], *operation = info[@"operation"];
    NSNumber *sequence = info[@"sequence"];
    if (!DFToken(client) || ![sequence isKindOfClass:NSNumber.class] ||
        sequence.unsignedLongLongValue == 0 || ![operation isKindOfClass:NSString.class]) return;
    NSUInteger previous = self.lastSequences[client].unsignedIntegerValue;
    if (sequence.unsignedLongLongValue <= previous) return;
    // Bound the retained sender set; never discard an active lease owner.
    if (!self.lastSequences[client] && self.lastSequences.count >= 16) {
        if (self.leaseOwner) return;
        [self.lastSequences removeAllObjects];
    }
    self.lastSequences[client] = sequence;
    if ([operation isEqualToString:@"query"]) {
        [self publish:nil client:client reason:nil]; return;
    }
    if ([operation isEqualToString:@"renew"]) {
        if ([client isEqualToString:self.leaseOwner] && DFHostIsExpanded())
            self.leaseDeadline = DFNow()+DFLeaseSeconds;
        return;
    }
    NSString *requestID = info[@"requestID"];
    if (![operation isEqualToString:@"set"] || !DFToken(requestID) ||
        ![info[@"expanded"] isKindOfClass:NSNumber.class]) return;
    BOOL enable = [info[@"expanded"] boolValue];
    if (self.leaseOwner && ![client isEqualToString:self.leaseOwner]) {
        [self publish:requestID client:client reason:@"host leased to another Dashboard session"];
        return;
    }
    NSString *reason = nil;
    BOOL applied = DFHostSetExpanded(enable, &reason);
    if (applied && enable) {
        self.leaseOwner = client; self.leaseDeadline = DFNow()+DFLeaseSeconds;
    } else if (!DFHostIsExpanded()) {
        self.leaseOwner = nil; self.leaseDeadline = 0;
    }
    [self publish:requestID client:client reason:reason];
}
- (void)handleState:(NSDictionary *)info {
    if (![info[@"active"] isKindOfClass:NSNumber.class] ||
        ![info[@"expanded"] isKindOfClass:NSNumber.class]) return;
    BOOL expanded = [info[@"expanded"] boolValue];
    BOOL ours = [info[@"owner"] isEqual:self.client];
    self.ownsFullscreen = expanded && ours && self.desiredExpanded;
    if (expanded && ours && !self.desiredExpanded) {
        [self send:@"set" enabled:NO requestID:NSUUID.UUID.UUIDString];
        return; // Ignore a late enter ACK after cancellation; do not renew its lease.
    }
    if (self.stateChanged) self.stateChanged(info);
    if (self.pendingID && [info[@"client"] isEqual:self.client] &&
        [info[@"requestID"] isEqual:self.pendingID]) {
        BOOL success = expanded == self.pendingEnabled && (!expanded || ours) &&
            [info[@"reason"] length] == 0;
        void (^completion)(BOOL, NSString *) = self.pendingCompletion;
        self.pendingID = nil; self.pendingCompletion = nil;
        if (completion) completion(success, info[@"reason"]);
    }
}
- (void)tick {
    if (self.host) {
        if (self.leaseOwner && (DFNow() > self.leaseDeadline || !DFHostIsExpanded())) {
            DFHostRestore(); self.leaseOwner = nil;
            [self publish:nil client:nil reason:@"host lease ended"];
        }
    } else if (self.ownsFullscreen) {
        [self send:@"renew" enabled:YES requestID:nil];
    } else if (!self.pendingID) {
        [self send:@"query" enabled:NO requestID:nil];
    }
}
@end

BOOL DFStartFullscreenTransport(BOOL springBoard, void (^stateChanged)(NSDictionary *)) {
    NSCAssert(NSThread.isMainThread, @"Transport starts on main thread");
    if (DFTransport) return DFTransport.host == springBoard;
    Class cls = NSClassFromString(@"NSDistributedNotificationCenter");
    if (![cls respondsToSelector:@selector(defaultCenter)]) return NO;
    id center = [cls defaultCenter];
    if (![center respondsToSelector:@selector(addObserver:selector:name:object:)] ||
        ![center respondsToSelector:@selector(postNotificationName:object:userInfo:)]) return NO;
    if (springBoard && !DFInstallHostGeometryHooks()) return NO;
    DFFullscreenTransport *transport = [DFFullscreenTransport new];
    transport.host = springBoard; transport.center = center;
    transport.client = NSUUID.UUID.UUIDString;
    transport.lastSequences = [NSMutableDictionary dictionary];
    transport.stateChanged = stateChanged;
    DFTransport = transport;
    [center addObserver:transport selector:@selector(received:)
        name:springBoard ? DFCommandEvent : DFStateEvent object:nil];
    transport.timer = [NSTimer scheduledTimerWithTimeInterval:2 target:transport
        selector:@selector(tick) userInfo:nil repeats:YES];
    if (springBoard) {
        DFHostSetLifecycleCallback(^{
            if (!DFHostIsExpanded()) {
                transport.leaseOwner = nil; transport.leaseDeadline = 0;
            }
            [transport publish:nil client:nil reason:nil];
        });
        [transport publish:nil client:nil reason:nil];
    } else DFQueryFullscreenHost();
    return YES;
}
void DFQueryFullscreenHost(void) {
    NSCAssert(NSThread.isMainThread, @"Host query must run on main thread");
    if (DFTransport && !DFTransport.host) [DFTransport send:@"query" enabled:NO requestID:nil];
}
void DFRequestHostFullscreen(BOOL expanded, void (^completion)(BOOL, NSString *)) {
    NSCAssert(NSThread.isMainThread, @"Host request must run on main thread");
    DFFullscreenTransport *transport = DFTransport;
    if (!transport || transport.host || transport.pendingID) {
        if (completion) completion(NO, @"transport unavailable or request pending");
        return;
    }
    NSString *requestID = NSUUID.UUID.UUIDString;
    transport.desiredExpanded = expanded;
    transport.pendingID = requestID; transport.pendingEnabled = expanded;
    transport.pendingCompletion = completion;
    [transport send:@"set" enabled:expanded requestID:requestID];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (![transport.pendingID isEqual:requestID]) return;
        void (^done)(BOOL, NSString *) = transport.pendingCompletion;
        transport.pendingID = nil; transport.pendingCompletion = nil;
        transport.ownsFullscreen = NO;
        transport.desiredExpanded = NO;
        // A newer sequence invalidates a delayed enter command; lease is a second rollback path.
        [transport send:@"set" enabled:NO requestID:NSUUID.UUID.UUIDString];
        if (done) done(NO, @"host acknowledgment timed out; restore requested");
    });
}
