// QA141: resize only the measured stale GOFA/Mapbox canvas within its own full-size parent.
// Mapbox owns Metal layout. No root/window/screen/rotation or camera writes.
#import <UIKit/UIKit.h>
#import <unistd.h>
#import "DFYouTubeHostState.h"
#import "DFGofaResizePolicy141.h"

@interface DFGofaMapResize141 : NSObject
@property(nonatomic) NSTimeInterval newest;
@property(nonatomic,copy) NSString *lease;
@property(nonatomic,strong) NSMapTable<UIView *,NSNumber *> *savedMasks;
@property(nonatomic,strong) NSTimer *expiry;
- (void)receive:(NSNotification *)notification;
@end
@implementation DFGofaMapResize141
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
                         @"parentBounds":NSStringFromCGRect(view.superview.bounds),
                         @"parentClass":view.superview?NSStringFromClass(view.superview.class):@"nil",
                         @"autoresizingMask":@(view.autoresizingMask),
                         @"translatesAutoresizingMaskIntoConstraints":@(view.translatesAutoresizingMaskIntoConstraints),
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
- (void)restoreMasks {
 UIViewAutoresizing temporary=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
 for(UIView *view in self.savedMasks.keyEnumerator) {
   NSNumber *previous=[self.savedMasks objectForKey:view];
   if(view.autoresizingMask==temporary)view.autoresizingMask=previous.unsignedIntegerValue;
 }
 [self.savedMasks removeAllObjects];
}
- (NSArray *)repair:(UIWindowScene *)scene state:(NSDictionary *)state {
 NSMutableArray *result=[NSMutableArray array];
 BOOL active=UIApplication.sharedApplication.applicationState==UIApplicationStateActive &&
             scene.activationState==UISceneActivationStateForegroundActive;
 for(UIWindow *window in scene.windows) {
   if(window.hidden || window.windowLevel!=UIWindowLevelNormal)continue;
   UIView *root=window.rootViewController.viewIfLoaded;
   if(!root)continue;
   NSMutableArray<UIView *> *queue=[NSMutableArray arrayWithObject:root];
   for(NSUInteger n=0;n<queue.count && n<128;n++) {
     UIView *view=queue[n],*parent=view.superview;
     NSString *name=NSStringFromClass(view.class);
     BOOL exact=[name isEqual:@"GOFA.GofaMapView"] || [name isEqual:@"MapboxMaps.MapView"];
     CGRect frame=view.frame,bounds=parent.bounds;
     if(exact) {
       BOOL allowed=DFGofa141MayResize(active,exact,parent && parent.window==window && view.window==window,
         CGAffineTransformIsIdentity(view.transform) && CGAffineTransformIsIdentity(parent.transform),
         view.translatesAutoresizingMaskIntoConstraints,
         [state[@"width"] doubleValue],[state[@"height"] doubleValue],
         window.bounds.size.width,window.bounds.size.height,bounds.size.width,bounds.size.height,
         bounds.origin.x,bounds.origin.y,frame.origin.x,frame.origin.y);
       BOOL changed=NO;
       if(allowed) {
         if(![self.savedMasks objectForKey:view])
            [self.savedMasks setObject:@(view.autoresizingMask) forKey:view];
         view.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
         if(!CGSizeEqualToSize(frame.size,bounds.size)) {
           view.frame=bounds; // Only exact canvas class, own measured full-size parent.
           [view setNeedsLayout];[view layoutIfNeeded];changed=YES;
         }
       }
       [result addObject:@{@"class":name,@"eligible":@(allowed),@"changed":@(changed),
         @"beforeFrame":NSStringFromCGRect(frame),@"afterFrame":NSStringFromCGRect(view.frame),
         @"parentBounds":NSStringFromCGRect(bounds)}];
     }
     for(UIView *child in view.subviews) {
       if(queue.count>=128)break;
       [queue addObject:child];
     }
   }
 }
 return result;
}
- (void)receive:(NSNotification *)notification {
 NSDictionary *state=[notification.userInfo copy];
 if(![state isKindOfClass:NSDictionary.class] ||
    ![state[@"bundleIdentifier"] isEqual:@"com.lumi.GOFA"] ||
    !DFYTString(state[@"sceneIdentifier"]) || !DFYTString(state[@"owner"]) ||
    !DFYTNumber(state[@"issuedAt"]) || !DFYTNumber(state[@"width"]) ||
    !DFYTNumber(state[@"height"]) || !DFYTNumber(state[@"generation"]))return;
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
   NSString *lease=[NSString stringWithFormat:@"%@/%@/%@",state[@"owner"],state[@"sceneIdentifier"],state[@"generation"]];
   if(![lease isEqual:self.lease])[self restoreMasks];
   self.lease=lease;
   NSArray *before=[self snapshot:scene];
   if(scene.activationState!=UISceneActivationStateForegroundActive ||
      UIApplication.sharedApplication.applicationState!=UIApplicationStateActive)[self restoreMasks];
   NSArray *repairs=[self repair:scene state:state];
   NSArray *after=[self snapshot:scene];
   [self.expiry invalidate];
   __weak DFGofaMapResize141 *weakSelf=self;
   self.expiry=[NSTimer scheduledTimerWithTimeInterval:8 repeats:NO block:^(__unused NSTimer *timer){
      [weakSelf restoreMasks];weakSelf.lease=nil;
   }];
   DFYTPost(@"com.duoface.gofa.layout-ack.v140",@{
     @"bundleIdentifier":@"com.lumi.GOFA",@"owner":state[@"owner"],
     @"sceneIdentifier":state[@"sceneIdentifier"],@"generation":state[@"generation"]?:@0,
     @"issuedAt":@(stamp),@"pid":@(getpid()),@"sceneActivation":@(scene.activationState),
     @"appActivation":@(UIApplication.sharedApplication.applicationState),
     @"phase":@"resize141",@"observed":after,@"before":before,@"repairs":repairs});
 });
}
@end
__attribute__((constructor)) static void DFGofaStart(void) {
 @autoreleasepool {
   if(![NSBundle.mainBundle.bundleIdentifier isEqual:@"com.lumi.GOFA"])return;
   static DFGofaMapResize141 *relay;
   relay=[DFGofaMapResize141 new];
   relay.savedMasks=[NSMapTable weakToStrongObjectsMapTable];
   [DFYTCenter() addObserver:relay selector:@selector(receive:)
       name:@"com.duoface.gofa.layout-state.v140" object:nil];
 }
}
