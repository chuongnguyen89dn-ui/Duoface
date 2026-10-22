#import <UIKit/UIKit.h>
// First-party split geometry. Frame calculation does not create or simulate app
// scenes; each occupied frame must be attached to a real DFSceneHost UIView.
// Presets are an independent implementation pending Native12 device parity.
NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT NSInteger DFSlotCountForPreset(NSInteger preset);
FOUNDATION_EXPORT BOOL DFPrimaryDividerIsVertical(NSInteger preset);
FOUNDATION_EXPORT BOOL DFSecondaryDividerIsVertical(NSInteger preset);
FOUNDATION_EXPORT CGRect DFSecondaryDividerRect(CGRect usableBounds, NSInteger preset, CGFloat ratio, CGFloat secondary);
FOUNDATION_EXPORT void DFComputePresetFramesWithSecondary(CGRect usableBounds, NSInteger preset, CGFloat ratio, CGFloat secondary, CGRect * _Nonnull outFrames);
// Returns the actual boundary separating the ratio-controlled groups, not
// necessarily the end of slot zero (four-strip preset has two left slots).
FOUNDATION_EXPORT CGFloat DFPrimaryDividerCoordinate(CGRect usableBounds, NSInteger preset, CGFloat ratio);
FOUNDATION_EXPORT void DFComputePresetFrames(CGRect usableBounds, NSInteger preset,
                                              CGFloat ratio, CGRect * _Nonnull outFrames);
NS_ASSUME_NONNULL_END
