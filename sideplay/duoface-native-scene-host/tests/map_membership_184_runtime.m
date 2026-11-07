#import <Foundation/Foundation.h>
#import "../DF184NativeMapMembership.h"
#include <assert.h>
#include <stdio.h>
int main(void) {@autoreleasepool {
 NSString *sid=@"00000000-0000-4000-8000-000000000001";
 NSString *other=@"00000000-0000-4000-8000-000000000002";
 NSString *aid=@"00000000-0000-4000-8000-000000000003";
 NSDictionary *pulse=@{@"Version":@1,@"Session":sid,@"HostSceneID":@"host",
   @"Active":@YES,@"HostBackground":@YES,@"Timestamp":@100};
 NSDictionary *owner=@{@"Version":@1,@"Session":sid,@"HostSceneID":@"host",
   @"Process":@"CarPlay",@"HomeHookReady":@YES,@"Active":@NO,@"Timestamp":@100};
 NSDictionary *choice=@{@"Version":@2,@"Session":sid,@"AssignmentID":aid,
   @"BundleID":@"com.google.Maps",@"PhysicalSlot":@0,@"Slot":@0};
 NSDictionary *member=@{@"Version":@1,@"Process":@"CarPlay",
   @"Session":sid,@"HostSceneID":@"host",@"AssignmentID":aid,@"PhysicalSlot":@0,
   @"BundleID":@"com.google.Maps",@"ControllerClass":@"DBApplicationSceneViewController",
   @"SceneClass":@"FBScene",@"NativeSceneID":@"CarPlayScene",
   @"PresentationSource":@"DBDashboardRootViewController.presentBase:post-original",
   @"WindowRole":@"UIWindowSceneSessionRoleCarPlay",@"WindowExternal":@YES,
   @"WindowVisible":@YES,@"SceneHostAttached":@YES,@"PaneBound":@NO,
   @"PaneFrameVerified":@NO,@"HitRegionVerified":@NO,
   @"Stage":@"PRESENTED",@"PresentedAt":@100,@"Timestamp":@100};
 assert(DF184MapMembershipAccepted(pulse,owner,member,choice,nil,100));
 assert(!DF184MapMembershipAccepted(pulse,owner,member,choice,nil,100.851));
 NSMutableDictionary *commit=[member mutableCopy];
 commit[@"Stage"]=@"COMMITTED";commit[@"PaneBound"]=@YES;
 commit[@"PaneFrameVerified"]=@YES;commit[@"HitRegionVerified"]=@YES;
 commit[@"Timestamp"]=@200;
 NSMutableDictionary *updated=[owner mutableCopy];updated[@"Timestamp"]=@200;
 assert(DF184MapMembershipAccepted(pulse,updated,commit,choice,nil,200));
 assert(!DF184MapMembershipAccepted(pulse,updated,commit,choice,nil,201.251));
 NSDictionary *revoke=@{@"Version":@1,@"Session":sid,@"Revoked":@YES};
 assert(!DF184MapMembershipAccepted(pulse,updated,commit,choice,revoke,200));
 NSDictionary *badFields=@{@"Process":@"CarPlayApp",@"BundleID":@"com.apple.Maps",
    @"ControllerClass":@"UIViewController",@"SceneClass":@"UIView",
    @"WindowRole":@"UIWindowSceneSessionRoleApplication",
    @"WindowExternal":@NO,@"WindowVisible":@NO,
    @"SceneHostAttached":@NO,@"HitRegionVerified":@NO,
    @"PaneBound":@NO,@"PaneFrameVerified":@NO,@"AssignmentID":other,
    @"Session":other,@"PhysicalSlot":@1,@"HostSceneID":@"foreign",
    @"NativeSceneID":@"",@"PresentationSource":@"guessed",@"Stage":@"REVOKED"};
 unsigned checks=5;
 for(id key in badFields) {
   NSMutableDictionary *x=[commit mutableCopy];x[key]=badFields[key];
   assert(!DF184MapMembershipAccepted(pulse,updated,x,choice,nil,200));checks++;
   [x removeObjectForKey:key];
   assert(!DF184MapMembershipAccepted(pulse,updated,x,choice,nil,200));checks++;
 }
 NSMutableDictionary *wrongChoice=[choice mutableCopy];
 wrongChoice[@"AssignmentID"]=other;
 assert(!DF184MapMembershipAccepted(pulse,updated,commit,wrongChoice,nil,200));checks++;
 NSMutableDictionary *notHome=[updated mutableCopy];
 notHome[@"HomeHookReady"]=@NO;
 assert(!DF184MapMembershipAccepted(pulse,notHome,commit,choice,nil,200));checks++;
 NSMutableDictionary *notBackground=[pulse mutableCopy];
 notBackground[@"HostBackground"]=@NO;
 assert(!DF184MapMembershipAccepted(notBackground,updated,commit,choice,nil,200));checks++;
 printf("QA184_MAPS_PRESENTATION_LEASE_%u_CASES_PASS\n",checks);
 return 0;
}}