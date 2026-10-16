// DuoFace-owned read-only adapter for GMapHUD 0.2.3 app source transport.
// Decode existing app-source data; DO NOT load GMapHUDOverspeedScreen or
// GMapHUDPlacementRelay (would create an unwanted second CarPlay HUD).
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#include <notify.h>
#include "DFSpeedGMapReader.hpp"
#include "DFSpeedGMapWire.hpp"

namespace DFSpeed {
namespace {
struct SourceWire {
    int slot[5]={-1,-1,-1,-1,-1};
    // index: 0 commit; 1 selection; 2 speed; 3 limit.
    bool ready=false;
};
static int selectionToken=-1;
static SourceWire endpoints[4];
static NSTimeInterval lastRequest=0;
static Source lastRequested=Source::None;
static bool Register(int &token,NSString *name) {
    if(token>=0) return true;
    int value=-1;
    if(notify_register_check(name.UTF8String,&value)!=NOTIFY_STATUS_OK)
        return false;
    token=value; return true;
}
static bool Read(int token,uint64_t &raw) {
    return token>=0 && notify_get_state(token,&raw)==NOTIFY_STATUS_OK;
}
static int GVMID(Source src) {
    switch(src) {
        case Source::VietMap:return 1;
        case Source::Waze:return 2;
        case Source::GOFA:return 3;
        default:return 0;
    }
}
static bool Endpoint(Source src) {
    int id=GVMID(src);
    if(!id) return false;
    SourceWire &w=endpoints[id];
    if(w.ready) return true;
    static NSString *const suffix[]={@"commit",@"selection",@"speed",@"limit"};
    for(int i=0;i<4;i++) {
        NSString *key=[NSString stringWithFormat:
                   @"com.chou.gmaphud.output.v1.%d.%@",id,suffix[i]];
        if(!Register(w.slot[i],key)) return false;
    }
    w.ready=true; return true;
}
static Source ActiveDuoFaceMapApp() {
    // Select only the currently DuoFace-managed source. No location spying,
    // app launching or global SpringBoard process scanning.
    Class cls=NSClassFromString(@"CBBridgeManager");
    SEL get=NSSelectorFromString(@"sharedInstanceIfExists");
    if(!cls || ![cls respondsToSelector:get]) return Source::None;
    id mgr=((id(*)(id,SEL))[cls methodForSelector:get])(cls,get);
    SEL app=NSSelectorFromString(@"bundleIdentifier");
    if(!mgr || ![mgr respondsToSelector:app]) return Source::None;
    id identifier=((id(*)(id,SEL))[mgr methodForSelector:app])(mgr,app);
    if(![identifier isKindOfClass:NSString.class]) return Source::None;
    NSString *bid=identifier;
    if([bid isEqualToString:@"com.waze.iphone"]) return Source::Waze;
    if([bid isEqualToString:@"vn.vietmap.live"]) return Source::VietMap;
    if([bid isEqualToString:@"com.lumi.GOFA"]) return Source::GOFA;
    return Source::None;
}
} // namespace

bool RequestPinnedGMapSource(Source requested) {
    int id=GVMID(requested);
    if(!id) return false; // upstream 0.2.3 has no Google Maps source ID.
    NSTimeInterval now=NSProcessInfo.processInfo.systemUptime;
    if(lastRequested==requested && now-lastRequest<3) return true;
    if(!Register(selectionToken,@"com.chou.gmaphud.source.selection")) return false;
    uint64_t prev=0;
    if(!Read(selectionToken,prev) || (prev>>3)>=(UINT64_MAX>>3)) return false;
    uint64_t next=prev;
    if(GVMSource(prev)!=requested) {
        next=(((prev>>3)+1)<<3)|uint64_t(id);
        if(notify_set_state(selectionToken,next)!=NOTIFY_STATUS_OK) return false;
        if(notify_post("com.chou.gmaphud.source.selection")!=NOTIFY_STATUS_OK)
            return false;
    }
    NSString *request=[NSString stringWithFormat:@"com.chou.gmaphud.source.%d.request",id];
    if(notify_post(request.UTF8String)!=NOTIFY_STATUS_OK) return false;
    lastRequested=requested; lastRequest=now;
    return true;
}

bool ReadPinnedGMapWire(Sample &out) {
    if(!Register(selectionToken,@"com.chou.gmaphud.source.selection"))
        return false;
    // A bridged map in DuoFace is authoritative; no scanning other processes.
    Source active=ActiveDuoFaceMapApp();
    if(active!=Source::None) RequestPinnedGMapSource(active);
    uint64_t selectionBefore=0;
    if(!Read(selectionToken,selectionBefore)) return false;
    Source source=GVMSource(selectionBefore);
    bool accepted=false;
    if(Endpoint(source)) {
        SourceWire &w=endpoints[GVMID(source)];
        uint64_t headerBefore=0,headerAfter=0,frameSelection=0;
        uint64_t speed=0,limit=0,selectionAfter=0;
        if(Read(w.slot[0],headerBefore) &&
           Read(w.slot[1],frameSelection) &&
           Read(w.slot[2],speed) &&
           Read(w.slot[3],limit) &&
           Read(w.slot[0],headerAfter) &&
           Read(selectionToken,selectionAfter)) {
            accepted=DecodeGVMFrame(selectionBefore,selectionAfter,frameSelection,
                headerBefore,headerAfter,speed,limit,
                NSProcessInfo.processInfo.systemUptime,out);
        }
    }
    // GOFA or Waze may run without being a DuoFace split tile. The original
    // GMapHUD 0.2.3 publisher gates output on ONE selected source. If its
    // current source has no fresh speed/limit, probe the next source at most
    // once every 4 seconds. Stop switching on a valid frame; never synthesize
    // limits or launch a third-party app.
    if(!accepted && active==Source::None) {
        static NSTimeInterval lastProbe=0;
        NSTimeInterval now=NSProcessInfo.processInfo.systemUptime;
        if(now>=lastProbe && now-lastProbe>=4) {
            Source next=source==Source::VietMap ? Source::Waze :
                        source==Source::Waze ? Source::GOFA : Source::VietMap;
            if(RequestPinnedGMapSource(next)) lastProbe=now;
        }
    }
    return accepted;
}
} // namespace DFSpeed
