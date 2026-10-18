#import "DFSPChromeBridge.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// No host/shared vendor classes are referenced in this receiver. It is only
// active in known CarPlay/Dashboard processes; the QA7 display stays in SpringBoard.
// Same transport family as Native12 DFFullscreenCoordinator (without license code).
static NSString * const DFSPChromeRequestEvent=@"com.duoface.sideplaydisplay.qa9.chrome.request";
static NSString * const DFSPChromeAckEvent=@"com.duoface.sideplaydisplay.qa9.chrome.ack";
static BOOL DFSPChromeActive=NO;
static BOOL DFSPChromeNormalVisible=YES;
static BOOL DFSPChromeApplying=NO;
static BOOL DFSPChromeInstalled=NO;
static NSUInteger DFSPChromeGeneration=0;
static NSHashTable<UIWindow *> *DFSPChromeWindows;
static NSMapTable<UIWindow *,NSNumber *> *DFSPChromeSnapshots;
static id DFSPChromeObserver;

@interface NSObject (DFSPDistributed)
+ (id)defaultCenter;
- (void)addObserver:(id)observer selector:(SEL)selector name:(NSString *)name object:(id)object;
- (void)postNotificationName:(NSString *)name object:(id)object userInfo:(NSDictionary *)info;
@end
@interface DBStatusBarWindow:UIWindow @end
@interface CARStatusBarWindow:UIWindow @end

static id DFSPNotificationCenter(void) {
    Class cls=NSClassFromString(@"NSDistributedNotificationCenter");
    return [cls respondsToSelector:@selector(defaultCenter)]?[cls defaultCenter]:nil;
}
static BOOL DFSPIsCarPlayStatusWindow(UIWindow *window) {
    if (!window) return NO;
    NSString *name=NSStringFromClass(window.class);
    return [name isEqualToString:@"DBStatusBarWindow"] ||
           [name isEqualToString:@"CARStatusBarWindow"];
}
static void DFSPChromeSendAck(NSString *message) {
    BOOL hasWindow=DFSPChromeWindows.allObjects.count>0;
    BOOL correct=NO;
    if (hasWindow) {
        correct=YES;
        for (UIWindow *win in DFSPChromeWindows.allObjects) {
            if (win.hidden==DFSPChromeNormalVisible) correct=NO;
        }
    }
    NSLog(@"[DuoFaceQA9Chrome] gen=%lu normal=%d windows=%lu ACK=%d %@",
          (unsigned long)DFSPChromeGeneration,DFSPChromeNormalVisible,
          (unsigned long)DFSPChromeWindows.allObjects.count,correct,message);
    id center=DFSPNotificationCenter();
    if (!center || !DFSPChromeActive) return;
    [center postNotificationName:DFSPChromeAckEvent object:nil
      userInfo:@{@"generation":@(DFSPChromeGeneration),
                 @"normalVisible":@(DFSPChromeNormalVisible),
                 @"statusbarObserved":@(hasWindow),
                 @"visibilityApplied":@(correct),
                 @"class":DFSPChromeWindows.allObjects.firstObject?
                    NSStringFromClass(DFSPChromeWindows.allObjects.firstObject.class):@"none",
                 @"reason":message?:@""}];
}
static void DFSPChromeApplyToWindow(UIWindow *win) {
    if (!DFSPChromeActive || !DFSPIsCarPlayStatusWindow(win))return;
    if (!DFSPChromeWindows)DFSPChromeWindows=[NSHashTable weakObjectsHashTable];
    if (!DFSPChromeSnapshots)DFSPChromeSnapshots=[NSMapTable weakToStrongObjectsMapTable];
    [DFSPChromeWindows addObject:win];
    if (![DFSPChromeSnapshots objectForKey:win])
        [DFSPChromeSnapshots setObject:@(win.hidden) forKey:win];
    BOOL targetHidden=!DFSPChromeNormalVisible;
    if (win.hidden!=targetHidden) {
        DFSPChromeApplying=YES;
        win.hidden=targetHidden;
        DFSPChromeApplying=NO;
    }
}
static void DFSPChromeObserve(UIWindow *win) {
    if (!DFSPChromeActive || !DFSPIsCarPlayStatusWindow(win))return;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!DFSPChromeActive)return;
        DFSPChromeApplyToWindow(win);
        DFSPChromeSendAck(@"status-window observed/layout");
    });
}
static void DFSPChromeEnumerate(void) {
    UIApplication *app=UIApplication.sharedApplication;
    for (UIWindow *win in app.windows)DFSPChromeApplyToWindow(win);
    if (@available(iOS 13.0,*)) {
        for (UIScene *scene in app.connectedScenes)
            if ([scene isKindOfClass:UIWindowScene.class])
                for (UIWindow *win in ((UIWindowScene *)scene).windows)
                    DFSPChromeApplyToWindow(win);
    }
}
static void DFSPChromeRestore(void) {
    DFSPChromeActive=NO; // release forced setHidden hook before restoring
    for (UIWindow *win in DFSPChromeSnapshots.keyEnumerator) {
        NSNumber *previous=[DFSPChromeSnapshots objectForKey:win];
        if (previous && win.hidden!=previous.boolValue)
            win.hidden=previous.boolValue;
    }
    [DFSPChromeSnapshots removeAllObjects];
    [DFSPChromeWindows removeAllObjects];
}
@interface DFSPChromeEventReceiver:NSObject
- (void)request:(NSNotification *)notification;
- (void)ack:(NSNotification *)notification;
@end
@implementation DFSPChromeEventReceiver
- (void)request:(NSNotification *)notification {
    NSDictionary *info=notification.userInfo;
    NSNumber *gen=info[@"generation"];
    NSNumber *active=info[@"active"];
    NSNumber *normal=info[@"normalVisible"];
    if (![gen isKindOfClass:NSNumber.class] || ![active isKindOfClass:NSNumber.class] ||
        ![normal isKindOfClass:NSNumber.class])return;
    dispatch_async(dispatch_get_main_queue(),^{
        // A disconnect/no-scene command must always clear the last request.
        DFSPChromeGeneration=gen.unsignedIntegerValue;
        if (!active.boolValue) {
            DFSPChromeRestore();
            NSLog(@"[DuoFaceQA9Chrome] inactive -> restored status-window snapshots");
            return;
        }
        DFSPChromeActive=YES;
        DFSPChromeNormalVisible=normal.boolValue;
        DFSPChromeEnumerate();
        DFSPChromeSendAck(DFSPChromeInstalled?@"request handled":@"awaiting statusbar class");
    });
}
- (void)ack:(NSNotification *)notification {
    NSDictionary *info=notification.userInfo;
    NSLog(@"[DuoFaceQA9Chrome] SpringBoard ACK generation=%@ normal=%@ observed=%@ applied=%@ class=%@ reason=%@",
          info[@"generation"],info[@"normalVisible"],info[@"statusbarObserved"],
          info[@"visibilityApplied"],info[@"class"],info[@"reason"]);
}
@end

%group DFSPQA9ChromeDB
%hook DBStatusBarWindow
- (void)layoutSubviews {
    %orig;
    DFSPChromeObserve((UIWindow *)self);
}
- (void)setHidden:(BOOL)hidden {
    if (DFSPChromeActive && !DFSPChromeApplying)
        hidden=!DFSPChromeNormalVisible;
    %orig(hidden);
}
%end
%end
%group DFSPQA9ChromeCAR
%hook CARStatusBarWindow
- (void)layoutSubviews {
    %orig;
    DFSPChromeObserve((UIWindow *)self);
}
- (void)setHidden:(BOOL)hidden {
    if (DFSPChromeActive && !DFSPChromeApplying)
        hidden=!DFSPChromeNormalVisible;
    %orig(hidden);
}
%end
%end

static void DFSPChromeInstallHooks(unsigned attempt) {
    if (DFSPChromeInstalled)return;
    if (NSClassFromString(@"DBStatusBarWindow")) {
        %init(DFSPQA9ChromeDB);
        DFSPChromeInstalled=YES;
    } else if (NSClassFromString(@"CARStatusBarWindow")) {
        %init(DFSPQA9ChromeCAR);
        DFSPChromeInstalled=YES;
    }
    if (DFSPChromeInstalled) {
        NSLog(@"[DuoFaceQA9Chrome] status-window hook ready %@",NSProcessInfo.processInfo.processName);
        DFSPChromeEnumerate();
        DFSPChromeSendAck(@"hook installed");
    } else if (attempt<40) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NSEC_PER_SEC/2)),
                       dispatch_get_main_queue(),^{ DFSPChromeInstallHooks(attempt+1); });
    } else NSLog(@"[DuoFaceQA9Chrome] no supported status-window class in %@",
                 NSProcessInfo.processInfo.processName);
}
void DFSPChromeInstallReceiver(void) {
    NSString *bundle=NSBundle.mainBundle.bundleIdentifier.lowercaseString;
    BOOL springBoard=[bundle isEqualToString:@"com.apple.springboard"];
    BOOL carPlay=[@[@"com.apple.carplayapp",@"com.apple.carplay",@"com.apple.dashboard"]
                  containsObject:bundle];
    if (!springBoard && !carPlay)return;
    id center=DFSPNotificationCenter();
    if (!center) {
        NSLog(@"[DuoFaceQA9Chrome] distributed notification center unavailable");
        return;
    }
    DFSPChromeObserver=[DFSPChromeEventReceiver new];
    [center addObserver:DFSPChromeObserver
              selector:springBoard?@selector(ack:):@selector(request:)
                  name:springBoard?DFSPChromeAckEvent:DFSPChromeRequestEvent
                object:nil];
    if (carPlay)
        dispatch_async(dispatch_get_main_queue(),^{ DFSPChromeInstallHooks(0); });
}
void DFSPChromeRequest(BOOL active, BOOL normalVisible, NSUInteger generation) {
    id center=DFSPNotificationCenter();
    if (!center)return;
    [center postNotificationName:DFSPChromeRequestEvent object:nil
       userInfo:@{@"generation":@(generation),@"active":@(active),
                  @"normalVisible":@(normalVisible)}];
    NSLog(@"[DuoFaceQA9Chrome] requested gen=%lu active=%d normal=%d",
          (unsigned long)generation,active,normalVisible);
}
%ctor {
    @autoreleasepool { DFSPChromeInstallReceiver(); }
}
