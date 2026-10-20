// Dedicated SpringBoard-only DuoFace Test command receiver.
// No app discovery changes, no UI window, no unsolicited enable.
// The app's explicit 45-second confirmation is the ONLY start path.
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <dispatch/dispatch.h>
#import <fcntl.h>
#import <sys/stat.h>
#import <unistd.h>
static NSString *const DFBase=@"/var/mobile/Library/Preferences/com.duoface.mytweak.v1bc.plist";
static NSString *const DFBridge=@"/var/mobile/Library/Preferences/com.duoface.mytweak.carplay-bridge.plist";
static NSString *const DFLease=@"/var/mobile/Library/Preferences/com.duoface.testapp.lease.plist";
static NSString *const DFLog=@"/var/mobile/Library/Logs/DuoFaceTestApp.log";
static NSString *const DFStart=@"com.duoface.testapp.cmd.start";
static NSString *const DFStop=@"com.duoface.testapp.cmd.stop";
static NSString *const DFStatus=@"com.duoface.testapp.cmd.status";
static NSString *const DFAckEnabled=@"com.duoface.testapp.ack.started";
static NSString *const DFAckStopped=@"com.duoface.testapp.ack.stopped";
static NSString *const DFAckMissing=@"com.duoface.testapp.ack.base-missing";
static NSString *const DFAckReady=@"com.duoface.testapp.ack.ready";
static NSString *const DFAckExpired=@"com.duoface.testapp.ack.expired";
static NSString *const DFError=@"com.duoface.testapp.ack.error";
static NSTimer *DFTimer;
static BOOL DFTestActive;

static void DFPost(NSString *name) {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
         (__bridge CFStringRef)name,NULL,NULL,YES);
}
static void DFWriteLog(NSString *line) {
    NSString *s=[NSString stringWithFormat:@"[DuoFaceTestApp] %@ %@\n",NSDate.date,line];
    NSLog(@"%@",s);
    int fd=open(DFLog.UTF8String,O_WRONLY|O_CREAT|O_APPEND,0644);
    if(fd>=0){NSData *d=[s dataUsingEncoding:NSUTF8StringEncoding];
        (void)write(fd,d.bytes,d.length);close(fd);}
}
static BOOL DFWritePrefs(NSString *path,NSDictionary *prefs) {
    if(!path || !prefs)return NO;
    NSDictionary *attrs=[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    if(attrs && ![attrs[NSFileType] isEqualToString:NSFileTypeRegular])return NO;
    BOOL ok=[prefs writeToFile:path atomically:YES];
    if(ok)chmod(path.UTF8String,0644);
    return ok;
}
static NSDictionary *DFRead(NSString *path) {
    id obj=[NSDictionary dictionaryWithContentsOfFile:path];
    return [obj isKindOfClass:NSDictionary.class]?obj:nil;
}
static void DFRestore(BOOL expired) {
    [DFTimer invalidate];DFTimer=nil;
    NSDictionary *state=DFRead(DFLease);
    if(state) {
        // Preserve all other stable prefs, only restore the one base bit.
        NSMutableDictionary *base=[DFRead(DFBase) mutableCopy]?:[NSMutableDictionary dictionary];
        id former=state[@"BaseEnabled"];
        if([state[@"BaseHadKey"] boolValue] && [former isKindOfClass:NSNumber.class])
            base[@"Enabled"]=former;
        else [base removeObjectForKey:@"Enabled"];
        DFWritePrefs(DFBase,base);
    }
    NSMutableDictionary *bridge=[DFRead(DFBridge) mutableCopy]?:[NSMutableDictionary dictionary];
    bridge[@"Enabled"]=@NO;
    bridge[@"NativeSidebarTrial"]=@NO; // never reactivate native bar trial on exit
    DFWritePrefs(DFBridge,bridge);
    [[NSFileManager defaultManager] removeItemAtPath:DFLease error:nil];
    DFTestActive=NO;
    DFWriteLog(expired?@"TIMEOUT 45s, prefs restored":@"STOP: native trial off, base flag restored");
    DFPost(expired?DFAckExpired:DFAckStopped);
}
static void DFStartTest(void) {
    if(DFTestActive) { DFPost(DFAckEnabled);return; }
    NSDictionary *original=DFRead(DFBase);
    if(!original) { DFWriteLog(@"REJECT missing original MyTweak V1BC base prefs");DFPost(DFAckMissing);return; }
    if([[NSFileManager defaultManager] fileExistsAtPath:DFLease]){
        // Stale incomplete prior trial; fail closed before accepting new trial.
        DFRestore(NO);DFPost(DFError);return;
    }
    NSMutableDictionary *base=[original mutableCopy];
    NSMutableDictionary *bridge=[DFRead(DFBridge) mutableCopy]?:[NSMutableDictionary dictionary];
    NSNumber *priorBase=[original[@"Enabled"] isKindOfClass:NSNumber.class]?original[@"Enabled"]:nil;
    NSDictionary *state=@{@"Started":@(NSDate.date.timeIntervalSince1970),
                          @"Expires":@(NSDate.date.timeIntervalSince1970+45),
                          @"BaseHadKey":@(priorBase!=nil),
                          @"BaseEnabled":priorBase?:@NO};
    if(![state writeToFile:DFLease atomically:YES]){DFPost(DFError);return;}
    base[@"Enabled"]=@YES;
    bridge[@"Enabled"]=@YES;
    bridge[@"NativeSidebarTrial"]=@YES;
    if(!DFWritePrefs(DFBase,base) || !DFWritePrefs(DFBridge,bridge)){
        DFRestore(NO);DFPost(DFError);return;
    }
    DFTestActive=YES;
    DFTimer=[NSTimer scheduledTimerWithTimeInterval:45 target:[NSBlockOperation blockOperationWithBlock:^{
        DFRestore(YES);
    }] selector:@selector(main) userInfo:nil repeats:NO];
    DFWriteLog(@"START 45s opt-in bridge/base; preserving prior BaseEnabled");
    DFPost(DFAckEnabled);
}
static void DFNotify(CFNotificationCenterRef c,void *observer,CFStringRef name,
                     const void *object,CFDictionaryRef userInfo){
    NSString *event=(__bridge NSString *)name;
    dispatch_async(dispatch_get_main_queue(), ^{
        if([event isEqualToString:DFStart])DFStartTest();
        else if([event isEqualToString:DFStop])DFRestore(NO);
        else if([event isEqualToString:DFStatus]) {
            DFWriteLog(@"PING from DuoFace Test app");
            DFPost(DFTestActive?DFAckEnabled:DFAckReady);
        }
    });
}
__attribute__((constructor)) static void DFLoad(void) {
    @autoreleasepool {
        if(![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"])return;
        dispatch_async(dispatch_get_main_queue(), ^{
            // Reboot/respring while test was active: restore fail-closed.
            if([[NSFileManager defaultManager] fileExistsAtPath:DFLease])DFRestore(YES);
            for(NSString *event in @[DFStart,DFStop,DFStatus])
                CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                    NULL,DFNotify,(__bridge CFStringRef)event,NULL,
                    CFNotificationSuspensionBehaviorDeliverImmediately);
            DFWriteLog(@"SpringBoard command receiver online (no LS hooks)");
        });
    }
}
