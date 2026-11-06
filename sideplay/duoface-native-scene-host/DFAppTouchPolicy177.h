// Foundation-only app activity and callback ownership policy, shared with
// executable tests. A verified app process is not proof of a particular scene.
#ifndef DF_APP_TOUCH_POLICY_177_H
#define DF_APP_TOUCH_POLICY_177_H
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#include <limits.h>
#include <math.h>
#include <stdint.h>

// Activity is an expiring event, unlike a retained keyboard-state snapshot.
// Both processes use the same device clock: accept no future timestamp, no
// event before this Chrome session, and at most two seconds of delivery delay.
static const NSTimeInterval DF177AppTouchMaximumAge = 2.0;
// JSON numbers remain exact throughout this range. At the sender's four
// events/second limit, exhausting it would take more than 70 million years.
static const uint64_t DF177AppTouchMaximumCount = UINT64_C(9007199254740991);

typedef struct {
    NSUInteger generation;
    NSTimeInterval startedAt;
    BOOL active;
} DF177AppTouchSession;

NS_INLINE NSUInteger DF177AppTouchNextGeneration(NSUInteger generation) {
    return generation == NSUIntegerMax ? 1 : generation + 1;
}

NS_INLINE DF177AppTouchSession DF177AppTouchBeginSession(
    DF177AppTouchSession previous, NSTimeInterval now) {
    DF177AppTouchSession session = {0};
    session.generation = DF177AppTouchNextGeneration(previous.generation);
    session.active = isfinite(now) && now > 0;
    session.startedAt = session.active ? now : 0;
    return session;
}

NS_INLINE DF177AppTouchSession DF177AppTouchEndSession(
    DF177AppTouchSession previous) {
    DF177AppTouchSession session = {0};
    session.generation = DF177AppTouchNextGeneration(previous.generation);
    return session;
}

NS_INLINE BOOL DF177AppTouchSessionMatches(DF177AppTouchSession session,
    NSUInteger capturedGeneration, id owner, id currentOwner) {
    return owner && owner == currentOwner && session.active &&
           capturedGeneration != 0 && session.generation == capturedGeneration;
}

NS_INLINE BOOL DF177AppTouchRecheckAllowed(DF177AppTouchSession session,
    NSUInteger capturedSession, id owner, id currentOwner,
    NSUInteger capturedRecheck, NSUInteger currentRecheck) {
    return DF177AppTouchSessionMatches(session,capturedSession,owner,currentOwner) &&
           capturedRecheck != 0 && capturedRecheck == currentRecheck;
}

NS_INLINE BOOL DF177AppTouchNumber(id value) {
    return [value isKindOfClass:NSNumber.class] &&
           CFGetTypeID((__bridge CFTypeRef)value) != CFBooleanGetTypeID();
}

NS_INLINE BOOL DF177AppTouchInteger(id value, double minimum, double maximum) {
    if(!DF177AppTouchNumber(value))return NO;
    double number = [value doubleValue];
    return isfinite(number) && number >= minimum && number <= maximum &&
           floor(number) == number;
}

// liveProcesses must be built from DFSceneHost's current live hosted surfaces
// and verifiedPIDForHostedView:, never from the sender's claimed bundle/PID.
// Legacy v1 has no process identity and is intentionally unverified. Existing
// app processes retaining the old relay must be relaunched after the upgrade.
NS_INLINE BOOL DF177AppTouchRecordMatches(id record, NSDictionary *liveProcesses,
    NSTimeInterval sessionStartedAt, NSTimeInterval now) {
    if(![record isKindOfClass:NSDictionary.class] ||
       ![liveProcesses isKindOfClass:NSDictionary.class] ||
       !DF177AppTouchInteger(record[@"version"],2,2))return NO;
    NSString *bundle = record[@"bundle"];
    if(![bundle isKindOfClass:NSString.class] || !bundle.length ||
       bundle.length > 128)return NO;
    NSNumber *pid = liveProcesses[bundle];
    if(!DF177AppTouchInteger(pid,2,INT_MAX) ||
       !DF177AppTouchInteger(record[@"pid"],2,INT_MAX) ||
       ![record[@"pid"] isEqual:pid] ||
       !DF177AppTouchInteger(record[@"count"],1,(double)DF177AppTouchMaximumCount) ||
       !DF177AppTouchNumber(record[@"ts"]))return NO;
    NSTimeInterval stamp = [record[@"ts"] doubleValue];
    return isfinite(now) && isfinite(sessionStartedAt) && isfinite(stamp) &&
           sessionStartedAt > 0 && now >= sessionStartedAt &&
           stamp >= sessionStartedAt && stamp <= now &&
           now - stamp <= DF177AppTouchMaximumAge;
}
#endif
