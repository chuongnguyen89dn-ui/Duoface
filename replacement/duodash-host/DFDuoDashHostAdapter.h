// DuoFace standalone replacement: optional interoperability with an installed DuoDash runtime.
// No DuoNavi classes. No vendor binary is copied or redistributed.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const DFDDHostErrorDomain;

// Runtime adapter: returns an unattached scene controller supplied by DuoDash.
// This source does not install DuoDash, present a window, or replace the DuoFace UI.
@interface DFDuoDashHostAdapter : NSObject
+ (BOOL)isAvailableWithError:(NSError * _Nullable * _Nullable)error;
+ (nullable UIViewController *)createUnattachedSceneForBundleID:(NSString *)bundleID
                                                     renderSize:(CGSize)size
                                                          error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
