// DuoFace Diagnostic3 — iPhone X only, no UI mutation, no forced activation.
// Read-only invocation tracing, signature-guarded hooks. Deployment is optional QA.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>
#import <sys/stat.h>
#import <unistd.h>
#import <stdint.h>
#import <dispatch/dispatch.h>

static NSString *const kLogRoot=@"/var/mobile/Library/Logs";
static NSString *sLogPath;
static NSString *sProcessName;
static NSString *sBundleID;
static dispatch_source_t sTimer;
static unsigned long sPolls=0;
// Weakly observe the already-existing Dashboard manager ONLY after a real intercepted call.
static __weak id sObservedDashboardManager=nil;
static BOOL sLoggedWriterError=NO;

static NSString *DFClass(id obj) {
    return obj ? NSStringFromClass([obj class]) : @"nil";
}
static id DFCallObj(id obj, const char *selector) {
    if(!obj)return nil;
    SEL sel=sel_registerName(selector);
    if(![obj respondsToSelector:sel])return nil;
    return ((id (*)(id, SEL))objc_msgSend)(obj,sel);
}
static NSNumber *DFCallBool(id obj, const char *selector) {
    if(!obj)return nil;
    SEL sel=sel_registerName(selector);
    if(![obj respondsToSelector:sel])return nil;
    Method m=class_getInstanceMethod(object_getClass(obj),sel);
    if(!m)m=class_getInstanceMethod([obj class],sel);
    if(!m)return nil;
    char buf[16]={0}; method_getReturnType(m,buf,sizeof(buf));
    if(!strchr("BcCiIsSlLqQ",buf[0]))return nil;
    return @(((BOOL (*)(id,SEL))objc_msgSend)(obj,sel));
}
static NSString *DFBoolText(NSNumber *v) {return v ? (v.boolValue?@"true":@"false") : @"unknown";}
static NSDictionary *DFSnapshot(void) {
    Class sb=NSClassFromString(@"CBBridgeManager");
    Class win=NSClassFromString(@"CBWindow");
    id manager=DFCallObj(sb,"sharedInstanceIfExists");
    id dashManager=sObservedDashboardManager;
    id window=DFCallObj(manager,"window");
    id active=DFCallObj(win,"activeCarPlayWindow");
    id app=DFCallObj(manager,"currentApp");
    NSNumber *a=DFCallBool(manager,"activated");
    NSNumber *p=DFCallBool(dashManager,"pending");
    NSNumber *da=DFCallBool(dashManager,"activated");
    return @{
      @"sb_manager_class":DFClass(manager),
      @"dashboard_manager_class":DFClass(dashManager),
      @"manager_activated":DFBoolText(a),
      @"dashboard_pending":DFBoolText(p),
      @"dashboard_activated":DFBoolText(da),
      @"window_class":DFClass(window),
      @"active_window_class":DFClass(active),
      @"current_app_class":DFClass(app),
      @"screen_count":@([UIScreen screens].count),
      @"external_screen_present":@([UIScreen screens].count>1)
    };
}
static void DFWrite(NSString *event, NSDictionary *details) {
    @autoreleasepool {
        if(!sLogPath)return;
        NSMutableDictionary *payload=[NSMutableDictionary dictionaryWithDictionary:@{
           @"time_unix":@([[NSDate date] timeIntervalSince1970]),
           @"pid":@(getpid()),
           @"process":sProcessName?:@"unknown",
           @"bundle":sBundleID?:@"unknown",
           @"event":event?:@"nil",
           @"version":@"diag3"
        }];
        if(details)payload[@"details"]=details;
        NSData *data=[NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
        if(!data)return;
        @synchronized([NSFileManager defaultManager]) {
            const char *filename=sLogPath.fileSystemRepresentation;
            struct stat st;
            if(stat(filename,&st)==0 && st.st_size>3*1024*1024) {
                NSString *previous=[sLogPath stringByAppendingString:@".previous"];
                unlink(previous.fileSystemRepresentation);
                rename(filename,previous.fileSystemRepresentation);
            }
            FILE *fp=fopen(filename,"a");
            if(!fp) {
                if(!sLoggedWriterError) {
                    sLoggedWriterError=YES;
                    NSLog(@"[DuoFaceDiagnostic3] log write unavailable process=%@ path=%@",sProcessName,sLogPath);
                }
                return;
            }
            fwrite(data.bytes,1,data.length,fp);
            fputc('\n',fp);
            fclose(fp);
        }
    }
}

static void DFRecordReceiver(id receiver) {
    Class dc=NSClassFromString(@"CBBridgeManagerDashboard");
    if(dc && receiver && [receiver isKindOfClass:dc])sObservedDashboardManager=receiver;
}

// Forward exactly the original GP argument register(s); do NOT dereference app arguments.
// Only install when Objective-C runtime confirms void return and 0/1 GP-register arguments.
typedef void (*DFHookMessageExType)(Class,SEL,IMP,IMP*);
static DFHookMessageExType sMSHook=NULL;
static BOOL DFInstall(const char *cls,const char *name,int argc,IMP replacement,IMP *original) {
    Class c=objc_getClass(cls);
    if(!c)return NO;
    SEL selector=sel_registerName(name);
    Method m=class_getInstanceMethod(c,selector);
    if(!m)return NO;
    char ret[32]={0};
    method_getReturnType(m,ret,sizeof(ret));
    unsigned n=method_getNumberOfArguments(m);
    NSString *reason=@"ok";
    if(ret[0]!='v'||ret[1]!=0||n!=(unsigned)(argc+2))reason=@"unexpected_return_or_arity";
    if([reason isEqualToString:@"ok"]) {
        for(int j=2;j<argc+2;j++) {
            char t[32]={0};
            method_getArgumentType(m,j,t,sizeof(t));
            // integer, pointer, object and block use GPR under arm64; never log argument objects.
            if(!strchr("@#:^*BcCsSiIlLqQ",t[0])) {reason=@"non_gp_argument";break;}
        }
    }
    if(![reason isEqualToString:@"ok"]) {
        DFWrite(@"HOOK_SKIPPED_ABI",@{@"class":@(cls),@"selector":@(name),@"encoding":@(method_getTypeEncoding(m)),@"reason":reason});
        return NO;
    }
    if(!sMSHook) {
        DFWrite(@"HOOK_UNAVAILABLE",@{@"class":@(cls),@"selector":@(name)});
        return NO;
    }
    sMSHook(c,selector,replacement,original);
    DFWrite(@"HOOK_INSTALLED",@{@"class":@(cls),@"selector":@(name),@"encoding":@(method_getTypeEncoding(m))});
    return YES;
}

#define ONE_HOOK(NAME,CLASS,SELECTOR) \
 static void (*orig_##NAME)(id,SEL,uintptr_t)=NULL; \
 static void probe_##NAME(id self,SEL cmd,uintptr_t arg) { \
     DFRecordReceiver(self); \
     DFWrite(@"ENTER_" #NAME,DFSnapshot()); \
     if(orig_##NAME) orig_##NAME(self,cmd,arg); \
     DFWrite(@"EXIT_" #NAME,DFSnapshot()); \
 } \
 static BOOL installed_##NAME=NO; \
 static void install_##NAME(void){ \
     if(!installed_##NAME)installed_##NAME=DFInstall(CLASS,SELECTOR,1,(IMP)probe_##NAME,(IMP*)&orig_##NAME); \
 }
#define ZERO_HOOK(NAME,CLASS,SELECTOR) \
 static void (*orig_##NAME)(id,SEL)=NULL; \
 static void probe_##NAME(id self,SEL cmd) { \
     DFWrite(@"ENTER_" #NAME,DFSnapshot()); \
     if(orig_##NAME)orig_##NAME(self,cmd); \
     DFWrite(@"EXIT_" #NAME,DFSnapshot()); \
 } \
 static BOOL installed_##NAME=NO; \
 static void install_##NAME(void){ \
     if(!installed_##NAME)installed_##NAME=DFInstall(CLASS,SELECTOR,0,(IMP)probe_##NAME,(IMP*)&orig_##NAME); \
 }

ONE_HOOK(DashIconTap,"CBBridgeManagerDashboard","handleDockIconTap:")
ONE_HOOK(DashRequestActivation,"CBBridgeManagerDashboard","requestActivation:")
ONE_HOOK(DashPrepareActivation,"CBBridgeManagerDashboard","prepareAndRequestActivation:")
ONE_HOOK(DashBridgeActivated,"CBBridgeManagerDashboard","bridgeDidActivate:")
ONE_HOOK(DashStateChanged,"CBBridgeManagerDashboard","handleSBStateChange:")
ONE_HOOK(SBAppRequest,"CBBridgeManager","receivedAppRequestNotification:")
ONE_HOOK(SBDockTap,"CBBridgeManager","receivedDockTapNotification:")
ONE_HOOK(SBStateChange,"CBBridgeManager","requestStateChange:")
ONE_HOOK(SBSetWindow,"CBBridgeManager","setWindow:")
ZERO_HOOK(WindowCreate,"CBWindow","createWindows")
ZERO_HOOK(WindowShow,"CBWindow","show")
ZERO_HOOK(WindowDestroy,"CBWindow","destroyWindows")


/*
 * Passive observation of DuoFace's class-level CarPlay policy decision.
 * Call original exactly once; never change its return value or modify state.
 */
static NSString *DFTraceIdentifier(id arg) {
    if(!arg)return @"nil";
    NSString *s=nil;
    if([arg isKindOfClass:NSString.class])s=(NSString *)arg;
    else {
        SEL b=sel_registerName("bundleIdentifier");
        if([arg respondsToSelector:b]) {
            id value=((id (*)(id,SEL))objc_msgSend)(arg,b);
            if([value isKindOfClass:NSString.class])s=value;
        }
    }
    if(!s)return [NSString stringWithFormat:@"<%@>",DFClass(arg)];
    if(s.length==0 || s.length>120)return @"<redacted>";
    NSCharacterSet *allowed=[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._-"];
    if([s rangeOfCharacterFromSet:allowed.invertedSet].location!=NSNotFound)return @"<redacted>";
    return s;
}
static BOOL DFTracePolicyHook(const char *methodName, BOOL hasArg, IMP replacement, IMP *original) {
    Class cls=objc_getClass("CBBridgeManagerDashboard");
    if(!cls)return NO;
    SEL sel=sel_registerName(methodName);
    Method m=class_getClassMethod(cls,sel);
    if(!m)return NO;
    char ret[16]={0},argType[32]={0};
    method_getReturnType(m,ret,sizeof(ret));
    unsigned argc=method_getNumberOfArguments(m);
    if(hasArg && argc==3)method_getArgumentType(m,2,argType,sizeof(argType));
    if(!sMSHook || (ret[0]!='B' && ret[0]!='c') || ret[1]!=0 ||
        argc!=(hasArg?3u:2u) || (hasArg && argType[0]!='@')) {
        DFWrite(@"POLICY_HOOK_SKIPPED_ABI",@{@"method":@(methodName),
           @"encoding":@(method_getTypeEncoding(m)),@"hasHookAPI":@(sMSHook!=NULL)});
        return NO;
    }
    Class meta=object_getClass((id)cls);
    sMSHook(meta,sel,replacement,original);
    DFWrite(@"POLICY_HOOK_INSTALLED",@{@"method":@(methodName),
        @"encoding":@(method_getTypeEncoding(m))});
    return YES;
}
#define DF_POLICY_ONE(NAME,SELECTOR) \
static BOOL (*sOrig_##NAME)(id,SEL,id)=NULL; \
static BOOL DFPolicy_##NAME(id owner,SEL sel,id arg) { \
    BOOL result=sOrig_##NAME ? sOrig_##NAME(owner,sel,arg) : NO; \
    DFWrite(@"POLICY_" #NAME,@{@"app":DFTraceIdentifier(arg),@"result":@(result), \
        @"snapshot":DFSnapshot()}); \
    return result; \
} \
static BOOL sHooked_##NAME=NO; \
static void DFInstall_##NAME(void) { \
    if(!sHooked_##NAME)sHooked_##NAME=DFTracePolicyHook(SELECTOR,YES,(IMP)DFPolicy_##NAME,(IMP *)&sOrig_##NAME); \
}
#define DF_POLICY_ZERO(NAME,SELECTOR) \
static BOOL (*sOrig_##NAME)(id,SEL)=NULL; \
static BOOL DFPolicy_##NAME(id owner,SEL sel) { \
    BOOL result=sOrig_##NAME ? sOrig_##NAME(owner,sel) : NO; \
    DFWrite(@"POLICY_" #NAME,@{@"result":@(result),@"snapshot":DFSnapshot()}); \
    return result; \
} \
static BOOL sHooked_##NAME=NO; \
static void DFInstall_##NAME(void) { \
    if(!sHooked_##NAME)sHooked_##NAME=DFTracePolicyHook(SELECTOR,NO,(IMP)DFPolicy_##NAME,(IMP *)&sOrig_##NAME); \
}
DF_POLICY_ONE(IsOfficialApp,"isOfficialApp:")
DF_POLICY_ONE(IsBridgedApp,"isBridgedApp:")
DF_POLICY_ONE(ShouldInterceptLaunch,"shouldInterceptLaunchForApp:")
DF_POLICY_ZERO(PolicySignalActive,"isDashboardPolicySignalActive")

static void DFTryInstall(void) {
    install_DashIconTap();
    install_DashRequestActivation();
    install_DashPrepareActivation();
    install_DashBridgeActivated();
    install_DashStateChanged();
    install_SBAppRequest();
    install_SBDockTap();
    install_SBStateChange();
    install_SBSetWindow();
    install_WindowCreate();
    install_WindowShow();
    install_WindowDestroy();
    DFInstall_IsOfficialApp();
    DFInstall_IsBridgedApp();
    DFInstall_ShouldInterceptLaunch();
    DFInstall_PolicySignalActive();
}
static void DFOnUIKitScreen(NSNotification *notification) {
    DFWrite(@"SCREEN_EVENT",@{@"name":notification.name?:@"nil",@"snapshot":DFSnapshot()});
}
static void DFStart(void) {
    if(!NSThread.isMainThread)return;
    sProcessName=NSProcessInfo.processInfo.processName?:@"unknown";
    sBundleID=NSBundle.mainBundle.bundleIdentifier?:@"unknown";
    BOOL spring=[sProcessName isEqualToString:@"SpringBoard"];
    BOOL carplay=[sProcessName isEqualToString:@"CarPlayApp"]||
      [sProcessName isEqualToString:@"CarPlay"]||
      [sProcessName isEqualToString:@"DashBoard"]||
      [sBundleID hasPrefix:@"com.apple.carplay"]||
      [sBundleID isEqualToString:@"com.apple.CarPlayApp"];
    if(!spring&&!carplay)return;
    [NSFileManager.defaultManager createDirectoryAtPath:kLogRoot
        withIntermediateDirectories:YES attributes:nil error:nil];
    sLogPath=[kLogRoot stringByAppendingPathComponent:spring?
        @"DuoFaceDiagnostic3-SpringBoard.jsonl":@"DuoFaceDiagnostic3-CarPlay.jsonl"];
    sMSHook=(DFHookMessageExType)dlsym(RTLD_DEFAULT,"MSHookMessageEx");
    DFWrite(@"LOADED",@{@"hook_api_present":@(sMSHook!=NULL),@"snapshot":DFSnapshot()});
    for(NSString *name in @[UIScreenDidConnectNotification,UIScreenDidDisconnectNotification,UIScreenModeDidChangeNotification]) {
       [NSNotificationCenter.defaultCenter addObserverForName:name object:nil queue:NSOperationQueue.mainQueue
          usingBlock:^(NSNotification *n){DFOnUIKitScreen(n);}];
    }
    DFTryInstall();
    sTimer=dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_get_main_queue());
    dispatch_source_set_timer(sTimer,dispatch_time(DISPATCH_TIME_NOW,2*NSEC_PER_SEC),
        2*NSEC_PER_SEC,200*NSEC_PER_MSEC);
    dispatch_source_set_event_handler(sTimer,^{
        sPolls++;
        // Retry hooks if CarPlay initializes classes after tweak injection.
        if(sPolls%3==0)DFTryInstall();
        if(sPolls%5==0)DFWrite(@"HEARTBEAT",@{@"poll":@(sPolls),@"snapshot":DFSnapshot()});
    });
    dispatch_resume(sTimer);
}
__attribute__((constructor))
static void DFDiagnostic3Init(void) {
    dispatch_async(dispatch_get_main_queue(),^{DFStart();});
}
