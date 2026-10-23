#ifndef DF_NATIVE12_MENU_HEADER_H
#define DF_NATIVE12_MENU_HEADER_H
#import <UIKit/UIKit.h>
#import <math.h>

// Grounded in this project's original v12 DFPickerZoomMenu.xm:
// OUT = arrow.up.left.and.arrow.down.right, IN = arrow.down.right.and.arrow.up.left.
// Icon is a visible subview, above the Zoom label; do NOT use an inert
// one-state fullscreen PNG or pretend an arrow is a successful Dock ACK.
static inline NSString *DFNative12ZoomArrowSymbol(BOOL expanded) {
    return expanded?@"arrow.down.right.and.arrow.up.left":
                    @"arrow.up.left.and.arrow.down.right";
}
static inline void DFNative12DecorateZoomButton(UIButton *button, BOOL expanded) {
    if(!button)return;
    [button setImage:nil forState:UIControlStateNormal];
    [button setTitle:expanded?@"Zoom Out":@"Zoom In" forState:UIControlStateNormal];
    button.accessibilityLabel=expanded?@"Zoom Out":@"Zoom In";
    button.accessibilityHint=@"Mở rộng toàn giao diện và ẩn Dock, hoặc khôi phục Dock";
    button.titleLabel.font=[UIFont systemFontOfSize:9 weight:UIFontWeightMedium];
    button.titleLabel.textAlignment=NSTextAlignmentCenter;
    button.titleLabel.adjustsFontSizeToFitWidth=YES;
    button.titleLabel.minimumScaleFactor=.8;
    button.titleEdgeInsets=UIEdgeInsetsMake(19,0,0,0);
    button.contentEdgeInsets=UIEdgeInsetsZero;
    button.contentHorizontalAlignment=UIControlContentHorizontalAlignmentCenter;
    button.contentVerticalAlignment=UIControlContentVerticalAlignmentCenter;
    UIImageView *arrow=(UIImageView *)[button viewWithTag:197312];
    if(!arrow) {
        arrow=[[UIImageView alloc]initWithFrame:CGRectZero];
        arrow.tag=197312;
        arrow.userInteractionEnabled=NO;
        arrow.contentMode=UIViewContentModeScaleAspectFit;
        [button addSubview:arrow];
    }
    CGFloat width=CGRectGetWidth(button.bounds);
    arrow.frame=CGRectMake((width-16.0)/2.0,1.0,16.0,16.0);
    arrow.tintColor=button.tintColor?:UIColor.whiteColor;
    arrow.image=[UIImage systemImageNamed:DFNative12ZoomArrowSymbol(expanded)
        withConfiguration:[UIImageSymbolConfiguration
            configurationWithPointSize:16 weight:UIImageSymbolWeightRegular]];
}

// First-party source reference: runtime/fullscreen/DFPickerZoomMenu.xm,
// DFLayoutPicker / DFDecorate. These are the shipped DuoFace header changes
// layered over Native12's original three modes, not a second outer modal.
// Return zero if the original safe-width gate rejects the four-button row.
static inline CGFloat DFLayoutNative12MenuHeader(UIView *sheet, UIView *bar,
    UIImageView *logo, UILabel *title, NSArray<UIButton *> *buttons,
    CGRect nativeFrame, NSInteger selected, BOOL expanded) {
    if(buttons.count!=4)return 0;
    CGFloat width=CGRectGetWidth(sheet.bounds);
    CGFloat available=width-16.0-120.0-48.0;
    CGFloat gap=MAX(6.0,(available-192.0)/5.0);
    CGFloat scale=MIN(1.0,(available-5.0*gap)/192.0);
    if(!isfinite(scale)||scale<.72)return 0;
    NSString *root=@"/var/jb/Library/Application Support/DuoFaceNativeHost/VisualAssets/";
    UIImage *art=[UIImage imageWithContentsOfFile:
        [root stringByAppendingString:@"duoface-logo-picker-alpha-v2.png"]];
    if(!art)art=[UIImage imageWithContentsOfFile:
        [root stringByAppendingString:@"duoface-logo.png"]];
    if(art){
        logo.image=art;logo.frame=CGRectMake(8,nativeFrame.origin.y,120,30);
        logo.contentMode=UIViewContentModeScaleAspectFit;title.hidden=YES;
    }
    const CGFloat desired[4]={43,51,47,51};
    CGFloat rowWidth=3*gap;
    for(int i=0;i<4;i++)rowWidth+=floor(desired[i]*scale);
    bar.frame=CGRectMake(128+gap,nativeFrame.origin.y,rowWidth,30);
    bar.backgroundColor=UIColor.clearColor;bar.layer.cornerRadius=0;
    NSArray *names=@[@"App",@"Zoom",@"Style",@"Close"];
    NSArray *symbols=@[@"square.grid.2x2",expanded?
        @"arrow.down.right.and.arrow.up.left":@"arrow.up.left.and.arrow.down.right",
        @"rectangle.3.group",@"xmark.circle"];
    CGFloat x=0;
    for(NSUInteger i=0;i<4;i++){
        UIButton *button=buttons[i];
        CGFloat w=floor(desired[i]*scale);
        button.frame=CGRectMake(x,0,w,30);x+=w+gap;
        [button setTitle:i==1?(expanded?@"Zoom Out":@"Zoom In"):names[i] forState:UIControlStateNormal];
        button.titleLabel.font=[button.titleLabel.font fontWithSize:10];
        button.titleLabel.adjustsFontSizeToFitWidth=YES;
        button.titleLabel.minimumScaleFactor=.85;
        button.titleEdgeInsets=UIEdgeInsetsMake(19,0,0,0);
        button.contentEdgeInsets=UIEdgeInsetsZero;
        button.layer.cornerRadius=0;button.layer.borderWidth=0;
        BOOL active=(NSInteger)i==selected;
        button.backgroundColor=active?
            [UIColor colorWithRed:227./255 green:2./255 blue:15./255 alpha:1]:UIColor.clearColor;
        UIColor *tint=active?UIColor.whiteColor:[UIColor colorWithWhite:.68 alpha:1];
        [button setTitleColor:tint forState:UIControlStateNormal];button.tintColor=tint;
        UIImageView *icon=(UIImageView *)[button viewWithTag:197312];
        if(!icon){icon=[UIImageView new];icon.tag=197312;icon.userInteractionEnabled=NO;
            icon.contentMode=UIViewContentModeScaleAspectFit;[button addSubview:icon];}
        icon.frame=CGRectMake((w-16)/2,1,16,16);icon.tintColor=tint;
        icon.image=[UIImage systemImageNamed:symbols[i] withConfiguration:
            [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightRegular]];
    }
    DFNative12DecorateZoomButton(buttons[1],expanded);
    return MAX(CGRectGetMaxY(nativeFrame),nativeFrame.origin.y+32.0);
}
#endif
