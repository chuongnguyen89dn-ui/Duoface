// QA176: speed-HUD single-owner arbitration by lease priority.
// Step-0 census (source + the QA175-built binaries): THREE presenters
// render DFNative8SpeedHUDView on the SAME external (CarPlay) display —
// Chrome gofaSpeedHUD (SpringBoard window), DF144-SB speedHUD
// (SpringBoard window; the pair anchors at the identical top-right
// position with the same saved position, so they stack exactly), and
// DFSpeedNativeOverlay163 (CarPlay process, subview of a CarPlay
// window). There is NO DF144Solo presenter in the CarPlay process: the
// dock-owner binary contains only DF144's CarPlay-region code and the
// overlay. Overlay163 already yielded to the DF144-SB lease and to the
// Chrome session pulse; the missing arbitration was Chrome <-> DF144-SB
// and a HUD-scoped (not session-scoped) Chrome signal for the overlay.
// Rule: a presenter publishes a lease ONLY while its HUD is actually
// visible; a lower presenter yields (hides, never destroys) while a
// higher lease is fresh, and resumes when it goes stale.
// Priority: Chrome > DF144-SB > DFSpeedNativeOverlay163.
// DF144 SpringBoard reuses its long-standing standalone lease record
// (HUDOwnerVisible + HUDOwner, 0.7s heartbeat) as its HUD lease; no new
// file for it. Leases are single-writer files, like the existing ones.
#ifndef DF_SPEED_HUD_LEASE_176_H
#define DF_SPEED_HUD_LEASE_176_H
#import <Foundation/Foundation.h>
#import <math.h>

static NSString *const DF176HUDLeaseChromePath =
    @"/var/mobile/Library/Preferences/com.duoface.speedhud.lease176.chrome.plist";
static NSString *const DF176HUDLeaseDF144SBPath =
    @"/var/mobile/Library/Preferences/com.duoface.nativehost.standalone144-sb-lease.plist";
// Freshness window doubles as the handover hysteresis (work order: ~2s).
static const NSTimeInterval kDF176HUDLeaseFreshSeconds = 2.0;

static inline BOOL DF176HUDLeaseFresh(NSString *path, NSString *owner) {
    NSDictionary *p = [NSDictionary dictionaryWithContentsOfFile:path];
    if (![p isKindOfClass:NSDictionary.class]) return NO;
    if (![p[@"HUDOwnerVisible"] isEqual:@YES]) return NO;
    if (owner && ![p[@"HUDOwner"] isEqualToString:owner]) return NO;
    if (![p[@"Timestamp"] isKindOfClass:NSNumber.class]) return NO;
    NSTimeInterval age = NSDate.date.timeIntervalSince1970 -
                         [p[@"Timestamp"] doubleValue];
    return isfinite(age) && age >= 0 && age <= kDF176HUDLeaseFreshSeconds;
}

static inline void DF176HUDLeasePublish(NSString *path, NSString *owner) {
    NSDictionary *p = @{@"Version" : @1,
                        @"HUDOwner" : owner,
                        @"HUDOwnerVisible" : @YES,
                        @"Timestamp" : @(NSDate.date.timeIntervalSince1970)};
    [p writeToFile:path atomically:YES];
}

static inline void DF176HUDLeaseRetract(NSString *path) {
    [NSFileManager.defaultManager removeItemAtPath:path error:nil];
}
#endif
