// Independent UI, loaded after DFV12SceneHost so all scene lifetime operations stay shared.
#import "DFIApprovedVisuals.h"
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
@interface DFV12List : UITableViewController
@property(nonatomic,strong) NSArray<NSDictionary *> *rows;
@property(nonatomic,copy) void(^pick)(NSDictionary *);
@property(nonatomic,copy) void(^touch)(void);
@property(nonatomic,copy) void(^act)(NSDictionary *row);
@end
@implementation DFV12List
- (void)viewDidLoad{[super viewDidLoad];self.tableView.backgroundColor=UIColor.clearColor;self.tableView.rowHeight=40;self.tableView.separatorStyle=UITableViewCellSeparatorStyleNone;}
- (NSInteger)tableView:(UITableView *)v numberOfRowsInSection:(NSInteger)s{return self.rows.count;}
- (UITableViewCell *)tableView:(UITableView *)v cellForRowAtIndexPath:(NSIndexPath *)p{
 NSDictionary *item=self.rows[p.row];
 UITableViewCell *c=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
 c.backgroundColor=UIColor.clearColor;
 c.textLabel.text=item[@"title"];
 c.textLabel.font=[UIFont systemFontOfSize:MIN(16,MAX(12,DFIFontSize()))];
 c.textLabel.textColor=UIColor.whiteColor;
 c.textLabel.adjustsFontSizeToFitWidth=YES;
 NSString *bid=item[@"id"];
 if([bid isKindOfClass:NSString.class] && bid.length && ![bid isEqual:@"*"]){
   UIImage *icon=nil;
   SEL iconSel=NSSelectorFromString(@"_applicationIconImageForBundleIdentifier:format:scale:");
   if([UIImage respondsToSelector:iconSel]){
     @try {icon=((UIImage *(*)(id,SEL,id,NSInteger,CGFloat))objc_msgSend)(
                UIImage.class,iconSel,bid,0,UIScreen.mainScreen.scale);}
     @catch(NSException *e){DFILog(e.reason);}
   }
   c.imageView.image=icon?:[UIImage systemImageNamed:@"square.grid.2x2"];
   c.imageView.tintColor=UIColor.whiteColor;
 }
 if([item[@"type"] isEqual:@"recent"]){
   BOOL live=[item[@"live"] boolValue];
   UIColor *color=live?DFIApprovedLiveGreen():DFIApprovedRed();
   UILabel *dot=[UILabel new];dot.text=@"●";dot.font=[UIFont systemFontOfSize:14];
   dot.textColor=color;dot.textAlignment=NSTextAlignmentCenter;dot.frame=CGRectMake(0,0,16,28);
   UIButton *action=[UIButton buttonWithType:UIButtonTypeSystem];
   action.tag=p.row;action.tintColor=color;action.frame=CGRectMake(0,0,35,36);
   [action setImage:[UIImage systemImageNamed:live?@"arrow.clockwise":@"xmark.circle"] forState:UIControlStateNormal];
   action.accessibilityLabel=live?@"Refresh":@"Đóng ứng dụng";
   [action addTarget:self action:@selector(recentAction:) forControlEvents:UIControlEventTouchUpInside];
   UIStackView *right=[[UIStackView alloc]initWithArrangedSubviews:@[dot,action]];
   right.axis=UILayoutConstraintAxisHorizontal;right.spacing=2;
   right.alignment=UIStackViewAlignmentCenter;right.frame=CGRectMake(0,0,53,36);
   c.accessoryView=right;
 }
 return c;
}
- (void)tableView:(UITableView *)v didSelectRowAtIndexPath:(NSIndexPath *)p{[v deselectRowAtIndexPath:p animated:YES];if(self.touch)self.touch();if(self.pick)self.pick(self.rows[p.row]);}
- (void)recentAction:(UIButton *)sender{
 if(sender.tag<0||sender.tag>=self.rows.count)return;
 if(self.touch)self.touch();
 if(self.act)self.act(self.rows[sender.tag]);
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)v{if(self.touch)self.touch();}
@end
@interface DFV12LayoutIcon : UIButton
@property(nonatomic) int kind;
@end
@implementation DFV12LayoutIcon
- (void)drawRect:(CGRect)rect{[super drawRect:rect];DFIFrames f=DFIFramesMake(CGRectInset(self.bounds,9,8),self.kind,self.kind==4?1./3:.5,self.kind==4?2./3:.5,-1);[[UIColor.whiteColor colorWithAlphaComponent:.85]setStroke];for(int i=0;i<f.count;i++){UIBezierPath *p=[UIBezierPath bezierPathWithRoundedRect:CGRectInset(f.panes[i],1.5,1.5) cornerRadius:2];p.lineWidth=1.2;[p stroke];}}
@end
@interface DFV12SplitController ()
@property(nonatomic,strong) NSArray<UIView *> *panes;
@property(nonatomic,strong) NSMutableArray *hosts;
@property(nonatomic,strong) NSArray<UIButton *> *emptyButtons;
@property(nonatomic,strong) NSArray<UIButton *> *paneButtons;
@property(nonatomic,strong) NSArray<UIButton *> *grips;
@property(nonatomic,strong) NSArray<UIView *> *lines;
@property(nonatomic,strong) UIButton *edge;
@property(nonatomic,strong) UIVisualEffectView *toolbar;
@property(nonatomic,strong) UIView *toolbarStack;
@property(nonatomic,strong) UIVisualEffectView *panel;
@property(nonatomic,strong) UIControl *pickerShade;
@property(nonatomic,strong) UIButton *pickerClose;
@property(nonatomic) BOOL interactionActive;
@property(nonatomic,strong) DFV12List *list;
@property(nonatomic,strong) NSTimer *hideTimer;
@property(nonatomic) NSInteger layoutKind,maximized,panelPane;
@property(nonatomic) CGFloat fraction,secondary;
@property(nonatomic) BOOL shuttingDown;
@property(nonatomic,strong) UILabel *statusLabel;
@property(nonatomic,strong) UIImageView *approvedLogo;
@property(nonatomic) NSInteger activePane,selectedTab;
@property(nonatomic,strong) NSMutableSet<NSNumber *> *pendingPanes;
@end
@implementation DFV12SplitController
- (UIInterfaceOrientationMask)supportedInterfaceOrientations{return UIInterfaceOrientationMaskAll;}
- (BOOL)prefersStatusBarHidden{return YES;}
- (UIButton *)button:(NSString *)symbol label:(NSString *)label action:(SEL)action {
 UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];[b setImage:[UIImage systemImageNamed:symbol] forState:UIControlStateNormal];b.tintColor=UIColor.whiteColor;b.accessibilityLabel=label;[b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];return b;
}
- (UIVisualEffectView *)glass {
 UIVisualEffectView *v=[[UIVisualEffectView alloc]initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];v.layer.cornerRadius=12;v.clipsToBounds=YES;v.layer.borderWidth=0;v.layer.borderColor=UIColor.clearColor.CGColor;[self.view addSubview:v];return v;
}
- (void)viewDidLoad {
 [super viewDidLoad];self.view.backgroundColor=UIColor.blackColor;self.overrideUserInterfaceStyle=UIUserInterfaceStyleDark;
 self.layoutKind=DFIPref(@"layout")?[DFIPref(@"layout") integerValue]:2;if(self.layoutKind<1||self.layoutKind>8)self.layoutKind=2;
 self.fraction=DFIPref(@"fraction")?DFIClamp([DFIPref(@"fraction") doubleValue],.02,.98):(self.layoutKind==4?1./3:.5);
 self.secondary=DFIPref(@"secondary")?DFIClamp([DFIPref(@"secondary") doubleValue],.02,.98):(self.layoutKind==4?2./3:.5);self.maximized=-1;self.activePane=0;self.selectedTab=0;self.interactionActive=NO;self.pendingPanes=[NSMutableSet set];
 self.hosts=[NSMutableArray arrayWithObjects:NSNull.null,NSNull.null,NSNull.null,nil];NSMutableArray *panes=[NSMutableArray array],*empty=[NSMutableArray array],*buttons=[NSMutableArray array],*grips=[NSMutableArray array],*lines=[NSMutableArray array];
 for(int i=0;i<3;i++){
  UIView *p=[UIView new];p.backgroundColor=UIColor.blackColor;p.clipsToBounds=YES;[self.view addSubview:p];[panes addObject:p];
  UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];[b setTitle:DFIT(@"＋ Chọn ứng dụng",@"＋ Choose app") forState:0];b.tintColor=UIColor.whiteColor;b.titleLabel.font=[UIFont systemFontOfSize:DFIFontSize()];b.titleLabel.numberOfLines=0;b.titleLabel.textAlignment=NSTextAlignmentCenter;b.tag=i;[b addTarget:self action:@selector(choose:) forControlEvents:UIControlEventTouchUpInside];[p addSubview:b];[empty addObject:b];
  UIButton *corner=[self button:@"ellipsis" label:DFIT(@"Chọn app trong khung",@"Choose pane app") action:@selector(choose:)];corner.tag=i;corner.backgroundColor=[UIColor.blackColor colorWithAlphaComponent:.18];corner.layer.cornerRadius=12;[self.view addSubview:corner];[buttons addObject:corner];
 }
 self.panes=panes;self.emptyButtons=empty;self.paneButtons=buttons;
 for(int i=0;i<2;i++){
  UIView *line=[UIView new];line.backgroundColor=[UIColor.whiteColor colorWithAlphaComponent:.18];line.userInteractionEnabled=NO;[self.view addSubview:line];[lines addObject:line];
  UIButton *g=[UIButton buttonWithType:UIButtonTypeCustom];g.tag=i;g.accessibilityLabel=DFIT(@"Kéo đổi tỷ lệ; chạm mở thanh công cụ",@"Drag to resize; tap for toolbar");[g addTarget:self action:@selector(menu) forControlEvents:UIControlEventTouchUpInside];[g addGestureRecognizer:[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(drag:)]];UIView *mark=[UIView new];mark.tag=77;mark.userInteractionEnabled=NO;mark.backgroundColor=[UIColor.whiteColor colorWithAlphaComponent:.9];mark.layer.cornerRadius=1.5;[g addSubview:mark];[self.view addSubview:g];[grips addObject:g];
 }
 self.grips=grips;self.lines=lines;
 self.edge=[self button:@"ellipsis" label:DFIT(@"Mở thanh công cụ",@"Show toolbar") action:@selector(edgeTap)];self.edge.layer.cornerRadius=12;self.edge.backgroundColor=[UIColor.blackColor colorWithAlphaComponent:.18];[self.view addSubview:self.edge];
 // Toolbar chỉ là PHẦN ĐẦU picker, không được gắn trực tiếp trên màn chia ô.
 self.toolbar=[[UIVisualEffectView alloc]initWithEffect:nil];self.toolbar.backgroundColor=UIColor.clearColor;
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
 self.statusLabel=[UILabel new];self.statusLabel.textColor=UIColor.whiteColor;self.statusLabel.backgroundColor=[UIColor.blackColor colorWithAlphaComponent:.5];self.statusLabel.font=[UIFont systemFontOfSize:12];self.statusLabel.textAlignment=NSTextAlignmentCenter;self.statusLabel.numberOfLines=2;self.statusLabel.hidden=YES;[self.view addSubview:self.statusLabel];
 NSInteger count=self.layoutKind==1?1:(self.layoutKind<=3?2:3);
 for(NSInteger i=0;i<count;i++){NSString *bid=DFIPref(@[@"left",@"right",@"third"][i]);if([bid isKindOfClass:NSString.class]&&bid.length)[self openBundle:bid pane:i];}
}
- (void)updateInteractionBorders {
 // Bản duyệt: đỏ #E3020F, rộng 1pt, không nhấp nháy, ẩn khi tập trung một ô
 // hoặc thanh điều khiển về trạng thái nghỉ.
 [CATransaction begin];[CATransaction setDisableActions:YES];
 for(int i=0;i<3;i++){
     BOOL active=self.hosts[i]!=NSNull.null &&
         !self.toolbar.hidden && self.maximized<0 &&
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
 CGRect bounds=self.view.bounds;DFIFrames f=DFIFramesMake(bounds,(int)self.layoutKind,self.fraction,self.secondary,(int)self.maximized);
 for(int i=0;i<3;i++){
  CGRect frame=f.panes[i];self.panes[i].frame=frame;self.panes[i].hidden=CGRectIsEmpty(frame);
  self.emptyButtons[i].frame=self.panes[i].bounds;self.paneButtons[i].hidden=CGRectIsEmpty(frame)||frame.size.width<40||frame.size.height<35;
  self.paneButtons[i].frame=CGRectMake(CGRectGetMaxX(frame)-34,CGRectGetMinY(frame)+2,32,26);
  if(!CGRectIsEmpty(frame)&&self.hosts[i]!=NSNull.null)[self.hosts[i] resizeTo:frame.size];
 }
 for(int i=0;i<2;i++){
  BOOL hidden=i>=f.boundaryCount||CGRectIsEmpty(bounds);self.grips[i].hidden=hidden;self.lines[i].hidden=hidden;if(hidden)continue;
  CGRect r=f.boundaries[i];BOOL vertical=f.vertical[i];
  if(vertical){self.lines[i].frame=CGRectMake(r.origin.x-.5,r.origin.y,1,r.size.height);self.grips[i].frame=CGRectMake(r.origin.x-18,CGRectGetMidY(r)-22,36,44);}
  else {self.lines[i].frame=CGRectMake(r.origin.x,r.origin.y-.5,r.size.width,1);self.grips[i].frame=CGRectMake(CGRectGetMidX(r)-22,r.origin.y-18,44,36);}
  [self.grips[i] viewWithTag:77].frame=vertical?CGRectMake(16.5,8,3,28):CGRectMake(8,16.5,28,3);
 }
 CGFloat width=MIN(390,MAX(240,bounds.size.width-16));
 self.toolbar.frame=CGRectMake((bounds.size.width-width)/2,bounds.size.height-44,width,36);
 CGFloat logoWidth=MIN(120,MAX(56,width*0.30));
 self.approvedLogo.frame=CGRectMake(6,3,logoWidth-4,30);
 self.toolbarStack.frame=CGRectMake(logoWidth+8,0,MAX(80,width-logoWidth-12),36);
 self.edge.frame=CGRectMake(CGRectGetMidX(bounds)-20,bounds.size.height-26,40,24);self.edge.hidden=!self.toolbar.hidden;
 self.statusLabel.frame=CGRectMake(8,4,bounds.size.width-16,34);
 if(self.panel){CGFloat desired=self.list?MIN(140,MAX(40,self.list.rows.count*40)):(self.panel.contentView.subviews.count>8?132:88);CGFloat w=MIN(220,bounds.size.width-16),h=MIN(desired,bounds.size.height-54);CGFloat x=(bounds.size.width-w)/2,y=bounds.size.height-h-46;
  if(self.panelPane>=0){CGRect p=self.panes[self.panelPane].frame;w=MIN(w,MAX(40,p.size.width-8));h=MIN(h,MAX(40,p.size.height-34));x=CGRectGetMaxX(p)-w-4;y=p.origin.y+30;}
  self.panel.frame=CGRectMake(x,MAX(0,y),w,h);if(self.list)self.list.view.frame=self.panel.contentView.bounds;
  else {NSArray *buttons=self.panel.contentView.subviews;CGFloat bw=w/4,bh=h/MAX(1,ceil((double)buttons.count/4.0));for(NSUInteger i=0;i<buttons.count;i++)[buttons[i] setFrame:CGRectMake((i%4)*bw,(i/4)*bh,bw,bh)];}
 }
 [self updateInteractionBorders];
}
- (void)armHide {
 [self.hideTimer invalidate];__weak typeof(self) weak=self;self.hideTimer=[NSTimer scheduledTimerWithTimeInterval:3 repeats:NO block:^(NSTimer *t){if(weak.list.tableView.dragging||weak.list.tableView.decelerating){[weak armHide];return;}[weak dismissPanel];weak.toolbar.hidden=YES;[weak.view setNeedsLayout];}];
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
- (void)menu{[self dismissPanel];self.toolbar.hidden=!self.toolbar.hidden;[self armHide];[self.view setNeedsLayout];}
- (void)edgeTap{if(self.maximized>=0){self.maximized=-1;self.fraction=self.layoutKind==4?1./3:.5;self.secondary=self.layoutKind==4?2./3:.5;[self saveLayout];[self.view setNeedsLayout];}else [self menu];}
- (void)dismissPanel{[self.list willMoveToParentViewController:nil];[self.list.view removeFromSuperview];[self.list removeFromParentViewController];self.list=nil;[self.panel removeFromSuperview];self.panel=nil;}
- (void)showRows:(NSArray *)rows pane:(NSInteger)pane pick:(void(^)(NSDictionary *))pick {
 [self dismissPanel];self.panelPane=pane;self.panel=[self glass];DFV12List *list=[DFV12List new];list.rows=rows;list.pick=pick;list.act=pick;__weak typeof(self) weak=self;list.touch=^{[weak armHide];};self.list=list;[self addChildViewController:list];[self.panel.contentView addSubview:list.view];[list didMoveToParentViewController:self];[self armHide];[self.view setNeedsLayout];
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
 if([self.pendingPanes containsObject:@(pane)]) {
     [self message:@"Đang chuyển ứng dụng, vui lòng đợi…"];
     return;
 }
 for(id h in self.hosts)if(h!=NSNull.null&&[[h bundleID]isEqual:bid])return;
 [self.pendingPanes addObject:@(pane)];
 NSError *error=nil;DFV12SceneHost *host=[[DFV12SceneHost alloc]initWithBundleID:bid error:&error];if(!host){[self.pendingPanes removeObject:@(pane)];[self message:error.localizedDescription?:@"Không mở được ứng dụng"];return;}
 id previous=self.hosts[pane];NSString *old=previous==NSNull.null?nil:[previous bundleID];if(previous!=NSNull.null)[previous close];self.hosts[pane]=host;
 __weak typeof(self) weak=self;__weak DFV12SceneHost *wh=host;
 host.failure=^(NSString *reason){DFV12SplitController *s=weak;DFV12SceneHost *h=wh;if(!s||!h)return;NSUInteger i=[s.hosts indexOfObjectIdenticalTo:h];if(i==NSNotFound||s.shuttingDown)return;[s.pendingPanes removeObject:@(pane)];s.hosts[i]=NSNull.null;s.emptyButtons[i].enabled=YES;s.emptyButtons[i].hidden=NO;[s.emptyButtons[i] setTitle:reason forState:0];};
 host.ready=^{DFV12SplitController *s=weak;DFV12SceneHost *h=wh;if(!s||!h)return;NSUInteger i=[s.hosts indexOfObjectIdenticalTo:h];if(i!=NSNotFound&&!s.shuttingDown){[s.pendingPanes removeObject:@(pane)];s.emptyButtons[i].hidden=YES;s.emptyButtons[i].enabled=YES;}};
 [self.emptyButtons[pane]setTitle:DFIT(@"Đang mở…",@"Opening…") forState:0];self.emptyButtons[pane].hidden=NO;self.emptyButtons[pane].enabled=NO;
 @try{[host attachTo:self container:self.panes[pane]];[DFIManaged addObject:bid];DFISetObject(DFIStateMonitor,@"updateInterestedBundleIDs:",DFIManaged.allObjects);[self.panes[pane]bringSubviewToFront:self.emptyButtons[pane]];[host resizeTo:self.panes[pane].bounds.size];DFIWritePreference(@[@"left",@"right",@"third"][pane],bid);}
 @catch(NSException *e){[self.pendingPanes removeObject:@(pane)];[host close];self.hosts[pane]=NSNull.null;self.emptyButtons[pane].enabled=YES;[self.emptyButtons[pane]setTitle:e.reason forState:0];}
 if(old&&[DFIPref(@"closeReplaced")boolValue])DFITerminate(old,nil,^(NSString *status){[weak message:status];});
}
- (void)saveLayout{DFIWritePreference(@"layout",@(self.layoutKind));DFIWritePreference(@"fraction",@(self.fraction));DFIWritePreference(@"secondary",@(self.secondary));}
- (void)layouts {
 self.selectedTab=2;[self updateApprovedTabs];
 [self dismissPanel];self.panelPane=-1;self.panel=[self glass];NSArray *names=@[DFIT(@"Một khung",@"One pane"),DFIT(@"Trái / phải",@"Left / right"),DFIT(@"Trên / dưới",@"Top / bottom"),DFIT(@"Ba cột",@"Three columns"),DFIT(@"Một trái, hai phải",@"One left, two right"),DFIT(@"Hai trái, một phải",@"Two left, one right"),DFIT(@"Một trên, hai dưới",@"One top, two bottom"),DFIT(@"Hai trên, một dưới",@"Two top, one bottom")];
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
 for(NSInteger i=count;i<3;i++)if(self.hosts[i]!=NSNull.null){[self.hosts[i]close];self.hosts[i]=NSNull.null;self.emptyButtons[i].hidden=NO;self.emptyButtons[i].enabled=YES;[self.emptyButtons[i]setTitle:DFIT(@"＋ Chọn ứng dụng",@"＋ Choose app") forState:0];}
 [self saveLayout];[self dismissPanel];[self armHide];[self.view setNeedsLayout];
}
- (void)drag:(UIPanGestureRecognizer *)g {
 if(g.state==UIGestureRecognizerStateBegan) DFIPerfMark(@"drag_begin",nil);
 if(g.state==UIGestureRecognizerStateEnded || g.state==UIGestureRecognizerStateCancelled) DFIPerfMark(@"drag_end",nil);
 [self.hideTimer invalidate];if(g.state==UIGestureRecognizerStateBegan){[self dismissPanel];self.toolbar.hidden=YES;}
 DFIFrames f=DFIFramesMake(self.view.bounds,(int)self.layoutKind,self.fraction,self.secondary,-1);int n=(int)g.view.tag;if(n>=f.boundaryCount)return;CGPoint p=[g locationInView:self.view];BOOL vertical=f.vertical[n];CGFloat length=vertical?self.view.bounds.size.width:self.view.bounds.size.height;if(length<=0)return;double raw=DFIClamp((vertical?p.x:p.y)/length,0,1),v=raw;
 if(n==0){if(self.layoutKind==4)v=MIN(v,self.secondary);self.fraction=v;}else {if(self.layoutKind==4)v=MAX(v,self.fraction);self.secondary=v;}
 if(g.state==UIGestureRecognizerStateEnded){
  if(raw<.03||raw>.97){DFIFrames end=DFIFramesMake(self.view.bounds,(int)self.layoutKind,self.fraction,self.secondary,-1);CGRect boundary=f.boundaries[n];CGPoint probe=CGPointMake(CGRectGetMidX(boundary),CGRectGetMidY(boundary));if(vertical)probe.x=raw<.03?self.view.bounds.size.width-.1:.1;else probe.y=raw<.03?self.view.bounds.size.height-.1:.1;double area=-1;NSInteger candidate=-1;for(int i=0;i<end.count;i++){CGRect r=end.panes[i];double a=r.size.width*r.size.height;if(a>area){area=a;self.maximized=i;}if(!CGRectIsEmpty(r)&&CGRectContainsPoint(r,probe))candidate=i;}if(candidate>=0)self.maximized=candidate;}
  [self saveLayout];[self armHide];
 }else if(g.state==UIGestureRecognizerStateCancelled){self.fraction=self.layoutKind==4?1./3:.5;self.secondary=self.layoutKind==4?2./3:.5;[self armHide];}
 [self.view setNeedsLayout];[self.view layoutIfNeeded];
}
- (void)swapPanes {
 DFIPerfMark(@"swap",nil);
 if(self.shuttingDown||self.pendingPanes.count)return;
 NSInteger count=self.layoutKind==1?1:(self.layoutKind<=3?2:3);if(count<2)return;
 id first=self.hosts[0];for(NSInteger i=0;i<count-1;i++)self.hosts[i]=self.hosts[i+1];self.hosts[count-1]=first;
 for(int i=0;i<count;i++){id h=self.hosts[i];self.emptyButtons[i].hidden=h!=NSNull.null;self.emptyButtons[i].enabled=YES;[self.emptyButtons[i]setTitle:DFIT(@"＋ Chọn ứng dụng",@"＋ Choose app") forState:0];if(h!=NSNull.null){DFV12SceneHost *host=h;[self.panes[i]addSubview:host.controller.view];host.container=self.panes[i];}DFIWritePreference(@[@"left",@"right",@"third"][i],h==NSNull.null?nil:[h bundleID]);}
 [self armHide];[self.view setNeedsLayout];
}
- (void)detachBundle:(NSString *)bid {
 for(int i=0;i<3;i++)if(self.hosts[i]!=NSNull.null&&[[self.hosts[i]bundleID]isEqual:bid]){[self.hosts[i]close];self.hosts[i]=NSNull.null;self.emptyButtons[i].hidden=NO;self.emptyButtons[i].enabled=YES;[self.emptyButtons[i]setTitle:DFIT(@"＋ Chọn ứng dụng",@"＋ Choose app") forState:0];DFIWritePreference(@[@"left",@"right",@"third"][i],nil);}
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
 if(self.shuttingDown)return;self.shuttingDown=YES;[self.pendingPanes removeAllObjects];[self.hideTimer invalidate];[self dismissPanel];for(id host in self.hosts)if(host!=NSNull.null)[host close];[self.hosts removeAllObjects];
}
@end
