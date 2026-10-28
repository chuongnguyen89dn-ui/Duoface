// Independent DuoFace native Maps pane ADAPTER (stage 2, INERT).
// The original OmniCar native ARM64 adopt:slot: uses this class of UIKit
// containment events; implementation below is new source-owned, does not
// import vendor code/dylib/license or call private scene mutations.
// Integration must wait for native-owner/host/controller parent verification.
#import "DFNativeMapPaneAdapter.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <math.h>

static id DFMapObjectGetter(id receiver,NSString *name) {
    if(!receiver)return nil;
    SEL getter=NSSelectorFromString(name);
    Method method=class_getInstanceMethod(object_getClass(receiver),getter);
    if(!method || method_getNumberOfArguments(method)!=2)return nil;
    char *ret=method_copyReturnType(method);
    BOOL object=(ret && ret[0]=='@');
    if(ret)free(ret);
    if(!object)return nil;
    @try {return ((id(*)(id,SEL))objc_msgSend)(receiver,getter);}
    @catch(NSException *e){(void)e;return nil;}
}
static BOOL DFMapFiniteFrame(CGRect r) {
    return !CGRectIsNull(r) && !CGRectIsInfinite(r) &&
           isfinite(r.origin.x) && isfinite(r.origin.y) &&
           isfinite(r.size.width) && isfinite(r.size.height) &&
           r.size.width>=90 && r.size.height>=120;
}
static BOOL DFMapExactFBScene(UIViewController *owner) {
    id info=DFMapObjectGetter(owner,@"applicationInfo");
    if(!info)info=DFMapObjectGetter(owner,@"proxyApplicationInfo");
    id bundle=DFMapObjectGetter(info,@"bundleIdentifier");
    id scene=DFMapObjectGetter(owner,@"scene");
    if(!scene)scene=DFMapObjectGetter(DFMapObjectGetter(owner,@"sceneHandle"),@"sceneIfExists");
    id sid=DFMapObjectGetter(scene,@"identifier");
    if(![bundle isKindOfClass:NSString.class] ||
       ![@[@"com.google.Maps",@"com.apple.Maps",@"com.waze.iphone"]
         containsObject:bundle] ||
       ![NSStringFromClass([scene class]) isEqual:@"FBScene"] ||
       ![sid isKindOfClass:NSString.class] ||
       ![sid hasPrefix:@"Car["] ||
       [sid rangeOfString:@"]:com.apple.CarPlayTemplateUIHost:"].location==NSNotFound ||
       ![sid hasSuffix:[@":" stringByAppendingString:bundle]])return NO;
    UIView *host=DFMapObjectGetter(owner,@"sceneHostView");
    UIView *view=owner.viewIfLoaded;
    return [host isKindOfClass:UIView.class] && view &&
           (host==view || [host isDescendantOfView:view]) &&
           host.window==view.window && host.window!=nil;
}
@interface DFNativeMapPaneAdapter ()
@property(nonatomic,strong) UIViewController *nativeOwner;
@property(nonatomic,strong) UIViewController *oldParent;
@property(nonatomic,strong) UIView *oldSuperview;
@property(nonatomic,strong) UIWindow *oldWindow;
@property(nonatomic,strong) UIViewController *assignedParent;
@property(nonatomic,strong) UIView *assignedContainer;
@property(nonatomic,assign) NSUInteger oldSubviewIndex;
@property(nonatomic,assign) CGRect oldFrame;
@property(nonatomic,assign) UIViewAutoresizing oldAutoresizing;
@property(nonatomic,assign) CGAffineTransform oldTransform;
@property(nonatomic,assign) UIEdgeInsets oldSafeInsets;
@property(nonatomic,assign) BOOL oldHidden;
@property(nonatomic,assign) CGFloat oldAlpha;
@property(nonatomic,assign) BOOL attached;
@end
@implementation DFNativeMapPaneAdapter
+ (NSString *)preflightNativeController:(UIViewController *)vc
                                  into:(UIViewController *)parent
                             container:(UIView *)container
                          measuredArea:(CGRect)usable {
    NSString *p=NSProcessInfo.processInfo.processName;
    if(!NSThread.isMainThread ||
       !([p isEqual:@"CarPlay"]||[p isEqual:@"CarPlayApp"]))
        return @"not-carplay-main-thread";
    if(!vc || ![NSStringFromClass(vc.class) isEqual:@"DBApplicationSceneViewController"] ||
       !parent || !container || vc==parent)
        return @"native-controller-or-target-invalid";
    if(!DFMapExactFBScene(vc))
        return @"native-maps-scene-host-identity-unverified";
    UIView *source=vc.viewIfLoaded;
    UIViewController *previous=vc.parentViewController;
    UIWindow *window=source.window;
    if(!previous || !previous.isViewLoaded || !window ||
       previous.view.window!=window || !source.superview)
        return @"previous-parent-or-window-not-owned";
    if(!parent.isViewLoaded || ![container isDescendantOfView:parent.view] ||
       parent.view.window!=window || container.window!=window)
        return @"target-parent-different-carplay-window";
    for(UIViewController *walker=parent;walker;walker=walker.parentViewController)
        if(walker==vc)return @"cyclic-controller-containment";
    UIWindowScene *ws=window.windowScene;
    if(!ws || ![ws.session.role isEqual:@"UIWindowSceneSessionRoleCarPlay"] ||
       ws.screen==UIScreen.mainScreen)
        return @"not-system-external-carplay-scene";
    if(!DFMapFiniteFrame(usable) ||
       !CGRectContainsRect(window.bounds,usable))
        return @"native-system-dock-bounds-not-measured";
    CGRect target=[container convertRect:container.bounds toView:window];
    if(!DFMapFiniteFrame(target) || !CGRectContainsRect(usable,target))
        return @"target-pane-overlaps-native-chrome";
    if(container==source || [container isDescendantOfView:source])
        return @"target-inside-native-source";
    return @"ready-only-when-explicitly-authorized";
}
- (BOOL)adoptNativeController:(UIViewController *)vc
                        into:(UIViewController *)parent
                   container:(UIView *)container
                measuredArea:(CGRect)usable
        explicitlyAuthorized:(BOOL)authorized
                       error:(NSString **)error {
    if(!authorized) {
        if(error)*error=@"explicitly-authorized-native-map-pane-required";
        return NO;
    }
    NSString *reason=[DFNativeMapPaneAdapter preflightNativeController:vc
                                   into:parent container:container measuredArea:usable];
    if(self.attached || ![reason isEqual:@"ready-only-when-explicitly-authorized"]) {
        if(error)*error=self.attached?@"one-lease-already-active":reason;
        return NO;
    }
    UIView *view=vc.viewIfLoaded;
    self.nativeOwner=vc;
    self.oldParent=vc.parentViewController;
    self.oldSuperview=view.superview;
    self.oldWindow=view.window;
    self.assignedParent=parent;
    self.assignedContainer=container;
    self.oldSubviewIndex=[view.superview.subviews indexOfObject:view];
    self.oldFrame=view.frame;
    self.oldAutoresizing=view.autoresizingMask;
    self.oldTransform=view.transform;
    self.oldSafeInsets=vc.additionalSafeAreaInsets;
    self.oldHidden=view.hidden;
    self.oldAlpha=view.alpha;
    // Match the original machine-verified UIKit containment transaction,
    // but NEVER call FBS foreground/background setters or touch CPWindow.
    [vc willMoveToParentViewController:nil];
    [view removeFromSuperview];
    [vc removeFromParentViewController];
    [parent addChildViewController:vc];
    view.transform=CGAffineTransformIdentity;
    view.frame=container.bounds;
    view.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [container addSubview:view];
    [vc didMoveToParentViewController:parent];
    self.attached=YES;
    return YES;
}
- (BOOL)restoreOriginalOwnerWithError:(NSString **)error {
    if(!self.attached)return YES;
    UIViewController *vc=self.nativeOwner,*parent=self.oldParent;
    UIView *view=vc.viewIfLoaded,*oldView=self.oldSuperview;
    if(!NSThread.isMainThread || !vc || !view || !parent ||
       !oldView || !self.oldWindow ||
       vc.parentViewController!=self.assignedParent ||
       view.superview!=self.assignedContainer ||
       oldView.window!=self.oldWindow ||
       !DFMapExactFBScene(vc)) {
        if(error)*error=@"restoration-owner-changed-no-unsafe-reparent";
        return NO;
    }
    [vc willMoveToParentViewController:nil];
    [view removeFromSuperview];
    [vc removeFromParentViewController];
    [parent addChildViewController:vc];
    NSUInteger index=MIN(self.oldSubviewIndex,oldView.subviews.count);
    [oldView insertSubview:view atIndex:index];
    view.transform=self.oldTransform;
    view.frame=self.oldFrame;
    view.autoresizingMask=self.oldAutoresizing;
    view.alpha=self.oldAlpha;view.hidden=self.oldHidden;
    vc.additionalSafeAreaInsets=self.oldSafeInsets;
    [vc didMoveToParentViewController:parent];
    self.attached=NO;
    self.nativeOwner=nil;self.oldParent=nil;self.oldSuperview=nil;
    self.oldWindow=nil;self.assignedParent=nil;self.assignedContainer=nil;
    return YES;
}
@end
