// DuoFace first-party persistence and 3/4 pane visual permutations.
// Executed with macOS Foundation; all writes remain in a temporary folder.
#import <Foundation/Foundation.h>
#import <unistd.h>
#import "DFSlotWorkspacePolicy.h"
static void check(BOOL ok,NSString *reason){
 if(!ok){NSLog(@"WORKSPACE_RUNTIME_FAIL %@",reason);abort();}
}
int main(void){
 @autoreleasepool {
  NSString *path=[NSTemporaryDirectory() stringByAppendingPathComponent:
    [NSString stringWithFormat:@"df-workspace-%d-%@.plist",getpid(),NSUUID.UUID.UUIDString]];
  NSDictionary *empty=DFReadWorkspaceAtPath(path);
  check([empty[@"PhysicalBundles"] isEqual:DFEmptyPhysicalBundles()],@"clean four slots");
  check([empty[@"RestoreOnReconnect"] boolValue],@"restore opt in by saved choice");
  check(DFSavePhysicalBundleAtPath(0,@"com.example.a",path),@"slot1");
  check(DFSavePhysicalBundleAtPath(1,@"com.example.b",path),@"slot2");
  check(DFSavePhysicalBundleAtPath(2,@"com.example.c",path),@"slot3");
  check(DFSavePhysicalBundleAtPath(3,@"com.example.d",path),@"slot4");
  check(!DFSavePhysicalBundleAtPath(2,@"com.example.b",path),@"no duplicate host");
  check(!DFSavePhysicalBundleAtPath(4,@"com.example.e",path),@"invalid slot rejected");
  check(!DFSavePhysicalBundleAtPath(0,@"com.apple.springboard",path),@"excluded service");
  NSDictionary *ready=DFReadWorkspaceAtPath(path);
  check([ready[@"PhysicalBundles"] isEqualToArray:@[@"com.example.a",
             @"com.example.b",@"com.example.c",@"com.example.d"]],@"persistence readback");
  for(NSInteger n=3;n<=4;n++){
    for(NSInteger i=0;i<n;i++){
      check(DFVisualForPhysical(i,NO,n,ready)==i,@"identity visual position");
      check(DFPhysicalForVisual(i,NO,n,ready)==i,@"identity inverse");
    }
    check(DFRotateWorkspaceAtPath(n,YES,path),@"rotate forward");
    NSDictionary *rotated=DFReadWorkspaceAtPath(path);
    for(NSInteger i=0;i<n;i++){
      check(DFVisualForPhysical(i,NO,n,rotated)==(i+1)%n,@"forward cyclic mapping");
      check(DFPhysicalForVisual((i+1)%n,NO,n,rotated)==i,@"forward inverse");
    }
    check(DFRotateWorkspaceAtPath(n,NO,path),@"rotate reverse");
    ready=DFReadWorkspaceAtPath(path);
    for(NSInteger i=0;i<n;i++)
       check(DFVisualForPhysical(i,NO,n,ready)==i,@"roundtrip rotation");
  }
  check(DFVisualForPhysical(0,YES,3,ready)==1 &&
        DFPhysicalForVisual(0,YES,3,ready)==1,@"original two-position swap survives");
  NSSet *installed=[NSSet setWithArray:@[@"com.example.a",@"com.example.b",
                                         @"com.example.c",@"com.example.d"]];
  NSArray *enabled=@[@"com.example.a",@"com.example.c"];
  NSArray *restore=DFRestorablePhysicalBundles(ready,enabled,installed,4);
  check([restore isEqualToArray:@[@"com.example.a",@"",@"com.example.c",@""]],
        @"only installed and iPhone enabled restored");
  check(DFRestorablePhysicalBundles(ready,nil,installed,4).count==4,
        @"not authorized entries are represented as blanks");
  check([DFRestorablePhysicalBundles(ready,nil,installed,4)[0] length]==0,
        @"not authorized never launches");
  check(DFSavePhysicalBundleAtPath(0,@"",path),@"explicit close clears slot");
  check(![DFReadWorkspaceAtPath(path)[@"PhysicalBundles"][0] length],@"close persisted");
  NSMutableDictionary *off=[DFReadWorkspaceAtPath(path) mutableCopy];
  off[@"RestoreOnReconnect"]=@NO;
  check(DFWriteWorkspaceAtPath(off,path),@"disable restoration");
  check([DFRestorablePhysicalBundles(DFReadWorkspaceAtPath(path),enabled,installed,4) count]==0,
        @"opt out stops restoration");
  [@{@"Version":@2,@"PhysicalBundles":@[@"com.example.bad"]} writeToFile:path atomically:YES];
  check([DFReadWorkspaceAtPath(path)[@"PhysicalBundles"] isEqual:DFEmptyPhysicalBundles()],
        @"malformed preferences never resurrect apps");
  [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
  NSLog(@"DF_WORKSPACE_RUNTIME_PASS");
 }
 return 0;
}
