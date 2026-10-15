#import "../shared/DFISettings.h"
@interface PSListController : UIViewController
@end
@interface DFIPreferencesController : PSListController
@property(nonatomic,strong) DFISettingsController *settings;
@end
@implementation DFIPreferencesController
- (void)viewDidLoad{[super viewDidLoad];self.title=@"DuoFace Mới";self.settings=[DFISettingsController new];[self addChildViewController:self.settings];self.settings.view.frame=self.view.bounds;self.settings.view.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;[self.view addSubview:self.settings.view];[self.settings didMoveToParentViewController:self];}
@end
