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
@end
@implementation DFNative12BasicController
- (instancetype)init { if((self=[super init]))_ratio=0.5;return self; }
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
 self.status=[self caption:@"0.0.9 GESTURE • Thử nút và KÉO CHIA trên bảng nhỏ" size:10];[self.view addSubview:self.status];
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
 [self.view setNeedsLayout];
}
- (void)viewDidLayoutSubviews {
 [super viewDidLayoutSubviews];
 CGRect area=self.view.safeAreaLayoutGuide.layoutFrame;
 if(CGRectIsEmpty(area))area=self.view.bounds;
 CGFloat width=CGRectGetWidth(area),height=CGRectGetHeight(area);
 CGFloat x=CGRectGetMinX(area),y=CGRectGetMinY(area);
 CGFloat margin=3,bar=3;
 CGFloat split=round(width*self.ratio);
 CGFloat lw=MAX(0,split-bar/2-margin),rw=MAX(0,width-split-bar/2-margin);
 self.leftSlot.frame=CGRectMake(x+margin,y+margin,lw,MAX(0,height-2*margin));
 self.rightSlot.frame=CGRectMake(x+split+bar/2,y+margin,rw,MAX(0,height-2*margin));
 self.divider.frame=CGRectMake(x+split-17,y,34,height);
 self.logo.frame=CGRectMake(x+split-15,y+height/2-15,30,30);
 self.leftMenu.frame=CGRectMake(CGRectGetMidX(self.leftSlot.frame)-38,y+5,76,22);
 self.rightMenu.frame=CGRectMake(CGRectGetMidX(self.rightSlot.frame)-38,y+5,76,22);
 self.status.frame=CGRectMake(x+4,y+height-22,width-8,18);
 self.menuSheet.frame=CGRectMake(x+(width-272)/2,y+MAX(2,(height-42)/2),272,42);
 if(self.expanded){self.rightSlot.hidden=YES;self.leftSlot.frame=CGRectInset(area,3,3);}
 else self.rightSlot.hidden=NO;
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
 // CarPlay CPWindow cannot receive a direct divider drag. Set ratio
 // from a genuine system template action instead.
 self.ratio=MAX(1.0/3.0,MIN(2.0/3.0,ratio));
 self.status.text=[NSString stringWithFormat:@"CarPlay ratio: %.0f / %.0f",self.ratio*100,(1-self.ratio)*100];
 [self.view setNeedsLayout];
}
- (void)performCarPlayControl:(NSString *)action {
 if([action isEqualToString:@"SWAP"]){[self swap:nil];return;}
 if([action isEqualToString:@"LEFT"]){[self setPresetRatio:1.0/3.0];return;}
 if([action isEqualToString:@"RIGHT"]){[self setPresetRatio:2.0/3.0];return;}
 if([action isEqualToString:@"App"]){
   self.status.text=@"App: chưa nối host ứng dụng iPhone";
 } else if([action isEqualToString:@"Zoom"]){
   self.expanded=!self.expanded;
   self.status.text=self.expanded?@"CarPlay Zoom: 1 ô":@"CarPlay Zoom: 2 ô";
   [self.view setNeedsLayout];
 } else if([action isEqualToString:@"Style"]){
   [self setPresetRatio:0.5];
 } else if([action isEqualToString:@"Close"]){
   self.menuSheet.hidden=YES;
   self.status.text=@"CarPlay Close: đã đóng menu";
 }
}
- (void)menuAction:(UIButton *)sender {
 self.menuSheet.hidden=YES;
 NSArray *actions=@[@"App",@"Zoom",@"Style",@"Close"];
 if(sender.tag>=0 && sender.tag<(NSInteger)actions.count)
   [self performCarPlayControl:actions[(NSUInteger)sender.tag]];
}
@end
