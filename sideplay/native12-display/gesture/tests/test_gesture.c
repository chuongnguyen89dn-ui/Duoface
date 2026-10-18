#include "../DFSPNative12Gestures.h"
#include <assert.h>
#include <math.h>
#include <stdio.h>
static int near(double a,double b){return fabs(a-b)<0.00001;}
static void test_ratio_track(void){
    DFSPGestureState s;DFSPGestureReset(&s,0.5,0.5);
    assert(DFSPGestureRatioPan(&s,0.40,0)==DFSP_GESTURE_RATIO);
    assert(near(s.ratio,0.40)&&near(s.logoFraction,0.5));
    assert(DFSPGestureRatioPan(&s,0.99,0)==DFSP_GESTURE_RATIO);
    assert(near(s.ratio,2.0/3.0));
}
static void test_ratio_snap_only_at_end(void){
    DFSPGestureState s;DFSPGestureReset(&s,0.5,0.4);
    DFSPGestureRatioPan(&s,0.53,0);
    assert(near(s.ratio,0.53));
    assert(DFSPGestureRatioPan(&s,0.53,1)==DFSP_GESTURE_RATIO);
    assert(near(s.ratio,0.5));
}
static void test_logo_hold_moves_without_ratio(void){
    DFSPGestureState s;DFSPGestureReset(&s,0.42,0.5);
    DFSPGestureLogoDown(&s);
    assert(DFSPGestureLogoHoldDrag(&s,0.15,0.85)==DFSP_GESTURE_NONE);
    assert(near(s.logoFraction,0.5));
    assert(DFSPGestureLogoHoldDrag(&s,0.31,0.85)==DFSP_GESTURE_LOGO_MOVE);
    assert(near(s.logoFraction,0.85)&&near(s.ratio,0.42));
    assert(DFSPGestureRatioPan(&s,0.66,0)==DFSP_GESTURE_NONE);
    assert(DFSPGestureLogoUp(&s)==DFSP_GESTURE_NONE);
    assert(near(s.ratio,0.42));
}
static void test_logo_tap_swaps_once(void){
    DFSPGestureState s;DFSPGestureReset(&s,0.5,0.5);
    DFSPGestureLogoDown(&s);
    assert(DFSPGestureLogoUp(&s)==DFSP_GESTURE_SWAP);
    assert(DFSPGestureLogoUp(&s)==DFSP_GESTURE_NONE);
}
static void test_cancel_not_swap(void){
    DFSPGestureState s;DFSPGestureReset(&s,0.5,0.5);
    DFSPGestureLogoDown(&s);
    DFSPGestureCancel(&s);
    assert(DFSPGestureLogoUp(&s)==DFSP_GESTURE_NONE);
}
static void test_boundaries_and_invalid(void){
    DFSPGestureState s;DFSPGestureReset(&s,0.5,0.5);
    DFSPGestureLogoDown(&s);
    assert(DFSPGestureLogoHoldDrag(&s,0.31,5)==DFSP_GESTURE_LOGO_MOVE);
    assert(near(s.logoFraction,0.9));
    DFSPGestureLogoUp(&s);
    DFSPGestureLogoDown(&s);
    assert(DFSPGestureLogoHoldDrag(&s,0.31,-5)==DFSP_GESTURE_LOGO_MOVE);
    assert(near(s.logoFraction,0.1));
    assert(DFSPGestureLogoHoldDrag(&s,NAN,0.3)==DFSP_GESTURE_NONE);
    DFSPGestureLogoUp(&s);
    assert(DFSPGestureRatioPan(&s,NAN,1)==DFSP_GESTURE_NONE);
}
int main(void){
    test_ratio_track();
    test_ratio_snap_only_at_end();
    test_logo_hold_moves_without_ratio();
    test_logo_tap_swaps_once();
    test_cancel_not_swap();
    test_boundaries_and_invalid();
    puts("PASS: six independent Native12 gesture invariants");
}
