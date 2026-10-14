// Source-only visual feature. Keep original start/stop methods and native layout.
// Compiled into DuoFaceVisualHook.m by an explicit #include; no standalone target.
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <dispatch/dispatch.h>
#import <math.h>
#import <string.h>
#import <stdlib.h>

static char DFRunnerAssociation;
static IMP DFNativeBorderStart = NULL, DFNativeBorderStop = NULL;
static BOOL DFBorderHooksInstalled = NO;
static IMP DFNativeSplitLayout = NULL;
static IMP DFNativeFocusSlot = NULL, DFNativeRestoreSplit = NULL;
static char DFFocusAssociation, DFRunningAssociation;
static NSHashTable *DFKnownBorderViews = nil;
static BOOL DFFocusHidden(id controller) { return [objc_getAssociatedObject(controller,&DFFocusAssociation) boolValue]; }
static void DFTrackBorderView(UIView *view) {
    if (![view isKindOfClass:[UIView class]]) return;
    if (!DFKnownBorderViews) DFKnownBorderViews=[[NSHashTable weakObjectsHashTable] retain];
    [DFKnownBorderViews addObject:view];
}

static NSHashTable *DFActiveBorderViews = nil;
static const CGFloat DFLineWidth = 1.0;
static const CFTimeInterval DFLapSeconds = 1.0;
// Match the approved installed logo instead of inventing another red palette.
// Canonical red sampled from approved duoface-logo.png SHA256
// 78450d8ee4759353bdc21f27a06016c03fab61038ae60109ba21515c087b0089
// Evidence: audit/approved-logo-red.json; RGB (227,2,15), hex #E3020F.
static UIColor *DFBorderLogoRed(void) {
    return [UIColor colorWithRed:227.0/255.0 green:2.0/255.0 blue:15.0/255.0 alpha:1.0];
}
static void DFSetBorderColor(UIView *view, UIColor *color) {
    if (![view isKindOfClass:[UIView class]]) return;
    [view.layer removeAnimationForKey:@"borderPulse"];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    view.layer.borderColor = color.CGColor;
    [CATransaction commit];
}


@interface DFBorderEffect : NSObject {
@public
    NSMutableArray *_layers;
    CGRect _lastBounds;
}
@end
@implementation DFBorderEffect
- (id)init { if ((self = [super init])) { _layers = [[NSMutableArray alloc] init]; _lastBounds = CGRectNull; } return self; }
- (void)dealloc { [_layers release]; [super dealloc]; }
@end

static CAKeyframeAnimation *DFRunnerAnimation(NSString *key, CGFloat from, CGFloat to, CFTimeInterval beginTime) {
    CAKeyframeAnimation *a = [CAKeyframeAnimation animationWithKeyPath:key];
    a.values = @[@(from), @(to)];
    a.keyTimes = @[@0, @1];
    a.calculationMode = kCAAnimationLinear;
    a.duration = DFLapSeconds;
    a.beginTime = beginTime;
    a.repeatCount = HUGE_VALF;
    a.removedOnCompletion = YES;
    return a;
}
static void DFConfigureLayer(CAShapeLayer *layer, UIBezierPath *path, CGRect bounds) {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    layer.frame = bounds;
    layer.path = path.CGPath;
    layer.lineWidth = DFLineWidth;
    layer.lineCap = kCALineCapRound;
    layer.lineJoin = kCALineJoinRound;
    layer.fillColor = [UIColor clearColor].CGColor;
    [CATransaction commit];
}
static void DFLayoutEffect(UIView *view, DFBorderEffect *effect) {
    CGRect b = view.bounds;
    if (CGRectIsEmpty(b) || CGRectEqualToRect(effect->_lastBounds,b)) return;
    effect->_lastBounds = b;
    CGRect inset = CGRectInset(CGRectMake(0,0,b.size.width,b.size.height),0.5,0.5);
    CGFloat radius = MIN(10.0,MIN(inset.size.width,inset.size.height)*0.5);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:inset cornerRadius:radius];
    for (CAShapeLayer *layer in effect->_layers) DFConfigureLayer(layer,path,b);
}
static void DFStopEffect(UIView *view) {
    if (![view isKindOfClass:[UIView class]]) return;
    DFBorderEffect *effect = objc_getAssociatedObject(view,&DFRunnerAssociation);
    if (!effect) return;
    for (CALayer *layer in effect->_layers) {
        [layer removeAllAnimations];
        [layer removeFromSuperlayer];
    }
    objc_setAssociatedObject(view,&DFRunnerAssociation,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [DFActiveBorderViews removeObject:view];
}
static void DFStartEffect(UIView *view) {
    if (![view isKindOfClass:[UIView class]] || CGRectIsEmpty(view.bounds)) return;
    // The native blink-session owner may call start again while already active.
    // Restarting the animation every time hides the moving segments at t=0.
    DFBorderEffect *existing=objc_getAssociatedObject(view,&DFRunnerAssociation);
    BOOL alive=existing && existing->_layers.count==5;
    if (alive) {
        NSUInteger index=0;
        for (CALayer *layer in existing->_layers) {
            if (layer.superlayer!=view.layer ||
                (index>0 && (![layer animationForKey:@"dfStart"] ||
                             ![layer animationForKey:@"dfEnd"]))) {
                alive=NO;
                break;
            }
            index++;
        }
    }
    if (alive) {
        DFLayoutEffect(view,existing);
        return;
    }
    DFStopEffect(view);
    DFBorderEffect *effect = [[[DFBorderEffect alloc] init] autorelease];
    // Opaque full-perimeter BLACK backing masks any old native blue glow
    // under our animated red/white segments. Never paint over CarPlay content.
    CAShapeLayer *backing=[CAShapeLayer layer];
    backing.strokeColor=[UIColor blackColor].CGColor;
    backing.zPosition=1000.0;
    backing.strokeStart=0;
    backing.strokeEnd=1;
    [view.layer addSublayer:backing];
    [effect->_layers addObject:backing];
    // Duplicate each segment shifted by -1 lap. This makes the wrap seam continuous.
    NSArray *colors = @[
        (id)(DFBorderLogoRed()).CGColor,
        (id)[UIColor whiteColor].CGColor
    ];
    CGFloat lengths[2] = {0.18,0.055};
    CFTimeInterval t = [view.layer convertTime:CACurrentMediaTime() fromLayer:nil];
    for (NSUInteger colorIndex=0; colorIndex<2; colorIndex++) {
        for (NSUInteger copy=0; copy<2; copy++) {
            CAShapeLayer *layer = [CAShapeLayer layer];
            layer.strokeColor = (CGColorRef)[colors objectAtIndex:colorIndex];
            layer.zPosition=1001.0+(CGFloat)colorIndex;
            layer.strokeStart = 0;
            layer.strokeEnd = 0;
            [view.layer addSublayer:layer];
            [effect->_layers addObject:layer];
            CGFloat offset = copy == 0 ? 0 : -1;
            CGFloat len = lengths[colorIndex];
            [layer addAnimation:DFRunnerAnimation(@"strokeStart",offset,offset+1,t) forKey:@"dfStart"];
            [layer addAnimation:DFRunnerAnimation(@"strokeEnd",offset+len,offset+1+len,t) forKey:@"dfEnd"];
        }
    }
    effect->_lastBounds = CGRectNull;
    DFLayoutEffect(view,effect);
    objc_setAssociatedObject(view,&DFRunnerAssociation,effect,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (!DFActiveBorderViews) DFActiveBorderViews = [[NSHashTable weakObjectsHashTable] retain];
    [DFActiveBorderViews addObject:view];
}
static void DFHideBorderForFocus(UIView *view) {
    if (![view isKindOfClass:[UIView class]]) return;
    DFStopEffect(view);
    [view.layer removeAnimationForKey:@"borderPulse"];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    view.layer.borderColor=[UIColor clearColor].CGColor;
    [CATransaction commit];
}
static void DFUpdateFocusBorders(id controller) {
    BOOL focused=DFFocusHidden(controller);
    for (UIView *view in [DFKnownBorderViews allObjects]) {
        if (focused) DFHideBorderForFocus(view);
        else {
            if ([objc_getAssociatedObject(view,&DFRunningAssociation) boolValue]) {
                DFSetBorderColor(view,[UIColor blackColor]);
                DFStartEffect(view);
            } else DFSetBorderColor(view,DFBorderLogoRed());
        }
    }
}
static void DFFocusSlotHook(id self, SEL cmd, NSInteger slot, BOOL animated) {
    objc_setAssociatedObject(self,&DFFocusAssociation,@YES,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    DFUpdateFocusBorders(self);
    ((void(*)(id,SEL,NSInteger,BOOL))DFNativeFocusSlot)(self,cmd,slot,animated);
    DFUpdateFocusBorders(self);
}
static void DFRestoreSplitHook(id self, SEL cmd, BOOL animated) {
    ((void(*)(id,SEL,BOOL))DFNativeRestoreSplit)(self,cmd,animated);
    objc_setAssociatedObject(self,&DFFocusAssociation,@NO,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    DFUpdateFocusBorders(self);
}
static void DFBorderStartHook(id self, SEL cmd, UIView *view) {
    // Original start creates the blue infinite borderColor animation (0x11fa88).
    // Do not invoke it: this replacement owns border visuals during the running phase.
    (void)self; (void)cmd;
    void (^update)(void) = ^{
        if ([view isKindOfClass:[UIView class]]) {
            DFTrackBorderView(view);
            objc_setAssociatedObject(view,&DFRunningAssociation,@YES,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            NSLog(@"[DuoFaceBorder] START view=%p focus=%d bounds=%@",view,DFFocusHidden(self),NSStringFromCGRect(view.bounds));
            if (DFFocusHidden(self)) { DFHideBorderForFocus(view); return; }
            // Black baseline is visible wherever moving red/white strokes leave a gap.
            DFSetBorderColor(view,[UIColor blackColor]);
            DFStartEffect(view);
        }
    };
    if ([NSThread isMainThread]) update(); else dispatch_async(dispatch_get_main_queue(),update);
}
static void DFBorderStopHook(id self, SEL cmd, UIView *view) {
    ((void(*)(id,SEL,id))DFNativeBorderStop)(self,cmd,view);
    void (^update)(void) = ^{
        DFTrackBorderView(view);
        objc_setAssociatedObject(view,&DFRunningAssociation,@NO,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        NSLog(@"[DuoFaceBorder] STOP view=%p focus=%d",view,DFFocusHidden(self));
        DFStopEffect(view);
        if (DFFocusHidden(self)) { DFHideBorderForFocus(view); return; }
        // The final static border uses the same red sampled by the menu from the approved logo.
        UIColor *red=DFBorderLogoRed();
        DFSetBorderColor(view,red);
    };
    if ([NSThread isMainThread]) update(); else dispatch_async(dispatch_get_main_queue(),update);
}
static void DFSplitLayoutHook(id self, SEL cmd) {
    ((void(*)(id,SEL))DFNativeSplitLayout)(self,cmd);
    if (DFFocusHidden(self)) { DFUpdateFocusBorders(self); return; }
    // A native start can fire before the container gets nonzero bounds.
    // Track that start and attach the runner as soon as native layout completes.
    for (UIView *view in [DFKnownBorderViews allObjects]) {
        DFBorderEffect *effect=objc_getAssociatedObject(view,&DFRunnerAssociation);
        if ([objc_getAssociatedObject(view,&DFRunningAssociation) boolValue] && !effect) {
            if (!CGRectIsEmpty(view.bounds)) {
                DFSetBorderColor(view,[UIColor blackColor]);
                DFStartEffect(view);
                NSLog(@"[DuoFaceBorder] delayed START after native layout %@",NSStringFromCGRect(view.bounds));
            }
        } else if (effect) DFLayoutEffect(view,effect);
    }
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
