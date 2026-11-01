// Independently supported application-side bridge clients from original
// DuoNavi static category research plus user's real Log24 bundle IDs.
// NOT a global wildcard injection: SpringBoard, CarPlay, DuoFace split,
// YouTube and GOFA retain their own independent scene/input contracts.
// Sender DF144Allowed validates live consent; app receiver validates real
// scene ID, request, generation/owner lease and restores exactly its windows.
#ifndef DF155_PILOT_APP_SCOPE_H
#define DF155_PILOT_APP_SCOPE_H
#import "DFEnabledAppsPolicy.h"
NS_INLINE NSArray<NSString *> *DF155SupportedAppIDs(void) {
 static NSArray<NSString *> *supported;
 static dispatch_once_t onceToken;
 dispatch_once(&onceToken,^{
   supported=@[
    @"com.apple.mobilesafari",
    @"org.videolan.vlc-ios",
    @"com.facebook.Facebook",
    @"com.ss.iphone.ugc.Ame",
    @"com.openai.chat",
    @"com.google.gemini",
    @"com.netflix.Netflix",
    @"tv.twitch",
    @"com.google.ios.youtubemusic",
    @"com.google.chrome.ios",
    @"com.spotify.client",
    @"com.google.Maps",
    @"com.waze.iphone",
    @"com.zhiliaoapp.musically"
   ];
 });
 return supported;
}
NS_INLINE BOOL DF155PilotAppID(NSString *bundle) {
 if(![bundle isKindOfClass:NSString.class] || !bundle.length)return NO;
 return [DF155SupportedAppIDs() containsObject:bundle];
}
NS_INLINE BOOL DF155EnabledPilotApp(NSString *bundle) {
 // App sandboxes may not see mobile prefs, so consent is checked by the
 // owning SpringBoard sender before each short, request-matched lease.
 return DF155PilotAppID(bundle);
}
#endif
