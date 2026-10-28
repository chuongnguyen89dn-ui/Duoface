#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "../DFHostedMapRenderSize.h"
int main(void) {
 @autoreleasepool {
    CGSize pane=CGSizeMake(240,240);
    for(NSString *name in @[@"com.apple.Maps",@"com.google.Maps",@"com.waze.iphone",@"vn.vietmap.live"]) {
        NSCAssert(DFIsMapNavigationBundle(name),@"exact allowlisted navigation bundle");
        NSCAssert(DFHostedViewportScaleForBundle(name)==0.80,@"map zoom 80 percent");
        CGSize size=DFHostedLogicalSizeForBundle(pane,name);
        NSCAssert(CGSizeEqualToSize(size,CGSizeMake(300,300)),@"map visual labels 1.6x size vs former 50 percent");
    }
    for(NSString *name in @[@"com.google.ios.youtube",@"com.apple.MobileSMS",@"com.duoface.native.scenehost"]) {
        NSCAssert(!DFIsMapNavigationBundle(name),@"no foreign scale change");
        NSCAssert(DFHostedViewportScaleForBundle(name)==0.50,@"original .83/.84 media size unchanged");
        NSCAssert(CGSizeEqualToSize(DFHostedLogicalSizeForBundle(pane,name),
                      CGSizeMake(480,480)),@"nonmap scene geometry unchanged");
    }
    NSCAssert(CGSizeEqualToSize(DFHostedLogicalSizeForBundle(CGSizeZero,@"com.apple.Maps"),CGSizeZero),
              @"reject invalid viewport");
    NSCAssert(CGSizeEqualToSize(DFHostedLogicalSizeForBundle(CGSizeMake(NAN,100),@"com.apple.Maps"),CGSizeZero),
              @"reject nonfinite viewport");
    NSLog(@"PASS .85 map profile: four explicit apps, non-map preserved, exact geometry");
 }
 return 0;
}
