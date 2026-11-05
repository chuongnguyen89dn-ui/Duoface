// Foundation-only keyboard evidence policy, shared with executable tests.
// Window-list misses are not hide events. Keep weak identities learned from
// visibility notifications until those windows hide or are deallocated.
#ifndef DF_KEYBOARD_STATE_177_H
#define DF_KEYBOARD_STATE_177_H
#import <Foundation/Foundation.h>
#include <math.h>

static const char *const DF177KbMailboxName="com.duoface.ipc.v177.kbstate";
NS_INLINE NSString *DF177KeyboardChannelName(NSString *bundle) {
    if(![bundle isKindOfClass:NSString.class] || !bundle.length ||
       bundle.length>128)return nil;
    return [NSString stringWithFormat:@"%s.%@",DF177KbMailboxName,bundle];
}

@protocol DF177ObservedKeyboardWindow <NSObject>
- (BOOL)isHidden;
@end

NS_INLINE BOOL DF177KeyboardBeginPublish(BOOL visible, BOOL lastVisible,
                                         BOOL *lastPublishSucceeded) {
    if(!lastPublishSucceeded)return NO;
    if(visible==lastVisible && *lastPublishSucceeded)return NO;
    // An attempted transition can invalidate or partially replace the
    // retained mailbox. A failed attempt must be retried even if the next
    // event returns to the previously acknowledged visibility value.
    *lastPublishSucceeded=NO;
    return YES;
}

NS_INLINE void DF177ObserveKeyboardWindow(NSHashTable *known, id window,
                                         BOOL visible) {
    if(!known || !window)return;
    if(visible)[known addObject:window];
    else [known removeObject:window];
}

NS_INLINE BOOL DF177KeyboardSnapshot(NSHashTable *known, NSArray *scanned) {
    // A scan contributes positive evidence only; absence cannot revoke a
    // notification-observed window that the public window lists omit.
    for(id<DF177ObservedKeyboardWindow> window in scanned)
        if(!window.isHidden)[known addObject:window];
    BOOL visible=NO;
    for(id<DF177ObservedKeyboardWindow> window in known.allObjects) {
        if(window.isHidden)[known removeObject:window];
        else visible=YES;
    }
    return visible;
}

NS_INLINE BOOL DF177KeyboardRecordMatches(NSDictionary *record,
                                          NSString *bundle, NSNumber *pid,
                                          NSTimeInterval now) {
    if(![record isKindOfClass:NSDictionary.class] ||
       ![record[@"version"] isEqual:@2] || !bundle.length ||
       ![record[@"bundle"] isEqual:bundle] ||
       ![pid isKindOfClass:NSNumber.class] || pid.intValue<=1 ||
       ![record[@"pid"] isKindOfClass:NSNumber.class] ||
       ![record[@"pid"] isEqual:pid] ||
       ![record[@"kb"] isKindOfClass:NSNumber.class] ||
       (![record[@"kb"] isEqual:@0] && ![record[@"kb"] isEqual:@1]) ||
       ![record[@"ts"] isKindOfClass:NSNumber.class])return NO;
    NSTimeInterval stamp=[record[@"ts"] doubleValue];
    // This is a retained per-process state snapshot, not an expiring event.
    // A quiet keyboard stays valid while its exact hosted process is alive.
    // A process restart is rejected by PID, and future/invalid records fail.
    return isfinite(now) && isfinite(stamp) && stamp>0 && stamp<=now+1.0;
}
#endif
