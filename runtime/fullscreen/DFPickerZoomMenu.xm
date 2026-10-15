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
// Scoped exclusively to native app-picker card construction. No global plus replacement.
static BOOL DFBuildingNativeAddTile;
// Scope native class-localized status strings strictly to construction of the
// Close/recent rows; never change stored PID/slot data or other screens.
static BOOL DFBuildingNativeRecentRows;
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
// The native v12 picker owns the dimming view, shadow carrier and blur card.
// Keep those UIKit views in place: dimming-view's tap recognizer dismisses the
// picker and its alpha must stay 1. Only clear their visual chrome.
static UIView *DFPickerNativeViewIvar(id overlay, const char *name) {
    Ivar ivar=class_getInstanceVariable(object_getClass(overlay),name);
    id object=ivar?object_getIvar(overlay,ivar):nil;
    return [object isKindOfClass:UIView.class]?(UIView *)object:nil;
}
static void DFClearNativePickerChrome(UIView *overlay) {
    UIView *dim=DFPickerNativeViewIvar(overlay,"_dimBackground");
    UIView *shadow=DFPickerNativeViewIvar(overlay,"_cardShadowContainer");
    UIView *card=DFPickerNativeViewIvar(overlay,"_sheetCard");
    if (dim) {
        dim.backgroundColor=UIColor.clearColor;
        dim.layer.borderWidth=0.0;
        // Do not hide the dim view or clear its alpha: that would disable
        // the original tap-outside-to-dismiss gesture.
    }
    if (shadow) {
        shadow.backgroundColor=UIColor.clearColor;
        shadow.layer.borderWidth=0.0;
        shadow.layer.shadowOpacity=0.0f;
    }
    if (card) {
        card.backgroundColor=UIColor.clearColor;
        card.layer.borderWidth=0.0;
        card.layer.shadowOpacity=0.0f;
        if ([card isKindOfClass:UIVisualEffectView.class]) {
            UIVisualEffectView *blur=(UIVisualEffectView *)card;
            blur.effect=nil;
            blur.contentView.backgroundColor=UIColor.clearColor;
            blur.contentView.layer.borderWidth=0.0;
        }
    }
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
    icon.frame=CGRectMake((CGRectGetWidth(b.bounds)-16)/2.0,1,16,16);
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
static UIColor *DFApprovedLogoRed(void);
// The v12 recent-app renderer adds its activity heading UILabel and native
// close-all UIButton to the SAME sheet contentView (audit: 0xA6A38, 0xA6D8C).
// Reuse the original UIButton: retain its closeAllBridgedAppsTapped: target.
// This removes only the redundant visible heading, not the running-app data.
static BOOL DFNativeCloseAllAction(UIButton *button) {
    for (id target in button.allTargets) {
        NSArray<NSString *> *actions=
            [button actionsForTarget:target
                    forControlEvent:UIControlEventTouchUpInside];
        if ([actions containsObject:@"closeAllBridgedAppsTapped:"]) return YES;
    }
    return NO;
}
static void DFRestyleRecentClearAll(UIView *overlay) {
    UIView *card=DFPickerNativeViewIvar(overlay,"_sheetCard");
    if (![card isKindOfClass:UIVisualEffectView.class]) return;
    UIView *content=((UIVisualEffectView *)card).contentView;
    UILabel *heading=nil;
    UIButton *clearAll=nil;
    for (UIView *view in content.subviews) {
        if ([view isKindOfClass:UIButton.class] &&
            DFNativeCloseAllAction((UIButton *)view))
            clearAll=(UIButton *)view;
        else if ([view isKindOfClass:UILabel.class]) {
            UILabel *label=(UILabel *)view;
            NSString *title=[label.text stringByTrimmingCharactersInSet:
                NSCharacterSet.whitespaceAndNewlineCharacterSet];
            if (title.length>0 &&
                [title rangeOfString:@"Đang hoạt động"
                            options:NSCaseInsensitiveSearch].location==0)
                heading=label;
        }
    }
    if (!heading || !clearAll || !heading.superview || !clearAll.superview)
        return; // Leave native layout intact when the target view changes.
    CGRect location=[heading.superview convertRect:heading.frame
                                            toView:clearAll.superview];
    if (!isfinite(location.origin.x) || !isfinite(location.origin.y) ||
        CGRectGetHeight(location)<14.0) return;
    CGFloat width=MIN(84.0,CGRectGetWidth(clearAll.superview.bounds)-
                        CGRectGetMinX(location)-8.0);
    if (width<68.0) return;
    // Center the 30pt control vertically within the former 34pt heading.
    clearAll.frame=CGRectMake(location.origin.x,
        location.origin.y+(location.size.height-30.0)/2.0,width,30.0);
    UIFont *font=[(clearAll.titleLabel.font?:[UIFont systemFontOfSize:10])
                  fontWithSize:10.0];
    DFDecorate(clearAll,@"Clear All",@"trash",font);
    clearAll.backgroundColor=UIColor.clearColor;
    clearAll.layer.borderWidth=0.0;
    clearAll.layer.cornerRadius=0.0;
    UIColor *accent=DFApprovedLogoRed();
    [clearAll setTitleColor:accent forState:UIControlStateNormal];
    clearAll.tintColor=accent;
    UIImageView *icon=objc_getAssociatedObject(clearAll,DFStackIconKey);
    if (icon) icon.tintColor=accent;
    clearAll.accessibilityLabel=@"Clear All";
    heading.hidden=YES;
}
// Original v12 builds each recent-app card as a 56pt row with a 20pt
// UIImageView, a title UILabel (top), a secondary status UILabel (below),
// and a native UIButton on the right. All four are children of that row:
// see v12 host audit 0xA71B0, 0xA7320, 0xA73E8, 0xA74C4, 0xA7770.
// Reflow these EXISTING controls; do not create a second close/restart button.
static const void *DFRecentInlineStatusKey=&DFRecentInlineStatusKey;
static NSInteger DFNativeSingleAppAction(UIButton *button) {
    for (id target in button.allTargets) {
        NSArray<NSString *> *actions=
            [button actionsForTarget:target
                    forControlEvent:UIControlEventTouchUpInside];
        if ([actions containsObject:@"restartSingleAppTapped:"]) return 1;
        if ([actions containsObject:@"closeSingleAppTapped:"]) return 2;
    }
    return 0;
}
static BOOL DFRestyleOneRecentAppRow(UIView *row) {
    if (CGRectGetWidth(row.bounds)<140.0 ||
        CGRectGetHeight(row.bounds)<32.0) return NO;
    UILabel *status=objc_getAssociatedObject(row,DFRecentInlineStatusKey);
    UILabel *name=nil;
    UIImageView *logo=nil;
    UIButton *action=nil;
    NSInteger kind=0;
    for (UIView *view in row.subviews) {
        if ([view isKindOfClass:UILabel.class]) {
            UILabel *label=(UILabel *)view;
            if (!status && ([label.text isEqualToString:@"🟢"] ||
                            [label.text isEqualToString:@"🔴"])) status=label;
            else if (label!=status && label.text.length>0 && !name) name=label;
        } else if ([view isKindOfClass:UIImageView.class]) {
            UIImageView *candidate=(UIImageView *)view;
            if (!logo && candidate.image &&
                CGRectGetWidth(candidate.frame)<=44.0 &&
                CGRectGetHeight(candidate.frame)<=44.0) logo=candidate;
        } else if ([view isKindOfClass:UIButton.class]) {
            NSInteger originalAction=DFNativeSingleAppAction((UIButton *)view);
            if (originalAction) {
                action=(UIButton *)view;
                kind=originalAction;
            }
        }
    }
    // Associated pointer survives subsequent native layout passes. If the
    // saved status was encountered before the title, locate the title now.
    if (status && !name) {
        for (UIView *view in row.subviews) {
            if ([view isKindOfClass:UILabel.class] && view!=status &&
                ((UILabel *)view).text.length>0) {
                name=(UILabel *)view;
                break;
            }
        }
    }
    if (!name || !status || status.superview!=row || !logo ||
        !action || !kind) return NO;
    // A native active-slot row has Restart; every off-slot row has Close.
    // Require the original status and action to agree instead of guessing.
    BOOL live=(kind==1);
    if (!objc_getAssociatedObject(row,DFRecentInlineStatusKey)) {
        if (live!=[status.text isEqualToString:@"🟢"]) return NO;
        objc_setAssociatedObject(row,DFRecentInlineStatusKey,status,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    CGFloat centerY=CGRectGetMidY(row.bounds);
    CGRect logoFrame=logo.frame;
    logoFrame.origin.y=round(centerY-CGRectGetHeight(logoFrame)/2.0);
    logo.frame=logoFrame;
    CGFloat left=MAX(CGRectGetMaxX(logoFrame)+8.0,
                     CGRectGetMinX(name.frame));
    CGFloat actionLeft=CGRectGetMinX(action.frame);
    CGFloat maxNameWidth=actionLeft-10.0-left-16.0-5.0;
    if (maxNameWidth<28.0) return NO;
    UIFont *nameFont=name.font?:[UIFont systemFontOfSize:13.0];
    CGFloat needed=ceil([name.text sizeWithAttributes:
        @{NSFontAttributeName:nameFont}].width)+3.0;
    CGFloat nameWidth=MAX(24.0,MIN(maxNameWidth,needed));
    CGFloat nameHeight=MIN(21.0,MAX(16.0,CGRectGetHeight(name.frame)));
    name.frame=CGRectMake(round(left),
        round(centerY-nameHeight/2.0),nameWidth,nameHeight);
    name.numberOfLines=1;
    name.lineBreakMode=NSLineBreakByTruncatingTail;
    // 14pt regular filled-circle glyph renders as a restrained ~9-10pt dot.
    // Keep it five points beyond the actual (possibly truncated) app title.
    status.text=@"●";
    status.font=[UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
    status.textAlignment=NSTextAlignmentCenter;
    status.frame=CGRectMake(CGRectGetMaxX(name.frame)+5.0,
                             round(centerY-10.0),16.0,20.0);
    UIColor *color=live?
        [UIColor colorWithRed:52.0/255.0 green:199.0/255.0
                        blue:89.0/255.0 alpha:1.0]:
        DFApprovedLogoRed();
    status.textColor=color;
    status.accessibilityLabel=live?@"Live":@"Chạy ngầm";
    // Only replace the glyph of the ORIGINAL native action control. Its
    // target/selector/accessibilityIdentifier and broad hitbox are retained.
    NSString *symbol=live?@"arrow.clockwise":@"xmark.circle";
    UIImage *glyph=[UIImage systemImageNamed:symbol withConfiguration:
        [UIImageSymbolConfiguration configurationWithPointSize:18.0
                                                        weight:UIImageSymbolWeightRegular]];
    if (glyph) {
        UIImage *template=[glyph imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [action setImage:template forState:UIControlStateNormal];
        [action setImage:template forState:UIControlStateHighlighted];
    }
    [action setTitle:@"" forState:UIControlStateNormal];
    [action setTitle:@"" forState:UIControlStateHighlighted];
    action.tintColor=color;
    action.backgroundColor=UIColor.clearColor;
    action.layer.borderWidth=0.0;
    action.layer.borderColor=UIColor.clearColor.CGColor;
    action.imageEdgeInsets=UIEdgeInsetsZero;
    action.titleEdgeInsets=UIEdgeInsetsZero;
    action.contentHorizontalAlignment=UIControlContentHorizontalAlignmentCenter;
    action.contentVerticalAlignment=UIControlContentVerticalAlignmentCenter;
    CGRect buttonFrame=action.frame;
    buttonFrame.origin.y=round(centerY-CGRectGetHeight(buttonFrame)/2.0);
    action.frame=buttonFrame;
    action.accessibilityLabel=live?@"Mở lại":@"Đóng ứng dụng";
    return YES;
}
static void DFRestyleRecentRowDescendants(UIView *view, NSUInteger depth) {
    if (depth>8) return;
    if (DFRestyleOneRecentAppRow(view)) return;
    for (UIView *child in view.subviews) {
        if ([child isKindOfClass:UILabel.class] ||
            [child isKindOfClass:UIImageView.class] ||
            [child isKindOfClass:UIButton.class]) continue;
        DFRestyleRecentRowDescendants(child,depth+1);
    }
}
static void DFRestyleNativeRecentAppRows(UIView *overlay) {
    UIView *card=DFPickerNativeViewIvar(overlay,"_sheetCard");
    if (![card isKindOfClass:UIVisualEffectView.class]) return;
    DFRestyleRecentRowDescendants(
        ((UIVisualEffectView *)card).contentView,0);
}
// One canonical accent sampled from the approved, installed horizontal logo.
// audit/approved-logo-red.json: SHA256 78450d8ee4759353bdc21f27a06016c03fab61038ae60109ba21515c087b0089
// RGB (227,2,15), #E3020F. Shared with src/DuoFaceBorderRunner.m.
static UIColor *DFApprovedLogoRed(void) {
    return [UIColor colorWithRed:227.0/255.0 green:2.0/255.0 blue:15.0/255.0 alpha:1.0];
}
// MENU ONLY: prefer the cropped, alpha-transparent derivative of the
// unchanged approved logo. Preserve the original asset for splash and elsewhere.
// The packaging step must install the derivative into the rootless support path
// before any separately authorized DEB build; otherwise use the original.
static UIImage *DFPickerApprovedHeaderLogo(void) {
    static UIImage *image;
    if (!image) {
        NSString *root=@"/var/jb/Library/Application Support/DuoFace/";
        image=[UIImage imageWithContentsOfFile:
            [root stringByAppendingString:@"duoface-logo-picker-alpha-v2.png"]];
        if (!image) image=[UIImage imageWithContentsOfFile:
            [root stringByAppendingString:@"duoface-logo.png"]];
    }
    return image;
}
// Reuse the approved 960x240 artwork in a compact leading menu slot.
// The logo stays on the SAME row as four native menu buttons.
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
    if (!isfinite(width) || width<32.0 || !isfinite(rowTop) ||
        !isfinite(rowHeight) || rowHeight<16.0) {
        title.hidden=NO;
        return CGRectNull;
    }
    CGRect target=CGRectMake(leftEdge,rowTop,width,rowHeight);
    headerIcon.frame=[headerIcon.superview convertRect:target fromView:rowParent];
    headerIcon.image=logo;
    headerIcon.contentMode=UIViewContentModeScaleAspectFit;
    headerIcon.backgroundColor=UIColor.clearColor;
    headerIcon.opaque=NO;
    headerIcon.layer.borderWidth=0.0;
    headerIcon.clipsToBounds=YES;
    title.hidden=YES;
    return target;
}
// The v12 native content views are laid out for 22/26pt tabs. The 30pt
// single row takes a few more points: move only overlapping content below,
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
    UIView *parent=app.superview; // Native rounded menu-background container.
    UIView *contentView=parent.superview; // Native sheet content, not menu container.
    if (!contentView) return;
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
    // 2026-10-14 owner override: ONE native-height ROW, not a giant 2-row
    // logo banner. Leftmost slot = the approved horizontal DuoFace logo;
    // four compact native App / Zoom / Style / Close slots follow.
    CGFloat sheetWidth=CGRectGetWidth(contentView.bounds);
    if (!isfinite(sheetWidth) || sheetWidth<148.0) {
        NSLog(@"[DuoFaceFullscreen] picker sheet width invalid %.1f",sheetWidth);
        return;
    }
    const CGFloat menuHeight=30.0;
    const CGFloat sideInset=8.0;
    // Compact intrinsic widths, leaving the native X its own unobstructed
    // hit region. Never stretch the menu parent over the close button.
    const CGFloat logoWidth=120.0; // Approved PNG 960x240 at 30pt height.
    // Buttons use their abbreviated labels; distribute the remaining
    // horizontal room over the logo-to-App, three tab, and Close-to-X gaps.
    // The last 48pt plus the side inset belongs exclusively to native X.
    const CGFloat xReserved=48.0;
    const CGFloat desired[4]={43.0,51.0,47.0,51.0};
    const CGFloat buttonTotal=192.0;
    CGFloat available=sheetWidth-2.0*sideInset-logoWidth-xReserved;
    CGFloat gap=MAX(6.0,(available-buttonTotal)/5.0);
    CGFloat buttonSpace=available-5.0*gap;
    CGFloat scale=MIN(1.0,buttonSpace/buttonTotal);
    if (!isfinite(scale) || scale<0.72) {
        NSLog(@"[DuoFaceFullscreen] insufficient safe picker width %.1f",sheetWidth);
        return;
    }
    CGFloat widths[4]={0};
    CGFloat menuWidth=0.0;
    for (int i=0;i<4;i++) {
        widths[i]=floor(desired[i]*scale);
        menuWidth+=widths[i];
    }
    menuWidth+=3.0*gap;
    CGRect nativeMenuFrame=parent.frame;
    CGFloat nativeBottom=CGRectGetMaxY(nativeMenuFrame);
    CGFloat menuTop=CGRectGetMinY(nativeMenuFrame);
    DFNativeHeaderLogoFrame(overlay,contentView,sideInset,
                            sideInset+logoWidth,menuTop,menuHeight);
    CGRect menuFrame=nativeMenuFrame;
    menuFrame.origin.x=sideInset+logoWidth+gap;
    menuFrame.origin.y=menuTop;
    menuFrame.size.width=menuWidth;
    menuFrame.size.height=menuHeight;
    parent.frame=menuFrame;
    parent.backgroundColor=UIColor.clearColor;
    parent.layer.cornerRadius=0.0;
    parent.layer.borderWidth=0.0;
    CGFloat x=0.0;
    UIButton *buttons[4]={app,zoom,style,close};
    for (int i=0;i<4;i++) {
        buttons[i].frame=CGRectMake(x,0,widths[i],menuHeight);
        x+=widths[i]+gap;
    }
    // Native _sheetCard (UIVisualEffectView) owns the actual blur and 1pt
    // outline. Preserve its hierarchy, native X and dismiss recognizer.
    DFClearNativePickerChrome(overlay);
    overlay.layer.borderWidth=0.0;
    contentView.backgroundColor=UIColor.clearColor;
    contentView.layer.borderWidth=0.0;
    for (UIView *v in contentView.subviews) {
        if (v==parent) continue;
        if (CGRectGetHeight(v.bounds)<=2.0 && CGRectGetWidth(v.bounds)>sheetWidth*0.55) {
            v.hidden=YES; // Native decorative horizontal separator only.
        }
    }
    DFReflowPickerContent(contentView,overlay,@[parent],
                          nativeBottom,menuTop+menuHeight+2.0);
    // Preserve the native font weight; only set approved 10pt size.
    UIFont *originalFont=app.titleLabel.font?:[UIFont systemFontOfSize:10.0];
    UIFont *font=[originalFont fontWithSize:10.0];
    BOOL expanded=DFHostIsExpanded();
    zoom.enabled=expanded || DFHostCanExpand();
    zoom.alpha=zoom.enabled?1.0:0.5;
    NSString *zoomTitle=@"Zoom";
    zoom.accessibilityLabel=expanded?@"Zoom Out":@"Zoom In";
    DFDecorate(app,@"App",@"square.grid.2x2",font);
    DFDecorate(zoom,zoomTitle,expanded?@"arrow.down.right.and.arrow.up.left":
        @"arrow.up.left.and.arrow.down.right",font);
    DFDecorate(style,@"Style",@"rectangle.3.group",font);
    DFDecorate(close,@"Close",@"xmark.circle",font);
    // Getter is present in the original v12 class (IMP 0xABA54).
    // The original actions set the mode, so no duplicate event handlers.
    NSInteger mode=[overlay respondsToSelector:@selector(overlayMode)]?
        [(id)overlay overlayMode]:-1;
    UIButton *active=nil;
    if (mode==0) active=app;
    else if (mode==1) active=style;
    else if (mode==2) active=close;
    // Do not pin the red highlight to Zoom while a native App/Style/Close
    // tab is actually selected. Preserve native overlayMode as source of truth.
    if (expanded && mode<0) active=zoom;
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
    if (mode==2) {
        DFRestyleRecentClearAll(overlay);
        DFRestyleNativeRecentAppRows(overlay);
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
// The v12 IMP is void(self,SEL,double,double,double), verified in
// audit/v12-picker-targeted-controls-20261015.txt at 0xa3e5c.
// Its only SF symbol 'plus' belongs to the native Add App tile.
%hook CBMultitaskingOverlayView
- (void)setupAppPickerCardsInCardW:(double)cardW
                             cardH:(double)cardH
                          contentY:(double)contentY {
    BOOL previous=DFBuildingNativeAddTile;
    DFBuildingNativeAddTile=YES;
    %orig;
    DFBuildingNativeAddTile=previous;
}
// Original renderer owns the heading and the close-all action. Restyle the
// existing UIButton only after native construction; never replace its target.
- (void)setupRecentAppsCardsInCardW:(double)cardW
                              cardH:(double)cardH
                           contentY:(double)contentY {
    // The original renderer chooses one of three localized status keys:
    // active CarPlay slot, off-slot PID, or off-slot/no confirmed PID.
    // Keep that decision and all native buttons. Localize only the visible
    // status output to the two owner-approved color dots.
    BOOL wasBuilding=DFBuildingNativeRecentRows;
    DFBuildingNativeRecentRows=YES;
    %orig;
    DFBuildingNativeRecentRows=wasBuilding;
    DFRestyleRecentClearAll((UIView *)self);
    DFRestyleNativeRecentAppRows((UIView *)self);
}
- (void)setupCardContent {
    %orig;
    DFLayoutPicker((UIView *)self);
}
- (void)layoutSubviews {
    %orig;
    DFLayoutPicker((UIView *)self);
}
%end
%hook CBLocalization
+ (NSString *)localizedStringForKey:(NSString *)key {
    // The key owner is verified in v12 DuoFaceDashboard.dylib at 0xA75B8
    // (RUNNING_TAG), 0xA769C (PID_TAG), and 0xA7700 (BACKGROUND_TAG).
    // Native stringWithFormat ignores surplus PID/slot arguments when there
    // is no format placeholder. The corresponding UILabel stays native.
    if (DFBuildingNativeRecentRows && NSThread.isMainThread) {
        if ([key isEqualToString:@"OVERLAY_RUNNING_TAG"]) return @"🟢";
        if ([key isEqualToString:@"OVERLAY_PID_TAG"] ||
            [key isEqualToString:@"OVERLAY_BACKGROUND_TAG"]) return @"🔴";
    }
    return %orig;
}
%end
%hook UIImage
+ (UIImage *)systemImageNamed:(NSString *)name
           withConfiguration:(UIImageSymbolConfiguration *)configuration {
    if (DFBuildingNativeAddTile && [name isEqualToString:@"plus"]) {
        UIImage *dots=%orig(@"ellipsis",configuration);
        if (dots) return dots;
    }
    return %orig;
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
