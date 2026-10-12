// Independent CarPlay dashboard proof-of-concept. Does not import DuoNavi binaries.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>

static UIWindow *DFWindow;
static UIView *DFPanel;

static void DFShow(void) {
    if (DFWindow) return;
    CGRect bounds = [UIScreen mainScreen].bounds;
    DFWindow = [[UIWindow alloc] initWithFrame:bounds];
    DFWindow.windowLevel = UIWindowLevelStatusBar + 10;
    DFWindow.backgroundColor = [UIColor clearColor];
    UIViewController *controller = [UIViewController new];
    controller.view.backgroundColor = [UIColor clearColor];
    DFWindow.rootViewController = controller;

    DFPanel = [[UIView alloc] initWithFrame:CGRectMake(20, 20, MIN(bounds.size.width-40, 340), 90)];
    DFPanel.backgroundColor = [UIColor colorWithRed:0.10 green:0.12 blue:0.16 alpha:0.94];
    DFPanel.layer.cornerRadius = 14;
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(14, 10, DFPanel.bounds.size.width-28, 35)];
    title.text = @"DuoFace CarPlay";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:22];
    [DFPanel addSubview:title];
    UILabel *subtitle = [[UILabel alloc] initWithFrame:CGRectMake(14, 48, DFPanel.bounds.size.width-28, 25)];
    subtitle.text = @"Standalone preview · no DuoNavi";
    subtitle.textColor = [UIColor lightGrayColor];
    subtitle.font = [UIFont systemFontOfSize:13];
    [DFPanel addSubview:subtitle];
    [controller.view addSubview:DFPanel];
    DFWindow.hidden = NO;
}

__attribute__((constructor))
static void DFStart(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        DFShow();
    });
}
