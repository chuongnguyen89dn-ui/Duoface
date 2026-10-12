#import <UIKit/UIKit.h>
#import <dispatch/dispatch.h>
static UIWindow *previewWindow;
__attribute__((constructor)) static void startPreview(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        window.windowLevel = UIWindowLevelStatusBar + 1;
        UIViewController *controller = [UIViewController new];
        controller.view.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.92];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16, 24, 350, 80)];
        label.text = @"DuoFace standalone CarPlay preview";
        label.textColor = [UIColor whiteColor];
        [controller.view addSubview:label];
        window.rootViewController = controller;
        previewWindow = window;
        window.hidden = NO;
    });
}
