// First-party transport: verified CarPlay route state is optional and expires.
// Never creates a route, camera, speed limit, or synthetic navigation signal.
#import "DF168NativeManeuver.h"
#import <notify.h>
#import <math.h>
static int DF168Token(void) {
  static int token=-1;
  static dispatch_once_t once;
  dispatch_once(&once,^{
    int candidate=-1;
    if(notify_register_check(DF168_MANEUVER_NOTIFY,&candidate)==NOTIFY_STATUS_OK)
      token=candidate;
  });
  return token;
}
BOOL DF168PublishManeuver(DF168Turn turn,NSUInteger meters) {
  if(![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.lumi.GOFA"])
    return NO; // only GOFA's own CarPlay maneuver source may publish
  int token=DF168Token();
  NSTimeInterval up=NSProcessInfo.processInfo.systemUptime;
  if(token<0 || !isfinite(up) || up<0 || up>UINT32_MAX ||
     meters>DF168_MAX_DISTANCE_METERS) return NO;
  static uint16_t seq;
  DF168Maneuver m={(uint8_t)turn,(uint16_t)meters,
                   ((uint32_t)floor(up))&DF168_UPTIME_MASK,
                   (uint16_t)((++seq)&1023u)};
  uint64_t encoded=0;
  return DF168ManeuverEncode(m,&encoded) &&
         notify_set_state(token,encoded)==NOTIFY_STATUS_OK &&
         notify_post(DF168_MANEUVER_NOTIFY)==NOTIFY_STATUS_OK;
}
BOOL DF168ReadManeuver(DF168Maneuver *record) {
  if(!record)return NO;
  *record=(DF168Maneuver){0};
  int token=DF168Token();
  NSTimeInterval up=NSProcessInfo.processInfo.systemUptime;
  if(token<0 || !isfinite(up) || up<0 || up>UINT32_MAX)return NO;
  uint64_t raw=0;
  return notify_get_state(token,&raw)==NOTIFY_STATUS_OK &&
         DF168ManeuverDecode(raw,(uint32_t)floor(up),record);
}
