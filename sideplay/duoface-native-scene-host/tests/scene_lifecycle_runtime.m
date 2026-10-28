// Executable Foundation harness: runs the production boundary on a fake FBScene.
// macOS unit coverage, not an iPhone/SpringBoard integration test.
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "../DFSceneLifecycle.h"

void MSHookMessageEx(Class cls, SEL sel, IMP replacement, IMP *original) {
    *original=method_setImplementation(class_getInstanceMethod(cls,sel),replacement);
}
@interface TestSettings : NSObject <NSMutableCopying>
@property(nonatomic) BOOL foreground;
@property(nonatomic) NSInteger untouched;
@end
@implementation TestSettings
- (id)mutableCopyWithZone:(NSZone *)zone {
    TestSettings *copy=[[[self class] allocWithZone:zone] init];
    copy.foreground=self.foreground;copy.untouched=self.untouched;return copy;
}
@end
@interface BrokenSettings : TestSettings
@end
@implementation BrokenSettings
- (id)mutableCopyWithZone:(NSZone *)zone {
    (void)zone;[NSException raise:@"PreparationError" format:@"test"];return nil;
}
@end
@interface FBScene : NSObject
@property(nonatomic,strong) id received;
@property(nonatomic,strong) id context;
@property(nonatomic) NSUInteger calls;
@property(nonatomic) BOOL throws;
- (void)updateSettings:(id)settings withTransitionContext:(id)context completion:(id)completion;
@end
@implementation FBScene
- (void)updateSettings:(id)settings withTransitionContext:(id)context completion:(id)completion {
    self.calls++;self.received=settings;self.context=context;
    if(self.throws)[NSException raise:@"OriginalError" format:@"must escape"];
    if(completion)((void(^)(void))completion)();
}
@end
// iOS16 SpringBoard observer model. The original method must be called
// exactly once for foreign, stale, closing and automatic-lifecycle controllers.
@interface TestSceneHandle : NSObject
@property(nonatomic,strong) id currentScene;
- (id)sceneIfExists;
@end
@implementation TestSceneHandle
- (id)sceneIfExists { return self.currentScene; }
@end
@interface SBAppViewController : NSObject
@property(nonatomic,strong) TestSceneHandle *sceneHandle;
@property(nonatomic) BOOL automatesLifecycle;
@property(nonatomic) NSUInteger originalObserverCalls;
@property(nonatomic) BOOL observerThrows;
- (void)sceneHandle:(id)handle didUpdateSettingsWithDiff:(id)diff previousSettings:(id)settings;
@end
@implementation SBAppViewController
- (void)sceneHandle:(id)handle didUpdateSettingsWithDiff:(id)diff previousSettings:(id)settings {
    (void)handle;(void)diff;(void)settings;
    self.originalObserverCalls++;
    if(self.observerThrows)[NSException raise:@"AppleObserverFailure" format:@"must escape"];
}
@end
int main(void) {
 @autoreleasepool {
    NSCAssert(DFSceneLifecycleInstall(),@"install");
    NSCAssert(DFSceneLifecycleInstall(),@"idempotent install");
    NSObject *owner=[NSObject new],*context=[NSObject new];
    FBScene *scene=[FBScene new],*foreign=[FBScene new];
    __block id active=scene;
    DFSceneLifecycleRegister(owner,^id{return active;});
    TestSettings *input=[TestSettings new];input.foreground=NO;input.untouched=42;
    __block NSUInteger completions=0;
    void (^done)(void)=^{completions++;};
    [scene updateSettings:input withTransitionContext:context completion:done];
    NSCAssert(scene.calls==1 && completions==1,@"exactly once");
    NSCAssert(scene.context==context,@"context identity");
    NSCAssert(scene.received!=input && !input.foreground,@"no caller mutation");
    NSCAssert([scene.received foreground] && [scene.received untouched]==42,@"copy policy");
    [foreign updateSettings:input withTransitionContext:context completion:done];
    NSCAssert(foreign.received==input && foreign.calls==1,@"nonowner pass through");
    active=foreign;
    [scene updateSettings:input withTransitionContext:context completion:done];
    NSCAssert(scene.received==input,@"stale scene pass through");
    active=scene;
    input.foreground=YES;
    [scene updateSettings:input withTransitionContext:nil completion:nil];
    NSCAssert(scene.received==input && scene.context==nil,@"unchanged/nil context");
    input.foreground=NO;
    [scene updateSettings:[BrokenSettings new] withTransitionContext:context completion:done];
    NSCAssert([scene.received isKindOfClass:BrokenSettings.class],@"preparation fallback");
    [scene updateSettings:nil withTransitionContext:context completion:done];
    NSCAssert(scene.received==nil,@"unknown settings pass through");
    // A background callback must never consult UIKit ownership probes.
    dispatch_semaphore_t finished=dispatch_semaphore_create(0);
    [NSThread detachNewThreadWithBlock:^{
        @autoreleasepool {
            [scene updateSettings:input withTransitionContext:context completion:nil];
            NSCAssert(scene.received==input,@"off-main pass through");
            dispatch_semaphore_signal(finished);
        }
    }];
    dispatch_semaphore_wait(finished,DISPATCH_TIME_FOREVER);
    scene.throws=YES;BOOL escaped=NO;
    @try {[scene updateSettings:input withTransitionContext:context completion:nil];}
    @catch(NSException *e){escaped=[e.name isEqualToString:@"OriginalError"];}
    NSCAssert(escaped,@"original exception must not be swallowed");scene.throws=NO;
    DFSceneLifecycleUnregister(owner);
    [scene updateSettings:input withTransitionContext:context completion:done];
    NSCAssert(scene.received==input,@"close/background allowed after revoke");
    @autoreleasepool {
        NSObject *temporaryOwner=[NSObject new];
        DFSceneLifecycleRegister(temporaryOwner,^id{return scene;});
    }
    [scene updateSettings:input withTransitionContext:context completion:nil];
    NSCAssert(scene.received==input,@"weak owner expiry");
    // Exact ABI/ownership contract of the 0.83 manual-lifecycle observer:
    // only a registered, currently attached manual controller can consume it.
    SBAppViewController *ctl=[SBAppViewController new];
    ctl.automatesLifecycle=NO;
    TestSceneHandle *handle=[TestSceneHandle new];
    handle.currentScene=scene;ctl.sceneHandle=handle;
    DFSceneLifecycleRegister(ctl,^id{return scene;});
    [ctl sceneHandle:handle didUpdateSettingsWithDiff:input previousSettings:nil];
    NSCAssert(ctl.originalObserverCalls==0,@"owned manual observer consumed");
    // Nonowned (and unknown controller) MUST follow original SpringBoard.
    SBAppViewController *foreignCtl=[SBAppViewController new];
    foreignCtl.automatesLifecycle=NO;foreignCtl.sceneHandle=handle;
    [foreignCtl sceneHandle:handle didUpdateSettingsWithDiff:input previousSettings:nil];
    NSCAssert(foreignCtl.originalObserverCalls==1,@"foreign manual controller forwards");
    // Automatic lifecycle is never suppressed even for a registered owner.
    ctl.automatesLifecycle=YES;
    [ctl sceneHandle:handle didUpdateSettingsWithDiff:input previousSettings:nil];
    NSCAssert(ctl.originalObserverCalls==1,@"automatic lifecycle forwards");
    ctl.automatesLifecycle=NO;
    TestSceneHandle *replacement=[TestSceneHandle new];
    replacement.currentScene=foreign;ctl.sceneHandle=replacement;
    [ctl sceneHandle:handle didUpdateSettingsWithDiff:input previousSettings:nil];
    NSCAssert(ctl.originalObserverCalls==2,@"stale handle forwards");
    [ctl sceneHandle:replacement didUpdateSettingsWithDiff:input previousSettings:nil];
    NSCAssert(ctl.originalObserverCalls==3,@"replacement scene forwards");
    ctl.sceneHandle=handle;
    DFSceneLifecycleUnregister(ctl);
    [ctl sceneHandle:handle didUpdateSettingsWithDiff:input previousSettings:nil];
    NSCAssert(ctl.originalObserverCalls==4,@"close unregister forwards");
    ctl.observerThrows=YES;BOOL threw=NO;
    @try {[ctl sceneHandle:handle didUpdateSettingsWithDiff:input previousSettings:nil];}
    @catch(NSException *e){threw=[e.name isEqualToString:@"AppleObserverFailure"];}
    NSCAssert(threw,@"original observer exception must escape");ctl.observerThrows=NO;
    NSLog(@"PASS lifecycle runtime: owned manual observer isolated, foreign/stale/replaced/automatic/revoked forwarded and original failure preserved");
    NSLog(@"PASS lifecycle runtime: copy, nonowner, stale, revoke, context, once, unknown, errors");
 }
 return 0;
}
