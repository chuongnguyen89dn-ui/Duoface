// Source-only visual feature. Keep original start/stop methods and native layout.
// Compiled into DuoFaceVisualHook.m by an explicit #include; no standalone target.
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <dispatch/dispatch.h>
#import <math.h>

static char DFRunnerAssociation;
static IMP DFNativeBorderStart = NULL, DFNativeBorderStop = NULL;
static BOOL DFBorderHooksInstalled = NO;
static IMP DFNativeSplitLayout = NULL;
static NSHashTable *DFActiveBorderViews = nil;
static const CGFloat DFLineWidth = 1.0;
static const CFTimeInterval DFLapSeconds = 1.0;
// Match the approved installed logo instead of inventing another red palette.
static UIColor *DFBorderLogoRed(void) {
    static UIColor *accent = nil;
    if (accent) return accent;
    UIImage *logo = [UIImage imageWithContentsOfFile:
        @"/var/jb/Library/Application Support/DuoFace/duoface-logo.png"];
    if (!logo.CGImage) return nil;
    uint8_t pixels[32*16*4] = {0};
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(pixels,32,16,8,32*4,space,
        kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(space);
    if (!ctx) return nil;
    CGContextDrawImage(ctx,CGRectMake(0,0,32,16),logo.CGImage);
    CGContextRelease(ctx);
    int best=-1, score=0;
    for (int n=0;n<32*16;n++) {
        int red=pixels[n*4], green=pixels[n*4+1];
        int blue=pixels[n*4+2], alpha=pixels[n*4+3];
        int strength=red-MAX(green,blue);
        if (alpha>180 && red>100 && strength>score) {score=strength;best=n;}
    }
    if (best<0) return nil;
    accent=[[UIColor colorWithRed:pixels[best*4]/255.0
        green:pixels[best*4+1]/255.0 blue:pixels[best*4+2]/255.0 alpha:1] retain];
    return accent;
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
    DFStopEffect(view);
    DFBorderEffect *effect = [[[DFBorderEffect alloc] init] autorelease];
    // Duplicate each segment shifted by -1 lap. This makes the wrap seam continuous.
    NSArray *colors = @[
        (id)(DFBorderLogoRed() ?: [UIColor whiteColor]).CGColor,
        (id)[UIColor whiteColor].CGColor
    ];
    CGFloat lengths[2] = {0.18,0.055};
    CFTimeInterval t = [view.layer convertTime:CACurrentMediaTime() fromLayer:nil];
    for (NSUInteger colorIndex=0; colorIndex<2; colorIndex++) {
        for (NSUInteger copy=0; copy<2; copy++) {
            CAShapeLayer *layer = [CAShapeLayer layer];
            layer.strokeColor = (CGColorRef)[colors objectAtIndex:colorIndex];
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
static void DFBorderStartHook(id self, SEL cmd, UIView *view) {
    // Original start creates the blue infinite borderColor animation (0x11fa88).
    // Do not invoke it: this replacement owns border visuals during the running phase.
    (void)self; (void)cmd;
    void (^update)(void) = ^{
        if ([view isKindOfClass:[UIView class]]) {
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
        DFStopEffect(view);
        // The final static border uses the same red sampled by the menu from the approved logo.
        UIColor *red=DFBorderLogoRed();
        DFSetBorderColor(view,red ?: [UIColor blackColor]);
    };
    if ([NSThread isMainThread]) update(); else dispatch_async(dispatch_get_main_queue(),update);
}
static void DFSplitLayoutHook(id self, SEL cmd) {
    ((void(*)(id,SEL))DFNativeSplitLayout)(self,cmd);
    for (UIView *view in [DFActiveBorderViews allObjects]) {
        DFBorderEffect *effect = objc_getAssociatedObject(view,&DFRunnerAssociation);
        if (effect) DFLayoutEffect(view,effect);
    }
}
static void DFInstallBorderRunner(Class controller, void (*hook)(Class,SEL,IMP,IMP *)) {
    if (DFBorderHooksInstalled || !controller || !hook) return;
    SEL start = @selector(startContainerBorderBlinking:);
    SEL stop = @selector(stopContainerBorderBlinking:);
    // Exact class CBBridgedSplitApp and selector signatures verified in original ObjC metadata.
    Method m1 = class_getInstanceMethod(controller,start);
    Method m2 = class_getInstanceMethod(controller,stop);
    if (!m1 || !m2) return;
    if (strcmp(method_getTypeEncoding(m1),"v24@0:8@16") ||
        strcmp(method_getTypeEncoding(m2),"v24@0:8@16")) return;
    SEL layout = @selector(layoutSplitViews);
    if (class_getInstanceMethod(controller,layout)) hook(controller,layout,(IMP)DFSplitLayoutHook,&DFNativeSplitLayout);
    hook(controller,start,(IMP)DFBorderStartHook,&DFNativeBorderStart);
    hook(controller,stop,(IMP)DFBorderStopHook,&DFNativeBorderStop);
    DFBorderHooksInstalled = (DFNativeBorderStart != NULL && DFNativeBorderStop != NULL);
}
