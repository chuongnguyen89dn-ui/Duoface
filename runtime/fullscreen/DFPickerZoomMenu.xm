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
static CGRect DFNativeHeaderLogoFrame(UIView *overlay, UIView *rowParent,
                                      CGFloat leftEdge, CGFloat rightEdge, CGFloat rowTop) {
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
        ![rowParent isDescendantOfView:overlay]) {title.hidden=NO;return CGRectNull;}
    CGFloat width=rightEdge-leftEdge;
    if (!isfinite(width) || width<100) {title.hidden=NO;return CGRectNull;}
    // Same left/right edges as the four-column 40pt menu, separate row above.
    CGFloat logoHeight=MIN(30.0,MAX(18.0,rowTop-4.0));
    CGRect target=CGRectMake(leftEdge,rowTop-logoHeight-2.0,width,logoHeight);
    headerIcon.frame=[headerIcon.superview convertRect:target fromView:rowParent];
    headerIcon.image=logo;
    headerIcon.contentMode=UIViewContentModeScaleAspectFit;
    headerIcon.clipsToBounds=YES;
    title.hidden=YES;
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
    // User-approved two full-width rows: logo above, four equal columns below.
    CGFloat left=MAX(CGRectGetMinX(parent.bounds)+4.0,nativeLeft);
    CGFloat col=(right-left)/4.0;
    if (col<53.0) {
        NSLog(@"[DuoFaceFullscreen] picker 40pt row too narrow %.1f",col);
        return;
    }
    (void)DFNativeHeaderLogoFrame(overlay,parent,left,right,top);
    const CGFloat menuHeight=40.0;
    app.frame=CGRectMake(left,top,col,menuHeight);
    zoom.frame=CGRectMake(left+col,top,col,menuHeight);
    style.frame=CGRectMake(left+2*col,top,col,menuHeight);
    close.frame=CGRectMake(left+3*col,top,col,menuHeight);
    UIFont *font=[UIFont systemFontOfSize:10.0];
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
    UIColor *accent=DFApprovedLogoRed();
    // Selection follows the actual picker mode, not fullscreen state.
    Ivar modeIvar=class_getInstanceVariable(object_getClass(overlay),"_overlayMode");
    NSInteger mode=modeIvar?[(NSNumber *)object_getIvar(overlay,modeIvar) integerValue]:0;
    for (UIButton *button in @[app,zoom,style,close]) {
        button.layer.cornerRadius=0;
        button.layer.borderWidth=0;
        button.backgroundColor=UIColor.clearColor;
        button.tintColor=[UIColor colorWithWhite:0.85 alpha:1];
        [button setTitleColor:[UIColor colorWithWhite:0.85 alpha:1] forState:UIControlStateNormal];
    }
    UIButton *selected=mode==1?style:(mode==2?close:app);
    selected.backgroundColor=accent?:UIColor.clearColor;
    [selected setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    // Zoom only highlights while its own control is pressed, never permanently.
    UIImageView *selectedIcon=objc_getAssociatedObject(selected,DFStackIconKey);
    if (selectedIcon) selectedIcon.tintColor=UIColor.whiteColor;
    for (UIButton *button in @[app,zoom,style,close]) {
        UIImageView *icon=objc_getAssociatedObject(button,DFStackIconKey);
        if (icon && button!=selected) icon.tintColor=button.tintColor;
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
