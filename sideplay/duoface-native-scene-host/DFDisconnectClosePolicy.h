// Independent DuoFace, approved 2026-10-16: 10s (DuoDash original uses 12s).
// No native12/vendor runtime or license dependencies.
#ifndef DF_DISCONNECT_CLOSE_POLICY_H
#define DF_DISCONNECT_CLOSE_POLICY_H
#import <Foundation/Foundation.h>
#import <notify.h>
static NSString *const DFDisconnectClosePrefPath=
 @"/var/mobile/Library/Preferences/com.duoface.nativehost.disconnect-close.v1.plist";
static const char *const DFDisconnectCloseChanged=
 "com.duoface.nativehost.disconnect-close.changed.v1";
static NSTimeInterval const DFDisconnectCloseGrace=10.0;
NS_INLINE BOOL DFDisconnectCloseReadAtPath(NSString *path) {
 NSDictionary *p=[NSDictionary dictionaryWithContentsOfFile:path];
 return [p[@"Version"] isEqual:@1] && [p[@"CloseOnPhysicalDisconnect"] isKindOfClass:NSNumber.class] &&
        CFGetTypeID((__bridge CFTypeRef)p[@"CloseOnPhysicalDisconnect"])==CFBooleanGetTypeID() &&
        [p[@"CloseOnPhysicalDisconnect"] boolValue];
}
NS_INLINE BOOL DFDisconnectCloseEnabled(void) {
 return DFDisconnectCloseReadAtPath(DFDisconnectClosePrefPath);
}
NS_INLINE BOOL DFDisconnectCloseWriteAtPath(NSString *path,BOOL on) {
 NSDictionary *p=@{@"Version":@1,@"CloseOnPhysicalDisconnect":@(on)};
 if(![p writeToFile:path atomically:YES])return NO;
 NSDictionary *saved=[NSDictionary dictionaryWithContentsOfFile:path];
 return [saved[@"Version"] isEqual:@1] && saved[@"CloseOnPhysicalDisconnect"] &&
        [saved[@"CloseOnPhysicalDisconnect"] boolValue]==on;
}
NS_INLINE BOOL DFDisconnectCloseSetEnabled(BOOL on) {
 if(!DFDisconnectCloseWriteAtPath(DFDisconnectClosePrefPath,on))return NO;
 notify_post(DFDisconnectCloseChanged);
 return YES;
}
// Pure, deterministic generation/reconnect/policy gate for the delayed close.
NS_INLINE BOOL DFDisconnectCloseMayExecute(NSUInteger expectedGeneration,
                                            NSUInteger currentGeneration,
                                            BOOL disconnected,BOOL enabled,
                                            NSTimeInterval elapsed) {
 return expectedGeneration==currentGeneration && disconnected && enabled &&
        isfinite(elapsed) && elapsed>=DFDisconnectCloseGrace;
}
#endif
