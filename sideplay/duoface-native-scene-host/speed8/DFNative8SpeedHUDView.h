#pragma once
#import <UIKit/UIKit.h>
// OWN historical Speed8 HUD view only; portable data and UI without old
// proprietary bridge manager. NOT mounted until safe real live owner validated.
@interface DFNative8SpeedHUDView : UIView
@property(nonatomic,weak) UIWindow *ownerWindow;
- (void)restoreSavedPosition;
- (void)stop;
@end
