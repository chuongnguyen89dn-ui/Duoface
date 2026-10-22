#import "DFNative12PresetPreview.h"
#import "DFLayoutEngine.h"
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
UIImage *DFNative12PresetPreview(NSInteger preset, CGSize size) {
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
        if(preset==0){
            // Original 9f158..9f174: colorWithWhite:alpha: (1,.3);
            // 9f170 loads line width .8.
            [[UIColor colorWithWhite:1 alpha:.3] setStroke];
            background.lineWidth=.8;
        }else{
            // Original 9f138..9f150: (.2,.6,.9,1), line width1.2.
            [[UIColor colorWithRed:.2 green:.6 blue:.9 alpha:1] setStroke];
            background.lineWidth=1.2;
        }
        [background stroke];
        // Original @9f1e4: threshold 100pt; gap3/4, and
        // @9f210: CGRectInset(...,2,2.5). Rounded, centred rectangles.
        CGFloat gap=size.width>100?4:3;
        CGRect inner=CGRectInset(canvas,4,4.5);
        CGRect rects[4]={CGRectNull,CGRectNull,CGRectNull,CGRectNull};
        DFComputePresetFramesWithSecondary(inner,preset,
                DFNative12DefaultPrimaryRatio(preset),
                DFNative12DefaultSecondaryRatio(preset),rects);
        NSInteger count=DFSlotCountForPreset(preset);
        for(NSInteger i=0;i<count;i++){
            CGRect region=rects[i];
            if(CGRectIsNull(region)||CGRectIsEmpty(region))continue;
            CGRect tile=CGRectInset(region,gap*.5,gap*.5);
            if(tile.size.width<=0||tile.size.height<=0)continue;
            CGFloat radius=size.width>100?3.5:2.5;
            UIBezierPath *p=[UIBezierPath bezierPathWithRoundedRect:tile
                                                      cornerRadius:radius];
            if(preset==0){
                // Original fallback 9fb04..9fb5c, literal loads
                // 0x3116e8=.87,0x3116f0=.48,0x3116f8=.53.
                [[UIColor colorWithRed:.87 green:.48 blue:.53 alpha:1] setFill];
                [[UIColor colorWithWhite:1 alpha:.4] setStroke];
            }else{
                // Original 9f9c0..9fa2c: verified 0x311720=.08,
                // 0x311728=.52 and blue=1, alpha=1.
                [[UIColor colorWithRed:.08 green:.52 blue:1 alpha:1] setFill];
                [[UIColor colorWithRed:.45 green:.85 blue:1 alpha:1] setStroke];
            }
            [p fill];
            p.lineWidth=size.width>100?1.0:.8;
            [p stroke];
        }
        return UIGraphicsGetImageFromCurrentImageContext();
    } @finally {
        UIGraphicsEndImageContext();
    }
}
