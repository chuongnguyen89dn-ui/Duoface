// QA167: privacy-limited cross-process proof of GOFA notification delivery.
// This protocol conveys ONLY event name index, object category, number of
// userInfo keys, sender uptime and sequence. No route, GPS or alert values.
// Magic/version prevent interpreting an unrelated notify-state as GOFA data.
#ifndef DF167_GOFA_EVENT_PROTOCOL_H
#define DF167_GOFA_EVENT_PROTOCOL_H
#include <stdint.h>
#define DF167_GOFA_NOTIFY_NAME "com.duoface.trafficnav.v1.gofa.discovery"
#define DF167_GOFA_MAGIC 0xD7u
#define DF167_GOFA_VERSION 1u
#define DF167_GOFA_MAX_UPTIME 0x0fffffffu
typedef struct {
    uint8_t event; // 1=notificationNextBoard, 2=notificationOtherBoard, 3=notificationSpeedBoard
    uint8_t keys;  // 0..255, saturated
    uint8_t kind;  // 0=none,1=dictionary,2=array,3=GOFA object,4=other
    uint32_t uptime; // monotonic sender uptime seconds, 28 bits
    uint8_t sequence;
} DF167GOFAEvent;
static inline int DF167GOFAEncode(DF167GOFAEvent e,uint64_t *out) {
    if(!out || e.event<1 || e.event>3 || e.kind>4 || e.uptime>DF167_GOFA_MAX_UPTIME)return 0;
    *out=((uint64_t)DF167_GOFA_MAGIC<<56)|((uint64_t)DF167_GOFA_VERSION<<52)
        |((uint64_t)e.event<<48)|((uint64_t)e.keys<<40)
        |((uint64_t)e.kind<<36)|((uint64_t)e.uptime<<8)|e.sequence;
    return 1;
}
static inline int DF167GOFADecode(uint64_t raw,uint32_t now,uint32_t maxAge,DF167GOFAEvent *out) {
    if(!out || (raw>>56)!=DF167_GOFA_MAGIC || ((raw>>52)&0x0fu)!=DF167_GOFA_VERSION)return 0;
    DF167GOFAEvent e={(uint8_t)((raw>>48)&15u),(uint8_t)((raw>>40)&255u),
         (uint8_t)((raw>>36)&15u),(uint32_t)((raw>>8)&DF167_GOFA_MAX_UPTIME),
         (uint8_t)(raw&255u)};
    if(e.event<1 || e.event>3 || e.kind>4 || now<e.uptime || now-e.uptime>maxAge)return 0;
    *out=e;return 1;
}
#endif
