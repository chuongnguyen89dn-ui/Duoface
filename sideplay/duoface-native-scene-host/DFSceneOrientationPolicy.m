// Independent DuoFace implementation based on verified Native12 ABI behavior,
// NOT copied from the vendor dylib. Baseline .83 lifecycle observer is untouched.
// Native12 gold: eligible bridge main-scene supports portrait=1 only, plus
// per-bundle native render-size override in both reference-size selectors.
// Unsupported/private ABIs fail closed (pass through Apple implementation).
#import "DFSceneOrientationPolicy.h"
#import "DFAppEligibility.h"
#import "DFDeepTrace.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>
#import <math.h>
#import <string.h>

typedef CGSize (^DFSizeProvider)(void);
static NSMapTable *sHandleOwners;
static NSMapTable *sControllerOwners;
static BOOL sAttempted;
static BOOL sInstalled;
static BOOL (*sOriginalOrientation)(id,SEL,NSInteger);
static void (*sOriginalSize2)(id,SEL,CGSize,NSInteger);
static void (*sOriginalSize3)(id,SEL,CGSize,NSInteger,NSInteger);

static BOOL DFOrientationABI(Method method) {
    if(!method || method_getNumberOfArguments(method)!=3)return NO;
    char t[128]={0};
    method_getReturnType(method,t,sizeof(t));
    if(t[0]!='B' && t[0]!='c')return NO;
    method_getArgumentType(method,2,t,sizeof(t));
    return t[0]=='q' || t[0]=='i';
}
static BOOL DFSizeABI(Method method, BOOL three) {
    if(!method || method_getNumberOfArguments(method)!=(three?5:4))return NO;
    char t[128]={0};
    method_getReturnType(method,t,sizeof(t));
    if(strcmp(t,"v"))return NO;
    method_getArgumentType(method,2,t,sizeof(t));
    if(strncmp(t,"{CGSize=",8)!=0 && strncmp(t,"{_CGSize=",9)!=0)return NO;
    method_getArgumentType(method,3,t,sizeof(t));
    if(t[0]!='q' && t[0]!='i')return NO;
    if(three) {
        method_getArgumentType(method,4,t,sizeof(t));
        if(t[0]!='q' && t[0]!='i')return NO;
    }
    return YES;
}
static CGSize DFEligibleSize(NSMapTable *table,id key) {
    // No UIKit ownership checks off main; never infer by bundle identifier.
    if(!NSThread.isMainThread || !table || !key)return CGSizeZero;
    DFSizeProvider current=[table objectForKey:key];
    if(!current)return CGSizeZero;
    CGSize size=current();
    if(!isfinite(size.width)||!isfinite(size.height)||
       size.width<64||size.height<64||size.width>8192||size.height>8192)
        return CGSizeZero;
    return size;
}
static BOOL DFMainSceneSupportsOrientation(id handle,SEL sel,NSInteger requested) {
    CGSize size=DFEligibleSize(sHandleOwners,handle);
    if(!CGSizeEqualToSize(size,CGSizeZero)) {
        // Native12 gold 0x2c8c44 compares requested main-scene orientation to 1.
        // This is NOT a CarPlay landscape lock and does not alter child/player UI.
        BOOL result=requested==1;
        DFDeepTrace(@"scene-orientation",[NSString stringWithFormat:
           @"owned-handle=%p requested=%ld allowed=%d size=%@",
            handle,(long)requested,result,[NSString stringWithFormat:@"%.0fx%.0f",size.width,size.height]]);
        return result;
    }
    return sOriginalOrientation(handle,sel,requested);
}
static void DFContentReferenceSize2(id controller,SEL sel,CGSize proposed,NSInteger orientation) {
    CGSize selected=DFEligibleSize(sControllerOwners,controller);
    if(CGSizeEqualToSize(selected,CGSizeZero))selected=proposed;
    // Preserve Apple's original orientation parameter, call original once.
    sOriginalSize2(controller,sel,selected,orientation);
}
static void DFContentReferenceSize3(id controller,SEL sel,CGSize proposed,
                                    NSInteger contentOrientation,NSInteger containerOrientation) {
    CGSize selected=DFEligibleSize(sControllerOwners,controller);
    if(CGSizeEqualToSize(selected,CGSizeZero))selected=proposed;
    sOriginalSize3(controller,sel,selected,contentOrientation,containerOrientation);
}
BOOL DFSceneOrientationPolicyInstall(void) {
    if(!NSThread.isMainThread)return NO;
    if(sAttempted)return sInstalled;
    sAttempted=YES;
    Class handle=NSClassFromString(@"SBDeviceApplicationSceneHandle");
    Class controller=NSClassFromString(@"SBDeviceApplicationSceneViewController");
    SEL orientation=NSSelectorFromString(@"_mainSceneSupportsInterfaceOrientation:");
    SEL size2=NSSelectorFromString(@"setContentReferenceSize:withInterfaceOrientation:");
    SEL size3=NSSelectorFromString(@"setContentReferenceSize:withContentOrientation:andContainerOrientation:");
    Method o=handle?class_getInstanceMethod(handle,orientation):NULL;
    Method a=controller?class_getInstanceMethod(controller,size2):NULL;
    Method b=controller?class_getInstanceMethod(controller,size3):NULL;
    typedef void (*Hook)(Class,SEL,IMP,IMP *);
    Hook hook=(Hook)dlsym(RTLD_DEFAULT,"MSHookMessageEx");
    // Do not change any behavior if the essential scene-handle ABI is unknown.
    if(!hook || !DFOrientationABI(o)) {
        DFDeepTrace(@"scene-orientation",@"install-skipped:hook-or-orientation-ABI-unavailable");
        return NO;
    }
    sHandleOwners=[NSMapTable weakToStrongObjectsMapTable];
    sControllerOwners=[NSMapTable weakToStrongObjectsMapTable];
    hook(handle,orientation,(IMP)DFMainSceneSupportsOrientation,(IMP *)&sOriginalOrientation);
    if(!sOriginalOrientation) {
        DFDeepTrace(@"scene-orientation",@"install-failed:missing-original-orientation-IMP");
        return NO;
    }
    if(DFSizeABI(a,NO)) {
        hook(controller,size2,(IMP)DFContentReferenceSize2,(IMP *)&sOriginalSize2);
    }
    if(DFSizeABI(b,YES)) {
        hook(controller,size3,(IMP)DFContentReferenceSize3,(IMP *)&sOriginalSize3);
    }
    sInstalled=YES;
    DFDeepTrace(@"scene-orientation",[NSString stringWithFormat:
       @"installed:portrait-only-owned-handle=1 size2=%d size3=%d",
       sOriginalSize2!=NULL,sOriginalSize3!=NULL]);
    return YES;
}
void DFSceneOrientationPolicyRegister(id handle,id deviceController,
                                      NSString *bundleID,DFSizeProvider provider) {
    NSCAssert(NSThread.isMainThread,@"Orientation registration must be on main thread");
    if(!sInstalled || !handle || !provider || !DFIsEligibleAppID(bundleID))return;
    DFSizeProvider copy=[provider copy];
    [sHandleOwners setObject:copy forKey:handle];
    if(deviceController && (sOriginalSize2 || sOriginalSize3))
        [sControllerOwners setObject:copy forKey:deviceController];
}
void DFSceneOrientationPolicyUnregister(id handle,id deviceController) {
    NSCAssert(NSThread.isMainThread,@"Orientation revoke must be on main thread");
    if(handle)[sHandleOwners removeObjectForKey:handle];
    if(deviceController)[sControllerOwners removeObjectForKey:deviceController];
}
