// native21: remove the failed CarPlay "Add App" tile, not the iPhone picker.
// No app-list writes, no alert, no bridge/geometry/zoom modifications.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface CBMultitaskingOverlayView : UIView
- (void)addMoreAppsTapped:(id)sender;
- (void)setupAppPickerCardsInCardW:(CGFloat)w cardH:(CGFloat)h contentY:(CGFloat)y;
@end

static BOOL DFIsDeprecatedAddControl(UIControl *control) {
    if (![control isKindOfClass:UIControl.class]) return NO;
    // Match the registered action, never a localized label or generic "+".
    for (id target in control.allTargets) {
        NSArray<NSString *> *actions =
            [control actionsForTarget:target forControlEvent:UIControlEventTouchUpInside];
        if ([actions containsObject:@"addMoreAppsTapped:"]) return YES;
    }
    return NO;
}
static NSUInteger DFRemoveAddControls(UIView *view, NSUInteger depth) {
    if (!view || depth>20) return 0;
    NSUInteger count=0;
    // Take a snapshot because removeFromSuperview mutates subviews.
    for (UIView *child in [view.subviews copy]) {
        if ([child isKindOfClass:UIControl.class] &&
            DFIsDeprecatedAddControl((UIControl *)child)) {
            child.hidden=YES;
            [child removeFromSuperview];
            count++;
            continue;
        }
        count+=DFRemoveAddControls(child,depth+1);
    }
    return count;
}
static void DFHideLegacyAddButton(UIView *overlay) {
    if (![NSThread isMainThread]) return;
    NSUInteger removed=DFRemoveAddControls(overlay,0);
    if (removed) NSLog(@"[DuoFace] removed obsolete Add App tile (count=%lu)",
                       (unsigned long)removed);
}
%group DFRemoveOldAddAppTile
%hook CBMultitaskingOverlayView
- (void)setupAppPickerCardsInCardW:(CGFloat)w cardH:(CGFloat)h contentY:(CGFloat)y {
    %orig;
    DFHideLegacyAddButton(self);
}
- (void)layoutSubviews {
    %orig;
    DFHideLegacyAddButton(self);
}
- (void)addMoreAppsTapped:(id)sender {
    // A stale retained button/gesture must NEVER recreate the old dialog.
    (void)sender;
    NSLog(@"[DuoFace] ignored obsolete Add App action");
}
%end
%end

static BOOL DFRemoveTileHooked=NO;
static BOOL DFAllowedCarPlayHost(void) {
    NSString *bundle=NSBundle.mainBundle.bundleIdentifier.lowercaseString;
    NSString *process=NSProcessInfo.processInfo.processName.lowercaseString;
    return [@[@"com.apple.springboard",@"com.apple.carplay",
              @"com.apple.carplayapp",@"com.apple.dashboard"] containsObject:bundle] ||
           [@[@"springboard",@"carplay",@"carplayapp",@"dashboard"] containsObject:process];
}
static void DFInstallOldAddTileRemoval(void) {
    if (DFRemoveTileHooked || !DFAllowedCarPlayHost()) return;
    if (NSClassFromString(@"CBMultitaskingOverlayView")==Nil) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,5*NSEC_PER_SEC),
                       dispatch_get_main_queue(),^{DFInstallOldAddTileRemoval();});
        return;
    }
    %init(DFRemoveOldAddAppTile);
    DFRemoveTileHooked=YES;
    NSLog(@"[DuoFace] obsolete Add App removal hook installed");
}
__attribute__((constructor)) static void DFStartRemoveOldAddTile(void) {
    @autoreleasepool {
        if (!DFAllowedCarPlayHost()) return;
        dispatch_async(dispatch_get_main_queue(), ^{DFInstallOldAddTileRemoval();});
    }
}
