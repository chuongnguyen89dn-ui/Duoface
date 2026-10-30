#include "../DFManualObserverContract.h"
#include <assert.h>
#include <stdio.h>
int main(void) {
    unsigned cases=0;
    // Exhaustive authorization matrix; visibility/presentation never grants
    // callback ownership to foreign/automatic/stale controllers.
    for(unsigned mask=0;mask<64;mask++) {
        bool mainThread=mask&1, registered=mask&2, currentHandle=mask&4;
        bool scene=mask&8, abi=mask&16, automatic=mask&32;
        bool expected=mask==31;
        for(unsigned visible=0;visible<2;visible++) {
            bool actual=DFManualObserverOwnsCallback(mainThread,registered,
                currentHandle,scene,abi,automatic);
            assert(actual==expected);
            // Old callback gate additionally required the presentation probe.
            // During window detach it forwarded a current manual controller.
            bool oldConsumed=actual && visible;
            if(mask==31 && !visible) {
                assert(!oldConsumed);
                assert(actual);
            }
            cases++;
        }
    }
    printf("PASS %u callback/visibility cases; detached-manual counterexample reproduced\n",cases);
    return 0;
}
