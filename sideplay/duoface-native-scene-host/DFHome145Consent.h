// QA145: Explicit phone-controlled consent for independent native CarPlay Home
// standalone app activation. No vendor logic, no deployment side effects.
#ifndef DF_HOME145_STANDALONE_CONSENT_H
#define DF_HOME145_STANDALONE_CONSENT_H
#import <Foundation/Foundation.h>
#import <notify.h>
#import <unistd.h>
#import "DFHome140Consent.h"

static NSString *const DFHome145ConsentPath=
 @"/var/mobile/Library/Preferences/com.duoface.nativehost.standalone144-optin.plist";
static const char *const DFHome145ConsentChanged=
 "com.duoface.nativehost.standalone144.consent.changed.v1";

NS_INLINE BOOL DFHome145EnabledAt(NSString *path,BOOL parentAllowed) {
 NSDictionary *p=[NSDictionary dictionaryWithContentsOfFile:path];
 return parentAllowed && [p isKindOfClass:NSDictionary.class] &&
        [p[@"Version"] isEqual:@1] &&
        [p[@"StandaloneHomeDirect"] isEqual:@YES];
}
NS_INLINE BOOL DFHome145Enabled(void) {
 return DFHome145EnabledAt(DFHome145ConsentPath,DFHome140Enabled());
}
NS_INLINE BOOL DFHome145Write(BOOL enable) {
 // Never silently enable the parent experimental Home policy.
 if(enable && !DFHome140Enabled())return NO;
 NSDictionary *record=@{@"Version":@1,@"StandaloneHomeDirect":@(enable)};
 if(![record writeToFile:DFHome145ConsentPath atomically:YES])return NO;
 if(DFHome145EnabledAt(DFHome145ConsentPath,YES)!=enable)return NO;
 notify_post(DFHome145ConsentChanged);
 return YES;
}
#endif
