#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
/* Independent, Native12-approved visual shell for SidePlay's existing app host.
   The SidePlay host remains responsible for scene lifecycle/actual pane views.
   This class never creates an SBAppViewController or alters licenses. */
@protocol DFSPNativeFrameDelegate <NSObject>
- (void)nativeFrameRequestedAppForSlot:(NSInteger)slot;
- (void)nativeFrameRequestedFocusForSlot:(NSInteger)slot;
- (void)nativeFrameRequestedRestoreForSlot:(NSInteger)slot;
- (void)nativeFrameRequestedZoom;
- (void)nativeFrameRequestedStyle;
- (void)nativeFrameRequestedCloseForSlot:(NSInteger)slot;
- (void)nativeFrameRequestedSwap;
- (void)nativeFrameDraggedToRatio:(double)ratio ended:(BOOL)ended;
@end
@interface DFSPNativeFrame : UIView
@property(nonatomic,weak,nullable) id<DFSPNativeFrameDelegate> delegate;
@property(nonatomic,readonly) BOOL pickerVisible;
/* -1 = split, otherwise focused pane index; no fullscreen CarPlay action. */
@property(nonatomic) NSInteger focusedSlot;
- (void)updateFirst:(CGRect)first second:(CGRect)second
         hasFirstApp:(BOOL)firstApp hasSecondApp:(BOOL)secondApp
             ratio:(double)ratio fullscreen:(BOOL)fullscreen;
- (void)resetForDisconnect;
@end
NS_ASSUME_NONNULL_END
