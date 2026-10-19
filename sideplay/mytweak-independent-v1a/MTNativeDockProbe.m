// Independent CarPlay-process observer of the REAL system-owned DBDockWindow.
// No hard-coded dock pixels/icons, no private setter, no window changes.
#import "MTNativeDockProbe.h"
#import <objc/runtime.h>
#import <math.h>

static NSString *const kDockRecord=@"/var/mobile/Library/Preferences/com.duoface.mytweak.native-dock.plist";
static NSString *const kDockLog=@"/var/mobile/Library/Logs/MyTweakDock.log";
static void (*MTOriginalDockLayout)(id,SEL)=NULL;

static void MTLogDock(NSString *name,NSString *message) {
    NSString *s=[NSString stringWithFormat:@"[MyTweakDock] event=%@ %@",name,message ?: @""];
    NSLog(@"%@",s);
    [[NSFileManager defaultManager] createDirectoryAtPath:[kDockLog stringByDeletingLastPathComponent]
                        withIntermediateDirectories:YES attributes:nil error:nil];
    NSFileHandle *f=[NSFileHandle fileHandleForWritingAtPath:kDockLog];
    if (!f) {
        [[NSFileManager defaultManager] createFileAtPath:kDockLog contents:nil attributes:nil];
        f=[NSFileHandle fileHandleForWritingAtPath:kDockLog];
    }
    @try {
        [f seekToEndOfFile];
        [f writeData:[[s stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [f closeFile];
    } @catch(NSException *e) {
        NSLog(@"[MyTweakDock] logging error class=%@",NSStringFromClass([e class]));
    }
}
static NSString *MTDockEdge(CGRect rect,CGSize area) {
    if (area.width<240 || area.height<100 || CGRectIsEmpty(rect) ||
        !isfinite(rect.origin.x) || !isfinite(rect.origin.y) ||
        !isfinite(rect.size.width) || !isfinite(rect.size.height)) return nil;
    CGFloat x=CGRectGetMinX(rect),y=CGRectGetMinY(rect);
    CGFloat w=CGRectGetWidth(rect),h=CGRectGetHeight(rect);
    CGFloat W=area.width,H=area.height;
    const CGFloat tolerance=MAX(5.0,MIN(W,H)*0.025);
    if (x<-tolerance || y<-tolerance || CGRectGetMaxX(rect)>W+tolerance ||
        CGRectGetMaxY(rect)>H+tolerance) return nil;
    if (w>=16 && w< W*0.27 && h>H*0.50) {
        if (x<=tolerance) return @"left";
        if (CGRectGetMaxX(rect)>=W-tolerance) return @"right";
    }
    if (h>=16 && h< H*0.27 && w>W*0.50) {
        if (y<=tolerance) return @"top";
        if (CGRectGetMaxY(rect)>=H-tolerance) return @"bottom";
    }
    return nil; // IMPORTANT: no guessed/fake Dock geometry.
}
static BOOL MTIsDockClassName(NSString *name) {
    return [name containsString:@"Dock"] || [name containsString:@"dock"];
}
@interface MTNativeDockProbe()
@property(nonatomic,strong,nullable) NSTimer *timer;
@property(nonatomic,copy) NSString *lastDescription;
@property(nonatomic,assign) BOOL hooked;
@end
@implementation MTNativeDockProbe
+ (instancetype)shared {
    static MTNativeDockProbe *one;static dispatch_once_t once;
    dispatch_once(&once, ^{one=[MTNativeDockProbe new];});
    return one;
}
+ (void)startForCarPlayProcess {
    if (![NSProcessInfo.processInfo.processName isEqualToString:@"CarPlay"])return;
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(),^{[self startForCarPlayProcess];});
        return;
    }
    MTNativeDockProbe *p=[self shared];
    if (p.timer) return;
    MTLogDock(@"start",@"process=CarPlay mode=read-only native-dock-window-observer");
    p.timer=[NSTimer scheduledTimerWithTimeInterval:1.1
                  target:p selector:@selector(scan:) userInfo:nil repeats:YES];
    [p scan:nil];
}
- (void)captureWindow:(UIWindow *)dockWindow reason:(NSString *)reason {
    if (![dockWindow isKindOfClass:UIWindow.class])return;
    UIScreen *screen=dockWindow.screen;
    if (!screen || dockWindow.hidden || dockWindow.alpha<0.01) return;
    CGSize display=screen.bounds.size;
    CGRect region=dockWindow.frame;
    NSString *edge=MTDockEdge(region,display);
    NSString *source=NSStringFromClass(dockWindow.class);
    if (!edge) {
        // DBDockWindow itself might span the entire display; only accept a
        // NATIVE Dock-named descendant if the actual geometry hugs one edge.
        NSMutableArray<UIView *> *stack=[NSMutableArray arrayWithArray:dockWindow.subviews];
        NSUInteger visited=0;
        while (stack.count && ++visited<=220) {
            UIView *view=stack.lastObject;[stack removeLastObject];
            if (view.hidden || view.alpha<0.01) continue;
            NSString *name=NSStringFromClass(view.class);
            if (MTIsDockClassName(name)) {
                CGRect local=[view convertRect:view.bounds toView:dockWindow];
                CGRect inScreen=CGRectOffset(local,dockWindow.frame.origin.x,
                                            dockWindow.frame.origin.y);
                NSString *candidate=MTDockEdge(inScreen,display);
                if (candidate) {
                    region=inScreen; edge=candidate;
                    source=name;break;
                }
            }
            [stack addObjectsFromArray:view.subviews];
        }
    }
    if (!edge)return;
    CGFloat width=region.size.width/display.width;
    CGFloat height=region.size.height/display.height;
    CGFloat px=region.origin.x/display.width;
    CGFloat py=region.origin.y/display.height;
    NSString *state=[NSString stringWithFormat:@"edge=%@ x=%.4f y=%.4f w=%.4f h=%.4f",
                      edge,px,py,width,height];
    if (![self.lastDescription isEqualToString:state]) {
        MTLogDock(@"native-window",[NSString stringWithFormat:
          @"source=%@ reason=%@ %@ dockLevel=%.2f display=%@",
          source,reason,state,dockWindow.windowLevel,NSStringFromCGSize(display)]);
        self.lastDescription=state;
    }
    // Record actual CarPlay-owned Dock window. No icon names, coordinates of
    // user apps, CarPlay preferences or sensitive data are included.
    NSDictionary *info=@{
        @"Producer":@"CarPlay",
        @"Kind":@"real-DBDockWindow",
        @"Edge":edge,@"X":@(px),@"Y":@(py),
        @"Width":@(width),@"Height":@(height),
        @"Timestamp":@([NSDate.date timeIntervalSince1970]),
        @"DisplayAspect":@(display.width/display.height),
        @"Class":source,
        @"Visible":@YES
    };
    if (![info writeToFile:kDockRecord atomically:YES]) {
        static BOOL warned=NO;
        if (!warned) { warned=YES; MTLogDock(@"write-failed",kDockRecord); }
    }
}
- (void)hookDockWindowIfPossible {
    if (self.hooked) return;
    Class cls=NSClassFromString(@"DBDockWindow");
    if (!cls || ![cls isSubclassOfClass:UIWindow.class])return;
    SEL sel=@selector(layoutSubviews);
    Method m=class_getInstanceMethod(cls,sel);
    if (!m || method_getNumberOfArguments(m)!=2) return;
    char type[8]={0};method_getReturnType(m,type,sizeof(type));
    if (type[0]!='v')return;
    IMP orig=method_getImplementation(m);
    MTOriginalDockLayout=(void (*)(id,SEL))orig;
    // Add override only to this class if inherited; never modify UIWindow.
    extern void MTNativeDockLayout(id,SEL);
    if (!class_addMethod(cls,sel,(IMP)MTNativeDockLayout,method_getTypeEncoding(m))) {
        Method own=class_getInstanceMethod(cls,sel);
        MTOriginalDockLayout=(void (*)(id,SEL))method_setImplementation(own,(IMP)MTNativeDockLayout);
    }
    self.hooked=YES;
    MTLogDock(@"hook-installed",@"class=DBDockWindow selector=layoutSubviews read-only-after-original");
}
- (void)scan:(NSTimer *)timer {
    (void)timer;
    [self hookDockWindowIfPossible];
    Class cls=NSClassFromString(@"DBDockWindow");
    if (!cls) { if (!self.lastDescription)self.lastDescription=@"missing-class";return; }
    UIApplication *app=UIApplication.sharedApplication;
    NSMutableOrderedSet<UIWindow *> *windows=[NSMutableOrderedSet orderedSet];
    for (UIScene *scene in app.connectedScenes) {
        if ([scene isKindOfClass:UIWindowScene.class])
            [windows addObjectsFromArray:((UIWindowScene *)scene).windows];
    }
    for (UIWindow *window in windows) {
        if ([window isKindOfClass:cls])
            [self captureWindow:window reason:@"scene-window-scan"];
    }
}
@end
// Runtime hook is restricted to the actual CarPlay DBDockWindow class.
// Original Apple layout is called BEFORE our geometry read, unmodified.
void MTNativeDockLayout(id window,SEL cmd) {
    if (MTOriginalDockLayout)MTOriginalDockLayout(window,cmd);
    if ([window isKindOfClass:UIWindow.class])
        [[MTNativeDockProbe shared] captureWindow:(UIWindow *)window reason:@"native-layout"];
}
