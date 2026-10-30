// Independent app-side half of the verified Native12 host -> app -> UIKit flow.
// No swizzling, global UIDevice orientation, player hooks or lifecycle spoofing.
#import <UIKit/UIKit.h>
#import "DFYouTubeHostState.h"
#import "DFYouTubeOrientationVirtualization.h"

@interface DFYTWindowSnapshot : NSObject
@property(nonatomic) CGRect frame;
@property(nonatomic) CGRect bounds;
@property(nonatomic) UIInterfaceOrientation orientation;
@end
@implementation DFYTWindowSnapshot
@end

@interface DFYouTubeOrientationRelay : NSObject
@property(nonatomic,copy) NSDictionary *state;
@property(nonatomic,weak) UIWindowScene *scene;
@property(nonatomic,strong) NSMapTable<UIWindow *,DFYTWindowSnapshot *> *snapshots;
@property(nonatomic,strong) NSTimer *expiryTimer;
@property(nonatomic) NSTimeInterval newestStamp;
@property(nonatomic) BOOL applying;
@property(nonatomic,copy) NSString *lastGeometryCheckKey;
- (void)receive:(NSNotification *)notification;
- (void)request:(NSNotification *)notification;
- (void)windowVisible:(NSNotification *)notification;
- (void)reset;
- (void)apply;
@end
@implementation DFYouTubeOrientationRelay
- (void)request:(NSNotification *)notification {
    (void)notification;
    DFYTPost(DFYTRequestName,@{@"bundleIdentifier":DFYTBundle});
}
- (void)receive:(NSNotification *)notification {
    NSDictionary *state=[notification.userInfo copy];
    dispatch_async(dispatch_get_main_queue(),^{
        NSTimeInterval now=NSDate.date.timeIntervalSince1970;
        if(!DFYTShouldAccept(state,self.state,now,self.newestStamp))return;
        self.newestStamp=[state[@"issuedAt"] doubleValue];
        if(![state[@"active"] boolValue]) {
            if([state[@"owner"] isEqual:self.state[@"owner"]])[self reset];
            return;
        }
        BOOL sameOwner=[state[@"owner"] isEqual:self.state[@"owner"]] &&
            [state[@"sceneIdentifier"] isEqual:self.state[@"sceneIdentifier"]];
        BOOL changed=!sameOwner || ![state[@"width"] isEqual:self.state[@"width"]] ||
            ![state[@"height"] isEqual:self.state[@"height"]] ||
            ![state[@"isSplit"] isEqual:self.state[@"isSplit"]];
        if(!sameOwner)[self reset];
        self.state=state;
        if(!self.expiryTimer) {
            __weak typeof(self) weakSelf=self;
            self.expiryTimer=[NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer *timer){
                (void)timer;
                DFYouTubeOrientationRelay *owner=weakSelf;
                if(owner && !DFYTValidState(owner.state,NSDate.date.timeIntervalSince1970))[owner reset];
            }];
            [NSRunLoop.mainRunLoop addTimer:self.expiryTimer forMode:NSRunLoopCommonModes];
        }
        // Heartbeats renew a lease, never continuously rotate a video player.
        if(changed || !self.scene)[self apply];
        else DFYTVirtualUpdateLease(state,self.scene);
    });
}
- (void)windowVisible:(NSNotification *)notification {
    // QA127: UIKit posts UIWindowDidBecomeVisible for ALL process windows,
    // including unrelated splash, controls and overlays. QA125 responded
    // to every such event by reflowing ALL hosted YouTube windows; repeated
    // visibility notifications can become a layout-feedback loop.
    // Reconcile only when the event belongs to the exact leased scene.
    // Preserve genuine owned-window/scene activation needed after Control
    // Center (QA90 portrait rotation must remain unchanged).
    id subject=notification.object;
    if(![subject isKindOfClass:UIWindow.class] &&
       ![subject isKindOfClass:UIWindowScene.class])return;
    dispatch_async(dispatch_get_main_queue(),^{
        UIWindowScene *owned=self.scene;
        if(!owned || !DFYTValidState(self.state,NSDate.date.timeIntervalSince1970))return;
        if([subject isKindOfClass:UIWindow.class]) {
            UIWindow *window=(UIWindow *)subject;
            if(window.windowScene!=owned || window.hidden ||
               window.windowLevel!=UIWindowLevelNormal ||
               !window.rootViewController)return;
        } else if(subject!=owned)return;
        [self apply];
    });
}
- (void)apply {
    if(self.applying || !DFYTValidState(self.state,NSDate.date.timeIntervalSince1970))return;
    UIWindowScene *owned=nil;
    for(UIScene *candidate in UIApplication.sharedApplication.connectedScenes) {
        if([candidate isKindOfClass:UIWindowScene.class] &&
           [DFYTObject(candidate,@"_sceneIdentifier") isEqual:self.state[@"sceneIdentifier"]]) {
            owned=(UIWindowScene *)candidate; break;
        }
    }
    // Main-display scenes ARE allowed, but only with exact server/client ID.
    // External display or bundle-name equality alone is never ownership proof.
    if(!owned) {
        DFYTPost(DFYTAckName,@{@"owner":self.state[@"owner"],@"sceneIdentifier":self.state[@"sceneIdentifier"],
                            @"phase":@"scene-id-unmatched",@"bundleIdentifier":DFYTBundle});
        return;
    }
    if(self.scene && self.scene!=owned)[self reset];
    if(!self.state)return;
    self.scene=owned;
    DFYTVirtualUpdateLease(self.state,owned);
    if(!self.snapshots)self.snapshots=[NSMapTable weakToStrongObjectsMapTable];
    self.applying=YES;
    CGSize size=CGSizeMake([self.state[@"width"] doubleValue],[self.state[@"height"] doubleValue]);
    NSUInteger applied=0, windowsFromScene=0, windowsFromInternal=0, layoutRefreshes=0;
    NSMutableArray *measurements=[NSMutableArray array];
    NSMutableArray<UIWindow *> *mismatched=[NSMutableArray array];
    @try {
        // .87 only searched UIWindowScene.windows and could leave YouTube's
        // internal video presentation window untouched. Native12 original
        // UIKit reconciler checks both normal and internal window enumerators.
        // Keep the exact owned UIWindowScene and normal-level guard below.
        NSMutableOrderedSet<UIWindow *> *candidates=[NSMutableOrderedSet orderedSet];
        for(UIWindow *window in owned.windows) {
            if([window isKindOfClass:UIWindow.class]) {
                [candidates addObject:window]; ++windowsFromScene;
            }
        }
        NSArray *internal=DFYTVisibleInternalWindows();
        for(id object in internal) {
            if([object isKindOfClass:UIWindow.class] && ((UIWindow *)object).windowScene==owned) {
                [candidates addObject:(UIWindow *)object]; ++windowsFromInternal;
            }
        }
        for(UIWindow *window in candidates) {
            if(window.windowScene!=owned || window.hidden || window.windowLevel!=UIWindowLevelNormal ||
               !window.rootViewController || [NSStringFromClass(window.class) containsString:@"Keyboard"] ||
               [NSStringFromClass(window.class) containsString:@"TextEffects"])continue;
            if(!DFYTRotationABI(window))continue;
            DFYTWindowSnapshot *saved=[self.snapshots objectForKey:window];
            if(saved && CGSizeEqualToSize(window.bounds.size,size) &&
               window.rootViewController.interfaceOrientation==UIInterfaceOrientationPortrait) {
                // Focus/Control-Center gestures can force a later UIKit reflow
                // without changing frame or reported orientation. Native12
                // uses the distinct layout invalidation selector after rotate.
                [window setNeedsLayout]; [window layoutIfNeeded];
                [window.rootViewController.view setNeedsLayout];
                [window.rootViewController.view layoutIfNeeded];
                ++layoutRefreshes;
                continue;
            }
            if(!saved) {
                saved=[DFYTWindowSnapshot new]; saved.frame=window.frame; saved.bounds=window.bounds;
                saved.orientation=window.rootViewController.interfaceOrientation;
                if(saved.orientation<1 || saved.orientation>4)continue;
                // Save before rotating: even an exception must remain restorable.
                [self.snapshots setObject:saved forKey:window];
            }
            if(!DFYTRotate(window,UIInterfaceOrientationPortrait))continue;
            window.frame=(CGRect){CGPointZero,size}; window.bounds=(CGRect){CGPointZero,size};
            [window setNeedsLayout]; [window layoutIfNeeded];
            [window.rootViewController.view setNeedsLayout]; [window.rootViewController.view layoutIfNeeded];
            ++layoutRefreshes;
            ++applied;
            if(window.rootViewController.interfaceOrientation!=UIInterfaceOrientationPortrait)
                [mismatched addObject:window];
            if(measurements.count<8)[measurements addObject:@{
                @"width":@(window.bounds.size.width),@"height":@(window.bounds.size.height),
                @"orientation":@(window.rootViewController.interfaceOrientation),
                @"rootClass":NSStringFromClass(window.rootViewController.class)?:@"unknown"}];
        }
        // The real .88 SceneHost log at lines 7238-7244 proves a root controller
        // still reported orientation=3 AFTER a successful private UIWindow call
        // in a Portrait scene=1. Native SidePlay's app-process flow additionally
        // requests UIKit geometry/supported-orientation re-evaluation.
        // Do that only for a live two-pane owner with an observed mismatch;
        // never infer a landscape target from the car's screen dimensions.
        NSString *geometryRequest=@"no-controller-mismatch";
        BOOL split=[self.state[@"isSplit"] boolValue];
        if(mismatched.count && !split) geometryRequest=@"single-pane-no-request";
        if(mismatched.count && split) {
            NSString *key=[NSString stringWithFormat:@"%@|%@|%@|%.0fx%.0f",
                self.state[@"owner"],self.state[@"sceneIdentifier"],
                self.state[@"isSplit"],size.width,size.height];
            if(![key isEqualToString:self.lastGeometryCheckKey]) {
                self.lastGeometryCheckKey=key;
                geometryRequest=@"delayed-controller-readback";
                __weak typeof(self) weakRelay=self;
                __weak UIWindow *weakWindow=mismatched.firstObject;
                UIWindowScene *expectedScene=owned;
                NSString *expectedOwner=[self.state[@"owner"] copy];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.12*NSEC_PER_SEC)),
                               dispatch_get_main_queue(), ^{
                    DFYouTubeOrientationRelay *relay=weakRelay;
                    UIWindow *target=weakWindow;
                    if(!relay || !target || !DFYTValidState(relay.state,NSDate.date.timeIntervalSince1970) ||
                       ![relay.state[@"owner"] isEqual:expectedOwner] ||
                       ![relay.state[@"isSplit"] boolValue] || relay.scene!=expectedScene ||
                       target.windowScene!=expectedScene ||
                       target.hidden || target.windowLevel!=UIWindowLevelNormal ||
                       ![UIApplication.sharedApplication.connectedScenes containsObject:expectedScene])return;
                    UIViewController *controller=target.rootViewController;
                    if(!controller || controller.interfaceOrientation==UIInterfaceOrientationPortrait)return;
                    // UIKit iOS16 counterpart of original app-side orientation
                    // geometry/supported-orientation invalidation, not a global
                    // UIDevice rotate, player hook or FrontBoard scene writer.
                    if(@available(iOS 16.0,*)) {
                        [controller setNeedsUpdateOfSupportedInterfaceOrientations];
                        UIWindowSceneGeometryPreferencesIOS *preferences=
                            [[UIWindowSceneGeometryPreferencesIOS alloc]
                                  initWithInterfaceOrientations:UIInterfaceOrientationMaskPortrait];
                        [expectedScene requestGeometryUpdateWithPreferences:preferences
                            errorHandler:^(NSError *error) {
                            if(![relay.state[@"owner"] isEqual:expectedOwner] ||
                               relay.scene!=expectedScene)return;
                            DFYTPost(DFYTAckName,@{
                                @"bundleIdentifier":DFYTBundle,@"owner":expectedOwner,
                                @"sceneIdentifier":relay.state[@"sceneIdentifier"],
                                @"phase":@"geometry-request-rejected",
                                @"errorCode":@(error.code),
                                @"sceneOrientation":@(expectedScene.interfaceOrientation)});
                        }];
                        DFYTPost(DFYTAckName,@{
                            @"bundleIdentifier":DFYTBundle,@"owner":expectedOwner,
                            @"sceneIdentifier":relay.state[@"sceneIdentifier"],
                            @"phase":@"geometry-request-issued",
                            @"controllerOrientation":@(controller.interfaceOrientation),
                            @"sceneOrientation":@(expectedScene.interfaceOrientation)});
                    }
                });
            } else geometryRequest=@"already-checked-this-layout";
        }
        DFYTPost(DFYTAckName,@{@"bundleIdentifier":DFYTBundle,@"owner":self.state[@"owner"],
            @"sceneIdentifier":self.state[@"sceneIdentifier"],@"phase":@"app-reflow-measured",
            @"windowsApplied":@(applied),@"windows":measurements,
            @"sceneWindowCount":@(windowsFromScene),@"internalWindowCount":@(windowsFromInternal),
            @"layoutRefreshes":@(layoutRefreshes),
            @"controllerMismatch":@(mismatched.count),
            @"geometryRequest":geometryRequest,
            @"virtualization":DFYTVirtualSnapshot(),
            @"sceneOrientation":@(owned.interfaceOrientation),
            @"sceneWidth":@(owned.coordinateSpace.bounds.size.width),
            @"sceneHeight":@(owned.coordinateSpace.bounds.size.height)});
    } @catch(NSException *error) {
        NSLog(@"[DuoFaceYouTube] reflow failed %@",error.name);
        [self reset];
    } @finally {self.applying=NO;}
}
- (void)reset {
    [self.expiryTimer invalidate]; self.expiryTimer=nil;
    UIWindowScene *scene=self.scene;
    DFYTVirtualClearLease();
    self.state=nil; self.scene=nil; self.lastGeometryCheckKey=nil;
    // Restore ONLY windows we changed and which still belong to that scene.
    for(UIWindow *window in self.snapshots.keyEnumerator) {
        if(window.windowScene!=scene || ![UIApplication.sharedApplication.connectedScenes containsObject:scene])continue;
        DFYTWindowSnapshot *saved=[self.snapshots objectForKey:window];
        @try {
            DFYTRotate(window,saved.orientation);
            window.frame=saved.frame; window.bounds=saved.bounds;
            [window setNeedsLayout]; [window layoutIfNeeded];
        } @catch(NSException *error) {NSLog(@"[DuoFaceYouTube] restore failed %@",error.name);}
    }
    [self.snapshots removeAllObjects];
}
@end
__attribute__((constructor)) static void DFYTStart(void) {
    @autoreleasepool {
        if(![NSBundle.mainBundle.bundleIdentifier isEqual:DFYTBundle] ||
           NSProcessInfo.processInfo.operatingSystemVersion.majorVersion!=16 ||
           NSBundle.mainBundle.infoDictionary[@"NSExtension"])return;
        dispatch_async(dispatch_get_main_queue(),^{
            static DFYouTubeOrientationRelay *relay;
            id center=DFYTCenter(); if(!center)return;
            relay=[DFYouTubeOrientationRelay new];
            DFYTVirtualInstall();
            [center addObserver:relay selector:@selector(receive:) name:DFYTStateName object:nil];
            [NSNotificationCenter.defaultCenter addObserver:relay selector:@selector(request:)
                name:UIApplicationDidBecomeActiveNotification object:nil];
            [NSNotificationCenter.defaultCenter addObserver:relay selector:@selector(windowVisible:)
                name:UIWindowDidBecomeVisibleNotification object:nil];
            [NSNotificationCenter.defaultCenter addObserver:relay selector:@selector(windowVisible:)
                name:UISceneDidActivateNotification object:nil];
            [relay request:nil];
        });
    }
}
