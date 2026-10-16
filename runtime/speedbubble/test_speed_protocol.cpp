#include "DFSpeedProtocol.hpp"
#include "DFSpeedGMapWire.hpp"
#include <cassert>
#include <cstring>
#include <iostream>
using namespace DFSpeed;
int main() {
  for(Source s: {Source::GoogleMaps,Source::Waze,Source::VietMap,Source::GOFA}) {
    assert(NotifyName(s)!=nullptr);
    Sample in; in.source=s; in.uptimeSec=1000; in.speedKmh=82;
    in.limitKmh=80; in.speedValid=true; in.limitValid=true;
    uint64_t raw=0; assert(Encode(in,raw));
    Sample out; assert(Decode(raw,s,1001,out));
    assert(out.source==s && out.speedKmh==82 && out.limitKmh==80);
    assert(!Decode(raw,s,1006,out)); // stale source
    assert(!Decode(raw,s,999,out));  // future sample
    assert(!Decode(raw,Source::None,1001,out)); // wrong source
    assert(!Decode(raw^1,s,1001,out)); // wrong schema version
    assert(!Decode(raw^(uint64_t(1)<<28),s,1001,out)); // cross-source mix
    in.limitValid=false; in.limitKmh=99; assert(Encode(in,raw));
    assert(Decode(raw,s,1001,out) && !out.limitValid && out.limitKmh==0);
    in.speedValid=false; in.limitValid=false; assert(!Encode(in,raw));
    in.speedValid=true; in.speedKmh=401; assert(!Encode(in,raw));
    in.speedKmh=0; in.limitValid=true; in.limitKmh=0; assert(!Encode(in,raw));
  }
  // One GOFA-inspired display, four alternative application sources.
  Sample waze; waze.source=Source::Waze; waze.uptimeSec=100;
  waze.speedValid=true; waze.speedKmh=81;
  Sample vietmap; vietmap.source=Source::VietMap; vietmap.uptimeSec=99;
  vietmap.speedValid=true; vietmap.limitValid=true;
  vietmap.speedKmh=79; vietmap.limitKmh=80;
  Sample picked;
  const Sample pair[]={waze,vietmap};
  assert(ChooseUnifiedSample(pair,2,Source::None,picked));
  assert(picked.source==Source::VietMap && picked.limitKmh==80); // prefer complete within 1s
  assert(ChooseUnifiedSample(pair,2,Source::Waze,picked));
  assert(picked.source==Source::VietMap); // complete source wins
  // A strictly newer live reading takes over (no indefinite stickiness).
  waze.uptimeSec=102;
  const Sample newer[]={waze,vietmap};
  assert(ChooseUnifiedSample(newer,2,Source::VietMap,picked));
  assert(picked.source==Source::Waze && !picked.limitValid);
  // When equally fresh and complete, prior source avoids visual thrashing.
  Sample gofa=vietmap; gofa.source=Source::GOFA;
  const Sample ties[]={gofa,vietmap};
  assert(ChooseUnifiedSample(ties,2,Source::GOFA,picked));
  assert(picked.source==Source::GOFA);
  // Never stitch speed from one app with a speed limit from a different app.
  Sample limitOnly=vietmap; limitOnly.source=Source::GoogleMaps;
  limitOnly.speedValid=false; limitOnly.speedKmh=0;
  const Sample split[]={waze,limitOnly};
  assert(ChooseUnifiedSample(split,2,Source::None,picked));
  assert(picked.source==Source::Waze && !picked.limitValid);
  assert(!ChooseUnifiedSample(nullptr,0,Source::None,picked));
  // Pinned GMapHUD 0.2.3 atomic format: schema 1/even revision 2,
  // milliseconds monotonic speed/limit. Never accept torn writes.
  const auto sampleWord=[](unsigned value,unsigned ms) {
      return (uint64_t(ms)<<10)|512|value;
  };
  const uint64_t sel=(uint64_t(3)<<3)|2; // Waze selected + epoch
  Sample gmap;
  assert(DecodeGVMFrame(sel,sel,sel,513,513,
          sampleWord(68,100000),sampleWord(80,100000),101.0,gmap));
  assert(gmap.source==Source::Waze &&
         gmap.speedKmh==68 && gmap.limitKmh==80);
  assert(!DecodeGVMFrame(sel,sel,sel,257,257,
          sampleWord(68,100000),sampleWord(80,100000),101.0,gmap)); // odd commit
  assert(!DecodeGVMFrame(sel,sel,sel,513,769,
          sampleWord(68,100000),sampleWord(80,100000),101.0,gmap)); // torn
  assert(!DecodeGVMFrame(sel,sel+8,sel,513,513,
          sampleWord(68,100000),sampleWord(80,100000),101.0,gmap)); // epoch switch
  assert(!DecodeGVMFrame(sel,sel,sel,513,513,
          sampleWord(68,90000),sampleWord(80,90000),101.0,gmap)); // stale 11s
  assert(DecodeGVMFrame(sel,sel,sel,513,513,
          sampleWord(68,100000),sampleWord(80,90000),101.0,gmap));
  assert(gmap.speedValid && !gmap.limitValid); // no stale speed limit
  assert(GVMSource(1)==Source::VietMap);
  assert(GVMSource(2)==Source::Waze);
  assert(GVMSource(3)==Source::GOFA);
  assert(GVMSource(4)==Source::None); // Google Maps has no GVM source ID
  assert(NotifyName(Source::None)==nullptr);
  std::cout<<"DF_SPEED_PROTOCOL_UNIT_PASS (4 sources, one bubble, arbitration, freshness, unknown limit)"<<std::endl;
}
