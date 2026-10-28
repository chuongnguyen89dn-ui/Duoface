#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "../DFHostedMapRenderSize.h"
int main(void) {
 @autoreleasepool {
    CGSize pane=CGSizeMake(240,240);
    for(NSString *name in @[@"com.apple.Maps",@"com.google.Maps",@"com.waze.iphone",
                              @"vn.vietmap.live",@"com.google.ios.youtube",
                              @"com.apple.MobileSMS",@"com.duoface.native.scenehost"]) {
        NSCAssert(DFHostedViewportScaleForBundle(name)==0.50,
                  @"all main-display scenes must preserve .83 original scale");
        NSCAssert(CGSizeEqualToSize(DFHostedLogicalSizeForBundle(pane,name),
                      CGSizeMake(480,480)),@"map scaling is NOT native CarPlay map");
    }
    NSCAssert(DFIsMapNavigationBundle(@"com.apple.Maps"),@"only routing classification");
    NSCAssert(!DFIsMapNavigationBundle(@"com.google.ios.youtube"),@"no media classification");
    NSCAssert(CGSizeEqualToSize(DFHostedLogicalSizeForBundle(CGSizeZero,@"com.apple.Maps"),CGSizeZero),
              @"reject invalid viewport");
    NSCAssert(CGSizeEqualToSize(DFHostedLogicalSizeForBundle(CGSizeMake(NAN,100),@"com.apple.Maps"),CGSizeZero),
              @"reject nonfinite viewport");
    NSLog(@"PASS source correction: no map-only zoom guess, baseline scene geometry preserved");
 }
 return 0;
}
