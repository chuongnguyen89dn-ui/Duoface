// First-party native-CarPlay owner lease: short-lived process identity proof.
// The current car display may be terminated only on user-enabled physical unplug
// and after SpringBoard validates the same live PID + phone foreground guard.
// Values never contain process pointers, handles, cookies, or vendor state.
#ifndef DF_NATIVE_MAP_LEASE_POLICY_H
#define DF_NATIVE_MAP_LEASE_POLICY_H
#import <Foundation/Foundation.h>
#import <math.h>
#include "DFNativeMapFreshness.h"
static NSString *const DFNativeMapLeasePath =
 @"/var/mobile/Library/Preferences/com.duoface.nativehost.native-map-lease.v1.plist";
static NSString *const DFNativeMapChoicePath =
 @"/var/mobile/Library/Preferences/com.duoface.nativehost.native-map-choice.v1.plist";
static NSString *const DFNativeMapCatalogPath =
 @"/var/mobile/Library/Preferences/com.duoface.nativehost.native-catalog.v1.plist";
static NSString *const DFNativeMapHeartbeatPath =
 @"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist";
NS_INLINE BOOL DFNativeMapAllowedBundle(id bundle) {
 // Only these map apps have the existing native scene/adapter contract.
 // Discovery of another declared CarPlay app does not authorize its adoption.
 return [bundle isKindOfClass:NSString.class] &&
   [@[@"com.google.Maps",@"com.apple.Maps",@"com.waze.iphone"] containsObject:bundle];
}
NS_INLINE BOOL DFNativeMapValidSlotValue(id slot) {
 if(![slot isKindOfClass:NSNumber.class])return NO;
 double n=[slot doubleValue];
 return isfinite(n) && (n==0.0 || n==1.0);
}
NS_INLINE NSArray<NSString *> *DFNativeMapCatalogBundlesAtPath(NSString *path) {
 if(![path isKindOfClass:NSString.class] || !path.length)return nil;
 NSDictionary *v=[NSDictionary dictionaryWithContentsOfFile:path];
 if(![v isKindOfClass:NSDictionary.class] || ![v[@"Version"] isEqual:@1] ||
    ![v[@"Bundles"] isKindOfClass:NSArray.class])return nil;
 NSMutableOrderedSet<NSString *> *bundles=[NSMutableOrderedSet orderedSet];
 for(id bundle in v[@"Bundles"]) {
   if(![bundle isKindOfClass:NSString.class] || ![bundle length] ||
      [bundle length]>255)return nil;
   [bundles addObject:bundle];
 }
 return bundles.array;
}
NS_INLINE NSArray<NSString *> *DFNativeMapCatalogBundles(void) {
 return DFNativeMapCatalogBundlesAtPath(DFNativeMapCatalogPath);
}
NS_INLINE NSDictionary *DFNativeMapFreshLeaseAtPath(NSString *path,
   NSString *session,NSTimeInterval now) {
 if(![path isKindOfClass:NSString.class] || !path.length ||
    ![session isKindOfClass:NSString.class] ||
    ![[NSUUID alloc]initWithUUIDString:session] || !isfinite(now))return nil;
 NSDictionary *v=[NSDictionary dictionaryWithContentsOfFile:path];
 if(![v isKindOfClass:NSDictionary.class] || ![v[@"Version"] isEqual:@1] ||
    ![v[@"Session"] isEqual:session] || !DFNativeMapAllowedBundle(v[@"BundleID"]) ||
    !DFNativeMapValidSlotValue(v[@"Slot"]) ||
    ![v[@"Timestamp"] isKindOfClass:NSNumber.class])return nil;
 return DFNativeMapSampleFresh(now,[v[@"Timestamp"] doubleValue],5.0)?v:nil;
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
NS_INLINE BOOL DFNativeMapOwnsBundleAtPaths(NSString *leasePath,
   NSString *heartbeatPath,NSString *bundle,NSTimeInterval now) {
 if(!DFNativeMapAllowedBundle(bundle) || !isfinite(now) ||
    ![heartbeatPath isKindOfClass:NSString.class] || !heartbeatPath.length)return NO;
 NSDictionary *pulse=[NSDictionary dictionaryWithContentsOfFile:heartbeatPath];
 if(![pulse isKindOfClass:NSDictionary.class] || ![pulse[@"Version"] isEqual:@1] ||
    ![pulse[@"Active"] isEqual:@YES] ||
    ![pulse[@"Timestamp"] isKindOfClass:NSNumber.class] ||
    !DFNativeMapSampleFresh(now,[pulse[@"Timestamp"] doubleValue],2.5))return NO;
 NSDictionary *lease=DFNativeMapFreshLeaseAtPath(leasePath,pulse[@"Session"],now);
 return [lease[@"BundleID"] isEqual:bundle] &&
        DFNativeMapSampleFresh(now,[lease[@"Timestamp"] doubleValue],2.0);
}
NS_INLINE BOOL DFNativeMapOwnsBundleNow(NSString *bundle) {
 // A remembered selection is not a live native owner. This guard expires
 // promptly when the exact CarPlay session or adopted owner stops reporting.
 return DFNativeMapOwnsBundleAtPaths(DFNativeMapLeasePath,
     DFNativeMapHeartbeatPath,bundle,NSDate.date.timeIntervalSince1970);
}
NS_INLINE void DFNativeMapClearLeaseAtPathForSession(NSString *path,NSString *session) {
 if(![path isKindOfClass:NSString.class] || !path.length ||
    ![session isKindOfClass:NSString.class] ||
    ![[NSUUID alloc]initWithUUIDString:session])return;
 NSDictionary *lease=[NSDictionary dictionaryWithContentsOfFile:path];
 if([lease[@"Session"] isEqual:session])
   (void)[NSFileManager.defaultManager removeItemAtPath:path error:nil];
}
NS_INLINE void DFNativeMapClearLeaseForSession(NSString *session) {
 DFNativeMapClearLeaseAtPathForSession(DFNativeMapLeasePath,session);
}
NS_INLINE NSDictionary *DFNativeMapRememberedChoiceAtPath(NSString *path) {
 if(![path isKindOfClass:NSString.class]||!path.length)return nil;
 NSDictionary *v=[NSDictionary dictionaryWithContentsOfFile:path];
 if(![v isKindOfClass:NSDictionary.class] || ![v[@"Version"] isEqual:@1] ||
    !DFNativeMapValidSlotValue(v[@"Slot"]) ||
    (v[@"BundleID"] && !DFNativeMapAllowedBundle(v[@"BundleID"])))return nil;
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
NS_INLINE BOOL DFNativeMapSaveChoiceForBundleAtPath(NSString *path,
   NSInteger slot,NSString *bundle) {
 if(![path isKindOfClass:NSString.class] || !path.length || slot<0 || slot>1 ||
    !DFNativeMapAllowedBundle(bundle))return NO;
 NSDictionary *v=@{@"Version":@1,@"Slot":@(slot),@"BundleID":bundle};
 if(![v writeToFile:path atomically:YES])return NO;
 NSDictionary *saved=DFNativeMapRememberedChoiceAtPath(path);
 return [saved[@"Slot"] integerValue]==slot && [saved[@"BundleID"] isEqual:bundle];
}
NS_INLINE BOOL DFNativeMapSaveChoiceForBundle(NSInteger slot,NSString *bundle) {
 return DFNativeMapSaveChoiceForBundleAtPath(DFNativeMapChoicePath,slot,bundle);
}
NS_INLINE NSString *DFNativeMapChoiceBundle(NSDictionary *choice) {
 id bundle=[choice isKindOfClass:NSDictionary.class]?choice[@"BundleID"]:nil;
 return DFNativeMapAllowedBundle(bundle)?bundle:nil;
}
NS_INLINE void DFNativeMapForgetChoice(void) {
 (void)[NSFileManager.defaultManager removeItemAtPath:DFNativeMapChoicePath error:nil];
}
#endif
