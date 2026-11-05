// Shared clock boundary for native-map ownership and portable regression tests.
#ifndef DF_NATIVE_MAP_FRESHNESS_H
#define DF_NATIVE_MAP_FRESHNESS_H
#include <stdbool.h>
#include <math.h>
static inline bool DFNativeMapSampleFresh(double now,double stamp,double ttl) {
    if(!isfinite(now) || !isfinite(stamp) || !isfinite(ttl) || ttl<0)return false;
    double age=now-stamp;
    return isfinite(age) && age>=0 && age<=ttl;
}
#endif
