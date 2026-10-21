#import "DFLayoutEngine.h"
#import <math.h>
NSInteger DFSlotCountForPreset(NSInteger preset) {
    if(preset<0 || preset>7)return 2;
    if(preset<=1)return 2;
    if(preset<=5)return 3;
    return 4;
}
BOOL DFPrimaryDividerIsVertical(NSInteger preset) {
    return preset==0 || preset==2 || preset==3 || preset==6 || preset==7;
}
void DFComputePresetFrames(CGRect b, NSInteger preset, CGFloat ratio, CGRect *out) {
    for(int i=0;i<4;i++)out[i]=CGRectNull;
    if(!isfinite(ratio))ratio=.5;
    ratio=MAX(1.0/3.0,MIN(2.0/3.0,ratio));
    CGFloat x=b.origin.x,y=b.origin.y,w=b.size.width,h=b.size.height;
    CGFloat a=w*ratio,c=h*ratio;
    switch(preset) {
      case 1: // two stacked live scenes
        out[0]=CGRectMake(x,y,w,c);
        out[1]=CGRectMake(x,y+c,w,h-c);
        break;
      case 2: // left primary; two genuine scenes stacked on right
        out[0]=CGRectMake(x,y,a,h);
        out[1]=CGRectMake(x+a,y,w-a,h/2);
        out[2]=CGRectMake(x+a,y+h/2,w-a,h/2);
        break;
      case 3: // right primary
        out[0]=CGRectMake(x,y,w-a,h/2);
        out[1]=CGRectMake(x+w-a,y,a,h);
        out[2]=CGRectMake(x,y+h/2,w-a,h/2);
        break;
      case 4: // top primary
        out[0]=CGRectMake(x,y,w,c);
        out[1]=CGRectMake(x,y+c,w/2,h-c);
        out[2]=CGRectMake(x+w/2,y+c,w/2,h-c);
        break;
      case 5: // bottom primary
        out[0]=CGRectMake(x,y,w/2,h-c);
        out[1]=CGRectMake(x+w/2,y,w/2,h-c);
        out[2]=CGRectMake(x,y+h-c,w,c);
        break;
      case 6: // four independent live quadrants
        out[0]=CGRectMake(x,y,a,c);
        out[1]=CGRectMake(x+a,y,w-a,c);
        out[2]=CGRectMake(x,y+c,a,h-c);
        out[3]=CGRectMake(x+a,y+c,w-a,h-c);
        break;
      case 7: // four strips, each holding an independent app scene
        out[0]=CGRectMake(x,y,a/2,h);
        out[1]=CGRectMake(x+a/2,y,a/2,h);
        out[2]=CGRectMake(x+a,y,(w-a)/2,h);
        out[3]=CGRectMake(x+a+(w-a)/2,y,(w-a)/2,h);
        break;
      case 0:
      default: // established vertical Native12-style two-app split
        out[0]=CGRectMake(x,y,a,h);
        out[1]=CGRectMake(x+a,y,w-a,h);
        break;
    }
}
