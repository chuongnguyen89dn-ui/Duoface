// Independent, opt-in SpringBoard half of DuoFace's iOS16 CarPlay app roster.
// One owned bundle only. No private entitlement DB writes or external binaries.
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>
#import <fcntl.h>
#import <unistd.h>
#import <string.h>
typedef void (*DFSBHook)(Class,SEL,IMP,IMP *);
static NSString *const kID=@"com.duoface.native.scenehost";
static NSString *const kPrefs=@"/var/mobile/Library/Preferences/com.duoface.firstparty-admission.plist";
static const char *kKill="/var/mobile/Library/Preferences/.duoface-firstparty-admission-disable";
static id (*origBulk)(id,SEL,id)=NULL;
static BOOL (*origBool)(id,SEL,id)=NULL;
static NSMapTable *tagged=nil;
static NSLock *tagLock=nil;
static volatile int firstBulkLog=0;
static volatile int firstFlagLog=0;
// Tiny bounded first-party-only events. No app IDs, no per-query hot-path I/O.
static void rosterLog(const char *message) {
    int fd=open("/var/mobile/Library/Logs/DuoFaceFirstPartySpringBoard.log",
                O_WRONLY|O_APPEND|O_CREAT,0644);
    if(fd>=0){(void)write(fd,message,strlen(message));close(fd);}
}
static BOOL armed=NO;
static BOOL consent(void) {
    if(access(kKill,F_OK)==0 ||
       ![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"] ||
       NSProcessInfo.processInfo.operatingSystemVersion.majorVersion!=16)return NO;
    NSDictionary *p=[NSDictionary dictionaryWithContentsOfFile:kPrefs];
    return [p[@"Enabled"] isKindOfClass:NSNumber.class] && [p[@"Enabled"] boolValue] &&
      [p[@"RiskAcknowledged"] isKindOfClass:NSNumber.class] && [p[@"RiskAcknowledged"] boolValue] &&
      [p[@"HostBundleID"] isKindOfClass:NSString.class] && [p[@"HostBundleID"] isEqualToString:kID];
}
static BOOL wanted(id k) {
    return [k isKindOfClass:NSString.class] &&
       ([k isEqualToString:@"SBStarkCapable"]||[k isEqualToString:@"CARCapableApp"]);
}
static BOOL owned(id proxy) {
    @try {
      if(![proxy respondsToSelector:@selector(bundleIdentifier)])return NO;
      id b=((id(*)(id,SEL))objc_msgSend)(proxy,@selector(bundleIdentifier));
      return [b isKindOfClass:NSString.class] && [b isEqualToString:kID];
    }@catch(NSException *e){(void)e;return NO;}
}
static id bulkHook(id proxy,SEL cmd,id keys) {
    if(!origBulk)return nil;
    id real=origBulk(proxy,cmd,keys);
    if(!real||!consent())return real;
    @try {
      if(!owned(proxy)||![keys isKindOfClass:NSArray.class])return real;
      BOOL hasFlag=NO;
      for(id k in (NSArray *)keys)if(wanted(k)){hasFlag=YES;break;}
      if(!hasFlag)return real;
      Class cache=NSClassFromString(@"LSBundleInfoCachedValues");
      if(!cache||![real isKindOfClass:cache])return real;
      [tagLock lock];[tagged setObject:kID forKey:real];[tagLock unlock];
      if(__sync_bool_compare_and_swap(&firstBulkLog,0,1))
          rosterLog("firstparty-bulk-cache-tagged; icon-not-yet-proven\n");
    }@catch(NSException *e){(void)e;}
    return real; // preserve private LS runtime class and original object
}
static BOOL boolHook(id obj,SEL cmd,id key) {
    if(!origBool)return NO;
    BOOL real=origBool(obj,cmd,key);
    if(real||!consent()||!wanted(key))return real;
    @try {
      [tagLock lock];BOOL match=[[tagged objectForKey:obj] isEqualToString:kID];[tagLock unlock];
      if(match && __sync_bool_compare_and_swap(&firstFlagLog,0,1))
          rosterLog("firstparty-flag-queried; icon-not-yet-proven\n");
      return match ? YES : real;
    }@catch(NSException *e){(void)e;return real;}
}
static BOOL abi(Class cls,SEL sel,const char *want) {
    Method m=cls?class_getInstanceMethod(cls,sel):NULL;
    const char *value=m?method_getTypeEncoding(m):NULL;
    return value && strcmp(value,want)==0;
}
static void arm(void) {
    if(armed||!consent())return;
    Class proxy=NSClassFromString(@"LSBundleProxy");
    Class cache=NSClassFromString(@"LSBundleInfoCachedValues");
    SEL bulk=sel_registerName("entitlementValuesForKeys:");
    SEL boolean=sel_registerName("boolForKey:");
    if(!abi(proxy,bulk,"@24@0:8@16")||!abi(cache,boolean,"B24@0:8@16")){
        rosterLog("springboard-roster-ABI-not-matched; no-hooks\n");
        return;
    }
    DFSBHook hook=(DFSBHook)dlsym(RTLD_DEFAULT,"MSHookMessageEx");
    if(!hook){rosterLog("springboard-hook-API-unavailable; no-hooks\n");return;}
    if(!tagged)tagged=[NSMapTable weakToStrongObjectsMapTable];
    if(!tagLock)tagLock=[NSLock new];
    hook(proxy,bulk,(IMP)bulkHook,(IMP *)&origBulk);
    if(!origBulk)return;
    hook(cache,boolean,(IMP)boolHook,(IMP *)&origBool);
    if(!origBool)return;
    armed=YES;
    rosterLog("springboard-firstparty-roster-hooks-armed; icon-not-yet-proven\n");
    NSLog(@"[DuoFaceRosterSB] original cached-value path armed; icon not proven");
}
static void refresh(CFNotificationCenterRef c,void *o,CFStringRef n,
                    const void *object,CFDictionaryRef info) {
    (void)c;(void)o;(void)n;(void)object;(void)info;
    dispatch_async(dispatch_get_main_queue(), ^{arm();});
}
__attribute__((constructor))static void start(void) {
    @autoreleasepool {
      if(![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"])return;
      CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,refresh,CFSTR("com.duoface.firstparty-admission.refresh"),NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately);
      arm(); // early initial roster, no automatic process restart
    }
}
