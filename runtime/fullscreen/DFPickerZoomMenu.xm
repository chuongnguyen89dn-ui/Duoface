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
    // Small native 10/11pt labels remain legible across CarPlay widths.
    b.imageEdgeInsets = UIEdgeInsetsZero;
    b.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
    b.contentEdgeInsets = UIEdgeInsetsMake(0, 2, 0, 2);
    b.titleLabel.adjustsFontSizeToFitWidth = YES;
    b.titleLabel.minimumScaleFactor = 0.85;
    b.titleLabel.lineBreakMode = NSLineBreakByClipping;
    b.tintColor = [UIColor colorWithWhite:0.72 alpha:1];
}
// DuoFace v12 already installs this APPROVED 960x240 asset in the base DEB.
// Never draw or synthesize a substitute. When absent, restore the native title.
static UIImage *DFPickerApprovedHeaderLogo(void) {
    static UIImage *image;
    if (!image) image = [UIImage imageWithContentsOfFile:
        @"/var/jb/Library/Application Support/DuoFace/duoface-logo.png"];
    return image;
}
static CGRect DFNativeHeaderLogoFrame(UIView *overlay, UIView *rowParent,
                                      CGFloat rightEdge) {
    // Header ivar is a UIImageView, NOT one of the three segment buttons.
    Ivar iconIvar = class_getInstanceVariable(object_getClass(overlay), "_headerIcon");
    Ivar labelIvar = class_getInstanceVariable(object_getClass(overlay), "_titleLabel");
    id iconObject = iconIvar ? object_getIvar(overlay, iconIvar) : nil;
    id labelObject = labelIvar ? object_getIvar(overlay, labelIvar) : nil;
    if (![iconObject isKindOfClass:UIImageView.class] ||
        ![labelObject isKindOfClass:UILabel.class]) return CGRectNull;
    UIImageView *headerIcon = iconObject;
    UILabel *title = labelObject;
    UIImage *logo = DFPickerApprovedHeaderLogo();
    if (!logo || !headerIcon.superview || !title.superview ||
        ![headerIcon isDescendantOfView:overlay] ||
        ![rowParent isDescendantOfView:overlay]) {
        title.hidden = NO; // Do not hide native header when logo cannot load.
        return CGRectNull;
    }
    // Derive current native header origin/height every setup/layout pass.
    // Bounds converted between common ancestor views, even before window attach.
    CGRect iconRect = [rowParent convertRect:headerIcon.frame fromView:headerIcon.superview];
    CGRect labelRect = [rowParent convertRect:title.frame fromView:title.superview];
    CGFloat x = CGRectGetMinX(iconRect);
    CGFloat centerY = CGRectGetMidY(labelRect);
    if (!isfinite(x) || !isfinite(centerY)) return CGRectNull;
    CGFloat desiredHeight = MIN(34.0, MAX(24.0, CGRectGetHeight(labelRect)));
    // Keep space for all FOUR menu items + trailing gap before the native X.
    CGFloat allowed = rightEdge - x - 4.0*76.0 - 18.0;
    CGFloat width = MIN(logo.size.width / logo.size.height * desiredHeight,
                        MAX(0.0, allowed));
    if (!isfinite(width) || width < 68.0) {
        title.hidden = NO;
        return CGRectNull;
    }
    CGFloat height = width * logo.size.height / logo.size.width;
    CGRect target = CGRectMake(x, centerY - height/2.0, width, height);
    // Convert from menu row coordinates into the existing header parent.
    headerIcon.frame = [headerIcon.superview convertRect:target fromView:rowParent];
    headerIcon.image = logo;
    headerIcon.contentMode = UIViewContentModeScaleAspectFit;
    headerIcon.clipsToBounds = YES;
    title.hidden = YES;
    return target;
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
    CGFloat nativeLeft=fmin(CGRectGetMinX(a),fmin(CGRectGetMinX(b),CGRectGetMinX(c)));
    CGFloat right=fmax(CGRectGetMaxX(a),fmax(CGRectGetMaxX(b),CGRectGetMaxX(c)));
    CGFloat top=fmin(CGRectGetMinY(a),fmin(CGRectGetMinY(b),CGRectGetMinY(c)));
    CGFloat height=CGRectGetHeight(a);
    if (!isfinite(nativeLeft) || !isfinite(right) || !isfinite(top) ||
        height<12 || right-nativeLeft<100) return;
    // Photo menu-zoom1: the native 3-tab top-right strip was divided into 4.
    // Use the otherwise empty space between the DuoFace logo and the last tab.
    CGRect header=DFNativeHeaderLogoFrame(overlay,parent,right);
    CGFloat left=nativeLeft;
    if (!CGRectIsNull(header)) left=MIN(nativeLeft,CGRectGetMaxX(header)+10.0);
    else {
        Ivar titleIvar=class_getInstanceVariable(object_getClass(overlay),"_titleLabel");
        id value=titleIvar?object_getIvar(overlay,titleIvar):nil;
        if ([value isKindOfClass:UILabel.class] && [value superview]) {
            UILabel *titleView=value;
            CGRect titleRect=[parent convertRect:titleView.frame fromView:titleView.superview];
            left=MIN(left,CGRectGetMaxX(titleRect)+10.0);
        }
    }
    left=MAX(left,CGRectGetMinX(parent.bounds)+4.0);
    CGFloat col=(right-left)/4.0;
    if (col<53.0) {
        // Do not force text into unusable slots or collide with the header.
        NSLog(@"[DuoFaceFullscreen] picker row too narrow %.1f",col);
        return;
    }
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
    if (!font) font=[UIFont systemFontOfSize:10.0];
    // All tabs keep the same font. Reduce only when the longest complete
    // label+outlined icon needs it; never truncate or substitute ellipses.
    CGFloat fullWidth=[@"Close App" sizeWithAttributes:@{NSFontAttributeName:font}].width
                      + 14.0 + 5.0 + 8.0;
    CGFloat needed=MAX(fullWidth,
        [title sizeWithAttributes:@{NSFontAttributeName:font}].width+27.0);
    if (col<needed) {
        CGFloat fontSize=MAX(8.0,font.pointSize*((col-16.0)/MAX(1.0,needed-16.0)));
        font=[font fontWithSize:fontSize];
    }
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
