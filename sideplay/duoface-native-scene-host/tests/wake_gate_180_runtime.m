// Executes the production owned-view gate against a small UIKit dispatch model.
// Not a real UIKit simulator, remote HID path or physical CarPlay test.
#import "../DFOwnedWakeSurface180.h"
#include <assert.h>
static UITouch *touch(UIView *view,UIWindow *window) {
    UITouch *t=[UITouch new];t.view=view;t.window=window;t.phase=UITouchPhaseBegan;return t;
}
int main(void) {@autoreleasepool {
    UIWindow *window=[[UIWindow alloc]initWithFrame:CGRectMake(0,0,100,100)];window.window=window;
    DFOwnedWakeSurface180 *gate=[[DFOwnedWakeSurface180 alloc]initWithFrame:window.bounds];gate.window=window;
    UIView *button=[[UIView alloc]initWithFrame:window.bounds];[gate addSubview:button];
    __block BOOL hidden=YES;__block NSUInteger wakes=0,finishes=0;
    gate.wakeCaptureAllowed180=^BOOL{return hidden;};
    gate.wakeContact180=^(NSString *phase,NSUInteger count){
        if([phase isEqual:@"began"]){assert(count>0);wakes++;hidden=NO;}
        else {assert(count==0);finishes++;}
    };
    CGPoint point=CGPointMake(25,25);UIEvent *e=[UIEvent new];e.allTouches=[NSSet set];
    assert([gate hitTest:point withEvent:nil]==gate && wakes==0 && hidden);
    for(NSUInteger i=0;i<20;i++) {
        hidden=YES;e.allTouches=[NSSet set];
        // Empty preflight allTouches must not bypass the gate.
        UIView *target=[gate hitTest:point withEvent:e];assert(target==gate);
        UITouch *t=touch(target,window);e.allTouches=[NSSet setWithObject:t];
        [target touchesBegan:e.allTouches withEvent:e];assert(!hidden && gate.hasWakeContacts180);
        t.phase=UITouchPhaseMoved;[target touchesMoved:e.allTouches withEvent:e];
        t.phase=UITouchPhaseEnded;[target touchesEnded:e.allTouches withEvent:e];
        assert(!gate.hasWakeContacts180 && button.forwardedEnd==i);
        e.allTouches=[NSSet set];target=[gate hitTest:point withEvent:e];assert(target==button);
        t=touch(target,window);e.allTouches=[NSSet setWithObject:t];
        [target touchesBegan:e.allTouches withEvent:e];t.phase=UITouchPhaseEnded;
        [target touchesEnded:e.allTouches withEvent:e];assert(button.forwardedEnd==i+1);
    }
    assert(wakes==20 && finishes==20 && gate.forwardedBegan==0 && gate.forwardedEnd==0);
    // Expiry must not seize the tail/additional finger of an existing child gesture.
    hidden=NO;e.allTouches=[NSSet set];assert([gate hitTest:point withEvent:e]==button);
    UITouch *drag=touch(button,window);drag.phase=UITouchPhaseMoved;e.allTouches=[NSSet setWithObject:drag];
    hidden=YES;assert([gate hitTest:point withEvent:e]==button && wakes==20);
    // Two fingers in a wake gesture remain consumed until both are finished.
    e.allTouches=[NSSet set];assert([gate hitTest:point withEvent:e]==gate);
    UITouch *a=touch(gate,window),*b=touch(gate,window);
    [gate touchesBegan:[NSSet setWithObject:a] withEvent:e];
    e.allTouches=[NSSet setWithObject:a];assert([gate hitTest:point withEvent:e]==gate);
    [gate touchesBegan:[NSSet setWithObject:b] withEvent:e];assert(wakes==21);
    a.phase=UITouchPhaseEnded;[gate touchesEnded:[NSSet setWithObject:a] withEvent:e];assert(gate.hasWakeContacts180);
    b.phase=UITouchPhaseCancelled;[gate touchesCancelled:[NSSet setWithObject:b] withEvent:e];assert(!gate.hasWakeContacts180 && finishes==21);
    // Existing child responder-chain events and visible keyboard/control input pass.
    UITouch *foreign=touch(button,window);[gate touchesBegan:[NSSet setWithObject:foreign] withEvent:e];
    assert(gate.forwardedBegan==1 && wakes==21);
    e.allTouches=[NSSet set];hidden=YES;gate.userInteractionEnabled=NO;
    assert([gate hitTest:point withEvent:e]==nil && wakes==21);
    gate.userInteractionEnabled=YES;gate.wakeCaptureAllowed180=^BOOL{return NO;};
    assert([gate hitTest:point withEvent:e]==button && wakes==21);
    puts("QA180_PRODUCTION_WAKE_GATE_BEHAVIOR_PASS_20_CYCLES_CANCEL_MULTI_VISIBLE_DRAG_NO_REPLAY");
    return 0;
}}
