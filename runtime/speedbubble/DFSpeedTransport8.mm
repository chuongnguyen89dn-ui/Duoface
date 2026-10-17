#import "DFSpeedTransport.h"
#include "DFSpeedProtocol.hpp"
#if defined(DF_SPEED_HUD_SPRINGBOARD)
#include "DFSpeedGMapReader.hpp"
#endif
#include <notify.h>
#include <cmath>
// No timer in source apps; apps publish on real, fresh source changes.
// Darwin notify is process-agnostic but MUST be verified on a jailbroken iPhone.
namespace {
  int gTokens[5] = {-1,-1,-1,-1,-1};
  void Setup() {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
      for (int i=1; i<=4; ++i) {
        const char *name=DFSpeed::NotifyName(static_cast<DFSpeed::Source>(i));
        int token=-1;
        if (notify_register_check(name,&token)==NOTIFY_STATUS_OK)
          gTokens[i]=token;
      }
    });
  }
  uint32_t UptimeSeconds() {
    double t=NSProcessInfo.processInfo.systemUptime;
    return (std::isfinite(t) && t>0) ? static_cast<uint32_t>(t) : 0;
  }
}
BOOL DFSpeedHUDPublish(DFSpeedAppSource src, NSInteger speed, BOOL hasSpeed,
                       NSInteger limit, BOOL hasLimit) {
  if (src<1 || src>4) return NO;
  Setup();
  if (gTokens[src]<0) return NO;
  // Do not infer a speed limit from road type or a previous sample.
  if ((hasSpeed && (speed<0 || speed>400)) ||
      (hasLimit && (limit<=0 || limit>200))) return NO;
  DFSpeed::Sample s;
  s.source=static_cast<DFSpeed::Source>(src);
  s.uptimeSec=UptimeSeconds();
  s.speedKmh=hasSpeed ? static_cast<uint16_t>(speed):0;
  s.limitKmh=hasLimit ? static_cast<uint16_t>(limit):0;
  s.speedValid=hasSpeed; s.limitValid=hasLimit;
  uint64_t encoded=0;
  if (!DFSpeed::Encode(s,encoded)) return NO;
  const char *name=DFSpeed::NotifyName(s.source);
  if (notify_set_state(gTokens[src],encoded)!=NOTIFY_STATUS_OK) return NO;
  return notify_post(name)==NOTIFY_STATUS_OK;
}
BOOL DFSpeedHUDReadBest(DFSpeedHUDRecord *record) {
  if (!record) return NO;
  Setup();
  // One source is always chosen as a unit: no Waze speed + GOFA speed limit.
  uint32_t now=UptimeSeconds();
  // Four app sources feed exactly ONE DuoFace-owned visual bubble.
  NSUserDefaults *prefs=[[NSUserDefaults alloc] initWithSuiteName:@"com.duoface.speedhud"];
  NSInteger pinned=[prefs integerForKey:@"source"];
  if(pinned!=2 && pinned!=3 && pinned!=4) pinned=0;
  // Publish/subscribe are not a request to launch missing apps.
  DFSpeed::Sample live[5];
  size_t count=0;
  for (int src=1; src<=4; ++src) {
    if (pinned && src!=pinned) continue;
    if (gTokens[src]<0) continue;
    uint64_t raw=0;
    if (notify_get_state(gTokens[src],&raw)!=NOTIFY_STATUS_OK) continue;
    DFSpeed::Sample sample;
    if (DFSpeed::Decode(raw,static_cast<DFSpeed::Source>(src),now,sample))
      live[count++]=sample;
  }
  // Read the actual Waze/VietMap/GOFA speed+limit samples published by
  // GMapHUD v0.2.3's source adapters, not their CarPlay HUD/window.
#if defined(DF_SPEED_HUD_SPRINGBOARD)
  DFSpeed::Sample native;
  if (DFSpeed::ReadPinnedGMapWire(native) &&
      (!pinned || static_cast<NSInteger>(native.source)==pinned)) live[count++]=native;
#endif
  static DFSpeed::Source previous=DFSpeed::Source::None;
  DFSpeed::Sample best;
  if (!DFSpeed::ChooseUnifiedSample(live,count,previous,best)) {
    previous=DFSpeed::Source::None;
    return NO;
  }
  previous=best.source;
  record->source=static_cast<DFSpeedAppSource>(best.source);
  record->currentKmh=best.speedKmh;
  record->limitKmh=best.limitKmh;
  record->hasCurrent=best.speedValid;
  record->hasLimit=best.limitValid;
  record->ageSeconds=static_cast<NSTimeInterval>(now-best.uptimeSec);
  return YES;
}
