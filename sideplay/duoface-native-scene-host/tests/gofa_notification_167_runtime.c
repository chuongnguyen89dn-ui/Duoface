#include "../DF167GOFAEventProtocol.h"
#include <assert.h>
#include <stdio.h>
int main(void) {
    uint64_t raw=0;
    DF167GOFAEvent e={1,2,3,600,17},out={0};
    assert(DF167GOFAEncode(e,&raw));
    assert(DF167GOFADecode(raw,605,900,&out));
    assert(out.event==1 && out.keys==2 && out.kind==3 && out.uptime==600 && out.sequence==17);
    assert(!DF167GOFADecode(raw,1501,900,&out));
    assert(!DF167GOFADecode(raw,599,900,&out)); // future event
    assert(!DF167GOFADecode(raw^((uint64_t)1<<56),605,900,&out)); // wrong magic
    assert(!DF167GOFADecode(raw^((uint64_t)1<<52),605,900,&out)); // wrong version
    assert(!DF167GOFADecode(raw^((uint64_t)7<<48),605,900,&out)); // invalid event 6
    assert(!DF167GOFAEncode((DF167GOFAEvent){0,0,0,0,0},&raw));
    assert(!DF167GOFAEncode((DF167GOFAEvent){1,0,5,0,0},&raw));
    assert(!DF167GOFAEncode((DF167GOFAEvent){1,0,0,DF167_GOFA_MAX_UPTIME+1u,0},&raw));
    assert(DF167GOFAEncode((DF167GOFAEvent){3,255,4,DF167_GOFA_MAX_UPTIME,255},&raw));
    assert(DF167GOFADecode(raw,DF167_GOFA_MAX_UPTIME,0,&out));
    assert(out.event==3 && out.keys==255 && out.kind==4 && out.sequence==255);
    puts("QA167_GOFA_IPC_PROTOCOL_TEST_OK");
    return 0;
}
