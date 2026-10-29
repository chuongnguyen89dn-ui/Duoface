// DuoFace first-party preferences for choosing apps, NOT fixed left/right or slot assignment.
// Stored entirely on device. A default is only ranked first in the picker; never auto-launch.
#ifndef DF_APP_HABITS_H
#define DF_APP_HABITS_H
#import <Foundation/Foundation.h>
#import <notify.h>
#import "DFAppEligibility.h"
static NSString *const DFAppChoicesPath =
 @"/var/mobile/Library/Preferences/com.duoface.nativehost.app-choices.v1.plist";
static NSString *const DFAppHabitCountsPath =
 @"/var/mobile/Library/Preferences/com.duoface.nativehost.app-usage.v1.plist";
static const char *const DFAppChoicesChangedNotification =
 "com.duoface.nativehost.app-choices.changed.v1";
NS_INLINE NSDictionary *DFEmptyAppChoices(void) {
 return @{@"DefaultBundleID":@"",@"PinnedBundleIDs":@[]};
}
NS_INLINE NSDictionary *DFReadAppChoicesAtPath(NSString *path) {
 NSDictionary *record=[NSDictionary dictionaryWithContentsOfFile:path];
 if(![record isKindOfClass:NSDictionary.class] ||
    ![record[@"Version"] isEqual:@1] ||
    ![record[@"DefaultBundleID"] isKindOfClass:NSString.class] ||
    ![record[@"PinnedBundleIDs"] isKindOfClass:NSArray.class])
    return DFEmptyAppChoices();
 NSString *preferred=record[@"DefaultBundleID"];
 if(preferred.length && !DFIsEligibleAppID(preferred))return DFEmptyAppChoices();
 NSMutableOrderedSet *pinned=[NSMutableOrderedSet new];
 for(id bid in record[@"PinnedBundleIDs"]) {
   if(!DFIsEligibleAppID(bid))return DFEmptyAppChoices();
   [pinned addObject:bid];
 }
 return @{@"DefaultBundleID":preferred,@"PinnedBundleIDs":pinned.array};
}
NS_INLINE NSDictionary *DFCurrentAppChoices(void) {
 return DFReadAppChoicesAtPath(DFAppChoicesPath);
}
NS_INLINE BOOL DFWriteAppChoicesAtPath(NSString *preferred,NSArray *pinned,NSString *path) {
 if(![path isKindOfClass:NSString.class] || !path.length ||
    ![preferred isKindOfClass:NSString.class] ||
    ![pinned isKindOfClass:NSArray.class] ||
    (preferred.length && !DFIsEligibleAppID(preferred)))return NO;
 NSMutableOrderedSet *unique=[NSMutableOrderedSet new];
 for(id bid in pinned){
   if(!DFIsEligibleAppID(bid))return NO;
   [unique addObject:bid];
 }
 NSDictionary *record=@{@"Version":@1,@"DefaultBundleID":preferred,
                         @"PinnedBundleIDs":unique.array};
 if(![record writeToFile:path atomically:YES])return NO;
 NSDictionary *check=DFReadAppChoicesAtPath(path);
 return [check[@"DefaultBundleID"] isEqualToString:preferred] &&
        [check[@"PinnedBundleIDs"] isEqualToArray:unique.array];
}
NS_INLINE BOOL DFSaveAppChoices(NSString *preferred,NSArray *pinned) {
 if(!DFWriteAppChoicesAtPath(preferred,pinned,DFAppChoicesPath))return NO;
 notify_post(DFAppChoicesChangedNotification);
 return YES;
}
NS_INLINE NSDictionary<NSString *,NSNumber *> *DFReadAppHabitCountsAtPath(NSString *path) {
 NSDictionary *data=[NSDictionary dictionaryWithContentsOfFile:path];
 if(![data isKindOfClass:NSDictionary.class] || ![data[@"Version"] isEqual:@1] ||
    ![data[@"SelectionCounts"] isKindOfClass:NSDictionary.class])return @{};
 NSMutableDictionary *valid=[NSMutableDictionary new];
 for(id key in data[@"SelectionCounts"]) {
   id count=data[@"SelectionCounts"][key];
   if(!DFIsEligibleAppID(key) || ![count isKindOfClass:NSNumber.class] ||
       [count integerValue]<0 || [count integerValue]>999999)continue;
   valid[key]=count;
 }
 return valid;
}
NS_INLINE BOOL DFRecordReadyAppHabitAtPath(NSString *bundleID,NSString *path) {
 if(!DFIsEligibleAppID(bundleID) || ![path isKindOfClass:NSString.class] ||
    !path.length)return NO;
 NSMutableDictionary *counts=[DFReadAppHabitCountsAtPath(path) mutableCopy];
 NSInteger before=[counts[bundleID] integerValue];
 counts[bundleID]=@(MIN(999999,before+1));
 NSDictionary *record=@{@"Version":@1,@"SelectionCounts":counts};
 if(![record writeToFile:path atomically:YES])return NO;
 return [DFReadAppHabitCountsAtPath(path)[bundleID] isEqual:counts[bundleID]];
}
NS_INLINE BOOL DFRecordReadyAppHabit(NSString *bundleID) {
 if(!DFRecordReadyAppHabitAtPath(bundleID,DFAppHabitCountsPath))return NO;
 notify_post(DFAppChoicesChangedNotification);
 return YES;
}
// Rank ONLY real installed, already allowlisted app IDs; never add an app.
NS_INLINE NSArray<NSString *> *DFRankAppIDsByHabits(NSArray<NSString *> *installed,
                    NSDictionary *choices,NSDictionary *counts) {
 NSString *preferred=choices[@"DefaultBundleID"]?:@"";
 NSArray *pinned=choices[@"PinnedBundleIDs"]?:@[];
 return [installed sortedArrayUsingComparator:^NSComparisonResult(NSString *a,NSString *b){
   BOOL ad=[a isEqualToString:preferred],bd=[b isEqualToString:preferred];
   if(ad!=bd)return ad?NSOrderedAscending:NSOrderedDescending;
   NSUInteger ai=[pinned indexOfObject:a],bi=[pinned indexOfObject:b];
   if((ai==NSNotFound)!=(bi==NSNotFound))
      return ai==NSNotFound?NSOrderedDescending:NSOrderedAscending;
   if(ai!=NSNotFound && bi!=NSNotFound && ai!=bi)
      return ai<bi?NSOrderedAscending:NSOrderedDescending;
   NSInteger ac=[counts[a] integerValue],bc=[counts[b] integerValue];
   if(ac!=bc)return ac>bc?NSOrderedAscending:NSOrderedDescending;
   NSUInteger ax=[installed indexOfObject:a],bx=[installed indexOfObject:b];
   return ax<bx?NSOrderedAscending:(ax>bx?NSOrderedDescending:NSOrderedSame);
 }];
}
#endif
