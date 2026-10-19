// Experimental CoreAnimation remote display: no automatic hooks.
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT NSDictionary<NSString *,NSNumber *> *MTCPRemoteLayerCapabilities(void);
@interface MTCPRemoteLayerProducer : NSObject
@property(nonatomic,copy,readonly,nullable) NSString *session;
- (BOOL)publishLayer:(CALayer *)layer normalizedContentBounds:(CGRect)bounds;
- (void)invalidate;
@end
@interface MTCPRemoteLayerReceiver : UIView
@property(nonatomic,copy,readonly,nullable) NSString *session;
- (BOOL)connectWithOwnedContentView:(UIView *)owner;
- (void)disconnect;
@end
NS_ASSUME_NONNULL_END
