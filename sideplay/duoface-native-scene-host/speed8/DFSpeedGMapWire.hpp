#pragma once
// GMapHUD v0.2.3 MIT source-output/source-transport/speed-state wire contract.
// Reimplemented only numeric validation; no third-party HUD renderer or assets.
#include "DFSpeedProtocol.hpp"
#include <cstdint>
#include <cmath>
namespace DFSpeed {
inline Source GVMSource(uint64_t selection) {
    uint64_t id=selection ? selection&7 : 1;
    return id==1 ? Source::VietMap : id==2 ? Source::Waze :
           id==3 ? Source::GOFA : Source::None;
}
inline bool GVMReadValue(uint64_t raw,double now,bool allowZero,
                         uint16_t &value,double &observed) {
    value=0; observed=0;
    if(!(raw&512) || (raw&511)>400 || (!allowZero && !(raw&511)) ||
       !std::isfinite(now) || now<0) return false;
    observed=double(raw>>10)/1000.0;
    const double age=now-observed;
    if(age<0 || age>=5) return false;
    value=uint16_t(raw&511);
    return true;
}
inline bool DecodeGVMFrame(uint64_t selectionBefore,uint64_t selectionAfter,
       uint64_t frameSelection,uint64_t commitBefore,uint64_t commitAfter,
       uint64_t speedRaw,uint64_t limitRaw,double now,Sample &sample) {
    Source source=GVMSource(selectionBefore);
    // GVM per-source commit: low 8 bits schema version 1, high revision even.
    uint64_t revision=commitBefore>>8;
    if(source==Source::None || selectionBefore!=selectionAfter ||
       frameSelection!=selectionBefore || commitBefore!=commitAfter ||
       (commitBefore&255)!=1 || !revision || (revision&1)) return false;
    uint16_t speed=0,limit=0;
    double speedAt=0, limitAt=0;
    bool hs=GVMReadValue(speedRaw,now,true,speed,speedAt);
    bool hl=GVMReadValue(limitRaw,now,false,limit,limitAt) && limit<=200;
    if(!hs && !hl) return false;
    Sample s;
    s.source=source;
    s.speedValid=hs; s.limitValid=hl;
    s.speedKmh=hs?speed:0; s.limitKmh=hl?limit:0;
    // Timestamp conservatively floors original sample time to guarantee TTL.
    s.uptimeSec=uint32_t(std::floor(hs?speedAt:limitAt));
    sample=s;
    return true;
}
} // namespace DFSpeed
