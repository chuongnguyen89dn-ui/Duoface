// Executes the shipping Foundation-only app activity and lifecycle policy.
// This proves record/session admission, not UIKit routing or CarPlay behavior.
#import "../DFAppTouchPolicy177.h"
#include <stdio.h>
#include <stdlib.h>

static NSUInteger checks;
static void expect(BOOL condition, NSString *message) {
    checks++;
    if(!condition){
        NSLog(@"DF177_APP_TOUCH_FAIL %@",message);
        abort();
    }
}

static NSMutableDictionary *record(NSString *bundle, NSNumber *pid,
                                    NSNumber *count, NSTimeInterval stamp) {
    return [@{@"version":@2,@"bundle":bundle,@"pid":pid,
              @"count":count,@"ts":@(stamp)} mutableCopy];
}

static void testOwnedActivity(void) {
    NSString *a=@"test.duoface.touch.alpha",*b=@"test.duoface.touch.beta";
    NSDictionary *owners=@{a:@1234,b:@5678};
    NSTimeInterval start=9990.0,now=10000.0;
    NSDictionary *valid=record(a,@1234,@1,now);
    expect(DF177AppTouchRecordMatches(valid,owners,start,now),
           @"current owned process may report fresh activity");
    expect(DF177AppTouchRecordMatches(record(b,@5678,@1,now),owners,start,now),
           @"another currently hosted process is independently admitted");
    expect(!DF177AppTouchRecordMatches(record(b,@5678,@1,now),@{a:@1234},start,now),
           @"supported but unhosted phone app cannot drive controls");
    expect(!DF177AppTouchRecordMatches(valid,@{},start,now),
           @"no live hosted owners means no accepted activity");
    expect(!DF177AppTouchRecordMatches(valid,@{a:@1235},start,now),
           @"old PID is rejected after same-bundle process restart");
    expect(!DF177AppTouchRecordMatches(record(b,@1234,@1,now),owners,start,now),
           @"another bundle cannot borrow a hosted process identity");
    expect(!DF177AppTouchRecordMatches(valid,nil,start,now),
           @"missing ownership evidence fails closed");
    expect(!DF177AppTouchRecordMatches(valid,(id)@[],start,now),
           @"malformed owner collection fails closed");
    for(id pid in @[@0,@1,@(-2),@1234.5,@"1234",@YES,NSNull.null,@(NAN)])
        expect(!DF177AppTouchRecordMatches(valid,@{a:pid},start,now),
               @"unverified or malformed owner PID fails closed");

    // Use the real JSON representation used by the v2 sender/receiver.
    NSData *encoded=[NSJSONSerialization dataWithJSONObject:valid options:0 error:NULL];
    id decoded=encoded?[NSJSONSerialization JSONObjectWithData:encoded options:0 error:NULL]:nil;
    expect(encoded!=nil && DF177AppTouchRecordMatches(decoded,owners,start,now),
           @"valid shipping v2 JSON survives round trip");

    NSMutableDictionary *legacy=[valid mutableCopy];
    legacy[@"version"]=@1;
    expect(!DF177AppTouchRecordMatches(legacy,owners,start,now),
           @"v1 is rejected even if a PID field was added");
    [legacy removeObjectForKey:@"pid"];
    expect(!DF177AppTouchRecordMatches(legacy,owners,start,now),
           @"old loaded v1 relay remains unverified until app relaunch");
}

static void testSchema(void) {
    NSString *bundle=@"test.duoface.touch.alpha";
    NSDictionary *owners=@{bundle:@1234};
    NSTimeInterval now=10000.0,start=9990.0;
    NSDictionary *valid=record(bundle,@1234,@1,now);
    for(id invalid in @[@[],@1234,@"record",NSNull.null])
        expect(!DF177AppTouchRecordMatches(invalid,owners,start,now),
               @"non-dictionary payload is rejected without messaging its fields");
    expect(!DF177AppTouchRecordMatches(nil,owners,start,now),@"missing payload rejected");

    NSDictionary<NSString *,NSArray *> *invalidFields=@{
        @"version":@[@1,@3,@2.5,@"2",@YES,@(NAN),NSNull.null],
        @"bundle":@[@"",@"test.duoface.touch.unhosted",@23,@[],NSNull.null],
        @"pid":@[@0,@1,@(-1),@1235,@1234.5,@"1234",@YES,
                  @((double)INT_MAX+1.0),@(NAN),@(INFINITY),NSNull.null],
        @"count":@[@0,@(-1),@1.5,@"1",@YES,@(NAN),@(INFINITY),
                    @((double)DF177AppTouchMaximumCount+1.0),@(UINT64_MAX),NSNull.null],
        @"ts":@[@0,@(-1),@"10000",@YES,@(NAN),@(INFINITY),@(-INFINITY),NSNull.null]
    };
    for(NSString *key in invalidFields){
        for(id value in invalidFields[key]){
            NSMutableDictionary *bad=[valid mutableCopy];
            bad[key]=value;
            expect(!DF177AppTouchRecordMatches(bad,owners,start,now),
                   [NSString stringWithFormat:@"reject malformed %@=%@",key,value]);
        }
        NSMutableDictionary *missing=[valid mutableCopy];
        [missing removeObjectForKey:key];
        expect(!DF177AppTouchRecordMatches(missing,owners,start,now),
               [NSString stringWithFormat:@"reject missing %@",key]);
    }
    expect(DF177AppTouchRecordMatches(record(bundle,@1234,
        @(DF177AppTouchMaximumCount),now),owners,start,now),
        @"largest exactly represented allowed count is admitted");
    NSString *longBundle=[@"a" stringByPaddingToLength:129 withString:@"a" startingAtIndex:0];
    expect(!DF177AppTouchRecordMatches(record(longBundle,@1234,@1,now),
        @{longBundle:@1234},start,now),@"oversized bundle rejected even with an owner");
}

static void testEventFreshness(void) {
    NSString *bundle=@"test.duoface.touch.alpha";
    NSDictionary *owners=@{bundle:@1234};
    NSTimeInterval now=10000.0,start=9990.0;
    expect(DF177AppTouchRecordMatches(record(bundle,@1234,@1,now-2.0),owners,start,now),
           @"two-second delivery boundary is accepted");
    expect(!DF177AppTouchRecordMatches(record(bundle,@1234,@1,now-2.001),owners,start,now),
           @"stale retained touch cannot extend controls");
    expect(!DF177AppTouchRecordMatches(record(bundle,@1234,@1,now+0.001),owners,start,now),
           @"future activity is rejected on the shared device clock");
    expect(!DF177AppTouchRecordMatches(record(bundle,@1234,@1,now-1.0),
        owners,now-0.5,now),@"fresh pre-session activity cannot enter a new session");
    expect(DF177AppTouchRecordMatches(record(bundle,@1234,@1,now-0.5),
        owners,now-0.5,now),@"activity at the current session boundary is accepted");
    expect(!DF177AppTouchRecordMatches(record(bundle,@1234,@1,now),owners,now+1,now),
           @"clock preceding session start fails closed");
    for(NSNumber *invalid in @[@0,@(-1),@(NAN),@(INFINITY),@(-INFINITY)]){
        expect(!DF177AppTouchRecordMatches(record(bundle,@1234,@1,now),
            owners,invalid.doubleValue,now),@"invalid session time rejected");
        expect(!DF177AppTouchRecordMatches(record(bundle,@1234,@1,now),
            owners,start,invalid.doubleValue),@"invalid receipt time rejected");
    }
}

static void testSessionAndCallbackOwnership(void) {
    NSObject *first=[NSObject new],*replacement=[NSObject new];
    DF177AppTouchSession session={0};
    expect(!DF177AppTouchSessionMatches(session,0,first,first),
           @"unstarted owner cannot receive activity");
    session=DF177AppTouchBeginSession(session,10000.0);
    NSUInteger original=session.generation;
    expect(session.active && session.startedAt==10000.0 && original!=0,
           @"start creates an active, time-bounded nonzero generation");
    expect(DF177AppTouchSessionMatches(session,original,first,first),
           @"current owner and session can receive their queued wake");
    expect(!DF177AppTouchSessionMatches(session,original,nil,nil),
           @"deallocated owner cannot receive a callback");
    expect(!DF177AppTouchSessionMatches(session,original,first,nil),
           @"cleared current owner invalidates callbacks");
    expect(!DF177AppTouchSessionMatches(session,original,first,replacement),
           @"retained old instance cannot act after owner replacement");
    expect(DF177AppTouchRecheckAllowed(session,original,first,first,7,7),
           @"latest current-session recheck is admitted");
    expect(!DF177AppTouchRecheckAllowed(session,original,first,first,6,7),
           @"new activity coalesces away an earlier recheck");
    expect(!DF177AppTouchRecheckAllowed(session,original,first,first,0,0),
           @"unset recheck cannot run");

    session=DF177AppTouchEndSession(session);
    expect(!session.active && session.startedAt==0 && session.generation!=original,
           @"stop revokes active state, time boundary and old generation");
    expect(!DF177AppTouchSessionMatches(session,original,first,first),
           @"already queued notification cannot run after stop");
    expect(!DF177AppTouchRecheckAllowed(session,original,first,first,7,7),
           @"old deferred layout is denied while stopped even with matching recheck");
    session=DF177AppTouchBeginSession(session,10001.0);
    expect(!DF177AppTouchSessionMatches(session,original,first,first),
           @"reused Chrome rejects the previous session's queued notification");
    expect(!DF177AppTouchRecheckAllowed(session,original,first,first,7,7),
           @"stop/start cannot revive old deferred layout before any new app touch");
    expect(DF177AppTouchRecheckAllowed(session,session.generation,first,first,8,8),
           @"new session's own latest callback is admitted");
    NSUInteger beforeRepeatedStart=session.generation;
    session=DF177AppTouchBeginSession(session,10002.0);
    expect(!DF177AppTouchSessionMatches(session,beforeRepeatedStart,first,first),
           @"start itself revokes callbacks from an earlier start");

    DF177AppTouchSession other={0};
    other=DF177AppTouchBeginSession(other,10002.0);
    expect(!DF177AppTouchRecheckAllowed(other,other.generation,first,replacement,7,7),
           @"equal numeric generations cannot substitute another Chrome identity");
    expect(DF177AppTouchSessionMatches(other,other.generation,replacement,replacement),
           @"replacement instance may act for its own current session");
    other=DF177AppTouchBeginSession(other,NAN);
    expect(!other.active && !DF177AppTouchSessionMatches(other,
        other.generation,replacement,replacement),@"invalid start clock never admits activity");
    expect(DF177AppTouchNextGeneration(NSUIntegerMax)==1,
           @"generation wrap never produces an unset zero ticket");
}

int main(void) {
    @autoreleasepool {
        testOwnedActivity();
        testSchema();
        testEventFreshness();
        testSessionAndCallbackOwnership();
        printf("DF177_APP_TOUCH_RUNTIME_PASS checks=%lu FOUNDATION_ONLY\n",
               (unsigned long)checks);
    }
    return 0;
}
