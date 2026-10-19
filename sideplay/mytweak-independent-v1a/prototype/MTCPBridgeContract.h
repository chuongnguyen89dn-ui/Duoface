// DuoFace-owned, experimental CarPlay presentation contract.
// Not included in the shipped SpringBoard tweak or Sileo package.
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT NSString *MTCPBridgeSurfaceFile(void);
FOUNDATION_EXPORT NSString *MTCPBridgeCommandFile(void);
FOUNDATION_EXPORT BOOL MTCPBridgeExplicitOptIn(void);
FOUNDATION_EXPORT BOOL MTCPBridgeValidateSurface(NSDictionary * _Nullable record,
    NSString * _Nullable expectedSession, NSTimeInterval now);
FOUNDATION_EXPORT BOOL MTCPBridgeValidateCommand(NSDictionary * _Nullable record,
    NSString *expectedSession, unsigned long long lastSequence, NSTimeInterval now);
FOUNDATION_EXPORT NSDictionary * _Nullable MTCPBridgeReadSurface(NSString * _Nullable session);
FOUNDATION_EXPORT NSDictionary * _Nullable MTCPBridgeReadCommand(NSString *session,
    unsigned long long lastSequence);
FOUNDATION_EXPORT BOOL MTCPBridgeWriteSurface(NSString *session, uint32_t contextID,
    CGRect normalizedBounds);
FOUNDATION_EXPORT BOOL MTCPBridgeWriteCommand(NSString *session, NSString *action,
    unsigned long long sequence, NSString * _Nullable phase, CGPoint normalizedPoint);
FOUNDATION_EXPORT void MTCPBridgeInvalidateSurface(NSString *session);
NS_ASSUME_NONNULL_END
