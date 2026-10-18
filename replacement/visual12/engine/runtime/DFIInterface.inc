// Independent UI, loaded after DFV12SceneHost so all scene lifetime operations stay shared.
#import "DFIApprovedVisuals.h"
#include "DFINativeShell.inc"
#include "DFINativePickerCards.inc"
static void DFIStop(void);
static NSMutableSet<NSString *> *DFIManaged;
static NSMutableSet<NSString *> *DFITerminating;
static id DFIStateMonitor;
static NSString *DFICloseGuard(NSString *bid) {
    if(![DFIManaged containsObject:bid]) return DFIT(@"App không do Split quản lý",@"Not managed by Split");
    SEL front=NSSelectorFromString(@"_accessibilityFrontMostApplication");
    if(![UIApplication.sharedApplication respondsToSelector:front]) return DFIT(@"Không xác minh được app trên iPhone",@"Cannot verify foreground phone app");
    id app=DFIGet(UIApplication.sharedApplication,@"_accessibilityFrontMostApplication");
    if([DFIGet(app,@"bundleIdentifier") isEqual:bid]) return DFIT(@"App đang mở trên iPhone",@"App is in use on iPhone");
    return nil;
}
static NSInteger DFIAppState(NSString *bid) {
    SEL s=NSSelectorFromString(@"applicationStateForApplication:");
    return [DFIStateMonitor respondsToSelector:s]?((NSInteger(*)(id,SEL,id))objc_msgSend)(DFIStateMonitor,s,bid):-1;
}
static void DFITerminate(NSString *bid,void(^detach)(void),void(^done)(NSString *)) {
    NSString *guard=DFICloseGuard(bid); if(guard){done(guard);return;}
    if([DFITerminating containsObject:bid]) {done(DFIT(@"Đang đóng…",@"Closing…"));return;}
    @try {
        Class contextClass=NSClassFromString(@"RBSTerminateContext"),requestClass=NSClassFromString(@"RBSTerminateRequest");
        id predicate=DFIObject(NSClassFromString(@"RBSProcessPredicate"),@"predicateMatchingBundleIdentifier:",bid);
        SEL contextInit=NSSelectorFromString(@"initWithExplanation:"),requestInit=NSSelectorFromString(@"initWithPredicate:context:"),execute=NSSelectorFromString(@"execute:error:");
        if(!predicate||![contextClass instancesRespondToSelector:contextInit]||![requestClass instancesRespondToSelector:requestInit]||![requestClass instancesRespondToSelector:execute]||DFIAppState(bid)<0){done(DFIT(@"iOS thiếu API đóng/xác minh",@"Close/verification API unavailable"));return;}
        id context=((id(*)(id,SEL,id))objc_msgSend)([contextClass alloc],contextInit,@"User closed app in DuoFace Mới");
        id request=((id(*)(id,SEL,id,id))objc_msgSend)([requestClass alloc],requestInit,predicate,context);
        [DFITerminating addObject:bid];if(detach)detach();
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
            NSError *error=nil;
            @try { ((void(*)(id,SEL,id __autoreleasing *,NSError *__autoreleasing *))objc_msgSend)(request,execute,NULL,&error); }
            @catch(NSException *e){error=DFIError(e.reason?:@"Termination exception");}
            dispatch_async(dispatch_get_main_queue(),^{
                if(error){[DFITerminating removeObject:bid];DFILog([NSString stringWithFormat:@"terminate %@ error=%@",bid,error]);done(error.localizedDescription);return;}
                // A successful request is not proof of process exit. Observe, then check for restart.
                __block int attempts=0;
                [NSTimer scheduledTimerWithTimeInterval:0.25 repeats:YES block:^(NSTimer *timer){
                    NSInteger state=DFIAppState(bid);
                    if(state==0){[timer invalidate];dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),dispatch_get_main_queue(),^{
                        NSInteger later=DFIAppState(bid);[DFITerminating removeObject:bid];
                        if(later==0)[DFIManaged removeObject:bid];
                        NSString *status=later==0?DFIT(@"Đã đóng",@"Closed"):DFIT(@"App đã tự chạy lại",@"App restarted");
                        DFILog([NSString stringWithFormat:@"terminate %@: %@ state=%ld",bid,status,(long)later]);done(status);
                    });}else if(++attempts>=12){[timer invalidate];[DFITerminating removeObject:bid];DFILog([NSString stringWithFormat:@"terminate %@ still running state=%ld",bid,(long)state]);done(DFIT(@"App vẫn chạy — chưa đóng được",@"Still running — could not close"));}
                }];
            });
        });
    }@catch(NSException *e){[DFITerminating removeObject:bid];DFILog(e.reason);done(DFIT(@"Không đóng được app",@"Could not close app"));}
}
static NSArray *DFIAvailableApps(void) {
    NSMutableArray *apps=[NSMutableArray array];
    id controller=DFIGet(NSClassFromString(@"SBApplicationController"),@"sharedInstance");
    for(id app in DFIGet(controller,@"allInstalledApplications")){
        NSString *bid=DFIGet(app,@"bundleIdentifier"),*name=DFIGet(app,@"displayName"),*type=DFIGet(app,@"bundleType");
        if(!bid.length||!name.length||[bid isEqual:DFIPreferences])continue;
        if(![type isEqual:@"User"]&&![@[@"com.apple.Maps",@"com.apple.mobilemusic",@"com.apple.mobilesafari",@"com.apple.podcasts",@"com.apple.MobileSMS"] containsObject:bid])continue;
        [apps addObject:@{@"id":bid,@"title":name}];
    }
    return [apps sortedArrayUsingComparator:^NSComparisonResult(id a,id b){return [a[@"title"] localizedCaseInsensitiveCompare:b[@"title"]];}];
}
@interface DFV12LayoutIcon : UIButton
@property(nonatomic) int kind;
@end
@implementation DFV12LayoutIcon
- (void)drawRect:(CGRect)rect{[super drawRect:rect];DFIFrames f=DFIFramesMake(CGRectInset(self.bounds,9,8),self.kind,self.kind==4?1./3:.5,self.kind==4?2./3:.5,-1);[[UIColor.whiteColor colorWithAlphaComponent:.85]setStroke];for(int i=0;i<f.count;i++){UIBezierPath *p=[UIBezierPath bezierPathWithRoundedRect:CGRectInset(f.panes[i],1.5,1.5) cornerRadius:2];p.lineWidth=1.2;[p stroke];}}
@end
@interface DFV12SplitController ()
@property(nonatomic,strong) DFINativeSplitSurface *nativeSplitSurface;
@property(nonatomic,strong) NSArray<UIView *> *panes;
@property(nonatomic,strong) NSMutableArray *hosts;
@property(nonatomic,strong) NSArray<UIButton *> *emptyButtons;
@property(nonatomic,strong) NSArray<UIButton *> *paneButtons;
@property(nonatomic,strong) NSArray<UIButton *> *paneZoomButtons;
@property(nonatomic,strong) NSArray<UIVisualEffectView *> *panePills;
@property(nonatomic,strong) NSArray<UIButton *> *grips;
@property(nonatomic,strong) NSArray<UIView *> *lines;
@property(nonatomic,strong) NSMutableArray<NSNumber *> *dividerLogoPositions;
@property(nonatomic,strong) UIButton *edge;
@property(nonatomic,strong) UIVisualEffectView *toolbar;
@property(nonatomic,strong) UIView *toolbarStack;
@property(nonatomic,strong) UIVisualEffectView *panel;
@property(nonatomic,strong) UIControl *pickerShade;
@property(nonatomic,strong) UIButton *pickerClose;
@property(nonatomic) BOOL interactionActive;
@property(nonatomic,strong) DFINativePickerCardsController *list;
@property(nonatomic,strong) NSTimer *hideTimer;
@property(nonatomic) NSInteger layoutKind,maximized,panelPane;
@property(nonatomic) CGFloat fraction,secondary;
@property(nonatomic) BOOL shuttingDown;
@property(nonatomic,strong) UILabel *statusLabel;
@property(nonatomic,strong) UIImageView *approvedLogo;
@property(nonatomic,strong) DFV12NativeHUD8 *native8HUD;
@property(nonatomic) BOOL native8HUDPositionRestored;
@property(nonatomic) BOOL savedAppsRestoreStarted;
@property(nonatomic) NSInteger nextSavedPane;
@property(nonatomic) NSInteger activePane,selectedTab;
@property(nonatomic,strong) NSMutableSet<NSNumber *> *pendingPanes;
@end
@implementation DFV12SplitController
- (void)loadView {
 self.view=[[DFINativeWindowSurface alloc]initWithFrame:UIScreen.mainScreen.bounds];
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations{return UIInterfaceOrientationMaskAll;}
- (BOOL)prefersStatusBarHidden{return YES;}
- (UIButton *)button:(NSString *)symbol label:(NSString *)label action:(SEL)action {
 UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];[b setImage:[UIImage systemImageNamed:symbol] forState:UIControlStateNormal];b.tintColor=UIColor.whiteColor;b.accessibilityLabel=label;[b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];return b;
}
- (UIVisualEffectView *)glass {
 // Native structure: a backdrop outside the native sheet card and its header.
 [self.pickerShade removeFromSuperview];
 UIControl *shade=[[UIControl alloc]initWithFrame:self.view.bounds];
 shade.backgroundColor=[UIColor.blackColor colorWithAlphaComponent:.34];
 shade.accessibilityIdentifier=@"duoface.native.picker.backdrop";
 [shade addTarget:self action:@selector(dismissPanel) forControlEvents:UIControlEventTouchUpInside];
 [self.view addSubview:shade];self.pickerShade=shade;
 DFINativePickerCard *card=[[DFINativePickerCard alloc]initWithFrame:CGRectZero];
 [self.view addSubview:card];return card;
}
// Native12 picker: approved horizontal logo + four tabs on a single 30pt row
// INSIDE the sheet. The root split never owns a floating toolbar.
- (void)attachNativePickerHeader {
 if(!self.panel)return;
 if(self.toolbar.superview!=self.panel.contentView){[self.toolbar removeFromSuperview];[self.panel.contentView addSubview:self.toolbar];}
 if(!self.pickerClose){
  self.pickerClose=[self button:@"xmark" label:DFIT(@"Đóng bảng chọn",@"Dismiss picker") action:@selector(dismissPanel)];
  self.pickerClose.backgroundColor=[UIColor colorWithWhite:0.15 alpha:0.92];
  self.pickerClose.layer.cornerRadius=13;
 }
 if(self.pickerClose.superview!=self.panel.contentView){[self.pickerClose removeFromSuperview];[self.panel.contentView addSubview:self.pickerClose];}
 self.toolbar.hidden=NO;
 [self updateApprovedTabs];
}
- (void)viewDidLoad {
 [super viewDidLoad];self.view.backgroundColor=UIColor.clearColor;
 self.overrideUserInterfaceStyle=UIUserInterfaceStyleDark;
 self.nativeSplitSurface=((DFINativeWindowSurface *)self.view).splitSurface;
 NSAssert(self.nativeSplitSurface,@"Native split surface absent");
 self.layoutKind=DFIPref(@"layout")?[DFIPref(@"layout") integerValue]:2;if(self.layoutKind<1||self.layoutKind>8)self.layoutKind=2;
 self.fraction=DFIPref(@"fraction")?DFIClamp([DFIPref(@"fraction") doubleValue],.02,.98):(self.layoutKind==4?1./3:.5);
 self.secondary=DFIPref(@"secondary")?DFIClamp([DFIPref(@"secondary") doubleValue],.02,.98):(self.layoutKind==4?2./3:.5);self.maximized=-1;self.activePane=0;self.selectedTab=0;self.interactionActive=NO;self.pendingPanes=[NSMutableSet set];
 NSArray *savedLogo=DFIPref(@"dividerLogoPositions");
 self.dividerLogoPositions=[NSMutableArray arrayWithObjects:@(.5),@(.5),nil];
 if([savedLogo isKindOfClass:NSArray.class] && savedLogo.count==2){
  for(int n=0;n<2;n++)if([savedLogo[n] respondsToSelector:@selector(doubleValue)]){
   self.dividerLogoPositions[n]=@(DFIClamp([savedLogo[n] doubleValue],.1,.9));
  }
 }
 self.hosts=[NSMutableArray arrayWithObjects:NSNull.null,NSNull.null,NSNull.null,nil];NSMutableArray *panes=[NSMutableArray array],*empty=[NSMutableArray array],*buttons=[NSMutableArray array],*zooms=[NSMutableArray array],*pills=[NSMutableArray array],*grips=[NSMutableArray array],*lines=[NSMutableArray array];
 for(int i=0;i<3;i++){
  UIView *p=[UIView new];p.backgroundColor=UIColor.blackColor;p.clipsToBounds=YES;
  p.accessibilityIdentifier=[NSString stringWithFormat:@"duoface.native.pane.%d",i];
  [self.nativeSplitSurface addSubview:p];[panes addObject:p];
  UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];[b setTitle:DFIT(@"＋ Chọn ứng dụng",@"＋ Choose app") forState:0];b.tintColor=UIColor.whiteColor;b.titleLabel.font=[UIFont systemFontOfSize:DFIFontSize()];b.titleLabel.numberOfLines=0;b.titleLabel.textAlignment=NSTextAlignmentCenter;b.tag=i;[b addTarget:self action:@selector(choose:) forControlEvents:UIControlEventTouchUpInside];[p addSubview:b];[empty addObject:b];
  DFINativeSlotPillView *pill=[[DFINativeSlotPillView alloc]
    initWithSlot:i target:self pickAction:@selector(choose:)
    focusAction:@selector(zoomPane:)
    restoreAction:@selector(restorePane:)];
  [self.nativeSplitSurface addSubview:pill];
  [buttons addObject:pill.dotsButton];[zooms addObject:pill.expandButton];
  [pills addObject:pill];
 }
 self.panes=panes;self.emptyButtons=empty;self.paneButtons=buttons;
 self.paneZoomButtons=zooms;self.panePills=pills;
 for(int i=0;i<2;i++){
  DFINativeDividerTrack *track=[[DFINativeDividerTrack alloc]
    initWithIndex:i target:self action:@selector(drag:)];
  [self.nativeSplitSurface addSubview:track];[lines addObject:track];
  DFINativeDividerLogo *logo=[[DFINativeDividerLogo alloc]
    initWithIndex:i target:self tapAction:@selector(swapPanes)
    holdAction:@selector(moveDividerLogo:)];
  [self.nativeSplitSurface addSubview:logo];[grips addObject:logo];
 }
 self.grips=grips;self.lines=lines;
 self.edge=[self button:@"ellipsis" label:DFIT(@"Mở thanh công cụ",@"Show toolbar") action:@selector(edgeTap)];self.edge.layer.cornerRadius=12;self.edge.backgroundColor=[UIColor.blackColor colorWithAlphaComponent:.18];[self.view addSubview:self.edge];
 // Native12 sheet header remains detached until a picker/layout/recents sheet opens.
 self.toolbar=[[DFINativePickerMenuBar alloc]initWithFrame:CGRectZero];self.toolbar.hidden=YES;
 self.toolbarStack=[UIView new];self.toolbarStack.backgroundColor=UIColor.clearColor;
 [self.toolbar.contentView addSubview:self.toolbarStack];
 NSArray *symbols=@[@"square.grid.2x2",@"arrow.up.left.and.arrow.down.right",
     @"rectangle.3.group",@"xmark.circle"],*labels=@[@"App",@"Zoom",@"Style",@"Close"],
     *actions=@[@"showAppMenu",@"toggleZoom",@"layouts",@"tasks"];
 self.approvedLogo=[[UIImageView alloc]initWithImage:DFIApprovedHeaderLogo()];
 self.approvedLogo.contentMode=UIViewContentModeScaleAspectFit;
 self.approvedLogo.backgroundColor=UIColor.clearColor;
 [self.toolbar.contentView addSubview:self.approvedLogo];
 for(int i=0;i<4;i++){
  UIButton *b=[self button:symbols[i] label:labels[i] action:NSSelectorFromString(actions[i])];
  b.tag=i;
  DFIStyleApprovedTab(b,labels[i],symbols[i],i==0);
  [self.toolbarStack addSubview:b];
 }
 self.native8HUD=[[DFV12NativeHUD8 alloc] initWithFrame:CGRectMake(0,0,104,46)];
 // Speed8 UIView is mounted once on the existing QA controller, never on a second window.
 [self.view addSubview:self.native8HUD];
 self.native8HUD.qaHasActiveSplit=NO;
 __weak typeof(self) weakNative8Owner=self;
 self.native8HUD.qaSplitState=^BOOL{
  DFV12SplitController *owner=weakNative8Owner;
  if(!owner || owner.shuttingDown || owner.maximized>=0)return NO;
  NSInteger live=0;
  for(id host in owner.hosts)if(host!=NSNull.null && [host scene])live++;
  return live>=2;
 };
 self.statusLabel=[UILabel new];self.statusLabel.textColor=UIColor.whiteColor;self.statusLabel.backgroundColor=[UIColor.blackColor colorWithAlphaComponent:.5];self.statusLabel.font=[UIFont systemFontOfSize:12];self.statusLabel.textAlignment=NSTextAlignmentCenter;self.statusLabel.numberOfLines=2;self.statusLabel.hidden=YES;[self.view addSubview:self.statusLabel];
 // Do not request app scenes from viewDidLoad, before external window/layout
 // exists. Original host binds the real CarPlay UIWindow first.
}
- (void)viewDidAppear:(BOOL)animated {
 [super viewDidAppear:animated];
 if(self.shuttingDown || self.savedAppsRestoreStarted || !self.view.window ||
    CGRectIsEmpty(self.view.bounds))return;
 self.savedAppsRestoreStarted=YES;
 self.nextSavedPane=0;
 DFILog([NSString stringWithFormat:
       @"Native UI root attached bounds=%@ usable=%@ safe=%@ windowLevel=%.1f",
       NSStringFromCGRect(self.view.bounds),
       NSStringFromCGRect([(DFINativeWindowSurface *)self.view usableContentFrame]),
       NSStringFromUIEdgeInsets(self.view.safeAreaInsets),self.view.window.windowLevel]);
 // Only the SpringBoard-process window inventory is visible here. The real
 // CarPlay status/dock windows may live in another process; absence from this
 // list is NOT evidence they do not exist. Never force windowLevel blindly.
 NSUInteger statusSeen=0;
 for(UIWindow *candidate in UIApplication.sharedApplication.windows){
   NSString *type=NSStringFromClass(candidate.class);
   BOOL chrome=[@[@"DBStatusBarWindow",@"CARStatusBarWindow",@"DBDockWindow"]
                         containsObject:type];
   if(candidate!=self.view.window && !chrome)continue;
   if(chrome)statusSeen++;
   DFILog([NSString stringWithFormat:
       @"Native UI SB window %@ level=%.1f hidden=%d frame=%@ safe=%@ owner=%d",
       type,candidate.windowLevel,(int)candidate.hidden,
       NSStringFromCGRect(candidate.frame),
       NSStringFromUIEdgeInsets(candidate.safeAreaInsets),
       (int)(candidate==self.view.window)]);
 }
 DFILog([NSString stringWithFormat:
       @"Native UI SB window inventory chrome_seen=%lu (CarPlay process must be checked separately)",
       (unsigned long)statusSeen]);
 __weak typeof(self) weak=self;
 dispatch_async(dispatch_get_main_queue(),^{[weak.view layoutIfNeeded];[weak restoreNextSavedPane];});
}
- (void)restoreNextSavedPane {
 if(self.shuttingDown || !self.view.window || !self.savedAppsRestoreStarted)return;
 NSInteger count=self.layoutKind==1?1:(self.layoutKind<=3?2:3);
 // At most one scene request per event-loop turn. Wait for scene ready/failure
 // before starting the next saved app, avoiding parallel respring restore.
 while(self.nextSavedPane<count){
     NSInteger pane=self.nextSavedPane++;
     NSString *bid=DFIPref(@[@"left",@"right",@"third"][pane]);
     if(![bid isKindOfClass:NSString.class] || !bid.length)continue;
     if(self.hosts[pane]!=NSNull.null || [self.pendingPanes containsObject:@(pane)])continue;
     [self.view layoutIfNeeded];
     if(CGRectIsEmpty(self.panes[pane].bounds)) {
         DFILog([NSString stringWithFormat:@"QA saved app skipped empty pane=%ld",(long)pane]);
         continue;
     }
     [self openBundle:bid pane:pane];
     if([self.pendingPanes containsObject:@(pane)])return;
 }
}
- (void)updateInteractionBorders {
 // Bản duyệt: đỏ #E3020F, rộng 1pt, không nhấp nháy, ẩn khi tập trung một ô
 // hoặc thanh điều khiển về trạng thái nghỉ.
 [CATransaction begin];[CATransaction setDisableActions:YES];
 for(int i=0;i<3;i++){
     BOOL active=self.hosts[i]!=NSNull.null &&
         self.panel!=nil && self.maximized<0 &&
         !CGRectIsEmpty(self.panes[i].frame);
     self.panes[i].layer.borderWidth=active?1.0:0.0;
     self.panes[i].layer.borderColor=
         (active?DFIApprovedRed():UIColor.clearColor).CGColor;
 }
 [CATransaction commit];
}
- (void)viewDidLayoutSubviews {
 [super viewDidLayoutSubviews];if(self.shuttingDown)return;
 DFIPerfCount(@"layout_passes");
 CGRect windowBounds=self.view.bounds;
 CGRect splitFrame=[(DFINativeWindowSurface *)self.view usableContentFrame];
 self.nativeSplitSurface.frame=splitFrame;
 CGRect bounds=self.nativeSplitSurface.bounds;
 DFIFrames f=DFIFramesMake(bounds,(int)self.layoutKind,self.fraction,self.secondary,(int)self.maximized);
 for(int i=0;i<3;i++){
  CGRect frame=f.panes[i];self.panes[i].frame=frame;self.panes[i].hidden=CGRectIsEmpty(frame);
  self.emptyButtons[i].frame=self.panes[i].bounds;
  self.panePills[i].hidden=CGRectIsEmpty(frame)||frame.size.width<74||frame.size.height<30;
  self.panePills[i].frame=CGRectMake(CGRectGetMaxX(frame)-76,CGRectGetMinY(frame)+3,74,30);
  DFINativeSlotPillView *nativePill=(DFINativeSlotPillView *)self.panePills[i];
  [nativePill setFocused:self.maximized==i];
  [nativePill setNeedsLayout];
  if(!CGRectIsEmpty(frame)&&self.hosts[i]!=NSNull.null)[self.hosts[i] resizeTo:frame.size];
 }
 for(int i=0;i<2;i++){
  BOOL hidden=i>=f.boundaryCount||CGRectIsEmpty(bounds);self.grips[i].hidden=hidden;self.lines[i].hidden=hidden;if(hidden)continue;
  CGRect r=f.boundaries[i];BOOL vertical=f.vertical[i];
  CGFloat relative=DFIClamp([self.dividerLogoPositions[i] doubleValue],.1,.9);
  if(vertical){
   self.lines[i].frame=CGRectMake(r.origin.x-8,r.origin.y,16,r.size.height);
   self.grips[i].frame=CGRectMake(r.origin.x-18,r.origin.y+relative*r.size.height-22,36,44);
  }else{
   self.lines[i].frame=CGRectMake(r.origin.x,r.origin.y-8,r.size.width,16);
   self.grips[i].frame=CGRectMake(r.origin.x+relative*r.size.width-22,r.origin.y-18,44,36);
  }
  [(DFINativeDividerTrack *)self.lines[i] positionStrokeVertically:vertical];
 }
 // Native12 uses a single header row IN the picker sheet; no root floating toolbar.
 self.pickerShade.frame=splitFrame;
 self.edge.frame=CGRectMake(CGRectGetMidX(splitFrame)-20,CGRectGetMaxY(splitFrame)-28,40,24);
 self.edge.hidden=self.panel!=nil;
 self.statusLabel.frame=CGRectMake(CGRectGetMinX(splitFrame)+8,CGRectGetMinY(splitFrame)+4,splitFrame.size.width-16,34);
 if(self.panel){
  CGRect nativeCardFrame=DFINativePickerCardFrame(splitFrame,self.list?self.list.rows.count:4);
  if(!self.list){nativeCardFrame.size.height=MIN(198,MAX(90,splitFrame.size.height-16));
      nativeCardFrame.origin.y=CGRectGetMidY(splitFrame)-nativeCardFrame.size.height/2.0;}
  self.panel.frame=nativeCardFrame;
  CGFloat w=nativeCardFrame.size.width,h=nativeCardFrame.size.height;
  // Native12 DFPickerZoomMenu owner: exactly ONE 30pt line. The original
  // 470pt sheet assigns 120pt logo, a 48pt reserved native X area, buttons
  // with widths 43/51/47/51 and distributes remaining room as equal gaps.
  // For narrower receivers, reduce the logo and glyph widths proportionally
  // rather than stacking into QA's old second header row.
  const CGFloat nativeSide=8.0, nativeMenuHeight=30.0, closeReserved=48.0;
  CGFloat logoWidth=MIN(120.0,MAX(78.0,w*.27));
  const CGFloat desiredTab[4]={43.0,51.0,47.0,51.0};
  const CGFloat desiredTotal=192.0;
  CGFloat available=w-2*nativeSide-logoWidth-closeReserved;
  CGFloat tabGap=MAX(4.0,(available-desiredTotal)/5.0);
  CGFloat tabScale=MIN(1.0,MAX(.58,(available-tabGap*5)/desiredTotal));
  CGFloat tabWidths[4]={0};CGFloat menuWidth=0;
  for(int tab=0;tab<4;tab++){
   tabWidths[tab]=floor(desiredTab[tab]*tabScale);
   menuWidth+=tabWidths[tab];
  }
  menuWidth+=3.0*tabGap;
  self.toolbar.frame=CGRectMake(nativeSide,7,w-2*nativeSide-closeReserved,nativeMenuHeight);
  self.approvedLogo.frame=CGRectMake(0,0,logoWidth,nativeMenuHeight);
  self.toolbarStack.frame=CGRectMake(logoWidth+tabGap,0,menuWidth,nativeMenuHeight);
  CGFloat tabX=0;
  for(UIView *tab in self.toolbarStack.subviews){
   if(![tab isKindOfClass:UIButton.class])continue;
   NSInteger index=((UIButton *)tab).tag;
   if(index<0 || index>=4)continue;
   tab.frame=CGRectMake(tabX,0,tabWidths[index],nativeMenuHeight);
   tabX+=tabWidths[index]+tabGap;
  }
  [self updateApprovedTabs];
  self.pickerClose.frame=CGRectMake(w-42,9,32,26);
  if(self.list){
   self.list.view.frame=CGRectMake(8,44,w-16,MAX(20,h-52));
  }else{
   NSMutableArray<UIView *> *controls=[NSMutableArray array];
   for(UIView *v in self.panel.contentView.subviews)
    if(v!=self.toolbar && v!=self.pickerClose)[controls addObject:v];
   CGFloat bw=w/4.0,bh=MAX(34,(h-46)/MAX(1,ceil((double)controls.count/4.0)));
   for(NSUInteger i=0;i<controls.count;i++)
    controls[i].frame=CGRectMake((i%4)*bw,44+(i/4)*bh,bw,bh);
  }
 }
 // Scene-hosted app views must never own the native-like divider/pill hit region.
 // Raise the actual receiver views at every layout, but leave app touch free elsewhere.
 for(int i=0;i<2;i++)if(!self.lines[i].hidden){
  [self.nativeSplitSurface bringSubviewToFront:self.lines[i]];
  [self.nativeSplitSurface bringSubviewToFront:self.grips[i]];
 }
 for(UIVisualEffectView *pill in self.panePills)if(!pill.hidden)
     [self.nativeSplitSurface bringSubviewToFront:pill];
 [self.view bringSubviewToFront:self.edge];
 // Native8 is split-only, above the app panes but below an active native picker.
 NSInteger activeCount=0;
 for(id host in self.hosts)if(host!=NSNull.null && [host scene])activeCount++;
 self.native8HUD.qaHasActiveSplit=activeCount>=2 && self.maximized<0;
 if(!self.native8HUDPositionRestored && !CGRectIsEmpty(self.view.bounds)){
  [self.native8HUD restoreSavedPosition];
  self.native8HUDPositionRestored=YES;
 }
 [self.native8HUD tick:nil];
 [self.view bringSubviewToFront:self.native8HUD];
 if(self.panel)[self.view bringSubviewToFront:self.panel];
 [self.view bringSubviewToFront:self.statusLabel];
 [self updateInteractionBorders];
}
- (void)armHide {
 [self.hideTimer invalidate];__weak typeof(self) weak=self;self.hideTimer=[NSTimer scheduledTimerWithTimeInterval:3 repeats:NO block:^(NSTimer *t){if(weak.list.scrollView.dragging||weak.list.scrollView.decelerating){[weak armHide];return;}if(!weak.panel){weak.toolbar.hidden=YES;[weak.view setNeedsLayout];}}];
}
- (void)updateApprovedTabs {
 NSArray *titles=@[@"App",@"Zoom",@"Style",@"Close"];
 NSArray *symbols=@[@"square.grid.2x2",
      DFIChromeZoomRequested()?@"arrow.down.right.and.arrow.up.left":@"arrow.up.left.and.arrow.down.right",
      @"rectangle.3.group",@"xmark.circle"];
 for(UIView *view in self.toolbarStack.subviews){
     if(![view isKindOfClass:UIButton.class])continue;
     UIButton *button=(UIButton *)view;
     NSInteger index=button.tag;
     if(index<0 || index>=4)continue;
     DFIStyleApprovedTab(button,titles[index],symbols[index],index==self.selectedTab);
 }
}
- (void)restorePane:(UIButton *)button {
 NSInteger pane=button.tag;
 if(self.shuttingDown || pane<0 || pane>=self.panes.count || self.maximized!=pane)return;
 // Native12 CBSlotPillView exposes a distinct onRestoreTapped callback.
 // Preserve split fraction/secondary from before focus; do not touch Zoom
 // chrome or recreate any app scene.
 [self dismissPanel];
 self.maximized=-1;
 [self saveLayout];
 DFIPerfMark(@"pane_restore",@{@"pane":@(pane)});
 DFILog([NSString stringWithFormat:@"Native12 source-owned slot restore pane=%ld ratio=%.3f/%.3f",
       (long)pane,self.fraction,self.secondary]);
 [self.view setNeedsLayout];
 [self.view layoutIfNeeded];
 [self armHide];
}
- (void)zoomPane:(UIButton *)button {
 NSInteger pane=button.tag;
 if(self.shuttingDown || pane<0 || pane>=self.panes.count ||
    CGRectIsEmpty(self.panes[pane].frame))return;
 [self dismissPanel];
 self.maximized=self.maximized==pane?-1:pane;
 DFIPerfMark(@"pane_focus",@{@"pane":@(pane),@"focused":@(self.maximized>=0)});
 DFILog([NSString stringWithFormat:@"QA per-slot focus pane=%ld focused=%ld",
        (long)pane,(long)self.maximized]);
 // Original CBBridgedSplitApp focuses one slot, unlike QA's external host Zoom.
 [self.view setNeedsLayout];
 [self.view layoutIfNeeded];
 [self armHide];
}
- (void)showAppMenu {
 self.selectedTab=0;[self updateApprovedTabs];
 NSInteger count=self.layoutKind==1?1:(self.layoutKind<=3?2:3);
 NSInteger pane=MAX(0,MIN(count-1,self.activePane));
 [self choose:self.paneButtons[pane]];
}
- (void)toggleZoom {
 [self dismissPanel];
 BOOL expanded=!DFHostIsExpanded();
 NSString *reason=nil;
 if(!DFHostSetExpanded(expanded,&reason)) {
  [self message:reason?:@"CarPlay host unavailable"];
  [self armHide];
  return;
 }
 // Geometry ACK is separate from native CarPlay chrome verification.
 DFIChromeSetZoom(expanded);
 self.selectedTab=1;[self updateApprovedTabs];
 [self message:expanded?@"Zoom In":@"Zoom Out"];
 [self armHide];
}
- (void)menu{if(self.panel)[self dismissPanel];else [self showAppMenu];[self armHide];[self.view setNeedsLayout];}
- (void)edgeTap{if(self.maximized>=0){self.maximized=-1;[self saveLayout];[self.view setNeedsLayout];}else [self menu];}
- (void)dismissPanel{
 if(self.list){[self.list willMoveToParentViewController:nil];[self.list.view removeFromSuperview];[self.list removeFromParentViewController];self.list=nil;}
 [self.panel removeFromSuperview];self.panel=nil;
 [self.pickerShade removeFromSuperview];self.pickerShade=nil;
 self.toolbar.hidden=YES;[self.view setNeedsLayout];
}
- (void)showRows:(NSArray *)rows pane:(NSInteger)pane pick:(void(^)(NSDictionary *))pick {
 [self dismissPanel];self.panelPane=pane;self.panel=[self glass];[self attachNativePickerHeader];DFINativePickerCardsController *list=[DFINativePickerCardsController new];list.rows=rows;list.pick=pick;list.act=pick;__weak typeof(self) weak=self;list.touch=^{[weak armHide];};self.list=list;[self addChildViewController:list];[self.panel.contentView addSubview:list.view];[list didMoveToParentViewController:self];[self armHide];[self.view setNeedsLayout];
}
- (void)choose:(UIButton *)button {
 NSInteger index=button.tag;
 if(index<0 || index>2)return;
 self.activePane=index;self.selectedTab=0;[self updateApprovedTabs];NSMutableArray *rows=[NSMutableArray array];for(NSDictionary *app in DFIAvailableApps()){BOOL duplicate=NO;for(int i=0;i<3;i++)if(i!=index&&self.hosts[i]!=NSNull.null&&[[self.hosts[i] bundleID]isEqual:app[@"id"]])duplicate=YES;if(!duplicate)[rows addObject:app];}
 if(!rows.count){[self message:DFIT(@"Chưa tìm thấy ứng dụng phù hợp",@"No eligible apps found")];return;}
 __weak typeof(self) weak=self;[self showRows:rows pane:index pick:^(NSDictionary *a){[weak dismissPanel];[weak openBundle:a[@"id"] pane:index];}];
}
- (void)message:(NSString *)text{self.statusLabel.text=text;self.statusLabel.hidden=NO;__weak typeof(self) weak=self;dispatch_after(dispatch_time(DISPATCH_TIME_NOW,4*NSEC_PER_SEC),dispatch_get_main_queue(),^{if([weak.statusLabel.text isEqual:text])weak.statusLabel.hidden=YES;});}
- (void)openBundle:(NSString *)bid pane:(NSInteger)pane {
 DFIPerfMark(@"open_app",@{@"pane":@(pane)});
 if(self.shuttingDown||pane<0||pane>2||!DFIEnabled()||[DFITerminating containsObject:bid])return;
 [self.view layoutIfNeeded];
 if(CGRectIsEmpty(self.panes[pane].bounds) || !self.view.window){
     DFILog([NSString stringWithFormat:@"QA app launch blocked before real pane geometry pane=%ld app=%@",
        (long)pane,bid]);
     [self message:@"Chưa sẵn sàng kích thước CarPlay, thử lại sau"];
     return;
 }
 if([self.pendingPanes containsObject:@(pane)]) {
     [self message:@"Đang chuyển ứng dụng, vui lòng đợi…"];
     return;
 }
 for(id h in self.hosts)if(h!=NSNull.null&&[[h bundleID]isEqual:bid])return;
 id previous=self.hosts[pane];
 if(previous!=NSNull.null){
     // Never construct the replacement SBAppViewController while the previous
     // scene still owns the pane. Finish mode=0/invalidate, yield to UIKit,
     // and re-check the owner before starting the new scene.
     NSString *old=[previous bundleID];
     [self.pendingPanes addObject:@(pane)];
     self.hosts[pane]=NSNull.null;
     DFILog([NSString stringWithFormat:@"QA replace close old=%@ next=%@ pane=%ld",
            old,bid,(long)pane]);
     [previous close];
     self.emptyButtons[pane].hidden=NO;
     self.emptyButtons[pane].enabled=NO;
     [self.emptyButtons[pane] setTitle:@"Đang thay ứng dụng…" forState:0];
     __weak typeof(self) weak=self;
     dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.3*NSEC_PER_SEC)),
        dispatch_get_main_queue(),^{
         DFV12SplitController *owner=weak;
         if(!owner || owner.shuttingDown || owner.hosts[pane]!=NSNull.null ||
            ![owner.pendingPanes containsObject:@(pane)])return;
         [owner.pendingPanes removeObject:@(pane)];
         DFILog([NSString stringWithFormat:@"QA replace start new=%@ pane=%ld",
            bid,(long)pane]);
         [owner openBundle:bid pane:pane];
         if(old.length && [DFIPref(@"closeReplaced") boolValue])
             DFITerminate(old,nil,^(NSString *status){[owner message:status];});
     });
     return;
 }
 [self.pendingPanes addObject:@(pane)];
 NSError *error=nil;
 DFILog([NSString stringWithFormat:@"QA scene host allocate bundle=%@ pane=%ld rect=%@",
    bid,(long)pane,NSStringFromCGRect(self.panes[pane].bounds)]);
 DFV12SceneHost *host=[[DFV12SceneHost alloc]initWithBundleID:bid error:&error];
 if(!host){
   [self.pendingPanes removeObject:@(pane)];
   [self message:error.localizedDescription?:@"Không mở được ứng dụng"];
   __weak typeof(self) weak=self;
   dispatch_async(dispatch_get_main_queue(),^{[weak restoreNextSavedPane];});
   return;
 }
 self.hosts[pane]=host;
 __weak typeof(self) weak=self;__weak DFV12SceneHost *wh=host;
 host.failure=^(NSString *reason){DFV12SplitController *s=weak;DFV12SceneHost *h=wh;if(!s||!h)return;NSUInteger i=[s.hosts indexOfObjectIdenticalTo:h];if(i==NSNotFound||s.shuttingDown)return;[s.pendingPanes removeObject:@(pane)];s.hosts[i]=NSNull.null;s.emptyButtons[i].enabled=YES;s.emptyButtons[i].hidden=NO;[s.emptyButtons[i] setTitle:reason forState:0];
 dispatch_async(dispatch_get_main_queue(),^{[s restoreNextSavedPane];});};
 host.ready=^{DFV12SplitController *s=weak;DFV12SceneHost *h=wh;if(!s||!h)return;NSUInteger i=[s.hosts indexOfObjectIdenticalTo:h];if(i!=NSNotFound&&!s.shuttingDown){[s.pendingPanes removeObject:@(pane)];s.emptyButtons[i].hidden=YES;s.emptyButtons[i].enabled=YES;
 dispatch_async(dispatch_get_main_queue(),^{[s restoreNextSavedPane];});}};
 [self.emptyButtons[pane]setTitle:DFIT(@"Đang mở…",@"Opening…") forState:0];self.emptyButtons[pane].hidden=NO;self.emptyButtons[pane].enabled=NO;
 @try{[host attachTo:self container:self.panes[pane]];[DFIManaged addObject:bid];DFISetObject(DFIStateMonitor,@"updateInterestedBundleIDs:",DFIManaged.allObjects);[self.panes[pane]bringSubviewToFront:self.emptyButtons[pane]];[host resizeTo:self.panes[pane].bounds.size];DFIWritePreference(@[@"left",@"right",@"third"][pane],bid);}
 @catch(NSException *e){
     [self.pendingPanes removeObject:@(pane)];
     if(self.hosts[pane]==host)self.hosts[pane]=NSNull.null;
     [host close];
     self.emptyButtons[pane].hidden=NO;
     self.emptyButtons[pane].enabled=YES;
     [self.emptyButtons[pane]setTitle:e.reason forState:0];
     return;
 }
}
- (void)saveLayout{DFIWritePreference(@"layout",@(self.layoutKind));DFIWritePreference(@"fraction",@(self.fraction));DFIWritePreference(@"secondary",@(self.secondary));}
- (void)layouts {
 self.selectedTab=2;[self updateApprovedTabs];
 [self dismissPanel];self.panelPane=-1;self.panel=[self glass];[self attachNativePickerHeader];NSArray *names=@[DFIT(@"Một khung",@"One pane"),DFIT(@"Trái / phải",@"Left / right"),DFIT(@"Trên / dưới",@"Top / bottom"),DFIT(@"Ba cột",@"Three columns"),DFIT(@"Một trái, hai phải",@"One left, two right"),DFIT(@"Hai trái, một phải",@"Two left, one right"),DFIT(@"Một trên, hai dưới",@"One top, two bottom"),DFIT(@"Hai trên, một dưới",@"Two top, one bottom")];
 for(int i=1;i<=8;i++){DFV12LayoutIcon *b=[DFV12LayoutIcon buttonWithType:UIButtonTypeCustom];b.kind=i;b.tag=i;b.accessibilityLabel=names[i-1];b.backgroundColor=i==self.layoutKind?[UIColor.whiteColor colorWithAlphaComponent:.15]:UIColor.clearColor;[b addTarget:self action:@selector(setLayout:) forControlEvents:UIControlEventTouchUpInside];[self.panel.contentView addSubview:b];}
 // Không bỏ nút hoán đổi và thoát bản cũ khi thay toolbar thành 4 mục.
 UIButton *swap=[self button:@"arrow.left.arrow.right" label:@"Swap" action:@selector(swapPanes)];
 [self.panel.contentView addSubview:swap];
 UIButton *exit=[self button:@"rectangle.portrait.and.arrow.right" label:@"Thoát DuoFace"
                        action:@selector(exitSplit)];
 [self.panel.contentView addSubview:exit];
 [self armHide];[self.view setNeedsLayout];
}
- (void)setLayout:(UIButton *)b {
 DFIPerfMark(@"layout_change",@{@"layout":@(b.tag)});
 self.layoutKind=b.tag;self.maximized=-1;self.fraction=b.tag==4?1./3:.5;self.secondary=b.tag==4?2./3:.5;NSInteger count=b.tag==1?1:(b.tag<=3?2:3);
 for(NSInteger i=count;i<3;i++){
     [self.pendingPanes removeObject:@(i)];
     id host=self.hosts[i];
     if(host!=NSNull.null){self.hosts[i]=NSNull.null;[host close];}
     self.emptyButtons[i].hidden=NO;self.emptyButtons[i].enabled=YES;
     [self.emptyButtons[i]setTitle:DFIT(@"＋ Chọn ứng dụng",@"＋ Choose app") forState:0];
     DFIWritePreference(@[@"left",@"right",@"third"][i],nil);
 }
 [self saveLayout];[self dismissPanel];[self armHide];[self.view setNeedsLayout];
}
- (void)moveDividerLogo:(UILongPressGestureRecognizer *)recognizer {
 if(self.shuttingDown || self.maximized>=0)return;
 UIGestureRecognizerState state=recognizer.state;
 if(state!=UIGestureRecognizerStateBegan &&
    state!=UIGestureRecognizerStateChanged &&
    state!=UIGestureRecognizerStateEnded)return;
 NSInteger index=recognizer.view.tag;
 DFIFrames frames=DFIFramesMake(self.nativeSplitSurface.bounds,
     (int)self.layoutKind,self.fraction,self.secondary,-1);
 if(index<0 || index>=frames.boundaryCount)return;
 CGRect boundary=frames.boundaries[index];
 BOOL vertical=frames.vertical[index];
 CGFloat length=vertical?CGRectGetHeight(boundary):CGRectGetWidth(boundary);
 if(length<=0)return;
 CGPoint point=[recognizer locationInView:self.nativeSplitSurface];
 CGFloat offset=vertical?point.y-CGRectGetMinY(boundary):
                        point.x-CGRectGetMinX(boundary);
 self.dividerLogoPositions[index]=@(DFIClamp(offset/length,.10,.90));
 if(state==UIGestureRecognizerStateEnded){
  DFIWritePreference(@"dividerLogoPositions",[self.dividerLogoPositions copy]);
  DFILog([NSString stringWithFormat:
    @"Native divider logo moved idx=%ld relative=%.3f, ratio preserved=%.3f",
     (long)index,[self.dividerLogoPositions[index] doubleValue],self.fraction]);
 }
 // Do NOT change fraction, secondary, app scene frame or invoke swap here.
 [self.view setNeedsLayout];
}
- (void)drag:(UIPanGestureRecognizer *)g {
 if(g.state==UIGestureRecognizerStateBegan) DFIPerfMark(@"drag_begin",nil);
 if(g.state==UIGestureRecognizerStateEnded || g.state==UIGestureRecognizerStateCancelled) DFIPerfMark(@"drag_end",nil);
 [self.hideTimer invalidate];if(g.state==UIGestureRecognizerStateBegan){[self dismissPanel];self.toolbar.hidden=YES;}
 DFIFrames f=DFIFramesMake(self.nativeSplitSurface.bounds,(int)self.layoutKind,self.fraction,self.secondary,-1);
 int n=(int)g.view.tag;if(n>=f.boundaryCount)return;
 CGPoint p=[g locationInView:self.nativeSplitSurface];
 BOOL vertical=f.vertical[n];CGFloat length=vertical?self.nativeSplitSurface.bounds.size.width:self.nativeSplitSurface.bounds.size.height;if(length<=0)return;double raw=DFIClamp((vertical?p.x:p.y)/length,0,1),v=raw;
 if(n==0){if(self.layoutKind==4)v=MIN(v,self.secondary);self.fraction=v;}else {if(self.layoutKind==4)v=MAX(v,self.fraction);self.secondary=v;}
 if(g.state==UIGestureRecognizerStateEnded){
  if(raw<.03||raw>.97){DFIFrames end=DFIFramesMake(self.nativeSplitSurface.bounds,(int)self.layoutKind,self.fraction,self.secondary,-1);CGRect boundary=f.boundaries[n];CGPoint probe=CGPointMake(CGRectGetMidX(boundary),CGRectGetMidY(boundary));if(vertical)probe.x=raw<.03?self.nativeSplitSurface.bounds.size.width-.1:.1;
   else probe.y=raw<.03?self.nativeSplitSurface.bounds.size.height-.1:.1;double area=-1;NSInteger candidate=-1;for(int i=0;i<end.count;i++){CGRect r=end.panes[i];double a=r.size.width*r.size.height;if(a>area){area=a;self.maximized=i;}if(!CGRectIsEmpty(r)&&CGRectContainsPoint(r,probe))candidate=i;}if(candidate>=0)self.maximized=candidate;}
  [self saveLayout];[self armHide];
 }else if(g.state==UIGestureRecognizerStateCancelled){self.fraction=self.layoutKind==4?1./3:.5;self.secondary=self.layoutKind==4?2./3:.5;[self armHide];}
 [self.view setNeedsLayout];[self.view layoutIfNeeded];
}
- (void)swapPanes {
 DFIPerfMark(@"swap",nil);
 if(self.shuttingDown||self.pendingPanes.count)return;
 NSInteger count=self.layoutKind==1?1:(self.layoutKind<=3?2:3);if(count<2)return;
 id first=self.hosts[0];for(NSInteger i=0;i<count-1;i++)self.hosts[i]=self.hosts[i+1];self.hosts[count-1]=first;
 for(int i=0;i<count;i++){id h=self.hosts[i];self.emptyButtons[i].hidden=h!=NSNull.null;self.emptyButtons[i].enabled=YES;[self.emptyButtons[i]setTitle:DFIT(@"＋ Chọn ứng dụng",@"＋ Choose app") forState:0];if(h!=NSNull.null){DFV12SceneHost *host=h;[self.panes[i]addSubview:host.controller.view];host.container=self.panes[i];[host resizeTo:self.panes[i].bounds.size];}DFIWritePreference(@[@"left",@"right",@"third"][i],h==NSNull.null?nil:[h bundleID]);}
 [self armHide];[self.view setNeedsLayout];
}
- (void)detachBundle:(NSString *)bid {
 for(int i=0;i<3;i++)if(self.hosts[i]!=NSNull.null&&[[self.hosts[i]bundleID]isEqual:bid]){
     id host=self.hosts[i];self.hosts[i]=NSNull.null;
     [self.pendingPanes removeObject:@(i)];
     [host close];
     self.emptyButtons[i].hidden=NO;self.emptyButtons[i].enabled=YES;
     [self.emptyButtons[i]setTitle:DFIT(@"＋ Chọn ứng dụng",@"＋ Choose app") forState:0];
     DFIWritePreference(@[@"left",@"right",@"third"][i],nil);
 }
}
- (void)tasks {
 self.selectedTab=3;[self updateApprovedTabs];
 NSMutableArray *rows=[NSMutableArray array];
 if(DFIManaged.count)[rows addObject:@{@"id":@"*", @"title":@"Clear All"}];
 id appController=DFIGet(NSClassFromString(@"SBApplicationController"),@"sharedInstance");
 for(NSString *bid in [DFIManaged.allObjects sortedArrayUsingSelector:@selector(compare:)]){
     id app=DFIObject(appController,@"applicationWithBundleIdentifier:",bid);
     NSString *title=DFIGet(app,@"displayName")?:bid;
     BOOL live=NO;
     for(id host in self.hosts){
         if(host!=NSNull.null && [[host bundleID] isEqual:bid] && [host scene]){
             live=YES;break;
         }
     }
     [rows addObject:@{@"id":bid,@"title":title,@"type":@"recent",
                       @"live":@(live),@"action":live?@"refresh":@"close"}];
 }
 if(!rows.count){
     [self message:DFIT(@"Không có app do DuoFace quản lý",@"No apps managed by DuoFace")];
     return;
 }
 __weak typeof(self) weak=self;
 [self showRows:rows pane:-1 pick:^(NSDictionary *row){
     [weak dismissPanel];
     NSString *bid=row[@"id"];
     if([bid isEqual:@"*"]){
         for(NSString *item in DFIManaged.allObjects){
             DFITerminate(item,^{[weak detachBundle:item];},
                 ^(NSString *status){[weak message:status];});
         }
         return;
     }
     if([row[@"action"] isEqual:@"refresh"]){
         NSInteger slot=NSNotFound;
         for(NSInteger i=0;i<3;i++){
             id host=weak.hosts[i];
             if(host!=NSNull.null && [[host bundleID] isEqual:bid]){slot=i;break;}
         }
         if(slot!=NSNotFound){
             [weak detachBundle:bid];
             // Không tạo host mới trong cùng lượt chuyển trạng thái scene cũ.
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.5*NSEC_PER_SEC)),
                 dispatch_get_main_queue(),^{if(!weak.shuttingDown)[weak openBundle:bid pane:slot];});
         }
         return;
     }
     DFITerminate(bid,^{[weak detachBundle:bid];},
         ^(NSString *status){[weak message:status];});
 }];
}
- (void)exitSplit{DFIStop();}
- (void)shutdown {
 DFIPerfMark(@"shutdown",nil);
 if(self.shuttingDown)return;
 self.shuttingDown=YES;
 [self.pendingPanes removeAllObjects];
 [self.hideTimer invalidate];
 [self.native8HUD stop];
 [self.native8HUD removeFromSuperview];self.native8HUD=nil;
 [self dismissPanel];
 // Release pane ownership before scene teardown; callbacks must not observe a live slot.
 NSArray *retiringHosts=[self.hosts copy];
 [self.hosts removeAllObjects];
 for(id host in retiringHosts)if(host!=NSNull.null)[host close];
}
@end
