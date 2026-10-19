// Executable macOS Foundation regression for the same platform-neutral validators.
// Not a real iOS/CarPlay runtime or UI test.
#import <Foundation/Foundation.h>
#import "MTCPBridgeContract.h"
#include <stdio.h>
static int checks=0;
static int failures=0;
static void Expect(BOOL value,const char *message) {
    ++checks;
    if (!value) { ++failures;fprintf(stderr,"FAIL: %s\n",message); }
}
int main(int argc,const char **argv) {
    (void)argc;(void)argv;
    @autoreleasepool {
        NSString *session=@"12345678-1234-1234-1234-1234567890AB";
        NSTimeInterval now=1000.0;
        NSDictionary *surface=@{@"Version":@1,@"Kind":@"surface",
            @"Session":session,@"Timestamp":@999.5,
            @"ContextID":@42,@"X":@0.10,@"Y":@0.05,
            @"Width":@0.80,@"Height":@0.90};
        Expect(MTCPBridgeValidateSurface(surface,session,now),"fresh bounded surface accepted");
        Expect(!MTCPBridgeValidateSurface(surface,@"00000000-0000-0000-0000-000000000000",now),
               "cross-session surface rejected");
        Expect(!MTCPBridgeValidateSurface(surface,session,1005),"stale surface rejected");
        Expect(!MTCPBridgeValidateSurface(surface,session,999),"future surface rejected");
        NSMutableDictionary *bad=[surface mutableCopy];
        bad[@"ContextID"]=@0;
        Expect(!MTCPBridgeValidateSurface(bad,session,now),"invalid context rejected");
        bad=[surface mutableCopy];bad[@"Width"]=@0.99;
        Expect(!MTCPBridgeValidateSurface(bad,session,now),"bounds overflow rejected");
        bad=[surface mutableCopy];bad[@"Kind"]=@1;
        Expect(!MTCPBridgeValidateSurface(bad,session,now),"malformed kind rejected without exception");
        bad=[surface mutableCopy];bad[@"Session"]=@123;
        Expect(!MTCPBridgeValidateSurface(bad,session,now),"malformed session type rejected");
        bad=[surface mutableCopy];bad[@"X"]=@(-1);
        Expect(!MTCPBridgeValidateSurface(bad,session,now),"negative coordinate rejected");
        bad=[surface mutableCopy];bad[@"Timestamp"]=@"wrong-type";
        Expect(!MTCPBridgeValidateSurface(bad,session,now),"wrong time type rejected");

        NSDictionary *control=@{@"Version":@1,@"Kind":@"command",
           @"Session":session,@"Timestamp":@999.5,
           @"Sequence":@7,@"Action":@"swap"};
        Expect(MTCPBridgeValidateCommand(control,session,6,now),"monotonic action accepted");
        Expect(!MTCPBridgeValidateCommand(control,session,7,now),"duplicate seq rejected");
        Expect(!MTCPBridgeValidateCommand(control,session,8,now),"out of order rejected");
        Expect(!MTCPBridgeValidateCommand(control,session,6,1005),"stale cmd rejected");
        bad=[control mutableCopy];bad[@"Action"]=@"launch-other-bundle";
        Expect(!MTCPBridgeValidateCommand(bad,session,6,now),"arbitrary action rejected");
        bad=[control mutableCopy];bad[@"Phase"]=@"begin";
        Expect(!MTCPBridgeValidateCommand(bad,session,6,now),"extra fields on action rejected");
        bad=[control mutableCopy];bad[@"Action"]=@"pointer";bad[@"Phase"]=@"begin";
        bad[@"X"]=@0.9;bad[@"Y"]=@0.15;
        Expect(MTCPBridgeValidateCommand(bad,session,6,now),"bounded pointer accepted");
        bad[@"X"]=@1.2;
        Expect(!MTCPBridgeValidateCommand(bad,session,6,now),"pointer overflow rejected");
        bad[@"X"]=@0.5;bad[@"Phase"]=@"unknown";
        Expect(!MTCPBridgeValidateCommand(bad,session,6,now),"unknown touch phase rejected");
        bad[@"Phase"]=@"end";bad[@"Sequence"]=@1000000001ULL;
        Expect(!MTCPBridgeValidateCommand(bad,session,6,now),"oversized seq rejected");
        bad[@"Sequence"]=@7;bad[@"Kind"]=@YES;
        Expect(!MTCPBridgeValidateCommand(bad,session,6,now),"malformed command type rejected");
        fprintf(stdout,"MTCPBridgeContract runtime checks=%d failures=%d\n",checks,failures);
        return failures ? 1:0;
    }
}
