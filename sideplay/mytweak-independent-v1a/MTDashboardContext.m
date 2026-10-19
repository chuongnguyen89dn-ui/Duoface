// Independent CarPlay process discovery. This file NEVER mutates Apple windows,
// scene activation, Dock visibility or the dashboard workspace.
#import "MTDashboardContext.h"
#import "MTDashboardWorkspace.h"
#import <objc/runtime.h>
#import <math.h>

static NSString *const MTContextRecord=@"/var/mobile/Library/Preferences/com.duoface.mytweak.dashboard-context.plist";
static NSString *const MTContextLog=@"/var/mobile/Library/Logs/MyTweakDashboard.log";
NSString *MTDashboardContextPath(void) { return MTContextRecord; }

static BOOL MTValidRect(CGRect r) {
    return isfinite(r.origin.x) && isfinite(r.origin.y) &&
           isfinite(r.size.width) && isfinite(r.size.height) &&
           r.size.width>0 && r.size.height>0;
}
static void MTContextLogEvent(NSString *event,NSString *detail) {
    NSString *line=[NSString stringWithFormat:@"[MyTweakDashboard] event=%@ %@\n",event,detail ?: @""];
    NSLog(@"%@",line);
    NSFileManager *fm=NSFileManager.defaultManager;
    [fm createDirectoryAtPath:[MTContextLog stringByDeletingLastPathComponent]
        withIntermediateDirectories:YES attributes:nil error:nil];
    NSFileHandle *f=[NSFileHandle fileHandleForWritingAtPath:MTContextLog];
    if (!f) {
        [fm createFileAtPath:MTContextLog contents:nil attributes:nil];
        f=[NSFileHandle fileHandleForWritingAtPath:MTContextLog];
    }
    @try {
        [f seekToEndOfFile];
        [f writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
        [f closeFile];
    } @catch (NSException *e) {
        NSLog(@"[MyTweakDashboard] log-error %@",NSStringFromClass(e.class));
    }
}
static BOOL MTIsCarPlayProcess(void) {
    NSString *p=NSProcessInfo.processInfo.processName;
    return [p isEqualToString:@"CarPlay"] || [p isEqualToString:@"CarPlayApp"];
}
static BOOL MTExcludedWindow(UIWindow *w) {
    NSString *name=NSStringFromClass(w.class);
    for (NSString *prefix in @[@"UIRemoteKeyboard", @"UITextEffects", @"UIInput",
                              @"DBDock", @"DBStatusBar", @"CARStatusBar",
                              @"UIAlert", @"MTBridge", @"UIKeyboard"]) {
        if ([name containsString:prefix]) return YES;
    }
    return NO;
}
@interface MTDashboardContext ()
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,copy) NSString *lastFingerprint;
@end
@implementation MTDashboardContext
+ (instancetype)shared {
    static MTDashboardContext *x;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ x=[MTDashboardContext new]; });
    return x;
}
+ (void)startIfCarPlayUIProcess {
    if (!MTIsCarPlayProcess())return;
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self startIfCarPlayUIProcess]; });
        return;
    }
    MTDashboardContext *ctx=[self shared];
    if (ctx.timer)return;
    MTContextLogEvent(@"observer-start",[NSString stringWithFormat:
      @"process=%@ workspaceClass=%d dashboardOwnerClass=%d",
      NSProcessInfo.processInfo.processName,
      NSClassFromString(@"DBWorkspace")!=Nil,
      NSClassFromString(@"DBDashboardWorkspaceOwner")!=Nil]);
    ctx.timer=[NSTimer scheduledTimerWithTimeInterval:1.3
                  target:ctx selector:@selector(scan:) userInfo:nil repeats:YES];
    [ctx scan:nil];
}
- (void)scan:(NSTimer *)timer {
    (void)timer;
    UIApplication *app=UIApplication.sharedApplication;
    if (!app) return;
    NSMutableOrderedSet<UIWindow *> *windows=[NSMutableOrderedSet orderedSet];
    NSUInteger sceneCount=0;
    for (UIScene *scene in app.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class])continue;
        sceneCount++;
        [windows addObjectsFromArray:((UIWindowScene *)scene).windows];
    }
    // UIWindowScene.windows is the supported iOS 16 enumeration API.
    // UIApplication.windows is deprecated and triggers Theos -Werror.
    UIWindow *best=nil;
    CGRect bestBounds=CGRectZero;
    CGFloat bestArea=0;
    for (UIWindow *w in windows) {
        UIScreen *screen=w.screen;
        if (!screen || w.hidden || w.alpha<0.01 || MTExcludedWindow(w))continue;
        CGRect sb=screen.bounds, f=w.frame;
        if (!MTValidRect(sb) || !MTValidRect(f))continue;
        CGFloat sw=sb.size.width,sh=sb.size.height;
        if (f.size.width<sw*0.60 || f.size.height<sh*0.50)continue;
        if (f.size.width>sw*1.1 || f.size.height>sh*1.1)continue;
        // Prefer full-sized native CarPlay content window, never a Dock strip.
        CGFloat area=f.size.width*f.size.height;
        if (area>bestArea) {best=w;bestBounds=sb;bestArea=area;}
    }
    NSString *status=best?@"window-found":@"no-carplay-root-window";
    if (!best) {
        NSString *finger=[NSString stringWithFormat:@"%@:%lu:%lu",status,
            (unsigned long)sceneCount,(unsigned long)windows.count];
        if (![finger isEqualToString:self.lastFingerprint]) {
            self.lastFingerprint=finger;
            MTContextLogEvent(@"scan",[NSString stringWithFormat:
              @"state=%@ scenes=%lu windows=%lu DBWorkspace=%d",
              status,(unsigned long)sceneCount,(unsigned long)windows.count,
              NSClassFromString(@"DBWorkspace")!=Nil]);
        }
        return;
    }
    UIEdgeInsets insets=best.safeAreaInsets;
    UIView *root=best.rootViewController.isViewLoaded ? best.rootViewController.view : nil;
    UIEdgeInsets rootInsets=root ? root.safeAreaInsets : UIEdgeInsetsZero;
    // Use only the actual root window's safeAreaInsets for geometry, not
    // arbitrary side padding measured from a nested card/picker.
    CGRect wf=best.frame;
    CGRect usable=UIEdgeInsetsInsetRect(wf,insets);
    CGRect whole=bestBounds;
    BOOL valid=MTValidRect(usable) && MTValidRect(whole) &&
              usable.size.width>=whole.size.width*0.50 &&
              usable.size.height>=whole.size.height*0.50 &&
              CGRectContainsRect(CGRectInset(whole,-2,-2),usable);
    BOOL nonzero=(insets.left>0.5 || insets.right>0.5 ||
                  insets.top>0.5 || insets.bottom>0.5);
    CGFloat W=whole.size.width,H=whole.size.height;
    NSString *finger=[NSString stringWithFormat:@"%@:%@:%d:%d:%.3f:%.3f:%.3f:%.3f",
                      NSStringFromClass(best.class),status,valid,nonzero,
                      insets.left,insets.right,insets.top,insets.bottom];
    if (![self.lastFingerprint isEqualToString:finger]) {
        self.lastFingerprint=finger;
        MTContextLogEvent(@"root-window",[NSString stringWithFormat:
         @"windowClass=%@ rootClass=%@ frame=%@ screen=%@ safeInsets=%@ rootInsets=%@ scenes=%lu windows=%lu usableValid=%d hasInset=%d",
         NSStringFromClass(best.class),
         best.rootViewController?NSStringFromClass(best.rootViewController.class):@"missing",
         NSStringFromCGRect(wf),NSStringFromCGRect(whole),
         NSStringFromUIEdgeInsets(insets),NSStringFromUIEdgeInsets(rootInsets),
         (unsigned long)sceneCount,(unsigned long)windows.count,valid,nonzero]);
    }
    NSMutableDictionary *record=[@{
        @"Producer":@"CarPlay",
        @"Kind":@"CarPlayRootWindowSafeArea",
        @"SourceProcess":NSProcessInfo.processInfo.processName,
        @"SourceWindowClass":NSStringFromClass(best.class),
        @"UsableValid":@(valid),
        @"HasNonzeroInsets":@(nonzero),
        @"X":@(usable.origin.x/W),@"Y":@(usable.origin.y/H),
        @"Width":@(usable.size.width/W),@"Height":@(usable.size.height/H),
        @"Timestamp":@(NSDate.date.timeIntervalSince1970),
        @"DisplayAspect":@(W/H),
        @"SceneCount":@(sceneCount),
        @"WorkspaceClassPresent":@(NSClassFromString(@"DBWorkspace")!=Nil),
        @"DashboardOwnerClassPresent":@(NSClassFromString(@"DBDashboardWorkspaceOwner")!=Nil)
    } mutableCopy];
    [record addEntriesFromDictionary:[MTDashboardWorkspace snapshot]];
    static BOOL loggedError=NO;
    if (![record writeToFile:MTContextRecord atomically:YES] && !loggedError) {
        loggedError=YES;
        MTContextLogEvent(@"context-write-failed",MTContextRecord);
    }
}
@end
