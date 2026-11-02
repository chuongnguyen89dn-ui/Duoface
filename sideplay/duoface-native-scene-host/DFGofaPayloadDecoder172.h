//  DFGofaPayloadDecoder172.h
//  DuoFace — QA172 clean-room GOFA payload decoder: ObjC bridge.
//
//  The decoder core is Swift (DFGofaPayloadDecoder172.swift) because
//  the payload models are Swift objects and labelled-property
//  reflection (Mirror) is a Swift stdlib facility. This header is the
//  contract the Objective-C observer glue (DFGofaBoardSource172,
//  gate G3) codes against; the @objc implementation lives at the
//  bottom of the Swift file.
//
//  All returned dictionaries are normalised, validated subsets —
//  see FIELD_MAP.md (sideplay/audit/qa172-gofa-payload-decoder-20261102)
//  for the evidence behind every key name used here.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DFGofaDecoder172 : NSObject

/// Decode the speed board from a `notificationSpeedBoard` userInfo.
/// Returns nil when the `pushSpeedBoard` payload key is absent.
/// Otherwise returns a dictionary with the found subset of:
///   userSpeed, speed, currentAllowSpeed, limit   (NSNumber, km/h)
/// plus a `diagnostics` dictionary:
///   valueTypeName (NSString), valueKind (NSNumber, DF167 kind code),
///   fieldsPresent / fieldsRejected (NSNumber bitmasks:
///   bit0 userSpeed, bit1 speed, bit2 currentAllowSpeed, bit3 limit).
+ (nullable NSDictionary *)decodeSpeedBoardWithUserInfo:
    (NSDictionary<id, id> *)userInfo;

/// Decode alert points from a `notificationNextBoard` or
/// `notificationOtherBoard` userInfo. Always returns a wrapper:
///   { points: [ {identity?, sign?, latitude, longitude} ],
///     diagnostics: { valueTypeName, valueKind,
///                    pointsAccepted, pointsRejected } }
/// Coordinates are validated to [-90, 90] / [-180, 180]; at most 32
/// points are returned. Points/diagnostics never contain route data
/// beyond the normalised point fields themselves.
+ (NSDictionary *)decodeAlertPointsWithNotificationName:(NSString *)name
                                               userInfo:
    (NSDictionary<id, id> *)userInfo;

@end

NS_ASSUME_NONNULL_END
