#include "../DFDockLifecycle147.h"
#include <assert.h>
#include <stdio.h>
int main(void) {
 DF147Lifecycle s={0};
 DF147BeginGeneration(&s);
 assert(DF147ResultAction(&s,false,true,true,false,true)==DF147Ignore); // older request
 assert(DF147ResultAction(&s,true,false,true,false,true)==DF147Ignore); // stale timestamp
 assert(DF147ResultAction(&s,true,true,false,false,true)==DF147Ignore); // pending-scene
 assert(DF147ResultAction(&s,true,true,true,false,false)==DF147Ignore); // no live PID
 assert(s.pending&&!s.active);
 assert(DF147ResultAction(&s,true,true,true,false,true)==DF147Activate);
 assert(DF147ResultAction(&s,true,true,true,false,true)==DF147Ignore); // duplicate ACK
 assert(DF147ResultAction(&s,false,true,false,true,false)==DF147Ignore); // old stop
 assert(s.active);
 assert(DF147ResultAction(&s,true,true,false,true,false)==DF147Restore);
 assert(!s.active&&!s.pending);
 assert(DF147RevokeGeneration(&s)==DF147Ignore); // idempotent cleanup
 DF147BeginGeneration(&s);
 assert(DF147ResultAction(&s,true,true,false,true,false)==DF147Ignore); // failed before activation
 assert(!s.pending);
 DF147BeginGeneration(&s);
 assert(DF147ResultAction(&s,true,true,true,false,true)==DF147Activate);
 uint64_t generation=s.generation;
 assert(DF147RevokeGeneration(&s)==DF147Restore); // Home/disconnect/native app takeover
 assert(s.generation==generation+1&&!s.active);
 puts("DOCK147_ASYNC_LIFECYCLE_TRANSITIONS_PASS");
}
