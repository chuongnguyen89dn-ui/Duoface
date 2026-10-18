#import "DFSPNative12Host.h"
#import <math.h>

static BOOL DFSPRectValid(CGRect r) {
    return isfinite(r.origin.x) && isfinite(r.origin.y) &&
           isfinite(r.size.width) && isfinite(r.size.height) &&
           r.size.width > 100.0 && r.size.height > 100.0;
}
static BOOL DFSPRectNear(CGRect a,CGRect b) {
    return fabs(a.origin.x-b.origin.x)<0.5 &&
           fabs(a.origin.y-b.origin.y)<0.5 &&
           fabs(a.size.width-b.size.width)<0.5 &&
           fabs(a.size.height-b.size.height)<0.5;
}
@interface DFSPNative12Host ()
@property(nonatomic,weak) UIWindow *window;
@property(nonatomic,weak) UIView *contentRoot;
@property(nonatomic) CGRect originalFrame;
@property(nonatomic) CGAffineTransform originalTransform;
@property(nonatomic) CGRect usableRect;
@property(nonatomic,readwrite) BOOL isFullscreen;
@property(nonatomic,readwrite) BOOL isAttached;
@end
@implementation DFSPNative12Host
- (instancetype)initWithCarPlayWindow:(UIWindow *)window
                          contentRoot:(UIView *)content
                  nativeUsableInWindow:(CGRect)usable {
    if (!window || !content || !DFSPRectValid(window.bounds) ||
        !DFSPRectValid(usable) || !CGRectContainsRect(window.bounds,usable) ||
        ![content isDescendantOfView:window] ||
        !CGAffineTransformIsIdentity(content.transform)) return nil;
    if ((self=[super init])) {
        _window=window;
        _contentRoot=content;
        _usableRect=usable;
        _originalFrame=content.frame;
        _originalTransform=content.transform;
        _isAttached=YES;
        _isFullscreen=NO;
    }
    return self;
}
- (BOOL)applyNormal {
    NSCAssert(NSThread.isMainThread,@"CarPlay UI owner must be main-thread");
    UIWindow *w=self.window;
    UIView *v=self.contentRoot;
    if (!self.isAttached || !w || !v ||
        ![v isDescendantOfView:w] || !DFSPRectValid(self.usableRect) ||
        !CGRectContainsRect(w.bounds,self.usableRect)) return NO;
    UIView *container=v.superview;
    if (!container) return NO;
    CGRect target=[container convertRect:self.usableRect fromView:w];
    if (!DFSPRectValid(target)) return NO;
    v.frame=target;
    [v setNeedsLayout];
    [v layoutIfNeeded];
    self.isFullscreen=NO;
    return DFSPRectNear(v.frame,target);
}
- (BOOL)applyFullscreen {
    NSCAssert(NSThread.isMainThread,@"CarPlay UI owner must be main-thread");
    UIWindow *w=self.window;
    UIView *v=self.contentRoot;
    if (!self.isAttached || !w || !v ||
        ![v isDescendantOfView:w] || !DFSPRectValid(w.bounds)) return NO;
    UIView *container=v.superview;
    if (!container) return NO;
    CGRect target=[container convertRect:w.bounds fromView:w];
    if (!DFSPRectValid(target)) return NO;
    v.frame=target;
    [v setNeedsLayout];
    [v layoutIfNeeded];
    BOOL ok=DFSPRectNear(v.frame,target);
    self.isFullscreen=ok;
    return ok;
}
- (BOOL)reconcileAfterSystemLayout {
    if (!self.isAttached) return NO;
    return self.isFullscreen ? [self applyFullscreen] : [self applyNormal];
}
- (void)restoreAndDetach {
    NSCAssert(NSThread.isMainThread,@"CarPlay UI owner must be main-thread");
    UIView *v=self.contentRoot;
    if (self.isAttached && v) {
        v.transform=self.originalTransform;
        v.frame=self.originalFrame;
        [v setNeedsLayout];
    }
    self.isFullscreen=NO;
    self.isAttached=NO;
    self.window=nil;
    self.contentRoot=nil;
}
@end
