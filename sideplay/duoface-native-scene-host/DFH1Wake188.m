// QA178 h1wake1 — host-side half of the QA177 H1 controls recall,
// kept in this companion translation unit so DFNative12Chrome.m stays
// byte-identical to the QA171 base. Compiled into DFTouchOwnerProbe
// alongside DFNative12Chrome.m (see build.sh).
//
// What it does, mirroring the QA172R wiring that passed on device:
//  - swizzles -[DFNative12Chrome start] to register for the DF156
//    app-touch wake (DF177TouchWakeName) and -stop to cancel it;
//  - on a wake, reads the bounded DF156 record {bundle,pid,count,ts,
//    swallowed} and calls -noteUserActivity — the exact 171 entry
//    point the original H1 used to recall the controls;
//  - swizzles -layoutControls to publish the controls-hidden state
//    (same computation layoutControls itself applies) into the qa177
//    prefs plist + a Darwin notify, which is what the app-side
//    swallow gate in DFAppTouch177.h consumes. Publishing is
//    change-only and fail-open: any doubt, nothing is written and the
//    relays keep their last known state (unknown = never swallow).
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#include <notify.h>
#import "DFNative12Chrome.h"
#import "DFDeepTrace.h"
#import "DF156DarwinMailbox.h"
#import "DFAppTouch177.h"
#import "DFAppTouchPolicy177.h"

@interface DFNative12Chrome (DFH1Wake188)
- (void)noteUserActivity;
- (void)layoutControls;
@end

static const char *const DF188ControlsStateName = "com.duoface.controls188.state";
static NSString *const DF188ControlsHiddenKey = @"ControlsHidden188";

static __weak DFNative12Chrome *DF188CurrentChrome = nil;
static int DF188WakeToken = 0;
static DF156Mailbox DF188TouchBox;
static BOOL DF188TouchBoxReady = NO;
static uint64_t DF188LastCount = 0;
static BOOL DF188LastHidden = NO;
static BOOL DF188HiddenPublished = NO;

static void DF188PublishHidden(DFNative12Chrome *chrome, BOOL force) {
    BOOL hidden = YES;
    @try {
        BOOL pan = [[chrome valueForKey:@"panActive"] boolValue];
        BOOL pending = [[chrome valueForKey:@"logoTouchPending"] boolValue];
        double until = [[chrome valueForKey:@"controlsUntil"] doubleValue];
        hidden = !(pan || pending ||
                   NSDate.date.timeIntervalSince1970 <= until);
    } @catch (__unused NSException *e) {
        return; // fail open: publish nothing
    }
    if (!force && DF188HiddenPublished && hidden == DF188LastHidden) return;
    DF188LastHidden = hidden;
    DF188HiddenPublished = YES;
    @try {
        NSMutableDictionary *p = [NSMutableDictionary new];
        NSDictionary *existing =
            [NSDictionary dictionaryWithContentsOfFile:DF177TouchPrefsPath];
        if ([existing isKindOfClass:NSDictionary.class])
            [p addEntriesFromDictionary:existing];
        p[DF188ControlsHiddenKey] = @(hidden);
        if ([p writeToFile:DF177TouchPrefsPath atomically:YES]) {
            notify_post(DF188ControlsStateName);
            DFDeepTrace(@"chrome", [NSString stringWithFormat:
                @"qa188-h1-controls-state hidden=%d", (int)hidden]);
        }
    } @catch (__unused NSException *e) {}
}

static void DF188HandleAppTouch(DFNative12Chrome *chrome) {
    if (!DF177AppTouchEnabled()) return;
    if (!DF188TouchBoxReady) {
        DF156Init(&DF188TouchBox, DF177TouchMailboxName);
        DF188TouchBoxReady = YES;
    }
    uint8_t bytes[DF156_MAX_BYTES];
    size_t size = DF156Read(&DF188TouchBox, bytes);
    if (!size) return;
    id rec = [NSJSONSerialization
        JSONObjectWithData:[NSData dataWithBytes:bytes length:size]
                   options:0 error:nil];
    if (![rec isKindOfClass:NSDictionary.class]) return;
    NSString *bundle = rec[@"bundle"];
    if (![bundle isKindOfClass:NSString.class] || !bundle.length) return;
    uint64_t count = [rec[@"count"] unsignedLongLongValue];
    NSTimeInterval ts = [rec[@"ts"] doubleValue];
    BOOL swallowed = [rec[@"swallowed"] boolValue];
    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    if (ts <= 0 || ts > now + 1.0 || now - ts > DF177AppTouchMaximumAge)
        return;
    if (count && count == DF188LastCount) return; // duplicate wakeup
    DF188LastCount = count;
    DFDeepTrace(@"chrome", [NSString stringWithFormat:
        @"qa188-h1-app-touch-wake bundle=%@ count=%llu swallowed=%d",
        bundle, (unsigned long long)count, (int)swallowed]);
    [chrome noteUserActivity];
}

static BOOL (*DF188OrigStart)(id, SEL) = NULL;
static BOOL DF188Start(DFNative12Chrome *self, SEL _cmd) {
    BOOL ok = DF188OrigStart(self, _cmd);
    DF188CurrentChrome = self;
    if (ok && !DF188WakeToken && DF177AppTouchEnabled()) {
        int token = 0;
        if (notify_register_dispatch(DF177TouchWakeName, &token,
                dispatch_get_main_queue(), ^(int __unused t) {
            DFNative12Chrome *owner = DF188CurrentChrome;
            if (owner) DF188HandleAppTouch(owner);
        }) == NOTIFY_STATUS_OK) DF188WakeToken = token;
    }
    if (ok) DF188PublishHidden(self, YES);
    return ok;
}

static void (*DF188OrigStop)(id, SEL) = NULL;
static void DF188Stop(DFNative12Chrome *self, SEL _cmd) {
    if (DF188WakeToken) { notify_cancel(DF188WakeToken); DF188WakeToken = 0; }
    if (DF188CurrentChrome == self) DF188CurrentChrome = nil;
    DF188OrigStop(self, _cmd);
}

static void (*DF188OrigLayout)(id, SEL) = NULL;
static void DF188Layout(DFNative12Chrome *self, SEL _cmd) {
    DF188OrigLayout(self, _cmd);
    DF188PublishHidden(self, NO);
}

static void DF188Swap(Class cls, SEL sel, IMP imp, IMP *orig) {
    Method m = class_getInstanceMethod(cls, sel);
    if (!m) return;
    IMP o = method_getImplementation(m);
    if (!o) return;
    *orig = o;
    method_setImplementation(m, imp);
}

__attribute__((constructor)) static void DF188Install(void) {
    @autoreleasepool {
        Class cls = NSClassFromString(@"DFNative12Chrome");
        if (!cls) return;
        DF188Swap(cls, @selector(start), (IMP)DF188Start, (IMP *)&DF188OrigStart);
        DF188Swap(cls, @selector(stop), (IMP)DF188Stop, (IMP *)&DF188OrigStop);
        DF188Swap(cls, @selector(layoutControls), (IMP)DF188Layout,
                  (IMP *)&DF188OrigLayout);
    }
}
