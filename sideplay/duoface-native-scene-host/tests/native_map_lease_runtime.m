// Executable macOS Foundation test of the exact production map-lease policy.
// Paths are isolated to a temporary directory; no user's phone prefs are touched.
#import <Foundation/Foundation.h>
#import "../DFNativeMapLeasePolicy.h"
#include <assert.h>
#include <math.h>
int main(void) {
 @autoreleasepool{
  NSString *base=[NSTemporaryDirectory() stringByAppendingPathComponent:
      [@"DFMapLeaseTest-" stringByAppendingString:NSUUID.UUID.UUIDString]];
  assert([[NSFileManager defaultManager] createDirectoryAtPath:base
        withIntermediateDirectories:YES attributes:nil error:nil]);
  NSString *lease=[base stringByAppendingPathComponent:@"lease.plist"];
  NSString *choice=[base stringByAppendingPathComponent:@"choice.plist"];
  NSString *session=NSUUID.UUID.UUIDString;
  NSString *other=NSUUID.UUID.UUIDString;
  assert(DFNativeMapAllowedBundle(@"com.google.Maps"));
  assert(DFNativeMapAllowedBundle(@"com.apple.Maps"));
  assert(DFNativeMapAllowedBundle(@"com.waze.iphone"));
  assert(!DFNativeMapAllowedBundle(@"com.apple.springboard"));
  assert(!DFNativeMapAllowedBundle(@"com.google.youtube"));
  assert(!DFNativeMapWriteLeaseAtPath(lease,session,@"com.google.youtube",0,100));
  assert(!DFNativeMapWriteLeaseAtPath(lease,session,@"com.google.Maps",2,100));
  assert(!DFNativeMapWriteLeaseAtPath(lease,@"bad-uuid",@"com.google.Maps",0,100));
  assert(DFNativeMapWriteLeaseAtPath(lease,session,@"com.google.Maps",0,100));
  assert([DFNativeMapFreshLeaseAtPath(lease,session,102)[@"BundleID"]
                  isEqualToString:@"com.google.Maps"]);
  assert(DFNativeMapFreshLeaseAtPath(lease,session,105));
  assert(DFNativeMapFreshLeaseAtPath(lease,session,106)==nil);
  assert(DFNativeMapFreshLeaseAtPath(lease,session,99)==nil);
  assert(DFNativeMapFreshLeaseAtPath(lease,other,102)==nil);
  assert(!DFNativeMapSaveChoiceAtPath(choice,-1));
  assert(!DFNativeMapRememberedChoiceAtPath(choice));
  assert(DFNativeMapSaveChoiceAtPath(choice,1));
  assert([DFNativeMapRememberedChoiceAtPath(choice)[@"Slot"] integerValue]==1);
  assert(!DFNativeMapSaveChoiceAtPath(choice,4));
  assert([DFNativeMapRememberedChoiceAtPath(choice)[@"Slot"] integerValue]==1);
  assert(DFNativeMapSaveChoiceAtPath(choice,0));
  assert([DFNativeMapRememberedChoiceAtPath(choice)[@"Slot"] integerValue]==0);
  [[NSFileManager defaultManager] removeItemAtPath:base error:nil];
  puts("PASS_MAP_LEASE_EXACT_SESSION_TTL_BUNDLE_SLOT_CHOICE");
 }
 return 0;
}
