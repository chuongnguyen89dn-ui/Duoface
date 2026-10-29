// DuoFace independent picker settings runtime test; only temporary files used.
#import <Foundation/Foundation.h>
#import <unistd.h>
#import "DFAppPickerDisplayPolicy.h"
#import "DFEnabledAppsPolicy.h"
static void verify(BOOL valid,NSString *message) {
 if(!valid){NSLog(@"DF_PICKER_TEST_FAIL %@",message);abort();}
}
int main(void) {
 @autoreleasepool {
  NSString *path=[NSTemporaryDirectory() stringByAppendingPathComponent:
    [NSString stringWithFormat:@"picker-test-%d-%@.plist",getpid(),NSUUID.UUID.UUIDString]];
  NSDictionary *defaults=DFReadPickerDisplayAtPath(path);
  verify([defaults[@"GridColumns"] integerValue]==4 &&
         [defaults[@"GridRows"] integerValue]==2 &&
         [defaults[@"ShowAppNames"] boolValue],@"4x2 visible names initial");
  for(NSInteger columns=4;columns<=6;columns++)
   for(NSInteger rows=2;rows<=3;rows++){
    verify(DFWritePickerDisplayAtPath(columns,rows,NO,path),@"write grid");
    NSDictionary *saved=DFReadPickerDisplayAtPath(path);
    verify([saved[@"GridColumns"] integerValue]==columns &&
           [saved[@"GridRows"] integerValue]==rows &&
           ![saved[@"ShowAppNames"] boolValue],@"read saved grid and names");
    verify(DFPickerCapacity(columns,rows)==columns*rows,@"grid capacity");
   }
  verify(!DFWritePickerDisplayAtPath(3,3,YES,path),@"reject 3 columns");
  verify(!DFWritePickerDisplayAtPath(6,4,YES,path),@"reject 4 rows");
  verify([@{@"Version":@2,@"GridColumns":@6,@"GridRows":@3,
           @"ShowAppNames":@NO} writeToFile:path atomically:YES],@"bad config written");
  verify([DFReadPickerDisplayAtPath(path)[@"GridColumns"] integerValue]==4,
         @"invalid file returns safe defaults");
  verify(!DFPickerAllowsApp(@"com.google.ios.youtube",nil),
         @"missing iPhone approval must NOT display apps");
  verify(!DFPickerAllowsApp(@"com.google.ios.youtube",@[]),
         @"disabled app hidden");
  verify(DFPickerAllowsApp(@"com.google.ios.youtube",@[@"com.google.ios.youtube"]),
         @"only explicitly enabled app shown");
  verify(!DFPickerAllowsApp(@"com.apple.springboard",@[@"com.apple.springboard"]),
         @"system process never allowed");
  [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
  NSLog(@"DF_PICKER_DISPLAY_RUNTIME_PASS");
 }
 return 0;
}
