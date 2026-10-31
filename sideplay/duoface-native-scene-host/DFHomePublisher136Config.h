// QA136 independent native Home admission: explicit user switch and kill switch.
// Existing enabled-app list is a separate, stricter intersection.
#ifndef DF_HOME_PUBLISHER136_CONFIG_H
#define DF_HOME_PUBLISHER136_CONFIG_H
#import <Foundation/Foundation.h>
#import <notify.h>
#import <unistd.h>
static NSString *const DFHome136ConfigPath=
 @"/var/mobile/Library/Preferences/com.duoface.nativehost.home-publisher136.v1.plist";
static const char *const DFHome136Kill=
 "/var/mobile/Library/Preferences/.duoface-home136-disable";
static const char *const DFHome136Changed=
 "com.duoface.nativehost.home-publisher136.changed.v1";
NS_INLINE BOOL DFHome136EnabledAt(NSString *path,BOOL killed) {
 if(killed || ![path isKindOfClass:NSString.class])return NO;
 NSDictionary *pref=[NSDictionary dictionaryWithContentsOfFile:path];
 return [pref isKindOfClass:NSDictionary.class] &&
        [pref[@"Version"] isEqual:@1] &&
        [pref[@"Enabled"] isKindOfClass:NSNumber.class] &&
        [pref[@"Enabled"] boolValue];
}
NS_INLINE BOOL DFHome136Enabled(void) {
 return DFHome136EnabledAt(DFHome136ConfigPath,access(DFHome136Kill,F_OK)==0);
}
NS_INLINE BOOL DFHome136Write(BOOL enabled) {
 NSDictionary *pref=@{@"Version":@1,@"Enabled":@(enabled)};
 if(![pref writeToFile:DFHome136ConfigPath atomically:YES])return NO;
 if(DFHome136EnabledAt(DFHome136ConfigPath,NO)!=enabled)return NO;
 notify_post(DFHome136Changed);
 return YES;
}
#endif
