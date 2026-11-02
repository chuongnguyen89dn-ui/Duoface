//  DF172GOFAEvidenceProtocol.h
//  DuoFace — QA172 shadow-mode evidence channel (diagnostics only).
//
//  Why this exists: Gate G1 (2026-11-02) proved the QA166/167 Darwin
//  discovery channel works from inside the GOFA process, while the
//  probe's detail log file does not survive the GOFA sandbox (writes
//  to /var/mobile/Library/Logs are denied there). QA172 shadow mode
//  therefore reports its decode diagnostics through this channel:
//  one 64-bit notify state on a dedicated notify name, decoded by the
//  DuoFace host process and written into the manual export.
//
//  Privacy contract (carried from QA166/167, unchanged): the state
//  carries NO payload values, NO coordinates, NO key names — only the
//  channel id, the payload value's kind, which normalised fields were
//  present/rejected, a bucketed point count, uptime and a rolling
//  sequence. Type names stay in the GOFA process's NSLog channel.
//
//  Bit layout (cf. DF167GOFAEventProtocol.h, same framing):
//    [63:56] magic 0xD7
//    [55:52] version 2
//    [51:48] event: 1=notificationNextBoard, 2=notificationOtherBoard,
//                   3=notificationSpeedBoard
//    [47:44] valueKind: 0=none, 1=dictionary, 2=array,
//                       3=GOFA object, 4=other   (DF167 kind codes)
//    [43:40] fieldsPresent bitmask (speed channel):
//                       bit0 userSpeed, bit1 speed,
//                       bit2 currentAllowSpeed, bit3 limit
//    [39:36] fieldsRejected bitmask (same layout)
//            — for alert channels these two nibbles carry instead:
//              fieldsPresent = points bucket of accepted points,
//              fieldsRejected = points bucket of rejected points,
//              bucket: 0,1,2,3, 4=4-7, 5=8-15, 6=16-31, 7=32 (cap)
//    [35:8]  uptime seconds (28 bits)
//    [7:0]   sequence (per-process, wraps)

#ifndef DF172_GOFA_EVIDENCE_PROTOCOL_H
#define DF172_GOFA_EVIDENCE_PROTOCOL_H

#include <stdint.h>

#define DF172_GOFA_NOTIFY_NAME "com.duoface.trafficnav.v2.gofa.decoder"
#define DF172_GOFA_MAGIC 0xD7u
#define DF172_GOFA_VERSION 2u
#define DF172_GOFA_MAX_UPTIME ((1u << 28) - 1)

typedef struct {
    uint8_t event;        // 1..3 as above
    uint8_t valueKind;    // 0..4 as above
    uint8_t present;      // speed: field bitmask; alerts: bucket
    uint8_t rejected;     // speed: field bitmask; alerts: bucket
    uint32_t uptime;      // seconds, <= DF172_GOFA_MAX_UPTIME
    uint8_t sequence;
} DF172GOFAEvidence;

static inline uint8_t DF172PointBucket(uint32_t count) {
    if (count == 0) return 0;
    if (count <= 3) return (uint8_t)count;
    if (count <= 7) return 4;
    if (count <= 15) return 5;
    if (count <= 31) return 6;
    return 7;
}

static inline int DF172GOFAEncode(const DF172GOFAEvidence *e,
                                  uint64_t *out) {
    if (!e || !out) return 0;
    if (e->event < 1 || e->event > 3 || e->valueKind > 4) return 0;
    if (e->uptime > DF172_GOFA_MAX_UPTIME) return 0;
    *out = ((uint64_t)DF172_GOFA_MAGIC << 56)
         | ((uint64_t)DF172_GOFA_VERSION << 52)
         | ((uint64_t)(e->event & 0xFu) << 48)
         | ((uint64_t)(e->valueKind & 0xFu) << 44)
         | ((uint64_t)(e->present & 0xFu) << 40)
         | ((uint64_t)(e->rejected & 0xFu) << 36)
         | ((uint64_t)e->uptime << 8)
         | (uint64_t)e->sequence;
    return 1;
}

static inline int DF172GOFADecode(uint64_t raw, double now,
                                  double maxAge, DF172GOFAEvidence *out) {
    if (!out) return 0;
    if ((raw >> 56) != DF172_GOFA_MAGIC) return 0;
    if (((raw >> 52) & 0xFu) != DF172_GOFA_VERSION) return 0;
    DF172GOFAEvidence e;
    e.event = (uint8_t)((raw >> 48) & 0xFu);
    e.valueKind = (uint8_t)((raw >> 44) & 0xFu);
    e.present = (uint8_t)((raw >> 40) & 0xFu);
    e.rejected = (uint8_t)((raw >> 36) & 0xFu);
    e.uptime = (uint32_t)((raw >> 8) & 0xFFFFFFFull);
    e.sequence = (uint8_t)(raw & 0xFFu);
    if (e.event < 1 || e.event > 3 || e.valueKind > 4) return 0;
    if (now < e.uptime || now - e.uptime > maxAge) return 0;
    *out = e;
    return 1;
}

#endif // DF172_GOFA_EVIDENCE_PROTOCOL_H
