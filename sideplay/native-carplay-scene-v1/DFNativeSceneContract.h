// Independent DuoFace CarPlay native-scene telemetry contract (no vendor code).
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT NSString *const DFNativeSceneOwnerRecordPath;
FOUNDATION_EXPORT BOOL DFNativeSceneUsable(CGRect full, CGFloat top, CGFloat left,
    CGFloat bottom, CGFloat right, CGRect * _Nullable usable);
FOUNDATION_EXPORT BOOL DFNativeSceneSplit(CGRect usable, CGFloat ratio,
    CGFloat divider, CGRect * _Nullable first, CGRect * _Nullable second);
FOUNDATION_EXPORT NSDictionary * _Nullable DFNativeSceneOwnerRecord(NSString *session,
    CGRect full, CGRect usable, BOOL nativeChromeVisible, NSTimeInterval now);
FOUNDATION_EXPORT BOOL DFNativeSceneValidateOwnerRecord(NSDictionary * _Nullable record,
    NSString * _Nullable session, NSTimeInterval now);
NS_ASSUME_NONNULL_END
