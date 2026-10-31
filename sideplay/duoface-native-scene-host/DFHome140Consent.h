// A recovered139 installation must not silently reactivate experimental hooks
// merely because its older136 switch was left ON before the138 incident.
#ifndef DF_HOME140_CONSENT_H
#define DF_HOME140_CONSENT_H
#import "DFHomePublisher136Config.h"
static NSString *const DFHome140ConsentPath=
 @"/var/mobile/Library/Preferences/com.duoface.nativehost.home140-consent.v1.plist";
NS_INLINE BOOL DFHome140EnabledAt(NSString *path,BOOL parentEnabled,BOOL killed) {
 return parentEnabled && DFHome136EnabledAt(path,killed);
}
NS_INLINE BOOL DFHome140Enabled(void) {
 return DFHome140EnabledAt(DFHome140ConsentPath,DFHome136Enabled(),
    access("/var/mobile/Library/Preferences/.duoface-home140-disable",F_OK)==0);
}
NS_INLINE BOOL DFHome140Write(BOOL enabled) {
 if(!DFHome136Write(enabled))return NO;
 NSDictionary *pref=@{@"Version":@1,@"Enabled":@(enabled)};
 if(![pref writeToFile:DFHome140ConsentPath atomically:YES] ||
    DFHome136EnabledAt(DFHome140ConsentPath,NO)!=enabled) {
   (void)DFHome136Write(NO);
   return NO;
 }
 notify_post(DFHome136Changed);
 return YES;
}
#endif
