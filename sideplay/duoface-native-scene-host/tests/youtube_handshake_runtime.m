#import <Foundation/Foundation.h>
#import "DFYouTubeHostState.h"
#include <assert.h>

static NSInteger received;
static NSUInteger calls;
@interface YTLongWindow : NSObject
- (void)_rotateWindowToOrientation:(NSInteger)value updateStatusBar:(BOOL)status duration:(double)duration skipCallbacks:(BOOL)skip;
@end
@implementation YTLongWindow
- (void)_rotateWindowToOrientation:(NSInteger)value updateStatusBar:(BOOL)status duration:(double)duration skipCallbacks:(BOOL)skip {
    assert(!status && duration==0.0 && !skip); received=value; ++calls;
}
@end
@interface YTIntWindow : NSObject
- (void)_rotateWindowToOrientation:(int)value updateStatusBar:(BOOL)status duration:(double)duration skipCallbacks:(BOOL)skip;
@end
@implementation YTIntWindow
- (void)_rotateWindowToOrientation:(int)value updateStatusBar:(BOOL)status duration:(double)duration skipCallbacks:(BOOL)skip {
    assert(!status && duration==0.0 && !skip); received=value; ++calls;
}
@end
@interface YTBadWindow : NSObject
- (void)_rotateWindowToOrientation:(id)value updateStatusBar:(BOOL)status duration:(float)duration skipCallbacks:(BOOL)skip;
@end
@implementation YTBadWindow
- (void)_rotateWindowToOrientation:(id)value updateStatusBar:(BOOL)status duration:(float)duration skipCallbacks:(BOOL)skip {
    (void)value;(void)status;(void)duration;(void)skip; assert(0);
}
@end
int main(void) {
 @autoreleasepool {
    NSDictionary *current=@{@"version":@1,@"bundleIdentifier":DFYTBundle,@"owner":@"generation-A",
       @"sceneIdentifier":@"scene-youtube",@"issuedAt":@1000,@"active":@YES,
       @"width":@854,@"height":@480,@"orientation":@1};
    assert(DFYTValidState(current,1000)); assert(DFYTValidState(current,1003));
    assert(!DFYTValidState(current,1003.001)); assert(!DFYTValidState(current,999));
    assert(!DFYTValidState(current,NAN));
    for(NSString *key in current) {
        NSMutableDictionary *bad=[current mutableCopy];[bad removeObjectForKey:key];
        assert(!DFYTValidState(bad,1000));
    }
    for(NSString *key in @[@"width",@"height",@"orientation",@"issuedAt",@"active"]) {
        NSMutableDictionary *bad=[current mutableCopy];bad[key]=@"1";
        assert(!DFYTValidState(bad,1000)); bad[key]=@(NAN);assert(!DFYTValidState(bad,1000));
    }
    for(NSNumber *value in @[@0,@63,@8193,@(-1)]) {
        NSMutableDictionary *bad=[current mutableCopy];bad[@"width"]=value;
        assert(!DFYTValidState(bad,1000));
    }
    for(NSNumber *value in @[@0,@2,@3,@4]) {
        NSMutableDictionary *bad=[current mutableCopy];bad[@"orientation"]=value;
        assert(!DFYTValidState(bad,1000));
    }
    NSMutableDictionary *next=[current mutableCopy]; next[@"bundleIdentifier"]=@"com.google.Maps";
    assert(!DFYTValidState(next,1000));
    next=[current mutableCopy];next[@"issuedAt"]=@1001;
    assert(DFYTShouldAccept(next,current,1001,1000));
    assert(!DFYTShouldAccept(current,next,1001,1001)); // replay
    next[@"active"]=@NO;assert(DFYTShouldAccept(next,current,1001,1000));
    next[@"owner"]=@"old-owner";assert(!DFYTShouldAccept(next,current,1001,1000));
    next[@"owner"]=current[@"owner"];next[@"sceneIdentifier"]=@"other-scene";
    assert(!DFYTShouldAccept(next,current,1001,1000));
    next[@"active"]=@YES;assert(DFYTShouldAccept(next,current,1001,1000)); // new owner
    assert(DFYTRotate([YTLongWindow new],1));assert(received==1 && calls==1);
    assert(DFYTRotate([YTIntWindow new],4));assert(received==4 && calls==2);
    assert(!DFYTRotate([YTBadWindow new],1));assert(calls==2);
    assert(!DFYTRotate([NSObject new],1));assert(calls==2);
    puts("YOUTUBE_HANDSHAKE_LEASE_REPLAY_REVOKE_ABI_PASS (not device rotation proof)");
 }
 return 0;
}
