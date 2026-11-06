// Independent OmniCar-inspired separation of OS-native maps and phone AppBridge.
// No vendor runtime, license, entitlements or synthetic CarPlay Home icon.
#ifndef DF_CARPLAY_APP_ROUTE_178_H
#define DF_CARPLAY_APP_ROUTE_178_H
#import <Foundation/Foundation.h>
#import "DFEnabledAppsPolicy.h"
#import "DFNativeMapLeasePolicy.h"
typedef NS_ENUM(NSInteger, DF178SelectedAppRoute) {
    DF178AppUnavailable=0,
    DF178PhoneAppBridge=1,
    DF178NativeMapReady=2,
    DF178NativeMapUnverified=3
};
// The exact installed and enabled identities are mandatory. This policy
// cannot authenticate a native map scene: the existing CarPlay coordinator
// separately verifies UIKit owner, Dashboard scene role, slot and geometry.
NS_INLINE DF178SelectedAppRoute DF178RouteForSelectedBundle(
    id bundle,NSArray<NSString *> *installed,
    NSArray<NSString *> *enabled,NSArray<NSString *> *nativeMaps) {
    if(![bundle isKindOfClass:NSString.class] ||
       ![installed isKindOfClass:NSArray.class] ||
       ![installed containsObject:bundle] ||
       !DFPickerAllowsApp(bundle,enabled))return DF178AppUnavailable;
    if(DFNativeMapAllowedBundle(bundle)){
        return [nativeMaps isKindOfClass:NSArray.class] &&
               [nativeMaps containsObject:bundle]?
               DF178NativeMapReady:DF178NativeMapUnverified;
    }
    // GOFA currently uses the existing PHONE AppBridge scene host.
    // Its historical native declaration alone does not grant a verified
    // native map controller/adapter or CarPlay-window attachment.
    return DF178PhoneAppBridge;
}
#endif
