// DuoFace-owned cross-process speed transport. GOFA-only QA162 pilot.
// The values contain GPS speed only; no guessed road speed limit.
#import "DFSpeedTransport.h"
#include "DFSpeedProtocol.hpp"
#import <notify.h>
#import <Foundation/Foundation.h>
#include <stdint.h>
#include <math.h>

static int DFGOFANotifyToken(void) {
    static int token = -1;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        if (notify_register_check(DFSpeed::NotifyName(DFSpeed::Source::GOFA), &token) != NOTIFY_STATUS_OK) {
            token = -1;
        }
    });
    return token;
}

extern "C" BOOL DFSpeedHUDPublish(DFSpeedAppSource source,
                                   NSInteger currentKmh, BOOL hasCurrent,
                                   NSInteger limitKmh, BOOL hasLimit) {
    if (source != DFSpeedAppSourceGOFA || !hasCurrent || hasLimit ||
        currentKmh < 0 || currentKmh > 400 || limitKmh != 0) return NO;
    int token = DFGOFANotifyToken();
    if (token < 0) return NO;
    NSTimeInterval uptime = [NSProcessInfo processInfo].systemUptime;
    if (!isfinite(uptime) || uptime < 0 || uptime > UINT32_MAX) return NO;
    DFSpeed::Sample sample;
    sample.source = DFSpeed::Source::GOFA;
    sample.uptimeSec = (uint32_t)floor(uptime);
    sample.speedKmh = (uint16_t)currentKmh;
    sample.speedValid = true;
    sample.limitValid = false; // GOFA GPS does not provide a verified road limit.
    uint64_t data = 0;
    if (!DFSpeed::Encode(sample, data)) return NO;
    if (notify_set_state(token, data) != NOTIFY_STATUS_OK) return NO;
    return notify_post(DFSpeed::NotifyName(DFSpeed::Source::GOFA)) == NOTIFY_STATUS_OK;
}

extern "C" BOOL DFSpeedHUDReadBest(DFSpeedHUDRecord *record) {
    if (!record) return NO;
    *record = (DFSpeedHUDRecord){};
    int token = DFGOFANotifyToken();
    if (token < 0) return NO;
    uint64_t data = 0;
    if (notify_get_state(token, &data) != NOTIFY_STATUS_OK) return NO;
    NSTimeInterval uptime = [NSProcessInfo processInfo].systemUptime;
    if (!isfinite(uptime) || uptime < 0 || uptime > UINT32_MAX) return NO;
    DFSpeed::Sample sample;
    if (!DFSpeed::Decode(data, DFSpeed::Source::GOFA,
                         (uint32_t)floor(uptime), sample)) return NO;
    record->source = DFSpeedAppSourceGOFA;
    record->hasCurrent = sample.speedValid;
    record->currentKmh = sample.speedKmh;
    record->hasLimit = sample.limitValid;
    record->limitKmh = sample.limitValid ? sample.limitKmh : 0;
    record->ageSeconds = uptime - sample.uptimeSec;
    return YES;
}
