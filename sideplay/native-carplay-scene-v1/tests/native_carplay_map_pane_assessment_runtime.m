// Source-runtime acceptance of a single real native CarPlay Maps scene
// alongside existing phone-hosted DuoFace (YouTube). Replays representative
// identities from actual 46 snapshot log, but does NOT emulate map tiles.
#import <Foundation/Foundation.h>
#import "../DFCarPlayNativeMapPaneAssessment.h"
static void check(BOOL ok, NSString *what) {
    if(!ok){NSLog(@"FAIL native-map-join %@",what);exit(1);}
}
static NSMutableDictionary *scene(NSString *bundle,NSString *controller) {
    return [@{@"controllerClass":@"DBApplicationSceneViewController",
       @"controllerPointer":controller,@"sceneHostViewStatus":@"present-UIView",
       @"sceneHostViewPointer":@"0x5d0a15160",
       @"sceneHostViewWindow":@"0x5d0d31600",
       @"nativeSceneClass":@"FBScene",@"nativeSceneStatus":@"present",
       @"nativeApplicationInfoStatus":@"present",
       @"hostedBundleIdentifier":bundle,
       @"hostedSceneIdentifier":[NSString stringWithFormat:
          @"Car[2-3]:com.apple.CarPlayTemplateUIHost:%@",bundle]}
          mutableCopy];
}
int main(void) {
 @autoreleasepool {
    NSNumber *pid=@68776;NSString *probe=@"D0177F7C-EFD1-446C-8253-9EB9F95553DA";
    NSTimeInterval now=1793163729;
    NSDictionary *pulse=@{@"Version":@1,@"Active":@YES,
       @"Session":@"D0177F7C-EFD1-446C-8253-9EB9F95553DA",
       @"Timestamp":@(now-1.0)};
    NSDictionary *maps=scene(@"com.google.Maps",@"0x5d0a14140");
    NSDictionary *timeline=DFCarPlayNativeSceneTimelineAdvance(nil,@[maps],probe,pid,@(now),YES);
    NSDictionary *a=DFCarPlayNativeMapPaneAssessment(@[maps],timeline,pulse,now,YES);
    check([a[@"state"] isEqual:@"one-native-map-plus-phone-session-candidate"],@"native+phone observed");
    check([a[@"nativeMapCount"] isEqual:@1] &&
          [a[@"nativeMapWindowCount"] isEqual:@1],@"real native FBScene host window");
    check([a[@"duofaceSessionLive"] isEqual:@YES],@"real existing phone heartbeat");
    check([a[@"nativeMapWithPhoneSessionCandidate"] isEqual:@YES],@"one map + phone sufficient");
    check([a[@"nativeMapTilesRendered"] isEqual:@NO] &&
          [a[@"navigationContinuityProven"] isEqual:@NO] &&
          [a[@"canAttachPane"] isEqual:@NO],@"never assert actual visual/attach");
    NSDictionary *stale=@{@"Version":@1,@"Active":@YES,
       @"Session":@"D0177F7C-EFD1-446C-8253-9EB9F95553DA",
       @"Timestamp":@(now-3.0)};
    NSDictionary *b=DFCarPlayNativeMapPaneAssessment(@[maps],timeline,stale,now,YES);
    check([b[@"state"] isEqual:@"native-map-observed-no-live-duoface-session"] &&
          [b[@"nativeMapWithPhoneSessionCandidate"] isEqual:@NO],@"stale heartbeat rejected");
    NSMutableDictionary *badInfo=[maps mutableCopy];
    badInfo[@"hostedSceneIdentifier"]=@"Car[2-3]:com.apple.CarPlayTemplateUIHost:com.apple.Maps";
    NSDictionary *invalid=DFCarPlayNativeMapPaneAssessment(@[badInfo],timeline,pulse,now,YES);
    check([invalid[@"state"] isEqual:@"unresolved-native-map-owner"] &&
          [invalid[@"nativeMapWithPhoneSessionCandidate"] isEqual:@NO],@"app/scene mismatch");
    NSMutableDictionary *widget=[maps mutableCopy];
    widget[@"controllerClass"]=@"DBMapsWidgetViewController";
    NSDictionary *w=DFCarPlayNativeMapPaneAssessment(@[widget],timeline,pulse,now,YES);
    check([w[@"nativeMapCount"] isEqual:@0] && [w[@"canAttachPane"] isEqual:@NO],
          @"Dashboard widget is not Google Maps full scene");
    NSMutableDictionary *unwindowed=[maps mutableCopy];
    unwindowed[@"sceneHostViewWindow"]=@"nil";
    NSDictionary *nw=DFCarPlayNativeMapPaneAssessment(@[unwindowed],timeline,pulse,now,YES);
    check([nw[@"nativeMapWithPhoneSessionCandidate"] isEqual:@NO] &&
          [nw[@"state"] isEqual:@"native-map-window-not-confirmed"],@"no real UIWindow");
    NSMutableDictionary *duo=scene(@"com.duoface.native.scenehost",@"0x5d0a14140");
    NSDictionary *handoff=DFCarPlayNativeSceneTimelineAdvance(timeline,@[duo],probe,pid,@(now+30),YES);
    NSDictionary *after=DFCarPlayNativeMapPaneAssessment(@[duo],handoff,pulse,now,YES);
    check([after[@"state"] isEqual:@"native-map-not-observed-duoface-scene-present"] &&
          [after[@"nativeMapWithPhoneSessionCandidate"] isEqual:@NO],
          @"same Dashboard controller rebind is not Maps coexistence");
    NSDictionary *partial=DFCarPlayNativeMapPaneAssessment(@[maps],timeline,pulse,now,NO);
    check([partial[@"state"] isEqual:@"partial-scan"] &&
          [partial[@"nativeMapWithPhoneSessionCandidate"] isEqual:@NO],
          @"no premature merge on limited controller scan");
    NSMutableDictionary *apple=scene(@"com.apple.Maps",@"0x555abcd12");
    apple[@"sceneHostViewPointer"]=@"0x555aabbcc";
    apple[@"sceneHostViewWindow"]=@"0x555cdef12";
    NSDictionary *two=DFCarPlayNativeMapPaneAssessment(@[maps,apple],timeline,pulse,now,YES);
    check([two[@"state"] isEqual:@"multiple-native-map-owners-unresolved"],@"two Maps need owner resolution");
    check([two[@"canAttachPane"] isEqual:@NO],@"even two host views cannot confer ownership");
    NSDictionary *null=DFCarPlayNativeMapPaneAssessment(nil,nil,pulse,now,YES);
    check([null[@"state"] isEqual:@"unresolved"] && [null[@"canAttachPane"] isEqual:@NO],
          @"invalid snapshot fail closed");
    NSLog(@"DUOFACE_ONE_NATIVE_MAP_PLUS_PHONE_SCENE_JOIN_ASSESSMENT_PASS_NO_ATTACH");
 }
 return 0;
}
