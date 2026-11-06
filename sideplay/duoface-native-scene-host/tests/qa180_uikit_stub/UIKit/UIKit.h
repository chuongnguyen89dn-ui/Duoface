#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
typedef NS_ENUM(NSInteger,UITouchPhase) {UITouchPhaseBegan,UITouchPhaseMoved,UITouchPhaseStationary,UITouchPhaseEnded,UITouchPhaseCancelled};
typedef NS_ENUM(NSInteger,UIEventType) {UIEventTypeTouches=0};
@class UIView,UIWindow,UIWindowScene;
@interface UISceneSession : NSObject
@property(nonatomic,copy) NSString *persistentIdentifier;
@end
@interface UIWindowScene : NSObject
@property(nonatomic,strong) UISceneSession *session;
@end
@interface UITouch : NSObject
@property(nonatomic) UITouchPhase phase;
@property(nonatomic,weak) UIView *view;
@property(nonatomic,weak) UIWindow *window;
@end
@interface UIEvent : NSObject
@property(nonatomic) UIEventType type;
@property(nonatomic,strong) NSSet<UITouch *> *allTouches;
@end
@interface UIView : NSObject
@property(nonatomic) CGRect frame;
@property(nonatomic) CGRect bounds;
@property(nonatomic) CGFloat alpha;
@property(nonatomic) BOOL hidden;
@property(nonatomic) BOOL userInteractionEnabled;
@property(nonatomic) BOOL multipleTouchEnabled;
@property(nonatomic,weak) UIWindow *window;
@property(nonatomic,weak) UIView *superview;
@property(nonatomic,strong) NSMutableArray<UIView *> *subviews;
@property(nonatomic) NSUInteger forwardedBegan;
@property(nonatomic) NSUInteger forwardedEnd;
- (instancetype)initWithFrame:(CGRect)frame;
- (void)addSubview:(UIView *)view;
- (BOOL)isDescendantOfView:(UIView *)view;
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event;
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event;
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
@end
@interface UIWindow : UIView
@property(nonatomic,strong) UIWindowScene *windowScene;
@end
