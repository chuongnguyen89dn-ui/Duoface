#include "../DFOwnerLeasePolicy.h"
#include <assert.h>
#include <stdio.h>
int main(void) {
    unsigned cases=0;
    for(unsigned bits=0;bits<64;bits++) {
        bool fg=bits&1,bg=bits&2,current=bits&4,external=bits&8,revoked=bits&16,native=bits&32;
        bool result=DFOwnerMayRenew(fg,bg,current,external,revoked,native);
        // Required invariants across all independent input combinations.
        if(!current || !external || revoked)assert(!result);
        if(!fg && !bg)assert(!result);
        if(!fg && bg && !native)assert(!result);
        if(current && external && !revoked && fg)assert(result);
        if(current && external && !revoked && bg && native)assert(result);
        cases++;
    }
    assert(DFOwnerFreshTime(100,100,1.25));
    assert(DFOwnerFreshTime(100,98.75,1.25));
    assert(!DFOwnerFreshTime(100,98.749,1.25));
    assert(!DFOwnerFreshTime(100,100.001,1.25));
    assert(!DFOwnerFreshTime(NAN,100,1.25));
    assert(!DFOwnerFreshTime(100,INFINITY,1.25));
    assert(!DFOwnerFreshTime(INFINITY,100,1.25));
    printf("%u owner state combinations + 7 freshness boundary cases PASS\n",cases);
}
