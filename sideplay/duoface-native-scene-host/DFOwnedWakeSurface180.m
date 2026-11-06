#import "DFOwnedWakeSurface180.h"
@interface DFOwnedWakeSurface180 ()
@property(nonatomic,strong) NSMutableSet<UITouch *> *wakeContacts180;
@end
@implementation DFOwnedWakeSurface180
- (instancetype)initWithFrame:(CGRect)frame {
    if((self=[super initWithFrame:frame]))self.multipleTouchEnabled=YES;
    return self;
}
- (BOOL)hasWakeContacts180 { return self.wakeContacts180.count>0; }
- (BOOL)reservesWakeAtPoint180:(CGPoint)point event:(UIEvent *)event {
    if(!self.window || self.hidden || self.alpha<=0.01 ||
       !self.userInteractionEnabled || ![self pointInside:point withEvent:event])return NO;
    // An already delivered visible-state gesture keeps its original child.
    // Expiry may not seize its tail or the other fingers in that gesture.
    for(UITouch *touch in event.allTouches) {
        UIView *view=touch.view;
        if(view && view!=self && [view isDescendantOfView:self] &&
           touch.phase!=UITouchPhaseEnded && touch.phase!=UITouchPhaseCancelled)return NO;
    }
    if(self.hasWakeContacts180)return YES;
    return self.wakeCaptureAllowed180 && self.wakeCaptureAllowed180();
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // Choose the host-side receiver BEFORE entering the remote app subtree.
    // Initial UIKit hit-testing need not have populated event.allTouches yet.
    // A nil-event hit-test does not wake anything; actual touchesBegan does.
    if([self reservesWakeAtPoint180:point event:event])return self;
    return [super hitTest:point withEvent:event];
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSMutableSet *forward=[touches mutableCopy];
    BOOL wasCapturing=self.hasWakeContacts180;
    for(UITouch *touch in touches) {
        // Responder-chain calls from child app views are not our wake contact.
        if(touch.view!=self || (!self.wakeContact180 && !wasCapturing))continue;
        if(!self.wakeContacts180)self.wakeContacts180=[NSMutableSet new];
        [self.wakeContacts180 addObject:touch];[forward removeObject:touch];
    }
    if(!wasCapturing && self.hasWakeContacts180 && self.wakeContact180)
        self.wakeContact180(@"began",self.wakeContacts180.count);
    if(forward.count)[super touchesBegan:forward withEvent:event];
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSMutableSet *forward=[touches mutableCopy];
    [forward minusSet:self.wakeContacts180?:[NSSet set]];
    if(forward.count)[super touchesMoved:forward withEvent:event];
}
- (void)finishWakeTouches180:(NSSet<UITouch *> *)touches event:(UIEvent *)event cancelled:(BOOL)cancelled {
    NSMutableSet *forward=[touches mutableCopy];
    BOOL wasCapturing=self.hasWakeContacts180;
    [forward minusSet:self.wakeContacts180?:[NSSet set]];
    [self.wakeContacts180 minusSet:touches];
    if(wasCapturing && !self.hasWakeContacts180 && self.wakeContact180)
        self.wakeContact180(cancelled?@"cancelled":@"ended",0);
    // A captured contact is NEVER forwarded or replayed, including its end.
    if(forward.count) {
        if(cancelled)[super touchesCancelled:forward withEvent:event];
        else [super touchesEnded:forward withEvent:event];
    }
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self finishWakeTouches180:touches event:event cancelled:NO];
}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self finishWakeTouches180:touches event:event cancelled:YES];
}
@end
