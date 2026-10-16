#pragma once
// DuoFace-owned speed HUD protocol; not a copy of third-party tweak code.
// One atomic Darwin notify state per installed app source. All speeds are km/h.
#include <cstdint>
#include <cmath>
#include <cstddef>

namespace DFSpeed {
enum class Source : uint8_t { None=0, GoogleMaps=1, Waze=2, VietMap=3, GOFA=4 };
struct Sample {
    Source source=Source::None;
    uint32_t uptimeSec=0;
    uint16_t speedKmh=0, limitKmh=0;
    bool speedValid=false, limitValid=false;
};
// 64-bit payload: [uptimeSec:32][source:4][speed:12][limit:12][valid:2][version:2].
// Version 1; zero/unknown is never silently treated as a posted speed limit.
constexpr uint64_t kVersion=1;
constexpr uint32_t kMaxAgeSeconds=5;  // stale / suspended app: hide
inline bool ValidSource(Source source) {
    return source==Source::GoogleMaps || source==Source::Waze ||
           source==Source::VietMap || source==Source::GOFA;
}
inline const char *NotifyName(Source source) {
    switch(source) {
        case Source::GoogleMaps:return "com.duoface.speedhud.v1.googlemaps";
        case Source::Waze:return "com.duoface.speedhud.v1.waze";
        case Source::VietMap:return "com.duoface.speedhud.v1.vietmap";
        case Source::GOFA:return "com.duoface.speedhud.v1.gofa";
        default:return nullptr;
    }
}
inline bool Encode(const Sample &s, uint64_t &out) {
    if(!ValidSource(s.source) || (!s.speedValid && !s.limitValid) ||
       (s.speedValid && s.speedKmh>400) ||
       (s.limitValid && (s.limitKmh==0 || s.limitKmh>200))) return false;
    out=(uint64_t(s.uptimeSec)<<32) |
        (uint64_t(uint8_t(s.source))<<28) |
        (uint64_t(s.speedValid?s.speedKmh:0)<<16) |
        (uint64_t(s.limitValid?s.limitKmh:0)<<4) |
        (uint64_t(s.speedValid?1:0)<<3) |
        (uint64_t(s.limitValid?1:0)<<2) | kVersion;
    return true;
}
inline bool Decode(uint64_t raw, Source expected, uint32_t now, Sample &out) {
    if((raw&3)!=kVersion) return false;
    Sample s;
    s.source=Source((raw>>28)&15);
    s.uptimeSec=uint32_t(raw>>32);
    s.speedKmh=uint16_t((raw>>16)&0xfff);
    s.limitKmh=uint16_t((raw>>4)&0xfff);
    s.speedValid=((raw>>3)&1)!=0;
    s.limitValid=((raw>>2)&1)!=0;
    if(s.source!=expected || !ValidSource(s.source) ||
       (!s.speedValid && !s.limitValid) ||
       (s.speedValid && s.speedKmh>400) ||
       (s.limitValid && (s.limitKmh==0 || s.limitKmh>200)) ||
       (!s.speedValid && s.speedKmh!=0) ||
       (!s.limitValid && s.limitKmh!=0) ||
       now<s.uptimeSec || now-s.uptimeSec>kMaxAgeSeconds) return false;
    out=s;
    return true;
}
// Select ONE coherent provider at a time for ONE GOFA-style bubble.
// The caller has already decoded and freshness-checked every candidate.
// Never combine one provider's GPS speed with another provider's road limit.
// Prefer a complete sample within one second of the newest live speed,
// and retain the current source on otherwise equal quality to avoid flicker.
inline bool ChooseUnifiedSample(const Sample *data, size_t count,
                                Source previous, Sample &selected) {
    if (!data || !count) return false;
    bool anySpeed=false, found=false;
    uint32_t newest=0;
    for (size_t i=0;i<count;++i) {
        if (!ValidSource(data[i].source)) continue;
        if (data[i].speedValid) anySpeed=true;
    }
    for (size_t i=0;i<count;++i) {
        const Sample &s=data[i];
        if (!ValidSource(s.source) ||
            (anySpeed && !s.speedValid) ||
            (!s.speedValid && !s.limitValid)) continue;
        if (s.uptimeSec>newest) newest=s.uptimeSec;
    }
    int bestQuality=-1;
    for (size_t i=0;i<count;++i) {
        const Sample &s=data[i];
        if (!ValidSource(s.source) ||
            (anySpeed && !s.speedValid) ||
            (!s.speedValid && !s.limitValid) ||
            s.uptimeSec>newest || newest-s.uptimeSec>1) continue;
        const int quality=(s.speedValid?4:0)+(s.limitValid?2:0)+
                          (s.source==previous?1:0);
        if (!found || quality>bestQuality ||
            (quality==bestQuality && s.uptimeSec>selected.uptimeSec)) {
            selected=s; bestQuality=quality; found=true;
        }
    }
    return found;
}
} // namespace DFSpeed
