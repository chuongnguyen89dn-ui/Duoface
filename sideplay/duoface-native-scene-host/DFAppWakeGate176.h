// Existing per-app dispatch gate. No new hook, overlay window or HID replay.
// For a main-display hosted app the UIWindow may have UIScreen.mainScreen;
// provenance is the exact SpringBoard-owned FBScene/session identifier, not
// a guessed 'external screen' test. A mismatch fails OPEN to the app.
#import <UIKit/UIKit.h>
#import "DFCarPlayOwnerLease.h"
#ifndef DF176_WAKE_READ_RECORD
#define DF176_WAKE_READ_RECORD(path) [NSDictionary dictionaryWithContentsOfFile:(path)]
#endif
static NSString *const DF176WakeStatePath=@"/var/mobile/Library/Preferences/com.duoface.nativehost.wake-state.v1.plist";
#ifdef DF177_APP_SIDE_SENDER
static BOOL DF176TouchInOwnedScene(UITouch *touch,NSString *sceneID) {
    if(![sceneID isKindOfClass:NSString.class] || !sceneID.length ||
       ![touch isKindOfClass:UITouch.class])return NO;
    UIWindow *window=touch.window;
    if(![window isKindOfClass:UIWindow.class] ||
       window.hidden || !window.userInteractionEnabled ||
       DF177IsKeyboardWindow(window))return NO;
    UIWindowScene *scene=window.windowScene;
    NSString *observed=scene.session.persistentIdentifier;
    return [observed isKindOfClass:NSString.class] &&
           [observed isEqualToString:sceneID];
}
static BOOL DF176EventOwnedByScene(UIEvent *event,NSString *sceneID) {
    if(![event.allTouches isKindOfClass:NSSet.class] ||
       !event.allTouches.count)return NO;
    for(UITouch *touch in event.allTouches)
        if(!DF176TouchInOwnedScene(touch,sceneID))return NO;
    return YES;
}
static BOOL DF176ConsumeWakeEvent(UIEvent *event,NSString *bundle) {
    static NSMutableSet *captured,*forwarded;
    static NSString *capturedScene;
    static NSTimeInterval recalledUntil;
    if(event.type!=UIEventTypeTouches)return NO;
    if(!captured){captured=[NSMutableSet new];forwarded=[NSMutableSet new];}
    BOOL began=NO;
    for(UITouch *touch in event.allTouches)
        if(touch.phase==UITouchPhaseBegan)began=YES;
    BOOL consume=captured.count>0;
    // A phone-scene contact joining a captured CarPlay gesture is not ours.
    // We cannot split a UIKit event, so release the entire event to UIKit
    // rather than swallow the foreign contact.
    if(consume && !DF176EventOwnedByScene(event,capturedScene)) {
        [forwarded unionSet:captured];
        [captured removeAllObjects];
        capturedScene=nil;
        consume=NO;
    }
    if(!consume && !forwarded.count && began && DF177AppTouchEnabled() &&
       NSThread.isMainThread) {
        NSTimeInterval now=NSDate.date.timeIntervalSince1970;
        NSDictionary *state=DF176_WAKE_READ_RECORD(DF176WakeStatePath);
        NSDictionary *pulse=DF176_WAKE_READ_RECORD(@"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist");
        id deadline=state[@"Until"],stamp=state[@"Timestamp"];
        NSString *sceneID=state[@"Scenes"][bundle];
        if([state[@"Version"] isEqual:@2] && [state[@"Eligible"] isEqual:@YES] &&
           [state[@"KeyboardKnown"] isEqual:@YES] &&
           [state[@"KeyboardVisible"] isEqual:@NO] &&
           [state[@"Session"] isEqual:pulse[@"Session"]] && DFOwnerAcceptPulse(pulse) &&
           [state[@"Processes"][bundle] isEqual:@(getpid())] &&
           [deadline isKindOfClass:NSNumber.class] && [stamp isKindOfClass:NSNumber.class] &&
           isfinite([deadline doubleValue]) && isfinite([stamp doubleValue]) &&
           [stamp doubleValue]<=now && now-[stamp doubleValue]<=1.0 &&
           now>=[deadline doubleValue] && now>=recalledUntil &&
           DF176EventOwnedByScene(event,sceneID) && !DF177KbComputeVisible()) {
            // Do not lose the user's touch when the mailbox/notify failed.
            // Host receipt and on-screen wake remain separately measurable.
            if(DF177AppTouchNoteBegan(bundle,YES)) {
                consume=YES;
                capturedScene=[sceneID copy];
                recalledUntil=now+4.0;
            }
        }
    }
    NSMutableSet *tracking=consume?captured:forwarded;
    for(UITouch *touch in event.allTouches) {
        if(touch.phase==UITouchPhaseEnded || touch.phase==UITouchPhaseCancelled)
            [tracking removeObject:touch];
        else [tracking addObject:touch];
    }
    if(!captured.count)capturedScene=nil;
    return consume;
}
#endif
