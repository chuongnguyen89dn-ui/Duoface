// DuoFace first-party native Maps membership receipt.
// CarPlay writes; DuoFaceNativeHost and SpringBoard only validate.
#ifndef DF184_NATIVE_MAP_MEMBERSHIP_H
#define DF184_NATIVE_MAP_MEMBERSHIP_H
#import <Foundation/Foundation.h>
#import <math.h>
static NSString *const DF184MapMembershipPath=
 @"/var/mobile/Library/Preferences/com.duoface.nativehost.maps-membership.v1.plist";
// Notification only wakes the consumer; the strict on-disk receipt authenticates.
static const char *const DF184MapMembershipChanged =
 "com.duoface.nativehost.maps-membership.changed.v1";
static inline BOOL DF184UUID(id obj) {
 return [obj isKindOfClass:NSString.class] &&
  [[NSUUID alloc]initWithUUIDString:(NSString *)obj]!=nil;
}
static inline BOOL DF184Fresh(NSTimeInterval now,id stamp,double ageLimit) {
 if(![stamp isKindOfClass:NSNumber.class]||!isfinite(now))return NO;
 double age=now-[stamp doubleValue];
 return isfinite(age)&&age>=0&&age<=ageLimit;
}
// Only a real post-original CarPlay presentation can grant PRESENTED (0.85s);
// COMMITTED requires continuous fresh verification of the same native pane.
// Neither intent nor launch/geometry receipt alone authorizes a watchdog lease.
static inline BOOL DF184MapMembershipAccepted(NSDictionary *pulse,
 NSDictionary *homeOwner,NSDictionary *member,NSDictionary *assignment,
 NSDictionary *revoke,NSTimeInterval now) {
 id session=pulse[@"Session"],aid=assignment[@"AssignmentID"];
 if(!DF184UUID(session)||!DF184UUID(aid) ||
    ![pulse[@"Version"] isEqual:@1] || ![pulse[@"Active"] isEqual:@YES] ||
    ![pulse[@"HostBackground"] isEqual:@YES] ||
    ![pulse[@"HostSceneID"] isKindOfClass:NSString.class] ||
    [pulse[@"HostSceneID"] length]==0 ||
    ![assignment[@"Version"] isEqual:@2] ||
    ![assignment[@"Session"] isEqual:session] ||
    ![assignment[@"BundleID"] isEqual:@"com.google.Maps"] ||
    ![assignment[@"PhysicalSlot"] isKindOfClass:NSNumber.class] ||
    [assignment[@"PhysicalSlot"] integerValue]<0 ||
    [assignment[@"PhysicalSlot"] integerValue]>1 ||
    ![assignment[@"Slot"] isKindOfClass:NSNumber.class] ||
    [assignment[@"Slot"] integerValue]<0 ||
    [assignment[@"Slot"] integerValue]>1 ||
    ([revoke[@"Version"] isEqual:@1] &&
     [revoke[@"Session"] isEqual:session] &&
     [revoke[@"Revoked"] isEqual:@YES]))return NO;
 // Old host may be inactive, but exact session native Home hook must stay live.
 if(![homeOwner[@"Version"] isEqual:@1] ||
    ![homeOwner[@"Session"] isEqual:session] ||
    ![homeOwner[@"HostSceneID"] isEqual:pulse[@"HostSceneID"]] ||
    ![homeOwner[@"Process"] isEqual:@"CarPlay"] ||
    ![homeOwner[@"HomeHookReady"] isEqual:@YES] ||
    !DF184Fresh(now,homeOwner[@"Timestamp"],1.25))return NO;
 if(![member[@"Version"] isEqual:@1] ||
    ![member[@"Process"] isEqual:@"CarPlay"] ||
    ![member[@"Session"] isEqual:session] ||
    ![member[@"HostSceneID"] isEqual:pulse[@"HostSceneID"]] ||
    ![member[@"AssignmentID"] isEqual:aid] ||
    ![member[@"PhysicalSlot"] isEqual:assignment[@"PhysicalSlot"]] ||
    ![member[@"BundleID"] isEqual:@"com.google.Maps"] ||
    ![member[@"ControllerClass"] isEqual:@"DBApplicationSceneViewController"] ||
    ![member[@"SceneClass"] isEqual:@"FBScene"] ||
    ![member[@"NativeSceneID"] isKindOfClass:NSString.class] ||
    [member[@"NativeSceneID"] length]==0 ||
    [member[@"NativeSceneID"] isEqual:@"unknown"] ||
    ![member[@"PresentationSource"] isEqual:
       @"DBDashboardRootViewController.presentBase:post-original"] ||
    ![member[@"WindowRole"] isEqual:@"UIWindowSceneSessionRoleCarPlay"] ||
    ![member[@"WindowExternal"] isEqual:@YES] ||
    ![member[@"WindowVisible"] isEqual:@YES] ||
    ![member[@"SceneHostAttached"] isEqual:@YES] ||
    !DF184Fresh(now,member[@"Timestamp"],1.25) ||
    ![member[@"PresentedAt"] isKindOfClass:NSNumber.class] ||
    now<[member[@"PresentedAt"] doubleValue])return NO;
 NSString *stage=member[@"Stage"];
 if([stage isEqual:@"PRESENTED"])
  return [member[@"PaneBound"] isEqual:@NO] &&
    [member[@"PaneFrameVerified"] isEqual:@NO] &&
    DF184Fresh(now,member[@"PresentedAt"],0.85);
 if([stage isEqual:@"COMMITTED"])
  return [member[@"PaneBound"] isEqual:@YES] &&
    [member[@"PaneFrameVerified"] isEqual:@YES] &&
    [member[@"HitRegionVerified"] isEqual:@YES];
 return NO; // REVOKED/MISSING/STALE/CONFLICT always fail closed.
}
#endif
