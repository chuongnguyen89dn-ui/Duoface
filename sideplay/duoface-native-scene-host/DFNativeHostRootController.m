// System-owned scene probe UI, NOT fake CarPlay chrome or a phone-app mirroring UI.
#import <UIKit/UIKit.h>
@interface DFNativeHostRootController : UIViewController
@property(nonatomic,assign) BOOL carPlay;
- (instancetype)initWithCarPlay:(BOOL)carPlay;
@end
@implementation DFNativeHostRootController
- (instancetype)initWithCarPlay:(BOOL)carPlay {
    if((self=[super initWithNibName:nil bundle:nil]))_carPlay=carPlay;
    return self;
}
- (void)loadView {
    UIView *v=[UIView new];
    v.backgroundColor=[UIColor colorWithWhite:0.10 alpha:1];
    self.view=v;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // This intentionally refuses to impersonate two running iPhone scenes.
    UILabel *label=[UILabel new];
    label.translatesAutoresizingMaskIntoConstraints=NO;
    label.numberOfLines=0;
    label.textAlignment=NSTextAlignmentCenter;
    label.textColor=UIColor.whiteColor;
    label.font=[UIFont systemFontOfSize:self.carPlay?20:18 weight:UIFontWeightMedium];
    label.text=self.carPlay?
      @"DuoFace Native Scene\nDashboard đã cấp cửa sổ CarPlay\nChưa nối hai ứng dụng iPhone":
      @"DuoFace Native Scene Host\nChờ Dashboard cấp CarPlay scene\nKhông có lệnh bật hoặc ẩn Dock";
    [self.view addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
      [label.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:16],
      [label.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-16],
      [label.centerXAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.centerXAnchor],
      [label.centerYAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.centerYAnchor]
    ]];
}
@end
