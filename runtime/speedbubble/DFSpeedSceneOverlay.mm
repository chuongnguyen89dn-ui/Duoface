// Native12 speed5scene: GOFA-style high UIWindow level bound ONLY to live DuoFace CBWindow.
// The code imports the already-used Speed4 HUD visuals/drag/data unchanged. Its CarPlayApp
// constructor is inert here; only this SpringBoard guarded lifecycle runs.
// Distinct file: Speed4 history and original Native12 remain immutable.
#import "DFSpeedBubbleBridge.mm"
#import <unistd.h>
#import <stdio.h>

// Same window technique as open-source GOFAHUD: independent, transparent UIWindow
// attached to the REAL host's scene, with card-only touch interception.
@interface DFSceneHUDWindow : UIWindow
@end
@implementation DFSceneHUDWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *card=[self.rootViewController.view viewWithTag:51412];
    if (!card || card.hidden) return nil;
    CGPoint local=[self convertPoint:point toView:card];
    if (![card pointInside:local withEvent:event]) return nil;
    return [super hitTest:point withEvent:event];
}
@end

static DFSceneHUDWindow *dfSceneOverlay=nil;
static __weak CBWindow *dfSceneOwner=nil;
static __weak UIWindow *dfSceneBase=nil;
static DFSpeedNativeHUD *dfSceneCard=nil;
static NSTimer *dfSceneTimer=nil;
static NSObject *dfSceneDriver=nil;
static IMP dfSceneOriginalShow=NULL;
static IMP dfSceneOriginalResize=NULL;
static IMP dfSceneOriginalDestroy=NULL;
static IMP dfSceneOriginalHide=NULL;
static BOOL dfSceneHooksReady=NO;
static NSString *dfSceneLastStatus=nil;
static NSTimeInterval dfSceneLastSnapshot=0;

static NSString *DFSceneLogFile(void) {
    return @"/var/mobile/Library/Logs/DuoFaceSpeedScene-SpringBoard.jsonl";
}
static void DFSceneLog(NSString *stage, CBWindow *bridge, UIWindow *base) {
    NSString *role=base.windowScene.session.role ?: @"nil";
    UIWindowScene *scene=base.windowScene;
    NSDictionary *line=@{
      @"time":@([[NSDate date] timeIntervalSince1970]),
      @"pid":@(getpid()),
      @"process":NSProcessInfo.processInfo.processName ?: @"nil",
      @"stage":stage ?: @"nil",
      @"cbwindow":bridge ? NSStringFromClass(bridge.class) : @"nil",
      @"visible":@(bridge && bridge.isVisible),
      @"root":base ? NSStringFromClass(base.class) : @"nil",
      @"windowHidden":@(base ? base.hidden : YES),
      @"windowAlpha":@(base ? base.alpha : 0),
      @"role":role,
      @"hasScene":@(scene!=nil),
      @"external":@(base && base.screen && base.screen!=UIScreen.mainScreen),
      @"frame":base ? NSStringFromCGRect(base.frame) : @"nil",
      @"overlayVisible":@(dfSceneOverlay && !dfSceneOverlay.hidden),
      @"hudVisible":@(dfSceneCard && !dfSceneCard.hidden),
    };
    NSData *json=[NSJSONSerialization dataWithJSONObject:line options:0 error:nil];
    if (!json) return;
    FILE *fp=fopen(DFSceneLogFile().fileSystemRepresentation,"a");
    if (!fp) {
        NSString *fallback=[NSTemporaryDirectory() stringByAppendingPathComponent:@"DuoFaceSpeedScene-SpringBoard.jsonl"];
        fp=fopen(fallback.fileSystemRepresentation,"a");
    }
    if (fp) { fwrite(json.bytes,1,json.length,fp); fputc('\n',fp); fclose(fp); }
    NSLog(@"[DuoFaceSpeedScene] %@",stage);
}
static void DFSceneState(NSString *state, CBWindow *bridge, UIWindow *root) {
    if (![dfSceneLastStatus isEqualToString:state]) {
        dfSceneLastStatus=[state copy]; DFSceneLog(state,bridge,root);
    }
}

static BOOL DFSceneValidBridge(CBWindow *bridge, UIWindow **rootOut) {
    if (rootOut) *rootOut=nil;
    if (!bridge || ![bridge isKindOfClass:NSClassFromString(@"CBWindow")]) return NO;
    if (!bridge.isVisible) return NO;
    UIWindow *base=bridge.rootWindow;
    if (![base isKindOfClass:UIWindow.class] || base.hidden || base.alpha<=0.01) return NO;
    if (!isfinite(base.bounds.size.width) || !isfinite(base.bounds.size.height) ||
        base.bounds.size.width<220 || base.bounds.size.height<120) return NO;
    NSString *role=base.windowScene.session.role;
    BOOL external=base.screen && base.screen!=UIScreen.mainScreen;
    BOOL carRole=[role rangeOfString:@"CarPlay" options:NSCaseInsensitiveSearch].location!=NSNotFound;
    if (!external && !carRole) return NO; // Never show on iPhone or generic Home.
    if (rootOut) *rootOut=base;
    return YES;
}
static void DFSceneUnmount(NSString *reason) {
    CBWindow *old=dfSceneOwner; UIWindow *base=dfSceneBase;
    [dfSceneCard stop];
    [dfSceneCard removeFromSuperview];
    dfSceneCard=nil;
    dfSceneOverlay.hidden=YES;
    dfSceneOverlay.rootViewController=nil;
    dfSceneOverlay=nil;
    dfSceneOwner=nil;
    dfSceneBase=nil;
    DFSceneState(reason,old,base);
}
static BOOL DFSceneHasSameTarget(CBWindow *bridge, UIWindow *base) {
    if (!dfSceneOverlay || dfSceneOwner!=bridge || dfSceneBase!=base) return NO;
    if (base.windowScene && dfSceneOverlay.windowScene!=base.windowScene) return NO;
    if (!base.windowScene && dfSceneOverlay.screen!=base.screen) return NO;
    return YES;
}
static void DFSceneMountIfEligible(CBWindow *bridge) {
    UIWindow *base=nil;
    if (!DFSceneValidBridge(bridge,&base)) {
        if (dfSceneOverlay) DFSceneUnmount(@"HIDDEN: no active DuoFace split root");
        else DFSceneState(@"WAIT: native split UIWindow missing, inactive or scene not CarPlay",bridge,
                          bridge ? bridge.rootWindow : nil);
        return;
    }
    if (dfSceneOverlay && !DFSceneHasSameTarget(bridge,base))
        DFSceneUnmount(@"RECREATE: native split scene/root changed");
    if (!dfSceneOverlay) {
        DFSceneHUDWindow *w=base.windowScene
          ? [[DFSceneHUDWindow alloc] initWithWindowScene:base.windowScene]
          : [[DFSceneHUDWindow alloc] initWithFrame:base.frame];
        if (!base.windowScene) w.screen=base.screen;
        w.backgroundColor=UIColor.clearColor;
        w.opaque=NO;
        w.windowLevel=10000000;
        UIViewController *vc=[UIViewController new];
        vc.view.backgroundColor=UIColor.clearColor;
        w.rootViewController=vc;
        DFSpeedNativeHUD *hud=[[DFSpeedNativeHUD alloc] initWithFrame:CGRectMake(0,0,142,64)];
        hud.tag=51412;
        hud.ownerBridge=bridge;
        [vc.view addSubview:hud];
        hud.bounds=CGRectMake(0,0,142,64);
        [hud restoreSavedPosition];
        dfSceneOwner=bridge;
        dfSceneBase=base;
        dfSceneOverlay=w;
        dfSceneCard=hud;
        DFSceneLog(@"MOUNT_REQUEST: GOFA-style scene UIWindow level 10000000",bridge,base);
    }
    dfSceneOverlay.frame=base.frame;
    dfSceneCard.ownerBridge=bridge;
    dfSceneOverlay.hidden=NO; // Never makeKeyAndVisible: keep native CarPlay focused.
    [dfSceneCard tick:nil];
    if (dfSceneOverlay.hidden || dfSceneCard.hidden)
        DFSceneState(@"WAIT: overlay or HUD hidden after mount",bridge,base);
    else
        DFSceneState(@"MOUNTED: GOFA-style overlay in live DuoFace scene",bridge,base);
}
static void DFSceneReconcile(void) {
    if (!NSThread.isMainThread) return;
    id manager=DFCurrentNativeOwner(); // SpringBoard native singleton (not CarPlayApp).
    CBWindow *bridge=[manager isKindOfClass:NSClassFromString(@"CBWindow")] ? manager : nil;
    if (!bridge) {
        if (dfSceneOverlay) DFSceneUnmount(@"HIDDEN: no native CBBridgeManager owner");
        else DFSceneState(@"WAIT: SpringBoard CBBridgeManager.window unavailable",nil,nil);
    } else {
        DFSceneMountIfEligible(bridge);
    }
    NSTimeInterval now=NSProcessInfo.processInfo.systemUptime;
    if (now-dfSceneLastSnapshot>=5) {
        dfSceneLastSnapshot=now;
        DFSceneLog(@"HEARTBEAT",bridge,bridge ? bridge.rootWindow:nil);
    }
}
static void DFSceneWrappedShow(id obj,SEL sel) {
    if (dfSceneOriginalShow) ((void(*)(id,SEL))dfSceneOriginalShow)(obj,sel);
    DFSceneReconcile();
}
static void DFSceneWrappedResize(id obj,SEL sel) {
    if (dfSceneOriginalResize) ((void(*)(id,SEL))dfSceneOriginalResize)(obj,sel);
    DFSceneReconcile();
}
static void DFSceneWrappedDestroy(id obj,SEL sel) {
    if (dfSceneOwner==obj) DFSceneUnmount(@"HIDDEN: native CBWindow destroyed");
    if (dfSceneOriginalDestroy) ((void(*)(id,SEL))dfSceneOriginalDestroy)(obj,sel);
}
static void DFSceneWrappedHide(id obj,SEL sel,id completion) {
    if (dfSceneOwner==obj) DFSceneUnmount(@"HIDDEN: native CBWindow hide");
    if (dfSceneOriginalHide) ((void(*)(id,SEL,id))dfSceneOriginalHide)(obj,sel,completion);
}
static void DFSceneInstallHooks(int attempts) {
    if (dfSceneHooksReady || !NSThread.isMainThread) return;
    Class cls=NSClassFromString(@"CBWindow");
    const char *image=cls ? class_getImageName(cls):NULL;
    if (cls && image && strstr(image,"DuoFaceDashboard.dylib")) {
        SEL selectors[]={@selector(show),@selector(resizeWindows),@selector(destroyWindows),@selector(hide:)};
        IMP wrappers[]={(IMP)DFSceneWrappedShow,(IMP)DFSceneWrappedResize,
                        (IMP)DFSceneWrappedDestroy,(IMP)DFSceneWrappedHide};
        IMP *originals[]={&dfSceneOriginalShow,&dfSceneOriginalResize,
                          &dfSceneOriginalDestroy,&dfSceneOriginalHide};
        Method list[4]={NULL,NULL,NULL,NULL};
        BOOL ready=YES;
        for (NSUInteger i=0;i<4;i++) {
            list[i]=class_getInstanceMethod(cls,selectors[i]);
            const char *actual=list[i]?method_getTypeEncoding(list[i]):NULL;
            const char *expected=(i==3)?"v24@0:8@?16":"v16@0:8";
            if (!actual || strcmp(actual,expected)!=0 ||
                method_getImplementation(list[i])==wrappers[i]) {ready=NO;break;}
        }
        if (ready) {
            for (NSUInteger i=0;i<4;i++)
                *originals[i]=method_getImplementation(list[i]);
            for (NSUInteger i=0;i<4;i++)
                method_setImplementation(list[i],wrappers[i]);
            dfSceneHooksReady=YES;
            DFSceneLog(@"HOOKED: SpringBoard Native12 CBWindow show/resize/destroy/hide",nil,nil);
            DFSceneReconcile();
            return;
        }
        if (attempts==0) DFSceneLog(@"WARN: Native12 CBWindow method ABI mismatch, no hooks installed",nil,nil);
    }
    if (attempts<30) dispatch_after(dispatch_time(DISPATCH_TIME_NOW,2*NSEC_PER_SEC),
            dispatch_get_main_queue(),^{ DFSceneInstallHooks(attempts+1); });
    else DFSceneLog(@"WARN: CBWindow hooks unavailable after retries",nil,nil);
}
@interface DFSceneDriver : NSObject
- (void)onTimer:(NSTimer *)timer;
- (void)visibleWindow:(NSNotification *)note;
@end
@implementation DFSceneDriver
- (void)onTimer:(NSTimer *)timer { (void)timer; DFSceneReconcile(); }
- (void)visibleWindow:(NSNotification *)note {
    if ([note.object isKindOfClass:DFSceneHUDWindow.class]) return;
    DFSceneReconcile();
}
@end
__attribute__((constructor)) static void DFSceneStartInSpringBoard(void) {
    @autoreleasepool {
        if (![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"]) return;
        dispatch_async(dispatch_get_main_queue(),^{
            DFSceneLog(@"LOADED: Speed5 scene module in SpringBoard",nil,nil);
            DFSceneInstallHooks(0);
            DFSceneDriver *driver=[DFSceneDriver new];
            dfSceneDriver=driver;
            dfSceneTimer=[NSTimer timerWithTimeInterval:0.5 target:driver
                             selector:@selector(onTimer:) userInfo:nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:dfSceneTimer forMode:NSRunLoopCommonModes];
            [[NSNotificationCenter defaultCenter] addObserver:driver
                    selector:@selector(visibleWindow:) name:UIWindowDidBecomeVisibleNotification object:nil];
            DFSceneReconcile();
        });
    }
}
