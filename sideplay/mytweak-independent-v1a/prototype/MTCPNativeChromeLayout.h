// CarPlay native sidebar geometry; pure CoreGraphics, no UI mutation.
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, MTCPDockEdge) {
    MTCPDockEdgeNone=0,
    MTCPDockEdgeLeft=1,MTCPDockEdgeRight=2,
    MTCPDockEdgeTop=3,MTCPDockEdgeBottom=4
};
FOUNDATION_EXPORT BOOL MTCPNativeUsableBounds(CGRect screen, CGRect systemBar,
                                              CGRect * _Nullable usable,
                                              MTCPDockEdge * _Nullable edge);
// Native12 CBWindow.carPlayUsableBounds equivalent, using measured dynamic
// CarPlay content insets (never a fixed 45/64pt or a ratio).
FOUNDATION_EXPORT BOOL MTCPNativeUsableFromInsets(CGRect screen,
    CGFloat top,CGFloat left,CGFloat bottom,CGFloat right,
    CGRect * _Nullable usable);
FOUNDATION_EXPORT BOOL MTCPNativeContentIsWithinScreen(CGRect screen,CGRect usable);
NS_ASSUME_NONNULL_END
