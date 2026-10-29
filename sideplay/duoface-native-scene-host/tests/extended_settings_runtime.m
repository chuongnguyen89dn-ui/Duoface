#import <Foundation/Foundation.h>
#import <unistd.h>
#import "DFExtendedSettingsPolicy.h"
static void ck(BOOL b,NSString *r){if(!b){NSLog(@"DF_EXTENDED_FAIL %@",r);abort();}}
int main(void){@autoreleasepool{
 NSString *path=[NSTemporaryDirectory() stringByAppendingPathComponent:
   [NSString stringWithFormat:@"df-lang-%d-%@.plist",getpid(),NSUUID.UUID.UUIDString]];
 ck([DFReadExtendedAtPath(path)[@"Language"] isEqualToString:@"vi"],@"initial Vietnamese");
 ck(DFWriteExtendedAtPath(@"en",path),@"write English");
 ck([DFReadExtendedAtPath(path)[@"Language"] isEqual:@"en"],@"readback English");
 ck(!DFWriteExtendedAtPath(@"fr",path),@"reject unsupported locale");
 ck(DFWriteExtendedAtPath(@"vi",path),@"write Vietnamese");
 ck([DFReadExtendedAtPath(path)[@"Language"] isEqual:@"vi"],@"readback Vietnamese");
 [@{@"Version":@1,@"Language":@"xx"} writeToFile:path atomically:YES];
 ck([DFReadExtendedAtPath(path)[@"Language"] isEqual:@"vi"],@"fail closed invalid");
 [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
 NSLog(@"DF_EXTENDED_LOCALE_RUNTIME_PASS");
}return 0;}
