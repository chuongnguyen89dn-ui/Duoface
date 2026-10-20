#import <Foundation/Foundation.h>
#import "../MTCPNativeChromeLayout.h"
#import <math.h>
static NSUInteger checks=0;
static void T(BOOL value,NSString *name) {
    checks++;
    if(!value){NSLog(@"FAIL %@ (#%lu)",name,(unsigned long)checks);exit(2);}
}
int main(void) { @autoreleasepool {
    CGRect screen=CGRectMake(0,0,507.333333333,240);
    CGRect content=CGRectZero;
    MTCPDockEdge edge=MTCPDockEdgeNone;
    T(!MTCPNativeUsableBounds(screen,CGRectMake(-45,0,45,240),&content,&edge),@"iPhone X actual offscreen statusbar rejected");
    T(CGRectIsNull(content),@"offscreen never yields content");
    T(edge==MTCPDockEdgeNone,@"offscreen no edge assigned");
    T(MTCPNativeUsableBounds(screen,CGRectMake(0,0,45,240),&content,&edge),@"visible left real native bar");
    T(edge==MTCPDockEdgeLeft,@"left edge");
    T(fabs(content.origin.x-45)<0.001,@"real observed width not magic 64");
    T(fabs(content.size.width-462.3333333)<0.001,@"native content dimensions");
    T(MTCPNativeUsableBounds(screen,CGRectMake(462.3333333,0,45,240),&content,&edge),@"right");
    T(edge==MTCPDockEdgeRight,@"right edge recognized");
    T(MTCPNativeUsableBounds(screen,CGRectMake(0,0,507.3333333,40),&content,&edge),@"top");
    T(edge==MTCPDockEdgeTop,@"top edge recognized");
    T(MTCPNativeUsableBounds(screen,CGRectMake(0,200,507.3333333,40),&content,&edge),@"bottom");
    T(edge==MTCPDockEdgeBottom,@"bottom edge recognized");
    T(!MTCPNativeUsableBounds(screen,CGRectMake(45,0,462.3333333,240),&content,&edge),@"notification content window is not dock");
    T(!MTCPNativeUsableBounds(screen,CGRectMake(0,0,507.3333333,240),&content,&edge),@"fullscreen window not dock");
    T(!MTCPNativeUsableBounds(screen,CGRectMake(0,0,5,240),&content,&edge),@"tiny transient not dock");
    T(!MTCPNativeUsableBounds(screen,CGRectMake(NAN,0,45,240),&content,&edge),@"nan rejected");
    T(!MTCPNativeUsableBounds(screen,CGRectMake(0,0,INFINITY,240),&content,&edge),@"infinite rejected");
    T(!MTCPNativeUsableBounds(CGRectZero,CGRectMake(0,0,45,240),&content,&edge),@"empty screen rejected");
    T(MTCPNativeContentIsWithinScreen(screen,CGRectMake(45,0,462.3333333,240)),@"content contained");
    T(!MTCPNativeContentIsWithinScreen(screen,CGRectMake(-1,0,463.3333333,240)),@"out of screen not allowed");
    T(!MTCPNativeContentIsWithinScreen(screen,CGRectMake(0,0,120,40)),@"small content not allowed");
    // Real iPhone X 507.333 x 240 measurement, visible 45pt left bar:
    // Normal=462.333 wide; fullscreen=507.333 wide. No ratio guess.
    CGRect normal=CGRectNull,full=CGRectNull;
    T(MTCPNativeUsableFromInsets(screen,0,45,0,0,&normal),@"Native12 dynamic left inset");
    T(fabs(normal.origin.x-45)<0.001,@"normal shifts content only");
    T(fabs(normal.size.width-462.3333333)<0.001,@"normal preserves right side");
    T(MTCPNativeUsableFromInsets(screen,0,0,0,0,&full),@"fullscreen zero insets");
    T(CGRectEqualToRect(full,screen),@"fullscreen covers root display");
    T(!CGRectEqualToRect(normal,full),@"separate geometries");
    T(MTCPNativeUsableFromInsets(screen,0,0,0,0,&full),@"can re-enter full without cumulative shrink");
    T(MTCPNativeUsableFromInsets(screen,0,45,0,0,&normal),@"can restore saved inset");
    T(!MTCPNativeUsableFromInsets(screen,0,507,0,0,&normal),@"invalid narrow content rejected");
    T(!MTCPNativeUsableFromInsets(screen,0,-1,0,0,&normal),@"negative inset rejected");
    T(!MTCPNativeUsableFromInsets(screen,0,NAN,0,0,&normal),@"nonfinite inset rejected");
    T(MTCPNativeUsableFromInsets(screen,12,30,12,30,&normal),@"dynamic multiple-edge insets");
    T(fabs(normal.size.height-216)<0.001,@"vertical insets applied");
    NSLog(@"PASS %lu MTCP NativeChrome layout checks",(unsigned long)checks);
    return 0;
}}
