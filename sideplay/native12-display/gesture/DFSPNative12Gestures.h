#ifndef DFSP_NATIVE12_GESTURES_H
#define DFSP_NATIVE12_GESTURES_H
/* Portable independent Native12 gesture policy. This module changes NO
 * SidePlay/DuoNavi window or scene. UIKit and host callbacks live elsewhere. */
typedef enum {
    DFSP_GESTURE_NONE=0,
    DFSP_GESTURE_RATIO=1,
    DFSP_GESTURE_LOGO_MOVE=2,
    DFSP_GESTURE_SWAP=3
} DFSPGestureEffect;
typedef enum {
    DFSP_DIVIDER_VERTICAL=0,  /* Track vertical, drag horizontally for ratio */
    DFSP_DIVIDER_HORIZONTAL=1 /* Track horizontal, drag vertically for ratio */
} DFSPDividerAxis;
typedef struct {
    double ratio;
    double logoFraction;
    int logoHeld;
    int logoMoved;
    int logoPressed;
} DFSPGestureState;
void DFSPGestureReset(DFSPGestureState *s, double ratio, double logoFraction);
/* Caller passes finger's perpendicular relative location 0..1.0.
 * Native12 clamp 1/3..2/3 and 4% snap only at gesture end. */
DFSPGestureEffect DFSPGestureRatioPan(DFSPGestureState *s,
                                      double across, int ended);
/* Press logo, then long-press after >=0.30 seconds; finger location along
 * divider does NOT update split ratio. */
void DFSPGestureLogoDown(DFSPGestureState *s);
DFSPGestureEffect DFSPGestureLogoHoldDrag(DFSPGestureState *s,
                           double heldSeconds, double along);
DFSPGestureEffect DFSPGestureLogoUp(DFSPGestureState *s);
/* Gesture cancellation must never become a swap. */
void DFSPGestureCancel(DFSPGestureState *s);
#endif
