#import "DFSPChromeBridge.h"
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>

// QA10 source-only fix: NSDistributedNotificationCenter was a Mac-style
// transport and could silently be nil on iOS. Darwin notification center is
// supported by iOS, but carries NO userInfo. Encode state in separate names.
// This controls ONLY observed DB/CAR statusbar UIWindows; it does not fabricate
// a CarPlay dock/sidebar, copy vendor code or claim device visibility.
static CFStringRef const DFSPChromeShow  = CFSTR("com.duoface.sideplaydisplay.chrome.v2.show");
static CFStringRef const DFSPChromeHide  = CFSTR("com.duoface.sideplaydisplay.chrome.v2.hide");
static CFStringRef const DFSPChromeReset = CFSTR("com.duoface.sideplaydisplay.chrome.v2.reset");
static CFStringRef const DFSPChromeAckShown   = CFSTR("com.duoface.sideplaydisplay.chrome.v2.ack.shown");
static CFStringRef const DFSPChromeAckHidden  = CFSTR("com.duoface.sideplaydisplay.chrome.v2.ack.hidden");
static CFStringRef const DFSPChromeAckMissing = CFSTR("com.duoface.sideplaydisplay.chrome.v2.ack.missing");
static CFStringRef const DFSPChromeAckReset   = CFSTR("com.duoface.sideplaydisplay.chrome.v2.ack.reset");

static BOOL DFSPChromeActive=NO;
static BOOL DFSPChromeNormalVisible=YES;
static BOOL DFSPChromeApplying=NO;
static BOOL DFSPChromeInstalled=NO;
static NSUInteger DFSPChromeGeneration=0;
static NSUInteger DFSPChromeLastAckGeneration=NSUIntegerMax;
static NSInteger DFSPChromeLastAckVisible=-1;
static NSInteger DFSPChromeLastAckWindowCount=-1;
static NSInteger DFSPChromeLastAckSuccess=-1;
static NSUInteger DFSPChromeAckCount=0;
static NSUInteger DFSPChromeRequestSerial=0;
static NSHashTable<UIWindow *> *DFSPChromeWindows;
static NSMapTable<UIWindow *,NSNumber *> *DFSPChromeSnapshots;
static char DFSPChromeDarwinObserverIdentity;

@interface DBStatusBarWindow : UIWindow @end
@interface CARStatusBarWindow : UIWindow @end

static void DFSPChromeLog(NSString *message, BOOL persistent) {
    NSLog(@"[DuoFaceQA10Chrome] %@",message);
    if (!persistent)return;
    // SpringBoard is the only expected writer; keep ACK evidence in the same
    // device log as SPDash diagnostics. No app names or private data.
    @try {
        NSString *dir=@"/var/mobile/Library/Logs";
        [[NSFileManager defaultManager] createDirectoryAtPath:dir
                withIntermediateDirectories:YES attributes:nil error:NULL];
        NSString *path=[dir stringByAppendingPathComponent:@"DuoFaceSidePlayDisplayQA.log"];
        NSData *line=[[NSString stringWithFormat:@"%@ QA10_CHROME %@\n",
             [NSDate date],message] dataUsingEncoding:NSUTF8StringEncoding];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [line writeToFile:path atomically:YES];
        } else {
            NSFileHandle *fd=[NSFileHandle fileHandleForWritingAtPath:path];
            if (fd) { [fd seekToEndOfFile]; [fd writeData:line]; [fd closeFile]; }
        }
    } @catch (NSException *ignored) { (void)ignored; }
}
static void DFSPChromePost(CFStringRef name) {
    CFNotificationCenterRef center=CFNotificationCenterGetDarwinNotifyCenter();
    if (center && name) CFNotificationCenterPostNotification(center,name,NULL,NULL,true);
}
static BOOL DFSPIsCarPlayStatusWindow(UIWindow *window) {
    NSString *cls=window?NSStringFromClass(window.class):@"";
    return [cls isEqualToString:@"DBStatusBarWindow"] ||
           [cls isEqualToString:@"CARStatusBarWindow"];
}
static void DFSPChromeSendAck(NSString *reason) {
    NSUInteger n=DFSPChromeWindows.allObjects.count;
    BOOL correct=n>0;
    for (UIWindow *win in DFSPChromeWindows.allObjects) {
        if (win.hidden!=!DFSPChromeNormalVisible)correct=NO;
    }
    if (DFSPChromeLastAckGeneration==DFSPChromeGeneration &&
        DFSPChromeLastAckVisible==(NSInteger)DFSPChromeNormalVisible &&
        DFSPChromeLastAckWindowCount==(NSInteger)n &&
        DFSPChromeLastAckSuccess==(NSInteger)correct)return;
    DFSPChromeLastAckGeneration=DFSPChromeGeneration;
    DFSPChromeLastAckVisible=DFSPChromeNormalVisible;
    DFSPChromeLastAckWindowCount=(NSInteger)n;
    DFSPChromeLastAckSuccess=correct;
    NSString *cls=n?NSStringFromClass(DFSPChromeWindows.allObjects.firstObject.class):@"none";
    DFSPChromeLog([NSString stringWithFormat:
        @"receiver normal=%d class=%@ windows=%lu applied=%d reason=%@",
        DFSPChromeNormalVisible,cls,(unsigned long)n,correct,reason],NO);
    if (!DFSPChromeActive)return;
    DFSPChromePost(!correct?DFSPChromeAckMissing:
                    (DFSPChromeNormalVisible?DFSPChromeAckShown:DFSPChromeAckHidden));
}
static void DFSPChromeApplyWindow(UIWindow *win) {
    if (!DFSPChromeActive || !DFSPIsCarPlayStatusWindow(win))return;
    if (!DFSPChromeWindows)DFSPChromeWindows=[NSHashTable weakObjectsHashTable];
    if (!DFSPChromeSnapshots)DFSPChromeSnapshots=[NSMapTable weakToStrongObjectsMapTable];
    [DFSPChromeWindows addObject:win];
    if (![DFSPChromeSnapshots objectForKey:win])
        [DFSPChromeSnapshots setObject:@(win.hidden) forKey:win];
    BOOL hidden=!DFSPChromeNormalVisible;
    if (win.hidden!=hidden) {
        DFSPChromeApplying=YES;
        win.hidden=hidden;
        DFSPChromeApplying=NO;
    }
}
static void DFSPChromeObserveWindow(UIWindow *win) {
    if (!DFSPChromeActive || !DFSPIsCarPlayStatusWindow(win))return;
    if ([DFSPChromeWindows containsObject:win] &&
        win.hidden==!DFSPChromeNormalVisible)return;
    dispatch_async(dispatch_get_main_queue(),^{
        if (!DFSPChromeActive)return;
        DFSPChromeApplyWindow(win);
        DFSPChromeSendAck(@"status-window layout");
    });
}
static void DFSPChromeEnumerateWindows(void) {
    UIApplication *app=UIApplication.sharedApplication;
    for (UIScene *scene in app.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class])continue;
        for (UIWindow *win in ((UIWindowScene *)scene).windows)
            DFSPChromeApplyWindow(win);
    }
}
static void DFSPChromeRestore(void) {
    DFSPChromeActive=NO;
    for (UIWindow *win in DFSPChromeSnapshots.keyEnumerator) {
        NSNumber *before=[DFSPChromeSnapshots objectForKey:win];
        if (before && win.hidden!=before.boolValue)win.hidden=before.boolValue;
    }
    [DFSPChromeSnapshots removeAllObjects];
    [DFSPChromeWindows removeAllObjects];
    DFSPChromeLastAckGeneration=NSUIntegerMax;
    DFSPChromeLastAckWindowCount=-1;
    DFSPChromeLog(@"receiver disconnected: original hidden state restored",NO);
    DFSPChromePost(DFSPChromeAckReset);
}
static void DFSPChromeReceiveCommand(CFStringRef name) {
    DFSPChromeGeneration++;
    if (CFEqual(name,DFSPChromeReset)) {
        DFSPChromeRestore();
        return;
    }
    DFSPChromeActive=YES;
    DFSPChromeNormalVisible=CFEqual(name,DFSPChromeShow);
    DFSPChromeEnumerateWindows();
    DFSPChromeSendAck(DFSPChromeInstalled?@"Darwin command delivered":
                                    @"Darwin command before window hook ready");
}
static void DFSPChromeHandleAck(CFStringRef name) {
    DFSPChromeAckCount++;
    NSString *state=@"unknown";
    if (CFEqual(name,DFSPChromeAckShown)) state=@"SHOWN_WINDOW";
    else if (CFEqual(name,DFSPChromeAckHidden)) state=@"HIDDEN_WINDOW";
    else if (CFEqual(name,DFSPChromeAckMissing)) state=@"WINDOW_NOT_FOUND_OR_MISMATCH";
    else if (CFEqual(name,DFSPChromeAckReset)) state=@"RESTORED";
    DFSPChromeLog([NSString stringWithFormat:
        @"SpringBoard receiver ACK=%@ requestSerial=%lu (ACK is window state, NOT visible dock proof)",
        state,(unsigned long)DFSPChromeRequestSerial],YES);
}
static void DFSPChromeDarwinCallback(CFNotificationCenterRef center,
                                    void *observer,CFStringRef name,
                                    const void *object,CFDictionaryRef userInfo) {
    (void)center; (void)observer; (void)object; (void)userInfo;
    if (!name)return;
    CFRetain(name);
    dispatch_async(dispatch_get_main_queue(),^{
        if (CFEqual(name,DFSPChromeShow)||CFEqual(name,DFSPChromeHide)||
            CFEqual(name,DFSPChromeReset)) DFSPChromeReceiveCommand(name);
        else DFSPChromeHandleAck(name);
        CFRelease(name);
    });
}
static void DFSPChromeSubscribe(CFNotificationCenterRef center,CFStringRef name) {
    CFNotificationCenterAddObserver(center,&DFSPChromeDarwinObserverIdentity,
        DFSPChromeDarwinCallback,name,NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately);
}

%group DFSPQA10ChromeDB
%hook DBStatusBarWindow
- (void)layoutSubviews {
    %orig;
    DFSPChromeObserveWindow((UIWindow *)self);
}
- (void)setHidden:(BOOL)hidden {
    if (DFSPChromeActive && !DFSPChromeApplying) hidden=!DFSPChromeNormalVisible;
    %orig(hidden);
}
%end
%end

%group DFSPQA10ChromeCAR
%hook CARStatusBarWindow
- (void)layoutSubviews {
    %orig;
    DFSPChromeObserveWindow((UIWindow *)self);
}
- (void)setHidden:(BOOL)hidden {
    if (DFSPChromeActive && !DFSPChromeApplying) hidden=!DFSPChromeNormalVisible;
    %orig(hidden);
}
%end
%end

static void DFSPChromeInstallHooks(unsigned attempt) {
    if (DFSPChromeInstalled)return;
    if (NSClassFromString(@"DBStatusBarWindow")) {
        %init(DFSPQA10ChromeDB);
        DFSPChromeInstalled=YES;
    } else if (NSClassFromString(@"CARStatusBarWindow")) {
        %init(DFSPQA10ChromeCAR);
        DFSPChromeInstalled=YES;
    }
    if (DFSPChromeInstalled) {
        DFSPChromeLog([NSString stringWithFormat:
            @"receiver hooked status window process=%@",NSProcessInfo.processInfo.processName],NO);
        DFSPChromeEnumerateWindows();
        DFSPChromeSendAck(@"statusbar class hook installed");
    } else if (attempt<40) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(NSEC_PER_SEC/2)),
                       dispatch_get_main_queue(),^{DFSPChromeInstallHooks(attempt+1);});
    } else {
        DFSPChromeLog([NSString stringWithFormat:
             @"receiver NO DBStatusBarWindow or CARStatusBarWindow in process=%@",
             NSProcessInfo.processInfo.processName],NO);
        if (DFSPChromeActive)DFSPChromePost(DFSPChromeAckMissing);
    }
}
void DFSPChromeInstallReceiver(void) {
    NSString *bundle=NSBundle.mainBundle.bundleIdentifier.lowercaseString?:@"";
    NSString *exe=NSProcessInfo.processInfo.processName.lowercaseString?:@"";
    BOOL springBoard=[bundle isEqualToString:@"com.apple.springboard"]||
                     [exe isEqualToString:@"springboard"];
    BOOL carPlay=[@[@"com.apple.carplayapp",@"com.apple.carplay",
                    @"com.apple.dashboard"] containsObject:bundle]||
                 [@[@"carplayapp",@"carplay",@"dashboard"] containsObject:exe];
    if (!springBoard && !carPlay)return;
    CFNotificationCenterRef center=CFNotificationCenterGetDarwinNotifyCenter();
    if (!center) {
        DFSPChromeLog(@"Darwin notification center unavailable",springBoard);
        return;
    }
    if (springBoard) {
        DFSPChromeSubscribe(center,DFSPChromeAckShown);
        DFSPChromeSubscribe(center,DFSPChromeAckHidden);
        DFSPChromeSubscribe(center,DFSPChromeAckMissing);
        DFSPChromeSubscribe(center,DFSPChromeAckReset);
        DFSPChromeLog(@"Darwin ACK receiver registered in SpringBoard",YES);
    }
    if (carPlay) {
        DFSPChromeSubscribe(center,DFSPChromeShow);
        DFSPChromeSubscribe(center,DFSPChromeHide);
        DFSPChromeSubscribe(center,DFSPChromeReset);
        DFSPChromeLog([NSString stringWithFormat:
           @"Darwin statusbar command receiver registered in %@ bundle=%@",
           exe,bundle],NO);
        dispatch_async(dispatch_get_main_queue(),^{DFSPChromeInstallHooks(0);});
    }
}
// A CarPlay process can start after SpringBoard has already attached SPDash.
// Retry a bounded number of missed command notifications; an ACK for a
// missing status window stops retries because the receiver is working and
// will recheck when the status window appears later.
static void DFSPChromeAwaitAck(CFStringRef event, NSUInteger serial,
                               NSUInteger ackBefore, NSUInteger attempt) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,2*NSEC_PER_SEC),
                   dispatch_get_main_queue(),^{
        if (DFSPChromeRequestSerial!=serial || DFSPChromeAckCount!=ackBefore)return;
        if (attempt<4) {
            DFSPChromeLog([NSString stringWithFormat:
                  @"no receiver ACK serial=%lu retry=%lu/4",
                  (unsigned long)serial,(unsigned long)attempt],YES);
            DFSPChromePost(event);
            DFSPChromeAwaitAck(event,serial,ackBefore,attempt+1);
        } else {
            DFSPChromeLog([NSString stringWithFormat:
                 @"ACK TIMEOUT serial=%lu: CarPlay process/receiver not verified after 4 retries",
                 (unsigned long)serial],YES);
        }
    });
}
void DFSPChromeRequest(BOOL active, BOOL normalVisible, NSUInteger generation) {
    // Do not assume a successful send means a statusbar/dock actually appeared.
    NSUInteger serial=++DFSPChromeRequestSerial;
    CFStringRef event=!active?DFSPChromeReset:
                      (normalVisible?DFSPChromeShow:DFSPChromeHide);
    NSUInteger ackBefore=DFSPChromeAckCount;
    DFSPChromePost(event);
    DFSPChromeLog([NSString stringWithFormat:
         @"Darwin request serial=%lu gen=%lu active=%d normal=%d",
         (unsigned long)serial,(unsigned long)generation,active,normalVisible],YES);
    DFSPChromeAwaitAck(event,serial,ackBefore,1);
}

%ctor {
    @autoreleasepool { DFSPChromeInstallReceiver(); }
}
