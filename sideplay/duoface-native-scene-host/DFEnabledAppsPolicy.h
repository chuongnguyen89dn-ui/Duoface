// Independent DuoFace app permission setting (no vendor runtime or licensing).
// Original Native12: phone Apps Manager controls catalog; CarPlay picker
// still picks a SINGLE bundle for a SINGLE slot. Missing config retains
// previous eligible list, explicit empty config means no apps enabled.
#ifndef DF_ENABLED_APPS_POLICY_H
#define DF_ENABLED_APPS_POLICY_H
#import <Foundation/Foundation.h>
#import "DFAppEligibility.h"
static NSString *const DFEnabledAppsPath=
 @"/var/mobile/Library/Preferences/com.duoface.nativehost.enabled-apps.v1.plist";
NS_INLINE NSArray<NSString *> *DFConfiguredEnabledAppIDs(void) {
 NSDictionary *record=[NSDictionary dictionaryWithContentsOfFile:DFEnabledAppsPath];
 if(![record isKindOfClass:NSDictionary.class] ||
    ![record[@"Version"] isEqual:@1] ||
    ![record[@"EnabledBundleIDs"] isKindOfClass:NSArray.class])return nil;
 NSMutableOrderedSet<NSString *> *valid=[NSMutableOrderedSet new];
 for(id value in (NSArray *)record[@"EnabledBundleIDs"])
     if(DFIsEligibleAppID(value))[valid addObject:value];
 return valid.array;
}
NS_INLINE BOOL DFWriteEnabledAppIDs(NSArray<NSString *> *bundleIDs) {
 if(![bundleIDs isKindOfClass:NSArray.class])return NO;
 NSMutableOrderedSet<NSString *> *valid=[NSMutableOrderedSet new];
 for(id value in bundleIDs)
     if(DFIsEligibleAppID(value))[valid addObject:value];
 NSDictionary *record=@{@"Version":@1,@"EnabledBundleIDs":valid.array};
 return [record writeToFile:DFEnabledAppsPath atomically:YES];
}
NS_INLINE BOOL DFPickerAllowsApp(NSString *bundleID,
                                 NSArray<NSString *> *enabled) {
 return DFIsEligibleAppID(bundleID) &&
        (!enabled || [enabled containsObject:bundleID]);
}
#endif
