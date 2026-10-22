#ifndef DF_NATIVE12_GALLERY_GEOMETRY_H
#define DF_NATIVE12_GALLERY_GEOMETRY_H
#include <math.h>
// Original setupPresetCards... @0xa5e78; SHA-bound evidence in
// audit/native12-continuation-4888299/constants-v2/GALLERY_CONSTANTS.json.
// Pure geometry only, no app hosting or private framework side effects.
typedef struct {
    int columns;
    double cardWidth, cardHeight, rowStride, contentHeight, previewWidth;
} DFNative12GalleryMetrics;
static inline DFNative12GalleryMetrics DFNative12Gallery(double width) {
    int columns=width>=560.0?6:5;
    double cardWidth=(width-28.0-(columns-1)*10.0)/columns;
    DFNative12GalleryMetrics m={columns,cardWidth,66.0,78.0,194.0,
                                (double)roundf((float)(cardWidth-14.0))};
    return m;
}
#endif
