// Execute the shipping pending/identity policy. No UIKit, native event,
// filesystem receipt, or actual CarPlay session is constructed in this test.
#import <Foundation/Foundation.h>
#import "../DFNativeMapLaunchPolicy.h"
#include <float.h>

@interface DFLaunchPolicyContext : NSObject <DFNativeMapLaunchContextIdentity>
@property(nonatomic,weak) id dashboard;
@property(nonatomic,weak) id workspace;
@property(nonatomic,weak) id owner;
@property(nonatomic,weak) id root;
@property(nonatomic,weak) id window;
@property(nonatomic,weak) id screen;
@property(nonatomic,copy) NSString *physicalSession;
@property(nonatomic,assign) uint64_t homeGeneration;
@property(nonatomic,assign) BOOL homeHooksReady;
@end
@implementation DFLaunchPolicyContext
@end

static NSUInteger checks=0;
static void check(BOOL condition,NSString *why) {
    checks++;
    if(!condition){NSLog(@"DF_NATIVE_MAP_LAUNCH_POLICY_FAIL %@",why);abort();}
}
static DFLaunchPolicyContext *context(NSArray *objects,NSString *session) {
    DFLaunchPolicyContext *value=[DFLaunchPolicyContext new];
    value.dashboard=objects[0];value.workspace=objects[1];value.owner=objects[2];
    value.root=objects[3];value.window=objects[4];value.screen=objects[5];
    value.physicalSession=session;value.homeGeneration=7;value.homeHooksReady=YES;
    return value;
}
static DFNativeMapLaunchEvidence evidence(void) {
    return (DFNativeMapLaunchEvidence){.physicalVerified=YES,.sameSession=YES,
        .samePane=YES,.leaseAbsent=YES,.matchingOwners=0,.matchingOwnerReady=NO};
}
int main(void){@autoreleasepool{
    __attribute__((objc_precise_lifetime)) NSArray *objects=@[
        [NSObject new],[NSObject new],[NSObject new],[NSObject new],[NSObject new],[NSObject new]];
    __attribute__((objc_precise_lifetime)) NSObject *replacement=[NSObject new];
    NSString *session=NSUUID.UUID.UUIDString;
    DFLaunchPolicyContext *expected=context(objects,session),*current=context(objects,session);
    DFNativeMapLaunchEvidence proof=evidence();

    // Zero, one ready, one not ready, and ambiguous are distinct outcomes.
    check(DFNativeMapSelectAttachAction(YES,0,NO)==DFNativeMapAttachStartLaunch,@"fresh explicit missing owner may launch");
    check(DFNativeMapSelectAttachAction(NO,0,NO)==DFNativeMapAttachRejectMissing,@"automatic reconnect never launches");
    for(NSNumber *explicit in @[@NO,@YES]) {
        check(DFNativeMapSelectAttachAction(explicit.boolValue,1,YES)==DFNativeMapAttachExistingOwner,@"unique live owner adopts without launch");
        check(DFNativeMapSelectAttachAction(explicit.boolValue,1,NO)==DFNativeMapAttachRejectNotReady,@"existing not-ready owner cannot cause another launch");
        check(DFNativeMapSelectAttachAction(explicit.boolValue,2,YES)==DFNativeMapAttachRejectAmbiguous,@"multiple live owners rejected");
        check(DFNativeMapSelectAttachAction(explicit.boolValue,NSUIntegerMax,NO)==DFNativeMapAttachRejectAmbiguous,@"all ambiguous counts rejected");
    }
    DFNativeMapLaunchState state={0};
    check(DFNativeMapLaunchBegin(&state,100,0),@"begin fresh bounded request");
    uint64_t first=state.generation;
    check(first && state.active && !state.attempted && !state.submitted && !state.adopting &&
          state.startedMonotonic==100 && state.deadlineMonotonic==106,@"begin captures a six-second monotonic interval");
    check(!DFNativeMapLaunchBegin(&state,100.1,0),@"second pending request cannot replace active state implicitly");
    check(DFNativeMapLaunchEvaluate(&state,first,100,expected,current,proof)==DFNativeMapLaunchWaiting,@"waiting without owner");
    check(!DFNativeMapLaunchMarkSubmitted(&state,first,100),@"no submission before attempt");
    check(!DFNativeMapLaunchClaimAdoption(&state,first,100),@"no adoption before event submission");
    check(DFNativeMapLaunchClaimAttempt(&state,first,100),@"claim sole attempt before native call");
    check(!DFNativeMapLaunchClaimAttempt(&state,first,100.1),@"reentrant call cannot claim another event");
    proof.matchingOwners=1;proof.matchingOwnerReady=YES;
    check(DFNativeMapLaunchEvaluate(&state,first,100.2,expected,current,proof)==DFNativeMapLaunchWaiting,@"scene arrival inside native factory cannot adopt before submission returns");
    check(DFNativeMapLaunchMarkSubmitted(&state,first,100.3),@"successful native return marks submission once");
    check(!DFNativeMapLaunchMarkSubmitted(&state,first,100.4),@"duplicate submission return ignored");
    check(DFNativeMapLaunchEvaluate(&state,first,105.999,expected,current,proof)==DFNativeMapLaunchReadyToAdopt,@"observed unique owner ready before deadline");
    proof.matchingOwnerReady=NO;
    check(DFNativeMapLaunchEvaluate(&state,first,101,expected,current,proof)==DFNativeMapLaunchWaiting,@"wait for actual live owner readiness");
    proof.matchingOwnerReady=YES;

    // Every native identity, current Home generation and physical session are
    // exercised through the same shared matcher as the real dispatcher.
    NSArray *fields=@[@"dashboard",@"workspace",@"owner",@"root",@"window",@"screen"];
    for(NSUInteger index=0;index<fields.count;index++) {
        [current setValue:replacement forKey:fields[index]];
        check(DFNativeMapLaunchEvaluate(&state,first,101,expected,current,proof)==DFNativeMapLaunchContextChanged,
              [NSString stringWithFormat:@"replaced %@ cancels",fields[index]]);
        [current setValue:nil forKey:fields[index]];
        check(DFNativeMapLaunchEvaluate(&state,first,101,expected,current,proof)==DFNativeMapLaunchContextChanged,
              [NSString stringWithFormat:@"lost weak %@ cancels",fields[index]]);
        [current setValue:objects[index] forKey:fields[index]];
    }
    current.homeGeneration++;
    check(DFNativeMapLaunchEvaluate(&state,first,101,expected,current,proof)==DFNativeMapLaunchContextChanged,@"Home invalidates pending request");
    current.homeGeneration=0;
    check(DFNativeMapLaunchEvaluate(&state,first,101,expected,current,proof)==DFNativeMapLaunchContextChanged,@"unobserved Home generation rejected");
    current.homeGeneration=expected.homeGeneration;current.homeHooksReady=NO;
    check(DFNativeMapLaunchEvaluate(&state,first,101,expected,current,proof)==DFNativeMapLaunchContextChanged,@"unavailable Home cancellation hooks rejected");
    current.homeHooksReady=YES;current.physicalSession=NSUUID.UUID.UUIDString;
    check(DFNativeMapLaunchEvaluate(&state,first,101,expected,current,proof)==DFNativeMapLaunchContextChanged,@"provider session replacement cancels");
    current.physicalSession=@"invalid";
    check(DFNativeMapLaunchEvaluate(&state,first,101,expected,current,proof)==DFNativeMapLaunchContextChanged,@"malformed context session rejected");
    current.physicalSession=session;
    @autoreleasepool {
        __attribute__((objc_precise_lifetime)) NSObject *temporary=[NSObject new];
        current.workspace=temporary;
        check(current.workspace!=nil,@"weak context observes a living workspace");
    }
    check(current.workspace==nil,@"context does not retain destroyed native workspace");
    check(DFNativeMapLaunchEvaluate(&state,first,101,expected,current,proof)==DFNativeMapLaunchContextChanged,@"deallocated workspace cancels");
    current.workspace=objects[1];
    check(DFNativeMapLaunchEvaluate(&state,first,101,expected,nil,proof)==DFNativeMapLaunchContextChanged,@"missing provider context cancels");

    proof.physicalVerified=NO;
    check(DFNativeMapLaunchEvaluate(&state,first,101,expected,current,proof)==DFNativeMapLaunchSessionChanged,@"stale or revoked physical receipt cancels");
    proof.physicalVerified=YES;proof.sameSession=NO;
    check(DFNativeMapLaunchEvaluate(&state,first,101,expected,current,proof)==DFNativeMapLaunchSessionChanged,@"new physical session cancels");
    proof.sameSession=YES;proof.samePane=NO;
    check(DFNativeMapLaunchEvaluate(&state,first,101,expected,current,proof)==DFNativeMapLaunchPaneChanged,@"resized or swapped physical target cancels");
    proof.samePane=YES;proof.leaseAbsent=NO;
    check(DFNativeMapLaunchEvaluate(&state,first,101,expected,current,proof)==DFNativeMapLaunchLeaseChanged,@"another active lease cancels");
    proof.leaseAbsent=YES;proof.matchingOwners=2;
    check(DFNativeMapLaunchEvaluate(&state,first,101,expected,current,proof)==DFNativeMapLaunchAmbiguousOwner,@"ambiguity cancels even if one owner appears ready");
    proof.matchingOwners=1;
    for(NSNumber *time in @[@99.99,@106,@107,@(NAN),@(INFINITY),@(-INFINITY)])
        check(DFNativeMapLaunchEvaluate(&state,first,time.doubleValue,expected,current,proof)==DFNativeMapLaunchTimedOut,@"deadline or invalid monotonic time cancels");
    check(!DFNativeMapLaunchClaimAdoption(&state,first,106),@"adoption forbidden at exact deadline");
    check(DFNativeMapLaunchClaimAdoption(&state,first,101),@"claim one containment transaction");
    check(DFNativeMapLaunchCanCommit(&state,first,8,8,101,expected,7,proof),@"verified owned adoption can commit");
    check(!DFNativeMapLaunchCanCommit(&state,first,8,8,101,expected,8,proof),
          @"Home during last native getter cancels commit even if revoke receipt still looks valid");
    check(!DFNativeMapLaunchCanCommit(&state,first,8,8,101,expected,0,proof),@"missing pure Home reader denies commit");
    check(!DFNativeMapLaunchCanCommit(&state,first,8,9,101,expected,7,proof),@"consumed newer command denies final commit");
    check(!DFNativeMapLaunchCanCommit(&state,first,8,8,106,expected,7,proof),@"expired adoption cannot commit");
    check(!DFNativeMapLaunchClaimAdoption(&state,first,101.1),@"reentrant adoption cannot repeat");
    check(DFNativeMapLaunchEvaluate(&state,first,101.1,expected,current,proof)==DFNativeMapLaunchWaiting,@"in-progress containment cannot reenter adoption");
    DFNativeMapLaunchInvalidate(&state);
    check(!state.active && !state.attempted && !state.submitted && !state.adopting && state.generation!=first,@"cancel invalidates every pending phase");
    check(DFNativeMapLaunchEvaluate(&state,first,101.2,expected,current,proof)==DFNativeMapLaunchStaleGeneration,@"cancelled callback cannot continue");
    check(!DFNativeMapLaunchCanCommit(&state,first,8,8,101.2,expected,7,proof),@"cancelled adoption cannot gain a deferred lease");
    check(DFNativeMapLaunchBegin(&state,102,0),@"new explicit request begins after cancellation");
    check(!DFNativeMapLaunchClaimAttempt(&state,first,102),@"old request cannot claim new generation");
    check(!DFNativeMapLaunchMarkSubmitted(&state,first,102),@"late old native return cannot mark new request submitted");
    check(!DFNativeMapLaunchClaimAdoption(&state,first,102),@"old request cannot adopt in replacement generation");
    DFNativeMapLaunchInvalidate(&state);
    check(DFNativeMapLaunchBegin(&state,200,5),@"last fresh second remains admissible");
    check(state.deadlineMonotonic==201,@"original delivery age shortens server lifetime");
    check(!DFNativeMapLaunchClaimAttempt(&state,state.generation,201),@"delayed request cannot gain a new six seconds");
    DFNativeMapLaunchInvalidate(&state);
    for(NSNumber *age in @[@(-0.1),@5.001,@(NAN),@(INFINITY)])
        check(!DFNativeMapLaunchBegin(&state,300,age.doubleValue),@"invalid original command age rejected");
    for(NSNumber *time in @[@(-1),@(NAN),@(INFINITY),@(DBL_MAX)])
        check(!DFNativeMapLaunchBegin(&state,time.doubleValue,0),@"invalid or nonadvancing monotonic interval rejected");

    // Native dispatch may synchronously cancel and replace its request. The
    // shipping claim/finish predicates prevent a second old event/adoption.
    DFNativeMapLaunchState reentrant={0};
    check(DFNativeMapLaunchBegin(&reentrant,400,0),@"reentrant fixture admitted");
    uint64_t oldGeneration=reentrant.generation;NSUInteger events=0;
    if(DFNativeMapLaunchClaimAttempt(&reentrant,oldGeneration,400)) {
        events++;
        check(!DFNativeMapLaunchClaimAttempt(&reentrant,oldGeneration,400),@"native reentry cannot send another event");
        DFNativeMapLaunchInvalidate(&reentrant);
        check(DFNativeMapLaunchBegin(&reentrant,400.1,0),@"new command can replace cancelled request");
    }
    check(events==1 && !DFNativeMapLaunchMarkSubmitted(&reentrant,oldGeneration,400.2),@"stale native completion has no authority in new request");

    // A can reenter native getters before it has any pending object. B's
    // already-consumed Restore still invalidates A's captured admission.
    DFNativeMapLaunchState notYetPending={0};
    uint64_t acceptedA=50,acceptedB=DFNativeMapLaunchNextGeneration(acceptedA);
    check(!DFNativeMapLaunchBeginForCommand(&notYetPending,acceptedA,acceptedB,500,0),
          @"consumed newer Restore prevents old observer from installing pending state");
    check(!notYetPending.active && !notYetPending.generation,
          @"old observer leaves newer command state untouched");
    check(!DFNativeMapCommandGenerationMatches(acceptedA,acceptedB),
          @"old adoption and old terminal ACK lose authority after native getter reentry");
    check(DFNativeMapLaunchBeginForCommand(&notYetPending,acceptedB,acceptedB,500.1,0),
          @"current command retains launch admission");
    check(!DFNativeMapCommandGenerationMatches(0,0),@"uninitialized command generation is not admitted");

    NSString *request=NSUUID.UUID.UUIDString;
    NSDictionary *command=@{@"Version":@1,@"RequestID":request,@"Operation":@"Attach",@"Timestamp":@1000};
    check(DFNativeMapFreshExplicitCommand(command,1000),@"original command fresh at receipt");
    check(DFNativeMapFreshExplicitCommand(command,1005),@"existing five-second freshness boundary retained");
    for(NSNumber *time in @[@999.9,@1005.001,@(NAN),@(INFINITY)])
        check(!DFNativeMapFreshExplicitCommand(command,time.doubleValue),@"future or expired command cannot start launch");
    for(NSString *key in @[@"Version",@"Timestamp",@"RequestID",@"Operation"]){
        NSMutableDictionary *bad=[command mutableCopy];bad[key]=NSNull.null;
        check(!DFNativeMapFreshExplicitCommand(bad,1000),@"malformed command envelope rejected");
    }
    NSMutableDictionary *bad=[command mutableCopy];bad[@"Version"]=@YES;
    check(!DFNativeMapFreshExplicitCommand(bad,1000),@"boolean is not schema version");
    NSMutableDictionary *consumed=[NSMutableDictionary new];
    check(DFNativeMapConsumeExplicitRequest(consumed,request,10),@"fresh request consumed once");
    NSString *newRequest=NSUUID.UUID.UUIDString;
    check(DFNativeMapConsumeExplicitRequest(consumed,newRequest,11),@"new request consumes a separate ID");
    check(!DFNativeMapConsumeExplicitRequest(consumed,request,12),@"superseded request replay rejected");
    check(!DFNativeMapConsumeExplicitRequest(consumed,request,17.999),@"consumed ID retained through client deadline");
    check(DFNativeMapConsumeExplicitRequest(consumed,request,18),@"expired cache entry can be reclaimed");
    check(!DFNativeMapFreshExplicitCommand(command,1008),@"unchanged original timestamp prevents launch after cache expiry");
    NSMutableDictionary *full=[NSMutableDictionary new];
    for(NSUInteger i=0;i<128;i++)
        check(DFNativeMapConsumeExplicitRequest(full,NSUUID.UUID.UUIDString,20),@"bounded cache records unique active request");
    check(!DFNativeMapConsumeExplicitRequest(full,NSUUID.UUID.UUIDString,21),@"cache overflow refuses instead of evicting replay protection");
    check(full.count==128,@"cache remains bounded");
    check(DFNativeMapConsumeExplicitRequest(full,NSUUID.UUID.UUIDString,28),@"expired cache releases admission capacity");
    check(!DFNativeMapConsumeExplicitRequest(full,NSUUID.UUID.UUIDString,NAN),@"invalid dedup clock rejected");
    NSLog(@"DF_NATIVE_MAP_LAUNCH_POLICY_RUNTIME_PASS checks=%lu FOUNDATION_ONLY",(unsigned long)checks);
}return 0;}
