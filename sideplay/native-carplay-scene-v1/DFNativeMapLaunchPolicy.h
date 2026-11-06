// Foundation-only policy for a single bounded native-map launch request.
// This governs request lifetime and identity; it neither launches nor adopts.
#ifndef DF_NATIVE_MAP_LAUNCH_POLICY_H
#define DF_NATIVE_MAP_LAUNCH_POLICY_H
#import <Foundation/Foundation.h>
#import "DFNativeMapLaunchContext.h"
#import "DFNativeMapCommandProtocol.h"
#include <math.h>
#include <stdint.h>

typedef struct {
    uint64_t generation;
    NSTimeInterval startedMonotonic;
    NSTimeInterval deadlineMonotonic;
    BOOL active;
    BOOL attempted;
    BOOL submitted;
    BOOL adopting;
} DFNativeMapLaunchState;

typedef struct {
    BOOL physicalVerified;
    BOOL sameSession;
    BOOL samePane;
    BOOL leaseAbsent;
    NSUInteger matchingOwners;
    BOOL matchingOwnerReady;
} DFNativeMapLaunchEvidence;

typedef NS_ENUM(NSUInteger,DFNativeMapLaunchDecision) {
    DFNativeMapLaunchWaiting,
    DFNativeMapLaunchReadyToAdopt,
    DFNativeMapLaunchStaleGeneration,
    DFNativeMapLaunchTimedOut,
    DFNativeMapLaunchContextChanged,
    DFNativeMapLaunchSessionChanged,
    DFNativeMapLaunchPaneChanged,
    DFNativeMapLaunchLeaseChanged,
    DFNativeMapLaunchAmbiguousOwner
};
typedef NS_ENUM(NSUInteger,DFNativeMapAttachAction) {
    DFNativeMapAttachExistingOwner,
    DFNativeMapAttachStartLaunch,
    DFNativeMapAttachRejectMissing,
    DFNativeMapAttachRejectNotReady,
    DFNativeMapAttachRejectAmbiguous
};
NS_INLINE DFNativeMapAttachAction DFNativeMapSelectAttachAction(
    BOOL allowLaunch,NSUInteger matchingOwners,BOOL ownerReady) {
    if(matchingOwners>1)return DFNativeMapAttachRejectAmbiguous;
    if(matchingOwners==1)
        return ownerReady?DFNativeMapAttachExistingOwner:DFNativeMapAttachRejectNotReady;
    return allowLaunch?DFNativeMapAttachStartLaunch:DFNativeMapAttachRejectMissing;
}

NS_INLINE uint64_t DFNativeMapLaunchNextGeneration(uint64_t current) {
    return current==UINT64_MAX?1:current+1;
}
NS_INLINE BOOL DFNativeMapCommandGenerationMatches(uint64_t captured,uint64_t current) {
    return captured && captured==current;
}
NS_INLINE void DFNativeMapLaunchInvalidate(DFNativeMapLaunchState *state) {
    if(!state)return;
    state->generation=DFNativeMapLaunchNextGeneration(state->generation);
    state->active=NO;state->attempted=NO;state->submitted=NO;state->adopting=NO;
    state->startedMonotonic=0;state->deadlineMonotonic=0;
}
NS_INLINE BOOL DFNativeMapLaunchBegin(DFNativeMapLaunchState *state,
                                     NSTimeInterval nowMonotonic,
                                     NSTimeInterval originalCommandAge) {
    if(!state || state->active || !isfinite(nowMonotonic) || nowMonotonic<0 ||
       !isfinite(originalCommandAge) || originalCommandAge<0 || originalCommandAge>5.0 ||
       !isfinite(nowMonotonic+DFNativeMapServerLaunchTimeout))return NO;
    NSTimeInterval deadline=nowMonotonic+DFNativeMapServerLaunchTimeout-originalCommandAge;
    if(!isfinite(deadline) || deadline<=nowMonotonic)return NO;
    state->generation=DFNativeMapLaunchNextGeneration(state->generation);
    state->startedMonotonic=nowMonotonic;
    // Account for delivery age once, then use only monotonic time. Even a
    // late admitted command cannot outlive the phone's longer ACK deadline.
    state->deadlineMonotonic=deadline;
    state->attempted=NO;state->submitted=NO;state->adopting=NO;state->active=YES;
    return YES;
}
NS_INLINE BOOL DFNativeMapLaunchBeginForCommand(DFNativeMapLaunchState *state,
    uint64_t capturedCommandGeneration,uint64_t currentCommandGeneration,
    NSTimeInterval nowMonotonic,NSTimeInterval originalCommandAge) {
    return DFNativeMapCommandGenerationMatches(capturedCommandGeneration,currentCommandGeneration) &&
        DFNativeMapLaunchBegin(state,nowMonotonic,originalCommandAge);
}
NS_INLINE BOOL DFNativeMapLaunchIsCurrent(const DFNativeMapLaunchState *state,
                                         uint64_t generation) {
    return state && state->active && generation && state->generation==generation;
}
NS_INLINE BOOL DFNativeMapLaunchClaimAttempt(DFNativeMapLaunchState *state,
                                            uint64_t generation,
                                            NSTimeInterval nowMonotonic) {
    if(!DFNativeMapLaunchIsCurrent(state,generation) || state->attempted ||
       !isfinite(nowMonotonic) || nowMonotonic<state->startedMonotonic ||
       nowMonotonic>=state->deadlineMonotonic)return NO;
    // Commit before calling the native dispatcher: its event can reenter.
    state->attempted=YES;
    return YES;
}
NS_INLINE BOOL DFNativeMapLaunchMarkSubmitted(DFNativeMapLaunchState *state,
                                             uint64_t generation,
                                             NSTimeInterval nowMonotonic) {
    if(!DFNativeMapLaunchIsCurrent(state,generation) || !state->attempted ||
       state->submitted || !isfinite(nowMonotonic) ||
       nowMonotonic<state->startedMonotonic || nowMonotonic>=state->deadlineMonotonic)
        return NO;
    state->submitted=YES;
    return YES;
}
NS_INLINE BOOL DFNativeMapLaunchClaimAdoption(DFNativeMapLaunchState *state,
                                             uint64_t generation,
                                             NSTimeInterval nowMonotonic) {
    if(!DFNativeMapLaunchIsCurrent(state,generation) || !state->submitted ||
       state->adopting || !isfinite(nowMonotonic) ||
       nowMonotonic<state->startedMonotonic || nowMonotonic>=state->deadlineMonotonic)
        return NO;
    state->adopting=YES;
    return YES;
}
NS_INLINE DFNativeMapLaunchDecision DFNativeMapLaunchEvaluate(
    const DFNativeMapLaunchState *state,uint64_t generation,
    NSTimeInterval nowMonotonic,
    id<DFNativeMapLaunchContextIdentity> expected,
    id<DFNativeMapLaunchContextIdentity> current,
    DFNativeMapLaunchEvidence evidence) {
    if(!DFNativeMapLaunchIsCurrent(state,generation))
        return DFNativeMapLaunchStaleGeneration;
    if(!isfinite(nowMonotonic) || nowMonotonic<state->startedMonotonic ||
       nowMonotonic>=state->deadlineMonotonic)
        return DFNativeMapLaunchTimedOut;
    if(!DFNativeMapLaunchContextsMatch(expected,current))
        return DFNativeMapLaunchContextChanged;
    if(!evidence.physicalVerified || !evidence.sameSession)
        return DFNativeMapLaunchSessionChanged;
    if(!evidence.samePane)return DFNativeMapLaunchPaneChanged;
    if(!evidence.leaseAbsent)return DFNativeMapLaunchLeaseChanged;
    if(evidence.matchingOwners>1)return DFNativeMapLaunchAmbiguousOwner;
    if(state->submitted && !state->adopting &&
       evidence.matchingOwners==1 && evidence.matchingOwnerReady)
        return DFNativeMapLaunchReadyToAdopt;
    return DFNativeMapLaunchWaiting;
}
NS_INLINE NSString *DFNativeMapLaunchDecisionReason(DFNativeMapLaunchDecision decision) {
    switch(decision) {
        case DFNativeMapLaunchStaleGeneration:return @"native-launch-request-superseded";
        case DFNativeMapLaunchTimedOut:return @"native-launch-scene-observation-timeout";
        case DFNativeMapLaunchContextChanged:return @"native-launch-context-or-home-changed";
        case DFNativeMapLaunchSessionChanged:return @"native-launch-physical-session-changed-or-stale";
        case DFNativeMapLaunchPaneChanged:return @"native-launch-target-pane-changed";
        case DFNativeMapLaunchLeaseChanged:return @"native-launch-other-pane-lease-active";
        case DFNativeMapLaunchAmbiguousOwner:return @"native-launch-multiple-matching-owners";
        case DFNativeMapLaunchReadyToAdopt:return @"native-launch-owner-observed";
        case DFNativeMapLaunchWaiting:return @"native-launch-awaiting-observed-scene";
    }
    return @"native-launch-invalid-state";
}
NS_INLINE BOOL DFNativeMapLaunchCanCommit(const DFNativeMapLaunchState *state,
    uint64_t generation,uint64_t capturedCommandGeneration,uint64_t currentCommandGeneration,
    NSTimeInterval nowMonotonic,id<DFNativeMapLaunchContextIdentity> expected,
    uint64_t currentHomeGeneration,DFNativeMapLaunchEvidence evidence) {
    if(!state || !state->submitted || !state->adopting || !expected ||
       !DFNativeMapCommandGenerationMatches(capturedCommandGeneration,currentCommandGeneration) ||
       !currentHomeGeneration || expected.homeGeneration!=currentHomeGeneration ||
       evidence.matchingOwners!=1 || !evidence.matchingOwnerReady)return NO;
    return DFNativeMapLaunchEvaluate(state,generation,nowMonotonic,expected,expected,evidence)
        ==DFNativeMapLaunchWaiting;
}

NS_INLINE BOOL DFNativeMapFreshExplicitCommand(NSDictionary *command,
                                               NSTimeInterval now) {
    if(![command isKindOfClass:NSDictionary.class] ||
       !DFNativeMapProtocolNumber(command[@"Version"]) ||
       ![command[@"Version"] isEqual:@(DFNativeMapCommandVersion)] ||
       !DFNativeMapProtocolUUID(command[@"RequestID"]) ||
       !DFNativeMapProtocolOperation(command[@"Operation"]) ||
       !DFNativeMapProtocolNumber(command[@"Timestamp"]) ||
       [command[@"Timestamp"] doubleValue]<=0 || !isfinite(now))return NO;
    NSTimeInterval age=now-[command[@"Timestamp"] doubleValue];
    return isfinite(age) && age>=0 && age<=5.0;
}

// Retain consumed IDs for the entire bounded client interaction. This also
// rejects an old request reappearing after a newer request has superseded it.
// The bounded cache refuses admission on overflow instead of dropping an ID.
NS_INLINE BOOL DFNativeMapConsumeExplicitRequest(NSMutableDictionary *consumed,
    NSString *requestID,NSTimeInterval nowMonotonic) {
    if(!consumed || !DFNativeMapProtocolUUID(requestID) ||
       !isfinite(nowMonotonic) || nowMonotonic<0)return NO;
    for(NSString *key in consumed.allKeys) {
        NSNumber *deadline=consumed[key];
        if(!DFNativeMapProtocolNumber(deadline))return NO;
        if(nowMonotonic>=[deadline doubleValue])[consumed removeObjectForKey:key];
    }
    if(consumed[requestID] || consumed.count>=128 ||
       !isfinite(nowMonotonic+DFNativeMapClientAckTimeout))return NO;
    consumed[[requestID copy]]=@(nowMonotonic+DFNativeMapClientAckTimeout);
    return YES;
}
#endif
