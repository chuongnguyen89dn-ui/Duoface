// Independent SidePlay native-display QA2: control old fullscreen geometry.
// SidePlay remains the CarPlay app host. Only SPDash exterior geometry and
// its internal dock-mode branch are overridden in NORMAL, never app split.
// Reversible: no changes to SidePlay.dylib, Native12 HUD8 or on-disk prefs.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <math.h>

@interface SPDash : NSObject
- (void)setCarWindow:(UIWindow *)window;
- (void)setCarWindowFrame:(CGRect)frame;
- (CGRect)carWindowFrameNow;
- (BOOL)carDockMode;
- (void)layoutRootView;
@end

static __weak UIWindow *DFSPWindow;
static __weak SPDash *DFSPManager;
static UIButton *DFSPZoom;
static id DFSPAction;
static CGFloat DFSPOriginalLevel;
static CGRect DFSPOriginalFrame;
static BOOL DFSPFull = NO;
static BOOL DFSPApplying = NO;
static NSUInteger DFSPSequence = 0;
static NSUInteger DFSPLayoutCalls = 0;
static const CGFloat DFSPNativeFallbackLeft = 64.0;
static const NSInteger DFSPZoomTag = 870291;

static void DFSPLog(NSString *message) {
    NSLog(@"[DuoFaceSidePlayDisplayQA2] %@", message);
    @try {
        NSString *directory = @"/var/mobile/Library/Logs";
        [[NSFileManager defaultManager] createDirectoryAtPath:directory
                    withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *path = [directory stringByAppendingPathComponent:@"DuoFaceSidePlayDisplayQA.log"];
        NSString *line = [NSString stringWithFormat:@"%@ QA2 %@\n", [NSDate date], message];
        NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [data writeToFile:path atomically:YES];
        } else {
            NSFileHandle *output = [NSFileHandle fileHandleForWritingAtPath:path];
            if (output) {
                [output seekToEndOfFile];
                [output writeData:data];
                [output closeFile];
            }
        }
    } @catch (NSException *ignored) { (void)ignored; }
}

static BOOL DFSPRectOK(CGRect rect) {
    return isfinite(rect.origin.x) && isfinite(rect.origin.y) &&
           isfinite(rect.size.width) && isfinite(rect.size.height) &&
           rect.size.width > 100.0 && rect.size.height > 100.0;
}
static BOOL DFSPNear(CGRect a, CGRect b) {
    return fabs(a.origin.x-b.origin.x)<1.0 &&
           fabs(a.origin.y-b.origin.y)<1.0 &&
           fabs(a.size.width-b.size.width)<1.0 &&
           fabs(a.size.height-b.size.height)<1.0;
}
static BOOL DFSPExternal(UIWindow *window) {
    UIScreen *screen = window.screen;
    return screen && screen != UIScreen.mainScreen;
}
static CGRect DFSPSystemUsableRect(UIWindow *window) {
    if (!window || !DFSPExternal(window)) return CGRectNull;
    CGRect screenRect = window.screen.bounds;
    if (!DFSPRectOK(screenRect)) return CGRectNull;
    UIEdgeInsets inset = window.safeAreaInsets;
    BOOL usableInsets = isfinite(inset.top) && isfinite(inset.left) &&
                        isfinite(inset.bottom) && isfinite(inset.right) &&
                        inset.top>=0 && inset.left>=0 &&
                        inset.bottom>=0 && inset.right>=0 &&
                        (inset.top>0 || inset.left>0 ||
                         inset.bottom>0 || inset.right>0);
    if (!usableInsets) {
        // Native DuoNavi 1.0.4 +[CBWindow carPlayContentInsets]:
        // original arm64 at 0xb1544 loads d9 = 64.0 (left), others 0.
        // This is a SAFE fallback from the approved original's behavior,
        // not a SidePlay carDockArea or invented scale fraction.
        inset = UIEdgeInsetsMake(0, DFSPNativeFallbackLeft, 0, 0);
    }
    CGRect usable = UIEdgeInsetsInsetRect(screenRect, inset);
    if (!DFSPRectOK(usable) || !CGRectContainsRect(screenRect, usable))
        return CGRectNull;
    return usable;
}
static CGRect DFSPActiveWindowRect(void) {
    UIWindow *window=DFSPWindow;
    if (!DFSPExternal(window)) return CGRectNull;
    return DFSPFull ? window.screen.bounds : DFSPSystemUsableRect(window);
}
static void DFSPPositionZoom(void) {
    UIWindow *window=DFSPWindow;
    if (!window || !DFSPZoom) return;
    CGRect bounds=window.bounds;
    if (!DFSPRectOK(bounds)) return;
    CGFloat top=MAX(8.0,window.safeAreaInsets.top+8.0);
    DFSPZoom.frame=CGRectMake(MAX(10.0,bounds.size.width-112.0),top,98.0,38.0);
    [window bringSubviewToFront:DFSPZoom];
}

static BOOL DFSPApply(BOOL full, NSString *source) {
    UIWindow *window=DFSPWindow;
    SPDash *owner=DFSPManager;
    if (!window || !owner || !DFSPExternal(window) || DFSPApplying) return NO;
    CGRect normal=DFSPSystemUsableRect(window);
    CGRect desired=full ? window.screen.bounds : normal;
    if (!DFSPRectOK(desired)) {
        DFSPLog(@"REFUSE: native usable bounds unavailable; old window unchanged");
        return NO;
    }
    BOOL oldFull=DFSPFull;
    CGRect beforeFrame=window.frame;
    CGFloat beforeLevel=window.windowLevel;
    DFSPApplying=YES;
    DFSPFull=full;
    // Replace SPDash's old fullscreen frame at its own geometry setter.
    [owner setCarWindowFrame:desired];
    [owner layoutRootView];
    // Physically keep the old SidePlay fullscreen window OUT of the native
    // sidebar region in NORMAL; merely changing z-order (QA1) was not enough.
    window.frame=desired;
    // Keep QA1's device-observed visible Z level to avoid hiding SidePlay
    // behind Dashboard; suppress old fullscreen by contracting the window.
    CGFloat targetLevel=full ? DFSPOriginalLevel : (UIWindowLevelStatusBar-1.0);
    window.windowLevel=targetLevel;
    [window setNeedsLayout];
    [window layoutIfNeeded];
    DFSPPositionZoom();
    BOOL ok=DFSPNear(window.frame,desired) &&
            fabs(window.windowLevel-targetLevel)<1.0;
    if (!ok) {
        // Restore previous known state on partial geometric failure.
        DFSPFull=oldFull;
        window.frame=beforeFrame;
        window.windowLevel=beforeLevel;
        [owner setCarWindowFrame:beforeFrame];
        [owner layoutRootView];
        DFSPPositionZoom();
    }
    DFSPApplying=NO;
    DFSPLog([NSString stringWithFormat:
      @"apply=%d requestedFull=%d source=%@ original=%@ normal=%@ actual=%@ level=%.1f expected=%.1f safe=%@",
      ok,full,source,NSStringFromCGRect(DFSPOriginalFrame),
      NSStringFromCGRect(normal),NSStringFromCGRect(window.frame),
      window.windowLevel,targetLevel,NSStringFromUIEdgeInsets(window.safeAreaInsets)]);
    return ok;
}

@interface DFSPZoomQA2Target : NSObject
- (void)pressed:(id)sender;
@end
@implementation DFSPZoomQA2Target
- (void)pressed:(id)sender {
    (void)sender;
    if (DFSPApply(!DFSPFull,@"button")) {
        [DFSPZoom setTitle:DFSPFull?@"Zoom Out":@"Zoom In"
                 forState:UIControlStateNormal];
        DFSPZoom.accessibilityLabel=DFSPFull?@"Zoom Out":@"Zoom In";
    }
}
@end
static void DFSPRemove(void) {
    UIWindow *oldWindow=DFSPWindow;
    if (oldWindow) {
        oldWindow.windowLevel=DFSPOriginalLevel;
        oldWindow.frame=DFSPOriginalFrame;
    }
    [DFSPZoom removeFromSuperview];
    DFSPZoom=nil;
    DFSPAction=nil;
    DFSPWindow=nil;
    DFSPManager=nil;
    DFSPFull=NO;
    DFSPApplying=NO;
    DFSPLog(@"window detached; old SidePlay level/frame restored");
}
static void DFSPInstall(SPDash *owner, UIWindow *window,
                        NSUInteger generation, NSUInteger attempt) {
    if (generation!=DFSPSequence || !owner || !window) return;
    if (!DFSPExternal(window)) {
        if (attempt<12)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,250000000),
                           dispatch_get_main_queue(), ^{
                DFSPInstall(owner,window,generation,attempt+1);
            });
        else DFSPLog(@"window not external; no global UIWindow override");
        return;
    }
    if (DFSPWindow==window && DFSPZoom) {
        if (!DFSPFull) (void)DFSPApply(NO,@"reconnected");
        return;
    }
    if (DFSPWindow && DFSPWindow!=window) DFSPRemove();
    DFSPOriginalLevel=window.windowLevel;
    DFSPOriginalFrame=window.frame;
    DFSPWindow=window;
    DFSPManager=owner;
    DFSPFull=NO;
    DFSPApplying=NO;
    DFSPLayoutCalls=0;
    DFSPAction=[DFSPZoomQA2Target new];
    UIButton *button=[UIButton buttonWithType:UIButtonTypeSystem];
    button.tag=DFSPZoomTag;
    [button setTitle:@"Zoom In" forState:UIControlStateNormal];
    button.accessibilityLabel=@"Zoom In";
    button.titleLabel.font=[UIFont boldSystemFontOfSize:13];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.backgroundColor=[UIColor colorWithRed:0.12 green:0.14 blue:0.19 alpha:0.95];
    button.layer.cornerRadius=10;
    button.layer.borderColor=[UIColor colorWithWhite:0.8 alpha:0.7].CGColor;
    button.layer.borderWidth=1;
    [button addTarget:DFSPAction action:@selector(pressed:)
        forControlEvents:UIControlEventTouchUpInside];
    DFSPZoom=button;
    [window addSubview:button];
    DFSPLog([NSString stringWithFormat:
        @"SPDash host attached external=%@ originalFrame=%@ oldLevel=%.1f",
        window.screen,NSStringFromCGRect(DFSPOriginalFrame),DFSPOriginalLevel]);
    if (!DFSPApply(NO,@"startup"))
        DFSPLog(@"startup override FAILED; leave SidePlay host recoverable");
}
%hook SPDash
- (void)setCarWindow:(UIWindow *)window {
    %orig; // preserve creation and app hosting; replace only display control
    NSUInteger generation=++DFSPSequence;
    if (!window) {
        if (DFSPManager==self) DFSPRemove();
        return;
    }
    __weak SPDash *weakOwner=self;
    __weak UIWindow *weakWindow=window;
    dispatch_async(dispatch_get_main_queue(), ^{
        DFSPInstall(weakOwner,weakWindow,generation,0);
    });
}
- (BOOL)carDockMode {
    // Disable SidePlay's old dock/fullscreen layout *decision*, NOT app host.
    if (DFSPManager==self && DFSPWindow && !DFSPFull) return NO;
    return %orig;
}
- (CGRect)carWindowFrameNow {
    if (DFSPManager==self && DFSPWindow) {
        CGRect desired=DFSPActiveWindowRect();
        if (DFSPRectOK(desired)) return desired;
    }
    return %orig;
}
- (void)setCarWindowFrame:(CGRect)frame {
    if (DFSPManager==self && DFSPWindow) {
        CGRect desired=DFSPActiveWindowRect();
        if (DFSPRectOK(desired)) frame=desired;
    }
    %orig(frame);
}
- (void)layoutRootView {
    // Old host/layout still renders app content, but cannot own NORMAL frame.
    %orig;
    if (DFSPManager==self && DFSPWindow && !DFSPApplying) {
        UIWindow *window=DFSPWindow;
        CGRect desired=DFSPActiveWindowRect();
        if (DFSPRectOK(desired)) {
            if (!DFSPNear(window.frame,desired)) {
                window.frame=desired;
                if (++DFSPLayoutCalls<=5)
                    DFSPLog(@"old SidePlay relayout attempted fullscreen; normalized");
            }
            CGFloat desiredLevel=DFSPFull?DFSPOriginalLevel:UIWindowLevelStatusBar-1.0;
            if (fabs(window.windowLevel-desiredLevel)>0.5)
                window.windowLevel=desiredLevel;
        }
        DFSPPositionZoom();
    }
}
%end

static void DFSPTryInit(unsigned attempt) {
    if (objc_getClass("SPDash")) {
        %init;
        DFSPLog(@"SPDash display takeover hooks QA2 installed");
        return;
    }
    if (attempt<30)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,1000000000),
                       dispatch_get_main_queue(), ^{DFSPTryInit(attempt+1);});
    else DFSPLog(@"SPDash class missing; disabled");
}
%ctor {
    @autoreleasepool {
        if (![NSBundle.mainBundle.bundleIdentifier.lowercaseString
               isEqualToString:@"com.apple.springboard"]) return;
        dispatch_async(dispatch_get_main_queue(), ^{DFSPTryInit(0);});
    }
}
