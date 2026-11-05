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
  NSString *heartbeat=[base stringByAppendingPathComponent:@"heartbeat.plist"];
  NSString *catalog=[base stringByAppendingPathComponent:@"catalog.plist"];
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
  // Legacy slot-only choice remains readable, but is not an app identity and
  // cannot authorize reconnect to whichever native map happens to be open.
  assert(DFNativeMapChoiceBundle(DFNativeMapRememberedChoiceAtPath(choice))==nil);
  assert(DFNativeMapSaveChoiceForBundleAtPath(choice,1,@"com.waze.iphone"));
  assert([DFNativeMapChoiceBundle(DFNativeMapRememberedChoiceAtPath(choice))
          isEqual:@"com.waze.iphone"]);
  assert(!DFNativeMapSaveChoiceForBundleAtPath(choice,1,@"com.google.youtube"));
  assert([DFNativeMapChoiceBundle(DFNativeMapRememberedChoiceAtPath(choice))
          isEqual:@"com.waze.iphone"]);
  assert(!DFNativeMapValidSlotValue(@0.5));
  assert(!DFNativeMapValidSlotValue(@1.5));
  assert(!DFNativeMapValidSlotValue(@"1"));
  assert(!DFNativeMapValidSlotValue(@(NAN)));
  assert(!DFNativeMapValidSlotValue(@(INFINITY)));
  assert(DFNativeMapValidSlotValue(@0));
  assert(DFNativeMapValidSlotValue(@1));
  NSDictionary *fractional=@{@"Version":@1,@"Slot":@0.5,@"BundleID":@"com.google.Maps"};
  assert([fractional writeToFile:choice atomically:YES]);
  assert(DFNativeMapRememberedChoiceAtPath(choice)==nil);

  // Phone-host exclusion requires both a fresh owner lease and the exact
  // live CarPlay session. A remembered choice or inactive heartbeat cannot
  // reserve a phone app indefinitely.
  NSMutableDictionary *pulse=[@{@"Version":@1,@"Active":@YES,
      @"Session":session,@"Timestamp":@100} mutableCopy];
  assert([pulse writeToFile:heartbeat atomically:YES]);
  assert(DFNativeMapOwnsBundleAtPaths(lease,heartbeat,@"com.google.Maps",102));
  assert(!DFNativeMapOwnsBundleAtPaths(lease,heartbeat,@"com.google.Maps",102.001));
  assert(!DFNativeMapOwnsBundleAtPaths(lease,heartbeat,@"com.waze.iphone",101));
  assert(!DFNativeMapOwnsBundleAtPaths(lease,heartbeat,@"com.google.Maps",99));
  assert(!DFNativeMapOwnsBundleAtPaths(lease,heartbeat,@"com.google.Maps",NAN));
  pulse[@"Active"]=@NO;
  assert([pulse writeToFile:heartbeat atomically:YES]);
  assert(!DFNativeMapOwnsBundleAtPaths(lease,heartbeat,@"com.google.Maps",101));
  pulse[@"Active"]=@YES;pulse[@"Session"]=other;
  assert([pulse writeToFile:heartbeat atomically:YES]);
  assert(!DFNativeMapOwnsBundleAtPaths(lease,heartbeat,@"com.google.Maps",101));
  pulse[@"Session"]=session;pulse[@"Timestamp"]=@98;
  assert([pulse writeToFile:heartbeat atomically:YES]);
  assert(!DFNativeMapOwnsBundleAtPaths(lease,heartbeat,@"com.google.Maps",101));
  pulse[@"Timestamp"]=@102;
  assert([pulse writeToFile:heartbeat atomically:YES]);
  assert(!DFNativeMapOwnsBundleAtPaths(lease,heartbeat,@"com.google.Maps",101));
  // Keep the original 5s disconnect lease; the stricter live-host guard must
  // not prevent the unplug coordinator from snapshotting its verified owner.
  assert(DFNativeMapFreshLeaseAtPath(lease,session,105));
  DFNativeMapClearLeaseAtPathForSession(lease,other);
  assert(DFNativeMapFreshLeaseAtPath(lease,session,101));
  DFNativeMapClearLeaseAtPathForSession(lease,session);
  assert(DFNativeMapFreshLeaseAtPath(lease,session,101)==nil);

  NSDictionary *validCatalog=@{@"Version":@1,@"Bundles":
      @[@"com.google.Maps",@"com.waze.iphone",@"com.google.Maps"]};
  assert([validCatalog writeToFile:catalog atomically:YES]);
  assert([DFNativeMapCatalogBundlesAtPath(catalog)
      isEqual:(@[@"com.google.Maps",@"com.waze.iphone"])]);
  assert(([@{@"Version":@1,@"Bundles":@[@"com.google.Maps",@7]}
      writeToFile:catalog atomically:YES]));
  assert(DFNativeMapCatalogBundlesAtPath(catalog)==nil);
  [[NSFileManager defaultManager] removeItemAtPath:base error:nil];
  puts("PASS_MAP_LEASE_EXACT_SESSION_TTL_BUNDLE_SLOT_CHOICE_LIVE_OWNERSHIP");
 }
 return 0;
}
