#include "DFSPNative12Gestures.h"
#include <math.h>
#include <stddef.h>
#define R_MIN (1.0/3.0)
#define R_MAX (2.0/3.0)
static double clamp(double n, double a, double b) {
    return fmax(a, fmin(b,n));
}
void DFSPGestureReset(DFSPGestureState *s,double ratio,double position) {
    if(!s)return;
    s->ratio=isfinite(ratio)?clamp(ratio,R_MIN,R_MAX):0.5;
    s->logoFraction=isfinite(position)?clamp(position,0.1,0.9):0.5;
    s->logoHeld=0;
    s->logoMoved=0;
    s->logoPressed=0;
}
DFSPGestureEffect DFSPGestureRatioPan(DFSPGestureState *s,double across,int ended) {
    if (!s || !isfinite(across) || s->logoPressed || s->logoHeld)
        return DFSP_GESTURE_NONE;
    double r=clamp(across,R_MIN,R_MAX);
    if(ended) {
        const double stops[]={R_MIN,0.5,R_MAX};
        for(unsigned i=0;i<3;i++)if(fabs(r-stops[i])<=0.04){r=stops[i];break;}
    }
    if(fabs(s->ratio-r)<0.000001)return DFSP_GESTURE_NONE;
    s->ratio=r;
    return DFSP_GESTURE_RATIO;
}
void DFSPGestureLogoDown(DFSPGestureState *s) {
    if (!s)return;
    s->logoPressed=1;s->logoHeld=0;s->logoMoved=0;
}
DFSPGestureEffect DFSPGestureLogoHoldDrag(DFSPGestureState *s,
                                          double heldSeconds,double along) {
    if(!s || !s->logoPressed || !isfinite(heldSeconds) || !isfinite(along))
        return DFSP_GESTURE_NONE;
    if(heldSeconds<0.30 && !s->logoHeld)return DFSP_GESTURE_NONE;
    s->logoHeld=1;
    double pos=clamp(along,0.1,0.9);
    if(fabs(s->logoFraction-pos)<0.000001)return DFSP_GESTURE_NONE;
    s->logoFraction=pos;
    s->logoMoved=1;
    return DFSP_GESTURE_LOGO_MOVE;
}
DFSPGestureEffect DFSPGestureLogoUp(DFSPGestureState *s) {
    if (!s || !s->logoPressed)return DFSP_GESTURE_NONE;
    int maySwap=!s->logoHeld && !s->logoMoved;
    s->logoPressed=0;
    s->logoHeld=0;
    s->logoMoved=0;
    return maySwap?DFSP_GESTURE_SWAP:DFSP_GESTURE_NONE;
}
void DFSPGestureCancel(DFSPGestureState *s) {
    if(!s)return;
    s->logoPressed=0;s->logoHeld=0;s->logoMoved=0;
}
