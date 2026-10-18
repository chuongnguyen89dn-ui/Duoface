#import "DFCarPlayBridgeAPI.h"
#import "DFIRuntime.h"
#import "../DFILayouts.h"
#import <math.h>

NSString *const DFCarPlayErrorDomain = @"com.duoface.carplay.bridge";

static NSError *DFCPError(DFCarPlayErrorCode code, NSString *text) {
    return [NSError errorWithDomain:DFCarPlayErrorDomain
                              code:code
                          userInfo:@{NSLocalizedDescriptionKey:text}];
}
static BOOL DFCPMainThread(void) {
    return [NSThread isMainThread];
}
static void DFCPLog(NSString *event, NSUInteger pane, NSString *detail) {
    NSLog(@"DuoFace DFCarPlay event=%@ pane=%lu %@",event,
          (unsigned long)pane,detail ?: @"");
}

@interface DFCarPlaySplitCoordinator ()
@property(nonatomic,strong) UIViewController *root;
@property(nonatomic,copy) NSArray<UIView *> *panes;
@property(nonatomic,strong) NSMutableArray *hosts; // DFV12SceneHost or NSNull (one per pane)
@property(nonatomic,strong) NSMutableDictionary<NSNumber *,DFCarPlayCompletion> *pending;
@property(nonatomic,readwrite) BOOL started;
@property(nonatomic) CGFloat ratio;
@property(nonatomic) CGFloat secondaryRatio;
@property(nonatomic) NSInteger layoutKind;
@property(nonatomic) NSInteger focused;
@end

@implementation DFCarPlaySplitCoordinator
- (instancetype)initWithRootController:(UIViewController *)root
                                  panes:(NSArray<UIView *> *)panes
                                  error:(NSError **)error {
    if (!root || (panes.count != 2 && panes.count != 3) || panes[0] == panes[1] ||
        ![panes[0] isKindOfClass:UIView.class] ||
        ![panes[1] isKindOfClass:UIView.class]) {
        if (error) *error=DFCPError(DFCarPlayErrorInvalidRequest,
                                   @"Two or three distinct pane views and one root are required");
        return nil;
    }
    if (panes.count==3 && (![panes[2] isKindOfClass:UIView.class] ||
        panes[2]==panes[0] || panes[2]==panes[1])) {
        if (error) *error=DFCPError(DFCarPlayErrorInvalidRequest,
                                   @"Three distinct pane views are required");
        return nil;
    }
    if (!(self=[super init])) return nil;
    _root=root;
    _panes=[panes copy];
    _hosts=[NSMutableArray array];
    for (NSUInteger i=0; i<panes.count; i++) [_hosts addObject:NSNull.null];
    _pending=[NSMutableDictionary dictionary];
    _ratio=.5;
    _secondaryRatio=.5;
    _layoutKind=panes.count==3?5:2;
    _focused=-1;
    return self;
}
- (NSError *)ownerError {
    if (!DFCPMainThread())
        return DFCPError(DFCarPlayErrorUnavailable,@"SpringBoard main thread required");
    if (![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"])
        return DFCPError(DFCarPlayErrorUnavailable,@"SpringBoard owner required");
    if (NSClassFromString(@"CBBridgeManager"))
        return DFCPError(DFCarPlayErrorUnavailable,@"Legacy scene owner present; refusing second owner");
    UIWindow *window=self.root.view.window;
    Class externalWindow=NSClassFromString(@"UIRootSceneWindow");
    if (!window || window.hidden || window.rootViewController!=self.root ||
        !externalWindow || ![window isKindOfClass:externalWindow])
        return DFCPError(DFCarPlayErrorUnavailable,@"Existing CarPlay root window is not attached");
    for (UIView *pane in self.panes)
        if (![pane isDescendantOfView:self.root.view])
            return DFCPError(DFCarPlayErrorInvalidRequest,@"Pane is not inside the host root");
    return nil;
}
- (void)startWithCompletion:(DFCarPlayCompletion)done {
    if (!DFCPMainThread()) {
        dispatch_async(dispatch_get_main_queue(),^{[self startWithCompletion:done];});
        return;
    }
    NSError *error=[self ownerError];
    self.started=(error==nil);
    if (self.started) [self layoutPanes];
    DFCPLog(error?@"start-refused":@"start-ready",0,error.localizedDescription);
    if (done) done(error);
}
- (void)finishPane:(NSUInteger)pane host:(DFV12SceneHost *)host error:(NSError *)error {
    if (pane>=self.panes.count || self.hosts[pane]!=host) return;
    NSNumber *key=@(pane);
    DFCarPlayCompletion done=self.pending[key];
    [self.pending removeObjectForKey:key];
    if (error) {
        [host close];
        self.hosts[pane]=NSNull.null;
    }
    DFCPLog(error?@"scene-failed":@"scene-attached",pane,
            error.localizedDescription ?: host.bundleID);
    if (done) done(error);
}
- (void)openApp:(NSString *)bundleID inPane:(NSUInteger)pane
    completion:(DFCarPlayCompletion)done {
    if (!DFCPMainThread()) {
        dispatch_async(dispatch_get_main_queue(),^{
            [self openApp:bundleID inPane:pane completion:done];
        });
        return;
    }
    NSError *error=self.started?[self ownerError]:
        DFCPError(DFCarPlayErrorUnavailable,@"Bridge has not started");
    if (!error && (pane>=self.panes.count || ![bundleID isKindOfClass:NSString.class] || !bundleID.length))
        error=DFCPError(DFCarPlayErrorInvalidRequest,@"Invalid bundle identifier or pane");
    if (!error && self.pending[@(pane)])
        error=DFCPError(DFCarPlayErrorBusy,@"Pane is still opening");
    if (!error) {
        for (NSUInteger i=0;i<self.panes.count;i++) {
            DFV12SceneHost *other=self.hosts[i]==NSNull.null?nil:self.hosts[i];
            if (other && [other.bundleID isEqualToString:bundleID]) {
                error=DFCPError(DFCarPlayErrorBusy,@"Bundle already hosted in another pane");
                break;
            }
        }
    }
    if (error) {
        DFCPLog(@"open-refused",pane,error.localizedDescription);
        if (done) done(error);
        return;
    }
    DFV12SceneHost *host=[[DFV12SceneHost alloc]initWithBundleID:bundleID error:&error];
    if (!host) {
        if (done) done(error ?: DFCPError(DFCarPlayErrorSceneFailed,@"Could not create scene host"));
        return;
    }
    DFV12SceneHost *previous=self.hosts[pane]==NSNull.null?nil:self.hosts[pane];
    if (previous) [previous close];
    self.hosts[pane]=host;
    // A nil callback must still reserve the slot until ACK or failure.
    DFCarPlayCompletion completion=done ?: ^(NSError *ignored) { (void)ignored; };
    self.pending[@(pane)]=[completion copy];
    __weak typeof(self) weakSelf=self;
    __weak DFV12SceneHost *weakHost=host;
    host.ready=^{
        DFCarPlaySplitCoordinator *strong=weakSelf;
        DFV12SceneHost *active=weakHost;
        if (strong && active) [strong finishPane:pane host:active error:nil];
    };
    host.failure=^(NSString *reason) {
        DFCarPlaySplitCoordinator *strong=weakSelf;
        DFV12SceneHost *active=weakHost;
        if (strong && active)
            [strong finishPane:pane host:active
                         error:DFCPError(DFCarPlayErrorSceneFailed,reason ?: @"Scene detached")];
    };
    @try {
        [host attachTo:self.root container:self.panes[pane]];
        [host resizeTo:self.panes[pane].bounds.size];
        DFCPLog(@"scene-pending",pane,bundleID);
    } @catch (NSException *exception) {
        [self finishPane:pane host:host
                  error:DFCPError(DFCarPlayErrorSceneFailed,
                                  exception.reason ?: @"Attach exception")];
    }
}
- (void)cancelAndClose:(NSUInteger)pane {
    if (pane>=self.panes.count) return;
    DFV12SceneHost *host=self.hosts[pane]==NSNull.null?nil:self.hosts[pane];
    DFCarPlayCompletion done=self.pending[@(pane)];
    [self.pending removeObjectForKey:@(pane)];
    // Clear callbacks BEFORE teardown, so a late scene timer cannot resurrect a pane.
    if (host) {
        host.ready=nil; host.failure=nil;
        [host close];
        self.hosts[pane]=NSNull.null;
    }
    if (done) done(DFCPError(DFCarPlayErrorCancelled,@"Scene opening cancelled"));
    DFCPLog(@"pane-closed",pane,nil);
}
- (void)closePane:(NSUInteger)pane {
    if (!DFCPMainThread()) {
        dispatch_async(dispatch_get_main_queue(),^{[self closePane:pane];});
        return;
    }
    [self cancelAndClose:pane];
}
- (void)layoutPanes {
    if (!self.started) return;
    CGRect r=self.root.view.bounds;
    if (CGRectIsEmpty(r) || !isfinite(r.size.width) || !isfinite(r.size.height)) return;
    DFIFrames frames=DFIFramesMake(r,(int)self.layoutKind,self.ratio,self.secondaryRatio,(int)self.focused);
    for (NSUInteger i=0;i<self.panes.count;i++) {
        BOOL focus=self.focused>=0;
        self.panes[i].hidden=(focus && (NSInteger)i!=self.focused) || (!focus && i>=(NSUInteger)frames.count);
        self.panes[i].frame=frames.panes[i];
        DFV12SceneHost *host=self.hosts[i]==NSNull.null?nil:self.hosts[i];
        if (host && !self.panes[i].hidden) [host resizeTo:self.panes[i].bounds.size];
    }
}
- (void)setSplitRatio:(CGFloat)ratio {
    if (!DFCPMainThread()) {
        dispatch_async(dispatch_get_main_queue(),^{[self setSplitRatio:ratio];});
        return;
    }
    if (!isfinite(ratio)) return;
    self.ratio=MAX(.10,MIN(.90,ratio));
    [self layoutPanes];
}
- (void)setLayoutKind:(NSInteger)kind fraction:(CGFloat)fraction secondary:(CGFloat)secondary {
    if (!DFCPMainThread()) {
        dispatch_async(dispatch_get_main_queue(),^{[self setLayoutKind:kind fraction:fraction secondary:secondary];});
        return;
    }
    if (kind<1 || kind>8 || !isfinite(fraction) || !isfinite(secondary)) return;
    if (kind>=4 && self.panes.count<3) return;
    self.layoutKind=kind;
    self.ratio=MAX(.02,MIN(.98,fraction));
    self.secondaryRatio=MAX(.02,MIN(.98,secondary));
    [self layoutPanes];
}
- (void)swapPanes {
    if (!DFCPMainThread()) {
        dispatch_async(dispatch_get_main_queue(),^{[self swapPanes];});
        return;
    }
    // Never swap while an async attach is in progress.
    if (!self.started || self.pending.count) return;
    id first=self.hosts[0];
    self.hosts[0]=self.hosts[1];
    self.hosts[1]=first;
    for (NSUInteger i=0;i<self.panes.count;i++) {
        DFV12SceneHost *host=self.hosts[i]==NSNull.null?nil:self.hosts[i];
        if (host) [host moveToContainer:self.panes[i]];
    }
    [self layoutPanes];
    DFCPLog(@"panes-swapped",0,nil);
}
- (void)focusPane:(NSUInteger)pane {
    if (!DFCPMainThread()) {
        dispatch_async(dispatch_get_main_queue(),^{[self focusPane:pane];});
        return;
    }
    if (!self.started || pane>=self.panes.count) return;
    self.focused=(NSInteger)pane;
    [self layoutPanes];
}
- (void)restoreSplit {
    if (!DFCPMainThread()) {
        dispatch_async(dispatch_get_main_queue(),^{[self restoreSplit];});
        return;
    }
    self.focused=-1;
    [self layoutPanes];
}
- (BOOL)hasLiveSceneInPane:(NSUInteger)pane {
    if (!DFCPMainThread() || pane>=self.panes.count) return NO;
    DFV12SceneHost *host=self.hosts[pane]==NSNull.null?nil:self.hosts[pane];
    return host.scene!=nil;
}
- (void)stop {
    if (!DFCPMainThread()) {
        dispatch_async(dispatch_get_main_queue(),^{[self stop];});
        return;
    }
    for (NSUInteger i=0;i<self.panes.count;i++) [self cancelAndClose:i];
    self.started=NO;
    self.focused=-1;
    // The single external UIWindow belongs to the caller; never destroy it here.
    DFCPLog(@"coordinator-stopped",0,nil);
}
@end
