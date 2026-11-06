// QA177 H1: app-side "user touched" signal for controls recall.
//
// Step-0 finding (QA177): the QA176 recall wiring subscribed Chrome to
// DFSceneHostDidObserveTouchNotification, but device logs prove that
// notification never fires in real use (0 unthrottled hit-test lines in
// a session with proven in-pane taps) — touches into hosted content are
// routed at scene level and never traverse DFSceneSurface.hitTest or
// the slot window's UIKit hit-test. The signal must therefore originate
// inside the hosted app's own process, where touches DO arrive.
//
// Transport: the existing DF156 Darwin mailbox, direction app ->
// SpringBoard — the same direction QA176's keyboard diagnostics used
// successfully on device (app wrote, SpringBoard read, 9 records).
// Payload is a bounded latest-value v2 JSON record {bundle, pid, count, ts};
// the mailbox name post is the wakeup. Sender throttled to one write
// per kDF177TouchThrottleSeconds; the count is cumulative so a lost
// wakeup loses nothing.
//
// Observation point: -[UIApplication sendEvent:]. The original
// implementation runs FIRST; the hook only reads the event afterwards
// (any touch with phase Began) — it never keeps, delays, reorders or
// cancels a touch. Installed only inside apps that carry an app-side
// relay (DF155 pilot scope, plus YouTube via its own relay).
//
// Kill switch: key AppTouchRecall177 in the qa177 prefs plist
// (absent = ON). Both sides read it live; 0 stops the sender and makes
// SpringBoard ignore the signal. No code change needed to disable.
#ifndef DF_APP_TOUCH_177_H
#define DF_APP_TOUCH_177_H
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#include <notify.h>
#include <unistd.h>
#include <math.h>
#import "DF156DarwinMailbox.h"
#import "DFKeyboardState177.h"
#import "DFAppTouchPolicy177.h"

static NSString *const DF177TouchPrefsPath =
    @"/var/mobile/Library/Preferences/com.duoface.nativehost.qa177.plist";
static const char *const DF177TouchWakeName = "com.duoface.apptouch177.wake";
static const char *const DF177TouchMailboxName = "com.duoface.ipc.v177.apptouch";
// QA172 wakefix: keyboard-visibility state, same DF156 transport and
// direction (app -> SpringBoard). Chrome's wake shield must never
// re-arm over a live keyboard; the keyboard window's order relative
// to the shield cannot be proven from SpringBoard, so the app
// reports its own keyboard state and Chrome trusts the report.
static const char *const DF177KbWakeName = "com.duoface.kbstate177.wake";
static const NSTimeInterval kDF177TouchThrottleSeconds = 0.25;

// Each app owns a separate retained snapshot. The common notification is
// only a wakeup, so simultaneous app writes cannot erase another app's state.
static inline DF156Mailbox *DF177KeyboardChannel(NSString *bundle) {
    if(!NSThread.isMainThread || ![bundle isKindOfClass:NSString.class] ||
       !bundle.length || bundle.length>128)return NULL;
    static NSMutableDictionary<NSString *,NSValue *> *channels;
    if(!channels)channels=[NSMutableDictionary new];
    DF156Mailbox *box=[channels[bundle] pointerValue];
    if(!box){
        NSString *name=DF177KeyboardChannelName(bundle);
        if(!name)return NULL;
        box=calloc(1,sizeof(*box));
        if(!box)return NULL;
        DF156Init(box,name.UTF8String);
        channels[bundle]=[NSValue valueWithPointer:box];
    }
    return box;
}

static inline NSDictionary *DF177ReadKeyboardState(NSString *bundle, NSNumber *pid) {
    DF156Mailbox *box=DF177KeyboardChannel(bundle);
    if(!box)return nil;
    uint8_t bytes[DF156_MAX_BYTES];
    size_t size=DF156Read(box,bytes);
    if(!size)return nil;
    id record=[NSJSONSerialization JSONObjectWithData:
        [NSData dataWithBytes:bytes length:size] options:0 error:nil];
    return DF177KeyboardRecordMatches(record,bundle,pid,
        NSDate.date.timeIntervalSince1970)?record:nil;
}

static inline BOOL DF177AppTouchEnabled(void) {
    NSDictionary *p = [NSDictionary dictionaryWithContentsOfFile:DF177TouchPrefsPath];
    id v = [p isKindOfClass:NSDictionary.class] ? p[@"AppTouchRecall177"] : nil;
    return v ? [v boolValue] : YES;
}

// Sender machinery below is compiled only into the app-side relays
// (they define DF177_APP_SIDE_SENDER before importing); SpringBoard
// imports only the names + flag above.
#ifdef DF177_APP_SIDE_SENDER
// Cumulative sender state (one instance per app process / TU).
static uint64_t DF177TouchCount = 0;
static NSTimeInterval DF177TouchLastSentAt = 0;
static DF156Mailbox DF177TouchBox;
static BOOL DF177TouchBoxReady = NO;
// QA180 H1 gate: last known host state, initially UNKNOWN (fail open).
// The sender records these exact process-local booleans in each wake JSON.
static BOOL DF188ControlsHidden = NO;
static BOOL DF188ControlsHiddenKnown = NO;
static BOOL DF188KbSessionVisible = NO;

static inline void DF177AppTouchNoteBeganEx(NSString *bundle, BOOL swallowed) {
    if (!bundle.length || !DF177AppTouchEnabled()) return;
    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    // A swallowed wake tap is the only signal the host gets; it must
    // never be throttled away. Ordinary observations keep the throttle.
    if (!swallowed && now - DF177TouchLastSentAt < kDF177TouchThrottleSeconds) return;
    DF177TouchLastSentAt = now;
    DF177TouchCount++;
    @try {
        if (!DF177TouchBoxReady) {
            DF156Init(&DF177TouchBox, DF177TouchMailboxName);
            DF177TouchBoxReady = YES;
        }
        NSDictionary *rec = @{@"version": @2, @"bundle": bundle,
                              @"pid": @(getpid()),
                              @"count": @(DF177TouchCount), @"ts": @(now),
                              @"swallowed": @(swallowed),
                              @"gate": [NSString stringWithFormat:
                                  @"known=%d hidden=%d kb=%d",
                                  (int)DF188ControlsHiddenKnown,
                                  (int)DF188ControlsHidden,
                                  (int)DF188KbSessionVisible]};
        NSData *bytes = [NSJSONSerialization dataWithJSONObject:rec
                                                          options:0 error:nil];
        uint64_t generation = 0;
        arc4random_buf(&generation, sizeof(generation));
        if (bytes && DF156Write(&DF177TouchBox, bytes.bytes, bytes.length,
                                generation ?: 1))
            notify_post(DF177TouchWakeName);
    } @catch (__unused NSException *e) {}
}

static inline void DF177AppTouchNoteBegan(NSString *bundle) {
    DF177AppTouchNoteBeganEx(bundle, NO);
}

static IMP DF177SendEventOriginal = NULL;
static NSString *DF177TouchBundle = nil;

// wakefix3: weak notification-observed identities survive incomplete scans.
// These records are per bundle/PID; a failed write is retried next event.
static NSHashTable *DF177KbKnownWindows;
static BOOL DF177KbHasPublished = NO;
static BOOL DF177KbVisible = NO;

// QA180: host's prefs are sandbox-inaccessible to hosted App Store relays.
// Receive live hidden/shown Darwin notifications instead; initial state is
// unknown until a host reply to the one-shot query or a state transition.
static const char *const DF188ControlsHiddenName = "com.duoface.controls188.hidden";
static const char *const DF188ControlsShownName = "com.duoface.controls188.shown";
static const char *const DF188ControlsQueryName = "com.duoface.controls188.query";
static int DF188ControlsHiddenToken = 0;
static int DF188ControlsShownToken = 0;
// QA179 process-local keyboard session and DF156 reporting remain unchanged.

static inline BOOL DF177IsKeyboardWindow(id window) {
    Class keyboard=NSClassFromString(@"UIRemoteKeyboardWindow");
    return [window isKindOfClass:UIWindow.class] && keyboard &&
           [window isKindOfClass:keyboard];
}

// QA179: a non-hidden remote keyboard window can be parked full-screen
// (origin.y == 0) with no keyboard on screen. Only an actual bottom-docked
// keyboard frame is positive initial evidence for this process's gate.
static inline BOOL DF188KeyboardWindowHasActiveFrame(UIWindow *window) {
    if (!DF177IsKeyboardWindow(window) || window.hidden) return NO;
    CGRect frame = window.frame;
    CGRect screen = window.screen ? window.screen.bounds : UIScreen.mainScreen.bounds;
    return CGRectGetMinY(frame) > 0.0 && CGRectGetHeight(frame) > 0.0 &&
           fabs(CGRectGetMaxY(frame) - CGRectGetMaxY(screen)) <= 2.0;
}

static inline BOOL DF188InitialKeyboardSessionVisible(void) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes)
        if ([scene isKindOfClass:UIWindowScene.class])
            for (UIWindow *window in ((UIWindowScene *)scene).windows)
                if (DF188KeyboardWindowHasActiveFrame(window)) return YES;
    for (UIWindow *window in UIApplication.sharedApplication.windows)
        if (DF188KeyboardWindowHasActiveFrame(window)) return YES;
    return NO;
}

static inline BOOL DF177KbComputeVisible(void) {
    if(!DF177KbKnownWindows)DF177KbKnownWindows=[NSHashTable weakObjectsHashTable];
    NSMutableArray *scanned=[NSMutableArray array];
    for(UIScene *scene in UIApplication.sharedApplication.connectedScenes)
        if([scene isKindOfClass:UIWindowScene.class])
            for(UIWindow *window in ((UIWindowScene *)scene).windows)
                if(DF177IsKeyboardWindow(window))[scanned addObject:window];
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
        if(DF177IsKeyboardWindow(window))[scanned addObject:window];
    }
    return DF177KeyboardSnapshot(DF177KbKnownWindows,scanned);
}

static inline void DF177KbSetVisible(BOOL visible) {
    if (!DF177AppTouchEnabled()) return;
    if (!DF177KeyboardBeginPublish(visible,DF177KbVisible,&DF177KbHasPublished)) return;
    @try {
        DF156Mailbox *box=DF177KeyboardChannel(DF177TouchBundle);
        if(!box)return;
        NSDictionary *rec = @{@"version": @2,
                              @"bundle": DF177TouchBundle ?: @"",
                              @"pid": @(getpid()),
                              @"kb": @(visible),
                              @"ts": @(NSDate.date.timeIntervalSince1970)};
        NSData *bytes = [NSJSONSerialization dataWithJSONObject:rec
                                                          options:0 error:nil];
        uint64_t generation = 0;
        arc4random_buf(&generation, sizeof(generation));
        if (bytes && DF156Write(box, bytes.bytes, bytes.length,
                                generation ?: 1) &&
            notify_post(DF177KbWakeName)==NOTIFY_STATUS_OK) {
            DF177KbVisible=visible;
            DF177KbHasPublished=YES;
        }
    } @catch (__unused NSException *e) {}
}

static inline void DF177KbRefreshFromScan(void) {
    if(!NSThread.isMainThread){
        dispatch_async(dispatch_get_main_queue(),^{DF177KbRefreshFromScan();});
        return;
    }
    DF177KbSetVisible(DF177KbComputeVisible());
}

// QA178 h1wake1 swallow state: while the host reports the controls
// hidden, the FIRST touch sequence is consumed whole (the DuoNavi
// wake contract): the app never sees it; the wake signal is its only
// effect. Consumption ends when every swallowed touch has ended or
// been cancelled. A live keyboard in this app disables the gate, so
// typing can never be eaten. Everything else keeps the original H1
// behaviour below: original first, read-only observation afterwards.
static BOOL DF188Swallowing = NO;
static NSMutableSet<NSValue *> *DF188SwallowedTouches = nil;

static void DF177SendEventHook(UIApplication *self, SEL _cmd, UIEvent *event) {
    if (event.type == UIEventTypeTouches) {
        NSSet<UITouch *> *touches = event.allTouches;
        BOOL hasBegan = NO;
        for (UITouch *touch in touches)
            if (touch.phase == UITouchPhaseBegan) { hasBegan = YES; break; }
        if (DF188Swallowing) {
            BOOL intersects = NO;
            for (UITouch *touch in touches)
                if ([DF188SwallowedTouches containsObject:
                        [NSValue valueWithPointer:(const void *)touch]]) {
                    intersects = YES; break;
                }
            if (intersects || hasBegan) {
                for (UITouch *touch in touches) {
                    NSValue *key = [NSValue valueWithPointer:(const void *)touch];
                    if (touch.phase == UITouchPhaseEnded ||
                        touch.phase == UITouchPhaseCancelled)
                        [DF188SwallowedTouches removeObject:key];
                    else
                        [DF188SwallowedTouches addObject:key];
                }
                if (!DF188SwallowedTouches.count) DF188Swallowing = NO;
                return; // consumed: the original never receives this event
            }
            // Unrelated event while a swallowed sequence is in flight:
            // fall through and deliver it normally.
        } else if (hasBegan && DF177AppTouchEnabled()) {
            if (DF188ControlsHiddenKnown && DF188ControlsHidden &&
                !DF188KbSessionVisible) {
                DF188Swallowing = YES;
                if (!DF188SwallowedTouches)
                    DF188SwallowedTouches = [NSMutableSet new];
                [DF188SwallowedTouches removeAllObjects];
                for (UITouch *touch in touches)
                    [DF188SwallowedTouches addObject:
                        [NSValue valueWithPointer:(const void *)touch]];
                DF177AppTouchNoteBeganEx(DF177TouchBundle, YES);
                DF177KbRefreshFromScan();
                return; // wake-only tap: the app never receives it
            }
        }
    }
    // Original first: the app receives the event exactly as before.
    ((void (*)(UIApplication *, SEL, UIEvent *))DF177SendEventOriginal)(
        self, _cmd, event);
    // Read-only observation afterwards.
    if (event.type == UIEventTypeTouches) {
        for (UITouch *touch in event.allTouches) {
            if (touch.phase == UITouchPhaseBegan) {
                DF177AppTouchNoteBegan(DF177TouchBundle);
                DF177KbRefreshFromScan();
                break;
            }
        }
    }
}

// Installs the sendEvent: observation hook once per process. Callers
// gate on their own bundle scope before calling.
static inline void DF177InstallAppTouchHook(NSString *bundle) {
    static BOOL installed = NO;
    if (installed || !bundle.length) return;
    installed = YES;
    DF177TouchBundle = [bundle copy];
    DF188KbSessionVisible = DF188InitialKeyboardSessionVisible();
    Method m = class_getInstanceMethod(UIApplication.class,
                                       @selector(sendEvent:));
    if (!m) return;
    DF177SendEventOriginal = method_getImplementation(m);
    if (DF177SendEventOriginal)
        method_setImplementation(m, (IMP)DF177SendEventHook);
    // QA172 wakefix: keyboard visibility observers for the wake
    // shield. Installed once per process, alongside the touch hook.
    static BOOL kbObserversInstalled = NO;
    if (!kbObserversInstalled) {
        kbObserversInstalled = YES;
        NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
        [nc addObserverForName:UIWindowDidBecomeVisibleNotification
                        object:nil queue:NSOperationQueue.mainQueue
                    usingBlock:^(__unused NSNotification *note) {
            if(DF177IsKeyboardWindow(note.object)){
                if(!DF177KbKnownWindows)
                    DF177KbKnownWindows=[NSHashTable weakObjectsHashTable];
                DF177ObserveKeyboardWindow(DF177KbKnownWindows,note.object,YES);
                DF177KbRefreshFromScan();
            }
        }];
        [nc addObserverForName:UIWindowDidBecomeHiddenNotification
                        object:nil queue:NSOperationQueue.mainQueue
                    usingBlock:^(__unused NSNotification *note) {
            if(DF177IsKeyboardWindow(note.object)){
                DF177ObserveKeyboardWindow(DF177KbKnownWindows,note.object,NO);
                DF177KbRefreshFromScan();
            }
        }];
    }
    // QA179: session notifications affect ONLY the H1 swallow gate.
    // They do not alter DF177's existing DF156 keyboard reports.
    NSNotificationCenter *kbSessionNC = NSNotificationCenter.defaultCenter;
    [kbSessionNC addObserverForName:UIKeyboardWillShowNotification
                            object:nil queue:NSOperationQueue.mainQueue
                        usingBlock:^(__unused NSNotification *note) {
        DF188KbSessionVisible = YES;
    }];
    [kbSessionNC addObserverForName:UIKeyboardWillHideNotification
                            object:nil queue:NSOperationQueue.mainQueue
                        usingBlock:^(__unused NSNotification *note) {
        DF188KbSessionVisible = NO;
    }];
    // QA180: subscribe before querying; the host will reply with exactly
    // one of the two state signals. No controls-state plist is read here.
    if (!DF188ControlsHiddenToken) {
        int token = 0;
        if (notify_register_dispatch(DF188ControlsHiddenName, &token,
                dispatch_get_main_queue(), ^(int __unused t) {
            DF188ControlsHidden = YES;
            DF188ControlsHiddenKnown = YES;
        }) == NOTIFY_STATUS_OK) DF188ControlsHiddenToken = token;
    }
    if (!DF188ControlsShownToken) {
        int token = 0;
        if (notify_register_dispatch(DF188ControlsShownName, &token,
                dispatch_get_main_queue(), ^(int __unused t) {
            DF188ControlsHidden = NO;
            DF188ControlsHiddenKnown = YES;
        }) == NOTIFY_STATUS_OK) DF188ControlsShownToken = token;
    }
    notify_post(DF188ControlsQueryName); // exactly once on hook installation
    // Preserve the independent DF156 keyboard report/refresh.
    DF177KbRefreshFromScan();
}
#endif // DF177_APP_SIDE_SENDER
#endif
