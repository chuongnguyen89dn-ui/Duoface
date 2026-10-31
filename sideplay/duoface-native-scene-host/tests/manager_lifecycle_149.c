#include "../DFManagerLifecycle149.h"
#include <assert.h>
#include <stdio.h>
int main(void) {
 DF149Manager s={0};
 DF149Start(&s);
 uint64_t one=s.generation;
 assert(s.pending&&!s.managerActive&&!s.sceneObserved&&!s.pidObserved);
 assert(DF149Receive(&s,false,true,true,false,false)==DF149Ignore);
 assert(DF149Receive(&s,true,false,true,true,false)==DF149Ignore);
 assert(DF149Receive(&s,true,true,false,false,false)==DF149Ignore); // pending mount isn't live
 assert(DF149Receive(&s,true,true,false,true,false)==DF149Ignore); // PID alone must never activate
 assert(s.pending&&!s.managerActive&&!s.pidObserved);
 assert(DF149Receive(&s,true,true,true,false,false)==DF149ManagerActivate); // real host view+scene only
 assert(!s.pending&&s.managerActive&&s.sceneObserved&&!s.pidObserved);
 assert(DF149Receive(&s,true,true,true,false,false)==DF149Ignore); // duplicated manager receipt
 assert(DF149Receive(&s,true,true,true,true,false)==DF149Ignore); // late real PID
 assert(s.managerActive&&s.pidObserved);
 assert(DF149Receive(&s,false,true,false,false,true)==DF149Ignore); // stale STOP
 assert(s.managerActive);
 assert(DF149Receive(&s,true,true,false,false,true)==DF149ManagerRestore);
 assert(!s.managerActive&&!s.sceneObserved&&!s.pidObserved);
 assert(DF149Revoke(&s)==DF149Ignore);
 DF149Start(&s);
 assert(s.generation>one);
 assert(DF149Receive(&s,true,true,true,true,false)==DF149ManagerActivate); // coalesced true PID result
 assert(s.sceneObserved&&s.managerActive&&s.pidObserved);
 assert(DF149Revoke(&s)==DF149ManagerRestore); // native switch/real Home
 assert(!s.managerActive&&!s.pending);
 DF149Start(&s);
 assert(DF149Receive(&s,true,true,false,false,true)==DF149Ignore); // sync host exception
 assert(!s.pending&&!s.managerActive);
 puts("MANAGER149_TRANSACTION_ORDER_AND_LATE_PID_PASS");
 return 0;
}
