#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <notify.h>

#define DFIStartNotification "com.duoface.visual12.start"
#define DFIStopNotification "com.duoface.visual12.stop"
#define DFIPreferences @"com.duoface.visual12"

@interface DFV12SceneHost : NSObject
@property(nonatomic,copy,readonly) NSString *bundleID;
@property(nonatomic,strong,readonly) UIViewController *controller;
@property(nonatomic,strong,readonly) id scene;
@property(nonatomic,copy) void (^failure)(NSString *message);
- (instancetype)initWithBundleID:(NSString *)bundleID error:(NSError **)error;
- (void)attachTo:(UIViewController *)parent container:(UIView *)container;
- (void)resizeTo:(CGSize)size;
- (void)close;
@end

@interface DFV12SplitController : UIViewController
- (void)shutdown;
@end

void DFV12InstallRuntime(void);
