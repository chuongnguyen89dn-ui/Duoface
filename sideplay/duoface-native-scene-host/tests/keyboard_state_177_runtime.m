// Executes the shipping Foundation-only evidence policy with mock windows.
// No UIKit keyboard, iPhone sandbox or CarPlay rendering result is claimed.
#import "../DFKeyboardState177.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

// Execute DF156's real retained-mailbox algorithm with a deterministic notify
// backend. This tests channel isolation/bytes, not Darwin service permissions.
static uint64_t notifySlots[128];
static char notifyNames[128][224];
static int notifyUsed;
static uint32_t DF177TestNotifyRegister(const char *name,int *token) {
    for(int i=0;i<notifyUsed;i++)
        if(!strcmp(notifyNames[i],name)){*token=i;return 0;}
    if(notifyUsed>=128)return 1;
    *token=notifyUsed;
    snprintf(notifyNames[notifyUsed++],224,"%s",name);
    return 0;
}
static uint32_t DF177TestNotifySet(int token,uint64_t value) {
    if(token<0 || token>=notifyUsed)return 1;
    notifySlots[token]=value;
    return 0;
}
static uint32_t DF177TestNotifyGet(int token,uint64_t *value) {
    if(token<0 || token>=notifyUsed)return 1;
    *value=notifySlots[token];
    return 0;
}
static uint32_t DF177TestNotifyPost(const char *name){(void)name;return 0;}
#define DF156_NOTIFY_TEST 1
#ifndef NOTIFY_STATUS_OK
#define NOTIFY_STATUS_OK 0
#endif
#define notify_register_check DF177TestNotifyRegister
#define notify_set_state DF177TestNotifySet
#define notify_get_state DF177TestNotifyGet
#define notify_post DF177TestNotifyPost
#import "../DF156DarwinMailbox.h"
#undef notify_register_check
#undef notify_set_state
#undef notify_get_state
#undef notify_post

@interface DF177TestKeyboardWindow : NSObject <DF177ObservedKeyboardWindow>
@property(nonatomic,assign,getter=isHidden) BOOL hidden;
@end
@implementation DF177TestKeyboardWindow
@end

static NSUInteger checks;
static void expect(BOOL condition, NSString *message) {
    checks++;
    if(!condition){
        NSLog(@"DF177_KEYBOARD_STATE_FAIL %@",message);
        abort();
    }
}

static NSMutableDictionary *record(NSString *bundle, NSNumber *pid,
                                    BOOL visible, NSTimeInterval stamp) {
    return [@{@"version":@2,@"bundle":bundle,@"pid":pid,
              @"kb":@(visible),@"ts":@(stamp)} mutableCopy];
}

static void testWindowEvidence(void) {
    NSHashTable *known=[NSHashTable weakObjectsHashTable];
    expect(!DF177KeyboardSnapshot(known,@[]),@"no evidence is not visible");
    DF177TestKeyboardWindow *first=[DF177TestKeyboardWindow new];
    DF177ObserveKeyboardWindow(known,first,YES);
    expect(DF177KeyboardSnapshot(known,@[]),
           @"visible notification survives an empty public window scan");
    expect(DF177KeyboardSnapshot(known,@[]),
           @"repeated touch-time empty scans cannot erase visible evidence");

    DF177TestKeyboardWindow *replacement=[DF177TestKeyboardWindow new];
    DF177ObserveKeyboardWindow(known,replacement,YES);
    first.hidden=YES;
    DF177ObserveKeyboardWindow(known,first,NO);
    expect(DF177KeyboardSnapshot(known,@[]),
           @"hiding the old keyboard does not hide its visible replacement");
    DF177TestKeyboardWindow *unrelated=[DF177TestKeyboardWindow new];
    unrelated.hidden=YES;
    DF177ObserveKeyboardWindow(known,unrelated,NO);
    expect(DF177KeyboardSnapshot(known,@[]),
           @"a hide event for another identity cannot clear the replacement");
    replacement.hidden=YES;
    DF177ObserveKeyboardWindow(known,replacement,NO);
    expect(!DF177KeyboardSnapshot(known,@[]),
           @"hiding the exact last visible keyboard clears visibility");

    first.hidden=NO;
    expect(DF177KeyboardSnapshot(known,@[first]),
           @"a positive scan can discover a keyboard without its notification");
    expect(DF177KeyboardSnapshot(known,@[]),
           @"positive scan evidence survives a later incomplete scan");
    first.hidden=YES;
    expect(!DF177KeyboardSnapshot(known,@[]),
           @"a known window's actual hidden state revokes its evidence");
    expect(!DF177KeyboardSnapshot(known,@[first]),
           @"scanning a hidden keyboard cannot make it visible");

    __weak DF177TestKeyboardWindow *weakWindow;
    @autoreleasepool {
        DF177TestKeyboardWindow *temporary=[DF177TestKeyboardWindow new];
        weakWindow=temporary;
        DF177ObserveKeyboardWindow(known,temporary,YES);
        expect(DF177KeyboardSnapshot(known,@[]),
               @"temporary notification-observed keyboard is visible");
        temporary=nil;
    }
    expect(weakWindow==nil,@"evidence table must not retain a keyboard window");
    expect(!DF177KeyboardSnapshot(known,@[]),
           @"deallocation removes the last weak keyboard identity");
}

static void testRecords(void) {
    NSString *bundle=@"test.duoface.keyboard.alpha";
    NSNumber *pid=@1234;
    NSTimeInterval now=10000.0;
    NSDictionary *valid=record(bundle,pid,YES,now-1.0);
    expect(DF177KeyboardRecordMatches(valid,bundle,pid,now),@"valid visible record");
    expect(DF177KeyboardRecordMatches(record(bundle,pid,NO,1.0),bundle,pid,now),
           @"quiet same-process retained state does not expire by age alone");
    expect(!DF177KeyboardRecordMatches(valid,bundle,@1235,now),
           @"a restarted process cannot reuse its predecessor's snapshot");
    expect(!DF177KeyboardRecordMatches(valid,@"test.duoface.keyboard.beta",pid,now),
           @"another bundle cannot supply this owner's state");
    expect(!DF177KeyboardRecordMatches(nil,bundle,pid,now),@"missing record");
    expect(!DF177KeyboardRecordMatches((id)@[],bundle,pid,now),@"array payload rejected");
    expect(!DF177KeyboardRecordMatches((id)NSNull.null,bundle,pid,now),@"null payload rejected");
    expect(!DF177KeyboardRecordMatches(valid,bundle,nil,now),@"unverified process rejected");
    expect(!DF177KeyboardRecordMatches(record(bundle,@1,YES,now),bundle,@1,now),
           @"invalid process identifier rejected even when equal");
    expect(!DF177KeyboardRecordMatches(valid,@"",pid,now),@"empty expected bundle rejected");

    NSDictionary<NSString *,NSArray *> *invalidFields=@{
        @"version":@[@1,@"2",NSNull.null],
        @"bundle":@[@"test.duoface.keyboard.beta",@23,NSNull.null],
        @"pid":@[@1235,@"1234",@(1234.5),NSNull.null],
        @"kb":@[@2,@(-1),@"true",@(NAN),NSNull.null],
        @"ts":@[@0,@(-1),@"9999",@(NAN),@(INFINITY),@(-INFINITY),NSNull.null]
    };
    for(NSString *key in invalidFields){
        for(id value in invalidFields[key]){
            NSMutableDictionary *bad=[valid mutableCopy];
            bad[key]=value;
            expect(!DF177KeyboardRecordMatches(bad,bundle,pid,now),
                   [NSString stringWithFormat:@"reject malformed %@=%@",key,value]);
        }
        NSMutableDictionary *missing=[valid mutableCopy];
        [missing removeObjectForKey:key];
        expect(!DF177KeyboardRecordMatches(missing,bundle,pid,now),
               [NSString stringWithFormat:@"reject missing %@",key]);
    }
    expect(!DF177KeyboardRecordMatches(record(bundle,pid,YES,now+2.0),bundle,pid,now),
           @"future timestamp outside the one-second tolerance is rejected");
    expect(DF177KeyboardRecordMatches(record(bundle,pid,YES,now+1.0),bundle,pid,now),
           @"documented one-second clock tolerance is retained");
    expect(!DF177KeyboardRecordMatches(valid,bundle,pid,NAN),@"NaN current time rejected");
    expect(!DF177KeyboardRecordMatches(valid,bundle,pid,INFINITY),@"infinite current time rejected");

    // Both retained snapshots remain independently valid; a false from B is
    // never accepted as evidence that A's visible keyboard has closed.
    NSString *other=@"test.duoface.keyboard.beta";
    NSDictionary *a=record(bundle,pid,YES,now-20.0);
    NSDictionary *b=record(other,@5678,NO,now-1.0);
    expect(DF177KeyboardRecordMatches(a,bundle,pid,now),@"A snapshot accepted for A");
    expect(DF177KeyboardRecordMatches(b,other,@5678,now),@"B snapshot accepted for B");
    expect(!DF177KeyboardRecordMatches(b,bundle,pid,now),@"B false cannot clear A state");
    expect(!DF177KeyboardRecordMatches(a,other,@5678,now),@"A state cannot impersonate B");
}

static void testChannelIsolation(void) {
    NSString *bundleA=@"test.duoface.keyboard.alpha";
    NSString *bundleB=@"test.duoface.keyboard.beta";
    NSString *channelA=DF177KeyboardChannelName(bundleA);
    NSString *channelB=DF177KeyboardChannelName(bundleB);
    expect(channelA.length>0 && channelB.length>0,@"valid channels exist");
    expect(![channelA isEqual:channelB],@"different bundles have different channels");
    expect([channelA isEqual:DF177KeyboardChannelName(bundleA)],
           @"sender and later reader derive the same retained channel");
    expect(DF177KeyboardChannelName(nil)==nil,@"nil bundle has no channel");
    expect(DF177KeyboardChannelName(@"")==nil,@"empty bundle has no channel");
    expect(DF177KeyboardChannelName((id)@42)==nil,@"non-string bundle has no channel");
    NSString *longBundle=[@"a" stringByPaddingToLength:129 withString:@"a" startingAtIndex:0];
    expect(DF177KeyboardChannelName(longBundle)==nil,@"oversized bundle has no channel");

    DF156Mailbox writerA,writerB,readerA,readerB;
    DF156Init(&writerA,channelA.UTF8String);
    DF156Init(&writerB,channelB.UTF8String);
    DF156Init(&readerA,DF177KeyboardChannelName(bundleA).UTF8String);
    DF156Init(&readerB,DF177KeyboardChannelName(bundleB).UTF8String);
    NSData *a=[NSJSONSerialization dataWithJSONObject:record(bundleA,@1234,YES,9990.0)
                                             options:0 error:NULL];
    NSData *b=[NSJSONSerialization dataWithJSONObject:record(bundleB,@5678,NO,9991.0)
                                             options:0 error:NULL];
    expect(a!=nil && b!=nil,@"snapshot JSON encoded");
    expect(DF156Write(&writerA,a.bytes,a.length,1),@"A visible snapshot committed");
    expect(DF156Write(&writerB,b.bytes,b.length,2),@"B hidden snapshot committed");
    uint8_t bytes[DF156_MAX_BYTES];
    size_t size=DF156Read(&readerA,bytes);
    expect(size==a.length && !memcmp(bytes,a.bytes,size),
           @"B's later false snapshot does not overwrite A's retained true snapshot");
    size=DF156Read(&readerB,bytes);
    expect(size==b.length && !memcmp(bytes,b.bytes,size),
           @"B's own reader receives B's independent false snapshot");
    expect(DF156Write(&writerB,b.bytes,b.length,3),@"B republish succeeds");
    size=DF156Read(&readerA,bytes);
    expect(size==a.length && !memcmp(bytes,a.bytes,size),
           @"repeated B writes preserve quiet A's retained state");
}

static void testFailedPublishRetry(void) {
    BOOL lastVisible=NO,published=NO;
    expect(DF177KeyboardBeginPublish(NO,lastVisible,&published),
           @"initial hidden state must publish");
    published=YES; // Full initial write and common wake succeeded.
    expect(!DF177KeyboardBeginPublish(NO,lastVisible,&published),
           @"identical successfully published state is coalesced");
    expect(DF177KeyboardBeginPublish(YES,lastVisible,&published),
           @"visible transition begins publication");
    expect(!published,@"attempt invalidates the previous success marker");
    // Simulate failed write, or a successful write whose common wake failed:
    // production deliberately does not set published/lastVisible on failure.
    expect(DF177KeyboardBeginPublish(NO,lastVisible,&published),
           @"bounce back after failed transition still repairs the mailbox");
    expect(DF177KeyboardBeginPublish(NO,lastVisible,&published),
           @"repeated failed attempts remain retryable");
    published=YES;
    expect(!DF177KeyboardBeginPublish(NO,lastVisible,&published),
           @"coalescing resumes only after full publication success");
}

int main(void) {
    @autoreleasepool {
        testWindowEvidence();
        testRecords();
        testChannelIsolation();
        testFailedPublishRetry();
        printf("DF177_KEYBOARD_STATE_RUNTIME_PASS checks=%lu FOUNDATION_ONLY\n",
               (unsigned long)checks);
    }
    return 0;
}
