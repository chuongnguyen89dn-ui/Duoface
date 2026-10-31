#import <Foundation/Foundation.h>
#import "../DFHome140Consent.h"
#define CHECK(x) do {if(!(x)){NSLog(@"FAIL %d %s",__LINE__,#x);return 1;}}while(0)
int main(void) {@autoreleasepool {
 NSString *path=[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
 CHECK(!DFHome140EnabledAt(path,YES,NO)); // old136ON alone cannot reactivate140
 CHECK([@{@"Version":@1,@"Enabled":@YES} writeToFile:path atomically:YES]);
 CHECK(DFHome140EnabledAt(path,YES,NO));
 CHECK(!DFHome140EnabledAt(path,NO,NO));
 CHECK(!DFHome140EnabledAt(path,YES,YES));
 CHECK([@{@"Version":@2,@"Enabled":@YES} writeToFile:path atomically:YES]);
 CHECK(!DFHome140EnabledAt(path,YES,NO));
 CHECK([@{@"Version":@1,@"Enabled":@NO} writeToFile:path atomically:YES]);
 CHECK(!DFHome140EnabledAt(path,YES,NO));
 [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
 NSLog(@"QA140_FRESH_CONSENT_DEFAULT_OFF_PARENT_AND_KILL_SWITCH_PASS");return 0;
}}
