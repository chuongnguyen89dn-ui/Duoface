#ifndef DF_NATIVE104_GEOMETRY_H
#define DF_NATIVE104_GEOMETRY_H

#ifdef __cplusplus
extern "C" {
#endif

/* Independent DuoFace geometry types. No SidePlay/CBWindow ABI or private hooks. */
typedef struct { double x, y, width, height; } DFNRect;
typedef struct { double top, left, bottom, right; } DFNInsets;

typedef enum {
    DFN_SPLIT_LEFT_RIGHT = 0,
    DFN_SPLIT_TOP_BOTTOM = 1,
} DFNSplitAxis;

typedef struct {
    DFNRect carplayScreen; /* Whole CarPlay display, including native dock. */
    DFNRect content;       /* Native usable area; NEVER SidePlay's screen frame. */
    DFNRect first;
    DFNRect divider;
    DFNRect second;
    double splitRatio;
    double contentScale;  /* Always 1.0 (100% of native usable area). */
} DFNLayout;

/* Original DuoNavi 1.0.4 values, SHA-pinned evidence in audit/native104-class-layout.json:
   -[CBBridgedSplitApp handleDividerPan:isVertical:state:]
   0x33c828: 1/3 ; 0x33c830: 2/3 ; 0x33e5b8: 0.04. */
#define DFN_RATIO_MIN (1.0 / 3.0)
#define DFN_RATIO_DEFAULT (0.5)
#define DFN_RATIO_MAX (2.0 / 3.0)
#define DFN_SNAP_THRESHOLD (0.04)

/* Resolve native CarPlay screen and real UIEdgeInsets. Reject unknown/invalid
   geometry instead of inventing a 64px dock or enlarging into fullscreen.
   Native1.0.4 carPlayUsableBounds has a 100-point validity threshold. */
int DFNUsableBounds(DFNRect display, DFNInsets nativeInsets, DFNRect *out);

/* Clamp the divider to native limits; snap on gesture end, not mid-drag.
   Invalid fractions are rejected by the layout builder. */
double DFNNormalizeRatio(double ratio, int endGesture);

/* Compute 100% native content-area split for a given divider visual width.
   Divider width must come from transplanted Native UI metrics, not SidePlay. */
int DFNBuildLayout(DFNRect display, DFNInsets nativeInsets,
                   double requestedRatio, double dividerThickness,
                   DFNSplitAxis axis, int endGesture, DFNLayout *out);

#ifdef __cplusplus
}
#endif
#endif
