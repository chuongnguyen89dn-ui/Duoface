// DuoFace independent source: baseline hosted iPhone app viewport only.
// IMPORTANT: Native OmniCar draws/hosts genuine CarPlay apps using its
// SCPCarSplit / SCPCarPane path; no arbitrary map-specific zoom recreates
// that CP scene. Keep .83/.84 2x geometry for ALL regular iPhone scenes
// until a separate owner-verified native CarPlay map compositor exists.
// The unapproved .85 0.80 map-only zoom is intentionally discontinued.
// The original .85 signed binary remains an immutable audit artifact;
// it must NOT be published as a correct native-map implementation.
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <math.h>
NS_INLINE BOOL DFIsMapNavigationBundle(NSString *bundleID) {
    return [bundleID isKindOfClass:NSString.class] &&
        [@[@"com.apple.Maps",@"com.google.Maps",@"com.waze.iphone",
           @"vn.vietmap.live"] containsObject:bundleID];
}
NS_INLINE CGFloat DFHostedViewportScaleForBundle(NSString *bundleID) {
    (void)bundleID;
    return (CGFloat)0.50; // immutable pre-.85 iPhone scene geometry
}
NS_INLINE CGSize DFHostedLogicalSizeForBundle(CGSize pane,NSString *bundleID) {
    (void)bundleID;
    if(!isfinite(pane.width)||!isfinite(pane.height)||
       pane.width<=0||pane.height<=0)return CGSizeZero;
    return CGSizeMake(round(pane.width*2.0),round(pane.height*2.0));
}
