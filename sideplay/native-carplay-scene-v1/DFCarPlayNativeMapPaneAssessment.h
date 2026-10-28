// First-party CarPlayApp native-navigation / existing DuoFace split evidence.
// READ-ONLY candidate identification. Never claims permission to reparent,
// mirror or foreground a foreign CPWindow, or proof of actual map tiles.
#ifndef DF_CARPLAY_NATIVE_MAP_PANE_ASSESSMENT_H
#define DF_CARPLAY_NATIVE_MAP_PANE_ASSESSMENT_H
#import <Foundation/Foundation.h>
#import <math.h>
#import "DFCarPlayNativeSceneTimeline.h"

static inline BOOL DFCPMapNavigationBundle(NSString *bundle) {
    return [bundle isKindOfClass:NSString.class] &&
           [@[@"com.google.Maps",@"com.apple.Maps",@"com.waze.iphone"]
             containsObject:bundle];
}
// SpringBoard publishes this short-lived DuoFace session heartbeat. A
// session is NOT a navigation-scene lease or a CarPlay-app permission.
static inline BOOL DFCPDuoFaceHeartbeatLive(NSDictionary *pulse, NSTimeInterval now) {
    if(![pulse isKindOfClass:NSDictionary.class] ||
       ![pulse[@"Version"] isEqual:@1] ||
       ![pulse[@"Active"] isEqual:@YES] ||
       ![pulse[@"Session"] isKindOfClass:NSString.class] ||
       ![[NSUUID alloc] initWithUUIDString:pulse[@"Session"]] ||
       ![pulse[@"Timestamp"] isKindOfClass:NSNumber.class] ||
       !isfinite(now))return NO;
    double timestamp=[pulse[@"Timestamp"] doubleValue];
    double age=now-timestamp;
    return isfinite(timestamp) && age>=0 && age<=2.5;
}
// Assesses exactly one native CarPlay app scene + the EXISTING SpringBoard
// DuoFace session (potential YouTube). TWO native Maps FBScenes are NOT required.
// The host owner and bitmap rendering still require live/device validation.
static inline NSDictionary *DFCarPlayNativeMapPaneAssessment(
    NSArray *controllers, NSDictionary *timeline,
    NSDictionary *duofacePulse, NSTimeInterval now, BOOL completeScan) {
    BOOL live=DFCPDuoFaceHeartbeatLive(duofacePulse,now);
    if(![controllers isKindOfClass:NSArray.class] ||
       ![timeline isKindOfClass:NSDictionary.class] ||
       ![timeline[@"owners"] isKindOfClass:NSArray.class] ||
       !isfinite(now) || now<=0) {
        return @{@"schema":@1,@"state":@"unresolved",
                 @"duofaceSessionLive":@(live),@"nativeMapCount":@0,
                 @"nativeMapWithPhoneSessionCandidate":@NO,
                 @"nativeMapTilesRendered":@NO,@"navigationContinuityProven":@NO,
                 @"canAttachPane":@NO};
    }
    NSUInteger count=0, windowed=0, dashboardDuo=0, unresolved=0;
    NSMutableArray *appIDs=[NSMutableArray new];
    // Validate EACH original native controller identity directly; do not
    // promote Dashboard map widgets or an inactive previous timeline owner.
    for(id item in controllers) {
        if(![item isKindOfClass:NSDictionary.class])continue;
        if(![item[@"controllerClass"] isEqual:@"DBApplicationSceneViewController"])continue;
        NSString *route=DFCarPlayNativeSceneRoute(item);
        if([route isEqual:@"native-duoface-scene"])dashboardDuo++;
        NSString *bundle=item[@"hostedBundleIdentifier"];
        if(!DFCPMapNavigationBundle(bundle))continue;
        if(![route isEqual:@"native-foreign-scene"]) {unresolved++;continue;}
        count++;
        if(DFCPValidPointer(item[@"sceneHostViewPointer"]) &&
           DFCPValidPointer(item[@"sceneHostViewWindow"]))
            windowed++;
        if(![appIDs containsObject:bundle]) [appIDs addObject:bundle];
    }
    BOOL ownerWindow=(count==1 && windowed==1 && unresolved==0);
    BOOL candidate=completeScan && ownerWindow && live && dashboardDuo==0;
    NSString *state;
    if(!completeScan)state=@"partial-scan";
    else if(unresolved)state=@"unresolved-native-map-owner";
    else if(count>1)state=@"multiple-native-map-owners-unresolved";
    else if(count==0 && dashboardDuo>0)state=@"native-map-not-observed-duoface-scene-present";
    else if(count==0)state=@"native-map-not-observed";
    else if(!ownerWindow)state=@"native-map-window-not-confirmed";
    else if(dashboardDuo>0)state=@"native-map-and-duoface-host-observed-not-pane-proof";
    else if(!live)state=@"native-map-observed-no-live-duoface-session";
    else state=@"one-native-map-plus-phone-session-candidate";
    return @{@"schema":@1,@"state":state,@"duofaceSessionLive":@(live),
        @"nativeMapCount":@(count),@"nativeMapWindowCount":@(windowed),
        @"nativeDashboardDuoFaceCount":@(dashboardDuo),
        @"unresolvedNavigationOwners":@(unresolved),
        @"navigationBundles":appIDs,@"completeScan":@(completeScan),
        @"nativeMapWithPhoneSessionCandidate":@(candidate),
        // Neither reading a live FBScene nor reading the phone heartbeat
        // proves visual map tiles, navigation progress or rehost permission.
        @"nativeMapTilesRendered":@NO,@"navigationContinuityProven":@NO,
        @"canAttachPane":@NO};
}
#endif
