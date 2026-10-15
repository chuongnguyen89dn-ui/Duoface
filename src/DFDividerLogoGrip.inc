// DuoFace Mới: source-only CarPlay divider logo reposition (NO DEB).
// Native6 ARM64: CBDividerView.longPress is 0.4s; user approved 0.30s.
// Tap -> original onSwap. Hold -> move logo along divider, never onRotate.
// Keep the native divider pan callback/ratio unchanged for touches off logo.
// Included by DuoFaceVisualHook.m after DFObjectIvar and DFHookFn are declared.
#import <objc/message.h>
#import <math.h>

static const NSTimeInterval kDFLogoHoldThreshold = 0.30;
static char kDFLogoGripStateKey;
static IMP oldDFGripTouchDown, oldDFGripTouchUp, oldDFGripTouchCancel;
static IMP oldDFGripLongPress, oldDFGripDividerPan;
static BOOL DFGripHooksInstalled;

@interface DFLogoGripSession : NSObject {
@public
    UIButton *pressed;            // assign only; view/button lifetime owns the session
    BOOL holdRecognized;          // latched until next touch-down to prevent late onSwap
    BOOL dividerPanOwned;         // only if pan BEGAN on the logo
    BOOL changedPosition;
    BOOL hasPosition;
    NSUInteger savedButtonIndex;
    double savedRelativePos;
}
@end
@implementation DFLogoGripSession
@end

static DFLogoGripSession *DFLogoSession(id divider, BOOL make) {
    DFLogoGripSession *session=objc_getAssociatedObject(divider, &kDFLogoGripStateKey);
    if (!session && make) {
        session=[[DFLogoGripSession alloc] init];
        objc_setAssociatedObject(divider, &kDFLogoGripStateKey, session,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [session release]; // project uses manual reference counting
    }
    return session;
}

static NSArray *DFGripArray(id divider, const char *ivar) {
    id value=DFObjectIvar(divider, ivar);
    return [value isKindOfClass:[NSArray class]] ? value : nil;
}
static NSUInteger DFLogoIndexForButton(id divider, UIButton *button) {
    NSArray *buttons=DFGripArray(divider, "_moveButtons");
    return button ? [buttons indexOfObjectIdenticalTo:button] : NSNotFound;
}
static BOOL DFLogoIsButton(id divider, id button) {
    return [button isKindOfClass:[UIButton class]] &&
           DFLogoIndexForButton(divider, (UIButton *)button)!=NSNotFound;
}
static id DFLogoConfigAtIndex(id divider, NSUInteger index) {
    NSArray *configs=DFGripArray(divider, "_buttonConfigs");
    if (!configs || index==NSNotFound || index>=configs.count) return nil;
    id value=[configs objectAtIndex:index];
    return [value respondsToSelector:@selector(setRelativePos:)] ? value : nil;
}
static void DFLogoSetRelativePos(id info, double pos) {
    ((void (*)(id, SEL, double))objc_msgSend)(info, @selector(setRelativePos:), pos);
}

static void DFLogoRestorePositionBeforeLayout(id divider) {
    DFLogoGripSession *session=DFLogoSession(divider, NO);
    if (!session || !session->hasPosition) return;
    id info=DFLogoConfigAtIndex(divider, session->savedButtonIndex);
    if (info) DFLogoSetRelativePos(info, session->savedRelativePos);
}

static void DFLogoSetNativeHoldThreshold(UIButton *button) {
    if (!DFGripHooksInstalled || ![button isKindOfClass:[UIButton class]]) return;
    // The native per-button long press recognizer already has its own target.
    // Adjust this ONE recognizer rather than injecting duplicate recognizers.
    for (UIGestureRecognizer *gesture in button.gestureRecognizers) {
        if (![gesture isKindOfClass:[UILongPressGestureRecognizer class]]) continue;
        UILongPressGestureRecognizer *hold=(UILongPressGestureRecognizer *)gesture;
        if (fabs(hold.minimumPressDuration-kDFLogoHoldThreshold)>0.000001)
            hold.minimumPressDuration=kDFLogoHoldThreshold;
    }
}

static void DFLogoGripDown(id divider, SEL cmd, UIControl *sender) {
    if (DFLogoIsButton(divider, sender)) {
        DFLogoGripSession *session=DFLogoSession(divider, YES);
        session->pressed=(UIButton *)sender;
        session->holdRecognized=NO;
        session->changedPosition=NO;
        session->dividerPanOwned=NO;
    }
    ((void (*)(id, SEL, id))oldDFGripTouchDown)(divider, cmd, sender);
}

static void DFLogoGripUp(id divider, SEL cmd, UIControl *sender) {
    DFLogoGripSession *session=DFLogoSession(divider, NO);
    // Do not allow a late native UIControl touch-up to call onSwap after a hold.
    if (session && session->holdRecognized && sender==session->pressed) {
        if (oldDFGripTouchCancel)
            ((void (*)(id, SEL, id))oldDFGripTouchCancel)(
                divider, @selector(moveButtonTouchCancelled:), sender);
        return;
    }
    ((void (*)(id, SEL, id))oldDFGripTouchUp)(divider, cmd, sender);
}

static void DFLogoGripCancel(id divider, SEL cmd, UIControl *sender) {
    // Keep holdRecognized latched until the next touch-down. UIKit may deliver
    // cancellation and touch-up in either order while recognizers compete.
    ((void (*)(id, SEL, id))oldDFGripTouchCancel)(divider, cmd, sender);
}

static BOOL DFLogoDividerIsVertical(id divider) {
    return [divider respondsToSelector:@selector(isVertical)] &&
           ((BOOL (*)(id, SEL))objc_msgSend)(divider, @selector(isVertical));
}

static void DFLogoMoveWithHold(id divider, UILongPressGestureRecognizer *hold,
                               UIButton *button, DFLogoGripSession *session) {
    NSUInteger index=DFLogoIndexForButton(divider, button);
    id info=DFLogoConfigAtIndex(divider, index);
    if (!info || ![divider respondsToSelector:@selector(updateGripLayout)]) return;

    CGRect bounds=[(UIView *)divider bounds];
    BOOL vertical=DFLogoDividerIsVertical(divider);
    CGFloat extent=vertical ? bounds.size.height : bounds.size.width;
    CGFloat buttonExtent=vertical ? button.bounds.size.height : button.bounds.size.width;
    CGFloat edge=buttonExtent*0.5+4.0;
    if (!isfinite(extent) || !isfinite(buttonExtent) || extent<=edge*2.0) return;

    CGPoint pos=[hold locationInView:(UIView *)divider];
    CGFloat coordinate=vertical ? pos.y : pos.x;
    if (!isfinite(coordinate)) return;
    double fraction=coordinate/extent;
    const double margin=edge/extent;
    fraction=fmax(margin, fmin(1.0-margin, fraction));

    DFLogoSetRelativePos(info, fraction);
    session->hasPosition=YES;
    session->savedButtonIndex=index;
    session->savedRelativePos=fraction;
    session->changedPosition=YES;

    // Native implementation calculates the existing 28/30 pt touch frame,
    // orientation, edge clamping and image overlay position.
    ((void (*)(id, SEL))objc_msgSend)(divider, @selector(updateGripLayout));
}

static void DFLogoGripHold(id divider, SEL cmd, UIGestureRecognizer *recognizer) {
    UIButton *button=(UIButton *)recognizer.view;
    if (![recognizer isKindOfClass:[UILongPressGestureRecognizer class]] ||
        !DFLogoIsButton(divider, button)) {
        ((void (*)(id, SEL, id))oldDFGripLongPress)(divider, cmd, recognizer);
        return;
    }
    DFLogoGripSession *session=DFLogoSession(divider, YES);
    UIGestureRecognizerState state=recognizer.state;
    if (state==UIGestureRecognizerStateBegan) {
        session->pressed=button;
        session->holdRecognized=YES;
        session->changedPosition=NO;
        // Intentionally DO NOT call original onRotate. Holding stationary
        // must never rotate/swap the two CarPlay apps.
    } else if (state==UIGestureRecognizerStateChanged && session->holdRecognized &&
               session->pressed==button) {
        DFLogoMoveWithHold(divider, (UILongPressGestureRecognizer *)recognizer,
                           button, session);
    } else if (state==UIGestureRecognizerStateEnded ||
               state==UIGestureRecognizerStateCancelled ||
               state==UIGestureRecognizerStateFailed) {
        // Keep the hold latch until the next physical touch-down. It suppresses
        // a possible late native TouchUpInside -> onSwap event.
        session->dividerPanOwned=NO;
    }
}

static BOOL DFLogoTouchStartsOnButton(id divider, UIGestureRecognizer *pan) {
    CGPoint pos=[pan locationInView:(UIView *)divider];
    for (id item in DFGripArray(divider, "_moveButtons")) {
        if (![item isKindOfClass:[UIButton class]]) continue;
        UIButton *button=(UIButton *)item;
        CGRect hit=CGRectInset(button.frame, -4.0, -4.0);
        if (CGRectContainsPoint(hit, pos)) return YES;
    }
    return NO;
}
static void DFLogoDividerPan(id divider, SEL cmd, UIGestureRecognizer *pan) {
    DFLogoGripSession *session=DFLogoSession(divider, YES);
    if (pan.state==UIGestureRecognizerStateBegan) {
        // Capture only pans which STARTED on a logo, not drags beginning on
        // the divider elsewhere. This keeps native splitRatio pan intact.
        session->dividerPanOwned=
            (session->pressed && DFLogoIsButton(divider, session->pressed)) ||
            DFLogoTouchStartsOnButton(divider, pan);
    }
    BOOL swallow=session->dividerPanOwned;
    if (pan.state==UIGestureRecognizerStateEnded ||
        pan.state==UIGestureRecognizerStateCancelled ||
        pan.state==UIGestureRecognizerStateFailed) session->dividerPanOwned=NO;
    if (!swallow)
        ((void (*)(id, SEL, id))oldDFGripDividerPan)(divider, cmd, pan);
}

static BOOL DFInstallLogoGripHooks(DFHookFn hook, Class divider) {
    if (DFGripHooksInstalled) return YES;
    Class info=objc_getClass("CBDividerButtonInfo");
    if (!hook || !divider || !info ||
        !class_getInstanceVariable(divider, "_moveButtons") ||
        !class_getInstanceVariable(divider, "_buttonConfigs") ||
        !class_getInstanceMethod(info, @selector(setRelativePos:)) ||
        !class_getInstanceMethod(divider, @selector(updateGripLayout))) return NO;
    SEL selectors[]={
        @selector(moveButtonTouchDown:),
        @selector(moveButtonTouchUp:),
        @selector(moveButtonTouchCancelled:),
        @selector(handleMoveButtonLongPress:),
        @selector(handlePan:)
    };
    for (NSUInteger i=0;i<sizeof(selectors)/sizeof(selectors[0]);i++)
        if (!class_getInstanceMethod(divider, selectors[i])) return NO;

    hook(divider, @selector(moveButtonTouchDown:),
         (IMP)DFLogoGripDown, &oldDFGripTouchDown);
    hook(divider, @selector(moveButtonTouchUp:),
         (IMP)DFLogoGripUp, &oldDFGripTouchUp);
    hook(divider, @selector(moveButtonTouchCancelled:),
         (IMP)DFLogoGripCancel, &oldDFGripTouchCancel);
    hook(divider, @selector(handleMoveButtonLongPress:),
         (IMP)DFLogoGripHold, &oldDFGripLongPress);
    hook(divider, @selector(handlePan:),
         (IMP)DFLogoDividerPan, &oldDFGripDividerPan);
    DFGripHooksInstalled=YES;
    NSLog(@"[DuoFaceGrip] threshold=0.30s; tap=onSwap; hold=move logo; other pan=splitRatio");
    return YES;
}
