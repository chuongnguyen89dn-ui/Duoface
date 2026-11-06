// Shared Foundation-only native map command/ACK and client polling policy.
// ACK means a controller operation was verified, not map pixels or navigation.
#ifndef DF_NATIVE_MAP_COMMAND_PROTOCOL_H
#define DF_NATIVE_MAP_COMMAND_PROTOCOL_H
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#include <math.h>

static const NSInteger DFNativeMapCommandVersion=1;
static const NSInteger DFNativeMapAckVersion=2;
static const NSTimeInterval DFNativeMapServerLaunchTimeout=6.0;
static const NSTimeInterval DFNativeMapClientAckTimeout=8.0;
static const NSTimeInterval DFNativeMapClientAckPollInterval=0.25;
static const NSUInteger DFNativeMapClientAckMaximumPolls=32;

static NSString *const DFNativeMapStatusPending=@"Pending";
static NSString *const DFNativeMapStatusApplied=@"Applied";
static NSString *const DFNativeMapStatusRejected=@"Rejected";
static NSString *const DFNativeMapStatusCancelled=@"Cancelled";

typedef NS_ENUM(NSUInteger, DFNativeMapAckState) {
    DFNativeMapAckIgnore,
    DFNativeMapAckPending,
    DFNativeMapAckApplied,
    DFNativeMapAckRejected,
    DFNativeMapAckCancelled
};
typedef NS_ENUM(NSUInteger, DFNativeMapPollDecision) {
    DFNativeMapPollStop,
    DFNativeMapPollContinue,
    DFNativeMapPollTimedOut
};

NS_INLINE BOOL DFNativeMapProtocolNumber(id value) {
    return [value isKindOfClass:NSNumber.class] &&
        CFGetTypeID((__bridge CFTypeRef)value)!=CFBooleanGetTypeID() &&
        isfinite([value doubleValue]);
}
NS_INLINE BOOL DFNativeMapProtocolBool(id value) {
    return [value isKindOfClass:NSNumber.class] &&
        CFGetTypeID((__bridge CFTypeRef)value)==CFBooleanGetTypeID();
}
NS_INLINE BOOL DFNativeMapProtocolUUID(id value) {
    return [value isKindOfClass:NSString.class] &&
        [[NSUUID alloc]initWithUUIDString:value]!=nil;
}
NS_INLINE BOOL DFNativeMapProtocolOperation(id value) {
    return [value isKindOfClass:NSString.class] &&
        ([value isEqual:@"Attach"] || [value isEqual:@"Restore"]);
}
NS_INLINE BOOL DFNativeMapProtocolStatus(id value) {
    return [value isKindOfClass:NSString.class] &&
        [@[DFNativeMapStatusPending,DFNativeMapStatusApplied,
           DFNativeMapStatusRejected,DFNativeMapStatusCancelled] containsObject:value];
}
NS_INLINE BOOL DFNativeMapProtocolOwner(id value) {
    return [value isKindOfClass:NSString.class] &&
        ([value isEqual:@"CarPlay"] || [value isEqual:@"CarPlayApp"]);
}

NS_INLINE NSDictionary *DFNativeMapMakeAck(NSDictionary *command,
    NSString *status, NSString *reason, NSString *ownerProcess,
    BOOL paneAttached, NSTimeInterval now) {
    if(![command isKindOfClass:NSDictionary.class] ||
       !DFNativeMapProtocolNumber(command[@"Version"]) ||
       ![command[@"Version"] isEqual:@(DFNativeMapCommandVersion)] ||
       !DFNativeMapProtocolUUID(command[@"RequestID"]) ||
       !DFNativeMapProtocolOperation(command[@"Operation"]) ||
       !DFNativeMapProtocolNumber(command[@"Timestamp"]) ||
       [command[@"Timestamp"] doubleValue]<=0 ||
       !DFNativeMapProtocolStatus(status) ||
       ![reason isKindOfClass:NSString.class] || !reason.length || reason.length>512 ||
       !DFNativeMapProtocolOwner(ownerProcess) || !isfinite(now) ||
       now<[command[@"Timestamp"] doubleValue])return nil;
    BOOL applied=[status isEqual:DFNativeMapStatusApplied];
    if(applied && [command[@"Operation"] isEqual:@"Attach"]!=paneAttached)return nil;
    return @{@"Version":@(DFNativeMapAckVersion),@"Status":status,
        @"RequestID":command[@"RequestID"],@"Applied":@(applied),
        @"Operation":command[@"Operation"],@"Reason":reason,@"Timestamp":@(now),
        @"OwnerProcess":ownerProcess,@"PaneAttached":@(paneAttached)};
}

NS_INLINE DFNativeMapAckState DFNativeMapAckReadState(id ack,
    NSString *request, NSString *operation, NSTimeInterval requestedAt,
    NSTimeInterval now) {
    if(![ack isKindOfClass:NSDictionary.class] ||
       !DFNativeMapProtocolUUID(request) || !DFNativeMapProtocolOperation(operation) ||
       !DFNativeMapProtocolNumber(ack[@"Version"]) ||
       (![ack[@"Version"] isEqual:@1] &&
        ![ack[@"Version"] isEqual:@(DFNativeMapAckVersion)]) ||
       ![ack[@"RequestID"] isKindOfClass:NSString.class] ||
       ![ack[@"RequestID"] isEqual:request] ||
       ![ack[@"Operation"] isEqual:operation] ||
       !DFNativeMapProtocolBool(ack[@"Applied"]) ||
       !DFNativeMapProtocolBool(ack[@"PaneAttached"]) ||
       ![ack[@"Reason"] isKindOfClass:NSString.class] ||
       ![ack[@"Reason"] length] || [ack[@"Reason"] length]>512 ||
       !DFNativeMapProtocolOwner(ack[@"OwnerProcess"]) ||
       !DFNativeMapProtocolNumber(ack[@"Timestamp"]) ||
       !isfinite(requestedAt) || requestedAt<=0 || !isfinite(now) || now<requestedAt)
        return DFNativeMapAckIgnore;
    NSTimeInterval stamp=[ack[@"Timestamp"] doubleValue];
    if(stamp<requestedAt || stamp>now || now-stamp>DFNativeMapClientAckTimeout)
        return DFNativeMapAckIgnore;
    BOOL applied=[ack[@"Applied"] boolValue];
    if(applied && [operation isEqual:@"Attach"]!=[ack[@"PaneAttached"] boolValue])
        return DFNativeMapAckIgnore;

    // Version 1 was wholly synchronous and has no Pending state. Preserve
    // terminal compatibility only with all of the same identity/time/type
    // checks. A hybrid v1/Status record is ambiguous and must be ignored.
    if([ack[@"Version"] isEqual:@1]) {
        if(ack[@"Status"])return DFNativeMapAckIgnore;
        return applied?DFNativeMapAckApplied:DFNativeMapAckRejected;
    }
    NSString *status=ack[@"Status"];
    if(!DFNativeMapProtocolStatus(status) ||
       applied!=[status isEqual:DFNativeMapStatusApplied])return DFNativeMapAckIgnore;
    if([status isEqual:DFNativeMapStatusPending])return DFNativeMapAckPending;
    if([status isEqual:DFNativeMapStatusApplied])return DFNativeMapAckApplied;
    if([status isEqual:DFNativeMapStatusCancelled])return DFNativeMapAckCancelled;
    return DFNativeMapAckRejected;
}

NS_INLINE NSUInteger DFNativeMapNextCommandGeneration(NSUInteger current) {
    return current==NSUIntegerMax?1:current+1;
}
NS_INLINE DFNativeMapPollDecision DFNativeMapPollDecisionForRequest(
    NSString *request, NSString *activeRequest, NSUInteger capturedGeneration,
    NSUInteger currentGeneration, BOOL controllerActive,
    NSTimeInterval startedMonotonic, NSTimeInterval nowMonotonic,
    NSUInteger completedPolls) {
    // Superseded/inactive UI is silent even if its old deadline has passed.
    if(!controllerActive || !DFNativeMapProtocolUUID(request) ||
       ![activeRequest isKindOfClass:NSString.class] || ![request isEqual:activeRequest] ||
       !capturedGeneration || capturedGeneration!=currentGeneration)return DFNativeMapPollStop;
    if(!isfinite(startedMonotonic) || startedMonotonic<0 || !isfinite(nowMonotonic) ||
       nowMonotonic<startedMonotonic || nowMonotonic-startedMonotonic>=DFNativeMapClientAckTimeout ||
       completedPolls>=DFNativeMapClientAckMaximumPolls)return DFNativeMapPollTimedOut;
    return DFNativeMapPollContinue;
}
#endif
