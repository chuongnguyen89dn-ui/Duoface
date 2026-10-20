// Based on the measured native CarPlay window, not a guessed 45/64pt crop.
// An offscreen bar (e.g. x=-45 width=45 on iPhone X) is NOT a visible Dock.
#import "MTCPNativeChromeLayout.h"
#import <math.h>
static BOOL MTCPRectFinite(CGRect r) {
    return isfinite(r.origin.x) && isfinite(r.origin.y) &&
           isfinite(r.size.width) && isfinite(r.size.height) &&
           r.size.width>0 && r.size.height>0 && !CGRectIsNull(r);
}
BOOL MTCPNativeContentIsWithinScreen(CGRect screen,CGRect usable) {
    return MTCPRectFinite(screen) && MTCPRectFinite(usable) &&
           usable.size.width>=160 && usable.size.height>=80 &&
           CGRectContainsRect(screen,usable);
}
BOOL MTCPNativeUsableBounds(CGRect screen,CGRect bar,CGRect *usable,MTCPDockEdge *edge) {
    if (usable)*usable=CGRectNull;
    if (edge)*edge=MTCPDockEdgeNone;
    if (!MTCPRectFinite(screen) || !MTCPRectFinite(bar) ||
        screen.size.width<200 || screen.size.height<120)return NO;
    CGRect visible=CGRectIntersection(screen,bar);
    if (CGRectIsNull(visible) || CGRectIsEmpty(visible))return NO;
    // Reject an almost invisible transient native window or a notification.
    if (visible.size.width<20 || visible.size.height<20)return NO;
    CGFloat eps=2.0;
    CGFloat left=fabs(CGRectGetMinX(visible)-CGRectGetMinX(screen));
    CGFloat right=fabs(CGRectGetMaxX(visible)-CGRectGetMaxX(screen));
    CGFloat top=fabs(CGRectGetMinY(visible)-CGRectGetMinY(screen));
    CGFloat bottom=fabs(CGRectGetMaxY(visible)-CGRectGetMaxY(screen));
    BOOL vertical=visible.size.height>=screen.size.height*0.80 &&
                  visible.size.width>=20 && visible.size.width<=screen.size.width*0.25;
    BOOL horizontal=visible.size.width>=screen.size.width*0.80 &&
                    visible.size.height>=20 && visible.size.height<=screen.size.height*0.25;
    MTCPDockEdge candidate=MTCPDockEdgeNone;
    CGRect content=screen;
    if (vertical && left<=eps && CGRectGetMaxX(visible)<CGRectGetMaxX(screen)-160) {
        candidate=MTCPDockEdgeLeft;
        content.origin.x=CGRectGetMaxX(visible);
        content.size.width=CGRectGetMaxX(screen)-content.origin.x;
    } else if (vertical && right<=eps && CGRectGetMinX(visible)>CGRectGetMinX(screen)+160) {
        candidate=MTCPDockEdgeRight;
        content.size.width=CGRectGetMinX(visible)-screen.origin.x;
    } else if (horizontal && top<=eps && CGRectGetMaxY(visible)<CGRectGetMaxY(screen)-80) {
        candidate=MTCPDockEdgeTop;
        content.origin.y=CGRectGetMaxY(visible);
        content.size.height=CGRectGetMaxY(screen)-content.origin.y;
    } else if (horizontal && bottom<=eps && CGRectGetMinY(visible)>CGRectGetMinY(screen)+80) {
        candidate=MTCPDockEdgeBottom;
        content.size.height=CGRectGetMinY(visible)-screen.origin.y;
    }
    if (candidate==MTCPDockEdgeNone || !MTCPNativeContentIsWithinScreen(screen,content))return NO;
    if (usable)*usable=content;
    if (edge)*edge=candidate;
    return YES;
}

// Native12 formula: x=screen.x+left,y=screen.y+top,
// width=screen.width-left-right,height=screen.height-top-bottom.
// Fullscreen uses original screen bounds (all insets 0), and Normal restores
// a *captured, valid* insets rectangle rather than multiplying by a ratio.
BOOL MTCPNativeUsableFromInsets(CGRect screen,CGFloat top,CGFloat left,
                                CGFloat bottom,CGFloat right,CGRect *usable) {
    if(usable)*usable=CGRectNull;
    if(!MTCPRectFinite(screen) || screen.size.width<200 ||
       screen.size.height<120 || !isfinite(top) || !isfinite(left) ||
       !isfinite(bottom) || !isfinite(right) ||
       top<0 || left<0 || bottom<0 || right<0)return NO;
    CGRect content=CGRectMake(screen.origin.x+left,screen.origin.y+top,
       screen.size.width-left-right,screen.size.height-top-bottom);
    if(!MTCPNativeContentIsWithinScreen(screen,content))return NO;
    if(usable)*usable=content;
    return YES;
}
