// DuoFace first-party, phone-managed, device-local settings for supported UI.
// No background microphone, auto-launch, or system-lock triggers.
#ifndef DF_EXTENDED_SETTINGS_POLICY_H
#define DF_EXTENDED_SETTINGS_POLICY_H
#import <Foundation/Foundation.h>
#import <notify.h>
static NSString *const DFExtendedPrefsPath =
 @"/var/mobile/Library/Preferences/com.duoface.nativehost.extended-settings.v1.plist";
static const char *const DFExtendedPrefsChanged =
 "com.duoface.nativehost.extended-settings.changed.v1";
NS_INLINE NSDictionary *DFExtendedDefaults(void) {
 return @{@"Version":@1,@"Language":@"vi"};
}
NS_INLINE NSDictionary *DFReadExtendedAtPath(NSString *path){
 NSDictionary *x=[NSDictionary dictionaryWithContentsOfFile:path];
 if(![x isKindOfClass:NSDictionary.class] || ![x[@"Version"] isEqual:@1] ||
    ![x[@"Language"] isKindOfClass:NSString.class] ||
    ![@[@"vi",@"en"] containsObject:x[@"Language"]])return DFExtendedDefaults();
 return @{@"Version":@1,@"Language":x[@"Language"]};
}
NS_INLINE NSDictionary *DFCurrentExtended(void) {
 return DFReadExtendedAtPath(DFExtendedPrefsPath);
}
NS_INLINE BOOL DFWriteExtendedAtPath(NSString *language,NSString *path) {
 if(![@[@"vi",@"en"] containsObject:language] || ![path isKindOfClass:NSString.class] ||
    !path.length)return NO;
 NSDictionary *record=@{@"Version":@1,@"Language":language};
 if(![record writeToFile:path atomically:YES])return NO;
 return [DFReadExtendedAtPath(path)[@"Language"] isEqualToString:language];
}
NS_INLINE BOOL DFSaveExtendedLanguage(NSString *language){
 if(!DFWriteExtendedAtPath(language,DFExtendedPrefsPath))return NO;
 notify_post(DFExtendedPrefsChanged);
 return YES;
}
NS_INLINE NSString *DFLocalize(NSString *vietnamese,NSString *english){
 return [DFCurrentExtended()[@"Language"] isEqualToString:@"en"]?english:vietnamese;
}
#endif
