#include "DFSpeedProtocol.hpp"
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
  assert(NotifyName(Source::None)==nullptr);
  std::cout<<"DF_SPEED_PROTOCOL_UNIT_PASS (4 sources, freshness, ABI, unknown limit)"<<std::endl;
}
