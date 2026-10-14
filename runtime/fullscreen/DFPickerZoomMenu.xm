#import "DFPickerZoomMenu.h"
#import "DFHostGeometry.h"
#import <objc/runtime.h>
#import <math.h>
// Native three segment actions are untouched. SpringBoard owns this v12 picker.
static NSString * const DFMenuZoomEvent = @"com.duoface.fullscreen.picker.v1";
static NSHashTable<UIView *> *DFOverlays;
static const void *DFZoomKey = &DFZoomKey;
static BOOL DFHookReady;
@interface NSObject (DFDistributedPost)
+ (id)defaultCenter;
- (void)postNotificationName:(NSString *)name object:(id)object userInfo:(NSDictionary *)info;
@end
@interface DFZoomAction : NSObject
- (void)pressed:(UIButton *)sender;
@end
static DFZoomAction *DFAction;
static UIButton *DFTab(id overlay, const char *name) {
    Ivar ivar = class_getInstanceVariable(object_getClass(overlay), name);
    id value = ivar ? object_getIvar(overlay, ivar) : nil;
    return [value isKindOfClass:UIButton.class] ? value : nil;
}
static void DFDecorate(UIButton *b, NSString *title, NSString *symbol, UIFont *font) {
    [b setTitle:title forState:UIControlStateNormal];
    [b setImage:[UIImage systemImageNamed:symbol withConfiguration:
        [UIImageSymbolConfiguration configurationWithPointSize:10 weight:UIImageSymbolWeightMedium]]
        forState:UIControlStateNormal];
    if (font) b.titleLabel.font = font;
    b.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    b.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
    b.imageEdgeInsets = UIEdgeInsetsMake(0, -2, 0, 2);
    b.titleEdgeInsets = UIEdgeInsetsMake(0, 2, 0, -2);
    b.tintColor = [UIColor colorWithWhite:0.72 alpha:1];
}
static void DFLayoutPicker(UIView *overlay) {
    UIButton *app=DFTab(overlay,"_appSegmentBtn");
    UIButton *style=DFTab(overlay,"_layoutSegmentBtn");
    UIButton *close=DFTab(overlay,"_recentSegmentBtn");
    if (!app || !style || !close || !app.superview ||
        style.superview!=app.superview || close.superview!=app.superview) return;
    UIView *parent=app.superview;
    UIButton *zoom=objc_getAssociatedObject(overlay,DFZoomKey);
    if (!zoom) {
        zoom=[UIButton buttonWithType:UIButtonTypeCustom];
        [zoom addTarget:DFAction action:@selector(pressed:) forControlEvents:UIControlEventTouchUpInside];
        zoom.accessibilityHint=@"Phóng to hoặc thu nhỏ giao diện DuoFace";
        objc_setAssociatedObject(overlay,DFZoomKey,zoom,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [parent addSubview:zoom];
    } else if (zoom.superview!=parent) {
        [zoom removeFromSuperview]; [parent addSubview:zoom];
    }
    CGRect a=app.frame,b=style.frame,c=close.frame;
    CGFloat left=fmin(CGRectGetMinX(a),fmin(CGRectGetMinX(b),CGRectGetMinX(c)));
    CGFloat right=fmax(CGRectGetMaxX(a),fmax(CGRectGetMaxX(b),CGRectGetMaxX(c)));
    CGFloat top=fmin(CGRectGetMinY(a),fmin(CGRectGetMinY(b),CGRectGetMinY(c)));
    CGFloat height=CGRectGetHeight(a), col=(right-left)/4.0;
    if (!isfinite(col) || !isfinite(top) || col<25 || height<12) return;
    app.frame=CGRectMake(left,top,col,height);
    zoom.frame=CGRectMake(left+col,top,col,height);
    style.frame=CGRectMake(left+2*col,top,col,height);
    close.frame=CGRectMake(left+3*col,top,col,height);
    zoom.layer.cornerRadius=app.layer.cornerRadius;
    BOOL expanded=DFHostIsExpanded();
    zoom.enabled=expanded || DFHostCanExpand();
    zoom.alpha=zoom.enabled ? 1.0 : 0.5;
    NSString *title=expanded?@"Zoom Out":@"Zoom In";
    zoom.accessibilityLabel=title;
    UIFont *font=app.titleLabel.font;
    DFDecorate(app,@"App",@"square.grid.2x2",font);
    DFDecorate(style,@"Style",@"rectangle.3.group",font);
    DFDecorate(close,@"Close App",@"xmark.circle",font);
    DFDecorate(zoom,title,expanded?@"arrow.down.right.and.arrow.up.left":
                @"arrow.up.left.and.arrow.down.right",font);
    zoom.backgroundColor=expanded?[UIColor colorWithRed:0.76 green:0.10 blue:0.14 alpha:1]:
                                UIColor.clearColor;
    [zoom setTitleColor:expanded?UIColor.whiteColor:
        [UIColor colorWithWhite:0.68 alpha:1] forState:UIControlStateNormal];
    if (expanded) {
        zoom.tintColor=UIColor.whiteColor;
        for (UIButton *native in @[app,style,close]) {
            native.backgroundColor=UIColor.clearColor;
            [native setTitleColor:[UIColor colorWithWhite:0.68 alpha:1]
                          forState:UIControlStateNormal];
        }
    }
    [DFOverlays addObject:overlay];
}
@implementation DFZoomAction
- (void)pressed:(UIButton *)sender {
    BOOL expanded=DFHostIsExpanded();
    if (!expanded && !DFHostCanExpand()) return;
    Class cls=NSClassFromString(@"NSDistributedNotificationCenter");
    id center=[cls respondsToSelector:@selector(defaultCenter)]?[cls defaultCenter]:nil;
    if (![center respondsToSelector:@selector(postNotificationName:object:userInfo:)]) return;
    [center postNotificationName:DFMenuZoomEvent object:nil
       userInfo:@{@"version":@1,@"expanded":@(!expanded),@"requestID":NSUUID.UUID.UUIDString}];
    sender.enabled=NO;
    NSLog(@"[DuoFaceFullscreen] native picker zoom requested=%d",!expanded);
}
@end
%group DFPickerZoom
%hook CBMultitaskingOverlayView
- (void)setupCardContent {
    %orig;
    DFLayoutPicker((UIView *)self);
}
- (void)layoutSubviews {
    %orig;
    DFLayoutPicker((UIView *)self);
}
%end
%end
BOOL DFInstallPickerZoomMenuHooks(void) {
    if (DFHookReady) return YES;
    if (![[NSBundle.mainBundle.bundleIdentifier lowercaseString] isEqualToString:@"com.apple.springboard"] ||
        !NSClassFromString(@"CBMultitaskingOverlayView")) return NO;
    DFOverlays=[NSHashTable weakObjectsHashTable]; DFAction=[DFZoomAction new];
    %init(DFPickerZoom); DFHookReady=YES; return YES;
}
void DFPickerZoomMenuRefresh(void) {
    if (!DFHookReady || !NSThread.isMainThread) return;
    for (UIView *overlay in DFOverlays.allObjects)
        if (overlay.window) DFLayoutPicker(overlay);
}
