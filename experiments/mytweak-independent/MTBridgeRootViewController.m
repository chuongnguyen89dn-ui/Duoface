#import "MTBridgeRootViewController.h"
#import "MTSplitContainerViewController.h"
#import "MTAppSlotViewController.h"
#import "MTAppPickerViewController.h"
#import "MTAppLauncher.h"

@interface MTBridgeRootViewController () <MTAppPickerDelegate, MTAppSlotDelegate>
@property (nonatomic, strong) MTSplitContainerViewController *splitContainer;
@property (nonatomic, weak, nullable) MTAppSlotViewController *pickerTargetSlot;
@end

@implementation MTBridgeRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];

    MTSplitContainerViewController *split = [[MTSplitContainerViewController alloc] init];
    [self addChildViewController:split];
    split.view.frame = self.view.bounds;
    split.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:split.view];
    [split didMoveToParentViewController:self];
    self.splitContainer = split;

    // Root làm delegate cho cả hai slot.
    split.leftSlot.delegate = self;
    split.rightSlot.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // Lần đầu hiện lên: mở sẵn màn chọn app cho slot trái.
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self presentAppPickerForSlot:self.splitContainer.leftSlot];
    });
}

- (void)presentAppPickerForSlot:(MTAppSlotViewController *)slot {
    self.pickerTargetSlot = slot;
    MTAppPickerViewController *picker = [[MTAppPickerViewController alloc] init];
    picker.delegate = self;
    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - MTAppPickerDelegate

- (void)appPicker:(MTAppPickerViewController *)picker
    didSelectBundleID:(NSString *)bundleID
          displayName:(NSString *)name {
    [picker dismissViewControllerAnimated:YES completion:nil];
    MTAppSlotViewController *slot = self.pickerTargetSlot;
    self.pickerTargetSlot = nil;
    if (!slot) {
        return;
    }
    NSError *error = nil;
    MTAppSession *session = [[MTAppLauncher sharedLauncher]
        launchAppWithBundleID:bundleID error:&error];
    if (session) {
        session.displayName = name;
        [slot setSession:session];
    } else {
        if (!error) {
            error = [NSError errorWithDomain:@"MyTweak"
                                        code:-1
                                    userInfo:@{NSLocalizedDescriptionKey: @"Không mở được app"}];
        }
        [slot showLaunchError:error];
    }
}

- (void)appPickerDidCancel:(MTAppPickerViewController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
    self.pickerTargetSlot = nil;
}

#pragma mark - MTAppSlotDelegate

- (void)slotDidRequestAppPicker:(MTAppSlotViewController *)slot {
    [self presentAppPickerForSlot:slot];
}

- (void)slotDidDoubleTap:(MTAppSlotViewController *)slot {
    [self.splitContainer toggleFullscreenForSlot:slot];
}

@end
