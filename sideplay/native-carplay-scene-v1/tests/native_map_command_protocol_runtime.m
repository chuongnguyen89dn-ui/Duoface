// Shipping Foundation ACK/poll policy: no UIKit, private API or device proof.
#import "../DFNativeMapCommandProtocol.h"
#include <stdio.h>
#include <stdlib.h>

static NSUInteger checks;
static void expect(BOOL condition,NSString *message) {
    checks++;
    if(!condition){NSLog(@"NATIVE_MAP_COMMAND_PROTOCOL_FAIL %@",message);abort();}
}
static NSString *const requestA=@"11111111-1111-4111-8111-111111111111";
static NSString *const requestB=@"22222222-2222-4222-8222-222222222222";
static NSDictionary *command(NSString *request,NSString *operation) {
    return @{@"Version":@(DFNativeMapCommandVersion),@"RequestID":request,
        @"Operation":operation,@"Timestamp":@1000.0};
}
static NSDictionary *ack(NSString *status,NSString *operation,BOOL attached) {
    return DFNativeMapMakeAck(command(requestA,operation),status,
        @"test-owner-result",@"CarPlayApp",attached,1001.0);
}
static DFNativeMapAckState DFTestReadAck(id value,NSString *operation) {
    return DFNativeMapAckReadState(value,requestA,operation,1000.0,1002.0);
}

static void testPendingAndTerminal(void) {
    NSDictionary *pending=ack(DFNativeMapStatusPending,@"Attach",NO);
    expect(pending!=nil && [pending[@"Applied"] isEqual:@NO],@"Pending is explicitly unapplied");
    expect(DFTestReadAck(pending,@"Attach")==DFNativeMapAckPending,@"Pending must keep waiting");
    expect(DFTestReadAck(ack(DFNativeMapStatusApplied,@"Attach",YES),@"Attach")==DFNativeMapAckApplied,
        @"verified attached pane is terminal success");
    expect(DFTestReadAck(ack(DFNativeMapStatusRejected,@"Attach",NO),@"Attach")==DFNativeMapAckRejected,
        @"server rejection is terminal failure");
    expect(DFTestReadAck(ack(DFNativeMapStatusCancelled,@"Attach",NO),@"Attach")==DFNativeMapAckCancelled,
        @"server cancellation is a distinct terminal result");
    expect(DFTestReadAck(ack(DFNativeMapStatusApplied,@"Restore",NO),@"Restore")==DFNativeMapAckApplied,
        @"Restore success requires detached pane, not attached pane");
    expect(ack(DFNativeMapStatusApplied,@"Attach",NO)==nil,
        @"writer cannot emit success for unattached Attach");
    expect(ack(DFNativeMapStatusApplied,@"Restore",YES)==nil,
        @"writer cannot emit successful Restore while still attached");
    NSMutableDictionary *falseAttach=[ack(DFNativeMapStatusApplied,@"Attach",YES) mutableCopy];
    falseAttach[@"PaneAttached"]=@NO;
    expect(DFTestReadAck(falseAttach,@"Attach")==DFNativeMapAckIgnore,@"reader rejects false Attach success");
    NSMutableDictionary *falseRestore=[ack(DFNativeMapStatusApplied,@"Restore",NO) mutableCopy];
    falseRestore[@"PaneAttached"]=@YES;
    expect(DFTestReadAck(falseRestore,@"Restore")==DFNativeMapAckIgnore,@"reader rejects false Restore success");

    // The actual producer and consumer agree after the same plist encoding
    // used by the retained ACK file, including true Boolean field types.
    NSData *bytes=[NSPropertyListSerialization dataWithPropertyList:pending
        format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
    id decoded=bytes?[NSPropertyListSerialization propertyListWithData:bytes
        options:NSPropertyListImmutable format:NULL error:NULL]:nil;
    expect(bytes!=nil && DFTestReadAck(decoded,@"Attach")==DFNativeMapAckPending,
        @"shipping Pending record survives plist round trip");
    NSDictionary *original=command(requestA,@"Attach");
    (void)DFNativeMapMakeAck(original,DFNativeMapStatusApplied,@"attached",@"CarPlay",YES,1005.0);
    expect([original[@"Timestamp"] isEqual:@1000.0],@"ACK producer never refreshes request timestamp");

    for(NSString *status in @[DFNativeMapStatusRejected,DFNativeMapStatusCancelled]) {
        NSMutableDictionary *contradictory=[ack(status,@"Attach",YES) mutableCopy];
        contradictory[@"Applied"]=@YES;
        expect(DFTestReadAck(contradictory,@"Attach")==DFNativeMapAckIgnore,
            @"terminal failure cannot also claim Applied");
    }
    NSMutableDictionary *contradictory=[pending mutableCopy];
    contradictory[@"Applied"]=@YES;contradictory[@"PaneAttached"]=@YES;
    expect(DFTestReadAck(contradictory,@"Attach")==DFNativeMapAckIgnore,@"Pending can never claim success");
    contradictory=[ack(DFNativeMapStatusApplied,@"Attach",YES) mutableCopy];
    contradictory[@"Applied"]=@NO;
    expect(DFTestReadAck(contradictory,@"Attach")==DFNativeMapAckIgnore,@"Applied status requires Applied Boolean");
}

static void testLegacyTerminalCompatibility(void) {
    NSMutableDictionary *legacy=[ack(DFNativeMapStatusApplied,@"Attach",YES) mutableCopy];
    legacy[@"Version"]=@1;[legacy removeObjectForKey:@"Status"];
    expect(DFTestReadAck(legacy,@"Attach")==DFNativeMapAckApplied,@"old synchronous v1 terminal success supported");
    legacy[@"Applied"]=@NO;
    expect(DFTestReadAck(legacy,@"Attach")==DFNativeMapAckRejected,@"v1 false maps only to terminal rejection");
    legacy[@"Status"]=DFNativeMapStatusPending;
    expect(DFTestReadAck(legacy,@"Attach")==DFNativeMapAckIgnore,@"hybrid v1/Pending cannot be mistaken for terminal");
    [legacy removeObjectForKey:@"Status"];legacy[@"Applied"]=@YES;legacy[@"PaneAttached"]=@NO;
    expect(DFTestReadAck(legacy,@"Attach")==DFNativeMapAckIgnore,@"v1 Attach needs the same attachment proof");
    legacy[@"Operation"]=@"Restore";
    expect(DFTestReadAck(legacy,@"Restore")==DFNativeMapAckApplied,@"v1 completed Restore remains supported");
    legacy[@"PaneAttached"]=@YES;
    expect(DFTestReadAck(legacy,@"Restore")==DFNativeMapAckIgnore,@"v1 cannot falsely claim restored while attached");
}

static void testMalformedAndUnrelated(void) {
    NSDictionary *valid=ack(DFNativeMapStatusApplied,@"Attach",YES);
    for(id invalid in @[@[],@1,@"ACK",NSNull.null])
        expect(DFTestReadAck(invalid,@"Attach")==DFNativeMapAckIgnore,@"non-dictionary ACK ignored safely");
    expect(DFTestReadAck(nil,@"Attach")==DFNativeMapAckIgnore,@"absent ACK means wait, not rejection/success");
    NSDictionary<NSString *,NSArray *> *invalidFields=@{
        @"Version":@[@0,@3,@2.5,@"2",@YES,NSNull.null],
        @"RequestID":@[requestB,@1,NSNull.null],
        @"Operation":@[@"Restore",@"Unknown",@1,NSNull.null],
        @"Status":@[@"Unknown",@"",@1,NSNull.null],
        @"Applied":@[@1,@0,@"YES",NSNull.null],
        @"PaneAttached":@[@1,@0,@"YES",NSNull.null],
        @"Reason":@[@"",@1,NSNull.null],
        @"OwnerProcess":@[@"SpringBoard",@"unknown",@1,NSNull.null],
        @"Timestamp":@[@YES,@"1001",@(NAN),@(INFINITY),@(-INFINITY),NSNull.null]
    };
    for(NSString *key in invalidFields) {
        for(id value in invalidFields[key]) {
            NSMutableDictionary *bad=[valid mutableCopy];bad[key]=value;
            expect(DFTestReadAck(bad,@"Attach")==DFNativeMapAckIgnore,
                [NSString stringWithFormat:@"ignore malformed %@=%@",key,value]);
        }
        NSMutableDictionary *missing=[valid mutableCopy];[missing removeObjectForKey:key];
        expect(DFTestReadAck(missing,@"Attach")==DFNativeMapAckIgnore,
            [NSString stringWithFormat:@"ignore missing %@",key]);
    }
    NSMutableDictionary *bad=[valid mutableCopy];
    bad[@"Reason"]=[@"a" stringByPaddingToLength:513 withString:@"a" startingAtIndex:0];
    expect(DFTestReadAck(bad,@"Attach")==DFNativeMapAckIgnore,@"bounded reason field");
    expect(DFNativeMapAckReadState(valid,requestB,@"Attach",1000,1002)==DFNativeMapAckIgnore,
        @"matching operation cannot override wrong request identity");
    expect(DFNativeMapAckReadState(valid,@"not-a-uuid",@"Attach",1000,1002)==DFNativeMapAckIgnore,
        @"invalid expected request identity fails closed");
    expect(DFNativeMapAckReadState(valid,requestA,@"Unknown",1000,1002)==DFNativeMapAckIgnore,
        @"unknown expected operation fails closed");
    expect(DFNativeMapMakeAck(command(requestA,@"Attach"),@"Unknown",@"reason",@"CarPlay",NO,1001)==nil,
        @"producer rejects unknown status");
    expect(DFNativeMapMakeAck(command(requestA,@"Attach"),DFNativeMapStatusPending,
        @"reason",@"SpringBoard",NO,1001)==nil,@"producer requires actual CarPlay owner name");
    NSMutableDictionary *wrong=[command(requestA,@"Attach") mutableCopy];wrong[@"Version"]=@2;
    expect(DFNativeMapMakeAck(wrong,DFNativeMapStatusPending,@"reason",@"CarPlay",NO,1001)==nil,
        @"producer retains command version1 contract");
}

static void testTimestampBinding(void) {
    NSMutableDictionary *value=[ack(DFNativeMapStatusApplied,@"Attach",YES) mutableCopy];
    for(NSNumber *stamp in @[@0,@(-1),@999.999,@1002.001]) {
        value[@"Timestamp"]=stamp;
        expect(DFTestReadAck(value,@"Attach")==DFNativeMapAckIgnore,@"pre-request/future ACK rejected");
    }
    value[@"Timestamp"]=@1001;
    expect(DFNativeMapAckReadState(value,requestA,@"Attach",1000,1009)==DFNativeMapAckApplied,
        @"ACK age boundary is explicit; client lifetime is separately monotonic");
    expect(DFNativeMapAckReadState(value,requestA,@"Attach",1000,1009.001)==DFNativeMapAckIgnore,
        @"stale ACK ignored");
    expect(DFNativeMapAckReadState(value,requestA,@"Attach",1000,999.9)==DFNativeMapAckIgnore,
        @"wall clock before request cannot validate an ACK");
    for(NSNumber *clock in @[@0,@(-1),@(NAN),@(INFINITY),@(-INFINITY)]) {
        expect(DFNativeMapAckReadState(value,requestA,@"Attach",clock.doubleValue,1002)==DFNativeMapAckIgnore,
            @"invalid original request timestamp rejected");
        expect(DFNativeMapAckReadState(value,requestA,@"Attach",1000,clock.doubleValue)==DFNativeMapAckIgnore,
            @"invalid wall receipt timestamp rejected");
    }
    expect(DFNativeMapMakeAck(command(requestA,@"Attach"),DFNativeMapStatusPending,
        @"reason",@"CarPlay",NO,999)==nil,@"writer cannot predate command");
}

static void testBoundedPollingAndLifecycle(void) {
    NSUInteger generation=DFNativeMapNextCommandGeneration(0);
    expect(DFNativeMapServerLaunchTimeout<DFNativeMapClientAckTimeout,@"client permits bounded server completion");
    expect(DFNativeMapClientAckPollInterval==0.25 && DFNativeMapClientAckMaximumPolls==32,
        @"explicit polling interval and independent hard bound");
    expect(DFNativeMapPollDecisionForRequest(requestA,requestA,generation,generation,YES,50,50.25,0)
        ==DFNativeMapPollContinue,@"current UI starts polling");
    expect(DFTestReadAck(ack(DFNativeMapStatusPending,@"Attach",NO),@"Attach")==DFNativeMapAckPending,
        @"first Pending observation supplies no terminal result");
    expect(DFNativeMapPollDecisionForRequest(requestA,requestA,generation,generation,YES,50,56,23)
        ==DFNativeMapPollContinue,@"same request can still observe six-second completion");
    expect(DFTestReadAck(ack(DFNativeMapStatusApplied,@"Attach",YES),@"Attach")==DFNativeMapAckApplied,
        @"later Applied for the same request terminates successfully");
    expect(DFNativeMapPollDecisionForRequest(requestA,requestA,generation,generation,YES,50,58,31)
        ==DFNativeMapPollTimedOut,@"eight-second monotonic deadline is terminal");
    expect(DFNativeMapPollDecisionForRequest(requestA,requestA,generation,generation,YES,50,50.5,32)
        ==DFNativeMapPollTimedOut,@"hard count bound stops polling even before clock deadline");
    expect(DFNativeMapPollDecisionForRequest(requestA,requestA,generation,generation,YES,50,49.9,1)
        ==DFNativeMapPollTimedOut,@"regressed monotonic clock fails boundedly");
    expect(DFNativeMapPollDecisionForRequest(requestA,requestA,generation,generation,YES,50,NAN,1)
        ==DFNativeMapPollTimedOut,@"invalid monotonic clock cannot poll forever");
    expect(DFNativeMapPollDecisionForRequest(requestA,requestB,generation,generation,YES,50,55,1)
        ==DFNativeMapPollStop,@"superseded request stops silently");
    expect(DFNativeMapPollDecisionForRequest(requestA,requestA,generation,generation+1,YES,50,55,1)
        ==DFNativeMapPollStop,@"stale generation stops even if request ID were reused");
    expect(DFNativeMapPollDecisionForRequest(requestA,requestB,generation,generation+1,YES,50,100,99)
        ==DFNativeMapPollStop,@"supersession takes precedence over old timeout dialog");
    expect(DFNativeMapPollDecisionForRequest(requestA,requestA,generation,generation,NO,50,100,99)
        ==DFNativeMapPollStop,@"departed UI never shows even an overdue timeout dialog");
    expect(DFNativeMapPollDecisionForRequest(requestA,nil,generation,generation,YES,50,55,1)
        ==DFNativeMapPollStop,@"completed/cancelled UI request stops retained callbacks");
    expect(DFNativeMapPollDecisionForRequest(requestA,requestA,0,0,YES,50,55,1)
        ==DFNativeMapPollStop,@"unset generation cannot acquire command ownership");
    __weak NSObject *weakController;
    @autoreleasepool {
        NSObject *controller=[NSObject new];weakController=controller;controller=nil;
    }
    expect(weakController==nil,@"queued UI uses weak controller lifetime");
    expect(DFNativeMapPollDecisionForRequest(requestA,requestA,generation,generation,
        weakController!=nil,50,55,1)==DFNativeMapPollStop,@"deallocated UI cannot present a final result");
    expect(DFNativeMapNextCommandGeneration(NSUIntegerMax)==1,@"generation never wraps to unset zero");
}

int main(void) {
    @autoreleasepool {
        testPendingAndTerminal();testLegacyTerminalCompatibility();
        testMalformedAndUnrelated();testTimestampBinding();testBoundedPollingAndLifecycle();
        printf("NATIVE_MAP_COMMAND_PROTOCOL_RUNTIME_PASS checks=%lu FOUNDATION_ONLY\n",(unsigned long)checks);
    }
    return 0;
}
