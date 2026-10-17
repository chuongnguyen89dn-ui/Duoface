#import "DFCarPlayQARootController.h"
#if DFCARPLAY_QA
#import "DFCarPlayBridgeAPI.h"

// A private QA root, NOT the approved DuoFace interface. Only compiled with
// DFCARPLAY_QA=1 and instantiated behind the opt-in preference and Darwin signal.
// The UIRootSceneWindow is exclusively constructed by DFIRuntime.m.
@interface DFCarPlayQARootController ()
@property(nonatomic,strong) UIView *leftPane;
@property(nonatomic,strong) UIView *rightPane;
@property(nonatomic,strong) DFCarPlaySplitCoordinator *bridge;
@property(nonatomic) BOOL shuttingDown;
@end

@implementation DFCarPlayQARootController

- (void)record:(NSString *)event detail:(NSString *)detail {
    NSString *line=[NSString stringWithFormat:@"%@ event=%@ %@\n",
                    [NSDate date],event,detail?:@""];
    NSLog(@"DuoFaceCarPlayQA %@",line);
    // A dedicated bounded log survives a SpringBoard respring after test.
    @try {
        NSString *path=@"/var/mobile/Library/Logs/DuoFaceCarPlayQA.log";
        NSFileManager *fm=NSFileManager.defaultManager;
        [fm createDirectoryAtPath:[path stringByDeletingLastPathComponent]
      withIntermediateDirectories:YES attributes:nil error:nil];
        NSDictionary *attributes=[fm attributesOfItemAtPath:path error:nil];
        if ([attributes fileSize]>1024*1024) [fm removeItemAtPath:path error:nil];
        if (![fm fileExistsAtPath:path])
            [fm createFileAtPath:path contents:nil attributes:nil];
        NSFileHandle *handle=[NSFileHandle fileHandleForWritingAtPath:path];
        if (handle) {
            [handle seekToEndOfFile];
            [handle writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
            [handle closeFile];
        }
    } @catch (NSException *exception) {
        NSLog(@"DuoFaceCarPlayQA log-write-failed %@",exception.reason);
    }
}
- (void)loadView {
    UIView *root=[[UIView alloc]initWithFrame:UIScreen.mainScreen.bounds];
    root.backgroundColor=UIColor.blackColor;
    self.view=root;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.leftPane=[UIView new];self.rightPane=[UIView new];
    self.leftPane.clipsToBounds=YES;self.rightPane.clipsToBounds=YES;
    self.leftPane.backgroundColor=UIColor.blackColor;
    self.rightPane.backgroundColor=UIColor.darkGrayColor;
    [self.view addSubview:self.leftPane];
    [self.view addSubview:self.rightPane];
    NSError *error=nil;
    self.bridge=[[DFCarPlaySplitCoordinator alloc]initWithRootController:self
                                      panes:@[self.leftPane,self.rightPane] error:&error];
    [self record:@"root-created" detail:error.localizedDescription?:@"two panes"];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.shuttingDown) return;
    CGRect r=self.view.bounds;
    if (!self.bridge.started) {
        CGFloat half=r.size.width*.5;
        self.leftPane.frame=CGRectMake(r.origin.x,r.origin.y,half,r.size.height);
        self.rightPane.frame=CGRectMake(r.origin.x+half,r.origin.y,
                                      r.size.width-half,r.size.height);
    } else {
        [self.bridge setSplitRatio:.5];
    }
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.shuttingDown) return;
    __weak typeof(self) weakSelf=self;
    [self.bridge startWithCompletion:^(NSError *error) {
        [weakSelf record:error?@"owner-refused":@"owner-ready"
                    detail:error.localizedDescription?:NSStringFromCGRect(weakSelf.view.bounds)];
    }];
}
- (void)runSingleBundle:(NSString *)bundleID {
    if (self.shuttingDown || !self.bridge.started || !bundleID.length) {
        [self record:@"G1-refused" detail:@"owner not ready or missing qaFirstBundle"];
        return;
    }
    [self record:@"G1-request" detail:bundleID];
    __weak typeof(self) weakSelf=self;
    [self.bridge openApp:bundleID inPane:0 completion:^(NSError *error) {
        [weakSelf record:error?@"G1-fail":@"G1-scene-attached"
                    detail:error.localizedDescription?:bundleID];
    }];
}
- (void)runPairFirst:(NSString *)firstBundle second:(NSString *)secondBundle {
    if (self.shuttingDown || !self.bridge.started || !firstBundle.length ||
        !secondBundle.length || [firstBundle isEqualToString:secondBundle]) {
        [self record:@"G2-refused" detail:@"owner not ready or two distinct bundle IDs required"];
        return;
    }
    __weak typeof(self) weakSelf=self;
    void (^openSecond)(void)=^{
        DFCarPlayQARootController *owner=weakSelf;
        if (!owner || owner.shuttingDown) return;
        [owner record:@"G2-right-request" detail:secondBundle];
        [owner.bridge openApp:secondBundle inPane:1 completion:^(NSError *error) {
            [weakSelf record:error?@"G2-right-fail":@"G2-right-scene-attached"
                        detail:error.localizedDescription?:secondBundle];
            if (!error && [weakSelf.bridge hasLiveSceneInPane:0] &&
                [weakSelf.bridge hasLiveSceneInPane:1])
                [weakSelf record:@"G2-two-scenes-present"
                            detail:@"Only scene handles confirmed; touch/resize/reconnect still require QA"];
        }];
    };
    if ([self.bridge hasLiveSceneInPane:0]) {
        [self record:@"G2-left-already-live" detail:firstBundle];
        openSecond();
    } else {
        [self record:@"G2-left-request" detail:firstBundle];
        [self.bridge openApp:firstBundle inPane:0 completion:^(NSError *error) {
            [weakSelf record:error?@"G2-left-fail":@"G2-left-scene-attached"
                        detail:error.localizedDescription?:firstBundle];
            if (!error) openSecond();
        }];
    }
}
- (void)shutdown {
    if (self.shuttingDown) return;
    self.shuttingDown=YES;
    [self.bridge stop];
    // Break root-controller <-> coordinator ownership cycle.
    self.bridge=nil;
    [self record:@"owner-stopped" detail:@"all QA scenes closed"];
}
@end
#endif
