#ifndef DF_DIVIDER_DRAG_H
#define DF_DIVIDER_DRAG_H
#include <math.h>
#include <stdbool.h>

// Immediate two-axis grip gesture: along divider moves logo; across divider resizes panes.
// The plain divider track only resizes panes; no long-press/timer anywhere.
typedef enum { DFDragUndecided, DFDragRatio, DFDragLogo } DFDragAxis;
typedef struct {
    bool active, vertical, allowLogo;
    DFDragAxis axis;
    double x, y, ratioStart, logoStart, ratio, logo;
    double ratioExtent, logoExtent, maxExcursion;
} DFDividerDrag;
static inline double DFDragClamp(double v, double low, double high) {
    return fmax(low, fmin(high, v));
}
static inline DFDividerDrag DFDragBegin(double x, double y, bool vertical,
                                        double ratio, double logo,
                                        double ratioExtent, double logoExtent) {
    DFDividerDrag d={0};
    d.active=isfinite(x)&&isfinite(y)&&isfinite(ratio)&&isfinite(logo)&&
        isfinite(ratioExtent)&&isfinite(logoExtent)&&ratioExtent>0&&logoExtent>0;
    d.vertical=vertical; d.x=x; d.y=y;
    d.ratioStart=d.ratio=ratio; d.logoStart=d.logo=logo;
    d.ratioExtent=ratioExtent; d.logoExtent=logoExtent;
    return d;
}
static inline void DFDragMove(DFDividerDrag *d, double x, double y) {
    if(!d->active || !isfinite(x) || !isfinite(y))return;
    double dx=x-d->x, dy=y-d->y;
    double perpendicular=d->vertical?dx:dy, parallel=d->vertical?dy:dx;
    d->maxExcursion=fmax(d->maxExcursion,hypot(dx,dy));
    // Lock one direction after real movement to prevent accidental cross-axis
    // changes on a diagonal. Grip: parallel -> logo, perpendicular -> ratio.
    // Bare track: perpendicular -> ratio only, never moves the logo.
    if(d->axis==DFDragUndecided) {
        if(fabs(perpendicular)>7 && fabs(perpendicular)>fabs(parallel)*1.25)
            d->axis=DFDragRatio;
        else if(d->allowLogo && fabs(parallel)>7 &&
                fabs(parallel)>fabs(perpendicular)*1.25)
            d->axis=DFDragLogo;
    }
    if(d->axis==DFDragRatio)
        d->ratio=DFDragClamp(d->ratioStart+perpendicular/d->ratioExtent,1.0/3.0,2.0/3.0);
    else if(d->axis==DFDragLogo)
        d->logo=DFDragClamp(d->logoStart+parallel/d->logoExtent,.1,.9);
}
static inline bool DFDragFinish(DFDividerDrag *d, double x, double y, bool cancelled) {
    if(!d->active)return false;
    // The final event may be the first event with displacement.
    if(!cancelled)DFDragMove(d,x,y);
    bool tap=!cancelled&&d->axis==DFDragUndecided&&d->maxExcursion<=7;
    if(cancelled){d->ratio=d->ratioStart;d->logo=d->logoStart;}
    d->active=false;
    return tap;
}
#endif
