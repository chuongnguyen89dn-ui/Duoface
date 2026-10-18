#import "MTAppSlotViewController.h"
#import "MTAppLauncher.h" // lấy định nghĩa MTAppSession
#import "MTSceneHost.h"

@interface MTAppSlotViewController ()
@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *pickButton;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong, nullable) MTAppSession *session;
@end

@implementation MTAppSlotViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0.08 alpha:1.0];

    // Thanh trên: tên slot/app + nút chọn app.
    _topBar = [[UIView alloc] init];
    _topBar.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.95];
    [self.view addSubview:_topBar];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.font = [UIFont boldSystemFontOfSize:15];
    [_topBar addSubview:_titleLabel];

    _pickButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_pickButton setTitle:@"Chọn app" forState:UIControlStateNormal];
    [_pickButton addTarget:self
                   action:@selector(pickButtonTapped)
         forControlEvents:UIControlEventTouchUpInside];
    [_topBar addSubview:_pickButton];

    // Vùng nội dung bên dưới.
    _contentView = [[UIView alloc] init];
    _contentView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_contentView];

    _placeholderLabel = [[UILabel alloc] init];
    _placeholderLabel.textColor = [UIColor lightGrayColor];
    _placeholderLabel.font = [UIFont systemFontOfSize:16];
    _placeholderLabel.textAlignment = NSTextAlignmentCenter;
    _placeholderLabel.numberOfLines = 0;
    [_contentView addSubview:_placeholderLabel];

    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(contentDoubleTapped)];
    doubleTap.numberOfTapsRequired = 2;
    [_contentView addGestureRecognizer:doubleTap];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sceneHostDidFail:) name:MTSceneHostDidFailNotification object:nil];
    [self clearSlot];
}
- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }
- (void)sceneHostDidFail:(NSNotification *)note {
    if (note.object != self.session.hostedView) return;
    NSError *error=note.userInfo[@"error"];
    [self showLaunchError:error ?: [NSError errorWithDomain:@"com.mytweak.scene" code:114 userInfo:nil]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    self.topBar.frame = CGRectMake(0, 0, w, 44);
    self.titleLabel.frame = CGRectMake(12, 0, w - 120, 44);
    self.pickButton.frame = CGRectMake(w - 100, 0, 100, 44);
    self.contentView.frame = CGRectMake(0, 44, w, h - 44);
    self.placeholderLabel.frame = self.contentView.bounds;
    for (UIView *sub in self.contentView.subviews) {
        if (sub != self.placeholderLabel) {
            sub.frame = self.contentView.bounds; // hosted view phủ kín
        }
    }
}

- (void)pickButtonTapped {
    [self.delegate slotDidRequestAppPicker:self];
}

- (void)contentDoubleTapped {
    [self.delegate slotDidDoubleTap:self];
}

- (NSString *)slotName {
    return self.slotIndex == 0 ? @"Slot trái" : @"Slot phải";
}

- (void)setSession:(MTAppSession *)session {
    _session = session;
    self.titleLabel.text = session.displayName ?: session.bundleID;
    [self clearContentKeepTitle];
    if (session.hostedView) {
        session.hostedView.frame = self.contentView.bounds;
        session.hostedView.autoresizingMask =
            UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:session.hostedView];
    } else {
        // Đã "mở" app ở tầng logic nhưng chưa host được view của nó
        // (xem MTSceneHost). Hiện rõ trạng thái để không gây hiểu lầm.
        self.placeholderLabel.hidden = NO;
        self.placeholderLabel.text = [NSString stringWithFormat:
            @"%@\n\nĐã chọn nhưng chưa hiển thị được giao diện app.\n(Xem MTSceneHost)",
            session.displayName ?: session.bundleID];
    }
}

- (void)showLaunchError:(NSError *)error {
    _session = nil;
    self.titleLabel.text = [self slotName];
    [self clearContentKeepTitle];
    self.placeholderLabel.hidden = NO;
    self.placeholderLabel.text = [NSString stringWithFormat:
        @"Không mở được app:\n%@", error.localizedDescription];
    NSLog(@"[MyTweak] Slot %ld launch error: %@", (long)self.slotIndex, error);
}

- (void)clearSlot {
    _session = nil;
    self.titleLabel.text = [self slotName];
    [self clearContentKeepTitle];
    self.placeholderLabel.hidden = NO;
    self.placeholderLabel.text =
        @"Slot trống\n\nNhấn \"Chọn app\" ở trên\nDouble-tap để toàn màn hình";
}

// Xóa nội dung cũ nhưng giữ thanh tiêu đề.
- (void)clearContentKeepTitle {
    for (UIView *sub in self.contentView.subviews) {
        if (sub != self.placeholderLabel) {
            [[MTSceneHost sharedHost] releaseHostedView:sub];
            [sub removeFromSuperview];
        }
    }
    self.placeholderLabel.hidden = YES;
}

@end
