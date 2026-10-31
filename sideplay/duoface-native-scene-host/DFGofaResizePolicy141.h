#ifndef DF_GOFA_RESIZE_POLICY141_H
#define DF_GOFA_RESIZE_POLICY141_H
#include <stdbool.h>
#include <math.h>
static inline bool DFGofa141Same(double a,double b) {
 return isfinite(a) && isfinite(b) && fabs(a-b)<0.5;
}
// All dimensions are measured in the SAME accepted UIWindow coordinate space.
// Reject inset parents, inactive scenes, transforms, and Auto Layout-owned frames.
static inline bool DFGofa141MayResize(bool active,bool exactClass,bool sameWindow,
 bool identity,bool automatic,double targetW,double targetH,double windowW,double windowH,
 double parentW,double parentH,double parentX,double parentY,double viewX,double viewY) {
 return active && exactClass && sameWindow && identity && automatic &&
  targetW>=64 && targetH>=64 && targetW<=8192 && targetH<=8192 &&
  DFGofa141Same(targetW,windowW) && DFGofa141Same(targetH,windowH) &&
  DFGofa141Same(parentW,windowW) && DFGofa141Same(parentH,windowH) &&
  DFGofa141Same(parentX,0) && DFGofa141Same(parentY,0) &&
  DFGofa141Same(viewX,0) && DFGofa141Same(viewY,0);
}
#endif
