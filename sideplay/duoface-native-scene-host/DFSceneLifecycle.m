// Independent scene-update boundary policy. Evidence: Native12 hook registration
// 0x2c7c88 -> 0x2c7e08, audited in native12-foreground-hooks-20261027.
// No vendor markers, ivar writes, lock policy, or assertion suppression.
#import "DFSceneLifecycle.h"
#import "DFDeepTrace.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>
#import <string.h>
#import <math.h>
#import <UIKit/UIKit.h>

static NSMapTable *sOwners;
static void (*sUpdate)(id, SEL, id, id, id);
static void (*sPreviousSceneObserver)(id, SEL, id, id, id);
static BOOL sInstalled;
// QA123: independently scoped under-lock policy for a live CarPlay-hosted
// phone scene only. Original signed DuoNavi/Native12 confirms the *behavior*,
// not code copied here. No passcode/activation hooks and no lock bypass.
static BOOL (*sOriginalBackgroundUnderLock)(id,SEL,id,id);
static BOOL sUnderLockInstalled;
static NSString *const DFCarPlayPulsePath123=
 @"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist";

static BOOL DFObjectUpdateABI(Method method) {
    if (!method || method_getNumberOfArguments(method)!=5) return NO;
    char type[64]={0};
    method_getReturnType(method,type,sizeof(type));
    if(strcmp(type,"v"))return NO;
    for(unsigned int i=2;i<5;i++) {
        method_getArgumentType(method,i,type,sizeof(type));
        if(type[0]!='@')return NO;
    }
    return YES;
}
static NSInteger DFForeground(id settings) {
    for(NSString *name in @[@"isForeground",@"foreground"]) {
        SEL sel=NSSelectorFromString(name);
        NSMethodSignature *sig=[settings methodSignatureForSelector:sel];
        if(sig && sig.numberOfArguments==2 &&
           (!strcmp(sig.methodReturnType,"B") || !strcmp(sig.methodReturnType,"c")))
            return ((BOOL(*)(id,SEL))objc_msgSend)(settings,sel)?1:0;
    }
    return -1;
}
static BOOL DFOwnsScene(id scene) {
    // No cross-thread UIKit access, and no identity-by-bundle shortcuts.
    if(!NSThread.isMainThread || !scene)return NO;
    for(id key in sOwners.keyEnumerator.allObjects) {
        id (^probe)(void)=[sOwners objectForKey:key];
        if(probe && probe()==scene)return YES;
    }
    return NO;
}
static void DFUpdateScene(id scene, SEL selector, id settings, id context, id completion) {
    id forwarded=settings;
    // Only repair an explicit background request while the pane still owns a
    // Live host. Unknown ABI/foreground, nonowned scenes and teardown pass through.
    if(DFOwnsScene(scene) && DFForeground(settings)==0) {
        @try {
            id candidate=[settings mutableCopy];
            SEL fg=NSSelectorFromString(@"setForeground:");
            NSMethodSignature *sig=[candidate methodSignatureForSelector:fg];
            BOOL valid=sig && sig.numberOfArguments==3 &&
                !strcmp(sig.methodReturnType,"v") &&
                (!strcmp([sig getArgumentTypeAtIndex:2],"B") ||
                 !strcmp([sig getArgumentTypeAtIndex:2],"c"));
            if(candidate && candidate!=settings && valid && DFOwnsScene(scene)) {
                ((void(*)(id,SEL,BOOL))objc_msgSend)(candidate,fg,YES);
                if(DFForeground(candidate)==1) {
                    forwarded=candidate;
                    DFDeepTrace(@"scene-lifecycle",[NSString stringWithFormat:
                        @"incoming-background-owned-live scene=%p corrected-copy=1 caller=%@",
                        scene,[NSThread.callStackSymbols componentsJoinedByString:@" | "]]);
                }
            }
        } @catch(NSException *error) {
            // Catch only preparation failures, NEVER exceptions from the OS IMP.
            DFDeepTrace(@"scene-lifecycle",[NSString stringWithFormat:
                @"policy-preparation-failed type=%@ pass-through=1",error.name]);
        }
    }
    // Exactly once, outside catch. Same context/completion, no recursive update,
    // no nil transition and no direct invocation of the completion block.
    sUpdate(scene,selector,forwarded,context,completion);
}
// Native12 original 0x2c8ca8 demonstrates a distinct policy at this exact
// SBAppViewController observer: its manual-lifecycle hosted controller does not
// forward the observer into Apple's automatic lifecycle handling. Keep the
// independent DuoFace contract STRICTER: only current registered controller,
// matching live sceneHandle/FBScene and explicit automatesLifecycle == NO.
// A foreign, stale, closing, unregistered or automatic controller is untouched.
static BOOL DFIsOwnedManualSceneObserver(id controller, id handle) {
    if(!NSThread.isMainThread || !sOwners || !controller || !handle)return NO;
    id (^ownedScene)(void)=[sOwners objectForKey:controller];
    if(!ownedScene)return NO;
    id scene=ownedScene();
    if(!scene)return NO;
    SEL getHandle=NSSelectorFromString(@"sceneHandle");
    SEL getScene=NSSelectorFromString(@"sceneIfExists");
    if(![controller respondsToSelector:getHandle] ||
       ![handle respondsToSelector:getScene])return NO;
    id currentHandle=((id(*)(id,SEL))objc_msgSend)(controller,getHandle);
    if(currentHandle!=handle)return NO;
    id currentScene=((id(*)(id,SEL))objc_msgSend)(handle,getScene);
    if(currentScene!=scene)return NO;
    SEL autoSel=NSSelectorFromString(@"automatesLifecycle");
    Method autoMethod=class_getInstanceMethod(object_getClass(controller),autoSel);
    if(!autoMethod)return NO;
    char resultType[8]={0};
    method_getReturnType(autoMethod,resultType,sizeof(resultType));
    if(resultType[0]!='B' && resultType[0]!='c')return NO;
    return !((BOOL(*)(id,SEL))objc_msgSend)(controller,autoSel);
}
// QA126 diagnostic-only breadcrumb at the EXACT real-device SpringBoard
// assertion boundary. Emits a bounded, synchronous one-line record before
// delegating to Apple's original observer. It NEVER changes scene settings,
// ownership, callback dispatch, exception handling, or device lock policy.
// Existing DuoFaceAudit exports DuoFaceDeepTrace.log, so no new tester needed.
static void DFObserverForwardBreadcrumb126(id controller, id callbackHandle) {
    if(!NSThread.isMainThread || !sOwners || sOwners.count==0)return;
    static unsigned int records;
    if(records>=96)return;
    ++records;
    @try {
        id (^owned)(void)=[sOwners objectForKey:controller];
        id registered=owned?owned():nil;
        SEL getHandle=NSSelectorFromString(@"sceneHandle");
        SEL getScene=NSSelectorFromString(@"sceneIfExists");
        id current=(controller && [controller respondsToSelector:getHandle])?
           ((id(*)(id,SEL))objc_msgSend)(controller,getHandle):nil;
        id observed=(callbackHandle && [callbackHandle respondsToSelector:getScene])?
           ((id(*)(id,SEL))objc_msgSend)(callbackHandle,getScene):nil;
        SEL automates=NSSelectorFromString(@"automatesLifecycle");
        Method m=controller?class_getInstanceMethod(object_getClass(controller),automates):NULL;
        char ret[8]={0};
        if(m)method_getReturnType(m,ret,sizeof(ret));
        int manual=-1;
        if(m && (ret[0]=='B'||ret[0]=='c'))
            manual=!((BOOL(*)(id,SEL))objc_msgSend)(controller,automates);
        SEL hosted=NSSelectorFromString(@"isHostingAnApp");
        Method hm=controller?class_getInstanceMethod(object_getClass(controller),hosted):NULL;
        char ht[8]={0};
        if(hm)method_getReturnType(hm,ht,sizeof(ht));
        int hosting=-1;
        if(hm && (ht[0]=='B'||ht[0]=='c'))
            hosting=((BOOL(*)(id,SEL))objc_msgSend)(controller,hosted);
        char line[560]={0};
        int n=snprintf(line,sizeof(line),
          "utc=%.6f pid=%d area=qa126-observer event=before-apple-forward count=%u owners=%lu controller=%p registered=%p currentHandle=%p callbackHandle=%p observed=%p ownerKnown=%d handleMatch=%d sceneMatch=%d manual=%d hosting=%d\n",
          NSDate.date.timeIntervalSince1970,getpid(),records,
          (unsigned long)sOwners.count,(void *)controller,(void *)registered,
          (void *)current,(void *)callbackHandle,(void *)observed,
          owned!=nil,current==callbackHandle,registered!=nil && registered==observed,
          manual,hosting);
        if(n<=0)return;
        size_t size=(size_t)n<sizeof(line)?(size_t)n:sizeof(line)-1;
        int fd=open("/var/mobile/Library/Logs/DuoFaceDeepTrace.log",
                    O_WRONLY|O_CREAT|O_APPEND,0644);
        if(fd>=0){
            (void)write(fd,line,size);
            (void)fsync(fd); // preserve evidence if the next Apple call aborts
            (void)close(fd);
        }
    } @catch(NSException *ignored) { (void)ignored; }
}
static void DFManagedSceneObserver(id controller, SEL selector, id handle,
                                   id diff, id previousSettings) {
    if(DFIsOwnedManualSceneObserver(controller,handle)) {
        // Only the lifecycle update delegate for THIS manual, currently owned
        // scene is handled by the custom host. The system observer's automatic
        // Live/background transition would conflict with that contract.
        // Never suppress all controllers or intercept a destroy/replace event.
        DFDeepTrace(@"scene-lifecycle",[NSString stringWithFormat:
            @"owned-manual-observer-consumed controller=%p handle=%p scene=%p",
            controller,handle,
            ((id(*)(id,SEL))objc_msgSend)(handle,NSSelectorFromString(@"sceneIfExists"))]);
        return;
    }
    DFObserverForwardBreadcrumb126(controller,handle);
    sPreviousSceneObserver(controller,selector,handle,diff,previousSettings);
}
// UIKit/FrontBoard object provenance must match the *current* live scene,
// not merely an allowed bundle string. SpringBoard may ask about other apps'
// scenes during a phone lock; those ALWAYS retain Apple's original policy.
// Fail closed on unknown ABI, off-main thread, a stale heartbeat or missing
// external display; never reinterpret iPhone passcode/lock authorization.
static BOOL DFLockABI(Method method, unsigned int count) {
    if(!method || method_getNumberOfArguments(method)!=count)return NO;
    char type[16]={0};
    method_getReturnType(method,type,sizeof(type));
    if(type[0]!='B' && type[0]!='c')return NO;
    for(unsigned int i=2;i<count;i++) {
        method_getArgumentType(method,i,type,sizeof(type));
        if(type[0]!='@')return NO;
    }
    return YES;
}
static BOOL DFSessionOwnsLiveCarPlay123(void) {
    if(!NSThread.isMainThread)return NO;
    NSDictionary *pulse=[NSDictionary dictionaryWithContentsOfFile:DFCarPlayPulsePath123];
    if(![pulse[@"Active"] respondsToSelector:@selector(boolValue)] ||
       ![pulse[@"Active"] boolValue] ||
       ![pulse[@"Session"] isKindOfClass:NSString.class] ||
       [pulse[@"Session"] length]<10 ||
       ![pulse[@"Timestamp"] respondsToSelector:@selector(doubleValue)])return NO;
    NSTimeInterval age=NSDate.date.timeIntervalSince1970-
                       [pulse[@"Timestamp"] doubleValue];
    // QA124: same validity window as SpringBoard owner watchdog; 0.75s
    // CarPlay pulse renewal tolerates ForegroundInactive while the external
    // template remains connected. A revoked pulse still fails closed.
    if(!isfinite(age) || age<0 || age>2.5)return NO;
    // An actual separate car display, not an iPhone lock-screen window.
    for(UIScreen *screen in UIScreen.screens)
        if(screen!=UIScreen.mainScreen)return YES;
    return NO;
}
static BOOL DFIsOwnedHostedLockScene123(id scene) {
    if(!sOwners || !scene || !DFSessionOwnsLiveCarPlay123())return NO;
    for(id controller in sOwners.keyEnumerator.allObjects) {
        id (^current)(void)=[sOwners objectForKey:controller];
        if(!current || current()!=scene)continue;
        id handle=((id(*)(id,SEL))objc_msgSend)(controller,
                                                NSSelectorFromString(@"sceneHandle"));
        if(!DFIsOwnedManualSceneObserver(controller,handle))continue;
        SEL hosted=NSSelectorFromString(@"isHostingAnApp");
        Method hm=class_getInstanceMethod(object_getClass(controller),hosted);
        if(!DFLockABI(hm,2))continue;
        if(!((BOOL(*)(id,SEL))objc_msgSend)(controller,hosted))continue;
        UIView *view=[controller viewIfLoaded];
        UIWindow *window=view.window;
        if(!window || window.hidden || window.screen==UIScreen.mainScreen ||
           view.hidden || view.alpha<=0.0)return NO;
        return YES;
    }
    return NO;
}
static BOOL DFUnderLockBackground123(id manager,SEL cmd,id scene,id settings) {
    if(DFIsOwnedHostedLockScene123(scene)) {
        DFDeepTrace(@"qa123-underlock",@"owned-live-underlock-background-rejected");
        return NO;
    }
    if(!sOriginalBackgroundUnderLock) {
        DFDeepTrace(@"qa125-underlock",@"missing-original-imp-fail-closed");
        return YES; // Conservative: never exempt unrelated scenes if hook chaining fails.
    }
    return sOriginalBackgroundUnderLock(manager,cmd,scene,settings);
}
static void DFInstallOwnedUnderLock123(void) {
    if(sUnderLockInstalled)return;
    Class cls=NSClassFromString(@"SBSuspendedUnderLockManager");
    SEL background=NSSelectorFromString(
          @"_shouldBeBackgroundUnderLockForScene:withSettings:");
    // QA125 physical iOS16.7.16 ABI measured from real SpringBoard PID 4989:
    // background B32@0:8@16@24 exists, but shouldBeUnderLockForScene:
    // DOES NOT EXIST. Never require or create the missing selector.
    Method bg=cls?class_getInstanceMethod(cls,background):NULL;
    Method obsolete=cls?class_getInstanceMethod(
        cls,NSSelectorFromString(@"shouldBeUnderLockForScene:")):NULL;
    DFDeepTrace(@"qa125-underlock",[NSString stringWithFormat:
        @"runtime-presence background=%d obsolete=%d bg-argc=%u",
        bg!=NULL,obsolete!=NULL,bg?method_getNumberOfArguments(bg):0]);
    if(!DFLockABI(bg,4) || method_getImplementation(bg)==NULL) {
        DFDeepTrace(@"qa125-underlock",@"background-abi-rejected-no-hook");
        return;
    }
    typedef void (*Hook)(Class,SEL,IMP,IMP *);
    Hook hook=(Hook)dlsym(RTLD_DEFAULT,"MSHookMessageEx");
    if(!hook) {
        DFDeepTrace(@"qa125-underlock",@"hook-provider-unavailable");
        return;
    }
    // Exactly one ABI-confirmed existing selector. Only live registered
    // exterior hosted scenes may return NO; foreign scenes call Apple's IMP.
    // No passcode, activation, device display or missing-method hooks.
    hook(cls,background,(IMP)DFUnderLockBackground123,
         (IMP *)&sOriginalBackgroundUnderLock);
    sUnderLockInstalled=sOriginalBackgroundUnderLock!=NULL;
    DFDeepTrace(@"qa125-underlock",sUnderLockInstalled?
      @"scoped-existing-background-hook-installed":
      @"background-original-imp-unavailable");
}
BOOL DFSceneLifecycleInstall(void) {
    if(!NSThread.isMainThread)return NO;
    if(sInstalled)return YES;
    Class cls=NSClassFromString(@"FBScene");
    Class host=NSClassFromString(@"SBAppViewController");
    SEL selector=NSSelectorFromString(@"updateSettings:withTransitionContext:completion:");
    SEL observer=NSSelectorFromString(@"sceneHandle:didUpdateSettingsWithDiff:previousSettings:");
    Method method=class_getInstanceMethod(cls,selector);
    Method observerMethod=class_getInstanceMethod(host,observer);
    // Never enable half of the first-party manual-scene policy. If the iOS
    // observer ABI is unavailable, fail host admission before Live is requested.
    if(!DFObjectUpdateABI(method) || !DFObjectUpdateABI(observerMethod))return NO;
    typedef void (*Hook)(Class,SEL,IMP,IMP *);
    Hook hook=(Hook)dlsym(RTLD_DEFAULT,"MSHookMessageEx");
    if(!hook)return NO;
    sOwners=[NSMapTable weakToStrongObjectsMapTable];
    hook(host,observer,(IMP)DFManagedSceneObserver,(IMP *)&sPreviousSceneObserver);
    if(!sPreviousSceneObserver){
        DFDeepTrace(@"scene-lifecycle",@"manual-observer-original-unavailable");
        return NO;
    }
    hook(cls,selector,(IMP)DFUpdateScene,(IMP *)&sUpdate);
    sInstalled=sUpdate!=NULL;
    if(sInstalled)DFInstallOwnedUnderLock123();
    DFDeepTrace(@"scene-lifecycle",sInstalled?@"manual-owner-observer-and-foreground-boundary-installed":@"boundary-unavailable");
    return sInstalled;
}
void DFSceneLifecycleRegister(id controller, id (^currentOwnedScene)(void)) {
    NSCAssert(NSThread.isMainThread,@"Scene ownership is main-thread confined");
    if(sInstalled && controller && currentOwnedScene)
        [sOwners setObject:[currentOwnedScene copy] forKey:controller];
}
void DFSceneLifecycleUnregister(id controller) {
    NSCAssert(NSThread.isMainThread,@"Scene ownership is main-thread confined");
    if(controller)[sOwners removeObjectForKey:controller];
}
