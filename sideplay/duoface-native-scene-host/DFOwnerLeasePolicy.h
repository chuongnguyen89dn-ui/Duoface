#ifndef DF_OWNER_LEASE_POLICY_H
#define DF_OWNER_LEASE_POLICY_H
#include <stdbool.h>
#include <math.h>
// Background can retain an existing owner only with independent live evidence.
static inline bool DFOwnerMayRenew(bool foreground, bool background,
    bool currentSession, bool externalVisible, bool revoked, bool nativeOwner) {
    return currentSession && externalVisible && !revoked &&
           (foreground || (background && nativeOwner));
}
static inline bool DFOwnerFreshTime(double now, double stamp, double limit) {
    double age=now-stamp;
    return isfinite(now) && isfinite(stamp) && isfinite(age) && age>=0 && age<=limit;
}
#endif
