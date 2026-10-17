#import "DFIRuntime.h"
#import "DFCBCompat.h" // DuoFace Visual12 source-only CB façade; build -I replacement/cb-compat
#import "../DFILayouts.h"
#import "../shared/DFISettings.h"
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <unistd.h>
#import <mach/mach.h>
#import <mach/task_info.h>
#import <QuartzCore/QuartzCore.h>
#import "DFIPerformance.inc"

// Private entry points are checked before use. The evidence for each group is
// recorded in IMPLEMENTATION_EVIDENCE.md. No reference dylib is loaded here.
static id DFIGet(id object, NSString *name) {
    SEL selector=NSSelectorFromString(name);
    return [object respondsToSelector:selector] ? ((id(*)(id,SEL))objc_msgSend)(object,selector) : nil;
}
static id DFIObject(id object, NSString *name, id argument) {
    SEL selector=NSSelectorFromString(name);
    return [object respondsToSelector:selector] ? ((id(*)(id,SEL,id))objc_msgSend)(object,selector,argument) : nil;
}
static void DFISetObject(id object, NSString *name, id argument) {
    SEL selector=NSSelectorFromString(name);
    if([object respondsToSelector:selector]) ((void(*)(id,SEL,id))objc_msgSend)(object,selector,argument);
}
static void DFIBool(id object, NSString *name, BOOL argument) {
    SEL selector=NSSelectorFromString(name);
    if([object respondsToSelector:selector]) ((void(*)(id,SEL,BOOL))objc_msgSend)(object,selector,argument);
}
static void DFIInteger(id object, NSString *name, NSInteger argument) {
    SEL selector=NSSelectorFromString(name);
    if([object respondsToSelector:selector]) ((void(*)(id,SEL,NSInteger))objc_msgSend)(object,selector,argument);
}
static void DFIRect(id object, NSString *name, CGRect argument) {
    SEL selector=NSSelectorFromString(name);
    if([object respondsToSelector:selector]) ((void(*)(id,SEL,CGRect))objc_msgSend)(object,selector,argument);
}
static NSError *DFIError(NSString *message) {
    return [NSError errorWithDomain:DFIPreferences code:1 userInfo:@{NSLocalizedDescriptionKey:message}];
}
static void DFILog(NSString *message) {
    NSLog(@"DuoFaceVisual12 %@",message);
    if(![NSProcessInfo.processInfo.processName isEqual:@"SpringBoard"])return;
    static dispatch_queue_t queue;static dispatch_once_t once;
    dispatch_once(&once,^{queue=dispatch_queue_create("com.duoface.visual12.log",DISPATCH_QUEUE_SERIAL);});
    NSString *line=[NSString stringWithFormat:@"%@ %@\n",[NSDate date],message];
    dispatch_async(queue,^{@autoreleasepool{@try{
        NSString *dir=@"/var/mobile/Library/Logs",*path=[dir stringByAppendingPathComponent:@"DuoFaceVisual12-runtime.log"];
        NSFileManager *fm=NSFileManager.defaultManager;[fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        if([[fm attributesOfItemAtPath:path error:nil] fileSize]>2*1024*1024)[fm removeItemAtPath:path error:nil];
        if(![fm fileExistsAtPath:path])[fm createFileAtPath:path contents:nil attributes:@{NSFilePosixPermissions:@0644}];
        NSFileHandle *file=[NSFileHandle fileHandleForWritingAtPath:path];[file seekToEndOfFile];[file writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];[file closeFile];
    }@catch(NSException *e){NSLog(@"DuoFaceVisual12 log write: %@",e.reason);}}});
}
static id DFIPreference(NSString *key) {
    return CFBridgingRelease(CFPreferencesCopyAppValue((__bridge CFStringRef)key,(__bridge CFStringRef)DFIPreferences));
}
static void DFIWritePreference(NSString *key,id value) {
    CFPreferencesSetAppValue((__bridge CFStringRef)key,(__bridge CFPropertyListRef)value,(__bridge CFStringRef)DFIPreferences);
    CFPreferencesAppSynchronize((__bridge CFStringRef)DFIPreferences);
}
static NSMutableSet<NSString *> *DFIHostedBundles;
static NSMutableSet *DFIHostedScenes;
static NSMapTable *DFISceneGeometry;
static NSMapTable *DFIControllerGeometry;
static NSMapTable *DFIHandleOwners;
static UIWindow *DFIWindow;
static DFISplitController *DFIRoot;

@interface DFISceneHost ()
@property(nonatomic,copy,readwrite) NSString *bundleID;
@property(nonatomic,strong,readwrite) UIViewController *controller;
@property(nonatomic,strong,readwrite) id scene;
@property(nonatomic,strong) id entity;
@property(nonatomic,strong) id savedSettings;
@property(nonatomic,strong) id deviceController;
@property(nonatomic,strong) id handle;
@property(nonatomic,strong) NSHashTable *phoneViews;
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,copy) void (^ready)(void);
@property(nonatomic,weak) UIView *container;
@property(nonatomic) CGSize requestedSize;
@property(nonatomic) CGSize appliedSize;
@property(nonatomic) NSUInteger attempts;
@property(nonatomic) BOOL closed;
@end

@implementation DFISceneHost
- (instancetype)initWithBundleID:(NSString *)bundleID error:(NSError **)error {
    if(!(self=[super init])) return nil;
    _bundleID=[bundleID copy];
    @try {
        id applications=DFIGet(NSClassFromString(@"SBApplicationController"),@"sharedInstance");
        id application=DFIObject(applications,@"applicationWithBundleIdentifier:",bundleID);
        Class entityClass=NSClassFromString(@"SBDeviceApplicationSceneEntity");
        Class controllerClass=NSClassFromString(@"SBAppViewController");
        SEL entityInit=NSSelectorFromString(@"initWithApplicationForMainDisplay:");
        SEL controllerInit=NSSelectorFromString(@"initWithIdentifier:andApplicationSceneEntity:");
        if(!application || ![entityClass instancesRespondToSelector:entityInit] ||
           ![controllerClass instancesRespondToSelector:controllerInit] ||
           ![controllerClass instancesRespondToSelector:NSSelectorFromString(@"setRequestedMode:")] ||
           ![controllerClass instancesRespondToSelector:NSSelectorFromString(@"_setCurrentMode:")]) {
            if(error) *error=DFIError(@"Phiên bản iOS này thiếu API mở vùng ứng dụng.");
            return nil;
        }
        _entity=((id(*)(id,SEL,id))objc_msgSend)([entityClass alloc],entityInit,application);
        // SpringBoard uses this identifier to bind the controller to its app scene.
        _controller=((id(*)(id,SEL,id,id))objc_msgSend)([controllerClass alloc],controllerInit,
                       bundleID,_entity);
        if(!_entity || !_controller) {
            if(error) *error=DFIError(@"Không tạo được vùng ứng dụng.");
            return nil;
        }
        DFIBool(_controller,@"setIgnoresOcclusions:",NO);
        DFIBool(_controller,@"setAutomatesLifecycle:",NO);
        [_controller loadViewIfNeeded];
        _controller.view.backgroundColor=UIColor.blackColor;
        _controller.view.clipsToBounds=YES;
        _handle=DFIGet(_controller,@"sceneHandle");
        _savedSettings=[DFIGet(DFIGet(_handle,@"sceneIfExists"),@"settings") copy];
        _phoneViews=[NSHashTable weakObjectsHashTable];
    } @catch(NSException *exception) {
        if(error) *error=DFIError([NSString stringWithFormat:@"Không mở được ứng dụng: %@",exception.reason]);
        return nil;
    }
    return self;
}
- (void)attachTo:(UIViewController *)parent container:(UIView *)container {
    if(self.closed) return;
    self.container=container;
    [DFIHostedBundles addObject:self.bundleID];
    [parent addChildViewController:self.controller];
    [container addSubview:self.controller.view];
    [self.controller didMoveToParentViewController:parent];
    if(self.handle) @synchronized(DFIHostedScenes) { [DFIHandleOwners setObject:self forKey:self.handle]; }
    [self.controller beginAppearanceTransition:YES animated:NO];
    DFIInteger(self.controller,@"setRequestedMode:",2);
    [self.controller endAppearanceTransition];
    __weak typeof(self) weakSelf=self;
    self.timer=[NSTimer scheduledTimerWithTimeInterval:0.25 repeats:YES block:^(NSTimer *timer) {
        [weakSelf pollScene];
    }];
    [self pollScene];
}
- (void)pollScene {
    if(self.closed) return;
    @try {
        id handle=DFIGet(self.controller,@"sceneHandle");
        id scene=DFIGet(handle,@"sceneIfExists");
        if(scene) {
            if(!self.scene) {
                self.scene=scene;
                self.handle=handle;
                @synchronized(DFIHostedScenes) {
                    [DFIHostedScenes addObject:scene];
                    if(handle) [DFIHandleOwners setObject:self forKey:handle];
                }
                id layout=DFIGet(NSClassFromString(@"SBMainDisplaySceneLayoutViewController"),@"mainDisplaySceneLayoutViewController");
                for(id appController in DFIGet(layout,@"appViewControllers")) {
                    id sceneController=DFIGet(appController,@"_applicationSceneViewController");
                    id sceneView=DFIGet(sceneController,@"_sceneView");
                    if([DFIGet(sceneView,@"sceneHandle") isEqual:handle] && [sceneView window]!=DFIWindow) {
                        SEL mode=NSSelectorFromString(@"setDisplayMode:animationFactory:completion:");
                        if([sceneView respondsToSelector:mode]) {
                            [self.phoneViews addObject:sceneView];
                            ((void(*)(id,SEL,NSInteger,id,id))objc_msgSend)(sceneView,mode,1,nil,nil);
                        }
                    }
                }
                DFILog([NSString stringWithFormat:@"scene attached bundle=%@ class=%@",self.bundleID,NSStringFromClass([scene class])]);
                if(self.ready) self.ready();
            }
            if(!CGSizeEqualToSize(self.appliedSize,self.requestedSize)) [self applySize];
            return;
        }
        if(self.scene || ++self.attempts>48) {
            NSString *reason=self.scene ? @"Ứng dụng đã đóng. Chọn lại để mở." : @"Ứng dụng không tạo được màn hình. Chọn lại hoặc chọn ứng dụng khác.";
            void (^failure)(NSString *)=self.failure;
            [self close];
            if(failure) failure(reason);
        }
    } @catch(NSException *exception) {
        void (^failure)(NSString *)=self.failure;
        NSString *reason=[NSString stringWithFormat:@"Lỗi vùng ứng dụng: %@",exception.reason];
        [self close];
        if(failure) failure(reason);
    }
}
- (void)resizeTo:(CGSize)size {
    if(self.closed || size.width<=0 || size.height<=0 || !isfinite(size.width) || !isfinite(size.height)) return;
    if(CGSizeEqualToSize(self.requestedSize,size)) { DFIPerfCount(@"resize_skipped"); return; }
    DFIPerfCount(@"resize_applied");
    self.requestedSize=size;
    // Render at twice the pane's logical size, then scale uniformly. This keeps
    // text usable without stretching either axis and preserves UIKit hit testing.
    CGSize logical=CGSizeMake(round(size.width*2),round(size.height*2));
    NSInteger orientation=logical.width>=logical.height ? UIInterfaceOrientationLandscapeRight : UIInterfaceOrientationPortrait;
    @try {
        self.deviceController=[self.controller valueForKey:@"_deviceAppViewController"];
        if(self.deviceController) {
            @synchronized(DFIHostedScenes) {
                [DFIControllerGeometry setObject:@{@"size":[NSValue valueWithCGSize:logical],@"orientation":@(orientation)} forKey:self.deviceController];
            }
            SEL reference=NSSelectorFromString(@"setContentReferenceSize:withInterfaceOrientation:");
            SEL reference3=NSSelectorFromString(@"setContentReferenceSize:withContentOrientation:andContainerOrientation:");
            if([self.deviceController respondsToSelector:reference])
                ((void(*)(id,SEL,CGSize,NSInteger))objc_msgSend)(self.deviceController,reference,logical,orientation);
            else if([self.deviceController respondsToSelector:reference3])
                ((void(*)(id,SEL,CGSize,NSInteger,NSInteger))objc_msgSend)(self.deviceController,reference3,logical,orientation,orientation);
            DFIInteger(self.deviceController,@"setHomeGrabberDisplayMode:",1);
        }
    } @catch(NSException *exception) { DFILog(exception.reason); }
    UIView *view=self.controller.view;
    view.transform=CGAffineTransformIdentity;
    view.bounds=(CGRect){CGPointZero,logical};
    view.center=CGPointMake(size.width/2,size.height/2);
    view.transform=CGAffineTransformMakeScale(size.width/logical.width,size.height/logical.height);
    if(self.scene && !CGSizeEqualToSize(self.appliedSize,size)) [self applySize];
}
- (void)applySize {
    if(self.closed || !self.scene || self.requestedSize.width<=0) return;
    id settings=DFIGet(self.scene,@"mutableSettings");
    SEL update=NSSelectorFromString(@"updateSettings:withTransitionContext:completion:");
    if(!settings || ![settings respondsToSelector:NSSelectorFromString(@"setFrame:")] || ![self.scene respondsToSelector:update]) return;
    CGSize logical=CGSizeMake(round(self.requestedSize.width*2),round(self.requestedSize.height*2));
    DFIRect(settings,@"setFrame:",(CGRect){CGPointZero,logical});
    DFIInteger(settings,@"setInterfaceOrientation:",logical.width>=logical.height ? UIInterfaceOrientationLandscapeRight : UIInterfaceOrientationPortrait);
    DFIBool(settings,@"setForeground:",YES);
    DFIBool(settings,@"setBackgrounded:",NO);
    @synchronized(DFIHostedScenes) {
        [DFISceneGeometry setObject:@{@"frame":[NSValue valueWithCGRect:(CGRect){CGPointZero,logical}],
            @"orientation":@(logical.width>=logical.height ? UIInterfaceOrientationLandscapeRight : UIInterfaceOrientationPortrait)} forKey:self.scene];
    }
    ((void(*)(id,SEL,id,id,id))objc_msgSend)(self.scene,update,settings,nil,nil);
    self.appliedSize=self.requestedSize;
    DFIPerfCount(@"scene_updates");
}
- (void)close {
    if(self.closed) return;
    self.closed=YES;
    [self.timer invalidate]; self.timer=nil;
    [DFIHostedBundles removeObject:self.bundleID];
    if(self.scene) @synchronized(DFIHostedScenes) {
        [DFIHostedScenes removeObject:self.scene]; [DFISceneGeometry removeObjectForKey:self.scene];
    }
    if(self.deviceController) @synchronized(DFIHostedScenes) { [DFIControllerGeometry removeObjectForKey:self.deviceController]; }
    if(self.handle) @synchronized(DFIHostedScenes) { [DFIHandleOwners removeObjectForKey:self.handle]; }
    @try {
        [self.controller willMoveToParentViewController:nil];
        [self.controller beginAppearanceTransition:NO animated:NO];
        // setRequestedMode: queues an asynchronous transition. Releasing the
        // controller during that transition triggers SBAppViewController's
        // dealloc assertion on iOS 16.7.16. Reset the actual mode first.
        DFIInteger(self.controller,@"_setCurrentMode:",0);
        [self.controller endAppearanceTransition];
        [self.controller.view removeFromSuperview];
        [self.controller removeFromParentViewController];
        SEL update=NSSelectorFromString(@"updateSettings:withTransitionContext:completion:");
        id restore=self.savedSettings ? [self.savedSettings mutableCopy] : DFIGet(self.scene,@"mutableSettings");
        if(restore && [self.scene respondsToSelector:update]) {
            id frontmost=DFIGet(UIApplication.sharedApplication,@"_accessibilityFrontMostApplication");
            BOOL active=[DFIGet(frontmost,@"bundleIdentifier") isEqualToString:self.bundleID];
            DFIBool(restore,@"setForeground:",active); DFIBool(restore,@"setBackgrounded:",!active);
            if(!self.savedSettings) {
                CGRect bounds=UIScreen.mainScreen.bounds;
                DFIRect(restore,@"setFrame:",bounds);
                DFIInteger(restore,@"setInterfaceOrientation:",bounds.size.width>bounds.size.height ? UIInterfaceOrientationLandscapeRight : UIInterfaceOrientationPortrait);
            }
            ((void(*)(id,SEL,id,id,id))objc_msgSend)(self.scene,update,restore,nil,nil);
        }
        SEL mode=NSSelectorFromString(@"setDisplayMode:animationFactory:completion:");
        for(id view in self.phoneViews) if([view respondsToSelector:mode])
            ((void(*)(id,SEL,NSInteger,id,id))objc_msgSend)(view,mode,4,nil,nil);
    } @catch(NSException *exception) { DFILog(exception.reason); }
    self.controller=nil; self.entity=nil; self.scene=nil; self.savedSettings=nil; self.deviceController=nil; self.handle=nil;
    [self.phoneViews removeAllObjects];
}
- (void)dealloc { [self.timer invalidate]; }
@end

#include "DFIChrome.inc"
#include "DFIInterface.inc"

static id DFICarDisplay(void) {
    id external=DFIGet(NSClassFromString(@"AVExternalDevice"),@"currentCarPlayExternalDevice");
    NSArray *screenIDs=DFIGet(external,@"screenIDs");
    if(!screenIDs.count) return nil;
    for(id display in DFIGet(NSClassFromString(@"CADisplay"),@"displays")) {
        if([screenIDs containsObject:DFIGet(display,@"uniqueId")]) return display;
    }
    return nil;
}
static void DFIStop(void) {
    // Unbind the facade BEFORE the actual host tears down its scenes.
    if(DFIWindow) DFCBUnbindHost(DFIWindow);
    DFIChromeSetZoom(NO);
    DFIPerfMark(@"split_stop",nil);
    DFIPerfStop();
    [DFIRoot shutdown];
    DFIWindow.hidden=YES; DFIWindow.rootViewController=nil;
    DFIRoot=nil; DFIWindow=nil;
    notify_post("com.duoface.visual12.stopped");
    DFILog(@"split dismissed; original Dashboard exposed");
}
static void DFIStart(void) {
    if(!DFIEnabled())return;
    // Fail closed when an existing legacy CarPlay host owns its runtime.
    // Package IDs alone do not isolate SpringBoard scene ownership.
    if(NSClassFromString(@"CBBridgeManager")) {
        DFILog(@"legacy CarPlay scene owner loaded; standalone start refused");
        notify_post("com.duoface.visual12.unavailable");
        return;
    }
    if(DFIWindow) { notify_post("com.duoface.visual12.started"); return; }
    @try {
        id display=DFICarDisplay();
        Class configClass=NSClassFromString(@"FBSDisplayConfiguration"), windowClass=NSClassFromString(@"UIRootSceneWindow");
        SEL configInit=NSSelectorFromString(@"initWithCADisplay:isMainDisplay:"),windowInit=NSSelectorFromString(@"initWithDisplayConfiguration:");
        if(!display || ![configClass instancesRespondToSelector:configInit] || ![windowClass instancesRespondToSelector:windowInit]) {
            DFILog(@"cannot start: CarPlay display or window API unavailable");
            notify_post("com.duoface.visual12.unavailable"); return;
        }
        id config=((id(*)(id,SEL,id,BOOL))objc_msgSend)([configClass alloc],configInit,display,NO);
        UIWindow *window=((id(*)(id,SEL,id))objc_msgSend)([windowClass alloc],windowInit,config);
        if(!window || CGRectIsEmpty(window.bounds)) { DFILog(@"empty external window"); return; }
        DFIRoot=[DFISplitController new]; DFIWindow=window;
        window.windowLevel=UIWindowLevelAlert+100;
        window.backgroundColor=UIColor.blackColor;
        window.rootViewController=DFIRoot;
        window.hidden=NO;
        // Bind the already-created owner: never create another scene/window.
        NSError *hostError=nil;
        if(!DFCBBindHost(window, DFIRoot, &hostError)) {
            DFILog([NSString stringWithFormat:@"CB facade bind failed: %@",hostError.localizedDescription]);
            DFIStop();
            notify_post("com.duoface.visual12.unavailable");
            return;
        }
        DFIPerfStart(); DFIPerfMark(@"split_start",@{@"bounds":NSStringFromCGRect(window.bounds)});
        DFIWritePreference(@"displayInfo",[NSString stringWithFormat:@"%@ pt\nscale %.2f\n%@",NSStringFromCGRect(window.bounds),window.screen.scale,UIDevice.currentDevice.systemVersion]);
        notify_post("com.duoface.visual12.started");
        DFILog([NSString stringWithFormat:@"split window visible bounds=%@",NSStringFromCGRect(window.bounds)]);
    } @catch(NSException *exception) { DFILog(exception.reason); DFIStop(); }
}

static BOOL DFIConnected;
static NSUInteger DFIConnectionGeneration;
static void DFIConnectionChanged(void) {
    BOOL connected=DFICarDisplay()!=nil;if(connected==DFIConnected)return;
    DFIConnected=connected;NSUInteger generation=++DFIConnectionGeneration;
    DFILog(connected?@"CarPlay connected":@"CarPlay disconnected");
    if(connected){if(DFIEnabled()&&[DFIPref(@"autoStart")boolValue])DFIStart();return;}
    NSArray *managed=DFIManaged.allObjects;DFIStop();
    if(![DFIPref(@"closeDisconnect")boolValue])return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,12*NSEC_PER_SEC),dispatch_get_main_queue(),^{
        if(generation!=DFIConnectionGeneration||DFICarDisplay()||![DFIPref(@"closeDisconnect")boolValue])return;
        for(NSString *bid in managed)DFITerminate(bid,nil,^(NSString *status){DFILog([NSString stringWithFormat:@"disconnect cleanup %@: %@",bid,status]);});
    });
}

static void (*DFIOriginalUpdate)(id,SEL,id,id,id);
static void DFIUpdate(id scene,SEL selector,id settings,id context,id completion) {
    BOOL hosted=NO; NSDictionary *geometry=nil;
    @synchronized(DFIHostedScenes) { hosted=[DFIHostedScenes containsObject:scene]; geometry=[DFISceneGeometry objectForKey:scene]; }
    if(hosted) {
        @try {
            id copy=[settings mutableCopy];
            DFIBool(copy,@"setForeground:",YES); DFIBool(copy,@"setBackgrounded:",NO);
            if(geometry) {
                DFIRect(copy,@"setFrame:",[geometry[@"frame"] CGRectValue]);
                DFIInteger(copy,@"setInterfaceOrientation:",[geometry[@"orientation"] integerValue]);
            }
            settings=copy ?: settings;
        } @catch(NSException *e) { DFILog(e.reason); }
    }
    DFIOriginalUpdate(scene,selector,settings,context,completion);
}
static int (*DFIOriginalLock)(id,SEL,id,id);
static int DFILock(id object,SEL selector,id scene,id settings) {
    @synchronized(DFIHostedScenes) { if([DFIHostedScenes containsObject:scene]) return 0; }
    return DFIOriginalLock(object,selector,scene,settings);
}
static void (*DFIOriginalDisplayMode)(id,SEL,NSInteger,id,id);
static void DFIDisplayMode(id view,SEL selector,NSInteger mode,id animation,id completion) {
    id handle=DFIGet(view,@"sceneHandle"); DFISceneHost *host=nil;
    if(handle) @synchronized(DFIHostedScenes) { host=[DFIHandleOwners objectForKey:handle]; }
    if(host && mode==4 && [view window]!=DFIWindow) {
        [host.phoneViews addObject:view]; mode=1;
    }
    DFIOriginalDisplayMode(view,selector,mode,animation,completion);
}
static void (*DFIOriginalReference)(id,SEL,CGSize,NSInteger);
static void DFIReference(id object,SEL selector,CGSize size,NSInteger orientation) {
    NSDictionary *geometry;
    @synchronized(DFIHostedScenes) { geometry=[DFIControllerGeometry objectForKey:object]; }
    if(geometry) { size=[geometry[@"size"] CGSizeValue]; orientation=[geometry[@"orientation"] integerValue]; }
    DFIOriginalReference(object,selector,size,orientation);
}
static void (*DFIOriginalReference3)(id,SEL,CGSize,NSInteger,NSInteger);
static void DFIReference3(id object,SEL selector,CGSize size,NSInteger content,NSInteger container) {
    NSDictionary *geometry;
    @synchronized(DFIHostedScenes) { geometry=[DFIControllerGeometry objectForKey:object]; }
    if(geometry) { size=[geometry[@"size"] CGSizeValue]; content=[geometry[@"orientation"] integerValue]; container=content; }
    DFIOriginalReference3(object,selector,size,content,container);
}
static BOOL DFIHook(Class cls,SEL selector,IMP replacement,IMP *original) {
    Method method=class_getInstanceMethod(cls,selector);
    if(!method) return NO;
    *original=method_getImplementation(method);
    if(!class_addMethod(cls,selector,replacement,method_getTypeEncoding(method))) method_setImplementation(method,replacement);
    return YES;
}
// CarPlay owns its own launcher process on iOS 16. Add only our app to its
// library. Selecting that icon signals SpringBoard to open the external UI;
// the iPhone application never needs to be launched.
static id (*DFIOriginalNewCarLibrary)(id,SEL);
static id DFINewCarLibrary(id cls,SEL selector) {
    id library=DFIOriginalNewCarLibrary(cls,selector);
    @try {
        NSString *bundle=DFIPreferences;
        id app=DFIObject(library,@"applicationInfoForBundleIdentifier:",bundle);
        if(!app) {
            id proxy=DFIObject(NSClassFromString(@"LSApplicationProxy"),@"applicationProxyForIdentifier:",bundle);
            SEL add=NSSelectorFromString(@"addApplicationProxy:withOverrideURL:");
            if(proxy && [library respondsToSelector:add]) {
                ((void(*)(id,SEL,id,id))objc_msgSend)(library,add,proxy,nil);
                app=DFIObject(library,@"applicationInfoForBundleIdentifier:",bundle);
            }
        }
        Ivar declarationIvar=class_getInstanceVariable([app class],"_carPlayDeclaration");
        Class declarationClass=NSClassFromString(@"CRCarPlayAppDeclaration");
        if(app && declarationIvar && declarationClass && !object_getIvar(app,declarationIvar)) {
            id declaration=[declarationClass new];
            DFIBool(declaration,@"setSupportsTemplates:",NO);
            DFIBool(declaration,@"setSupportsMaps:",YES);
            DFISetObject(declaration,@"setBundleIdentifier:",bundle);
            DFISetObject(declaration,@"setBundlePath:",DFIGet(app,@"bundleURL"));
            object_setIvar(app,declarationIvar,declaration);
            DFILog(@"registered launcher icon in CarPlay");
        } else if(!app || !declarationIvar || !declarationClass) {
            DFILog(@"CarPlay launcher registration API unavailable");
        }
    } @catch(NSException *exception) { DFILog([NSString stringWithFormat:@"launcher registration: %@",exception.reason]); }
    return library;
}
static id (*DFIOriginalCarLaunch)(id,SEL,id,id);
static id DFICarLaunch(id cls,SEL selector,id application,id settings) {
    NSString *bundle=DFIGet(application,@"bundleIdentifier");
    if([bundle isEqualToString:DFIPreferences]) {
        DFILog(@"launcher icon tapped; requesting external split");
        notify_post(DFIStartNotification);
        return nil;
    }
    return DFIOriginalCarLaunch(cls,selector,application,settings);
}
static void DFIInstallCarLauncher(void) {
    Class libraryClass=NSClassFromString(@"CARApplication");
    Class launchClass=NSClassFromString(@"CARApplicationLaunchInfo");
    if(!DFIOriginalNewCarLibrary)
        DFIHook(object_getClass(libraryClass),NSSelectorFromString(@"_newApplicationLibrary"),(IMP)DFINewCarLibrary,(IMP *)&DFIOriginalNewCarLibrary);
    if(!DFIOriginalCarLaunch)
        DFIHook(object_getClass(launchClass),NSSelectorFromString(@"launchInfoForApplication:withActivationSettings:"),(IMP)DFICarLaunch,(IMP *)&DFIOriginalCarLaunch);
}
@interface DFIHomeGestureTarget : NSObject
- (void)hold:(UILongPressGestureRecognizer *)gesture;
@end
@implementation DFIHomeGestureTarget
- (void)hold:(UILongPressGestureRecognizer *)gesture {
    if(gesture.state==UIGestureRecognizerStateBegan) notify_post(DFIStartNotification);
}
@end
static DFIHomeGestureTarget *DFIGestureTarget;
static char DFIGestureKey;
static void DFIAttachGesture(UIView *view) {
    if(!view.window || objc_getAssociatedObject(view,&DFIGestureKey)) return;
    UILongPressGestureRecognizer *hold=[[UILongPressGestureRecognizer alloc] initWithTarget:DFIGestureTarget action:@selector(hold:)];
    hold.minimumPressDuration=0.75;
    [view addGestureRecognizer:hold];
    objc_setAssociatedObject(view,&DFIGestureKey,hold,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
static void (*DFIOriginalDBMove)(id,SEL);
static void DFIDBMove(id view,SEL selector) { DFIOriginalDBMove(view,selector); DFIAttachGesture(view); }
static void (*DFIOriginalCARMove)(id,SEL);
static void DFICARMove(id view,SEL selector) { DFIOriginalCARMove(view,selector); DFIAttachGesture(view); }
static void DFIInstallHomeGesture(void) {
    if(!DFIOriginalDBMove) DFIHook(NSClassFromString(@"DBStatusBarHomeButton"),@selector(didMoveToWindow),(IMP)DFIDBMove,(IMP *)&DFIOriginalDBMove);
    if(!DFIOriginalCARMove) DFIHook(NSClassFromString(@"CARStatusBarHomeButton"),@selector(didMoveToWindow),(IMP)DFICARMove,(IMP *)&DFIOriginalCARMove);
}
void DFIInstallRuntime(void) {
    NSString *process=NSProcessInfo.processInfo.processName;
    if([process isEqualToString:@"SpringBoard"]) {
        DFIHostedBundles=[NSMutableSet set]; DFIHostedScenes=[NSMutableSet set];
        DFIManaged=[NSMutableSet set];DFITerminating=[NSMutableSet set];
        dlopen("/System/Library/PrivateFrameworks/RunningBoardServices.framework/RunningBoardServices",RTLD_LAZY);
        dlopen("/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices",RTLD_LAZY);
        DFIStateMonitor=[NSClassFromString(@"BKSApplicationStateMonitor") new];
        DFISceneGeometry=[NSMapTable strongToStrongObjectsMapTable];
        DFIControllerGeometry=[NSMapTable weakToStrongObjectsMapTable];
        DFIHandleOwners=[NSMapTable strongToWeakObjectsMapTable];
        DFIHook(NSClassFromString(@"SBDeviceApplicationSceneView"),NSSelectorFromString(@"setDisplayMode:animationFactory:completion:"),(IMP)DFIDisplayMode,(IMP *)&DFIOriginalDisplayMode);
        Class sceneController=NSClassFromString(@"SBDeviceApplicationSceneViewController");
        DFIHook(sceneController,NSSelectorFromString(@"setContentReferenceSize:withInterfaceOrientation:"),(IMP)DFIReference,(IMP *)&DFIOriginalReference);
        DFIHook(sceneController,NSSelectorFromString(@"setContentReferenceSize:withContentOrientation:andContainerOrientation:"),(IMP)DFIReference3,(IMP *)&DFIOriginalReference3);
        DFIHook(NSClassFromString(@"FBScene"),NSSelectorFromString(@"updateSettings:withTransitionContext:completion:"),(IMP)DFIUpdate,(IMP *)&DFIOriginalUpdate);
        DFIHook(NSClassFromString(@"SBSuspendedUnderLockManager"),NSSelectorFromString(@"_shouldBeBackgroundUnderLockForScene:withSettings:"),(IMP)DFILock,(IMP *)&DFIOriginalLock);
        static int startToken,stopToken;
        notify_register_dispatch(DFIStartNotification,&startToken,dispatch_get_main_queue(),^(int token) { DFIStart(); });
        notify_register_dispatch(DFIStopNotification,&stopToken,dispatch_get_main_queue(),^(int token) { DFIStop(); });
        static int preferenceToken;
        notify_register_dispatch(DFIChanged,&preferenceToken,dispatch_get_main_queue(),^(int token){
            CFPreferencesAppSynchronize((__bridge CFStringRef)DFIPreferences);
            if(!DFIEnabled()){DFIStop();return;}
            if(DFIWindow && [DFIPref(@"perfEnabled") boolValue]) DFIPerfStart(); else DFIPerfStop();
        });
        for(NSString *name in @[@"CarPlayIsConnectedDidChange",UIScreenDidConnectNotification,UIScreenDidDisconnectNotification])
            [[NSNotificationCenter defaultCenter] addObserverForName:name object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note){DFIConnectionChanged();}];
        // Some heads advertise their display after UIScreen notification. Poll only connection identity.
        [NSTimer scheduledTimerWithTimeInterval:2 repeats:YES block:^(NSTimer *t){DFIConnectionChanged();}];
        DFIConnectionChanged();
    } else if([process isEqualToString:@"CarPlay"]) {
        DFIChromeInstall();
        DFIInstallCarLauncher();
        DFIGestureTarget=[DFIHomeGestureTarget new];
        DFIInstallHomeGesture();
        __block NSUInteger attempts=0;
        [NSTimer scheduledTimerWithTimeInterval:2 repeats:YES block:^(NSTimer *timer) {
            DFIInstallHomeGesture(); if(++attempts>=15) [timer invalidate];
        }];
    }
}
__attribute__((constructor)) static void DFIInitialize(void) {
    @autoreleasepool {
        if([NSProcessInfo.processInfo.processName isEqualToString:@"CarPlay"])
            DFIInstallRuntime();
        else dispatch_async(dispatch_get_main_queue(), ^{ DFIInstallRuntime(); });
    }
}
