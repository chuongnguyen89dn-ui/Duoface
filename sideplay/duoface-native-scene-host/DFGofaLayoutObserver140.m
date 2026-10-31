// QA140 GOFA-only passive app-side measurements. No layout mutation.
// No orientation spoof, screen scale, window frame write, or map internals.
#import <UIKit/UIKit.h>
#import <unistd.h>
#import "DFYouTubeHostState.h"

@interface DFGofaLayoutObserver140 : NSObject
@property(nonatomic) NSTimeInterval newest;
- (void)receive:(NSNotification *)notification;
@end
@implementation DFGofaLayoutObserver140
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
     if(([name.lowercaseString containsString:@"map"] || [name.lowercaseString containsString:@"flutter"] || [name.lowercaseString containsString:@"render"]) && maps.count<12)
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
     @"rootBounds":NSStringFromCGRect(root.bounds),@"rootTransform":NSStringFromCGAffineTransform(root.transform),@"rootFrame":NSStringFromCGRect(root.frame),
     @"rootSafeArea":NSStringFromUIEdgeInsets(root.safeAreaInsets),
     @"sceneBounds":NSStringFromCGRect(scene.coordinateSpace.bounds),
     @"screenBounds":NSStringFromCGRect(scene.screen.bounds),@"screenScale":@(scene.screen.scale),
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
   DFYTPost(@"com.duoface.gofa.layout-ack.v140",@{
     @"bundleIdentifier":@"com.lumi.GOFA",@"owner":state[@"owner"],
     @"sceneIdentifier":state[@"sceneIdentifier"],@"generation":state[@"generation"]?:@0,
     @"issuedAt":@(stamp),@"pid":@(getpid()),@"sceneActivation":@(scene.activationState),
     @"appActivation":@(UIApplication.sharedApplication.applicationState),
     @"phase":@"read-only",@"observed":before});
 });
}
@end
__attribute__((constructor)) static void DFGofaStart(void) {
 @autoreleasepool {
   if(![NSBundle.mainBundle.bundleIdentifier isEqual:@"com.lumi.GOFA"])return;
   static DFGofaLayoutObserver140 *relay;
   relay=[DFGofaLayoutObserver140 new];
   [DFYTCenter() addObserver:relay selector:@selector(receive:)
       name:@"com.duoface.gofa.layout-state.v140" object:nil];
 }
}
