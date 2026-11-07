// QA185: launch identity is authoritative for PRESENTED admission.
// No physical-pane Preferences snapshot or UIKit visibility participates here.
#ifndef DF185_LAUNCH_ADMISSION_H
#define DF185_LAUNCH_ADMISSION_H
#import <Foundation/Foundation.h>
#import "DF184NativeMapMembership.h"
static inline BOOL DF185LaunchIdentityMatches(NSDictionary *launch,
 NSDictionary *current,NSString *nativeBundle) {
 if(![launch[@"Version"] isEqual:@2] ||
    !DF184UUID(launch[@"Session"]) || !DF184UUID(launch[@"AssignmentID"]) ||
    ![launch[@"BundleID"] isEqual:@"com.google.Maps"] ||
    ![nativeBundle isEqual:launch[@"BundleID"]] ||
    ![launch[@"HostSceneID"] isKindOfClass:NSString.class] ||
    [launch[@"HostSceneID"] length]==0 ||
    [launch[@"HostSceneID"] isEqual:@"unknown"])return NO;
 for(NSString *slot in @[@"PhysicalSlot",@"Slot"]) {
  id value=launch[slot];
  if(![value isKindOfClass:NSNumber.class] ||
     !([value isEqual:@0]||[value isEqual:@1]))return NO;
 }
 // Atomic assignment is still the cancellation/replacement authority.
 // Exact keys prevent an earlier launch or wrong physical slot being admitted.
 for(NSString *key in @[@"Version",@"Session",@"AssignmentID",@"HostSceneID",
                         @"BundleID",@"PhysicalSlot",@"Slot"])
  if(![launch[key] isEqual:current[key]])return NO;
 return YES;
}
static inline BOOL DF185PostAdmissionVisible(BOOL hidden,double alpha) {
 return !hidden && isfinite(alpha) && alpha>=0.95;
}
#endif
