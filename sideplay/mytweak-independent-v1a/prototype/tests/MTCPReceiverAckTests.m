#import <Foundation/Foundation.h>
#import "../MTCPBridgeContract.h"
#include <stdlib.h>
static unsigned checks=0;
static void T(BOOL valid,NSString *why) {
    checks++;
    if (!valid) { NSLog(@"ACK TEST FAILURE: %@",why);exit(1); }
}
int main(void) { @autoreleasepool {
    NSString *session=@"5C20F9AF-0C68-4D89-A6EE-DDA5B2B2A8EB";
    NSTimeInterval now=NSDate.date.timeIntervalSince1970;
    NSMutableDictionary *d=[@{@"Version":@1,@"Kind":@"receiver-ack",
      @"Timestamp":@(now),@"Session":session,
      @"ContextID":@42,@"DashboardOwned":@YES,
      @"RootClass":@"DBDashboardRootViewController",
      @"X":@0.0887,@"Y":@0,@"Width":@0.9113,@"Height":@1} mutableCopy];
    T(MTCPBridgeValidateReceiverAck(d,session,now),@"valid native owner");
    T(!MTCPBridgeValidateReceiverAck(d,@"A929967B-8251-4675-BF9C-8799A666DB30",now),@"reject other session");
    T(!MTCPBridgeValidateReceiverAck(d,session,now+2.5),@"reject stale owner");
    d[@"DashboardOwned"]=@NO;
    T(!MTCPBridgeValidateReceiverAck(d,session,now),@"reject non Dashboard owner");
    d[@"DashboardOwned"]=@YES;
    d[@"RootClass"]=@"UIRootSceneWindow";
    T(!MTCPBridgeValidateReceiverAck(d,session,now),@"reject externally owned UIWindow");
    d[@"RootClass"]=@"DBDashboardRootViewController";
    d[@"X"]=@0.2;d[@"Width"]=@0.95;
    T(!MTCPBridgeValidateReceiverAck(d,session,now),@"reject offscreen content");
    d[@"X"]=@0;d[@"Width"]=@0.4;
    T(!MTCPBridgeValidateReceiverAck(d,session,now),@"reject tiny content");
    d[@"Width"]=@1;
    T(MTCPBridgeValidateReceiverAck(d,session,now),@"full bounded native content accepted");
    d[@"ContextID"]=@0;
    T(!MTCPBridgeValidateReceiverAck(d,session,now),@"reject zero context");
    d[@"ContextID"]=@42;
    d[@"Timestamp"]=@(now+5);
    T(!MTCPBridgeValidateReceiverAck(d,session,now),@"reject future replay");
    NSLog(@"PASS %u native receiver ownership ACK cases",checks);
    return 0;
}}
