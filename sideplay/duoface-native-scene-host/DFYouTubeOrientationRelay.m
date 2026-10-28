// Independent app-side half of the verified Native12 host -> app -> UIKit flow.
// No swizzling, global UIDevice orientation, player hooks or lifecycle spoofing.
#import <UIKit/UIKit.h>
#import "DFYouTubeHostState.h"

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
            ![state[@"height"] isEqual:self.state[@"height"]];
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
    });
}
- (void)windowVisible:(NSNotification *)notification {
    (void)notification;
    dispatch_async(dispatch_get_main_queue(),^{[self apply];});
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
    if(!self.snapshots)self.snapshots=[NSMapTable weakToStrongObjectsMapTable];
    self.applying=YES;
    CGSize size=CGSizeMake([self.state[@"width"] doubleValue],[self.state[@"height"] doubleValue]);
    NSUInteger applied=0;
    NSMutableArray *measurements=[NSMutableArray array];
    @try {
        for(UIWindow *window in owned.windows) {
            if(window.windowScene!=owned || window.hidden || window.windowLevel!=UIWindowLevelNormal ||
               !window.rootViewController || [NSStringFromClass(window.class) containsString:@"Keyboard"] ||
               [NSStringFromClass(window.class) containsString:@"TextEffects"])continue;
            if(!DFYTRotationABI(window))continue;
            DFYTWindowSnapshot *saved=[self.snapshots objectForKey:window];
            if(saved && CGSizeEqualToSize(window.bounds.size,size) &&
               window.rootViewController.interfaceOrientation==UIInterfaceOrientationPortrait)continue;
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
            ++applied;
            if(measurements.count<8)[measurements addObject:@{
                @"width":@(window.bounds.size.width),@"height":@(window.bounds.size.height),
                @"orientation":@(window.rootViewController.interfaceOrientation)}];
        }
        DFYTPost(DFYTAckName,@{@"bundleIdentifier":DFYTBundle,@"owner":self.state[@"owner"],
            @"sceneIdentifier":self.state[@"sceneIdentifier"],@"phase":@"app-reflow-measured",
            @"windowsApplied":@(applied),@"windows":measurements,@"sceneOrientation":@(owned.interfaceOrientation),
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
    self.state=nil; self.scene=nil;
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
