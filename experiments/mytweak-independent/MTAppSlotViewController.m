#import "MTAppSlotViewController.h"
#import "MTAppLauncher.h"
#import "MTSceneHost.h"

@interface MTAppSlotViewController ()
@property(nonatomic,strong) UIView *topBar;
@property(nonatomic,strong) UILabel *titleLabel;
@property(nonatomic,strong) UIButton *pickButton;
@property(nonatomic,strong) UIView *contentView;
@property(nonatomic,strong) UILabel *placeholderLabel;
@property(nonatomic,strong,nullable) MTAppSession *session;
@end

@implementation MTAppSlotViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=[UIColor colorWithWhite:0.08 alpha:1.0];
    self.topBar=[UIView new];
    self.topBar.backgroundColor=[UIColor colorWithWhite:0.15 alpha:0.95];
    [self.view addSubview:self.topBar];
    self.titleLabel=[UILabel new];
    self.titleLabel.textColor=UIColor.whiteColor;
    self.titleLabel.font=[UIFont boldSystemFontOfSize:15];
    [self.topBar addSubview:self.titleLabel];
    self.pickButton=[UIButton buttonWithType:UIButtonTypeSystem];
    [self.pickButton setTitle:@"Chọn app" forState:UIControlStateNormal];
    [self.pickButton addTarget:self action:@selector(pickButtonTapped)
              forControlEvents:UIControlEventTouchUpInside];
    [self.topBar addSubview:self.pickButton];
    self.contentView=[UIView new];
    self.contentView.backgroundColor=UIColor.clearColor;
    [self.view addSubview:self.contentView];
    self.placeholderLabel=[UILabel new];
    self.placeholderLabel.textColor=UIColor.lightGrayColor;
    self.placeholderLabel.font=[UIFont systemFontOfSize:16];
    self.placeholderLabel.textAlignment=NSTextAlignmentCenter;
    self.placeholderLabel.numberOfLines=0;
    [self.contentView addSubview:self.placeholderLabel];
    UITapGestureRecognizer *doubleTap=[[UITapGestureRecognizer alloc]
            initWithTarget:self action:@selector(contentDoubleTapped)];
    doubleTap.numberOfTapsRequired=2;
    [self.contentView addGestureRecognizer:doubleTap];
    [NSNotificationCenter.defaultCenter addObserver:self
             selector:@selector(sceneHostDidFail:)
                 name:MTSceneHostDidFailNotification object:nil];
    [self clearSlot];
}
- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }
- (void)sceneHostDidFail:(NSNotification *)notification {
    if (notification.object != self.session.hostedView) return;
    NSError *error=notification.userInfo[@"error"];
    [self showLaunchError:error ?: [NSError errorWithDomain:@"com.mytweak.scene"
                                 code:114 userInfo:nil]];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w=self.view.bounds.size.width, h=self.view.bounds.size.height;
    self.topBar.frame=CGRectMake(0,0,w,44);
    self.titleLabel.frame=CGRectMake(12,0,w-120,44);
    self.pickButton.frame=CGRectMake(w-100,0,100,44);
    self.contentView.frame=CGRectMake(0,44,w,h-44);
    self.placeholderLabel.frame=self.contentView.bounds;
    for (UIView *view in self.contentView.subviews)
        if (view!=self.placeholderLabel) view.frame=self.contentView.bounds;
}
- (void)pickButtonTapped { [self.delegate slotDidRequestAppPicker:self]; }
- (void)contentDoubleTapped { [self.delegate slotDidDoubleTap:self]; }
- (NSString *)slotName { return self.slotIndex==0?@"Slot trái":@"Slot phải"; }
- (void)setSession:(MTAppSession *)session {
    _session=session;
    self.titleLabel.text=session.displayName?:session.bundleID;
    [self clearContentKeepTitle];
    if (session.hostedView) {
        session.hostedView.frame=self.contentView.bounds;
        session.hostedView.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:session.hostedView];
    } else {
        self.placeholderLabel.hidden=NO;
        self.placeholderLabel.text=[NSString stringWithFormat:
          @"%@\n\nĐã chọn nhưng chưa host được scene.",session.displayName?:session.bundleID];
    }
}
- (void)showLaunchError:(NSError *)error {
    _session=nil;
    self.titleLabel.text=[self slotName];
    [self clearContentKeepTitle];
    self.placeholderLabel.hidden=NO;
    self.placeholderLabel.text=[NSString stringWithFormat:
        @"Không mở được app:\n%@",error.localizedDescription?:@"Không rõ lỗi"];
    NSLog(@"[MyTweakScene] event=slot-error slot=%ld reason=%@",
          (long)self.slotIndex,error.localizedDescription);
}
- (void)clearSlot {
    _session=nil;
    self.titleLabel.text=[self slotName];
    [self clearContentKeepTitle];
    self.placeholderLabel.hidden=NO;
    self.placeholderLabel.text=@"Slot trống\n\nNhấn Chọn app ở trên";
}
- (void)clearContentKeepTitle {
    for (UIView *view in [self.contentView.subviews copy]) {
        if (view==self.placeholderLabel) continue;
        [[MTSceneHost sharedHost] releaseHostedView:view];
        [view removeFromSuperview];
    }
    self.placeholderLabel.hidden=YES;
}
@end
