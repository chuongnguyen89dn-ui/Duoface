#import "DFNative12PresetPreview.h"
#import "DFNative12PreviewGeometry.h"
#import <math.h>

// Original Native12 Dashboard SHA256:
// 9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea
// static C preview helper @0x9efe0..0x9ff00, called by
// CBMultitaskingOverlayView.setupPresetCards... @0xa6484.
// Verified 968 ARM64 instructions in
// audit/native12-continuation-4888299/original-preview-helper/.
// 25 original RGB/geometry literal values verified in
// original-preview-helper/PREVIEW_HELPER_LITERALS.json.
// The original helper renders a UIImage with UIGraphics, a 6.5pt
// rounded background, filled/stroked rounded region rectangles and
// the standard nine split configurations; it DOES NOT show nine
// separate fully-white UIView tiles. All code below is independent.
UIImage *DFNative12PresetPreview(NSInteger preset, BOOL selected, CGSize size) {
    if(preset<0 || preset>8 || !isfinite(size.width) || !isfinite(size.height) ||
       size.width<10 || size.height<10 || size.width>1200 || size.height>1200)
        return nil;
    UIGraphicsBeginImageContextWithOptions(size,NO,0);
    @try {
        CGRect canvas=CGRectMake(0,0,size.width,size.height);
        // Original helper 9f068..9f0a0: inset=(2,2), radius=6.5.
        UIBezierPath *background=[UIBezierPath
                bezierPathWithRoundedRect:CGRectInset(canvas,2,2)
                cornerRadius:6.5];
        // Original 9f0c4..9f0dc: (0.04,0.04,0.06,1).
        [[UIColor colorWithRed:.04 green:.04 blue:.06 alpha:1] setFill];
        [background fill];
        if(!selected){
            // Original 9f158..9f174: colorWithWhite:alpha: (1,.3);
            // 9f170 loads line width .8.
            [[UIColor colorWithWhite:1 alpha:.3] setStroke];
            background.lineWidth=.8;
        }else{
            // Original 9f138..9f150: (.2,.6,.9,1), line width1.2.
            [[UIColor colorWithRed:.2 green:.6 blue:1 alpha:.9] setStroke];
            background.lineWidth=1.2;
        }
        [background stroke];
        // Original 9f1e4..9f28c: outer inset and inter-pane gap are
        // distinct; thumbnails do not use the live scene layout ratios.
        DFNative12PreviewRect rects[4];
        int count=DFNative12PreviewRects((int)preset,size.width,size.height,rects);
        for(int i=0;i<count;i++){
            DFNative12PreviewRect r=rects[i];
            CGRect tile=CGRectMake(r.x,r.y,r.w,r.h);
            CGFloat radius=size.width>100?3.5:2.5;
            UIBezierPath *p=[UIBezierPath bezierPathWithRoundedRect:tile
                                                      cornerRadius:radius];
            if(!selected){
                // Original unselected fill and stroke, 9fb04..9fb90.
                [[UIColor colorWithRed:.87 green:.9 blue:.95 alpha:1] setFill];
                [[UIColor colorWithRed:.48 green:.53 blue:.62 alpha:1] setStroke];
            }else{
                // Original 9f9c0..9fa2c: verified 0x311720=.08,
                // 0x311728=.52 and blue=1, alpha=1.
                [[UIColor colorWithRed:.08 green:.52 blue:1 alpha:1] setFill];
                [[UIColor colorWithRed:.45 green:.85 blue:1 alpha:1] setStroke];
            }
            [p fill];
            p.lineWidth=selected?1.0:.6;
            [p stroke];
            // Original 9fa58..9fc40: small top indicator in every pane.
            if(tile.size.width>=12 && tile.size.height>=10){
                CGFloat w=roundf((float)(tile.size.width*(selected?.4:.35)));
                UIBezierPath *indicator=[UIBezierPath bezierPathWithRoundedRect:
                    CGRectMake(tile.origin.x+(tile.size.width-w)*.5,
                               tile.origin.y+2,w,selected?1.2:1)
                    cornerRadius:selected?.6:.5];
                UIColor *color=selected?[UIColor colorWithWhite:1 alpha:.95]:
                    [UIColor colorWithRed:.25 green:.32 blue:.45 alpha:.9];
                [color setFill];[indicator fill];
            }
        }
        // Original 9fc80..9fd60: bottom indicator only above 60pt.
        if(size.width>60){
            CGFloat w=roundf((float)(size.width*.22));
            UIBezierPath *indicator=[UIBezierPath bezierPathWithRoundedRect:
                CGRectMake((size.width-w)*.5,size.height-4.5,w,1.5)
                cornerRadius:.75];
            UIColor *color=selected?[UIColor colorWithRed:.65 green:.88 blue:1 alpha:.95]:
                [UIColor colorWithWhite:1 alpha:.75];
            [color setFill];[indicator fill];
        }
        return UIGraphicsGetImageFromCurrentImageContext();
    } @finally {
        UIGraphicsEndImageContext();
    }
}
