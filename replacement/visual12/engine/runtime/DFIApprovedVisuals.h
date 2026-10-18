#pragma once
#import <UIKit/UIKit.h>

// Giá trị y hệt bản DuoFace đã duyệt:
// runtime/fullscreen/DFPickerZoomMenu.xm DFApprovedLogoRed = RGB(227,2,15).
// Các tệp nằm trong namespace mới, tránh ghi đè bản cài kế thừa DuoNavi.
static NSString * const DFIApprovedAssetRoot = @"/var/jb/Library/Application Support/DuoFaceVisual12/";

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
    // iOS 16 UIButtonConfiguration may ignore titleEdgeInsets/contentEdgeInsets.
    // Draw our own 16pt icon + 10pt caption at measured positions; the
    // UIButton itself keeps its original UIControl tap action/selected state.
    button.configuration=nil;
    [button setTitle:nil forState:UIControlStateNormal];
    [button setImage:nil forState:UIControlStateNormal];
    UILabel *caption=(UILabel *)[button viewWithTag:8163];
    if(![caption isKindOfClass:UILabel.class]) {
        caption=[UILabel new];
        caption.tag=8163;
        caption.userInteractionEnabled=NO;
        caption.textAlignment=NSTextAlignmentCenter;
        caption.adjustsFontSizeToFitWidth=YES;
        caption.minimumScaleFactor=.85;
        caption.lineBreakMode=NSLineBreakByClipping;
        [button addSubview:caption];
    }
    caption.text=title;
    caption.font=[UIFont systemFontOfSize:10];
    caption.textColor=color;
    caption.frame=CGRectMake(0,18,CGRectGetWidth(button.bounds),12);
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
