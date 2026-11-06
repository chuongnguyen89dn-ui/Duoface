// Existing app-side dispatch gate. No additional hook or window.
#import <UIKit/UIKit.h>
#import "DFCarPlayOwnerLease.h"
#ifndef DF176_WAKE_READ_RECORD
#define DF176_WAKE_READ_RECORD(path) [NSDictionary dictionaryWithContentsOfFile:(path)]
#endif
static NSString *const DF176WakeStatePath=@"/var/mobile/Library/Preferences/com.duoface.nativehost.wake-state.v1.plist";
#ifdef DF177_APP_SIDE_SENDER
static BOOL DF176ConsumeWakeEvent(UIEvent *event,NSString *bundle) {
    static NSMutableSet *captured,*forwarded;
    static NSTimeInterval recalledUntil;
    if(event.type!=UIEventTypeTouches)return NO;
    if(!captured){captured=[NSMutableSet new];forwarded=[NSMutableSet new];}
    BOOL began=NO;
    for(UITouch *touch in event.allTouches)if(touch.phase==UITouchPhaseBegan)began=YES;
    BOOL consume=captured.count>0;
    if(!consume && !forwarded.count && began && DF177AppTouchEnabled()) {
        NSTimeInterval now=NSDate.date.timeIntervalSince1970;
        NSDictionary *state=DF176_WAKE_READ_RECORD(DF176WakeStatePath);
        NSDictionary *pulse=DF176_WAKE_READ_RECORD(@"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist");
        id deadline=state[@"Until"],stamp=state[@"Timestamp"];
        if([state[@"Version"] isEqual:@1] && [state[@"Eligible"] isEqual:@YES] &&
           [state[@"Session"] isEqual:pulse[@"Session"]] && DFOwnerAcceptPulse(pulse) &&
           [state[@"Processes"][bundle] isEqual:@(getpid())] &&
           [deadline isKindOfClass:NSNumber.class] && [stamp isKindOfClass:NSNumber.class] &&
           isfinite([deadline doubleValue]) && isfinite([stamp doubleValue]) &&
           [stamp doubleValue]<=now && now-[stamp doubleValue]<=1.0 && now>=[deadline doubleValue] &&
           now>=recalledUntil) {
            consume=YES;recalledUntil=now+4.0;
            // A reserved first contact must not be lost to observation throttling.
            DF177TouchLastSentAt=0;
            DF177AppTouchNoteBegan(bundle);
        }
    }
    NSMutableSet *tracking=consume?captured:forwarded;
    for(UITouch *touch in event.allTouches) {
        if(touch.phase==UITouchPhaseEnded || touch.phase==UITouchPhaseCancelled)
            [tracking removeObject:touch];
        else [tracking addObject:touch];
    }
    return consume;
}
#endif
