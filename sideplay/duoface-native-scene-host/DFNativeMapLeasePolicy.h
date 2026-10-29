// Independent DuoFace native-CarPlay controller lease and opt-in restore intent.
// Cross-process values contain NO executable pointers, PIDs, or vendor state.
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
NS_INLINE NSDictionary *DFNativeMapFreshLease(NSString *session,NSTimeInterval now) {
 if(![session isKindOfClass:NSString.class] ||
    ![[NSUUID alloc]initWithUUIDString:session] || !isfinite(now))return nil;
 NSDictionary *v=[NSDictionary dictionaryWithContentsOfFile:DFNativeMapLeasePath];
 if(![v isKindOfClass:NSDictionary.class] || ![v[@"Version"] isEqual:@1] ||
    ![v[@"Session"] isEqual:session] || !DFNativeMapAllowedBundle(v[@"BundleID"]) ||
    ![v[@"Slot"] isKindOfClass:NSNumber.class] ||
    [v[@"Slot"] integerValue]<0 || [v[@"Slot"] integerValue]>1 ||
    ![v[@"Timestamp"] isKindOfClass:NSNumber.class])return nil;
 double age=now-[v[@"Timestamp"] doubleValue];
 return isfinite(age)&&age>=0&&age<=5.0?v:nil;
}
NS_INLINE BOOL DFNativeMapWriteLease(NSString *session,NSString *bundle,NSInteger slot) {
 if(![[NSUUID alloc]initWithUUIDString:session] ||
    !DFNativeMapAllowedBundle(bundle) || slot<0 || slot>1)return NO;
 NSDictionary *v=@{@"Version":@1,@"Session":session,@"BundleID":bundle,
                   @"Slot":@(slot),@"Timestamp":@(NSDate.date.timeIntervalSince1970)};
 return [v writeToFile:DFNativeMapLeasePath atomically:YES] &&
       DFNativeMapFreshLease(session,NSDate.date.timeIntervalSince1970)!=nil;
}
NS_INLINE NSDictionary *DFNativeMapRememberedChoice(void) {
 NSDictionary *v=[NSDictionary dictionaryWithContentsOfFile:DFNativeMapChoicePath];
 if(![v isKindOfClass:NSDictionary.class] || ![v[@"Version"] isEqual:@1] ||
    ![v[@"Slot"] isKindOfClass:NSNumber.class] ||
    ([v[@"Slot"] integerValue]!=0&&[v[@"Slot"] integerValue]!=1))return nil;
 return v;
}
NS_INLINE BOOL DFNativeMapSaveChoice(NSInteger slot) {
 if(slot<0||slot>1)return NO;
 NSDictionary *v=@{@"Version":@1,@"Slot":@(slot)};
 return [v writeToFile:DFNativeMapChoicePath atomically:YES] &&
        [DFNativeMapRememberedChoice()[@"Slot"] integerValue]==slot;
}
NS_INLINE void DFNativeMapForgetChoice(void) {
 (void)[NSFileManager.defaultManager removeItemAtPath:DFNativeMapChoicePath error:nil];
}
#endif
