// Independent SidePlay display smoke-test tweak, rootless iOS16.
// Strictly scope to SPDash's existing CarPlay UIWindow. No CB*, license,
// app-scene replacement, split-pane edits, or modified vendor DEB.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <math.h>

@interface SPDash : NSObject
- (void)setCarWindow:(UIWindow *)window;
- (void)layoutRootView;
@end

static __weak UIWindow *DFSPWindow;
static __weak SPDash *DFSPManager;
static UIButton *DFSPZoom;
static CGFloat DFSPOriginalLevel;
static CGRect DFSPOriginalFrame;
static BOOL DFSPFull;
static const NSInteger DFSPZoomTag=870291;
static NSUInteger DFSPSequence;

static void DFSPLog(NSString *text) {
    NSLog(@"[DuoFaceSidePlayDisplayQA] %@",text);
    @try {
        NSString *dir=@"/var/mobile/Library/Logs";
        [[NSFileManager defaultManager] createDirectoryAtPath:dir
             withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *path=[dir stringByAppendingPathComponent:@"DuoFaceSidePlayDisplayQA.log"];
        NSString *line=[NSString stringWithFormat:@"%@ %@\n",[NSDate date],text];
        NSData *bytes=[line dataUsingEncoding:NSUTF8StringEncoding];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path])
            [bytes writeToFile:path atomically:YES];
        else {
            NSFileHandle *out=[NSFileHandle fileHandleForWritingAtPath:path];
            if (out) {
                [out seekToEndOfFile];
                [out writeData:bytes];
                [out closeFile];
            }
        }
    } @catch(NSException *ignored) {(void)ignored;}
}

static BOOL DFSPIsExternal(UIWindow *w) {
    UIScreen *screen=w.screen;
    return screen && screen!=UIScreen.mainScreen;
}
static CGFloat DFSPNormalWindowLevel(void) {
    // Original SidePlay sets UIWindowLevelAlert+10, above CarPlay chrome.
    // Probe with a level below statusbar but above normal app windows.
    // This is a QA hypothesis, NOT proven native chrome geometry parity.
    return UIWindowLevelStatusBar-1.0;
}
static BOOL DFSPApplyLevel(BOOL full) {
    UIWindow *w=DFSPWindow;
    if (!w || !DFSPIsExternal(w)) return NO;
    CGFloat level=full?DFSPOriginalLevel:DFSPNormalWindowLevel();
    if (!isfinite(level)) return NO;
    w.windowLevel=level;
    if (full && !CGRectIsEmpty(w.screen.bounds)) w.frame=w.screen.bounds;
    else if (!full) w.frame=DFSPOriginalFrame;
    [w setNeedsLayout];
    [w layoutIfNeeded];
    BOOL ok=fabs(w.windowLevel-level)<0.5;
    if (ok) DFSPFull=full;
    DFSPLog([NSString stringWithFormat:
        @"display applied=%d requestedFull=%d level=%.1f frame=%@ original=%.1f",
        ok,full,w.windowLevel,NSStringFromCGRect(w.frame),DFSPOriginalLevel]);
    return ok;
}
static void DFSPPlaceZoom(void) {
    UIWindow *w=DFSPWindow;
    if (!w || !DFSPZoom) return;
    CGFloat safeTop=MAX(0.0,w.safeAreaInsets.top);
    CGRect r=w.bounds;
    // Temporary independent QA control near top-right of CarPlay window.
    // Final accepted Zoom belongs in Native12 App-Zoom-Style-Close menu.
    DFSPZoom.frame=CGRectMake(MAX(10.0,CGRectGetMaxX(r)-112.0),
                             CGRectGetMinY(r)+MAX(10.0,safeTop+8.0),98.0,38.0);
    [w bringSubviewToFront:DFSPZoom];
}
@interface DFSPZoomTarget : NSObject
- (void)pressed:(id)sender;
@end
@implementation DFSPZoomTarget
- (void)pressed:(id)sender {
    (void)sender;
    BOOL requestedFull=!DFSPFull;
    if (DFSPApplyLevel(requestedFull)) {
        [DFSPZoom setTitle:DFSPFull?@"Zoom Out":@"Zoom In"
                 forState:UIControlStateNormal];
        DFSPZoom.accessibilityLabel=DFSPFull?@"Zoom Out":@"Zoom In";
        DFSPZoom.backgroundColor=[UIColor colorWithRed:0.12 green:0.14 blue:0.19
                                                 alpha:0.95];
        DFSPLog([NSString stringWithFormat:@"Zoom button tapped requestedFull=%d",requestedFull]);
    }
}
@end
static DFSPZoomTarget *DFSPAction;

static void DFSPRemove(void) {
    UIWindow *old=DFSPWindow;
    if (old) {
        old.windowLevel=DFSPOriginalLevel;
        old.frame=DFSPOriginalFrame;
    }
    [DFSPZoom removeFromSuperview];
    DFSPZoom=nil;
    DFSPWindow=nil;
    DFSPManager=nil;
    DFSPFull=NO;
    DFSPLog(@"SidePlay CarPlay window removed: original window restored");
}
static void DFSPInstall(SPDash *owner,UIWindow *win,NSUInteger generation,
                        NSInteger attempt) {
    if (generation!=DFSPSequence || !owner || !win) return;
    if (!DFSPIsExternal(win)) {
        if (attempt<12) dispatch_after(dispatch_time(DISPATCH_TIME_NOW,250000000),
            dispatch_get_main_queue(),^{DFSPInstall(owner,win,generation,attempt+1);});
        else DFSPLog(@"SidePlay window has no external UIScreen; not attaching");
        return;
    }
    if (DFSPWindow==win && DFSPZoom) {DFSPPlaceZoom();return;}
    if (DFSPWindow && DFSPWindow!=win) DFSPRemove();
    DFSPOriginalLevel=win.windowLevel;
    DFSPOriginalFrame=win.frame;
    DFSPWindow=win;
    DFSPManager=owner;
    DFSPFull=NO;
    DFSPAction=[DFSPZoomTarget new];
    UIButton *zoom=[UIButton buttonWithType:UIButtonTypeSystem];
    zoom.tag=DFSPZoomTag;
    [zoom setTitle:@"Zoom In" forState:UIControlStateNormal];
    zoom.accessibilityLabel=@"Zoom In";
    zoom.titleLabel.font=[UIFont boldSystemFontOfSize:13.0];
    [zoom setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    zoom.backgroundColor=[UIColor colorWithRed:0.12 green:0.14 blue:0.19 alpha:0.95];
    zoom.layer.cornerRadius=10.0;
    zoom.layer.borderColor=[UIColor colorWithWhite:0.78 alpha:0.55].CGColor;
    zoom.layer.borderWidth=1;
    [zoom addTarget:DFSPAction action:@selector(pressed:)
          forControlEvents:UIControlEventTouchUpInside];
    DFSPZoom=zoom;
    [win addSubview:zoom];
    DFSPPlaceZoom();
    DFSPLog([NSString stringWithFormat:
        @"SPDash CarPlay found: window=%@ screen=%@ frame=%@ level=%.1f",
        win,win.screen,NSStringFromCGRect(win.frame),win.windowLevel]);
    (void)DFSPApplyLevel(NO);
}
%hook SPDash
- (void)setCarWindow:(UIWindow *)window {
    %orig;
    NSUInteger generation=++DFSPSequence;
    if (!window) {
        if (DFSPManager==self) DFSPRemove();
        return;
    }
    __weak SPDash *owner=self;
    __weak UIWindow *target=window;
    dispatch_async(dispatch_get_main_queue(),^{
        DFSPInstall(owner,target,generation,0);
    });
}
- (void)layoutRootView {
    %orig;
    if (DFSPManager==self && DFSPWindow) {
        DFSPPlaceZoom();
    }
}
%end

static void DFSPTryInit(unsigned attempt) {
    if (objc_getClass("SPDash")) {
        %init;
        DFSPLog(@"SPDash hook installed; awaiting CarPlay window");
        return;
    }
    if (attempt<30) dispatch_after(dispatch_time(DISPATCH_TIME_NOW,1000000000),
        dispatch_get_main_queue(),^{DFSPTryInit(attempt+1);});
    else DFSPLog(@"SPDash class unavailable; addon disabled, no global hook");
}
%ctor {
    @autoreleasepool {
        if (![NSBundle.mainBundle.bundleIdentifier.lowercaseString
                isEqualToString:@"com.apple.springboard"]) return;
        dispatch_async(dispatch_get_main_queue(),^{DFSPTryInit(0);});
    }
}
