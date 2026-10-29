#import "DFDividerDrag.h"
#import "DFLogoHoldGate.h"
#import "DFDeepTrace.h"
#import "DFNative12CardHeaderGeometry.h"
#import "DFNative12GalleryGeometry.h"
#import "DFNative12PresetPreview.h"
#import "DFNative12OuterGeometry.h"
#import "DFNative12MenuHeader.h"
#import "DFNative12Chrome.h"
#import "DFSceneHost.h"
#import "DFAppPickerVC.h"
#import "DFSlotWorkspacePolicy.h"
#import "DFAppLibrary.h"
#import "DFLayoutEngine.h"
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIGestureRecognizerSubclass.h>
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
    const NSInteger map[9]={1,2,4,5,6,7,8,3,0};
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
       preset.integerValue<0 || preset.integerValue>8))return nil;
    // Exact ORIGINAL CBMultitaskingOverlayView.presetSelected: @0xaa4f0
    // writes the SAME selected UIButton.tag into splitPreset and splitMode.
    // Preserve this dual-state selection contract in our independent prefs.
    for(NSString *key in @[@"splitPreset",@"splitMode"]){
        id value=record[key];
        if(value && (![value isKindOfClass:NSNumber.class] ||
                     [value integerValue]<0 || [value integerValue]>8 ||
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
    DFDeepTrace(@"chrome",text);
    NSString *s=[NSString stringWithFormat:@"[DFNative12Chrome] %@\n",text];
    NSLog(@"%@",s);
    int fd=open("/var/mobile/Library/Logs/DuoFaceTouchOwner.log",
                O_WRONLY|O_APPEND|O_CREAT,0644);
    if(fd>=0) {
        NSData *d=[s dataUsingEncoding:NSUTF8StringEncoding];
        (void)write(fd,d.bytes,d.length);close(fd);
    }
}
// Primary divider contacts use immediate axis selection without long press.
// Empty panes in a shared CarPlay UIWindow must pass through unclaimed taps.
@interface DFNativePanePassthroughView : UIView @end
@implementation DFNativePanePassthroughView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit=[super hitTest:point withEvent:event];
    return hit==self?nil:hit;
}
@end
// Native12 expands the real logo target by 12pt. Its raw touch is separate
// from the track's independent split ratio pan; no vendor code is reused.
@interface DFNativeDividerGripButton : UIButton
@property(nonatomic,assign) CGPoint trackedScreenPoint;
@property(nonatomic,assign) BOOL touchTracked;
@property(nonatomic,weak) UITouch *activeTouch;
@property(nonatomic,assign) NSTimeInterval traceStarted;
@property(nonatomic,assign) NSUInteger traceID;
@property(nonatomic,copy) void (^touchBegan)(UIButton *);
@property(nonatomic,copy) void (^touchMoved)(UIButton *);
@property(nonatomic,copy) void (^touchEnded)(UIButton *,BOOL,BOOL);
@end
@implementation DFNativeDividerGripButton
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    (void)event;
    return !self.hidden && self.alpha>0.01 &&
        CGRectContainsPoint(CGRectInset(self.bounds,-12.0,-12.0),point);
}
- (CGPoint)screenPointForTouch:(UITouch *)touch {
    UIWindow *window=self.window;
    if(!window||!window.screen)return CGPointMake(NAN,NAN);
    CGPoint inWindow=[touch locationInView:window];
    id<UICoordinateSpace> screen=window.screen.coordinateSpace;
    return screen?[window convertPoint:inWindow toCoordinateSpace:screen]:inWindow;
}
// The iOS16 CarPlay device delivered a 3.72-second contact but the
// UIButton/UILongPress arbitration lost it. Use ONE UIResponder touch
// owner throughout movement; no super UIControl tracking / recognizers.
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    (void)event;
    if(self.touchTracked)return;
    UITouch *touch=touches.anyObject;
    if(!touch)return;
    self.touchTracked=YES;
    self.activeTouch=touch;
    self.traceStarted=NSProcessInfo.processInfo.systemUptime;
    ++self.traceID;
    self.trackedScreenPoint=[self screenPointForTouch:touch];
    DFDeepTrace(@"logo-control",[NSString stringWithFormat:
        @"raw-began id=%lu at=%@",(unsigned long)self.traceID,
        NSStringFromCGPoint(self.trackedScreenPoint)]);
    if(self.touchBegan)self.touchBegan(self);
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    (void)event;
    UITouch *touch=self.activeTouch;
    if(!self.touchTracked||!touch||![touches containsObject:touch])return;
    self.trackedScreenPoint=[self screenPointForTouch:touch];
    if(self.touchTracked && self.touchMoved)self.touchMoved(self);
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch=self.activeTouch;
    if(!self.touchTracked||!touch||![touches containsObject:touch])return;
    self.trackedScreenPoint=[self screenPointForTouch:touch];
    BOOL inside=[self pointInside:[touch locationInView:self] withEvent:event];
    DFDeepTrace(@"logo-control",[NSString stringWithFormat:
        @"raw-ended id=%lu elapsed=%.6f inside=%d",
        (unsigned long)self.traceID,NSProcessInfo.processInfo.systemUptime-self.traceStarted,inside]);
    if(self.touchEnded)self.touchEnded(self,inside,NO);
    self.touchTracked=NO;
    self.activeTouch=nil;
}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    (void)event;
    UITouch *touch=self.activeTouch;
    if(!self.touchTracked||!touch||![touches containsObject:touch])return;
    DFDeepTrace(@"logo-control",[NSString stringWithFormat:
        @"raw-cancelled id=%lu elapsed=%.6f",
        (unsigned long)self.traceID,NSProcessInfo.processInfo.systemUptime-self.traceStarted]);
    if(self.touchEnded)self.touchEnded(self,NO,YES);
    self.touchTracked=NO;
    self.activeTouch=nil;
}
@end

// Observe activity on our OWN external windows, above the hosted view's
// hitTest implementation. Never recognize/cancel a competing app gesture.
@interface DFNativeActivityObserver : UIGestureRecognizer
@property(nonatomic,copy) void (^activity)(UIWindow *window);
@end
@implementation DFNativeActivityObserver
- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)other {
    (void)other;return NO;
}
- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)other {
    (void)other;return NO;
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    (void)event;
    for(UITouch *touch in touches){
        if(touch.window==self.view && self.activity){self.activity(touch.window);break;}
    }
    // Failure releases other recognizers immediately; this is an observer,
    // not a new tap action or a recognizer that delays YouTube input.
    self.state=UIGestureRecognizerStateFailed;
}
@end

@interface DFNative12Chrome () <DFAppPickerDelegate, UIGestureRecognizerDelegate>
@property(nonatomic,strong) id display;
@property(nonatomic,assign) Class configurationClass;
@property(nonatomic,assign) Class externalWindowClass;
@property(nonatomic,assign) CGRect contentRect;
@property(nonatomic,assign) CGRect normalContentRect;
@property(nonatomic,assign) BOOL hostFullscreen;
@property(nonatomic,copy) DFNative12ChromeCommand callback;
@property(nonatomic,strong) NSMutableArray<UIWindow *> *windows;
@property(nonatomic,strong) NSMutableArray<UIWindow *> *pillWindows;
@property(nonatomic,strong) UIWindow *dividerWindow;
@property(nonatomic,strong) UIWindow *secondaryDividerWindow;
@property(nonatomic,strong) UIWindow *pickerWindow;
@property(nonatomic,strong) UIWindow *styleWindow;
@property(nonatomic,strong) NSArray<UIButton *> *styleChoices;
@property(nonatomic,strong) NSArray<UIImageView *> *styleSelectionBadges;
@property(nonatomic,strong) NSArray<UIButton *> *styleHeaderActions;
@property(nonatomic,strong) UIImageView *styleHeaderLogo;
@property(nonatomic,strong) UILabel *styleHeaderTitle;
@property(nonatomic,strong) UIButton *styleZoom;
@property(nonatomic,strong) UIView *styleModeBar;
@property(nonatomic,assign) BOOL styleVisible;
@property(nonatomic,strong) UIWindow *appPickerWindow;
@property(nonatomic,assign) BOOL appPickerVisible;
@property(nonatomic,strong) UIWindow *splashWindow;
@property(nonatomic,assign) BOOL startupActive;
@property(nonatomic,assign) NSTimeInterval borderUntil;
@property(nonatomic,assign) NSTimeInterval controlsUntil;
@property(nonatomic,assign) NSUInteger borderGeneration;
@property(nonatomic,strong) DFAppPickerVC *appPickerController;
@property(nonatomic,strong) NSMutableArray<UIWindow *> *appSceneWindows;
@property(nonatomic,strong) NSMutableArray<UIView *> *appSceneContainers;
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
@property(nonatomic,assign) CGFloat secondaryRatio;
@property(nonatomic,assign) CGFloat dragStartSecondary;
@property(nonatomic,assign) CGPoint secondaryDragStartPoint;
@property(nonatomic,assign) CGFloat logoFraction;
@property(nonatomic,assign) DFDividerDrag dividerDrag;
@property(nonatomic,assign) DFLogoHoldGate logoHoldGate;
@property(nonatomic,assign) BOOL verticalDivider;
@property(nonatomic,assign) NSInteger preset;
@property(nonatomic,assign) BOOL swapped;
@property(nonatomic,assign) BOOL pickerVisible;
@property(nonatomic,assign) NSInteger focus;
@property(nonatomic,assign) NSInteger selectedSlot;
@property(nonatomic,assign) BOOL panActive;
@property(nonatomic,assign) BOOL logoTouchPending;
@property(nonatomic,assign) BOOL logoWakeOnlyTap;
@property(nonatomic,copy) NSDictionary *workspace;
@property(nonatomic,strong) NSMutableArray<NSNumber *> *restoreQueue;
@property(nonatomic,assign) NSUInteger restoreGeneration;
@property(nonatomic,assign) BOOL restorePending;
@property(nonatomic,assign) NSInteger restoringPhysical;
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
        _normalContentRect=content;_hostFullscreen=NO;
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
        _appSceneContainers=[NSMutableArray new];
        _hostedScenes=[NSMutableArray arrayWithArray:@[[NSNull null],[NSNull null],[NSNull null],[NSNull null]]];
        _pendingScenes=[NSMutableArray arrayWithArray:@[[NSNull null],[NSNull null],[NSNull null],[NSNull null]]];
        _sceneHandleReady=[NSMutableArray arrayWithArray:@[@NO,@NO,@NO,@NO]];
        _workspace=DFCurrentWorkspace();
        _restoreQueue=[NSMutableArray new];_restoringPhysical=-1;
    }return self;
}
- (NSInteger)physicalForVisual:(NSInteger)visual {
    return DFPhysicalForVisual(visual,self.swapped,DFSlotCountForPreset(self.preset),self.workspace);
}
- (NSInteger)visualForPhysical:(NSInteger)physical {
    return DFVisualForPhysical(physical,self.swapped,DFSlotCountForPreset(self.preset),self.workspace);
}
- (NSArray<NSString *> *)installedBundleIDsForRestore {
    NSMutableArray<NSString *> *ids=[NSMutableArray new];
    for(DFAppInfo *app in [DFAppLibrary installedUserApps])
      if(app.bundleID.length)[ids addObject:app.bundleID];
    return ids;
}
// Recover only saved, still-installed, explicitly approved apps after startup.
// One pending host at a time. Never restore app scene handles or UIWindows.
- (void)beginSavedWorkspaceRestore {
    if(self.appSceneContainers.count!=4 || self.startupActive)return;
    ++self.restoreGeneration;
    [self.restoreQueue removeAllObjects];
    NSArray<NSString *> *list=DFRestorablePhysicalBundles(self.workspace,
       DFConfiguredEnabledAppIDs(),[NSSet setWithArray:[self installedBundleIDsForRestore]],
       DFSlotCountForPreset(self.preset));
    for(NSInteger i=0;i<(NSInteger)list.count;i++)
       if([list[(NSUInteger)i] length])[self.restoreQueue addObject:@(i)];
    self.restorePending=NO;
    [self restoreNextSavedWorkspaceApp];
}
- (void)restoreNextSavedWorkspaceApp {
    if(self.startupActive || self.restorePending || self.appSceneContainers.count!=4)return;
    DFSceneHost *host=[DFSceneHost sharedHost];
    while(self.restoreQueue.count) {
       NSInteger physical=self.restoreQueue.firstObject.integerValue;
       [self.restoreQueue removeObjectAtIndex:0];
       if(physical<0 || physical>=DFSlotCountForPreset(self.preset))continue;
       NSArray *savedBundles=self.workspace[@"PhysicalBundles"];
       NSString *bundle=savedBundles[(NSUInteger)physical];
       if(!DFPickerAllowsApp(bundle,DFConfiguredEnabledAppIDs()) ||
          ![[self installedBundleIDsForRestore] containsObject:bundle])continue;
       if([self.hostedScenes[(NSUInteger)physical] isKindOfClass:UIView.class] ||
          [self.pendingScenes[(NSUInteger)physical] isKindOfClass:UIView.class])continue;
       NSError *error=nil;
       UIView *surface=[host hostViewForBundleID:bundle error:&error];
       if(!surface) {
          DFCLog([NSString stringWithFormat:@"workspace-restore-refused slot=%ld reason=%@",
                 (long)physical,error.localizedDescription?:@"unknown"]);
          continue;
       }
       UIView *container=self.appSceneContainers[(NSUInteger)physical];
       surface.frame=container.bounds;
       surface.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
       surface.userInteractionEnabled=NO;
       self.pendingScenes[(NSUInteger)physical]=surface;
       [container addSubview:surface];
       self.restorePending=YES;
       self.restoringPhysical=physical;
       [self layoutControls];
       DFCLog([NSString stringWithFormat:@"workspace-restore-pending physical=%ld",(long)physical]);
       NSUInteger generation=self.restoreGeneration;
       __weak typeof(self) weakOwner=self;
       dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(7*NSEC_PER_SEC)),
                      dispatch_get_main_queue(),^{
          DFNative12Chrome *owner=weakOwner;
          if(!owner || owner.restoreGeneration!=generation || !owner.restorePending ||
             owner.appSceneContainers.count!=4)return;
          if(owner.pendingScenes[(NSUInteger)physical]==surface){
             [[DFSceneHost sharedHost] releaseHostedView:surface];
             owner.pendingScenes[(NSUInteger)physical]=NSNull.null;
             owner.restorePending=NO;
             owner.restoringPhysical=-1;
             [owner restoreNextSavedWorkspaceApp];
             DFCLog(@"workspace-restore-timeout-skipped-no-fake-ready");
          }
       });
       return;
    }
}
// Shift physical scene WINDOWS among visible positions; do not reparent
// SBAppViewController or re-create media scenes. Requires all slots ready.
- (BOOL)rotateHostedAppsClockwise:(BOOL)clockwise {
    NSInteger active=DFSlotCountForPreset(self.preset);
    if(active<3 || active>4 || self.appSceneContainers.count!=4)return NO;
    DFSceneHost *host=[DFSceneHost sharedHost];
    for(NSInteger i=0;i<active;i++) {
      UIView *surface=self.hostedScenes[(NSUInteger)i];
      if(![surface isKindOfClass:UIView.class] ||
         ![self.sceneHandleReady[(NSUInteger)i] boolValue] ||
         [self.pendingScenes[(NSUInteger)i] isKindOfClass:UIView.class] ||
         surface.superview!=self.appSceneContainers[(NSUInteger)i] ||
         surface.window!=self.appSceneWindows[(NSUInteger)i] ||
         ![host bundleIDForHostedView:surface])return NO;
    }
    if(!DFRotateWorkspace(active,clockwise))return NO;
    self.workspace=DFCurrentWorkspace();
    self.selectedSlot=MIN(self.selectedSlot,active-1);
    [self layoutControls];
    [self emit:@"Style" ratio:nil];
    DFCLog([NSString stringWithFormat:@"workspace-window-rotation size=%ld direction=%@",
       (long)active,clockwise?@"forward":@"reverse"]);
    return YES;
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
- (void)observeActivityInWindow:(UIWindow *)window {
    DFNativeActivityObserver *observer=[DFNativeActivityObserver new];
    observer.cancelsTouchesInView=NO;
    observer.delaysTouchesBegan=NO;
    observer.delaysTouchesEnded=NO;
    __weak typeof(self) weakOwner=self;
    observer.activity=^(UIWindow *touchedWindow){
        // Never mutate scene/window layout during UIKit's touch dispatch.
        dispatch_async(dispatch_get_main_queue(), ^{
            DFNative12Chrome *owner=weakOwner;
            if(!owner || ![owner.windows containsObject:touchedWindow] ||
               touchedWindow.hidden || touchedWindow.screen==UIScreen.mainScreen ||
               owner.startupActive || owner.pickerVisible || owner.styleVisible ||
               owner.appPickerVisible)return;
            [owner noteUserActivity];
        });
    };
    [window addGestureRecognizer:observer];
}
- (UIButton *)button:(NSString *)text tag:(NSInteger)tag
              action:(SEL)action {
    UIButton *b=[UIButton buttonWithType:UIButtonTypeCustom];
    b.tag=tag;
    b.tintColor=UIColor.whiteColor;
    b.backgroundColor=UIColor.clearColor;
    b.imageView.contentMode=UIViewContentModeScaleAspectFit;
    b.titleLabel.font=[UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    [b setTitle:text forState:UIControlStateNormal];
    [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return b;
}
- (BOOL)start {
    // A previously stopped Chrome can be reused after reconnect. Do not
    // resurrect an App/Close modal or stale outer menu on CarPlay Home.
    self.pickerVisible=NO;
    self.appPickerVisible=NO;
    self.styleVisible=NO;
    self.logoTouchPending=NO;
    _dividerDrag.active=false;
    self.logoHoldGate=(DFLogoHoldGate){0};
    self.logoWakeOnlyTap=NO;
    self.startupActive=YES;
    self.controlsUntil=NSDate.date.timeIntervalSince1970+4.0;
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(sceneReady:) name:DFSceneHostDidBecomeReadyNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(sceneFailed:) name:DFSceneHostDidFailNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(realAppTouched:) name:DFSceneHostDidObserveTouchNotification object:nil];
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
        // Original first-party PNG: fullscreen 88x88 RGBA; picker 256x70
        // is the original face+line brand, not an ellipsis bitmap.
        [menu setTitle:@"" forState:UIControlStateNormal];
        [zoom setTitle:@"" forState:UIControlStateNormal];
        UIImageSymbolConfiguration *symbol=[UIImageSymbolConfiguration
                       configurationWithPointSize:12 weight:UIImageSymbolWeightMedium];
        [menu setImage:[UIImage systemImageNamed:@"ellipsis" withConfiguration:symbol]
              forState:UIControlStateNormal];
        UIImage *fullscreenArt=DFCArtwork(@"duoface-fullscreen");
        if(fullscreenArt)
            [zoom setImage:[fullscreenArt imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                  forState:UIControlStateNormal];
        else
            [zoom setImage:[UIImage systemImageNamed:@"arrow.up.left.and.arrow.down.right"
                                     withConfiguration:symbol] forState:UIControlStateNormal];
        zoom.imageView.contentMode=UIViewContentModeScaleAspectFit;
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
    // Own exactly ONE primary divider interaction owner. A second white
    // 2pt decorative line previously painted directly over the real split
    // edge and under the round logo. The hosted pane boundaries already
    // define the divider, so do not create tag 718 at all. The transparent
    // 32pt track remains the independently owned Ratio touch target.
    UIPanGestureRecognizer *trackPan=[[UIPanGestureRecognizer alloc]
                             initWithTarget:self action:@selector(dividerPan:)];
    trackPan.maximumNumberOfTouches=1;
    // A touch starting on the logo is owned by its raw touch stream. The parent divider pan must not consume that touch.
    trackPan.delegate=self;
    [self.dividerTrack addGestureRecognizer:trackPan];
    DFNativeDividerGripButton *logo=[[DFNativeDividerGripButton alloc]initWithFrame:CGRectZero];
    logo.backgroundColor=UIColor.clearColor;
    // Native8 device-verified layout: one real UIButton owns logo movement;
    // logo has a 3s hold gate; the surrounding track keeps immediate ratio pan.
    __weak typeof(self) weakGripOwner=self;
    // Raw contact is gated: brief tap swaps, hold then parallel drag moves logo.
    logo.touchBegan=^(UIButton *sender){[weakGripOwner logoTouchDown:sender];};
    logo.touchMoved=^(UIButton *sender){[weakGripOwner logoTouchChanged:sender];};
    logo.touchEnded=^(UIButton *sender,BOOL inside,BOOL cancelled){
        [weakGripOwner logoTouchFinished:sender inside:inside cancelled:cancelled];
    };
    logo.titleLabel.font=[UIFont boldSystemFontOfSize:23];
    // Verified 120x120 first-party duoface-swap.png is a circular face logo.
    // Do not swap it for a counterfeit vector or a square placeholder.
    [logo setTitle:@"" forState:UIControlStateNormal];
    // Original Native12 grip pulse animates the TRUE logo visual at 1.18x.
    // Keep background/border clear: old vendor badge blue/glow must not sit
    // underneath this independently authored PNG (visual-only layer).
    logo.layer.borderWidth=0;
    logo.layer.shadowOpacity=0;
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
    // One raw touch owner and uptime gate; no competing grip recognizer.
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
    [self observeActivityInWindow:self.dividerWindow];
    [self observeActivityInWindow:self.secondaryDividerWindow];
    // Keep the action menu inside the selected split pane rather than
    // covering the whole dual-app display as a centered 470pt sheet.
    CGFloat pw=MIN(470,MAX(180,cr.size.width-16));
    // The external App/Zoom/Style/Close action ROW has no body view.
    // Real Native12 setupCardContent uses 32pt short / 38pt tall header;
    // DO NOT cover both live panes with the old blank 224pt gray sheet.
    CGFloat ph=(CGFloat)DFOriginalCardHeader(cr.size.width,cr.size.height).headerHeight;
    CGRect picker=CGRectMake(CGRectGetMidX(cr)-pw/2,CGRectGetMidY(cr)-ph/2,pw,ph);
    UIViewController *pc=[self emptyRoot:picker];
    UIView *sheet=pc.view;
    sheet.backgroundColor=UIColor.clearColor;
    sheet.layer.cornerRadius=MIN(20,ph/2);
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
    brandImage.frame=CGRectMake(8,(ph-30)/2,MIN(120,pw*.25),30);
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
    NSMutableArray<UIButton *> *actions=[NSMutableArray new];
    // Native12-approved 30pt ONE row; logo, App, Zoom, Style, Close.
    const CGFloat widths[4]={43,51,47,51};
    CGFloat logoW=MIN(120,MAX(65,pw*.25));
    CGFloat scale=MIN(1.0,MAX(.58,(pw-logoW-68)/192));
    CGFloat bx=8+logoW+5;
    for(NSInteger i=0;i<4;i++){
        UIButton *b=[self button:names[(NSUInteger)i] tag:i
                         action:@selector(menuAction:)];
        b.frame=CGRectMake(bx,(ph-30)/2,widths[i]*scale,30);
        bx+=widths[i]*scale;
        // Original CBMultitaskingOverlayView uses a one-line titleLabel:
        // stacked iOS15 image-over-title config clipped App/Zoom/Style/Close.
        b.titleLabel.font=[UIFont systemFontOfSize:10];
        b.titleLabel.adjustsFontSizeToFitWidth=YES;
        b.titleLabel.minimumScaleFactor=.75;
        b.titleLabel.lineBreakMode=NSLineBreakByClipping;
        [sheet addSubview:b];[actions addObject:b];
    }
    self.menuActions=actions;
    // The Native12 native parent owns button touch-up, not a floating
    // overlay label. Capture actual CarPlay UIControl touch delivery so that
    // a visible Zoom button with an uncalled selector is never marked wired.
    if(actions.count==4){
        UIButton *zoomAction=actions[1];
        // TouchUpInside is the original UIKit path; CarPlay's focused
        // select key can instead dispatch PrimaryActionTriggered. Route
        // BOTH to the SAME real menuAction: selector, never a second
        // visual-only Zoom handler.
        [zoomAction addTarget:self action:@selector(menuAction:)
            forControlEvents:UIControlEventPrimaryActionTriggered];
        [zoomAction addTarget:self action:@selector(zoomButtonTouchDown:)
            forControlEvents:UIControlEventTouchDown];
        [zoomAction addTarget:self action:@selector(zoomButtonTouchCancelled:)
            forControlEvents:UIControlEventTouchUpOutside|UIControlEventTouchCancel];
        zoomAction.accessibilityIdentifier=@"DuoFace.Native12.globalZoom";
    }
    UILabel *hint=[UILabel new];
    hint.text=@"";hint.hidden=YES; // remove invented duplicate caption
    hint.font=[UIFont systemFontOfSize:9];
    hint.textColor=[UIColor colorWithWhite:.8 alpha:1];
    hint.textAlignment=NSTextAlignmentCenter;
    hint.frame=CGRectMake(8,MIN(ph-25,52),pw-16,19);
    [sheet addSubview:hint];self.menuContext=hint;
    // Preserve the OUTER four actions but use Native12's decoded
    // source-owned X imagery/geometry. X dismisses, Close manages apps.
    DFNative12CardHeader menuHeader=DFOriginalCardHeader(pw,ph);
    UIButton *dismiss=[self button:@"" tag:0 action:@selector(closeMenu:)];
    dismiss.frame=CGRectMake(menuHeader.dismiss.x,menuHeader.dismiss.y,
                  menuHeader.dismiss.width,menuHeader.dismiss.height);
    dismiss.backgroundColor=[UIColor colorWithRed:.18 green:.18 blue:.22 alpha:.9];
    dismiss.layer.cornerRadius=menuHeader.dismiss.width/2;
    [dismiss setImage:[UIImage systemImageNamed:@"xmark"] forState:UIControlStateNormal];
    dismiss.tintColor=UIColor.whiteColor;
    dismiss.accessibilityLabel=@"Đóng menu";
    [sheet addSubview:dismiss];self.menuDismiss=dismiss;
    self.pickerWindow=[self makeWindow:picker root:pc level:3];
    if(!self.pickerWindow){[self stop];return NO;}
    // Native12-inspired Style gallery: explicit selectable split arrangements,
    // not the old invisible preset++ on each press. Miniatures are geometry
    // previews only (DFLayoutEngine), NOT simulated embedded applications.
    // Native12 CBMultitaskingOverlayView.layoutSubviews @0xa28e8:
    // four byte-verified literals + fminnm + frinta; this replaces the
    // locally invented 470x220 cap, without altering scene/window ownership.
    DFNative12OuterSheetRect outer=DFNative12OuterGeometry(cr.size.width,cr.size.height);
    CGFloat styleW=(CGFloat)outer.width,styleH=(CGFloat)outer.height;
    CGRect styleRect=CGRectMake(cr.origin.x+(CGFloat)outer.x,
                                cr.origin.y+(CGFloat)outer.y,styleW,styleH);
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
    // Original Native12 CBMultitaskingOverlayView.setupCardContent @0xa2a58:
    // The INNER selector is Apps / Layout / Recent (three modes), not
    // the separate OUTER App / Zoom / Style / Close toolbar above.
    // This geometry was decoded from original immutable Dashboard bytes;
    // no vendor application code or licensing is executed here.
    DFNative12CardHeader native=DFOriginalCardHeader(styleW,styleH);
    UIImageView *styleLogo=[[UIImageView alloc] initWithImage:
        [UIImage systemImageNamed:@"rectangle.split.2x1.fill"]];
    styleLogo.frame=CGRectMake(native.icon.x,native.icon.y,
                              native.icon.width,native.icon.height);
    styleLogo.tintColor=[UIColor colorWithRed:.08 green:.52 blue:1 alpha:1];
    styleLogo.contentMode=UIViewContentModeScaleAspectFit;
    styleLogo.userInteractionEnabled=NO;
    [styleSheet addSubview:styleLogo];
    self.styleHeaderLogo=styleLogo;
    UILabel *styleTitle=[UILabel new];
    styleTitle.text=@"Layout"; // Original localized OVERLAY_LAYOUT mode 1.
    styleTitle.textColor=UIColor.whiteColor;
    styleTitle.font=[UIFont systemFontOfSize:styleW<440?11.5:13 weight:UIFontWeightBold];
    styleTitle.adjustsFontSizeToFitWidth=YES;
    styleTitle.minimumScaleFactor=.7;
    styleTitle.lineBreakMode=NSLineBreakByTruncatingTail;
    styleTitle.frame=CGRectMake(native.title.x,native.title.y,
                                 native.title.width,native.title.height);
    [styleSheet addSubview:styleTitle];
    self.styleHeaderTitle=styleTitle;
    UIView *modeBar=[[UIView alloc] initWithFrame:CGRectMake(native.tabs.x,
        native.tabs.y,native.tabs.width,native.tabs.height)];
    modeBar.layer.cornerRadius=8;
    modeBar.layer.cornerCurve=kCACornerCurveContinuous;
    modeBar.clipsToBounds=YES;
    [styleSheet addSubview:modeBar];
    NSArray *innerModeNames=@[@"Apps",@"Layout",@"Recent"];
    const NSInteger innerModeTags[3]={0,2,3}; // existing real owner actions
    NSMutableArray<UIButton *> *styleTabs=[NSMutableArray new];
    for(NSInteger tab=0;tab<3;tab++){
        UIButton *action=[self button:innerModeNames[(NSUInteger)tab]
                                  tag:innerModeTags[tab]
                               action:@selector(menuAction:)];
        DFNative12CardRect frame=native.tabButtons[tab];
        action.frame=CGRectMake(frame.x,frame.y,frame.width,frame.height);
        action.titleLabel.font=[UIFont systemFontOfSize:styleW<440?10:11
                                                      weight:UIFontWeightMedium];
        action.titleLabel.adjustsFontSizeToFitWidth=YES;
        action.titleLabel.minimumScaleFactor=.7;
        action.layer.cornerRadius=6;
        action.layer.cornerCurve=kCACornerCurveContinuous;
        action.backgroundColor=tab==1?
            [UIColor colorWithRed:.08 green:.52 blue:1 alpha:1]:
            UIColor.clearColor;
        [modeBar addSubview:action];
        [styleTabs addObject:action];
    }
    self.styleHeaderActions=styleTabs;
    self.styleModeBar=modeBar;
    self.styleZoom=[self button:@"Zoom" tag:1 action:@selector(menuAction:)];
    [modeBar addSubview:self.styleZoom];
    CGFloat styledContentY=DFLayoutNative12MenuHeader(styleSheet,modeBar,styleLogo,styleTitle,
        @[styleTabs[0],self.styleZoom,styleTabs[1],styleTabs[2]],modeBar.frame,2,self.hostFullscreen);
    self.styleZoom.hidden=styledContentY==0;
    // The original X image dismisses its sheet; Recent/Close is a
    // different action that works only on real owned app scenes.
    UIButton *dismissStyle=[self button:@"" tag:0 action:@selector(closeStylePicker:)];
    dismissStyle.frame=CGRectMake(native.dismiss.x,native.dismiss.y,
                                  native.dismiss.width,native.dismiss.height);
    dismissStyle.backgroundColor=[UIColor colorWithRed:.18 green:.18 blue:.22 alpha:.9];
    dismissStyle.layer.cornerRadius=native.dismiss.width/2;
    [dismissStyle setImage:[UIImage systemImageNamed:@"xmark"]
                 forState:UIControlStateNormal];
    dismissStyle.tintColor=UIColor.whiteColor;
    dismissStyle.accessibilityLabel=@"Đóng menu";
    [styleSheet addSubview:dismissStyle];
    UIView *headerSeparator=[[UIView alloc] initWithFrame:
        CGRectMake(0,native.headerHeight,styleW,.5)];
    headerSeparator.backgroundColor=[UIColor colorWithWhite:1 alpha:.12];
    headerSeparator.hidden=styledContentY>0;
    [styleSheet addSubview:headerSeparator];
    NSArray<NSString *> *styleNames=@[@"Một khung",@"Trái / phải",
         @"Trên / dưới",@"Ba cột",@"Một trái, hai phải",
         @"Hai trái, một phải",@"Một trên, hai dưới",@"Hai trên, một dưới",
          @"Bốn ô"];
    // Original @0xa3dd8 passes headerHeight+.5 to the nine-preset page.
    UIScrollView *gallery=[[UIScrollView alloc] initWithFrame:
        CGRectMake(0,native.contentY,styleW,MAX(1,styleH-native.contentY-4))];
    if(styledContentY>native.contentY)
        gallery.frame=CGRectMake(0,styledContentY,styleW,MAX(1,styleH-styledContentY-4));
    gallery.contentSize=CGSizeMake(styleW,194);
    gallery.delaysContentTouches=YES;
    [styleSheet addSubview:gallery];
    DFNative12GalleryMetrics metrics=DFNative12Gallery(styleW);
    NSMutableArray<UIButton *> *choices=[NSMutableArray new];
    NSMutableArray<UIImageView *> *badges=[NSMutableArray new];
    for(NSInteger idx=0;idx<9;idx++){
        UIButton *button=[self button:@"" tag:idx action:@selector(selectStylePreset:)];
        button.frame=CGRectMake(14+(idx%metrics.columns)*(metrics.cardWidth+10),
               22+(idx/metrics.columns)*metrics.rowStride,
               metrics.cardWidth,metrics.cardHeight);
        button.layer.cornerRadius=12;
        button.layer.cornerCurve=kCACornerCurveContinuous;
        button.clipsToBounds=YES;
        button.accessibilityLabel=styleNames[(NSUInteger)idx];
        CGFloat thumbW=metrics.previewWidth;
        CGFloat thumbH=54;
        // Exact original 0x9efe0 calls UIGraphics and returns a UIImage.
        // Do not substitute white demo UIView blocks for the bitmap.
        UIImage *preview=DFNative12PresetPreview(idx,idx==self.preset,CGSizeMake(thumbW,thumbH));
        UIImageView *thumb=[[UIImageView alloc] initWithImage:preview];
        thumb.frame=CGRectMake(roundf((float)((metrics.cardWidth-thumbW)/2)),
                               6,thumbW,thumbH);
        thumb.tag=12001;
        thumb.highlighted=(idx==self.preset);
        thumb.contentMode=UIViewContentModeScaleAspectFit;
        thumb.backgroundColor=UIColor.clearColor;
        thumb.userInteractionEnabled=NO;
        [button addSubview:thumb];
        // Native original uses image-only cards; retain localized text for
        // VoiceOver, not an invented visible caption beside the preview.
        UIImageSymbolConfiguration *palette=[UIImageSymbolConfiguration
            configurationWithPaletteColors:@[UIColor.whiteColor,
                [UIColor colorWithRed:.08 green:.52 blue:1 alpha:1]]];
        UIImageView *badge=[[UIImageView alloc] initWithImage:
            [[UIImage systemImageNamed:@"checkmark.circle.fill"] imageWithConfiguration:palette]];
        badge.frame=CGRectMake(metrics.cardWidth-21,4,17,17);
        badge.layer.shadowColor=UIColor.blackColor.CGColor;
        badge.layer.shadowRadius=3;
        badge.layer.shadowOpacity=.45f; // Original a6174/a666c/a6670.
        badge.userInteractionEnabled=NO;
        [button addSubview:badge];
        [badges addObject:badge];
        [gallery addSubview:button];
        [choices addObject:button];
    }
    self.styleSelectionBadges=badges;
    self.styleChoices=choices;
    self.styleWindow=[self makeWindow:styleRect root:styleRoot level:4];
    if(!self.styleWindow){[self stop];return NO;}
    // RESTORE .37's real scene owner: one external UIWindow per physical
    // slot. Shared .48+ window silently changed remote UIWindowScene geometry
    // ownership even while the inner app viewport was set to Native12 size.
    // Keep the CURRENT gesture/menu/Dock/Zoom overlays (separate windows).
    // Never recreate a window in layoutControls, including on ratio drag.
    for(NSInteger i=0;i<4;i++){
        CGRect slotRect=CGRectMake(cr.origin.x,cr.origin.y,
                                 MAX(30,cr.size.width/4),cr.size.height);
        UIViewController *slotRoot=[UIViewController new];
        slotRoot.view=[[DFNativePanePassthroughView alloc]
             initWithFrame:CGRectMake(0,0,slotRect.size.width,
                                           slotRect.size.height)];
        slotRoot.view.backgroundColor=UIColor.clearColor;
        slotRoot.view.clipsToBounds=YES;
        UIWindow *slotWindow=[self makeWindow:slotRect root:slotRoot level:0.5];
        if(!slotWindow){[self stop];return NO;}
        UIView *container=[[UIView alloc]initWithFrame:slotRoot.view.bounds];
        container.backgroundColor=UIColor.clearColor;
        container.clipsToBounds=YES;
        container.userInteractionEnabled=NO;
        container.autoresizingMask=UIViewAutoresizingFlexibleWidth|
                                   UIViewAutoresizingFlexibleHeight;
        [slotRoot.view addSubview:container];
        [self.appSceneContainers addObject:container];
        [self.appSceneWindows addObject:slotWindow];
        [self observeActivityInWindow:slotWindow];
    }
    DFCLog(@"media37-four-physical-scene-windows-restored");
    self.appPickerController=[DFAppPickerVC new];
    self.appPickerController.delegate=self;
    // Original CBMultitaskingOverlayView.layoutSubviews owns ONE outer sheet
    // geometry for Apps/Layout/Recent; do not use the old invented 480x330.
    CGRect chooserRect=styleRect;
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
               [owner noteUserActivity];
               DFCLog(@"native12-logo-and-loading-line-completed");
               // New CarPlay session only, after UI startup has finished.
               [owner beginSavedWorkspaceRestore];
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
    return self.dividerLogo.hidden || !CGRectContainsPoint(logoHit,p);
}
// SHA-pinned ORIGINAL CBDividerView.startBlinking/stopBlinking (0x1009d4 /
// 0x1010bc) applies a visual 1.18x transform to the move button. Keep the
// independently authored PNG and raw UIKit event/hit target untouched:
// CoreAnimation affects presentation only, not UIView.frame or touch routing.
// The original exact pulse cadence is NOT decoded; this conservative blink
// is bounded by the EXISTING Chrome activity/idle visibility session rather
// than an invented second lifecycle timer.
- (void)updateGripBlinkForVisibleSession:(BOOL)visible {
    UIButton *grip=self.dividerLogo;
    if(!grip)return;
    NSString *key=@"dfNative12GripPulse";
    CAAnimation *existing=[grip.layer animationForKey:key];
    BOOL running=visible && !self.startupActive && self.focus<0 &&
        !self.pickerVisible && !self.styleVisible && !self.appPickerVisible &&
        DFSlotCountForPreset(self.preset)>1;
    if(!running){
        if(existing)[grip.layer removeAnimationForKey:key];
        return;
    }
    if(existing)return; // relayout, Ratio and touch changes MUST NOT restart blink
    CABasicAnimation *blink=[CABasicAnimation animationWithKeyPath:@"transform.scale"];
    blink.fromValue=@1.0;
    blink.toValue=@1.18; // original Native12 Mach-O at 0x312498
    blink.duration=0.35; // first-party cadence; original cadence is not verified
    blink.autoreverses=YES;
    blink.repeatCount=HUGE_VALF;
    blink.removedOnCompletion=YES;
    [grip.layer addAnimation:blink forKey:key];
    DFCLog(@"grip-native12-scale-pulse-start-visual-1.18");
}
- (void)noteUserActivity {
    self.borderUntil=NSDate.date.timeIntervalSince1970+2.0;
    self.controlsUntil=NSDate.date.timeIntervalSince1970+4.0;
    NSUInteger seq=++self.borderGeneration;
    [self layoutControls];
    __weak typeof(self) weakOwner=self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(4.05*NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        DFNative12Chrome *owner=weakOwner;
        if(owner && owner.borderGeneration==seq){
            owner.borderUntil=0;
            [owner layoutControls];
        }
    });
}
- (void)realAppTouched:(NSNotification *)note {
    if(![note.object isKindOfClass:UIView.class] ||
       self.startupActive || self.pickerVisible || self.styleVisible ||
       self.appPickerVisible)return;
    UIView *surface=note.object;
    if(![self.appSceneWindows containsObject:surface.window])return;
    [self noteUserActivity];
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
        @"HostFullscreenGeometry":@(self.hostFullscreen),
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
    if(preset<0 || preset>8)return NO;
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
    CGFloat height=(CGFloat)DFOriginalCardHeader(cr.size.width,cr.size.height).headerHeight;
    CGFloat x=MAX(CGRectGetMinX(cr)+4,MIN(CGRectGetMidX(pane)-width/2,
                                          CGRectGetMaxX(cr)-width-4));
    // Top-align the sole real action row to the selected pane; its
    // content consists only of this header, never a fabricated empty body.
    CGFloat y=MAX(CGRectGetMinY(cr)+4,MIN(CGRectGetMinY(pane)+4,
                                          CGRectGetMaxY(cr)-height-4));
    self.pickerWindow.frame=CGRectMake(x,y,width,height);
    UIView *sheet=self.pickerWindow.rootViewController.view;
    sheet.frame=CGRectMake(0,0,width,height);
    const CGFloat widths[4]={43,51,47,51};
    CGFloat logoW=MIN(120,MAX(65,width*.25));
    CGFloat scale=MIN(1.0,MAX(.58,(width-logoW-68)/192));
    CGFloat bx=8+logoW+5;
    for(NSUInteger i=0;i<self.menuActions.count;i++){
        self.menuActions[i].frame=CGRectMake(bx,(height-30)/2,widths[i]*scale,30);
        bx+=widths[i]*scale;
    }
    // This was the broken visible "Zoom" text-only slot: the original
    // DFPickerZoomMenu.v12 draws a 16pt OUT/IN arrow above the 10pt label.
    // Reuse its verified visual contract; the *physical* Dock still changes
    // only after DFDockZoomCoordinator receives real two-owner ACK.
    if(self.menuActions.count==4)
        DFNative12DecorateZoomButton(self.menuActions[1],self.hostFullscreen);
    CGRect brandFrame=CGRectMake(8,(height-30)/2,logoW,30);
    self.menuBrandImage.frame=brandFrame;
    self.pickerBrand.frame=brandFrame;
    // The initial X was decoded from original setupCardContent. Re-layout
    // must NOT override it with the old local 32×26 invented rectangle.
    DFNative12CardHeader originalMenu=DFOriginalCardHeader(width,height);
    self.menuDismiss.frame=CGRectMake(originalMenu.dismiss.x,
                originalMenu.dismiss.y,originalMenu.dismiss.width,
                originalMenu.dismiss.height);
    self.menuDismiss.layer.cornerRadius=originalMenu.dismiss.width/2;
    self.menuContext.text=@"";self.menuContext.hidden=YES;
    self.menuContext.frame=CGRectMake(8,MIN(height-25,52),width-16,19);
}
- (void)layoutControls {
    CGRect cr=self.contentRect;
    if(self.appPickerController.hostExpanded!=self.hostFullscreen){
        self.appPickerController.hostExpanded=self.hostFullscreen;
        [self.appPickerController.view setNeedsLayout];
    }
    if(self.styleHeaderActions.count==3){
        UIView *sheet=self.styleWindow.rootViewController.view;
        DFNative12CardHeader header=DFOriginalCardHeader(sheet.bounds.size.width,sheet.bounds.size.height);
        CGFloat contentY=DFLayoutNative12MenuHeader(sheet,self.styleModeBar,self.styleHeaderLogo,
            self.styleHeaderTitle,@[self.styleHeaderActions[0],self.styleZoom,
            self.styleHeaderActions[1],self.styleHeaderActions[2]],
            CGRectMake(header.tabs.x,header.tabs.y,header.tabs.width,header.tabs.height),2,self.hostFullscreen);
        self.styleZoom.hidden=contentY==0;
    }
    BOOL controlsVisible=self.panActive || self.logoTouchPending ||
                         NSDate.date.timeIntervalSince1970<=self.controlsUntil;
    for(UIButton *choice in self.styleChoices){
        BOOL selected=(choice.tag==self.preset);
        UIImageView *thumb=(UIImageView *)[choice viewWithTag:12001];
        if([thumb isKindOfClass:UIImageView.class] && thumb.highlighted!=selected){
            thumb.image=DFNative12PresetPreview(choice.tag,selected,thumb.bounds.size);
            thumb.highlighted=selected;
        }
        choice.layer.borderWidth=selected?2:1;
        choice.backgroundColor=selected?
            [UIColor colorWithRed:.04 green:.2 blue:.45 alpha:.95]:
            [UIColor colorWithRed:.14 green:.15 blue:.19 alpha:.95];
        choice.layer.borderColor=(selected?
           [UIColor colorWithRed:.12 green:.58 blue:1 alpha:1]:
           [UIColor colorWithWhite:1 alpha:.18]).CGColor;
        self.styleSelectionBadges[(NSUInteger)choice.tag].hidden=!selected;
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
        NSInteger physicalSlot=[self physicalForVisual:i];
        BOOL ready=[self.sceneHandleReady[(NSUInteger)physicalSlot] boolValue];
        BOOL focused=(self.focus==i);
        BOOL show=(self.focus<0 || focused)&&!self.pickerVisible&&!self.styleVisible&&!self.appPickerVisible;
        BOOL allReady=YES;
        for(NSInteger k=0;k<activeSlots;k++){
            NSInteger actual=[self physicalForVisual:k];
            if(![self.sceneHandleReady[(NSUInteger)actual] boolValue]){
                allReady=NO;break;
            }
        }
        // A missing real app must keep its launch controls. When fully
        // populated, pill controls auto-hide until actual pane touches.
        show=show && (!allReady || controlsVisible);
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
        // Per-pane Focus/Restore is distinct from the outer whole-host Zoom.
        // The arrow must visibly REVERSE after a successful focus transition;
        // the approved static duoface-fullscreen.png cannot convey Zoom Out.
        zoom.accessibilityLabel=ready?(focused?@"Zoom Out ô":@"Zoom In ô"):
                                         @"Chọn ứng dụng để dùng Zoom";
        UIImage *direction=[UIImage systemImageNamed:DFNative12ZoomArrowSymbol(focused)
                            withConfiguration:[UIImageSymbolConfiguration
                               configurationWithPointSize:13 weight:UIImageSymbolWeightRegular]];
        UIImage *fallback=direction?:DFCArtwork(@"duoface-fullscreen");
        [zoom setImage:[fallback imageWithRenderingMode:direction?
                         UIImageRenderingModeAlwaysTemplate:UIImageRenderingModeAlwaysOriginal]
              forState:UIControlStateNormal];
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
    // No additional primary divider stroke: the existing split edge and
    // single movable grip are the visible boundary (no layered old white line).
    CGFloat size=MIN(tr.size.height>250?30:28,30);
    self.dividerLogo.frame=self.verticalDivider?
        CGRectMake((tr.size.width-size)/2,tr.size.height*self.logoFraction-size/2,size,size):
        CGRectMake(tr.size.width*self.logoFraction-size/2,(tr.size.height-size)/2,size,size);
    self.dividerLogo.layer.cornerRadius=size/2;
    // Keep the actual drag hit target alive after the 4s hide timer.
    // At 0.02 alpha it remains hit-testable but not visibly painted;
    // a short tap ONLY wakes controls, not an unwanted Swap.
    self.dividerLogo.hidden=NO;
    self.dividerLogo.alpha=controlsVisible?1.0:0.02;
    [self updateGripBlinkForVisibleSession:controlsVisible];
    // The 32pt ratio grab lane stays responsive when the 4s artwork timer
    // hides the line/logo. A new pan wakes chrome rather than disabling
    // the only split-ratio input path after the timeout.
    self.dividerWindow.userInteractionEnabled=YES;
    self.dividerWindow.hidden=(self.startupActive||activeSlots==1||self.focus>=0||self.pickerVisible||self.styleVisible||self.appPickerVisible);
    CGRect second=DFSecondaryDividerRect(cr,self.preset,p,self.secondaryRatio);
    if(!CGRectIsNull(second)){
        BOOL vertical=DFSecondaryDividerIsVertical(self.preset);
        CGRect sf=vertical?
          CGRectMake(second.origin.x-16,second.origin.y+2,32,MAX(18,second.size.height-4)):
          CGRectMake(second.origin.x+2,second.origin.y-16,MAX(18,second.size.width-4),32);
        self.secondaryDividerWindow.frame=sf;
        self.secondaryDividerTrack.frame=(CGRect){CGPointZero,sf.size};
        UIView *stroke=[self.secondaryDividerTrack viewWithTag:719];
        stroke.hidden=!controlsVisible;
        self.secondaryDividerWindow.userInteractionEnabled=YES;
        stroke.frame=vertical?CGRectMake(15,0,2,sf.size.height):
                              CGRectMake(0,15,sf.size.width,2);
    }
    self.secondaryDividerWindow.hidden=(self.startupActive||activeSlots<3||
        self.focus>=0||self.pickerVisible||self.styleVisible||self.appPickerVisible||CGRectIsNull(second));
    self.pickerWindow.hidden=(self.startupActive||!self.pickerVisible);
    self.styleWindow.hidden=(self.startupActive||!self.styleVisible);
    self.appPickerWindow.hidden=(self.startupActive||!self.appPickerVisible);
    // .37 remote owner layout: physical-slot UIWindow changes frame together
    // with its root/scene pane; the video source is NOT a child rect of an
    // unrelated full-car shared UIWindow. Physical slot persists on swap.
    for(NSInteger i=0;i<4;i++){
        UIWindow *appWindow=self.appSceneWindows[(NSUInteger)i];
        UIView *v=self.appSceneContainers[(NSUInteger)i];
        NSInteger visualSlot=[self visualForPhysical:i];
        if(visualSlot<0 || visualSlot>=activeSlots){appWindow.hidden=YES;v.hidden=YES;continue;}
        CGRect target=pane[visualSlot];
        if(self.focus>=0 && visualSlot==self.focus)target=cr;
        if(!CGRectEqualToRect(appWindow.frame,target))appWindow.frame=target;
        UIView *root=appWindow.rootViewController.view;
        CGRect localFrame=(CGRect){CGPointZero,target.size};
        if(!CGRectEqualToRect(root.frame,localFrame))root.frame=localFrame;
        if(!CGRectEqualToRect(v.frame,localFrame))v.frame=localFrame;
        for(UIView *child in v.subviews)
            if(!CGRectEqualToRect(child.frame,v.bounds))child.frame=v.bounds;
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
        v.hidden=appWindow.hidden;
        // Empty/negotiating panes cannot steal gestures.
        v.userInteractionEnabled=loaded;
        // Native12 split and SOLO are UI state, not inferred from a second
        // loaded app or the pane's width. One visible YouTube pane plus one
        // EMPTY pane is still split. The host owns the app-scene IPC lease.
        id hosted=self.hostedScenes[(NSUInteger)i];
        if([hosted isKindOfClass:UIView.class]) {
            [[DFSceneHost sharedHost] setSplitMode:
                (activeSlots>1 && self.focus<0 && !self.startupActive)
                forHostedView:(UIView *)hosted];
        }
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
    if(sender.tag<0 || sender.tag>=DFSlotCountForPreset(self.preset))return;
    [self noteUserActivity];
    // 2026-10-23 actual head-unit screenshot: .53 produced ONLY a thin,
    // floating App/Zoom/Style/Close row, with NO installed-app contents.
    // That is NOT the original Native12 card, which uses the existing
    // overlay card's app-mode contents (Apps/Layout/Recent). Reuse our
    // previously implemented DFAppPickerVC sheet, inventory and Zoom action.
    // Do NOT show the separate hand-built popup toolbar from .53.
    self.pickerVisible=NO;
    [self openAppPickerForSlot:sender.tag];
    DFCLog([NSString stringWithFormat:
        @"native12-ellipsis-opened-real-app-card slot=%ld picker=%d row=%d",
        (long)sender.tag,self.appPickerVisible,self.pickerVisible]);
}
- (void)closeMenu:(id)sender {
    (void)sender;
    self.pickerVisible=NO;[self layoutControls];
}
- (void)closeStylePicker:(id)sender {
    (void)sender;
    self.styleVisible=NO;
    [self noteUserActivity];
}
- (void)openStylePicker {
    self.pickerVisible=NO;
    self.appPickerVisible=NO;
    self.appPickerWindow.hidden=YES;
    self.styleVisible=YES;
    [self layoutControls];
    DFCLog([NSString stringWithFormat:@"style-choices-visible selected=%ld",(long)self.preset]);
}
- (void)selectStylePreset:(UIButton *)sender {
    NSInteger selected=sender.tag;
    if(!self.styleVisible || selected<0 || selected>8)return;
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
    NSInteger physical=[self physicalForVisual:slot];
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
- (void)zoomButtonTouchDown:(UIButton *)sender {
    DFCLog([NSString stringWithFormat:
       @"native12-zoom-button-touchdown hit=%@ window=%@ enabled=%d target=%d",
       NSStringFromCGRect(sender.frame),
       sender.window?NSStringFromClass(sender.window.class):@"none",
       sender.enabled,
       [[sender actionsForTarget:self forControlEvent:UIControlEventTouchUpInside]
          containsObject:NSStringFromSelector(@selector(menuAction:))]]);
}
- (void)zoomButtonTouchCancelled:(UIButton *)sender {
    DFCLog([NSString stringWithFormat:
       @"native12-zoom-button-touch-cancelled window=%@",
       sender.window?NSStringFromClass(sender.window.class):@"none"]);
}
- (void)menuAction:(UIButton *)sender {
    DFCLog([NSString stringWithFormat:@"native12-menu-action-invoked tag=%ld",(long)sender.tag]);
    [self noteUserActivity];
    if(sender.tag==1){
        // Native12: retain App/Zoom/Style/Close until real Dock+host ACK.
        DFCLog(self.hostFullscreen?@"native12-zoom-out-arrow-pressed-ack-pending":
                                 @"native12-zoom-in-arrow-pressed-ack-pending");
        [self emit:@"Zoom" ratio:nil];
        return;
    }
    [self closeMenu:nil];
    self.styleVisible=NO;
    [self layoutControls];
    switch(sender.tag){
        case 0:[self openAppPickerForSlot:self.selectedSlot];break;
        case 2:[self openStylePicker];break;
        case 3:[self openRunningAppManager];break;
        default:break;
    }
}
- (void)appPickerDidRequestLayout:(DFAppPickerVC *)picker {
    if(picker!=self.appPickerController)return;
    [self openStylePicker]; // Existing independent real nine-preset selector.
}
- (void)appPickerDidRequestZoom:(DFAppPickerVC *)picker {
    if(picker!=self.appPickerController || !self.appPickerVisible)return;
    [self noteUserActivity];
    // Root DuoFace October 14 history: never lose the only Zoom/Restore
    // control before an actual native Dock and host geometry response.
    DFCLog(self.hostFullscreen?@"native12-card-zoom-out-request-real-dock":
                               @"native12-card-zoom-in-request-real-dock");
    [self emit:@"Zoom" ratio:nil];
}
- (void)completeWholeHostZoomRequest:(BOOL)applied {
    if(!NSThread.isMainThread)return;
    if(applied) {
        self.appPickerVisible=NO;
        self.pickerVisible=NO;
        self.styleVisible=NO;
        self.appPickerWindow.hidden=YES;
        [self layoutControls];
        DFCLog(@"native12-card-zoom-verified-ui-dismissed");
    } else {
        // A rejected Zoom must not visibly look like the user clicked Close.
        if(self.appPickerVisible) {
            self.appPickerWindow.hidden=NO;
            [self layoutControls];
        }
        [self layoutControls];
        DFCLog(@"native12-card-zoom-rejected-ui-retained");
    }
}
- (void)appPickerDidRequestRunningApps:(DFAppPickerVC *)picker {
    if(picker!=self.appPickerController)return;
    [self openRunningAppManager]; // Verified DFSceneHost bundleIDs only.
}
- (void)openAppPickerForSlot:(NSInteger)slot {
    if(slot<0 || slot>=DFSlotCountForPreset(self.preset))return;
    self.selectedSlot=slot;
    self.appPickerVisible=YES;
    self.pickerVisible=NO;
    self.styleVisible=NO;
    // Picker contents are read fresh every time. Do not reuse a stale
    // LSApplicationWorkspace snapshot across install/remove operations.
    // Read the *actually scene-ready* bundle in this physical slot before
    // showing active App colors. Nothing in the installed list proves selection.
    NSInteger physical=[self physicalForVisual:slot];
    NSString *current=nil;
    if([self.sceneHandleReady[(NSUInteger)physical] boolValue]){
        UIView *surface=self.hostedScenes[(NSUInteger)physical];
        if([surface isKindOfClass:UIView.class])
            current=[[DFSceneHost sharedHost] bundleIDForHostedView:surface];
    }
    self.appPickerController.currentSlotBundleID=current;
    self.appPickerController.runningAppDetails=@{};
    // Original two-branch App badge semantics, but identity comes ONLY from
    // our scene-ready independent host. Respect swapped logical/physical slots.
    NSMutableOrderedSet<NSString *> *others=[NSMutableOrderedSet new];
    for(NSInteger visual=0;visual<DFSlotCountForPreset(self.preset);visual++){
        if(visual==slot)continue;
        NSInteger otherPhysical=[self physicalForVisual:visual];
        if(otherPhysical<0 || (NSUInteger)otherPhysical>=self.hostedScenes.count)continue;
        if(![self.sceneHandleReady[(NSUInteger)otherPhysical] boolValue])continue;
        UIView *otherScene=self.hostedScenes[(NSUInteger)otherPhysical];
        if(![otherScene isKindOfClass:UIView.class])continue;
        NSString *otherID=[[DFSceneHost sharedHost] bundleIDForHostedView:otherScene];
        if(otherID.length)[others addObject:otherID];
    }
    self.appPickerController.otherSlotBundleIDs=others.array;
    [self.appPickerController presentInstalledApps];
    [self.appPickerController refreshInstalledApps];
    self.appPickerWindow.hidden=NO;
    [self layoutControls];
    DFCLog([NSString stringWithFormat:@"real-app-picker-open slot=%ld",(long)slot]);
}
// Original Native12 CBMultitaskingOverlayView.setupRecentAppsCards @0xa678c
// queries runningBridgedApplications. Independent DuoFace instead queries
// real DFSceneHost-owned, ready scenes, NEVER installed/recent/demo records.
- (NSArray<NSString *> *)ownedRunningBundleIDs {
    DFSceneHost *host=[DFSceneHost sharedHost];
    NSMutableOrderedSet<NSString *> *bids=[NSMutableOrderedSet new];
    for(NSInteger physical=0;physical<4;physical++){
        if(![self.sceneHandleReady[(NSUInteger)physical] boolValue])continue;
        UIView *surface=self.hostedScenes[(NSUInteger)physical];
        if(![surface isKindOfClass:UIView.class])continue;
        NSString *bid=[host bundleIDForHostedView:surface];
        if(bid.length)[bids addObject:bid];
    }
    return bids.array;
}
- (NSInteger)visualSlotForVerifiedRunningBundleID:(NSString *)bundleID {
    if(![bundleID isKindOfClass:NSString.class] || !bundleID.length)return -1;
    NSInteger count=DFSlotCountForPreset(self.preset);
    DFSceneHost *owner=[DFSceneHost sharedHost];
    for(NSInteger physical=0;physical<4;physical++){
        if(![self.sceneHandleReady[(NSUInteger)physical] boolValue])continue;
        UIView *surface=self.hostedScenes[(NSUInteger)physical];
        NSString *actual=[surface isKindOfClass:UIView.class]?
                     [owner bundleIDForHostedView:surface]:nil;
        if(![actual isEqualToString:bundleID])continue;
        NSInteger visual=[self visualForPhysical:physical];
        if(visual>=0 && visual<count)return visual;
    }
    return -1; // hidden old preset: no speculative scene intervention
}
- (NSDictionary<NSString *,NSDictionary *> *)verifiedRunningDetails {
 DFSceneHost *host=[DFSceneHost sharedHost];
 NSMutableDictionary *result=[NSMutableDictionary new];
 for(NSInteger physical=0;physical<4;physical++){
   if(![self.sceneHandleReady[(NSUInteger)physical] boolValue])continue;
   UIView *surface=self.hostedScenes[(NSUInteger)physical];
   if(![surface isKindOfClass:UIView.class] ||
      ![host isLiveSceneForHostedView:surface])continue;
   NSString *bundle=[host bundleIDForHostedView:surface];
   if(!bundle.length)continue;
   UIWindow *window=self.appSceneWindows[(NSUInteger)physical];
   NSMutableDictionary *detail=[@{@"State":window&&!window.hidden?@"Scene hiển thị":@"Scene tạm ẩn",
       @"Physical":@(physical)} mutableCopy];
   NSNumber *pid=[host verifiedPIDForHostedView:surface];
   if(pid)detail[@"PID"]=pid;
   result[bundle]=detail;
 }
 return result;
}
- (void)openRunningAppManager {
    // The original Close page opens RECENT/RUNNING APP cards with genuine
    // per-app Close/Restart and Close All. X always dismisses this page.
    self.appPickerVisible=YES;
    self.pickerVisible=NO;
    self.styleVisible=NO;
    self.appPickerController.runningAppDetails=[self verifiedRunningDetails];
    self.appPickerController.runningRotateCapacity=DFSlotCountForPreset(self.preset);
    [self.appPickerController presentRunningApps:[self ownedRunningBundleIDs]];
    self.appPickerWindow.hidden=NO;
    [self layoutControls];
    DFCLog([NSString stringWithFormat:@"original-running-close-open actual=%lu",
        (unsigned long)[self ownedRunningBundleIDs].count]);
}
- (void)appPicker:(DFAppPickerVC *)picker closeRunningBundleID:(NSString *)bundleID {
    if(picker!=self.appPickerController)return;
    NSInteger slot=[self visualSlotForVerifiedRunningBundleID:bundleID];
    if(slot<0){DFCLog(@"close-refused-no-live-owned-bundle");return;}
    [self closeHostedSlot:slot];
    picker.runningAppDetails=[self verifiedRunningDetails];
    [picker presentRunningApps:[self ownedRunningBundleIDs]];
}
- (void)appPicker:(DFAppPickerVC *)picker restartRunningBundleID:(NSString *)bundleID {
    if(picker!=self.appPickerController)return;
    NSInteger slot=[self visualSlotForVerifiedRunningBundleID:bundleID];
    if(slot<0){DFCLog(@"restart-refused-no-live-owned-bundle");return;}
    [self closeHostedSlot:slot];
    self.selectedSlot=slot;
    // Use the EXISTING real SceneHost asynchronous app-start path, not a
    // fake ACK or a UIApplication deep link.
    [self appPicker:picker didSelectBundleID:bundleID displayName:bundleID];
    DFCLog([NSString stringWithFormat:@"restart-real-scene-pending bundle=%@",bundleID]);
}
- (void)appPicker:(DFAppPickerVC *)picker rotateRunningClockwise:(BOOL)clockwise {
 if(picker!=self.appPickerController)return;
 if(![self rotateHostedAppsClockwise:clockwise]){
    DFCLog(@"workspace-rotation-rejected-missing-ready-scene-or-pending");
    return;
 }
 picker.runningAppDetails=[self verifiedRunningDetails];
 [picker presentRunningApps:[self ownedRunningBundleIDs]];
}
- (void)appPickerCloseAllRunning:(DFAppPickerVC *)picker {
    if(picker!=self.appPickerController)return;
    NSArray<NSString *> *snapshot=[self ownedRunningBundleIDs];
    for(NSString *bid in snapshot){
        NSInteger slot=[self visualSlotForVerifiedRunningBundleID:bid];
        if(slot>=0)[self closeHostedSlot:slot];
    }
    picker.runningAppDetails=[self verifiedRunningDetails];
    [picker presentRunningApps:[self ownedRunningBundleIDs]];
    DFCLog([NSString stringWithFormat:@"close-all-owned-live-scene-count=%lu",
        (unsigned long)snapshot.count]);
}
- (void)appPickerDidCancel:(DFAppPickerVC *)picker {
    if(picker!=self.appPickerController)return;
    self.appPickerVisible=NO;
    self.appPickerWindow.hidden=YES;
    [self noteUserActivity];
}
- (void)appPicker:(DFAppPickerVC *)picker
 didSelectBundleID:(NSString *)bundleID displayName:(NSString *)name {
    if(picker!=self.appPickerController || !self.appPickerWindow || 
       ![bundleID isKindOfClass:NSString.class] || !bundleID.length)return;
    NSInteger slot=self.selectedSlot;
    NSInteger physicalSlot=[self physicalForVisual:slot];
    if(physicalSlot<0 || physicalSlot>=DFSlotCountForPreset(self.preset))return;
    DFSceneHost *owner=[DFSceneHost sharedHost];
    UIView *active=self.hostedScenes[(NSUInteger)physicalSlot];
    UIView *pending=self.pendingScenes[(NSUInteger)physicalSlot];
    NSString *activeID=[active isKindOfClass:UIView.class]?
         [owner bundleIDForHostedView:active]:nil;
    if([activeID isEqualToString:bundleID]){
        self.appPickerVisible=NO;
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
        self.appPickerVisible=YES;
        self.appPickerWindow.hidden=NO;
        [self layoutControls];
        return;
    }
    UIView *container=self.appSceneContainers[(NSUInteger)physicalSlot];
    host.frame=container.bounds;
    host.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    // A transparent pending host must not steal touch input from the
    // still-running application underneath until the new scene is ready.
    host.userInteractionEnabled=NO;
    self.pendingScenes[(NSUInteger)physicalSlot]=host;
    [container addSubview:host];
    self.appPickerVisible=NO;
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
          NSString *bundle=[[DFSceneHost sharedHost] bundleIDForHostedView:host];
          if(bundle.length && !DFSavePhysicalBundle(i,bundle))
             DFCLog(@"workspace-slot-save-failed-no-scene-impact");
          self.workspace=DFCurrentWorkspace();
          if(self.restorePending && self.restoringPhysical==i){
             self.restorePending=NO;
             self.restoringPhysical=-1;
             dispatch_async(dispatch_get_main_queue(),^{[self restoreNextSavedWorkspaceApp];});
          }
          [self layoutControls];
          if([prior isKindOfClass:UIView.class] && prior!=host)
              [[DFSceneHost sharedHost] releaseHostedView:prior];
          NSInteger visual=[self visualForPhysical:i];
          [self noteUserActivity];
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
          if(self.restorePending && self.restoringPhysical==i){
             self.restorePending=NO;
             self.restoringPhysical=-1;
             dispatch_async(dispatch_get_main_queue(),^{[self restoreNextSavedWorkspaceApp];});
          }
          DFCLog([NSString stringWithFormat:
            @"scene-replace-rolled-back-old-app-retained slot=%ld error=%@",
            (long)i,note.userInfo[@"error"]?:@"unknown"]);
          [self layoutControls];return;
       }
       if(self.hostedScenes[(NSUInteger)i]==host){
          self.hostedScenes[(NSUInteger)i]=NSNull.null;
          self.sceneHandleReady[(NSUInteger)i]=@NO;
          NSInteger visual=[self visualForPhysical:i];
          if(self.focus==visual)self.focus=-1;
          self.appSceneContainers[(NSUInteger)i].hidden=YES;
          DFCLog([NSString stringWithFormat:@"real-scene-failed slot=%ld error=%@",
                (long)i,note.userInfo[@"error"]?:@"unknown"]);
          [self layoutControls];return;
       }
    }
}
// Original Close ends selected app; X dismisses the menu only.
- (void)closeHostedSlot:(NSInteger)slot {
    NSInteger physicalSlot=[self physicalForVisual:slot];
    if(physicalSlot<0||physicalSlot>=DFSlotCountForPreset(self.preset))return;
    DFSceneHost *owner=[DFSceneHost sharedHost];
    UIView *pending=self.pendingScenes[(NSUInteger)physicalSlot];
    if([pending isKindOfClass:UIView.class])[owner releaseHostedView:pending];
    self.pendingScenes[(NSUInteger)physicalSlot]=NSNull.null;
    UIView *view=self.hostedScenes[(NSUInteger)physicalSlot];
    if([view isKindOfClass:UIView.class])[owner releaseHostedView:view];
    self.hostedScenes[(NSUInteger)physicalSlot]=NSNull.null;
    self.sceneHandleReady[(NSUInteger)physicalSlot]=@NO;
    if(!DFSavePhysicalBundle(physicalSlot,@""))
        DFCLog(@"workspace-slot-clear-prefs-failed");
    self.workspace=DFCurrentWorkspace();
    if(self.focus==slot)self.focus=-1;
    UIView *container=self.appSceneContainers[(NSUInteger)physicalSlot];
    container.hidden=YES;
    [self layoutControls];
    [self emit:@"Close" ratio:@(slot)];
    DFCLog([NSString stringWithFormat:@"app-host-close slot=%ld",(long)slot]);
}
// Both the circular grip and the surrounding track use this one state machine.
- (void)beginDividerDragAt:(CGPoint)p {
    if(_dividerDrag.active || self.dividerWindow.hidden)return;
    CGFloat extent=self.verticalDivider?self.contentRect.size.width:self.contentRect.size.height;
    CGFloat span=self.verticalDivider?self.dividerTrack.bounds.size.height:self.dividerTrack.bounds.size.width;
    _dividerDrag=DFDragBegin(p.x,p.y,self.verticalDivider,self.ratio,self.logoFraction,extent,span);
    self.panActive=_dividerDrag.active;
    [self noteUserActivity];
}
- (void)renderDividerDragFinal:(BOOL)final {
    self.ratio=_dividerDrag.ratio;
    self.logoFraction=_dividerDrag.logo;
    [self layoutControls];
    NSTimeInterval now=NSDate.date.timeIntervalSince1970;
    if(_dividerDrag.axis==DFDragRatio && (final || now-self.lastSent>.05)){
        self.lastSent=now;
        [self emit:@"Ratio" ratio:@(self.ratio)];
    }
}
- (void)updateDividerDragAt:(CGPoint)p {
    if(!_dividerDrag.active)return;
    DFDragAxis previous=_dividerDrag.axis;
    DFDragMove(&_dividerDrag,p.x,p.y);
    if(previous!=_dividerDrag.axis)
        DFCLog(_dividerDrag.axis==DFDragRatio?@"divider-axis-locked-ratio":@"divider-axis-locked-logo-no-hold");
    [self renderDividerDragFinal:NO];
}
- (BOOL)finishDividerDragAt:(CGPoint)p cancelled:(BOOL)cancelled {
    if(!_dividerDrag.active)return NO;
    BOOL tap=DFDragFinish(&_dividerDrag,p.x,p.y,cancelled);
    if(!cancelled && _dividerDrag.axis==DFDragRatio)
        _dividerDrag.ratio=DFCSnap(_dividerDrag.ratio);
    [self renderDividerDragFinal:YES];
    if(!cancelled && _dividerDrag.axis!=DFDragUndecided)[self saveSplitState];
    self.panActive=NO;
    DFCLog([NSString stringWithFormat:@"divider-axis-end axis=%d cancel=%d ratio=%.3f logo=%.3f",
        (int)_dividerDrag.axis,cancelled,self.ratio,self.logoFraction]);
    [self noteUserActivity];
    return tap;
}
// User-approved 3s logo hold is deliberately distinct from the original
// machine-code divider's rotate/swap menu actions. Ratio drag remains available
// on the surrounding track immediately, not through this circular grip.
- (void)logoTouchDown:(id)sender {
    if(sender!=self.dividerLogo || _dividerDrag.active || self.logoTouchPending)return;
    CGPoint point=((DFNativeDividerGripButton *)sender).trackedScreenPoint;
    self->_logoHoldGate=DFLogoHoldBegin(NSProcessInfo.processInfo.systemUptime,
                                       point.x,point.y);
    if(!self->_logoHoldGate.tracking)return;
    self.logoWakeOnlyTap=(NSDate.date.timeIntervalSince1970>self.controlsUntil);
    self.logoTouchPending=YES;
    [self noteUserActivity]; // Keep the grip visible during the physical hold.
    DFCLog(@"logo-3s-hold-armed-no-ratio-drag");
}
- (void)logoTouchChanged:(id)sender {
    if(sender!=self.dividerLogo || !self.logoTouchPending)return;
    CGPoint point=((DFNativeDividerGripButton *)sender).trackedScreenPoint;
    if(self->_logoHoldGate.unlocked){
        [self updateDividerDragAt:point];
    }else if(DFLogoHoldAdvance(&self->_logoHoldGate,
                 NSProcessInfo.processInfo.systemUptime,point.x,point.y,
                 self.verticalDivider)){
        // Original 0.0.90 video orientation and live scene geometry are NOT
        // modified; this drag is restricted to the normalized logo position.
        [self beginDividerDragAt:CGPointMake(self->_logoHoldGate.x,
                                             self->_logoHoldGate.y)];
        if(_dividerDrag.active){
            self->_dividerDrag.axis=DFDragLogo;
            [self updateDividerDragAt:point];
            DFCLog(@"logo-hold-3s-unlocked-parallel-only");
        }
    }
    // Do not hide controls on an active, stationary or moving raw contact.
    self.controlsUntil=NSDate.date.timeIntervalSince1970+4.0;
}
- (void)logoTouchFinished:(id)sender inside:(BOOL)inside cancelled:(BOOL)cancelled {
    if(sender!=self.dividerLogo || !self.logoTouchPending)return;
    CGPoint point=((DFNativeDividerGripButton *)sender).trackedScreenPoint;
    BOOL allowSwap=DFLogoHoldIsQuickTap(&self->_logoHoldGate,
                       NSProcessInfo.processInfo.systemUptime,
                       point.x,point.y,inside,cancelled,self.logoWakeOnlyTap);
    BOOL moved=self->_logoHoldGate.unlocked && _dividerDrag.active;
    if(moved)[self finishDividerDragAt:point cancelled:cancelled];
    self->_logoHoldGate=(DFLogoHoldGate){0};
    self.logoTouchPending=NO;
    self.logoWakeOnlyTap=NO;
    if(!moved)[self noteUserActivity];
    if(allowSwap)[self swapPressed:sender];
}
- (void)swapPressed:(id)sender {
    // A drag never dispatches this tap action.
    BOOL justWaking=self.logoWakeOnlyTap && sender==self.dividerLogo;
    self->_logoHoldGate=(DFLogoHoldGate){0};
    self.logoTouchPending=NO;
    _dividerDrag.active=false;
    self.logoWakeOnlyTap=NO;
    [self noteUserActivity];
    if(justWaking){DFCLog(@"logo-invisible-first-tap-wake-only");return;}
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
    UIGestureRecognizerState state=pan.state;
    CGPoint current=[self dividerTouchOnScreen:pan];
    if(state==UIGestureRecognizerStateBegan){
        if(self.logoTouchPending || _dividerDrag.active || self.dividerWindow.hidden)return;
        // Recover touch-down from translation: Began arrives after UIKit slop.
        CGPoint translation=[pan translationInView:self.dividerTrack];
        CGPoint local=[pan locationInView:self.dividerTrack];
        CGPoint initial=CGPointMake(local.x-translation.x,local.y-translation.y);
        CGPoint screen=[self.dividerTrack convertPoint:initial
            toCoordinateSpace:self.dividerWindow.screen.coordinateSpace];
        [self beginDividerDragAt:screen];
        [self updateDividerDragAt:current];
        DFCLog(@"divider-pan-begin");
    }else if(!self.logoTouchPending && _dividerDrag.active){
        if(state==UIGestureRecognizerStateChanged)[self updateDividerDragAt:current];
        else if(state==UIGestureRecognizerStateEnded || state==UIGestureRecognizerStateCancelled || state==UIGestureRecognizerStateFailed){
            [self finishDividerDragAt:current cancelled:state!=UIGestureRecognizerStateEnded];
            DFCLog(state==UIGestureRecognizerStateEnded?@"divider-pan-end":@"divider-pan-cancel");
        }
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
        self.panActive=YES;
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
    if(end||cancel)self.panActive=NO;
    if(end){[self saveSplitState];[self noteUserActivity];}
    if(end||cancel)DFCLog(end?@"secondary-divider-pan-end":@"secondary-divider-pan-cancel");
}
// Native12 CBWindow.carPlayUsableBounds is normal content; whole-host
// fullscreen uses real screen bounds (WIRING_REPORT original CBWindow
// @0xb0ef4 / @0xb1aac), NOT scaling one pane and NOT per-slot focus.
//
// This is ONLY the reversible SpringBoard source-window geometry half.
// The real iOS16 CarPlay Dashboard Dock receiver/ACK is a separate owner;
// no caller may trigger this method until that dock is verified hidden.
- (BOOL)applyHostFullscreenToScreenBoundsAfterDockAck:(CGRect)screenBounds {
    if(self.hostFullscreen)return YES;
    // A native App card may remain shown while a real Dock ACK is pending.
    // Only the existing verified completion dismisses it, not the button.
    if(self.startupActive || !self.windows.count ||
       self.appSceneWindows.count!=4 || self.appSceneContainers.count!=4)return NO;
    UIWindow *anchor=self.windows.firstObject;
    CGRect actual=anchor.screen.bounds;
    CGRect saved=self.contentRect;
    if(!anchor.screen || anchor.screen==UIScreen.mainScreen ||
       !isfinite(screenBounds.origin.x) || !isfinite(screenBounds.origin.y) ||
       !isfinite(screenBounds.size.width) || !isfinite(screenBounds.size.height) ||
       screenBounds.size.width<300 || screenBounds.size.height<145 ||
       fabs(actual.origin.x-screenBounds.origin.x)>1.0 ||
       fabs(actual.origin.y-screenBounds.origin.y)>1.0 ||
       fabs(actual.size.width-screenBounds.size.width)>1.0 ||
       fabs(actual.size.height-screenBounds.size.height)>1.0 ||
       !CGRectContainsRect(actual,saved))return NO;
    for(UIWindow *window in self.windows)
        if(window.screen!=anchor.screen)return NO;
    self.normalContentRect=saved;
    self.contentRect=actual;
    self.hostFullscreen=YES;
    @try {
        [self layoutControls];
        CGRect pane[4];
        DFComputePresetFramesWithSecondary(self.contentRect,self.preset,
                  DFCClamp(self.ratio),self.secondaryRatio,pane);
        NSInteger count=DFSlotCountForPreset(self.preset);
        for(NSInteger i=0;i<count;i++){
            NSInteger visual=[self visualForPhysical:i];
            // Verification must match layoutControls: a focused/solo pane
            // occupies the whole host, not the preset's split-cell frame.
            CGRect rendered=(self.focus>=0 && visual==self.focus)?actual:pane[visual];
            UIWindow *appWindow=self.appSceneWindows[(NSUInteger)i];
            CGRect observed=appWindow.frame;
            CGRect local=self.appSceneContainers[(NSUInteger)i].frame;
            const CGFloat eps=0.5;
            BOOL contained=CGRectContainsRect(
                CGRectInset(actual,-eps,-eps),observed);
            BOOL matched=fabs(observed.origin.x-rendered.origin.x)<=eps &&
                fabs(observed.origin.y-rendered.origin.y)<=eps &&
                fabs(observed.size.width-rendered.size.width)<=eps &&
                fabs(observed.size.height-rendered.size.height)<=eps;
            BOOL innerMatched=fabs(local.origin.x)<=eps &&
                fabs(local.origin.y)<=eps &&
                fabs(local.size.width-rendered.size.width)<=eps &&
                fabs(local.size.height-rendered.size.height)<=eps;
            if(!contained || !matched || !innerMatched){
                DFCLog([NSString stringWithFormat:
                    @"host-zoom-validation-rejected slot=%ld visual=%ld focus=%ld contained=%d matched=%d inner=%d window=%@ local=%@ expected=%@ screen=%@",
                    (long)i,(long)visual,(long)self.focus,contained,matched,innerMatched,
                    NSStringFromCGRect(observed),NSStringFromCGRect(local),
                    NSStringFromCGRect(rendered),NSStringFromCGRect(actual)]);
                [self restoreHostFullscreenGeometry];
                return NO;
            }
        }
    } @catch(NSException *exception) {
        DFCLog([NSString stringWithFormat:@"host-zoom-geometry-exception=%@",exception.name]);
        [self restoreHostFullscreenGeometry];
        return NO;
    }
    // Geometry applied does NOT mean actual native Dock is hidden.
    DFCLog([NSString stringWithFormat:@"host-zoom-geometry-only screen=%@ normal=%@",
            NSStringFromCGRect(actual),NSStringFromCGRect(saved)]);
    return YES;
}
- (void)restoreHostFullscreenGeometry {
    if(!self.hostFullscreen)return;
    CGRect previous=self.normalContentRect;
    self.hostFullscreen=NO;
    self.contentRect=previous;
    // Never change focus, splitPreset, dragged ratio or running scenes.
    [self layoutControls];
    DFCLog([NSString stringWithFormat:@"host-zoom-geometry-restored %@",NSStringFromCGRect(previous)]);
}
- (void)stop {
    ++self.restoreGeneration;
    self.restorePending=NO;
    self.restoringPhysical=-1;
    [self.restoreQueue removeAllObjects];
    self.logoTouchPending=NO;
    self->_logoHoldGate=(DFLogoHoldGate){0};
    _dividerDrag.active=false;
    if(self.hostFullscreen)[self restoreHostFullscreenGeometry];
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
    [self.dividerLogo.layer removeAnimationForKey:@"dfNative12GripPulse"];
    for(UIWindow *w in self.windows)w.hidden=YES;
    DFCLog(@"home-teardown-all-external-windows-hidden-before-scene-invalidate");
    [[DFSceneHost sharedHost] stopAllHosts];
    for(UIWindow *w in self.windows)w.rootViewController=nil;
    [self.windows removeAllObjects];
    [self.pillWindows removeAllObjects];
    self.dividerWindow=nil;self.secondaryDividerWindow=nil;self.secondaryDividerTrack=nil;self.pickerWindow=nil;self.styleWindow=nil;self.splashWindow=nil;
    self.styleChoices=nil;self.styleSelectionBadges=nil;self.styleHeaderActions=nil;self.styleHeaderLogo=nil;self.styleVisible=NO;
    self.styleHeaderTitle=nil;self.styleZoom=nil;self.styleModeBar=nil;
    self.appPickerVisible=NO;
    self.pickerVisible=NO;
    self.appPickerWindow=nil;self.appPickerController=nil;
    [self.appSceneContainers removeAllObjects];
    [self.appSceneWindows removeAllObjects];[self.hostedScenes removeAllObjects];
    [self.pendingScenes removeAllObjects];
    [self.sceneHandleReady removeAllObjects];
    self.dividerTrack=nil;self.dividerLogo=nil;
    self.pillMenu=nil;self.pillZoom=nil;self.pickerBrand=nil;
    self.menuBrandImage=nil;self.menuContext=nil;self.menuDismiss=nil;self.menuActions=nil;
    DFCLog(@"native12-chrome-stop");
}
@end

