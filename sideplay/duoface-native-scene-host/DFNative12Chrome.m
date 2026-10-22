#import "DFNative12Chrome.h"
#import "DFSceneHost.h"
#import "DFAppPickerVC.h"
#import "DFLayoutEngine.h"
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
static NSInteger DFCanonicalPreset(NSInteger old) {
    const NSInteger map[9]={1,2,4,5,6,7,3,3,0};
    return old>=0&&old<=8?map[old]:1;
}
static NSDictionary *DFCRestoreLayout(void) {
    NSDictionary *record=[NSDictionary dictionaryWithContentsOfFile:kDFLayoutPath];
    if(![record isKindOfClass:NSDictionary.class] ||
       !([record[@"Version"] isEqual:@1] || [record[@"Version"] isEqual:@2]))return nil;
    BOOL legacy=[record[@"Version"] isEqual:@1];
    for(NSString *key in @[@"Ratio",@"LogoFraction",@"Vertical",@"Swapped"])
        if(![record[key] isKindOfClass:NSNumber.class])return nil;
    double ratio=[record[@"Ratio"] doubleValue];
    double logo=[record[@"LogoFraction"] doubleValue];
    if(!isfinite(ratio) || ratio<1.0/3.0 || ratio>2.0/3.0 ||
       !isfinite(logo) || logo<.1 || logo>.9)return nil;
    NSNumber *preset=record[@"Preset"];
    if(preset && (![preset isKindOfClass:NSNumber.class] ||
       preset.integerValue<0 || preset.integerValue>(legacy?8:7)))return nil;
    // Exact ORIGINAL CBMultitaskingOverlayView.presetSelected: @0xaa4f0
    // writes the SAME selected UIButton.tag into splitPreset and splitMode.
    // Preserve this dual-state selection contract in our independent prefs.
    for(NSString *key in @[@"splitPreset",@"splitMode"]){
        id value=record[key];
        if(value && (![value isKindOfClass:NSNumber.class] ||
                     [value integerValue]<0 || [value integerValue]>(legacy?8:7) ||
                     (preset && [value integerValue]!=preset.integerValue)))
            return nil;
    }
    if(!legacy)return record;
    NSInteger originalID=preset?preset.integerValue:([record[@"Vertical"] boolValue]?0:1);
    NSInteger canonical=DFCanonicalPreset(originalID);
    NSMutableDictionary *normalized=[record mutableCopy];
    normalized[@"Version"]=@2;normalized[@"Preset"]=@(canonical);
    normalized[@"splitPreset"]=@(canonical);normalized[@"splitMode"]=@(canonical);
    normalized[@"Secondary"]=@.5;
    normalized[@"Vertical"]=@(DFPrimaryDividerIsVertical(canonical));
    if(![normalized writeToFile:kDFLayoutPath atomically:YES])
        NSLog(@"[DFNative12Chrome] layout migration deferred");
    return normalized;
}
static BOOL DFCSaveLayout(CGFloat ratio, CGFloat secondary, CGFloat logo, BOOL vertical, BOOL swapped, NSInteger preset) {
    if(!isfinite(ratio) || ratio<1.0/3.0 || ratio>2.0/3.0 ||
       !isfinite(logo) || logo<.1 || logo>.9)return NO;
    NSDictionary *record=@{@"Version":@2,@"Ratio":@(ratio),
        @"Secondary":@(secondary),
        @"LogoFraction":@(logo),@"Vertical":@(vertical),@"Swapped":@(swapped),
        @"Preset":@(preset),@"splitPreset":@(preset),@"splitMode":@(preset)};
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
// Native12 CBDividerView.pointInside:withEvent: expands each move-button
// target by 12pt. Do not resize the artwork or route logo holds to ratio pan.
@interface DFNativeDividerGripButton : UIButton
@end
@implementation DFNativeDividerGripButton
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    (void)event;
    if(self.hidden || self.alpha<=0.01)return NO;
    return CGRectContainsPoint(CGRectInset(self.bounds,-12.0,-12.0),point);
}
@end

@interface DFNative12Chrome () <DFAppPickerDelegate, UIGestureRecognizerDelegate>
@property(nonatomic,strong) id display;
@property(nonatomic,assign) Class configurationClass;
@property(nonatomic,assign) Class externalWindowClass;
@property(nonatomic,assign) CGRect contentRect;
@property(nonatomic,copy) DFNative12ChromeCommand callback;
@property(nonatomic,strong) NSMutableArray<UIWindow *> *windows;
@property(nonatomic,strong) NSMutableArray<UIWindow *> *pillWindows;
@property(nonatomic,strong) UIWindow *dividerWindow;
@property(nonatomic,strong) UIWindow *secondaryDividerWindow;
@property(nonatomic,strong) UIWindow *pickerWindow;
@property(nonatomic,strong) UIWindow *styleWindow;
@property(nonatomic,strong) NSArray<UIButton *> *styleChoices;
@property(nonatomic,strong) NSArray<UIButton *> *styleHeaderActions;
@property(nonatomic,strong) UIImageView *styleHeaderLogo;
@property(nonatomic,assign) BOOL styleVisible;
@property(nonatomic,strong) UIWindow *appPickerWindow;
@property(nonatomic,strong) UIWindow *splashWindow;
@property(nonatomic,assign) BOOL startupActive;
@property(nonatomic,assign) NSTimeInterval borderUntil;
@property(nonatomic,assign) NSUInteger borderGeneration;
@property(nonatomic,strong) DFAppPickerVC *appPickerController;
@property(nonatomic,strong) NSMutableArray<UIWindow *> *appSceneWindows;
@property(nonatomic,strong) NSMutableArray *hostedScenes;
@property(nonatomic,strong) NSMutableArray *pendingScenes;
@property(nonatomic,strong) NSMutableArray<NSNumber *> *sceneHandleReady;
@property(nonatomic,strong) UIView *dividerTrack;
@property(nonatomic,strong) UIView *secondaryDividerTrack;
@property(nonatomic,strong) UIButton *dividerLogo;
@property(nonatomic,strong) NSArray<UIButton *> *pillZoom;
@property(nonatomic,strong) NSArray<UIButton *> *pillMenu;
@property(nonatomic,strong) UILabel *pickerBrand;
@property(nonatomic,strong) UIImageView *menuBrandImage;
@property(nonatomic,strong) UILabel *menuContext;
@property(nonatomic,strong) UIButton *menuDismiss;
@property(nonatomic,strong) NSArray<UIButton *> *menuActions;
@property(nonatomic,assign) CGFloat ratio;
@property(nonatomic,assign) CGFloat dragStartRatio;
@property(nonatomic,assign) CGFloat secondaryRatio;
@property(nonatomic,assign) CGFloat dragStartSecondary;
@property(nonatomic,assign) CGPoint secondaryDragStartPoint;
@property(nonatomic,assign) CGPoint dragStartScreenPoint;
@property(nonatomic,assign) CGFloat logoFraction;
@property(nonatomic,assign) BOOL verticalDivider;
@property(nonatomic,assign) NSInteger preset;
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
        _verticalDivider=YES;_focus=-1;_selectedSlot=0;_preset=1;_secondaryRatio=.5;
        NSDictionary *prior=DFCRestoreLayout();
        if(prior){
            _ratio=[prior[@"Ratio"] doubleValue];
            _secondaryRatio=[prior[@"Secondary"] isKindOfClass:NSNumber.class]?
                   DFCClamp([prior[@"Secondary"] doubleValue]):.5;
            _logoFraction=[prior[@"LogoFraction"] doubleValue];
            _verticalDivider=[prior[@"Vertical"] boolValue];
            _swapped=[prior[@"Swapped"] boolValue];
            _preset=prior[@"Preset"]?[prior[@"Preset"] integerValue]:(_verticalDivider?1:2);
            _verticalDivider=DFPrimaryDividerIsVertical(_preset);
        }
        _windows=[NSMutableArray new];_pillWindows=[NSMutableArray new];
        _appSceneWindows=[NSMutableArray new];
        _hostedScenes=[NSMutableArray arrayWithArray:@[[NSNull null],[NSNull null],[NSNull null],[NSNull null]]];
        _pendingScenes=[NSMutableArray arrayWithArray:@[[NSNull null],[NSNull null],[NSNull null],[NSNull null]]];
        _sceneHandleReady=[NSMutableArray arrayWithArray:@[@NO,@NO,@NO,@NO]];
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
    self.startupActive=YES;
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(sceneReady:) name:DFSceneHostDidBecomeReadyNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(sceneFailed:) name:DFSceneHostDidFailNotification object:nil];
    CGRect cr=self.contentRect;
    if(!isfinite(cr.origin.x)||!isfinite(cr.origin.y)||
       CGRectGetWidth(cr)<300||CGRectGetHeight(cr)<145)return NO;
    NSMutableArray *menus=[NSMutableArray new],*zooms=[NSMutableArray new];
    for(NSInteger slot=0;slot<4;slot++) {
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
    // The real split boundary must remain perceptible without painting
    // a permanent red/green status outline around playing apps.
    line.backgroundColor=[UIColor colorWithWhite:1 alpha:.24];
    line.userInteractionEnabled=NO;
    [root.view addSubview:line];
    UIPanGestureRecognizer *trackPan=[[UIPanGestureRecognizer alloc]
                             initWithTarget:self action:@selector(dividerPan:)];
    trackPan.maximumNumberOfTouches=1;
    // A touch starting on the logo is owned by its tap/hold/early-pan
    // recognizers. The parent divider pan must not consume that touch.
    trackPan.delegate=self;
    [self.dividerTrack addGestureRecognizer:trackPan];
    UIButton *logo=[[DFNativeDividerGripButton alloc]initWithFrame:CGRectZero];
    logo.backgroundColor=UIColor.clearColor;
    [logo addTarget:self action:@selector(swapPressed:)
              forControlEvents:UIControlEventTouchUpInside];
    logo.titleLabel.font=[UIFont boldSystemFontOfSize:23];
    // The 120x120 reference swap bitmap includes an opaque dark square
    // in this asset set. Use the original QA-native vector fallback instead:
    // the divider logo must have no black disk/background on CarPlay.
    [logo setTitle:@"" forState:UIControlStateNormal];
    // Original-approved two-face swap artwork is 120x120 but has opaque
    // square corners. Circular-mask it at the Native12 28/30pt grip size
    // rather than shipping a dark square over live app content.
    UIImage *smallArt=DFCArtwork(@"duoface-swap");
    UIImage *arrow=smallArt?
        [smallArt imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]:
        [[UIImage systemImageNamed:@"arrow.left.arrow.right"]
            imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [logo setImage:arrow forState:UIControlStateNormal];
    logo.tintColor=UIColor.whiteColor;
    logo.layer.masksToBounds=YES;
    logo.imageView.contentMode=UIViewContentModeScaleAspectFit;
    logo.accessibilityLabel=@"Thanh chia DuoFace";
    [root.view addSubview:logo];
    UILongPressGestureRecognizer *hold=[[UILongPressGestureRecognizer alloc]
                                  initWithTarget:self action:@selector(logoHold:)];
    hold.minimumPressDuration=3.0;
    // Current user override: hold the logo for three full seconds before moving.
    // Once recognized, drag along the divider only; short tap still swaps.
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
    // Original three-pane kinds have a second independently movable boundary.
    UIViewController *secondRoot=[self emptyRoot:divider];
    self.secondaryDividerTrack=secondRoot.view;
    UIView *secondLine=[UIView new];
    secondLine.tag=719;
    secondLine.backgroundColor=[UIColor colorWithWhite:1 alpha:.24];
    secondLine.userInteractionEnabled=NO;
    [self.secondaryDividerTrack addSubview:secondLine];
    UIPanGestureRecognizer *secondaryPan=[[UIPanGestureRecognizer alloc]
             initWithTarget:self action:@selector(secondaryDividerPan:)];
    secondaryPan.maximumNumberOfTouches=1;
    [self.secondaryDividerTrack addGestureRecognizer:secondaryPan];
    self.secondaryDividerWindow=[self makeWindow:divider root:secondRoot level:2];
    if(!self.secondaryDividerWindow){[self stop];return NO;}
    // Keep the action menu inside the selected split pane rather than
    // covering the whole dual-app display as a centered 470pt sheet.
    CGFloat pw=MIN(470,MAX(180,cr.size.width-16));
    CGFloat ph=MIN(280,MAX(140,cr.size.height-16));
    CGRect picker=CGRectMake(CGRectGetMidX(cr)-pw/2,CGRectGetMidY(cr)-ph/2,pw,ph);
    UIViewController *pc=[self emptyRoot:picker];
    UIView *sheet=pc.view;
    sheet.backgroundColor=UIColor.clearColor;
    sheet.layer.cornerRadius=20;
    sheet.layer.borderWidth=0;
    sheet.layer.masksToBounds=YES;
    UIVisualEffectView *nativeMaterial=[[UIVisualEffectView alloc] initWithEffect:
        [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark]];
    nativeMaterial.frame=sheet.bounds;
    nativeMaterial.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    nativeMaterial.userInteractionEnabled=NO;
    [sheet addSubview:nativeMaterial];
    UIImage *horizontal=DFCArtwork(@"duoface-logo-picker-alpha-v2");
    UIImageView *brandImage=[[UIImageView alloc]initWithImage:horizontal];
    brandImage.contentMode=UIViewContentModeScaleAspectFit;
    brandImage.frame=CGRectMake(8,7,MIN(120,pw*.25),30);
    brandImage.userInteractionEnabled=NO;
    [sheet addSubview:brandImage];self.menuBrandImage=brandImage;
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
    NSMutableArray<UIButton *> *actions=[NSMutableArray new];
    // Native12-approved 30pt ONE row; logo, App, Zoom, Style, Close.
    const CGFloat widths[4]={43,51,47,51};
    CGFloat logoW=MIN(120,MAX(65,pw*.25));
    CGFloat scale=MIN(1.0,MAX(.58,(pw-logoW-68)/192));
    CGFloat bx=8+logoW+5;
    for(NSInteger i=0;i<4;i++){
        UIButton *b=[self button:names[(NSUInteger)i] tag:i
                         action:@selector(menuAction:)];
        b.frame=CGRectMake(bx,7,widths[i]*scale,30);
        bx+=widths[i]*scale;
        UIImage *img=[UIImage systemImageNamed:symbols[(NSUInteger)i]];
        [b setImage:img forState:UIControlStateNormal];
        b.tintColor=UIColor.whiteColor;
        b.titleLabel.font=[UIFont systemFontOfSize:10];
        if(@available(iOS 15,*)){
            UIButtonConfiguration *conf=[UIButtonConfiguration plainButtonConfiguration];
            conf.title=names[(NSUInteger)i];
            conf.image=img;
            conf.imagePlacement=NSDirectionalRectEdgeTop;
            conf.imagePadding=1;
            b.configuration=conf;
        }
        [sheet addSubview:b];[actions addObject:b];
    }
    self.menuActions=actions;
    UILabel *hint=[UILabel new];
    hint.text=@"Ô trái · App · Zoom · Style · Close";
    hint.font=[UIFont systemFontOfSize:9];
    hint.textColor=[UIColor colorWithWhite:.8 alpha:1];
    hint.textAlignment=NSTextAlignmentCenter;
    hint.frame=CGRectMake(8,MIN(ph-25,52),pw-16,19);
    [sheet addSubview:hint];self.menuContext=hint;
    UIButton *dismiss=[self button:@"×" tag:0 action:@selector(closeMenu:)];
    dismiss.frame=CGRectMake(pw-42,9,32,26);
    [sheet addSubview:dismiss];self.menuDismiss=dismiss;
    self.pickerWindow=[self makeWindow:picker root:pc level:3];
    if(!self.pickerWindow){[self stop];return NO;}
    // Native12-inspired Style gallery: explicit selectable split arrangements,
    // not the old invisible preset++ on each press. Miniatures are geometry
    // previews only (DFLayoutEngine), NOT simulated embedded applications.
    CGFloat styleW=MIN(cr.size.width-12,470);
    CGFloat styleH=MIN(cr.size.height-8,220);
    CGRect styleRect=CGRectMake(CGRectGetMidX(cr)-styleW/2,
                                  CGRectGetMidY(cr)-styleH/2,styleW,styleH);
    UIViewController *styleRoot=[self emptyRoot:styleRect];
    UIView *styleSheet=styleRoot.view;
    styleSheet.backgroundColor=UIColor.clearColor;
    styleSheet.layer.cornerRadius=20;
    styleSheet.layer.borderWidth=0;
    styleSheet.layer.masksToBounds=YES;
    UIVisualEffectView *styleMaterial=[[UIVisualEffectView alloc] initWithEffect:
        [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark]];
    styleMaterial.frame=styleSheet.bounds;
    styleMaterial.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    styleMaterial.userInteractionEnabled=NO;
    [styleSheet addSubview:styleMaterial];
    // Style is the second page of the SAME Native12 30pt picker header,
    // not an invented screen with unrelated stacked headings.
    UIImageView *styleLogo=[[UIImageView alloc]initWithImage:horizontal];
    styleLogo.contentMode=UIViewContentModeScaleAspectFit;
    styleLogo.frame=CGRectMake(8,7,MIN(120,styleW*.25),30);
    styleLogo.userInteractionEnabled=NO;
    [styleSheet addSubview:styleLogo];
    self.styleHeaderLogo=styleLogo;
    NSMutableArray<UIButton *> *styleTabs=[NSMutableArray new];
    const CGFloat styleTabWidths[4]={43,51,47,51};
    CGFloat styleBX=8+MIN(120,MAX(65,styleW*.25))+5;
    CGFloat styleScale=MIN(1.0,MAX(.58,(styleW-MIN(120,MAX(65,styleW*.25))-68)/192));
    for(NSInteger tab=0;tab<4;tab++){
        UIButton *action=[self button:names[(NSUInteger)tab] tag:tab
                      action:@selector(menuAction:)];
        action.frame=CGRectMake(styleBX,7,styleTabWidths[tab]*styleScale,30);
        styleBX+=styleTabWidths[tab]*styleScale;
        UIImage *icon=[UIImage systemImageNamed:symbols[(NSUInteger)tab]];
        [action setImage:icon forState:UIControlStateNormal];
        if(@available(iOS 15,*)){
            UIButtonConfiguration *config=[UIButtonConfiguration plainButtonConfiguration];
            config.title=names[(NSUInteger)tab];
            config.image=icon;
            config.imagePlacement=NSDirectionalRectEdgeTop;
            config.imagePadding=1;
            action.configuration=config;
        }
        action.titleLabel.font=[UIFont systemFontOfSize:10];
        [styleSheet addSubview:action];
        [styleTabs addObject:action];
    }
    self.styleHeaderActions=styleTabs;
    UIButton *dismissStyle=[self button:@"×" tag:0 action:@selector(closeStylePicker:)];
    dismissStyle.frame=CGRectMake(styleW-42,9,32,26);
    [styleSheet addSubview:dismissStyle];
    NSArray<NSString *> *styleNames=@[@"Một khung",@"Trái / phải",
         @"Trên / dưới",@"Ba cột",@"Một trái, hai phải",
         @"Hai trái, một phải",@"Một trên, hai dưới",@"Hai trên, một dưới"];
    NSMutableArray<UIButton *> *choices=[NSMutableArray new];
    CGFloat styleCellWidth=(styleW-24)/4;
    CGFloat styleCellHeight=(styleH-54)/2;
    for(NSInteger idx=0;idx<8;idx++){
        UIButton *button=[self button:@"" tag:idx action:@selector(selectStylePreset:)];
        button.frame=CGRectMake(6+(idx%4)*(styleCellWidth+4),
               46+(idx/4)*styleCellHeight,styleCellWidth,MAX(26,styleCellHeight-4));
        button.layer.cornerRadius=7;
        button.layer.borderWidth=1;
        button.layer.borderColor=[UIColor colorWithWhite:1 alpha:.26].CGColor;
        button.backgroundColor=[UIColor colorWithWhite:1 alpha:.08];
        button.accessibilityLabel=styleNames[(NSUInteger)idx];
        CGFloat thumbW=MIN(45,styleCellWidth*.40);
        CGFloat thumbH=MIN(23,styleCellHeight-10);
        UIView *thumb=[[UIView alloc] initWithFrame:CGRectMake(7,
                  (CGRectGetHeight(button.frame)-thumbH)/2,thumbW,thumbH)];
        thumb.backgroundColor=[UIColor colorWithWhite:1 alpha:.05];
        thumb.layer.borderWidth=.6;
        thumb.layer.borderColor=[UIColor colorWithWhite:1 alpha:.5].CGColor;
        thumb.userInteractionEnabled=NO;
        CGRect regions[4];
        DFComputePresetFramesWithSecondary(CGRectMake(0,0,thumbW,thumbH),idx,.5,.5,regions);
        for(NSInteger slot=0;slot<DFSlotCountForPreset(idx);slot++){
            CGRect region=CGRectInset(regions[slot],.7,.7);
            if(CGRectIsNull(region)||CGRectIsEmpty(region))continue;
            UIView *segment=[[UIView alloc]initWithFrame:region];
            segment.backgroundColor=[UIColor colorWithWhite:1 alpha:.43];
            segment.userInteractionEnabled=NO;
            [thumb addSubview:segment];
        }
        [button addSubview:thumb];
        UILabel *desc=[[UILabel alloc] initWithFrame:CGRectMake(
              thumbW+11,0,styleCellWidth-thumbW-15,CGRectGetHeight(button.frame))];
        desc.text=styleNames[(NSUInteger)idx];
        desc.font=[UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
        desc.textColor=UIColor.whiteColor;
        desc.numberOfLines=2;
        desc.userInteractionEnabled=NO;
        [button addSubview:desc];
        [styleSheet addSubview:button];
        [choices addObject:button];
    }
    self.styleChoices=choices;
    self.styleWindow=[self makeWindow:styleRect root:styleRoot level:4];
    if(!self.styleWindow){[self stop];return NO;}
    // Two REAL app-scene containers from SpringBoard, created but kept
    // hidden until a user explicitly selects an installed application.
    // Do not claim "APP scene ready" just because the external window exists.
    for(NSInteger i=0;i<4;i++){
        CGRect rect=CGRectMake(cr.origin.x,cr.origin.y,MAX(30,cr.size.width/4),cr.size.height);
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
    // Show genuine DuoFace horizontal logo and animated progress BEFORE chrome.
    // One source-owned SpringBoard presentation; controls cannot pre-empt launch.
    UIViewController *launch=[self emptyRoot:cr];
    launch.view.backgroundColor=UIColor.blackColor;
    UIImageView *startupLogo=[[UIImageView alloc]initWithImage:DFCArtwork(@"duoface-logo")];
    startupLogo.contentMode=UIViewContentModeScaleAspectFit;
    CGFloat lw=MIN(cr.size.width*.7,310),lh=lw/4.;
    startupLogo.frame=CGRectMake((cr.size.width-lw)/2,cr.size.height*.35-lh/2,lw,lh);
    [launch.view addSubview:startupLogo];
    UILabel *motto=[UILabel new];
    motto.text=@"TWO FACES ONE SCREEN";
    motto.font=[UIFont systemFontOfSize:10 weight:UIFontWeightSemibold];
    motto.textColor=UIColor.whiteColor;
    motto.textAlignment=NSTextAlignmentCenter;
    motto.frame=CGRectMake(5,CGRectGetMaxY(startupLogo.frame)+4,cr.size.width-10,18);
    [launch.view addSubview:motto];
    CGFloat barWidth=MIN(cr.size.width*.58,240);
    UIView *track=[[UIView alloc]initWithFrame:CGRectMake((cr.size.width-barWidth)/2,
                     CGRectGetMaxY(motto.frame)+14,barWidth,3)];
    track.backgroundColor=[UIColor colorWithWhite:.26 alpha:1];
    track.layer.cornerRadius=1.5;
    track.clipsToBounds=YES;
    [launch.view addSubview:track];
    CALayer *fill=[CALayer layer];
    fill.anchorPoint=CGPointMake(0,.5);
    fill.position=CGPointMake(0,1.5);
    fill.bounds=CGRectMake(0,0,barWidth,3);
    fill.backgroundColor=[UIColor colorWithRed:227./255 green:2./255 blue:15./255 alpha:1].CGColor;
    [track.layer addSublayer:fill];
    CABasicAnimation *load=[CABasicAnimation animationWithKeyPath:@"bounds.size.width"];
    load.fromValue=@0;
    load.toValue=@(barWidth);
    load.duration=1.25;
    load.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [fill addAnimation:load forKey:@"duoface-native-loading-line"];
    self.splashWindow=[self makeWindow:cr root:launch level:5];
    if(!self.splashWindow){[self stop];return NO;}
    [self layoutControls];
    self.splashWindow.hidden=NO;
    __weak typeof(self) weakOwner=self;
    UIWindow *initial=self.splashWindow;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(1.3*NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
       DFNative12Chrome *owner=weakOwner;
       if(!owner || !owner.startupActive || owner.splashWindow!=initial)return;
       [UIView animateWithDuration:.2 animations:^{initial.alpha=0;}
           completion:^(BOOL finished){
               (void)finished;
               if(!owner || !owner.startupActive || owner.splashWindow!=initial)return;
               owner.startupActive=NO;
               initial.hidden=YES;
               [owner layoutControls];
               DFCLog(@"native12-logo-and-loading-line-completed");
           }];
    });
    DFCLog([NSString stringWithFormat:
        @"native12-chrome-start windows=%lu content=%@",
        (unsigned long)self.windows.count,NSStringFromCGRect(cr)]);
    return YES;
}
// Original Native12 separates logo hit/long-press from divider ratio pan.
// Give the move-button its +/-12pt touch slop (within the bounded window)
// without letting the parent track's pan steal the same touch sequence.
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch:(UITouch *)touch {
    if(gestureRecognizer.view!=self.dividerTrack || !self.dividerLogo)return YES;
    CGPoint p=[touch locationInView:self.dividerTrack];
    CGRect logoHit=CGRectInset(self.dividerLogo.frame,-12.0,-12.0);
    return !CGRectContainsPoint(logoHit,p);
}
- (void)noteUserActivity {
    self.borderUntil=NSDate.date.timeIntervalSince1970+2.0;
    NSUInteger seq=++self.borderGeneration;
    [self layoutControls];
    __weak typeof(self) weakOwner=self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(2.1*NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        DFNative12Chrome *owner=weakOwner;
        if(owner && owner.borderGeneration==seq){
            owner.borderUntil=0;
            [owner layoutControls];
        }
    });
}
- (NSDictionary<NSString *,id> *)stateSnapshot {
    // A post-action observation of REAL owned scenes and layout; never
    // fabricated from the command being reported to the CarPlay process.
    NSInteger running=0,pending=0;
    for(id view in self.hostedScenes)if(view!=[NSNull null])running++;
    for(id view in self.pendingScenes)if(view!=[NSNull null])pending++;
    return @{
        @"Version":@2,
        @"Ratio":@(self.ratio),
        @"Vertical":@(self.verticalDivider),
        @"Swapped":@(self.swapped),
        @"Focus":@(self.focus),
        @"SelectedSlot":@(self.selectedSlot),
        @"PickerVisible":@(self.pickerVisible),
        @"StylePickerVisible":@(self.styleVisible),
        @"StartupActive":@(self.startupActive),
        @"RunningScenes":@(running),
        @"PendingScenes":@(pending),
        @"SlotCount":@(self.hostedScenes.count),
        @"ActiveSlots":@(DFSlotCountForPreset(self.preset)),
        @"Preset":@(self.preset),
        @"SplitPreset":@(self.preset),
        @"SplitMode":@(self.preset),
        @"Owner":@"SpringBoard",
    };
}
- (void)emit:(NSString *)action ratio:(NSNumber *)ratio {
    if(!self.callback)return;
    self.callback(action,ratio);
}
- (BOOL)applyLayoutSettingsFromDisk {
    NSDictionary *saved=DFCRestoreLayout();
    if(!saved)return NO;
    NSInteger preset=saved[@"Preset"]?[saved[@"Preset"] integerValue]:
       ([saved[@"Vertical"] boolValue]?0:1);
    if(preset<0 || preset>7)return NO;
    // This changes the actual scene geometry and survives a reconnect.
    // Never release the two previously running real apps when switching to
    // three/four slots; merely hide inactive containers and restore later.
    self.preset=preset;
    self.ratio=[saved[@"Ratio"] doubleValue];
    self.secondaryRatio=[saved[@"Secondary"] isKindOfClass:NSNumber.class]?
           DFCClamp([saved[@"Secondary"] doubleValue]):.5;
    self.logoFraction=[saved[@"LogoFraction"] doubleValue];
    self.swapped=[saved[@"Swapped"] boolValue];
    self.verticalDivider=DFPrimaryDividerIsVertical(self.preset);
    NSInteger active=DFSlotCountForPreset(preset);
    self.selectedSlot=MIN(self.selectedSlot,active-1);
    if(self.focus>=active)self.focus=-1;
    self.pickerVisible=NO;
    self.styleVisible=NO;
    self.appPickerWindow.hidden=YES;
    [self layoutControls];
    [self emit:@"Style" ratio:nil];
    DFCLog([NSString stringWithFormat:@"live-preset-updated preset=%ld slots=%ld",
             (long)preset,(long)active]);
    return YES;
}
- (void)saveSplitState {
    if(!DFCSaveLayout(self.ratio,self.secondaryRatio,self.logoFraction,
                      self.verticalDivider,self.swapped,self.preset))
        DFCLog(@"split-layout-persist-failed");
}
// Position real App/Zoom/Style/Close controls in the pane whose ellipsis
// was touched. The same menu HWND and button handlers are reused for both.
- (void)layoutContextMenuForPane:(CGRect)pane {
    if(!self.pickerWindow || CGRectIsNull(pane) || CGRectIsEmpty(pane))return;
    CGRect cr=self.contentRect;
    CGFloat width=MIN(470,MAX(180,cr.size.width-16));
    CGFloat height=MIN(280,MAX(140,cr.size.height-16));
    CGFloat x=MAX(CGRectGetMinX(cr)+4,MIN(CGRectGetMidX(pane)-width/2,
                                          CGRectGetMaxX(cr)-width-4));
    CGFloat y=MAX(CGRectGetMinY(cr)+4,MIN(CGRectGetMidY(pane)-height/2,
                                          CGRectGetMaxY(cr)-height-4));
    self.pickerWindow.frame=CGRectMake(x,y,width,height);
    UIView *sheet=self.pickerWindow.rootViewController.view;
    sheet.frame=CGRectMake(0,0,width,height);
    const CGFloat widths[4]={43,51,47,51};
    CGFloat logoW=MIN(120,MAX(65,width*.25));
    CGFloat scale=MIN(1.0,MAX(.58,(width-logoW-68)/192));
    CGFloat bx=8+logoW+5;
    for(NSUInteger i=0;i<self.menuActions.count;i++){
        self.menuActions[i].frame=CGRectMake(bx,7,widths[i]*scale,30);
        bx+=widths[i]*scale;
    }
    CGRect brandFrame=CGRectMake(8,7,logoW,30);
    self.menuBrandImage.frame=brandFrame;
    self.pickerBrand.frame=brandFrame;
    self.menuDismiss.frame=CGRectMake(width-42,9,32,26);
    NSString *region=[NSString stringWithFormat:@"%ld",(long)self.selectedSlot+1];
    if(self.preset==1 && self.selectedSlot<2)
        region=self.selectedSlot==0?@"trái":@"phải";
    else if(self.preset==2 && self.selectedSlot<2)
        region=self.selectedSlot==0?@"trên":@"dưới";
    self.menuContext.text=[NSString stringWithFormat:
        @"Ô %@ · App · Zoom · Style · Close",region];
    self.menuContext.frame=CGRectMake(8,MIN(height-25,52),width-16,19);
}
- (void)layoutControls {
    CGRect cr=self.contentRect;
    for(UIButton *choice in self.styleChoices){
        BOOL selected=(choice.tag==self.preset);
        choice.layer.borderWidth=selected?1.6:1;
        choice.layer.borderColor=(selected?
           [UIColor colorWithRed:227./255 green:2./255 blue:15./255 alpha:1]:
           [UIColor colorWithWhite:1 alpha:.26]).CGColor;
        choice.accessibilityValue=selected?@"Đang chọn":@"Chọn kiểu";
    }
    CGFloat p=DFCClamp(self.ratio);
    CGRect pane[4];
    DFComputePresetFramesWithSecondary(cr,self.preset,p,self.secondaryRatio,pane);
    NSInteger activeSlots=DFSlotCountForPreset(self.preset);
    if(self.focus>=0 && self.focus<activeSlots)pane[self.focus]=cr;
    NSInteger menuSlot=MAX(0,MIN(activeSlots-1,self.selectedSlot));
    [self layoutContextMenuForPane:pane[menuSlot]];
    for(NSInteger i=0;i<4;i++) {
        UIWindow *w=self.pillWindows[(NSUInteger)i];
        if(i>=activeSlots){w.hidden=YES;continue;}
        // Reproduce Native12 six pill states from DFSPNativeSlotPill:
        // empty/loaded/focused, each normal or compact. An empty or
        // pending slot must not offer a nonfunctional fullscreen action.
        NSInteger physicalSlot=(self.swapped && i<2)?1-i:i;
        BOOL ready=[self.sceneHandleReady[(NSUInteger)physicalSlot] boolValue];
        BOOL focused=(self.focus==i);
        BOOL show=(self.focus<0 || focused)&&!self.pickerVisible&&!self.styleVisible;
        CGFloat compact=(pane[i].size.width<320||pane[i].size.height<220);
        // Two split-pane controls must be usable before a scene is loaded.
        // Pressing Zoom on an empty pane opens the actual installed app picker.
        CGFloat width=focused?(compact?72:80):(compact?64:76);
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
        menu.frame=CGRectMake(0,0,focused?0:width/2,height);
        zoom.frame=CGRectMake(CGRectGetMaxX(menu.frame),0,
                              width-CGRectGetMaxX(menu.frame),height);
        menu.hidden=focused;
        // Never silently hide the second button in an empty/pending pane.
        zoom.hidden=NO;
        zoom.accessibilityLabel=ready?@"Zoom ứng dụng":@"Chọn ứng dụng để dùng Zoom";
        UIImage *icon=[UIImage systemImageNamed:self.focus==i?
             @"arrow.down.right.and.arrow.up.left":
             @"arrow.up.left.and.arrow.down.right"];
        [zoom setImage:icon forState:UIControlStateNormal];
        w.hidden=(!show||self.startupActive);
    }
    // Source-owned ratio boundary, not maxX/Y of the first app. In preset 7
    // the left side is TWO real strips: pane[0] ends at ratio/2, not ratio.
    CGFloat boundary=DFPrimaryDividerCoordinate(cr,self.preset,p);
    CGRect tr=self.verticalDivider?
        CGRectMake(boundary-16,cr.origin.y+2,32,cr.size.height-4):
        CGRectMake(cr.origin.x+2,boundary-16,cr.size.width-4,32);
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
    self.dividerLogo.layer.cornerRadius=size/2;
    self.dividerWindow.hidden=(self.startupActive||activeSlots==1||self.focus>=0||self.pickerVisible||self.styleVisible);
    CGRect second=DFSecondaryDividerRect(cr,self.preset,p,self.secondaryRatio);
    if(!CGRectIsNull(second)){
        BOOL vertical=DFSecondaryDividerIsVertical(self.preset);
        CGRect sf=vertical?
          CGRectMake(second.origin.x-16,second.origin.y+2,32,MAX(18,second.size.height-4)):
          CGRectMake(second.origin.x+2,second.origin.y-16,MAX(18,second.size.width-4),32);
        self.secondaryDividerWindow.frame=sf;
        self.secondaryDividerTrack.frame=(CGRect){CGPointZero,sf.size};
        UIView *stroke=[self.secondaryDividerTrack viewWithTag:719];
        stroke.frame=vertical?CGRectMake(15,0,2,sf.size.height):
                              CGRectMake(0,15,sf.size.width,2);
    }
    self.secondaryDividerWindow.hidden=(self.startupActive||activeSlots<3||
        self.focus>=0||self.pickerVisible||self.styleVisible||CGRectIsNull(second));
    self.pickerWindow.hidden=(self.startupActive||!self.pickerVisible);
    self.styleWindow.hidden=(self.startupActive||!self.styleVisible);
    for(NSInteger i=0;i<4;i++){
        UIWindow *appWindow=self.appSceneWindows[(NSUInteger)i];
        NSInteger visualSlot=(self.swapped && i<2)?1-i:i;
        if(visualSlot>=activeSlots){appWindow.hidden=YES;continue;}
        CGRect target=pane[visualSlot];
        if(self.focus>=0 && visualSlot==self.focus)target=cr;
        appWindow.frame=target;
        UIView *v=appWindow.rootViewController.view;
        v.frame=CGRectMake(0,0,target.size.width,target.size.height);
        for(UIView *child in v.subviews)child.frame=v.bounds;
        // Native12 keeps genuine app scenes visible BEHIND the App/Style
        // sheet and picker. A modal must never detach/suspend both scenes.
        BOOL loaded=([self.sceneHandleReady[(NSUInteger)i] boolValue] &&
                     self.hostedScenes[(NSUInteger)i]!=NSNull.null);
        BOOL negotiating=(self.pendingScenes[(NSUInteger)i]!=NSNull.null);
        // A pane is still a *real, empty app container* before the user
        // selects an installed application. Hiding both windows when empty
        // made the screen look like a single, unimplemented CarPlay page.
        // Preserve the same UIWindow/UIView for pending and loaded scenes:
        // no demo tiles, labels or invented app content.
        BOOL focusedElsewhere=(self.focus>=0 && self.focus!=visualSlot);
        appWindow.hidden=(self.startupActive || focusedElsewhere);
        // An empty/negotiating window must NEVER steal input from the native
        // CarPlay UI. Only a proven ready app may receive gestures in a slot.
        appWindow.userInteractionEnabled=loaded;
        // Native12 policy: a faint neutral outline identifies EMPTY panes;
        // a RED outline appears only briefly after a real user action; a
        // loaded pane never retains a permanent border while playing media.
        BOOL splitVisible=(!self.startupActive && self.focus<0);
        BOOL touched=(splitVisible && !self.pickerVisible &&
                     NSDate.date.timeIntervalSince1970<self.borderUntil);
        BOOL empty=(!loaded && !negotiating);
        v.layer.borderWidth=splitVisible?(touched?1.0:(empty?0.75:0.0)):0.0;
        v.layer.borderColor=(touched?
          [UIColor colorWithRed:227./255 green:2./255 blue:15./255 alpha:1]:
          [UIColor colorWithWhite:1 alpha:.25]).CGColor;
        v.layer.cornerRadius=10;
    }
}
- (void)pillPressed:(UIButton *)sender {
    [self noteUserActivity];
    self.selectedSlot=sender.tag;
    self.styleVisible=NO;
    self.pickerVisible=YES;
    [self layoutControls];
    DFCLog([NSString stringWithFormat:@"picker-open slot=%ld",(long)sender.tag]);
}
- (void)closeMenu:(id)sender {
    (void)sender;
    self.pickerVisible=NO;[self layoutControls];
}
- (void)closeStylePicker:(id)sender {
    (void)sender;
    self.styleVisible=NO;
    [self layoutControls];
}
- (void)openStylePicker {
    self.pickerVisible=NO;
    self.appPickerWindow.hidden=YES;
    self.styleVisible=YES;
    [self layoutControls];
    DFCLog([NSString stringWithFormat:@"style-choices-visible selected=%ld",(long)self.preset]);
}
- (void)selectStylePreset:(UIButton *)sender {
    NSInteger selected=sender.tag;
    if(!self.styleVisible || selected<0 || selected>7)return;
    [self noteUserActivity];
    // Entering Solo uses one real hosted scene. Preserve which two-pane
    // app the user selected (including an existing left/right swap) rather
    // than unexpectedly showing the other side on the single full pane.
    if(selected==0 && (self.preset==1 || self.preset==2) && self.selectedSlot==1)
        self.swapped=!self.swapped;
    self.preset=selected;
    // As Native12's approved setLayout: does, reset the initial ratio on
    // an explicit Style change. Dragged ratios remain persisted for reconnect
    // and are NOT reset by layoutControls/Zoom/scene resize.
    self.ratio=DFNative12DefaultPrimaryRatio(selected);
    self.secondaryRatio=DFNative12DefaultSecondaryRatio(selected);
    self.verticalDivider=DFPrimaryDividerIsVertical(self.preset);
    self.focus=-1;
    self.selectedSlot=MIN(self.selectedSlot,DFSlotCountForPreset(self.preset)-1);
    self.styleVisible=NO;
    [self saveSplitState];
    [self emit:@"Style" ratio:nil];
    [self layoutControls];
    DFCLog([NSString stringWithFormat:@"style-preset-selected preset=%ld slots=%ld",
           (long)selected,(long)DFSlotCountForPreset(selected)]);
}
- (void)zoomPressed:(UIButton *)sender {
    [self noteUserActivity];
    NSInteger slot=sender.tag;
    if(slot<0 || slot>=DFSlotCountForPreset(self.preset))return;
    NSInteger physical=(self.swapped && slot<2)?1-slot:slot;
    // An unloaded scene cannot be focused. Respond by allowing selection of
    // a real app, not by silently ignoring the visible Zoom action.
    if(self.focus!=slot && ![self.sceneHandleReady[(NSUInteger)physical] boolValue]){
        self.selectedSlot=slot;
        [self openAppPickerForSlot:slot];
        DFCLog([NSString stringWithFormat:@"zoom-requires-real-app slot=%ld picker-opened",(long)slot]);
        return;
    }
    self.focus=(self.focus==slot)?-1:slot;
    [self emit:self.focus<0?@"Restore":(self.focus==0?@"FocusLeft":self.focus==1?@"FocusRight":self.focus==2?@"FocusSlot2":@"FocusSlot3")
         ratio:nil];
    [self layoutControls];
}
- (void)menuAction:(UIButton *)sender {
    [self noteUserActivity];
    [self closeMenu:nil];
    self.styleVisible=NO;
    [self layoutControls];
    switch(sender.tag){
      case 0:[self openAppPickerForSlot:self.selectedSlot];break;
      case 1:{
             // Native12 global Zoom is not the same as per-pane focus.
             // Forward through the existing session owner, never forge Dock.
             [self emit:@"Zoom" ratio:nil];
             DFCLog(@"native12-global-zoom-owner-ack-pending");
             break;
      }
      case 2:[self openStylePicker];break;
      case 3:[self closeHostedSlot:self.selectedSlot];break;
      default:break;
    }
}
- (void)openAppPickerForSlot:(NSInteger)slot {
    if(slot<0 || slot>=DFSlotCountForPreset(self.preset))return;
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
    NSInteger physicalSlot=(self.swapped && slot<2)?1-slot:slot;
    if(physicalSlot<0 || physicalSlot>=DFSlotCountForPreset(self.preset))return;
    DFSceneHost *owner=[DFSceneHost sharedHost];
    UIView *active=self.hostedScenes[(NSUInteger)physicalSlot];
    UIView *pending=self.pendingScenes[(NSUInteger)physicalSlot];
    NSString *activeID=[active isKindOfClass:UIView.class]?
         [owner bundleIDForHostedView:active]:nil;
    if([activeID isEqualToString:bundleID]){
        self.appPickerWindow.hidden=YES;
        [self layoutControls];
        DFCLog([NSString stringWithFormat:@"replace-same-app-noop slot=%ld bundle=%@",
            (long)slot,bundleID]);return;
    }
    if([pending isKindOfClass:UIView.class]){
        [owner releaseHostedView:pending];
        self.pendingScenes[(NSUInteger)physicalSlot]=NSNull.null;
    }
    NSError *error=nil;
    UIView *host=[owner hostViewForBundleID:bundleID error:&error];
    if(!host){
        DFCLog([NSString stringWithFormat:@"app-host-refused id=%@ reason=%@",
                         bundleID,error.localizedDescription?:@"unknown"]);
        // Old app remains live and visible; allow another real app choice.
        self.appPickerWindow.hidden=NO;
        [self layoutControls];
        return;
    }
    UIWindow *slotWindow=self.appSceneWindows[(NSUInteger)physicalSlot];
    UIView *container=slotWindow.rootViewController.view;
    host.frame=container.bounds;
    host.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    // A transparent pending host must not steal touch input from the
    // still-running application underneath until the new scene is ready.
    host.userInteractionEnabled=NO;
    self.pendingScenes[(NSUInteger)physicalSlot]=host;
    [container addSubview:host];
    self.appPickerWindow.hidden=YES;
    [self layoutControls];
    DFCLog([NSString stringWithFormat:
         @"app-replace-pending-existing-retained slot=%ld bundle=%@ name=%@",
         (long)slot,bundleID,name]);
    // Success is emitted only after sceneReady: confirms the new live scene.
}
- (void)sceneReady:(NSNotification *)note {
    UIView *host=(UIView *)note.object;
    if(![host isKindOfClass:UIView.class])return;
    for(NSInteger i=0;i<4;i++){
       if(self.pendingScenes[(NSUInteger)i]==host){
          // Commit only after the next app has a scene + hosting state.
          UIView *prior=self.hostedScenes[(NSUInteger)i];
          self.pendingScenes[(NSUInteger)i]=NSNull.null;
          self.hostedScenes[(NSUInteger)i]=host;
          self.sceneHandleReady[(NSUInteger)i]=@YES;
          host.userInteractionEnabled=YES;
          [self layoutControls];
          if([prior isKindOfClass:UIView.class] && prior!=host)
              [[DFSceneHost sharedHost] releaseHostedView:prior];
          NSInteger visual=(self.swapped && i<2)?1-i:i;
          [self emit:@"App" ratio:@(visual)];
          DFCLog([NSString stringWithFormat:
              @"scene-replace-committed-render-unverified slot=%ld bundle=%@",
              (long)i,note.userInfo[@"bundleID"]?:@"unknown"]);
          return;
       }
    }
}
- (void)sceneFailed:(NSNotification *)note {
    UIView *host=(UIView *)note.object;
    if(![host isKindOfClass:UIView.class])return;
    for(NSInteger i=0;i<4;i++){
       if(self.pendingScenes[(NSUInteger)i]==host){
          self.pendingScenes[(NSUInteger)i]=NSNull.null;
          DFCLog([NSString stringWithFormat:
            @"scene-replace-rolled-back-old-app-retained slot=%ld error=%@",
            (long)i,note.userInfo[@"error"]?:@"unknown"]);
          [self layoutControls];return;
       }
       if(self.hostedScenes[(NSUInteger)i]==host){
          self.hostedScenes[(NSUInteger)i]=NSNull.null;
          self.sceneHandleReady[(NSUInteger)i]=@NO;
          NSInteger visual=(self.swapped && i<2)?1-i:i;
          if(self.focus==visual)self.focus=-1;
          self.appSceneWindows[(NSUInteger)i].hidden=YES;
          DFCLog([NSString stringWithFormat:@"real-scene-failed slot=%ld error=%@",
                (long)i,note.userInfo[@"error"]?:@"unknown"]);
          [self layoutControls];return;
       }
    }
}
- (void)closeHostedSlot:(NSInteger)slot {
    NSInteger physicalSlot=(self.swapped && slot<2)?1-slot:slot;
    if(physicalSlot<0||physicalSlot>=DFSlotCountForPreset(self.preset))return;
    DFSceneHost *owner=[DFSceneHost sharedHost];
    UIView *pending=self.pendingScenes[(NSUInteger)physicalSlot];
    if([pending isKindOfClass:UIView.class])[owner releaseHostedView:pending];
    self.pendingScenes[(NSUInteger)physicalSlot]=NSNull.null;
    UIView *view=self.hostedScenes[(NSUInteger)physicalSlot];
    if([view isKindOfClass:UIView.class])[owner releaseHostedView:view];
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
    [self noteUserActivity];
    self.swapped=!self.swapped;
    [self saveSplitState];
    [self layoutControls];
    [self emit:@"SWAP" ratio:nil];
    DFCLog(@"swap-button");
}
// The divider window itself is re-framed on every split resize.
// Measure finger displacement in the fixed external UIScreen coordinate space,
// never in the moving dividerTrack or its movable UIWindow. The historical
// Native12/visual12 reference uses a fixed split root for this reason.
- (CGPoint)dividerTouchOnScreen:(UIPanGestureRecognizer *)pan {
    CGPoint local=[pan locationInView:self.dividerTrack];
    id<UICoordinateSpace> screen=self.dividerWindow.screen.coordinateSpace;
    return screen?[self.dividerTrack convertPoint:local toCoordinateSpace:screen]:
                  CGPointMake(NAN,NAN);
}
- (void)dividerPan:(UIPanGestureRecognizer *)pan {
    if(self.pickerVisible||self.focus>=0)return;
    UIGestureRecognizerState state=pan.state;
    if(state==UIGestureRecognizerStateBegan) {
        CGPoint start=[self dividerTouchOnScreen:pan];
        if(!isfinite(start.x)||!isfinite(start.y))return;
        [self noteUserActivity];
        self.dragStartRatio=self.ratio;
        self.dragStartScreenPoint=start;
        self.panActive=YES;
        DFCLog(@"divider-pan-begin");return;
    }
    if(!self.panActive)return;
    BOOL end=state==UIGestureRecognizerStateEnded;
    BOOL cancel=state==UIGestureRecognizerStateCancelled ||
                state==UIGestureRecognizerStateFailed;
    if(state!=UIGestureRecognizerStateChanged && !end && !cancel)return;
    CGPoint current=[self dividerTouchOnScreen:pan];
    if((!isfinite(current.x)||!isfinite(current.y)) && !cancel)return;
    CGFloat displacement=self.verticalDivider?
        current.x-self.dragStartScreenPoint.x:
        current.y-self.dragStartScreenPoint.y;
    CGFloat extent=self.verticalDivider?self.contentRect.size.width:
                                     self.contentRect.size.height;
    if(extent<=0||!isfinite(extent))return;
    CGFloat proposed=self.dragStartRatio+displacement/extent;
    self.ratio=cancel?self.dragStartRatio:(end?DFCSnap(proposed):DFCClamp(proposed));
    [self layoutControls];
    NSTimeInterval now=NSDate.date.timeIntervalSince1970;
    if(end||cancel||now-self.lastSent>.05) {
        self.lastSent=now;[self emit:@"Ratio" ratio:@(self.ratio)];
    }
    if(end||cancel){
        if(end){[self saveSplitState];[self noteUserActivity];}
        self.panActive=NO;DFCLog(end?@"divider-pan-end":@"divider-pan-cancel");
    }
}
// Native12: second divider alters only the secondary split fraction.
// Like the primary divider, measure in fixed UIScreen coordinate space.
- (CGPoint)secondaryTouchOnScreen:(UIPanGestureRecognizer *)pan {
    CGPoint local=[pan locationInView:self.secondaryDividerTrack];
    id<UICoordinateSpace> screen=self.secondaryDividerWindow.screen.coordinateSpace;
    return screen?[self.secondaryDividerTrack convertPoint:local toCoordinateSpace:screen]:
                  CGPointMake(NAN,NAN);
}
- (void)secondaryDividerPan:(UIPanGestureRecognizer *)pan {
    if(self.pickerVisible||self.styleVisible||self.focus>=0||self.preset<3)return;
    UIGestureRecognizerState state=pan.state;
    if(state==UIGestureRecognizerStateBegan){
        CGPoint start=[self secondaryTouchOnScreen:pan];
        if(!isfinite(start.x)||!isfinite(start.y))return;
        self.secondaryDragStartPoint=start;
        self.dragStartSecondary=self.secondaryRatio;
        [self noteUserActivity];
        DFCLog(@"secondary-divider-pan-begin");
        return;
    }
    BOOL end=state==UIGestureRecognizerStateEnded;
    BOOL cancel=state==UIGestureRecognizerStateCancelled ||
                state==UIGestureRecognizerStateFailed;
    if(state!=UIGestureRecognizerStateChanged&&!end&&!cancel)return;
    CGPoint now=[self secondaryTouchOnScreen:pan];
    if((!isfinite(now.x)||!isfinite(now.y))&&!cancel)return;
    BOOL vertical=DFSecondaryDividerIsVertical(self.preset);
    CGFloat delta=vertical?now.x-self.secondaryDragStartPoint.x:
                           now.y-self.secondaryDragStartPoint.y;
    CGFloat extent=vertical?self.contentRect.size.width:self.contentRect.size.height;
    if(self.preset==3)extent*=1-self.ratio;
    if(extent<=0||!isfinite(extent))return;
    CGFloat proposed=self.dragStartSecondary+delta/extent;
    self.secondaryRatio=cancel?self.dragStartSecondary:
           (end?DFCSnap(proposed):DFCClamp(proposed));
    [self layoutControls];
    if(end){[self saveSplitState];[self noteUserActivity];}
    if(end||cancel)DFCLog(end?@"secondary-divider-pan-end":@"secondary-divider-pan-cancel");
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
    self.startupActive=NO;
    ++self.borderGeneration;
    self.borderUntil=0;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.callback=nil;
    [self.appPickerController setDelegate:nil];
    // The Native12 CBWindow destroys/hides chrome at scene deactivation.
    // Hide EVERY SpringBoard window before unloading SBAppViewControllers:
    // scene invalidation can be slow for media apps, and must never leave
    // divider/menu controls drawn over CarPlay Home during that delay.
    for(UIWindow *w in self.windows)w.hidden=YES;
    DFCLog(@"home-teardown-all-external-windows-hidden-before-scene-invalidate");
    [[DFSceneHost sharedHost] stopAllHosts];
    for(UIWindow *w in self.windows)w.rootViewController=nil;
    [self.windows removeAllObjects];
    [self.pillWindows removeAllObjects];
    self.dividerWindow=nil;self.secondaryDividerWindow=nil;self.secondaryDividerTrack=nil;self.pickerWindow=nil;self.styleWindow=nil;self.splashWindow=nil;
    self.styleChoices=nil;self.styleHeaderActions=nil;self.styleHeaderLogo=nil;self.styleVisible=NO;
    self.appPickerWindow=nil;self.appPickerController=nil;
    [self.appSceneWindows removeAllObjects];[self.hostedScenes removeAllObjects];
    [self.pendingScenes removeAllObjects];
    [self.sceneHandleReady removeAllObjects];
    self.dividerTrack=nil;self.dividerLogo=nil;
    self.pillMenu=nil;self.pillZoom=nil;self.pickerBrand=nil;
    self.menuBrandImage=nil;self.menuContext=nil;self.menuDismiss=nil;self.menuActions=nil;
    DFCLog(@"native12-chrome-stop");
}
@end
