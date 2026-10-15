#pragma once
#import <UIKit/UIKit.h>

// Giá trị y hệt bản DuoFace đã duyệt:
// runtime/fullscreen/DFPickerZoomMenu.xm DFApprovedLogoRed = RGB(227,2,15).
// Các tệp nằm trong namespace mới, tránh ghi đè bản cài kế thừa DuoNavi.
static NSString * const DFIApprovedAssetRoot = @"/var/jb/Library/Application Support/DuoFaceIndependent/";

static inline UIColor *DFIApprovedRed(void) {
    return [UIColor colorWithRed:227.0/255.0 green:2.0/255.0 blue:15.0/255.0 alpha:1.0];
}
static inline UIColor *DFIApprovedLiveGreen(void) {
    return [UIColor colorWithRed:52.0/255.0 green:199.0/255.0 blue:89.0/255.0 alpha:1.0];
}
static inline UIImage *DFIApprovedArtwork(NSString *relativeName) {
    if (!relativeName.length || [relativeName containsString:@".."] || [relativeName hasPrefix:@"/"])
        return nil;
    return [UIImage imageWithContentsOfFile:
            [DFIApprovedAssetRoot stringByAppendingString:relativeName]];
}
static inline UIImage *DFIApprovedHeaderLogo(void) {
    UIImage *logo = DFIApprovedArtwork(@"duoface-logo-picker-alpha-v2.png");
    return logo ?: DFIApprovedArtwork(@"duoface-logo.png");
}
// Một dòng 30pt như picker v12: SF Symbol 16pt ở trên, nhãn 10pt ở dưới.
// Không dùng imageEdgeInsets âm: ở iOS16 UIButtonConfiguration có thể bỏ qua.
static inline void DFIStyleApprovedTab(UIButton *button, NSString *title,
                                       NSString *symbol, BOOL selected) {
    UIColor *color = selected ? UIColor.whiteColor :
        [UIColor colorWithWhite:0.68 alpha:1.0];
    button.layer.borderWidth=0;
    button.layer.cornerRadius=0;
    button.backgroundColor=selected?DFIApprovedRed():UIColor.clearColor;
    button.tintColor=color;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:color forState:UIControlStateNormal];
    [button setImage:nil forState:UIControlStateNormal];
    button.titleLabel.font=[UIFont systemFontOfSize:10];
    button.titleLabel.textAlignment=NSTextAlignmentCenter;
    button.titleLabel.adjustsFontSizeToFitWidth=YES;
    button.titleLabel.minimumScaleFactor=0.85;
    button.titleLabel.lineBreakMode=NSLineBreakByClipping;
    button.contentHorizontalAlignment=UIControlContentHorizontalAlignmentCenter;
    button.contentVerticalAlignment=UIControlContentVerticalAlignmentCenter;
    button.contentEdgeInsets=UIEdgeInsetsZero;
    button.titleEdgeInsets=UIEdgeInsetsMake(19,0,0,0);
    UIImageView *icon=(UIImageView *)[button viewWithTag:8162];
    if(![icon isKindOfClass:UIImageView.class]) {
        icon=[UIImageView new];icon.tag=8162;
        icon.contentMode=UIViewContentModeScaleAspectFit;
        icon.userInteractionEnabled=NO;
        [button addSubview:icon];
    }
    UIImage *image=[UIImage systemImageNamed:symbol withConfiguration:
        [UIImageSymbolConfiguration configurationWithPointSize:16
                            weight:UIImageSymbolWeightRegular]];
    icon.image=[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    icon.tintColor=color;
    icon.frame=CGRectMake((CGRectGetWidth(button.bounds)-16)/2,1,16,16);
    button.accessibilityLabel=title;
}
