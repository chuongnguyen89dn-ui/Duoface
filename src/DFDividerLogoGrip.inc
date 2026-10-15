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
    BOOL dividerPanOwned;         // long hold owns a later pan, not a quick drag
    BOOL nativeDividerPanActive;  // native ratio resize already started
    BOOL nativeDividerPanMoved;   // latch until next touch-down, protect onSwap
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
        session->nativeDividerPanActive=NO;
        session->nativeDividerPanMoved=NO;
    }
    ((void (*)(id, SEL, id))oldDFGripTouchDown)(divider, cmd, sender);
}

static void DFLogoGripUp(id divider, SEL cmd, UIControl *sender) {
    DFLogoGripSession *session=DFLogoSession(divider, NO);
    // Do not allow a late native UIControl touch-up to call onSwap after a hold.
    if (session && (session->holdRecognized || session->nativeDividerPanMoved) &&
        sender==session->pressed) {
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
        // The first recognized gesture owns the touch: if the user already
        // dragged the split divider, NEVER hijack it into a logo drag.
        if (session->nativeDividerPanActive || session->nativeDividerPanMoved)
            return;
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

static void DFLogoDividerPan(id divider, SEL cmd, UIGestureRecognizer *pan) {
    DFLogoGripSession *session=DFLogoSession(divider, YES);
    UIGestureRecognizerState state=pan.state;
    if (state==UIGestureRecognizerStateBegan) {
        // Preserve native splitRatio drag EVEN when it starts on the logo:
        // a pan recognized BEFORE the 0.30s hold belongs to the divider.
        // Only a long press which was already recognized may own a later pan.
        session->dividerPanOwned=
            session->holdRecognized && session->pressed &&
            DFLogoIsButton(divider, session->pressed);
        session->nativeDividerPanActive=!session->dividerPanOwned;
    }
    BOOL swallow=session->dividerPanOwned;
    if (state==UIGestureRecognizerStateChanged &&
        session->nativeDividerPanActive && !swallow && session->pressed)
        session->nativeDividerPanMoved=YES;
    if (state==UIGestureRecognizerStateEnded ||
        state==UIGestureRecognizerStateCancelled ||
        state==UIGestureRecognizerStateFailed) {
        session->dividerPanOwned=NO;
        session->nativeDividerPanActive=NO;
        // nativeDividerPanMoved stays set until the next touch-down to avoid
        // any late touchUpInside erroneously swapping while resizing.
    }
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
