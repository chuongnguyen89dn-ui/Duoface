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
// Payload is a bounded latest-value JSON record {bundle, count, ts};
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
#import "DF156DarwinMailbox.h"

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
static const char *const DF177KbMailboxName = "com.duoface.ipc.v177.kbstate";
static const NSTimeInterval kDF177TouchThrottleSeconds = 0.25;

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

static inline void DF177AppTouchNoteBegan(NSString *bundle) {
    if (!bundle.length || !DF177AppTouchEnabled()) return;
    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    if (now - DF177TouchLastSentAt < kDF177TouchThrottleSeconds) return;
    DF177TouchLastSentAt = now;
    DF177TouchCount++;
    @try {
        if (!DF177TouchBoxReady) {
            DF156Init(&DF177TouchBox, DF177TouchMailboxName);
            DF177TouchBoxReady = YES;
        }
        NSDictionary *rec = @{@"version": @1, @"bundle": bundle,
                              @"count": @(DF177TouchCount), @"ts": @(now)};
        NSData *bytes = [NSJSONSerialization dataWithJSONObject:rec
                                                          options:0 error:nil];
        uint64_t generation = 0;
        arc4random_buf(&generation, sizeof(generation));
        if (bytes && DF156Write(&DF177TouchBox, bytes.bytes, bytes.length,
                                generation ?: 1))
            notify_post(DF177TouchWakeName);
    } @catch (__unused NSException *e) {}
}

static IMP DF177SendEventOriginal = NULL;
static NSString *DF177TouchBundle = nil;

// QA172 wakefix keyboard state sender. Sent only on change. The
// visibility notification is the trigger and a window scan is the
// state read, with a corrective scan on every Began touch (the
// QA178 lesson: a bare poll can miss the keyboard window in the
// app's window list; a visibility notification does not depend on
// enumeration timing, and the event object names the window).
static DF156Mailbox DF177KbBox;
static BOOL DF177KbBoxReady = NO;
static BOOL DF177KbVisible = NO;

static inline BOOL DF177KbComputeVisible(void) {
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
        if (!window.hidden &&
            [NSStringFromClass(window.class)
                isEqualToString:@"UIRemoteKeyboardWindow"])
            return YES;
    }
    return NO;
}

static inline void DF177KbSetVisible(BOOL visible) {
    if (!DF177AppTouchEnabled()) return;
    if (visible == DF177KbVisible && DF177KbBoxReady) return;
    DF177KbVisible = visible;
    @try {
        if (!DF177KbBoxReady) {
            DF156Init(&DF177KbBox, DF177KbMailboxName);
            DF177KbBoxReady = YES;
        }
        NSDictionary *rec = @{@"version": @1,
                              @"bundle": DF177TouchBundle ?: @"",
                              @"kb": @(visible),
                              @"ts": @(NSDate.date.timeIntervalSince1970)};
        NSData *bytes = [NSJSONSerialization dataWithJSONObject:rec
                                                          options:0 error:nil];
        uint64_t generation = 0;
        arc4random_buf(&generation, sizeof(generation));
        if (bytes && DF156Write(&DF177KbBox, bytes.bytes, bytes.length,
                                generation ?: 1))
            notify_post(DF177KbWakeName);
    } @catch (__unused NSException *e) {}
}

static inline void DF177KbRefreshFromScan(void) {
    DF177KbSetVisible(DF177KbComputeVisible());
}

static void DF177SendEventHook(UIApplication *self, SEL _cmd, UIEvent *event) {
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
            if ([NSStringFromClass(note.object.class)
                    isEqualToString:@"UIRemoteKeyboardWindow"])
                DF177KbSetVisible(YES);
        }];
        [nc addObserverForName:UIWindowDidBecomeHiddenNotification
                        object:nil queue:NSOperationQueue.mainQueue
                    usingBlock:^(__unused NSNotification *note) {
            if ([NSStringFromClass(note.object.class)
                    isEqualToString:@"UIRemoteKeyboardWindow"])
                DF177KbRefreshFromScan();
        }];
    }
}
#endif // DF177_APP_SIDE_SENDER
#endif
