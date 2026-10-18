// Native12 reference UI inspector (source-only, opt-in, read-only).
// Does NOT hook, call, patch, relink, or ship any vendor method or binary.
// Runs only after a manual Darwin notification on an instrumented test device.
// Never reads UILabel.text, UITextField.text, UIImage pixel data, URL, device ID,
// app bundle ID, cookies, keys, passwords, GPS, or scene screenshot.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <dispatch/dispatch.h>
#import <math.h>

static NSString *const DFNativeProbeTrigger =
    @"com.duoface.native12.reference.capture";
static NSString *const DFNativeProbeDirectory =
    @"/var/mobile/Library/Logs/DuoFaceNative12Reference";

static NSArray<NSNumber *> *DFProbeRect(CGRect r) {
    if (!isfinite(r.origin.x) || !isfinite(r.origin.y) ||
        !isfinite(r.size.width) || !isfinite(r.size.height)) return @[];
    return @[@(r.origin.x), @(r.origin.y), @(r.size.width), @(r.size.height)];
}
static NSArray<NSNumber *> *DFProbeInsets(UIEdgeInsets i) {
    return @[@(i.top), @(i.left), @(i.bottom), @(i.right)];
}
static id DFProbeColor(UIColor *color) {
    if (!color) return [NSNull null];
    CGFloat r=0,g=0,b=0,a=0;
    if ([color getRed:&r green:&g blue:&b alpha:&a])
        return @[@(r),@(g),@(b),@(a)];
    CGFloat w=0;
    if ([color getWhite:&w alpha:&a])
        return @[@(w),@(w),@(w),@(a)];
    return [NSNull null]; // dynamic UIColor may not resolve in this context
}
static id DFProbeLayerColor(CGColorRef c) {
    if (!c) return [NSNull null];
    return DFProbeColor([UIColor colorWithCGColor:c]);
}
static BOOL DFProbeNativeClass(UIView *v) {
    NSString *n=NSStringFromClass(v.class);
    return [n hasPrefix:@"CBWindow"] ||
           [n hasPrefix:@"CBSplit"] ||
           [n hasPrefix:@"CBBridged"] ||
           [n hasPrefix:@"CBSlot"] ||
           [n hasPrefix:@"CBDivider"] ||
           [n hasPrefix:@"CBMultitasking"] ||
           [n hasPrefix:@"CBOverlay"] ||
           [n hasPrefix:@"CBUIAppContainer"] ||
           [n hasPrefix:@"CBDock"];
}
static BOOL DFProbeNativeInSubtree(UIView *v, NSUInteger depth) {
    if (!v || depth>15) return NO;
    if (DFProbeNativeClass(v)) return YES;
    for (UIView *s in v.subviews)
        if (DFProbeNativeInSubtree(s,depth+1)) return YES;
    return NO;
}
static NSArray *DFProbeGestures(UIView *v) {
    NSMutableArray *result=[NSMutableArray array];
    for (UIGestureRecognizer *g in v.gestureRecognizers) {
        NSMutableDictionary *item=[@{
            @"class":NSStringFromClass(g.class),
            @"enabled":@(g.enabled),
            @"cancels_touches":@(g.cancelsTouchesInView)
        } mutableCopy];
        if ([g isKindOfClass:UIPanGestureRecognizer.class]) {
            UIPanGestureRecognizer *p=(UIPanGestureRecognizer *)g;
            item[@"min_touches"]=@(p.minimumNumberOfTouches);
            item[@"max_touches"]=@(p.maximumNumberOfTouches);
        }
        if ([g isKindOfClass:UILongPressGestureRecognizer.class]) {
            UILongPressGestureRecognizer *p=(UILongPressGestureRecognizer *)g;
            item[@"min_hold_s"]=@(p.minimumPressDuration);
            item[@"allowable_movement_pt"]=@(p.allowableMovement);
        }
        [result addObject:item];
    }
    return result;
}
static NSDictionary *DFProbeView(UIView *v, UIWindow *w, NSUInteger depth,
                                 NSUInteger *count) {
    if (!v || *count>=2500 || depth>28) return @{};
    ++*count;
    CGRect inWindow=CGRectNull;
    @try {
        inWindow=[v convertRect:v.bounds toView:w];
    } @catch (NSException *ignored) {}
    CALayer *l=v.layer;
    NSMutableDictionary *node=[@{
        @"class":NSStringFromClass(v.class),
        @"frame_parent_pt":DFProbeRect(v.frame),
        @"bounds_pt":DFProbeRect(v.bounds),
        @"frame_window_pt":DFProbeRect(inWindow),
        @"safe_area_t_l_b_r_pt":DFProbeInsets(v.safeAreaInsets),
        @"hidden":@(v.hidden),
        @"alpha":@(v.alpha),
        @"touch_enabled":@(v.userInteractionEnabled),
        @"clips_to_bounds":@(v.clipsToBounds),
        @"corner_radius_pt":@(l.cornerRadius),
        @"border_width_pt":@(l.borderWidth),
        @"background_rgba":DFProbeColor(v.backgroundColor),
        @"layer_background_rgba":DFProbeLayerColor(l.backgroundColor),
        @"border_rgba":DFProbeLayerColor(l.borderColor),
        @"tint_rgba":DFProbeColor(v.tintColor),
        @"gestures":DFProbeGestures(v),
        @"native_ui_class":@(DFProbeNativeClass(v))
    } mutableCopy];
    if ([v isKindOfClass:UIControl.class])
        node[@"control_events"]=@(((UIControl *)v).allControlEvents);
    NSMutableArray *children=[NSMutableArray array];
    for (UIView *child in v.subviews) {
        if (*count>=2500) break;
        [children addObject:DFProbeView(child,w,depth+1,count)];
    }
    node[@"children"]=children;
    return node;
}
static NSArray *DFProbeScreens(UIApplication *app) {
    NSMutableArray *r=[NSMutableArray array];
    // UIKit iOS16 deprecates UIScreen.screens; enumerate scenes explicitly.
    NSMutableOrderedSet<UIScreen *> *found=[NSMutableOrderedSet orderedSet];
    [found addObject:UIScreen.mainScreen];
    if (@available(iOS 13.0,*)) {
        for (UIScene *scene in app.connectedScenes) {
            if ([scene isKindOfClass:UIWindowScene.class] &&
                ((UIWindowScene *)scene).screen)
                [found addObject:((UIWindowScene *)scene).screen];
        }
    }
    for (UIScreen *s in found) {
        [r addObject:@{
            @"bounds_pt":DFProbeRect(s.bounds),
            @"native_scale":@(s.nativeScale),
            @"scale":@(s.scale),
            @"is_main":@(s==UIScreen.mainScreen)
        }];
    }
    return r;
}
static void DFProbeCaptureNow(void) {
    if (!NSThread.isMainThread) return;
    UIApplication *app=UIApplication.sharedApplication;
    if (!app) return;
    NSMutableOrderedSet<UIWindow *> *windows=[NSMutableOrderedSet orderedSet];
    // UIWindowScene.windows is the supported iOS16 API. A special native
    // window not registered to a scene is a coverage limitation, NOT absence.
    if (@available(iOS 13.0,*)) {
        for (UIScene *s in app.connectedScenes) {
            if (![s isKindOfClass:UIWindowScene.class]) continue;
            for (UIWindow *w in ((UIWindowScene *)s).windows)
                if ([w isKindOfClass:UIWindow.class]) [windows addObject:w];
        }
    }
    NSMutableArray *out=[NSMutableArray array];
    NSUInteger skipped=0;
    for (UIWindow *w in windows) {
        // Only external CarPlay windows OR a tree exposing an actual
        // Native12 CB* root. Never dump arbitrary phone application windows.
        BOOL external=w.screen && (w.screen!=UIScreen.mainScreen);
        if (!external && !DFProbeNativeInSubtree(w,0)) {
            ++skipped;
            continue;
        }
        NSUInteger nodes=0;
        NSDictionary *tree=DFProbeView(w,w,0,&nodes);
        [out addObject:@{
            @"class":NSStringFromClass(w.class),
            @"external_screen":@(external),
            @"window_level":@(w.windowLevel),
            @"window_frame_pt":DFProbeRect(w.frame),
            @"window_bounds_pt":DFProbeRect(w.bounds),
            @"safe_area_t_l_b_r_pt":DFProbeInsets(w.safeAreaInsets),
            @"tree_nodes":@(nodes),
            @"view_tree":tree
        }];
    }
    NSDictionary *result=@{
        @"schema":@"native12_runtime_ui_reference_v1",
        @"capture_is_manual":@YES,
        @"read_only":@YES,
        @"contains_no_view_text_or_images":@YES,
        @"note":@"Native12 UI hierarchy snapshot; does not measure on-screen visual pixels, input actions, or full software behavior",
        @"screens":DFProbeScreens(app),
        @"windows":out,
        @"other_windows_not_recorded":@(skipped)
    };
    NSError *error=nil;
    NSData *json=[NSJSONSerialization dataWithJSONObject:result
                                                 options:NSJSONWritingPrettyPrinted
                                                   error:&error];
    if (!json) {
        NSLog(@"[DFNative12Reference] JSON failed: %@",error);
        return;
    }
    NSFileManager *fm=NSFileManager.defaultManager;
    if (![fm createDirectoryAtPath:DFNativeProbeDirectory
       withIntermediateDirectories:YES attributes:nil error:&error]) {
        NSLog(@"[DFNative12Reference] directory failed: %@",error);
        return;
    }
    NSString *filename=[NSString stringWithFormat:@"ui-%lld.json",
        (long long)(NSDate.date.timeIntervalSince1970*1000.0)];
    NSString *dest=[DFNativeProbeDirectory stringByAppendingPathComponent:filename];
    if (![json writeToFile:dest options:NSDataWritingAtomic error:&error])
        NSLog(@"[DFNative12Reference] write failed: %@",error);
    else
        NSLog(@"[DFNative12Reference] saved %@ windows=%lu",dest,(unsigned long)out.count);
}
static void DFProbeNotification(CFNotificationCenterRef center, void *observer,
                                CFNotificationName name, const void *object,
                                CFDictionaryRef userInfo) {
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool { DFProbeCaptureNow(); }
    });
}
__attribute__((constructor)) static void DFProbeRegister(void) {
    // Registration ONLY: no automatic scan and no UI/window modification.
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
        NULL, DFProbeNotification,
        (__bridge CFStringRef)DFNativeProbeTrigger,
        NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}
