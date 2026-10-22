#ifndef DF_NATIVE12_OUTER_GEOMETRY_H
#define DF_NATIVE12_OUTER_GEOMETRY_H
#include <math.h>
/* SHA-verified ORIGINAL Dashboard, CBMultitaskingOverlayView.layoutSubviews
 * @0xa28e8. Literal PCs: a2980(500), a2998(300), a29b4(680),
 * a29c4(380). Implement only the original numerical frame bounds;
 * the enclosing SpringBoard owner is independent and not parity-proven.
 * Evidence: audit/native12-continuation-4888299/outer-constants/.
 */
typedef struct { double width, height, x, y; } DFNative12OuterSheetRect;
static inline DFNative12OuterSheetRect DFNative12OuterGeometry(double width,double height) {
    if (!isfinite(width)||!isfinite(height)||width<=0||height<=0) {
        return (DFNative12OuterSheetRect){0,0,0,0};
    }
    double insetX=width<500.0?10.0:24.0;
    double insetY=height<300.0?8.0:18.0;
    double w=fmin(fmax(0.0,width-insetX),680.0);
    double h=fmin(fmax(0.0,height-insetY),380.0);
    double x=(double)roundf((float)((width-w)*0.5));
    double y=(double)roundf((float)((height-h)*0.5));
    return (DFNative12OuterSheetRect){w,h,x,y};
}
#endif
