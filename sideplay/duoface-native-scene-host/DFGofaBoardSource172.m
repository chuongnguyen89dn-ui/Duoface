//  DFGofaBoardSource172.m
//  DuoFace — QA172 gate G3: shadow-mode observer glue for the
//  clean-room GOFA payload decoder (DFGofaPayloadDecoder172.swift).
//
//  Runs ONLY inside the GOFA process (bundle check below), observes
//  the same three board notifications as the QA166/167 probe, decodes
//  their payloads with the first-party Swift decoder and reports
//  diagnostics through two channels that survive the GOFA sandbox:
//    - NSLog tagged [DuoFaceDecoder172] (device system log), and
//    - the DF172 Darwin evidence state (read by the DuoFace host app
//      and rendered into the manual audit export).
//
//  SHADOW MODE: nothing decoded here reaches the Speed8 HUD or any
//  other process's UI. There is deliberately no publish call in this
//  file. Transport wiring is gate G4, behind a separate flag.
//
//  The QA166/167 probe stays compiled and untouched in this build:
//  its DF167 discovery evidence is the proven liveness baseline the
//  decoder's output is compared against. Removing it is a G4 cleanup
//  decision, not a G3 side effect.
//
//  Privacy: speed/limit values appear only in the device-local NSLog
//  (needed at G3 to compare decoded boards against GOFA's own UI, as
//  DESIGN.md specifies). Alert coordinates are NEVER logged — the
//  alert channel reports type names and counters only. The Darwin
//  state carries no values at all (see DF172GOFAEvidenceProtocol.h).

#import <Foundation/Foundation.h>
#import <notify.h>
#import <stdint.h>
#import <math.h>

#import "DFGofaPayloadDecoder172.h"
#import "DF172GOFAEvidenceProtocol.h"

// At most 2 decodes per second per channel (DESIGN.md throttle).
static const NSTimeInterval DF172MinDecodeInterval = 0.5;

static int DF172NotifyToken = -1;
static uint8_t DF172Sequence = 0;
static NSTimeInterval DF172LastDecode[4] = {0, 0, 0, 0};

// QA175 (T5): all decode work and every shared static above are
// confined to this one serial queue. The observer blocks used to run
// on GOFA's posting thread (queue:nil): the throttle table, evidence
// sequence and notify token raced, and the Swift decoder reflected
// GOFA's live model objects from that foreign thread. Blocks now copy
// the userInfo and hop here; handlers below run only on this queue.
static dispatch_queue_t DF172Queue(void) {
    static dispatch_queue_t q; static dispatch_once_t once;
    dispatch_once(&once, ^{
        q = dispatch_queue_create("com.duoface.gofa.decoder172",
                                  DISPATCH_QUEUE_SERIAL);
    });
    return q;
}
static id DF172ObserverTokens[3];

static uint8_t DF172EventId(NSString *name) {
    if ([name isEqualToString:@"notificationNextBoard"]) return 1;
    if ([name isEqualToString:@"notificationOtherBoard"]) return 2;
    if ([name isEqualToString:@"notificationSpeedBoard"]) return 3;
    return 0;
}

static BOOL DF172ShouldDecode(uint8_t event) {
    NSTimeInterval now = NSProcessInfo.processInfo.systemUptime;
    if (now - DF172LastDecode[event] < DF172MinDecodeInterval)
        return NO;
    DF172LastDecode[event] = now;
    return YES;
}

static void DF172PublishEvidence(uint8_t event, uint8_t valueKind,
                                 uint8_t present, uint8_t rejected) {
    if (DF172NotifyToken < 0) {
        int token = -1;
        if (notify_register_check(DF172_GOFA_NOTIFY_NAME, &token) !=
                NOTIFY_STATUS_OK)
            return;
        DF172NotifyToken = token;
    }
    double seconds = NSProcessInfo.processInfo.systemUptime;
    if (!isfinite(seconds) || seconds < 0 ||
        seconds > DF172_GOFA_MAX_UPTIME)
        return;
    DF172GOFAEvidence e = {event, valueKind, present, rejected,
                           (uint32_t)floor(seconds), ++DF172Sequence};
    uint64_t encoded = 0;
    if (!DF172GOFAEncode(&e, &encoded)) return;
    if (notify_set_state(DF172NotifyToken, encoded) == NOTIFY_STATUS_OK)
        (void)notify_post(DF172_GOFA_NOTIFY_NAME);
}

static NSString *DF172Fmt(NSNumber *value) {
    return value ? [NSString stringWithFormat:@"%.0f", value.doubleValue]
                 : @"nil";
}

static void DF172HandleSpeed(NSDictionary *userInfo) {
    NSDictionary *board =
        [DFGofaDecoder172 decodeSpeedBoardWithUserInfo:userInfo];
    if (!board) return;
    NSDictionary *diag = board[@"diagnostics"];
    uint8_t kind = (uint8_t)[diag[@"valueKind"] unsignedLongValue];
    uint8_t present = (uint8_t)[diag[@"fieldsPresent"] unsignedLongValue];
    uint8_t rejected =
        (uint8_t)[diag[@"fieldsRejected"] unsignedLongValue];
    NSLog(@"[DuoFaceDecoder172] speed type=%@ kind=%lu present=0x%lx "
           "rejected=0x%lx userSpeed=%@ speed=%@ currentAllowSpeed=%@ "
           "limit=%@",
          diag[@"valueTypeName"], (unsigned long)kind,
          (unsigned long)present, (unsigned long)rejected,
          DF172Fmt(board[@"userSpeed"]), DF172Fmt(board[@"speed"]),
          DF172Fmt(board[@"currentAllowSpeed"]), DF172Fmt(board[@"limit"]));
    DF172PublishEvidence(3, kind, present, rejected);
}

static void DF172HandleAlerts(NSString *name, NSDictionary *userInfo,
                              uint8_t event) {
    NSDictionary *result =
        [DFGofaDecoder172 decodeAlertPointsWithNotificationName:name
                                                       userInfo:userInfo];
    NSDictionary *diag = result[@"diagnostics"];
    uint8_t kind = (uint8_t)[diag[@"valueKind"] unsignedLongValue];
    NSUInteger accepted = [diag[@"pointsAccepted"] unsignedLongValue];
    NSUInteger rejected = [diag[@"pointsRejected"] unsignedLongValue];
    // Counters and type names only — never coordinates (privacy rule).
    NSLog(@"[DuoFaceDecoder172] alerts event=%lu type=%@ kind=%lu "
           "accepted=%lu rejected=%lu",
          (unsigned long)event, diag[@"valueTypeName"],
          (unsigned long)kind, (unsigned long)accepted,
          (unsigned long)rejected);
    DF172PublishEvidence(event, kind, DF172PointBucket((uint32_t)accepted),
                         DF172PointBucket((uint32_t)rejected));
}

static void DF172Install(void) {
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    NSArray<NSString *> *names = @[
        @"notificationSpeedBoard",
        @"notificationNextBoard",
        @"notificationOtherBoard",
    ];
    for (NSUInteger i = 0; i < names.count; i++) {
        NSString *name = names[i];
        // QA175 (T5): tokens are kept so the observers have a teardown
        // path; the block copies the payload and hops to the serial
        // decode queue instead of running on GOFA's posting thread.
        DF172ObserverTokens[i] =
            [center addObserverForName:name
                                object:nil
                                 queue:nil
                            usingBlock:^(NSNotification *note) {
                NSDictionary *info = [note.userInfo copy];
                NSString *noteName = note.name;
                dispatch_async(DF172Queue(), ^{
                    uint8_t event = DF172EventId(noteName);
                    if (event == 0 || !DF172ShouldDecode(event)) return;
                    if (event == 3)
                        DF172HandleSpeed(info);
                    else
                        DF172HandleAlerts(noteName, info, event);
                });
            }];
    }
    NSLog(@"[DuoFaceDecoder172] shadow decoder installed in GOFA; "
           "HUD publishing OFF (QA172 G3)");
}

// QA175 (T5): teardown path for the three block observers (the install
// is process-lifetime today, but the tokens are no longer discarded).
__attribute__((unused)) static void DF172RemoveObservers(void) {
    for (int i = 0; i < 3; i++) {
        if (DF172ObserverTokens[i]) {
            [NSNotificationCenter.defaultCenter
                removeObserver:DF172ObserverTokens[i]];
            DF172ObserverTokens[i] = nil;
        }
    }
}

__attribute__((constructor)) static void DF172Start(void) {
    @autoreleasepool {
        if (![NSBundle.mainBundle.bundleIdentifier
                isEqualToString:@"com.lumi.GOFA"])
            return;
        dispatch_async(dispatch_get_main_queue(), ^{
            DF172Install();
        });
    }
}
