#import <Foundation/Foundation.h>
#import <unistd.h>
#import "DFDisconnectClosePolicy.h"
static void expect(BOOL x,NSString *msg){if(!x){NSLog(@"DF106_POLICY_FAIL %@",msg);abort();}}
int main(void){@autoreleasepool{
 NSString *path=[NSTemporaryDirectory() stringByAppendingPathComponent:
   [NSString stringWithFormat:@"disconnect-106-%d-%@.plist",getpid(),NSUUID.UUID.UUIDString]];
 expect(!DFDisconnectCloseReadAtPath(path),@"default-off");
 expect(DFDisconnectCloseWriteAtPath(path,YES),@"enable persisted");
 expect(DFDisconnectCloseReadAtPath(path),@"enabled readback");
 expect(!DFDisconnectCloseMayExecute(7,7,YES,YES,9.999),@"before-grace");
 expect(!DFDisconnectCloseMayExecute(7,8,YES,YES,10.1),@"stale-generation");
 expect(!DFDisconnectCloseMayExecute(7,7,NO,YES,10.1),@"physical-reconnected");
 expect(!DFDisconnectCloseMayExecute(7,7,YES,NO,10.1),@"disabled");
 expect(DFDisconnectCloseMayExecute(7,7,YES,YES,10.1),@"valid 10 seconds");
 expect(DFDisconnectCloseWriteAtPath(path,NO),@"disable persisted");
 expect(!DFDisconnectCloseReadAtPath(path),@"disabled readback");
 [@{@"Version":@1,@"CloseOnPhysicalDisconnect":@"YES"} writeToFile:path atomically:YES];
 expect(!DFDisconnectCloseReadAtPath(path),@"reject-string-bool");
 [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
 NSLog(@"DF106_DISCONNECT_POLICY_RUNTIME_PASS");
}return 0;}
