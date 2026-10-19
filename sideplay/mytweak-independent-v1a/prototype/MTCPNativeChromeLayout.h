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
FOUNDATION_EXPORT BOOL MTCPNativeContentIsWithinScreen(CGRect screen,CGRect usable);
NS_ASSUME_NONNULL_END
