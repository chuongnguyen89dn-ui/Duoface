// QA155 private pilot: fixed package-time process filter AND live user consent.
// A full arbitrary-app receiver cannot use a wildcard substrate filter safely.
// Do not silently add Apple CarPlay/Home, Youtube, GOFA or DuoFace processes.
#ifndef DF155_PILOT_APP_SCOPE_H
#define DF155_PILOT_APP_SCOPE_H
#import "DFEnabledAppsPolicy.h"
NS_INLINE BOOL DF155PilotAppID(NSString *bundle) {
 return [bundle isEqualToString:@"com.apple.mobilesafari"] ||
        [bundle isEqualToString:@"org.videolan.vlc-ios"];
}
NS_INLINE BOOL DF155EnabledPilotApp(NSString *bundle) {
 return DF155PilotAppID(bundle) &&
        DFPickerAllowsApp(bundle,DFConfiguredEnabledAppIDs());
}
#endif
