#import "DFLayoutEngine.h"
#import <math.h>
// Native12 approved eight layouts, preserving original presentation order:
// 1-pane, left/right, top/bottom, 3 columns, left+2 right,
// 2 left+right, top+2 bottom, 2 top+bottom.
// Unlike the prior prototype this NEVER invents a fourth live pane.
static CGFloat DFBoundRatio(CGFloat v) {
    return isfinite(v)?MAX(1.0/3.0,MIN(2.0/3.0,v)):.5;
}
NSInteger DFSlotCountForPreset(NSInteger preset) {
    return preset==0?1:(preset==1||preset==2?2:3);
}
BOOL DFPrimaryDividerIsVertical(NSInteger preset) {
    return preset!=2 && preset!=6 && preset!=7;
}
BOOL DFSecondaryDividerIsVertical(NSInteger preset) {
    return preset==3 || preset==6 || preset==7;
}
CGFloat DFPrimaryDividerCoordinate(CGRect b,NSInteger preset,CGFloat ratio) {
    CGFloat t=DFBoundRatio(ratio);
    return DFPrimaryDividerIsVertical(preset)?
      CGRectGetMinX(b)+CGRectGetWidth(b)*t:
      CGRectGetMinY(b)+CGRectGetHeight(b)*t;
}
void DFComputePresetFramesWithSecondary(CGRect b,NSInteger preset,
                                        CGFloat ratio,CGFloat secondary,CGRect *out) {
    for(int i=0;i<4;i++)out[i]=CGRectNull;
    if(CGRectIsNull(b)||CGRectIsEmpty(b))return;
    if(preset<0||preset>7)preset=1;
    CGFloat x=b.origin.x,y=b.origin.y,w=b.size.width,h=b.size.height;
    CGFloat a=DFBoundRatio(ratio),c=DFBoundRatio(secondary);
    CGFloat xx=x+w*a,yy=y+h*a;
    switch(preset) {
      case 0:out[0]=b;break;
      case 1:out[0]=CGRectMake(x,y,w*a,h);
             out[1]=CGRectMake(xx,y,w*(1-a),h);break;
      case 2:out[0]=CGRectMake(x,y,w,h*a);
             out[1]=CGRectMake(x,yy,w,h*(1-a));break;
      case 3:{
        CGFloat end=xx+w*(1-a)*c;
        out[0]=CGRectMake(x,y,w*a,h);
        out[1]=CGRectMake(xx,y,end-xx,h);
        out[2]=CGRectMake(end,y,x+w-end,h);break;}
      case 4:out[0]=CGRectMake(x,y,w*a,h);
             out[1]=CGRectMake(xx,y,w*(1-a),h*c);
             out[2]=CGRectMake(xx,y+h*c,w*(1-a),h*(1-c));break;
      case 5:out[0]=CGRectMake(x,y,w*a,h*c);
             out[1]=CGRectMake(x,y+h*c,w*a,h*(1-c));
             out[2]=CGRectMake(xx,y,w*(1-a),h);break;
      case 6:out[0]=CGRectMake(x,y,w,h*a);
             out[1]=CGRectMake(x,yy,w*c,h*(1-a));
             out[2]=CGRectMake(x+w*c,yy,w*(1-c),h*(1-a));break;
      case 7:out[0]=CGRectMake(x,y,w*c,h*a);
             out[1]=CGRectMake(x+w*c,y,w*(1-c),h*a);
             out[2]=CGRectMake(x,yy,w,h*(1-a));break;
    }
}
void DFComputePresetFrames(CGRect b,NSInteger preset,CGFloat ratio,CGRect *out) {
    DFComputePresetFramesWithSecondary(b,preset,ratio,.5,out);
}
CGRect DFSecondaryDividerRect(CGRect b,NSInteger preset,CGFloat ratio,CGFloat secondary) {
    if(preset<3||preset>7||CGRectIsNull(b)||CGRectIsEmpty(b))return CGRectNull;
    CGFloat x=CGRectGetMinX(b),y=CGRectGetMinY(b);
    CGFloat w=CGRectGetWidth(b),h=CGRectGetHeight(b);
    CGFloat a=DFBoundRatio(ratio),c=DFBoundRatio(secondary);
    switch(preset) {
      case 3:return CGRectMake(x+w*(a+(1-a)*c),y,0,h);
      case 4:return CGRectMake(x+w*a,y+h*c,w*(1-a),0);
      case 5:return CGRectMake(x,y+h*c,w*a,0);
      case 6:return CGRectMake(x+w*c,y+h*a,0,h*(1-a));
      case 7:return CGRectMake(x+w*c,y,0,h*a);
    }
    return CGRectNull;
}
