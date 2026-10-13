// DuoFace border runner source only; do not package until reviewed and tested.
// Hooks the original start/stop border methods without changing their timing.
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <math.h>

static char DFRunnerKey;
static IMP DFOriginalStart;
static IMP DFOriginalStop;
static const CGFloat DFRunnerWidth = 1.0;
static const CFTimeInterval DFRunnerLap = 1.0;

@interface DFBorderRunner : NSObject
@property(nonatomic, retain) CAShapeLayer *red;
@property(nonatomic, retain) CAShapeLayer *white;
@end
@implementation DFBorderRunner
@synthesize red = _red, white = _white;
- (void)dealloc { [_red release]; [_white release]; [super dealloc]; }
@end

static CAKeyframeAnimation *DFSegment(NSString *key, CGFloat begin, CGFloat end) {
    CAKeyframeAnimation *a = [CAKeyframeAnimation animationWithKeyPath:key];
    a.values = @[@(begin), @(end)];
    a.keyTimes = @[@0, @1];
    a.calculationMode = kCAAnimationLinear;
    a.duration = DFRunnerLap;
    a.repeatCount = HUGE_VALF;
    a.removedOnCompletion = YES;
    return a;
}

static void DFAnimateSegment(CAShapeLayer *layer, CGFloat tail, CGFloat head) {
    // Two synchronized endpoints. Values may extend beyond [0,1] and are clipped by CA.
    [layer addAnimation:DFSegment(@"strokeStart", tail, tail + 1.0) forKey:@"dfStart"];
    [layer addAnimation:DFSegment(@"strokeEnd", head, head + 1.0) forKey:@"dfEnd"];
}

static void DFRunnerLayout(UIView *view, DFBorderRunner *runner) {
    CGRect b = view.bounds;
    if (CGRectIsEmpty(b)) return;
    CGFloat radius = MIN(10.0, MIN(b.size.width, b.size.height) / 2.0);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(b, 0.5, 0.5)
                                                   cornerRadius:radius];
    for (CAShapeLayer *layer in @[runner.red, runner.white]) {
        layer.frame = b;
        layer.path = path.CGPath;
        layer.lineWidth = DFRunnerWidth;
        layer.fillColor = [UIColor clearColor].CGColor;
        layer.lineCap = kCALineCapRound;
    }
}

static void DFStartRunner(UIView *view) {
    if (![view isKindOfClass:[UIView class]]) return;
    DFBorderRunner *runner = objc_getAssociatedObject(view, &DFRunnerKey);
    if (!runner) {
        runner = [[[DFBorderRunner alloc] init] autorelease];
        runner.red = [CAShapeLayer layer];
        runner.white = [CAShapeLayer layer];
        runner.red.strokeColor = [UIColor colorWithRed:1 green:0.09 blue:0.22 alpha:1].CGColor;
        runner.white.strokeColor = [UIColor whiteColor].CGColor;
        runner.red.actions = @{@"path":[NSNull null], @"bounds":[NSNull null], @"position":[NSNull null]};
        runner.white.actions = runner.red.actions;
        [view.layer addSublayer:runner.red];
        [view.layer addSublayer:runner.white];
        objc_setAssociatedObject(view, &DFRunnerKey, runner, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    DFRunnerLayout(view, runner);
    [runner.red removeAllAnimations];
    [runner.white removeAllAnimations];
    DFAnimateSegment(runner.red, -0.18, 0.0);
    DFAnimateSegment(runner.white, -0.055, 0.0);
}

static void DFStopRunner(UIView *view) {
    DFBorderRunner *runner = objc_getAssociatedObject(view, &DFRunnerKey);
    if (!runner) return;
    [runner.red removeFromSuperlayer];
    [runner.white removeFromSuperlayer];
    objc_setAssociatedObject(view, &DFRunnerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void DFStartBorder(id self, SEL cmd, id view) {
    ((void (*)(id,SEL,id))DFOriginalStart)(self,cmd,view);
    if ([NSThread isMainThread]) DFStartRunner(view);
    else dispatch_async(dispatch_get_main_queue(), ^{ DFStartRunner(view); });
}
static void DFStopBorder(id self, SEL cmd, id view) {
    ((void (*)(id,SEL,id))DFOriginalStop)(self,cmd,view);
    if ([NSThread isMainThread]) DFStopRunner(view);
    else dispatch_async(dispatch_get_main_queue(), ^{ DFStopRunner(view); });
}

// Call this from existing visual hook's DFInstall after Substrate is available.
// Class name must be checked against original ObjC metadata before activation.
void DFInstallBorderRunner(Class controller, void (*hook)(Class,SEL,IMP,IMP *)) {
    if (!controller || !hook || DFOriginalStart || DFOriginalStop) return;
    SEL start = sel_registerName("startContainerBorderBlinking:");
    SEL stop = sel_registerName("stopContainerBorderBlinking:");
    if (!class_getInstanceMethod(controller,start) || !class_getInstanceMethod(controller,stop)) return;
    hook(controller,start,(IMP)DFStartBorder,&DFOriginalStart);
    hook(controller,stop,(IMP)DFStopBorder,&DFOriginalStop);
}
