#import "DFSPNativeDock.h"
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <math.h>

// Source-owned Native12 CBWindow +carPlayContentInsets and
// +carPlayUsableBounds use the display's own usable region (left 64pt
// in iOS16 left-dock layout). Adapt that policy to the SidePlay-owned
// external window WITHOUT importing CBWindow/CBBridgeManager/license code.
// Use actual UIKit insets if CarPlay gives a driver-side dock inset; if
// it only reports a top/zero inset, reserve the Native12 driver-side strip.
CGRect DFSPNativeDockUsableBounds(UIWindow *window) {
    if (!window || !window.screen || window.screen==UIScreen.mainScreen)
        return CGRectNull;
    CGRect all=window.bounds;
    if (!isfinite(all.origin.x) || !isfinite(all.origin.y) ||
        !isfinite(all.size.width) || !isfinite(all.size.height) ||
        all.size.width<=100 || all.size.height<=100)return CGRectNull;
    UIEdgeInsets insets=window.safeAreaInsets;
    if (!isfinite(insets.top)||!isfinite(insets.left)||
        !isfinite(insets.bottom)||!isfinite(insets.right)||
        insets.top<0||insets.left<0||insets.bottom<0||insets.right<0)
        insets=UIEdgeInsetsZero;
    // Native12 fixed 64pt left inset when a CarPlay dock inset is not
    // supplied. Respect right/bottom anchored docks if UIKit reports one.
    if (insets.left<32 && insets.right<32 && insets.bottom<32)
        insets.left=64.0;
    CGRect usable=UIEdgeInsetsInsetRect(all,insets);
    if (!isfinite(usable.origin.x) || !isfinite(usable.origin.y) ||
        !isfinite(usable.size.width) || !isfinite(usable.size.height) ||
        usable.size.width<=100 || usable.size.height<=100 ||
        !CGRectContainsRect(all,usable))return CGRectNull;
    return usable;
}

// Native12 DuoFaceDashboard.dylib imports the actual Apple App Dock
// controller classes DBAppDockViewController / CARAppDockViewController
// (verified in hash-pinned Native12 Mach-O strings). QA10 only hooked the
// STATUS BAR, hence did not target the left app-icon Dock at all.
// QA11 observes these real UIKit controllers; no imitation icons or
// dependencies on the license-coupled CBBridgeManager.
// Port of the SOURCE-OWNED Native12 DashboardChrome behavior:
// observe the actual DBStatusBarWindow/CARStatusBarWindow, snapshot original
// hidden state, restore it on teardown. The original Native12 host does not
// create a dock UIView. iOS CarPlay supplies the entire icon/status strip.
// No CBBridgeManager, licensing, vendor binary, or fake dock UI is imported.
//
// Native12 statusbar behavior: Normal restores ORIGINAL state, Zoom hides.
// Separately restore/show the genuine DB/CAR AppDockViewController in Normal.
// Statusbar ACK alone does NOT prove app dock icons exist.
// Darwin signals are name-only, and are never interpreted as visual proof.
static CFStringRef const DFSPDockNormal = CFSTR("com.duoface.qa10.nativedock.v1.normal");
static CFStringRef const DFSPDockZoom = CFSTR("com.duoface.qa10.nativedock.v1.zoom");
static CFStringRef const DFSPDockDetach = CFSTR("com.duoface.qa10.nativedock.v1.detach");
static CFStringRef const DFSPDockAckNormal = CFSTR("com.duoface.qa10.nativedock.v1.ack.normal");
static CFStringRef const DFSPDockAckZoom = CFSTR("com.duoface.qa10.nativedock.v1.ack.zoom");
static CFStringRef const DFSPDockAckMissing = CFSTR("com.duoface.qa10.nativedock.v1.ack.missing");
static CFStringRef const DFSPDockAckDetach = CFSTR("com.duoface.qa10.nativedock.v1.ack.detach");

static NSHashTable<UIWindow *> *DFSPDockWindows;
static NSMapTable<UIWindow *,NSNumber *> *DFSPDockOriginalHidden;
static BOOL DFSPDockRequested=NO, DFSPDockZoomRequested=NO;
static BOOL DFSPDockApplying=NO, DFSPDockHookReady=NO;
static BOOL DFSPAppDockHookReady=NO;
static NSHashTable<UIViewController *> *DFSPAppDockControllers;
static NSMapTable<UIView *, NSDictionary *> *DFSPAppDockSnapshots;
static NSUInteger DFSPDockAckCount=0,DFSPDockRequestSerial=0;
static NSUInteger DFSPDockLastWindowCount=NSUIntegerMax;
static NSUInteger DFSPDockLastAppCount=NSUIntegerMax;
static void DFSPDockAck(NSString *reason);
static NSInteger DFSPDockLastVisible=-1,DFSPDockLastOK=-1;
static char DFSPDockObserverKey;

@interface DBStatusBarWindow : UIWindow @end
@interface CARStatusBarWindow : UIWindow @end
@interface DBAppDockViewController : UIViewController @end
@interface CARAppDockViewController : UIViewController @end

static void DFSPDockLog(NSString *message, BOOL store) {
    NSLog(@"[DuoFaceNativeDock] %@",message);
    if (!store)return;
    @try {
        NSString *directory=@"/var/mobile/Library/Logs";
        [[NSFileManager defaultManager] createDirectoryAtPath:directory
                    withIntermediateDirectories:YES attributes:nil error:NULL];
        NSString *file=[directory stringByAppendingPathComponent:@"DuoFaceSidePlayDisplayQA.log"];
        NSData *line=[[NSString stringWithFormat:@"%@ NATIVE_DOCK %@\n",
             [NSDate date],message] dataUsingEncoding:NSUTF8StringEncoding];
        NSFileHandle *out=[NSFileHandle fileHandleForWritingAtPath:file];
        if (out) {
            [out seekToEndOfFile];[out writeData:line];[out closeFile];
        } else {
            [line writeToFile:file atomically:YES];
        }
    } @catch (NSException *ignored) { (void)ignored; }
}
static void DFSPDockPost(CFStringRef name) {
    CFNotificationCenterRef center=CFNotificationCenterGetDarwinNotifyCenter();
    if (center && name) CFNotificationCenterPostNotification(center,name,NULL,NULL,true);
}
static BOOL DFSPDockIsWindow(UIWindow *w) {
    NSString *name=w?NSStringFromClass(w.class):@"";
    return [name isEqualToString:@"DBStatusBarWindow"] ||
           [name isEqualToString:@"CARStatusBarWindow"];
}
static BOOL DFSPIsAppleAppDockVC(UIViewController *controller) {
    if (!controller)return NO;
    Class db=NSClassFromString(@"DBAppDockViewController");
    Class car=NSClassFromString(@"CARAppDockViewController");
    return (db && [controller isKindOfClass:db]) ||
           (car && [controller isKindOfClass:car]);
}
static void DFSPDockObserveAppController(UIViewController *controller) {
    if (!DFSPIsAppleAppDockVC(controller) || !controller.isViewLoaded)return;
    if (!DFSPAppDockControllers)
        DFSPAppDockControllers=[NSHashTable weakObjectsHashTable];
    if (!DFSPAppDockSnapshots)
        DFSPAppDockSnapshots=[NSMapTable weakToStrongObjectsMapTable];
    UIView *dockView=controller.view;
    if (!dockView)return;
    [DFSPAppDockControllers addObject:controller];
    if (![DFSPAppDockSnapshots objectForKey:dockView]) {
        [DFSPAppDockSnapshots setObject:
           @{@"hidden":@(dockView.hidden),@"alpha":@(dockView.alpha)}
           forKey:dockView];
    }
    if (!DFSPDockRequested || !dockView.window)return;
    BOOL expectedHidden=DFSPDockZoomRequested;
    // No extra custom Dock; preserve Apple's existing icons/status/launcher.
    if (dockView.hidden!=expectedHidden) dockView.hidden=expectedHidden;
    if (!expectedHidden && dockView.alpha<0.99)dockView.alpha=1.0;
    DFSPDockLog([NSString stringWithFormat:
       @"APPDOCK class=%@ mounted=YES mode=%@ hidden=%d alpha=%.2f frame=%@",
       NSStringFromClass(controller.class),
       DFSPDockZoomRequested?@"Zoom":@"Normal",
       dockView.hidden,dockView.alpha,NSStringFromCGRect(dockView.frame)],NO);
    DFSPDockAck(@"genuine AppDockViewController attached");
}
static void DFSPDockFindAppControllersInWindow(UIWindow *window) {
    if (!window)return;
    // UIKit's real controller is often under a Dashboard root container.
    // Inspect view responders without creating a new controller or moving views.
    NSMutableArray<UIView *> *queue=[NSMutableArray arrayWithObject:window];
    NSUInteger checked=0;
    while (queue.count && checked++<500) {
        UIView *v=queue.firstObject;
        [queue removeObjectAtIndex:0];
        UIResponder *owner=v.nextResponder;
        if ([owner isKindOfClass:UIViewController.class] &&
            DFSPIsAppleAppDockVC((UIViewController *)owner))
            DFSPDockObserveAppController((UIViewController *)owner);
        for (UIView *child in v.subviews)
            if (queue.count<500)[queue addObject:child];
    }
}
static void DFSPDockSetWindow(UIWindow *w) {
    if (!DFSPDockRequested || !DFSPDockIsWindow(w))return;
    if (!DFSPDockWindows)DFSPDockWindows=[NSHashTable weakObjectsHashTable];
    if (!DFSPDockOriginalHidden)
        DFSPDockOriginalHidden=[NSMapTable weakToStrongObjectsMapTable];
    [DFSPDockWindows addObject:w];
    if (![DFSPDockOriginalHidden objectForKey:w])
        [DFSPDockOriginalHidden setObject:@(w.hidden) forKey:w];
    // The actual Native12 DashboardChrome owner ONLY forces hidden in Zoom.
    // In Normal it restores the system's original hidden state instead of
    // unconditionally setting hidden=NO (QA10 wrongly exposed an old bar).
    NSNumber *original=[DFSPDockOriginalHidden objectForKey:w];
    BOOL hide=DFSPDockZoomRequested?YES:original.boolValue;
    if (w.hidden!=hide) {
        DFSPDockApplying=YES;
        w.hidden=hide;
        DFSPDockApplying=NO;
    }
}
static void DFSPDockAck(NSString *reason) {
    NSUInteger count=DFSPDockWindows.allObjects.count;
    BOOL correct=count>0;
    for (UIWindow *w in DFSPDockWindows.allObjects) {
        NSNumber *initial=[DFSPDockOriginalHidden objectForKey:w];
        BOOL expected=DFSPDockZoomRequested?YES:initial.boolValue;
        if (!initial || w.hidden!=expected)correct=NO;
    }
    NSUInteger dockMounted=0;
    for (UIViewController *controller in DFSPAppDockControllers.allObjects)
        if (controller.isViewLoaded && controller.view.window)++dockMounted;
    if (DFSPDockLastWindowCount==count &&
        DFSPDockLastAppCount==dockMounted &&
        DFSPDockLastVisible==(NSInteger)!DFSPDockZoomRequested &&
        DFSPDockLastOK==(NSInteger)correct)return;
    DFSPDockLastWindowCount=count;
    DFSPDockLastAppCount=dockMounted;
    DFSPDockLastVisible=(NSInteger)!DFSPDockZoomRequested;
    DFSPDockLastOK=(NSInteger)correct;
    NSUInteger appDockSeen=0;
    BOOL appDockApplied=YES;
    for (UIViewController *controller in DFSPAppDockControllers.allObjects) {
        if (!controller.isViewLoaded || !controller.view.window)continue;
        ++appDockSeen;
        if (controller.view.hidden!=DFSPDockZoomRequested ||
            (!DFSPDockZoomRequested && controller.view.alpha<0.99))
            appDockApplied=NO;
    }
    if (!appDockSeen)appDockApplied=NO;
    NSString *klass=count?NSStringFromClass(DFSPDockWindows.allObjects.firstObject.class):@"none";
    DFSPDockLog([NSString stringWithFormat:
        @"receiver mode=%@ statusbarClass=%@ windowCount=%lu appDockMounted=%lu statusbarApplied=%d appDockApplied=%d reason=%@",
        DFSPDockZoomRequested?@"Zoom":@"Normal",klass,(unsigned long)count,
        (unsigned long)appDockSeen,correct,appDockApplied,reason],NO);
    if (!DFSPDockRequested)return;
    // The QA10 mistake was ACKing a STATUS BAR even when no icon Dock existed.
    // Only the actual mounted Apple AppDockViewController validates the command.
    CFStringRef event=appDockApplied?
        (DFSPDockZoomRequested?DFSPDockAckZoom:DFSPDockAckNormal)
        :DFSPDockAckMissing;
    DFSPDockPost(event);
}
static void DFSPDockVisitWindows(void) {
    UIApplication *app=UIApplication.sharedApplication;
    // QA10 statusbar != guaranteed CarPlay launcher Dock. Record real
    // scene/window ownership; do not claim ACK as a visible app dock.
    NSMutableArray<NSString *> *inventory=[NSMutableArray array];
    for (UIScene *scene in app.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class])continue;
        for (UIWindow *w in ((UIWindowScene *)scene).windows) {
            [inventory addObject:[NSString stringWithFormat:
                @"%@ hidden=%d level=%.1f frame=%@",
                NSStringFromClass(w.class),w.hidden,w.windowLevel,
                NSStringFromCGRect(w.frame)]];
            DFSPDockSetWindow(w);
            DFSPDockFindAppControllersInWindow(w);
        }
    }
    DFSPDockLog([NSString stringWithFormat:
         @"CarPlay process=%@ scene windows=%@; appDockVC not verified",
         NSProcessInfo.processInfo.processName,[inventory componentsJoinedByString:@" | "]],NO);
}
static void DFSPDockObserveWindow(UIWindow *w) {
    if (!DFSPDockRequested || !DFSPDockIsWindow(w))return;
    NSNumber *original=[DFSPDockOriginalHidden objectForKey:w];
    BOOL target=DFSPDockZoomRequested?YES:original.boolValue;
    if ([DFSPDockWindows containsObject:w] && original &&
        w.hidden==target)return;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!DFSPDockRequested)return;
        DFSPDockSetWindow(w);
        DFSPDockAck(@"Native12 statusbar layout");
    });
}
static void DFSPDockRestoreOriginal(void) {
    // Important: no active force while restoring the system-owned state.
    DFSPDockRequested=NO;
    for (UIWindow *w in DFSPDockOriginalHidden.keyEnumerator) {
        NSNumber *was=[DFSPDockOriginalHidden objectForKey:w];
        if (was && w.hidden!=was.boolValue)w.hidden=was.boolValue;
    }
    [DFSPDockOriginalHidden removeAllObjects];
    [DFSPDockWindows removeAllObjects];
    for (UIView *view in DFSPAppDockSnapshots.keyEnumerator) {
        NSDictionary *snapshot=[DFSPAppDockSnapshots objectForKey:view];
        if (snapshot) {
            view.hidden=[snapshot[@"hidden"] boolValue];
            view.alpha=[snapshot[@"alpha"] doubleValue];
        }
    }
    [DFSPAppDockSnapshots removeAllObjects];
    [DFSPAppDockControllers removeAllObjects];
    DFSPDockLastWindowCount=NSUIntegerMax;
    DFSPDockLastAppCount=NSUIntegerMax;
    DFSPDockLastVisible=-1;DFSPDockLastOK=-1;
    DFSPDockPost(DFSPDockAckDetach);
}
static void DFSPDockReceive(CFStringRef name) {
    if (CFEqual(name,DFSPDockDetach)) {
        DFSPDockRestoreOriginal();
        return;
    }
    if (!CFEqual(name,DFSPDockNormal) && !CFEqual(name,DFSPDockZoom))return;
    DFSPDockRequested=YES;
    DFSPDockZoomRequested=CFEqual(name,DFSPDockZoom);
    // The real dock is owned by CarPlay. Never insert a duplicate UIImageView.
    DFSPDockVisitWindows();
    DFSPDockAck(@"Native12 host presentation mode requested");
}
static void DFSPDockAckReceived(CFStringRef name) {
    ++DFSPDockAckCount;
    NSString *result=@"UNKNOWN";
    if (CFEqual(name,DFSPDockAckNormal))result=@"NORMAL_APPDOCK_CONTROLLER_APPLIED";
    else if (CFEqual(name,DFSPDockAckZoom))result=@"ZOOM_APPDOCK_CONTROLLER_HIDDEN";
    else if (CFEqual(name,DFSPDockAckMissing))result=@"CARPLAY_APP_DOCK_CONTROLLER_MISSING_OR_UNMOUNTED";
    else if (CFEqual(name,DFSPDockAckDetach))result=@"WINDOW_RESTORED";
    DFSPDockLog([NSString stringWithFormat:
        @"ACK=%@ serial=%lu (window state, visual dock still needs device confirmation)",
        result,(unsigned long)DFSPDockRequestSerial],YES);
}
static void DFSPDockCallback(CFNotificationCenterRef center,void *observer,
                             CFStringRef name,const void *object,
                             CFDictionaryRef userInfo) {
    (void)center;(void)observer;(void)object;(void)userInfo;
    if (!name)return;
    CFRetain(name);
    dispatch_async(dispatch_get_main_queue(),^{
        if (CFEqual(name,DFSPDockNormal)||CFEqual(name,DFSPDockZoom)||
            CFEqual(name,DFSPDockDetach))DFSPDockReceive(name);
        else DFSPDockAckReceived(name);
        CFRelease(name);
    });
}
static void DFSPDockRegister(CFStringRef name) {
    CFNotificationCenterRef center=CFNotificationCenterGetDarwinNotifyCenter();
    if (center)CFNotificationCenterAddObserver(center,&DFSPDockObserverKey,
          DFSPDockCallback,name,NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
}

// Hook names correspond to Native12's own DFDashboardChrome.m.
// This intentionally replaces (not stacks with) the obsolete QA9/QA10 hooks.
%group DFSPNativeDockDB
%hook DBStatusBarWindow
- (void)layoutSubviews {
    %orig;
    DFSPDockObserveWindow((UIWindow *)self);
}
- (void)setHidden:(BOOL)hidden {
    // Never force show CarPlay statusbar in Normal. Return ownership to iOS.
    if (DFSPDockRequested && DFSPDockZoomRequested && !DFSPDockApplying)
        hidden=YES;
    %orig(hidden);
}
%end
%end
%group DFSPNativeDockCAR
%hook CARStatusBarWindow
- (void)layoutSubviews {
    %orig;
    DFSPDockObserveWindow((UIWindow *)self);
}
- (void)setHidden:(BOOL)hidden {
    // Never force show CarPlay statusbar in Normal. Return ownership to iOS.
    if (DFSPDockRequested && DFSPDockZoomRequested && !DFSPDockApplying)
        hidden=YES;
    %orig(hidden);
}
%end
%end

%group DFSPAppleAppDockDB
%hook DBAppDockViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig(animated);
    DFSPDockObserveAppController((UIViewController *)self);
}
- (void)viewDidLayoutSubviews {
    %orig;
    DFSPDockObserveAppController((UIViewController *)self);
}
%end
%end
%group DFSPAppleAppDockCAR
%hook CARAppDockViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig(animated);
    DFSPDockObserveAppController((UIViewController *)self);
}
- (void)viewDidLayoutSubviews {
    %orig;
    DFSPDockObserveAppController((UIViewController *)self);
}
%end
%end

static void DFSPDockInstall(unsigned attempt) {
    if (!DFSPDockHookReady) {
        if (NSClassFromString(@"DBStatusBarWindow")) {
            %init(DFSPNativeDockDB);
            DFSPDockHookReady=YES;
        } else if (NSClassFromString(@"CARStatusBarWindow")) {
            %init(DFSPNativeDockCAR);
            DFSPDockHookReady=YES;
        }
    }
    if (!DFSPAppDockHookReady) {
        if (NSClassFromString(@"DBAppDockViewController")) {
            %init(DFSPAppleAppDockDB);
            DFSPAppDockHookReady=YES;
        } else if (NSClassFromString(@"CARAppDockViewController")) {
            %init(DFSPAppleAppDockCAR);
            DFSPAppDockHookReady=YES;
        }
    }
    DFSPDockVisitWindows();
    if (DFSPDockHookReady || DFSPAppDockHookReady)
        DFSPDockAck(@"real iOS16 CarPlay Dashboard owners inspected");
    if ((!DFSPDockHookReady || !DFSPAppDockHookReady) && attempt<40) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC/2),
          dispatch_get_main_queue(),^{DFSPDockInstall(attempt+1);});
    } else if (!DFSPAppDockHookReady) {
        DFSPDockLog(@"APPDOCK_MISSING: neither DBAppDockViewController nor CARAppDockViewController found in this process",NO);
    }
}
static void DFSPDockStartup(void) {
    NSString *bundle=NSBundle.mainBundle.bundleIdentifier.lowercaseString?:@"";
    NSString *exe=NSProcessInfo.processInfo.processName.lowercaseString?:@"";
    BOOL springboard=[bundle isEqualToString:@"com.apple.springboard"]||
                     [exe isEqualToString:@"springboard"];
    BOOL carplay=[@[@"com.apple.carplayapp",@"com.apple.carplay",@"com.apple.dashboard"]
                  containsObject:bundle]||
                 [@[@"carplayapp",@"carplay",@"dashboard"] containsObject:exe];
    if (springboard) {
        DFSPDockRegister(DFSPDockAckNormal);DFSPDockRegister(DFSPDockAckZoom);
        DFSPDockRegister(DFSPDockAckMissing);DFSPDockRegister(DFSPDockAckDetach);
        DFSPDockLog(@"Native12-compatible system dock owner receiver ready in SpringBoard",YES);
    }
    if (carplay) {
        DFSPDockRegister(DFSPDockNormal);DFSPDockRegister(DFSPDockZoom);
        DFSPDockRegister(DFSPDockDetach);
        dispatch_async(dispatch_get_main_queue(),^{DFSPDockInstall(0);});
    }
}
static void DFSPDockCheckAck(CFStringRef name, NSUInteger serial,
                             NSUInteger before,NSUInteger attempts) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,2*NSEC_PER_SEC),
      dispatch_get_main_queue(),^{
        if (serial!=DFSPDockRequestSerial || before!=DFSPDockAckCount)return;
        if (attempts<4) {
            DFSPDockLog([NSString stringWithFormat:
                   @"no native dock receiver ACK serial=%lu retry=%lu/4",
                   (unsigned long)serial,(unsigned long)attempts],YES);
            DFSPDockPost(name);
            DFSPDockCheckAck(name,serial,before,attempts+1);
        } else {
            DFSPDockLog([NSString stringWithFormat:
                 @"ACK TIMEOUT serial=%lu: no responding CarPlay dock/statusbar UIWindow",
                 (unsigned long)serial],YES);
        }
    });
}
void DFSPDockRequest(BOOL active, BOOL zoom, NSUInteger generation) {
    CFStringRef msg=!active?DFSPDockDetach:
                    (zoom?DFSPDockZoom:DFSPDockNormal);
    NSUInteger serial=++DFSPDockRequestSerial;
    NSUInteger ackBefore=DFSPDockAckCount;
    DFSPDockPost(msg);
    DFSPDockLog([NSString stringWithFormat:
        @"request serial=%lu gen=%lu mode=%@",
        (unsigned long)serial,(unsigned long)generation,
        !active?@"Detach":zoom?@"Zoom":@"Normal"],YES);
    DFSPDockCheckAck(msg,serial,ackBefore,1);
}
%ctor {
    @autoreleasepool { DFSPDockStartup(); }
}
