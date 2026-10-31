// GOFA-only app-side layout reconciliation and before/after evidence.
// No orientation spoof, screen scale, window frame write, or map internals.
#import <UIKit/UIKit.h>
#import <unistd.h>
#import "DFYouTubeHostState.h"

@interface DFGofaLayoutRelay : NSObject
@property(nonatomic) NSTimeInterval newest;
@property(nonatomic,copy) NSString *lastLayoutKey;
- (void)receive:(NSNotification *)notification;
@end
@implementation DFGofaLayoutRelay
- (NSArray *)snapshot:(UIWindowScene *)scene {
 NSMutableArray *result=[NSMutableArray array];
 for(UIWindow *window in scene.windows) {
   if(window.hidden || window.windowLevel!=UIWindowLevelNormal)continue;
   UIViewController *controller=window.rootViewController;
   UIView *root=controller.viewIfLoaded;
   if(!root)continue;
   NSMutableArray *maps=[NSMutableArray array];
   NSMutableArray<UIView *> *queue=[NSMutableArray arrayWithObject:root];
   for(NSUInteger n=0;n<queue.count && n<128;n++) {
     UIView *view=queue[n];
     NSString *name=NSStringFromClass([view class]);
     if([name.lowercaseString containsString:@"map"] && maps.count<12)
       [maps addObject:@{@"class":name,@"bounds":NSStringFromCGRect(view.bounds),
                         @"frame":NSStringFromCGRect(view.frame),
                         @"safeArea":NSStringFromUIEdgeInsets(view.safeAreaInsets)}];
     if(queue.count<128)for(UIView *child in view.subviews) {
       if(queue.count>=128)break;
       [queue addObject:child];
     }
   }
   [result addObject:@{@"windowBounds":NSStringFromCGRect(window.bounds),
     @"windowFrame":NSStringFromCGRect(window.frame),
     @"rootClass":NSStringFromClass([controller class]),
     @"rootBounds":NSStringFromCGRect(root.bounds),@"rootFrame":NSStringFromCGRect(root.frame),
     @"rootSafeArea":NSStringFromUIEdgeInsets(root.safeAreaInsets),
     @"sceneBounds":NSStringFromCGRect(scene.coordinateSpace.bounds),
     @"orientation":@(scene.interfaceOrientation),
     @"horizontalTrait":@(root.traitCollection.horizontalSizeClass),
     @"verticalTrait":@(root.traitCollection.verticalSizeClass),@"maps":maps}];
 }
 return result;
}
- (void)receive:(NSNotification *)notification {
 NSDictionary *state=[notification.userInfo copy];
 if(![state isKindOfClass:NSDictionary.class] ||
    ![state[@"bundleIdentifier"] isEqual:@"com.lumi.GOFA"] ||
    !DFYTString(state[@"sceneIdentifier"]) || !DFYTString(state[@"owner"]) ||
    !DFYTNumber(state[@"issuedAt"]) || !DFYTNumber(state[@"width"]) ||
    !DFYTNumber(state[@"height"]))return;
 dispatch_async(dispatch_get_main_queue(),^{
   NSTimeInterval stamp=[state[@"issuedAt"] doubleValue];
   NSTimeInterval age=NSDate.date.timeIntervalSince1970-stamp;
   if(age<0 || age>3 || stamp<=self.newest)return;
   self.newest=stamp;
   UIWindowScene *scene=nil;
   for(UIScene *candidate in UIApplication.sharedApplication.connectedScenes)
     if([candidate isKindOfClass:UIWindowScene.class] &&
        [DFYTObject(candidate,@"_sceneIdentifier") isEqual:state[@"sceneIdentifier"]]) {
       scene=(UIWindowScene *)candidate;break;
     }
   if(!scene)return;
   NSArray *before=[self snapshot:scene];
   NSString *key=[NSString stringWithFormat:@"%@/%@/%@/%@/%@",
        state[@"owner"],state[@"sceneIdentifier"],state[@"generation"],state[@"width"],state[@"height"]];
   NSUInteger refreshed=0;
   if(![key isEqual:self.lastLayoutKey]) {
     self.lastLayoutKey=key;
     for(UIWindow *window in scene.windows) {
       UIView *root=window.rootViewController.viewIfLoaded;
       // Refresh only a measured mismatch after the scene itself accepted
       // the host size. UIKit remains responsible for frames and constraints.
       CGSize target=CGSizeMake([state[@"width"] doubleValue],[state[@"height"] doubleValue]);
       BOOL accepted=fabs(window.bounds.size.width-target.width)<1 &&
                     fabs(window.bounds.size.height-target.height)<1;
       if(!window.hidden && window.windowLevel==UIWindowLevelNormal && root &&
          root.window==window && accepted && !CGSizeEqualToSize(root.bounds.size,window.bounds.size)) {
         [window setNeedsLayout];[root setNeedsLayout];
         [window layoutIfNeeded];[root layoutIfNeeded];++refreshed;
       }
     }
   }
   DFYTPost(@"com.duoface.gofa.layout-ack.v1",@{
     @"bundleIdentifier":@"com.lumi.GOFA",@"owner":state[@"owner"],
     @"sceneIdentifier":state[@"sceneIdentifier"],@"generation":state[@"generation"]?:@0,
     @"issuedAt":@(stamp),@"pid":@(getpid()),@"sceneActivation":@(scene.activationState),
     @"appActivation":@(UIApplication.sharedApplication.applicationState),
     @"refreshed":@(refreshed),@"before":before,@"after":[self snapshot:scene]});
 });
}
@end
__attribute__((constructor)) static void DFGofaStart(void) {
 @autoreleasepool {
   if(![NSBundle.mainBundle.bundleIdentifier isEqual:@"com.lumi.GOFA"])return;
   static DFGofaLayoutRelay *relay;
   relay=[DFGofaLayoutRelay new];
   [DFYTCenter() addObserver:relay selector:@selector(receive:)
       name:@"com.duoface.gofa.layout-state.v1" object:nil];
 }
}
