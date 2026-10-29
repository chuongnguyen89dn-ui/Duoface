// First-party native-CarPlay owner lease: short-lived process identity proof.
// The current car display may be terminated only on user-enabled physical unplug
// and after SpringBoard validates the same live PID + phone foreground guard.
// Values never contain process pointers, handles, cookies, or vendor state.
#ifndef DF_NATIVE_MAP_LEASE_POLICY_H
#define DF_NATIVE_MAP_LEASE_POLICY_H
#import <Foundation/Foundation.h>
#import <math.h>
static NSString *const DFNativeMapLeasePath =
 @"/var/mobile/Library/Preferences/com.duoface.nativehost.native-map-lease.v1.plist";
static NSString *const DFNativeMapChoicePath =
 @"/var/mobile/Library/Preferences/com.duoface.nativehost.native-map-choice.v1.plist";
NS_INLINE BOOL DFNativeMapAllowedBundle(id bundle) {
 return [bundle isKindOfClass:NSString.class] &&
   [@[@"com.google.Maps",@"com.apple.Maps",@"com.waze.iphone"] containsObject:bundle];
}
NS_INLINE NSDictionary *DFNativeMapFreshLeaseAtPath(NSString *path,
   NSString *session,NSTimeInterval now) {
 if(![path isKindOfClass:NSString.class] || !path.length ||
    ![session isKindOfClass:NSString.class] ||
    ![[NSUUID alloc]initWithUUIDString:session] || !isfinite(now))return nil;
 NSDictionary *v=[NSDictionary dictionaryWithContentsOfFile:path];
 if(![v isKindOfClass:NSDictionary.class] || ![v[@"Version"] isEqual:@1] ||
    ![v[@"Session"] isEqual:session] || !DFNativeMapAllowedBundle(v[@"BundleID"]) ||
    ![v[@"Slot"] isKindOfClass:NSNumber.class] ||
    [v[@"Slot"] integerValue]<0 || [v[@"Slot"] integerValue]>1 ||
    ![v[@"Timestamp"] isKindOfClass:NSNumber.class])return nil;
 double age=now-[v[@"Timestamp"] doubleValue];
 return isfinite(age)&&age>=0&&age<=5.0?v:nil;
}
NS_INLINE NSDictionary *DFNativeMapFreshLease(NSString *session,NSTimeInterval now) {
 return DFNativeMapFreshLeaseAtPath(DFNativeMapLeasePath,session,now);
}
NS_INLINE BOOL DFNativeMapWriteLeaseAtPath(NSString *path,NSString *session,
   NSString *bundle,NSInteger slot,NSTimeInterval now) {
 if(![path isKindOfClass:NSString.class] || !path.length ||
    ![session isKindOfClass:NSString.class] ||
    ![[NSUUID alloc]initWithUUIDString:session] || !DFNativeMapAllowedBundle(bundle) ||
    slot<0 || slot>1 || !isfinite(now))return NO;
 NSDictionary *v=@{@"Version":@1,@"Session":session,@"BundleID":bundle,
                   @"Slot":@(slot),@"Timestamp":@(now)};
 return [v writeToFile:path atomically:YES] &&
       DFNativeMapFreshLeaseAtPath(path,session,now)!=nil;
}
NS_INLINE BOOL DFNativeMapWriteLease(NSString *session,NSString *bundle,NSInteger slot) {
 return DFNativeMapWriteLeaseAtPath(DFNativeMapLeasePath,session,bundle,slot,
                                  NSDate.date.timeIntervalSince1970);
}
NS_INLINE NSDictionary *DFNativeMapRememberedChoiceAtPath(NSString *path) {
 if(![path isKindOfClass:NSString.class]||!path.length)return nil;
 NSDictionary *v=[NSDictionary dictionaryWithContentsOfFile:path];
 if(![v isKindOfClass:NSDictionary.class] || ![v[@"Version"] isEqual:@1] ||
    ![v[@"Slot"] isKindOfClass:NSNumber.class] ||
    ([v[@"Slot"] integerValue]!=0&&[v[@"Slot"] integerValue]!=1))return nil;
 return v;
}
NS_INLINE NSDictionary *DFNativeMapRememberedChoice(void) {
 return DFNativeMapRememberedChoiceAtPath(DFNativeMapChoicePath);
}
NS_INLINE BOOL DFNativeMapSaveChoiceAtPath(NSString *path,NSInteger slot) {
 if(![path isKindOfClass:NSString.class]||!path.length||slot<0||slot>1)return NO;
 NSDictionary *v=@{@"Version":@1,@"Slot":@(slot)};
 return [v writeToFile:path atomically:YES] &&
       [DFNativeMapRememberedChoiceAtPath(path)[@"Slot"] integerValue]==slot;
}
NS_INLINE BOOL DFNativeMapSaveChoice(NSInteger slot) {
 return DFNativeMapSaveChoiceAtPath(DFNativeMapChoicePath,slot);
}
NS_INLINE void DFNativeMapForgetChoice(void) {
 (void)[NSFileManager.defaultManager removeItemAtPath:DFNativeMapChoicePath error:nil];
}
#endif
