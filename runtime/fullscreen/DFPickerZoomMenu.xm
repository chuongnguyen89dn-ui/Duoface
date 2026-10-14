#import "DFPickerZoomMenu.h"
#import "DFHostGeometry.h"
#import <objc/runtime.h>
#import <math.h>

// Original v12 CBMultitaskingOverlayView getter (IMP 0xABA54).
// The three native switchTo... actions update this state themselves.
@interface NSObject (DFNativePickerMode)
- (NSInteger)overlayMode;
@end
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
static const void *DFStackIconKey=&DFStackIconKey;
static void DFDecorate(UIButton *b, NSString *title, NSString *symbol, UIFont *font) {
    [b setTitle:title forState:UIControlStateNormal];
    UIImage *image=[UIImage systemImageNamed:symbol withConfiguration:
        [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightRegular]];
    UIImageView *icon=objc_getAssociatedObject(b,DFStackIconKey);
    if (!icon) {
        icon=[UIImageView new];
        icon.contentMode=UIViewContentModeScaleAspectFit;
        icon.userInteractionEnabled=NO;
        [b addSubview:icon];
        objc_setAssociatedObject(b,DFStackIconKey,icon,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    icon.image=image;
    icon.tintColor=b.tintColor;
    icon.frame=CGRectMake((CGRectGetWidth(b.bounds)-16)/2.0,3,16,16);
    [b setImage:nil forState:UIControlStateNormal];
    if (font) b.titleLabel.font=font;
    b.contentHorizontalAlignment=UIControlContentHorizontalAlignmentCenter;
    b.contentVerticalAlignment=UIControlContentVerticalAlignmentCenter;
    b.titleLabel.textAlignment=NSTextAlignmentCenter;
    b.titleEdgeInsets=UIEdgeInsetsMake(19,0,0,0);
    b.contentEdgeInsets=UIEdgeInsetsZero;
    b.titleLabel.adjustsFontSizeToFitWidth=YES;
    b.titleLabel.minimumScaleFactor=0.85;
    b.titleLabel.lineBreakMode=NSLineBreakByClipping;
}
static UIColor *DFApprovedLogoRed(void) {
    static UIColor *accent=nil;
    if (accent) return accent;
    UIImage *logo=[UIImage imageWithContentsOfFile:
        @"/var/jb/Library/Application Support/DuoFace/duoface-logo.png"];
    if (!logo.CGImage) return nil;
    uint8_t pixels[32*16*4]={0};
    CGColorSpaceRef space=CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx=CGBitmapContextCreate(pixels,32,16,8,32*4,space,
        kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(space);
    if (!ctx) return nil;
    CGContextDrawImage(ctx,CGRectMake(0,0,32,16),logo.CGImage);
    CGContextRelease(ctx);
    int best=-1,score=0;
    for (int i=0;i<32*16;i++) {
        int r=pixels[i*4],g=pixels[i*4+1],bl=pixels[i*4+2],alpha=pixels[i*4+3];
        int strength=r-MAX(g,bl);
        if (alpha>180 && r>100 && strength>score) {score=strength;best=i;}
    }
    if (best<0) return nil;
    accent=[UIColor colorWithRed:pixels[best*4]/255.0
        green:pixels[best*4+1]/255.0 blue:pixels[best*4+2]/255.0 alpha:1];
    return accent;
}
// DuoFace v12 already installs this APPROVED 960x240 asset in the base DEB.
// Never draw or synthesize a substitute. When absent, restore the native title.
static UIImage *DFPickerApprovedHeaderLogo(void) {
    static UIImage *image;
    if (!image) image = [UIImage imageWithContentsOfFile:
        @"/var/jb/Library/Application Support/DuoFace/duoface-logo.png"];
    return image;
}
// Reuse the installed 960x240 DuoFace artwork. Equal outer bounds are critical:
// both logo row and 4-column menu span [leftEdge, rightEdge].
static CGRect DFNativeHeaderLogoFrame(UIView *overlay, UIView *rowParent,
                                      CGFloat leftEdge, CGFloat rightEdge,
                                      CGFloat rowTop, CGFloat rowHeight) {
    Ivar iconIvar=class_getInstanceVariable(object_getClass(overlay),"_headerIcon");
    Ivar labelIvar=class_getInstanceVariable(object_getClass(overlay),"_titleLabel");
    id iconObj=iconIvar?object_getIvar(overlay,iconIvar):nil;
    id labelObj=labelIvar?object_getIvar(overlay,labelIvar):nil;
    if (![iconObj isKindOfClass:UIImageView.class] ||
        ![labelObj isKindOfClass:UILabel.class]) return CGRectNull;
    UIImageView *headerIcon=iconObj;
    UILabel *title=labelObj;
    UIImage *logo=DFPickerApprovedHeaderLogo();
    if (!logo || !headerIcon.superview || !title.superview ||
        ![rowParent isDescendantOfView:overlay]) {
        title.hidden=NO;
        return CGRectNull;
    }
    CGFloat width=rightEdge-leftEdge;
    if (!isfinite(width) || width<100.0 || !isfinite(rowTop) ||
        !isfinite(rowHeight) || rowHeight<16.0) {
        title.hidden=NO;
        return CGRectNull;
    }
    CGRect target=CGRectMake(leftEdge,rowTop,width,rowHeight);
    headerIcon.frame=[headerIcon.superview convertRect:target fromView:rowParent];
    headerIcon.image=logo;
    headerIcon.contentMode=UIViewContentModeScaleAspectFit;
    headerIcon.clipsToBounds=YES;
    title.hidden=YES;
    return target;
}
// The v12 native content views are laid out for 22/26pt tabs. The 40pt
// stacked row takes more space: move only content starting below those tabs,
// leaving the native header, X, buttons, callbacks, and sheet untouched.
static void DFReflowPickerContent(UIView *parent, UIView *overlay,
                                  NSArray<UIView *> *menuButtons,
                                  CGFloat nativeBottom, CGFloat desiredTop) {
    Ivar headerIvar=class_getInstanceVariable(object_getClass(overlay),"_headerIcon");
    Ivar titleIvar=class_getInstanceVariable(object_getClass(overlay),"_titleLabel");
    UIView *header=headerIvar?object_getIvar(overlay,headerIvar):nil;
    UIView *title=titleIvar?object_getIvar(overlay,titleIvar):nil;
    if (desiredTop<=nativeBottom+1.0) return;
    for (UIView *child in parent.subviews) {
        if (child==header || child==title || [menuButtons containsObject:child])
            continue;
        CGRect frame=child.frame;
        // Ignore the card background, native close X and decorative elements
        // above the old menu. Only shift actual content immediately below it.
        if (!isfinite(frame.origin.y) || !isfinite(frame.size.height) ||
            frame.size.height<10.0 || frame.origin.y<nativeBottom-1.0 ||
            frame.origin.y>=desiredTop) continue;
        CGFloat oldBottom=CGRectGetMaxY(frame);
        frame.origin.y=desiredTop;
        if ([child isKindOfClass:UIScrollView.class]) {
            frame.size.height=MAX(30.0,oldBottom-desiredTop);
        }
        child.frame=frame;
    }
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
    // Approved two rows: original horizontal logo above 40pt menu.
    // Both rows align on exactly the same native left and right edges.
    CGFloat left=MAX(CGRectGetMinX(parent.bounds)+4.0,nativeLeft);
    CGFloat width=right-left;
    CGFloat col=width/4.0;
    if (col<53.0) {
        NSLog(@"[DuoFaceFullscreen] picker column too narrow %.1f",col);
        return;
    }
    CGFloat nativeBottom=top+height;
    CGFloat logoTop=CGRectGetMinY(parent.bounds)+4.0;
    CGFloat safeHeight=CGRectGetHeight(parent.bounds)-40.0-90.0-12.0;
    CGFloat logoHeight=MIN(width/4.0,MAX(16.0,safeHeight));
    CGRect logoFrame=DFNativeHeaderLogoFrame(overlay,parent,left,right,
                                             logoTop,logoHeight);
    CGFloat menuTop=CGRectIsNull(logoFrame)?top:CGRectGetMaxY(logoFrame)+4.0;
    const CGFloat menuHeight=40.0;
    app.frame=CGRectMake(left,menuTop,col,menuHeight);
    zoom.frame=CGRectMake(left+col,menuTop,col,menuHeight);
    style.frame=CGRectMake(left+2*col,menuTop,col,menuHeight);
    close.frame=CGRectMake(left+3*col,menuTop,col,menuHeight);
    DFReflowPickerContent(parent,overlay,@[app,zoom,style,close],
                          nativeBottom,menuTop+menuHeight+2.0);
    // Preserve the native font weight; only set approved 10pt size.
    UIFont *originalFont=app.titleLabel.font?:[UIFont systemFontOfSize:10.0];
    UIFont *font=[originalFont fontWithSize:10.0];
    BOOL expanded=DFHostIsExpanded();
    zoom.enabled=expanded || DFHostCanExpand();
    zoom.alpha=zoom.enabled?1.0:0.5;
    NSString *zoomTitle=expanded?@"Zoom Out":@"Zoom In";
    zoom.accessibilityLabel=zoomTitle;
    DFDecorate(app,@"App",@"square.grid.2x2",font);
    DFDecorate(zoom,zoomTitle,expanded?@"arrow.down.right.and.arrow.up.left":
        @"arrow.up.left.and.arrow.down.right",font);
    DFDecorate(style,@"Style",@"rectangle.3.group",font);
    DFDecorate(close,@"Close App",@"xmark.circle",font);
    // Getter is present in the original v12 class (IMP 0xABA54).
    // The original actions set the mode, so no duplicate event handlers.
    NSInteger mode=[overlay respondsToSelector:@selector(overlayMode)]?
        [(id)overlay overlayMode]:-1;
    UIButton *active=nil;
    if (mode==0) active=app;
    else if (mode==1) active=style;
    else if (mode==2) active=close;
    if (expanded) active=zoom;
    UIColor *originalActiveColor=active.backgroundColor;
    UIColor *red=DFApprovedLogoRed();
    UIColor *inactiveText=[UIColor colorWithWhite:0.68 alpha:1.0];
    for (UIButton *button in @[app,zoom,style,close]) {
        BOOL selected=button==active;
        button.layer.cornerRadius=0.0;
        button.layer.borderWidth=0.0;
        button.backgroundColor=selected?(red?:originalActiveColor):UIColor.clearColor;
        UIColor *textColor=selected?UIColor.whiteColor:inactiveText;
        [button setTitleColor:textColor forState:UIControlStateNormal];
        button.tintColor=textColor;
        UIImageView *icon=objc_getAssociatedObject(button,DFStackIconKey);
        if (icon) icon.tintColor=textColor;
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
