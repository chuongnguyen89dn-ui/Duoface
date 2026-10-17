// DuoFace VisualTest12 recovery: narrow, read-only DuoDash-path activation tracing.
// Intentionally DOES NOT import a DuoDash/Airaw binary, forge a trial state,
// force activation, create scenes, or change any original method's behavior.
// This probe records the failed handoff so a surgical fix can be based on evidence.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dispatch/dispatch.h>
#import <dlfcn.h>
#import <string.h>

typedef void (*DFMessageHook)(Class, SEL, IMP, IMP *);
static DFMessageHook DFHookAPI = NULL;
static NSString *DFRole(void) {
    NSString *bid = [NSBundle mainBundle].bundleIdentifier.lowercaseString;
    if ([bid isEqualToString:@"com.apple.springboard"]) return @"SpringBoard";
    if ([bid isEqualToString:@"com.apple.carplayapp"]) return @"CarPlayApp";
    if ([bid isEqualToString:@"com.duoface.duofaceui"] ||
        [bid isEqualToString:@"com.duonavi.app"]) return @"DuoFaceUI";
    return nil;
}
static id DFBoolGetter(NSString *className, SEL getter) {
    Class cls=NSClassFromString(className);
    if (!cls) return @"NO_CLASS";
    Method method=class_getClassMethod(cls,getter);
    if (!method || strcmp(method_getTypeEncoding(method),"B16@0:8")!=0)
        return @"NO_VERIFIED_BOOL_GETTER";
    BOOL (*send)(id,SEL)=(BOOL (*)(id,SEL))objc_msgSend;
    return @(send(cls,getter));
}
static id DFExistingBridgeActivated(void) {
    Class cls=NSClassFromString(@"CBBridgeManager");
    if (!cls) return @"NO_BRIDGE_CLASS";
    Method owner=class_getClassMethod(cls,NSSelectorFromString(@"sharedInstanceIfExists"));
    if (!owner || strcmp(method_getTypeEncoding(owner),"@16@0:8")!=0)
        return @"NO_VERIFIED_OWNER_GETTER";
    id (*sendId)(id,SEL)=(id (*)(id,SEL))objc_msgSend;
    id manager=sendId(cls,NSSelectorFromString(@"sharedInstanceIfExists"));
    if (!manager) return @"NO_EXISTING_MANAGER";
    SEL sel=NSSelectorFromString(@"activated");
    Method method=class_getInstanceMethod([manager class],sel);
    if (!method || strcmp(method_getTypeEncoding(method),"B16@0:8")!=0)
        return @"NO_VERIFIED_ACTIVATED";
    BOOL (*sendBool)(id,SEL)=(BOOL (*)(id,SEL))objc_msgSend;
    return @(sendBool(manager,sel));
}
static NSString *DFBundleIfSafe(id arg) {
    if (![arg isKindOfClass:NSString.class]) return @"";
    NSString *s=(NSString *)arg;
    if (s.length>255 || s.length<3 || ![s containsString:@"."] ||
        [s rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location!=NSNotFound)
        return @"";
    return s;
}
static void DFRecordNow(NSString *event, NSString *argType, NSString *argBundle,
                        NSNumber *occurredMs) {
    NSString *role=DFRole();
    if (!role) return;
    NSDictionary *row=@{
        @"time_ms":occurredMs ?: @0,
        @"role":role,
        @"event":event ?: @"unknown",
        @"argument_class":argType ?: @"nil",
        @"argument_bundle_if_string":argBundle ?: @"",
        @"bridge_activated":DFExistingBridgeActivated(),
        @"dashboard_policy_active":DFBoolGetter(@"CBBridgeManagerDashboard",
            NSSelectorFromString(@"isDashboardPolicySignalActive")),
        @"duodash_scene_host_class_present":@(NSClassFromString(@"DDz2")!=Nil),
        @"duodash_request_owner_present":@(NSClassFromString(@"CNABSpringBoardObserver")!=Nil),
        @"duodash_app_process_owner_present":@(NSClassFromString(@"CNABUIApp")!=Nil),
        @"duodash_scene_host_selector_present":@(
            class_getInstanceMethod(NSClassFromString(@"DDz2"),
              NSSelectorFromString(@"cnabBuildSceneHostForBid:displaySize:"))!=NULL),
        @"duoface_window_class_present":@(NSClassFromString(@"CBWindow")!=Nil),
        @"external_display_count":@([UIScreen screens].count>0 ?
              [UIScreen screens].count-1 : 0)
    };
    NSError *error=nil;
    NSData *serialized=[NSJSONSerialization dataWithJSONObject:row options:0 error:&error];
    if (!serialized) {
        NSLog(@"[DFDuoDashTrace] JSON error %@",error);
        return;
    }
    NSMutableData *line=[serialized mutableCopy];
    [line appendBytes:"\n" length:1];
    NSString *dir=@"/var/mobile/Documents/DuoFaceDuoDashTrace";
    NSFileManager *fm=[NSFileManager defaultManager];
    BOOL ok=[fm createDirectoryAtPath:dir withIntermediateDirectories:YES
                          attributes:nil error:&error];
    if (ok) {
        NSString *file=[dir stringByAppendingPathComponent:
                        [role stringByAppendingString:@".jsonl"]];
        if (![fm fileExistsAtPath:file]) [fm createFileAtPath:file contents:nil attributes:nil];
        NSFileHandle *handle=[NSFileHandle fileHandleForWritingAtPath:file];
        if (handle) {
            @try {
                [handle seekToEndOfFile];
                [handle writeData:line];
                [handle synchronizeFile];
            } @catch(NSException *ex) {
                NSLog(@"[DFDuoDashTrace] write exception %@",ex.reason);
            } @finally {
                [handle closeFile];
            }
        } else {
            NSLog(@"[DFDuoDashTrace] no file handle %@",file);
        }
    } else {
        NSLog(@"[DFDuoDashTrace] mkdir failed %@",error);
    }
    NSLog(@"[DFDuoDashTrace] %@ %@ activated=%@ policy=%@ ddhost=%@",
          role,event,row[@"bridge_activated"],row[@"dashboard_policy_active"],
          row[@"duodash_scene_host_class_present"]);
}
static void DFRecord(NSString *event, id arg) {
    NSNumber *now=@((long long)([NSDate date].timeIntervalSince1970*1000.0));
    NSString *type=arg?NSStringFromClass([arg class]):@"nil";
    NSString *bundle=DFBundleIfSafe(arg);
    if ([NSThread isMainThread]) {
        DFRecordNow(event,type,bundle,now);
    } else {
        dispatch_async(dispatch_get_main_queue(),^{
            DFRecordNow(event,type,bundle,now);
        });
    }
}
#define DF_TRACE_WRAPPER(KEY, LABEL) \
    static void (*DFOriginal_##KEY)(id,SEL,id)=NULL; \
    static void DFTraced_##KEY(id self,SEL sel,id argument) { \
        DFRecord([@LABEL stringByAppendingString:@".before"],argument); \
        @try { \
            if (DFOriginal_##KEY) DFOriginal_##KEY(self,sel,argument); \
        } @finally { \
            DFRecord([@LABEL stringByAppendingString:@".after"],argument); \
        } \
    }
DF_TRACE_WRAPPER(ReqActivation, "CBBridgeManagerDashboard.requestActivation:")
DF_TRACE_WRAPPER(StartBridging, "CBBridgeManagerDashboard.startBridging:")
DF_TRACE_WRAPPER(PrepareActivation, "CBBridgeManagerDashboard.prepareAndRequestActivation:")
DF_TRACE_WRAPPER(BridgeActivated, "CBBridgeManagerDashboard.bridgeDidActivate:")
DF_TRACE_WRAPPER(RequestState, "CBBridgeManager.requestStateChange:")
DF_TRACE_WRAPPER(LoadNewApp, "CBBridgeManager.loadNewAppFromCurrentRequest:")
DF_TRACE_WRAPPER(CarPlayChanged, "CBBridgeManager.handleCarPlayConnectionChanged:")

static NSMutableSet<NSString *> *DFInstalled(void) {
    static NSMutableSet<NSString *> *installed=nil;
    static dispatch_once_t once;
    dispatch_once(&once,^{installed=[NSMutableSet new];});
    return installed;
}
static void DFInstall(NSString *owner, NSString *selector, IMP replacement, IMP *original) {
    NSString *key=[owner stringByAppendingFormat:@"|%@",selector];
    if ([DFInstalled() containsObject:key]) return;
    Class cls=NSClassFromString(owner);
    if (!cls) return;
    SEL sel=NSSelectorFromString(selector);
    Method method=class_getInstanceMethod(cls,sel);
    if (!method) {
        DFRecord([@"NO_METHOD." stringByAppendingString:key],nil);
        return;
    }
    // All seven target ABIs were catalogued as void(id, SEL, id). Mismatches
    // must fail CLOSED rather than hooking arbitrary private OS signatures.
    const char *abi=method_getTypeEncoding(method);
    if (!abi || strcmp(abi,"v24@0:8@16")!=0) {
        DFRecord([@"ABI_MISMATCH." stringByAppendingString:key],nil);
        return;
    }
    if (!DFHookAPI) {
        DFRecord([@"NO_SUBSTRATE_HOOK_API." stringByAppendingString:key],nil);
        return;
    }
    DFHookAPI(cls,sel,replacement,original);
    if (*original) {
        [DFInstalled() addObject:key];
        DFRecord([@"hook_installed." stringByAppendingString:key],nil);
    } else {
        DFRecord([@"hook_no_original." stringByAppendingString:key],nil);
    }
}
static void DFInstallAvailable(void) {
    if (!DFRole()) return;
    if (!DFHookAPI)
        DFHookAPI=(DFMessageHook)dlsym(RTLD_DEFAULT,"MSHookMessageEx");
    DFInstall(@"CBBridgeManagerDashboard",@"requestActivation:",
      (IMP)DFTraced_ReqActivation,(IMP *)&DFOriginal_ReqActivation);
    DFInstall(@"CBBridgeManagerDashboard",@"startBridging:",
      (IMP)DFTraced_StartBridging,(IMP *)&DFOriginal_StartBridging);
    DFInstall(@"CBBridgeManagerDashboard",@"prepareAndRequestActivation:",
      (IMP)DFTraced_PrepareActivation,(IMP *)&DFOriginal_PrepareActivation);
    DFInstall(@"CBBridgeManagerDashboard",@"bridgeDidActivate:",
      (IMP)DFTraced_BridgeActivated,(IMP *)&DFOriginal_BridgeActivated);
    DFInstall(@"CBBridgeManager",@"requestStateChange:",
      (IMP)DFTraced_RequestState,(IMP *)&DFOriginal_RequestState);
    DFInstall(@"CBBridgeManager",@"loadNewAppFromCurrentRequest:",
      (IMP)DFTraced_LoadNewApp,(IMP *)&DFOriginal_LoadNewApp);
    DFInstall(@"CBBridgeManager",@"handleCarPlayConnectionChanged:",
      (IMP)DFTraced_CarPlayChanged,(IMP *)&DFOriginal_CarPlayChanged);
    DFRecord(@"hook-install-attempt",nil);
}
__attribute__((constructor)) static void DFDuoDashTraceBoot(void) {
    @autoreleasepool {
        if (!DFRole()) return;
        // Delayed, nonblocking installation handles classes appearing after
        // the inject constructor. Every original implementation is preserved.
        dispatch_async(dispatch_get_main_queue(),^{
            DFRecord(@"trace-loaded",nil);
            DFInstallAvailable();
            for (NSNumber *seconds in @[@2,@8,@20]) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                    (int64_t)(seconds.doubleValue*NSEC_PER_SEC)),
                    dispatch_get_main_queue(),^{DFInstallAvailable();});
            }
            NSNotificationCenter *nc=NSNotificationCenter.defaultCenter;
            [nc addObserverForName:UIScreenDidConnectNotification
                            object:nil queue:NSOperationQueue.mainQueue
                        usingBlock:^(__unused NSNotification *n){
                DFRecord(@"UIScreenDidConnect",nil); DFInstallAvailable();
            }];
            [nc addObserverForName:UIScreenDidDisconnectNotification
                            object:nil queue:NSOperationQueue.mainQueue
                        usingBlock:^(__unused NSNotification *n){
                DFRecord(@"UIScreenDidDisconnect",nil);
            }];
            [nc addObserverForName:UIApplicationDidBecomeActiveNotification
                            object:nil queue:NSOperationQueue.mainQueue
                        usingBlock:^(__unused NSNotification *n){
                DFRecord(@"UIApplicationDidBecomeActive",nil); DFInstallAvailable();
            }];
        });
    }
}
