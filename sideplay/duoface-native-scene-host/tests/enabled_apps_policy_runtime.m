// Executable first-party regression. Only NSTemporaryDirectory is modified.
#import <Foundation/Foundation.h>
#import <unistd.h>
#import "DFEnabledAppsPolicy.h"
static void check(BOOL ok, NSString *reason) {
 if(!ok){NSLog(@"ENABLED_APPS_TEST_FAIL: %@",reason);abort();}
}
int main(void) {
 @autoreleasepool {
  NSString *path=[NSTemporaryDirectory() stringByAppendingPathComponent:
    [NSString stringWithFormat:@"df-apps-%d-%@.plist",getpid(),NSUUID.UUID.UUIDString]];
  check(DFReadEnabledAppIDsAtPath(path)==nil,@"missing config preserves legacy all");
  check(DFPickerAllowsApp(@"com.google.ios.youtube",nil),@"legacy gallery has eligible apps");
  check(DFWriteEnabledAppIDsAtPath(@[],path),@"save disable all");
  NSArray<NSString *> *none=DFReadEnabledAppIDsAtPath(path);
  check(none!=nil && none.count==0,@"explicit none != absent");
  check(!DFPickerAllowsApp(@"com.google.ios.youtube",none),@"disabled hidden");
  check(DFWriteEnabledAppIDsAtPath(@[@"com.google.ios.youtube",
    @"com.apple.springboard",@"com.google.ios.youtube",@"com.apple.Maps"],path),
    @"save allowed unique installed-style IDs");
  NSArray<NSString *> *ids=DFReadEnabledAppIDsAtPath(path);
  check(ids.count==2,@"deduplicate and reject system service");
  check(DFPickerAllowsApp(@"com.apple.Maps",ids),@"manually allowed maps");
  check(!DFPickerAllowsApp(@"com.apple.springboard",ids),@"no SpringBoard");
  check(DFIsRecommendedAppID(@"com.google.ios.youtube"),@"user app recommended");
  check(!DFIsRecommendedAppID(@"com.apple.Maps"),@"recommended excludes Apple");
  check([@{@"Version":@9,@"EnabledBundleIDs":@[@"com.google.ios.youtube"]}
    writeToFile:path atomically:YES],@"create invalid record");
  NSArray<NSString *> *bad=DFReadEnabledAppIDsAtPath(path);
  check(bad!=nil && bad.count==0,@"bad record fails closed");
  [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
  NSLog(@"ENABLED_APPS_POLICY_RUNTIME_PASS");
 }
 return 0;
}
