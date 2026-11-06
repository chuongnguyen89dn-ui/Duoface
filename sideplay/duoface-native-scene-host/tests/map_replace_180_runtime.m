#import "../DFMapReplace180.h"
#include <assert.h>
int main(void) {@autoreleasepool {
    NSString *session=NSUUID.UUID.UUIDString;
    NSMutableDictionary *pane0=[@{@"VisualSlot":@0,@"PhysicalSlot":@0,@"WindowVisible":@YES,@"OnExternalScreen":@YES,@"HasLiveApp":@YES} mutableCopy];
    NSMutableDictionary *pane1=[@{@"VisualSlot":@1,@"PhysicalSlot":@1,@"WindowVisible":@YES,@"OnExternalScreen":@YES,@"HasLiveApp":@NO} mutableCopy];
    NSMutableDictionary *sample=[@{@"Version":@1,@"Owner":@"SpringBoard",@"Session":session,@"ActiveSlots":@2,@"Focus":@(-1),@"Timestamp":@101,@"Windows":@[pane0,pane1]} mutableCopy];
    NSMutableDictionary *pulse=[@{@"Session":session,@"Active":@YES,@"Timestamp":@101} mutableCopy];
    assert(DF180EmptyPaneReadbackReady(sample,pulse,session,1,1,100,101.5));
    assert(!DF180EmptyPaneReadbackReady(sample,pulse,session,0,0,100,101.5));
    assert(!DF180EmptyPaneReadbackReady(sample,pulse,session,1,0,100,101.5));
    assert(!DF180EmptyPaneReadbackReady(sample,pulse,session,1,1,101.1,101.5));
    assert(!DF180EmptyPaneReadbackReady(sample,pulse,session,1,1,100,104));
    pane1[@"HasLiveApp"]=@YES;assert(!DF180EmptyPaneReadbackReady(sample,pulse,session,1,1,100,101.5));pane1[@"HasLiveApp"]=@NO;
    pane1[@"PhysicalSlot"]=@0;assert(!DF180EmptyPaneReadbackReady(sample,pulse,session,1,1,100,101.5));pane1[@"PhysicalSlot"]=@1;
    pulse[@"Session"]=NSUUID.UUID.UUIDString;assert(!DF180EmptyPaneReadbackReady(sample,pulse,session,1,1,100,101.5));pulse[@"Session"]=session;
    pulse[@"Active"]=@NO;assert(!DF180EmptyPaneReadbackReady(sample,pulse,session,1,1,100,101.5));pulse[@"Active"]=@YES;
    sample[@"Focus"]=@0;assert(!DF180EmptyPaneReadbackReady(sample,pulse,session,1,1,100,101.5));sample[@"Focus"]=@(-1);
    // A swapped layout is allowed only if BOTH distinct physical identities agree.
    pane0[@"PhysicalSlot"]=@1;pane1[@"PhysicalSlot"]=@0;
    assert(DF180EmptyPaneReadbackReady(sample,pulse,session,1,0,100,101.5));
    assert(!DF180EmptyPaneReadbackReady(sample,pulse,session,1,1,100,101.5));
    assert(!DF180EmptyPaneReadbackReady(@{},pulse,session,1,0,100,101.5));
    puts("QA180_REAL_EMPTY_PANE_BARRIER_POLICY_PASS_13_CASES");
    return 0;
}}
