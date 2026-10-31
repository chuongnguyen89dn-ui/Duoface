#include "../DFNativePrepOnce152.h"
#include <assert.h>
#include <stdio.h>
int main(void){
 DF152Preparation p={0};
 uint64_t first=DF152Begin(&p);
 assert(first && p.pending && !p.resumed);
 assert(!DF152FinishOnce(&p,first+1)); // other request cannot resume
 assert(DF152FinishOnce(&p,first)); // Apple synchronous completion
 assert(!DF152FinishOnce(&p,first)); // later 250ms fallback ignored
 uint64_t second=DF152Begin(&p);
 assert(second>first);
 assert(!DF152FinishOnce(&p,first)); // old Apple late completion
 DF152Revoke(&p); // physical Home / native app switch
 assert(!DF152FinishOnce(&p,second));
 uint64_t third=DF152Begin(&p);
 assert(DF152FinishOnce(&p,third)); // bounded fallback first
 assert(!DF152FinishOnce(&p,third)); // Apple late callback ignored
 DF152Begin(&p);
 DF152Revoke(&p);
 assert(!p.pending && !p.resumed);
 puts("QA152_NATIVE_WORKSPACE_ONCE_GENERATION_CANCELLATION_PASS");
 return 0;
}
