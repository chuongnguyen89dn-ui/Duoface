// DuoFace first-party CarPlay maneuver IPC. No proprietary GOFA object layout.
// This protocol carries only a validated turn classification and distance,
// from genuine CarPlay CPManeuver/CPTravelEstimates; never a camera/road limit.
#ifndef DF168_NATIVE_MANEUVER_H
#define DF168_NATIVE_MANEUVER_H
#include <stdint.h>
#define DF168_MANEUVER_NOTIFY "com.duoface.trafficnav.v2.gofa.cpnavigation"
#define DF168_MANEUVER_MAGIC 0xD8u
#define DF168_MANEUVER_VERSION 1u
#define DF168_UPTIME_MASK 0x00ffffffu
#define DF168_MAX_DISTANCE_METERS 16000u
#define DF168_MAX_AGE_SECONDS 12u

typedef enum {
  DF168TurnUnknown=0, DF168TurnLeft=1, DF168TurnRight=2,
  DF168TurnStraight=3, DF168TurnUTurn=4
} DF168Turn;
typedef struct {
  uint8_t turn;
  uint16_t meters;
  uint32_t uptimeSeconds;
  uint16_t sequence;
} DF168Maneuver;

static inline int DF168ManeuverEncode(DF168Maneuver m,uint64_t *out) {
  if(!out || m.turn<DF168TurnLeft || m.turn>DF168TurnUTurn ||
     m.meters<1 || m.meters>DF168_MAX_DISTANCE_METERS ||
     m.uptimeSeconds>DF168_UPTIME_MASK || m.sequence>1023u) return 0;
  *out=((uint64_t)DF168_MANEUVER_MAGIC<<56) |
       ((uint64_t)DF168_MANEUVER_VERSION<<52) |
       ((uint64_t)m.turn<<48) |
       ((uint64_t)m.meters<<34) |
       ((uint64_t)m.uptimeSeconds<<10) | m.sequence;
  return 1;
}
static inline int DF168ManeuverDecode(uint64_t raw,uint32_t now,
                                      DF168Maneuver *out) {
  if(!out || (raw>>56)!=DF168_MANEUVER_MAGIC ||
     ((raw>>52)&15u)!=DF168_MANEUVER_VERSION) return 0;
  DF168Maneuver m={(uint8_t)((raw>>48)&15u),
    (uint16_t)((raw>>34)&0x3fffu),
    (uint32_t)((raw>>10)&DF168_UPTIME_MASK),
    (uint16_t)(raw&1023u)};
  uint32_t age=((now&DF168_UPTIME_MASK)-m.uptimeSeconds)&DF168_UPTIME_MASK;
  if(m.turn<DF168TurnLeft || m.turn>DF168TurnUTurn ||
     m.meters<1 || m.meters>DF168_MAX_DISTANCE_METERS ||
     age>DF168_MAX_AGE_SECONDS) return 0;
  *out=m;return 1;
}
#ifdef __OBJC__
#import <Foundation/Foundation.h>
FOUNDATION_EXPORT BOOL DF168PublishManeuver(DF168Turn turn,NSUInteger meters);
FOUNDATION_EXPORT BOOL DF168ReadManeuver(DF168Maneuver *record);
#endif
#endif
