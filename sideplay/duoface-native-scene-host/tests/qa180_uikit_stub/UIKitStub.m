#import <UIKit/UIKit.h>
@implementation UITouch
@end
@implementation UIEvent
@end
@implementation UIView
- (instancetype)initWithFrame:(CGRect)frame {
    if((self=[super init])){_frame=frame;_bounds=(CGRect){CGPointZero,frame.size};_alpha=1;_userInteractionEnabled=YES;_subviews=[NSMutableArray new];}
    return self;
}
- (void)addSubview:(UIView *)view {[self.subviews addObject:view];view.superview=self;view.window=self.window;}
- (BOOL)isDescendantOfView:(UIView *)view {for(UIView *v=self;v;v=v.superview)if(v==view)return YES;return NO;}
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {(void)event;return CGRectContainsPoint(self.bounds,point);}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if(self.hidden || !self.userInteractionEnabled || self.alpha<=.01 || ![self pointInside:point withEvent:event])return nil;
    for(UIView *v in self.subviews.reverseObjectEnumerator) {UIView *hit=[v hitTest:point withEvent:event];if(hit)return hit;}
    return self;
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {(void)event;self.forwardedBegan+=touches.count;}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {(void)touches;(void)event;}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {(void)event;self.forwardedEnd+=touches.count;}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {(void)touches;(void)event;}
@end
@implementation UIWindow
@end
