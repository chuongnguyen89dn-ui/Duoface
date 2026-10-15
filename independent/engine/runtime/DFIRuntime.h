#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <notify.h>

#define DFIStartNotification "com.duoface.independent.start"
#define DFIStopNotification "com.duoface.independent.stop"
#define DFIPreferences @"com.duoface.independent"

@interface DFISceneHost : NSObject
@property(nonatomic,copy,readonly) NSString *bundleID;
@property(nonatomic,strong,readonly) UIViewController *controller;
@property(nonatomic,strong,readonly) id scene;
@property(nonatomic,copy) void (^failure)(NSString *message);
- (instancetype)initWithBundleID:(NSString *)bundleID error:(NSError **)error;
- (void)attachTo:(UIViewController *)parent container:(UIView *)container;
- (void)resizeTo:(CGSize)size;
- (void)close;
@end

@interface DFISplitController : UIViewController
- (void)shutdown;
@end

void DFIInstallRuntime(void);
