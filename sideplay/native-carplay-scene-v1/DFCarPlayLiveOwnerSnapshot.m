// Opt-in, standalone CarPlay process diagnostic. READ-ONLY: no scene creation,
// no app activation, no view hierarchy mutation, no hooks or private setters.
#import "DFCarPlayNativeSceneIdentity.h"
#import "DFCarPlayNativeSceneTimeline.h"
// Observational state only; never retains UIView/FBScene or manipulates a scene.
static NSDictionary *DFCarPlayPreviousTimeline = nil;
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <fcntl.h>
#import <unistd.h>
#import <sys/stat.h>
#import <string.h>
#import <errno.h>
#import <stdlib.h>

static NSString *const DFMapOwnerLog = @"/var/mobile/Library/Logs/DuoFaceCarPlayOwnerSnapshot.log";
static NSString *DFClassName(id value) {
    return value ? NSStringFromClass([value class]) : @"nil";
}
static NSString *DFRect(CGRect value) {
    return CGRectIsNull(value) ? @"null" : NSStringFromCGRect(value);
}
static NSString *DFPtr(id value) {
    return value ? [NSString stringWithFormat:@"%p",value] : @"nil";
}
// Only invoke a zero-argument, OBJECT-returning getter that exists at runtime.
// Never use KVC, dynamically guessed ivar offsets, or scene lifecycle methods.
static NSString *DFReadHostView(id vc, NSMutableDictionary *record) {
    SEL getter=NSSelectorFromString(@"sceneHostView");
    Method method=class_getInstanceMethod(object_getClass(vc),getter);
    if (!method) return @"selector-missing";
    if (method_getNumberOfArguments(method)!=2) return @"unsupported-arguments";
    char *ret=method_copyReturnType(method);
    BOOL objectResult=(ret && ret[0]=='@');
    if(ret)free(ret);
    if(!objectResult)return @"non-object-return";
    id host=nil;
    @try {
        host=((id (*)(id,SEL))objc_msgSend)(vc,getter);
    } @catch(NSException *e) {
        record[@"sceneHostViewException"]=e.name?:@"unknown";
        return @"exception";
    }
    if(!host)return @"nil";
    record[@"sceneHostViewClass"]=DFClassName(host);
    record[@"sceneHostViewPointer"]=DFPtr(host);
    if([host isKindOfClass:UIView.class]){
        UIView *v=(UIView *)host;
        record[@"sceneHostViewBounds"]=DFRect(v.bounds);
        record[@"sceneHostViewFrame"]=DFRect(v.frame);
        record[@"sceneHostViewWindow"]=DFPtr(v.window);
        UIWindowScene *ws=v.window.windowScene;
        record[@"sceneHostViewScene"]=ws.session.persistentIdentifier?:@"nil";
        return @"present-UIView";
    }
    return @"present-non-UIView";
}
// Identity-only observation for the live Dashboard app-scene controller.
// Only invoke verified zero-argument OBJECT getters; no scene lifecycle calls.
static id DFGetOwnerObject(id receiver, NSString *name, NSMutableDictionary *log, NSString *key) {
    SEL sel=NSSelectorFromString(name);
    Method m=class_getInstanceMethod(object_getClass(receiver),sel);
    if(!m){log[[key stringByAppendingString:@"Status"]]=@"absent";return nil;}
    if(method_getNumberOfArguments(m)!=2){
        log[[key stringByAppendingString:@"Status"]]=@"unsupported-abi";return nil;
    }
    char *type=method_copyReturnType(m);
    BOOL isObject=(type && type[0]=='@');
    if(type)free(type);
    if(!isObject){log[[key stringByAppendingString:@"Status"]]=@"unsupported-abi";return nil;}
    @try{
        id value=((id (*)(id,SEL))objc_msgSend)(receiver,sel);
        log[[key stringByAppendingString:@"Status"]]=value?@"present":@"nil";
        if(value){
            log[[key stringByAppendingString:@"Class"]]=DFClassName(value);
            log[[key stringByAppendingString:@"Pointer"]]=DFPtr(value);
        }
        return value;
    } @catch(NSException *e){
        log[[key stringByAppendingString:@"Status"]]=@"exception";
        return nil;
    }
}
static void DFInspectOwner(UIViewController *vc, NSMutableDictionary *log) {
    if(![DFClassName(vc) isEqualToString:@"DBApplicationSceneViewController"])return;
    id scene=DFGetOwnerObject(vc,@"scene",log,@"nativeScene");
    id handle=DFGetOwnerObject(vc,@"sceneHandle",log,@"nativeSceneHandle");
    id info=DFGetOwnerObject(vc,@"applicationInfo",log,@"nativeApplicationInfo");
    id proxy=DFGetOwnerObject(vc,@"proxyApplicationInfo",log,@"nativeProxyApplicationInfo");
    if(!scene && handle)scene=DFGetOwnerObject(handle,@"sceneIfExists",log,@"nativeHandleScene");
    if(!info)info=proxy;
    if(info){
        NSMutableDictionary *metadata=[NSMutableDictionary new];
        id bundle=DFGetOwnerObject(info,@"bundleIdentifier",metadata,@"bundle");
        if([bundle isKindOfClass:NSString.class] && [bundle length]<=160)
            log[@"hostedBundleIdentifier"]=bundle;
    }
    if(scene){
        NSMutableDictionary *metadata=[NSMutableDictionary new];
        id identifier=DFGetOwnerObject(scene,@"identifier",metadata,@"identifier");
        if([identifier isKindOfClass:NSString.class] && [identifier length]<=160)
            log[@"hostedSceneIdentifier"]=identifier;
        // The public carplay-cast code documents this exact read-only
        // scene -> client -> process -> bundleIdentifier chain in SpringBoard.
        // Here it is guarded independently on CarPlayApp; missing selectors
        // must remain unresolved, never substituted by an assumed bundle.
        id client=DFGetOwnerObject(scene,@"client",log,@"nativeSceneClient");
        id process=client?DFGetOwnerObject(client,@"process",log,@"nativeSceneProcess"):nil;
        if(process){
            NSMutableDictionary *source=[NSMutableDictionary new];
            id bundle=DFGetOwnerObject(process,@"bundleIdentifier",source,@"bundle");
            if([bundle isKindOfClass:NSString.class] && [bundle length]<=160)
                log[@"nativeSceneProcessBundleIdentifier"]=bundle;
        }
    }
}

static void DFVisitController(UIViewController *vc,
                             NSMutableArray *records,
                             NSMutableSet<NSValue *> *seen,
                             NSUInteger depth) {
    if(!vc || depth>6 || records.count>=72)return;
    NSValue *key=[NSValue valueWithPointer:(__bridge const void *)vc];
    if([seen containsObject:key])return;
    [seen addObject:key];
    UIView *v=vc.viewIfLoaded; // MUST NOT trigger loadView/viewDidLoad.
    NSMutableDictionary *entry=[@{
        @"controllerClass":DFClassName(vc),
        @"controllerPointer":DFPtr(vc),
        @"depth":@(depth),
        @"loadedView":@(v!=nil),
        @"viewWindow":DFPtr(v.window),
        @"viewBounds":v?DFRect(v.bounds):@"nil",
        @"viewSceneRole":v.window.windowScene.session.role?:@"nil",
        @"viewSceneIdentifier":v.window.windowScene.session.persistentIdentifier?:@"nil",
        @"hasSceneHandleSelector":@(class_getInstanceMethod(object_getClass(vc),NSSelectorFromString(@"sceneHandle"))!=NULL),
        @"hasSceneSelector":@(class_getInstanceMethod(object_getClass(vc),NSSelectorFromString(@"scene"))!=NULL),
        @"hasApplicationInfoSelector":@(class_getInstanceMethod(object_getClass(vc),NSSelectorFromString(@"applicationInfo"))!=NULL)
    } mutableCopy];
    entry[@"sceneHostViewStatus"]=DFReadHostView(vc,entry);
    DFInspectOwner(vc,entry);
    if([entry[@"controllerClass"] isEqual:@"DBApplicationSceneViewController"])
        entry[@"nativeHostedSceneRoute"]=DFCarPlayNativeSceneRoute(entry);
    [records addObject:entry];
    if(records.count>=72)return;
    for(UIViewController *child in vc.childViewControllers){
        if(records.count>=72)break;
        DFVisitController(child,records,seen,depth+1);
    }
    if(vc.presentedViewController && records.count<72)
        DFVisitController(vc.presentedViewController,records,seen,depth+1);
}
static void DFWriteSnapshotLine(NSDictionary *payload) {
    if(![NSJSONSerialization isValidJSONObject:payload])return;
    NSData *json=[NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    if(!json || json.length>100*1024)return;
    NSMutableData *line=[json mutableCopy];
    [line appendBytes:"\n" length:1];
    int fd=open(DFMapOwnerLog.UTF8String,O_WRONLY|O_APPEND|O_CREAT|O_CLOEXEC,0644);
    if(fd<0){NSLog(@"[DuoFaceMapOwner] log-open-failed errno=%d",errno);return;}
    off_t size=lseek(fd,0,SEEK_END);
    if(size>4*1024*1024){(void)ftruncate(fd,0);(void)lseek(fd,0,SEEK_SET);}
    (void)write(fd,line.bytes,line.length);
    close(fd);
}
void DFCarPlayCaptureLiveOwnerSnapshot(NSString *probeSession) {
    if(!NSThread.isMainThread)return;
    NSString *process=NSProcessInfo.processInfo.processName;
    if(![process isEqualToString:@"CarPlayApp"] &&
       ![process isEqualToString:@"CarPlay"])return;
    @autoreleasepool {
        NSMutableArray *scenes=[NSMutableArray new];
        NSMutableArray *controllers=[NSMutableArray new];
        NSMutableSet<NSValue *> *visited=[NSMutableSet new];
        NSUInteger sceneCount=0, windowCount=0;
        // UIApplication window scenes are an observation, NOT proof of ownership
        // of a Maps scene in another process. Record missing association as missing.
        for(UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if(sceneCount++>=12)break;
            NSMutableDictionary *s=[@{
                @"sceneClass":DFClassName(scene),
                @"scenePointer":DFPtr(scene),
                @"sceneRole":scene.session.role?:@"nil",
                @"sceneIdentifier":scene.session.persistentIdentifier?:@"nil",
                @"activationState":@(scene.activationState)
            } mutableCopy];
            if([scene isKindOfClass:UIWindowScene.class]){
                UIWindowScene *ws=(UIWindowScene *)scene;
                s[@"screenPointer"]=DFPtr(ws.screen);
                s[@"mainScreen"]=@(ws.screen==UIScreen.mainScreen);
                s[@"sceneBounds"]=DFRect(ws.coordinateSpace.bounds);
                NSMutableArray *windows=[NSMutableArray new];
                for(UIWindow *w in ws.windows){
                    if(windowCount++>=48)break;
                    [windows addObject:@{
                        @"windowClass":DFClassName(w),
                        @"windowPointer":DFPtr(w),
                        @"rootController":DFClassName(w.rootViewController),
                        @"rootPointer":DFPtr(w.rootViewController),
                        @"hidden":@(w.hidden),
                        @"bounds":DFRect(w.bounds)
                    }];
                    DFVisitController(w.rootViewController,controllers,visited,0);
                }
                s[@"windows"]=windows;
            }
            [scenes addObject:s];
        }
        NSNumber *sampleUTC=@((long long)NSDate.date.timeIntervalSince1970);
        BOOL complete=(sceneCount<=12 && windowCount<=48 && controllers.count<72);
        NSDictionary *timeline=DFCarPlayNativeSceneTimelineAdvance(
            DFCarPlayPreviousTimeline,controllers,probeSession?:@"unset",
            @(getpid()),sampleUTC,complete);
        DFCarPlayPreviousTimeline=timeline;
        DFWriteSnapshotLine(@{
            @"schema":@3,@"kind":@"carplay-live-owner-readonly",
            @"probeSession":probeSession?:@"unset",
            @"utc":sampleUTC,
            @"process":process,
            @"bundle":NSBundle.mainBundle.bundleIdentifier?:@"nil",
            @"processPID":@(getpid()),
            @"scenes":scenes,@"controllers":controllers,@"nativeSceneTimeline":timeline,
            @"limitedScenes":@(sceneCount>12),@"limitedWindows":@(windowCount>48),
            @"limitedControllers":@(controllers.count>=72),
            @"mapsNativeOwnerProven":@NO,
            @"note":@"Presence/selector observations only; map scene identity and CP ownership require live interpretation."
        });
    }
}
