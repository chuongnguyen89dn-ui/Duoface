#ifndef DF_NATIVE12_PREVIEW_GEOMETRY_H
#define DF_NATIVE12_PREVIEW_GEOMETRY_H
#include <math.h>
typedef struct { double x,y,w,h; } DFNative12PreviewRect;
// Native12 helper 0x9efe0: geometry decoded from the immutable reference.
// 9f1e4..9f274 separates padding (3/4) from gap (1.8/2.5),
// and rounds half/third widths through float, ties away from zero.
static inline int DFNative12PreviewRects(int preset,double width,double height,
                                        DFNative12PreviewRect out[4]) {
    if(preset<0 || preset>8 || !isfinite(width) || !isfinite(height) ||
       width<10 || height<10 || width>1200 || height>1200)return 0;
    double pad=width>100?4:3, gap=width>100?2.5:1.8;
    double x=2+pad,y=2+pad,w=width-4-2*pad,h=height-4-2*pad;
    if(w<=0 || h<=0)return 0;
    double left=roundf((float)((w-gap)*.5)),right=w-gap-left;
    double top=roundf((float)((h-gap)*.5)),bottom=h-gap-top;
    double rx=x+left+gap,by=y+top+gap;
    DFNative12PreviewRect full={x,y,w,h},l={x,y,left,h},r={rx,y,right,h};
    DFNative12PreviewRect t={x,y,w,top},b={x,by,w,bottom};
    DFNative12PreviewRect tl={x,y,left,top},tr={rx,y,right,top};
    DFNative12PreviewRect bl={x,by,left,bottom},br={rx,by,right,bottom};
    switch(preset){
        case 0:out[0]=full;return 1; // 9f290
        case 1:out[0]=l;out[1]=r;return 2; // 9f2fc
        case 2:out[0]=t;out[1]=b;return 2; // 9f384
        case 3:{ // 9f408: first two columns rounded; third takes remainder
            double c=roundf((float)((w-2*gap)/3));
            out[0]=(DFNative12PreviewRect){x,y,c,h};
            out[1]=(DFNative12PreviewRect){x+c+gap,y,c,h};
            out[2]=(DFNative12PreviewRect){x+2*(c+gap),y,w-2*gap-2*c,h};return 3;
        }
        case 4:out[0]=l;out[1]=tr;out[2]=br;return 3; // 9f4f4
        case 5:out[0]=tl;out[1]=bl;out[2]=r;return 3; // 9f5c4
        case 6:out[0]=t;out[1]=bl;out[2]=br;return 3; // 9f690
        case 7:out[0]=tl;out[1]=tr;out[2]=b;return 3; // 9f760
        case 8:out[0]=tl;out[1]=tr;out[2]=bl;out[3]=br;return 4; // 9fdd4
    }
    return 0;
}
#endif
