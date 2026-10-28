// DuoFace first-party map-viewport policy. An experiment, not a claim of
// reproducing OmniCar's native CarPlay map compositor.
// Original OmniCar 1.0.3 ABHost.zoom: appBridgeZoom/100 clamped 0.60..1.00.
// DuoFace .84 hardcoded display scale 0.50 for every app (tiny map labels).
// Preserve all non-map app geometry by defaulting to exactly 0.50.
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <math.h>
NS_INLINE BOOL DFIsMapNavigationBundle(NSString *bundleID) {
    return [bundleID isKindOfClass:NSString.class] &&
        [@[@"com.apple.Maps",@"com.google.Maps",@"com.waze.iphone",
           @"vn.vietmap.live"] containsObject:bundleID];
}
NS_INLINE CGFloat DFHostedViewportScaleForBundle(NSString *bundleID) {
    // FIRST-PARTY provisional map UX choice (80%), within the VERIFIED
    // original OmniCar zoom range. Not asserted to equal its user setting.
    return DFIsMapNavigationBundle(bundleID)?0.80:0.50;
}
NS_INLINE CGSize DFHostedLogicalSizeForBundle(CGSize pane,NSString *bundleID) {
    CGFloat z=DFHostedViewportScaleForBundle(bundleID);
    if(!isfinite(pane.width)||!isfinite(pane.height)||
       pane.width<=0||pane.height<=0||!isfinite(z)||z<0.50||z>1.0)return CGSizeZero;
    return CGSizeMake(round(pane.width/z),round(pane.height/z));
}
