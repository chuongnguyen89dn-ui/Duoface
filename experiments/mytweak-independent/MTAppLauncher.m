#import "MTAppLauncher.h"
#import "MTSceneHost.h"
@implementation MTAppSession
@end
@implementation MTAppLauncher
+ (instancetype)sharedLauncher {
    static MTAppLauncher *shared=nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ shared=[MTAppLauncher new]; });
    return shared;
}
- (MTAppSession *)launchAppWithBundleID:(NSString *)bundleID error:(NSError **)error {
    if (![bundleID isKindOfClass:NSString.class] || !bundleID.length) {
        if (error) *error=[NSError errorWithDomain:@"MyTweak" code:-2
                userInfo:@{NSLocalizedDescriptionKey:@"bundleID rỗng"}];
        return nil;
    }
    UIView *hosted=[[MTSceneHost sharedHost] hostViewForBundleID:bundleID error:error];
    if (!hosted) return nil;
    MTAppSession *session=[MTAppSession new];
    session.bundleID=bundleID;
    session.hostedView=hosted;
    // A host surface is pending; a scene must attach asynchronously.
    NSLog(@"[MyTweakScene] event=scene-pending bundle=%@",bundleID);
    return session;
}
@end
