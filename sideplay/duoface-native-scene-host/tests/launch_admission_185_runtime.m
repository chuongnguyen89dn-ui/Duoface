#import <Foundation/Foundation.h>
#import "../DF185LaunchAdmission.h"
#include <assert.h>
#include <stdio.h>
int main(void) {@autoreleasepool {
 NSDictionary *launch=@{@"Version":@2,@"Session":@"00000000-0000-4000-8000-000000000001",
  @"AssignmentID":@"00000000-0000-4000-8000-000000000002",
  @"HostSceneID":@"CarPlay-host",@"BundleID":@"com.google.Maps",
  @"PhysicalSlot":@1,@"Slot":@0,@"LaunchPaneFrame":@"{{0,0},{200,360}}"};
 assert(DF185LaunchIdentityMatches(launch,launch,@"com.google.Maps"));
 assert(!DF185LaunchIdentityMatches(launch,nil,@"com.google.Maps"));
 assert(!DF185LaunchIdentityMatches(nil,launch,@"com.google.Maps"));
 assert(!DF185LaunchIdentityMatches(launch,launch,@"com.waze.iphone"));
 NSDictionary *bad=@{@"Version":@1,@"Session":@"00000000-0000-4000-8000-000000000003",
  @"AssignmentID":@"00000000-0000-4000-8000-000000000004",
  @"HostSceneID":@"other-host",@"BundleID":@"com.waze.iphone",
  @"PhysicalSlot":@0,@"Slot":@1};
 unsigned cases=4;
 for(NSString *key in bad) {
  NSMutableDictionary *current=[launch mutableCopy];current[key]=bad[key];
  assert(!DF185LaunchIdentityMatches(launch,current,@"com.google.Maps"));cases++;
  [current removeObjectForKey:key];
  assert(!DF185LaunchIdentityMatches(launch,current,@"com.google.Maps"));cases++;
 }
 for(NSString *key in @[@"Session",@"AssignmentID",@"HostSceneID",@"PhysicalSlot",@"Slot"]) {
  NSMutableDictionary *invalid=[launch mutableCopy];invalid[key]=@"unknown";
  assert(!DF185LaunchIdentityMatches(invalid,invalid,@"com.google.Maps"));cases++;
 }
 assert(!DF185PostAdmissionVisible(YES,1));
 assert(!DF185PostAdmissionVisible(NO,0));
 assert(!DF185PostAdmissionVisible(NO,NAN));
 assert(DF185PostAdmissionVisible(NO,1));cases+=4;
 // Existing watchdog/Home criteria are intentionally unchanged.
 NSDictionary *pulse=@{@"Version":@1,@"Session":launch[@"Session"],@"HostSceneID":@"CarPlay-host",
  @"Active":@YES,@"HostBackground":@YES,@"Timestamp":@100};
 NSDictionary *home=@{@"Version":@1,@"Session":launch[@"Session"],@"HostSceneID":@"CarPlay-host",
  @"Process":@"CarPlay",@"HomeHookReady":@YES,@"Timestamp":@100};
 NSDictionary *member=@{@"Version":@1,@"Process":@"CarPlay",@"Session":launch[@"Session"],
  @"HostSceneID":@"CarPlay-host",@"AssignmentID":launch[@"AssignmentID"],@"PhysicalSlot":@1,
  @"BundleID":@"com.google.Maps",@"ControllerClass":@"DBApplicationSceneViewController",
  @"SceneClass":@"FBScene",@"NativeSceneID":@"MapsScene",
  @"PresentationSource":@"DBDashboardRootViewController.presentBase:post-original",
  @"WindowRole":@"UIWindowSceneSessionRoleCarPlay",@"WindowExternal":@YES,
  @"WindowVisible":@YES,@"SceneHostAttached":@YES,@"PaneBound":@NO,@"PaneFrameVerified":@NO,
  @"Stage":@"PRESENTED",@"PresentedAt":@100,@"Timestamp":@100};
 assert(DF184MapMembershipAccepted(pulse,home,member,launch,nil,100));
 NSDictionary *revoke=@{@"Version":@1,@"Session":launch[@"Session"],@"Revoked":@YES};
 assert(!DF184MapMembershipAccepted(pulse,home,member,launch,revoke,100));
 assert(!DF184MapMembershipAccepted(pulse,home,member,launch,nil,100.851));
 NSMutableDictionary *wrongPulse=[pulse mutableCopy];wrongPulse[@"Session"]=bad[@"Session"];
 assert(!DF184MapMembershipAccepted(wrongPulse,home,member,launch,nil,100));cases+=4;
 printf("QA185_LAUNCH_IDENTITY_AND_UNCHANGED_HOME_%u_CASES_PASS\n",cases);
 return 0;
}}
