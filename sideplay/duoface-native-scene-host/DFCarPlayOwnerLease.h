#ifndef DF_CARPLAY_OWNER_LEASE_H
#define DF_CARPLAY_OWNER_LEASE_H
#import <Foundation/Foundation.h>
#import "DFOwnerLeasePolicy.h"
static NSString *const DFOwnerEvidencePath=@"/var/mobile/Library/Preferences/com.duoface.nativehost.native-owner.v1.plist";
static NSString *const DFOwnerRevokePath=@"/var/mobile/Library/Preferences/com.duoface.nativehost.owner-revoke.v1.plist";
static const char *const DFOwnerRevokeNotify="com.duoface.nativehost.owner-revoke.v1";
static inline BOOL DFOwnerValidSession(id session) {
    return [session isKindOfClass:NSString.class] &&
           [[NSUUID alloc] initWithUUIDString:session]!=nil;
}
static inline BOOL DFOwnerRevokeMatches(NSDictionary *record, NSString *session) {
    // A Home revocation never expires for that UUID. New sessions use new UUIDs.
    return DFOwnerValidSession(session) && [record[@"Version"] isEqual:@1] &&
           [record[@"Session"] isEqual:session] && [record[@"Revoked"] isEqual:@YES];
}
static inline BOOL DFOwnerEvidenceMatches(NSDictionary *owner, NSString *session,
                                         NSString *hostSceneID, NSTimeInterval now) {
    if(!DFOwnerValidSession(session) || ![hostSceneID isKindOfClass:NSString.class] ||
       hostSceneID.length==0)return NO;
    id stamp=owner[@"Timestamp"],nativeID=owner[@"NativeSceneID"];
    return [owner[@"Version"] isEqual:@1] &&
        [owner[@"Session"] isEqual:session] && [owner[@"HostSceneID"] isEqual:hostSceneID] &&
        [owner[@"Active"] isEqual:@YES] && [owner[@"HomeHookReady"] isEqual:@YES] &&
        [owner[@"Process"] isEqual:@"CarPlay"] &&
        [owner[@"Bundle"] isEqual:@"com.duoface.native.scenehost"] &&
        [nativeID isKindOfClass:NSString.class] && [nativeID length]>0 &&
        [stamp isKindOfClass:NSNumber.class] &&
        DFOwnerFreshTime(now,[stamp doubleValue],1.25);
}
static inline BOOL DFOwnerAcceptRecords(NSDictionary *pulse, NSDictionary *owner,
                                       NSDictionary *revoke, NSTimeInterval now) {
    id session=pulse[@"Session"],stamp=pulse[@"Timestamp"],background=pulse[@"HostBackground"];
    if(![pulse[@"Version"] isEqual:@1] || ![pulse[@"Active"] isEqual:@YES] ||
       !DFOwnerValidSession(session) || ![stamp isKindOfClass:NSNumber.class] ||
       (background && ![background isKindOfClass:NSNumber.class]) ||
       !isfinite([stamp doubleValue]) || now<[stamp doubleValue] ||
       DFOwnerRevokeMatches(revoke,session))return NO;
    // An already bound native owner may renew while the phone app is suspended.
    // Only its independent 1.25s attestation can keep a Background session alive.
    if([background boolValue])
        return DFOwnerEvidenceMatches(owner,session,pulse[@"HostSceneID"],now);
    return DFOwnerFreshTime(now,[stamp doubleValue],2.5);
}
static inline BOOL DFOwnerSessionRevoked(NSString *session) {
    return !DFOwnerValidSession(session) || DFOwnerRevokeMatches(
        [NSDictionary dictionaryWithContentsOfFile:DFOwnerRevokePath],session);
}
static inline BOOL DFOwnerNativeEvidence(NSString *session, NSString *hostSceneID) {
    return !DFOwnerSessionRevoked(session) && DFOwnerEvidenceMatches(
        [NSDictionary dictionaryWithContentsOfFile:DFOwnerEvidencePath],session,hostSceneID,
        NSDate.date.timeIntervalSince1970);
}
static inline BOOL DFOwnerAcceptPulse(NSDictionary *pulse) {
    return DFOwnerAcceptRecords(pulse,
        [NSDictionary dictionaryWithContentsOfFile:DFOwnerEvidencePath],
        [NSDictionary dictionaryWithContentsOfFile:DFOwnerRevokePath],
        NSDate.date.timeIntervalSince1970);
}
#endif
