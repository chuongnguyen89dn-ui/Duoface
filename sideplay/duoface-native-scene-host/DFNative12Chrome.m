#import "DFNative12Chrome.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/message.h>
#import <math.h>
#import <fcntl.h>
#import <unistd.h>

// Native12 UI behavior is implemented independently. The original third-party
// binary is neither linked nor loaded. Only small actionable UIKit windows
// are created so the iPhone-app surfaces and Apple Dock are not occluded.
static CGFloat DFCClamp(CGFloat x) {
    if(!isfinite(x))return .5;
    return MAX(1.0/3.0,MIN(2.0/3.0,x));
}
static CGFloat DFCSnap(CGFloat x) {
    x=DFCClamp(x);
    for(NSNumber *stop in @[@(1.0/3.0),@.5,@(2.0/3.0)])
        if(fabs(x-stop.doubleValue)<.04)return stop.doubleValue;
    return x;
}
static UIImage *DFCArtwork(NSString *name) {
    // Approved independent artwork is packaged with this first-party tweak.
    if([name containsString:@"/"] || [name containsString:@".."])return nil;
    NSString *dir=@"/var/jb/Library/Application Support/DuoFaceNativeHost/VisualAssets/";
    return [UIImage imageWithContentsOfFile:
          [dir stringByAppendingString:[name stringByAppendingString:@".png"]]];
}
static void DFCLog(NSString *text) {
    NSString *s=[NSString stringWithFormat:@"[DFNative12Chrome] %@\n",text];
    NSLog(@"%@",s);
    int fd=open("/var/mobile/Library/Logs/DuoFaceTouchOwner.log",
                O_WRONLY|O_APPEND|O_CREAT,0644);
    if(fd>=0) {
        NSData *d=[s dataUsingEncoding:NSUTF8StringEncoding];
        (void)write(fd,d.bytes,d.length);close(fd);
    }
}
@interface DFNative12Chrome ()
@property(nonatomic,strong) id display;
@property(nonatomic,assign) Class configurationClass;
@property(nonatomic,assign) Class externalWindowClass;
@property(nonatomic,assign) CGRect contentRect;
@property(nonatomic,copy) DFNative12ChromeCommand callback;
@property(nonatomic,strong) NSMutableArray<UIWindow *> *windows;
@property(nonatomic,strong) NSMutableArray<UIWindow *> *pillWindows;
@property(nonatomic,strong) UIWindow *dividerWindow;
@property(nonatomic,strong) UIWindow *pickerWindow;
@property(nonatomic,strong) UIView *dividerTrack;
@property(nonatomic,strong) UIButton *dividerLogo;
@property(nonatomic,strong) NSArray<UIButton *> *pillZoom;
@property(nonatomic,strong) NSArray<UIButton *> *pillMenu;
@property(nonatomic,strong) UILabel *pickerBrand;
@property(nonatomic,assign) CGFloat ratio;
@property(nonatomic,assign) CGFloat dragStartRatio;
@property(nonatomic,assign) CGFloat logoFraction;
@property(nonatomic,assign) BOOL verticalDivider;
@property(nonatomic,assign) BOOL swapped;
@property(nonatomic,assign) BOOL pickerVisible;
@property(nonatomic,assign) NSInteger focus;
@property(nonatomic,assign) NSInteger selectedSlot;
@property(nonatomic,assign) BOOL panActive;
@property(nonatomic,assign) NSTimeInterval lastSent;
@end
@implementation DFNative12Chrome
- (instancetype)initWithDisplay:(id)display
                  configuration:(Class)configurationClass
                    windowClass:(Class)windowClass
                    contentRect:(CGRect)content
                        command:(DFNative12ChromeCommand)command {
    if((self=[super init])){
        _display=display;_configurationClass=configurationClass;
        _externalWindowClass=windowClass;_contentRect=content;
        _callback=[command copy];_ratio=.5;_logoFraction=.5;
        _verticalDivider=YES;_focus=-1;_selectedSlot=0;
        _windows=[NSMutableArray new];_pillWindows=[NSMutableArray new];
    }return self;
}
- (UIWindow *)makeWindow:(CGRect)frame root:(UIViewController *)root
                   level:(CGFloat)level {
    SEL configSelector=NSSelectorFromString(@"initWithCADisplay:isMainDisplay:");
    SEL windowSelector=NSSelectorFromString(@"initWithDisplayConfiguration:");
    if(!_display || !_configurationClass || !_externalWindowClass ||
       ![_configurationClass instancesRespondToSelector:configSelector] ||
       ![_externalWindowClass instancesRespondToSelector:windowSelector])return nil;
    // Never construct a window on the phone display or outside the external
    // CarPlay content rect. The Dock's left region remains system-owned.
    if(!isfinite(frame.origin.x) || !isfinite(frame.origin.y) ||
       frame.size.width<18 || frame.size.height<18 ||
       !CGRectContainsRect(self.contentRect,CGRectInset(frame,1,1)))return nil;
    @try {
        id config=((id(*)(id,SEL,id,BOOL))objc_msgSend)(
            [_configurationClass alloc],configSelector,_display,NO);
        UIWindow *w=((id(*)(id,SEL,id))objc_msgSend)(
            [_externalWindowClass alloc],windowSelector,config);
        if(![w isKindOfClass:UIWindow.class] || !w.screen ||
           w.screen==UIScreen.mainScreen)return nil;
        w.frame=frame;
        if(fabs(w.frame.origin.x-frame.origin.x)>2 ||
           fabs(w.frame.origin.y-frame.origin.y)>2 ||
           fabs(w.frame.size.width-frame.size.width)>2 ||
           fabs(w.frame.size.height-frame.size.height)>2)return nil;
        w.backgroundColor=UIColor.clearColor;w.opaque=NO;
        w.windowLevel=UIWindowLevelNormal+level;
        w.rootViewController=root;
        root.view.frame=CGRectMake(0,0,frame.size.width,frame.size.height);
        w.hidden=YES;
        [self.windows addObject:w];
        return w;
    } @catch(NSException *e) {
        DFCLog([NSString stringWithFormat:@"window-error=%@",e.name]);
        return nil;
    }
}
- (UIViewController *)emptyRoot:(CGRect)frame {
    UIViewController *v=[UIViewController new];
    v.view=[[UIView alloc] initWithFrame:
            CGRectMake(0,0,frame.size.width,frame.size.height)];
    v.view.backgroundColor=UIColor.clearColor;
    return v;
}
- (UIButton *)button:(NSString *)text tag:(NSInteger)tag
              action:(SEL)action {
    UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];
    b.tag=tag;
    b.tintColor=UIColor.whiteColor;
    b.titleLabel.font=[UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    [b setTitle:text forState:UIControlStateNormal];
    [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return b;
}
- (BOOL)start {
    CGRect cr=self.contentRect;
    if(!isfinite(cr.origin.x)||!isfinite(cr.origin.y)||
       CGRectGetWidth(cr)<300||CGRectGetHeight(cr)<145)return NO;
    NSMutableArray *menus=[NSMutableArray new],*zooms=[NSMutableArray new];
    for(NSInteger slot=0;slot<2;slot++) {
        CGRect frame=CGRectMake(cr.origin.x+10,cr.origin.y+3,76,22);
        UIViewController *root=[self emptyRoot:frame];
        UIView *pill=[UIView new];
        pill.frame=root.view.bounds;
        pill.layer.cornerRadius=11;
        pill.layer.masksToBounds=YES;
        pill.backgroundColor=[UIColor colorWithWhite:.16 alpha:.94];
        pill.layer.borderColor=[UIColor colorWithWhite:1 alpha:.25].CGColor;
        pill.layer.borderWidth=.5;
        [root.view addSubview:pill];
        UIButton *menu=[self button:@"App ···" tag:slot
                             action:@selector(pillPressed:)];
        UIButton *zoom=[self button:@"↗" tag:slot
                             action:@selector(zoomPressed:)];
        menu.titleLabel.font=[UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
        zoom.titleLabel.font=[UIFont boldSystemFontOfSize:13];
        UIImage *pickerArt=DFCArtwork(@"duoface-picker");
        UIImage *zoomArt=DFCArtwork(@"duoface-fullscreen");
        if(pickerArt){
            [menu setTitle:@"" forState:UIControlStateNormal];
            [menu setImage:pickerArt forState:UIControlStateNormal];
            menu.imageView.contentMode=UIViewContentModeScaleAspectFit;
        }
        if(zoomArt){
            [zoom setTitle:@"" forState:UIControlStateNormal];
            [zoom setImage:zoomArt forState:UIControlStateNormal];
            zoom.imageView.contentMode=UIViewContentModeScaleAspectFit;
        }
        menu.frame=CGRectMake(0,0,48,22);
        zoom.frame=CGRectMake(48,0,28,22);
        [pill addSubview:menu];[pill addSubview:zoom];
        UIWindow *w=[self makeWindow:frame root:root level:2];
        if(!w){[self stop];return NO;}
        [self.pillWindows addObject:w];
        [menus addObject:menu];[zooms addObject:zoom];
    }
    self.pillMenu=menus;self.pillZoom=zooms;
    CGRect divider=CGRectMake(CGRectGetMidX(cr)-16,cr.origin.y+2,
                              32,cr.size.height-4);
    UIViewController *root=[self emptyRoot:divider];
    self.dividerTrack=root.view;
    self.dividerTrack.backgroundColor=UIColor.clearColor;
    UIView *line=[UIView new];
    line.tag=718;
    line.backgroundColor=[UIColor colorWithWhite:1 alpha:.16];
    line.userInteractionEnabled=NO;
    [root.view addSubview:line];
    UIPanGestureRecognizer *trackPan=[[UIPanGestureRecognizer alloc]
                             initWithTarget:self action:@selector(dividerPan:)];
    trackPan.maximumNumberOfTouches=1;
    [self.dividerTrack addGestureRecognizer:trackPan];
    UIButton *logo=[self button:@"⇄" tag:0 action:@selector(swapPressed:)];
    logo.backgroundColor=UIColor.clearColor;
    logo.titleLabel.font=[UIFont boldSystemFontOfSize:23];
    UIImage *swapArt=DFCArtwork(@"duoface-swap");
    if(swapArt){
        [logo setTitle:@"" forState:UIControlStateNormal];
        [logo setImage:swapArt forState:UIControlStateNormal];
        logo.imageView.contentMode=UIViewContentModeScaleAspectFit;
    }
    logo.accessibilityLabel=@"Thanh chia DuoFace";
    [root.view addSubview:logo];
    UILongPressGestureRecognizer *hold=[[UILongPressGestureRecognizer alloc]
                                  initWithTarget:self action:@selector(logoHold:)];
    hold.minimumPressDuration=.30;
    hold.allowableMovement=14;
    [logo addGestureRecognizer:hold];
    UIPanGestureRecognizer *logoPan=[[UIPanGestureRecognizer alloc]
                                     initWithTarget:self action:@selector(dividerPan:)];
    logoPan.maximumNumberOfTouches=1;
    [logoPan requireGestureRecognizerToFail:hold];
    [logo addGestureRecognizer:logoPan];
    self.dividerLogo=logo;
    self.dividerWindow=[self makeWindow:divider root:root level:2];
    if(!self.dividerWindow){[self stop];return NO;}
    CGFloat pw=MIN(470,cr.size.width-20);
    CGFloat ph=MIN(150,MAX(110,cr.size.height-16));
    CGRect picker=CGRectMake(CGRectGetMidX(cr)-pw/2,
                             CGRectGetMidY(cr)-ph/2,pw,ph);
    UIViewController *pc=[self emptyRoot:picker];
    UIView *sheet=pc.view;
    sheet.backgroundColor=[UIColor colorWithWhite:.12 alpha:.97];
    sheet.layer.cornerRadius=20;
    sheet.layer.masksToBounds=YES;
    UIImage *horizontal=DFCArtwork(@"duoface-logo");
    UIImageView *brandImage=[[UIImageView alloc]initWithImage:horizontal];
    brandImage.contentMode=UIViewContentModeScaleAspectFit;
    brandImage.frame=CGRectMake(8,8,MIN(120,pw*.27),30);
    brandImage.userInteractionEnabled=NO;
    [sheet addSubview:brandImage];
    UILabel *brand=[UILabel new];
    brand.text=horizontal?@"":@"DUOFACE";
    brand.textColor=[UIColor colorWithRed:.89 green:.01 blue:.06 alpha:1];
    brand.font=[UIFont boldSystemFontOfSize:17];
    brand.textAlignment=NSTextAlignmentCenter;
    brand.frame=brandImage.frame;
    [sheet addSubview:brand];self.pickerBrand=brand;
    NSArray *names=@[@"App",@"Zoom",@"Style",@"Close"];
    NSArray *symbols=@[@"square.grid.2x2",@"arrow.up.left.and.arrow.down.right",
                        @"rectangle.3.group",@"xmark.circle"];
    CGFloat start=CGRectGetMaxX(brand.frame)+4;
    CGFloat bw=(pw-start-34)/4;
    for(NSInteger i=0;i<4;i++){
        UIButton *b=[self button:names[(NSUInteger)i] tag:i
                         action:@selector(menuAction:)];
        b.frame=CGRectMake(start+i*bw,6,bw,52);
        UIImage *img=[UIImage systemImageNamed:symbols[(NSUInteger)i]];
        [b setImage:img forState:UIControlStateNormal];
        b.tintColor=UIColor.whiteColor;
        b.titleLabel.font=[UIFont systemFontOfSize:10];
        if(@available(iOS 15,*)){
            UIButtonConfiguration *conf=[UIButtonConfiguration plainButtonConfiguration];
            conf.title=names[(NSUInteger)i];
            conf.image=img;conf.imagePlacement=NSDirectionalRectEdgeTop;
            conf.imagePadding=3;
            b.configuration=conf;
        }
        [sheet addSubview:b];
    }
    UILabel *hint=[UILabel new];
    hint.text=@"Native12 · giao diện độc lập · chưa host app iPhone";
    hint.font=[UIFont systemFontOfSize:10];
    hint.textColor=[UIColor colorWithWhite:.8 alpha:1];
    hint.textAlignment=NSTextAlignmentCenter;
    hint.frame=CGRectMake(6,ph-24,pw-12,19);
    [sheet addSubview:hint];
    UIButton *dismiss=[self button:@"×" tag:0 action:@selector(closeMenu:)];
    dismiss.frame=CGRectMake(pw-32,8,30,32);
    [sheet addSubview:dismiss];
    self.pickerWindow=[self makeWindow:picker root:pc level:3];
    if(!self.pickerWindow){[self stop];return NO;}
    [self layoutControls];
    DFCLog([NSString stringWithFormat:
        @"native12-chrome-start windows=%lu content=%@",
        (unsigned long)self.windows.count,NSStringFromCGRect(cr)]);
    return YES;
}
- (void)emit:(NSString *)action ratio:(NSNumber *)ratio {
    if(!self.callback)return;
    self.callback(action,ratio);
}
- (void)layoutControls {
    CGRect cr=self.contentRect;
    CGFloat p=DFCClamp(self.ratio);
    CGRect pane[2];
    if(self.verticalDivider) {
        CGFloat x=cr.origin.x+cr.size.width*p;
        pane[0]=CGRectMake(cr.origin.x,cr.origin.y,x-cr.origin.x,cr.size.height);
        pane[1]=CGRectMake(x,cr.origin.y,CGRectGetMaxX(cr)-x,cr.size.height);
    } else {
        CGFloat y=cr.origin.y+cr.size.height*p;
        pane[0]=CGRectMake(cr.origin.x,cr.origin.y,cr.size.width,y-cr.origin.y);
        pane[1]=CGRectMake(cr.origin.x,y,cr.size.width,CGRectGetMaxY(cr)-y);
    }
    if(self.focus>=0 && self.focus<=1) pane[self.focus]=cr;
    for(NSInteger i=0;i<2;i++) {
        UIWindow *w=self.pillWindows[(NSUInteger)i];
        BOOL show=(self.focus<0 || self.focus==i)&&!self.pickerVisible;
        CGFloat compact=(pane[i].size.width<320||pane[i].size.height<220);
        CGFloat width=(self.focus==i)?(compact?72:80):(compact?64:76);
        CGFloat height=compact?19:22;
        CGRect f=CGRectMake(CGRectGetMidX(pane[i])-width/2,
                            CGRectGetMinY(pane[i])+3,width,height);
        w.frame=f;
        UIView *v=w.rootViewController.view;
        v.frame=CGRectMake(0,0,width,height);
        UIView *pill=v.subviews.firstObject;
        pill.frame=v.bounds; pill.layer.cornerRadius=height/2;
        UIButton *menu=self.pillMenu[(NSUInteger)i];
        UIButton *zoom=self.pillZoom[(NSUInteger)i];
        menu.frame=CGRectMake(0,0,self.focus==i?0:width*.64,height);
        zoom.frame=CGRectMake(CGRectGetMaxX(menu.frame),0,
                              width-CGRectGetMaxX(menu.frame),height);
        menu.hidden=self.focus==i;
        [zoom setTitle:self.focus==i?@"↙":@"↗" forState:UIControlStateNormal];
        w.hidden=!show;
    }
    CGRect tr=self.verticalDivider?
        CGRectMake(CGRectGetMaxX(pane[0])-16,cr.origin.y+2,32,cr.size.height-4):
        CGRectMake(cr.origin.x+2,CGRectGetMaxY(pane[0])-16,cr.size.width-4,32);
    self.dividerWindow.frame=tr;
    self.dividerTrack.frame=CGRectMake(0,0,tr.size.width,tr.size.height);
    UIView *line=[self.dividerTrack viewWithTag:718];
    line.frame=self.verticalDivider?
         CGRectMake(15,0,2,tr.size.height):
         CGRectMake(0,15,tr.size.width,2);
    CGFloat size=MIN(tr.size.height>250?30:28,30);
    self.dividerLogo.frame=self.verticalDivider?
        CGRectMake((tr.size.width-size)/2,tr.size.height*self.logoFraction-size/2,size,size):
        CGRectMake(tr.size.width*self.logoFraction-size/2,(tr.size.height-size)/2,size,size);
    self.dividerWindow.hidden=(self.focus>=0||self.pickerVisible);
    self.pickerWindow.hidden=!self.pickerVisible;
}
- (void)pillPressed:(UIButton *)sender {
    self.selectedSlot=sender.tag;
    self.pickerVisible=YES;
    [self layoutControls];
    DFCLog([NSString stringWithFormat:@"picker-open slot=%ld",(long)sender.tag]);
}
- (void)closeMenu:(id)sender {
    (void)sender;
    self.pickerVisible=NO;[self layoutControls];
}
- (void)zoomPressed:(UIButton *)sender {
    self.focus=(self.focus==sender.tag)?-1:sender.tag;
    [self emit:self.focus<0?@"Restore":(self.focus==0?@"FocusLeft":@"FocusRight")
         ratio:nil];
    [self layoutControls];
}
- (void)menuAction:(UIButton *)sender {
    [self closeMenu:nil];
    switch(sender.tag){
      case 0:[self emit:@"App" ratio:@(self.selectedSlot)];break;
      case 1:self.focus=self.focus<0?self.selectedSlot:-1;
             [self emit:self.focus<0?@"Restore":(self.focus==0?@"FocusLeft":@"FocusRight")
                  ratio:nil];
             [self layoutControls];break;
      case 2:self.verticalDivider=!self.verticalDivider;
             self.ratio=.5;self.focus=-1;
             [self emit:@"Style" ratio:nil];
             [self layoutControls];break;
      case 3:[self emit:@"Close" ratio:@(self.selectedSlot)];break;
      default:break;
    }
}
- (void)swapPressed:(id)sender {
    (void)sender;
    self.swapped=!self.swapped;
    [self emit:@"SWAP" ratio:nil];
    DFCLog(@"swap-button");
}
- (void)dividerPan:(UIPanGestureRecognizer *)pan {
    if(self.pickerVisible||self.focus>=0)return;
    UIGestureRecognizerState state=pan.state;
    if(state==UIGestureRecognizerStateBegan) {
        self.dragStartRatio=self.ratio;self.panActive=YES;
        DFCLog(@"divider-pan-begin");return;
    }
    if(!self.panActive)return;
    BOOL end=state==UIGestureRecognizerStateEnded;
    BOOL cancel=state==UIGestureRecognizerStateCancelled ||
                state==UIGestureRecognizerStateFailed;
    if(state!=UIGestureRecognizerStateChanged && !end && !cancel)return;
    CGFloat displacement=self.verticalDivider?
        [pan translationInView:self.dividerTrack].x:
        [pan translationInView:self.dividerTrack].y;
    CGFloat extent=self.verticalDivider?self.contentRect.size.width:
                                     self.contentRect.size.height;
    CGFloat proposed=self.dragStartRatio+displacement/extent;
    self.ratio=cancel?self.dragStartRatio:(end?DFCSnap(proposed):DFCClamp(proposed));
    [self layoutControls];
    NSTimeInterval now=NSDate.date.timeIntervalSince1970;
    if(end||cancel||now-self.lastSent>.05) {
        self.lastSent=now;[self emit:@"Ratio" ratio:@(self.ratio)];
    }
    if(end||cancel){
        self.panActive=NO;DFCLog(end?@"divider-pan-end":@"divider-pan-cancel");
    }
}
- (void)logoHold:(UILongPressGestureRecognizer *)hold {
    if(hold.state!=UIGestureRecognizerStateChanged &&
       hold.state!=UIGestureRecognizerStateEnded)return;
    CGPoint p=[hold locationInView:self.dividerTrack];
    CGFloat span=self.verticalDivider?self.dividerTrack.bounds.size.height:
                                       self.dividerTrack.bounds.size.width;
    CGFloat position=self.verticalDivider?p.y:p.x;
    if(span<40)return;
    self.logoFraction=MAX(.1,MIN(.9,position/span));
    [self layoutControls];
    if(hold.state==UIGestureRecognizerStateEnded)
        DFCLog(@"logo-reposition-long-hold");
}
- (void)stop {
    self.callback=nil;
    for(UIWindow *w in self.windows){
        w.hidden=YES;
        w.rootViewController=nil;
    }
    [self.windows removeAllObjects];
    [self.pillWindows removeAllObjects];
    self.dividerWindow=nil;self.pickerWindow=nil;
    self.dividerTrack=nil;self.dividerLogo=nil;
    self.pillMenu=nil;self.pillZoom=nil;self.pickerBrand=nil;
    DFCLog(@"native12-chrome-stop");
}
@end
