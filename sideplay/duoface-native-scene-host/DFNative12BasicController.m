// Independent Native12/HUD8-inspired basic UI test; NO licensed vendor binary.
#import "DFNative12BasicController.h"
#import <math.h>
@interface DFNative12BasicController ()
@property(nonatomic,strong) UIView *leftSlot;
@property(nonatomic,strong) UIView *rightSlot;
@property(nonatomic,strong) UIView *divider;
@property(nonatomic,strong) UIButton *logo;
@property(nonatomic,strong) UIButton *leftMenu;
@property(nonatomic,strong) UIButton *rightMenu;
@property(nonatomic,strong) UILabel *status;
@property(nonatomic,strong) UIView *menuSheet;
@property(nonatomic) CGFloat ratio;
@property(nonatomic) BOOL swapped;
@property(nonatomic) BOOL expanded;
@property(nonatomic) BOOL touchesEnabled;
@property(nonatomic) BOOL verticalDivider;
@property(nonatomic) NSInteger focusedSlot;
@property(nonatomic,strong) UIView *startupSplash;
@end
@implementation DFNative12BasicController
- (instancetype)init { if((self=[super init])){_ratio=0.5;_verticalDivider=YES;_focusedSlot=-1;}return self; }
- (UILabel *)caption:(NSString *)title size:(CGFloat)size {
 UILabel *l=[UILabel new];l.text=title;l.textColor=UIColor.whiteColor;l.font=[UIFont systemFontOfSize:size weight:UIFontWeightMedium];l.textAlignment=NSTextAlignmentCenter;l.numberOfLines=0;return l;
}
- (void)viewDidLoad {
 [super viewDidLoad];
 self.view.backgroundColor=[UIColor colorWithRed:.06 green:.13 blue:.18 alpha:1];
 self.leftSlot=[UIView new];self.rightSlot=[UIView new];
 for(UIView *slot in @[self.leftSlot,self.rightSlot]){
  slot.backgroundColor=[UIColor colorWithRed:.09 green:.19 blue:.25 alpha:1];
  slot.layer.cornerRadius=5;slot.clipsToBounds=YES;[self.view addSubview:slot];
 }
 UILabel *left=[self caption:@"APP 1\nCHƯA NỐI SCENE" size:13];
 UILabel *right=[self caption:@"APP 2\nCHƯA NỐI SCENE" size:13];
 for(NSInteger i=0;i<2;i++){
  UIView *slot=i==0?self.leftSlot:self.rightSlot;
  UILabel *l=i==0?left:right;l.tag=42;l.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;[slot addSubview:l];
 }
 self.divider=[UIView new];self.divider.backgroundColor=UIColor.clearColor;[self.view addSubview:self.divider];
 UIPanGestureRecognizer *pan=[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(drag:)];
 [self.divider addGestureRecognizer:pan];
 self.logo=[UIButton buttonWithType:UIButtonTypeSystem];
 [self.logo setTitle:@"⇄" forState:UIControlStateNormal];
 self.logo.titleLabel.font=[UIFont boldSystemFontOfSize:20];self.logo.tintColor=UIColor.whiteColor;
 self.logo.backgroundColor=[UIColor colorWithRed:.20 green:.24 blue:.27 alpha:1];
 self.logo.layer.cornerRadius=15;[self.logo addTarget:self action:@selector(swap:) forControlEvents:UIControlEventTouchUpInside];
 [self.view addSubview:self.logo];
 UIPanGestureRecognizer *logoPan=[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(drag:)];
 [self.logo addGestureRecognizer:logoPan];
 self.leftMenu=[UIButton buttonWithType:UIButtonTypeSystem];self.rightMenu=[UIButton buttonWithType:UIButtonTypeSystem];
 for(UIButton *b in @[self.leftMenu,self.rightMenu]){
  [b setTitle:@"App  ···" forState:UIControlStateNormal];b.tintColor=UIColor.whiteColor;
  b.titleLabel.font=[UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
  [b addTarget:self action:@selector(showMenu:) forControlEvents:UIControlEventTouchUpInside];[self.view addSubview:b];
 }
 self.status=[self caption:@"0.1.0 NATIVE12 · Độc lập · Chưa nối app scene" size:10];[self.view addSubview:self.status];
 self.menuSheet=[UIView new];self.menuSheet.backgroundColor=[UIColor colorWithWhite:.13 alpha:.97];
 self.menuSheet.layer.cornerRadius=20;self.menuSheet.hidden=YES;[self.view addSubview:self.menuSheet];
 NSArray *names=@[@"App",@"Zoom",@"Style",@"Close"];
 for(NSInteger i=0;i<4;i++){
  UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];b.tag=i;
  [b setTitle:names[i] forState:UIControlStateNormal];b.tintColor=UIColor.whiteColor;
  b.titleLabel.font=[UIFont systemFontOfSize:12];
  [b addTarget:self action:@selector(menuAction:) forControlEvents:UIControlEventTouchUpInside];
  b.frame=CGRectMake(i*68,0,68,42);[self.menuSheet addSubview:b];
 }
 // Actual UIKit input is owned by bounded independent external windows.
 // CPWindow remains a visual receiver; avoid duplicate noninteractive buttons.
 self.leftMenu.hidden=YES;self.rightMenu.hidden=YES;
 self.logo.hidden=YES;
 // Reproduce the approved black Native12 logo splash in the CarPlay
 // presentation window without interacting with or obscuring the Apple Dock.
 UIView *splash=[UIView new];
 splash.backgroundColor=UIColor.blackColor;
 splash.userInteractionEnabled=NO;
 [self.view addSubview:splash];self.startupSplash=splash;
 UIImage *asset=[UIImage imageWithContentsOfFile:[[NSBundle mainBundle]
           pathForResource:@"duoface-logo" ofType:@"png" inDirectory:@"VisualAssets"]];
 UIImageView *brand=[[UIImageView alloc]initWithImage:asset];
 brand.tag=9237;brand.contentMode=UIViewContentModeScaleAspectFit;
 [splash addSubview:brand];
 [self.view setNeedsLayout];
}
- (void)viewDidAppear:(BOOL)animated {
 [super viewDidAppear:animated];
 UIView *splash=self.startupSplash;
 if(!splash)return;
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(1.6*NSEC_PER_SEC)),
       dispatch_get_main_queue(), ^{
   if(splash!=self.startupSplash)return;
   [UIView animateWithDuration:.32 animations:^{splash.alpha=0;}
          completion:^(BOOL finished){
       (void)finished;
       if(splash==self.startupSplash){
           [splash removeFromSuperview];self.startupSplash=nil;
       }
   }];
 });
}
- (void)viewDidLayoutSubviews {
 [super viewDidLayoutSubviews];
 if(self.startupSplash){
    CGRect area=CGRectIsEmpty(self.view.safeAreaLayoutGuide.layoutFrame)?
       self.view.bounds:self.view.safeAreaLayoutGuide.layoutFrame;
    self.startupSplash.frame=area;
    UIImageView *logo=[self.startupSplash viewWithTag:9237];
    CGFloat width=MIN(area.size.width*.8,400);
    logo.frame=CGRectMake((area.size.width-width)/2,(area.size.height-width/4)/2,
                           width,width/4);
 }
 CGRect area=self.view.safeAreaLayoutGuide.layoutFrame;
 if(CGRectIsEmpty(area))area=self.view.bounds;
 CGFloat width=CGRectGetWidth(area),height=CGRectGetHeight(area);
 CGFloat x=CGRectGetMinX(area),y=CGRectGetMinY(area);
 CGFloat margin=3,bar=3;
 CGFloat split=round((self.verticalDivider?width:height)*self.ratio);
 if(self.verticalDivider) {
   CGFloat lw=MAX(0,split-bar/2-margin),rw=MAX(0,width-split-bar/2-margin);
   self.leftSlot.frame=CGRectMake(x+margin,y+margin,lw,MAX(0,height-2*margin));
   self.rightSlot.frame=CGRectMake(x+split+bar/2,y+margin,rw,MAX(0,height-2*margin));
   self.divider.frame=CGRectMake(x+split-16,y,32,height);
   self.logo.frame=CGRectMake(x+split-15,y+height/2-15,30,30);
 } else {
   CGFloat th=MAX(0,split-bar/2-margin),bh=MAX(0,height-split-bar/2-margin);
   self.leftSlot.frame=CGRectMake(x+margin,y+margin,MAX(0,width-2*margin),th);
   self.rightSlot.frame=CGRectMake(x+margin,y+split+bar/2,MAX(0,width-2*margin),bh);
   self.divider.frame=CGRectMake(x,y+split-16,width,32);
   self.logo.frame=CGRectMake(x+width/2-15,y+split-15,30,30);
 }
 self.leftMenu.frame=CGRectMake(CGRectGetMidX(self.leftSlot.frame)-38,
                                  CGRectGetMinY(self.leftSlot.frame)+3,76,22);
 self.rightMenu.frame=CGRectMake(CGRectGetMidX(self.rightSlot.frame)-38,
                                  CGRectGetMinY(self.rightSlot.frame)+3,76,22);
 self.status.frame=CGRectMake(x+4,y+height-22,width-8,18);
 self.menuSheet.frame=CGRectMake(x+(width-272)/2,y+MAX(2,(height-42)/2),272,42);
 self.leftSlot.hidden=NO;self.rightSlot.hidden=NO;
 if(self.expanded) {
     self.leftSlot.hidden=self.focusedSlot==1;
     self.rightSlot.hidden=self.focusedSlot!=1;
     UIView *focused=self.focusedSlot==1?self.rightSlot:self.leftSlot;
     focused.frame=CGRectInset(area,3,3);
 }
 // Visible Native12 pills/divider/selector are drawn by external input owner,
 // not duplicates in navigation CPWindow.
 self.leftMenu.hidden=YES;self.rightMenu.hidden=YES;
 self.logo.hidden=YES;self.menuSheet.hidden=YES;
}
- (void)drag:(UIPanGestureRecognizer *)pan {
 CGPoint p=[pan locationInView:self.view];CGRect a=self.view.safeAreaLayoutGuide.layoutFrame;
 if(CGRectGetWidth(a)<100)return;
 CGFloat r=(p.x-CGRectGetMinX(a))/CGRectGetWidth(a);
 self.ratio=MAX(1.0/3.0,MIN(2.0/3.0,r));
 if(pan.state==UIGestureRecognizerStateChanged||pan.state==UIGestureRecognizerStateEnded){
  [self.view setNeedsLayout];self.status.text=[NSString stringWithFormat:@"Tỷ lệ %.0f / %.0f",100*self.ratio,100*(1-self.ratio)];
 }
}
- (void)swap:(id)sender { (void)sender;self.swapped=!self.swapped;
 UILabel *a=[self.leftSlot viewWithTag:42],*b=[self.rightSlot viewWithTag:42];
 a.text=self.swapped?@"APP 2\nCHƯA NỐI SCENE":@"APP 1\nCHƯA NỐI SCENE";
 b.text=self.swapped?@"APP 1\nCHƯA NỐI SCENE":@"APP 2\nCHƯA NỐI SCENE";
 self.status.text=@"Đã đổi vị trí 2 ô thử nghiệm";
}
- (void)showMenu:(id)sender { (void)sender;self.menuSheet.hidden=!self.menuSheet.hidden; }
- (void)setPresetRatio:(CGFloat)ratio {
 // Native12 behavior: both panes share one source-owned ratio state.
 self.ratio=MAX(1.0/3.0,MIN(2.0/3.0,ratio));
 self.status.text=[NSString stringWithFormat:@"Native12 tỷ lệ %.0f / %.0f",self.ratio*100,(1-self.ratio)*100];
 [self.view setNeedsLayout];
}
- (void)performCarPlayControl:(NSString *)action {
 [self performCarPlayControl:action slot:0];
}
- (void)performCarPlayControl:(NSString *)action slot:(NSInteger)slot {
 if([action isEqualToString:@"SWAP"]){[self swap:nil];return;}
 if([action isEqualToString:@"LEFT"]){[self setPresetRatio:1.0/3.0];return;}
 if([action isEqualToString:@"RIGHT"]){[self setPresetRatio:2.0/3.0];return;}
 if([action isEqualToString:@"FocusLeft"] || [action isEqualToString:@"FocusRight"]){
    self.focusedSlot=[action isEqualToString:@"FocusLeft"]?0:1;
    self.expanded=YES;
    self.status.text=self.focusedSlot==0?@"Native12: ô trái đầy vùng nội dung":@"Native12: ô phải đầy vùng nội dung";
    [self.view setNeedsLayout];
 }else if([action isEqualToString:@"Restore"]){
    self.focusedSlot=-1;self.expanded=NO;
    self.status.text=@"Native12: khôi phục 2 ô";
    [self.view setNeedsLayout];
 }else if([action isEqualToString:@"App"]){
    self.status.text=[NSString stringWithFormat:@"App ô %ld: chưa nối host scene",(long)(slot+1)];
 }else if([action isEqualToString:@"Zoom"]){
    self.expanded=!self.expanded;
    self.focusedSlot=self.expanded?0:-1;
    self.status.text=self.expanded?@"Native12 Zoom: một ô":@"Native12 Zoom: hai ô";
    [self.view setNeedsLayout];
 }else if([action isEqualToString:@"Style"]){
    self.verticalDivider=!self.verticalDivider;
    self.ratio=.5;
    self.expanded=NO;self.focusedSlot=-1;
    self.status.text=self.verticalDivider?@"Native12: chia trái/phải":@"Native12: chia trên/dưới";
    [self.view setNeedsLayout];
 }else if([action isEqualToString:@"Close"]){
    self.status.text=[NSString stringWithFormat:@"Close ô %ld: chưa có app để đóng",(long)(slot+1)];
 }
}
- (void)menuAction:(UIButton *)sender {
 self.menuSheet.hidden=YES;
 NSArray *actions=@[@"App",@"Zoom",@"Style",@"Close"];
 if(sender.tag>=0 && sender.tag<(NSInteger)actions.count)
   [self performCarPlayControl:actions[(NSUInteger)sender.tag]];
}
@end
