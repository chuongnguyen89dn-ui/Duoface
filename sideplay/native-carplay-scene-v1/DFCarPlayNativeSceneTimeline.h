// First-party, READ-ONLY CarPlay native scene observation timeline.
// No private scene actions, no view adoption, no navigation teardown.
// A snapshot cannot prove an offscreen FBScene was destroyed or that
// simultaneous native full-map panes are supported.
#ifndef DF_CARPLAY_NATIVE_SCENE_TIMELINE_H
#define DF_CARPLAY_NATIVE_SCENE_TIMELINE_H
#import <Foundation/Foundation.h>
#import "DFCarPlayNativeSceneIdentity.h"

static inline BOOL DFCPValidPointer(id pointer) {
    return [pointer isKindOfClass:NSString.class] &&
           [(NSString *)pointer hasPrefix:@"0x"] &&
           [(NSString *)pointer length]>=4 &&
           [(NSString *)pointer length]<=32 &&
           ![pointer isEqual:@"0x0"];
}
static inline NSString *DFCPString(id value) {
    return [value isKindOfClass:NSString.class] ? (NSString *)value : @"";
}
// The generation is a process-local observational epoch, not a scene lease
// granting ownership or authorization to manipulate foreign views.
static inline NSDictionary *DFCarPlayNativeSceneTimelineAdvance(
    NSDictionary *previous, NSArray *controllers, NSString *session,
    NSNumber *pid, NSNumber *utc, BOOL completeScan) {
    if(![controllers isKindOfClass:NSArray.class] ||
       ![session isKindOfClass:NSString.class] || session.length==0 ||
       ![pid isKindOfClass:NSNumber.class] || pid.longLongValue<=0 ||
       ![utc isKindOfClass:NSNumber.class] || utc.longLongValue<=0)
        return @{@"schema":@1,@"status":@"unresolved",@"canAttachPane":@NO};
    BOOL same=[previous isKindOfClass:NSDictionary.class] &&
        [previous[@"session"] isEqual:session] &&
        [previous[@"pid"] isEqual:pid];
    NSUInteger tick=same?[previous[@"tick"] unsignedIntegerValue]+1:1;
    NSUInteger generation=same?[previous[@"lastGeneration"] unsignedIntegerValue]:0;
    NSArray *oldOwners=same && [previous[@"owners"] isKindOfClass:NSArray.class]
        ?previous[@"owners"]:@[];
    NSMutableDictionary *oldByPointer=[NSMutableDictionary new];
    for(id item in oldOwners) {
        if([item isKindOfClass:NSDictionary.class] &&
           DFCPValidPointer(item[@"controllerPointer"]))
            oldByPointer[item[@"controllerPointer"]]=item;
    }
    NSMutableArray *owners=[NSMutableArray new];
    NSMutableArray *events=[NSMutableArray new];
    NSMutableSet *seenPointers=[NSMutableSet new];
    NSUInteger nativeMaps=0,nativeDuoFace=0,unresolved=0;
    for(id item in controllers) {
        if(![item isKindOfClass:NSDictionary.class] ||
           ![item[@"controllerClass"] isEqual:@"DBApplicationSceneViewController"])
            continue;
        NSString *pointer=DFCPString(item[@"controllerPointer"]);
        if(!DFCPValidPointer(pointer) || [seenPointers containsObject:pointer]) {
            unresolved++; continue;
        }
        [seenPointers addObject:pointer];
        NSString *route=DFCarPlayNativeSceneRoute(item);
        NSString *bundle=DFCPString(item[@"hostedBundleIdentifier"]);
        NSString *scene=DFCPString(item[@"hostedSceneIdentifier"]);
        NSString *host=DFCPString(item[@"sceneHostViewPointer"]);
        NSString *window=DFCPString(item[@"sceneHostViewWindow"]);
        NSString *processBundle=DFCPString(item[@"nativeSceneProcessBundleIdentifier"]);
        if((processBundle.length>0 && ![processBundle isEqual:bundle]) ||
           !DFCPValidPointer(host))
            route=@"unresolved";
        if(![route isEqual:@"native-foreign-scene"] &&
           ![route isEqual:@"native-duoface-scene"]) {
            route=@"unresolved"; unresolved++;
            // Never carry forward a previously valid owner after an invalid read.
            bundle=@""; scene=@""; host=@""; window=@"";
        }
        // Include the native scene ID and host view pointer. Same controller
        // re-bound from Maps to DuoFace MUST open a new epoch.
        NSString *signature=[NSString stringWithFormat:@"%@|%@|%@|%@",
                             route,bundle,scene,host];
        NSDictionary *old=oldByPointer[pointer];
        BOOL changed=![old[@"signature"] isEqual:signature];
        if(changed) {
            generation++;
            [events addObject:@{
                @"kind":old?@"rebound-or-invalidated":@"first-observed",
                @"controllerPointer":pointer,
                @"previousRoute":DFCPString(old[@"route"]),
                @"currentRoute":route,
                @"generation":@(generation)
            }];
        }
        NSUInteger epoch=changed?generation:[old[@"generation"] unsignedIntegerValue];
        NSDictionary *record=@{
            @"controllerPointer":pointer,@"signature":signature,
            @"sceneIdentifier":scene,@"bundleIdentifier":bundle,
            @"hostViewPointer":host,@"hostWindowPointer":window,
            @"route":route,@"generation":@(epoch),@"seenTick":@(tick),
            @"hostWindowObserved":@(DFCPValidPointer(window))
        };
        [owners addObject:record];
        if([route isEqual:@"native-foreign-scene"] &&
           [bundle isEqual:@"com.google.Maps"])nativeMaps++;
        if([route isEqual:@"native-duoface-scene"])nativeDuoFace++;
    }
    if(completeScan) {
        for(NSDictionary *old in oldOwners) {
            if(![seenPointers containsObject:old[@"controllerPointer"]]) {
                [events addObject:@{
                    @"kind":@"not-observed-not-proof-of-destruction",
                    @"controllerPointer":old[@"controllerPointer"],
                    @"previousRoute":DFCPString(old[@"route"])
                }];
            }
        }
    }
    BOOL candidate=NO;
    // Co-observation is strictly a candidate, NOT proof of two rendered panes.
    if(completeScan && nativeMaps>0 && nativeDuoFace>0) {
        for(NSDictionary *a in owners) {
            if(![a[@"bundleIdentifier"] isEqual:@"com.google.Maps"] ||
               ![a[@"hostWindowObserved"] boolValue])continue;
            for(NSDictionary *b in owners) {
                if([b[@"route"] isEqual:@"native-duoface-scene"] &&
                   [b[@"hostWindowObserved"] boolValue] &&
                   ![a[@"controllerPointer"] isEqual:b[@"controllerPointer"]] &&
                   ![a[@"sceneIdentifier"] isEqual:b[@"sceneIdentifier"]])
                    candidate=YES;
            }
        }
    }
    return @{@"schema":@1,@"status":completeScan?@"observed":@"partial",
        @"session":session,@"pid":pid,@"utc":utc,@"tick":@(tick),
        @"lastGeneration":@(generation),@"owners":owners,@"events":events,
        @"nativeMapsCount":@(nativeMaps),@"nativeDuoFaceCount":@(nativeDuoFace),
        @"unresolvedCount":@(unresolved),
        @"distinctNativeHostCandidate":@(candidate),
        @"simultaneousPaneRenderingProven":@NO,@"canAttachPane":@NO};
}
#endif
