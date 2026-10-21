// CarPlay supplies the system CPWindow. This root owns no duplicate splash,
// no simulated app panes and NO second copy of the SpringBoard split state.
// DFNative12Chrome is the single source-owned visible launch/line/picker UI;
// foreground/live app geometry is applied to real hosted scenes there.
#import "DFNative12BasicController.h"
@implementation DFNative12BasicController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=UIColor.blackColor;
    self.view.userInteractionEnabled=NO;
}
// DO NOT implement dummy performCarPlayControl:/setPresetRatio: handlers.
// Post-action snapshots are validated/ACKed by the CarPlay scene delegate.
@end
