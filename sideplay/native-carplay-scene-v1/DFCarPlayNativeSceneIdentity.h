// First-party READ-ONLY CarPlay native-scene identity contract.
// Verifies actual iOS16 Dashboard FBScene owner evidence, not bundle names
// alone. No vendor implementation/license, no CPWindow creation/reparenting.
#ifndef DF_CARPLAY_NATIVE_SCENE_IDENTITY_H
#define DF_CARPLAY_NATIVE_SCENE_IDENTITY_H
#import <Foundation/Foundation.h>

static inline NSString *DFCarPlayNativeSceneRoute(NSDictionary *snapshot) {
    if(![snapshot isKindOfClass:NSDictionary.class])return @"unknown";
    id controller=snapshot[@"controllerClass"];
    id host=snapshot[@"sceneHostViewStatus"];
    id bundle=snapshot[@"hostedBundleIdentifier"];
    id sceneID=snapshot[@"hostedSceneIdentifier"];
    id sceneClass=snapshot[@"nativeSceneClass"];
    id sceneStatus=snapshot[@"nativeSceneStatus"];
    id appStatus=snapshot[@"nativeApplicationInfoStatus"];
    if(![controller isEqual:@"DBApplicationSceneViewController"] ||
       ![host isEqual:@"present-UIView"] ||
       ![sceneStatus isEqual:@"present"] || ![appStatus isEqual:@"present"] ||
       ![bundle isKindOfClass:NSString.class] ||
       ![sceneID isKindOfClass:NSString.class] ||
       ![sceneClass isKindOfClass:NSString.class])return @"unresolved";
    // Cross-check FBScene identity and exact CarPlay role. A Dashboard UIKit
    // scene ID and a hosted FBScene ID are different; never confuse them.
    if(![sceneClass isEqual:@"FBScene"] ||
       ![sceneID hasPrefix:@"Car["] ||
       [sceneID rangeOfString:@"]:com.apple.CarPlayTemplateUIHost:"].location==NSNotFound)
       return @"unresolved";
    NSString *suffix=[NSString stringWithFormat:@":%@",bundle];
    if([(NSString *)bundle length]<3 || [(NSString *)bundle length]>160 || ![(NSString *)sceneID hasSuffix:suffix])
        return @"unresolved";
    if([bundle isEqual:@"com.duoface.native.scenehost"])
        return @"native-duoface-scene";
    // OTHER native CarPlay application, including Google Maps. This only
    // establishes the ONE original Dashboard hosted scene identity.
    return @"native-foreign-scene";
}
static inline BOOL DFCarPlayOwnsForeignNativeScene(NSDictionary *snapshot) {
    return [DFCarPlayNativeSceneRoute(snapshot) isEqual:@"native-foreign-scene"];
}
#endif
