#include "DFNative104Geometry.h"
#include <math.h>
#include <stddef.h>

/* The frame rules are independently authored. No DuoNavi/SidePlay binary
   linked or copied. Render owner must separately preserve Dashboard chrome. */
static int rect_ok(DFNRect r) {
    return isfinite(r.x) && isfinite(r.y) && isfinite(r.width) &&
           isfinite(r.height) && r.width > 100.0 && r.height > 100.0;
}

int DFNUsableBounds(DFNRect display, DFNInsets insets, DFNRect *out) {
    if (out == NULL || !rect_ok(display)) return 0;
    if (!isfinite(insets.top) || !isfinite(insets.left) ||
        !isfinite(insets.bottom) || !isfinite(insets.right) ||
        insets.top < 0 || insets.left < 0 ||
        insets.bottom < 0 || insets.right < 0) return 0;
    DFNRect content = {
        display.x + insets.left,
        display.y + insets.top,
        display.width - (insets.left + insets.right),
        display.height - (insets.top + insets.bottom)
    };
    if (!rect_ok(content)) return 0;
    *out = content;
    return 1;
}

double DFNNormalizeRatio(double value, int endGesture) {
    if (!isfinite(value)) return NAN;
    value = fmax(DFN_RATIO_MIN, fmin(DFN_RATIO_MAX, value));
    if (!endGesture) return value;
    const double positions[] = { DFN_RATIO_MIN, DFN_RATIO_DEFAULT, DFN_RATIO_MAX };
    for (unsigned int i = 0; i < 3; ++i) {
        if (fabs(value - positions[i]) <= DFN_SNAP_THRESHOLD)
            return positions[i];
    }
    return value;
}

int DFNBuildLayout(DFNRect display, DFNInsets nativeInsets,
                   double requestedRatio, double dividerThickness,
                   DFNSplitAxis axis, int endGesture, DFNLayout *out) {
    if (out == NULL || !isfinite(dividerThickness) || dividerThickness < 0 ||
        !(axis == DFN_SPLIT_LEFT_RIGHT || axis == DFN_SPLIT_TOP_BOTTOM))
        return 0;
    DFNRect content;
    if (!DFNUsableBounds(display, nativeInsets, &content)) return 0;
    double ratio = DFNNormalizeRatio(requestedRatio, endGesture);
    if (!isfinite(ratio)) return 0;
    int horizontal = (axis == DFN_SPLIT_LEFT_RIGHT);
    double available = (horizontal ? content.width : content.height) - dividerThickness;
    if (available < 100.0) return 0;
    double firstExtent = available * ratio;
    double secondExtent = available - firstExtent;
    if (firstExtent <= 0.0 || secondExtent <= 0.0) return 0;
    DFNLayout result = {0};
    result.carplayScreen = display;
    result.content = content;
    result.contentScale = 1.0;
    result.splitRatio = ratio;
    if (horizontal) {
        result.first = (DFNRect){content.x, content.y, firstExtent, content.height};
        result.divider = (DFNRect){content.x + firstExtent, content.y,
                                   dividerThickness, content.height};
        result.second = (DFNRect){result.divider.x + dividerThickness, content.y,
                                  secondExtent, content.height};
    } else {
        result.first = (DFNRect){content.x, content.y, content.width, firstExtent};
        result.divider = (DFNRect){content.x, content.y + firstExtent,
                                   content.width, dividerThickness};
        result.second = (DFNRect){content.x, result.divider.y + dividerThickness,
                                  content.width, secondExtent};
    }
    *out = result;
    return 1;
}
