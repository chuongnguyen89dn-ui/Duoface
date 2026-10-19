#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/// Scoped runtime CarPlay admission for our independent shell only.
@interface MTCarPlayAdmission : NSObject
+ (void)installIfNeeded;
@end
NS_ASSUME_NONNULL_END
