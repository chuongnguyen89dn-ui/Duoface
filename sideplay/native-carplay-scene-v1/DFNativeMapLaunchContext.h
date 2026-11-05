// First-party context shared by the existing CarPlay Dock owner and map
// coordinator. Weak identities do not extend the lifetime of native objects.
#ifndef DF_NATIVE_MAP_LAUNCH_CONTEXT_H
#define DF_NATIVE_MAP_LAUNCH_CONTEXT_H
#import <Foundation/Foundation.h>
#include <stdint.h>

@protocol DFNativeMapLaunchContextIdentity <NSObject>
@property(nonatomic,weak,readonly) id dashboard;
@property(nonatomic,weak,readonly) id workspace;
@property(nonatomic,weak,readonly) id owner;
@property(nonatomic,weak,readonly) id root;
@property(nonatomic,weak,readonly) id window;
@property(nonatomic,weak,readonly) id screen;
@property(nonatomic,readonly) uint64_t homeGeneration;
@property(nonatomic,readonly) BOOL homeHooksReady;
@property(nonatomic,copy,readonly) NSString *physicalSession;
@end

// Implemented exactly once, in the already installed Dock/Home dylib. The
// coordinator uses this type without importing an Objective-C class symbol.
@interface DFNativeMapLaunchContext : NSObject <DFNativeMapLaunchContextIdentity>
@property(nonatomic,weak) id dashboard;
@property(nonatomic,weak) id workspace;
@property(nonatomic,weak) id owner;
@property(nonatomic,weak) id root;
@property(nonatomic,weak) id window;
@property(nonatomic,weak) id screen;
@property(nonatomic,assign) uint64_t homeGeneration;
@property(nonatomic,assign) BOOL homeHooksReady;
@property(nonatomic,copy) NSString *physicalSession;
// A pre-dispatch observation only. It is intentionally excluded from stable
// context identity: opening the selected native map may replace the base.
@property(nonatomic,weak) id ownedBase;
@property(nonatomic,copy) NSString *requestID;
@end

// These getters belong to our own context objects, not untyped private OS
// receivers. Both the pending policy and the dispatcher use this predicate.
NS_INLINE BOOL DFNativeMapLaunchContextsMatch(
 id<DFNativeMapLaunchContextIdentity> expected,
 id<DFNativeMapLaunchContextIdentity> actual) {
 if(!expected || !actual)return NO;
 @try {
  if(!expected.homeHooksReady || !actual.homeHooksReady ||
     !expected.homeGeneration ||
     expected.homeGeneration!=actual.homeGeneration)return NO;
  NSString *session=expected.physicalSession;
  if(![session isKindOfClass:NSString.class] ||
     ![[NSUUID alloc]initWithUUIDString:session] ||
     ![session isEqual:actual.physicalSession])return NO;
  id dashboard=expected.dashboard,workspace=expected.workspace,owner=expected.owner;
  id root=expected.root,window=expected.window,screen=expected.screen;
  return dashboard && workspace && owner && root && window && screen &&
      dashboard==actual.dashboard && workspace==actual.workspace &&
      owner==actual.owner && root==actual.root && window==actual.window &&
      screen==actual.screen;
 } @catch(__unused NSException *exception){return NO;}
}

typedef DFNativeMapLaunchContext *(*DFNativeMapLaunchContextProvider)(
 id expectedRoot,id expectedWindow,NSString *requestID,NSString **reason);
#define DF_NATIVE_MAP_LAUNCH_CONTEXT_SYMBOL "DFNativeMapReadLaunchContextV1"
#define DF_NATIVE_MAP_HOME_GENERATION_SYMBOL "DFNativeMapReadHomeGenerationV1"

// Called through the versioned first-party C symbol; no synthetic workspace
// and no direct link from the map dylib to another injected dylib.
FOUNDATION_EXPORT DFNativeMapLaunchContext *DFNativeMapReadLaunchContextV1(
 id expectedRoot,id expectedWindow,NSString *requestID,NSString **reason);
// Main-thread-only pure read, performed after all native getter calls. This
// catches a real Home callback even when its later revoke-file write fails.
FOUNDATION_EXPORT uint64_t DFNativeMapReadHomeGenerationV1(void);
#endif
