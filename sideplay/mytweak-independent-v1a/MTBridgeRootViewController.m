#import "MTBridgeRootViewController.h"
#import "MTSplitContainerViewController.h"
#import "MTAppSlotViewController.h"
#import "MTAppPickerViewController.h"
#import "MTAppLauncher.h"
#import "MTSceneHost.h"
#import "MTBridgeCoordinator.h"
#import "MTTrialLog.h"

@interface MTBridgeRootViewController () <MTAppPickerDelegate,MTAppSlotDelegate>
@property(nonatomic,strong) MTSplitContainerViewController *splitContainer;
@property(nonatomic,weak,nullable) MTAppSlotViewController *pickerTargetSlot;
@property(nonatomic,strong) NSArray<UIButton *> *menuButtons;
@end

@implementation MTBridgeRootViewController
- (UIButton *)makeButton:(NSString *)name action:(SEL)action {
    UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:name forState:UIControlStateNormal];
    [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    b.titleLabel.font=[UIFont boldSystemFontOfSize:14];
    b.backgroundColor=[UIColor colorWithWhite:0.17 alpha:0.96];
    [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return b;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=UIColor.blackColor;
    MTSplitContainerViewController *split=[MTSplitContainerViewController new];
    [self addChildViewController:split];
    split.view.frame=self.view.bounds;
    [self.view addSubview:split.view];
    [split didMoveToParentViewController:self];
    self.splitContainer=split;
    split.leftSlot.delegate=self;
    split.rightSlot.delegate=self;
    UIButton *app=[self makeButton:@"App" action:@selector(chooseApp)];
    UIButton *mode=[self makeButton:@"Split 2" action:@selector(toggleSplit)];
    UIButton *swap=[self makeButton:@"Swap" action:@selector(swapApps)];
    UIButton *zoom=[self makeButton:@"Zoom" action:@selector(toggleZoom)];
    UIButton *close=[self makeButton:@"Close" action:@selector(closeTrial)];
    self.menuButtons=@[app,mode,swap,zoom,close];
    for (UIButton *b in self.menuButtons) [self.view addSubview:b];
    MTTrialLog(@"ui-created",@"controls=App,Split,Swap,Zoom,Close initialMode=single");
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w=self.view.bounds.size.width,h=self.view.bounds.size.height;
    CGFloat menuH=52.0;
    CGFloat each=w/(CGFloat)self.menuButtons.count;
    NSUInteger i=0;
    for (UIButton *b in self.menuButtons) {
        b.frame=CGRectMake(each*i,0,each-1,menuH);
        i++;
    }
    self.splitContainer.view.frame=CGRectMake(0,menuH,w,MAX(0,h-menuH));
}
- (void)chooseApp {
    [self presentAppPickerForSlot:self.splitContainer.leftSlot];
}
- (void)toggleSplit {
    self.splitContainer.singlePaneMode=!self.splitContainer.singlePaneMode;
    UIButton *btn=self.menuButtons[1];
    [btn setTitle:self.splitContainer.singlePaneMode ? @"Split 2" : @"Single"
       forState:UIControlStateNormal];
    [self.splitContainer.view setNeedsLayout];
    MTTrialLog(@"mode-changed",self.splitContainer.singlePaneMode?@"one-app":@"two-apps");
}
- (void)swapApps {
    [self.splitContainer swapSlots];
    MTTrialLog(@"swap",@"slot-viewcontrollers-reordered-hosts-kept");
}
- (void)toggleZoom {
    [self.splitContainer toggleFullscreenForSlot:self.splitContainer.leftSlot];
    MTTrialLog(@"zoom",@"left-visible-slot-toggled");
}
- (void)closeTrial {
    MTTrialLog(@"close-request",@"disable-trial-and-stop-all-hosts");
    [[MTBridgeCoordinator sharedCoordinator] stopAndDisable];
}
- (void)presentAppPickerForSlot:(MTAppSlotViewController *)slot {
    if (self.presentedViewController) return;
    self.pickerTargetSlot=slot;
    MTAppPickerViewController *picker=[MTAppPickerViewController new];
    picker.delegate=self;
    picker.modalPresentationStyle=UIModalPresentationFullScreen;
    [self presentViewController:picker animated:YES completion:nil];
    MTTrialLog(@"picker-shown",[NSString stringWithFormat:@"slot=%ld",(long)slot.slotIndex]);
}
- (void)appPicker:(MTAppPickerViewController *)picker
    didSelectBundleID:(NSString *)bundleID displayName:(NSString *)name {
    MTAppSlotViewController *slot=self.pickerTargetSlot;
    self.pickerTargetSlot=nil;
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (!slot) return;
    NSError *error=nil;
    MTAppSession *session=[[MTAppLauncher sharedLauncher] launchAppWithBundleID:bundleID error:&error];
    if (session) {
        session.displayName=name;
        [slot setSession:session];
        MTTrialLog(@"app-chosen",[NSString stringWithFormat:@"slot=%ld bundle=%@",(long)slot.slotIndex,bundleID]);
    } else {
        [slot showLaunchError:error ?: [NSError errorWithDomain:@"com.duoface.mytweak" code:201
                                    userInfo:@{NSLocalizedDescriptionKey:@"Không mở được app"}]];
        MTTrialLog(@"app-failed",[NSString stringWithFormat:@"bundle=%@ error=%@",bundleID,error.localizedDescription ?: @"unknown"]);
    }
}
- (void)appPickerDidCancel:(MTAppPickerViewController *)picker {
    self.pickerTargetSlot=nil;
    [picker dismissViewControllerAnimated:YES completion:nil];
}
- (void)slotDidRequestAppPicker:(MTAppSlotViewController *)slot {
    [self presentAppPickerForSlot:slot];
}
- (void)slotDidDoubleTap:(MTAppSlotViewController *)slot {
    [self.splitContainer toggleFullscreenForSlot:slot];
}
@end
