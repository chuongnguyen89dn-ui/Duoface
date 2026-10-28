// Executable macOS Foundation/CoreGraphics harness for production .84 policy.
// Not a CarPlay hardware test; fake SpringBoard classes expose the same ABIs.
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <objc/runtime.h>
#import "../DFSceneOrientationPolicy.h"

void MSHookMessageEx(Class cls,SEL sel,IMP replacement,IMP *old) {
    *old=method_setImplementation(class_getInstanceMethod(cls,sel),replacement);
}
@interface SBDeviceApplicationSceneHandle : NSObject
@property(nonatomic) NSInteger originals;
- (BOOL)_mainSceneSupportsInterfaceOrientation:(NSInteger)value;
@end
@implementation SBDeviceApplicationSceneHandle
- (BOOL)_mainSceneSupportsInterfaceOrientation:(NSInteger)value {
    self.originals++;
    return value==3; // A deliberately different Apple-side policy.
}
@end
@interface SBDeviceApplicationSceneViewController : NSObject
@property(nonatomic) CGSize last2;
@property(nonatomic) CGSize last3;
@property(nonatomic) NSInteger lastContent;
@property(nonatomic) NSInteger lastContainer;
@property(nonatomic) NSInteger twoCalls;
@property(nonatomic) NSInteger threeCalls;
- (void)setContentReferenceSize:(CGSize)value withInterfaceOrientation:(NSInteger)o;
- (void)setContentReferenceSize:(CGSize)value withContentOrientation:(NSInteger)c andContainerOrientation:(NSInteger)o;
@end
@implementation SBDeviceApplicationSceneViewController
- (void)setContentReferenceSize:(CGSize)value withInterfaceOrientation:(NSInteger)o {
    self.last2=value;self.lastContent=o;self.twoCalls++;
}
- (void)setContentReferenceSize:(CGSize)value withContentOrientation:(NSInteger)c andContainerOrientation:(NSInteger)o {
    self.last3=value;self.lastContent=c;self.lastContainer=o;self.threeCalls++;
}
@end
int main(void) {
 @autoreleasepool {
    NSCAssert(DFSceneOrientationPolicyInstall(),@"real methods and hook");
    NSCAssert(DFSceneOrientationPolicyInstall(),@"idempotent");
    SBDeviceApplicationSceneHandle *mine=[SBDeviceApplicationSceneHandle new];
    SBDeviceApplicationSceneHandle *other=[SBDeviceApplicationSceneHandle new];
    SBDeviceApplicationSceneViewController *child=[SBDeviceApplicationSceneViewController new];
    SBDeviceApplicationSceneViewController *foreign=[SBDeviceApplicationSceneViewController new];
    __block CGSize size=CGSizeMake(1000,480);
    DFSceneOrientationPolicyRegister(mine,child,@"com.google.ios.youtube",^CGSize{return size;});
    NSCAssert([mine _mainSceneSupportsInterfaceOrientation:1],@"owned portrait accepted");
    NSCAssert(![mine _mainSceneSupportsInterfaceOrientation:3],@"owned landscape rejected");
    NSCAssert(mine.originals==0,@"no original for owned");
    NSCAssert([other _mainSceneSupportsInterfaceOrientation:3],@"foreign passthrough");
    NSCAssert(other.originals==1,@"foreign original once");
    [child setContentReferenceSize:CGSizeMake(5,5) withInterfaceOrientation:4];
    NSCAssert(CGSizeEqualToSize(child.last2,size),@"native renderer size broker");
    NSCAssert(child.lastContent==4 && child.twoCalls==1,@"preserved orientation ABI/once");
    [child setContentReferenceSize:CGSizeMake(1,2) withContentOrientation:3 andContainerOrientation:4];
    NSCAssert(CGSizeEqualToSize(child.last3,size),@"three-arg size broker");
    NSCAssert(child.lastContent==3 && child.lastContainer==4 && child.threeCalls==1,
              @"two original arguments preserved");
    [foreign setContentReferenceSize:CGSizeMake(11,12) withInterfaceOrientation:3];
    NSCAssert(CGSizeEqualToSize(foreign.last2,CGSizeMake(11,12)),@"foreign size unchanged");
    size=CGSizeZero;
    NSCAssert([mine _mainSceneSupportsInterfaceOrientation:3],@"stale owner forwarded");
    [child setContentReferenceSize:CGSizeMake(12,13) withInterfaceOrientation:2];
    NSCAssert(CGSizeEqualToSize(child.last2,CGSizeMake(12,13)),@"invalid size original");
    size=CGSizeMake(960,440);
    dispatch_semaphore_t done=dispatch_semaphore_create(0);
    [NSThread detachNewThreadWithBlock:^{
        @autoreleasepool {
            NSCAssert([mine _mainSceneSupportsInterfaceOrientation:3],@"off-main original");
            dispatch_semaphore_signal(done);
        }
    }];
    dispatch_semaphore_wait(done,DISPATCH_TIME_FOREVER);
    DFSceneOrientationPolicyUnregister(mine,child);
    NSCAssert([mine _mainSceneSupportsInterfaceOrientation:3],@"revoked original");
    [child setContentReferenceSize:CGSizeMake(15,16) withInterfaceOrientation:3];
    NSCAssert(CGSizeEqualToSize(child.last2,CGSizeMake(15,16)),@"revoked original size");
    DFSceneOrientationPolicyRegister(mine,child,@"com.apple.springboard",^CGSize{
      return CGSizeMake(1000,480);
    });
    NSCAssert([mine _mainSceneSupportsInterfaceOrientation:3],@"system bundle forbidden");
    NSLog(@"PASS .84 orientation: owner portrait, 2/3 size, ABI, stale, foreign, off-main, revoke");
 }
 return 0;
}
