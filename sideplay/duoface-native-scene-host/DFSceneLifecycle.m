#import "DFCarPlayOwnerLease.h"
// Independent scene-update boundary policy. Evidence: Native12 hook registration
// 0x2c7c88 -> 0x2c7e08, audited in native12-foreground-hooks-20261027.
// No vendor markers, ivar writes, lock policy, or assertion suppression.
#import "DFSceneLifecycle.h"
#import "DFManualObserverContract.h"
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
// Native12 has a distinct sceneHandle:didDestroyScene: boundary. Keep a
// weak, identity-only tombstone so an already destroyed FBScene can NEVER
// be revived by a delayed foreground/under-lock settings write. Unlike the
// vendor implementation this never kills an app or swallows Apple's callback.
static void (*sPreviousSceneDestroy)(id, SEL, id, id);
static NSHashTable *sDestroyedOwnedScenes;
static BOOL sSceneDestroyInstalled;
static BOOL sInstalled;
// QA123: independently scoped under-lock policy for a live CarPlay-hosted
// phone scene only. Original signed DuoNavi/Native12 confirms the *behavior*,
// not code copied here. No passcode/activation hooks and no lock bypass.
static BOOL (*sOriginalBackgroundUnderLock)(id,SEL,id,id);
static BOOL sUnderLockInstalled;
static void (*sOriginalPostLockIntercept)(id,SEL,id,id);
static BOOL sPostLockInterceptInstalled;
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
    if(!NSThread.isMainThread || !scene ||
       [sDestroyedOwnedScenes containsObject:scene])return NO;
    for(id key in sOwners.keyEnumerator.allObjects) {
        id (^probe)(void)=[sOwners objectForKey:key];
        if(probe && probe()==scene)return YES;
    }
    return NO;
}
// The exact owner test is defined below with the iOS16 ABI/identity checks.
static BOOL DFIsOwnedHostedLockScene123(id scene);
static void DFUpdateScene(id scene, SEL selector, id settings, id context, id completion) {
    id forwarded=settings;
    // A stale registration/presentation is NOT enough to veto Apple's
    // background transition. QA129 previously rewrote foreground=NO whenever
    // the pane's scene pointer was still attached, even after CarPlay Home had
    // revoked that session. Require the SAME exact live host, current manual
    // scene handle, native CarPlay pulse, nonrevoked session and external window
    // already checked by our first-party under-lock owner predicate.
    // This is deliberately fail-closed and never changes unrelated scenes.
    if(DFOwnsScene(scene) && DFForeground(settings)==0) {
        if(!DFIsOwnedHostedLockScene123(scene)) {
            DFDeepTrace(@"scene-lifecycle",[NSString stringWithFormat:
              @"incoming-background-passthrough no-current-carplay-host scene=%p",
              scene]);
            sUpdate(scene,selector,settings,context,completion);
            return;
        }
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
// Independent scope: only our registered controller, its current sceneHandle
// with a real FBScene and ABI-checked automatesLifecycle == NO. Presentation
// visibility is deliberately NOT a callback ownership condition: a temporary
// detach must not route our still-manual controller into automatic handling.
// Foreign/stale handles and unregistered/automatic controllers pass through.
static BOOL DFIsOwnedManualSceneObserver(id controller, id handle) {
    if(!NSThread.isMainThread || !sOwners || !controller || !handle)return NO;
    BOOL registered=[sOwners objectForKey:controller]!=nil;
    if(!registered)return NO;
    SEL getHandle=NSSelectorFromString(@"sceneHandle");
    SEL getScene=NSSelectorFromString(@"sceneIfExists");
    if(![controller respondsToSelector:getHandle] ||
       ![handle respondsToSelector:getScene])return NO;
    id currentHandle=((id(*)(id,SEL))objc_msgSend)(controller,getHandle);
    if(currentHandle!=handle)return NO;
    id currentScene=((id(*)(id,SEL))objc_msgSend)(handle,getScene);
    if(!currentScene)return NO;
    SEL autoSel=NSSelectorFromString(@"automatesLifecycle");
    Method autoMethod=class_getInstanceMethod(object_getClass(controller),autoSel);
    if(!autoMethod || method_getNumberOfArguments(autoMethod)!=2)return NO;
    char resultType[8]={0};
    method_getReturnType(autoMethod,resultType,sizeof(resultType));
    BOOL valid=!strcmp(resultType,"B") || !strcmp(resultType,"c");
    if(!valid)return NO;
    BOOL automatic=((BOOL(*)(id,SEL))objc_msgSend)(controller,autoSel);
    return DFManualObserverOwnsCallback(NSThread.isMainThread,registered,
        currentHandle==handle,currentScene!=nil,valid,automatic);
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
    sPreviousSceneObserver(controller,selector,handle,diff,previousSettings);
}
// Never interpret a destroyed manual scene as a valid owner. This callback
// comes from the real iOS16 SBAppViewController boundary seen in Native12's
// SHA-pinned 11-hook ARM64 inventory. This independent implementation is
// deliberately not a vendor-style 'terminate' hook. It only withdraws the
// stale scene identity, then forwards Apple's original exactly once.
static void DFManagedSceneDestroy(id controller, SEL selector, id handle, id scene) {
    if(NSThread.isMainThread && controller && handle && scene && sOwners &&
       [sOwners objectForKey:controller]) {
        SEL getHandle=NSSelectorFromString(@"sceneHandle");
        if([controller respondsToSelector:getHandle]) {
            id current=((id(*)(id,SEL))objc_msgSend)(controller,getHandle);
            id (^owned)(void)=[sOwners objectForKey:controller];
            if(current==handle && owned && owned()==scene) {
                [sDestroyedOwnedScenes addObject:scene];
                DFDeepTrace(@"scene-lifecycle",[NSString stringWithFormat:
                    @"owned-manual-scene-destroy-tombstone scene=%p controller=%p handle=%p",
                    scene,controller,handle]);
            }
        }
    }
    // Foreign, unmatched and genuine owned scenes all continue into Apple.
    // Never dismiss an app or synthesize a destroy event from this observer.
    sPreviousSceneDestroy(controller,selector,handle,scene);
}
static void DFInstallSceneDestroyObserver(Class host,
                                         void (*hook)(Class,SEL,IMP,IMP *)) {
    if(sSceneDestroyInstalled || !host || !hook)return;
    SEL sel=NSSelectorFromString(@"sceneHandle:didDestroyScene:");
    Method m=class_getInstanceMethod(host,sel);
    if(!m || method_getNumberOfArguments(m)!=4) {
        DFDeepTrace(@"scene-lifecycle",@"scene-destroy-abi-missing-original-only");
        return;
    }
    char type[32]={0};method_getReturnType(m,type,sizeof(type));
    if(strcmp(type,"v"))return;
    for(unsigned int i=2;i<4;i++) {
        method_getArgumentType(m,i,type,sizeof(type));
        if(type[0]!='@')return;
    }
    IMP existing=method_getImplementation(m);
    if(!existing || existing==(IMP)DFManagedSceneDestroy)return;
    hook(host,sel,(IMP)DFManagedSceneDestroy,(IMP *)&sPreviousSceneDestroy);
    // Preserve a safe pre-hook IMP if the substrate provider does not return
    // its trampoline. Do not silently consume Apple destroy on an ABI failure.
    if(!sPreviousSceneDestroy)sPreviousSceneDestroy=(void(*)(id,SEL,id,id))existing;
    sSceneDestroyInstalled=sPreviousSceneDestroy!=NULL;
    DFDeepTrace(@"scene-lifecycle",sSceneDestroyInstalled?
       @"owned-scene-destroy-tombstone-and-original-forward-installed":
       @"scene-destroy-no-original-not-installed");
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
    if(!DFOwnerAcceptPulse(pulse))return NO;
    if(![pulse[@"Active"] respondsToSelector:@selector(boolValue)] ||
       ![pulse[@"Active"] boolValue] ||
       ![pulse[@"Session"] isKindOfClass:NSString.class] ||
       [pulse[@"Session"] length]<10 ||
       ![pulse[@"Timestamp"] respondsToSelector:@selector(doubleValue)])return NO;
    // Shared validator checks app freshness or the bound native Background lease.
    // An actual separate car display, not an iPhone lock-screen window.
    for(UIScreen *screen in UIScreen.screens)
        if(screen!=UIScreen.mainScreen)return YES;
    return NO;
}
static BOOL DFIsOwnedHostedLockScene123(id scene) {
    if(!sOwners || !scene || [sDestroyedOwnedScenes containsObject:scene] ||
       !DFSessionOwnsLiveCarPlay123())return NO;
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
// Original DuoNavi post-lock callback at 0x2ed954 forwards Apple FIRST and
// then normalizes settings for its selected hosted scene (helper 0x2eca50).
// Independent implementation: only ABI-checked BOOL accessors; no ivar writes,
// frame changes, deactivation-reason clearing or phone security policy hooks.
static BOOL DFPostLockBoolABI(NSMethodSignature *sig, BOOL setter) {
    if(!sig || sig.numberOfArguments!=(setter?3u:2u))return NO;
    const char *type=setter?[sig getArgumentTypeAtIndex:2]:sig.methodReturnType;
    return (!strcmp(type,"B") || !strcmp(type,"c")) &&
           (!setter || !strcmp(sig.methodReturnType,"v"));
}
static BOOL DFPostLockSetBool(id settings, NSString *readName,
                             NSString *writeName, BOOL value) {
    SEL read=NSSelectorFromString(readName),write=NSSelectorFromString(writeName);
    if(!DFPostLockBoolABI([settings methodSignatureForSelector:read],NO) ||
       !DFPostLockBoolABI([settings methodSignatureForSelector:write],YES))return NO;
    BOOL before=((BOOL(*)(id,SEL))objc_msgSend)(settings,read);
    if(before!=value)((void(*)(id,SEL,BOOL))objc_msgSend)(settings,write,value);
    return ((BOOL(*)(id,SEL))objc_msgSend)(settings,read)==value;
}
static void DFPostLockIntercept(id manager,SEL cmd,id scene,id settings) {
    // Exactly once and outside any catch. This is a void callback, never a
    // predicate. A foreign/stale/inactive scene receives only Apple's behavior.
    sOriginalPostLockIntercept(manager,cmd,scene,settings);
    if(!settings || !DFIsOwnedHostedLockScene123(scene))return;
    @try {
        BOOL fg=DFPostLockSetBool(settings,@"isForeground",@"setForeground:",YES);
        BOOL occluded=DFPostLockSetBool(settings,@"isOccluded",@"setOccluded:",NO);
        BOOL locked=DFPostLockSetBool(settings,@"isUnderLock",@"setUnderLock:",NO);
        BOOL show=DFPostLockSetBool(settings,@"canShowWhileLocked",@"setCanShowWhileLocked:",YES);
        BOOL idle=DFPostLockSetBool(settings,@"idleModeEnabled",@"setIdleModeEnabled:",NO);
        DFDeepTrace(@"postlock-settings",[NSString stringWithFormat:
          @"owned-original-first scene=%p fg-ack=%d occlusion-ack=%d scene-lock-ack=%d show-ack=%d idle-ack=%d input-ack=unverified",
          scene,fg,occluded,locked,show,idle]);
    } @catch(NSException *error) {
        DFDeepTrace(@"postlock-settings",[NSString stringWithFormat:
          @"normalization-unavailable exception=%@",error.name]);
    }
}
static void DFInstallPostLockIntercept(void) {
    if(sPostLockInterceptInstalled)return;
    Class cls=NSClassFromString(@"SBSuspendedUnderLockManager");
    SEL sel=NSSelectorFromString(@"interceptUpdateForScene:withNewSettings:");
    Method method=cls?class_getInstanceMethod(cls,sel):NULL;
    if(!method || method_getNumberOfArguments(method)!=4)return;
    char type[32]={0};method_getReturnType(method,type,sizeof(type));
    if(strcmp(type,"v"))return;
    for(unsigned int i=2;i<4;i++) {
        method_getArgumentType(method,i,type,sizeof(type));
        if(type[0]!='@')return;
    }
    typedef void (*Hook)(Class,SEL,IMP,IMP *);
    Hook hook=(Hook)dlsym(RTLD_DEFAULT,"MSHookMessageEx");
    if(!hook || !method_getImplementation(method))return;
    hook(cls,sel,(IMP)DFPostLockIntercept,(IMP *)&sOriginalPostLockIntercept);
    sPostLockInterceptInstalled=sOriginalPostLockIntercept!=NULL;
    DFDeepTrace(@"postlock-settings",sPostLockInterceptInstalled?
        @"original-first-intercept-installed":@"original-imp-unavailable");
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
    sDestroyedOwnedScenes=[NSHashTable weakObjectsHashTable];
    hook(host,observer,(IMP)DFManagedSceneObserver,(IMP *)&sPreviousSceneObserver);
    if(!sPreviousSceneObserver){
        DFDeepTrace(@"scene-lifecycle",@"manual-observer-original-unavailable");
        return NO;
    }
    hook(cls,selector,(IMP)DFUpdateScene,(IMP *)&sUpdate);
    sInstalled=sUpdate!=NULL;
    if(sInstalled) {
        DFInstallSceneDestroyObserver(host,hook);
        DFInstallOwnedUnderLock123();
        DFInstallPostLockIntercept();
    }
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
