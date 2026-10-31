// Independent first-party manager receipt: live scene/window, NOT pixels or PID.
// Process observation is a separate gate. No vendor implementation or licensing.
#ifndef DF_MANAGER_LIFECYCLE_149_H
#define DF_MANAGER_LIFECYCLE_149_H
#include <stdbool.h>
#include <stdint.h>
typedef enum { DF149Ignore=0, DF149ManagerActivate=1, DF149ManagerRestore=2 } DF149Action;
typedef struct {
 uint64_t generation;
 bool pending,managerActive,sceneObserved,pidObserved;
} DF149Manager;
static inline void DF149Start(DF149Manager *s) {
 ++s->generation; s->pending=true; s->managerActive=false;
 s->sceneObserved=false; s->pidObserved=false;
}
static inline DF149Action DF149Receive(DF149Manager *s,bool identity,bool fresh,
                                       bool managerSceneLive,bool verifiedPID,bool terminal) {
 if(!identity || !fresh || (!s->pending && !s->managerActive))return DF149Ignore;
 if(terminal) {
   bool was=s->managerActive;
   s->pending=false;s->managerActive=false;s->sceneObserved=false;s->pidObserved=false;
   return was?DF149ManagerRestore:DF149Ignore;
 }
 if(managerSceneLive) {
   s->sceneObserved=true;
   // A coalesced live-host + verified-PID observation must retain BOTH facts.
   if(verifiedPID)s->pidObserved=true;
   if(s->pending) {
     s->pending=false;s->managerActive=true;
     return DF149ManagerActivate;
   }
 }
 if(verifiedPID && s->sceneObserved)s->pidObserved=true;
 return DF149Ignore;
}
static inline DF149Action DF149Revoke(DF149Manager *s) {
 bool was=s->managerActive;
 ++s->generation; s->pending=false;s->managerActive=false;
 s->sceneObserved=false;s->pidObserved=false;
 return was?DF149ManagerRestore:DF149Ignore;
}
#endif
