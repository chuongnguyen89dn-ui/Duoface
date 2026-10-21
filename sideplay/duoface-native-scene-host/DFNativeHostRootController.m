// Independent DuoFace iPhone landing screen and CarPlay scene status.
// Native12 visual proportions are reconstructed from project-approved artwork.
// No licensed bridge classes, vendor binaries or service access.
#import <UIKit/UIKit.h>
@interface DFNativeHostSurfaceView : UIView
- (void)start;
- (void)stop;
@end
@interface DFNativeHostRootController : UIViewController
@property(nonatomic,assign) BOOL carPlay;
@property(nonatomic,strong) DFNativeHostSurfaceView *nativeSurface;
@property(nonatomic,strong) UIView *mainContent;
@property(nonatomic,strong) UILabel *stateLabel;
@property(nonatomic,strong) UIImageView *mainLogo;
@property(nonatomic,strong) UISegmentedControl *tabs;
- (instancetype)initWithCarPlay:(BOOL)carPlay;
@end
@implementation DFNativeHostRootController
- (instancetype)initWithCarPlay:(BOOL)carPlay {
    if((self=[super initWithNibName:nil bundle:nil]))_carPlay=carPlay;
    return self;
}
- (UIImage *)art:(NSString *)name {
    return [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]
                 pathForResource:name ofType:@"png" inDirectory:@"VisualAssets"]];
}
- (UILabel *)label:(NSString *)content size:(CGFloat)size color:(UIColor *)color {
    UILabel *l=[UILabel new];l.translatesAutoresizingMaskIntoConstraints=NO;
    l.numberOfLines=0;l.text=content;l.textAlignment=NSTextAlignmentCenter;
    l.textColor=color;l.font=[UIFont systemFontOfSize:size weight:UIFontWeightMedium];
    return l;
}
- (void)loadView {
    UIView *v=[UIView new];
    v.backgroundColor=UIColor.blackColor;
    self.view=v;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    if(self.carPlay){
        // The alternate UIKit CarPlay role never creates a phone-style
        // settings panel, system Dock or a second overlay controller.
        UILabel *state=[self label:@"DuoFace\nNative12 · CarPlay\nChưa nối hai ứng dụng iPhone"
                             size:19 color:UIColor.whiteColor];
        [self.view addSubview:state];
        [NSLayoutConstraint activateConstraints:@[
            [state.centerXAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.centerXAnchor],
            [state.centerYAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.centerYAnchor],
            [state.widthAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.widthAnchor multiplier:.86]
        ]];
        self.nativeSurface=[DFNativeHostSurfaceView new];
        self.nativeSurface.translatesAutoresizingMaskIntoConstraints=NO;
        [self.view addSubview:self.nativeSurface];
        [NSLayoutConstraint activateConstraints:@[
            [self.nativeSurface.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
            [self.nativeSurface.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
            [self.nativeSurface.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
            [self.nativeSurface.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
        ]];
        return;
    }
    UIScrollView *scroll=[UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints=NO;
    scroll.backgroundColor=UIColor.blackColor;
    [self.view addSubview:scroll];
    [NSLayoutConstraint activateConstraints:@[
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];
    UIView *body=[UIView new];
    body.translatesAutoresizingMaskIntoConstraints=NO;
    [scroll addSubview:body];
    [NSLayoutConstraint activateConstraints:@[
        [body.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor],
        [body.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor],
        [body.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor],
        [body.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor],
        [body.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor]
    ]];
    UIImageView *logo=[[UIImageView alloc]initWithImage:[self art:@"duoface-logo"]];
    logo.translatesAutoresizingMaskIntoConstraints=NO;
    logo.contentMode=UIViewContentModeScaleAspectFit;
    [body addSubview:logo];self.mainLogo=logo;
    UILabel *tagline=[self label:@"TWO FACES. ONE SCREEN."
                               size:12 color:[UIColor colorWithWhite:.8 alpha:1]];
    [body addSubview:tagline];
    UISegmentedControl *tabs=[[UISegmentedControl alloc]
                initWithItems:@[@"Trang chủ",@"Ứng dụng",@"Cài đặt"]];
    tabs.translatesAutoresizingMaskIntoConstraints=NO;
    tabs.selectedSegmentIndex=0;
    tabs.selectedSegmentTintColor=[UIColor colorWithRed:.82 green:.02 blue:.08 alpha:1];
    [tabs setTitleTextAttributes:@{NSForegroundColorAttributeName:UIColor.whiteColor}
                       forState:UIControlStateSelected];
    [tabs addTarget:self action:@selector(tabChanged:) forControlEvents:UIControlEventValueChanged];
    [body addSubview:tabs];self.tabs=tabs;
    UIView *card=[UIView new];
    card.translatesAutoresizingMaskIntoConstraints=NO;
    card.backgroundColor=[UIColor colorWithWhite:.09 alpha:1];
    card.layer.cornerRadius=20;card.layer.borderColor=[UIColor colorWithWhite:1 alpha:.17].CGColor;
    card.layer.borderWidth=.5;[body addSubview:card];self.mainContent=card;
    UIView *paneA=[UIView new],*paneB=[UIView new];
    for(UIView *pane in @[paneA,paneB]){
        pane.translatesAutoresizingMaskIntoConstraints=NO;
        pane.layer.cornerRadius=10;
        pane.backgroundColor=[UIColor colorWithRed:.08 green:.15 blue:.19 alpha:1];
        [card addSubview:pane];
    }
    UILabel *a=[self label:@"APP 1" size:12 color:UIColor.whiteColor];
    UILabel *b=[self label:@"APP 2" size:12 color:UIColor.whiteColor];
    [paneA addSubview:a];[paneB addSubview:b];
    UILabel *bar=[self label:@"⇄" size:26 color:UIColor.whiteColor];
    bar.backgroundColor=[UIColor colorWithWhite:.22 alpha:1];
    bar.layer.cornerRadius=15;bar.layer.masksToBounds=YES;
    [card addSubview:bar];
    UILabel *state=[self label:@"DuoFace Native12\nCarPlay: chờ kết nối\nChưa nối ứng dụng iPhone"
                            size:14 color:[UIColor colorWithWhite:.8 alpha:1]];
    [body addSubview:state];self.stateLabel=state;
    UILabel *note=[self label:@"App · Zoom · Style · Close\nĐược điều khiển trực tiếp trên màn hình CarPlay."
                           size:12 color:[UIColor colorWithWhite:.63 alpha:1]];
    [body addSubview:note];
    [NSLayoutConstraint activateConstraints:@[
        [logo.topAnchor constraintEqualToAnchor:body.topAnchor constant:26],
        [logo.centerXAnchor constraintEqualToAnchor:body.centerXAnchor],
        [logo.widthAnchor constraintLessThanOrEqualToAnchor:body.widthAnchor multiplier:.85],
        [logo.widthAnchor constraintEqualToConstant:MIN(328,UIScreen.mainScreen.bounds.size.width*.82)],
        [logo.heightAnchor constraintEqualToConstant:82],
        [tagline.topAnchor constraintEqualToAnchor:logo.bottomAnchor constant:1],
        [tagline.centerXAnchor constraintEqualToAnchor:body.centerXAnchor],
        [tabs.topAnchor constraintEqualToAnchor:tagline.bottomAnchor constant:30],
        [tabs.leadingAnchor constraintEqualToAnchor:body.leadingAnchor constant:22],
        [tabs.trailingAnchor constraintEqualToAnchor:body.trailingAnchor constant:-22],
        [tabs.heightAnchor constraintEqualToConstant:38],
        [card.topAnchor constraintEqualToAnchor:tabs.bottomAnchor constant:20],
        [card.leadingAnchor constraintEqualToAnchor:body.leadingAnchor constant:22],
        [card.trailingAnchor constraintEqualToAnchor:body.trailingAnchor constant:-22],
        [card.heightAnchor constraintEqualToConstant:192],
        [paneA.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:8],
        [paneA.topAnchor constraintEqualToAnchor:card.topAnchor constant:8],
        [paneA.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-8],
        [paneA.trailingAnchor constraintEqualToAnchor:card.centerXAnchor constant:-2],
        [paneB.leadingAnchor constraintEqualToAnchor:card.centerXAnchor constant:2],
        [paneB.topAnchor constraintEqualToAnchor:card.topAnchor constant:8],
        [paneB.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-8],
        [paneB.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-8],
        [a.centerXAnchor constraintEqualToAnchor:paneA.centerXAnchor],
        [a.centerYAnchor constraintEqualToAnchor:paneA.centerYAnchor],
        [b.centerXAnchor constraintEqualToAnchor:paneB.centerXAnchor],
        [b.centerYAnchor constraintEqualToAnchor:paneB.centerYAnchor],
        [bar.widthAnchor constraintEqualToConstant:30],
        [bar.heightAnchor constraintEqualToConstant:30],
        [bar.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [bar.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
        [state.topAnchor constraintEqualToAnchor:card.bottomAnchor constant:22],
        [state.leadingAnchor constraintEqualToAnchor:body.leadingAnchor constant:25],
        [state.trailingAnchor constraintEqualToAnchor:body.trailingAnchor constant:-25],
        [note.topAnchor constraintEqualToAnchor:state.bottomAnchor constant:20],
        [note.leadingAnchor constraintEqualToAnchor:body.leadingAnchor constant:22],
        [note.trailingAnchor constraintEqualToAnchor:body.trailingAnchor constant:-22],
        [note.bottomAnchor constraintEqualToAnchor:body.bottomAnchor constant:-28]
    ]];
}
- (void)tabChanged:(UISegmentedControl *)tabs {
    switch(tabs.selectedSegmentIndex){
      case 0:self.stateLabel.text=@"DuoFace Native12\nCarPlay: chờ kết nối\nChưa nối ứng dụng iPhone";break;
      case 1:self.stateLabel.text=@"Ứng dụng\nDanh sách và bộ host app iPhone: chưa tích hợp";break;
      case 2:self.stateLabel.text=@"Cài đặt\nGiao diện: Native12 độc lập\nKết nối: CarPlay jailbreak";break;
    }
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if(self.carPlay)[self.nativeSurface start];
}
- (void)viewWillDisappear:(BOOL)animated {
    [self.nativeSurface stop];
    [super viewWillDisappear:animated];
}
@end
