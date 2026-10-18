// MyTweak 0.2 independent SpringBoard hook. Scene host is test-only.
#import <UIKit/UIKit.h>
#import "MTBridgeCoordinator.h"
#define MT_SHOW_LOAD_ALERT 0

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(2*NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [[MTBridgeCoordinator sharedCoordinator] start];
#if MT_SHOW_LOAD_ALERT
        UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"MyTweak"
             message:@"CarPlay coordinator loaded" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                     style:UIAlertActionStyleDefault handler:nil]];
        UIViewController *root=UIApplication.sharedApplication.keyWindow.rootViewController;
        [root presentViewController:alert animated:YES completion:nil];
#endif
    });
}
%end
