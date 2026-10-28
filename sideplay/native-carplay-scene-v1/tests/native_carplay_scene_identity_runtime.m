// Executable independent Foundation tests for the actual Google Maps->DuoFace
// CarPlay Dashboard owner observed in on-device 46-snapshot JSONL.
#import <Foundation/Foundation.h>
#import "../DFCarPlayNativeSceneIdentity.h"
static void check(BOOL ok,NSString *name) {
    if(!ok){NSLog(@"FAIL native-scene-identity %@",name);exit(1);}
}
int main(void) {
    @autoreleasepool {
        NSDictionary *maps=@{
            @"controllerClass":@"DBApplicationSceneViewController",
            @"sceneHostViewStatus":@"present-UIView",
            @"nativeSceneStatus":@"present",
            @"nativeApplicationInfoStatus":@"present",
            @"nativeSceneClass":@"FBScene",
            @"hostedBundleIdentifier":@"com.google.Maps",
            @"hostedSceneIdentifier":@"Car[2-3]:com.apple.CarPlayTemplateUIHost:com.google.Maps"
        };
        check([DFCarPlayNativeSceneRoute(maps) isEqual:@"native-foreign-scene"],@"real Maps");
        check(DFCarPlayOwnsForeignNativeScene(maps),@"foreign owner protected");
        NSMutableDictionary *duo=[maps mutableCopy];
        duo[@"hostedBundleIdentifier"]=@"com.duoface.native.scenehost";
        duo[@"hostedSceneIdentifier"]=@"Car[2-3]:com.apple.CarPlayTemplateUIHost:com.duoface.native.scenehost";
        check([DFCarPlayNativeSceneRoute(duo) isEqual:@"native-duoface-scene"],@"real DuoFace host");
        check(!DFCarPlayOwnsForeignNativeScene(duo),@"DuoFace not foreign");
        NSMutableDictionary *notHosted=[maps mutableCopy];
        notHosted[@"sceneHostViewStatus"]=@"nil";
        check([DFCarPlayNativeSceneRoute(notHosted) isEqual:@"unresolved"],@"no host");
        NSMutableDictionary *wrongScene=[maps mutableCopy];
        wrongScene[@"hostedSceneIdentifier"]=@"DBDashboard-Car[2-3]";
        check([DFCarPlayNativeSceneRoute(wrongScene) isEqual:@"unresolved"],@"dashboard scene is not FBS app");
        NSMutableDictionary *mismatch=[maps mutableCopy];
        mismatch[@"hostedSceneIdentifier"]=@"Car[2-3]:com.apple.CarPlayTemplateUIHost:com.apple.Maps";
        check([DFCarPlayNativeSceneRoute(mismatch) isEqual:@"unresolved"],@"no bundle mismatch");
        NSMutableDictionary *badClass=[maps mutableCopy];
        badClass[@"controllerClass"]=@"DBMapsNavigationWidgetViewController";
        check([DFCarPlayNativeSceneRoute(badClass) isEqual:@"unresolved"],@"widget not full app");
        NSMutableDictionary *badInfo=[maps mutableCopy];
        badInfo[@"nativeApplicationInfoStatus"]=@"absent";
        check([DFCarPlayNativeSceneRoute(badInfo) isEqual:@"unresolved"],@"missing app identity");
        check([DFCarPlayNativeSceneRoute(nil) isEqual:@"unknown"],@"empty input");
        NSLog(@"DUOFACE_CARPLAY_NATIVE_MAPS_OWNER_IDENTITY_CONTRACT_PASS");
    }
    return 0;
}
