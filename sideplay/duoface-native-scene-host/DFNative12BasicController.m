// CarPlay supplies the native CPWindow. The only visible content here is the
// opening brand splash and the real app surfaces owned by DFSceneHost outside
// this window. Never draw two dummy panes, fake app icons or a demo divider.
#import "DFNative12BasicController.h"
#import <math.h>
@interface DFNative12BasicController ()
@property(nonatomic,strong) UIImageView *startupSplash;
@end
@implementation DFNative12BasicController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=UIColor.blackColor;
    self.view.userInteractionEnabled=NO;
    UIImage *art=[UIImage imageWithContentsOfFile:[[NSBundle mainBundle]
                 pathForResource:@"duoface-logo" ofType:@"png" inDirectory:@"VisualAssets"]];
    if(!art)return;
    UIImageView *logo=[[UIImageView alloc]initWithImage:art];
    logo.contentMode=UIViewContentModeScaleAspectFit;
    logo.backgroundColor=UIColor.clearColor;
    logo.userInteractionEnabled=NO;
    [self.view addSubview:logo];self.startupSplash=logo;
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if(!self.startupSplash)return;
    CGRect area=self.view.safeAreaLayoutGuide.layoutFrame;
    if(CGRectIsEmpty(area))area=self.view.bounds;
    CGFloat width=MIN(CGRectGetWidth(area)*.78,400);
    self.startupSplash.frame=CGRectMake(CGRectGetMidX(area)-width/2,
               CGRectGetMidY(area)-width/8,width,width/4);
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    UIImageView *logo=self.startupSplash;
    if(!logo)return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(1.5*NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if(logo!=self.startupSplash)return;
        [UIView animateWithDuration:.25 animations:^{logo.alpha=0;}
                         completion:^(BOOL finished){
           (void)finished;
           if(logo==self.startupSplash){
               [logo removeFromSuperview];self.startupSplash=nil;
           }
        }];
    });
}
// These are receipt-only diagnostics from the source-owned split/scene host.
// Do NOT mutate a second copy of the ratio, focus, app views or window order.
- (void)setPresetRatio:(CGFloat)ratio {
    if(!isfinite(ratio) || ratio<1.0/3.0 || ratio>2.0/3.0)return;
    NSLog(@"[DuoFaceSceneReceiver] ratio=%f",ratio);
}
- (void)swap:(id)sender {
    (void)sender;
    [self performCarPlayControl:@"SWAP" slot:0];
}
- (void)performCarPlayControl:(NSString *)action {
    [self performCarPlayControl:action slot:0];
}
- (void)performCarPlayControl:(NSString *)action slot:(NSInteger)slot {
    if(![action isKindOfClass:NSString.class] || !action.length)return;
    NSLog(@"[DuoFaceSceneReceiver] control=%@ slot=%ld",action,(long)slot);
}
@end
