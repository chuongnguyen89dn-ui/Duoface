#import "MTAppLauncher.h"
#import "MTSceneHost.h"

@implementation MTAppSession
@end

@implementation MTAppLauncher

+ (instancetype)sharedLauncher {
    static MTAppLauncher *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (MTAppSession *)launchAppWithBundleID:(NSString *)bundleID
                                  error:(NSError **)error {
    if (bundleID.length == 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"MyTweak"
                                         code:-2
                                     userInfo:@{NSLocalizedDescriptionKey:
                                         @"bundleID rỗng"}];
        }
        return nil;
    }

    MTAppSession *session = [[MTAppSession alloc] init];
    session.bundleID = bundleID;

    // Nhờ MTSceneHost tạo view chứa scene của app.
    UIView *hosted = [[MTSceneHost sharedHost] hostViewForBundleID:bundleID
                                                            error:error];
    if (!hosted) {
        return nil; // error đã được MTSceneHost set
    }
    session.hostedView = hosted;
    NSLog(@"[MyTweakScene] event=scene-pending bundle=%@", bundleID);
    return session;
}

@end
