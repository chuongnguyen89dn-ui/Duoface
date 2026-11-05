// Read-only first-party session/owner evidence for the current native DuoFace
// base. This never creates, renews or rebinds an ownership attestation.
#ifndef DF_NATIVE_MAP_OWNED_BASE_POLICY_H
#define DF_NATIVE_MAP_OWNED_BASE_POLICY_H
#import <Foundation/Foundation.h>
#import "../duoface-native-scene-host/DFCarPlayOwnerLease.h"
#import "DFNativeMapCommandProtocol.h"

NS_INLINE NSString *DFNativeMapFreshLaunchSession(NSDictionary *pulse,
                                                  BOOL revoked,NSTimeInterval now) {
 if(![pulse isKindOfClass:NSDictionary.class] || revoked ||
    !DFNativeMapProtocolNumber(pulse[@"Version"]) || ![pulse[@"Version"] isEqual:@1] ||
    !DFNativeMapProtocolBool(pulse[@"Active"]) || ![pulse[@"Active"] isEqual:@YES] ||
    !DFOwnerValidSession(pulse[@"Session"]) ||
    ![pulse[@"HostSceneID"] isKindOfClass:NSString.class] ||
    ![pulse[@"HostSceneID"] length] ||
    !DFNativeMapProtocolNumber(pulse[@"Timestamp"]) || [pulse[@"Timestamp"] doubleValue]<=0 ||
    !DFOwnerFreshTime(now,[pulse[@"Timestamp"] doubleValue],2.5))return nil;
 return pulse[@"Session"];
}

// `candidate` must come from the existing visible+foreground owner scan.
// Pointer equality here is essential: a matching bundle alone grants nothing.
NS_INLINE BOOL DFNativeMapOwnedBaseRecordMatches(NSDictionary *pulse,
 NSDictionary *bound,NSDictionary *candidate,BOOL revoked,NSTimeInterval now) {
 NSString *session=DFNativeMapFreshLaunchSession(pulse,revoked,now);
 if(!session || ![bound isKindOfClass:NSDictionary.class] ||
    ![candidate isKindOfClass:NSDictionary.class])return NO;
 id controller=bound[@"Controller"],sceneID=bound[@"NativeSceneID"];
 return controller && controller!=NSNull.null &&
    [session isEqual:bound[@"Session"]] &&
    [pulse[@"HostSceneID"] isEqual:bound[@"HostSceneID"]] &&
    [sceneID isKindOfClass:NSString.class] && [sceneID length]>0 &&
    [candidate[@"Bundle"] isEqual:@"com.duoface.native.scenehost"] &&
    [candidate[@"SceneID"] isEqual:sceneID] &&
    candidate[@"Controller"]==controller;
}
#endif
