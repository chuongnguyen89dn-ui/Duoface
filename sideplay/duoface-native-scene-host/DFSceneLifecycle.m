// Independent scene-update boundary policy. Evidence: Native12 hook registration
// 0x2c7c88 -> 0x2c7e08, audited in native12-foreground-hooks-20261027.
// No vendor markers, ivar writes, lock policy, or assertion suppression.
#import "DFSceneLifecycle.h"
#import "DFDeepTrace.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>
#import <string.h>

static NSMapTable *sOwners;
static void (*sUpdate)(id, SEL, id, id, id);
static BOOL sInstalled;

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
BOOL DFSceneLifecycleInstall(void) {
    if(!NSThread.isMainThread)return NO;
    if(sInstalled)return YES;
    Class cls=NSClassFromString(@"FBScene");
    SEL selector=NSSelectorFromString(@"updateSettings:withTransitionContext:completion:");
    Method method=class_getInstanceMethod(cls,selector);
    if(!DFObjectUpdateABI(method))return NO;
    typedef void (*Hook)(Class,SEL,IMP,IMP *);
    Hook hook=(Hook)dlsym(RTLD_DEFAULT,"MSHookMessageEx");
    if(!hook)return NO;
    sOwners=[NSMapTable weakToStrongObjectsMapTable];
    hook(cls,selector,(IMP)DFUpdateScene,(IMP *)&sUpdate);
    sInstalled=sUpdate!=NULL;
    DFDeepTrace(@"scene-lifecycle",sInstalled?@"boundary-installed":@"boundary-unavailable");
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
