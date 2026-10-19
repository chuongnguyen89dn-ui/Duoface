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
    NSLog(@"PASS %lu MTCP NativeChrome layout checks",(unsigned long)checks);
    return 0;
}}
