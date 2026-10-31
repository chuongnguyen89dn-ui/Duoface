// QA143: accept a CarPlay Home click only after the genuine DuoFace CPTemplate
// scene has become foreground and existing SpringBoard chrome is live.
#import <Foundation/Foundation.h>
#import <fcntl.h>
#import <unistd.h>
#import "DFNative12Chrome.h"
#import "DFHome140Consent.h"
#import "DFEnabledAppsPolicy.h"
static NSString *const DF143RequestPath=@"/var/mobile/Library/Preferences/com.duoface.nativehost.home143-request.plist";
static NSString *const DF143AckPath=@"/var/mobile/Library/Preferences/com.duoface.nativehost.home143-ack.plist";
static NSString *DF143LastConsumed;
static void DF143ReceiverLog(NSString *msg) {
 NSString *line=[NSString stringWithFormat:@"[DFHome143SB] time=%.3f %@\n",
                    NSDate.date.timeIntervalSince1970,msg];
 int fd=open("/var/mobile/Library/Logs/DuoFaceHomeLaunch143.log",O_CREAT|O_WRONLY|O_APPEND,0644);
 if(fd>=0){NSData *bytes=[line dataUsingEncoding:NSUTF8StringEncoding];
   if(bytes.length)(void)write(fd,bytes.bytes,bytes.length);close(fd);}
}
BOOL DFHome143ConsumeRequest(DFNative12Chrome *owner,NSString *activeSession) {
 if(![NSThread isMainThread] || !owner || !activeSession.length)return NO;
 NSDictionary *p=[NSDictionary dictionaryWithContentsOfFile:DF143RequestPath];
 if(![p isKindOfClass:NSDictionary.class])return NO;
 NSString *rid=p[@"ID"],*bundle=p[@"BundleID"],*host=p[@"HostBundleID"];
 NSNumber *stamp=p[@"Timestamp"];
 if(![rid isKindOfClass:NSString.class] || rid.length<32 ||
    ![p[@"Version"] isEqual:@1] || ![stamp isKindOfClass:NSNumber.class] ||
    ![host isEqualToString:@"com.duoface.native.scenehost"] ||
    ![p[@"Origin"] isEqualToString:@"CarPlayHomeTap143"] ||
    ![bundle isKindOfClass:NSString.class])return NO;
 NSTimeInterval age=NSDate.date.timeIntervalSince1970-stamp.doubleValue;
 if(age<0 || age>15.0 || [rid isEqualToString:DF143LastConsumed]) {
    [[NSFileManager defaultManager] removeItemAtPath:DF143RequestPath error:nil];
    DF143ReceiverLog(@"expired-or-replayed-request-denied");
    return NO;
 }
 if(!DFHome140Enabled() ||
    !DFPickerAllowsApp(bundle,DFConfiguredEnabledAppIDs())) {
    [[NSFileManager defaultManager] removeItemAtPath:DF143RequestPath error:nil];
    DF143ReceiverLog(@"request-no-longer-enabled-denied");
    return NO;
 }
 DF143LastConsumed=[rid copy];
 // Immediately consume one-time intent, so a reconnect cannot replay it.
 [[NSFileManager defaultManager] removeItemAtPath:DF143RequestPath error:nil];
 BOOL accepted=[owner openSelectedHomeBundleID143:bundle];
 NSDictionary *ack=@{@"Version":@1,@"RequestID":rid,@"BundleID":bundle,
     @"Session":activeSession,@"Accepted":@(accepted),
     @"Timestamp":@(NSDate.date.timeIntervalSince1970),
     @"Outcome":accepted?@"scene-requested-not-yet-ready":@"chrome-preflight-rejected"};
 (void)[ack writeToFile:DF143AckPath atomically:YES];
 DF143ReceiverLog([NSString stringWithFormat:
       @"request-consumed bundle=%@ accepted=%d scene-ready-not-claimed",
       bundle,accepted]);
 return accepted;
}
