#import <Foundation/Foundation.h>
#import "../DFCarPlayOwnerLease.h"
#include <assert.h>
#include <stdio.h>
int main(void) {@autoreleasepool {
    NSString *sid=@"00000000-0000-4000-8000-000000000001";
    NSString *other=@"00000000-0000-4000-8000-000000000002";
    NSDictionary *owner=@{@"Version":@1,@"Session":sid,@"HostSceneID":@"host1",
        @"NativeSceneID":@"native1",@"Active":@YES,@"HomeHookReady":@YES,
        @"Process":@"CarPlay",@"Bundle":@"com.duoface.native.scenehost",@"Timestamp":@100};
    NSDictionary *pulse=@{@"Version":@1,@"Session":sid,@"HostSceneID":@"host1",
        @"Active":@YES,@"HostBackground":@YES,@"Timestamp":@100};
    NSDictionary *revoke=@{@"Version":@1,@"Session":sid,@"Revoked":@YES,@"Timestamp":@0};
    assert(DFOwnerAcceptRecords(pulse,owner,nil,100));
    assert(!DFOwnerAcceptRecords(pulse,nil,nil,100));
    assert(!DFOwnerAcceptRecords(pulse,owner,revoke,100));
    assert(DFOwnerRevokeMatches(revoke,sid)); // sticky, even old Timestamp=0
    assert(!DFOwnerRevokeMatches(revoke,other)); // delayed old Home cannot revoke new UUID
    assert(!DFOwnerAcceptRecords(pulse,owner,nil,101.251));
    assert(!DFOwnerAcceptRecords(pulse,owner,nil,99.999));
    NSUInteger checks=7;
    NSDictionary *bad=@{@"Version":@2,@"Session":other,@"HostSceneID":@"other-host",
        @"NativeSceneID":@"",@"Active":@NO,@"HomeHookReady":@NO,
        @"Process":@"CarPlayApp",@"Bundle":@"foreign.bundle",@"Timestamp":@"100"};
    for(NSString *key in bad) {
        NSMutableDictionary *changed=[owner mutableCopy];changed[key]=bad[key];
        assert(!DFOwnerAcceptRecords(pulse,changed,nil,100));checks++;
        [changed removeObjectForKey:key];
        assert(!DFOwnerAcceptRecords(pulse,changed,nil,100));checks++;
    }
    NSMutableDictionary *fg=[pulse mutableCopy];fg[@"HostBackground"]=@NO;
    assert(DFOwnerAcceptRecords(fg,nil,nil,100));checks++;
    assert(!DFOwnerAcceptRecords(fg,nil,revoke,100));checks++;
    fg[@"HostBackground"]=@"bad-type";
    assert(!DFOwnerAcceptRecords(fg,owner,nil,100));checks++;
    NSMutableDictionary *suspended=[pulse mutableCopy];suspended[@"Timestamp"]=@0;
    assert(DFOwnerAcceptRecords(suspended,owner,nil,100));checks++;
    assert(!DFOwnerAcceptRecords(suspended,nil,nil,100));checks++;
    suspended[@"HostBackground"]=@NO;
    assert(!DFOwnerAcceptRecords(suspended,owner,nil,100));checks++;
    // Transition: app suspends; only continuously renewed SAME native owner survives.
    NSMutableDictionary *live=[owner mutableCopy];live[@"Timestamp"]=@130;
    suspended[@"HostBackground"]=@YES;
    assert(DFOwnerAcceptRecords(suspended,live,nil,130));checks++;
    assert(!DFOwnerAcceptRecords(suspended,live,nil,131.251));checks++;
    assert(!DFOwnerAcceptRecords(suspended,live,revoke,130));checks++;
    NSMutableDictionary *newPulse=[pulse mutableCopy];newPulse[@"Session"]=other;
    NSMutableDictionary *newOwner=[owner mutableCopy];newOwner[@"Session"]=other;
    assert(DFOwnerAcceptRecords(newPulse,newOwner,revoke,100));checks++;
    printf("%lu real Foundation lease/identity/revocation cases PASS\n",(unsigned long)checks);
}}
