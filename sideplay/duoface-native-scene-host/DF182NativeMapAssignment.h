// QA182 B1: one native Maps assignment. State, not an enable switch.
#ifndef DF182_NATIVE_MAP_ASSIGNMENT_H
#define DF182_NATIVE_MAP_ASSIGNMENT_H
#import <Foundation/Foundation.h>
#import <notify.h>
#import <math.h>
#import <dlfcn.h>
#import "DFDeepTrace.h"
#import "DFNativeMapLeasePolicy.h"
static NSString *const DF182ResultPath=@"/var/mobile/Library/Preferences/com.duoface.nativehost.native-map182.result.plist";
static const char *const DF182Changed="com.duoface.nativehost.native-map182.assignment";
static inline BOOL DF182UUID(id s) {
 return [s isKindOfClass:NSString.class] && [[NSUUID alloc] initWithUUIDString:s]!=nil;
}
static inline NSDictionary *DF182Pulse(void) {
 return [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist"];
}
static inline NSDictionary *DF182AssignmentFromRecords(NSDictionary *a,NSDictionary *p,NSTimeInterval now) {
 if(![a[@"Version"] isEqual:@2] || !DF182UUID(a[@"AssignmentID"]) ||
    !DF182UUID(a[@"Session"]) || ![a[@"Session"] isEqual:p[@"Session"]] ||
    ![p[@"Active"] isEqual:@YES] || ![p[@"Timestamp"] isKindOfClass:NSNumber.class] ||
    ![a[@"AssignedAt"] isKindOfClass:NSNumber.class] ||
    ![a[@"BundleID"] isEqual:@"com.google.Maps"] ||
    ![a[@"Slot"] isKindOfClass:NSNumber.class] || [a[@"Slot"] integerValue]<0 || [a[@"Slot"] integerValue]>1 ||
    ![a[@"PhysicalSlot"] isKindOfClass:NSNumber.class] ||
    [a[@"PhysicalSlot"] integerValue]<0 || [a[@"PhysicalSlot"] integerValue]>1)return nil;
 double age=now-[p[@"Timestamp"] doubleValue],assigned=now-[a[@"AssignedAt"] doubleValue];
 if(!isfinite(age)||age<0||age>2.5||!isfinite(assigned)||assigned<0)return nil;
 return a;
}
static inline NSDictionary *DF182AssignmentAtPaths(NSString *choicePath,NSString *pulsePath,NSTimeInterval now) {
 NSDictionary *a=[NSDictionary dictionaryWithContentsOfFile:choicePath];
 NSDictionary *p=[NSDictionary dictionaryWithContentsOfFile:pulsePath];
 return DF182AssignmentFromRecords(a,p,now);
}
static inline NSDictionary *DF182Assignment(void) {
 return DF182AssignmentAtPaths(DFNativeMapChoicePath,
  @"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist",
  NSDate.date.timeIntervalSince1970);
}
static inline NSString *DF182String(id value) {
 return [value isKindOfClass:NSString.class] && [value length]?value:@"unknown";
}
static inline void DF182Log(NSString *event,NSDictionary *a,NSString *detail) {
 DFDeepTrace(@"qa182-b1",[NSString stringWithFormat:
  @"qa182-b1 event=b1-%@ assignment=%@ session=%@ bundle=%@ physical=%@ stock-settings=unknown %@",
  event,DF182String(a[@"AssignmentID"]),DF182String(a[@"Session"]),
  DF182String(a[@"BundleID"]),a[@"PhysicalSlot"]?:@"unknown",detail?:@"evidence=UNVERIFIED"]);
}
static inline NSDictionary *DF182Assign(NSInteger physical,NSInteger visual) {
 NSDictionary *p=DF182Pulse();
 if(physical<0||physical>1||visual<0||visual>1||!DF182UUID(p[@"Session"])||
    ![p[@"Active"] isEqual:@YES])return nil;
 NSDictionary *a=@{@"Version":@2,@"AssignmentID":NSUUID.UUID.UUIDString,
  @"Session":p[@"Session"],@"BundleID":@"com.google.Maps",@"PhysicalSlot":@(physical),
  @"Slot":@(visual),@"AssignedAt":@(NSDate.date.timeIntervalSince1970)};
 if(![a writeToFile:DFNativeMapChoicePath atomically:YES] ||
    ![DF182Assignment()[@"AssignmentID"] isEqual:a[@"AssignmentID"]])return nil;
 DF182Log(@"assignment-created",a,@"phone-fallback=forbidden");
 notify_post(DF182Changed);
 return a;
}
static inline void DF182Revoke(NSString *reason) {
 NSDictionary *a=[NSDictionary dictionaryWithContentsOfFile:DFNativeMapChoicePath];
 if(![a[@"Version"] isEqual:@2])return; // Never reinterpret legacy Version1/Slot.
 if([NSFileManager.defaultManager removeItemAtPath:DFNativeMapChoicePath error:nil]) {
  DF182Log(@"assignment-revoked",a,[NSString stringWithFormat:@"reason=%@",reason]);
  typedef void(*Restore)(NSString *,NSString *);
  Restore restore=(Restore)dlsym(RTLD_DEFAULT,"DF182RestoreAssignmentNow");
  if(restore && NSThread.isMainThread)restore(a[@"AssignmentID"],reason);
  notify_post(DF182Changed);
 }
}
// Called only by the already-installed factory hook in the Dock module.
extern void DF182CaptureLibrary(id library);
extern id DF182ReconcileNativeMaps(id library,NSString **reason);
extern id DF182CapturedDashboardWorkspace(void);
extern id DF182ExistingApplicationLibrary(void);
#endif
