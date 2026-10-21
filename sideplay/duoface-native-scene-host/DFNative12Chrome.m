#import "DFNative12Chrome.h"
#import "DFSceneHost.h"
#import "DFAppPickerVC.h"
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
// Persist only fully source-owned layout settings, never private scene handles
// or vendor-license state. App scenes are created fresh on each connection.
static NSString *const kDFLayoutPath=
    @"/var/mobile/Library/Preferences/com.duoface.nativehost.layout.v1.plist";
static NSDictionary *DFCRestoreLayout(void) {
    NSDictionary *record=[NSDictionary dictionaryWithContentsOfFile:kDFLayoutPath];
    if(![record isKindOfClass:NSDictionary.class] ||
       ![record[@"Version"] isEqual:@1])return nil;
    for(NSString *key in @[@"Ratio",@"LogoFraction",@"Vertical",@"Swapped"])
        if(![record[key] isKindOfClass:NSNumber.class])return nil;
    double ratio=[record[@"Ratio"] doubleValue];
    double logo=[record[@"LogoFraction"] doubleValue];
    if(!isfinite(ratio) || ratio<1.0/3.0 || ratio>2.0/3.0 ||
       !isfinite(logo) || logo<.1 || logo>.9)return nil;
    return record;
}
static BOOL DFCSaveLayout(CGFloat ratio, CGFloat logo, BOOL vertical, BOOL swapped) {
    if(!isfinite(ratio) || ratio<1.0/3.0 || ratio>2.0/3.0 ||
       !isfinite(logo) || logo<.1 || logo>.9)return NO;
    NSDictionary *record=@{@"Version":@1,@"Ratio":@(ratio),
        @"LogoFraction":@(logo),@"Vertical":@(vertical),@"Swapped":@(swapped)};
    return [record writeToFile:kDFLayoutPath atomically:YES];
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
@interface DFNative12Chrome () <DFAppPickerDelegate>
@property(nonatomic,strong) id display;
@property(nonatomic,assign) Class configurationClass;
@property(nonatomic,assign) Class externalWindowClass;
@property(nonatomic,assign) CGRect contentRect;
@property(nonatomic,copy) DFNative12ChromeCommand callback;
@property(nonatomic,strong) NSMutableArray<UIWindow *> *windows;
@property(nonatomic,strong) NSMutableArray<UIWindow *> *pillWindows;
@property(nonatomic,strong) UIWindow *dividerWindow;
@property(nonatomic,strong) UIWindow *pickerWindow;
@property(nonatomic,strong) UIWindow *appPickerWindow;
@property(nonatomic,strong) DFAppPickerVC *appPickerController;
@property(nonatomic,strong) NSMutableArray<UIWindow *> *appSceneWindows;
@property(nonatomic,strong) NSMutableArray *hostedScenes;
@property(nonatomic,strong) NSMutableArray<NSNumber *> *sceneHandleReady;
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
        NSDictionary *prior=DFCRestoreLayout();
        if(prior){
            _ratio=[prior[@"Ratio"] doubleValue];
            _logoFraction=[prior[@"LogoFraction"] doubleValue];
            _verticalDivider=[prior[@"Vertical"] boolValue];
            _swapped=[prior[@"Swapped"] boolValue];
        }
        _windows=[NSMutableArray new];_pillWindows=[NSMutableArray new];
        _appSceneWindows=[NSMutableArray new];
        _hostedScenes=[NSMutableArray arrayWithArray:@[[NSNull null],[NSNull null]]];
        _sceneHandleReady=[NSMutableArray arrayWithArray:@[@NO,@NO]];
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
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(sceneReady:) name:DFSceneHostDidBecomeReadyNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(sceneFailed:) name:DFSceneHostDidFailNotification object:nil];
    CGRect cr=self.contentRect;
    if(!isfinite(cr.origin.x)||!isfinite(cr.origin.y)||
       CGRectGetWidth(cr)<300||CGRectGetHeight(cr)<145)return NO;
    NSMutableArray *menus=[NSMutableArray new],*zooms=[NSMutableArray new];
    for(NSInteger slot=0;slot<2;slot++) {
        CGRect frame=CGRectMake(cr.origin.x+10,cr.origin.y+3,76,22);
        UIViewController *root=[self emptyRoot:frame];
        UIVisualEffectView *pill=[[UIVisualEffectView alloc]
                  initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark]];
        pill.frame=root.view.bounds;
        pill.layer.cornerRadius=11;
        pill.layer.masksToBounds=YES;
        pill.layer.borderColor=[UIColor colorWithWhite:1 alpha:.25].CGColor;
        pill.layer.borderWidth=.5;
        [root.view addSubview:pill];
        UIButton *menu=[self button:@"App ···" tag:slot
                             action:@selector(pillPressed:)];
        UIButton *zoom=[self button:@"↗" tag:slot
                             action:@selector(zoomPressed:)];
        menu.titleLabel.font=[UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
        zoom.titleLabel.font=[UIFont boldSystemFontOfSize:13];
        // The approved picker PNG is a 256x70 COMPOSITE strip, not an
        // icon. Stretching it into 48x22 made the enormous black/white
        // blocks visible on the real CarPlay screenshot. Source-own the
        // Native12 two-action pill and use proper alpha symbols instead.
        [menu setTitle:@"" forState:UIControlStateNormal];
        [zoom setTitle:@"" forState:UIControlStateNormal];
        UIImageSymbolConfiguration *symbol=[UIImageSymbolConfiguration
                      configurationWithPointSize:12 weight:UIImageSymbolWeightMedium];
        [menu setImage:[UIImage systemImageNamed:@"ellipsis" withConfiguration:symbol]
              forState:UIControlStateNormal];
        [zoom setImage:[UIImage systemImageNamed:@"arrow.up.left.and.arrow.down.right"
                                     withConfiguration:symbol]
              forState:UIControlStateNormal];
        menu.frame=CGRectMake(0,0,38,22);
        zoom.frame=CGRectMake(38,0,38,22);
        [pill.contentView addSubview:menu];
        [pill.contentView addSubview:zoom];
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
    line.backgroundColor=[UIColor clearColor];
    line.userInteractionEnabled=NO;
    [root.view addSubview:line];
    UIPanGestureRecognizer *trackPan=[[UIPanGestureRecognizer alloc]
                             initWithTarget:self action:@selector(dividerPan:)];
    trackPan.maximumNumberOfTouches=1;
    [self.dividerTrack addGestureRecognizer:trackPan];
    UIButton *logo=[self button:@"⇄" tag:0 action:@selector(swapPressed:)];
    logo.backgroundColor=UIColor.clearColor;
    logo.titleLabel.font=[UIFont boldSystemFontOfSize:23];
    // The 120x120 reference swap bitmap includes an opaque dark square
    // in this asset set. Use the original QA-native vector fallback instead:
    // the divider logo must have no black disk/background on CarPlay.
    [logo setTitle:@"" forState:UIControlStateNormal];
    UIImage *arrow=[[UIImage systemImageNamed:@"arrow.left.arrow.right"]
                       imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [logo setImage:arrow forState:UIControlStateNormal];
    logo.tintColor=UIColor.whiteColor;
    logo.imageView.contentMode=UIViewContentModeScaleAspectFit;
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
    UIImage *horizontal=DFCArtwork(@"duoface-logo-picker-alpha-v2");
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
    hint.text=@"DuoFace · App chọn ứng dụng đã cài";
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
    // Two REAL app-scene containers from SpringBoard, created but kept
    // hidden until a user explicitly selects an installed application.
    // Do not claim "APP scene ready" just because the external window exists.
    for(NSInteger i=0;i<2;i++){
        CGRect rect=CGRectMake(cr.origin.x+(i?cr.size.width/2:0),
                               cr.origin.y,cr.size.width/2,cr.size.height);
        UIViewController *slotRoot=[self emptyRoot:rect];
        slotRoot.view.clipsToBounds=YES;
        UIWindow *slotWindow=[self makeWindow:rect root:slotRoot level:0.5];
        if(!slotWindow){[self stop];return NO;}
        [self.appSceneWindows addObject:slotWindow];
    }
    self.appPickerController=[DFAppPickerVC new];
    self.appPickerController.delegate=self;
    CGRect chooserRect=CGRectInset(cr,MAX(8,(cr.size.width-480)/2),
                MAX(8,(cr.size.height-330)/2));
    if(chooserRect.size.width<220||chooserRect.size.height<110){
        [self stop];return NO;
    }
    self.appPickerWindow=[self makeWindow:chooserRect
          root:self.appPickerController level:4];
    if(!self.appPickerWindow){[self stop];return NO;}
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
- (void)saveSplitState {
    if(!DFCSaveLayout(self.ratio,self.logoFraction,
                      self.verticalDivider,self.swapped))
        DFCLog(@"split-layout-persist-failed");
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
        // Reproduce Native12 six pill states from DFSPNativeSlotPill:
        // empty/loaded/focused, each normal or compact. An empty or
        // pending slot must not offer a nonfunctional fullscreen action.
        NSInteger physicalSlot=self.swapped?1-i:i;
        BOOL ready=[self.sceneHandleReady[(NSUInteger)physicalSlot] boolValue];
        BOOL focused=(self.focus==i);
        BOOL show=(self.focus<0 || focused)&&!self.pickerVisible;
        CGFloat compact=(pane[i].size.width<320||pane[i].size.height<220);
        CGFloat width=focused?(compact?72:80):
               (ready?(compact?64:76):(compact?38:44));
        CGFloat height=compact?19:22;
        CGRect f=CGRectMake(CGRectGetMidX(pane[i])-width/2,
                            CGRectGetMinY(pane[i])+3,width,height);
        w.frame=f;
        UIView *v=w.rootViewController.view;
        v.frame=CGRectMake(0,0,width,height);
        UIVisualEffectView *pill=(UIVisualEffectView *)v.subviews.firstObject;
        pill.frame=v.bounds; pill.layer.cornerRadius=height/2;
        UIButton *menu=self.pillMenu[(NSUInteger)i];
        UIButton *zoom=self.pillZoom[(NSUInteger)i];
        menu.frame=CGRectMake(0,0,focused?0:(ready?width/2:width),height);
        zoom.frame=CGRectMake(CGRectGetMaxX(menu.frame),0,
                              width-CGRectGetMaxX(menu.frame),height);
        menu.hidden=focused;
        zoom.hidden=!(focused||ready);
        UIImage *icon=[UIImage systemImageNamed:self.focus==i?
             @"arrow.down.right.and.arrow.up.left":
             @"arrow.up.left.and.arrow.down.right"];
        [zoom setImage:icon forState:UIControlStateNormal];
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
    for(NSInteger i=0;i<2;i++){
        UIWindow *appWindow=self.appSceneWindows[(NSUInteger)i];
        NSInteger visualSlot=self.swapped?1-i:i;
        CGRect target=pane[visualSlot];
        if(self.focus>=0 && visualSlot==self.focus)target=cr;
        appWindow.frame=target;
        UIView *v=appWindow.rootViewController.view;
        v.frame=CGRectMake(0,0,target.size.width,target.size.height);
        for(UIView *child in v.subviews)child.frame=v.bounds;
        // Native12 keeps genuine app scenes visible BEHIND the App/Style
        // sheet and picker. A modal must never detach/suspend both scenes.
        BOOL loaded=(self.hostedScenes[(NSUInteger)i]!=NSNull.null);
        appWindow.hidden=(!loaded ||
                           (self.focus>=0 && self.focus!=visualSlot));
    }
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
    NSInteger physical=self.swapped?1-sender.tag:sender.tag;
    if(self.focus!=sender.tag &&
       (physical<0 || physical>1 ||
        ![self.sceneHandleReady[(NSUInteger)physical] boolValue]))return;
    self.focus=(self.focus==sender.tag)?-1:sender.tag;
    [self emit:self.focus<0?@"Restore":(self.focus==0?@"FocusLeft":@"FocusRight")
         ratio:nil];
    [self layoutControls];
}
- (void)menuAction:(UIButton *)sender {
    [self closeMenu:nil];
    switch(sender.tag){
      case 0:[self openAppPickerForSlot:self.selectedSlot];break;
      case 1:{
             NSInteger physical=self.swapped?1-self.selectedSlot:self.selectedSlot;
             if(self.focus<0 &&
                (physical<0||physical>1||
                 ![self.sceneHandleReady[(NSUInteger)physical] boolValue]))break;
             self.focus=self.focus<0?self.selectedSlot:-1;
             [self emit:self.focus<0?@"Restore":(self.focus==0?@"FocusLeft":@"FocusRight")
                  ratio:nil];
             [self layoutControls];break;
      }
      case 2:self.verticalDivider=!self.verticalDivider;
             self.ratio=.5;self.focus=-1;
             [self saveSplitState];
             [self emit:@"Style" ratio:nil];
             [self layoutControls];break;
      case 3:[self closeHostedSlot:self.selectedSlot];break;
      default:break;
    }
}
- (void)openAppPickerForSlot:(NSInteger)slot {
    if(slot!=0 && slot!=1)return;
    self.selectedSlot=slot;
    // Picker contents are read fresh every time. Do not reuse a stale
    // LSApplicationWorkspace snapshot across install/remove operations.
    [self.appPickerController refreshInstalledApps];
    self.appPickerWindow.hidden=NO;
    [self layoutControls];
    DFCLog([NSString stringWithFormat:@"real-app-picker-open slot=%ld",(long)slot]);
}
- (void)appPickerDidCancel:(DFAppPickerVC *)picker {
    if(picker!=self.appPickerController)return;
    self.appPickerWindow.hidden=YES;
    [self layoutControls];
}
- (void)appPicker:(DFAppPickerVC *)picker
 didSelectBundleID:(NSString *)bundleID displayName:(NSString *)name {
    if(picker!=self.appPickerController || !self.appPickerWindow || 
       ![bundleID isKindOfClass:NSString.class] || !bundleID.length)return;
    NSInteger slot=self.selectedSlot;
    NSInteger physicalSlot=self.swapped?1-slot:slot;
    if(physicalSlot<0 || physicalSlot>=2)return;
    if(self.hostedScenes[(NSUInteger)physicalSlot]!=NSNull.null)
        [self closeHostedSlot:slot];
    NSError *error=nil;
    UIView *host=[[DFSceneHost sharedHost] hostViewForBundleID:bundleID
                                                          error:&error];
    if(!host){
        DFCLog([NSString stringWithFormat:@"app-host-refused id=%@ reason=%@",
                         bundleID,error.localizedDescription?:@"unknown"]);
        // Leave the actual picker visible after a failed host request; do
        // not display a blank app pane as though launch succeeded.
        self.appPickerWindow.hidden=NO;
        [self layoutControls];
        return;
    }
    UIWindow *slotWindow=self.appSceneWindows[(NSUInteger)physicalSlot];
    UIView *container=slotWindow.rootViewController.view;
    host.frame=container.bounds;
    host.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [container addSubview:host];
    self.hostedScenes[(NSUInteger)physicalSlot]=host;
    self.sceneHandleReady[(NSUInteger)physicalSlot]=@NO;
    self.appPickerWindow.hidden=YES;
    [self layoutControls];
    [self emit:@"App" ratio:@(slot)];
    DFCLog([NSString stringWithFormat:
          @"app-scene-pending-not-render-verified slot=%ld bundle=%@ name=%@",
          (long)slot,bundleID,name]);
}
- (void)sceneReady:(NSNotification *)note {
    UIView *host=(UIView *)note.object;
    if(![host isKindOfClass:UIView.class])return;
    for(NSInteger i=0;i<2;i++){
       if(self.hostedScenes[(NSUInteger)i]==host){
          self.sceneHandleReady[(NSUInteger)i]=@YES;
          DFCLog([NSString stringWithFormat:@"scene-handle-attached-render-unverified slot=%ld bundle=%@",
             (long)i,note.userInfo[@"bundleID"]?:@"unknown"]);
          [self layoutControls];
          return;
       }
    }
}
- (void)sceneFailed:(NSNotification *)note {
    UIView *host=(UIView *)note.object;
    if(![host isKindOfClass:UIView.class])return;
    for(NSInteger i=0;i<2;i++){
       if(self.hostedScenes[(NSUInteger)i]==host){
          self.hostedScenes[(NSUInteger)i]=NSNull.null;
          self.sceneHandleReady[(NSUInteger)i]=@NO;
          NSInteger visual=self.swapped?1-i:i;
          if(self.focus==visual)self.focus=-1;
          self.appSceneWindows[(NSUInteger)i].hidden=YES;
          DFCLog([NSString stringWithFormat:@"real-scene-failed slot=%ld error=%@",
                (long)i,note.userInfo[@"error"]?:@"unknown"]);
          [self layoutControls];
          return;
       }
    }
}
- (void)closeHostedSlot:(NSInteger)slot {
    NSInteger physicalSlot=self.swapped?1-slot:slot;
    if(physicalSlot<0||physicalSlot>=2)return;
    UIView *view=self.hostedScenes[(NSUInteger)physicalSlot];
    if([view isKindOfClass:UIView.class])
        [[DFSceneHost sharedHost] releaseHostedView:view];
    self.hostedScenes[(NSUInteger)physicalSlot]=NSNull.null;
    self.sceneHandleReady[(NSUInteger)physicalSlot]=@NO;
    if(self.focus==slot)self.focus=-1;
    UIWindow *window=self.appSceneWindows[(NSUInteger)physicalSlot];
    window.hidden=YES;
    [self layoutControls];
    [self emit:@"Close" ratio:@(slot)];
    DFCLog([NSString stringWithFormat:@"app-host-close slot=%ld",(long)slot]);
}
- (void)swapPressed:(id)sender {
    (void)sender;
    self.swapped=!self.swapped;
    [self saveSplitState];
    [self layoutControls];
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
        if(end)[self saveSplitState];
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
    if(hold.state==UIGestureRecognizerStateEnded){
        [self saveSplitState];
        DFCLog(@"logo-reposition-long-hold");
    }
}
- (void)stop {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.callback=nil;
    [self.appPickerController setDelegate:nil];
    [[DFSceneHost sharedHost] stopAllHosts];
    self.appPickerWindow.hidden=YES;
    for(UIWindow *w in self.appSceneWindows)w.hidden=YES;
    for(UIWindow *w in self.windows){
        w.hidden=YES;
        w.rootViewController=nil;
    }
    [self.windows removeAllObjects];
    [self.pillWindows removeAllObjects];
    self.dividerWindow=nil;self.pickerWindow=nil;
    self.appPickerWindow=nil;self.appPickerController=nil;
    [self.appSceneWindows removeAllObjects];[self.hostedScenes removeAllObjects];
    [self.sceneHandleReady removeAllObjects];
    self.dividerTrack=nil;self.dividerLogo=nil;
    self.pillMenu=nil;self.pillZoom=nil;self.pickerBrand=nil;
    DFCLog(@"native12-chrome-stop");
}
@end
