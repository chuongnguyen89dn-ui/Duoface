#include "../DF168NativeManeuver.h"
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
int main(void) {
  DF168Maneuver sample={DF168TurnRight,420,16777213u,1023u}, got={0};
  uint64_t raw=0;
  assert(DF168ManeuverEncode(sample,&raw));
  assert(DF168ManeuverDecode(raw,16777215u,&got));
  assert(got.turn==DF168TurnRight && got.meters==420 && got.sequence==1023u);
  assert(!DF168ManeuverDecode(raw,16777227u,&got)); // stale
  assert(!DF168ManeuverDecode(raw^((uint64_t)1<<56),16777215u,&got)); // magic
  assert(!DF168ManeuverDecode(raw^((uint64_t)1<<52),16777215u,&got)); // version
  sample.turn=DF168TurnUnknown;
  assert(!DF168ManeuverEncode(sample,&raw));
  sample.turn=DF168TurnLeft;sample.meters=0;
  assert(!DF168ManeuverEncode(sample,&raw));
  sample.meters=16001;
  assert(!DF168ManeuverEncode(sample,&raw));
  sample.meters=50;sample.uptimeSeconds=DF168_UPTIME_MASK;
  assert(DF168ManeuverEncode(sample,&raw));
  assert(DF168ManeuverDecode(raw,1u,&got)); // valid wrap age=2
  assert(!DF168ManeuverDecode(raw,20u,&got));
  puts("QA168_CARPLAY_NAV_PACKET_PASS");
  return 0;
}
