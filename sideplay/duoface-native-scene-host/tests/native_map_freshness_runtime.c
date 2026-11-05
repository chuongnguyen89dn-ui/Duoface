#include "../DFNativeMapFreshness.h"
#include <assert.h>
#include <float.h>
#include <stdio.h>

int main(void) {
    assert(DFNativeMapSampleFresh(100,100,0));
    assert(DFNativeMapSampleFresh(102,100,2));
    assert(!DFNativeMapSampleFresh(nextafter(102,INFINITY),100,2));
    assert(!DFNativeMapSampleFresh(99,100,2));
    assert(!DFNativeMapSampleFresh(100,nextafter(100,INFINITY),2));
    assert(!DFNativeMapSampleFresh(100,100,-1));
    assert(!DFNativeMapSampleFresh(NAN,100,2));
    assert(!DFNativeMapSampleFresh(100,NAN,2));
    assert(!DFNativeMapSampleFresh(100,100,NAN));
    assert(!DFNativeMapSampleFresh(INFINITY,100,2));
    assert(!DFNativeMapSampleFresh(100,-INFINITY,2));
    assert(!DFNativeMapSampleFresh(100,100,INFINITY));
    assert(!DFNativeMapSampleFresh(DBL_MAX,-DBL_MAX,DBL_MAX));
    puts("PASS_NATIVE_MAP_FRESHNESS_EXACT_TTL_FUTURE_NONFINITE_OVERFLOW");
    return 0;
}
