#ifndef DF_NATIVE12_MEDIA_GEOMETRY_H
#define DF_NATIVE12_MEDIA_GEOMETRY_H
#include <math.h>

/* Original SHA-pinned CBBridgedUIAppView updateLayout @0xacc6c:
 * render logical dimensions roundf(2*slot.width/height) @0xacc28;
 * ad03c..ad068: uniform minimum scale, threshold VM0x310c60=.05,
 * fallback .5, original CA layer corner policy ad0d0..ad124
 * width threshold VM0x311910=600. Not an orientation override. */
typedef struct {
    double nativeWidth,nativeHeight,scale,cornerRadius;
} DFOriginalMediaGeometry;
static inline DFOriginalMediaGeometry DFNative12MediaGeometry(double w,double h) {
    DFOriginalMediaGeometry out={0};
    if(!isfinite(w)||!isfinite(h)||w<=0||h<=0)return out;
    double nw=(double)roundf((float)(w*2.0));
    double nh=(double)roundf((float)(h*2.0));
    if(nw<=0||nh<=0)return out;
    double candidate=fmin(w/nw,h/nh);
    double scale=(candidate>0.05)?candidate:0.5;
    if(!isfinite(scale)||scale<=0)return out;
    out.nativeWidth=nw;out.nativeHeight=nh;out.scale=scale;
    out.cornerRadius=(w<600.0)?(10.0/scale):0.0;
    return out;
}
#endif
