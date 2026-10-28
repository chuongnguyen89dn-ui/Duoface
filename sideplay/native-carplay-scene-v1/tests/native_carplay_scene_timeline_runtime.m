// Deterministic replay of real-device #41-#46 identity/owner sequence.
// 1-based JSONL numbering; does not assert the offscreen Maps FBScene died.
#import <Foundation/Foundation.h>
#import "../DFCarPlayNativeSceneTimeline.h"
static void check(BOOL ok,NSString *name) {
    if(!ok){NSLog(@"FAIL carplay-native-scene-timeline %@",name);exit(1);}
}
static NSMutableDictionary *owner(NSString *bundle,NSString *scene,NSString *pointer,NSString *window) {
    return [@{@"controllerClass":@"DBApplicationSceneViewController",
        @"controllerPointer":pointer,
        @"sceneHostViewStatus":@"present-UIView",
        @"sceneHostViewPointer":@"0x5d0a15160",
        @"sceneHostViewWindow":window,
        @"nativeSceneStatus":@"present",
        @"nativeApplicationInfoStatus":@"present",
        @"nativeSceneClass":@"FBScene",
        @"hostedBundleIdentifier":bundle,
        @"hostedSceneIdentifier":scene} mutableCopy];
}
int main(void) {
    @autoreleasepool {
        NSString *sid=@"D0177F7C-EFD1-446C-8253-9EB9F95553DA";
        NSNumber *pid=@68776;
        NSString *mapScene=@"Car[2-3]:com.apple.CarPlayTemplateUIHost:com.google.Maps";
        NSString *duoScene=@"Car[2-3]:com.apple.CarPlayTemplateUIHost:com.duoface.native.scenehost";
        NSMutableDictionary *maps=owner(@"com.google.Maps",mapScene,@"0x5d0a14140",@"0x5d0d31600");
        NSDictionary *t1=DFCarPlayNativeSceneTimelineAdvance(nil,@[maps],sid,pid,@1793163729,YES);
        check([t1[@"nativeMapsCount"] isEqual:@1],@"#41 Maps exists");
        check([t1[@"lastGeneration"] isEqual:@1],@"first generation");
        check([t1[@"canAttachPane"] isEqual:@NO],@"no adoption on first identity");
        NSDictionary *t2=DFCarPlayNativeSceneTimelineAdvance(t1,@[maps],sid,pid,@1793163757,YES);
        check([t2[@"lastGeneration"] isEqual:@1],@"#42 stable same host and scene");
        check([t2[@"events"] count]==0,@"no false transition");
        NSMutableDictionary *duo=owner(@"com.duoface.native.scenehost",duoScene,@"0x5d0a14140",@"0x5d0d31600");
        NSDictionary *t3=DFCarPlayNativeSceneTimelineAdvance(t2,@[duo],sid,pid,@1793163787,YES);
        check([t3[@"lastGeneration"] isEqual:@2],@"#43 same controller rebound to DuoFace");
        check([t3[@"nativeMapsCount"] isEqual:@0],@"no Maps in current snapshot");
        check([t3[@"nativeDuoFaceCount"] isEqual:@1],@"DuoFace now observed");
        check([t3[@"distinctNativeHostCandidate"] isEqual:@NO],@"sequential not concurrent");
        check([t3[@"events"][0][@"kind"] isEqual:@"rebound-or-invalidated"],@"transition qualified");
        NSDictionary *t4=DFCarPlayNativeSceneTimelineAdvance(t3,@[duo],sid,pid,@1793163817,YES);
        check([t4[@"lastGeneration"] isEqual:@2],@"#44 stable DuoFace");
        NSDictionary *t5=DFCarPlayNativeSceneTimelineAdvance(t4,@[],sid,pid,@1793163847,YES);
        check([t5[@"owners"] count]==0,@"#45 no reachable host");
        check([t5[@"events"][0][@"kind"] isEqual:@"not-observed-not-proof-of-destruction"],
              @"absence cannot prove scene destruction");
        NSDictionary *t6=DFCarPlayNativeSceneTimelineAdvance(t5,@[],sid,pid,@1793163877,YES);
        check([t6[@"events"] count]==0,@"#46 no invented destruction event");
        NSDictionary *partial=DFCarPlayNativeSceneTimelineAdvance(t4,@[],sid,pid,@1793163847,NO);
        check([partial[@"status"] isEqual:@"partial"] && [partial[@"events"] count]==0,
              @"truncated scans cannot declare disappearance");
        // A distinct, window-hosted pair MAY be a candidate but never authorizes
        // either foreign window adoption or backgrounding navigation.
        NSMutableDictionary *second=owner(@"com.duoface.native.scenehost",duoScene,
                                          @"0x55aaaaaaa",@"0x55bbbbbbb");
        second[@"sceneHostViewPointer"]=@"0x55ccccccc";
        NSDictionary *pair=DFCarPlayNativeSceneTimelineAdvance(nil,@[maps,second],sid,pid,@1793163999,YES);
        check([pair[@"distinctNativeHostCandidate"] isEqual:@YES],@"two real identity candidates");
        check([pair[@"simultaneousPaneRenderingProven"] isEqual:@NO] &&
              [pair[@"canAttachPane"] isEqual:@NO],@"coexistence not rendering permission");
        NSMutableDictionary *mismatch=[maps mutableCopy];
        mismatch[@"nativeSceneProcessBundleIdentifier"]=@"com.example.different";
        NSDictionary *invalid=DFCarPlayNativeSceneTimelineAdvance(t2,@[mismatch],sid,pid,@1793163787,YES);
        check([invalid[@"nativeMapsCount"] isEqual:@0] &&
              [invalid[@"unresolvedCount"] isEqual:@1],@"process bundle mismatch fails closed");
        check([invalid[@"lastGeneration"] isEqual:@2],@"invalidating old valid owner changes generation");
        NSDictionary *newPID=DFCarPlayNativeSceneTimelineAdvance(t4,@[maps],sid,@68777,@1793164010,YES);
        check([newPID[@"tick"] isEqual:@1] && [newPID[@"lastGeneration"] isEqual:@1],
              @"PID restart resets observational epochs");
        NSDictionary *newSession=DFCarPlayNativeSceneTimelineAdvance(t4,@[maps],
                               @"new-session",pid,@1793164010,YES);
        check([newSession[@"tick"] isEqual:@1],@"session restart resets timeline");
        NSDictionary *none=DFCarPlayNativeSceneTimelineAdvance(nil,nil,sid,pid,@1793164010,YES);
        check([none[@"canAttachPane"] isEqual:@NO] &&
              [none[@"status"] isEqual:@"unresolved"],@"no synthetic authority on invalid data");
        NSLog(@"DUOFACE_CARPLAY_NATIVE_MAPS_SCENE_TIMELINE_46_LOG_SEQUENCE_PASS");
    }
    return 0;
}
