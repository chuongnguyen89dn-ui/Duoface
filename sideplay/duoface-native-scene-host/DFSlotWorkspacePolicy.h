// DuoFace independent workspace: physical-host preference + visual arrangement.
// Scene surfaces/handles and processes are NEVER serialized; only approved bundle IDs.
#ifndef DF_SLOT_WORKSPACE_POLICY_H
#define DF_SLOT_WORKSPACE_POLICY_H
#import <Foundation/Foundation.h>
#import "DFEnabledAppsPolicy.h"
static NSString *const DFWorkspacePrefsPath =
 @"/var/mobile/Library/Preferences/com.duoface.nativehost.workspace.v1.plist";
NS_INLINE NSArray<NSString *> *DFEmptyPhysicalBundles(void) {
 return @[@"",@"",@"",@""];
}
NS_INLINE NSArray<NSNumber *> *DFIdentityOrder(NSInteger n) {
 NSMutableArray *array=[NSMutableArray new];
 for(NSInteger i=0;i<n;i++)[array addObject:@(i)];
 return array;
}
NS_INLINE BOOL DFOrderIsPermutation(NSArray *order,NSInteger count) {
 if(![order isKindOfClass:NSArray.class] || order.count!=(NSUInteger)count)return NO;
 NSMutableSet *seen=[NSMutableSet new];
 for(id v in order) {
   if(![v isKindOfClass:NSNumber.class] ||
      [v integerValue]<0 || [v integerValue]>=count ||
      [seen containsObject:v])return NO;
   [seen addObject:v];
 }
 return YES;
}
NS_INLINE BOOL DFPhysicalBundlesAreValid(NSArray *arr) {
 if(![arr isKindOfClass:NSArray.class] || arr.count!=4)return NO;
 NSMutableSet *seen=[NSMutableSet new];
 for(id bid in arr) {
   if(![bid isKindOfClass:NSString.class])return NO;
   if([bid length] && (!DFIsEligibleAppID(bid)||[seen containsObject:bid]))return NO;
   if([bid length])[seen addObject:bid];
 }
 return YES;
}
NS_INLINE NSDictionary *DFDefaultWorkspace(void) {
 return @{@"Version":@1,@"PhysicalBundles":DFEmptyPhysicalBundles(),
          @"Order3":DFIdentityOrder(3),@"Order4":DFIdentityOrder(4),
          @"RestoreOnReconnect":@YES};
}
NS_INLINE NSDictionary *DFReadWorkspaceAtPath(NSString *path) {
 NSDictionary *p=[NSDictionary dictionaryWithContentsOfFile:path];
 if(![p isKindOfClass:NSDictionary.class] || ![p[@"Version"] isEqual:@1] ||
    !DFPhysicalBundlesAreValid(p[@"PhysicalBundles"]) ||
    !DFOrderIsPermutation(p[@"Order3"],3) ||
    !DFOrderIsPermutation(p[@"Order4"],4) ||
    ![p[@"RestoreOnReconnect"] isKindOfClass:NSNumber.class])
    return DFDefaultWorkspace();
 return p;
}
NS_INLINE BOOL DFWriteWorkspaceAtPath(NSDictionary *p,NSString *path) {
 if(![path isKindOfClass:NSString.class] || !path.length ||
    ![p isKindOfClass:NSDictionary.class] || ![p[@"Version"] isEqual:@1] ||
    !DFPhysicalBundlesAreValid(p[@"PhysicalBundles"]) ||
    !DFOrderIsPermutation(p[@"Order3"],3) || !DFOrderIsPermutation(p[@"Order4"],4) ||
    ![p[@"RestoreOnReconnect"] isKindOfClass:NSNumber.class])return NO;
 if(![p writeToFile:path atomically:YES])return NO;
 NSDictionary *readback=DFReadWorkspaceAtPath(path);
 return [readback[@"PhysicalBundles"] isEqualToArray:p[@"PhysicalBundles"]] &&
        [readback[@"Order3"] isEqualToArray:p[@"Order3"]] &&
        [readback[@"Order4"] isEqualToArray:p[@"Order4"]] &&
        [readback[@"RestoreOnReconnect"] isEqual:p[@"RestoreOnReconnect"]];
}
NS_INLINE NSDictionary *DFCurrentWorkspace(void) {
 return DFReadWorkspaceAtPath(DFWorkspacePrefsPath);
}
NS_INLINE BOOL DFWriteWorkspace(NSDictionary *record) {
 return DFWriteWorkspaceAtPath(record,DFWorkspacePrefsPath);
}
NS_INLINE BOOL DFSavePhysicalBundleAtPath(NSInteger slot,NSString *bundle,NSString *path) {
 if(slot<0||slot>=4||![bundle isKindOfClass:NSString.class] ||
    (bundle.length && !DFIsEligibleAppID(bundle)))return NO;
 NSDictionary *p=DFReadWorkspaceAtPath(path);
 NSMutableArray *arr=[p[@"PhysicalBundles"] mutableCopy];
 if(bundle.length)
   for(NSInteger i=0;i<4;i++)
     if(i!=slot && [arr[(NSUInteger)i] isEqualToString:bundle])return NO;
 arr[(NSUInteger)slot]=bundle;
 NSMutableDictionary *updated=[p mutableCopy];updated[@"PhysicalBundles"]=arr;
 return DFWriteWorkspaceAtPath(updated,path);
}
NS_INLINE BOOL DFSavePhysicalBundle(NSInteger slot,NSString *bundle) {
 return DFSavePhysicalBundleAtPath(slot,bundle,DFWorkspacePrefsPath);
}
NS_INLINE NSArray<NSNumber *> *DFOrderForCount(NSDictionary *record,NSInteger n) {
 return n==3?record[@"Order3"]:(n==4?record[@"Order4"]:DFIdentityOrder(MAX(1,MIN(2,n))));
}
// Physical scene window is NOT reparented. This maps its screen position only.
// The existing native12 swapped flag is applied BEFORE 3/4 position ordering.
NS_INLINE NSInteger DFVisualForPhysical(NSInteger physical,BOOL swapped,NSInteger count,
                                       NSDictionary *record) {
 if(physical<0||physical>=count)return -1;
 NSInteger base=swapped&&physical<2?1-physical:physical;
 NSArray *order=DFOrderForCount(record,count);
 return base<(NSInteger)order.count?[order[(NSUInteger)base] integerValue]:-1;
}
NS_INLINE NSInteger DFPhysicalForVisual(NSInteger visual,BOOL swapped,NSInteger count,
                                       NSDictionary *record) {
 if(visual<0||visual>=count)return -1;
 for(NSInteger i=0;i<count;i++)
  if(DFVisualForPhysical(i,swapped,count,record)==visual)return i;
 return -1;
}
NS_INLINE BOOL DFRotateWorkspaceAtPath(NSInteger n,BOOL clockwise,NSString *path) {
 if(n!=3 && n!=4)return NO;
 NSDictionary *p=DFReadWorkspaceAtPath(path);
 NSString *key=n==3?@"Order3":@"Order4";
 NSMutableArray *rotated=[NSMutableArray new];
 for(NSNumber *v in p[key]){
   NSInteger next=(v.integerValue+(clockwise?1:n-1))%n;
   [rotated addObject:@(next)];
 }
 NSMutableDictionary *updated=[p mutableCopy];updated[key]=rotated;
 return DFWriteWorkspaceAtPath(updated,path);
}
NS_INLINE BOOL DFRotateWorkspace(NSInteger count,BOOL clockwise) {
 return DFRotateWorkspaceAtPath(count,clockwise,DFWorkspacePrefsPath);
}
NS_INLINE BOOL DFSetRestoreOnReconnect(BOOL enabled) {
 NSMutableDictionary *p=[DFCurrentWorkspace() mutableCopy];
 p[@"RestoreOnReconnect"]=@(enabled);
 return DFWriteWorkspace(p);
}
// Do not restore apps disabled by phone, removed from inventory or already hosted.
NS_INLINE NSArray<NSString *> *DFRestorablePhysicalBundles(
 NSDictionary *workspace,NSArray<NSString *> *enabled,
 NSSet<NSString *> *installed,NSInteger count) {
 NSMutableArray *list=[NSMutableArray new];
 NSArray *saved=workspace[@"PhysicalBundles"];
 if(![workspace[@"RestoreOnReconnect"] boolValue] || !DFPhysicalBundlesAreValid(saved))
    return @[];
 for(NSInteger i=0;i<MIN(4,MAX(0,count));i++){
   NSString *bid=saved[(NSUInteger)i];
   if(bid.length && DFPickerAllowsApp(bid,enabled) && [installed containsObject:bid])
     [list addObject:bid];
   else [list addObject:@""];
 }
 return list;
}
#endif
