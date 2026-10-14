// DuoFace native activity border: RED only while user interacts.
// Source is included by DuoFaceVisualHook.m; no standalone dylib.
// Uses CBBridgedSplitApp's OWN noteUserActivity/startBlinkingSession/
// stopBlinkingSession timeout. No independent timer or animation.
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <dispatch/dispatch.h>
#import <string.h>
#import <stdlib.h>

static IMP DFNativeBorderStart=NULL, DFNativeBorderStop=NULL;
static IMP DFNativeSplitLayout=NULL, DFNativeFocusSlot=NULL, DFNativeRestoreSplit=NULL;
static BOOL DFBorderHooksInstalled=NO;
static char DFFocusAssociation, DFRunningAssociation, DFKnownBorderViewsKey;
static const CGFloat DFVisibleLineWidth=1.0;

static BOOL DFFocusHidden(id controller) {
    return [objc_getAssociatedObject(controller,&DFFocusAssociation) boolValue];
}
static NSHashTable *DFKnownBorderViewsFor(id controller) {
    NSHashTable *views=objc_getAssociatedObject(controller,&DFKnownBorderViewsKey);
    if (!views) {
        views=[NSHashTable weakObjectsHashTable];
        objc_setAssociatedObject(controller,&DFKnownBorderViewsKey,views,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return views;
}
static void DFTrackBorderView(id controller, UIView *view) {
    if ([view isKindOfClass:[UIView class]]) {
        [DFKnownBorderViewsFor(controller) addObject:view];
    }
}
static UIColor *DFBorderLogoRed(void) {
    // One approved red: audit/approved-logo-red.json, RGB(227,2,15).
    return [UIColor colorWithRed:227.0/255.0 green:2.0/255.0 blue:15.0/255.0 alpha:1.0];
}
static void DFRemoveLegacyBorderEffects(UIView *view) {
    // Remove only our old red/white runner and black backing layers, if any.
    // The native blue borderColor animation is intentionally never started.
    [view.layer removeAnimationForKey:@"borderPulse"];
    for (CALayer *layer in [view.layer.sublayers copy]) {
        if ([layer isKindOfClass:[CAShapeLayer class]] &&
            layer.zPosition>=1000.0 && layer.zPosition<=1003.0) {
            [layer removeAllAnimations];
            [layer removeFromSuperlayer];
        }
    }
}
static void DFSetBorderVisible(UIView *view, BOOL visible) {
    if (![view isKindOfClass:[UIView class]]) return;
    DFRemoveLegacyBorderEffects(view);
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    view.layer.borderColor=(visible?DFBorderLogoRed():[UIColor clearColor]).CGColor;
    view.layer.borderWidth=visible?DFVisibleLineWidth:0.0;
    [CATransaction commit];
}
static void DFUpdateFocusBorders(id controller) {
    BOOL focused=DFFocusHidden(controller);
    for (UIView *view in [DFKnownBorderViewsFor(controller) allObjects]) {
        BOOL nativeSessionActive=[objc_getAssociatedObject(view,&DFRunningAssociation) boolValue];
        DFSetBorderVisible(view,nativeSessionActive && !focused);
    }
}
static void DFFocusSlotHook(id self, SEL cmd, NSInteger slot, BOOL animated) {
    // Keep native focus geometry/callback. A focused pane NEVER has border.
    objc_setAssociatedObject(self,&DFFocusAssociation,@YES,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    DFUpdateFocusBorders(self);
    ((void(*)(id,SEL,NSInteger,BOOL))DFNativeFocusSlot)(self,cmd,slot,animated);
    DFUpdateFocusBorders(self);
}
static void DFRestoreSplitHook(id self, SEL cmd, BOOL animated) {
    ((void(*)(id,SEL,BOOL))DFNativeRestoreSplit)(self,cmd,animated);
    objc_setAssociatedObject(self,&DFFocusAssociation,@NO,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    // Returning to split must NOT leave a permanent static red border.
    // If native idle already fired, the border remains invisible.
    DFUpdateFocusBorders(self);
}
static void DFBorderStartHook(id self, SEL cmd, UIView *view) {
    // Original native START would create the infinite BLUE borderPulse.
    // Do NOT call it. The original session still owns the idle timeout.
    (void)cmd;
    void (^update)(void)=^{
        if (![view isKindOfClass:[UIView class]]) return;
        DFTrackBorderView(self,view);
        objc_setAssociatedObject(view,&DFRunningAssociation,@YES,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        DFSetBorderVisible(view,!DFFocusHidden(self));
        NSLog(@"[DuoFaceBorder] RED ON user activity view=%p focus=%d",view,DFFocusHidden(self));
    };
    if ([NSThread isMainThread]) update();
    else dispatch_async(dispatch_get_main_queue(),update);
}
static void DFBorderStopHook(id self, SEL cmd, UIView *view) {
    // Keep original native STOP cleanup and EXACT same idle cadence as swap UI.
    ((void(*)(id,SEL,id))DFNativeBorderStop)(self,cmd,view);
    void (^update)(void)=^{
        if (![view isKindOfClass:[UIView class]]) return;
        DFTrackBorderView(self,view);
        objc_setAssociatedObject(view,&DFRunningAssociation,@NO,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        DFSetBorderVisible(view,NO);
        NSLog(@"[DuoFaceBorder] RED OFF native idle view=%p",view);
    };
    if ([NSThread isMainThread]) update();
    else dispatch_async(dispatch_get_main_queue(),update);
}
static void DFSplitLayoutHook(id self, SEL cmd) {
    ((void(*)(id,SEL))DFNativeSplitLayout)(self,cmd);
    DFUpdateFocusBorders(self);
}
static void DFInstallBorderRunner(Class controller, void (*hook)(Class,SEL,IMP,IMP *)) {
    if (DFBorderHooksInstalled || !controller || !hook) return;
    SEL start = @selector(startContainerBorderBlinking:);
    SEL stop = @selector(stopContainerBorderBlinking:);
    // Exact class CBBridgedSplitApp and selector signatures verified in original ObjC metadata.
    Method m1 = class_getInstanceMethod(controller,start);
    Method m2 = class_getInstanceMethod(controller,stop);
    if (!m1 || !m2) {
        NSLog(@"[DuoFaceBorder] native start/stop selectors missing");
        return;
    }
    if (strcmp(method_getTypeEncoding(m1),"v24@0:8@16") ||
        strcmp(method_getTypeEncoding(m2),"v24@0:8@16")) {
        NSLog(@"[DuoFaceBorder] signature mismatch start=%s stop=%s",
              method_getTypeEncoding(m1),method_getTypeEncoding(m2));
        return;
    }
    SEL layout = @selector(layoutSplitViews);
    if (class_getInstanceMethod(controller,layout)) hook(controller,layout,(IMP)DFSplitLayoutHook,&DFNativeSplitLayout);
    hook(controller,start,(IMP)DFBorderStartHook,&DFNativeBorderStart);
    hook(controller,stop,(IMP)DFBorderStopHook,&DFNativeBorderStop);
    Method focus=class_getInstanceMethod(controller,@selector(focusSlot:animated:));
    Method restore=class_getInstanceMethod(controller,@selector(restoreSplitAnimated:));
    // Check argument types by index; ObjC encodings contain stack offsets between them.
    BOOL safe=NO;
    if (focus && restore && method_getNumberOfArguments(focus)==4 &&
        method_getNumberOfArguments(restore)==3) {
        char *slotType=method_copyArgumentType(focus,2);
        char *focusAnimated=method_copyArgumentType(focus,3);
        char *restoreAnimated=method_copyArgumentType(restore,2);
        safe=slotType && (!strcmp(slotType,@encode(NSInteger)) ||
            !strcmp(slotType,@encode(NSUInteger))) &&
            focusAnimated && (!strcmp(focusAnimated,"B") || !strcmp(focusAnimated,"c")) &&
            restoreAnimated && (!strcmp(restoreAnimated,"B") || !strcmp(restoreAnimated,"c"));
        if (slotType) free(slotType);
        if (focusAnimated) free(focusAnimated);
        if (restoreAnimated) free(restoreAnimated);
    }
    if (safe) {
        hook(controller,@selector(focusSlot:animated:),(IMP)DFFocusSlotHook,&DFNativeFocusSlot);
        hook(controller,@selector(restoreSplitAnimated:),(IMP)DFRestoreSplitHook,&DFNativeRestoreSplit);
    }
    DFBorderHooksInstalled = (DFNativeBorderStart != NULL && DFNativeBorderStop != NULL);
    NSLog(@"[DuoFaceBorder] install %@ start=%p stop=%p focus=%p restore=%p",
          DFBorderHooksInstalled?@"OK":@"FAILED",
          DFNativeBorderStart,DFNativeBorderStop,DFNativeFocusSlot,DFNativeRestoreSplit);
}
