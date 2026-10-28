// First-party YouTube process-local orientation contract, NOT vendor binary code.
// Original Native12 SHA-pinned ARM64 audit at:
// sideplay/audit/native12-083-rotation-20261028/
// NATIVE12_ORIGINAL_36_HOOK_CALLBACKS_RUN_40667230467.json
// Runtime owns ONLY com.google.ios.youtube, exact v2 host lease, active UIKit scene.
// The process-wide hooks are inert outside the validated lease and restore saved
// UIKit implementations; they never modify SpringBoard, CarPlay Dock, or Maps.
#import "DFYouTubeOrientationVirtualization.h"
#import "DFYouTubeHostState.h"
#import <objc/runtime.h>
#import <dlfcn.h>

typedef void (*DFYTMSHookMessageEx)(Class,SEL,IMP,IMP *);
static UIInterfaceOrientationMask (*DFYTOrigSupported)(UIViewController *,SEL);
static UIInterfaceOrientationMask (*DFYTOrigInternalSupported)(UIViewController *,SEL);
static UIInterfaceOrientation (*DFYTOrigSceneOrientation)(UIWindowScene *,SEL);
static UIDeviceOrientation (*DFYTOrigDeviceOrientation)(UIDevice *,SEL);
static void (*DFYTOrigWindowRotate)(UIWindow *,SEL,NSInteger,BOOL,double,BOOL);
static void (*DFYTOrigWindowRotatable)(UIWindow *,SEL,NSInteger,double,BOOL);

static __weak UIWindowScene *DFYTLeasedScene;
static NSTimeInterval DFYTLeaseDeadline;
static NSInteger DFYTLeaseOrientation;
static BOOL DFYTLeaseIsSplit;
static NSUInteger DFYTInstalledHooks;
static BOOL DFYTInstallAttempted;
static NSString *DFYTInstallPhase;

static BOOL DFYTOwnedLease(void) {
    // UIKit orientation queries are main-thread state. For background callers
    // use the original UIKit method instead of racing a mutable scene lease.
    if(!NSThread.isMainThread || !DFYTLeasedScene)return NO;
    if(DFYTLeaseOrientation!=UIInterfaceOrientationPortrait)return NO;
    return NSDate.date.timeIntervalSince1970<=DFYTLeaseDeadline;
}
static BOOL DFYTWindowIsOwned(UIWindow *window) {
    return DFYTOwnedLease() && window.windowScene==DFYTLeasedScene &&
        !window.hidden && window.windowLevel<=UIWindowLevelNormal;
}
// Derived from the ORIGINAL 0x2acc04 and 0x2acc60 branches:
// active => 1 << max(requestedOrientation,1); inactive => saved original IMP.
static UIInterfaceOrientationMask DFYTSupported(UIViewController *controller,SEL cmd) {
    if(DFYTOwnedLease())return UIInterfaceOrientationMaskPortrait;
    return DFYTOrigSupported?DFYTOrigSupported(controller,cmd):UIInterfaceOrientationMaskAll;
}
static UIInterfaceOrientationMask DFYTInternalSupported(UIViewController *controller,SEL cmd) {
    if(DFYTOwnedLease())return UIInterfaceOrientationMaskPortrait;
    return DFYTOrigInternalSupported?DFYTOrigInternalSupported(controller,cmd):UIInterfaceOrientationMaskAll;
}
// ORIGINAL UIWindowScene.interfaceOrientation 0x2ad7f0 is a bridge-gated
// getter; restrict the first-party behavior further to the owned scene.
static UIInterfaceOrientation DFYTSceneOrientation(UIWindowScene *scene,SEL cmd) {
    if(DFYTOwnedLease() && scene==DFYTLeasedScene)return UIInterfaceOrientationPortrait;
    return DFYTOrigSceneOrientation?DFYTOrigSceneOrientation(scene,cmd):UIInterfaceOrientationUnknown;
}
// ORIGINAL UIDevice.orientation 0x2ad8d0 answers requested orientation while
// bridged, but returns original outside. Only the YouTube process is injected.
static UIDeviceOrientation DFYTDeviceOrientation(UIDevice *device,SEL cmd) {
    if(DFYTOwnedLease())return UIDeviceOrientationPortrait;
    return DFYTOrigDeviceOrientation?DFYTOrigDeviceOrientation(device,cmd):UIDeviceOrientationUnknown;
}
// ORIGINAL 0x2acfd8 intercepts FUTURE UIKit window rotation calls and replaces
// requested orientation. .89 only invoked one initial rotation, so later
// YouTube fullscreen / control-surface events could undo it.
static void DFYTWindowRotate(UIWindow *window,SEL cmd,NSInteger orientation,
                             BOOL statusBar,double duration,BOOL skipCallbacks) {
    if(DFYTWindowIsOwned(window))orientation=UIInterfaceOrientationPortrait;
    if(DFYTOrigWindowRotate)
        DFYTOrigWindowRotate(window,cmd,orientation,statusBar,duration,skipCallbacks);
}
// ORIGINAL 0x2acef4 also substitutes the requested orientation and forces the
// "force" flag during bridge, then forwards to saved UIKit implementation.
static void DFYTWindowRotatable(UIWindow *window,SEL cmd,NSInteger orientation,
                                double duration,BOOL force) {
    if(DFYTWindowIsOwned(window)) {
        orientation=UIInterfaceOrientationPortrait;
        force=YES;
    }
    if(DFYTOrigWindowRotatable)
        DFYTOrigWindowRotatable(window,cmd,orientation,duration,force);
}

static BOOL DFYTInstallOne(DFYTMSHookMessageEx hook,Class cls,NSString *name,
                            IMP callback,IMP *saved,NSUInteger args,
                            char resultType) {
    if(!cls || !hook || !saved)return NO;
    SEL sel=NSSelectorFromString(name);
    Method method=class_getInstanceMethod(cls,sel);
    if(!method || method_getNumberOfArguments(method)!=args)return NO;
    char r[64]={0};
    method_getReturnType(method,r,sizeof(r));
    if(r[0]!=resultType)return NO;
    hook(cls,sel,callback,saved);
    return *saved!=NULL;
}
void DFYTVirtualInstall(void) {
    if(!NSThread.isMainThread || DFYTInstallAttempted)return;
    DFYTInstallAttempted=YES;
    DFYTInstallPhase=@"unavailable";
    if(![NSBundle.mainBundle.bundleIdentifier isEqual:DFYTBundle] ||
       NSProcessInfo.processInfo.operatingSystemVersion.majorVersion!=16)return;
    // ElleKit/Substrate compatibility is resolved at runtime. Absence is
    // reported, never silently replaced with unreviewed Objective-C swizzling.
    DFYTMSHookMessageEx hook=(DFYTMSHookMessageEx)dlsym(RTLD_DEFAULT,"MSHookMessageEx");
    if(!hook) {
        DFYTInstallPhase=@"MSHookMessageEx-symbol-unavailable";
        NSLog(@"[DuoFaceYouTube] first-party orientation hooks unavailable");
        return;
    }
    if(DFYTInstallOne(hook,UIViewController.class,@"supportedInterfaceOrientations",
         (IMP)DFYTSupported,(IMP *)&DFYTOrigSupported,2,'Q'))++DFYTInstalledHooks;
    if(DFYTInstallOne(hook,UIViewController.class,@"__supportedInterfaceOrientations",
         (IMP)DFYTInternalSupported,(IMP *)&DFYTOrigInternalSupported,2,'Q'))++DFYTInstalledHooks;
    if(DFYTInstallOne(hook,UIWindowScene.class,@"interfaceOrientation",
         (IMP)DFYTSceneOrientation,(IMP *)&DFYTOrigSceneOrientation,2,'q'))++DFYTInstalledHooks;
    if(DFYTInstallOne(hook,UIDevice.class,@"orientation",
         (IMP)DFYTDeviceOrientation,(IMP *)&DFYTOrigDeviceOrientation,2,'q'))++DFYTInstalledHooks;
    // Original was void, orientation integer, flag BOOL, duration double,
    // skipCallbacks BOOL. Check exact ABI before installing window intercepts.
    Class windowClass=UIWindow.class;
    Method rotate=class_getInstanceMethod(windowClass,
            NSSelectorFromString(@"_rotateWindowToOrientation:updateStatusBar:duration:skipCallbacks:"));
    if(rotate && method_getNumberOfArguments(rotate)==6) {
        char a[32]={0},c[32]={0},d[32]={0},e[32]={0};
        method_getArgumentType(rotate,2,a,sizeof(a));
        method_getArgumentType(rotate,3,c,sizeof(c));
        method_getArgumentType(rotate,4,d,sizeof(d));
        method_getArgumentType(rotate,5,e,sizeof(e));
        if((a[0]=='q'||a[0]=='i') && (c[0]=='B'||c[0]=='c') &&
           d[0]=='d' && (e[0]=='B'||e[0]=='c') &&
           DFYTInstallOne(hook,windowClass,
           @"_rotateWindowToOrientation:updateStatusBar:duration:skipCallbacks:",
           (IMP)DFYTWindowRotate,(IMP *)&DFYTOrigWindowRotate,6,'v'))
            ++DFYTInstalledHooks;
    }
    Method rotatable=class_getInstanceMethod(windowClass,
                        NSSelectorFromString(@"_setRotatableViewOrientation:duration:force:"));
    if(rotatable && method_getNumberOfArguments(rotatable)==5) {
        char a[32]={0},duration[32]={0},forced[32]={0};
        method_getArgumentType(rotatable,2,a,sizeof(a));
        method_getArgumentType(rotatable,3,duration,sizeof(duration));
        method_getArgumentType(rotatable,4,forced,sizeof(forced));
        if((a[0]=='q'||a[0]=='i') && duration[0]=='d' &&
           (forced[0]=='B'||forced[0]=='c') &&
           DFYTInstallOne(hook,windowClass,
              @"_setRotatableViewOrientation:duration:force:",
              (IMP)DFYTWindowRotatable,(IMP *)&DFYTOrigWindowRotatable,5,'v'))
            ++DFYTInstalledHooks;
    }
    DFYTInstallPhase=DFYTInstalledHooks?@"hooks-installed-ABI-checked":@"no-compatible-hooks";
    NSLog(@"[DuoFaceYouTube] original-ABI-backed first-party hooks installed %lu",
          (unsigned long)DFYTInstalledHooks);
}
void DFYTVirtualUpdateLease(NSDictionary *state,UIWindowScene *scene) {
    if(!NSThread.isMainThread)return;
    if(!scene || !DFYTValidState(state,NSDate.date.timeIntervalSince1970) ||
       ![state[@"active"] boolValue] ||
       ![state[@"orientation"] isEqual:@1] ||
       ![DFYTObject(scene,@"_sceneIdentifier") isEqual:state[@"sceneIdentifier"]]) {
        DFYTVirtualClearLease();return;
    }
    DFYTLeasedScene=scene;
    DFYTLeaseOrientation=[state[@"orientation"] integerValue];
    DFYTLeaseIsSplit=[state[@"isSplit"] boolValue];
    DFYTLeaseDeadline=[state[@"issuedAt"] doubleValue]+3.0;
}
void DFYTVirtualClearLease(void) {
    if(!NSThread.isMainThread)return;
    DFYTLeaseDeadline=0;
    DFYTLeaseOrientation=0;
    DFYTLeaseIsSplit=NO;
    DFYTLeasedScene=nil;
}
NSDictionary *DFYTVirtualSnapshot(void) {
    return @{
        @"phase":DFYTInstallPhase?:@"not-installed",
        @"hooks":@(DFYTInstalledHooks),
        @"leaseActive":@(DFYTOwnedLease()),
        @"split":@(DFYTLeaseIsSplit),
    };
}
