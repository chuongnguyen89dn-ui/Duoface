#include "../DFGofaResizePolicy141.h"
#include <assert.h>
#include <stdio.h>
static bool allow(bool active,double target,double window,double parent) {
 return DFGofa141MayResize(active,true,true,true,true,target,685,window,685,parent,685,0,0,0,0);
}
int main(void) {
 // Log19 active mismatches: old maps 793/1190 wide, accepted windows below.
 double targets[]={1190,793,793,397,793};
 for(unsigned i=0;i<5;i++)assert(allow(true,targets[i],targets[i],targets[i]));
 assert(!allow(false,375,375,375)); // phone/inactive sample must not be repaired
 assert(!allow(true,1190,793,793)); // host and app window still disagree
 assert(!allow(true,1190,1190,793)); // actual parent not yet resized
 assert(!allow(true,NAN,793,793));
 assert(!DFGofa141MayResize(true,false,true,true,true,793,685,793,685,793,685,0,0,0,0));
 assert(!DFGofa141MayResize(true,true,false,true,true,793,685,793,685,793,685,0,0,0,0));
 assert(!DFGofa141MayResize(true,true,true,false,true,793,685,793,685,793,685,0,0,0,0));
 assert(!DFGofa141MayResize(true,true,true,true,false,793,685,793,685,793,685,0,0,0,0));
 assert(!DFGofa141MayResize(true,true,true,true,true,793,685,793,685,793,685,1,0,0,0));
 assert(DFGofa141Same(793,793));assert(!DFGofa141Same(793,1190));
 puts("QA141_GOFA_LOG19_DIMENSION_GATES_PASS");return 0;
}
