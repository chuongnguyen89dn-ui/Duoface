// First-party independent DuoFace phone-to-CarPlay app allowlist.
#ifndef DF_ENABLED_APPS_POLICY_H
#define DF_ENABLED_APPS_POLICY_H
#import <Foundation/Foundation.h>
#import <notify.h>
#import "DFAppEligibility.h"
static NSString *const DFEnabledAppsPath =
 @"/var/mobile/Library/Preferences/com.duoface.nativehost.enabled-apps.v1.plist";
static const char *const DFEnabledAppsChangedNotification =
 "com.duoface.nativehost.enabled-apps.changed.v1";
// Absent preference: preserve .92 old all-eligible list. Explicit [] = none.
// Invalid existing file: fail-closed rather than silently enable all.
NS_INLINE NSArray<NSString *> *DFReadEnabledAppIDsAtPath(NSString *path) {
 if(![path isKindOfClass:NSString.class] || !path.length)return @[];
 if(![[NSFileManager defaultManager] fileExistsAtPath:path])return nil;
 NSDictionary *record=[NSDictionary dictionaryWithContentsOfFile:path];
 if(![record isKindOfClass:NSDictionary.class] ||
    ![record[@"Version"] isEqual:@1] ||
    ![record[@"EnabledBundleIDs"] isKindOfClass:NSArray.class])return @[];
 NSMutableOrderedSet<NSString *> *ids=[NSMutableOrderedSet new];
 for(id value in (NSArray *)record[@"EnabledBundleIDs"])
   if(DFIsEligibleAppID(value))[ids addObject:value];
 return ids.array;
}
NS_INLINE NSArray<NSString *> *DFConfiguredEnabledAppIDs(void) {
 return DFReadEnabledAppIDsAtPath(DFEnabledAppsPath);
}
NS_INLINE BOOL DFWriteEnabledAppIDsAtPath(NSArray<NSString *> *bundleIDs,
                                          NSString *path) {
 if(![bundleIDs isKindOfClass:NSArray.class] ||
    ![path isKindOfClass:NSString.class] || !path.length)return NO;
 NSMutableOrderedSet<NSString *> *ids=[NSMutableOrderedSet new];
 for(id value in bundleIDs)if(DFIsEligibleAppID(value))[ids addObject:value];
 NSDictionary *record=@{@"Version":@1,@"EnabledBundleIDs":ids.array};
 if(![record writeToFile:path atomically:YES])return NO;
 NSArray<NSString *> *readback=DFReadEnabledAppIDsAtPath(path);
 return readback && [readback isEqualToArray:ids.array];
}
NS_INLINE BOOL DFWriteEnabledAppIDs(NSArray<NSString *> *bundleIDs) {
 if(!DFWriteEnabledAppIDsAtPath(bundleIDs,DFEnabledAppsPath))return NO;
 notify_post(DFEnabledAppsChangedNotification);
 return YES;
}
NS_INLINE BOOL DFPickerAllowsApp(NSString *bundleID,
                                  NSArray<NSString *> *enabled) {
 return DFIsEligibleAppID(bundleID) &&
        (!enabled || [enabled containsObject:bundleID]);
}
// Original Enable Recommended invokes enableAllUserApps. Independently
// interpret as user-installed non-Apple apps; no vendor scoring is copied.
NS_INLINE BOOL DFIsRecommendedAppID(NSString *bundleID) {
 return DFIsEligibleAppID(bundleID) && ![bundleID hasPrefix:@"com.apple."];
}
#endif
