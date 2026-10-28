#ifndef DF_LOGO_HOLD_GATE_H
#define DF_LOGO_HOLD_GATE_H

#include <math.h>
#include <stdbool.h>

// Independent, pure-C policy for the user's explicit 3-second grip hold.
// The surrounding divider track remains immediate ratio pan, but a contact
// originating on the circular grip cannot resize the ratio by accident.
typedef struct {
    bool tracking;
    bool rejected;
    bool unlocked;
    double beganAt;
    double x;
    double y;
} DFLogoHoldGate;

static inline DFLogoHoldGate DFLogoHoldBegin(double now, double x, double y) {
    DFLogoHoldGate g={0};
    if(isfinite(now) && isfinite(x) && isfinite(y)){
        g.tracking=true;g.beganAt=now;g.x=x;g.y=y;
    }
    return g;
}

static inline bool DFLogoHoldAdvance(DFLogoHoldGate *g, double now,
                                     double x, double y, bool vertical) {
    if(!g || !g->tracking || !isfinite(now) || !isfinite(x) ||
       !isfinite(y) || now<g->beganAt)return false;
    if(g->unlocked)return true;
    if(g->rejected)return false;
    double dx=x-g->x, dy=y-g->y;
    double distance=hypot(dx,dy);
    // Moving BEFORE the three seconds cancels this grip drag for the contact.
    // A sideways excursion AFTER the hold cannot turn into a ratio resize.
    if(now-g->beganAt<3.0){
        if(distance>7.0)g->rejected=true;
        return false;
    }
    double parallel=vertical?dy:dx;
    double perpendicular=vertical?dx:dy;
    if(fabs(perpendicular)>7.0 &&
       fabs(perpendicular)>fabs(parallel)*1.25){
        g->rejected=true;return false;
    }
    if(fabs(parallel)>7.0 &&
       fabs(parallel)>fabs(perpendicular)*1.25){
        g->unlocked=true;return true;
    }
    return false;
}

static inline bool DFLogoHoldIsQuickTap(const DFLogoHoldGate *g,
                                       double now, double x, double y,
                                       bool inside, bool cancelled,
                                       bool wakeOnly) {
    return g && g->tracking && !g->rejected && !g->unlocked &&
        !cancelled && !wakeOnly && inside && isfinite(now) &&
        isfinite(x) && isfinite(y) && now>=g->beganAt &&
        now-g->beganAt<=0.5 && hypot(x-g->x,y-g->y)<=7.0;
}
#endif
